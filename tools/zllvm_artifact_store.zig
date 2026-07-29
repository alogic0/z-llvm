const std = @import("std");
const builtin = @import("builtin");
const authority_control = @import("zllvm_artifact_store/authority_control.zig");
const capacity = @import("zllvm_artifact_store/capacity.zig");
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
const prior_failed_materialize_store = "/home/oleg/prog/z_llvm-inbox194-artifact-store-synthetic";
const prior_failed_materialize_continuation_store =
    "/home/oleg/prog/z_llvm-inbox194a-artifact-store-synthetic";
const prior_failed_materialize_second_continuation_store =
    "/home/oleg/prog/z_llvm-inbox194b-artifact-store-synthetic";
const prior_failed_materialize_third_continuation_store =
    "/home/oleg/prog/z_llvm-inbox194c-artifact-store-synthetic";
const synthetic_store = "/home/oleg/prog/z_llvm-inbox194d-artifact-store-synthetic";
const default_store = "/home/oleg/prog/z_llvm-artifacts";
const main_repository = registration.main_repository;
const main_git_common_dir = registration.main_git_common_dir;
const canonical_source_spec_path = "docs/evidence/inbox194_calls_canonical_source_spec_v1.tsv";
const canonical_source_spec_sha = "0dd908eed246b09fbea8fd87241ce899b100823b8d83c7223d4e48928e7c599b";
const proposed_live_manifest_path = "docs/evidence/inbox194_calls_proposed_live_manifest_v1.tsv";

const schema_magic = manifest_model.schema_magic;
const schema_header = manifest_model.schema_header;
const snapshot_format = manifest_model.snapshot_format;
const snapshot_recipe = store_model.snapshot_recipe;
const snapshot_recipe_sha = manifest_model.snapshot_recipe_sha;
const max_snapshot_members = manifest_model.max_snapshot_members;
const source_spec_magic = "zllvm-calls-canonical-source-spec-v1";
const source_spec_header =
    "logical_id\tsource_set_id\tsource_path\tsha256\tbytes\tsource_mode\tmedia_type\tretention_class\tobject_key\tmember_path\tgroup_id\tsnapshot_id\tsnapshot_format\trecipe_sha256\tconstituent_sha256\tgroup_manifest_sha256";
const source_set_ac285 = "calls/input/accepted-cohort-ac285/v1";
const source_set_compiler_rt = "calls/input/compiler-rt-v1/raw/v1";
const source_set_coverage = "calls/input/validation-v3/coverage-bundle/v1";
const group_calls_inputs = "calls-inputs";
const group_calls_validation_inputs = "calls-validation-inputs";
const snapshot_calls_inputs = "snapshot/calls-inputs/v1";
const snapshot_calls_validation_inputs = "snapshot/calls-validation-inputs/v1";
const retained_materialize_object_sha =
    "d8da86cae494d7d4a58053ab24b1e8be944859263072b85ffa164880b0110cd4";
const retained_materialize_object_bytes = 7_215_373;

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
const validateCanonicalField = manifest_model.validateCanonicalField;
const encodeField = manifest_model.encodeField;
const validateLogicalId = manifest_model.validateLogicalId;
const validateRelativeKey = manifest_model.validateRelativeKey;
const validateSha = manifest_model.validateSha;
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
const encodeConstituentManifest = store_model.encodeConstituentManifest;
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

const SourceSpecRow = struct {
    logical_id: []const u8,
    source_set_id: []const u8,
    source_path: []const u8,
    sha256: []const u8,
    bytes: u64,
    source_mode: u16,
    media_type: []const u8,
    retention_class: RetentionClass,
    object_key: []const u8,
    member_path: []const u8,
    group_id: []const u8,
    snapshot_id: []const u8,
    snapshot_format: []const u8,
    recipe_sha256: []const u8,
    constituent_sha256: []const u8,
    group_manifest_sha256: []const u8,
};

const SourceSpec = struct {
    storage: []u8,
    rows: []SourceSpecRow,

    fn deinit(spec: *SourceSpec, allocator: std.mem.Allocator) void {
        allocator.free(spec.rows);
        allocator.free(spec.storage);
        spec.* = undefined;
    }
};

const PublishedObject = struct {
    identity: FileIdentity,
    source_row_index: usize,
};

const PublishedSnapshot = struct {
    group_id: []const u8,
    snapshot_id: []const u8,
    identity: SnapshotIdentity,
};

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
    const manifest = try publishCanonicalSourceSpec(allocator, io, spec_path, root);
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

fn loadCanonicalSourceSpec(
    allocator: std.mem.Allocator,
    io: std.Io,
    spec_path: []const u8,
) !SourceSpec {
    if (!std.mem.eql(u8, spec_path, canonical_source_spec_path)) {
        return error.UnexpectedSourceSpecification;
    }
    const text = try std.Io.Dir.cwd().readFileAlloc(
        io,
        spec_path,
        allocator,
        .limited(256 * 1024),
    );
    errdefer allocator.free(text);
    if (!std.mem.eql(u8, &sha256Hex(text), canonical_source_spec_sha)) {
        return error.SourceSpecificationHashMismatch;
    }
    return parseSourceSpecOwned(allocator, text);
}

