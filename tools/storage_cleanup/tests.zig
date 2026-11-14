const std = @import("std");
const t = std.testing;
const u = @import("../validation/common.zig");
const core = @import("engine.zig");
const mutation = @import("mutation.zig");
const releases = @import("release.zig");
const batches = @import("batch.zig");
const private_cache = @import("private_cache.zig");
const command_caches = @import("command_caches.zig");
const retired_compiler = @import("retired_compiler.zig");
const generated = @import("generated.zig");
const command_outputs = @import("command_outputs.zig");
const observed_compiler = @import("observed_compiler.zig");
const legacy_outputs = @import("legacy.zig");
const cache_holds = @import("cache_holds.zig");
const held_products = @import("held_products.zig");
const reviewed_products = @import("reviewed_products.zig");
const cache_batch = @import("cache_batch.zig");
const p = core.p;
const workspaces = @import("workspaces.zig");
const workspace = @import("../validation/storage_workspace.zig");
const run = "local-state/validations/test/batch/build";
const cache = run ++ "/zig-local-cache";
const report = run ++ "/report.json";
const output = "local-state/retirements/test-cleanup";
const released = "local-state/validations/test/batch/released";
const assembly_owner = run ++ "/execution-breadth-controls";
const assembly_dir = assembly_owner ++ "/ReleaseFast/example";
const assembly_path = assembly_dir ++ "/linked-harness.s";

const receipt_root = "local-state/validations/legacy";
const receipt_path = receipt_root ++ "/build-run.json";
const shared_cache = "local-state/caches/retired-tools";
const held_plan = output ++ "/held-products.json";
const reviewed_plan = output ++ "/reviewed-products.json";
const reviewed_notes = output ++ "/review.md";
const reviewed_file = run ++ "/old-helper";
fn reviewedProductFixture(f: *Fixture) !reviewed_products.Plan {
    try f.write(reviewed_file, "\x7fELFordinary generated helper");
    try f.write(reviewed_notes, "Reviewed generated helper; completed consumers; no continuing use identified.");
    var e = f.engine();
    const plan: reviewed_products.Plan = .{
        .reason = "Explicit review; original build receipt absent",
        .review = .{ .path = reviewed_notes, .sha256 = try e.digest(reviewed_notes) },
        .products = try e.c.a.dupe(reviewed_products.Product, &.{.{ .path = reviewed_file, .sha256 = try e.digest(reviewed_file), .run_root = run, .reason = "Disposable completed helper", .consumers_closed = true }}),
    };
    try e.write(reviewed_plan, plan);
    return plan;
}

test "storage cleanup: explicit reviewed product needs no fabricated producer receipt" {
    const f = try Fixture.init();
    defer f.deinit();
    _ = try reviewedProductFixture(f);
    try f.write(run ++ "/input.ll", "unique input");
    try f.write(run ++ "/diagnostic.log", "original diagnostic");
    var e = f.engine();
    try reviewed_products.prepare(&e, reviewed_plan);
    try t.expectEqual(@as(usize, 1), e.actions.items.len);
    try e.qualify(0);
    try mutation.applyFileBatch(&e, &.{0});
    try t.expectEqual(.removed, e.actions.items[0].status);
    for ([_][]const u8{ reviewed_plan, reviewed_notes, run ++ "/input.ll", run ++ "/diagnostic.log", output ++ "/record-0.json" }) |path| _ = try e.metadata(path);
    var repeat = f.engine();
    try reviewed_products.prepare(&repeat, reviewed_plan);
    try t.expectEqual(.absent, repeat.actions.items[0].status);
}

test "storage cleanup: reviewed products reject unclosed ownership and nonproduct paths" {
    for (0..7) |case| {
        const f = try Fixture.init();
        defer f.deinit();
        var plan = try reviewedProductFixture(f);
        var product = plan.products[0];
        switch (case) {
            0 => product.consumers_closed = false,
            1 => product.run_root = "local-state/validations/unrelated",
            2 => product.reason = " ",
            3 => product.path = "local-state/validations/test/../outside.o",
            4 => product.path = "local-state/inputs/adopted.o",
            5 => product.path = run ++ "/input.ll",
            else => product.path = run ++ "/profile.events.jsonl",
        }
        plan.products = &.{product};
        var e = f.engine();
        try e.write(reviewed_plan, plan);
        try t.expectError(error.InvalidReviewedProduct, reviewed_products.prepare(&e, reviewed_plan));
        _ = try e.metadata(reviewed_file);
    }
}

test "storage cleanup: reviewed products reject changed hash and noncompiled contents" {
    for ([_]bool{ false, true }) |bind_text| {
        const f = try Fixture.init();
        defer f.deinit();
        var plan = try reviewedProductFixture(f);
        try f.write(reviewed_file, "an extensionless source file is not compiled output");
        var e = f.engine();
        if (bind_text) {
            var product = plan.products[0];
            product.sha256 = try e.digest(reviewed_file);
            plan.products = &.{product};
            try e.write(reviewed_plan, plan);
        }
        try reviewed_products.prepare(&e, reviewed_plan);
        try t.expectError(if (bind_text) error.NotCompiledOutput else error.EvidenceHashMismatch, e.qualify(0));
        _ = try e.metadata(reviewed_file);
    }
}

test "storage cleanup: changed review evidence blocks reviewed product mutation" {
    for ([_][]const u8{ reviewed_plan, reviewed_notes }) |changed| {
        const f = try Fixture.init();
        defer f.deinit();
        _ = try reviewedProductFixture(f);
        var e = f.engine();
        try reviewed_products.prepare(&e, reviewed_plan);
        try e.qualify(0);
        try f.write(changed, "changed review");
        // Parsed controls remember their original metadata; a hash-only review
        // binding rejects changed bytes at the subsequent digest comparison.
        try t.expectError(if (std.mem.eql(u8, changed, reviewed_plan)) error.FileChanged else error.EvidenceHashMismatch, mutation.applyFileBatch(&e, &.{0}));
        _ = try e.metadata(reviewed_file);
        try t.expect(!u.exists(t.io, try e.absolute(mutation.pending_path)));
    }
}

test "storage cleanup: new pins and holds roll back reviewed products" {
    for ([_]bool{ false, true }) |hold| {
        const f = try Fixture.init();
        defer f.deinit();
        _ = try reviewedProductFixture(f);
        var e = f.engine();
        try reviewed_products.prepare(&e, reviewed_plan);
        try e.qualify(0);
        if (hold) try e.write(e.config.holds_file, p.Holds{ .paths = &.{reviewed_file} }) else try f.write(run ++ "/pin.sha256", try f.c.fmt("{s}  {s}\n", .{ e.actions.items[0].sha256.?, reviewed_file }));
        try t.expectError(error.GeneratedBatchBecameHeld, mutation.applyFileBatch(&e, &.{0}));
        _ = try e.metadata(reviewed_file);
        try t.expect(!u.exists(t.io, try e.absolute(mutation.pending_path)));
    }
}

test "storage cleanup: reviewed products protect current manifests and retained dependencies" {
    for ([_]bool{ false, true }) |manifest| {
        const f = try Fixture.init();
        defer f.deinit();
        _ = try reviewedProductFixture(f);
        var e = f.engine();
        try reviewed_products.prepare(&e, reviewed_plan);
        try e.qualify(0);
        if (manifest) {
            try f.write(output ++ "/current-contract.txt", try f.c.fmt("{s}  {s}\n", .{ e.actions.items[0].sha256.?, reviewed_file }));
            e.config.current_manifests = &.{output ++ "/current-contract.txt"};
            try e.pins();
        } else {
            try e.retained_declarations.append(e.c.a, reviewed_file);
            try e.protectRetained();
        }
        try t.expectEqual(.skipped, e.actions.items[0].status);
        _ = try e.metadata(reviewed_file);
    }
}

test "storage cleanup: reviewed products require every alias and charge its inode once" {
    const f = try Fixture.init();
    defer f.deinit();
    var plan = try reviewedProductFixture(f);
    const alias = run ++ "/peer-helper";
    {
        const file = try f.tmp.dir.openFile(t.io, reviewed_file, .{});
        defer file.close(t.io);
        try file.hardLink(t.io, f.tmp.dir, alias, .{});
    }
    var e = f.engine();
    e.allow_artifact_aliases = true;
    try reviewed_products.prepare(&e, reviewed_plan);
    try t.expectError(error.AliasedOrNonRegularArtifact, e.qualify(0));
    var peer = plan.products[0];
    peer.path = alias;
    plan.products = &.{ plan.products[0], peer };
    try e.write(reviewed_plan, plan);
    var complete = f.engine();
    complete.allow_artifact_aliases = true;
    try reviewed_products.prepare(&complete, reviewed_plan);
    try complete.qualify(0);
    try complete.qualify(1);
    try complete.guardCaptureGroups();
    const bytes = (try complete.metadata(reviewed_file)).allocated_bytes;
    try mutation.applyFileBatch(&complete, &.{ 0, 1 });
    try t.expectEqual(bytes, complete.actions.items[0].reclaimed_file_bytes + complete.actions.items[1].reclaimed_file_bytes);
    for (complete.actions.items) |a| try t.expectEqual(.removed, a.status);
}

fn reviewedPinFixture(f: *Fixture, manifest: []const u8) !reviewed_products.Plan {
    var plan = try reviewedProductFixture(f);
    var e = f.engine();
    try f.tmp.dir.createDirPath(t.io, std.fs.path.dirname(manifest).?);
    try f.write(manifest, try f.c.fmt("{s}  {s}\n", .{ plan.products[0].sha256, reviewed_file }));
    var product = plan.products[0];
    product.retired_pins = try e.c.a.dupe(p.PinTransition, &.{.{
        .manifest = .{ .path = manifest, .sha256 = try e.digest(manifest) },
        .reference = reviewed_file,
        .target = .{ .path = reviewed_file, .sha256 = product.sha256 },
        .reason = "Reviewed historical identity of a completed temporary helper",
    }});
    plan.products = try e.c.a.dupe(reviewed_products.Product, &.{product});
    try e.write(reviewed_plan, plan);
    return plan;
}

test "storage cleanup: reviewed product transitions only its exact historical reference" {
    const f = try Fixture.init();
    defer f.deinit();
    const manifest = "local-state/retirements/earlier/retained.sha256";
    const plan = try reviewedPinFixture(f, manifest);
    var e = f.engine();
    try reviewed_products.prepare(&e, reviewed_plan);
    try e.qualify(0);
    try e.pins();
    try t.expectEqual(.ready, e.actions.items[0].status);
    try mutation.applyFileBatch(&e, &.{0});
    try t.expectEqual(.removed, e.actions.items[0].status);
    try t.expectEqualStrings(plan.products[0].retired_pins[0].manifest.sha256, try e.digest(manifest));
}

test "storage cleanup: reviewed pin transitions reject current manifests and wrong targets" {
    for (0..4) |case| {
        const f = try Fixture.init();
        defer f.deinit();
        const manifest = run ++ "/historical.sha256";
        var plan = try reviewedPinFixture(f, manifest);
        var e = f.engine();
        if (case == 0) {
            e.config.current_manifests = &.{manifest};
        } else {
            var product = plan.products[0];
            var transition = product.retired_pins[0];
            switch (case) {
                1 => transition.target.path = run ++ "/unreviewed-helper",
                2 => transition.target.sha256 = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
                else => transition.reason = " ",
            }
            product.retired_pins = &.{transition};
            plan.products = &.{product};
            try e.write(reviewed_plan, plan);
        }
        try t.expectError(if (case == 0) error.CurrentManifestCannotBeRetired else error.InvalidPinTransition, reviewed_products.prepare(&e, reviewed_plan));
        _ = try e.metadata(reviewed_file);
    }
}

test "storage cleanup: reviewed transitions preserve independent pins and changed manifests" {
    for ([_]bool{ false, true }) |changed| {
        const f = try Fixture.init();
        defer f.deinit();
        const manifest = run ++ "/historical.sha256";
        const plan = try reviewedPinFixture(f, manifest);
        var e = f.engine();
        try reviewed_products.prepare(&e, reviewed_plan);
        try e.qualify(0);
        if (changed) {
            try f.write(manifest, "changed historical manifest");
            try t.expectError(error.EvidenceHashMismatch, mutation.applyFileBatch(&e, &.{0}));
        } else {
            try f.write(run ++ "/independent.sha256", try f.c.fmt("{s}  {s}\n", .{ plan.products[0].sha256, reviewed_file }));
            try t.expectError(error.GeneratedBatchBecameHeld, mutation.applyFileBatch(&e, &.{0}));
        }
        _ = try e.metadata(reviewed_file);
        try t.expect(!u.exists(t.io, try e.absolute(mutation.pending_path)));
    }
}

test "storage cleanup: reviewed transitions reject incomplete historical retirement records" {
    const f = try Fixture.init();
    defer f.deinit();
    const manifest = "local-state/retirements/earlier/record.json";
    var plan = try reviewedPinFixture(f, manifest);
    try f.write(manifest, "{\"status\":\"pending\"}");
    var e = f.engine();
    var product = plan.products[0];
    var transition = product.retired_pins[0];
    transition.manifest.sha256 = try e.digest(manifest);
    product.retired_pins = &.{transition};
    plan.products = &.{product};
    try e.write(reviewed_plan, plan);
    try t.expectError(error.IncompletePinRetirement, reviewed_products.prepare(&e, reviewed_plan));
}

test "storage cleanup: joint traces retain both audits without raw sibling cycles" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    const hash = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
    const first: p.Release = .{
        .schema = "zllvm-storage-release-v1",
        .state = .audited,
        .run_root = run,
        .reason = "Joint capture review",
        .producer = .{ .path = report, .sha256 = hash },
        .artifacts = &.{.{ .path = run ++ "/one/profile.events.jsonl", .sha256 = hash, .kind = .raw_trace, .audit = output ++ "/audit-one.json" }},
        .retained = &.{ .{ .path = output ++ "/audit-one.json", .sha256 = hash, .role = .audit }, .{ .path = run ++ "/two/profile.events.jsonl", .sha256 = hash, .role = .other }, .{ .path = report, .sha256 = hash, .role = .result }, .{ .path = report, .sha256 = hash, .role = .source }, .{ .path = report, .sha256 = hash, .role = .build } },
    };
    var second = first;
    second.artifacts = &.{.{ .path = run ++ "/two/profile.events.jsonl", .sha256 = hash, .kind = .raw_trace, .audit = output ++ "/audit-two.json" }};
    second.retained = &.{ .{ .path = output ++ "/audit-two.json", .sha256 = hash, .role = .audit }, .{ .path = run ++ "/one/profile.events.jsonl", .sha256 = hash, .role = .other }, .{ .path = report, .sha256 = hash, .role = .result } };
    const joined = try batches.jointTraces(&e, &.{ first, second });
    try t.expectEqual(@as(usize, 1), joined.len);
    try t.expectEqual(@as(usize, 2), joined[0].artifacts.len);
    try t.expectEqual(@as(usize, 5), joined[0].retained.len);
    var audits: usize = 0;
    for (joined[0].retained) |row| {
        if (row.role == .audit) audits += 1;
        try t.expect(!std.mem.endsWith(u8, row.path, "/profile.events.jsonl"));
    }
    try t.expectEqual(@as(usize, 2), audits);
    for (0..4) |case| {
        var different = second;
        switch (case) {
            0 => different.run_root = run ++ "-other",
            1 => different.producer.sha256 = "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
            2 => different.compiler_retirement = .{ .path = output ++ "/record.json", .sha256 = hash },
            else => different.source_reconstructions = &.{.{ .path = output ++ "/sources.json", .sha256 = hash }},
        }
        const separate = try batches.jointTraces(&e, &.{ first, different });
        try t.expectEqual(@as(usize, 2), separate.len);
        try t.expectEqual(@as(usize, 5), separate[0].retained.len);
    }
    second.retained = &.{.{ .path = run ++ "/one/profile.events.jsonl", .sha256 = "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb", .role = .other }};
    try t.expectError(error.RetainedArtifactHashMismatch, batches.jointTraces(&e, &.{ first, second }));
    try t.expectError(error.DuplicateTraceArtifact, batches.jointTraces(&e, &.{ first, first }));
}

fn heldProductsFixture(f: *Fixture, finished: bool) !void {
    var e = f.engine();
    try f.build(&e);
    try f.tmp.dir.createDirPath(t.io, shared_cache ++ "/o");
    try f.tmp.dir.createDirPath(t.io, shared_cache ++ "/h");
    try f.write(shared_cache ++ "/o/tool", "compiled cache tool");
    try f.write(output ++ "/checkpoint.json", "{\"status\":\"passed\"}");
    const receipt = output ++ "/cache-run.json";
    try e.write(receipt, .{ .status = if (finished) "finished" else "running", .outcome = "completed", .actual_returncode = 0, .started_ns = 1, .finished_ns = 2, .argv = [_][]const u8{ "zig", "run", "--cache-dir", shared_cache, "tool.zig" } });
    try e.write(e.config.holds_file, p.Holds{ .paths = &.{ shared_cache, run ++ "/z_llvm", report } });
    try e.write(held_plan, held_products.Plan{
        .reason = "Explicit review of closed ordinary products",
        .holds = .{ .path = e.config.holds_file, .sha256 = try e.digest(e.config.holds_file) },
        .checkpoint = .{ .path = output ++ "/checkpoint.json", .sha256 = try e.digest(output ++ "/checkpoint.json") },
        .retained = &.{.{ .path = "toolchain/zig", .sha256 = try e.digest("toolchain/zig") }},
        .products = &.{
            .{ .path = shared_cache, .kind = .shared_zig_cache, .closed_receipts = &.{.{ .path = receipt, .sha256 = try e.digest(receipt) }} },
            .{ .path = run ++ "/z_llvm", .kind = .compiler_build, .build_report = .{ .path = report, .sha256 = try e.digest(report) } },
        },
    });
}

test "storage cleanup: explicit held products retire through guarded batches and preserve records" {
    const f = try Fixture.init();
    defer f.deinit();
    try heldProductsFixture(f, true);
    var e = f.engine();
    e.now_ns = 0; // Exercise qualification of release records staged by prepare.
    e.config.protected_paths = &.{"local-state/caches"};
    const before = try e.digest(e.config.holds_file);
    try held_products.prepare(&e, held_plan);
    try e.loadHolds();
    try e.qualify(0);
    try e.qualify(1);
    try e.protectRetained();
    try t.expectEqualStrings(before, try e.digest(e.config.holds_file));
    try cache_batch.apply(&e, &.{0});
    try mutation.applyFileBatch(&e, &.{1});
    try held_products.finish(&e);
    for (e.actions.items) |a| try t.expectEqual(.removed, a.status);
    var fresh = f.engine();
    try fresh.loadHolds();
    try t.expectEqual(@as(usize, 1), fresh.held.items.len);
    try t.expectEqualStrings(report, fresh.held.items[0]);
    for ([_][]const u8{ report, run ++ "/build.stdout", output ++ "/checkpoint.json", output ++ "/cache-run.json", "toolchain/zig", output ++ "/holds-before.json" }) |path| _ = try fresh.metadata(path);
}

test "storage cleanup: reviewed hold exceptions do not override independent or policy holds" {
    for (0..4) |case| {
        const f = try Fixture.init();
        defer f.deinit();
        try heldProductsFixture(f, true);
        var e = f.engine();
        e.config.protected_paths = if (case == 3) &.{ shared_cache, "local-state/caches" } else &.{"local-state/caches"};
        try held_products.prepare(&e, held_plan);
        if (case != 3) try e.release_holds.append(e.c.a, switch (case) {
            0 => shared_cache,
            1 => "local-state/caches",
            else => shared_cache ++ "/o/tool",
        });
        try e.loadHolds();
        try t.expectEqual(.skipped, e.actions.items[0].status);
        try held_products.finish(&e);
        var fresh = f.engine();
        try fresh.loadHolds();
        try t.expectEqual(@as(usize, 3), fresh.held.items.len);
        _ = try fresh.metadata(shared_cache ++ "/o/tool");
    }
}

test "storage cleanup: held release remains authoritative in explicit product review" {
    const f = try Fixture.init();
    defer f.deinit();
    try heldProductsFixture(f, true);
    var e = f.engine();
    var held = try releases.disposableBuild(&e, report, "Active exact product investigation");
    held.state = .held;
    try e.write(run ++ "/storage-release.json", held);
    var fresh = f.engine();
    try held_products.prepare(&fresh, held_plan);
    try fresh.loadHolds();
    try t.expectEqual(@as(usize, 2), fresh.actions.items.len);
    try t.expectEqual(.skipped, fresh.actions.items[1].status);
    try t.expectEqual(.discovered, fresh.actions.items[0].status);
}

test "storage cleanup: product review without hold release preserves existing holds" {
    for ([_]bool{ false, true }) |held| {
        const f = try Fixture.init();
        defer f.deinit();
        try heldProductsFixture(f, true);
        var prepare = f.engine();
        if (!held) try prepare.write(prepare.config.holds_file, p.Holds{ .paths = &.{ run ++ "/z_llvm", report } });
        const json = try prepare.load(prepare.c.a, held_plan);
        var plan = (try std.json.parseFromValue(held_products.Plan, prepare.c.a, json.value, .{ .allocate = .alloc_always })).value;
        var products = [_]held_products.Product{plan.products[0]};
        products[0].release_manual_hold = false;
        plan.products = &products;
        plan.holds.sha256 = try prepare.digest(prepare.config.holds_file);
        try prepare.write(held_plan, plan);
        var e = f.engine();
        try held_products.prepare(&e, held_plan);
        try e.loadHolds();
        try t.expectEqual(@as(usize, 0), e.reviewed_hold_paths.len);
        if (held) {
            try t.expectEqual(.skipped, e.actions.items[0].status);
            _ = try e.metadata(shared_cache ++ "/o/tool");
        } else {
            try e.qualify(0);
            try cache_batch.apply(&e, &.{0});
        }
        try held_products.finish(&e);
        try t.expectEqualStrings(plan.holds.sha256, try e.digest(e.config.holds_file));
    }
}

const readiness = @import("readiness_cache.zig");
const readiness_root = run ++ "/readiness-zig-local-behavior-v1";
const readiness_receipt = run ++ "/readiness-behavior-v1-run.json";
fn readinessFixture(f: *Fixture, e: *core.Engine, case: usize) !readiness.Launcher {
    const script_path = run ++ "/run-readiness-behavior-v1.sh";
    const snapshot = run ++ "/source-frozen-v1.json";
    try f.write(snapshot, "{\"status\":\"passed\"}");
    var binding: readiness.Launcher = .{
        .script = .{ .path = script_path, .sha256 = "" },
        .source_snapshot = .{ .path = snapshot, .sha256 = try e.digest(snapshot) },
        .compiler = run ++ "/compiler/Debug/bin/z_llvm",
        .zig_source_directory = "/source/zig",
        .zig_emitter = "/source/zig/build/bin/zig",
    };
    const bytes = try readiness.script(e, readiness_root, binding);
    try f.write(script_path, if (case == 1) try e.c.fmt("{s}echo changed\n", .{bytes}) else bytes);
    binding.script.sha256 = try e.digest(script_path);
    try e.write(readiness_receipt, .{
        .status = if (case == 2) "running" else "finished",
        .outcome = "completed",
        .actual_returncode = 0,
        .returncode = 0,
        .started_ns = 1,
        .finished_ns = if (case == 3) @as(i64, 1) else @as(i64, 2),
        .cwd = if (case == 4) "/other/repo" else e.c.root,
        .argv = [_][]const u8{ "bash", if (case == 5) run ++ "/other.sh" else script_path },
    });
    return binding;
}

test "storage cleanup: exact readiness launcher binds closed cache ownership and retained evidence" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    const binding = try readinessFixture(f, &e, 0);
    var kept: std.ArrayList(p.Evidence) = .empty;
    try readiness.verify(&e, readiness_root, .{ .path = readiness_receipt, .sha256 = try e.digest(readiness_receipt) }, binding, &kept);
    try t.expectEqual(@as(usize, 3), kept.items.len);
    for (kept.items) |ev| try e.check(ev);
}

test "storage cleanup: readiness review rejects changed shell logic and unbound completion" {
    for (1..6) |case| {
        const f = try Fixture.init();
        defer f.deinit();
        var e = f.engine();
        const binding = try readinessFixture(f, &e, case);
        var kept: std.ArrayList(p.Evidence) = .empty;
        try t.expectError(switch (case) {
            1 => error.UnsupportedReadinessLauncher,
            2, 3 => error.ReadinessNotClosed,
            4 => error.ReadinessWorkingDirectoryMismatch,
            else => error.UnboundReadinessLauncher,
        }, readiness.verify(&e, readiness_root, .{ .path = readiness_receipt, .sha256 = try e.digest(readiness_receipt) }, binding, &kept));
    }
}

test "storage cleanup: held products reject running owners and changed review controls" {
    for (0..3) |case| {
        const f = try Fixture.init();
        defer f.deinit();
        try heldProductsFixture(f, case != 0);
        var e = f.engine();
        if (case == 0) {
            try t.expectError(error.CacheReceiptNotClosed, held_products.prepare(&e, held_plan));
            continue;
        }
        try held_products.prepare(&e, held_plan);
        if (case == 1) {
            try f.write(e.config.holds_file, "{\"schema\":1,\"paths\":[]}");
            if (e.loadHolds()) |_| return error.ChangedReviewAccepted else |_| {}
        } else {
            try e.loadHolds();
            try e.qualify(0);
            try f.write(output ++ "/cache-run.json", "{\"status\":\"running\"}");
            if (cache_batch.apply(&e, &.{0})) |_| return error.ChangedReceiptAccepted else |_| {}
        }
        _ = try e.metadata(shared_cache ++ "/o/tool");
    }
}

