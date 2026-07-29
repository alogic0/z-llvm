const std = @import("std");
const builtin = @import("builtin");
const artifact_composition = @import("zllvm_artifact_store/artifact_composition.zig");
const authority_control = @import("zllvm_artifact_store/authority_control.zig");
const capacity = @import("zllvm_artifact_store/capacity.zig");
const canonical_source = @import("zllvm_artifact_store/canonical_source.zig");
const digest_model = @import("zllvm_artifact_store/digest.zig");
const exact_real_observer = @import("zllvm_artifact_store/exact_real_observer.zig");
const exact_real_receipt = @import("zllvm_artifact_store/exact_real_receipt.zig");
const filesystem = @import("zllvm_artifact_store/filesystem.zig");
const identity_model = @import("zllvm_artifact_store/identity.zig");
const manifest_model = @import("zllvm_artifact_store/manifest.zig");
const path_policy = @import("zllvm_artifact_store/path_policy.zig");
const process_result = @import("zllvm_artifact_store/process_result.zig");
const registration = @import("zllvm_artifact_store/registration.zig");
const store_model = @import("zllvm_artifact_store/store.zig");
const synthetic_fixture = @import("zllvm_artifact_store/synthetic_fixture.zig");

const original_failed_store = "/home/oleg/prog/z_llvm-inbox193-artifact-store-synthetic";
const prior_first_continuation_store = "/home/oleg/prog/z_llvm-inbox193a-artifact-store-synthetic";
const prior_second_continuation_store = "/home/oleg/prog/z_llvm-inbox193b-artifact-store-synthetic";
const prior_failed_materialize_third_continuation_store =
    "/home/oleg/prog/z_llvm-inbox194c-artifact-store-synthetic";
const synthetic_store = "/home/oleg/prog/z_llvm-inbox194d-artifact-store-synthetic";
const default_store = "/home/oleg/prog/z_llvm-artifacts";
const main_repository = registration.main_repository;
const main_git_common_dir = registration.main_git_common_dir;
const canonical_source_spec_path = canonical_source.canonical_source_spec_path;
const canonical_source_spec_sha = canonical_source.canonical_source_spec_sha;
const proposed_live_manifest_path = canonical_source.proposed_live_manifest_path;

const schema_magic = manifest_model.schema_magic;
const schema_header = manifest_model.schema_header;
const snapshot_format = manifest_model.snapshot_format;
const snapshot_recipe = store_model.snapshot_recipe;
const snapshot_recipe_sha = manifest_model.snapshot_recipe_sha;
const max_snapshot_members = manifest_model.max_snapshot_members;
const source_spec_magic = canonical_source.source_spec_magic;

pub const RowKind = manifest_model.RowKind;
pub const Status = manifest_model.Status;
pub const RetentionClass = manifest_model.RetentionClass;
pub const Row = manifest_model.Row;
pub const Manifest = manifest_model.Manifest;
pub const parseManifest = manifest_model.parseManifest;
pub const encodeManifest = manifest_model.encodeManifest;