fn parseSourceSpecOwned(allocator: std.mem.Allocator, storage: []u8) !SourceSpec {
    errdefer allocator.free(storage);
    if (storage.len == 0 or storage[storage.len - 1] != '\n') {
        return error.NonCanonicalSourceSpecification;
    }
    var lines = std.mem.splitScalar(u8, storage, '\n');
    if (!std.mem.eql(u8, lines.next() orelse return error.MissingSourceSpecMagic, source_spec_magic)) {
        return error.UnknownSourceSpecVersion;
    }
    if (!std.mem.eql(u8, lines.next() orelse return error.MissingSourceSpecHeader, source_spec_header)) {
        return error.UnknownOrReorderedSourceSpecField;
    }
    var rows: std.ArrayList(SourceSpecRow) = .empty;
    errdefer rows.deinit(allocator);
    while (lines.next()) |line| {
        if (line.len == 0) {
            if (lines.peek() == null) break;
            return error.EmptySourceSpecRow;
        }
        var fields: [16][]const u8 = undefined;
        var field_it = std.mem.splitScalar(u8, line, '\t');
        for (&fields) |*field| field.* = field_it.next() orelse
            return error.MissingSourceSpecField;
        if (field_it.next() != null) return error.UnknownSourceSpecField;
        for (fields) |field| try validateCanonicalField(allocator, field);
        const row: SourceSpecRow = .{
            .logical_id = fields[0],
            .source_set_id = fields[1],
            .source_path = fields[2],
            .sha256 = fields[3],
            .bytes = std.fmt.parseInt(u64, fields[4], 10) catch
                return error.InvalidByteCount,
            .source_mode = std.fmt.parseInt(u16, fields[5], 8) catch return error.InvalidMode,
            .media_type = fields[6],
            .retention_class = parseEnum(RetentionClass, fields[7]) orelse
                return error.UnknownRetentionClass,
            .object_key = fields[8],
            .member_path = fields[9],
            .group_id = fields[10],
            .snapshot_id = fields[11],
            .snapshot_format = fields[12],
            .recipe_sha256 = fields[13],
            .constituent_sha256 = fields[14],
            .group_manifest_sha256 = fields[15],
        };
        try validateSourceSpecRow(allocator, row);
        if (rows.items.len != 0 and
            std.mem.order(u8, rows.items[rows.items.len - 1].logical_id, row.logical_id) != .lt)
        {
            return error.NonCanonicalSourceSpecOrder;
        }
        for (rows.items) |prior| {
            if (std.mem.eql(u8, prior.logical_id, row.logical_id)) {
                return error.DuplicateLogicalId;
            }
            if (std.mem.eql(u8, prior.source_path, row.source_path)) {
                return error.DuplicateSourcePath;
            }
        }
        try rows.append(allocator, row);
    }
    const owned = try rows.toOwnedSlice(allocator);
    errdefer allocator.free(owned);
    const spec: SourceSpec = .{ .storage = storage, .rows = owned };
    try validateSourceSpecRelationships(allocator, spec);
    return spec;
}

fn validateSourceSpecRow(allocator: std.mem.Allocator, row: SourceSpecRow) !void {
    try validateLogicalId(row.logical_id);
    try validateLogicalId(row.source_set_id);
    try validateRelativeKey(row.source_path);
    try validateSha(row.sha256);
    if (row.bytes == 0 or row.source_mode > 0o7777) return error.InvalidSourceIdentity;
    if (row.retention_class != .canonical_input) return error.InvalidSourceRetentionClass;
    try validateRelativeKey(row.object_key);
    try validateRelativeKey(row.member_path);
    try validateLogicalId(row.group_id);
    try validateLogicalId(row.snapshot_id);
    try validateSha(row.recipe_sha256);
    try validateSha(row.constituent_sha256);
    try validateSha(row.group_manifest_sha256);
    if (!std.mem.eql(u8, row.snapshot_format, snapshot_format) or
        !std.mem.eql(u8, row.recipe_sha256, snapshot_recipe_sha) or
        !std.mem.eql(u8, row.object_key, row.member_path))
    {
        return error.SourceSnapshotContractMismatch;
    }
    const expected_key = try objectKey(allocator, row.sha256);
    defer allocator.free(expected_key);
    if (!std.mem.eql(u8, row.object_key, expected_key)) return error.ObjectKeyShaMismatch;
}

