const std = @import("std");
const builtin = @import("builtin");
const authority_control = @import("authority_control.zig");
const digest = @import("digest.zig");
const exact_real_runner = @import("exact_real_runner.zig");
const filesystem = @import("filesystem.zig");
const registration = @import("registration.zig");
const synthetic_fixture = @import("synthetic_fixture.zig");

const main_repository = registration.main_repository;
const sha256Hex = digest.sha256Hex;
const dormant_candidate_key = authority_control.API.candidate_key;
const dormant_generation_key = authority_control.API.generation_key;
const dormant_lineage_key = authority_control.API.lineage_key;
const dormant_receipt_key = authority_control.API.receipt_key;
const dormant_candidate_magic = authority_control.API.candidate_magic;
const dormant_lineage_magic = authority_control.API.lineage_magic;
const dormant_receipt_magic = authority_control.API.receipt_magic;
const dormant_real_control_root = authority_control.API.real_control_root;
const dormant_real_payload_root = authority_control.API.real_payload_root;
const dormant_real_source_root = authority_control.API.real_source_root;
const ControlGitObservation = authority_control.API.ControlObservation;
const DormantControlFileExpectationSpec =
    authority_control.API.ControlFileExpectationSpec;
const DormantAuthorityConfig = authority_control.API.AuthorityConfig;
const DormantAuthorityValidation = authority_control.API.AuthorityValidation;
const readDormantControlFile = authority_control.API.readControlFile;
const callDormantValidationReadinessForTest = exact_real_runner.callValidationReadiness;
const openPathNoFollow = filesystem.openPathNoFollow;
const dormant_test_root = synthetic_fixture.API.test_root;
const dormant_test_source_inventory_sha256 = synthetic_fixture.API.source_inventory_sha256;
const dormant_test_source_file_ledger_sha256 = synthetic_fixture.API.source_file_ledger_sha256;
const dormant_test_source_destination_ledger_sha256 =
    synthetic_fixture.API.source_destination_ledger_sha256;
const dormant_test_copy_evidence_path = synthetic_fixture.API.copy_evidence_path;
const dormant_test_copy_evidence_sha256 = synthetic_fixture.API.copy_evidence_sha256;
const DormantSyntheticFixture = synthetic_fixture.API.Fixture;
const writeDormantFixtureRelative = synthetic_fixture.API.writeRelative;
const setDormantAbsoluteDirectoryMode = synthetic_fixture.API.setAbsoluteDirectoryMode;
const deleteDormantFixtureRelative = synthetic_fixture.API.deleteRelative;
const replaceDormantTestOwnedBytes = synthetic_fixture.API.replaceOwnedBytes;
const restoreDormantTestOwnedBytes = synthetic_fixture.API.restoreOwnedBytes;
const captureDormantReadinessState = synthetic_fixture.API.captureReadinessState;
const compareDormantReadinessStates = synthetic_fixture.API.compareReadinessStates;
const expectDormantReadinessEffects = synthetic_fixture.API.expectReadinessEffects;
const exerciseDormantReadinessOwnershipFailure =
    synthetic_fixture.API.exerciseReadinessOwnershipFailure;

fn requireTest() !void {
    if (!builtin.is_test) return error.TestOnlyOperation;
}

fn expectDormantReceiptIdentityMismatch(
    fixture: *DormantSyntheticFixture,
    config: *const DormantAuthorityConfig,
    receipt: []const u8,
) !void {
    try requireTest();
    const candidate = try fixture.candidateFor(
        fixture.allocator,
        fixture.manifest,
        fixture.lineage,
        receipt,
        "candidate",
    );
    defer fixture.allocator.free(candidate);
    try fixture.replaceControl(dormant_receipt_key, receipt);
    try fixture.replaceControl(dormant_candidate_key, candidate);
    try expectDormantReadinessRejection(
        fixture,
        config,
        error.DormantReceiptMismatched,
    );
    try fixture.replaceControl(dormant_receipt_key, fixture.receipt);
    try fixture.replaceControl(dormant_candidate_key, fixture.candidate);
}

