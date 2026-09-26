const std = @import("std");
const common = @import("tool_common.zig");

pub fn main(init: std.process.Init) !void {
    try runCase(init, "test/opt/inputs/optimizer_correctness.ll", "test/opt/optimizer_correctness_harness.c", &.{ "early-cse,instcombine,licm,sccp,globalopt", "release-o3" }, "optimizer correctness", "functions=17");
    try runCase(init, "test/opt/inputs/globaldce_references.ll", "test/opt/globaldce_references_harness.c", &.{ "globaldce", "adce", "release-o3" }, "GlobalDCE references", "entry_points=5");
    try runCase(init, "test/opt/inputs/adce_operands.ll", "test/opt/adce_operands_harness.c", &.{ "adce", "release-o3" }, "ADCE vector operands", "observations=156");
}

fn runCase(init: std.process.Init, fixture: []const u8, harness: []const u8, pipelines: []const []const u8, label: []const u8, count: []const u8) !void {
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
    for (pipelines) |pipeline| {
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
        try out.interface.print("ok {s} pipeline={s} {s}\n", .{ label, pipeline, count });
        try out.interface.flush();
    }
    success = true;
}

fn checked(init: std.process.Init, argv: []const []const u8) !void {
    const result = try common.runCapture(init.gpa, init.io, argv, argv[0]);
    defer common.freeRunResult(init.gpa, result);
}
