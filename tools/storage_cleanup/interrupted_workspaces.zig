//! Explicit disposal authorization for a lost monitor, without producer credit.
//! Ordinary active-workspace refusal and its original layout stay unchanged.
const std = @import("std");
const core = @import("engine.zig");
const u = @import("../validation/common.zig");
const paths = @import("../validation/storage_paths.zig");
const lifecycle = @import("../validation/storage_lifecycle.zig");
const p = core.p;

pub const Processes = struct {
    observation: p.Evidence,
    pids: []const i32,
    groups: []const i32,
    sessions: []const i32,
};
pub const Row = struct {
    layout: p.Evidence,
    original_receipt: p.Evidence,
    original_job: p.Evidence,
    original_monitor_outcome: []const u8,
    outer_observation: p.Evidence,
    child_build: p.Evidence,
    admission: p.Evidence,
    diagnosis: p.Evidence,
    tree: p.Evidence,
    processes: Processes,
    consumers_closed: bool,
    disposal_authorized: bool,
    reason: []const u8,
    retained: []const p.Evidence = &.{},
};
pub const Plan = struct {
    schema: []const u8,
    case: []const u8,
    review: p.Evidence,
    records: []const Row,
};

fn loadPlan(e: *core.Engine, path: []const u8) !Plan {
    var parsed = try e.load(e.c.gpa, path);
    defer parsed.deinit();
    const plan = try std.json.parseFromValue(Plan, e.c.a, parsed.value, .{ .allocate = .alloc_always });
    if (!std.mem.eql(u8, plan.value.schema, "zllvm-interrupted-workspace-recovery-v1") or
        !std.mem.eql(u8, plan.value.case, "lost-monitor-completed-compiler-build") or plan.value.records.len != 1)
        return error.InvalidInterruptedWorkspacePlan;
    return plan.value;
}
pub fn prepare(e: *core.Engine, name: []const u8) !void {
    if (!p.relative(name) or e.actions.items.len != 0) return error.InvalidInterruptedWorkspacePlan;
    // Carry every held release and independent retained dependency into this
    // explicit route, while leaving unrelated ordinary candidates untouched.
    try e.discover();
    e.actions.clearRetainingCapacity();
    try e.addControl(name);
    const plan = try loadPlan(e, name);
    try e.check(plan.review);
    const row = plan.records[0];
    try e.check(row.layout);
    var original = try e.load(e.c.gpa, row.layout.path);
    defer original.deinit();
    const record = try std.json.parseFromValue(paths.Record, e.c.a, original.value, .{ .allocate = .alloc_always });
    try paths.validate(e.c.a, row.layout.path, record.value);
    const index = try e.add(record.value.temporary_root, record.value.evidence_root, row.layout.path, .temporary_workspace, null);
    e.actions.items[index].interrupted_workspace_recovery = .{ .path = try e.c.a.dupe(u8, name), .sha256 = try e.digest(name) };
    e.actions.items[index].original_monitor_outcome = "unknown";
}
fn selected(e: *core.Engine, action: core.Action) !struct { plan: Plan, row: Row } {
    const authorization = action.interrupted_workspace_recovery orelse return error.MissingInterruptedWorkspaceAuthorization;
    try e.check(authorization);
    const plan = try loadPlan(e, authorization.path);
    const row = plan.records[0];
    if (action.kind != .temporary_workspace or action.workspace_release != null or
        action.original_monitor_outcome == null or !std.mem.eql(u8, action.original_monitor_outcome.?, "unknown") or
        !std.mem.eql(u8, row.layout.path, action.producer)) return error.InterruptedWorkspaceScopeMismatch;
    return .{ .plan = plan, .row = row };
}
fn missing(v: u.Value, key: []const u8) bool {
    return v == .object and (v.object.get(key) orelse .null) == .null;
}
fn zero(v: u.Value, key: []const u8) bool {
    return v == .object and u.json.eql(v.object.get(key) orelse .null, u.n(0));
}
pub fn validProcesses(processes: Processes, owner: i64) bool {
    if (owner <= 1 or processes.pids.len == 0 or processes.groups.len == 0 or processes.sessions.len == 0) return false;
    var found = false;
    for (processes.pids) |pid| {
        if (pid <= 1) return false;
        if (pid == owner) found = true;
    }
    for (processes.groups) |pid| if (pid <= 1) return false;
    for (processes.sessions) |pid| if (pid <= 1) return false;
    return found;
}
pub fn processSnapshotBusy(text: []const u8, processes: Processes) !bool {
    var lines = std.mem.tokenizeScalar(u8, text, '\n');
    while (lines.next()) |line| {
        var columns = std.mem.tokenizeAny(u8, line, " \t");
        const first = columns.next() orelse continue;
        if (std.mem.eql(u8, first, "PID")) continue;
        const pid = std.fmt.parseInt(i32, first, 10) catch return error.InvalidProcessSnapshot;
        const group = try std.fmt.parseInt(i32, columns.next() orelse return error.InvalidProcessSnapshot, 10);
        const session = try std.fmt.parseInt(i32, columns.next() orelse return error.InvalidProcessSnapshot, 10);
        for (processes.pids) |old| if (pid == old) return true;
        for (processes.groups) |old| if (group == old) return true;
        for (processes.sessions) |old| if (session == old) return true;
    }
    return false;
}
pub fn quiescent(e: *core.Engine, action: core.Action, quarantine: ?[]const u8) !void {
    const row = (try selected(e, action)).row;
    const processes = try e.c.capture(&.{ "ps", "-eo", "pid,pgid,sid,args" });
    if (try processSnapshotBusy(processes, row.processes)) return error.InterruptedWorkspaceProcessStillLive;
    if (quarantine) |alias| {
        const absolute = try e.absolute(alias);
        if (core.commandUsesRun(processes, alias, std.os.linux.getpid()) or
            core.commandUsesRun(processes, absolute, std.os.linux.getpid())) return error.InterruptedWorkspaceQuarantineCommand;
        const listing = try e.c.capture(&.{ "lsof", "-nP", "-u", try e.c.fmt("{d}", .{std.os.linux.getuid()}), "-Fn" });
        var lines = std.mem.tokenizeScalar(u8, listing, '\n');
        while (lines.next()) |line| if (line.len > 1 and line[0] == 'n' and p.within(absolute, line[1..]))
            return error.InterruptedWorkspaceQuarantineReader;
    }
}

