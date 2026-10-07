const std = @import("std");
const provenance = @import("provenance.zig");
const GitSha1Identity = provenance.GitSha1Identity;
const RawSha256Identity = provenance.RawSha256Identity;
const canonical_git_sha1_algorithm = provenance.canonical_git_sha1_algorithm;
const canonicalRepositoryPath = provenance.canonicalRepositoryPath;
const equalGitIdentity = provenance.equalGitIdentity;
const equalRawIdentity = provenance.equalRawIdentity;
const fixedIdentity = provenance.fixedIdentity;

const ComponentValidationError = error{
    ComponentLexicallyInvalid,
};

fn validateComponentLexical(component: []const u8) ComponentValidationError!void {
    if (component.len == 0 or
        std.mem.eql(u8, component, ".") or
        std.mem.eql(u8, component, ".."))
    {
        return error.ComponentLexicallyInvalid;
    }
    for (component) |byte| {
        if (byte == '/' or byte == 0) return error.ComponentLexicallyInvalid;
    }
}

const CanonicalSourceSet = provenance.CanonicalSourceSet;
const capability_source_count = provenance.capability_source_count;
const capability_source_mode = provenance.capability_source_mode;
const validateCanonicalSourceSet = provenance.validateCanonicalSourceSet;

pub const receipt_schema_version: u16 = 2;
pub const receipt_capability_version: u16 = 2;
pub const receipt_max_bytes = 8192;
pub const receipt_toolchain_identity_max = 96;
pub const receipt_scope = "synthetic_only";
pub const receipt_selected_variant = "none";
pub const receipt_git_hash_algorithm = "sha1";
pub const receipt_gate_ids =
    "canonical_tuple_admission,synthetic_authority_binding,pre_descriptor_rejection," ++
    "post_seal_length_sha,fresh_owned_replay,consumed_handoff_rejection," ++
    "ownership_exactly_once_close";

pub const receipt_semantic_tuple_admission: u32 = 1 << 0;
pub const receipt_semantic_synthetic_authority_binding: u32 = 1 << 1;
pub const receipt_semantic_pre_descriptor_rejection: u32 = 1 << 2;
pub const receipt_semantic_post_seal_length_sha: u32 = 1 << 3;
pub const receipt_semantic_fresh_owned_replay: u32 = 1 << 4;
pub const receipt_semantic_consumed_handoff_rejection: u32 = 1 << 5;
pub const receipt_semantic_ownership_exactly_once_close: u32 = 1 << 6;
pub const receipt_required_semantic_bits: u32 =
    receipt_semantic_tuple_admission |
    receipt_semantic_synthetic_authority_binding |
    receipt_semantic_pre_descriptor_rejection |
    receipt_semantic_post_seal_length_sha |
    receipt_semantic_fresh_owned_replay |
    receipt_semantic_consumed_handoff_rejection |
    receipt_semantic_ownership_exactly_once_close;

pub const receipt_field_names = [_][]const u8{
    "schema_version",
    "capability_version",
    "scope",
    "selected_variant",
    "source_0_path",
    "source_0_mode",
    "source_0_git_blob",
    "source_0_raw_sha256",
    "source_0_exact_length",
    "source_1_path",
    "source_1_mode",
    "source_1_git_blob",
    "source_1_raw_sha256",
    "source_1_exact_length",
    "source_2_path",
    "source_2_mode",
    "source_2_git_blob",
    "source_2_raw_sha256",
    "source_2_exact_length",
    "source_3_path",
    "source_3_mode",
    "source_3_git_blob",
    "source_3_raw_sha256",
    "source_3_exact_length",
    "source_4_path",
    "source_4_mode",
    "source_4_git_blob",
    "source_4_raw_sha256",
    "source_4_exact_length",
    "staged_tree_hash_algorithm",
    "staged_tree_identity",
    "zig_toolchain_identity",
    "stable_symbolic_gate_ids",
    "numeric_format_and_focused_test_statuses",
    "semantic_gate_bits",
    "completion_state",
};

pub const ReceiptCompletionState = enum {
    incomplete,
    complete,
};

pub const CanonicalReceiptToken = struct {
    length: u8,
    bytes: [receipt_toolchain_identity_max]u8,

    pub fn slice(self: *const CanonicalReceiptToken) ReceiptError![]const u8 {
        return canonicalReceiptTokenSlice(self);
    }
};

pub const CanonicalAcceptanceReceipt = struct {
    schema_version: u16,
    capability_version: u16,
    source_set: CanonicalSourceSet,
    staged_tree_hash_algorithm: u8,
    staged_tree_identity: GitSha1Identity,
    zig_toolchain_identity: CanonicalReceiptToken,
    format_status: u8,
    focused_test_status: u8,
    semantic_gate_bits: u32,
    completion_state: ReceiptCompletionState,
};

pub const CanonicalReceiptBytes = struct {
    length: u16 = 0,
    bytes: [receipt_max_bytes]u8 = @splat(0),

    // Compatibility for already-encoded, internally owned values only. Every
    // authentication and publication boundary uses canonicalReceiptBytesSlice.
    pub fn slice(self: *const CanonicalReceiptBytes) []const u8 {
        std.debug.assert(canonicalReceiptBytesTailIsZero(self));
        return self.bytes[0..self.length];
    }
};

pub fn canonicalReceiptBytesTailIsZero(value: *const CanonicalReceiptBytes) bool {
    const length = std.math.cast(usize, value.length) orelse return false;
    if (length == 0 or length > value.bytes.len) return false;
    return std.mem.allEqual(u8, value.bytes[length..], 0);
}

pub fn validateCanonicalReceiptBytes(value: *const CanonicalReceiptBytes) ReceiptError!void {
    const length = std.math.cast(usize, value.length) orelse return error.ReceiptOversized;
    if (length == 0) return error.ReceiptNonCanonical;
    if (length > value.bytes.len) return error.ReceiptOversized;
    if (!std.mem.allEqual(u8, value.bytes[length..], 0)) return error.ReceiptNonCanonical;
}

pub fn canonicalReceiptBytesSlice(
    value: *const CanonicalReceiptBytes,
) ReceiptError![]const u8 {
    try validateCanonicalReceiptBytes(value);
    const length = std.math.cast(usize, value.length) orelse return error.ReceiptOversized;
    return value.bytes[0..length];
}

pub fn equalCanonicalReceiptBytes(
    left: *const CanonicalReceiptBytes,
    right: *const CanonicalReceiptBytes,
) ReceiptError!bool {
    const left_bytes = try canonicalReceiptBytesSlice(left);
    const right_bytes = try canonicalReceiptBytesSlice(right);
    return std.mem.eql(u8, left_bytes, right_bytes);
}

