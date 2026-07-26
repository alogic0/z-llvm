const std = @import("std");
const builtin = @import("builtin");
const capacity = @import("zllvm_artifact_store/capacity.zig");
const digest_model = @import("zllvm_artifact_store/digest.zig");
const identity_model = @import("zllvm_artifact_store/identity.zig");
const manifest_model = @import("zllvm_artifact_store/manifest.zig");
const path_policy = @import("zllvm_artifact_store/path_policy.zig");
const process_result = @import("zllvm_artifact_store/process_result.zig");
const registration = @import("zllvm_artifact_store/registration.zig");

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
const snapshot_recipe =
    "tar-1.35:--format=ustar,--sort=name,--mtime=@0,--owner=0,--group=0,--numeric-owner,--mode=0444,--no-acls,--no-xattrs,--no-selinux,--no-recursion,--null,--files-from;zstd-1.5.5:-T1,-19,--check,--no-progress,-c";
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

const SnapshotProofWorkspace = struct {
    io: std.Io,
    parent: std.Io.Dir,
    workspace: std.Io.Dir,
    name: [32]u8,
    parent_open: bool = true,
    workspace_open: bool = true,
    workspace_exists: bool = true,

    fn init(io: std.Io, store_root: std.Io.Dir) !SnapshotProofWorkspace {
        var parent = try openOrCreateDir(io, store_root, "snapshot-proof");
        errdefer parent.close(io);
        var random: [16]u8 = undefined;
        io.random(&random);
        const name = std.fmt.bytesToHex(random, .lower);
        const workspace = try openOrCreateDir(io, parent, &name);
        return .{
            .io = io,
            .parent = parent,
            .workspace = workspace,
            .name = name,
        };
    }

    fn dir(proof: *const SnapshotProofWorkspace) std.Io.Dir {
        std.debug.assert(proof.workspace_open);
        return proof.workspace;
    }

    fn relativePath(
        proof: *const SnapshotProofWorkspace,
        allocator: std.mem.Allocator,
    ) ![]u8 {
        std.debug.assert(proof.workspace_open);
        return std.fs.path.join(allocator, &.{ "snapshot-proof", &proof.name });
    }

    fn finish(proof: *SnapshotProofWorkspace) !void {
        proof.closeWorkspace();
        try proof.parent.deleteTree(proof.io, &proof.name);
        proof.workspace_exists = false;
        try syncDirectory(proof.parent);
        proof.closeParent();
    }

    fn deinitAfterError(proof: *SnapshotProofWorkspace) void {
        proof.closeWorkspace();
        if (proof.workspace_exists) {
            proof.parent.deleteTree(proof.io, &proof.name) catch {};
            proof.workspace_exists = false;
            syncDirectory(proof.parent) catch {};
        }
        proof.closeParent();
    }

    fn closeWorkspace(proof: *SnapshotProofWorkspace) void {
        if (!proof.workspace_open) return;
        proof.workspace.close(proof.io);
        proof.workspace_open = false;
    }

    fn closeParent(proof: *SnapshotProofWorkspace) void {
        if (!proof.parent_open) return;
        proof.parent.close(proof.io);
        proof.parent_open = false;
    }
};

pub const Store = struct {
    allocator: std.mem.Allocator,
    io: std.Io,
    root_path: []u8,
    root: std.Io.Dir,
    guard: *const RegistrationGuard,

    pub fn open(
        allocator: std.mem.Allocator,
        io: std.Io,
        guard: *const RegistrationGuard,
        root_path: []const u8,
    ) !Store {
        try guard.assertCurrent();
        try guard.assertStoreRoot(root_path);
        const root = try std.Io.Dir.openDirAbsolute(io, root_path, .{
            .access_sub_paths = true,
            .iterate = true,
            .follow_symlinks = false,
        });
        errdefer root.close(io);
        const owned = try allocator.dupe(u8, root_path);
        return .{
            .allocator = allocator,
            .io = io,
            .root_path = owned,
            .root = root,
            .guard = guard,
        };
    }

    pub fn deinit(store: *Store) void {
        store.root.close(store.io);
        store.allocator.free(store.root_path);
        store.* = undefined;
    }

    pub fn preflightCapacity(
        store: *Store,
        requirement: CapacityRequirement,
    ) !CapacityObservation {
        try store.guard.assertCurrent();
        const observed = try freshCapacity(store.root);
        try requirement.validate(observed);
        try store.guard.assertCurrent();
        return observed;
    }

    pub fn publishBytes(store: *Store, bytes: []const u8) !FileIdentity {
        return store.publishBytesWithFault(bytes, .none);
    }

    fn publishBytesWithFault(
        store: *Store,
        bytes: []const u8,
        fault: PublishFault,
    ) !FileIdentity {
        try store.guard.assertCurrent();
        const digest = sha256Hex(bytes);
        const key = try objectKey(store.allocator, &digest);
        errdefer store.allocator.free(key);
        var leaf = try store.openObjectLeaf(digest[0..2]);
        defer leaf.close(store.io);
        const expected: FileIdentity = .{
            .sha256 = digest,
            .bytes = bytes.len,
            .mode = 0o444,
            .key = @constCast("-"),
        };
        _ = try publishVerifiedBytes(
            store.allocator,
            store.io,
            leaf,
            digest[2..],
            bytes,
            expected,
            fault,
        );
        try store.guard.assertCurrent();
        return .{
            .sha256 = digest,
            .bytes = bytes.len,
            .mode = 0o444,
            .key = key,
        };
    }

    pub fn publishFile(
        store: *Store,
        bounded_source_root: []const u8,
        source_path: []const u8,
    ) !FileIdentity {
        try store.guard.assertCurrent();
        if (pathContains(store.root_path, source_path) or pathContains(source_path, store.root_path)) {
            return error.SourceStoreAliasing;
        }
        try store.guard.assertReadSource(bounded_source_root, source_path);
        var source = try std.Io.Dir.openFileAbsolute(store.io, source_path, .{
            .allow_directory = false,
            .follow_symlinks = false,
        });
        defer source.close(store.io);
        const source_identity = try identityOfOpenFileAnyMode(store.allocator, store.io, source);
        defer {
            var mutable = source_identity;
            mutable.deinit(store.allocator);
        }
        const expected: FileIdentity = .{
            .sha256 = source_identity.sha256,
            .bytes = source_identity.bytes,
            .mode = 0o444,
            .key = @constCast("-"),
        };
        try store.guard.assertCurrent();
        return store.publishOpenFile(source, expected, .none);
    }

    fn publishOpenFile(
        store: *Store,
        source: std.Io.File,
        expected: FileIdentity,
        fault: PublishFault,
    ) !FileIdentity {
        const key = try objectKey(store.allocator, &expected.sha256);
        errdefer store.allocator.free(key);
        var leaf = try store.openObjectLeaf(expected.sha256[0..2]);
        defer leaf.close(store.io);
        _ = try publishVerifiedFile(
            store.allocator,
            store.io,
            leaf,
            expected.sha256[2..],
            source,
            expected,
            fault,
        );
        try store.guard.assertCurrent();
        return .{
            .sha256 = expected.sha256,
            .bytes = expected.bytes,
            .mode = expected.mode,
            .key = key,
        };
    }

    pub fn verifyObject(store: *Store, identity: FileIdentity) !void {
        try store.guard.assertCurrent();
        try validateRelativeKey(identity.key);
        const split = splitObjectKey(identity.key) orelse return error.InvalidObjectKey;
        if (!std.mem.eql(u8, split.prefix, identity.sha256[0..2]) or
            !std.mem.eql(u8, split.basename, identity.sha256[2..]))
        {
            return error.ObjectKeyShaMismatch;
        }
        var leaf = try store.openObjectLeafExisting(split.prefix);
        defer leaf.close(store.io);
        var actual = try verifyRelativeFile(store.allocator, store.io, leaf, split.basename, identity.mode);
        defer actual.deinit(store.allocator);
        if (!std.mem.eql(u8, &actual.sha256, &identity.sha256) or actual.bytes != identity.bytes) {
            return error.ObjectVerificationFailed;
        }
        try store.guard.assertCurrent();
    }

    pub fn publishManifest(store: *Store, generation: u64, canonical: []const u8) ![]u8 {
        try store.guard.assertCurrent();
        var manifest = try parseManifest(store.allocator, canonical);
        defer manifest.deinit(store.allocator);
        const encoded = try encodeManifest(store.allocator, manifest);
        defer store.allocator.free(encoded);
        if (!std.mem.eql(u8, encoded, canonical)) return error.NonCanonicalManifest;

        var manifests = try openOrCreateDir(store.io, store.root, "manifests");
        defer manifests.close(store.io);
        const name = try std.fmt.allocPrint(store.allocator, "generation-{d:0>8}.tsv", .{generation});
        defer store.allocator.free(name);
        const expected: FileIdentity = .{
            .sha256 = sha256Hex(canonical),
            .bytes = canonical.len,
            .mode = 0o444,
            .key = @constCast("-"),
        };
        _ = try publishVerifiedBytes(
            store.allocator,
            store.io,
            manifests,
            name,
            canonical,
            expected,
            .none,
        );
        try store.guard.assertCurrent();
        return std.fs.path.join(store.allocator, &.{ "manifests", name });
    }

    pub fn publishSnapshot(store: *Store, objects: []const FileIdentity) !SnapshotIdentity {
        const sorted = try sortedObjectGroup(store.allocator, objects);
        defer store.allocator.free(sorted);
        for (sorted) |object| try store.verifyObject(object);
        try verifyToolchain(store.allocator, store.io);

        const constituent_text = try encodeConstituentManifest(store.allocator, sorted);
        defer store.allocator.free(constituent_text);
        var constituent = try store.publishBytes(constituent_text);
        errdefer constituent.deinit(store.allocator);

        var work = try openOrCreateDir(store.io, store.root, "snapshot-work");
        defer work.close(store.io);
        var random: [16]u8 = undefined;
        store.io.random(&random);
        const token = std.fmt.bytesToHex(random, .lower);
        const members_name = try std.fmt.allocPrint(store.allocator, "{s}.members.nul", .{&token});
        defer store.allocator.free(members_name);
        const incoming_name = try std.fmt.allocPrint(store.allocator, "{s}.incoming.tar.zst", .{&token});
        defer store.allocator.free(incoming_name);
        const member_data = try encodeMemberList(store.allocator, sorted);
        defer store.allocator.free(member_data);
        try writeExclusive(store.io, work, members_name, member_data, 0o444);
        defer {
            work.deleteFile(store.io, members_name) catch {};
            syncDirectory(work) catch {};
        }

        var incoming = try work.createFile(store.io, incoming_name, .{
            .read = true,
            .exclusive = true,
            .permissions = .fromMode(0o600),
        });
        try syncDirectory(work);
        const incoming_open = true;
        const incoming_exists = true;
        defer {
            if (incoming_open) incoming.close(store.io);
            if (incoming_exists) {
                work.deleteFile(store.io, incoming_name) catch {};
                syncDirectory(work) catch {};
            }
        }

        const command =
            \\set -u -o pipefail
            \\set +e
            \\/usr/bin/tar --format=ustar --sort=name --mtime=@0 --owner=0 --group=0 --numeric-owner --mode=0444 --no-acls --no-xattrs --no-selinux --no-recursion --null --files-from="$1" -cf - |
            \\  /usr/bin/zstd -T1 -19 --check --no-progress -c
            \\pipeline=("${PIPESTATUS[@]}")
            \\set -e
            \\test "${#pipeline[@]}" -eq 2
            \\test "${pipeline[0]}" -eq 0
            \\test "${pipeline[1]}" -eq 0
        ;
        const members_rel = try std.fs.path.join(store.allocator, &.{ "snapshot-work", members_name });
        defer store.allocator.free(members_rel);
        var environment = cleanToolEnvironment(store.allocator);
        defer environment.deinit();
        var child = try std.process.spawn(store.io, .{
            .argv = &.{ "/bin/bash", "-c", command, "_", members_rel },
            .cwd = .{ .dir = store.root },
            .environ_map = &environment,
            .stdin = .ignore,
            .stdout = .{ .file = incoming },
            .stderr = .inherit,
        });
        const term = try child.wait(store.io);
        if (!termSuccess(term)) return error.SnapshotProducerFailed;
        try incoming.sync(store.io);
        try incoming.setPermissions(store.io, .fromMode(0o444));
        try incoming.sync(store.io);
        var archive_identity = try identityOfOpenFile(store.allocator, store.io, incoming, 0o444);
        errdefer archive_identity.deinit(store.allocator);
        const archive_key = try snapshotKey(store.allocator, &archive_identity.sha256);
        store.allocator.free(archive_identity.key);
        archive_identity.key = archive_key;

        const split = splitSnapshotKey(archive_identity.key) orelse return error.InvalidSnapshotKey;
        var snapshots = try openOrCreateDir(store.io, store.root, "snapshots");
        defer snapshots.close(store.io);
        var sha_dir = try openOrCreateDir(store.io, snapshots, "sha256");
        defer sha_dir.close(store.io);
        var leaf = try openOrCreateDir(store.io, sha_dir, split.prefix);
        defer leaf.close(store.io);
        _ = try publishVerifiedFile(
            store.allocator,
            store.io,
            leaf,
            split.basename,
            incoming,
            archive_identity,
            .none,
        );
        try store.verifySnapshotArchive(archive_identity, sorted);
        try store.guard.assertCurrent();

        const owned_keys = try store.allocator.alloc([]u8, sorted.len);
        var owned_count: usize = 0;
        errdefer {
            for (owned_keys[0..owned_count]) |key| store.allocator.free(key);
            store.allocator.free(owned_keys);
        }
        for (sorted, 0..) |object, index| {
            owned_keys[index] = try store.allocator.dupe(u8, object.key);
            owned_count += 1;
        }
        return .{
            .archive = archive_identity,
            .constituent = constituent,
            .member_keys = owned_keys,
        };
    }

    pub fn verifySnapshot(
        store: *Store,
        snapshot: SnapshotIdentity,
        objects: []const FileIdentity,
    ) !void {
        const sorted = try sortedObjectGroup(store.allocator, objects);
        defer store.allocator.free(sorted);
        for (sorted) |object| try store.verifyObject(object);
        try store.verifyObject(snapshot.constituent);
        if (snapshot.member_keys.len != sorted.len) return error.ConstituentMismatch;
        for (sorted, snapshot.member_keys) |object, member_key| {
            if (!std.mem.eql(u8, member_key, object.key)) return error.ConstituentMismatch;
        }
        const constituent_text = try encodeConstituentManifest(store.allocator, sorted);
        defer store.allocator.free(constituent_text);
        if (!std.mem.eql(u8, &sha256Hex(constituent_text), &snapshot.constituent.sha256) or
            constituent_text.len != snapshot.constituent.bytes)
        {
            return error.ConstituentMismatch;
        }
        try store.verifySnapshotArchive(snapshot.archive, sorted);
    }

    pub fn resolveCompatibility(
        store: *Store,
        canonical_manifest: []const u8,
        logical_ref_id: []const u8,
        snapshot: SnapshotIdentity,
        objects: []const FileIdentity,
        compatibility_root: []const u8,
        relative_path: []const u8,
    ) !void {
        try store.guard.assertCurrent();
        try store.guard.assertSyntheticWrite(store.root_path, compatibility_root);
        try validateRelativeKey(relative_path);
        if (std.mem.startsWith(u8, relative_path, "objects/") or
            std.mem.startsWith(u8, relative_path, "snapshots/") or
            std.mem.startsWith(u8, relative_path, "manifests/"))
        {
            return error.ReservedCompatibilityPath;
        }
        var manifest = try parseManifest(store.allocator, canonical_manifest);
        defer manifest.deinit(store.allocator);
        const reencoded_manifest = try encodeManifest(store.allocator, manifest);
        defer store.allocator.free(reencoded_manifest);
        if (!std.mem.eql(u8, reencoded_manifest, canonical_manifest)) {
            return error.NonCanonicalManifest;
        }
        const logical_ref = findRow(manifest, logical_ref_id) orelse return error.MissingLogicalReference;
        if (logical_ref.kind != .logical_ref or !std.mem.eql(u8, logical_ref.key, relative_path)) {
            return error.LogicalReferenceMismatch;
        }
        const target_row = findRow(manifest, logical_ref.target_id) orelse
            return error.MissingTargetObject;
        var object: ?FileIdentity = null;
        for (objects) |candidate| {
            if (std.mem.eql(u8, candidate.key, target_row.key) and
                std.mem.eql(u8, &candidate.sha256, target_row.sha256) and
                candidate.bytes == target_row.bytes and
                candidate.mode == target_row.mode)
            {
                object = candidate;
            }
        }
        const selected = object orelse return error.ManifestPrimaryGroupMismatch;
        var snapshot_row: ?Row = null;
        for (manifest.rows) |candidate| {
            if (candidate.kind == .snapshot and
                std.mem.eql(u8, candidate.sha256, &snapshot.archive.sha256))
            {
                snapshot_row = candidate;
            }
        }
        const declared_snapshot = snapshot_row orelse return error.ManifestSnapshotGroupMismatch;
        if (!std.mem.eql(u8, declared_snapshot.constituent_sha256, &snapshot.constituent.sha256)) {
            return error.ManifestSnapshotGroupMismatch;
        }
        var all_declared_member_count: usize = 0;
        for (manifest.rows) |candidate| {
            if (candidate.kind == .snapshot_member and
                std.mem.eql(u8, candidate.snapshot_id, declared_snapshot.logical_id))
            {
                all_declared_member_count += 1;
            }
        }
        if (all_declared_member_count != objects.len) return error.ManifestSnapshotGroupMismatch;
        var declared_member_count: usize = 0;
        for (objects) |group_object| {
            var group_row: ?Row = null;
            for (manifest.rows) |candidate| {
                if (candidate.kind == .object and
                    std.mem.eql(u8, candidate.key, group_object.key) and
                    std.mem.eql(u8, candidate.sha256, &group_object.sha256) and
                    candidate.bytes == group_object.bytes and
                    candidate.mode == group_object.mode)
                {
                    group_row = candidate;
                }
            }
            const declared_object = group_row orelse return error.ManifestPrimaryGroupMismatch;
            var member_found = false;
            for (manifest.rows) |candidate| {
                if (candidate.kind == .snapshot_member and
                    std.mem.eql(u8, candidate.snapshot_id, declared_snapshot.logical_id) and
                    std.mem.eql(u8, candidate.target_id, declared_object.logical_id) and
                    std.mem.eql(u8, candidate.member_path, group_object.key))
                {
                    member_found = true;
                    declared_member_count += 1;
                }
            }
            if (!member_found) return error.ManifestSnapshotGroupMismatch;
        }
        if (declared_member_count != objects.len) return error.ManifestSnapshotGroupMismatch;
        try store.verifySnapshot(snapshot, objects);

        var compat = try std.Io.Dir.openDirAbsolute(store.io, compatibility_root, .{
            .access_sub_paths = true,
            .iterate = true,
            .follow_symlinks = false,
        });
        defer compat.close(store.io);
        const parent_path = std.fs.path.dirname(relative_path) orelse ".";
        const basename = std.fs.path.basename(relative_path);
        var parent = try openPathNoFollow(store.io, compat, parent_path, true);
        defer parent.close(store.io);

        if (parent.openFile(store.io, basename, .{
            .allow_directory = false,
            .follow_symlinks = false,
        })) |existing| {
            defer existing.close(store.io);
            var actual = try identityOfOpenFile(store.allocator, store.io, existing, selected.mode);
            defer actual.deinit(store.allocator);
            if (!sameFileIdentity(actual, selected)) {
                return error.StaleCompatibilityDestination;
            }
            try store.guard.assertCurrent();
            return;
        } else |err| switch (err) {
            error.FileNotFound => {},
            error.SymLinkLoop => return error.UnsafeCompatibilityDestination,
            else => return err,
        }

        const object_split = splitObjectKey(selected.key) orelse return error.InvalidObjectKey;
        var object_leaf = try store.openObjectLeafExisting(object_split.prefix);
        defer object_leaf.close(store.io);
        var source = try object_leaf.openFile(store.io, object_split.basename, .{
            .allow_directory = false,
            .follow_symlinks = false,
        });
        defer source.close(store.io);

        _ = publishVerifiedFile(
            store.allocator,
            store.io,
            parent,
            basename,
            source,
            selected,
            .none,
        ) catch |err| switch (err) {
            error.UnequalExistingCollision => return error.StaleCompatibilityDestination,
            else => return err,
        };
        try store.guard.assertCurrent();
    }

    pub fn verifyNoPartialObjects(store: *Store) !void {
        var objects = try openExistingDir(store.io, store.root, "objects");
        defer objects.close(store.io);
        var sha_dir = try openExistingDir(store.io, objects, "sha256");
        defer sha_dir.close(store.io);
        var prefixes = sha_dir.iterate();
        while (try prefixes.next(store.io)) |prefix| {
            if (prefix.kind != .directory or prefix.name.len != 2 or !isLowerHex(prefix.name)) {
                return error.UnexpectedObjectEntry;
            }
            var leaf = try sha_dir.openDir(store.io, prefix.name, .{
                .iterate = true,
                .follow_symlinks = false,
            });
            defer leaf.close(store.io);
            var entries = leaf.iterate();
            while (try entries.next(store.io)) |entry| {
                if (entry.kind != .file or entry.name.len != 62 or !isLowerHex(entry.name)) {
                    return error.PartialOrUnexpectedObject;
                }
            }
        }
    }

    fn openObjectLeaf(store: *Store, prefix: []const u8) !std.Io.Dir {
        var objects = try openOrCreateDir(store.io, store.root, "objects");
        defer objects.close(store.io);
        var sha_dir = try openOrCreateDir(store.io, objects, "sha256");
        defer sha_dir.close(store.io);
        return openOrCreateDir(store.io, sha_dir, prefix);
    }

    fn openObjectLeafExisting(store: *Store, prefix: []const u8) !std.Io.Dir {
        var objects = try openExistingDir(store.io, store.root, "objects");
        defer objects.close(store.io);
        var sha_dir = try openExistingDir(store.io, objects, "sha256");
        defer sha_dir.close(store.io);
        return openExistingDir(store.io, sha_dir, prefix);
    }

    fn verifySnapshotArchive(
        store: *Store,
        archive: FileIdentity,
        objects: []const FileIdentity,
    ) !void {
        const split = splitSnapshotKey(archive.key) orelse return error.InvalidSnapshotKey;
        if (!std.mem.eql(u8, split.prefix, archive.sha256[0..2]) or
            !std.mem.eql(u8, split.basename[0..62], archive.sha256[2..]))
        {
            return error.SnapshotKeyShaMismatch;
        }
        var snapshots = try openExistingDir(store.io, store.root, "snapshots");
        defer snapshots.close(store.io);
        var sha_dir = try openExistingDir(store.io, snapshots, "sha256");
        defer sha_dir.close(store.io);
        var leaf = try openExistingDir(store.io, sha_dir, split.prefix);
        defer leaf.close(store.io);
        var actual = try verifyRelativeFile(store.allocator, store.io, leaf, split.basename, 0o444);
        defer actual.deinit(store.allocator);
        if (!std.mem.eql(u8, &actual.sha256, &archive.sha256) or actual.bytes != archive.bytes) {
            return error.SnapshotVerificationFailed;
        }

        const archive_rel = archive.key;
        var environment = cleanToolEnvironment(store.allocator);
        defer environment.deinit();
        const listing = try runCleanCapture(
            store.allocator,
            store.io,
            &.{ "/usr/bin/tar", "--use-compress-program=/usr/bin/zstd", "-tvf", archive_rel },
            store.root,
            &environment,
        );
        defer freeRunResult(store.allocator, listing);
        try validateSnapshotListing(store.allocator, listing.stdout, objects);

        var proof = try SnapshotProofWorkspace.init(store.io, store.root);
        defer proof.deinitAfterError();
        const proof_path = try proof.relativePath(store.allocator);
        defer store.allocator.free(proof_path);
        const extraction = try runCleanCapture(
            store.allocator,
            store.io,
            &.{
                "/usr/bin/tar",
                "--use-compress-program=/usr/bin/zstd",
                "--no-same-owner",
                "-xf",
                archive_rel,
                "-C",
                proof_path,
            },
            store.root,
            &environment,
        );
        defer freeRunResult(store.allocator, extraction);

        {
            var proof_objects = try openExistingDir(store.io, proof.dir(), "objects");
            defer proof_objects.close(store.io);
            var proof_sha = try openExistingDir(store.io, proof_objects, "sha256");
            defer proof_sha.close(store.io);
            for (objects) |object| {
                {
                    const object_split = splitObjectKey(object.key) orelse return error.InvalidObjectKey;
                    var proof_leaf = try openExistingDir(store.io, proof_sha, object_split.prefix);
                    defer proof_leaf.close(store.io);
                    var reconstructed = try verifyRelativeFile(
                        store.allocator,
                        store.io,
                        proof_leaf,
                        object_split.basename,
                        object.mode,
                    );
                    defer reconstructed.deinit(store.allocator);
                    if (!sameFileIdentity(reconstructed, object)) return error.ConstituentMismatch;
                }
            }
        }
        try proof.finish();
    }
};

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

