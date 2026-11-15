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
    retired_pins: []const p.PinTransition = &.{},
};
pub const Cache = struct {
    path: []const u8,
    run_root: []const u8,
    reason: []const u8,
    consumers_closed: bool,
    owner: ?p.Evidence = null,
    retained: []const p.Evidence,
    failure_disposition: ?[]const u8 = null,
    retired_pins: []const p.PinTransition = &.{},
};

pub fn cacheScope(path: []const u8) bool {
    if (!p.validationOutput(path)) return false;
    const name = std.fs.path.basename(path);
    return p.privateCacheName(name) or p.commandCacheName(name) or std.mem.eql(u8, name, "cache") or std.mem.eql(u8, name, "cc-cache") or
        std.mem.indexOf(u8, name, "zig-local-") != null or std.mem.indexOf(u8, name, "zig-global-") != null or
        std.mem.endsWith(u8, name, "-local") or std.mem.endsWith(u8, name, "-global") or
        std.mem.startsWith(u8, name, "unit-global-") or std.mem.startsWith(u8, name, "unit-local-");
}
pub const Plan = struct {
    schema: []const u8 = "zllvm-reviewed-products-v1",
    reason: []const u8,
    review: p.Evidence,
    products: []const Product,
    caches: []const Cache = &.{},
};

pub fn scope(path: []const u8) bool {
    if (!p.validationOutput(path)) return false;
    const name = std.fs.path.basename(path);
    // Source, IR, traces and records cannot be admitted by renaming their role.
    // A .stdout capture can contain an object rather than text: qualification
    // checks ELF/archive bytes for every name, including captured output.
    const ext = std.fs.path.extension(name);
    if (name.len == 0 or name[0] == '.') return false;
    return ext.len == 0 or u.contains(&.{
        ".o",             ".obj",                         ".a",               ".exe",              ".link",                  ".so",           ".stdout",
        // Named executable outputs of run_distribution_zig_integrated_exe
        // and codegen_canary_shared, not arbitrary dotted evidence files.
        ".syscall_hello", ".compiler_rt_i128_arithmetic", ".compiler_rt_fma", ".setcc_predicates", ".aggregate_sse_returns", ".differential",
    }, ext);
}

