const std = @import("std");
const common = @import("tool_common.zig");

const usage =
    \\usage: zig run tools/compare_codegen.zig -- --mode=asm|objdump|readelf
    \\
    \\Compare local x86_64 codegen fixtures.
    \\Set TARGET to override x86_64-unknown-linux-gnu.
    \\
;

const Mode = enum { assembly, objdump, readelf };

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;

    const mode = try parseModeArg(allocator, io, init);
    const target = try getEnvOwnedOrNull(allocator, init.minimal.environ, "TARGET");
    defer if (target) |value| allocator.free(value);

    const temp = try common.TempDir.init(allocator, io, "compare_codegen");
    defer temp.deinit(allocator, io);

    const files = try collectInputFiles(allocator, io, mode);
    defer {
        for (files) |file| allocator.free(file);
        allocator.free(files);
    }

    var stdout_buffer: [4096]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
    for (files) |file| {
        const id = std.fs.path.stem(file);
        switch (mode) {
            .assembly => try runAsmCase(allocator, io, temp, target orelse "x86_64-unknown-linux-gnu", file, id),
            .objdump => try runObjdumpCase(allocator, io, temp, target orelse "x86_64-unknown-linux-gnu", file, id),
            .readelf => try runReadelfCase(allocator, io, temp, target orelse "x86_64-unknown-linux-gnu", file, id),
        }
        try stdout_writer.interface.print("ok codegen {s} {s}\n", .{ modeName(mode), id });
        try stdout_writer.interface.flush();
    }
}

fn parseModeArg(allocator: std.mem.Allocator, io: std.Io, init: std.process.Init) !Mode {
    var args = try std.process.Args.Iterator.initAllocator(init.minimal.args, allocator);
    defer args.deinit();
    _ = args.next();

    var mode: ?Mode = null;
    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "--help") or std.mem.eql(u8, arg, "-h")) {
            var stdout_buffer: [512]u8 = undefined;
            var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
            try stdout_writer.interface.writeAll(usage);
            try stdout_writer.interface.flush();
            std.process.exit(0);
        } else if (std.mem.startsWith(u8, arg, "--mode=")) {
            const text = arg["--mode=".len..];
            mode = if (std.mem.eql(u8, text, "asm"))
                .assembly
            else if (std.mem.eql(u8, text, "objdump"))
                .objdump
            else if (std.mem.eql(u8, text, "readelf"))
                .readelf
            else
                try common.validationError(io, "unknown mode: {s}\n{s}", .{ text, usage });
        } else {
            try common.validationError(io, "unexpected argument: {s}\n{s}", .{ arg, usage });
        }
    }
    return mode orelse try common.validationError(io, "missing --mode\n{s}", .{usage});
}

fn collectInputFiles(allocator: std.mem.Allocator, io: std.Io, mode: Mode) ![][]const u8 {
    var dir = try std.Io.Dir.cwd().openDir(io, "test/codegen/inputs", .{ .iterate = true });
    defer dir.close(io);

    var files: std.ArrayList([]const u8) = .empty;
    errdefer {
        for (files.items) |file| allocator.free(file);
        files.deinit(allocator);
    }

    var iter = dir.iterate();
    while (try iter.next(io)) |entry| {
        if (entry.kind != .file) continue;
        if (!std.mem.endsWith(u8, entry.name, ".ll")) continue;
        if (mode == .readelf and !std.mem.startsWith(u8, entry.name, "call_")) continue;
        if (mode != .readelf and !try expectedExists(io, mode, std.fs.path.stem(entry.name))) continue;
        try files.append(allocator, try allocator.dupe(u8, entry.name));
    }

    std.mem.sort([]const u8, files.items, {}, stringLessThan);
    return files.toOwnedSlice(allocator);
}

fn expectedExists(io: std.Io, mode: Mode, id: []const u8) !bool {
    const allocator = std.heap.smp_allocator;
    const expected = try expectedPath(allocator, mode, id);
    defer allocator.free(expected);
    return common.fileExists(io, expected);
}

fn runAsmCase(
    allocator: std.mem.Allocator,
    io: std.Io,
    temp: common.TempDir,
    target: []const u8,
    file: []const u8,
    id: []const u8,
) !void {
    const input = try std.fs.path.join(allocator, &.{ "test/codegen/inputs", file });
    defer allocator.free(input);
    const expected = try expectedPath(allocator, .assembly, id);
    defer allocator.free(expected);
    const actual = try common.allocTempFile(allocator, temp, id, ".s");
    defer allocator.free(actual);

    const target_arg = try std.fmt.allocPrint(allocator, "--target={s}", .{target});
    defer allocator.free(target_arg);
    const argv = [_][]const u8{ "zig", "build", "run", "--", "--emit=asm", target_arg, input };
    try common.runToFile(allocator, io, &argv, "zig build run", actual);
    try common.diffFiles(allocator, io, expected, actual);
}

