const std = @import("std");
const builtin = @import("builtin");
const artifact_composition = @import("artifact_composition.zig");
const authority_control = @import("authority_control.zig");
const canonical_source = @import("canonical_source.zig");
const digest = @import("digest.zig");
const filesystem = @import("filesystem.zig");
const identity = @import("identity.zig");
const manifest = @import("manifest.zig");
const registration = @import("registration.zig");
const store_model = @import("store.zig");

const original_failed_store = "/home/oleg/prog/z_llvm-inbox193-artifact-store-synthetic";
const prior_first_continuation_store = "/home/oleg/prog/z_llvm-inbox193a-artifact-store-synthetic";
const prior_second_continuation_store = "/home/oleg/prog/z_llvm-inbox193b-artifact-store-synthetic";
const synthetic_store = "/home/oleg/prog/z_llvm-inbox194d-artifact-store-synthetic";
const default_store = "/home/oleg/prog/z_llvm-artifacts";
const main_repository = registration.main_repository;
const main_git_common_dir = registration.main_git_common_dir;
const canonical_source_spec_path = canonical_source.canonical_source_spec_path;
const canonical_source_spec_sha = canonical_source.canonical_source_spec_sha;
const proposed_live_manifest_path = canonical_source.proposed_live_manifest_path;
const schema_magic = manifest.schema_magic;
const schema_header = manifest.schema_header;
const snapshot_recipe = store_model.snapshot_recipe;
const snapshot_recipe_sha = manifest.snapshot_recipe_sha;
const source_spec_magic = canonical_source.source_spec_magic;
const RowKind = manifest.RowKind;
const Status = manifest.Status;
const RetentionClass = manifest.RetentionClass;
const parseManifest = manifest.parseManifest;
const encodeManifest = manifest.encodeManifest;
const appendManifestPreamble = manifest.appendManifestPreamble;
const appendManifestRowText = manifest.appendManifestRowText;
const findRow = manifest.findRow;
const sameIdentity = manifest.sameIdentity;
const logicalRefMatchesTarget = manifest.logicalRefMatchesTarget;
const parseEnum = manifest.parseEnum;
const splitSnapshotKey = manifest.splitSnapshotKey;
const sha256Hex = digest.sha256Hex;
const openOrCreateDir = filesystem.openOrCreateDir;
const openExistingDir = filesystem.openExistingDir;
const writeCollisionFixtureAtomic = filesystem.writeCollisionFixtureAtomic;
const writeExclusive = filesystem.writeExclusive;
const syncDirectory = filesystem.syncDirectory;
const readTestDirectorySyncCount = filesystem.readTestDirectorySyncCount;
const FileIdentity = identity.FileIdentity;
const SnapshotIdentity = identity.SnapshotIdentity;
const RegistrationGuard = registration.RegistrationGuard;
const Store = store_model.Store;
const objectKey = store_model.objectKey;
const expectSnapshotProofDirectoryEmpty = store_model.expectSnapshotProofDirectoryEmpty;
const testOnlySnapshotProofEarlyUnwind = store_model.testOnlySnapshotProofEarlyUnwind;
const verifyToolchain = store_model.verifyToolchain;
const validateSnapshotListing = store_model.validateSnapshotListing;
const testPublishBytesCorruptIncoming = store_model.testPublishBytesCorruptIncoming;
const testPublishBytesCorruptFinal = store_model.testPublishBytesCorruptFinal;
const testOpenObjectLeaf = store_model.testOpenObjectLeaf;
const SourceSpecRow = canonical_source.SourceSpecRow;
const SourceSpec = canonical_source.SourceSpec;
const parseSourceSpecOwned = canonical_source.parseSourceSpecOwned;
const validateProposedManifestFieldCounts =
    canonical_source.validateProposedManifestFieldCounts;
const proposedManifestForSourceSpec = canonical_source.proposedManifestForSourceSpec;
const appendPublishedConstituentObject = canonical_source.appendPublishedConstituentObject;
const appendPublishedSnapshot = canonical_source.appendPublishedSnapshot;
const manifestForSynthetic = artifact_composition.manifestForSynthetic;
const assertRetainedMaterializeBoundaries =
    artifact_composition.assertRetainedMaterializeBoundaries;
const generatorTestSourceSpecRow = artifact_composition.generatorTestSourceSpecRow;
const mutateGeneratedMembers = artifact_composition.mutateGeneratedMembers;
const validateAuthorityAncestry = authority_control.API.validateAncestry;

fn requireTest() !void {
    if (!builtin.is_test) return error.TestOnlyOperation;
}

