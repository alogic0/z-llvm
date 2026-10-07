const std = @import("std");
const contract = @import("../o2_compiler_rt_v1_baseline_validation.zig");
const process = @import("process.zig");
const inputs = @import("authenticated_inputs.zig");
const storage = @import("storage.zig");

pub const schema = "o2-compiler-rt-v1-baseline-closure-v3";
pub const maximum_bytes: usize = 64 * 1024;
pub const name = "baseline-validation-closure-v1.tsv";
const temporary_name = ".baseline-validation-closure-v1.tsv.tmp";

pub const RegisteredWorktreeSetIdentity = struct {
    count: u8,
    sha256: contract.Digest,
};

pub const RestorationIdentity = struct {
    repository: contract.Digest,
    canonical_source: contract.Digest,
    coverage_source: contract.Digest,
    accepted_input: contract.Digest,
};

pub const CompleteRunObservation = struct {
    identities: []const contract.IdentityDescriptor,
    compatibility_keys: []const []const u8,
    repetitions: []const contract.CanonicalRepetition,
    raw_report: contract.RawReportBinding,
    coverage: contract.CoverageState,
    restoration: contract.RestorationState,
    semantic_equality: contract.SemanticEquality,
    phases: contract.PhaseMachine,
    family_usage: []const storage.FamilyUsage,
    available_bytes: u64,
    before: RestorationIdentity,
    after: RestorationIdentity,
};

pub const Binding = struct {
    tools: inputs.SubjectSet,
    fixed_sources: contract.Digest,
    fixed_inputs: contract.Digest,
    raw_report: contract.RawReportBinding,
    canonical_artifact: inputs.FileIdentity,
    coverage_artifact: inputs.FileIdentity,
    canonical_observations: contract.Digest,
    coverage_off_observation: contract.Digest,
    coverage_on_observation: contract.Digest,
    counter_result: contract.Digest,
    registered_worktrees: RegisteredWorktreeSetIdentity,
    family_usage: contract.Digest,
    completion: bool,
};

pub const ValidatedRun = struct {
    retained_bytes: u64,
    raw_report: contract.RawReportBinding,
    before: RestorationIdentity,
    after: RestorationIdentity,
    available_bytes: u64,
};

pub const Published = struct { bytes: u64, sha256: contract.Digest };

pub fn requireRestorationEqual(before: RestorationIdentity, after: RestorationIdentity) !void {
    if (!std.meta.eql(before, after)) return error.RestorationMismatch;
}

pub fn validateCompletedPhases(phases: contract.PhaseMachine) !void {
    if (phases.first_failure != null or phases.next != phases.statuses.len)
        return error.ClosurePrecondition;
    for (phases.statuses) |status| if (status != .succeeded) return error.ClosurePrecondition;
}

pub fn validateCompleteRun(observation: CompleteRunObservation) !ValidatedRun {
    try contract.validateIdentities(observation.identities);
    try contract.validateCompatibilityKeys(observation.compatibility_keys);
    try contract.validateCanonicalRepetitions(observation.repetitions, observation.raw_report);
    try contract.validateCoverage(observation.coverage);
    try contract.validateRestoration(observation.restoration);
    try contract.validateSemanticEquality(observation.semantic_equality);
    try validateCompletedPhases(observation.phases);
    const tracker = try storage.validateStorageRoot(observation.family_usage, observation.available_bytes);
    try requireRestorationEqual(observation.before, observation.after);
    return .{
        .retained_bytes = tracker.total_retained_bytes,
        .raw_report = observation.raw_report,
        .before = observation.before,
        .after = observation.after,
        .available_bytes = observation.available_bytes,
    };
}

fn orderedTools(subjects: inputs.SubjectSet) [6]inputs.AuthenticatedSubject {
    return .{ subjects.zig, subjects.git, subjects.llvm_extract, subjects.objcopy, subjects.objdump, subjects.readelf };
}

pub fn validateToolBindings(subjects: inputs.SubjectSet) !void {
    const tools = orderedTools(subjects);
    const roles = [_]inputs.ToolRole{ .zig, .git, .llvm_extract, .objcopy, .objdump, .readelf };
    for (tools, roles) |tool, role| {
        const portable = tool.portable_tool orelse return error.SubjectAuthorityMismatch;
        if (portable.role != role or portable.bytes != tool.identity.bytes or
            !std.mem.eql(u8, &portable.sha256, &tool.identity.sha256)) return error.SubjectAuthorityMismatch;
        if ((role == .zig) != (portable.version != null)) return error.SubjectAuthorityMismatch;
        if (portable.version) |version| if (!std.mem.eql(u8, version, inputs.expected_zig_version))
            return error.SubjectAuthorityMismatch;
    }
}

