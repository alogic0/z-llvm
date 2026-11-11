//! Native binary16/binary128/i128 conversions and independent integer oracles.
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
    try w.writeAll("declare fp128 @extended_mixed_quad(i64, i128, fp128, i128, i64)\ndeclare i128 @extended_mixed_integer(fp128, i64, i128)\n");
    try d.writeAll("#include <stdint.h>\ntypedef unsigned __int128 u128;\ntypedef u128 (*conversion_fn)(u128,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint8_t*);\n");
    const Conversion = struct { suffix: []const u8, op: []const u8, from: []const u8, to: []const u8, literal: ?[]const u8 = null };
    const cases = [_]Conversion{
        .{ .suffix = "from_half", .op = "fpext", .from = "half", .to = "fp128" },
        .{ .suffix = "from_signed", .op = "sitofp", .from = "i128", .to = "fp128" },
        .{ .suffix = "from_unsigned", .op = "uitofp", .from = "i128", .to = "fp128" },
        .{ .suffix = "to_half", .op = "fptrunc", .from = "fp128", .to = "half" },
        .{ .suffix = "to_signed", .op = "fptosi", .from = "fp128", .to = "i128" },
        .{ .suffix = "to_unsigned", .op = "fptoui", .from = "fp128", .to = "i128" },
        .{ .suffix = "signed_literal", .op = "sitofp", .from = "i128", .to = "fp128", .literal = "-170141183460469231731687303715884105727" },
        // LLVM integers are bit patterns: -1 spells the full unsigned i128
        // value without requiring an out-of-range signed parser accumulator.
        .{ .suffix = "unsigned_literal", .op = "uitofp", .from = "i128", .to = "fp128", .literal = "-1" },
        .{ .suffix = "mixed_quad", .op = "call_quad", .from = "fp128", .to = "fp128" },
        .{ .suffix = "mixed_integer", .op = "call_integer", .from = "fp128", .to = "i128" },
    };
    var names: std.ArrayList([]const u8) = .empty;
    for (cases) |case| {
        const name = try c.fmt("extended_float_{s}", .{case.suffix});
        try names.append(c.a, name);
        try w.print("define i128 @{s}(i128 %raw, i64 %live, i64 %e1, i64 %e2, i64 %e3, i64 %e4, ptr %out) {{\nentry:\n", .{name});
        if (std.mem.eql(u8, case.from, "half")) try w.writeAll(" %half_bits = trunc i128 %raw to i16\n %input = bitcast i16 %half_bits to half\n");
        if (std.mem.eql(u8, case.from, "fp128")) try w.writeAll(" %input = bitcast i128 %raw to fp128\n");
        const input = case.literal orelse if (std.mem.eql(u8, case.from, "i128")) "%raw" else "%input";
        if (std.mem.eql(u8, case.op, "call_quad")) {
            try w.writeAll(" %other_seed = zext i64 %e1 to i128\n %other = xor i128 %raw, %other_seed\n %number = call fp128 @extended_mixed_quad(i64 %live, i128 %raw, fp128 %input, i128 %other, i64 %e4)\n");
        } else if (std.mem.eql(u8, case.op, "call_integer")) {
            try w.writeAll(" %number = call i128 @extended_mixed_integer(fp128 %input, i64 %e2, i128 %raw)\n");
        } else try w.print(" %number = {s} {s} {s} to {s}\n", .{ case.op, case.from, input, case.to });
        if (std.mem.eql(u8, case.to, "fp128")) try w.writeAll(" %converted = bitcast fp128 %number to i128\n");
        if (std.mem.eql(u8, case.to, "half")) try w.writeAll(" %half_result = bitcast half %number to i16\n %converted = zext i16 %half_result to i128\n");
        const converted = if (std.mem.eql(u8, case.to, "i128")) "%number" else "%converted";
        try w.print(" store i128 {s}, ptr %out, align 1\n", .{converted});
        try w.writeAll(" %one = xor i64 %live, %e1\n %two = add i64 %one, %e2\n %three = xor i64 %two, %e3\n %four = add i64 %three, %e4\n %wide = zext i64 %four to i128\n");
        try w.print(" %with_raw = xor i128 {s}, %raw\n %answer = xor i128 %with_raw, %wide\n ret i128 %answer\n}}\n", .{converted});
        try d.print("extern u128 {s}(u128,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint8_t*);\n", .{name});
    }
    try d.writeAll("static const conversion_fn cases[]={\n");
    for (names.items) |name| try d.print(" {s},\n", .{name});
    try d.writeAll("};\n");
    try d.writeAll(@embedFile("templates/extended_float_conversion_driver.c"));
    try c.write(try c.join(&.{ output, "extended_float_conversion.ll" }), llvm.written());
    try c.write(try c.join(&.{ output, "extended_float_conversion_driver.c" }), driver.written());
    const population = try u.toValue(c.a, .{
        .population = "extended_float_conversion",
        .prefix = "extended-float-conversion",
        .fixture = "extended_float_conversion",
        .functions = names.items,
        .observations = 139264,
        .stdout = "extended-float-conversion observations=139264 rounding=classes=wide=abi=live=stores=guards=preserved\n",
    });
    try c.writeJson(try c.join(&.{ output, "population.json" }), population);
    if (args.get("registry-input")) |path| {
        const original = try c.read(try c.join(&.{path}));
        const registry = try c.load(try c.join(&.{path}));
        for (try u.json.array(try u.get(registry, "canaries"))) |entry| if (std.mem.eql(u8, try u.str(entry, "population"), "extended_float_conversion")) return error.PopulationAlreadyRegistered;
        const end = std.mem.lastIndexOf(u8, original, "\n  ]") orelse return error.UnexpectedRegistryLayout;
        const rendered = try std.json.Stringify.valueAlloc(c.a, population, .{ .whitespace = .indent_2 });
        const indented = try std.mem.replaceOwned(u8, c.a, rendered, "\n", "\n    ");
        try c.write(try c.join(&.{ output, "native_canaries.json" }), try c.fmt("{s},\n    {s}{s}", .{ original[0..end], indented, original[end..] }));
    }
}
