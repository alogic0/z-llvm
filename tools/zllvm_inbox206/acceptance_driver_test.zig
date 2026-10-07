const std = @import("std");
const provenance = @import("provenance.zig");
const receipt = @import("receipt.zig");
const driver_module = @import("acceptance_driver.zig");

const fixedIdentity = provenance.fixedIdentity;
const canonicalRepositoryPath = provenance.canonicalRepositoryPath;
const equalGitIdentity = provenance.equalGitIdentity;
const equalRawIdentity = provenance.equalRawIdentity;
const equalCanonicalPath = provenance.equalCanonicalPath;
const capability_source_count = provenance.capability_source_count;
const canonicalReceiptToken = receipt.canonicalReceiptToken;
const encodeCanonicalReceipt = receipt.encodeCanonicalReceipt;
const receipt_required_semantic_bits = receipt.receipt_required_semantic_bits;

const DriverError = driver_module.DriverError;
const DriverProcessId = driver_module.DriverProcessId;
const FixedProcessSpecification = driver_module.FixedProcessSpecification;
const git_environment = driver_module.git_environment;
const zig_environment = driver_module.zig_environment;
const git_object_format_argv = driver_module.git_object_format_argv;
const git_staged_listing_argv = driver_module.git_staged_listing_argv;
const git_staged_tree_argv = driver_module.git_staged_tree_argv;
const zig_format_argv = driver_module.zig_format_argv;
const zig_focused_test_argv = driver_module.zig_focused_test_argv;
const driver_process_specs = driver_module.driver_process_specs;
const processSpecification = driver_module.processSpecification;
const ProcessTermination = driver_module.ProcessTermination;
const ObservedProcessResult = driver_module.ObservedProcessResult;
const AuthenticatedProcessResult = driver_module.AuthenticatedProcessResult;
const ObservedSourceCapture = driver_module.ObservedSourceCapture;
const ObservedRepositoryScope = driver_module.ObservedRepositoryScope;
const ValidatedRepositoryScope = driver_module.ValidatedRepositoryScope;
const AuthenticatedRepositoryScope = driver_module.AuthenticatedRepositoryScope;
const ObservedBootstrap = driver_module.ObservedBootstrap;
const ValidatedBootstrap = driver_module.ValidatedBootstrap;
const AuthenticatedBootstrap = driver_module.AuthenticatedBootstrap;
const ObservedStagedSource = driver_module.ObservedStagedSource;
const ValidatedStagedSource = driver_module.ValidatedStagedSource;
const AuthenticatedStagedSource = driver_module.AuthenticatedStagedSource;
const ObservedValidationDirectory = driver_module.ObservedValidationDirectory;
const ValidatedValidationDirectory = driver_module.ValidatedValidationDirectory;
const AuthenticatedValidationDirectory = driver_module.AuthenticatedValidationDirectory;
const AcceptanceAuthorityContext = driver_module.AcceptanceAuthorityContext;
const validateObservedRepositoryScope = driver_module.validateObservedRepositoryScope;
const authenticateValidatedRepositoryScope = driver_module.authenticateValidatedRepositoryScope;
const validateObservedBootstrap = driver_module.validateObservedBootstrap;
const authenticateValidatedBootstrap = driver_module.authenticateValidatedBootstrap;
const normalizeAuthenticatedProcessResult = driver_module.normalizeAuthenticatedProcessResult;
const parseGitSha1Line = driver_module.parseGitSha1Line;
const parseStagedListing = driver_module.parseStagedListing;
const normalizeAuthenticatedStagedSource = driver_module.normalizeAuthenticatedStagedSource;
const authenticateValidatedStagedSource = driver_module.authenticateValidatedStagedSource;
const validateObservedValidationDirectory = driver_module.validateObservedValidationDirectory;
const authenticateValidatedValidationDirectory = driver_module.authenticateValidatedValidationDirectory;
const SemanticGateId = driver_module.SemanticGateId;
const AuthenticatedSemanticGate = driver_module.AuthenticatedSemanticGate;
const requireSyntheticGate = driver_module.requireSyntheticGate;
const gateCanonicalTupleAdmission = driver_module.gateCanonicalTupleAdmission;
const gateSyntheticAuthorityBinding = driver_module.gateSyntheticAuthorityBinding;
const gatePreDescriptorRejection = driver_module.gatePreDescriptorRejection;
const gatePostSealLengthSha = driver_module.gatePostSealLengthSha;
const gateFreshOwnedReplay = driver_module.gateFreshOwnedReplay;
const gateConsumedHandoffRejection = driver_module.gateConsumedHandoffRejection;
const gateOwnershipExactlyOnceClose = driver_module.gateOwnershipExactlyOnceClose;
const collectSemanticGateBits = driver_module.collectSemanticGateBits;
const ValidatedPublicationTarget = driver_module.ValidatedPublicationTarget;
const validatePublicationTarget = driver_module.validatePublicationTarget;
const equalPublicationTarget = driver_module.equalPublicationTarget;
const BoundReceipt = driver_module.BoundReceipt;
const PreparedReceipt = driver_module.PreparedReceipt;
const PublishedReceipt = driver_module.PublishedReceipt;
const bindPublishedReceipt = driver_module.bindPublishedReceipt;
const DriverPhase = driver_module.DriverPhase;
const AcceptanceDriver = driver_module.AcceptanceDriver;
const syntheticDescriptorIdentity = driver_module.syntheticDescriptorIdentity;
const syntheticAuthorityContext = driver_module.syntheticAuthorityContext;
const syntheticObservedProcess = driver_module.syntheticObservedProcess;
const test_support = driver_module.test_support;
const path_b_test_support = driver_module.path_b_test_support;
const syntheticStagedListing = driver_module.syntheticStagedListing;
const SyntheticStagedListingFault = driver_module.SyntheticStagedListingFault;
const syntheticStagedListingWithFault = driver_module.syntheticStagedListingWithFault;
const syntheticTreeOutput = driver_module.syntheticTreeOutput;
const syntheticAuthenticatedBootstrap = driver_module.syntheticAuthenticatedBootstrap;
const syntheticAuthenticatedProcess = driver_module.syntheticAuthenticatedProcess;
const syntheticObservedStagedSource = driver_module.syntheticObservedStagedSource;
const syntheticObservedSourceCaptures = driver_module.syntheticObservedSourceCaptures;
const syntheticAuthenticatedStagedSource = driver_module.syntheticAuthenticatedStagedSource;
const syntheticSemanticGates = driver_module.syntheticSemanticGates;
const syntheticAuthenticatedRepository = driver_module.syntheticAuthenticatedRepository;
const syntheticAuthenticatedValidationDirectory = driver_module.syntheticAuthenticatedValidationDirectory;
const advanceSyntheticDriverToPreparedReceipt = driver_module.advanceSyntheticDriverToPreparedReceipt;
const syntheticPublishedReceipt = driver_module.syntheticPublishedReceipt;
const failClosedRealRepositoryAdapter = driver_module.failClosedRealRepositoryAdapter;
const failClosedRealBootstrapAdapter = driver_module.failClosedRealBootstrapAdapter;
const failClosedRealProcessAdapter = driver_module.failClosedRealProcessAdapter;
const failClosedRealNativeProcessAdapter = driver_module.failClosedRealNativeProcessAdapter;
const failClosedRealValidationDirectoryAdapter = driver_module.failClosedRealValidationDirectoryAdapter;
const isRecursivelySafeAcceptanceValue = driver_module.isRecursivelySafeAcceptanceValue;

fn sourceSetBytes(root_bytes: []const u8) [capability_source_count][]const u8 {
    var result = driver_module.synthetic_source_bytes;
    result[capability_source_count - 1] = root_bytes;
    return result;
}

fn processCaptureAllocationHarness(allocator: std.mem.Allocator) !void {
    const source_bytes = sourceSetBytes("process allocation source");
    const context = try syntheticAuthorityContext(source_bytes);
    const bootstrap = try syntheticAuthenticatedBootstrap(&context);
    const observed = ObservedProcessResult{
        .specification_id = .zig_format_check,
        .executable_identity = context.zig_executable_identity,
        .stdout = "scoped stdout",
        .stderr = "scoped stderr",
    };
    _ = try normalizeAuthenticatedProcessResult(
        allocator,
        observed,
        .zig_format_check,
        bootstrap,
        &context,
    );
}

