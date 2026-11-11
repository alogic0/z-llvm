//! Unsigned pair overflow, range-attributed memory and target-method call ABI.
const std = @import("std");
const u = @import("validation/common.zig");
const names = [_][]const u8{ "integer_boundaries_umul", "integer_boundaries_smul", "integer_boundaries_target", "integer_boundaries_memset", "integer_boundaries_memset_constant" };
pub fn main(init: std.process.Init) !void {
    var c = try u.Context.init(init);
    const argv = try init.minimal.args.toSlice(c.a);
    const args = try u.Args.parse(c.a, argv[1..], &.{ "output-root", "registry-input" }, &.{});
    const out = try c.newOutput(try args.require("output-root"));
    var llvm: std.Io.Writer.Allocating = .init(c.a);
    const w = &llvm.writer;
    try w.writeAll("target triple = \"x86_64-unknown-linux-gnu\"\ndeclare i64 @integer_boundaries_clobber(i64)\ndeclare fastcc i16 @zig.target.intByteSize(ptr,i16)\ndeclare void @llvm.memset.p0.i64(ptr,i8,i64,i1)\n");
    for ([_]bool{ false, true }) |signed| {
        const op = if (signed) "smul" else "umul";
        try w.print("declare {{ i128, i1 }} @llvm.{s}.with.overflow.i128(i128,i128)\ndefine i128 @integer_boundaries_{s}(i128 %a,i128 %b,ptr %out,i64 %live) {{\nentry:\n %pair = call {{ i128, i1 }} @llvm.{s}.with.overflow.i128(i128 %a,i128 %b)\n %value = extractvalue {{ i128, i1 }} %pair,0\n %overflow = extractvalue {{ i128, i1 }} %pair,1\n %byte = zext i1 %overflow to i8\n %flag = getelementptr i8,ptr %out,i64 16\n %probe = call i64 @integer_boundaries_clobber(i64 %live)\n store i128 %value,ptr %out,align 1\n store i8 %byte,ptr %flag,align 1\n %wide = zext i64 %probe to i128\n %answer = xor i128 %value,%wide\n ret i128 %answer\n}}\n", .{ op, op, op });
    }
    try w.writeAll("define i64 @integer_boundaries_target(ptr %context,i64 %raw,ptr %out,i64 %live) {\nentry:\n %bits = trunc i64 %raw to i16\n %small = tail call fastcc i16 @zig.target.intByteSize(ptr nonnull readonly align 1 %context,i16 %bits)\n %value = zext i16 %small to i64\n %probe = call i64 @integer_boundaries_clobber(i64 %live)\n store i16 %small,ptr %out,align 1\n %answer = xor i64 %value,%probe\n ret i64 %answer\n}\n");
    for ([_]bool{ false, true }) |constant| {
        try w.print("define i64 @integer_boundaries_memset{s}(ptr %out,i64 %rawfill,i64 %rawlen,i64 %live) {{\nentry:\n %fill = trunc i64 %rawfill to i8\n %len = and i64 %rawlen,31\n call void @llvm.memset.p0.i64(ptr align 1 %out,i8 noundef %fill,i64 range(i64 0, 33) {s},i1 false)\n %probe = call i64 @integer_boundaries_clobber(i64 %live)\n ret i64 %probe\n}}\n", .{ if (constant) "_constant" else "", if (constant) "32" else "%len" });
    }
    try c.write(try c.join(&.{ out, "integer_boundaries.ll" }), llvm.written());
    try c.write(try c.join(&.{ out, "integer_boundaries_driver.c" }), @embedFile("templates/integer_boundaries_driver.c"));
    const pop = try u.toValue(c.a, .{ .population = "integer_boundaries", .prefix = "integer-boundaries", .fixture = "integer_boundaries", .functions = names, .observations = 40960, .stdout = "integer-boundaries observations=40960 product=overflow=target=range=live=guards=preserved\n" });
    try c.writeJson(try c.join(&.{ out, "population.json" }), pop);
    if (args.get("registry-input")) |path| {
        const original = try c.read(try c.join(&.{path}));
        const registry = try c.load(try c.join(&.{path}));
        for (try u.json.array(try u.get(registry, "canaries"))) |entry| if (std.mem.eql(u8, try u.str(entry, "population"), "integer_boundaries")) return error.PopulationAlreadyRegistered;
        const end = std.mem.lastIndexOf(u8, original, "\n  ]") orelse return error.UnexpectedRegistryLayout;
        const rendered = try std.json.Stringify.valueAlloc(c.a, pop, .{ .whitespace = .indent_2 });
        const indented = try std.mem.replaceOwned(u8, c.a, rendered, "\n", "\n    ");
        try c.write(try c.join(&.{ out, "native_canaries.json" }), try c.fmt("{s},\n    {s}{s}", .{ original[0..end], indented, original[end..] }));
    }
}
