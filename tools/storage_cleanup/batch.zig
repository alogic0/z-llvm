//! Explicit, reviewable requests for historical completed builds.
const std = @import("std");
const core = @import("engine.zig");
const release = @import("release.zig");
const private_cache = @import("private_cache.zig");
const p = core.p;
const List = struct { schema: []const u8 = "zllvm-storage-requests-v1", requests: []const p.Evidence };
pub const TraceEntry = struct { audit: []const u8, build: []const u8, compiler_retirement: ?[]const u8 = null, source_reconstructions: []const p.Evidence = &.{} };

pub fn generated(e: *core.Engine, paths_file: []const u8, reason: []const u8) !void {
    if (!p.relative(paths_file) or reason.len == 0) return error.InvalidEvidencePath;
    try e.addControl(paths_file);
    const bytes = try e.read(e.c.gpa, paths_file, 1024 * 1024);
    defer e.c.gpa.free(bytes);
    var paths = std.mem.tokenizeScalar(u8, bytes, '\n');
    var seen = std.StringHashMap(void).init(e.c.a);
    var requests: std.ArrayList(p.Evidence) = .empty;
    const Rejected = struct { path: []const u8, reason: []const u8 };
    var rejected: std.ArrayList(Rejected) = .empty;
    while (paths.next()) |path| {
        if (seen.count() >= 1024 or seen.contains(path)) return error.InvalidRequestList;
        const owned = try e.c.a.dupe(u8, path);
        try seen.put(owned, {});
        const candidate = @import("generated.zig").request(e, owned, reason) catch |err| {
            try rejected.append(e.c.a, .{ .path = owned, .reason = @errorName(err) });
            continue;
        };
        const destination = try e.c.fmt("{s}/request-{d}.json", .{ e.output, requests.items.len });
        try e.write(destination, candidate);
        try requests.append(e.c.a, .{ .path = destination, .sha256 = try e.digest(destination) });
    }
    try e.write(try e.c.fmt("{s}/generated-review.json", .{e.output}), .{ .prepared = requests.items.len, .rejected = rejected.items });
    if (requests.items.len != 0) try e.write(try e.c.fmt("{s}/requests.json", .{e.output}), List{ .requests = requests.items });
    try e.c.print("Prepared {d} generated-output requests; {d} entries need review. No payloads changed.\n{s}/generated-review.json\n", .{ requests.items.len, rejected.items.len, e.output });
}

pub fn traces(e: *core.Engine, plan_path: []const u8, reason: []const u8) !void {
    if (!p.relative(plan_path) or reason.len == 0) return error.InvalidEvidencePath;
    try e.addControl(plan_path);
    var parsed = try e.load(e.c.gpa, plan_path);
    defer parsed.deinit();
    const Plan = struct { schema: []const u8, traces: []const TraceEntry };
    var plan = try std.json.parseFromValue(Plan, e.c.gpa, parsed.value, .{});
    defer plan.deinit();
    if (!std.mem.eql(u8, plan.value.schema, "zllvm-trace-retirement-plan-v1") or plan.value.traces.len == 0 or plan.value.traces.len > 1024) return error.InvalidTracePlan;
    var requests: std.ArrayList(p.Evidence) = .empty;
    for (plan.value.traces) |entry| {
        const retired: ?p.Evidence = if (entry.compiler_retirement) |path| blk: {
            if (!p.relative(path)) return error.InvalidEvidencePath;
            break :blk .{ .path = path, .sha256 = try e.digest(path) };
        } else null;
        const candidate = try release.traceRequest(e, entry.audit, entry.build, reason, entry.source_reconstructions, retired);
        const destination = try e.c.fmt("{s}/request-{d}.json", .{ e.output, requests.items.len });
        try e.write(destination, candidate);
        try requests.append(e.c.a, .{ .path = destination, .sha256 = try e.digest(destination) });
    }
    try e.write(try e.c.fmt("{s}/requests.json", .{e.output}), List{ .requests = requests.items });
    try e.c.print("Prepared {d} audited-trace requests; no payloads changed. Review with:\ntools/clean-storage --requests {s}/requests.json\n", .{ requests.items.len, e.output });
}

