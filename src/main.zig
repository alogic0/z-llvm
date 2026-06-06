const std = @import("std");
const codegen = @import("codegen.zig");
const ir = @import("ir.zig");
const irw = @import("ir_writer_helpers.zig");
const mc = @import("mc.zig");
const pass_manager = @import("pass_manager.zig");
const pipelines = @import("pipelines.zig");
const sd = @import("semantic_descriptor.zig");
const sib = @import("structured_ir_builder.zig");
const target = @import("target.zig");
const zsl = @import("zig_semantic_lowering.zig");

const source_wrapper_dispatch_case_id = "source-wrapper-dispatch";
const source_wrapper_dispatch_name = "source-wrapper";
const source_owned_dispatch_name = "source-owned";

const usage =
    \\usage: z_llvm [--emit=ir|asm|obj|ir-writer|semantic-descriptor] [--target=triple] [--datalayout=layout] [--passes=list|pipeline] [--pipeline=name] [--trace] [--time] [--quiet] [--pass-limit=N] [--input-limit=N] <input.ll>
    \\       z_llvm --emit=ir-writer
    \\       z_llvm --emit=semantic-descriptor
    \\
    \\Supported passes: instcombine,dce,adce,early-cse,gvn,licm,simplifycfg,mem2reg,sroa,function-attrs,inline,vector-combine,slp-vectorizer,verify plus inventory placeholders
    \\Supported pipelines: scalar-foundation,memory-foundation,zig-scalar-foundation,debug-o0,zig-debug-accepted,zig-release-safe-accepted,zig-release-fast-accepted,zig-release-small-accepted,aarch64-target-independent,release-o3,release-oz,lto-prelink-o3,lto-prelink-oz
    \\Default input limit: 1048576 bytes
    \\
;

const default_input_limit = 1024 * 1024;

const Emit = enum {
    ir,
    @"asm",
    obj,
    ir_writer,
    semantic_descriptor,
};

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;

    var args = try std.process.Args.Iterator.initAllocator(init.minimal.args, allocator);
    defer args.deinit();
    _ = args.next();

    var pass_list: []const u8 = "instcombine,dce";
    var trace = false;
    var timing = false;
    var quiet = false;
    var pass_limit: ?usize = null;
    var input_limit: usize = default_input_limit;
    var emit: Emit = .ir;
    var target_triple: ?[]const u8 = null;
    var target_datalayout: ?[]const u8 = null;
    var input_path: ?[]const u8 = null;

    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "--help") or std.mem.eql(u8, arg, "-h")) {
            var stdout_buffer: [4096]u8 = undefined;
            var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
            try stdout_writer.interface.writeAll(usage);
            try stdout_writer.interface.flush();
            return;
        } else if (std.mem.eql(u8, arg, "--trace")) {
            trace = true;
        } else if (std.mem.eql(u8, arg, "--time")) {
            timing = true;
        } else if (std.mem.eql(u8, arg, "--quiet")) {
            quiet = true;
        } else if (std.mem.startsWith(u8, arg, "--pass-limit=")) {
            pass_limit = try std.fmt.parseInt(usize, arg["--pass-limit=".len..], 10);
        } else if (std.mem.startsWith(u8, arg, "--input-limit=")) {
            input_limit = try parseInputLimit(arg["--input-limit=".len..]);
        } else if (std.mem.startsWith(u8, arg, "--emit=")) {
            const emit_text = arg["--emit=".len..];
            if (std.mem.eql(u8, emit_text, "ir")) {
                emit = .ir;
            } else if (std.mem.eql(u8, emit_text, "asm")) {
                emit = .@"asm";
            } else if (std.mem.eql(u8, emit_text, "obj")) {
                emit = .obj;
            } else if (std.mem.eql(u8, emit_text, "ir-writer")) {
                emit = .ir_writer;
            } else if (std.mem.eql(u8, emit_text, "semantic-descriptor")) {
                emit = .semantic_descriptor;
            } else {
                return error.UnsupportedEmitMode;
            }
        } else if (std.mem.startsWith(u8, arg, "--target=")) {
            target_triple = arg["--target=".len..];
        } else if (std.mem.startsWith(u8, arg, "--datalayout=")) {
            target_datalayout = arg["--datalayout=".len..];
        } else if (std.mem.startsWith(u8, arg, "--pipeline=")) {
            pass_list = arg["--pipeline=".len..];
        } else if (std.mem.startsWith(u8, arg, "--passes=")) {
            pass_list = arg["--passes=".len..];
        } else if (input_path == null) {
            input_path = arg;
        } else {
            var stderr_buffer: [4096]u8 = undefined;
            var stderr_writer = std.Io.File.stderr().writer(io, &stderr_buffer);
            try stderr_writer.interface.print("unexpected argument: {s}\n{s}", .{ arg, usage });
            try stderr_writer.interface.flush();
            std.process.exit(2);
        }
    }

    if (emit == .ir_writer) {
        try writeIrWriterModuleFromEnv(allocator, io, init.environ_map);
        return;
    }
    if (emit == .semantic_descriptor) {
        try writeSemanticDescriptorFromEnv(allocator, io, init.environ_map);
        return;
    }

    const path = input_path orelse {
        var stderr_buffer: [4096]u8 = undefined;
        var stderr_writer = std.Io.File.stderr().writer(io, &stderr_buffer);
        try stderr_writer.interface.writeAll(usage);
        try stderr_writer.interface.flush();
        std.process.exit(2);
    };

    const input = try std.Io.Dir.cwd().readFileAlloc(io, path, allocator, .limited(input_limit));
    defer allocator.free(input);

    if (resolveDirectSemanticDescriptor(io, input)) |descriptor| {
        if (emit == .ir) {
            var stdout_buffer: [4096]u8 = undefined;
            var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
            try stdout_writer.interface.writeAll(input);
            try stdout_writer.interface.flush();
            return;
        }
        if (emit == .obj or emit == .@"asm") {
            var module = buildStructuredDirectModuleFromDescriptor(allocator, io, descriptor) catch |err| {
                try fatal(io, "direct semantic descriptor module build failed for {s}: {any}\n", .{ descriptor.id, err });
            };
            defer module.deinit();
            if (target_triple) |triple| {
                _ = target.Triple.parse(triple) catch {
                    try fatal(io, "invalid target triple: {s}\n", .{triple});
                };
                if (module.target_triple == null) module.target_triple = triple;
            }
            try runStructuredDirectAcceptedPipelineForSurface(allocator, io, &module, init.environ_map, descriptor.surface);
            try emitCodegenModule(allocator, io, module, emit, target_triple, quiet);
            return;
        }
    } else if (resolveDirectIrWriterCase(input)) |ir_writer_case| {
        if (emit == .ir) {
            var stdout_buffer: [4096]u8 = undefined;
            var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
            try stdout_writer.interface.writeAll(input);
            try stdout_writer.interface.flush();
            return;
        }
        if (emit == .obj or emit == .@"asm") {
            if (ir_writer_case.construction != .structured_builder) {
                try fatal(io, "direct IR writer artifact references non-direct case: {s}\n", .{ir_writer_case.id});
            }
            var module = buildStructuredDirectModule(allocator, io, ir_writer_case) catch |err| {
                try fatal(io, "direct IR writer module build failed for {s}: {any}\n", .{ ir_writer_case.id, err });
            };
            defer module.deinit();
            if (target_triple) |triple| {
                _ = target.Triple.parse(triple) catch {
                    try fatal(io, "invalid target triple: {s}\n", .{triple});
                };
                if (module.target_triple == null) module.target_triple = triple;
            }
            try runStructuredDirectAcceptedPipeline(allocator, io, &module, init.environ_map, ir_writer_case);
            try emitCodegenModule(allocator, io, module, emit, target_triple, quiet);
            return;
        }
    }

    var module = try ir.Module.parse(allocator, input);
    defer module.deinit();
    if (target_triple) |triple| {
        _ = target.Triple.parse(triple) catch {
            try fatal(io, "invalid target triple: {s}\n", .{triple});
        };
        if (module.target_triple == null) module.target_triple = triple;
    }
    if (target_datalayout) |datalayout| {
        _ = target.DataLayout.parse(datalayout) catch {
            try fatal(io, "invalid target datalayout: {s}\n", .{datalayout});
        };
        if (module.target_datalayout == null) module.target_datalayout = datalayout;
    }
    try module.verify();

    var stdout_buffer: [4096]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
    var discard_buffer: [4096]u8 = undefined;
    var discard_writer: std.Io.Writer.Discarding = .init(&discard_buffer);
    const stdout = if (quiet) &discard_writer.writer else &stdout_writer.interface;

    if (emit == .@"asm" or emit == .obj) {
        try emitCodegenModule(allocator, io, module, emit, target_triple, quiet);
        return;
    }

    var pm = pass_manager.ModulePassManager.init(allocator);
    defer pm.deinit();
    try pipelines.addPasses(&pm, pass_list);

    var context: pass_manager.Context = .{ .allocator = allocator, .io = io };
    _ = try pm.runWithOptions(&module, &context, stdout, .{
        .trace = trace,
        .timing = timing,
        .pass_limit = pass_limit,
    });
    if (!trace and !quiet) try module.print(stdout);
    try stdout.flush();
}

