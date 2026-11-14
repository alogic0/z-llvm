//! Closed test products, bound to explicit output arguments in saved commands.
const std = @import("std");
const core = @import("engine.zig");
const p = core.p;
const u = @import("../validation/common.zig");

fn same(a: []const u8, b: []const u8) bool {
    return std.mem.eql(u8, a, b);
}
fn named(v: u.Value, key: []const u8, value: []const u8) bool {
    if (v != .object) return false;
    const item = v.object.get(key) orelse return false;
    if (item == .string) return same(item.string, value);
    return core.eq(item, "path", value);
}
const Product = struct { path: []const u8, copied_sha256: ?[]const u8 = null };
fn product(e: *core.Engine, command: u.Value, report: u.Value) !?Product {
    var arena = std.heap.ArenaAllocator.init(e.c.gpa);
    defer arena.deinit();
    const args = try u.stringSlice(arena.allocator(), try core.get(command, "argv"));
    if (args.len < 2) return null;
    const tool = std.fs.path.basename(args[0]);
    // Direct copies require the report's exact compiler identity. Shell scripts,
    // implicit zig build destinations, and arbitrary copy commands stay unknown.
    if (same(tool, "cp")) {
        if (args.len != 3 or !std.fs.path.isAbsolute(args[2]) or !named(report, "compiler", args[1])) return null;
        return .{ .path = try e.relative(args[2]), .copied_sha256 = try core.str(report, "compiler_sha256") };
    }
    const compiler = named(report, "compiler", args[0]);
    const zig = same(tool, "zig") or named(report, "frontend", args[0]) or named(report, "emitter", args[0]);
    const cc = same(tool, "cc") or same(tool, "gcc") or same(tool, "clang") or std.mem.startsWith(u8, tool, "clang-");
    if (!compiler and !cc and !(zig and (same(args[1], "cc") or same(args[1], "build-exe") or same(args[1], "build-obj") or same(args[1], "build-lib")))) return null;
    var destination: ?[]const u8 = null;
    var stdout_object = false;
    for (args, 0..) |arg, i| {
        var value: ?[]const u8 = null;
        if (same(arg, "-o")) {
            if (i + 1 == args.len) return error.InvalidOutputArgument;
            value = args[i + 1];
        } else if (std.mem.startsWith(u8, arg, "-femit-bin=")) value = arg[11..];
        if (value) |path| {
            if (destination != null or !std.fs.path.isAbsolute(path)) return error.AmbiguousOutputArgument;
            destination = try e.relative(path);
        }
        if (compiler and same(arg, "--emit=obj")) stdout_object = true;
    }
    if (stdout_object) {
        if (destination != null) return error.AmbiguousOutputArgument;
        destination = try e.relative(try core.str(command, "stdout"));
    }
    return if (destination) |path| .{ .path = path } else null;
}
pub const Record = struct { output: Product, successful: bool, stdout: []const u8, stderr: []const u8 };
fn records(e: *core.Engine, commands: p.Evidence, report: u.Value) ![]const Record {
    // owner() verifies the command hash before consulting this invocation-local
    // index; e.load also binds report/command paths to unchanged observations.
    if (e.command_output_records.get(commands.path)) |cached| return cached;
    var parsed = try e.load(e.c.gpa, commands.path);
    defer parsed.deinit();
    if (parsed.value != .array) return error.InvalidOutputCommands;
    var result: std.ArrayList(Record) = .empty;
    for (parsed.value.array.items) |command| {
        var output = (try product(e, command, report)) orelse continue;
        if (!p.within(std.fs.path.dirname(commands.path).?, output.path) or !p.commandOutputName(.{ .path = output.path, .sha256 = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", .kind = .build_output })) continue;
        if (output.copied_sha256) |sha| output.copied_sha256 = try e.c.a.dupe(u8, sha);
        try result.append(e.c.a, .{ .output = output, .successful = core.eq(command, "outcome", "completed") and try core.integer(command, "actual_returncode") == 0 and try core.integer(command, "returncode") == 0, .stdout = try e.relative(try core.str(command, "stdout")), .stderr = try e.relative(try core.str(command, "stderr")) });
    }
    try e.command_output_records.put(try e.c.a.dupe(u8, commands.path), result.items);
    return result.items;
}
fn owner(e: *core.Engine, r: p.Release, report: u.Value) !p.Evidence {
    if (r.state != .disposable or !core.eq(report, "status", "passed") or
        !same(r.producer.path, try e.c.fmt("{s}/report.json", .{r.run_root}))) return error.UnboundOutputOwner;
    const commands = r.command_outputs orelse return error.MissingCommandOutputBinding;
    if (!same(commands.path, try e.c.fmt("{s}/commands.json", .{r.run_root}))) return error.UnboundOutputCommands;
    try e.check(commands);
    return commands;
}
pub fn verify(e: *core.Engine, a: core.Action, r: p.Release, report: u.Value, kept: *std.ArrayList(p.Evidence)) !void {
    const commands = try owner(e, r, report);
    try e.keep(kept, commands.path, commands.sha256);
    var matched = false;
    for (try records(e, commands, report)) |command| {
        const output = command.output;
        if (!same(output.path, a.path)) continue;
        if (!p.within(r.run_root, output.path)) return error.UnboundOutputPath;
        if (!command.successful) return error.OutputCommandNotSuccessful;
        if (output.copied_sha256) |sha| if (!same(sha, a.sha256.?)) return error.CopiedCompilerHashMismatch;
        for ([_][]const u8{ command.stdout, command.stderr }) |log| {
            if (!same(log, a.path)) try @import("retired_logs.zig").keep(e, log, kept);
        }
        matched = true;
    }
    if (!matched) return error.MissingCommandOutputBinding;
}
pub fn request(e: *core.Engine, report_path: []const u8, reason: []const u8) !p.Release {
    if (!p.candidate(report_path) or !same(std.fs.path.basename(report_path), "report.json") or reason.len == 0) return error.UnboundOutputOwner;
    const run_root = std.fs.path.dirname(report_path).?;
    if (!p.candidate(run_root)) return error.UnboundOutputOwner;
    const commands = try e.c.fmt("{s}/commands.json", .{run_root});
    var result: p.Release = .{ .schema = "zllvm-storage-release-v1", .state = .disposable, .run_root = try e.c.a.dupe(u8, run_root), .reason = reason, .producer = .{ .path = try e.c.a.dupe(u8, report_path), .sha256 = try e.digest(report_path) }, .command_outputs = .{ .path = commands, .sha256 = try e.digest(commands) }, .retained = &.{}, .artifacts = &.{} };
    var report = try e.load(e.c.gpa, report_path);
    defer report.deinit();
    _ = try owner(e, result, report.value);
    var artifacts: std.ArrayList(p.Artifact) = .empty;
    var seen = std.StringHashMap(void).init(e.c.a);
    for (try records(e, result.command_outputs.?, report.value)) |command| {
        const output = command.output;
        if (!p.within(run_root, output.path) or seen.contains(output.path)) continue;
        // The allowlist is additional to command provenance and compiled magic.
        if (!p.commandOutputName(.{ .path = output.path, .sha256 = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", .kind = .build_output })) continue;
        const m = e.metadata(output.path) catch |err| switch (err) {
            error.FileNotFound => continue,
            else => return err,
        };
        if (m.kind != .file) return error.NotRegularFile;
        try seen.put(output.path, {});
        try artifacts.append(e.c.a, .{ .path = output.path, .sha256 = try e.digest(output.path), .kind = .build_output });
    }
    if (artifacts.items.len == 0) return error.NoBoundOutputs;
    if (artifacts.items.len > e.config.max_candidate_entries) return error.TooManyOutputEntries;
    result.artifacts = artifacts.items;
    var kept: std.ArrayList(p.Evidence) = .empty;
    for (artifacts.items) |artifact| try verify(e, .{ .path = artifact.path, .run_root = run_root, .producer = report_path, .kind = .build_output, .sha256 = artifact.sha256 }, result, report.value, &kept);
    // Each action's verifier retains its own command diagnostics. Repeating the
    // union of every sibling's logs on every action makes large suites quadratic.
    result.retained = try e.c.a.dupe(p.Retained, &.{.{ .path = commands, .sha256 = result.command_outputs.?.sha256, .role = .result }});
    return result;
}
