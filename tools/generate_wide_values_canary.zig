//! Non-native pair bit intrinsics and exact integer call literals.
const std = @import("std");
const u = @import("validation/common.zig");
const widths = [_]u16{ 65, 80, 113, 127 };
const ops = [_][]const u8{ "abs", "ctlz", "cttz", "ctpop" };
const fixed: u128 = 0xfedcba98765432100123456789abcdef;
pub fn main(init: std.process.Init) !void {
    var c = try u.Context.init(init);
    const argv = try init.minimal.args.toSlice(c.a);
    const args = try u.Args.parse(c.a, argv[1..], &.{ "output-root", "registry-input" }, &.{});
    const out = try c.newOutput(try args.require("output-root"));
    var llvm: std.Io.Writer.Allocating = .init(c.a);
    var driver: std.Io.Writer.Allocating = .init(c.a);
    const w = &llvm.writer;
    const d = &driver.writer;
    var names: std.ArrayList([]const u8) = .empty;
    try w.writeAll("target triple = \"x86_64-unknown-linux-gnu\"\ndeclare i64 @wide_values_clobber(i64)\ndeclare i128 @wide_values_probe(i128,i128,i64)\n");
    try d.writeAll("#include <stdint.h>\ntypedef unsigned __int128 u128;\ntypedef u128 (*wide_fn)(u128,uint8_t*,uint64_t);\nstruct wide_case {wide_fn function;unsigned width,operation,literal;};\n");
    for (widths) |bits| for (ops) |op| {
        try w.print("declare i{d} @llvm.{s}.i{d}(i{d}{s})\n", .{ bits, op, bits, bits, if (std.mem.eql(u8, op, "ctpop")) "" else ",i1" });
        for (0..2) |literal| {
            const name = try c.fmt("wide_values_{d}_{s}_{d}", .{ bits, op, literal });
            try names.append(c.a, name);
            const value = if (literal != 0) try c.fmt("{d}", .{fixed & ((@as(u128, 1) << @as(u7, @intCast(bits))) - 1)}) else "%narrow";
            try w.print("define i128 @{s}(i128 %raw,ptr %out,i64 %live) {{\nentry:\n %narrow = trunc i128 %raw to i{d}\n %result = call i{d} @llvm.{s}.i{d}(i{d} {s}{s})\n %wide = zext i{d} %result to i128\n %probe = call i64 @wide_values_clobber(i64 %live)\n store i128 %wide,ptr %out,align 1\n %extended = zext i64 %probe to i128\n %answer = xor i128 %wide,%extended\n ret i128 %answer\n}}\n", .{ name, bits, bits, op, bits, bits, value, if (std.mem.eql(u8, op, "ctpop")) "" else ",i1 false", bits });
            try d.print("extern u128 {s}(u128,uint8_t*,uint64_t);\n", .{name});
        }
    };
    for (0..3) |variant| {
        const name = try c.fmt("wide_values_call_{d}", .{variant});
        try names.append(c.a, name);
        const constant = try c.fmt("{d}", .{@as(i128, @bitCast(fixed))});
        const lhs = if (variant == 0 or variant == 2) constant else "%raw";
        const rhs = if (variant == 1 or variant == 2) constant else "%raw";
        try w.print("define i128 @{s}(i128 %raw,ptr %out,i64 %live) {{\nentry:\n %result = call i128 @wide_values_probe(i128 {s},i128 {s},i64 %live)\n %probe = call i64 @wide_values_clobber(i64 %live)\n store i128 %result,ptr %out,align 1\n %extended = zext i64 %probe to i128\n %answer = xor i128 %result,%extended\n ret i128 %answer\n}}\n", .{ name, lhs, rhs });
        try d.print("extern u128 {s}(u128,uint8_t*,uint64_t);\n", .{name});
    }
    try d.writeAll("static const struct wide_case cases[]={\n");
    for (widths) |bits| for (ops, 0..) |op, index| for (0..2) |literal| try d.print("{{wide_values_{d}_{s}_{d},{d},{d},{d}}},\n", .{ bits, op, literal, bits, index, literal });
    for (0..3) |variant| try d.print("{{wide_values_call_{d},128,4,{d}}},\n", .{ variant, variant });
    try d.writeAll("};\n");
    try d.writeAll(@embedFile("templates/wide_values_driver.c"));
    try c.write(try c.join(&.{ out, "wide_values.ll" }), llvm.written());
    try c.write(try c.join(&.{ out, "wide_values_driver.c" }), driver.written());
    const pop = try u.toValue(c.a, .{ .population = "wide_values", .prefix = "wide-values", .fixture = "wide_values", .functions = names.items, .observations = 286720, .stdout = "wide-values observations=286720 widths=counts=abs=literals=call=live=guards=preserved\n" });
    try c.writeJson(try c.join(&.{ out, "population.json" }), pop);
    if (args.get("registry-input")) |path| {
        const original = try c.read(try c.join(&.{path}));
        const registry = try c.load(try c.join(&.{path}));
        for (try u.json.array(try u.get(registry, "canaries"))) |entry| if (std.mem.eql(u8, try u.str(entry, "population"), "wide_values")) return error.PopulationAlreadyRegistered;
        const end = std.mem.lastIndexOf(u8, original, "\n  ]") orelse return error.UnexpectedRegistryLayout;
        const rendered = try std.json.Stringify.valueAlloc(c.a, pop, .{ .whitespace = .indent_2 });
        const indented = try std.mem.replaceOwned(u8, c.a, rendered, "\n", "\n    ");
        try c.write(try c.join(&.{ out, "native_canaries.json" }), try c.fmt("{s},\n    {s}{s}", .{ original[0..end], indented, original[end..] }));
    }
}