pub fn verify(e: *core.Engine, action: core.Action, kept: *std.ArrayList(p.Evidence)) !void {
    return verifyControls(e, action, kept, true);
}
fn verifyControls(e: *core.Engine, action: core.Action, kept: *std.ArrayList(p.Evidence), verify_tree: bool) !void {
    const selection = try selected(e, action);
    const row = selection.row;
    if (!row.consumers_closed or !row.disposal_authorized or u.trim(row.reason).len == 0 or
        !std.mem.eql(u8, row.original_monitor_outcome, "unknown")) return error.InterruptedWorkspaceNotAuthorized;
    try e.keep(kept, action.interrupted_workspace_recovery.?.path, action.interrupted_workspace_recovery.?.sha256);
    for ([_]p.Evidence{ selection.plan.review, row.layout, row.original_receipt, row.original_job, row.outer_observation, row.child_build, row.admission, row.diagnosis, row.tree, row.processes.observation }) |ev|
        try e.keep(kept, ev.path, ev.sha256);
    for (row.retained) |ev| try e.keep(kept, ev.path, ev.sha256);

    var layout_json = try e.load(e.c.gpa, row.layout.path);
    defer layout_json.deinit();
    const record = try std.json.parseFromValue(paths.Record, e.c.a, layout_json.value, .{ .allocate = .alloc_always });
    const r = record.value;
    try paths.validate(e.c.a, row.layout.path, r);
    if (r.state != .active or r.result != null or r.lifetime != .validation or
        !std.mem.eql(u8, r.evidence_root, action.run_root) or !std.mem.eql(u8, r.temporary_root, action.path) or
        !std.mem.eql(u8, row.original_receipt.path, try e.c.fmt("{s}/{s}.json", .{ r.evidence_root, r.key })))
        return error.InterruptedWorkspaceScopeMismatch;
    if (u.exists(e.c.io, try e.absolute(try paths.releasePath(e.c.a, r)))) return error.InterruptedWorkspaceAlreadyReleased;
    for (r.diagnostics) |ev| try e.keep(kept, ev.path, ev.sha256);
    var original = try e.load(e.c.gpa, row.original_receipt.path);
    defer original.deinit();
    if (!u.json.is(try u.get(original.value, "status"), "running") or !missing(original.value, "actual_returncode") or !missing(original.value, "returncode"))
        return error.OriginalMonitorOutcomeIsNotUnknown;
    const storage = try u.get(original.value, "storage");
    if (!u.json.is(try u.get(storage, "layout"), try e.absolute(row.layout.path)) or
        !u.json.is(try u.get(storage, "temporary_root"), try e.absolute(r.temporary_root)) or
        !u.json.is(try u.get(storage, "evidence_root"), try e.absolute(r.evidence_root)) or
        !u.json.is(try u.get(original.value, "cwd"), e.c.root)) return error.InterruptedWorkspaceScopeMismatch;
    const owner = try u.get(original.value, "pid");
    if (owner != .integer or !validProcesses(row.processes, owner.integer)) return error.InvalidInterruptedWorkspaceProcesses;
    var job_json = try e.load(e.c.gpa, row.original_job.path);
    defer job_json.deinit();
    const job = try std.json.parseFromValue(lifecycle.Job, e.c.a, job_json.value, .{ .allocate = .alloc_always });
    if (!std.mem.eql(u8, job.value.schema, "zllvm-storage-job-v1") or job.value.state != .running or
        !std.mem.eql(u8, job.value.run_root, r.evidence_root) or !std.mem.eql(u8, job.value.producer.path, row.original_receipt.path) or
        !std.mem.eql(u8, job.value.working_directory, ".") or job.value.external_working_directory != null or
        !u.json.eql(try u.get(original.value, "started_ns"), u.n(job.value.started_ns))) return error.InterruptedWorkspaceJobMismatch;
    const job_prefix = try e.c.fmt("{s}/{d}-", .{ lifecycle.jobs_directory, job.value.started_ns });
    if (!std.mem.startsWith(u8, row.original_job.path, job_prefix) or !std.mem.endsWith(u8, row.original_job.path, ".json")) return error.InterruptedWorkspaceJobMismatch;
    const monitor = try std.fmt.parseInt(i32, row.original_job.path[job_prefix.len .. row.original_job.path.len - 5], 10);
    var monitor_observed = false;
    for (row.processes.pids) |pid| if (pid == monitor and monitor > 1) {
        monitor_observed = true;
    };
    if (!monitor_observed) return error.InvalidInterruptedWorkspaceProcesses;
    var outer = try e.load(e.c.gpa, row.outer_observation.path);
    defer outer.deinit();
    if (!u.json.eql(try u.get(outer.value, "observed_outer_session_returncode"), u.n(143)) or
        !u.json.eql(try u.get(outer.value, "original_managed_final_exit_available"), u.b(false))) return error.InvalidOuterInterruptionObservation;
    var build = try e.load(e.c.gpa, row.child_build.path);
    defer build.deinit();
    const command = try u.get(build.value, "command");
    if (!u.json.is(try u.get(build.value, "schema"), "zllvm-compiler-build-v1") or
        !zero(command, "actual_returncode") or !zero(command, "returncode") or
        !u.json.is(try u.get(command, "outcome"), "completed") or !u.json.is(try u.get(command, "cwd"), e.c.root))
        return error.ChildCompilerBuildNotCompleted;
    const environment = try u.get(build.value, "environment");
    for ([_][]const u8{ "ZIG_LOCAL_CACHE_DIR", "ZIG_GLOBAL_CACHE_DIR" }) |key| {
        if (!p.within(r.temporary_root, try e.relative(try u.str(environment, key)))) return error.ChildCompilerScratchMismatch;
    }
    var admission = try e.load(e.c.gpa, row.admission.path);
    defer admission.deinit();
    const child_sha256 = try u.str(build.value, "compiler_sha256");
    const admitted_sha256 = try u.str(admission.value, "backend_sha256");
    if (!p.hash(child_sha256) or !p.hash(admitted_sha256) or !std.mem.eql(u8, child_sha256, admitted_sha256))
        return error.ChildCompilerAdmissionMismatch;
    if (!u.json.is(try u.get(admission.value, "status"), "passed") or
        !u.json.eql(try u.get(admission.value, "exact_completed_child_build_adopted"), u.b(true)) or
        !zero(admission.value, "actual_sdk_build_returncode") or
        !u.json.eql(try u.get(admission.value, "original_monitor_terminal_exit_available"), u.b(false)))
        return error.ChildCompilerAdmissionMismatch;
    var tree_json = try e.loadLimit(e.c.gpa, row.tree.path, 512 * 1024 * 1024);
    defer tree_json.deinit();
    const snapshot = try std.json.parseFromValue(core.fa.Snapshot, e.c.a, tree_json.value, .{ .allocate = .alloc_always });
    if (snapshot.value.schema != 1 or !snapshot.value.options.hash_files or snapshot.value.options.exclude_paths.len != 0 or
        !std.mem.eql(u8, snapshot.value.root, try e.absolute(r.temporary_root))) return error.InterruptedWorkspaceTreeScopeMismatch;
    if (verify_tree) {
        try core.fa.verify(e.c.gpa, e.c.io, snapshot.value);
        try e.checkCache(snapshot.value);
    }
    try quiescent(e, action, null);
}

