//! Read-only full-stream audits for an explicit list of live native traces.
const std = @import("std");
const u = @import("validation/common.zig");
const storage = @import("storage_cleanup/engine.zig");
const core = @import("storage_cleanup/event_audit_core.zig");
const p = storage.p;
const fa = storage.fa;
const Entry = struct { path: []const u8, producer: p.Evidence, top_report: p.Evidence, backend_report: p.Evidence };
const Plan = struct { schema: []const u8, traces: []const Entry };
const Sources = struct { core: p.Evidence, driver: p.Evidence, binary_sha256: []const u8, revision: ?[]const u8 = null };
const Finding = struct { path: []const u8, audit: ?[]const u8 = null, verified: bool = false, error_code: ?[]const u8 = null };
const Failure = struct { code: []const u8, record: u64, byte_offset: u64 };

fn countsMatch(a: core.Counters, value: u.Value) bool {
    inline for (@typeInfo(core.Counters).@"struct".field_names) |key| {
        const n = storage.integer(value, key) catch return false;
        if (n < 0 or n != @field(a, key)) return false;
    }
    return true;
}

fn failureNamesMatch(a: std.mem.Allocator, actual: []const core.FailedFunction, expected: u.Value) !bool {
    if (expected != .array or actual.len != expected.array.items.len) return false;
    var names = std.StringHashMap(void).init(a);
    defer names.deinit();
    for (expected.array.items) |row| {
        const name = storage.str(row, "function") catch return false;
        if (names.contains(name)) return false;
        try names.put(name, {});
    }
    for (actual) |row| if (!names.contains(row.name)) return false;
    return true;
}

fn binding(e: *storage.Engine, value: u.Value) !p.Evidence {
    const result: p.Evidence = .{ .path = try e.relative(try storage.str(value, "path")), .sha256 = try storage.str(value, "sha256") };
    try e.check(result);
    return result;
}

fn buildArgs(args: []const []const u8) ![]const []const u8 {
    var command = args;
    if (command.len > 0 and std.mem.eql(u8, command[0], "/usr/bin/time")) {
        var i: usize = 1;
        while (i < command.len and !std.mem.eql(u8, command[i], "--")) {
            if (i + 1 >= command.len or (!std.mem.eql(u8, command[i], "-f") and !std.mem.eql(u8, command[i], "-o"))) return error.UnboundProducer;
            i += 2;
        }
        if (i == command.len) return error.UnboundProducer;
        command = command[i + 1 ..];
    }
    if (command.len > 0 and std.mem.eql(u8, command[0], "/usr/bin/taskset")) {
        if (command.len < 4 or !std.mem.eql(u8, command[1], "--cpu-list") or !std.mem.eql(u8, command[2], "0")) return error.UnboundProducer;
        command = command[3..];
    }
    return command;
}

