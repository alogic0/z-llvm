const std = @import("std");
const builtin = @import("builtin");
const authority_control = @import("authority_control.zig");
const digest = @import("digest.zig");
const exact_real_observer = @import("exact_real_observer.zig");
const filesystem = @import("filesystem.zig");
const identity = @import("identity.zig");
const manifest = @import("manifest.zig");
const store = @import("store.zig");

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
const DormantAuthorityConfig = authority_control.API.AuthorityConfig;
const DormantReadinessNetEffects = exact_real_observer.API.NetEffects;
const appendDormantReadinessField = exact_real_observer.API.appendReadinessField;
const appendDormantReadinessInteger = exact_real_observer.API.appendReadinessInteger;
const appendDormantLogicalState = exact_real_observer.API.appendLogicalState;
const sha256Hex = digest.sha256Hex;
const openPathNoFollow = filesystem.openPathNoFollow;
const openExistingDir = filesystem.openExistingDir;
const writeExclusive = filesystem.writeExclusive;
const syncDirectory = filesystem.syncDirectory;
const identityOfOpenFileAnyMode = identity.identityOfOpenFileAnyMode;
const schema_magic = manifest.schema_magic;
const schema_header = manifest.schema_header;
const snapshot_format = manifest.snapshot_format;
const snapshot_recipe_sha = manifest.snapshot_recipe_sha;
const parseManifest = manifest.parseManifest;
const objectKey = store.objectKey;
const snapshotKey = store.snapshotKey;

const dormant_test_root = authority_control.API.test_root;
const dormant_test_source_inventory_sha256 =
    "1111111111111111111111111111111111111111111111111111111111111111";
const dormant_test_source_file_ledger_sha256 =
    "2222222222222222222222222222222222222222222222222222222222222222";
const dormant_test_source_destination_ledger_sha256 =
    "3333333333333333333333333333333333333333333333333333333333333333";
const dormant_test_copy_evidence_path = "docs/evidence/synthetic-copy-proof.md";
const dormant_test_copy_evidence_sha256 =
    "4444444444444444444444444444444444444444444444444444444444444444";

fn createFixtureRootSynced(io: std.Io, absolute_path: []const u8) !void {
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

fn removeFixtureRootSynced(io: std.Io, absolute_path: []const u8) !void {
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

    pub fn init(allocator: std.mem.Allocator, io: std.Io) !DormantSyntheticFixture {
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
        try createFixtureRootSynced(io, dormant_test_root);
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
        try createFixtureRootSynced(io, main_root);
        try createFixtureRootSynced(io, control_root);
        try createFixtureRootSynced(io, artifacts_root);
        try createFixtureRootSynced(io, payload_root);
        try createFixtureRootSynced(io, source_root);
        try createFixtureRootSynced(io, non_main_root);
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

        const generation_manifest = try std.fmt.allocPrint(
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
        errdefer allocator.free(generation_manifest);
        var parsed_manifest = try parseManifest(allocator, generation_manifest);
        parsed_manifest.deinit(allocator);
        const manifest_sha = sha256Hex(generation_manifest);
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
                generation_manifest.len,
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
            generation_manifest,
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
            .manifest = generation_manifest,
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

    pub fn deinitAfterSuccess(fixture: *DormantSyntheticFixture) !void {
        try removeFixtureRootSynced(fixture.io, fixture.root);
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

    pub fn replaceControl(
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
        try replaceDormantFixtureRelative(fixture.io, control, relative_path, bytes, 0o644);
    }

    pub fn deleteControl(
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

    pub fn replacePayload(
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
        try replaceDormantFixtureRelative(fixture.io, payload_dir, relative_path, bytes, 0o444);
    }

    pub fn deletePayload(
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

    pub fn candidateFor(
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

    pub fn receiptFor(
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

    pub fn symlinkControl(
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

    pub fn symlinkPayload(
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

    pub fn deinit(snapshot: *DormantReadinessSnapshot) void {
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

const dormant_readiness_publication_prefix =
    "main/control/authority/zllvm/v1/receipts/publication";

fn dormantReadinessPublicationPath(path: []const u8) bool {
    return std.mem.eql(u8, path, dormant_readiness_publication_prefix) or
        (std.mem.startsWith(u8, path, dormant_readiness_publication_prefix) and
            path.len > dormant_readiness_publication_prefix.len and
            path[dormant_readiness_publication_prefix.len] == '/');
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
                var file_identity = try identityOfOpenFileAnyMode(allocator, io, file);
                defer file_identity.deinit(allocator);
                try appendDormantReadinessInteger(allocator, &state, file_identity.bytes);
                try appendDormantReadinessField(allocator, &state, &file_identity.sha256);
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

pub const API = struct {
    pub const test_root = dormant_test_root;
    pub const source_inventory_sha256 = dormant_test_source_inventory_sha256;
    pub const source_file_ledger_sha256 = dormant_test_source_file_ledger_sha256;
    pub const source_destination_ledger_sha256 =
        dormant_test_source_destination_ledger_sha256;
    pub const copy_evidence_path = dormant_test_copy_evidence_path;
    pub const copy_evidence_sha256 = dormant_test_copy_evidence_sha256;
    pub const Fixture = DormantSyntheticFixture;
    pub const ReadinessSnapshot = DormantReadinessSnapshot;
    pub const writeRelative = writeDormantFixtureRelative;
    pub const setAbsoluteDirectoryMode = setDormantAbsoluteDirectoryMode;
    pub const setRelativeDirectoryModes = setDormantRelativeDirectoryModes;
    pub const deleteRelative = deleteDormantFixtureRelative;
    pub const replaceRelative = replaceDormantFixtureRelative;
    pub const replaceOwnedBytes = replaceDormantTestOwnedBytes;
    pub const restoreOwnedBytes = restoreDormantTestOwnedBytes;
    pub const captureReadinessState = captureDormantReadinessState;
    pub const compareReadinessStates = compareDormantReadinessStates;
    pub const expectReadinessEffects = expectDormantReadinessEffects;
    pub const exerciseReadinessOwnershipFailure = exerciseDormantReadinessOwnershipFailure;
};
