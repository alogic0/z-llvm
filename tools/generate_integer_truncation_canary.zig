//! Typed i52 truncations, dirty source padding, live inputs and exact stores.
const std = @import("std");
const u = @import("validation/common.zig");

pub fn main(init: std.process.Init) !void {
    var c = try u.Context.init(init);
    const argv = try init.minimal.args.toSlice(c.a);
    const args = try u.Args.parse(c.a, argv[1..], &.{ "output-root", "registry-input" }, &.{});
    const output = try c.newOutput(try args.require("output-root"));
    var llvm: std.Io.Writer.Allocating = .init(c.a);
    var driver: std.Io.Writer.Allocating = .init(c.a);
    const w = &llvm.writer;
    const d = &driver.writer;
    try w.writeAll("target triple = \"x86_64-unknown-linux-gnu\"\n");
    try d.writeAll("#include <stdint.h>\ntypedef uint64_t (*truncation_fn)(uint64_t,uint64_t,uint8_t*,uint64_t,uint64_t,uint64_t,uint64_t);\n");
    var names: std.ArrayList([]const u8) = .empty;
    var cases: std.Io.Writer.Allocating = .init(c.a);
    const widths = [_]u16{ 53, 55, 56, 63, 64, 1, 2, 5, 6, 7, 8, 16, 31, 32, 33, 51 };
    for (widths) |width| {
        const from: u16 = if (width > 52) width else 52;
        const to: u16 = if (width > 52) 52 else width;
        const name = try c.fmt("integer_truncation_{d}_to_{d}", .{ from, to });
        try names.append(c.a, name);
        try w.print(
            \\define i64 @{s}(i64 %input, i64 %live, ptr %out, i64 %extra1, i64 %extra2, i64 %extra3, i64 %extra4) {{
            \\entry:
        , .{name});
        if (from == 64) {
            try w.writeAll("\n %source = add i64 %input, 0\n");
        } else try w.print("\n %source = trunc i64 %input to i{d}\n", .{from});
        try w.print(
            \\ %narrow = trunc i{d} %source to i{d}
            \\ store i{d} %narrow, ptr %out, align 1
            \\ %wide = zext i{d} %narrow to i64
            \\ %one = xor i64 %live, %extra1
            \\ %two = add i64 %one, %extra2
            \\ %three = xor i64 %two, %extra3
            \\ %four = add i64 %three, %extra4
            \\ %mixed = xor i64 %wide, %input
            \\ %answer = xor i64 %mixed, %four
            \\ ret i64 %answer
            \\}}
            \\
        , .{ from, to, to, to });
        try d.print("extern uint64_t {s}(uint64_t,uint64_t,uint8_t*,uint64_t,uint64_t,uint64_t,uint64_t);\n", .{name});
        try cases.writer.print(" {{{s},{d}}},\n", .{ name, to });
    }
    try d.writeAll("static const struct { truncation_fn run; unsigned bits; } cases[]={\n");
    try d.writeAll(cases.written());
    try d.writeAll("};\n");
    try d.writeAll(@embedFile("templates/integer_truncation_driver.c"));
    try c.write(try c.join(&.{ output, "integer_truncation.ll" }), llvm.written());
    try c.write(try c.join(&.{ output, "integer_truncation_driver.c" }), driver.written());
    const population = try u.toValue(c.a, .{
        .population = "integer_truncation",
        .prefix = "integer-truncation",
        .fixture = "integer_truncation",
        .functions = names.items,
        .observations = 1024,
        .stdout = "integer-truncation observations=1024 widths=padding=live=stores=guards=preserved\n",
    });
    try c.writeJson(try c.join(&.{ output, "population.json" }), population);
    if (args.get("registry-input")) |path| {
        const original = try c.read(try c.join(&.{path}));
        const registry = try c.load(try c.join(&.{path}));
        for (try u.json.array(try u.get(registry, "canaries"))) |entry| if (std.mem.eql(u8, try u.str(entry, "population"), "integer_truncation")) return error.PopulationAlreadyRegistered;
        const end = std.mem.lastIndexOf(u8, original, "\n  ]") orelse return error.UnexpectedRegistryLayout;
        const rendered = try std.json.Stringify.valueAlloc(c.a, population, .{ .whitespace = .indent_2 });
        const indented = try std.mem.replaceOwned(u8, c.a, rendered, "\n", "\n    ");
        try c.write(try c.join(&.{ output, "native_canaries.json" }), try c.fmt("{s},\n    {s}{s}", .{ original[0..end], indented, original[end..] }));
    }
}
