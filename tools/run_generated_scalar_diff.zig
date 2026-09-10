const std = @import("std");
const common = @import("tool_common.zig");

const Case = struct {
    id: []const u8,
    op: []const u8,
    rhs: []const u8,
};

const generated_cases = [_]Case{
    .{ .id = "gen_add_zero", .op = "add", .rhs = "0" },
    .{ .id = "gen_sub_zero", .op = "sub", .rhs = "0" },
    .{ .id = "gen_mul_one", .op = "mul", .rhs = "1" },
    .{ .id = "gen_and_allones", .op = "and", .rhs = "-1" },
    .{ .id = "gen_or_zero", .op = "or", .rhs = "0" },
    .{ .id = "gen_xor_zero", .op = "xor", .rhs = "0" },
};

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;

    const opt_bin = try common.getEnvOwnedOrNull(allocator, init.minimal.environ, "OPT_BIN");
    defer if (opt_bin) |value| allocator.free(value);

    const temp = try common.TempDir.init(allocator, io, "generated_scalar_diff");
    defer temp.deinit(allocator, io);

    var stdout_buffer: [4096]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);

    for (generated_cases) |case| {
        const path = try writeScalarCase(allocator, io, temp, case);
        defer allocator.free(path);
        try runEquivalentCase(allocator, io, temp, case.id, "instcombine,dce", path, opt_bin orelse "opt-22");
        try stdout_writer.interface.print("ok generated scalar {s} [instcombine,dce]\n", .{case.id});
        try stdout_writer.interface.flush();
    }

    try runUnsupportedVector(allocator, io, temp);
    try stdout_writer.interface.writeAll("ok generated negative unsupported_vector\n");
    try stdout_writer.interface.flush();

    try runUnsupportedAtomicOrdering(allocator, io, temp);
    try stdout_writer.interface.writeAll("ok generated negative unsupported_atomic_ordering\n");
    try stdout_writer.interface.flush();

    if (try common.commandExists(allocator, io, "lli-22")) {
        try runExecutionCase(allocator, io, temp);
        try stdout_writer.interface.writeAll("ok generated execution lli-22\n");
    } else {
        try stdout_writer.interface.writeAll("skip generated execution lli-22 unavailable\n");
    }
    try stdout_writer.interface.flush();
    try @import("run_behavioral_diff.zig").run(init);
}

fn writeScalarCase(allocator: std.mem.Allocator, io: std.Io, temp: common.TempDir, case: Case) ![]const u8 {
    const path = try common.allocTempFile(allocator, temp, case.id, ".ll");
    errdefer allocator.free(path);
    const contents = try std.fmt.allocPrint(
        allocator,
        \\define i32 @{s}(i32 %x) {{
        \\entry:
        \\  %y = {s} i32 %x, {s}
        \\  ret i32 %y
        \\}}
        \\
    ,
        .{ case.id, case.op, case.rhs },
    );
    defer allocator.free(contents);
    try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = path, .data = contents });
    return path;
}

fn runEquivalentCase(
    allocator: std.mem.Allocator,
    io: std.Io,
    temp: common.TempDir,
    id: []const u8,
    passes: []const u8,
    path: []const u8,
    opt_bin: []const u8,
) !void {
    const z_raw = try common.allocTempFile(allocator, temp, id, ".z.ll");
    defer allocator.free(z_raw);
    const z_norm = try common.allocTempFile(allocator, temp, id, ".z.norm.ll");
    defer allocator.free(z_norm);
    const llvm_raw = try common.allocTempFile(allocator, temp, id, ".llvm.ll");
    defer allocator.free(llvm_raw);
    const llvm_norm = try common.allocTempFile(allocator, temp, id, ".llvm.norm.ll");
    defer allocator.free(llvm_norm);

    const passes_arg = try std.fmt.allocPrint(allocator, "--passes={s}", .{passes});
    defer allocator.free(passes_arg);
    const z_argv = [_][]const u8{ "zig", "build", "run", "--", passes_arg, path };
    try common.runToFile(allocator, io, &z_argv, "zig build run", z_raw);

    const opt_passes_arg = try std.fmt.allocPrint(allocator, "-passes={s}", .{passes});
    defer allocator.free(opt_passes_arg);
    const opt_argv = [_][]const u8{ opt_bin, opt_passes_arg, path, "-S", "-o", llvm_raw };
    const opt_result = try common.runCapture(allocator, io, &opt_argv, opt_bin);
    common.freeRunResult(allocator, opt_result);

    try common.normalizeToFile(allocator, io, z_raw, z_norm);
    try common.normalizeToFile(allocator, io, llvm_raw, llvm_norm);
    try common.diffFiles(allocator, io, llvm_norm, z_norm);
}

fn runUnsupportedVector(allocator: std.mem.Allocator, io: std.Io, temp: common.TempDir) !void {
    const path = try temp.join(allocator, "unsupported_vector.ll");
    defer allocator.free(path);
    try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = path, .data =
        \\define <vscale x 2 x i32> @bad(<vscale x 2 x i32> %x) {
        \\entry:
        \\  ret <vscale x 2 x i32> %x
        \\}
        \\
    });
    const argv = [_][]const u8{ "zig", "build", "run", "--", path };
    if (!try common.runExpectFailure(allocator, io, &argv)) {
        try common.validationError(io, "expected unsupported vector case to fail\n", .{});
    }
}

fn runUnsupportedAtomicOrdering(allocator: std.mem.Allocator, io: std.Io, temp: common.TempDir) !void {
    const path = try temp.join(allocator, "unsupported_atomic_ordering.ll");
    defer allocator.free(path);
    try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = path, .data =
        \\define i32 @bad(ptr %p) {
        \\entry:
        \\  %v = atomicrmw add ptr %p, i32 1 unordered
        \\  ret i32 %v
        \\}
        \\
    });
    const argv = [_][]const u8{ "zig", "build", "run", "--", path };
    if (!try common.runExpectFailure(allocator, io, &argv)) {
        try common.validationError(io, "expected unsupported atomic ordering case to fail\n", .{});
    }
}

fn runExecutionCase(allocator: std.mem.Allocator, io: std.Io, temp: common.TempDir) !void {
    const path = try temp.join(allocator, "execute_main.ll");
    defer allocator.free(path);
    const optimized = try temp.join(allocator, "execute_main.opt.ll");
    defer allocator.free(optimized);

    try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = path, .data =
        \\define i32 @main() {
        \\entry:
        \\  %x = add i32 42, 0
        \\  ret i32 %x
        \\}
        \\
    });

    const z_argv = [_][]const u8{ "zig", "build", "run", "--", "--passes=instcombine,dce", path };
    try common.runToFile(allocator, io, &z_argv, "zig build run", optimized);

    const lli_argv = [_][]const u8{ "lli-22", optimized };
    const result = try std.process.run(allocator, io, .{
        .argv = &lli_argv,
        .stdout_limit = .limited(1024 * 1024),
        .stderr_limit = .limited(1024 * 1024),
    });
    defer common.freeRunResult(allocator, result);
    const status = switch (result.term) {
        .exited => |code| code,
        else => 255,
    };
    if (status != 42) {
        try common.validationError(io, "expected lli-22 exit status 42, got {}\n", .{status});
    }
}