pub const ReceiptError = error{
    ReceiptOversized,
    ReceiptFieldUnknown,
    ReceiptFieldDuplicate,
    ReceiptFieldMissing,
    ReceiptFieldReordered,
    ReceiptNonCanonical,
    ReceiptSchemaUnsupported,
    ReceiptCapabilityUnsupported,
    ReceiptScopeUnsupported,
    ReceiptVariantUnsupported,
    ReceiptPathMalformed,
    ReceiptSourceSetInvalid,
    ReceiptIdentityMalformed,
    ReceiptHashAlgorithmUnsupported,
    ReceiptGateIdsInvalid,
    ReceiptStatusNonzero,
    ReceiptSemanticBitsIncomplete,
    ReceiptSemanticBitsUnknown,
    ReceiptCompletionInvalid,
    ReceiptPublicationNameCollision,
    ReceiptReadBackMismatch,
};

pub const PublicationResult = struct {
    final_sha256: RawSha256Identity,
    exact_length: u64,
    completion_status: ReceiptCompletionState,
};

pub fn canonicalReceiptToken(input: []const u8) ReceiptError!CanonicalReceiptToken {
    if (input.len == 0 or input.len > receipt_toolchain_identity_max) {
        return error.ReceiptIdentityMalformed;
    }
    var result = CanonicalReceiptToken{
        .length = @intCast(input.len),
        .bytes = @splat(0),
    };
    for (input, 0..) |byte, index| {
        const accepted = std.ascii.isAlphanumeric(byte) or
            byte == '.' or byte == '-' or byte == '_' or byte == '+';
        if (!accepted) return error.ReceiptIdentityMalformed;
        result.bytes[index] = byte;
    }
    return result;
}

pub fn validateCanonicalReceiptToken(token: *const CanonicalReceiptToken) ReceiptError!void {
    const length = std.math.cast(usize, token.length) orelse
        return error.ReceiptIdentityMalformed;
    if (length == 0 or length > token.bytes.len) return error.ReceiptIdentityMalformed;
    for (token.bytes[length..]) |byte| {
        if (byte != 0) return error.ReceiptIdentityMalformed;
    }
    const used = token.bytes[0..length];
    for (used) |byte| {
        const accepted = std.ascii.isAlphanumeric(byte) or
            byte == '.' or byte == '-' or byte == '_' or byte == '+';
        if (!accepted) return error.ReceiptIdentityMalformed;
    }
}

pub fn canonicalReceiptTokenSlice(
    token: *const CanonicalReceiptToken,
) ReceiptError![]const u8 {
    try validateCanonicalReceiptToken(token);
    const length = std.math.cast(usize, token.length) orelse
        return error.ReceiptIdentityMalformed;
    return token.bytes[0..length];
}

pub fn validateCanonicalReceipt(receipt: *const CanonicalAcceptanceReceipt) ReceiptError!void {
    if (receipt.schema_version != receipt_schema_version) {
        return error.ReceiptSchemaUnsupported;
    }
    if (receipt.capability_version != receipt_capability_version) {
        return error.ReceiptCapabilityUnsupported;
    }
    validateCanonicalSourceSet(&receipt.source_set) catch
        return error.ReceiptSourceSetInvalid;
    if (receipt.staged_tree_hash_algorithm != canonical_git_sha1_algorithm) {
        return error.ReceiptHashAlgorithmUnsupported;
    }
    try validateCanonicalReceiptToken(&receipt.zig_toolchain_identity);
    if (receipt.format_status != 0 or receipt.focused_test_status != 0) {
        return error.ReceiptStatusNonzero;
    }
    if (receipt.semantic_gate_bits & ~receipt_required_semantic_bits != 0) {
        return error.ReceiptSemanticBitsUnknown;
    }
    if (receipt.semantic_gate_bits != receipt_required_semantic_bits) {
        return error.ReceiptSemanticBitsIncomplete;
    }
    if (receipt.completion_state != .complete) return error.ReceiptCompletionInvalid;
}

pub fn appendReceiptBytes(output: *CanonicalReceiptBytes, bytes: []const u8) ReceiptError!void {
    const old_length = @as(usize, output.length);
    const next = @addWithOverflow(old_length, bytes.len);
    if (next[1] != 0 or next[0] > output.bytes.len) return error.ReceiptOversized;
    @memcpy(output.bytes[old_length..next[0]], bytes);
    output.length = @intCast(next[0]);
}

pub fn appendReceiptField(
    output: *CanonicalReceiptBytes,
    name: []const u8,
    value: []const u8,
) ReceiptError!void {
    if (value.len == 0) return error.ReceiptNonCanonical;
    try appendReceiptBytes(output, name);
    try appendReceiptBytes(output, "=");
    try appendReceiptBytes(output, value);
    try appendReceiptBytes(output, "\n");
}

pub fn lowerHexNibble(value: u8) u8 {
    return if (value < 10) '0' + value else 'a' + (value - 10);
}

pub fn encodeLowerHex(input: []const u8, output: []u8) void {
    std.debug.assert(output.len == input.len * 2);
    for (input, 0..) |byte, index| {
        output[index * 2] = lowerHexNibble(byte >> 4);
        output[index * 2 + 1] = lowerHexNibble(byte & 0x0f);
    }
}

pub fn encodeSemanticBits(bits: u32) [8]u8 {
    var output: [8]u8 = undefined;
    var shift: usize = 0;
    while (shift < output.len) : (shift += 1) {
        const nibble_shift: u5 = @intCast((output.len - shift - 1) * 4);
        output[shift] = lowerHexNibble(@intCast((bits >> nibble_shift) & 0x0f));
    }
    return output;
}

