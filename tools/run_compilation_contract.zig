//! Exercise the public CLI routes as well as the shared preparation API tests.
const std = @import("std");
const u = @import("validation/common.zig");
const Runner = @import("validation/runner.zig").Runner;
const TempDir = @import("tool_common.zig").TempDir;

pub fn main(init: std.process.Init) !void {
    var c = try u.Context.init(init);
    u.installSignals();
    const argv = try init.minimal.args.toSlice(c.a);
    const args = try u.Args.parse(c.a, argv[1..], &.{ "output-root", "zllvm" }, &.{});
    const temp: ?TempDir = if (args.get("output-root") == null) try .init(c.a, c.io, "compilation_contract") else null;
    defer if (temp) |directory| directory.deinit(c.a, c.io);
    const output = if (temp) |directory| try c.join(&.{directory.path}) else try c.newOutput(args.get("output-root").?);
    var runner = Runner.init(&c, output);
    const compiler = try c.join(&.{args.get("zllvm") orelse "zig-out/bin/z_llvm"});
    c.env = try c.cleanEnvironment();
    var report = u.object(c.a);
    try u.put(c.a, &report, "compiler_sha256", u.s(try c.digest(compiler)));
    var passed = true;
    check(&runner, compiler) catch |err| {
        passed = false;
        try u.put(c.a, &report, "error", u.s(c.diagnostic orelse @errorName(err)));
        try c.print("compilation contract failed: {s}\n", .{c.diagnostic orelse @errorName(err)});
    };
    try u.put(c.a, &report, "status", u.s(if (passed) "passed" else "failed"));
    try c.writeJson(try c.join(&.{ output, "report.json" }), report);
    try c.print("compilation contract: {s}\n", .{if (passed) "passed" else "failed"});
    if (!passed) std.process.exit(1);
}

fn invoke(r: *Runner, compiler: []const u8, input: []const u8, options: []const []const u8, label: []const u8) ![]const u8 {
    const c = r.context;
    const argv = try c.a.alloc([]const u8, options.len + 4);
    argv[0] = compiler;
    argv[1] = "--generic-cfg-selector";
    argv[2] = "--target=x86_64-unknown-linux-gnu";
    @memcpy(argv[3..][0..options.len], options);
    argv[argv.len - 1] = input;
    const stem = try c.join(&.{ r.output, label });
    try r.require(argv, stem, &c.env);
    return c.fmt("{s}.stdout", .{stem});
}

fn same(c: *u.Context, a: []const u8, b: []const u8) !void {
    if (!std.mem.eql(u8, try c.read(a), try c.read(b))) return c.fail("route output differs: {s}, {s}", .{ a, b });
}

