const std = @import("std");
const builtin = @import("builtin");
const capacity = @import("capacity.zig");
const digest_model = @import("digest.zig");
const filesystem = @import("filesystem.zig");
const identity_model = @import("identity.zig");
const manifest_model = @import("manifest.zig");
const path_policy = @import("path_policy.zig");
const process_result = @import("process_result.zig");
const registration = @import("registration.zig");

const CapacityObservation = capacity.CapacityObservation;
const CapacityRequirement = capacity.CapacityRequirement;
const freshCapacity = capacity.freshCapacity;
const sha256Hex = digest_model.sha256Hex;
const PublishFault = filesystem.PublishFault;
const openOrCreateDir = filesystem.openOrCreateDir;
const openExistingDir = filesystem.openExistingDir;
const openPathNoFollow = filesystem.openPathNoFollow;
const publishVerifiedBytes = filesystem.publishVerifiedBytes;
const publishVerifiedFile = filesystem.publishVerifiedFile;
const writeExclusive = filesystem.writeExclusive;
const syncDirectory = filesystem.syncDirectory;
const FileIdentity = identity_model.FileIdentity;
const SnapshotIdentity = identity_model.SnapshotIdentity;
const sameFileIdentity = identity_model.sameFileIdentity;
const verifyRelativeFile = identity_model.verifyRelativeFile;
const identityOfOpenFile = identity_model.identityOfOpenFile;
const identityOfOpenFileAnyMode = identity_model.identityOfOpenFileAnyMode;
const Row = manifest_model.Row;
const parseManifest = manifest_model.parseManifest;
const encodeManifest = manifest_model.encodeManifest;
const findRow = manifest_model.findRow;
const validateRelativeKey = manifest_model.validateRelativeKey;
const validateSha = manifest_model.validateSha;
const isLowerHex = manifest_model.isLowerHex;
const splitObjectKey = manifest_model.splitObjectKey;
const splitSnapshotKey = manifest_model.splitSnapshotKey;
const max_snapshot_members = manifest_model.max_snapshot_members;
const pathContains = path_policy.pathContains;
const termSuccess = process_result.termSuccess;
const freeRunResult = process_result.freeRunResult;
const RegistrationGuard = registration.RegistrationGuard;

pub const snapshot_recipe =
    "tar-1.35:--format=ustar,--sort=name,--mtime=@0,--owner=0,--group=0,--numeric-owner,--mode=0444,--no-acls,--no-xattrs,--no-selinux,--no-recursion,--null,--files-from;zstd-1.5.5:-T1,-19,--check,--no-progress,-c";

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
        var actual = try verifyRelativeFile(
            store.allocator,
            store.io,
            leaf,
            split.basename,
            identity.mode,
        );
        defer actual.deinit(store.allocator);
        if (!std.mem.eql(u8, &actual.sha256, &identity.sha256) or
            actual.bytes != identity.bytes)
        {
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

pub fn testPublishBytesCorruptIncoming(
    store: *Store,
    bytes: []const u8,
) !FileIdentity {
    if (!builtin.is_test) return error.TestOnlyOperation;
    return store.publishBytesWithFault(bytes, .corrupt_incoming);
}

pub fn testPublishBytesCorruptFinal(
    store: *Store,
    bytes: []const u8,
) !FileIdentity {
    if (!builtin.is_test) return error.TestOnlyOperation;
    return store.publishBytesWithFault(bytes, .corrupt_final);
}

pub fn testOpenObjectLeaf(store: *Store, prefix: []const u8) !std.Io.Dir {
    if (!builtin.is_test) return error.TestOnlyOperation;
    return store.openObjectLeaf(prefix);
}

pub fn sortedObjectGroup(
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

pub fn encodeConstituentManifest(
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

pub fn encodeMemberList(
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

pub fn objectKey(allocator: std.mem.Allocator, sha: []const u8) ![]u8 {
    try validateSha(sha);
    return std.fmt.allocPrint(allocator, "objects/sha256/{s}/{s}", .{ sha[0..2], sha[2..] });
}

pub fn snapshotKey(allocator: std.mem.Allocator, sha: []const u8) ![]u8 {
    try validateSha(sha);
    return std.fmt.allocPrint(allocator, "snapshots/sha256/{s}/{s}.tar.zst", .{ sha[0..2], sha[2..] });
}

pub fn expectSnapshotProofDirectoryEmpty(store: *Store) !void {
    if (!builtin.is_test) return error.TestOnlyOperation;
    var proof_root = try openExistingDir(store.io, store.root, "snapshot-proof");
    defer proof_root.close(store.io);
    var entries = proof_root.iterate();
    if (try entries.next(store.io) != null) return error.SnapshotProofWorkspaceRetained;
}

pub fn testOnlySnapshotProofEarlyUnwind(store: *Store) !void {
    if (!builtin.is_test) return error.TestOnlyOperation;
    var proof = try SnapshotProofWorkspace.init(store.io, store.root);
    defer proof.deinitAfterError();
    return error.TestSnapshotProofEarlyFailure;
}

pub fn cleanToolEnvironment(allocator: std.mem.Allocator) std.process.Environ.Map {
    var environment = std.process.Environ.Map.init(allocator);
    environment.put("PATH", "/usr/bin:/bin") catch @panic("out of memory");
    environment.put("LC_ALL", "C") catch @panic("out of memory");
    environment.put("TZ", "UTC") catch @panic("out of memory");
    environment.put("SOURCE_DATE_EPOCH", "0") catch @panic("out of memory");
    return environment;
}

pub fn verifyToolchain(allocator: std.mem.Allocator, io: std.Io) !void {
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

pub fn runCleanCapture(
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

pub fn validateSnapshotListing(
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
