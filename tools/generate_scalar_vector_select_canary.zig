//! Scalar conditions choose one complete payload without lane mixing.
const std = @import("std");
const u = @import("validation/common.zig");
const types = [_][]const u8{ "fp128", "fp128", "<2 x float>", "<2 x double>" };
pub fn main(init: std.process.Init) !void {
    var c = try u.Context.init(init);
    const argv = try init.minimal.args.toSlice(c.a);
    const args = try u.Args.parse(c.a, argv[1..], &.{ "output-root", "registry-input" }, &.{});
    const output = try c.newOutput(try args.require("output-root"));
    var llvm: std.Io.Writer.Allocating = .init(c.a);
    var driver: std.Io.Writer.Allocating = .init(c.a);
    const w = &llvm.writer;
    const d = &driver.writer;
    try w.writeAll("target triple = \"x86_64-unknown-linux-gnu\"\ntarget datalayout = \"e-i128:128\"\ndeclare i64 @scalar_vector_select_clobber(i64)\n");
    try d.writeAll("#define _GNU_SOURCE\n#include <stdint.h>\ntypedef unsigned __int128 u128;\ntypedef uint64_t (*choice_fn)(uint64_t,const uint8_t*,const uint8_t*,uint8_t*,uint64_t);\nstruct choice_case {choice_fn function;unsigned size,literal;};\n");
    var names: std.ArrayList([]const u8) = .empty;
    for (types, 0..) |ty, index| {
        const name = try c.fmt("scalar_vector_select_{d}", .{index});
        try names.append(c.a, name);
        try w.print("define i64 @{s}(i64 %choice,ptr %left,ptr %right,ptr %output,i64 %live) {{\nentry:\n %a = load {s},ptr %left,align 1\n %b = load {s},ptr %right,align 1\n %condition = trunc i64 %choice to i1\n %selected = select i1 %condition,{s} {s},{s} %b\n %probe = call i64 @scalar_vector_select_clobber(i64 %live)\n store {s} %selected,ptr %output,align 1\n %answer = xor i64 %probe,%choice\n ret i64 %answer\n}}\n", .{ name, ty, ty, ty, if (index == 1) "0xL00000000000000017FFF000000000000" else "%a", ty, ty });
        try d.print("extern uint64_t {s}(uint64_t,const uint8_t*,const uint8_t*,uint8_t*,uint64_t);\n", .{name});
    }
    try d.writeAll("static const struct choice_case cases[]={\n");
    for (0..types.len) |index| try d.print("{{scalar_vector_select_{d},{d},{d}}},\n", .{ index, if (index == 2) @as(usize, 8) else 16, @intFromBool(index == 1) });
    try d.writeAll("};\n");
    try d.writeAll(@embedFile("templates/scalar_vector_select_driver.c"));
    try c.write(try c.join(&.{ output, "scalar_vector_select.ll" }), llvm.written());
    try c.write(try c.join(&.{ output, "scalar_vector_select_driver.c" }), driver.written());
    const population = try u.toValue(c.a, .{ .population = "scalar_vector_select", .prefix = "scalar-vector-select", .fixture = "scalar_vector_select", .functions = names.items, .observations = 32768, .stdout = "scalar-vector-select observations=32768 whole=literal=payloads=live=guards=preserved\n" });
    try c.writeJson(try c.join(&.{ output, "population.json" }), population);
    if (args.get("registry-input")) |path| {
        const original = try c.read(try c.join(&.{path}));
        const registry = try c.load(try c.join(&.{path}));
        for (try u.json.array(try u.get(registry, "canaries"))) |entry| if (std.mem.eql(u8, try u.str(entry, "population"), "scalar_vector_select")) return error.PopulationAlreadyRegistered;
        const end = std.mem.lastIndexOf(u8, original, "\n  ]") orelse return error.UnexpectedRegistryLayout;
        const rendered = try std.json.Stringify.valueAlloc(c.a, population, .{ .whitespace = .indent_2 });
        const indented = try std.mem.replaceOwned(u8, c.a, rendered, "\n", "\n    ");
        try c.write(try c.join(&.{ output, "native_canaries.json" }), try c.fmt("{s},\n    {s}{s}", .{ original[0..end], indented, original[end..] }));
    }
}
