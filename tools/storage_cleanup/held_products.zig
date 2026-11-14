//! Explicit retirement of reviewed manual holds on ordinary build products.
//! This is not automatic age-based expiry. Every invocation needs a hash-bound
//! review and closed owners; only successfully removed paths lose their hold.
const std = @import("std");
const core = @import("engine.zig");
const p = core.p;
pub const Product = struct {
    path: []const u8,
    kind: enum { compiler_build, shared_zig_cache },
    build_report: ?p.Evidence = null,
    closed_receipts: []const p.Evidence = &.{},
    release_manual_hold: bool = true,
    readiness_launcher: ?@import("readiness_cache.zig").Launcher = null,
};
pub const Plan = struct {
    schema: []const u8 = "zllvm-held-products-review-v1",
    reason: []const u8,
    holds: p.Evidence,
    checkpoint: p.Evidence,
    retained: []const p.Evidence,
    products: []const Product,
};

pub fn reviewedManualHold(e: *const core.Engine, path: []const u8) bool {
    if (e.reviewed_holds == null) return false;
    for (e.reviewed_hold_paths) |selected| if (std.mem.eql(u8, selected, path)) return true;
    return false;
}

pub fn cacheScope(path: []const u8) bool {
    if (!p.relative(path)) return false;
    if (std.mem.eql(u8, std.fs.path.dirname(path) orelse "", "local-state/caches")) return true;
    return p.candidate(path) and std.mem.indexOf(u8, std.fs.path.basename(path), "zig-local-") != null;
}

fn receiptUses(e: *core.Engine, value: std.json.Value, cache: []const u8) !bool {
    const argv = try core.get(value, "argv");
    if (argv != .array or argv.array.items.len == 0) return error.InvalidCacheReceipt;
    const absolute = try e.absolute(cache);
    for (argv.array.items) |arg| if (arg != .string) return error.InvalidCacheReceipt;
    if (std.mem.eql(u8, argv.array.items[0].string, "env")) {
        var i: usize = 1;
        while (i < argv.array.items.len and std.mem.indexOfScalar(u8, argv.array.items[i].string, '=') != null) : (i += 1) {
            const assignment = argv.array.items[i].string;
            for ([_][]const u8{ "ZIG_LOCAL_CACHE_DIR=", "ZIG_GLOBAL_CACHE_DIR=" }) |prefix| {
                if (!std.mem.startsWith(u8, assignment, prefix)) continue;
                const path = assignment[prefix.len..];
                if (std.mem.eql(u8, path, absolute) or std.mem.eql(u8, path, cache)) return true;
            }
        }
    }
    for (argv.array.items, 0..) |arg, i| {
        if (arg != .string) return error.InvalidCacheReceipt;
        if (i == 0 and (p.within(absolute, arg.string) or p.within(cache, arg.string))) return true;
        if (i == 0) continue;
        const previous = argv.array.items[i - 1];
        if (previous != .string) return error.InvalidCacheReceipt;
        if ((std.mem.eql(u8, previous.string, "--cache-dir") or std.mem.eql(u8, previous.string, "--global-cache-dir")) and
            (std.mem.eql(u8, arg.string, absolute) or std.mem.eql(u8, arg.string, cache))) return true;
    }
    return false;
}

fn closedReceipt(e: *core.Engine, receipt: p.Evidence, cache: []const u8) !void {
    try e.check(receipt);
    var parsed = try e.load(e.c.gpa, receipt.path);
    defer parsed.deinit();
    const value = parsed.value;
    if (!core.eq(value, "status", "finished") or
        (!core.eq(value, "outcome", "completed") and !core.eq(value, "outcome", "canceled"))) return error.CacheReceiptNotClosed;
    const code = try core.get(value, "actual_returncode");
    const started = try core.get(value, "started_ns");
    const finished = try core.get(value, "finished_ns");
    if (code != .integer or started != .integer or finished != .integer or finished.integer <= started.integer) return error.CacheReceiptNotClosed;
    if (!try receiptUses(e, value, cache)) {
        e.c.diagnostic = try e.c.fmt("Receipt {s} does not bind cache {s}", .{ receipt.path, cache });
        return error.CacheReceiptDoesNotOwnRoot;
    }
    try e.addControl(receipt.path);
}

fn cacheLayout(e: *core.Engine, path: []const u8) !void {
    var root = try core.fa.metadata.openRoot(e.c.io, try e.absolute(path));
    defer root.close(e.c.io);
    var dir = try root.openDir(e.c.io, ".", .{ .iterate = true, .follow_symlinks = false });
    defer dir.close(e.c.io);
    var entries = dir.iterate();
    var objects = false;
    var hashes = false;
    while (try entries.next(e.c.io)) |entry| {
        if (entry.kind != .directory) return error.NotSharedZigCache;
        if (std.mem.eql(u8, entry.name, "o")) objects = true else if (std.mem.eql(u8, entry.name, "h")) hashes = true else if (!std.mem.eql(u8, entry.name, "z") and !std.mem.eql(u8, entry.name, "tmp") and !std.mem.eql(u8, entry.name, "c")) return error.NotSharedZigCache;
    }
    if (!objects or !hashes) return error.NotSharedZigCache;
}