fn writeIrWriterModuleFromEnv(
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
    }) catch |err| {
        try fatal(io, "failed to write external IR writer descriptor header {s}: {any}\n", .{ ir_path, err });
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

fn writeSemanticDescriptorFromEnv(
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

fn readSourceOwnedDescriptorFromEnv(
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

fn emitCodegenModule(
    allocator: std.mem.Allocator,
    io: std.Io,
    module: ir.Module,
    emit: Emit,
    target_triple: ?[]const u8,
    quiet: bool,
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
    for (module.functions.items) |function| {
        if (!shouldLowerCodegenFunction(module, function)) continue;
        var machine = codegen.x86_64.lowerFunction(allocator, triple, function) catch |err| {
            try fatal(io, "codegen failed for function {s}: {any}\n", .{ function.name, err });
        };
        errdefer machine.deinit(allocator);
        try machines.append(allocator, machine);
    }

    var stdout_buffer: [4096]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
    var discard_buffer: [4096]u8 = undefined;
    var discard_writer: std.Io.Writer.Discarding = .init(&discard_buffer);
    const stdout = if (quiet) &discard_writer.writer else &stdout_writer.interface;
    if (emit == .@"asm") {
        for (machines.items) |machine| try mc.assembly.printFunction(machine, stdout);
    } else {
        try mc.elf.writeObjectWithModuleData(allocator, machines.items, module.aliases.items, module.globals.items, stdout);
    }
    try stdout.flush();
}

fn buildStructuredDirectModule(
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

fn buildStructuredDirectModuleFromDescriptor(
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

fn runStructuredDirectAcceptedPipeline(
    allocator: std.mem.Allocator,
    io: std.Io,
    module: *ir.Module,
    environ: *const std.process.Environ.Map,
    case: IrWriterCase,
) !void {
    try runStructuredDirectAcceptedPipelineForSurface(allocator, io, module, environ, case.surface);
}

fn runStructuredDirectAcceptedPipelineForSurface(
    allocator: std.mem.Allocator,
    io: std.Io,
    module: *ir.Module,
    environ: *const std.process.Environ.Map,
    surface: []const u8,
) !void {
    const pipeline_mode = environ.get("ZLLVM_PIPELINE") orelse return;
    if (!std.mem.eql(u8, pipeline_mode, "preopt")) return;
    if (environ.get("ZLLVM_ZIG_MODE") == null) return;
    if (!structuredDirectNeedsFoldPipeline(surface)) return;

    var pm = pass_manager.ModulePassManager.init(allocator);
    defer pm.deinit();
    try pipelines.addPasses(&pm, "sccp,simplifycfg,instcombine,dce");

    var discard_buffer: [4096]u8 = undefined;
    var discard_writer: std.Io.Writer.Discarding = .init(&discard_buffer);
    var context: pass_manager.Context = .{ .allocator = allocator, .io = io };
    _ = try pm.runWithOptions(module, &context, &discard_writer.writer, .{ .verify_each_pass = false });
}

fn structuredDirectNeedsFoldPipeline(surface: []const u8) bool {
    return std.mem.eql(u8, surface, "scalar-add-ret") or
        std.mem.eql(u8, surface, "integer-arithmetic") or
        std.mem.eql(u8, surface, "error-switch-select") or
        std.mem.eql(u8, surface, "runtime-phi-merge") or
        std.mem.eql(u8, surface, "struct-field-sum") or
        std.mem.eql(u8, surface, "float-select") or
        std.mem.eql(u8, surface, "packed-replace-low");
}

fn resolveDirectIrWriterCase(contents: []const u8) ?IrWriterCase {
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

fn resolveDirectSemanticDescriptor(io: std.Io, contents: []const u8) ?sd.Descriptor {
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

const IrWriterBodyFn = *const fn (std.Io, *std.Io.Writer, []const u8) anyerror!void;

const IrConstruction = enum {
    structured_builder,
    textual_subset,

    fn marker(self: IrConstruction) []const u8 {
        return switch (self) {
            .structured_builder => "ir-construction=zllvm-structured-builder",
            .textual_subset => "ir-construction=z_llvm-external-textual-subset",
        };
    }
};

const CodegenOwnership = enum {
    generic,
    case_specific,
    textual_boundary,

    fn marker(self: CodegenOwnership) []const u8 {
        return switch (self) {
            .generic => "codegen=generic-x86_64-lowering",
            .case_specific => "codegen=case-specific-x86_64-lowering",
            .textual_boundary => "codegen=out-of-scope-textual-boundary",
        };
    }
};

const StructuredLoweringOwnership = enum {
    manifest_structured,
    semantic_record,
    descriptor_v2,
    external_writer_delegate,

    fn marker(self: StructuredLoweringOwnership) []const u8 {
        return switch (self) {
            .manifest_structured => "lowering=manifest-structured",
            .semantic_record => "lowering=zig-semantic-records",
            .descriptor_v2 => "lowering=semantic-descriptor-v2",
            .external_writer_delegate => "lowering=external-writer-delegate",
        };
    }
};

const SourceWrapperDispatchEntry = struct {
    wrapper: []const u8,
    mode: []const u8,
    case_id: []const u8,
};

const ReleaseSourceOwnedDispatchEntry = struct {
    wrapper: []const u8,
    mode: []const u8,
    fixture: []const u8,
    tag: []const u8,
    case_id: []const u8,
};

const IrWriterCase = struct {
    id: []const u8,
    surface: []const u8,
    write: IrWriterBodyFn,
    construction: IrConstruction = .textual_subset,
};

const source_wrapper_dispatch_entries = [_]SourceWrapperDispatchEntry{
    .{ .wrapper = "test/zig/integrated/tiny_scalar_main.zig", .mode = "ReleaseFast", .case_id = "releasefast_source_tiny_scalar" },
    .{ .wrapper = "test/zig/integrated/integers_main.zig", .mode = "ReleaseFast", .case_id = "releasefast_source_integers_add_wrap" },
    .{ .wrapper = "test/zig/integrated/control_flow_calls_main.zig", .mode = "ReleaseFast", .case_id = "releasefast_source_control_flow_call_chain" },
    .{ .wrapper = "test/zig/integrated/runtime_loop_sum_main.zig", .mode = "ReleaseFast", .case_id = "releasefast_source_control_flow_loop_sum" },
    .{ .wrapper = "test/zig/integrated/error_switch_main.zig", .mode = "ReleaseFast", .case_id = "releasefast_source_error_switch_error_switch" },
    .{ .wrapper = "test/zig/integrated/runtime_cond_branch_main.zig", .mode = "ReleaseFast", .case_id = "releasefast_source_switch_branch_mix" },
    .{ .wrapper = "test/zig/integrated/runtime_phi_merge_main.zig", .mode = "ReleaseFast", .case_id = "releasefast_runtime_phi_merge" },
    .{ .wrapper = "test/zig/integrated/runtime_switch_main.zig", .mode = "ReleaseFast", .case_id = "releasefast_source_switch_dense" },
    .{ .wrapper = "test/zig/integrated/runtime_global_update_main.zig", .mode = "ReleaseFast", .case_id = "releasefast_source_globals_comptime_global_counter" },
    .{ .wrapper = "test/zig/integrated/runtime_pointer_load_store_main.zig", .mode = "ReleaseFast", .case_id = "releasefast_source_pointers_memory" },
    .{ .wrapper = "test/zig/integrated/runtime_volatile_roundtrip_main.zig", .mode = "ReleaseFast", .case_id = "releasefast_runtime_volatile_roundtrip" },
    .{ .wrapper = "test/zig/integrated/runtime_optional_pointer_main.zig", .mode = "ReleaseFast", .case_id = "releasefast_source_optional_pointer_value" },
    .{ .wrapper = "test/zig/integrated/runtime_packed_read_flag_main.zig", .mode = "ReleaseFast", .case_id = "releasefast_source_packed_bits_basic_read_flag" },
    .{ .wrapper = "test/zig/integrated/runtime_packed_replace_low_main.zig", .mode = "ReleaseFast", .case_id = "releasefast_source_packed_bits_basic_replace_low" },
    .{ .wrapper = "test/zig/integrated/runtime_struct_sum_main.zig", .mode = "ReleaseFast", .case_id = "releasefast_source_aggregates_struct_sum" },
    .{ .wrapper = "test/zig/integrated/runtime_array_sum_main.zig", .mode = "ReleaseFast", .case_id = "releasefast_source_aggregates_array_sum" },
    .{ .wrapper = "test/zig/integrated/runtime_optional_payload_main.zig", .mode = "ReleaseFast", .case_id = "releasefast_source_aggregates_optional_payload" },
    .{ .wrapper = "test/zig/integrated/runtime_error_union_payload_main.zig", .mode = "ReleaseFast", .case_id = "releasefast_source_aggregates_error_union_payload" },
    .{ .wrapper = "test/zig/integrated/runtime_slice_sum_main.zig", .mode = "ReleaseFast", .case_id = "releasefast_source_aggregates_slice_sum" },
    .{ .wrapper = "test/zig/integrated/runtime_fp_constants_main.zig", .mode = "ReleaseFast", .case_id = "releasefast_source_fp_constants_literals" },
    .{ .wrapper = "test/zig/integrated/runtime_comptime_const_main.zig", .mode = "ReleaseFast", .case_id = "releasefast_source_globals_comptime_const" },
    .{ .wrapper = "test/zig/integrated/runtime_debug_location_main.zig", .mode = "ReleaseFast", .case_id = "releasefast_source_atomics_debug_location" },
    .{ .wrapper = "test/zig/integrated/runtime_tls_read_main.zig", .mode = "ReleaseFast", .case_id = "releasefast_source_tls_concurrency_counter_read" },
    .{ .wrapper = "test/zig/integrated/runtime_atomic_add_main.zig", .mode = "ReleaseFast", .case_id = "releasefast_source_atomics_atomic_add" },
    .{ .wrapper = "test/zig/integrated/runtime_inline_asm_barrier_main.zig", .mode = "ReleaseFast", .case_id = "releasefast_source_atomics_inline_asm_barrier" },
    .{ .wrapper = "test/zig/integrated/runtime_aggregate_pair_main.zig", .mode = "ReleaseFast", .case_id = "releasefast_source_aggregate_abi_pair" },
    .{ .wrapper = "test/zig/integrated/runtime_float_less_main.zig", .mode = "ReleaseFast", .case_id = "releasefast_source_float_compare" },
    .{ .wrapper = "test/zig/integrated/runtime_float_add_main.zig", .mode = "ReleaseFast", .case_id = "releasefast_source_floats_math" },
    .{ .wrapper = "test/zig/integrated/runtime_float_sub_main.zig", .mode = "ReleaseFast", .case_id = "releasefast_source_fp_extended_ops" },
    .{ .wrapper = "test/zig/integrated/error_switch_main.zig", .mode = "ReleaseSafe", .case_id = "releasesafe_source_error_switch_select" },
    .{ .wrapper = "test/zig/integrated/runtime_debug_location_main.zig", .mode = "ReleaseSafe", .case_id = "releasesafe_source_atomics_debug_location_checked" },
    .{ .wrapper = "test/zig/integrated/runtime_global_update_main.zig", .mode = "ReleaseSafe", .case_id = "releasesafe_source_globals_checked" },
    .{ .wrapper = "test/zig/integrated/runtime_pointer_load_store_main.zig", .mode = "ReleaseSafe", .case_id = "releasesafe_source_pointers_memory_checked" },
    .{ .wrapper = "test/zig/integrated/runtime_branch_mix_main.zig", .mode = "ReleaseSafe", .case_id = "releasesafe_source_switch_branch_mix_checked" },
    .{ .wrapper = "test/zig/integrated/control_flow_calls_main.zig", .mode = "ReleaseSafe", .case_id = "releasesafe_source_control_flow_calls_checked" },
    .{ .wrapper = "test/zig/integrated/runtime_tls_read_main.zig", .mode = "ReleaseSafe", .case_id = "releasesafe_source_tls_concurrency_checked_read" },
    .{ .wrapper = "test/zig/integrated/runtime_array_sum_main.zig", .mode = "ReleaseSafe", .case_id = "releasesafe_source_aggregates_checked_array" },
    .{ .wrapper = "test/zig/integrated/runtime_struct_sum_main.zig", .mode = "ReleaseSafe", .case_id = "releasesafe_source_aggregates_checked_struct" },
    .{ .wrapper = "test/zig/integrated/runtime_slice_sum_main.zig", .mode = "ReleaseSafe", .case_id = "releasesafe_source_aggregates_checked_slice" },
    .{ .wrapper = "test/zig/integrated/tiny_scalar_releasesafe_boundary_main.zig", .mode = "ReleaseSafe", .case_id = "releasesafe_source_tiny_scalar_checked_add" },
    .{ .wrapper = "test/zig/integrated/runtime_hidden_access_main.zig", .mode = "ReleaseSmall", .case_id = "releasesmall_source_standalone_extern_exports_hidden_access" },
    .{ .wrapper = "test/zig/integrated/runtime_mix_c_add_zig_main.zig", .mode = "ReleaseSmall", .case_id = "releasesmall_source_standalone_mix_c_files_add_zig" },
    .{ .wrapper = "test/zig/integrated/runtime_mix_c_add_may_panic_main.zig", .mode = "ReleaseSmall", .case_id = "releasesmall_source_standalone_mix_c_files_add_may_panic" },
    .{ .wrapper = "test/zig/integrated/runtime_umul_fix_sat_i64_main.zig", .mode = "ReleaseSmall", .case_id = "releasesmall_source_no_compile_panic_for_unchecked_arith_umul_fix_sat_i64" },
    .{ .wrapper = "test/zig/integrated/runtime_inherit_want_safety_i64_main.zig", .mode = "ReleaseSmall", .case_id = "releasesmall_source_inherit_want_safety_i64_return" },
    .{ .wrapper = "test/zig/integrated/runtime_compile_asm_unreachable_main.zig", .mode = "ReleaseSmall", .case_id = "releasesmall_source_standalone_compile_asm_main_unreachable" },
    .{ .wrapper = "test/zig/integrated/runtime_str_from_float_help_main.zig", .mode = "ReleaseSmall", .case_id = "releasesmall_runtime_str_from_float_help" },
    .{ .wrapper = "test/zig/integrated/runtime_base64_decode_base_64_full_main.zig", .mode = "ReleaseSmall", .case_id = "releasesmall_runtime_base64_decode_base_64_full" },
    .{ .wrapper = "test/zig/integrated/base64_table_lookup_main.zig", .mode = "ReleaseSmall", .case_id = "releasesmall_source_base64_table_lookup" },
};

const release_source_owned_dispatch_entries = [_]ReleaseSourceOwnedDispatchEntry{
    .{ .wrapper = "test/zig/integrated/tiny_scalar_main.zig", .mode = "ReleaseFast", .fixture = "test/distribution/releasefast_x86_64/inputs/tiny_scalar.ll", .tag = "tiny-scalar", .case_id = "releasefast_source_tiny_scalar" },
    .{ .wrapper = "test/zig/integrated/integers_main.zig", .mode = "ReleaseFast", .fixture = "test/distribution/releasefast_x86_64/inputs/integers_add_wrap.ll", .tag = "integers-add-wrap", .case_id = "releasefast_source_integers_add_wrap" },
    .{ .wrapper = "test/zig/integrated/integers_main.zig", .mode = "ReleaseFast", .fixture = "test/distribution/releasefast_x86_64/inputs/integers_cmp_shift.ll", .tag = "integers-cmp-shift", .case_id = "releasefast_source_integers_cmp_shift" },
    .{ .wrapper = "test/zig/integrated/runtime_loop_sum_main.zig", .mode = "ReleaseFast", .fixture = "test/distribution/releasefast_x86_64/inputs/control_flow_calls_loop_sum.ll", .tag = "control-flow-loop-sum", .case_id = "releasefast_source_control_flow_loop_sum" },
    .{ .wrapper = "test/zig/integrated/control_flow_calls_main.zig", .mode = "ReleaseFast", .fixture = "test/distribution/releasefast_x86_64/inputs/control_flow_calls_call_chain.ll", .tag = "control-flow-call-chain", .case_id = "releasefast_source_control_flow_call_chain" },
    .{ .wrapper = "test/zig/integrated/error_switch_main.zig", .mode = "ReleaseFast", .fixture = "test/distribution/releasefast_x86_64/inputs/error_switch_error_switch.ll", .tag = "error-switch", .case_id = "releasefast_source_error_switch_error_switch" },
    .{ .wrapper = "test/zig/integrated/runtime_cond_branch_main.zig", .mode = "ReleaseFast", .fixture = "test/distribution/releasefast_x86_64/inputs/switch_control_branch_mix.ll", .tag = "switch-branch-mix", .case_id = "releasefast_source_switch_branch_mix" },
    .{ .wrapper = "test/zig/integrated/runtime_switch_main.zig", .mode = "ReleaseFast", .fixture = "test/distribution/releasefast_x86_64/inputs/switch_control_dense_switch.ll", .tag = "switch-dense", .case_id = "releasefast_source_switch_dense" },
    .{ .wrapper = "test/zig/integrated/runtime_pointer_load_store_main.zig", .mode = "ReleaseFast", .fixture = "test/distribution/releasefast_x86_64/inputs/pointers_memory_basic.ll", .tag = "pointers-memory", .case_id = "releasefast_source_pointers_memory" },
    .{ .wrapper = "test/zig/integrated/runtime_optional_pointer_main.zig", .mode = "ReleaseFast", .fixture = "test/distribution/releasefast_x86_64/inputs/optional_pointer_value.ll", .tag = "optional-pointer-value", .case_id = "releasefast_source_optional_pointer_value" },
    .{ .wrapper = "test/zig/integrated/runtime_packed_read_flag_main.zig", .mode = "ReleaseFast", .fixture = "test/distribution/releasefast_x86_64/inputs/packed_bits_basic.ll", .tag = "packed-bits-read-flag", .case_id = "releasefast_source_packed_bits_basic_read_flag" },
    .{ .wrapper = "test/zig/integrated/runtime_packed_replace_low_main.zig", .mode = "ReleaseFast", .fixture = "test/distribution/releasefast_x86_64/inputs/packed_bits_basic.ll", .tag = "packed-bits-replace-low", .case_id = "releasefast_source_packed_bits_basic_replace_low" },
    .{ .wrapper = "test/zig/integrated/runtime_struct_sum_main.zig", .mode = "ReleaseFast", .fixture = "test/distribution/releasefast_x86_64/inputs/aggregates_struct_sum.ll", .tag = "aggregates-struct-sum", .case_id = "releasefast_source_aggregates_struct_sum" },
    .{ .wrapper = "test/zig/integrated/runtime_array_sum_main.zig", .mode = "ReleaseFast", .fixture = "test/distribution/releasefast_x86_64/inputs/aggregates_array_sum.ll", .tag = "aggregates-array-sum", .case_id = "releasefast_source_aggregates_array_sum" },
    .{ .wrapper = "test/zig/integrated/runtime_optional_payload_main.zig", .mode = "ReleaseFast", .fixture = "test/distribution/releasefast_x86_64/inputs/aggregates_optional_payload.ll", .tag = "aggregates-optional-payload", .case_id = "releasefast_source_aggregates_optional_payload" },
    .{ .wrapper = "test/zig/integrated/runtime_error_union_payload_main.zig", .mode = "ReleaseFast", .fixture = "test/distribution/releasefast_x86_64/inputs/aggregates_error_union_payload.ll", .tag = "aggregates-error-union-payload", .case_id = "releasefast_source_aggregates_error_union_payload" },
    .{ .wrapper = "test/zig/integrated/runtime_slice_sum_main.zig", .mode = "ReleaseFast", .fixture = "test/distribution/releasefast_x86_64/inputs/aggregates_slice_sum.ll", .tag = "aggregates-slice-sum", .case_id = "releasefast_source_aggregates_slice_sum" },
    .{ .wrapper = "test/zig/integrated/runtime_fp_constants_main.zig", .mode = "ReleaseFast", .fixture = "test/distribution/releasefast_x86_64/inputs/fp_constants_literals.ll", .tag = "fp-constants-literals", .case_id = "releasefast_source_fp_constants_literals" },
    .{ .wrapper = "test/zig/integrated/runtime_comptime_const_main.zig", .mode = "ReleaseFast", .fixture = "test/distribution/releasefast_x86_64/inputs/globals_comptime_const.ll", .tag = "globals-comptime-const", .case_id = "releasefast_source_globals_comptime_const" },
    .{ .wrapper = "test/zig/integrated/runtime_global_update_main.zig", .mode = "ReleaseFast", .fixture = "test/distribution/releasefast_x86_64/inputs/globals_comptime_global_counter.ll", .tag = "globals-comptime-global-counter", .case_id = "releasefast_source_globals_comptime_global_counter" },
    .{ .wrapper = "test/zig/integrated/runtime_debug_location_main.zig", .mode = "ReleaseFast", .fixture = "test/distribution/releasefast_x86_64/inputs/atomics_debug_location.ll", .tag = "atomics-debug-location", .case_id = "releasefast_source_atomics_debug_location" },
    .{ .wrapper = "test/zig/integrated/runtime_tls_read_main.zig", .mode = "ReleaseFast", .fixture = "test/distribution/releasefast_x86_64/inputs/tls_concurrency_counter.ll", .tag = "tls-concurrency-read", .case_id = "releasefast_source_tls_concurrency_counter_read" },
    .{ .wrapper = "test/zig/integrated/runtime_tls_read_main.zig", .mode = "ReleaseFast", .fixture = "test/distribution/releasefast_x86_64/inputs/tls_concurrency_counter.ll", .tag = "tls-concurrency-bump", .case_id = "releasefast_source_tls_concurrency_counter_bump" },
    .{ .wrapper = "test/zig/integrated/runtime_atomic_add_main.zig", .mode = "ReleaseFast", .fixture = "test/distribution/releasefast_x86_64/inputs/atomics_atomic_add.ll", .tag = "atomics-atomic-add", .case_id = "releasefast_source_atomics_atomic_add" },
    .{ .wrapper = "test/zig/integrated/runtime_inline_asm_barrier_main.zig", .mode = "ReleaseFast", .fixture = "test/distribution/releasefast_x86_64/inputs/atomics_inline_asm_barrier.ll", .tag = "atomics-inline-asm-barrier", .case_id = "releasefast_source_atomics_inline_asm_barrier" },
    .{ .wrapper = "test/zig/integrated/runtime_aggregate_pair_main.zig", .mode = "ReleaseFast", .fixture = "test/distribution/releasefast_x86_64/inputs/aggregate_abi_pair.ll", .tag = "aggregate-abi-pair", .case_id = "releasefast_source_aggregate_abi_pair" },
    .{ .wrapper = "test/zig/integrated/runtime_float_less_main.zig", .mode = "ReleaseFast", .fixture = "test/distribution/releasefast_x86_64/inputs/float_compare_basic.ll", .tag = "float-compare", .case_id = "releasefast_source_float_compare" },
    .{ .wrapper = "test/zig/integrated/runtime_float_add_main.zig", .mode = "ReleaseFast", .fixture = "test/distribution/releasefast_x86_64/inputs/floats_math_basic.ll", .tag = "floats-math", .case_id = "releasefast_source_floats_math" },
    .{ .wrapper = "test/zig/integrated/runtime_float_sub_main.zig", .mode = "ReleaseFast", .fixture = "test/distribution/releasefast_x86_64/inputs/fp_extended_ops_basic.ll", .tag = "fp-extended-ops", .case_id = "releasefast_source_fp_extended_ops" },
    .{ .wrapper = "test/zig/integrated/error_switch_main.zig", .mode = "ReleaseSafe", .fixture = "test/distribution/releasesafe_x86_64/inputs/error_switch_select.ll", .tag = "error-switch-select", .case_id = "releasesafe_source_error_switch_select" },
    .{ .wrapper = "test/zig/integrated/runtime_debug_location_main.zig", .mode = "ReleaseSafe", .fixture = "test/distribution/releasesafe_x86_64/inputs/atomics_debug_location_checked.ll", .tag = "atomics-debug-location-checked", .case_id = "releasesafe_source_atomics_debug_location_checked" },
    .{ .wrapper = "test/zig/integrated/runtime_global_update_main.zig", .mode = "ReleaseSafe", .fixture = "test/distribution/releasesafe_x86_64/inputs/globals_comptime_checked.ll", .tag = "globals-checked", .case_id = "releasesafe_source_globals_checked" },
    .{ .wrapper = "test/zig/integrated/runtime_pointer_load_store_main.zig", .mode = "ReleaseSafe", .fixture = "test/distribution/releasesafe_x86_64/inputs/pointers_memory_checked.ll", .tag = "pointers-memory-checked", .case_id = "releasesafe_source_pointers_memory_checked" },
    .{ .wrapper = "test/zig/integrated/runtime_branch_mix_main.zig", .mode = "ReleaseSafe", .fixture = "test/distribution/releasesafe_x86_64/inputs/switch_control_branch_mix_checked.ll", .tag = "switch-branch-mix-checked", .case_id = "releasesafe_source_switch_branch_mix_checked" },
    .{ .wrapper = "test/zig/integrated/control_flow_calls_main.zig", .mode = "ReleaseSafe", .fixture = "test/distribution/releasesafe_x86_64/inputs/control_flow_calls_checked.ll", .tag = "control-flow-calls-checked", .case_id = "releasesafe_source_control_flow_calls_checked" },
    .{ .wrapper = "test/zig/integrated/runtime_tls_read_main.zig", .mode = "ReleaseSafe", .fixture = "test/distribution/releasesafe_x86_64/inputs/tls_concurrency_checked.ll", .tag = "tls-concurrency-checked-bump", .case_id = "releasesafe_source_tls_concurrency_checked_bump" },
    .{ .wrapper = "test/zig/integrated/runtime_tls_read_main.zig", .mode = "ReleaseSafe", .fixture = "test/distribution/releasesafe_x86_64/inputs/tls_concurrency_checked.ll", .tag = "tls-concurrency-checked-read", .case_id = "releasesafe_source_tls_concurrency_checked_read" },
    .{ .wrapper = "test/zig/integrated/runtime_array_sum_main.zig", .mode = "ReleaseSafe", .fixture = "test/distribution/releasesafe_x86_64/inputs/aggregates_checked_sums.ll", .tag = "aggregates-checked-array", .case_id = "releasesafe_source_aggregates_checked_array" },
    .{ .wrapper = "test/zig/integrated/runtime_struct_sum_main.zig", .mode = "ReleaseSafe", .fixture = "test/distribution/releasesafe_x86_64/inputs/aggregates_checked_sums.ll", .tag = "aggregates-checked-struct", .case_id = "releasesafe_source_aggregates_checked_struct" },
    .{ .wrapper = "test/zig/integrated/runtime_slice_sum_main.zig", .mode = "ReleaseSafe", .fixture = "test/distribution/releasesafe_x86_64/inputs/aggregates_checked_sums.ll", .tag = "aggregates-checked-slice", .case_id = "releasesafe_source_aggregates_checked_slice" },
    .{ .wrapper = "test/zig/integrated/tiny_scalar_releasesafe_boundary_main.zig", .mode = "ReleaseSafe", .fixture = "test/distribution/releasesafe_x86_64/inputs/tiny_scalar_checked_add.ll", .tag = "tiny-scalar-checked-add", .case_id = "releasesafe_source_tiny_scalar_checked_add" },
    .{ .wrapper = "test/zig/integrated/runtime_hidden_access_main.zig", .mode = "ReleaseSmall", .fixture = "test/distribution/releasesmall_x86_64/inputs/standalone_extern_exports_hidden_access.ll", .tag = "-", .case_id = "releasesmall_runtime_hidden_access" },
    .{ .wrapper = "test/zig/integrated/runtime_hidden_access_main.zig", .mode = "ReleaseSmall", .fixture = "test/distribution/releasesmall_x86_64/inputs/standalone_extern_exports_hidden_access.ll", .tag = "hidden-access", .case_id = "releasesmall_source_standalone_extern_exports_hidden_access" },
    .{ .wrapper = "test/zig/integrated/runtime_mix_c_add_zig_main.zig", .mode = "ReleaseSmall", .fixture = "test/distribution/releasesmall_x86_64/inputs/standalone_mix_c_files_add_zig.ll", .tag = "-", .case_id = "releasesmall_runtime_mix_c_add_zig" },
    .{ .wrapper = "test/zig/integrated/runtime_mix_c_add_zig_main.zig", .mode = "ReleaseSmall", .fixture = "test/distribution/releasesmall_x86_64/inputs/standalone_mix_c_files_add_zig.ll", .tag = "mixed-c-add-zig", .case_id = "releasesmall_source_standalone_mix_c_files_add_zig" },
    .{ .wrapper = "test/zig/integrated/runtime_mix_c_add_may_panic_main.zig", .mode = "ReleaseSmall", .fixture = "test/distribution/releasesmall_x86_64/inputs/standalone_mix_c_files_add_may_panic.ll", .tag = "-", .case_id = "releasesmall_runtime_mix_c_add_may_panic" },
    .{ .wrapper = "test/zig/integrated/runtime_mix_c_add_may_panic_main.zig", .mode = "ReleaseSmall", .fixture = "test/distribution/releasesmall_x86_64/inputs/standalone_mix_c_files_add_may_panic.ll", .tag = "mixed-c-add-may-panic", .case_id = "releasesmall_source_standalone_mix_c_files_add_may_panic" },
    .{ .wrapper = "test/zig/integrated/runtime_umul_fix_sat_i64_main.zig", .mode = "ReleaseSmall", .fixture = "test/distribution/releasesmall_x86_64/inputs/no_compile_panic_for_unchecked_arith_umul_fix_sat_i64.ll", .tag = "-", .case_id = "releasesmall_runtime_umul_fix_sat_i64" },
    .{ .wrapper = "test/zig/integrated/runtime_umul_fix_sat_i64_main.zig", .mode = "ReleaseSmall", .fixture = "test/distribution/releasesmall_x86_64/inputs/no_compile_panic_for_unchecked_arith_umul_fix_sat_i64.ll", .tag = "umul-fix-sat-i64", .case_id = "releasesmall_source_no_compile_panic_for_unchecked_arith_umul_fix_sat_i64" },
    .{ .wrapper = "test/zig/integrated/runtime_inherit_want_safety_i64_main.zig", .mode = "ReleaseSmall", .fixture = "test/distribution/releasesmall_x86_64/inputs/inherit_want_safety_i64_return.ll", .tag = "-", .case_id = "releasesmall_runtime_inherit_want_safety_i64" },
    .{ .wrapper = "test/zig/integrated/runtime_inherit_want_safety_i64_main.zig", .mode = "ReleaseSmall", .fixture = "test/distribution/releasesmall_x86_64/inputs/inherit_want_safety_i64_return.ll", .tag = "inherit-want-safety-i64-return", .case_id = "releasesmall_source_inherit_want_safety_i64_return" },
    .{ .wrapper = "test/zig/integrated/runtime_compile_asm_unreachable_main.zig", .mode = "ReleaseSmall", .fixture = "test/distribution/releasesmall_x86_64/inputs/standalone_compile_asm_main_unreachable.ll", .tag = "-", .case_id = "releasesmall_runtime_compile_asm_unreachable" },
    .{ .wrapper = "test/zig/integrated/runtime_compile_asm_unreachable_main.zig", .mode = "ReleaseSmall", .fixture = "test/distribution/releasesmall_x86_64/inputs/standalone_compile_asm_main_unreachable.ll", .tag = "compile-asm-main-unreachable", .case_id = "releasesmall_source_standalone_compile_asm_main_unreachable" },
    .{ .wrapper = "test/zig/integrated/runtime_compile_asm_unreachable_main.zig", .mode = "ReleaseSmall", .fixture = "test/distribution/releasesmall_x86_64/inputs/address_space_start_trampoline.ll", .tag = "address-space-start-trampoline", .case_id = "releasesmall_source_address_space_start_trampoline" },
    .{ .wrapper = "test/zig/integrated/runtime_compile_asm_unreachable_main.zig", .mode = "ReleaseSmall", .fixture = "test/distribution/releasesmall_x86_64/inputs/array_in_anon_struct_getauxval.ll", .tag = "getauxval-pointer-walk", .case_id = "releasesmall_source_array_in_anon_struct_getauxval" },
    .{ .wrapper = "test/zig/integrated/runtime_compile_asm_unreachable_main.zig", .mode = "ReleaseSmall", .fixture = "test/distribution/releasesmall_x86_64/inputs/c_abi_main_f128_sret.ll", .tag = "f128-sret-byval", .case_id = "releasesmall_source_c_abi_main_f128_sret" },
    .{ .wrapper = "test/zig/integrated/runtime_compile_asm_unreachable_main.zig", .mode = "ReleaseSmall", .fixture = "test/distribution/releasesmall_x86_64/inputs/compile_errors_illegal_operation_on_logical_ptr_elem_ptr.ll", .tag = "logical-pointer-unreachable", .case_id = "releasesmall_source_compile_errors_logical_ptr_elem_ptr" },
    .{ .wrapper = "test/zig/integrated/runtime_compile_asm_unreachable_main.zig", .mode = "ReleaseSmall", .fixture = "test/distribution/releasesmall_x86_64/inputs/export_keyword_vram_store.ll", .tag = "vram-volatile-store", .case_id = "releasesmall_source_export_keyword_vram_store" },
    .{ .wrapper = "test/zig/integrated/runtime_compile_asm_unreachable_main.zig", .mode = "ReleaseSmall", .fixture = "test/distribution/releasesmall_x86_64/inputs/sizeof_typeof_unreachable_stubs.ll", .tag = "unreachable-stubs", .case_id = "releasesmall_source_sizeof_typeof_unreachable_stubs" },
    .{ .wrapper = "test/zig/integrated/runtime_compile_asm_unreachable_main.zig", .mode = "ReleaseSmall", .fixture = "test/distribution/releasesmall_x86_64/inputs/standalone_install_raw_hex_start_loop.ll", .tag = "raw-start-loop", .case_id = "releasesmall_source_standalone_install_raw_hex_start_loop" },
    .{ .wrapper = "test/zig/integrated/runtime_compile_asm_unreachable_main.zig", .mode = "ReleaseSmall", .fixture = "test/distribution/releasesmall_x86_64/inputs/standalone_libfuzzer_runner_futex_wait.ll", .tag = "libfuzzer-futex-wait", .case_id = "releasesmall_source_standalone_libfuzzer_runner_futex_wait" },
    .{ .wrapper = "test/zig/integrated/runtime_compile_asm_unreachable_main.zig", .mode = "ReleaseSmall", .fixture = "test/distribution/releasesmall_x86_64/inputs/standalone_libfuzzer_runner_test_name.ll", .tag = "libfuzzer-test-name", .case_id = "releasesmall_source_standalone_libfuzzer_runner_test_name" },
    .{ .wrapper = "test/zig/integrated/runtime_compile_asm_unreachable_main.zig", .mode = "ReleaseSmall", .fixture = "test/distribution/releasesmall_x86_64/inputs/standalone_libfuzzer_runner_test_run.ll", .tag = "libfuzzer-test-run", .case_id = "releasesmall_source_standalone_libfuzzer_runner_test_run" },
    .{ .wrapper = "test/zig/integrated/runtime_str_from_float_help_main.zig", .mode = "ReleaseSmall", .fixture = "test/distribution/releasesmall_x86_64/exclusions/standalone_emit_llvm_no_bin_str_from_float_help.ll", .tag = "-", .case_id = "releasesmall_runtime_str_from_float_help" },
    .{ .wrapper = "test/zig/integrated/runtime_base64_decode_base_64_full_main.zig", .mode = "ReleaseSmall", .fixture = "test/distribution/releasesmall_x86_64/exclusions/standalone_mix_o_files_base64_decode_base_64.ll", .tag = "-", .case_id = "releasesmall_runtime_base64_decode_base_64_full" },
    .{ .wrapper = "test/zig/integrated/runtime_base64_decode_step_main.zig", .mode = "ReleaseSmall", .fixture = "test/distribution/releasesmall_x86_64/exclusions/standalone_mix_o_files_base64_decode_base_64.ll", .tag = "-", .case_id = "releasesmall_runtime_base64_decode_step" },
    .{ .wrapper = "test/zig/integrated/runtime_base64_store_step_main.zig", .mode = "ReleaseSmall", .fixture = "test/distribution/releasesmall_x86_64/exclusions/standalone_mix_o_files_base64_decode_base_64.ll", .tag = "-", .case_id = "releasesmall_runtime_base64_store_step" },
    .{ .wrapper = "test/zig/integrated/runtime_base64_residual_byte_step_main.zig", .mode = "ReleaseSmall", .fixture = "test/distribution/releasesmall_x86_64/exclusions/standalone_mix_o_files_base64_decode_base_64.ll", .tag = "-", .case_id = "releasesmall_runtime_base64_residual_byte_step" },
    .{ .wrapper = "test/zig/integrated/runtime_base64_padding_tail_step_main.zig", .mode = "ReleaseSmall", .fixture = "test/distribution/releasesmall_x86_64/exclusions/standalone_mix_o_files_base64_decode_base_64.ll", .tag = "-", .case_id = "releasesmall_runtime_base64_padding_tail_step" },
    .{ .wrapper = "test/zig/integrated/runtime_base64_padding_loop_step_main.zig", .mode = "ReleaseSmall", .fixture = "test/distribution/releasesmall_x86_64/exclusions/standalone_mix_o_files_base64_decode_base_64.ll", .tag = "-", .case_id = "releasesmall_runtime_base64_padding_loop_step" },
    .{ .wrapper = "test/zig/integrated/runtime_base64_padding_length_step_main.zig", .mode = "ReleaseSmall", .fixture = "test/distribution/releasesmall_x86_64/exclusions/standalone_mix_o_files_base64_decode_base_64.ll", .tag = "-", .case_id = "releasesmall_runtime_base64_padding_length_step" },
    .{ .wrapper = "test/zig/integrated/runtime_base64_chunk_guard_step_main.zig", .mode = "ReleaseSmall", .fixture = "test/distribution/releasesmall_x86_64/exclusions/standalone_mix_o_files_base64_decode_base_64.ll", .tag = "-", .case_id = "releasesmall_runtime_base64_chunk_guard_step" },
    .{ .wrapper = "test/zig/integrated/runtime_base64_source_stride_step_main.zig", .mode = "ReleaseSmall", .fixture = "test/distribution/releasesmall_x86_64/exclusions/standalone_mix_o_files_base64_decode_base_64.ll", .tag = "-", .case_id = "releasesmall_runtime_base64_source_stride_step" },
    .{ .wrapper = "test/zig/integrated/runtime_base64_source_bundle_step_main.zig", .mode = "ReleaseSmall", .fixture = "test/distribution/releasesmall_x86_64/exclusions/standalone_mix_o_files_base64_decode_base_64.ll", .tag = "-", .case_id = "releasesmall_runtime_base64_source_bundle_step" },
    .{ .wrapper = "test/zig/integrated/runtime_base64_next_source_bundle_step_main.zig", .mode = "ReleaseSmall", .fixture = "test/distribution/releasesmall_x86_64/exclusions/standalone_mix_o_files_base64_decode_base_64.ll", .tag = "-", .case_id = "releasesmall_runtime_base64_next_source_bundle_step" },
    .{ .wrapper = "test/zig/integrated/runtime_base64_third_source_bundle_step_main.zig", .mode = "ReleaseSmall", .fixture = "test/distribution/releasesmall_x86_64/exclusions/standalone_mix_o_files_base64_decode_base_64.ll", .tag = "-", .case_id = "releasesmall_runtime_base64_third_source_bundle_step" },
    .{ .wrapper = "test/zig/integrated/runtime_base64_bit_buffer_store_step_main.zig", .mode = "ReleaseSmall", .fixture = "test/distribution/releasesmall_x86_64/exclusions/standalone_mix_o_files_base64_decode_base_64.ll", .tag = "-", .case_id = "releasesmall_runtime_base64_bit_buffer_store_step" },
    .{ .wrapper = "test/zig/integrated/runtime_base64_loop_advance_step_main.zig", .mode = "ReleaseSmall", .fixture = "test/distribution/releasesmall_x86_64/exclusions/standalone_mix_o_files_base64_decode_base_64.ll", .tag = "-", .case_id = "releasesmall_runtime_base64_loop_advance_step" },
    .{ .wrapper = "test/zig/integrated/runtime_base64_residual_guard_step_main.zig", .mode = "ReleaseSmall", .fixture = "test/distribution/releasesmall_x86_64/exclusions/standalone_mix_o_files_base64_decode_base_64.ll", .tag = "-", .case_id = "releasesmall_runtime_base64_residual_guard_step" },
    .{ .wrapper = "test/zig/integrated/runtime_base64_residual_bundle_step_main.zig", .mode = "ReleaseSmall", .fixture = "test/distribution/releasesmall_x86_64/exclusions/standalone_mix_o_files_base64_decode_base_64.ll", .tag = "-", .case_id = "releasesmall_runtime_base64_residual_bundle_step" },
    .{ .wrapper = "test/zig/integrated/runtime_base64_residual_store_step_main.zig", .mode = "ReleaseSmall", .fixture = "test/distribution/releasesmall_x86_64/exclusions/standalone_mix_o_files_base64_decode_base_64.ll", .tag = "-", .case_id = "releasesmall_runtime_base64_residual_store_step" },
    .{ .wrapper = "test/zig/integrated/runtime_base64_residual_length_step_main.zig", .mode = "ReleaseSmall", .fixture = "test/distribution/releasesmall_x86_64/exclusions/standalone_mix_o_files_base64_decode_base_64.ll", .tag = "-", .case_id = "releasesmall_runtime_base64_residual_length_step" },
    .{ .wrapper = "test/zig/integrated/runtime_base64_residual_table_check_step_main.zig", .mode = "ReleaseSmall", .fixture = "test/distribution/releasesmall_x86_64/exclusions/standalone_mix_o_files_base64_decode_base_64.ll", .tag = "-", .case_id = "releasesmall_runtime_base64_residual_table_check_step" },
    .{ .wrapper = "test/zig/integrated/runtime_base64_residual_accumulator_step_main.zig", .mode = "ReleaseSmall", .fixture = "test/distribution/releasesmall_x86_64/exclusions/standalone_mix_o_files_base64_decode_base_64.ll", .tag = "-", .case_id = "releasesmall_runtime_base64_residual_accumulator_step" },
    .{ .wrapper = "test/zig/integrated/runtime_base64_residual_loop_advance_step_main.zig", .mode = "ReleaseSmall", .fixture = "test/distribution/releasesmall_x86_64/exclusions/standalone_mix_o_files_base64_decode_base_64.ll", .tag = "-", .case_id = "releasesmall_runtime_base64_residual_loop_advance_step" },
    .{ .wrapper = "test/zig/integrated/runtime_base64_residual_padding_check_step_main.zig", .mode = "ReleaseSmall", .fixture = "test/distribution/releasesmall_x86_64/exclusions/standalone_mix_o_files_base64_decode_base_64.ll", .tag = "-", .case_id = "releasesmall_runtime_base64_residual_padding_check_step" },
    .{ .wrapper = "test/zig/integrated/runtime_base64_residual_final_mask_step_main.zig", .mode = "ReleaseSmall", .fixture = "test/distribution/releasesmall_x86_64/exclusions/standalone_mix_o_files_base64_decode_base_64.ll", .tag = "-", .case_id = "releasesmall_runtime_base64_residual_final_mask_step" },
    .{ .wrapper = "test/zig/integrated/runtime_base64_residual_padding_loop_step_main.zig", .mode = "ReleaseSmall", .fixture = "test/distribution/releasesmall_x86_64/exclusions/standalone_mix_o_files_base64_decode_base_64.ll", .tag = "-", .case_id = "releasesmall_runtime_base64_residual_padding_loop_step" },
    .{ .wrapper = "test/zig/integrated/runtime_base64_decode_exit_step_main.zig", .mode = "ReleaseSmall", .fixture = "test/distribution/releasesmall_x86_64/exclusions/standalone_mix_o_files_base64_decode_base_64.ll", .tag = "-", .case_id = "releasesmall_runtime_base64_decode_exit_step" },
    .{ .wrapper = "test/zig/integrated/base64_table_lookup_main.zig", .mode = "ReleaseSmall", .fixture = "test/distribution/releasesmall_x86_64/inputs/base64_table_lookup.ll", .tag = "base64-table-lookup", .case_id = "releasesmall_source_base64_table_lookup" },
};

const ir_writer_cases = [_]IrWriterCase{
    .{ .id = "releasefast_tiny_scalar", .surface = "scalar-add-ret", .write = writeTinyScalarIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_source_tiny_scalar", .surface = "scalar-add-ret", .write = writeTinyScalarIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_integers", .surface = "integer-arithmetic", .write = writeIntegersIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_source_integers_add_wrap", .surface = "integer-arithmetic", .write = writeIntegersIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_source_integers_cmp_shift", .surface = "integer-arithmetic", .write = writeIntegersIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_error_switch", .surface = "error-switch-select", .write = writeErrorSwitchIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_source_error_switch_error_switch", .surface = "error-switch-select", .write = writeErrorSwitchIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_control_flow_calls", .surface = "direct-call", .write = writeControlFlowCallsIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_source_control_flow_loop_sum", .surface = "runtime-loop-sum", .write = writeRuntimeLoopSumIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_source_control_flow_call_chain", .surface = "abi-arg-call", .write = writeRuntimeCallChainIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_globals_comptime", .surface = "global-load", .write = writeGlobalsComptimeIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesafe_runtime_read_global", .surface = "global-load", .write = writeReleaseSafeRuntimeReadGlobalIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_runtime_cond_branch", .surface = "runtime-condbr", .write = writeRuntimeCondBranchIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_source_switch_branch_mix", .surface = "runtime-condbr", .write = writeRuntimeCondBranchIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_runtime_phi_merge", .surface = "runtime-phi-merge", .write = writeRuntimePhiMergeIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_runtime_loop_sum", .surface = "runtime-loop-sum", .write = writeRuntimeLoopSumIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesafe_runtime_loop_sum", .surface = "checked-loop-sum-boundary", .write = writeReleaseSafeRuntimeLoopSumIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_runtime_switch", .surface = "runtime-switch", .write = writeRuntimeSwitchIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_source_switch_dense", .surface = "runtime-switch", .write = writeRuntimeSwitchIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesafe_runtime_branch_mix", .surface = "checked-branch-mix-boundary", .write = writeReleaseSafeRuntimeBranchMixIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_runtime_global_update", .surface = "global-update", .write = writeRuntimeGlobalUpdateIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesafe_runtime_global_update", .surface = "checked-global-update-boundary", .write = writeReleaseSafeRuntimeGlobalUpdateIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesafe_source_globals_checked", .surface = "checked-global-update-boundary", .write = writeReleaseSafeRuntimeGlobalUpdateIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_runtime_pointer_load_store", .surface = "pointer-load-store", .write = writeRuntimePointerLoadStoreIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_source_pointers_memory", .surface = "pointer-load-store", .write = writeRuntimePointerLoadStoreIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesafe_runtime_pointer_load_store", .surface = "checked-pointer-load-store-boundary", .write = writeReleaseSafeRuntimePointerLoadStoreIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesafe_source_pointers_memory_checked", .surface = "checked-pointer-load-store-boundary", .write = writeReleaseSafeRuntimePointerLoadStoreIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_runtime_volatile_roundtrip", .surface = "volatile-roundtrip", .write = writeRuntimeVolatileRoundtripIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_runtime_optional_pointer", .surface = "optional-pointer", .write = writeRuntimeOptionalPointerIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_source_optional_pointer_value", .surface = "optional-pointer", .write = writeRuntimeOptionalPointerIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_runtime_packed_read_flag", .surface = "packed-read-flag", .write = writeRuntimePackedReadFlagIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_source_packed_bits_basic_read_flag", .surface = "packed-read-flag", .write = writeRuntimePackedReadFlagIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_runtime_packed_replace_low", .surface = "packed-replace-low", .write = writeRuntimePackedReplaceLowIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_source_packed_bits_basic_replace_low", .surface = "packed-replace-low", .write = writeRuntimePackedReplaceLowIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_runtime_struct_sum", .surface = "struct-field-sum", .write = writeRuntimeStructSumIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_source_aggregates_struct_sum", .surface = "struct-field-sum", .write = writeRuntimeStructSumIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesafe_runtime_struct_sum", .surface = "checked-struct-sum-boundary", .write = writeReleaseSafeRuntimeStructSumIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesafe_source_aggregates_checked_struct", .surface = "checked-struct-sum-boundary", .write = writeReleaseSafeRuntimeStructSumIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_runtime_array_sum", .surface = "array-scalar-sum", .write = writeRuntimeArraySumIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_source_aggregates_array_sum", .surface = "array-scalar-sum", .write = writeRuntimeArraySumIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesafe_runtime_array_sum", .surface = "checked-array-sum-boundary", .write = writeReleaseSafeRuntimeArraySumIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesafe_source_aggregates_checked_array", .surface = "checked-array-sum-boundary", .write = writeReleaseSafeRuntimeArraySumIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_runtime_optional_payload", .surface = "optional-scalar-payload", .write = writeRuntimeOptionalPayloadIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_source_aggregates_optional_payload", .surface = "optional-scalar-payload", .write = writeRuntimeOptionalPayloadIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_runtime_error_union_payload", .surface = "error-union-payload", .write = writeRuntimeErrorUnionPayloadIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_source_aggregates_error_union_payload", .surface = "error-union-payload", .write = writeRuntimeErrorUnionPayloadIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_runtime_slice_sum", .surface = "slice-loop-sum", .write = writeRuntimeSliceSumIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_source_aggregates_slice_sum", .surface = "slice-loop-sum", .write = writeRuntimeSliceSumIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesafe_runtime_slice_sum", .surface = "checked-slice-loop-sum-boundary", .write = writeReleaseSafeRuntimeSliceSumIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesafe_source_aggregates_checked_slice", .surface = "checked-slice-loop-sum-boundary", .write = writeReleaseSafeRuntimeSliceSumIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_runtime_fp_constants", .surface = "fp-literal-return", .write = writeRuntimeFpConstantsIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_source_fp_constants_literals", .surface = "fp-literal-return", .write = writeRuntimeFpConstantsIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_runtime_comptime_const", .surface = "comptime-const-mul", .write = writeRuntimeComptimeConstIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_source_globals_comptime_const", .surface = "comptime-const-mul", .write = writeRuntimeComptimeConstIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_source_globals_comptime_global_counter", .surface = "global-update", .write = writeRuntimeGlobalUpdateIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesafe_runtime_comptime_const", .surface = "checked-comptime-const-boundary", .write = writeReleaseSafeRuntimeComptimeConstIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_runtime_debug_location", .surface = "add-imm-return", .write = writeRuntimeDebugLocationIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_source_atomics_debug_location", .surface = "add-imm-return", .write = writeRuntimeDebugLocationIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesafe_runtime_debug_location", .surface = "checked-add-imm-boundary", .write = writeReleaseSafeRuntimeDebugLocationIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesafe_source_atomics_debug_location_checked", .surface = "checked-add-imm-boundary", .write = writeReleaseSafeRuntimeDebugLocationIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_runtime_call_chain", .surface = "abi-arg-call", .write = writeRuntimeCallChainIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesafe_runtime_call_chain", .surface = "checked-call-chain-boundary", .write = writeReleaseSafeRuntimeCallChainIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesafe_source_control_flow_calls_checked", .surface = "checked-call-chain-boundary", .write = writeReleaseSafeRuntimeCallChainIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_runtime_tls_read", .surface = "tls-read", .write = writeRuntimeTlsReadIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_source_tls_concurrency_counter_read", .surface = "tls-read", .write = writeRuntimeTlsReadIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesafe_runtime_tls_read", .surface = "tls-read", .write = writeRuntimeTlsReadIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesafe_source_tls_concurrency_checked_read", .surface = "tls-read", .write = writeRuntimeTlsReadIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_runtime_tls_bump", .surface = "tls-bump", .write = writeRuntimeTlsBumpIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_source_tls_concurrency_counter_bump", .surface = "tls-bump", .write = writeRuntimeTlsBumpIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesafe_runtime_tls_bump", .surface = "checked-tls-bump-boundary", .write = writeReleaseSafeRuntimeTlsBumpIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesafe_source_tls_concurrency_checked_bump", .surface = "checked-tls-bump-boundary", .write = writeReleaseSafeRuntimeTlsBumpIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_runtime_atomic_add", .surface = "atomic-add", .write = writeRuntimeAtomicAddIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_source_atomics_atomic_add", .surface = "atomic-add", .write = writeRuntimeAtomicAddIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_runtime_inline_asm_barrier", .surface = "inline-asm-barrier", .write = writeRuntimeInlineAsmBarrierIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_source_atomics_inline_asm_barrier", .surface = "inline-asm-barrier", .write = writeRuntimeInlineAsmBarrierIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_runtime_aggregate_pair", .surface = "aggregate-pair-abi", .write = writeRuntimeAggregatePairIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_source_aggregate_abi_pair", .surface = "aggregate-pair-abi", .write = writeRuntimeAggregatePairIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_runtime_float_less", .surface = "float-less", .write = writeRuntimeFloatLessIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_source_float_compare", .surface = "float-less", .write = writeRuntimeFloatLessIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_runtime_float_mul", .surface = "float-mul", .write = writeRuntimeFloatMulIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_runtime_float_add", .surface = "float-add", .write = writeRuntimeFloatAddIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_source_floats_math", .surface = "float-add", .write = writeRuntimeFloatAddIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_runtime_float_select", .surface = "float-select", .write = writeRuntimeFloatSelectIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_runtime_float_sub", .surface = "float-sub", .write = writeRuntimeFloatSubIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_source_fp_extended_ops", .surface = "float-sub", .write = writeRuntimeFloatSubIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_runtime_double_div", .surface = "double-div", .write = writeRuntimeDoubleDivIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_runtime_float_rem", .surface = "float-rem", .write = writeRuntimeFloatRemIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesafe_error_switch", .surface = "error-switch-select", .write = writeErrorSwitchIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesafe_source_error_switch_select", .surface = "error-switch-select", .write = writeErrorSwitchIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesafe_tiny_scalar_runtime_boundary", .surface = "checked-add-runtime-boundary", .write = writeCheckedAddRuntimeBoundaryIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesafe_source_tiny_scalar_checked_add", .surface = "checked-add-runtime-boundary", .write = writeCheckedAddRuntimeBoundaryIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesafe_source_switch_branch_mix_checked", .surface = "checked-branch-mix-boundary", .write = writeReleaseSafeRuntimeBranchMixIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesafe_runtime_side_effect_free", .surface = "void-noop-call", .write = writeReleaseSafeRuntimeSideEffectFreeIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_globals_comptime", .surface = "global-load", .write = writeGlobalsComptimeIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_runtime_hidden_access", .surface = "hidden-global-access", .write = writeReleaseSmallRuntimeHiddenAccessIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_source_standalone_extern_exports_hidden_access", .surface = "hidden-global-access", .write = writeReleaseSmallRuntimeHiddenAccessIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_runtime_mix_c_add_zig", .surface = "mixed-c-zig-add", .write = writeReleaseSmallRuntimeMixCAddZigIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_source_standalone_mix_c_files_add_zig", .surface = "mixed-c-zig-add", .write = writeReleaseSmallRuntimeMixCAddZigIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_runtime_mix_c_add_may_panic", .surface = "mixed-c-zig-panic-add", .write = writeReleaseSmallRuntimeMixCAddMayPanicIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_source_standalone_mix_c_files_add_may_panic", .surface = "mixed-c-zig-panic-add", .write = writeReleaseSmallRuntimeMixCAddMayPanicIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_runtime_umul_fix_sat_i64", .surface = "umul-fix-sat-i64", .write = writeReleaseSmallRuntimeUmulFixSatI64IrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_source_no_compile_panic_for_unchecked_arith_umul_fix_sat_i64", .surface = "umul-fix-sat-i64", .write = writeReleaseSmallRuntimeUmulFixSatI64IrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_runtime_inherit_want_safety_i64", .surface = "inherit-i64-return", .write = writeReleaseSmallRuntimeInheritWantSafetyI64IrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_source_inherit_want_safety_i64_return", .surface = "inherit-i64-return", .write = writeReleaseSmallRuntimeInheritWantSafetyI64IrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_runtime_compile_asm_unreachable", .surface = "compile-asm-unreachable", .write = writeReleaseSmallRuntimeCompileAsmUnreachableIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_source_standalone_compile_asm_main_unreachable", .surface = "compile-asm-unreachable", .write = writeReleaseSmallRuntimeCompileAsmUnreachableIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_source_address_space_start_trampoline", .surface = "start-trampoline", .write = writeReleaseSmallAddressSpaceStartTrampolineIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_source_array_in_anon_struct_getauxval", .surface = "getauxval-pointer-walk", .write = writeReleaseSmallGetauxvalIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_source_c_abi_main_f128_sret", .surface = "f128-sret-byval", .write = writeReleaseSmallCAbiF128SretIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_source_compile_errors_logical_ptr_elem_ptr", .surface = "noreturn-unreachable-stub", .write = writeReleaseSmallLogicalPtrUnreachableIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_source_export_keyword_vram_store", .surface = "address-space-volatile-store", .write = writeReleaseSmallVramStoreIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_source_sizeof_typeof_unreachable_stubs", .surface = "noreturn-unreachable-stub", .write = writeReleaseSmallSizeofTypeofUnreachableIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_source_standalone_install_raw_hex_start_loop", .surface = "raw-start-loop", .write = writeReleaseSmallRawStartLoopIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_source_standalone_libfuzzer_runner_futex_wait", .surface = "i1-const-return", .write = writeReleaseSmallLibfuzzerFutexWaitIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_source_standalone_libfuzzer_runner_test_name", .surface = "constant-string-slice-return", .write = writeReleaseSmallLibfuzzerTestNameIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_source_standalone_libfuzzer_runner_test_run", .surface = "libfuzzer-vtable-run", .write = writeReleaseSmallLibfuzzerTestRunIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_runtime_str_from_float_help", .surface = "str-from-float-help", .write = writeReleaseSmallRuntimeStrFromFloatHelpIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_runtime_base64_decode_base_64_full", .surface = "base64-decode-base64-full", .write = writeReleaseSmallRuntimeBase64DecodeBase64FullIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_runtime_base64_decode_step", .surface = "base64-decode-step", .write = writeReleaseSmallRuntimeBase64DecodeStepIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_runtime_base64_store_step", .surface = "base64-store-step", .write = writeReleaseSmallRuntimeBase64StoreStepIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_runtime_base64_residual_byte_step", .surface = "base64-residual-byte-step", .write = writeReleaseSmallRuntimeBase64ResidualByteStepIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_runtime_base64_padding_tail_step", .surface = "base64-padding-tail-step", .write = writeReleaseSmallRuntimeBase64PaddingTailStepIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_runtime_base64_padding_loop_step", .surface = "base64-padding-loop-step", .write = writeReleaseSmallRuntimeBase64PaddingLoopStepIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_runtime_base64_padding_length_step", .surface = "base64-padding-length-step", .write = writeReleaseSmallRuntimeBase64PaddingLengthStepIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_runtime_base64_chunk_guard_step", .surface = "base64-chunk-guard-step", .write = writeReleaseSmallRuntimeBase64ChunkGuardStepIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_runtime_base64_source_stride_step", .surface = "base64-source-stride-step", .write = writeReleaseSmallRuntimeBase64SourceStrideStepIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_runtime_base64_source_bundle_step", .surface = "base64-source-bundle-step", .write = writeReleaseSmallRuntimeBase64SourceBundleStepIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_runtime_base64_next_source_bundle_step", .surface = "base64-next-source-bundle-step", .write = writeReleaseSmallRuntimeBase64NextSourceBundleStepIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_runtime_base64_third_source_bundle_step", .surface = "base64-third-source-bundle-step", .write = writeReleaseSmallRuntimeBase64ThirdSourceBundleStepIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_runtime_base64_bit_buffer_store_step", .surface = "base64-bit-buffer-store-step", .write = writeReleaseSmallRuntimeBase64BitBufferStoreStepIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_runtime_base64_loop_advance_step", .surface = "base64-loop-advance-step", .write = writeReleaseSmallRuntimeBase64LoopAdvanceStepIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_runtime_base64_residual_guard_step", .surface = "base64-residual-guard-step", .write = writeReleaseSmallRuntimeBase64ResidualGuardStepIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_runtime_base64_residual_bundle_step", .surface = "base64-residual-bundle-step", .write = writeReleaseSmallRuntimeBase64ResidualBundleStepIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_runtime_base64_residual_store_step", .surface = "base64-residual-store-step", .write = writeReleaseSmallRuntimeBase64ResidualStoreStepIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_runtime_base64_residual_length_step", .surface = "base64-residual-length-step", .write = writeReleaseSmallRuntimeBase64ResidualLengthStepIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_runtime_base64_residual_table_check_step", .surface = "base64-residual-table-check-step", .write = writeReleaseSmallRuntimeBase64ResidualTableCheckStepIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_runtime_base64_residual_accumulator_step", .surface = "base64-residual-accumulator-step", .write = writeReleaseSmallRuntimeBase64ResidualAccumulatorStepIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_runtime_base64_residual_loop_advance_step", .surface = "base64-residual-loop-advance-step", .write = writeReleaseSmallRuntimeBase64ResidualLoopAdvanceStepIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_runtime_base64_residual_padding_check_step", .surface = "base64-residual-padding-check-step", .write = writeReleaseSmallRuntimeBase64ResidualPaddingCheckStepIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_runtime_base64_residual_final_mask_step", .surface = "base64-residual-final-mask-step", .write = writeReleaseSmallRuntimeBase64ResidualFinalMaskStepIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_runtime_base64_residual_padding_loop_step", .surface = "base64-residual-padding-loop-step", .write = writeReleaseSmallRuntimeBase64ResidualPaddingLoopStepIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_runtime_base64_decode_exit_step", .surface = "base64-decode-exit-step", .write = writeReleaseSmallRuntimeBase64DecodeExitStepIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_i64_arithmetic", .surface = "i64-arithmetic", .write = writeI64ArithmeticIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_runtime_i64_call", .surface = "i64-call-return", .write = writeRuntimeI64CallIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_base64_table_lookup", .surface = "table-indexed-load", .write = writeBase64TableLookupIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_source_base64_table_lookup", .surface = "table-indexed-load", .write = writeBase64TableLookupIrWriterBody, .construction = .structured_builder },
};

fn findIrWriterCase(case_id: []const u8) ?IrWriterCase {
    for (ir_writer_cases) |case| {
        if (std.mem.eql(u8, case.id, case_id)) return case;
    }
    return null;
}

fn resolveSourceWrapperDispatchCase(wrapper: []const u8, mode: []const u8) ?IrWriterCase {
    for (source_wrapper_dispatch_entries) |entry| {
        if (std.mem.eql(u8, entry.wrapper, wrapper) and std.mem.eql(u8, entry.mode, mode)) {
            return findIrWriterCase(entry.case_id);
        }
    }
    return null;
}

fn resolveReleaseSourceOwnedDispatchCase(
    wrapper: []const u8,
    mode: []const u8,
    fixture: []const u8,
    tag: []const u8,
) ?IrWriterCase {
    for (release_source_owned_dispatch_entries) |entry| {
        if (std.mem.eql(u8, entry.wrapper, wrapper) and
            std.mem.eql(u8, entry.mode, mode) and
            std.mem.eql(u8, entry.fixture, fixture) and
            std.mem.eql(u8, entry.tag, tag))
        {
            return findIrWriterCase(entry.case_id);
        }
    }
    return null;
}

fn codegenOwnershipForCase(case: IrWriterCase) CodegenOwnership {
    if (case.construction != .structured_builder) return .textual_boundary;
    return .generic;
}

fn structuredLoweringOwnershipForCase(case: IrWriterCase) StructuredLoweringOwnership {
    if (zsl.isSemanticSurface(case.surface)) return .semantic_record;
    if (case.construction == .structured_builder) return .external_writer_delegate;
    return .manifest_structured;
}

fn semanticProgramForCase(case: IrWriterCase) ?zsl.Program {
    if (case.construction != .structured_builder) return null;
    const surface = case.surface;
    if (std.mem.eql(u8, surface, "scalar-add-ret")) return .tiny_scalar;
    if (std.mem.eql(u8, surface, "integer-arithmetic")) return .integer_arithmetic;
    if (std.mem.eql(u8, surface, "error-switch-select")) return .error_switch_select;
    if (std.mem.eql(u8, surface, "direct-call")) return .direct_call;
    if (std.mem.eql(u8, surface, "abi-arg-call")) return .call_chain;
    if (std.mem.eql(u8, surface, "runtime-condbr")) return .cond_branch;
    if (std.mem.eql(u8, surface, "runtime-phi-merge")) return .phi_merge;
    if (std.mem.eql(u8, surface, "runtime-loop-sum")) return .loop_sum;
    if (std.mem.eql(u8, surface, "global-update")) return .global_update;
    if (std.mem.eql(u8, surface, "pointer-load-store")) return .pointer_load_store;
    if (std.mem.eql(u8, surface, "struct-field-sum")) return .struct_sum;
    if (std.mem.eql(u8, surface, "array-scalar-sum")) return .array_sum;
    if (std.mem.eql(u8, surface, "optional-scalar-payload")) return .optional_payload;
    if (std.mem.eql(u8, surface, "error-union-payload")) return .error_union_payload;
    if (std.mem.eql(u8, surface, "slice-loop-sum")) return .slice_sum;
    if (std.mem.eql(u8, surface, "fp-literal-return")) return .fp_literals;
    if (std.mem.eql(u8, surface, "comptime-const-mul")) return .comptime_const;
    if (std.mem.eql(u8, surface, "add-imm-return")) return .debug_location;
    if (std.mem.eql(u8, surface, "tls-read")) return .tls_read;
    if (std.mem.eql(u8, surface, "atomic-add")) return .atomic_add;
    return null;
}

fn writeTinyScalarIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeTinyScalarStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write tiny scalar external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeTinyScalarStructuredModule(writer: *std.Io.Writer) !void {
    try zsl.emit(.tiny_scalar, writer);
}

fn writeIntegersIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeIntegersStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write integers external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeIntegersStructuredModule(writer: *std.Io.Writer) !void {
    try zsl.emit(.integer_arithmetic, writer);
}

fn writeErrorSwitchIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeErrorSwitchStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write error_switch external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeErrorSwitchStructuredModule(writer: *std.Io.Writer) !void {
    try zsl.emit(.error_switch_select, writer);
}

fn writeControlFlowCallsIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeControlFlowCallsStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write control_flow_calls external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeControlFlowCallsStructuredModule(writer: *std.Io.Writer) !void {
    try zsl.emit(.direct_call, writer);
}

fn writeGlobalsComptimeIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeGlobalsComptimeStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write globals_comptime external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeGlobalsComptimeStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.global("globals_comptime.writer_counter", "private", .i32, "5", "4");
    try writer.writeAll("\n");
    var read_global = try module.function("dso_local ", .i32, "globals_comptime.read_global", "", " local_unnamed_addr");
    var read_entry = try read_global.block("entry");
    _ = try read_entry.load("value", .i32, sib.global(.ptr, "@globals_comptime.writer_counter"), "4");
    try read_entry.ret(sib.local(.i32, "%value"));
    try read_global.end();
    var main_fn = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var entry = try main_fn.block("entry");
    _ = try entry.call("value", "", .i32, "@globals_comptime.read_global", "");
    try entry.ret(sib.local(.i32, "%value"));
    try main_fn.end();
}

fn writeReleaseSafeRuntimeReadGlobalIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeReleaseSafeRuntimeReadGlobalStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSafe runtime read-global external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeReleaseSafeRuntimeReadGlobalStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.global("globals_comptime.global_counter", "private", .i32, "5", "4");
    try module.alias("read_global", .{ .text = "i32 ()" }, "@globals_comptime.read_global");
    try writer.writeAll("\n");
    var main_fn = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var main_entry = try main_fn.block("entry");
    _ = try main_entry.call("value", "", .i32, "@globals_comptime.read_global", "");
    try main_entry.ret(sib.local(.i32, "%value"));
    try main_fn.end();
    var read_global = try module.function("private ", .i32, "globals_comptime.read_global", "", " unnamed_addr align 1");
    var read_entry = try read_global.block("entry");
    _ = try read_entry.load("value", .i32, sib.global(.ptr, "@globals_comptime.global_counter"), "4");
    try read_entry.ret(sib.local(.i32, "%value"));
    try read_global.end();
}

fn writeReleaseSmallRuntimeHiddenAccessIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeReleaseSmallHiddenAccessModule(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime hidden-access external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeReleaseSmallHiddenAccessModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.global("exports.hidden", "private unnamed_addr", .i32, "0", "4");
    try writer.writeAll("\n");
    try module.alias("getHidden", .{ .text = "i32 ()" }, "@exports.getHidden");
    try module.alias("updateHidden", .{ .text = "void (i32)" }, "@exports.updateHidden");
    try writer.writeAll("\n");
    var main_fn = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var main_entry = try main_fn.block("entry");
    _ = try main_entry.call(null, "", .void, "@exports.updateHidden", "i32 7");
    _ = try main_entry.call("value", "", .i32, "@exports.getHidden", "");
    try main_entry.ret(sib.local(.i32, "%value"));
    try main_fn.end();
    var get_hidden = try module.function("private ", .i32, "exports.getHidden", "", " unnamed_addr align 1");
    var get_entry = try get_hidden.block("entry");
    _ = try get_entry.load("value", .i32, sib.global(.ptr, "@exports.hidden"), "4");
    try get_entry.ret(sib.local(.i32, "%value"));
    try get_hidden.end();
    var update_hidden = try module.function("private ", .void, "exports.updateHidden", "i32 %value", " unnamed_addr align 1");
    var update_entry = try update_hidden.block("entry");
    try update_entry.store(sib.local(.i32, "%value"), sib.global(.ptr, "@exports.hidden"), "4");
    try update_entry.retVoid();
    try update_hidden.end();
}

fn writeReleaseSmallRuntimeMixCAddZigIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeReleaseSmallMixCAddZigModule(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime mixed C/Zig add external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeReleaseSmallMixCAddZigModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.tlsGlobal("C_k", "", "localexec", .i32, "2", "4");
    try module.global("main.zig_k", "private unnamed_addr", .i32, "1", "4");
    try writer.writeAll("\n");
    try module.alias("add_zig", .{ .text = "i32 (i32)" }, "@main.add_zig");
    try module.alias("zig_k", .i32, "@main.zig_k");
    try writer.writeAll("\n");
    var main_fn = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var main_entry = try main_fn.block("entry");
    _ = try main_entry.call("value", "", .i32, "@main.add_zig", "i32 4");
    try main_entry.ret(sib.local(.i32, "%value"));
    try main_fn.end();
    var add_zig = try module.function("private ", .i32, "main.add_zig", "i32 %0", " unnamed_addr align 1");
    var entry = try add_zig.block("entry");
    _ = try entry.load("zig", .i32, sib.global(.ptr, "@main.zig_k"), "4");
    _ = try entry.binary("with_arg", "add nsw", .i32, sib.local(.i32, "%zig"), sib.local(.i32, "%0"));
    _ = try entry.load("c", .i32, sib.global(.ptr, "@C_k"), "4");
    _ = try entry.binary("sum", "add nsw", .i32, sib.local(.i32, "%with_arg"), sib.local(.i32, "%c"));
    try entry.ret(sib.local(.i32, "%sum"));
    try add_zig.end();
}

fn writeReleaseSmallRuntimeMixCAddMayPanicIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeReleaseSmallMixCAddMayPanicModule(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime mixed C/Zig panic add external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeReleaseSmallMixCAddMayPanicModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.global("main.zig_k", "private unnamed_addr", .i32, "1", "4");
    try module.constant("__anon_14658", "private unnamed_addr", .{ .text = "[13 x i8]" }, "c\"negative int\\00\"", "1");
    try writer.writeAll("\n");
    try module.alias("add_may_panic", .{ .text = "i32 (i32)" }, "@main.add_may_panic");
    try module.alias("zig_k", .i32, "@main.zig_k");
    try writer.writeAll("\n");
    var main_fn = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var main_entry = try main_fn.block("entry");
    _ = try main_entry.call("value", "", .i32, "@main.add_may_panic", "i32 4");
    try main_entry.ret(sib.local(.i32, "%value"));
    try main_fn.end();
    var add_fn = try module.function("private ", .i32, "main.add_may_panic", "i32 %0", " unnamed_addr align 1");
    var entry = try add_fn.block("entry");
    _ = try entry.icmp("negative", "slt", .i32, sib.local(.i32, "%0"), sib.int(.i32, "0"));
    try entry.condBr(sib.local(.i1, "%negative"), "panic", "ok");
    try writer.writeAll("\n");
    var panic = try add_fn.block("panic");
    _ = try panic.call(null, "", .void, "@llvm.assume", "i1 1");
    _ = try panic.call(null, "tail fastcc ", .void, "@debug.defaultPanic", "ptr @__anon_14658, i64 12");
    try panic.emitUnreachable();
    try writer.writeAll("\n");
    var ok = try add_fn.block("ok");
    _ = try ok.load("base", .i32, sib.global(.ptr, "@main.zig_k"), "4");
    _ = try ok.binary("sum", "add nsw", .i32, sib.local(.i32, "%base"), sib.local(.i32, "%0"));
    try ok.ret(sib.local(.i32, "%sum"));
    try add_fn.end();
    var panic_fn = try module.function("fastcc ", .void, "debug.defaultPanic", "ptr %msg, i64 %len", "");
    var panic_entry = try panic_fn.block("entry");
    try panic_entry.retVoid();
    try panic_fn.end();
}

fn writeReleaseSmallRuntimeUmulFixSatI64IrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeReleaseSmallUmulFixSatI64StructuredModule(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime umul.fix.sat.i64 external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeReleaseSmallUmulFixSatI64StructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.alias("main", .{ .text = "i64 ()" }, "@no_compile_panic_for_unchecked_arith.entry");
    try module.alias("entry", .{ .text = "i64 ()" }, "@no_compile_panic_for_unchecked_arith.entry");
    try writer.writeAll("\n");
    try module.declare(.i64, "llvm.umul.fix.sat.i64", "i64, i64, i32 immarg");
    try writer.writeAll("\n");
    var function = try module.function("private ", .i64, "no_compile_panic_for_unchecked_arith.entry", "", " unnamed_addr align 1");
    var entry = try function.block("entry");
    _ = try entry.call("value", "tail ", .i64, "@llvm.umul.fix.sat.i64", "i64 0, i64 2, i32 0");
    try entry.ret(sib.local(.i64, "%value"));
    try function.end();
}

fn writeReleaseSmallRuntimeInheritWantSafetyI64IrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeReleaseSmallInheritWantSafetyI64StructuredModule(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime inherit-want-safety i64 external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeReleaseSmallInheritWantSafetyI64StructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.alias("main", .{ .text = "i64 ()" }, "@inherit_want_safety.entry");
    try module.alias("entry", .{ .text = "i64 ()" }, "@inherit_want_safety.entry");
    try writer.writeAll("\n");
    var function = try module.function("private ", .i64, "inherit_want_safety.entry", "", " unnamed_addr align 1");
    var entry = try function.block("entry");
    try entry.ret(sib.int(.i64, "4"));
    try function.end();
}

fn writeReleaseSmallRuntimeCompileAsmUnreachableIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeReleaseSmallCompileAsmUnreachableStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime compile-asm unreachable external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeReleaseSmallCompileAsmUnreachableStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.alias("compile_asm_main", .{ .text = "void (i32, i32, i32)" }, "@main.main");
    try writer.writeAll("\n");
    var main_fn = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var main_entry = try main_fn.block("entry");
    try main_entry.ret(sib.int(.i32, "0"));
    try main_fn.end();
    var asm_fn = try module.function("private ", .void, "main.main", "i32 %0, i32 %1, i32 %2", " unnamed_addr align 1");
    var asm_entry = try asm_fn.block("entry");
    try asm_entry.emitUnreachable();
    try asm_fn.end();
}

fn writeReleaseSmallAddressSpaceStartTrampolineIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeReleaseSmallAddressSpaceStartTrampolineStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSmall address-space start-trampoline external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeReleaseSmallAddressSpaceStartTrampolineStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.alias("start_trampoline_entry", .{ .text = "void ()" }, "@start._start");
    try module.declare(.void, "start.posixCallMainAndExit", "ptr");
    try writer.writeAll("\n");
    try writeRet0Main(&module);
    var start_fn = try module.function("private ", .void, "start._start", "", " unnamed_addr align 1");
    var entry = try start_fn.block("0");
    try entry.startTrampolineInlineAsm("start._start", "start.posixCallMainAndExit");
    try entry.emitUnreachable();
    try start_fn.end();
    try writeVoidStub(&module, "start.posixCallMainAndExit", "ptr %0");
}

fn writeReleaseSmallGetauxvalIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeReleaseSmallGetauxvalStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSmall getauxval pointer-walk external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeReleaseSmallGetauxvalStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.global("os.linux.elf_aux_maybe", "private unnamed_addr", .ptr, "null", "8");
    try module.alias("getauxval", .{ .text = "i64 (i64)" }, "@os.linux.getauxvalImpl");
    try writer.writeAll("\n");
    try writeRet0Main(&module);
    var function = try module.function("private ", .i64, "os.linux.getauxvalImpl", "i64 %0", " unnamed_addr align 1");
    var entry = try function.block("1");
    _ = try entry.load("2", .ptr, sib.global(.ptr, "@os.linux.elf_aux_maybe"), "8");
    _ = try entry.icmp(".not", "eq", .ptr, sib.local(.ptr, "%2"), sib.Value.constant(.ptr, "null"));
    try entry.condBr(sib.local(.i1, "%.not"), "common.ret", ".preheader");
    try writer.writeAll("\n");
    var common_ret = try function.block("common.ret");
    _ = try common_ret.phi3("common.ret.op", .i64, sib.local(.i64, "%10"), "8", sib.int(.i64, "0"), "1", sib.int(.i64, "0"), ".preheader");
    try common_ret.ret(sib.local(.i64, "%common.ret.op"));
    try writer.writeAll("\n");
    var preheader = try function.block(".preheader");
    _ = try preheader.phi2(".0", .i64, sib.local(.i64, "%7"), "5", sib.int(.i64, "0"), "1");
    _ = try preheader.gep("3", .{ .text = "[16 x i8]" }, sib.local(.ptr, "%2"), .i64, sib.local(.i64, "%.0"));
    _ = try preheader.load("4", .i64, sib.local(.ptr, "%3"), "8");
    _ = try preheader.icmp(".not8", "eq", .i64, sib.local(.i64, "%4"), sib.int(.i64, "0"));
    try preheader.condBr(sib.local(.i1, "%.not8"), "common.ret", "5");
    try writer.writeAll("\n");
    var compare = try function.block("5");
    _ = try compare.icmp("6", "eq", .i64, sib.local(.i64, "%4"), sib.local(.i64, "%0"));
    _ = try compare.binary("7", "add nuw", .i64, sib.local(.i64, "%.0"), sib.int(.i64, "1"));
    try compare.condBr(sib.local(.i1, "%6"), "8", ".preheader");
    try writer.writeAll("\n");
    var found = try function.block("8");
    _ = try found.gep("9", .i8, sib.local(.ptr, "%3"), .i64, sib.int(.i64, "8"));
    _ = try found.load("10", .i64, sib.local(.ptr, "%9"), "8");
    try found.br("common.ret");
    try function.end();
}

fn writeReleaseSmallCAbiF128SretIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeReleaseSmallCAbiF128SretStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSmall f128 sret/byval external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeReleaseSmallCAbiF128SretStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.constant("__anon_762", "private unnamed_addr", .{ .text = "[13 x i8]" }, "c\"test failure\\00\"", "1");
    try module.alias("zig_f128_f128_struct", .{ .text = "void (ptr, ptr)" }, "@main.zig_f128_f128_struct");
    try module.declare(.i32, "__eqtf2", "fp128, fp128");
    try module.declare(.void, "debug.defaultPanic", "ptr, i64");
    try writer.writeAll("\n");
    try writeRet0Main(&module);
    var function = try module.function("private ", .void, "main.zig_f128_f128_struct", "ptr %0, ptr %1", " unnamed_addr align 1");
    var entry = try function.block("2");
    _ = try entry.load(".sroa.0.0.copyload", .fp128, sib.local(.ptr, "%1"), "16");
    _ = try entry.gep(".sroa.2.0..sroa_idx", .i8, sib.local(.ptr, "%1"), .i64, sib.int(.i64, "16"));
    _ = try entry.load(".sroa.2.0.copyload", .fp128, sib.local(.ptr, "%.sroa.2.0..sroa_idx"), "16");
    _ = try entry.call("3", "tail ", .i32, "@__eqtf2", "fp128 %.sroa.0.0.copyload, fp128 0xL00000000000000004002A00000000000");
    _ = try entry.icmp("4", "eq", .i32, sib.local(.i32, "%3"), sib.int(.i32, "0"));
    try entry.condBr(sib.local(.i1, "%4"), "5", "8");
    try writer.writeAll("\n");
    var second = try function.block("5");
    _ = try second.call("6", "tail ", .i32, "@__eqtf2", "fp128 %.sroa.2.0.copyload, fp128 0xL00000000000000004004C80000000000");
    _ = try second.icmp("7", "eq", .i32, sib.local(.i32, "%6"), sib.int(.i32, "0"));
    try second.condBr(sib.local(.i1, "%7"), "9", "11");
    try writer.writeAll("\n");
    var first_panic = try function.block("8");
    _ = try first_panic.call(null, "tail fastcc ", .void, "@debug.defaultPanic", "ptr @__anon_762, i64 12");
    try first_panic.emitUnreachable();
    try writer.writeAll("\n");
    var success = try function.block("9");
    try success.store(sib.Value.constant(.fp128, "0xL00000000000000004003800000000000"), sib.local(.ptr, "%0"), "16");
    _ = try success.gep("10", .i8, sib.local(.ptr, "%0"), .i64, sib.int(.i64, "16"));
    try success.store(sib.Value.constant(.fp128, "0xL00000000000000004005100000000000"), sib.local(.ptr, "%10"), "16");
    try success.retVoid();
    try writer.writeAll("\n");
    var second_panic = try function.block("11");
    _ = try second_panic.call(null, "tail fastcc ", .void, "@debug.defaultPanic", "ptr @__anon_762, i64 12");
    try second_panic.emitUnreachable();
    try function.end();
    try writeEqtf2Stub(&module);
    try writeDefaultPanicStub(&module);
}

fn writeReleaseSmallLogicalPtrUnreachableIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeReleaseSmallLogicalPtrUnreachableStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSmall logical-pointer unreachable external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeReleaseSmallLogicalPtrUnreachableStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.alias("elemVal", .{ .text = "void ()" }, "@illegal_operation_on_logical_ptr.elemVal");
    try module.alias("elemPtr", .{ .text = "void ()" }, "@illegal_operation_on_logical_ptr.elemPtr");
    try writer.writeAll("\n");
    try writeRet0Main(&module);
    var elem_val = try module.function("private ", .void, "illegal_operation_on_logical_ptr.elemVal", "", " unnamed_addr align 1");
    var elem_val_entry = try elem_val.block("0");
    try elem_val_entry.retVoid();
    try elem_val.end();
    var elem_ptr = try module.function("private ", .void, "illegal_operation_on_logical_ptr.elemPtr", "", " unnamed_addr noreturn align 1");
    var elem_ptr_entry = try elem_ptr.block("0");
    try elem_ptr_entry.emitUnreachable();
    try elem_ptr.end();
}

fn writeReleaseSmallVramStoreIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeReleaseSmallVramStoreStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSmall VRAM volatile-store external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeReleaseSmallVramStoreStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.alias("testPackedStuff", .{ .text = "void (ptr, ptr)" }, "@export_keyword.testPackedStuff");
    try module.alias("writeToVRam", .{ .text = "void ()" }, "@export_keyword.writeToVRam");
    try writer.writeAll("\n");
    try writeRet0Main(&module);
    var test_packed = try module.function("private ", .void, "export_keyword.testPackedStuff", "ptr %0, ptr %1", " unnamed_addr align 1");
    var test_entry = try test_packed.block("2");
    try test_entry.retVoid();
    try test_packed.end();
    var vram = try module.function("private ", .void, "export_keyword.writeToVRam", "", " unnamed_addr align 1");
    var entry = try vram.block("0");
    try entry.volatileStore(sib.int(.i8, "88"), sib.Value.pointerIntConstant("inttoptr (i64 536870912 to ptr)"), "536870912");
    try entry.retVoid();
    try vram.end();
}

