const std = @import("std");
const builtin = @import("builtin");

const Sha256 = std.crypto.hash.sha2.Sha256;
const original_failed_store = "/home/oleg/prog/z_llvm-inbox193-artifact-store-synthetic";
const prior_first_continuation_store = "/home/oleg/prog/z_llvm-inbox193a-artifact-store-synthetic";
const prior_second_continuation_store = "/home/oleg/prog/z_llvm-inbox193b-artifact-store-synthetic";
const synthetic_store = "/home/oleg/prog/z_llvm-inbox193c-artifact-store-synthetic";
const default_store = "/home/oleg/prog/z_llvm-artifacts";
const main_repository = "/home/oleg/prog/z_llvm";
const main_git_common_dir = "/home/oleg/prog/z_llvm/.git";
const expected_path_hash = "f31d8542baafc7b64cd5ee6fe8cc4194842ca696b97a7ffc8df06ce12d553d7e";
const expected_topology_hash = "6c868e3b6d436cfba92a1e2b21dbd616391763961f1cba9b6670b1ed4a6ebb62";
const expected_non_main_hash = "ebc30a376b3db4c6fbf788f49ea85f4ce792471e539c0a89308068efdf96ebbe";

const schema_magic = "zllvm-artifact-manifest-v1";
const schema_header =
    "kind\tlogical_id\tsha256\tbytes\tmode\tmedia_type\tprovenance\treconstruction\tretention_class\tstatus\tkey\ttarget_id\tsnapshot_id\tmember_path\tsnapshot_format\trecipe_sha256\tconstituent_sha256";
const snapshot_format = "ustar+zstd-v1";
const snapshot_recipe =
    "tar-1.35:--format=ustar,--sort=name,--mtime=@0,--owner=0,--group=0,--numeric-owner,--mode=0444,--no-acls,--no-xattrs,--no-selinux,--no-recursion,--null,--files-from;zstd-1.5.5:-T1,-19,--check,--no-progress,-c";
const snapshot_recipe_sha = "cb9f999404a7dd9eb991d73d18078b20d99e82399d1d415eb1afa3398e97113a";
const max_snapshot_members = 1024;

pub const RowKind = enum {
    object,
    logical_ref,
    snapshot,
    snapshot_member,
};

pub const Status = enum {
    active,
    exhausted_evidence,
    future_required,
    superseded,
    absent_unrecoverable,
};

pub const RetentionClass = enum {
    canonical_input,
    irreplaceable_acceptance_evidence,
    reproducible_cache,
    ephemeral_scratch,
};

pub const Row = struct {
    kind: RowKind,
    logical_id: []const u8,
    sha256: []const u8,
    bytes: u64,
    mode: u16,
    media_type: []const u8,
    provenance: []const u8,
    reconstruction: []const u8,
    retention_class: RetentionClass,
    status: Status,
    key: []const u8,
    target_id: []const u8,
    snapshot_id: []const u8,
    member_path: []const u8,
    snapshot_format: []const u8,
    recipe_sha256: []const u8,
    constituent_sha256: []const u8,
};

pub const Manifest = struct {
    storage: []u8,
    rows: []Row,

    pub fn deinit(manifest: *Manifest, allocator: std.mem.Allocator) void {
        allocator.free(manifest.rows);
        allocator.free(manifest.storage);
        manifest.* = undefined;
    }
};

pub const RegistrationSnapshot = struct {
    raw: []u8,
    paths: [][]const u8,
    full_hash: [64]u8,
    path_hash: [64]u8,
    topology_hash: [64]u8,
    non_main_hash: [64]u8,
    repository_tmp_count: usize,
    system_tmp_count: usize,
    other_count: usize,

    pub fn deinit(snapshot: *RegistrationSnapshot, allocator: std.mem.Allocator) void {
        allocator.free(snapshot.paths);
        allocator.free(snapshot.raw);
        snapshot.* = undefined;
    }

    pub fn count(snapshot: RegistrationSnapshot) usize {
        return snapshot.paths.len;
    }

    pub fn eql(a: RegistrationSnapshot, b: RegistrationSnapshot) bool {
        return std.mem.eql(u8, &a.full_hash, &b.full_hash) and
            std.mem.eql(u8, &a.path_hash, &b.path_hash) and
            std.mem.eql(u8, &a.topology_hash, &b.topology_hash) and
            std.mem.eql(u8, &a.non_main_hash, &b.non_main_hash);
    }
};