pub fn caches(e: *core.Engine, plan_path: []const u8, reason: []const u8) !void {
    if (!p.relative(plan_path) or reason.len == 0) return error.InvalidEvidencePath;
    try e.addControl(plan_path);
    var parsed = try e.load(e.c.gpa, plan_path);
    defer parsed.deinit();
    const Plan = struct { schema: []const u8, runs: []const private_cache.PlanEntry };
    var plan = try std.json.parseFromValue(Plan, e.c.gpa, parsed.value, .{});
    defer plan.deinit();
    if (!std.mem.eql(u8, plan.value.schema, "zllvm-private-cache-plan-v1") or plan.value.runs.len > 1024) return error.InvalidCachePlan;
    var requests: std.ArrayList(p.Evidence) = .empty;
    const Rejected = struct { producer: []const u8, reason: []const u8 };
    var rejected: std.ArrayList(Rejected) = .empty;
    for (plan.value.runs) |entry| {
        const candidate = private_cache.request(e, entry, reason) catch |err| {
            try rejected.append(e.c.a, .{ .producer = try e.c.a.dupe(u8, entry.producer), .reason = @errorName(err) });
            continue;
        };
        const record = candidate orelse {
            try rejected.append(e.c.a, .{ .producer = try e.c.a.dupe(u8, entry.producer), .reason = "No present owned cache roots" });
            continue;
        };
        const destination = try e.c.fmt("{s}/request-{d}.json", .{ e.output, requests.items.len });
        try e.write(destination, record);
        try requests.append(e.c.a, .{ .path = destination, .sha256 = try e.digest(destination) });
    }
    try e.write(try e.c.fmt("{s}/cache-plan-review.json", .{e.output}), .{ .prepared = requests.items.len, .rejected = rejected.items });
    if (requests.items.len != 0) try e.write(try e.c.fmt("{s}/requests.json", .{e.output}), List{ .requests = requests.items });
    try e.c.print("Prepared {d} private-cache requests; {d} entries need review. No payloads changed.\n{s}/cache-plan-review.json\n", .{ requests.items.len, rejected.items.len, e.output });
}

pub fn load(e: *core.Engine, path: []const u8) ![]const p.Evidence {
    if (!p.relative(path)) return error.InvalidEvidencePath;
    try e.addControl(path);
    const parsed = try e.load(e.c.a, path);
    const list = (try std.json.parseFromValue(List, e.c.a, parsed.value, .{})).value;
    if (!std.mem.eql(u8, list.schema, "zllvm-storage-requests-v1") or list.requests.len == 0 or list.requests.len > 1024) return error.InvalidRequestList;
    var seen = std.StringHashMap(void).init(e.c.a);
    for (list.requests) |request| {
        if (!p.relative(request.path) or seen.contains(request.path)) return error.InvalidRequestList;
        try seen.put(request.path, {});
        try e.check(request);
        try e.addControl(request.path);
    }
    return list.requests;
}
pub fn discover(e: *core.Engine, path: []const u8) !void {
    for (try load(e, path)) |request| {
        e.released_records += 1;
        try e.discoverRelease(request.path, true);
    }
}

pub fn builds(e: *core.Engine, build_list: []const u8, successor: ?[]const u8, reason: []const u8) !void {
    if (!p.relative(build_list) or reason.len == 0) return error.InvalidEvidencePath;
    try e.addControl(build_list);
    if (successor) |path| {
        if (!p.relative(path)) return error.InvalidEvidencePath;
        var accepted = try e.load(e.c.gpa, path);
        defer accepted.deinit();
        if (!core.eq(accepted.value, "status", "passed")) return error.NoAcceptedSuccessor;
    }
    const bytes = try e.read(e.c.gpa, build_list, 1024 * 1024);
    defer e.c.gpa.free(bytes);
    var paths = std.mem.tokenizeScalar(u8, bytes, '\n');
    var requests: std.ArrayList(p.Evidence) = .empty;
    var seen = std.StringHashMap(void).init(e.c.a);
    while (paths.next()) |path| {
        if (requests.items.len >= 1024 or seen.contains(path)) return error.InvalidRequestList;
        try seen.put(try e.c.a.dupe(u8, path), {});
        const owned = try e.c.a.dupe(u8, path);
        const request = if (successor) |accepted| try release.buildRequest(e, owned, accepted, reason, &.{}) else try release.disposableBuild(e, owned, reason);
        const destination = try e.c.fmt("{s}/request-{d}.json", .{ e.output, requests.items.len });
        try e.write(destination, request);
        try requests.append(e.c.a, .{ .path = destination, .sha256 = try e.digest(destination) });
    }
    if (requests.items.len == 0) return error.InvalidRequestList;
    try e.write(try e.c.fmt("{s}/requests.json", .{e.output}), List{ .requests = requests.items });
    try e.c.print("Prepared {d} build requests; no payloads changed. Review with:\ntools/clean-storage --requests {s}/requests.json\n", .{ requests.items.len, e.output });
}

