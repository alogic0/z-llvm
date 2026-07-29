const std = @import("std");
const builtin = @import("builtin");
const canonical_source = @import("canonical_source.zig");
const identity_model = @import("identity.zig");
const manifest_model = @import("manifest.zig");
const store_model = @import("store.zig");

const FileIdentity = identity_model.FileIdentity;
const SnapshotIdentity = identity_model.SnapshotIdentity;
const identityOfOpenFileAnyMode = identity_model.identityOfOpenFileAnyMode;
const schema_magic = manifest_model.schema_magic;
const schema_header = manifest_model.schema_header;
const snapshot_format = manifest_model.snapshot_format;
const snapshot_recipe_sha = manifest_model.snapshot_recipe_sha;
const parseManifest = manifest_model.parseManifest;
const encodeManifest = manifest_model.encodeManifest;
const findRow = manifest_model.findRow;
const sortedObjectGroup = store_model.sortedObjectGroup;
const SourceSpecRow = canonical_source.SourceSpecRow;

const prior_failed_materialize_store =
    "/home/oleg/prog/z_llvm-inbox194-artifact-store-synthetic";
const prior_failed_materialize_continuation_store =
    "/home/oleg/prog/z_llvm-inbox194a-artifact-store-synthetic";
const prior_failed_materialize_second_continuation_store =
    "/home/oleg/prog/z_llvm-inbox194b-artifact-store-synthetic";
const retained_materialize_object_sha =
    "d8da86cae494d7d4a58053ab24b1e8be944859263072b85ffa164880b0110cd4";
const retained_materialize_object_bytes = 7_215_373;

pub fn manifestForSynthetic(
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

pub fn assertRetainedMaterializeBoundaries(io: std.Io, default_store: []const u8) !void {
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

pub fn generatorTestSourceSpecRow(group_id: []const u8) SourceSpecRow {
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

pub const GeneratedMemberMutation = enum {
    dash_keys,
    other_object_key,
    hash,
    bytes,
    mode,
};

pub fn mutateGeneratedMembers(
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