fn check(r: *Runner, compiler: []const u8) !void {
    const c = r.context;
    const input = try c.join(&.{ r.output, "route.ll" });
    try c.write(input,
        \\define i32 @route(i32 %x) {
        \\entry:
        \\ %unused = mul i32 %x, 17
        \\ %constant = add i32 40, 2
        \\ %answer = add i32 %x, %constant
        \\ ret i32 %answer
        \\}
        \\define i16 @fp16() {
        \\entry:
        \\ %bits = bitcast half 0xH8000 to i16
        \\ ret i16 %bits
        \\}
        \\define i32 @fp32() {
        \\entry:
        \\ %bits = bitcast float -0.000000e+00 to i32
        \\ ret i32 %bits
        \\}
        \\define i64 @fp64() {
        \\entry:
        \\ %bits = bitcast double 1.000000e+00 to i64
        \\ ret i64 %bits
        \\}
        \\define i64 @fp_nan() {
        \\entry:
        \\ %bits = bitcast double 0x7FF8000000000042 to i64
        \\ ret i64 %bits
        \\}
        \\define i64 @fp_subnormal() {
        \\entry:
        \\ %bits = bitcast double 0x0000000000000001 to i64
        \\ ret i64 %bits
        \\}
        \\define i32 @array_at(ptr %base, i64 %index) {
        \\entry:
        \\ %element = getelementptr [16 x i32], ptr %base, i64 0, i64 %index
        \\ %value = load i32, ptr %element, align 4
        \\ ret i32 %value
        \\}
        \\define i32 @array_const(ptr %base) {
        \\entry:
        \\ %element = getelementptr [16 x i32], ptr %base, i64 0, i64 5
        \\ %value = load i32, ptr %element, align 4
        \\ ret i32 %value
        \\}
        \\define i8 @byte_array_at(ptr %base, i64 %index) {
        \\entry:
        \\ %element = getelementptr [4 x i8], ptr %base, i64 0, i64 %index
        \\ %value = load i8, ptr %element, align 1
        \\ ret i8 %value
        \\}
        \\@bytes = private constant [4 x i8] c"\00\04\08\0C"
        \\define i8 @byte_array_const() {
        \\entry:
        \\ %element = getelementptr [4 x i8], ptr @bytes, i64 0, i64 3
        \\ %value = load i8, ptr %element, align 1
        \\ ret i8 %value
        \\}
        \\
    );
    const staged = try invoke(r, compiler, input, &.{"--passes=instcombine,dce"}, "optimize");
    const direct = try invoke(r, compiler, input, &.{"--emit=obj"}, "direct");
    try checkProfile(r, compiler, input, direct, "direct-profile", &.{});
    try checkFailedProfile(r, compiler);
    const limited = try invoke(r, compiler, input, &.{ "--emit=obj", "--passes=instcombine,dce", "--pass-limit=0" }, "limited");
    try same(c, direct, limited);
    for ([_][]const u8{ "obj", "asm", "selection-owner-manifest" }) |emit| {
        const option = try c.fmt("--emit={s}", .{emit});
        const prepared = try invoke(r, compiler, staged, &.{option}, try c.fmt("staged-{s}", .{emit}));
        const inline_result = try invoke(r, compiler, input, &.{ option, "--passes=instcombine,dce" }, try c.fmt("inline-{s}", .{emit}));
        try same(c, prepared, inline_result);
        if (std.mem.eql(u8, emit, "obj")) {
            try checkProfile(r, compiler, input, inline_result, "optimized-profile", &.{"--passes=instcombine,dce"});
            if (std.mem.eql(u8, try c.read(direct), try c.read(inline_result))) return error.OptimizationDidNotChangeObject;
            const traced = try invoke(r, compiler, input, &.{ option, "--passes=instcombine,dce", "--trace", "--time" }, "traced");
            try same(c, traced, inline_result);
            const diagnostics = try c.read(try c.join(&.{ r.output, "traced.stderr" }));
            if (std.mem.indexOf(u8, diagnostics, "; before instcombine") == null or std.mem.indexOf(u8, diagnostics, "; time instcombine") == null) return error.MissingPassDiagnostics;
            const driver = try c.join(&.{ r.output, "driver.c" });
            try c.write(driver,
                \\#include <stdint.h>
                \\extern int route(int);
                \\extern uint16_t fp16(void);
                \\extern uint32_t fp32(void);
                \\extern uint64_t fp64(void), fp_nan(void), fp_subnormal(void);
                \\extern int array_at(const int *, int64_t), array_const(const int *);
                \\extern uint8_t byte_array_at(const uint8_t *, int64_t), byte_array_const(void);
                \\int main(void) {
                \\  for (int i=-100; i<=100; ++i) if (route(i)!=i+42) return 1;
                \\  if (fp16()!=0x8000 || fp32()!=0x80000000U) return 2;
                \\  if (fp64()!=0x3ff0000000000000ULL || fp_nan()!=0x7ff8000000000042ULL || fp_subnormal()!=1) return 3;
                \\  int values[16]; for (int i=0; i<16; ++i) values[i]=i*7-39;
                \\  for (int i=0; i<16; ++i) if (array_at(values, i)!=values[i]) return 4;
                \\  if (array_const(values)!=values[5] || array_at(values+1, -1)!=values[0]) return 5;
                \\  const uint8_t bytes[4] = {0, 65, 128, 255};
                \\  for (int i=0; i<4; ++i) if (byte_array_at(bytes, i)!=bytes[i]) return 6;
                \\  if (byte_array_at(bytes+1, -1)!=0 || byte_array_const()!=12) return 7;
                \\  return 0;
                \\}
                \\
            );
            const object = try c.join(&.{ r.output, "route.o" });
            try c.copy(inline_result, object);
            const exe = try c.join(&.{ r.output, "route" });
            try r.require(&.{ "cc", "-no-pie", "-Wl,-z,noexecstack", driver, object, "-o", exe }, try c.join(&.{ r.output, "link" }), &c.env);
            try r.observe(exe, &.{}, 0, "", try c.join(&.{ r.output, "execute" }), &c.env);
        }
        const stem = try c.join(&.{ r.output, try c.fmt("invalid-{s}", .{emit}) });
        const failure = try r.run(&.{ compiler, option, "--passes=not-a-pass", input }, stem, &c.env, .{});
        if (failure.code == 0 or (try c.read(try c.fmt("{s}.stdout", .{stem}))).len != 0 or std.mem.indexOf(u8, try c.read(try c.fmt("{s}.stderr", .{stem})), "UnknownPass") == null) return error.InvalidPassWasIgnored;
    }
    const pipeline_ir = try invoke(r, compiler, input, &.{"--pipeline=release-o3"}, "pipeline-ir");
    const pipeline_staged = try invoke(r, compiler, pipeline_ir, &.{"--emit=obj"}, "pipeline-staged");
    try same(c, pipeline_staged, try invoke(r, compiler, input, &.{ "--pipeline=release-o3", "--emit=obj" }, "pipeline-inline"));

    const air = try c.join(&.{ r.output, "route.air" });
    const body = "  %0!= ret(<i32, 42>)\n";
    try c.write(air, try c.fmt(
        \\zllvm-air-export-v1
        \\contract_version=1
        \\payload=zig-air-print-v1
        \\producer=patched-zig-llvm-update-func
        \\root_source=route.zig
        \\wrapper=route.zig
        \\mode=ReleaseFast
        \\target=x86_64-unknown-linux-gnu
        \\function_count=1
        \\global_count=0
        \\function_begin
        \\name_bytes=4
        \\main
        \\type_bytes=9
        \\fn () i32
        \\instruction_count=1
        \\main_body_count=1
        \\liveness=present
        \\air_bytes={d}
        \\{s}
        \\function_end
        \\
    , .{ body.len, body }));
    const air_ir = try invoke(r, compiler, air, &.{"--passes=instcombine,dce"}, "air-ir");
    for ([_][]const u8{ "obj", "asm", "selection-owner-manifest" }) |emit| {
        const option = try c.fmt("--emit={s}", .{emit});
        const prepared = try invoke(r, compiler, air_ir, &.{option}, try c.fmt("air-staged-{s}", .{emit}));
        try same(c, prepared, try invoke(r, compiler, air, &.{ option, "--passes=instcombine,dce", "--trace" }, try c.fmt("air-inline-{s}", .{emit})));
        const diagnostics = try c.read(try c.join(&.{ r.output, try c.fmt("air-inline-{s}.stderr", .{emit}) }));
        if (std.mem.indexOf(u8, diagnostics, "; before instcombine") == null) return error.AirOptimizationWasIgnored;
    }
    try checkArtifact(r, compiler, "builder",
        \\; zllvm_ir_writer_construction = "ir-construction=zllvm-structured-builder"
        \\; zllvm_ir_writer_case = "releasefast_tiny_scalar"
        \\; deliberately no LLVM body: the structured builder owns the module
        \\
    );
    try checkArtifact(r, compiler, "descriptor",
        \\; zllvm_semantic_descriptor = "descriptor-owned"
        \\; zllvm_ir_writer_wrapper = "tiny_scalar_main.zig"
        \\; zllvm_ir_writer_mode = "ReleaseFast"
        \\; zllvm_ir_writer_source_fixture = "-"
        \\; zllvm_ir_writer_source_tag = "contract-test"
        \\; zllvm_semantic_descriptor_body = "scalar-add-ret"
        \\; zllvm_ir_writer_surface = "scalar-add-ret"
        \\; deliberately no LLVM body: the descriptor owns the module
        \\
    );
    try checkArtifact(r, compiler, "slice",
        \\; zllvm_semantic_descriptor = "descriptor-owned"
        \\; zllvm_ir_writer_wrapper = "runtime_slice_sum_main.zig"
        \\; zllvm_ir_writer_mode = "ReleaseFast"
        \\; zllvm_ir_writer_source_fixture = "-"
        \\; zllvm_ir_writer_source_tag = "contract-test"
        \\; zllvm_semantic_descriptor_body = "slice-loop-sum"
        \\; zllvm_ir_writer_surface = "slice-loop-sum"
        \\
    );
    try checkPaddingLength(r, compiler);
}

