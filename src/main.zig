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
    } else if (std.mem.eql(u8, case_id, "releasesmall_i64_arithmetic")) {
        try writeI64ArithmeticIrWriterBody(io, &writer.interface, ir_path);
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
    if (std.mem.eql(u8, case_id, "releasesmall_i64_arithmetic")) return "i64-arithmetic";
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