test "storage cleanup: shared cache env ownership stops at the actual command" {
    for ([_]bool{ false, true }) |leading| {
        const f = try Fixture.init();
        defer f.deinit();
        try heldProductsFixture(f, true);
        var e = f.engine();
        const receipt = output ++ "/cache-run.json";
        const argv = if (leading) &[_][]const u8{ "env", "ZIG_LOCAL_CACHE_DIR=" ++ shared_cache, "zig", "build" } else &[_][]const u8{ "env", "zig", "build", "ZIG_LOCAL_CACHE_DIR=" ++ shared_cache };
        try e.write(receipt, .{ .status = "finished", .outcome = "completed", .actual_returncode = 1, .started_ns = 1, .finished_ns = 2, .argv = argv });
        var old = try e.load(e.c.gpa, held_plan);
        defer old.deinit();
        const parsed = try std.json.parseFromValue(held_products.Plan, e.c.a, old.value, .{ .allocate = .alloc_always });
        var plan = parsed.value;
        const products = try e.c.a.dupe(held_products.Product, plan.products);
        products[0].closed_receipts = &.{.{ .path = receipt, .sha256 = try e.digest(receipt) }};
        plan.products = products;
        try e.write(held_plan, plan);
        var fresh = f.engine();
        if (leading) try held_products.prepare(&fresh, held_plan) else try t.expectError(error.CacheReceiptDoesNotOwnRoot, held_products.prepare(&fresh, held_plan));
    }
}

test "storage cleanup: reviewed caches retain pinned bytes and reject misplaced raw traces" {
    for ([_]bool{ false, true }) |trace| {
        const f = try Fixture.init();
        defer f.deinit();
        try heldProductsFixture(f, true);
        if (trace) try f.write(shared_cache ++ "/o/profile.events.jsonl", "raw evidence");
        var e = f.engine();
        try held_products.prepare(&e, held_plan);
        try e.loadHolds();
        if (trace) {
            try t.expectError(error.WorkspaceContainsRawTrace, e.qualify(0));
        } else {
            try e.qualify(0);
            try f.write(run ++ "/pinned.sha256", try f.c.fmt("{s}  {s}\n", .{ try e.digest(shared_cache ++ "/o/tool"), shared_cache ++ "/o/tool" }));
            try t.expectError(error.CacheBatchBecameHeld, cache_batch.apply(&e, &.{0}));
        }
        _ = try e.metadata(shared_cache ++ "/o/tool");
    }
    for ([_][]const u8{ "local-state/caches", "local-state/caches/a/child", "local-state/inputs/a", "local-state/validations/a/b/source", "../cache" }) |path| try t.expect(!held_products.cacheScope(path));
}
fn receiptFixture(f: *Fixture, cwd: ?[]const u8, destination: []const u8, code: i32) !void {
    try f.tmp.dir.createDirPath(t.io, receipt_root);
    try f.write(receipt_root ++ "/compiler-old", "\x7fELFclosed compiler");
    try f.write(receipt_root ++ "/build.log", "build diagnostics");
    try f.write(receipt_root ++ "/main.zig", "source remains");
    var e = f.engine();
    try e.write(receipt_path, .{ .argv = [_][]const u8{ "zig", "build-exe", receipt_root ++ "/main.zig", try f.c.fmt("-femit-bin={s}", .{destination}) }, .cwd = cwd, .status = "finished", .outcome = "completed", .returncode = code, .actual_returncode = code, .started_ns = 1, .finished_ns = 2, .log = try e.absolute(receipt_root ++ "/build.log") });
}

test "storage cleanup: modern standalone receipt retires a shallow explicit product" {
    const f = try Fixture.init();
    defer f.deinit();
    try receiptFixture(f, f.c.root, receipt_root ++ "/compiler-old", 0);
    var e = f.engine();
    const request = try command_outputs.receipt(&e, .{ .producer = receipt_path, .working_directory = "." }, "Closed build");
    try e.write(output ++ "/receipt-release.json", request);
    try e.discoverRelease(output ++ "/receipt-release.json", true);
    try t.expectEqual(@as(usize, 1), e.actions.items.len);
    try e.qualify(0);
    try e.protectRetained();
    try mutation.applyFileBatch(&e, &.{0});
    try t.expectEqual(.removed, e.actions.items[0].status);
    for ([_][]const u8{ receipt_path, receipt_root ++ "/build.log", receipt_root ++ "/main.zig" }) |path| _ = try e.metadata(path);
}

test "storage cleanup: legacy receipt cwd needs explicit review and cannot override recorded cwd" {
    const f = try Fixture.init();
    defer f.deinit();
    try receiptFixture(f, null, receipt_root ++ "/compiler-old", 0);
    var e = f.engine();
    try t.expectError(error.MissingOutputWorkingDirectory, command_outputs.receipt(&e, .{ .producer = receipt_path, .working_directory = "." }, "Closed build"));
    _ = try command_outputs.receipt(&e, .{ .producer = receipt_path, .working_directory = ".", .legacy_working_directory_review = "Reviewed original runner project-root convention" }, "Closed build");
    try receiptFixture(f, "/different-checkout", receipt_root ++ "/compiler-old", 0);
    var fresh = f.engine();
    try t.expectError(error.OutputWorkingDirectoryMismatch, command_outputs.receipt(&fresh, .{ .producer = receipt_path, .working_directory = ".", .legacy_working_directory_review = "Cannot override a recorded cwd" }, "Closed build"));
}

test "storage cleanup: receipt rejects failure traversal and missing diagnostics" {
    const f = try Fixture.init();
    defer f.deinit();
    const binding: command_outputs.ReceiptEntry = .{ .producer = receipt_path, .working_directory = "." };
    try receiptFixture(f, f.c.root, receipt_root ++ "/compiler-old", 1);
    var failed = f.engine();
    try t.expectError(error.OutputCommandNotSuccessful, command_outputs.receipt(&failed, binding, "Closed build"));
    try receiptFixture(f, f.c.root, "../compiler-old", 0);
    var traversal = f.engine();
    try t.expectError(error.AmbiguousOutputArgument, command_outputs.receipt(&traversal, binding, "Closed build"));
    try receiptFixture(f, f.c.root, receipt_root ++ "/compiler-old", 0);
    try f.tmp.dir.deleteFile(t.io, receipt_root ++ "/build.log");
    var missing = f.engine();
    if (command_outputs.receipt(&missing, binding, "Closed build")) |_| return error.MissingDiagnosticAccepted else |_| {}
    _ = try missing.metadata(receipt_root ++ "/compiler-old");
}

test "storage cleanup: standalone command index is separated by reviewed cwd" {
    const f = try Fixture.init();
    defer f.deinit();
    try receiptFixture(f, null, "compiler-old", 0);
    var e = f.engine();
    const review = "Reviewed command directory";
    try t.expectError(error.NoBoundOutputs, command_outputs.receipt(&e, .{ .producer = receipt_path, .working_directory = ".", .legacy_working_directory_review = review }, "Closed build"));
    const request = try command_outputs.receipt(&e, .{ .producer = receipt_path, .working_directory = receipt_root, .legacy_working_directory_review = review }, "Closed build");
    try t.expectEqualStrings(receipt_root ++ "/compiler-old", request.artifacts[0].path);
}

fn wholeCompilerFixture(f: *Fixture, hash: ?[]const u8, help: bool) !void {
    var e = f.engine();
    try f.tmp.dir.createDirPath(t.io, run ++ "/install/bin");
    try f.write(run ++ "/install/bin/zig", "\x7fELFwhole compiler");
    try f.write(run ++ "/build.stdout", "build success");
    try f.write(run ++ "/build.stderr", "");
    try e.write(report, .{ .schema = "whole-compiler-diagnostic-v1", .status = "passed", .build_completed = true, .build_returncode = 0, .candidate = .{ .path = try e.absolute(run ++ "/install/bin/zig"), .sha256 = hash orelse try e.digest(run ++ "/install/bin/zig") } });
    const args = [_][]const u8{ "/usr/bin/time", "-f", "%e", "-o", try e.absolute(run ++ "/time.txt"), "--", "/toolchain/zig", "build", "--prefix", try e.absolute(run ++ "/install"), if (help) "--help" else "-Doptimize=ReleaseFast" };
    try e.write(run ++ "/commands.json", .{.{ .argv = args, .outcome = "completed", .actual_returncode = 0, .returncode = 0, .stdout = try e.absolute(run ++ "/build.stdout"), .stderr = try e.absolute(run ++ "/build.stderr") }});
}

test "storage cleanup: timed whole-compiler build requires exact installed candidate hash" {
    const f = try Fixture.init();
    defer f.deinit();
    try wholeCompilerFixture(f, null, false);
    var e = f.engine();
    const request = try command_outputs.request(&e, report, "Closed compiler diagnostic");
    try t.expectEqualStrings(run ++ "/install/bin/zig", request.artifacts[0].path);
    try wholeCompilerFixture(f, "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", false);
    var wrong = f.engine();
    try t.expectError(error.CopiedCompilerHashMismatch, command_outputs.request(&wrong, report, "Closed compiler diagnostic"));
    try wholeCompilerFixture(f, null, true);
    var warmup = f.engine();
    try t.expectError(error.NoBoundOutputs, command_outputs.request(&warmup, report, "Warmup is not a build"));
}

test "storage cleanup: fixed affinity wrapper binds successful compiler builds only" {
    for (0..4) |case| {
        const f = try Fixture.init();
        defer f.deinit();
        try wholeCompilerFixture(f, null, false);
        var prepare = f.engine();
        try prepare.write(run ++ "/commands.json", .{.{
            .argv = [_][]const u8{ "/usr/bin/time", "--", "/usr/bin/taskset", if (case == 1) "--pid" else "--cpu-list", if (case == 2) "0-1" else "0", "/toolchain/zig", "build", "--prefix", try prepare.absolute(run ++ "/install") },
            .outcome = "completed",
            .actual_returncode = if (case == 3) @as(i32, 1) else @as(i32, 0),
            .returncode = if (case == 3) @as(i32, 1) else @as(i32, 0),
            .stdout = run ++ "/build.stdout",
            .stderr = run ++ "/build.stderr",
        }});
        var e = f.engine();
        if (case != 0) {
            try t.expectError(if (case == 3) error.OutputCommandNotSuccessful else error.UnsupportedOutputWrapper, command_outputs.request(&e, report, "Reject unknown or failed wrapper"));
        } else {
            try e.write(output ++ "/affinity.json", try command_outputs.request(&e, report, "Closed affinity-bound build"));
            try e.discoverRelease(output ++ "/affinity.json", true);
            try e.qualify(0);
            try mutation.applyFileBatch(&e, &.{0});
            try t.expectEqual(.removed, e.actions.items[0].status);
            _ = try e.metadata(run ++ "/commands.json");
            _ = try e.metadata(run ++ "/build.stdout");
        }
    }
}

test "storage cleanup: report toolchain binds compiler stdout and selected output owners" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try f.write(run ++ "/subject.o", "\x7fELFobject");
    try f.write(run ++ "/compiler.stderr", "diagnostic");
    try f.write(run ++ "/failed", "\x7fELFfailed product stays");
    try e.write(report, .{ .schema = "upstream-c-program-v1", .status = "passed", .toolchain = .{ .zllvm = "/known/compiler" } });
    const Command = struct { argv: []const []const u8, outcome: []const u8 = "completed", actual_returncode: i32 = 0, returncode: i32 = 0, stdout: []const u8, stderr: []const u8 };
    try e.write(run ++ "/commands.json", [_]Command{
        .{ .argv = &.{ "/known/compiler", "--emit=obj", "input.ll" }, .stdout = try e.absolute(run ++ "/subject.o"), .stderr = try e.absolute(run ++ "/compiler.stderr") },
        .{ .argv = &.{ "cc", "-o", try e.absolute(run ++ "/failed") }, .actual_returncode = 1, .returncode = 1, .stdout = try e.absolute(run ++ "/compiler.stderr"), .stderr = try e.absolute(run ++ "/compiler.stderr") },
    });
    try t.expectError(error.OutputCommandNotSuccessful, command_outputs.request(&e, report, "Review all outputs"));
    const selected = try command_outputs.requestSelected(&e, report, "Independently owned successful output", &.{run ++ "/subject.o"});
    try t.expectEqual(@as(usize, 1), selected.artifacts.len);
    try t.expectEqualStrings(run ++ "/subject.o", selected.artifacts[0].path);
}

fn cachePairFixture(f: *Fixture, passed: bool) !void {
    var e = f.engine();
    try f.tmp.dir.createDirPath(t.io, run ++ "/zig-global-cache/o");
    try f.write(cache ++ "/o/object", "local cache object");
    try f.write(run ++ "/zig-global-cache/o/object", "global cache object");
    try f.write(run ++ "/z_llvm", "\x7fELFcompiler must stay");
    try f.write(run ++ "/build.log", "kept diagnostics");
    try e.write(report, .{ .status = if (passed) "passed" else "failed", .commands = .{.{ .outcome = "completed", .actual_returncode = 0, .argv = [_][]const u8{ "zig", "build-exe", "--cache-dir", try e.absolute(cache), "--global-cache-dir", try e.absolute(run ++ "/zig-global-cache") } }} });
}
fn qualifyCachePair(e: *core.Engine) !void {
    e.config.cache_evidence = .closed_producer;
    for ([_][]const u8{ cache, run ++ "/zig-global-cache" }) |path| {
        const i = try e.add(path, run, report, .cache, null);
        try e.qualify(i);
    }
    try e.protectRetained();
}
fn cacheHoldsFixture(f: *Fixture, passed: bool) !void {
    try cachePairFixture(f, passed);
    var e = f.engine();
    try e.write(e.config.holds_file, p.Holds{ .paths = &.{ run, released } });
    try f.write(output ++ "/roots.txt", run ++ "\n");
}

test "storage cleanup: narrowed cache hold retains every non-cache child and independent hold" {
    const f = try Fixture.init();
    defer f.deinit();
    try cacheHoldsFixture(f, true);
    var e = f.engine();
    const proposal = try cache_holds.prepare(&e, output ++ "/roots.txt");
    try t.expectEqual(@as(usize, 2), proposal.actions.len);
    try t.expectEqual(@as(usize, 4), proposal.after.paths.len);
    for ([_][]const u8{ released, run ++ "/z_llvm", report, run ++ "/build.log" }) |expected| {
        var found = false;
        for (proposal.after.paths) |path| if (std.mem.eql(u8, path, expected)) {
            found = true;
        };
        try t.expect(found);
    }
    try cache_holds.apply(&e, proposal);
    var fresh = f.engine();
    try fresh.loadHolds();
    try qualifyCachePair(&fresh);
    try cache_batch.apply(&fresh, try cache_batch.select(&fresh, 0));
    for (fresh.actions.items) |a| try t.expectEqual(.removed, a.status);
    for ([_][]const u8{ run ++ "/z_llvm", report, run ++ "/build.log", output ++ "/holds-before.json", output ++ "/holds-after.json" }) |path| _ = try fresh.metadata(path);
}

test "storage cleanup: hold narrowing refuses changed membership failed producers and changed holds" {
    for (0..3) |case| {
        const f = try Fixture.init();
        defer f.deinit();
        try cacheHoldsFixture(f, case != 0);
        var e = f.engine();
        if (case == 0) {
            try t.expectError(error.ProducerNotSuccessful, cache_holds.prepare(&e, output ++ "/roots.txt"));
            continue;
        }
        const proposal = try cache_holds.prepare(&e, output ++ "/roots.txt");
        if (case == 1) {
            try f.write(run ++ "/new-evidence.json", "{}");
            try t.expectError(error.HeldRootChanged, cache_holds.apply(&e, proposal));
        } else {
            try f.write(e.config.holds_file, "{\"schema\":1,\"paths\":[]}");
            if (cache_holds.apply(&e, proposal)) |_| return error.ChangedHoldAccepted else |_| {}
        }
        _ = try e.metadata(cache ++ "/o/object");
        try t.expect(!u.exists(t.io, try e.absolute(output ++ "/holds-after.json")));
    }
}

test "storage cleanup: bounded cache batch deletes both caches and retains evidence" {
    const f = try Fixture.init();
    defer f.deinit();
    try cachePairFixture(f, true);
    var e = f.engine();
    try qualifyCachePair(&e);
    try cache_batch.apply(&e, &.{ 0, 1 });
    for (e.actions.items) |a| {
        try t.expectEqual(.removed, a.status);
        try t.expectEqual(a.allocated_bytes, a.reclaimed_file_bytes);
        try t.expect(!u.exists(t.io, try e.absolute(a.path)));
    }
    for ([_][]const u8{ report, run ++ "/z_llvm", run ++ "/build.log" }) |path| _ = try e.metadata(path);
    try t.expect(!u.exists(t.io, try e.absolute(mutation.pending_path)));
}

test "storage cleanup: cache batch rolls back all roots on fresh pin or hold" {
    for ([_]bool{ false, true }) |hold| {
        const f = try Fixture.init();
        defer f.deinit();
        try cachePairFixture(f, true);
        var e = f.engine();
        try qualifyCachePair(&e);
        if (hold) try e.write(e.config.holds_file, p.Holds{ .paths = &.{run ++ "/zig-global-cache"} }) else try f.write(run ++ "/new-pin.sha256", try f.c.fmt("{s}  {s}\n", .{ try e.digest(run ++ "/zig-global-cache/o/object"), run ++ "/zig-global-cache/o/object" }));
        try t.expectError(error.CacheBatchBecameHeld, cache_batch.apply(&e, &.{ 0, 1 }));
        for (e.actions.items) |a| {
            _ = try e.metadata(a.path);
            try t.expectEqual(@as(u64, 0), a.reclaimed_file_bytes);
        }
        try t.expect(!u.exists(t.io, try e.absolute(mutation.pending_path)));
    }
}

test "storage cleanup: cache batch rejects changed data accounting and duplicate members" {
    for (0..3) |case| {
        const f = try Fixture.init();
        defer f.deinit();
        try cachePairFixture(f, true);
        var e = f.engine();
        try qualifyCachePair(&e);
        if (case == 0) {
            try f.write(run ++ "/zig-global-cache/o/object", "modified cache object");
            if (cache_batch.apply(&e, &.{ 0, 1 })) |_| return error.ChangedCacheAccepted else |_| {}
        } else if (case == 1) {
            e.actions.items[1].allocated_bytes += 4096;
            try t.expectError(error.AllocationMismatch, cache_batch.apply(&e, &.{ 0, 1 }));
        } else try t.expectError(error.InvalidCacheBatch, cache_batch.apply(&e, &.{ 0, 0 }));
        for (e.actions.items) |a| _ = try e.metadata(a.path);
        try t.expect(!u.exists(t.io, try e.absolute(mutation.pending_path)));
    }
}

fn commandOutputFixture(f: *Fixture, e: *core.Engine, success: bool) !void {
    try f.write(run ++ "/local", "\x7fELFtest executable");
    try f.write(run ++ "/reference.o", "\x7fELFtest object");
    try f.write(run ++ "/input.ll", "preserved test input");
    try f.write(run ++ "/compile.stdout", "diagnostic");
    try f.write(run ++ "/compile.stderr", "");
    try e.write(report, .{ .schema = "input-program-v1", .status = "passed" });
    const Command = struct { argv: []const []const u8, outcome: []const u8 = "completed", actual_returncode: i32, returncode: i32, stdout: []const u8, stderr: []const u8 };
    const code: i32 = if (success) 0 else 1;
    try e.write(run ++ "/commands.json", [_]Command{
        .{ .argv = &.{ "cc", try e.absolute(run ++ "/reference.o"), "-o", try e.absolute(run ++ "/local") }, .actual_returncode = code, .returncode = code, .stdout = run ++ "/compile.stdout", .stderr = run ++ "/compile.stderr" },
        .{ .argv = &.{ "clang-22", "-c", try e.absolute(run ++ "/input.ll"), "-o", try e.absolute(run ++ "/reference.o") }, .actual_returncode = 0, .returncode = 0, .stdout = run ++ "/compile.stdout", .stderr = run ++ "/compile.stderr" },
    });
}

const observed_binary = receipt_root ++ "/compiler-debug/bin/z_llvm";
const observed_report = receipt_root ++ "/native/report.json";
fn observedCompilerFixture(f: *Fixture, e: *core.Engine, case: usize) !void {
    try f.tmp.dir.createDirPath(t.io, receipt_root ++ "/compiler-debug/bin");
    try f.tmp.dir.createDirPath(t.io, receipt_root ++ "/native");
    try f.write(observed_binary, "\x7fELFlegacy debug compiler");
    try f.write(receipt_root ++ "/native/compile.stderr", "");
    try f.write(receipt_root ++ "/native/local.o", "\x7fELFdisposable object");
    try e.write(observed_report, .{ .schema = "native-canary-v1", .status = if (case == 1) "running" else "passed", .compiler_sha256 = if (case == 2) "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" else try e.digest(observed_binary) });
    // Legacy successful invocations lack outcome and actual_returncode.
    var command = try u.toValue(e.c.a, .{
        .argv = [_][]const u8{ try e.absolute(observed_binary), if (case == 3) "--version" else "--emit=obj", "input.ll" },
        .returncode = if (case == 4) @as(i32, 1) else @as(i32, 0),
        .stdout = receipt_root ++ "/native/local.o",
        .stderr = receipt_root ++ "/native/compile.stderr",
    });
    if (case == 5) try u.put(e.c.a, &command, "outcome", u.s("timed_out"));
    if (case == 6) try u.put(e.c.a, &command, "actual_returncode", .{ .integer = 1 });
    try e.write(receipt_root ++ "/native/commands.json", .{command});
    if (case == 7) try f.write(observed_binary ++ ".build.json", "{\"status\":\"incomplete\"}");
}

test "storage cleanup: legacy compiler observation retires exact binary without retaining its object" {
    const f = try Fixture.init();
    defer f.deinit();
    var prepare = f.engine();
    try observedCompilerFixture(f, &prepare, 0);
    var e = f.engine();
    const r = try observed_compiler.request(&e, observed_report, "Closed legacy temporary compiler");
    try t.expectEqualStrings(receipt_root, r.run_root);
    try e.write(output ++ "/observed.json", r);
    try e.discoverRelease(output ++ "/observed.json", true);
    try e.qualify(0);
    for (e.actions.items[0].retained) |ev| try t.expect(!std.mem.eql(u8, ev.path, receipt_root ++ "/native/local.o"));
    try mutation.applyFileBatch(&e, &.{0});
    try t.expectEqual(.removed, e.actions.items[0].status);
    for ([_][]const u8{ observed_report, receipt_root ++ "/native/commands.json", receipt_root ++ "/native/compile.stderr", receipt_root ++ "/native/local.o" }) |path| _ = try e.metadata(path);
}

test "storage cleanup: compiler observation rejects missing identity completion and existing receipts" {
    for (1..8) |case| {
        const f = try Fixture.init();
        defer f.deinit();
        var prepare = f.engine();
        try observedCompilerFixture(f, &prepare, case);
        var e = f.engine();
        try t.expectError(if (case == 1) error.UnboundCompilerObservation else error.NoObservedCompiler, observed_compiler.request(&e, observed_report, "Reject unbound compiler"));
        _ = try e.metadata(observed_binary);
    }
}

test "storage cleanup: observed compilers remain subject to holds current pins and changed evidence" {
    for (0..4) |case| {
        const f = try Fixture.init();
        defer f.deinit();
        var prepare = f.engine();
        try observedCompilerFixture(f, &prepare, 0);
        try prepare.write(output ++ "/observed.json", try observed_compiler.request(&prepare, observed_report, "Keep independent protections"));
        if (case == 0) try prepare.write(prepare.config.holds_file, p.Holds{ .paths = &.{receipt_root} });
        if (case == 1) try f.write(receipt_root ++ "/current.sha256", try prepare.c.fmt("{s}  {s}\n", .{ try prepare.digest(observed_binary), observed_binary }));
        if (case == 2) try f.write(observed_binary ++ ".build.json", "{\"status\":\"passed\"}");
        if (case == 3) try f.write(receipt_root ++ "/native/commands.json", "[]");
        var e = f.engine();
        if (case == 1) e.config.current_manifests = &.{receipt_root ++ "/current.sha256"};
        try e.discoverRelease(output ++ "/observed.json", true);
        try e.loadHolds();
        if (case == 0) {
            try t.expectEqual(.skipped, e.actions.items[0].status);
        } else if (case == 1) {
            try e.qualify(0);
            try e.pins();
            try e.currentManifests(true);
            try t.expectEqual(.skipped, e.actions.items[0].status);
        } else try t.expectError(if (case == 2) error.CanonicalBuildReceiptPresent else error.EvidenceHashMismatch, e.qualify(0));
        _ = try e.metadata(observed_binary);
    }
}

test "storage cleanup: explicit completed command outputs retire as a mixed file batch" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try commandOutputFixture(f, &e, true);
    try e.write(run ++ "/products-release.json", try command_outputs.request(&e, report, "Closed test products"));
    try e.discoverRelease(run ++ "/products-release.json", true);
    try t.expectEqual(@as(usize, 2), e.actions.items.len);
    for (0..2) |i| try e.qualify(i);
    try e.protectRetained();
    try mutation.applyFileBatch(&e, try mutation.fileBatch(&e, 0));
    for (e.actions.items) |a| try t.expectEqual(.removed, a.status);
    for ([_][]const u8{ report, run ++ "/commands.json", run ++ "/input.ll", run ++ "/compile.stdout", run ++ "/compile.stderr" }) |path| _ = try e.metadata(path);
}