fn checkProfile(r: *Runner, compiler: []const u8, input: []const u8, expected_object: []const u8, label: []const u8, options: []const []const u8) !void {
    const c = r.context;
    const owners = try c.join(&.{ r.output, try c.fmt("{s}.tsv", .{label}) });
    const profile = try c.join(&.{ r.output, try c.fmt("{s}.json", .{label}) });
    const args = try std.mem.concat(c.a, []const u8, &.{ options, &.{
        "--emit=obj", try c.fmt("--selection-owner-output={s}", .{owners}), try c.fmt("--profile={s}", .{profile}),
    } });
    try same(c, expected_object, try invoke(r, compiler, input, args, label));
    try same(c, owners, try invoke(r, compiler, input, try std.mem.concat(c.a, []const u8, &.{ options, &.{"--emit=selection-owner-manifest"} }), try c.fmt("{s}-replay", .{label})));
    const measurement = try c.load(profile);
    if (!u.json.is(try u.get(measurement, "schema"), "compilation-profile-v2") or !(try u.get(measurement, "succeeded")).bool) return error.InvalidCompilationProfile;
    const counters = try u.get(measurement, "counters");
    if ((try u.get(counters, "selected_functions")).integer != 10 or (try u.get(counters, "normalization_runs")).integer < 10 or (try u.get(counters, "legalizer_attempts")).integer == 0) return error.InvalidProfileCounters;
    var total: i64 = 0;
    for ((try u.get(measurement, "phases")).array.items) |phase| {
        const ns = (try u.get(phase, "exclusive_ns")).integer;
        if (ns < 0) return error.NegativePhaseTime;
        total += ns;
    }
    if (total != (try u.get(measurement, "total_ns")).integer or total <= 0) return error.NestedTimingDoubleCounted;
    const functions = (try u.get(measurement, "functions")).array.items;
    if (functions.len != 10) return error.MissingFunctionProfiles;
    var names = std.StringHashMap(void).init(c.a);
    var attempts: i64 = 0;
    var allocated: i64 = 0;
    var grown: i64 = 0;
    for (functions) |function| {
        if ((try names.getOrPut(try u.str(function, "name"))).found_existing) return error.DuplicateFunctionProfile;
        var function_total: i64 = 0;
        for ((try u.get(function, "phases")).array.items) |phase| function_total += (try u.get(phase, "exclusive_ns")).integer;
        if (function_total != (try u.get(function, "total_ns")).integer or function_total < 0) return error.InvalidFunctionTime;
        const counts = try u.get(function, "counters");
        if ((try u.get(counts, "selected_functions")).integer != 1 or (try u.get(counts, "failed_functions")).integer != 0) return error.InvalidFunctionStatus;
        attempts += (try u.get(counts, "legalizer_attempts")).integer;
        const allocations = try u.get(function, "legalizer_allocations");
        allocated += (try u.get(allocations, "allocated_bytes")).integer;
        grown += (try u.get(allocations, "grown_bytes")).integer;
    }
    if (!names.contains("route") or !names.contains("byte_array_const")) return error.InvalidFunctionNames;
    const allocations = try u.get(measurement, "legalizer_allocations");
    if (attempts != (try u.get(counters, "legalizer_attempts")).integer or
        allocated != (try u.get(allocations, "allocated_bytes")).integer or
        grown != (try u.get(allocations, "grown_bytes")).integer) return error.InvalidFunctionAccounting;
    var stage_attempts: i64 = 0;
    var stage_bytes: i64 = 0;
    for ((try u.get(measurement, "legalizers")).array.items) |stage| {
        const split = (try u.get(stage, "rewritten_ns")).integer + (try u.get(stage, "unchanged_ns")).integer + (try u.get(stage, "error_ns")).integer;
        if (split != (try u.get(stage, "elapsed_ns")).integer or split < 0) return error.InvalidLegalizerTime;
        stage_attempts += (try u.get(stage, "attempts")).integer;
        const stats = try u.get(stage, "allocations");
        stage_bytes += (try u.get(stats, "allocated_bytes")).integer + (try u.get(stats, "grown_bytes")).integer;
    }
    if (stage_attempts != attempts or stage_bytes != allocated + grown) return error.InvalidLegalizerAccounting;
}

