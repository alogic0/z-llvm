const std = @import("std");
const codegen = @import("codegen.zig");
const ir = @import("ir.zig");
const irw = @import("ir_writer_helpers.zig");
const mc = @import("mc.zig");
const sd = @import("semantic_descriptor.zig");
const sdv2 = @import("semantic_descriptor_v2.zig");
const sib = @import("structured_ir_builder.zig");
const target = @import("target.zig");
const zae = @import("zig_air_export.zig");
const zal = @import("zig_air_lowering.zig");
const zsl = @import("zig_semantic_lowering.zig");
const base64_rows = @import("main_base64_rows.zig");
const dependencies = @import("analysis/global_dependencies.zig");
const compilation = @import("compilation.zig");

const writeBase64SourceByte = base64_rows.writeBase64SourceByte;
const writeBase64OutputStore = base64_rows.writeBase64OutputStore;
const writeBase64FourByteBundleLoads = base64_rows.writeBase64FourByteBundleLoads;
const base64DecodeTableValue = base64_rows.base64DecodeTableValue;
const writeBase64FullTableConstant = base64_rows.writeBase64FullTableConstant;
const writeBase64FullMainCheck = base64_rows.writeBase64FullMainCheck;
const base64FullTableInitializer = base64_rows.base64FullTableInitializer;
const writeBase64FullStructuredModule = base64_rows.writeBase64FullStructuredModule;
const writeBase64FullMainCheckStructured = base64_rows.writeBase64FullMainCheckStructured;
const writeBase64FullTableLoadStructured = base64_rows.writeBase64FullTableLoadStructured;
const writeBase64OutputStoreStructured = base64_rows.writeBase64OutputStoreStructured;
const writeReleaseSmallRuntimeBase64DecodeBase64FullIrWriterBody = base64_rows.writeReleaseSmallRuntimeBase64DecodeBase64FullIrWriterBody;
const writeReleaseSmallRuntimeBase64DecodeBase64FullTextualIrWriterBody = base64_rows.writeReleaseSmallRuntimeBase64DecodeBase64FullTextualIrWriterBody;
const writeReleaseSmallRuntimeBase64DecodeStepIrWriterBody = base64_rows.writeReleaseSmallRuntimeBase64DecodeStepIrWriterBody;
const writeBase64DecodeStepStructuredModule = base64_rows.writeBase64DecodeStepStructuredModule;
const writeReleaseSmallRuntimeBase64StoreStepIrWriterBody = base64_rows.writeReleaseSmallRuntimeBase64StoreStepIrWriterBody;
const writeBase64StoreStepStructuredModule = base64_rows.writeBase64StoreStepStructuredModule;
const writeReleaseSmallRuntimeBase64ResidualByteStepIrWriterBody = base64_rows.writeReleaseSmallRuntimeBase64ResidualByteStepIrWriterBody;
const writeBase64ResidualByteStepStructuredModule = base64_rows.writeBase64ResidualByteStepStructuredModule;
const writeReleaseSmallRuntimeBase64PaddingTailStepIrWriterBody = base64_rows.writeReleaseSmallRuntimeBase64PaddingTailStepIrWriterBody;
const writeBase64PaddingTailStepStructuredModule = base64_rows.writeBase64PaddingTailStepStructuredModule;
const writeReleaseSmallRuntimeBase64PaddingLoopStepIrWriterBody = base64_rows.writeReleaseSmallRuntimeBase64PaddingLoopStepIrWriterBody;
const writeBase64PaddingLoopStepStructuredModule = base64_rows.writeBase64PaddingLoopStepStructuredModule;
const writeReleaseSmallRuntimeBase64PaddingLengthStepIrWriterBody = base64_rows.writeReleaseSmallRuntimeBase64PaddingLengthStepIrWriterBody;
const writeBase64PaddingLengthStepStructuredModule = base64_rows.writeBase64PaddingLengthStepStructuredModule;
const writeReleaseSmallRuntimeBase64ChunkGuardStepIrWriterBody = base64_rows.writeReleaseSmallRuntimeBase64ChunkGuardStepIrWriterBody;
const writeBase64ChunkGuardStepStructuredModule = base64_rows.writeBase64ChunkGuardStepStructuredModule;
const writeReleaseSmallRuntimeBase64SourceStrideStepIrWriterBody = base64_rows.writeReleaseSmallRuntimeBase64SourceStrideStepIrWriterBody;
const writeBase64SourceStrideStructuredModule = base64_rows.writeBase64SourceStrideStructuredModule;
const writeReleaseSmallRuntimeBase64SourceBundleStepIrWriterBody = base64_rows.writeReleaseSmallRuntimeBase64SourceBundleStepIrWriterBody;
const writeReleaseSmallRuntimeBase64NextSourceBundleStepIrWriterBody = base64_rows.writeReleaseSmallRuntimeBase64NextSourceBundleStepIrWriterBody;
const writeReleaseSmallRuntimeBase64ThirdSourceBundleStepIrWriterBody = base64_rows.writeReleaseSmallRuntimeBase64ThirdSourceBundleStepIrWriterBody;
const writeBase64SourceBundleStructuredModule = base64_rows.writeBase64SourceBundleStructuredModule;
const writeBase64FourByteBundleStructured = base64_rows.writeBase64FourByteBundleStructured;
const writeBase64BundleTableLoad = base64_rows.writeBase64BundleTableLoad;
const writeReleaseSmallRuntimeBase64BitBufferStoreStepIrWriterBody = base64_rows.writeReleaseSmallRuntimeBase64BitBufferStoreStepIrWriterBody;
const writeBase64BitBufferStoreStructuredModule = base64_rows.writeBase64BitBufferStoreStructuredModule;
const writeReleaseSmallRuntimeBase64LoopAdvanceStepIrWriterBody = base64_rows.writeReleaseSmallRuntimeBase64LoopAdvanceStepIrWriterBody;
const writeBase64LoopAdvanceStructuredModule = base64_rows.writeBase64LoopAdvanceStructuredModule;
const writeReleaseSmallRuntimeBase64ResidualGuardStepIrWriterBody = base64_rows.writeReleaseSmallRuntimeBase64ResidualGuardStepIrWriterBody;
const writeBase64ResidualGuardStructuredModule = base64_rows.writeBase64ResidualGuardStructuredModule;
const writeReleaseSmallRuntimeBase64ResidualBundleStepIrWriterBody = base64_rows.writeReleaseSmallRuntimeBase64ResidualBundleStepIrWriterBody;
const writeReleaseSmallRuntimeBase64ResidualStoreStepIrWriterBody = base64_rows.writeReleaseSmallRuntimeBase64ResidualStoreStepIrWriterBody;
const writeBase64ResidualStoreStructuredModule = base64_rows.writeBase64ResidualStoreStructuredModule;
const writeReleaseSmallRuntimeBase64ResidualLengthStepIrWriterBody = base64_rows.writeReleaseSmallRuntimeBase64ResidualLengthStepIrWriterBody;
const writeBase64ResidualLengthStructuredModule = base64_rows.writeBase64ResidualLengthStructuredModule;
const writeReleaseSmallRuntimeBase64ResidualTableCheckStepIrWriterBody = base64_rows.writeReleaseSmallRuntimeBase64ResidualTableCheckStepIrWriterBody;
const writeBase64ResidualTableCheckStructuredModule = base64_rows.writeBase64ResidualTableCheckStructuredModule;
const writeReleaseSmallRuntimeBase64ResidualAccumulatorStepIrWriterBody = base64_rows.writeReleaseSmallRuntimeBase64ResidualAccumulatorStepIrWriterBody;
const writeBase64ResidualAccumulatorStructuredModule = base64_rows.writeBase64ResidualAccumulatorStructuredModule;
const writeReleaseSmallRuntimeBase64ResidualLoopAdvanceStepIrWriterBody = base64_rows.writeReleaseSmallRuntimeBase64ResidualLoopAdvanceStepIrWriterBody;
const writeBase64ResidualLoopAdvanceStructuredModule = base64_rows.writeBase64ResidualLoopAdvanceStructuredModule;
const writeReleaseSmallRuntimeBase64ResidualPaddingCheckStepIrWriterBody = base64_rows.writeReleaseSmallRuntimeBase64ResidualPaddingCheckStepIrWriterBody;
const writeBase64ResidualPaddingCheckStructuredModule = base64_rows.writeBase64ResidualPaddingCheckStructuredModule;
const writeReleaseSmallRuntimeBase64ResidualFinalMaskStepIrWriterBody = base64_rows.writeReleaseSmallRuntimeBase64ResidualFinalMaskStepIrWriterBody;
const writeBase64ResidualFinalMaskStructuredModule = base64_rows.writeBase64ResidualFinalMaskStructuredModule;
const writeReleaseSmallRuntimeBase64ResidualPaddingLoopStepIrWriterBody = base64_rows.writeReleaseSmallRuntimeBase64ResidualPaddingLoopStepIrWriterBody;
const writeBase64ResidualPaddingLoopStructuredModule = base64_rows.writeBase64ResidualPaddingLoopStructuredModule;
const writeReleaseSmallRuntimeBase64DecodeExitStepIrWriterBody = base64_rows.writeReleaseSmallRuntimeBase64DecodeExitStepIrWriterBody;
const writeBase64DecodeExitStructuredModule = base64_rows.writeBase64DecodeExitStructuredModule;
const writeBase64TableLookupIrWriterBody = base64_rows.writeBase64TableLookupIrWriterBody;
const writeBase64TableLookupStructuredModule = base64_rows.writeBase64TableLookupStructuredModule;

