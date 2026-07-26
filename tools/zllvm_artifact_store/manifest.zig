const std = @import("std");

pub const schema_magic = "zllvm-artifact-manifest-v1";
pub const schema_header =
    "kind\tlogical_id\tsha256\tbytes\tmode\tmedia_type\tprovenance\treconstruction\tretention_class\tstatus\tkey\ttarget_id\tsnapshot_id\tmember_path\tsnapshot_format\trecipe_sha256\tconstituent_sha256";
pub const snapshot_format = "ustar+zstd-v1";
pub const snapshot_recipe_sha = "cb9f999404a7dd9eb991d73d18078b20d99e82399d1d415eb1afa3398e97113a";
pub const max_snapshot_members = 1024;

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

    pub fn deinit(value: *Manifest, allocator: std.mem.Allocator) void {
        allocator.free(value.rows);
        allocator.free(value.storage);
        value.* = undefined;
    }
};

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
    const value: Manifest = .{ .storage = storage, .rows = owned };
    try validateRelationships(value);
    return value;
}

pub fn encodeManifest(allocator: std.mem.Allocator, value: Manifest) ![]u8 {
    var output: std.ArrayList(u8) = .empty;
    errdefer output.deinit(allocator);
    try appendManifestPreamble(allocator, &output);
    for (value.rows) |row| try appendManifestRowText(allocator, &output, row);
    return output.toOwnedSlice(allocator);
}

pub fn appendManifestPreamble(
    allocator: std.mem.Allocator,
    output: *std.ArrayList(u8),
) !void {
    try output.appendSlice(allocator, schema_magic);
    try output.append(allocator, '\n');
    try output.appendSlice(allocator, schema_header);
    try output.append(allocator, '\n');
}

pub fn appendManifestRowText(
    allocator: std.mem.Allocator,
    output: *std.ArrayList(u8),
    row: Row,
) !void {
    try output.print(
        allocator,
        "{s}\t{s}\t{s}\t{}\t{o}\t{s}\t{s}\t{s}\t{s}\t{s}\t{s}\t{s}\t{s}\t{s}\t{s}\t{s}\t{s}\n",
        .{
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
        },
    );
}