const appendManifestPreamble = manifest_model.appendManifestPreamble;
const appendManifestRowText = manifest_model.appendManifestRowText;
const findRow = manifest_model.findRow;
const sameIdentity = manifest_model.sameIdentity;
const logicalRefMatchesTarget = manifest_model.logicalRefMatchesTarget;
const parseEnum = manifest_model.parseEnum;
const externalEnumName = manifest_model.externalEnumName;
const encodeField = manifest_model.encodeField;
const isLowerHex = manifest_model.isLowerHex;
const isLowerAlphaNumeric = manifest_model.isLowerAlphaNumeric;
const splitObjectKey = manifest_model.splitObjectKey;
const splitSnapshotKey = manifest_model.splitSnapshotKey;
const sha256Hex = digest_model.sha256Hex;
const pathContains = path_policy.pathContains;
const normalizedAbsolute = path_policy.normalizedAbsolute;
const termSuccess = process_result.termSuccess;
const freeRunResult = process_result.freeRunResult;
const freshCapacity = capacity.freshCapacity;
const sameFileIdentity = identity_model.sameFileIdentity;
const verifyRelativeFile = identity_model.verifyRelativeFile;
const identityOfOpenFile = identity_model.identityOfOpenFile;
const identityOfOpenFileAnyMode = identity_model.identityOfOpenFileAnyMode;
const copyFileContents = identity_model.copyFileContents;
const openOrCreateDir = filesystem.openOrCreateDir;
const openExistingDir = filesystem.openExistingDir;
const openPathNoFollow = filesystem.openPathNoFollow;
const writeCollisionFixtureAtomic = filesystem.writeCollisionFixtureAtomic;
const PublishFault = filesystem.PublishFault;
const publishVerifiedBytes = filesystem.publishVerifiedBytes;
const publishVerifiedFile = filesystem.publishVerifiedFile;
const finishVerifiedAtomic = filesystem.finishVerifiedAtomic;
const writeExclusive = filesystem.writeExclusive;
const syncDirectory = filesystem.syncDirectory;
const resetTestDirectorySyncCount = filesystem.resetTestDirectorySyncCount;
const readTestDirectorySyncCount = filesystem.readTestDirectorySyncCount;
const sortedObjectGroup = store_model.sortedObjectGroup;
const encodeMemberList = store_model.encodeMemberList;
const objectKey = store_model.objectKey;
const snapshotKey = store_model.snapshotKey;
const expectSnapshotProofDirectoryEmpty = store_model.expectSnapshotProofDirectoryEmpty;
const testOnlySnapshotProofEarlyUnwind = store_model.testOnlySnapshotProofEarlyUnwind;
const cleanToolEnvironment = store_model.cleanToolEnvironment;
const verifyToolchain = store_model.verifyToolchain;
const runCleanCapture = store_model.runCleanCapture;
const validateSnapshotListing = store_model.validateSnapshotListing;
const testPublishBytesCorruptIncoming = store_model.testPublishBytesCorruptIncoming;
const testPublishBytesCorruptFinal = store_model.testPublishBytesCorruptFinal;
const testOpenObjectLeaf = store_model.testOpenObjectLeaf;
const SourceSpecRow = canonical_source.SourceSpecRow;
const SourceSpec = canonical_source.SourceSpec;
const parseSourceSpecOwned = canonical_source.parseSourceSpecOwned;
const planCanonicalSourceSpec = canonical_source.planCanonicalSourceSpec;
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

pub const RegistrationSnapshot = registration.RegistrationSnapshot;
pub const parseRegistration = registration.parseRegistration;
pub const RegistrationGuard = registration.RegistrationGuard;

pub const FileIdentity = identity_model.FileIdentity;
pub const SnapshotIdentity = identity_model.SnapshotIdentity;

pub const CapacityObservation = capacity.CapacityObservation;
pub const CapacityRequirement = capacity.CapacityRequirement;
pub const Store = store_model.Store;

const dormant_candidate_key = authority_control.API.candidate_key;
const dormant_generation_key = authority_control.API.generation_key;
const dormant_lineage_key = authority_control.API.lineage_key;
const dormant_receipt_key = authority_control.API.receipt_key;
const dormant_candidate_magic = authority_control.API.candidate_magic;
const dormant_candidate_header = authority_control.API.candidate_header;
const dormant_lineage_magic = authority_control.API.lineage_magic;
const dormant_lineage_header = authority_control.API.lineage_header;
const dormant_receipt_magic = authority_control.API.receipt_magic;
const dormant_receipt_header = authority_control.API.receipt_header;
const dormant_real_control_root = authority_control.API.real_control_root;
const dormant_real_payload_root = authority_control.API.real_payload_root;
const dormant_real_source_root = authority_control.API.real_source_root;
const dormant_git_executable = authority_control.API.git_executable;
const dormant_git_bytes = authority_control.API.git_bytes;
const dormant_git_sha256 = authority_control.API.git_sha256;
const dormant_exact_real_copy_evidence_path =
    authority_control.API.exact_real_copy_evidence_path;
const dormant_exact_real_copy_evidence_sha256 =
    authority_control.API.exact_real_copy_evidence_sha256;
const dormant_exact_real_copy_evidence_max_bytes =
    authority_control.API.exact_real_copy_evidence_max_bytes;
