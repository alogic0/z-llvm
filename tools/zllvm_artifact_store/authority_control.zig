const std = @import("std");
const builtin = @import("builtin");
const digest_model = @import("digest.zig");
const filesystem = @import("filesystem.zig");
const identity_model = @import("identity.zig");
const manifest_model = @import("manifest.zig");
const path_policy = @import("path_policy.zig");
const process_result = @import("process_result.zig");
const registration = @import("registration.zig");

const sha256Hex = digest_model.sha256Hex;
const openExistingDir = filesystem.openExistingDir;
const openPathNoFollow = filesystem.openPathNoFollow;
const identityOfOpenFileAnyMode = identity_model.identityOfOpenFileAnyMode;
const verifyRelativeFile = identity_model.verifyRelativeFile;
const FileIdentity = identity_model.FileIdentity;
const Manifest = manifest_model.Manifest;
const parseManifest = manifest_model.parseManifest;
const encodeManifest = manifest_model.encodeManifest;
const validateCanonicalField = manifest_model.validateCanonicalField;
const validateRelativeKey = manifest_model.validateRelativeKey;
const validateSha = manifest_model.validateSha;
const splitObjectKey = manifest_model.splitObjectKey;
const splitSnapshotKey = manifest_model.splitSnapshotKey;
const pathContains = path_policy.pathContains;
const normalizedAbsolute = path_policy.normalizedAbsolute;
const termSuccess = process_result.termSuccess;
const freeRunResult = process_result.freeRunResult;
const RegistrationGuard = registration.RegistrationGuard;
const main_repository = registration.main_repository;

const dormant_test_root = "/tmp/zllvm-inbox205b-authority-dormant-synthetic";
const dormant_candidate_key = "authority/zllvm/v1/manifests/candidate.tsv";
const dormant_generation_key = "authority/zllvm/v1/manifests/generation-00000001.tsv";
const dormant_lineage_key = "authority/zllvm/v1/lineage/generation-00000001.tsv";
const dormant_receipt_key =
    "authority/zllvm/v1/receipts/publication/generation-00000001-payload-copy.tsv";
const dormant_candidate_magic = "zllvm-authority-candidate-v1";
const dormant_candidate_header =
    "authority_id\tgeneration\tpayload_root\tgeneration_manifest_key\tgeneration_manifest_sha256\tgeneration_manifest_bytes\tgeneration_manifest_mode\tlineage_key\tlineage_sha256\tpayload_copy_receipt_key\tpayload_copy_receipt_sha256\tsource_authority_root\tsource_generation_manifest_sha256\tstate";
const dormant_lineage_magic = "zllvm-artifact-lineage-v1";
const dormant_lineage_header =
    "generation\tparent_generation\tparent_manifest_sha256\tgeneration_manifest_sha256\tsource_authority_root\tsource_generation_manifest_sha256\ttransition";
const dormant_receipt_magic = "zllvm-payload-copy-receipt-v1";
const dormant_receipt_header =
    "receipt_id\tgeneration\tsource_root\tdestination_root\tsource_inventory_sha256\tsource_file_ledger_sha256\tsource_destination_ledger_sha256\tpayload_files\tpayload_bytes\tobjects\tsnapshots\tdestination_modes\tcopy_evidence_path\tcopy_evidence_sha256\tresult";
const dormant_real_control_root = "/home/oleg/prog/z_llvm/local-state/control";
const dormant_real_authority_root =
    "/home/oleg/prog/z_llvm/local-state/control/authority/zllvm/v1";
const dormant_real_payload_root =
    "/home/oleg/prog/z_llvm/local-state/artifacts/zllvm-authority-v1";
const dormant_real_source_root = "/home/oleg/prog/z_llvm-artifacts";
const dormant_git_executable = "/usr/bin/git";
const dormant_git_bytes = 4_066_232;
const dormant_git_sha256 = "2a8c18fbf43da9f692d75474c72bea9dfd796c260b0f3dfe456376abc3bbd668";
const dormant_control_commit = "9c55bda34088e1230b0b91a126d35795a3ac70b4";
const dormant_control_tree = "756369ad4a89d806f463bd8094c5159d8c973d7e";
const dormant_exact_real_copy_evidence_path =
    "docs/evidence/inbox202_local_state_artifact_copy_verify.md";
const dormant_exact_real_copy_evidence_sha256 =
    "4b532daabe33e7c6eaca7f0ab412d9c271b55b6b1de8235dd3d4f65d7ab6f7a6";
const dormant_exact_real_copy_evidence_max_bytes = 1024 * 1024;

const ControlGitEntrySpec = struct {
    mode: []const u8,
    kind: []const u8,
    object_id: []const u8,
    path: []const u8,
};

const dormant_real_control_entries = [_]ControlGitEntrySpec{
    .{
        .mode = "100644",
        .kind = "blob",
        .object_id = "1652b3dae95b0cd7e26efbdd3e989588f7abcbd4",
        .path = dormant_lineage_key,
    },
    .{
        .mode = "100644",
        .kind = "blob",
        .object_id = "ad3dfaf211a583481eea31b78fce77a901dcce34",
        .path = dormant_candidate_key,
    },
    .{
        .mode = "100644",
        .kind = "blob",
        .object_id = "aa4637a2747d09afd450c925cc38bf01843e6cb3",
        .path = dormant_generation_key,
    },
    .{
        .mode = "100644",
        .kind = "blob",
        .object_id = "e0a872bd03847c63e0ece6d3f17a74042a7049bc",
        .path = dormant_receipt_key,
    },
};

const dormant_synthetic_control_entries = [_]ControlGitEntrySpec{
    .{
        .mode = "100644",
        .kind = "blob",
        .object_id = "1111111111111111111111111111111111111111",
        .path = dormant_lineage_key,
    },
    .{
        .mode = "100644",
        .kind = "blob",
        .object_id = "2222222222222222222222222222222222222222",
        .path = dormant_candidate_key,
    },
    .{
        .mode = "100644",
        .kind = "blob",
        .object_id = "3333333333333333333333333333333333333333",
        .path = dormant_generation_key,
    },
    .{
        .mode = "100644",
        .kind = "blob",
        .object_id = "4444444444444444444444444444444444444444",
        .path = dormant_receipt_key,
    },
};

const DormantControlFileExpectationSpec = struct {
    component: DormantComponent,
    path: []const u8,
    sha256: []const u8,
    bytes: u64,
    mode: u16,
};

const dormant_real_control_file_expectations = [_]DormantControlFileExpectationSpec{
    .{
        .component = .candidate,
        .path = dormant_candidate_key,
        .sha256 = "7c0aa46fb6c0cb2b93034bbb6b520b6d4831fedea333983002622197a74c832b",
        .bytes = 899,
        .mode = 0o644,
    },
    .{
        .component = .generation,
        .path = dormant_generation_key,
        .sha256 = "61b7426bd52a3a139999f17f36d91ecaab954e6132fe36eca541480cdf31104d",
        .bytes = 27_823,
        .mode = 0o644,
    },
    .{
        .component = .lineage,
        .path = dormant_lineage_key,
        .sha256 = "f8b22b687f3d3cb727ba82e92c3a346c7025958387f3a45d4143fb42936c6a3a",
        .bytes = 378,
        .mode = 0o644,
    },
    .{
        .component = .receipt,
        .path = dormant_receipt_key,
        .sha256 = "9c6748234292c963c9716504a1451c4da0cdb0fe2ce1642d1c5fa83264aa19a3",
        .bytes = 792,
        .mode = 0o644,
    },
};

