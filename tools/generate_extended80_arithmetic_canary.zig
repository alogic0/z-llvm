//! Exact x87 numerical operators with literal, live-value and memory controls.
const std = @import("std");
const u = @import("validation/common.zig");
const operations = [_][]const u8{ "add", "sub", "mul", "div", "sqrt" };
pub fn main(init: std.process.Init) !void {
    var c = try u.Context.init(init);
    const argv = try init.minimal.args.toSlice(c.a);
    const args = try u.Args.parse(c.a, argv[1..], &.{ "output-root", "registry-input" }, &.{});
    const output = try c.newOutput(try args.require("output-root"));
    var llvm: std.Io.Writer.Allocating = .init(c.a);
    var driver: std.Io.Writer.Allocating = .init(c.a);
    const w = &llvm.writer;
    const d = &driver.writer;
    try w.writeAll("target triple = \"x86_64-unknown-linux-gnu\"\ntarget datalayout = \"e-i128:128-f80:128\"\ndeclare i64 @extended80_arithmetic_clobber(i64)\ndeclare x86_fp80 @llvm.sqrt.f80(x86_fp80)\n");
    try d.writeAll("#define _GNU_SOURCE\n#define __STDC_WANT_IEC_60559_TYPES_EXT__ 1\n#include <stdint.h>\ntypedef unsigned __int128 u128;\ntypedef uint64_t (*math_fn)(const uint8_t*,const uint8_t*,const uint8_t*,uint8_t*,uint64_t);\nstruct math_case {math_fn function;unsigned format,operation,literal;};\n");
    var names: std.ArrayList([]const u8) = .empty;
    for (operations) |operation| for (0..3) |variant| {
        const name = try c.fmt("extended80_arithmetic_{s}_{d}", .{ operation, variant });
        try names.append(c.a, name);
        const sqrt = std.mem.eql(u8, operation, "sqrt");
        const lhs = if (variant == 1) "0xK3FFFC000000000000000" else if (sqrt and variant == 2) "0xK80000000000000000000" else "%a";
        const rhs = if (variant == 2) "0xK4000A000000000000000" else "%b";
        const expression = if (sqrt) try c.fmt("call x86_fp80 @llvm.sqrt.f80(x86_fp80 {s})", .{lhs}) else try c.fmt("f{s} x86_fp80 {s},{s}", .{ operation, lhs, rhs });
        try w.print("define i64 @{s}(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {{\nentry:\n %a = load x86_fp80,ptr %left,align 1\n %b = load x86_fp80,ptr %right,align 1\n %r = {s}\n %probe = call i64 @extended80_arithmetic_clobber(i64 %live)\n store x86_fp80 %r,ptr %output,align 1\n ret i64 %probe\n}}\n", .{ name, expression });
        try d.print("extern uint64_t {s}(const uint8_t*,const uint8_t*,const uint8_t*,uint8_t*,uint64_t);\n", .{name});
    };
    try d.writeAll("static const struct math_case cases[]={\n");
    for (operations, 0..) |operation, index| for (0..3) |variant| try d.print("{{extended80_arithmetic_{s}_{d},0,{d},{d}}},\n", .{ operation, variant, index, variant });
    try d.writeAll("};\n");
    try d.writeAll(@embedFile("templates/extended80_arithmetic_driver.c"));
    try c.write(try c.join(&.{ output, "extended80_arithmetic.ll" }), llvm.written());
    try c.write(try c.join(&.{ output, "extended80_arithmetic_driver.c" }), driver.written());
    const population = try u.toValue(c.a, .{ .population = "extended80_arithmetic", .prefix = "extended80-arithmetic", .fixture = "extended80_arithmetic", .functions = names.items, .libraries = [_][]const u8{"m"}, .observations = 61440, .stdout = "extended80-arithmetic observations=61440 native=llvm=literal=payloads=errno=x87=live=guards=preserved\n" });
    try c.writeJson(try c.join(&.{ output, "population.json" }), population);
    if (args.get("registry-input")) |path| {
        const original = try c.read(try c.join(&.{path}));
        const registry = try c.load(try c.join(&.{path}));
        for (try u.json.array(try u.get(registry, "canaries"))) |entry| if (std.mem.eql(u8, try u.str(entry, "population"), "extended80_arithmetic")) return error.PopulationAlreadyRegistered;
        const end = std.mem.lastIndexOf(u8, original, "\n  ]") orelse return error.UnexpectedRegistryLayout;
        const rendered = try std.json.Stringify.valueAlloc(c.a, population, .{ .whitespace = .indent_2 });
        const indented = try std.mem.replaceOwned(u8, c.a, rendered, "\n", "\n    ");
        try c.write(try c.join(&.{ output, "native_canaries.json" }), try c.fmt("{s},\n    {s}{s}", .{ original[0..end], indented, original[end..] }));
    }
}
