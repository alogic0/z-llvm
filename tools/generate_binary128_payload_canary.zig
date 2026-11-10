//! Generate binary128 ABI and compiler-rt differential fixtures and C oracles.
const std = @import("std");
const u = @import("validation/common.zig");

pub fn main(init: std.process.Init) !void {
    var c = try u.Context.init(init);
    const argv = try init.minimal.args.toSlice(c.a);
    const args = try u.Args.parse(c.a, argv[1..], &.{ "output-root", "registry-input" }, &.{});
    const output = try c.newOutput(try args.require("output-root"));
    var llvm: std.Io.Writer.Allocating = .init(c.a);
    var driver: std.Io.Writer.Allocating = .init(c.a);
    const w = &llvm.writer;
    try w.writeAll(@embedFile("templates/binary128_payloads_base.ll"));
    try driver.writer.writeAll(@embedFile("templates/binary128_payloads_header.c"));
    var names: std.ArrayList([]const u8) = .empty;
    for ([_][]const u8{ "identity", "bits", "from_bits", "load_index", "transport", "call_constant", "eight" }) |suffix|
        try names.append(c.a, try c.fmt("binary128_{s}", .{suffix}));
    try w.writeAll("define fp128 @binary128_eight(");
    for (0..8) |i| try w.print("{s}fp128 %a{d}", .{ if (i == 0) "" else ", ", i });
    try w.writeAll(", i64 %seed) {\nentry:\n %probe = call i64 @binary128_clobber(i64 %seed)\n");
    for (0..8) |i| {
        try w.print(" %bits{0d} = bitcast fp128 %a{0d} to i128\n %lo{0d} = trunc i128 %bits{0d} to i64\n %shift{0d} = lshr i128 %bits{0d}, 64\n %hi{0d} = trunc i128 %shift{0d} to i64\n", .{i});
        try w.print(" %lw{d} = mul i64 %lo{d}, {d}\n %hw{d} = mul i64 %hi{d}, {d}\n", .{ i, i, 2 * i + 1, i, i, 2 * i + 3 });
        if (i == 0) try w.writeAll(" %ls0 = add i64 %lw0, %probe\n %hs0 = xor i64 %hw0, %seed\n") else try w.print(" %ls{d} = add i64 %ls{d}, %lw{d}\n %hs{d} = add i64 %hs{d}, %hw{d}\n", .{ i, i - 1, i, i, i - 1, i });
    }
    try w.writeAll(" %low = zext i64 %ls7 to i128\n %high = zext i64 %hs7 to i128\n %shifted = shl i128 %high, 64\n %combined = or i128 %low, %shifted\n %result = bitcast i128 %combined to fp128\n ret fp128 %result\n}\n");
    for ([_][]const u8{ "add", "sub", "mul", "div" }) |op| {
        const name = try c.fmt("binary128_{s}", .{op});
        try names.append(c.a, name);
        try w.print("define fp128 @{s}(fp128 %a, fp128 %b) {{\nentry:\n %r = f{s} fp128 %a, %b\n ret fp128 %r\n}}\n", .{ name, op });
        try driver.writer.print("extern quad {s}(quad,quad);\n", .{name});
    }
    const Conversion = struct { name: []const u8, op: []const u8, from: []const u8, to: []const u8, c_from: []const u8, c_to: []const u8 };
    for ([_]Conversion{
        .{ .name = "from_f32", .op = "fpext", .from = "float", .to = "fp128", .c_from = "float", .c_to = "quad" },
        .{ .name = "from_f64", .op = "fpext", .from = "double", .to = "fp128", .c_from = "double", .c_to = "quad" },
        .{ .name = "to_f32", .op = "fptrunc", .from = "fp128", .to = "float", .c_from = "quad", .c_to = "float" },
        .{ .name = "to_f64", .op = "fptrunc", .from = "fp128", .to = "double", .c_from = "quad", .c_to = "double" },
        .{ .name = "from_i32", .op = "sitofp", .from = "i32", .to = "fp128", .c_from = "int32_t", .c_to = "quad" },
        .{ .name = "from_u32", .op = "uitofp", .from = "i32", .to = "fp128", .c_from = "uint32_t", .c_to = "quad" },
        .{ .name = "from_i64", .op = "sitofp", .from = "i64", .to = "fp128", .c_from = "int64_t", .c_to = "quad" },
        .{ .name = "from_u64", .op = "uitofp", .from = "i64", .to = "fp128", .c_from = "uint64_t", .c_to = "quad" },
        .{ .name = "to_i32", .op = "fptosi", .from = "fp128", .to = "i32", .c_from = "quad", .c_to = "int32_t" },
        .{ .name = "to_u32", .op = "fptoui", .from = "fp128", .to = "i32", .c_from = "quad", .c_to = "uint32_t" },
        .{ .name = "to_i64", .op = "fptosi", .from = "fp128", .to = "i64", .c_from = "quad", .c_to = "int64_t" },
        .{ .name = "to_u64", .op = "fptoui", .from = "fp128", .to = "i64", .c_from = "quad", .c_to = "uint64_t" },
    }) |cast| {
        const name = try c.fmt("binary128_{s}", .{cast.name});
        try names.append(c.a, name);
        try w.print("define {s} @{s}({s} %a) {{\nentry:\n %r = {s} {s} %a to {s}\n ret {s} %r\n}}\n", .{ cast.to, name, cast.from, cast.op, cast.from, cast.to, cast.to });
        try driver.writer.print("extern {s} {s}({s});\n", .{ cast.c_to, name, cast.c_from });
    }
    const predicates = [_][]const u8{ "false", "oeq", "ogt", "oge", "olt", "ole", "one", "ord", "uno", "ueq", "ugt", "uge", "ult", "ule", "une", "true" };
    for (predicates) |predicate| {
        const name = try c.fmt("binary128_cmp_{s}", .{predicate});
        try names.append(c.a, name);
        try w.print("define i32 @{s}(fp128 %a, fp128 %b, ptr %out) {{\nentry:\n %c = fcmp {s} fp128 %a, %b\n store fp128 %a, ptr %out, align 1\n %r = zext i1 %c to i32\n ret i32 %r\n}}\n", .{ name, predicate });
        try driver.writer.print("extern uint32_t {s}(quad,quad,uint64_t*);\n", .{name});
    }
    try driver.writer.writeAll("static uint32_t (*const comparisons[])(quad,quad,uint64_t*)={\n");
    for (predicates) |predicate| try driver.writer.print(" binary128_cmp_{s},\n", .{predicate});
    try driver.writer.writeAll("};\n");
    try driver.writer.writeAll(@embedFile("templates/binary128_payloads_checks.c"));
    try c.write(try c.join(&.{ output, "binary128_payloads.ll" }), llvm.written());
    try c.write(try c.join(&.{ output, "binary128_payloads_driver.c" }), driver.written());
    // Preserve the existing structural negation owner separately from the new
    // population, whose strict contract requires every definition to compose.
    try c.write(try c.join(&.{ output, "binary128_negation.ll" }),
        \\target triple = "x86_64-unknown-linux-gnu"
        \\define fp128 @binary128_neg(fp128 %a) {
        \\entry:
        \\ %r = fneg fp128 %a
        \\ ret fp128 %r
        \\}
        \\
    );
    try c.write(try c.join(&.{ output, "binary128_negation_driver.c" }),
        \\#include <stdint.h>
        \\#include <stdio.h>
        \\#include <string.h>
        \\typedef unsigned __int128 u128;
        \\extern __float128 binary128_neg(__float128);
        \\int main(void) {
        \\ const u128 values[]={0,1,(u128)1<<127,(u128)0x3fff<<112,(u128)0x7fff<<112,
        \\  ((u128)0x7fff<<112)|1,((u128)UINT64_C(0xffff800000000123)<<64)|UINT64_C(0xfeedface01234567),~(u128)0};
        \\ for(unsigned i=0;i<8;i++) {
        \\  __float128 input,result; u128 actual; memcpy(&input,values+i,16);
        \\  result=binary128_neg(input); memcpy(&actual,&result,16);
        \\  if(actual!=(values[i]^((u128)1<<127)))return 1;
        \\ }
        \\ puts("binary128-negation observations=8 sign=payload=signaling=preserved");return 0;
        \\}
        \\
    );
    const population = try u.toValue(c.a, .{
        .population = "binary128_payloads",
        .prefix = "binary128-payloads",
        .fixture = "binary128_payloads",
        .functions = names.items,
        .observations = 5041,
        .stdout = "binary128-payloads observations=5041 bits=abi=memory=arithmetic=conversions=comparisons=clobbers=guards=preserved\n",
    });
    try c.writeJson(try c.join(&.{ output, "population.json" }), population);
    if (args.get("registry-input")) |path| {
        const original = try c.read(try c.join(&.{path}));
        const registry = try c.load(try c.join(&.{path}));
        for (try u.json.array(try u.get(registry, "canaries"))) |entry| if (std.mem.eql(u8, try u.str(entry, "population"), "binary128_payloads")) return error.PopulationAlreadyRegistered;
        const end = std.mem.lastIndexOf(u8, original, "\n  ]") orelse return error.UnexpectedRegistryLayout;
        const rendered = try std.json.Stringify.valueAlloc(c.a, population, .{ .whitespace = .indent_2 });
        const indented = try std.mem.replaceOwned(u8, c.a, rendered, "\n", "\n    ");
        try c.write(try c.join(&.{ output, "native_canaries.json" }), try c.fmt("{s},\n    {s}{s}", .{ original[0..end], indented, original[end..] }));
    }
}
