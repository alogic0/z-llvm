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
        \\
    );
    const staged = try invoke(r, compiler, input, &.{"--passes=instcombine,dce"}, "optimize");
    const direct = try invoke(r, compiler, input, &.{"--emit=obj"}, "direct");
    const limited = try invoke(r, compiler, input, &.{ "--emit=obj", "--passes=instcombine,dce", "--pass-limit=0" }, "limited");
    try same(c, direct, limited);
    for ([_][]const u8{ "obj", "asm", "selection-owner-manifest" }) |emit| {
        const option = try c.fmt("--emit={s}", .{emit});
        const prepared = try invoke(r, compiler, staged, &.{option}, try c.fmt("staged-{s}", .{emit}));
        const inline_result = try invoke(r, compiler, input, &.{ option, "--passes=instcombine,dce" }, try c.fmt("inline-{s}", .{emit}));
        try same(c, prepared, inline_result);
        if (std.mem.eql(u8, emit, "obj")) {
            if (std.mem.eql(u8, try c.read(direct), try c.read(inline_result))) return error.OptimizationDidNotChangeObject;
            const traced = try invoke(r, compiler, input, &.{ option, "--passes=instcombine,dce", "--trace", "--time" }, "traced");
            try same(c, traced, inline_result);
            const diagnostics = try c.read(try c.join(&.{ r.output, "traced.stderr" }));
            if (std.mem.indexOf(u8, diagnostics, "; before instcombine") == null or std.mem.indexOf(u8, diagnostics, "; time instcombine") == null) return error.MissingPassDiagnostics;
            const driver = try c.join(&.{ r.output, "driver.c" });
            try c.write(driver, "extern int route(int); int main(void) { for (int i=-100; i<=100; ++i) if (route(i)!=i+42) return 1; return 0; }\n");
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
}
