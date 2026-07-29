const std = @import("std");
const authority_control = @import("authority_control.zig");
const digest_model = @import("digest.zig");
const identity_model = @import("identity.zig");
const manifest_model = @import("manifest.zig");
const registration = @import("registration.zig");
const store_model = @import("store.zig");

const sha256Hex = digest_model.sha256Hex;
const FileIdentity = identity_model.FileIdentity;
const SnapshotIdentity = identity_model.SnapshotIdentity;
const RetentionClass = manifest_model.RetentionClass;
const appendManifestPreamble = manifest_model.appendManifestPreamble;
const appendManifestRowText = manifest_model.appendManifestRowText;
const parseManifest = manifest_model.parseManifest;
const encodeManifest = manifest_model.encodeManifest;
const validateCanonicalField = manifest_model.validateCanonicalField;
const parseEnum = manifest_model.parseEnum;
const validateLogicalId = manifest_model.validateLogicalId;
const validateRelativeKey = manifest_model.validateRelativeKey;
const validateSha = manifest_model.validateSha;
const snapshot_format = manifest_model.snapshot_format;
const snapshot_recipe_sha = manifest_model.snapshot_recipe_sha;
const identityOfOpenFileAnyMode = identity_model.identityOfOpenFileAnyMode;
const RegistrationGuard = registration.RegistrationGuard;
const main_repository = registration.main_repository;
const Store = store_model.Store;
const snapshot_recipe = store_model.snapshot_recipe;
const sortedObjectGroup = store_model.sortedObjectGroup;
const encodeConstituentManifest = store_model.encodeConstituentManifest;
const objectKey = store_model.objectKey;
const validateAuthorityAncestry = authority_control.API.validateAncestry;

pub const canonical_source_spec_path =
    "docs/evidence/inbox194_calls_canonical_source_spec_v1.tsv";
pub const canonical_source_spec_sha =
    "0dd908eed246b09fbea8fd87241ce899b100823b8d83c7223d4e48928e7c599b";
pub const proposed_live_manifest_path =
    "docs/evidence/inbox194_calls_proposed_live_manifest_v1.tsv";
pub const source_spec_magic = "zllvm-calls-canonical-source-spec-v1";
const source_spec_header =
    "logical_id\tsource_set_id\tsource_path\tsha256\tbytes\tsource_mode\tmedia_type\tretention_class\tobject_key\tmember_path\tgroup_id\tsnapshot_id\tsnapshot_format\trecipe_sha256\tconstituent_sha256\tgroup_manifest_sha256";
const source_set_ac285 = "calls/input/accepted-cohort-ac285/v1";
const source_set_compiler_rt = "calls/input/compiler-rt-v1/raw/v1";
const source_set_coverage = "calls/input/validation-v3/coverage-bundle/v1";
const group_calls_inputs = "calls-inputs";
const group_calls_validation_inputs = "calls-validation-inputs";
const snapshot_calls_inputs = "snapshot/calls-inputs/v1";
const snapshot_calls_validation_inputs = "snapshot/calls-validation-inputs/v1";

pub const SourceSpecRow = struct {
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

pub const SourceSpec = struct {
    storage: []u8,
    rows: []SourceSpecRow,

    pub fn deinit(spec: *SourceSpec, allocator: std.mem.Allocator) void {
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

const CreateAbsoluteDirectorySynced = *const fn (std.Io, []const u8) anyerror!void;

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

pub fn parseSourceSpecOwned(allocator: std.mem.Allocator, storage: []u8) !SourceSpec {
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

pub fn planCanonicalSourceSpec(
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

pub fn validateProposedManifestFieldCounts(text: []const u8) !void {
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

pub fn proposedManifestForSourceSpec(
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

pub fn publishCanonicalSourceSpec(
    allocator: std.mem.Allocator,
    io: std.Io,
    spec_path: []const u8,
    root_path: []const u8,
    create_absolute_directory_synced: CreateAbsoluteDirectorySynced,
) ![]u8 {
    var spec = try loadCanonicalSourceSpec(allocator, io, spec_path);
    defer spec.deinit(allocator);
    var guard = try RegistrationGuard.init(allocator, io);
    defer guard.deinit();
    try guard.assertStoreRoot(root_path);
    try verifyCanonicalSources(allocator, io, &guard, spec);
    try prepareStoreRoot(
        allocator,
        io,
        &guard,
        root_path,
        create_absolute_directory_synced,
    );

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

pub fn prepareStoreRoot(
    allocator: std.mem.Allocator,
    io: std.Io,
    guard: *const RegistrationGuard,
    root_path: []const u8,
    create_absolute_directory_synced: CreateAbsoluteDirectorySynced,
) !void {
    try guard.assertStoreRoot(root_path);
    const exists = try validateAuthorityAncestry(allocator, io, root_path);
    try guard.assertCurrent();
    if (!exists) try create_absolute_directory_synced(io, root_path);
    try guard.assertCurrent();
    if (!try validateAuthorityAncestry(allocator, io, root_path)) {
        return error.AuthorityRootMissingAfterPreparation;
    }
}

pub fn publishedManifestForSourceSpec(
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

pub fn appendPublishedConstituentObject(
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

pub fn appendPublishedSnapshot(
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
