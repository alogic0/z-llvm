//! Reviewed temporary outputs of the integrated validation runner.
//! Names select an adapter; successful producer/consumer records establish ownership.
const std = @import("std");
const core = @import("engine.zig");
const p = core.p;
const u = @import("../validation/common.zig");

fn same(a: []const u8, b: []const u8) bool {
    return std.mem.eql(u8, a, b);
}
pub fn consumerRoot(owner: []const u8) []const u8 {
    var parent: ?[]const u8 = owner;
    while (parent) |path| {
        if (std.mem.startsWith(u8, std.fs.path.basename(path), "integrated-")) return path;
        parent = std.fs.path.dirname(path);
    }
    return owner;
}
fn completed(command: u.Value) !void {
    if (!core.eq(command, "outcome", "completed") or try core.integer(command, "actual_returncode") != 0 or
        try core.integer(command, "returncode") != 0) return error.GeneratedCommandNotSuccessful;
}
fn count(args: []const []const u8, value: []const u8) usize {
    var n: usize = 0;
    for (args) |arg| if (same(arg, value)) {
        n += 1;
    };
    return n;
}
fn option(args: []const []const u8, key: []const u8, value: []const u8) bool {
    if (count(args, key) != 1) return false;
    for (args, 0..) |arg, i| if (same(arg, key)) return i + 1 < args.len and same(args[i + 1], value);
    return false;
}
fn commandLogs(e: *core.Engine, command: u.Value, kept: *std.ArrayList(p.Evidence)) !void {
    for ([_][]const u8{ "stdout", "stderr" }) |key| try @import("retired_logs.zig").keep(e, try core.str(command, key), kept);
}

pub fn verify(e: *core.Engine, a: core.Action, r: p.Release, producer: u.Value, kept: *std.ArrayList(p.Evidence)) !void {
    if (r.state != .disposable or !core.eq(producer, "status", "passed") or
        !same(r.producer.path, try e.c.fmt("{s}/report.json", .{r.run_root}))) return error.UnboundGeneratedProducer;
    const rows = try core.get(producer, "rows");
    if (rows != .array or rows.array.items.len == 0) return error.MissingGeneratedRows;
    if (same(std.fs.path.basename(a.path), "capture-zllvm")) {
        if (a.kind != .build_output or !same(std.fs.path.dirname(a.path).?, r.run_root) or
            !core.eq(producer, "schema", "real-program-v1")) return error.UnboundCaptureHelper;
        const provenance = try core.get(producer, "tool_provenance");
        if (!same(try core.str(provenance, "binary_sha256"), a.sha256.?)) return error.CaptureRunnerHashMismatch;
        for (rows.array.items) |row| if (!core.eq(row, "status", "matched")) return error.IncompleteGeneratedComparison;
        // program.zig copies /proc/self/exe here before running the selected modes.
        // Its provenance hash identifies that exact runner, not the tested compiler.
        try e.keep(kept, try e.c.fmt("{s}/commands.json", .{r.run_root}), null);
        return;
    }
    if (a.kind != .generated_assembly or !same(std.fs.path.basename(a.path), "linked-harness.s") or
        !core.eq(producer, "schema", "execution-breadth-controls-v2") or
        !same(std.fs.path.basename(r.run_root), "execution-breadth-controls")) return error.UnboundGeneratedAssembly;
    const directory = std.fs.path.dirname(a.path).?;
    const mode_dir = std.fs.path.dirname(directory) orelse return error.UnboundGeneratedAssembly;
    if (!same(std.fs.path.dirname(mode_dir) orelse "", r.run_root)) return error.UnboundGeneratedAssembly;
    const object = try e.c.fmt("{s}/linked-harness.o", .{directory});
    var matched: ?u.Value = null;
    for (rows.array.items) |row| {
        const harness = try core.get(row, "harness");
        if (!same(try e.relative(try core.str(harness, "object")), object)) continue;
        if (matched != null) return error.AmbiguousGeneratedOwner;
        if (!core.eq(row, "status", "passed") or !core.eq(row, "mode", std.fs.path.basename(mode_dir))) return error.IncompleteGeneratedComparison;
        matched = harness;
    }
    const harness = matched orelse return error.UnboundGeneratedAssembly;
    const source = try e.c.fmt("{s}/linked.zig", .{directory});
    if (!same(try e.relative(try core.str(harness, "source")), source)) return error.UnboundHarnessSource;
    const command_path = try e.c.fmt("{s}/commands.json", .{r.run_root});
    try e.keep(kept, command_path, null);
    var parsed = try e.load(e.c.gpa, command_path);
    defer parsed.deinit();
    if (parsed.value != .array) return error.InvalidGeneratedCommands;
    const indexes = try core.get(harness, "producer_commands");
    if (indexes != .array or indexes.array.items.len != 2) return error.InvalidGeneratedCommandIndexes;
    var commands: [2]u.Value = undefined;
    var previous: ?usize = null;
    for (indexes.array.items, 0..) |index, i| {
        if (index != .integer or index.integer < 0 or index.integer >= parsed.value.array.items.len) return error.InvalidGeneratedCommandIndexes;
        const n: usize = @intCast(index.integer);
        if (previous) |old| if (n != old + 1) return error.InvalidGeneratedCommandIndexes;
        previous = n;
        commands[i] = parsed.value.array.items[n];
        try completed(commands[i]);
    }
    const compile = try u.stringSlice(e.c.a, try core.get(commands[0], "argv"));
    const assemble = try u.stringSlice(e.c.a, try core.get(commands[1], "argv"));
    const emitter = try core.str(try core.get(harness, "emitter"), "path");
    const asm_absolute = try e.absolute(a.path);
    const source_absolute = try e.absolute(source);
    const object_absolute = try e.absolute(object);
    if (compile.len < 4 or !same(compile[0], emitter) or !same(compile[1], "build-exe") or
        count(compile, source_absolute) != 1 or count(compile, "-fno-emit-bin") != 1 or
        count(compile, try e.c.fmt("-femit-asm={s}", .{asm_absolute})) != 1) return error.UnboundAssemblyProducer;
    var asm_options: usize = 0;
    for (compile) |arg| if (std.mem.startsWith(u8, arg, "-femit-asm=")) {
        asm_options += 1;
    };
    if (asm_options != 1) return error.UnboundAssemblyProducer;
    if (assemble.len < 4 or !same(assemble[0], emitter) or !same(assemble[1], "cc") or
        !option(assemble, "-x", "assembler") or !option(assemble, "-c", asm_absolute) or
        !option(assemble, "-o", object_absolute)) return error.UnboundAssemblyConsumer;
    for (commands) |command| try commandLogs(e, command, kept);
}

