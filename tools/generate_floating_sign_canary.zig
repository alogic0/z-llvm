//! Exact extended floating sign bits across raw representations and calls.
const std = @import("std");
const u = @import("validation/common.zig");
const operations = [_][]const u8{ "neg", "abs", "copy" };

pub fn main(init: std.process.Init) !void {
    var c = try u.Context.init(init);
    const argv = try init.minimal.args.toSlice(c.a);
    const args = try u.Args.parse(c.a, argv[1..], &.{ "output-root", "registry-input" }, &.{});
    const output = try c.newOutput(try args.require("output-root"));
    var llvm: std.Io.Writer.Allocating = .init(c.a);
    var driver: std.Io.Writer.Allocating = .init(c.a);
    const w = &llvm.writer;
    const d = &driver.writer;
    try w.writeAll("target triple = \"x86_64-unknown-linux-gnu\"\ntarget datalayout = \"e-i128:128-f80:128\"\ndeclare i64 @floating_sign_clobber(i64)\n");
    try d.writeAll("#define _GNU_SOURCE\n#include <stdint.h>\ntypedef unsigned __int128 u128;\ntypedef uint64_t (*sign_fn)(const uint8_t*,const uint8_t*,uint8_t*,uint64_t);\nstruct sign_case {sign_fn function;unsigned width,operation;};\n");
    var names: std.ArrayList([]const u8) = .empty;
    for ([_]usize{ 80, 128 }) |width| {
        const ty = if (width == 80) "x86_fp80" else "fp128";
        try w.print("declare {s} @llvm.fabs.f{d}({s})\ndeclare {s} @llvm.copysign.f{d}({s},{s})\n", .{ ty, width, ty, ty, width, ty, ty });
        for (operations, 0..) |operation, which| {
            const name = try c.fmt("floating_sign_{d}_{s}", .{ width, operation });
            try names.append(c.a, name);
            try w.print("define i64 @{s}(ptr %left,ptr %right,ptr %output,i64 %live) {{\nentry:\n %x = load {s},ptr %left,align 1\n %y = load {s},ptr %right,align 1\n", .{ name, ty, ty });
            switch (which) {
                0 => try w.print(" %z = fneg {s} %x\n", .{ty}),
                1 => try w.print(" %z = call {s} @llvm.fabs.f{d}({s} %x)\n", .{ ty, width, ty }),
                2 => try w.print(" %z = call {s} @llvm.copysign.f{d}({s} %x,{s} %y)\n", .{ ty, width, ty, ty }),
                else => unreachable,
            }
            try w.print(" %bits = bitcast {s} %z to i{d}\n %low = trunc i{d} %bits to i64\n %probe = call i64 @floating_sign_clobber(i64 %live)\n store {s} %z,ptr %output,align 1\n %answer = xor i64 %low,%probe\n ret i64 %answer\n}}\n", .{ ty, width, width, ty });
            try d.print("extern uint64_t {s}(const uint8_t*,const uint8_t*,uint8_t*,uint64_t);\n", .{name});
        }
    }
    try d.writeAll("static const struct sign_case cases[]={\n");
    for ([_]usize{ 80, 128 }) |width| for (operations, 0..) |operation, which| try d.print("{{floating_sign_{d}_{s},{d},{d}}},\n", .{ width, operation, width, which });
    try d.writeAll("};\n");
    try d.writeAll(@embedFile("templates/floating_sign_driver.c"));
    try c.write(try c.join(&.{ output, "floating_signs.ll" }), llvm.written());
    try c.write(try c.join(&.{ output, "floating_signs_driver.c" }), driver.written());
    const population = try u.toValue(c.a, .{
        .population = "floating_signs",
        .prefix = "floating-signs",
        .fixture = "floating_signs",
        .functions = names.items,
        .observations = 49152,
        .stdout = "floating-signs observations=49152 neg=abs=copysign=payloads=live=guards=preserved\n",
    });
    try c.writeJson(try c.join(&.{ output, "population.json" }), population);
    if (args.get("registry-input")) |path| {
        const original = try c.read(try c.join(&.{path}));
        const registry = try c.load(try c.join(&.{path}));
        for (try u.json.array(try u.get(registry, "canaries"))) |entry| if (std.mem.eql(u8, try u.str(entry, "population"), "floating_signs")) return error.PopulationAlreadyRegistered;
        const end = std.mem.lastIndexOf(u8, original, "\n  ]") orelse return error.UnexpectedRegistryLayout;
        const rendered = try std.json.Stringify.valueAlloc(c.a, population, .{ .whitespace = .indent_2 });
        const indented = try std.mem.replaceOwned(u8, c.a, rendered, "\n", "\n    ");
        try c.write(try c.join(&.{ output, "native_canaries.json" }), try c.fmt("{s},\n    {s}{s}", .{ original[0..end], indented, original[end..] }));
    }
}
