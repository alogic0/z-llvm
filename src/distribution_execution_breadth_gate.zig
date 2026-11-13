//! Focused execution and negative controls for the added compiler-core members.
const std = @import("std");
const breadth = @import("distribution_execution_breadth.zig");
const cohort = @import("distribution_execution_cohort_v1.zig");
const gate = @import("distribution_real_rows_gate.zig");
const air = @import("zig_air_export.zig");
const u = @import("validation").common;
const Runner = @import("validation").Runner;
const harnesses = @import("validation").linked_harness;
const storage = @import("validation").storage_workspace;

pub fn main(init: std.process.Init) !void {
    var c = try u.Context.init(init);
    u.installSignals();
    const argv = try init.minimal.args.toSlice(c.a);
    const args = try u.Args.parse(c.a, argv[1..], &.{ "output-root", "zig-emitter", "mode" }, &.{"fresh-harness"});
    const output = try c.newOutput(try args.require("output-root"));
    const workspace = try storage.start(&c, output, "validation");
    defer if (workspace) |w| w.close(&c);
    const emitter = args.get("zig-emitter") orelse cohort.external_repository_root ++ "/build/stage4/bin/zig";
    const emitter_identity = try harnesses.emitterIdentity(&c, emitter);
    if (args.get("mode")) |mode| if (!u.contains(&u.modes, mode)) return error.InvalidMode;
    const sources = try cohort.readCurrentSources(c.a, c.io, 8 * 1024 * 1024);
    try sources.validate();
    var runner = Runner.init(&c, output);
    var env = try c.env.clone(c.a);
    try env.put("ZIG_LOCAL_CACHE_DIR", try c.temporaryPath(&.{ output, "local-cache" }));
    try env.put("ZIG_GLOBAL_CACHE_DIR", try c.temporaryPath(&.{ output, "global-cache" }));
    var rows = u.array(c.a);
    var negative_controls: i64 = 0;
    var observations: usize = 0;
    var function_modes: usize = 0;
    inline for (.{ "ReleaseFast", "ReleaseSafe", "ReleaseSmall" }) |mode| {
        if (args.get("mode") == null or std.mem.eql(u8, mode, args.get("mode").?)) {
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
                const object_path = try c.temporaryPath(&.{ root, "subject.o" });
                try c.write(object_path, object);
                const reference_source = try c.join(&.{ root, "reference.zig" });
                const linked_source = try c.join(&.{ root, "linked.zig" });
                try c.write(reference_source, member.referenceHarness());
                try c.write(linked_source, member.linkedHarness());
                const optimize = "-O" ++ mode;
                const reference = try c.temporaryPath(&.{ root, "reference" });
                const linked = try c.temporaryPath(&.{ root, "linked" });
                try runner.require(&.{ emitter, "build-exe", reference_source, optimize, try c.fmt("-femit-bin={s}", .{reference}) }, try c.join(&.{ root, "reference-build" }), &env);
                const harness: ?harnesses.Compiled = if (args.flag("fresh-harness")) null else try harnesses.compile(&runner, root, linked_source, mode, emitter_identity, &env);
                const linked_command: []const []const u8 = if (harness) |h| try h.linkCommand(&c, object_path, linked) else &.{ emitter, "build-exe", "-fno-lld", linked_source, object_path, optimize, try c.fmt("-femit-bin={s}", .{linked}) };
                try runner.require(linked_command, try c.join(&.{ root, "linked-build" }), &env);
                try runner.observe(reference, &.{}, 0, member.expectedStdout(), try c.join(&.{ root, "reference-run" }), &env);
                try runner.observe(linked, &.{}, 0, member.expectedStdout(), try c.join(&.{ root, "linked-run" }), &env);
                for ([_][]const u8{ "wrong-result", "wrong-symbol", "memory-clobber", "high-half-loss" }) |control| {
                    if (std.mem.eql(u8, control, "memory-clobber") and !member.hasMemoryGuard()) continue;
                    if (std.mem.eql(u8, control, "high-half-loss") and !member.isPacked()) continue;
                    const ir_path = try c.join(&.{ root, try c.fmt("{s}.ll", .{control}) });
                    const bad_object = try c.temporaryPath(&.{ root, try c.fmt("{s}.o", .{control}) });
                    const bad_exe = try c.temporaryPath(&.{ root, control });
                    const log_stem = try c.join(&.{ root, control });
                    try c.write(ir_path, try negativeIR(&c, member, control));
                    try runner.require(&.{ "clang-22", "-x", "ir", "-c", ir_path, "-o", bad_object }, try c.fmt("{s}-object", .{log_stem}), &env);
                    const negative_command: []const []const u8 = if (harness) |h| try h.linkCommand(&c, bad_object, bad_exe) else &.{ emitter, "build-exe", "-fno-lld", linked_source, bad_object, optimize, try c.fmt("-femit-bin={s}", .{bad_exe}) };
                    const build = try runner.run(negative_command, try c.fmt("{s}-build", .{log_stem}), &env, .{});
                    if (std.mem.eql(u8, control, "wrong-symbol")) {
                        const diagnostic = try c.read(try c.fmt("{s}-build.stderr", .{log_stem}));
                        if (!build.completed or build.code == 0 or std.mem.indexOf(u8, diagnostic, "undefined symbol") == null or std.mem.indexOf(u8, diagnostic, member.functionName()) == null) return error.WrongSymbolControlFailed;
                    } else {
                        if (build.code != 0) return error.NegativeHarnessBuildFailed;
                        const run = try runner.run(&.{bad_exe}, try c.fmt("{s}-run", .{log_stem}), &env, .{ .timeout_ms = 5000 });
                        // An explicit oracle error is required; a crash/timeout is
                        // not evidence that the semantic check rejected the bug.
                        if (!run.completed or run.code != 1 or std.mem.indexOf(u8, try c.read(try c.fmt("{s}-run.stderr", .{log_stem})), "OracleMismatch") == null) return error.NegativeOracleControlFailed;
                    }
                    negative_controls += 1;
                }
                var row = u.object(c.a);
                try u.put(c.a, &row, "mode", u.s(mode));
                try u.put(c.a, &row, "function", u.s(member.functionName()));
                try u.put(c.a, &row, "observations", u.n(member.observations()));
                try u.put(c.a, &row, "object_sha256", u.s(try c.digest(object_path)));
                if (harness) |h| {
                    try h.verify(&c);
                    try u.put(c.a, &row, "harness", try h.identity(&c));
                }
                try u.put(c.a, &row, "status", u.s("passed"));
                try u.add(&rows, row);
                observations += member.observations();
                function_modes += 1;
            }
        }
    }
    var report = u.object(c.a);
    if (!u.json.eql(emitter_identity, try harnesses.emitterIdentity(&c, emitter))) return error.HarnessEmitterChanged;
    try u.put(c.a, &report, "schema", u.s("execution-breadth-controls-v2"));
    try u.put(c.a, &report, "rows", rows);
    try u.put(c.a, &report, "harness_reuse", u.b(!args.flag("fresh-harness")));
    try u.put(c.a, &report, "emitter", emitter_identity);
    try u.put(c.a, &report, "negative_controls", u.n(negative_controls));
    try u.put(c.a, &report, "function_modes", u.n(function_modes));
    try u.put(c.a, &report, "observations", u.n(observations));
    try u.put(c.a, &report, "status", u.s("passed"));
    try c.writeJson(try c.join(&.{ output, "report.json" }), report);
    if (workspace) |w| try w.finishReport(&c);
    try c.print("execution-breadth-controls function_modes={d} observations={d} negative_controls={d} local_fail=0\n", .{ function_modes, observations, negative_controls });
}

fn negativeIR(c: *u.Context, member: breadth.Member, control: []const u8) ![]const u8 {
    const symbol = if (std.mem.eql(u8, control, "wrong-symbol")) "wrong_execution_breadth_symbol" else member.functionName();
    if (member == .event_reset) {
        const effect: []const u8 = if (std.mem.eql(u8, control, "memory-clobber"))
            "store i32 0, ptr %arg\n  %guard = getelementptr i8, ptr %arg, i64 -1\n  store i8 0, ptr %guard"
        else
            "store i32 1, ptr %arg";
        return c.fmt("target triple = \"x86_64-unknown-linux-gnu\"\ndefine void @\"{s}\"(ptr %arg) {{\n  {s}\n  ret void\n}}\n", .{ symbol, effect });
    }
    if (member.isPacked()) {
        const body: []const u8 = if (std.mem.eql(u8, control, "high-half-loss"))
            "%low = trunc i64 %arg to i32\n  %result = zext i32 %low to i64\n  ret i64 %result"
        else
            "ret i64 0";
        return c.fmt("target triple = \"x86_64-unknown-linux-gnu\"\ndefine i64 @\"{s}\"(i64 %arg) {{\n  {s}\n}}\n", .{ symbol, body });
    }
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
