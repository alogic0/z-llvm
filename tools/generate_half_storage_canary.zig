//! Store-only half views inside larger owned objects, with live captures.
const std = @import("std");
const u = @import("validation/common.zig");
const variants = [_][]const u8{ "argument", "input", "signaling_nan", "negative_zero" };
pub fn main(init: std.process.Init) !void {
    var c = try u.Context.init(init);
    const argv = try init.minimal.args.toSlice(c.a);
    const args = try u.Args.parse(c.a, argv[1..], &.{ "output-root", "registry-input" }, &.{});
    const output = try c.newOutput(try args.require("output-root"));
    var llvm: std.Io.Writer.Allocating = .init(c.a);
    var driver: std.Io.Writer.Allocating = .init(c.a);
    const w = &llvm.writer;
    const d = &driver.writer;
    try w.writeAll("target triple = \"x86_64-unknown-linux-gnu\"\ndeclare i64 @half_storage_clobber(i64)\ndeclare void @llvm.memset.p0.i64(ptr,i8,i64,i1)\ndeclare void @llvm.memcpy.p0.p0.i64(ptr,ptr,i64,i1)\n");
    try d.writeAll("#define _GNU_SOURCE\n#include <stdint.h>\ntypedef uint64_t (*storage_fn)(uint16_t,const uint8_t*,uint8_t*,uint64_t);\nstruct storage_case {storage_fn function;unsigned kind;};\n");
    var names: std.ArrayList([]const u8) = .empty;
    for (variants, 0..) |variant, index| {
        const name = try c.fmt("half_storage_{s}", .{variant});
        try names.append(c.a, name);
        try w.print("define i64 @{s}(i16 %raw,ptr %input,ptr %output,i64 %live) {{\nentry:\n %slab = alloca [16 x i8],align 16\n call void @llvm.memset.p0.i64(ptr %slab,i8 -89,i64 16,i1 false)\n", .{name});
        if (index == 1) try w.writeAll(" %source = load i16,ptr %input,align 1\n %value = bitcast i16 %source to half\n") else if (index == 0) try w.writeAll(" %value = bitcast i16 %raw to half\n");
        try w.writeAll(" %choose = trunc i64 %live to i1\n br i1 %choose,label %left,label %right\nleft:\n %a = getelementptr i8,ptr %slab,i64 3\n br label %merge\nright:\n %b = getelementptr i8,ptr %slab,i64 14\n br label %merge\nmerge:\n %at = phi ptr [%a,%left],[%b,%right]\n");
        const value = if (index < 2) "%value" else if (index == 2) "0xH7D01" else "0xH8000";
        try w.print(" store half {s},ptr %at,align 1\n %captured = load i16,ptr %at,align 1\n %probe = call i64 @half_storage_clobber(i64 %live)\n store half 0xH3C01,ptr %at,align 1\n call void @llvm.memcpy.p0.p0.i64(ptr %output,ptr %slab,i64 16,i1 false)\n %before = zext i16 %captured to i64\n %answer = xor i64 %before,%probe\n ret i64 %answer\n}}\n", .{value});
        try d.print("extern uint64_t {s}(uint16_t,const uint8_t*,uint8_t*,uint64_t);\n", .{name});
    }
    try d.writeAll("static const struct storage_case cases[]={\n");
    for (variants, 0..) |variant, index| try d.print("{{half_storage_{s},{d}}},\n", .{ variant, index });
    try d.writeAll("};\n");
    try d.writeAll(@embedFile("templates/half_storage_driver.c"));
    try c.write(try c.join(&.{ output, "half_storage.ll" }), llvm.written());
    try c.write(try c.join(&.{ output, "half_storage_driver.c" }), driver.written());
    const population = try u.toValue(c.a, .{
        .population = "half_storage",
        .prefix = "half-storage",
        .fixture = "half_storage",
        .functions = names.items,
        .observations = 262144,
        .stdout = "half-storage observations=262144 store-only=phi=capture=payloads=live=guards=preserved\n",
    });
    try c.writeJson(try c.join(&.{ output, "population.json" }), population);
    if (args.get("registry-input")) |path| {
        const original = try c.read(try c.join(&.{path}));
        const registry = try c.load(try c.join(&.{path}));
        for (try u.json.array(try u.get(registry, "canaries"))) |entry| if (std.mem.eql(u8, try u.str(entry, "population"), "half_storage")) return error.PopulationAlreadyRegistered;
        const end = std.mem.lastIndexOf(u8, original, "\n  ]") orelse return error.UnexpectedRegistryLayout;
        const rendered = try std.json.Stringify.valueAlloc(c.a, population, .{ .whitespace = .indent_2 });
        const indented = try std.mem.replaceOwned(u8, c.a, rendered, "\n", "\n    ");
        try c.write(try c.join(&.{ output, "native_canaries.json" }), try c.fmt("{s},\n    {s}{s}", .{ original[0..end], indented, original[end..] }));
    }
}