test "storage cleanup: alias preparation binds peer commands and preserves an outside link" {
    for ([_]bool{ false, true }) |outside| {
        const f = try Fixture.init();
        defer f.deinit();
        var prepare = f.engine();
        try commandOutputFixture(f, &prepare, false);
        const peer = "local-state/validations/test/batch/peer";
        try f.tmp.dir.createDirPath(t.io, peer);
        {
            const file = try f.tmp.dir.openFile(t.io, run ++ "/reference.o", .{});
            defer file.close(t.io);
            try file.hardLink(t.io, f.tmp.dir, peer ++ "/reference.o", .{});
            if (outside) try file.hardLink(t.io, f.tmp.dir, "toolchain/unreviewed-object", .{});
        }
        try f.write(peer ++ "/compile.log", "peer diagnostics");
        try prepare.write(peer ++ "/report.json", .{ .status = "passed" });
        try prepare.write(peer ++ "/commands.json", .{.{ .argv = [_][]const u8{ "cc", "-c", "input.c", "-o", try prepare.absolute(peer ++ "/reference.o") }, .outcome = "completed", .actual_returncode = 0, .returncode = 0, .stdout = try prepare.absolute(peer ++ "/compile.log"), .stderr = try prepare.absolute(peer ++ "/compile.log") }});
        try prepare.write(output ++ "/original.json", try command_outputs.requestSelected(&prepare, report, "Original owner", &.{run ++ "/reference.o"}));
        try prepare.write(output ++ "/original-list.json", batches.List{ .requests = &.{.{ .path = output ++ "/original.json", .sha256 = try prepare.digest(output ++ "/original.json") }} });
        try legacy_outputs.aliases(&prepare, output ++ "/original-list.json", "Resolve independently owned peer");
        var collect = f.engine();
        collect.allow_artifact_aliases = true;
        const requests = try batches.load(&collect, output ++ "/requests.json");
        try t.expectEqual(@as(usize, 2), requests.len);
        for (requests) |request| try collect.discoverRelease(request.path, true);
        try t.expectEqual(@as(usize, 2), collect.actions.items.len);
        if (outside) {
            try t.expectError(error.AliasedOrNonRegularArtifact, collect.qualify(0));
            _ = try collect.metadata("toolchain/unreviewed-object");
        } else {
            for (0..2) |i| try collect.qualify(i);
            try collect.protectRetained();
            try collect.guardCaptureGroups();
            try mutation.applyFileBatch(&collect, &.{ 0, 1 });
            for (collect.actions.items) |a| try t.expectEqual(.removed, a.status);
        }
        for ([_][]const u8{ run ++ "/local", report, peer ++ "/report.json", peer ++ "/commands.json", peer ++ "/compile.log" }) |path| _ = try collect.metadata(path);
    }
}

test "storage cleanup: unsuccessful output command cannot release a passed owner's files" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try commandOutputFixture(f, &e, false);
    try t.expectError(error.OutputCommandNotSuccessful, command_outputs.request(&e, report, "Rejected output"));
}

test "storage cleanup: explicit closed outputs retire failed products but retain diagnostics" {
    for ([_][]const u8{ "passed", "failed" }) |status| {
        const f = try Fixture.init();
        defer f.deinit();
        var prepare = f.engine();
        try commandOutputFixture(f, &prepare, false);
        try prepare.write(report, .{ .schema = "input-program-v1", .status = status });
        var e = f.engine();
        const r = try command_outputs.requestClosed(&e, report, "Closed failed or negative-test products");
        try t.expect(r.closed_command_outputs);
        try e.write(run ++ "/products-release.json", r);
        try e.discoverRelease(run ++ "/products-release.json", true);
        for (0..2) |i| try e.qualify(i);
        try e.protectRetained();
        try mutation.applyFileBatch(&e, &.{ 0, 1 });
        for (e.actions.items) |a| try t.expectEqual(.removed, a.status);
        for ([_][]const u8{ report, run ++ "/commands.json", run ++ "/input.ll", run ++ "/compile.stdout", run ++ "/compile.stderr" }) |path| _ = try e.metadata(path);
    }
}

test "storage cleanup: closed output opt-in rejects unfinished owners and commands" {
    for (0..5) |case| {
        const f = try Fixture.init();
        defer f.deinit();
        var prepare = f.engine();
        try commandOutputFixture(f, &prepare, false);
        if (case == 0) try prepare.write(report, .{ .status = "running" });
        if (case != 0) try prepare.write(run ++ "/commands.json", .{.{
            .argv = [_][]const u8{ "cc", "input.c", "-o", try prepare.absolute(run ++ "/local") },
            .outcome = switch (case) {
                1 => "running",
                2 => "timed_out",
                3 => "canceled",
                else => "completed",
            },
            .actual_returncode = if (case == 4) @as(?i32, null) else @as(?i32, 1),
            .returncode = 1,
            .stdout = run ++ "/compile.stdout",
            .stderr = run ++ "/compile.stderr",
        }});
        var e = f.engine();
        try t.expectError(if (case == 0) error.UnboundOutputOwner else error.OutputCommandNotSuccessful, command_outputs.requestClosed(&e, report, "Reject incomplete commands"));
        _ = try e.metadata(run ++ "/local");
    }
}

test "storage cleanup: closed output opt-in cannot waive holds pins or compiled magic" {
    for (0..3) |case| {
        const f = try Fixture.init();
        defer f.deinit();
        var prepare = f.engine();
        try commandOutputFixture(f, &prepare, false);
        if (case == 0) try prepare.write(prepare.config.holds_file, p.Holds{ .paths = &.{run ++ "/local"} });
        if (case == 1) try f.write(run ++ "/historical.sha256", try prepare.c.fmt("{s}  {s}\n", .{ try prepare.digest(run ++ "/local"), run ++ "/local" }));
        if (case == 2) try f.write(run ++ "/local", "#!/bin/sh\nexit 0\n");
        var e = f.engine();
        try e.write(run ++ "/products-release.json", try command_outputs.requestClosed(&e, report, "Keep independently protected files"));
        try e.discoverRelease(run ++ "/products-release.json", true);
        try e.loadHolds();
        if (case == 2) {
            try t.expectError(error.NotCompiledOutput, e.qualify(0));
        } else {
            if (case == 1) {
                try e.qualify(0);
                try e.pins();
            }
            try t.expectEqual(.skipped, e.actions.items[0].status);
        }
        _ = try e.metadata(run ++ "/local");
    }
}

fn partialLinkFixture(f: *Fixture, e: *core.Engine, case: usize) !void {
    try commandOutputFixture(f, e, false);
    var bytes: [512]u8 = @splat(0);
    // Zero ELF header, PT_PHDR and the read-only PT_LOAD used by the native
    // linker, copied structurally from a retained wrong-symbol control.
    const words = [_]u64{ 0x400000006, 64, 0x1000040, 0x1000040, 448, 448, 8, 0x400000001, 0, 0x1000000, 0x1000000, 512, 512, 4096 };
    for (words, 0..) |word, i| std.mem.writeInt(u64, bytes[64 + i * 8 ..][0..8], word, .little);
    if (case == 1) bytes[0] = '#';
    if (case == 2) bytes[96] = 0; // Invalid program-header table extent.
    try f.write(run ++ "/wrong-symbol", if (case == 3) bytes[0..175] else &bytes);
    try f.write(run ++ "/compile.stderr", if (case == 4) "unrelated failure" else "error: undefined symbol: test.symbol\n");
    try e.write(report, .{ .schema = if (case == 5) "input-program-v1" else "execution-breadth-controls-v2", .status = "passed" });
    try e.write(run ++ "/commands.json", .{.{
        .argv = [_][]const u8{ "zig", "build-exe", if (case == 6) "-flld" else "-fno-lld", "-fno-lto", try e.c.fmt("-femit-bin={s}", .{try e.absolute(run ++ "/wrong-symbol")}) },
        .outcome = "completed",
        .actual_returncode = if (case == 7) @as(i32, 0) else @as(i32, 1),
        .returncode = if (case == 7) @as(i32, 0) else @as(i32, 1),
        .stdout = run ++ "/compile.stdout",
        .stderr = run ++ "/compile.stderr",
    }});
}

test "storage cleanup: closed wrong-symbol link fragments require structural and diagnostic evidence" {
    for (0..9) |case| {
        const f = try Fixture.init();
        defer f.deinit();
        var prepare = f.engine();
        try partialLinkFixture(f, &prepare, case);
        var e = f.engine();
        var r = try command_outputs.requestClosed(&e, report, "Closed partial native-link output");
        if (case == 8) {
            // Successful mode must never inherit this partial-file exception.
            r.closed_command_outputs = false;
            var kept: std.ArrayList(p.Evidence) = .empty;
            try t.expectError(error.OutputCommandNotSuccessful, command_outputs.verify(&e, .{ .path = run ++ "/wrong-symbol", .run_root = run, .producer = report, .kind = .build_output, .sha256 = r.artifacts[0].sha256 }, r, (try e.load(e.c.a, report)).value, &kept));
            continue;
        }
        try e.write(run ++ "/products-release.json", r);
        try e.discoverRelease(run ++ "/products-release.json", true);
        if (case == 0) {
            try e.qualify(0);
            try mutation.applyFileBatch(&e, &.{0});
            try t.expectEqual(.removed, e.actions.items[0].status);
            for ([_][]const u8{ report, run ++ "/commands.json", run ++ "/compile.stderr" }) |path| _ = try e.metadata(path);
        } else {
            try t.expectError(error.NotCompiledOutput, e.qualify(0));
            _ = try e.metadata(run ++ "/wrong-symbol");
        }
    }
}

test "storage cleanup: multi-product requests retain only exact per-file pin exceptions" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try commandOutputFixture(f, &e, true);
    var r = try command_outputs.request(&e, report, "Closed products with historical references");
    const manifest = run ++ "/historical.sha256";
    try f.write(manifest, try e.c.fmt("{s}  {s}\n{s}  {s}\n", .{ r.artifacts[0].sha256, r.artifacts[0].path, r.artifacts[1].sha256, r.artifacts[1].path }));
    var transitions: [2]p.PinTransition = undefined;
    for (r.artifacts, &transitions) |artifact, *transition| transition.* = .{ .manifest = .{ .path = manifest, .sha256 = try e.digest(manifest) }, .reference = artifact.path, .target = .{ .path = artifact.path, .sha256 = artifact.sha256 }, .reason = "Exact reviewed historical output" };
    r.retired_pins = &transitions;
    try e.write(run ++ "/products-release.json", r);
    try e.discoverRelease(run ++ "/products-release.json", true);
    for (0..2) |index| {
        try e.qualify(index);
        try t.expectEqual(@as(usize, 1), e.actions.items[index].retired_pins.len);
        try t.expectEqualStrings(e.actions.items[index].path, e.actions.items[index].retired_pins[0].target.path);
    }
    try e.pins();
    try mutation.applyFileBatch(&e, &.{ 0, 1 });
    for (e.actions.items) |a| try t.expectEqual(.removed, a.status);
    _ = try e.metadata(manifest);
}

test "storage cleanup: object-valued inventory pins require an exact recorded hash" {
    for (0..4) |case| {
        const f = try Fixture.init();
        defer f.deinit();
        var initial = f.engine();
        try commandOutputFixture(f, &initial, true);
        var r = try command_outputs.request(&initial, report, "Closed inventoried product");
        const artifact = r.artifacts[0];
        try t.expectEqualStrings(run ++ "/local", artifact.path);
        const manifest = run ++ "/artifact-manifest.json";
        var row = try u.toValue(f.c.a, .{ .bytes = @as(u64, 23), .sha256 = artifact.sha256 });
        switch (case) {
            1 => try u.put(f.c.a, &row, "sha256", u.s("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")),
            2 => try u.put(f.c.a, &row, "sha256", .{ .integer = 7 }),
            3 => _ = row.object.swapRemove("sha256"),
            else => {},
        }
        try initial.write(manifest, .{ .root = run, .files = .{ .local = row } });
        r.retired_pins = &.{.{ .manifest = .{ .path = manifest, .sha256 = try initial.digest(manifest) }, .reference = artifact.path, .target = .{ .path = artifact.path, .sha256 = artifact.sha256 }, .reason = "Reviewed exact historical entry" }};
        try initial.write(run ++ "/products-release.json", r);
        var e = f.engine();
        try e.discoverRelease(run ++ "/products-release.json", true);
        for (0..2) |index| try e.qualify(index);
        try e.pins();
        try t.expectEqual(@as(@FieldType(core.Action, "status"), if (case == 0) .ready else .skipped), e.actions.items[0].status);
        // The unrelated product stays eligible; cached manifests give the same decision.
        try t.expectEqual(.ready, e.actions.items[1].status);
        try e.pins();
        _ = try e.metadata(artifact.path);
    }
}

test "storage cleanup: other extensionless executables require commands and compiled bytes" {
    const f = try Fixture.init();
    defer f.deinit();
    var prepare = f.engine();
    try commandOutputFixture(f, &prepare, true);
    const path = run ++ "/case-reference";
    try f.write(path, "\x7fELFcompleted case executable");
    try prepare.write(run ++ "/commands.json", .{.{ .argv = [_][]const u8{ "cc", try prepare.absolute(run ++ "/input.ll"), "-o", try prepare.absolute(path) }, .outcome = "completed", .actual_returncode = @as(i32, 0), .returncode = @as(i32, 0), .stdout = run ++ "/compile.stdout", .stderr = run ++ "/compile.stderr" }});
    var e = f.engine();
    var r = try command_outputs.request(&e, report, "Completed named test executable");
    try t.expectEqual(@as(usize, 1), r.artifacts.len);
    try e.write(run ++ "/products-release.json", r);
    try e.discoverRelease(run ++ "/products-release.json", true);
    try e.qualify(0);
    r.command_outputs = null;
    try e.write(run ++ "/unbound-release.json", r);
    try t.expectError(error.InvalidReleaseArtifact, e.discoverRelease(run ++ "/unbound-release.json", true));
    try mutation.applyFileBatch(&e, &.{0});
    _ = try e.metadata(run ++ "/input.ll");
    // A command cannot promote a script into a compiled product by its name.
    try f.write(path, "#!/bin/sh\nexit 0\n");
    var again = f.engine();
    try again.write(run ++ "/script-release.json", try command_outputs.request(&again, report, "Reject script"));
    try again.discoverRelease(run ++ "/script-release.json", true);
    try t.expectError(error.NotCompiledOutput, again.qualify(0));
}

test "storage cleanup: extensionless product names require explicit output binding" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try commandOutputFixture(f, &e, true);
    var r = try command_outputs.request(&e, report, "Missing binding");
    r.command_outputs = null;
    try e.write(run ++ "/products-release.json", r);
    try e.discoverRelease(run ++ "/products-release.json", true);
    try t.expectError(error.MissingCommandOutputBinding, e.qualify(0));
}

test "storage cleanup: command output adapter ignores shell and source outputs" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try t.expectError(error.UnboundOutputOwner, command_outputs.request(&e, "local-state/inputs/legacy/run/report.json", "Reject maintained input scope"));
    try commandOutputFixture(f, &e, true);
    // A source-looking -o is never promoted merely because a command names it.
    try e.write(run ++ "/commands.json", .{.{ .argv = [_][]const u8{ "cc", "-S", "-o", try e.absolute(run ++ "/input.ll") }, .outcome = "completed", .actual_returncode = 0, .returncode = 0 }});
    var fresh = f.engine();
    try t.expectError(error.NoBoundOutputs, command_outputs.request(&fresh, report, "No compiled outputs"));
    try e.write(run ++ "/commands.json", .{.{ .argv = [_][]const u8{ "bash", "-c", "cc -o local source.c" }, .outcome = "completed", .actual_returncode = 0, .returncode = 0 }});
    fresh = f.engine();
    try t.expectError(error.NoBoundOutputs, command_outputs.request(&fresh, report, "No direct output command"));
}

test "storage cleanup: changed command evidence preserves every batched product" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try commandOutputFixture(f, &e, true);
    try e.write(run ++ "/products-release.json", try command_outputs.request(&e, report, "Closed products"));
    try e.discoverRelease(run ++ "/products-release.json", true);
    for (0..2) |i| try e.qualify(i);
    try f.write(run ++ "/commands.json", "[]");
    if (mutation.applyFileBatch(&e, &.{ 0, 1 })) |_| return error.ChangedEvidenceAccepted else |_| {}
    for (e.actions.items) |a| _ = try e.metadata(a.path);
    try t.expect(!u.exists(t.io, try e.absolute(mutation.pending_path)));
}

test "storage cleanup: cached owner request detects changes between product qualifications" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try commandOutputFixture(f, &e, true);
    var r = try command_outputs.request(&e, report, "Closed products");
    try e.write(run ++ "/products-release.json", r);
    try e.discoverRelease(run ++ "/products-release.json", true);
    try e.qualify(0);
    r.reason = "Changed after first product qualified";
    try e.write(run ++ "/products-release.json", r);
    try t.expectError(error.FileChanged, e.qualify(1));
    for (e.actions.items) |a| _ = try e.metadata(a.path);
    try t.expect(!u.exists(t.io, try e.absolute(mutation.pending_path)));
}

