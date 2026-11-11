//! Explicit reuse of a completed local backend invocation. A failed outer link
//! is eligible; failed/changed backend output and reuse chains are not.
const std = @import("std");
const u = @import("common.zig");
const reports = @import("whole_compiler_report.zig");
const elf = @import("object_contract.zig");
const toolchain = @import("toolchain.zig");

fn identity(c: *u.Context, path: []const u8) !u.Value {
    return u.toValue(c.a, .{ .path = path, .sha256 = try c.digest(path), .bytes = (try std.Io.Dir.cwd().statFile(c.io, path, .{})).size });
}

/// Only artifact destinations differ between otherwise identical requests.
pub fn semanticArguments(a: std.mem.Allocator, argv: []const []const u8) !u.Value {
    if (argv.len < 2) return error.InvalidRetainedArguments;
    var result = u.array(a);
    for (argv, 0..) |arg, i| {
        const value = if (i == 0) "BACKEND" else if (i == argv.len - 1) "INPUT" else value: {
            for ([_][]const u8{ "--profile=", "--selection-owner-output=", "--profile-events=" }) |prefix| {
                if (std.mem.startsWith(u8, arg, prefix)) break :value prefix;
            }
            break :value arg;
        };
        try u.add(&result, u.s(value));
    }
    return result;
}

pub fn sourceEligible(invocation: u.Value) !void {
    if (!u.json.is(try u.get(invocation, "failure_stage"), "none") or
        !(try u.get(invocation, "object_complete")).bool or !(try u.get(invocation, "process_completed")).bool or
        (try u.get(invocation, "returncode")).integer != 0) return error.RetainedBackendDidNotPass;
    if (invocation.object.get("backend_executed")) |executed| if (executed != .bool or !executed.bool) return error.RetainedReuseChain;
    const commands = (try u.get(invocation, "commands")).array.items;
    if (commands.len != 1 or (try u.get(commands[0], "actual_returncode")).integer != 0 or
        (try u.get(commands[0], "returncode")).integer != 0 or !u.json.is(try u.get(commands[0], "outcome"), "completed")) return error.RetainedCommandDidNotPass;
}