pub const RegistrationGuard = struct {
    allocator: std.mem.Allocator,
    io: std.Io,
    frozen: RegistrationSnapshot,

    pub fn init(allocator: std.mem.Allocator, io: std.Io) !RegistrationGuard {
        const frozen = try captureRegistration(allocator, io);
        errdefer {
            var mutable = frozen;
            mutable.deinit(allocator);
        }
        try validateExpectedRegistration(frozen);
        return .{ .allocator = allocator, .io = io, .frozen = frozen };
    }

    pub fn deinit(guard: *RegistrationGuard) void {
        guard.frozen.deinit(guard.allocator);
        guard.* = undefined;
    }

    pub fn assertCurrent(guard: *const RegistrationGuard) !void {
        var current = try captureRegistration(guard.allocator, guard.io);
        defer current.deinit(guard.allocator);
        if (!guard.frozen.eql(current)) return error.RegisteredWorktreeDrift;
    }

    pub fn assertStoreRoot(guard: *const RegistrationGuard, absolute_path: []const u8) !void {
        try guard.assertDisjointFromEveryRegistration(absolute_path);
    }

    pub fn assertReadSource(
        guard: *const RegistrationGuard,
        bounded_root: []const u8,
        absolute_path: []const u8,
    ) !void {
        const normalized_root = try normalizedAbsolute(guard.allocator, bounded_root);
        defer guard.allocator.free(normalized_root);
        const normalized_path = try normalizedAbsolute(guard.allocator, absolute_path);
        defer guard.allocator.free(normalized_path);
        if (!std.mem.eql(u8, normalized_root, bounded_root) or
            !std.mem.eql(u8, normalized_path, absolute_path))
        {
            return error.PathNotNormalized;
        }
        if (!pathContains(main_repository, bounded_root) or
            !pathContains(bounded_root, absolute_path))
        {
            return error.ReadSourceOutsideBound;
        }
        for (guard.frozen.paths[1..]) |protected| {
            if (pathContains(protected, bounded_root) or
                pathContains(protected, absolute_path) or
                pathContains(bounded_root, protected))
            {
                return error.RegisteredWorktreeOverlap;
            }
        }
    }

    pub fn assertSyntheticWrite(
        guard: *const RegistrationGuard,
        store_root: []const u8,
        absolute_path: []const u8,
    ) !void {
        try guard.assertStoreRoot(store_root);
        const normalized = try normalizedAbsolute(guard.allocator, absolute_path);
        defer guard.allocator.free(normalized);
        if (!std.mem.eql(u8, normalized, absolute_path)) return error.PathNotNormalized;
        if (!pathContains(store_root, absolute_path)) return error.WriteOutsideSyntheticStore;
    }

    fn assertDisjointFromEveryRegistration(
        guard: *const RegistrationGuard,
        absolute_path: []const u8,
    ) !void {
        if (!std.fs.path.isAbsolute(absolute_path)) return error.PathNotAbsolute;
        const normalized = try normalizedAbsolute(guard.allocator, absolute_path);
        defer guard.allocator.free(normalized);
        if (!std.mem.eql(u8, normalized, absolute_path)) return error.PathNotNormalized;
        for (guard.frozen.paths) |protected| {
            if (pathContains(protected, absolute_path) or pathContains(absolute_path, protected)) {
                return error.RegisteredWorktreeOverlap;
            }
        }
    }
};

pub const FileIdentity = struct {
    sha256: [64]u8,
    bytes: u64,
    mode: u16,
    key: []u8,

    pub fn deinit(identity: *FileIdentity, allocator: std.mem.Allocator) void {
        allocator.free(identity.key);
        identity.* = undefined;
    }
};

pub const SnapshotIdentity = struct {
    archive: FileIdentity,
    constituent: FileIdentity,
    member_keys: [][]u8,

    pub fn deinit(snapshot: *SnapshotIdentity, allocator: std.mem.Allocator) void {
        snapshot.archive.deinit(allocator);
        snapshot.constituent.deinit(allocator);
        for (snapshot.member_keys) |key| allocator.free(key);
        allocator.free(snapshot.member_keys);
        snapshot.* = undefined;
    }
};

pub const CapacityObservation = struct {
    free_bytes: u64,
    free_inodes: u64,
};

pub const CapacityRequirement = struct {
    validation_reserve: u64,
    primary_bytes: u64,
    snapshot_bound: u64,
    manifest_bound: u64,
    compatibility_peak: u64 = 0,
    required_inodes: u64,

    pub fn requiredBytes(requirement: CapacityRequirement) !u64 {
        var total = try std.math.add(u64, requirement.validation_reserve, requirement.primary_bytes);
        total = try std.math.add(u64, total, requirement.snapshot_bound);
        total = try std.math.add(u64, total, requirement.manifest_bound);
        return std.math.add(u64, total, requirement.compatibility_peak);
    }

    pub fn validate(requirement: CapacityRequirement, observed: CapacityObservation) !void {
        if (observed.free_bytes < try requirement.requiredBytes()) return error.InsufficientFreeBytes;
        if (observed.free_inodes < requirement.required_inodes) return error.InsufficientFreeInodes;
    }
};

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
    if (!std.mem.eql(u8, command, "resolve-authority") or args.next() != null) {
        return error.UnsupportedCommand;
    }
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
    var buffer: [1024]u8 = undefined;
    var writer = std.Io.File.stdout().writer(io, &buffer);
    try writer.interface.print("{s}\n", .{resolved});
    try writer.interface.flush();
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

pub fn parseManifest(allocator: std.mem.Allocator, text: []const u8) !Manifest {
    if (text.len == 0 or text[text.len - 1] != '\n') return error.NonCanonicalManifest;
    const storage = try allocator.dupe(u8, text);
    errdefer allocator.free(storage);
    var lines = std.mem.splitScalar(u8, storage, '\n');
    if (!std.mem.eql(u8, lines.next() orelse return error.MissingSchemaMagic, schema_magic)) {
        return error.UnknownSchemaVersion;
    }
    if (!std.mem.eql(u8, lines.next() orelse return error.MissingSchemaHeader, schema_header)) {
        return error.UnknownOrReorderedField;
    }
    var rows: std.ArrayList(Row) = .empty;
    errdefer rows.deinit(allocator);
    while (lines.next()) |line| {
        if (line.len == 0) {
            if (lines.peek() == null) break;
            return error.EmptyManifestRow;
        }
        var fields: [17][]const u8 = undefined;
        var field_it = std.mem.splitScalar(u8, line, '\t');
        for (&fields) |*field| field.* = field_it.next() orelse return error.MissingManifestField;
        if (field_it.next() != null) return error.UnknownManifestField;
        for (fields) |field| try validateCanonicalField(allocator, field);
        const row: Row = .{
            .kind = parseEnum(RowKind, fields[0]) orelse return error.UnknownRowKind,
            .logical_id = fields[1],
            .sha256 = fields[2],
            .bytes = std.fmt.parseInt(u64, fields[3], 10) catch return error.InvalidByteCount,
            .mode = std.fmt.parseInt(u16, fields[4], 8) catch return error.InvalidMode,
            .media_type = fields[5],
            .provenance = fields[6],
            .reconstruction = fields[7],
            .retention_class = parseEnum(RetentionClass, fields[8]) orelse
                return error.UnknownRetentionClass,
            .status = parseEnum(Status, fields[9]) orelse return error.UnknownStatus,
            .key = fields[10],
            .target_id = fields[11],
            .snapshot_id = fields[12],
            .member_path = fields[13],
            .snapshot_format = fields[14],
            .recipe_sha256 = fields[15],
            .constituent_sha256 = fields[16],
        };
        try validateLogicalId(row.logical_id);
        if (row.mode > 0o7777) return error.InvalidMode;
        for (rows.items) |prior| {
            if (std.mem.eql(u8, prior.logical_id, row.logical_id)) return error.DuplicateLogicalId;
        }
        try validateRowShape(row);
        try rows.append(allocator, row);
    }
    const owned = try rows.toOwnedSlice(allocator);
    errdefer allocator.free(owned);
    const manifest: Manifest = .{ .storage = storage, .rows = owned };
    try validateRelationships(manifest);
    return manifest;
}

