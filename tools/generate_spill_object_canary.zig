//! Exercise preserved address values beside live owned arrays.
const std = @import("std");
const u = @import("validation/common.zig");
const Output = @import("generate_optimized_fact_canaries.zig").Output;
const contract = "independent-c-byte-goldens=late-address-spills=live-owned-arrays=constant-vector-stores=forward-and-reverse-observation=call-clobbers=exact-memory-extents=guard-pages=preserved";
pub fn main(init: std.process.Init) !void {
    var c = try u.Context.init(init);
    const argv = try init.minimal.args.toSlice(c.a);
    const args = try u.Args.parse(c.a, argv[1..], &.{ "output-root", "verify-root" }, &.{});
    const root = try c.newOutput(try args.require("output-root"));
    var out = try Output.init(&c, "spill-object-separation", "spill_object_separation_model.c", contract);
    try out.ir.writer.writeAll("declare void @spill_object_copy(ptr,ptr,i64)\n");
    for ([_]usize{ 16, 40, 72 }, 0..) |count, shape| for ([_]usize{ 8, 16, 32, 64 }) |bits| for (0..2) |reverse| {
        const probe = try c.fmt("spill_object_probe_{d}", .{out.count});
        try out.probe(&c, probe, bits, shape * 2 + reverse);
        try out.ir.writer.print("define i64 @{s}(ptr %out,ptr %input,ptr %unused,i64 %salt) {{\nentry:\n", .{probe});
        // Retain room for the preexisting allocation guard while exposing
        // spill/object overlap inside the frame. Only initialized bytes escape.
        for (0..count) |object| try out.ir.writer.print(" %box{d} = alloca [512 x i8],align 16\n", .{object});
        for (0..count) |object| {
            for (0..2) |half| {
                if (half != 0) try out.ir.writer.print(" %tail{0d} = getelementptr i8,ptr %box{0d},i64 16\n", .{object});
                try out.ir.writer.print(" store <{d} x i{d}> <", .{ 128 / bits, bits });
                for (0..128 / bits) |lane| {
                    if (lane != 0) try out.ir.writer.writeAll(",");
                    const value = ((object + 1) * 257 + (half * (128 / bits) + lane) * 17 + shape * 13) & (@as(u128, std.math.maxInt(u64)) >> @intCast(64 - bits));
                    try out.ir.writer.print("i{d} {d}", .{ bits, value });
                }
                try out.ir.writer.print(">,ptr %{s}{d},align 16\n", .{ if (half == 0) "box" else "tail", object });
            }
        }
        try out.ir.writer.writeAll(" %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)\n");
        for (0..count) |iteration| {
            const object = if (reverse == 0) iteration else count - 1 - iteration;
            try out.ir.writer.print(" %destination{0d} = getelementptr i8,ptr %out,i64 {1d}\n call void @spill_object_copy(ptr %box{0d},ptr %destination{0d},i64 32)\n", .{ object, object * 32 });
        }
        try out.ir.writer.print(" %token_out = getelementptr i8,ptr %out,i64 {d}\n store i64 %token,ptr %token_out,align 1\n %answer = xor i64 %token,%salt\n ret i64 %answer\n}}\n", .{count * 32});
    };
    if (out.count != 24) return error.CaseInventoryChanged;
    const entry = try out.finish(&c, root, "spill_object_separation", "spill-object-separation", contract);
    try c.writeJson(try c.join(&.{ root, "native_canaries.json" }), try u.toValue(c.a, .{ .schema = 1, .canaries = [_]u.Value{entry} }));
    if (args.get("verify-root")) |before| {
        if (!u.json.eql(try c.load(try c.join(&.{ before, "native_canaries.json" })), try c.load(try c.join(&.{ root, "native_canaries.json" })))) return error.RegistryChanged;
        for ([_][]const u8{ "spill_object_separation.ll", "spill_object_separation_driver.c" }) |file| {
            if (!std.mem.eql(u8, try c.digest(try c.join(&.{ before, file })), try c.digest(try c.join(&.{ root, file })))) return error.GeneratedFixtureChanged;
        }
    }
    try c.print("spill/object separation:24 cases/12288 observations per route{s}\n", .{if (args.get("verify-root") != null) "; byte-exact verification passed" else ""});
}
