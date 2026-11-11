//! Extended80 conversions and mixed physical ABI, checked by integer oracles.
const std = @import("std");
const u = @import("validation/common.zig");
const formats = [_]struct { name: []const u8, ty: []const u8, bits: u16 }{
    .{ .name = "half", .ty = "half", .bits = 16 },
    .{ .name = "float", .ty = "float", .bits = 32 },
    .{ .name = "double", .ty = "double", .bits = 64 },
    .{ .name = "quad", .ty = "fp128", .bits = 128 },
    .{ .name = "extended", .ty = "x86_fp80", .bits = 80 },
};
const pairs = [_][2]usize{ .{ 0, 4 }, .{ 4, 0 }, .{ 1, 4 }, .{ 4, 1 }, .{ 2, 4 }, .{ 4, 2 }, .{ 3, 4 }, .{ 4, 3 }, .{ 2, 0 }, .{ 0, 2 } };

fn caseName(c: *u.Context, pair: [2]usize) ![]const u8 {
    if (pair[1] == 4) return c.fmt("extended80_from_{s}", .{formats[pair[0]].name});
    if (pair[0] == 4) return c.fmt("extended80_to_{s}", .{formats[pair[1]].name});
    return c.fmt("extended80_{s}_to_{s}", .{ formats[pair[0]].name, formats[pair[1]].name });
}

pub fn main(init: std.process.Init) !void {
    var c = try u.Context.init(init);
    const argv = try init.minimal.args.toSlice(c.a);
    const args = try u.Args.parse(c.a, argv[1..], &.{ "output-root", "registry-input" }, &.{});
    const output = try c.newOutput(try args.require("output-root"));
    var llvm: std.Io.Writer.Allocating = .init(c.a);
    var driver: std.Io.Writer.Allocating = .init(c.a);
    const w = &llvm.writer;
    const d = &driver.writer;
    try w.writeAll("target triple = \"x86_64-unknown-linux-gnu\"\ntarget datalayout = \"e-i128:128-f80:128\"\ndeclare i64 @extended80_float_clobber(i64)\n");
    try d.writeAll("#define _GNU_SOURCE\n#include <stdint.h>\ntypedef unsigned __int128 u128;\ntypedef __float128 quad;\ntypedef u128 (*conversion_fn)(const uint8_t*,uint8_t*,uint64_t);\nstruct conversion_case {conversion_fn function;unsigned source,target,rows;};\n");
    var names: std.ArrayList([]const u8) = .empty;
    for (pairs) |pair| {
        const from = formats[pair[0]];
        const to = formats[pair[1]];
        const name = try caseName(&c, pair);
        try names.append(c.a, name);
        try w.print("define i128 @{s}(ptr %input,ptr %output,i64 %live) {{\nentry:\n %x = load {s},ptr %input,align 1\n %raw = bitcast {s} %x to i{d}\n", .{ name, from.ty, from.ty, from.bits });
        if (from.bits == 128) try w.writeAll(" %wide_input = add i128 %raw,0\n") else try w.print(" %wide_input = zext i{d} %raw to i128\n", .{from.bits});
        const widen = from.bits < to.bits;
        try w.print(" %converted = {s} {s} %x to {s}\n %probe = call i64 @extended80_float_clobber(i64 %live)\n store {s} %converted,ptr %output,align 1\n %mask = zext i64 %probe to i128\n %answer = xor i128 %wide_input,%mask\n ret i128 %answer\n}}\n", .{ if (widen) "fpext" else "fptrunc", from.ty, to.ty, to.ty });
        try d.print("extern u128 {s}(const uint8_t*,uint8_t*,uint64_t);\n", .{name});
    }
    try names.appendSlice(c.a, &.{ "extended80_mixed_incoming", "extended80_mixed_call" });
    try w.writeAll(@embedFile("templates/extended80_float_mixed.ll"));
    try d.writeAll("extern u128 extended80_mixed_incoming(uint64_t,double,long double,uint64_t,float,uint64_t,double,uint64_t,uint64_t,uint64_t,uint64_t,long double,quad,uint8_t*);\nextern u128 extended80_mixed_call(const uint8_t*,uint8_t*,uint64_t);\nstatic const struct conversion_case cases[]={\n");
    for (pairs) |pair| try d.print("{{{s},{d},{d},{d}}},\n", .{ try caseName(&c, pair), pair[0], pair[1], if (pair[0] == 0) @as(usize, 65536) else 8192 });
    try d.writeAll("};\n");
    try d.writeAll(@embedFile("templates/extended80_float_driver.c"));
    try c.write(try c.join(&.{ output, "extended80_float.ll" }), llvm.written());
    try c.write(try c.join(&.{ output, "extended80_float_driver.c" }), driver.written());
    const population = try u.toValue(c.a, .{
        .population = "extended80_float",
        .prefix = "extended80-float",
        .fixture = "extended80_float",
        .functions = names.items,
        .observations = 204800,
        .stdout = "extended80-float observations=204800 rounding=subnormal=nan=mixed-abi=live=guards=preserved\n",
    });
    try c.writeJson(try c.join(&.{ output, "population.json" }), population);
    if (args.get("registry-input")) |path| {
        const original = try c.read(try c.join(&.{path}));
        const registry = try c.load(try c.join(&.{path}));
        for (try u.json.array(try u.get(registry, "canaries"))) |entry| if (std.mem.eql(u8, try u.str(entry, "population"), "extended80_float")) return error.PopulationAlreadyRegistered;
        const end = std.mem.lastIndexOf(u8, original, "\n  ]") orelse return error.UnexpectedRegistryLayout;
        const rendered = try std.json.Stringify.valueAlloc(c.a, population, .{ .whitespace = .indent_2 });
        const indented = try std.mem.replaceOwned(u8, c.a, rendered, "\n", "\n    ");
        try c.write(try c.join(&.{ output, "native_canaries.json" }), try c.fmt("{s},\n    {s}{s}", .{ original[0..end], indented, original[end..] }));
    }
}