pub fn encodeCanonicalReceipt(receipt: *const CanonicalAcceptanceReceipt) ReceiptError!CanonicalReceiptBytes {
    try validateCanonicalReceipt(receipt);
    var output = CanonicalReceiptBytes{};
    var decimal_buffer: [20]u8 = undefined;
    var tree_hex: [40]u8 = undefined;
    const semantic_hex = encodeSemanticBits(receipt.semantic_gate_bits);

    const schema = std.fmt.bufPrint(&decimal_buffer, "{d}", .{receipt.schema_version}) catch
        return error.ReceiptOversized;
    try appendReceiptField(&output, receipt_field_names[0], schema);
    const capability = std.fmt.bufPrint(&decimal_buffer, "{d}", .{receipt.capability_version}) catch
        return error.ReceiptOversized;
    try appendReceiptField(&output, receipt_field_names[1], capability);
    try appendReceiptField(&output, receipt_field_names[2], receipt_scope);
    try appendReceiptField(&output, receipt_field_names[3], receipt_selected_variant);
    for (&receipt.source_set.entries, 0..) |*entry, source_index| {
        var raw_hash_hex: [64]u8 = undefined;
        var blob_hex: [40]u8 = undefined;
        const base = 4 + source_index * 5;
        try appendReceiptField(
            &output,
            receipt_field_names[base],
            entry.path.bytes[0..entry.path.length],
        );
        try appendReceiptField(&output, receipt_field_names[base + 1], "100644");
        encodeLowerHex(&entry.git_blob_identity.bytes, &blob_hex);
        try appendReceiptField(&output, receipt_field_names[base + 2], &blob_hex);
        encodeLowerHex(&entry.raw_sha256.bytes, &raw_hash_hex);
        try appendReceiptField(&output, receipt_field_names[base + 3], &raw_hash_hex);
        const exact_length = std.fmt.bufPrint(&decimal_buffer, "{d}", .{entry.exact_length}) catch
            return error.ReceiptOversized;
        try appendReceiptField(&output, receipt_field_names[base + 4], exact_length);
    }
    const staged_base = 4 + capability_source_count * 5;
    try appendReceiptField(&output, receipt_field_names[staged_base], receipt_git_hash_algorithm);
    encodeLowerHex(&receipt.staged_tree_identity.bytes, &tree_hex);
    try appendReceiptField(&output, receipt_field_names[staged_base + 1], &tree_hex);
    try appendReceiptField(
        &output,
        receipt_field_names[staged_base + 2],
        try canonicalReceiptTokenSlice(&receipt.zig_toolchain_identity),
    );
    try appendReceiptField(&output, receipt_field_names[staged_base + 3], receipt_gate_ids);
    try appendReceiptField(&output, receipt_field_names[staged_base + 4], "0,0");
    try appendReceiptField(&output, receipt_field_names[staged_base + 5], &semantic_hex);
    try appendReceiptField(&output, receipt_field_names[staged_base + 6], "complete");
    return output;
}

pub fn receiptFieldIndex(name: []const u8) ?usize {
    for (receipt_field_names, 0..) |expected, index| {
        if (std.mem.eql(u8, name, expected)) return index;
    }
    return null;
}

pub fn decodeDecimalCanonical(value: []const u8) ReceiptError!u16 {
    if (value.len == 0 or (value.len > 1 and value[0] == '0')) {
        return error.ReceiptNonCanonical;
    }
    for (value) |byte| {
        if (!std.ascii.isDigit(byte)) return error.ReceiptNonCanonical;
    }
    return std.fmt.parseInt(u16, value, 10) catch return error.ReceiptNonCanonical;
}

pub fn decodeDecimalU64Canonical(value: []const u8) ReceiptError!u64 {
    if (value.len == 0 or (value.len > 1 and value[0] == '0')) {
        return error.ReceiptNonCanonical;
    }
    for (value) |byte| {
        if (!std.ascii.isDigit(byte)) return error.ReceiptNonCanonical;
    }
    return std.fmt.parseInt(u64, value, 10) catch return error.ReceiptNonCanonical;
}

pub fn decodeLowerHexNibble(byte: u8) ReceiptError!u8 {
    return switch (byte) {
        '0'...'9' => byte - '0',
        'a'...'f' => byte - 'a' + 10,
        else => error.ReceiptIdentityMalformed,
    };
}

pub fn decodeLowerHex(value: []const u8, output: []u8) ReceiptError!void {
    if (value.len != output.len * 2) return error.ReceiptIdentityMalformed;
    for (output, 0..) |*byte, index| {
        const high = try decodeLowerHexNibble(value[index * 2]);
        const low = try decodeLowerHexNibble(value[index * 2 + 1]);
        byte.* = (high << 4) | low;
    }
}

pub fn decodeSemanticBits(value: []const u8) ReceiptError!u32 {
    if (value.len != 8) return error.ReceiptNonCanonical;
    var result: u32 = 0;
    for (value) |byte| {
        result = (result << 4) | try decodeLowerHexNibble(byte);
    }
    return result;
}