fn validateSourceSpecRelationships(allocator: std.mem.Allocator, spec: SourceSpec) !void {
    if (spec.rows.len != 19) return error.SourceSpecRowCountMismatch;
    var ac_count: usize = 0;
    var compiler_count: usize = 0;
    var coverage_count: usize = 0;
    for (spec.rows) |row| {
        if (std.mem.eql(u8, row.source_set_id, source_set_ac285)) {
            ac_count += 1;
            if (!std.mem.eql(u8, row.group_id, group_calls_inputs) or
                !std.mem.eql(u8, row.snapshot_id, snapshot_calls_inputs))
            {
                return error.SourceSetGroupMismatch;
            }
        } else if (std.mem.eql(u8, row.source_set_id, source_set_compiler_rt)) {
            compiler_count += 1;
            if (!std.mem.eql(u8, row.group_id, group_calls_inputs) or
                !std.mem.eql(u8, row.snapshot_id, snapshot_calls_inputs))
            {
                return error.SourceSetGroupMismatch;
            }
        } else if (std.mem.eql(u8, row.source_set_id, source_set_coverage)) {
            coverage_count += 1;
            if (!std.mem.eql(u8, row.group_id, group_calls_validation_inputs) or
                !std.mem.eql(u8, row.snapshot_id, snapshot_calls_validation_inputs))
            {
                return error.SourceSetGroupMismatch;
            }
        } else return error.UnknownSourceSet;
        for (spec.rows) |other| {
            if (std.mem.eql(u8, row.sha256, other.sha256) and
                (row.bytes != other.bytes or row.source_mode != other.source_mode or
                    !std.mem.eql(u8, row.object_key, other.object_key)))
            {
                return error.ConflictingSourceIdentity;
            }
        }
    }
    if (ac_count != 1 or compiler_count != 3 or coverage_count != 15) {
        return error.SourceSetCountMismatch;
    }
    try validateDeclaredConstituent(allocator, spec, group_calls_inputs);
    try validateDeclaredConstituent(allocator, spec, group_calls_validation_inputs);
}

fn validateDeclaredConstituent(
    allocator: std.mem.Allocator,
    spec: SourceSpec,
    group_id: []const u8,
) !void {
    var objects: std.ArrayList(FileIdentity) = .empty;
    defer objects.deinit(allocator);
    for (spec.rows) |row| {
        if (!std.mem.eql(u8, row.group_id, group_id)) continue;
        var duplicate = false;
        for (objects.items) |object| {
            if (std.mem.eql(u8, object.key, row.object_key)) duplicate = true;
        }
        if (!duplicate) try objects.append(allocator, .{
            .sha256 = row.sha256[0..64].*,
            .bytes = row.bytes,
            .mode = 0o444,
            .key = @constCast(row.object_key),
        });
    }
    const sorted = try sortedObjectGroup(allocator, objects.items);
    defer allocator.free(sorted);
    const text = try encodeConstituentManifest(allocator, sorted);
    defer allocator.free(text);
    const actual = sha256Hex(text);
    for (spec.rows) |row| {
        if (std.mem.eql(u8, row.group_id, group_id) and
            !std.mem.eql(u8, &actual, row.constituent_sha256))
        {
            return error.ConstituentMismatch;
        }
    }
}

fn planCanonicalSourceSpec(
    allocator: std.mem.Allocator,
    io: std.Io,
    spec_path: []const u8,
) ![]u8 {
    var spec = try loadCanonicalSourceSpec(allocator, io, spec_path);
    defer spec.deinit(allocator);
    var guard = try RegistrationGuard.init(allocator, io);
    defer guard.deinit();
    try verifyCanonicalSources(allocator, io, &guard, spec);
    const manifest = try proposedManifestForSourceSpec(allocator, spec);
    errdefer allocator.free(manifest);
    try validateProposedManifestFieldCounts(manifest);
    var parsed = try parseManifest(allocator, manifest);
    defer parsed.deinit(allocator);
    const encoded = try encodeManifest(allocator, parsed);
    defer allocator.free(encoded);
    if (!std.mem.eql(u8, encoded, manifest)) return error.NonCanonicalManifest;
    const tracked = try std.Io.Dir.cwd().readFileAlloc(
        io,
        proposed_live_manifest_path,
        allocator,
        .limited(256 * 1024),
    );
    defer allocator.free(tracked);
    try validateProposedManifestFieldCounts(tracked);
    if (!std.mem.eql(u8, manifest, tracked)) return error.ProposedManifestByteMismatch;
    try guard.assertCurrent();
    return manifest;
}

fn validateProposedManifestFieldCounts(text: []const u8) !void {
    if (text.len == 0 or text[text.len - 1] != '\n') {
        return error.NonCanonicalManifest;
    }
    var lines = std.mem.splitScalar(u8, text, '\n');
    _ = lines.next() orelse return error.MissingSchemaMagic;
    _ = lines.next() orelse return error.MissingSchemaHeader;
    while (lines.next()) |line| {
        if (line.len == 0) {
            if (lines.peek() == null) break;
            return error.EmptyManifestRow;
        }
        var field_count: usize = 1;
        for (line) |byte| {
            if (byte == '\t') field_count += 1;
        }
        if (field_count != 17) return error.ProposedManifestFieldCountMismatch;
    }
}

