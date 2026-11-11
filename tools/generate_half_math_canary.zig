//! Exhaust every half input through LLVM22's promoted scalar math operations.
const std = @import("std");
const u = @import("validation/common.zig");
const operations = [_][]const u8{ "trunc", "round", "ceil", "floor", "log10", "log2", "log", "exp2", "exp", "tan", "cos", "sin", "sqrt", "fma" };
pub fn main(init: std.process.Init) !void {
    var c = try u.Context.init(init);
    const argv = try init.minimal.args.toSlice(c.a);
    const args = try u.Args.parse(c.a, argv[1..], &.{ "output-root", "registry-input" }, &.{});
    const output = try c.newOutput(try args.require("output-root"));
    var llvm: std.Io.Writer.Allocating = .init(c.a);
    var driver: std.Io.Writer.Allocating = .init(c.a);
    const w = &llvm.writer;
    const d = &driver.writer;
    try w.writeAll("target triple = \"x86_64-unknown-linux-gnu\"\ndeclare i64 @half_math_clobber(i64)\n");
    try d.writeAll("#define _GNU_SOURCE\n#include <stdint.h>\ntypedef uint64_t (*math_fn)(const uint8_t*,const uint8_t*,const uint8_t*,uint8_t*,uint64_t);\nstruct math_case {math_fn function;unsigned operation;};\n");
    var names: std.ArrayList([]const u8) = .empty;
    for (operations) |operation| {
        const fma = std.mem.eql(u8, operation, "fma");
        const name = try c.fmt("half_math_{s}", .{operation});
        try names.append(c.a, name);
        try w.print("declare half @llvm.{s}.f16(half{s})\ndefine i64 @{s}(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {{\nentry:\n %a = load half,ptr %left,align 1\n %b = load half,ptr %right,align 1\n %c = load half,ptr %third,align 1\n %r = call half @llvm.{s}.f16(half %a{s})\n %probe = call i64 @half_math_clobber(i64 %live)\n store half %r,ptr %output,align 1\n ret i64 %probe\n}}\n", .{ operation, if (fma) ",half,half" else "", name, operation, if (fma) ",half %b,half %c" else "" });
        try d.print("extern uint64_t {s}(const uint8_t*,const uint8_t*,const uint8_t*,uint8_t*,uint64_t);\n", .{name});
    }
    try d.writeAll("static const struct math_case cases[]={\n");
    for (operations, 0..) |operation, index| try d.print("{{half_math_{s},{d}}},\n", .{ operation, index });
    try d.writeAll("};\n");
    try d.writeAll(@embedFile("templates/half_math_driver.c"));
    try c.write(try c.join(&.{ output, "half_math.ll" }), llvm.written());
    try c.write(try c.join(&.{ output, "half_math_driver.c" }), driver.written());
    const population = try u.toValue(c.a, .{ .population = "half_math", .prefix = "half-math", .fixture = "half_math", .functions = names.items, .libraries = [_][]const u8{"m"}, .observations = 917504, .stdout = "half-math observations=917504 exhaustive=promotion=fma=rounding=errno=live=guards=preserved\n" });
    try c.writeJson(try c.join(&.{ output, "population.json" }), population);
    if (args.get("registry-input")) |path| {
        const original = try c.read(try c.join(&.{path}));
        const registry = try c.load(try c.join(&.{path}));
        for (try u.json.array(try u.get(registry, "canaries"))) |entry| if (std.mem.eql(u8, try u.str(entry, "population"), "half_math")) return error.PopulationAlreadyRegistered;
        const end = std.mem.lastIndexOf(u8, original, "\n  ]") orelse return error.UnexpectedRegistryLayout;
        const rendered = try std.json.Stringify.valueAlloc(c.a, population, .{ .whitespace = .indent_2 });
        const indented = try std.mem.replaceOwned(u8, c.a, rendered, "\n", "\n    ");
        try c.write(try c.join(&.{ output, "native_canaries.json" }), try c.fmt("{s},\n    {s}{s}", .{ original[0..end], indented, original[end..] }));
    }
}
