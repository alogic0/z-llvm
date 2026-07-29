const std = @import("std");
const builtin = @import("builtin");
const authority_control = @import("authority_control.zig");
const digest = @import("digest.zig");
const exact_real_observer = @import("exact_real_observer.zig");
const exact_real_receipt = @import("exact_real_receipt.zig");
const exact_real_runner = @import("exact_real_runner.zig");
const filesystem = @import("filesystem.zig");
const synthetic_fixture = @import("synthetic_fixture.zig");

const sha256Hex = digest.sha256Hex;
const dormant_exact_real_copy_evidence_max_bytes =
    authority_control.API.exact_real_copy_evidence_max_bytes;
const verifyDormantCopyEvidenceFromHeldRoot =
    authority_control.API.verifyCopyEvidenceFromHeldRoot;
const DormantReadinessNetEffects = exact_real_observer.API.NetEffects;
const DormantExactObserverRow = exact_real_observer.API.ObserverRow;
const DormantExactRealObservation = exact_real_observer.API.Observation;
const captureDormantExactObserverRowFromDir = exact_real_observer.API.captureRowFromDir;
const appendDormantExactObserverLogicalRow = exact_real_observer.API.appendLogicalRow;
const finishDormantExactObservation = exact_real_observer.API.finishObservation;
const compareDormantExactRealObservations = exact_real_observer.API.compareObservations;
const dormant_exact_real_acceptance_environment = exact_real_runner.acceptance_environment;
const runDormantExactRealAcceptanceForTest = exact_real_runner.runAcceptanceForTest;
const dormant_exact_real_acceptance_receipt_basename =
    exact_real_receipt.API.receipt_basename;
const DormantExactAcceptanceEvidence = exact_real_receipt.API.Evidence;
const parseDormantExactAcceptanceInteger = exact_real_receipt.API.parseInteger;
const encodeDormantExactAcceptanceReceipt = exact_real_receipt.API.encode;
const parseDormantExactAcceptanceReceipt = exact_real_receipt.API.parse;
const validateDormantExactAcceptanceReceipt = exact_real_receipt.API.validate;
const readDormantExactAcceptanceReceipt = exact_real_receipt.API.read;
const publishDormantExactAcceptanceReceipt = exact_real_receipt.API.publish;
const openPathNoFollow = filesystem.openPathNoFollow;
const writeCollisionFixtureAtomic = filesystem.writeCollisionFixtureAtomic;
const writeExclusive = filesystem.writeExclusive;
const writeDormantFixtureRelative = synthetic_fixture.API.writeRelative;
const deleteDormantFixtureRelative = synthetic_fixture.API.deleteRelative;
const replaceDormantFixtureRelative = synthetic_fixture.API.replaceRelative;
const expectDormantReadinessEffects = synthetic_fixture.API.expectReadinessEffects;

const dormant_acceptance_synthetic_hash_a =
    "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
const dormant_acceptance_synthetic_hash_b =
    "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb";
const dormant_acceptance_synthetic_hash_c =
    "cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc";
const dormant_acceptance_synthetic_hash_d =
    "dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd";
const dormant_acceptance_synthetic_hash_e =
    "eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee";
const dormant_acceptance_synthetic_hash_f =
    "ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff";

fn requireTest() !void {
    if (!builtin.is_test) return error.TestOnlyOperation;
}