fn stagedCaptureAllocationHarness(allocator: std.mem.Allocator) !void {
    const source_bytes = sourceSetBytes("partial staged allocation source");
    const context = try syntheticAuthorityContext(source_bytes);
    const bootstrap = try syntheticAuthenticatedBootstrap(&context);
    var listing_buffer: [4096]u8 = undefined;
    var tree_buffer: [64]u8 = undefined;
    const observed = try syntheticObservedStagedSource(
        source_bytes,
        &context,
        bootstrap,
        &listing_buffer,
        &tree_buffer,
    );
    _ = try normalizeAuthenticatedStagedSource(
        allocator,
        observed,
        bootstrap,
        &context,
    );
}

fn driverAllocationHarness(allocator: std.mem.Allocator) !void {
    const source_bytes = sourceSetBytes("driver allocation source");
    const context = try syntheticAuthorityContext(source_bytes);
    var driver = AcceptanceDriver{};
    defer driver.deinit();
    _ = try advanceSyntheticDriverToPreparedReceipt(
        allocator,
        &driver,
        &context,
        source_bytes,
        try validatePublicationTarget("allocation-receipt.tsv"),
    );
}

test "scoped process normalization returns alias-proof fixed authentication" {
    var fixture = [_]u8{ 's', 't', 'd', 'o', 'u', 't' };
    const context = try syntheticAuthorityContext(sourceSetBytes("scoped process source"));
    const bootstrap = try syntheticAuthenticatedBootstrap(&context);
    const observed = ObservedProcessResult{
        .specification_id = .zig_format_check,
        .executable_identity = context.zig_executable_identity,
        .stdout = &fixture,
        .stderr = "",
    };
    const authenticated = try normalizeAuthenticatedProcessResult(
        std.testing.allocator,
        observed,
        .zig_format_check,
        bootstrap,
        &context,
    );
    var copied = authenticated;
    fixture[0] = 'X';
    copied.specification_id = .zig_focused_test;
    try std.testing.expectEqual(DriverProcessId.zig_format_check, authenticated.specification_id);
    try std.testing.expectEqual(DriverProcessId.zig_focused_test, copied.specification_id);
    try std.testing.expect(authenticated.context == &context);
    comptime {
        if (@hasField(AuthenticatedProcessResult, "allocator") or
            @hasField(AuthenticatedProcessResult, "stdout") or
            @hasField(AuthenticatedProcessResult, "stderr"))
        {
            @compileError("authenticated process tokens must not retain capture ownership");
        }
    }
}

test "borrowed aliases cannot mutate normalized success failure or reuse state" {
    var stdout_fixture = [_]u8{ 'o', 'k' };
    const source_bytes = sourceSetBytes("alias source");
    const context_value = try syntheticAuthorityContext(source_bytes);
    const contexts = [2]AcceptanceAuthorityContext{ context_value, context_value };
    const context_a = &contexts[0];
    const context_b = &contexts[1];
    const bootstrap_a = try syntheticAuthenticatedBootstrap(context_a);
    const observed = ObservedProcessResult{
        .specification_id = .zig_format_check,
        .executable_identity = context_a.zig_executable_identity,
        .stdout = &stdout_fixture,
        .stderr = "",
    };
    const failing_alias = observed;
    try std.testing.expectError(
        error.AuthorityContextMismatch,
        normalizeAuthenticatedProcessResult(
            std.testing.allocator,
            failing_alias,
            .zig_format_check,
            bootstrap_a,
            context_b,
        ),
    );
    const first = try normalizeAuthenticatedProcessResult(
        std.testing.allocator,
        observed,
        .zig_format_check,
        bootstrap_a,
        context_a,
    );
    stdout_fixture[0] = 'X';
    const second = try normalizeAuthenticatedProcessResult(
        std.testing.allocator,
        observed,
        .zig_format_check,
        bootstrap_a,
        context_a,
    );
    try std.testing.expectEqualDeep(first, second);

    var listing_buffer: [4096]u8 = undefined;
    var tree_buffer: [64]u8 = undefined;
    const staged_observed = try syntheticObservedStagedSource(
        source_bytes,
        context_a,
        bootstrap_a,
        &listing_buffer,
        &tree_buffer,
    );
    var staged_alias = staged_observed;
    staged_alias.sources[0].context = context_b;
    try std.testing.expectError(
        error.AuthorityContextMismatch,
        normalizeAuthenticatedStagedSource(
            std.testing.allocator,
            staged_alias,
            bootstrap_a,
            context_a,
        ),
    );
    const staged_first = try normalizeAuthenticatedStagedSource(
        std.testing.allocator,
        staged_observed,
        bootstrap_a,
        context_a,
    );
    const staged_second = try normalizeAuthenticatedStagedSource(
        std.testing.allocator,
        staged_observed,
        bootstrap_a,
        context_a,
    );
    try std.testing.expectEqualDeep(staged_first, staged_second);
}

test "authenticated and receipt values have no owning capture fields" {
    comptime {
        if (!isRecursivelySafeAcceptanceValue(AuthenticatedRepositoryScope) or
            !isRecursivelySafeAcceptanceValue(AuthenticatedBootstrap) or
            !isRecursivelySafeAcceptanceValue(AuthenticatedProcessResult) or
            !isRecursivelySafeAcceptanceValue(AuthenticatedStagedSource) or
            !isRecursivelySafeAcceptanceValue(AuthenticatedValidationDirectory) or
            !isRecursivelySafeAcceptanceValue(AuthenticatedSemanticGate) or
            !isRecursivelySafeAcceptanceValue(PreparedReceipt) or
            !isRecursivelySafeAcceptanceValue(PublishedReceipt) or
            !isRecursivelySafeAcceptanceValue(AcceptanceDriver))
        {
            @compileError("authenticated values must satisfy the recursive safe-leaf policy");
        }
        if (isRecursivelySafeAcceptanceValue(struct { bytes: []const u8 }) or
            isRecursivelySafeAcceptanceValue(struct { pointer: *const u8 }) or
            isRecursivelySafeAcceptanceValue(struct { mutable_context: *AcceptanceAuthorityContext }) or
            isRecursivelySafeAcceptanceValue(struct { specification: *const FixedProcessSpecification }) or
            isRecursivelySafeAcceptanceValue(struct { prepared: *const PreparedReceipt }) or
            isRecursivelySafeAcceptanceValue(struct { callback: *const fn () void }) or
            isRecursivelySafeAcceptanceValue(struct { allocator: std.mem.Allocator }) or
            isRecursivelySafeAcceptanceValue(struct { fd: i32 }) or
            isRecursivelySafeAcceptanceValue(struct { handle: usize }) or
            isRecursivelySafeAcceptanceValue(comptime_int) or
            !isRecursivelySafeAcceptanceValue(*const AcceptanceAuthorityContext))
        {
            @compileError("unsafe slices, pointers, allocators, and handle leaves must be rejected");
        }
    }
}

test "scoped staged normalization copies fixtures and returns alias-proof identities" {
    var root_fixture = [_]u8{ 'o', 'w', 'n', 'e', 'd', '-', 'r', 'o', 'o', 't' };
    const source_bytes = sourceSetBytes(&root_fixture);
    const context = try syntheticAuthorityContext(source_bytes);
    const bootstrap = try syntheticAuthenticatedBootstrap(&context);
    var listing_buffer: [4096]u8 = undefined;
    var tree_buffer: [64]u8 = undefined;
    const observed = try syntheticObservedStagedSource(
        source_bytes,
        &context,
        bootstrap,
        &listing_buffer,
        &tree_buffer,
    );
    const authenticated = try normalizeAuthenticatedStagedSource(
        std.testing.allocator,
        observed,
        bootstrap,
        &context,
    );
    try std.testing.expect(provenance.equalCanonicalSourceSet(
        &authenticated.source_set,
        &context.source_set,
    ));
    var copied = authenticated;
    copied.source_set.entries[0].raw_sha256.bytes[0] ^= 1;
    root_fixture[0] = 'X';
    try std.testing.expect(provenance.equalCanonicalSourceSet(
        &authenticated.source_set,
        &context.source_set,
    ));
    try std.testing.expect(!equalRawIdentity(
        copied.source_set.entries[0].raw_sha256,
        authenticated.source_set.entries[0].raw_sha256,
    ));

    const cross_context_bytes = sourceSetBytes("cross-context owned source");
    const context_value = try syntheticAuthorityContext(cross_context_bytes);
    const contexts = [2]AcceptanceAuthorityContext{ context_value, context_value };
    const context_a = &contexts[0];
    const context_b = &contexts[1];
    const bootstrap_a = try syntheticAuthenticatedBootstrap(context_a);
    var cross_listing_buffer: [4096]u8 = undefined;
    var cross_tree_buffer: [64]u8 = undefined;
    const cross_context = try syntheticObservedStagedSource(
        cross_context_bytes,
        context_a,
        bootstrap_a,
        &cross_listing_buffer,
        &cross_tree_buffer,
    );
    try std.testing.expectError(
        error.AuthorityContextMismatch,
        normalizeAuthenticatedStagedSource(
            std.testing.allocator,
            cross_context,
            bootstrap_a,
            context_b,
        ),
    );
    comptime {
        if (@hasField(AuthenticatedStagedSource, "allocator") or
            @hasField(AuthenticatedStagedSource, "staged_bytes") or
            @hasField(AuthenticatedStagedSource, "worktree_bytes"))
        {
            @compileError("authenticated staged values must contain fixed identities only");
        }
    }
}