/// Only completed retirement ledgers may be transitioned by this adapter.
/// Validation-suite pins still require individual review and an explicit request.
pub fn historicalPins(e: *core.Engine, requests_path: []const u8, review_path: []const u8) !void {
    const requests = try load(e, requests_path);
    if (!p.relative(review_path)) return error.InvalidEvidencePath;
    try e.addControl(review_path);
    var review = try e.load(e.c.gpa, review_path);
    defer review.deinit();
    if (!core.eq(review.value, "status", "complete") or !core.eq(review.value, "mode", "review")) return error.IncompleteRequestReview;
    var bound = false;
    for ((try core.get(review.value, "controls")).array.items) |control| {
        if (core.eq(control, "path", requests_path) and core.eq(control, "sha256", try e.digest(requests_path))) bound = true;
    }
    if (!bound) return error.UnboundRequestReview;
    const pin_path = try e.c.fmt("{s}/pin-references.json", .{std.fs.path.dirname(review_path).?});
    try e.addControl(pin_path);
    var pin_json = try e.load(e.c.gpa, pin_path);
    defer pin_json.deinit();
    var pins = try std.json.parseFromValue([]const core.PinReference, e.c.gpa, pin_json.value, .{});
    defer pins.deinit();
    var revised: std.ArrayList(p.Evidence) = .empty;
    var transitioned: usize = 0;
    for (requests) |request| {
        var parsed = try e.load(e.c.gpa, request.path);
        defer parsed.deinit();
        var record = try std.json.parseFromValue(p.Release, e.c.gpa, parsed.value, .{});
        defer record.deinit();
        var transitions: std.ArrayList(p.PinTransition) = .empty;
        try transitions.appendSlice(e.c.a, record.value.retired_pins);
        for (record.value.artifacts) |artifact| {
            var qualified = false;
            for ((try core.get(review.value, "actions")).array.items) |action| {
                if (!core.eq(action, "producer", request.path) or !core.eq(action, "path", artifact.path)) continue;
                const retained = try core.get(action, "retained");
                if (retained == .array and retained.array.items.len > 0) qualified = true;
            }
            if (!qualified) continue;
            for (pins.value) |pin| {
                if (pin.retired or !std.mem.eql(u8, pin.candidate, artifact.path) or pin.reference == null or pin.sha256 == null or
                    !std.ascii.eqlIgnoreCase(pin.sha256.?, artifact.sha256) or !p.within("local-state/retirements", pin.manifest.path)) continue;
                for (e.config.current_manifests) |current| if (std.mem.eql(u8, current, pin.manifest.path)) return error.CurrentManifestCannotBeRetired;
                try e.check(pin.manifest);
                if (std.mem.endsWith(u8, pin.manifest.path, ".json")) {
                    var old = try e.load(e.c.gpa, pin.manifest.path);
                    defer old.deinit();
                    if (!core.eq(old.value, "status", "complete")) continue;
                }
                try transitions.append(e.c.a, .{ .manifest = pin.manifest, .reference = pin.reference.?, .target = .{ .path = artifact.path, .sha256 = artifact.sha256 }, .reason = if (record.value.state == .disposable) "User-authorized disposal of completed temporary build output; this historical reference does not require preserving its binary" else "Completed historical retirement pin replaced by verified source/build/result evidence and the explicitly accepted successor" });
                transitioned += 1;
            }
        }
        record.value.retired_pins = transitions.items;
        const destination = try e.c.fmt("{s}/request-{d}.json", .{ e.output, revised.items.len });
        try e.write(destination, record.value);
        try revised.append(e.c.a, .{ .path = destination, .sha256 = try e.digest(destination) });
    }
    try e.write(try e.c.fmt("{s}/requests.json", .{e.output}), List{ .requests = revised.items });
    try e.c.print("Prepared {d} exact historical pin transitions. Review/apply still verifies all evidence:\ntools/clean-storage --requests {s}/requests.json\n", .{ transitioned, e.output });
}