const DormantComponent = enum {
    candidate,
    generation,
    lineage,
    receipt,

    fn missing(component: DormantComponent) anyerror {
        return switch (component) {
            .candidate => error.DormantCandidateMissing,
            .generation => error.DormantGenerationMissing,
            .lineage => error.DormantLineageMissing,
            .receipt => error.DormantReceiptMissing,
        };
    }

    fn malformed(component: DormantComponent) anyerror {
        return switch (component) {
            .candidate => error.DormantCandidateMalformed,
            .generation => error.DormantGenerationMalformed,
            .lineage => error.DormantLineageMalformed,
            .receipt => error.DormantReceiptMalformed,
        };
    }

    fn mismatched(component: DormantComponent) anyerror {
        return switch (component) {
            .candidate => error.DormantCandidateMismatched,
            .generation => error.DormantGenerationMismatched,
            .lineage => error.DormantLineageMismatched,
            .receipt => error.DormantReceiptMismatched,
        };
    }

    fn unsafe(component: DormantComponent) anyerror {
        return switch (component) {
            .candidate => error.DormantCandidateUnsafe,
            .generation => error.DormantGenerationUnsafe,
            .lineage => error.DormantLineageUnsafe,
            .receipt => error.DormantReceiptUnsafe,
        };
    }
};

const DormantOwnedRow = struct {
    storage: []u8,
    fields: [][]const u8,

    fn deinit(row: *DormantOwnedRow, allocator: std.mem.Allocator) void {
        allocator.free(row.fields);
        allocator.free(row.storage);
        row.* = undefined;
    }
};

const ControlGitEntry = struct {
    mode: [6]u8,
    kind: [4]u8,
    object_id: [40]u8,
    path: []u8,

    fn deinit(entry: *ControlGitEntry, allocator: std.mem.Allocator) void {
        allocator.free(entry.path);
        entry.* = undefined;
    }
};

const ControlGitObservation = struct {
    allocator: std.mem.Allocator,
    commit: [40]u8,
    tree: [40]u8,
    branch: []u8,
    status: []u8,
    remotes: []u8,
    entries: []ControlGitEntry,

    fn initOwned(
        allocator: std.mem.Allocator,
        commit: []const u8,
        tree: []const u8,
        branch: []const u8,
        status: []const u8,
        remotes: []const u8,
        specs: []const ControlGitEntrySpec,
    ) !ControlGitObservation {
        const owned_branch = try allocator.dupe(u8, branch);
        errdefer allocator.free(owned_branch);
        const owned_status = try allocator.dupe(u8, status);
        errdefer allocator.free(owned_status);
        const owned_remotes = try allocator.dupe(u8, remotes);
        errdefer allocator.free(owned_remotes);
        const entries = try allocator.alloc(ControlGitEntry, specs.len);
        errdefer allocator.free(entries);
        var initialized: usize = 0;
        errdefer for (entries[0..initialized]) |*entry| entry.deinit(allocator);
        for (specs, entries) |spec, *entry| {
            if (!std.mem.eql(u8, spec.mode, "100644") or
                !std.mem.eql(u8, spec.kind, "blob") or
                spec.object_id.len != 40)
            {
                return error.DormantControlGitMalformed;
            }
            for (spec.object_id) |byte| {
                if (!std.ascii.isDigit(byte) and (byte < 'a' or byte > 'f')) {
                    return error.DormantControlGitMalformed;
                }
            }
            validateRelativeKey(spec.path) catch return error.DormantControlGitMalformed;
            entry.* = .{
                .mode = spec.mode[0..6].*,
                .kind = spec.kind[0..4].*,
                .object_id = spec.object_id[0..40].*,
                .path = try allocator.dupe(u8, spec.path),
            };
            initialized += 1;
        }
        return .{
            .allocator = allocator,
            .commit = try controlGitObjectId(commit),
            .tree = try controlGitObjectId(tree),
            .branch = owned_branch,
            .status = owned_status,
            .remotes = owned_remotes,
            .entries = entries,
        };
    }

    fn initRealExpected(allocator: std.mem.Allocator) !ControlGitObservation {
        return initOwned(
            allocator,
            dormant_control_commit,
            dormant_control_tree,
            "main",
            "",
            "",
            &dormant_real_control_entries,
        );
    }

    pub fn initSyntheticExpected(allocator: std.mem.Allocator) !ControlGitObservation {
        if (!builtin.is_test) return error.TestOnlyOperation;
        return initOwned(
            allocator,
            "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
            "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
            "main",
            "",
            "",
            &dormant_synthetic_control_entries,
        );
    }

    pub fn deinit(observation: *ControlGitObservation) void {
        for (observation.entries) |*entry| entry.deinit(observation.allocator);
        observation.allocator.free(observation.entries);
        observation.allocator.free(observation.remotes);
        observation.allocator.free(observation.status);
        observation.allocator.free(observation.branch);
        observation.* = undefined;
    }
};

const DormantRolePolicyKind = enum {
    exact_real,
    synthetic_test,
};

const DormantControlFileExpectation = struct {
    component: DormantComponent,
    path: []u8,
    sha256: [64]u8,
    bytes: u64,
    mode: u16,

    fn deinit(expectation: *DormantControlFileExpectation, allocator: std.mem.Allocator) void {
        allocator.free(expectation.path);
        expectation.* = undefined;
    }
};

const DormantRootPolicy = struct {
    allocator: std.mem.Allocator,
    kind: DormantRolePolicyKind,
    main_root: []u8,
    control_root: []u8,
    authority_root: []u8,
    payload_root: []u8,
    source_root: []u8,
    supplemental_control_root: []u8,
    non_main_roots: [][]u8,
    control_files: []DormantControlFileExpectation,
    observed_control: ControlGitObservation,
    expected_control: ControlGitObservation,

    fn initOwned(
        allocator: std.mem.Allocator,
        kind: DormantRolePolicyKind,
        main_root: []const u8,
        control_root: []const u8,
        authority_root: []const u8,
        payload_root: []const u8,
        source_root: []const u8,
        supplemental_control_root: []const u8,
        non_main_roots: []const []const u8,
        control_file_specs: []const DormantControlFileExpectationSpec,
        observed_control: *ControlGitObservation,
        expected_control: *ControlGitObservation,
    ) !DormantRootPolicy {
        const owned_main = try allocator.dupe(u8, main_root);
        errdefer allocator.free(owned_main);
        const owned_control = try allocator.dupe(u8, control_root);
        errdefer allocator.free(owned_control);
        const owned_authority = try allocator.dupe(u8, authority_root);
        errdefer allocator.free(owned_authority);
        const owned_payload = try allocator.dupe(u8, payload_root);
        errdefer allocator.free(owned_payload);
        const owned_source = try allocator.dupe(u8, source_root);
        errdefer allocator.free(owned_source);
        const owned_supplemental = try allocator.dupe(u8, supplemental_control_root);
        errdefer allocator.free(owned_supplemental);
        const owned_non_main = try allocator.alloc([]u8, non_main_roots.len);
        errdefer allocator.free(owned_non_main);
        var initialized: usize = 0;
        errdefer for (owned_non_main[0..initialized]) |path| allocator.free(path);
        for (non_main_roots, owned_non_main) |path, *owned| {
            owned.* = try allocator.dupe(u8, path);
            initialized += 1;
        }
        const owned_control_files = try allocator.alloc(
            DormantControlFileExpectation,
            control_file_specs.len,
        );
        errdefer allocator.free(owned_control_files);
        var initialized_control_files: usize = 0;
        var seen_control_components = [_]bool{false} ** 4;
        errdefer for (owned_control_files[0..initialized_control_files]) |*expectation| {
            expectation.deinit(allocator);
        };
        for (control_file_specs, owned_control_files) |spec, *expectation| {
            const component_index = @intFromEnum(spec.component);
            if (!dormantControlKeyMatches(spec.component, spec.path) or
                seen_control_components[component_index] or
                spec.mode != 0o644 or
                spec.bytes > 4 * 1024 * 1024)
            {
                return error.DormantControlGitMalformed;
            }
            try validateSha(spec.sha256);
            expectation.* = .{
                .component = spec.component,
                .path = try allocator.dupe(u8, spec.path),
                .sha256 = spec.sha256[0..64].*,
                .bytes = spec.bytes,
                .mode = spec.mode,
            };
            seen_control_components[component_index] = true;
            initialized_control_files += 1;
        }
        if (owned_control_files.len != 4) return error.DormantControlGitMalformed;
        const policy: DormantRootPolicy = .{
            .allocator = allocator,
            .kind = kind,
            .main_root = owned_main,
            .control_root = owned_control,
            .authority_root = owned_authority,
            .payload_root = owned_payload,
            .source_root = owned_source,
            .supplemental_control_root = owned_supplemental,
            .non_main_roots = owned_non_main,
            .control_files = owned_control_files,
            .observed_control = observed_control.*,
            .expected_control = expected_control.*,
        };
        observed_control.* = undefined;
        expected_control.* = undefined;
        return policy;
    }

    fn deinit(policy: *DormantRootPolicy) void {
        policy.expected_control.deinit();
        policy.observed_control.deinit();
        for (policy.control_files) |*expectation| expectation.deinit(policy.allocator);
        policy.allocator.free(policy.control_files);
        for (policy.non_main_roots) |path| policy.allocator.free(path);
        policy.allocator.free(policy.non_main_roots);
        policy.allocator.free(policy.supplemental_control_root);
        policy.allocator.free(policy.source_root);
        policy.allocator.free(policy.payload_root);
        policy.allocator.free(policy.authority_root);
        policy.allocator.free(policy.control_root);
        policy.allocator.free(policy.main_root);
        policy.* = undefined;
    }
};

