//! Present-day disposal of reviewed historical detail. The original outcome
//! remains evidence: an interrupted trace is never upgraded to a complete audit.
const std = @import("std");
const core = @import("engine.zig");
const p = core.p;
const u = @import("../validation/common.zig");

pub const Interruption = struct {
    diagnosis: p.Evidence,
    terminal: p.Evidence,
    commands: ?p.Evidence = null,
    launcher: ?p.Evidence = null,
    invocation: p.Evidence,
    checkpoint: p.Evidence,
    acceptance: p.Evidence,
};
pub const Record = struct {
    path: []const u8,
    sha256: []const u8,
    run_root: []const u8,
    reason: []const u8,
    consumers_closed: bool,
    retained: []const p.Evidence,
    interruption: ?Interruption = null,
    audited: ?p.Evidence = null,
    retired_pins: []const p.PinTransition = &.{},
};
pub const Plan = struct {
    schema: []const u8 = "zllvm-reviewed-records-v1",
    reason: []const u8,
    review: p.Evidence,
    records: []const Record,
};

pub fn scope(path: []const u8) bool {
    if (!p.candidate(path)) return false;
    const name = std.fs.path.basename(path);
    if (name.len == 0 or name[0] == '.') return false;
    return u.contains(&.{ ".json", ".jsonl", ".ndjson", ".log", ".stdout", ".stderr", ".tsv", ".txt", ".diff" }, std.fs.path.extension(name));
}
fn same(a: []const u8, b: []const u8) bool {
    return std.mem.eql(u8, a, b);
}
fn samePath(e: *core.Engine, a: []const u8, b: []const u8) !bool {
    return same(try e.absolute(a), try e.absolute(b));
}
fn keep(e: *core.Engine, list: *std.ArrayList(p.Evidence), ev: p.Evidence) !void {
    try e.keep(list, ev.path, ev.sha256);
}

// A few canceled legacy runs have no completed backend command record. Their
// actual checked producer invoked a fixed, single-command shell launcher. Only
// that narrowly serialized launcher is supported; arbitrary shell is rejected.
fn legacyLauncher(e: *core.Engine, record: Record, proof: p.Evidence, terminal: u.Value, input: p.Evidence, list: *std.ArrayList(p.Evidence)) !void {
    try keep(e, list, proof);
    const outer = try u.stringSlice(e.c.a, try core.get(terminal, "argv"));
    if (outer.len != 2 or !same(outer[0], "bash") or !try samePath(e, outer[1], proof.path)) return error.InterruptedProducerNotBound;
    const bytes = try e.read(e.c.a, proof.path, 64 * 1024);
    const prefix = "#!/usr/bin/env bash\nset -euo pipefail\n";
    if (!std.mem.startsWith(u8, bytes, prefix)) return error.UnsupportedInterruptedLauncher;
    const body = std.mem.trim(u8, bytes[prefix.len..], "\r\n");
    if (body.len < 2 or body[0] != '\'' or body[body.len - 1] != '\'') return error.UnsupportedInterruptedLauncher;
    var words = std.mem.splitSequence(u8, body[1 .. body.len - 1], "' '");
    var args: std.ArrayList([]const u8) = .empty;
    while (words.next()) |word| {
        if (word.len == 0 or std.mem.indexOfAny(u8, word, "'\r\n") != null) return error.UnsupportedInterruptedLauncher;
        try args.append(e.c.a, word);
    }
    if (args.items.len < 9 or !same(args.items[0], "zig") or !same(args.items[1], "run") or
        !same(args.items[2], "tools/run_whole_compiler.zig") or !same(args.items[3], "--")) return error.UnsupportedInterruptedLauncher;
    var selected = std.StringHashMap(void).init(e.c.a);
    var i: usize = 4;
    while (i < args.items.len) : (i += 1) {
        const flag = args.items[i];
        if (selected.contains(flag)) return error.UnsupportedInterruptedLauncher;
        try selected.put(flag, {});
        if (same(flag, "--profile-events")) continue;
        if (!u.contains(&.{ "--output-root", "--zllvm", "--timeout-ms", "--input-ir" }, flag) or i + 1 >= args.items.len) return error.UnsupportedInterruptedLauncher;
        i += 1;
        const arg = args.items[i];
        if (same(flag, "--output-root") and !try samePath(e, arg, record.run_root)) return error.InterruptedProducerNotBound;
        if (same(flag, "--input-ir")) try e.keep(list, arg, input.sha256);
        if (same(flag, "--zllvm")) _ = try e.relative(arg);
        if (same(flag, "--timeout-ms")) _ = std.fmt.parseInt(u64, arg, 10) catch return error.UnsupportedInterruptedLauncher;
    }
    for ([_][]const u8{ "--output-root", "--zllvm", "--input-ir", "--profile-events" }) |flag|
        if (!selected.contains(flag)) return error.InterruptedProducerNotBound;
    const object = try e.c.fmt("{s}/backend/local.o", .{record.run_root});
    if ((try e.metadata(object)).size != 0) return error.InterruptedObjectNotEmpty;
    try e.keep(list, object, null);
    try e.keep(list, try e.c.fmt("{s}/backend/backend.stderr", .{record.run_root}), null);
}

