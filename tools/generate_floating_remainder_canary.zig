//! GNU libm remainders and exact half subtraction, with exhaustive half inputs.
const std = @import("std");
const u = @import("validation/common.zig");
const types = [_][]const u8{ "x86_fp80", "fp128", "float", "double", "half", "half" };
const left = [_][]const u8{ "0xK3FFFC000000000000000", "0xL00000000000000003FFF800000000000", "1.500000e+00", "1.500000e+00", "0xH3E00", "0xH3E00" };
const right = [_][]const u8{ "0xK4000A000000000000000", "0xL00000000000000004000400000000000", "2.500000e+00", "2.500000e+00", "0xH4100", "0xH4100" };
pub fn main(init: std.process.Init) !void {
    var c = try u.Context.init(init);
    const argv = try init.minimal.args.toSlice(c.a);
    const args = try u.Args.parse(c.a, argv[1..], &.{ "output-root", "registry-input" }, &.{});
    const output = try c.newOutput(try args.require("output-root"));
    var llvm: std.Io.Writer.Allocating = .init(c.a);
    var driver: std.Io.Writer.Allocating = .init(c.a);
    const w = &llvm.writer;
    const d = &driver.writer;
    try w.writeAll("target triple = \"x86_64-unknown-linux-gnu\"\ntarget datalayout = \"e-i128:128-f80:128\"\ndeclare i64 @floating_remainder_clobber(i64)\n");
    try d.writeAll("#define _GNU_SOURCE\n#define __STDC_WANT_IEC_60559_TYPES_EXT__ 1\n#include <stdint.h>\ntypedef unsigned __int128 u128;\ntypedef uint64_t (*math_fn)(const uint8_t*,const uint8_t*,const uint8_t*,uint8_t*,uint64_t);\nstruct math_case {math_fn function;unsigned format,operation,literal;};\n");
    var names: std.ArrayList([]const u8) = .empty;
    for (types, 0..) |ty, index| for (0..3) |variant| {
        const name = try c.fmt("floating_remainder_{d}_{d}", .{ index, variant });
        try names.append(c.a, name);
        try w.print("define i64 @{s}(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {{\nentry:\n %a = load {s},ptr %left,align 1\n %b = load {s},ptr %right,align 1\n %r = {s} {s} {s},{s}\n %probe = call i64 @floating_remainder_clobber(i64 %live)\n store {s} %r,ptr %output,align 1\n ret i64 %probe\n}}\n", .{ name, ty, ty, if (index == 5) "fsub" else "frem", ty, if (variant == 1) left[index] else "%a", if (variant == 2) right[index] else "%b", ty });
        try d.print("extern uint64_t {s}(const uint8_t*,const uint8_t*,const uint8_t*,uint8_t*,uint64_t);\n", .{name});
    };
    try d.writeAll("static const struct math_case cases[]={\n");
    for (types, 0..) |_, index| for (0..3) |variant| try d.print("{{floating_remainder_{d}_{d},{d},{d},{d}}},\n", .{ index, variant, @min(index, 4), if (index == 5) @as(usize, 15) else 14, variant });
    try d.writeAll("};\n");
    try d.writeAll(@embedFile("templates/floating_remainder_driver.c"));
    try c.write(try c.join(&.{ output, "floating_remainder.ll" }), llvm.written());
    try c.write(try c.join(&.{ output, "floating_remainder_driver.c" }), driver.written());
    const population = try u.toValue(c.a, .{ .population = "floating_remainder", .prefix = "floating-remainder", .fixture = "floating_remainder", .functions = names.items, .libraries = [_][]const u8{"m"}, .observations = 442368, .stdout = "floating-remainder observations=442368 libm=llvm=half-sub=literal=payloads=errno=x87=live=guards=preserved\n" });
    try c.writeJson(try c.join(&.{ output, "population.json" }), population);
    if (args.get("registry-input")) |path| {
        const original = try c.read(try c.join(&.{path}));
        const registry = try c.load(try c.join(&.{path}));
        for (try u.json.array(try u.get(registry, "canaries"))) |entry| if (std.mem.eql(u8, try u.str(entry, "population"), "floating_remainder")) return error.PopulationAlreadyRegistered;
        const end = std.mem.lastIndexOf(u8, original, "\n  ]") orelse return error.UnexpectedRegistryLayout;
        const rendered = try std.json.Stringify.valueAlloc(c.a, population, .{ .whitespace = .indent_2 });
        const indented = try std.mem.replaceOwned(u8, c.a, rendered, "\n", "\n    ");
        try c.write(try c.join(&.{ output, "native_canaries.json" }), try c.fmt("{s},\n    {s}{s}", .{ original[0..end], indented, original[end..] }));
    }
}