pub fn completeEnforcementEvidence(
    families: []const contract.EnforcedStorageFamily,
    available_bytes: u64,
    actual_successful_functions: u16,
) contract.CompleteEnforcementEvidence {
    return .{
        .prerequisites = &contract.required_enforcement_prerequisites,
        .storage_families = families,
        .available_bytes = available_bytes,
        .identity_count = contract.closed_identities.len,
        .compatibility_key_count = contract.compatibility_keys.len,
        .v3_path_count = @typeInfo(contract.V3Path).@"enum".field_names.len,
        .repetition_count = contract.canonical_repetition_count,
        .actual_successful_functions = actual_successful_functions,
        .phase_count = @typeInfo(contract.Phase).@"enum".field_names.len,
        .stdout_capture_bytes = process.capture_max,
        .stderr_capture_bytes = process.capture_max,
    };
}

pub fn encode(allocator: std.mem.Allocator, validated: ValidatedRun, binding: Binding) ![]u8 {
    const families = try contract.acceptedEnforcedStorageFamilies();
    const evidence = completeEnforcementEvidence(&families, validated.available_bytes, validated.raw_report.actual_successful_functions);
    try contract.validateCompleteEnforcementEvidence(evidence);
    try requireRestorationEqual(validated.before, validated.after);
    try validateToolBindings(binding.tools);
    if (!binding.completion or !std.meta.eql(binding.raw_report, validated.raw_report) or
        binding.registered_worktrees.count != inputs.accepted_registered_worktree_count or
        binding.canonical_artifact.bytes == 0 or binding.coverage_artifact.bytes == 0)
        return error.ClosurePrecondition;

    var output: std.Io.Writer.Allocating = .init(allocator);
    errdefer output.deinit();
    try output.writer.print(
        "schema\t{s}\nreadiness\tready\nretained_bytes\t{d}\navailable_bytes\t{d}\nmaximum_bytes\t{d}\nreserve_bytes\t{d}\nidentities\t{d}\ncompatibility_keys\t{d}\nrepetitions\t{d}\nactual_successful_functions\t{d}\nselected_functions\t{d}\nfailed_functions\t{d}\nphases\t{d}\n",
        .{ schema, validated.retained_bytes, validated.available_bytes, contract.accepted_maximum_storage_bytes, contract.accepted_storage_reserve_bytes, evidence.identity_count, evidence.compatibility_key_count, evidence.repetition_count, evidence.actual_successful_functions, validated.raw_report.selected_functions, validated.raw_report.failed_functions, evidence.phase_count },
    );
    for (orderedTools(binding.tools)) |tool| {
        const portable = tool.portable_tool orelse return error.SubjectAuthorityMismatch;
        const digest_hex = std.fmt.bytesToHex(portable.sha256, .lower);
        try output.writer.print("tool\t{s}\t{d}\t{s}\t{s}\n", .{
            inputs.toolRoleName(portable.role), portable.bytes, &digest_hex, portable.version orelse "-",
        });
    }
    const source_hex = std.fmt.bytesToHex(binding.fixed_sources, .lower);
    const input_hex = std.fmt.bytesToHex(binding.fixed_inputs, .lower);
    const canonical_artifact_hex = std.fmt.bytesToHex(binding.canonical_artifact.sha256, .lower);
    const coverage_artifact_hex = std.fmt.bytesToHex(binding.coverage_artifact.sha256, .lower);
    const canonical_observations_hex = std.fmt.bytesToHex(binding.canonical_observations, .lower);
    const coverage_off_hex = std.fmt.bytesToHex(binding.coverage_off_observation, .lower);
    const coverage_on_hex = std.fmt.bytesToHex(binding.coverage_on_observation, .lower);
    const counter_hex = std.fmt.bytesToHex(binding.counter_result, .lower);
    const failure_order_hex = std.fmt.bytesToHex(binding.raw_report.failure_order_sha256, .lower);
    const successful_manifest_hex = std.fmt.bytesToHex(binding.raw_report.successful_manifest_sha256, .lower);
    const worktree_hex = std.fmt.bytesToHex(binding.registered_worktrees.sha256, .lower);
    const family_usage_hex = std.fmt.bytesToHex(binding.family_usage, .lower);
    const repository_before_hex = std.fmt.bytesToHex(validated.before.repository, .lower);
    const canonical_before_hex = std.fmt.bytesToHex(validated.before.canonical_source, .lower);
    const coverage_before_hex = std.fmt.bytesToHex(validated.before.coverage_source, .lower);
    const accepted_before_hex = std.fmt.bytesToHex(validated.before.accepted_input, .lower);
    const repository_after_hex = std.fmt.bytesToHex(validated.after.repository, .lower);
    const canonical_after_hex = std.fmt.bytesToHex(validated.after.canonical_source, .lower);
    const coverage_after_hex = std.fmt.bytesToHex(validated.after.coverage_source, .lower);
    const accepted_after_hex = std.fmt.bytesToHex(validated.after.accepted_input, .lower);
    try output.writer.print(
        "fixed_sources_sha256\t{s}\nfixed_inputs_sha256\t{s}\n" ++
            "canonical_artifact\t{d}\t{o}\t{s}\ncoverage_artifact\t{d}\t{o}\t{s}\n" ++
            "canonical_observations_sha256\t{s}\ncoverage_off_observation_sha256\t{s}\n" ++
            "coverage_on_observation_sha256\t{s}\ncounter_result_sha256\t{s}\n" ++
            "failure_order_sha256\t{s}\nsuccessful_manifest_sha256\t{s}\n" ++
            "registered_worktrees\t{d}\t{s}\nfamily_usage_sha256\t{s}\n" ++
            "restoration_before\t{s}\t{s}\t{s}\t{s}\n" ++
            "restoration_after\t{s}\t{s}\t{s}\t{s}\ncompletion\tcomplete\n",
        .{ &source_hex, &input_hex, binding.canonical_artifact.bytes, binding.canonical_artifact.mode, &canonical_artifact_hex, binding.coverage_artifact.bytes, binding.coverage_artifact.mode, &coverage_artifact_hex, &canonical_observations_hex, &coverage_off_hex, &coverage_on_hex, &counter_hex, &failure_order_hex, &successful_manifest_hex, binding.registered_worktrees.count, &worktree_hex, &family_usage_hex, &repository_before_hex, &canonical_before_hex, &coverage_before_hex, &accepted_before_hex, &repository_after_hex, &canonical_after_hex, &coverage_after_hex, &accepted_after_hex },
    );
    if (output.writer.end > maximum_bytes) {
        output.deinit();
        return error.ClosureTooLarge;
    }
    return output.toOwnedSlice();
}