fn dormantSyntheticExactAcceptanceEvidence() DormantExactAcceptanceEvidence {
    return .{
        .control_root = "/synthetic/control",
        .authority_root = "/synthetic/control/authority/zllvm/v1",
        .payload_root = "/synthetic/payload",
        .source_root = "/synthetic/source",
        .source_manifest_sha256 = dormant_acceptance_synthetic_hash_a,
        .source_inventory_sha256 = dormant_acceptance_synthetic_hash_b,
        .source_file_ledger_sha256 = dormant_acceptance_synthetic_hash_c,
        .source_destination_ledger_sha256 = dormant_acceptance_synthetic_hash_d,
        .copy_evidence_path = "docs/evidence/synthetic-copy-proof.md",
        .copy_evidence_sha256 = dormant_acceptance_synthetic_hash_e,
        .registration_full_sha256 = dormant_acceptance_synthetic_hash_a,
        .registration_path_sha256 = dormant_acceptance_synthetic_hash_b,
        .registration_topology_sha256 = dormant_acceptance_synthetic_hash_c,
        .registration_non_main_sha256 = dormant_acceptance_synthetic_hash_d,
        .before_snapshot = .{
            .bytes = 1234,
            .sha256 = dormant_acceptance_synthetic_hash_e[0..64].*,
        },
        .after_snapshot = .{
            .bytes = 1234,
            .sha256 = dormant_acceptance_synthetic_hash_e[0..64].*,
        },
        .validation = .{
            .manifest_sha256 = dormant_acceptance_synthetic_hash_f[0..64].*,
            .payload_files = 20,
            .payload_bytes = 9_970_364,
            .objects = 18,
            .snapshots = 2,
        },
        .effects = .{},
    };
}

const DormantExactObserverFixtureSpec = struct {
    label: []const u8,
    path: []const u8,
    unexpected_publication: bool = false,
};

fn captureDormantExactObserverFixture(
    allocator: std.mem.Allocator,
    io: std.Io,
    directory: std.Io.Dir,
    specs: []const DormantExactObserverFixtureSpec,
    logical_state: []const u8,
) !DormantExactRealObservation {
    try requireTest();
    var rows: std.ArrayList(DormantExactObserverRow) = .empty;
    errdefer {
        for (rows.items) |*row| row.deinit(allocator);
        rows.deinit(allocator);
    }
    for (specs) |spec| {
        try rows.append(
            allocator,
            try captureDormantExactObserverRowFromDir(
                allocator,
                io,
                directory,
                spec.path,
                spec.label,
                spec.path,
                spec.unexpected_publication,
            ),
        );
    }
    try appendDormantExactObserverLogicalRow(
        allocator,
        &rows,
        "logical:synthetic-authority",
        "logical://synthetic-authority",
        logical_state,
    );
    return finishDormantExactObservation(allocator, &rows);
}

fn expectDormantExactObserverEffects(
    before: *const DormantExactRealObservation,
    after: *const DormantExactRealObservation,
    expected: DormantReadinessNetEffects,
) !DormantReadinessNetEffects {
    try requireTest();
    const effects = compareDormantExactRealObservations(before, after);
    try expectDormantReadinessEffects(effects, expected);
    return effects;
}

fn expectDormantAcceptanceDirectoryEmpty(io: std.Io, directory: std.Io.Dir) !void {
    try requireTest();
    var iterator = directory.iterate();
    if (try iterator.next(io) != null) return error.DormantAcceptanceTemporaryRetained;
}

pub fn acceptanceGatePrecedesRealPaths() !void {
    try requireTest();
    const allocator = std.testing.allocator;
    const io = std.testing.io;
    try std.testing.expectError(
        error.SkipZigTest,
        runDormantExactRealAcceptanceForTest(allocator, io, null),
    );
    try std.testing.expectError(
        error.SkipZigTest,
        runDormantExactRealAcceptanceForTest(allocator, io, "invalid-token"),
    );
}