test "scoped normalizers free every partial allocation" {
    try std.testing.checkAllAllocationFailures(
        std.testing.allocator,
        processCaptureAllocationHarness,
        .{},
    );
    try std.testing.checkAllAllocationFailures(
        std.testing.allocator,
        stagedCaptureAllocationHarness,
        .{},
    );
    try std.testing.checkAllAllocationFailures(
        std.testing.allocator,
        driverAllocationHarness,
        .{},
    );
}

test "source capture bound rejects before allocation and driver teardown is idempotent" {
    const source_bytes = sourceSetBytes("bounded source");
    const context = try syntheticAuthorityContext(source_bytes);
    const oversized = try std.testing.allocator.alloc(
        u8,
        driver_module.source_capture_max_bytes + 1,
    );
    defer std.testing.allocator.free(oversized);
    const bootstrap = try syntheticAuthenticatedBootstrap(&context);
    var listing_buffer: [4096]u8 = undefined;
    var tree_buffer: [64]u8 = undefined;
    var observed = try syntheticObservedStagedSource(
        source_bytes,
        &context,
        bootstrap,
        &listing_buffer,
        &tree_buffer,
    );
    observed.sources[0].staged_bytes = oversized;
    observed.sources[0].worktree_bytes = oversized;
    try std.testing.expectError(error.SourceCaptureOversized, normalizeAuthenticatedStagedSource(
        std.testing.allocator,
        observed,
        bootstrap,
        &context,
    ));

    var driver = AcceptanceDriver{};
    _ = try advanceSyntheticDriverToPreparedReceipt(
        std.testing.allocator,
        &driver,
        &context,
        source_bytes,
        try validatePublicationTarget("teardown-receipt.tsv"),
    );
    driver.deinit();
    try std.testing.expectEqual(DriverPhase.deinitialized, driver.phase);
    try std.testing.expect(driver.context == null);
    try std.testing.expect(driver.prepared_receipt == null);
    driver.deinit();
    try std.testing.expectEqual(DriverPhase.deinitialized, driver.phase);
}

test "same authority context completes exact prepared and published receipt transition" {
    const source_bytes = sourceSetBytes("synthetic checked-in Zig source bytes");
    const context = try syntheticAuthorityContext(source_bytes);
    const target = try validatePublicationTarget("acceptance-receipt.tsv");
    var driver = AcceptanceDriver{};
    const prepared = try advanceSyntheticDriverToPreparedReceipt(
        std.testing.allocator,
        &driver,
        &context,
        source_bytes,
        target,
    );
    try std.testing.expectEqual(DriverPhase.receipt_ready, driver.phase);
    try std.testing.expect(driver.context.? == &context);
    try std.testing.expect(driver.repository.?.context == &context);
    try std.testing.expect(driver.bootstrap.?.context == &context);
    try std.testing.expect(driver.staged_source.?.context == &context);
    try std.testing.expect(driver.validation_directory.?.context == &context);
    try std.testing.expect(prepared.context == &context);
    try std.testing.expect(try equalPublicationTarget(&prepared.final_target, &target));
    const reencoded = try encodeCanonicalReceipt(&prepared.receipt);
    try std.testing.expectEqualSlices(
        u8,
        try receipt.canonicalReceiptBytesSlice(&reencoded),
        try receipt.canonicalReceiptBytesSlice(&prepared.canonical_bytes),
    );
    var digest: [std.crypto.hash.sha2.Sha256.digest_length]u8 = undefined;
    std.crypto.hash.sha2.Sha256.hash(
        try receipt.canonicalReceiptBytesSlice(&reencoded),
        &digest,
        .{},
    );
    try std.testing.expectEqualSlices(u8, &digest, &prepared.canonical_sha256.bytes);
    try std.testing.expectEqual(@as(u64, reencoded.length), prepared.exact_length);

    var preparation_driver = driver;
    preparation_driver.phase = .validation_directory_authenticated;
    preparation_driver.prepared_receipt = null;
    var malformed_target = target;
    malformed_target.length = 0;
    const before_malformed_preparation = preparation_driver;
    try std.testing.expectError(
        error.PublicationTargetInvalid,
        preparation_driver.prepareReceipt(malformed_target),
    );
    try std.testing.expectEqualDeep(before_malformed_preparation, preparation_driver);
    _ = try preparation_driver.prepareReceipt(target);
    try std.testing.expectEqual(DriverPhase.receipt_ready, preparation_driver.phase);

    const published = try syntheticPublishedReceipt(prepared);
    var driver_copies = [2]AcceptanceDriver{ driver, driver };
    const prepared_copies = [2]PreparedReceipt{ prepared, prepared };
    const rebound_published = try syntheticPublishedReceipt(prepared_copies[1]);
    const published_copies = [2]PublishedReceipt{ published, rebound_published };
    try std.testing.expect(&driver_copies[0] != &driver_copies[1]);
    try std.testing.expect(&prepared_copies[0] != &prepared_copies[1]);
    try std.testing.expect(&published_copies[0] != &published_copies[1]);
    try std.testing.expectEqualDeep(published_copies[0], published_copies[1]);
    try driver_copies[1].acceptPublishedReceipt(published_copies[1]);
    try std.testing.expectEqual(DriverPhase.published, driver_copies[1].phase);
    try std.testing.expectEqual(DriverPhase.receipt_ready, driver_copies[0].phase);
    try std.testing.expectEqual(DriverPhase.receipt_ready, driver.phase);
    try driver.acceptPublishedReceipt(published);
    try std.testing.expectEqual(DriverPhase.published, driver.phase);
    try std.testing.expectEqualDeep(published, driver.published_receipt.?);
    try std.testing.expectEqualSlices(
        u8,
        try receipt.canonicalReceiptBytesSlice(&prepared.canonical_bytes),
        try receipt.canonicalReceiptBytesSlice(&driver.published_receipt.?.canonical_bytes),
    );
}

test "driver authenticated types and phase machine reject shortcuts and reordering" {
    comptime {
        const repository_parameters = @typeInfo(@TypeOf(AcceptanceDriver.acceptRepository)).@"fn".param_types;
        if (repository_parameters[1].? != AuthenticatedRepositoryScope) {
            @compileError("repository phase must require authenticated input");
        }
        const staged_parameters = @typeInfo(@TypeOf(AcceptanceDriver.acceptStagedSource)).@"fn".param_types;
        if (staged_parameters[1].? != AuthenticatedStagedSource) {
            @compileError("staged-source phase must require authenticated input");
        }
        const validation_parameters = @typeInfo(@TypeOf(AcceptanceDriver.acceptValidationDirectory)).@"fn".param_types;
        if (validation_parameters[1].? != AuthenticatedValidationDirectory) {
            @compileError("validation phase must require authenticated input");
        }
        const publication_parameters = @typeInfo(@TypeOf(AcceptanceDriver.acceptPublishedReceipt)).@"fn".param_types;
        if (publication_parameters[1].? != PublishedReceipt) {
            @compileError("publication phase must require a bound published receipt");
        }
    }

    const source_bytes = sourceSetBytes("phase-order source");
    const context = try syntheticAuthorityContext(source_bytes);
    const bootstrap = try syntheticAuthenticatedBootstrap(&context);
    const repository = try syntheticAuthenticatedRepository(&context);
    const format_result = try syntheticAuthenticatedProcess(
        std.testing.allocator,
        .zig_format_check,
        "",
        bootstrap,
        &context,
    );
    const validation_directory = try syntheticAuthenticatedValidationDirectory(&context);

    var driver = AcceptanceDriver{};
    try std.testing.expectError(error.DriverPhaseViolation, driver.acceptBootstrap(bootstrap));
    try std.testing.expectError(error.DriverPhaseViolation, driver.acceptFormatResult(format_result));
    try std.testing.expectError(error.DriverPhaseViolation, driver.acceptFormatResult(format_result));
    try std.testing.expectEqual(DriverPhase.initialized, driver.phase);
    try std.testing.expectError(
        error.DriverPhaseViolation,
        driver.acceptValidationDirectory(validation_directory),
    );
    try std.testing.expectError(
        error.DriverPhaseViolation,
        driver.prepareReceipt(try validatePublicationTarget("receipt.tsv")),
    );
    try std.testing.expectError(
        error.DriverPhaseViolation,
        driver.acceptPublishedReceipt(undefined),
    );
    try driver.acceptRepository(repository);
    try std.testing.expectError(error.DriverPhaseViolation, driver.acceptRepository(repository));
}