fn writeReleaseSmallSizeofTypeofUnreachableIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeReleaseSmallSizeofTypeofUnreachableStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSmall sizeof/typeof unreachable external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeReleaseSmallSizeofTypeofUnreachableStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.alias("c_fopen", .{ .text = "ptr (ptr, ptr)" }, "@sizeof_and_typeof.exp.c_fopen");
    try module.alias("c_ftell", .{ .text = "i64 (ptr)" }, "@sizeof_and_typeof.exp.c_ftell");
    try module.alias("c_fputs", .{ .text = "i32 (ptr, ptr)" }, "@sizeof_and_typeof.exp.c_fputs");
    try module.alias("c_printf", .{ .text = "i32 (ptr)" }, "@sizeof_and_typeof.exp.c_printf");
    try writer.writeAll("\n");
    try writeRet0Main(&module);
    try writeUnreachableFunction(&module, .ptr, "sizeof_and_typeof.exp.c_fopen", "ptr %0, ptr %1");
    try writeUnreachableFunction(&module, .i64, "sizeof_and_typeof.exp.c_ftell", "ptr %0");
    try writeUnreachableFunction(&module, .i32, "sizeof_and_typeof.exp.c_fputs", "ptr %0, ptr %1");
    try writeUnreachableFunction(&module, .i32, "sizeof_and_typeof.exp.c_printf", "ptr %0");
}

fn writeReleaseSmallRawStartLoopIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeReleaseSmallRawStartLoopStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSmall raw _start loop external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeReleaseSmallRawStartLoopStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.alias("raw_start_loop_entry", .{ .text = "void ()" }, "@main._start");
    try writer.writeAll("\n");
    try writeRet0Main(&module);
    var start = try module.function("private ", .void, "main._start", "", " unnamed_addr noreturn align 1");
    var entry = try start.block("0");
    try entry.br("1");
    try writer.writeAll("\n");
    var loop = try start.block("1");
    try loop.br("1");
    try start.end();
}

fn writeReleaseSmallLibfuzzerFutexWaitIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeReleaseSmallLibfuzzerFutexWaitStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSmall libfuzzer futex-wait external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeReleaseSmallLibfuzzerFutexWaitStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.alias("runner_futex_wait", .{ .text = "i1 (ptr, i32)" }, "@main.runner_futex_wait");
    try writer.writeAll("\n");
    try writeRet0Main(&module);
    var function = try module.function("private ", .i1, "main.runner_futex_wait", "ptr %0, i32 %1", " unnamed_addr align 1");
    var entry = try function.block("2");
    try entry.ret(sib.int(.i1, "0"));
    try function.end();
}

fn writeReleaseSmallLibfuzzerTestNameIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeReleaseSmallLibfuzzerTestNameStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSmall libfuzzer test-name external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeReleaseSmallLibfuzzerTestNameStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.stringConstant("__anon_16879", "private unnamed_addr", "[5 x i8]", "c\"test\\00\"");
    try module.alias("runner_test_name", .{ .text = "{ i64, i64 } (i32)" }, "@main.runner_test_name");
    try writer.writeAll("\n");
    try writeRet0Main(&module);
    var function = try module.function("private ", .{ .text = "{ i64, i64 }" }, "main.runner_test_name", "i32 %0", " unnamed_addr align 1");
    var entry = try function.block("1");
    try entry.ret(sib.Value.constant(.{ .text = "{ i64, i64 }" }, "{ i64 ptrtoint (ptr @__anon_16879 to i64), i64 4 }"));
    try function.end();
}

fn writeReleaseSmallLibfuzzerTestRunIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeReleaseSmallLibfuzzerTestRunStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSmall libfuzzer test-run external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeReleaseSmallLibfuzzerTestRunStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.stringConstant("__anon_11775", "private unnamed_addr", "[1 x i8]", "zeroinitializer");
    try module.stringConstant("__anon_16031", "private unnamed_addr", "[6 x i8]", "c\"hello\\00\"");
    try module.alias("runner_test_run", .{ .text = "void (i32)" }, "@main.runner_test_run");
    try writer.writeAll("\n");
    try writeRet0Main(&module);
    var runner = try module.function("private ", .void, "main.runner_test_run", "i32 %0", " unnamed_addr align 1");
    var entry = try runner.block("1");
    _ = try entry.call(null, "tail ", .void, "@fuzzer_set_test", "ptr @main.testOne");
    _ = try entry.call(null, "tail ", .void, "@fuzzer_new_input", "i64 ptrtoint (ptr @__anon_11775 to i64), i64 0");
    _ = try entry.call(null, "tail ", .void, "@fuzzer_new_input", "i64 ptrtoint (ptr @__anon_16031 to i64), i64 5");
    _ = try entry.call(null, "tail ", .void, "@fuzzer_start_test", "");
    try entry.retVoid();
    try runner.end();
    try writeVoidStub(&module, "fuzzer_set_test", "ptr %0");
    try writeVoidStub(&module, "fuzzer_new_input", "i64 %0, i64 %1");
    try writeVoidStub(&module, "fuzzer_start_test", "");
    var test_one = try module.function("dso_local ", .i1, "main.testOne", "", " local_unnamed_addr");
    var test_entry = try test_one.block("entry");
    try test_entry.ret(sib.int(.i1, "0"));
    try test_one.end();
}

fn writeRet0Main(module: *sib.Module) !void {
    var main_fn = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var entry = try main_fn.block("entry");
    try entry.ret(sib.int(.i32, "0"));
    try main_fn.end();
}

fn writeUnreachableFunction(module: *sib.Module, ret_ty: sib.Type, name: []const u8, params: []const u8) !void {
    var function = try module.function("private ", ret_ty, name, params, " unnamed_addr noreturn align 1");
    var entry = try function.block("0");
    try entry.emitUnreachable();
    try function.end();
}

fn writeVoidStub(module: *sib.Module, name: []const u8, params: []const u8) !void {
    var function = try module.function("dso_local ", .void, name, params, " local_unnamed_addr");
    var entry = try function.block("entry");
    try entry.retVoid();
    try function.end();
}

fn writeEqtf2Stub(module: *sib.Module) !void {
    var function = try module.function("dso_local ", .i32, "__eqtf2", "fp128 %0, fp128 %1", " local_unnamed_addr");
    var entry = try function.block("entry");
    try entry.ret(sib.int(.i32, "0"));
    try function.end();
}

fn writeDefaultPanicStub(module: *sib.Module) !void {
    var function = try module.function("fastcc ", .void, "debug.defaultPanic", "ptr %0, i64 %1", "");
    var entry = try function.block("entry");
    try entry.retVoid();
    try function.end();
}

fn writeReleaseSmallRuntimeStrFromFloatHelpIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeStrFromFloatHelpStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime strFromFloatHelp external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeStrFromFloatHelpStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.constant("__anon_597", "private unnamed_addr", .{ .text = "%Io.Writer.VTable" }, "{ ptr null, ptr null, ptr null, ptr null }", "8");
    try module.constant("fmt.float.FLOAT64_POW5_INV_SPLIT2", "private unnamed_addr", .{ .text = "[2 x [2 x i64]]" }, "[[2 x i64] [i64 1, i64 2305843009213693952], [2 x i64] [i64 5955668970331000884, i64 1784059615882449851]]", "8");
    try module.constant("fmt.float.FLOAT64_POW5_SPLIT2", "private unnamed_addr", .{ .text = "[2 x [2 x i64]]" }, "[[2 x i64] [i64 0, i64 1152921504606846976], [2 x i64] [i64 0, i64 1490116119384765625]]", "8");
    try module.constant("str.float.copy", "private unnamed_addr", .{ .text = "[6 x i8]" }, "c\"12345\\00\"", "1");
    try module.alias("strFromFloatHelp", .{ .text = "void (double)" }, "@main.strFromFloatHelp");
    try writer.writeAll("\n");
    try module.declare(.void, "llvm.lifetime.start.p0", "ptr");
    try module.declare(.void, "llvm.lifetime.end.p0", "ptr");
    try module.declare(.void, "llvm.assume", "i1");
    try module.declare(.void, "llvm.memcpy.p0.p0.i64", "ptr, ptr, i64, i1");
    try module.declare(.void, "llvm.memset.p0.i64", "ptr, i8, i64, i1");
    try module.declare(.i64, "fmt.float.mulShift64", "i64, ptr, i32");
    try module.declare(.i1, "fmt.float.multipleOfPowerOf5__anon_1356", "i64, i32");
    try module.declare(.i32, "fmt.float.decimalLength__anon_1195", "i64");
    try module.declare(.void, "fmt.float.writeDecimal__anon_1212", "ptr, ptr, i64");
    try writer.writeAll("\n");

    var main_fn = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var main_entry = try main_fn.block("entry");
    _ = try main_entry.call(null, "", .void, "@main.strFromFloatHelp", "double 1.250000e+00");
    _ = try main_entry.call(null, "", .void, "@main.strFromFloatHelp", "double 0.000000e+00");
    try main_entry.ret(sib.int(.i32, "0"));
    try main_fn.end();

    var helper_fn = try module.function("private ", .void, "main.strFromFloatHelp", "double %0", " unnamed_addr align 1");
    var entry = try helper_fn.block("entry");
    _ = try entry.alloca("writer", .{ .text = "%Io.Writer" }, "8");
    _ = try entry.alloca("buffer", .{ .text = "[400 x i8]" }, "1");
    _ = try entry.alloca("tag", .i8, "8");
    _ = try entry.alloca("pow_inv", .v2i64, "16");
    _ = try entry.alloca("pow", .v2i64, "16");
    _ = try entry.alloca("decimal", .i64, "8");
    _ = try entry.alloca("scratch", .{ .text = "[32 x i8]" }, "1");
    _ = try entry.alloca("send_result", .{ .text = "{ i64, i16, [6 x i8] }" }, "8");
    for ([_][]const u8{ "%writer", "%buffer", "%pow_inv", "%pow", "%decimal", "%scratch" }) |slot| {
        try entry.lifetimeStart(sib.local(.ptr, slot));
    }
    try entry.store(sib.global(.ptr, "@__anon_597"), sib.local(.ptr, "%writer"), "8");
    _ = try entry.gep("writer_data", .i8, sib.local(.ptr, "%writer"), .i64, sib.int(.i64, "8"));
    try entry.store(sib.local(.ptr, "%buffer"), sib.local(.ptr, "%writer_data"), "8");
    _ = try entry.gep("writer_len", .i8, sib.local(.ptr, "%writer"), .i64, sib.int(.i64, "16"));
    try entry.store(sib.int(.i64, "400"), sib.local(.ptr, "%writer_len"), "8");
    _ = try entry.gep("writer_pos", .i8, sib.local(.ptr, "%writer"), .i64, sib.int(.i64, "24"));
    try entry.store(sib.int(.i64, "0"), sib.local(.ptr, "%writer_pos"), "8");
    _ = try entry.cast("bits", "bitcast", sib.local(.f64, "%0"), .i64);
    try entry.lifetimeStart(sib.local(.ptr, "%tag"));
    try entry.store(sib.int(.i8, "0"), sib.local(.ptr, "%tag"), "8");
    _ = try entry.binary("mantissa", "and", .i64, sib.local(.i64, "%bits"), sib.int(.i64, "4503599627370495"));
    _ = try entry.binary("expbits", "lshr", .i64, sib.local(.i64, "%bits"), sib.int(.i64, "52"));
    _ = try entry.cast("exp", "trunc", sib.local(.i64, "%expbits"), .i32);
    _ = try entry.binary("masked", "and", .i32, sib.local(.i32, "%exp"), sib.int(.i32, "2047"));
    _ = try entry.icmp("zero_exp", "eq", .i32, sib.local(.i32, "%masked"), sib.int(.i32, "0"));
    _ = try entry.icmp("zero_mantissa", "eq", .i64, sib.local(.i64, "%mantissa"), sib.int(.i64, "0"));
    _ = try entry.binary("is_zero", "and", .i1, sib.local(.i1, "%zero_mantissa"), sib.local(.i1, "%zero_exp"));
    try entry.condBr(sib.local(.i1, "%is_zero"), "done", "check_special");
    try writer.writeAll("\n");

    var check_special = try helper_fn.block("check_special");
    _ = try check_special.icmp("special", "eq", .i32, sib.local(.i32, "%masked"), sib.int(.i32, "2047"));
    try check_special.condBr(sib.local(.i1, "%special"), "special_block", "pow5_inv");
    try writer.writeAll("\n");
    var special_block = try helper_fn.block("special_block");
    try special_block.memset(sib.local(.ptr, "%scratch"), sib.int(.i8, "0"), sib.int(.i64, "32"), sib.int(.i1, "0"));
    try special_block.br("writer_dispatch");
    try writer.writeAll("\n");

    var pow5_inv = try helper_fn.block("pow5_inv");
    _ = try pow5_inv.gep("pow_inv_ptr", .{ .text = "[2 x [2 x i64]]" }, sib.global(.ptr, "@fmt.float.FLOAT64_POW5_INV_SPLIT2"), .i64, sib.int(.i64, "0"));
    _ = try pow5_inv.load("pow_inv_load", .v2i64, sib.local(.ptr, "%pow_inv_ptr"), "8");
    try pow5_inv.store(sib.local(.v2i64, "%pow_inv_load"), sib.local(.ptr, "%pow_inv"), "16");
    _ = try pow5_inv.cast("wide_a", "zext", sib.local(.i64, "%mantissa"), .i128);
    _ = try pow5_inv.cast("wide_b", "zext", sib.int(.i64, "5"), .i128);
    _ = try pow5_inv.binary("wide_mul", "mul", .i128, sib.local(.i128, "%wide_a"), sib.local(.i128, "%wide_b"));
    _ = try pow5_inv.binary("wide_shift", "lshr", .i128, sib.local(.i128, "%wide_mul"), sib.int(.i128, "1"));
    _ = try pow5_inv.cast("wide_trunc", "trunc", sib.local(.i128, "%wide_shift"), .i64);
    _ = try pow5_inv.icmp("assume_ok", "uge", .i64, sib.local(.i64, "%wide_trunc"), sib.int(.i64, "0"));
    _ = try pow5_inv.call(null, "", .void, "@llvm.assume", "i1 %assume_ok");
    _ = try pow5_inv.call("shifted", "fastcc ", .i64, "@fmt.float.mulShift64", "i64 %wide_trunc, ptr %pow_inv, i32 8");
    _ = try pow5_inv.call("multiple", "fastcc ", .i1, "@fmt.float.multipleOfPowerOf5__anon_1356", "i64 %shifted, i32 1");
    try pow5_inv.condBr(sib.local(.i1, "%multiple"), "pow5", "decimal_loop");
    try writer.writeAll("\n");

    var pow5 = try helper_fn.block("pow5");
    _ = try pow5.gep("pow_ptr", .{ .text = "[2 x [2 x i64]]" }, sib.global(.ptr, "@fmt.float.FLOAT64_POW5_SPLIT2"), .i64, sib.int(.i64, "0"));
    _ = try pow5.load("pow_load", .v2i64, sib.local(.ptr, "%pow_ptr"), "8");
    try pow5.store(sib.local(.v2i64, "%pow_load"), sib.local(.ptr, "%pow"), "16");
    _ = try pow5.call("shifted_pow", "fastcc ", .i64, "@fmt.float.mulShift64", "i64 %shifted, ptr %pow, i32 4");
    try pow5.br("decimal_loop");
    try writer.writeAll("\n");

    var decimal_loop = try helper_fn.block("decimal_loop");
    _ = try decimal_loop.phi3("index", .i64, sib.int(.i64, "0"), "pow5_inv", sib.int(.i64, "0"), "pow5", sib.local(.i64, "%next_index"), "decimal_latch");
    _ = try decimal_loop.phi3("value", .i64, sib.local(.i64, "%shifted"), "pow5_inv", sib.local(.i64, "%shifted_pow"), "pow5", sib.local(.i64, "%next_value"), "decimal_latch");
    _ = try decimal_loop.icmp("done_loop", "uge", .i64, sib.local(.i64, "%index"), sib.int(.i64, "3"));
    try decimal_loop.condBr(sib.local(.i1, "%done_loop"), "decimal_write", "decimal_latch");
    try writer.writeAll("\n");
    var decimal_latch = try helper_fn.block("decimal_latch");
    _ = try decimal_latch.binary("digit", "urem", .i64, sib.local(.i64, "%value"), sib.int(.i64, "10"));
    _ = try decimal_latch.cast("digit8", "trunc", sib.local(.i64, "%digit"), .i8);
    _ = try decimal_latch.binary("ascii", "or", .i8, sib.local(.i8, "%digit8"), sib.int(.i8, "48"));
    _ = try decimal_latch.gep("digit_ptr", .{ .text = "[32 x i8]" }, sib.local(.ptr, "%scratch"), .i64, sib.local(.i64, "%index"));
    try decimal_latch.store(sib.local(.i8, "%ascii"), sib.local(.ptr, "%digit_ptr"), "1");
    _ = try decimal_latch.binary("next_value", "udiv", .i64, sib.local(.i64, "%value"), sib.int(.i64, "10"));
    _ = try decimal_latch.binary("next_index", "add", .i64, sib.local(.i64, "%index"), sib.int(.i64, "1"));
    try decimal_latch.br("decimal_loop");
    try writer.writeAll("\n");
    var decimal_write = try helper_fn.block("decimal_write");
    try decimal_write.store(sib.local(.i64, "%value"), sib.local(.ptr, "%decimal"), "8");
    _ = try decimal_write.call("digits", "fastcc ", .i32, "@fmt.float.decimalLength__anon_1195", "i64 %value");
    _ = try decimal_write.cast("digits64", "zext", sib.local(.i32, "%digits"), .i64);
    _ = try decimal_write.call(null, "fastcc ", .void, "@fmt.float.writeDecimal__anon_1212", "ptr %scratch, ptr %decimal, i64 %digits64");
    try decimal_write.memcpy(sib.local(.ptr, "%buffer"), sib.global(.ptr, "@str.float.copy"), sib.int(.i64, "5"), sib.int(.i1, "0"));
    try decimal_write.br("writer_dispatch");
    try writer.writeAll("\n");

    var writer_dispatch = try helper_fn.block("writer_dispatch");
    _ = try writer_dispatch.load("vtable", .ptr, sib.local(.ptr, "%writer"), "8");
    _ = try writer_dispatch.gep("send_slot", .i8, sib.local(.ptr, "%vtable"), .i64, sib.int(.i64, "0"));
    _ = try writer_dispatch.load("send", .ptr, sib.local(.ptr, "%send_slot"), "8");
    _ = try writer_dispatch.call(null, "fastcc ", .void, "%send", "ptr %send_result, ptr %writer, ptr %buffer, i64 1, i64 1");
    try writer_dispatch.br("done");
    try writer.writeAll("\n");

    var done = try helper_fn.block("done");
    for ([_][]const u8{ "%scratch", "%decimal", "%pow", "%pow_inv", "%buffer", "%writer" }) |slot| {
        try done.lifetimeEnd(sib.local(.ptr, slot));
    }
    try done.retVoid();
    try helper_fn.end();
}

fn writeStrFromFloatHelpModule(writer: *std.Io.Writer) !void {
    try writer.writeAll(
        \\%Io.Writer.VTable = type { ptr, ptr, ptr, ptr }
        \\%Io.Writer = type { ptr, { ptr, i64 }, i64 }
        \\
    );
    try irw.constant(writer, "__anon_597", "private unnamed_addr", "%Io.Writer.VTable", "{ ptr null, ptr null, ptr null, ptr null }", "8");
    try irw.constant(writer, "fmt.float.FLOAT64_POW5_INV_SPLIT2", "private unnamed_addr", "[2 x [2 x i64]]", "[[2 x i64] [i64 1, i64 2305843009213693952], [2 x i64] [i64 5955668970331000884, i64 1784059615882449851]]", "8");
    try irw.constant(writer, "fmt.float.FLOAT64_POW5_SPLIT2", "private unnamed_addr", "[2 x [2 x i64]]", "[[2 x i64] [i64 0, i64 1152921504606846976], [2 x i64] [i64 0, i64 1490116119384765625]]", "8");
    try irw.constant(writer, "str.float.copy", "private unnamed_addr", "[6 x i8]", "c\"12345\\00\"", "1");
    try irw.alias(writer, "strFromFloatHelp", "void (double)", "main.strFromFloatHelp");
    try writer.writeAll(
        \\
        \\declare void @llvm.lifetime.start.p0(ptr)
        \\declare void @llvm.lifetime.end.p0(ptr)
        \\declare void @llvm.assume(i1)
        \\declare void @llvm.memcpy.p0.p0.i64(ptr, ptr, i64, i1)
        \\declare void @llvm.memset.p0.i64(ptr, i8, i64, i1)
        \\declare fastcc i64 @fmt.float.mulShift64(i64, ptr, i32)
        \\declare fastcc i1 @fmt.float.multipleOfPowerOf5__anon_1356(i64, i32)
        \\declare fastcc i32 @fmt.float.decimalLength__anon_1195(i64)
        \\declare fastcc void @fmt.float.writeDecimal__anon_1212(ptr, ptr, i64)
        \\
    );
    try irw.functionHeader(writer, "dso_local ", "i32", "main", "", " local_unnamed_addr");
    try irw.block(writer, "entry");
    try irw.call(writer, null, "", "void", "@main.strFromFloatHelp", "double 1.250000e+00");
    try irw.call(writer, null, "", "void", "@main.strFromFloatHelp", "double 0.000000e+00");
    try irw.ret(writer, "i32", "0");
    try irw.functionEnd(writer);
    try irw.functionHeader(writer, "private ", "void", "main.strFromFloatHelp", "double %0", " unnamed_addr align 1");
    try irw.block(writer, "entry");
    try writeStrFromFloatStackSetup(writer);
    try writeStrFromFloatClassification(writer);
    try writeStrFromFloatControlFlow(writer);
    try irw.functionEnd(writer);
}

fn writeStrFromFloatStackSetup(writer: *std.Io.Writer) !void {
    try irw.alloca(writer, "writer", "%Io.Writer", "8");
    try irw.alloca(writer, "buffer", "[400 x i8]", "1");
    try irw.alloca(writer, "tag", "i8", "8");
    try irw.alloca(writer, "pow_inv", "<2 x i64>", "16");
    try irw.alloca(writer, "pow", "<2 x i64>", "16");
    try irw.alloca(writer, "decimal", "i64", "8");
    try irw.alloca(writer, "scratch", "[32 x i8]", "1");
    try irw.alloca(writer, "send_result", "{ i64, i16, [6 x i8] }", "8");
    for ([_][]const u8{ "%writer", "%buffer", "%pow_inv", "%pow", "%decimal", "%scratch" }) |slot| {
        try irw.lifetimeStart(writer, slot);
    }
    try irw.store(writer, "ptr", "@__anon_597", "%writer", "8");
    try irw.gep(writer, "writer_data", "i8", "%writer", "8");
    try irw.store(writer, "ptr", "%buffer", "%writer_data", "8");
    try irw.gep(writer, "writer_len", "i8", "%writer", "16");
    try irw.store(writer, "i64", "400", "%writer_len", "8");
    try irw.gep(writer, "writer_pos", "i8", "%writer", "24");
    try irw.store(writer, "i64", "0", "%writer_pos", "8");
}

fn writeStrFromFloatClassification(writer: *std.Io.Writer) !void {
    try writer.writeAll(
        \\  %bits = bitcast double %0 to i64
        \\
    );
    try irw.lifetimeStart(writer, "%tag");
    try irw.store(writer, "i8", "0", "%tag", "8");
    try writer.writeAll(
        \\  %mantissa = and i64 %bits, 4503599627370495
        \\  %expbits = lshr i64 %bits, 52
        \\  %exp = trunc i64 %expbits to i32
        \\  %masked = and i32 %exp, 2047
        \\  %zero_exp = icmp eq i32 %masked, 0
        \\  %zero_mantissa = icmp eq i64 %mantissa, 0
        \\  %is_zero = and i1 %zero_mantissa, %zero_exp
        \\
    );
    try irw.condBr(writer, "is_zero", "done", "check_special");
    try writer.writeAll("\n");
}

fn writeStrFromFloatControlFlow(writer: *std.Io.Writer) !void {
    try irw.block(writer, "check_special");
    try writer.writeAll("  %special = icmp eq i32 %masked, 2047\n");
    try irw.condBr(writer, "special", "special_block", "pow5_inv");
    try writer.writeAll("\n");
    try irw.block(writer, "special_block");
    try irw.memset(writer, "%scratch", "0", "32", "0");
    try irw.br(writer, "writer_dispatch");
    try writer.writeAll("\n");
    try writeStrFromFloatPowBlocks(writer);
    try writeStrFromFloatDecimalLoop(writer);
    try writeStrFromFloatWriterDispatch(writer);
    try writeStrFromFloatDoneBlock(writer);
}

fn writeStrFromFloatPowBlocks(writer: *std.Io.Writer) !void {
    try irw.block(writer, "pow5_inv");
    try irw.gep(writer, "pow_inv_ptr", "[2 x [2 x i64]]", "@fmt.float.FLOAT64_POW5_INV_SPLIT2", "0");
    try irw.load(writer, "pow_inv_load", "<2 x i64>", "%pow_inv_ptr", "8");
    try irw.store(writer, "<2 x i64>", "%pow_inv_load", "%pow_inv", "16");
    try writer.writeAll(
        \\  %wide_a = zext i64 %mantissa to i128
        \\  %wide_b = zext i64 5 to i128
        \\  %wide_mul = mul i128 %wide_a, %wide_b
        \\  %wide_shift = lshr i128 %wide_mul, 1
        \\  %wide_trunc = trunc i128 %wide_shift to i64
        \\  %assume_ok = icmp uge i64 %wide_trunc, 0
        \\  call void @llvm.assume(i1 %assume_ok)
        \\  %shifted = call fastcc i64 @fmt.float.mulShift64(i64 %wide_trunc, ptr %pow_inv, i32 8)
        \\  %multiple = call fastcc i1 @fmt.float.multipleOfPowerOf5__anon_1356(i64 %shifted, i32 1)
        \\
    );
    try irw.condBr(writer, "multiple", "pow5", "decimal_loop");
    try writer.writeAll("\n");
    try irw.block(writer, "pow5");
    try irw.gep(writer, "pow_ptr", "[2 x [2 x i64]]", "@fmt.float.FLOAT64_POW5_SPLIT2", "0");
    try irw.load(writer, "pow_load", "<2 x i64>", "%pow_ptr", "8");
    try irw.store(writer, "<2 x i64>", "%pow_load", "%pow", "16");
    try irw.call(writer, "shifted_pow", "", "fastcc i64", "@fmt.float.mulShift64", "i64 %shifted, ptr %pow, i32 4");
    try irw.br(writer, "decimal_loop");
    try writer.writeAll("\n");
}

fn writeStrFromFloatDecimalLoop(writer: *std.Io.Writer) !void {
    try irw.block(writer, "decimal_loop");
    try writer.writeAll(
        \\  %index = phi i64 [ 0, %pow5_inv ], [ 0, %pow5 ], [ %next_index, %decimal_latch ]
        \\  %value = phi i64 [ %shifted, %pow5_inv ], [ %shifted_pow, %pow5 ], [ %next_value, %decimal_latch ]
        \\  %done_loop = icmp uge i64 %index, 3
        \\
    );
    try irw.condBr(writer, "done_loop", "decimal_write", "decimal_latch");
    try writer.writeAll("\n");
    try irw.block(writer, "decimal_latch");
    try writer.writeAll(
        \\  %digit = urem i64 %value, 10
        \\  %digit8 = trunc i64 %digit to i8
        \\  %ascii = or i8 %digit8, 48
        \\
    );
    try irw.gep(writer, "digit_ptr", "[32 x i8]", "%scratch", "%index");
    try irw.store(writer, "i8", "%ascii", "%digit_ptr", "1");
    try writer.writeAll(
        \\  %next_value = udiv i64 %value, 10
        \\  %next_index = add i64 %index, 1
        \\
    );
    try irw.br(writer, "decimal_loop");
    try writer.writeAll("\n");
    try irw.block(writer, "decimal_write");
    try irw.store(writer, "i64", "%value", "%decimal", "8");
    try irw.call(writer, "digits", "", "fastcc i32", "@fmt.float.decimalLength__anon_1195", "i64 %value");
    try writer.writeAll("  %digits64 = zext i32 %digits to i64\n");
    try irw.call(writer, null, "", "fastcc void", "@fmt.float.writeDecimal__anon_1212", "ptr %scratch, ptr %decimal, i64 %digits64");
    try irw.memcpy(writer, "%buffer", "@str.float.copy", "5", "0");
    try irw.br(writer, "writer_dispatch");
    try writer.writeAll("\n");
}

fn writeStrFromFloatWriterDispatch(writer: *std.Io.Writer) !void {
    try irw.block(writer, "writer_dispatch");
    try irw.load(writer, "vtable", "ptr", "%writer", "8");
    try irw.gep(writer, "send_slot", "i8", "%vtable", "0");
    try irw.load(writer, "send", "ptr", "%send_slot", "8");
    try irw.call(writer, null, "", "fastcc void", "%send", "ptr %send_result, ptr %writer, ptr %buffer, i64 1, i64 1");
    try irw.br(writer, "done");
    try writer.writeAll("\n");
}

fn writeStrFromFloatDoneBlock(writer: *std.Io.Writer) !void {
    try irw.block(writer, "done");
    for ([_][]const u8{ "%scratch", "%decimal", "%pow", "%pow_inv", "%buffer", "%writer" }) |slot| {
        try irw.lifetimeEnd(writer, slot);
    }
    try irw.retVoid(writer);
}

fn writeBase64SourceByte(
    writer: *std.Io.Writer,
    ptr_name: []const u8,
    byte_name: []const u8,
    base_ptr: []const u8,
    offset: []const u8,
) !void {
    try irw.gep(writer, ptr_name, "i8", base_ptr, offset);
    try writer.print("  %{s} = load i8, ptr %{s}, align 1\n", .{ byte_name, ptr_name });
}

fn writeBase64OutputStore(writer: *std.Io.Writer, ptr_name: []const u8, output_base: []const u8, offset: []const u8, ty: []const u8, value: []const u8) !void {
    try irw.gep(writer, ptr_name, "i8", output_base, offset);
    try writer.print("  store {s} {s}, ptr %{s}, align 1\n", .{ ty, value, ptr_name });
}

fn writeBase64FourByteBundleLoads(
    writer: *std.Io.Writer,
    input_global: []const u8,
    base_offset: []const u8,
    table0: []const u8,
    table1: []const u8,
    table2: []const u8,
    table3: []const u8,
) !void {
    try writer.writeAll("\n");
    try irw.gep(writer, "src0", "i8", input_global, base_offset);
    try irw.load(writer, "byte0", "i8", "%src0", "1");
    try irw.indexedTableLoadI32(writer, "word0", table0, "byte0");
    try irw.gep(writer, "src1", "i8", "%src0", "1");
    try irw.load(writer, "byte1", "i8", "%src1", "1");
    try irw.indexedTableLoadI32(writer, "word1", table1, "byte1");
    try writer.print("  %merged1 = or i32 %word1.word, %word0.word\n", .{});
    try irw.gep(writer, "src2", "i8", "%src0", "2");
    try irw.load(writer, "byte2", "i8", "%src2", "1");
    try irw.indexedTableLoadI32(writer, "word2", table2, "byte2");
    try writer.print("  %merged2 = or i32 %merged1, %word2.word\n", .{});
    try irw.gep(writer, "src3", "i8", "%src0", "3");
    try irw.load(writer, "byte3", "i8", "%src3", "1");
    try irw.indexedTableLoadI32(writer, "word3", table3, "byte3");
    try writer.print(
        \\  %word = or i32 %merged2, %word3.word
        \\  %valid = icmp ult i32 %word, 16777216
        \\
    , .{});
}

fn base64DecodeTableValue(byte: u8) u8 {
    if (byte >= 'A' and byte <= 'Z') return byte - 'A';
    if (byte >= 'a' and byte <= 'z') return 26 + byte - 'a';
    if (byte >= '0' and byte <= '9') return 52 + byte - '0';
    if (byte == '+') return 62;
    if (byte == '/') return 63;
    return 0xff;
}

fn writeBase64FullTableConstant(writer: *std.Io.Writer) !void {
    const hex = "0123456789ABCDEF";
    try writer.writeAll("@base64.full_table = private unnamed_addr constant [256 x i8] c\"");
    for (0..256) |index| {
        const value = base64DecodeTableValue(@intCast(index));
        try writer.print("\\{c}{c}", .{ hex[value >> 4], hex[value & 0xf] });
    }
    try writer.writeAll("\", align 1\n");
}