pub fn copyEvidenceVerifiesActualHeldRootBytes() !void {
    try requireTest();
    const allocator = std.testing.allocator;
    const io = std.testing.io;
    const evidence_path = "docs/evidence/copy-proof.md";
    const evidence_bytes = "synthetic exact-real copy evidence\n";
    const evidence_sha256 = sha256Hex(evidence_bytes);
    var fixture = std.testing.tmpDir(.{ .iterate = true });
    defer fixture.cleanup();
    var evidence_directory = try openPathNoFollow(io, fixture.dir, "docs/evidence", true);
    defer evidence_directory.close(io);

    try std.testing.expectError(
        error.DormantCopyEvidenceMissing,
        verifyDormantCopyEvidenceFromHeldRoot(
            allocator,
            io,
            fixture.dir,
            evidence_path,
            &evidence_sha256,
            dormant_exact_real_copy_evidence_max_bytes,
        ),
    );

    try writeExclusive(io, evidence_directory, "target.md", evidence_bytes, 0o664);
    try evidence_directory.symLink(io, "target.md", "copy-proof.md", .{});
    try std.testing.expectError(
        error.DormantCopyEvidenceUnsafe,
        verifyDormantCopyEvidenceFromHeldRoot(
            allocator,
            io,
            fixture.dir,
            evidence_path,
            &evidence_sha256,
            dormant_exact_real_copy_evidence_max_bytes,
        ),
    );
    try evidence_directory.deleteFile(io, "copy-proof.md");

    try evidence_directory.createDir(io, "copy-proof.md", .default_dir);
    try std.testing.expectError(
        error.DormantCopyEvidenceUnsafe,
        verifyDormantCopyEvidenceFromHeldRoot(
            allocator,
            io,
            fixture.dir,
            evidence_path,
            &evidence_sha256,
            dormant_exact_real_copy_evidence_max_bytes,
        ),
    );
    try evidence_directory.deleteDir(io, "copy-proof.md");

    try writeExclusive(io, evidence_directory, "copy-proof.md", evidence_bytes, 0o755);
    try std.testing.expectError(
        error.DormantCopyEvidenceExecutable,
        verifyDormantCopyEvidenceFromHeldRoot(
            allocator,
            io,
            fixture.dir,
            evidence_path,
            &evidence_sha256,
            dormant_exact_real_copy_evidence_max_bytes,
        ),
    );
    try evidence_directory.deleteFile(io, "copy-proof.md");

    try writeExclusive(io, evidence_directory, "copy-proof.md", evidence_bytes, 0o664);
    var wrong_sha256 = evidence_sha256;
    wrong_sha256[0] = if (wrong_sha256[0] == '0') '1' else '0';
    try std.testing.expectError(
        error.DormantCopyEvidenceMismatched,
        verifyDormantCopyEvidenceFromHeldRoot(
            allocator,
            io,
            fixture.dir,
            evidence_path,
            &wrong_sha256,
            dormant_exact_real_copy_evidence_max_bytes,
        ),
    );
    try std.testing.expectError(
        error.DormantCopyEvidenceTooLarge,
        verifyDormantCopyEvidenceFromHeldRoot(
            allocator,
            io,
            fixture.dir,
            evidence_path,
            &evidence_sha256,
            evidence_bytes.len - 1,
        ),
    );

    var identity = try verifyDormantCopyEvidenceFromHeldRoot(
        allocator,
        io,
        fixture.dir,
        evidence_path,
        &evidence_sha256,
        dormant_exact_real_copy_evidence_max_bytes,
    );
    defer identity.deinit(allocator);
    try std.testing.expectEqual(@as(u16, 0o664), identity.mode);
    try std.testing.expectEqual(@as(u64, evidence_bytes.len), identity.bytes);
    try std.testing.expectEqualSlices(u8, &evidence_sha256, &identity.sha256);
    try std.testing.expectError(
        error.FileNotFound,
        fixture.dir.statFile(io, "validation", .{ .follow_symlinks = false }),
    );
}

