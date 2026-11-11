//! Binary16 multiplication/division with independent integer rounding oracles.
const std = @import("std");
const u = @import("validation/common.zig");

pub fn main(init: std.process.Init) !void {
    var c = try u.Context.init(init);
    const argv = try init.minimal.args.toSlice(c.a);
    const args = try u.Args.parse(c.a, argv[1..], &.{ "output-root", "registry-input" }, &.{});
    const output = try c.newOutput(try args.require("output-root"));
    var llvm: std.Io.Writer.Allocating = .init(c.a);
    var driver: std.Io.Writer.Allocating = .init(c.a);
    var rows: std.Io.Writer.Allocating = .init(c.a);
    const w = &llvm.writer;
    const d = &driver.writer;
    try w.writeAll("target triple = \"x86_64-unknown-linux-gnu\"\n");
    try d.writeAll("#include <stdint.h>\ntypedef uint64_t (*product_fn)(uint16_t,uint16_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint8_t*);\n");
    var names: std.ArrayList([]const u8) = .empty;
    for (0..41) |index| {
        const negation = index >= 32;
        const operand_case = if (negation) @as(usize, if (index < 34) 0 else index - 34) else index % 16;
        const constants = [_]u16{ 0x0000, 0x8000, 0x0001, 0x3c00, 0x70e2, 0x7c00, 0x7e55 };
        const mode: u8 = if (negation) (if (index < 34) 0 else 1) else if (operand_case == 0 or operand_case == 15) 0 else if (operand_case % 2 == 1) 1 else 2;
        const constant: u16 = if (mode == 0) 0 else constants[if (negation) operand_case else (operand_case - 1) / 2];
        const name = try c.fmt("half_product_{d}", .{index});
        try names.append(c.a, name);
        const literal = try c.fmt("0xH{X:0>4}", .{constant});
        const memory = index == 33 or (!negation and operand_case == 15);
        const lhs = if (memory) "%loaded" else if (mode == 1) literal else "%left";
        const operation = if (negation) try c.fmt("fneg half {s}", .{lhs}) else try c.fmt("{s} half {s}, {s}", .{ if (index < 16) "fmul" else "fdiv", lhs, if (mode == 2) literal else "%right" });
        try w.print(
            \\define i64 @{s}(i16 %a, i16 %b, i64 %live, i64 %e1, i64 %e2, i64 %e3, i64 %e4, ptr %out) {{
            \\entry:
            \\ %left = bitcast i16 %a to half
            \\ %right = bitcast i16 %b to half
            \\{s}
            \\ %raw = {s}
            \\ %bits = bitcast half %raw to i16
            \\ store i16 %bits, ptr %out, align 1
            \\ %wide = zext i16 %bits to i64
            \\ %aw = zext i16 %a to i64
            \\ %bw = zext i16 %b to i64
            \\ %one = xor i64 %live, %e1
            \\ %two = add i64 %one, %e2
            \\ %three = xor i64 %two, %e3
            \\ %four = add i64 %three, %e4
            \\ %mixed = xor i64 %four, %wide
            \\ %with_a = xor i64 %mixed, %aw
            \\ %answer = xor i64 %with_a, %bw
            \\ ret i64 %answer
            \\}}
            \\
        , .{ name, if (memory) " %loaded = load half, ptr %out, align 1" else "", operation });
        try d.print("extern uint64_t {s}(uint16_t,uint16_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint8_t*);\n", .{name});
        try rows.writer.print(" {{{s},{d},{d},{d}}},\n", .{ name, mode, constant, @as(u8, if (negation) 2 else if (index >= 16) 1 else 0) });
    }
    try d.writeAll("static const struct { product_fn run; unsigned mode; uint16_t constant; unsigned operation; } cases[]={\n");
    try d.writeAll(rows.written());
    try d.writeAll("};\n");
    try d.writeAll(@embedFile("templates/half_product_driver.c"));
    try c.write(try c.join(&.{ output, "half_product.ll" }), llvm.written());
    try c.write(try c.join(&.{ output, "half_product_driver.c" }), driver.written());
    const population = try u.toValue(c.a, .{
        .population = "half_product",
        .prefix = "half-product",
        .fixture = "half_product",
        .functions = names.items,
        .observations = 9371648,
        .stdout = "half-product observations=9371648 multiplication=division=negation=rounding=classes=bits=live=loads=stores=guards=preserved\n",
    });
    try c.writeJson(try c.join(&.{ output, "population.json" }), population);
    if (args.get("registry-input")) |path| {
        const original = try c.read(try c.join(&.{path}));
        const registry = try c.load(try c.join(&.{path}));
        for (try u.json.array(try u.get(registry, "canaries"))) |entry| if (std.mem.eql(u8, try u.str(entry, "population"), "half_product")) return error.PopulationAlreadyRegistered;
        const end = std.mem.lastIndexOf(u8, original, "\n  ]") orelse return error.UnexpectedRegistryLayout;
        const rendered = try std.json.Stringify.valueAlloc(c.a, population, .{ .whitespace = .indent_2 });
        const indented = try std.mem.replaceOwned(u8, c.a, rendered, "\n", "\n    ");
        try c.write(try c.join(&.{ output, "native_canaries.json" }), try c.fmt("{s},\n    {s}{s}", .{ original[0..end], indented, original[end..] }));
    }
}