pub const Emit = enum {
    ir,
    @"asm",
    obj,
    ir_writer,
    semantic_descriptor,
    selection_owner_manifest,
};

pub const CodegenEmitOptions = struct {
    profile: ?*@import("compilation_profile.zig").Profile = null,
    owner_output: ?[]const u8 = null,
    quiet: bool = false,
    report_all_failures: bool = false,
    generic_cfg_selector: bool = false,
    codegen_reachable: bool = false,
};

pub fn fatal(io: std.Io, comptime fmt: []const u8, args: anytype) noreturn {
    var stderr_buffer: [4096]u8 = undefined;
    var stderr_writer = std.Io.File.stderr().writerStreaming(io, &stderr_buffer);
    stderr_writer.interface.print(fmt, args) catch {};
    stderr_writer.interface.flush() catch {};
    std.process.exit(2);
}

const source_wrapper_dispatch_case_id = "source-wrapper-dispatch";
const source_wrapper_dispatch_name = "source-wrapper";
const source_owned_dispatch_name = "source-owned";
pub fn writeIrWriterModuleFromEnv(
    allocator: std.mem.Allocator,
    io: std.Io,
    environ: *const std.process.Environ.Map,
) !void {
    const writer_mode = requiredEnv(io, environ, "ZLLVM_IR_WRITER_MODE");
    if (!std.mem.eql(u8, writer_mode, "external")) {
        try fatal(io, "ZLLVM_IR_WRITER_MODE must be external; got {s}\n", .{writer_mode});
    }
    const case_id = requiredEnv(io, environ, "ZLLVM_CASE_ID");
    const mode = requiredEnv(io, environ, "ZLLVM_ZIG_MODE");
    const wrapper = requiredEnv(io, environ, "ZLLVM_WRAPPER");
    const ir_path = requiredEnv(io, environ, "ZLLVM_IR_PATH");
    const source_fixture = environ.get("ZLLVM_SOURCE_FIXTURE") orelse "-";
    const source_tag = environ.get("ZLLVM_SOURCE_TAG") orelse "-";
    const semantic_descriptor_path = environ.get("ZLLVM_SEMANTIC_DESCRIPTOR_PATH") orelse "-";
    const source_owned_dispatch = envEquals(environ, "ZLLVM_IR_WRITER_DISPATCH", source_owned_dispatch_name);
    const source_wrapper_dispatch = !source_owned_dispatch and
        (std.mem.eql(u8, case_id, source_wrapper_dispatch_case_id) or
            envEquals(environ, "ZLLVM_IR_WRITER_DISPATCH", source_wrapper_dispatch_name));
    const descriptor = if (source_owned_dispatch)
        try readSourceOwnedDescriptorFromEnv(allocator, io, environ, wrapper, mode, source_fixture, source_tag)
    else
        null;
    if (descriptor) |desc| {
        if (sd.firstUnsupportedConstruct(desc)) |construct| {
            try fatal(io, "unsupported semantic descriptor construct={s} wrapper={s} fixture={s} mode={s} source_tag={s}\n", .{ construct, wrapper, source_fixture, mode, source_tag });
        }
    }
    const ir_writer_case = if (source_owned_dispatch)
        null
    else if (source_wrapper_dispatch)
        resolveSourceWrapperDispatchCase(wrapper, mode)
    else
        findIrWriterCase(case_id);
    const surface = if (descriptor) |desc| desc.surface else if (ir_writer_case) |case| case.surface else "minimal-ret0";
    const construction = if (descriptor != null) IrConstruction.structured_builder.marker() else if (ir_writer_case) |case| case.construction.marker() else IrConstruction.textual_subset.marker();
    const codegen_ownership = if (descriptor != null) CodegenOwnership.generic.marker() else if (ir_writer_case) |case| codegenOwnershipForCase(case).marker() else CodegenOwnership.case_specific.marker();
    const lowering_ownership = if (descriptor != null) StructuredLoweringOwnership.descriptor_v2.marker() else if (ir_writer_case) |case|
        structuredLoweringOwnershipForCase(case).marker()
    else
        StructuredLoweringOwnership.manifest_structured.marker();

    var file = std.Io.Dir.cwd().createFile(io, ir_path, .{}) catch |err| {
        try fatal(io, "failed to create external IR writer output {s}: {any}\n", .{ ir_path, err });
    };
    defer file.close(io);

    var buffer: [4096]u8 = undefined;
    var writer = file.writer(io, &buffer);
    const is_structured_direct = if (descriptor != null) true else if (ir_writer_case) |case| case.construction == .structured_builder else false;
    const release_canonicalization: sdv2.ReleaseCanonicalizationReport = if (descriptor) |desc| sd.releaseCanonicalizationReport(desc) else .{};
    writer.interface.print(
        \\; ModuleID = "zllvm-external-ir-writer"
        \\source_filename = "{s}"
        \\target triple = "x86_64-unknown-linux-gnu"
        \\; zllvm_ir_writer_contract = "external"
        \\; zllvm_ir_writer_case = "{s}"
        \\; zllvm_ir_writer_resolved_case = "{s}"
        \\; zllvm_ir_writer_dispatch = "{s}"
        \\; zllvm_ir_writer_wrapper = "{s}"
        \\; zllvm_ir_writer_mode = "{s}"
        \\; zllvm_ir_writer_source_fixture = "{s}"
        \\; zllvm_ir_writer_source_tag = "{s}"
        \\; zllvm_ir_writer_surface = "{s}"
        \\; zllvm_ir_writer_construction = "{s}"
        \\; zllvm_ir_writer_llvm_text_parse = "{s}"
        \\; zllvm_ir_writer_direct_module = "{s}"
        \\; zllvm_ir_writer_codegen = "{s}"
        \\; zllvm_ir_writer_lowering = "{s}"
        \\; zllvm_semantic_descriptor = "{s}"
        \\; zllvm_semantic_descriptor_path = "{s}"
        \\; zllvm_semantic_descriptor_id = "{s}"
        \\; zllvm_semantic_descriptor_version = "{s}"
        \\; zllvm_semantic_descriptor_body = "{s}"
        \\; zllvm_descriptor_program = "{s}"
        \\; zllvm_descriptor_input = "{s}"
        \\; zllvm_descriptor_file_consumed = "{s}"
        \\; zllvm_source_fact_stream = "{s}"
        \\; zllvm_zig_emitted_descriptor = "{s}"
        \\; zllvm_runner_generated_descriptor = "{s}"
        \\; zllvm_source_derived_descriptor = "{s}"
        \\; zllvm_tag_table_descriptor = "{s}"
        \\; zllvm_body_enum_dispatch = "{s}"
        \\; zllvm_surface_to_body_adapter = "{s}"
        \\; zllvm_canned_return_descriptor = "{s}"
        \\; zllvm_surface_dispatch = "{s}"
        \\
    , .{
        wrapper,
        case_id,
        if (descriptor) |desc| desc.id else if (ir_writer_case) |case| case.id else "-",
        if (source_owned_dispatch) source_owned_dispatch_name else if (source_wrapper_dispatch) source_wrapper_dispatch_name else "case-id",
        wrapper,
        mode,
        source_fixture,
        source_tag,
        surface,
        construction,
        if (is_structured_direct) "not-used" else "required-for-textual-boundary",
        if (is_structured_direct) "z_llvm-owned-internal-ir" else "not-used",
        codegen_ownership,
        lowering_ownership,
        if (descriptor != null) "descriptor-owned" else "not-used",
        if (descriptor != null) semantic_descriptor_path else "-",
        if (descriptor) |desc| desc.id else "-",
        if (descriptor != null) "v2" else "-",
        if (descriptor) |desc| sdv2BodyName(desc) else "-",
        if (descriptor) |desc| if (sd.isRealDescriptorProgram(desc)) "real" else "not-real" else "-",
        if (descriptor != null) "source-derived" else "not-used",
        if (descriptor != null) "used" else "-",
        if (descriptor) |desc| if (sd.usesSourceFactStream(desc)) "used" else "not-used" else "-",
        if (descriptor) |desc| if (sd.isZigEmittedDescriptor(desc)) "used" else "not-used" else "-",
        if (descriptor) |desc| if (sd.isRunnerGeneratedDescriptor(desc)) "used" else "not-used" else "-",
        if (descriptor) |desc| if (sd.isSourceDerivedDescriptor(desc)) "used" else "not-used" else "-",
        if (descriptor != null) "not-used" else "-",
        if (descriptor) |desc| if (sd.isBodyEnumDispatchDescriptor(desc)) "used" else "not-used" else "-",
        if (descriptor) |desc| if (sd.isSurfaceToBodyAdapter(desc)) "used" else "not-used" else "-",
        if (descriptor) |desc| if (sd.isCannedReturnDescriptor(desc)) "used" else "not-used" else "-",
        if (descriptor != null) "not-used" else if (ir_writer_case != null) "case-surface" else "not-used",
    }) catch |err| {
        try fatal(io, "failed to write external IR writer header {s}: {any}\n", .{ ir_path, err });
    };
    writer.interface.print(
        \\; zllvm_full_descriptor_program = "{s}"
        \\; zllvm_descriptor_body_name = "{s}"
        \\; zllvm_body_expansion = "{s}"
        \\; zllvm_serialized_functions = "{s}"
        \\; zllvm_serialized_instructions = "{s}"
        \\; zllvm_serialized_globals = "{s}"
        \\; zllvm_descriptor_program_body_expansion = "{s}"
        \\; zllvm_functions_for_body = "{s}"
        \\; zllvm_globals_for_body = "{s}"
        \\; zllvm_serialized_return_i32 = "{}"
        \\; zllvm_air_derived_descriptor = "{s}"
        \\; zllvm_static_descriptor_map = "{s}"
        \\; zllvm_air_extracted_descriptor = "{s}"
        \\; zllvm_template_descriptor = "{s}"
        \\; zllvm_wrapper_body_map = "{s}"
        \\; zllvm_source_tag_body_map = "{s}"
        \\; zllvm_zig_compile_context_descriptor = "{s}"
        \\; zllvm_env_source_tag_selector = "{s}"
        \\; zllvm_wrapper_body_selector = "{s}"
        \\; zllvm_source_tag_body_selector = "{s}"
        \\; zllvm_fixture_metadata_selector = "{s}"
        \\; zllvm_source_tag_env_present = "{s}"
        \\; zllvm_concrete_source_facts = "{s}"
        \\; zllvm_fact_derived_classification = "{s}"
        \\; zllvm_root_source_classification_fallback = "{s}"
        \\; zllvm_source_fact_program = "{s}"
        \\; zllvm_source_fact_program_direct = "{s}"
        \\; zllvm_source_fact_body_wrapper = "{s}"
        \\; zllvm_body_enum_fallback = "{s}"
        \\
    , .{
        if (descriptor) |desc| if (sd.isFullDescriptorProgramInput(desc)) "used" else "not-used" else "-",
        if (descriptor) |desc| if (sd.usesDescriptorBodyNameInput(desc)) "used" else "not-used" else "-",
        if (descriptor) |desc| if (sd.usesZllvmBodyExpansion(desc)) "used" else "not-used" else "-",
        if (descriptor) |desc| if (sd.hasSerializedFunctions(desc)) "used" else "not-used" else "-",
        if (descriptor) |desc| if (sd.hasSerializedInstructions(desc)) "used" else "not-used" else "-",
        if (descriptor) |desc| if (sd.hasSerializedGlobals(desc)) "used" else "not-used" else "-",
        if (descriptor) |desc| if (sd.usesDescriptorProgramBodyExpansion(desc)) "used" else "not-used" else "-",
        if (descriptor) |desc| if (sd.usesFunctionsForBody(desc)) "used" else "not-used" else "-",
        if (descriptor) |desc| if (sd.usesGlobalsForBody(desc)) "used" else "not-used" else "-",
        if (descriptor) |desc| sd.serializedReturnI32(desc) orelse -1 else -1,
        if (descriptor) |desc| if (sd.isAirDerivedDescriptor(desc)) "used" else "not-used" else "-",
        if (descriptor) |desc| if (sd.isStaticDescriptorMap(desc)) "used" else "not-used" else "-",
        if (descriptor) |desc| if (sd.isAirExtractedDescriptor(desc)) "used" else "not-used" else "-",
        if (descriptor) |desc| if (sd.isTemplateDescriptor(desc)) "used" else "not-used" else "-",
        if (descriptor) |desc| if (sd.usesWrapperBodyMap(desc)) "used" else "not-used" else "-",
        if (descriptor) |desc| if (sd.usesSourceTagBodyMap(desc)) "used" else "not-used" else "-",
        if (descriptor) |desc| if (sd.usesCompileContextDescriptor(desc)) "used" else "not-used" else "-",
        if (descriptor) |desc| if (sd.usesEnvSourceTagSelector(desc)) "used" else "not-used" else "-",
        if (descriptor) |desc| if (sd.usesWrapperBodySelector(desc)) "used" else "not-used" else "-",
        if (descriptor) |desc| if (sd.usesSourceTagBodySelector(desc)) "used" else "not-used" else "-",
        if (descriptor) |desc| if (sd.usesFixtureMetadataSelector(desc)) "used" else "not-used" else "-",
        if (descriptor) |desc| if (sd.hasSourceTagEnv(desc)) "present" else "not-present" else "-",
        if (descriptor) |desc| if (sd.hasConcreteSourceFacts(desc)) "used" else "not-used" else "-",
        if (descriptor) |desc| if (sd.usesFactDerivedClassification(desc)) "used" else "not-used" else "-",
        if (descriptor) |desc| if (sd.usesRootSourceClassificationFallback(desc)) "used" else "not-used" else "-",
        if (descriptor) |desc| if (sd.usesSourceFactProgram(desc)) "used" else "not-used" else "-",
        if (descriptor) |desc| if (sd.usesSourceFactProgramDirect(desc)) "used" else "not-used" else "-",
        if (descriptor) |desc| if (sd.usesSourceFactBodyWrapper(desc)) "used" else "not-used" else "-",
        if (descriptor) |desc| if (sd.usesBodyEnumFallback(desc)) "used" else "not-used" else "-",
    }) catch |err| {
        try fatal(io, "failed to write external IR writer descriptor header {s}: {any}\n", .{ ir_path, err });
    };
    writer.interface.print(
        \\; zllvm_release_canonicalizer = "{s}"
        \\; zllvm_release_canonicalizer_int_folds = "{}"
        \\; zllvm_release_canonicalizer_fp_folds = "{}"
        \\; zllvm_release_canonicalizer_dead_locals = "{}"
        \\; zllvm_release_canonicalizer_select_fcmp = "{}"
        \\; zllvm_release_canonicalizer_branch_to_return = "{}"
        \\; zllvm_release_canonicalizer_single_pred_phi = "{}"
        \\; zllvm_release_canonicalizer_checked_seen = "{}"
        \\; zllvm_release_canonicalizer_checks_preserved = "{}"
        \\; zllvm_release_canonicalizer_observed_int_folds = "{}"
        \\; zllvm_release_canonicalizer_observed_fp_folds = "{}"
        \\; zllvm_release_canonicalizer_observed_dead_locals = "{}"
        \\; zllvm_release_canonicalizer_observed_select_fcmp = "{}"
        \\; zllvm_release_canonicalizer_observed_branch_to_return = "{}"
        \\; zllvm_release_canonicalizer_observed_single_pred_phi = "{}"
        \\; zllvm_release_canonicalizer_applied_int_folds = "{}"
        \\; zllvm_release_canonicalizer_applied_fp_folds = "{}"
        \\; zllvm_release_canonicalizer_applied_dead_locals = "{}"
        \\; zllvm_release_canonicalizer_applied_select_fcmp = "{}"
        \\; zllvm_release_canonicalizer_applied_branch_to_return = "{}"
        \\; zllvm_release_canonicalizer_applied_single_pred_phi = "{}"
        \\; zllvm_release_canonicalizer_after_int_folds = "{}"
        \\; zllvm_release_canonicalizer_after_fp_folds = "{}"
        \\; zllvm_release_canonicalizer_after_dead_locals = "{}"
        \\; zllvm_release_canonicalizer_after_select_fcmp = "{}"
        \\; zllvm_release_canonicalizer_after_branch_to_return = "{}"
        \\; zllvm_release_canonicalizer_after_single_pred_phi = "{}"
        \\; zllvm_release_canonicalizer_check_mode = "{s}"
        \\
    , .{
        if (release_canonicalization.observed.ran) "used" else "not-used",
        release_canonicalization.observed.constant_folded_int_ops,
        release_canonicalization.observed.constant_folded_fp_ops,
        release_canonicalization.observed.dead_local_computations,
        release_canonicalization.observed.canonicalized_select_fcmp,
        release_canonicalization.observed.simplified_branch_to_return,
        release_canonicalization.observed.simplified_single_pred_phi,
        release_canonicalization.observed.checked_boundaries_seen,
        release_canonicalization.after.checked_boundaries_seen,
        release_canonicalization.observed.constant_folded_int_ops,
        release_canonicalization.observed.constant_folded_fp_ops,
        release_canonicalization.observed.dead_local_computations,
        release_canonicalization.observed.canonicalized_select_fcmp,
        release_canonicalization.observed.simplified_branch_to_return,
        release_canonicalization.observed.simplified_single_pred_phi,
        release_canonicalization.applied.constant_folded_int_ops,
        release_canonicalization.applied.constant_folded_fp_ops,
        release_canonicalization.applied.dead_local_computations,
        release_canonicalization.applied.canonicalized_select_fcmp,
        release_canonicalization.applied.simplified_branch_to_return,
        release_canonicalization.applied.simplified_single_pred_phi,
        release_canonicalization.after.constant_folded_int_ops,
        release_canonicalization.after.constant_folded_fp_ops,
        release_canonicalization.after.dead_local_computations,
        release_canonicalization.after.canonicalized_select_fcmp,
        release_canonicalization.after.simplified_branch_to_return,
        release_canonicalization.after.simplified_single_pred_phi,
        mode,
    }) catch |err| {
        try fatal(io, "failed to write external IR writer optimizer header {s}: {any}\n", .{ ir_path, err });
    };
    if (descriptor) |desc| {
        writer.interface.writeAll("; zllvm_semantic_descriptor_features = \"") catch |err| {
            try fatal(io, "failed to start semantic descriptor features {s}: {any}\n", .{ ir_path, err });
        };
        sd.writeFeatureList(desc.features, &writer.interface) catch |err| {
            try fatal(io, "failed to write semantic descriptor features {s}: {any}\n", .{ ir_path, err });
        };
        writer.interface.writeAll("\"\n; zllvm_manual_fixture_dispatch = \"not-used\"\n\n") catch |err| {
            try fatal(io, "failed to write semantic descriptor header {s}: {any}\n", .{ ir_path, err });
        };
        var direct_module = buildStructuredDirectModuleFromDescriptor(allocator, io, desc) catch |err| {
            try fatal(io, "failed to build semantic descriptor module for {s}: {any}\n", .{ desc.id, err });
        };
        defer direct_module.deinit();
    } else if (ir_writer_case) |case| {
        writer.interface.writeAll("; zllvm_semantic_descriptor_features = \"-\"\n; zllvm_manual_fixture_dispatch = \"not-used\"\n\n") catch |err| {
            try fatal(io, "failed to finish external IR writer header {s}: {any}\n", .{ ir_path, err });
        };
        if (case.construction == .structured_builder) {
            var direct_module = buildStructuredDirectModule(allocator, io, case) catch |err| {
                try fatal(io, "failed to build direct IR writer module for {s}: {any}\n", .{ case.id, err });
            };
            defer direct_module.deinit();
        } else {
            try case.write(io, &writer.interface, ir_path);
        }
    } else {
        writer.interface.writeAll("; zllvm_semantic_descriptor_features = \"-\"\n; zllvm_manual_fixture_dispatch = \"not-used\"\n\n") catch |err| {
            try fatal(io, "failed to finish minimal external IR writer header {s}: {any}\n", .{ ir_path, err });
        };
        try writeMinimalIrWriterBody(io, &writer.interface, ir_path);
    }
    writer.interface.flush() catch |err| {
        try fatal(io, "failed to flush external IR writer output {s}: {any}\n", .{ ir_path, err });
    };
}