const ControlGitObservation = authority_control.API.ControlObservation;
const DormantControlFileExpectationSpec =
    authority_control.API.ControlFileExpectationSpec;
const DormantAuthorityConfig = authority_control.API.AuthorityConfig;
const DormantAuthorityValidation = authority_control.API.AuthorityValidation;
const readDormantControlFile = authority_control.API.readControlFile;
const verifyDormantCopyEvidenceFromHeldRoot =
    authority_control.API.verifyCopyEvidenceFromHeldRoot;
const validateDormantAuthorityCandidate = authority_control.API.validateCandidate;
const validateAuthorityAncestry = authority_control.API.validateAncestry;
const DormantReadinessNetEffects = exact_real_observer.API.NetEffects;
const DormantExactAcceptanceSnapshotIdentity = exact_real_observer.API.SnapshotIdentity;
const DormantExactObserverRow = exact_real_observer.API.ObserverRow;
const DormantExactRealObservation = exact_real_observer.API.Observation;
const appendDormantReadinessField = exact_real_observer.API.appendReadinessField;
const appendDormantReadinessInteger = exact_real_observer.API.appendReadinessInteger;
const appendDormantLogicalState = exact_real_observer.API.appendLogicalState;
const captureDormantExactObserverRowFromDir = exact_real_observer.API.captureRowFromDir;
const appendDormantExactObserverLogicalRow = exact_real_observer.API.appendLogicalRow;
const finishDormantExactObservation = exact_real_observer.API.finishObservation;
const compareDormantExactRealObservations = exact_real_observer.API.compareObservations;
const captureDormantExactRealObservation = exact_real_observer.API.captureObservation;
const dormant_exact_real_acceptance_receipt_directory =
    exact_real_receipt.API.receipt_directory;
const dormant_exact_real_acceptance_receipt_basename =
    exact_real_receipt.API.receipt_basename;
const DormantExactAcceptanceEvidence = exact_real_receipt.API.Evidence;
const DormantExactAcceptanceParsedReceipt = exact_real_receipt.API.ParsedReceipt;
const DormantExactAcceptancePublishFault = exact_real_receipt.API.PublishFault;
const parseDormantExactAcceptanceInteger = exact_real_receipt.API.parseInteger;
const encodeDormantExactAcceptanceReceipt = exact_real_receipt.API.encode;
const parseDormantExactAcceptanceReceipt = exact_real_receipt.API.parse;
const validateDormantExactAcceptanceReceipt = exact_real_receipt.API.validate;
const readDormantExactAcceptanceReceipt = exact_real_receipt.API.read;
const publishDormantExactAcceptanceReceipt = exact_real_receipt.API.publish;
const openDormantExactAcceptanceReceiptDirectory = exact_real_receipt.API.openDirectory;
const dormant_test_root = synthetic_fixture.API.test_root;
const dormant_test_source_inventory_sha256 = synthetic_fixture.API.source_inventory_sha256;
const dormant_test_source_file_ledger_sha256 = synthetic_fixture.API.source_file_ledger_sha256;
const dormant_test_source_destination_ledger_sha256 =
    synthetic_fixture.API.source_destination_ledger_sha256;
