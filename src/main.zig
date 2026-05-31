const std = @import("std");
const codegen = @import("codegen.zig");
const ir = @import("ir.zig");
const mc = @import("mc.zig");
const pass_manager = @import("pass_manager.zig");
const pipelines = @import("pipelines.zig");
const target = @import("target.zig");

const usage =
    \\usage: z_llvm [--emit=ir|asm|obj] [--target=triple] [--datalayout=layout] [--passes=list|pipeline] [--pipeline=name] [--trace] [--time] [--quiet] [--pass-limit=N] [--input-limit=N] <input.ll>
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
            var machine = try codegen.x86_64.lowerFunction(allocator, triple, function);
            errdefer machine.deinit(allocator);
            try machines.append(allocator, machine);
        }

        if (emit == .@"asm") {
            for (machines.items) |machine| try mc.assembly.printFunction(machine, stdout);
        } else {
            try mc.elf.writeObjectWithAliases(allocator, machines.items, module.aliases.items, stdout);
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

fn parseInputLimit(text: []const u8) !usize {
    const limit = try std.fmt.parseInt(usize, text, 10);
    if (limit == 0) return error.InvalidInputLimit;
    return limit;
}

fn fatal(io: std.Io, comptime fmt: []const u8, args: anytype) noreturn {
    var stderr_buffer: [4096]u8 = undefined;
    var stderr_writer = std.Io.File.stderr().writer(io, &stderr_buffer);
    stderr_writer.interface.print(fmt, args) catch {};
    stderr_writer.interface.flush() catch {};
    std.process.exit(2);
}