test "storage cleanup: copied compiler output requires the recorded compiler hash" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try commandOutputFixture(f, &e, true);
    try f.write(run ++ "/z_llvm", "\x7fELFcopied compiler");
    const original = try e.absolute(run ++ "/original/z_llvm");
    try e.write(report, .{ .status = "passed", .compiler = original, .compiler_sha256 = try e.digest(run ++ "/z_llvm") });
    try e.write(run ++ "/commands.json", .{.{ .argv = [_][]const u8{ "cp", original, try e.absolute(run ++ "/z_llvm") }, .outcome = "completed", .actual_returncode = @as(i32, 0), .returncode = @as(i32, 0), .stdout = run ++ "/compile.stdout", .stderr = run ++ "/compile.stderr" }});
    var fresh = f.engine();
    const r = try command_outputs.request(&fresh, report, "Closed compiler copy");
    try t.expectEqual(@as(usize, 1), r.artifacts.len);
    try e.write(report, .{ .status = "passed", .compiler = original, .compiler_sha256 = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" });
    fresh = f.engine();
    try t.expectError(error.CopiedCompilerHashMismatch, command_outputs.request(&fresh, report, "Reject unbound copy"));
    try e.write(run ++ "/commands.json", .{.{ .argv = [_][]const u8{ "cp", original, run ++ "/z_llvm" }, .outcome = "completed", .actual_returncode = @as(i32, 0), .returncode = @as(i32, 0) }});
    fresh = f.engine();
    try t.expectError(error.NoBoundOutputs, command_outputs.request(&fresh, report, "Relative copy destination has no cwd binding"));
}

const peer_trace = released ++ "/peer/profile.events.jsonl";
fn traceAliasFixture(f: *Fixture) !void {
    var prepare = f.engine();
    _ = try f.release(&prepare, .raw_trace, true, true, false);
    try f.tmp.dir.createDirPath(t.io, released ++ "/peer");
    const file = try f.tmp.dir.openFile(t.io, released ++ "/profile.events.jsonl", .{});
    defer file.close(t.io);
    try file.hardLink(t.io, f.tmp.dir, peer_trace, .{});
    var audit = try prepare.load(f.c.a, released ++ "/audit.json");
    try audit.value.object.put(f.c.a, "path", .{ .string = peer_trace });
    try prepare.write(released ++ "/peer-audit.json", audit.value);
    const parsed = try prepare.load(f.c.a, released ++ "/storage-release.json");
    var r = (try std.json.parseFromValue(p.Release, f.c.a, parsed.value, .{})).value;
    var artifacts: [2]p.Artifact = .{ r.artifacts[0], .{ .path = peer_trace, .sha256 = r.artifacts[0].sha256, .kind = .raw_trace, .audit = released ++ "/peer-audit.json" } };
    var rows: std.ArrayList(p.Retained) = .empty;
    try rows.appendSlice(f.c.a, r.retained);
    try rows.append(f.c.a, .{ .path = released ++ "/peer-audit.json", .sha256 = try prepare.digest(released ++ "/peer-audit.json"), .role = .audit });
    r.retained = rows.items;
    r.artifacts = &artifacts;
    r.state = .audited;
    r.successor = null;
    try prepare.write(released ++ "/storage-release.json", r);
}
fn qualifyTraceAliases(f: *Fixture, e: *core.Engine) !void {
    _ = f;
    e.allow_artifact_aliases = true;
    try e.discoverRelease(released ++ "/storage-release.json", true);
    for (0..2) |i| try e.qualify(i);
    try e.guardCaptureGroups();
}

test "storage cleanup: audited trace alias batch frees exactly one physical allocation" {
    const f = try Fixture.init();
    defer f.deinit();
    try traceAliasFixture(f);
    var e = f.engine();
    try qualifyTraceAliases(f, &e);
    const allocation = e.actions.items[0].metadata.?.allocated_bytes;
    try t.expectError(error.AllocationMismatch, mutation.applyFileBatch(&e, &.{ 1, 0 }));
    for (e.actions.items) |a| _ = try e.metadata(a.path);
    try mutation.applyFileBatch(&e, try mutation.fileBatch(&e, 0));
    try t.expectEqual(allocation, e.actions.items[0].reclaimed_file_bytes + e.actions.items[1].reclaimed_file_bytes);
    for (e.actions.items) |a| try t.expectEqual(.removed, a.status);
    _ = try e.metadata(released ++ "/input.ll");
}

test "storage cleanup: missing trace alias audit prevents physical retirement" {
    const f = try Fixture.init();
    defer f.deinit();
    try traceAliasFixture(f);
    var e = f.engine();
    try qualifyTraceAliases(f, &e);
    try f.tmp.dir.deleteFile(t.io, released ++ "/peer-audit.json");
    if (mutation.applyFileBatch(&e, &.{ 0, 1 })) |_| return error.MissingAuditAccepted else |_| {}
    for (e.actions.items) |a| _ = try e.metadata(a.path);
    try t.expect(!u.exists(t.io, try e.absolute(mutation.pending_path)));
}

test "storage cleanup: unknown third trace name prevents group admission" {
    const f = try Fixture.init();
    defer f.deinit();
    try traceAliasFixture(f);
    const file = try f.tmp.dir.openFile(t.io, peer_trace, .{});
    defer file.close(t.io);
    try file.hardLink(t.io, f.tmp.dir, released ++ "/unknown-alias", .{});
    var e = f.engine();
    e.allow_artifact_aliases = true;
    try e.discoverRelease(released ++ "/storage-release.json", true);
    try t.expectError(error.AliasedOrNonRegularArtifact, e.qualify(0));
    for (e.actions.items) |a| _ = try e.metadata(a.path);
}

test "storage cleanup: cached alias index rechecks names after a same-count relink" {
    const f = try Fixture.init();
    defer f.deinit();
    try traceAliasFixture(f);
    var e = f.engine();
    try qualifyTraceAliases(f, &e);
    const file = try f.tmp.dir.openFile(t.io, peer_trace, .{});
    defer file.close(t.io);
    try file.hardLink(t.io, f.tmp.dir, released ++ "/unlisted-link", .{});
    try f.tmp.dir.deleteFile(t.io, peer_trace);
    try t.expectEqual(@as(u64, 2), (try e.metadata(released ++ "/profile.events.jsonl")).links);
    e.actions.items[0].status = .discovered;
    try t.expectError(error.AliasedOrNonRegularArtifact, e.qualify(0));
    _ = try e.metadata(released ++ "/profile.events.jsonl");
    try t.expect(!u.exists(t.io, try e.absolute(mutation.pending_path)));
}

test "storage cleanup: new trace alias pin rolls back both quarantined names" {
    const f = try Fixture.init();
    defer f.deinit();
    try traceAliasFixture(f);
    var e = f.engine();
    try qualifyTraceAliases(f, &e);
    try f.write(run ++ "/new-pin.sha256", try f.c.fmt("{s}  {s}\n", .{ e.actions.items[1].sha256.?, peer_trace }));
    try t.expectError(error.GeneratedBatchBecameHeld, mutation.applyFileBatch(&e, &.{ 0, 1 }));
    for (e.actions.items) |a| try t.expectEqual(@as(u64, 2), (try e.metadata(a.path)).links);
    try t.expect(!u.exists(t.io, try e.absolute(mutation.pending_path)));
}
fn workspaceFixture(f: *Fixture, passed: bool) !workspace.Workspace {
    try f.c.mkdir(try f.c.join(&.{"docs"}));
    try f.c.mkdir(try f.c.join(&.{"tools"}));
    try f.write("docs/storage_cleanup_policy.json", "{\"schema\":1}");
    try f.write("tools/clean-storage", "fixture wrapper");
    const w = (try workspace.start(&f.c, try f.c.join(&.{run}), "validation")).?;
    const object = try f.c.temporaryPath(&.{ run, "objects/subject.o" });
    try f.c.write(object, "\x7fELFtemporary object");
    try f.write(run ++ "/input.ll", "retained input");
    try f.write(run ++ "/profile.events.jsonl", "unique raw trace stays maintained");
    try f.write(run ++ "/diagnostic.log", "retained diagnostic");
    try f.c.writeJson(try f.c.join(&.{report}), .{ .status = if (passed) "passed" else "failed" });
    try w.finish(&f.c, try f.c.join(&.{report}), &.{try f.c.join(&.{ run, "diagnostic.log" })});
    return w;
}

test "storage cleanup: a completed separate workspace retires only temporary data and repeats safely" {
    const f = try Fixture.init();
    defer f.deinit();
    const w = try workspaceFixture(f, true);
    w.close(&f.c);
    var e = f.engine();
    try workspaces.discover(&e);
    try t.expectEqual(@as(usize, 1), e.actions.items.len);
    try e.qualify(0);
    try t.expectEqual(.temporary_workspace, e.actions.items[0].kind);
    try mutation.apply(&e, 0);
    try t.expect(!u.exists(f.c.io, try e.absolute(w.record.temporary_root)));
    for ([_][]const u8{ report, run ++ "/input.ll", run ++ "/profile.events.jsonl", run ++ "/diagnostic.log" }) |path| try t.expect(u.exists(f.c.io, try e.absolute(path)));
    var again = f.engine();
    try workspaces.discover(&again);
    try t.expectEqual(@as(usize, 0), again.actions.items.len);
}

fn workspaceSetFixture(f: *Fixture, count: usize, empty_others: bool) !void {
    const first = try workspaceFixture(f, true);
    first.close(&f.c);
    for (1..count) |i| {
        const key = if (i == 1) "second" else try f.c.fmt("workspace-{d}", .{i});
        const next = (try workspace.start(&f.c, try f.c.join(&.{run}), key)).?;
        if (!empty_others) try f.c.write(try f.c.join(&.{ next.record.temporary_root, "object.o" }), "\x7fELFtemporary object");
        try next.finish(&f.c, try f.c.join(&.{report}), &.{try f.c.join(&.{ run, "diagnostic.log" })});
        next.close(&f.c);
    }
}

test "storage cleanup: bounded workspace batches retire empty and populated roots with receipts" {
    const f = try Fixture.init();
    defer f.deinit();
    try workspaceSetFixture(f, 20, true);
    var e = f.engine();
    try workspaces.discover(&e);
    try t.expectEqual(@as(usize, 20), e.actions.items.len);
    for (0..20) |i| try e.qualify(i);
    const selected = try cache_batch.select(&e, 0);
    try t.expectEqual(@as(usize, 20), selected.len);
    try cache_batch.apply(&e, selected);
    for (e.actions.items, 0..) |action, i| {
        try t.expectEqual(.removed, action.status);
        try t.expectEqual(action.allocated_bytes, action.reclaimed_file_bytes);
        try t.expect(!u.exists(f.c.io, try e.absolute(action.path)));
        _ = try e.metadata(try f.c.fmt("{s}/record-{d}.json", .{ output, i }));
    }
    for ([_][]const u8{ report, run ++ "/diagnostic.log", run ++ "/profile.events.jsonl", run ++ "/input.ll" }) |path| _ = try e.metadata(path);
    try t.expect(!u.exists(f.c.io, try e.absolute(mutation.pending_path)));
}

test "storage cleanup: workspace batch rolls back both roots on a fresh evidence hold or pin" {
    for ([_]bool{ false, true }) |hold| {
        const f = try Fixture.init();
        defer f.deinit();
        try workspaceSetFixture(f, 20, false);
        var e = f.engine();
        try workspaces.discover(&e);
        for (0..20) |i| try e.qualify(i);
        if (hold) try e.write(e.config.holds_file, p.Holds{ .paths = &.{run ++ "/input.ll"} }) else {
            const member = try f.c.fmt("{s}/object.o", .{try workspace.paths.temporaryRoot(f.c.a, run, "second")});
            try f.write(run ++ "/new-pin.sha256", try f.c.fmt("{s}  {s}\n", .{ try e.digest(member), member }));
        }
        try t.expectError(error.CacheBatchBecameHeld, cache_batch.apply(&e, try cache_batch.select(&e, 0)));
        for (e.actions.items) |action| {
            _ = try e.metadata(action.path);
            try t.expectEqual(@as(u64, 0), action.reclaimed_file_bytes);
        }
        try t.expect(!u.exists(f.c.io, try e.absolute(mutation.pending_path)));
    }
}

test "storage cleanup: workspace batch rejects changed owner evidence before mutation" {
    const f = try Fixture.init();
    defer f.deinit();
    try workspaceSetFixture(f, 2, false);
    var e = f.engine();
    try workspaces.discover(&e);
    for (0..2) |i| try e.qualify(i);
    try f.write(run ++ "/diagnostic.log", "changed diagnostics");
    if (cache_batch.apply(&e, &.{ 0, 1 })) |_| return error.ChangedWorkspaceEvidenceAccepted else |_| {}
    for (e.actions.items) |action| _ = try e.metadata(action.path);
    try t.expect(!u.exists(f.c.io, try e.absolute(mutation.pending_path)));
}

test "storage cleanup: unfinished and failed workspaces retain their objects" {
    const f = try Fixture.init();
    defer f.deinit();
    const w = try workspaceFixture(f, false);
    w.close(&f.c);
    var failed = f.engine();
    try workspaces.discover(&failed);
    try t.expectEqual(.skipped, failed.actions.items[0].status);
    try f.c.writeJson(w.record_path, w.record); // original active record; no guessed expiry
    var active = f.engine();
    try workspaces.discover(&active);
    try t.expectEqual(.skipped, active.actions.items[0].status);
    try t.expect(u.exists(f.c.io, try active.absolute(w.record.temporary_root)));
}

test "storage cleanup: holds on either workspace tree protect all temporary products" {
    const f = try Fixture.init();
    defer f.deinit();
    const w = try workspaceFixture(f, true);
    w.close(&f.c);
    for ([_][]const u8{ run, run ++ "/input.ll", w.record.temporary_root }) |held| {
        var e = f.engine();
        try e.write(e.config.holds_file, p.Holds{ .paths = &.{held} });
        try workspaces.discover(&e);
        try e.loadHolds();
        try t.expectEqual(.skipped, e.actions.items[0].status);
    }
}

test "storage cleanup: workspace scope cannot promote maintained or unrelated paths to scratch" {
    const f = try Fixture.init();
    defer f.deinit();
    const w = try workspaceFixture(f, true);
    w.close(&f.c);
    for ([_][]const u8{ run, "local-state/tmp", "local-state/tmp/validations/other/.workspaces/validation", "local-state/tmp/validations/../artifacts" }) |path| {
        var record = w.record;
        record.temporary_root = path;
        try f.c.writeJson(w.record_path, record);
        var e = f.engine();
        try t.expectError(error.InvalidWorkspaceScope, workspaces.discover(&e));
    }
}

test "storage cleanup: changed workspace evidence prevents mutation" {
    const f = try Fixture.init();
    defer f.deinit();
    const w = try workspaceFixture(f, true);
    w.close(&f.c);
    var e = f.engine();
    try workspaces.discover(&e);
    try e.qualify(0);
    try f.write(run ++ "/diagnostic.log", "changed diagnostic");
    if (mutation.apply(&e, 0)) |_| return error.ChangedEvidenceAccepted else |_| {}
    try t.expect(u.exists(f.c.io, try e.absolute(w.record.temporary_root)));
    try t.expect(!u.exists(f.c.io, try e.absolute(mutation.pending_path)));
}

test "storage cleanup: a new workspace hold rolls back quarantine before unlink" {
    const f = try Fixture.init();
    defer f.deinit();
    const w = try workspaceFixture(f, true);
    w.close(&f.c);
    var e = f.engine();
    try workspaces.discover(&e);
    try e.qualify(0);
    try e.write(e.config.holds_file, p.Holds{ .paths = &.{run} });
    try t.expectError(error.WorkspaceBecameHeld, mutation.apply(&e, 0));
    try t.expect(u.exists(f.c.io, try e.absolute(try f.c.fmt("{s}/objects/subject.o", .{w.record.temporary_root}))));
    try t.expect(!u.exists(f.c.io, try e.absolute(mutation.pending_path)));
}

test "storage cleanup: workspace cannot collect external aliases or misfiled raw traces" {
    const f = try Fixture.init();
    defer f.deinit();
    const w = try workspaceFixture(f, true);
    w.close(&f.c);
    const object = try f.c.fmt("{s}/{s}/objects/subject.o", .{ f.c.root, w.record.temporary_root });
    const alias = try f.c.join(&.{ run, "adopted.o" });
    _ = try f.c.capture(&.{ "ln", "--", object, alias });
    var e = f.engine();
    try workspaces.discover(&e);
    try t.expectError(error.AliasedCacheFile, e.qualify(0));
    try std.Io.Dir.cwd().deleteFile(f.c.io, alias);
    const trace = try f.c.fmt("{s}/{s}/profile.events.jsonl", .{ f.c.root, w.record.temporary_root });
    try f.c.write(trace, "must be audited independently");
    var raw = f.engine();
    try workspaces.discover(&raw);
    try t.expectError(error.WorkspaceContainsRawTrace, raw.qualify(0));
}

test "storage cleanup: current checksum pins still protect temporary workspace files" {
    const f = try Fixture.init();
    defer f.deinit();
    const w = try workspaceFixture(f, true);
    w.close(&f.c);
    var e = f.engine();
    const object = try f.c.fmt("{s}/objects/subject.o", .{w.record.temporary_root});
    try f.write("current.sha256", try f.c.fmt("{s}  {s}\n", .{ try e.digest(object), object }));
    e.config.current_manifests = &.{"current.sha256"};
    try workspaces.discover(&e);
    try e.qualify(0);
    try e.pins();
    try t.expectEqual(.skipped, e.actions.items[0].status);
    try e.currentManifests(true);
}

test "storage cleanup: consumer descriptors in either workspace tree defer collection" {
    const f = try Fixture.init();
    defer f.deinit();
    const w = try workspaceFixture(f, true);
    w.close(&f.c);
    for ([_][]const u8{ run ++ "/input.ll", try f.c.fmt("{s}/objects/subject.o", .{w.record.temporary_root}) }) |path| {
        const file = try std.Io.Dir.cwd().openFile(f.c.io, try f.c.join(&.{path}), .{});
        defer file.close(f.c.io);
        var e = f.engine();
        try workspaces.discover(&e);
        try e.consumers();
        try t.expectEqual(.skipped, e.actions.items[0].status);
    }
}

test "storage cleanup: workspace allocation refuses reuse and maps capture children exactly" {
    const f = try Fixture.init();
    defer f.deinit();
    const w = try workspaceFixture(f, true);
    defer w.close(&f.c);
    try t.expectError(error.WorkspaceAlreadyExists, workspace.start(&f.c, try f.c.join(&.{run}), "validation"));
    try t.expectError(error.TemporaryPathOutsideWorkspace, f.c.temporaryPath(&.{"src/main.zig"}));
    try workspace.exportPaths(&f.c, &f.c.env);
    f.c.workspace_paths = null;
    try t.expectError(error.InvalidWorkspaceScope, workspace.adopt(&f.c)); // already finished
    try f.c.writeJson(w.record_path, w.record);
    try workspace.adopt(&f.c);
    try t.expectEqualStrings(try f.c.fmt("{s}/{s}/nested/probe.o", .{ f.c.root, w.record.temporary_root }), try f.c.temporaryPath(&.{ run, "nested/probe.o" }));
    const transient = try f.c.fmt("{s}/{s}/already-retired/marker.o", .{ f.c.root, w.record.temporary_root });
    try t.expectEqualStrings(transient, try f.c.resolveParent(transient));
    try f.c.env.put("ZLLVM_TEMPORARY_ROOT", try f.c.join(&.{"local-state/artifacts"}));
    if (workspace.adopt(&f.c)) |_| return error.InvalidMappingAccepted else |_| {}
}
const Fixture = struct {
    tmp: t.TmpDir,
    arena: std.heap.ArenaAllocator,
    c: u.Context,
    fn init() !*Fixture {
        const f = try t.allocator.create(Fixture);
        errdefer t.allocator.destroy(f);
        f.tmp = t.tmpDir(.{ .iterate = true });
        errdefer f.tmp.cleanup();
        f.arena = .init(t.allocator);
        errdefer f.arena.deinit();
        const a = f.arena.allocator();
        f.c = .{ .a = a, .gpa = t.allocator, .io = t.io, .root = try f.tmp.dir.realPathFileAlloc(t.io, ".", a), .env = try t.environ.createMap(a), .quiet = true };
        for ([_][]const u8{ output, "local-state/storage-cleanup", run, cache ++ "/o", "local-state/validations/test/source", "toolchain" }) |path| try f.tmp.dir.createDirPath(t.io, path);
        return f;
    }
    fn deinit(f: *Fixture) void {
        f.tmp.cleanup();
        f.arena.deinit();
        t.allocator.destroy(f);
    }
    fn write(f: *Fixture, path: []const u8, bytes: []const u8) !void {
        try f.tmp.dir.writeFile(t.io, .{ .sub_path = path, .data = bytes });
    }
    fn engine(f: *Fixture) core.Engine {
        var e = core.Engine.init(&f.c, .{ .minimum_idle_hours = 0 }, output, f.c.env.get("ZIGREP") orelse "zigrep");
        e.now_ns += std.time.ns_per_s * 60;
        return e;
    }
    fn build(f: *Fixture, e: *core.Engine) !void {
        try f.write(cache ++ "/o/object", "cache object");
        try f.write(run ++ "/z_llvm", "\x7fELFsynthetic compiler");
        try f.write(run ++ "/build.stdout", "successful build output");
        try f.write(run ++ "/build.stderr", "");
        try f.write("local-state/validations/test/source/main.zig", "pub fn main() void {}");
        try f.write("toolchain/zig", "compiler toolchain");
        const source = try e.absolute("local-state/validations/test/source");
        const compiler = try e.absolute(run ++ "/z_llvm");
        try e.write(report, .{ .status = "passed", .source_root = source, .compiler = compiler, .compiler_sha256 = try e.digest(compiler), .source_sha256 = .{ .@"main.zig" = try e.digest("local-state/validations/test/source/main.zig") }, .zig = try e.absolute("toolchain/zig"), .zig_sha256 = try e.digest("toolchain/zig"), .commands = .{.{ .actual_returncode = 0, .outcome = "completed", .argv = [_][]const u8{ "zig", "build-exe", "--cache-dir", try e.absolute(cache), try e.c.fmt("-Mroot={s}/main.zig", .{source}), try e.c.fmt("-femit-bin={s}", .{compiler}) }, .stdout = try e.absolute(run ++ "/build.stdout"), .stderr = try e.absolute(run ++ "/build.stderr") }} });
    }
    fn canonical(f: *Fixture, e: *core.Engine) !void {
        try f.build(e);
        try f.tmp.dir.createDirPath(t.io, run ++ "/bin");
        try f.tmp.dir.createDirPath(t.io, "toolchain/lib");
        try f.write(run ++ "/bin/z_llvm", "\x7fELFsynthetic-compiler");
        try f.write("toolchain/lib/std.zig", "pub const example = 1;");
        _ = try f.c.capture(&.{ "git", "init", "-q" });
        _ = try f.c.capture(&.{ "git", "add", "--", "local-state/validations/test/source/main.zig" });
        _ = try f.c.capture(&.{ "git", "-c", "user.name=Storage Test", "-c", "user.email=storage@example.invalid", "-c", "commit.gpgsign=false", "commit", "-qm", "source fixture" });
        const argv = [_][]const u8{ try e.absolute("toolchain/zig"), "build", "--prefix", try e.absolute(run) };
        const command = .{ .argv = argv, .actual_returncode = 0, .outcome = "completed", .stdout = try e.absolute(run ++ "/build.stdout"), .stderr = try e.absolute(run ++ "/build.stderr") };
        try e.write(report, .{
            .schema = "zllvm-compiler-build-v1",
            .compiler = try e.absolute(run ++ "/bin/z_llvm"),
            .compiler_sha256 = try e.digest(run ++ "/bin/z_llvm"),
            .source_head = u.trim(try f.c.capture(&.{ "git", "rev-parse", "HEAD" })),
            .source_sha256 = .{ .@"local-state/validations/test/source/main.zig" = try e.digest("local-state/validations/test/source/main.zig") },
            .argv = argv,
            .command = command,
            .zig = .{ .path = argv[0], .sha256 = try e.digest("toolchain/zig"), .library = try @import("../validation/toolchain.zig").libraryIdentity(&f.c, try e.absolute("toolchain/lib")) },
        });
    }
    fn privateCache(f: *Fixture, e: *core.Engine, legacy: bool, code: i64, env_args: bool) !p.Release {
        try f.tmp.dir.createDirPath(t.io, run ++ "/evidence/zig-local-Debug-v1/o");
        try f.tmp.dir.createDirPath(t.io, run ++ "/src");
        try f.write(run ++ "/.zigversion", "0.17.0\n");
        try f.write(run ++ "/src/main.zig", "unique original source remains");
        try f.write(run ++ "/evidence/zig-local-Debug-v1/o/test", "temporary test binary");
        try f.write(run ++ "/evidence/unit.log", "complete diagnostics remain");
        const args: []const []const u8 = if (env_args) &.{ "env", "ZIG_LOCAL_CACHE_DIR=evidence/zig-local-Debug-v1", "zig", "build", "test" } else &.{ "zig", "test", "--cache-dir", "evidence/zig-local-Debug-v1", "src/tests.zig" };
        try e.write(run ++ "/evidence/unit.json", .{ .argv = args, .cwd = if (legacy) null else try e.absolute(run), .status = "finished", .outcome = if (code < 0) "canceled" else "completed", .actual_returncode = code, .started_ns = 1, .finished_ns = 2, .log = try e.absolute(run ++ "/evidence/unit.log") });
        return (try private_cache.request(e, .{ .producer = run ++ "/evidence/unit.json", .run_root = run, .working_directory = run, .legacy_working_directory_review = if (legacy) "Reviewed copied project markers, run log and matching private cache arguments" else null }, "Closed temporary native-test cache")).?;
    }
    fn retireCompiler(f: *Fixture, build_report: []const u8) !p.Evidence {
        const retirement_output = "local-state/retirements/automatic-storage-cleanup/fixture";
        try f.tmp.dir.createDirPath(t.io, retirement_output);
        var prepare = f.engine();
        const request = try releases.disposableBuild(&prepare, build_report, "Completed temporary compiler");
        const request_path = try f.c.fmt("{s}/request.json", .{retirement_output});
        try prepare.write(request_path, request);
        var deletion = f.engine();
        deletion.output = retirement_output;
        try deletion.discoverRelease(request_path, true);
        try deletion.qualify(0);
        try mutation.apply(&deletion, 0);
        const path = retirement_output ++ "/record-0.json";
        return .{ .path = path, .sha256 = try deletion.digest(path) };
    }
    fn retiredTrace(f: *Fixture) !p.Evidence {
        var initial = f.engine();
        _ = try f.release(&initial, .raw_trace, true, true, false);
        const receipt = try f.retireCompiler(report);
        var parsed = try initial.load(f.c.a, released ++ "/storage-release.json");
        const record = (try std.json.parseFromValue(p.Release, f.c.a, parsed.value, .{})).value;
        var replacement = record;
        replacement.state = .audited;
        replacement.successor = null;
        replacement.compiler_retirement = receipt;
        var rows: std.ArrayList(p.Retained) = .empty;
        for (record.retained) |row| if (row.role != .compiler) try rows.append(f.c.a, row);
        replacement.retained = rows.items;
        try initial.write(released ++ "/storage-release.json", replacement);
        parsed.deinit();
        return receipt;
    }
    fn release(f: *Fixture, e: *core.Engine, kind: @FieldType(p.Artifact, "kind"), complete: bool, successor_passed: bool, failed_without_diagnostic: bool) !usize {
        try f.build(e);
        try f.tmp.dir.createDirPath(t.io, released);
        const path = try e.c.fmt("{s}/{s}", .{ released, switch (kind) {
            .log => "old.log",
            .raw_trace => "profile.events.jsonl",
            .build_output => "result.o",
            .generated_assembly => "linked-harness.s",
            .private_cache => unreachable,
        } });
        try f.write(path, if (kind == .build_output and complete) "\x7fELFsynthetic-object" else "original payload");
        try f.write(released ++ "/input.ll", "original input");
        try e.write(released ++ "/producer.json", .{ .status = if (failed_without_diagnostic) "finished" else "passed", .actual_returncode = if (failed_without_diagnostic) @as(i32, 1) else 0 });
        try e.write(released ++ "/successor.json", .{ .status = if (successor_passed) "passed" else "failed" });
        try e.write(released ++ "/top.json", .{ .backend = .{ .path = try e.absolute(run ++ "/z_llvm"), .sha256 = try e.digest(run ++ "/z_llvm") } });
        try e.write(released ++ "/backend.json", .{ .status = "passed" });
        var rows: std.ArrayList(p.Retained) = .empty;
        for ([_]struct { path: []const u8, role: @FieldType(p.Retained, "role") }{
            .{ .path = "local-state/validations/test/source/main.zig", .role = .source },
            .{ .path = released ++ "/input.ll", .role = .input },
            .{ .path = report, .role = .build },
            .{ .path = released ++ "/producer.json", .role = .result },
            .{ .path = released ++ "/top.json", .role = .other },
            .{ .path = released ++ "/backend.json", .role = .other },
            .{ .path = run ++ "/z_llvm", .role = .compiler },
        }) |r| try rows.append(f.c.a, .{ .path = r.path, .role = r.role, .sha256 = try e.digest(r.path) });
        if (kind == .raw_trace) {
            try e.write(released ++ "/audit.json", .{
                .schema = "zllvm-native-event-audit-v1",
                .status = "verified",
                .path = path,
                .sha256 = try e.digest(path),
                .whole_stream_read = true,
                .whole_stream_semantically_valid = true,
                .report_binding_verified = true,
                .complete = complete,
                .stream_metadata_unchanged = true,
                .recorded_hash_matches = true,
                .producer = .{ .path = released ++ "/producer.json", .sha256 = try e.digest(released ++ "/producer.json") },
                .top_report = .{ .path = released ++ "/top.json", .sha256 = try e.digest(released ++ "/top.json") },
                .backend_report = .{ .path = released ++ "/backend.json", .sha256 = try e.digest(released ++ "/backend.json") },
                .input = .{ .path = try e.absolute(released ++ "/input.ll"), .sha256 = try e.digest(released ++ "/input.ll") },
                .core_source = "local-state/validations/test/source/main.zig",
                .core_sha256 = try e.digest("local-state/validations/test/source/main.zig"),
                .driver_source = "local-state/validations/test/source/main.zig",
                .driver_sha256 = try e.digest("local-state/validations/test/source/main.zig"),
            });
            try rows.append(f.c.a, .{ .path = released ++ "/audit.json", .role = .audit, .sha256 = try e.digest(released ++ "/audit.json") });
        }
        try e.write(released ++ "/storage-release.json", p.Release{ .schema = "zllvm-storage-release-v1", .state = .superseded, .run_root = released, .reason = "Synthetic accepted successor", .producer = .{ .path = released ++ "/producer.json", .sha256 = try e.digest(released ++ "/producer.json") }, .successor = .{ .path = released ++ "/successor.json", .sha256 = try e.digest(released ++ "/successor.json") }, .retained = rows.items, .artifacts = &.{.{ .path = path, .sha256 = try e.digest(path), .kind = kind, .audit = if (kind == .raw_trace) released ++ "/audit.json" else null }} });
        try e.discover();
        for (e.actions.items, 0..) |a, index| if (std.mem.eql(u8, path, a.path)) return index;
        return error.MissingTestCandidate;
    }
};

test "storage cleanup: audited trace accepts exact guarded compiler retirement and preserves replay evidence" {
    const f = try Fixture.init();
    defer f.deinit();
    const receipt = try f.retiredTrace();
    var e = f.engine();
    try e.discoverRelease(released ++ "/storage-release.json", true);
    try e.qualify(0);
    try t.expect(e.actions.items[0].retired_compiler != null);
    try t.expect(e.actions.items[0].replay_required);
    try mutation.apply(&e, 0);
    try t.expectError(error.FileNotFound, e.metadata(released ++ "/profile.events.jsonl"));
    try t.expectError(error.FileNotFound, e.metadata(run ++ "/z_llvm"));
    _ = try e.metadata("local-state/validations/test/source/main.zig");
    _ = try e.metadata(released ++ "/input.ll");
    _ = try e.metadata(released ++ "/audit.json");
    _ = try e.metadata(receipt.path);
    var retained: std.ArrayList(core.Evidence) = .empty;
    // A proof is local to its audited release, never a global missing-file waiver.
    try t.expectError(error.FileNotFound, e.buildEvidence(report, &retained, null, &.{}));
}

test "storage cleanup: incomplete or unrelated compiler retirement cannot replace original bytes" {
    for (0..5) |case| {
        const f = try Fixture.init();
        defer f.deinit();
        const original = try f.retiredTrace();
        var edit = f.engine();
        var parsed = try edit.load(f.c.a, original.path);
        switch (case) {
            0 => try u.put(f.c.a, &parsed.value, "status", u.s("pending")),
            1 => try u.put(f.c.a, parsed.value.object.getPtr("action").?, "status", u.s("ready")),
            2 => try u.put(f.c.a, parsed.value.object.getPtr("action").?, "sha256", u.s("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")),
            3 => try u.put(f.c.a, parsed.value.object.getPtr("action").?, "reclaimed_file_bytes", u.n(0)),
            4 => try u.put(f.c.a, &parsed.value, "retained", u.array(f.c.a)),
            else => unreachable,
        }
        try edit.write(original.path, parsed.value);
        var e = f.engine();
        var retained: std.ArrayList(core.Evidence) = .empty;
        const receipt: p.Evidence = .{ .path = original.path, .sha256 = try e.digest(original.path) };
        const result = retired_compiler.verify(&e, receipt, &retained);
        if (result) |_| return error.InvalidRetirementWasAccepted else |_| {}
        _ = try e.metadata(released ++ "/profile.events.jsonl");
    }
}

test "storage cleanup: retired compiler proof requires unchanged owner request and build receipt" {
    for ([_][]const u8{ report, "local-state/retirements/automatic-storage-cleanup/fixture/request.json" }) |path| {
        const f = try Fixture.init();
        defer f.deinit();
        const receipt = try f.retiredTrace();
        try f.write(path, "{\"status\":\"passed\"}\n");
        var e = f.engine();
        var retained: std.ArrayList(core.Evidence) = .empty;
        try t.expectError(error.EvidenceHashMismatch, retired_compiler.verify(&e, receipt, &retained));
    }
}

test "storage cleanup: retired compiler proof is bound to one build and only audited trace releases" {
    const f = try Fixture.init();
    defer f.deinit();
    const receipt = try f.retiredTrace();
    var initial = f.engine();
    var retained: std.ArrayList(core.Evidence) = .empty;
    const proof = try retired_compiler.verify(&initial, receipt, &retained);
    try t.expectError(error.RetiredCompilerBuildMismatch, retired_compiler.bind(&initial, proof, "different-build.json", proof.compiler.path, proof.compiler.sha256));
    var parsed = try initial.load(f.c.a, released ++ "/storage-release.json");
    try u.put(f.c.a, &parsed.value, "state", u.s("superseded"));
    try initial.write(released ++ "/storage-release.json", parsed.value);
    var e = f.engine();
    try e.discoverRelease(released ++ "/storage-release.json", true);
    try t.expectError(error.RetiredCompilerOnlyAuditedTrace, e.qualify(0));
    parsed.deinit();
}

test "storage cleanup: retired compiler and proof records are rechecked before trace mutation" {
    for ([_]bool{ false, true }) |compiler_reappears| {
        const f = try Fixture.init();
        defer f.deinit();
        const receipt = try f.retiredTrace();
        var e = f.engine();
        try e.discoverRelease(released ++ "/storage-release.json", true);
        try e.qualify(0);
        if (compiler_reappears) try f.write(run ++ "/z_llvm", "replacement executable") else try f.write(receipt.path, "{\"status\":\"complete\"}");
        const result = mutation.apply(&e, 0);
        if (result) |_| return error.ChangedRetirementWasAccepted else |_| {}
        _ = try e.metadata(released ++ "/profile.events.jsonl");
        try t.expectError(error.FileNotFound, e.metadata(mutation.pending_path));
    }
}

test "storage cleanup: retired compiler identity does not excuse changed source or incomplete audit" {
    for ([_]bool{ false, true }) |source_changed| {
        const f = try Fixture.init();
        defer f.deinit();
        _ = try f.retiredTrace();
        if (source_changed) try f.write("local-state/validations/test/source/main.zig", "changed source") else try f.write(released ++ "/audit.json", "{\"status\":\"verified\",\"complete\":false}");
        var e = f.engine();
        try e.discoverRelease(released ++ "/storage-release.json", true);
        const result = e.qualify(0);
        if (result) |_| return error.InvalidReplayWasAccepted else |_| {}
    }
}

test "storage cleanup: canonical build sources still qualify after verified compiler retirement" {
    const f = try Fixture.init();
    defer f.deinit();
    var initial = f.engine();
    try f.canonical(&initial);
    const receipt = try f.retireCompiler(report);
    var e = f.engine();
    var retained: std.ArrayList(core.Evidence) = .empty;
    const proof = try retired_compiler.verify(&e, receipt, &retained);
    var parsed = try e.load(f.c.a, report);
    try @import("historical.zig").canonicalWithRetirement(&e, report, parsed.value, &retained, null, &.{}, proof);
    try t.expectEqual(@as(usize, 1), e.revisions.items.len);
    try f.write("toolchain/lib/std.zig", "changed toolchain");
    try t.expectError(error.ToolchainLibraryChanged, @import("historical.zig").verifyLibraries(&e));
    parsed.deinit();
}

test "storage cleanup: trace preparation owns its audit data and binds retirement proof" {
    const f = try Fixture.init();
    defer f.deinit();
    const receipt = try f.retiredTrace();
    var e = f.engine();
    try e.write("trace-plan.json", .{ .schema = "zllvm-trace-retirement-plan-v1", .traces = [_]batches.TraceEntry{.{ .audit = released ++ "/audit.json", .build = report, .compiler_retirement = receipt.path }} });
    try batches.traces(&e, "trace-plan.json", "Complete audit and retired original identity");
    var fresh = f.engine();
    try batches.discover(&fresh, output ++ "/requests.json");
    try fresh.qualify(0);
    try t.expect(fresh.actions.items[0].retired_compiler != null);
    _ = try fresh.metadata(released ++ "/profile.events.jsonl");
}

test "storage cleanup: canonical receipt reconstructs sources from Git after checkout changes" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try f.canonical(&e);
    try f.write("local-state/validations/test/source/main.zig", "different current checkout");
    var retained: std.ArrayList(core.Evidence) = .empty;
    try e.buildEvidence(report, &retained, run ++ "/bin/z_llvm", &.{});
    try t.expectEqual(@as(usize, 1), e.revisions.items.len);
    try e.pinRevisions();
    try e.verifyRevisions();
    for (retained.items) |ev| {
        try t.expect(!std.mem.eql(u8, ev.path, run ++ "/bin/z_llvm"));
        try e.check(ev);
    }
    try f.write("toolchain/lib/std.zig", "changed toolchain");
    try t.expectError(error.ToolchainLibraryChanged, @import("historical.zig").verifyLibraries(&e));
}