const dormant_test_copy_evidence_path = synthetic_fixture.API.copy_evidence_path;
const dormant_test_copy_evidence_sha256 = synthetic_fixture.API.copy_evidence_sha256;
const DormantSyntheticFixture = synthetic_fixture.API.Fixture;
const DormantReadinessSnapshot = synthetic_fixture.API.ReadinessSnapshot;
const writeDormantFixtureRelative = synthetic_fixture.API.writeRelative;
const setDormantAbsoluteDirectoryMode = synthetic_fixture.API.setAbsoluteDirectoryMode;
const setDormantRelativeDirectoryModes = synthetic_fixture.API.setRelativeDirectoryModes;
const deleteDormantFixtureRelative = synthetic_fixture.API.deleteRelative;
const replaceDormantFixtureRelative = synthetic_fixture.API.replaceRelative;
const replaceDormantTestOwnedBytes = synthetic_fixture.API.replaceOwnedBytes;
const restoreDormantTestOwnedBytes = synthetic_fixture.API.restoreOwnedBytes;
const captureDormantReadinessState = synthetic_fixture.API.captureReadinessState;
const compareDormantReadinessStates = synthetic_fixture.API.compareReadinessStates;
const expectDormantReadinessEffects = synthetic_fixture.API.expectReadinessEffects;
const exerciseDormantReadinessOwnershipFailure =
    synthetic_fixture.API.exerciseReadinessOwnershipFailure;

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;
    var args = try std.process.Args.Iterator.initAllocator(init.minimal.args, allocator);
    defer args.deinit();
    _ = args.skip();
    const command = args.next() orelse return error.MissingCommand;
    if (std.mem.eql(u8, command, "resolve-authority")) {
        if (args.next() != null) return error.UnknownOption;
        const environment_value = init.minimal.environ.getAlloc(
            allocator,
            "ZLLVM_ARTIFACT_STORE",
        ) catch |err| switch (err) {
            error.EnvironmentVariableMissing => null,
            else => return err,
        };
        defer if (environment_value) |value| allocator.free(value);
        const resolved = try resolveAuthority(allocator, environment_value, main_git_common_dir);
        defer allocator.free(resolved);
        try writeStdoutLine(io, resolved);
        return;
    }
    if (!std.mem.eql(u8, command, "materialize-spec")) return error.UnsupportedCommand;
    const mode = args.next() orelse return error.MissingMaterializeMode;
    const spec_path = args.next() orelse return error.MissingSourceSpecification;
    if (args.next() != null) return error.UnknownOption;
    if (!std.mem.eql(u8, spec_path, canonical_source_spec_path)) {
        return error.UnexpectedSourceSpecification;
    }
    if (std.mem.eql(u8, mode, "plan")) {
        const proposed = try planCanonicalSourceSpec(allocator, io, spec_path);
        defer allocator.free(proposed);
        try writeStdout(io, proposed);
        return;
    }
    if (!std.mem.eql(u8, mode, "publish")) return error.UnknownMaterializeMode;
    const environment_value = try init.minimal.environ.getAlloc(allocator, "ZLLVM_ARTIFACT_STORE");
    defer allocator.free(environment_value);
    const root = try resolveAuthority(allocator, environment_value, main_git_common_dir);
    defer allocator.free(root);
    const manifest = try canonical_source.publishCanonicalSourceSpec(
        allocator,
        io,
        spec_path,
        root,
        createAbsoluteDirectorySynced,
    );
    defer allocator.free(manifest);
    try writeStdout(io, manifest);
}

fn writeStdout(io: std.Io, text: []const u8) !void {
    var buffer: [1024]u8 = undefined;
    var writer = std.Io.File.stdout().writer(io, &buffer);
    try writer.interface.writeAll(text);
    try writer.interface.flush();
}

fn writeStdoutLine(io: std.Io, text: []const u8) !void {
    var buffer: [1024]u8 = undefined;
    var writer = std.Io.File.stdout().writer(io, &buffer);
    try writer.interface.print("{s}\n", .{text});
    try writer.interface.flush();
}

fn prepareStoreRoot(
    allocator: std.mem.Allocator,
    io: std.Io,
    guard: *const RegistrationGuard,
    root_path: []const u8,
) !void {
    return canonical_source.prepareStoreRoot(
        allocator,
        io,
        guard,
        root_path,
        createAbsoluteDirectorySynced,
    );
}

const dormant_exact_real_source_manifest_sha256 =
    "61b7426bd52a3a139999f17f36d91ecaab954e6132fe36eca541480cdf31104d";
const dormant_exact_real_source_inventory_sha256 =
    "3234fb508d370878efe082cf1accb5af3b488372bf3f1ee7e9e87408a37a2d7c";
const dormant_exact_real_source_file_ledger_sha256 =
    "a06c48e1549d16b9f924cc2b5f0404e60d7755a785bf3a4a23311c2383279a65";
const dormant_exact_real_source_destination_ledger_sha256 =
    "4c29709b9ef9242dd799ab52d346cdf302f5728d35e37e0d78063e892a6cf9e8";
const dormant_exact_real_acceptance_environment =
    "ZLLVM_INBOX206CQ_EXACT_REAL_ACCEPTANCE";