pub fn decodeCanonicalReceipt(bytes: []const u8) ReceiptError!CanonicalAcceptanceReceipt {
    if (bytes.len == 0 or bytes.len > receipt_max_bytes) return error.ReceiptOversized;
    if (bytes[bytes.len - 1] != '\n') return error.ReceiptNonCanonical;

    var values: [receipt_field_names.len][]const u8 = undefined;
    var seen: u64 = 0;
    var field_count: usize = 0;
    var offset: usize = 0;
    while (offset < bytes.len) {
        const relative_end = std.mem.indexOfScalar(u8, bytes[offset..], '\n') orelse
            return error.ReceiptNonCanonical;
        const line_end = offset + relative_end;
        const line = bytes[offset..line_end];
        if (line.len == 0) return error.ReceiptNonCanonical;
        const equals = std.mem.indexOfScalar(u8, line, '=') orelse
            return error.ReceiptNonCanonical;
        if (equals == 0 or equals + 1 == line.len) return error.ReceiptNonCanonical;
        const name = line[0..equals];
        const value = line[equals + 1 ..];
        const index = receiptFieldIndex(name) orelse return error.ReceiptFieldUnknown;
        const bit = @as(u64, 1) << @intCast(index);
        if (seen & bit != 0) return error.ReceiptFieldDuplicate;
        if (index != field_count) return error.ReceiptFieldReordered;
        seen |= bit;
        values[index] = value;
        field_count += 1;
        offset = line_end + 1;
    }
    if (field_count != receipt_field_names.len) return error.ReceiptFieldMissing;

    const schema_version = try decodeDecimalCanonical(values[0]);
    if (schema_version != receipt_schema_version) return error.ReceiptSchemaUnsupported;
    const capability_version = try decodeDecimalCanonical(values[1]);
    if (capability_version != receipt_capability_version) {
        return error.ReceiptCapabilityUnsupported;
    }
    if (!std.mem.eql(u8, values[2], receipt_scope)) return error.ReceiptScopeUnsupported;
    if (!std.mem.eql(u8, values[3], receipt_selected_variant)) {
        return error.ReceiptVariantUnsupported;
    }
    var source_set: CanonicalSourceSet = undefined;
    for (&source_set.entries, 0..) |*entry, source_index| {
        const base = 4 + source_index * 5;
        entry.path = canonicalRepositoryPath(values[base]) catch
            return error.ReceiptPathMalformed;
        if (!std.mem.eql(u8, values[base + 1], "100644")) {
            return error.ReceiptSourceSetInvalid;
        }
        entry.mode = capability_source_mode;
        try decodeLowerHex(values[base + 2], &entry.git_blob_identity.bytes);
        try decodeLowerHex(values[base + 3], &entry.raw_sha256.bytes);
        entry.exact_length = try decodeDecimalU64Canonical(values[base + 4]);
    }
    validateCanonicalSourceSet(&source_set) catch return error.ReceiptSourceSetInvalid;
    const staged_base = 4 + capability_source_count * 5;
    if (!std.mem.eql(u8, values[staged_base], receipt_git_hash_algorithm)) {
        return error.ReceiptHashAlgorithmUnsupported;
    }
    var staged_tree_identity = GitSha1Identity{ .bytes = undefined };
    try decodeLowerHex(values[staged_base + 1], &staged_tree_identity.bytes);
    const toolchain_identity = try canonicalReceiptToken(values[staged_base + 2]);
    if (!std.mem.eql(u8, values[staged_base + 3], receipt_gate_ids)) {
        return error.ReceiptGateIdsInvalid;
    }
    const statuses = values[staged_base + 4];
    const comma = std.mem.indexOfScalar(u8, statuses, ',') orelse
        return error.ReceiptNonCanonical;
    if (std.mem.indexOfScalarPos(u8, statuses, comma + 1, ',') != null) {
        return error.ReceiptNonCanonical;
    }
    const format_status = try decodeDecimalCanonical(statuses[0..comma]);
    const focused_status = try decodeDecimalCanonical(statuses[comma + 1 ..]);
    if (format_status != 0 or focused_status != 0) return error.ReceiptStatusNonzero;
    const semantic_bits = try decodeSemanticBits(values[staged_base + 5]);
    if (semantic_bits & ~receipt_required_semantic_bits != 0) {
        return error.ReceiptSemanticBitsUnknown;
    }
    if (semantic_bits != receipt_required_semantic_bits) {
        return error.ReceiptSemanticBitsIncomplete;
    }
    if (!std.mem.eql(u8, values[staged_base + 6], "complete")) {
        return error.ReceiptCompletionInvalid;
    }

    const receipt = CanonicalAcceptanceReceipt{
        .schema_version = schema_version,
        .capability_version = capability_version,
        .source_set = source_set,
        .staged_tree_hash_algorithm = canonical_git_sha1_algorithm,
        .staged_tree_identity = staged_tree_identity,
        .zig_toolchain_identity = toolchain_identity,
        .format_status = @intCast(format_status),
        .focused_test_status = @intCast(focused_status),
        .semantic_gate_bits = semantic_bits,
        .completion_state = .complete,
    };
    try validateCanonicalReceipt(&receipt);
    return receipt;
}

pub fn syntheticAcceptanceReceipt() !CanonicalAcceptanceReceipt {
    const source_bytes = [capability_source_count][]const u8{
        "synthetic acceptance driver",
        "synthetic acceptance driver test",
        "synthetic provenance",
        "synthetic receipt",
        "synthetic materializer root",
    };
    return .{
        .schema_version = receipt_schema_version,
        .capability_version = receipt_capability_version,
        .source_set = try provenance.canonicalSourceSetFromBytes(source_bytes),
        .staged_tree_hash_algorithm = canonical_git_sha1_algorithm,
        .staged_tree_identity = .{ .bytes = fixedIdentity(20, 0x77) },
        .zig_toolchain_identity = try canonicalReceiptToken("zig-0.17.0-x86_64-linux"),
        .format_status = 0,
        .focused_test_status = 0,
        .semantic_gate_bits = receipt_required_semantic_bits,
        .completion_state = .complete,
    };
}

pub fn syncOwnedDirectory(directory: std.Io.Dir, io: std.Io) !void {
    const owned_directory_file = try directory.openFile(io, ".", .{
        .mode = .read_only,
        .allow_directory = true,
        .path_only = false,
        .follow_symlinks = false,
        .resolve_beneath = true,
    });
    defer owned_directory_file.close(io);
    try owned_directory_file.sync(io);
}

pub const syncBorrowedDirectory = syncOwnedDirectory;

pub fn deleteReceiptPathIfPresent(directory: std.Io.Dir, io: std.Io, name: []const u8) !void {
    directory.deleteFile(io, name) catch |err| switch (err) {
        error.FileNotFound => {},
        else => return err,
    };
}

pub fn publishCanonicalReceipt(
    comptime observe_regular_file: fn (std.posix.fd_t) anyerror!void,
    validation_directory: std.Io.Dir,
    io: std.Io,
    receipt: *const CanonicalAcceptanceReceipt,
    temporary_name: []const u8,
    final_name: []const u8,
) !PublicationResult {
    try validateComponentLexical(temporary_name);
    try validateComponentLexical(final_name);
    if (std.mem.eql(u8, temporary_name, final_name)) {
        return error.ReceiptPublicationNameCollision;
    }
    const encoded = try encodeCanonicalReceipt(receipt);
    const encoded_bytes = try canonicalReceiptBytesSlice(&encoded);
    _ = try decodeCanonicalReceipt(encoded_bytes);

    var temporary_created = false;
    errdefer if (temporary_created) {
        deleteReceiptPathIfPresent(validation_directory, io, temporary_name) catch {};
    };
    var temporary_file = try validation_directory.createFile(io, temporary_name, .{
        .read = false,
        .truncate = false,
        .exclusive = true,
    });
    temporary_created = true;
    var temporary_open = true;
    errdefer if (temporary_open) temporary_file.close(io);
    try temporary_file.writeStreamingAll(io, encoded_bytes);
    try temporary_file.sync(io);
    temporary_file.close(io);
    temporary_open = false;

    try validation_directory.renamePreserve(
        temporary_name,
        validation_directory,
        final_name,
        io,
    );
    temporary_created = false;
    var final_created = true;
    errdefer if (final_created) {
        deleteReceiptPathIfPresent(validation_directory, io, final_name) catch {};
    };
    try syncOwnedDirectory(validation_directory, io);

    const final_file = try validation_directory.openFile(io, final_name, .{
        .mode = .read_only,
        .follow_symlinks = false,
        .resolve_beneath = true,
    });
    defer final_file.close(io);
    try observe_regular_file(final_file.handle);
    var read_back: [receipt_max_bytes]u8 = undefined;
    const expected = encoded_bytes;
    const count = try final_file.readPositionalAll(io, read_back[0..expected.len], 0);
    if (count != expected.len or !std.mem.eql(u8, read_back[0..count], expected)) {
        return error.ReceiptReadBackMismatch;
    }
    var trailing: [1]u8 = undefined;
    const trailing_count = try final_file.readPositionalAll(io, &trailing, expected.len);
    if (trailing_count != 0) return error.ReceiptReadBackMismatch;
    const decoded = try decodeCanonicalReceipt(read_back[0..count]);
    if (!std.meta.eql(decoded, receipt.*)) return error.ReceiptReadBackMismatch;

    var final_digest: [std.crypto.hash.sha2.Sha256.digest_length]u8 = undefined;
    std.crypto.hash.sha2.Sha256.hash(read_back[0..count], &final_digest, .{});
    final_created = false;
    return .{
        .final_sha256 = .{ .bytes = final_digest },
        .exact_length = @intCast(count),
        .completion_status = .complete,
    };
}