fn validateEntry(e: *storage.Engine, entry: Entry, producer: u.Value) !i64 {
    if (!p.relative(entry.path) or !p.candidate(entry.path) or !std.mem.eql(u8, std.fs.path.basename(entry.path), "profile.events.jsonl")) return error.InvalidTracePath;
    const run = std.fs.path.dirname(entry.top_report.path) orelse return error.InvalidTraceScope;
    if (!p.candidate(run) or !p.within(run, entry.path) or !p.within(run, entry.backend_report.path)) return error.InvalidTraceScope;
    // Older whole-build runs kept their terminal report and command records,
    // but not a separate run_checked receipt. Bind that actual report to its
    // successful build prefix and the exact embedded capture, never synthesize
    // a replacement producer receipt.
    if (std.mem.eql(u8, entry.producer.path, entry.top_report.path)) {
        if (!storage.eq(producer, "schema", "whole-compiler-diagnostic-v1") or !storage.eq(producer, "status", "passed") or
            !try storage.boolean(producer, "build_completed") or try storage.integer(producer, "build_returncode") != 0 or
            !try storage.boolean(producer, "all_hook_objects_complete") or !try storage.boolean(producer, "source_and_backend_verified")) return error.ProducerNotTerminal;
        const self_root = try e.c.fmt("{s}/self-rebuild", .{run});
        const self_rebuild = p.within(self_root, entry.path);
        if (self_rebuild and (!try storage.boolean(producer, "self_rebuild_passed") or try storage.boolean(producer, "self_rebuild_backend_reuse"))) return error.ProducerNotTerminal;
        const build_root = if (self_rebuild) self_root else run;
        const commands = try storage.get(producer, "commands");
        if (commands != .array) return error.UnboundProducer;
        var build_bound = false;
        for (commands.array.items) |command| {
            const args = try buildArgs(try u.stringSlice(e.c.a, try storage.get(command, "argv")));
            if (args.len < 2 or !std.mem.eql(u8, std.fs.path.basename(args[0]), "zig") or !std.mem.eql(u8, args[1], "build")) continue;
            if (self_rebuild) {
                const expected = try e.c.fmt("{s}/install/bin/zig", .{run});
                if (!std.mem.eql(u8, args[0], expected) and !std.mem.eql(u8, args[0], try e.absolute(expected))) continue;
            }
            var warmup = false;
            var prefix: ?[]const u8 = null;
            for (args, 0..) |arg, i| {
                if (std.mem.eql(u8, arg, "--help") or std.mem.eql(u8, arg, "-h")) warmup = true;
                if (std.mem.eql(u8, arg, "--prefix")) {
                    if (prefix != null or i + 1 == args.len) return error.UnboundProducer;
                    prefix = try e.relative(args[i + 1]);
                }
            }
            if (!warmup and prefix != null and std.mem.eql(u8, prefix.?, try e.c.fmt("{s}/install", .{build_root}))) {
                if (!storage.eq(command, "outcome", "completed") or try storage.integer(command, "actual_returncode") != 0 or try storage.integer(command, "returncode") != 0) return error.ProducerNotTerminal;
                build_bound = true;
            }
        }
        if (!build_bound) return error.UnboundProducer;
        const invocations = try storage.get(producer, if (self_rebuild) "self_rebuild_invocations" else "invocations");
        if (invocations != .array) return error.UnboundProducer;
        var matches: usize = 0;
        var backend = try e.load(e.c.gpa, entry.backend_report.path);
        defer backend.deinit();
        for (invocations.array.items) |invocation| {
            if (!std.mem.eql(u8, try e.relative(try storage.str(invocation, "directory")), std.fs.path.dirname(entry.path).?)) continue;
            if (!try storage.boolean(invocation, "process_completed") or !try storage.boolean(invocation, "object_complete") or try storage.integer(invocation, "returncode") != 0) return error.ProducerNotTerminal;
            for ([_][]const u8{ "profile_events", "input" }) |key| {
                const embedded = try storage.get(invocation, key);
                const actual = try storage.get(backend.value, key);
                if (!std.mem.eql(u8, try e.relative(try storage.str(embedded, "path")), try e.relative(try storage.str(actual, "path"))) or
                    !std.mem.eql(u8, try storage.str(embedded, "sha256"), try storage.str(actual, "sha256"))) return error.UnboundProducer;
            }
            matches += 1;
        }
        if (matches != 1) return error.UnboundProducer;
        return 0;
    }
    if (!storage.eq(producer, "status", "finished") or !storage.eq(producer, "outcome", "completed")) return error.ProducerNotTerminal;
    _ = try storage.integer(producer, "actual_returncode");
    const argv = try storage.get(producer, "argv");
    if (argv != .array) return error.UnboundProducer;
    var bound = false;
    for (argv.array.items, 0..) |arg, i| {
        if (arg == .string and std.mem.eql(u8, arg.string, "--output-root") and i + 1 < argv.array.items.len and argv.array.items[i + 1] == .string) {
            if (std.mem.eql(u8, run, try e.relative(argv.array.items[i + 1].string))) bound = true;
        }
    }
    if (!bound) return error.UnboundProducer;
    return storage.integer(producer, "actual_returncode");
}