const dormant_exact_real_acceptance_token =
    "INBOX-206CQ-EXACT-REAL-ACCEPTANCE-V1";
const DormantExactRealValidationInput = struct {
    allocator: std.mem.Allocator,
    io: std.Io,
    source_manifest_sha256: []const u8,
    source_inventory_sha256: []const u8,
    source_file_ledger_sha256: []const u8,
    source_destination_ledger_sha256: []const u8,
    copy_evidence_path: []const u8,
    copy_evidence_sha256: []const u8,
};

const DormantValidationReadinessInput = union(enum) {
    exact_real: DormantExactRealValidationInput,
    synthetic: *const DormantAuthorityConfig,
};

fn invokeDormantValidationReadinessForTest(
    input: DormantValidationReadinessInput,
) !DormantAuthorityValidation {
    if (!builtin.is_test) return error.TestOnlyOperation;
    return switch (input) {
        .exact_real => |exact| blk: {
            var config = try DormantAuthorityConfig.initExactRealCandidate(
                exact.allocator,
                exact.io,
                exact.source_manifest_sha256,
                exact.source_inventory_sha256,
                exact.source_file_ledger_sha256,
                exact.source_destination_ledger_sha256,
                exact.copy_evidence_path,
                exact.copy_evidence_sha256,
            );
            defer config.deinit();
            break :blk try validateDormantAuthorityCandidate(&config);
        },
        .synthetic => |config| validateDormantAuthorityCandidate(config),
    };
}

fn callDormantValidationReadinessForTest(
    input: DormantValidationReadinessInput,
) !DormantAuthorityValidation {
    if (!builtin.is_test) return error.TestOnlyOperation;
    return invokeDormantValidationReadinessForTest(input);
}

pub fn resolveAuthority(
    allocator: std.mem.Allocator,
    environment_value: ?[]const u8,
    git_common_dir: []const u8,
) ![]u8 {
    if (environment_value) |value| {
        if (!std.fs.path.isAbsolute(value)) return error.PathNotAbsolute;
        const normalized = try std.fs.path.resolve(allocator, &.{value});
        errdefer allocator.free(normalized);
        if (!std.mem.eql(u8, normalized, value)) return error.PathNotNormalized;
        return normalized;
    }
    if (!std.fs.path.isAbsolute(git_common_dir) or
        !std.mem.eql(u8, std.fs.path.basename(git_common_dir), ".git"))
    {
        return error.InvalidGitCommonDirectory;
    }
    const main_root = std.fs.path.dirname(git_common_dir) orelse return error.InvalidGitCommonDirectory;
    const parent = std.fs.path.dirname(main_root) orelse return error.InvalidGitCommonDirectory;
    const name = std.fs.path.basename(main_root);
    const store_name = try std.fmt.allocPrint(allocator, "{s}-artifacts", .{name});
    defer allocator.free(store_name);
    return std.fs.path.join(allocator, &.{ parent, store_name });
}

fn createAbsoluteDirectorySynced(
    io: std.Io,
    absolute_path: []const u8,
) !void {
    const parent_path = std.fs.path.dirname(absolute_path) orelse return error.InvalidRootPath;
    const basename = std.fs.path.basename(absolute_path);
    var parent = try std.Io.Dir.openDirAbsolute(io, parent_path, .{
        .iterate = true,
        .follow_symlinks = false,
    });
    defer parent.close(io);
    try parent.createDir(io, basename, .default_dir);
    var created = try parent.openDir(io, basename, .{
        .iterate = true,
        .follow_symlinks = false,
    });
    defer created.close(io);
    try syncDirectory(created);
    try syncDirectory(parent);
}

fn removeAbsoluteDirectorySynced(io: std.Io, absolute_path: []const u8) !void {
    const parent_path = std.fs.path.dirname(absolute_path) orelse return error.InvalidRootPath;
    const basename = std.fs.path.basename(absolute_path);
    var parent = try std.Io.Dir.openDirAbsolute(io, parent_path, .{
        .iterate = true,
        .follow_symlinks = false,
    });
    defer parent.close(io);
    try parent.deleteTree(io, basename);
    try syncDirectory(parent);
}