fn checkFailedProfile(r: *Runner, compiler: []const u8) !void {
    const c = r.context;
    const input = try c.join(&.{ r.output, "profile-failure.ll" });
    try c.write(input,
        \\define i32 @good() {
        \\entry:
        \\ ret i32 7
        \\}
        \\define i256 @bad(i256 %value) {
        \\entry:
        \\ ret i256 %value
        \\}
        \\
    );
    const profile = try c.join(&.{ r.output, "profile-failure.json" });
    const owners = try c.join(&.{ r.output, "profile-failure.tsv" });
    const stem = try c.join(&.{ r.output, "profile-failure" });
    const result = try r.run(&.{ compiler, "--generic-cfg-selector", "--target=x86_64-unknown-linux-gnu", "--report-all-codegen-failures", "--emit=obj", try c.fmt("--profile={s}", .{profile}), try c.fmt("--selection-owner-output={s}", .{owners}), input }, stem, &c.env, .{});
    if (result.code == 0 or (try c.read(try c.fmt("{s}.stdout", .{stem}))).len != 0 or u.exists(c.io, owners)) return error.FailedSelectionPublishedObject;
    const measurement = try c.load(profile);
    if ((try u.get(measurement, "succeeded")).bool) return error.FailedSelectionProfileSucceeded;
    const functions = (try u.get(measurement, "functions")).array.items;
    if (functions.len != 2) return error.MissingFailedFunctionProfile;
    var selected: i64 = 0;
    var failed: i64 = 0;
    for (functions) |function| {
        const counters = try u.get(function, "counters");
        selected += (try u.get(counters, "selected_functions")).integer;
        failed += (try u.get(counters, "failed_functions")).integer;
        if (u.json.is(try u.get(function, "name"), "bad") and (try u.get(counters, "failed_functions")).integer != 1) return error.WrongFailedFunctionProfile;
    }
    if (selected != 1 or failed != 1) return error.InvalidFailedFunctionAccounting;
}