fn auditOne(e: *storage.Engine, entry: Entry, destination: []const u8, sources: Sources) !bool {
    for ([_]p.Evidence{ entry.producer, entry.top_report, entry.backend_report }) |control| {
        if (!p.relative(control.path)) return error.InvalidEvidencePath;
        try e.check(control);
    }
    var producer = try e.load(e.c.gpa, entry.producer.path);
    defer producer.deinit();
    const producer_returncode = try validateEntry(e, entry, producer.value);
    var top = try e.load(e.c.gpa, entry.top_report.path);
    defer top.deinit();
    const compiler = try storage.get(top.value, "backend");
    _ = try e.relative(try storage.str(compiler, "path"));
    if (!p.hash(try storage.str(compiler, "sha256"))) return error.InvalidCompilerIdentity;
    var backend = try e.load(e.c.gpa, entry.backend_report.path);
    defer backend.deinit();
    const report = backend.value;
    if (!try storage.boolean(report, "process_completed")) return error.ProducerNotTerminal;
    const reported = try storage.get(report, "profile_events");
    if (!std.mem.eql(u8, entry.path, try e.relative(try storage.str(reported, "path")))) return error.TraceReportPathMismatch;
    const expected_sha = try storage.str(reported, "sha256");
    if (!p.hash(expected_sha)) return error.InvalidTraceHash;
    const input = try binding(e, try storage.get(report, "input"));
    const metadata = try e.metadata(entry.path);
    if (metadata.kind != .file) return error.NotRegularFile;
    var parent = try fa.metadata.openRoot(e.c.io, try e.absolute(std.fs.path.dirname(entry.path).?));
    defer parent.close(e.c.io);
    const name = std.fs.path.basename(entry.path);
    const z = try e.c.a.dupeSentinel(u8, name, 0);
    const fd = std.os.linux.openat(parent.handle, z, .{ .ACCMODE = .RDONLY, .CLOEXEC = true, .NOFOLLOW = true, .NONBLOCK = true, .NOCTTY = true }, 0);
    if (std.os.linux.errno(fd) != .SUCCESS) return error.OpenFailed;
    const file: std.Io.File = .{ .handle = @intCast(fd), .flags = .{ .nonblocking = true } };
    defer file.close(e.c.io);
    if (!metadata.eql(try fa.metadata.descriptor(file.handle))) return error.OpenedFileChanged;
    var state = core.State.init(e.c.a);
    defer state.deinit();
    var event_arena = std.heap.ArenaAllocator.init(e.c.gpa);
    defer event_arena.deinit();
    var reader = file.readerStreaming(e.c.io, try e.c.a.alloc(u8, 1024 * 1024));
    var hash = std.crypto.hash.sha2.Sha256.init(.{});
    var offset: u64 = 0;
    var records: u64 = 0;
    var failure: ?Failure = null;
    var newline_complete = true;
    const started = std.Io.Timestamp.now(e.c.io, .awake);
    while (true) {
        const line = reader.interface.takeDelimiterInclusive('\n') catch |err| switch (err) {
            error.EndOfStream => {
                const tail = reader.interface.buffer[reader.interface.seek..reader.interface.end];
                if (tail.len != 0) {
                    hash.update(tail);
                    newline_complete = false;
                    if (failure == null) failure = .{ .code = "UnterminatedRecord", .record = records, .byte_offset = offset };
                    offset += tail.len;
                }
                break;
            },
            else => return err,
        };
        hash.update(line);
        const begin = offset;
        offset += line.len;
        records += 1;
        if (failure != null) continue;
        _ = event_arena.reset(.retain_capacity);
        const event = std.json.parseFromSliceLeaky(core.Event, event_arena.allocator(), line, .{ .ignore_unknown_fields = true }) catch |err| {
            failure = .{ .code = @errorName(err), .record = records - 1, .byte_offset = begin };
            continue;
        };
        state.feed(event, begin, offset) catch |err| {
            failure = .{ .code = @errorName(err), .record = records - 1, .byte_offset = begin };
        };
    }
    if (failure == null) state.finish() catch |err| {
        failure = .{ .code = @errorName(err), .record = records, .byte_offset = offset };
    };
    const unchanged = metadata.eql(try fa.metadata.descriptor(file.handle)) and metadata.eql(try fa.metadata.child(e.c.gpa, parent, name));
    const sha = try e.c.a.dupe(u8, &std.fmt.bytesToHex(hash.finalResult(), .lower));
    const hash_matches = std.mem.eql(u8, expected_sha, sha) and offset == metadata.size and offset == try storage.integer(reported, "bytes");
    const original_tail = try storage.get(try storage.get(report, "profile_progress"), "last_record");
    const details = try storage.get(original_tail, "details");
    const tail_matches = state.complete and state.sequence == try storage.integer(original_tail, "sequence") + 1 and
        state.succeeded.? == try storage.boolean(details, "succeeded") and countsMatch(state.counters.?, try storage.get(details, "counters"));
    const selection = try storage.get(report, "selection");
    const failures = try storage.get(selection, "failures");
    const names_match = try failureNamesMatch(e.c.a, state.failures.items, failures);
    var selection_matches = true;
    if (storage.has(selection, "counts", .object)) {
        const counts = try storage.get(selection, "counts");
        selection_matches = state.begins == try storage.integer(counts, "selected") and
            state.selected == try storage.integer(counts, "selected_successfully") and state.failed == try storage.integer(counts, "failed");
    }
    e.hash_cache.clearRetainingCapacity();
    for ([_]p.Evidence{ entry.producer, entry.top_report, entry.backend_report, input, sources.core, sources.driver }) |control| try e.check(control);
    const bound = unchanged and hash_matches and tail_matches and names_match and selection_matches;
    const verified = failure == null and bound;
    try e.write(destination, .{
        .schema = "zllvm-native-event-audit-v1",
        .path = entry.path,
        .metadata = metadata,
        .sha256 = sha,
        .status = if (verified) "verified" else "needs_review",
        .whole_stream_read = true,
        .whole_stream_semantically_valid = failure == null,
        .report_binding_verified = bound,
        .error_record = failure,
        .records = records,
        .logical_bytes_read = offset,
        .newline_complete = newline_complete,
        .stream_metadata_unchanged = unchanged,
        .recorded_hash_matches = hash_matches,
        .original_tail_matches = tail_matches,
        .complete = state.complete,
        .succeeded = state.succeeded,
        .selected = state.selected,
        .failed = state.failed,
        .function_begins = state.begins,
        .function_ends = state.ends,
        .counters = state.counters,
        .failed_functions = state.failures.items,
        .original_failure_details = failures,
        .failure_names_match = names_match,
        .selection_counts_match = selection_matches,
        .producer = entry.producer,
        .top_report = entry.top_report,
        .backend_report = entry.backend_report,
        .input = input,
        .producer_returncode = producer_returncode,
        .backend_returncode = try storage.integer(report, "returncode"),
        .failure_stage = try storage.get(report, "failure_stage"),
        .core_source = sources.core.path,
        .core_sha256 = sources.core.sha256,
        .driver_source = sources.driver.path,
        .driver_sha256 = sources.driver.sha256,
        .auditor_binary_sha256 = sources.binary_sha256,
        .project_revision = sources.revision,
        .audit_elapsed_ns = started.durationTo(.now(e.c.io, .awake)).nanoseconds,
        .retirement_ready = false,
    });
    return verified;
}