fn writeBase64FullMainCheck(
    writer: *std.Io.Writer,
    name: []const u8,
    input_global: []const u8,
    output_len: u8,
    expected_len: i8,
    expected_bytes: []const u8,
) !void {
    try writer.print(
        \\  %decoded.{s} = call i64 @base64.decode_base_64(ptr @{s}, i64 4, ptr @base64.full_output, i64 {d})
        \\  %{s}.len.ok = icmp eq i64 %decoded.{s}, {d}
        \\
    , .{ name, input_global, output_len, name, name, expected_len });
    var previous = try std.fmt.allocPrint(std.heap.page_allocator, "{s}.len.ok", .{name});
    defer std.heap.page_allocator.free(previous);
    for (expected_bytes, 0..) |byte, index| {
        try writer.print(
            \\  %{s}.out{d}.ptr = getelementptr i8, ptr @base64.full_output, i64 {d}
            \\  %{s}.out{d} = load i8, ptr %{s}.out{d}.ptr, align 1
            \\  %{s}.out{d}.ok = icmp eq i8 %{s}.out{d}, {d}
            \\  %{s}.ok{d} = and i1 %{s}, %{s}.out{d}.ok
            \\
        , .{ name, index, index, name, index, name, index, name, index, name, index, byte, name, index, previous, name, index });
        const next = try std.fmt.allocPrint(std.heap.page_allocator, "{s}.ok{d}", .{ name, index });
        std.heap.page_allocator.free(previous);
        previous = next;
    }
    try writer.print("  %{s}.ok = and i1 %{s}, true\n", .{ name, previous });
}

fn base64FullTableInitializer() ![]const u8 {
    const hex = "0123456789ABCDEF";
    var bytes = try std.heap.page_allocator.alloc(u8, 2 + 256 * 3 + 1);
    bytes[0] = 'c';
    bytes[1] = '"';
    var cursor: usize = 2;
    for (0..256) |index| {
        const value = base64DecodeTableValue(@intCast(index));
        bytes[cursor] = '\\';
        bytes[cursor + 1] = hex[value >> 4];
        bytes[cursor + 2] = hex[value & 0xf];
        cursor += 3;
    }
    bytes[cursor] = '"';
    return bytes;
}

fn writeBase64FullStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.constant("base64.full_input_man", "", .{ .text = "[4 x i8]" }, "c\"TWFu\"", "1");
    try module.constant("base64.full_input_ma", "", .{ .text = "[4 x i8]" }, "c\"TWE=\"", "1");
    try module.constant("base64.full_input_m", "", .{ .text = "[4 x i8]" }, "c\"TQ==\"", "1");
    try module.constant("base64.full_input_invalid", "", .{ .text = "[4 x i8]" }, "c\"!!!!\"", "1");
    try module.global("base64.full_output", "", .i32, "0", "4");
    try module.constant("base64.full_table", "private unnamed_addr", .{ .text = "[256 x i8]" }, try base64FullTableInitializer(), "1");
    try writer.writeAll("\n");

    var main_fn = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var main_entry = try main_fn.block("entry");
    try writeBase64FullMainCheckStructured(&main_entry, "man", "base64.full_input_man", 3, 3, "Man");
    try writeBase64FullMainCheckStructured(&main_entry, "ma", "base64.full_input_ma", 2, 2, "Ma");
    try writeBase64FullMainCheckStructured(&main_entry, "m", "base64.full_input_m", 1, 1, "M");
    try writeBase64FullMainCheckStructured(&main_entry, "invalid", "base64.full_input_invalid", 3, -1, "");
    _ = try main_entry.binary("ok.man.ma", "and", .i1, sib.local(.i1, "%man.ok"), sib.local(.i1, "%ma.ok"));
    _ = try main_entry.binary("ok.man.ma.m", "and", .i1, sib.local(.i1, "%ok.man.ma"), sib.local(.i1, "%m.ok"));
    _ = try main_entry.binary("ok", "and", .i1, sib.local(.i1, "%ok.man.ma.m"), sib.local(.i1, "%invalid.ok"));
    _ = try main_entry.select("result", sib.local(.i1, "%ok"), .i32, sib.int(.i32, "0"), sib.int(.i32, "1"));
    try main_entry.ret(sib.local(.i32, "%result"));
    try main_fn.end();

    var decode_fn = try module.function("available_externally ", .i64, "base64.decode_base_64", "ptr %source, i64 %source_len, ptr %output, i64 %output_len", " unnamed_addr");
    var entry = try decode_fn.block("entry");
    _ = try entry.icmp("source.len.ok", "eq", .i64, sib.local(.i64, "%source_len"), sib.int(.i64, "4"));
    try entry.condBr(sib.local(.i1, "%source.len.ok"), "check_output", "decode_fail");
    try writer.writeAll("\n");
    var check_output = try decode_fn.block("check_output");
    try check_output.br("decode_loop");
    try writer.writeAll("\n");
    var loop = try decode_fn.block("decode_loop");
    _ = try loop.phi2("source.index", .i64, sib.int(.i64, "0"), "check_output", sib.local(.i64, "%source.next"), "decode_latch");
    _ = try loop.phi2("output.index", .i64, sib.int(.i64, "0"), "check_output", sib.local(.i64, "%output.next"), "decode_latch");
    _ = try loop.gep("src0", .i8, sib.local(.ptr, "%source"), .i64, sib.local(.i64, "%source.index"));
    _ = try loop.load("b0", .i8, sib.local(.ptr, "%src0"), "1");
    try writeBase64FullTableLoadStructured(&loop, "v0", "%b0");
    _ = try loop.binary("src1.index", "add nuw", .i64, sib.local(.i64, "%source.index"), sib.int(.i64, "1"));
    _ = try loop.gep("src1", .i8, sib.local(.ptr, "%source"), .i64, sib.local(.i64, "%src1.index"));
    _ = try loop.load("b1", .i8, sib.local(.ptr, "%src1"), "1");
    try writeBase64FullTableLoadStructured(&loop, "v1", "%b1");
    _ = try loop.binary("src2.index", "add nuw", .i64, sib.local(.i64, "%source.index"), sib.int(.i64, "2"));
    _ = try loop.gep("src2", .i8, sib.local(.ptr, "%source"), .i64, sib.local(.i64, "%src2.index"));
    _ = try loop.load("b2", .i8, sib.local(.ptr, "%src2"), "1");
    try writeBase64FullTableLoadStructured(&loop, "v2", "%b2");
    _ = try loop.binary("src3.index", "add nuw", .i64, sib.local(.i64, "%source.index"), sib.int(.i64, "3"));
    _ = try loop.gep("src3", .i8, sib.local(.ptr, "%source"), .i64, sib.local(.i64, "%src3.index"));
    _ = try loop.load("b3", .i8, sib.local(.ptr, "%src3"), "1");
    try writeBase64FullTableLoadStructured(&loop, "v3", "%b3");
    _ = try loop.icmp("b2.pad", "eq", .i8, sib.local(.i8, "%b2"), sib.int(.i8, "61"));
    _ = try loop.icmp("b3.pad", "eq", .i8, sib.local(.i8, "%b3"), sib.int(.i8, "61"));
    _ = try loop.icmp("v0.valid", "ne", .i8, sib.local(.i8, "%v0.word"), sib.int(.i8, "-1"));
    _ = try loop.icmp("v1.valid", "ne", .i8, sib.local(.i8, "%v1.word"), sib.int(.i8, "-1"));
    _ = try loop.icmp("v2.valid.raw", "ne", .i8, sib.local(.i8, "%v2.word"), sib.int(.i8, "-1"));
    _ = try loop.select("v2.valid", sib.local(.i1, "%b2.pad"), .i1, sib.int(.i1, "1"), sib.local(.i1, "%v2.valid.raw"));
    _ = try loop.icmp("v3.valid.raw", "ne", .i8, sib.local(.i8, "%v3.word"), sib.int(.i8, "-1"));
    _ = try loop.select("v3.valid", sib.local(.i1, "%b3.pad"), .i1, sib.int(.i1, "1"), sib.local(.i1, "%v3.valid.raw"));
    _ = try loop.select("pad.valid", sib.local(.i1, "%b2.pad"), .i1, sib.local(.i1, "%b3.pad"), sib.int(.i1, "1"));
    _ = try loop.binary("valid01", "and", .i1, sib.local(.i1, "%v0.valid"), sib.local(.i1, "%v1.valid"));
    _ = try loop.binary("valid012", "and", .i1, sib.local(.i1, "%valid01"), sib.local(.i1, "%v2.valid"));
    _ = try loop.binary("valid0123", "and", .i1, sib.local(.i1, "%valid012"), sib.local(.i1, "%v3.valid"));
    _ = try loop.binary("valid", "and", .i1, sib.local(.i1, "%valid0123"), sib.local(.i1, "%pad.valid"));
    _ = try loop.select("output.required.23", sib.local(.i1, "%b3.pad"), .i64, sib.int(.i64, "2"), sib.int(.i64, "3"));
    _ = try loop.select("output.required", sib.local(.i1, "%b2.pad"), .i64, sib.int(.i64, "1"), sib.local(.i64, "%output.required.23"));
    _ = try loop.icmp("output.len.ok", "uge", .i64, sib.local(.i64, "%output_len"), sib.local(.i64, "%output.required"));
    _ = try loop.binary("valid.output", "and", .i1, sib.local(.i1, "%valid"), sib.local(.i1, "%output.len.ok"));
    try loop.condBr(sib.local(.i1, "%valid.output"), "decode_values", "decode_fail");
    try writer.writeAll("\n");
    var values = try decode_fn.block("decode_values");
    _ = try values.binary("v0.masked", "and", .i8, sib.local(.i8, "%v0.word"), sib.int(.i8, "63"));
    _ = try values.binary("v1.masked", "and", .i8, sib.local(.i8, "%v1.word"), sib.int(.i8, "63"));
    _ = try values.binary("v2.masked", "and", .i8, sib.local(.i8, "%v2.word"), sib.int(.i8, "63"));
    _ = try values.binary("v3.masked", "and", .i8, sib.local(.i8, "%v3.word"), sib.int(.i8, "63"));
    _ = try values.select("v2.value", sib.local(.i1, "%b2.pad"), .i8, sib.int(.i8, "0"), sib.local(.i8, "%v2.masked"));
    _ = try values.select("v3.value", sib.local(.i1, "%b3.pad"), .i8, sib.int(.i8, "0"), sib.local(.i8, "%v3.masked"));
    _ = try values.cast("v0.i32", "zext", sib.local(.i8, "%v0.masked"), .i32);
    _ = try values.cast("v1.i32", "zext", sib.local(.i8, "%v1.masked"), .i32);
    _ = try values.cast("v2.i32", "zext", sib.local(.i8, "%v2.value"), .i32);
    _ = try values.cast("v3.i32", "zext", sib.local(.i8, "%v3.value"), .i32);
    _ = try values.binary("shift0", "shl", .i32, sib.local(.i32, "%v0.i32"), sib.int(.i32, "18"));
    _ = try values.binary("shift1", "shl", .i32, sib.local(.i32, "%v1.i32"), sib.int(.i32, "12"));
    _ = try values.binary("word1", "or", .i32, sib.local(.i32, "%shift0"), sib.local(.i32, "%shift1"));
    _ = try values.binary("shift2", "shl", .i32, sib.local(.i32, "%v2.i32"), sib.int(.i32, "6"));
    _ = try values.binary("word2", "or", .i32, sib.local(.i32, "%word1"), sib.local(.i32, "%shift2"));
    _ = try values.binary("word", "or", .i32, sib.local(.i32, "%word2"), sib.local(.i32, "%v3.i32"));
    _ = try values.binary("byte0.shift", "lshr", .i32, sib.local(.i32, "%word"), sib.int(.i32, "16"));
    _ = try values.cast("byte0", "trunc", sib.local(.i32, "%byte0.shift"), .i8);
    try writeBase64OutputStoreStructured(&values, "dst0", "%output", "%output.index", .i8, "%byte0");
    _ = try values.binary("output.next", "add", .i64, sib.local(.i64, "%output.index"), sib.local(.i64, "%output.required"));
    try values.condBr(sib.local(.i1, "%b2.pad"), "decode_done", "store_byte1");
    try writer.writeAll("\n");
    var store1 = try decode_fn.block("store_byte1");
    _ = try store1.binary("dst1.index", "add nuw", .i64, sib.local(.i64, "%output.index"), sib.int(.i64, "1"));
    _ = try store1.binary("byte1.shift", "lshr", .i32, sib.local(.i32, "%word"), sib.int(.i32, "8"));
    _ = try store1.cast("byte1", "trunc", sib.local(.i32, "%byte1.shift"), .i8);
    try writeBase64OutputStoreStructured(&store1, "dst1", "%output", "%dst1.index", .i8, "%byte1");
    try store1.condBr(sib.local(.i1, "%b3.pad"), "decode_done", "store_byte2");
    try writer.writeAll("\n");
    var store2 = try decode_fn.block("store_byte2");
    _ = try store2.binary("dst2.index", "add nuw", .i64, sib.local(.i64, "%output.index"), sib.int(.i64, "2"));
    _ = try store2.cast("byte2", "trunc", sib.local(.i32, "%word"), .i8);
    try writeBase64OutputStoreStructured(&store2, "dst2", "%output", "%dst2.index", .i8, "%byte2");
    _ = try store2.binary("source.next", "add nuw", .i64, sib.local(.i64, "%source.index"), sib.int(.i64, "4"));
    _ = try store2.icmp("done", "eq", .i64, sib.local(.i64, "%source.next"), sib.local(.i64, "%source_len"));
    try store2.condBr(sib.local(.i1, "%done"), "decode_done", "decode_latch");
    try writer.writeAll("\n");
    var latch = try decode_fn.block("decode_latch");
    try latch.br("decode_loop");
    try writer.writeAll("\n");
    var done = try decode_fn.block("decode_done");
    try done.ret(sib.local(.i64, "%output.next"));
    try writer.writeAll("\n");
    var fail = try decode_fn.block("decode_fail");
    try fail.ret(sib.int(.i64, "-1"));
    try decode_fn.end();
}

fn writeBase64FullMainCheckStructured(
    entry: *sib.Block,
    name: []const u8,
    input_global: []const u8,
    output_len: u8,
    expected_len: i8,
    expected_bytes: []const u8,
) !void {
    const decoded = try std.fmt.allocPrint(std.heap.page_allocator, "decoded.{s}", .{name});
    const len_ok = try std.fmt.allocPrint(std.heap.page_allocator, "{s}.len.ok", .{name});
    const input_ref = try std.fmt.allocPrint(std.heap.page_allocator, "@{s}", .{input_global});
    const args = try std.fmt.allocPrint(std.heap.page_allocator, "ptr {s}, i64 4, ptr @base64.full_output, i64 {d}", .{ input_ref, output_len });
    _ = try entry.call(decoded, "", .i64, "@base64.decode_base_64", args);
    const decoded_ref = try std.fmt.allocPrint(std.heap.page_allocator, "%{s}", .{decoded});
    _ = try entry.icmp(len_ok, "eq", .i64, sib.local(.i64, decoded_ref), sib.int(.i64, try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{expected_len})));
    var previous = len_ok;
    for (expected_bytes, 0..) |byte, index| {
        const ptr_name = try std.fmt.allocPrint(std.heap.page_allocator, "{s}.out{d}.ptr", .{ name, index });
        const load_name = try std.fmt.allocPrint(std.heap.page_allocator, "{s}.out{d}", .{ name, index });
        const ok_name = try std.fmt.allocPrint(std.heap.page_allocator, "{s}.out{d}.ok", .{ name, index });
        _ = try entry.gep(ptr_name, .i8, sib.global(.ptr, "@base64.full_output"), .i64, sib.int(.i64, try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{index})));
        const ptr_ref = try std.fmt.allocPrint(std.heap.page_allocator, "%{s}", .{ptr_name});
        _ = try entry.load(load_name, .i8, sib.local(.ptr, ptr_ref), "1");
        const load_ref = try std.fmt.allocPrint(std.heap.page_allocator, "%{s}", .{load_name});
        _ = try entry.icmp(ok_name, "eq", .i8, sib.local(.i8, load_ref), sib.int(.i8, try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{byte})));
        const next = try std.fmt.allocPrint(std.heap.page_allocator, "{s}.ok{d}", .{ name, index });
        const previous_ref = try std.fmt.allocPrint(std.heap.page_allocator, "%{s}", .{previous});
        const ok_ref = try std.fmt.allocPrint(std.heap.page_allocator, "%{s}", .{ok_name});
        _ = try entry.binary(next, "and", .i1, sib.local(.i1, previous_ref), sib.local(.i1, ok_ref));
        previous = next;
    }
    const final_name = try std.fmt.allocPrint(std.heap.page_allocator, "{s}.ok", .{name});
    const previous_ref = try std.fmt.allocPrint(std.heap.page_allocator, "%{s}", .{previous});
    _ = try entry.binary(final_name, "and", .i1, sib.local(.i1, previous_ref), sib.int(.i1, "1"));
}

fn writeBase64FullTableLoadStructured(entry: *sib.Block, prefix: []const u8, byte_ref: []const u8) !void {
    const idx = try std.fmt.allocPrint(std.heap.page_allocator, "{s}.idx", .{prefix});
    const entry_name = try std.fmt.allocPrint(std.heap.page_allocator, "{s}.entry", .{prefix});
    const word = try std.fmt.allocPrint(std.heap.page_allocator, "{s}.word", .{prefix});
    _ = try entry.cast(idx, "zext", sib.local(.i8, byte_ref), .i64);
    const idx_ref = try std.fmt.allocPrint(std.heap.page_allocator, "%{s}", .{idx});
    _ = try entry.gep2(entry_name, .{ .text = "[256 x i8]" }, sib.global(.ptr, "@base64.full_table"), sib.int(.i64, "0"), sib.local(.i64, idx_ref));
    const entry_ref = try std.fmt.allocPrint(std.heap.page_allocator, "%{s}", .{entry_name});
    _ = try entry.load(word, .i8, sib.local(.ptr, entry_ref), "1");
}

fn writeBase64OutputStoreStructured(entry: *sib.Block, ptr_name: []const u8, output_base: []const u8, offset: []const u8, ty: sib.Type, value: []const u8) !void {
    _ = try entry.gep(ptr_name, .i8, sib.local(.ptr, output_base), .i64, sib.local(.i64, offset));
    const ptr_ref = try std.fmt.allocPrint(std.heap.page_allocator, "%{s}", .{ptr_name});
    try entry.store(sib.local(ty, value), sib.local(.ptr, ptr_ref), "1");
}