fn checkArtifact(r: *Runner, compiler: []const u8, kind: []const u8, envelope: []const u8) !void {
    const c = r.context;
    const input = try c.join(&.{ r.output, try c.fmt("{s}.recipe", .{kind}) });
    try c.write(input, envelope);
    const staged = try invoke(r, compiler, input, &.{ "--passes=instcombine,dce", "--trace", "--time" }, try c.fmt("{s}-prepare", .{kind}));
    const staged_text = try c.read(staged);
    if (!std.mem.endsWith(u8, staged_text, envelope) or !std.mem.startsWith(u8, staged_text, "; zllvm_deferred_preparation_v1 = ")) return error.ArtifactOwnershipLost;
    const limited = try invoke(r, compiler, input, &.{ "--passes=instcombine,dce", "--pass-limit=0" }, try c.fmt("{s}-limited", .{kind}));
    const limited_object = try invoke(r, compiler, limited, &.{"--emit=obj"}, try c.fmt("{s}-limited-object", .{kind}));
    const unoptimized = try invoke(r, compiler, input, &.{"--emit=obj"}, try c.fmt("{s}-unoptimized", .{kind}));
    try same(c, limited_object, unoptimized);
    var prepared_object: ?[]const u8 = null;
    for ([_][]const u8{ "obj", "asm", "selection-owner-manifest" }) |emit| {
        const option = try c.fmt("--emit={s}", .{emit});
        const label = try c.fmt("{s}-staged-{s}", .{ kind, emit });
        const prepared = try invoke(r, compiler, staged, &.{option}, label);
        if (std.mem.eql(u8, emit, "obj")) prepared_object = prepared;
        const inline_result = try invoke(r, compiler, input, &.{ option, "--passes=instcombine,dce" }, try c.fmt("{s}-inline-{s}", .{ kind, emit }));
        try same(c, prepared, inline_result);
        const diagnostics = try c.read(try c.join(&.{ r.output, try c.fmt("{s}.stderr", .{label}) }));
        if (std.mem.indexOf(u8, diagnostics, "; before instcombine") == null or std.mem.indexOf(u8, diagnostics, "; time instcombine") == null) return error.DeferredOptimizationWasIgnored;
        // This builder emits foldable arithmetic. The descriptor fixture is
        // already constant, so its trace proves execution without a byte change.
        if (std.mem.eql(u8, kind, "builder") and std.mem.eql(u8, emit, "obj") and std.mem.eql(u8, try c.read(prepared), try c.read(unoptimized))) return error.ArtifactOptimizationDidNotChangeObject;
    }
    const chained = try invoke(r, compiler, limited, &.{"--pipeline=zig-release-fast-accepted"}, try c.fmt("{s}-chained", .{kind}));
    const chained_object = try invoke(r, compiler, chained, &.{"--emit=obj"}, try c.fmt("{s}-chained-object", .{kind}));
    try same(c, chained_object, try invoke(r, compiler, input, &.{ "--emit=obj", "--pipeline=zig-release-fast-accepted" }, try c.fmt("{s}-pipeline-object", .{kind})));
    const stem = try c.join(&.{ r.output, try c.fmt("{s}-invalid", .{kind}) });
    const failure = try r.run(&.{ compiler, "--passes=not-a-pass", input }, stem, &c.env, .{});
    if (failure.code == 0 or (try c.read(try c.fmt("{s}.stdout", .{stem}))).len != 0 or std.mem.indexOf(u8, try c.read(try c.fmt("{s}.stderr", .{stem})), "UnknownPass") == null) return error.InvalidArtifactPassWasIgnored;
    if (std.mem.eql(u8, kind, "slice")) try checkSliceExecution(r, &.{ unoptimized, prepared_object.? });
}