pub fn authorityResolutionIsClosed(comptime resolveAuthority: anytype) !void {
    try requireTest();
    const allocator = std.testing.allocator;
    const forced = try resolveAuthority(
        allocator,
        synthetic_store,
        "/home/oleg/prog/z_llvm/.git",
    );
    defer allocator.free(forced);
    try std.testing.expectEqualStrings(synthetic_store, forced);
    const fallback = try resolveAuthority(
        allocator,
        null,
        "/home/oleg/prog/z_llvm/.git",
    );
    defer allocator.free(fallback);
    try std.testing.expectEqualStrings(default_store, fallback);
    try std.testing.expectError(
        error.PathNotAbsolute,
        resolveAuthority(allocator, "relative/store", "/home/oleg/prog/z_llvm/.git"),
    );
    try std.testing.expectError(
        error.PathNotNormalized,
        resolveAuthority(
            allocator,
            "/home/oleg/prog/../prog/z_llvm-inbox193-artifact-store-synthetic",
            "/home/oleg/prog/z_llvm/.git",
        ),
    );
    try std.testing.expectEqual(RowKind.logical_ref, parseEnum(RowKind, "logical-ref").?);
    try std.testing.expectEqual(RowKind.snapshot_member, parseEnum(RowKind, "snapshot-member").?);
    try std.testing.expectEqual(
        Status.absent_unrecoverable,
        parseEnum(Status, "absent-unrecoverable").?,
    );
    try std.testing.expectEqual(
        RetentionClass.irreplaceable_acceptance_evidence,
        parseEnum(RetentionClass, "irreplaceable-acceptance-evidence").?,
    );
    try std.testing.expect(parseEnum(RowKind, "logical_ref") == null);
    try std.testing.expectEqualStrings(snapshot_recipe_sha, &sha256Hex(snapshot_recipe));
}

pub fn publishedSnapshotGeneratorBindsEveryMember() !void {
    try requireTest();
    const allocator = std.testing.allocator;
    const sha_a = "0000000000000000000000000000000000000000000000000000000000000000";
    const sha_b = "1111111111111111111111111111111111111111111111111111111111111111";
    const constituent_sha =
        "2222222222222222222222222222222222222222222222222222222222222222";
    const archive_sha =
        "3333333333333333333333333333333333333333333333333333333333333333";
    const key_a =
        "objects/sha256/00/00000000000000000000000000000000000000000000000000000000000000";
    const key_b =
        "objects/sha256/11/11111111111111111111111111111111111111111111111111111111111111";
    const constituent_key =
        "objects/sha256/22/22222222222222222222222222222222222222222222222222222222222222";
    const archive_key =
        "snapshots/sha256/33/33333333333333333333333333333333333333333333333333333333333333.tar.zst";
    const group_id = "test-generated-snapshot";
    const snapshot_id = "snapshot/test-generated/v1";
    const objects = [_]FileIdentity{
        .{
            .sha256 = sha_a.*,
            .bytes = 7,
            .mode = 0o444,
            .key = @constCast(key_a),
        },
        .{
            .sha256 = sha_b.*,
            .bytes = 11,
            .mode = 0o444,
            .key = @constCast(key_b),
        },
    };
    const object_rows = [_]usize{ 0, 1 };
    var source_rows = [_]SourceSpecRow{
        generatorTestSourceSpecRow(group_id),
        generatorTestSourceSpecRow(group_id),
    };
    var empty_storage: [0]u8 = .{};
    const spec: SourceSpec = .{
        .storage = &empty_storage,
        .rows = &source_rows,
    };
    var empty_member_keys: [0][]u8 = .{};
    const snapshot: SnapshotIdentity = .{
        .archive = .{
            .sha256 = archive_sha.*,
            .bytes = 17,
            .mode = 0o444,
            .key = @constCast(archive_key),
        },
        .constituent = .{
            .sha256 = constituent_sha.*,
            .bytes = 19,
            .mode = 0o444,
            .key = @constCast(constituent_key),
        },
        .member_keys = &empty_member_keys,
    };

    var output: std.ArrayList(u8) = .empty;
    defer output.deinit(allocator);
    try appendManifestPreamble(allocator, &output);
    for (objects) |object| {
        const object_id = try std.fmt.allocPrint(
            allocator,
            "object/sha256/{s}",
            .{&object.sha256},
        );
        defer allocator.free(object_id);
        try appendManifestRowText(allocator, &output, .{
            .kind = .object,
            .logical_id = object_id,
            .sha256 = &object.sha256,
            .bytes = object.bytes,
            .mode = object.mode,
            .media_type = "application/octet-stream",
            .provenance = "generator-test",
            .reconstruction = "generator-test",
            .retention_class = .canonical_input,
            .status = .active,
            .key = object.key,
            .target_id = "-",
            .snapshot_id = "-",
            .member_path = "-",
            .snapshot_format = "-",
            .recipe_sha256 = "-",
            .constituent_sha256 = "-",
        });
    }
    try appendPublishedConstituentObject(allocator, &output, snapshot.constituent);
    try appendPublishedSnapshot(
        allocator,
        &output,
        snapshot_id,
        snapshot,
        &objects,
        &object_rows,
        spec,
        group_id,
    );
    const canonical = try output.toOwnedSlice(allocator);
    defer allocator.free(canonical);
    var parsed = try parseManifest(allocator, canonical);
    defer parsed.deinit(allocator);
    const reencoded = try encodeManifest(allocator, parsed);
    defer allocator.free(reencoded);
    try std.testing.expectEqualStrings(canonical, reencoded);

    var generated_member_count: usize = 0;
    for (parsed.rows) |row| {
        if (row.kind != .snapshot_member) continue;
        const target = findRow(parsed, row.target_id) orelse return error.MissingTargetObject;
        try std.testing.expectEqual(RowKind.object, target.kind);
        try std.testing.expectEqualStrings(target.key, row.key);
        try std.testing.expectEqualStrings(target.key, row.member_path);
        try std.testing.expect(sameIdentity(row, target));
        generated_member_count += 1;
    }
    try std.testing.expectEqual(@as(usize, 2), generated_member_count);

    const dash_keys = try mutateGeneratedMembers(allocator, canonical, .dash_keys);
    defer allocator.free(dash_keys);
    try std.testing.expectError(error.ConflictingManifestKey, parseManifest(allocator, dash_keys));
    const other_object_key = try mutateGeneratedMembers(allocator, canonical, .other_object_key);
    defer allocator.free(other_object_key);
    try std.testing.expectError(
        error.ConflictingManifestKey,
        parseManifest(allocator, other_object_key),
    );
    const mismatched_hash = try mutateGeneratedMembers(allocator, canonical, .hash);
    defer allocator.free(mismatched_hash);
    try std.testing.expectError(
        error.ConflictingManifestKey,
        parseManifest(allocator, mismatched_hash),
    );
    const mismatched_bytes = try mutateGeneratedMembers(allocator, canonical, .bytes);
    defer allocator.free(mismatched_bytes);
    try std.testing.expectError(
        error.ConflictingManifestKey,
        parseManifest(allocator, mismatched_bytes),
    );
    const mismatched_mode = try mutateGeneratedMembers(allocator, canonical, .mode);
    defer allocator.free(mismatched_mode);
    try std.testing.expectError(
        error.InvalidSnapshotMemberRow,
        parseManifest(allocator, mismatched_mode),
    );
}