/// Explicit closure of tracing detail needs the complete ordered-event audit,
/// its bound input/results and the auditor's sources. It does not create a new
/// obligation to reconstruct a superseded compiler after its consumers closed.
/// Ordinary releases retain their stricter replay contract unchanged.
fn audited(e: *core.Engine, record: Record, proof: p.Evidence, list: *std.ArrayList(p.Evidence)) !void {
    try keep(e, list, proof);
    var parsed = try e.load(e.c.gpa, proof.path);
    defer parsed.deinit();
    const v = parsed.value;
    if (!core.eq(v, "schema", "zllvm-native-event-audit-v1") or !core.eq(v, "status", "verified") or
        !core.eq(v, "path", record.path) or !core.eq(v, "sha256", record.sha256)) return error.ReviewedTraceAuditMismatch;
    for ([_][]const u8{
        "whole_stream_read",         "whole_stream_semantically_valid", "report_binding_verified", "complete",
        "stream_metadata_unchanged", "recorded_hash_matches",           "newline_complete",        "original_tail_matches",
        "failure_names_match",       "selection_counts_match",
    }) |key| if (!try core.boolean(v, key)) return error.IncompleteReviewedTraceAudit;
    if (try core.integer(v, "logical_bytes_read") != (try e.metadata(record.path)).size or
        try core.integer(v, "records") <= 0 or
        try core.integer(v, "function_begins") != try core.integer(v, "function_ends") or
        (try core.get(v, "error_record")) != .null or !p.hash(try core.str(v, "auditor_binary_sha256"))) return error.IncompleteReviewedTraceAudit;
    // A complete, failed compilation remains failed; no success is inferred.
    _ = try core.boolean(v, "succeeded");
    for ([_][]const u8{ "producer", "top_report", "backend_report", "input" }) |key| {
        const bound = try core.get(v, key);
        const ev = p.Evidence{ .path = try core.str(bound, "path"), .sha256 = try core.str(bound, "sha256") };
        if (same(key, "top_report") and !try samePath(e, ev.path, try e.c.fmt("{s}/report.json", .{record.run_root}))) return error.ReviewedTraceAuditScopeMismatch;
        if (same(key, "backend_report") and !try samePath(e, ev.path, try e.c.fmt("{s}/report.json", .{std.fs.path.dirname(record.path).?}))) return error.ReviewedTraceAuditScopeMismatch;
        try keep(e, list, ev);
        if (same(key, "producer")) {
            var producer = try e.load(e.c.gpa, ev.path);
            defer producer.deinit();
            if (producer.value != .object) return error.InvalidProducerLog;
            for ([_][]const u8{ "log", "stdout", "stderr" }) |log_key| {
                if (producer.value.object.get(log_key)) |log| {
                    if (log != .string) return error.InvalidProducerLog;
                    try e.keep(list, log.string, null);
                }
            }
        }
        if (same(key, "backend_report")) {
            var backend = try e.load(e.c.gpa, ev.path);
            defer backend.deinit();
            if (backend.value.object.get("commands")) |commands| {
                if (commands != .array) return error.InvalidProducerLog;
                for (commands.array.items) |command| {
                    // Object stdout remains an ordinary build product. Keep
                    // the original diagnostics even for an embedded producer.
                    try e.keep(list, try core.str(command, "stderr"), null);
                }
            }
        }
    }
    for ([_][]const u8{ "core", "driver" }) |key| try e.keep(list, try core.str(v, try e.c.fmt("{s}_source", .{key})), try core.str(v, try e.c.fmt("{s}_sha256", .{key})));
}