/// Only this explicit one-action authorization resolves its exact producer-owned
/// storage hold. The original job remains running/unknown; every other job and
/// manual hold still goes through the unchanged ordinary hold checks.
pub fn authorizedStorageJob(e: *core.Engine, name: []const u8, job: lifecycle.Job) !bool {
    if (e.actions.items.len != 1 or job.state != .running) return false;
    const action = e.actions.items[0];
    if (action.interrupted_workspace_recovery == null) return false;
    const row = (try selected(e, action)).row;
    if (!std.mem.eql(u8, row.original_job.path, name) or !std.mem.eql(u8, action.run_root, job.run_root)) return false;
    var kept: std.ArrayList(p.Evidence) = .empty;
    try verifyControls(e, action, &kept, false);
    return true;
}

pub fn verifyQualifiedTree(e: *core.Engine, action: core.Action, current: core.fa.Snapshot) !void {
    const row = (try selected(e, action)).row;
    try e.check(row.tree);
    var parsed = try e.loadLimit(e.c.gpa, row.tree.path, 512 * 1024 * 1024);
    defer parsed.deinit();
    const expected = try std.json.parseFromValue(core.fa.Snapshot, e.c.a, parsed.value, .{ .allocate = .alloc_always });
    if (!std.mem.eql(u8, expected.value.root, current.root) or expected.value.entries.len != current.entries.len) return error.InterruptedWorkspaceTreeChanged;
    for (expected.value.entries, current.entries) |old, new| {
        const same_hash = if (old.sha256) |hash| new.sha256 != null and std.mem.eql(u8, hash, new.sha256.?) else new.sha256 == null;
        if (!std.mem.eql(u8, old.path, new.path) or !old.metadata.eql(new.metadata) or !same_hash)
            return error.InterruptedWorkspaceTreeChanged;
    }
}

test "interrupted recovery requires the observed owner and closed process families" {
    const ev: p.Evidence = .{ .path = "observation.json", .sha256 = "unused-in-pure-test" };
    const processes: Processes = .{ .observation = ev, .pids = &.{ 123, 124 }, .groups = &.{123}, .sessions = &.{100} };
    try std.testing.expect(validProcesses(processes, 123));
    try std.testing.expect(!validProcesses(processes, 125));
    try std.testing.expect(!validProcesses(.{ .observation = ev, .pids = &.{0}, .groups = &.{123}, .sessions = &.{100} }, 0));
    try std.testing.expect(try processSnapshotBusy(" PID PGID SID COMMAND\n 124 999 999 worker\n", processes));
    try std.testing.expect(try processSnapshotBusy("777 123 999 new-descendant\n", processes));
    try std.testing.expect(try processSnapshotBusy("778 777 100 detached-descendant\n", processes));
    try std.testing.expect(!try processSnapshotBusy("779 779 779 unrelated\n", processes));
    try std.testing.expectError(error.InvalidProcessSnapshot, processSnapshotBusy("bad truncated snapshot\n", processes));
}