pub fn writeSemanticDescriptorFromEnv(
    allocator: std.mem.Allocator,
    io: std.Io,
    environ: *const std.process.Environ.Map,
) !void {
    const mode = requiredEnv(io, environ, "ZLLVM_ZIG_MODE");
    const wrapper = requiredEnv(io, environ, "ZLLVM_WRAPPER");
    const source_fixture = environ.get("ZLLVM_SOURCE_FIXTURE") orelse "-";
    const source_tag = environ.get("ZLLVM_SOURCE_TAG") orelse "-";
    const descriptor = try readSourceOwnedDescriptorFromEnv(allocator, io, environ, wrapper, mode, source_fixture, source_tag);
    if (sd.firstUnsupportedConstruct(descriptor)) |construct| {
        try fatal(io, "unsupported semantic descriptor construct={s} wrapper={s} fixture={s} mode={s} source_tag={s}\n", .{ construct, wrapper, source_fixture, mode, source_tag });
    }

    var stdout_buffer: [4096]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
    try sd.writeText(descriptor, &stdout_writer.interface);
    try stdout_writer.interface.flush();
}

pub fn readSourceOwnedDescriptorFromEnv(
    allocator: std.mem.Allocator,
    io: std.Io,
    environ: *const std.process.Environ.Map,
    wrapper: []const u8,
    mode: []const u8,
    source_fixture: []const u8,
    source_tag: []const u8,
) !sd.Descriptor {
    const descriptor_path = requiredEnv(io, environ, "ZLLVM_SEMANTIC_DESCRIPTOR_PATH");
    const contents = std.Io.Dir.cwd().readFileAlloc(io, descriptor_path, allocator, .limited(1024 * 1024)) catch |err| {
        try fatal(io, "failed to read source-derived semantic descriptor {s}: {any}\n", .{ descriptor_path, err });
    };
    // The returned descriptor borrows slices from this process-local input.
    // z_llvm exits immediately after consuming one descriptor, so keeping the
    // stable input alive is simpler than cloning each field independently.
    const descriptor = sd.resolveSourceOwnedFromInput(contents) orelse {
        try fatal(io, "unsupported semantic descriptor construct=source-derived-input wrapper={s} fixture={s} mode={s} source_tag={s} descriptor={s}\n", .{ wrapper, source_fixture, mode, source_tag, descriptor_path });
    };
    if (!std.mem.eql(u8, descriptor.source.wrapper, wrapper) or
        !std.mem.eql(u8, descriptor.source.mode, mode))
    {
        try fatal(io, "source-derived descriptor metadata mismatch descriptor={s} expected_wrapper={s} actual_wrapper={s} diagnostic_fixture={s} actual_fixture={s} expected_mode={s} actual_mode={s} diagnostic_source_tag={s} actual_source_tag={s}\n", .{ descriptor_path, wrapper, descriptor.source.wrapper, source_fixture, descriptor.source.fixture, mode, descriptor.source.mode, source_tag, descriptor.source.tag });
    }
    return descriptor;
}