fn checkSliceExecution(r: *Runner, objects: []const []const u8) !void {
    const c = r.context;
    const driver = try c.join(&.{ r.output, "slice-driver.c" });
    try c.write(driver,
        \\#include <stdint.h>
        \\extern int slice_sum(const int *, uint64_t) __asm__("aggregates.slice_sum");
        \\extern int descriptor_main(void);
        \\int main(void) {
        \\  if (descriptor_main() != 0 || slice_sum(0, 0) != 0) return 1;
        \\  for (int seed = -8; seed <= 8; ++seed) {
        \\    int values[16], expected = 0;
        \\    for (int i = 0; i < 16; ++i) values[i] = (i * 7) - seed * 3;
        \\    for (unsigned n = 0; n <= 16; ++n) {
        \\      if (slice_sum(values, n) != expected) return 2;
        \\      if (n < 16) expected += values[n];
        \\    }
        \\  }
        \\  return 0;
        \\}
        \\
    );
    for (objects, 0..) |object, index| {
        const exported = try c.join(&.{ r.output, try c.fmt("slice-{d}.o", .{index}) });
        try r.require(&.{ "objcopy", "--redefine-sym", "main=descriptor_main", "--globalize-symbol", "aggregates.slice_sum", object, exported }, try c.join(&.{ r.output, try c.fmt("slice-export-{d}", .{index}) }), &c.env);
        const exe = try c.join(&.{ r.output, try c.fmt("slice-{d}", .{index}) });
        try r.require(&.{ "cc", "-no-pie", "-Wl,-z,noexecstack", driver, exported, "-o", exe }, try c.join(&.{ r.output, try c.fmt("slice-link-{d}", .{index}) }), &c.env);
        try r.observe(exe, &.{}, 0, "", try c.join(&.{ r.output, try c.fmt("slice-execute-{d}", .{index}) }), &c.env);
    }
}