pub fn snapshotListingValidationIsClosed() !void {
    try requireTest();
    const allocator = std.testing.allocator;
    const key_a = "objects/sha256/00/00000000000000000000000000000000000000000000000000000000000000";
    const key_b = "objects/sha256/11/11111111111111111111111111111111111111111111111111111111111111";
    const objects = [_]FileIdentity{
        .{
            .sha256 = "0000000000000000000000000000000000000000000000000000000000000000".*,
            .bytes = 1,
            .mode = 0o444,
            .key = @constCast(key_a),
        },
        .{
            .sha256 = "1111111111111111111111111111111111111111111111111111111111111111".*,
            .bytes = 1,
            .mode = 0o444,
            .key = @constCast(key_b),
        },
    };
    const valid = try std.fmt.allocPrint(
        allocator,
        "-r--r--r-- 0/0 1 1970-01-01 00:00 {s}\n" ++
            "-r--r--r-- 0/0 1 1970-01-01 00:00 {s}\n",
        .{ key_a, key_b },
    );
    defer allocator.free(valid);
    try validateSnapshotListing(allocator, valid, &objects);

    const unsafe = "-r--r--r-- 0/0 1 1970-01-01 00:00 ../escape\n";
    try std.testing.expectError(
        error.UnsafeOrUnexpectedSnapshotMember,
        validateSnapshotListing(allocator, unsafe, &objects),
    );
    const extra = try std.fmt.allocPrint(
        allocator,
        "-r--r--r-- 0/0 1 1970-01-01 00:00 {s}\n" ++
            "-r--r--r-- 0/0 1 1970-01-01 00:00 {s}\n" ++
            "-r--r--r-- 0/0 1 1970-01-01 00:00 unexpected\n",
        .{ key_a, key_b },
    );
    defer allocator.free(extra);
    try std.testing.expectError(
        error.UnsafeOrUnexpectedSnapshotMember,
        validateSnapshotListing(allocator, extra, &objects),
    );
    const symlink = try std.fmt.allocPrint(
        allocator,
        "lrwxrwxrwx 0/0 0 1970-01-01 00:00 {s} -> target\n",
        .{key_a},
    );
    defer allocator.free(symlink);
    try std.testing.expectError(
        error.UnsafeOrUnexpectedSnapshotMember,
        validateSnapshotListing(allocator, symlink, &objects),
    );
}

