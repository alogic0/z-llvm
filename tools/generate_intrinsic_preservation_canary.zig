//! Native oracles for destructive scalar intrinsics with live input identities.
const std = @import("std");
const u = @import("validation/common.zig");
const Operation = struct { name: []const u8, intrinsic: []const u8, bits: u16 };
const operations = [_]Operation{
    .{ .name = "count64", .intrinsic = "ctpop", .bits = 64 },
    .{ .name = "leading16", .intrinsic = "ctlz", .bits = 16 },
    .{ .name = "swap16", .intrinsic = "bswap", .bits = 16 },
    .{ .name = "swap32", .intrinsic = "bswap", .bits = 32 },
    .{ .name = "swap64", .intrinsic = "bswap", .bits = 64 },
    .{ .name = "reverse32", .intrinsic = "bitreverse", .bits = 32 },
    .{ .name = "reverse64", .intrinsic = "bitreverse", .bits = 64 },
    .{ .name = "funnel32", .intrinsic = "fshl", .bits = 32 },
};
pub fn main(init: std.process.Init) !void {
    var c = try u.Context.init(init);
    const argv = try init.minimal.args.toSlice(c.a);
    const args = try u.Args.parse(c.a, argv[1..], &.{ "output-root", "registry-input" }, &.{});
    const out = try c.newOutput(try args.require("output-root"));
    var llvm: std.Io.Writer.Allocating = .init(c.a);
    const w = &llvm.writer;
    var driver: std.Io.Writer.Allocating = .init(c.a);
    const d = &driver.writer;
    var names = std.array_list.Managed([]const u8).init(c.a);
    try w.writeAll("target triple = \"x86_64-unknown-linux-gnu\"\n");
    try d.writeAll("#include <stdint.h>\n#include <stdio.h>\n#include <stdlib.h>\n#include <string.h>\ntypedef uint64_t (*oracle_fn)(uint64_t,const void *,void *,uint64_t);\nstruct oracle_case { oracle_fn run; unsigned operation,bits,shape; };\n");
    for (operations) |op| {
        try w.print("declare i{d} @llvm.{s}.i{d}(i{d}", .{ op.bits, op.intrinsic, op.bits, op.bits });
        if (std.mem.eql(u8, op.intrinsic, "ctlz")) try w.writeAll(",i1");
        if (std.mem.eql(u8, op.intrinsic, "fshl")) try w.writeAll(",i32,i32");
        try w.writeAll(")\n");
    }
    for (operations) |op| for ([_][]const u8{ "register", "computed", "load" }, 0..) |shape, shape_index| {
        const name = try c.fmt("intrinsic_preservation_{s}_{s}", .{ op.name, shape });
        try names.append(name);
        try d.print("extern uint64_t {s}(uint64_t,const void *,void *,uint64_t);\n", .{name});
        try w.print("define i64 @{s}(i64 %raw,ptr %source,ptr %out,i64 %salt) {{\nentry:\n", .{name});
        if (shape_index == 2) {
            try w.print(" %value = load i{d},ptr %source,align 1\n", .{op.bits});
        } else {
            if (op.bits == 64) try w.writeAll(" %narrow = add i64 %raw,0\n") else try w.print(" %narrow = trunc i64 %raw to i{d}\n", .{op.bits});
            try w.print(" %value = {s} i{d} %narrow,{d}\n", .{ if (shape_index == 1) "xor" else "add", op.bits, if (shape_index == 1) @as(u64, 0x5aa5) else 0 });
        }
        try w.print(" %alias = add i{d} %value,0\n %result = call i{d} @llvm.{s}.i{d}(i{d} %value", .{ op.bits, op.bits, op.intrinsic, op.bits, op.bits });
        if (std.mem.eql(u8, op.intrinsic, "ctlz")) try w.writeAll(",i1 false");
        if (std.mem.eql(u8, op.intrinsic, "fshl")) try w.writeAll(",i32 %value,i32 7");
        try w.print(")\n store i{d} %value,ptr %out,align 1\n %next = getelementptr i8,ptr %out,i64 8\n store i{d} %alias,ptr %next,align 1\n", .{ op.bits, op.bits });
        if (op.bits == 64) try w.writeAll(" %wide = add i64 %result,0\n %original = add i64 %value,0\n") else try w.print(" %wide = zext i{d} %result to i64\n %original = zext i{d} %value to i64\n", .{ op.bits, op.bits });
        try w.writeAll(" %mixed = xor i64 %wide,%original\n %answer = xor i64 %mixed,%salt\n ret i64 %answer\n}\n");
    };
    try names.append("intrinsic_preservation_roundup");
    try d.writeAll("extern uint64_t intrinsic_preservation_roundup(uint16_t);\nstatic const struct oracle_case cases[]={\n");
    for (operations, 0..) |op, index| for ([_][]const u8{ "register", "computed", "load" }, 0..) |shape, shape_index| {
        try d.print(" {{intrinsic_preservation_{s}_{s},{d},{d},{d}}},\n", .{ op.name, shape, index, op.bits, shape_index });
    };
    try d.writeAll("};\n");
    try d.writeAll(@embedFile("templates/intrinsic_preservation_driver.c"));
    try w.writeAll("define i64 @intrinsic_preservation_roundup(i16 %raw) {\nentry:\n %value = zext i16 %raw to i64\n %count = call i64 @llvm.ctpop.i64(i64 %value)\n %sum = add i64 %value,9\n %negative = sub i64 0,%value\n %aligned = and i64 %sum,%negative\n %answer = add i64 %aligned,%count\n ret i64 %answer\n}\n");
    try c.write(try c.join(&.{ out, "intrinsic_preservation.ll" }), llvm.written());
    try c.write(try c.join(&.{ out, "intrinsic_preservation_driver.c" }), driver.written());
    const population = try u.toValue(c.a, .{ .population = "intrinsic_preservation", .prefix = "intrinsic-preservation", .fixture = "intrinsic_preservation", .functions = names.items, .codegen_args = &.{"--codegen-reachable"}, .observations = 1168, .stdout = "intrinsic-preservation observations=1168 live=aliases=memory=preserved\n" });
    try c.writeJson(try c.join(&.{ out, "population.json" }), population);
    if (args.get("registry-input")) |path| {
        const original = try c.read(try c.join(&.{path}));
        const registry = try c.load(try c.join(&.{path}));
        for (try u.json.array(try u.get(registry, "canaries"))) |entry| if (std.mem.eql(u8, try u.str(entry, "population"), "intrinsic_preservation")) return error.PopulationAlreadyRegistered;
        const end = std.mem.lastIndexOf(u8, original, "\n  ]") orelse return error.UnexpectedRegistryLayout;
        const rendered = try std.json.Stringify.valueAlloc(c.a, population, .{ .whitespace = .indent_2 });
        const indented = try std.mem.replaceOwned(u8, c.a, rendered, "\n", "\n    ");
        try c.write(try c.join(&.{ out, "native_canaries.json" }), try c.fmt("{s},\n    {s}{s}", .{ original[0..end], indented, original[end..] }));
    }
}
