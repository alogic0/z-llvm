//! Integer-defined truncation and single-rounding oracles across scalar formats.
const std = @import("std");
const u = @import("validation/common.zig");
const widths = [_]usize{ 1, 8, 16, 32, 52, 64, 65, 80, 113, 127, 128 };
const formats = [_][]const u8{ "half", "float", "double", "fp128" };
const fixed: u128 = 0xfedcba98765432100123456789abcdef;
pub fn main(init: std.process.Init) !void {
    var c = try u.Context.init(init);
    const argv = try init.minimal.args.toSlice(c.a);
    const args = try u.Args.parse(c.a, argv[1..], &.{ "output-root", "registry-input" }, &.{});
    const output = try c.newOutput(try args.require("output-root"));
    var llvm: std.Io.Writer.Allocating = .init(c.a);
    var driver: std.Io.Writer.Allocating = .init(c.a);
    const w = &llvm.writer;
    const d = &driver.writer;
    try w.writeAll("target triple = \"x86_64-unknown-linux-gnu\"\ntarget datalayout = \"e-i128:128\"\ndeclare i64 @scalar_integer_clobber(i64)\n");
    try d.writeAll("#define _GNU_SOURCE\n#include <stdint.h>\ntypedef unsigned __int128 u128;\ntypedef u128 (*to_fn)(u128,uint8_t*,uint64_t);\ntypedef u128 (*from_fn)(const uint8_t*,uint8_t*,uint64_t);\nstruct to_case {to_fn function;unsigned width,sign,literal;};\nstruct from_case {from_fn function;unsigned format,width,sign;};\n");
    var names: std.ArrayList([]const u8) = .empty;
    for (0..widths.len + 1) |index| for (0..2) |sign| {
        const bits = if (index == widths.len) 128 else widths[index];
        const literal = index == widths.len;
        const name = try c.fmt("scalar_integer_to_quad_{d}_{d}_{d}", .{ bits, sign, @intFromBool(literal) });
        try names.append(c.a, name);
        try w.print("define i128 @{s}(i128 %raw,ptr %output,i64 %live) {{\nentry:\n", .{name});
        if (bits == 128) try w.writeAll(" %narrow = add i128 %raw,0\n") else try w.print(" %narrow = trunc i128 %raw to i{d}\n", .{bits});
        const value = if (literal) try c.fmt("{d}", .{@as(i128, @bitCast(fixed))}) else "%narrow";
        try w.print(" %converted = {s} i{d} {s} to fp128\n %probe = call i64 @scalar_integer_clobber(i64 %live)\n store fp128 %converted,ptr %output,align 1\n %wide = zext i64 %probe to i128\n %answer = xor i128 %raw,%wide\n ret i128 %answer\n}}\n", .{ if (sign == 1) "sitofp" else "uitofp", bits, value });
        try d.print("extern u128 {s}(u128,uint8_t*,uint64_t);\n", .{name});
    };
    for (formats, 0..) |ty, format| for (widths) |bits| for (0..2) |sign| {
        const name = try c.fmt("scalar_integer_from_{d}_{d}_{d}", .{ format, bits, sign });
        try names.append(c.a, name);
        try w.print("define i128 @{s}(ptr %input,ptr %output,i64 %live) {{\nentry:\n %value = load {s},ptr %input,align 1\n %converted = {s} {s} %value to i{d}\n", .{ name, ty, if (sign == 1) "fptosi" else "fptoui", ty, bits });
        if (bits == 128) try w.writeAll(" %wide = add i128 %converted,0\n") else try w.print(" %wide = zext i{d} %converted to i128\n", .{bits});
        try w.writeAll(" %probe = call i64 @scalar_integer_clobber(i64 %live)\n store i128 %wide,ptr %output,align 1\n %extended = zext i64 %probe to i128\n %answer = xor i128 %wide,%extended\n ret i128 %answer\n}\n");
        try d.print("extern u128 {s}(const uint8_t*,uint8_t*,uint64_t);\n", .{name});
    };
    try d.writeAll("static const struct to_case to_cases[]={\n");
    for (0..widths.len + 1) |index| for (0..2) |sign| {
        const bits = if (index == widths.len) 128 else widths[index];
        const literal = @intFromBool(index == widths.len);
        try d.print("{{scalar_integer_to_quad_{d}_{d}_{d},{d},{d},{d}}},\n", .{ bits, sign, literal, bits, sign, literal });
    };
    try d.writeAll("};\nstatic const struct from_case from_cases[]={\n");
    for (0..formats.len) |format| for (widths) |bits| for (0..2) |sign| try d.print("{{scalar_integer_from_{d}_{d}_{d},{d},{d},{d}}},\n", .{ format, bits, sign, format, bits, sign });
    try d.writeAll("};\n");
    try d.writeAll(@embedFile("templates/scalar_integer_driver.c"));
    try c.write(try c.join(&.{ output, "scalar_integer.ll" }), llvm.written());
    try c.write(try c.join(&.{ output, "scalar_integer_driver.c" }), driver.written());
    const population = try u.toValue(c.a, .{ .population = "scalar_integer", .prefix = "scalar-integer", .fixture = "scalar_integer", .functions = names.items, .observations = 458752, .stdout = "scalar-integer observations=458752 formats=widths=rounding=truncation=literal=live=guards=preserved\n" });
    try c.writeJson(try c.join(&.{ output, "population.json" }), population);
    if (args.get("registry-input")) |path| {
        const original = try c.read(try c.join(&.{path}));
        const registry = try c.load(try c.join(&.{path}));
        for (try u.json.array(try u.get(registry, "canaries"))) |entry| if (std.mem.eql(u8, try u.str(entry, "population"), "scalar_integer")) return error.PopulationAlreadyRegistered;
        const end = std.mem.lastIndexOf(u8, original, "\n  ]") orelse return error.UnexpectedRegistryLayout;
        const rendered = try std.json.Stringify.valueAlloc(c.a, population, .{ .whitespace = .indent_2 });
        const indented = try std.mem.replaceOwned(u8, c.a, rendered, "\n", "\n    ");
        try c.write(try c.join(&.{ output, "native_canaries.json" }), try c.fmt("{s},\n    {s}{s}", .{ original[0..end], indented, original[end..] }));
    }
}