fn validateRowShape(row: Row) !void {
    try validateSha(row.sha256);
    try validateRelativeKey(row.key);
    switch (row.kind) {
        .object => {
            const split = splitObjectKey(row.key) orelse return error.InvalidObjectRow;
            if (row.mode != 0o444 or
                row.target_id.len != 1 or row.target_id[0] != '-' or
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
            if (row.mode != 0o444 or
                row.target_id.len != 1 or row.target_id[0] != '-' or
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
            if (row.mode != 0o444 or
                !isDash(row.snapshot_format) or
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

fn validateRelationships(value: Manifest) !void {
    for (value.rows, 0..) |row, row_index| {
        for (value.rows[0..row_index]) |prior| {
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
                const target = findRow(value, row.target_id) orelse return error.MissingTargetObject;
                if (target.kind != .object or !logicalRefMatchesTarget(row, target)) {
                    return error.LogicalRefMismatch;
                }
            },
            .snapshot => {
                var constituent_matches: usize = 0;
                var member_count: usize = 0;
                for (value.rows) |candidate| {
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
                const target = findRow(value, row.target_id) orelse return error.MissingTargetObject;
                const snapshot = findRow(value, row.snapshot_id) orelse return error.MissingSnapshot;
                if (target.kind != .object or snapshot.kind != .snapshot or
                    !sameIdentity(row, target) or !std.mem.eql(u8, row.member_path, target.key))
                {
                    return error.SnapshotMemberMismatch;
                }
                for (value.rows[0..row_index]) |other| {
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

pub fn findRow(value: Manifest, logical_id: []const u8) ?Row {
    for (value.rows) |row| {
        if (std.mem.eql(u8, row.logical_id, logical_id)) return row;
    }
    return null;
}

pub fn sameIdentity(a: Row, b: Row) bool {
    return std.mem.eql(u8, a.sha256, b.sha256) and a.bytes == b.bytes and a.mode == b.mode;
}

pub fn logicalRefMatchesTarget(logical_ref: Row, target: Row) bool {
    return std.mem.eql(u8, logical_ref.sha256, target.sha256) and
        logical_ref.bytes == target.bytes and
        std.mem.eql(u8, logical_ref.media_type, target.media_type);
}

pub fn parseEnum(comptime E: type, text: []const u8) ?E {
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

pub fn externalEnumName(value: anytype) []const u8 {
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

pub fn validateCanonicalField(allocator: std.mem.Allocator, encoded: []const u8) !void {
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

pub fn encodeField(allocator: std.mem.Allocator, decoded: []const u8) ![]u8 {
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

pub fn validateLogicalId(id: []const u8) !void {
    if (id.len == 0 or !isLowerAlphaNumeric(id[0])) return error.InvalidLogicalId;
    try validateRelativeKey(id);
}

pub fn validateRelativeKey(key: []const u8) !void {
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

pub fn validateSha(text: []const u8) !void {
    if (text.len != 64 or !isLowerHex(text)) return error.InvalidSha256;
}

pub fn isLowerHex(text: []const u8) bool {
    for (text) |byte| {
        if (!std.ascii.isDigit(byte) and !(byte >= 'a' and byte <= 'f')) return false;
    }
    return true;
}

pub fn isLowerAlphaNumeric(byte: u8) bool {
    return std.ascii.isDigit(byte) or (byte >= 'a' and byte <= 'z');
}

pub const KeySplit = struct { prefix: []const u8, basename: []const u8 };

pub fn splitObjectKey(key: []const u8) ?KeySplit {
    const prefix = "objects/sha256/";
    if (!std.mem.startsWith(u8, key, prefix) or key.len != prefix.len + 2 + 1 + 62) return null;
    if (key[prefix.len + 2] != '/') return null;
    const a = key[prefix.len .. prefix.len + 2];
    const b = key[prefix.len + 3 ..];
    if (!isLowerHex(a) or !isLowerHex(b)) return null;
    return .{ .prefix = a, .basename = b };
}

pub fn splitSnapshotKey(key: []const u8) ?KeySplit {
    const prefix = "snapshots/sha256/";
    const suffix = ".tar.zst";
    if (!std.mem.startsWith(u8, key, prefix) or !std.mem.endsWith(u8, key, suffix)) return null;
    if (key.len != prefix.len + 2 + 1 + 62 + suffix.len or key[prefix.len + 2] != '/') return null;
    const a = key[prefix.len .. prefix.len + 2];
    const b = key[prefix.len + 3 ..];
    if (!isLowerHex(a) or !isLowerHex(b[0..62])) return null;
    return .{ .prefix = a, .basename = b };
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
    var value = try parseManifest(allocator, text);
    defer value.deinit(allocator);
    const encoded = try encodeManifest(allocator, value);
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

    const logical_mode_split = try std.fmt.allocPrint(
        allocator,
        schema_magic ++ "\n" ++ schema_header ++ "\n" ++
            "object\tobject.one\t{s}\t1\t444\tapplication/octet-stream\tproof\tunavailable\tcanonical-input\tactive\tobjects/sha256/00/{s}\t-\t-\t-\t-\t-\t-\n" ++
            "logical-ref\tref.one\t{s}\t1\t664\tapplication/octet-stream\tproof\tunavailable\tcanonical-input\tactive\tcompatibility/object.one\tobject.one\t-\t-\t-\t-\t-\n",
        .{ zero_sha, zero_sha[2..], zero_sha },
    );
    defer allocator.free(logical_mode_split);
    var split_manifest = try parseManifest(allocator, logical_mode_split);
    defer split_manifest.deinit(allocator);
    const split_ref = findRow(split_manifest, "ref.one") orelse return error.MissingLogicalReference;
    const split_target = findRow(split_manifest, "object.one") orelse return error.MissingTargetObject;
    try std.testing.expectEqual(@as(u16, 0o664), split_ref.mode);
    try std.testing.expectEqual(@as(u16, 0o444), split_target.mode);
    try std.testing.expect(logicalRefMatchesTarget(split_ref, split_target));

    const logical_hash_mismatch = try std.mem.replaceOwned(
        u8,
        allocator,
        logical_mode_split,
        "logical-ref\tref.one\t0000000000000000000000000000000000000000000000000000000000000000",
        "logical-ref\tref.one\t1111111111111111111111111111111111111111111111111111111111111111",
    );
    defer allocator.free(logical_hash_mismatch);
    try std.testing.expectError(
        error.LogicalRefMismatch,
        parseManifest(allocator, logical_hash_mismatch),
    );
    const logical_byte_mismatch = try std.mem.replaceOwned(
        u8,
        allocator,
        logical_mode_split,
        "logical-ref\tref.one\t0000000000000000000000000000000000000000000000000000000000000000\t1\t664",
        "logical-ref\tref.one\t0000000000000000000000000000000000000000000000000000000000000000\t2\t664",
    );
    defer allocator.free(logical_byte_mismatch);
    try std.testing.expectError(
        error.LogicalRefMismatch,
        parseManifest(allocator, logical_byte_mismatch),
    );
    const logical_media_mismatch = try std.mem.replaceOwned(
        u8,
        allocator,
        logical_mode_split,
        "logical-ref\tref.one\t0000000000000000000000000000000000000000000000000000000000000000\t1\t664\tapplication/octet-stream",
        "logical-ref\tref.one\t0000000000000000000000000000000000000000000000000000000000000000\t1\t664\ttext/plain",
    );
    defer allocator.free(logical_media_mismatch);
    try std.testing.expectError(
        error.LogicalRefMismatch,
        parseManifest(allocator, logical_media_mismatch),
    );
    const logical_target_mismatch = try std.mem.replaceOwned(
        u8,
        allocator,
        logical_mode_split,
        "\tobject.one\t-\t-\t-\t-\t-\n",
        "\tobject.missing\t-\t-\t-\t-\t-\n",
    );
    defer allocator.free(logical_target_mismatch);
    try std.testing.expectError(
        error.MissingTargetObject,
        parseManifest(allocator, logical_target_mismatch),
    );
    const logical_target_key_mismatch = try std.mem.replaceOwned(
        u8,
        allocator,
        logical_mode_split,
        "objects/sha256/00/00000000000000000000000000000000000000000000000000000000000000",
        "objects/sha256/00/00000000000000000000000000000000000000000000000000000000000001",
    );
    defer allocator.free(logical_target_key_mismatch);
    try std.testing.expectError(
        error.InvalidObjectRow,
        parseManifest(allocator, logical_target_key_mismatch),
    );
    const non_immutable_object = try std.mem.replaceOwned(
        u8,
        allocator,
        logical_mode_split,
        "object\tobject.one\t0000000000000000000000000000000000000000000000000000000000000000\t1\t444",
        "object\tobject.one\t0000000000000000000000000000000000000000000000000000000000000000\t1\t400",
    );
    defer allocator.free(non_immutable_object);
    try std.testing.expectError(
        error.InvalidObjectRow,
        parseManifest(allocator, non_immutable_object),
    );

    const incomplete_snapshot = try std.mem.replaceOwned(
        u8,
        allocator,
        text,
        snapshot_format,
        "-",
    );
    defer allocator.free(incomplete_snapshot);
    try std.testing.expectError(error.InvalidSnapshotRow, parseManifest(allocator, incomplete_snapshot));

    const non_immutable_snapshot = try std.mem.replaceOwned(
        u8,
        allocator,
        text,
        "snapshot\tsnapshot.one\t1111111111111111111111111111111111111111111111111111111111111111\t2\t444",
        "snapshot\tsnapshot.one\t1111111111111111111111111111111111111111111111111111111111111111\t2\t400",
    );
    defer allocator.free(non_immutable_snapshot);
    try std.testing.expectError(
        error.InvalidSnapshotRow,
        parseManifest(allocator, non_immutable_snapshot),
    );
    const non_immutable_snapshot_member = try std.mem.replaceOwned(
        u8,
        allocator,
        text,
        "snapshot-member\tmember.one\t0000000000000000000000000000000000000000000000000000000000000000\t1\t444",
        "snapshot-member\tmember.one\t0000000000000000000000000000000000000000000000000000000000000000\t1\t400",
    );
    defer allocator.free(non_immutable_snapshot_member);
    try std.testing.expectError(
        error.InvalidSnapshotMemberRow,
        parseManifest(allocator, non_immutable_snapshot_member),
    );

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
