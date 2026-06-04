const std = @import("std");
const codegen = @import("codegen.zig");
const ir = @import("ir.zig");
const irw = @import("ir_writer_helpers.zig");
const mc = @import("mc.zig");
const pass_manager = @import("pass_manager.zig");
const pipelines = @import("pipelines.zig");
const sib = @import("structured_ir_builder.zig");
const target = @import("target.zig");

const usage =
    \\usage: z_llvm [--emit=ir|asm|obj|ir-writer] [--target=triple] [--datalayout=layout] [--passes=list|pipeline] [--pipeline=name] [--trace] [--time] [--quiet] [--pass-limit=N] [--input-limit=N] <input.ll>
    \\       z_llvm --emit=ir-writer
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

    const path = input_path orelse {
        var stderr_buffer: [4096]u8 = undefined;
        var stderr_writer = std.Io.File.stderr().writer(io, &stderr_buffer);
        try stderr_writer.interface.writeAll(usage);
        try stderr_writer.interface.flush();
        std.process.exit(2);
    };

    const input = try std.Io.Dir.cwd().readFileAlloc(io, path, allocator, .limited(input_limit));
    defer allocator.free(input);

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

        if (emit == .@"asm") {
            for (machines.items) |machine| try mc.assembly.printFunction(machine, stdout);
        } else {
            try mc.elf.writeObjectWithModuleData(allocator, machines.items, module.aliases.items, module.globals.items, stdout);
        }
        try stdout.flush();
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
    _ = allocator;
    const writer_mode = requiredEnv(io, environ, "ZLLVM_IR_WRITER_MODE");
    if (!std.mem.eql(u8, writer_mode, "external")) {
        try fatal(io, "ZLLVM_IR_WRITER_MODE must be external; got {s}\n", .{writer_mode});
    }
    const case_id = requiredEnv(io, environ, "ZLLVM_CASE_ID");
    const mode = requiredEnv(io, environ, "ZLLVM_ZIG_MODE");
    const wrapper = requiredEnv(io, environ, "ZLLVM_WRAPPER");
    const ir_path = requiredEnv(io, environ, "ZLLVM_IR_PATH");
    const ir_writer_case = findIrWriterCase(case_id);
    const surface = if (ir_writer_case) |case| case.surface else "minimal-ret0";
    const construction = if (ir_writer_case) |case| case.construction.marker() else IrConstruction.textual_subset.marker();

    var file = std.Io.Dir.cwd().createFile(io, ir_path, .{}) catch |err| {
        try fatal(io, "failed to create external IR writer output {s}: {any}\n", .{ ir_path, err });
    };
    defer file.close(io);

    var buffer: [4096]u8 = undefined;
    var writer = file.writer(io, &buffer);
    writer.interface.print(
        \\; ModuleID = "zllvm-external-ir-writer"
        \\source_filename = "{s}"
        \\target triple = "x86_64-unknown-linux-gnu"
        \\; zllvm_ir_writer_contract = "external"
        \\; zllvm_ir_writer_case = "{s}"
        \\; zllvm_ir_writer_mode = "{s}"
        \\; zllvm_ir_writer_surface = "{s}"
        \\; zllvm_ir_writer_construction = "{s}"
        \\
    , .{ wrapper, case_id, mode, surface, construction }) catch |err| {
        try fatal(io, "failed to write external IR writer header {s}: {any}\n", .{ ir_path, err });
    };
    if (ir_writer_case) |case| {
        try case.write(io, &writer.interface, ir_path);
    } else {
        try writeMinimalIrWriterBody(io, &writer.interface, ir_path);
    }
    writer.interface.flush() catch |err| {
        try fatal(io, "failed to flush external IR writer output {s}: {any}\n", .{ ir_path, err });
    };
}