pub fn main(init: std.process.Init) !void {
    var c = try u.Context.init(init);
    const args = try init.minimal.args.toSlice(c.a);
    if (args.len != 3 or !std.mem.eql(u8, args[1], "--plan") or !p.relative(args[2])) return error.ExpectedPlan;
    const state_dir_path = try c.join(&.{"local-state/storage-cleanup"});
    try std.Io.Dir.cwd().createDirPath(c.io, state_dir_path);
    var state_dir = try fa.metadata.openRoot(c.io, state_dir_path);
    defer state_dir.close(c.io);
    const lease = try state_dir.createFile(c.io, "cleanup.lock", .{ .truncate = false });
    defer lease.close(c.io);
    if (!try lease.tryLock(c.io, .shared)) return error.CleanupInProgress;
    defer lease.unlock(c.io);
    const output = try c.fmt("local-state/retirements/native-event-audit/{d}-{d}", .{ std.Io.Clock.real.now(c.io).nanoseconds, std.os.linux.getpid() });
    _ = try c.newOutput(output);
    var e = storage.Engine.init(&c, .{}, output, "zigrep");
    const plan_sha = try e.digest(args[2]);
    var plan_json = try e.load(c.gpa, args[2]);
    defer plan_json.deinit();
    var plan = try std.json.parseFromValue(Plan, c.a, plan_json.value, .{});
    defer plan.deinit();
    if (!std.mem.eql(u8, plan.value.schema, "zllvm-native-event-audit-plan-v1") or plan.value.traces.len == 0 or plan.value.traces.len > 1024) return error.InvalidAuditPlan;
    const core_path = try c.fmt("{s}/event_audit_core.zig", .{output});
    const driver_path = try c.fmt("{s}/audit_native_events.zig", .{output});
    try u.files.writeAtomic(c.io, .{ .path = try e.absolute(core_path), .replace = false }, &.{@embedFile("storage_cleanup/event_audit_core.zig")});
    try u.files.writeAtomic(c.io, .{ .path = try e.absolute(driver_path), .replace = false }, &.{@embedFile("audit_native_events.zig")});
    const sources: Sources = .{
        .core = .{ .path = core_path, .sha256 = try e.digest(core_path) },
        .driver = .{ .path = driver_path, .sha256 = try e.digest(driver_path) },
        .binary_sha256 = try c.digest("/proc/self/exe"),
        .revision = std.mem.trim(u8, try c.capture(&.{ "git", "-C", c.root, "rev-parse", "HEAD" }), "\r\n"),
    };
    var findings: std.ArrayList(Finding) = .empty;
    var passed: usize = 0;
    for (plan.value.traces, 0..) |entry, index| {
        const destination = try c.fmt("{s}/audit-{d}.json", .{ output, index });
        var arena = std.heap.ArenaAllocator.init(c.gpa);
        defer arena.deinit();
        var per_file = c;
        per_file.a = arena.allocator();
        var worker = storage.Engine.init(&per_file, .{}, output, "zigrep");
        const verified = auditOne(&worker, entry, destination, sources) catch |err| {
            try findings.append(c.a, .{ .path = entry.path, .error_code = @errorName(err) });
            try c.print("{d}/{d} needs review: {s}: {s}\n", .{ index + 1, plan.value.traces.len, entry.path, @errorName(err) });
            continue;
        };
        try findings.append(c.a, .{ .path = entry.path, .audit = destination, .verified = verified });
        if (verified) passed += 1;
        try c.print("{d}/{d} {s}: {s}\n", .{ index + 1, plan.value.traces.len, if (verified) "verified" else "needs review", entry.path });
    }
    e.hash_cache.clearRetainingCapacity();
    try e.check(.{ .path = args[2], .sha256 = plan_sha });
    try e.write(try c.fmt("{s}/summary.json", .{output}), .{
        .schema = "zllvm-native-event-audit-summary-v1",
        .plan = p.Evidence{ .path = args[2], .sha256 = plan_sha },
        .status = if (passed == findings.items.len) "verified" else "needs_review",
        .verified = passed,
        .total = findings.items.len,
        .findings = findings.items,
    });
    try c.print("Audit summary: {s}/summary.json\n", .{output});
    if (passed != findings.items.len) return error.AuditsNeedReview;
}