test "storage cleanup: historical reconstruction checks saved overrides instead of trusting verified flags" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try f.canonical(&e);
    const original = try f.c.load(try e.absolute(report));
    var modified = original;
    try f.write(output ++ "/override.zig", "historical uncommitted source");
    const sha = try e.digest(output ++ "/override.zig");
    var hashes = try core.get(modified, "source_sha256");
    try hashes.object.put(f.c.a, "local-state/validations/test/source/main.zig", u.s(sha));
    try modified.object.put(f.c.a, "source_sha256", hashes);
    try e.write(report, modified);
    try e.write(output ++ "/reconstruction.json", .{ .sources = .{.{ .sha256 = sha, .saved = output ++ "/override.zig", .verified = true }} });
    var fresh = f.engine();
    var retained: std.ArrayList(core.Evidence) = .empty;
    try t.expectError(error.SourceReconstructionMissing, fresh.buildEvidence(report, &retained, null, &.{}));
    const ledger = core.Evidence{ .path = output ++ "/reconstruction.json", .sha256 = try fresh.digest(output ++ "/reconstruction.json") };
    try fresh.buildEvidence(report, &retained, null, &.{ledger});
    try f.write(output ++ "/override.zig", "wrong bytes");
    var changed = f.engine();
    try t.expectError(error.EvidenceHashMismatch, changed.buildEvidence(report, &retained, null, &.{ledger}));
}

test "storage cleanup: canonical receipts reject failed or redirected commands" {
    for ([_]bool{ false, true }) |failed| {
        const f = try Fixture.init();
        defer f.deinit();
        var e = f.engine();
        try f.canonical(&e);
        var value = try f.c.load(try e.absolute(report));
        var command = try core.get(value, "command");
        if (failed) {
            try command.object.put(f.c.a, "actual_returncode", .{ .integer = 1 });
        } else {
            var argv = try core.get(command, "argv");
            argv.array.items[3] = u.s("local-state/validations/test/wrong");
            try value.object.put(f.c.a, "argv", argv);
            try command.object.put(f.c.a, "argv", argv);
        }
        try value.object.put(f.c.a, "command", command);
        try e.write(report, value);
        var fresh = f.engine();
        var retained: std.ArrayList(core.Evidence) = .empty;
        try t.expectError(if (failed) error.IncompleteBuildCommand else error.SourceCompilerCommandNotBound, fresh.buildEvidence(report, &retained, null, &.{}));
    }
}

fn transitionFixture(f: *Fixture, e: *core.Engine, extra_manifest: bool, current: bool, wrong_hash: bool) !core.Engine {
    const index = try f.release(e, .build_output, true, true, false);
    const artifact = e.actions.items[index];
    const manifest = "local-state/retirements/historical.sha256";
    try f.write(manifest, try e.c.fmt("{s}  {s}\n{s}  {s}/o/object\n", .{ artifact.sha256.?, artifact.path, try e.digest(cache ++ "/o/object"), cache }));
    const value = try f.c.load(try e.absolute(released ++ "/storage-release.json"));
    var parsed = try std.json.parseFromValue(p.Release, f.c.a, value, .{});
    parsed.value.retired_pins = &.{.{ .manifest = .{ .path = manifest, .sha256 = try e.digest(manifest) }, .reference = artifact.path, .target = .{ .path = artifact.path, .sha256 = if (wrong_hash) "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" else artifact.sha256.? }, .reason = "Verified accepted successor replaces this output" }};
    try e.write(released ++ "/storage-release.json", parsed.value);
    if (extra_manifest) try f.write("local-state/retirements/new-pin.sha256", try e.c.fmt("{s}  {s}\n", .{ artifact.sha256.?, artifact.path }));
    var fresh = f.engine();
    if (current) fresh.config.current_manifests = &.{manifest};
    try fresh.discover();
    return fresh;
}

test "storage cleanup: pin transition exempts only its exact file and manifest" {
    for ([_]bool{ false, true }) |extra| {
        const f = try Fixture.init();
        defer f.deinit();
        var original = f.engine();
        var e = try transitionFixture(f, &original, extra, false, false);
        for (e.actions.items, 0..) |_, i| try e.qualify(i);
        try e.pins();
        for (e.actions.items) |action| {
            if (action.kind == .cache) try t.expectEqual(.skipped, action.status) else try t.expectEqual(@as(@FieldType(core.Action, "status"), if (extra) .skipped else .ready), action.status);
        }
        // Reusing parsed manifests must make the identical decision.
        try e.pins();
    }
}

test "storage cleanup: current manifests outside discovery globs still pin retired historical targets" {
    const f = try Fixture.init();
    defer f.deinit();
    var original = f.engine();
    var e = try transitionFixture(f, &original, false, false, false);
    for (e.actions.items, 0..) |action, i| {
        try e.qualify(i);
        if (action.kind == .build_output) try f.write("current-inputs", try e.c.fmt("{s}  {s}\n", .{ action.sha256.?, action.path }));
    }
    e.config.current_manifests = &.{"current-inputs"};
    try e.pins();
    for (e.actions.items) |action| if (action.kind == .build_output) try t.expectEqual(.skipped, action.status);
}

test "storage cleanup: pin transitions reject current manifests, wrong hashes and changed seals" {
    for (0..3) |case| {
        const f = try Fixture.init();
        defer f.deinit();
        var original = f.engine();
        var e = try transitionFixture(f, &original, false, case == 0, case == 1);
        if (case == 2) try f.write("local-state/retirements/historical.sha256", "changed manifest\n");
        for (e.actions.items, 0..) |action, i| if (action.kind == .build_output) {
            try t.expectError(switch (case) {
                0 => error.CurrentManifestCannotBeRetired,
                1 => error.PinTransitionNotAnArtifact,
                else => error.EvidenceHashMismatch,
            }, e.qualify(i));
        };
    }
}

test "storage cleanup: staged historical requests verify hashes and retire only reviewed completed-record pins" {
    const f = try Fixture.init();
    defer f.deinit();
    var initial = f.engine();
    const index = try f.release(&initial, .build_output, true, true, false);
    const artifact = initial.actions.items[index];
    const request_path = output ++ "/original-request.json";
    const original_release = try f.c.load(try initial.absolute(released ++ "/storage-release.json"));
    try initial.write(request_path, original_release);
    try f.tmp.dir.deleteFile(t.io, released ++ "/storage-release.json");
    try initial.write(output ++ "/requests.json", .{ .schema = "zllvm-storage-requests-v1", .requests = .{.{ .path = request_path, .sha256 = try initial.digest(request_path) }} });
    try initial.write("local-state/retirements/record-old.json", .{ .status = "complete", .retained = .{.{ .path = artifact.path, .sha256 = artifact.sha256.? }} });
    try f.write(run ++ "/milestone.sha256", try f.c.fmt("{s}  {s}\n", .{ artifact.sha256.?, artifact.path }));
    var files = u.object(f.c.a);
    try u.put(f.c.a, &files, std.fs.path.basename(artifact.path), try u.toValue(f.c.a, .{ .bytes = artifact.allocated_bytes, .sha256 = artifact.sha256.? }));
    const inventory_manifest = run ++ "/artifact-manifest.json";
    try initial.write(inventory_manifest, .{ .root = std.fs.path.dirname(artifact.path).?, .files = files });
    try initial.write(output ++ "/manifest-review.json", .{ .schema = "zllvm-reviewed-pin-manifests-v1", .reason = "Reviewed completed milestone's temporary output", .manifests = .{
        .{ .path = run ++ "/milestone.sha256", .sha256 = try initial.digest(run ++ "/milestone.sha256") },
        .{ .path = inventory_manifest, .sha256 = try initial.digest(inventory_manifest) },
    } });
    var review = f.engine();
    try review.discover();
    try batches.discover(&review, output ++ "/requests.json");
    for (review.actions.items, 0..) |_, i| try review.qualify(i);
    try review.pins();
    try review.write(output ++ "/review.json", .{ .status = "complete", .mode = "review", .controls = review.controls.items, .actions = review.actions.items });
    try review.write(output ++ "/pin-references.json", review.pin_references.items);
    try f.tmp.dir.createDirPath(t.io, output ++ "/prepared");
    var prepare = f.engine();
    prepare.output = output ++ "/prepared";
    try batches.reviewedPins(&prepare, output ++ "/requests.json", output ++ "/review.json", output ++ "/manifest-review.json");
    try f.tmp.dir.createDirPath(t.io, output ++ "/apply");
    var apply = f.engine();
    apply.output = output ++ "/apply";
    try batches.discover(&apply, output ++ "/prepared/requests.json");
    try t.expectEqual(@as(usize, 1), apply.actions.items.len);
    try apply.qualify(0);
    try apply.pins();
    try t.expectEqual(.ready, apply.actions.items[0].status);
    try mutation.apply(&apply, 0);
    try t.expectError(error.FileNotFound, apply.metadata(artifact.path));
    _ = try apply.metadata("local-state/retirements/record-old.json");
    _ = try apply.metadata(cache ++ "/o/object");
    try f.write(request_path, "changed request");
    var changed = f.engine();
    try t.expectError(error.EvidenceHashMismatch, batches.discover(&changed, output ++ "/requests.json"));
}

test "storage cleanup: reviewed milestone adapter cannot exempt a current manifest" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try f.write(run ++ "/current.sha256", "current contract\n");
    e.config.current_manifests = &.{run ++ "/current.sha256"};
    try e.write(output ++ "/manifest-review.json", .{ .schema = "zllvm-reviewed-pin-manifests-v1", .reason = "Rejected current exemption", .manifests = .{.{ .path = run ++ "/current.sha256", .sha256 = try e.digest(run ++ "/current.sha256") }} });
    try t.expectError(error.CurrentManifestCannotBeRetired, batches.reviewedPins(&e, "unused-requests.json", "unused-review.json", output ++ "/manifest-review.json"));
}

test "storage cleanup: failed release qualification still protects its declared dependencies" {
    const f = try Fixture.init();
    defer f.deinit();
    var initial = f.engine();
    _ = try f.release(&initial, .build_output, true, false, false);
    var value = try f.c.load(try initial.absolute(released ++ "/storage-release.json"));
    var retained = try core.get(value, "retained");
    try retained.array.append(try u.toValue(f.c.a, p.Retained{ .path = cache ++ "/o/object", .sha256 = try initial.digest(cache ++ "/o/object"), .role = .other }));
    try value.object.put(f.c.a, "retained", retained);
    try initial.write(released ++ "/storage-release.json", value);
    var e = f.engine();
    try e.discover();
    for (e.actions.items, 0..) |action, i| {
        if (action.kind == .cache) try e.qualify(i) else try t.expectError(error.NoAcceptedSuccessor, e.qualify(i));
    }
    try e.protectRetained();
    for (e.actions.items) |action| if (action.kind == .cache) try t.expectEqual(.skipped, action.status);
}

test "storage cleanup: producer compiler release preserves canonical rebuild evidence and accepted successor" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try f.canonical(&e);
    try e.write(output ++ "/successor.json", .{ .status = "passed" });
    const destination = try releases.compilerBuild(&e, report, output ++ "/successor.json", "New accepted compiler", &.{});
    try t.expectEqualStrings(run ++ "/storage-release.json", destination);
    var apply = f.engine();
    try apply.discover();
    try t.expectEqual(@as(usize, 1), apply.actions.items.len);
    try apply.qualify(0);
    try apply.pinRevisions();
    try mutation.apply(&apply, 0);
    try t.expectError(error.FileNotFound, apply.metadata(run ++ "/bin/z_llvm"));
    _ = try apply.metadata(report);
    _ = try apply.metadata(output ++ "/successor.json");
    _ = try apply.metadata("toolchain/lib/std.zig");
}

test "storage cleanup: inventory counts hardlinks once and respects a required alias" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try f.write(run ++ "/required", "one allocation with two names");
    _ = try f.c.capture(&.{ "ln", try e.absolute(run ++ "/required"), try e.absolute(output ++ "/alias") });
    try e.held.append(f.c.a, run ++ "/required");
    try @import("inventory.zig").write(&e);
    const result = try f.c.load(try e.absolute(output ++ "/inventory.json"));
    try t.expectEqual((try e.metadata(run ++ "/required")).allocated_bytes, @as(u64, @intCast(try core.integer(result, "required_by_current_contract_bytes"))));
    try t.expectEqual(@as(i64, 0), try core.integer(result, "eligible_bytes"));
}

test "storage cleanup: own release command is not a consumer but other processes remain protected" {
    const own = "    PID COMMAND\n  123 clean-storage release-build --build " ++ report ++ "\n";
    try t.expect(!core.commandUsesRun(own, run, 123));
    try t.expect(core.commandUsesRun(own ++ "  124 reader " ++ run ++ "/z_llvm\n", run, 123));
    try t.expect(core.commandUsesRun(own ++ "  122 parent-job " ++ report ++ "\n", run, 123));
}

test "storage cleanup: disposable compiler needs no source, toolchain or successor reconstruction" {
    const f = try Fixture.init();
    defer f.deinit();
    var initial = f.engine();
    try f.canonical(&initial);
    try f.tmp.dir.deleteFile(t.io, "local-state/validations/test/source/main.zig");
    try f.tmp.dir.deleteFile(t.io, "toolchain/zig");
    var e = f.engine();
    const request = try releases.disposableBuild(&e, report, "User classifies this closed compiler as temporary");
    _ = try releases.publish(&e, request);
    try t.expectEqual(@as(usize, 0), e.revisions.items.len);
    try t.expectEqual(@as(usize, 0), e.libraries.items.len);
    var apply = f.engine();
    try apply.discover();
    try apply.qualify(0);
    try mutation.apply(&apply, 0);
    try t.expectError(error.FileNotFound, apply.metadata(run ++ "/bin/z_llvm"));
    _ = try apply.metadata(report);
}

test "storage cleanup: disposable outputs require closed producer and never include raw traces or logs" {
    for (0..4) |case| {
        const f = try Fixture.init();
        defer f.deinit();
        var initial = f.engine();
        const kind: @FieldType(p.Artifact, "kind") = if (case == 2) .raw_trace else if (case == 3) .log else .build_output;
        _ = try f.release(&initial, kind, true, false, true);
        if (case == 1) try initial.write(released ++ "/producer.json", .{ .status = "running" });
        var value = try f.c.load(try initial.absolute(released ++ "/storage-release.json"));
        var parsed = try std.json.parseFromValue(p.Release, f.c.a, value, .{});
        parsed.value.state = .disposable;
        parsed.value.retained = &.{};
        parsed.value.successor = null;
        var hash = f.engine();
        parsed.value.producer.sha256 = try hash.digest(released ++ "/producer.json");
        try initial.write(released ++ "/storage-release.json", parsed.value);
        var e = f.engine();
        try e.discover();
        for (e.actions.items, 0..) |action, index| if (action.kind != .cache) {
            if (case == 0) try e.qualify(index) else try t.expectError(if (case == 1) error.ProducerNotTerminal else error.DisposableOnlyBuildOutputs, e.qualify(index));
        };
        // Keep this parsed input live through publication above.
        _ = &value;
    }
}

test "storage cleanup: disposable compiler still obeys current pins" {
    const f = try Fixture.init();
    defer f.deinit();
    var initial = f.engine();
    try f.canonical(&initial);
    const request = try releases.disposableBuild(&initial, report, "Temporary build");
    try initial.write(run ++ "/storage-release.json", request);
    try f.write("current-inputs", try initial.c.fmt("{s}  {s}\n", .{ request.artifacts[0].sha256, request.artifacts[0].path }));
    var e = f.engine();
    e.config.current_manifests = &.{"current-inputs"};
    try e.discover();
    try e.qualify(0);
    try e.pins();
    try t.expectEqual(.skipped, e.actions.items[0].status);
}

