//! Range-attributed vector populations, masks, reductions and lane shuffles.
const std = @import("std");
const u = @import("validation/common.zig");
const names = [_][]const u8{ "vector_counts_range", "vector_counts_mask", "vector_counts_min", "vector_counts_shuffle" };
pub fn main(init: std.process.Init) !void {
    var c = try u.Context.init(init);
    const argv = try init.minimal.args.toSlice(c.a);
    const args = try u.Args.parse(c.a, argv[1..], &.{ "output-root", "registry-input" }, &.{});
    const out = try c.newOutput(try args.require("output-root"));
    const llvm =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\declare i64 @vector_counts_clobber(i64)
        \\declare <6 x i64> @llvm.ctpop.v6i64(<6 x i64>)
        \\declare i64 @llvm.vector.reduce.add.v6i64(<6 x i64>)
        \\declare i4 @llvm.vector.reduce.umin.v16i4(<16 x i4>)
        \\define i64 @vector_counts_range(ptr %input,ptr %out,i64 %live) {
        \\entry:
        \\ %a = load <6 x i64>,ptr %input,align 1
        \\ %counts = call range(i64 0, 65) <6 x i64> @llvm.ctpop.v6i64(<6 x i64> %a)
        \\ %sum = call i64 @llvm.vector.reduce.add.v6i64(<6 x i64> %counts)
        \\ %probe = call i64 @vector_counts_clobber(i64 %live)
        \\ store <6 x i64> %counts,ptr %out,align 1
        \\ %answer = xor i64 %sum,%probe
        \\ ret i64 %answer
        \\}
        \\define i64 @vector_counts_mask(ptr %input,ptr %out,i64 %live) {
        \\entry:
        \\ %a = load <16 x i8>,ptr %input,align 1
        \\ %condition = icmp eq <16 x i8> %a,zeroinitializer
        \\ %mask = bitcast <16 x i1> %condition to i16
        \\ %wide = zext i16 %mask to i64
        \\ %probe = call i64 @vector_counts_clobber(i64 %live)
        \\ store i16 %mask,ptr %out,align 1
        \\ %answer = xor i64 %wide,%probe
        \\ ret i64 %answer
        \\}
        \\define i64 @vector_counts_min(ptr %input,ptr %out,i64 %live) {
        \\entry:
        \\ %a = load i64,ptr %input,align 1
        \\ %lanes = bitcast i64 %a to <16 x i4>
        \\ %minimum = call i4 @llvm.vector.reduce.umin.v16i4(<16 x i4> %lanes)
        \\ %byte = zext i4 %minimum to i8
        \\ %wide = zext i4 %minimum to i64
        \\ %probe = call i64 @vector_counts_clobber(i64 %live)
        \\ store i8 %byte,ptr %out,align 1
        \\ %answer = xor i64 %wide,%probe
        \\ ret i64 %answer
        \\}
        \\define i64 @vector_counts_shuffle(ptr %input,ptr %out,i64 %live) {
        \\entry:
        \\ %a = load <2 x i64>,ptr %input,align 1
        \\ %swapped = shufflevector <2 x i64> %a,<2 x i64> poison,<2 x i32> <i32 1,i32 0>
        \\ %left = extractelement <2 x i64> %swapped,i64 0
        \\ %right = extractelement <2 x i64> %swapped,i64 1
        \\ %sum = xor i64 %left,%right
        \\ %probe = call i64 @vector_counts_clobber(i64 %live)
        \\ store <2 x i64> %swapped,ptr %out,align 1
        \\ %answer = xor i64 %sum,%probe
        \\ ret i64 %answer
        \\}
    ;
    try c.write(try c.join(&.{ out, "vector_counts.ll" }), llvm ++ "\n");
    try c.write(try c.join(&.{ out, "vector_counts_driver.c" }), @embedFile("templates/vector_counts_driver.c"));
    const pop = try u.toValue(c.a, .{ .population = "vector_counts", .prefix = "vector-counts", .fixture = "vector_counts", .functions = names, .observations = 32768, .stdout = "vector-counts observations=32768 range=popcount=masks=reduction=shuffle=live=guards=preserved\n" });
    try c.writeJson(try c.join(&.{ out, "population.json" }), pop);
    if (args.get("registry-input")) |path| {
        const original = try c.read(try c.join(&.{path}));
        const registry = try c.load(try c.join(&.{path}));
        for (try u.json.array(try u.get(registry, "canaries"))) |entry| if (std.mem.eql(u8, try u.str(entry, "population"), "vector_counts")) return error.PopulationAlreadyRegistered;
        const end = std.mem.lastIndexOf(u8, original, "\n  ]") orelse return error.UnexpectedRegistryLayout;
        const rendered = try std.json.Stringify.valueAlloc(c.a, pop, .{ .whitespace = .indent_2 });
        const indented = try std.mem.replaceOwned(u8, c.a, rendered, "\n", "\n    ");
        try c.write(try c.join(&.{ out, "native_canaries.json" }), try c.fmt("{s},\n    {s}{s}", .{ original[0..end], indented, original[end..] }));
    }
}