pub fn encodeManifest(allocator: std.mem.Allocator, manifest: Manifest) ![]u8 {
    var output: std.ArrayList(u8) = .empty;
    errdefer output.deinit(allocator);
    try output.appendSlice(allocator, schema_magic);
    try output.append(allocator, '\n');
    try output.appendSlice(allocator, schema_header);
    try output.append(allocator, '\n');
    for (manifest.rows) |row| {
        try output.print(allocator, "{s}\t{s}\t{s}\t{}\t{o}\t{s}\t{s}\t{s}\t{s}\t{s}\t{s}\t{s}\t{s}\t{s}\t{s}\t{s}\t{s}\n", .{
            externalEnumName(row.kind),
            row.logical_id,
            row.sha256,
            row.bytes,
            row.mode,
            row.media_type,
            row.provenance,
            row.reconstruction,
            externalEnumName(row.retention_class),
            externalEnumName(row.status),
            row.key,
            row.target_id,
            row.snapshot_id,
            row.member_path,
            row.snapshot_format,
            row.recipe_sha256,
            row.constituent_sha256,
        });
    }
    return output.toOwnedSlice(allocator);
}

pub fn parseRegistration(allocator: std.mem.Allocator, raw_input: []const u8) !RegistrationSnapshot {
    if (!std.mem.endsWith(u8, raw_input, "\n\n")) return error.NonCanonicalRegistrationRecord;
    const raw = try allocator.dupe(u8, raw_input);
    errdefer allocator.free(raw);
    var paths_list: std.ArrayList([]const u8) = .empty;
    errdefer paths_list.deinit(allocator);
    var path_record: std.ArrayList(u8) = .empty;
    defer path_record.deinit(allocator);
    var topology_record: std.ArrayList(u8) = .empty;
    defer topology_record.deinit(allocator);
    var repo_count: usize = 0;
    var tmp_count: usize = 0;
    var other_count: usize = 0;

    var lines = std.mem.splitScalar(u8, raw, '\n');
    while (lines.next()) |line| {
        if (std.mem.startsWith(u8, line, "worktree ")) {
            const path = line["worktree ".len..];
            if (!std.fs.path.isAbsolute(path)) return error.NonCanonicalRegistrationRecord;
            for (paths_list.items) |prior| {
                if (std.mem.eql(u8, prior, path)) return error.DuplicateRegistration;
            }
            try paths_list.append(allocator, path);
            try path_record.appendSlice(allocator, path);
            try path_record.append(allocator, '\n');
            try topology_record.appendSlice(allocator, path);
            try topology_record.append(allocator, '\n');
            if (std.mem.startsWith(u8, path, "/home/oleg/prog/z_llvm/tmp/")) {
                repo_count += 1;
            } else if (std.mem.startsWith(u8, path, "/tmp/")) {
                tmp_count += 1;
            } else {
                other_count += 1;
            }
        } else if (std.mem.startsWith(u8, line, "branch ") or
            std.mem.eql(u8, line, "detached") or
            std.mem.startsWith(u8, line, "locked") or
            std.mem.startsWith(u8, line, "prunable"))
        {
            try topology_record.appendSlice(allocator, line);
            try topology_record.append(allocator, '\n');
        } else if (line.len == 0 or std.mem.startsWith(u8, line, "HEAD ")) {
            continue;
        } else {
            return error.UnknownRegistrationField;
        }
    }
    if (paths_list.items.len == 0) return error.EmptyRegistration;
    const first_separator = std.mem.indexOf(u8, raw, "\n\n") orelse
        return error.NonCanonicalRegistrationRecord;
    const non_main = raw[first_separator + 2 ..];
    return .{
        .raw = raw,
        .paths = try paths_list.toOwnedSlice(allocator),
        .full_hash = sha256Hex(raw),
        .path_hash = sha256Hex(path_record.items),
        .topology_hash = sha256Hex(topology_record.items),
        .non_main_hash = sha256Hex(non_main),
        .repository_tmp_count = repo_count,
        .system_tmp_count = tmp_count,
        .other_count = other_count,
    };
}

fn captureRegistration(allocator: std.mem.Allocator, io: std.Io) !RegistrationSnapshot {
    const result = try std.process.run(allocator, io, .{
        .argv = &.{
            "/usr/bin/git",
            "--git-dir=" ++ main_git_common_dir,
            "worktree",
            "list",
            "--porcelain",
        },
        .stdout_limit = .limited(1024 * 1024),
        .stderr_limit = .limited(1024 * 1024),
    });
    defer freeRunResult(allocator, result);
    if (!termSuccess(result.term)) return error.RegistrationInventoryFailed;
    return parseRegistration(allocator, result.stdout);
}

fn validateExpectedRegistration(snapshot: RegistrationSnapshot) !void {
    if (snapshot.count() != 43 or
        snapshot.repository_tmp_count != 33 or
        snapshot.system_tmp_count != 8 or
        snapshot.other_count != 2 or
        !std.mem.eql(u8, &snapshot.path_hash, expected_path_hash) or
        !std.mem.eql(u8, &snapshot.topology_hash, expected_topology_hash) or
        !std.mem.eql(u8, &snapshot.non_main_hash, expected_non_main_hash))
    {
        return error.UnexpectedRegistrationInventory;
    }
}