fn writeReleaseSmallRuntimeBase64DecodeBase64FullIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeBase64FullStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 full decoder external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeReleaseSmallRuntimeBase64DecodeBase64FullTextualIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writer.print(
        \\@base64.full_input_man = constant [4 x i8] c"TWFu", align 1
        \\@base64.full_input_ma = constant [4 x i8] c"TWE=", align 1
        \\@base64.full_input_m = constant [4 x i8] c"TQ==", align 1
        \\@base64.full_input_invalid = constant [4 x i8] c"!!!!", align 1
        \\@base64.full_output = global i32 0, align 4
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 full decoder external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
    writeBase64FullTableConstant(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 full decoder external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
    writer.print(
        \\
        \\define dso_local i32 @main() local_unnamed_addr {{
        \\entry:
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 full decoder external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
    writeBase64FullMainCheck(writer, "man", "base64.full_input_man", 3, 3, "Man") catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 full decoder external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
    writeBase64FullMainCheck(writer, "ma", "base64.full_input_ma", 2, 2, "Ma") catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 full decoder external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
    writeBase64FullMainCheck(writer, "m", "base64.full_input_m", 1, 1, "M") catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 full decoder external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
    writeBase64FullMainCheck(writer, "invalid", "base64.full_input_invalid", 3, -1, "") catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 full decoder external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
    writer.print(
        \\  %ok.man.ma = and i1 %man.ok, %ma.ok
        \\  %ok.man.ma.m = and i1 %ok.man.ma, %m.ok
        \\  %ok = and i1 %ok.man.ma.m, %invalid.ok
        \\  %result = select i1 %ok, i32 0, i32 1
        \\  ret i32 %result
        \\}}
        \\
        \\define available_externally i64 @base64.decode_base_64(ptr %source, i64 %source_len, ptr %output, i64 %output_len) unnamed_addr {{
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 full decoder external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
    irw.block(writer, "entry") catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 full decoder external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
    writer.print(
        \\  %source.len.ok = icmp eq i64 %source_len, 4
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 full decoder external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
    irw.condBr(writer, "source.len.ok", "check_output", "decode_fail") catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 full decoder external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
    irw.block(writer, "check_output") catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 full decoder external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
    irw.br(writer, "decode_loop") catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 full decoder external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
    irw.block(writer, "decode_loop") catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 full decoder external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
    try irw.phi2(writer, "source.index", "i64", "0", "check_output", "%source.next", "decode_latch");
    try irw.phi2(writer, "output.index", "i64", "0", "check_output", "%output.next", "decode_latch");
    irw.gep(writer, "src0", "i8", "%source", "%source.index") catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 full decoder external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
    irw.load(writer, "b0", "i8", "%src0", "1") catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 full decoder external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
    try irw.indexedTableLoadI8(writer, "v0", "base64.full_table", "b0");
    try irw.pointerIndexAdvance(writer, "src1.index", "%source.index", "1");
    try irw.gep(writer, "src1", "i8", "%source", "%src1.index");
    try irw.load(writer, "b1", "i8", "%src1", "1");
    try irw.indexedTableLoadI8(writer, "v1", "base64.full_table", "b1");
    try irw.pointerIndexAdvance(writer, "src2.index", "%source.index", "2");
    try irw.gep(writer, "src2", "i8", "%source", "%src2.index");
    try irw.load(writer, "b2", "i8", "%src2", "1");
    try irw.indexedTableLoadI8(writer, "v2", "base64.full_table", "b2");
    try irw.pointerIndexAdvance(writer, "src3.index", "%source.index", "3");
    try irw.gep(writer, "src3", "i8", "%source", "%src3.index");
    try irw.load(writer, "b3", "i8", "%src3", "1");
    try irw.indexedTableLoadI8(writer, "v3", "base64.full_table", "b3");
    writer.print(
        \\  %b2.pad = icmp eq i8 %b2, 61
        \\  %b3.pad = icmp eq i8 %b3, 61
        \\  %v0.valid = icmp ne i8 %v0.word, -1
        \\  %v1.valid = icmp ne i8 %v1.word, -1
        \\  %v2.valid.raw = icmp ne i8 %v2.word, -1
        \\  %v2.valid = select i1 %b2.pad, i1 true, i1 %v2.valid.raw
        \\  %v3.valid.raw = icmp ne i8 %v3.word, -1
        \\  %v3.valid = select i1 %b3.pad, i1 true, i1 %v3.valid.raw
        \\  %pad.valid = select i1 %b2.pad, i1 %b3.pad, i1 true
        \\  %valid01 = and i1 %v0.valid, %v1.valid
        \\  %valid012 = and i1 %valid01, %v2.valid
        \\  %valid0123 = and i1 %valid012, %v3.valid
        \\  %valid = and i1 %valid0123, %pad.valid
        \\  %output.required.23 = select i1 %b3.pad, i64 2, i64 3
        \\  %output.required = select i1 %b2.pad, i64 1, i64 %output.required.23
        \\  %output.len.ok = icmp uge i64 %output_len, %output.required
        \\  %valid.output = and i1 %valid, %output.len.ok
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 full decoder external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
    irw.condBr(writer, "valid.output", "decode_values", "decode_fail") catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 full decoder external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
    irw.block(writer, "decode_values") catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 full decoder external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
    try irw.byteMask(writer, "v0.masked", "%v0.word", "63");
    try irw.byteMask(writer, "v1.masked", "%v1.word", "63");
    try irw.byteMask(writer, "v2.masked", "%v2.word", "63");
    try irw.byteMask(writer, "v3.masked", "%v3.word", "63");
    writer.print(
        \\  %v2.value = select i1 %b2.pad, i8 0, i8 %v2.masked
        \\  %v3.value = select i1 %b3.pad, i8 0, i8 %v3.masked
        \\  %v0.i32 = zext i8 %v0.masked to i32
        \\  %v1.i32 = zext i8 %v1.masked to i32
        \\  %v2.i32 = zext i8 %v2.value to i32
        \\  %v3.i32 = zext i8 %v3.value to i32
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 full decoder external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
    try irw.shift(writer, "shift0", "shl", "i32", "%v0.i32", "18");
    try irw.shift(writer, "shift1", "shl", "i32", "%v1.i32", "12");
    writer.print(
        \\  %word1 = or i32 %shift0, %shift1
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 full decoder external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
    try irw.shift(writer, "shift2", "shl", "i32", "%v2.i32", "6");
    writer.print(
        \\  %word2 = or i32 %word1, %shift2
        \\  %word = or i32 %word2, %v3.i32
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 full decoder external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
    try irw.shift(writer, "byte0.shift", "lshr", "i32", "%word", "16");
    try irw.trunc(writer, "byte0", "i32", "%byte0.shift", "i8");
    try writeBase64OutputStore(writer, "dst0", "%output", "%output.index", "i8", "%byte0");
    writer.print(
        \\  %output.next = add i64 %output.index, %output.required
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 full decoder external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
    irw.condBr(writer, "b2.pad", "decode_done", "store_byte1") catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 full decoder external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
    irw.block(writer, "store_byte1") catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 full decoder external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
    try irw.pointerIndexAdvance(writer, "dst1.index", "%output.index", "1");
    try irw.shift(writer, "byte1.shift", "lshr", "i32", "%word", "8");
    try irw.trunc(writer, "byte1", "i32", "%byte1.shift", "i8");
    try writeBase64OutputStore(writer, "dst1", "%output", "%dst1.index", "i8", "%byte1");
    irw.condBr(writer, "b3.pad", "decode_done", "store_byte2") catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 full decoder external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
    irw.block(writer, "store_byte2") catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 full decoder external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
    try irw.pointerIndexAdvance(writer, "dst2.index", "%output.index", "2");
    try irw.trunc(writer, "byte2", "i32", "%word", "i8");
    try writeBase64OutputStore(writer, "dst2", "%output", "%dst2.index", "i8", "%byte2");
    try irw.pointerIndexAdvance(writer, "source.next", "%source.index", "4");
    writer.print(
        \\  %done = icmp eq i64 %source.next, %source_len
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 full decoder external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
    irw.condBr(writer, "done", "decode_done", "decode_latch") catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 full decoder external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
    irw.block(writer, "decode_latch") catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 full decoder external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
    irw.br(writer, "decode_loop") catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 full decoder external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
    irw.block(writer, "decode_done") catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 full decoder external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
    writer.print(
        \\  ret i64 %output.next
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 full decoder external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
    irw.block(writer, "decode_fail") catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 full decoder external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
    writer.print(
        \\  ret i64 -1
        \\}}
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 full decoder external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeReleaseSmallRuntimeBase64DecodeStepIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeBase64DecodeStepStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 decode-step external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeBase64DecodeStepStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.global("base64.decode_step_table", "private unnamed_addr", .{ .text = "[16 x i32]" }, "[i32 0, i32 248, i32 -16777216, i32 252, i32 0, i32 4096, i32 -16777216, i32 61443, i32 0, i32 8192, i32 -16777216, i32 12586752, i32 0, i32 196608, i32 -16777216, i32 4128768]", "4");
    try writer.writeAll("\n");
    var function = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var entry = try function.block("entry");
    _ = try entry.gep2("p0", .{ .text = "[16 x i32]" }, sib.global(.ptr, "@base64.decode_step_table"), sib.int(.i64, "0"), sib.int(.i64, "0"));
    _ = try entry.load("v0", .i32, sib.local(.ptr, "%p0"), "4");
    _ = try entry.gep2("p1", .{ .text = "[16 x i32]" }, sib.global(.ptr, "@base64.decode_step_table"), sib.int(.i64, "0"), sib.int(.i64, "5"));
    _ = try entry.load("v1", .i32, sib.local(.ptr, "%p1"), "4");
    _ = try entry.binary("word1", "or", .i32, sib.local(.i32, "%v1"), sib.local(.i32, "%v0"));
    _ = try entry.gep2("p2", .{ .text = "[16 x i32]" }, sib.global(.ptr, "@base64.decode_step_table"), sib.int(.i64, "0"), sib.int(.i64, "9"));
    _ = try entry.load("v2", .i32, sib.local(.ptr, "%p2"), "4");
    _ = try entry.binary("word2", "or", .i32, sib.local(.i32, "%word1"), sib.local(.i32, "%v2"));
    _ = try entry.gep2("p3", .{ .text = "[16 x i32]" }, sib.global(.ptr, "@base64.decode_step_table"), sib.int(.i64, "0"), sib.int(.i64, "13"));
    _ = try entry.load("v3", .i32, sib.local(.ptr, "%p3"), "4");
    _ = try entry.binary("word", "or", .i32, sib.local(.i32, "%word2"), sib.local(.i32, "%v3"));
    _ = try entry.icmp("valid", "ult", .i32, sib.local(.i32, "%word"), sib.int(.i32, "16777216"));
    _ = try entry.select("ret", sib.local(.i1, "%valid"), .i32, sib.int(.i32, "0"), sib.int(.i32, "1"));
    try entry.ret(sib.local(.i32, "%ret"));
    try function.end();
}

fn writeReleaseSmallRuntimeBase64StoreStepIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeBase64StoreStepStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 store-step external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeBase64StoreStepStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.global("base64.decode_output", "private unnamed_addr", .i32, "0", "4");
    try writer.writeAll("\n");
    var function = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var entry = try function.block("entry");
    _ = try entry.gep("dst", .{ .text = "[1 x i8]" }, sib.global(.ptr, "@base64.decode_output"), .i64, sib.int(.i64, "0"));
    try entry.store(sib.int(.i32, "2105344"), sib.local(.ptr, "%dst"), "1");
    _ = try entry.load("check", .i32, sib.local(.ptr, "%dst"), "1");
    _ = try entry.icmp("ok", "eq", .i32, sib.local(.i32, "%check"), sib.int(.i32, "2105344"));
    _ = try entry.select("ret", sib.local(.i1, "%ok"), .i32, sib.int(.i32, "0"), sib.int(.i32, "1"));
    try entry.ret(sib.local(.i32, "%ret"));
    try function.end();
}

fn writeReleaseSmallRuntimeBase64ResidualByteStepIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeBase64ResidualByteStepStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 residual-byte external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeBase64ResidualByteStepStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.global("base64.residual_output", "private unnamed_addr", .i32, "0", "4");
    try writer.writeAll("\n");
    var function = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var entry = try function.block("entry");
    _ = try entry.gep("dst", .{ .text = "[1 x i8]" }, sib.global(.ptr, "@base64.residual_output"), .i64, sib.int(.i64, "0"));
    try entry.store(sib.int(.i8, "63"), sib.local(.ptr, "%dst"), "1");
    _ = try entry.load("check", .i8, sib.local(.ptr, "%dst"), "1");
    _ = try entry.icmp("ok", "eq", .i8, sib.local(.i8, "%check"), sib.int(.i8, "63"));
    _ = try entry.select("ret", sib.local(.i1, "%ok"), .i32, sib.int(.i32, "0"), sib.int(.i32, "1"));
    try entry.ret(sib.local(.i32, "%ret"));
    try function.end();
}

fn writeReleaseSmallRuntimeBase64PaddingTailStepIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeBase64PaddingTailStepStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 padding-tail external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeBase64PaddingTailStepStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.global("base64.padding_tail", "private unnamed_addr", .i32, "61", "4");
    try writer.writeAll("\n");
    var function = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var entry = try function.block("entry");
    _ = try entry.gep("src", .{ .text = "[1 x i8]" }, sib.global(.ptr, "@base64.padding_tail"), .i64, sib.int(.i64, "0"));
    _ = try entry.load("byte", .i8, sib.local(.ptr, "%src"), "1");
    _ = try entry.icmp("is_pad", "eq", .i8, sib.local(.i8, "%byte"), sib.int(.i8, "61"));
    _ = try entry.select("ret", sib.local(.i1, "%is_pad"), .i32, sib.int(.i32, "0"), sib.int(.i32, "1"));
    try entry.ret(sib.local(.i32, "%ret"));
    try function.end();
}

fn writeReleaseSmallRuntimeBase64PaddingLoopStepIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeBase64PaddingLoopStepStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 padding-loop external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeBase64PaddingLoopStepStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.global("base64.padding_loop", "private unnamed_addr", .i32, "61", "4");
    try writer.writeAll("\n");
    var function = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var entry = try function.block("entry");
    try entry.br("loop");
    try writer.writeAll("\n");
    var loop = try function.block("loop");
    _ = try loop.phi2("index", .i64, sib.int(.i64, "0"), "entry", sib.local(.i64, "%next"), "body");
    _ = try loop.icmp("done", "eq", .i64, sib.local(.i64, "%index"), sib.int(.i64, "2"));
    try loop.condBr(sib.local(.i1, "%done"), "exit", "body");
    try writer.writeAll("\n");
    var body = try function.block("body");
    _ = try body.gep("src", .{ .text = "[1 x i8]" }, sib.global(.ptr, "@base64.padding_loop"), .i64, sib.int(.i64, "0"));
    _ = try body.load("byte", .i8, sib.local(.ptr, "%src"), "1");
    _ = try body.icmp("is_pad", "eq", .i8, sib.local(.i8, "%byte"), sib.int(.i8, "61"));
    _ = try body.binary("next", "add", .i64, sib.local(.i64, "%index"), sib.int(.i64, "1"));
    try body.condBr(sib.local(.i1, "%is_pad"), "loop", "fail");
    try writer.writeAll("\n");
    var fail = try function.block("fail");
    try fail.ret(sib.int(.i32, "1"));
    try writer.writeAll("\n");
    var exit = try function.block("exit");
    try exit.ret(sib.int(.i32, "0"));
    try function.end();
}

fn writeReleaseSmallRuntimeBase64PaddingLengthStepIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeBase64PaddingLengthStepStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 padding-length external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeBase64PaddingLengthStepStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.global("base64.padding_length_tail", "private unnamed_addr", .i32, "15677", "4");
    try writer.writeAll("\n");
    var function = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var entry = try function.block("entry");
    _ = try entry.gep("end", .{ .text = "[1 x i8]" }, sib.global(.ptr, "@base64.padding_length_tail"), .i64, sib.int(.i64, "2"));
    _ = try entry.gep("last_ptr", .i8, sib.local(.ptr, "%end"), .i64, sib.int(.i64, "-1"));
    _ = try entry.load("last", .i8, sib.local(.ptr, "%last_ptr"), "1");
    _ = try entry.icmp("last_eq", "eq", .i8, sib.local(.i8, "%last"), sib.int(.i8, "61"));
    _ = try entry.cast("last_adj", "sext", sib.local(.i1, "%last_eq"), .i64);
    _ = try entry.binary("base", "add", .i64, sib.int(.i64, "6"), sib.local(.i64, "%last_adj"));
    _ = try entry.gep("second_ptr", .i8, sib.local(.ptr, "%end"), .i64, sib.int(.i64, "-2"));
    _ = try entry.load("second", .i8, sib.local(.ptr, "%second_ptr"), "1");
    _ = try entry.icmp("second_eq", "eq", .i8, sib.local(.i8, "%second"), sib.int(.i8, "61"));
    _ = try entry.cast("second_adj", "sext", sib.local(.i1, "%second_eq"), .i64);
    _ = try entry.binary("total", "add", .i64, sib.local(.i64, "%base"), sib.local(.i64, "%second_adj"));
    _ = try entry.icmp("ok", "eq", .i64, sib.local(.i64, "%total"), sib.int(.i64, "8"));
    _ = try entry.select("ret", sib.local(.i1, "%ok"), .i32, sib.int(.i32, "0"), sib.int(.i32, "1"));
    try entry.ret(sib.local(.i32, "%ret"));
    try function.end();
}

fn writeReleaseSmallRuntimeBase64ChunkGuardStepIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeBase64ChunkGuardStepStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 chunk-guard external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeBase64ChunkGuardStepStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    var function = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var entry = try function.block("entry");
    _ = try entry.binary("source_next", "add nuw", .i64, sib.int(.i64, "0"), sib.int(.i64, "16"));
    _ = try entry.icmp("source_ok", "ult", .i64, sib.local(.i64, "%source_next"), sib.int(.i64, "64"));
    _ = try entry.binary("output_next", "add nuw", .i64, sib.int(.i64, "0"), sib.int(.i64, "15"));
    _ = try entry.icmp("output_ok", "ult", .i64, sib.local(.i64, "%output_next"), sib.int(.i64, "63"));
    _ = try entry.select("wide_ok", sib.local(.i1, "%source_ok"), .i1, sib.local(.i1, "%output_ok"), sib.int(.i1, "0"));
    _ = try entry.select("ret", sib.local(.i1, "%wide_ok"), .i32, sib.int(.i32, "0"), sib.int(.i32, "1"));
    try entry.ret(sib.local(.i32, "%ret"));
    try function.end();
}

fn writeReleaseSmallRuntimeBase64SourceStrideStepIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeBase64SourceStrideStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 source-stride external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeBase64SourceStrideStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.global("base64.source_stride_input", "private unnamed_addr", .i32, "0", "4");
    try module.global("base64.source_stride_table", "private unnamed_addr", .{ .text = "[8 x i32]" }, "[i32 42, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0]", "4");
    try writer.writeAll("\n");
    var function = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var entry = try function.block("entry");
    _ = try entry.gep("src", .i8, sib.global(.ptr, "@base64.source_stride_input"), .i64, sib.int(.i64, "4"));
    _ = try entry.load("byte", .i8, sib.local(.ptr, "%src"), "1");
    _ = try entry.cast("idx", "zext", sib.local(.i8, "%byte"), .i64);
    _ = try entry.gep("entry_ptr", .{ .text = "[4 x i8]" }, sib.global(.ptr, "@base64.source_stride_table"), .i64, sib.local(.i64, "%idx"));
    _ = try entry.load("word", .i32, sib.local(.ptr, "%entry_ptr"), "4");
    _ = try entry.icmp("ok", "eq", .i32, sib.local(.i32, "%word"), sib.int(.i32, "42"));
    _ = try entry.select("ret", sib.local(.i1, "%ok"), .i32, sib.int(.i32, "0"), sib.int(.i32, "1"));
    try entry.ret(sib.local(.i32, "%ret"));
    try function.end();
}

fn writeReleaseSmallRuntimeBase64SourceBundleStepIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeBase64SourceBundleStructuredModule(writer, "source_bundle", "base64.source_bundle_input", "4") catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 source-bundle external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeReleaseSmallRuntimeBase64NextSourceBundleStepIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeBase64SourceBundleStructuredModule(writer, "next_source_bundle", "base64.next_source_bundle_input", "8") catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 next-source-bundle external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeReleaseSmallRuntimeBase64ThirdSourceBundleStepIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeBase64SourceBundleStructuredModule(writer, "third_source_bundle", "base64.third_source_bundle_input", "12") catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 third-source-bundle external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeBase64SourceBundleStructuredModule(writer: *std.Io.Writer, prefix: []const u8, input_symbol: []const u8, first_offset: []const u8) !void {
    var module = sib.Module.init(writer);
    try module.global(input_symbol, "private unnamed_addr", .i32, "0", "4");
    const suffixes = [_][]const u8{ "0", "1", "2", "3" };
    const values = [_][]const u8{ "0", "4096", "8192", "196608" };
    for (suffixes, values) |suffix, value| {
        const table_name = try std.fmt.allocPrint(std.heap.page_allocator, "base64.{s}_table{s}", .{ prefix, suffix });
        const initializer = try std.fmt.allocPrint(std.heap.page_allocator, "[i32 {s}]", .{value});
        try module.global(table_name, "private unnamed_addr", .{ .text = "[1 x i32]" }, initializer, "4");
    }
    try writer.writeAll("\n");
    var function = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var entry = try function.block("entry");
    try writeBase64FourByteBundleStructured(&entry, input_symbol, first_offset, prefix);
    _ = try entry.select("ret", sib.local(.i1, "%valid"), .i32, sib.int(.i32, "0"), sib.int(.i32, "1"));
    try entry.ret(sib.local(.i32, "%ret"));
    try function.end();
}

fn writeBase64FourByteBundleStructured(entry: *sib.Block, input_symbol: []const u8, first_offset: []const u8, prefix: []const u8) !void {
    const input_ref = try std.fmt.allocPrint(std.heap.page_allocator, "@{s}", .{input_symbol});
    _ = try entry.gep("src0", .i8, sib.global(.ptr, input_ref), .i64, sib.int(.i64, first_offset));
    _ = try entry.load("byte0", .i8, sib.local(.ptr, "%src0"), "1");
    try writeBase64BundleTableLoad(entry, "word0", prefix, "0", "%byte0");
    _ = try entry.gep("src1", .i8, sib.local(.ptr, "%src0"), .i64, sib.int(.i64, "1"));
    _ = try entry.load("byte1", .i8, sib.local(.ptr, "%src1"), "1");
    try writeBase64BundleTableLoad(entry, "word1", prefix, "1", "%byte1");
    _ = try entry.binary("merged1", "or", .i32, sib.local(.i32, "%word1.word"), sib.local(.i32, "%word0.word"));
    _ = try entry.gep("src2", .i8, sib.local(.ptr, "%src0"), .i64, sib.int(.i64, "2"));
    _ = try entry.load("byte2", .i8, sib.local(.ptr, "%src2"), "1");
    try writeBase64BundleTableLoad(entry, "word2", prefix, "2", "%byte2");
    _ = try entry.binary("merged2", "or", .i32, sib.local(.i32, "%merged1"), sib.local(.i32, "%word2.word"));
    _ = try entry.gep("src3", .i8, sib.local(.ptr, "%src0"), .i64, sib.int(.i64, "3"));
    _ = try entry.load("byte3", .i8, sib.local(.ptr, "%src3"), "1");
    try writeBase64BundleTableLoad(entry, "word3", prefix, "3", "%byte3");
    _ = try entry.binary("word", "or", .i32, sib.local(.i32, "%merged2"), sib.local(.i32, "%word3.word"));
    _ = try entry.icmp("valid", "ult", .i32, sib.local(.i32, "%word"), sib.int(.i32, "16777216"));
}

fn writeBase64BundleTableLoad(entry: *sib.Block, result_prefix: []const u8, prefix: []const u8, table_suffix: []const u8, byte_ref: []const u8) !void {
    const idx = try std.fmt.allocPrint(std.heap.page_allocator, "{s}.idx", .{result_prefix});
    const entry_name = try std.fmt.allocPrint(std.heap.page_allocator, "{s}.entry", .{result_prefix});
    const word = try std.fmt.allocPrint(std.heap.page_allocator, "{s}.word", .{result_prefix});
    const table_ref = try std.fmt.allocPrint(std.heap.page_allocator, "@base64.{s}_table{s}", .{ prefix, table_suffix });
    _ = try entry.cast(idx, "zext", sib.local(.i8, byte_ref), .i64);
    const idx_ref = try std.fmt.allocPrint(std.heap.page_allocator, "%{s}", .{idx});
    _ = try entry.gep(entry_name, .{ .text = "[4 x i8]" }, sib.global(.ptr, table_ref), .i64, sib.local(.i64, idx_ref));
    const entry_ref = try std.fmt.allocPrint(std.heap.page_allocator, "%{s}", .{entry_name});
    _ = try entry.load(word, .i32, sib.local(.ptr, entry_ref), "4");
}

fn writeReleaseSmallRuntimeBase64BitBufferStoreStepIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeBase64BitBufferStoreStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 bit-buffer-store external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeBase64BitBufferStoreStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.global("base64.bit_buffer_word0", "private unnamed_addr", .i32, "1", "4");
    try module.global("base64.bit_buffer_word1", "private unnamed_addr", .i32, "2", "4");
    try module.global("base64.bit_buffer_word2", "private unnamed_addr", .i32, "3", "4");
    try module.global("base64.bit_buffer_word3", "private unnamed_addr", .i32, "4", "4");
    try module.global("base64.bit_buffer_output", "private unnamed_addr", .i32, "0", "4");
    try writer.writeAll("\n");
    var function = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var entry = try function.block("entry");
    _ = try entry.load("word0.raw", .i32, sib.global(.ptr, "@base64.bit_buffer_word0"), "4");
    _ = try entry.cast("word0", "zext", sib.local(.i32, "%word0.raw"), .i128);
    _ = try entry.load("word3.raw", .i32, sib.global(.ptr, "@base64.bit_buffer_word3"), "4");
    _ = try entry.castFlags("word3", "zext nneg", sib.local(.i32, "%word3.raw"), .i128);
    _ = try entry.load("word1.raw", .i32, sib.global(.ptr, "@base64.bit_buffer_word1"), "4");
    _ = try entry.castFlags("word1", "zext nneg", sib.local(.i32, "%word1.raw"), .i128);
    _ = try entry.binary("shift1", "shl nsw nuw", .i128, sib.local(.i128, "%word1"), sib.int(.i128, "24"));
    _ = try entry.binary("merged1", "or disjoint", .i128, sib.local(.i128, "%shift1"), sib.local(.i128, "%word0"));
    _ = try entry.load("word2.raw", .i32, sib.global(.ptr, "@base64.bit_buffer_word2"), "4");
    _ = try entry.castFlags("word2", "zext nneg", sib.local(.i32, "%word2.raw"), .i128);
    _ = try entry.binary("shift2", "shl nsw nuw", .i128, sib.local(.i128, "%word2"), sib.int(.i128, "48"));
    _ = try entry.binary("merged2", "or disjoint", .i128, sib.local(.i128, "%merged1"), sib.local(.i128, "%shift2"));
    _ = try entry.binary("shift3", "shl nsw nuw", .i128, sib.local(.i128, "%word3"), sib.int(.i128, "72"));
    _ = try entry.binary("merged", "or disjoint", .i128, sib.local(.i128, "%merged2"), sib.local(.i128, "%shift3"));
    _ = try entry.gep("dst", .{ .text = "[1 x i8]" }, sib.global(.ptr, "@base64.bit_buffer_output"), .i64, sib.int(.i64, "0"));
    try entry.store(sib.local(.i128, "%merged"), sib.local(.ptr, "%dst"), "1");
    try entry.ret(sib.int(.i32, "0"));
    try function.end();
}

fn writeReleaseSmallRuntimeBase64LoopAdvanceStepIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeBase64LoopAdvanceStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 loop-advance external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeBase64LoopAdvanceStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.global("base64.loop_advance_output", "private unnamed_addr", .i64, "0", "8");
    try module.global("base64.loop_advance_source", "private unnamed_addr", .i64, "16", "8");
    try writer.writeAll("\n");
    var function = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var entry = try function.block("entry");
    _ = try entry.load("out.start", .i64, sib.global(.ptr, "@base64.loop_advance_output"), "8");
    _ = try entry.load("src.start", .i64, sib.global(.ptr, "@base64.loop_advance_source"), "8");
    try entry.br("loop");
    try writer.writeAll("\n");
    var loop = try function.block("loop");
    _ = try loop.phi2("out", .i64, sib.local(.i64, "%out.start"), "entry", sib.local(.i64, "%out.next"), "loop");
    _ = try loop.phi2("src", .i64, sib.local(.i64, "%src.start"), "entry", sib.local(.i64, "%src.next"), "loop");
    _ = try loop.binary("out.next", "add nuw", .i64, sib.local(.i64, "%out"), sib.int(.i64, "12"));
    _ = try loop.binary("src.next", "add", .i64, sib.local(.i64, "%src"), sib.int(.i64, "-16"));
    _ = try loop.icmp("done", "eq", .i64, sib.local(.i64, "%out.next"), sib.int(.i64, "12"));
    try loop.condBr(sib.local(.i1, "%done"), "exit", "loop");
    try writer.writeAll("\n");
    var exit = try function.block("exit");
    _ = try exit.icmp("src.ok", "eq", .i64, sib.local(.i64, "%src.next"), sib.int(.i64, "0"));
    _ = try exit.select("ret", sib.local(.i1, "%src.ok"), .i32, sib.int(.i32, "0"), sib.int(.i32, "1"));
    try exit.ret(sib.local(.i32, "%ret"));
    try function.end();
}

fn writeReleaseSmallRuntimeBase64ResidualGuardStepIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeBase64ResidualGuardStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 residual-guard external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeBase64ResidualGuardStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.global("base64.residual_guard_source_index", "private unnamed_addr", .i64, "0", "8");
    try module.global("base64.residual_guard_output_index", "private unnamed_addr", .i64, "0", "8");
    try module.global("base64.residual_guard_source_len", "private unnamed_addr", .i64, "8", "8");
    try module.global("base64.residual_guard_output_len", "private unnamed_addr", .i64, "8", "8");
    try module.global("base64.residual_guard_source", "private unnamed_addr", .{ .text = "[1 x i8]" }, "c\"A\"", "1");
    try writer.writeAll("\n");
    var function = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var entry = try function.block("entry");
    _ = try entry.load("source.index", .i64, sib.global(.ptr, "@base64.residual_guard_source_index"), "8");
    _ = try entry.load("output.index", .i64, sib.global(.ptr, "@base64.residual_guard_output_index"), "8");
    _ = try entry.load("source.len", .i64, sib.global(.ptr, "@base64.residual_guard_source_len"), "8");
    _ = try entry.load("output.len", .i64, sib.global(.ptr, "@base64.residual_guard_output_len"), "8");
    _ = try entry.binary("source.next", "add nuw", .i64, sib.local(.i64, "%source.index"), sib.int(.i64, "4"));
    _ = try entry.icmp("source.ok", "ult", .i64, sib.local(.i64, "%source.next"), sib.local(.i64, "%source.len"));
    _ = try entry.binary("output.next", "add nuw", .i64, sib.local(.i64, "%output.index"), sib.int(.i64, "3"));
    _ = try entry.icmp("output.ok", "ult", .i64, sib.local(.i64, "%output.next"), sib.local(.i64, "%output.len"));
    _ = try entry.select("guard", sib.local(.i1, "%source.ok"), .i1, sib.local(.i1, "%output.ok"), sib.int(.i1, "0"));
    _ = try entry.gep("src.ptr", .{ .text = "[1 x i8]" }, sib.global(.ptr, "@base64.residual_guard_source"), .i64, sib.local(.i64, "%source.index"));
    try entry.condBr(sib.local(.i1, "%guard"), "decode", "done");
    try writer.writeAll("\n");
    var decode = try function.block("decode");
    _ = try decode.load("byte", .i8, sib.local(.ptr, "%src.ptr"), "1");
    _ = try decode.icmp("byte.ok", "eq", .i8, sib.local(.i8, "%byte"), sib.int(.i8, "65"));
    _ = try decode.select("ret.ok", sib.local(.i1, "%byte.ok"), .i32, sib.int(.i32, "0"), sib.int(.i32, "2"));
    try decode.ret(sib.local(.i32, "%ret.ok"));
    try writer.writeAll("\n");
    var done = try function.block("done");
    try done.ret(sib.int(.i32, "1"));
    try function.end();
}

fn writeReleaseSmallRuntimeBase64ResidualBundleStepIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeBase64SourceBundleStructuredModule(writer, "residual_bundle", "base64.residual_bundle_input", "0") catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 residual-bundle external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeReleaseSmallRuntimeBase64ResidualStoreStepIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeBase64ResidualStoreStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 residual-store external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeBase64ResidualStoreStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.global("base64.residual_store_output", "private unnamed_addr", .i32, "0", "4");
    try module.global("base64.residual_store_word", "private unnamed_addr", .i32, "2105344", "4");
    try module.global("base64.residual_store_remaining", "private unnamed_addr", .i64, "4", "8");
    try writer.writeAll("\n");
    var function = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var entry = try function.block("entry");
    _ = try entry.load("word", .i32, sib.global(.ptr, "@base64.residual_store_word"), "4");
    _ = try entry.gep("dst", .{ .text = "[1 x i8]" }, sib.global(.ptr, "@base64.residual_store_output"), .i64, sib.int(.i64, "0"));
    try entry.store(sib.local(.i32, "%word"), sib.local(.ptr, "%dst"), "1");
    _ = try entry.load("check", .i32, sib.local(.ptr, "%dst"), "1");
    _ = try entry.icmp("store.ok", "eq", .i32, sib.local(.i32, "%check"), sib.local(.i32, "%word"));
    _ = try entry.load("remaining", .i64, sib.global(.ptr, "@base64.residual_store_remaining"), "8");
    _ = try entry.binary("next", "add", .i64, sib.local(.i64, "%remaining"), sib.int(.i64, "-4"));
    _ = try entry.icmp("next.ok", "eq", .i64, sib.local(.i64, "%next"), sib.int(.i64, "0"));
    _ = try entry.select("ok", sib.local(.i1, "%store.ok"), .i1, sib.local(.i1, "%next.ok"), sib.int(.i1, "0"));
    _ = try entry.select("ret", sib.local(.i1, "%ok"), .i32, sib.int(.i32, "0"), sib.int(.i32, "1"));
    try entry.ret(sib.local(.i32, "%ret"));
    try function.end();
}

fn writeReleaseSmallRuntimeBase64ResidualLengthStepIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeBase64ResidualLengthStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 residual-length external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeBase64ResidualLengthStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.global("base64.residual_length_total", "private unnamed_addr", .i64, "8", "8");
    try module.global("base64.residual_length_index", "private unnamed_addr", .i64, "4", "8");
    try writer.writeAll("\n");
    var function = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var entry = try function.block("entry");
    _ = try entry.load("total", .i64, sib.global(.ptr, "@base64.residual_length_total"), "8");
    _ = try entry.load("index", .i64, sib.global(.ptr, "@base64.residual_length_index"), "8");
    _ = try entry.binary("remaining", "sub nuw", .i64, sib.local(.i64, "%total"), sib.local(.i64, "%index"));
    _ = try entry.icmp("ok", "eq", .i64, sib.local(.i64, "%remaining"), sib.int(.i64, "4"));
    _ = try entry.select("ret", sib.local(.i1, "%ok"), .i32, sib.int(.i32, "0"), sib.int(.i32, "1"));
    try entry.ret(sib.local(.i32, "%ret"));
    try function.end();
}

fn writeReleaseSmallRuntimeBase64ResidualTableCheckStepIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeBase64ResidualTableCheckStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 residual-table-check external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeBase64ResidualTableCheckStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.global("base64.residual_table_check_input", "private unnamed_addr", .{ .text = "[1 x i8]" }, "c\"\\00\"", "1");
    try module.global("base64.residual_table_check_table", "private unnamed_addr", .{ .text = "[1 x i8]" }, "c\"\\00\"", "1");
    try writer.writeAll("\n");
    var function = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var entry = try function.block("entry");
    _ = try entry.gep("src", .{ .text = "[1 x i8]" }, sib.global(.ptr, "@base64.residual_table_check_input"), .i64, sib.int(.i64, "0"));
    _ = try entry.load("byte", .i8, sib.local(.ptr, "%src"), "1");
    _ = try entry.cast("idx", "zext", sib.local(.i8, "%byte"), .i64);
    _ = try entry.gep("entry_ptr", .{ .text = "[1 x i8]" }, sib.global(.ptr, "@base64.residual_table_check_table"), .i64, sib.local(.i64, "%idx"));
    _ = try entry.load("entry", .i8, sib.local(.ptr, "%entry_ptr"), "1");
    _ = try entry.icmp("invalid", "eq", .i8, sib.local(.i8, "%entry"), sib.int(.i8, "-1"));
    _ = try entry.select("ret", sib.local(.i1, "%invalid"), .i32, sib.int(.i32, "1"), sib.int(.i32, "0"));
    try entry.ret(sib.local(.i32, "%ret"));
    try function.end();
}

fn writeReleaseSmallRuntimeBase64ResidualAccumulatorStepIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeBase64ResidualAccumulatorStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 residual-accumulator external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeBase64ResidualAccumulatorStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.global("base64.residual_accumulator_bits", "private unnamed_addr", .i16, "1", "2");
    try module.global("base64.residual_accumulator_entry", "private unnamed_addr", .i8, "2", "1");
    try module.global("base64.residual_accumulator_count", "private unnamed_addr", .i8, "0", "1");
    try writer.writeAll("\n");
    var function = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var entry = try function.block("entry");
    _ = try entry.load("bits.raw", .i16, sib.global(.ptr, "@base64.residual_accumulator_bits"), "2");
    _ = try entry.cast("bits", "trunc", sib.local(.i16, "%bits.raw"), .i12);
    _ = try entry.binary("shifted", "shl", .i12, sib.local(.i12, "%bits"), sib.int(.i12, "6"));
    _ = try entry.load("entry.raw", .i8, sib.global(.ptr, "@base64.residual_accumulator_entry"), "1");
    _ = try entry.cast("entry.bits", "zext", sib.local(.i8, "%entry.raw"), .i12);
    _ = try entry.binary("next.bits", "add nuw", .i12, sib.local(.i12, "%shifted"), sib.local(.i12, "%entry.bits"));
    try entry.store(sib.local(.i12, "%next.bits"), sib.global(.ptr, "@base64.residual_accumulator_bits"), "2");
    _ = try entry.load("count.raw", .i8, sib.global(.ptr, "@base64.residual_accumulator_count"), "1");
    _ = try entry.cast("count", "trunc", sib.local(.i8, "%count.raw"), .i4);
    _ = try entry.binary("next.count", "add nuw", .i4, sib.local(.i4, "%count"), sib.int(.i4, "6"));
    try entry.store(sib.local(.i4, "%next.count"), sib.global(.ptr, "@base64.residual_accumulator_count"), "1");
    _ = try entry.icmp("ok", "eq", .i4, sib.local(.i4, "%next.count"), sib.int(.i4, "6"));
    _ = try entry.select("ret", sib.local(.i1, "%ok"), .i32, sib.int(.i32, "0"), sib.int(.i32, "1"));
    try entry.ret(sib.local(.i32, "%ret"));
    try function.end();
}

fn writeReleaseSmallRuntimeBase64ResidualLoopAdvanceStepIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeBase64ResidualLoopAdvanceStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 residual-loop-advance external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeBase64ResidualLoopAdvanceStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.global("base64.residual_loop_index", "private unnamed_addr", .i64, "0", "8");
    try writer.writeAll("\n");
    var function = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var entry = try function.block("entry");
    _ = try entry.load("index", .i64, sib.global(.ptr, "@base64.residual_loop_index"), "8");
    _ = try entry.binary("next", "add nuw", .i64, sib.local(.i64, "%index"), sib.int(.i64, "1"));
    _ = try entry.icmp("ok", "eq", .i64, sib.local(.i64, "%next"), sib.int(.i64, "1"));
    _ = try entry.select("ret", sib.local(.i1, "%ok"), .i32, sib.int(.i32, "0"), sib.int(.i32, "1"));
    try entry.ret(sib.local(.i32, "%ret"));
    try function.end();
}

fn writeReleaseSmallRuntimeBase64ResidualPaddingCheckStepIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeBase64ResidualPaddingCheckStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 residual-padding-check external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeBase64ResidualPaddingCheckStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.global("base64.residual_padding_index", "private unnamed_addr", .i64, "1", "8");
    try module.global("base64.residual_padding_base", "private unnamed_addr", .i64, "3", "8");
    try module.global("base64.residual_padding_byte", "private unnamed_addr", .i8, "61", "1");
    try writer.writeAll("\n");
    var function = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var entry = try function.block("entry");
    _ = try entry.load("index", .i64, sib.global(.ptr, "@base64.residual_padding_index"), "8");
    _ = try entry.load("base", .i64, sib.global(.ptr, "@base64.residual_padding_base"), "8");
    _ = try entry.binary("offset", "add nuw", .i64, sib.local(.i64, "%index"), sib.local(.i64, "%base"));
    _ = try entry.icmp("offset.ok", "eq", .i64, sib.local(.i64, "%offset"), sib.int(.i64, "4"));
    _ = try entry.load("byte", .i8, sib.global(.ptr, "@base64.residual_padding_byte"), "1");
    _ = try entry.icmp("pad.ok", "eq", .i8, sib.local(.i8, "%byte"), sib.int(.i8, "61"));
    _ = try entry.select("ok", sib.local(.i1, "%offset.ok"), .i1, sib.local(.i1, "%pad.ok"), sib.int(.i1, "0"));
    _ = try entry.select("ret", sib.local(.i1, "%ok"), .i32, sib.int(.i32, "0"), sib.int(.i32, "1"));
    try entry.ret(sib.local(.i32, "%ret"));
    try function.end();
}

fn writeReleaseSmallRuntimeBase64ResidualFinalMaskStepIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeBase64ResidualFinalMaskStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 residual-final-mask external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeBase64ResidualFinalMaskStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.global("base64.residual_final_index", "private unnamed_addr", .i64, "0", "8");
    try module.global("base64.residual_final_remaining", "private unnamed_addr", .i64, "1", "8");
    try module.global("base64.residual_final_bits", "private unnamed_addr", .i16, "0", "2");
    try module.global("base64.residual_final_shift", "private unnamed_addr", .i8, "0", "1");
    try writer.writeAll("\n");
    var function = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var entry = try function.block("entry");
    _ = try entry.load("index", .i64, sib.global(.ptr, "@base64.residual_final_index"), "8");
    _ = try entry.load("remaining", .i64, sib.global(.ptr, "@base64.residual_final_remaining"), "8");
    _ = try entry.icmp("done", "uge", .i64, sib.local(.i64, "%index"), sib.local(.i64, "%remaining"));
    _ = try entry.load("bits.raw", .i16, sib.global(.ptr, "@base64.residual_final_bits"), "2");
    _ = try entry.cast("bits", "trunc", sib.local(.i16, "%bits.raw"), .i12);
    _ = try entry.load("shift.raw", .i8, sib.global(.ptr, "@base64.residual_final_shift"), "1");
    _ = try entry.binary("shift", "and", .i8, sib.local(.i8, "%shift.raw"), sib.int(.i8, "7"));
    _ = try entry.cast("shift.bits", "zext", sib.local(.i8, "%shift"), .i12);
    _ = try entry.binary("notmask", "shl nsw", .i12, sib.int(.i12, "-1"), sib.local(.i12, "%shift.bits"));
    _ = try entry.binary("mask", "xor", .i12, sib.local(.i12, "%notmask"), sib.int(.i12, "-1"));
    _ = try entry.binary("residual", "and", .i12, sib.local(.i12, "%bits"), sib.local(.i12, "%mask"));
    _ = try entry.icmp("has.residual", "ne", .i12, sib.local(.i12, "%residual"), sib.int(.i12, "0"));
    _ = try entry.binary("fail", "or", .i1, sib.local(.i1, "%done"), sib.local(.i1, "%has.residual"));
    _ = try entry.select("ret", sib.local(.i1, "%fail"), .i32, sib.int(.i32, "1"), sib.int(.i32, "0"));
    try entry.ret(sib.local(.i32, "%ret"));
    try function.end();
}