pub fn mutateReceiptFieldValue(
    encoded: *CanonicalReceiptBytes,
    name: []const u8,
    replacement: []const u8,
) !void {
    var prefix_buffer: [96]u8 = undefined;
    if (name.len + 1 > prefix_buffer.len) return error.TestUnexpectedResult;
    @memcpy(prefix_buffer[0..name.len], name);
    prefix_buffer[name.len] = '=';
    const prefix = prefix_buffer[0 .. name.len + 1];
    const encoded_bytes = try canonicalReceiptBytesSlice(encoded);
    const start = std.mem.indexOf(u8, encoded_bytes, prefix) orelse
        return error.TestUnexpectedResult;
    const value_start = start + prefix.len;
    const relative_end = std.mem.indexOfScalar(u8, encoded_bytes[value_start..], '\n') orelse
        return error.TestUnexpectedResult;
    if (relative_end != replacement.len) return error.TestUnexpectedResult;
    @memcpy(encoded.bytes[value_start..][0..replacement.len], replacement);
}

pub fn openCnValidationDirectory(io: std.Io) !std.Io.Dir {
    return std.Io.Dir.cwd().openDir(io, "local-state/validations/inbox206cn", .{
        .access_sub_paths = true,
        .iterate = true,
        .follow_symlinks = false,
    });
}

pub fn expectReceiptPathMissing(directory: std.Io.Dir, io: std.Io, name: []const u8) !void {
    if (directory.openFile(io, name, .{ .follow_symlinks = false })) |file| {
        file.close(io);
        return error.TestUnexpectedResult;
    } else |err| {
        try std.testing.expect(err == error.FileNotFound);
    }
}

pub const publication_target_max = 128;

pub const ValidatedPublicationTarget = struct {
    length: u8,
    bytes: [publication_target_max]u8,

    pub fn slice(self: *const ValidatedPublicationTarget) ReceiptBindingError![]const u8 {
        return publicationTargetSlice(self);
    }
};

pub const ReceiptBindingError = error{
    PublicationContextMismatch,
    PublicationDirectoryMismatch,
    PublicationTargetMismatch,
    PublicationBytesMismatch,
    PublicationDigestMismatch,
    PublicationLengthMismatch,
    PublicationIncomplete,
    PublicationTargetInvalid,
};

pub fn validatePublicationTarget(bytes: []const u8) ReceiptBindingError!ValidatedPublicationTarget {
    if (bytes.len == 0 or bytes.len > publication_target_max) {
        return error.PublicationTargetInvalid;
    }
    if (std.mem.eql(u8, bytes, ".") or std.mem.eql(u8, bytes, "..")) {
        return error.PublicationTargetInvalid;
    }
    for (bytes) |byte| {
        if (byte == '/' or byte == 0) return error.PublicationTargetInvalid;
    }
    var target = ValidatedPublicationTarget{
        .length = @intCast(bytes.len),
        .bytes = @splat(0),
    };
    @memcpy(target.bytes[0..bytes.len], bytes);
    return target;
}

pub fn validatePublicationTargetValue(
    target: *const ValidatedPublicationTarget,
) ReceiptBindingError!void {
    const length = std.math.cast(usize, target.length) orelse
        return error.PublicationTargetInvalid;
    if (length == 0 or length > target.bytes.len) return error.PublicationTargetInvalid;
    if (!std.mem.allEqual(u8, target.bytes[length..], 0)) {
        return error.PublicationTargetInvalid;
    }
    const used = target.bytes[0..length];
    if (std.mem.eql(u8, used, ".") or std.mem.eql(u8, used, "..")) {
        return error.PublicationTargetInvalid;
    }
    for (used) |byte| {
        if (byte == '/' or byte == 0) return error.PublicationTargetInvalid;
    }
}

pub fn publicationTargetSlice(
    target: *const ValidatedPublicationTarget,
) ReceiptBindingError![]const u8 {
    try validatePublicationTargetValue(target);
    const length = std.math.cast(usize, target.length) orelse
        return error.PublicationTargetInvalid;
    return target.bytes[0..length];
}

pub fn equalPublicationTarget(
    left: *const ValidatedPublicationTarget,
    right: *const ValidatedPublicationTarget,
) ReceiptBindingError!bool {
    const left_bytes = try publicationTargetSlice(left);
    const right_bytes = try publicationTargetSlice(right);
    return std.mem.eql(u8, left_bytes, right_bytes);
}

pub fn publicationReceiptBytesSlice(
    value: *const CanonicalReceiptBytes,
) ReceiptBindingError![]const u8 {
    const length = std.math.cast(usize, value.length) orelse
        return error.PublicationLengthMismatch;
    if (length == 0 or length > value.bytes.len) return error.PublicationLengthMismatch;
    if (!std.mem.allEqual(u8, value.bytes[length..], 0)) {
        return error.PublicationBytesMismatch;
    }
    return value.bytes[0..length];
}

pub fn equalPublicationReceiptBytes(
    left: *const CanonicalReceiptBytes,
    right: *const CanonicalReceiptBytes,
) ReceiptBindingError!bool {
    const left_bytes = try publicationReceiptBytesSlice(left);
    const right_bytes = try publicationReceiptBytesSlice(right);
    return std.mem.eql(u8, left_bytes, right_bytes);
}

