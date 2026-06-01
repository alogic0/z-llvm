const std = @import("std");
const common = @import("tool_common.zig");

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;

    const target_env = try common.getEnvOwnedOrNull(allocator, init.minimal.environ, "TARGET");
    defer if (target_env) |value| allocator.free(value);
    const cc_target_env = try common.getEnvOwnedOrNull(allocator, init.minimal.environ, "CC_TARGET");
    defer if (cc_target_env) |value| allocator.free(value);
    const target = target_env orelse "x86_64-unknown-linux-gnu";
    const cc_target = cc_target_env orelse defaultCcTarget(target);

    const temp = try common.TempDir.init(allocator, io, "debug_executable_m4");
    defer temp.deinit(allocator, io);

    const fixture = "test/distribution/debug_x86_64/inputs/shared_library_mathtest_add_o0.ll";
    const object = try temp.join(allocator, "shared_library_mathtest_add_o0.o");
    defer allocator.free(object);
    const harness = try temp.join(allocator, "shared_library_mathtest_add_o0_harness.c");
    defer allocator.free(harness);
    const panic_stub = try temp.join(allocator, "debug_panic_stub.s");
    defer allocator.free(panic_stub);
    const exe = try temp.join(allocator, "shared_library_mathtest_add_o0_harness");
    defer allocator.free(exe);

    const target_arg = try std.fmt.allocPrint(allocator, "--target={s}", .{target});
    defer allocator.free(target_arg);
    const emit_argv = [_][]const u8{ "zig", "build", "run", "--", "--emit=obj", target_arg, "--input-limit=67108864", fixture };
    try common.runToFile(allocator, io, &emit_argv, "zig build run", object);

    try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = harness, .data =
        \\extern int add(int a, int b);
        \\
        \\int main(void) {
        \\    if (add(40, 2) != 42) return 1;
        \\    if (add(-7, 9) != 2) return 2;
        \\    return 0;
        \\}
        \\
    });
    try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = panic_stub, .data =
        \\.text
        \\.globl "debug.FullPanic((function 'defaultPanic')).integerOverflow"
        \\.type "debug.FullPanic((function 'defaultPanic')).integerOverflow", @function
        \\"debug.FullPanic((function 'defaultPanic')).integerOverflow":
        \\  ud2
        \\
    });

    const cc_argv = [_][]const u8{ "zig", "cc", "-target", cc_target, harness, panic_stub, object, "-o", exe };
    const cc_result = try common.runCapture(allocator, io, &cc_argv, "zig cc");
    common.freeRunResult(allocator, cc_result);

    const run_argv = [_][]const u8{exe};
    const run_result = try common.runCapture(allocator, io, &run_argv, exe);
    common.freeRunResult(allocator, run_result);

    var stdout_buffer: [256]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
    try stdout_writer.interface.writeAll("ok distribution debug executable shared_library_mathtest_add_o0\n");
    try stdout_writer.interface.flush();
}

fn defaultCcTarget(target: []const u8) []const u8 {
    if (std.mem.eql(u8, target, "x86_64-unknown-linux-gnu")) return "x86_64-linux-gnu";
    if (std.mem.eql(u8, target, "x86_64-unknown-linux-musl")) return "x86_64-linux-musl";
    return target;
}
