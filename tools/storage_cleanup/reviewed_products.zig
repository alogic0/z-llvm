//! Explicit present-day disposal decisions for ordinary generated products.
//! This does not infer disposal from missing receipts, names, ages or inventory
//! categories. A reviewed file list replaces producer reconstruction, never
//! current consumers, holds, pins, hashes or complete hardlink ownership.
const std = @import("std");
const core = @import("engine.zig");
const p = core.p;
const u = @import("../validation/common.zig");

pub const Product = struct {
    path: []const u8,
    sha256: []const u8,
    run_root: []const u8,
    reason: []const u8,
    consumers_closed: bool,
};
pub const Plan = struct {
    schema: []const u8 = "zllvm-reviewed-products-v1",
    reason: []const u8,
    review: p.Evidence,
    products: []const Product,
};

pub fn scope(path: []const u8) bool {
    if (!p.validationOutput(path)) return false;
    const name = std.fs.path.basename(path);
    // Source, IR, logs, traces and records cannot be admitted by renaming their
    // role in a plan. Extensionless helpers and ordinary object formats only;
    // qualification separately checks their ELF/archive bytes.
    const ext = std.fs.path.extension(name);
    if (name.len == 0 or name[0] == '.') return false;
    return ext.len == 0 or u.contains(&.{ ".o", ".obj", ".a", ".exe" }, ext);
}

pub fn prepare(e: *core.Engine, path: []const u8) !void {
    if (!p.relative(path) or e.actions.items.len != 0) return error.InvalidReviewedProducts;
    // Import held releases and existing retained dependencies, but never add
    // unrelated default candidates to this explicit review's deletion set.
    try e.discover();
    e.actions.clearRetainingCapacity();
    try e.addControl(path);
    var parsed = try e.load(e.c.gpa, path);
    defer parsed.deinit();
    const owned = try std.json.parseFromValue(Plan, e.c.a, parsed.value, .{ .allocate = .alloc_always });
    const plan = owned.value;
    if (!std.mem.eql(u8, plan.schema, "zllvm-reviewed-products-v1") or
        u.trim(plan.reason).len == 0 or plan.products.len == 0 or plan.products.len > 16_384 or
        !p.relative(plan.review.path) or !p.hash(plan.review.sha256)) return error.InvalidReviewedProducts;
    var kept: std.ArrayList(p.Evidence) = .empty;
    try e.keep(&kept, path, null);
    try e.keep(&kept, plan.review.path, plan.review.sha256);
    var seen = std.StringHashMap(void).init(e.c.a);
    for (plan.products) |product| {
        if (!scope(product.path) or !p.hash(product.sha256) or !p.validationRun(product.run_root) or
            !p.within(product.run_root, product.path) or std.mem.eql(u8, product.run_root, product.path) or
            u.trim(product.reason).len == 0 or !product.consumers_closed) return error.InvalidReviewedProduct;
        if (seen.contains(product.path)) return error.DuplicateReviewedProduct;
        try seen.put(product.path, {});
        for (kept.items) |ev| if (p.overlaps(product.path, ev.path)) return error.RetentionOverlap;
        const index = try e.add(product.path, product.run_root, path, .build_output, product.sha256);
        const action = &e.actions.items[index];
        action.reviewed_build_output = true;
        action.replay_required = false;
        action.retained = kept.items;
        _ = e.metadata(product.path) catch |err| switch (err) {
            error.FileNotFound => {
                action.status = .absent;
                continue;
            },
            else => return err,
        };
    }
}
