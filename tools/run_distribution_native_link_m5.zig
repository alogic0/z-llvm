const std = @import("std");
const common = @import("tool_common.zig");

const Case = struct {
    id: []const u8,
    fixture: []const u8,
    harness: []const u8,
    panic_stub: bool = false,
};

const cases = [_]Case{
    .{
        .id = "releasefast_tiny_scalar",
        .fixture = "test/distribution/releasefast_x86_64/inputs/tiny_scalar.ll",
        .harness =
        \\extern int add(int a, int b);
        \\int main(void) {
        \\    if (add(40, 2) != 42) return 1;
        \\    if (add(-7, 9) != 2) return 2;
        \\    return 0;
        \\}
        \\
        ,
    },
    .{
        .id = "releasefast_add_wrap",
        .fixture = "test/distribution/releasefast_x86_64/inputs/integers_add_wrap.ll",
        .harness =
        \\extern int add_wrap(int a, int b);
        \\int main(void) {
        \\    if (add_wrap(2147483647, 1) != -2147483648) return 1;
        \\    if (add_wrap(-5, 12) != 7) return 2;
        \\    return 0;
        \\}
        \\
        ,
    },
    .{
        .id = "releasefast_comptime_const",
        .fixture = "test/distribution/releasefast_x86_64/inputs/globals_comptime_const.ll",
        .harness =
        \\extern int comptime_const(int value);
        \\int main(void) {
        \\    if (comptime_const(7) != 35) return 1;
        \\    if (comptime_const(-3) != -15) return 2;
        \\    return 0;
        \\}
        \\
        ,
    },
    .{
        .id = "releasesafe_checked_add",
        .fixture = "test/distribution/releasesafe_x86_64/inputs/tiny_scalar_checked_add.ll",
        .panic_stub = true,
        .harness =
        \\extern int add(int a, int b);
        \\int main(void) {
        \\    if (add(40, 2) != 42) return 1;
        \\    if (add(-7, 9) != 2) return 2;
        \\    return 0;
        \\}
        \\
        ,
    },
    .{
        .id = "releasesmall_i64_return",
        .fixture = "test/distribution/releasesmall_x86_64/inputs/inherit_want_safety_i64_return.ll",
        .harness =
        \\extern long entry(void);
        \\int main(void) {
        \\    return entry() == 4 ? 0 : 1;
        \\}
        \\
        ,
    },
};

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;

    const target_env = try common.getEnvOwnedOrNull(allocator, init.minimal.environ, "TARGET");
    defer if (target_env) |value| allocator.free(value);
    const cc_target_env = try common.getEnvOwnedOrNull(allocator, init.minimal.environ, "CC_TARGET");
    defer if (cc_target_env) |value| allocator.free(value);
    const target = target_env orelse "x86_64-unknown-linux-gnu";
    const cc_target = cc_target_env orelse defaultCcTarget(target);

    const temp = try common.TempDir.init(allocator, io, "distribution_native_link_m5");
    defer temp.deinit(allocator, io);

    var stdout_buffer: [512]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
    for (cases) |case| {
        try runCase(allocator, io, temp, target, cc_target, case);
        try stdout_writer.interface.print("ok distribution native-link {s}\n", .{case.id});
        try stdout_writer.interface.flush();
    }
}

fn runCase(
    allocator: std.mem.Allocator,
    io: std.Io,
    temp: common.TempDir,
    target: []const u8,
    cc_target: []const u8,
    case: Case,
) !void {
    const object = try common.allocTempFile(allocator, temp, case.id, ".o");
    defer allocator.free(object);
    const harness_c = try common.allocTempFile(allocator, temp, case.id, "_harness.c");
    defer allocator.free(harness_c);
    const harness_o = try common.allocTempFile(allocator, temp, case.id, "_harness.o");
    defer allocator.free(harness_o);
    const exe = try common.allocTempFile(allocator, temp, case.id, "_native_link");
    defer allocator.free(exe);

    const target_arg = try std.fmt.allocPrint(allocator, "--target={s}", .{target});
    defer allocator.free(target_arg);
    const emit_argv = [_][]const u8{ "zig", "build", "run", "--", "--emit=obj", target_arg, "--input-limit=67108864", case.fixture };
    try common.runToFile(allocator, io, &emit_argv, "zig build run", object);

    try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = harness_c, .data = case.harness });
    const cc_argv = [_][]const u8{ "zig", "cc", "-target", cc_target, "-c", harness_c, "-o", harness_o };
    const cc_result = try common.runCapture(allocator, io, &cc_argv, "zig cc -c");
    common.freeRunResult(allocator, cc_result);

    var link_args: std.ArrayList([]const u8) = .empty;
    defer link_args.deinit(allocator);
    const emit_bin_arg = try std.fmt.allocPrint(allocator, "-femit-bin={s}", .{exe});
    defer allocator.free(emit_bin_arg);
    try link_args.appendSlice(allocator, &.{ "zig", "build-exe", "-target", cc_target, "-fno-lld", harness_o, object });
    var panic_stub_o: ?[]const u8 = null;
    defer if (panic_stub_o) |path| allocator.free(path);
    if (case.panic_stub) {
        const panic_stub_s = try common.allocTempFile(allocator, temp, case.id, "_panic_stub.s");
        defer allocator.free(panic_stub_s);
        const panic_object = try common.allocTempFile(allocator, temp, case.id, "_panic_stub.o");
        panic_stub_o = panic_object;
        try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = panic_stub_s, .data =
            \\.text
            \\.globl "debug.FullPanic((function 'defaultPanic')).integerOverflow"
            \\.type "debug.FullPanic((function 'defaultPanic')).integerOverflow", @function
            \\"debug.FullPanic((function 'defaultPanic')).integerOverflow":
            \\  ud2
            \\
        });
        const asm_argv = [_][]const u8{ "zig", "cc", "-target", cc_target, "-c", panic_stub_s, "-o", panic_object };
        const asm_result = try common.runCapture(allocator, io, &asm_argv, "zig cc -c panic stub");
        common.freeRunResult(allocator, asm_result);
        try link_args.append(allocator, panic_object);
    }
    try link_args.appendSlice(allocator, &.{ "-lc", emit_bin_arg });

    const link_result = try common.runCapture(allocator, io, link_args.items, "zig build-exe -fno-lld");
    common.freeRunResult(allocator, link_result);

    const run_argv = [_][]const u8{exe};
    const run_result = try common.runCapture(allocator, io, &run_argv, exe);
    common.freeRunResult(allocator, run_result);
}

fn defaultCcTarget(target: []const u8) []const u8 {
    if (std.mem.eql(u8, target, "x86_64-unknown-linux-gnu")) return "x86_64-linux-gnu";
    if (std.mem.eql(u8, target, "x86_64-unknown-linux-musl")) return "x86_64-linux-musl";
    return target;
}