pub fn verifyReadBack(expected: []const u8, actual: []const u8) !void {
    if (!std.mem.eql(u8, expected, actual)) return error.ClosureReadBackMismatch;
}

pub fn syncOwnedDirectory(directory: std.Io.Dir, io: std.Io) !void {
    const owned = try directory.openFile(io, ".", .{
        .mode = .read_only,
        .allow_directory = true,
        .path_only = false,
        .follow_symlinks = false,
        .resolve_beneath = true,
    });
    defer owned.close(io);
    try owned.sync(io);
}

pub fn publish(allocator: std.mem.Allocator, directory: std.Io.Dir, io: std.Io, encoded: []const u8) !Published {
    if (encoded.len == 0 or encoded.len > maximum_bytes) return error.ClosureTooLarge;
    var temporary = directory.createFile(io, temporary_name, .{
        .read = false,
        .truncate = false,
        .exclusive = true,
        .resolve_beneath = true,
    }) catch |failure| switch (failure) {
        error.PathAlreadyExists => return error.ClosureCollision,
        else => return failure,
    };
    var temporary_open = true;
    var temporary_exists = true;
    var final_published = false;
    defer if (temporary_open) temporary.close(io);
    errdefer {
        if (temporary_exists) directory.deleteFile(io, temporary_name) catch {} else if (final_published) {
            directory.deleteFile(io, name) catch {};
            syncOwnedDirectory(directory, io) catch {};
        }
    }
    try temporary.writeStreamingAll(io, encoded);
    try temporary.sync(io);
    temporary.close(io);
    temporary_open = false;
    directory.renamePreserve(temporary_name, directory, name, io) catch |failure| switch (failure) {
        error.PathAlreadyExists => return error.ClosureCollision,
        else => return failure,
    };
    temporary_exists = false;
    final_published = true;
    try syncOwnedDirectory(directory, io);
    const final = try directory.openFile(io, name, .{
        .mode = .read_only,
        .follow_symlinks = false,
        .resolve_beneath = true,
    });
    defer final.close(io);
    const read_back = try allocator.alloc(u8, encoded.len);
    defer allocator.free(read_back);
    if (try final.readPositionalAll(io, read_back, 0) != encoded.len) return error.ClosureReadBackMismatch;
    var trailing: [1]u8 = undefined;
    if (try final.readPositionalAll(io, &trailing, encoded.len) != 0) return error.ClosureReadBackMismatch;
    try verifyReadBack(encoded, read_back);
    return .{ .bytes = @intCast(encoded.len), .sha256 = sha256(encoded) };
}

fn sha256(bytes: []const u8) contract.Digest {
    var digest: contract.Digest = undefined;
    std.crypto.hash.sha2.Sha256.hash(bytes, &digest, .{});
    return digest;
}

test "closure readback and publication are exact and no-overwrite" {
    try verifyReadBack("exact\n", "exact\n");
    try std.testing.expectError(error.ClosureReadBackMismatch, verifyReadBack("one", "two"));
    var temporary = std.testing.tmpDir(.{});
    defer temporary.cleanup();
    const published = try publish(std.testing.allocator, temporary.dir, std.testing.io, "exact\n");
    try std.testing.expectEqual(@as(u64, 6), published.bytes);
    try std.testing.expectError(error.ClosureCollision, publish(std.testing.allocator, temporary.dir, std.testing.io, "again\n"));
}