const dormant_candidate_key = "authority/zllvm/v1/manifests/candidate.tsv";
const dormant_generation_key = "authority/zllvm/v1/manifests/generation-00000001.tsv";
const dormant_lineage_key = "authority/zllvm/v1/lineage/generation-00000001.tsv";
const dormant_receipt_key =
    "authority/zllvm/v1/receipts/publication/generation-00000001-payload-copy.tsv";
const dormant_candidate_magic = "zllvm-authority-candidate-v1";
const dormant_candidate_header =
    "authority_id\tgeneration\tpayload_root\tgeneration_manifest_key\tgeneration_manifest_sha256\tgeneration_manifest_bytes\tgeneration_manifest_mode\tlineage_key\tlineage_sha256\tpayload_copy_receipt_key\tpayload_copy_receipt_sha256\tsource_authority_root\tsource_generation_manifest_sha256\tstate";
const dormant_lineage_magic = "zllvm-artifact-lineage-v1";
const dormant_lineage_header =
    "generation\tparent_generation\tparent_manifest_sha256\tgeneration_manifest_sha256\tsource_authority_root\tsource_generation_manifest_sha256\ttransition";
const dormant_receipt_magic = "zllvm-payload-copy-receipt-v1";
const dormant_receipt_header =
    "receipt_id\tgeneration\tsource_root\tdestination_root\tsource_inventory_sha256\tsource_file_ledger_sha256\tsource_destination_ledger_sha256\tpayload_files\tpayload_bytes\tobjects\tsnapshots\tdestination_modes\tcopy_evidence_path\tcopy_evidence_sha256\tresult";
const dormant_real_control_root = "/home/oleg/prog/z_llvm/local-state/control";
const dormant_real_authority_root =
    "/home/oleg/prog/z_llvm/local-state/control/authority/zllvm/v1";
const dormant_real_payload_root =
    "/home/oleg/prog/z_llvm/local-state/artifacts/zllvm-authority-v1";
const dormant_real_source_root = "/home/oleg/prog/z_llvm-artifacts";
const dormant_git_executable = "/usr/bin/git";
const dormant_git_bytes = 4_066_232;
const dormant_git_sha256 = "2a8c18fbf43da9f692d75474c72bea9dfd796c260b0f3dfe456376abc3bbd668";
const dormant_control_commit = "9c55bda34088e1230b0b91a126d35795a3ac70b4";
const dormant_control_tree = "756369ad4a89d806f463bd8094c5159d8c973d7e";
const dormant_exact_real_source_manifest_sha256 =
    "61b7426bd52a3a139999f17f36d91ecaab954e6132fe36eca541480cdf31104d";
const dormant_exact_real_source_inventory_sha256 =
    "3234fb508d370878efe082cf1accb5af3b488372bf3f1ee7e9e87408a37a2d7c";
const dormant_exact_real_source_file_ledger_sha256 =
    "a06c48e1549d16b9f924cc2b5f0404e60d7755a785bf3a4a23311c2383279a65";
const dormant_exact_real_source_destination_ledger_sha256 =
    "4c29709b9ef9242dd799ab52d346cdf302f5728d35e37e0d78063e892a6cf9e8";
const dormant_exact_real_copy_evidence_path =
    "docs/evidence/inbox202_local_state_artifact_copy_verify.md";
const dormant_exact_real_copy_evidence_sha256 =
    "4b532daabe33e7c6eaca7f0ab412d9c271b55b6b1de8235dd3d4f65d7ab6f7a6";
const dormant_exact_real_acceptance_environment =
    "ZLLVM_INBOX206CQ_EXACT_REAL_ACCEPTANCE";
const dormant_exact_real_acceptance_token =
    "INBOX-206CQ-EXACT-REAL-ACCEPTANCE-V1";
const dormant_exact_real_acceptance_receipt_directory =
    "local-state/validations/inbox206cq";
const dormant_exact_real_acceptance_receipt_basename =
    "exact_real_acceptance_receipt_v1.tsv";
const dormant_exact_real_acceptance_magic =
    "zllvm-exact-real-acceptance-receipt-v1";
const dormant_exact_real_acceptance_capability =
    "inbox206cq-exact-real-validation-v1";
const dormant_exact_real_acceptance_header =
    "capability\tcontrol_root\tauthority_root\tpayload_root\tsource_root\tsource_manifest_sha256\tsource_inventory_sha256\tsource_file_ledger_sha256\tsource_destination_ledger_sha256\tcopy_evidence_path\tcopy_evidence_sha256\tregistration_full_sha256\tregistration_path_sha256\tregistration_topology_sha256\tregistration_non_main_sha256\tbefore_snapshot_bytes\tbefore_snapshot_sha256\tafter_snapshot_bytes\tafter_snapshot_sha256\tvalidation_disposition\tgeneration_manifest_sha256\tpayload_files\tpayload_bytes\tobjects\tsnapshots\tcreated_paths\tremoved_paths\tmodified_paths\tpublication_path_changes\tlogical_state_modified\tcompletion";
const dormant_exact_real_acceptance_identity_header =
    "canonical_body_bytes\tcanonical_body_sha256";
const dormant_exact_real_acceptance_receipt_max_bytes = 16 * 1024;
const dormant_exact_real_copy_evidence_max_bytes = 1024 * 1024;

const ControlGitEntrySpec = struct {
    mode: []const u8,
    kind: []const u8,
    object_id: []const u8,
    path: []const u8,
};

const dormant_real_control_entries = [_]ControlGitEntrySpec{
    .{
        .mode = "100644",
        .kind = "blob",
        .object_id = "1652b3dae95b0cd7e26efbdd3e989588f7abcbd4",
        .path = dormant_lineage_key,
    },
    .{
        .mode = "100644",
        .kind = "blob",
        .object_id = "ad3dfaf211a583481eea31b78fce77a901dcce34",
        .path = dormant_candidate_key,
    },
    .{
        .mode = "100644",
        .kind = "blob",
        .object_id = "aa4637a2747d09afd450c925cc38bf01843e6cb3",
        .path = dormant_generation_key,
    },
    .{
        .mode = "100644",
        .kind = "blob",
        .object_id = "e0a872bd03847c63e0ece6d3f17a74042a7049bc",
        .path = dormant_receipt_key,
    },
};

const dormant_synthetic_control_entries = [_]ControlGitEntrySpec{
    .{
        .mode = "100644",
        .kind = "blob",
        .object_id = "1111111111111111111111111111111111111111",
        .path = dormant_lineage_key,
    },
    .{
        .mode = "100644",
        .kind = "blob",
        .object_id = "2222222222222222222222222222222222222222",
        .path = dormant_candidate_key,
    },
    .{
        .mode = "100644",
        .kind = "blob",
        .object_id = "3333333333333333333333333333333333333333",
        .path = dormant_generation_key,
    },
    .{
        .mode = "100644",
        .kind = "blob",
        .object_id = "4444444444444444444444444444444444444444",
        .path = dormant_receipt_key,
    },
};

const DormantControlFileExpectationSpec = struct {
    component: DormantComponent,
    path: []const u8,
    sha256: []const u8,
    bytes: u64,
    mode: u16,
};

const dormant_real_control_file_expectations = [_]DormantControlFileExpectationSpec{
    .{
        .component = .candidate,
        .path = dormant_candidate_key,
        .sha256 = "7c0aa46fb6c0cb2b93034bbb6b520b6d4831fedea333983002622197a74c832b",
        .bytes = 899,
        .mode = 0o644,
    },
    .{
        .component = .generation,
        .path = dormant_generation_key,
        .sha256 = "61b7426bd52a3a139999f17f36d91ecaab954e6132fe36eca541480cdf31104d",
        .bytes = 27_823,
        .mode = 0o644,
    },
    .{
        .component = .lineage,
        .path = dormant_lineage_key,
        .sha256 = "f8b22b687f3d3cb727ba82e92c3a346c7025958387f3a45d4143fb42936c6a3a",
        .bytes = 378,
        .mode = 0o644,
    },
    .{
        .component = .receipt,
        .path = dormant_receipt_key,
        .sha256 = "9c6748234292c963c9716504a1451c4da0cdb0fe2ce1642d1c5fa83264aa19a3",
        .bytes = 792,
        .mode = 0o644,
    },
};

const DormantComponent = enum {
    candidate,
    generation,
    lineage,
    receipt,

    fn missing(component: DormantComponent) anyerror {
        return switch (component) {
            .candidate => error.DormantCandidateMissing,
            .generation => error.DormantGenerationMissing,
            .lineage => error.DormantLineageMissing,
            .receipt => error.DormantReceiptMissing,
        };
    }

    fn malformed(component: DormantComponent) anyerror {
        return switch (component) {
            .candidate => error.DormantCandidateMalformed,
            .generation => error.DormantGenerationMalformed,
            .lineage => error.DormantLineageMalformed,
            .receipt => error.DormantReceiptMalformed,
        };
    }

    fn mismatched(component: DormantComponent) anyerror {
        return switch (component) {
            .candidate => error.DormantCandidateMismatched,
            .generation => error.DormantGenerationMismatched,
            .lineage => error.DormantLineageMismatched,
            .receipt => error.DormantReceiptMismatched,
        };
    }

    fn unsafe(component: DormantComponent) anyerror {
        return switch (component) {
            .candidate => error.DormantCandidateUnsafe,
            .generation => error.DormantGenerationUnsafe,
            .lineage => error.DormantLineageUnsafe,
            .receipt => error.DormantReceiptUnsafe,
        };
    }
};

const DormantOwnedRow = struct {
    storage: []u8,
    fields: [][]const u8,

    fn deinit(row: *DormantOwnedRow, allocator: std.mem.Allocator) void {
        allocator.free(row.fields);
        allocator.free(row.storage);
        row.* = undefined;
    }
};

const ControlGitEntry = struct {
    mode: [6]u8,
    kind: [4]u8,
    object_id: [40]u8,
    path: []u8,

    fn deinit(entry: *ControlGitEntry, allocator: std.mem.Allocator) void {
        allocator.free(entry.path);
        entry.* = undefined;
    }
};

const ControlGitObservation = struct {
    allocator: std.mem.Allocator,
    commit: [40]u8,
    tree: [40]u8,
    branch: []u8,
    status: []u8,
    remotes: []u8,
    entries: []ControlGitEntry,

    fn initOwned(
        allocator: std.mem.Allocator,
        commit: []const u8,
        tree: []const u8,
        branch: []const u8,
        status: []const u8,
        remotes: []const u8,
        specs: []const ControlGitEntrySpec,
    ) !ControlGitObservation {
        const owned_branch = try allocator.dupe(u8, branch);
        errdefer allocator.free(owned_branch);
        const owned_status = try allocator.dupe(u8, status);
        errdefer allocator.free(owned_status);
        const owned_remotes = try allocator.dupe(u8, remotes);
        errdefer allocator.free(owned_remotes);
        const entries = try allocator.alloc(ControlGitEntry, specs.len);
        errdefer allocator.free(entries);
        var initialized: usize = 0;
        errdefer for (entries[0..initialized]) |*entry| entry.deinit(allocator);
        for (specs, entries) |spec, *entry| {
            if (!std.mem.eql(u8, spec.mode, "100644") or
                !std.mem.eql(u8, spec.kind, "blob") or
                spec.object_id.len != 40)
            {
                return error.DormantControlGitMalformed;
            }
            for (spec.object_id) |byte| {
                if (!std.ascii.isDigit(byte) and (byte < 'a' or byte > 'f')) {
                    return error.DormantControlGitMalformed;
                }
            }
            validateRelativeKey(spec.path) catch return error.DormantControlGitMalformed;
            entry.* = .{
                .mode = spec.mode[0..6].*,
                .kind = spec.kind[0..4].*,
                .object_id = spec.object_id[0..40].*,
                .path = try allocator.dupe(u8, spec.path),
            };
            initialized += 1;
        }
        return .{
            .allocator = allocator,
            .commit = try controlGitObjectId(commit),
            .tree = try controlGitObjectId(tree),
            .branch = owned_branch,
            .status = owned_status,
            .remotes = owned_remotes,
            .entries = entries,
        };
    }

    fn initRealExpected(allocator: std.mem.Allocator) !ControlGitObservation {
        return initOwned(
            allocator,
            dormant_control_commit,
            dormant_control_tree,
            "main",
            "",
            "",
            &dormant_real_control_entries,
        );
    }

    fn initSyntheticExpected(allocator: std.mem.Allocator) !ControlGitObservation {
        if (!builtin.is_test) return error.TestOnlyOperation;
        return initOwned(
            allocator,
            "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
            "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
            "main",
            "",
            "",
            &dormant_synthetic_control_entries,
        );
    }

    fn deinit(observation: *ControlGitObservation) void {
        for (observation.entries) |*entry| entry.deinit(observation.allocator);
        observation.allocator.free(observation.entries);
        observation.allocator.free(observation.remotes);
        observation.allocator.free(observation.status);
        observation.allocator.free(observation.branch);
        observation.* = undefined;
    }
};

const DormantRolePolicyKind = enum {
    exact_real,
    synthetic_test,
};

const DormantControlFileExpectation = struct {
    component: DormantComponent,
    path: []u8,
    sha256: [64]u8,
    bytes: u64,
    mode: u16,

    fn deinit(expectation: *DormantControlFileExpectation, allocator: std.mem.Allocator) void {
        allocator.free(expectation.path);
        expectation.* = undefined;
    }
};

const DormantRootPolicy = struct {
    allocator: std.mem.Allocator,
    kind: DormantRolePolicyKind,
    main_root: []u8,
    control_root: []u8,
    authority_root: []u8,
    payload_root: []u8,
    source_root: []u8,
    supplemental_control_root: []u8,
    non_main_roots: [][]u8,
    control_files: []DormantControlFileExpectation,
    observed_control: ControlGitObservation,
    expected_control: ControlGitObservation,

    fn initOwned(
        allocator: std.mem.Allocator,
        kind: DormantRolePolicyKind,
        main_root: []const u8,
        control_root: []const u8,
        authority_root: []const u8,
        payload_root: []const u8,
        source_root: []const u8,
        supplemental_control_root: []const u8,
        non_main_roots: []const []const u8,
        control_file_specs: []const DormantControlFileExpectationSpec,
        observed_control: *ControlGitObservation,
        expected_control: *ControlGitObservation,
    ) !DormantRootPolicy {
        const owned_main = try allocator.dupe(u8, main_root);
        errdefer allocator.free(owned_main);
        const owned_control = try allocator.dupe(u8, control_root);
        errdefer allocator.free(owned_control);
        const owned_authority = try allocator.dupe(u8, authority_root);
        errdefer allocator.free(owned_authority);
        const owned_payload = try allocator.dupe(u8, payload_root);
        errdefer allocator.free(owned_payload);
        const owned_source = try allocator.dupe(u8, source_root);
        errdefer allocator.free(owned_source);
        const owned_supplemental = try allocator.dupe(u8, supplemental_control_root);
        errdefer allocator.free(owned_supplemental);
        const owned_non_main = try allocator.alloc([]u8, non_main_roots.len);
        errdefer allocator.free(owned_non_main);
        var initialized: usize = 0;
        errdefer for (owned_non_main[0..initialized]) |path| allocator.free(path);
        for (non_main_roots, owned_non_main) |path, *owned| {
            owned.* = try allocator.dupe(u8, path);
            initialized += 1;
        }
        const owned_control_files = try allocator.alloc(
            DormantControlFileExpectation,
            control_file_specs.len,
        );
        errdefer allocator.free(owned_control_files);
        var initialized_control_files: usize = 0;
        var seen_control_components = [_]bool{false} ** 4;
        errdefer for (owned_control_files[0..initialized_control_files]) |*expectation| {
            expectation.deinit(allocator);
        };
        for (control_file_specs, owned_control_files) |spec, *expectation| {
            const component_index = @intFromEnum(spec.component);
            if (!dormantControlKeyMatches(spec.component, spec.path) or
                seen_control_components[component_index] or
                spec.mode != 0o644 or
                spec.bytes > 4 * 1024 * 1024)
            {
                return error.DormantControlGitMalformed;
            }
            try validateSha(spec.sha256);
            expectation.* = .{
                .component = spec.component,
                .path = try allocator.dupe(u8, spec.path),
                .sha256 = spec.sha256[0..64].*,
                .bytes = spec.bytes,
                .mode = spec.mode,
            };
            seen_control_components[component_index] = true;
            initialized_control_files += 1;
        }
        if (owned_control_files.len != 4) return error.DormantControlGitMalformed;
        const policy: DormantRootPolicy = .{
            .allocator = allocator,
            .kind = kind,
            .main_root = owned_main,
            .control_root = owned_control,
            .authority_root = owned_authority,
            .payload_root = owned_payload,
            .source_root = owned_source,
            .supplemental_control_root = owned_supplemental,
            .non_main_roots = owned_non_main,
            .control_files = owned_control_files,
            .observed_control = observed_control.*,
            .expected_control = expected_control.*,
        };
        observed_control.* = undefined;
        expected_control.* = undefined;
        return policy;
    }

    fn deinit(policy: *DormantRootPolicy) void {
        policy.expected_control.deinit();
        policy.observed_control.deinit();
        for (policy.control_files) |*expectation| expectation.deinit(policy.allocator);
        policy.allocator.free(policy.control_files);
        for (policy.non_main_roots) |path| policy.allocator.free(path);
        policy.allocator.free(policy.non_main_roots);
        policy.allocator.free(policy.supplemental_control_root);
        policy.allocator.free(policy.source_root);
        policy.allocator.free(policy.payload_root);
        policy.allocator.free(policy.authority_root);
        policy.allocator.free(policy.control_root);
        policy.allocator.free(policy.main_root);
        policy.* = undefined;
    }
};

fn controlGitObjectId(value: []const u8) ![40]u8 {
    if (value.len != 40) return error.DormantControlGitMalformed;
    for (value) |byte| {
        if (!std.ascii.isDigit(byte) and (byte < 'a' or byte > 'f')) {
            return error.DormantControlGitMalformed;
        }
    }
    return value[0..40].*;
}

fn controlGitSingleLine(output: []const u8) ![]const u8 {
    if (output.len < 2 or output[output.len - 1] != '\n' or
        std.mem.indexOfScalar(u8, output, '\r') != null or
        std.mem.indexOfScalar(u8, output[0 .. output.len - 1], '\n') != null)
    {
        return error.DormantControlGitMalformed;
    }
    return output[0 .. output.len - 1];
}