fn verifyCanonicalSources(
    allocator: std.mem.Allocator,
    io: std.Io,
    guard: *const RegistrationGuard,
    spec: SourceSpec,
) !void {
    var ac_virtual: std.ArrayList(u8) = .empty;
    defer ac_virtual.deinit(allocator);
    var compiler_virtual: std.ArrayList(u8) = .empty;
    defer compiler_virtual.deinit(allocator);
    var coverage_virtual: std.ArrayList(u8) = .empty;
    defer coverage_virtual.deinit(allocator);
    const coverage_prefix =
        "tmp/o2_calls_perf/compiler_rt_v1/inbox187_baseline_validation_contract_bundle/";

    for (spec.rows) |row| {
        const absolute = try std.fs.path.join(allocator, &.{ main_repository, row.source_path });
        defer allocator.free(absolute);
        try guard.assertReadSource(absolute, absolute);
        var file = try std.Io.Dir.openFileAbsolute(io, absolute, .{
            .allow_directory = false,
            .follow_symlinks = false,
        });
        defer file.close(io);
        var actual = try identityOfOpenFileAnyMode(allocator, io, file);
        defer actual.deinit(allocator);
        if (!std.mem.eql(u8, &actual.sha256, row.sha256) or
            actual.bytes != row.bytes or actual.mode != row.source_mode)
        {
            return error.CanonicalSourceIdentityMismatch;
        }
        const output = if (std.mem.eql(u8, row.source_set_id, source_set_ac285))
            &ac_virtual
        else if (std.mem.eql(u8, row.source_set_id, source_set_compiler_rt))
            &compiler_virtual
        else
            &coverage_virtual;
        const label = if (std.mem.eql(u8, row.source_set_id, source_set_coverage))
            if (std.mem.startsWith(u8, row.source_path, coverage_prefix))
                row.source_path[coverage_prefix.len..]
            else
                return error.CoverageSourcePrefixMismatch
        else
            row.source_path;
        try output.print(allocator, "F\t{s}\t{}\t{o}\t{s}\n", .{
            label,
            actual.bytes,
            actual.mode,
            &actual.sha256,
        });
    }
    try validateVirtualManifest(spec, source_set_ac285, ac_virtual.items);
    try validateVirtualManifest(spec, source_set_compiler_rt, compiler_virtual.items);
    try validateVirtualManifest(spec, source_set_coverage, coverage_virtual.items);
    try guard.assertCurrent();
}

fn validateVirtualManifest(
    spec: SourceSpec,
    source_set_id: []const u8,
    text: []const u8,
) !void {
    const actual = sha256Hex(text);
    for (spec.rows) |row| {
        if (std.mem.eql(u8, row.source_set_id, source_set_id)) {
            if (!std.mem.eql(u8, &actual, row.group_manifest_sha256)) {
                return error.SourceSetManifestMismatch;
            }
            return;
        }
    }
    return error.UnknownSourceSet;
}

fn proposedManifestForSourceSpec(
    allocator: std.mem.Allocator,
    spec: SourceSpec,
) ![]u8 {
    var output: std.ArrayList(u8) = .empty;
    errdefer output.deinit(allocator);
    try appendManifestPreamble(allocator, &output);
    for (spec.rows, 0..) |row, index| {
        var first = true;
        for (spec.rows[0..index]) |prior| {
            if (std.mem.eql(u8, prior.sha256, row.sha256)) first = false;
        }
        if (!first) continue;
        const object_id = try std.fmt.allocPrint(allocator, "object/sha256/{s}", .{row.sha256});
        defer allocator.free(object_id);
        try appendManifestRowText(allocator, &output, .{
            .kind = .object,
            .logical_id = object_id,
            .sha256 = row.sha256,
            .bytes = row.bytes,
            .mode = 0o444,
            .media_type = row.media_type,
            .provenance = "inbox194-source-spec",
            .reconstruction = "exact-source-publication",
            .retention_class = .canonical_input,
            .status = .future_required,
            .key = row.object_key,
            .target_id = "-",
            .snapshot_id = "-",
            .member_path = "-",
            .snapshot_format = "-",
            .recipe_sha256 = "-",
            .constituent_sha256 = "-",
        });
    }
    for (spec.rows) |row| {
        const object_id = try std.fmt.allocPrint(allocator, "object/sha256/{s}", .{row.sha256});
        defer allocator.free(object_id);
        const planned_key = try std.fmt.allocPrint(allocator, "planned/{s}", .{row.logical_id});
        defer allocator.free(planned_key);
        try appendManifestRowText(allocator, &output, .{
            .kind = .logical_ref,
            .logical_id = row.logical_id,
            .sha256 = row.sha256,
            .bytes = row.bytes,
            .mode = row.source_mode,
            .media_type = row.media_type,
            .provenance = "inbox194-source-spec",
            .reconstruction = "materialize-spec-publish",
            .retention_class = .canonical_input,
            .status = .future_required,
            .key = planned_key,
            .target_id = object_id,
            .snapshot_id = "-",
            .member_path = "-",
            .snapshot_format = "-",
            .recipe_sha256 = "-",
            .constituent_sha256 = "-",
        });
    }
    return output.toOwnedSlice(allocator);
}