test "structurally identical contexts remain distinct immutable cohorts" {
    const source_bytes = sourceSetBytes("authority substitution source");
    const context_value = try syntheticAuthorityContext(source_bytes);
    const contexts = [2]AcceptanceAuthorityContext{ context_value, context_value };
    const context_a = &contexts[0];
    const context_b = &contexts[1];
    try std.testing.expect(context_a != context_b);

    try std.testing.expectError(
        error.RepositoryDescriptorMismatch,
        authenticateValidatedRepositoryScope(
            validateObservedRepositoryScope(.{
                .descriptor_identity = syntheticDescriptorIdentity(999),
            }),
            context_a,
        ),
    );
    try std.testing.expectError(
        error.ValidationDescriptorMismatch,
        authenticateValidatedValidationDirectory(
            validateObservedValidationDirectory(.{
                .descriptor_identity = syntheticDescriptorIdentity(998),
            }),
            context_a,
        ),
    );

    var wrong_launch = ObservedBootstrap{
        .driver_launch_identity = .{ .bytes = fixedIdentity(32, 0x01) },
        .zig_executable_identity = context_a.zig_executable_identity,
        .git_executable_identity = context_a.git_executable_identity,
        .zig_toolchain_identity = context_a.zig_toolchain_identity,
    };
    try std.testing.expectError(
        error.DriverLaunchMismatch,
        authenticateValidatedBootstrap(
            try validateObservedBootstrap(wrong_launch),
            context_a,
        ),
    );
    wrong_launch.driver_launch_identity = context_a.driver_launch_identity;
    wrong_launch.zig_toolchain_identity = try canonicalReceiptToken("zig-0.17.0-other");
    try std.testing.expectError(
        error.ToolchainMismatch,
        authenticateValidatedBootstrap(
            try validateObservedBootstrap(wrong_launch),
            context_a,
        ),
    );

    const bootstrap_a = try syntheticAuthenticatedBootstrap(context_a);
    const bootstrap_b = try syntheticAuthenticatedBootstrap(context_b);
    const substituted_observed = ObservedProcessResult{
        .specification_id = .zig_format_check,
        .executable_identity = .{ .bytes = fixedIdentity(32, 0x02) },
        .stdout = "",
        .stderr = "",
    };
    try std.testing.expectError(
        error.ProcessExecutableMismatch,
        normalizeAuthenticatedProcessResult(
            std.testing.allocator,
            substituted_observed,
            .zig_format_check,
            bootstrap_a,
            context_a,
        ),
    );
    const valid_observed = syntheticObservedProcess(
        .zig_format_check,
        context_a.zig_executable_identity,
        "",
    );
    try std.testing.expectError(
        error.AuthorityContextMismatch,
        normalizeAuthenticatedProcessResult(
            std.testing.allocator,
            valid_observed,
            .zig_format_check,
            bootstrap_b,
            context_a,
        ),
    );
}

test "bootstrap receipt-token bounds fail closed before driver mutation" {
    const source_bytes = sourceSetBytes("bootstrap token bounds source");
    const context = try syntheticAuthorityContext(source_bytes);
    const valid_observed = ObservedBootstrap{
        .driver_launch_identity = context.driver_launch_identity,
        .zig_executable_identity = context.zig_executable_identity,
        .git_executable_identity = context.git_executable_identity,
        .zig_toolchain_identity = context.zig_toolchain_identity,
    };

    var malformed_observed = valid_observed;
    malformed_observed.zig_toolchain_identity.length = 0;
    try std.testing.expectError(
        error.ReceiptIdentityMalformed,
        validateObservedBootstrap(malformed_observed),
    );
    malformed_observed = valid_observed;
    malformed_observed.zig_toolchain_identity.length =
        @intCast(receipt.receipt_toolchain_identity_max + 1);
    try std.testing.expectError(
        error.ReceiptIdentityMalformed,
        validateObservedBootstrap(malformed_observed),
    );
    malformed_observed = valid_observed;
    malformed_observed.zig_toolchain_identity.length = std.math.maxInt(u8);
    try std.testing.expectError(
        error.ReceiptIdentityMalformed,
        validateObservedBootstrap(malformed_observed),
    );
    malformed_observed = valid_observed;
    const used_length: usize = malformed_observed.zig_toolchain_identity.length;
    malformed_observed.zig_toolchain_identity.bytes[used_length] = 1;
    try std.testing.expectError(
        error.ReceiptIdentityMalformed,
        validateObservedBootstrap(malformed_observed),
    );

    const exact_token_input: [receipt.receipt_toolchain_identity_max]u8 = @splat('a');
    malformed_observed = valid_observed;
    malformed_observed.zig_toolchain_identity = try canonicalReceiptToken(&exact_token_input);
    _ = try validateObservedBootstrap(malformed_observed);

    var driver = AcceptanceDriver{};
    try driver.acceptRepository(try syntheticAuthenticatedRepository(&context));
    const before = driver;
    const valid_bootstrap = try syntheticAuthenticatedBootstrap(&context);
    var malformed_bootstrap = valid_bootstrap;
    malformed_bootstrap.zig_toolchain_identity.length = 0;
    try std.testing.expectError(
        error.ReceiptIdentityMalformed,
        driver.acceptBootstrap(malformed_bootstrap),
    );
    try std.testing.expectEqualDeep(before, driver);
    malformed_bootstrap = valid_bootstrap;
    malformed_bootstrap.zig_toolchain_identity.bytes[used_length] = 1;
    try std.testing.expectError(
        error.ReceiptIdentityMalformed,
        driver.acceptBootstrap(malformed_bootstrap),
    );
    try std.testing.expectEqualDeep(before, driver);
    try driver.acceptBootstrap(valid_bootstrap);
    try std.testing.expectEqual(DriverPhase.bootstrap_authenticated, driver.phase);
}