pub fn canonicalSourceSpecificationIsClosed() !void {
    try requireTest();
    const allocator = std.testing.allocator;
    const io = std.testing.io;
    const canonical = try std.Io.Dir.cwd().readFileAlloc(
        io,
        canonical_source_spec_path,
        allocator,
        .limited(256 * 1024),
    );
    defer allocator.free(canonical);
    try std.testing.expectEqualStrings(canonical_source_spec_sha, &sha256Hex(canonical));

    var spec = try parseSourceSpecOwned(allocator, try allocator.dupe(u8, canonical));
    defer spec.deinit(allocator);
    try std.testing.expectEqual(@as(usize, 19), spec.rows.len);
    try std.testing.expectEqual(@as(u16, 0o664), spec.rows[0].source_mode);
    const proposed = try proposedManifestForSourceSpec(allocator, spec);
    defer allocator.free(proposed);
    const tracked_proposed = try std.Io.Dir.cwd().readFileAlloc(
        io,
        proposed_live_manifest_path,
        allocator,
        .limited(256 * 1024),
    );
    defer allocator.free(tracked_proposed);
    try validateProposedManifestFieldCounts(tracked_proposed);
    try std.testing.expectEqualStrings(tracked_proposed, proposed);
    var parsed = try parseManifest(allocator, proposed);
    defer parsed.deinit(allocator);
    const ac_ref = findRow(parsed, "calls/input/accepted-cohort-ac285/v1") orelse
        return error.MissingLogicalReference;
    const ac_object = findRow(
        parsed,
        "object/sha256/d8da86cae494d7d4a58053ab24b1e8be944859263072b85ffa164880b0110cd4",
    ) orelse return error.MissingTargetObject;
    try std.testing.expectEqual(@as(u16, 0o664), ac_ref.mode);
    try std.testing.expectEqual(@as(u16, 0o444), ac_object.mode);
    try std.testing.expect(logicalRefMatchesTarget(ac_ref, ac_object));
    const reencoded = try encodeManifest(allocator, parsed);
    defer allocator.free(reencoded);
    try std.testing.expectEqualStrings(proposed, reencoded);

    const too_many_fields =
        schema_magic ++ "\n" ++ schema_header ++ "\n" ++
        "logical-ref\tcalls/input/test/v1\t0000000000000000000000000000000000000000000000000000000000000000\t1\t444\ttext/plain\ttest\ttest\tcanonical-input\tfuture-required\tplanned/test\tobject/test\t-\t-\t-\t-\t-\t-\n";
    try std.testing.expectError(
        error.ProposedManifestFieldCountMismatch,
        validateProposedManifestFieldCounts(too_many_fields),
    );

    const bad_magic = try std.mem.replaceOwned(
        u8,
        allocator,
        canonical,
        source_spec_magic,
        "zllvm-calls-canonical-source-spec-v2",
    );
    try std.testing.expectError(
        error.UnknownSourceSpecVersion,
        parseSourceSpecOwned(allocator, bad_magic),
    );

    const bad_key = try std.mem.replaceOwned(
        u8,
        allocator,
        canonical,
        "objects/sha256/d8/da86cae494d7d4a58053ab24b1e8be944859263072b85ffa164880b0110cd4",
        "objects/sha256/d8/da86cae494d7d4a58053ab24b1e8be944859263072b85ffa164880b0110cd5",
    );
    try std.testing.expectError(
        error.ObjectKeyShaMismatch,
        parseSourceSpecOwned(allocator, bad_key),
    );

    const bad_group = try std.mem.replaceOwned(
        u8,
        allocator,
        canonical,
        "\tcalls-validation-inputs\tsnapshot/calls-validation-inputs/v1\t",
        "\tcalls-inputs\tsnapshot/calls-validation-inputs/v1\t",
    );
    try std.testing.expectError(
        error.SourceSetGroupMismatch,
        parseSourceSpecOwned(allocator, bad_group),
    );
}