fn interrupted(e: *core.Engine, record: Record, proof: Interruption, list: *std.ArrayList(p.Evidence)) !void {
    if ((proof.commands == null) == (proof.launcher == null)) return error.InterruptedProducerNotBound;
    for ([_]p.Evidence{ proof.diagnosis, proof.terminal, proof.invocation, proof.checkpoint, proof.acceptance }) |ev| try keep(e, list, ev);
    if (proof.commands) |commands| try keep(e, list, commands);
    var diagnosis = try e.load(e.c.gpa, proof.diagnosis.path);
    defer diagnosis.deinit();
    const d = diagnosis.value;
    if (!core.eq(d, "schema", "zllvm-event-prefix-diagnosis-v1") or !core.eq(d, "path", record.path) or
        !core.eq(d, "sha256", record.sha256) or try core.boolean(d, "complete") or
        try core.boolean(d, "retirement_ready")) return error.InvalidInterruptedTraceDiagnosis;
    for ([_][]const u8{ "whole_stream_read", "stream_metadata_unchanged", "prefix_semantically_valid", "newline_complete" }) |key|
        if (!try core.boolean(d, key)) return error.InvalidInterruptedTraceDiagnosis;
    const m = try e.metadata(record.path);
    if (try core.integer(d, "logical_bytes_read") != m.size or
        try core.integer(d, "records") != try core.integer(d, "validated_prefix_records")) return error.InvalidInterruptedTraceDiagnosis;
    for ([_][]const u8{ "core", "driver" }) |key| {
        const ev = try core.get(d, key);
        try keep(e, list, .{ .path = try core.str(ev, "path"), .sha256 = try core.str(ev, "sha256") });
    }
    var terminal = try e.load(e.c.gpa, proof.terminal.path);
    defer terminal.deinit();
    const receipt = terminal.value;
    if ((!core.eq(receipt, "status", "failed") and !core.eq(receipt, "status", "finished")) or
        (!core.eq(receipt, "outcome", "supervision_failed") and !core.eq(receipt, "outcome", "canceled")) or
        try core.integer(receipt, "actual_returncode") == 0 or
        try core.integer(receipt, "finished_ns") <= try core.integer(receipt, "started_ns")) return error.InterruptedProducerNotClosed;
    const outer = try u.stringSlice(e.c.a, try core.get(receipt, "argv"));
    var run_bound = false;
    for (outer, 0..) |arg, i| if (i > 0 and same(outer[i - 1], "--output-root") and try samePath(e, arg, record.run_root)) {
        run_bound = true;
    };
    if (proof.commands != null and !run_bound) return error.InterruptedProducerNotBound;
    var invocation = try e.load(e.c.gpa, proof.invocation.path);
    defer invocation.deinit();
    if (!try samePath(e, proof.invocation.path, try e.c.fmt("{s}/backend/invocation.json", .{record.run_root})) or
        try core.boolean(invocation.value, "object_complete")) return error.InterruptedInvocationNotBound;
    const input = try core.get(invocation.value, "input");
    const input_path = try core.str(input, "path");
    const input_hash = try core.str(input, "sha256");
    try keep(e, list, .{ .path = input_path, .sha256 = input_hash });
    if (proof.commands) |command_proof| {
        var commands = try e.load(e.c.gpa, command_proof.path);
        defer commands.deinit();
        if (!try samePath(e, command_proof.path, try e.c.fmt("{s}/backend/commands.json", .{record.run_root})) or commands.value != .array) return error.InterruptedCommandNotBound;
        var bound: usize = 0;
        const profile_arg = try e.c.fmt("--profile-events={s}", .{try e.absolute(record.path)});
        for (commands.value.array.items) |cmd| {
            const argv = try u.stringSlice(e.c.a, try core.get(cmd, "argv"));
            if (!u.contains(argv, profile_arg)) continue;
            if (!u.contains(argv, try e.absolute(input_path)) or
                !core.eq(cmd, "outcome", "canceled") or try core.integer(cmd, "actual_returncode") == 0) return error.InterruptedCommandNotBound;
            const object = try core.str(cmd, "stdout");
            const diagnostic = try core.str(cmd, "stderr");
            if (!try samePath(e, object, try e.c.fmt("{s}/backend/local.o", .{record.run_root})) or
                (try e.metadata(object)).size != 0) return error.InterruptedObjectNotEmpty;
            try e.keep(list, object, null);
            try e.keep(list, diagnostic, null);
            bound += 1;
        }
        if (bound != 1) return error.InterruptedCommandNotBound;
    } else try legacyLauncher(e, record, proof.launcher.?, receipt, .{ .path = input_path, .sha256 = input_hash }, list);
    var acceptance = try e.load(e.c.gpa, proof.acceptance.path);
    defer acceptance.deinit();
    if (!core.eq(acceptance.value, "status", "passed") or !try core.boolean(acceptance.value, "final_follow_up_complete") or
        !core.eq(acceptance.value, "cumulative_checkpoint_sha256", proof.checkpoint.sha256)) return error.InterruptedSuccessorNotAccepted;
    var checkpoint = try e.load(e.c.gpa, proof.checkpoint.path);
    defer checkpoint.deinit();
    const objects = try core.get(checkpoint.value, "original_objects");
    if (objects != .array) return error.InterruptedSuccessorNotAccepted;
    var matched = false;
    for (objects.array.items) |row| {
        if (!core.eq(row, "input_sha256", input_hash)) continue;
        const object = try core.get(row, "object");
        const path = try core.str(object, "path");
        if ((try e.metadata(path)).size == 0) return error.InterruptedSuccessorNotAccepted;
        try keep(e, list, .{ .path = path, .sha256 = try core.str(object, "sha256") });
        matched = true;
    }
    if (!matched) return error.InterruptedSuccessorInputMismatch;
}

