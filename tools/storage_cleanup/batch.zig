//! Explicit, reviewable requests for historical completed builds.
const std = @import("std");
const core = @import("engine.zig");
const release = @import("release.zig");
const private_cache = @import("private_cache.zig");
const p = core.p;
const u = @import("../validation/common.zig");
pub const List = struct { schema: []const u8 = "zllvm-storage-requests-v1", requests: []const p.Evidence };
pub const TraceEntry = struct { audit: []const u8, build: []const u8, compiler_retirement: ?[]const u8 = null, source_reconstructions: []const p.Evidence = &.{} };

pub fn generated(e: *core.Engine, paths_file: []const u8, reason: []const u8) !void {
    return outputRequests(e, paths_file, reason, .generated);
}
pub fn outputs(e: *core.Engine, paths_file: []const u8, reason: []const u8) !void {
    return outputRequests(e, paths_file, reason, .outputs);
}
pub fn closedOutputs(e: *core.Engine, paths_file: []const u8, reason: []const u8) !void {
    return outputRequests(e, paths_file, reason, .closed_outputs);
}
pub fn observedCompilers(e: *core.Engine, paths_file: []const u8, reason: []const u8) !void {
    return outputRequests(e, paths_file, reason, .observed_compilers);
}
fn outputRequests(e: *core.Engine, paths_file: []const u8, reason: []const u8, mode: enum { generated, outputs, closed_outputs, observed_compilers }) !void {
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
        const candidate = (switch (mode) {
            .closed_outputs => @import("command_outputs.zig").requestClosed(e, owned, reason),
            .outputs => @import("command_outputs.zig").request(e, owned, reason),
            .generated => @import("generated.zig").request(e, owned, reason),
            .observed_compilers => @import("observed_compiler.zig").request(e, owned, reason),
        }) catch |err| {
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
    var peers: std.ArrayList(p.Evidence) = .empty;
    for (plan.value.traces) |entry| {
        var audit = try e.load(e.c.gpa, entry.audit);
        defer audit.deinit();
        try peers.append(e.c.a, .{ .path = try e.relative(try core.str(audit.value, "path")), .sha256 = try e.c.a.dupe(u8, try core.str(audit.value, "sha256")) });
    }
    var candidates: std.ArrayList(p.Release) = .empty;
    for (plan.value.traces) |entry| {
        const retired: ?p.Evidence = if (entry.compiler_retirement) |path| blk: {
            if (!p.relative(path)) return error.InvalidEvidencePath;
            break :blk .{ .path = path, .sha256 = try e.digest(path) };
        } else null;
        const candidate = try release.traceRequestWithPeers(e, entry.audit, entry.build, reason, entry.source_reconstructions, retired, peers.items);
        try candidates.append(e.c.a, candidate);
    }
    var requests: std.ArrayList(p.Evidence) = .empty;
    for (try jointTraces(e, candidates.items)) |candidate| {
        const destination = try e.c.fmt("{s}/request-{d}.json", .{ e.output, requests.items.len });
        try e.write(destination, candidate);
        try requests.append(e.c.a, .{ .path = destination, .sha256 = try e.digest(destination) });
    }
    try e.write(try e.c.fmt("{s}/requests.json", .{e.output}), List{ .requests = requests.items });
    try e.c.print("Prepared {d} audited-trace requests; no payloads changed. Review with:\ntools/clean-storage --requests {s}/requests.json\n", .{ requests.items.len, e.output });
}

/// Distinct captures of one producer must not pin each other's raw streams.
/// Join only compatible explicit requests; retain every audit and all other
/// evidence. Each artifact still passes its own native qualification/mutation.
pub fn jointTraces(e: *core.Engine, candidates: []const p.Release) ![]const p.Release {
    var groups: std.ArrayList(p.Release) = .empty;
    for (candidates) |candidate| {
        if (candidate.state != .audited or candidate.retired_pins.len != 0) return error.InvalidTraceGroup;
        for (candidate.artifacts) |artifact| if (artifact.kind != .raw_trace) return error.InvalidTraceGroup;
        var match: ?usize = null;
        for (groups.items, 0..) |group, i| {
            if (std.mem.eql(u8, group.run_root, candidate.run_root) and
                u.json.eql(try u.toValue(e.c.a, group.producer), try u.toValue(e.c.a, candidate.producer)) and
                u.json.eql(try u.toValue(e.c.a, group.compiler_retirement), try u.toValue(e.c.a, candidate.compiler_retirement)) and
                u.json.eql(try u.toValue(e.c.a, group.source_reconstructions), try u.toValue(e.c.a, candidate.source_reconstructions)))
            {
                match = i;
                break;
            }
        }
        if (match) |i| {
            groups.items[i].artifacts = try std.mem.concat(e.c.a, p.Artifact, &.{ groups.items[i].artifacts, candidate.artifacts });
            groups.items[i].retained = try std.mem.concat(e.c.a, p.Retained, &.{ groups.items[i].retained, candidate.retained });
        } else try groups.append(e.c.a, candidate);
    }
    for (groups.items) |*group| {
        var artifacts = std.StringHashMap([]const u8).init(e.c.a);
        for (group.artifacts) |artifact| {
            const entry = try artifacts.getOrPut(artifact.path);
            if (entry.found_existing) return error.DuplicateTraceArtifact;
            entry.value_ptr.* = artifact.sha256;
        }
        var seen = std.StringHashMap([]const u8).init(e.c.a);
        var roles = std.StringHashMap(void).init(e.c.a);
        var kept: std.ArrayList(p.Retained) = .empty;
        for (group.retained) |row| {
            if (artifacts.get(row.path)) |hash| {
                if (!std.mem.eql(u8, row.sha256, hash)) return error.RetainedArtifactHashMismatch;
                continue;
            }
            const entry = try seen.getOrPut(row.path);
            if (entry.found_existing) {
                if (!std.mem.eql(u8, entry.value_ptr.*, row.sha256)) return error.EvidenceHashMismatch;
            } else {
                entry.value_ptr.* = row.sha256;
            }
            // A canonical build receipt is both build and source evidence.
            // Preserve distinct roles even when the path and hash coincide.
            const role_key = try e.c.fmt("{s}\n{s}", .{ row.path, @tagName(row.role) });
            if ((try roles.getOrPut(role_key)).found_existing) continue;
            try kept.append(e.c.a, row);
        }
        group.retained = kept.items;
    }
    return groups.items;
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
    return reviewedPins(e, requests_path, review_path, null);
}

/// An explicit reviewed manifest list permits exact target transitions only.
/// It never retires a whole manifest or exempts a current integrity contract.
pub fn reviewedPins(e: *core.Engine, requests_path: []const u8, review_path: []const u8, manifests_path: ?[]const u8) !void {
    var reviewed: []const p.Evidence = &.{};
    var reviewed_reason: []const u8 = "";
    if (manifests_path) |path| {
        if (!p.relative(path)) return error.InvalidEvidencePath;
        try e.addControl(path);
        const json = try e.load(e.c.a, path);
        const Plan = struct { schema: []const u8, reason: []const u8, manifests: []const p.Evidence };
        const plan = (try std.json.parseFromValue(Plan, e.c.a, json.value, .{})).value;
        if (!std.mem.eql(u8, plan.schema, "zllvm-reviewed-pin-manifests-v1") or plan.reason.len == 0 or plan.manifests.len == 0) return error.InvalidManifestReview;
        for (plan.manifests) |manifest| {
            for (e.config.current_manifests) |current| if (std.mem.eql(u8, current, manifest.path)) return error.CurrentManifestCannotBeRetired;
            try e.check(manifest);
        }
        reviewed = plan.manifests;
        reviewed_reason = plan.reason;
    }
    const requests = try load(e, requests_path);
    if (!p.relative(review_path)) return error.InvalidEvidencePath;
    try e.addControl(review_path);
    // A 16K-candidate review can exceed the ordinary 32 MiB evidence limit.
    // This larger bound applies only to the explicitly selected collector report.
    var review = try e.loadLimit(e.c.gpa, review_path, 128 * 1024 * 1024);
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
    var qualified_actions = std.StringHashMap(void).init(e.c.a);
    for ((try core.get(review.value, "actions")).array.items) |action| {
        const retained = try core.get(action, "retained");
        if (retained != .array or retained.array.items.len == 0) continue;
        try qualified_actions.put(try e.c.fmt("{s}\n{s}", .{ try core.str(action, "producer"), try core.str(action, "path") }), {});
    }
    var candidate_pins = std.StringHashMap(std.ArrayList(core.PinReference)).init(e.c.a);
    for (pins.value) |pin| {
        const group = try candidate_pins.getOrPut(pin.candidate);
        if (!group.found_existing) group.value_ptr.* = .empty;
        try group.value_ptr.append(e.c.a, pin);
    }
    var terminal_manifests = std.StringHashMap(bool).init(e.c.a);
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
            if (!qualified_actions.contains(try e.c.fmt("{s}\n{s}", .{ request.path, artifact.path }))) continue;
            const matches = candidate_pins.get(artifact.path) orelse continue;
            for (matches.items) |pin| {
                var explicitly_reviewed = false;
                for (reviewed) |manifest| if (std.mem.eql(u8, manifest.path, pin.manifest.path) and std.mem.eql(u8, manifest.sha256, pin.manifest.sha256)) {
                    explicitly_reviewed = true;
                };
                if (pin.retired or !std.mem.eql(u8, pin.candidate, artifact.path) or pin.reference == null or pin.sha256 == null or
                    !std.ascii.eqlIgnoreCase(pin.sha256.?, artifact.sha256) or (!explicitly_reviewed and !p.within("local-state/retirements", pin.manifest.path))) continue;
                for (e.config.current_manifests) |current| if (std.mem.eql(u8, current, pin.manifest.path)) return error.CurrentManifestCannotBeRetired;
                try e.check(pin.manifest);
                if (!explicitly_reviewed and std.mem.endsWith(u8, pin.manifest.path, ".json")) {
                    // The hash/path observation is checked above on every use.
                    // Only parsing the immutable terminal status is shared.
                    const complete = terminal_manifests.get(pin.manifest.path) orelse blk: {
                        var old = try e.load(e.c.gpa, pin.manifest.path);
                        defer old.deinit();
                        const result = core.eq(old.value, "status", "complete");
                        try terminal_manifests.put(pin.manifest.path, result);
                        break :blk result;
                    };
                    if (!complete) continue;
                }
                try transitions.append(e.c.a, .{ .manifest = pin.manifest, .reference = pin.reference.?, .target = .{ .path = artifact.path, .sha256 = artifact.sha256 }, .reason = if (explicitly_reviewed) reviewed_reason else if (record.value.state == .disposable) "User-authorized disposal of completed temporary build output; this historical reference does not require preserving its binary" else "Completed historical retirement pin replaced by verified source/build/result evidence and the explicitly accepted successor" });
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
