//! Evidence-based project storage collection; see docs/storage_cleanup.md.
const std = @import("std");
const u = @import("validation/common.zig");
const core = @import("storage_cleanup/engine.zig");
const mutation = @import("storage_cleanup/mutation.zig");
const coverage = @import("storage_cleanup/coverage.zig");
const release = @import("storage_cleanup/release.zig");
const inventory = @import("storage_cleanup/inventory.zig");
const batch = @import("storage_cleanup/batch.zig");
const p = core.p;
const usage =
    \\usage: tools/clean-storage [--minimal] [--apply] [--policy FILE]
    \\       tools/clean-storage exec -- COMMAND [ARG...]
    \\       tools/clean-storage maintain -- COMMAND [ARG...]
    \\       tools/clean-storage maintain --release-request FILE -- COMMAND [ARG...]
    \\       tools/clean-storage share-inputs --inputs PLAN [--apply]
    \\       tools/clean-storage prepare-pins --requests FILE --review REPORT [--manifests PLAN]
    \\       tools/clean-storage --requests FILE --complete-capture-aliases [--apply]
    \\       tools/clean-storage --requests FILE --complete-artifact-aliases [--apply]
    \\       tools/clean-storage release-trace --audit FILE --build FILE --reason TEXT
    \\           [--reconstruction FILE ...]
    \\           [--compiler-retirement RECORD.json]
    \\       tools/clean-storage release --request FILE
    \\       tools/clean-storage release-workspace --layout FILE --reason TEXT
    \\       tools/clean-storage release-build --build FILE --reason TEXT [--successor FILE]
    \\           [--reconstruction FILE ...]
    \\       tools/clean-storage inventory [--policy FILE]
    \\       tools/clean-storage prepare-builds --builds FILE --reason TEXT [--successor FILE]
    \\       tools/clean-storage prepare-caches --caches FILE --reason TEXT
    \\       tools/clean-storage prepare-traces --traces FILE --reason TEXT
    \\       tools/clean-storage prepare-generated --paths FILE --reason TEXT
    \\       tools/clean-storage prepare-outputs --reports FILE --reason TEXT
    \\       tools/clean-storage prepare-pins --requests FILE --review FILE
    \\       tools/clean-storage [--apply] --requests FILE
    \\
    \\Without --apply, writes a review with reasons and makes no artifact changes.
    \\--apply discovers again and collects eligible completed private caches and
    \\explicitly released artifacts. Unknown or pinned files are retained.
    \\--minimal removes the optional idle delay and reviews up to 1024 candidates;
    \\all provenance, pins, consumers and the policy's byte limit still apply.
    \\maintain runs a command under the reader lease, then applies minimal cleanup.
    \\Policy defaults to docs/storage_cleanup_policy.json. JSON reports are saved
    \\under local-state/retirements/automatic-storage-cleanup/.
    \\Use exec for builds/readers to hold the shared cleanup lock. Add queued
    \\work to local-state/storage-cleanup/holds.json before starting it.
    \\
