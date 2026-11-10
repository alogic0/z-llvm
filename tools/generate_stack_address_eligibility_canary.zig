//! Generate independent frame-address views beside an unrewritten dynamic copy.
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
    try w.writeAll("target triple = \"x86_64-unknown-linux-gnu\"\ndeclare void @llvm.memcpy.p0.p0.i64(ptr, ptr, i64, i1)\n");
    try driver.writer.writeAll("#include <stdint.h>\n#include <stdbool.h>\ntypedef uint64_t (*eligibility_fn)(unsigned char*,uint64_t,bool,uint64_t,uint64_t);\n");
    const Storage = struct { suffix: []const u8, ty: []const u8, bits: u16 };
    const storage = [_]Storage{
        .{ .suffix = "i8", .ty = "i8", .bits = 8 },
        .{ .suffix = "i16", .ty = "i16", .bits = 16 },
        .{ .suffix = "i32", .ty = "i32", .bits = 32 },
        .{ .suffix = "i64", .ty = "i64", .bits = 32 },
        .{ .suffix = "i128", .ty = "i128", .bits = 32 },
        .{ .suffix = "array16", .ty = "[16 x i32]", .bits = 32 },
    };
    var names: std.ArrayList([]const u8) = .empty;
    for (storage) |s| for ([_]bool{ false, true }) |local_on_true| {
        const name = try c.fmt("eligibility_{s}_{s}", .{ s.suffix, if (local_on_true) "true" else "false" });
        try names.append(c.a, name);
        try w.print(
            \\define i64 @{0s}(ptr %external, i64 %value, i1 %choose, i64 %length, i64 %seed) {{
            \\entry:
            \\ %slot = alloca {1s}, align 16
            \\ %other = alloca [3 x i32], align 4
            \\ %small = trunc i64 %value to i{2d}
            \\ store i{2d} %small, ptr %slot, align 1
            \\ %copy_value = xor i64 %value, 72623859790382856
            \\ %copy_low = trunc i64 %copy_value to i32
            \\ %high = lshr i64 %value, 32
            \\ %copy_high = trunc i64 %high to i32
            \\ %copy_last = xor i32 %copy_low, 1516880852
            \\ %other_high = getelementptr i8, ptr %other, i64 4
            \\ %other_last = getelementptr i8, ptr %other, i64 8
            \\ store i32 %copy_low, ptr %other, align 4
            \\ store i32 %copy_high, ptr %other_high, align 4
            \\ store i32 %copy_last, ptr %other_last, align 4
            \\ call void @llvm.memcpy.p0.p0.i64(ptr %external, ptr %other, i64 %length, i1 false)
            \\ %p = select i1 %choose, ptr {3s}, ptr {4s}
            \\ %selected = load i{2d}, ptr %p, align 1
            \\ %original = load i{2d}, ptr %slot, align 1
            \\ %selected_wide = zext i{2d} %selected to i64
            \\ %original_wide = zext i{2d} %original to i64
            \\ %shifted = shl i64 %original_wide, 17
            \\ %both = xor i64 %selected_wide, %shifted
            \\ %with_seed = xor i64 %both, %seed
            \\ %result = xor i64 %with_seed, %value
            \\ ret i64 %result
            \\}}
            \\
        , .{ name, s.ty, s.bits, if (local_on_true) "%slot" else "%external", if (local_on_true) "%external" else "%slot" });
        try driver.writer.print("extern uint64_t {s}(unsigned char*,uint64_t,bool,uint64_t,uint64_t);\n", .{name});
    };
    try driver.writer.writeAll("static const struct { eligibility_fn run; unsigned bytes; bool local_on_true; } cases[]={\n");
    for (storage) |s| for ([_]bool{ false, true }) |local_on_true| {
        try driver.writer.print(" {{eligibility_{s}_{s},{d},{s}}},\n", .{ s.suffix, if (local_on_true) "true" else "false", s.bits / 8, if (local_on_true) "true" else "false" });
    };
    try driver.writer.writeAll("};\n");
    try driver.writer.writeAll(@embedFile("templates/stack_address_eligibility_driver.c"));
    try c.write(try c.join(&.{ output, "stack_address_eligibility.ll" }), llvm.written());
    try c.write(try c.join(&.{ output, "stack_address_eligibility_driver.c" }), driver.written());
    const population = try u.toValue(c.a, .{
        .population = "stack_address_eligibility",
        .prefix = "stack-address-eligibility",
        .fixture = "stack_address_eligibility",
        .functions = names.items,
        .observations = 3780,
        .stdout = "stack-address-eligibility observations=3780 choices=copies=live=guards=preserved\n",
    });
    try c.writeJson(try c.join(&.{ output, "population.json" }), population);
    if (args.get("registry-input")) |path| {
        const original = try c.read(try c.join(&.{path}));
        const registry = try c.load(try c.join(&.{path}));
        for (try u.json.array(try u.get(registry, "canaries"))) |entry| if (std.mem.eql(u8, try u.str(entry, "population"), "stack_address_eligibility")) return error.PopulationAlreadyRegistered;
        const end = std.mem.lastIndexOf(u8, original, "\n  ]") orelse return error.UnexpectedRegistryLayout;
        const rendered = try std.json.Stringify.valueAlloc(c.a, population, .{ .whitespace = .indent_2 });
        const indented = try std.mem.replaceOwned(u8, c.a, rendered, "\n", "\n    ");
        try c.write(try c.join(&.{ output, "native_canaries.json" }), try c.fmt("{s},\n    {s}{s}", .{ original[0..end], indented, original[end..] }));
    }
}