pub fn tryReplay(c: *u.Context, prior_root: []const u8, compiler: []const u8, directory: []const u8, argv: []const []const u8, base: u.Value) !?u.Value {
    const prior_path = try c.join(&.{ prior_root, "report.json" });
    const prior = try c.load(prior_path);
    if (!u.json.is(try u.get(prior, "schema"), "whole-compiler-diagnostic-v1")) return error.RetainedSchemaMismatch;
    if (!(try u.get(prior, "source_and_backend_verified")).bool or prior.object.contains("runner_error")) return error.UnverifiedRetainedSource;
    const backend = try u.get(prior, "backend");
    if (!std.mem.eql(u8, try u.str(backend, "sha256"), try c.digest(compiler))) return error.RetainedBackendMismatch;
    const current_build = try toolchain.compilerBuild(c, compiler);
    const prior_build = try u.get(prior, "backend_build");
    if (!u.json.is(try u.get(current_build, "status"), "recorded") or !u.json.is(try u.get(prior_build, "status"), "recorded")) return error.RetainedBuildReceiptRequired;
    const source_map = try u.get(try u.get(current_build, "identity"), "source_sha256");
    if (!u.json.eql(source_map, try u.get(try u.get(prior_build, "identity"), "source_sha256"))) return error.RetainedCompilerSourceMismatch;
    for (source_map.object.keys(), source_map.object.values()) |path, digest| {
        if (!std.mem.eql(u8, try c.digest(try c.join(&.{path})), digest.string)) return error.RetainedCompilerSourceMismatch;
    }
    const input_sha = try u.str(try u.get(base, "input"), "sha256");
    var matches = u.array(c.a);
    if (prior.object.get("invocations")) |invocations| {
        for (invocations.array.items) |invocation| if (u.json.is(try u.get(try u.get(invocation, "input"), "sha256"), input_sha)) try u.add(&matches, invocation);
    } else if (prior.object.get("invocation")) |invocation| {
        if (u.json.is(try u.get(try u.get(invocation, "input"), "sha256"), input_sha)) try u.add(&matches, invocation);
    }
    if (matches.array.items.len == 0) return null;
    if (matches.array.items.len != 1) return error.AmbiguousRetainedInput;
    const source = matches.array.items[0];
    try sourceEligible(source);
    const source_input = try u.str(try u.get(source, "input"), "path");
    if (!std.mem.eql(u8, input_sha, try c.digest(source_input))) return error.RetainedInputChanged;
    const source_dir = std.fs.path.dirname(source_input) orelse return error.InvalidRetainedInput;
    const source_argv = try c.load(try c.join(&.{ source_dir, "effective-argv.json" }));
    const source_args = try u.stringSlice(c.a, source_argv);
    if (!u.json.eql(try semanticArguments(c.a, source_args), try semanticArguments(c.a, argv))) return null;
    const recorded = (try u.get((try u.get(source, "commands")).array.items[0], "argv")).array.items;
    if (recorded.len < source_args.len or !u.json.eql(try u.strings(c.a, source_args), try u.toValue(c.a, recorded[recorded.len - source_args.len ..]))) return error.RetainedCommandMismatch;
    if (!std.mem.eql(u8, try c.digest(source_args[0]), try c.digest(compiler))) return error.RetainedBackendMismatch;
    const profile_bytes = try c.read(try c.join(&.{ source_dir, "profile.json" }));
    const profile = (try u.json.parse(c.a, profile_bytes)).value;
    const owners = try c.read(try c.join(&.{ source_dir, "owners.tsv" }));
    try reports.validateSuccess(c.a, try u.get(source, "selection"), profile, owners);
    const source_object = try u.get(source, "object");
    const object_path = try u.str(source_object, "path");
    const object_bytes = try c.read(object_path);
    if (!std.mem.eql(u8, try u.digestBytes(c.a, object_bytes), try u.str(source_object, "sha256"))) return error.RetainedObjectChanged;
    const contract = try elf.parse(c.a, object_bytes);
    try reports.validateObject(c.a, contract, profile);
    var result = base;
    try c.write(try c.join(&.{ directory, "local.o" }), object_bytes);
    try c.write(try c.join(&.{ directory, "profile.json" }), profile_bytes);
    try c.write(try c.join(&.{ directory, "owners.tsv" }), owners);
    try c.copy(try c.join(&.{ source_dir, "backend.stderr" }), try c.join(&.{ directory, "backend.stderr" }));
    if (source.object.get("profile_events")) |events| {
        const path = try u.str(events, "path");
        if (!std.mem.eql(u8, try c.digest(path), try u.str(events, "sha256"))) return error.RetainedEventsChanged;
        const destination = try c.join(&.{ directory, "profile.events.jsonl" });
        try c.copy(path, destination);
        if (!std.mem.eql(u8, try c.digest(destination), try u.str(events, "sha256"))) return error.RetainedEventsChanged;
        try u.put(c.a, &result, "profile_events", try identity(c, destination));
        try u.put(c.a, &result, "profile_progress", try u.get(source, "profile_progress"));
    }
    try c.writeJson(try c.join(&.{ directory, "object-contract.json" }), contract);
    try c.writeJson(try c.join(&.{ directory, "reuse-source-report.json" }), source);
    try c.writeJson(try c.join(&.{ directory, "reuse-source-commands.json" }), try u.get(source, "commands"));
    try c.writeJson(try c.join(&.{ directory, "commands.json" }), u.array(c.a));
    try u.put(c.a, &result, "commands", u.array(c.a));
    try u.put(c.a, &result, "backend_executed", u.b(false));
    try u.put(c.a, &result, "execution_kind", u.s("verified-retained-local-object"));
    try u.put(c.a, &result, "profile_origin", u.s("retained measurement; not a new backend execution"));
    try u.put(c.a, &result, "reuse", try u.toValue(c.a, .{
        .source_report = prior_path,
        .source_report_sha256 = try c.digest(prior_path),
        .source_input = source_input,
        .source_object = object_path,
        .source_backend_actual_returncode = 0,
        .source_backend_process_completed = true,
        .compiler_source_files = source_map.object.count(),
        .backend_sha256 = try c.digest(compiler),
        .semantic_arguments_match = true,
        .profile_sha256 = try u.digestBytes(c.a, profile_bytes),
        .owners_sha256 = try u.digestBytes(c.a, owners),
    }));
    try u.put(c.a, &result, "profile", u.s(try c.join(&.{ directory, "profile.json" })));
    try u.put(c.a, &result, "selection", try u.get(source, "selection"));
    try u.put(c.a, &result, "diagnostic_tail", try u.get(source, "diagnostic_tail"));
    try u.put(c.a, &result, "object", try identity(c, try c.join(&.{ directory, "local.o" })));
    try u.put(c.a, &result, "object_complete", u.b(true));
    try u.put(c.a, &result, "failure_stage", u.s("none"));
    try u.put(c.a, &result, "returncode", u.n(0));
    try u.put(c.a, &result, "returncode_scope", u.s("capture delivery; source backend exit recorded in reuse"));
    try u.put(c.a, &result, "process_completed", u.b(true));
    try u.put(c.a, &result, "time_record", u.s("retained object verified; backend not executed"));
    try c.writeJson(try c.join(&.{ directory, "report.json" }), result);
    return result;
}

test "reuse normalizes only artifact destinations and keeps semantic flags" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const a = arena.allocator();
    const old = try semanticArguments(a, &.{ "old/backend", "--emit=obj", "--input-limit=18", "--profile=old/profile", "old/input" });
    const same = try semanticArguments(a, &.{ "new/backend", "--emit=obj", "--input-limit=18", "--profile=new/profile", "new/input" });
    const changed = try semanticArguments(a, &.{ "new/backend", "--emit=obj", "--input-limit=19", "--profile=new/profile", "new/input" });
    try std.testing.expect(u.json.eql(old, same));
    try std.testing.expect(!u.json.eql(old, changed));
}

test "reuse rejects failed backend commands and reuse chains" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const a = arena.allocator();
    var source = try u.toValue(a, .{ .failure_stage = "none", .object_complete = true, .process_completed = true, .returncode = 0, .commands = .{.{ .actual_returncode = 0, .returncode = 0, .outcome = "completed" }} });
    try sourceEligible(source);
    try u.put(a, &source, "backend_executed", u.b(false));
    try std.testing.expectError(error.RetainedReuseChain, sourceEligible(source));
    try u.put(a, &source, "backend_executed", u.b(true));
    try u.put(a, &source, "object_complete", u.b(false));
    try std.testing.expectError(error.RetainedBackendDidNotPass, sourceEligible(source));
}