test "fixed process results reject drift nonzero signals truncation and unbounded output" {
    const context = try syntheticAuthorityContext(sourceSetBytes("process source"));
    const bootstrap = try syntheticAuthenticatedBootstrap(&context);
    const exact = syntheticObservedProcess(
        .git_object_format,
        bootstrap.git_executable_identity,
        "sha1\n",
    );
    try std.testing.expectError(
        error.ProcessSpecificationMismatch,
        normalizeAuthenticatedProcessResult(
            std.testing.allocator,
            exact,
            .git_staged_tree,
            bootstrap,
            &context,
        ),
    );

    var changed = syntheticObservedProcess(
        .git_object_format,
        bootstrap.git_executable_identity,
        "sha1\n",
    );
    changed.termination = .{ .exited = 1 };
    try std.testing.expectError(
        error.ProcessExitedNonzero,
        normalizeAuthenticatedProcessResult(std.testing.allocator, changed, .git_object_format, bootstrap, &context),
    );
    changed = syntheticObservedProcess(
        .git_object_format,
        bootstrap.git_executable_identity,
        "sha1\n",
    );
    changed.termination = .{ .signaled = 9 };
    try std.testing.expectError(
        error.ProcessSignaled,
        normalizeAuthenticatedProcessResult(std.testing.allocator, changed, .git_object_format, bootstrap, &context),
    );
    changed = syntheticObservedProcess(
        .git_object_format,
        bootstrap.git_executable_identity,
        "sha1\n",
    );
    changed.stdout_truncated = true;
    try std.testing.expectError(
        error.ProcessOutputTruncated,
        normalizeAuthenticatedProcessResult(std.testing.allocator, changed, .git_object_format, bootstrap, &context),
    );
    changed = syntheticObservedProcess(
        .git_object_format,
        bootstrap.git_executable_identity,
        "sha1\n",
    );
    changed.stderr_truncated = true;
    try std.testing.expectError(
        error.ProcessOutputTruncated,
        normalizeAuthenticatedProcessResult(std.testing.allocator, changed, .git_object_format, bootstrap, &context),
    );
    try std.testing.expectError(
        error.ProcessOutputUnbounded,
        normalizeAuthenticatedProcessResult(
            std.testing.allocator,
            .{
                .specification_id = .git_object_format,
                .executable_identity = bootstrap.git_executable_identity,
                .stdout = "0123456789abcdefx",
                .stderr = "",
            },
            .git_object_format,
            bootstrap,
            &context,
        ),
    );
    try std.testing.expectError(
        error.ProcessOutputUnbounded,
        normalizeAuthenticatedProcessResult(
            std.testing.allocator,
            .{
                .specification_id = .git_object_format,
                .executable_identity = bootstrap.git_executable_identity,
                .stdout = "",
                .stderr = &@as([4097]u8, @splat('x')),
            },
            .git_object_format,
            bootstrap,
            &context,
        ),
    );

    for (driver_process_specs, 0..) |specification, index| {
        try std.testing.expectEqual(@as(usize, @intFromEnum(specification.id)), index);
        try std.testing.expect(std.fs.path.isAbsolute(specification.executable));
        try std.testing.expectEqualStrings(specification.executable, specification.argv[0]);
        try std.testing.expect(specification.environment.len > 0);
        try std.testing.expectEqual(
            driver_module.ProcessEnvironmentMode.closed_allowlist,
            specification.environment_mode,
        );
    }
    try std.testing.expectEqual(@as(usize, 14), git_staged_listing_argv.len);
    try std.testing.expectEqualStrings("-c", git_staged_listing_argv[3]);
    try std.testing.expectEqualStrings("core.fsmonitor=false", git_staged_listing_argv[4]);
    try std.testing.expectEqualStrings("-c", git_staged_listing_argv[5]);
    try std.testing.expectEqualStrings("core.untrackedCache=false", git_staged_listing_argv[6]);
    try std.testing.expectEqualStrings("status", git_staged_listing_argv[7]);
    try std.testing.expectEqualStrings("--porcelain=v2", git_staged_listing_argv[8]);
    try std.testing.expectEqualStrings("-z", git_staged_listing_argv[9]);
    try std.testing.expectEqualStrings("--untracked-files=all", git_staged_listing_argv[10]);
    try std.testing.expectEqualStrings("--no-ahead-behind", git_staged_listing_argv[11]);
    try std.testing.expectEqualStrings("--ignore-submodules=none", git_staged_listing_argv[12]);
    try std.testing.expectEqualStrings("--no-renames", git_staged_listing_argv[13]);
    const expected_git_environment = [_][]const u8{
        "LC_ALL=C",
        "GIT_CONFIG_NOSYSTEM=1",
        "GIT_CONFIG_GLOBAL=/dev/null",
        "GIT_CONFIG_COUNT=0",
        "GIT_OPTIONAL_LOCKS=0",
        "GIT_TERMINAL_PROMPT=0",
        "GIT_PAGER=cat",
        "PAGER=cat",
    };
    try std.testing.expectEqual(expected_git_environment.len, git_environment.len);
    for (expected_git_environment, git_environment) |expected, actual| {
        try std.testing.expectEqualStrings(expected, actual);
    }
    for (git_environment) |entry| {
        try std.testing.expect(!std.mem.startsWith(u8, entry, "GIT_DIR="));
        try std.testing.expect(!std.mem.startsWith(u8, entry, "GIT_WORK_TREE="));
        try std.testing.expect(!std.mem.startsWith(u8, entry, "GIT_INDEX_FILE="));
    }
    try std.testing.expectEqual(@as(usize, 3 + capability_source_count), zig_format_argv.len);
    for (provenance.capability_source_paths, 0..) |path, index| {
        try std.testing.expectEqualStrings(path, zig_format_argv[3 + index]);
    }
}

test "private process authority surface is absent and normalized scenarios remain green" {
    comptime {
        const forbidden = [_][]const u8{
            "SyntheticExpectedExecutableFacts",
            "SyntheticObservedExecutableFacts",
            "SyntheticExpectedExecutableCapability",
            "SyntheticObservedExecutableCapability",
            "SyntheticExpectedSupplierVariant",
            "SyntheticObservationSupplierVariant",
            "admitSyntheticExecutableToken",
            "AuthenticatedExecutableToken",
            "syntheticAuthenticatedExecutableToken",
            "syntheticForgedExecutableTokenForTest",
            "syntheticExpectedExecutableCapabilityForTest",
            "syntheticObservedExecutableCapabilityForTest",
            "syntheticExecutableCapabilitiesShareClaimsForTest",
            "SyntheticWorkingDirectoryAuthority",
            "SyntheticClosedEnvironment",
            "SyntheticNativeProcessRequest",
            "SyntheticNativeProcessFixture",
            "SyntheticProcessReadEvent",
            "syntheticNativeProcessRequest",
            "runInjectedSyntheticNativeProcess",
        };
        for (forbidden) |name| {
            if (@hasDecl(driver_module, name)) {
                @compileError("private executable authority leaked through module exports");
            }
        }
    }

    const cases = [_]struct {
        id: test_support.ScenarioId,
        result: test_support.Result,
        launches: u8,
        waits: u8,
        lifecycle: test_support.Lifecycle,
    }{
        .{ .id = .success, .result = .success, .launches = 1, .waits = 1, .lifecycle = .confirmed_reaped },
        .{ .id = .matching_facts_forgery, .result = .authority_unavailable, .launches = 0, .waits = 0, .lifecycle = .not_launched },
        .{ .id = .context_mismatch, .result = .context_mismatch, .launches = 0, .waits = 0, .lifecycle = .not_launched },
        .{ .id = .specification_mismatch, .result = .specification_mismatch, .launches = 0, .waits = 0, .lifecycle = .not_launched },
        .{ .id = .fixture_reuse, .result = .fixture_consumed, .launches = 1, .waits = 1, .lifecycle = .confirmed_reaped },
        .{ .id = .launch_failure, .result = .launch_failure, .launches = 1, .waits = 0, .lifecycle = .not_launched },
        .{ .id = .stdout_allocation_failure, .result = .out_of_memory, .launches = 1, .waits = 1, .lifecycle = .confirmed_reaped },
        .{ .id = .stderr_allocation_failure, .result = .out_of_memory, .launches = 1, .waits = 1, .lifecycle = .confirmed_reaped },
        .{ .id = .read_failure, .result = .read_failure, .launches = 1, .waits = 1, .lifecycle = .confirmed_reaped },
        .{ .id = .output_unbounded, .result = .output_unbounded, .launches = 1, .waits = 1, .lifecycle = .confirmed_reaped },
        .{ .id = .output_truncated, .result = .output_truncated, .launches = 1, .waits = 1, .lifecycle = .confirmed_reaped },
        .{ .id = .incomplete_eof, .result = .output_incomplete, .launches = 1, .waits = 1, .lifecycle = .confirmed_reaped },
        .{ .id = .wait_failure, .result = .wait_failure, .launches = 1, .waits = 1, .lifecycle = .wait_failed_disposition_unknown },
        .{ .id = .wait_failure_over_read, .result = .wait_failure, .launches = 1, .waits = 1, .lifecycle = .wait_failed_disposition_unknown },
        .{ .id = .nonzero_exit, .result = .nonzero_exit, .launches = 1, .waits = 1, .lifecycle = .confirmed_reaped },
        .{ .id = .signal, .result = .signal, .launches = 1, .waits = 1, .lifecycle = .confirmed_reaped },
        .{ .id = .stop, .result = .stop, .launches = 1, .waits = 1, .lifecycle = .confirmed_reaped },
        .{ .id = .unknown_termination, .result = .unknown_termination, .launches = 1, .waits = 1, .lifecycle = .confirmed_reaped },
    };
    for (cases) |case| {
        const outcome = try test_support.run(case.id);
        try std.testing.expectEqual(case.result, outcome.result);
        try std.testing.expectEqual(case.launches, outcome.launch_attempts);
        try std.testing.expectEqual(case.waits, outcome.wait_attempts);
        try std.testing.expectEqual(case.lifecycle, outcome.lifecycle);
        try std.testing.expect(outcome.driver_unchanged);
        try std.testing.expect(outcome.authority_unchanged);
    }
}

test "Path-B static contract and synthetic receipt reject deterministic drift" {
    const cases = [_]struct {
        id: path_b_test_support.ScenarioId,
        expected: path_b_test_support.Result,
    }{
        .{ .id = .exact, .expected = .accepted },
        .{ .id = .wrong_command, .expected = .fixed_input_rejected },
        .{ .id = .wrong_environment, .expected = .fixed_input_rejected },
        .{ .id = .wrong_cwd, .expected = .fixed_input_rejected },
        .{ .id = .corrupt_receipt, .expected = .receipt_rejected },
        .{ .id = .trailing_receipt, .expected = .receipt_rejected },
    };
    for (cases) |case| {
        try std.testing.expectEqual(case.expected, try path_b_test_support.run(case.id));
    }
}

