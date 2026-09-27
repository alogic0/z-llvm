const std = @import("std");
const common = @import("tool_common.zig");

pub fn main(init: std.process.Init) !void {
    try run(init);
}

pub fn run(init: std.process.Init) !void {
    const a = init.gpa;
    const io = init.io;
    const temp = try common.TempDir.init(a, io, "byte_loops_diff");
    var success = false;
    defer if (success) temp.deinit(a, io) else {
        std.debug.print("byte_loops failure artifacts: {s}\n", .{temp.path});
        a.free(temp.path);
    };
    const fixture = try temp.join(a, "input.ll");
    defer a.free(fixture);
    const family = try std.Io.Dir.cwd().readFileAlloc(io, "test/behavioral/byte_loops_family.ll", a, .limited(1024 * 1024));
    defer a.free(family);
    const compositions = try std.Io.Dir.cwd().readFileAlloc(io, "test/behavioral/byte_loops_compositions.ll", a, .limited(1024 * 1024));
    defer a.free(compositions);
    // The composition preamble duplicates the triple and declaration.
    const definitions = std.mem.indexOf(u8, compositions, "define ") orelse return error.MissingDefinitions;
    const source = try std.fmt.allocPrint(a, "{s}\n{s}", .{ family, compositions[definitions..] });
    defer a.free(source);
    try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = fixture, .data = source });
    var hash: [32]u8 = undefined;
    std.crypto.hash.sha2.Sha256.hash(source, &hash, .{});
    var buffer: [4096]u8 = undefined;
    var out = std.Io.File.stdout().writer(io, &buffer);
    for ([_][]const u8{ "direct", "release-o3" }) |route| {
        const input = try common.allocTempFile(a, temp, route, ".ll");
        defer a.free(input);
        if (std.mem.eql(u8, route, "direct")) {
            try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = input, .data = source });
        } else {
            try runToFile(a, io, temp, &.{ "zig", "build", "run", "--", "--passes=release-o3", fixture }, "byte_loops optimize", input);
        }
        const verified = try runChecked(a, io, temp, &.{ "opt-22", "-passes=verify", "-disable-output", input }, "byte_loops IR verification");
        common.freeRunResult(a, verified);
        const object = try common.allocTempFile(a, temp, route, ".o");
        defer a.free(object);
        try runToFile(a, io, temp, &.{ "zig", "build", "run", "--", "--target=x86_64-linux", "--generic-cfg-selector", "--emit=obj", input }, "byte_loops object", object);
        const owners = try runChecked(a, io, temp, &.{ "zig", "build", "run", "--", "--target=x86_64-linux", "--generic-cfg-selector", "--emit=selection-owner-manifest", input }, "byte_loops ownership");
        defer common.freeRunResult(a, owners);
        const owners_path = try common.allocTempFile(a, temp, route, ".owners");
        defer a.free(owners_path);
        try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = owners_path, .data = owners.stdout });
        var lines = std.mem.splitScalar(u8, owners.stdout, '\n');
        if (!std.mem.eql(u8, lines.next() orelse return error.MissingOwnership, "row_identity\tselection_owner")) return error.InvalidOwnership;
        var count: usize = 0;
        while (lines.next()) |line| {
            if (line.len == 0) continue;
            const tab = std.mem.indexOfScalar(u8, line, '\t') orelse return error.InvalidOwnership;
            const owner = line[tab + 1 ..];
            if (!std.mem.eql(u8, owner, "composed_block") and !std.mem.eql(u8, owner, "composed_cfg")) return error.ByteLoopsFallback;
            try out.interface.print("byte_loops-owner route={s} function={s} owner={s}\n", .{ route, line[0..tab], owner });
            count += 1;
        }
        if (count != 7) return error.WrongFunctionCount;
        for ([_][]const u8{ "ReleaseFast", "ReleaseSafe", "ReleaseSmall" }) |mode| {
            const stem = try std.fmt.allocPrint(a, "{s}-{s}", .{ route, mode });
            defer a.free(stem);
            const reference_obj = try common.allocTempFile(a, temp, stem, ".reference.o");
            defer a.free(reference_obj);
            const opt = if (std.mem.eql(u8, mode, "ReleaseSmall")) "-Oz" else if (std.mem.eql(u8, mode, "ReleaseFast")) "-O3" else "-O2";
            // Always compare against the original input, including optimized runs.
            const compiled = try runChecked(a, io, temp, &.{ "clang-22", "-Wno-override-module", opt, "-c", fixture, "-o", reference_obj }, "byte_loops LLVM reference");
            common.freeRunResult(a, compiled);
            const reference = try common.allocTempFile(a, temp, stem, ".reference");
            defer a.free(reference);
            const linked = try common.allocTempFile(a, temp, stem, ".linked");
            defer a.free(linked);
            for ([_][]const u8{ reference_obj, object }, [_][]const u8{ reference, linked }) |obj, exe| {
                const emit = try std.fmt.allocPrint(a, "-femit-bin={s}", .{exe});
                defer a.free(emit);
                const result = try runChecked(a, io, temp, &.{ "zig", "build-exe", "test/behavioral/byte_loops_harness.zig", obj, "-O", mode, emit }, "byte_loops harness");
                common.freeRunResult(a, result);
            }
            const expected = try runChecked(a, io, temp, &.{ "timeout", "30", reference }, "byte loops reference execution");
            defer common.freeRunResult(a, expected);
            const actual = try runChecked(a, io, temp, &.{ "timeout", "30", linked }, "byte loops execution");
            defer common.freeRunResult(a, actual);
            if (expected.stderr.len != 0 or actual.stderr.len != 0 or !std.mem.eql(u8, expected.stdout, actual.stdout) or
                !std.mem.startsWith(u8, actual.stdout, "byte-loops observations=32648 ")) return error.ByteLoopsMismatch;
            for ([_][]const u8{ "checked", "huge" }) |member| {
                for ([_][]const u8{ reference, linked }) |exe| {
                    const trapped = try std.process.run(a, io, .{ .argv = &.{ exe, member } });
                    defer common.freeRunResult(a, trapped);
                    if (trapped.term != .signal or trapped.term.signal != .ILL) return error.ExpectedIllegalInstruction;
                }
            }
            try out.interface.print("byte_loops-row route={s} mode={s} source_sha256={s} observations=32648 checked_traps=2 family_members=3 composition_functions=4 composed_functions=7 fallback_functions=0 local_fail=0\n", .{ route, mode, std.fmt.bytesToHex(hash, .lower) });
            try out.interface.flush();
        }
    }
    try out.interface.writeAll("summary byte-loops-diff population=retained-byte-loops-family-and-compositions routes=2 modes=3 programs_ok=6 observations=195888 checked_traps=12 family_members=3 composition_functions=4 local_fail=0\n");
    try out.interface.flush();
    success = true;
}

fn runChecked(a: std.mem.Allocator, io: std.Io, temp: common.TempDir, argv: []const []const u8, label: []const u8) !std.process.RunResult {
    const result = try std.process.run(a, io, .{ .argv = argv, .stdout_limit = .limited(128 * 1024 * 1024), .stderr_limit = .limited(32 * 1024 * 1024) });
    if (!common.termOk(result.term)) {
        defer common.freeRunResult(a, result);
        for ([_][]const u8{ "command.stdout", "command.stderr" }, [_][]const u8{ result.stdout, result.stderr }) |name, data| {
            const path = try temp.join(a, name);
            defer a.free(path);
            try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = path, .data = data });
        }
        std.debug.print("{s} failed: {any}\n{s}\n", .{ label, result.term, result.stderr });
        return error.BehavioralCommandFailed;
    }
    return result;
}
fn runToFile(a: std.mem.Allocator, io: std.Io, temp: common.TempDir, argv: []const []const u8, label: []const u8, output: []const u8) !void {
    const result = try runChecked(a, io, temp, argv, label);
    defer common.freeRunResult(a, result);
    try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = output, .data = result.stdout });
}