fn controlGitObjectId(value: []const u8) ![40]u8 {
    if (value.len != 40) return error.DormantControlGitMalformed;
    for (value) |byte| {
        if (!std.ascii.isDigit(byte) and (byte < 'a' or byte > 'f')) {
            return error.DormantControlGitMalformed;
        }
    }
    return value[0..40].*;
}

fn controlGitSingleLine(output: []const u8) ![]const u8 {
    if (output.len < 2 or output[output.len - 1] != '\n' or
        std.mem.indexOfScalar(u8, output, '\r') != null or
        std.mem.indexOfScalar(u8, output[0 .. output.len - 1], '\n') != null)
    {
        return error.DormantControlGitMalformed;
    }
    return output[0 .. output.len - 1];
}

fn parseControlGitTreeSpecs(
    allocator: std.mem.Allocator,
    output: []const u8,
) ![]ControlGitEntrySpec {
    if (output.len == 0 or output[output.len - 1] != 0) {
        return error.DormantControlGitMalformed;
    }
    var specs: std.ArrayList(ControlGitEntrySpec) = .empty;
    errdefer specs.deinit(allocator);
    var records = std.mem.splitScalar(u8, output, 0);
    while (records.next()) |record| {
        if (record.len == 0) {
            if (records.next() != null) return error.DormantControlGitMalformed;
            break;
        }
        if (specs.items.len == 16) return error.DormantControlGitMalformed;
        const first_space = std.mem.indexOfScalar(u8, record, ' ') orelse
            return error.DormantControlGitMalformed;
        const second_space_offset = std.mem.indexOfScalar(
            u8,
            record[first_space + 1 ..],
            ' ',
        ) orelse return error.DormantControlGitMalformed;
        const second_space = first_space + 1 + second_space_offset;
        const tab = std.mem.indexOfScalar(u8, record, '\t') orelse
            return error.DormantControlGitMalformed;
        if (second_space + 1 >= tab or
            std.mem.indexOfScalar(u8, record[tab + 1 ..], '\t') != null)
        {
            return error.DormantControlGitMalformed;
        }
        try specs.append(allocator, .{
            .mode = record[0..first_space],
            .kind = record[first_space + 1 .. second_space],
            .object_id = record[second_space + 1 .. tab],
            .path = record[tab + 1 ..],
        });
    }
    return specs.toOwnedSlice(allocator);
}

fn cleanControlGitEnvironment(
    allocator: std.mem.Allocator,
) !std.process.Environ.Map {
    var environment = std.process.Environ.Map.init(allocator);
    errdefer environment.deinit();
    try environment.put("PATH", "/usr/bin:/bin");
    try environment.put("LC_ALL", "C");
    try environment.put("HOME", "/nonexistent");
    try environment.put("XDG_CONFIG_HOME", "/nonexistent");
    try environment.put("GIT_CONFIG_NOSYSTEM", "1");
    try environment.put("GIT_CONFIG_GLOBAL", "/dev/null");
    try environment.put("GIT_CONFIG_SYSTEM", "/dev/null");
    try environment.put("GIT_OPTIONAL_LOCKS", "0");
    try environment.put("GIT_TERMINAL_PROMPT", "0");
    try environment.put("GIT_PAGER", "cat");
    try environment.put("PAGER", "cat");
    return environment;
}

fn runControlGit(
    allocator: std.mem.Allocator,
    io: std.Io,
    args: []const []const u8,
) ![]u8 {
    var environment = try cleanControlGitEnvironment(allocator);
    defer environment.deinit();
    const result = try std.process.run(allocator, io, .{
        .argv = args,
        .environ_map = &environment,
        .stdout_limit = .limited(64 * 1024),
        .stderr_limit = .limited(64 * 1024),
    });
    if (!termSuccess(result.term) or result.stderr.len != 0) {
        freeRunResult(allocator, result);
        return error.DormantControlGitFailed;
    }
    allocator.free(result.stderr);
    return result.stdout;
}

fn acquireControlGitObservation(
    allocator: std.mem.Allocator,
    io: std.Io,
) !ControlGitObservation {
    var executable = try std.Io.Dir.openFileAbsolute(io, dormant_git_executable, .{
        .allow_directory = false,
        .follow_symlinks = false,
    });
    defer executable.close(io);
    var executable_identity = try identityOfOpenFileAnyMode(allocator, io, executable);
    defer executable_identity.deinit(allocator);
    if (executable_identity.mode != 0o755 or
        executable_identity.bytes != dormant_git_bytes or
        !std.mem.eql(u8, &executable_identity.sha256, dormant_git_sha256))
    {
        return error.DormantControlGitIdentityMismatch;
    }

    const commit_output = try runControlGit(allocator, io, &.{
        dormant_git_executable,
        "-C",
        dormant_real_control_root,
        "rev-parse",
        "--verify",
        "HEAD",
    });
    defer allocator.free(commit_output);
    const tree_output = try runControlGit(allocator, io, &.{
        dormant_git_executable,
        "-C",
        dormant_real_control_root,
        "rev-parse",
        "HEAD^{tree}",
    });
    defer allocator.free(tree_output);
    const branch_output = try runControlGit(allocator, io, &.{
        dormant_git_executable,
        "-C",
        dormant_real_control_root,
        "symbolic-ref",
        "--quiet",
        "--short",
        "HEAD",
    });
    defer allocator.free(branch_output);
    const status_output = try runControlGit(allocator, io, &.{
        dormant_git_executable,
        "-C",
        dormant_real_control_root,
        "status",
        "--porcelain=v1",
        "--untracked-files=all",
    });
    defer allocator.free(status_output);
    const remotes_output = try runControlGit(allocator, io, &.{
        dormant_git_executable,
        "-C",
        dormant_real_control_root,
        "remote",
    });
    defer allocator.free(remotes_output);
    const entries_output = try runControlGit(allocator, io, &.{
        dormant_git_executable,
        "-C",
        dormant_real_control_root,
        "ls-tree",
        "-r",
        "-z",
        "--full-tree",
        "HEAD",
        "--",
        "authority/zllvm/v1",
    });
    defer allocator.free(entries_output);
    const entry_specs = try parseControlGitTreeSpecs(allocator, entries_output);
    defer allocator.free(entry_specs);
    return ControlGitObservation.initOwned(
        allocator,
        try controlGitSingleLine(commit_output),
        try controlGitSingleLine(tree_output),
        try controlGitSingleLine(branch_output),
        status_output,
        remotes_output,
        entry_specs,
    );
}