pub fn copyEvidenceIsUnchangedInFiniteObserver() !void {
    try requireTest();
    const allocator = std.testing.allocator;
    const io = std.testing.io;
    const evidence_path = "docs/evidence/copy-proof.md";
    const evidence_bytes = "synthetic observed copy evidence\n";
    const evidence_sha256 = sha256Hex(evidence_bytes);
    const specs = [_]DormantExactObserverFixtureSpec{.{
        .label = "copy-evidence-file:docs/evidence/copy-proof.md",
        .path = evidence_path,
    }};
    var fixture = std.testing.tmpDir(.{ .iterate = true });
    defer fixture.cleanup();
    try writeDormantFixtureRelative(io, fixture.dir, evidence_path, evidence_bytes, 0o664);
    var before = try captureDormantExactObserverFixture(
        allocator,
        io,
        fixture.dir,
        &specs,
        "copy-evidence-logical-state",
    );
    defer before.deinit();
    var identity = try verifyDormantCopyEvidenceFromHeldRoot(
        allocator,
        io,
        fixture.dir,
        evidence_path,
        &evidence_sha256,
        dormant_exact_real_copy_evidence_max_bytes,
    );
    identity.deinit(allocator);
    var after = try captureDormantExactObserverFixture(
        allocator,
        io,
        fixture.dir,
        &specs,
        "copy-evidence-logical-state",
    );
    defer after.deinit();
    const effects = try expectDormantExactObserverEffects(&before, &after, .{});
    try std.testing.expect(effects.isUnchanged());
    try std.testing.expectEqualSlices(u8, &before.identity.sha256, &after.identity.sha256);
}

pub fn acceptanceReceiptEncodingIsCanonical() !void {
    try requireTest();
    const allocator = std.testing.allocator;
    const evidence = dormantSyntheticExactAcceptanceEvidence();
    const first = try encodeDormantExactAcceptanceReceipt(allocator, evidence);
    defer allocator.free(first);
    const second = try encodeDormantExactAcceptanceReceipt(allocator, evidence);
    defer allocator.free(second);
    try std.testing.expectEqualSlices(u8, first, second);
    _ = try parseDormantExactAcceptanceReceipt(allocator, first);
    try validateDormantExactAcceptanceReceipt(allocator, first, evidence);

    const wrong_schema = try allocator.dupe(u8, first);
    defer allocator.free(wrong_schema);
    wrong_schema[0] = 'x';
    try std.testing.expectError(
        error.NonCanonicalExactAcceptanceReceipt,
        parseDormantExactAcceptanceReceipt(allocator, wrong_schema),
    );

    var wrong_identity = evidence;
    wrong_identity.source_manifest_sha256 = dormant_acceptance_synthetic_hash_f;
    const wrong_identity_receipt = try encodeDormantExactAcceptanceReceipt(
        allocator,
        wrong_identity,
    );
    defer allocator.free(wrong_identity_receipt);
    try std.testing.expectError(
        error.DormantAcceptanceReceiptEvidenceMismatch,
        validateDormantExactAcceptanceReceipt(
            allocator,
            wrong_identity_receipt,
            evidence,
        ),
    );
}