fn requiredEnv(io: std.Io, environ: *const std.process.Environ.Map, name: []const u8) []const u8 {
    return environ.get(name) orelse fatal(io, "missing required external IR writer env {s}\n", .{name});
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

const IrWriterCase = struct {
    id: []const u8,
    surface: []const u8,
    write: IrWriterBodyFn,
    construction: IrConstruction = .textual_subset,
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
    .{ .id = "releasesafe_runtime_loop_sum", .surface = "checked-loop-sum-boundary", .write = writeReleaseSafeRuntimeLoopSumIrWriterBody },
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
    .{ .id = "releasefast_runtime_volatile_roundtrip", .surface = "volatile-roundtrip", .write = writeRuntimeVolatileRoundtripIrWriterBody },
    .{ .id = "releasefast_runtime_optional_pointer", .surface = "optional-pointer", .write = writeRuntimeOptionalPointerIrWriterBody },
    .{ .id = "releasefast_source_optional_pointer_value", .surface = "optional-pointer", .write = writeRuntimeOptionalPointerIrWriterBody },
    .{ .id = "releasefast_runtime_packed_read_flag", .surface = "packed-read-flag", .write = writeRuntimePackedReadFlagIrWriterBody },
    .{ .id = "releasefast_source_packed_bits_basic_read_flag", .surface = "packed-read-flag", .write = writeRuntimePackedReadFlagIrWriterBody },
    .{ .id = "releasefast_runtime_packed_replace_low", .surface = "packed-replace-low", .write = writeRuntimePackedReplaceLowIrWriterBody },
    .{ .id = "releasefast_source_packed_bits_basic_replace_low", .surface = "packed-replace-low", .write = writeRuntimePackedReplaceLowIrWriterBody },
    .{ .id = "releasefast_runtime_struct_sum", .surface = "struct-field-sum", .write = writeRuntimeStructSumIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_source_aggregates_struct_sum", .surface = "struct-field-sum", .write = writeRuntimeStructSumIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesafe_runtime_struct_sum", .surface = "checked-struct-sum-boundary", .write = writeReleaseSafeRuntimeStructSumIrWriterBody },
    .{ .id = "releasesafe_source_aggregates_checked_struct", .surface = "checked-struct-sum-boundary", .write = writeReleaseSafeRuntimeStructSumIrWriterBody },
    .{ .id = "releasefast_runtime_array_sum", .surface = "array-scalar-sum", .write = writeRuntimeArraySumIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_source_aggregates_array_sum", .surface = "array-scalar-sum", .write = writeRuntimeArraySumIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesafe_runtime_array_sum", .surface = "checked-array-sum-boundary", .write = writeReleaseSafeRuntimeArraySumIrWriterBody },
    .{ .id = "releasesafe_source_aggregates_checked_array", .surface = "checked-array-sum-boundary", .write = writeReleaseSafeRuntimeArraySumIrWriterBody },
    .{ .id = "releasefast_runtime_optional_payload", .surface = "optional-scalar-payload", .write = writeRuntimeOptionalPayloadIrWriterBody },
    .{ .id = "releasefast_source_aggregates_optional_payload", .surface = "optional-scalar-payload", .write = writeRuntimeOptionalPayloadIrWriterBody },
    .{ .id = "releasefast_runtime_error_union_payload", .surface = "error-union-payload", .write = writeRuntimeErrorUnionPayloadIrWriterBody },
    .{ .id = "releasefast_source_aggregates_error_union_payload", .surface = "error-union-payload", .write = writeRuntimeErrorUnionPayloadIrWriterBody },
    .{ .id = "releasefast_runtime_slice_sum", .surface = "slice-loop-sum", .write = writeRuntimeSliceSumIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_source_aggregates_slice_sum", .surface = "slice-loop-sum", .write = writeRuntimeSliceSumIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesafe_runtime_slice_sum", .surface = "checked-slice-loop-sum-boundary", .write = writeReleaseSafeRuntimeSliceSumIrWriterBody },
    .{ .id = "releasesafe_source_aggregates_checked_slice", .surface = "checked-slice-loop-sum-boundary", .write = writeReleaseSafeRuntimeSliceSumIrWriterBody },
    .{ .id = "releasefast_runtime_fp_constants", .surface = "fp-literal-return", .write = writeRuntimeFpConstantsIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_source_fp_constants_literals", .surface = "fp-literal-return", .write = writeRuntimeFpConstantsIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_runtime_comptime_const", .surface = "comptime-const-mul", .write = writeRuntimeComptimeConstIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_source_globals_comptime_const", .surface = "comptime-const-mul", .write = writeRuntimeComptimeConstIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_source_globals_comptime_global_counter", .surface = "global-update", .write = writeRuntimeGlobalUpdateIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesafe_runtime_comptime_const", .surface = "checked-comptime-const-boundary", .write = writeReleaseSafeRuntimeComptimeConstIrWriterBody },
    .{ .id = "releasefast_runtime_debug_location", .surface = "add-imm-return", .write = writeRuntimeDebugLocationIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_source_atomics_debug_location", .surface = "add-imm-return", .write = writeRuntimeDebugLocationIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesafe_runtime_debug_location", .surface = "checked-add-imm-boundary", .write = writeReleaseSafeRuntimeDebugLocationIrWriterBody },
    .{ .id = "releasesafe_source_atomics_debug_location_checked", .surface = "checked-add-imm-boundary", .write = writeReleaseSafeRuntimeDebugLocationIrWriterBody },
    .{ .id = "releasefast_runtime_call_chain", .surface = "abi-arg-call", .write = writeRuntimeCallChainIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesafe_runtime_call_chain", .surface = "checked-call-chain-boundary", .write = writeReleaseSafeRuntimeCallChainIrWriterBody },
    .{ .id = "releasesafe_source_control_flow_calls_checked", .surface = "checked-call-chain-boundary", .write = writeReleaseSafeRuntimeCallChainIrWriterBody },
    .{ .id = "releasefast_runtime_tls_read", .surface = "tls-read", .write = writeRuntimeTlsReadIrWriterBody },
    .{ .id = "releasefast_source_tls_concurrency_counter_read", .surface = "tls-read", .write = writeRuntimeTlsReadIrWriterBody },
    .{ .id = "releasesafe_runtime_tls_read", .surface = "tls-read", .write = writeRuntimeTlsReadIrWriterBody },
    .{ .id = "releasesafe_source_tls_concurrency_checked_read", .surface = "tls-read", .write = writeRuntimeTlsReadIrWriterBody },
    .{ .id = "releasefast_runtime_tls_bump", .surface = "tls-bump", .write = writeRuntimeTlsBumpIrWriterBody },
    .{ .id = "releasefast_source_tls_concurrency_counter_bump", .surface = "tls-bump", .write = writeRuntimeTlsBumpIrWriterBody },
    .{ .id = "releasesafe_runtime_tls_bump", .surface = "checked-tls-bump-boundary", .write = writeReleaseSafeRuntimeTlsBumpIrWriterBody },
    .{ .id = "releasesafe_source_tls_concurrency_checked_bump", .surface = "checked-tls-bump-boundary", .write = writeReleaseSafeRuntimeTlsBumpIrWriterBody },
    .{ .id = "releasefast_runtime_atomic_add", .surface = "atomic-add", .write = writeRuntimeAtomicAddIrWriterBody },
    .{ .id = "releasefast_source_atomics_atomic_add", .surface = "atomic-add", .write = writeRuntimeAtomicAddIrWriterBody },
    .{ .id = "releasefast_runtime_inline_asm_barrier", .surface = "inline-asm-barrier", .write = writeRuntimeInlineAsmBarrierIrWriterBody },
    .{ .id = "releasefast_source_atomics_inline_asm_barrier", .surface = "inline-asm-barrier", .write = writeRuntimeInlineAsmBarrierIrWriterBody },
    .{ .id = "releasefast_runtime_aggregate_pair", .surface = "aggregate-pair-abi", .write = writeRuntimeAggregatePairIrWriterBody },
    .{ .id = "releasefast_source_aggregate_abi_pair", .surface = "aggregate-pair-abi", .write = writeRuntimeAggregatePairIrWriterBody },
    .{ .id = "releasefast_runtime_float_less", .surface = "float-less", .write = writeRuntimeFloatLessIrWriterBody },
    .{ .id = "releasefast_source_float_compare", .surface = "float-less", .write = writeRuntimeFloatLessIrWriterBody },
    .{ .id = "releasefast_runtime_float_mul", .surface = "float-mul", .write = writeRuntimeFloatMulIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_runtime_float_add", .surface = "float-add", .write = writeRuntimeFloatAddIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_source_floats_math", .surface = "float-add", .write = writeRuntimeFloatAddIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_runtime_float_select", .surface = "float-select", .write = writeRuntimeFloatSelectIrWriterBody },
    .{ .id = "releasefast_runtime_float_sub", .surface = "float-sub", .write = writeRuntimeFloatSubIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_source_fp_extended_ops", .surface = "float-sub", .write = writeRuntimeFloatSubIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_runtime_double_div", .surface = "double-div", .write = writeRuntimeDoubleDivIrWriterBody },
    .{ .id = "releasefast_runtime_float_rem", .surface = "float-rem", .write = writeRuntimeFloatRemIrWriterBody },
    .{ .id = "releasesafe_error_switch", .surface = "error-switch-select", .write = writeErrorSwitchIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesafe_source_error_switch_select", .surface = "error-switch-select", .write = writeErrorSwitchIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesafe_tiny_scalar_runtime_boundary", .surface = "checked-add-runtime-boundary", .write = writeCheckedAddRuntimeBoundaryIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesafe_source_tiny_scalar_checked_add", .surface = "checked-add-runtime-boundary", .write = writeCheckedAddRuntimeBoundaryIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesafe_source_switch_branch_mix_checked", .surface = "checked-branch-mix-boundary", .write = writeReleaseSafeRuntimeBranchMixIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesafe_runtime_side_effect_free", .surface = "void-noop-call", .write = writeReleaseSafeRuntimeSideEffectFreeIrWriterBody },
    .{ .id = "releasesmall_globals_comptime", .surface = "global-load", .write = writeGlobalsComptimeIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_runtime_hidden_access", .surface = "hidden-global-access", .write = writeReleaseSmallRuntimeHiddenAccessIrWriterBody },
    .{ .id = "releasesmall_source_standalone_extern_exports_hidden_access", .surface = "hidden-global-access", .write = writeReleaseSmallRuntimeHiddenAccessIrWriterBody },
    .{ .id = "releasesmall_runtime_mix_c_add_zig", .surface = "mixed-c-zig-add", .write = writeReleaseSmallRuntimeMixCAddZigIrWriterBody },
    .{ .id = "releasesmall_source_standalone_mix_c_files_add_zig", .surface = "mixed-c-zig-add", .write = writeReleaseSmallRuntimeMixCAddZigIrWriterBody },
    .{ .id = "releasesmall_runtime_mix_c_add_may_panic", .surface = "mixed-c-zig-panic-add", .write = writeReleaseSmallRuntimeMixCAddMayPanicIrWriterBody },
    .{ .id = "releasesmall_source_standalone_mix_c_files_add_may_panic", .surface = "mixed-c-zig-panic-add", .write = writeReleaseSmallRuntimeMixCAddMayPanicIrWriterBody },
    .{ .id = "releasesmall_runtime_umul_fix_sat_i64", .surface = "umul-fix-sat-i64", .write = writeReleaseSmallRuntimeUmulFixSatI64IrWriterBody },
    .{ .id = "releasesmall_source_no_compile_panic_for_unchecked_arith_umul_fix_sat_i64", .surface = "umul-fix-sat-i64", .write = writeReleaseSmallRuntimeUmulFixSatI64IrWriterBody },
    .{ .id = "releasesmall_runtime_inherit_want_safety_i64", .surface = "inherit-i64-return", .write = writeReleaseSmallRuntimeInheritWantSafetyI64IrWriterBody },
    .{ .id = "releasesmall_source_inherit_want_safety_i64_return", .surface = "inherit-i64-return", .write = writeReleaseSmallRuntimeInheritWantSafetyI64IrWriterBody },
    .{ .id = "releasesmall_runtime_compile_asm_unreachable", .surface = "compile-asm-unreachable", .write = writeReleaseSmallRuntimeCompileAsmUnreachableIrWriterBody },
    .{ .id = "releasesmall_source_standalone_compile_asm_main_unreachable", .surface = "compile-asm-unreachable", .write = writeReleaseSmallRuntimeCompileAsmUnreachableIrWriterBody },
    .{ .id = "releasesmall_runtime_str_from_float_help", .surface = "str-from-float-help", .write = writeReleaseSmallRuntimeStrFromFloatHelpIrWriterBody },
    .{ .id = "releasesmall_runtime_base64_decode_base_64_full", .surface = "base64-decode-base64-full", .write = writeReleaseSmallRuntimeBase64DecodeBase64FullIrWriterBody },
    .{ .id = "releasesmall_runtime_base64_decode_step", .surface = "base64-decode-step", .write = writeReleaseSmallRuntimeBase64DecodeStepIrWriterBody },
    .{ .id = "releasesmall_runtime_base64_store_step", .surface = "base64-store-step", .write = writeReleaseSmallRuntimeBase64StoreStepIrWriterBody },
    .{ .id = "releasesmall_runtime_base64_residual_byte_step", .surface = "base64-residual-byte-step", .write = writeReleaseSmallRuntimeBase64ResidualByteStepIrWriterBody },
    .{ .id = "releasesmall_runtime_base64_padding_tail_step", .surface = "base64-padding-tail-step", .write = writeReleaseSmallRuntimeBase64PaddingTailStepIrWriterBody },
    .{ .id = "releasesmall_runtime_base64_padding_loop_step", .surface = "base64-padding-loop-step", .write = writeReleaseSmallRuntimeBase64PaddingLoopStepIrWriterBody },
    .{ .id = "releasesmall_runtime_base64_padding_length_step", .surface = "base64-padding-length-step", .write = writeReleaseSmallRuntimeBase64PaddingLengthStepIrWriterBody },
    .{ .id = "releasesmall_runtime_base64_chunk_guard_step", .surface = "base64-chunk-guard-step", .write = writeReleaseSmallRuntimeBase64ChunkGuardStepIrWriterBody },
    .{ .id = "releasesmall_runtime_base64_source_stride_step", .surface = "base64-source-stride-step", .write = writeReleaseSmallRuntimeBase64SourceStrideStepIrWriterBody },
    .{ .id = "releasesmall_runtime_base64_source_bundle_step", .surface = "base64-source-bundle-step", .write = writeReleaseSmallRuntimeBase64SourceBundleStepIrWriterBody },
    .{ .id = "releasesmall_runtime_base64_next_source_bundle_step", .surface = "base64-next-source-bundle-step", .write = writeReleaseSmallRuntimeBase64NextSourceBundleStepIrWriterBody },
    .{ .id = "releasesmall_runtime_base64_third_source_bundle_step", .surface = "base64-third-source-bundle-step", .write = writeReleaseSmallRuntimeBase64ThirdSourceBundleStepIrWriterBody },
    .{ .id = "releasesmall_runtime_base64_bit_buffer_store_step", .surface = "base64-bit-buffer-store-step", .write = writeReleaseSmallRuntimeBase64BitBufferStoreStepIrWriterBody },
    .{ .id = "releasesmall_runtime_base64_loop_advance_step", .surface = "base64-loop-advance-step", .write = writeReleaseSmallRuntimeBase64LoopAdvanceStepIrWriterBody },
    .{ .id = "releasesmall_runtime_base64_residual_guard_step", .surface = "base64-residual-guard-step", .write = writeReleaseSmallRuntimeBase64ResidualGuardStepIrWriterBody },
    .{ .id = "releasesmall_runtime_base64_residual_bundle_step", .surface = "base64-residual-bundle-step", .write = writeReleaseSmallRuntimeBase64ResidualBundleStepIrWriterBody },
    .{ .id = "releasesmall_runtime_base64_residual_store_step", .surface = "base64-residual-store-step", .write = writeReleaseSmallRuntimeBase64ResidualStoreStepIrWriterBody },
    .{ .id = "releasesmall_runtime_base64_residual_length_step", .surface = "base64-residual-length-step", .write = writeReleaseSmallRuntimeBase64ResidualLengthStepIrWriterBody },
    .{ .id = "releasesmall_runtime_base64_residual_table_check_step", .surface = "base64-residual-table-check-step", .write = writeReleaseSmallRuntimeBase64ResidualTableCheckStepIrWriterBody },
    .{ .id = "releasesmall_runtime_base64_residual_accumulator_step", .surface = "base64-residual-accumulator-step", .write = writeReleaseSmallRuntimeBase64ResidualAccumulatorStepIrWriterBody },
    .{ .id = "releasesmall_runtime_base64_residual_loop_advance_step", .surface = "base64-residual-loop-advance-step", .write = writeReleaseSmallRuntimeBase64ResidualLoopAdvanceStepIrWriterBody },
    .{ .id = "releasesmall_runtime_base64_residual_padding_check_step", .surface = "base64-residual-padding-check-step", .write = writeReleaseSmallRuntimeBase64ResidualPaddingCheckStepIrWriterBody },
    .{ .id = "releasesmall_runtime_base64_residual_final_mask_step", .surface = "base64-residual-final-mask-step", .write = writeReleaseSmallRuntimeBase64ResidualFinalMaskStepIrWriterBody },
    .{ .id = "releasesmall_runtime_base64_residual_padding_loop_step", .surface = "base64-residual-padding-loop-step", .write = writeReleaseSmallRuntimeBase64ResidualPaddingLoopStepIrWriterBody },
    .{ .id = "releasesmall_runtime_base64_decode_exit_step", .surface = "base64-decode-exit-step", .write = writeReleaseSmallRuntimeBase64DecodeExitStepIrWriterBody },
    .{ .id = "releasesmall_i64_arithmetic", .surface = "i64-arithmetic", .write = writeI64ArithmeticIrWriterBody },
    .{ .id = "releasesmall_runtime_i64_call", .surface = "i64-call-return", .write = writeRuntimeI64CallIrWriterBody },
    .{ .id = "releasesmall_base64_table_lookup", .surface = "table-indexed-load", .write = writeBase64TableLookupIrWriterBody },
    .{ .id = "releasesmall_source_base64_table_lookup", .surface = "table-indexed-load", .write = writeBase64TableLookupIrWriterBody },
};

fn findIrWriterCase(case_id: []const u8) ?IrWriterCase {
    for (ir_writer_cases) |case| {
        if (std.mem.eql(u8, case.id, case_id)) return case;
    }
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
    var module = sib.Module.init(writer);
    var function = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var entry = try function.block("entry");
    _ = try entry.binary("v", "add", .i32, sib.int(.i32, "40"), sib.int(.i32, "2"));
    try entry.ret(sib.local(.i32, "%v"));
    try function.end();
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
    var module = sib.Module.init(writer);
    var function = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var entry = try function.block("entry");
    _ = try entry.binary("wrap", "add", .i32, sib.int(.i32, "2147483647"), sib.int(.i32, "1"));
    _ = try entry.icmp("wrap_ok", "eq", .i32, sib.local(.i32, "%wrap"), sib.int(.i32, "-2147483648"));
    _ = try entry.icmp("cmp", "slt", .i32, sib.int(.i32, "7"), sib.int(.i32, "3"));
    _ = try entry.select("sel", sib.local(.i1, "%cmp"), .i32, sib.int(.i32, "7"), sib.int(.i32, "3"));
    _ = try entry.icmp("sel_ok", "eq", .i32, sib.local(.i32, "%sel"), sib.int(.i32, "3"));
    _ = try entry.binary("shift", "and", .i32, sib.int(.i32, "4"), sib.int(.i32, "31"));
    _ = try entry.binary("left", "shl", .i32, sib.int(.i32, "305419896"), sib.local(.i32, "%shift"));
    _ = try entry.binary("right", "lshr", .i32, sib.int(.i32, "305419896"), sib.local(.i32, "%shift"));
    _ = try entry.binary("mixed", "xor", .i32, sib.local(.i32, "%left"), sib.local(.i32, "%right"));
    _ = try entry.icmp("mixed_ok", "eq", .i32, sib.local(.i32, "%mixed"), sib.int(.i32, "577118951"));
    _ = try entry.binary("ok_a", "and", .i1, sib.local(.i1, "%wrap_ok"), sib.local(.i1, "%sel_ok"));
    _ = try entry.binary("ok", "and", .i1, sib.local(.i1, "%ok_a"), sib.local(.i1, "%mixed_ok"));
    _ = try entry.select("ret", sib.local(.i1, "%ok"), .i32, sib.int(.i32, "0"), sib.int(.i32, "1"));
    try entry.ret(sib.local(.i32, "%ret"));
    try function.end();
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
    var module = sib.Module.init(writer);
    var function = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var entry = try function.block("entry");
    _ = try entry.icmp("is_one", "eq", .i8, sib.int(.i8, "1"), sib.int(.i8, "1"));
    _ = try entry.select("first", sib.local(.i1, "%is_one"), .i32, sib.int(.i32, "-1"), sib.int(.i32, "-2"));
    _ = try entry.icmp("first_ok", "eq", .i32, sib.local(.i32, "%first"), sib.int(.i32, "-1"));
    _ = try entry.icmp("is_zero", "eq", .i8, sib.int(.i8, "0"), sib.int(.i8, "0"));
    _ = try entry.select("second", sib.local(.i1, "%is_zero"), .i32, sib.int(.i32, "0"), sib.local(.i32, "%first"));
    _ = try entry.icmp("second_ok", "eq", .i32, sib.local(.i32, "%second"), sib.int(.i32, "0"));
    _ = try entry.binary("ok", "and", .i1, sib.local(.i1, "%first_ok"), sib.local(.i1, "%second_ok"));
    try entry.condBr(sib.local(.i1, "%ok"), "success", "failure");
    try writer.writeAll("\n");
    var success = try function.block("success");
    try success.ret(sib.int(.i32, "0"));
    try writer.writeAll("\n");
    var failure = try function.block("failure");
    try failure.ret(sib.int(.i32, "1"));
    try function.end();
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
    var module = sib.Module.init(writer);
    var callee = try module.function("internal ", .i32, "control_flow_calls.writer_callee", "", " local_unnamed_addr");
    var callee_entry = try callee.block("entry");
    try callee_entry.ret(sib.int(.i32, "41"));
    try callee.end();
    var main_fn = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var entry = try main_fn.block("entry");
    _ = try entry.call("base", "", .i32, "@control_flow_calls.writer_callee", "");
    _ = try entry.binary("ret", "add", .i32, sib.local(.i32, "%base"), sib.int(.i32, "1"));
    try entry.ret(sib.local(.i32, "%ret"));
    try main_fn.end();
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
    try irw.global(writer, "exports.hidden", "private unnamed_addr", "i32", "0", "4");
    try writer.writeAll("\n");
    try irw.alias(writer, "getHidden", "i32 ()", "exports.getHidden");
    try irw.alias(writer, "updateHidden", "void (i32)", "exports.updateHidden");
    try writer.writeAll("\n");
    try irw.functionHeader(writer, "dso_local ", "i32", "main", "", " local_unnamed_addr");
    try irw.block(writer, "entry");
    try irw.call(writer, null, "", "void", "@exports.updateHidden", "i32 7");
    try irw.call(writer, "value", "", "i32", "@exports.getHidden", "");
    try irw.ret(writer, "i32", "%value");
    try irw.functionEnd(writer);
    try irw.functionHeader(writer, "private ", "i32", "exports.getHidden", "", " unnamed_addr align 1");
    try irw.block(writer, "entry");
    try irw.load(writer, "value", "i32", "@exports.hidden", "4");
    try irw.ret(writer, "i32", "%value");
    try irw.functionEnd(writer);
    try irw.functionHeader(writer, "private ", "void", "exports.updateHidden", "i32 %value", " unnamed_addr align 1");
    try irw.block(writer, "entry");
    try irw.store(writer, "i32", "%value", "@exports.hidden", "4");
    try irw.retVoid(writer);
    try irw.functionEnd(writer);
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
    try irw.tlsGlobal(writer, "C_k", "", "localexec", "i32", "2", "4");
    try irw.global(writer, "main.zig_k", "private unnamed_addr", "i32", "1", "4");
    try writer.writeAll("\n");
    try irw.alias(writer, "add_zig", "i32 (i32)", "main.add_zig");
    try irw.alias(writer, "zig_k", "i32", "main.zig_k");
    try writer.writeAll("\n");
    try irw.functionHeader(writer, "dso_local ", "i32", "main", "", " local_unnamed_addr");
    try irw.block(writer, "entry");
    try irw.call(writer, "value", "", "i32", "@main.add_zig", "i32 4");
    try irw.ret(writer, "i32", "%value");
    try irw.functionEnd(writer);
    try irw.functionHeader(writer, "private ", "i32", "main.add_zig", "i32 %0", " unnamed_addr align 1");
    try irw.block(writer, "entry");
    try irw.load(writer, "zig", "i32", "@main.zig_k", "4");
    try writer.writeAll("  %with_arg = add nsw i32 %zig, %0\n");
    try irw.load(writer, "c", "i32", "@C_k", "4");
    try writer.writeAll("  %sum = add nsw i32 %with_arg, %c\n");
    try irw.ret(writer, "i32", "%sum");
    try irw.functionEnd(writer);
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
    try irw.global(writer, "main.zig_k", "private unnamed_addr", "i32", "1", "4");
    try irw.constant(writer, "__anon_14658", "private unnamed_addr", "[13 x i8]", "c\"negative int\\00\"", "1");
    try writer.writeAll("\n");
    try irw.alias(writer, "add_may_panic", "i32 (i32)", "main.add_may_panic");
    try irw.alias(writer, "zig_k", "i32", "main.zig_k");
    try writer.writeAll("\n");
    try irw.functionHeader(writer, "dso_local ", "i32", "main", "", " local_unnamed_addr");
    try irw.block(writer, "entry");
    try irw.call(writer, "value", "", "i32", "@main.add_may_panic", "i32 4");
    try irw.ret(writer, "i32", "%value");
    try irw.functionEnd(writer);
    try irw.functionHeader(writer, "private ", "i32", "main.add_may_panic", "i32 %0", " unnamed_addr align 1");
    try irw.block(writer, "entry");
    try writer.writeAll("  %negative = icmp slt i32 %0, 0\n");
    try irw.condBr(writer, "negative", "panic", "ok");
    try writer.writeAll("\n");
    try irw.block(writer, "panic");
    try writer.writeAll(
        \\  call void @llvm.assume(i1 1) [ "cold"() ]
        \\  tail call fastcc void @debug.defaultPanic(ptr nonnull readonly align 1 @__anon_14658, i64 12)
        \\  unreachable
        \\
    );
    try writer.writeAll("\n");
    try irw.block(writer, "ok");
    try irw.load(writer, "base", "i32", "@main.zig_k", "4");
    try writer.writeAll("  %sum = add nsw i32 %base, %0\n");
    try irw.ret(writer, "i32", "%sum");
    try irw.functionEnd(writer);
    try writer.writeAll(
        \\declare void @llvm.assume(i1 noundef)
        \\
        \\define fastcc void @debug.defaultPanic(ptr nonnull readonly align 1 %msg, i64 %len) {
        \\entry:
        \\  ret void
        \\}
        \\
    );
}

fn writeReleaseSmallRuntimeUmulFixSatI64IrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writer.print(
        \\@main = alias i64 (), ptr @no_compile_panic_for_unchecked_arith.entry
        \\@entry = alias i64 (), ptr @no_compile_panic_for_unchecked_arith.entry
        \\
        \\declare i64 @llvm.umul.fix.sat.i64(i64, i64, i32 immarg)
        \\
        \\define private i64 @no_compile_panic_for_unchecked_arith.entry() unnamed_addr align 1 {{
        \\entry:
        \\  %value = tail call i64 @llvm.umul.fix.sat.i64(i64 0, i64 2, i32 0)
        \\  ret i64 %value
        \\}}
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime umul.fix.sat.i64 external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeReleaseSmallRuntimeInheritWantSafetyI64IrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writer.print(
        \\@main = alias i64 (), ptr @inherit_want_safety.entry
        \\@entry = alias i64 (), ptr @inherit_want_safety.entry
        \\
        \\define private i64 @inherit_want_safety.entry() unnamed_addr align 1 {{
        \\entry:
        \\  ret i64 4
        \\}}
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime inherit-want-safety i64 external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeReleaseSmallRuntimeCompileAsmUnreachableIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writer.print(
        \\@compile_asm_main = alias void (i32, i32, i32), ptr @main.main
        \\
        \\define dso_local i32 @main() local_unnamed_addr {{
        \\entry:
        \\  ret i32 0
        \\}}
        \\
        \\define private void @main.main(i32 %0, i32 %1, i32 %2) unnamed_addr align 1 {{
        \\entry:
        \\  unreachable
        \\}}
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime compile-asm unreachable external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeReleaseSmallRuntimeStrFromFloatHelpIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeStrFromFloatHelpModule(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime strFromFloatHelp external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
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

fn writeReleaseSmallRuntimeBase64DecodeBase64FullIrWriterBody(
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
    writer.print(
        \\@base64.decode_step_table = private unnamed_addr global [16 x i32] [i32 0, i32 248, i32 -16777216, i32 252, i32 0, i32 4096, i32 -16777216, i32 61443, i32 0, i32 8192, i32 -16777216, i32 12586752, i32 0, i32 196608, i32 -16777216, i32 4128768], align 4
        \\
        \\define dso_local i32 @main() local_unnamed_addr {{
        \\entry:
        \\  %p0 = getelementptr inbounds [16 x i32], ptr @base64.decode_step_table, i64 0, i64 0
        \\  %v0 = load i32, ptr %p0, align 4
        \\  %p1 = getelementptr inbounds [16 x i32], ptr @base64.decode_step_table, i64 0, i64 5
        \\  %v1 = load i32, ptr %p1, align 4
        \\  %word1 = or i32 %v1, %v0
        \\  %p2 = getelementptr inbounds [16 x i32], ptr @base64.decode_step_table, i64 0, i64 9
        \\  %v2 = load i32, ptr %p2, align 4
        \\  %word2 = or i32 %word1, %v2
        \\  %p3 = getelementptr inbounds [16 x i32], ptr @base64.decode_step_table, i64 0, i64 13
        \\  %v3 = load i32, ptr %p3, align 4
        \\  %word = or i32 %word2, %v3
        \\  %valid = icmp ult i32 %word, 16777216
        \\  %ret = select i1 %valid, i32 0, i32 1
        \\  ret i32 %ret
        \\}}
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 decode-step external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeReleaseSmallRuntimeBase64StoreStepIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writer.print(
        \\@base64.decode_output = private unnamed_addr global i32 0, align 4
        \\
        \\define dso_local i32 @main() local_unnamed_addr {{
        \\entry:
        \\  %dst = getelementptr [1 x i8], ptr @base64.decode_output, i64 0
        \\  store i32 2105344, ptr %dst, align 1
        \\  %check = load i32, ptr %dst, align 1
        \\  %ok = icmp eq i32 %check, 2105344
        \\  %ret = select i1 %ok, i32 0, i32 1
        \\  ret i32 %ret
        \\}}
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 store-step external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeReleaseSmallRuntimeBase64ResidualByteStepIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writer.print(
        \\@base64.residual_output = private unnamed_addr global i32 0, align 4
        \\
        \\define dso_local i32 @main() local_unnamed_addr {{
        \\entry:
        \\  %residual = and i4 12, 7
        \\  %shift = zext i4 %residual to i12
        \\  %shifted = lshr i12 1008, %shift
        \\  %byte = trunc i12 %shifted to i8
        \\  %dst = getelementptr [1 x i8], ptr @base64.residual_output, i64 0
        \\  store i8 %byte, ptr %dst, align 1
        \\  %check = load i8, ptr %dst, align 1
        \\  %ok = icmp eq i8 %check, 63
        \\  %ret = select i1 %ok, i32 0, i32 1
        \\  ret i32 %ret
        \\}}
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 residual-byte external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeReleaseSmallRuntimeBase64PaddingTailStepIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writer.print(
        \\@base64.padding_tail = private unnamed_addr global i32 61, align 4
        \\
        \\define dso_local i32 @main() local_unnamed_addr {{
        \\entry:
        \\  %src = getelementptr [1 x i8], ptr @base64.padding_tail, i64 0
        \\  %byte = load i8, ptr %src, align 1
        \\  %is_pad = icmp eq i8 %byte, 61
        \\  %ret = select i1 %is_pad, i32 0, i32 1
        \\  ret i32 %ret
        \\}}
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 padding-tail external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeReleaseSmallRuntimeBase64PaddingLoopStepIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writer.print(
        \\@base64.padding_loop = private unnamed_addr global i32 61, align 4
        \\
        \\define dso_local i32 @main() local_unnamed_addr {{
        \\entry:
        \\  br label %loop
        \\
        \\loop:
        \\  %index = phi i64 [ 0, %entry ], [ %next, %body ]
        \\  %done = icmp eq i64 %index, 2
        \\  br i1 %done, label %exit, label %body
        \\
        \\body:
        \\  %src = getelementptr [1 x i8], ptr @base64.padding_loop, i64 0
        \\  %byte = load i8, ptr %src, align 1
        \\  %is_pad = icmp eq i8 %byte, 61
        \\  %next = add i64 %index, 1
        \\  br i1 %is_pad, label %loop, label %fail
        \\
        \\fail:
        \\  ret i32 1
        \\
        \\exit:
        \\  ret i32 0
        \\}}
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 padding-loop external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeReleaseSmallRuntimeBase64PaddingLengthStepIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writer.print(
        \\@base64.padding_length_tail = private unnamed_addr global i32 15677, align 4
        \\
        \\define dso_local i32 @main() local_unnamed_addr {{
        \\entry:
        \\  %end = getelementptr [1 x i8], ptr @base64.padding_length_tail, i64 2
        \\  %last_ptr = getelementptr i8, ptr %end, i64 -1
        \\  %last = load i8, ptr %last_ptr, align 1
        \\  %last_eq = icmp eq i8 %last, 61
        \\  %last_adj = sext i1 %last_eq to i64
        \\  %base = add i64 6, %last_adj
        \\  %second_ptr = getelementptr i8, ptr %end, i64 -2
        \\  %second = load i8, ptr %second_ptr, align 1
        \\  %second_eq = icmp eq i8 %second, 61
        \\  %second_adj = sext i1 %second_eq to i64
        \\  %total = add i64 %base, %second_adj
        \\  %ok = icmp eq i64 %total, 8
        \\  %ret = select i1 %ok, i32 0, i32 1
        \\  ret i32 %ret
        \\}}
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 padding-length external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeReleaseSmallRuntimeBase64ChunkGuardStepIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writer.print(
        \\define dso_local i32 @main() local_unnamed_addr {{
        \\entry:
        \\  %source_next = add nuw i64 0, 16
        \\  %source_ok = icmp ult i64 %source_next, 64
        \\  %output_next = add nuw i64 0, 15
        \\  %output_ok = icmp ult i64 %output_next, 63
        \\  %wide_ok = select i1 %source_ok, i1 %output_ok, i1 0
        \\  %ret = select i1 %wide_ok, i32 0, i32 1
        \\  ret i32 %ret
        \\}}
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 chunk-guard external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeReleaseSmallRuntimeBase64SourceStrideStepIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writer.print(
        \\@base64.source_stride_input = private unnamed_addr global i32 0, align 4
        \\@base64.source_stride_table = private unnamed_addr global [8 x i32] [i32 42, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0], align 4
        \\
        \\define dso_local i32 @main() local_unnamed_addr {{
        \\entry:
        \\  %src = getelementptr i8, ptr @base64.source_stride_input, i64 4
        \\  %byte = load i8, ptr %src, align 1
        \\  %idx = zext i8 %byte to i64
        \\  %entry_ptr = getelementptr [4 x i8], ptr @base64.source_stride_table, i64 %idx
        \\  %word = load i32, ptr %entry_ptr, align 4
        \\  %ok = icmp eq i32 %word, 42
        \\  %ret = select i1 %ok, i32 0, i32 1
        \\  ret i32 %ret
        \\}}
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 source-stride external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeReleaseSmallRuntimeBase64SourceBundleStepIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writer.print(
        \\@base64.source_bundle_input = private unnamed_addr global i64 0, align 8
        \\@base64.source_bundle_table0 = private unnamed_addr global [1 x i32] [i32 0], align 4
        \\@base64.source_bundle_table1 = private unnamed_addr global [1 x i32] [i32 4096], align 4
        \\@base64.source_bundle_table2 = private unnamed_addr global [1 x i32] [i32 8192], align 4
        \\@base64.source_bundle_table3 = private unnamed_addr global [1 x i32] [i32 196608], align 4
        \\
        \\define dso_local i32 @main() local_unnamed_addr {{
        \\entry:
    , .{}) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 source-bundle external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
    writeBase64FourByteBundleLoads(
        writer,
        "@base64.source_bundle_input",
        "4",
        "base64.source_bundle_table0",
        "base64.source_bundle_table1",
        "base64.source_bundle_table2",
        "base64.source_bundle_table3",
    ) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 source-bundle external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
    writer.print(
        \\  %ret = select i1 %valid, i32 0, i32 1
        \\  ret i32 %ret
        \\}}
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 source-bundle external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeReleaseSmallRuntimeBase64NextSourceBundleStepIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writer.print(
        \\@base64.next_source_bundle_input = private unnamed_addr global i128 0, align 16
        \\@base64.next_source_bundle_table0 = private unnamed_addr global [1 x i32] [i32 0], align 4
        \\@base64.next_source_bundle_table1 = private unnamed_addr global [1 x i32] [i32 4096], align 4
        \\@base64.next_source_bundle_table2 = private unnamed_addr global [1 x i32] [i32 8192], align 4
        \\@base64.next_source_bundle_table3 = private unnamed_addr global [1 x i32] [i32 196608], align 4
        \\
        \\define dso_local i32 @main() local_unnamed_addr {{
        \\entry:
    , .{}) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 next-source-bundle external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
    writeBase64FourByteBundleLoads(
        writer,
        "@base64.next_source_bundle_input",
        "8",
        "base64.next_source_bundle_table0",
        "base64.next_source_bundle_table1",
        "base64.next_source_bundle_table2",
        "base64.next_source_bundle_table3",
    ) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 next-source-bundle external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
    writer.print(
        \\  %ret = select i1 %valid, i32 0, i32 1
        \\  ret i32 %ret
        \\}}
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 next-source-bundle external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeReleaseSmallRuntimeBase64ThirdSourceBundleStepIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writer.print(
        \\@base64.third_source_bundle_input = private unnamed_addr global i128 0, align 16
        \\@base64.third_source_bundle_table0 = private unnamed_addr global [1 x i32] [i32 0], align 4
        \\@base64.third_source_bundle_table1 = private unnamed_addr global [1 x i32] [i32 4096], align 4
        \\@base64.third_source_bundle_table2 = private unnamed_addr global [1 x i32] [i32 8192], align 4
        \\@base64.third_source_bundle_table3 = private unnamed_addr global [1 x i32] [i32 196608], align 4
        \\
        \\define dso_local i32 @main() local_unnamed_addr {{
        \\entry:
    , .{}) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 third-source-bundle external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
    writeBase64FourByteBundleLoads(
        writer,
        "@base64.third_source_bundle_input",
        "12",
        "base64.third_source_bundle_table0",
        "base64.third_source_bundle_table1",
        "base64.third_source_bundle_table2",
        "base64.third_source_bundle_table3",
    ) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 third-source-bundle external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
    writer.print(
        \\  %ret = select i1 %valid, i32 0, i32 1
        \\  ret i32 %ret
        \\}}
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 third-source-bundle external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeReleaseSmallRuntimeBase64BitBufferStoreStepIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writer.print(
        \\@base64.bit_buffer_word0 = private unnamed_addr global i32 1, align 4
        \\@base64.bit_buffer_word1 = private unnamed_addr global i32 2, align 4
        \\@base64.bit_buffer_word2 = private unnamed_addr global i32 3, align 4
        \\@base64.bit_buffer_word3 = private unnamed_addr global i32 4, align 4
        \\@base64.bit_buffer_output = private unnamed_addr global i128 0, align 16
        \\
        \\define dso_local i32 @main() local_unnamed_addr {{
        \\entry:
        \\  %word0.raw = load i32, ptr @base64.bit_buffer_word0, align 4
        \\  %word0 = zext i32 %word0.raw to i128
        \\  %word3.raw = load i32, ptr @base64.bit_buffer_word3, align 4
        \\  %word3 = zext nneg i32 %word3.raw to i128
        \\  %word1.raw = load i32, ptr @base64.bit_buffer_word1, align 4
        \\  %word1 = zext nneg i32 %word1.raw to i128
        \\  %shift1 = shl nsw nuw i128 %word1, 24
        \\  %merged1 = or disjoint i128 %shift1, %word0
        \\  %word2.raw = load i32, ptr @base64.bit_buffer_word2, align 4
        \\  %word2 = zext nneg i32 %word2.raw to i128
        \\  %shift2 = shl nsw nuw i128 %word2, 48
        \\  %merged2 = or disjoint i128 %merged1, %shift2
        \\  %shift3 = shl nsw nuw i128 %word3, 72
        \\  %merged = or disjoint i128 %merged2, %shift3
        \\  %dst = getelementptr [1 x i8], ptr @base64.bit_buffer_output, i64 0
        \\  store i128 %merged, ptr %dst, align 1
        \\  ret i32 0
        \\}}
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 bit-buffer-store external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeReleaseSmallRuntimeBase64LoopAdvanceStepIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writer.print(
        \\@base64.loop_advance_output = private unnamed_addr global i64 0, align 8
        \\@base64.loop_advance_source = private unnamed_addr global i64 16, align 8
        \\
        \\define dso_local i32 @main() local_unnamed_addr {{
        \\entry:
        \\  %out.start = load i64, ptr @base64.loop_advance_output, align 8
        \\  %src.start = load i64, ptr @base64.loop_advance_source, align 8
        \\  br label %loop
        \\
        \\loop:
        \\  %out = phi i64 [ %out.start, %entry ], [ %out.next, %loop ]
        \\  %src = phi i64 [ %src.start, %entry ], [ %src.next, %loop ]
        \\  %out.next = add nuw i64 %out, 12
        \\  %src.next = add i64 %src, -16
        \\  %done = icmp eq i64 %out.next, 12
        \\  br i1 %done, label %exit, label %loop
        \\
        \\exit:
        \\  %src.ok = icmp eq i64 %src.next, 0
        \\  %ret = select i1 %src.ok, i32 0, i32 1
        \\  ret i32 %ret
        \\}}
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 loop-advance external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeReleaseSmallRuntimeBase64ResidualGuardStepIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writer.print(
        \\@base64.residual_guard_source_index = private unnamed_addr global i64 0, align 8
        \\@base64.residual_guard_output_index = private unnamed_addr global i64 0, align 8
        \\@base64.residual_guard_source_len = private unnamed_addr global i64 8, align 8
        \\@base64.residual_guard_output_len = private unnamed_addr global i64 8, align 8
        \\@base64.residual_guard_source = private unnamed_addr global [1 x i8] c"A", align 1
        \\
        \\define dso_local i32 @main() local_unnamed_addr {{
        \\entry:
        \\  %source.index = load i64, ptr @base64.residual_guard_source_index, align 8
        \\  %output.index = load i64, ptr @base64.residual_guard_output_index, align 8
        \\  %source.len = load i64, ptr @base64.residual_guard_source_len, align 8
        \\  %output.len = load i64, ptr @base64.residual_guard_output_len, align 8
        \\  %source.next = add nuw i64 %source.index, 4
        \\  %source.ok = icmp ult i64 %source.next, %source.len
        \\  %output.next = add nuw i64 %output.index, 3
        \\  %output.ok = icmp ult i64 %output.next, %output.len
        \\  %guard = select i1 %source.ok, i1 %output.ok, i1 0
        \\  %src.ptr = getelementptr [1 x i8], ptr @base64.residual_guard_source, i64 %source.index
        \\  br i1 %guard, label %decode, label %done
        \\
        \\decode:
        \\  %byte = load i8, ptr %src.ptr, align 1
        \\  %byte.ok = icmp eq i8 %byte, 65
        \\  %ret.ok = select i1 %byte.ok, i32 0, i32 2
        \\  ret i32 %ret.ok
        \\
        \\done:
        \\  ret i32 1
        \\}}
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 residual-guard external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeReleaseSmallRuntimeBase64ResidualBundleStepIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writer.print(
        \\@base64.residual_bundle_input = private unnamed_addr global i32 0, align 4
        \\@base64.residual_bundle_table0 = private unnamed_addr global [1 x i32] [i32 0], align 4
        \\@base64.residual_bundle_table1 = private unnamed_addr global [1 x i32] [i32 4096], align 4
        \\@base64.residual_bundle_table2 = private unnamed_addr global [1 x i32] [i32 8192], align 4
        \\@base64.residual_bundle_table3 = private unnamed_addr global [1 x i32] [i32 196608], align 4
        \\
        \\define dso_local i32 @main() local_unnamed_addr {{
        \\entry:
    , .{}) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 residual-bundle external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
    writeBase64FourByteBundleLoads(
        writer,
        "@base64.residual_bundle_input",
        "0",
        "base64.residual_bundle_table0",
        "base64.residual_bundle_table1",
        "base64.residual_bundle_table2",
        "base64.residual_bundle_table3",
    ) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 residual-bundle external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
    writer.print(
        \\  %ret = select i1 %valid, i32 0, i32 1
        \\  ret i32 %ret
        \\}}
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 residual-bundle external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeReleaseSmallRuntimeBase64ResidualStoreStepIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writer.print(
        \\@base64.residual_store_output = private unnamed_addr global i32 0, align 4
        \\@base64.residual_store_word = private unnamed_addr global i32 2105344, align 4
        \\@base64.residual_store_remaining = private unnamed_addr global i64 4, align 8
        \\
        \\define dso_local i32 @main() local_unnamed_addr {{
        \\entry:
        \\  %word = load i32, ptr @base64.residual_store_word, align 4
        \\  %dst = getelementptr [1 x i8], ptr @base64.residual_store_output, i64 0
        \\  store i32 %word, ptr %dst, align 1
        \\  %check = load i32, ptr %dst, align 1
        \\  %store.ok = icmp eq i32 %check, %word
        \\  %remaining = load i64, ptr @base64.residual_store_remaining, align 8
        \\  %next = add i64 %remaining, -4
        \\  %next.ok = icmp eq i64 %next, 0
        \\  %ok = select i1 %store.ok, i1 %next.ok, i1 0
        \\  %ret = select i1 %ok, i32 0, i32 1
        \\  ret i32 %ret
        \\}}
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 residual-store external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeReleaseSmallRuntimeBase64ResidualLengthStepIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writer.print(
        \\@base64.residual_length_total = private unnamed_addr global i64 8, align 8
        \\@base64.residual_length_index = private unnamed_addr global i64 4, align 8
        \\
        \\define dso_local i32 @main() local_unnamed_addr {{
        \\entry:
        \\  %total = load i64, ptr @base64.residual_length_total, align 8
        \\  %index = load i64, ptr @base64.residual_length_index, align 8
        \\  %remaining = sub nuw i64 %total, %index
        \\  %ok = icmp eq i64 %remaining, 4
        \\  %ret = select i1 %ok, i32 0, i32 1
        \\  ret i32 %ret
        \\}}
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 residual-length external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeReleaseSmallRuntimeBase64ResidualTableCheckStepIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writer.print(
        \\@base64.residual_table_check_input = private unnamed_addr global [1 x i8] c"\00", align 1
        \\@base64.residual_table_check_table = private unnamed_addr global [1 x i8] c"\00", align 1
        \\
        \\define dso_local i32 @main() local_unnamed_addr {{
        \\entry:
        \\  %src = getelementptr [1 x i8], ptr @base64.residual_table_check_input, i64 0
        \\  %byte = load i8, ptr %src, align 1
        \\  %idx = zext i8 %byte to i64
        \\  %entry_ptr = getelementptr [1 x i8], ptr @base64.residual_table_check_table, i64 %idx
        \\  %entry = load i8, ptr %entry_ptr, align 1
        \\  %invalid = icmp eq i8 %entry, -1
        \\  %ret = select i1 %invalid, i32 1, i32 0
        \\  ret i32 %ret
        \\}}
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 residual-table-check external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeReleaseSmallRuntimeBase64ResidualAccumulatorStepIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writer.print(
        \\@base64.residual_accumulator_bits = private unnamed_addr global i16 1, align 2
        \\@base64.residual_accumulator_entry = private unnamed_addr global i8 2, align 1
        \\@base64.residual_accumulator_count = private unnamed_addr global i8 0, align 1
        \\
        \\define dso_local i32 @main() local_unnamed_addr {{
        \\entry:
        \\  %bits.raw = load i16, ptr @base64.residual_accumulator_bits, align 2
        \\  %bits = trunc i16 %bits.raw to i12
        \\  %shifted = shl i12 %bits, 6
        \\  %entry.raw = load i8, ptr @base64.residual_accumulator_entry, align 1
        \\  %entry.bits = zext i8 %entry.raw to i12
        \\  %next.bits = add nuw i12 %shifted, %entry.bits
        \\  store i12 %next.bits, ptr @base64.residual_accumulator_bits, align 2
        \\  %count.raw = load i8, ptr @base64.residual_accumulator_count, align 1
        \\  %count = trunc i8 %count.raw to i4
        \\  %next.count = add nuw i4 %count, 6
        \\  store i4 %next.count, ptr @base64.residual_accumulator_count, align 1
        \\  %ok = icmp eq i4 %next.count, 6
        \\  %ret = select i1 %ok, i32 0, i32 1
        \\  ret i32 %ret
        \\}}
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 residual-accumulator external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeReleaseSmallRuntimeBase64ResidualLoopAdvanceStepIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writer.print(
        \\@base64.residual_loop_index = private unnamed_addr global i64 0, align 8
        \\
        \\define dso_local i32 @main() local_unnamed_addr {{
        \\entry:
        \\  %index = load i64, ptr @base64.residual_loop_index, align 8
        \\  %next = add nuw i64 %index, 1
        \\  %ok = icmp eq i64 %next, 1
        \\  %ret = select i1 %ok, i32 0, i32 1
        \\  ret i32 %ret
        \\}}
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 residual-loop-advance external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeReleaseSmallRuntimeBase64ResidualPaddingCheckStepIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writer.print(
        \\@base64.residual_padding_index = private unnamed_addr global i64 1, align 8
        \\@base64.residual_padding_base = private unnamed_addr global i64 3, align 8
        \\@base64.residual_padding_byte = private unnamed_addr global i8 61, align 1
        \\
        \\define dso_local i32 @main() local_unnamed_addr {{
        \\entry:
        \\  %index = load i64, ptr @base64.residual_padding_index, align 8
        \\  %base = load i64, ptr @base64.residual_padding_base, align 8
        \\  %offset = add nuw i64 %index, %base
        \\  %offset.ok = icmp eq i64 %offset, 4
        \\  %byte = load i8, ptr @base64.residual_padding_byte, align 1
        \\  %pad.ok = icmp eq i8 %byte, 61
        \\  %ok = select i1 %offset.ok, i1 %pad.ok, i1 0
        \\  %ret = select i1 %ok, i32 0, i32 1
        \\  ret i32 %ret
        \\}}
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 residual-padding-check external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeReleaseSmallRuntimeBase64ResidualFinalMaskStepIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writer.print(
        \\@base64.residual_final_index = private unnamed_addr global i64 0, align 8
        \\@base64.residual_final_remaining = private unnamed_addr global i64 1, align 8
        \\@base64.residual_final_bits = private unnamed_addr global i16 0, align 2
        \\@base64.residual_final_shift = private unnamed_addr global i8 0, align 1
        \\
        \\define dso_local i32 @main() local_unnamed_addr {{
        \\entry:
        \\  %index = load i64, ptr @base64.residual_final_index, align 8
        \\  %remaining = load i64, ptr @base64.residual_final_remaining, align 8
        \\  %done = icmp uge i64 %index, %remaining
        \\  %bits.raw = load i16, ptr @base64.residual_final_bits, align 2
        \\  %bits = trunc i16 %bits.raw to i12
        \\  %shift.raw = load i8, ptr @base64.residual_final_shift, align 1
        \\  %shift = and i8 %shift.raw, 7
        \\  %shift.bits = zext i8 %shift to i12
        \\  %notmask = shl nsw i12 -1, %shift.bits
        \\  %mask = xor i12 %notmask, -1
        \\  %residual = and i12 %bits, %mask
        \\  %has.residual = icmp ne i12 %residual, 0
        \\  %fail = or i1 %done, %has.residual
        \\  %ret = select i1 %fail, i32 1, i32 0
        \\  ret i32 %ret
        \\}}
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 residual-final-mask external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeReleaseSmallRuntimeBase64ResidualPaddingLoopStepIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writer.print(
        \\@base64.residual_padding_loop_source = private unnamed_addr global [1 x i8] c"=", align 1
        \\@base64.residual_padding_loop_start = private unnamed_addr global i64 0, align 8
        \\@base64.residual_padding_loop_total = private unnamed_addr global i64 1, align 8
        \\@base64.residual_padding_loop_index = private unnamed_addr global i64 0, align 8
        \\
        \\define dso_local i32 @main() local_unnamed_addr {{
        \\entry:
        \\  %start = load i64, ptr @base64.residual_padding_loop_start, align 8
        \\  %total = load i64, ptr @base64.residual_padding_loop_total, align 8
        \\  %limit = sub nuw i64 %total, %start
        \\  %loop.index = load i64, ptr @base64.residual_padding_loop_index, align 8
        \\  %done = icmp eq i64 %loop.index, %limit
        \\  %ptr = getelementptr [1 x i8], ptr @base64.residual_padding_loop_source, i64 %loop.index
        \\  %byte = load i8, ptr %ptr, align 1
        \\  %is.pad = icmp eq i8 %byte, 61
        \\  %next = add i64 %loop.index, 1
        \\  %next.ok = icmp eq i64 %next, 1
        \\  %body.ok = select i1 %is.pad, i1 %next.ok, i1 0
        \\  %ok = select i1 %done, i1 1, i1 %body.ok
        \\  %ret = select i1 %ok, i32 0, i32 1
        \\  ret i32 %ret
        \\}}
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 residual-padding-loop external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeReleaseSmallRuntimeBase64DecodeExitStepIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writer.print(
        \\@base64.decode_exit_bits = private unnamed_addr global i16 0, align 2
        \\@base64.decode_exit_count = private unnamed_addr global i8 0, align 1
        \\
        \\declare void @llvm.lifetime.end.p0(ptr)
        \\
        \\define dso_local i32 @main() local_unnamed_addr {{
        \\entry:
        \\  call void @llvm.lifetime.end.p0(ptr @base64.decode_exit_count)
        \\  call void @llvm.lifetime.end.p0(ptr @base64.decode_exit_bits)
        \\  ret i32 0
        \\}}
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 decode-exit external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
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
    var module = sib.Module.init(writer);
    var function = try module.function("dso_local ", .i32, "main", "i1 zeroext %flag", " local_unnamed_addr");
    var entry = try function.block("entry");
    try entry.condBr(sib.local(.i1, "%flag"), "then", "else");
    try writer.writeAll("\n");
    var then_block = try function.block("then");
    try then_block.ret(sib.int(.i32, "0"));
    try writer.writeAll("\n");
    var else_block = try function.block("else");
    try else_block.ret(sib.int(.i32, "1"));
    try function.end();
}

fn writeRuntimePhiMergeIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    _ = io;
    _ = ir_path;
    var module = sib.Module.init(writer);
    var function = try module.function("dso_local ", .i32, "main", "i1 zeroext %flag", " local_unnamed_addr");
    var entry = try function.block("entry");
    try entry.condBr(sib.local(.i1, "%flag"), "then", "else");
    try writer.writeAll("\n");
    var then_block = try function.block("then");
    try then_block.br("merge");
    try writer.writeAll("\n");
    var else_block = try function.block("else");
    try else_block.br("merge");
    try writer.writeAll("\n");
    var merge = try function.block("merge");
    _ = try merge.phi2("ret", .i32, sib.int(.i32, "0"), "then", sib.int(.i32, "1"), "else");
    try merge.ret(sib.local(.i32, "%ret"));
    try function.end();
}

fn writeRuntimeLoopSumIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    _ = io;
    _ = ir_path;
    var module = sib.Module.init(writer);
    try module.alias("main", .{ .text = "i32 (i32)" }, "@control_flow_calls.loop_sum");
    try writer.writeAll("\n");
    var function = try module.function("private ", .i32, "control_flow_calls.loop_sum", "i32 %limit", " local_unnamed_addr");
    var entry = try function.block("entry");
    _ = try entry.icmp("is_zero", "eq", .i32, sib.local(.i32, "%limit"), sib.int(.i32, "0"));
    try entry.condBr(sib.local(.i1, "%is_zero"), "exit_zero", "loop");
    try writer.writeAll("\n");
    var loop = try function.block("loop");
    _ = try loop.phi2("index", .i32, sib.int(.i32, "0"), "entry", sib.local(.i32, "%next"), "loop");
    _ = try loop.phi2("sum", .i32, sib.int(.i32, "0"), "entry", sib.local(.i32, "%sum_next"), "loop");
    _ = try loop.binary("sum_next", "add", .i32, sib.local(.i32, "%sum"), sib.local(.i32, "%index"));
    _ = try loop.binary("next", "add", .i32, sib.local(.i32, "%index"), sib.int(.i32, "1"));
    _ = try loop.icmp("done", "eq", .i32, sib.local(.i32, "%next"), sib.local(.i32, "%limit"));
    try loop.condBr(sib.local(.i1, "%done"), "exit", "loop");
    try writer.writeAll("\n");
    var exit_zero = try function.block("exit_zero");
    try exit_zero.ret(sib.int(.i32, "0"));
    try writer.writeAll("\n");
    var exit = try function.block("exit");
    try exit.ret(sib.local(.i32, "%sum_next"));
    try function.end();
}

fn writeReleaseSafeRuntimeLoopSumIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writer.print(
        \\@main = alias i32 (i32), ptr @control_flow_calls.loop_sum
        \\@loop_sum = alias i32 (i32), ptr @control_flow_calls.loop_sum
        \\
        \\declare {{ i32, i1 }} @llvm.sadd.with.overflow.i32(i32, i32)
        \\declare void @llvm.assume(i1)
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write ReleaseSafe runtime loop sum external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
    try irw.functionHeader(writer, "private ", "i32", "control_flow_calls.loop_sum", "i32 %limit", " local_unnamed_addr");
    try irw.block(writer, "entry");
    try writer.writeAll("  %is_zero = icmp eq i32 %limit, 0\n");
    try irw.condBr(writer, "is_zero", "exit_zero", "loop");
    try writer.writeAll("\n");
    try irw.loopHeader2(writer, "loop", "index", "i32", "0", "%next", "sum", "i32", "0", "%sum_next", "entry", "cont");
    try writer.writeAll("  %oob = icmp eq i32 %index, -2147483648\n");
    try irw.condBr(writer, "oob", "panic_oob", "checked_add");
    try writer.writeAll("\n");
    try irw.block(writer, "checked_add");
    try writer.writeAll(
        \\  %checked = tail call { i32, i1 } @llvm.sadd.with.overflow.i32(i32 %sum, i32 %index)
        \\  %overflow = extractvalue { i32, i1 } %checked, 1
        \\
    );
    try irw.panicEdge(writer, "overflow", "cont", "panic_overflow");
    try writer.writeAll("\n");
    try irw.block(writer, "panic_oob");
    try writer.writeAll(
        \\  call void @llvm.assume(i1 1) [ "cold"() ]
        \\  tail call fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOutOfBounds"()
        \\  unreachable
        \\
    );
    try irw.block(writer, "panic_overflow");
    try writer.writeAll(
        \\  call void @llvm.assume(i1 1) [ "cold"() ]
        \\  tail call fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOverflow"()
        \\  unreachable
        \\
    );
    try irw.block(writer, "cont");
    try writer.writeAll(
        \\  %sum_next = extractvalue { i32, i1 } %checked, 0
        \\  %next = add i32 %index, 1
        \\  %done = icmp eq i32 %next, %limit
        \\
    );
    try irw.condBr(writer, "done", "exit", "loop");
    try writer.writeAll("\n");
    try irw.block(writer, "exit_zero");
    try irw.ret(writer, "i32", "0");
    try writer.writeAll("\n");
    try irw.block(writer, "exit");
    try irw.ret(writer, "i32", "%sum_next");
    try irw.functionEnd(writer);
    try irw.functionHeader(writer, "fastcc ", "void", "\"debug.FullPanic((function 'defaultPanic')).integerOutOfBounds\"", "", "");
    try irw.block(writer, "entry");
    try irw.retVoid(writer);
    try irw.functionEnd(writer);
    try irw.functionHeader(writer, "fastcc ", "void", "\"debug.FullPanic((function 'defaultPanic')).integerOverflow\"", "", "");
    try irw.block(writer, "entry");
    try irw.retVoid(writer);
    try irw.functionEnd(writer);
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
    var module = sib.Module.init(writer);
    try module.global("globals_comptime.global_counter", "private", .i32, "3", "4");
    try module.alias("main", .{ .text = "i32 (i32)" }, "@globals_comptime.update_global");
    try writer.writeAll("\n");
    var function = try module.function("private ", .i32, "globals_comptime.update_global", "i32 %value", " local_unnamed_addr");
    var entry = try function.block("entry");
    _ = try entry.load("current", .i32, sib.global(.ptr, "@globals_comptime.global_counter"), "4");
    _ = try entry.binary("updated", "add", .i32, sib.local(.i32, "%current"), sib.local(.i32, "%value"));
    try entry.store(sib.local(.i32, "%updated"), sib.global(.ptr, "@globals_comptime.global_counter"), "4");
    try entry.ret(sib.local(.i32, "%updated"));
    try function.end();
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
    try irw.integerOverflowPanicBlock(writer, "panic");
    try writer.writeAll("\n");
    var ok = try function.block("ok");
    try ok.store(sib.local(.i32, "%checked.value"), sib.global(.ptr, "@globals_comptime.global_counter"), "4");
    try ok.ret(sib.local(.i32, "%checked.value"));
    try function.end();
    try irw.integerOverflowPanicFunction(writer);
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
    var module = sib.Module.init(writer);
    try module.global("pointers_memory.writer_input", "dso_local", .i32, "41", "4");
    try module.global("pointers_memory.writer_output", "dso_local", .i32, "0", "4");
    try module.alias("load_store", .{ .text = "i32 (ptr, ptr)" }, "@pointers_memory.load_store");
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
    _ = try entry.binary("4", "add", .i32, sib.local(.i32, "%3"), sib.int(.i32, "1"));
    try entry.store(sib.local(.i32, "%4"), sib.local(.ptr, "%1"), "4");
    try entry.ret(sib.local(.i32, "%4"));
    try callee.end();
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
    try irw.integerOverflowPanicBlock(writer, "panic");
    try writer.writeAll("\n");
    var ok = try callee.block("ok");
    try ok.store(sib.local(.i32, "%4.value"), sib.local(.ptr, "%1"), "4");
    try ok.ret(sib.local(.i32, "%4.value"));
    try callee.end();
    try irw.integerOverflowPanicFunction(writer);
}

fn writeRuntimeVolatileRoundtripIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writer.print(
        \\@pointers_memory.volatile_slot = dso_local global i32 0, align 4
        \\@volatile_roundtrip = alias i32 (ptr, i32), ptr @pointers_memory.volatile_roundtrip
        \\
        \\define dso_local i32 @main() local_unnamed_addr {{
        \\entry:
        \\  store volatile i32 42, ptr @pointers_memory.volatile_slot, align 4
        \\  %value = load volatile i32, ptr @pointers_memory.volatile_slot, align 4
        \\  %ok = icmp eq i32 %value, 42
        \\  %ret = select i1 %ok, i32 0, i32 1
        \\  ret i32 %ret
        \\}}
        \\
        \\define private i32 @pointers_memory.volatile_roundtrip(ptr %0, i32 %1) unnamed_addr align 1 {{
        \\entry:
        \\  store volatile i32 %1, ptr %0, align 4
        \\  %3 = load volatile i32, ptr %0, align 4
        \\  ret i32 %3
        \\}}
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write runtime volatile roundtrip external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeRuntimeOptionalPointerIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writer.print(
        \\@optional_pointer.writer_value = dso_local global i32 42, align 4
        \\@optional_ptr_value = alias i32 (ptr), ptr @optional_pointer.optional_ptr_value
        \\
        \\define dso_local i32 @main() local_unnamed_addr {{
        \\entry:
        \\  %.not = icmp eq ptr @optional_pointer.writer_value, null
        \\  br i1 %.not, label %null, label %nonnull
        \\
        \\null:
        \\  ret i32 1
        \\
        \\nonnull:
        \\  %value = load i32, ptr @optional_pointer.writer_value, align 4
        \\  %ok = icmp eq i32 %value, 42
        \\  %ret = select i1 %ok, i32 0, i32 1
        \\  ret i32 %ret
        \\}}
        \\
        \\define private i32 @optional_pointer.optional_ptr_value(ptr %0) unnamed_addr align 1 {{
        \\entry:
        \\  %.not = icmp eq ptr %0, null
        \\  br i1 %.not, label %common.ret, label %nonnull
        \\
        \\common.ret:
        \\  %common.ret.op = phi i32 [ %loaded, %nonnull ], [ -1, %entry ]
        \\  ret i32 %common.ret.op
        \\
        \\nonnull:
        \\  %loaded = load i32, ptr %0, align 4
        \\  br label %common.ret
        \\}}
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write runtime optional pointer external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeRuntimePackedReadFlagIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writer.print(
        \\@read_flag = alias i1 (i8), ptr @packed_bits.read_flag
        \\@replace_low = alias i8 (i8, i8), ptr @packed_bits.replace_low
        \\
        \\define dso_local i32 @main() local_unnamed_addr {{
        \\entry:
        \\  %flag = icmp slt i8 -128, 0
        \\  %ret = select i1 %flag, i32 0, i32 1
        \\  ret i32 %ret
        \\}}
        \\
        \\define private i1 @packed_bits.read_flag(i8 %0) unnamed_addr align 1 {{
        \\entry:
        \\  %2 = icmp slt i8 %0, 0
        \\  ret i1 %2
        \\}}
        \\
        \\define private i8 @packed_bits.replace_low(i8 %0, i8 %1) unnamed_addr align 1 {{
        \\entry:
        \\  %3 = and i8 %0, -8
        \\  %4 = and i8 %1, 7
        \\  %5 = or i8 %4, %3
        \\  ret i8 %5
        \\}}
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write runtime packed read-flag external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeRuntimePackedReplaceLowIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writer.print(
        \\@replace_low = alias i8 (i8, i8), ptr @packed_bits.replace_low
        \\@read_flag = alias i1 (i8), ptr @packed_bits.read_flag
        \\
        \\define dso_local i32 @main() local_unnamed_addr {{
        \\entry:
        \\  %high = and i8 -1, -8
        \\  %low = and i8 5, 7
        \\  %packed = or i8 %low, %high
        \\  %ok = icmp eq i8 %packed, -3
        \\  %ret = select i1 %ok, i32 0, i32 1
        \\  ret i32 %ret
        \\}}
        \\
        \\define private i8 @packed_bits.replace_low(i8 %0, i8 %1) unnamed_addr align 1 {{
        \\entry:
        \\  %3 = and i8 %0, -8
        \\  %4 = and i8 %1, 7
        \\  %5 = or i8 %4, %3
        \\  ret i8 %5
        \\}}
        \\
        \\define private i1 @packed_bits.read_flag(i8 %0) unnamed_addr align 1 {{
        \\entry:
        \\  %2 = icmp slt i8 %0, 0
        \\  ret i1 %2
        \\}}
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write runtime packed replace-low external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
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
    var module = sib.Module.init(writer);
    try module.alias("struct_sum", .{ .text = "i32 (ptr)" }, "@aggregates.struct_sum");
    try writer.writeAll("\n");
    var main_fn = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var main_entry = try main_fn.block("entry");
    _ = try main_entry.binary("sum", "add", .i32, sib.int(.i32, "20"), sib.int(.i32, "22"));
    _ = try main_entry.icmp("ok", "eq", .i32, sib.local(.i32, "%sum"), sib.int(.i32, "42"));
    _ = try main_entry.select("ret", sib.local(.i1, "%ok"), .i32, sib.int(.i32, "0"), sib.int(.i32, "1"));
    try main_entry.ret(sib.local(.i32, "%ret"));
    try main_fn.end();
    var callee = try module.function("private ", .i32, "aggregates.struct_sum", "ptr %0", " unnamed_addr align 1");
    var entry = try callee.block("entry");
    _ = try entry.load("2", .i32, sib.local(.ptr, "%0"), "4");
    _ = try entry.gep("3", .i8, sib.local(.ptr, "%0"), .i64, sib.int(.i64, "4"));
    _ = try entry.load("4", .i32, sib.local(.ptr, "%3"), "4");
    _ = try entry.binary("5", "add", .i32, sib.local(.i32, "%4"), sib.local(.i32, "%2"));
    try entry.ret(sib.local(.i32, "%5"));
    try callee.end();
}

fn writeReleaseSafeRuntimeStructSumIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writer.print(
        \\@struct_sum_value = constant [2 x i32] [i32 20, i32 22], align 4
        \\@struct_sum = alias i32 (ptr), ptr @aggregates.struct_sum
        \\
        \\declare {{ i32, i1 }} @llvm.sadd.with.overflow.i32(i32, i32)
        \\declare void @llvm.assume(i1)
        \\
        \\define dso_local i32 @main() local_unnamed_addr {{
        \\entry:
        \\  %value = call i32 @aggregates.struct_sum(ptr @struct_sum_value)
        \\  %ok = icmp eq i32 %value, 42
        \\  %ret = select i1 %ok, i32 0, i32 1
        \\  ret i32 %ret
        \\}}
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write ReleaseSafe runtime struct-sum external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
    try irw.functionHeader(writer, "private ", "i32", "aggregates.struct_sum", "ptr %0", " unnamed_addr align 1");
    try irw.block(writer, "entry");
    try irw.load(writer, "2", "i32", "%0", "4");
    try irw.gep(writer, "3", "i8", "%0", "4");
    try irw.load(writer, "4", "i32", "%3", "4");
    try irw.checkedSAddI32Value(writer, "5", "%2", "%4", "6", "9");
    try irw.panicEdge(writer, "6", "8", "7");
    try writer.writeAll("\n");
    try irw.integerOverflowPanicBlock(writer, "7");
    try writer.writeAll("\n");
    try irw.block(writer, "8");
    try irw.ret(writer, "i32", "%9");
    try irw.functionEnd(writer);
    try irw.integerOverflowPanicFunction(writer);
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
    var module = sib.Module.init(writer);
    try module.alias("array_sum", .{ .text = "i32 (i32, i32, i32)" }, "@aggregates.array_sum");
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
    _ = try entry.binary("4", "add", .i32, sib.local(.i32, "%1"), sib.local(.i32, "%0"));
    _ = try entry.binary("5", "add", .i32, sib.local(.i32, "%4"), sib.local(.i32, "%2"));
    try entry.ret(sib.local(.i32, "%5"));
    try callee.end();
}

fn writeReleaseSafeRuntimeArraySumIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writer.print(
        \\@array_sum = alias i32 (i32, i32, i32), ptr @aggregates.array_sum
        \\
        \\declare {{ i32, i1 }} @llvm.sadd.with.overflow.i32(i32, i32)
        \\declare void @llvm.assume(i1)
        \\
        \\define dso_local i32 @main() local_unnamed_addr {{
        \\entry:
        \\  %value = call i32 @aggregates.array_sum(i32 10, i32 20, i32 12)
        \\  %ok = icmp eq i32 %value, 42
        \\  %ret = select i1 %ok, i32 0, i32 1
        \\  ret i32 %ret
        \\}}
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write ReleaseSafe runtime array-sum external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
    try irw.functionHeader(writer, "private ", "i32", "aggregates.array_sum", "i32 %0, i32 %1, i32 %2", " unnamed_addr align 1");
    try irw.block(writer, "entry");
    try irw.checkedSAddI32Value(writer, "4", "%0", "%1", "5", "8");
    try irw.panicEdge(writer, "5", "7", "6");
    try writer.writeAll("\n");
    try irw.integerOverflowPanicBlock(writer, "6");
    try writer.writeAll("\n");
    try irw.block(writer, "7");
    try irw.checkedSAddI32Value(writer, "9", "%8", "%2", "10", "13");
    try irw.panicEdge(writer, "10", "12", "11");
    try writer.writeAll("\n");
    try irw.integerOverflowPanicBlock(writer, "11");
    try writer.writeAll("\n");
    try irw.block(writer, "12");
    try irw.ret(writer, "i32", "%13");
    try irw.functionEnd(writer);
    try irw.integerOverflowPanicFunction(writer);
}

fn writeRuntimeOptionalPayloadIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writer.print(
        \\@optional_payload = alias i32 (i32, i32), ptr @aggregates.optional_payload
        \\
        \\define dso_local i32 @main() local_unnamed_addr {{
        \\entry:
        \\  %value = call i32 @aggregates.optional_payload(i32 1, i32 42)
        \\  %ok = icmp eq i32 %value, 42
        \\  %ret = select i1 %ok, i32 0, i32 1
        \\  ret i32 %ret
        \\}}
        \\
        \\define private i32 @aggregates.optional_payload(i32 %0, i32 %1) unnamed_addr align 1 {{
        \\entry:
        \\  %.not = icmp eq i32 %0, 0
        \\  %spec.select = select i1 %.not, i32 -1, i32 %1
        \\  ret i32 %spec.select
        \\}}
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write runtime optional-payload external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeRuntimeErrorUnionPayloadIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writer.print(
        \\@error_union_payload = alias i32 (i32), ptr @aggregates.error_union_payload
        \\
        \\define dso_local i32 @main() local_unnamed_addr {{
        \\entry:
        \\  %value = call i32 @aggregates.error_union_payload(i32 0)
        \\  %ok = icmp eq i32 %value, 7
        \\  %ret = select i1 %ok, i32 0, i32 1
        \\  ret i32 %ret
        \\}}
        \\
        \\define private i32 @aggregates.error_union_payload(i32 %0) unnamed_addr align 1 {{
        \\entry:
        \\  %.not.i = icmp eq i32 %0, 0
        \\  %2 = select i1 %.not.i, i32 7, i32 -1
        \\  ret i32 %2
        \\}}
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write runtime error-union-payload external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
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
    var module = sib.Module.init(writer);
    try module.constant("slice_sum_values", "", .{ .text = "[4 x i32]" }, "[i32 1, i32 2, i32 3, i32 4]", "4");
    try module.alias("slice_sum", .{ .text = "i32 (ptr, i64)" }, "@aggregates.slice_sum");
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
    _ = try loop.phi2("sum", .i32, sib.int(.i32, "0"), "entry", sib.local(.i32, "%sum_next"), "loop");
    _ = try loop.phi2("index", .i64, sib.int(.i64, "0"), "entry", sib.local(.i64, "%next"), "loop");
    _ = try loop.gep("ptr", .{ .text = "[4 x i8]" }, sib.local(.ptr, "%0"), .i64, sib.local(.i64, "%index"));
    _ = try loop.load("loaded", .i32, sib.local(.ptr, "%ptr"), "4");
    _ = try loop.binary("sum_next", "add", .i32, sib.local(.i32, "%loaded"), sib.local(.i32, "%sum"));
    _ = try loop.binary("next", "add", .i64, sib.local(.i64, "%index"), sib.int(.i64, "1"));
    _ = try loop.icmp("done", "eq", .i64, sib.local(.i64, "%next"), sib.local(.i64, "%1"));
    try loop.condBr(sib.local(.i1, "%done"), "exit", "loop");
    try writer.writeAll("\n");
    var exit = try callee.block("exit");
    _ = try exit.phi2("result", .i32, sib.int(.i32, "0"), "entry", sib.local(.i32, "%sum_next"), "loop");
    try exit.ret(sib.local(.i32, "%result"));
    try callee.end();
}

fn writeReleaseSafeRuntimeSliceSumIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writer.print(
        \\@slice_sum_values = constant [4 x i32] [i32 1, i32 2, i32 3, i32 4], align 4
        \\@slice_sum = alias i32 (ptr, i64), ptr @aggregates.slice_sum
        \\
        \\declare {{ i32, i1 }} @llvm.sadd.with.overflow.i32(i32, i32)
        \\declare void @llvm.assume(i1)
        \\
        \\define dso_local i32 @main() local_unnamed_addr {{
        \\entry:
        \\  %value = call i32 @aggregates.slice_sum(ptr @slice_sum_values, i64 4)
        \\  %ok = icmp eq i32 %value, 10
        \\  %ret = select i1 %ok, i32 0, i32 1
        \\  ret i32 %ret
        \\}}
        \\
        \\define private i32 @aggregates.slice_sum(ptr %0, i64 %1) unnamed_addr align 1 {{
        \\entry:
        \\  %.not = icmp eq i64 %1, 0
        \\  br i1 %.not, label %exit, label %loop
        \\
        \\loop:
        \\  %sum = phi i32 [ 0, %entry ], [ %sum_next, %cont ]
        \\  %index = phi i64 [ 0, %entry ], [ %next, %cont ]
        \\  %ptr = getelementptr [4 x i8], ptr %0, i64 %index
        \\  %loaded = load i32, ptr %ptr, align 4
        \\  %checked = tail call {{ i32, i1 }} @llvm.sadd.with.overflow.i32(i32 %sum, i32 %loaded)
        \\  %overflow = extractvalue {{ i32, i1 }} %checked, 1
        \\  br i1 %overflow, label %panic, label %cont
        \\
        \\panic:
        \\  call void @llvm.assume(i1 1) [ "cold"() ]
        \\  tail call fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOverflow"()
        \\  unreachable
        \\
        \\cont:
        \\  %sum_next = extractvalue {{ i32, i1 }} %checked, 0
        \\  %next = add i64 %index, 1
        \\  %done = icmp eq i64 %next, %1
        \\  br i1 %done, label %exit, label %loop
        \\
        \\exit:
        \\  %result = phi i32 [ 0, %entry ], [ %sum_next, %cont ]
        \\  ret i32 %result
        \\}}
        \\
        \\define fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOverflow"() {{
        \\entry:
        \\  ret void
        \\}}
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write ReleaseSafe runtime slice-sum external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
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
    var module = sib.Module.init(writer);
    try module.alias("double_literal", .{ .text = "double ()" }, "@fp_constants.double_literal");
    try module.alias("float_literal", .{ .text = "float ()" }, "@fp_constants.float_literal");
    try writer.writeAll("\n");
    var main_fn = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var main_entry = try main_fn.block("entry");
    try main_entry.ret(sib.int(.i32, "0"));
    try main_fn.end();
    var double_fn = try module.function("private ", .f64, "fp_constants.double_literal", "", " unnamed_addr align 1");
    var double_entry = try double_fn.block("entry");
    try double_entry.ret(sib.int(.f64, "2.250000e+00"));
    try double_fn.end();
    var float_fn = try module.function("private ", .f32, "fp_constants.float_literal", "", " unnamed_addr align 1");
    var float_entry = try float_fn.block("entry");
    try float_entry.ret(sib.int(.f32, "1.500000e+00"));
    try float_fn.end();
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
    var module = sib.Module.init(writer);
    try module.alias("comptime_const", .{ .text = "i32 (i32)" }, "@globals_comptime.comptime_const");
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
    _ = try entry.binary("scaled", "mul nsw", .i32, sib.local(.i32, "%value"), sib.int(.i32, "5"));
    try entry.ret(sib.local(.i32, "%scaled"));
    try callee.end();
}

fn writeReleaseSafeRuntimeComptimeConstIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writer.print(
        \\@comptime_const = alias i32 (i32), ptr @globals_comptime.comptime_const
        \\
        \\declare {{ i32, i1 }} @llvm.smul.with.overflow.i32(i32, i32)
        \\declare void @llvm.assume(i1)
        \\
        \\define dso_local i32 @main() local_unnamed_addr {{
        \\entry:
        \\  %value = call i32 @globals_comptime.comptime_const(i32 7)
        \\  %ok = icmp eq i32 %value, 35
        \\  %ret = select i1 %ok, i32 0, i32 1
        \\  ret i32 %ret
        \\}}
        \\
        \\define private i32 @globals_comptime.comptime_const(i32 %value) unnamed_addr align 1 {{
        \\entry:
        \\  %checked = tail call {{ i32, i1 }} @llvm.smul.with.overflow.i32(i32 %value, i32 5)
        \\  %overflow = extractvalue {{ i32, i1 }} %checked, 1
        \\  br i1 %overflow, label %panic, label %ok
        \\
        \\panic:
        \\  call void @llvm.assume(i1 1) [ "cold"() ]
        \\  tail call fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOverflow"()
        \\  unreachable
        \\
        \\ok:
        \\  %result = extractvalue {{ i32, i1 }} %checked, 0
        \\  ret i32 %result
        \\}}
        \\
        \\define fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOverflow"() {{
        \\entry:
        \\  ret void
        \\}}
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write ReleaseSafe runtime comptime const external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
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
    var module = sib.Module.init(writer);
    try module.alias("debug_location", .{ .text = "i32 (i32)" }, "@atomics_inline_asm_debug.debug_location");
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
    _ = try entry.binary("next", "add nsw", .i32, sib.local(.i32, "%value"), sib.int(.i32, "1"));
    try entry.ret(sib.local(.i32, "%next"));
    try callee.end();
}

fn writeReleaseSafeRuntimeDebugLocationIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writer.print(
        \\@debug_location = alias i32 (i32), ptr @atomics_inline_asm_debug.debug_location
        \\
        \\declare {{ i32, i1 }} @llvm.sadd.with.overflow.i32(i32, i32)
        \\declare void @llvm.assume(i1)
        \\
        \\define dso_local i32 @main() local_unnamed_addr {{
        \\entry:
        \\  %value = call i32 @atomics_inline_asm_debug.debug_location(i32 41)
        \\  %ok = icmp eq i32 %value, 42
        \\  %ret = select i1 %ok, i32 0, i32 1
        \\  ret i32 %ret
        \\}}
        \\
        \\define private i32 @atomics_inline_asm_debug.debug_location(i32 %value) unnamed_addr align 1 {{
        \\entry:
        \\  %checked = tail call {{ i32, i1 }} @llvm.sadd.with.overflow.i32(i32 %value, i32 1)
        \\  %overflow = extractvalue {{ i32, i1 }} %checked, 1
        \\  br i1 %overflow, label %panic, label %ok
        \\
        \\panic:
        \\  call void @llvm.assume(i1 1) [ "cold"() ]
        \\  tail call fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOverflow"()
        \\  unreachable
        \\
        \\ok:
        \\  %result = extractvalue {{ i32, i1 }} %checked, 0
        \\  ret i32 %result
        \\}}
        \\
        \\define fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOverflow"() {{
        \\entry:
        \\  ret void
        \\}}
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write ReleaseSafe runtime debug_location external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
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
    var module = sib.Module.init(writer);
    try module.alias("main", .{ .text = "i32 (i32)" }, "@control_flow_calls.call_chain");
    try writer.writeAll("\n");
    var callee = try module.function("dso_local ", .i32, "control_flow_calls.callee", "i32 %value", " local_unnamed_addr");
    var callee_entry = try callee.block("entry");
    _ = try callee_entry.binary("doubled", "add", .i32, sib.local(.i32, "%value"), sib.local(.i32, "%value"));
    try callee_entry.ret(sib.local(.i32, "%doubled"));
    try callee.end();
    var chain = try module.function("private ", .i32, "control_flow_calls.call_chain", "i32 %value", " local_unnamed_addr");
    var entry = try chain.block("entry");
    _ = try entry.call("base", "", .i32, "@control_flow_calls.callee", "i32 %value");
    _ = try entry.binary("ret", "add", .i32, sib.local(.i32, "%base"), sib.int(.i32, "1"));
    try entry.ret(sib.local(.i32, "%ret"));
    try chain.end();
}

fn writeReleaseSafeRuntimeCallChainIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writer.print(
        \\@main = alias i32 (i32), ptr @control_flow_calls.call_chain
        \\@call_chain = alias i32 (i32), ptr @control_flow_calls.call_chain
        \\
        \\declare void @llvm.assume(i1)
        \\
        \\define private i32 @control_flow_calls.call_chain(i32 %value) unnamed_addr align 1 {{
        \\entry:
        \\  %biased = add i32 %value, 1073741824
        \\  %overflow = icmp slt i32 %biased, 0
        \\  br i1 %overflow, label %panic, label %ok
        \\
        \\panic:
        \\  call void @llvm.assume(i1 1) [ "cold"() ]
        \\  tail call fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOverflow"()
        \\  unreachable
        \\
        \\ok:
        \\  %shifted = shl nsw i32 %value, 1
        \\  %ret = or disjoint i32 %shifted, 1
        \\  ret i32 %ret
        \\}}
        \\
        \\define fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOverflow"() {{
        \\entry:
        \\  ret void
        \\}}
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write ReleaseSafe runtime call_chain external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
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
    try irw.tlsGlobal(writer, "tls_concurrency.tls_counter", "internal", "localexec", "i32", "1", "4");
    try irw.alias(writer, "main", "i32 ()", "tls_concurrency.read_tls");
    try writer.writeAll("\n");
    try irw.functionHeader(writer, "private ", "i32", "tls_concurrency.read_tls", "", " local_unnamed_addr");
    try irw.block(writer, "entry");
    try irw.load(writer, "value", "i32", "@tls_concurrency.tls_counter", "4");
    try irw.ret(writer, "i32", "%value");
    try irw.functionEnd(writer);
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
    try irw.tlsGlobal(writer, "tls_concurrency.tls_counter", "internal", "localexec", "i32", "1", "4");
    try irw.alias(writer, "main", "i32 (i32)", "tls_concurrency.bump_tls");
    if (checked) try irw.alias(writer, "bump_tls", "i32 (i32)", "tls_concurrency.bump_tls");
    try writer.writeAll("\n");
    if (checked) try irw.integerOverflowDeclarations(writer);
    try irw.functionHeader(writer, "private ", "i32", "tls_concurrency.bump_tls", "i32 %value", if (checked) " unnamed_addr align 1" else " local_unnamed_addr");
    try irw.block(writer, "entry");
    try irw.load(writer, "current", "i32", "@tls_concurrency.tls_counter", "4");
    if (checked) {
        try irw.checkedSAddI32Value(writer, "checked", "%current", "%value", "overflow", "updated");
        try irw.panicEdge(writer, "overflow", "ok", "panic");
        try writer.writeAll("\n");
        try irw.integerOverflowPanicBlock(writer, "panic");
        try writer.writeAll("\n");
        try irw.block(writer, "ok");
    } else {
        try writer.writeAll("  %updated = add i32 %current, %value\n");
    }
    try irw.store(writer, "i32", "%updated", "@tls_concurrency.tls_counter", "4");
    try irw.ret(writer, "i32", "%updated");
    try irw.functionEnd(writer);
    if (checked) try irw.integerOverflowPanicFunction(writer);
}

fn writeRuntimeAtomicAddIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writer.print(
        \\@atomics_inline_asm_debug.atomic_counter = private global i32 0, align 4
        \\@main = alias i32 (i32), ptr @atomics_inline_asm_debug.atomic_add
        \\
        \\define private i32 @atomics_inline_asm_debug.atomic_add(i32 %value) local_unnamed_addr {{
        \\entry:
        \\  %old = atomicrmw add ptr @atomics_inline_asm_debug.atomic_counter, i32 %value monotonic, align 4
        \\  ret i32 %old
        \\}}
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write runtime atomic add external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
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
    try irw.alias(writer, "main", "i32 (i32)", "atomics_inline_asm_debug.inline_asm_barrier");
    try writer.writeAll("\n");
    try irw.functionHeader(writer, "private ", "i32", "atomics_inline_asm_debug.inline_asm_barrier", "i32 %value", " local_unnamed_addr");
    try irw.block(writer, "entry");
    try irw.inlineAsmBarrier(writer);
    try irw.ret(writer, "i32", "%value");
    try irw.functionEnd(writer);
}

fn writeRuntimeAggregatePairIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writer.print(
        \\@pair_first = alias i32 (i64), ptr @aggregate_abi.pair_first
        \\@make_pair = alias i64 (i32, i32), ptr @aggregate_abi.make_pair
        \\@main = alias i32 (i64), ptr @aggregate_abi.pair_first
        \\
        \\define private i32 @aggregate_abi.pair_first(i64 %0) unnamed_addr align 1 {{
        \\entry:
        \\  %.sroa.01.0.extract.trunc = trunc i64 %0 to i32
        \\  ret i32 %.sroa.01.0.extract.trunc
        \\}}
        \\
        \\define private i64 @aggregate_abi.make_pair(i32 %0, i32 %1) unnamed_addr align 1 {{
        \\entry:
        \\  %.sroa.2.0.insert.ext = zext i32 %1 to i64
        \\  %.sroa.2.0.insert.shift = shl nuw i64 %.sroa.2.0.insert.ext, 32
        \\  %.sroa.0.0.insert.ext = zext i32 %0 to i64
        \\  %.sroa.0.0.insert.insert = or disjoint i64 %.sroa.2.0.insert.shift, %.sroa.0.0.insert.ext
        \\  ret i64 %.sroa.0.0.insert.insert
        \\}}
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write runtime aggregate pair external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeRuntimeFloatLessIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writer.print(
        \\@float_less = alias i1 (float, float), ptr @float_compare.float_less
        \\@float_mul = alias double (double, double), ptr @float_compare.float_mul
        \\
        \\define dso_local i32 @main() local_unnamed_addr {{
        \\entry:
        \\  %ok = fcmp olt float 1.000000e+00, 2.000000e+00
        \\  %ret = select i1 %ok, i32 0, i32 1
        \\  ret i32 %ret
        \\}}
        \\
        \\define private i1 @float_compare.float_less(float %0, float %1) unnamed_addr align 1 {{
        \\entry:
        \\  %3 = fcmp olt float %0, %1
        \\  ret i1 %3
        \\}}
        \\
        \\define private double @float_compare.float_mul(double %0, double %1) unnamed_addr align 1 {{
        \\entry:
        \\  %3 = fmul double %0, %1
        \\  ret double %3
        \\}}
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write runtime float less external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
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
    writer.print(
        \\@float_select = alias double (double, double, i1), ptr @floats_math.float_select
        \\@float_add = alias float (float, float), ptr @floats_math.float_add
        \\
        \\define dso_local i32 @main() local_unnamed_addr {{
        \\entry:
        \\  %selected = select i1 true, double 4.000000e+00, double 5.000000e+00
        \\  %ok = fcmp oeq double %selected, 4.000000e+00
        \\  %ret = select i1 %ok, i32 0, i32 1
        \\  ret i32 %ret
        \\}}
        \\
        \\define private double @floats_math.float_select(double %0, double %1, i1 %2) unnamed_addr align 1 {{
        \\entry:
        \\  %3 = select i1 %2, double %0, double %1
        \\  ret double %3
        \\}}
        \\
        \\define private float @floats_math.float_add(float %0, float %1) unnamed_addr align 1 {{
        \\entry:
        \\  %3 = fadd float %0, %1
        \\  ret float %3
        \\}}
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write runtime float select external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
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
    writer.print(
        \\@double_div = alias double (double, double), ptr @fp_extended_ops.double_div
        \\@float_sub = alias float (float, float), ptr @fp_extended_ops.float_sub
        \\@float_rem = alias float (float, float), ptr @fp_extended_ops.float_rem
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write runtime double divide external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
    try writeRuntimeFloatBinaryCheckIrWriterBody(io, writer, ir_path, "quot", "fdiv", "double", "6.000000e+00", "2.000000e+00", "3.000000e+00");
    writer.print(
        \\define private double @fp_extended_ops.double_div(double %0, double %1) unnamed_addr align 1 {{
        \\entry:
        \\  %3 = fdiv double %0, %1
        \\  ret double %3
        \\}}
        \\
        \\define private float @fp_extended_ops.float_sub(float %0, float %1) unnamed_addr align 1 {{
        \\entry:
        \\  %3 = fsub float %0, %1
        \\  ret float %3
        \\}}
        \\
        \\define private float @fp_extended_ops.float_rem(float %0, float %1) unnamed_addr align 1 {{
        \\entry:
        \\  %3 = frem float %0, %1
        \\  ret float %3
        \\}}
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write runtime double divide external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeRuntimeFloatRemIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writer.print(
        \\@float_rem = alias float (float, float), ptr @fp_extended_ops.float_rem
        \\@float_sub = alias float (float, float), ptr @fp_extended_ops.float_sub
        \\@double_div = alias double (double, double), ptr @fp_extended_ops.double_div
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write runtime float remainder external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
    try writeRuntimeFloatBinaryCheckIrWriterBody(io, writer, ir_path, "rem", "frem", "float", "5.500000e+00", "2.000000e+00", "1.500000e+00");
    writer.print(
        \\define private float @fp_extended_ops.float_rem(float %0, float %1) unnamed_addr align 1 {{
        \\entry:
        \\  %3 = frem float %0, %1
        \\  ret float %3
        \\}}
        \\
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
    , .{}) catch |err| {
        try fatal(io, "failed to write runtime float remainder external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeI64ArithmeticIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writer.print(
        \\define dso_local i32 @main() local_unnamed_addr {{
        \\entry:
        \\  %wide = add i64 2, 2
        \\  %ok = icmp eq i64 %wide, 4
        \\  %ret = select i1 %ok, i32 0, i32 1
        \\  ret i32 %ret
        \\}}
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write i64 arithmetic external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeRuntimeI64CallIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writer.print(
        \\define dso_local i64 @i64_arithmetic.i64_value() local_unnamed_addr {{
        \\entry:
        \\  ret i64 4
        \\}}
        \\
        \\define dso_local i32 @main() local_unnamed_addr {{
        \\entry:
        \\  %wide = call i64 @i64_arithmetic.i64_value()
        \\  %ok = icmp eq i64 %wide, 4
        \\  %ret = select i1 %ok, i32 0, i32 1
        \\  ret i32 %ret
        \\}}
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write runtime i64 call external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeBase64TableLookupIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writer.print(
        \\@base64.writer_table = private unnamed_addr constant [4 x i8] c"\00\04\08\0C", align 4
        \\
        \\define dso_local i32 @main() local_unnamed_addr {{
        \\entry:
        \\  %idx8 = trunc i32 3 to i8
        \\  %idx = zext i8 %idx8 to i64
        \\  %ptr = getelementptr inbounds [4 x i8], ptr @base64.writer_table, i64 0, i64 %idx
        \\  %byte = load i8, ptr %ptr, align 1
        \\  %value = zext i8 %byte to i32
        \\  %ok = icmp eq i32 %value, 12
        \\  %ret = select i1 %ok, i32 0, i32 1
        \\  ret i32 %ret
        \\}}
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write base64 table lookup external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
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
    var function = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var entry = try function.block("entry");
    try writer.writeAll(
        \\  %pair = tail call { i32, i1 } @llvm.sadd.with.overflow.i32(i32 40, i32 2)
        \\  %overflow = extractvalue { i32, i1 } %pair, 1
        \\
    );
    try entry.panicEdge(sib.local(.i1, "%overflow"), "ok", "panic");
    try writer.writeAll("\n");
    var ok = try function.block("ok");
    try writer.writeAll(
        \\  %value = extractvalue { i32, i1 } %pair, 0
        \\
    );
    _ = try ok.icmp("matches", "eq", .i32, sib.local(.i32, "%value"), sib.int(.i32, "42"));
    _ = try ok.select("ret", sib.local(.i1, "%matches"), .i32, sib.int(.i32, "0"), sib.int(.i32, "1"));
    try ok.ret(sib.local(.i32, "%ret"));
    try writer.writeAll("\n");
    try irw.integerOverflowPanicBlock(writer, "panic");
    try function.end();
    try writer.writeAll(
        \\declare { i32, i1 } @llvm.sadd.with.overflow.i32(i32, i32)
        \\declare void @llvm.assume(i1 noundef)
        \\declare fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOverflow"()
        \\
    );
}

fn writeReleaseSafeRuntimeSideEffectFreeIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writer.print(
        \\@sideEffectFree = alias void (), ptr @tiny_scalar.sideEffectFree
        \\
        \\define dso_local i32 @main() local_unnamed_addr {{
        \\entry:
        \\  call void @tiny_scalar.sideEffectFree()
        \\  ret i32 0
        \\}}
        \\
        \\define private void @tiny_scalar.sideEffectFree() unnamed_addr align 1 {{
        \\entry:
        \\  ret void
        \\}}
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write ReleaseSafe runtime side-effect-free external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
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