pub fn BoundReceiptTypes(
    comptime AcceptanceAuthorityContext: type,
    comptime AuthenticatedValidationDirectory: type,
) type {
    return struct {
        pub const PreparedReceipt = struct {
            context: *const AcceptanceAuthorityContext,
            validation_directory: AuthenticatedValidationDirectory,
            final_target: ValidatedPublicationTarget,
            receipt: CanonicalAcceptanceReceipt,
            canonical_bytes: CanonicalReceiptBytes,
            canonical_sha256: RawSha256Identity,
            exact_length: u64,
        };

        pub const PublishedReceipt = struct {
            context: *const AcceptanceAuthorityContext,
            validation_directory: AuthenticatedValidationDirectory,
            final_target: ValidatedPublicationTarget,
            receipt: CanonicalAcceptanceReceipt,
            canonical_bytes: CanonicalReceiptBytes,
            canonical_sha256: RawSha256Identity,
            exact_length: u64,
            publication_identity: PublicationResult,
        };

        pub fn bindPublishedReceipt(
            prepared: *const PreparedReceipt,
            context: *const AcceptanceAuthorityContext,
            validation_directory: AuthenticatedValidationDirectory,
            final_target: ValidatedPublicationTarget,
            publication_identity: PublicationResult,
        ) !PublishedReceipt {
            if (context != prepared.context) return error.PublicationContextMismatch;
            if (validation_directory.context != context or
                !std.meta.eql(
                    validation_directory.descriptor_identity,
                    prepared.validation_directory.descriptor_identity,
                ))
            {
                return error.PublicationDirectoryMismatch;
            }
            try validateCanonicalReceipt(&prepared.receipt);
            _ = try publicationTargetSlice(&final_target);
            _ = try publicationTargetSlice(&prepared.final_target);
            _ = try publicationReceiptBytesSlice(&prepared.canonical_bytes);
            if (!try equalPublicationTarget(&final_target, &prepared.final_target)) {
                return error.PublicationTargetMismatch;
            }
            if (prepared.exact_length == 0 or
                prepared.exact_length != prepared.canonical_bytes.length)
            {
                return error.PublicationLengthMismatch;
            }
            const encoded = encodeCanonicalReceipt(&prepared.receipt) catch
                return error.PublicationBytesMismatch;
            if (!try equalPublicationReceiptBytes(&encoded, &prepared.canonical_bytes)) {
                return error.PublicationBytesMismatch;
            }
            var digest: [std.crypto.hash.sha2.Sha256.digest_length]u8 = undefined;
            std.crypto.hash.sha2.Sha256.hash(
                try publicationReceiptBytesSlice(&encoded),
                &digest,
                .{},
            );
            if (!equalRawIdentity(.{ .bytes = digest }, prepared.canonical_sha256)) {
                return error.PublicationDigestMismatch;
            }
            if (publication_identity.completion_status != .complete) {
                return error.PublicationIncomplete;
            }
            if (publication_identity.exact_length == 0 or
                publication_identity.exact_length != prepared.exact_length)
            {
                return error.PublicationLengthMismatch;
            }
            if (!equalRawIdentity(
                publication_identity.final_sha256,
                prepared.canonical_sha256,
            )) return error.PublicationDigestMismatch;
            return .{
                .context = context,
                .validation_directory = validation_directory,
                .final_target = final_target,
                .receipt = prepared.receipt,
                .canonical_bytes = prepared.canonical_bytes,
                .canonical_sha256 = prepared.canonical_sha256,
                .exact_length = prepared.exact_length,
                .publication_identity = publication_identity,
            };
        }
    };
}

test "canonical synthetic receipt encoding round trips deterministically" {
    const receipt = try syntheticAcceptanceReceipt();
    const first = try encodeCanonicalReceipt(&receipt);
    const second = try encodeCanonicalReceipt(&receipt);
    try std.testing.expectEqualSlices(
        u8,
        try canonicalReceiptBytesSlice(&first),
        try canonicalReceiptBytesSlice(&second),
    );
    const decoded = try decodeCanonicalReceipt(try canonicalReceiptBytesSlice(&first));
    try std.testing.expect(std.meta.eql(receipt, decoded));
    try std.testing.expect(std.mem.indexOf(
        u8,
        try canonicalReceiptBytesSlice(&first),
        "scope=synthetic_only\n",
    ) != null);
    try std.testing.expect(std.mem.indexOf(
        u8,
        try canonicalReceiptBytesSlice(&first),
        "selected_variant=none\n",
    ) != null);
    try std.testing.expect(std.mem.indexOf(
        u8,
        try canonicalReceiptBytesSlice(&first),
        "synthetic_authority_binding",
    ) != null);
    try std.testing.expectEqual(@as(usize, 36), receipt_field_names.len);
    for (provenance.capability_source_paths, 0..) |path, index| {
        var expected_buffer: [320]u8 = undefined;
        const expected = try std.fmt.bufPrint(
            &expected_buffer,
            "source_{d}_path={s}\n",
            .{ index, path },
        );
        try std.testing.expect(std.mem.indexOf(
            u8,
            try canonicalReceiptBytesSlice(&first),
            expected,
        ) != null);
    }
}

test "owned directory sync publication and collision work from non-iterable directory" {
    const io = std.testing.io;
    var temporary = std.testing.tmpDir(.{});
    defer temporary.cleanup();
    var non_iterable_directory = try temporary.dir.openDir(io, ".", .{
        .access_sub_paths = true,
        .iterate = false,
        .follow_symlinks = false,
    });
    defer non_iterable_directory.close(io);

    try syncOwnedDirectory(non_iterable_directory, io);
    const Observer = struct {
        fn observe(_: std.posix.fd_t) !void {}
    };
    const receipt = try syntheticAcceptanceReceipt();
    const publication = try publishCanonicalReceipt(
        Observer.observe,
        non_iterable_directory,
        io,
        &receipt,
        "owned-sync.tmp",
        "owned-sync.final",
    );
    try std.testing.expect(publication.exact_length != 0);
    try std.testing.expectEqual(ReceiptCompletionState.complete, publication.completion_status);
    try std.testing.expectError(
        error.PathAlreadyExists,
        publishCanonicalReceipt(
            Observer.observe,
            non_iterable_directory,
            io,
            &receipt,
            "owned-sync.tmp",
            "owned-sync.final",
        ),
    );
}

test "publication targets are validated single components" {
    try std.testing.expectError(error.PublicationTargetInvalid, validatePublicationTarget(""));
    try std.testing.expectError(error.PublicationTargetInvalid, validatePublicationTarget("."));
    try std.testing.expectError(error.PublicationTargetInvalid, validatePublicationTarget(".."));
    try std.testing.expectError(error.PublicationTargetInvalid, validatePublicationTarget("a/b"));
    try std.testing.expectError(error.PublicationTargetInvalid, validatePublicationTarget("a\x00b"));
    const target = try validatePublicationTarget("receipt.tsv");
    try std.testing.expectEqualStrings("receipt.tsv", try target.slice());
}