test "storage cleanup: disposable output does not depend on another action's replay environment" {
    const f = try Fixture.init();
    defer f.deinit();
    var initial = f.engine();
    try f.canonical(&initial);
    try initial.write(run ++ "/storage-release.json", try releases.disposableBuild(&initial, report, "Temporary build"));
    var e = f.engine();
    try e.discover();
    try e.qualify(0);
    try t.expect(!e.actions.items[0].replay_required);
    // Another, already completed trace action may have registered this replay
    // environment. It must not become a prerequisite for ordinary disposal.
    try e.libraries.append(f.c.a, .{ .path = "missing-other-toolchain", .sha256 = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", .files = 1 });
    try e.revisions.append(f.c.a, .{ .commit = "missing-other-commit", .tree = "missing-other-tree", .reference = "refs/retirements/missing-other" });
    try e.verifyEvidence(e.actions.items[0]);
    try mutation.apply(&e, 0);
    try t.expectError(error.FileNotFound, e.metadata(run ++ "/bin/z_llvm"));
}

test "storage cleanup: completed private caches may be disposable without old source or compiler" {
    const f = try Fixture.init();
    defer f.deinit();
    var initial = f.engine();
    try f.build(&initial);
    try f.tmp.dir.deleteFile(t.io, "local-state/validations/test/source/main.zig");
    try f.tmp.dir.deleteFile(t.io, run ++ "/z_llvm");
    var e = f.engine();
    e.config.cache_evidence = .closed_producer;
    try e.discover();
    try e.qualify(0);
    try mutation.apply(&e, 0);
    try t.expectError(error.FileNotFound, e.metadata(cache));
    _ = try e.metadata(report);
}

test "storage cleanup: private test caches preserve diagnostics for passed failed and canceled commands" {
    for ([_]i64{ 0, 1, -15 }) |code| for ([_]bool{ false, true }) |legacy| {
        const f = try Fixture.init();
        defer f.deinit();
        var initial = f.engine();
        const record = try f.privateCache(&initial, legacy, code, legacy);
        try initial.write(run ++ "/storage-release.json", record);
        var e = f.engine();
        try e.discover();
        try t.expectEqual(@as(usize, 1), e.actions.items.len);
        try e.qualify(0);
        try t.expect(e.actions.items[0].released_cache);
        try t.expect(!e.actions.items[0].replay_required);
        try mutation.apply(&e, 0);
        try t.expectError(error.FileNotFound, e.metadata(run ++ "/evidence/zig-local-Debug-v1"));
        _ = try e.metadata(run ++ "/evidence/unit.log");
        _ = try e.metadata(run ++ "/evidence/unit.json");
        _ = try e.metadata(run ++ "/src/main.zig");
    };
}

fn commandCachesFixture(f: *Fixture, e: *core.Engine) !void {
    for ([_][]const u8{ run ++ "/global-cache", run ++ "/Debug/reference-cache" }) |path| {
        try f.tmp.dir.createDirPath(t.io, path);
        try f.write(try e.c.fmt("{s}/object", .{path}), "temporary compiled bytes");
    }
    try f.write(run ++ "/compile.stdout", "");
    try f.write(run ++ "/compile.stderr", "expected negative-case diagnostics\n");
    try e.write(report, .{ .status = "passed", .toolchain = .{ .zig_emitter = .{ .path = "/missing/old-emitter" } } });
    const Command = struct { argv: []const []const u8, outcome: []const u8 = "completed", returncode: i64, actual_returncode: i64, stdout: []const u8, stderr: []const u8 };
    const argv = [_][]const u8{ "/missing/old-emitter", "build-obj", "--cache-dir", try e.absolute(run ++ "/Debug/reference-cache"), "--global-cache-dir", try e.absolute(run ++ "/global-cache") };
    try e.write(run ++ "/commands.json", [_]Command{
        .{ .argv = &argv, .returncode = 0, .actual_returncode = 0, .stdout = try e.absolute(run ++ "/compile.stdout"), .stderr = try e.absolute(run ++ "/compile.stderr") },
        .{ .argv = &argv, .returncode = 1, .actual_returncode = 1, .stdout = try e.absolute(run ++ "/compile.stdout"), .stderr = try e.absolute(run ++ "/compile.stderr") },
    });
}

test "storage cleanup: command ledgers release private mode caches and preserve negative-case evidence" {
    const f = try Fixture.init();
    defer f.deinit();
    var initial = f.engine();
    try commandCachesFixture(f, &initial);
    try initial.write(run ++ "/storage-release.json", try command_caches.request(&initial, report, "Completed comparison caches"));
    var e = f.engine();
    try e.discover();
    try t.expectEqual(@as(usize, 2), e.actions.items.len);
    for (0..e.actions.items.len) |i| {
        try e.qualify(i);
        try t.expect(!e.actions.items[i].replay_required);
        try mutation.apply(&e, i);
    }
    try t.expectError(error.FileNotFound, e.metadata(run ++ "/Debug/reference-cache"));
    try t.expectError(error.FileNotFound, e.metadata(run ++ "/global-cache"));
    for ([_][]const u8{ report, run ++ "/commands.json", run ++ "/compile.stdout", run ++ "/compile.stderr" }) |path| _ = try e.metadata(path);
}

test "storage cleanup: cache ledger requires a passed parent and every using command to be closed" {
    for (0..4) |case| {
        const f = try Fixture.init();
        defer f.deinit();
        var initial = f.engine();
        try commandCachesFixture(f, &initial);
        if (case == 0) {
            try initial.write(report, .{ .status = "failed" });
        } else {
            var commands = try initial.load(f.c.a, run ++ "/commands.json");
            const command = &commands.value.array.items[1];
            if (case == 1) try u.put(f.c.a, command, "outcome", u.s("running"));
            if (case == 2) try u.put(f.c.a, command, "actual_returncode", .{ .integer = 2 });
            if (case == 3) command.object.getPtr("argv").?.array.items[0] = u.s("/unknown/script");
            try initial.write(run ++ "/commands.json", commands.value);
        }
        var e = f.engine();
        try t.expectError(switch (case) {
            0 => error.UnboundCommandCacheOwner,
            3 => error.UnsupportedCacheTool,
            else => error.CacheCommandNotClosed,
        }, command_caches.request(&e, report, "Review all cache consumers"));
        _ = try e.metadata(run ++ "/global-cache/object");
    }
}

test "storage cleanup: cache ledger refuses arbitrary locations and diagnostics inside scratch" {
    try t.expect(!command_caches.owned(run, "local-state/caches/global-cache"));
    try t.expect(!command_caches.owned(run, run ++ "/src/reference-cache"));
    try t.expect(!command_caches.owned(run, run ++ "/Debug/source"));
    const f = try Fixture.init();
    defer f.deinit();
    var initial = f.engine();
    try commandCachesFixture(f, &initial);
    var commands = try initial.load(f.c.a, run ++ "/commands.json");
    try u.put(f.c.a, &commands.value.array.items[0], "stderr", u.s(try initial.absolute(run ++ "/global-cache/object")));
    try initial.write(run ++ "/commands.json", commands.value);
    var e = f.engine();
    try t.expectError(error.RetentionOverlap, command_caches.request(&e, report, "Preserve diagnostics"));
}

test "storage cleanup: cache ledger binds commands and diagnostics before mutation" {
    for (0..3) |case| {
        const f = try Fixture.init();
        defer f.deinit();
        var initial = f.engine();
        try commandCachesFixture(f, &initial);
        try initial.write(run ++ "/storage-release.json", try command_caches.request(&initial, report, "Closed caches"));
        if (case == 0) try f.write(run ++ "/commands.json", "[]\n");
        if (case == 1) try f.tmp.dir.deleteFile(t.io, run ++ "/compile.stderr");
        var e = f.engine();
        try e.discover();
        if (case == 0) {
            try t.expectError(error.EvidenceHashMismatch, e.qualify(0));
        } else if (case == 1) {
            try t.expectError(error.MissingDiagnosticRetirement, e.qualify(0));
        } else {
            try e.qualify(0);
            try f.write(run ++ "/compile.stderr", "changed diagnostics");
            if (mutation.apply(&e, 0)) |_| return error.ChangedCacheDiagnosticsAccepted else |_| {}
        }
        _ = try e.metadata(run ++ "/global-cache/object");
        _ = try e.metadata(run ++ "/Debug/reference-cache/object");
    }
}

test "storage cleanup: cache ledger preparation reports rejected owners and preserves current pins" {
    const f = try Fixture.init();
    defer f.deinit();
    var initial = f.engine();
    try commandCachesFixture(f, &initial);
    try f.write("reports.txt", report ++ "\nlocal-state/validations/missing/batch/report.json\n");
    try command_caches.prepare(&initial, "reports.txt", "Reviewed comparison caches");
    var e = f.engine();
    try batches.discover(&e, output ++ "/requests.json");
    try t.expectEqual(@as(usize, 2), e.actions.items.len);
    for (0..e.actions.items.len) |i| try e.qualify(i);
    const member = run ++ "/global-cache/object";
    try f.write("current-cache", try e.c.fmt("{s}  {s}\n", .{ try e.digest(member), member }));
    e.config.current_manifests = &.{"current-cache"};
    try e.pins();
    for (e.actions.items) |action| if (std.mem.eql(u8, action.path, run ++ "/global-cache")) try t.expectEqual(.skipped, action.status);
    var review = try e.load(f.c.a, output ++ "/command-cache-review.json");
    try t.expectEqual(@as(i64, 1), try core.integer(review.value, "prepared"));
    try t.expectEqual(@as(usize, 1), (try core.get(review.value, "rejected")).array.items.len);
    review.deinit();
}

test "storage cleanup: legacy cache cwd requires explicit review and modern cwd must match" {
    const f = try Fixture.init();
    defer f.deinit();
    var initial = f.engine();
    _ = try f.privateCache(&initial, true, 1, false);
    var legacy = f.engine();
    try t.expectError(error.MissingCacheWorkingDirectory, private_cache.request(&legacy, .{ .producer = run ++ "/evidence/unit.json", .run_root = run, .working_directory = run }, "Temporary cache"));
    var modern_setup = f.engine();
    _ = try f.privateCache(&modern_setup, false, 0, false);
    var modern = f.engine();
    try t.expectError(error.CacheWorkingDirectoryMismatch, private_cache.request(&modern, .{ .producer = run ++ "/evidence/unit.json", .run_root = run, .working_directory = run ++ "/different", .legacy_working_directory_review = "Cannot override a recorded cwd" }, "Temporary cache"));
}

test "storage cleanup: copied test project may link source outside its private cache" {
    const f = try Fixture.init();
    defer f.deinit();
    var initial = f.engine();
    const record = try f.privateCache(&initial, true, 1, false);
    try f.tmp.dir.rename(run ++ "/src", f.tmp.dir, run ++ "/original-source", t.io);
    try f.tmp.dir.symLink(t.io, "original-source", run ++ "/src", .{ .is_directory = true });
    try initial.write(run ++ "/storage-release.json", record);
    var e = f.engine();
    try e.discover();
    try e.qualify(0);
    try mutation.apply(&e, 0);
    try t.expectError(error.FileNotFound, e.metadata(run ++ "/evidence/zig-local-Debug-v1"));
    try t.expectEqual(.symlink, (try e.metadata(run ++ "/src")).kind);
    _ = try e.metadata(run ++ "/original-source/main.zig");
    _ = try e.metadata(run ++ "/evidence/unit.log");
}

test "storage cleanup: private caches reject nonterminal producers missing logs and other release states" {
    for (0..3) |case| {
        const f = try Fixture.init();
        defer f.deinit();
        var initial = f.engine();
        var record = try f.privateCache(&initial, false, 1, false);
        if (case == 0) {
            var v = try initial.load(f.c.a, run ++ "/evidence/unit.json");
            try u.put(f.c.a, &v.value, "status", u.s("running"));
            try initial.write(run ++ "/evidence/unit.json", v.value);
            var fresh = f.engine();
            record.producer.sha256 = try fresh.digest(record.producer.path);
        } else if (case == 1) record.retained = &.{} else record.state = .superseded;
        try initial.write(run ++ "/storage-release.json", record);
        var e = f.engine();
        try e.discover();
        try t.expectError(switch (case) {
            0 => error.ProducerNotTerminal,
            1 => error.MissingCacheDiagnostics,
            else => error.PrivateCacheRequiresDisposable,
        }, e.qualify(0));
    }
}

test "storage cleanup: private cache release cannot claim shared source or arbitrary directories" {
    try t.expect(!p.privateCacheOwned(run, run, "local-state/caches/zig-local-cache"));
    try t.expect(!p.privateCacheOwned(run, run, run ++ "/src/zig-local-cache"));
    try t.expect(!p.privateCacheOwned(run, run, run ++ "/evidence/diagnostics"));
    try t.expect(p.privateCacheOwned(run, run, run ++ "/local-state/zig-global-Debug-v1"));
    try t.expect(!p.artifactName(.{ .path = run ++ "/src", .kind = .private_cache }));
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    const invalid = try u.toValue(f.c.a, .{ .argv = [_][]const u8{ "zig", "test", "--cache-dir", "../shared/zig-local-cache" } });
    try t.expectError(error.InvalidPrivateCacheArgument, private_cache.paths(&e, run, run, invalid));
}

test "storage cleanup: current manifest protects a member of a released private cache" {
    const f = try Fixture.init();
    defer f.deinit();
    var initial = f.engine();
    const record = try f.privateCache(&initial, false, 0, false);
    try initial.write(run ++ "/storage-release.json", record);
    const member = run ++ "/evidence/zig-local-Debug-v1/o/test";
    try f.write("current-cache", try initial.c.fmt("{s}  {s}\n", .{ try initial.digest(member), member }));
    var e = f.engine();
    e.config.current_manifests = &.{"current-cache"};
    try e.discover();
    try e.qualify(0);
    try e.pins();
    try t.expectEqual(.skipped, e.actions.items[0].status);
}

test "storage cleanup: cache preparation reports rejected ownership and binds requests" {
    const f = try Fixture.init();
    defer f.deinit();
    var initial = f.engine();
    _ = try f.privateCache(&initial, false, 0, false);
    try initial.write("cache-plan.json", .{ .schema = "zllvm-private-cache-plan-v1", .runs = [_]private_cache.PlanEntry{
        .{ .producer = run ++ "/evidence/unit.json", .run_root = run, .working_directory = run },
        .{ .producer = run ++ "/evidence/unit.json", .run_root = run, .working_directory = run ++ "/wrong" },
    } });
    try batches.caches(&initial, "cache-plan.json", "Reviewed test cache");
    var e = f.engine();
    try batches.discover(&e, output ++ "/requests.json");
    try t.expectEqual(@as(usize, 1), e.actions.items.len);
    try e.qualify(0);
    _ = try e.metadata(run ++ "/evidence/zig-local-Debug-v1/o/test");
    var review = try e.load(f.c.a, output ++ "/cache-plan-review.json");
    try t.expectEqual(@as(i64, 1), try core.integer(review.value, "prepared"));
    try t.expectEqual(@as(usize, 1), (try core.get(review.value, "rejected")).array.items.len);
    review.deinit();
}

test "storage cleanup: parsed control bytes cannot be rebound to changed or replaced files" {
    const f = try Fixture.init();
    defer f.deinit();
    for ([_]bool{ false, true }) |replace| {
        var e = f.engine();
        try f.write(report, "{\"status\":\"passed\"}");
        var parsed = try e.load(t.allocator, report);
        defer parsed.deinit();
        if (replace) {
            try f.write(run ++ "/replacement.json", "{\"status\":\"failed\"}");
            try f.tmp.dir.rename(report, f.tmp.dir, run ++ "/old.json", t.io);
            try f.tmp.dir.rename(run ++ "/replacement.json", f.tmp.dir, report, t.io);
        } else try f.write(report, "{\"status\":\"failed\"}");
        e.hash_cache.clearRetainingCapacity();
        try t.expectError(error.FileChanged, e.addControl(report));
        try t.expectError(error.FileChanged, e.load(t.allocator, report));
    }
}

test "storage cleanup: completed owned cache is deleted as a whole and all replay evidence survives" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try f.build(&e);
    try e.discover();
    try t.expectEqual(@as(usize, 1), e.actions.items.len);
    try e.qualify(0);
    const bytes = e.actions.items[0].allocated_bytes;
    try mutation.apply(&e, 0);
    try t.expectEqual(.removed, e.actions.items[0].status);
    try t.expectEqual(bytes, e.actions.items[0].reclaimed_file_bytes);
    try t.expectError(error.FileNotFound, e.metadata(cache));
    for (e.actions.items[0].retained) |row| try e.check(row);
    try t.expectError(error.FileNotFound, e.metadata(mutation.pending_path));
    var again = f.engine();
    try again.discover();
    try t.expectEqual(@as(usize, 0), again.actions.items.len);
}
test "storage cleanup: changed cache contents or retained source refuse deletion" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try f.build(&e);
    try e.discover();
    try e.qualify(0);
    try f.write(cache ++ "/o/object", "changed cache bytes");
    try t.expectError(error.SnapshotChanged, mutation.apply(&e, 0));
    _ = try e.metadata(cache);
    try t.expectError(error.FileNotFound, e.metadata(mutation.pending_path));
}
test "storage cleanup: source edit invalidates the build evidence before cache admission" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try f.build(&e);
    try e.discover();
    try f.write("local-state/validations/test/source/main.zig", "edited source");
    e.hash_cache.clearRetainingCapacity();
    try t.expectError(error.EvidenceHashMismatch, e.qualify(0));
    _ = try e.metadata(cache);
}
test "storage cleanup: cache with external hardlink is retained" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try f.build(&e);
    try f.tmp.dir.hardLink(cache ++ "/o/object", f.tmp.dir, "alias", t.io, .{});
    try e.discover();
    try t.expectError(error.AliasedCacheFile, e.qualify(0));
    try t.expectEqual(@as(u64, 2), (try e.metadata("alias")).links);
}
test "storage cleanup: cache with symlink is retained without following it" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try f.build(&e);
    try f.tmp.dir.symLink(t.io, "/tmp", cache ++ "/external", .{});
    try e.discover();
    try t.expectError(error.SpecialCacheEntry, e.qualify(0));
}
test "storage cleanup: minimum idle time protects fresh caches" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try f.build(&e);
    e.config.minimum_idle_hours = 24;
    try e.discover();
    try t.expectError(error.TooRecent, e.qualify(0));
}
test "storage cleanup: new cache membership after preparation blocks removal" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try f.build(&e);
    try e.discover();
    try e.qualify(0);
    try f.write(cache ++ "/o/new-file", "new result");
    try t.expectError(error.SnapshotChanged, mutation.apply(&e, 0));
    _ = try e.metadata(cache ++ "/o/new-file");
}
test "storage cleanup: relative manifest pins resolve through ancestor working directories" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try f.build(&e);
    try e.discover();
    try e.pin("zig-local-cache/o/object", run ++ "/hashes.sha256");
    try t.expectEqual(.skipped, e.actions.items[0].status);
}
test "storage cleanup: hold on a parent run protects a completed cache" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try f.build(&e);
    try e.discover();
    try e.write(e.config.holds_file, p.Holds{ .paths = &.{run} });
    try e.loadHolds();
    try t.expectEqual(.skipped, e.actions.items[0].status);
}
test "storage cleanup: new pins are rechecked before deletion" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try f.build(&e);
    try e.discover();
    try e.qualify(0);
    try f.write(run ++ "/new.sha256", try e.c.fmt("{s}  {s}\n", .{ try e.digest(cache ++ "/o/object"), cache ++ "/o/object" }));
    try e.pins();
    try t.expectEqual(.skipped, e.actions.items[0].status);
}
test "storage cleanup: quarantine collision preserves both names" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try f.build(&e);
    try e.discover();
    try e.qualify(0);
    const q = try e.c.fmt(run ++ "/.storage-cleanup-{d}-zig-local-cache", .{std.os.linux.getpid()});
    try f.write(q, "other evidence");
    try t.expectError(error.PathAlreadyExists, mutation.apply(&e, 0));
    _ = try e.metadata(cache);
    _ = try e.metadata(q);
    try t.expectError(error.FileNotFound, e.metadata(mutation.pending_path));
}
test "storage cleanup: real open descriptor blocks a candidate" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try f.build(&e);
    try e.discover();
    const file = try f.tmp.dir.openFile(t.io, cache ++ "/o/object", .{});
    defer file.close(t.io);
    try e.consumers();
    try t.expectEqual(.skipped, e.actions.items[0].status);
}
test "storage cleanup: failed producer does not qualify a cache from a successful child command" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try f.build(&e);
    try e.discover();
    var v = try e.load(t.allocator, report);
    defer v.deinit();
    v.value.object.getPtr("status").?.* = .{ .string = "failed" };
    try e.write(report, v.value);
    e = f.engine();
    try e.discover();
    try t.expectError(error.ProducerNotSuccessful, e.qualify(0));
}
test "storage cleanup: metadata comparison detects changed bytes after a quarantine rename" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try f.build(&e);
    var old = try core.fa.scan(t.allocator, t.io, try e.absolute(cache), .{ .hash_files = true });
    defer old.deinit();
    try f.write(cache ++ "/o/object", "replacement");
    var changed = try core.fa.scan(t.allocator, t.io, try e.absolute(cache), .{ .hash_files = true });
    defer changed.deinit();
    try t.expectError(error.QuarantineChanged, mutation.compareMoved(old.value, changed.value));
}
test "storage cleanup: explicit obsolete log release preserves replay material" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    const index = try f.release(&e, .log, true, true, false);
    try e.qualify(index);
    try mutation.apply(&e, index);
    try t.expectError(error.FileNotFound, e.metadata(released ++ "/old.log"));
    for (e.actions.items[index].retained) |row| try e.check(row);
}
test "storage cleanup: release requires an accepted successor" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    const index = try f.release(&e, .log, true, false, false);
    try t.expectError(error.NoAcceptedSuccessor, e.qualify(index));
}
test "storage cleanup: failed producer requires retained diagnostics" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    const index = try f.release(&e, .log, true, true, true);
    try t.expectError(error.MissingFailureEvidence, e.qualify(index));
}
test "storage cleanup: incomplete trace audit never releases its payload" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    const index = try f.release(&e, .raw_trace, false, true, false);
    try t.expectError(error.IncompleteTraceAudit, e.qualify(index));
}
test "storage cleanup: bound full trace audit permits retirement and restores readonly parent" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    const index = try f.release(&e, .raw_trace, true, true, false);
    try e.qualify(index);
    var parent = try f.tmp.dir.openDir(t.io, released, .{ .iterate = true });
    defer parent.close(t.io);
    try parent.setPermissions(t.io, .fromMode(0o555));
    defer parent.setPermissions(t.io, .fromMode(0o755)) catch {};
    try mutation.apply(&e, index);
    try t.expectEqual(@as(u32, 0o555), (try parent.stat(t.io)).permissions.toMode() & 0o7777);
    try t.expectError(error.FileNotFound, e.metadata(released ++ "/profile.events.jsonl"));
}
test "storage cleanup: released ELF object preserves the compiler" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    const index = try f.release(&e, .build_output, true, true, false);
    try e.qualify(index);
    try t.expectEqual(.ready, e.actions.items[index].status);
    try mutation.apply(&e, index);
    _ = try e.metadata(run ++ "/z_llvm");
}
test "storage cleanup: non-object bytes fail the compiled-output check" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    const index = try f.release(&e, .build_output, false, true, false);
    try t.expectError(error.NotCompiledOutput, e.qualify(index));
}
test "storage cleanup: completed snapshot compaction is lossless and idempotent" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try f.build(&e);
    try e.discover();
    try e.qualify(0);
    const original = e.actions.items[0].snapshot.?;
    try mutation.apply(&e, 0);
    try e.compactSnapshots();
    try t.expectEqualStrings(original.sha256, e.actions.items[0].snapshot_uncompressed_sha256.?);
    try t.expectError(error.FileNotFound, e.metadata(original.path));
    const archived = e.actions.items[0].snapshot.?;
    try e.check(archived);
    var record = try e.load(t.allocator, output ++ "/record-0.json");
    defer record.deinit();
    const recorded_snapshot = try core.get(try core.get(record.value, "action"), "snapshot");
    try t.expectEqualStrings(archived.path, try core.str(recorded_snapshot, "path"));
    try t.expectEqualStrings(archived.sha256, try core.str(recorded_snapshot, "sha256"));
    try e.compactSnapshots();
    try t.expectEqualStrings(archived.path, e.actions.items[0].snapshot.?.path);
}
test "storage cleanup: recorded source commits get durable retention refs" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try f.build(&e);
    try f.c.env.put("GIT_DIR", try e.absolute(".git"));
    try f.c.env.put("GIT_WORK_TREE", f.c.root);
    _ = try f.c.capture(&.{ "git", "-c", "core.hooksPath=/dev/null", "init", "--quiet" });
    _ = try f.c.capture(&.{ "git", "add", "--", "local-state/validations/test/source/main.zig" });
    _ = try f.c.capture(&.{ "git", "-c", "core.hooksPath=/dev/null", "-c", "commit.gpgsign=false", "-c", "user.name=Storage cleanup test", "-c", "user.email=test@example.invalid", "commit", "--quiet", "-m", "Storage cleanup test fixture" });
    const revision = u.trim(try f.c.capture(&.{ "git", "rev-parse", "HEAD" }));
    var v = try e.load(t.allocator, report);
    defer v.deinit();
    try v.value.object.put(v.arena.allocator(), "source_head", .{ .string = revision });
    try e.write(report, v.value);
    e = f.engine();
    try e.discover();
    try e.qualify(0);
    try t.expectEqual(@as(usize, 1), e.revisions.items.len);
    try e.pinRevisions();
    try mutation.apply(&e, 0);
    try e.verifyRevisions();
    try t.expectEqualStrings(revision, e.revisions.items[0].commit);
}
test "storage cleanup: symlink aliases in retention manifests protect their target" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try f.build(&e);
    try e.discover();
    try f.tmp.dir.symLink(t.io, cache ++ "/o/object", "pinned-alias", .{});
    try e.pin("pinned-alias", "docs/manifest.sha256");
    try t.expectEqual(.skipped, e.actions.items[0].status);
}
test "storage cleanup: uppercase and BSD checksums remain retention pins" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try f.build(&e);
    try e.discover();
    const sha = try e.digest(cache ++ "/o/object");
    var upper: [64]u8 = undefined;
    for (sha, 0..) |ch, i| upper[i] = std.ascii.toUpper(ch);
    try f.write(run ++ "/uppercase.sha256", try e.c.fmt("{s}  {s}\n", .{ upper, cache ++ "/o/object" }));
    try e.pins();
    try t.expectEqual(.skipped, e.actions.items[0].status);
    try f.tmp.dir.deleteFile(t.io, run ++ "/uppercase.sha256");
    e = f.engine();
    try e.discover();
    try f.write(run ++ "/bsd.sha256", try e.c.fmt("SHA256 ({s}) = {s}\n", .{ cache ++ "/o/object", sha }));
    try e.pins();
    try t.expectEqual(.skipped, e.actions.items[0].status);
}
test "storage cleanup: unrecognized checksum formats fail closed" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try f.build(&e);
    try e.discover();
    try f.write(run ++ "/unknown.sha256", "unrecognized checksum format\n");
    try t.expectError(error.ValidationFailed, e.pins());
    _ = try e.metadata(cache);
}
test "storage cleanup: a retired manifest exemption is bound to exact bytes" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try f.build(&e);
    try e.discover();
    try f.write(run ++ "/old.sha256", try e.c.fmt("{s}  {s}\n", .{ try e.digest(cache ++ "/o/object"), cache ++ "/o/object" }));
    e.config.retired_manifests = &.{.{ .path = run ++ "/old.sha256", .sha256 = try e.digest(run ++ "/old.sha256") }};
    try e.pins();
    try t.expectEqual(.discovered, e.actions.items[0].status);
    try f.write(run ++ "/old.sha256", "changed\n");
    e.hash_cache.clearRetainingCapacity();
    try t.expectError(error.EvidenceHashMismatch, e.pins());
}
test "storage cleanup: multiple commands may share one completed private cache" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try f.build(&e);
    var v = try e.load(t.allocator, report);
    defer v.deinit();
    const commands = v.value.object.getPtr("commands").?;
    try commands.array.append(commands.array.items[0]);
    try e.write(report, v.value);
    e = f.engine();
    try e.discover();
    try t.expectEqual(@as(usize, 1), e.actions.items.len);
    try e.qualify(0);
    try t.expectEqual(.ready, e.actions.items[0].status);
}

test "storage cleanup: previous numbered retirement records pin retained evidence" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try f.build(&e);
    try e.discover();
    try f.tmp.dir.createDirPath(t.io, "local-state/retirements/previous");
    try e.write("local-state/retirements/previous/record-7.json", .{ .status = "complete", .retained = .{.{ .path = cache ++ "/o/object", .sha256 = try e.digest(cache ++ "/o/object") }} });
    try e.pins();
    try t.expectEqual(.skipped, e.actions.items[0].status);
}

test "storage cleanup: unnamed hash fingerprints hold their entire containing run" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try f.build(&e);
    try e.discover();
    try f.write(run ++ "/fingerprint.sha256", try e.digest(cache ++ "/o/object"));
    try e.pins();
    try t.expectEqual(.skipped, e.actions.items[0].status);
}

test "storage cleanup: a mounted root is rejected independently of device comparison" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    var proc = try core.fa.metadata.openRoot(t.io, "/proc");
    defer proc.close(t.io);
    const entries = [_]core.fa.Entry{.{ .path = ".", .metadata = try core.fa.metadata.descriptor(proc.handle), .sha256 = null }};
    try t.expectError(error.MountedCache, e.checkMounts(.{ .root = "/proc", .entries = &entries, .options = .{}, .totals = .{} }));
}

test "storage cleanup: stale inode cache entries do not override a new file identity" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try f.write(report, "{\"status\":\"passed\"}");
    const actual = try e.metadata(report);
    var stale = actual;
    stale.ctime_ns -= 1;
    const stale_hash = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
    try e.hash_cache.put(core.fa.metadata.identity(actual), .{ .metadata = stale, .sha256 = stale_hash });
    try t.expect(!std.mem.eql(u8, stale_hash, try e.digest(report)));
    try e.hash_cache.put(core.fa.metadata.identity(actual), .{ .metadata = stale, .sha256 = stale_hash });
    var parsed = try e.load(t.allocator, report);
    defer parsed.deinit();
    try t.expect(core.eq(parsed.value, "status", "passed"));
}

test "storage cleanup: a fresh pin pass observes changed symlink targets" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try f.build(&e);
    try e.discover();
    try f.write("unrelated", "keep");
    try f.tmp.dir.symLink(t.io, "unrelated", "pin-alias", .{});
    try f.write(run ++ "/pins.sha256", try e.c.fmt("{s}  {s}\n", .{ try e.digest("unrelated"), try e.absolute("pin-alias") }));
    try e.pins();
    try t.expectEqual(.discovered, e.actions.items[0].status);
    try f.tmp.dir.deleteFile(t.io, "pin-alias");
    try f.tmp.dir.symLink(t.io, cache ++ "/o/object", "pin-alias", .{});
    try e.pins();
    try t.expectEqual(.skipped, e.actions.items[0].status);
}

test "storage cleanup: minimal lifecycle admits completed fresh cache without waiving source checks" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try f.build(&e);
    e.config.minimum_idle_hours = 24;
    try e.discover();
    try t.expectError(error.TooRecent, e.qualify(0));
    try e.measureHeld(0);
    try t.expect(e.actions.items[0].measured);
    try t.expect(e.actions.items[0].allocated_bytes > 0);
    e.config = p.minimal(e.config);
    // Fresh engine to avoid carrying the observational held byte measurement.
    var minimal = core.Engine.init(&f.c, e.config, output, e.zigrep);
    minimal.now_ns = e.now_ns;
    try minimal.discover();
    try minimal.qualify(0);
    try t.expectEqual(.ready, minimal.actions.items[0].status);
    try f.write("local-state/validations/test/source/main.zig", "changed source");
    var changed = f.engine();
    changed.config = p.minimal(changed.config);
    try changed.discover();
    try t.expectError(error.EvidenceHashMismatch, changed.qualify(0));
}

test "storage cleanup: missing pin parent is refreshed on every pass" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try f.build(&e);
    try e.discover();
    try f.write(run ++ "/pins.sha256", try e.c.fmt("{s}  future/pin-alias\n", .{try e.digest(cache ++ "/o/object")}));
    try e.pins();
    try t.expectEqual(.discovered, e.actions.items[0].status);
    try f.tmp.dir.createDir(t.io, "future", .default_dir);
    try f.tmp.dir.symLink(t.io, "../" ++ cache ++ "/o/object", "future/pin-alias", .{});
    try e.pins();
    try t.expectEqual(.skipped, e.actions.items[0].status);
}

test "storage cleanup: repeated missing pin leaves in existing parents are refreshed" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try f.build(&e);
    try e.discover();
    try f.tmp.dir.createDir(t.io, "future", .default_dir);
    const line = try e.c.fmt("{s}  future/pin-alias\n", .{try e.digest(cache ++ "/o/object")});
    try f.write(run ++ "/pins.sha256", try e.c.fmt("{s}{s}{s}", .{ line, line, line }));
    try e.pins();
    try t.expectEqual(.discovered, e.actions.items[0].status);
    try f.tmp.dir.symLink(t.io, "../" ++ cache ++ "/o/object", "future/pin-alias", .{});
    try e.pins();
    try t.expectEqual(.skipped, e.actions.items[0].status);
}

