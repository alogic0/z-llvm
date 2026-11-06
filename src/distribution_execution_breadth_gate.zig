//! Focused execution and negative controls for the added compiler-core members.
const std = @import("std");
const breadth = @import("distribution_execution_breadth.zig");
const cohort = @import("distribution_execution_cohort_v1.zig");
const gate = @import("distribution_real_rows_gate.zig");
const air = @import("zig_air_export.zig");
const u = @import("validation").common;
const Runner = @import("validation").Runner;

pub fn main(init: std.process.Init) !void {
    var c = try u.Context.init(init);
    u.installSignals();
    const argv = try init.minimal.args.toSlice(c.a);
    const args = try u.Args.parse(c.a, argv[1..], &.{ "output-root", "zig-emitter" }, &.{});
    const output = try c.newOutput(try args.require("output-root"));
    const emitter = args.get("zig-emitter") orelse cohort.external_repository_root ++ "/build/stage4/bin/zig";
    const sources = try cohort.readCurrentSources(c.a, c.io, 8 * 1024 * 1024);
    try sources.validate();
    var runner = Runner.init(&c, output);
    var env = try c.env.clone(c.a);
    try env.put("ZIG_LOCAL_CACHE_DIR", try c.join(&.{ output, "local-cache" }));
    try env.put("ZIG_GLOBAL_CACHE_DIR", try c.join(&.{ output, "global-cache" }));
    var rows = u.array(c.a);
    var negative_controls: i64 = 0;
    inline for (.{ "ReleaseFast", "ReleaseSafe", "ReleaseSmall" }) |mode| {
        for (std.enums.values(breadth.Member)) |member| {
            const root = try c.newOutput(try c.join(&.{ output, mode, @tagName(member) }));
            const descriptor = member.fixture(mode);
            var parsed = try air.parse(c.a, descriptor);
            defer parsed.deinit();
            try breadth.validateDescriptor(c.a, member, parsed.functions[0]);
            const outcome = try gate.lowerOracleFunctionToObject(c.a, descriptor);
            const object = switch (outcome) {
                .success => |bytes| bytes,
                .failure => |failure| return c.fail("{s}: {s}: {s}", .{ member.functionName(), failure.stage, failure.diagnostic }),
            };
            const object_path = try c.join(&.{ root, "subject.o" });
            try c.write(object_path, object);
            const reference_source = try c.join(&.{ root, "reference.zig" });
            const linked_source = try c.join(&.{ root, "linked.zig" });
            try c.write(reference_source, member.referenceHarness());
            try c.write(linked_source, member.linkedHarness());
            const optimize = "-O" ++ mode;
            const reference = try c.join(&.{ root, "reference" });
            const linked = try c.join(&.{ root, "linked" });
            try runner.require(&.{ emitter, "build-exe", reference_source, optimize, try c.fmt("-femit-bin={s}", .{reference}) }, try c.join(&.{ root, "reference-build" }), &env);
            try runner.require(&.{ emitter, "build-exe", "-fno-lld", linked_source, object_path, optimize, try c.fmt("-femit-bin={s}", .{linked}) }, try c.join(&.{ root, "linked-build" }), &env);
            try runner.observe(reference, &.{}, 0, member.expectedStdout(), try c.join(&.{ root, "reference-run" }), &env);
            try runner.observe(linked, &.{}, 0, member.expectedStdout(), try c.join(&.{ root, "linked-run" }), &env);
            for ([_][]const u8{ "wrong-result", "wrong-symbol", "memory-clobber" }) |control| {
                if (std.mem.eql(u8, control, "memory-clobber") and member != .mutex_try_lock) continue;
                const ir_path = try c.join(&.{ root, try c.fmt("{s}.ll", .{control}) });
                const bad_object = try c.join(&.{ root, try c.fmt("{s}.o", .{control}) });
                const bad_exe = try c.join(&.{ root, control });
                try c.write(ir_path, try negativeIR(&c, member, control));
                try runner.require(&.{ "clang-22", "-x", "ir", "-c", ir_path, "-o", bad_object }, try c.fmt("{s}-object", .{bad_exe}), &env);
                const build = try runner.run(&.{ emitter, "build-exe", "-fno-lld", linked_source, bad_object, optimize, try c.fmt("-femit-bin={s}", .{bad_exe}) }, try c.fmt("{s}-build", .{bad_exe}), &env, .{});
                if (std.mem.eql(u8, control, "wrong-symbol")) {
                    if (build.code == 0 or std.mem.indexOf(u8, try c.read(try c.fmt("{s}-build.stderr", .{bad_exe})), member.functionName()) == null) return error.WrongSymbolControlFailed;
                } else {
                    if (build.code != 0) return error.NegativeHarnessBuildFailed;
                    const run = try runner.run(&.{bad_exe}, try c.fmt("{s}-run", .{bad_exe}), &env, .{ .timeout_ms = 5000 });
                    // An explicit oracle error is required; a crash/timeout is
                    // not evidence that the semantic check rejected the bug.
                    if (run.code != 1 or std.mem.indexOf(u8, try c.read(try c.fmt("{s}-run.stderr", .{bad_exe})), "OracleMismatch") == null) return error.NegativeOracleControlFailed;
                }
                negative_controls += 1;
            }
            var row = u.object(c.a);
            try u.put(c.a, &row, "mode", u.s(mode));
            try u.put(c.a, &row, "function", u.s(member.functionName()));
            try u.put(c.a, &row, "observations", u.n(member.observations()));
            try u.put(c.a, &row, "object_sha256", u.s(try c.digest(object_path)));
            try u.put(c.a, &row, "status", u.s("passed"));
            try u.add(&rows, row);
        }
    }
    var report = u.object(c.a);
    try u.put(c.a, &report, "schema", u.s("execution-breadth-controls-v1"));
    try u.put(c.a, &report, "rows", rows);
    try u.put(c.a, &report, "negative_controls", u.n(negative_controls));
    try u.put(c.a, &report, "status", u.s("passed"));
    try c.writeJson(try c.join(&.{ output, "report.json" }), report);
    try c.print("execution-breadth-controls function_modes=12 observations=15012 negative_controls={d} local_fail=0\n", .{negative_controls});
}

fn negativeIR(c: *u.Context, member: breadth.Member, control: []const u8) ![]const u8 {
    const symbol = if (std.mem.eql(u8, control, "wrong-symbol")) "wrong_execution_breadth_symbol" else member.functionName();
    if (std.mem.eql(u8, control, "memory-clobber")) return c.fmt("target triple = \"x86_64-unknown-linux-gnu\"\ndefine i1 @\"{s}\"(ptr %state) {{\n  %guard = getelementptr i8, ptr %state, i64 -1\n  store i8 0, ptr %guard\n  %old = atomicrmw xchg ptr %state, i8 1 acquire\n  %result = icmp eq i8 %old, 0\n  ret i1 %result\n}}\n", .{symbol});
    const signature: []const u8 = switch (member) {
        .dynamic_mask_index => "i64",
        .mutex_try_lock => "ptr",
        else => "i8",
    };
    const result: []const u8 = if (member == .dynamic_mask_index) "i64 0" else "i1 false";
    const ty: []const u8 = if (member == .dynamic_mask_index) "i64" else "i1";
    return c.fmt("target triple = \"x86_64-unknown-linux-gnu\"\ndefine {s} @\"{s}\"({s} %arg) {{\n  ret {s}\n}}\n", .{ ty, symbol, signature, result });
}