fn parseControlGitTreeSpecs(
    allocator: std.mem.Allocator,
    output: []const u8,
) ![]ControlGitEntrySpec {
    if (output.len == 0 or output[output.len - 1] != 0) {
        return error.DormantControlGitMalformed;
    }
    var specs: std.ArrayList(ControlGitEntrySpec) = .empty;
    errdefer specs.deinit(allocator);
    var records = std.mem.splitScalar(u8, output, 0);
    while (records.next()) |record| {
        if (record.len == 0) {
            if (records.next() != null) return error.DormantControlGitMalformed;
            break;
        }
        if (specs.items.len == 16) return error.DormantControlGitMalformed;
        const first_space = std.mem.indexOfScalar(u8, record, ' ') orelse
            return error.DormantControlGitMalformed;
        const second_space_offset = std.mem.indexOfScalar(
            u8,
            record[first_space + 1 ..],
            ' ',
        ) orelse return error.DormantControlGitMalformed;
        const second_space = first_space + 1 + second_space_offset;
        const tab = std.mem.indexOfScalar(u8, record, '\t') orelse
            return error.DormantControlGitMalformed;
        if (second_space + 1 >= tab or
            std.mem.indexOfScalar(u8, record[tab + 1 ..], '\t') != null)
        {
            return error.DormantControlGitMalformed;
        }
        try specs.append(allocator, .{
            .mode = record[0..first_space],
            .kind = record[first_space + 1 .. second_space],
            .object_id = record[second_space + 1 .. tab],
            .path = record[tab + 1 ..],
        });
    }
    return specs.toOwnedSlice(allocator);
}

fn cleanControlGitEnvironment(
    allocator: std.mem.Allocator,
) !std.process.Environ.Map {
    var environment = std.process.Environ.Map.init(allocator);
    errdefer environment.deinit();
    try environment.put("PATH", "/usr/bin:/bin");
    try environment.put("LC_ALL", "C");
    try environment.put("HOME", "/nonexistent");
    try environment.put("XDG_CONFIG_HOME", "/nonexistent");
    try environment.put("GIT_CONFIG_NOSYSTEM", "1");
    try environment.put("GIT_CONFIG_GLOBAL", "/dev/null");
    try environment.put("GIT_CONFIG_SYSTEM", "/dev/null");
    try environment.put("GIT_OPTIONAL_LOCKS", "0");
    try environment.put("GIT_TERMINAL_PROMPT", "0");
    try environment.put("GIT_PAGER", "cat");
    try environment.put("PAGER", "cat");
    return environment;
}

fn runControlGit(
    allocator: std.mem.Allocator,
    io: std.Io,
    args: []const []const u8,
) ![]u8 {
    var environment = try cleanControlGitEnvironment(allocator);
    defer environment.deinit();
    const result = try std.process.run(allocator, io, .{
        .argv = args,
        .environ_map = &environment,
        .stdout_limit = .limited(64 * 1024),
        .stderr_limit = .limited(64 * 1024),
    });
    if (!termSuccess(result.term) or result.stderr.len != 0) {
        freeRunResult(allocator, result);
        return error.DormantControlGitFailed;
    }
    allocator.free(result.stderr);
    return result.stdout;
}

fn acquireControlGitObservation(
    allocator: std.mem.Allocator,
    io: std.Io,
) !ControlGitObservation {
    var executable = try std.Io.Dir.openFileAbsolute(io, dormant_git_executable, .{
        .allow_directory = false,
        .follow_symlinks = false,
    });
    defer executable.close(io);
    var executable_identity = try identityOfOpenFileAnyMode(allocator, io, executable);
    defer executable_identity.deinit(allocator);
    if (executable_identity.mode != 0o755 or
        executable_identity.bytes != dormant_git_bytes or
        !std.mem.eql(u8, &executable_identity.sha256, dormant_git_sha256))
    {
        return error.DormantControlGitIdentityMismatch;
    }

    const commit_output = try runControlGit(allocator, io, &.{
        dormant_git_executable,
        "-C",
        dormant_real_control_root,
        "rev-parse",
        "--verify",
        "HEAD",
    });
    defer allocator.free(commit_output);
    const tree_output = try runControlGit(allocator, io, &.{
        dormant_git_executable,
        "-C",
        dormant_real_control_root,
        "rev-parse",
        "HEAD^{tree}",
    });
    defer allocator.free(tree_output);
    const branch_output = try runControlGit(allocator, io, &.{
        dormant_git_executable,
        "-C",
        dormant_real_control_root,
        "symbolic-ref",
        "--quiet",
        "--short",
        "HEAD",
    });
    defer allocator.free(branch_output);
    const status_output = try runControlGit(allocator, io, &.{
        dormant_git_executable,
        "-C",
        dormant_real_control_root,
        "status",
        "--porcelain=v1",
        "--untracked-files=all",
    });
    defer allocator.free(status_output);
    const remotes_output = try runControlGit(allocator, io, &.{
        dormant_git_executable,
        "-C",
        dormant_real_control_root,
        "remote",
    });
    defer allocator.free(remotes_output);
    const entries_output = try runControlGit(allocator, io, &.{
        dormant_git_executable,
        "-C",
        dormant_real_control_root,
        "ls-tree",
        "-r",
        "-z",
        "--full-tree",
        "HEAD",
        "--",
        "authority/zllvm/v1",
    });
    defer allocator.free(entries_output);
    const entry_specs = try parseControlGitTreeSpecs(allocator, entries_output);
    defer allocator.free(entry_specs);
    return ControlGitObservation.initOwned(
        allocator,
        try controlGitSingleLine(commit_output),
        try controlGitSingleLine(tree_output),
        try controlGitSingleLine(branch_output),
        status_output,
        remotes_output,
        entry_specs,
    );
}

fn validateControlGitObservation(
    observed: ControlGitObservation,
    expected: ControlGitObservation,
) !void {
    if (!std.mem.eql(u8, &observed.commit, &expected.commit) or
        !std.mem.eql(u8, &observed.tree, &expected.tree) or
        !std.mem.eql(u8, observed.branch, expected.branch) or
        !std.mem.eql(u8, observed.status, expected.status) or
        !std.mem.eql(u8, observed.remotes, expected.remotes) or
        observed.entries.len != expected.entries.len)
    {
        return error.DormantUnsafeRoot;
    }
    for (observed.entries, expected.entries) |actual, wanted| {
        if (!std.mem.eql(u8, &actual.mode, &wanted.mode) or
            !std.mem.eql(u8, &actual.kind, &wanted.kind) or
            !std.mem.eql(u8, &actual.object_id, &wanted.object_id) or
            !std.mem.eql(u8, actual.path, wanted.path))
        {
            return error.DormantUnsafeRoot;
        }
    }
}

fn pathsIntersect(a: []const u8, b: []const u8) bool {
    return pathContains(a, b) or pathContains(b, a);
}

const DormantAuthorityConfig = struct {
    allocator: std.mem.Allocator,
    io: std.Io,
    guard: RegistrationGuard,
    root_policy: DormantRootPolicy,
    control_root: []u8,
    authority_root: []u8,
    payload_root: []u8,
    source_root: []u8,
    source_manifest_sha256: [64]u8,
    expected_source_inventory_sha256: [64]u8,
    expected_source_file_ledger_sha256: [64]u8,
    expected_source_destination_ledger_sha256: [64]u8,
    expected_copy_evidence_path: []u8,
    expected_copy_evidence_sha256: [64]u8,
    expected_registration_full_hash: [64]u8,
    expected_registration_path_hash: [64]u8,
    expected_registration_topology_hash: [64]u8,
    expected_registration_non_main_hash: [64]u8,

    fn initExactRealCandidate(
        allocator: std.mem.Allocator,
        io: std.Io,
        source_manifest_sha256: []const u8,
        source_inventory_sha256: []const u8,
        source_file_ledger_sha256: []const u8,
        source_destination_ledger_sha256: []const u8,
        copy_evidence_path: []const u8,
        copy_evidence_sha256: []const u8,
    ) !DormantAuthorityConfig {
        var guard = try RegistrationGuard.init(allocator, io);
        errdefer guard.deinit();
        if (!std.mem.eql(u8, guard.frozen.paths[0], main_repository)) {
            return error.DormantRegistrationStale;
        }
        var observed = try acquireControlGitObservation(allocator, io);
        var observed_transferred = false;
        errdefer if (!observed_transferred) observed.deinit();
        var expected = try ControlGitObservation.initRealExpected(allocator);
        var expected_transferred = false;
        errdefer if (!expected_transferred) expected.deinit();
        var policy = try DormantRootPolicy.initOwned(
            allocator,
            .exact_real,
            main_repository,
            dormant_real_control_root,
            dormant_real_authority_root,
            dormant_real_payload_root,
            dormant_real_source_root,
            dormant_real_control_root,
            guard.frozen.paths[1..],
            &dormant_real_control_file_expectations,
            &observed,
            &expected,
        );
        observed_transferred = true;
        expected_transferred = true;
        errdefer policy.deinit();
        return initOwned(
            allocator,
            io,
            &guard,
            &policy,
            source_manifest_sha256,
            source_inventory_sha256,
            source_file_ledger_sha256,
            source_destination_ledger_sha256,
            copy_evidence_path,
            copy_evidence_sha256,
        );
    }

    fn initSynthetic(
        allocator: std.mem.Allocator,
        io: std.Io,
        main_root: []const u8,
        control_root: []const u8,
        payload_root: []const u8,
        source_root: []const u8,
        supplemental_control_root: []const u8,
        non_main_roots: []const []const u8,
        observed_control: *ControlGitObservation,
        control_file_specs: []const DormantControlFileExpectationSpec,
        source_manifest_sha256: []const u8,
        source_inventory_sha256: []const u8,
        source_file_ledger_sha256: []const u8,
        source_destination_ledger_sha256: []const u8,
        copy_evidence_path: []const u8,
        copy_evidence_sha256: []const u8,
    ) !DormantAuthorityConfig {
        if (!builtin.is_test) return error.TestOnlyOperation;
        const roots = [_][]const u8{ main_root, control_root, payload_root, source_root };
        for (roots) |root| {
            if (!pathContains(dormant_test_root, root) or
                pathsIntersect(root, dormant_real_control_root) or
                pathsIntersect(root, dormant_real_payload_root) or
                pathsIntersect(root, dormant_real_source_root))
            {
                return error.DormantUnsafeRoot;
            }
        }
        const authority_root = try std.fs.path.join(
            allocator,
            &.{ control_root, "authority", "zllvm", "v1" },
        );
        defer allocator.free(authority_root);
        var guard = try RegistrationGuard.init(allocator, io);
        errdefer guard.deinit();
        var expected = try ControlGitObservation.initSyntheticExpected(allocator);
        var expected_transferred = false;
        errdefer if (!expected_transferred) expected.deinit();
        var policy = try DormantRootPolicy.initOwned(
            allocator,
            .synthetic_test,
            main_root,
            control_root,
            authority_root,
            payload_root,
            source_root,
            supplemental_control_root,
            non_main_roots,
            control_file_specs,
            observed_control,
            &expected,
        );
        expected_transferred = true;
        errdefer policy.deinit();
        return initOwned(
            allocator,
            io,
            &guard,
            &policy,
            source_manifest_sha256,
            source_inventory_sha256,
            source_file_ledger_sha256,
            source_destination_ledger_sha256,
            copy_evidence_path,
            copy_evidence_sha256,
        );
    }

    fn initOwned(
        allocator: std.mem.Allocator,
        io: std.Io,
        guard: *RegistrationGuard,
        root_policy: *DormantRootPolicy,
        source_manifest_sha256: []const u8,
        source_inventory_sha256: []const u8,
        source_file_ledger_sha256: []const u8,
        source_destination_ledger_sha256: []const u8,
        copy_evidence_path: []const u8,
        copy_evidence_sha256: []const u8,
    ) !DormantAuthorityConfig {
        try validateSha(source_manifest_sha256);
        try validateSha(source_inventory_sha256);
        try validateSha(source_file_ledger_sha256);
        try validateSha(source_destination_ledger_sha256);
        try validateRelativeKey(copy_evidence_path);
        try validateSha(copy_evidence_sha256);
        const owned_control = try allocator.dupe(u8, root_policy.control_root);
        errdefer allocator.free(owned_control);
        const owned_authority = try allocator.dupe(u8, root_policy.authority_root);
        errdefer allocator.free(owned_authority);
        const owned_payload = try allocator.dupe(u8, root_policy.payload_root);
        errdefer allocator.free(owned_payload);
        const owned_source = try allocator.dupe(u8, root_policy.source_root);
        errdefer allocator.free(owned_source);
        const owned_copy_evidence_path = try allocator.dupe(u8, copy_evidence_path);
        errdefer allocator.free(owned_copy_evidence_path);
        const result: DormantAuthorityConfig = .{
            .allocator = allocator,
            .io = io,
            .guard = guard.*,
            .root_policy = root_policy.*,
            .control_root = owned_control,
            .authority_root = owned_authority,
            .payload_root = owned_payload,
            .source_root = owned_source,
            .source_manifest_sha256 = source_manifest_sha256[0..64].*,
            .expected_source_inventory_sha256 = source_inventory_sha256[0..64].*,
            .expected_source_file_ledger_sha256 = source_file_ledger_sha256[0..64].*,
            .expected_source_destination_ledger_sha256 = source_destination_ledger_sha256[0..64].*,
            .expected_copy_evidence_path = owned_copy_evidence_path,
            .expected_copy_evidence_sha256 = copy_evidence_sha256[0..64].*,
            .expected_registration_full_hash = guard.frozen.full_hash,
            .expected_registration_path_hash = guard.frozen.path_hash,
            .expected_registration_topology_hash = guard.frozen.topology_hash,
            .expected_registration_non_main_hash = guard.frozen.non_main_hash,
        };
        guard.* = undefined;
        root_policy.* = undefined;
        return result;
    }

    fn deinit(config: *DormantAuthorityConfig) void {
        config.allocator.free(config.expected_copy_evidence_path);
        config.allocator.free(config.source_root);
        config.allocator.free(config.payload_root);
        config.allocator.free(config.authority_root);
        config.allocator.free(config.control_root);
        config.root_policy.deinit();
        config.guard.deinit();
        config.* = undefined;
    }

    fn validateRegistration(config: *const DormantAuthorityConfig) !void {
        if (!std.mem.eql(
            u8,
            &config.expected_registration_full_hash,
            &config.guard.frozen.full_hash,
        ) or
            !std.mem.eql(
                u8,
                &config.expected_registration_path_hash,
                &config.guard.frozen.path_hash,
            ) or
            !std.mem.eql(
                u8,
                &config.expected_registration_topology_hash,
                &config.guard.frozen.topology_hash,
            ) or
            !std.mem.eql(
                u8,
                &config.expected_registration_non_main_hash,
                &config.guard.frozen.non_main_hash,
            ))
        {
            return error.DormantRegistrationStale;
        }
        config.guard.assertCurrent() catch return error.DormantRegistrationStale;
    }
};

const DormantAuthorityValidation = struct {
    manifest_sha256: [64]u8,
    payload_files: u64,
    payload_bytes: u64,
    objects: u64,
    snapshots: u64,
};

fn parseDormantOwnedRow(
    allocator: std.mem.Allocator,
    input: []const u8,
    magic: []const u8,
    header: []const u8,
    field_count: usize,
) !DormantOwnedRow {
    if (!std.mem.endsWith(u8, input, "\n") or std.mem.indexOfScalar(u8, input, '\r') != null) {
        return error.NonCanonicalDormantRecord;
    }
    const storage = try allocator.dupe(u8, input);
    errdefer allocator.free(storage);
    var lines = std.mem.splitScalar(u8, storage, '\n');
    if (!std.mem.eql(u8, lines.next() orelse return error.MissingDormantMagic, magic) or
        !std.mem.eql(u8, lines.next() orelse return error.MissingDormantHeader, header))
    {
        return error.UnknownDormantSchema;
    }
    const data = lines.next() orelse return error.MissingDormantRow;
    if (data.len == 0 or
        !std.mem.eql(u8, lines.next() orelse return error.NonCanonicalDormantRecord, "") or
        lines.next() != null)
    {
        return error.NonCanonicalDormantRecord;
    }
    const fields = try allocator.alloc([]const u8, field_count);
    errdefer allocator.free(fields);
    var field_it = std.mem.splitScalar(u8, data, '\t');
    for (fields) |*field| {
        field.* = field_it.next() orelse return error.MissingDormantField;
        try validateCanonicalField(allocator, field.*);
    }
    if (field_it.next() != null) return error.UnknownDormantField;

    var encoded: std.ArrayList(u8) = .empty;
    defer encoded.deinit(allocator);
    try encoded.appendSlice(allocator, magic);
    try encoded.append(allocator, '\n');
    try encoded.appendSlice(allocator, header);
    try encoded.append(allocator, '\n');
    for (fields, 0..) |field, index| {
        if (index != 0) try encoded.append(allocator, '\t');
        try encoded.appendSlice(allocator, field);
    }
    try encoded.append(allocator, '\n');
    if (!std.mem.eql(u8, encoded.items, input)) return error.NonCanonicalDormantRecord;
    return .{ .storage = storage, .fields = fields };
}

fn readDormantControlFile(
    config: *const DormantAuthorityConfig,
    component: DormantComponent,
    relative_path: []const u8,
) ![]u8 {
    if (!dormantControlKeyMatches(component, relative_path)) return component.unsafe();
    const expectation = dormantControlFileExpectation(
        &config.root_policy,
        component,
        relative_path,
    ) orelse return component.unsafe();
    var control = std.Io.Dir.openDirAbsolute(config.io, config.control_root, .{
        .access_sub_paths = true,
        .follow_symlinks = false,
    }) catch |err| return switch (err) {
        error.FileNotFound => component.missing(),
        error.SymLinkLoop, error.NotDir => component.unsafe(),
        else => component.malformed(),
    };
    defer control.close(config.io);
    const control_stat = control.stat(config.io) catch return component.unsafe();
    if (@as(u16, @intCast(control_stat.permissions.toMode() & 0o7777)) != 0o775) {
        return component.mismatched();
    }
    const parent_path = std.fs.path.dirname(relative_path) orelse ".";
    const basename = std.fs.path.basename(relative_path);
    var current = control;
    var current_owned = false;
    errdefer if (current_owned) current.close(config.io);
    var segments = std.mem.splitScalar(u8, parent_path, '/');
    while (segments.next()) |segment| {
        const next = openExistingDir(config.io, current, segment) catch |err|
            return switch (err) {
                error.FileNotFound => component.missing(),
                error.SymLinkLoop, error.NotDir => component.unsafe(),
                else => component.malformed(),
            };
        if (current_owned) current.close(config.io);
        current = next;
        current_owned = true;
        const directory_stat = current.stat(config.io) catch return component.unsafe();
        if (@as(u16, @intCast(directory_stat.permissions.toMode() & 0o7777)) != 0o755) {
            return component.mismatched();
        }
    }
    var parent = current;
    defer parent.close(config.io);
    current_owned = false;
    var file = parent.openFile(config.io, basename, .{
        .allow_directory = false,
        .follow_symlinks = false,
    }) catch |err| return switch (err) {
        error.FileNotFound => component.missing(),
        error.SymLinkLoop, error.NotDir => component.unsafe(),
        else => component.malformed(),
    };
    defer file.close(config.io);
    const stat = file.stat(config.io) catch return component.malformed();
    if (stat.kind != .file) return component.unsafe();
    if (@as(u16, @intCast(stat.permissions.toMode() & 0o7777)) != expectation.mode) {
        return component.mismatched();
    }
    if (config.root_policy.kind == .exact_real and stat.size != expectation.bytes) {
        return component.mismatched();
    }
    const size = std.math.cast(usize, stat.size) orelse return component.malformed();
    if (size > 4 * 1024 * 1024) return component.malformed();
    const bytes = try config.allocator.alloc(u8, size);
    errdefer config.allocator.free(bytes);
    var offset: usize = 0;
    while (offset < bytes.len) {
        const count = file.readPositional(
            config.io,
            &.{bytes[offset..]},
            offset,
        ) catch return component.malformed();
        if (count == 0) return component.malformed();
        offset += count;
    }
    var extra: [1]u8 = undefined;
    const extra_count = file.readPositional(
        config.io,
        &.{&extra},
        bytes.len,
    ) catch return component.malformed();
    if (extra_count != 0) return component.malformed();
    if (config.root_policy.kind == .exact_real and
        !std.mem.eql(u8, &sha256Hex(bytes), &expectation.sha256))
    {
        return component.mismatched();
    }
    return bytes;
}

fn dormantControlFileExpectation(
    policy: *const DormantRootPolicy,
    component: DormantComponent,
    relative_path: []const u8,
) ?*const DormantControlFileExpectation {
    var found: ?*const DormantControlFileExpectation = null;
    for (policy.control_files) |*expectation| {
        if (expectation.component == component and
            std.mem.eql(u8, expectation.path, relative_path))
        {
            if (found != null) return null;
            found = expectation;
        }
    }
    return found;
}

fn dormantControlKeyMatches(
    component: DormantComponent,
    relative_path: []const u8,
) bool {
    return switch (component) {
        .candidate => std.mem.eql(u8, relative_path, dormant_candidate_key),
        .generation => std.mem.eql(u8, relative_path, dormant_generation_key),
        .lineage => std.mem.eql(u8, relative_path, dormant_lineage_key),
        .receipt => std.mem.eql(u8, relative_path, dormant_receipt_key),
    };
}

fn validateDormantRoots(config: *const DormantAuthorityConfig) !void {
    try validateDormantControlRoot(config);
    try validateDormantAuthorityRoot(config);
    try validateDormantPayloadRoot(config);
    try validateDormantSourceRoot(config);
}