fn validateRowShape(row: Row) !void {
    try validateSha(row.sha256);
    try validateRelativeKey(row.key);
    switch (row.kind) {
        .object => {
            const split = splitObjectKey(row.key) orelse return error.InvalidObjectRow;
            if (row.target_id.len != 1 or row.target_id[0] != '-' or
                row.snapshot_id.len != 1 or row.snapshot_id[0] != '-' or
                row.member_path.len != 1 or row.member_path[0] != '-' or
                !isDash(row.snapshot_format) or
                !isDash(row.recipe_sha256) or
                !isDash(row.constituent_sha256) or
                !std.mem.eql(u8, split.prefix, row.sha256[0..2]) or
                !std.mem.eql(u8, split.basename, row.sha256[2..]))
            {
                return error.InvalidObjectRow;
            }
        },
        .logical_ref => {
            try validateLogicalId(row.target_id);
            if (row.snapshot_id.len != 1 or row.snapshot_id[0] != '-' or
                row.member_path.len != 1 or row.member_path[0] != '-' or
                !isDash(row.snapshot_format) or
                !isDash(row.recipe_sha256) or
                !isDash(row.constituent_sha256))
            {
                return error.InvalidLogicalRefRow;
            }
        },
        .snapshot => {
            const split = splitSnapshotKey(row.key) orelse return error.InvalidSnapshotRow;
            if (row.target_id.len != 1 or row.target_id[0] != '-' or
                row.snapshot_id.len != 1 or row.snapshot_id[0] != '-' or
                row.member_path.len != 1 or row.member_path[0] != '-' or
                !std.mem.eql(u8, row.snapshot_format, snapshot_format) or
                !std.mem.eql(u8, row.recipe_sha256, snapshot_recipe_sha) or
                !std.mem.eql(u8, split.prefix, row.sha256[0..2]) or
                !std.mem.eql(u8, split.basename[0..62], row.sha256[2..]))
            {
                return error.InvalidSnapshotRow;
            }
            try validateSha(row.constituent_sha256);
        },
        .snapshot_member => {
            try validateLogicalId(row.target_id);
            try validateLogicalId(row.snapshot_id);
            try validateRelativeKey(row.member_path);
            if (!isDash(row.snapshot_format) or
                !isDash(row.recipe_sha256) or
                !isDash(row.constituent_sha256))
            {
                return error.InvalidSnapshotMemberRow;
            }
        },
    }
}

fn isDash(text: []const u8) bool {
    return text.len == 1 and text[0] == '-';
}

fn validateRelationships(manifest: Manifest) !void {
    for (manifest.rows, 0..) |row, row_index| {
        for (manifest.rows[0..row_index]) |prior| {
            if (std.mem.eql(u8, prior.key, row.key)) {
                if (!sameIdentity(prior, row)) return error.ConflictingManifestKey;
                const object_member_pair =
                    (prior.kind == .object and row.kind == .snapshot_member) or
                    (prior.kind == .snapshot_member and row.kind == .object);
                const separate_snapshot_members =
                    prior.kind == .snapshot_member and row.kind == .snapshot_member and
                    !std.mem.eql(u8, prior.snapshot_id, row.snapshot_id);
                if (!object_member_pair and !separate_snapshot_members) {
                    return error.AmbiguousManifestKey;
                }
            }
        }
        switch (row.kind) {
            .object => {},
            .logical_ref => {
                const target = findRow(manifest, row.target_id) orelse return error.MissingTargetObject;
                if (target.kind != .object or !sameIdentity(row, target)) return error.LogicalRefMismatch;
            },
            .snapshot => {
                var constituent_matches: usize = 0;
                var member_count: usize = 0;
                for (manifest.rows) |candidate| {
                    if (candidate.kind == .object and
                        std.mem.eql(u8, candidate.sha256, row.constituent_sha256))
                    {
                        constituent_matches += 1;
                    }
                    if (candidate.kind == .snapshot_member and
                        std.mem.eql(u8, candidate.snapshot_id, row.logical_id))
                    {
                        member_count += 1;
                    }
                }
                if (constituent_matches != 1) return error.InvalidSnapshotConstituent;
                if (member_count == 0 or member_count > max_snapshot_members) {
                    return error.InvalidSnapshotMemberCount;
                }
            },
            .snapshot_member => {
                const target = findRow(manifest, row.target_id) orelse return error.MissingTargetObject;
                const snapshot = findRow(manifest, row.snapshot_id) orelse return error.MissingSnapshot;
                if (target.kind != .object or snapshot.kind != .snapshot or
                    !sameIdentity(row, target) or !std.mem.eql(u8, row.member_path, target.key))
                {
                    return error.SnapshotMemberMismatch;
                }
                for (manifest.rows[0..row_index]) |other| {
                    if (other.kind == .snapshot_member and
                        std.mem.eql(u8, row.snapshot_id, other.snapshot_id) and
                        std.mem.eql(u8, row.member_path, other.member_path))
                    {
                        return error.DuplicateSnapshotMember;
                    }
                }
            },
        }
    }
}

fn findRow(manifest: Manifest, logical_id: []const u8) ?Row {
    for (manifest.rows) |row| {
        if (std.mem.eql(u8, row.logical_id, logical_id)) return row;
    }
    return null;
}