test "staged source set rejects incomplete unsafe or mismatched evidence" {
    const source_bytes = sourceSetBytes("staged source bytes");
    const context = try syntheticAuthorityContext(source_bytes);
    const bootstrap = try syntheticAuthenticatedBootstrap(&context);
    var listing_buffer: [4096]u8 = undefined;
    var tree_buffer: [64]u8 = undefined;
    var changed = try syntheticObservedStagedSource(
        source_bytes,
        &context,
        bootstrap,
        &listing_buffer,
        &tree_buffer,
    );
    changed.object_format.stdout = "xha1\n";
    try std.testing.expectError(
        error.GitObjectAlgorithmUnsupported,
        normalizeAuthenticatedStagedSource(std.testing.allocator, changed, bootstrap, &context),
    );
    listing_buffer = undefined;
    tree_buffer = undefined;
    changed = try syntheticObservedStagedSource(
        source_bytes,
        &context,
        bootstrap,
        &listing_buffer,
        &tree_buffer,
    );
    changed.sources[2].worktree_bytes = "different source bytes";
    try std.testing.expectError(
        error.SourceBytesMismatch,
        normalizeAuthenticatedStagedSource(std.testing.allocator, changed, bootstrap, &context),
    );
    listing_buffer = undefined;
    tree_buffer = undefined;
    changed = try syntheticObservedStagedSource(
        source_bytes,
        &context,
        bootstrap,
        &listing_buffer,
        &tree_buffer,
    );
    changed.sources[2].staged_bytes = "wrong length";
    changed.sources[2].worktree_bytes = "wrong length";
    try std.testing.expectError(
        error.SourceLengthMismatch,
        normalizeAuthenticatedStagedSource(std.testing.allocator, changed, bootstrap, &context),
    );
    var other_context = context;
    listing_buffer = undefined;
    tree_buffer = undefined;
    changed = try syntheticObservedStagedSource(
        source_bytes,
        &context,
        bootstrap,
        &listing_buffer,
        &tree_buffer,
    );
    changed.sources[1].context = &other_context;
    try std.testing.expectError(
        error.AuthorityContextMismatch,
        normalizeAuthenticatedStagedSource(std.testing.allocator, changed, bootstrap, &context),
    );
    listing_buffer = undefined;
    tree_buffer = undefined;
    changed = try syntheticObservedStagedSource(
        source_bytes,
        &context,
        bootstrap,
        &listing_buffer,
        &tree_buffer,
    );
    changed.staged_tree.stdout = "not-a-tree\n";
    try std.testing.expectError(
        error.GitOutputMalformed,
        normalizeAuthenticatedStagedSource(std.testing.allocator, changed, bootstrap, &context),
    );

    const faults = [_]struct { SyntheticStagedListingFault, DriverError }{
        .{ .missing, error.MissingStagedPath },
        .{ .extra, error.ExtraStagedPath },
        .{ .duplicate, error.DuplicateStagedPath },
        .{ .reordered, error.StagedOrderMismatch },
        .{ .deleted, error.StagedStatusMismatch },
        .{ .renamed, error.StagedRecordTypeUnsupported },
        .{ .copied, error.StagedRecordTypeUnsupported },
        .{ .unmerged, error.StagedRecordTypeUnsupported },
        .{ .untracked, error.StagedRecordTypeUnsupported },
        .{ .unsupported_type, error.StagedRecordTypeUnsupported },
        .{ .intent_to_add, error.StagedStageMismatch },
        .{ .wrong_mode, error.StagedModeMismatch },
        .{ .type_change, error.StagedModeMismatch },
        .{ .malformed, error.GitOutputMalformed },
        .{ .trailing, error.StagedRecordTrailing },
    };
    for (faults) |fault| {
        var fault_buffer: [4096]u8 = undefined;
        const fault_listing = try syntheticStagedListingWithFault(
            &context,
            &fault_buffer,
            fault[0],
        );
        try std.testing.expectError(fault[1], parseStagedListing(fault_listing));
    }
    var wrong_blob_buffer: [4096]u8 = undefined;
    const wrong_blob_listing = try syntheticStagedListingWithFault(
        &context,
        &wrong_blob_buffer,
        .wrong_blob,
    );
    listing_buffer = undefined;
    tree_buffer = undefined;
    changed = try syntheticObservedStagedSource(
        source_bytes,
        &context,
        bootstrap,
        &listing_buffer,
        &tree_buffer,
    );
    changed.staged_listing.stdout = wrong_blob_listing;
    try std.testing.expectError(
        error.StagedBlobMismatch,
        normalizeAuthenticatedStagedSource(std.testing.allocator, changed, bootstrap, &context),
    );

    listing_buffer = undefined;
    tree_buffer = undefined;
    const exact = try syntheticObservedStagedSource(
        source_bytes,
        &context,
        bootstrap,
        &listing_buffer,
        &tree_buffer,
    );
    const authenticated = try normalizeAuthenticatedStagedSource(
        std.testing.allocator,
        exact,
        bootstrap,
        &context,
    );
    const validated = ValidatedStagedSource{
        .context = &context,
        .source_set = authenticated.source_set,
        .tree_identity = authenticated.tree_identity,
    };
    var wrong_context = context;
    wrong_context.source_set.entries[0].path = try canonicalRepositoryPath("tools/other.zig");
    var validated_wrong = validated;
    validated_wrong.context = &wrong_context;
    try std.testing.expectError(
        error.StagedPathMismatch,
        authenticateValidatedStagedSource(validated_wrong, &wrong_context),
    );
    wrong_context = context;
    wrong_context.source_set.entries[0].raw_sha256 = .{ .bytes = fixedIdentity(32, 0x11) };
    validated_wrong.context = &wrong_context;
    try std.testing.expectError(
        error.SourceDigestMismatch,
        authenticateValidatedStagedSource(validated_wrong, &wrong_context),
    );
    wrong_context = context;
    wrong_context.source_set.entries[0].git_blob_identity = .{ .bytes = fixedIdentity(20, 0x12) };
    validated_wrong.context = &wrong_context;
    try std.testing.expectError(
        error.StagedBlobMismatch,
        authenticateValidatedStagedSource(validated_wrong, &wrong_context),
    );
    wrong_context = context;
    wrong_context.tree_identity = .{ .bytes = fixedIdentity(20, 0x13) };
    validated_wrong.context = &wrong_context;
    try std.testing.expectError(
        error.StagedTreeMismatch,
        authenticateValidatedStagedSource(validated_wrong, &wrong_context),
    );
}

test "every source-set identity field is independently authority bound" {
    const source_bytes = sourceSetBytes("every identity field source");
    const context = try syntheticAuthorityContext(source_bytes);
    const bootstrap = try syntheticAuthenticatedBootstrap(&context);
    const authenticated = try syntheticAuthenticatedStagedSource(
        std.testing.allocator,
        source_bytes,
        &context,
        bootstrap,
    );
    const validated = ValidatedStagedSource{
        .context = &context,
        .source_set = authenticated.source_set,
        .tree_identity = authenticated.tree_identity,
    };

    for (0..capability_source_count) |index| {
        var wrong = context;
        var path_buffer: [64]u8 = undefined;
        const path = try std.fmt.bufPrint(&path_buffer, "tools/wrong-{d}.zig", .{index});
        wrong.source_set.entries[index].path = try canonicalRepositoryPath(path);
        var candidate = validated;
        candidate.context = &wrong;
        try std.testing.expectError(
            error.StagedPathMismatch,
            authenticateValidatedStagedSource(candidate, &wrong),
        );

        wrong = context;
        wrong.source_set.entries[index].mode = 0o100755;
        candidate.context = &wrong;
        try std.testing.expectError(
            error.StagedModeMismatch,
            authenticateValidatedStagedSource(candidate, &wrong),
        );

        wrong = context;
        wrong.source_set.entries[index].git_blob_identity.bytes[0] ^= 1;
        candidate.context = &wrong;
        try std.testing.expectError(
            error.StagedBlobMismatch,
            authenticateValidatedStagedSource(candidate, &wrong),
        );

        wrong = context;
        wrong.source_set.entries[index].raw_sha256.bytes[0] ^= 1;
        candidate.context = &wrong;
        try std.testing.expectError(
            error.SourceDigestMismatch,
            authenticateValidatedStagedSource(candidate, &wrong),
        );

        wrong = context;
        wrong.source_set.entries[index].exact_length += 1;
        candidate.context = &wrong;
        try std.testing.expectError(
            error.SourceLengthMismatch,
            authenticateValidatedStagedSource(candidate, &wrong),
        );
    }
}

