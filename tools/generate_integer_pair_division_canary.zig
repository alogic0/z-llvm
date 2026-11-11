//! Independent full-width quotient/remainder and physical pair-call coverage.
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
    try w.writeAll("target triple = \"x86_64-unknown-linux-gnu\"\n" ++
        "declare i128 @__udivti3(i128, i128)\ndeclare i128 @__umodti3(i128, i128)\n" ++
        "declare i128 @__divti3(i128, i128)\ndeclare i128 @__modti3(i128, i128)\n");
    try d.writeAll("#include <stdint.h>\ntypedef __uint128_t wide;\ntypedef wide (*division_fn)(wide,wide,uint64_t,uint64_t,uint64_t,uint64_t);\n");
    var names: std.ArrayList([]const u8) = .empty;
    var cases: std.Io.Writer.Allocating = .init(c.a);
    for ([_][]const u8{ "udiv", "urem", "sdiv", "srem" }, 0..) |op, operation| for ([_]bool{ false, true }) |constant| {
        const name = try c.fmt("pair_division_{s}_{s}", .{ op, if (constant) "constant" else "named" });
        try names.append(c.a, name);
        const divisor = if (constant) (if (operation < 2) "79228162514264337593543950339" else "-79228162514264337593543950339") else "%b";
        try w.print(
            \\define i128 @{s}(i128 %a, i128 %b, i64 %seed, i64 %live1, i64 %live2, i64 %live3) {{
            \\entry:
            \\ %raw = {s} i128 %a, {s}
            \\ %with_a = xor i128 %raw, %a
            \\ %with_b = xor i128 %with_a, %b
            \\ %one = xor i64 %seed, %live1
            \\ %two = add i64 %one, %live2
            \\ %three = xor i64 %two, %live3
            \\ %wide = zext i64 %three to i128
            \\ %result = xor i128 %with_b, %wide
            \\ ret i128 %result
            \\}}
            \\
        , .{ name, op, divisor });
        try d.print("extern wide {s}(wide,wide,uint64_t,uint64_t,uint64_t,uint64_t);\n", .{name});
        try cases.writer.print(" {{{s},{d},{d}}},\n", .{ name, operation, @intFromBool(constant) });
    };
    try d.writeAll("static const struct { division_fn run; unsigned op,constant; } cases[]={\n");
    try d.writeAll(cases.written());
    try d.writeAll("};\n");
    try d.writeAll(@embedFile("templates/integer_pair_division_driver.c"));
    try c.write(try c.join(&.{ output, "integer_pair_division.ll" }), llvm.written());
    try c.write(try c.join(&.{ output, "integer_pair_division_driver.c" }), driver.written());
    const population = try u.toValue(c.a, .{
        .population = "integer_pair_division",
        .prefix = "integer-pair-division",
        .fixture = "integer_pair_division",
        .functions = names.items,
        .observations = 7928,
        .stdout = "integer-pair-division observations=7928 quotient=remainder=signed=live=abi=preserved\n",
    });
    try c.writeJson(try c.join(&.{ output, "population.json" }), population);
    if (args.get("registry-input")) |path| {
        const original = try c.read(try c.join(&.{path}));
        const registry = try c.load(try c.join(&.{path}));
        for (try u.json.array(try u.get(registry, "canaries"))) |entry| if (std.mem.eql(u8, try u.str(entry, "population"), "integer_pair_division")) return error.PopulationAlreadyRegistered;
        const end = std.mem.lastIndexOf(u8, original, "\n  ]") orelse return error.UnexpectedRegistryLayout;
        const rendered = try std.json.Stringify.valueAlloc(c.a, population, .{ .whitespace = .indent_2 });
        const indented = try std.mem.replaceOwned(u8, c.a, rendered, "\n", "\n    ");
        try c.write(try c.join(&.{ output, "native_canaries.json" }), try c.fmt("{s},\n    {s}{s}", .{ original[0..end], indented, original[end..] }));
    }
}