fn publishCanonicalSourceSpec(
    allocator: std.mem.Allocator,
    io: std.Io,
    spec_path: []const u8,
    root_path: []const u8,
) ![]u8 {
    var spec = try loadCanonicalSourceSpec(allocator, io, spec_path);
    defer spec.deinit(allocator);
    var guard = try RegistrationGuard.init(allocator, io);
    defer guard.deinit();
    try guard.assertStoreRoot(root_path);
    try verifyCanonicalSources(allocator, io, &guard, spec);
    try prepareStoreRoot(allocator, io, &guard, root_path);

    var store = try Store.open(allocator, io, &guard, root_path);
    defer store.deinit();
    var required_bytes: u64 = 0;
    for (spec.rows, 0..) |row, index| {
        var first = true;
        for (spec.rows[0..index]) |prior| {
            if (std.mem.eql(u8, prior.sha256, row.sha256)) first = false;
        }
        if (first) required_bytes = std.math.add(u64, required_bytes, row.bytes) catch
            return error.Overflow;
    }
    _ = try store.preflightCapacity(.{
        .validation_reserve = 0,
        .primary_bytes = required_bytes,
        .snapshot_bound = required_bytes * 2,
        .manifest_bound = 1024 * 1024,
        .required_inodes = spec.rows.len * 4 + 64,
    });

    var objects: std.ArrayList(FileIdentity) = .empty;
    defer {
        for (objects.items) |*object| object.deinit(allocator);
        objects.deinit(allocator);
    }
    var object_rows: std.ArrayList(usize) = .empty;
    defer object_rows.deinit(allocator);
    for (spec.rows, 0..) |row, index| {
        var duplicate = false;
        for (objects.items) |object| {
            if (std.mem.eql(u8, &object.sha256, row.sha256)) duplicate = true;
        }
        if (duplicate) continue;
        const absolute = try std.fs.path.join(allocator, &.{ main_repository, row.source_path });
        defer allocator.free(absolute);
        var object = try store.publishFile(absolute, absolute);
        errdefer object.deinit(allocator);
        if (!std.mem.eql(u8, &object.sha256, row.sha256) or
            object.bytes != row.bytes or object.mode != 0o444 or
            !std.mem.eql(u8, object.key, row.object_key))
        {
            return error.PublishedSourceIdentityMismatch;
        }
        try objects.append(allocator, object);
        try object_rows.append(allocator, index);
    }

    var call_objects: std.ArrayList(FileIdentity) = .empty;
    defer call_objects.deinit(allocator);
    var validation_objects: std.ArrayList(FileIdentity) = .empty;
    defer validation_objects.deinit(allocator);
    for (objects.items, object_rows.items) |object, row_index| {
        if (std.mem.eql(u8, spec.rows[row_index].group_id, group_calls_inputs)) {
            try call_objects.append(allocator, object);
        } else {
            try validation_objects.append(allocator, object);
        }
    }
    var calls_snapshot = try store.publishSnapshot(call_objects.items);
    defer calls_snapshot.deinit(allocator);
    var validation_snapshot = try store.publishSnapshot(validation_objects.items);
    defer validation_snapshot.deinit(allocator);
    try store.verifySnapshot(calls_snapshot, call_objects.items);
    try store.verifySnapshot(validation_snapshot, validation_objects.items);

    const manifest = try publishedManifestForSourceSpec(
        allocator,
        spec,
        objects.items,
        object_rows.items,
        calls_snapshot,
        validation_snapshot,
    );
    errdefer allocator.free(manifest);
    const manifest_key = try store.publishManifest(1, manifest);
    defer allocator.free(manifest_key);
    try store.verifyNoPartialObjects();
    try guard.assertCurrent();
    return manifest;
}

