const std = @import("std");
const builtin = @import("builtin");
const authority_control = @import("authority_control.zig");
const exact_real_observer = @import("exact_real_observer.zig");
const exact_real_receipt = @import("exact_real_receipt.zig");

const DormantAuthorityConfig = authority_control.API.AuthorityConfig;
const DormantAuthorityValidation = authority_control.API.AuthorityValidation;
const validateDormantAuthorityCandidate = authority_control.API.validateCandidate;
const dormant_exact_real_copy_evidence_path =
    authority_control.API.exact_real_copy_evidence_path;
const dormant_exact_real_copy_evidence_sha256 =
    authority_control.API.exact_real_copy_evidence_sha256;
const captureDormantExactRealObservation = exact_real_observer.API.captureObservation;
const compareDormantExactRealObservations = exact_real_observer.API.compareObservations;
const DormantExactAcceptanceEvidence = exact_real_receipt.API.Evidence;
const encodeDormantExactAcceptanceReceipt = exact_real_receipt.API.encode;
const publishDormantExactAcceptanceReceipt = exact_real_receipt.API.publish;
const openDormantExactAcceptanceReceiptDirectory = exact_real_receipt.API.openDirectory;

const dormant_exact_real_source_manifest_sha256 =
    "61b7426bd52a3a139999f17f36d91ecaab954e6132fe36eca541480cdf31104d";
const dormant_exact_real_source_inventory_sha256 =
    "3234fb508d370878efe082cf1accb5af3b488372bf3f1ee7e9e87408a37a2d7c";
const dormant_exact_real_source_file_ledger_sha256 =
    "a06c48e1549d16b9f924cc2b5f0404e60d7755a785bf3a4a23311c2383279a65";
const dormant_exact_real_source_destination_ledger_sha256 =
    "4c29709b9ef9242dd799ab52d346cdf302f5728d35e37e0d78063e892a6cf9e8";
pub const acceptance_environment = "ZLLVM_INBOX206CQ_EXACT_REAL_ACCEPTANCE";
const acceptance_token = "INBOX-206CQ-EXACT-REAL-ACCEPTANCE-V1";

pub const ExactRealValidationInput = struct {
    allocator: std.mem.Allocator,
    io: std.Io,
    source_manifest_sha256: []const u8,
    source_inventory_sha256: []const u8,
    source_file_ledger_sha256: []const u8,
    source_destination_ledger_sha256: []const u8,
    copy_evidence_path: []const u8,
    copy_evidence_sha256: []const u8,
};

pub const ValidationReadinessInput = union(enum) {
    exact_real: ExactRealValidationInput,
    synthetic: *const DormantAuthorityConfig,
};

fn invokeValidationReadiness(input: ValidationReadinessInput) !DormantAuthorityValidation {
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

pub fn callValidationReadiness(
    input: ValidationReadinessInput,
) !DormantAuthorityValidation {
    if (!builtin.is_test) return error.TestOnlyOperation;
    return invokeValidationReadiness(input);
}

fn requireAcceptanceGate(token: ?[]const u8) !void {
    if (!builtin.is_test) return error.TestOnlyOperation;
    const value = token orelse return error.SkipZigTest;
    if (!std.mem.eql(u8, value, acceptance_token)) {
        return error.SkipZigTest;
    }
}

fn requireAcceptanceValidation(validation: DormantAuthorityValidation) !void {
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

pub fn runAcceptanceForTest(
    allocator: std.mem.Allocator,
    io: std.Io,
    token: ?[]const u8,
) !void {
    if (!builtin.is_test) return error.TestOnlyOperation;
    try requireAcceptanceGate(token);

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
    try requireAcceptanceValidation(validation);
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