fn runObjdumpCase(
    allocator: std.mem.Allocator,
    io: std.Io,
    temp: common.TempDir,
    target: []const u8,
    file: []const u8,
    id: []const u8,
) !void {
    const input = try std.fs.path.join(allocator, &.{ "test/codegen/inputs", file });
    defer allocator.free(input);
    const expected = try expectedPath(allocator, .objdump, id);
    defer allocator.free(expected);
    const object = try common.allocTempFile(allocator, temp, id, ".o");
    defer allocator.free(object);
    const actual = try common.allocTempFile(allocator, temp, id, ".objdump.txt");
    defer allocator.free(actual);

    const target_arg = try std.fmt.allocPrint(allocator, "--target={s}", .{target});
    defer allocator.free(target_arg);
    const z_argv = [_][]const u8{ "zig", "build", "run", "--", "--emit=obj", target_arg, input };
    try common.runToFile(allocator, io, &z_argv, "zig build run", object);

    try writeObjdumpTextSection(allocator, io, object, actual);
    try common.diffFiles(allocator, io, expected, actual);
}

fn runReadelfCase(
    allocator: std.mem.Allocator,
    io: std.Io,
    temp: common.TempDir,
    target: []const u8,
    file: []const u8,
    id: []const u8,
) !void {
    const input = try std.fs.path.join(allocator, &.{ "test/codegen/inputs", file });
    defer allocator.free(input);
    const object = try common.allocTempFile(allocator, temp, id, ".o");
    defer allocator.free(object);

    const target_arg = try std.fmt.allocPrint(allocator, "--target={s}", .{target});
    defer allocator.free(target_arg);
    const z_argv = [_][]const u8{ "zig", "build", "run", "--", "--emit=obj", target_arg, input };
    try common.runToFile(allocator, io, &z_argv, "zig build run", object);

    const readelf_argv = [_][]const u8{ "readelf", "-r", "-s", object };
    const result = try common.runCapture(allocator, io, &readelf_argv, "readelf");
    defer common.freeRunResult(allocator, result);
    if (std.mem.indexOf(u8, result.stdout, "R_X86_64_PLT32") == null) {
        try common.validationError(io, "missing R_X86_64_PLT32 relocation in {s}\n", .{id});
    }
    if (std.mem.indexOf(u8, result.stdout, "callee") == null) {
        try common.validationError(io, "missing callee symbol in {s}\n", .{id});
    }
}

fn expectedPath(allocator: std.mem.Allocator, mode: Mode, id: []const u8) ![]const u8 {
    return switch (mode) {
        .assembly => std.fmt.allocPrint(allocator, "test/codegen/expected/asm/{s}.s", .{id}),
        .objdump => std.fmt.allocPrint(allocator, "test/codegen/expected/objdump/{s}.txt", .{id}),
        .readelf => unreachable,
    };
}

fn writeObjdumpTextSection(
    allocator: std.mem.Allocator,
    io: std.Io,
    object: []const u8,
    output_path: []const u8,
) !void {
    const argv = [_][]const u8{ "objdump", "-dr", object };
    const result = try common.runCapture(allocator, io, &argv, "objdump");
    defer common.freeRunResult(allocator, result);

    const marker = "Disassembly of section .text:";
    const start = std.mem.indexOf(u8, result.stdout, marker) orelse {
        try common.validationError(io, "objdump output missing .text disassembly for {s}\n", .{object});
    };
    try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = output_path, .data = result.stdout[start..] });
}

fn stringLessThan(_: void, lhs: []const u8, rhs: []const u8) bool {
    return std.mem.lessThan(u8, lhs, rhs);
}

fn modeName(mode: Mode) []const u8 {
    return switch (mode) {
        .assembly => "asm",
        .objdump => "objdump",
        .readelf => "readelf",
    };
}

fn getEnvOwnedOrNull(allocator: std.mem.Allocator, environ: std.process.Environ, name: []const u8) !?[]const u8 {
    return environ.getAlloc(allocator, name) catch |err| switch (err) {
        error.EnvironmentVariableMissing => null,
        else => err,
    };
}
