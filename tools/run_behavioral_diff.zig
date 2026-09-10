const std = @import("std");
const common = @import("tool_common.zig");
const cases = [_][]const u8{ "arguments_branches", "loops_memory", "nested_calls", "register_pressure" };
const modes = [_][]const u8{ "ReleaseFast", "ReleaseSafe", "ReleaseSmall" };

pub fn main(init: std.process.Init) !void {
    var args = try std.process.Args.Iterator.initAllocator(init.minimal.args, init.gpa);
    defer args.deinit();
    _ = args.next();
    const flag = args.next();
    const filter = if (flag) |arg| if (std.mem.eql(u8, arg, "--case")) args.next() orelse return error.MissingCase else return error.UnknownOption else null;
    if (args.next() != null) return error.UnknownOption;
    try runFiltered(init, filter);
}

pub fn run(init: std.process.Init) !void {
    try runFiltered(init, null);
}

fn runFiltered(init: std.process.Init, filter: ?[]const u8) !void {
    const a = init.gpa;
    const io = init.io;
    const temp = try common.TempDir.init(a, io, "behavioral_diff");
    // Failures retain the exact small fixtures, objects, and process streams.
    var success = false;
    defer if (success) temp.deinit(a, io) else {
        std.debug.print("behavioral failure artifacts: {s}\n", .{temp.path});
        a.free(temp.path);
    };
    var buffer: [4096]u8 = undefined;
    var out = std.Io.File.stdout().writer(io, &buffer);
    var case_count: usize = 0;
    var function_count: usize = 0;
    for (cases) |id| {
        if (filter) |wanted| if (!std.mem.eql(u8, id, wanted)) continue;
        const fixture = try std.fmt.allocPrint(a, "test/behavioral/{s}.ll", .{id});
        defer a.free(fixture);
        function_count += try compare(init, temp, id, fixture, &out.interface);
        case_count += 1;
    }
    // Generated interactions cover wrapping integer arithmetic, signed division,
    // narrow truncation/extension, and signed/unsigned right shifts together.
    // Every generated case is a one-function stable reproducer keyed by its seed.
    for ([_]u32{ 1, 7, 0x5eed1234, 0xdeadbeef }) |seed| {
        const id = try std.fmt.allocPrint(a, "generated_{x}", .{seed});
        defer a.free(id);
        if (filter) |wanted| if (!std.mem.eql(u8, id, wanted)) continue;
        const fixture = try common.allocTempFile(a, temp, id, ".ll");
        defer a.free(fixture);
        const source = try std.fmt.allocPrint(a,
            \\define i32 @probe(i32 %x, i32 %y) {{
            \\entry:
            \\  %a = add i32 %x, {d}
            \\  %b = xor i32 %a, %y
            \\  %q = sdiv i32 %b, {d}
            \\  %s = ashr i32 %q, 2
            \\  %n = trunc i32 %s to i16
            \\  %wide = zext i16 %n to i32
            \\  %u = lshr i32 %b, 3
            \\  %t = add i32 %wide, %y
            \\  %r = xor i32 %t, %u
            \\  ret i32 %r
            \\}}
        , .{ @as(i32, @bitCast(seed)), @as(u32, 1) << @as(u5, @intCast(2 + seed % 5)) });
        defer a.free(source);
        try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = fixture, .data = source });
        function_count += try compare(init, temp, id, fixture, &out.interface);
        case_count += 1;
    }
    if (case_count == 0) return error.UnknownCase;
    try out.interface.print("summary behavioral-diff schema=1 population=standalone-ir-programs target=x86_64-linux-gnu cases={} harness_modes=3 inputs_per_case_mode=272 distinct_executed_functions={} programs_ok={} observations={} seed=5eed1234 composed_functions={} fallback_functions=0 local_fail=0\n", .{ case_count, function_count, case_count * 3, case_count * 3 * 272, function_count });
    try out.interface.flush();
    success = true;
}

