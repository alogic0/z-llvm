//! Native word literals, pair projections and a captured digest-shaped graph.
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
    try w.writeAll("target triple = \"x86_64-unknown-linux-gnu\"\ndeclare i64 @shift_operand_clobber(i64)\n" ++
        "declare void @llvm.lifetime.start.p0(ptr)\ndeclare void @llvm.lifetime.end.p0(ptr)\n" ++
        "declare void @llvm.assume(i1)\ndeclare void @llvm.memcpy.p0.p0.i64(ptr, ptr, i64, i1)\n" ++
        "declare i64 @llvm.fshl.i64(i64, i64, i64)\n\n");
    try d.writeAll("#include <stdint.h>\n#include <stdbool.h>\ntypedef uint64_t (*word_fn)(uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t);\n" ++
        "typedef uint64_t (*pair_fn)(unsigned char*,uint64_t,uint64_t,uint64_t,uint64_t);\n");
    var names: std.ArrayList([]const u8) = .empty;
    var word_cases: std.Io.Writer.Allocating = .init(c.a);
    for ([_]u16{ 32, 64 }) |bits| for ([_][]const u8{ "shl", "lshr", "ashr" }, 0..) |op, operation| for (0..4) |variant| {
        const top = @as(u64, 1) << @as(u6, @intCast(bits - 1));
        const mask: u64 = if (bits == 64) std.math.maxInt(u64) else std.math.maxInt(u32);
        const payload = ([_]u64{ top, top, mask, 0xfedcba9876543210 & mask })[variant];
        const literal: i128 = if (variant == 0) -@as(i128, top) else payload;
        const name = try c.fmt("shift_word_{s}{d}_{d}", .{ op, bits, variant });
        try names.append(c.a, name);
        try d.print("extern uint64_t {s}(uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t);\n", .{name});
        try word_cases.writer.print(" {{{s},{d},{d},UINT64_C({d})}},\n", .{ name, bits, operation, payload });
        const spill = variant % 2 != 0;
        try w.print(
            \\define i64 @{s}(i64 %count, i64 %a, i64 %b, i64 %c, i64 %d, i64 %e, i64 %f, i64 %g) {{
            \\entry:
            \\ %masked = and i64 %count, {d}
            \\ {s}
            \\ {s}
            \\ %shifted = {s} {s}i{d} {d}, {s}
            \\ {s}
            \\ {s}
            \\ %one = xor i64 %wide, %marker
            \\ %two = add i64 %one, %c
            \\ %three = xor i64 %two, %d
            \\ %four = sub i64 %three, %e
            \\ %five = xor i64 %four, %f
            \\ %result = add i64 %five, %g
            \\ ret i64 %result
            \\}}
            \\
        , .{ name, bits - 1, if (bits == 32) "%narrow_count = trunc i64 %masked to i32" else "", if (spill) "%marker = xor i64 %a, %b" else "", op, if (operation != 0 and variant < 2) "exact " else "", bits, literal, if (bits == 32) "%narrow_count" else "%masked", if (bits == 32) "%wide = zext i32 %shifted to i64" else "%wide = xor i64 %shifted, 0", if (spill) "" else "%marker = xor i64 %a, %b" });
    };
    try d.writeAll("static const struct { word_fn run; unsigned bits,op; uint64_t literal; } word_cases[]={\n");
    try d.writeAll(word_cases.written());
    try d.writeAll("};\n");
    var pair_cases: std.Io.Writer.Allocating = .init(c.a);
    for ([_]?u8{ 0, 1, 7, 31, 32, 40, 63, 64, 65, 127, null }) |amount| {
        const suffix = if (amount) |n| try c.fmt("{d}", .{n}) else "named";
        const name = try c.fmt("shift_pair_{s}", .{suffix});
        try names.append(c.a, name);
        try d.print("extern uint64_t {s}(unsigned char*,uint64_t,uint64_t,uint64_t,uint64_t);\n", .{name});
        try pair_cases.writer.print(" {{{s},{d}}},\n", .{ name, if (amount) |n| @as(i16, n) else -1 });
        try w.print(
            \\define i64 @{s}(ptr %output, i64 %lo, i64 %hi, i64 %count, i64 %seed) {{
            \\entry:
            \\ %low_pair = zext i64 %lo to i128
            \\ %high_pair = zext i64 %hi to i128
            \\ %upper = shl i128 %high_pair, 64
            \\ %pair = or i128 %low_pair, %upper
            \\ %masked = and i64 %count, 127
            \\ %wide_count = zext i64 %masked to i128
            \\ %shifted = lshr i128 %pair, {s}
            \\ %clobbered = call i64 @shift_operand_clobber(i64 %seed)
            \\ %low = trunc i128 %shifted to i64
            \\ %projection = lshr i128 %shifted, 64
            \\ %high = trunc i128 %projection to i64
            \\ store i64 %low, ptr %output, align 1
            \\ %p1 = getelementptr i8, ptr %output, i64 8
            \\ store i64 %high, ptr %p1, align 1
            \\ %both = xor i64 %lo, %hi
            \\ %with_seed = add i64 %both, %seed
            \\ %result = xor i64 %with_seed, %clobbered
            \\ ret i64 %result
            \\}}
            \\
        , .{ name, if (amount) |n| try c.fmt("{d}", .{n}) else "%wide_count" });
    }
    try d.writeAll("static const struct { pair_fn run; int count; } pair_cases[]={\n");
    try d.writeAll(pair_cases.written());
    try d.writeAll("};\nextern void integer_shift_digest(void*,unsigned char*);\n");
    try w.writeAll(@embedFile("templates/integer_shift_digest.ll"));
    try names.append(c.a, "integer_shift_digest");
    try d.writeAll(@embedFile("templates/integer_shift_operands_driver.c"));
    try c.write(try c.join(&.{ output, "integer_shift_operands.ll" }), llvm.written());
    try c.write(try c.join(&.{ output, "integer_shift_operands_driver.c" }), driver.written());
    const population = try u.toValue(c.a, .{
        .population = "integer_shift_operands",
        .prefix = "integer-shift-operands",
        .fixture = "integer_shift_operands",
        .functions = names.items,
        .observations = 22536,
        .stdout = "integer-shift-operands observations=22536 literals=pairs=digest=abi=guards=preserved\n",
    });
    try c.writeJson(try c.join(&.{ output, "population.json" }), population);
    if (args.get("registry-input")) |path| {
        const original = try c.read(try c.join(&.{path}));
        const registry = try c.load(try c.join(&.{path}));
        for (try u.json.array(try u.get(registry, "canaries"))) |entry| if (std.mem.eql(u8, try u.str(entry, "population"), "integer_shift_operands")) return error.PopulationAlreadyRegistered;
        const end = std.mem.lastIndexOf(u8, original, "\n  ]") orelse return error.UnexpectedRegistryLayout;
        const rendered = try std.json.Stringify.valueAlloc(c.a, population, .{ .whitespace = .indent_2 });
        const indented = try std.mem.replaceOwned(u8, c.a, rendered, "\n", "\n    ");
        try c.write(try c.join(&.{ output, "native_canaries.json" }), try c.fmt("{s},\n    {s}{s}", .{ original[0..end], indented, original[end..] }));
    }
}
