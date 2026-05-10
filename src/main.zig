const std = @import("std");
const ir = @import("ir.zig");
const pass_manager = @import("pass_manager.zig");
const instcombine = @import("passes/instcombine.zig");
const dce = @import("passes/dce.zig");

const usage =
    \\usage: z_llvm [--passes=list] [--trace] <input.ll>
    \\
    \\Supported passes: instcombine,dce
    \\
;

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;

    var args = try std.process.Args.Iterator.initAllocator(init.minimal.args, allocator);
    defer args.deinit();
    _ = args.next();

    var pass_list: []const u8 = "instcombine,dce";
    var trace = false;
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

    const input = try std.Io.Dir.cwd().readFileAlloc(io, path, allocator, .limited(1024 * 1024));
    defer allocator.free(input);

    var module = try ir.Module.parse(allocator, input);
    defer module.deinit();
    try module.verify();

    var pm = pass_manager.ModulePassManager.init(allocator);
    defer pm.deinit();
    try addPasses(&pm, pass_list);

    var context: pass_manager.Context = .{ .allocator = allocator };
    var stdout_buffer: [4096]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;
    _ = try pm.run(&module, &context, stdout, trace);
    if (!trace) try module.print(stdout);
    try stdout.flush();
}

fn addPasses(pm: *pass_manager.ModulePassManager, pass_list: []const u8) !void {
    var names = std.mem.splitScalar(u8, pass_list, ',');
    while (names.next()) |raw_name| {
        const name = std.mem.trim(u8, raw_name, " \t");
        if (name.len == 0) continue;
        if (std.mem.eql(u8, name, "instcombine")) {
            try pm.add(instcombine.pass);
        } else if (std.mem.eql(u8, name, "dce")) {
            try pm.add(dce.pass);
        } else {
            return error.UnknownPass;
        }
    }
}
