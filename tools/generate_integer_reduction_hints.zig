//! Optional tail hints on bounded modular vector product reductions.
const std = @import("std");
const u = @import("validation/common.zig");
const Output = @import("generate_optimized_fact_canaries.zig").Output;
pub fn main(init: std.process.Init) !void {
    var c = try u.Context.init(init);
    const argv = try init.minimal.args.toSlice(c.a);
    const args = try u.Args.parse(c.a, argv[1..], &.{ "output-root", "verify-root" }, &.{});
    const root = try c.newOutput(try args.require("output-root"));
    const contract = "independent-c-modular-products=optional-tail-and-notail=existing-8-through-128-bit-lanes=four-and-64-lanes=literal-and-dynamic-operands=exact-memory-extents=call-clobbers=guard-pages=preserved";
    var out = try Output.init(&c, "integer-reduction-hints", "integer_reduction_hints_model.c", contract);
    for ([_]usize{ 8, 16, 24, 32, 48, 64, 128 }) |bits| for ([_]usize{ 4, 64 }) |count| {
        try out.ir.writer.print("declare i{0d} @llvm.vector.reduce.mul.v{1d}i{0d}(<{1d} x i{0d}>)\n", .{ bits, count });
        var literal: std.Io.Writer.Allocating = .init(c.a);
        try literal.writer.writeByte('<');
        for (0..count) |lane| try literal.writer.print("{s}i{d} {d}", .{ if (lane == 0) "" else ",", bits, 2 * ((lane + 1) % 7) + 1 });
        try literal.writer.writeByte('>');
        for (0..2) |constant| for ([_][]const u8{ "tail", "notail" }) |hint| {
            const probe = try c.fmt("integer_reduction_hint_probe_{d}", .{out.count});
            try out.probe(&c, probe, bits, count * 2 + constant);
            try out.ir.writer.print("define i64 @{s}(ptr %out,ptr %source,ptr %unused,i64 %salt) {{\nentry:\n", .{probe});
            if (constant == 0) try out.ir.writer.print(" %v = load <{d} x i{d}>,ptr %source,align 1\n", .{ count, bits });
            try out.ir.writer.print(" %r = {s} call i{d} @llvm.vector.reduce.mul.v{d}i{d}(<{d} x i{d}> {s})\n %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)\n store i{d} %r,ptr %out,align 1\n %token_out = getelementptr i8,ptr %out,i64 {d}\n store i64 %token,ptr %token_out,align 1\n ret i64 %token\n}}\n", .{ hint, bits, count, bits, count, bits, if (constant != 0) literal.written() else "%v", bits, bits / 8 });
        };
    };
    if (out.count != 56) return error.ReductionHintInventoryChanged;
    const entry = try out.finish(&c, root, "integer_reduction_hints", "integer-reduction-hints", contract);
    try c.writeJson(try c.join(&.{ root, "native_canaries.json" }), try u.toValue(c.a, .{ .schema = 1, .canaries = &.{entry} }));
    if (args.get("verify-root")) |before| {
        if (!u.json.eql(try c.load(try c.join(&.{ before, "native_canaries.json" })), try c.load(try c.join(&.{ root, "native_canaries.json" })))) return error.RegistryContractMismatch;
        for ([_][]const u8{ "integer_reduction_hints.ll", "integer_reduction_hints_driver.c" }) |file| if (!std.mem.eql(u8, try c.digest(try c.join(&.{ root, file })), try c.digest(try c.join(&.{ before, file })))) return error.GeneratedFixtureMismatch;
    }
    try c.print("integer reduction hints:56 cases/28672 observations per route{s}\n", .{if (args.get("verify-root") != null) "; byte-exact verification passed" else ""});
}