test "native event audit: report counters and failure names must match exactly" {
    const a = std.testing.allocator;
    var counts = try std.json.parseFromSlice(u.Value, a, "{\"selected_functions\":1,\"failed_functions\":0}", .{});
    defer counts.deinit();
    try std.testing.expect(!countsMatch(.{ .selected_functions = 1, .failed_functions = 0 }, counts.value));
    const good = try std.json.Stringify.valueAlloc(a, core.Counters{ .selected_functions = 1, .failed_functions = 0 }, .{});
    defer a.free(good);
    var complete = try std.json.parseFromSlice(u.Value, a, good, .{});
    defer complete.deinit();
    try std.testing.expect(countsMatch(.{ .selected_functions = 1, .failed_functions = 0 }, complete.value));
    var duplicates = try std.json.parseFromSlice(u.Value, a, "[{\"function\":\"f\"},{\"function\":\"f\"}]", .{});
    defer duplicates.deinit();
    const f: core.FailedFunction = .{ .name = "f", .begin_sequence = 1, .end_sequence = 2, .begin_byte_offset = 0, .end_byte_offset = 1, .counters = .{ .selected_functions = 0, .failed_functions = 1 } };
    try std.testing.expect(!try failureNamesMatch(a, &.{ f, f }, duplicates.value));
    var one = try std.json.parseFromSlice(u.Value, a, "[{\"function\":\"f\"}]", .{});
    defer one.deinit();
    try std.testing.expect(try failureNamesMatch(a, &.{f}, one.value));
    try std.testing.expect(!try failureNamesMatch(a, &.{}, one.value));
}