test "storage cleanup: changed cached pin manifest aborts refresh" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try f.build(&e);
    try e.discover();
    try f.write(run ++ "/pins.sha256", "# no pins yet\n");
    try e.pins();
    try f.write(run ++ "/pins.sha256", try e.c.fmt("{s}  {s}\n", .{ try e.digest(cache ++ "/o/object"), cache ++ "/o/object" }));
    try t.expectError(error.PinManifestChanged, e.pins());
}

test "storage cleanup: another candidate's retained evidence always wins" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try f.build(&e);
    try e.discover();
    try e.qualify(0);
    try e.actions.append(f.c.a, .{ .path = released ++ "/unrelated.log", .run_root = released, .producer = report, .kind = .log, .status = .skipped, .retained = &.{.{ .path = try e.absolute(cache ++ "/o/object"), .sha256 = try e.digest(cache ++ "/o/object") }} });
    try e.protectRetained();
    try t.expectEqual(.skipped, e.actions.items[0].status);
}

test "storage cleanup: owner can publish audited failed trace without a passed successor" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    _ = try f.release(&e, .raw_trace, true, false, true);
    try f.tmp.dir.deleteFile(t.io, released ++ "/storage-release.json");
    e = f.engine();
    e.now_ns = std.Io.Clock.real.now(t.io).nanoseconds - std.time.ns_per_s;
    const published = try releases.trace(&e, released ++ "/audit.json", report, "Raw detail is audited; preserve the failure and replay inputs");
    try t.expectEqualStrings(released ++ "/storage-release.json", published);
    // Publishing is an ownership transition only.
    _ = try e.metadata(released ++ "/profile.events.jsonl");
    var collector = f.engine();
    try collector.discover();
    for (collector.actions.items, 0..) |a, i| {
        if (a.kind != .raw_trace) continue;
        try collector.qualify(i);
        try mutation.apply(&collector, i);
    }
    try t.expectError(error.FileNotFound, collector.metadata(released ++ "/profile.events.jsonl"));
    var producer = try collector.load(t.allocator, released ++ "/producer.json");
    defer producer.deinit();
    try t.expectEqual(@as(i64, 1), try core.integer(producer.value, "actual_returncode"));
    try t.expect(core.eq(producer.value, "status", "finished"));
}

test "storage cleanup: incomplete audit cannot publish a release" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    _ = try f.release(&e, .raw_trace, false, false, true);
    try f.tmp.dir.deleteFile(t.io, released ++ "/storage-release.json");
    e = f.engine();
    try t.expectError(error.IncompleteTraceAudit, releases.trace(&e, released ++ "/audit.json", report, "Insufficient audit"));
    try t.expectError(error.FileNotFound, e.metadata(released ++ "/storage-release.json"));
    _ = try e.metadata(released ++ "/profile.events.jsonl");
}

test "storage cleanup: audited state cannot release binaries or logs" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    _ = try f.release(&e, .log, true, true, false);
    var v = try e.load(t.allocator, released ++ "/storage-release.json");
    defer v.deinit();
    v.value.object.getPtr("state").?.* = .{ .string = "audited" };
    try e.write(released ++ "/storage-release.json", v.value);
    e = f.engine();
    try e.discover();
    for (e.actions.items, 0..) |a, i| {
        if (a.kind == .log) try t.expectError(error.AuditedReleaseOnlyTraces, e.qualify(i));
    }
}

test "storage cleanup: indexed pins cover ancestors and missing descendants but respect boundaries" {
    const f = try Fixture.init();
    defer f.deinit();
    for ([_][]const u8{ run, cache ++ "/future/file", cache ++ "-neighbor/file" }) |target| {
        var e = f.engine();
        try f.build(&e);
        try e.discover();
        try f.write(run ++ "/index.sha256", try e.c.fmt("{s}  {s}\n", .{ try e.digest(cache ++ "/o/object"), target }));
        try e.pins();
        try t.expectEqual(if (std.mem.eql(u8, target, cache ++ "-neighbor/file")) @as(@FieldType(core.Action, "status"), .discovered) else .skipped, e.actions.items[0].status);
    }
}

test "storage cleanup: minimal mode preserves byte limits and protection declarations" {
    const config: p.Config = .{ .max_reclaim_bytes = 4096, .protected_paths = &.{run}, .current_manifests = &.{"required.sha256"}, .holds_file = "queue.json" };
    const minimal = p.minimal(config);
    try t.expectEqual(@as(u32, 0), minimal.minimum_idle_hours);
    try t.expectEqual(@as(usize, 16_384), minimal.max_candidates);
    try p.validate(minimal);
    try t.expectEqual(config.max_reclaim_bytes, minimal.max_reclaim_bytes);
    try t.expectEqualStrings(run, minimal.protected_paths[0]);
    try t.expectEqualStrings("required.sha256", minimal.current_manifests[0]);
    try t.expectEqualStrings(config.holds_file, minimal.holds_file);
}

test "storage cleanup: pinned candidates do not consume the collection budget" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    e.config.max_candidates = 1;
    e.config.max_reclaim_bytes = 4096;
    for ([_]@FieldType(core.Action, "status"){ .skipped, .ready, .ready }) |status| try e.actions.append(f.c.a, .{ .path = cache, .run_root = run, .producer = report, .kind = .cache, .status = status, .allocated_bytes = 4096 });
    e.applyLimits();
    try t.expectEqual(.ready, e.actions.items[1].status);
    try t.expectEqual(.skipped, e.actions.items[2].status);
    try t.expect(e.hasReady());
}

test "storage cleanup: directory pin aliases are resolved anew for each mutation" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try f.build(&e);
    try e.discover();
    try f.tmp.dir.createDirPath(t.io, "unrelated/o");
    try f.write("unrelated/o/object", "other");
    try f.tmp.dir.symLink(t.io, "unrelated", "directory-alias", .{ .is_directory = true });
    try f.write(run ++ "/directory.sha256", try e.c.fmt("{s}  directory-alias/o/object\n", .{try e.digest("unrelated/o/object")}));
    try e.pins();
    try t.expectEqual(.discovered, e.actions.items[0].status);
    try f.tmp.dir.deleteFile(t.io, "directory-alias");
    try f.tmp.dir.symLink(t.io, cache, "directory-alias", .{ .is_directory = true });
    try e.pins();
    try t.expectEqual(.skipped, e.actions.items[0].status);
}

test "storage cleanup: pin resolution remains correct beyond the directory descriptor budget" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try f.build(&e);
    try e.discover();
    var lines: std.ArrayList(u8) = .empty;
    for (0..140) |i| {
        const dir = try e.c.fmt("pin-directories/d{d}", .{i});
        try f.tmp.dir.createDirPath(t.io, dir);
        const path = try e.c.fmt("{s}/file", .{dir});
        try f.write(path, "unrelated");
        try lines.appendSlice(f.c.a, try e.c.fmt("{s}  {s}\n", .{ try e.digest(path), path }));
    }
    try f.tmp.dir.symLink(t.io, "../../" ++ cache ++ "/o/object", "pin-directories/d139/last-alias", .{});
    try lines.appendSlice(f.c.a, try e.c.fmt("{s}  pin-directories/d139/last-alias\n", .{try e.digest(cache ++ "/o/object")}));
    try f.write(run ++ "/many-pins.sha256", lines.items);
    try e.pins();
    try t.expect(e.pin_open_directories <= 128);
    try t.expectEqual(.skipped, e.actions.items[0].status);
}

const GeneratedFault = enum { none, failed_assemble, wrong_output, bad_index, incomplete, wrong_source };
fn assemblyFixture(f: *Fixture, e: *core.Engine, fault: GeneratedFault) !void {
    try f.tmp.dir.createDirPath(t.io, assembly_dir);
    try f.write(assembly_path, ".text\n# disposable generated assembly\n");
    try f.write(assembly_dir ++ "/linked.zig", "pub fn main() void {}\n");
    for ([_][]const u8{ "compile.stdout", "compile.stderr", "assemble.stdout", "assemble.stderr" }) |name|
        try f.write(try f.c.fmt("{s}/{s}", .{ assembly_dir, name }), "original diagnostic\n");
    const emitter = "/reviewed/zig";
    const compile = [_][]const u8{ emitter, "build-exe", try e.absolute(assembly_dir ++ "/linked.zig"), "-fno-emit-bin", try f.c.fmt("-femit-asm={s}", .{try e.absolute(if (fault == .wrong_output) assembly_dir ++ "/unrelated.s" else assembly_path)}) };
    const assemble = [_][]const u8{ emitter, "cc", "-x", "assembler", "-c", try e.absolute(assembly_path), "-o", try e.absolute(assembly_dir ++ "/linked-harness.o") };
    try e.write(assembly_owner ++ "/commands.json", .{
        .{ .argv = compile, .outcome = "completed", .returncode = 0, .actual_returncode = 0, .stdout = try e.absolute(assembly_dir ++ "/compile.stdout"), .stderr = try e.absolute(assembly_dir ++ "/compile.stderr") },
        .{ .argv = assemble, .outcome = "completed", .returncode = if (fault == .failed_assemble) @as(i32, 2) else 0, .actual_returncode = if (fault == .failed_assemble) @as(i32, 2) else 0, .stdout = try e.absolute(assembly_dir ++ "/assemble.stdout"), .stderr = try e.absolute(assembly_dir ++ "/assemble.stderr") },
    });
    try e.write(assembly_owner ++ "/report.json", .{
        .schema = "execution-breadth-controls-v2",
        .status = "passed",
        .rows = .{.{ .mode = "ReleaseFast", .status = if (fault == .incomplete) "failed" else "passed", .harness = .{
            .source = try e.absolute(if (fault == .wrong_source) assembly_dir ++ "/other.zig" else assembly_dir ++ "/linked.zig"),
            .object = try e.absolute(assembly_dir ++ "/linked-harness.o"),
            .producer_commands = [_]usize{ 0, if (fault == .bad_index) 99 else 1 },
            .emitter = .{ .path = emitter },
        } }},
    });
}

test "storage cleanup: generated assembly removal keeps source, commands and diagnostics" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try assemblyFixture(f, &e, .none);
    const request = try generated.request(&e, assembly_path, "Completed generated test output");
    try e.write(run ++ "/generated-release.json", request);
    try e.discoverRelease(run ++ "/generated-release.json", true);
    try e.qualify(0);
    try t.expectEqual(.ready, e.actions.items[0].status);
    try mutation.apply(&e, 0);
    try t.expect(!u.exists(t.io, try e.absolute(assembly_path)));
    for ([_][]const u8{ assembly_dir ++ "/linked.zig", assembly_owner ++ "/report.json", assembly_owner ++ "/commands.json", assembly_dir ++ "/compile.stderr", assembly_dir ++ "/assemble.stderr" }) |path|
        try t.expect(u.exists(t.io, try e.absolute(path)));
    try t.expect(!u.exists(t.io, try e.absolute(mutation.pending_path)));
}

test "storage cleanup: generated assembly rejects failed, unrelated and incomplete commands" {
    inline for (.{
        .{ GeneratedFault.failed_assemble, error.GeneratedCommandNotSuccessful },
        .{ GeneratedFault.wrong_output, error.UnboundAssemblyProducer },
        .{ GeneratedFault.bad_index, error.InvalidGeneratedCommandIndexes },
        .{ GeneratedFault.incomplete, error.IncompleteGeneratedComparison },
        .{ GeneratedFault.wrong_source, error.UnboundHarnessSource },
    }) |case| {
        const f = try Fixture.init();
        defer f.deinit();
        var e = f.engine();
        try assemblyFixture(f, &e, case[0]);
        try t.expectError(case[1], generated.request(&e, assembly_path, "Review generated output"));
        try t.expect(u.exists(t.io, try e.absolute(assembly_path)));
    }
}

test "storage cleanup: changed generated commands stop mutation and preserve payload" {
    const f = try Fixture.init();
    defer f.deinit();
    var initial = f.engine();
    try assemblyFixture(f, &initial, .none);
    try initial.write(run ++ "/generated-release.json", try generated.request(&initial, assembly_path, "Completed generated test output"));
    var e = f.engine();
    try e.discoverRelease(run ++ "/generated-release.json", true);
    try e.qualify(0);
    try f.write(assembly_owner ++ "/commands.json", "[]\n");
    if (mutation.apply(&e, 0)) |_| return error.ChangedCommandsAccepted else |_| {}
    try t.expect(u.exists(t.io, try e.absolute(assembly_path)));
    try t.expect(!u.exists(t.io, try e.absolute(mutation.pending_path)));
}

test "storage cleanup: checksum pins still protect generated assembly" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try assemblyFixture(f, &e, .none);
    try e.write(run ++ "/generated-release.json", try generated.request(&e, assembly_path, "Completed generated test output"));
    try e.discoverRelease(run ++ "/generated-release.json", true);
    try e.qualify(0);
    try f.write(run ++ "/accepted.sha256", try f.c.fmt("{s}  {s}\n", .{ try e.digest(assembly_path), assembly_path }));
    try e.pins();
    try t.expectEqual(.skipped, e.actions.items[0].status);
}

fn captureFixture(f: *Fixture, e: *core.Engine, wrong_hash: bool) !void {
    try f.write(run ++ "/capture-zllvm", "\x7fELFsynthetic-validation-runner");
    try f.write(run ++ "/commands.json", "[]\n");
    try e.write(report, .{ .schema = "real-program-v1", .status = "passed", .tool_provenance = .{ .binary_sha256 = if (wrong_hash) "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" else try e.digest(run ++ "/capture-zllvm") }, .rows = .{.{ .mode = "ReleaseFast", .status = "matched" }} });
}

test "storage cleanup: shallow legacy capture helper retains exact provenance and scope" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    const owner = "local-state/validations/test/legacy-capture";
    const helper = owner ++ "/capture-zllvm";
    try f.tmp.dir.createDirPath(t.io, owner);
    try f.write(helper, "\x7fELFclosed capture runner");
    try f.write(owner ++ "/commands.json", "[]");
    try e.write(owner ++ "/report.json", .{ .schema = "real-program-v1", .status = "passed", .tool_provenance = .{ .binary_sha256 = try e.digest(helper) }, .rows = .{.{ .mode = "ReleaseFast", .status = "matched" }} });
    const request = try generated.request(&e, helper, "Closed legacy capture");
    try t.expect(p.releaseRoot(request));
    var unrelated = request;
    unrelated.artifacts = &.{.{ .path = owner ++ "/unbound.o", .kind = .build_output }};
    try t.expect(!p.releaseRoot(unrelated));
    unrelated = request;
    unrelated.producer.path = run ++ "/report.json";
    try t.expect(!p.releaseRoot(unrelated));
    try e.write(output ++ "/capture-request.json", request);
    try e.discoverRelease(output ++ "/capture-request.json", true);
    try e.qualify(0);
    try e.protectRetained();
    try mutation.applyFileBatch(&e, &.{0});
    try t.expectEqual(.removed, e.actions.items[0].status);
    _ = try e.metadata(owner ++ "/report.json");
    _ = try e.metadata(owner ++ "/commands.json");
}

test "storage cleanup: capture helper requires the runner provenance hash" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try captureFixture(f, &e, true);
    try t.expectError(error.CaptureRunnerHashMismatch, generated.request(&e, run ++ "/capture-zllvm", "Completed capture helper"));
    try captureFixture(f, &e, false);
    e = f.engine();
    try e.write(run ++ "/generated-release.json", try generated.request(&e, run ++ "/capture-zllvm", "Completed capture helper"));
    try e.discoverRelease(run ++ "/generated-release.json", true);
    try e.qualify(0);
    try mutation.apply(&e, 0);
    try t.expect(!u.exists(t.io, try e.absolute(run ++ "/capture-zllvm")));
    try t.expect(u.exists(t.io, try e.absolute(report)));
}

test "storage cleanup: aliased capture helpers cannot be removed" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try captureFixture(f, &e, false);
    const file = try f.tmp.dir.openFile(t.io, run ++ "/capture-zllvm", .{});
    defer file.close(t.io);
    try file.hardLink(t.io, f.tmp.dir, run ++ "/still-needed-runner", .{});
    try e.write(run ++ "/generated-release.json", try generated.request(&e, run ++ "/capture-zllvm", "Completed capture helper"));
    try e.discoverRelease(run ++ "/generated-release.json", true);
    try t.expectError(error.AliasedOrNonRegularArtifact, e.qualify(0));
}

test "storage cleanup: generated assembly adapter does not accept arbitrary source files" {
    try t.expect(!p.artifactName(.{ .path = assembly_dir ++ "/original.s", .sha256 = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", .kind = .generated_assembly }));
}

test "storage cleanup: parent integrated job protects finished subtest outputs" {
    const parent = "local-state/validations/example/batch/integrated-v2";
    const scope = generated.consumerRoot(parent ++ "/execution-breadth-controls");
    try t.expectEqualStrings(parent, scope);
    try t.expect(core.commandUsesRun("123 runner --output-root " ++ parent, scope, 456));
    try t.expectEqualStrings(run, generated.consumerRoot(run));
}

fn generatedBatchFixture(f: *Fixture, e: *core.Engine) !void {
    for ([_][]const u8{ "first", "second" }, 0..) |name, index| {
        const owner = try f.c.fmt("{s}/integrated-batch/{s}", .{ run, name });
        const path = try f.c.fmt("{s}/capture-zllvm", .{owner});
        try f.tmp.dir.createDirPath(t.io, owner);
        try f.write(path, "\x7fELFtemporary copied runner");
        try f.write(try f.c.fmt("{s}/commands.json", .{owner}), "[]\n");
        try f.write(try f.c.fmt("{s}/input.ll", .{owner}), "original input remains\n");
        try e.write(try f.c.fmt("{s}/report.json", .{owner}), .{ .schema = "real-program-v1", .status = "passed", .tool_provenance = .{ .binary_sha256 = try e.digest(path) }, .rows = .{.{ .mode = "ReleaseFast", .status = "matched" }} });
        const request_path = try f.c.fmt("{s}/batch-release-{d}.json", .{ run, index });
        try e.write(request_path, try generated.request(e, path, "Completed copied helpers"));
        try e.discoverRelease(request_path, true);
        try e.qualify(index);
    }
}

test "storage cleanup: generated batch removes only named files and records each result" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try generatedBatchFixture(f, &e);
    var parent = try f.tmp.dir.openDir(t.io, run ++ "/integrated-batch/first", .{ .iterate = true });
    try parent.setPermissions(t.io, .fromMode(0o500));
    parent.close(t.io);
    defer {
        var restore = f.tmp.dir.openDir(t.io, run ++ "/integrated-batch/first", .{ .iterate = true }) catch unreachable;
        defer restore.close(t.io);
        restore.setPermissions(t.io, .fromMode(0o700)) catch {};
    }
    try mutation.applyGeneratedBatch(&e, &.{ 0, 1 });
    parent = try f.tmp.dir.openDir(t.io, run ++ "/integrated-batch/first", .{ .iterate = true });
    defer parent.close(t.io);
    try t.expectEqual(@as(u32, 0o500), (try parent.stat(t.io)).permissions.toMode() & 0o7777);
    for (e.actions.items, 0..) |a, index| {
        try t.expectEqual(.removed, a.status);
        try t.expectEqual(a.allocated_bytes, a.reclaimed_file_bytes);
        try t.expect(!u.exists(t.io, try e.absolute(a.path)));
        try t.expect(u.exists(t.io, try e.absolute(try f.c.fmt("{s}/record-{d}.json", .{ output, index }))));
        try t.expect(u.exists(t.io, try e.absolute(try f.c.fmt("{s}/input.ll", .{a.run_root}))));
    }
    try t.expect(!u.exists(t.io, try e.absolute(mutation.pending_path)));
}

test "storage cleanup: generated batch rolls back every name when a pin appears at refresh" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try generatedBatchFixture(f, &e);
    try f.write(run ++ "/new-pin.sha256", try f.c.fmt("{s}  {s}\n", .{ e.actions.items[1].sha256.?, e.actions.items[1].path }));
    try t.expectError(error.GeneratedBatchBecameHeld, mutation.applyGeneratedBatch(&e, &.{ 0, 1 }));
    for (e.actions.items) |a| {
        try t.expect(u.exists(t.io, try e.absolute(a.path)));
        try t.expectEqual(@as(u64, 0), a.reclaimed_file_bytes);
        try t.expectEqualStrings(a.sha256.?, try f.c.digest(try e.absolute(a.path)));
    }
    try t.expect(!u.exists(t.io, try e.absolute(mutation.pending_path)));
}

test "storage cleanup: generated batch rejects changed files before any quarantine" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try generatedBatchFixture(f, &e);
    try f.write(e.actions.items[1].path, "changed output");
    try t.expectError(error.CandidateChanged, mutation.applyGeneratedBatch(&e, &.{ 0, 1 }));
    for (e.actions.items) |a| try t.expect(u.exists(t.io, try e.absolute(a.path)));
    try t.expect(!u.exists(t.io, try e.absolute(mutation.pending_path)));
}

test "storage cleanup: generated batch rejects duplicate members and unrelated generations" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try generatedBatchFixture(f, &e);
    try t.expectError(error.InvalidGeneratedBatch, mutation.applyGeneratedBatch(&e, &.{ 0, 0 }));
    e.actions.items[1].run_root = "local-state/validations/unrelated/batch/integrated-other";
    try t.expectError(error.InvalidGeneratedBatch, mutation.applyGeneratedBatch(&e, &.{ 0, 1 }));
    for (e.actions.items) |a| try t.expect(u.exists(t.io, try e.absolute(a.path)));
    try t.expect(!u.exists(t.io, try e.absolute(mutation.pending_path)));
}

fn retiredLogFixture(f: *Fixture, e: *core.Engine, size: u64, applied: bool) !void {
    try assemblyFixture(f, e, .none);
    try f.tmp.dir.deleteFile(t.io, assembly_dir ++ "/compile.stdout");
    try f.write(output ++ "/approved-audit.json", "{\"reviewed\":true}\n");
    try e.write(output ++ "/record.json", .{
        .schema = 1,
        .status = "complete",
        .preservation_verified_before = true,
        .preservation_verified_after = true,
        .audit_sha256 = try e.digest(output ++ "/approved-audit.json"),
        .actions = .{.{ .path = assembly_dir ++ "/compile.stdout", .sha256 = "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855", .applied = applied, .info = .{ .size = size, .allocated = 0 } }},
    });
    e.config.retired_empty_log_records = try f.c.a.dupe(p.Evidence, &.{.{ .path = output ++ "/record.json", .sha256 = try e.digest(output ++ "/record.json") }});
}

test "storage cleanup: retired empty diagnostics retain verified ledger and audit" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try retiredLogFixture(f, &e, 0, true);
    try e.write(run ++ "/generated-release.json", try generated.request(&e, assembly_path, "Verified empty log retirement"));
    try e.discoverRelease(run ++ "/generated-release.json", true);
    try e.qualify(0);
    try mutation.apply(&e, 0);
    try t.expect(!u.exists(t.io, try e.absolute(assembly_path)));
    try t.expect(u.exists(t.io, try e.absolute(output ++ "/record.json")));
    try t.expect(u.exists(t.io, try e.absolute(output ++ "/approved-audit.json")));
}

test "storage cleanup: missing or nonempty retired diagnostics stay blocked" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try retiredLogFixture(f, &e, 1, true);
    try t.expectError(error.NonemptyOrUnretiredLog, generated.request(&e, assembly_path, "Reject nonempty log"));
    e.config.retired_empty_log_records = &.{};
    try t.expectError(error.MissingDiagnosticRetirement, generated.request(&e, assembly_path, "Reject unknown missing log"));
}

test "storage cleanup: changed retired log audit blocks deletion" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try retiredLogFixture(f, &e, 0, true);
    try e.write(run ++ "/generated-release.json", try generated.request(&e, assembly_path, "Verified empty log retirement"));
    try e.discoverRelease(run ++ "/generated-release.json", true);
    try e.qualify(0);
    try f.write(output ++ "/approved-audit.json", "changed audit\n");
    try t.expectError(error.EvidenceHashMismatch, mutation.apply(&e, 0));
    try t.expect(u.exists(t.io, try e.absolute(assembly_path)));
}

test "storage cleanup: only a terminal receipt closes a job-owned hold" {
    const lifecycle = @import("../validation/storage_lifecycle.zig");
    const jobs = @import("jobs.zig");
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    var job: lifecycle.Job = .{ .run_root = run, .working_directory = run, .producer = .{ .path = report, .sha256 = "" }, .started_ns = 1 };
    try t.expect(!try jobs.validate(&e, job));
    try e.write(report, .{ .status = "finished", .outcome = "completed", .actual_returncode = 1, .started_ns = 1, .finished_ns = 2, .cwd = try e.absolute(run) });
    job.state = .finished;
    job.producer.sha256 = try e.digest(report);
    try t.expect(try jobs.validate(&e, job));
    job.started_ns = 9;
    try t.expectError(error.StorageJobNotTerminal, jobs.validate(&e, job));
    job.started_ns = 1;
    try f.write(report, "{}\n");
    try t.expectError(error.FileChanged, jobs.validate(&e, job));
}

test "storage cleanup: completed job does not expire manual holds" {
    const lifecycle = @import("../validation/storage_lifecycle.zig");
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try f.tmp.dir.createDirPath(t.io, lifecycle.jobs_directory);
    try e.write(report, .{ .status = "finished", .outcome = "completed", .actual_returncode = 0, .started_ns = 1, .finished_ns = 2, .cwd = try e.absolute(run) });
    const job: lifecycle.Job = .{ .state = .finished, .run_root = run, .working_directory = run, .producer = .{ .path = report, .sha256 = try e.digest(report) }, .started_ns = 1 };
    try e.write(lifecycle.jobs_directory ++ "/test.json", job);
    try e.write(e.config.holds_file, p.Holds{ .paths = &.{run} });
    try e.actions.append(f.c.a, .{ .path = cache, .run_root = run, .producer = report, .kind = .cache });
    try e.loadHolds();
    try t.expectEqual(.skipped, e.actions.items[0].status);
    try t.expect(std.mem.indexOf(u8, e.actions.items[0].reason.?, "protected by hold") != null);
}