fn sdv2BodyName(descriptor: sd.Descriptor) []const u8 {
    return @import("semantic_descriptor_v2.zig").bodyName(descriptor.v2.body);
}

pub fn emitCodegenModule(
    allocator: std.mem.Allocator,
    io: std.Io,
    module: ir.Module,
    emit: Emit,
    target_triple: ?[]const u8,
    options: CodegenEmitOptions,
) !void {
    const triple = target_triple orelse module.target_triple orelse {
        try fatal(io, "missing target triple for codegen emit; pass --target=<triple> or include target triple in the input\n", .{});
    };
    const parsed_triple = target.Triple.parse(triple) catch {
        try fatal(io, "invalid target triple for codegen emit: {s}\n", .{triple});
    };
    if (!parsed_triple.isX86_64() or !parsed_triple.isLinux()) {
        try fatal(io, "unsupported codegen target: {s}; supported target subset is x86_64-linux\n", .{triple});
    }

    var machines: std.ArrayList(codegen.x86_64.MachineFunction) = .empty;
    defer {
        for (machines.items) |*machine| machine.deinit(allocator);
        machines.deinit(allocator);
    }
    var selected_functions: usize = 0;
    var failed_functions: usize = 0;
    var first_failing_function: []const u8 = "-";
    var first_failing_diagnostic: []const u8 = "-";
    var first_failing_selector_tag: []const u8 = "-";
    var first_failing_selector_detail: []const u8 = "-";
    var stderr_buffer: [4096]u8 = undefined;
    var stderr_writer = std.Io.File.stderr().writerStreaming(io, &stderr_buffer);
    var reachable: ?dependencies.Reachability = null;
    defer if (reachable) |*selection| selection.deinit();
    var selected_globals: std.ArrayList(ir.Global) = .empty;
    defer selected_globals.deinit(allocator);
    var selected_aliases: std.ArrayList(ir.GlobalAlias) = .empty;
    defer selected_aliases.deinit(allocator);
    if (options.codegen_reachable) {
        const scope = @import("compilation_profile.zig").enter(options.profile, .reachability);
        defer scope.end();
        if (emit == .@"asm") return error.UnsupportedReachableAssembly;
        if (module.module_asm.items.len != 0) return error.UnsupportedModuleAssembly;
        var graph = try dependencies.Graph.build(allocator, module);
        defer graph.deinit();
        reachable = try graph.reachable();
        for (module.globals.items) |global| {
            if (reachable.?.contains(.global, global.name)) try selected_globals.append(allocator, global);
        }
        for (module.aliases.items) |alias| {
            if (reachable.?.contains(.alias, alias.name)) try selected_aliases.append(allocator, alias);
        }
        try stderr_writer.interface.print("summary zllvm-codegen-selection mode=reachable coverage={s} selected_globals={} selected_aliases={}\n", .{
            if (reachable.?.has_unknown) "conservative" else "complete",
            selected_globals.items.len,
            selected_aliases.items.len,
        });
        try stderr_writer.interface.flush();
    }
    const module_context: codegen.x86_64.ReadOnlyModuleContext = .{
        .globals = if (reachable != null) selected_globals.items else module.globals.items,
        .named_types = module.named_types.items,
        .target_datalayout = module.target_datalayout,
        .emit_all_globals = options.codegen_reachable,
        .require_resolved_aliases = options.codegen_reachable,
        .functions = module.functions.items,
        .declarations = module.declarations.items,
    };
    for (module.functions.items) |function| {
        const selected = if (reachable) |selection| selection.contains(.function, function.name) else shouldLowerCodegenFunction(module, function);
        if (!selected) continue;
        if (options.codegen_reachable) switch (function.linkage) {
            .default, .external, .internal, .private => {},
            else => return error.UnsupportedFunctionLinkage,
        };
        selected_functions += 1;
        var selector_diagnostic_tag: ?[]const u8 = null;
        var selector_diagnostic_detail: ?[]const u8 = null;
        const selection_scope = @import("compilation_profile.zig").enter(options.profile, .select);
        defer selection_scope.end();
        var machine = compilation.select(allocator, triple, function, .{
            .profile = options.profile,
            .generic_cfg_selector = options.generic_cfg_selector,
            .module_context = &module_context,
            .generic_cfg_selector_diagnostic_tag = &selector_diagnostic_tag,
            .generic_cfg_selector_diagnostic_detail = &selector_diagnostic_detail,
        }) catch |err| {
            if (options.profile) |p| p.counters.failed_functions += 1;
            if (options.report_all_failures) {
                if (failed_functions == 0) {
                    first_failing_function = function.name;
                    first_failing_diagnostic = @errorName(err);
                    first_failing_selector_tag = selector_diagnostic_tag orelse "-";
                    first_failing_selector_detail = selector_diagnostic_detail orelse "-";
                }
                failed_functions += 1;
                try stderr_writer.interface.print(
                    "zllvm-codegen-failure function={s} diagnostic={s} selector_tag={s} selector_detail={s}\n",
                    .{
                        function.name,
                        @errorName(err),
                        selector_diagnostic_tag orelse "-",
                        selector_diagnostic_detail orelse "-",
                    },
                );
                // Selector diagnostics also write stderr directly. Finish this
                // row before the next function can emit those diagnostics.
                try stderr_writer.interface.flush();
                continue;
            }
            try fatal(io, "codegen failed for function {s}: {any}\n", .{ function.name, err });
        };
        errdefer machine.deinit(allocator);
        if (options.profile) |p| {
            p.counters.selected_functions += 1;
            p.counters.emitted_instructions += machine.instructions.items.len;
            for (machine.instructions.items) |instruction| {
                if (std.mem.startsWith(u8, @tagName(instruction), "spill_"))
                    p.counters.emitted_spill_instructions += 1;
            }
        }
        if (options.codegen_reachable) {
            machine.symbol_linkage = function.linkage;
            machine.symbol_visibility = function.visibility;
        }
        try machines.append(allocator, machine);
    }
    var stdout_buffer: [4096]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
    if (emit == .selection_owner_manifest) {
        const scope = @import("compilation_profile.zig").enter(options.profile, .ownership_write);
        defer scope.end();
        try writeOwnerManifest(allocator, machines.items, &stdout_writer.interface);
        try stdout_writer.interface.flush();
    }
    if (options.report_all_failures) {
        try stderr_writer.interface.print(
            "summary zllvm-codegen-report-all target={s} selected_functions={} emitted_functions={} failed_functions={} first_failing_function={s} first_failing_diagnostic={s} first_failing_selector_tag={s} first_failing_selector_detail={s} local_fail={}\n",
            .{
                triple,
                selected_functions,
                machines.items.len,
                failed_functions,
                first_failing_function,
                first_failing_diagnostic,
                first_failing_selector_tag,
                first_failing_selector_detail,
                @intFromBool(failed_functions != 0),
            },
        );
        try stderr_writer.interface.flush();
        if (failed_functions != 0) return error.CodegenFunctionsFailed;
    }

    if (emit == .selection_owner_manifest) return;

    var discard_buffer: [4096]u8 = undefined;
    var discard_writer: std.Io.Writer.Discarding = .init(&discard_buffer);
    const stdout = if (options.quiet) &discard_writer.writer else &stdout_writer.interface;
    if (emit == .@"asm") {
        for (machines.items) |machine| try mc.assembly.printFunction(machine, stdout);
    } else {
        const scope = @import("compilation_profile.zig").enter(options.profile, .object_write);
        defer scope.end();
        try mc.elf.writeObjectWithModuleContext(allocator, machines.items, if (reachable != null) selected_aliases.items else module.aliases.items, module_context, stdout);
        try stdout.flush();
    }
    try stdout.flush();
    if (options.owner_output) |path| {
        if (emit != .obj) return error.OwnerSidecarRequiresObject;
        const scope = @import("compilation_profile.zig").enter(options.profile, .ownership_write);
        defer scope.end();
        const file = try std.Io.Dir.cwd().createFile(io, path, .{});
        defer file.close(io);
        var buffer: [4096]u8 = undefined;
        var writer = file.writer(io, &buffer);
        try writeOwnerManifest(allocator, machines.items, &writer.interface);
        try writer.interface.flush();
    }
}

