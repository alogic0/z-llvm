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
const Product = struct { path: []const u8, copied_sha256: ?[]const u8 = null, native_link: bool = false };
fn argument(args: []const []const u8, wanted: []const u8) bool {
    for (args) |arg| if (same(arg, wanted)) return true;
    return false;
}
fn toolNamed(report: u.Value, key: []const u8, value: []const u8) bool {
    if (named(report, key, value)) return true;
    const chain = core.get(report, "toolchain") catch return false;
    return named(chain, key, value);
}
fn outputPath(e: *core.Engine, command: u.Value, raw: []const u8, binding: ?p.CacheOwner) ![]const u8 {
    if (std.fs.path.isAbsolute(raw)) return e.relative(raw);
    if (!p.relative(raw)) return error.AmbiguousOutputArgument;
    const cwd = if (core.has(command, "cwd", .string)) try core.str(command, "cwd") else if (binding) |b|
        if (same(b.working_directory, ".")) e.c.root else try e.absolute(b.working_directory)
    else
        return error.MissingOutputWorkingDirectory;
    return e.relative(try e.c.fmt("{s}/{s}", .{ cwd, raw }));
}
fn compilerArgs(args: []const []const u8) ![]const []const u8 {
    if (args.len == 0 or !same(args[0], "/usr/bin/time")) return args;
    // Only the recorded transparent time wrapper is supported, never a shell.
    var i: usize = 1;
    while (i < args.len) {
        if (same(args[i], "--")) return args[i + 1 ..];
        if ((same(args[i], "-f") or same(args[i], "-o")) and i + 1 < args.len) {
            i += 2;
        } else return error.UnsupportedOutputWrapper;
    }
    return error.UnsupportedOutputWrapper;
}
fn wholeCompiler(e: *core.Engine, args: []const []const u8, report: u.Value) !?Product {
    if (!core.eq(report, "schema", "whole-compiler-diagnostic-v1") or !core.eq(report, "status", "passed") or
        !try core.boolean(report, "build_completed") or try core.integer(report, "build_returncode") != 0) return null;
    var prefix: ?[]const u8 = null;
    for (args, 0..) |arg, i| {
        if (same(arg, "--help") or same(arg, "-h")) return null;
        if (same(arg, "--prefix") or same(arg, "-p")) {
            if (prefix != null or i + 1 == args.len or !std.fs.path.isAbsolute(args[i + 1])) return error.AmbiguousOutputArgument;
            prefix = args[i + 1];
        }
    }
    const install = prefix orelse return null;
    const path = try e.c.fmt("{s}/bin/zig", .{install});
    for ([_][]const u8{ "candidate", "rebuilt_candidate" }) |key| {
        const candidate = core.get(report, key) catch continue;
        if (!named(report, key, path)) continue;
        const sha = try core.str(candidate, "sha256");
        if (!p.hash(sha)) return error.InvalidOutputHash;
        return .{ .path = try e.relative(path), .copied_sha256 = sha };
    }
    return null;
}
fn product(e: *core.Engine, command: u.Value, report: u.Value, binding: ?p.CacheOwner) !?Product {
    var arena = std.heap.ArenaAllocator.init(e.c.gpa);
    defer arena.deinit();
    const args = try compilerArgs(try u.stringSlice(arena.allocator(), try core.get(command, "argv")));
    if (args.len < 2) return null;
    const tool = std.fs.path.basename(args[0]);
    // Direct copies require the report's exact compiler identity. Shell scripts,
    // implicit zig build destinations, and arbitrary copy commands stay unknown.
    if (same(tool, "cp")) {
        if (args.len != 3 or !std.fs.path.isAbsolute(args[2]) or !named(report, "compiler", args[1])) return null;
        return .{ .path = try e.relative(args[2]), .copied_sha256 = try core.str(report, "compiler_sha256") };
    }
    const compiler = named(report, "compiler", args[0]) or toolNamed(report, "zllvm", args[0]);
    const zig = same(tool, "zig") or named(report, "frontend", args[0]) or named(report, "emitter", args[0]) or toolNamed(report, "zig_emitter", args[0]);
    if (zig and same(args[1], "build")) return wholeCompiler(e, args, report);
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
            if (destination != null) return error.AmbiguousOutputArgument;
            destination = try outputPath(e, command, path, binding);
        }
        if (compiler and same(arg, "--emit=obj")) stdout_object = true;
    }
    if (stdout_object) {
        if (destination != null) return error.AmbiguousOutputArgument;
        destination = try e.relative(try core.str(command, "stdout"));
    }
    return if (destination) |path| .{ .path = path, .native_link = zig and same(args[1], "build-exe") and argument(args, "-fno-lld") and argument(args, "-fno-lto") } else null;
}
pub const Record = struct { output: Product, successful: bool, terminal: bool = false, stdout: []const u8, stderr: []const u8 };
fn records(e: *core.Engine, commands: p.Evidence, report: u.Value, binding: ?p.CacheOwner) ![]const Record {
    // owner() verifies the command hash before consulting this invocation-local
    // index; e.load also binds report/command paths to unchanged observations.
    const cache_key = try e.c.fmt("{s}\n{s}", .{ commands.path, if (binding) |b| b.working_directory else "" });
    if (e.command_output_records.get(cache_key)) |cached| return cached;
    var parsed = try e.load(e.c.gpa, commands.path);
    defer parsed.deinit();
    const single = [_]u.Value{parsed.value};
    const values = if (binding != null) &single else if (parsed.value == .array) parsed.value.array.items else return error.InvalidOutputCommands;
    var result: std.ArrayList(Record) = .empty;
    for (values) |command| {
        var output = (try product(e, command, report, binding)) orelse continue;
        if (!p.within(std.fs.path.dirname(commands.path).?, output.path) or !p.commandOutputName(.{ .path = output.path, .sha256 = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", .kind = .build_output })) continue;
        if (output.copied_sha256) |sha| output.copied_sha256 = try e.c.a.dupe(u8, sha);
        const stdout = try e.relative(try core.str(command, if (binding != null) "log" else "stdout"));
        const stderr = if (binding != null) stdout else try e.relative(try core.str(command, "stderr"));
        const terminal = core.eq(command, "outcome", "completed") and core.has(command, "actual_returncode", .integer) and core.has(command, "returncode", .integer);
        try result.append(e.c.a, .{ .output = output, .terminal = terminal, .successful = terminal and try core.integer(command, "actual_returncode") == 0 and try core.integer(command, "returncode") == 0, .stdout = stdout, .stderr = stderr });
    }
    try e.command_output_records.put(cache_key, result.items);
    return result.items;
}
fn owner(e: *core.Engine, r: p.Release, report: u.Value) !p.Evidence {
    if (r.command_owner) |binding| {
        if (r.state != .disposable or !same(std.fs.path.dirname(r.producer.path) orelse "", r.run_root) or
            !core.eq(report, "status", "finished") or !core.eq(report, "outcome", "completed") or
            try core.integer(report, "returncode") != 0 or try core.integer(report, "actual_returncode") != 0 or
            try core.integer(report, "started_ns") <= 0 or try core.integer(report, "finished_ns") <= try core.integer(report, "started_ns")) return error.OutputCommandNotSuccessful;
        if (!same(binding.working_directory, ".") and (!p.validationRun(binding.working_directory) or !p.within(r.run_root, binding.working_directory))) return error.InvalidOutputWorkingDirectory;
        const cwd = if (same(binding.working_directory, ".")) e.c.root else try e.absolute(binding.working_directory);
        if (core.has(report, "cwd", .string)) {
            if (!core.eq(report, "cwd", cwd)) return error.OutputWorkingDirectoryMismatch;
        } else if (binding.legacy_working_directory_review == null or binding.legacy_working_directory_review.?.len == 0) return error.MissingOutputWorkingDirectory;
        const commands = r.command_outputs orelse return error.MissingCommandOutputBinding;
        if (!same(commands.path, r.producer.path) or !same(commands.sha256, r.producer.sha256)) return error.UnboundOutputCommands;
        const log = try e.relative(try core.str(report, "log"));
        if (!p.within(r.run_root, log) or same(log, r.run_root)) return error.UnboundOutputLog;
        try e.check(commands);
        return commands;
    }
    if (r.state != .disposable or (!core.eq(report, "status", "passed") and !(r.closed_command_outputs and core.eq(report, "status", "failed"))) or
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
    for (try records(e, commands, report, r.command_owner)) |command| {
        const output = command.output;
        if (!same(output.path, a.path)) continue;
        if (!p.within(r.run_root, output.path)) return error.UnboundOutputPath;
        if (!command.successful and !(r.closed_command_outputs and command.terminal)) return error.OutputCommandNotSuccessful;
        if (r.command_owner != null and same(command.stdout, a.path)) return error.UnboundOutputLog;
        if (output.copied_sha256) |sha| if (!same(sha, a.sha256.?)) return error.CopiedCompilerHashMismatch;
        for ([_][]const u8{ command.stdout, command.stderr }) |log| {
            if (!same(log, a.path)) try @import("retired_logs.zig").keep(e, log, kept);
        }
        matched = true;
    }
    if (!matched) return error.MissingCommandOutputBinding;
}

/// The native ELF linker can leave a zeroed ELF header followed by an intact
/// program-header table when a wrong-symbol control fails to link. Recognize
/// only that structure, with independent failed-command and diagnostic proof.
pub fn incompleteNativeLink(e: *core.Engine, a: core.Action, r: p.Release, bytes: []const u8, size: u64) !bool {
    if (!r.closed_command_outputs or r.command_outputs == null or !same(std.fs.path.basename(a.path), "wrong-symbol") or bytes.len < 176) return false;
    for (bytes[0..64]) |byte| if (byte != 0) return false;
    const ph = bytes[64..120];
    const load = bytes[120..176];
    const table_size = std.mem.readInt(u64, ph[32..40], .little);
    const address = std.mem.readInt(u64, ph[16..24], .little);
    if (table_size < 112 or table_size > 56 * 128 or table_size % 56 != 0 or size < table_size + 64 or address < 64 or (address - 64) % 4096 != 0 or
        std.mem.readInt(u32, ph[0..4], .little) != 6 or std.mem.readInt(u32, ph[4..8], .little) != 4 or
        std.mem.readInt(u64, ph[8..16], .little) != 64 or std.mem.readInt(u64, ph[24..32], .little) != address or
        std.mem.readInt(u64, ph[40..48], .little) != table_size or std.mem.readInt(u64, ph[48..56], .little) != 8 or
        std.mem.readInt(u32, load[0..4], .little) != 1 or std.mem.readInt(u32, load[4..8], .little) != 4 or
        std.mem.readInt(u64, load[8..16], .little) != 0 or std.mem.readInt(u64, load[16..24], .little) != address - 64 or
        std.mem.readInt(u64, load[24..32], .little) != address - 64 or std.mem.readInt(u64, load[32..40], .little) != table_size + 64 or
        std.mem.readInt(u64, load[40..48], .little) != table_size + 64 or std.mem.readInt(u64, load[48..56], .little) != 4096) return false;
    var report = try e.load(e.c.gpa, r.producer.path);
    defer report.deinit();
    if (!core.eq(report.value, "schema", "execution-breadth-controls-v1") and !core.eq(report.value, "schema", "execution-breadth-controls-v2")) return false;
    const commands = try owner(e, r, report.value);
    var matched = false;
    for (try records(e, commands, report.value, r.command_owner)) |command| {
        if (!same(command.output.path, a.path)) continue;
        if (!command.terminal or command.successful or !command.output.native_link or same(command.stderr, a.path)) return false;
        const diagnostic = e.read(e.c.gpa, command.stderr, 1024 * 1024) catch return false;
        defer e.c.gpa.free(diagnostic);
        if (std.mem.indexOf(u8, diagnostic, "error: undefined symbol:") == null) return false;
        matched = true;
    }
    return matched;
}
pub fn request(e: *core.Engine, report_path: []const u8, reason: []const u8) !p.Release {
    return requestSelected(e, report_path, reason, null);
}
pub fn requestSelected(e: *core.Engine, report_path: []const u8, reason: []const u8, selected: ?[]const []const u8) !p.Release {
    return requestMode(e, report_path, reason, selected, false);
}
pub fn requestClosed(e: *core.Engine, report_path: []const u8, reason: []const u8) !p.Release {
    return requestMode(e, report_path, reason, null, true);
}
fn requestMode(e: *core.Engine, report_path: []const u8, reason: []const u8, selected: ?[]const []const u8, closed: bool) !p.Release {
    if (!p.validationOutput(report_path) or !same(std.fs.path.basename(report_path), "report.json") or reason.len == 0) return error.UnboundOutputOwner;
    const run_root = std.fs.path.dirname(report_path).?;
    if (!p.validationRun(run_root)) return error.UnboundOutputOwner;
    const commands = try e.c.fmt("{s}/commands.json", .{run_root});
    const result: p.Release = .{ .schema = "zllvm-storage-release-v1", .state = .disposable, .run_root = try e.c.a.dupe(u8, run_root), .reason = reason, .producer = .{ .path = try e.c.a.dupe(u8, report_path), .sha256 = try e.digest(report_path) }, .command_outputs = .{ .path = commands, .sha256 = try e.digest(commands) }, .retained = &.{}, .artifacts = &.{}, .closed_command_outputs = closed };
    var report = try e.load(e.c.gpa, report_path);
    defer report.deinit();
    return prepare(e, result, report.value, selected);
}
pub const ReceiptEntry = struct {
    producer: []const u8,
    working_directory: []const u8,
    legacy_working_directory_review: ?[]const u8 = null,
};
pub fn receipt(e: *core.Engine, entry: ReceiptEntry, reason: []const u8) !p.Release {
    if (!p.validationOutput(entry.producer) or reason.len == 0) return error.UnboundOutputOwner;
    const producer: p.Evidence = .{ .path = entry.producer, .sha256 = try e.digest(entry.producer) };
    const result: p.Release = .{ .schema = "zllvm-storage-release-v1", .state = .disposable, .run_root = std.fs.path.dirname(entry.producer).?, .reason = reason, .producer = producer, .retained = &.{}, .artifacts = &.{}, .command_outputs = producer, .command_owner = .{ .working_directory = entry.working_directory, .legacy_working_directory_review = entry.legacy_working_directory_review } };
    var parsed = try e.load(e.c.gpa, entry.producer);
    defer parsed.deinit();
    return prepare(e, result, parsed.value, null);
}
fn prepare(e: *core.Engine, initial: p.Release, report: u.Value, selected: ?[]const []const u8) !p.Release {
    var result = initial;
    _ = try owner(e, result, report);
    var artifacts: std.ArrayList(p.Artifact) = .empty;
    var seen = std.StringHashMap(void).init(e.c.a);
    for (try records(e, result.command_outputs.?, report, result.command_owner)) |command| {
        const output = command.output;
        if (!p.within(result.run_root, output.path) or seen.contains(output.path)) continue;
        if (selected) |paths| {
            var wanted = false;
            for (paths) |path| if (same(path, output.path)) {
                wanted = true;
                break;
            };
            if (!wanted) continue;
        }
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
    for (artifacts.items) |artifact| try verify(e, .{ .path = artifact.path, .run_root = result.run_root, .producer = result.producer.path, .kind = .build_output, .sha256 = artifact.sha256 }, result, report, &kept);
    // Each action's verifier retains its own command diagnostics. Repeating the
    // union of every sibling's logs on every action makes large suites quadratic.
    result.retained = try e.c.a.dupe(p.Retained, &.{.{ .path = result.command_outputs.?.path, .sha256 = result.command_outputs.?.sha256, .role = .result }});
    return result;
}