pub fn prepare(e: *core.Engine, plan_path: []const u8) !void {
    if (!p.relative(plan_path) or e.actions.items.len != 0) return error.InvalidHeldProductReview;
    // Import the ordinary collector's held releases and retained dependencies,
    // but this explicit command may mutate only the reviewed product list.
    try e.discover();
    e.actions.clearRetainingCapacity();
    try e.addControl(plan_path);
    var parsed = try e.load(e.c.gpa, plan_path);
    defer parsed.deinit();
    const plan = try std.json.parseFromValue(Plan, e.c.a, parsed.value, .{ .allocate = .alloc_always });
    const review = plan.value;
    if (!std.mem.eql(u8, review.schema, "zllvm-held-products-review-v1") or review.reason.len == 0 or review.products.len == 0 or review.products.len > 1024 or review.retained.len == 0 or !std.mem.eql(u8, review.holds.path, e.config.holds_file)) return error.InvalidHeldProductReview;
    try e.check(review.holds);
    try e.addControl(review.holds.path);
    var holds_json = try e.load(e.c.gpa, review.holds.path);
    defer holds_json.deinit();
    var holds = try std.json.parseFromValue(p.Holds, e.c.gpa, holds_json.value, .{});
    defer holds.deinit();
    if (holds.value.schema != 1) return error.InvalidHolds;
    try e.check(review.checkpoint);
    var checkpoint = try e.load(e.c.gpa, review.checkpoint.path);
    defer checkpoint.deinit();
    if (!core.eq(checkpoint.value, "status", "passed")) return error.CheckpointNotPassed;
    try e.addControl(review.checkpoint.path);
    for (review.retained) |ev| {
        try e.check(ev);
        try e.addControl(ev.path);
        try e.retained_declarations.append(e.c.a, ev.path);
    }
    var selected: std.ArrayList([]const u8) = .empty;
    for (review.products, 0..) |product, n| {
        if (!p.relative(product.path)) return error.InvalidHeldProductReview;
        for (review.products[0..n]) |other| if (p.overlaps(other.path, product.path)) return error.OverlappingHeldProducts;
        var found = false;
        for (holds.value.paths) |held| if (std.mem.eql(u8, held, product.path)) {
            found = true;
        };
        if (product.release_manual_hold) {
            if (!found) return error.HoldNotPresent;
            try selected.append(e.c.a, product.path);
        }
        switch (product.kind) {
            .compiler_build => {
                const build = product.build_report orelse return error.MissingBuildReport;
                try e.check(build);
                const request = try @import("release.zig").disposableBuild(e, build.path, review.reason);
                if (request.artifacts.len != 1 or !std.mem.eql(u8, request.artifacts[0].path, product.path)) return error.BuildProductMismatch;
                const request_path = try e.c.fmt("{s}/held-build-{d}.json", .{ e.output, n });
                try e.write(request_path, request);
                try e.discoverRelease(request_path, true);
            },
            .shared_zig_cache => {
                if (!cacheScope(product.path) or product.closed_receipts.len == 0) return error.InvalidSharedCacheReview;
                try cacheLayout(e, product.path);
                var kept: std.ArrayList(p.Evidence) = .empty;
                try e.keep(&kept, plan_path, null);
                try e.keep(&kept, review.checkpoint.path, review.checkpoint.sha256);
                for (product.closed_receipts) |receipt| {
                    if (product.readiness_launcher) |launcher| {
                        try @import("readiness_cache.zig").verify(e, product.path, receipt, launcher, &kept);
                    } else try closedReceipt(e, receipt, product.path);
                    try e.keep(&kept, receipt.path, receipt.sha256);
                }
                try e.actions.append(e.c.a, .{ .path = product.path, .run_root = product.path, .producer = plan_path, .kind = .cache, .reviewed_shared_cache = true, .replay_required = false, .retained = kept.items });
            },
        }
    }
    e.reviewed_holds = review.holds;
    e.reviewed_hold_paths = selected.items;
    // The compiler release records were written after Engine.init. Their
    // creation time must not look like a future timestamp during qualification.
    e.now_ns = @max(e.now_ns, std.Io.Clock.real.now(e.c.io).nanoseconds);
}

pub fn finish(e: *core.Engine) !void {
    const before = e.reviewed_holds orelse return error.InvalidHeldProductReview;
    try e.check(before);
    var parsed = try e.load(e.c.gpa, before.path);
    defer parsed.deinit();
    var holds = try std.json.parseFromValue(p.Holds, e.c.gpa, parsed.value, .{});
    defer holds.deinit();
    var after: std.ArrayList([]const u8) = .empty;
    for (holds.value.paths) |path| {
        var removed = false;
        for (e.actions.items) |action| if (reviewedManualHold(e, path) and action.status == .removed and std.mem.eql(u8, path, action.path)) {
            removed = true;
        };
        if (!removed) try after.append(e.c.a, path);
    }
    if (after.items.len == holds.value.paths.len) return;
    try e.write(try e.c.fmt("{s}/holds-before.json", .{e.output}), holds.value);
    try e.write(try e.c.fmt("{s}/holds-after.json", .{e.output}), p.Holds{ .paths = after.items });
    try e.check(before);
    try e.write(before.path, p.Holds{ .paths = after.items });
}