test "semantic gates remain individually authenticated and reject aggregate shortcuts" {
    const context = try syntheticAuthorityContext(sourceSetBytes("semantic source"));
    try std.testing.expectError(error.SemanticGateFailed, gateCanonicalTupleAdmission(&context, false));
    try std.testing.expectError(error.SemanticGateFailed, gateSyntheticAuthorityBinding(&context, false));
    try std.testing.expectError(error.SemanticGateFailed, gatePreDescriptorRejection(&context, false));
    try std.testing.expectError(error.SemanticGateFailed, gatePostSealLengthSha(&context, false));
    try std.testing.expectError(error.SemanticGateFailed, gateFreshOwnedReplay(&context, false));
    try std.testing.expectError(error.SemanticGateFailed, gateConsumedHandoffRejection(&context, false));
    try std.testing.expectError(error.SemanticGateFailed, gateOwnershipExactlyOnceClose(&context, false));
    try std.testing.expectError(error.SemanticGateMissing, collectSemanticGateBits(&context, &.{}));

    const gates = try syntheticSemanticGates(&context);
    try std.testing.expectError(error.SemanticGateMissing, collectSemanticGateBits(&context, gates[0..6]));
    const duplicate = [_]AuthenticatedSemanticGate{ gates[0], gates[0] };
    try std.testing.expectError(error.SemanticGateDuplicate, collectSemanticGateBits(&context, &duplicate));
    try std.testing.expectEqual(receipt_required_semantic_bits, try collectSemanticGateBits(&context, &gates));
}

test "cross-context phase inputs leave driver state unchanged" {
    const source_bytes = sourceSetBytes("cross-context phase source");
    const context_value = try syntheticAuthorityContext(source_bytes);
    const contexts = [2]AcceptanceAuthorityContext{ context_value, context_value };
    const context_a = &contexts[0];
    const context_b = &contexts[1];
    const repository_a = try syntheticAuthenticatedRepository(context_a);
    const repository_b = try syntheticAuthenticatedRepository(context_b);
    const bootstrap_a = try syntheticAuthenticatedBootstrap(context_a);
    const bootstrap_b = try syntheticAuthenticatedBootstrap(context_b);
    const staged_a = try syntheticAuthenticatedStagedSource(
        std.testing.allocator,
        source_bytes,
        context_a,
        bootstrap_a,
    );
    const staged_b = try syntheticAuthenticatedStagedSource(
        std.testing.allocator,
        source_bytes,
        context_b,
        bootstrap_b,
    );
    const format_a = try syntheticAuthenticatedProcess(
        std.testing.allocator,
        .zig_format_check,
        "",
        bootstrap_a,
        context_a,
    );
    const format_b = try syntheticAuthenticatedProcess(
        std.testing.allocator,
        .zig_format_check,
        "",
        bootstrap_b,
        context_b,
    );
    const focused_a = try syntheticAuthenticatedProcess(
        std.testing.allocator,
        .zig_focused_test,
        "",
        bootstrap_a,
        context_a,
    );
    const focused_b = try syntheticAuthenticatedProcess(
        std.testing.allocator,
        .zig_focused_test,
        "",
        bootstrap_b,
        context_b,
    );
    const gates_a = try syntheticSemanticGates(context_a);
    const gates_b = try syntheticSemanticGates(context_b);
    const validation_a = try syntheticAuthenticatedValidationDirectory(context_a);
    const validation_b = try syntheticAuthenticatedValidationDirectory(context_b);

    var driver = AcceptanceDriver{};
    try driver.acceptRepository(repository_a);
    var before = driver;
    try std.testing.expectError(error.DriverPhaseViolation, driver.acceptRepository(repository_b));
    try std.testing.expectEqualDeep(before, driver);
    try std.testing.expectError(error.AuthorityContextMismatch, driver.acceptBootstrap(bootstrap_b));
    try std.testing.expectEqualDeep(before, driver);
    try driver.acceptBootstrap(bootstrap_a);
    before = driver;
    try std.testing.expectError(error.AuthorityContextMismatch, driver.acceptStagedSource(staged_b));
    try std.testing.expectEqualDeep(before, driver);
    try driver.acceptStagedSource(staged_a);
    before = driver;
    try std.testing.expectError(error.AuthorityContextMismatch, driver.acceptFormatResult(format_b));
    try std.testing.expectEqualDeep(before, driver);
    var wrong_format = try syntheticAuthenticatedProcess(
        std.testing.allocator,
        .zig_format_check,
        "",
        bootstrap_a,
        context_a,
    );
    wrong_format.specification_id = .zig_focused_test;
    try std.testing.expectError(error.ProcessSpecificationMismatch, driver.acceptFormatResult(wrong_format));
    try std.testing.expectEqualDeep(before, driver);
    wrong_format = try syntheticAuthenticatedProcess(
        std.testing.allocator,
        .zig_format_check,
        "",
        bootstrap_a,
        context_a,
    );
    wrong_format.bootstrap.zig_executable_identity = .{ .bytes = fixedIdentity(32, 0x31) };
    try std.testing.expectError(error.ToolchainMismatch, driver.acceptFormatResult(wrong_format));
    try std.testing.expectEqualDeep(before, driver);
    try driver.acceptFormatResult(format_a);
    before = driver;
    try std.testing.expectError(error.AuthorityContextMismatch, driver.acceptFocusedTestResult(focused_b));
    try std.testing.expectEqualDeep(before, driver);
    try driver.acceptFocusedTestResult(focused_a);
    before = driver;
    try std.testing.expectError(error.AuthorityContextMismatch, driver.acceptSemanticGates(&gates_b));
    try std.testing.expectEqualDeep(before, driver);
    try driver.acceptSemanticGates(&gates_a);
    before = driver;
    try std.testing.expectError(
        error.AuthorityContextMismatch,
        driver.acceptValidationDirectory(validation_b),
    );
    try std.testing.expectEqualDeep(before, driver);
    try driver.acceptValidationDirectory(validation_a);
}