fn validateControlGitObservation(
    observed: ControlGitObservation,
    expected: ControlGitObservation,
) !void {
    if (!std.mem.eql(u8, &observed.commit, &expected.commit) or
        !std.mem.eql(u8, &observed.tree, &expected.tree) or
        !std.mem.eql(u8, observed.branch, expected.branch) or
        !std.mem.eql(u8, observed.status, expected.status) or
        !std.mem.eql(u8, observed.remotes, expected.remotes) or
        observed.entries.len != expected.entries.len)
    {
        return error.DormantUnsafeRoot;
    }
    for (observed.entries, expected.entries) |actual, wanted| {
        if (!std.mem.eql(u8, &actual.mode, &wanted.mode) or
            !std.mem.eql(u8, &actual.kind, &wanted.kind) or
            !std.mem.eql(u8, &actual.object_id, &wanted.object_id) or
            !std.mem.eql(u8, actual.path, wanted.path))
        {
            return error.DormantUnsafeRoot;
        }
    }
}

fn pathsIntersect(a: []const u8, b: []const u8) bool {
    return pathContains(a, b) or pathContains(b, a);
}

const DormantAuthorityConfig = struct {
    allocator: std.mem.Allocator,
    io: std.Io,
    guard: RegistrationGuard,
    root_policy: DormantRootPolicy,
    control_root: []u8,
    authority_root: []u8,
    payload_root: []u8,
    source_root: []u8,
    source_manifest_sha256: [64]u8,
    expected_source_inventory_sha256: [64]u8,
    expected_source_file_ledger_sha256: [64]u8,
    expected_source_destination_ledger_sha256: [64]u8,
    expected_copy_evidence_path: []u8,
    expected_copy_evidence_sha256: [64]u8,
    expected_registration_full_hash: [64]u8,
    expected_registration_path_hash: [64]u8,
    expected_registration_topology_hash: [64]u8,
    expected_registration_non_main_hash: [64]u8,

    pub fn initExactRealCandidate(
        allocator: std.mem.Allocator,
        io: std.Io,
        source_manifest_sha256: []const u8,
        source_inventory_sha256: []const u8,
        source_file_ledger_sha256: []const u8,
        source_destination_ledger_sha256: []const u8,
        copy_evidence_path: []const u8,
        copy_evidence_sha256: []const u8,
    ) !DormantAuthorityConfig {
        var guard = try RegistrationGuard.init(allocator, io);
        errdefer guard.deinit();
        if (!std.mem.eql(u8, guard.frozen.paths[0], main_repository)) {
            return error.DormantRegistrationStale;
        }
        var observed = try acquireControlGitObservation(allocator, io);
        var observed_transferred = false;
        errdefer if (!observed_transferred) observed.deinit();
        var expected = try ControlGitObservation.initRealExpected(allocator);
        var expected_transferred = false;
        errdefer if (!expected_transferred) expected.deinit();
        var policy = try DormantRootPolicy.initOwned(
            allocator,
            .exact_real,
            main_repository,
            dormant_real_control_root,
            dormant_real_authority_root,
            dormant_real_payload_root,
            dormant_real_source_root,
            dormant_real_control_root,
            guard.frozen.paths[1..],
            &dormant_real_control_file_expectations,
            &observed,
            &expected,
        );
        observed_transferred = true;
        expected_transferred = true;
        errdefer policy.deinit();
        return initOwned(
            allocator,
            io,
            &guard,
            &policy,
            source_manifest_sha256,
            source_inventory_sha256,
            source_file_ledger_sha256,
            source_destination_ledger_sha256,
            copy_evidence_path,
            copy_evidence_sha256,
        );
    }

    pub fn initSynthetic(
        allocator: std.mem.Allocator,
        io: std.Io,
        main_root: []const u8,
        control_root: []const u8,
        payload_root: []const u8,
        source_root: []const u8,
        supplemental_control_root: []const u8,
        non_main_roots: []const []const u8,
        observed_control: *ControlGitObservation,
        control_file_specs: []const DormantControlFileExpectationSpec,
        source_manifest_sha256: []const u8,
        source_inventory_sha256: []const u8,
        source_file_ledger_sha256: []const u8,
        source_destination_ledger_sha256: []const u8,
        copy_evidence_path: []const u8,
        copy_evidence_sha256: []const u8,
    ) !DormantAuthorityConfig {
        if (!builtin.is_test) return error.TestOnlyOperation;
        const roots = [_][]const u8{ main_root, control_root, payload_root, source_root };
        for (roots) |root| {
            if (!pathContains(dormant_test_root, root) or
                pathsIntersect(root, dormant_real_control_root) or
                pathsIntersect(root, dormant_real_payload_root) or
                pathsIntersect(root, dormant_real_source_root))
            {
                return error.DormantUnsafeRoot;
            }
        }
        const authority_root = try std.fs.path.join(
            allocator,
            &.{ control_root, "authority", "zllvm", "v1" },
        );
        defer allocator.free(authority_root);
        var guard = try RegistrationGuard.init(allocator, io);
        errdefer guard.deinit();
        var expected = try ControlGitObservation.initSyntheticExpected(allocator);
        var expected_transferred = false;
        errdefer if (!expected_transferred) expected.deinit();
        var policy = try DormantRootPolicy.initOwned(
            allocator,
            .synthetic_test,
            main_root,
            control_root,
            authority_root,
            payload_root,
            source_root,
            supplemental_control_root,
            non_main_roots,
            control_file_specs,
            observed_control,
            &expected,
        );
        expected_transferred = true;
        errdefer policy.deinit();
        return initOwned(
            allocator,
            io,
            &guard,
            &policy,
            source_manifest_sha256,
            source_inventory_sha256,
            source_file_ledger_sha256,
            source_destination_ledger_sha256,
            copy_evidence_path,
            copy_evidence_sha256,
        );
    }

    fn initOwned(
        allocator: std.mem.Allocator,
        io: std.Io,
        guard: *RegistrationGuard,
        root_policy: *DormantRootPolicy,
        source_manifest_sha256: []const u8,
        source_inventory_sha256: []const u8,
        source_file_ledger_sha256: []const u8,
        source_destination_ledger_sha256: []const u8,
        copy_evidence_path: []const u8,
        copy_evidence_sha256: []const u8,
    ) !DormantAuthorityConfig {
        try validateSha(source_manifest_sha256);
        try validateSha(source_inventory_sha256);
        try validateSha(source_file_ledger_sha256);
        try validateSha(source_destination_ledger_sha256);
        try validateRelativeKey(copy_evidence_path);
        try validateSha(copy_evidence_sha256);
        const owned_control = try allocator.dupe(u8, root_policy.control_root);
        errdefer allocator.free(owned_control);
        const owned_authority = try allocator.dupe(u8, root_policy.authority_root);
        errdefer allocator.free(owned_authority);
        const owned_payload = try allocator.dupe(u8, root_policy.payload_root);
        errdefer allocator.free(owned_payload);
        const owned_source = try allocator.dupe(u8, root_policy.source_root);
        errdefer allocator.free(owned_source);
        const owned_copy_evidence_path = try allocator.dupe(u8, copy_evidence_path);
        errdefer allocator.free(owned_copy_evidence_path);
        const result: DormantAuthorityConfig = .{
            .allocator = allocator,
            .io = io,
            .guard = guard.*,
            .root_policy = root_policy.*,
            .control_root = owned_control,
            .authority_root = owned_authority,
            .payload_root = owned_payload,
            .source_root = owned_source,
            .source_manifest_sha256 = source_manifest_sha256[0..64].*,
            .expected_source_inventory_sha256 = source_inventory_sha256[0..64].*,
            .expected_source_file_ledger_sha256 = source_file_ledger_sha256[0..64].*,
            .expected_source_destination_ledger_sha256 = source_destination_ledger_sha256[0..64].*,
            .expected_copy_evidence_path = owned_copy_evidence_path,
            .expected_copy_evidence_sha256 = copy_evidence_sha256[0..64].*,
            .expected_registration_full_hash = guard.frozen.full_hash,
            .expected_registration_path_hash = guard.frozen.path_hash,
            .expected_registration_topology_hash = guard.frozen.topology_hash,
            .expected_registration_non_main_hash = guard.frozen.non_main_hash,
        };
        guard.* = undefined;
        root_policy.* = undefined;
        return result;
    }

    pub fn deinit(config: *DormantAuthorityConfig) void {
        config.allocator.free(config.expected_copy_evidence_path);
        config.allocator.free(config.source_root);
        config.allocator.free(config.payload_root);
        config.allocator.free(config.authority_root);
        config.allocator.free(config.control_root);
        config.root_policy.deinit();
        config.guard.deinit();
        config.* = undefined;
    }

    pub fn validateRegistration(config: *const DormantAuthorityConfig) !void {
        if (!std.mem.eql(
            u8,
            &config.expected_registration_full_hash,
            &config.guard.frozen.full_hash,
        ) or
            !std.mem.eql(
                u8,
                &config.expected_registration_path_hash,
                &config.guard.frozen.path_hash,
            ) or
            !std.mem.eql(
                u8,
                &config.expected_registration_topology_hash,
                &config.guard.frozen.topology_hash,
            ) or
            !std.mem.eql(
                u8,
                &config.expected_registration_non_main_hash,
                &config.guard.frozen.non_main_hash,
            ))
        {
            return error.DormantRegistrationStale;
        }
        config.guard.assertCurrent() catch return error.DormantRegistrationStale;
    }
};