fn prepareStoreRoot(
    allocator: std.mem.Allocator,
    io: std.Io,
    guard: *const RegistrationGuard,
    root_path: []const u8,
) !void {
    try guard.assertStoreRoot(root_path);
    const exists = try validateAuthorityAncestry(allocator, io, root_path);
    try guard.assertCurrent();
    if (!exists) try createAbsoluteDirectorySynced(io, root_path);
    try guard.assertCurrent();
    if (!try validateAuthorityAncestry(allocator, io, root_path)) {
        return error.AuthorityRootMissingAfterPreparation;
    }
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

fn publishedManifestForSourceSpec(
    allocator: std.mem.Allocator,
    spec: SourceSpec,
    objects: []const FileIdentity,
    object_rows: []const usize,
    calls_snapshot: SnapshotIdentity,
    validation_snapshot: SnapshotIdentity,
) ![]u8 {
    var output: std.ArrayList(u8) = .empty;
    errdefer output.deinit(allocator);
    try appendManifestPreamble(allocator, &output);
    for (objects, object_rows) |object, row_index| {
        const row = spec.rows[row_index];
        const object_id = try std.fmt.allocPrint(allocator, "object/sha256/{s}", .{&object.sha256});
        defer allocator.free(object_id);
        try appendManifestRowText(allocator, &output, .{
            .kind = .object,
            .logical_id = object_id,
            .sha256 = &object.sha256,
            .bytes = object.bytes,
            .mode = object.mode,
            .media_type = row.media_type,
            .provenance = "inbox194-source-spec",
            .reconstruction = "exact-source-publication",
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
    try appendPublishedConstituentObject(allocator, &output, calls_snapshot.constituent);
    try appendPublishedConstituentObject(allocator, &output, validation_snapshot.constituent);
    for (spec.rows) |row| {
        const object_id = try std.fmt.allocPrint(allocator, "object/sha256/{s}", .{row.sha256});
        defer allocator.free(object_id);
        const planned_key = try std.fmt.allocPrint(allocator, "planned/{s}", .{row.logical_id});
        defer allocator.free(planned_key);
        try appendManifestRowText(allocator, &output, .{
            .kind = .logical_ref,
            .logical_id = row.logical_id,
            .sha256 = row.sha256,
            .bytes = row.bytes,
            .mode = row.source_mode,
            .media_type = row.media_type,
            .provenance = "inbox194-source-spec",
            .reconstruction = "materialize-spec-publish",
            .retention_class = .canonical_input,
            .status = .active,
            .key = planned_key,
            .target_id = object_id,
            .snapshot_id = "-",
            .member_path = "-",
            .snapshot_format = "-",
            .recipe_sha256 = "-",
            .constituent_sha256 = "-",
        });
    }
    try appendPublishedSnapshot(
        allocator,
        &output,
        snapshot_calls_inputs,
        calls_snapshot,
        objects,
        object_rows,
        spec,
        group_calls_inputs,
    );
    try appendPublishedSnapshot(
        allocator,
        &output,
        snapshot_calls_validation_inputs,
        validation_snapshot,
        objects,
        object_rows,
        spec,
        group_calls_validation_inputs,
    );
    const canonical = try output.toOwnedSlice(allocator);
    errdefer allocator.free(canonical);
    var parsed = try parseManifest(allocator, canonical);
    defer parsed.deinit(allocator);
    const encoded = try encodeManifest(allocator, parsed);
    defer allocator.free(encoded);
    if (!std.mem.eql(u8, encoded, canonical)) return error.NonCanonicalManifest;
    return canonical;
}

fn appendPublishedConstituentObject(
    allocator: std.mem.Allocator,
    output: *std.ArrayList(u8),
    object: FileIdentity,
) !void {
    const object_id = try std.fmt.allocPrint(allocator, "object/sha256/{s}", .{&object.sha256});
    defer allocator.free(object_id);
    try appendManifestRowText(allocator, output, .{
        .kind = .object,
        .logical_id = object_id,
        .sha256 = &object.sha256,
        .bytes = object.bytes,
        .mode = object.mode,
        .media_type = "text/tab-separated-values",
        .provenance = "inbox194-snapshot-constituents",
        .reconstruction = snapshot_recipe,
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

fn appendPublishedSnapshot(
    allocator: std.mem.Allocator,
    output: *std.ArrayList(u8),
    snapshot_id: []const u8,
    snapshot: SnapshotIdentity,
    objects: []const FileIdentity,
    object_rows: []const usize,
    spec: SourceSpec,
    group_id: []const u8,
) !void {
    try appendManifestRowText(allocator, output, .{
        .kind = .snapshot,
        .logical_id = snapshot_id,
        .sha256 = &snapshot.archive.sha256,
        .bytes = snapshot.archive.bytes,
        .mode = snapshot.archive.mode,
        .media_type = "application/zstd",
        .provenance = "inbox194-source-spec",
        .reconstruction = snapshot_recipe,
        .retention_class = .canonical_input,
        .status = .active,
        .key = snapshot.archive.key,
        .target_id = "-",
        .snapshot_id = "-",
        .member_path = "-",
        .snapshot_format = snapshot_format,
        .recipe_sha256 = snapshot_recipe_sha,
        .constituent_sha256 = &snapshot.constituent.sha256,
    });
    var members: std.ArrayList(FileIdentity) = .empty;
    defer members.deinit(allocator);
    for (objects, object_rows) |object, row_index| {
        if (std.mem.eql(u8, spec.rows[row_index].group_id, group_id)) {
            try members.append(allocator, object);
        }
    }
    const sorted = try sortedObjectGroup(allocator, members.items);
    defer allocator.free(sorted);
    for (sorted) |object| {
        const object_id = try std.fmt.allocPrint(allocator, "object/sha256/{s}", .{&object.sha256});
        defer allocator.free(object_id);
        const member_id = try std.fmt.allocPrint(
            allocator,
            "{s}/member/{s}",
            .{ snapshot_id, &object.sha256 },
        );
        defer allocator.free(member_id);
        try appendManifestRowText(allocator, output, .{
            .kind = .snapshot_member,
            .logical_id = member_id,
            .sha256 = &object.sha256,
            .bytes = object.bytes,
            .mode = object.mode,
            .media_type = "application/octet-stream",
            .provenance = "inbox194-source-spec",
            .reconstruction = snapshot_recipe,
            .retention_class = .canonical_input,
            .status = .active,
            .key = object.key,
            .target_id = object_id,
            .snapshot_id = snapshot_id,
            .member_path = object.key,
            .snapshot_format = "-",
            .recipe_sha256 = "-",
            .constituent_sha256 = "-",
        });
    }
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

fn manifestForSynthetic(
    allocator: std.mem.Allocator,
    objects: []const FileIdentity,
    snapshot: SnapshotIdentity,
) ![]u8 {
    const sorted = try sortedObjectGroup(allocator, objects);
    defer allocator.free(sorted);
    var output: std.ArrayList(u8) = .empty;
    errdefer output.deinit(allocator);
    try output.appendSlice(allocator, schema_magic ++ "\n" ++ schema_header ++ "\n");
    for (sorted, 0..) |object, index| {
        try output.print(
            allocator,
            "object\tcalls.input.synthetic.{d}.v1\t{s}\t{}\t444\tapplication/octet-stream\tsynthetic\tunavailable\tcanonical-input\tactive\t{s}\t-\t-\t-\t-\t-\t-\n",
            .{ index, object.sha256, object.bytes, object.key },
        );
    }
    try output.print(
        allocator,
        "object\tcalls.constituent.synthetic.v1\t{s}\t{}\t444\ttext/tab-separated-values\tsynthetic\tunavailable\treproducible-cache\tactive\t{s}\t-\t-\t-\t-\t-\t-\n",
        .{ snapshot.constituent.sha256, snapshot.constituent.bytes, snapshot.constituent.key },
    );
    try output.print(
        allocator,
        "logical-ref\tcalls.ref.synthetic.v1\t{s}\t{}\t444\tapplication/octet-stream\tsynthetic\tunavailable\tcanonical-input\tactive\tresult.bin\tcalls.input.synthetic.0.v1\t-\t-\t-\t-\t-\n",
        .{ sorted[0].sha256, sorted[0].bytes },
    );
    try output.print(
        allocator,
        "snapshot\tcalls.snapshot.synthetic.v1\t{s}\t{}\t444\tapplication/zstd+tar\tsynthetic\tunavailable\tirreplaceable-acceptance-evidence\tactive\t{s}\t-\t-\t-\t{s}\t{s}\t{s}\n",
        .{
            snapshot.archive.sha256,
            snapshot.archive.bytes,
            snapshot.archive.key,
            snapshot_format,
            snapshot_recipe_sha,
            snapshot.constituent.sha256,
        },
    );
    for (sorted, 0..) |object, index| {
        try output.print(
            allocator,
            "snapshot-member\tcalls.snapshot.member.synthetic.{d}.v1\t{s}\t{}\t444\tapplication/octet-stream\tsynthetic\tunavailable\tcanonical-input\tactive\t{s}\tcalls.input.synthetic.{d}.v1\tcalls.snapshot.synthetic.v1\t{s}\t-\t-\t-\n",
            .{ index, object.sha256, object.bytes, object.key, index, object.key },
        );
    }
    return output.toOwnedSlice(allocator);
}

fn assertRetainedMaterializeBoundaries(io: std.Io) !void {
    if (!builtin.is_test) return error.TestOnlyOperation;
    if (std.Io.Dir.cwd().statFile(io, prior_failed_materialize_store, .{
        .follow_symlinks = false,
    })) |_| {
        return error.PriorMaterializeStoreMustRemainAbsent;
    } else |err| switch (err) {
        error.FileNotFound => {},
        else => return err,
    }
    const real_store_stat = try std.Io.Dir.cwd().statFile(io, default_store, .{
        .follow_symlinks = false,
    });
    if (real_store_stat.kind != .directory or
        @as(u16, @intCast(real_store_stat.permissions.toMode() & 0o7777)) != 0o775)
    {
        return error.RealStoreRootChanged;
    }

    const root_stat = try std.Io.Dir.cwd().statFile(
        io,
        prior_failed_materialize_continuation_store,
        .{ .follow_symlinks = false },
    );
    if (root_stat.kind != .directory or
        @as(u16, @intCast(root_stat.permissions.toMode() & 0o7777)) != 0o775)
    {
        return error.PriorMaterializeContinuationStoreChanged;
    }
    const retained_link =
        prior_failed_materialize_continuation_store ++ "/authority-symlink";
    const link_stat = try std.Io.Dir.cwd().statFile(io, retained_link, .{
        .follow_symlinks = false,
    });
    if (link_stat.kind != .sym_link) return error.PriorMaterializeSymlinkChanged;
    var target_buffer: [16]u8 = undefined;
    const target_len = try std.Io.Dir.readLinkAbsolute(io, retained_link, &target_buffer);
    if (!std.mem.eql(u8, target_buffer[0..target_len], ".")) {
        return error.PriorMaterializeSymlinkChanged;
    }

    var retained_root = try std.Io.Dir.openDirAbsolute(
        io,
        prior_failed_materialize_second_continuation_store,
        .{ .iterate = true, .follow_symlinks = false },
    );
    defer retained_root.close(io);
    const retained_root_stat = try retained_root.stat(io);
    if (@as(u16, @intCast(retained_root_stat.permissions.toMode() & 0o7777)) != 0o775) {
        return error.PriorSecondMaterializeContinuationStoreChanged;
    }
    var root_entries = retained_root.iterate();
    const objects_entry = (try root_entries.next(io)) orelse
        return error.PriorSecondMaterializeContinuationStoreChanged;
    if (!std.mem.eql(u8, objects_entry.name, "objects") or objects_entry.kind != .directory or
        try root_entries.next(io) != null)
    {
        return error.PriorSecondMaterializeContinuationStoreChanged;
    }
    var objects = try retained_root.openDir(io, "objects", .{
        .iterate = true,
        .follow_symlinks = false,
    });
    defer objects.close(io);
    var objects_entries = objects.iterate();
    const sha_entry = (try objects_entries.next(io)) orelse
        return error.PriorSecondMaterializeContinuationStoreChanged;
    if (!std.mem.eql(u8, sha_entry.name, "sha256") or sha_entry.kind != .directory or
        try objects_entries.next(io) != null)
    {
        return error.PriorSecondMaterializeContinuationStoreChanged;
    }
    var sha_dir = try objects.openDir(io, "sha256", .{
        .iterate = true,
        .follow_symlinks = false,
    });
    defer sha_dir.close(io);
    var sha_entries = sha_dir.iterate();
    const prefix_entry = (try sha_entries.next(io)) orelse
        return error.PriorSecondMaterializeContinuationStoreChanged;
    if (!std.mem.eql(u8, prefix_entry.name, "d8") or prefix_entry.kind != .directory or
        try sha_entries.next(io) != null)
    {
        return error.PriorSecondMaterializeContinuationStoreChanged;
    }
    var prefix_dir = try sha_dir.openDir(io, "d8", .{
        .iterate = true,
        .follow_symlinks = false,
    });
    defer prefix_dir.close(io);
    var prefix_entries = prefix_dir.iterate();
    const object_entry = (try prefix_entries.next(io)) orelse
        return error.PriorSecondMaterializeContinuationStoreChanged;
    if (!std.mem.eql(u8, object_entry.name, retained_materialize_object_sha[2..]) or
        object_entry.kind != .file or try prefix_entries.next(io) != null)
    {
        return error.PriorSecondMaterializeContinuationStoreChanged;
    }
    var retained_object = try prefix_dir.openFile(io, retained_materialize_object_sha[2..], .{
        .allow_directory = false,
        .follow_symlinks = false,
    });
    defer retained_object.close(io);
    var retained_identity = try identityOfOpenFileAnyMode(
        std.testing.allocator,
        io,
        retained_object,
    );
    defer retained_identity.deinit(std.testing.allocator);
    if (!std.mem.eql(u8, &retained_identity.sha256, retained_materialize_object_sha) or
        retained_identity.bytes != retained_materialize_object_bytes or
        retained_identity.mode != 0o444)
    {
        return error.PriorSecondMaterializeContinuationStoreChanged;
    }
}

fn generatorTestSourceSpecRow(group_id: []const u8) SourceSpecRow {
    if (!builtin.is_test) @panic("test-only helper");
    return .{
        .logical_id = "test/source",
        .source_set_id = "test/source-set",
        .source_path = "test/source",
        .sha256 = "0000000000000000000000000000000000000000000000000000000000000000",
        .bytes = 1,
        .source_mode = 0o444,
        .media_type = "application/octet-stream",
        .retention_class = .canonical_input,
        .object_key = "objects/sha256/00/00000000000000000000000000000000000000000000000000000000000000",
        .member_path = "objects/sha256/00/00000000000000000000000000000000000000000000000000000000000000",
        .group_id = group_id,
        .snapshot_id = "snapshot/test/v1",
        .snapshot_format = snapshot_format,
        .recipe_sha256 = snapshot_recipe_sha,
        .constituent_sha256 = "2222222222222222222222222222222222222222222222222222222222222222",
        .group_manifest_sha256 = "3333333333333333333333333333333333333333333333333333333333333333",
    };
}

const GeneratedMemberMutation = enum {
    dash_keys,
    other_object_key,
    hash,
    bytes,
    mode,
};

fn mutateGeneratedMembers(
    allocator: std.mem.Allocator,
    canonical: []const u8,
    mutation: GeneratedMemberMutation,
) ![]u8 {
    if (!builtin.is_test) return error.TestOnlyOperation;
    var manifest = try parseManifest(allocator, canonical);
    defer manifest.deinit(allocator);
    var member_indices: [2]usize = undefined;
    var member_count: usize = 0;
    for (manifest.rows, 0..) |row, index| {
        if (row.kind != .snapshot_member) continue;
        if (member_count == member_indices.len) return error.UnexpectedGeneratedMemberCount;
        member_indices[member_count] = index;
        member_count += 1;
    }
    if (member_count != member_indices.len) return error.UnexpectedGeneratedMemberCount;
    const first_index = member_indices[0];
    const second_index = member_indices[1];
    const second_target = findRow(
        manifest,
        manifest.rows[second_index].target_id,
    ) orelse return error.MissingTargetObject;
    switch (mutation) {
        .dash_keys => {
            manifest.rows[first_index].key = "-";
            manifest.rows[second_index].key = "-";
        },
        .other_object_key => manifest.rows[first_index].key = second_target.key,
        .hash => manifest.rows[first_index].sha256 = second_target.sha256,
        .bytes => manifest.rows[first_index].bytes += 1,
        .mode => manifest.rows[first_index].mode = 0o400,
    }
    return encodeManifest(allocator, manifest);
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
    try assertRetainedMaterializeBoundaries(io);

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
    try assertRetainedMaterializeBoundaries(io);
    var original_after = try std.Io.Dir.openDirAbsolute(io, original_failed_store, .{
        .iterate = true,
        .follow_symlinks = false,
    });
    defer original_after.close(io);
    var original_entries_after = original_after.iterate();
    if (try original_entries_after.next(io) != null) return error.OriginalFailedStoreChanged;
}