test "fixed receipt buffers validate bounds and zero tails before slicing" {
    const one_token = try canonicalReceiptToken("x");
    try std.testing.expectEqualStrings("x", try one_token.slice());

    const exact_token_input: [receipt_toolchain_identity_max]u8 = @splat('a');
    const exact_token = try canonicalReceiptToken(&exact_token_input);
    try std.testing.expectEqual(
        @as(usize, receipt_toolchain_identity_max),
        (try exact_token.slice()).len,
    );

    var malformed_token = one_token;
    malformed_token.length = 0;
    try std.testing.expectError(error.ReceiptIdentityMalformed, malformed_token.slice());
    malformed_token = one_token;
    malformed_token.length = @intCast(receipt_toolchain_identity_max + 1);
    try std.testing.expectError(error.ReceiptIdentityMalformed, malformed_token.slice());
    malformed_token = one_token;
    malformed_token.length = std.math.maxInt(u8);
    try std.testing.expectError(error.ReceiptIdentityMalformed, malformed_token.slice());
    malformed_token = one_token;
    malformed_token.bytes[1] = 1;
    try std.testing.expectError(error.ReceiptIdentityMalformed, malformed_token.slice());

    const one_bytes = CanonicalReceiptBytes{
        .length = 1,
        .bytes = blk: {
            var b: [receipt_max_bytes]u8 = @splat(0);
            b[0] = 'x';
            break :blk b;
        },
    };
    try std.testing.expectEqualStrings("x", try canonicalReceiptBytesSlice(&one_bytes));

    const exact_bytes = CanonicalReceiptBytes{
        .length = receipt_max_bytes,
        .bytes = @splat('x'),
    };
    try std.testing.expectEqual(
        @as(usize, receipt_max_bytes),
        (try canonicalReceiptBytesSlice(&exact_bytes)).len,
    );

    var malformed_bytes = one_bytes;
    malformed_bytes.length = 0;
    try std.testing.expectError(
        error.ReceiptNonCanonical,
        canonicalReceiptBytesSlice(&malformed_bytes),
    );
    try std.testing.expectError(
        error.PublicationLengthMismatch,
        publicationReceiptBytesSlice(&malformed_bytes),
    );
    malformed_bytes = one_bytes;
    malformed_bytes.length = @intCast(receipt_max_bytes + 1);
    try std.testing.expectError(
        error.ReceiptOversized,
        canonicalReceiptBytesSlice(&malformed_bytes),
    );
    try std.testing.expectError(
        error.PublicationLengthMismatch,
        publicationReceiptBytesSlice(&malformed_bytes),
    );
    malformed_bytes = one_bytes;
    malformed_bytes.length = std.math.maxInt(u16);
    try std.testing.expectError(
        error.ReceiptOversized,
        canonicalReceiptBytesSlice(&malformed_bytes),
    );
    malformed_bytes = one_bytes;
    malformed_bytes.bytes[1] = 1;
    try std.testing.expectError(
        error.ReceiptNonCanonical,
        canonicalReceiptBytesSlice(&malformed_bytes),
    );
    try std.testing.expectError(
        error.PublicationBytesMismatch,
        publicationReceiptBytesSlice(&malformed_bytes),
    );
    try std.testing.expectError(
        error.ReceiptNonCanonical,
        equalCanonicalReceiptBytes(&one_bytes, &malformed_bytes),
    );
    try std.testing.expectError(
        error.PublicationBytesMismatch,
        equalPublicationReceiptBytes(&one_bytes, &malformed_bytes),
    );

    const one_target = try validatePublicationTarget("x");
    try std.testing.expectEqualStrings("x", try one_target.slice());
    const exact_target_input: [publication_target_max]u8 = @splat('a');
    const exact_target = try validatePublicationTarget(&exact_target_input);
    try std.testing.expectEqual(
        @as(usize, publication_target_max),
        (try exact_target.slice()).len,
    );

    var malformed_target = one_target;
    malformed_target.length = 0;
    try std.testing.expectError(error.PublicationTargetInvalid, malformed_target.slice());
    malformed_target = one_target;
    malformed_target.length = @intCast(publication_target_max + 1);
    try std.testing.expectError(error.PublicationTargetInvalid, malformed_target.slice());
    malformed_target = one_target;
    malformed_target.length = std.math.maxInt(u8);
    try std.testing.expectError(error.PublicationTargetInvalid, malformed_target.slice());
    malformed_target = one_target;
    malformed_target.bytes[1] = 1;
    try std.testing.expectError(error.PublicationTargetInvalid, malformed_target.slice());
    malformed_target = one_target;
    malformed_target.bytes[0] = '/';
    try std.testing.expectError(error.PublicationTargetInvalid, malformed_target.slice());
    try std.testing.expectError(
        error.PublicationTargetInvalid,
        equalPublicationTarget(&one_target, &malformed_target),
    );
}

test "canonical receipt rejects unknown duplicate missing reordered oversized and noncanonical fields" {
    try std.testing.expectError(
        error.ReceiptFieldUnknown,
        decodeCanonicalReceipt("unknown=1\n"),
    );
    try std.testing.expectError(
        error.ReceiptFieldDuplicate,
        decodeCanonicalReceipt("schema_version=1\nschema_version=1\n"),
    );
    try std.testing.expectError(
        error.ReceiptFieldMissing,
        decodeCanonicalReceipt("schema_version=1\n"),
    );
    try std.testing.expectError(
        error.ReceiptFieldReordered,
        decodeCanonicalReceipt("capability_version=1\nschema_version=1\n"),
    );
    var oversized: [receipt_max_bytes + 1]u8 = @splat('x');
    oversized[oversized.len - 1] = '\n';
    try std.testing.expectError(
        error.ReceiptOversized,
        decodeCanonicalReceipt(&oversized),
    );
    try std.testing.expectError(
        error.ReceiptNonCanonical,
        decodeCanonicalReceipt("schema_version=1"),
    );
}

test "canonical receipt rejects unsupported schema scope variant and completion" {
    const receipt = try syntheticAcceptanceReceipt();

    var changed = try encodeCanonicalReceipt(&receipt);
    try mutateReceiptFieldValue(&changed, "schema_version", "1");
    try std.testing.expectError(
        error.ReceiptSchemaUnsupported,
        decodeCanonicalReceipt(try canonicalReceiptBytesSlice(&changed)),
    );

    changed = try encodeCanonicalReceipt(&receipt);
    try mutateReceiptFieldValue(&changed, "capability_version", "1");
    try std.testing.expectError(
        error.ReceiptCapabilityUnsupported,
        decodeCanonicalReceipt(try canonicalReceiptBytesSlice(&changed)),
    );

    changed = try encodeCanonicalReceipt(&receipt);
    try mutateReceiptFieldValue(&changed, "scope", "synthetic_fake");
    try std.testing.expectError(
        error.ReceiptScopeUnsupported,
        decodeCanonicalReceipt(try canonicalReceiptBytesSlice(&changed)),
    );

    changed = try encodeCanonicalReceipt(&receipt);
    try mutateReceiptFieldValue(&changed, "selected_variant", "some");
    try std.testing.expectError(
        error.ReceiptVariantUnsupported,
        decodeCanonicalReceipt(try canonicalReceiptBytesSlice(&changed)),
    );

    changed = try encodeCanonicalReceipt(&receipt);
    try mutateReceiptFieldValue(&changed, "completion_state", "pendingx");
    try std.testing.expectError(
        error.ReceiptCompletionInvalid,
        decodeCanonicalReceipt(try canonicalReceiptBytesSlice(&changed)),
    );
}

