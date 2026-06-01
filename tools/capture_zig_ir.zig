const std = @import("std");
const common = @import("tool_common.zig");

const usage = "usage: zig build capture-zig-ir -- <zig-source> <Debug|ReleaseSafe|ReleaseFast|ReleaseSmall> [target] [output.ll]";

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;

    var args = try std.process.Args.Iterator.initAllocator(init.minimal.args, allocator);
    defer args.deinit();
    _ = args.skip();
    const source_path = args.next() orelse try usageError(io, "{s}\n", .{usage});
    const optimize_mode = args.next() orelse try usageError(io, "{s}\n", .{usage});
    const target_arg = args.next() orelse "x86_64-linux-gnu";
    const output_override = args.next();
    if (args.next() != null) {
        try usageError(io, "{s}\n", .{usage});
    }

    if (!validOptimizeMode(optimize_mode)) {
        try usageError(io, "unsupported optimize mode: {s}\n{s}\n", .{ optimize_mode, usage });
    }

    std.Io.Dir.cwd().access(io, source_path, .{ .read = true }) catch {
        try common.validationError(io, "missing Zig source: {s}\n", .{source_path});
    };

    const zig_source_env = try common.getEnvOwnedOrNull(allocator, init.minimal.environ, "ZIG_SOURCE_DIR");
    defer if (zig_source_env) |value| allocator.free(value);
    const zig_source_dir = zig_source_env orelse "../ziglang";

    const zig_emitter_env = try common.getEnvOwnedOrNull(allocator, init.minimal.environ, "ZIG_EMITTER");
    defer if (zig_emitter_env) |value| allocator.free(value);
    const default_zig_emitter = try std.fs.path.join(allocator, &.{ zig_source_dir, "build/stage4/bin/zig" });
    defer allocator.free(default_zig_emitter);
    const zig_emitter = zig_emitter_env orelse default_zig_emitter;

    const check_argv = [_][]const u8{ "zig", "run", "tools/check_zig_stage4_emitter.zig" };
    const check_result = try common.runCapture(allocator, io, &check_argv, "tools/check_zig_stage4_emitter.zig");
    common.freeRunResult(allocator, check_result);

    const output_path = if (output_override) |path|
        try allocator.dupe(u8, path)
    else
        try defaultOutputPath(allocator, source_path, optimize_mode, target_arg);
    defer allocator.free(output_path);

    if (std.fs.path.dirname(output_path)) |parent| {
        try std.Io.Dir.cwd().createDirPath(io, parent);
    }

    const emit_arg = try std.fmt.allocPrint(allocator, "-femit-llvm-ir={s}", .{output_path});
    defer allocator.free(emit_arg);

    var argv: std.ArrayList([]const u8) = .empty;
    defer argv.deinit(allocator);
    try argv.appendSlice(allocator, &.{
        zig_emitter,
        "build-obj",
        "-fllvm",
        "-flibllvm",
    });
    if (shouldStrip(optimize_mode)) {
        try argv.append(allocator, "-fstrip");
    }
    try argv.appendSlice(allocator, &.{
        "-fno-emit-bin",
        emit_arg,
        "-O",
        optimize_mode,
        "-target",
        target_arg,
        source_path,
    });

    const emit_result = try common.runCapture(allocator, io, argv.items, "stage4 Zig LLVM IR capture");
    common.freeRunResult(allocator, emit_result);

    var stdout_buffer: [512]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
    try stdout_writer.interface.print("wrote {s}\n", .{output_path});
    try stdout_writer.interface.flush();
}

fn validOptimizeMode(mode: []const u8) bool {
    return std.mem.eql(u8, mode, "Debug") or
        std.mem.eql(u8, mode, "ReleaseSafe") or
        std.mem.eql(u8, mode, "ReleaseFast") or
        std.mem.eql(u8, mode, "ReleaseSmall");
}

fn shouldStrip(mode: []const u8) bool {
    return std.mem.eql(u8, mode, "ReleaseFast") or std.mem.eql(u8, mode, "ReleaseSmall");
}

fn defaultOutputPath(allocator: std.mem.Allocator, source_path: []const u8, mode: []const u8, target_arg: []const u8) ![]u8 {
    const source_name = std.fs.path.stem(source_path);
    const target_tag_end = std.mem.indexOfScalar(u8, target_arg, '-') orelse target_arg.len;
    const target_tag = target_arg[0..target_tag_end];
    const dir = if (std.mem.eql(u8, mode, "Debug") or std.mem.eql(u8, mode, "ReleaseSafe"))
        "tmp/zig_ir/raw"
    else
        "test/zig/captured";
    return std.fmt.allocPrint(allocator, "{s}/{s}.{s}.{s}.ll", .{ dir, source_name, mode, target_tag });
}

fn usageError(io: std.Io, comptime fmt: []const u8, args: anytype) !noreturn {
    var stderr_buffer: [4096]u8 = undefined;
    var stderr_writer = std.Io.File.stderr().writer(io, &stderr_buffer);
    try stderr_writer.interface.print(fmt, args);
    try stderr_writer.interface.flush();
    std.process.exit(2);
}