fn writeOwnerManifest(allocator: std.mem.Allocator, machines: []const codegen.x86_64.MachineFunction, writer: *std.Io.Writer) !void {
    // Sort references, preserving object function order and bytes.
    const sorted = try allocator.alloc(*const codegen.x86_64.MachineFunction, machines.len);
    defer allocator.free(sorted);
    for (machines, sorted) |*machine, *slot| slot.* = machine;
    std.mem.sort(*const codegen.x86_64.MachineFunction, sorted, {}, machineNameLessThan);
    try writer.writeAll("row_identity\tselection_owner\n");
    for (sorted) |machine| {
        if (machine.selection_owner == .unassigned) return error.UnassignedSelectionOwner;
        try writer.print("{s}\t{s}\n", .{ machine.name, @tagName(machine.selection_owner) });
    }
}

fn machineNameLessThan(_: void, lhs: *const codegen.x86_64.MachineFunction, rhs: *const codegen.x86_64.MachineFunction) bool {
    return std.mem.lessThan(u8, lhs.name, rhs.name);
}

fn shouldLowerCodegenFunction(module: ir.Module, function: ir.Function) bool {
    if (isCodegenRuntimeBoundaryFunction(function.name)) return false;
    if (isCodegenRootFunction(module, function)) return true;
    if (function.linkage != .private and function.linkage != .internal) return false;
    if (!isCodegenSelectedDirectPrivateHelper(function.name)) return false;
    for (module.functions.items) |caller| {
        if (std.mem.eql(u8, caller.name, function.name)) continue;
        if (!isCodegenRootFunction(module, caller)) continue;
        if (functionDirectlyCalls(caller, function.name)) return true;
    }
    return false;
}