fn writeReleaseSmallRuntimeBase64ResidualPaddingLoopStepIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeBase64ResidualPaddingLoopStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 residual-padding-loop external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeBase64ResidualPaddingLoopStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.global("base64.residual_padding_loop_source", "private unnamed_addr", .{ .text = "[1 x i8]" }, "c\"=\"", "1");
    try module.global("base64.residual_padding_loop_start", "private unnamed_addr", .i64, "0", "8");
    try module.global("base64.residual_padding_loop_total", "private unnamed_addr", .i64, "1", "8");
    try module.global("base64.residual_padding_loop_index", "private unnamed_addr", .i64, "0", "8");
    try writer.writeAll("\n");
    var function = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var entry = try function.block("entry");
    _ = try entry.load("start", .i64, sib.global(.ptr, "@base64.residual_padding_loop_start"), "8");
    _ = try entry.load("total", .i64, sib.global(.ptr, "@base64.residual_padding_loop_total"), "8");
    _ = try entry.binary("limit", "sub nuw", .i64, sib.local(.i64, "%total"), sib.local(.i64, "%start"));
    _ = try entry.load("loop.index", .i64, sib.global(.ptr, "@base64.residual_padding_loop_index"), "8");
    _ = try entry.icmp("done", "eq", .i64, sib.local(.i64, "%loop.index"), sib.local(.i64, "%limit"));
    _ = try entry.gep("ptr", .{ .text = "[1 x i8]" }, sib.global(.ptr, "@base64.residual_padding_loop_source"), .i64, sib.local(.i64, "%loop.index"));
    _ = try entry.load("byte", .i8, sib.local(.ptr, "%ptr"), "1");
    _ = try entry.icmp("is.pad", "eq", .i8, sib.local(.i8, "%byte"), sib.int(.i8, "61"));
    _ = try entry.binary("next", "add", .i64, sib.local(.i64, "%loop.index"), sib.int(.i64, "1"));
    _ = try entry.icmp("next.ok", "eq", .i64, sib.local(.i64, "%next"), sib.int(.i64, "1"));
    _ = try entry.select("body.ok", sib.local(.i1, "%is.pad"), .i1, sib.local(.i1, "%next.ok"), sib.int(.i1, "0"));
    _ = try entry.select("ok", sib.local(.i1, "%done"), .i1, sib.int(.i1, "1"), sib.local(.i1, "%body.ok"));
    _ = try entry.select("ret", sib.local(.i1, "%ok"), .i32, sib.int(.i32, "0"), sib.int(.i32, "1"));
    try entry.ret(sib.local(.i32, "%ret"));
    try function.end();
}

fn writeReleaseSmallRuntimeBase64DecodeExitStepIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeBase64DecodeExitStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 decode-exit external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeBase64DecodeExitStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.global("base64.decode_exit_bits", "private unnamed_addr", .i16, "0", "2");
    try module.global("base64.decode_exit_count", "private unnamed_addr", .i8, "0", "1");
    try writer.writeAll("\n");
    try module.declare(.void, "llvm.lifetime.end.p0", "ptr");
    try writer.writeAll("\n");
    var function = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var entry = try function.block("entry");
    try entry.lifetimeEnd(sib.global(.ptr, "@base64.decode_exit_count"));
    try entry.lifetimeEnd(sib.global(.ptr, "@base64.decode_exit_bits"));
    try entry.ret(sib.int(.i32, "0"));
    try function.end();
}

fn writeRuntimeCondBranchIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeRuntimeCondBranchStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write runtime conditional branch external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeRuntimeCondBranchStructuredModule(writer: *std.Io.Writer) !void {
    try zsl.emit(.cond_branch, writer);
}

fn writeRuntimePhiMergeIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    _ = io;
    _ = ir_path;
    try zsl.emit(.phi_merge, writer);
}

fn writeRuntimeLoopSumIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    _ = io;
    _ = ir_path;
    try zsl.emit(.loop_sum, writer);
}

fn writeReleaseSafeRuntimeLoopSumIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeReleaseSafeRuntimeLoopSumStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSafe runtime loop sum external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeReleaseSafeRuntimeLoopSumStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.alias("main", .{ .text = "i32 (i32)" }, "@control_flow_calls.loop_sum");
    try module.alias("loop_sum", .{ .text = "i32 (i32)" }, "@control_flow_calls.loop_sum");
    try module.declare(.{ .text = "{ i32, i1 }" }, "llvm.sadd.with.overflow.i32", "i32, i32");
    try module.declare(.void, "llvm.assume", "i1");
    try writer.writeAll("\n");

    var function = try module.function("private ", .i32, "control_flow_calls.loop_sum", "i32 %limit", " local_unnamed_addr");
    var entry = try function.block("entry");
    _ = try entry.icmp("is_zero", "eq", .i32, sib.local(.i32, "%limit"), sib.int(.i32, "0"));
    try entry.condBr(sib.local(.i1, "%is_zero"), "exit_zero", "loop");
    try writer.writeAll("\n");

    var loop = try function.block("loop");
    _ = try loop.phi2("index", .i32, sib.int(.i32, "0"), "entry", sib.local(.i32, "%next"), "cont");
    _ = try loop.phi2("sum", .i32, sib.int(.i32, "0"), "entry", sib.local(.i32, "%sum_next"), "cont");
    _ = try loop.icmp("oob", "eq", .i32, sib.local(.i32, "%index"), sib.int(.i32, "-2147483648"));
    try loop.condBr(sib.local(.i1, "%oob"), "panic_oob", "checked_add");
    try writer.writeAll("\n");

    var checked_add = try function.block("checked_add");
    _ = try checked_add.call("checked", "tail ", .{ .text = "{ i32, i1 }" }, "@llvm.sadd.with.overflow.i32", "i32 %sum, i32 %index");
    _ = try checked_add.extractValue("overflow", "{ i32, i1 }", "%checked", 1, .i1);
    try checked_add.panicEdge(sib.local(.i1, "%overflow"), "cont", "panic_overflow");
    try writer.writeAll("\n");

    var panic_oob = try function.block("panic_oob");
    _ = try panic_oob.call(null, "", .void, "@llvm.assume", "i1 1");
    _ = try panic_oob.call(null, "tail fastcc ", .void, "@\"debug.FullPanic((function 'defaultPanic')).integerOutOfBounds\"", "");
    try panic_oob.emitUnreachable();
    try writer.writeAll("\n");

    var panic_overflow = try function.block("panic_overflow");
    _ = try panic_overflow.call(null, "", .void, "@llvm.assume", "i1 1");
    _ = try panic_overflow.call(null, "tail fastcc ", .void, "@\"debug.FullPanic((function 'defaultPanic')).integerOverflow\"", "");
    try panic_overflow.emitUnreachable();
    try writer.writeAll("\n");

    var cont = try function.block("cont");
    _ = try cont.extractValue("sum_next", "{ i32, i1 }", "%checked", 0, .i32);
    _ = try cont.binary("next", "add", .i32, sib.local(.i32, "%index"), sib.int(.i32, "1"));
    _ = try cont.icmp("done", "eq", .i32, sib.local(.i32, "%next"), sib.local(.i32, "%limit"));
    try cont.condBr(sib.local(.i1, "%done"), "exit", "loop");
    try writer.writeAll("\n");

    var exit_zero = try function.block("exit_zero");
    try exit_zero.ret(sib.int(.i32, "0"));
    try writer.writeAll("\n");

    var exit = try function.block("exit");
    try exit.ret(sib.local(.i32, "%sum_next"));
    try function.end();

    var oob = try module.function("fastcc ", .void, "\"debug.FullPanic((function 'defaultPanic')).integerOutOfBounds\"", "", "");
    var oob_entry = try oob.block("entry");
    try oob_entry.retVoid();
    try oob.end();

    var overflow = try module.function("fastcc ", .void, "\"debug.FullPanic((function 'defaultPanic')).integerOverflow\"", "", "");
    var overflow_entry = try overflow.block("entry");
    try overflow_entry.retVoid();
    try overflow.end();
}

fn writeRuntimeSwitchIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeRuntimeSwitchStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write runtime switch external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeRuntimeSwitchStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.constant("switch.table.switch_control.dense_switch", "private unnamed_addr", .{ .text = "[3 x i32]" }, "[i32 11, i32 13, i32 17]", "4");
    try module.alias("main", .{ .text = "i32 (i8)" }, "@switch_control.dense_switch");
    try writer.writeAll("\n");
    var function = try module.function("private range(i32 11, 24) ", .i32, "switch_control.dense_switch", "i8 zeroext %0", " unnamed_addr");
    var entry = try function.block("entry");
    _ = try entry.icmp("in_table", "ult", .i8, sib.local(.i8, "%0"), sib.int(.i8, "3"));
    try entry.condBr(sib.local(.i1, "%in_table"), "switch.lookup", "fallback");
    try writer.writeAll("\n");
    var lookup = try function.block("switch.lookup");
    _ = try lookup.cast("index", "zext", sib.local(.i8, "%0"), .i64);
    _ = try lookup.gep("switch.gep", .i32, sib.global(.ptr, "@switch.table.switch_control.dense_switch"), .i64, sib.local(.i64, "%index"));
    _ = try lookup.load("switch.load", .i32, sib.local(.ptr, "%switch.gep"), "4");
    try lookup.br("merge");
    try writer.writeAll("\n");
    var fallback = try function.block("fallback");
    _ = try fallback.binary("range_base", "add", .i8, sib.local(.i8, "%0"), sib.int(.i8, "-3"));
    _ = try fallback.icmp("in_range", "ult", .i8, sib.local(.i8, "%range_base"), sib.int(.i8, "3"));
    _ = try fallback.select("fallback_value", sib.local(.i1, "%in_range"), .i32, sib.int(.i32, "19"), sib.int(.i32, "23"));
    try fallback.br("merge");
    try writer.writeAll("\n");
    var merge = try function.block("merge");
    _ = try merge.phi2("ret", .i32, sib.local(.i32, "%switch.load"), "switch.lookup", sib.local(.i32, "%fallback_value"), "fallback");
    try merge.ret(sib.local(.i32, "%ret"));
    try function.end();
}

fn writeReleaseSafeRuntimeBranchMixIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeReleaseSafeRuntimeBranchMixStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSafe runtime branch_mix external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeReleaseSafeRuntimeBranchMixStructuredModule(writer: *std.Io.Writer) !void {
    const checked_pair: sib.Type = .{ .text = "{ i32, i1 }" };
    var module = sib.Module.init(writer);
    try module.alias("branch_mix", .{ .text = "i32 (i32, i32, i1)" }, "@switch_control.branch_mix");
    try writer.writeAll("\n");
    try module.declare(checked_pair, "llvm.sadd.with.overflow.i32", "i32, i32");
    try module.declare(checked_pair, "llvm.ssub.with.overflow.i32", "i32, i32");
    try module.declare(.void, "llvm.assume", "i1");
    try writer.writeAll("\n");
    var main_fn = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var main_entry = try main_fn.block("entry");
    try main_entry.ret(sib.int(.i32, "0"));
    try main_fn.end();
    var branch_mix = try module.function("private ", .i32, "switch_control.branch_mix", "i32 %a, i32 %b, i1 %flag", " unnamed_addr align 1");
    var entry = try branch_mix.block("entry");
    try entry.condBr(sib.local(.i1, "%flag"), "add_path", "sub_path");
    try writer.writeAll("\n");
    var merge = try branch_mix.block("merge");
    _ = try merge.phi2("value", checked_pair, sib.local(checked_pair, "%add_checked"), "add_path", sib.local(checked_pair, "%sub_checked"), "sub_path");
    try writer.writeAll("  %result = extractvalue { i32, i1 } %value, 0\n");
    try merge.ret(sib.local(.i32, "%result"));
    try writer.writeAll("\n");
    var add_path = try branch_mix.block("add_path");
    _ = try add_path.call("add_checked", "tail ", checked_pair, "@llvm.sadd.with.overflow.i32", "i32 %a, i32 %b");
    try writer.writeAll("  %add_overflow = extractvalue { i32, i1 } %add_checked, 1\n");
    try add_path.panicEdge(sib.local(.i1, "%add_overflow"), "merge", "panic_add");
    try writer.writeAll("\n");
    var sub_path = try branch_mix.block("sub_path");
    _ = try sub_path.call("sub_checked", "tail ", checked_pair, "@llvm.ssub.with.overflow.i32", "i32 %a, i32 %b");
    try writer.writeAll("  %sub_overflow = extractvalue { i32, i1 } %sub_checked, 1\n");
    try sub_path.panicEdge(sib.local(.i1, "%sub_overflow"), "merge", "panic_sub");
    try writer.writeAll("\n");
    try irw.integerOverflowPanicBlock(writer, "panic_add");
    try writer.writeAll("\n");
    try irw.integerOverflowPanicBlock(writer, "panic_sub");
    try branch_mix.end();
    var panic_fn = try module.function("fastcc ", .void, "\"debug.FullPanic((function 'defaultPanic')).integerOverflow\"", "", "");
    var panic_entry = try panic_fn.block("entry");
    try panic_entry.retVoid();
    try panic_fn.end();
}

fn writeRuntimeGlobalUpdateIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeRuntimeGlobalUpdateStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write runtime global update external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeRuntimeGlobalUpdateStructuredModule(writer: *std.Io.Writer) !void {
    try zsl.emit(.global_update, writer);
}

fn writeReleaseSafeRuntimeGlobalUpdateIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeReleaseSafeGlobalUpdateModule(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSafe runtime global update external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeReleaseSafeGlobalUpdateModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.global("globals_comptime.global_counter", "private", .i32, "3", "4");
    try module.alias("main", .{ .text = "i32 (i32)" }, "@globals_comptime.update_global");
    try writer.writeAll("\n");
    try module.declare(.{ .text = "{ i32, i1 }" }, "llvm.sadd.with.overflow.i32", "i32, i32");
    try module.declare(.void, "llvm.assume", "i1");
    try writer.writeAll("\n");
    var function = try module.function("private ", .i32, "globals_comptime.update_global", "i32 %value", " unnamed_addr align 1");
    var entry = try function.block("entry");
    _ = try entry.load("current", .i32, sib.global(.ptr, "@globals_comptime.global_counter"), "4");
    _ = try entry.checkedSAddI32("checked", sib.local(.i32, "%current"), sib.local(.i32, "%value"));
    try entry.panicEdge(sib.local(.i1, "%checked.overflow"), "ok", "panic");
    try writer.writeAll("\n");
    try writeIntegerOverflowPanicBlockStructured(&function, "panic");
    try writer.writeAll("\n");
    var ok = try function.block("ok");
    try ok.store(sib.local(.i32, "%checked.value"), sib.global(.ptr, "@globals_comptime.global_counter"), "4");
    try ok.ret(sib.local(.i32, "%checked.value"));
    try function.end();
    try writeIntegerOverflowPanicFunctionStructured(&module);
}

fn writeRuntimePointerLoadStoreIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeRuntimePointerLoadStoreStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write runtime pointer load/store external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeRuntimePointerLoadStoreStructuredModule(writer: *std.Io.Writer) !void {
    try zsl.emit(.pointer_load_store, writer);
}

fn writeReleaseSafeRuntimePointerLoadStoreIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeReleaseSafeRuntimePointerLoadStoreStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSafe runtime pointer load/store external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeReleaseSafeRuntimePointerLoadStoreStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.global("pointers_memory.writer_input", "dso_local", .i32, "41", "4");
    try module.global("pointers_memory.writer_output", "dso_local", .i32, "0", "4");
    try module.alias("load_store", .{ .text = "i32 (ptr, ptr)" }, "@pointers_memory.load_store");
    try writer.writeAll("\n");
    try module.declare(.{ .text = "{ i32, i1 }" }, "llvm.sadd.with.overflow.i32", "i32, i32");
    try module.declare(.void, "llvm.assume", "i1");
    try writer.writeAll("\n");
    var main_fn = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var main_entry = try main_fn.block("entry");
    _ = try main_entry.load("value", .i32, sib.global(.ptr, "@pointers_memory.writer_input"), "4");
    _ = try main_entry.binary("updated", "add", .i32, sib.local(.i32, "%value"), sib.int(.i32, "1"));
    try main_entry.store(sib.local(.i32, "%updated"), sib.global(.ptr, "@pointers_memory.writer_output"), "4");
    _ = try main_entry.load("stored", .i32, sib.global(.ptr, "@pointers_memory.writer_output"), "4");
    _ = try main_entry.icmp("ok", "eq", .i32, sib.local(.i32, "%stored"), sib.int(.i32, "42"));
    _ = try main_entry.select("ret", sib.local(.i1, "%ok"), .i32, sib.int(.i32, "0"), sib.int(.i32, "1"));
    try main_entry.ret(sib.local(.i32, "%ret"));
    try main_fn.end();
    var callee = try module.function("private ", .i32, "pointers_memory.load_store", "ptr %0, ptr %1", " unnamed_addr align 1");
    var entry = try callee.block("entry");
    _ = try entry.load("3", .i32, sib.local(.ptr, "%0"), "4");
    _ = try entry.checkedSAddI32("4", sib.local(.i32, "%3"), sib.int(.i32, "1"));
    try entry.panicEdge(sib.local(.i1, "%4.overflow"), "ok", "panic");
    try writer.writeAll("\n");
    try writeIntegerOverflowPanicBlockStructured(&callee, "panic");
    try writer.writeAll("\n");
    var ok = try callee.block("ok");
    try ok.store(sib.local(.i32, "%4.value"), sib.local(.ptr, "%1"), "4");
    try ok.ret(sib.local(.i32, "%4.value"));
    try callee.end();
    try writeIntegerOverflowPanicFunctionStructured(&module);
}

fn writeRuntimeVolatileRoundtripIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeRuntimeVolatileRoundtripStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write runtime volatile roundtrip external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeRuntimeVolatileRoundtripStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.global("pointers_memory.volatile_slot", "dso_local", .i32, "0", "4");
    try module.alias("volatile_roundtrip", .{ .text = "i32 (ptr, i32)" }, "@pointers_memory.volatile_roundtrip");
    try writer.writeAll("\n");
    var main_fn = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var main_entry = try main_fn.block("entry");
    try main_entry.volatileStore(sib.int(.i32, "42"), sib.global(.ptr, "@pointers_memory.volatile_slot"), "4");
    _ = try main_entry.volatileLoad("value", .i32, sib.global(.ptr, "@pointers_memory.volatile_slot"), "4");
    _ = try main_entry.icmp("ok", "eq", .i32, sib.local(.i32, "%value"), sib.int(.i32, "42"));
    _ = try main_entry.select("ret", sib.local(.i1, "%ok"), .i32, sib.int(.i32, "0"), sib.int(.i32, "1"));
    try main_entry.ret(sib.local(.i32, "%ret"));
    try main_fn.end();
    var callee = try module.function("private ", .i32, "pointers_memory.volatile_roundtrip", "ptr %0, i32 %1", " unnamed_addr align 1");
    var entry = try callee.block("entry");
    try entry.volatileStore(sib.local(.i32, "%1"), sib.local(.ptr, "%0"), "4");
    _ = try entry.volatileLoad("3", .i32, sib.local(.ptr, "%0"), "4");
    try entry.ret(sib.local(.i32, "%3"));
    try callee.end();
}

fn writeRuntimeOptionalPointerIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeRuntimeOptionalPointerStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write runtime optional pointer external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeRuntimeOptionalPointerStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.global("optional_pointer.writer_value", "dso_local", .i32, "42", "4");
    try module.alias("optional_ptr_value", .{ .text = "i32 (ptr)" }, "@optional_pointer.optional_ptr_value");
    try writer.writeAll("\n");
    var main_fn = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var main_entry = try main_fn.block("entry");
    _ = try main_entry.icmp(".not", "eq", .ptr, sib.global(.ptr, "@optional_pointer.writer_value"), sib.int(.ptr, "null"));
    try main_entry.condBr(sib.local(.i1, "%.not"), "null", "nonnull");
    try writer.writeAll("\n");
    var null_block = try main_fn.block("null");
    try null_block.ret(sib.int(.i32, "1"));
    try writer.writeAll("\n");
    var nonnull_main = try main_fn.block("nonnull");
    _ = try nonnull_main.load("value", .i32, sib.global(.ptr, "@optional_pointer.writer_value"), "4");
    _ = try nonnull_main.icmp("ok", "eq", .i32, sib.local(.i32, "%value"), sib.int(.i32, "42"));
    _ = try nonnull_main.select("ret", sib.local(.i1, "%ok"), .i32, sib.int(.i32, "0"), sib.int(.i32, "1"));
    try nonnull_main.ret(sib.local(.i32, "%ret"));
    try main_fn.end();
    var callee = try module.function("private ", .i32, "optional_pointer.optional_ptr_value", "ptr %0", " unnamed_addr align 1");
    var entry = try callee.block("entry");
    _ = try entry.icmp(".not", "eq", .ptr, sib.local(.ptr, "%0"), sib.int(.ptr, "null"));
    try entry.condBr(sib.local(.i1, "%.not"), "common.ret", "nonnull");
    try writer.writeAll("\n");
    var common_ret = try callee.block("common.ret");
    _ = try common_ret.phi2("common.ret.op", .i32, sib.local(.i32, "%loaded"), "nonnull", sib.int(.i32, "-1"), "entry");
    try common_ret.ret(sib.local(.i32, "%common.ret.op"));
    try writer.writeAll("\n");
    var nonnull = try callee.block("nonnull");
    _ = try nonnull.load("loaded", .i32, sib.local(.ptr, "%0"), "4");
    try nonnull.br("common.ret");
    try callee.end();
}

fn writeRuntimePackedReadFlagIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeRuntimePackedReadFlagStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write runtime packed read-flag external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeRuntimePackedReadFlagStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try writePackedBitsAliases(&module, writer, true);
    var main_fn = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var main_entry = try main_fn.block("entry");
    _ = try main_entry.icmp("flag", "slt", .i8, sib.int(.i8, "-128"), sib.int(.i8, "0"));
    _ = try main_entry.select("ret", sib.local(.i1, "%flag"), .i32, sib.int(.i32, "0"), sib.int(.i32, "1"));
    try main_entry.ret(sib.local(.i32, "%ret"));
    try main_fn.end();
    try writePackedBitsCallees(&module, true);
}

fn writeRuntimePackedReplaceLowIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeRuntimePackedReplaceLowStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write runtime packed replace-low external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeRuntimePackedReplaceLowStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try writePackedBitsAliases(&module, writer, false);
    var main_fn = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var main_entry = try main_fn.block("entry");
    _ = try main_entry.binary("high", "and", .i8, sib.int(.i8, "-1"), sib.int(.i8, "-8"));
    _ = try main_entry.binary("low", "and", .i8, sib.int(.i8, "5"), sib.int(.i8, "7"));
    _ = try main_entry.binary("packed", "or", .i8, sib.local(.i8, "%low"), sib.local(.i8, "%high"));
    _ = try main_entry.icmp("ok", "eq", .i8, sib.local(.i8, "%packed"), sib.int(.i8, "-3"));
    _ = try main_entry.select("ret", sib.local(.i1, "%ok"), .i32, sib.int(.i32, "0"), sib.int(.i32, "1"));
    try main_entry.ret(sib.local(.i32, "%ret"));
    try main_fn.end();
    try writePackedBitsCallees(&module, false);
}

fn writePackedBitsAliases(module: *sib.Module, writer: *std.Io.Writer, read_first: bool) !void {
    if (read_first) {
        try module.alias("read_flag", .{ .text = "i1 (i8)" }, "@packed_bits.read_flag");
        try module.alias("replace_low", .{ .text = "i8 (i8, i8)" }, "@packed_bits.replace_low");
    } else {
        try module.alias("replace_low", .{ .text = "i8 (i8, i8)" }, "@packed_bits.replace_low");
        try module.alias("read_flag", .{ .text = "i1 (i8)" }, "@packed_bits.read_flag");
    }
    try writer.writeAll("\n");
}

fn writePackedBitsCallees(module: *sib.Module, replace_first: bool) !void {
    if (replace_first) {
        try writePackedReplaceLowCallee(module);
        try writePackedReadFlagCallee(module);
    } else {
        try writePackedReadFlagCallee(module);
        try writePackedReplaceLowCallee(module);
    }
}

fn writePackedReadFlagCallee(module: *sib.Module) !void {
    var callee = try module.function("private ", .i1, "packed_bits.read_flag", "i8 %0", " unnamed_addr align 1");
    var entry = try callee.block("entry");
    _ = try entry.icmp("2", "slt", .i8, sib.local(.i8, "%0"), sib.int(.i8, "0"));
    try entry.ret(sib.local(.i1, "%2"));
    try callee.end();
}

fn writePackedReplaceLowCallee(module: *sib.Module) !void {
    var callee = try module.function("private ", .i8, "packed_bits.replace_low", "i8 %0, i8 %1", " unnamed_addr align 1");
    var entry = try callee.block("entry");
    _ = try entry.binary("3", "and", .i8, sib.local(.i8, "%0"), sib.int(.i8, "-8"));
    _ = try entry.binary("4", "and", .i8, sib.local(.i8, "%1"), sib.int(.i8, "7"));
    _ = try entry.binary("5", "or", .i8, sib.local(.i8, "%4"), sib.local(.i8, "%3"));
    try entry.ret(sib.local(.i8, "%5"));
    try callee.end();
}

fn writeRuntimeStructSumIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeRuntimeStructSumStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write runtime struct-sum external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeRuntimeStructSumStructuredModule(writer: *std.Io.Writer) !void {
    try zsl.emit(.struct_sum, writer);
}

fn writeReleaseSafeRuntimeStructSumIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeReleaseSafeRuntimeStructSumStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSafe runtime struct-sum external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeReleaseSafeRuntimeStructSumStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.constant("struct_sum_value", "", .{ .text = "[2 x i32]" }, "[i32 20, i32 22]", "4");
    try module.alias("struct_sum", .{ .text = "i32 (ptr)" }, "@aggregates.struct_sum");
    try writer.writeAll("\n");
    try module.declare(.{ .text = "{ i32, i1 }" }, "llvm.sadd.with.overflow.i32", "i32, i32");
    try module.declare(.void, "llvm.assume", "i1");
    try writer.writeAll("\n");
    var main_fn = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var main_entry = try main_fn.block("entry");
    _ = try main_entry.call("value", "", .i32, "@aggregates.struct_sum", "ptr @struct_sum_value");
    _ = try main_entry.icmp("ok", "eq", .i32, sib.local(.i32, "%value"), sib.int(.i32, "42"));
    _ = try main_entry.select("ret", sib.local(.i1, "%ok"), .i32, sib.int(.i32, "0"), sib.int(.i32, "1"));
    try main_entry.ret(sib.local(.i32, "%ret"));
    try main_fn.end();
    var callee = try module.function("private ", .i32, "aggregates.struct_sum", "ptr %0", " unnamed_addr align 1");
    var entry = try callee.block("entry");
    _ = try entry.load("2", .i32, sib.local(.ptr, "%0"), "4");
    _ = try entry.gep("3", .i8, sib.local(.ptr, "%0"), .i64, sib.int(.i64, "4"));
    _ = try entry.load("4", .i32, sib.local(.ptr, "%3"), "4");
    _ = try entry.checkedSAddI32("checked", sib.local(.i32, "%2"), sib.local(.i32, "%4"));
    try entry.panicEdge(sib.local(.i1, "%checked.overflow"), "ok", "panic");
    try writer.writeAll("\n");
    try writeIntegerOverflowPanicBlockStructured(&callee, "panic");
    try writer.writeAll("\n");
    var ok = try callee.block("ok");
    try ok.ret(sib.local(.i32, "%checked.value"));
    try callee.end();
    try writeIntegerOverflowPanicFunctionStructured(&module);
}

fn writeRuntimeArraySumIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeRuntimeArraySumStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write runtime array-sum external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeRuntimeArraySumStructuredModule(writer: *std.Io.Writer) !void {
    try zsl.emit(.array_sum, writer);
}

fn writeReleaseSafeRuntimeArraySumIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeReleaseSafeRuntimeArraySumStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSafe runtime array-sum external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeReleaseSafeRuntimeArraySumStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.alias("array_sum", .{ .text = "i32 (i32, i32, i32)" }, "@aggregates.array_sum");
    try writer.writeAll("\n");
    try module.declare(.{ .text = "{ i32, i1 }" }, "llvm.sadd.with.overflow.i32", "i32, i32");
    try module.declare(.void, "llvm.assume", "i1");
    try writer.writeAll("\n");
    var main_fn = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var main_entry = try main_fn.block("entry");
    _ = try main_entry.call("value", "", .i32, "@aggregates.array_sum", "i32 10, i32 20, i32 12");
    _ = try main_entry.icmp("ok", "eq", .i32, sib.local(.i32, "%value"), sib.int(.i32, "42"));
    _ = try main_entry.select("ret", sib.local(.i1, "%ok"), .i32, sib.int(.i32, "0"), sib.int(.i32, "1"));
    try main_entry.ret(sib.local(.i32, "%ret"));
    try main_fn.end();
    var callee = try module.function("private ", .i32, "aggregates.array_sum", "i32 %0, i32 %1, i32 %2", " unnamed_addr align 1");
    var entry = try callee.block("entry");
    _ = try entry.checkedSAddI32("first", sib.local(.i32, "%0"), sib.local(.i32, "%1"));
    try entry.panicEdge(sib.local(.i1, "%first.overflow"), "second", "panic_first");
    try writer.writeAll("\n");
    try writeIntegerOverflowPanicBlockStructured(&callee, "panic_first");
    try writer.writeAll("\n");
    var second = try callee.block("second");
    _ = try second.checkedSAddI32("second", sib.local(.i32, "%first.value"), sib.local(.i32, "%2"));
    try second.panicEdge(sib.local(.i1, "%second.overflow"), "ok", "panic_second");
    try writer.writeAll("\n");
    try writeIntegerOverflowPanicBlockStructured(&callee, "panic_second");
    try writer.writeAll("\n");
    var ok = try callee.block("ok");
    try ok.ret(sib.local(.i32, "%second.value"));
    try callee.end();
    try writeIntegerOverflowPanicFunctionStructured(&module);
}

fn writeRuntimeOptionalPayloadIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeRuntimeOptionalPayloadStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write runtime optional-payload external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeRuntimeOptionalPayloadStructuredModule(writer: *std.Io.Writer) !void {
    try zsl.emit(.optional_payload, writer);
}

fn writeRuntimeErrorUnionPayloadIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeRuntimeErrorUnionPayloadStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write runtime error-union-payload external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeRuntimeErrorUnionPayloadStructuredModule(writer: *std.Io.Writer) !void {
    try zsl.emit(.error_union_payload, writer);
}

fn writeRuntimeSliceSumIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeRuntimeSliceSumStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write runtime slice-sum external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeRuntimeSliceSumStructuredModule(writer: *std.Io.Writer) !void {
    try zsl.emit(.slice_sum, writer);
}