fn keepRetiredManifest(e: *core.Engine, kept: *std.ArrayList(p.Evidence), validated: *std.StringHashMap(void), transition: p.PinTransition) !void {
    if (!p.relative(transition.manifest.path) or !p.hash(transition.manifest.sha256) or
        u.trim(transition.reason).len == 0 or transition.reference.len == 0 or
        !p.relative(transition.target.path) or !p.hash(transition.target.sha256)) return error.InvalidPinTransition;
    for (e.config.current_manifests) |current| if (std.mem.eql(u8, current, transition.manifest.path)) return error.CurrentManifestCannotBeRetired;
    if (!p.within("local-state/retirements", transition.manifest.path) and !p.validationOutput(transition.manifest.path)) return error.InvalidPinTransition;
    try e.keep(kept, transition.manifest.path, transition.manifest.sha256);
    if (p.within("local-state/retirements", transition.manifest.path) and std.mem.endsWith(u8, transition.manifest.path, ".json")) {
        // A large cleanup record can bind thousands of products. Keep the
        // exact expected hash above for every reference, but parse its closed
        // status once per plan. The retained identity and normal mutation
        // guards still reject a later change to the underlying record.
        if (validated.contains(transition.manifest.path)) return;
        var old = try e.load(e.c.gpa, transition.manifest.path);
        defer old.deinit();
        if (!core.eq(old.value, "status", "complete")) return error.IncompletePinRetirement;
        try validated.put(transition.manifest.path, {});
    }
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
        u.trim(plan.reason).len == 0 or plan.products.len + plan.caches.len == 0 or plan.products.len + plan.caches.len > 16_384 or
        !p.relative(plan.review.path) or !p.hash(plan.review.sha256)) return error.InvalidReviewedProducts;
    var kept: std.ArrayList(p.Evidence) = .empty;
    try e.keep(&kept, path, null);
    try e.keep(&kept, plan.review.path, plan.review.sha256);
    var seen = std.StringHashMap(void).init(e.c.a);
    var validated_retirements = std.StringHashMap(void).init(e.c.a);
    for (plan.products) |product| {
        if (!scope(product.path) or !p.hash(product.sha256) or !p.validationRun(product.run_root) or
            !p.within(product.run_root, product.path) or std.mem.eql(u8, product.run_root, product.path) or
            u.trim(product.reason).len == 0 or !product.consumers_closed) return error.InvalidReviewedProduct;
        if (seen.contains(product.path)) return error.DuplicateReviewedProduct;
        try seen.put(product.path, {});
        for (kept.items) |ev| if (p.overlaps(product.path, ev.path)) return error.RetentionOverlap;
        var product_kept: std.ArrayList(p.Evidence) = .empty;
        try product_kept.appendSlice(e.c.a, kept.items);
        for (product.retired_pins) |transition| {
            if (!std.mem.eql(u8, transition.target.path, product.path) or
                !std.mem.eql(u8, transition.target.sha256, product.sha256)) return error.InvalidPinTransition;
            try keepRetiredManifest(e, &product_kept, &validated_retirements, transition);
        }
        const index = try e.add(product.path, product.run_root, path, .build_output, product.sha256);
        const action = &e.actions.items[index];
        action.reviewed_build_output = true;
        action.replay_required = false;
        action.retained = product_kept.items;
        action.retired_pins = product.retired_pins;
        _ = e.metadata(product.path) catch |err| switch (err) {
            error.FileNotFound => {
                action.status = .absent;
                continue;
            },
            else => return err,
        };
    }
    // Some historical launchers wrote private row caches outside a modern
    // workspace. Their source/ownership review is explicit, not inferred from
    // a filename. Only named cache roots under the reviewed run are admitted;
    // complete snapshots, raw-evidence rejection and normal guards still apply.
    for (plan.caches) |cache| {
        if (!cacheScope(cache.path) or
            !p.validationRun(cache.run_root) or !p.within(cache.run_root, cache.path) or
            !cache.consumers_closed or
            u.trim(cache.reason).len == 0 or cache.retained.len == 0 or seen.contains(cache.path)) return error.InvalidReviewedCache;
        try seen.put(cache.path, {});
        var cache_kept: std.ArrayList(p.Evidence) = .empty;
        try cache_kept.appendSlice(e.c.a, kept.items);
        for (cache.retained) |ev| try e.keep(&cache_kept, ev.path, ev.sha256);
        for (cache_kept.items) |ev| if (p.overlaps(cache.path, try e.relative(ev.path))) return error.RetentionOverlap;
        if (cache.owner) |proof| {
            if (!p.within(cache.run_root, proof.path) or p.overlaps(cache.path, proof.path)) return error.InvalidReviewedCache;
            try e.keep(&cache_kept, proof.path, proof.sha256);
            var owner = try e.load(e.c.gpa, proof.path);
            defer owner.deinit();
            if (!core.eq(owner.value, "status", "finished") or
                (!core.eq(owner.value, "outcome", "completed") and !core.eq(owner.value, "outcome", "canceled")) or
                try core.integer(owner.value, "finished_ns") <= try core.integer(owner.value, "started_ns")) return error.ReviewedCacheOwnerNotSuccessful;
            const successful = core.eq(owner.value, "outcome", "completed") and
                try core.integer(owner.value, "actual_returncode") == 0 and try core.integer(owner.value, "returncode") == 0;
            if (!successful) {
                // Failed scratch needs an explicit present-day diagnosis; the
                // immutable owner receipt and its original diagnostic remain.
                const disposition = cache.failure_disposition orelse return error.ReviewedCacheOwnerNotSuccessful;
                if (u.trim(disposition).len == 0 or try core.integer(owner.value, "actual_returncode") == 0) return error.ReviewedCacheOwnerNotSuccessful;
                _ = try core.integer(owner.value, "returncode");
                const log = try e.relative(try core.str(owner.value, "log"));
                if (!p.within(cache.run_root, log) or p.overlaps(cache.path, log)) return error.UnboundPrivateCacheLog;
                try e.keep(&cache_kept, log, null);
            }
        } else if (cache.failure_disposition != null) return error.MissingCacheOwner;
        for (cache.retired_pins) |transition| {
            if (!p.within(cache.path, transition.target.path) or std.mem.eql(u8, cache.path, transition.target.path)) return error.InvalidPinTransition;
            try keepRetiredManifest(e, &cache_kept, &validated_retirements, transition);
        }
        const index = try e.addReviewedCache(cache.path, cache.run_root, path);
        const action = &e.actions.items[index];
        action.reviewed_shared_cache = true;
        action.replay_required = false;
        action.retained = cache_kept.items;
        action.retired_pins = cache.retired_pins;
        const metadata = e.metadata(cache.path) catch |err| switch (err) {
            error.FileNotFound => {
                action.status = .absent;
                continue;
            },
            else => return err,
        };
        if (metadata.kind != .directory) return error.CacheNotDirectory;
        // Copied historical caches may have receipts naming their original
        // location. An explicit present-day review can instead establish the
        // native Zig h/o layout; no successful producer receipt is fabricated.
        if (cache.owner == null) try @import("held_products.zig").cacheLayout(e, cache.path);
        for (cache.retired_pins) |transition| try e.check(transition.target);
    }
}