fn isCodegenRootFunction(module: ir.Module, function: ir.Function) bool {
    if (std.mem.eql(u8, function.name, "main.testOne")) return true;
    if (module.aliases.items.len == 0) return true;
    if (function.linkage != .private and function.linkage != .internal) return true;
    for (module.aliases.items) |alias| {
        if (std.mem.eql(u8, alias.target, function.name)) return true;
    }
    return false;
}

fn isCodegenRuntimeBoundaryFunction(name: []const u8) bool {
    return std.mem.startsWith(u8, name, "debug.") or
        std.mem.startsWith(u8, name, "\"debug.");
}

fn isCodegenSelectedDirectPrivateHelper(name: []const u8) bool {
    return std.mem.eql(u8, name, "runtime_tls_bump_main.bumpTls") or
        std.mem.eql(u8, name, "runtime_side_effect_free_main.sideEffectFree") or
        std.mem.eql(u8, name, "runtime_hidden_access_main.getHidden") or
        std.mem.eql(u8, name, "runtime_hidden_access_main.updateHidden") or
        std.mem.eql(u8, name, "runtime_mix_c_add_zig_main.add_zig") or
        std.mem.eql(u8, name, "runtime_mix_c_add_may_panic_main.add_may_panic");
}

fn functionDirectlyCalls(function: ir.Function, callee_name: []const u8) bool {
    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            const call = switch (instruction.kind) {
                .call => |call| call,
                else => continue,
            };
            if (std.mem.eql(u8, call.callee, callee_name)) return true;
        }
    }
    return false;
}