const DormantAuthorityValidation = struct {
    manifest_sha256: [64]u8,
    payload_files: u64,
    payload_bytes: u64,
    objects: u64,
    snapshots: u64,
};

fn parseDormantOwnedRow(
    allocator: std.mem.Allocator,
    input: []const u8,
    magic: []const u8,
    header: []const u8,
    field_count: usize,
) !DormantOwnedRow {
    if (!std.mem.endsWith(u8, input, "\n") or std.mem.indexOfScalar(u8, input, '\r') != null) {
        return error.NonCanonicalDormantRecord;
    }
    const storage = try allocator.dupe(u8, input);
    errdefer allocator.free(storage);
    var lines = std.mem.splitScalar(u8, storage, '\n');
    if (!std.mem.eql(u8, lines.next() orelse return error.MissingDormantMagic, magic) or
        !std.mem.eql(u8, lines.next() orelse return error.MissingDormantHeader, header))
    {
        return error.UnknownDormantSchema;
    }
    const data = lines.next() orelse return error.MissingDormantRow;
    if (data.len == 0 or
        !std.mem.eql(u8, lines.next() orelse return error.NonCanonicalDormantRecord, "") or
        lines.next() != null)
    {
        return error.NonCanonicalDormantRecord;
    }
    const fields = try allocator.alloc([]const u8, field_count);
    errdefer allocator.free(fields);
    var field_it = std.mem.splitScalar(u8, data, '\t');
    for (fields) |*field| {
        field.* = field_it.next() orelse return error.MissingDormantField;
        try validateCanonicalField(allocator, field.*);
    }
    if (field_it.next() != null) return error.UnknownDormantField;

    var encoded: std.ArrayList(u8) = .empty;
    defer encoded.deinit(allocator);
    try encoded.appendSlice(allocator, magic);
    try encoded.append(allocator, '\n');
    try encoded.appendSlice(allocator, header);
    try encoded.append(allocator, '\n');
    for (fields, 0..) |field, index| {
        if (index != 0) try encoded.append(allocator, '\t');
        try encoded.appendSlice(allocator, field);
    }
    try encoded.append(allocator, '\n');
    if (!std.mem.eql(u8, encoded.items, input)) return error.NonCanonicalDormantRecord;
    return .{ .storage = storage, .fields = fields };
}

fn readDormantControlFile(
    config: *const DormantAuthorityConfig,
    component: DormantComponent,
    relative_path: []const u8,
) ![]u8 {
    if (!dormantControlKeyMatches(component, relative_path)) return component.unsafe();
    const expectation = dormantControlFileExpectation(
        &config.root_policy,
        component,
        relative_path,
    ) orelse return component.unsafe();
    var control = std.Io.Dir.openDirAbsolute(config.io, config.control_root, .{
        .access_sub_paths = true,
        .follow_symlinks = false,
    }) catch |err| return switch (err) {
        error.FileNotFound => component.missing(),
        error.SymLinkLoop, error.NotDir => component.unsafe(),
        else => component.malformed(),
    };
    defer control.close(config.io);
    const control_stat = control.stat(config.io) catch return component.unsafe();
    if (@as(u16, @intCast(control_stat.permissions.toMode() & 0o7777)) != 0o775) {
        return component.mismatched();
    }
    const parent_path = std.fs.path.dirname(relative_path) orelse ".";
    const basename = std.fs.path.basename(relative_path);
    var current = control;
    var current_owned = false;
    errdefer if (current_owned) current.close(config.io);
    var segments = std.mem.splitScalar(u8, parent_path, '/');
    while (segments.next()) |segment| {
        const next = openExistingDir(config.io, current, segment) catch |err|
            return switch (err) {
                error.FileNotFound => component.missing(),
                error.SymLinkLoop, error.NotDir => component.unsafe(),
                else => component.malformed(),
            };
        if (current_owned) current.close(config.io);
        current = next;
        current_owned = true;
        const directory_stat = current.stat(config.io) catch return component.unsafe();
        if (@as(u16, @intCast(directory_stat.permissions.toMode() & 0o7777)) != 0o755) {
            return component.mismatched();
        }
    }
    var parent = current;
    defer parent.close(config.io);
    current_owned = false;
    var file = parent.openFile(config.io, basename, .{
        .allow_directory = false,
        .follow_symlinks = false,
    }) catch |err| return switch (err) {
        error.FileNotFound => component.missing(),
        error.SymLinkLoop, error.NotDir => component.unsafe(),
        else => component.malformed(),
    };
    defer file.close(config.io);
    const stat = file.stat(config.io) catch return component.malformed();
    if (stat.kind != .file) return component.unsafe();
    if (@as(u16, @intCast(stat.permissions.toMode() & 0o7777)) != expectation.mode) {
        return component.mismatched();
    }
    if (config.root_policy.kind == .exact_real and stat.size != expectation.bytes) {
        return component.mismatched();
    }
    const size = std.math.cast(usize, stat.size) orelse return component.malformed();
    if (size > 4 * 1024 * 1024) return component.malformed();
    const bytes = try config.allocator.alloc(u8, size);
    errdefer config.allocator.free(bytes);
    var offset: usize = 0;
    while (offset < bytes.len) {
        const count = file.readPositional(
            config.io,
            &.{bytes[offset..]},
            offset,
        ) catch return component.malformed();
        if (count == 0) return component.malformed();
        offset += count;
    }
    var extra: [1]u8 = undefined;
    const extra_count = file.readPositional(
        config.io,
        &.{&extra},
        bytes.len,
    ) catch return component.malformed();
    if (extra_count != 0) return component.malformed();
    if (config.root_policy.kind == .exact_real and
        !std.mem.eql(u8, &sha256Hex(bytes), &expectation.sha256))
    {
        return component.mismatched();
    }
    return bytes;
}

fn dormantControlFileExpectation(
    policy: *const DormantRootPolicy,
    component: DormantComponent,
    relative_path: []const u8,
) ?*const DormantControlFileExpectation {
    var found: ?*const DormantControlFileExpectation = null;
    for (policy.control_files) |*expectation| {
        if (expectation.component == component and
            std.mem.eql(u8, expectation.path, relative_path))
        {
            if (found != null) return null;
            found = expectation;
        }
    }
    return found;
}

fn dormantControlKeyMatches(
    component: DormantComponent,
    relative_path: []const u8,
) bool {
    return switch (component) {
        .candidate => std.mem.eql(u8, relative_path, dormant_candidate_key),
        .generation => std.mem.eql(u8, relative_path, dormant_generation_key),
        .lineage => std.mem.eql(u8, relative_path, dormant_lineage_key),
        .receipt => std.mem.eql(u8, relative_path, dormant_receipt_key),
    };
}

fn validateDormantRoots(config: *const DormantAuthorityConfig) !void {
    try validateDormantControlRoot(config);
    try validateDormantAuthorityRoot(config);
    try validateDormantPayloadRoot(config);
    try validateDormantSourceRoot(config);
}