fn expectDormantReadinessRejection(
    fixture: *const DormantSyntheticFixture,
    config: *const DormantAuthorityConfig,
    expected_error: anyerror,
) !void {
    try requireTest();
    var before = try captureDormantReadinessState(fixture, config);
    defer before.deinit();
    if (callDormantValidationReadinessForTest(.{ .synthetic = config })) |_| {
        return error.ExpectedDormantValidationRejection;
    } else |actual_error| {
        try std.testing.expectEqual(expected_error, actual_error);
    }
    var after = try captureDormantReadinessState(fixture, config);
    defer after.deinit();
    const effects = compareDormantReadinessStates(&before, &after);
    try std.testing.expect(effects.isUnchanged());
}

fn expectDormantReadinessSuccess(
    fixture: *const DormantSyntheticFixture,
    config: *const DormantAuthorityConfig,
) !DormantAuthorityValidation {
    try requireTest();
    var before = try captureDormantReadinessState(fixture, config);
    defer before.deinit();
    const validation = try callDormantValidationReadinessForTest(.{ .synthetic = config });
    var after = try captureDormantReadinessState(fixture, config);
    defer after.deinit();
    const effects = compareDormantReadinessStates(&before, &after);
    try std.testing.expect(effects.isUnchanged());
    return validation;
}

fn testDormantReadinessObserverControls(
    fixture: *DormantSyntheticFixture,
    config: *const DormantAuthorityConfig,
) !void {
    try requireTest();
    var baseline = try captureDormantReadinessState(fixture, config);
    defer baseline.deinit();

    try fixture.replaceControl(dormant_candidate_key, "readiness modified content\n");
    var modified = try captureDormantReadinessState(fixture, config);
    defer modified.deinit();
    try expectDormantReadinessEffects(
        compareDormantReadinessStates(&baseline, &modified),
        .{ .modified_paths = 1 },
    );
    try fixture.replaceControl(dormant_candidate_key, fixture.candidate);
    var modification_restored = try captureDormantReadinessState(fixture, config);
    defer modification_restored.deinit();
    try std.testing.expect(
        compareDormantReadinessStates(&baseline, &modification_restored).isUnchanged(),
    );

    const created_path = "readiness-observer-created";
    var payload = try std.Io.Dir.openDirAbsolute(fixture.io, fixture.payload_root, .{
        .access_sub_paths = true,
        .iterate = true,
        .follow_symlinks = false,
    });
    defer payload.close(fixture.io);
    try writeDormantFixtureRelative(fixture.io, payload, created_path, "created\n", 0o444);
    var created = try captureDormantReadinessState(fixture, config);
    defer created.deinit();
    try expectDormantReadinessEffects(
        compareDormantReadinessStates(&baseline, &created),
        .{ .created_paths = 1 },
    );
    try deleteDormantFixtureRelative(fixture.io, payload, created_path);
    var removed = try captureDormantReadinessState(fixture, config);
    defer removed.deinit();
    try expectDormantReadinessEffects(
        compareDormantReadinessStates(&created, &removed),
        .{ .removed_paths = 1 },
    );
    try std.testing.expect(compareDormantReadinessStates(&baseline, &removed).isUnchanged());

    const publication_path =
        "authority/zllvm/v1/receipts/publication/readiness-observer.tsv";
    var control = try std.Io.Dir.openDirAbsolute(fixture.io, fixture.control_root, .{
        .access_sub_paths = true,
        .iterate = true,
        .follow_symlinks = false,
    });
    defer control.close(fixture.io);
    try writeDormantFixtureRelative(
        fixture.io,
        control,
        publication_path,
        "publication-shaped\n",
        0o644,
    );
    var publication = try captureDormantReadinessState(fixture, config);
    defer publication.deinit();
    try expectDormantReadinessEffects(
        compareDormantReadinessStates(&baseline, &publication),
        .{ .created_paths = 1, .publication_path_changes = 1 },
    );
    try deleteDormantFixtureRelative(fixture.io, control, publication_path);
    var publication_restored = try captureDormantReadinessState(fixture, config);
    defer publication_restored.deinit();
    try std.testing.expect(
        compareDormantReadinessStates(&baseline, &publication_restored).isUnchanged(),
    );
}