fn sameIdentity(a: Row, b: Row) bool {
    return std.mem.eql(u8, a.sha256, b.sha256) and a.bytes == b.bytes and a.mode == b.mode;
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

fn parseEnum(comptime E: type, text: []const u8) ?E {
    inline for (@typeInfo(E).@"enum".fields) |field| {
        if (externalTagMatches(field.name, text)) return @enumFromInt(field.value);
    }
    return null;
}

fn externalTagMatches(comptime internal: []const u8, external: []const u8) bool {
    if (internal.len != external.len) return false;
    for (internal, external) |internal_byte, external_byte| {
        if ((if (internal_byte == '_') '-' else internal_byte) != external_byte) return false;
    }
    return true;
}

fn externalEnumName(value: anytype) []const u8 {
    return switch (@TypeOf(value)) {
        RowKind => switch (value) {
            .object => "object",
            .logical_ref => "logical-ref",
            .snapshot => "snapshot",
            .snapshot_member => "snapshot-member",
        },
        Status => switch (value) {
            .active => "active",
            .exhausted_evidence => "exhausted-evidence",
            .future_required => "future-required",
            .superseded => "superseded",
            .absent_unrecoverable => "absent-unrecoverable",
        },
        RetentionClass => switch (value) {
            .canonical_input => "canonical-input",
            .irreplaceable_acceptance_evidence => "irreplaceable-acceptance-evidence",
            .reproducible_cache => "reproducible-cache",
            .ephemeral_scratch => "ephemeral-scratch",
        },
        else => @compileError("unsupported external enum"),
    };
}

fn validateCanonicalField(allocator: std.mem.Allocator, encoded: []const u8) !void {
    if (encoded.len == 0) return error.EmptyManifestField;
    var decoded: std.ArrayList(u8) = .empty;
    defer decoded.deinit(allocator);
    var index: usize = 0;
    while (index < encoded.len) {
        const byte = encoded[index];
        if (byte == '%') {
            if (index + 2 >= encoded.len or
                !std.ascii.isHex(encoded[index + 1]) or
                !std.ascii.isHex(encoded[index + 2]) or
                std.ascii.isLower(encoded[index + 1]) or
                std.ascii.isLower(encoded[index + 2]))
            {
                return error.InvalidPercentEncoding;
            }
            const value = std.fmt.parseInt(u8, encoded[index + 1 .. index + 3], 16) catch
                return error.InvalidPercentEncoding;
            try decoded.append(allocator, value);
            index += 3;
        } else {
            if (byte == '\t' or byte == '\r' or byte == '\n' or byte == 0 or byte == '\\' or
                byte < 0x20 or byte >= 0x7f)
            {
                return error.UnencodedUnsafeByte;
            }
            try decoded.append(allocator, byte);
            index += 1;
        }
    }
    const reencoded = try encodeField(allocator, decoded.items);
    defer allocator.free(reencoded);
    if (!std.mem.eql(u8, reencoded, encoded)) return error.NonCanonicalPercentEncoding;
}

fn encodeField(allocator: std.mem.Allocator, decoded: []const u8) ![]u8 {
    var encoded: std.ArrayList(u8) = .empty;
    errdefer encoded.deinit(allocator);
    const hex = "0123456789ABCDEF";
    for (decoded) |byte| {
        const safe = byte >= 0x20 and byte < 0x7f and
            byte != '%' and byte != '\\' and byte != '\t' and byte != '\r' and byte != '\n';
        if (safe) {
            try encoded.append(allocator, byte);
        } else {
            try encoded.appendSlice(allocator, &.{ '%', hex[byte >> 4], hex[byte & 0xf] });
        }
    }
    return encoded.toOwnedSlice(allocator);
}

fn validateLogicalId(id: []const u8) !void {
    if (id.len == 0 or !isLowerAlphaNumeric(id[0])) return error.InvalidLogicalId;
    try validateRelativeKey(id);
}

fn validateRelativeKey(key: []const u8) !void {
    if (key.len == 0 or std.fs.path.isAbsolute(key) or key[0] == '/' or key[key.len - 1] == '/') {
        return error.UnsafeRelativeKey;
    }
    var segments = std.mem.splitScalar(u8, key, '/');
    while (segments.next()) |segment| {
        if (segment.len == 0 or segment.len > 255 or
            std.mem.eql(u8, segment, ".") or std.mem.eql(u8, segment, ".."))
        {
            return error.UnsafeRelativeKey;
        }
        for (segment) |byte| {
            if (!isLowerAlphaNumeric(byte) and byte != '.' and byte != '_' and byte != '-') {
                return error.UnsafeRelativeKey;
            }
        }
    }
}

fn validateSha(text: []const u8) !void {
    if (text.len != 64 or !isLowerHex(text)) return error.InvalidSha256;
}

fn isLowerHex(text: []const u8) bool {
    for (text) |byte| {
        if (!std.ascii.isDigit(byte) and !(byte >= 'a' and byte <= 'f')) return false;
    }
    return true;
}

fn isLowerAlphaNumeric(byte: u8) bool {
    return std.ascii.isDigit(byte) or (byte >= 'a' and byte <= 'z');
}

fn sha256Hex(bytes: []const u8) [64]u8 {
    var digest: [Sha256.digest_length]u8 = undefined;
    Sha256.hash(bytes, &digest, .{});
    return std.fmt.bytesToHex(digest, .lower);
}

fn objectKey(allocator: std.mem.Allocator, sha: []const u8) ![]u8 {
    try validateSha(sha);
    return std.fmt.allocPrint(allocator, "objects/sha256/{s}/{s}", .{ sha[0..2], sha[2..] });
}

fn snapshotKey(allocator: std.mem.Allocator, sha: []const u8) ![]u8 {
    try validateSha(sha);
    return std.fmt.allocPrint(allocator, "snapshots/sha256/{s}/{s}.tar.zst", .{ sha[0..2], sha[2..] });
}

const KeySplit = struct { prefix: []const u8, basename: []const u8 };

fn splitObjectKey(key: []const u8) ?KeySplit {
    const prefix = "objects/sha256/";
    if (!std.mem.startsWith(u8, key, prefix) or key.len != prefix.len + 2 + 1 + 62) return null;
    if (key[prefix.len + 2] != '/') return null;
    const a = key[prefix.len .. prefix.len + 2];
    const b = key[prefix.len + 3 ..];
    if (!isLowerHex(a) or !isLowerHex(b)) return null;
    return .{ .prefix = a, .basename = b };
}

fn splitSnapshotKey(key: []const u8) ?KeySplit {
    const prefix = "snapshots/sha256/";
    const suffix = ".tar.zst";
    if (!std.mem.startsWith(u8, key, prefix) or !std.mem.endsWith(u8, key, suffix)) return null;
    if (key.len != prefix.len + 2 + 1 + 62 + suffix.len or key[prefix.len + 2] != '/') return null;
    const a = key[prefix.len .. prefix.len + 2];
    const b = key[prefix.len + 3 ..];
    if (!isLowerHex(a) or !isLowerHex(b[0..62])) return null;
    return .{ .prefix = a, .basename = b };
}

fn pathContains(parent: []const u8, child: []const u8) bool {
    if (std.mem.eql(u8, parent, child)) return true;
    return std.mem.startsWith(u8, child, parent) and child.len > parent.len and
        parent[parent.len - 1] != '/' and child[parent.len] == '/';
}

fn normalizedAbsolute(allocator: std.mem.Allocator, path: []const u8) ![]u8 {
    if (!std.fs.path.isAbsolute(path)) return error.PathNotAbsolute;
    return std.fs.path.resolve(allocator, &.{path});
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

fn sameFileIdentity(a: FileIdentity, b: FileIdentity) bool {
    return std.mem.eql(u8, &a.sha256, &b.sha256) and
        a.bytes == b.bytes and
        a.mode == b.mode;
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

fn verifyRelativeFile(
    allocator: std.mem.Allocator,
    io: std.Io,
    dir: std.Io.Dir,
    basename: []const u8,
    expected_mode: u16,
) !FileIdentity {
    var file = try dir.openFile(io, basename, .{
        .allow_directory = false,
        .follow_symlinks = false,
    });
    defer file.close(io);
    return identityOfOpenFile(allocator, io, file, expected_mode);
}

fn identityOfOpenFile(
    allocator: std.mem.Allocator,
    io: std.Io,
    file: std.Io.File,
    expected_mode: u16,
) !FileIdentity {
    var identity = try identityOfOpenFileAnyMode(allocator, io, file);
    errdefer identity.deinit(allocator);
    if (identity.mode != expected_mode) return error.ModeMismatch;
    return identity;
}

fn identityOfOpenFileAnyMode(
    allocator: std.mem.Allocator,
    io: std.Io,
    file: std.Io.File,
) !FileIdentity {
    const stat = try file.stat(io);
    if (stat.kind != .file) return error.NotRegularFile;
    const actual_mode: u16 = @intCast(stat.permissions.toMode() & 0o7777);
    var hasher = Sha256.init(.{});
    var offset: u64 = 0;
    var buffer: [64 * 1024]u8 = undefined;
    while (true) {
        const count = try file.readPositional(io, &.{&buffer}, offset);
        if (count == 0) break;
        hasher.update(buffer[0..count]);
        offset += count;
    }
    var digest: [Sha256.digest_length]u8 = undefined;
    hasher.final(&digest);
    return .{
        .sha256 = std.fmt.bytesToHex(digest, .lower),
        .bytes = offset,
        .mode = actual_mode,
        .key = try allocator.dupe(u8, "-"),
    };
}

fn copyFileContents(io: std.Io, source: std.Io.File, destination: std.Io.File) !void {
    var offset: u64 = 0;
    var buffer: [64 * 1024]u8 = undefined;
    while (true) {
        const count = try source.readPositional(io, &.{&buffer}, offset);
        if (count == 0) break;
        try destination.writePositionalAll(io, buffer[0..count], offset);
        offset += count;
    }
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

const LinuxStatFs = extern struct {
    fs_type: i64,
    block_size: i64,
    blocks: u64,
    blocks_free: u64,
    blocks_available: u64,
    files: u64,
    files_free: u64,
    fs_id: [2]i32,
    name_length: i64,
    fragment_size: i64,
    flags: i64,
    spare: [4]i64,
};

fn freshCapacity(dir: std.Io.Dir) !CapacityObservation {
    if (builtin.os.tag != .linux or builtin.cpu.arch != .x86_64) {
        @compileError("INBOX-193A descriptor capacity requires the pinned x86_64-linux host");
    }
    var info: LinuxStatFs = undefined;
    const rc = std.os.linux.syscall2(
        .fstatfs,
        @as(usize, @bitCast(@as(isize, dir.handle))),
        @intFromPtr(&info),
    );
    switch (std.os.linux.errno(rc)) {
        .SUCCESS => {},
        else => |err| return std.posix.unexpectedErrno(err),
    }
    const signed_unit = if (info.fragment_size > 0) info.fragment_size else info.block_size;
    if (signed_unit <= 0) return error.InvalidCapacityObservation;
    return capacityFromFields(info.blocks_available, @intCast(signed_unit), info.files_free);
}

fn capacityFromFields(
    available_blocks: u64,
    block_size: u64,
    free_inodes: u64,
) !CapacityObservation {
    if (block_size == 0) return error.InvalidCapacityObservation;
    return .{
        .free_bytes = try std.math.mul(u64, available_blocks, block_size),
        .free_inodes = free_inodes,
    };
}

fn termSuccess(term: std.process.Child.Term) bool {
    return switch (term) {
        .exited => |code| code == 0,
        else => false,
    };
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

fn freeRunResult(allocator: std.mem.Allocator, result: std.process.RunResult) void {
    allocator.free(result.stdout);
    allocator.free(result.stderr);
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

test "manifest schema round trips and rejects unsafe or unknown input" {
    const allocator = std.testing.allocator;
    const zero_sha = "0000000000000000000000000000000000000000000000000000000000000000";
    const one_sha = "1111111111111111111111111111111111111111111111111111111111111111";
    const two_sha = "2222222222222222222222222222222222222222222222222222222222222222";
    const text = try std.fmt.allocPrint(
        allocator,
        schema_magic ++ "\n" ++ schema_header ++ "\n" ++
            "object\tobject.one\t{s}\t1\t444\tapplication/octet-stream\tproof\tunavailable\tcanonical-input\tactive\tobjects/sha256/00/{s}\t-\t-\t-\t-\t-\t-\n" ++
            "object\tconstituent.one\t{s}\t2\t444\ttext/tab-separated-values\tproof\tunavailable\treproducible-cache\tactive\tobjects/sha256/22/{s}\t-\t-\t-\t-\t-\t-\n" ++
            "snapshot\tsnapshot.one\t{s}\t2\t444\tapplication/zstd+tar\tproof\tunavailable\tirreplaceable-acceptance-evidence\tactive\tsnapshots/sha256/11/{s}.tar.zst\t-\t-\t-\t{s}\t{s}\t{s}\n" ++
            "snapshot-member\tmember.one\t{s}\t1\t444\tapplication/octet-stream\tproof\tunavailable\tcanonical-input\tactive\tobjects/sha256/00/{s}\tobject.one\tsnapshot.one\tobjects/sha256/00/{s}\t-\t-\t-\n",
        .{
            zero_sha,
            zero_sha[2..],
            two_sha,
            two_sha[2..],
            one_sha,
            one_sha[2..],
            snapshot_format,
            snapshot_recipe_sha,
            two_sha,
            zero_sha,
            zero_sha[2..],
            zero_sha[2..],
        },
    );
    defer allocator.free(text);
    var manifest = try parseManifest(allocator, text);
    defer manifest.deinit(allocator);
    const encoded = try encodeManifest(allocator, manifest);
    defer allocator.free(encoded);
    try std.testing.expectEqualStrings(text, encoded);

    try std.testing.expectError(error.UnsafeRelativeKey, validateRelativeKey("../escape"));
    try std.testing.expectError(error.UnsafeRelativeKey, validateRelativeKey("a//b"));
    try std.testing.expectError(error.InvalidLogicalId, validateLogicalId("-bad"));
    try std.testing.expectError(error.InvalidPercentEncoding, validateCanonicalField(allocator, "%2f"));

    const duplicate = try std.fmt.allocPrint(
        allocator,
        schema_magic ++ "\n" ++ schema_header ++ "\n" ++
            "object\tobject.one\t{s}\t1\t444\tapplication/octet-stream\tproof\tunavailable\tcanonical-input\tactive\tobjects/sha256/00/{s}\t-\t-\t-\t-\t-\t-\n" ++
            "object\tobject.one\t{s}\t1\t444\tapplication/octet-stream\tproof\tunavailable\tcanonical-input\tactive\tobjects/sha256/00/{s}\t-\t-\t-\t-\t-\t-\n",
        .{ zero_sha, zero_sha[2..], zero_sha, zero_sha[2..] },
    );
    defer allocator.free(duplicate);
    try std.testing.expectError(error.DuplicateLogicalId, parseManifest(allocator, duplicate));

    const ambiguous_key = try std.fmt.allocPrint(
        allocator,
        schema_magic ++ "\n" ++ schema_header ++ "\n" ++
            "object\tobject.one\t{s}\t1\t444\tapplication/octet-stream\tproof\tunavailable\tcanonical-input\tactive\tobjects/sha256/00/{s}\t-\t-\t-\t-\t-\t-\n" ++
            "object\tobject.two\t{s}\t1\t444\tapplication/octet-stream\tproof\tunavailable\tcanonical-input\tactive\tobjects/sha256/00/{s}\t-\t-\t-\t-\t-\t-\n",
        .{ zero_sha, zero_sha[2..], zero_sha, zero_sha[2..] },
    );
    defer allocator.free(ambiguous_key);
    try std.testing.expectError(error.AmbiguousManifestKey, parseManifest(allocator, ambiguous_key));

    const unknown = try std.mem.replaceOwned(
        u8,
        allocator,
        text,
        "snapshot-member",
        "unknown-kind",
    );
    defer allocator.free(unknown);
    try std.testing.expectError(error.UnknownRowKind, parseManifest(allocator, unknown));

    const extra_field = try std.fmt.allocPrint(
        allocator,
        schema_magic ++ "\n" ++ schema_header ++ "\n" ++
            "object\tobject.one\t{s}\t1\t444\tapplication/octet-stream\tproof\tunavailable\tcanonical-input\tactive\tobjects/sha256/00/{s}\t-\t-\t-\t-\t-\t-\textra\n",
        .{ zero_sha, zero_sha[2..] },
    );
    defer allocator.free(extra_field);
    try std.testing.expectError(error.UnknownManifestField, parseManifest(allocator, extra_field));

    const missing_target = try std.fmt.allocPrint(
        allocator,
        schema_magic ++ "\n" ++ schema_header ++ "\n" ++
            "logical-ref\tref.one\t{s}\t1\t444\tapplication/octet-stream\tproof\tunavailable\tcanonical-input\tactive\tcompatibility/object.one\tobject.missing\t-\t-\t-\t-\t-\n",
        .{zero_sha},
    );
    defer allocator.free(missing_target);
    try std.testing.expectError(error.MissingTargetObject, parseManifest(allocator, missing_target));

    const incomplete_snapshot = try std.mem.replaceOwned(
        u8,
        allocator,
        text,
        snapshot_format,
        "-",
    );
    defer allocator.free(incomplete_snapshot);
    try std.testing.expectError(error.InvalidSnapshotRow, parseManifest(allocator, incomplete_snapshot));

    const key_mismatch = try std.fmt.allocPrint(
        allocator,
        schema_magic ++ "\n" ++ schema_header ++ "\n" ++
            "object\tobject.one\t{s}\t1\t444\tapplication/octet-stream\tproof\tunavailable\tcanonical-input\tactive\tobjects/sha256/00/{s}\t-\t-\t-\t-\t-\t-\n",
        .{ one_sha, zero_sha[2..] },
    );
    defer allocator.free(key_mismatch);
    try std.testing.expectError(error.InvalidObjectRow, parseManifest(allocator, key_mismatch));

    const conflicting_key = try std.fmt.allocPrint(
        allocator,
        schema_magic ++ "\n" ++ schema_header ++ "\n" ++
            "object\tobject.zero\t{s}\t1\t444\tapplication/octet-stream\tproof\tunavailable\tcanonical-input\tactive\tobjects/sha256/00/{s}\t-\t-\t-\t-\t-\t-\n" ++
            "object\tobject.one\t{s}\t1\t444\tapplication/octet-stream\tproof\tunavailable\tcanonical-input\tactive\tobjects/sha256/11/{s}\t-\t-\t-\t-\t-\t-\n" ++
            "logical-ref\tref.zero\t{s}\t1\t444\tapplication/octet-stream\tproof\tunavailable\tcanonical-input\tactive\tshared.bin\tobject.zero\t-\t-\t-\t-\t-\n" ++
            "logical-ref\tref.one\t{s}\t1\t444\tapplication/octet-stream\tproof\tunavailable\tcanonical-input\tactive\tshared.bin\tobject.one\t-\t-\t-\t-\t-\n",
        .{ zero_sha, zero_sha[2..], one_sha, one_sha[2..], zero_sha, one_sha },
    );
    defer allocator.free(conflicting_key);
    try std.testing.expectError(error.ConflictingManifestKey, parseManifest(allocator, conflicting_key));
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

test "capacity arithmetic counts each component once and fails closed" {
    const accepted: CapacityRequirement = .{
        .validation_reserve = 49_112_001_332,
        .primary_bytes = 3_112_270_055,
        .snapshot_bound = 6_230_928_384,
        .manifest_bound = 67_108_864,
        .required_inodes = 3_362,
    };
    try std.testing.expectEqual(@as(u64, 58_522_308_635), try accepted.requiredBytes());
    try accepted.validate(.{ .free_bytes = 58_522_308_635, .free_inodes = 3_362 });
    try std.testing.expectError(
        error.InsufficientFreeBytes,
        accepted.validate(.{ .free_bytes = 58_522_308_634, .free_inodes = 3_362 }),
    );
    try std.testing.expectError(
        error.InsufficientFreeInodes,
        accepted.validate(.{ .free_bytes = 58_522_308_635, .free_inodes = 3_361 }),
    );
    const overflow: CapacityRequirement = .{
        .validation_reserve = std.math.maxInt(u64),
        .primary_bytes = 1,
        .snapshot_bound = 0,
        .manifest_bound = 0,
        .required_inodes = 0,
    };
    try std.testing.expectError(error.Overflow, overflow.requiredBytes());
    try std.testing.expectEqual(
        CapacityObservation{ .free_bytes = 4096, .free_inodes = 7 },
        try capacityFromFields(2, 2048, 7),
    );
    try std.testing.expectError(
        error.Overflow,
        capacityFromFields(std.math.maxInt(u64), 2, 0),
    );
    try std.testing.expectError(error.InvalidCapacityObservation, capacityFromFields(1, 0, 0));
}

test "registration drift is modeled without mutating git" {
    const allocator = std.testing.allocator;
    const io = std.testing.io;
    var actual = try captureRegistration(allocator, io);
    defer actual.deinit(allocator);
    try validateExpectedRegistration(actual);

    const changed = try std.mem.replaceOwned(
        u8,
        allocator,
        actual.raw,
        "worktree /home/oleg/prog/z_llvm\n",
        "worktree /home/oleg/prog/z_llvm-drift\n",
    );
    defer allocator.free(changed);
    var drift = try parseRegistration(allocator, changed);
    defer drift.deinit(allocator);
    try std.testing.expect(!actual.eql(drift));
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
        "/home/oleg/prog/z_llvm/docs/evidence",
        "/home/oleg/prog/z_llvm/docs/evidence/zllvm_artifact_manifest_v1.template.tsv",
    );
    try std.testing.expectError(
        error.RegisteredWorktreeOverlap,
        guard.assertReadSource(
            main_repository,
            "/home/oleg/prog/z_llvm/docs/evidence/zllvm_artifact_manifest_v1.template.tsv",
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
    if (std.Io.Dir.openDirAbsolute(io, default_store, .{ .follow_symlinks = false })) |existing| {
        existing.close(io);
        return error.RealStoreMustRemainAbsent;
    } else |err| switch (err) {
        error.FileNotFound => {},
        else => return err,
    }

    const sync_before_root = test_directory_sync_count;
    try createAbsoluteDirectorySynced(io, synthetic_store);
    try std.testing.expect(test_directory_sync_count >= sync_before_root + 2);
    errdefer std.debug.print(
        "INBOX-193C retain-on-failure synthetic_root={s}\n",
        .{synthetic_store},
    );

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
        "/home/oleg/prog/z_llvm/docs/evidence",
        "/home/oleg/prog/z_llvm/docs/evidence/zllvm_artifact_manifest_v1.template.tsv",
    );
    defer streamed_object.deinit(allocator);
    try store.verifyObject(streamed_object);
    if (store.publishFile("/home/oleg/prog/z_llvm/docs", "/home/oleg/prog/z_llvm/docs")) |unexpected| {
        var mutable = unexpected;
        mutable.deinit(allocator);
        return error.NonRegularReadSourceWasAccepted;
    } else |_| {}

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
    if (std.Io.Dir.openDirAbsolute(io, default_store, .{ .follow_symlinks = false })) |unexpected| {
        unexpected.close(io);
        return error.RealStoreWasCreated;
    } else |err| switch (err) {
        error.FileNotFound => {},
        else => return err,
    }
    var original_after = try std.Io.Dir.openDirAbsolute(io, original_failed_store, .{
        .iterate = true,
        .follow_symlinks = false,
    });
    defer original_after.close(io);
    var original_entries_after = original_after.iterate();
    if (try original_entries_after.next(io) != null) return error.OriginalFailedStoreChanged;
}