fn verifyDormantCopyEvidenceFromHeldRoot(
    allocator: std.mem.Allocator,
    io: std.Io,
    root: std.Io.Dir,
    relative_path: []const u8,
    expected_sha256: []const u8,
    max_bytes: u64,
) !FileIdentity {
    validateRelativeKey(relative_path) catch return error.DormantCopyEvidenceUnsafe;
    validateSha(expected_sha256) catch return error.DormantCopyEvidenceMismatched;
    const parent_path = std.fs.path.dirname(relative_path) orelse ".";
    const basename = std.fs.path.basename(relative_path);
    var parent = openPathNoFollow(io, root, parent_path, false) catch |err|
        return switch (err) {
            error.FileNotFound => error.DormantCopyEvidenceMissing,
            error.SymLinkLoop, error.NotDir => error.DormantCopyEvidenceUnsafe,
            else => error.DormantCopyEvidenceUnreadable,
        };
    defer parent.close(io);
    var file = parent.openFile(io, basename, .{
        .allow_directory = true,
        .follow_symlinks = false,
    }) catch |err| return switch (err) {
        error.FileNotFound => error.DormantCopyEvidenceMissing,
        error.SymLinkLoop, error.NotDir => error.DormantCopyEvidenceUnsafe,
        else => error.DormantCopyEvidenceUnreadable,
    };
    defer file.close(io);
    const stat = file.stat(io) catch return error.DormantCopyEvidenceUnreadable;
    if (stat.kind != .file) return error.DormantCopyEvidenceUnsafe;
    const mode: u16 = @intCast(stat.permissions.toMode() & 0o7777);
    if (mode & 0o111 != 0) return error.DormantCopyEvidenceExecutable;
    if (stat.size > max_bytes) return error.DormantCopyEvidenceTooLarge;
    var identity = identityOfOpenFileAnyMode(allocator, io, file) catch
        return error.DormantCopyEvidenceUnreadable;
    errdefer identity.deinit(allocator);
    if (identity.bytes != stat.size or identity.bytes > max_bytes or identity.mode != mode) {
        return error.DormantCopyEvidenceChangedDuringRead;
    }
    if (!std.mem.eql(u8, &identity.sha256, expected_sha256)) {
        return error.DormantCopyEvidenceMismatched;
    }
    return identity;
}

fn verifyDormantExactRealCopyEvidence(
    config: *const DormantAuthorityConfig,
) !void {
    if (config.root_policy.kind != .exact_real or
        !std.mem.eql(u8, config.root_policy.main_root, main_repository) or
        !std.mem.eql(u8, config.expected_copy_evidence_path, dormant_exact_real_copy_evidence_path) or
        !std.mem.eql(
            u8,
            &config.expected_copy_evidence_sha256,
            dormant_exact_real_copy_evidence_sha256,
        ))
    {
        return error.DormantCopyEvidenceAuthorityMismatched;
    }
    var repository = std.Io.Dir.openDirAbsolute(config.io, main_repository, .{
        .access_sub_paths = true,
        .follow_symlinks = false,
    }) catch return error.DormantCopyEvidenceUnsafe;
    defer repository.close(config.io);
    var identity = try verifyDormantCopyEvidenceFromHeldRoot(
        config.allocator,
        config.io,
        repository,
        config.expected_copy_evidence_path,
        &config.expected_copy_evidence_sha256,
        dormant_exact_real_copy_evidence_max_bytes,
    );
    identity.deinit(config.allocator);
}

fn validateDormantRoleDirectory(
    config: *const DormantAuthorityConfig,
    actual: []const u8,
    expected: []const u8,
    expected_mode: u16,
    missing_is_partial: bool,
) !void {
    if (!std.mem.eql(u8, actual, expected)) return error.DormantUnsafeRoot;
    const normalized = normalizedAbsolute(config.allocator, actual) catch
        return error.DormantUnsafeRoot;
    defer config.allocator.free(normalized);
    if (!std.mem.eql(u8, normalized, actual)) return error.DormantUnsafeRoot;
    const exists = validateAuthorityAncestry(config.allocator, config.io, actual) catch
        return error.DormantUnsafeRoot;
    if (!exists) {
        if (missing_is_partial) return error.DormantDestinationPartial;
        return error.DormantUnsafeRoot;
    }
    var directory = std.Io.Dir.openDirAbsolute(config.io, actual, .{
        .follow_symlinks = false,
    }) catch return error.DormantUnsafeRoot;
    defer directory.close(config.io);
    const stat = directory.stat(config.io) catch return error.DormantUnsafeRoot;
    if (@as(u16, @intCast(stat.permissions.toMode() & 0o7777)) != expected_mode) {
        return error.DormantUnsafeRoot;
    }
}

fn validateDormantNonMainDisjoint(
    policy: *const DormantRootPolicy,
    path: []const u8,
) !void {
    for (policy.non_main_roots) |protected| {
        if (pathsIntersect(path, protected)) return error.DormantUnsafeRoot;
    }
}

fn validateDormantControlRoot(config: *const DormantAuthorityConfig) !void {
    const policy = &config.root_policy;
    try validateDormantRoleDirectory(
        config,
        config.control_root,
        policy.control_root,
        0o775,
        false,
    );
    if (!pathContains(policy.main_root, config.control_root)) {
        return error.DormantUnsafeRoot;
    }
    try validateDormantNonMainDisjoint(policy, config.control_root);
    try validateControlGitObservation(policy.observed_control, policy.expected_control);
}

fn validateDormantAuthorityRoot(config: *const DormantAuthorityConfig) !void {
    const policy = &config.root_policy;
    try validateDormantRoleDirectory(
        config,
        config.authority_root,
        policy.authority_root,
        0o755,
        false,
    );
    if (!pathContains(config.control_root, config.authority_root) or
        !pathContains(policy.main_root, config.authority_root))
    {
        return error.DormantUnsafeRoot;
    }
    try validateDormantNonMainDisjoint(policy, config.authority_root);
}

fn validateDormantPayloadRoot(config: *const DormantAuthorityConfig) !void {
    const policy = &config.root_policy;
    try validateDormantRoleDirectory(
        config,
        config.payload_root,
        policy.payload_root,
        0o755,
        true,
    );
    if (!pathContains(policy.main_root, config.payload_root) or
        pathsIntersect(config.payload_root, policy.supplemental_control_root) or
        pathsIntersect(config.payload_root, config.control_root) or
        pathsIntersect(config.payload_root, config.authority_root) or
        pathsIntersect(config.payload_root, config.source_root))
    {
        return error.DormantUnsafeRoot;
    }
    try validateDormantNonMainDisjoint(policy, config.payload_root);
}

fn validateDormantSourceRoot(config: *const DormantAuthorityConfig) !void {
    const policy = &config.root_policy;
    try validateDormantRoleDirectory(
        config,
        config.source_root,
        policy.source_root,
        0o775,
        false,
    );
    if (pathsIntersect(config.source_root, policy.main_root) or
        pathsIntersect(config.source_root, policy.supplemental_control_root) or
        pathsIntersect(config.source_root, config.control_root) or
        pathsIntersect(config.source_root, config.authority_root) or
        pathsIntersect(config.source_root, config.payload_root))
    {
        return error.DormantUnsafeRoot;
    }
    try validateDormantNonMainDisjoint(policy, config.source_root);
}

const DormantExpectedEntry = struct {
    path: []u8,
    kind: std.Io.File.Kind,
};

fn appendDormantExpected(
    allocator: std.mem.Allocator,
    entries: *std.ArrayList(DormantExpectedEntry),
    path: []const u8,
    kind: std.Io.File.Kind,
) !void {
    for (entries.items) |entry| {
        if (std.mem.eql(u8, entry.path, path)) {
            if (entry.kind != kind) return error.DormantDestinationMismatched;
            return;
        }
    }
    try entries.append(allocator, .{
        .path = try allocator.dupe(u8, path),
        .kind = kind,
    });
}

fn freeDormantExpected(
    allocator: std.mem.Allocator,
    entries: *std.ArrayList(DormantExpectedEntry),
) void {
    for (entries.items) |entry| allocator.free(entry.path);
    entries.deinit(allocator);
}