// The old whole-function matcher returned success even when sext i1 made
// the fixture's comparison false. Vary both memory bytes and the expectation,
// and check default/generic selection against an independent LLVM execution.
fn checkPaddingLength(r: *Runner, compiler: []const u8) !void {
    const c = r.context;
    for ([_]u32{ 0, 61, 61 << 8, 15677 }) |tail| {
        for ([_]u32{ 4, 8 }) |expected| {
            const label = try c.fmt("padding-{d}-{d}", .{ tail, expected });
            const input = try c.join(&.{ r.output, try c.fmt("{s}.ll", .{label}) });
            try c.write(input, try c.fmt(
                \\@base64.padding_length_tail = private unnamed_addr global i32 {d}, align 4
                \\define i32 @main() {{
                \\entry:
                \\ %end = getelementptr [1 x i8], ptr @base64.padding_length_tail, i64 2
                \\ %last_ptr = getelementptr i8, ptr %end, i64 -1
                \\ %last = load i8, ptr %last_ptr, align 1
                \\ %last_eq = icmp eq i8 %last, 61
                \\ %last_adj = sext i1 %last_eq to i64
                \\ %base = add i64 6, %last_adj
                \\ %second_ptr = getelementptr i8, ptr %end, i64 -2
                \\ %second = load i8, ptr %second_ptr, align 1
                \\ %second_eq = icmp eq i8 %second, 61
                \\ %second_adj = sext i1 %second_eq to i64
                \\ %total = add i64 %base, %second_adj
                \\ %ok = icmp eq i64 %total, {d}
                \\ %ret = select i1 %ok, i32 0, i32 1
                \\ ret i32 %ret
                \\}}
                \\
            , .{ tail, expected }));
            const exit_code: u8 = if (tail == 15677 and expected == 4) 0 else 1;
            const reference = try c.join(&.{ r.output, try c.fmt("{s}-reference", .{label}) });
            try r.require(&.{ "clang-22", "-Wno-override-module", "-O0", input, "-o", reference }, try c.fmt("{s}-compile", .{reference}), &c.env);
            try r.observe(reference, &.{}, exit_code, "", try c.fmt("{s}-execute", .{reference}), &c.env);
            for ([_][]const []const u8{ &.{}, &.{"--generic-cfg-selector"}, &.{ "--generic-cfg-selector", "--passes=zig-release-small-accepted" } }, 0..) |options, index| {
                const stem = try c.join(&.{ r.output, try c.fmt("{s}-{d}", .{ label, index }) });
                const command = try std.mem.concat(c.a, []const u8, &.{ &.{ compiler, "--emit=obj", "--target=x86_64-unknown-linux-gnu" }, options, &.{input} });
                const compilation_result = try r.run(command, try c.fmt("{s}-object", .{stem}), &c.env, .{});
                // The legacy route may reject this form. It must never turn
                // an unproved memory-dependent computation into constant success.
                if (index == 0 and compilation_result.code != 0) {
                    const diagnostic = try c.read(try c.fmt("{s}-object.stderr", .{stem}));
                    if (std.mem.indexOf(u8, diagnostic, "UnsupportedCodegenInstruction") == null or
                        (try c.read(try c.fmt("{s}-object.stdout", .{stem}))).len != 0) return error.UnexpectedLegacyFailure;
                    continue;
                }
                if (compilation_result.code != 0) return error.PaddingLengthCompilationFailed;
                const object = try c.fmt("{s}.o", .{stem});
                try c.copy(try c.fmt("{s}-object.stdout", .{stem}), object);
                try r.require(&.{ "cc", "-no-pie", "-Wl,-z,noexecstack", object, "-o", stem }, try c.fmt("{s}-link", .{stem}), &c.env);
                try r.observe(stem, &.{}, exit_code, "", try c.fmt("{s}-execute", .{stem}), &c.env);
            }
        }
    }
}
