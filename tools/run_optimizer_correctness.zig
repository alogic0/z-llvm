const std = @import("std");
const common = @import("tool_common.zig");

const fixture = "test/opt/inputs/optimizer_correctness.ll";
const harness = "test/opt/optimizer_correctness_harness.c";

pub fn main(init: std.process.Init) !void {
    const a = init.gpa;
    const io = init.io;
    const temp = try common.TempDir.init(a, io, "optimizer_correctness");
    var success = false;
    defer if (success) temp.deinit(a, io) else {
        std.debug.print("optimizer regression artifacts: {s}\n", .{temp.path});
        a.free(temp.path);
    };

    const reference = try temp.join(a, "reference");
    defer a.free(reference);
    try checked(init, &.{ "clang-22", "-Wno-override-module", "-O2", fixture, harness, "-o", reference });
    const expected = try common.runCapture(a, io, &.{reference}, "optimizer reference execution");
    defer common.freeRunResult(a, expected);

    var buffer: [4096]u8 = undefined;
    var out = std.Io.File.stdout().writer(io, &buffer);
    for ([_][]const u8{ "early-cse,instcombine,licm,sccp,globalopt", "release-o3" }) |pipeline| {
        const optimized = try common.allocTempFile(a, temp, pipeline, ".ll");
        defer a.free(optimized);
        const executable = try common.allocTempFile(a, temp, pipeline, ".exe");
        defer a.free(executable);
        const option = try std.fmt.allocPrint(a, "--passes={s}", .{pipeline});
        defer a.free(option);
        try common.runToFile(a, io, &.{ "zig", "build", "run", "--", option, fixture }, "optimizer regression pipeline", optimized);
        try checked(init, &.{ "opt-22", "-passes=verify", "-disable-output", optimized });
        // Keep LLVM's optimizing passes out of the transformed-IR execution.
        try checked(init, &.{ "clang-22", "-Wno-override-module", "-O0", optimized, harness, "-o", executable });
        const actual = try common.runCapture(a, io, &.{executable}, "optimized IR execution");
        defer common.freeRunResult(a, actual);
        if (!std.mem.eql(u8, expected.stdout, actual.stdout) or
            !std.mem.eql(u8, expected.stderr, actual.stderr)) return error.OptimizerExecutionMismatch;
        try out.interface.print("ok optimizer correctness pipeline={s} functions=16\n", .{pipeline});
        try out.interface.flush();
    }
    success = true;
}

fn checked(init: std.process.Init, argv: []const []const u8) !void {
    const result = try common.runCapture(init.gpa, init.io, argv, argv[0]);
    defer common.freeRunResult(init.gpa, result);
}