fn expectDormantReceiptIdentityMismatch(
    fixture: *DormantSyntheticFixture,
    config: *const DormantAuthorityConfig,
    receipt: []const u8,
) !void {
    if (!builtin.is_test) return error.TestOnlyOperation;
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
    if (!builtin.is_test) return error.TestOnlyOperation;
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
    if (!builtin.is_test) return error.TestOnlyOperation;
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
    if (!builtin.is_test) return error.TestOnlyOperation;
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

fn requireDormantExactRealAcceptanceGate(token: ?[]const u8) !void {
    if (!builtin.is_test) return error.TestOnlyOperation;
    const value = token orelse return error.SkipZigTest;
    if (!std.mem.eql(u8, value, dormant_exact_real_acceptance_token)) {
        return error.SkipZigTest;
    }
}

fn requireDormantExactAcceptanceValidation(
    validation: DormantAuthorityValidation,
) !void {
    if (!std.mem.eql(
        u8,
        &validation.manifest_sha256,
        dormant_exact_real_source_manifest_sha256,
    ) or
        validation.payload_files != 20 or
        validation.payload_bytes != 9_970_364 or
        validation.objects != 18 or
        validation.snapshots != 2)
    {
        return error.DormantAcceptanceValidationMismatch;
    }
}

fn runDormantExactRealAcceptanceForTest(
    allocator: std.mem.Allocator,
    io: std.Io,
    token: ?[]const u8,
) !void {
    if (!builtin.is_test) return error.TestOnlyOperation;
    try requireDormantExactRealAcceptanceGate(token);

    var config = try DormantAuthorityConfig.initExactRealCandidate(
        allocator,
        io,
        dormant_exact_real_source_manifest_sha256,
        dormant_exact_real_source_inventory_sha256,
        dormant_exact_real_source_file_ledger_sha256,
        dormant_exact_real_source_destination_ledger_sha256,
        dormant_exact_real_copy_evidence_path,
        dormant_exact_real_copy_evidence_sha256,
    );
    defer config.deinit();
    var before = try captureDormantExactRealObservation(&config);
    defer before.deinit();
    const validation = try validateDormantAuthorityCandidate(&config);
    try requireDormantExactAcceptanceValidation(validation);
    var after = try captureDormantExactRealObservation(&config);
    defer after.deinit();
    const effects = compareDormantExactRealObservations(&before, &after);
    if (!effects.isUnchanged()) return error.DormantAcceptanceObservedMutation;
    const evidence: DormantExactAcceptanceEvidence = .{
        .control_root = config.control_root,
        .authority_root = config.authority_root,
        .payload_root = config.payload_root,
        .source_root = config.source_root,
        .source_manifest_sha256 = &config.source_manifest_sha256,
        .source_inventory_sha256 = &config.expected_source_inventory_sha256,
        .source_file_ledger_sha256 = &config.expected_source_file_ledger_sha256,
        .source_destination_ledger_sha256 = &config.expected_source_destination_ledger_sha256,
        .copy_evidence_path = config.expected_copy_evidence_path,
        .copy_evidence_sha256 = &config.expected_copy_evidence_sha256,
        .registration_full_sha256 = &config.expected_registration_full_hash,
        .registration_path_sha256 = &config.expected_registration_path_hash,
        .registration_topology_sha256 = &config.expected_registration_topology_hash,
        .registration_non_main_sha256 = &config.expected_registration_non_main_hash,
        .before_snapshot = before.identity,
        .after_snapshot = after.identity,
        .validation = validation,
        .effects = effects,
    };
    const receipt = try encodeDormantExactAcceptanceReceipt(allocator, evidence);
    defer allocator.free(receipt);
    var receipt_directory = try openDormantExactAcceptanceReceiptDirectory(io);
    defer receipt_directory.close(io);
    try publishDormantExactAcceptanceReceipt(
        allocator,
        io,
        receipt_directory,
        receipt,
        evidence,
        .none,
    );
}

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
    if (!builtin.is_test) return error.TestOnlyOperation;
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
    const effects = compareDormantExactRealObservations(before, after);
    try expectDormantReadinessEffects(effects, expected);
    return effects;
}

