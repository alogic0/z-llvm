//! Independent byte reversal across complete native pairs and call clobbers.
const std = @import("std");
const u = @import("validation/common.zig");
const widths = [_]usize{ 80, 96, 112, 128 };
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
    try w.writeAll("target triple = \"x86_64-unknown-linux-gnu\"\ntarget datalayout = \"e-i128:128\"\ndeclare i64 @wide_bswap_clobber(i64)\n");
    try d.writeAll("#define _GNU_SOURCE\n#include <stdint.h>\ntypedef unsigned __int128 u128;\ntypedef u128 (*swap_fn)(u128,uint8_t*,uint64_t);\nstruct swap_case {swap_fn function;unsigned width,literal;};\n");
    var names: std.ArrayList([]const u8) = .empty;
    for (widths) |bits| {
        try w.print("declare i{d} @llvm.bswap.i{d}(i{d})\n", .{ bits, bits, bits });
        for ([_]bool{ false, true }) |literal| {
            const name = try c.fmt("wide_bswap_{d}_{s}", .{ bits, if (literal) "literal" else "argument" });
            try names.append(c.a, name);
            try w.print("define i128 @{s}(i128 %input,ptr %output,i64 %live) {{\nentry:\n", .{name});
            if (bits == 128) try w.writeAll(" %narrow = add i128 %input,0\n") else try w.print(" %narrow = trunc i128 %input to i{d}\n", .{bits});
            const mask = if (bits == 128) std.math.maxInt(u128) else (@as(u128, 1) << @as(u7, @intCast(bits))) - 1;
            const value = if (literal) try c.fmt("{d}", .{@as(i128, @bitCast(fixed & mask))}) else "%narrow";
            try w.print(" %swapped = call i{d} @llvm.bswap.i{d}(i{d} {s})\n", .{ bits, bits, bits, value });
            if (bits == 128) try w.writeAll(" %wide = add i128 %swapped,0\n") else try w.print(" %wide = zext i{d} %swapped to i128\n", .{bits});
            try w.writeAll(" %probe = call i64 @wide_bswap_clobber(i64 %live)\n store i128 %wide,ptr %output,align 1\n %extended = zext i64 %probe to i128\n %answer = xor i128 %wide,%extended\n ret i128 %answer\n}\n");
            try d.print("extern u128 {s}(u128,uint8_t*,uint64_t);\n", .{name});
        }
    }
    try d.writeAll("static const struct swap_case cases[]={\n");
    for (widths) |bits| for ([_]bool{ false, true }) |literal| try d.print("{{wide_bswap_{d}_{s},{d},{d}}},\n", .{ bits, if (literal) "literal" else "argument", bits, @intFromBool(literal) });
    try d.writeAll("};\n");
    try d.writeAll(@embedFile("templates/wide_bswap_driver.c"));
    try c.write(try c.join(&.{ output, "wide_bswap.ll" }), llvm.written());
    try c.write(try c.join(&.{ output, "wide_bswap_driver.c" }), driver.written());
    const population = try u.toValue(c.a, .{ .population = "wide_bswap", .prefix = "wide-bswap", .fixture = "wide_bswap", .functions = names.items, .observations = 65536, .stdout = "wide-bswap observations=65536 bytes=widths=literal=live=guards=preserved\n" });
    try c.writeJson(try c.join(&.{ output, "population.json" }), population);
    if (args.get("registry-input")) |path| {
        const original = try c.read(try c.join(&.{path}));
        const registry = try c.load(try c.join(&.{path}));
        for (try u.json.array(try u.get(registry, "canaries"))) |entry| if (std.mem.eql(u8, try u.str(entry, "population"), "wide_bswap")) return error.PopulationAlreadyRegistered;
        const end = std.mem.lastIndexOf(u8, original, "\n  ]") orelse return error.UnexpectedRegistryLayout;
        const rendered = try std.json.Stringify.valueAlloc(c.a, population, .{ .whitespace = .indent_2 });
        const indented = try std.mem.replaceOwned(u8, c.a, rendered, "\n", "\n    ");
        try c.write(try c.join(&.{ output, "native_canaries.json" }), try c.fmt("{s},\n    {s}{s}", .{ original[0..end], indented, original[end..] }));
    }
}