fn verifyDormantCopyEvidenceFromHeldRoot(
    allocator: std.mem.Allocator,
    io: std.Io,
    root: std.Io.Dir,
    relative_path: []const u8,
    expected_sha256: []const u8,
    max_bytes: u64,
) !FileIdentity {
    validateRelativeKey(relative_path) catch return error.DormantCopyEvidenceUnsafe;
    validateSha(expected_sha256) catch return error.DormantCopyEvidenceMismatched;
    const parent_path = std.fs.path.dirname(relative_path) orelse ".";
    const basename = std.fs.path.basename(relative_path);
    var parent = openPathNoFollow(io, root, parent_path, false) catch |err|
        return switch (err) {
            error.FileNotFound => error.DormantCopyEvidenceMissing,
            error.SymLinkLoop, error.NotDir => error.DormantCopyEvidenceUnsafe,
            else => error.DormantCopyEvidenceUnreadable,
        };
    defer parent.close(io);
    var file = parent.openFile(io, basename, .{
        .allow_directory = true,
        .follow_symlinks = false,
    }) catch |err| return switch (err) {
        error.FileNotFound => error.DormantCopyEvidenceMissing,
        error.SymLinkLoop, error.NotDir => error.DormantCopyEvidenceUnsafe,
        else => error.DormantCopyEvidenceUnreadable,
    };
    defer file.close(io);
    const stat = file.stat(io) catch return error.DormantCopyEvidenceUnreadable;
    if (stat.kind != .file) return error.DormantCopyEvidenceUnsafe;
    const mode: u16 = @intCast(stat.permissions.toMode() & 0o7777);
    if (mode & 0o111 != 0) return error.DormantCopyEvidenceExecutable;
    if (stat.size > max_bytes) return error.DormantCopyEvidenceTooLarge;
    var identity = identityOfOpenFileAnyMode(allocator, io, file) catch
        return error.DormantCopyEvidenceUnreadable;
    errdefer identity.deinit(allocator);
    if (identity.bytes != stat.size or identity.bytes > max_bytes or identity.mode != mode) {
        return error.DormantCopyEvidenceChangedDuringRead;
    }
    if (!std.mem.eql(u8, &identity.sha256, expected_sha256)) {
        return error.DormantCopyEvidenceMismatched;
    }
    return identity;
}

fn verifyDormantExactRealCopyEvidence(
    config: *const DormantAuthorityConfig,
) !void {
    if (config.root_policy.kind != .exact_real or
        !std.mem.eql(u8, config.root_policy.main_root, main_repository) or
        !std.mem.eql(u8, config.expected_copy_evidence_path, dormant_exact_real_copy_evidence_path) or
        !std.mem.eql(
            u8,
            &config.expected_copy_evidence_sha256,
            dormant_exact_real_copy_evidence_sha256,
        ))
    {
        return error.DormantCopyEvidenceAuthorityMismatched;
    }
    var repository = std.Io.Dir.openDirAbsolute(config.io, main_repository, .{
        .access_sub_paths = true,
        .follow_symlinks = false,
    }) catch return error.DormantCopyEvidenceUnsafe;
    defer repository.close(config.io);
    var identity = try verifyDormantCopyEvidenceFromHeldRoot(
        config.allocator,
        config.io,
        repository,
        config.expected_copy_evidence_path,
        &config.expected_copy_evidence_sha256,
        dormant_exact_real_copy_evidence_max_bytes,
    );
    identity.deinit(config.allocator);
}

fn validateDormantRoleDirectory(
    config: *const DormantAuthorityConfig,
    actual: []const u8,
    expected: []const u8,
    expected_mode: u16,
    missing_is_partial: bool,
) !void {
    if (!std.mem.eql(u8, actual, expected)) return error.DormantUnsafeRoot;
    const normalized = normalizedAbsolute(config.allocator, actual) catch
        return error.DormantUnsafeRoot;
    defer config.allocator.free(normalized);
    if (!std.mem.eql(u8, normalized, actual)) return error.DormantUnsafeRoot;
    const exists = validateAuthorityAncestry(config.allocator, config.io, actual) catch
        return error.DormantUnsafeRoot;
    if (!exists) {
        if (missing_is_partial) return error.DormantDestinationPartial;
        return error.DormantUnsafeRoot;
    }
    var directory = std.Io.Dir.openDirAbsolute(config.io, actual, .{
        .follow_symlinks = false,
    }) catch return error.DormantUnsafeRoot;
    defer directory.close(config.io);
    const stat = directory.stat(config.io) catch return error.DormantUnsafeRoot;
    if (@as(u16, @intCast(stat.permissions.toMode() & 0o7777)) != expected_mode) {
        return error.DormantUnsafeRoot;
    }
}

fn validateDormantNonMainDisjoint(
    policy: *const DormantRootPolicy,
    path: []const u8,
) !void {
    for (policy.non_main_roots) |protected| {
        if (pathsIntersect(path, protected)) return error.DormantUnsafeRoot;
    }
}

fn validateDormantControlRoot(config: *const DormantAuthorityConfig) !void {
    const policy = &config.root_policy;
    try validateDormantRoleDirectory(
        config,
        config.control_root,
        policy.control_root,
        0o775,
        false,
    );
    if (!pathContains(policy.main_root, config.control_root)) {
        return error.DormantUnsafeRoot;
    }
    try validateDormantNonMainDisjoint(policy, config.control_root);
    try validateControlGitObservation(policy.observed_control, policy.expected_control);
}

fn validateDormantAuthorityRoot(config: *const DormantAuthorityConfig) !void {
    const policy = &config.root_policy;
    try validateDormantRoleDirectory(
        config,
        config.authority_root,
        policy.authority_root,
        0o755,
        false,
    );
    if (!pathContains(config.control_root, config.authority_root) or
        !pathContains(policy.main_root, config.authority_root))
    {
        return error.DormantUnsafeRoot;
    }
    try validateDormantNonMainDisjoint(policy, config.authority_root);
}

fn validateDormantPayloadRoot(config: *const DormantAuthorityConfig) !void {
    const policy = &config.root_policy;
    try validateDormantRoleDirectory(
        config,
        config.payload_root,
        policy.payload_root,
        0o755,
        true,
    );
    if (!pathContains(policy.main_root, config.payload_root) or
        pathsIntersect(config.payload_root, policy.supplemental_control_root) or
        pathsIntersect(config.payload_root, config.control_root) or
        pathsIntersect(config.payload_root, config.authority_root) or
        pathsIntersect(config.payload_root, config.source_root))
    {
        return error.DormantUnsafeRoot;
    }
    try validateDormantNonMainDisjoint(policy, config.payload_root);
}

fn validateDormantSourceRoot(config: *const DormantAuthorityConfig) !void {
    const policy = &config.root_policy;
    try validateDormantRoleDirectory(
        config,
        config.source_root,
        policy.source_root,
        0o775,
        false,
    );
    if (pathsIntersect(config.source_root, policy.main_root) or
        pathsIntersect(config.source_root, policy.supplemental_control_root) or
        pathsIntersect(config.source_root, config.control_root) or
        pathsIntersect(config.source_root, config.authority_root) or
        pathsIntersect(config.source_root, config.payload_root))
    {
        return error.DormantUnsafeRoot;
    }
    try validateDormantNonMainDisjoint(policy, config.source_root);
}

const DormantExpectedEntry = struct {
    path: []u8,
    kind: std.Io.File.Kind,
};

fn appendDormantExpected(
    allocator: std.mem.Allocator,
    entries: *std.ArrayList(DormantExpectedEntry),
    path: []const u8,
    kind: std.Io.File.Kind,
) !void {
    for (entries.items) |entry| {
        if (std.mem.eql(u8, entry.path, path)) {
            if (entry.kind != kind) return error.DormantDestinationMismatched;
            return;
        }
    }
    try entries.append(allocator, .{
        .path = try allocator.dupe(u8, path),
        .kind = kind,
    });
}

fn freeDormantExpected(
    allocator: std.mem.Allocator,
    entries: *std.ArrayList(DormantExpectedEntry),
) void {
    for (entries.items) |entry| allocator.free(entry.path);
    entries.deinit(allocator);
}

fn findDormantExpected(
    entries: []const DormantExpectedEntry,
    path: []const u8,
    kind: std.Io.File.Kind,
) bool {
    for (entries) |entry| {
        if (entry.kind == kind and std.mem.eql(u8, entry.path, path)) return true;
    }
    return false;
}

fn inspectDormantTree(
    allocator: std.mem.Allocator,
    io: std.Io,
    dir: std.Io.Dir,
    prefix: []const u8,
    expected: []const DormantExpectedEntry,
    actual_count: *usize,
) !void {
    var iterator = dir.iterate();
    while (try iterator.next(io)) |entry| {
        const relative = if (prefix.len == 0)
            try allocator.dupe(u8, entry.name)
        else
            try std.fs.path.join(allocator, &.{ prefix, entry.name });
        defer allocator.free(relative);
        switch (entry.kind) {
            .directory => {
                if (!findDormantExpected(expected, relative, .directory)) {
                    return error.DormantDestinationExtra;
                }
                var child = dir.openDir(io, entry.name, .{
                    .access_sub_paths = true,
                    .iterate = true,
                    .follow_symlinks = false,
                }) catch return error.DormantDestinationUnsafe;
                defer child.close(io);
                const stat = child.stat(io) catch return error.DormantDestinationUnsafe;
                if (@as(u16, @intCast(stat.permissions.toMode() & 0o7777)) != 0o755) {
                    return error.DormantDestinationMismatched;
                }
                actual_count.* += 1;
                try inspectDormantTree(
                    allocator,
                    io,
                    child,
                    relative,
                    expected,
                    actual_count,
                );
            },
            .file => {
                if (!findDormantExpected(expected, relative, .file)) {
                    return error.DormantDestinationExtra;
                }
                actual_count.* += 1;
            },
            else => return error.DormantDestinationUnsafe,
        }
    }
}

fn verifyDormantDestination(
    config: *const DormantAuthorityConfig,
    manifest: Manifest,
) !DormantAuthorityValidation {
    var expected: std.ArrayList(DormantExpectedEntry) = .empty;
    defer freeDormantExpected(config.allocator, &expected);
    try appendDormantExpected(config.allocator, &expected, "incoming", .directory);
    try appendDormantExpected(config.allocator, &expected, "objects", .directory);
    try appendDormantExpected(config.allocator, &expected, "objects/sha256", .directory);
    try appendDormantExpected(config.allocator, &expected, "snapshots", .directory);
    try appendDormantExpected(config.allocator, &expected, "snapshots/sha256", .directory);

    var payload_files: u64 = 0;
    var payload_bytes: u64 = 0;
    var objects: u64 = 0;
    var snapshots: u64 = 0;
    for (manifest.rows) |row| {
        if (row.kind != .object and row.kind != .snapshot) continue;
        const split = if (row.kind == .object)
            splitObjectKey(row.key)
        else
            splitSnapshotKey(row.key);
        const key_split = split orelse return error.DormantDestinationMismatched;
        if (!std.mem.eql(u8, key_split.prefix, row.sha256[0..2])) {
            return error.DormantDestinationMismatched;
        }
        const prefix_path = if (row.kind == .object)
            try std.fmt.allocPrint(
                config.allocator,
                "objects/sha256/{s}",
                .{key_split.prefix},
            )
        else
            try std.fmt.allocPrint(
                config.allocator,
                "snapshots/sha256/{s}",
                .{key_split.prefix},
            );
        defer config.allocator.free(prefix_path);
        try appendDormantExpected(config.allocator, &expected, prefix_path, .directory);
        try appendDormantExpected(config.allocator, &expected, row.key, .file);
        payload_files += 1;
        payload_bytes = std.math.add(u64, payload_bytes, row.bytes) catch
            return error.DormantDestinationMismatched;
        if (row.kind == .object) objects += 1 else snapshots += 1;
    }

    var root = std.Io.Dir.openDirAbsolute(config.io, config.payload_root, .{
        .access_sub_paths = true,
        .iterate = true,
        .follow_symlinks = false,
    }) catch |err| return switch (err) {
        error.FileNotFound => error.DormantDestinationPartial,
        error.SymLinkLoop, error.NotDir => error.DormantDestinationUnsafe,
        else => error.DormantDestinationMismatched,
    };
    defer root.close(config.io);
    const root_stat = root.stat(config.io) catch return error.DormantDestinationUnsafe;
    if (@as(u16, @intCast(root_stat.permissions.toMode() & 0o7777)) != 0o755) {
        return error.DormantDestinationMismatched;
    }
    var actual_count: usize = 0;
    try inspectDormantTree(
        config.allocator,
        config.io,
        root,
        "",
        expected.items,
        &actual_count,
    );
    if (actual_count != expected.items.len) return error.DormantDestinationPartial;

    for (manifest.rows) |row| {
        if (row.kind != .object and row.kind != .snapshot) continue;
        const parent_path = std.fs.path.dirname(row.key) orelse
            return error.DormantDestinationMismatched;
        const basename = std.fs.path.basename(row.key);
        var parent = openPathNoFollow(config.io, root, parent_path, false) catch |err|
            return switch (err) {
                error.FileNotFound => error.DormantDestinationPartial,
                error.SymLinkLoop, error.NotDir => error.DormantDestinationUnsafe,
                else => error.DormantDestinationMismatched,
            };
        defer parent.close(config.io);
        var identity = verifyRelativeFile(
            config.allocator,
            config.io,
            parent,
            basename,
            0o444,
        ) catch |err| return switch (err) {
            error.FileNotFound => error.DormantDestinationPartial,
            error.SymLinkLoop, error.NotDir, error.NotRegularFile => error.DormantDestinationUnsafe,
            else => error.DormantDestinationMismatched,
        };
        defer identity.deinit(config.allocator);
        if (!std.mem.eql(u8, &identity.sha256, row.sha256) or identity.bytes != row.bytes) {
            return error.DormantDestinationMismatched;
        }
    }
    return .{
        .manifest_sha256 = undefined,
        .payload_files = payload_files,
        .payload_bytes = payload_bytes,
        .objects = objects,
        .snapshots = snapshots,
    };
}

fn validateDormantAuthorityCandidate(
    config: *const DormantAuthorityConfig,
) !DormantAuthorityValidation {
    try config.validateRegistration();
    try validateDormantRoots(config);
    if (config.root_policy.kind == .exact_real and
        std.mem.eql(u8, config.root_policy.main_root, main_repository))
    {
        try verifyDormantExactRealCopyEvidence(config);
    }

    const candidate_bytes = try readDormantControlFile(
        config,
        .candidate,
        dormant_candidate_key,
    );
    defer config.allocator.free(candidate_bytes);
    var candidate = parseDormantOwnedRow(
        config.allocator,
        candidate_bytes,
        dormant_candidate_magic,
        dormant_candidate_header,
        14,
    ) catch return error.DormantCandidateMalformed;
    defer candidate.deinit(config.allocator);
    const c = candidate.fields;
    validateRelativeKey(c[3]) catch return error.DormantCandidateUnsafe;
    validateRelativeKey(c[7]) catch return error.DormantCandidateUnsafe;
    validateRelativeKey(c[9]) catch return error.DormantCandidateUnsafe;
    validateSha(c[4]) catch return error.DormantCandidateMalformed;
    validateSha(c[8]) catch return error.DormantCandidateMalformed;
    validateSha(c[10]) catch return error.DormantCandidateMalformed;
    validateSha(c[12]) catch return error.DormantCandidateMalformed;
    const declared_manifest_bytes = std.fmt.parseInt(u64, c[5], 10) catch
        return error.DormantCandidateMalformed;
    const declared_manifest_mode = std.fmt.parseInt(u16, c[6], 8) catch
        return error.DormantCandidateMalformed;
    if (!std.mem.eql(u8, c[0], "zllvm-local-state-v1") or
        !std.mem.eql(u8, c[1], "00000001") or
        !std.mem.eql(u8, c[2], config.payload_root) or
        !std.mem.eql(u8, c[3], dormant_generation_key) or
        declared_manifest_mode != 0o644 or
        !std.mem.eql(u8, c[7], dormant_lineage_key) or
        !std.mem.eql(u8, c[9], dormant_receipt_key) or
        !std.mem.eql(u8, c[11], config.source_root) or
        !std.mem.eql(u8, c[12], &config.source_manifest_sha256) or
        !std.mem.eql(u8, c[13], "candidate"))
    {
        return error.DormantCandidateMismatched;
    }

    const generation_bytes = try readDormantControlFile(
        config,
        .generation,
        dormant_generation_key,
    );
    defer config.allocator.free(generation_bytes);
    if (!std.mem.eql(u8, &sha256Hex(generation_bytes), c[4]) or
        generation_bytes.len != declared_manifest_bytes)
    {
        return error.DormantGenerationMismatched;
    }
    var manifest = parseManifest(config.allocator, generation_bytes) catch
        return error.DormantGenerationMalformed;
    defer manifest.deinit(config.allocator);
    const reencoded_manifest = encodeManifest(config.allocator, manifest) catch
        return error.DormantGenerationMalformed;
    defer config.allocator.free(reencoded_manifest);
    if (!std.mem.eql(u8, reencoded_manifest, generation_bytes)) {
        return error.DormantGenerationMalformed;
    }

    const lineage_bytes = try readDormantControlFile(
        config,
        .lineage,
        dormant_lineage_key,
    );
    defer config.allocator.free(lineage_bytes);
    if (!std.mem.eql(u8, &sha256Hex(lineage_bytes), c[8])) {
        return error.DormantLineageMismatched;
    }
    var lineage = parseDormantOwnedRow(
        config.allocator,
        lineage_bytes,
        dormant_lineage_magic,
        dormant_lineage_header,
        7,
    ) catch return error.DormantLineageMalformed;
    defer lineage.deinit(config.allocator);
    const l = lineage.fields;
    validateSha(l[3]) catch return error.DormantLineageMalformed;
    validateSha(l[5]) catch return error.DormantLineageMalformed;
    if (!std.mem.eql(u8, l[0], "00000001") or
        !std.mem.eql(u8, l[1], "-") or
        !std.mem.eql(u8, l[2], "-") or
        !std.mem.eql(u8, l[3], c[4]) or
        !std.mem.eql(u8, l[4], config.source_root) or
        !std.mem.eql(u8, l[5], &config.source_manifest_sha256) or
        !std.mem.eql(u8, l[6], "non_destructive_verified_copy"))
    {
        return error.DormantLineageMismatched;
    }

    const receipt_bytes = try readDormantControlFile(
        config,
        .receipt,
        dormant_receipt_key,
    );
    defer config.allocator.free(receipt_bytes);
    if (!std.mem.eql(u8, &sha256Hex(receipt_bytes), c[10])) {
        return error.DormantReceiptMismatched;
    }
    var receipt = parseDormantOwnedRow(
        config.allocator,
        receipt_bytes,
        dormant_receipt_magic,
        dormant_receipt_header,
        15,
    ) catch return error.DormantReceiptMalformed;
    defer receipt.deinit(config.allocator);
    const r = receipt.fields;
    validateSha(r[4]) catch return error.DormantReceiptMalformed;
    validateSha(r[5]) catch return error.DormantReceiptMalformed;
    validateSha(r[6]) catch return error.DormantReceiptMalformed;
    validateRelativeKey(r[12]) catch return error.DormantReceiptUnsafe;
    validateSha(r[13]) catch return error.DormantReceiptMalformed;
    const receipt_files = std.fmt.parseInt(u64, r[7], 10) catch
        return error.DormantReceiptMalformed;
    const receipt_bytes_count = std.fmt.parseInt(u64, r[8], 10) catch
        return error.DormantReceiptMalformed;
    const receipt_objects = std.fmt.parseInt(u64, r[9], 10) catch
        return error.DormantReceiptMalformed;
    const receipt_snapshots = std.fmt.parseInt(u64, r[10], 10) catch
        return error.DormantReceiptMalformed;
    if (!std.mem.eql(u8, r[0], "zllvm-generation-00000001-payload-copy") or
        !std.mem.eql(u8, r[1], "00000001") or
        !std.mem.eql(u8, r[2], config.source_root) or
        !std.mem.eql(u8, r[3], config.payload_root) or
        !std.mem.eql(u8, r[4], &config.expected_source_inventory_sha256) or
        !std.mem.eql(u8, r[5], &config.expected_source_file_ledger_sha256) or
        !std.mem.eql(u8, r[6], &config.expected_source_destination_ledger_sha256) or
        !std.mem.eql(u8, r[11], "0444") or
        !std.mem.eql(u8, r[12], config.expected_copy_evidence_path) or
        !std.mem.eql(u8, r[13], &config.expected_copy_evidence_sha256) or
        !std.mem.eql(u8, r[14], "verified_non_authoritative_copy"))
    {
        return error.DormantReceiptMismatched;
    }

    var validation = try verifyDormantDestination(config, manifest);
    if (validation.payload_files != receipt_files or
        validation.payload_bytes != receipt_bytes_count or
        validation.objects != receipt_objects or
        validation.snapshots != receipt_snapshots)
    {
        return error.DormantReceiptMismatched;
    }
    validation.manifest_sha256 = sha256Hex(generation_bytes);
    try config.validateRegistration();
    return validation;
}

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