test "canonical receipt rejects malformed path identities algorithms and gate IDs" {
    const receipt = try syntheticAcceptanceReceipt();

    var changed = try encodeCanonicalReceipt(&receipt);
    var invalid_path: ["tools/zllvm_inbox206/acceptance_driver.zig".len]u8 = undefined;
    @memcpy(&invalid_path, "tools/zllvm_inbox206/acceptance_driver.zig");
    invalid_path[0] = '/';
    try mutateReceiptFieldValue(&changed, "source_0_path", &invalid_path);
    try std.testing.expectError(
        error.ReceiptPathMalformed,
        decodeCanonicalReceipt(try canonicalReceiptBytesSlice(&changed)),
    );

    changed = try encodeCanonicalReceipt(&receipt);
    var wrong_path: ["tools/zllvm_inbox206/acceptance_driver.zig".len]u8 = undefined;
    @memcpy(&wrong_path, "tools/zllvm_inbox206/acceptance_driver.zig");
    wrong_path[wrong_path.len - 2] = 'a';
    try mutateReceiptFieldValue(
        &changed,
        "source_0_path",
        &wrong_path,
    );
    try std.testing.expectError(
        error.ReceiptSourceSetInvalid,
        decodeCanonicalReceipt(try canonicalReceiptBytesSlice(&changed)),
    );

    changed = try encodeCanonicalReceipt(&receipt);
    var invalid_raw: [64]u8 = undefined;
    encodeLowerHex(&receipt.source_set.entries[0].raw_sha256.bytes, &invalid_raw);
    invalid_raw[0] = 'A';
    try mutateReceiptFieldValue(&changed, "source_0_raw_sha256", &invalid_raw);
    try std.testing.expectError(
        error.ReceiptIdentityMalformed,
        decodeCanonicalReceipt(try canonicalReceiptBytesSlice(&changed)),
    );

    changed = try encodeCanonicalReceipt(&receipt);
    try mutateReceiptFieldValue(&changed, "source_0_mode", "100755");
    try std.testing.expectError(
        error.ReceiptSourceSetInvalid,
        decodeCanonicalReceipt(try canonicalReceiptBytesSlice(&changed)),
    );

    var invalid_length_receipt = receipt;
    invalid_length_receipt.source_set.entries[0].exact_length = 0;
    try std.testing.expectError(
        error.ReceiptSourceSetInvalid,
        validateCanonicalReceipt(&invalid_length_receipt),
    );

    changed = try encodeCanonicalReceipt(&receipt);
    var invalid_blob: [40]u8 = undefined;
    encodeLowerHex(&receipt.source_set.entries[0].git_blob_identity.bytes, &invalid_blob);
    invalid_blob[0] = 'G';
    try mutateReceiptFieldValue(&changed, "source_0_git_blob", &invalid_blob);
    try std.testing.expectError(
        error.ReceiptIdentityMalformed,
        decodeCanonicalReceipt(try canonicalReceiptBytesSlice(&changed)),
    );

    changed = try encodeCanonicalReceipt(&receipt);
    try mutateReceiptFieldValue(&changed, "staged_tree_hash_algorithm", "sha2");
    try std.testing.expectError(
        error.ReceiptHashAlgorithmUnsupported,
        decodeCanonicalReceipt(try canonicalReceiptBytesSlice(&changed)),
    );

    changed = try encodeCanonicalReceipt(&receipt);
    var invalid_tree: [40]u8 = undefined;
    encodeLowerHex(&receipt.staged_tree_identity.bytes, &invalid_tree);
    invalid_tree[0] = 'A';
    try mutateReceiptFieldValue(&changed, "staged_tree_identity", &invalid_tree);
    try std.testing.expectError(
        error.ReceiptIdentityMalformed,
        decodeCanonicalReceipt(try canonicalReceiptBytesSlice(&changed)),
    );

    changed = try encodeCanonicalReceipt(&receipt);
    var invalid_toolchain: ["zig-0.17.0-x86_64-linux".len]u8 = undefined;
    @memcpy(&invalid_toolchain, "zig-0.17.0-x86_64-linux");
    invalid_toolchain[0] = ' ';
    try mutateReceiptFieldValue(&changed, "zig_toolchain_identity", &invalid_toolchain);
    try std.testing.expectError(
        error.ReceiptIdentityMalformed,
        decodeCanonicalReceipt(try canonicalReceiptBytesSlice(&changed)),
    );

    changed = try encodeCanonicalReceipt(&receipt);
    var invalid_gates: [receipt_gate_ids.len]u8 = undefined;
    @memcpy(&invalid_gates, receipt_gate_ids);
    invalid_gates[0] = 'x';
    try mutateReceiptFieldValue(&changed, "stable_symbolic_gate_ids", &invalid_gates);
    try std.testing.expectError(
        error.ReceiptGateIdsInvalid,
        decodeCanonicalReceipt(try canonicalReceiptBytesSlice(&changed)),
    );
}

test "canonical receipt rejects nonzero statuses and incomplete or unknown semantic bits" {
    const receipt = try syntheticAcceptanceReceipt();

    var changed = try encodeCanonicalReceipt(&receipt);
    try mutateReceiptFieldValue(
        &changed,
        "numeric_format_and_focused_test_statuses",
        "1,0",
    );
    try std.testing.expectError(
        error.ReceiptStatusNonzero,
        decodeCanonicalReceipt(try canonicalReceiptBytesSlice(&changed)),
    );

    changed = try encodeCanonicalReceipt(&receipt);
    try mutateReceiptFieldValue(&changed, "semantic_gate_bits", "0000007e");
    try std.testing.expectError(
        error.ReceiptSemanticBitsIncomplete,
        decodeCanonicalReceipt(try canonicalReceiptBytesSlice(&changed)),
    );

    changed = try encodeCanonicalReceipt(&receipt);
    try mutateReceiptFieldValue(&changed, "semantic_gate_bits", "000000ff");
    try std.testing.expectError(
        error.ReceiptSemanticBitsUnknown,
        decodeCanonicalReceipt(try canonicalReceiptBytesSlice(&changed)),
    );
}
