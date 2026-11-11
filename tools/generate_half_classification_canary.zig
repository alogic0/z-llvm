//! Exhaustive binary16 representation classes with independent LLVM checks.
const std = @import("std");
const u = @import("validation/common.zig");
const masks = [_]usize{ 0, 1, 2, 4, 8, 16, 32, 64, 128, 256, 512, 3, 1020, 448, 60, 1023 };
pub fn main(init: std.process.Init) !void {
    var c = try u.Context.init(init);
    const argv = try init.minimal.args.toSlice(c.a);
    const args = try u.Args.parse(c.a, argv[1..], &.{ "output-root", "registry-input" }, &.{});
    const out = try c.newOutput(try args.require("output-root"));
    var llvm: std.Io.Writer.Allocating = .init(c.a);
    var driver: std.Io.Writer.Allocating = .init(c.a);
    const w = &llvm.writer;
    const d = &driver.writer;
    try w.writeAll("target triple = \"x86_64-unknown-linux-gnu\"\ndeclare i1 @llvm.is.fpclass.f16(half,i32)\ndeclare i64 @half_classification_clobber(i64)\n");
    try d.writeAll("#define _GNU_SOURCE\n#include <stdint.h>\ntypedef uint64_t (*class_fn)(const uint8_t*,uint8_t*,uint64_t);\nstruct class_case {class_fn function;unsigned mask;};\n");
    var names: std.ArrayList([]const u8) = .empty;
    for (masks) |mask| {
        const name = try c.fmt("half_classification_{d}", .{mask});
        try names.append(c.a, name);
        try w.print("define i64 @{s}(ptr %input,ptr %out,i64 %live) {{\nentry:\n %value = load half,ptr %input,align 1\n %condition = call i1 @llvm.is.fpclass.f16(half %value,i32 {d})\n %byte = zext i1 %condition to i8\n %wide = zext i1 %condition to i64\n %probe = call i64 @half_classification_clobber(i64 %live)\n store i8 %byte,ptr %out,align 1\n %answer = xor i64 %wide,%probe\n ret i64 %answer\n}}\n", .{ name, mask });
        try d.print("extern uint64_t {s}(const uint8_t*,uint8_t*,uint64_t);\n", .{name});
    }
    try d.writeAll("static const struct class_case cases[]={\n");
    for (masks) |mask| try d.print("{{half_classification_{d},{d}}},\n", .{ mask, mask });
    try d.writeAll("};\n");
    try d.writeAll(@embedFile("templates/half_classification_driver.c"));
    try c.write(try c.join(&.{ out, "half_classification.ll" }), llvm.written());
    try c.write(try c.join(&.{ out, "half_classification_driver.c" }), driver.written());
    const pop = try u.toValue(c.a, .{ .population = "half_classification", .prefix = "half-classification", .fixture = "half_classification", .functions = names.items, .observations = 1048576, .stdout = "half-classification observations=1048576 exhaustive=classes=masks=live=guards=preserved\n" });
    try c.writeJson(try c.join(&.{ out, "population.json" }), pop);
    if (args.get("registry-input")) |path| {
        const original = try c.read(try c.join(&.{path}));
        const registry = try c.load(try c.join(&.{path}));
        for (try u.json.array(try u.get(registry, "canaries"))) |entry| if (std.mem.eql(u8, try u.str(entry, "population"), "half_classification")) return error.PopulationAlreadyRegistered;
        const end = std.mem.lastIndexOf(u8, original, "\n  ]") orelse return error.UnexpectedRegistryLayout;
        const rendered = try std.json.Stringify.valueAlloc(c.a, pop, .{ .whitespace = .indent_2 });
        const indented = try std.mem.replaceOwned(u8, c.a, rendered, "\n", "\n    ");
        try c.write(try c.join(&.{ out, "native_canaries.json" }), try c.fmt("{s},\n    {s}{s}", .{ original[0..end], indented, original[end..] }));
    }
}