fn compare(init: std.process.Init, temp: common.TempDir, id: []const u8, fixture: []const u8, out: *std.Io.Writer) !usize {
    const a = init.gpa;
    const io = init.io;
    const source = try std.Io.Dir.cwd().readFileAlloc(io, fixture, a, .limited(1024 * 1024));
    defer a.free(source);
    var digest: [32]u8 = undefined;
    std.crypto.hash.sha2.Sha256.hash(source, &digest, .{});
    const source_hash = std.fmt.bytesToHex(digest, .lower);
    const object = try common.allocTempFile(a, temp, id, ".o");
    defer a.free(object);
    try runToFile(a, io, temp, &.{ "zig", "build", "run", "--", "--target=x86_64-unknown-linux-gnu", "--generic-cfg-selector", "--emit=obj", fixture }, "z_llvm behavioral object", object);
    const owners = try common.allocTempFile(a, temp, id, ".owners");
    defer a.free(owners);
    try runToFile(a, io, temp, &.{ "zig", "build", "run", "--", "--target=x86_64-unknown-linux-gnu", "--generic-cfg-selector", "--emit=selection-owner-manifest", fixture }, "behavioral selection owners", owners);
    const ownership = try std.Io.Dir.cwd().readFileAlloc(io, owners, a, .limited(1024 * 1024));
    defer a.free(ownership);
    var lines = std.mem.splitScalar(u8, ownership, '\n');
    if (!std.mem.eql(u8, lines.next() orelse return error.MissingOwnership, "row_identity\tselection_owner")) return error.InvalidOwnership;
    var function_count: usize = 0;
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        const tab = std.mem.indexOfScalar(u8, line, '\t') orelse return error.InvalidOwnership;
        const owner = line[tab + 1 ..];
        if (!std.mem.eql(u8, owner, "composed_block") and !std.mem.eql(u8, owner, "composed_cfg")) return error.BehavioralFallback;
        try out.print("behavioral-owner case={s} function={s} owner={s}\n", .{ id, line[0..tab], owner });
        function_count += 1;
    }
    if (function_count == 0) return error.MissingOwnership;
    for (modes) |mode| {
        const stem = try std.fmt.allocPrint(a, "{s}-{s}", .{ id, mode });
        defer a.free(stem);
        const reference_obj = try common.allocTempFile(a, temp, stem, ".reference.o");
        defer a.free(reference_obj);
        const opt = if (std.mem.eql(u8, mode, "ReleaseSmall")) "-Oz" else if (std.mem.eql(u8, mode, "ReleaseFast")) "-O3" else "-O2";
        const compiled = try runChecked(a, io, temp, &.{ "clang-22", "-Wno-override-module", opt, "-c", fixture, "-o", reference_obj }, "LLVM behavioral reference");
        defer common.freeRunResult(a, compiled);
        const reference = try common.allocTempFile(a, temp, stem, ".reference");
        defer a.free(reference);
        const linked = try common.allocTempFile(a, temp, stem, ".linked");
        defer a.free(linked);
        for ([_][]const u8{ reference_obj, object }, [_][]const u8{ reference, linked }) |obj, exe| {
            const emit = try std.fmt.allocPrint(a, "-femit-bin={s}", .{exe});
            defer a.free(emit);
            const result = try runChecked(a, io, temp, &.{ "zig", "build-exe", "test/behavioral/harness.zig", obj, "-O", mode, emit }, "behavioral harness");
            common.freeRunResult(a, result);
        }
        const expected = try std.process.run(a, io, .{ .argv = &.{reference} });
        defer common.freeRunResult(a, expected);
        const actual = try std.process.run(a, io, .{ .argv = &.{linked} });
        defer common.freeRunResult(a, actual);
        for ([_][]const u8{ ".reference.stdout", ".linked.stdout", ".reference.stderr", ".linked.stderr" }, [_][]const u8{ expected.stdout, actual.stdout, expected.stderr, actual.stderr }) |suffix, data| {
            const path = try common.allocTempFile(a, temp, stem, suffix);
            defer a.free(path);
            try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = path, .data = data });
        }
        if (!common.termOk(expected.term) or !common.termOk(actual.term) or expected.stderr.len != 0 or actual.stderr.len != 0 or !std.mem.eql(u8, expected.stdout, actual.stdout) or std.mem.count(u8, actual.stdout, "\n") != 272) return error.BehavioralMismatch;
        try out.print("behavioral-row case={s} mode={s} reference=clang-22 source_sha256={s} input_seed=5eed1234 inputs=272 programs_ok=1\n", .{ id, mode, source_hash });
        try out.flush();
    }
    return function_count;
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
