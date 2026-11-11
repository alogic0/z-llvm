//! Full IEEE predicate truth tables, half inputs and extended80 representations.
const std = @import("std");
const u = @import("validation/common.zig");
const predicates = [_][]const u8{ "false", "oeq", "ogt", "oge", "olt", "ole", "one", "ord", "ueq", "ugt", "uge", "ult", "ule", "une", "uno", "true" };

pub fn main(init: std.process.Init) !void {
    var c = try u.Context.init(init);
    const argv = try init.minimal.args.toSlice(c.a);
    const args = try u.Args.parse(c.a, argv[1..], &.{ "output-root", "registry-input" }, &.{});
    const output = try c.newOutput(try args.require("output-root"));
    var llvm: std.Io.Writer.Allocating = .init(c.a);
    var driver: std.Io.Writer.Allocating = .init(c.a);
    const w = &llvm.writer;
    const d = &driver.writer;
    try w.writeAll("target triple = \"x86_64-unknown-linux-gnu\"\ntarget datalayout = \"e-i128:128-f80:128\"\ndeclare i64 @floating_predicate_clobber(i64)\n");
    try d.writeAll("#define _GNU_SOURCE\n#include <stdint.h>\ntypedef unsigned __int128 u128;\ntypedef uint64_t (*predicate_fn)(const uint8_t*,const uint8_t*,uint8_t*,uint64_t);\nstruct predicate_case {predicate_fn function;unsigned format,predicate,rows;};\n");
    var names: std.ArrayList([]const u8) = .empty;
    for (0..2) |format| for (0..17) |which| {
        const name = try c.fmt("floating_predicate_{s}_{s}", .{ if (format == 0) "half" else "extended", if (which == 16) "mask" else predicates[which] });
        try names.append(c.a, name);
        const ty = if (format == 0) "half" else "x86_fp80";
        try w.print("define i64 @{s}(ptr %left,ptr %right,ptr %output,i64 %live) {{\nentry:\n %x = load {s},ptr %left,align 1\n %y = load {s},ptr %right,align 1\n", .{ name, ty, ty });
        const first = if (which == 16) @as(usize, 0) else which;
        const end = if (which == 16) @as(usize, 16) else which + 1;
        for (first..end) |index| {
            try w.print(" %c{d} = fcmp {s} {s} %x,%y\n %w{d} = zext i1 %c{d} to i64\n", .{ index, predicates[index], ty, index, index });
            if (which == 16) {
                try w.print(" %s{d} = shl i64 %w{d},{d}\n %m{d} = or i64 {s},%s{d}\n", .{ index, index, index, index, if (index == 0) "0" else try c.fmt("%m{d}", .{index - 1}), index });
            }
        }
        const result = if (which == 16) "%m15" else try c.fmt("%w{d}", .{which});
        try w.print(" %probe = call i64 @floating_predicate_clobber(i64 %live)\n store i64 {s},ptr %output,align 1\n %answer = xor i64 {s},%probe\n ret i64 %answer\n}}\n", .{ result, result });
        try d.print("extern uint64_t {s}(const uint8_t*,const uint8_t*,uint8_t*,uint64_t);\n", .{name});
    };
    try d.writeAll("static const struct predicate_case cases[]={\n");
    for (0..2) |format| for (0..17) |which| try d.print("{{floating_predicate_{s}_{s},{d},{d},{d}}},\n", .{ if (format == 0) "half" else "extended", if (which == 16) "mask" else predicates[which], format, which, if (format == 0) @as(usize, 65792) else 8192 });
    try d.writeAll("};\n");
    try d.writeAll(@embedFile("templates/floating_predicate_driver.c"));
    try c.write(try c.join(&.{ output, "floating_predicates.ll" }), llvm.written());
    try c.write(try c.join(&.{ output, "floating_predicates_driver.c" }), driver.written());
    const population = try u.toValue(c.a, .{
        .population = "floating_predicates",
        .prefix = "floating-predicates",
        .fixture = "floating_predicates",
        .functions = names.items,
        .observations = 1257728,
        .stdout = "floating-predicates observations=1257728 ordered=unordered=half=extended=live=guards=preserved\n",
    });
    try c.writeJson(try c.join(&.{ output, "population.json" }), population);
    if (args.get("registry-input")) |path| {
        const original = try c.read(try c.join(&.{path}));
        const registry = try c.load(try c.join(&.{path}));
        for (try u.json.array(try u.get(registry, "canaries"))) |entry| if (std.mem.eql(u8, try u.str(entry, "population"), "floating_predicates")) return error.PopulationAlreadyRegistered;
        const end = std.mem.lastIndexOf(u8, original, "\n  ]") orelse return error.UnexpectedRegistryLayout;
        const rendered = try std.json.Stringify.valueAlloc(c.a, population, .{ .whitespace = .indent_2 });
        const indented = try std.mem.replaceOwned(u8, c.a, rendered, "\n", "\n    ");
        try c.write(try c.join(&.{ output, "native_canaries.json" }), try c.fmt("{s},\n    {s}{s}", .{ original[0..end], indented, original[end..] }));
    }
}
