const std = @import("std");
const authority_control = @import("authority_control.zig");
const digest = @import("digest.zig");
const exact_real_observer = @import("exact_real_observer.zig");
const filesystem = @import("filesystem.zig");
const manifest = @import("manifest.zig");
const registration = @import("registration.zig");

const main_repository = registration.main_repository;
const DormantAuthorityValidation = authority_control.API.AuthorityValidation;
const DormantReadinessNetEffects = exact_real_observer.API.NetEffects;
const DormantExactAcceptanceSnapshotIdentity = exact_real_observer.API.SnapshotIdentity;
const sha256Hex = digest.sha256Hex;
const encodeField = manifest.encodeField;
const validateCanonicalField = manifest.validateCanonicalField;
const validateSha = manifest.validateSha;
const openExistingDir = filesystem.openExistingDir;
const openOrCreateDir = filesystem.openOrCreateDir;
const syncDirectory = filesystem.syncDirectory;

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

pub const API = struct {
    pub const receipt_directory = dormant_exact_real_acceptance_receipt_directory;
    pub const receipt_basename = dormant_exact_real_acceptance_receipt_basename;
    pub const Evidence = DormantExactAcceptanceEvidence;
    pub const ParsedReceipt = DormantExactAcceptanceParsedReceipt;
    pub const PublishFault = DormantExactAcceptancePublishFault;
    pub const parseInteger = parseDormantExactAcceptanceInteger;
    pub const encode = encodeDormantExactAcceptanceReceipt;
    pub const parse = parseDormantExactAcceptanceReceipt;
    pub const validate = validateDormantExactAcceptanceReceipt;
    pub const read = readDormantExactAcceptanceReceipt;
    pub const publish = publishDormantExactAcceptanceReceipt;
    pub const openDirectory = openDormantExactAcceptanceReceiptDirectory;
};