pub fn buildStructuredDirectModule(
    allocator: std.mem.Allocator,
    io: std.Io,
    case: IrWriterCase,
) !ir.Module {
    var direct = try sib.DirectBuilder.init(allocator, "zllvm-structured-direct", "x86_64-unknown-linux-gnu");
    errdefer direct.deinit();
    direct.activate();
    defer direct.deactivate();

    var discard_buffer: [4096]u8 = undefined;
    var discard_writer: std.Io.Writer.Discarding = .init(&discard_buffer);
    if (!try zsl.emitSurface(case.surface, &discard_writer.writer)) {
        try case.write(io, &discard_writer.writer, "<zllvm-structured-direct>");
    }
    return direct.finish();
}

pub fn buildStructuredDirectModuleFromDescriptor(
    allocator: std.mem.Allocator,
    io: std.Io,
    descriptor: sd.Descriptor,
) !ir.Module {
    var direct = try sib.DirectBuilder.init(allocator, "zllvm-semantic-descriptor", "x86_64-unknown-linux-gnu");
    errdefer direct.deinit();
    direct.activate();
    defer direct.deactivate();

    var discard_buffer: [4096]u8 = undefined;
    var discard_writer: std.Io.Writer.Discarding = .init(&discard_buffer);
    sd.emit(descriptor, &discard_writer.writer) catch |err| switch (err) {
        error.UnsupportedDescriptorConstruct => {
            try fatal(io, "unsupported semantic descriptor construct={s} wrapper={s} fixture={s} mode={s} source_tag={s}\n", .{ descriptor.surface, descriptor.source.wrapper, descriptor.source.fixture, descriptor.source.mode, descriptor.source.tag });
        },
        else => return err,
    };
    return direct.finish();
}

pub fn runStructuredDirectAcceptedPipeline(
    allocator: std.mem.Allocator,
    io: std.Io,
    module: *ir.Module,
    environ: *const std.process.Environ.Map,
    case: IrWriterCase,
) !void {
    try runStructuredDirectAcceptedPipelineForSurface(allocator, io, module, environ, case.surface);
}

pub fn runStructuredDirectAcceptedPipelineForSurface(
    allocator: std.mem.Allocator,
    io: std.Io,
    module: *ir.Module,
    environ: *const std.process.Environ.Map,
    surface: []const u8,
) !void {
    const pipeline_mode = environ.get("ZLLVM_PIPELINE") orelse return;
    if (!std.mem.eql(u8, pipeline_mode, "preopt")) return;
    if (environ.get("ZLLVM_ZIG_MODE") == null) return;
    if (structuredDirectFoldPipelineReason(surface) == null) return;

    var discard_buffer: [4096]u8 = undefined;
    var discard_writer: std.Io.Writer.Discarding = .init(&discard_buffer);
    try compilation.prepare(allocator, io, module, &discard_writer.writer, .{
        .optimization = "sccp,simplifycfg,instcombine,dce",
        .passes = .{ .verify_each_pass = false },
    });
}

pub const StructuredDirectFoldPipelineSurface = struct {
    surface: []const u8,
    reason: []const u8,
};

pub const structured_direct_fold_pipeline_surfaces = [_]StructuredDirectFoldPipelineSurface{
    .{ .surface = "scalar-add-ret", .reason = "fold scalar identity arithmetic emitted by structured direct rows" },
    .{ .surface = "integer-arithmetic", .reason = "fold integer arithmetic and compare/select constants before object emission" },
    .{ .surface = "error-switch-select", .reason = "fold selected error classifier branches into the expected i32 return" },
    .{ .surface = "runtime-phi-merge", .reason = "fold selected PHI merge constants before x86_64 lowering" },
    .{ .surface = "struct-field-sum", .reason = "fold aggregate field loads/adds into the selected return shape" },
    .{ .surface = "float-select", .reason = "fold selected fcmp/select wrapper main checks" },
    .{ .surface = "packed-replace-low", .reason = "fold packed-bit mask/insert arithmetic in selected rows" },
};