fn writeReleaseSafeRuntimeSliceSumIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeReleaseSafeRuntimeSliceSumStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSafe runtime slice-sum external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeReleaseSafeRuntimeSliceSumStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.constant("slice_sum_values", "", .{ .text = "[4 x i32]" }, "[i32 1, i32 2, i32 3, i32 4]", "4");
    try module.alias("slice_sum", .{ .text = "i32 (ptr, i64)" }, "@aggregates.slice_sum");
    try writer.writeAll("\n");
    try module.declare(.{ .text = "{ i32, i1 }" }, "llvm.sadd.with.overflow.i32", "i32, i32");
    try module.declare(.void, "llvm.assume", "i1");
    try writer.writeAll("\n");
    var main_fn = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var main_entry = try main_fn.block("entry");
    _ = try main_entry.call("value", "", .i32, "@aggregates.slice_sum", "ptr @slice_sum_values, i64 4");
    _ = try main_entry.icmp("ok", "eq", .i32, sib.local(.i32, "%value"), sib.int(.i32, "10"));
    _ = try main_entry.select("ret", sib.local(.i1, "%ok"), .i32, sib.int(.i32, "0"), sib.int(.i32, "1"));
    try main_entry.ret(sib.local(.i32, "%ret"));
    try main_fn.end();
    var callee = try module.function("private ", .i32, "aggregates.slice_sum", "ptr %0, i64 %1", " unnamed_addr align 1");
    var entry = try callee.block("entry");
    _ = try entry.icmp(".not", "eq", .i64, sib.local(.i64, "%1"), sib.int(.i64, "0"));
    try entry.condBr(sib.local(.i1, "%.not"), "exit", "loop");
    try writer.writeAll("\n");
    var loop = try callee.block("loop");
    _ = try loop.phi2("sum", .i32, sib.int(.i32, "0"), "entry", sib.local(.i32, "%sum_next"), "cont");
    _ = try loop.phi2("index", .i64, sib.int(.i64, "0"), "entry", sib.local(.i64, "%next"), "cont");
    _ = try loop.gep("ptr", .{ .text = "[4 x i8]" }, sib.local(.ptr, "%0"), .i64, sib.local(.i64, "%index"));
    _ = try loop.load("loaded", .i32, sib.local(.ptr, "%ptr"), "4");
    _ = try loop.checkedSAddI32("checked", sib.local(.i32, "%sum"), sib.local(.i32, "%loaded"));
    try loop.panicEdge(sib.local(.i1, "%checked.overflow"), "cont", "panic");
    try writer.writeAll("\n");
    try writeIntegerOverflowPanicBlockStructured(&callee, "panic");
    try writer.writeAll("\n");
    var cont = try callee.block("cont");
    _ = try cont.binary("sum_next", "add", .i32, sib.local(.i32, "%checked.value"), sib.int(.i32, "0"));
    _ = try cont.binary("next", "add", .i64, sib.local(.i64, "%index"), sib.int(.i64, "1"));
    _ = try cont.icmp("done", "eq", .i64, sib.local(.i64, "%next"), sib.local(.i64, "%1"));
    try cont.condBr(sib.local(.i1, "%done"), "exit", "loop");
    try writer.writeAll("\n");
    var exit = try callee.block("exit");
    _ = try exit.phi2("result", .i32, sib.int(.i32, "0"), "entry", sib.local(.i32, "%sum_next"), "cont");
    try exit.ret(sib.local(.i32, "%result"));
    try callee.end();
    try writeIntegerOverflowPanicFunctionStructured(&module);
}

fn writeRuntimeFpConstantsIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeRuntimeFpConstantsStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write runtime FP constants external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeRuntimeFpConstantsStructuredModule(writer: *std.Io.Writer) !void {
    try zsl.emit(.fp_literals, writer);
}

fn writeRuntimeComptimeConstIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeRuntimeComptimeConstStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write runtime comptime const external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeRuntimeComptimeConstStructuredModule(writer: *std.Io.Writer) !void {
    try zsl.emit(.comptime_const, writer);
}

fn writeReleaseSafeRuntimeComptimeConstIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeReleaseSafeRuntimeComptimeConstStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSafe runtime comptime const external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeReleaseSafeRuntimeComptimeConstStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.alias("comptime_const", .{ .text = "i32 (i32)" }, "@globals_comptime.comptime_const");
    try writer.writeAll("\n");
    try module.declare(.{ .text = "{ i32, i1 }" }, "llvm.smul.with.overflow.i32", "i32, i32");
    try module.declare(.void, "llvm.assume", "i1");
    try writer.writeAll("\n");
    var main_fn = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var main_entry = try main_fn.block("entry");
    _ = try main_entry.call("value", "", .i32, "@globals_comptime.comptime_const", "i32 7");
    _ = try main_entry.icmp("ok", "eq", .i32, sib.local(.i32, "%value"), sib.int(.i32, "35"));
    _ = try main_entry.select("ret", sib.local(.i1, "%ok"), .i32, sib.int(.i32, "0"), sib.int(.i32, "1"));
    try main_entry.ret(sib.local(.i32, "%ret"));
    try main_fn.end();
    var callee = try module.function("private ", .i32, "globals_comptime.comptime_const", "i32 %value", " unnamed_addr align 1");
    var entry = try callee.block("entry");
    _ = try entry.checkedSMulI32("checked", sib.local(.i32, "%value"), sib.int(.i32, "5"));
    try entry.panicEdge(sib.local(.i1, "%checked.overflow"), "ok", "panic");
    try writer.writeAll("\n");
    try writeIntegerOverflowPanicBlockStructured(&callee, "panic");
    try writer.writeAll("\n");
    var ok = try callee.block("ok");
    try ok.ret(sib.local(.i32, "%checked.value"));
    try callee.end();
    try writeIntegerOverflowPanicFunctionStructured(&module);
}

fn writeRuntimeDebugLocationIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeRuntimeDebugLocationStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write runtime debug_location external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeRuntimeDebugLocationStructuredModule(writer: *std.Io.Writer) !void {
    try zsl.emit(.debug_location, writer);
}

fn writeReleaseSafeRuntimeDebugLocationIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeReleaseSafeRuntimeDebugLocationStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSafe runtime debug_location external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeReleaseSafeRuntimeDebugLocationStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.alias("debug_location", .{ .text = "i32 (i32)" }, "@atomics_inline_asm_debug.debug_location");
    try writer.writeAll("\n");
    try module.declare(.{ .text = "{ i32, i1 }" }, "llvm.sadd.with.overflow.i32", "i32, i32");
    try module.declare(.void, "llvm.assume", "i1");
    try writer.writeAll("\n");
    var main_fn = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var main_entry = try main_fn.block("entry");
    _ = try main_entry.call("value", "", .i32, "@atomics_inline_asm_debug.debug_location", "i32 41");
    _ = try main_entry.icmp("ok", "eq", .i32, sib.local(.i32, "%value"), sib.int(.i32, "42"));
    _ = try main_entry.select("ret", sib.local(.i1, "%ok"), .i32, sib.int(.i32, "0"), sib.int(.i32, "1"));
    try main_entry.ret(sib.local(.i32, "%ret"));
    try main_fn.end();
    var callee = try module.function("private ", .i32, "atomics_inline_asm_debug.debug_location", "i32 %value", " unnamed_addr align 1");
    var entry = try callee.block("entry");
    _ = try entry.checkedSAddI32("checked", sib.local(.i32, "%value"), sib.int(.i32, "1"));
    try entry.panicEdge(sib.local(.i1, "%checked.overflow"), "ok", "panic");
    try writer.writeAll("\n");
    try writeIntegerOverflowPanicBlockStructured(&callee, "panic");
    try writer.writeAll("\n");
    var ok = try callee.block("ok");
    try ok.ret(sib.local(.i32, "%checked.value"));
    try callee.end();
    try writeIntegerOverflowPanicFunctionStructured(&module);
}

fn writeIntegerOverflowPanicBlockStructured(function: *sib.Function, name: []const u8) !void {
    var panic = try function.block(name);
    _ = try panic.call(null, "", .void, "@llvm.assume", "i1 1");
    _ = try panic.call(null, "tail fastcc ", .void, "@\"debug.FullPanic((function 'defaultPanic')).integerOverflow\"", "");
    try panic.emitUnreachable();
}

fn writeIntegerOverflowPanicFunctionStructured(module: *sib.Module) !void {
    var panic_fn = try module.function("fastcc ", .void, "\"debug.FullPanic((function 'defaultPanic')).integerOverflow\"", "", "");
    var panic_entry = try panic_fn.block("entry");
    try panic_entry.retVoid();
    try panic_fn.end();
}

fn writeRuntimeCallChainIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeRuntimeCallChainStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write runtime call chain external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeRuntimeCallChainStructuredModule(writer: *std.Io.Writer) !void {
    try zsl.emit(.call_chain, writer);
}

fn writeReleaseSafeRuntimeCallChainIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeReleaseSafeRuntimeCallChainStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSafe runtime call_chain external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeReleaseSafeRuntimeCallChainStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.alias("main", .{ .text = "i32 (i32)" }, "@control_flow_calls.call_chain");
    try module.alias("call_chain", .{ .text = "i32 (i32)" }, "@control_flow_calls.call_chain");
    try writer.writeAll("\n");
    try module.declare(.void, "llvm.assume", "i1");
    try writer.writeAll("\n");
    var chain = try module.function("private ", .i32, "control_flow_calls.call_chain", "i32 %value", " unnamed_addr align 1");
    var entry = try chain.block("entry");
    _ = try entry.binary("biased", "add", .i32, sib.local(.i32, "%value"), sib.int(.i32, "1073741824"));
    _ = try entry.icmp("overflow", "slt", .i32, sib.local(.i32, "%biased"), sib.int(.i32, "0"));
    try entry.panicEdge(sib.local(.i1, "%overflow"), "ok", "panic");
    try writer.writeAll("\n");
    try writeIntegerOverflowPanicBlockStructured(&chain, "panic");
    try writer.writeAll("\n");
    var ok = try chain.block("ok");
    _ = try ok.binary("shifted", "shl nsw", .i32, sib.local(.i32, "%value"), sib.int(.i32, "1"));
    _ = try ok.binary("ret", "or disjoint", .i32, sib.local(.i32, "%shifted"), sib.int(.i32, "1"));
    try ok.ret(sib.local(.i32, "%ret"));
    try chain.end();
    try writeIntegerOverflowPanicFunctionStructured(&module);
}

fn writeRuntimeTlsReadIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeTlsReadModule(writer) catch |err| {
        try fatal(io, "failed to write runtime TLS read external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeTlsReadModule(writer: *std.Io.Writer) !void {
    try zsl.emit(.tls_read, writer);
}

fn writeRuntimeTlsBumpIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeTlsBumpModule(writer, false) catch |err| {
        try fatal(io, "failed to write runtime TLS bump external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeReleaseSafeRuntimeTlsBumpIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeTlsBumpModule(writer, true) catch |err| {
        try fatal(io, "failed to write ReleaseSafe runtime TLS bump external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeTlsBumpModule(writer: *std.Io.Writer, checked: bool) !void {
    var module = sib.Module.init(writer);
    try module.tlsGlobal("tls_concurrency.tls_counter", "internal", "localexec", .i32, "1", "4");
    try module.alias("main", .{ .text = "i32 (i32)" }, "@tls_concurrency.bump_tls");
    if (checked) try module.alias("bump_tls", .{ .text = "i32 (i32)" }, "@tls_concurrency.bump_tls");
    try writer.writeAll("\n");
    if (checked) {
        try module.declare(.{ .text = "{ i32, i1 }" }, "llvm.sadd.with.overflow.i32", "i32, i32");
        try module.declare(.void, "llvm.assume", "i1");
        try writer.writeAll("\n");
    }
    var function = try module.function("private ", .i32, "tls_concurrency.bump_tls", "i32 %value", if (checked) " unnamed_addr align 1" else " local_unnamed_addr");
    var entry = try function.block("entry");
    _ = try entry.load("current", .i32, sib.global(.ptr, "@tls_concurrency.tls_counter"), "4");
    if (checked) {
        _ = try entry.checkedSAddI32("checked", sib.local(.i32, "%current"), sib.local(.i32, "%value"));
        try entry.panicEdge(sib.local(.i1, "%checked.overflow"), "ok", "panic");
        try writer.writeAll("\n");
        try writeIntegerOverflowPanicBlockStructured(&function, "panic");
        try writer.writeAll("\n");
        var ok_block = try function.block("ok");
        try ok_block.store(sib.local(.i32, "%checked.value"), sib.global(.ptr, "@tls_concurrency.tls_counter"), "4");
        try ok_block.ret(sib.local(.i32, "%checked.value"));
    } else {
        _ = try entry.binary("updated", "add", .i32, sib.local(.i32, "%current"), sib.local(.i32, "%value"));
        try entry.store(sib.local(.i32, "%updated"), sib.global(.ptr, "@tls_concurrency.tls_counter"), "4");
        try entry.ret(sib.local(.i32, "%updated"));
    }
    try function.end();
    if (checked) try writeIntegerOverflowPanicFunctionStructured(&module);
}

fn writeRuntimeAtomicAddIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeRuntimeAtomicAddStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write runtime atomic add external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeRuntimeAtomicAddStructuredModule(writer: *std.Io.Writer) !void {
    try zsl.emit(.atomic_add, writer);
}

fn writeRuntimeInlineAsmBarrierIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeInlineAsmBarrierModule(writer) catch |err| {
        try fatal(io, "failed to write runtime inline asm barrier external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeInlineAsmBarrierModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.alias("main", .{ .text = "i32 (i32)" }, "@atomics_inline_asm_debug.inline_asm_barrier");
    try writer.writeAll("\n");
    var function = try module.function("private ", .i32, "atomics_inline_asm_debug.inline_asm_barrier", "i32 %value", " local_unnamed_addr");
    var entry = try function.block("entry");
    try entry.inlineAsmBarrier();
    try entry.ret(sib.local(.i32, "%value"));
    try function.end();
}

fn writeRuntimeAggregatePairIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeRuntimeAggregatePairStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write runtime aggregate pair external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeRuntimeAggregatePairStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.alias("pair_first", .{ .text = "i32 (i64)" }, "@aggregate_abi.pair_first");
    try module.alias("make_pair", .{ .text = "i64 (i32, i32)" }, "@aggregate_abi.make_pair");
    try module.alias("main", .{ .text = "i32 (i64)" }, "@aggregate_abi.pair_first");
    try writer.writeAll("\n");
    var pair_first = try module.function("private ", .i32, "aggregate_abi.pair_first", "i64 %0", " unnamed_addr align 1");
    var first_entry = try pair_first.block("entry");
    _ = try first_entry.cast(".sroa.01.0.extract.trunc", "trunc", sib.local(.i64, "%0"), .i32);
    try first_entry.ret(sib.local(.i32, "%.sroa.01.0.extract.trunc"));
    try pair_first.end();
    var make_pair = try module.function("private ", .i64, "aggregate_abi.make_pair", "i32 %0, i32 %1", " unnamed_addr align 1");
    var entry = try make_pair.block("entry");
    _ = try entry.cast(".sroa.2.0.insert.ext", "zext", sib.local(.i32, "%1"), .i64);
    _ = try entry.binary(".sroa.2.0.insert.shift", "shl nuw", .i64, sib.local(.i64, "%.sroa.2.0.insert.ext"), sib.int(.i64, "32"));
    _ = try entry.cast(".sroa.0.0.insert.ext", "zext", sib.local(.i32, "%0"), .i64);
    _ = try entry.binary(".sroa.0.0.insert.insert", "or disjoint", .i64, sib.local(.i64, "%.sroa.2.0.insert.shift"), sib.local(.i64, "%.sroa.0.0.insert.ext"));
    try entry.ret(sib.local(.i64, "%.sroa.0.0.insert.insert"));
    try make_pair.end();
}

fn writeRuntimeFloatLessIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeRuntimeFloatLessStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write runtime float less external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeRuntimeFloatLessStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.alias("float_less", .{ .text = "i1 (float, float)" }, "@float_compare.float_less");
    try module.alias("float_mul", .{ .text = "double (double, double)" }, "@float_compare.float_mul");
    try writer.writeAll("\n");
    var main_fn = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var main_entry = try main_fn.block("entry");
    _ = try main_entry.fcmp("ok", "olt", .f32, sib.int(.f32, "1.000000e+00"), sib.int(.f32, "2.000000e+00"));
    _ = try main_entry.select("ret", sib.local(.i1, "%ok"), .i32, sib.int(.i32, "0"), sib.int(.i32, "1"));
    try main_entry.ret(sib.local(.i32, "%ret"));
    try main_fn.end();
    var less = try module.function("private ", .i1, "float_compare.float_less", "float %0, float %1", " unnamed_addr align 1");
    var less_entry = try less.block("entry");
    _ = try less_entry.fcmp("3", "olt", .f32, sib.local(.f32, "%0"), sib.local(.f32, "%1"));
    try less_entry.ret(sib.local(.i1, "%3"));
    try less.end();
    var mul = try module.function("private ", .f64, "float_compare.float_mul", "double %0, double %1", " unnamed_addr align 1");
    var mul_entry = try mul.block("entry");
    _ = try mul_entry.binary("3", "fmul", .f64, sib.local(.f64, "%0"), sib.local(.f64, "%1"));
    try mul_entry.ret(sib.local(.f64, "%3"));
    try mul.end();
}

fn writeRuntimeFloatMulIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writer.print(
        \\@float_mul = alias double (double, double), ptr @float_compare.float_mul
        \\@float_less = alias i1 (float, float), ptr @float_compare.float_less
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write runtime float multiply external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
    try writeRuntimeFloatBinaryCheckIrWriterBody(io, writer, ir_path, "mul", "fmul", "double", "3.000000e+00", "2.000000e+00", "6.000000e+00");
    writer.print(
        \\define private double @float_compare.float_mul(double %0, double %1) unnamed_addr align 1 {{
        \\entry:
        \\  %3 = fmul double %0, %1
        \\  ret double %3
        \\}}
        \\
        \\define private i1 @float_compare.float_less(float %0, float %1) unnamed_addr align 1 {{
        \\entry:
        \\  %3 = fcmp olt float %0, %1
        \\  ret i1 %3
        \\}}
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write runtime float multiply external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeRuntimeFloatAddIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writer.print(
        \\@float_add = alias float (float, float), ptr @floats_math.float_add
        \\@float_select = alias double (double, double, i1), ptr @floats_math.float_select
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write runtime float add external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
    try writeRuntimeFloatBinaryCheckIrWriterBody(io, writer, ir_path, "sum", "fadd", "float", "1.000000e+00", "2.000000e+00", "3.000000e+00");
    writer.print(
        \\define private float @floats_math.float_add(float %0, float %1) unnamed_addr align 1 {{
        \\entry:
        \\  %3 = fadd float %0, %1
        \\  ret float %3
        \\}}
        \\
        \\define private double @floats_math.float_select(double %0, double %1, i1 %2) unnamed_addr align 1 {{
        \\entry:
        \\  %3 = select i1 %2, double %0, double %1
        \\  ret double %3
        \\}}
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write runtime float add external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeRuntimeFloatSelectIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeRuntimeFloatSelectStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write runtime float select external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeRuntimeFloatSelectStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.alias("float_select", .{ .text = "double (double, double, i1)" }, "@floats_math.float_select");
    try module.alias("float_add", .{ .text = "float (float, float)" }, "@floats_math.float_add");
    try writer.writeAll("\n");
    var main_fn = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var main_entry = try main_fn.block("entry");
    _ = try main_entry.select("selected", sib.int(.i1, "true"), .f64, sib.int(.f64, "4.000000e+00"), sib.int(.f64, "5.000000e+00"));
    _ = try main_entry.fcmp("ok", "oeq", .f64, sib.local(.f64, "%selected"), sib.int(.f64, "4.000000e+00"));
    _ = try main_entry.select("ret", sib.local(.i1, "%ok"), .i32, sib.int(.i32, "0"), sib.int(.i32, "1"));
    try main_entry.ret(sib.local(.i32, "%ret"));
    try main_fn.end();
    var select_fn = try module.function("private ", .f64, "floats_math.float_select", "double %0, double %1, i1 %2", " unnamed_addr align 1");
    var select_entry = try select_fn.block("entry");
    _ = try select_entry.select("3", sib.local(.i1, "%2"), .f64, sib.local(.f64, "%0"), sib.local(.f64, "%1"));
    try select_entry.ret(sib.local(.f64, "%3"));
    try select_fn.end();
    var add_fn = try module.function("private ", .f32, "floats_math.float_add", "float %0, float %1", " unnamed_addr align 1");
    var add_entry = try add_fn.block("entry");
    _ = try add_entry.binary("3", "fadd", .f32, sib.local(.f32, "%0"), sib.local(.f32, "%1"));
    try add_entry.ret(sib.local(.f32, "%3"));
    try add_fn.end();
}

fn writeRuntimeFloatSubIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writer.print(
        \\@float_sub = alias float (float, float), ptr @fp_extended_ops.float_sub
        \\@double_div = alias double (double, double), ptr @fp_extended_ops.double_div
        \\@float_rem = alias float (float, float), ptr @fp_extended_ops.float_rem
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write runtime float subtract external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
    try writeRuntimeFloatBinaryCheckIrWriterBody(io, writer, ir_path, "diff", "fsub", "float", "5.000000e+00", "2.000000e+00", "3.000000e+00");
    writer.print(
        \\define private float @fp_extended_ops.float_sub(float %0, float %1) unnamed_addr align 1 {{
        \\entry:
        \\  %3 = fsub float %0, %1
        \\  ret float %3
        \\}}
        \\
        \\define private double @fp_extended_ops.double_div(double %0, double %1) unnamed_addr align 1 {{
        \\entry:
        \\  %3 = fdiv double %0, %1
        \\  ret double %3
        \\}}
        \\
        \\define private float @fp_extended_ops.float_rem(float %0, float %1) unnamed_addr align 1 {{
        \\entry:
        \\  %3 = frem float %0, %1
        \\  ret float %3
        \\}}
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write runtime float subtract external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeRuntimeFloatBinaryCheckIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
    result_name: []const u8,
    op: []const u8,
    ty: []const u8,
    lhs: []const u8,
    rhs: []const u8,
    expected: []const u8,
) !void {
    _ = io;
    _ = ir_path;
    const fp_ty: sib.Type = if (std.mem.eql(u8, ty, "double")) .f64 else .f32;
    var module = sib.Module.init(writer);
    var function = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var entry = try function.block("entry");
    _ = try entry.binary(result_name, op, fp_ty, sib.int(fp_ty, lhs), sib.int(fp_ty, rhs));
    _ = try entry.fcmpLocalName("ok", "oeq", fp_ty, result_name, sib.int(fp_ty, expected));
    _ = try entry.select("ret", sib.local(.i1, "%ok"), .i32, sib.int(.i32, "0"), sib.int(.i32, "1"));
    try entry.ret(sib.local(.i32, "%ret"));
    try function.end();
}

fn writeRuntimeDoubleDivIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeFpExtendedOpsAliases(writer, .double_div_first) catch |err| {
        try fatal(io, "failed to write runtime double divide external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
    try writeRuntimeFloatBinaryCheckIrWriterBody(io, writer, ir_path, "quot", "fdiv", "double", "6.000000e+00", "2.000000e+00", "3.000000e+00");
    writeFpExtendedOpsCallees(writer, .double_div_first) catch |err| {
        try fatal(io, "failed to write runtime double divide external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeRuntimeFloatRemIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeFpExtendedOpsAliases(writer, .float_rem_first) catch |err| {
        try fatal(io, "failed to write runtime float remainder external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
    try writeRuntimeFloatBinaryCheckIrWriterBody(io, writer, ir_path, "rem", "frem", "float", "5.500000e+00", "2.000000e+00", "1.500000e+00");
    writeFpExtendedOpsCallees(writer, .float_rem_first) catch |err| {
        try fatal(io, "failed to write runtime float remainder external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

const FpExtendedOrder = enum {
    double_div_first,
    float_rem_first,
};

fn writeFpExtendedOpsAliases(writer: *std.Io.Writer, order: FpExtendedOrder) !void {
    var module = sib.Module.init(writer);
    switch (order) {
        .double_div_first => {
            try module.alias("double_div", .{ .text = "double (double, double)" }, "@fp_extended_ops.double_div");
            try module.alias("float_sub", .{ .text = "float (float, float)" }, "@fp_extended_ops.float_sub");
            try module.alias("float_rem", .{ .text = "float (float, float)" }, "@fp_extended_ops.float_rem");
        },
        .float_rem_first => {
            try module.alias("float_rem", .{ .text = "float (float, float)" }, "@fp_extended_ops.float_rem");
            try module.alias("float_sub", .{ .text = "float (float, float)" }, "@fp_extended_ops.float_sub");
            try module.alias("double_div", .{ .text = "double (double, double)" }, "@fp_extended_ops.double_div");
        },
    }
    try writer.writeAll("\n");
}

fn writeFpExtendedOpsCallees(writer: *std.Io.Writer, order: FpExtendedOrder) !void {
    var module = sib.Module.init(writer);
    switch (order) {
        .double_div_first => {
            try writeFpExtendedDoubleDivCallee(&module);
            try writeFpExtendedFloatSubCallee(&module);
            try writeFpExtendedFloatRemCallee(&module);
        },
        .float_rem_first => {
            try writeFpExtendedFloatRemCallee(&module);
            try writeFpExtendedFloatSubCallee(&module);
            try writeFpExtendedDoubleDivCallee(&module);
        },
    }
}

fn writeFpExtendedFloatSubCallee(module: *sib.Module) !void {
    var function = try module.function("private ", .f32, "fp_extended_ops.float_sub", "float %0, float %1", " unnamed_addr align 1");
    var entry = try function.block("entry");
    _ = try entry.binary("3", "fsub", .f32, sib.local(.f32, "%0"), sib.local(.f32, "%1"));
    try entry.ret(sib.local(.f32, "%3"));
    try function.end();
}

fn writeFpExtendedDoubleDivCallee(module: *sib.Module) !void {
    var function = try module.function("private ", .f64, "fp_extended_ops.double_div", "double %0, double %1", " unnamed_addr align 1");
    var entry = try function.block("entry");
    _ = try entry.binary("3", "fdiv", .f64, sib.local(.f64, "%0"), sib.local(.f64, "%1"));
    try entry.ret(sib.local(.f64, "%3"));
    try function.end();
}

fn writeFpExtendedFloatRemCallee(module: *sib.Module) !void {
    var function = try module.function("private ", .f32, "fp_extended_ops.float_rem", "float %0, float %1", " unnamed_addr align 1");
    var entry = try function.block("entry");
    _ = try entry.binary("3", "frem", .f32, sib.local(.f32, "%0"), sib.local(.f32, "%1"));
    try entry.ret(sib.local(.f32, "%3"));
    try function.end();
}

fn writeI64ArithmeticIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeI64ArithmeticStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write i64 arithmetic external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeI64ArithmeticStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    var main_fn = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var entry = try main_fn.block("entry");
    _ = try entry.binary("wide", "add", .i64, sib.int(.i64, "2"), sib.int(.i64, "2"));
    _ = try entry.icmp("ok", "eq", .i64, sib.local(.i64, "%wide"), sib.int(.i64, "4"));
    _ = try entry.select("ret", sib.local(.i1, "%ok"), .i32, sib.int(.i32, "0"), sib.int(.i32, "1"));
    try entry.ret(sib.local(.i32, "%ret"));
    try main_fn.end();
}

fn writeRuntimeI64CallIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeRuntimeI64CallStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write runtime i64 call external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeRuntimeI64CallStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    var value_fn = try module.function("dso_local ", .i64, "i64_arithmetic.i64_value", "", " local_unnamed_addr");
    var value_entry = try value_fn.block("entry");
    try value_entry.ret(sib.int(.i64, "4"));
    try value_fn.end();
    var main_fn = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var entry = try main_fn.block("entry");
    _ = try entry.call("wide", "", .i64, "@i64_arithmetic.i64_value", "");
    _ = try entry.icmp("ok", "eq", .i64, sib.local(.i64, "%wide"), sib.int(.i64, "4"));
    _ = try entry.select("ret", sib.local(.i1, "%ok"), .i32, sib.int(.i32, "0"), sib.int(.i32, "1"));
    try entry.ret(sib.local(.i32, "%ret"));
    try main_fn.end();
}

fn writeBase64TableLookupIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeBase64TableLookupStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write base64 table lookup external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeBase64TableLookupStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.constant("base64.writer_table", "private unnamed_addr", .{ .text = "[4 x i8]" }, "c\"\\00\\04\\08\\0C\"", "4");
    try writer.writeAll("\n");
    var main_fn = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var entry = try main_fn.block("entry");
    _ = try entry.cast("idx8", "trunc", sib.int(.i32, "3"), .i8);
    _ = try entry.cast("idx", "zext", sib.local(.i8, "%idx8"), .i64);
    _ = try entry.gep2("ptr", .{ .text = "[4 x i8]" }, sib.global(.ptr, "@base64.writer_table"), sib.int(.i64, "0"), sib.local(.i64, "%idx"));
    _ = try entry.load("byte", .i8, sib.local(.ptr, "%ptr"), "1");
    _ = try entry.cast("value", "zext", sib.local(.i8, "%byte"), .i32);
    _ = try entry.icmp("ok", "eq", .i32, sib.local(.i32, "%value"), sib.int(.i32, "12"));
    _ = try entry.select("ret", sib.local(.i1, "%ok"), .i32, sib.int(.i32, "0"), sib.int(.i32, "1"));
    try entry.ret(sib.local(.i32, "%ret"));
    try main_fn.end();
}

fn writeCheckedAddRuntimeBoundaryIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeCheckedAddRuntimeBoundaryModule(writer) catch |err| {
        try fatal(io, "failed to write checked-add runtime boundary external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeCheckedAddRuntimeBoundaryModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.declare(.{ .text = "{ i32, i1 }" }, "llvm.sadd.with.overflow.i32", "i32, i32");
    try module.declare(.void, "llvm.assume", "i1 noundef");
    try writer.writeAll("\n");
    var function = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var entry = try function.block("entry");
    _ = try entry.checkedSAddI32("pair", sib.int(.i32, "40"), sib.int(.i32, "2"));
    try entry.panicEdge(sib.local(.i1, "%pair.overflow"), "ok", "panic");
    try writer.writeAll("\n");
    var ok = try function.block("ok");
    _ = try ok.icmp("matches", "eq", .i32, sib.local(.i32, "%pair.value"), sib.int(.i32, "42"));
    _ = try ok.select("ret", sib.local(.i1, "%matches"), .i32, sib.int(.i32, "0"), sib.int(.i32, "1"));
    try ok.ret(sib.local(.i32, "%ret"));
    try writer.writeAll("\n");
    try writeIntegerOverflowPanicBlockStructured(&function, "panic");
    try function.end();
    try writeIntegerOverflowPanicFunctionStructured(&module);
}

fn writeReleaseSafeRuntimeSideEffectFreeIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeReleaseSafeRuntimeSideEffectFreeStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSafe runtime side-effect-free external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeReleaseSafeRuntimeSideEffectFreeStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.alias("sideEffectFree", .{ .text = "void ()" }, "@tiny_scalar.sideEffectFree");
    try writer.writeAll("\n");
    var main_fn = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var main_entry = try main_fn.block("entry");
    _ = try main_entry.call(null, "", .void, "@tiny_scalar.sideEffectFree", "");
    try main_entry.ret(sib.int(.i32, "0"));
    try main_fn.end();
    var callee = try module.function("private ", .void, "tiny_scalar.sideEffectFree", "", " unnamed_addr align 1");
    var entry = try callee.block("entry");
    try entry.retVoid();
    try callee.end();
}

fn writeMinimalIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writer.print(
        \\define dso_local i32 @main() local_unnamed_addr {{
        \\entry:
        \\  ret i32 0
        \\}}
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write minimal external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn parseInputLimit(text: []const u8) !usize {
    const limit = try std.fmt.parseInt(usize, text, 10);
    if (limit == 0) return error.InvalidInputLimit;
    return limit;
}

fn shouldLowerCodegenFunction(module: ir.Module, function: ir.Function) bool {
    if (std.mem.eql(u8, function.name, "main.testOne")) return true;
    if (module.aliases.items.len == 0) return true;
    if (function.linkage != .private and function.linkage != .internal) return true;
    for (module.aliases.items) |alias| {
        if (std.mem.eql(u8, alias.target, function.name)) return true;
    }
    return false;
}

fn fatal(io: std.Io, comptime fmt: []const u8, args: anytype) noreturn {
    var stderr_buffer: [4096]u8 = undefined;
    var stderr_writer = std.Io.File.stderr().writer(io, &stderr_buffer);
    stderr_writer.interface.print(fmt, args) catch {};
    stderr_writer.interface.flush() catch {};
    std.process.exit(2);
}