pub fn syntheticStorePublishesAndResolves(
    comptime resolveAuthority: anytype,
    comptime prepareStoreRoot: anytype,
    comptime removeAbsoluteDirectorySynced: anytype,
) !void {
    try requireTest();
    const allocator = std.testing.allocator;
    const io = std.testing.io;
    const forced = try std.testing.environ.getAlloc(allocator, "ZLLVM_ARTIFACT_STORE");
    defer allocator.free(forced);
    try std.testing.expectEqualStrings(synthetic_store, forced);
    const resolved_from_environment = try resolveAuthority(
        allocator,
        forced,
        main_git_common_dir,
    );
    defer allocator.free(resolved_from_environment);
    try std.testing.expectEqualStrings(synthetic_store, resolved_from_environment);

    var guard = try RegistrationGuard.init(allocator, io);
    var guard_open = true;
    defer if (guard_open) guard.deinit();
    try guard.assertStoreRoot(synthetic_store);
    const protected = guard.frozen.paths[0];
    try std.testing.expectError(error.RegisteredWorktreeOverlap, guard.assertStoreRoot(protected));
    const protected_descendant = try std.fs.path.join(allocator, &.{ protected, "synthetic-child" });
    defer allocator.free(protected_descendant);
    try std.testing.expectError(
        error.RegisteredWorktreeOverlap,
        guard.assertStoreRoot(protected_descendant),
    );
    const protected_ancestor = std.fs.path.dirname(protected) orelse
        return error.InvalidProtectedPath;
    try std.testing.expectError(
        error.RegisteredWorktreeOverlap,
        guard.assertStoreRoot(protected_ancestor),
    );
    try guard.assertReadSource(
        "/home/oleg/prog/z_llvm/tmp/inbox63_accepted_cohort.ll",
        "/home/oleg/prog/z_llvm/tmp/inbox63_accepted_cohort.ll",
    );
    try std.testing.expectError(
        error.RegisteredWorktreeOverlap,
        guard.assertReadSource(
            main_repository,
            "/home/oleg/prog/z_llvm/tmp/inbox63_accepted_cohort.ll",
        ),
    );
    try verifyToolchain(allocator, io);

    var original = try std.Io.Dir.openDirAbsolute(io, original_failed_store, .{
        .iterate = true,
        .follow_symlinks = false,
    });
    defer original.close(io);
    const original_stat = try original.stat(io);
    if (@as(u16, @intCast(original_stat.permissions.toMode() & 0o7777)) != 0o775) {
        return error.OriginalFailedStoreModeChanged;
    }
    var original_entries = original.iterate();
    if (try original_entries.next(io) != null) return error.OriginalFailedStoreNotEmpty;
    var prior_continuation = try std.Io.Dir.openDirAbsolute(io, prior_first_continuation_store, .{
        .iterate = true,
        .follow_symlinks = false,
    });
    defer prior_continuation.close(io);
    const prior_continuation_stat = try prior_continuation.stat(io);
    if (@as(u16, @intCast(prior_continuation_stat.permissions.toMode() & 0o7777)) != 0o775) {
        return error.PriorContinuationStoreModeChanged;
    }
    var prior_continuation_entries = prior_continuation.iterate();
    if (try prior_continuation_entries.next(io) == null) {
        return error.PriorContinuationStoreNotPopulated;
    }
    var prior_second_continuation = try std.Io.Dir.openDirAbsolute(io, prior_second_continuation_store, .{
        .iterate = true,
        .follow_symlinks = false,
    });
    defer prior_second_continuation.close(io);
    const prior_second_continuation_stat = try prior_second_continuation.stat(io);
    if (@as(u16, @intCast(prior_second_continuation_stat.permissions.toMode() & 0o7777)) != 0o775) {
        return error.PriorSecondContinuationStoreModeChanged;
    }
    var prior_second_continuation_entries = prior_second_continuation.iterate();
    if (try prior_second_continuation_entries.next(io) == null) {
        return error.PriorSecondContinuationStoreNotPopulated;
    }

    if (std.Io.Dir.openDirAbsolute(io, synthetic_store, .{ .follow_symlinks = false })) |existing| {
        existing.close(io);
        return error.SyntheticStorePreexisted;
    } else |err| switch (err) {
        error.FileNotFound => {},
        else => return err,
    }
    try assertRetainedMaterializeBoundaries(io, default_store);

    const sync_before_root = try readTestDirectorySyncCount();
    try prepareStoreRoot(allocator, io, &guard, synthetic_store);
    try std.testing.expect(try readTestDirectorySyncCount() >= sync_before_root + 2);
    errdefer std.debug.print(
        "INBOX-194D retain-on-failure synthetic_root={s}\n",
        .{synthetic_store},
    );

    try std.testing.expectError(
        error.PathNotNormalized,
        validateAuthorityAncestry(
            allocator,
            io,
            synthetic_store ++ "/../z_llvm-inbox194d-artifact-store-synthetic",
        ),
    );
    const generic_authority = try std.fs.path.join(
        allocator,
        &.{ synthetic_store, "authority-generic-child" },
    );
    defer allocator.free(generic_authority);
    try prepareStoreRoot(allocator, io, &guard, generic_authority);
    try std.testing.expect(try validateAuthorityAncestry(allocator, io, generic_authority));
    try removeAbsoluteDirectorySynced(io, generic_authority);

    {
        var authority_root = try std.Io.Dir.openDirAbsolute(io, synthetic_store, .{
            .access_sub_paths = true,
            .iterate = true,
            .follow_symlinks = false,
        });
        defer authority_root.close(io);
        try authority_root.symLink(io, ".", "authority-symlink", .{});
        const symlink_authority = try std.fs.path.join(
            allocator,
            &.{ synthetic_store, "authority-symlink", "child" },
        );
        defer allocator.free(symlink_authority);
        if (validateAuthorityAncestry(allocator, io, symlink_authority)) |_| {
            return error.SymlinkAuthorityWasAccepted;
        } else |err| switch (err) {
            error.AuthoritySymlinkComponent,
            error.AuthorityNonDirectoryComponent,
            => {},
            else => return err,
        }
        try authority_root.deleteFile(io, "authority-symlink");
        try writeExclusive(io, authority_root, "authority-file", "not a directory\n", 0o444);
        const file_authority = try std.fs.path.join(
            allocator,
            &.{ synthetic_store, "authority-file", "child" },
        );
        defer allocator.free(file_authority);
        try std.testing.expectError(
            error.AuthorityNonDirectoryComponent,
            validateAuthorityAncestry(allocator, io, file_authority),
        );
        try authority_root.deleteFile(io, "authority-file");
    }

    var store = try Store.open(allocator, io, &guard, synthetic_store);
    var store_open = true;
    defer if (store_open) store.deinit();

    const observed = try store.preflightCapacity(.{
        .validation_reserve = 0,
        .primary_bytes = 4096,
        .snapshot_bound = 8192,
        .manifest_bound = 4096,
        .required_inodes = 32,
    });
    try std.testing.expect(observed.free_bytes > 0);
    try std.testing.expect(observed.free_inodes > 0);

    var streamed_object = try store.publishFile(
        "/home/oleg/prog/z_llvm/tmp/inbox63_accepted_cohort.ll",
        "/home/oleg/prog/z_llvm/tmp/inbox63_accepted_cohort.ll",
    );
    defer streamed_object.deinit(allocator);
    try store.verifyObject(streamed_object);

    const rejected_before = "prepublication corruption must never become final\n";
    const rejected_before_sha = sha256Hex(rejected_before);
    try std.testing.expectError(
        error.PrepublicationVerificationFailed,
        testPublishBytesCorruptIncoming(&store, rejected_before),
    );
    var rejected_before_leaf = try testOpenObjectLeaf(&store, rejected_before_sha[0..2]);
    if (rejected_before_leaf.openFile(io, rejected_before_sha[2..], .{
        .allow_directory = false,
        .follow_symlinks = false,
    })) |unexpected| {
        unexpected.close(io);
        return error.PrepublicationCorruptionCreatedFinal;
    } else |err| switch (err) {
        error.FileNotFound => {},
        else => return err,
    }
    rejected_before_leaf.close(io);

    const rejected_after = "postpublication mismatch removes only its own final\n";
    const rejected_after_sha = sha256Hex(rejected_after);
    try std.testing.expectError(
        error.PostPublicationReadBackMismatch,
        testPublishBytesCorruptFinal(&store, rejected_after),
    );
    var rejected_after_leaf = try testOpenObjectLeaf(&store, rejected_after_sha[0..2]);
    if (rejected_after_leaf.openFile(io, rejected_after_sha[2..], .{
        .allow_directory = false,
        .follow_symlinks = false,
    })) |unexpected| {
        unexpected.close(io);
        return error.PostpublicationMismatchWasNotRemoved;
    } else |err| switch (err) {
        error.FileNotFound => {},
        else => return err,
    }
    rejected_after_leaf.close(io);

    var object = try store.publishBytes("synthetic artifact bytes\n");
    defer object.deinit(allocator);
    var equal_object = try store.publishBytes("synthetic artifact bytes\n");
    defer equal_object.deinit(allocator);
    try std.testing.expectEqualStrings(&object.sha256, &equal_object.sha256);
    try std.testing.expectEqualStrings(object.key, equal_object.key);
    try store.verifyObject(object);
    var wrong_hash = object;
    wrong_hash.sha256[0] = if (wrong_hash.sha256[0] == '0') '1' else '0';
    try std.testing.expectError(error.ObjectKeyShaMismatch, store.verifyObject(wrong_hash));
    var wrong_size = object;
    wrong_size.bytes += 1;
    try std.testing.expectError(error.ObjectVerificationFailed, store.verifyObject(wrong_size));
    var wrong_mode = object;
    wrong_mode.mode = 0o400;
    try std.testing.expectError(error.ModeMismatch, store.verifyObject(wrong_mode));

    const aliased_source = try std.fs.path.join(allocator, &.{ synthetic_store, "inside-source" });
    defer allocator.free(aliased_source);
    try std.testing.expectError(
        error.SourceStoreAliasing,
        store.publishFile(synthetic_store, aliased_source),
    );

    const collision_bytes = "collision target";
    const collision_sha = sha256Hex(collision_bytes);
    var collision_leaf = try testOpenObjectLeaf(&store, collision_sha[0..2]);
    try writeCollisionFixtureAtomic(
        io,
        collision_leaf,
        collision_sha[2..],
        "wrong collision bytes",
        0o444,
    );
    collision_leaf.close(io);
    try std.testing.expectError(error.UnequalExistingCollision, store.publishBytes(collision_bytes));
    const collision_path = try std.fs.path.join(
        allocator,
        &.{ synthetic_store, "objects", "sha256", collision_sha[0..2], collision_sha[2..] },
    );
    defer allocator.free(collision_path);
    const collision_retained = try std.Io.Dir.cwd().readFileAlloc(
        io,
        collision_path,
        allocator,
        .limited(1024),
    );
    defer allocator.free(collision_retained);
    try std.testing.expectEqualStrings("wrong collision bytes", collision_retained);

    var partial_leaf = try testOpenObjectLeaf(&store, object.sha256[0..2]);
    try writeExclusive(io, partial_leaf, "partial", "partial", 0o444);
    try std.testing.expectError(error.PartialOrUnexpectedObject, store.verifyNoPartialObjects());
    try partial_leaf.deleteFile(io, "partial");
    partial_leaf.close(io);
    try store.verifyNoPartialObjects();

    const symlink_sha = "ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff";
    var symlink_leaf = try testOpenObjectLeaf(&store, symlink_sha[0..2]);
    try symlink_leaf.symLink(io, object.key, symlink_sha[2..], .{});
    const symlink_key = try objectKey(allocator, symlink_sha);
    defer allocator.free(symlink_key);
    const symlink_identity: FileIdentity = .{
        .sha256 = symlink_sha.*,
        .bytes = object.bytes,
        .mode = 0o444,
        .key = symlink_key,
    };
    if (store.verifyObject(symlink_identity)) {
        return error.SymlinkObjectWasAccepted;
    } else |_| {}
    try symlink_leaf.deleteFile(io, symlink_sha[2..]);
    symlink_leaf.close(io);

    const directory_sha = "eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee";
    var directory_leaf = try testOpenObjectLeaf(&store, directory_sha[0..2]);
    try directory_leaf.createDir(io, directory_sha[2..], .default_dir);
    const directory_key = try objectKey(allocator, directory_sha);
    defer allocator.free(directory_key);
    const directory_identity: FileIdentity = .{
        .sha256 = directory_sha.*,
        .bytes = 0,
        .mode = 0o444,
        .key = directory_key,
    };
    if (store.verifyObject(directory_identity)) {
        return error.NonRegularObjectWasAccepted;
    } else |_| {}
    try directory_leaf.deleteDir(io, directory_sha[2..]);
    directory_leaf.close(io);

    const objects = [_]FileIdentity{ object, streamed_object };
    const empty_objects = [_]FileIdentity{};
    try std.testing.expectError(
        error.InvalidSnapshotMemberCount,
        store.publishSnapshot(&empty_objects),
    );
    const duplicate_objects = [_]FileIdentity{ object, object };
    try std.testing.expectError(
        error.DuplicateSnapshotMember,
        store.publishSnapshot(&duplicate_objects),
    );
    var snapshot = try store.publishSnapshot(&objects);
    defer snapshot.deinit(allocator);
    try expectSnapshotProofDirectoryEmpty(&store);
    try store.verifySnapshot(snapshot, &objects);
    try expectSnapshotProofDirectoryEmpty(&store);
    try std.testing.expectError(
        error.TestSnapshotProofEarlyFailure,
        testOnlySnapshotProofEarlyUnwind(&store),
    );
    try expectSnapshotProofDirectoryEmpty(&store);
    const reversed_objects = [_]FileIdentity{ streamed_object, object };
    var repeated_snapshot = try store.publishSnapshot(&reversed_objects);
    defer repeated_snapshot.deinit(allocator);
    try std.testing.expectEqualStrings(&snapshot.archive.sha256, &repeated_snapshot.archive.sha256);
    try std.testing.expectEqual(snapshot.archive.bytes, repeated_snapshot.archive.bytes);
    try std.testing.expectEqualStrings(snapshot.archive.key, repeated_snapshot.archive.key);
    try store.verifySnapshot(repeated_snapshot, &reversed_objects);

    const snapshot_split = splitSnapshotKey(snapshot.archive.key) orelse
        return error.InvalidSnapshotKey;
    var snapshots_root = try openExistingDir(io, store.root, "snapshots");
    var snapshots_sha = try openExistingDir(io, snapshots_root, "sha256");
    var snapshot_leaf = try openExistingDir(io, snapshots_sha, snapshot_split.prefix);
    try snapshot_leaf.setFilePermissions(
        io,
        snapshot_split.basename,
        .fromMode(0o600),
        .{ .follow_symlinks = false },
    );
    var corrupt_archive = try snapshot_leaf.openFile(io, snapshot_split.basename, .{
        .mode = .read_write,
        .allow_directory = false,
        .follow_symlinks = false,
    });
    try corrupt_archive.writePositionalAll(io, "!", 0);
    try corrupt_archive.sync(io);
    try corrupt_archive.setPermissions(io, .fromMode(0o444));
    try corrupt_archive.sync(io);
    corrupt_archive.close(io);
    try std.testing.expectError(
        error.SnapshotVerificationFailed,
        store.verifySnapshot(snapshot, &objects),
    );
    try snapshot_leaf.deleteFile(io, snapshot_split.basename);
    try syncDirectory(snapshot_leaf);
    snapshot_leaf.close(io);
    snapshots_sha.close(io);
    snapshots_root.close(io);
    var restored_snapshot = try store.publishSnapshot(&objects);
    defer restored_snapshot.deinit(allocator);
    try std.testing.expectEqualStrings(&snapshot.archive.sha256, &restored_snapshot.archive.sha256);
    try store.verifySnapshot(snapshot, &objects);

    var wrong_member = try store.publishBytes("different synthetic member\n");
    defer wrong_member.deinit(allocator);
    const wrong_objects = [_]FileIdentity{ object, wrong_member };
    try std.testing.expectError(
        error.ConstituentMismatch,
        store.verifySnapshot(snapshot, &wrong_objects),
    );

    const manifest_text = try manifestForSynthetic(allocator, &objects, snapshot);
    defer allocator.free(manifest_text);
    const manifest_key = try store.publishManifest(1, manifest_text);
    defer allocator.free(manifest_key);
    const repeated_manifest_key = try store.publishManifest(1, manifest_text);
    defer allocator.free(repeated_manifest_key);
    try std.testing.expectEqualStrings(manifest_key, repeated_manifest_key);

    var compatibility = try openOrCreateDir(io, store.root, "compatibility-tests");
    compatibility.close(io);
    const compatibility_root = try std.fs.path.join(
        allocator,
        &.{ synthetic_store, "compatibility-tests" },
    );
    defer allocator.free(compatibility_root);
    try store.resolveCompatibility(
        manifest_text,
        "calls.ref.synthetic.v1",
        snapshot,
        &objects,
        compatibility_root,
        "result.bin",
    );
    try store.resolveCompatibility(
        manifest_text,
        "calls.ref.synthetic.v1",
        snapshot,
        &objects,
        compatibility_root,
        "result.bin",
    );
    var compat_dir = try std.Io.Dir.openDirAbsolute(io, compatibility_root, .{
        .access_sub_paths = true,
        .iterate = true,
        .follow_symlinks = false,
    });
    compat_dir.close(io);

    var stale_compat = try openOrCreateDir(io, store.root, "compatibility-stale");
    try writeExclusive(io, stale_compat, "result.bin", "stale", 0o444);
    stale_compat.close(io);
    const stale_root = try std.fs.path.join(
        allocator,
        &.{ synthetic_store, "compatibility-stale" },
    );
    defer allocator.free(stale_root);
    try std.testing.expectError(
        error.StaleCompatibilityDestination,
        store.resolveCompatibility(
            manifest_text,
            "calls.ref.synthetic.v1",
            snapshot,
            &objects,
            stale_root,
            "result.bin",
        ),
    );
    const stale_path = try std.fs.path.join(allocator, &.{ stale_root, "result.bin" });
    defer allocator.free(stale_path);
    const stale = try std.Io.Dir.cwd().readFileAlloc(
        io,
        stale_path,
        allocator,
        .limited(1024),
    );
    defer allocator.free(stale);
    try std.testing.expectEqualStrings("stale", stale);

    var symlink_compat = try openOrCreateDir(io, store.root, "compatibility-symlink");
    try symlink_compat.symLink(io, "elsewhere", "result.bin", .{});
    symlink_compat.close(io);
    const symlink_root = try std.fs.path.join(
        allocator,
        &.{ synthetic_store, "compatibility-symlink" },
    );
    defer allocator.free(symlink_root);
    try std.testing.expectError(
        error.UnsafeCompatibilityDestination,
        store.resolveCompatibility(
            manifest_text,
            "calls.ref.synthetic.v1",
            snapshot,
            &objects,
            symlink_root,
            "result.bin",
        ),
    );

    var directory_compat = try openOrCreateDir(io, store.root, "compatibility-directory");
    try directory_compat.createDir(io, "result.bin", .default_dir);
    directory_compat.close(io);
    const directory_root = try std.fs.path.join(
        allocator,
        &.{ synthetic_store, "compatibility-directory" },
    );
    defer allocator.free(directory_root);
    if (store.resolveCompatibility(
        manifest_text,
        "calls.ref.synthetic.v1",
        snapshot,
        &objects,
        directory_root,
        "result.bin",
    )) {
        return error.NonRegularCompatibilityDestinationWasAccepted;
    } else |_| {}

    try guard.assertCurrent();
    try std.testing.expect(try readTestDirectorySyncCount() > sync_before_root + 10);
    store.deinit();
    store_open = false;
    try guard.assertCurrent();
    try guard.assertStoreRoot(synthetic_store);
    const cleanup_root = try std.fs.path.resolve(allocator, &.{synthetic_store});
    defer allocator.free(cleanup_root);
    try std.testing.expectEqualStrings(synthetic_store, cleanup_root);
    var cleanup_target = try std.Io.Dir.openDirAbsolute(io, cleanup_root, .{
        .access_sub_paths = true,
        .iterate = true,
        .follow_symlinks = false,
    });
    cleanup_target.close(io);
    try removeAbsoluteDirectorySynced(io, synthetic_store);
    guard.deinit();
    guard_open = false;
    if (std.Io.Dir.openDirAbsolute(io, synthetic_store, .{ .follow_symlinks = false })) |remaining| {
        remaining.close(io);
        return error.ContinuationStoreRemovalFailed;
    } else |err| switch (err) {
        error.FileNotFound => {},
        else => return err,
    }
    try assertRetainedMaterializeBoundaries(io, default_store);
    var original_after = try std.Io.Dir.openDirAbsolute(io, original_failed_store, .{
        .iterate = true,
        .follow_symlinks = false,
    });
    defer original_after.close(io);
    var original_entries_after = original_after.iterate();
    if (try original_entries_after.next(io) != null) return error.OriginalFailedStoreChanged;
}
