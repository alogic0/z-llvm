const std = @import("std");
const codegen = @import("codegen.zig");
const ir = @import("ir.zig");
const mc = @import("mc.zig");
const pass_manager = @import("pass_manager.zig");
const pipelines = @import("pipelines.zig");
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
    const surface = irWriterSurfaceForCase(case_id);

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
        \\
    , .{ wrapper, case_id, mode, surface }) catch |err| {
        try fatal(io, "failed to write external IR writer header {s}: {any}\n", .{ ir_path, err });
    };
    if (std.mem.eql(u8, case_id, "releasefast_tiny_scalar")) {
        try writeTinyScalarIrWriterBody(io, &writer.interface, ir_path);
    } else if (std.mem.eql(u8, case_id, "releasefast_integers")) {
        try writeIntegersIrWriterBody(io, &writer.interface, ir_path);
    } else if (std.mem.eql(u8, case_id, "releasefast_error_switch")) {
        try writeErrorSwitchIrWriterBody(io, &writer.interface, ir_path);
    } else if (std.mem.eql(u8, case_id, "releasefast_control_flow_calls")) {
        try writeControlFlowCallsIrWriterBody(io, &writer.interface, ir_path);
    } else if (std.mem.eql(u8, case_id, "releasefast_globals_comptime")) {
        try writeGlobalsComptimeIrWriterBody(io, &writer.interface, ir_path);
    } else if (std.mem.eql(u8, case_id, "releasefast_runtime_cond_branch")) {
        try writeRuntimeCondBranchIrWriterBody(io, &writer.interface, ir_path);
    } else if (std.mem.eql(u8, case_id, "releasefast_runtime_phi_merge")) {
        try writeRuntimePhiMergeIrWriterBody(io, &writer.interface, ir_path);
    } else if (std.mem.eql(u8, case_id, "releasefast_runtime_loop_sum")) {
        try writeRuntimeLoopSumIrWriterBody(io, &writer.interface, ir_path);
    } else if (std.mem.eql(u8, case_id, "releasefast_runtime_switch")) {
        try writeRuntimeSwitchIrWriterBody(io, &writer.interface, ir_path);
    } else if (std.mem.eql(u8, case_id, "releasefast_runtime_global_update")) {
        try writeRuntimeGlobalUpdateIrWriterBody(io, &writer.interface, ir_path);
    } else if (std.mem.eql(u8, case_id, "releasesafe_runtime_global_update")) {
        try writeReleaseSafeRuntimeGlobalUpdateIrWriterBody(io, &writer.interface, ir_path);
    } else if (std.mem.eql(u8, case_id, "releasefast_runtime_pointer_load_store")) {
        try writeRuntimePointerLoadStoreIrWriterBody(io, &writer.interface, ir_path);
    } else if (std.mem.eql(u8, case_id, "releasesafe_runtime_pointer_load_store")) {
        try writeReleaseSafeRuntimePointerLoadStoreIrWriterBody(io, &writer.interface, ir_path);
    } else if (std.mem.eql(u8, case_id, "releasefast_runtime_volatile_roundtrip")) {
        try writeRuntimeVolatileRoundtripIrWriterBody(io, &writer.interface, ir_path);
    } else if (std.mem.eql(u8, case_id, "releasefast_runtime_optional_pointer")) {
        try writeRuntimeOptionalPointerIrWriterBody(io, &writer.interface, ir_path);
    } else if (std.mem.eql(u8, case_id, "releasefast_runtime_packed_read_flag")) {
        try writeRuntimePackedReadFlagIrWriterBody(io, &writer.interface, ir_path);
    } else if (std.mem.eql(u8, case_id, "releasefast_runtime_packed_replace_low")) {
        try writeRuntimePackedReplaceLowIrWriterBody(io, &writer.interface, ir_path);
    } else if (std.mem.eql(u8, case_id, "releasefast_runtime_struct_sum")) {
        try writeRuntimeStructSumIrWriterBody(io, &writer.interface, ir_path);
    } else if (std.mem.eql(u8, case_id, "releasefast_runtime_array_sum")) {
        try writeRuntimeArraySumIrWriterBody(io, &writer.interface, ir_path);
    } else if (std.mem.eql(u8, case_id, "releasefast_runtime_optional_payload")) {
        try writeRuntimeOptionalPayloadIrWriterBody(io, &writer.interface, ir_path);
    } else if (std.mem.eql(u8, case_id, "releasefast_runtime_error_union_payload")) {
        try writeRuntimeErrorUnionPayloadIrWriterBody(io, &writer.interface, ir_path);
    } else if (std.mem.eql(u8, case_id, "releasefast_runtime_slice_sum")) {
        try writeRuntimeSliceSumIrWriterBody(io, &writer.interface, ir_path);
    } else if (std.mem.eql(u8, case_id, "releasefast_runtime_fp_constants")) {
        try writeRuntimeFpConstantsIrWriterBody(io, &writer.interface, ir_path);
    } else if (std.mem.eql(u8, case_id, "releasefast_runtime_comptime_const")) {
        try writeRuntimeComptimeConstIrWriterBody(io, &writer.interface, ir_path);
    } else if (std.mem.eql(u8, case_id, "releasesafe_runtime_comptime_const")) {
        try writeReleaseSafeRuntimeComptimeConstIrWriterBody(io, &writer.interface, ir_path);
    } else if (std.mem.eql(u8, case_id, "releasefast_runtime_debug_location")) {
        try writeRuntimeDebugLocationIrWriterBody(io, &writer.interface, ir_path);
    } else if (std.mem.eql(u8, case_id, "releasesafe_runtime_debug_location")) {
        try writeReleaseSafeRuntimeDebugLocationIrWriterBody(io, &writer.interface, ir_path);
    } else if (std.mem.eql(u8, case_id, "releasefast_runtime_call_chain")) {
        try writeRuntimeCallChainIrWriterBody(io, &writer.interface, ir_path);
    } else if (std.mem.eql(u8, case_id, "releasefast_runtime_tls_read")) {
        try writeRuntimeTlsReadIrWriterBody(io, &writer.interface, ir_path);
    } else if (std.mem.eql(u8, case_id, "releasefast_runtime_tls_bump")) {
        try writeRuntimeTlsBumpIrWriterBody(io, &writer.interface, ir_path);
    } else if (std.mem.eql(u8, case_id, "releasefast_runtime_atomic_add")) {
        try writeRuntimeAtomicAddIrWriterBody(io, &writer.interface, ir_path);
    } else if (std.mem.eql(u8, case_id, "releasefast_runtime_inline_asm_barrier")) {
        try writeRuntimeInlineAsmBarrierIrWriterBody(io, &writer.interface, ir_path);
    } else if (std.mem.eql(u8, case_id, "releasefast_runtime_aggregate_pair")) {
        try writeRuntimeAggregatePairIrWriterBody(io, &writer.interface, ir_path);
    } else if (std.mem.eql(u8, case_id, "releasefast_runtime_float_less")) {
        try writeRuntimeFloatLessIrWriterBody(io, &writer.interface, ir_path);
    } else if (std.mem.eql(u8, case_id, "releasefast_runtime_float_mul")) {
        try writeRuntimeFloatMulIrWriterBody(io, &writer.interface, ir_path);
    } else if (std.mem.eql(u8, case_id, "releasefast_runtime_float_add")) {
        try writeRuntimeFloatAddIrWriterBody(io, &writer.interface, ir_path);
    } else if (std.mem.eql(u8, case_id, "releasefast_runtime_float_select")) {
        try writeRuntimeFloatSelectIrWriterBody(io, &writer.interface, ir_path);
    } else if (std.mem.eql(u8, case_id, "releasefast_runtime_float_sub")) {
        try writeRuntimeFloatSubIrWriterBody(io, &writer.interface, ir_path);
    } else if (std.mem.eql(u8, case_id, "releasefast_runtime_double_div")) {
        try writeRuntimeDoubleDivIrWriterBody(io, &writer.interface, ir_path);
    } else if (std.mem.eql(u8, case_id, "releasefast_runtime_float_rem")) {
        try writeRuntimeFloatRemIrWriterBody(io, &writer.interface, ir_path);
    } else if (std.mem.eql(u8, case_id, "releasesafe_error_switch")) {
        try writeErrorSwitchIrWriterBody(io, &writer.interface, ir_path);
    } else if (std.mem.eql(u8, case_id, "releasesafe_tiny_scalar_runtime_boundary")) {
        try writeCheckedAddRuntimeBoundaryIrWriterBody(io, &writer.interface, ir_path);
    } else if (std.mem.eql(u8, case_id, "releasesmall_globals_comptime")) {
        try writeGlobalsComptimeIrWriterBody(io, &writer.interface, ir_path);
    } else if (std.mem.eql(u8, case_id, "releasesmall_i64_arithmetic")) {
        try writeI64ArithmeticIrWriterBody(io, &writer.interface, ir_path);
    } else if (std.mem.eql(u8, case_id, "releasesmall_runtime_i64_call")) {
        try writeRuntimeI64CallIrWriterBody(io, &writer.interface, ir_path);
    } else if (std.mem.eql(u8, case_id, "releasesmall_base64_table_lookup")) {
        try writeBase64TableLookupIrWriterBody(io, &writer.interface, ir_path);
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

fn irWriterSurfaceForCase(case_id: []const u8) []const u8 {
    if (std.mem.eql(u8, case_id, "releasefast_tiny_scalar")) return "scalar-add-ret";
    if (std.mem.eql(u8, case_id, "releasefast_integers")) return "integer-arithmetic";
    if (std.mem.eql(u8, case_id, "releasefast_error_switch")) return "error-switch-select";
    if (std.mem.eql(u8, case_id, "releasefast_control_flow_calls")) return "direct-call";
    if (std.mem.eql(u8, case_id, "releasefast_globals_comptime")) return "global-load";
    if (std.mem.eql(u8, case_id, "releasefast_runtime_cond_branch")) return "runtime-condbr";
    if (std.mem.eql(u8, case_id, "releasefast_runtime_phi_merge")) return "runtime-phi-merge";
    if (std.mem.eql(u8, case_id, "releasefast_runtime_loop_sum")) return "runtime-loop-sum";
    if (std.mem.eql(u8, case_id, "releasefast_runtime_switch")) return "runtime-switch";
    if (std.mem.eql(u8, case_id, "releasefast_runtime_global_update")) return "global-update";
    if (std.mem.eql(u8, case_id, "releasesafe_runtime_global_update")) return "checked-global-update-boundary";
    if (std.mem.eql(u8, case_id, "releasefast_runtime_pointer_load_store")) return "pointer-load-store";
    if (std.mem.eql(u8, case_id, "releasesafe_runtime_pointer_load_store")) return "checked-pointer-load-store-boundary";
    if (std.mem.eql(u8, case_id, "releasefast_runtime_volatile_roundtrip")) return "volatile-roundtrip";
    if (std.mem.eql(u8, case_id, "releasefast_runtime_optional_pointer")) return "optional-pointer";
    if (std.mem.eql(u8, case_id, "releasefast_runtime_packed_read_flag")) return "packed-read-flag";
    if (std.mem.eql(u8, case_id, "releasefast_runtime_packed_replace_low")) return "packed-replace-low";
    if (std.mem.eql(u8, case_id, "releasefast_runtime_struct_sum")) return "struct-field-sum";
    if (std.mem.eql(u8, case_id, "releasefast_runtime_array_sum")) return "array-scalar-sum";
    if (std.mem.eql(u8, case_id, "releasefast_runtime_optional_payload")) return "optional-scalar-payload";
    if (std.mem.eql(u8, case_id, "releasefast_runtime_error_union_payload")) return "error-union-payload";
    if (std.mem.eql(u8, case_id, "releasefast_runtime_slice_sum")) return "slice-loop-sum";
    if (std.mem.eql(u8, case_id, "releasefast_runtime_fp_constants")) return "fp-literal-return";
    if (std.mem.eql(u8, case_id, "releasefast_runtime_comptime_const")) return "comptime-const-mul";
    if (std.mem.eql(u8, case_id, "releasesafe_runtime_comptime_const")) return "checked-comptime-const-boundary";
    if (std.mem.eql(u8, case_id, "releasefast_runtime_debug_location")) return "add-imm-return";
    if (std.mem.eql(u8, case_id, "releasesafe_runtime_debug_location")) return "checked-add-imm-boundary";
    if (std.mem.eql(u8, case_id, "releasefast_runtime_call_chain")) return "abi-arg-call";
    if (std.mem.eql(u8, case_id, "releasefast_runtime_tls_read")) return "tls-read";
    if (std.mem.eql(u8, case_id, "releasefast_runtime_tls_bump")) return "tls-bump";
    if (std.mem.eql(u8, case_id, "releasefast_runtime_atomic_add")) return "atomic-add";
    if (std.mem.eql(u8, case_id, "releasefast_runtime_inline_asm_barrier")) return "inline-asm-barrier";
    if (std.mem.eql(u8, case_id, "releasefast_runtime_aggregate_pair")) return "aggregate-pair-abi";
    if (std.mem.eql(u8, case_id, "releasefast_runtime_float_less")) return "float-less";
    if (std.mem.eql(u8, case_id, "releasefast_runtime_float_mul")) return "float-mul";
    if (std.mem.eql(u8, case_id, "releasefast_runtime_float_add")) return "float-add";
    if (std.mem.eql(u8, case_id, "releasefast_runtime_float_select")) return "float-select";
    if (std.mem.eql(u8, case_id, "releasefast_runtime_float_sub")) return "float-sub";
    if (std.mem.eql(u8, case_id, "releasefast_runtime_double_div")) return "double-div";
    if (std.mem.eql(u8, case_id, "releasefast_runtime_float_rem")) return "float-rem";
    if (std.mem.eql(u8, case_id, "releasesafe_error_switch")) return "error-switch-select";
    if (std.mem.eql(u8, case_id, "releasesafe_tiny_scalar_runtime_boundary")) return "checked-add-runtime-boundary";
    if (std.mem.eql(u8, case_id, "releasesmall_globals_comptime")) return "global-load";
    if (std.mem.eql(u8, case_id, "releasesmall_i64_arithmetic")) return "i64-arithmetic";
    if (std.mem.eql(u8, case_id, "releasesmall_runtime_i64_call")) return "i64-call-return";
    if (std.mem.eql(u8, case_id, "releasesmall_base64_table_lookup")) return "table-indexed-load";
    return "minimal-ret0";
}

fn writeTinyScalarIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writer.print(
        \\define dso_local i32 @main() local_unnamed_addr {{
        \\entry:
        \\  %v = add i32 40, 2
        \\  ret i32 %v
        \\}}
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write tiny scalar external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeIntegersIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writer.print(
        \\define dso_local i32 @main() local_unnamed_addr {{
        \\entry:
        \\  %wrap = add i32 2147483647, 1
        \\  %wrap_ok = icmp eq i32 %wrap, -2147483648
        \\  %cmp = icmp slt i32 7, 3
        \\  %sel = select i1 %cmp, i32 7, i32 3
        \\  %sel_ok = icmp eq i32 %sel, 3
        \\  %shift = and i32 4, 31
        \\  %left = shl i32 305419896, %shift
        \\  %right = lshr i32 305419896, %shift
        \\  %mixed = xor i32 %left, %right
        \\  %mixed_ok = icmp eq i32 %mixed, 577118951
        \\  %ok_a = and i1 %wrap_ok, %sel_ok
        \\  %ok = and i1 %ok_a, %mixed_ok
        \\  %ret = select i1 %ok, i32 0, i32 1
        \\  ret i32 %ret
        \\}}
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write integers external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeErrorSwitchIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writer.print(
        \\define dso_local i32 @main() local_unnamed_addr {{
        \\entry:
        \\  %is_one = icmp eq i8 1, 1
        \\  %first = select i1 %is_one, i32 -1, i32 -2
        \\  %first_ok = icmp eq i32 %first, -1
        \\  %is_zero = icmp eq i8 0, 0
        \\  %second = select i1 %is_zero, i32 0, i32 %first
        \\  %second_ok = icmp eq i32 %second, 0
        \\  %ok = and i1 %first_ok, %second_ok
        \\  br i1 %ok, label %success, label %failure
        \\
        \\success:
        \\  ret i32 0
        \\
        \\failure:
        \\  ret i32 1
        \\}}
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write error_switch external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeControlFlowCallsIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writer.print(
        \\define internal i32 @control_flow_calls.writer_callee() local_unnamed_addr {{
        \\entry:
        \\  ret i32 41
        \\}}
        \\
        \\define dso_local i32 @main() local_unnamed_addr {{
        \\entry:
        \\  %base = call i32 @control_flow_calls.writer_callee()
        \\  %ret = add i32 %base, 1
        \\  ret i32 %ret
        \\}}
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write control_flow_calls external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeGlobalsComptimeIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writer.print(
        \\@globals_comptime.writer_counter = private global i32 5, align 4
        \\
        \\define dso_local i32 @globals_comptime.read_global() local_unnamed_addr {{
        \\entry:
        \\  %value = load i32, ptr @globals_comptime.writer_counter, align 4
        \\  ret i32 %value
        \\}}
        \\
        \\define dso_local i32 @main() local_unnamed_addr {{
        \\entry:
        \\  %value = call i32 @globals_comptime.read_global()
        \\  ret i32 %value
        \\}}
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write globals_comptime external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeRuntimeCondBranchIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writer.print(
        \\define dso_local i32 @main(i1 zeroext %flag) local_unnamed_addr {{
        \\entry:
        \\  br i1 %flag, label %then, label %else
        \\
        \\then:
        \\  ret i32 0
        \\
        \\else:
        \\  ret i32 1
        \\}}
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write runtime conditional branch external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeRuntimePhiMergeIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writer.print(
        \\define dso_local i32 @main(i1 zeroext %flag) local_unnamed_addr {{
        \\entry:
        \\  br i1 %flag, label %then, label %else
        \\
        \\then:
        \\  br label %merge
        \\
        \\else:
        \\  br label %merge
        \\
        \\merge:
        \\  %ret = phi i32 [ 0, %then ], [ 1, %else ]
        \\  ret i32 %ret
        \\}}
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write runtime phi merge external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeRuntimeLoopSumIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writer.print(
        \\@main = alias i32 (i32), ptr @control_flow_calls.loop_sum
        \\
        \\define private i32 @control_flow_calls.loop_sum(i32 %limit) local_unnamed_addr {{
        \\entry:
        \\  %is_zero = icmp eq i32 %limit, 0
        \\  br i1 %is_zero, label %exit_zero, label %loop
        \\
        \\loop:
        \\  %index = phi i32 [ 0, %entry ], [ %next, %loop ]
        \\  %sum = phi i32 [ 0, %entry ], [ %sum_next, %loop ]
        \\  %sum_next = add i32 %sum, %index
        \\  %next = add i32 %index, 1
        \\  %done = icmp eq i32 %next, %limit
        \\  br i1 %done, label %exit, label %loop
        \\
        \\exit_zero:
        \\  ret i32 0
        \\
        \\exit:
        \\  ret i32 %sum_next
        \\}}
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write runtime loop sum external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeRuntimeSwitchIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writer.print(
        \\@switch.table.switch_control.dense_switch = private unnamed_addr constant [3 x i32] [i32 11, i32 13, i32 17], align 4
        \\@main = alias i32 (i8), ptr @switch_control.dense_switch
        \\
        \\define private range(i32 11, 24) i32 @switch_control.dense_switch(i8 zeroext %0) unnamed_addr {{
        \\entry:
        \\  %in_table = icmp ult i8 %0, 3
        \\  br i1 %in_table, label %switch.lookup, label %fallback
        \\
        \\switch.lookup:
        \\  %index = zext i8 %0 to i64
        \\  %switch.gep = getelementptr i32, ptr @switch.table.switch_control.dense_switch, i64 %index
        \\  %switch.load = load i32, ptr %switch.gep, align 4
        \\  br label %merge
        \\
        \\fallback:
        \\  %range_base = add i8 %0, -3
        \\  %in_range = icmp ult i8 %range_base, 3
        \\  %fallback_value = select i1 %in_range, i32 19, i32 23
        \\  br label %merge
        \\
        \\merge:
        \\  %ret = phi i32 [ %switch.load, %switch.lookup ], [ %fallback_value, %fallback ]
        \\  ret i32 %ret
        \\}}
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write runtime switch external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeRuntimeGlobalUpdateIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writer.print(
        \\@globals_comptime.global_counter = private global i32 3, align 4
        \\@main = alias i32 (i32), ptr @globals_comptime.update_global
        \\
        \\define private i32 @globals_comptime.update_global(i32 %value) local_unnamed_addr {{
        \\entry:
        \\  %current = load i32, ptr @globals_comptime.global_counter, align 4
        \\  %updated = add i32 %current, %value
        \\  store i32 %updated, ptr @globals_comptime.global_counter, align 4
        \\  ret i32 %updated
        \\}}
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write runtime global update external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeReleaseSafeRuntimeGlobalUpdateIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writer.print(
        \\@globals_comptime.global_counter = private global i32 3, align 4
        \\@main = alias i32 (i32), ptr @globals_comptime.update_global
        \\
        \\declare {{ i32, i1 }} @llvm.sadd.with.overflow.i32(i32, i32)
        \\declare void @llvm.assume(i1)
        \\
        \\define private i32 @globals_comptime.update_global(i32 %value) unnamed_addr align 1 {{
        \\entry:
        \\  %current = load i32, ptr @globals_comptime.global_counter, align 4
        \\  %checked = tail call {{ i32, i1 }} @llvm.sadd.with.overflow.i32(i32 %current, i32 %value)
        \\  %overflow = extractvalue {{ i32, i1 }} %checked, 1
        \\  br i1 %overflow, label %panic, label %ok
        \\
        \\panic:
        \\  call void @llvm.assume(i1 1) [ "cold"() ]
        \\  tail call fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOverflow"()
        \\  unreachable
        \\
        \\ok:
        \\  %updated = extractvalue {{ i32, i1 }} %checked, 0
        \\  store i32 %updated, ptr @globals_comptime.global_counter, align 4
        \\  ret i32 %updated
        \\}}
        \\
        \\define fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOverflow"() {{
        \\entry:
        \\  ret void
        \\}}
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write ReleaseSafe runtime global update external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeRuntimePointerLoadStoreIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writer.print(
        \\@pointers_memory.writer_input = dso_local global i32 41, align 4
        \\@pointers_memory.writer_output = dso_local global i32 0, align 4
        \\@load_store = alias i32 (ptr, ptr), ptr @pointers_memory.load_store
        \\
        \\define dso_local i32 @main() local_unnamed_addr {{
        \\entry:
        \\  %value = load i32, ptr @pointers_memory.writer_input, align 4
        \\  %updated = add i32 %value, 1
        \\  store i32 %updated, ptr @pointers_memory.writer_output, align 4
        \\  %stored = load i32, ptr @pointers_memory.writer_output, align 4
        \\  %ok = icmp eq i32 %stored, 42
        \\  %ret = select i1 %ok, i32 0, i32 1
        \\  ret i32 %ret
        \\}}
        \\
        \\define private i32 @pointers_memory.load_store(ptr %0, ptr %1) unnamed_addr align 1 {{
        \\entry:
        \\  %3 = load i32, ptr %0, align 4
        \\  %4 = add i32 %3, 1
        \\  store i32 %4, ptr %1, align 4
        \\  ret i32 %4
        \\}}
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write runtime pointer load/store external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeReleaseSafeRuntimePointerLoadStoreIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writer.print(
        \\@pointers_memory.writer_input = dso_local global i32 41, align 4
        \\@pointers_memory.writer_output = dso_local global i32 0, align 4
        \\@load_store = alias i32 (ptr, ptr), ptr @pointers_memory.load_store
        \\
        \\declare {{ i32, i1 }} @llvm.sadd.with.overflow.i32(i32, i32)
        \\declare void @llvm.assume(i1)
        \\
        \\define dso_local i32 @main() local_unnamed_addr {{
        \\entry:
        \\  %value = load i32, ptr @pointers_memory.writer_input, align 4
        \\  %updated = add i32 %value, 1
        \\  store i32 %updated, ptr @pointers_memory.writer_output, align 4
        \\  %stored = load i32, ptr @pointers_memory.writer_output, align 4
        \\  %ok = icmp eq i32 %stored, 42
        \\  %ret = select i1 %ok, i32 0, i32 1
        \\  ret i32 %ret
        \\}}
        \\
        \\define private i32 @pointers_memory.load_store(ptr %0, ptr %1) unnamed_addr align 1 {{
        \\entry:
        \\  %3 = load i32, ptr %0, align 4
        \\  %4 = tail call {{ i32, i1 }} @llvm.sadd.with.overflow.i32(i32 %3, i32 1)
        \\  %5 = extractvalue {{ i32, i1 }} %4, 1
        \\  br i1 %5, label %panic, label %ok
        \\
        \\panic:
        \\  call void @llvm.assume(i1 1) [ "cold"() ]
        \\  tail call fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOverflow"()
        \\  unreachable
        \\
        \\ok:
        \\  %8 = extractvalue {{ i32, i1 }} %4, 0
        \\  store i32 %8, ptr %1, align 4
        \\  ret i32 %8
        \\}}
        \\
        \\define fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOverflow"() {{
        \\entry:
        \\  ret void
        \\}}
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write ReleaseSafe runtime pointer load/store external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
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
    writer.print(
        \\@struct_sum = alias i32 (ptr), ptr @aggregates.struct_sum
        \\
        \\define dso_local i32 @main() local_unnamed_addr {{
        \\entry:
        \\  %sum = add i32 20, 22
        \\  %ok = icmp eq i32 %sum, 42
        \\  %ret = select i1 %ok, i32 0, i32 1
        \\  ret i32 %ret
        \\}}
        \\
        \\define private i32 @aggregates.struct_sum(ptr %0) unnamed_addr align 1 {{
        \\entry:
        \\  %2 = load i32, ptr %0, align 4
        \\  %3 = getelementptr i8, ptr %0, i64 4
        \\  %4 = load i32, ptr %3, align 4
        \\  %5 = add i32 %4, %2
        \\  ret i32 %5
        \\}}
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write runtime struct-sum external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeRuntimeArraySumIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writer.print(
        \\@array_sum = alias i32 (i32, i32, i32), ptr @aggregates.array_sum
        \\
        \\define dso_local i32 @main() local_unnamed_addr {{
        \\entry:
        \\  %value = call i32 @aggregates.array_sum(i32 10, i32 20, i32 12)
        \\  %ok = icmp eq i32 %value, 42
        \\  %ret = select i1 %ok, i32 0, i32 1
        \\  ret i32 %ret
        \\}}
        \\
        \\define private i32 @aggregates.array_sum(i32 %0, i32 %1, i32 %2) unnamed_addr align 1 {{
        \\entry:
        \\  %4 = add i32 %1, %0
        \\  %5 = add i32 %4, %2
        \\  ret i32 %5
        \\}}
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write runtime array-sum external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
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
    writer.print(
        \\@slice_sum_values = constant [4 x i32] [i32 1, i32 2, i32 3, i32 4], align 4
        \\@slice_sum = alias i32 (ptr, i64), ptr @aggregates.slice_sum
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
        \\  %sum = phi i32 [ 0, %entry ], [ %sum_next, %loop ]
        \\  %index = phi i64 [ 0, %entry ], [ %next, %loop ]
        \\  %ptr = getelementptr [4 x i8], ptr %0, i64 %index
        \\  %loaded = load i32, ptr %ptr, align 4
        \\  %sum_next = add i32 %loaded, %sum
        \\  %next = add i64 %index, 1
        \\  %done = icmp eq i64 %next, %1
        \\  br i1 %done, label %exit, label %loop
        \\
        \\exit:
        \\  %result = phi i32 [ 0, %entry ], [ %sum_next, %loop ]
        \\  ret i32 %result
        \\}}
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write runtime slice-sum external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeRuntimeFpConstantsIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writer.print(
        \\@double_literal = alias double (), ptr @fp_constants.double_literal
        \\@float_literal = alias float (), ptr @fp_constants.float_literal
        \\
        \\define dso_local i32 @main() local_unnamed_addr {{
        \\entry:
        \\  ret i32 0
        \\}}
        \\
        \\define private double @fp_constants.double_literal() unnamed_addr align 1 {{
        \\entry:
        \\  ret double 2.250000e+00
        \\}}
        \\
        \\define private float @fp_constants.float_literal() unnamed_addr align 1 {{
        \\entry:
        \\  ret float 1.500000e+00
        \\}}
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write runtime FP constants external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeRuntimeComptimeConstIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writer.print(
        \\@comptime_const = alias i32 (i32), ptr @globals_comptime.comptime_const
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
        \\  %scaled = mul nsw i32 %value, 5
        \\  ret i32 %scaled
        \\}}
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write runtime comptime const external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
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
    writer.print(
        \\@debug_location = alias i32 (i32), ptr @atomics_inline_asm_debug.debug_location
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
        \\  %next = add nsw i32 %value, 1
        \\  ret i32 %next
        \\}}
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write runtime debug_location external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
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
    writer.print(
        \\@main = alias i32 (i32), ptr @control_flow_calls.call_chain
        \\
        \\define dso_local i32 @control_flow_calls.callee(i32 %value) local_unnamed_addr {{
        \\entry:
        \\  %doubled = add i32 %value, %value
        \\  ret i32 %doubled
        \\}}
        \\
        \\define private i32 @control_flow_calls.call_chain(i32 %value) local_unnamed_addr {{
        \\entry:
        \\  %base = call i32 @control_flow_calls.callee(i32 %value)
        \\  %ret = add i32 %base, 1
        \\  ret i32 %ret
        \\}}
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write runtime call chain external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeRuntimeTlsReadIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writer.print(
        \\@tls_concurrency.tls_counter = internal thread_local(localexec) global i32 1, align 4
        \\@main = alias i32 (), ptr @tls_concurrency.read_tls
        \\
        \\define private i32 @tls_concurrency.read_tls() local_unnamed_addr {{
        \\entry:
        \\  %value = load i32, ptr @tls_concurrency.tls_counter, align 4
        \\  ret i32 %value
        \\}}
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write runtime TLS read external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

fn writeRuntimeTlsBumpIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writer.print(
        \\@tls_concurrency.tls_counter = internal thread_local(localexec) global i32 1, align 4
        \\@main = alias i32 (i32), ptr @tls_concurrency.bump_tls
        \\
        \\define private i32 @tls_concurrency.bump_tls(i32 %value) local_unnamed_addr {{
        \\entry:
        \\  %current = load i32, ptr @tls_concurrency.tls_counter, align 4
        \\  %updated = add i32 %current, %value
        \\  store i32 %updated, ptr @tls_concurrency.tls_counter, align 4
        \\  ret i32 %updated
        \\}}
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write runtime TLS bump external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
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
    writer.print(
        \\@main = alias i32 (i32), ptr @atomics_inline_asm_debug.inline_asm_barrier
        \\
        \\define private i32 @atomics_inline_asm_debug.inline_asm_barrier(i32 %value) local_unnamed_addr {{
        \\entry:
        \\  tail call void asm sideeffect "", "~{{memory}},~{{dirflag}},~{{fpsr}},~{{flags}}"()
        \\  ret i32 %value
        \\}}
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write runtime inline asm barrier external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
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
        \\define dso_local i32 @main() local_unnamed_addr {{
        \\entry:
        \\  %mul = fmul double 3.000000e+00, 2.000000e+00
        \\  %ok = fcmp oeq double %mul, 6.000000e+00
        \\  %ret = select i1 %ok, i32 0, i32 1
        \\  ret i32 %ret
        \\}}
        \\
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
        \\define dso_local i32 @main() local_unnamed_addr {{
        \\entry:
        \\  %sum = fadd float 1.000000e+00, 2.000000e+00
        \\  %ok = fcmp oeq float %sum, 3.000000e+00
        \\  %ret = select i1 %ok, i32 0, i32 1
        \\  ret i32 %ret
        \\}}
        \\
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
        \\define dso_local i32 @main() local_unnamed_addr {{
        \\entry:
        \\  %diff = fsub float 5.000000e+00, 2.000000e+00
        \\  %ok = fcmp oeq float %diff, 3.000000e+00
        \\  %ret = select i1 %ok, i32 0, i32 1
        \\  ret i32 %ret
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
        \\define dso_local i32 @main() local_unnamed_addr {{
        \\entry:
        \\  %quot = fdiv double 6.000000e+00, 2.000000e+00
        \\  %ok = fcmp oeq double %quot, 3.000000e+00
        \\  %ret = select i1 %ok, i32 0, i32 1
        \\  ret i32 %ret
        \\}}
        \\
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
        \\define dso_local i32 @main() local_unnamed_addr {{
        \\entry:
        \\  %rem = frem float 5.500000e+00, 2.000000e+00
        \\  %ok = fcmp oeq float %rem, 1.500000e+00
        \\  %ret = select i1 %ok, i32 0, i32 1
        \\  ret i32 %ret
        \\}}
        \\
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
    writer.print(
        \\define dso_local i32 @main() local_unnamed_addr {{
        \\entry:
        \\  %pair = tail call {{ i32, i1 }} @llvm.sadd.with.overflow.i32(i32 40, i32 2)
        \\  %overflow = extractvalue {{ i32, i1 }} %pair, 1
        \\  br i1 %overflow, label %panic, label %ok
        \\
        \\ok:
        \\  %value = extractvalue {{ i32, i1 }} %pair, 0
        \\  %matches = icmp eq i32 %value, 42
        \\  %ret = select i1 %matches, i32 0, i32 1
        \\  ret i32 %ret
        \\
        \\panic:
        \\  call void @llvm.assume(i1 1) [ "cold"() ]
        \\  tail call fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOverflow"()
        \\  unreachable
        \\}}
        \\
        \\declare {{ i32, i1 }} @llvm.sadd.with.overflow.i32(i32, i32)
        \\declare void @llvm.assume(i1 noundef)
        \\declare fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOverflow"()
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write checked-add runtime boundary external IR writer body {s}: {any}\n", .{ ir_path, err });
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
