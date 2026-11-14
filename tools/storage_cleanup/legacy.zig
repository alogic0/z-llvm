//! Explicit command receipts and discovery of unlisted artifact aliases.
const std = @import("std");
const core = @import("engine.zig");
const p = core.p;
const batch = @import("batch.zig");
const outputs = @import("command_outputs.zig");
const generated = @import("generated.zig");

pub fn receipts(e: *core.Engine, plan_path: []const u8, reason: []const u8) !void {
    if (!p.relative(plan_path) or reason.len == 0) return error.InvalidEvidencePath;
    try e.addControl(plan_path);
    var parsed = try e.load(e.c.gpa, plan_path);
    defer parsed.deinit();
    const Plan = struct { schema: []const u8, receipts: []const outputs.ReceiptEntry };
    var plan = try std.json.parseFromValue(Plan, e.c.gpa, parsed.value, .{});
    defer plan.deinit();
    if (!std.mem.eql(u8, plan.value.schema, "zllvm-command-output-plan-v1") or plan.value.receipts.len == 0 or plan.value.receipts.len > 1024) return error.InvalidRequestList;
    var requests: std.ArrayList(p.Evidence) = .empty;
    const Rejected = struct { producer: []const u8, reason: []const u8 };
    var rejected: std.ArrayList(Rejected) = .empty;
    for (plan.value.receipts) |entry| {
        const r = outputs.receipt(e, entry, reason) catch |err| {
            try rejected.append(e.c.a, .{ .producer = try e.c.a.dupe(u8, entry.producer), .reason = @errorName(err) });
            continue;
        };
        try append(e, &requests, r);
    }
    try e.write(try e.c.fmt("{s}/receipt-review.json", .{e.output}), .{ .prepared = requests.items.len, .rejected = rejected.items });
    if (requests.items.len != 0) try e.write(try e.c.fmt("{s}/requests.json", .{e.output}), batch.List{ .requests = requests.items });
    try e.c.print("Prepared {d} explicit command-output requests; {d} receipts remain unresolved.\n{s}/receipt-review.json\n", .{ requests.items.len, rejected.items.len, e.output });
}
fn append(e: *core.Engine, requests: *std.ArrayList(p.Evidence), r: p.Release) !void {
    if (requests.items.len >= 1024) return error.InvalidRequestList;
    const destination = try e.c.fmt("{s}/request-{d}.json", .{ e.output, requests.items.len });
    try e.write(destination, r);
    try requests.append(e.c.a, .{ .path = destination, .sha256 = try e.digest(destination) });
}

pub fn aliases(e: *core.Engine, requests_path: []const u8, reason: []const u8) !void {
    if (reason.len == 0) return error.InvalidEvidencePath;
    const originals = try batch.load(e, requests_path);
    var requests: std.ArrayList(p.Evidence) = .empty;
    try requests.appendSlice(e.c.a, originals);
    var declared = std.StringHashMap(void).init(e.c.a);
    var targets = std.AutoHashMap(core.fa.metadata.Identity, void).init(e.c.a);
    for (originals) |request| {
        var parsed = try e.load(e.c.gpa, request.path);
        defer parsed.deinit();
        var r = try std.json.parseFromValue(p.Release, e.c.gpa, parsed.value, .{});
        defer r.deinit();
        for (r.value.artifacts) |artifact| {
            try declared.put(try e.c.a.dupe(u8, artifact.path), {});
            if (artifact.kind != .build_output) continue;
            const m = e.metadata(artifact.path) catch |err| switch (err) {
                error.FileNotFound => continue,
                else => return err,
            };
            if (m.kind == .file and m.links > 1) try targets.put(core.fa.metadata.identity(m), {});
        }
    }
    const Alias = struct { path: []const u8, metadata: core.fa.Metadata, owner: ?[]const u8 = null, reason: ?[]const u8 = null };
    var aliases_found: std.ArrayList(Alias) = .empty;
    var owners = std.StringHashMap(std.ArrayList([]const u8)).init(e.c.a);
    var root = try std.Io.Dir.cwd().openDir(e.c.io, try e.absolute("local-state/validations"), .{ .iterate = true, .follow_symlinks = false });
    defer root.close(e.c.io);
    const root_metadata = try core.fa.metadata.descriptor(root.handle);
    var walker = try root.walkSelectively(e.c.gpa);
    defer walker.deinit();
    while (try walker.next(e.c.io)) |entry| {
        const m = core.fa.metadata.child(e.c.gpa, entry.dir, entry.basename) catch |err| switch (err) {
            error.FileNotFound => continue,
            else => return err,
        };
        if (m.device != root_metadata.device) continue;
        if (m.kind == .directory and entry.kind == .directory) try walker.enter(e.c.io, entry);
        if (m.kind != .file or !targets.contains(core.fa.metadata.identity(m))) continue;
        if (aliases_found.items.len >= e.config.max_candidate_entries) return error.TooManyOutputEntries;
        const path = try e.c.fmt("local-state/validations/{s}", .{entry.path});
        var alias: Alias = .{ .path = path, .metadata = m };
        if (declared.contains(path)) {
            alias.reason = "already declared";
        } else if (std.mem.eql(u8, std.fs.path.basename(path), "capture-zllvm")) {
            const r = generated.request(e, path, reason) catch |err| {
                alias.reason = @errorName(err);
                try aliases_found.append(e.c.a, alias);
                continue;
            };
            try append(e, &requests, r);
            alias.owner = r.producer.path;
        } else {
            var parent = std.fs.path.dirname(path);
            while (parent) |directory| : (parent = std.fs.path.dirname(directory)) {
                if (!p.validationRun(directory)) break;
                const report = try e.c.fmt("{s}/report.json", .{directory});
                const commands = try e.c.fmt("{s}/commands.json", .{directory});
                _ = e.metadata(report) catch |err| switch (err) {
                    error.FileNotFound => continue,
                    else => return err,
                };
                _ = e.metadata(commands) catch |err| switch (err) {
                    error.FileNotFound => continue,
                    else => return err,
                };
                alias.owner = report;
                const owner = try owners.getOrPut(report);
                if (!owner.found_existing) owner.value_ptr.* = .empty;
                try owner.value_ptr.append(e.c.a, path);
                break;
            }
            if (alias.owner == null) alias.reason = "no recorded owner";
        }
        try aliases_found.append(e.c.a, alias);
    }
    const Rejected = struct { owner: []const u8, reason: []const u8 };
    var rejected: std.ArrayList(Rejected) = .empty;
    var it = owners.iterator();
    while (it.next()) |entry| {
        const r = outputs.requestSelected(e, entry.key_ptr.*, reason, entry.value_ptr.items) catch |err| {
            try rejected.append(e.c.a, .{ .owner = entry.key_ptr.*, .reason = @errorName(err) });
            continue;
        };
        try append(e, &requests, r);
    }
    try e.write(try e.c.fmt("{s}/requests.json", .{e.output}), batch.List{ .requests = requests.items });
    try e.write(try e.c.fmt("{s}/alias-review.json", .{e.output}), .{ .schema = "zllvm-alias-owner-review-v1", .input = requests_path, .target_inodes = targets.count(), .observed_names = aliases_found.items, .prepared_owners = requests.items.len - originals.len, .rejected = rejected.items, .scope = "Observed aliases within local-state/validations. Collection rechecks every link; outside aliases and unqualified owners remain protected." });
    try e.c.print("Observed {d} names for {d} inodes; prepared {d} additional owners. No payloads changed.\n{s}/requests.json\n", .{ aliases_found.items.len, targets.count(), requests.items.len - originals.len, e.output });
}