fn findDormantExpected(
    entries: []const DormantExpectedEntry,
    path: []const u8,
    kind: std.Io.File.Kind,
) bool {
    for (entries) |entry| {
        if (entry.kind == kind and std.mem.eql(u8, entry.path, path)) return true;
    }
    return false;
}

fn inspectDormantTree(
    allocator: std.mem.Allocator,
    io: std.Io,
    dir: std.Io.Dir,
    prefix: []const u8,
    expected: []const DormantExpectedEntry,
    actual_count: *usize,
) !void {
    var iterator = dir.iterate();
    while (try iterator.next(io)) |entry| {
        const relative = if (prefix.len == 0)
            try allocator.dupe(u8, entry.name)
        else
            try std.fs.path.join(allocator, &.{ prefix, entry.name });
        defer allocator.free(relative);
        switch (entry.kind) {
            .directory => {
                if (!findDormantExpected(expected, relative, .directory)) {
                    return error.DormantDestinationExtra;
                }
                var child = dir.openDir(io, entry.name, .{
                    .access_sub_paths = true,
                    .iterate = true,
                    .follow_symlinks = false,
                }) catch return error.DormantDestinationUnsafe;
                defer child.close(io);
                const stat = child.stat(io) catch return error.DormantDestinationUnsafe;
                if (@as(u16, @intCast(stat.permissions.toMode() & 0o7777)) != 0o755) {
                    return error.DormantDestinationMismatched;
                }
                actual_count.* += 1;
                try inspectDormantTree(
                    allocator,
                    io,
                    child,
                    relative,
                    expected,
                    actual_count,
                );
            },
            .file => {
                if (!findDormantExpected(expected, relative, .file)) {
                    return error.DormantDestinationExtra;
                }
                actual_count.* += 1;
            },
            else => return error.DormantDestinationUnsafe,
        }
    }
}

fn verifyDormantDestination(
    config: *const DormantAuthorityConfig,
    manifest: Manifest,
) !DormantAuthorityValidation {
    var expected: std.ArrayList(DormantExpectedEntry) = .empty;
    defer freeDormantExpected(config.allocator, &expected);
    try appendDormantExpected(config.allocator, &expected, "incoming", .directory);
    try appendDormantExpected(config.allocator, &expected, "objects", .directory);
    try appendDormantExpected(config.allocator, &expected, "objects/sha256", .directory);
    try appendDormantExpected(config.allocator, &expected, "snapshots", .directory);
    try appendDormantExpected(config.allocator, &expected, "snapshots/sha256", .directory);

    var payload_files: u64 = 0;
    var payload_bytes: u64 = 0;
    var objects: u64 = 0;
    var snapshots: u64 = 0;
    for (manifest.rows) |row| {
        if (row.kind != .object and row.kind != .snapshot) continue;
        const split = if (row.kind == .object)
            splitObjectKey(row.key)
        else
            splitSnapshotKey(row.key);
        const key_split = split orelse return error.DormantDestinationMismatched;
        if (!std.mem.eql(u8, key_split.prefix, row.sha256[0..2])) {
            return error.DormantDestinationMismatched;
        }
        const prefix_path = if (row.kind == .object)
            try std.fmt.allocPrint(
                config.allocator,
                "objects/sha256/{s}",
                .{key_split.prefix},
            )
        else
            try std.fmt.allocPrint(
                config.allocator,
                "snapshots/sha256/{s}",
                .{key_split.prefix},
            );
        defer config.allocator.free(prefix_path);
        try appendDormantExpected(config.allocator, &expected, prefix_path, .directory);
        try appendDormantExpected(config.allocator, &expected, row.key, .file);
        payload_files += 1;
        payload_bytes = std.math.add(u64, payload_bytes, row.bytes) catch
            return error.DormantDestinationMismatched;
        if (row.kind == .object) objects += 1 else snapshots += 1;
    }

    var root = std.Io.Dir.openDirAbsolute(config.io, config.payload_root, .{
        .access_sub_paths = true,
        .iterate = true,
        .follow_symlinks = false,
    }) catch |err| return switch (err) {
        error.FileNotFound => error.DormantDestinationPartial,
        error.SymLinkLoop, error.NotDir => error.DormantDestinationUnsafe,
        else => error.DormantDestinationMismatched,
    };
    defer root.close(config.io);
    const root_stat = root.stat(config.io) catch return error.DormantDestinationUnsafe;
    if (@as(u16, @intCast(root_stat.permissions.toMode() & 0o7777)) != 0o755) {
        return error.DormantDestinationMismatched;
    }
    var actual_count: usize = 0;
    try inspectDormantTree(
        config.allocator,
        config.io,
        root,
        "",
        expected.items,
        &actual_count,
    );
    if (actual_count != expected.items.len) return error.DormantDestinationPartial;

    for (manifest.rows) |row| {
        if (row.kind != .object and row.kind != .snapshot) continue;
        const parent_path = std.fs.path.dirname(row.key) orelse
            return error.DormantDestinationMismatched;
        const basename = std.fs.path.basename(row.key);
        var parent = openPathNoFollow(config.io, root, parent_path, false) catch |err|
            return switch (err) {
                error.FileNotFound => error.DormantDestinationPartial,
                error.SymLinkLoop, error.NotDir => error.DormantDestinationUnsafe,
                else => error.DormantDestinationMismatched,
            };
        defer parent.close(config.io);
        var identity = verifyRelativeFile(
            config.allocator,
            config.io,
            parent,
            basename,
            0o444,
        ) catch |err| return switch (err) {
            error.FileNotFound => error.DormantDestinationPartial,
            error.SymLinkLoop, error.NotDir, error.NotRegularFile => error.DormantDestinationUnsafe,
            else => error.DormantDestinationMismatched,
        };
        defer identity.deinit(config.allocator);
        if (!std.mem.eql(u8, &identity.sha256, row.sha256) or identity.bytes != row.bytes) {
            return error.DormantDestinationMismatched;
        }
    }
    return .{
        .manifest_sha256 = undefined,
        .payload_files = payload_files,
        .payload_bytes = payload_bytes,
        .objects = objects,
        .snapshots = snapshots,
    };
}