fn validateAuthorityAncestry(
    allocator: std.mem.Allocator,
    io: std.Io,
    root_path: []const u8,
) !bool {
    if (!std.fs.path.isAbsolute(root_path)) return error.PathNotAbsolute;
    const normalized = try normalizedAbsolute(allocator, root_path);
    defer allocator.free(normalized);
    if (!std.mem.eql(u8, normalized, root_path)) return error.PathNotNormalized;

    var components = std.fs.path.componentIterator(root_path);
    while (components.next()) |component| {
        var directory = std.Io.Dir.openDirAbsolute(io, component.path, .{
            .iterate = true,
            .follow_symlinks = false,
        }) catch |err| switch (err) {
            error.FileNotFound => return false,
            error.SymLinkLoop => return error.AuthoritySymlinkComponent,
            error.NotDir => return error.AuthorityNonDirectoryComponent,
            else => return err,
        };
        directory.close(io);
    }
    return true;
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

fn sortedObjectGroup(
    allocator: std.mem.Allocator,
    objects: []const FileIdentity,
) ![]FileIdentity {
    if (objects.len == 0 or objects.len > max_snapshot_members) {
        return error.InvalidSnapshotMemberCount;
    }
    const sorted = try allocator.dupe(FileIdentity, objects);
    errdefer allocator.free(sorted);
    std.mem.sort(FileIdentity, sorted, {}, struct {
        fn lessThan(_: void, a: FileIdentity, b: FileIdentity) bool {
            return std.mem.order(u8, a.key, b.key) == .lt;
        }
    }.lessThan);
    for (sorted, 0..) |object, index| {
        const split = splitObjectKey(object.key) orelse return error.InvalidObjectKey;
        if (!std.mem.eql(u8, split.prefix, object.sha256[0..2]) or
            !std.mem.eql(u8, split.basename, object.sha256[2..]))
        {
            return error.ObjectKeyShaMismatch;
        }
        if (index != 0 and std.mem.eql(u8, sorted[index - 1].key, object.key)) {
            return error.DuplicateSnapshotMember;
        }
    }
    return sorted;
}

fn encodeConstituentManifest(
    allocator: std.mem.Allocator,
    sorted: []const FileIdentity,
) ![]u8 {
    var output: std.ArrayList(u8) = .empty;
    errdefer output.deinit(allocator);
    try output.appendSlice(allocator, "zllvm-snapshot-constituents-v1\n");
    try output.appendSlice(allocator, "key\tsha256\tbytes\tmode\n");
    for (sorted) |object| {
        try output.print(
            allocator,
            "{s}\t{s}\t{}\t{o}\n",
            .{ object.key, object.sha256, object.bytes, object.mode },
        );
    }
    return output.toOwnedSlice(allocator);
}

fn encodeMemberList(
    allocator: std.mem.Allocator,
    sorted: []const FileIdentity,
) ![]u8 {
    var output: std.ArrayList(u8) = .empty;
    errdefer output.deinit(allocator);
    for (sorted) |object| {
        try output.appendSlice(allocator, object.key);
        try output.append(allocator, 0);
    }
    return output.toOwnedSlice(allocator);
}

fn objectKey(allocator: std.mem.Allocator, sha: []const u8) ![]u8 {
    try validateSha(sha);
    return std.fmt.allocPrint(allocator, "objects/sha256/{s}/{s}", .{ sha[0..2], sha[2..] });
}

fn snapshotKey(allocator: std.mem.Allocator, sha: []const u8) ![]u8 {
    try validateSha(sha);
    return std.fmt.allocPrint(allocator, "snapshots/sha256/{s}/{s}.tar.zst", .{ sha[0..2], sha[2..] });
}

fn openOrCreateDir(io: std.Io, parent: std.Io.Dir, name: []const u8) !std.Io.Dir {
    if (std.mem.indexOfScalar(u8, name, '/') != null or
        std.mem.eql(u8, name, ".") or std.mem.eql(u8, name, ".."))
    {
        return error.UnsafePathComponent;
    }
    const created = created: {
        parent.createDir(io, name, .default_dir) catch |err| switch (err) {
            error.PathAlreadyExists => break :created false,
            else => return err,
        };
        break :created true;
    };
    if (parent.openDir(io, name, .{
        .access_sub_paths = true,
        .iterate = true,
        .follow_symlinks = false,
    })) |dir| {
        if (created) {
            try syncDirectory(dir);
            try syncDirectory(parent);
        }
        return dir;
    } else |err| return err;
}

fn openExistingDir(io: std.Io, parent: std.Io.Dir, name: []const u8) !std.Io.Dir {
    if (std.mem.indexOfScalar(u8, name, '/') != null) return error.UnsafePathComponent;
    return parent.openDir(io, name, .{
        .access_sub_paths = true,
        .iterate = true,
        .follow_symlinks = false,
    });
}

fn openPathNoFollow(io: std.Io, start: std.Io.Dir, relative: []const u8, create: bool) !std.Io.Dir {
    if (std.mem.eql(u8, relative, ".")) {
        return start.openDir(io, ".", .{
            .access_sub_paths = true,
            .iterate = true,
            .follow_symlinks = false,
        });
    }
    try validateRelativeKey(relative);
    var current = start;
    var current_owned = false;
    errdefer if (current_owned) current.close(io);
    var segments = std.mem.splitScalar(u8, relative, '/');
    while (segments.next()) |segment| {
        const next = if (create)
            try openOrCreateDir(io, current, segment)
        else
            try openExistingDir(io, current, segment);
        if (current_owned) current.close(io);
        current = next;
        current_owned = true;
    }
    return current;
}

fn writeCollisionFixtureAtomic(
    io: std.Io,
    dir: std.Io.Dir,
    basename: []const u8,
    bytes: []const u8,
    mode: u16,
) !void {
    if (!builtin.is_test) return error.TestOnlyOperation;
    if (std.mem.indexOfScalar(u8, basename, '/') != null) return error.UnsafePathComponent;
    var atomic = try dir.createFileAtomic(io, basename, .{
        .permissions = .fromMode(0o600),
        .replace = false,
    });
    defer atomic.deinit(io);
    try atomic.file.writeStreamingAll(io, bytes);
    try atomic.file.sync(io);
    try atomic.file.setPermissions(io, .fromMode(mode));
    try atomic.file.sync(io);
    try atomic.link(io);
    try syncDirectory(dir);
}

const PublishFault = enum {
    none,
    corrupt_incoming,
    corrupt_final,
};

fn publishVerifiedBytes(
    allocator: std.mem.Allocator,
    io: std.Io,
    dir: std.Io.Dir,
    basename: []const u8,
    bytes: []const u8,
    expected: FileIdentity,
    fault: PublishFault,
) !bool {
    var atomic = try dir.createFileAtomic(io, basename, .{
        .permissions = .fromMode(0o600),
        .replace = false,
    });
    defer atomic.deinit(io);
    try atomic.file.writeStreamingAll(io, bytes);
    return finishVerifiedAtomic(allocator, io, dir, basename, &atomic, expected, fault);
}

fn publishVerifiedFile(
    allocator: std.mem.Allocator,
    io: std.Io,
    dir: std.Io.Dir,
    basename: []const u8,
    source: std.Io.File,
    expected: FileIdentity,
    fault: PublishFault,
) !bool {
    var atomic = try dir.createFileAtomic(io, basename, .{
        .permissions = .fromMode(0o600),
        .replace = false,
    });
    defer atomic.deinit(io);
    try copyFileContents(io, source, atomic.file);
    return finishVerifiedAtomic(allocator, io, dir, basename, &atomic, expected, fault);
}

fn finishVerifiedAtomic(
    allocator: std.mem.Allocator,
    io: std.Io,
    dir: std.Io.Dir,
    basename: []const u8,
    atomic: *std.Io.File.Atomic,
    expected: FileIdentity,
    fault: PublishFault,
) !bool {
    try atomic.file.sync(io);
    if (fault == .corrupt_incoming) {
        try atomic.file.writePositionalAll(io, "!", 0);
        try atomic.file.sync(io);
    }
    try atomic.file.setPermissions(io, .fromMode(expected.mode));
    try atomic.file.sync(io);
    var incoming = try identityOfOpenFile(allocator, io, atomic.file, expected.mode);
    defer incoming.deinit(allocator);
    if (!sameFileIdentity(incoming, expected)) return error.PrepublicationVerificationFailed;

    var created = true;
    atomic.link(io) catch |err| switch (err) {
        error.PathAlreadyExists => created = false,
        else => return err,
    };
    try syncDirectory(dir);

    if (created and fault == .corrupt_final) {
        try dir.setFilePermissions(
            io,
            basename,
            .fromMode(0o600),
            .{ .follow_symlinks = false },
        );
        var final_for_fault = try dir.openFile(io, basename, .{
            .mode = .read_write,
            .allow_directory = false,
            .follow_symlinks = false,
        });
        defer final_for_fault.close(io);
        try final_for_fault.writePositionalAll(io, "!", 0);
        try final_for_fault.sync(io);
        try final_for_fault.setPermissions(io, .fromMode(expected.mode));
        try final_for_fault.sync(io);
    }

    const verified = verifyRelativeFile(allocator, io, dir, basename, expected.mode) catch |err| {
        if (created) {
            dir.deleteFile(io, basename) catch {};
            syncDirectory(dir) catch {};
        }
        return err;
    };
    defer {
        var mutable = verified;
        mutable.deinit(allocator);
    }
    if (!sameFileIdentity(verified, expected)) {
        if (created) {
            try dir.deleteFile(io, basename);
            try syncDirectory(dir);
        }
        return if (created)
            error.PostPublicationReadBackMismatch
        else
            error.UnequalExistingCollision;
    }
    try syncDirectory(dir);
    return created;
}

fn writeExclusive(
    io: std.Io,
    dir: std.Io.Dir,
    basename: []const u8,
    bytes: []const u8,
    mode: u16,
) !void {
    var file = try dir.createFile(io, basename, .{
        .exclusive = true,
        .permissions = .fromMode(0o600),
    });
    defer file.close(io);
    try file.writeStreamingAll(io, bytes);
    try file.sync(io);
    try file.setPermissions(io, .fromMode(mode));
    try file.sync(io);
    try syncDirectory(dir);
}

threadlocal var test_directory_sync_count: usize = 0;

fn syncDirectory(dir: std.Io.Dir) !void {
    switch (std.os.linux.errno(std.os.linux.fsync(dir.handle))) {
        .SUCCESS => {},
        else => |err| return std.posix.unexpectedErrno(err),
    }
    if (builtin.is_test) test_directory_sync_count += 1;
}

fn expectSnapshotProofDirectoryEmpty(store: *Store) !void {
    if (!builtin.is_test) return error.TestOnlyOperation;
    var proof_root = try openExistingDir(store.io, store.root, "snapshot-proof");
    defer proof_root.close(store.io);
    var entries = proof_root.iterate();
    if (try entries.next(store.io) != null) return error.SnapshotProofWorkspaceRetained;
}

fn testOnlySnapshotProofEarlyUnwind(store: *Store) !void {
    if (!builtin.is_test) return error.TestOnlyOperation;
    var proof = try SnapshotProofWorkspace.init(store.io, store.root);
    defer proof.deinitAfterError();
    return error.TestSnapshotProofEarlyFailure;
}

fn cleanToolEnvironment(allocator: std.mem.Allocator) std.process.Environ.Map {
    var environment = std.process.Environ.Map.init(allocator);
    environment.put("PATH", "/usr/bin:/bin") catch @panic("out of memory");
    environment.put("LC_ALL", "C") catch @panic("out of memory");
    environment.put("TZ", "UTC") catch @panic("out of memory");
    environment.put("SOURCE_DATE_EPOCH", "0") catch @panic("out of memory");
    return environment;
}

fn verifyToolchain(allocator: std.mem.Allocator, io: std.Io) !void {
    const checks = [_]struct {
        argv: []const []const u8,
        needle: []const u8,
        sha256: []const u8,
    }{
        .{
            .argv = &.{ "/usr/bin/tar", "--version" },
            .needle = "tar (GNU tar) 1.35",
            .sha256 = "1effa935ebc606b859e3ab8ae0a3878be466c9b3690b665f6378479dd08571e9",
        },
        .{
            .argv = &.{ "/usr/bin/zstd", "--version" },
            .needle = "v1.5.5",
            .sha256 = "7c5468b370f7c47eda07281e3437fafc568f95d10420051e3aa522709f9342c5",
        },
        .{
            .argv = &.{ "/usr/bin/sha256sum", "--version" },
            .needle = "GNU coreutils) 9.4",
            .sha256 = "9992e1f1feb6f0f396bc8d6691ebc1adbfc269fd628bce84eda1d4ba5c3995c7",
        },
        .{
            .argv = &.{ "/usr/bin/install", "--version" },
            .needle = "GNU coreutils) 9.4",
            .sha256 = "0e328ae109217200da3207ece12514b867d44fb90b444958b4d64b6007736f33",
        },
    };
    var environment = cleanToolEnvironment(allocator);
    defer environment.deinit();
    for (checks) |check| {
        var executable = try std.Io.Dir.openFileAbsolute(io, check.argv[0], .{
            .allow_directory = false,
            .follow_symlinks = false,
        });
        defer executable.close(io);
        var executable_identity = try identityOfOpenFileAnyMode(allocator, io, executable);
        defer executable_identity.deinit(allocator);
        if (!std.mem.eql(u8, &executable_identity.sha256, check.sha256)) {
            return error.ToolchainIdentityMismatch;
        }
        const result = try std.process.run(allocator, io, .{
            .argv = check.argv,
            .environ_map = &environment,
            .stdout_limit = .limited(64 * 1024),
            .stderr_limit = .limited(64 * 1024),
        });
        defer freeRunResult(allocator, result);
        if (!termSuccess(result.term) or std.mem.indexOf(u8, result.stdout, check.needle) == null) {
            return error.ToolchainIdentityMismatch;
        }
    }
}

fn runCleanCapture(
    allocator: std.mem.Allocator,
    io: std.Io,
    argv: []const []const u8,
    cwd: std.Io.Dir,
    environment: *const std.process.Environ.Map,
) !std.process.RunResult {
    const result = try std.process.run(allocator, io, .{
        .argv = argv,
        .cwd = .{ .dir = cwd },
        .environ_map = environment,
        .stdout_limit = .limited(16 * 1024 * 1024),
        .stderr_limit = .limited(16 * 1024 * 1024),
    });
    if (!termSuccess(result.term)) {
        freeRunResult(allocator, result);
        return error.ExternalToolFailed;
    }
    return result;
}

fn validateSnapshotListing(
    allocator: std.mem.Allocator,
    listing: []const u8,
    objects: []const FileIdentity,
) !void {
    _ = allocator;
    if (!std.mem.endsWith(u8, listing, "\n")) return error.UnsafeOrUnexpectedSnapshotMember;
    var lines = std.mem.splitScalar(u8, listing, '\n');
    for (objects) |object| {
        try validateRelativeKey(object.key);
        const line = lines.next() orelse return error.UnsafeOrUnexpectedSnapshotMember;
        const final_space = std.mem.lastIndexOfScalar(u8, line, ' ') orelse
            return error.UnsafeOrUnexpectedSnapshotMember;
        if (!std.mem.startsWith(u8, line, "-r--r--r--") or
            !std.mem.eql(u8, line[final_space + 1 ..], object.key))
        {
            return error.UnsafeOrUnexpectedSnapshotMember;
        }
    }
    if (!std.mem.eql(u8, lines.next() orelse return error.UnsafeOrUnexpectedSnapshotMember, "") or
        lines.next() != null)
    {
        return error.UnsafeOrUnexpectedSnapshotMember;
    }
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

const dormant_test_root = "/tmp/zllvm-inbox205b-authority-dormant-synthetic";
const dormant_test_source_inventory_sha256 =
    "1111111111111111111111111111111111111111111111111111111111111111";
const dormant_test_source_file_ledger_sha256 =
    "2222222222222222222222222222222222222222222222222222222222222222";
const dormant_test_source_destination_ledger_sha256 =
    "3333333333333333333333333333333333333333333333333333333333333333";
const dormant_test_copy_evidence_path = "docs/evidence/synthetic-copy-proof.md";
const dormant_test_copy_evidence_sha256 =
    "4444444444444444444444444444444444444444444444444444444444444444";

const DormantSyntheticFixture = struct {
    allocator: std.mem.Allocator,
    io: std.Io,
    root: []u8,
    main_root: []u8,
    control_root: []u8,
    payload_root: []u8,
    source_root: []u8,
    non_main_root: []u8,
    manifest: []u8,
    candidate: []u8,
    lineage: []u8,
    receipt: []u8,
    payload: []const u8,
    constituent: []const u8,
    snapshot: []const u8,
    payload_key: []u8,
    constituent_key: []u8,
    snapshot_key: []u8,
    source_manifest_sha256: [64]u8,

    fn init(allocator: std.mem.Allocator, io: std.Io) !DormantSyntheticFixture {
        if (!builtin.is_test) return error.TestOnlyOperation;
        if (std.Io.Dir.openDirAbsolute(io, dormant_test_root, .{
            .follow_symlinks = false,
        })) |existing| {
            existing.close(io);
            return error.DormantSyntheticRootPreexisted;
        } else |err| switch (err) {
            error.FileNotFound => {},
            else => return err,
        }
        try createAbsoluteDirectorySynced(io, dormant_test_root);
        errdefer std.debug.print(
            "INBOX-205A retain-on-failure synthetic_root={s}\n",
            .{dormant_test_root},
        );
        const root = try allocator.dupe(u8, dormant_test_root);
        errdefer allocator.free(root);
        const main_root = try std.fs.path.join(allocator, &.{ root, "main" });
        errdefer allocator.free(main_root);
        const control_root = try std.fs.path.join(allocator, &.{ main_root, "control" });
        errdefer allocator.free(control_root);
        const artifacts_root = try std.fs.path.join(allocator, &.{ main_root, "artifacts" });
        defer allocator.free(artifacts_root);
        const payload_root = try std.fs.path.join(
            allocator,
            &.{ artifacts_root, "zllvm-authority-v1" },
        );
        errdefer allocator.free(payload_root);
        const source_root = try std.fs.path.join(allocator, &.{ root, "external-source" });
        errdefer allocator.free(source_root);
        const non_main_root = try std.fs.path.join(
            allocator,
            &.{ root, "non-main-registration" },
        );
        errdefer allocator.free(non_main_root);
        try createAbsoluteDirectorySynced(io, main_root);
        try createAbsoluteDirectorySynced(io, control_root);
        try createAbsoluteDirectorySynced(io, artifacts_root);
        try createAbsoluteDirectorySynced(io, payload_root);
        try createAbsoluteDirectorySynced(io, source_root);
        try createAbsoluteDirectorySynced(io, non_main_root);
        try setDormantAbsoluteDirectoryMode(io, root, 0o755);
        try setDormantAbsoluteDirectoryMode(io, main_root, 0o755);
        try setDormantAbsoluteDirectoryMode(io, control_root, 0o775);
        try setDormantAbsoluteDirectoryMode(io, artifacts_root, 0o755);
        try setDormantAbsoluteDirectoryMode(io, payload_root, 0o755);
        try setDormantAbsoluteDirectoryMode(io, source_root, 0o775);
        try setDormantAbsoluteDirectoryMode(io, non_main_root, 0o755);

        var control = try std.Io.Dir.openDirAbsolute(io, control_root, .{
            .access_sub_paths = true,
            .iterate = true,
            .follow_symlinks = false,
        });
        defer control.close(io);
        const control_dirs = [_][]const u8{
            "authority/zllvm/v1/manifests",
            "authority/zllvm/v1/lineage",
            "authority/zllvm/v1/receipts/publication",
        };
        for (control_dirs) |path| {
            var created = try openPathNoFollow(io, control, path, true);
            created.close(io);
            try setDormantRelativeDirectoryModes(io, control, path, 0o755);
        }

        var payload_dir = try std.Io.Dir.openDirAbsolute(io, payload_root, .{
            .access_sub_paths = true,
            .iterate = true,
            .follow_symlinks = false,
        });
        defer payload_dir.close(io);
        const payload_dirs = [_][]const u8{
            "incoming",
            "objects/sha256",
            "snapshots/sha256",
        };
        for (payload_dirs) |path| {
            var created = try openPathNoFollow(io, payload_dir, path, true);
            created.close(io);
            try setDormantRelativeDirectoryModes(io, payload_dir, path, 0o755);
        }

        const payload = "synthetic dormant authority payload\n";
        const constituent = "synthetic dormant constituent\n";
        const snapshot = "synthetic dormant snapshot archive\n";
        const payload_sha = sha256Hex(payload);
        const constituent_sha = sha256Hex(constituent);
        const snapshot_sha = sha256Hex(snapshot);
        const payload_key = try objectKey(allocator, &payload_sha);
        errdefer allocator.free(payload_key);
        const constituent_key = try objectKey(allocator, &constituent_sha);
        errdefer allocator.free(constituent_key);
        const owned_snapshot_key = try snapshotKey(allocator, &snapshot_sha);
        errdefer allocator.free(owned_snapshot_key);

        try writeDormantFixtureRelative(io, payload_dir, payload_key, payload, 0o444);
        try writeDormantFixtureRelative(
            io,
            payload_dir,
            constituent_key,
            constituent,
            0o444,
        );
        try writeDormantFixtureRelative(
            io,
            payload_dir,
            owned_snapshot_key,
            snapshot,
            0o444,
        );
        try setDormantRelativeDirectoryModes(
            io,
            payload_dir,
            std.fs.path.dirname(payload_key).?,
            0o755,
        );
        try setDormantRelativeDirectoryModes(
            io,
            payload_dir,
            std.fs.path.dirname(constituent_key).?,
            0o755,
        );
        try setDormantRelativeDirectoryModes(
            io,
            payload_dir,
            std.fs.path.dirname(owned_snapshot_key).?,
            0o755,
        );

        const manifest = try std.fmt.allocPrint(
            allocator,
            schema_magic ++ "\n" ++ schema_header ++ "\n" ++
                "object\tobject.synthetic.payload\t{s}\t{}\t444\tapplication/octet-stream\tsynthetic\tunavailable\tcanonical-input\tactive\t{s}\t-\t-\t-\t-\t-\t-\n" ++
                "object\tobject.synthetic.constituent\t{s}\t{}\t444\ttext/tab-separated-values\tsynthetic\tunavailable\treproducible-cache\tactive\t{s}\t-\t-\t-\t-\t-\t-\n" ++
                "snapshot\tsnapshot.synthetic\t{s}\t{}\t444\tapplication/zstd+tar\tsynthetic\tunavailable\tirreplaceable-acceptance-evidence\tactive\t{s}\t-\t-\t-\t{s}\t{s}\t{s}\n" ++
                "snapshot-member\tsnapshot.synthetic.member.payload\t{s}\t{}\t444\tapplication/octet-stream\tsynthetic\tunavailable\tcanonical-input\tactive\t{s}\tobject.synthetic.payload\tsnapshot.synthetic\t{s}\t-\t-\t-\n",
            .{
                payload_sha,
                payload.len,
                payload_key,
                constituent_sha,
                constituent.len,
                constituent_key,
                snapshot_sha,
                snapshot.len,
                owned_snapshot_key,
                snapshot_format,
                snapshot_recipe_sha,
                constituent_sha,
                payload_sha,
                payload.len,
                payload_key,
                payload_key,
            },
        );
        errdefer allocator.free(manifest);
        var parsed_manifest = try parseManifest(allocator, manifest);
        parsed_manifest.deinit(allocator);
        const manifest_sha = sha256Hex(manifest);
        const source_manifest_sha256 =
            "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa".*;

        const lineage = try std.fmt.allocPrint(
            allocator,
            dormant_lineage_magic ++ "\n" ++ dormant_lineage_header ++ "\n" ++
                "00000001\t-\t-\t{s}\t{s}\t{s}\tnon_destructive_verified_copy\n",
            .{ manifest_sha, source_root, source_manifest_sha256 },
        );
        errdefer allocator.free(lineage);
        const lineage_sha = sha256Hex(lineage);
        const receipt = try std.fmt.allocPrint(
            allocator,
            dormant_receipt_magic ++ "\n" ++ dormant_receipt_header ++ "\n" ++
                "zllvm-generation-00000001-payload-copy\t00000001\t{s}\t{s}\t{s}\t{s}\t{s}\t3\t{}\t2\t1\t0444\t{s}\t{s}\tverified_non_authoritative_copy\n",
            .{
                source_root,
                payload_root,
                dormant_test_source_inventory_sha256,
                dormant_test_source_file_ledger_sha256,
                dormant_test_source_destination_ledger_sha256,
                payload.len + constituent.len + snapshot.len,
                dormant_test_copy_evidence_path,
                dormant_test_copy_evidence_sha256,
            },
        );
        errdefer allocator.free(receipt);
        const receipt_sha = sha256Hex(receipt);
        const candidate = try std.fmt.allocPrint(
            allocator,
            dormant_candidate_magic ++ "\n" ++ dormant_candidate_header ++ "\n" ++
                "zllvm-local-state-v1\t00000001\t{s}\t{s}\t{s}\t{}\t0644\t{s}\t{s}\t{s}\t{s}\t{s}\t{s}\tcandidate\n",
            .{
                payload_root,
                dormant_generation_key,
                manifest_sha,
                manifest.len,
                dormant_lineage_key,
                lineage_sha,
                dormant_receipt_key,
                receipt_sha,
                source_root,
                source_manifest_sha256,
            },
        );
        errdefer allocator.free(candidate);
        try writeDormantFixtureRelative(
            io,
            control,
            dormant_generation_key,
            manifest,
            0o644,
        );
        try writeDormantFixtureRelative(
            io,
            control,
            dormant_lineage_key,
            lineage,
            0o644,
        );
        try writeDormantFixtureRelative(
            io,
            control,
            dormant_receipt_key,
            receipt,
            0o644,
        );
        try writeDormantFixtureRelative(
            io,
            control,
            dormant_candidate_key,
            candidate,
            0o644,
        );
        return .{
            .allocator = allocator,
            .io = io,
            .root = root,
            .main_root = main_root,
            .control_root = control_root,
            .payload_root = payload_root,
            .source_root = source_root,
            .non_main_root = non_main_root,
            .manifest = manifest,
            .candidate = candidate,
            .lineage = lineage,
            .receipt = receipt,
            .payload = payload,
            .constituent = constituent,
            .snapshot = snapshot,
            .payload_key = payload_key,
            .constituent_key = constituent_key,
            .snapshot_key = owned_snapshot_key,
            .source_manifest_sha256 = source_manifest_sha256,
        };
    }

    fn deinitAfterSuccess(fixture: *DormantSyntheticFixture) !void {
        try removeAbsoluteDirectorySynced(fixture.io, fixture.root);
        fixture.allocator.free(fixture.snapshot_key);
        fixture.allocator.free(fixture.constituent_key);
        fixture.allocator.free(fixture.payload_key);
        fixture.allocator.free(fixture.receipt);
        fixture.allocator.free(fixture.lineage);
        fixture.allocator.free(fixture.candidate);
        fixture.allocator.free(fixture.manifest);
        fixture.allocator.free(fixture.non_main_root);
        fixture.allocator.free(fixture.source_root);
        fixture.allocator.free(fixture.payload_root);
        fixture.allocator.free(fixture.control_root);
        fixture.allocator.free(fixture.main_root);
        fixture.allocator.free(fixture.root);
        fixture.* = undefined;
    }

    fn replaceControl(
        fixture: *DormantSyntheticFixture,
        relative_path: []const u8,
        bytes: []const u8,
    ) !void {
        var control = try std.Io.Dir.openDirAbsolute(fixture.io, fixture.control_root, .{
            .access_sub_paths = true,
            .iterate = true,
            .follow_symlinks = false,
        });
        defer control.close(fixture.io);
        try replaceDormantFixtureRelative(
            fixture.io,
            control,
            relative_path,
            bytes,
            0o644,
        );
    }

    fn deleteControl(
        fixture: *DormantSyntheticFixture,
        relative_path: []const u8,
    ) !void {
        var control = try std.Io.Dir.openDirAbsolute(fixture.io, fixture.control_root, .{
            .access_sub_paths = true,
            .iterate = true,
            .follow_symlinks = false,
        });
        defer control.close(fixture.io);
        try deleteDormantFixtureRelative(fixture.io, control, relative_path);
    }

    fn replacePayload(
        fixture: *DormantSyntheticFixture,
        relative_path: []const u8,
        bytes: []const u8,
    ) !void {
        var payload_dir = try std.Io.Dir.openDirAbsolute(fixture.io, fixture.payload_root, .{
            .access_sub_paths = true,
            .iterate = true,
            .follow_symlinks = false,
        });
        defer payload_dir.close(fixture.io);
        try replaceDormantFixtureRelative(
            fixture.io,
            payload_dir,
            relative_path,
            bytes,
            0o444,
        );
    }

    fn deletePayload(
        fixture: *DormantSyntheticFixture,
        relative_path: []const u8,
    ) !void {
        var payload_dir = try std.Io.Dir.openDirAbsolute(fixture.io, fixture.payload_root, .{
            .access_sub_paths = true,
            .iterate = true,
            .follow_symlinks = false,
        });
        defer payload_dir.close(fixture.io);
        try deleteDormantFixtureRelative(fixture.io, payload_dir, relative_path);
    }

    fn candidateFor(
        fixture: *const DormantSyntheticFixture,
        allocator: std.mem.Allocator,
        generation: []const u8,
        lineage: []const u8,
        receipt: []const u8,
        state: []const u8,
    ) ![]u8 {
        const generation_sha = sha256Hex(generation);
        const lineage_sha = sha256Hex(lineage);
        const receipt_sha = sha256Hex(receipt);
        return std.fmt.allocPrint(
            allocator,
            dormant_candidate_magic ++ "\n" ++ dormant_candidate_header ++ "\n" ++
                "zllvm-local-state-v1\t00000001\t{s}\t{s}\t{s}\t{}\t0644\t{s}\t{s}\t{s}\t{s}\t{s}\t{s}\t{s}\n",
            .{
                fixture.payload_root,
                dormant_generation_key,
                generation_sha,
                generation.len,
                dormant_lineage_key,
                lineage_sha,
                dormant_receipt_key,
                receipt_sha,
                fixture.source_root,
                fixture.source_manifest_sha256,
                state,
            },
        );
    }

    fn receiptFor(
        fixture: *const DormantSyntheticFixture,
        allocator: std.mem.Allocator,
        source_inventory_sha256: []const u8,
        source_file_ledger_sha256: []const u8,
        source_destination_ledger_sha256: []const u8,
        copy_evidence_path: []const u8,
        copy_evidence_sha256: []const u8,
    ) ![]u8 {
        return std.fmt.allocPrint(
            allocator,
            dormant_receipt_magic ++ "\n" ++ dormant_receipt_header ++ "\n" ++
                "zllvm-generation-00000001-payload-copy\t00000001\t{s}\t{s}\t{s}\t{s}\t{s}\t3\t{}\t2\t1\t0444\t{s}\t{s}\tverified_non_authoritative_copy\n",
            .{
                fixture.source_root,
                fixture.payload_root,
                source_inventory_sha256,
                source_file_ledger_sha256,
                source_destination_ledger_sha256,
                fixture.payload.len + fixture.constituent.len + fixture.snapshot.len,
                copy_evidence_path,
                copy_evidence_sha256,
            },
        );
    }

    fn symlinkControl(
        fixture: *DormantSyntheticFixture,
        relative_path: []const u8,
        target: []const u8,
    ) !void {
        var control = try std.Io.Dir.openDirAbsolute(fixture.io, fixture.control_root, .{
            .access_sub_paths = true,
            .iterate = true,
            .follow_symlinks = false,
        });
        defer control.close(fixture.io);
        const parent_path = std.fs.path.dirname(relative_path) orelse ".";
        const basename = std.fs.path.basename(relative_path);
        var parent = try openPathNoFollow(fixture.io, control, parent_path, false);
        defer parent.close(fixture.io);
        try parent.symLink(fixture.io, target, basename, .{});
    }

    fn symlinkPayload(
        fixture: *DormantSyntheticFixture,
        relative_path: []const u8,
        target: []const u8,
    ) !void {
        var payload_dir = try std.Io.Dir.openDirAbsolute(fixture.io, fixture.payload_root, .{
            .access_sub_paths = true,
            .iterate = true,
            .follow_symlinks = false,
        });
        defer payload_dir.close(fixture.io);
        const parent_path = std.fs.path.dirname(relative_path) orelse ".";
        const basename = std.fs.path.basename(relative_path);
        var parent = try openPathNoFollow(fixture.io, payload_dir, parent_path, false);
        defer parent.close(fixture.io);
        try parent.symLink(fixture.io, target, basename, .{});
    }
};

fn writeDormantFixtureRelative(
    io: std.Io,
    root: std.Io.Dir,
    relative_path: []const u8,
    bytes: []const u8,
    mode: u16,
) !void {
    const parent_path = std.fs.path.dirname(relative_path) orelse ".";
    const basename = std.fs.path.basename(relative_path);
    var parent = try openPathNoFollow(io, root, parent_path, true);
    defer parent.close(io);
    try writeExclusive(io, parent, basename, bytes, mode);
}

fn setDormantAbsoluteDirectoryMode(io: std.Io, path: []const u8, mode: u16) !void {
    var directory = try std.Io.Dir.openDirAbsolute(io, path, .{
        .iterate = true,
        .follow_symlinks = false,
    });
    defer directory.close(io);
    try directory.setPermissions(io, .fromMode(mode));
    try syncDirectory(directory);
}

fn setDormantRelativeDirectoryModes(
    io: std.Io,
    root: std.Io.Dir,
    relative_path: []const u8,
    mode: u16,
) !void {
    var current = root;
    var current_owned = false;
    defer if (current_owned) current.close(io);
    var segments = std.mem.splitScalar(u8, relative_path, '/');
    while (segments.next()) |segment| {
        const next = try openExistingDir(io, current, segment);
        if (current_owned) current.close(io);
        current = next;
        current_owned = true;
        try current.setPermissions(io, .fromMode(mode));
        try syncDirectory(current);
    }
}

fn deleteDormantFixtureRelative(
    io: std.Io,
    root: std.Io.Dir,
    relative_path: []const u8,
) !void {
    const parent_path = std.fs.path.dirname(relative_path) orelse ".";
    const basename = std.fs.path.basename(relative_path);
    var parent = try openPathNoFollow(io, root, parent_path, false);
    defer parent.close(io);
    try parent.deleteFile(io, basename);
    try syncDirectory(parent);
}

fn replaceDormantFixtureRelative(
    io: std.Io,
    root: std.Io.Dir,
    relative_path: []const u8,
    bytes: []const u8,
    mode: u16,
) !void {
    deleteDormantFixtureRelative(io, root, relative_path) catch |err| switch (err) {
        error.FileNotFound => {},
        else => return err,
    };
    try writeDormantFixtureRelative(io, root, relative_path, bytes, mode);
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

fn replaceDormantTestOwnedBytes(
    allocator: std.mem.Allocator,
    slot: *[]u8,
    replacement: []const u8,
) ![]u8 {
    if (!builtin.is_test) return error.TestOnlyOperation;
    const previous = slot.*;
    slot.* = try allocator.dupe(u8, replacement);
    return previous;
}

fn restoreDormantTestOwnedBytes(
    allocator: std.mem.Allocator,
    slot: *[]u8,
    previous: []u8,
) void {
    if (!builtin.is_test) @panic("test-only dormant restoration");
    allocator.free(slot.*);
    slot.* = previous;
}

const DormantReadinessTreeEntry = struct {
    name: []u8,
    kind: std.Io.File.Kind,

    fn deinit(entry: *DormantReadinessTreeEntry, allocator: std.mem.Allocator) void {
        allocator.free(entry.name);
        entry.* = undefined;
    }
};

const DormantReadinessSnapshotEntry = struct {
    path: []u8,
    state: []u8,

    fn deinit(entry: *DormantReadinessSnapshotEntry, allocator: std.mem.Allocator) void {
        allocator.free(entry.state);
        allocator.free(entry.path);
        entry.* = undefined;
    }
};

const DormantReadinessSnapshot = struct {
    allocator: std.mem.Allocator,
    logical_state: []u8,
    entries: []DormantReadinessSnapshotEntry,

    fn deinit(snapshot: *DormantReadinessSnapshot) void {
        for (snapshot.entries) |*entry| entry.deinit(snapshot.allocator);
        snapshot.allocator.free(snapshot.entries);
        snapshot.allocator.free(snapshot.logical_state);
        snapshot.* = undefined;
    }
};

fn appendDormantReadinessSnapshotEntry(
    allocator: std.mem.Allocator,
    entries: *std.ArrayList(DormantReadinessSnapshotEntry),
    owned_path: *?[]u8,
    owned_state: *?[]u8,
) !void {
    const path = owned_path.* orelse return error.DormantReadinessMissingOwnedPath;
    const state = owned_state.* orelse return error.DormantReadinessMissingOwnedState;
    try entries.append(allocator, .{ .path = path, .state = state });
    owned_path.* = null;
    owned_state.* = null;
}

const DormantReadinessNetEffects = struct {
    created_paths: usize = 0,
    removed_paths: usize = 0,
    modified_paths: usize = 0,
    publication_path_changes: usize = 0,
    logical_state_modified: bool = false,

    fn isUnchanged(effects: DormantReadinessNetEffects) bool {
        return effects.created_paths == 0 and
            effects.removed_paths == 0 and
            effects.modified_paths == 0 and
            effects.publication_path_changes == 0 and
            !effects.logical_state_modified;
    }
};

const dormant_readiness_publication_prefix =
    "main/control/authority/zllvm/v1/receipts/publication";

fn dormantReadinessPublicationPath(path: []const u8) bool {
    return std.mem.eql(u8, path, dormant_readiness_publication_prefix) or
        (std.mem.startsWith(u8, path, dormant_readiness_publication_prefix) and
            path.len > dormant_readiness_publication_prefix.len and
            path[dormant_readiness_publication_prefix.len] == '/');
}

fn appendDormantReadinessField(
    allocator: std.mem.Allocator,
    output: *std.ArrayList(u8),
    value: []const u8,
) !void {
    try output.print(allocator, "{}:", .{value.len});
    try output.appendSlice(allocator, value);
    try output.append(allocator, '\n');
}

fn appendDormantReadinessInteger(
    allocator: std.mem.Allocator,
    output: *std.ArrayList(u8),
    value: anytype,
) !void {
    try output.print(allocator, "{}\n", .{value});
}

fn appendDormantControlObservationState(
    allocator: std.mem.Allocator,
    output: *std.ArrayList(u8),
    observation: *const ControlGitObservation,
) !void {
    try appendDormantReadinessField(allocator, output, &observation.commit);
    try appendDormantReadinessField(allocator, output, &observation.tree);
    try appendDormantReadinessField(allocator, output, observation.branch);
    try appendDormantReadinessField(allocator, output, observation.status);
    try appendDormantReadinessField(allocator, output, observation.remotes);
    try appendDormantReadinessInteger(allocator, output, observation.entries.len);
    for (observation.entries) |entry| {
        try appendDormantReadinessField(allocator, output, &entry.mode);
        try appendDormantReadinessField(allocator, output, &entry.kind);
        try appendDormantReadinessField(allocator, output, &entry.object_id);
        try appendDormantReadinessField(allocator, output, entry.path);
    }
}

fn appendDormantRegistrationState(
    allocator: std.mem.Allocator,
    output: *std.ArrayList(u8),
    snapshot: *const RegistrationSnapshot,
) !void {
    try appendDormantReadinessField(allocator, output, snapshot.raw);
    try appendDormantReadinessInteger(allocator, output, snapshot.paths.len);
    for (snapshot.paths) |path| {
        try appendDormantReadinessField(allocator, output, path);
    }
    try appendDormantReadinessField(allocator, output, &snapshot.full_hash);
    try appendDormantReadinessField(allocator, output, &snapshot.path_hash);
    try appendDormantReadinessField(allocator, output, &snapshot.topology_hash);
    try appendDormantReadinessField(allocator, output, &snapshot.non_main_hash);
    try appendDormantReadinessInteger(allocator, output, snapshot.repository_tmp_count);
    try appendDormantReadinessInteger(allocator, output, snapshot.system_tmp_count);
    try appendDormantReadinessInteger(allocator, output, snapshot.other_count);
}

fn appendDormantLogicalState(
    allocator: std.mem.Allocator,
    output: *std.ArrayList(u8),
    config: *const DormantAuthorityConfig,
) !void {
    try appendDormantReadinessField(allocator, output, config.control_root);
    try appendDormantReadinessField(allocator, output, config.authority_root);
    try appendDormantReadinessField(allocator, output, config.payload_root);
    try appendDormantReadinessField(allocator, output, config.source_root);
    try appendDormantReadinessField(allocator, output, &config.source_manifest_sha256);
    try appendDormantReadinessField(
        allocator,
        output,
        &config.expected_source_inventory_sha256,
    );
    try appendDormantReadinessField(
        allocator,
        output,
        &config.expected_source_file_ledger_sha256,
    );
    try appendDormantReadinessField(
        allocator,
        output,
        &config.expected_source_destination_ledger_sha256,
    );
    try appendDormantReadinessField(allocator, output, config.expected_copy_evidence_path);
    try appendDormantReadinessField(allocator, output, &config.expected_copy_evidence_sha256);
    try appendDormantReadinessField(allocator, output, &config.expected_registration_full_hash);
    try appendDormantReadinessField(allocator, output, &config.expected_registration_path_hash);
    try appendDormantReadinessField(
        allocator,
        output,
        &config.expected_registration_topology_hash,
    );
    try appendDormantReadinessField(
        allocator,
        output,
        &config.expected_registration_non_main_hash,
    );

    const policy = &config.root_policy;
    try appendDormantReadinessField(allocator, output, @tagName(policy.kind));
    try appendDormantReadinessField(allocator, output, policy.main_root);
    try appendDormantReadinessField(allocator, output, policy.control_root);
    try appendDormantReadinessField(allocator, output, policy.authority_root);
    try appendDormantReadinessField(allocator, output, policy.payload_root);
    try appendDormantReadinessField(allocator, output, policy.source_root);
    try appendDormantReadinessField(allocator, output, policy.supplemental_control_root);
    try appendDormantReadinessInteger(allocator, output, policy.non_main_roots.len);
    for (policy.non_main_roots) |path| {
        try appendDormantReadinessField(allocator, output, path);
    }
    try appendDormantReadinessInteger(allocator, output, policy.control_files.len);
    for (policy.control_files) |expectation| {
        try appendDormantReadinessField(
            allocator,
            output,
            @tagName(expectation.component),
        );
        try appendDormantReadinessField(allocator, output, expectation.path);
        try appendDormantReadinessField(allocator, output, &expectation.sha256);
        try appendDormantReadinessInteger(allocator, output, expectation.bytes);
        try appendDormantReadinessInteger(allocator, output, expectation.mode);
    }
    try appendDormantControlObservationState(allocator, output, &policy.observed_control);
    try appendDormantControlObservationState(allocator, output, &policy.expected_control);
    try appendDormantRegistrationState(allocator, output, &config.guard.frozen);
}

fn appendDormantReadinessTree(
    allocator: std.mem.Allocator,
    io: std.Io,
    absolute_root: []const u8,
    directory: std.Io.Dir,
    prefix: []const u8,
    snapshot_entries: *std.ArrayList(DormantReadinessSnapshotEntry),
) !void {
    var entries: std.ArrayList(DormantReadinessTreeEntry) = .empty;
    defer {
        for (entries.items) |*entry| entry.deinit(allocator);
        entries.deinit(allocator);
    }
    var iterator = directory.iterate();
    while (try iterator.next(io)) |entry| {
        try entries.append(allocator, .{
            .name = try allocator.dupe(u8, entry.name),
            .kind = entry.kind,
        });
    }
    std.mem.sort(DormantReadinessTreeEntry, entries.items, {}, struct {
        fn lessThan(_: void, a: DormantReadinessTreeEntry, b: DormantReadinessTreeEntry) bool {
            return std.mem.order(u8, a.name, b.name) == .lt;
        }
    }.lessThan);
    for (entries.items) |entry| {
        var owned_path: ?[]u8 = if (prefix.len == 0)
            try allocator.dupe(u8, entry.name)
        else
            try std.fs.path.join(allocator, &.{ prefix, entry.name });
        errdefer if (owned_path) |path| allocator.free(path);
        const relative = owned_path.?;
        const stat = try directory.statFile(io, entry.name, .{ .follow_symlinks = false });
        var state: std.ArrayList(u8) = .empty;
        errdefer state.deinit(allocator);
        try appendDormantReadinessField(allocator, &state, @tagName(entry.kind));
        try appendDormantReadinessInteger(
            allocator,
            &state,
            @as(u16, @intCast(stat.permissions.toMode() & 0o7777)),
        );
        switch (entry.kind) {
            .directory => {
                var child = try directory.openDir(io, entry.name, .{
                    .access_sub_paths = true,
                    .iterate = true,
                    .follow_symlinks = false,
                });
                defer child.close(io);
                try appendDormantReadinessTree(
                    allocator,
                    io,
                    absolute_root,
                    child,
                    relative,
                    snapshot_entries,
                );
            },
            .file => {
                var file = try directory.openFile(io, entry.name, .{
                    .allow_directory = false,
                    .follow_symlinks = false,
                });
                defer file.close(io);
                var identity = try identityOfOpenFileAnyMode(allocator, io, file);
                defer identity.deinit(allocator);
                try appendDormantReadinessInteger(allocator, &state, identity.bytes);
                try appendDormantReadinessField(allocator, &state, &identity.sha256);
            },
            .sym_link => {
                const absolute = try std.fs.path.join(
                    allocator,
                    &.{ absolute_root, relative },
                );
                defer allocator.free(absolute);
                var target_buffer: [4096]u8 = undefined;
                const target_len = try std.Io.Dir.readLinkAbsolute(
                    io,
                    absolute,
                    &target_buffer,
                );
                try appendDormantReadinessField(
                    allocator,
                    &state,
                    target_buffer[0..target_len],
                );
            },
            else => return error.DormantReadinessUnsupportedFixtureKind,
        }
        var owned_state: ?[]u8 = try state.toOwnedSlice(allocator);
        errdefer if (owned_state) |state_bytes| allocator.free(state_bytes);
        try appendDormantReadinessSnapshotEntry(
            allocator,
            snapshot_entries,
            &owned_path,
            &owned_state,
        );
    }
}

fn captureDormantReadinessState(
    fixture: *const DormantSyntheticFixture,
    config: *const DormantAuthorityConfig,
) !DormantReadinessSnapshot {
    if (!builtin.is_test) return error.TestOnlyOperation;
    var logical_state: std.ArrayList(u8) = .empty;
    errdefer logical_state.deinit(fixture.allocator);
    try appendDormantReadinessField(fixture.allocator, &logical_state, "logical-v1");
    try appendDormantLogicalState(fixture.allocator, &logical_state, config);
    const owned_logical_state = try logical_state.toOwnedSlice(fixture.allocator);
    errdefer fixture.allocator.free(owned_logical_state);

    var entries: std.ArrayList(DormantReadinessSnapshotEntry) = .empty;
    errdefer {
        for (entries.items) |*entry| entry.deinit(fixture.allocator);
        entries.deinit(fixture.allocator);
    }
    var root = try std.Io.Dir.openDirAbsolute(fixture.io, fixture.root, .{
        .access_sub_paths = true,
        .iterate = true,
        .follow_symlinks = false,
    });
    defer root.close(fixture.io);
    const root_stat = try root.stat(fixture.io);
    var root_state: std.ArrayList(u8) = .empty;
    defer root_state.deinit(fixture.allocator);
    try appendDormantReadinessField(fixture.allocator, &root_state, "directory");
    try appendDormantReadinessInteger(
        fixture.allocator,
        &root_state,
        @as(u16, @intCast(root_stat.permissions.toMode() & 0o7777)),
    );
    var owned_root_state: ?[]u8 = try root_state.toOwnedSlice(fixture.allocator);
    errdefer if (owned_root_state) |state| fixture.allocator.free(state);
    var owned_root_path: ?[]u8 = try fixture.allocator.dupe(u8, ".");
    errdefer if (owned_root_path) |path| fixture.allocator.free(path);
    try appendDormantReadinessSnapshotEntry(
        fixture.allocator,
        &entries,
        &owned_root_path,
        &owned_root_state,
    );
    try appendDormantReadinessTree(
        fixture.allocator,
        fixture.io,
        fixture.root,
        root,
        "",
        &entries,
    );
    std.mem.sort(DormantReadinessSnapshotEntry, entries.items, {}, struct {
        fn lessThan(
            _: void,
            a: DormantReadinessSnapshotEntry,
            b: DormantReadinessSnapshotEntry,
        ) bool {
            return std.mem.order(u8, a.path, b.path) == .lt;
        }
    }.lessThan);
    return .{
        .allocator = fixture.allocator,
        .logical_state = owned_logical_state,
        .entries = try entries.toOwnedSlice(fixture.allocator),
    };
}

fn compareDormantReadinessStates(
    before: *const DormantReadinessSnapshot,
    after: *const DormantReadinessSnapshot,
) DormantReadinessNetEffects {
    var effects: DormantReadinessNetEffects = .{
        .logical_state_modified = !std.mem.eql(
            u8,
            before.logical_state,
            after.logical_state,
        ),
    };
    var before_index: usize = 0;
    var after_index: usize = 0;
    while (before_index < before.entries.len or after_index < after.entries.len) {
        if (before_index == before.entries.len) {
            const entry = after.entries[after_index];
            effects.created_paths += 1;
            if (dormantReadinessPublicationPath(entry.path)) {
                effects.publication_path_changes += 1;
            }
            after_index += 1;
            continue;
        }
        if (after_index == after.entries.len) {
            const entry = before.entries[before_index];
            effects.removed_paths += 1;
            if (dormantReadinessPublicationPath(entry.path)) {
                effects.publication_path_changes += 1;
            }
            before_index += 1;
            continue;
        }
        const old_entry = before.entries[before_index];
        const new_entry = after.entries[after_index];
        switch (std.mem.order(u8, old_entry.path, new_entry.path)) {
            .lt => {
                effects.removed_paths += 1;
                if (dormantReadinessPublicationPath(old_entry.path)) {
                    effects.publication_path_changes += 1;
                }
                before_index += 1;
            },
            .gt => {
                effects.created_paths += 1;
                if (dormantReadinessPublicationPath(new_entry.path)) {
                    effects.publication_path_changes += 1;
                }
                after_index += 1;
            },
            .eq => {
                if (!std.mem.eql(u8, old_entry.state, new_entry.state)) {
                    effects.modified_paths += 1;
                    if (dormantReadinessPublicationPath(old_entry.path)) {
                        effects.publication_path_changes += 1;
                    }
                }
                before_index += 1;
                after_index += 1;
            },
        }
    }
    return effects;
}

fn expectDormantReadinessEffects(
    actual: DormantReadinessNetEffects,
    expected: DormantReadinessNetEffects,
) !void {
    try std.testing.expectEqual(expected.created_paths, actual.created_paths);
    try std.testing.expectEqual(expected.removed_paths, actual.removed_paths);
    try std.testing.expectEqual(expected.modified_paths, actual.modified_paths);
    try std.testing.expectEqual(
        expected.publication_path_changes,
        actual.publication_path_changes,
    );
    try std.testing.expectEqual(expected.logical_state_modified, actual.logical_state_modified);
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

fn exerciseDormantReadinessOwnershipFailure(
    allocator: std.mem.Allocator,
    appended_entries: *usize,
) !void {
    if (!builtin.is_test) return error.TestOnlyOperation;
    var entries: std.ArrayList(DormantReadinessSnapshotEntry) = .empty;
    defer {
        for (entries.items) |*entry| entry.deinit(allocator);
        entries.deinit(allocator);
    }

    var first_path: ?[]u8 = try allocator.dupe(u8, "first/child");
    errdefer if (first_path) |path| allocator.free(path);
    var first_state: ?[]u8 = try allocator.dupe(u8, "first-state");
    errdefer if (first_state) |state| allocator.free(state);
    try appendDormantReadinessSnapshotEntry(
        allocator,
        &entries,
        &first_path,
        &first_state,
    );
    appended_entries.* += 1;

    var later_path: ?[]u8 = try allocator.dupe(u8, "later/recursive/child");
    errdefer if (later_path) |path| allocator.free(path);
    var later_state: ?[]u8 = try allocator.dupe(u8, "later-state");
    errdefer if (later_state) |state| allocator.free(state);
    try appendDormantReadinessSnapshotEntry(
        allocator,
        &entries,
        &later_path,
        &later_state,
    );
    appended_entries.* += 1;
}

const DormantExactAcceptanceSnapshotIdentity = struct {
    bytes: u64,
    sha256: [64]u8,
};

const DormantExactObserverPathSpec = struct {
    label: []u8,
    path: []u8,
    unexpected_publication: bool,

    fn deinit(spec: *DormantExactObserverPathSpec, allocator: std.mem.Allocator) void {
        allocator.free(spec.path);
        allocator.free(spec.label);
        spec.* = undefined;
    }
};

const DormantExactObserverRow = struct {
    label: []u8,
    path: []u8,
    state: []u8,
    exists: bool,
    logical: bool,
    unexpected_publication: bool,

    fn deinit(row: *DormantExactObserverRow, allocator: std.mem.Allocator) void {
        allocator.free(row.state);
        allocator.free(row.path);
        allocator.free(row.label);
        row.* = undefined;
    }
};

const DormantExactRealObservation = struct {
    allocator: std.mem.Allocator,
    rows: []DormantExactObserverRow,
    identity: DormantExactAcceptanceSnapshotIdentity,

    fn deinit(observation: *DormantExactRealObservation) void {
        for (observation.rows) |*row| row.deinit(observation.allocator);
        observation.allocator.free(observation.rows);
        observation.* = undefined;
    }
};

fn appendDormantExactObserverSpec(
    allocator: std.mem.Allocator,
    specs: *std.ArrayList(DormantExactObserverPathSpec),
    label: []const u8,
    path: []const u8,
    unexpected_publication: bool,
) !void {
    for (specs.items) |existing| {
        if (std.mem.eql(u8, existing.label, label) or
            std.mem.eql(u8, existing.path, path))
        {
            if (!std.mem.eql(u8, existing.label, label) or
                !std.mem.eql(u8, existing.path, path) or
                existing.unexpected_publication != unexpected_publication)
            {
                return error.DormantExactObserverAmbiguousPath;
            }
            return;
        }
    }
    const owned_label = try allocator.dupe(u8, label);
    errdefer allocator.free(owned_label);
    const owned_path = try allocator.dupe(u8, path);
    errdefer allocator.free(owned_path);
    try specs.append(allocator, .{
        .label = owned_label,
        .path = owned_path,
        .unexpected_publication = unexpected_publication,
    });
}

fn appendDormantExactObserverAllocatedSpec(
    allocator: std.mem.Allocator,
    specs: *std.ArrayList(DormantExactObserverPathSpec),
    label: []const u8,
    path: []const u8,
    unexpected_publication: bool,
) !void {
    try appendDormantExactObserverSpec(
        allocator,
        specs,
        label,
        path,
        unexpected_publication,
    );
}

fn appendDormantExactObserverAncestors(
    allocator: std.mem.Allocator,
    specs: *std.ArrayList(DormantExactObserverPathSpec),
    root: []const u8,
    domain: []const u8,
    relative_path: []const u8,
) !void {
    const parent = std.fs.path.dirname(relative_path) orelse return;
    if (std.mem.eql(u8, parent, ".")) return;
    var prefix: std.ArrayList(u8) = .empty;
    defer prefix.deinit(allocator);
    var segments = std.mem.splitScalar(u8, parent, '/');
    while (segments.next()) |segment| {
        if (prefix.items.len != 0) try prefix.append(allocator, '/');
        try prefix.appendSlice(allocator, segment);
        const label = try std.fmt.allocPrint(
            allocator,
            "{s}-directory:{s}",
            .{ domain, prefix.items },
        );
        defer allocator.free(label);
        const path = try std.fs.path.join(allocator, &.{ root, prefix.items });
        defer allocator.free(path);
        try appendDormantExactObserverAllocatedSpec(
            allocator,
            specs,
            label,
            path,
            false,
        );
    }
}

fn appendDormantExactObserverFileSpec(
    allocator: std.mem.Allocator,
    specs: *std.ArrayList(DormantExactObserverPathSpec),
    root: []const u8,
    domain: []const u8,
    relative_path: []const u8,
) !void {
    try appendDormantExactObserverAncestors(
        allocator,
        specs,
        root,
        domain,
        relative_path,
    );
    const label = try std.fmt.allocPrint(
        allocator,
        "{s}-file:{s}",
        .{ domain, relative_path },
    );
    defer allocator.free(label);
    const path = try std.fs.path.join(allocator, &.{ root, relative_path });
    defer allocator.free(path);
    try appendDormantExactObserverAllocatedSpec(allocator, specs, label, path, false);
}

fn dormantExactObserverRowLessThan(
    _: void,
    a: DormantExactObserverRow,
    b: DormantExactObserverRow,
) bool {
    const label_order = std.mem.order(u8, a.label, b.label);
    if (label_order != .eq) return label_order == .lt;
    return std.mem.order(u8, a.path, b.path) == .lt;
}

fn captureDormantExactObserverRowFromDir(
    allocator: std.mem.Allocator,
    io: std.Io,
    directory: std.Io.Dir,
    basename: []const u8,
    label: []const u8,
    canonical_path: []const u8,
    unexpected_publication: bool,
) !DormantExactObserverRow {
    const owned_label = try allocator.dupe(u8, label);
    errdefer allocator.free(owned_label);
    const owned_path = try allocator.dupe(u8, canonical_path);
    errdefer allocator.free(owned_path);
    var state: std.ArrayList(u8) = .empty;
    errdefer state.deinit(allocator);
    const stat = directory.statFile(io, basename, .{ .follow_symlinks = false }) catch |err|
        switch (err) {
            error.FileNotFound => {
                try appendDormantReadinessField(allocator, &state, "absent");
                return .{
                    .label = owned_label,
                    .path = owned_path,
                    .state = try state.toOwnedSlice(allocator),
                    .exists = false,
                    .logical = false,
                    .unexpected_publication = unexpected_publication,
                };
            },
            else => return err,
        };
    try appendDormantReadinessField(allocator, &state, "present");
    try appendDormantReadinessField(allocator, &state, @tagName(stat.kind));
    try appendDormantReadinessInteger(
        allocator,
        &state,
        @as(u16, @intCast(stat.permissions.toMode() & 0o7777)),
    );
    try appendDormantReadinessInteger(allocator, &state, stat.inode);
    try appendDormantReadinessInteger(allocator, &state, stat.nlink);
    try appendDormantReadinessInteger(allocator, &state, stat.size);
    if (stat.kind == .file) {
        var file = try directory.openFile(io, basename, .{
            .allow_directory = false,
            .follow_symlinks = false,
        });
        defer file.close(io);
        var identity = try identityOfOpenFileAnyMode(allocator, io, file);
        defer identity.deinit(allocator);
        if (identity.bytes != stat.size or
            identity.mode != @as(u16, @intCast(stat.permissions.toMode() & 0o7777)))
        {
            return error.DormantExactObserverPathDrift;
        }
        try appendDormantReadinessField(allocator, &state, &identity.sha256);
    } else {
        try appendDormantReadinessField(allocator, &state, "not-applicable");
    }
    return .{
        .label = owned_label,
        .path = owned_path,
        .state = try state.toOwnedSlice(allocator),
        .exists = true,
        .logical = false,
        .unexpected_publication = unexpected_publication,
    };
}

fn captureDormantExactObserverAbsoluteRow(
    allocator: std.mem.Allocator,
    io: std.Io,
    spec: DormantExactObserverPathSpec,
) !DormantExactObserverRow {
    const parent_path = std.fs.path.dirname(spec.path) orelse
        return error.DormantExactObserverUnsafePath;
    const basename = std.fs.path.basename(spec.path);
    var parent = std.Io.Dir.openDirAbsolute(io, parent_path, .{
        .access_sub_paths = true,
        .follow_symlinks = false,
    }) catch |err| switch (err) {
        error.FileNotFound => {
            const owned_label = try allocator.dupe(u8, spec.label);
            errdefer allocator.free(owned_label);
            const owned_path = try allocator.dupe(u8, spec.path);
            errdefer allocator.free(owned_path);
            var state: std.ArrayList(u8) = .empty;
            errdefer state.deinit(allocator);
            try appendDormantReadinessField(allocator, &state, "absent");
            return .{
                .label = owned_label,
                .path = owned_path,
                .state = try state.toOwnedSlice(allocator),
                .exists = false,
                .logical = false,
                .unexpected_publication = spec.unexpected_publication,
            };
        },
        else => return err,
    };
    defer parent.close(io);
    return captureDormantExactObserverRowFromDir(
        allocator,
        io,
        parent,
        basename,
        spec.label,
        spec.path,
        spec.unexpected_publication,
    );
}

fn appendDormantExactObserverLogicalRow(
    allocator: std.mem.Allocator,
    rows: *std.ArrayList(DormantExactObserverRow),
    label: []const u8,
    path: []const u8,
    state: []const u8,
) !void {
    const owned_label = try allocator.dupe(u8, label);
    errdefer allocator.free(owned_label);
    const owned_path = try allocator.dupe(u8, path);
    errdefer allocator.free(owned_path);
    const owned_state = try allocator.dupe(u8, state);
    errdefer allocator.free(owned_state);
    try rows.append(allocator, .{
        .label = owned_label,
        .path = owned_path,
        .state = owned_state,
        .exists = true,
        .logical = true,
        .unexpected_publication = false,
    });
}

fn dormantExactObserverIdentity(
    allocator: std.mem.Allocator,
    rows: []const DormantExactObserverRow,
) !DormantExactAcceptanceSnapshotIdentity {
    var encoded: std.ArrayList(u8) = .empty;
    defer encoded.deinit(allocator);
    try appendDormantReadinessField(allocator, &encoded, "dormant-exact-real-observer-v1");
    try appendDormantReadinessInteger(allocator, &encoded, rows.len);
    for (rows) |row| {
        try appendDormantReadinessField(allocator, &encoded, row.label);
        try appendDormantReadinessField(allocator, &encoded, row.path);
        try appendDormantReadinessField(
            allocator,
            &encoded,
            if (row.exists) "present" else "absent",
        );
        try appendDormantReadinessField(
            allocator,
            &encoded,
            if (row.logical) "logical" else "path",
        );
        try appendDormantReadinessField(
            allocator,
            &encoded,
            if (row.unexpected_publication) "unexpected-publication" else "admitted",
        );
        try appendDormantReadinessField(allocator, &encoded, row.state);
    }
    return .{
        .bytes = std.math.cast(u64, encoded.items.len) orelse
            return error.DormantAcceptanceSnapshotTooLarge,
        .sha256 = sha256Hex(encoded.items),
    };
}

fn finishDormantExactObservation(
    allocator: std.mem.Allocator,
    rows: *std.ArrayList(DormantExactObserverRow),
) !DormantExactRealObservation {
    std.mem.sort(DormantExactObserverRow, rows.items, {}, dormantExactObserverRowLessThan);
    for (rows.items, 0..) |row, index| {
        if (index != 0) {
            const previous = rows.items[index - 1];
            if (std.mem.eql(u8, previous.label, row.label) or
                std.mem.eql(u8, previous.path, row.path))
            {
                return error.DormantExactObserverDuplicateRow;
            }
        }
    }
    const identity = try dormantExactObserverIdentity(allocator, rows.items);
    return .{
        .allocator = allocator,
        .rows = try rows.toOwnedSlice(allocator),
        .identity = identity,
    };
}

fn compareDormantExactRealObservations(
    before: *const DormantExactRealObservation,
    after: *const DormantExactRealObservation,
) DormantReadinessNetEffects {
    var effects: DormantReadinessNetEffects = .{};
    var before_index: usize = 0;
    var after_index: usize = 0;
    while (before_index < before.rows.len or after_index < after.rows.len) {
        const old: ?DormantExactObserverRow = if (before_index < before.rows.len)
            before.rows[before_index]
        else
            null;
        const new: ?DormantExactObserverRow = if (after_index < after.rows.len)
            after.rows[after_index]
        else
            null;
        const order = if (old == null)
            std.math.Order.gt
        else if (new == null)
            std.math.Order.lt
        else blk: {
            const label_order = std.mem.order(u8, old.?.label, new.?.label);
            break :blk if (label_order != .eq)
                label_order
            else
                std.mem.order(u8, old.?.path, new.?.path);
        };
        if (order == .lt) {
            const row = old.?;
            if (row.logical) {
                effects.logical_state_modified = true;
            } else if (row.exists) {
                effects.removed_paths += 1;
            }
            if (row.unexpected_publication and row.exists) {
                effects.publication_path_changes += 1;
            }
            before_index += 1;
        } else if (order == .gt) {
            const row = new.?;
            if (row.logical) {
                effects.logical_state_modified = true;
            } else if (row.exists) {
                effects.created_paths += 1;
            }
            if (row.unexpected_publication and row.exists) {
                effects.publication_path_changes += 1;
            }
            after_index += 1;
        } else {
            const old_row = old.?;
            const new_row = new.?;
            if (old_row.logical or new_row.logical) {
                if (!old_row.logical or !new_row.logical or
                    !std.mem.eql(u8, old_row.state, new_row.state))
                {
                    effects.logical_state_modified = true;
                }
            } else if (!old_row.exists and new_row.exists) {
                effects.created_paths += 1;
            } else if (old_row.exists and !new_row.exists) {
                effects.removed_paths += 1;
            } else if (old_row.exists and new_row.exists and
                !std.mem.eql(u8, old_row.state, new_row.state))
            {
                effects.modified_paths += 1;
            }
            if ((old_row.unexpected_publication and old_row.exists) or
                (new_row.unexpected_publication and new_row.exists))
            {
                effects.publication_path_changes += 1;
            }
            before_index += 1;
            after_index += 1;
        }
    }
    return effects;
}

fn deinitDormantExactObserverSpecs(
    allocator: std.mem.Allocator,
    specs: *std.ArrayList(DormantExactObserverPathSpec),
) void {
    for (specs.items) |*spec| spec.deinit(allocator);
    specs.deinit(allocator);
}

fn appendDormantExactObserverDirectorySpec(
    allocator: std.mem.Allocator,
    specs: *std.ArrayList(DormantExactObserverPathSpec),
    root: []const u8,
    domain: []const u8,
    relative_path: []const u8,
) !void {
    const label = try std.fmt.allocPrint(
        allocator,
        "{s}-directory:{s}",
        .{ domain, relative_path },
    );
    defer allocator.free(label);
    const path = try std.fs.path.join(allocator, &.{ root, relative_path });
    defer allocator.free(path);
    try appendDormantExactObserverAllocatedSpec(allocator, specs, label, path, false);
}

fn appendDormantExactObserverControlSpecs(
    allocator: std.mem.Allocator,
    specs: *std.ArrayList(DormantExactObserverPathSpec),
    config: *const DormantAuthorityConfig,
) !void {
    for (config.root_policy.control_files) |expectation| {
        try appendDormantExactObserverFileSpec(
            allocator,
            specs,
            config.control_root,
            "control",
            expectation.path,
        );
    }
}

fn appendDormantExactObserverPayloadSpecs(
    allocator: std.mem.Allocator,
    specs: *std.ArrayList(DormantExactObserverPathSpec),
    config: *const DormantAuthorityConfig,
) !void {
    const generation_bytes = try readDormantControlFile(
        config,
        .generation,
        dormant_generation_key,
    );
    defer allocator.free(generation_bytes);
    var manifest = try parseManifest(allocator, generation_bytes);
    defer manifest.deinit(allocator);
    for ([_][]const u8{
        "incoming",
        "objects",
        "objects/sha256",
        "snapshots",
        "snapshots/sha256",
    }) |relative_path| {
        try appendDormantExactObserverDirectorySpec(
            allocator,
            specs,
            config.payload_root,
            "payload",
            relative_path,
        );
    }
    for (manifest.rows) |row| {
        if (row.kind != .object and row.kind != .snapshot) continue;
        const parent_path = std.fs.path.dirname(row.key) orelse
            return error.DormantExactObserverUnsafePath;
        try appendDormantExactObserverDirectorySpec(
            allocator,
            specs,
            config.payload_root,
            "payload",
            parent_path,
        );
        try appendDormantExactObserverFileSpec(
            allocator,
            specs,
            config.payload_root,
            "payload",
            row.key,
        );
    }
}

fn appendDormantExactObserverUnexpectedPublicationSpecs(
    allocator: std.mem.Allocator,
    specs: *std.ArrayList(DormantExactObserverPathSpec),
    config: *const DormantAuthorityConfig,
) !void {
    const relative_directory = "authority/zllvm/v1/receipts/publication";
    var control = std.Io.Dir.openDirAbsolute(config.io, config.control_root, .{
        .access_sub_paths = true,
        .iterate = true,
        .follow_symlinks = false,
    }) catch |err| switch (err) {
        error.FileNotFound => return,
        else => return err,
    };
    defer control.close(config.io);
    var publication = openPathNoFollow(
        config.io,
        control,
        relative_directory,
        false,
    ) catch |err| switch (err) {
        error.FileNotFound => return,
        else => return err,
    };
    defer publication.close(config.io);
    var iterator = publication.iterate();
    var entry_count: usize = 0;
    while (try iterator.next(config.io)) |entry| {
        entry_count += 1;
        if (entry_count > 64) return error.DormantExactObserverPublicationBoundExceeded;
        if (std.mem.eql(u8, entry.name, std.fs.path.basename(dormant_receipt_key))) continue;
        const relative_path = try std.fs.path.join(
            allocator,
            &.{ relative_directory, entry.name },
        );
        defer allocator.free(relative_path);
        const path = try std.fs.path.join(allocator, &.{ config.control_root, relative_path });
        defer allocator.free(path);
        const label = try std.fmt.allocPrint(
            allocator,
            "unexpected-publication:{s}",
            .{entry.name},
        );
        defer allocator.free(label);
        try appendDormantExactObserverAllocatedSpec(allocator, specs, label, path, true);
    }
}

fn captureDormantExactRealObservation(
    config: *const DormantAuthorityConfig,
) !DormantExactRealObservation {
    if (!builtin.is_test) return error.TestOnlyOperation;
    var specs: std.ArrayList(DormantExactObserverPathSpec) = .empty;
    defer deinitDormantExactObserverSpecs(config.allocator, &specs);
    try appendDormantExactObserverSpec(
        config.allocator,
        &specs,
        "root:main",
        config.root_policy.main_root,
        false,
    );
    try appendDormantExactObserverSpec(
        config.allocator,
        &specs,
        "root:control",
        config.control_root,
        false,
    );
    try appendDormantExactObserverSpec(
        config.allocator,
        &specs,
        "root:payload",
        config.payload_root,
        false,
    );
    try appendDormantExactObserverSpec(
        config.allocator,
        &specs,
        "root:source",
        config.source_root,
        false,
    );
    try appendDormantExactObserverSpec(
        config.allocator,
        &specs,
        "tool:git",
        dormant_git_executable,
        false,
    );
    try appendDormantExactObserverFileSpec(
        config.allocator,
        &specs,
        config.root_policy.main_root,
        "copy-evidence",
        config.expected_copy_evidence_path,
    );
    try appendDormantExactObserverControlSpecs(config.allocator, &specs, config);
    try appendDormantExactObserverPayloadSpecs(config.allocator, &specs, config);
    try appendDormantExactObserverUnexpectedPublicationSpecs(
        config.allocator,
        &specs,
        config,
    );

    var rows: std.ArrayList(DormantExactObserverRow) = .empty;
    errdefer {
        for (rows.items) |*row| row.deinit(config.allocator);
        rows.deinit(config.allocator);
    }
    for (specs.items) |spec| {
        try rows.append(
            config.allocator,
            try captureDormantExactObserverAbsoluteRow(
                config.allocator,
                config.io,
                spec,
            ),
        );
    }
    var logical_state: std.ArrayList(u8) = .empty;
    defer logical_state.deinit(config.allocator);
    try appendDormantReadinessField(
        config.allocator,
        &logical_state,
        "dormant-exact-real-logical-state-v1",
    );
    try appendDormantLogicalState(config.allocator, &logical_state, config);
    try appendDormantExactObserverLogicalRow(
        config.allocator,
        &rows,
        "logical:authority-and-registration",
        "logical://authority-and-registration",
        logical_state.items,
    );
    return finishDormantExactObservation(config.allocator, &rows);
}

const DormantExactAcceptanceEvidence = struct {
    control_root: []const u8,
    authority_root: []const u8,
    payload_root: []const u8,
    source_root: []const u8,
    source_manifest_sha256: []const u8,
    source_inventory_sha256: []const u8,
    source_file_ledger_sha256: []const u8,
    source_destination_ledger_sha256: []const u8,
    copy_evidence_path: []const u8,
    copy_evidence_sha256: []const u8,
    registration_full_sha256: []const u8,
    registration_path_sha256: []const u8,
    registration_topology_sha256: []const u8,
    registration_non_main_sha256: []const u8,
    before_snapshot: DormantExactAcceptanceSnapshotIdentity,
    after_snapshot: DormantExactAcceptanceSnapshotIdentity,
    validation: DormantAuthorityValidation,
    effects: DormantReadinessNetEffects,
};

const DormantExactAcceptanceParsedReceipt = struct {
    fields: [31][]const u8,
    body_identity: DormantExactAcceptanceSnapshotIdentity,
};

const DormantExactAcceptancePublishFault = enum {
    none,
    before_link,
};

fn requireDormantExactRealAcceptanceGate(token: ?[]const u8) !void {
    if (!builtin.is_test) return error.TestOnlyOperation;
    const value = token orelse return error.SkipZigTest;
    if (!std.mem.eql(u8, value, dormant_exact_real_acceptance_token)) {
        return error.SkipZigTest;
    }
}

fn appendDormantExactAcceptanceString(
    allocator: std.mem.Allocator,
    output: *std.ArrayList(u8),
    field_index: *usize,
    value: []const u8,
) !void {
    if (field_index.* != 0) try output.append(allocator, '\t');
    const encoded = try encodeField(allocator, value);
    defer allocator.free(encoded);
    try output.appendSlice(allocator, encoded);
    field_index.* += 1;
}

fn appendDormantExactAcceptanceInteger(
    allocator: std.mem.Allocator,
    output: *std.ArrayList(u8),
    field_index: *usize,
    value: u64,
) !void {
    if (field_index.* != 0) try output.append(allocator, '\t');
    try output.print(allocator, "{}", .{value});
    field_index.* += 1;
}

fn parseDormantExactAcceptanceInteger(text: []const u8) !u64 {
    if (text.len == 0) return error.NonCanonicalExactAcceptanceReceipt;
    const value = std.fmt.parseInt(u64, text, 10) catch
        return error.NonCanonicalExactAcceptanceReceipt;
    var buffer: [32]u8 = undefined;
    const canonical = std.fmt.bufPrint(&buffer, "{}", .{value}) catch unreachable;
    if (!std.mem.eql(u8, text, canonical)) {
        return error.NonCanonicalExactAcceptanceReceipt;
    }
    return value;
}

fn validateDormantExactAcceptanceHash(text: []const u8) !void {
    validateSha(text) catch return error.NonCanonicalExactAcceptanceReceipt;
}

fn encodeDormantExactAcceptanceReceipt(
    allocator: std.mem.Allocator,
    evidence: DormantExactAcceptanceEvidence,
) ![]u8 {
    var output: std.ArrayList(u8) = .empty;
    errdefer output.deinit(allocator);
    try output.appendSlice(allocator, dormant_exact_real_acceptance_magic);
    try output.append(allocator, '\n');
    try output.appendSlice(allocator, dormant_exact_real_acceptance_header);
    try output.append(allocator, '\n');
    var field_index: usize = 0;
    try appendDormantExactAcceptanceString(
        allocator,
        &output,
        &field_index,
        dormant_exact_real_acceptance_capability,
    );
    try appendDormantExactAcceptanceString(allocator, &output, &field_index, evidence.control_root);
    try appendDormantExactAcceptanceString(allocator, &output, &field_index, evidence.authority_root);
    try appendDormantExactAcceptanceString(allocator, &output, &field_index, evidence.payload_root);
    try appendDormantExactAcceptanceString(allocator, &output, &field_index, evidence.source_root);
    try appendDormantExactAcceptanceString(
        allocator,
        &output,
        &field_index,
        evidence.source_manifest_sha256,
    );
    try appendDormantExactAcceptanceString(
        allocator,
        &output,
        &field_index,
        evidence.source_inventory_sha256,
    );
    try appendDormantExactAcceptanceString(
        allocator,
        &output,
        &field_index,
        evidence.source_file_ledger_sha256,
    );
    try appendDormantExactAcceptanceString(
        allocator,
        &output,
        &field_index,
        evidence.source_destination_ledger_sha256,
    );
    try appendDormantExactAcceptanceString(
        allocator,
        &output,
        &field_index,
        evidence.copy_evidence_path,
    );
    try appendDormantExactAcceptanceString(
        allocator,
        &output,
        &field_index,
        evidence.copy_evidence_sha256,
    );
    try appendDormantExactAcceptanceString(
        allocator,
        &output,
        &field_index,
        evidence.registration_full_sha256,
    );
    try appendDormantExactAcceptanceString(
        allocator,
        &output,
        &field_index,
        evidence.registration_path_sha256,
    );
    try appendDormantExactAcceptanceString(
        allocator,
        &output,
        &field_index,
        evidence.registration_topology_sha256,
    );
    try appendDormantExactAcceptanceString(
        allocator,
        &output,
        &field_index,
        evidence.registration_non_main_sha256,
    );
    try appendDormantExactAcceptanceInteger(
        allocator,
        &output,
        &field_index,
        evidence.before_snapshot.bytes,
    );
    try appendDormantExactAcceptanceString(
        allocator,
        &output,
        &field_index,
        &evidence.before_snapshot.sha256,
    );
    try appendDormantExactAcceptanceInteger(
        allocator,
        &output,
        &field_index,
        evidence.after_snapshot.bytes,
    );
    try appendDormantExactAcceptanceString(
        allocator,
        &output,
        &field_index,
        &evidence.after_snapshot.sha256,
    );
    try appendDormantExactAcceptanceString(
        allocator,
        &output,
        &field_index,
        "validated",
    );
    try appendDormantExactAcceptanceString(
        allocator,
        &output,
        &field_index,
        &evidence.validation.manifest_sha256,
    );
    try appendDormantExactAcceptanceInteger(
        allocator,
        &output,
        &field_index,
        evidence.validation.payload_files,
    );
    try appendDormantExactAcceptanceInteger(
        allocator,
        &output,
        &field_index,
        evidence.validation.payload_bytes,
    );
    try appendDormantExactAcceptanceInteger(
        allocator,
        &output,
        &field_index,
        evidence.validation.objects,
    );
    try appendDormantExactAcceptanceInteger(
        allocator,
        &output,
        &field_index,
        evidence.validation.snapshots,
    );
    try appendDormantExactAcceptanceInteger(
        allocator,
        &output,
        &field_index,
        std.math.cast(u64, evidence.effects.created_paths) orelse
            return error.DormantAcceptanceEffectOverflow,
    );
    try appendDormantExactAcceptanceInteger(
        allocator,
        &output,
        &field_index,
        std.math.cast(u64, evidence.effects.removed_paths) orelse
            return error.DormantAcceptanceEffectOverflow,
    );
    try appendDormantExactAcceptanceInteger(
        allocator,
        &output,
        &field_index,
        std.math.cast(u64, evidence.effects.modified_paths) orelse
            return error.DormantAcceptanceEffectOverflow,
    );
    try appendDormantExactAcceptanceInteger(
        allocator,
        &output,
        &field_index,
        std.math.cast(u64, evidence.effects.publication_path_changes) orelse
            return error.DormantAcceptanceEffectOverflow,
    );
    try appendDormantExactAcceptanceString(
        allocator,
        &output,
        &field_index,
        if (evidence.effects.logical_state_modified) "true" else "false",
    );
    try appendDormantExactAcceptanceString(allocator, &output, &field_index, "complete");
    if (field_index != 31) return error.DormantAcceptanceReceiptFieldCount;
    try output.append(allocator, '\n');

    const body_bytes = std.math.cast(u64, output.items.len) orelse
        return error.DormantAcceptanceReceiptTooLarge;
    const body_sha256 = sha256Hex(output.items);
    try output.appendSlice(allocator, dormant_exact_real_acceptance_identity_header);
    try output.append(allocator, '\n');
    try output.print(allocator, "{}\t{s}\n", .{ body_bytes, &body_sha256 });
    if (output.items.len > dormant_exact_real_acceptance_receipt_max_bytes) {
        return error.DormantAcceptanceReceiptTooLarge;
    }
    return output.toOwnedSlice(allocator);
}

fn parseDormantExactAcceptanceReceipt(
    allocator: std.mem.Allocator,
    input: []const u8,
) !DormantExactAcceptanceParsedReceipt {
    if (input.len == 0 or
        input.len > dormant_exact_real_acceptance_receipt_max_bytes or
        input[input.len - 1] != '\n' or
        std.mem.indexOfScalar(u8, input, '\r') != null)
    {
        return error.NonCanonicalExactAcceptanceReceipt;
    }
    var lines = std.mem.splitScalar(u8, input, '\n');
    const magic = lines.next() orelse return error.NonCanonicalExactAcceptanceReceipt;
    const header = lines.next() orelse return error.NonCanonicalExactAcceptanceReceipt;
    const data = lines.next() orelse return error.NonCanonicalExactAcceptanceReceipt;
    const identity_header = lines.next() orelse return error.NonCanonicalExactAcceptanceReceipt;
    const identity_data = lines.next() orelse return error.NonCanonicalExactAcceptanceReceipt;
    if (!std.mem.eql(u8, magic, dormant_exact_real_acceptance_magic) or
        !std.mem.eql(u8, header, dormant_exact_real_acceptance_header) or
        !std.mem.eql(u8, identity_header, dormant_exact_real_acceptance_identity_header) or
        data.len == 0 or identity_data.len == 0 or
        !std.mem.eql(u8, lines.next() orelse return error.NonCanonicalExactAcceptanceReceipt, "") or
        lines.next() != null)
    {
        return error.NonCanonicalExactAcceptanceReceipt;
    }

    var result: DormantExactAcceptanceParsedReceipt = undefined;
    var fields = std.mem.splitScalar(u8, data, '\t');
    for (&result.fields) |*field| {
        field.* = fields.next() orelse return error.NonCanonicalExactAcceptanceReceipt;
        validateCanonicalField(allocator, field.*) catch
            return error.NonCanonicalExactAcceptanceReceipt;
    }
    if (fields.next() != null or
        !std.mem.eql(u8, result.fields[0], dormant_exact_real_acceptance_capability) or
        !std.mem.eql(u8, result.fields[19], "validated") or
        (!std.mem.eql(u8, result.fields[29], "false") and
            !std.mem.eql(u8, result.fields[29], "true")) or
        !std.mem.eql(u8, result.fields[30], "complete"))
    {
        return error.NonCanonicalExactAcceptanceReceipt;
    }
    for ([_]usize{ 5, 6, 7, 8, 10, 11, 12, 13, 14, 16, 18, 20 }) |index| {
        try validateDormantExactAcceptanceHash(result.fields[index]);
    }
    for ([_]usize{ 15, 17, 21, 22, 23, 24, 25, 26, 27, 28 }) |index| {
        _ = try parseDormantExactAcceptanceInteger(result.fields[index]);
    }

    var identity_fields = std.mem.splitScalar(u8, identity_data, '\t');
    const body_bytes_text = identity_fields.next() orelse
        return error.NonCanonicalExactAcceptanceReceipt;
    const body_sha256_text = identity_fields.next() orelse
        return error.NonCanonicalExactAcceptanceReceipt;
    if (identity_fields.next() != null) return error.NonCanonicalExactAcceptanceReceipt;
    const body_bytes = try parseDormantExactAcceptanceInteger(body_bytes_text);
    try validateDormantExactAcceptanceHash(body_sha256_text);
    const body_len = dormant_exact_real_acceptance_magic.len + 1 +
        dormant_exact_real_acceptance_header.len + 1 + data.len + 1;
    if (body_bytes != body_len or body_len > input.len) {
        return error.DormantAcceptanceReceiptIdentityMismatch;
    }
    const body_sha256 = sha256Hex(input[0..body_len]);
    if (!std.mem.eql(u8, body_sha256_text, &body_sha256)) {
        return error.DormantAcceptanceReceiptIdentityMismatch;
    }
    result.body_identity = .{
        .bytes = body_bytes,
        .sha256 = body_sha256,
    };
    return result;
}

fn validateDormantExactAcceptanceReceipt(
    allocator: std.mem.Allocator,
    input: []const u8,
    expected: DormantExactAcceptanceEvidence,
) !void {
    _ = try parseDormantExactAcceptanceReceipt(allocator, input);
    const canonical = try encodeDormantExactAcceptanceReceipt(allocator, expected);
    defer allocator.free(canonical);
    if (!std.mem.eql(u8, input, canonical)) {
        return error.DormantAcceptanceReceiptEvidenceMismatch;
    }
}

fn readDormantExactAcceptanceReceipt(
    allocator: std.mem.Allocator,
    io: std.Io,
    directory: std.Io.Dir,
    basename: []const u8,
) ![]u8 {
    var file = try directory.openFile(io, basename, .{
        .allow_directory = false,
        .follow_symlinks = false,
    });
    defer file.close(io);
    const stat = try file.stat(io);
    if (stat.kind != .file or
        @as(u16, @intCast(stat.permissions.toMode() & 0o7777)) != 0o644 or
        stat.size == 0 or stat.size > dormant_exact_real_acceptance_receipt_max_bytes)
    {
        return error.DormantAcceptanceReceiptReadBackMismatch;
    }
    const size = std.math.cast(usize, stat.size) orelse
        return error.DormantAcceptanceReceiptReadBackMismatch;
    const bytes = try allocator.alloc(u8, size);
    errdefer allocator.free(bytes);
    var offset: usize = 0;
    while (offset < bytes.len) {
        const count = try file.readPositional(io, &.{bytes[offset..]}, offset);
        if (count == 0) return error.DormantAcceptanceReceiptReadBackMismatch;
        offset += count;
    }
    var extra: [1]u8 = undefined;
    if (try file.readPositional(io, &.{&extra}, bytes.len) != 0) {
        return error.DormantAcceptanceReceiptReadBackMismatch;
    }
    return bytes;
}

fn publishDormantExactAcceptanceReceipt(
    allocator: std.mem.Allocator,
    io: std.Io,
    directory: std.Io.Dir,
    bytes: []const u8,
    expected: DormantExactAcceptanceEvidence,
    fault: DormantExactAcceptancePublishFault,
) !void {
    try validateDormantExactAcceptanceReceipt(allocator, bytes, expected);
    var atomic = try directory.createFileAtomic(
        io,
        dormant_exact_real_acceptance_receipt_basename,
        .{ .permissions = .fromMode(0o600), .replace = false },
    );
    defer atomic.deinit(io);
    try atomic.file.writeStreamingAll(io, bytes);
    try atomic.file.sync(io);
    try atomic.file.setPermissions(io, .fromMode(0o644));
    try atomic.file.sync(io);
    if (fault == .before_link) return error.DormantAcceptanceSyntheticPublicationFailure;
    atomic.link(io) catch |err| switch (err) {
        error.PathAlreadyExists => return error.DormantAcceptanceReceiptCollision,
        else => return err,
    };
    try syncDirectory(directory);
    const readback = try readDormantExactAcceptanceReceipt(
        allocator,
        io,
        directory,
        dormant_exact_real_acceptance_receipt_basename,
    );
    defer allocator.free(readback);
    if (!std.mem.eql(u8, readback, bytes)) {
        return error.DormantAcceptanceReceiptReadBackMismatch;
    }
    try validateDormantExactAcceptanceReceipt(allocator, readback, expected);
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

fn openDormantExactAcceptanceReceiptDirectory(io: std.Io) !std.Io.Dir {
    var repository = try std.Io.Dir.openDirAbsolute(io, main_repository, .{
        .access_sub_paths = true,
        .iterate = true,
        .follow_symlinks = false,
    });
    defer repository.close(io);
    var local_state = try openExistingDir(io, repository, "local-state");
    defer local_state.close(io);
    var validations = try openOrCreateDir(io, local_state, "validations");
    defer validations.close(io);
    return openOrCreateDir(io, validations, "inbox206cq");
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

    const sync_before_root = test_directory_sync_count;
    try prepareStoreRoot(allocator, io, &guard, synthetic_store);
    try std.testing.expect(test_directory_sync_count >= sync_before_root + 2);
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
        store.publishBytesWithFault(rejected_before, .corrupt_incoming),
    );
    var rejected_before_leaf = try store.openObjectLeaf(rejected_before_sha[0..2]);
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
        store.publishBytesWithFault(rejected_after, .corrupt_final),
    );
    var rejected_after_leaf = try store.openObjectLeaf(rejected_after_sha[0..2]);
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
    var collision_leaf = try store.openObjectLeaf(collision_sha[0..2]);
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

    var partial_leaf = try store.openObjectLeaf(object.sha256[0..2]);
    try writeExclusive(io, partial_leaf, "partial", "partial", 0o444);
    try std.testing.expectError(error.PartialOrUnexpectedObject, store.verifyNoPartialObjects());
    try partial_leaf.deleteFile(io, "partial");
    partial_leaf.close(io);
    try store.verifyNoPartialObjects();

    const symlink_sha = "ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff";
    var symlink_leaf = try store.openObjectLeaf(symlink_sha[0..2]);
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
    var directory_leaf = try store.openObjectLeaf(directory_sha[0..2]);
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
    try std.testing.expect(test_directory_sync_count > sync_before_root + 10);
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