pub fn prepare(e: *core.Engine, path: []const u8) !void {
    if (!p.relative(path) or e.actions.items.len != 0) return error.InvalidReviewedRecords;
    try e.discover();
    e.actions.clearRetainingCapacity();
    try e.addControl(path);
    var parsed = try e.load(e.c.gpa, path);
    defer parsed.deinit();
    const plan = (try std.json.parseFromValue(Plan, e.c.a, parsed.value, .{ .allocate = .alloc_always })).value;
    if (!same(plan.schema, "zllvm-reviewed-records-v1") or u.trim(plan.reason).len == 0 or plan.records.len == 0 or
        plan.records.len > 16384 or !p.relative(plan.review.path)) return error.InvalidReviewedRecords;
    var common: std.ArrayList(p.Evidence) = .empty;
    try e.keep(&common, path, null);
    try keep(e, &common, plan.review);
    var seen = std.StringHashMap(void).init(e.c.a);
    for (plan.records) |record| {
        if (!scope(record.path) or !p.hash(record.sha256) or !p.validationRun(record.run_root) or
            !p.within(record.run_root, record.path) or !record.consumers_closed or u.trim(record.reason).len == 0 or
            record.retained.len == 0) return error.InvalidReviewedRecord;
        if (seen.contains(record.path)) return error.DuplicateReviewedRecord;
        try seen.put(record.path, {});
        const raw = same(std.fs.path.basename(record.path), "profile.events.jsonl");
        if (raw != (record.interruption != null or record.audited != null) or
            (record.interruption != null and record.audited != null)) return error.RawTraceRequiresDispositionProof;
        var kept: std.ArrayList(p.Evidence) = .empty;
        try kept.appendSlice(e.c.a, common.items);
        for (record.retained) |ev| try keep(e, &kept, ev);
        _ = e.metadata(record.path) catch |err| switch (err) {
            error.FileNotFound => {
                const absent = try e.add(record.path, record.run_root, path, if (raw) .raw_trace else .record_detail, record.sha256);
                e.actions.items[absent].status = .absent;
                e.actions.items[absent].reviewed_record = true;
                e.actions.items[absent].replay_required = false;
                e.actions.items[absent].retained = kept.items;
                continue;
            },
            else => return err,
        };
        if (record.interruption) |proof| try interrupted(e, record, proof, &kept);
        if (record.audited) |proof| try audited(e, record, proof, &kept);
        for (record.retired_pins) |transition| {
            if (!p.relative(transition.manifest.path) or !p.hash(transition.manifest.sha256) or
                u.trim(transition.reason).len == 0 or transition.reference.len == 0 or
                !same(transition.target.path, record.path) or !same(transition.target.sha256, record.sha256)) return error.InvalidPinTransition;
            for (e.config.current_manifests) |current| if (same(current, transition.manifest.path)) return error.CurrentManifestCannotBeRetired;
            if (!p.within("local-state/retirements", transition.manifest.path) and !p.validationOutput(transition.manifest.path)) return error.InvalidPinTransition;
            try keep(e, &kept, transition.manifest);
            if (p.within("local-state/retirements", transition.manifest.path) and std.mem.endsWith(u8, transition.manifest.path, ".json")) {
                var old = try e.load(e.c.gpa, transition.manifest.path);
                defer old.deinit();
                if (!core.eq(old.value, "status", "complete")) return error.IncompletePinRetirement;
            }
        }
        for (kept.items) |ev| if (try samePath(e, record.path, ev.path)) return error.RetentionOverlap;
        const index = try e.add(record.path, record.run_root, path, if (raw) .raw_trace else .record_detail, record.sha256);
        e.actions.items[index].reviewed_record = true;
        e.actions.items[index].replay_required = false;
        e.actions.items[index].retained = kept.items;
        e.actions.items[index].retired_pins = record.retired_pins;
    }
}

pub fn verifyFile(e: *core.Engine, a: core.Action) !void {
    if (!scope(a.path) or a.retained.len < 3 or (a.kind != .record_detail and a.kind != .raw_trace)) return error.InvalidReviewedRecord;
    const file = try std.Io.Dir.cwd().openFile(e.c.io, try e.absolute(a.path), .{});
    defer file.close(e.c.io);
    var prefix: [8]u8 = undefined;
    const n = try file.readPositionalAll(e.c.io, &prefix, 0);
    if ((try e.metadata(a.path)).mode & 0o111 != 0 or std.mem.startsWith(u8, prefix[0..n], "\x7fELF") or
        std.mem.startsWith(u8, prefix[0..n], "!<arch>\n")) return error.NotTextDetail;
}