fn validateDormantAuthorityCandidate(
    config: *const DormantAuthorityConfig,
) !DormantAuthorityValidation {
    try config.validateRegistration();
    try validateDormantRoots(config);
    if (config.root_policy.kind == .exact_real and
        std.mem.eql(u8, config.root_policy.main_root, main_repository))
    {
        try verifyDormantExactRealCopyEvidence(config);
    }

    const candidate_bytes = try readDormantControlFile(
        config,
        .candidate,
        dormant_candidate_key,
    );
    defer config.allocator.free(candidate_bytes);
    var candidate = parseDormantOwnedRow(
        config.allocator,
        candidate_bytes,
        dormant_candidate_magic,
        dormant_candidate_header,
        14,
    ) catch return error.DormantCandidateMalformed;
    defer candidate.deinit(config.allocator);
    const c = candidate.fields;
    validateRelativeKey(c[3]) catch return error.DormantCandidateUnsafe;
    validateRelativeKey(c[7]) catch return error.DormantCandidateUnsafe;
    validateRelativeKey(c[9]) catch return error.DormantCandidateUnsafe;
    validateSha(c[4]) catch return error.DormantCandidateMalformed;
    validateSha(c[8]) catch return error.DormantCandidateMalformed;
    validateSha(c[10]) catch return error.DormantCandidateMalformed;
    validateSha(c[12]) catch return error.DormantCandidateMalformed;
    const declared_manifest_bytes = std.fmt.parseInt(u64, c[5], 10) catch
        return error.DormantCandidateMalformed;
    const declared_manifest_mode = std.fmt.parseInt(u16, c[6], 8) catch
        return error.DormantCandidateMalformed;
    if (!std.mem.eql(u8, c[0], "zllvm-local-state-v1") or
        !std.mem.eql(u8, c[1], "00000001") or
        !std.mem.eql(u8, c[2], config.payload_root) or
        !std.mem.eql(u8, c[3], dormant_generation_key) or
        declared_manifest_mode != 0o644 or
        !std.mem.eql(u8, c[7], dormant_lineage_key) or
        !std.mem.eql(u8, c[9], dormant_receipt_key) or
        !std.mem.eql(u8, c[11], config.source_root) or
        !std.mem.eql(u8, c[12], &config.source_manifest_sha256) or
        !std.mem.eql(u8, c[13], "candidate"))
    {
        return error.DormantCandidateMismatched;
    }

    const generation_bytes = try readDormantControlFile(
        config,
        .generation,
        dormant_generation_key,
    );
    defer config.allocator.free(generation_bytes);
    if (!std.mem.eql(u8, &sha256Hex(generation_bytes), c[4]) or
        generation_bytes.len != declared_manifest_bytes)
    {
        return error.DormantGenerationMismatched;
    }
    var manifest = parseManifest(config.allocator, generation_bytes) catch
        return error.DormantGenerationMalformed;
    defer manifest.deinit(config.allocator);
    const reencoded_manifest = encodeManifest(config.allocator, manifest) catch
        return error.DormantGenerationMalformed;
    defer config.allocator.free(reencoded_manifest);
    if (!std.mem.eql(u8, reencoded_manifest, generation_bytes)) {
        return error.DormantGenerationMalformed;
    }

    const lineage_bytes = try readDormantControlFile(
        config,
        .lineage,
        dormant_lineage_key,
    );
    defer config.allocator.free(lineage_bytes);
    if (!std.mem.eql(u8, &sha256Hex(lineage_bytes), c[8])) {
        return error.DormantLineageMismatched;
    }
    var lineage = parseDormantOwnedRow(
        config.allocator,
        lineage_bytes,
        dormant_lineage_magic,
        dormant_lineage_header,
        7,
    ) catch return error.DormantLineageMalformed;
    defer lineage.deinit(config.allocator);
    const l = lineage.fields;
    validateSha(l[3]) catch return error.DormantLineageMalformed;
    validateSha(l[5]) catch return error.DormantLineageMalformed;
    if (!std.mem.eql(u8, l[0], "00000001") or
        !std.mem.eql(u8, l[1], "-") or
        !std.mem.eql(u8, l[2], "-") or
        !std.mem.eql(u8, l[3], c[4]) or
        !std.mem.eql(u8, l[4], config.source_root) or
        !std.mem.eql(u8, l[5], &config.source_manifest_sha256) or
        !std.mem.eql(u8, l[6], "non_destructive_verified_copy"))
    {
        return error.DormantLineageMismatched;
    }

    const receipt_bytes = try readDormantControlFile(
        config,
        .receipt,
        dormant_receipt_key,
    );
    defer config.allocator.free(receipt_bytes);
    if (!std.mem.eql(u8, &sha256Hex(receipt_bytes), c[10])) {
        return error.DormantReceiptMismatched;
    }
    var receipt = parseDormantOwnedRow(
        config.allocator,
        receipt_bytes,
        dormant_receipt_magic,
        dormant_receipt_header,
        15,
    ) catch return error.DormantReceiptMalformed;
    defer receipt.deinit(config.allocator);
    const r = receipt.fields;
    validateSha(r[4]) catch return error.DormantReceiptMalformed;
    validateSha(r[5]) catch return error.DormantReceiptMalformed;
    validateSha(r[6]) catch return error.DormantReceiptMalformed;
    validateRelativeKey(r[12]) catch return error.DormantReceiptUnsafe;
    validateSha(r[13]) catch return error.DormantReceiptMalformed;
    const receipt_files = std.fmt.parseInt(u64, r[7], 10) catch
        return error.DormantReceiptMalformed;
    const receipt_bytes_count = std.fmt.parseInt(u64, r[8], 10) catch
        return error.DormantReceiptMalformed;
    const receipt_objects = std.fmt.parseInt(u64, r[9], 10) catch
        return error.DormantReceiptMalformed;
    const receipt_snapshots = std.fmt.parseInt(u64, r[10], 10) catch
        return error.DormantReceiptMalformed;
    if (!std.mem.eql(u8, r[0], "zllvm-generation-00000001-payload-copy") or
        !std.mem.eql(u8, r[1], "00000001") or
        !std.mem.eql(u8, r[2], config.source_root) or
        !std.mem.eql(u8, r[3], config.payload_root) or
        !std.mem.eql(u8, r[4], &config.expected_source_inventory_sha256) or
        !std.mem.eql(u8, r[5], &config.expected_source_file_ledger_sha256) or
        !std.mem.eql(u8, r[6], &config.expected_source_destination_ledger_sha256) or
        !std.mem.eql(u8, r[11], "0444") or
        !std.mem.eql(u8, r[12], config.expected_copy_evidence_path) or
        !std.mem.eql(u8, r[13], &config.expected_copy_evidence_sha256) or
        !std.mem.eql(u8, r[14], "verified_non_authoritative_copy"))
    {
        return error.DormantReceiptMismatched;
    }

    var validation = try verifyDormantDestination(config, manifest);
    if (validation.payload_files != receipt_files or
        validation.payload_bytes != receipt_bytes_count or
        validation.objects != receipt_objects or
        validation.snapshots != receipt_snapshots)
    {
        return error.DormantReceiptMismatched;
    }
    validation.manifest_sha256 = sha256Hex(generation_bytes);
    try config.validateRegistration();
    return validation;
}

fn validateAuthorityAncestry(
    allocator: std.mem.Allocator,
    io: std.Io,
    root_path: []const u8,
) !bool {
    if (!std.fs.path.isAbsolute(root_path)) return error.PathNotAbsolute;
    const normalized = try normalizedAbsolute(allocator, root_path);
    defer allocator.free(normalized);
    if (!std.mem.eql(u8, normalized, root_path)) return error.PathNotNormalized;

    var components = std.fs.path.componentIterator(root_path);
    while (components.next()) |component| {
        var directory = std.Io.Dir.openDirAbsolute(io, component.path, .{
            .iterate = true,
            .follow_symlinks = false,
        }) catch |err| switch (err) {
            error.FileNotFound => return false,
            error.SymLinkLoop => return error.AuthoritySymlinkComponent,
            error.NotDir => return error.AuthorityNonDirectoryComponent,
            else => return err,
        };
        directory.close(io);
    }
    return true;
}

pub const API = struct {
    pub const candidate_key = dormant_candidate_key;
    pub const generation_key = dormant_generation_key;
    pub const lineage_key = dormant_lineage_key;
    pub const receipt_key = dormant_receipt_key;
    pub const candidate_magic = dormant_candidate_magic;
    pub const candidate_header = dormant_candidate_header;
    pub const lineage_magic = dormant_lineage_magic;
    pub const lineage_header = dormant_lineage_header;
    pub const receipt_magic = dormant_receipt_magic;
    pub const receipt_header = dormant_receipt_header;
    pub const real_control_root = dormant_real_control_root;
    pub const real_payload_root = dormant_real_payload_root;
    pub const real_source_root = dormant_real_source_root;
    pub const git_executable = dormant_git_executable;
    pub const git_bytes = dormant_git_bytes;
    pub const git_sha256 = dormant_git_sha256;
    pub const test_root = dormant_test_root;
    pub const exact_real_copy_evidence_path = dormant_exact_real_copy_evidence_path;
    pub const exact_real_copy_evidence_sha256 = dormant_exact_real_copy_evidence_sha256;
    pub const exact_real_copy_evidence_max_bytes = dormant_exact_real_copy_evidence_max_bytes;

    pub const ControlObservation = ControlGitObservation;
    pub const ControlFileExpectationSpec = DormantControlFileExpectationSpec;
    pub const AuthorityConfig = DormantAuthorityConfig;
    pub const AuthorityValidation = DormantAuthorityValidation;

    pub const readControlFile = readDormantControlFile;
    pub const verifyCopyEvidenceFromHeldRoot = verifyDormantCopyEvidenceFromHeldRoot;
    pub const validateCandidate = validateDormantAuthorityCandidate;
    pub const validateAncestry = validateAuthorityAncestry;
};