pub fn structuredDirectFoldPipelineReason(surface: []const u8) ?[]const u8 {
    for (structured_direct_fold_pipeline_surfaces) |entry| {
        if (std.mem.eql(u8, surface, entry.surface)) return entry.reason;
    }
    return null;
}

pub fn resolveDirectIrWriterCase(contents: []const u8) ?IrWriterCase {
    const construction = readHeaderValue(contents, "; zllvm_ir_writer_construction = \"") orelse return null;
    if (!std.mem.eql(u8, construction, IrConstruction.structured_builder.marker())) return null;
    const dispatch = readHeaderValue(contents, "; zllvm_ir_writer_dispatch = \"") orelse "case-id";
    if (std.mem.eql(u8, dispatch, source_owned_dispatch_name)) {
        return null;
    }
    if (std.mem.eql(u8, dispatch, source_wrapper_dispatch_name)) {
        const wrapper = readHeaderValue(contents, "; zllvm_ir_writer_wrapper = \"") orelse return null;
        const mode = readHeaderValue(contents, "; zllvm_ir_writer_mode = \"") orelse return null;
        return resolveSourceWrapperDispatchCase(wrapper, mode);
    }
    const case_id = readHeaderValue(contents, "; zllvm_ir_writer_case = \"") orelse return null;
    return findIrWriterCase(case_id);
}

pub fn resolveDirectSemanticDescriptor(io: std.Io, contents: []const u8) ?sd.Descriptor {
    const ownership = readHeaderValue(contents, "; zllvm_semantic_descriptor = \"") orelse return null;
    if (!std.mem.eql(u8, ownership, "descriptor-owned")) return null;
    const wrapper = readHeaderValue(contents, "; zllvm_ir_writer_wrapper = \"") orelse {
        fatal(io, "semantic descriptor artifact is missing wrapper metadata\n", .{});
    };
    const mode = readHeaderValue(contents, "; zllvm_ir_writer_mode = \"") orelse {
        fatal(io, "semantic descriptor artifact is missing mode metadata\n", .{});
    };
    const source_fixture = readHeaderValue(contents, "; zllvm_ir_writer_source_fixture = \"") orelse {
        fatal(io, "semantic descriptor artifact is missing fixture metadata\n", .{});
    };
    const source_tag = readHeaderValue(contents, "; zllvm_ir_writer_source_tag = \"") orelse {
        fatal(io, "semantic descriptor artifact is missing source tag metadata\n", .{});
    };
    const body_name = readHeaderValue(contents, "; zllvm_semantic_descriptor_body = \"") orelse {
        fatal(io, "semantic descriptor artifact is missing descriptor body metadata\n", .{});
    };
    const diagnostic_surface = readHeaderValue(contents, "; zllvm_ir_writer_surface = \"") orelse {
        fatal(io, "semantic descriptor artifact is missing diagnostic surface metadata\n", .{});
    };
    const full_descriptor_program = readHeaderValue(contents, "; zllvm_full_descriptor_program = \"") orelse "not-used";
    const descriptor = if (std.mem.eql(u8, full_descriptor_program, "used")) blk: {
        const serialized_ret = readHeaderValue(contents, "; zllvm_serialized_return_i32 = \"") orelse {
            fatal(io, "semantic descriptor artifact is missing serialized return metadata\n", .{});
        };
        if (!std.mem.eql(u8, serialized_ret, "-1")) {
            const ret_i32 = std.fmt.parseInt(i32, serialized_ret, 10) catch {
                fatal(io, "semantic descriptor artifact has invalid serialized return metadata: {s}\n", .{serialized_ret});
            };
            break :blk sd.resolveSourceOwnedFromSerializedReturn(wrapper, mode, source_fixture, source_tag, body_name, diagnostic_surface, "patched-zig-hook", .unknown, ret_i32);
        }
        const descriptor_path = readHeaderValue(contents, "; zllvm_semantic_descriptor_path = \"") orelse {
            fatal(io, "semantic descriptor artifact is missing descriptor path metadata\n", .{});
        };
        const descriptor_contents = std.Io.Dir.cwd().readFileAlloc(io, descriptor_path, std.heap.page_allocator, .limited(1024 * 1024)) catch {
            fatal(io, "semantic descriptor artifact cannot read descriptor path metadata: {s}\n", .{descriptor_path});
        };
        break :blk sd.resolveSourceOwnedFromInput(descriptor_contents);
    } else sd.resolveSourceOwnedFromBody(wrapper, mode, source_fixture, source_tag, body_name, diagnostic_surface);
    const resolved_descriptor = descriptor orelse {
        fatal(io, "unsupported semantic descriptor construct=source-derived-artifact wrapper={s} fixture={s} mode={s} source_tag={s} body={s}\n", .{ wrapper, source_fixture, mode, source_tag, body_name });
    };
    if (sd.firstUnsupportedConstruct(resolved_descriptor)) |construct| {
        fatal(io, "unsupported semantic descriptor construct={s} wrapper={s} fixture={s} mode={s} source_tag={s}\n", .{ construct, wrapper, source_fixture, mode, source_tag });
    }
    return resolved_descriptor;
}

fn readHeaderValue(contents: []const u8, prefix: []const u8) ?[]const u8 {
    const start = std.mem.indexOf(u8, contents, prefix) orelse return null;
    const value_start = start + prefix.len;
    const end = std.mem.indexOfScalarPos(u8, contents, value_start, '"') orelse return null;
    return contents[value_start..end];
}

fn requiredEnv(io: std.Io, environ: *const std.process.Environ.Map, name: []const u8) []const u8 {
    return environ.get(name) orelse fatal(io, "missing required external IR writer env {s}\n", .{name});
}

fn envEquals(environ: *const std.process.Environ.Map, name: []const u8, expected: []const u8) bool {
    const value = environ.get(name) orelse return false;
    return std.mem.eql(u8, value, expected);
}

const case_data = @import("main_flow_ir_writer_cases.zig");

pub const IrWriterBodyFn = case_data.IrWriterBodyFn;
pub const IrConstruction = case_data.IrConstruction;
pub const IrWriterCase = case_data.IrWriterCase;
const CodegenOwnership = case_data.CodegenOwnership;
const StructuredLoweringOwnership = case_data.StructuredLoweringOwnership;
const findIrWriterCase = case_data.findIrWriterCase;
const resolveSourceWrapperDispatchCase = case_data.resolveSourceWrapperDispatchCase;
const resolveReleaseSourceOwnedDispatchCase = case_data.resolveReleaseSourceOwnedDispatchCase;
const codegenOwnershipForCase = case_data.codegenOwnershipForCase;
const structuredLoweringOwnershipForCase = case_data.structuredLoweringOwnershipForCase;
const semanticProgramForCase = case_data.semanticProgramForCase;
const writeMinimalIrWriterBody = case_data.writeMinimalIrWriterBody;
