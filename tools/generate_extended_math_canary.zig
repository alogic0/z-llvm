//! Standard GNU libm boundaries, checked against independent LLVM lowering.
const std = @import("std");
const u = @import("validation/common.zig");
const operations = [_][]const u8{ "trunc", "round", "ceil", "floor", "log10", "log2", "log", "exp2", "exp", "tan", "cos", "sin", "sqrt", "fma" };
const types = [_][]const u8{ "x86_fp80", "fp128", "float", "double" };
const widths = [_]usize{ 80, 128, 32, 64 };
pub fn main(init: std.process.Init) !void {
    var c = try u.Context.init(init);
    const argv = try init.minimal.args.toSlice(c.a);
    const args = try u.Args.parse(c.a, argv[1..], &.{ "output-root", "registry-input" }, &.{});
    const output = try c.newOutput(try args.require("output-root"));
    var llvm: std.Io.Writer.Allocating = .init(c.a);
    var driver: std.Io.Writer.Allocating = .init(c.a);
    const w = &llvm.writer;
    const d = &driver.writer;
    try w.writeAll("target triple = \"x86_64-unknown-linux-gnu\"\ntarget datalayout = \"e-i128:128-f80:128\"\ndeclare i64 @extended_math_clobber(i64)\n");
    try d.writeAll("#define _GNU_SOURCE\n#define __STDC_WANT_IEC_60559_TYPES_EXT__ 1\n#include <stdint.h>\ntypedef unsigned __int128 u128;\ntypedef uint64_t (*math_fn)(const uint8_t*,const uint8_t*,const uint8_t*,uint8_t*,uint64_t);\nstruct math_case {math_fn function;unsigned format,operation;};\n");
    var names: std.ArrayList([]const u8) = .empty;
    for (0..types.len) |format| for (operations, 0..) |operation, index| {
        if (format != 1 and std.mem.eql(u8, operation, "sqrt")) continue;
        const ty = types[format];
        const bits = widths[format];
        const fma = std.mem.eql(u8, operation, "fma");
        const name = try c.fmt("extended_math_{d}_{s}", .{ bits, operation });
        try names.append(c.a, name);
        try w.print("declare {s} @llvm.{s}.f{d}({s}{s})\ndefine i64 @{s}(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {{\nentry:\n %a = load {s},ptr %left,align 1\n %b = load {s},ptr %right,align 1\n %c = load {s},ptr %third,align 1\n %r = call {s} @llvm.{s}.f{d}({s} %a{s})\n %probe = call i64 @extended_math_clobber(i64 %live)\n store {s} %r,ptr %output,align 1\n ret i64 %probe\n}}\n", .{
            ty, operation,                                                 bits, ty, if (fma) try c.fmt(",{s},{s}", .{ ty, ty }) else "", name,
            ty, ty,                                                        ty,   ty, operation,                                           bits,
            ty, if (fma) try c.fmt(",{s} %b,{s} %c", .{ ty, ty }) else "", ty,
        });
        try d.print("extern uint64_t {s}(const uint8_t*,const uint8_t*,const uint8_t*,uint8_t*,uint64_t);\n", .{name});
        _ = index;
    };
    try d.writeAll("static const struct math_case cases[]={\n");
    for (0..types.len) |format| for (operations, 0..) |operation, index| {
        if (format != 1 and std.mem.eql(u8, operation, "sqrt")) continue;
        try d.print("{{extended_math_{d}_{s},{d},{d}}},\n", .{ widths[format], operation, format, index });
    };
    try d.writeAll("};\n");
    try d.writeAll(@embedFile("templates/extended_math_driver.c"));
    try c.write(try c.join(&.{ output, "extended_math.ll" }), llvm.written());
    try c.write(try c.join(&.{ output, "extended_math_driver.c" }), driver.written());
    const population = try u.toValue(c.a, .{ .population = "extended_math", .prefix = "extended-math", .fixture = "extended_math", .functions = names.items, .libraries = [_][]const u8{"m"}, .observations = 217088, .stdout = "extended-math observations=217088 libm=llvm=payloads=errno=x87=live=guards=preserved\n" });
    try c.writeJson(try c.join(&.{ output, "population.json" }), population);
    if (args.get("registry-input")) |path| {
        const original = try c.read(try c.join(&.{path}));
        const registry = try c.load(try c.join(&.{path}));
        for (try u.json.array(try u.get(registry, "canaries"))) |entry| if (std.mem.eql(u8, try u.str(entry, "population"), "extended_math")) return error.PopulationAlreadyRegistered;
        const end = std.mem.lastIndexOf(u8, original, "\n  ]") orelse return error.UnexpectedRegistryLayout;
        const rendered = try std.json.Stringify.valueAlloc(c.a, population, .{ .whitespace = .indent_2 });
        const indented = try std.mem.replaceOwned(u8, c.a, rendered, "\n", "\n    ");
        try c.write(try c.join(&.{ output, "native_canaries.json" }), try c.fmt("{s},\n    {s}{s}", .{ original[0..end], indented, original[end..] }));
    }
}