;
pub fn main(init: std.process.Init) !void {
    var c = try u.Context.init(init);
    errdefer if (c.diagnostic) |d| c.print("{s}\n", .{d}) catch {};
    const args = try init.minimal.args.toSlice(c.a);
    var apply = false;
    var minimal = false;
    var capture_aliases = false;
    var artifact_aliases = false;
    var policy_path: []const u8 = "docs/storage_cleanup_policy.json";
    const release_trace = args.len > 1 and std.mem.eql(u8, args[1], "release-trace");
    const release_request = args.len > 1 and std.mem.eql(u8, args[1], "release");
    const release_build = args.len > 1 and std.mem.eql(u8, args[1], "release-build");
    const release_workspace = args.len > 1 and std.mem.eql(u8, args[1], "release-workspace");
    const publishing = release_trace or release_request or release_build or release_workspace;
    var workspace_layout: ?[]const u8 = null;
    const inventory_requested = args.len > 1 and std.mem.eql(u8, args[1], "inventory");
    const share_inputs = args.len > 1 and std.mem.eql(u8, args[1], "share-inputs");
    var inputs_plan: ?[]const u8 = null;
    const prepare_builds = args.len > 1 and std.mem.eql(u8, args[1], "prepare-builds");
    const prepare_caches = args.len > 1 and std.mem.eql(u8, args[1], "prepare-caches");
    const prepare_traces = args.len > 1 and std.mem.eql(u8, args[1], "prepare-traces");
    const prepare_generated = args.len > 1 and std.mem.eql(u8, args[1], "prepare-generated");
    const prepare_outputs = args.len > 1 and std.mem.eql(u8, args[1], "prepare-outputs");
    const prepare_pins = args.len > 1 and std.mem.eql(u8, args[1], "prepare-pins");
    var requests_path: ?[]const u8 = null;
    var builds_path: ?[]const u8 = null;
    var caches_path: ?[]const u8 = null;
    var traces_path: ?[]const u8 = null;
    var generated_paths: ?[]const u8 = null;
    var compiler_retirement_path: ?[]const u8 = null;
    var review_path: ?[]const u8 = null;
    var reviewed_manifests: ?[]const u8 = null;
    var request_path: ?[]const u8 = null;
    var successor_path: ?[]const u8 = null;
    var audit_path: ?[]const u8 = null;
    var build_path: ?[]const u8 = null;
    var reason: ?[]const u8 = null;
    var reconstruction_paths: std.ArrayList([]const u8) = .empty;
    var i: usize = if (publishing or inventory_requested or share_inputs or prepare_builds or prepare_pins or prepare_caches or prepare_traces or prepare_generated or prepare_outputs) 2 else 1;
    while (i < args.len) : (i += 1) {
        if (std.mem.eql(u8, args[i], "--help")) return c.print("{s}", .{usage});
        if (std.mem.eql(u8, args[i], "--apply")) {
            apply = true;
            continue;
        }
        if (std.mem.eql(u8, args[i], "--minimal")) {
            minimal = true;
            continue;
        }
        if (std.mem.eql(u8, args[i], "--complete-capture-aliases")) {
            capture_aliases = true;
            continue;
        }
        if (std.mem.eql(u8, args[i], "--complete-artifact-aliases")) {
            artifact_aliases = true;
            continue;
        }
        if (share_inputs and std.mem.eql(u8, args[i], "--inputs") and i + 1 < args.len) {
            i += 1;
            inputs_plan = args[i];
            continue;
        }
        if (std.mem.eql(u8, args[i], "--policy") and i + 1 < args.len) {
            i += 1;
            policy_path = args[i];
            continue;
        }
        if (std.mem.eql(u8, args[i], "--requests") and i + 1 < args.len) {
            i += 1;
            requests_path = args[i];
            continue;
        }
        if (release_workspace and i + 1 < args.len) {
            if (std.mem.eql(u8, args[i], "--layout")) {
                i += 1;
                workspace_layout = args[i];
                continue;
            }
            if (std.mem.eql(u8, args[i], "--reason")) {
                i += 1;
                reason = args[i];
                continue;
            }
        }
        if (prepare_builds and std.mem.eql(u8, args[i], "--builds") and i + 1 < args.len) {
            i += 1;
            builds_path = args[i];
            continue;
        }
        if (prepare_caches and std.mem.eql(u8, args[i], "--caches") and i + 1 < args.len) {
            i += 1;
            caches_path = args[i];
            continue;
        }
        if (prepare_traces and std.mem.eql(u8, args[i], "--traces") and i + 1 < args.len) {
            i += 1;
            traces_path = args[i];
            continue;
        }
        if (release_trace and std.mem.eql(u8, args[i], "--compiler-retirement") and i + 1 < args.len) {
            i += 1;
            compiler_retirement_path = args[i];
            continue;
        }
        if (((prepare_generated and std.mem.eql(u8, args[i], "--paths")) or (prepare_outputs and std.mem.eql(u8, args[i], "--reports"))) and i + 1 < args.len) {
            i += 1;
            generated_paths = args[i];
            continue;
        }
        if ((prepare_caches or prepare_traces or prepare_generated or prepare_outputs) and std.mem.eql(u8, args[i], "--reason") and i + 1 < args.len) {
            i += 1;
            reason = args[i];
            continue;
        }
        if (prepare_pins and std.mem.eql(u8, args[i], "--review") and i + 1 < args.len) {
            i += 1;
            review_path = args[i];
            continue;
        }
        if (prepare_pins and std.mem.eql(u8, args[i], "--manifests") and i + 1 < args.len) {
            i += 1;
            reviewed_manifests = args[i];
            continue;
        }
        if ((release_trace or release_build or prepare_builds) and i + 1 < args.len) {
            if ((release_build or prepare_builds) and std.mem.eql(u8, args[i], "--successor")) {
                i += 1;
                successor_path = args[i];
                continue;
            }
            if (std.mem.eql(u8, args[i], "--reconstruction")) {
                i += 1;
                try reconstruction_paths.append(c.a, args[i]);
                continue;
            }
            if (std.mem.eql(u8, args[i], "--audit")) {
                i += 1;
                audit_path = args[i];
                continue;
            }
            if (std.mem.eql(u8, args[i], "--build")) {
                i += 1;
                build_path = args[i];
                continue;
            }
            if (std.mem.eql(u8, args[i], "--reason")) {
                i += 1;
                reason = args[i];
                continue;
            }
        }
        if (release_request and std.mem.eql(u8, args[i], "--request") and i + 1 < args.len) {
            i += 1;
            request_path = args[i];
            continue;
        }
        return error.UnknownArgument;
    }
    if (release_trace and (apply or minimal or audit_path == null or build_path == null or reason == null)) return error.InvalidReleaseArguments;
    if (release_request and (apply or minimal or request_path == null)) return error.InvalidReleaseArguments;
    if (release_build and (apply or minimal or build_path == null or reason == null or audit_path != null)) return error.InvalidReleaseArguments;
    if (release_workspace and (apply or minimal or workspace_layout == null or reason == null)) return error.InvalidReleaseArguments;
    if (inventory_requested and apply) return error.InventoryIsReadOnly;
    if (share_inputs and (inputs_plan == null or minimal or requests_path != null)) return error.InvalidSharedInputPlan;
    if ((prepare_builds or prepare_pins or prepare_caches or prepare_traces or prepare_generated) and (apply or minimal)) return error.PreparationIsReadOnly;
    if ((prepare_generated or prepare_outputs) and (generated_paths == null or reason == null)) return error.InvalidReleaseArguments;
    if (prepare_caches and (caches_path == null or reason == null)) return error.InvalidReleaseArguments;
    if (prepare_traces and (traces_path == null or reason == null)) return error.InvalidReleaseArguments;
    if (prepare_builds and (builds_path == null or reason == null)) return error.InvalidReleaseArguments;
    if (prepare_pins and (requests_path == null or review_path == null)) return error.InvalidReleaseArguments;
    if (publishing and requests_path != null) return error.InvalidReleaseArguments;
    if ((capture_aliases or artifact_aliases) and (requests_path == null or publishing or share_inputs or prepare_builds or prepare_caches or prepare_traces or prepare_generated or prepare_outputs or prepare_pins)) return error.InvalidCaptureAliasArguments;
    if (!p.relative(policy_path)) return error.InvalidPolicyPath;
    const policy_absolute = try c.join(&.{policy_path});
    var policy_dir = try core.fa.metadata.openRoot(c.io, std.fs.path.dirname(policy_absolute).?);
    defer policy_dir.close(c.io);
    const policy_name = std.fs.path.basename(policy_absolute);
    const policy_metadata = try core.fa.metadata.child(c.gpa, policy_dir, policy_name);
    const bytes = try core.fa.metadata.readFile(c.gpa, c.io, policy_dir, policy_name, policy_metadata, 1024 * 1024);
    defer c.gpa.free(bytes);
    const policy_sha256 = try u.digestBytes(c.a, bytes);
    const parsed_config = try std.json.parseFromSlice(p.Config, c.a, bytes, .{});
    try p.validate(parsed_config.value);
    const config = if (minimal or publishing) p.minimal(parsed_config.value) else parsed_config.value;
    const state = "local-state/storage-cleanup";
    try std.Io.Dir.cwd().createDirPath(c.io, try c.join(&.{state}));
    var state_dir = try core.fa.metadata.openRoot(c.io, try c.join(&.{state}));
    defer state_dir.close(c.io);
    const lock = try state_dir.createFile(c.io, "cleanup.lock", .{ .truncate = false });
    defer lock.close(c.io);
    if (!try lock.tryLock(c.io, .exclusive)) return c.fail("Cleanup skipped: another collector or a reader/build holds the storage lock.", .{});
    defer lock.unlock(c.io);
    if (u.exists(c.io, try c.join(&.{mutation.pending_path}))) return c.fail("An interrupted cleanup needs review: {s}. No new deletion attempted.", .{mutation.pending_path});
    const output = try c.fmt("local-state/retirements/automatic-storage-cleanup/{d}-{d}", .{ std.Io.Clock.real.now(c.io).nanoseconds, std.os.linux.getpid() });
    _ = try c.newOutput(output);
    const zigrep = c.env.get("ZIGREP") orelse "zigrep";
    var e = core.Engine.init(&c, config, output, zigrep);
    e.allow_capture_aliases = capture_aliases;
    e.allow_artifact_aliases = artifact_aliases;
    e.collector_binary_sha256 = try c.digest("/proc/self/exe");
    e.collector_sources = try collectorSources(&c);
    var status: []const u8 = "failed";
    defer report(&e, status, apply, minimal) catch {};
    try e.check(.{ .path = policy_path, .sha256 = policy_sha256 });
    try e.addControl(policy_path);
    if (share_inputs) {
        try @import("storage_cleanup/shared_inputs.zig").run(&e, inputs_plan.?, apply);
        status = "complete";
        return;
    }
    if (prepare_builds or prepare_pins or prepare_caches or prepare_traces or prepare_generated or prepare_outputs) {
        if (prepare_builds) try batch.builds(&e, builds_path.?, successor_path, reason.?) else if (prepare_caches) try batch.caches(&e, caches_path.?, reason.?) else if (prepare_traces) try batch.traces(&e, traces_path.?, reason.?) else if (prepare_generated) try batch.generated(&e, generated_paths.?, reason.?) else if (prepare_outputs) try batch.outputs(&e, generated_paths.?, reason.?) else try batch.reviewedPins(&e, requests_path.?, review_path.?, reviewed_manifests);
        status = "prepared";
        return;
    }
    if (publishing) {
        try e.currentManifests(true);
        if (release_workspace) {
            const published = try @import("storage_cleanup/workspaces.zig").publish(&e, workspace_layout.?, reason.?);
            status = "release-published";
            try c.print("Workspace release: {s}; payload retained until --apply.\n", .{published});
            return;
        }
        var reconstructions: std.ArrayList(p.Evidence) = .empty;
        for (reconstruction_paths.items) |path| {
            if (!p.relative(path)) return error.InvalidEvidencePath;
            try reconstructions.append(c.a, .{ .path = path, .sha256 = try e.digest(path) });
        }
        const compiler_retirement: ?p.Evidence = if (compiler_retirement_path) |path| blk: {
            if (!p.relative(path)) return error.InvalidEvidencePath;
            break :blk .{ .path = path, .sha256 = try e.digest(path) };
        } else null;
        const published = if (release_trace) try release.publish(&e, try release.traceRequest(&e, audit_path.?, build_path.?, reason.?, reconstructions.items, compiler_retirement)) else if (release_build) if (successor_path) |accepted| try release.compilerBuild(&e, build_path.?, accepted, reason.?, reconstructions.items) else try release.publish(&e, try release.disposableBuild(&e, build_path.?, reason.?)) else try release.request(&e, request_path.?);
        status = "release-published";
        try c.print("Published verified release: {s}\nRun tools/clean-storage --minimal --apply to collect it.\n", .{published});
        return;
    }
    try c.print("Discovering completed runs and release records...\n", .{});
    try e.discover();
    if (requests_path) |path| try batch.discover(&e, path);
    try e.loadHolds();
    // Required control files must still exist on a no-op pass. Expensive
    // target/alias checks are needed only if provenance admits any candidate.
    try e.currentManifests(false);
    try c.print("Checking active consumers and retained source/build evidence...\n", .{});
    try e.consumers();
    for (e.actions.items, 0..) |*a, index| {
        if (a.status != .discovered) continue;
        e.qualify(index) catch |err| {
            a.status = .skipped;
            a.reason = try c.fmt("{s}", .{@errorName(err)});
            continue;
        };
    }
    try e.protectRetained();
    if (e.hasReady()) {
        try c.print("Checking retention pins for {d} candidates...\n", .{e.actions.items.len});
        try e.pins();
        try c.print("Verifying {d} required integrity manifests...\n", .{config.current_manifests.len});
        try e.currentManifests(true);
    } else try c.print("No provenance-qualified candidates; no deletion checks needed.\n", .{});
    // Limits count eligible candidates only, so pins cannot starve later runs.
    try e.guardCaptureGroups();
    e.applyLimits();
    try e.guardCaptureGroups();
    for (e.actions.items) |a| if (a.status == .ready) try c.print("Eligible: {s} ({d} file bytes)\n", .{ a.path, a.allocated_bytes });
    for (e.actions.items, 0..) |*a, index| {
        if (a.status != .skipped or a.measured) continue;
        e.measureHeld(index) catch |err| {
            try c.print("Could not measure held path {s}: {s}\n", .{ a.path, @errorName(err) });
        };
    }
    try coverage.write(&e, "before");
    if (inventory_requested) try inventory.write(&e);
    try report(&e, "reviewed", apply, minimal);
    if (apply and e.hasReady()) {
        try e.pinRevisions();
        for (e.actions.items, 0..) |*a, index| {
            if (a.status != .ready) continue;
            // Refresh consumers and pins immediately before each owned mutation.
            e.hash_cache.clearRetainingCapacity();
            try e.loadHolds();
            try e.pins();
            try e.consumers();
            try e.guardCaptureGroups();
            if (a.status != .ready) continue;
            const group = if (mutation.fileAction(a.*)) try mutation.fileBatch(&e, index) else &.{};
            if (group.len > 0) {
                try mutation.applyFileBatch(&e, group);
            } else try mutation.apply(&e, index);
            try report(&e, "applying", apply, minimal);
            if (group.len > 0) {
                var reclaimed_group: u64 = 0;
                for (group) |member| reclaimed_group += e.actions.items[member].reclaimed_file_bytes;
                try c.print("Removed {d} verified files ({d} allocated file bytes)\n", .{ group.len, reclaimed_group });
            } else try c.print("Removed: {s} ({d} allocated file bytes)\n", .{ a.path, a.reclaimed_file_bytes });
        }
        e.hash_cache.clearRetainingCapacity();
        try e.currentManifests(true);
        for (e.controls.items) |row| try e.check(row);
    }
    try e.compactSnapshots();
    if (apply) try coverage.write(&e, "after");
    status = "complete";
    try report(&e, status, apply, minimal);
    var ready: usize = 0;
    var kept: usize = 0;
    var removed: usize = 0;
    var reclaimed: u64 = 0;
    for (e.actions.items) |a| switch (a.status) {
        .ready => ready += 1,
        .skipped => kept += 1,
        .removed => {
            removed += 1;
            reclaimed += a.reclaimed_file_bytes;
        },
        else => {},
    };
    try c.print("Eligible: {d}; kept: {d}; removed: {d}; reclaimed allocated file bytes: {d}\n", .{ ready, kept, removed, reclaimed });
    try c.print("{s}: {s}/report.json\n", .{ if (apply) "Cleanup complete" else "Review complete", output });
}
fn report(e: *core.Engine, status: []const u8, apply: bool, minimal: bool) !void {
    if (e.pin_references.items.len != 0) try e.write(try e.c.fmt("{s}/pin-references.json", .{e.output}), e.pin_references.items);
    var ready: usize = 0;
    var skipped: usize = 0;
    var removed: usize = 0;
    var proposed: u64 = 0;
    var reclaimed: u64 = 0;
    var held_bytes: u64 = 0;
    var unmeasured: usize = 0;
    for (e.actions.items) |a| {
        switch (a.status) {
            .ready => {
                ready += 1;
                proposed += a.allocated_bytes;
            },
            .skipped => {
                skipped += 1;
                if (a.measured) held_bytes += a.allocated_bytes else unmeasured += 1;
            },
            .removed => {
                removed += 1;
                reclaimed += a.reclaimed_file_bytes;
            },
            else => {},
        }
    }
    try e.write(try e.c.fmt("{s}/report.json", .{e.output}), .{ .schema = "zllvm-storage-cleanup-v1", .status = status, .mode = if (apply) "apply" else "review", .retention = if (minimal) "minimal" else "policy", .effective_policy = e.config, .ready = ready, .skipped = skipped, .removed = removed, .proposed_allocated_file_bytes = proposed, .held_allocated_file_bytes = held_bytes, .unmeasured_candidates = unmeasured, .reclaimed_allocated_file_bytes = reclaimed, .producer_reports = e.producer_reports, .release_records = e.released_records, .pin_files_checked = e.checked_manifests, .current_integrity_verified = e.current_integrity_verified, .collector = .{ .binary_sha256 = e.collector_binary_sha256, .zig_version = @import("builtin").zig_version_string, .compiled_sources = e.collector_sources }, .source_revisions = e.revisions.items, .controls = e.controls.items, .actions = e.actions.items });
}
fn collectorSources(c: *u.Context) ![]const core.Evidence {
    const Source = struct { path: []const u8, bytes: []const u8 };
    const files = [_]Source{
        .{ .path = "tools/clean_storage.zig", .bytes = @embedFile("clean_storage.zig") },
        .{ .path = "tools/storage_cleanup/engine.zig", .bytes = @embedFile("storage_cleanup/engine.zig") },
        .{ .path = "tools/storage_cleanup/mutation.zig", .bytes = @embedFile("storage_cleanup/mutation.zig") },
        .{ .path = "tools/storage_cleanup/policy.zig", .bytes = @embedFile("storage_cleanup/policy.zig") },
        .{ .path = "tools/storage_cleanup/coverage.zig", .bytes = @embedFile("storage_cleanup/coverage.zig") },
        .{ .path = "tools/storage_cleanup/release.zig", .bytes = @embedFile("storage_cleanup/release.zig") },
        .{ .path = "tools/storage_cleanup/historical.zig", .bytes = @embedFile("storage_cleanup/historical.zig") },
        .{ .path = "tools/storage_cleanup/inventory.zig", .bytes = @embedFile("storage_cleanup/inventory.zig") },
        .{ .path = "tools/storage_cleanup/batch.zig", .bytes = @embedFile("storage_cleanup/batch.zig") },
        .{ .path = "tools/storage_cleanup/private_cache.zig", .bytes = @embedFile("storage_cleanup/private_cache.zig") },
        .{ .path = "tools/storage_cleanup/retired_compiler.zig", .bytes = @embedFile("storage_cleanup/retired_compiler.zig") },
        .{ .path = "tools/storage_cleanup/generated.zig", .bytes = @embedFile("storage_cleanup/generated.zig") },
        .{ .path = "tools/storage_cleanup/command_outputs.zig", .bytes = @embedFile("storage_cleanup/command_outputs.zig") },
        .{ .path = "tools/storage_cleanup/retired_logs.zig", .bytes = @embedFile("storage_cleanup/retired_logs.zig") },
        .{ .path = "tools/storage_cleanup/jobs.zig", .bytes = @embedFile("storage_cleanup/jobs.zig") },
        .{ .path = "tools/storage_cleanup/shared_inputs.zig", .bytes = @embedFile("storage_cleanup/shared_inputs.zig") },
        .{ .path = "tools/storage_cleanup/workspaces.zig", .bytes = @embedFile("storage_cleanup/workspaces.zig") },
        .{ .path = "tools/zllvm_artifact_store/store.zig", .bytes = @embedFile("zllvm_artifact_store/store.zig") },
        .{ .path = "tools/validation/storage_lifecycle.zig", .bytes = @embedFile("validation/storage_lifecycle.zig") },
        .{ .path = "tools/validation/storage_paths.zig", .bytes = @embedFile("validation/storage_paths.zig") },
        .{ .path = "tools/validation/storage_workspace.zig", .bytes = @embedFile("validation/storage_workspace.zig") },
        .{ .path = "tools/validation/toolchain.zig", .bytes = @embedFile("validation/toolchain.zig") },
        .{ .path = "tools/validation/common.zig", .bytes = @embedFile("validation/common.zig") },
        .{ .path = "tools/vendor/file_audit.SHA256SUMS", .bytes = @embedFile("vendor/file_audit.SHA256SUMS") },
        .{ .path = "tools/vendor/process.SHA256SUMS", .bytes = @embedFile("vendor/process.SHA256SUMS") },
        .{ .path = "tools/vendor/test_support.SHA256SUMS", .bytes = @embedFile("vendor/test_support.SHA256SUMS") },
    };
    var result: std.ArrayList(core.Evidence) = .empty;
    for (files) |file| try result.append(c.a, .{ .path = file.path, .sha256 = try u.digestBytes(c.a, file.bytes) });
    return result.toOwnedSlice(c.a);
}
comptime {
    if (@import("builtin").is_test) {
        _ = @import("storage_cleanup/tests.zig");
        _ = @import("storage_cleanup/inventory.zig");
    }
}