pub fn observerDetectsFinitePathAndLogicalControls() !void {
    try requireTest();
    const allocator = std.testing.allocator;
    const io = std.testing.io;
    var fixture = std.testing.tmpDir(.{ .iterate = true });
    defer fixture.cleanup();
    const specs = [_]DormantExactObserverFixtureSpec{
        .{ .label = "path:created", .path = "created" },
        .{ .label = "path:removed", .path = "removed" },
        .{ .label = "path:content", .path = "content" },
        .{ .label = "path:mode", .path = "mode" },
        .{ .label = "path:type", .path = "type" },
        .{
            .label = "unexpected-publication:synthetic",
            .path = "unexpected-publication",
            .unexpected_publication = true,
        },
    };
    try writeDormantFixtureRelative(io, fixture.dir, "removed", "removed\n", 0o644);
    try writeDormantFixtureRelative(io, fixture.dir, "content", "before\n", 0o644);
    try writeDormantFixtureRelative(io, fixture.dir, "mode", "mode\n", 0o644);
    try writeDormantFixtureRelative(io, fixture.dir, "type", "type\n", 0o644);
    var baseline = try captureDormantExactObserverFixture(
        allocator,
        io,
        fixture.dir,
        &specs,
        "logical-before",
    );
    defer baseline.deinit();

    try writeDormantFixtureRelative(io, fixture.dir, "created", "created\n", 0o644);
    var created = try captureDormantExactObserverFixture(
        allocator,
        io,
        fixture.dir,
        &specs,
        "logical-before",
    );
    defer created.deinit();
    _ = try expectDormantExactObserverEffects(
        &baseline,
        &created,
        .{ .created_paths = 1 },
    );
    try deleteDormantFixtureRelative(io, fixture.dir, "created");

    try deleteDormantFixtureRelative(io, fixture.dir, "removed");
    var removed = try captureDormantExactObserverFixture(
        allocator,
        io,
        fixture.dir,
        &specs,
        "logical-before",
    );
    defer removed.deinit();
    _ = try expectDormantExactObserverEffects(
        &baseline,
        &removed,
        .{ .removed_paths = 1 },
    );
    try writeDormantFixtureRelative(io, fixture.dir, "removed", "removed\n", 0o644);

    try replaceDormantFixtureRelative(io, fixture.dir, "content", "after\n", 0o644);
    var content = try captureDormantExactObserverFixture(
        allocator,
        io,
        fixture.dir,
        &specs,
        "logical-before",
    );
    defer content.deinit();
    _ = try expectDormantExactObserverEffects(
        &baseline,
        &content,
        .{ .modified_paths = 1 },
    );
    try replaceDormantFixtureRelative(io, fixture.dir, "content", "before\n", 0o644);

    try fixture.dir.setFilePermissions(
        io,
        "mode",
        .fromMode(0o600),
        .{ .follow_symlinks = false },
    );
    var mode = try captureDormantExactObserverFixture(
        allocator,
        io,
        fixture.dir,
        &specs,
        "logical-before",
    );
    defer mode.deinit();
    _ = try expectDormantExactObserverEffects(
        &baseline,
        &mode,
        .{ .modified_paths = 1 },
    );
    try fixture.dir.setFilePermissions(
        io,
        "mode",
        .fromMode(0o644),
        .{ .follow_symlinks = false },
    );

    try fixture.dir.deleteFile(io, "type");
    try fixture.dir.createDir(io, "type", .default_dir);
    var kind = try captureDormantExactObserverFixture(
        allocator,
        io,
        fixture.dir,
        &specs,
        "logical-before",
    );
    defer kind.deinit();
    _ = try expectDormantExactObserverEffects(
        &baseline,
        &kind,
        .{ .modified_paths = 1 },
    );
    try fixture.dir.deleteDir(io, "type");
    try writeDormantFixtureRelative(io, fixture.dir, "type", "type\n", 0o644);

    var logical = try captureDormantExactObserverFixture(
        allocator,
        io,
        fixture.dir,
        &specs,
        "logical-after",
    );
    defer logical.deinit();
    _ = try expectDormantExactObserverEffects(
        &baseline,
        &logical,
        .{ .logical_state_modified = true },
    );

    try writeDormantFixtureRelative(
        io,
        fixture.dir,
        "unexpected-publication",
        "unexpected\n",
        0o644,
    );
    var publication = try captureDormantExactObserverFixture(
        allocator,
        io,
        fixture.dir,
        &specs,
        "logical-before",
    );
    defer publication.deinit();
    _ = try expectDormantExactObserverEffects(
        &baseline,
        &publication,
        .{ .created_paths = 1, .publication_path_changes = 1 },
    );

    try writeDormantFixtureRelative(io, fixture.dir, "created", "created\n", 0o644);
    try deleteDormantFixtureRelative(io, fixture.dir, "removed");
    try replaceDormantFixtureRelative(io, fixture.dir, "content", "after\n", 0o644);
    try fixture.dir.setFilePermissions(
        io,
        "mode",
        .fromMode(0o600),
        .{ .follow_symlinks = false },
    );
    try fixture.dir.deleteFile(io, "type");
    try fixture.dir.createDir(io, "type", .default_dir);
    var combined = try captureDormantExactObserverFixture(
        allocator,
        io,
        fixture.dir,
        &specs,
        "logical-after",
    );
    defer combined.deinit();
    const combined_effects = try expectDormantExactObserverEffects(
        &baseline,
        &combined,
        .{
            .created_paths = 2,
            .removed_paths = 1,
            .modified_paths = 3,
            .publication_path_changes = 1,
            .logical_state_modified = true,
        },
    );

    var evidence = dormantSyntheticExactAcceptanceEvidence();
    evidence.effects = combined_effects;
    const receipt = try encodeDormantExactAcceptanceReceipt(allocator, evidence);
    defer allocator.free(receipt);
    const parsed = try parseDormantExactAcceptanceReceipt(allocator, receipt);
    try std.testing.expectEqual(
        @as(u64, combined_effects.created_paths),
        try parseDormantExactAcceptanceInteger(parsed.fields[25]),
    );
    try std.testing.expectEqual(
        @as(u64, combined_effects.removed_paths),
        try parseDormantExactAcceptanceInteger(parsed.fields[26]),
    );
    try std.testing.expectEqual(
        @as(u64, combined_effects.modified_paths),
        try parseDormantExactAcceptanceInteger(parsed.fields[27]),
    );
    try std.testing.expectEqual(
        @as(u64, combined_effects.publication_path_changes),
        try parseDormantExactAcceptanceInteger(parsed.fields[28]),
    );
    try std.testing.expectEqualStrings("true", parsed.fields[29]);
}