test "prepared publication rejects every binding mismatch without state mutation" {
    const source_bytes = sourceSetBytes("publication-binding source");
    const context_value = try syntheticAuthorityContext(source_bytes);
    const contexts = [2]AcceptanceAuthorityContext{ context_value, context_value };
    const context_a = &contexts[0];
    const context_b = &contexts[1];
    const target_a = try validatePublicationTarget("receipt-a.tsv");
    const target_b = try validatePublicationTarget("receipt-b.tsv");
    var driver_a = AcceptanceDriver{};
    const prepared_a = try advanceSyntheticDriverToPreparedReceipt(
        std.testing.allocator,
        &driver_a,
        context_a,
        source_bytes,
        target_a,
    );
    const exact = try syntheticPublishedReceipt(prepared_a);
    const before = driver_a;

    var changed = exact;
    changed.context = context_b;
    try std.testing.expectError(error.PublicationContextMismatch, driver_a.acceptPublishedReceipt(changed));
    try std.testing.expectEqualDeep(before, driver_a);
    changed = exact;
    changed.validation_directory = .{
        .context = context_a,
        .descriptor_identity = syntheticDescriptorIdentity(900),
    };
    try std.testing.expectError(error.PublicationDirectoryMismatch, driver_a.acceptPublishedReceipt(changed));
    try std.testing.expectEqualDeep(before, driver_a);
    changed = exact;
    changed.final_target = target_b;
    try std.testing.expectError(error.PublicationTargetMismatch, driver_a.acceptPublishedReceipt(changed));
    try std.testing.expectEqualDeep(before, driver_a);
    changed = exact;
    changed.receipt.staged_tree_identity.bytes[0] ^= 1;
    try std.testing.expectError(error.PublicationPreparedMismatch, driver_a.acceptPublishedReceipt(changed));
    try std.testing.expectEqualDeep(before, driver_a);
    changed = exact;
    changed.publication_identity.final_sha256 = .{ .bytes = fixedIdentity(32, 0x41) };
    try std.testing.expectError(error.PublicationDigestMismatch, driver_a.acceptPublishedReceipt(changed));
    try std.testing.expectEqualDeep(before, driver_a);
    changed = exact;
    changed.canonical_sha256 = .{ .bytes = fixedIdentity(32, 0x42) };
    try std.testing.expectError(error.PublicationDigestMismatch, driver_a.acceptPublishedReceipt(changed));
    try std.testing.expectEqualDeep(before, driver_a);
    changed = exact;
    changed.publication_identity.exact_length += 1;
    try std.testing.expectError(error.PublicationLengthMismatch, driver_a.acceptPublishedReceipt(changed));
    try std.testing.expectEqualDeep(before, driver_a);
    changed = exact;
    changed.publication_identity.exact_length = 0;
    try std.testing.expectError(error.PublicationLengthMismatch, driver_a.acceptPublishedReceipt(changed));
    try std.testing.expectEqualDeep(before, driver_a);
    changed = exact;
    changed.publication_identity.completion_status = .incomplete;
    try std.testing.expectError(error.PublicationIncomplete, driver_a.acceptPublishedReceipt(changed));
    try std.testing.expectEqualDeep(before, driver_a);
    changed = exact;
    changed.canonical_bytes.bytes[0] ^= 1;
    try std.testing.expectError(error.PublicationBytesMismatch, driver_a.acceptPublishedReceipt(changed));
    try std.testing.expectEqualDeep(before, driver_a);
    changed = exact;
    changed.canonical_bytes.bytes[changed.canonical_bytes.length] = 1;
    try std.testing.expectError(error.PublicationBytesMismatch, driver_a.acceptPublishedReceipt(changed));
    try std.testing.expectEqualDeep(before, driver_a);
    changed = exact;
    changed.canonical_bytes.length = 0;
    try std.testing.expectError(error.PublicationLengthMismatch, driver_a.acceptPublishedReceipt(changed));
    try std.testing.expectEqualDeep(before, driver_a);
    changed = exact;
    changed.canonical_bytes.length = @intCast(receipt.receipt_max_bytes + 1);
    try std.testing.expectError(error.PublicationLengthMismatch, driver_a.acceptPublishedReceipt(changed));
    try std.testing.expectEqualDeep(before, driver_a);
    changed = exact;
    changed.canonical_bytes.length = std.math.maxInt(u16);
    try std.testing.expectError(error.PublicationLengthMismatch, driver_a.acceptPublishedReceipt(changed));
    try std.testing.expectEqualDeep(before, driver_a);
    changed = exact;
    changed.final_target.length = 0;
    try std.testing.expectError(error.PublicationTargetInvalid, driver_a.acceptPublishedReceipt(changed));
    try std.testing.expectEqualDeep(before, driver_a);
    changed = exact;
    changed.final_target.length = @intCast(receipt.publication_target_max + 1);
    try std.testing.expectError(error.PublicationTargetInvalid, driver_a.acceptPublishedReceipt(changed));
    try std.testing.expectEqualDeep(before, driver_a);
    changed = exact;
    changed.final_target.length = std.math.maxInt(u8);
    try std.testing.expectError(error.PublicationTargetInvalid, driver_a.acceptPublishedReceipt(changed));
    try std.testing.expectEqualDeep(before, driver_a);
    changed = exact;
    changed.final_target.bytes[changed.final_target.length] = 1;
    try std.testing.expectError(error.PublicationTargetInvalid, driver_a.acceptPublishedReceipt(changed));
    try std.testing.expectEqualDeep(before, driver_a);
    changed = exact;
    changed.receipt.zig_toolchain_identity.length = 0;
    try std.testing.expectError(error.ReceiptIdentityMalformed, driver_a.acceptPublishedReceipt(changed));
    try std.testing.expectEqualDeep(before, driver_a);
    changed = exact;
    changed.receipt.zig_toolchain_identity.bytes[
        changed.receipt.zig_toolchain_identity.length
    ] = 1;
    try std.testing.expectError(error.ReceiptIdentityMalformed, driver_a.acceptPublishedReceipt(changed));
    try std.testing.expectEqualDeep(before, driver_a);

    var driver_b = AcceptanceDriver{};
    const prepared_b = try advanceSyntheticDriverToPreparedReceipt(
        std.testing.allocator,
        &driver_b,
        context_b,
        source_bytes,
        target_a,
    );
    changed = try syntheticPublishedReceipt(prepared_b);
    try std.testing.expectError(error.PublicationContextMismatch, driver_a.acceptPublishedReceipt(changed));
    try std.testing.expectEqualDeep(before, driver_a);

    var driver_c = AcceptanceDriver{};
    const prepared_c = try advanceSyntheticDriverToPreparedReceipt(
        std.testing.allocator,
        &driver_c,
        context_a,
        source_bytes,
        target_b,
    );
    changed = try syntheticPublishedReceipt(prepared_c);
    try std.testing.expectError(error.PublicationTargetMismatch, driver_a.acceptPublishedReceipt(changed));
    try std.testing.expectEqualDeep(before, driver_a);

    var altered_prepared = prepared_a;
    altered_prepared.receipt.staged_tree_identity.bytes[0] ^= 1;
    altered_prepared.canonical_bytes = try encodeCanonicalReceipt(&altered_prepared.receipt);
    altered_prepared.exact_length = altered_prepared.canonical_bytes.length;
    var altered_digest: [std.crypto.hash.sha2.Sha256.digest_length]u8 = undefined;
    std.crypto.hash.sha2.Sha256.hash(
        try receipt.canonicalReceiptBytesSlice(&altered_prepared.canonical_bytes),
        &altered_digest,
        .{},
    );
    altered_prepared.canonical_sha256 = .{ .bytes = altered_digest };
    changed = try syntheticPublishedReceipt(altered_prepared);
    try std.testing.expectError(error.PublicationPreparedMismatch, driver_a.acceptPublishedReceipt(changed));
    try std.testing.expectEqualDeep(before, driver_a);

    try std.testing.expectError(
        error.PublicationContextMismatch,
        bindPublishedReceipt(
            &prepared_a,
            context_b,
            prepared_a.validation_directory,
            prepared_a.final_target,
            exact.publication_identity,
        ),
    );
    try std.testing.expectError(
        error.PublicationTargetMismatch,
        bindPublishedReceipt(
            &prepared_a,
            context_a,
            prepared_a.validation_directory,
            target_b,
            exact.publication_identity,
        ),
    );
    var incomplete_identity = exact.publication_identity;
    incomplete_identity.completion_status = .incomplete;
    try std.testing.expectError(
        error.PublicationIncomplete,
        bindPublishedReceipt(
            &prepared_a,
            context_a,
            prepared_a.validation_directory,
            target_a,
            incomplete_identity,
        ),
    );

    var malformed_prepared = prepared_a;
    malformed_prepared.canonical_bytes.length = 0;
    try std.testing.expectError(
        error.PublicationLengthMismatch,
        bindPublishedReceipt(
            &malformed_prepared,
            context_a,
            prepared_a.validation_directory,
            target_a,
            exact.publication_identity,
        ),
    );
    malformed_prepared = prepared_a;
    malformed_prepared.canonical_bytes.length = @intCast(receipt.receipt_max_bytes + 1);
    try std.testing.expectError(
        error.PublicationLengthMismatch,
        bindPublishedReceipt(
            &malformed_prepared,
            context_a,
            prepared_a.validation_directory,
            target_a,
            exact.publication_identity,
        ),
    );
    malformed_prepared = prepared_a;
    malformed_prepared.canonical_bytes.bytes[malformed_prepared.canonical_bytes.length] = 1;
    try std.testing.expectError(
        error.PublicationBytesMismatch,
        bindPublishedReceipt(
            &malformed_prepared,
            context_a,
            prepared_a.validation_directory,
            target_a,
            exact.publication_identity,
        ),
    );
    malformed_prepared = prepared_a;
    malformed_prepared.final_target.length = 0;
    try std.testing.expectError(
        error.PublicationTargetInvalid,
        bindPublishedReceipt(
            &malformed_prepared,
            context_a,
            prepared_a.validation_directory,
            target_a,
            exact.publication_identity,
        ),
    );
    malformed_prepared = prepared_a;
    malformed_prepared.receipt.zig_toolchain_identity.length = 0;
    try std.testing.expectError(
        error.ReceiptIdentityMalformed,
        bindPublishedReceipt(
            &malformed_prepared,
            context_a,
            prepared_a.validation_directory,
            target_a,
            exact.publication_identity,
        ),
    );
    try driver_a.acceptPublishedReceipt(exact);
    try std.testing.expectEqual(DriverPhase.published, driver_a.phase);
}

test "real acceptance adapters remain absent and fail closed" {
    try std.testing.expectError(
        error.AcceptanceAdaptersUnavailable,
        failClosedRealRepositoryAdapter(),
    );
    try std.testing.expectError(
        error.AcceptanceAdaptersUnavailable,
        failClosedRealBootstrapAdapter(),
    );
    try std.testing.expectError(
        error.AcceptanceAdaptersUnavailable,
        failClosedRealProcessAdapter(),
    );
    try std.testing.expectError(
        error.AcceptanceAdaptersUnavailable,
        failClosedRealNativeProcessAdapter(),
    );
    try std.testing.expectError(
        error.AcceptanceAdaptersUnavailable,
        failClosedRealValidationDirectoryAdapter(),
    );
    comptime if (!@hasDecl(driver_module, "main")) {
        @compileError("the unwired tool-local entry point must remain declared");
    };
}
