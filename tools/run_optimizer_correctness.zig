const std = @import("std");
const common = @import("tool_common.zig");

pub fn main(init: std.process.Init) !void {
    var buffer: [4096]u8 = undefined;
    var out = std.Io.File.stdout().writer(init.io, &buffer);
    try runCalibratedCase(init, &out.interface, "test/opt/inputs/fast_math_cancellation.ll", "test/opt/fast_math_cancellation_harness.c", &.{ "instcombine,dce", "zig-release-safe-accepted", "zig-release-fast-accepted", "zig-release-small-accepted" }, "fastmath cancellation", "functions=9 observations=5120", 4);
    try runCase(init, &out.interface, "test/opt/inputs/extended_fneg.ll", "test/opt/extended_fneg_harness.c", &.{ "zig-release-safe-accepted", "zig-release-fast-accepted", "zig-release-small-accepted" }, "extended fneg serialization", "functions=4 observations=1056");
    try runCase(init, &out.interface, "test/opt/inputs/numeric_local_names.ll", "test/opt/numeric_local_names_harness.c", &.{ "simplifycfg", "instcombine,dce,simplifycfg", "release-o3" }, "numeric local serialization", "functions=10 observations=160");
    try runCase(init, &out.interface, "test/opt/inputs/optimizer_checkpoint.ll", "test/opt/optimizer_checkpoint_harness.c", &.{ "instcombine", "constmerge", "vector-combine", "release-o3" }, "correctness checkpoint", "functions=11 observations=1640 seed=5eed1234");
    try runCase(init, &out.interface, "test/opt/inputs/optimizer_review_boundaries.ll", "test/opt/optimizer_review_boundaries_harness.c", &.{ "instcombine,dce", "release-o3" }, "optimizer review boundaries", "functions=7 observations=134");
    try runCase(init, &out.interface, "test/opt/inputs/optimizer_correctness.ll", "test/opt/optimizer_correctness_harness.c", &.{ "early-cse,instcombine,licm,sccp,globalopt", "release-o3" }, "optimizer correctness", "functions=17");
    try runCase(init, &out.interface, "test/opt/inputs/globaldce_references.ll", "test/opt/globaldce_references_harness.c", &.{ "globaldce", "adce", "release-o3" }, "GlobalDCE references", "entry_points=5");
    try runCase(init, &out.interface, "test/opt/inputs/symbol_spelling.ll", "test/opt/symbol_spelling_harness.c", &.{ "globaldce", "globalopt", "release-o3" }, "symbol spelling", "entry_points=5 input_cases=16");
    try runCase(init, &out.interface, "test/opt/inputs/reference_attributes.ll", "test/opt/reference_attributes_harness.c", &.{ "globaldce", "globalopt", "constmerge", "globalopt,constmerge,globaldce", "release-o3" }, "reference attributes", "entry_points=5 input_cases=16");
    try runCase(init, &out.interface, "test/opt/inputs/reference_metadata.ll", "test/opt/reference_metadata_harness.c", &.{ "globaldce", "globalopt", "constmerge", "globalopt,constmerge,globaldce", "release-o3" }, "reference metadata", "entry_points=5 input_cases=16");
    try runCase(init, &out.interface, "test/opt/inputs/adce_operands.ll", "test/opt/adce_operands_harness.c", &.{ "adce", "release-o3" }, "ADCE vector operands", "observations=156");
}

fn runCase(init: std.process.Init, out: *std.Io.Writer, fixture: []const u8, harness: []const u8, pipelines: []const []const u8, label: []const u8, count: []const u8) !void {
    return runCalibratedCase(init, out, fixture, harness, pipelines, label, count, 0);
}

fn runCalibratedCase(init: std.process.Init, out: *std.Io.Writer, fixture: []const u8, harness: []const u8, pipelines: []const []const u8, label: []const u8, count: []const u8, faults: u16) !void {
    const a = init.gpa;
    const io = init.io;
    const temp = try optimizerTemp(init);
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
    try calibrate(init, out, reference, label, "reference", faults);
    const optimizer = try common.resolveZllvm(init);
    defer a.free(optimizer);

    for (pipelines) |pipeline| {
        const optimized = try common.allocTempFile(a, temp, pipeline, ".ll");
        defer a.free(optimized);
        const executable = try common.allocTempFile(a, temp, pipeline, ".exe");
        defer a.free(executable);
        const option = try std.fmt.allocPrint(a, "--passes={s}", .{pipeline});
        defer a.free(option);
        try common.runToFile(a, io, &.{ optimizer, option, fixture }, "optimizer regression pipeline", optimized);
        try checked(init, &.{ "opt-22", "-passes=verify", "-disable-output", optimized });
        // Keep LLVM's optimizing passes out of the transformed-IR execution.
        try checked(init, &.{ "clang-22", "-Wno-override-module", "-O0", optimized, harness, "-o", executable });
        const actual = try common.runCapture(a, io, &.{executable}, "optimized IR execution");
        defer common.freeRunResult(a, actual);
        if (!std.mem.eql(u8, expected.stdout, actual.stdout) or
            !std.mem.eql(u8, expected.stderr, actual.stderr)) return error.OptimizerExecutionMismatch;
        try calibrate(init, out, executable, label, pipeline, faults);
        try out.print("ok {s} pipeline={s} {s}\n", .{ label, pipeline, count });
        try out.flush();
    }
    success = true;
}

fn optimizerTemp(init: std.process.Init) !common.TempDir {
    const root = init.environ_map.get("ZLLVM_TEMP_ROOT") orelse
        return common.TempDir.init(init.gpa, init.io, "optimizer_correctness");
    const path = try std.fmt.allocPrint(init.gpa, "{s}/optimizer_correctness_{d}", .{ root, std.os.linux.getpid() });
    errdefer init.gpa.free(path);
    try std.Io.Dir.cwd().createDirPath(init.io, path);
    return .{ .path = path };
}

fn calibrate(init: std.process.Init, out: *std.Io.Writer, executable: []const u8, label: []const u8, pipeline: []const u8, faults: u16) !void {
    for (1..@as(usize, faults) + 1) |fault| {
        const text = try std.fmt.allocPrint(init.gpa, "{d}", .{fault});
        defer init.gpa.free(text);
        const marker = try std.fmt.allocPrint(init.gpa, "fault={d}", .{fault});
        defer init.gpa.free(marker);
        const result = try std.process.run(init.gpa, init.io, .{
            .argv = &.{ executable, text },
            .stdout_limit = .limited(4096),
            .stderr_limit = .limited(4096),
        });
        defer common.freeRunResult(init.gpa, result);
        // The shared detector uses completion, exit status and streams;
        // this standalone capture does not make a timing claim.
        if (!@import("validation/native_faults.zig").detected(.{
            .code = switch (result.term) {
                .exited => |code| @as(i64, code),
                else => -1,
            },
            .completed = result.term == .exited,
            .wall_ns = 0,
        }, result.stdout, result.stderr, marker)) return error.OptimizerOracleMissedFault;
        try out.print("ok {s} oracle pipeline={s} fault={d}\n", .{ label, pipeline, fault });
        try out.flush();
    }
}

fn checked(init: std.process.Init, argv: []const []const u8) !void {
    const result = try common.runCapture(init.gpa, init.io, argv, argv[0]);
    defer common.freeRunResult(init.gpa, result);
}