pub fn acceptanceReceiptPublicationIsDurableAndNoReplace() !void {
    try requireTest();
    const allocator = std.testing.allocator;
    const io = std.testing.io;
    const evidence = dormantSyntheticExactAcceptanceEvidence();
    const receipt = try encodeDormantExactAcceptanceReceipt(allocator, evidence);
    defer allocator.free(receipt);

    var partial = std.testing.tmpDir(.{ .iterate = true });
    defer partial.cleanup();
    try std.testing.expectError(
        error.DormantAcceptanceSyntheticPublicationFailure,
        publishDormantExactAcceptanceReceipt(
            allocator,
            io,
            partial.dir,
            receipt,
            evidence,
            .before_link,
        ),
    );
    try expectDormantAcceptanceDirectoryEmpty(io, partial.dir);

    var success = std.testing.tmpDir(.{ .iterate = true });
    defer success.cleanup();
    try publishDormantExactAcceptanceReceipt(
        allocator,
        io,
        success.dir,
        receipt,
        evidence,
        .none,
    );
    const readback = try readDormantExactAcceptanceReceipt(
        allocator,
        io,
        success.dir,
        dormant_exact_real_acceptance_receipt_basename,
    );
    defer allocator.free(readback);
    try std.testing.expectEqualSlices(u8, receipt, readback);

    var collision = std.testing.tmpDir(.{ .iterate = true });
    defer collision.cleanup();
    const retained = "retained collision\n";
    try writeCollisionFixtureAtomic(
        io,
        collision.dir,
        dormant_exact_real_acceptance_receipt_basename,
        retained,
        0o644,
    );
    try std.testing.expectError(
        error.DormantAcceptanceReceiptCollision,
        publishDormantExactAcceptanceReceipt(
            allocator,
            io,
            collision.dir,
            receipt,
            evidence,
            .none,
        ),
    );
    const collision_readback = try readDormantExactAcceptanceReceipt(
        allocator,
        io,
        collision.dir,
        dormant_exact_real_acceptance_receipt_basename,
    );
    defer allocator.free(collision_readback);
    try std.testing.expectEqualStrings(retained, collision_readback);
}

pub fn acceptanceOneShot() !void {
    try requireTest();
    const allocator = std.testing.allocator;
    const token = std.testing.environ.getAlloc(
        allocator,
        dormant_exact_real_acceptance_environment,
    ) catch |err| switch (err) {
        error.EnvironmentVariableMissing => null,
        else => return err,
    };
    defer if (token) |value| allocator.free(value);
    try runDormantExactRealAcceptanceForTest(std.testing.allocator, std.testing.io, token);
}
