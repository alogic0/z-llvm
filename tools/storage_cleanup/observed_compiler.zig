//! Legacy temporary compilers identified by a passed native comparison.
//! A saved successful compiler invocation and the report's exact compiler hash
//! replace the absent build receipt, never an existing or conflicting receipt.
const std = @import("std");
const core = @import("engine.zig");
const p = core.p;
const u = @import("../validation/common.zig");
fn same(a: []const u8, b: []const u8) bool {
    return std.mem.eql(u8, a, b);
}
fn invocation(e: *core.Engine, command: u.Value) !?[]const u8 {
    if (!core.has(command, "returncode", .integer) or try core.integer(command, "returncode") != 0) return null;
    if (command.object.get("outcome") != null and !core.eq(command, "outcome", "completed")) return null;
    if (command.object.get("actual_returncode") != null and (!core.has(command, "actual_returncode", .integer) or try core.integer(command, "actual_returncode") != 0)) return null;
    const argv = try core.get(command, "argv");
    if (argv != .array or argv.array.items.len < 2) return null;
    for (argv.array.items) |arg| if (arg != .string) return error.InvalidCompilerInvocation;
    const raw = argv.array.items[0].string;
    if (!std.fs.path.isAbsolute(raw) or !same(std.fs.path.basename(raw), "z_llvm")) return null;
    const path = e.relative(raw) catch return null;
    if (!p.validationOutput(path)) return null;
    for (argv.array.items[1..]) |arg| if (same(arg.string, "--emit=obj")) return path;
    return null;
}
fn reportHash(value: u.Value) ![]const u8 {
    if (!core.eq(value, "schema", "native-canary-v1") or !core.eq(value, "status", "passed")) return error.UnboundCompilerObservation;
    const sha = try core.str(value, "compiler_sha256");
    if (!p.hash(sha)) return error.InvalidCompilerObservationHash;
    return sha;
}
fn noBuildReceipt(e: *core.Engine, path: []const u8) !void {
    _ = e.metadata(try e.c.fmt("{s}.build.json", .{path})) catch |err| switch (err) {
        error.FileNotFound => return,
        else => return err,
    };
    return error.CanonicalBuildReceiptPresent;
}
pub fn verify(e: *core.Engine, a: core.Action, r: p.Release, value: u.Value, kept: *std.ArrayList(p.Evidence)) !void {
    const commands = r.compiler_observation orelse return error.UnboundCompilerObservation;
    if (r.state != .disposable or r.artifacts.len != 1 or a.kind != .build_output or !same(std.fs.path.basename(a.path), "z_llvm") or
        r.command_outputs != null or r.command_owner != null or !p.validationRun(r.run_root) or !p.within(r.run_root, a.path) or !p.within(r.run_root, r.producer.path) or
        !same(std.fs.path.basename(r.producer.path), "report.json") or !same(commands.path, try e.c.fmt("{s}/commands.json", .{std.fs.path.dirname(r.producer.path).?}))) return error.UnboundCompilerObservation;
    if (!same(try reportHash(value), a.sha256.?)) return error.CompilerObservationHashMismatch;
    try noBuildReceipt(e, a.path);
    try e.keep(kept, commands.path, commands.sha256);
    var parsed = try e.load(e.c.gpa, commands.path);
    defer parsed.deinit();
    if (parsed.value != .array) return error.InvalidCompilerInvocation;
    var matched = false;
    for (parsed.value.array.items) |command| {
        const path = (try invocation(e, command)) orelse continue;
        if (!same(path, a.path)) continue;
        const diagnostic = try e.relative(try core.str(command, "stderr"));
        if (!p.within(r.run_root, diagnostic) or same(diagnostic, a.path)) return error.UnboundCompilerDiagnostic;
        // --emit=obj stdout is another temporary product, not diagnostic data.
        try @import("retired_logs.zig").keep(e, diagnostic, kept);
        matched = true;
    }
    if (!matched) return error.NoObservedCompiler;
}
pub fn request(e: *core.Engine, report_path: []const u8, reason: []const u8) !p.Release {
    if (!p.validationOutput(report_path) or !same(std.fs.path.basename(report_path), "report.json") or reason.len == 0) return error.UnboundCompilerObservation;
    var report = try e.load(e.c.gpa, report_path);
    defer report.deinit();
    const sha = try e.c.a.dupe(u8, try reportHash(report.value));
    const commands: p.Evidence = .{ .path = try e.c.fmt("{s}/commands.json", .{std.fs.path.dirname(report_path).?}), .sha256 = "" };
    var parsed = try e.load(e.c.gpa, commands.path);
    defer parsed.deinit();
    if (parsed.value != .array) return error.InvalidCompilerInvocation;
    var compiler: ?[]const u8 = null;
    for (parsed.value.array.items) |command| {
        const path = (try invocation(e, command)) orelse continue;
        noBuildReceipt(e, path) catch |err| switch (err) {
            error.CanonicalBuildReceiptPresent => continue,
            else => return err,
        };
        const digest = e.digest(path) catch |err| switch (err) {
            error.FileNotFound => continue,
            else => return err,
        };
        if (!same(digest, sha)) continue;
        if (compiler) |old| if (!same(old, path)) return error.AmbiguousCompilerObservation;
        compiler = path;
    }
    const path = compiler orelse return error.NoObservedCompiler;
    var root = std.fs.path.dirname(report_path).?;
    while (!p.within(root, path)) root = std.fs.path.dirname(root) orelse return error.UnboundCompilerObservation;
    if (!p.validationRun(root)) return error.UnboundCompilerObservation;
    const result: p.Release = .{
        .schema = "zllvm-storage-release-v1",
        .state = .disposable,
        .run_root = root,
        .reason = reason,
        .producer = .{ .path = report_path, .sha256 = try e.digest(report_path) },
        .retained = &.{},
        .artifacts = try e.c.a.dupe(p.Artifact, &.{.{ .path = path, .sha256 = sha, .kind = .build_output }}),
        .compiler_observation = .{ .path = commands.path, .sha256 = try e.digest(commands.path) },
    };
    var kept: std.ArrayList(p.Evidence) = .empty;
    try verify(e, .{ .path = path, .run_root = root, .producer = report_path, .kind = .build_output, .sha256 = sha }, result, report.value, &kept);
    return result;
}