fn expectDormantAcceptanceDirectoryEmpty(io: std.Io, directory: std.Io.Dir) !void {
    var iterator = directory.iterate();
    if (try iterator.next(io) != null) return error.DormantAcceptanceTemporaryRetained;
}

test "dormant exact-real acceptance gate precedes real paths" {
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

test "dormant exact-real copy evidence verifies actual held-root bytes" {
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

test "dormant exact-real copy evidence is unchanged in finite observer" {
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

test "dormant exact-real acceptance receipt encoding is canonical" {
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

test "dormant exact-real observer detects finite path and logical controls" {
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

test "dormant exact-real acceptance receipt publication is durable and no-replace" {
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

test "INBOX-206CQ exact-real acceptance one-shot" {
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

test "dormant readiness snapshot ownership unwinds later allocation failure" {
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

test "dormant authority candidate validates only closed synthetic state" {
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

test "authority resolution is closed and default remains read only" {
    const allocator = std.testing.allocator;
    const forced = try resolveAuthority(allocator, synthetic_store, "/home/oleg/prog/z_llvm/.git");
    defer allocator.free(forced);
    try std.testing.expectEqualStrings(synthetic_store, forced);
    const fallback = try resolveAuthority(allocator, null, "/home/oleg/prog/z_llvm/.git");
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

test "published snapshot generator binds every member to its exact object key" {
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
    var manifest = try parseManifest(allocator, canonical);
    defer manifest.deinit(allocator);
    const reencoded = try encodeManifest(allocator, manifest);
    defer allocator.free(reencoded);
    try std.testing.expectEqualStrings(canonical, reencoded);

    var generated_member_count: usize = 0;
    for (manifest.rows) |row| {
        if (row.kind != .snapshot_member) continue;
        const target = findRow(manifest, row.target_id) orelse return error.MissingTargetObject;
        try std.testing.expectEqual(RowKind.object, target.kind);
        try std.testing.expectEqualStrings(target.key, row.key);
        try std.testing.expectEqualStrings(target.key, row.member_path);
        try std.testing.expect(sameIdentity(row, target));
        generated_member_count += 1;
    }
    try std.testing.expectEqual(@as(usize, 2), generated_member_count);

    const dash_keys = try mutateGeneratedMembers(allocator, canonical, .dash_keys);
    defer allocator.free(dash_keys);
    try std.testing.expectError(
        error.ConflictingManifestKey,
        parseManifest(allocator, dash_keys),
    );
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

test "snapshot listing validation is closed to sorted regular members" {
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

test "canonical calls source specification is closed and produces canonical proposed rows" {
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
    var manifest = try parseManifest(allocator, proposed);
    defer manifest.deinit(allocator);
    const ac_ref = findRow(manifest, "calls/input/accepted-cohort-ac285/v1") orelse
        return error.MissingLogicalReference;
    const ac_object = findRow(
        manifest,
        "object/sha256/d8da86cae494d7d4a58053ab24b1e8be944859263072b85ffa164880b0110cd4",
    ) orelse return error.MissingTargetObject;
    try std.testing.expectEqual(@as(u16, 0o664), ac_ref.mode);
    try std.testing.expectEqual(@as(u16, 0o444), ac_object.mode);
    try std.testing.expect(logicalRefMatchesTarget(ac_ref, ac_object));
    const reencoded = try encodeManifest(allocator, manifest);
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

test "synthetic store publishes verifies snapshots and resolves without overwrite" {
    const allocator = std.testing.allocator;
    const io = std.testing.io;
    const forced = try std.testing.environ.getAlloc(allocator, "ZLLVM_ARTIFACT_STORE");
    defer allocator.free(forced);
    try std.testing.expectEqualStrings(synthetic_store, forced);
    const resolved_from_environment = try resolveAuthority(allocator, forced, main_git_common_dir);
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
    const protected_ancestor = std.fs.path.dirname(protected) orelse return error.InvalidProtectedPath;
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
    const compatibility_root = try std.fs.path.join(allocator, &.{ synthetic_store, "compatibility-tests" });
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
    const stale_root = try std.fs.path.join(allocator, &.{ synthetic_store, "compatibility-stale" });
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
    const symlink_root = try std.fs.path.join(allocator, &.{ synthetic_store, "compatibility-symlink" });
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