test "native event audit: real files preserve failed outcomes and reject truncation changed hashes and unrelated producers" {
    const t = std.testing;
    const run = "local-state/validations/audit/test/run";
    for (0..5) |case| {
        var tmp = t.tmpDir(.{ .iterate = true });
        defer tmp.cleanup();
        var arena = std.heap.ArenaAllocator.init(t.allocator);
        defer arena.deinit();
        const a = arena.allocator();
        var c: u.Context = .{ .a = a, .gpa = t.allocator, .io = t.io, .root = try tmp.dir.realPathFileAlloc(t.io, ".", a), .env = try t.environ.createMap(a), .quiet = true };
        try tmp.dir.createDirPath(t.io, run ++ "/backend");
        try tmp.dir.createDirPath(t.io, "audit");
        var prepare = storage.Engine.init(&c, .{}, "audit", "zigrep");
        try tmp.dir.writeFile(t.io, .{ .sub_path = "audit/core.zig", .data = "auditor core fixture" });
        try tmp.dir.writeFile(t.io, .{ .sub_path = "audit/driver.zig", .data = "auditor driver fixture" });
        try tmp.dir.writeFile(t.io, .{ .sub_path = run ++ "/backend/input.ll", .data = "retained input" });
        const counters: core.Counters = .{ .selected_functions = 0, .failed_functions = 0 };
        const begin: core.Event = .{ .schema = "compilation-events-v1", .sequence = 0, .elapsed_ns = 0, .event = "profile_begin", .function = null, .phase = "other", .details = .{} };
        const end: core.Event = .{ .schema = "compilation-events-v1", .sequence = 1, .elapsed_ns = 1, .event = "profile_end", .function = null, .phase = "other", .details = .{ .counters = counters, .succeeded = false } };
        const raw = try c.fmt("{s}\n{s}{s}", .{ try std.json.Stringify.valueAlloc(a, begin, .{}), try std.json.Stringify.valueAlloc(a, end, .{}), if (case == 1) "" else "\n" });
        try tmp.dir.writeFile(t.io, .{ .sub_path = run ++ "/backend/profile.events.jsonl", .data = raw });
        try prepare.write(run ++ "/report.json", .{ .backend = .{ .path = "local-state/validations/audit/old/z_llvm", .sha256 = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" } });
        try prepare.write(run ++ "/producer.json", .{ .status = "finished", .outcome = "completed", .actual_returncode = 1, .argv = [_][]const u8{ "runner", "--output-root", if (case == 4) "local-state/validations/unrelated" else run } });
        try prepare.write(run ++ "/backend/report.json", .{
            .process_completed = true,
            .returncode = 1,
            .failure_stage = "parse",
            .profile_events = .{ .path = run ++ "/backend/profile.events.jsonl", .sha256 = if (case == 2) "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" else try prepare.digest(run ++ "/backend/profile.events.jsonl"), .bytes = raw.len },
            .profile_progress = .{ .last_record = end },
            .selection = .{ .failures = [_]u.Value{} },
            .input = .{ .path = run ++ "/backend/input.ll", .sha256 = try prepare.digest(run ++ "/backend/input.ll") },
        });
        const entry: Entry = .{
            .path = run ++ "/backend/profile.events.jsonl",
            .producer = .{ .path = run ++ "/producer.json", .sha256 = try prepare.digest(run ++ "/producer.json") },
            .top_report = .{ .path = run ++ "/report.json", .sha256 = try prepare.digest(run ++ "/report.json") },
            .backend_report = .{ .path = run ++ "/backend/report.json", .sha256 = try prepare.digest(run ++ "/backend/report.json") },
        };
        const sources: Sources = .{
            .core = .{ .path = "audit/core.zig", .sha256 = try prepare.digest("audit/core.zig") },
            .driver = .{ .path = "audit/driver.zig", .sha256 = try prepare.digest("audit/driver.zig") },
            .binary_sha256 = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
        };
        if (case == 3) try tmp.dir.writeFile(t.io, .{ .sub_path = run ++ "/backend/input.ll", .data = "changed input" });
        var e = storage.Engine.init(&c, .{}, "audit", "zigrep");
        if (case == 3) {
            try t.expectError(error.EvidenceHashMismatch, auditOne(&e, entry, "audit/result.json", sources));
        } else if (case == 4) {
            try t.expectError(error.UnboundProducer, auditOne(&e, entry, "audit/result.json", sources));
        } else {
            try t.expectEqual(case == 0, try auditOne(&e, entry, "audit/result.json", sources));
            var result = try e.load(t.allocator, "audit/result.json");
            defer result.deinit();
            if (case == 1) try t.expect((try storage.get(result.value, "succeeded")) == .null) else try t.expect(!try storage.boolean(result.value, "succeeded"));
            try t.expectEqual(@as(i64, 1), try storage.integer(result.value, "producer_returncode"));
        }
        _ = try e.metadata(entry.path);
    }
}

test "native event audit: terminal whole-build reports bind the build and exact capture" {
    const t = std.testing;
    const run = "local-state/validations/audit/test/run";
    for (0..5) |case| {
        var tmp = t.tmpDir(.{ .iterate = true });
        defer tmp.cleanup();
        var arena = std.heap.ArenaAllocator.init(t.allocator);
        defer arena.deinit();
        const a = arena.allocator();
        var c: u.Context = .{ .a = a, .gpa = t.allocator, .io = t.io, .root = try tmp.dir.realPathFileAlloc(t.io, ".", a), .env = try t.environ.createMap(a), .quiet = true };
        try tmp.dir.createDirPath(t.io, run ++ "/captures/1");
        var e = storage.Engine.init(&c, .{}, run, "zigrep");
        const raw: p.Evidence = .{ .path = run ++ "/captures/1/profile.events.jsonl", .sha256 = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" };
        const input: p.Evidence = .{ .path = run ++ "/captures/1/input.ll", .sha256 = raw.sha256 };
        try e.write(run ++ "/captures/1/report.json", .{ .profile_events = raw, .input = input });
        try e.write(run ++ "/report.json", .{
            .schema = "whole-compiler-diagnostic-v1",
            .status = "passed",
            .build_completed = case != 1,
            .build_returncode = @as(i32, 0),
            .all_hook_objects_complete = true,
            .source_and_backend_verified = true,
            .commands = .{.{ .argv = [_][]const u8{ "zig", "build", "--prefix", if (case == 2) run ++ "/unrelated" else run ++ "/install" }, .outcome = "completed", .actual_returncode = @as(i32, if (case == 4) 1 else 0), .returncode = @as(i32, 0) }},
            .invocations = .{.{ .directory = if (case == 3) run ++ "/captures/2" else run ++ "/captures/1", .process_completed = true, .object_complete = true, .returncode = @as(i32, 0), .profile_events = raw, .input = input }},
        });
        const top: p.Evidence = .{ .path = run ++ "/report.json", .sha256 = try e.digest(run ++ "/report.json") };
        const entry: Entry = .{ .path = raw.path, .producer = top, .top_report = top, .backend_report = .{ .path = run ++ "/captures/1/report.json", .sha256 = try e.digest(run ++ "/captures/1/report.json") } };
        var parsed = try e.load(t.allocator, top.path);
        defer parsed.deinit();
        if (case == 0) try t.expectEqual(@as(i64, 0), try validateEntry(&e, entry, parsed.value)) else if (case == 1 or case == 4)
            try t.expectError(error.ProducerNotTerminal, validateEntry(&e, entry, parsed.value))
        else
            try t.expectError(error.UnboundProducer, validateEntry(&e, entry, parsed.value));
    }
}

test "native event audit: self-rebuild requires its own command and bound captures" {
    const t = std.testing;
    const run = "local-state/validations/audit/test/run";
    const capture = run ++ "/self-rebuild/captures/1";
    for (0..8) |case| {
        var tmp = t.tmpDir(.{ .iterate = true });
        defer tmp.cleanup();
        var arena = std.heap.ArenaAllocator.init(t.allocator);
        defer arena.deinit();
        const a = arena.allocator();
        var c: u.Context = .{ .a = a, .gpa = t.allocator, .io = t.io, .root = try tmp.dir.realPathFileAlloc(t.io, ".", a), .env = try t.environ.createMap(a), .quiet = true };
        try tmp.dir.createDirPath(t.io, capture);
        var e = storage.Engine.init(&c, .{}, run, "zigrep");
        const raw: p.Evidence = .{ .path = capture ++ "/profile.events.jsonl", .sha256 = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" };
        const input: p.Evidence = .{ .path = capture ++ "/input.ll", .sha256 = raw.sha256 };
        try e.write(capture ++ "/report.json", .{ .profile_events = raw, .input = input });
        try e.write(run ++ "/report.json", .{
            .schema = "whole-compiler-diagnostic-v1",
            .status = "passed",
            .build_completed = true,
            .build_returncode = @as(i32, 0),
            .all_hook_objects_complete = true,
            .source_and_backend_verified = true,
            .self_rebuild_passed = case != 1,
            .self_rebuild_backend_reuse = case == 2,
            .commands = .{ .{
                .argv = [_][]const u8{ "/outside/zig", "build", "--prefix", run ++ "/install", "--help" },
                .outcome = "completed",
                .actual_returncode = @as(i32, 0),
                .returncode = @as(i32, 0),
            }, .{
                .argv = [_][]const u8{ "/usr/bin/time", "-o", "timing.txt", "--", "/usr/bin/taskset", "--cpu-list", if (case == 6) "1" else "0", if (case == 7) "zig" else run ++ "/install/bin/zig", "build", "--prefix", if (case == 3) run ++ "/install" else run ++ "/self-rebuild/install", if (case == 4) "--help" else "-j1" },
                .outcome = "completed",
                .actual_returncode = @as(i32, 0),
                .returncode = @as(i32, 0),
            } },
            .self_rebuild_invocations = .{.{ .directory = if (case == 5) run ++ "/captures/1" else capture, .process_completed = true, .object_complete = true, .returncode = @as(i32, 0), .profile_events = raw, .input = input }},
        });
        const top: p.Evidence = .{ .path = run ++ "/report.json", .sha256 = try e.digest(run ++ "/report.json") };
        const entry: Entry = .{ .path = raw.path, .producer = top, .top_report = top, .backend_report = .{ .path = capture ++ "/report.json", .sha256 = try e.digest(capture ++ "/report.json") } };
        var parsed = try e.load(t.allocator, top.path);
        defer parsed.deinit();
        if (case == 0) try t.expectEqual(@as(i64, 0), try validateEntry(&e, entry, parsed.value)) else if (case == 1 or case == 2)
            try t.expectError(error.ProducerNotTerminal, validateEntry(&e, entry, parsed.value))
        else
            try t.expectError(error.UnboundProducer, validateEntry(&e, entry, parsed.value));
    }
}

test {
    _ = core;
}