pub fn request(e: *core.Engine, path: []const u8, reason: []const u8) !p.Release {
    if (!p.candidate(path) or reason.len == 0) return error.InvalidGeneratedPath;
    const capture = same(std.fs.path.basename(path), "capture-zllvm");
    if (!capture and !same(std.fs.path.basename(path), "linked-harness.s")) return error.InvalidGeneratedPath;
    var owner = std.fs.path.dirname(path).?;
    if (!capture) owner = std.fs.path.dirname(std.fs.path.dirname(owner) orelse return error.InvalidGeneratedPath) orelse return error.InvalidGeneratedPath;
    const producer = try e.c.fmt("{s}/report.json", .{owner});
    const artifacts = try e.c.a.dupe(p.Artifact, &.{.{ .path = try e.c.a.dupe(u8, path), .sha256 = try e.digest(path), .kind = if (capture) .build_output else .generated_assembly }});
    var result: p.Release = .{ .schema = "zllvm-storage-release-v1", .state = .disposable, .run_root = owner, .reason = reason, .producer = .{ .path = producer, .sha256 = try e.digest(producer) }, .retained = &.{}, .artifacts = artifacts };
    var parsed = try e.load(e.c.gpa, producer);
    defer parsed.deinit();
    var kept: std.ArrayList(p.Evidence) = .empty;
    try verify(e, .{ .path = artifacts[0].path, .run_root = owner, .producer = producer, .kind = if (capture) .build_output else .generated_assembly, .sha256 = artifacts[0].sha256 }, result, parsed.value, &kept);
    const retained = try e.c.a.alloc(p.Retained, kept.items.len);
    for (kept.items, retained) |ev, *row| row.* = .{ .path = try e.relative(ev.path), .sha256 = ev.sha256, .role = .result };
    result.retained = retained;
    return result;
}