test "storage cleanup: shared input migration preserves aliases and rolls back a new hold" {
    const shared = @import("shared_inputs.zig");
    const storage = @import("../zllvm_artifact_store/store.zig");
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try f.write(run ++ "/input.ll", "identical retained IR\n");
    const file = try f.tmp.dir.openFile(t.io, run ++ "/input.ll", .{});
    try file.hardLink(t.io, f.tmp.dir, run ++ "/alias.ll", .{});
    const sha = try e.digest(run ++ "/input.ll");
    const metadata = try e.metadata(run ++ "/input.ll");
    var store = try storage.Store.open(f.c.a, t.io, try e.absolute("local-state/artifacts"), true);
    defer store.deinit();
    try store.publishFile(file, .{ .name = "input.ll", .sha256 = sha, .bytes = metadata.size });
    file.close(t.io);
    for ([_][]const u8{ run ++ "/input.ll", run ++ "/alias.ll" }) |path|
        try e.actions.append(f.c.a, .{ .path = path, .run_root = run, .producer = report, .kind = .build_output, .status = .ready, .sha256 = sha, .metadata = metadata });
    try e.write(e.config.holds_file, p.Holds{ .paths = &.{run} });
    try t.expectError(error.SharedInputHeld, shared.migrate(&e, &store, &.{ 0, 1 }, metadata, sha));
    try t.expectEqual(metadata.inode, (try e.metadata(run ++ "/input.ll")).inode);
    try t.expectEqual(metadata.inode, (try e.metadata(run ++ "/alias.ll")).inode);
    try t.expectEqual(metadata.links, (try e.metadata(run ++ "/input.ll")).links);
    try t.expect(!u.exists(t.io, try e.absolute(mutation.pending_path)));
    try f.tmp.dir.deleteFile(t.io, e.config.holds_file);
    // Rollback changes ctime; take a fresh observation before retrying.
    e = f.engine();
    const retry = try e.metadata(run ++ "/input.ll");
    for ([_][]const u8{ run ++ "/input.ll", run ++ "/alias.ll" }) |path|
        try e.actions.append(f.c.a, .{ .path = path, .run_root = run, .producer = report, .kind = .build_output, .status = .ready, .sha256 = sha, .metadata = retry });
    try t.expectEqual(retry.allocated_bytes, try shared.migrate(&e, &store, &.{ 0, 1 }, retry, sha));
    const object = try store.objects.statFile(t.io, sha, .{});
    for (e.actions.items) |a| {
        const current = try e.metadata(a.path);
        try t.expectEqual(object.inode, current.inode);
        try t.expectEqual(@as(u32, 0o444), current.mode & 0o7777);
        try t.expectEqualStrings(sha, try e.digest(a.path));
    }
}

test "storage cleanup: AIR sharing preserves cache aliases and current contracts" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    const original = "local-state/caches/compiler/export/input.air";
    const alias = "local-state/inputs/compiler/input.air";
    const copy = "local-state/validations/legacy/input.air";
    try f.tmp.dir.createDirPath(t.io, std.fs.path.dirname(original).?);
    try f.tmp.dir.createDirPath(t.io, std.fs.path.dirname(copy).?);
    try f.write(original, "identical serialized compiler input\n");
    try f.tmp.dir.createDirPath(t.io, "local-state/inputs/compiler");
    {
        const file = try f.tmp.dir.openFile(t.io, original, .{});
        defer file.close(t.io);
        try file.hardLink(t.io, f.tmp.dir, alias, .{});
    }
    try f.write(copy, "identical serialized compiler input\n");
    const sha = try e.digest(original);
    const plan = output ++ "/inputs.json";
    try e.write(plan, .{ .schema = "zllvm-shared-inputs-v1", .inputs = .{.{ .sha256 = sha, .paths = [_][]const u8{ original, alias, copy } }} });
    const manifest = output ++ "/current.sha256";
    try f.write(manifest, try f.c.fmt("{s}  {s}\n{s}  {s}\n{s}  {s}\n", .{ sha, original, sha, alias, sha, copy }));
    e.config.current_manifests = &.{manifest};
    e.config.protected_paths = &.{ "local-state/caches", "local-state/inputs" };
    try @import("shared_inputs.zig").run(&e, plan, true);
    const object = try e.metadata(try f.c.fmt("local-state/artifacts/objects/{s}", .{sha}));
    for ([_][]const u8{ original, alias, copy }) |path| {
        try t.expectEqual(object.inode, (try e.metadata(path)).inode);
        try t.expectEqualStrings(sha, try e.digest(path));
    }
    try t.expect(!u.exists(t.io, try e.absolute(mutation.pending_path)));
}

test "storage cleanup: input sharing honors manual generic and specific policy holds" {
    for ([_]bool{ false, true }) |manual| {
        const f = try Fixture.init();
        defer f.deinit();
        var e = f.engine();
        const input = "local-state/caches/compiler/export/input.air";
        try f.tmp.dir.createDirPath(t.io, std.fs.path.dirname(input).?);
        try f.write(input, "held immutable input");
        const before = try e.metadata(input);
        const plan = output ++ "/inputs.json";
        try e.write(plan, .{ .schema = "zllvm-shared-inputs-v1", .inputs = .{.{ .sha256 = try e.digest(input), .paths = [_][]const u8{input} }} });
        if (manual) try e.write(e.config.holds_file, p.Holds{ .paths = &.{"local-state/caches"} }) else e.config.protected_paths = &.{"local-state/caches/compiler"};
        try @import("shared_inputs.zig").run(&e, plan, true);
        try t.expectEqual(.skipped, e.actions.items[0].status);
        try t.expect(before.eql(try e.metadata(input)));
        try t.expect(!u.exists(t.io, try e.absolute("local-state/artifacts")));
    }
}

test "storage cleanup: input sharing restricts file scope and observes shallow parent consumers" {
    const shared = @import("shared_inputs.zig");
    for ([_][]const u8{ "local-state/validations/legacy/input.ll", "local-state/inputs/input.air", "local-state/caches/compiler/input.air" }) |path| try t.expect(shared.scope(path));
    for ([_][]const u8{ "src/input.ll", "local-state/worktrees/x/input.ll", "local-state/caches/../src/input.ll", "local-state/inputs/source.zig", "local-state/caches/compiler/object.o" }) |path| try t.expect(!shared.scope(path));
    try t.expectEqualStrings("local-state/validations/legacy", shared.consumerRoot("local-state/validations/legacy/input.ll"));
    try t.expectEqualStrings("local-state/inputs", shared.consumerRoot("local-state/inputs/input.air"));
    try t.expectEqualStrings("local-state/caches/compiler", shared.consumerRoot("local-state/caches/compiler/export/input.air"));
}

test "storage cleanup: held release prevents input sharing without a repeated manual hold" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try f.build(&e);
    try f.write(run ++ "/input.ll", "retained input\n");
    const before = try e.metadata(run ++ "/input.ll");
    var held = try releases.disposableBuild(&e, report, "Active investigation");
    held.state = .held;
    try e.write(run ++ "/storage-release.json", held);
    const plan = output ++ "/inputs.json";
    try e.write(plan, .{ .schema = "zllvm-shared-inputs-v1", .inputs = .{.{ .sha256 = try e.digest(run ++ "/input.ll"), .paths = [_][]const u8{run ++ "/input.ll"} }} });
    var fresh = f.engine();
    try @import("shared_inputs.zig").run(&fresh, plan, true);
    try t.expectEqual(@as(usize, 1), fresh.actions.items.len);
    try t.expectEqual(.skipped, fresh.actions.items[0].status);
    try t.expect(before.eql(try fresh.metadata(run ++ "/input.ll")));
    try t.expect(!u.exists(t.io, try fresh.absolute("local-state/artifacts")));
}

test "storage cleanup: shared input migration rejects incomplete aliases and changed content" {
    const shared = @import("shared_inputs.zig");
    const storage = @import("../zllvm_artifact_store/store.zig");
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try f.write(run ++ "/input.ll", "retained IR\n");
    const file = try f.tmp.dir.openFile(t.io, run ++ "/input.ll", .{});
    defer file.close(t.io);
    try file.hardLink(t.io, f.tmp.dir, run ++ "/unknown-alias.ll", .{});
    const metadata = try e.metadata(run ++ "/input.ll");
    const sha = try e.digest(run ++ "/input.ll");
    var store = try storage.Store.open(f.c.a, t.io, try e.absolute("local-state/artifacts"), true);
    defer store.deinit();
    try e.actions.append(f.c.a, .{ .path = run ++ "/input.ll", .run_root = run, .producer = report, .kind = .build_output, .status = .ready, .sha256 = sha, .metadata = metadata });
    try t.expectError(error.IncompleteInputAliases, shared.migrate(&e, &store, &.{0}, metadata, sha));
    try f.tmp.dir.deleteFile(t.io, run ++ "/unknown-alias.ll");
    const single = try e.metadata(run ++ "/input.ll");
    try f.write(run ++ "/input.ll", "changed IR\n");
    try t.expectError(error.SharedInputChanged, shared.migrate(&e, &store, &.{0}, single, sha));
    try t.expect(!u.exists(t.io, try e.absolute(mutation.pending_path)));
}

fn captureAliasFixture(f: *Fixture, e: *core.Engine) !void {
    try generatedBatchFixture(f, e);
    try f.tmp.dir.deleteFile(t.io, e.actions.items[1].path);
    const file = try f.tmp.dir.openFile(t.io, e.actions.items[0].path, .{});
    defer file.close(t.io);
    try file.hardLink(t.io, f.tmp.dir, e.actions.items[1].path, .{});
    e.allow_capture_aliases = true;
    for (0..2) |i| {
        e.actions.items[i].status = .discovered;
        try e.qualify(i);
    }
    try e.guardCaptureGroups();
}

test "storage cleanup: complete capture alias retirement charges one physical inode" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try captureAliasFixture(f, &e);
    const allocation = e.actions.items[0].metadata.?.allocated_bytes;
    try t.expectEqual(allocation, e.actions.items[0].allocated_bytes + e.actions.items[1].allocated_bytes);
    try mutation.applyGeneratedBatch(&e, &.{ 0, 1 });
    try t.expectEqual(allocation, e.actions.items[0].reclaimed_file_bytes + e.actions.items[1].reclaimed_file_bytes);
    for (e.actions.items) |a| try t.expect(!u.exists(t.io, try e.absolute(a.path)));
}

test "storage cleanup: a current pin on one capture alias protects the group" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try captureAliasFixture(f, &e);
    try f.write(run ++ "/current.sha256", try f.c.fmt("{s}  {s}\n", .{ e.actions.items[1].sha256.?, e.actions.items[1].path }));
    e.config.current_manifests = &.{run ++ "/current.sha256"};
    try e.pins();
    try e.guardCaptureGroups();
    for (e.actions.items) |a| {
        try t.expectEqual(.skipped, a.status);
        try t.expect(u.exists(t.io, try e.absolute(a.path)));
    }
}

test "storage cleanup: newly pinned capture aliases roll back every name" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try captureAliasFixture(f, &e);
    try f.write(run ++ "/new.sha256", try f.c.fmt("{s}  {s}\n", .{ e.actions.items[1].sha256.?, e.actions.items[1].path }));
    try t.expectError(error.GeneratedBatchBecameHeld, mutation.applyGeneratedBatch(&e, &.{ 0, 1 }));
    for (e.actions.items) |a| {
        try t.expectEqual(@as(u64, 2), (try e.metadata(a.path)).links);
        try t.expectEqual(@as(u64, 0), a.reclaimed_file_bytes);
    }
    try t.expect(!u.exists(t.io, try e.absolute(mutation.pending_path)));
}

test "storage cleanup: undeclared capture alias still prevents collection" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try captureAliasFixture(f, &e);
    const file = try f.tmp.dir.openFile(t.io, e.actions.items[0].path, .{});
    defer file.close(t.io);
    try file.hardLink(t.io, f.tmp.dir, run ++ "/unlisted-runner", .{});
    e.actions.items[0].status = .discovered;
    try t.expectError(error.AliasedOrNonRegularArtifact, e.qualify(0));
}

test "storage cleanup: input sharing recognizes parent jobs without a batch directory" {
    const shared = @import("shared_inputs.zig");
    const old = "local-state/validations/selection-census-20261107/compiler-replay-final";
    try t.expectEqualStrings(old, shared.consumerRoot(old ++ "/backend/input.ll"));
    try t.expect(core.commandUsesRun("123 runner --output-root " ++ old, shared.consumerRoot(old ++ "/backend/input.ll"), 456));
    const current = "local-state/validations/compiler-behavior-completion-20261111/batch-01/old-run";
    try t.expectEqualStrings(current, shared.consumerRoot(current ++ "/backend/input.ll"));
    try t.expect(!core.commandUsesRun("123 runner --output-root local-state/validations/compiler-behavior-completion-20261111/batch-01/new-run", shared.consumerRoot(current ++ "/backend/input.ll"), 456));
}

test "storage cleanup: reviewed failed workspace release preserves the failed result" {
    const f = try Fixture.init();
    defer f.deinit();
    const w = try workspaceFixture(f, false);
    w.close(&f.c);
    const result_hash = try f.c.digest(try f.c.join(&.{report}));
    var publishing = f.engine();
    const name = try publishing.relative(w.record_path);
    _ = try workspaces.publish(&publishing, name, "Reviewed resolved failure; diagnostics remain maintained");
    var e = f.engine();
    try workspaces.discover(&e);
    try e.qualify(0);
    try mutation.apply(&e, 0);
    try t.expectEqualStrings(result_hash, try f.c.digest(try f.c.join(&.{report})));
    try t.expect(!workspace.successful(try f.c.load(try f.c.join(&.{report}))));
    try t.expect(!u.exists(f.c.io, try e.absolute(w.record.temporary_root)));
    try t.expect(u.exists(f.c.io, try e.absolute(run ++ "/diagnostic.log")));
}

test "storage cleanup: explicit workspace release refuses holds unfinished producers and raw traces" {
    const f = try Fixture.init();
    defer f.deinit();
    const w = try workspaceFixture(f, false);
    w.close(&f.c);
    const name = w.record_path[f.c.root.len + 1 ..];
    const destination = try workspace.paths.releasePath(f.c.a, w.record);
    var held = f.engine();
    try held.write(held.config.holds_file, p.Holds{ .paths = &.{run} });
    try t.expectError(error.ReleaseCandidateHeld, workspaces.publish(&held, name, "review"));
    try t.expect(!u.exists(f.c.io, try held.absolute(destination)));
    try held.write(held.config.holds_file, p.Holds{ .paths = &.{} });
    const saved = try f.c.read(w.record_path);
    try f.c.writeJson(w.record_path, w.record);
    var active = f.engine();
    try t.expectError(error.WorkspaceProducerNotClosed, workspaces.publish(&active, name, "review"));
    try f.c.write(w.record_path, saved);
    try f.c.write(try f.c.fmt("{s}/{s}/profile.events.jsonl", .{ f.c.root, w.record.temporary_root }), "unique trace");
    var raw = f.engine();
    try t.expectError(error.WorkspaceContainsRawTrace, workspaces.publish(&raw, name, "review"));
    try t.expect(!u.exists(f.c.io, try raw.absolute(destination)));
}

test "storage cleanup: workspace release is bound to unchanged layout result and diagnostics" {
    for ([_][]const u8{ "layout", "result", "diagnostic" }) |changed| {
        const f = try Fixture.init();
        defer f.deinit();
        const w = try workspaceFixture(f, false);
        w.close(&f.c);
        var publishing = f.engine();
        _ = try workspaces.publish(&publishing, try publishing.relative(w.record_path), "resolved");
        if (std.mem.eql(u8, changed, "layout")) {
            var value = try f.c.load(w.record_path);
            try u.put(f.c.a, &value, "state", u.s("disposable"));
            try f.c.writeJson(w.record_path, value);
        } else if (std.mem.eql(u8, changed, "result")) try f.write(report, "{\"status\":\"passed\"}") else try f.write(run ++ "/diagnostic.log", "changed diagnostic");
        var e = f.engine();
        try workspaces.discover(&e);
        if (e.qualify(0)) |_| return error.ChangedReleaseAccepted else |_| {}
        try t.expect(u.exists(f.c.io, try e.absolute(w.record.temporary_root)));
    }
}

test "storage cleanup: compiler workspace stays retained until explicit pipeline release" {
    const f = try Fixture.init();
    defer f.deinit();
    const fixture = try workspaceFixture(f, true);
    fixture.close(&f.c);
    const compiler_root = try f.c.join(&.{ run, "compiler-install" });
    try f.c.mkdir(compiler_root);
    const w = (try workspace.compiler(&f.c, compiler_root)).?;
    const binary = try f.c.temporaryPath(&.{ compiler_root, "bin/z_llvm" });
    try f.c.write(binary, "\x7fELFtemporary compiler");
    try f.c.writeJson(try f.c.join(&.{ compiler_root, "report.json" }), .{ .status = "passed" });
    try w.finishReport(&f.c);
    w.close(&f.c);
    var before = f.engine();
    try workspaces.discover(&before);
    for (before.actions.items) |action| if (std.mem.eql(u8, action.path, w.record.temporary_root)) try t.expectEqual(.skipped, action.status);
    const reopened = (try workspace.compiler(&f.c, compiler_root)).?;
    try t.expectEqualStrings(binary, try f.c.temporaryPath(&.{ compiler_root, "bin/z_llvm" }));
    try reopened.finishReport(&f.c);
    reopened.close(&f.c);
    var publishing = f.engine();
    _ = try workspaces.publish(&publishing, try publishing.relative(w.record_path), "All downstream validation has completed");
    try t.expectError(error.WorkspaceNotReusable, workspace.compiler(&f.c, compiler_root));
    var e = f.engine();
    try workspaces.discover(&e);
    for (e.actions.items, 0..) |action, i| if (std.mem.eql(u8, action.path, w.record.temporary_root)) {
        try e.qualify(i);
        try mutation.apply(&e, i);
    };
    try t.expect(!u.exists(f.c.io, binary));
}

test "storage cleanup: copied roots use enclosing storage and native readers resolve split artifacts" {
    const f = try Fixture.init();
    defer f.deinit();
    const w = try workspaceFixture(f, true);
    w.close(&f.c);
    const original = f.c.root;
    for ([_][]const u8{ "docs", "tools" }) |dir| try f.c.mkdir(try f.c.join(&.{ run, dir }));
    try f.write(run ++ "/docs/storage_cleanup_policy.json", "{\"schema\":1}");
    try f.write(run ++ "/tools/clean-storage", "copied wrapper");
    f.c.root = try f.c.join(&.{run});
    try t.expectEqualStrings(original, (try @import("../validation/storage_lifecycle.zig").projectRoot(&f.c)).?);
    const logical = try f.c.join(&.{"objects/subject.o"});
    const physical = try workspace.artifact(&f.c, f.c.root, &.{logical});
    try t.expect(std.mem.indexOf(u8, physical, "/local-state/tmp/") != null);
    try t.expectEqualStrings("\x7fELFtemporary object", try f.c.read(physical));
    f.c.workspace_paths = .{ .evidence = f.c.root, .temporary = try f.c.fmt("{s}/{s}", .{ original, w.record.temporary_root }) };
    try t.expectEqualStrings(logical, try f.c.evidencePath(physical));
    try std.Io.Dir.cwd().deleteFile(f.c.io, physical);
    try t.expectEqualStrings(physical, try workspace.artifact(&f.c, f.c.root, &.{logical}));
    try t.expect(!u.exists(f.c.io, physical)); // no fallback or reconstruction
}

test "storage cleanup: a maintained compiler alias pin protects its temporary target" {
    const f = try Fixture.init();
    defer f.deinit();
    const w = try workspaceFixture(f, true);
    w.close(&f.c);
    var e = f.engine();
    const target = try f.c.fmt("{s}/objects/subject.o", .{w.record.temporary_root});
    const alias = run ++ "/compiler-alias";
    try std.Io.Dir.cwd().symLink(f.c.io, try e.absolute(target), try e.absolute(alias), .{});
    try f.write("current.sha256", try f.c.fmt("{s}  {s}\n", .{ try e.digest(target), alias }));
    e.config.current_manifests = &.{"current.sha256"};
    try workspaces.discover(&e);
    try e.qualify(0);
    try e.pins();
    try t.expectEqual(.skipped, e.actions.items[0].status);
    try e.currentManifests(true);
}

test "storage cleanup: reopening a compiler cannot overwrite unresolved failure diagnostics" {
    const f = try Fixture.init();
    defer f.deinit();
    const fixture = try workspaceFixture(f, true);
    fixture.close(&f.c);
    const root = try f.c.join(&.{ run, "failed-compiler" });
    try f.c.mkdir(root);
    const w = (try workspace.compiler(&f.c, root)).?;
    try f.c.writeJson(try f.c.join(&.{ root, "report.json" }), .{ .status = "failed", .diagnostic = "unique failed compiler preparation" });
    try w.finishReport(&f.c);
    w.close(&f.c);
    const hash = try f.c.digest(w.record_path);
    try t.expectError(error.WorkspaceNotReusable, workspace.compiler(&f.c, root));
    try t.expectEqualStrings(hash, try f.c.digest(w.record_path));
}

test "storage cleanup: external source checkout uses its explicit owner's workspace and terminal job" {
    const lifecycle = @import("../validation/storage_lifecycle.zig");
    const jobs = @import("jobs.zig");
    const f = try Fixture.init();
    defer f.deinit();
    const source = try Fixture.init();
    defer source.deinit();
    const initial = try workspaceFixture(f, true);
    initial.close(&f.c);
    const copied = try workspaceFixture(source, true);
    copied.close(&source.c);
    const owner = f.c.root;
    const evidence = try f.c.join(&.{run ++ "/external"});
    try f.c.env.put("ZLLVM_STORAGE_ROOT", owner);
    try f.c.env.put("ZLLVM_REQUIRE_MANAGED_STORAGE", "1");
    f.c.root = source.c.root;
    defer f.c.root = owner;
    try t.expectEqualStrings(owner, (try lifecycle.projectRoot(&f.c)).?);
    _ = try f.c.newOutput(evidence);
    const result_path = try f.c.fmt("{s}/run.json", .{evidence});
    const session = (try lifecycle.start(&f.c, evidence, result_path, 1)).?;
    defer session.close(&f.c);
    try t.expectEqualStrings(source.c.root, session.job.external_working_directory.?);
    const w = (try workspace.start(&f.c, evidence, "check")).?;
    defer w.close(&f.c);
    var env = try f.c.cleanEnvironment();
    try workspace.exportPaths(&f.c, &env);
    try t.expectEqualStrings(owner, env.get("ZLLVM_STORAGE_ROOT").?);
    try t.expectEqualStrings("1", env.get("ZLLVM_REQUIRE_MANAGED_STORAGE").?);
    f.c.env = env;
    f.c.workspace_paths = null;
    try workspace.adopt(&f.c);
    const product = try f.c.temporaryPath(&.{ evidence, "subject.o" });
    try t.expect(p.within(owner, product));
    try t.expect(!p.within(source.c.root, product));
    try f.c.write(product, "temporary object");
    try f.c.writeJson(result_path, .{ .status = "finished", .outcome = "completed", .returncode = 0, .actual_returncode = 0, .started_ns = 1, .finished_ns = 2, .cwd = source.c.root });
    try w.finish(&f.c, result_path, &.{});
    try session.finish(&f.c);
    f.c.root = owner;
    const saved = try std.json.parseFromValue(lifecycle.Job, f.c.a, try f.c.load(session.path), .{});
    var e = f.engine();
    try t.expect(try jobs.validate(&e, saved.value));
    try jobs.scan(&e, true); // does not infer ownership of the external checkout's caches
    try f.c.writeJson(result_path, .{ .status = "finished", .outcome = "completed", .actual_returncode = 0, .started_ns = 1, .finished_ns = 2, .cwd = owner });
    var wrong = saved.value;
    wrong.producer.sha256 = try f.c.digest(result_path);
    var fresh = f.engine();
    try t.expectError(error.CacheWorkingDirectoryMismatch, jobs.validate(&fresh, wrong));
}

test "storage cleanup: managed admission rejects source outputs and symlink escapes before creation" {
    const f = try Fixture.init();
    defer f.deinit();
    const source = try Fixture.init();
    defer source.deinit();
    const initial = try workspaceFixture(f, true);
    initial.close(&f.c);
    const owner = f.c.root;
    try f.c.env.put("ZLLVM_STORAGE_ROOT", owner);
    try f.c.env.put("ZLLVM_REQUIRE_MANAGED_STORAGE", "1");
    f.c.root = source.c.root;
    const bad = try source.c.join(&.{"local-state/isolated-validations/run"});
    try t.expectError(error.ValidationFailed, f.c.newOutput(bad));
    try t.expect(!u.exists(f.c.io, bad));
    try t.expectError(error.ValidationFailed, workspace.start(&f.c, bad, "validation"));
    const alias = try f.c.fmt("{s}/{s}/source-link", .{ owner, run });
    try std.Io.Dir.cwd().symLink(f.c.io, source.c.root, alias, .{});
    try t.expectError(error.ValidationFailed, f.c.newOutput(try f.c.fmt("{s}/escaped", .{alias})));
    try t.expect(!u.exists(f.c.io, try source.c.join(&.{"escaped"})));
    try f.c.env.put("ZLLVM_STORAGE_ROOT", source.c.root);
    try t.expectError(error.InvalidStorageOwner, f.c.newOutput(bad));
}

test "storage cleanup: external job source identities cannot become relative deletion scopes" {
    const lifecycle = @import("../validation/storage_lifecycle.zig");
    const jobs = @import("jobs.zig");
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    var job: lifecycle.Job = .{ .run_root = run, .working_directory = ".", .external_working_directory = "../source", .producer = .{ .path = report, .sha256 = "" }, .started_ns = 1 };
    try t.expectError(error.InvalidStorageJob, jobs.validate(&e, job));
    job.external_working_directory = "/tmp/source/../other";
    try t.expectError(error.InvalidStorageJob, jobs.validate(&e, job));
    job.external_working_directory = "/tmp/source";
    job.working_directory = run;
    try t.expectError(error.InvalidStorageJob, jobs.validate(&e, job));
}
