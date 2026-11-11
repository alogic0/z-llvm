//! Integer/extended80 conversion fixtures with integer-only independent oracles.
const std = @import("std");
const u = @import("validation/common.zig");

const widths = [_]u16{ 1, 8, 16, 32, 52, 64, 65, 80, 127, 128 };

fn toFloat(w: *std.Io.Writer, name: []const u8, width: u16, signed: bool, constant: ?u128) !void {
    try w.print("define i128 @{s}(i128 %raw,ptr %output,i64 %live) {{\nentry:\n", .{name});
    if (constant) |raw| {
        try w.print(" %converted = {s} i128 {d} to x86_fp80\n", .{ if (signed) "sitofp" else "uitofp", @as(i128, @bitCast(raw)) });
    } else {
        try w.writeAll(" %word = trunc i128 %raw to i64\n");
        if (width == 128) try w.writeAll(" %narrow = add i128 %raw,0\n") else try w.print(" %narrow = trunc {s} {s} to i{d}\n", .{ if (width < 64) "i64" else "i128", if (width < 64) "%word" else "%raw", width });
        try w.print(" %converted = {s} i{d} %narrow to x86_fp80\n", .{ if (signed) "sitofp" else "uitofp", width });
    }
    try w.writeAll(" %probe = call i64 @extended80_integer_clobber(i64 %live)\n store x86_fp80 %converted,ptr %output,align 1\n %mask = zext i64 %probe to i128\n %answer = xor i128 %raw,%mask\n ret i128 %answer\n}\n");
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
    try w.writeAll("target triple = \"x86_64-unknown-linux-gnu\"\ntarget datalayout = \"e-i128:128-f80:128\"\ndeclare i64 @extended80_integer_clobber(i64)\n");
    try d.writeAll("#define _GNU_SOURCE\n#include <stdint.h>\ntypedef unsigned __int128 u128;\ntypedef u128 (*to_fn)(u128,uint8_t*,uint64_t);\ntypedef u128 (*from_fn)(const uint8_t*,uint8_t*,uint64_t);\nstruct to_case {to_fn function;unsigned width,sign,constant;u128 raw;};\nstruct from_case {from_fn function;unsigned width,sign;};\n");
    var names: std.ArrayList([]const u8) = .empty;
    for (widths) |width| for ([_]bool{ false, true }) |signed| {
        const to = try c.fmt("extended80_itof_{s}{d}", .{ if (signed) "s" else "u", width });
        const from = try c.fmt("extended80_ftoi_{s}{d}", .{ if (signed) "s" else "u", width });
        try names.appendSlice(c.a, &.{ to, from });
        try toFloat(w, to, width, signed, null);
        try w.print("define i128 @{s}(ptr %input,ptr %output,i64 %live) {{\nentry:\n %x = load x86_fp80,ptr %input,align 1\n %narrow = {s} x86_fp80 %x to i{d}\n", .{ from, if (signed) "fptosi" else "fptoui", width });
        if (width == 128) try w.writeAll(" %wide = add i128 %narrow,0\n") else try w.print(" %wide = {s} i{d} %narrow to i128\n", .{ if (signed) "sext" else "zext", width });
        try w.writeAll(" %probe = call i64 @extended80_integer_clobber(i64 %live)\n store i128 %wide,ptr %output,align 1\n %mask = zext i64 %probe to i128\n %answer = xor i128 %wide,%mask\n ret i128 %answer\n}\n");
        try d.print("extern u128 {s}(u128,uint8_t*,uint64_t);\nextern u128 {s}(const uint8_t*,uint8_t*,uint64_t);\n", .{ to, from });
    };
    const constants = [_]u128{ @as(u128, 1) << 127, std.math.maxInt(u128), 0, (@as(u128, 1) << 63) + 1 };
    for (constants, 0..) |raw, index| {
        const name = try c.fmt("extended80_itof_constant_{d}", .{index});
        try names.append(c.a, name);
        try toFloat(w, name, 128, index == 0 or index == 3, raw);
        try d.print("extern u128 {s}(u128,uint8_t*,uint64_t);\n", .{name});
    }
    try d.writeAll("static const struct to_case to_cases[]={\n");
    for (widths) |width| for ([_]bool{ false, true }) |signed| try d.print("{{extended80_itof_{s}{d},{d},{d},0,0}},\n", .{ if (signed) "s" else "u", width, width, @intFromBool(signed) });
    for (constants, 0..) |raw, index| try d.print("{{extended80_itof_constant_{d},128,{d},1,((u128)UINT64_C(0x{x})<<64)|UINT64_C(0x{x})}},\n", .{ index, @intFromBool(index == 0 or index == 3), @as(u64, @truncate(raw >> 64)), @as(u64, @truncate(raw)) });
    try d.writeAll("};\nstatic const struct from_case from_cases[]={\n");
    for (widths) |width| for ([_]bool{ false, true }) |signed| try d.print("{{extended80_ftoi_{s}{d},{d},{d}}},\n", .{ if (signed) "s" else "u", width, width, @intFromBool(signed) });
    try d.writeAll("};\n");
    try d.writeAll(@embedFile("templates/extended80_integer_driver.c"));
    try c.write(try c.join(&.{ output, "extended80_integer.ll" }), llvm.written());
    try c.write(try c.join(&.{ output, "extended80_integer_driver.c" }), driver.written());
    const population = try u.toValue(c.a, .{
        .population = "extended80_integer",
        .prefix = "extended80-integer",
        .fixture = "extended80_integer",
        .functions = names.items,
        .observations = 180224,
        .stdout = "extended80-integer observations=180224 rounding=truncation=widths=literal=live=guards=preserved\n",
    });
    try c.writeJson(try c.join(&.{ output, "population.json" }), population);
    if (args.get("registry-input")) |path| {
        const original = try c.read(try c.join(&.{path}));
        const registry = try c.load(try c.join(&.{path}));
        for (try u.json.array(try u.get(registry, "canaries"))) |entry| if (std.mem.eql(u8, try u.str(entry, "population"), "extended80_integer")) return error.PopulationAlreadyRegistered;
        const end = std.mem.lastIndexOf(u8, original, "\n  ]") orelse return error.UnexpectedRegistryLayout;
        const rendered = try std.json.Stringify.valueAlloc(c.a, population, .{ .whitespace = .indent_2 });
        const indented = try std.mem.replaceOwned(u8, c.a, rendered, "\n", "\n    ");
        try c.write(try c.join(&.{ output, "native_canaries.json" }), try c.fmt("{s},\n    {s}{s}", .{ original[0..end], indented, original[end..] }));
    }
}