pub fn readinessSnapshotOwnershipUnwindsLaterAllocationFailure() !void {
    try requireTest();
    var failing = std.testing.FailingAllocator.init(std.testing.allocator, .{
        .fail_index = 4,
    });
    var appended_entries: usize = 0;
    try std.testing.expectError(
        error.OutOfMemory,
        exerciseDormantReadinessOwnershipFailure(failing.allocator(), &appended_entries),
    );
    try std.testing.expect(failing.has_induced_failure);
    try std.testing.expectEqual(@as(usize, 1), appended_entries);
    try std.testing.expectEqual(failing.allocated_bytes, failing.freed_bytes);
}

pub fn authorityCandidateValidatesOnlyClosedSyntheticState() !void {
    try requireTest();
    const allocator = std.testing.allocator;
    const io = std.testing.io;
    _ = &DormantAuthorityConfig.initExactRealCandidate;
    var fixture = try DormantSyntheticFixture.init(allocator, io);
    var completed = false;
    defer if (!completed) std.debug.print(
        "INBOX-205A retain-on-failure synthetic_root={s}\n",
        .{dormant_test_root},
    );
    const candidate_sha = sha256Hex(fixture.candidate);
    const generation_sha = sha256Hex(fixture.manifest);
    const lineage_sha = sha256Hex(fixture.lineage);
    const receipt_sha = sha256Hex(fixture.receipt);
    const control_file_specs = [_]DormantControlFileExpectationSpec{
        .{
            .component = .candidate,
            .path = dormant_candidate_key,
            .sha256 = &candidate_sha,
            .bytes = fixture.candidate.len,
            .mode = 0o644,
        },
        .{
            .component = .generation,
            .path = dormant_generation_key,
            .sha256 = &generation_sha,
            .bytes = fixture.manifest.len,
            .mode = 0o644,
        },
        .{
            .component = .lineage,
            .path = dormant_lineage_key,
            .sha256 = &lineage_sha,
            .bytes = fixture.lineage.len,
            .mode = 0o644,
        },
        .{
            .component = .receipt,
            .path = dormant_receipt_key,
            .sha256 = &receipt_sha,
            .bytes = fixture.receipt.len,
            .mode = 0o644,
        },
    };
    var rejected_real_observation =
        try ControlGitObservation.initSyntheticExpected(allocator);
    try std.testing.expectError(
        error.DormantUnsafeRoot,
        DormantAuthorityConfig.initSynthetic(
            allocator,
            io,
            main_repository,
            dormant_real_control_root,
            dormant_real_payload_root,
            dormant_real_source_root,
            dormant_real_control_root,
            &.{fixture.non_main_root},
            &rejected_real_observation,
            &control_file_specs,
            &fixture.source_manifest_sha256,
            dormant_test_source_inventory_sha256,
            dormant_test_source_file_ledger_sha256,
            dormant_test_source_destination_ledger_sha256,
            dormant_test_copy_evidence_path,
            dormant_test_copy_evidence_sha256,
        ),
    );
    rejected_real_observation.deinit();
    var observed_control = try ControlGitObservation.initSyntheticExpected(allocator);
    var config = try DormantAuthorityConfig.initSynthetic(
        allocator,
        io,
        fixture.main_root,
        fixture.control_root,
        fixture.payload_root,
        fixture.source_root,
        fixture.control_root,
        &.{fixture.non_main_root},
        &observed_control,
        &control_file_specs,
        &fixture.source_manifest_sha256,
        dormant_test_source_inventory_sha256,
        dormant_test_source_file_ledger_sha256,
        dormant_test_source_destination_ledger_sha256,
        dormant_test_copy_evidence_path,
        dormant_test_copy_evidence_sha256,
    );
    defer config.deinit();

    try testDormantReadinessObserverControls(&fixture, &config);
    const positive = try expectDormantReadinessSuccess(&fixture, &config);
    try std.testing.expectEqual(@as(u64, 3), positive.payload_files);
    try std.testing.expectEqual(
        @as(u64, fixture.payload.len + fixture.constituent.len + fixture.snapshot.len),
        positive.payload_bytes,
    );
    try std.testing.expectEqual(@as(u64, 2), positive.objects);
    try std.testing.expectEqual(@as(u64, 1), positive.snapshots);
    try std.testing.expectEqualStrings(&sha256Hex(fixture.manifest), &positive.manifest_sha256);

    std.mem.swap([]u8, &config.payload_root, &config.source_root);
    try expectDormantReadinessRejection(&fixture, &config, error.DormantUnsafeRoot);
    std.mem.swap([]u8, &config.payload_root, &config.source_root);

    const previous_payload_root = try replaceDormantTestOwnedBytes(
        allocator,
        &config.payload_root,
        fixture.root,
    );
    try expectDormantReadinessRejection(&fixture, &config, error.DormantUnsafeRoot);
    restoreDormantTestOwnedBytes(
        allocator,
        &config.payload_root,
        previous_payload_root,
    );

    try setDormantAbsoluteDirectoryMode(io, fixture.control_root, 0o755);
    try expectDormantReadinessRejection(&fixture, &config, error.DormantUnsafeRoot);
    try setDormantAbsoluteDirectoryMode(io, fixture.control_root, 0o775);

    try setDormantAbsoluteDirectoryMode(io, config.authority_root, 0o775);
    try expectDormantReadinessRejection(&fixture, &config, error.DormantUnsafeRoot);
    try setDormantAbsoluteDirectoryMode(io, config.authority_root, 0o755);

    try setDormantAbsoluteDirectoryMode(io, fixture.payload_root, 0o775);
    try expectDormantReadinessRejection(&fixture, &config, error.DormantUnsafeRoot);
    try setDormantAbsoluteDirectoryMode(io, fixture.payload_root, 0o755);

    try setDormantAbsoluteDirectoryMode(io, fixture.source_root, 0o755);
    try expectDormantReadinessRejection(&fixture, &config, error.DormantUnsafeRoot);
    try setDormantAbsoluteDirectoryMode(io, fixture.source_root, 0o775);

    var fixture_root = try std.Io.Dir.openDirAbsolute(io, fixture.root, .{
        .access_sub_paths = true,
        .iterate = true,
        .follow_symlinks = false,
    });
    try fixture_root.symLink(io, "external-source", "source-link", .{});
    const source_link = try std.fs.path.join(allocator, &.{ fixture.root, "source-link" });
    defer allocator.free(source_link);
    const previous_config_source = try replaceDormantTestOwnedBytes(
        allocator,
        &config.source_root,
        source_link,
    );
    const previous_policy_source = try replaceDormantTestOwnedBytes(
        allocator,
        &config.root_policy.source_root,
        source_link,
    );
    try expectDormantReadinessRejection(&fixture, &config, error.DormantUnsafeRoot);
    restoreDormantTestOwnedBytes(
        allocator,
        &config.root_policy.source_root,
        previous_policy_source,
    );
    restoreDormantTestOwnedBytes(
        allocator,
        &config.source_root,
        previous_config_source,
    );
    try fixture_root.deleteFile(io, "source-link");
    fixture_root.close(io);

    try std.testing.expectError(
        error.DormantCandidateUnsafe,
        readDormantControlFile(
            &config,
            .candidate,
            "authority/zllvm/v1/manifests/unlisted.tsv",
        ),
    );

    const previous_non_main = try replaceDormantTestOwnedBytes(
        allocator,
        &config.root_policy.non_main_roots[0],
        fixture.payload_root,
    );
    try expectDormantReadinessRejection(&fixture, &config, error.DormantUnsafeRoot);
    restoreDormantTestOwnedBytes(
        allocator,
        &config.root_policy.non_main_roots[0],
        previous_non_main,
    );

    const previous_supplemental = try replaceDormantTestOwnedBytes(
        allocator,
        &config.root_policy.supplemental_control_root,
        fixture.payload_root,
    );
    try expectDormantReadinessRejection(&fixture, &config, error.DormantUnsafeRoot);
    restoreDormantTestOwnedBytes(
        allocator,
        &config.root_policy.supplemental_control_root,
        previous_supplemental,
    );

    config.root_policy.observed_control.commit[0] = 'c';
    try expectDormantReadinessRejection(&fixture, &config, error.DormantUnsafeRoot);
    config.root_policy.observed_control.commit[0] = 'a';

    config.root_policy.observed_control.tree[0] = 'c';
    try expectDormantReadinessRejection(&fixture, &config, error.DormantUnsafeRoot);
    config.root_policy.observed_control.tree[0] = 'b';

    config.root_policy.observed_control.branch[0] = 'x';
    try expectDormantReadinessRejection(&fixture, &config, error.DormantUnsafeRoot);
    config.root_policy.observed_control.branch[0] = 'm';

    const previous_status = try replaceDormantTestOwnedBytes(
        allocator,
        &config.root_policy.observed_control.status,
        " M candidate.tsv\n",
    );
    try expectDormantReadinessRejection(&fixture, &config, error.DormantUnsafeRoot);
    restoreDormantTestOwnedBytes(
        allocator,
        &config.root_policy.observed_control.status,
        previous_status,
    );

    const previous_remotes = try replaceDormantTestOwnedBytes(
        allocator,
        &config.root_policy.observed_control.remotes,
        "origin\n",
    );
    try expectDormantReadinessRejection(&fixture, &config, error.DormantUnsafeRoot);
    restoreDormantTestOwnedBytes(
        allocator,
        &config.root_policy.observed_control.remotes,
        previous_remotes,
    );

    config.root_policy.observed_control.entries[0].object_id[0] = '5';
    try expectDormantReadinessRejection(&fixture, &config, error.DormantUnsafeRoot);
    config.root_policy.observed_control.entries[0].object_id[0] = '1';

    config.root_policy.kind = .exact_real;
    config.root_policy.control_files[0].sha256[0] =
        if (candidate_sha[0] == '0') '1' else '0';
    try expectDormantReadinessRejection(
        &fixture,
        &config,
        error.DormantCandidateMismatched,
    );
    config.root_policy.control_files[0].sha256[0] = candidate_sha[0];
    config.root_policy.kind = .synthetic_test;

    try fixture.deleteControl(dormant_candidate_key);
    try expectDormantReadinessRejection(&fixture, &config, error.DormantCandidateMissing);
    try fixture.replaceControl(dormant_candidate_key, fixture.candidate);

    const mismatched_candidate = try fixture.candidateFor(
        allocator,
        fixture.manifest,
        fixture.lineage,
        fixture.receipt,
        "active",
    );
    defer allocator.free(mismatched_candidate);
    try fixture.replaceControl(dormant_candidate_key, mismatched_candidate);
    try expectDormantReadinessRejection(
        &fixture,
        &config,
        error.DormantCandidateMismatched,
    );
    try fixture.replaceControl(dormant_candidate_key, fixture.candidate);

    try fixture.deleteControl(dormant_generation_key);
    try expectDormantReadinessRejection(&fixture, &config, error.DormantGenerationMissing);
    try fixture.replaceControl(dormant_generation_key, fixture.manifest);

    const bad_generation = "not-a-manifest\n";
    try fixture.replaceControl(dormant_generation_key, bad_generation);
    try expectDormantReadinessRejection(
        &fixture,
        &config,
        error.DormantGenerationMismatched,
    );
    try fixture.replaceControl(dormant_generation_key, fixture.manifest);

    const bad_generation_candidate = try fixture.candidateFor(
        allocator,
        bad_generation,
        fixture.lineage,
        fixture.receipt,
        "candidate",
    );
    defer allocator.free(bad_generation_candidate);
    try fixture.replaceControl(dormant_generation_key, bad_generation);
    try fixture.replaceControl(dormant_candidate_key, bad_generation_candidate);
    try expectDormantReadinessRejection(
        &fixture,
        &config,
        error.DormantGenerationMalformed,
    );
    try fixture.replaceControl(dormant_generation_key, fixture.manifest);
    try fixture.replaceControl(dormant_candidate_key, fixture.candidate);

    try fixture.deleteControl(dormant_generation_key);
    try fixture.symlinkControl(dormant_generation_key, "candidate.tsv");
    try expectDormantReadinessRejection(&fixture, &config, error.DormantGenerationUnsafe);
    try fixture.deleteControl(dormant_generation_key);
    try fixture.replaceControl(dormant_generation_key, fixture.manifest);

    const malformed_candidate = dormant_candidate_magic ++ "\nwrong-header\nrow\n";
    try fixture.replaceControl(dormant_candidate_key, malformed_candidate);
    try expectDormantReadinessRejection(&fixture, &config, error.DormantCandidateMalformed);
    try fixture.replaceControl(dormant_candidate_key, fixture.candidate);

    try fixture.deleteControl(dormant_lineage_key);
    try expectDormantReadinessRejection(&fixture, &config, error.DormantLineageMissing);
    try fixture.replaceControl(dormant_lineage_key, fixture.lineage);

    const wrong_lineage = fixture.lineage[0 .. fixture.lineage.len - 1];
    try fixture.replaceControl(dormant_lineage_key, wrong_lineage);
    try expectDormantReadinessRejection(&fixture, &config, error.DormantLineageMismatched);
    try fixture.replaceControl(dormant_lineage_key, fixture.lineage);

    const bad_lineage = dormant_lineage_magic ++ "\nwrong-header\nrow\n";
    const bad_lineage_candidate = try fixture.candidateFor(
        allocator,
        fixture.manifest,
        bad_lineage,
        fixture.receipt,
        "candidate",
    );
    defer allocator.free(bad_lineage_candidate);
    try fixture.replaceControl(dormant_lineage_key, bad_lineage);
    try fixture.replaceControl(dormant_candidate_key, bad_lineage_candidate);
    try expectDormantReadinessRejection(&fixture, &config, error.DormantLineageMalformed);
    try fixture.replaceControl(dormant_lineage_key, fixture.lineage);
    try fixture.replaceControl(dormant_candidate_key, fixture.candidate);

    try fixture.deleteControl(dormant_lineage_key);
    try fixture.symlinkControl(dormant_lineage_key, "../manifests/candidate.tsv");
    try expectDormantReadinessRejection(&fixture, &config, error.DormantLineageUnsafe);
    try fixture.deleteControl(dormant_lineage_key);
    try fixture.replaceControl(dormant_lineage_key, fixture.lineage);

    try fixture.deleteControl(dormant_receipt_key);
    try expectDormantReadinessRejection(&fixture, &config, error.DormantReceiptMissing);
    try fixture.replaceControl(dormant_receipt_key, fixture.receipt);

    const wrong_receipt = fixture.receipt[0 .. fixture.receipt.len - 1];
    try fixture.replaceControl(dormant_receipt_key, wrong_receipt);
    try expectDormantReadinessRejection(&fixture, &config, error.DormantReceiptMismatched);
    try fixture.replaceControl(dormant_receipt_key, fixture.receipt);

    const receipt_mismatch_sha =
        "5555555555555555555555555555555555555555555555555555555555555555";
    const receipt_source_inventory_mismatch = try fixture.receiptFor(
        allocator,
        receipt_mismatch_sha,
        dormant_test_source_file_ledger_sha256,
        dormant_test_source_destination_ledger_sha256,
        dormant_test_copy_evidence_path,
        dormant_test_copy_evidence_sha256,
    );
    defer allocator.free(receipt_source_inventory_mismatch);
    try expectDormantReceiptIdentityMismatch(
        &fixture,
        &config,
        receipt_source_inventory_mismatch,
    );

    const receipt_source_file_ledger_mismatch = try fixture.receiptFor(
        allocator,
        dormant_test_source_inventory_sha256,
        receipt_mismatch_sha,
        dormant_test_source_destination_ledger_sha256,
        dormant_test_copy_evidence_path,
        dormant_test_copy_evidence_sha256,
    );
    defer allocator.free(receipt_source_file_ledger_mismatch);
    try expectDormantReceiptIdentityMismatch(
        &fixture,
        &config,
        receipt_source_file_ledger_mismatch,
    );

    const receipt_source_destination_ledger_mismatch = try fixture.receiptFor(
        allocator,
        dormant_test_source_inventory_sha256,
        dormant_test_source_file_ledger_sha256,
        receipt_mismatch_sha,
        dormant_test_copy_evidence_path,
        dormant_test_copy_evidence_sha256,
    );
    defer allocator.free(receipt_source_destination_ledger_mismatch);
    try expectDormantReceiptIdentityMismatch(
        &fixture,
        &config,
        receipt_source_destination_ledger_mismatch,
    );

    const receipt_copy_evidence_path_mismatch = try fixture.receiptFor(
        allocator,
        dormant_test_source_inventory_sha256,
        dormant_test_source_file_ledger_sha256,
        dormant_test_source_destination_ledger_sha256,
        "docs/evidence/other-synthetic-copy-proof.md",
        dormant_test_copy_evidence_sha256,
    );
    defer allocator.free(receipt_copy_evidence_path_mismatch);
    try expectDormantReceiptIdentityMismatch(
        &fixture,
        &config,
        receipt_copy_evidence_path_mismatch,
    );

    const receipt_copy_evidence_sha_mismatch = try fixture.receiptFor(
        allocator,
        dormant_test_source_inventory_sha256,
        dormant_test_source_file_ledger_sha256,
        dormant_test_source_destination_ledger_sha256,
        dormant_test_copy_evidence_path,
        receipt_mismatch_sha,
    );
    defer allocator.free(receipt_copy_evidence_sha_mismatch);
    try expectDormantReceiptIdentityMismatch(
        &fixture,
        &config,
        receipt_copy_evidence_sha_mismatch,
    );

    const bad_receipt = dormant_receipt_magic ++ "\nwrong-header\nrow\n";
    const bad_receipt_candidate = try fixture.candidateFor(
        allocator,
        fixture.manifest,
        fixture.lineage,
        bad_receipt,
        "candidate",
    );
    defer allocator.free(bad_receipt_candidate);
    try fixture.replaceControl(dormant_receipt_key, bad_receipt);
    try fixture.replaceControl(dormant_candidate_key, bad_receipt_candidate);
    try expectDormantReadinessRejection(&fixture, &config, error.DormantReceiptMalformed);
    try fixture.replaceControl(dormant_receipt_key, fixture.receipt);
    try fixture.replaceControl(dormant_candidate_key, fixture.candidate);

    try fixture.deleteControl(dormant_receipt_key);
    try fixture.symlinkControl(dormant_receipt_key, "../../manifests/candidate.tsv");
    try expectDormantReadinessRejection(&fixture, &config, error.DormantReceiptUnsafe);
    try fixture.deleteControl(dormant_receipt_key);
    try fixture.replaceControl(dormant_receipt_key, fixture.receipt);

    config.expected_registration_path_hash[0] =
        if (config.expected_registration_path_hash[0] == '0') '1' else '0';
    try expectDormantReadinessRejection(&fixture, &config, error.DormantRegistrationStale);
    config.expected_registration_path_hash = config.guard.frozen.path_hash;

    try fixture.deletePayload(fixture.payload_key);
    try expectDormantReadinessRejection(&fixture, &config, error.DormantDestinationPartial);
    try fixture.replacePayload(fixture.payload_key, fixture.payload);

    try fixture.replacePayload(fixture.payload_key, "wrong payload\n");
    try expectDormantReadinessRejection(
        &fixture,
        &config,
        error.DormantDestinationMismatched,
    );
    try fixture.replacePayload(fixture.payload_key, fixture.payload);

    try fixture.deletePayload(fixture.payload_key);
    try fixture.symlinkPayload(fixture.payload_key, "/dev/null");
    try expectDormantReadinessRejection(&fixture, &config, error.DormantDestinationUnsafe);
    try fixture.deletePayload(fixture.payload_key);
    try fixture.replacePayload(fixture.payload_key, fixture.payload);

    var payload_dir = try std.Io.Dir.openDirAbsolute(io, fixture.payload_root, .{
        .access_sub_paths = true,
        .iterate = true,
        .follow_symlinks = false,
    });
    try writeDormantFixtureRelative(io, payload_dir, "unexpected", "extra\n", 0o444);
    try expectDormantReadinessRejection(&fixture, &config, error.DormantDestinationExtra);
    try deleteDormantFixtureRelative(io, payload_dir, "unexpected");

    try fixture.deleteControl(dormant_candidate_key);
    var control_dir = try std.Io.Dir.openDirAbsolute(io, fixture.control_root, .{
        .access_sub_paths = true,
        .iterate = true,
        .follow_symlinks = false,
    });
    var manifests = try openPathNoFollow(
        io,
        control_dir,
        "authority/zllvm/v1/manifests",
        false,
    );
    try manifests.symLink(io, "generation-00000001.tsv", "candidate.tsv", .{});
    try expectDormantReadinessRejection(&fixture, &config, error.DormantCandidateUnsafe);
    try manifests.deleteFile(io, "candidate.tsv");
    manifests.close(io);
    control_dir.close(io);
    try fixture.replaceControl(dormant_candidate_key, fixture.candidate);
    payload_dir.close(io);

    _ = try expectDormantReadinessSuccess(&fixture, &config);
    try fixture.deinitAfterSuccess();
    completed = true;
}
