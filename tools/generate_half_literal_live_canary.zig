//! Half literal arithmetic with independently checked live scalar values.
const std = @import("std");
const u = @import("validation/common.zig");
const Output = @import("generate_optimized_fact_canaries.zig").Output;
const contract = "independent-c-integer-and-half-goldens=live-boolean-and-32-and-64-bit-values=scalar-and-vector-half-addition=literal-and-loaded-seeds=signed-zero-and-nan=optional-tail-hints=call-clobbers=guard-pages=preserved";
pub fn main(init: std.process.Init) !void {
    var c = try u.Context.init(init);
    const argv = try init.minimal.args.toSlice(c.a);
    const args = try u.Args.parse(c.a, argv[1..], &.{ "output-root", "verify-root" }, &.{});
    const root = try c.newOutput(try args.require("output-root"));
    var out = try Output.init(&c, "half-literal-live-values", "half_literal_live_model.c", contract);
    try out.ir.writer.writeAll("declare half @llvm.vector.reduce.fadd.v4f16(half,<4 x half>)\n");
    const values = [_][2][]const u8{
        .{ "0xH0000", "0xH3C00" }, .{ "0xH8000", "0xH8000" }, .{ "0xH3E00", "0xH4080" },
        .{ "0xHC000", "0xH3800" }, .{ "0xH7C00", "0xHFC00" }, .{ "0xH7E00", "0xH3C00" },
    };
    for ([_]usize{ 1, 32, 64 }) |bits| for (values, 0..) |value, kind| for (0..4) |form| {
        const probe = try c.fmt("half_literal_live_probe_{d}", .{out.count});
        try out.probe(&c, probe, bits, kind * 4 + form);
        try out.ir.writer.print("define i64 @{s}(ptr %out,ptr %input,ptr %unused,i64 %salt) {{\nentry:\n %word = load i64,ptr %input,align 1\n", .{probe});
        if (form == 1 or form == 3) try out.ir.writer.writeAll(" %seed_pointer = getelementptr i8,ptr %input,i64 8\n %seed = load half,ptr %seed_pointer,align 1\n");
        if (bits == 1) {
            try out.ir.writer.writeAll(" %kept = icmp ult i64 %word,%salt\n");
        } else if (bits == 32) {
            try out.ir.writer.writeAll(" %salt32 = trunc i64 %salt to i32\n %word32 = trunc i64 %word to i32\n %kept = xor i32 %salt32,%word32\n");
        } else {
            try out.ir.writer.writeAll(" %kept = xor i64 %salt,%word\n");
        }
        const seed = if (form == 1 or form == 3) "%seed" else value[0];
        if (form < 2) {
            try out.ir.writer.print(" %sum = fadd half {s},{s}\n", .{ seed, value[1] });
        } else {
            try out.ir.writer.print(" %sum = {s}call half @llvm.vector.reduce.fadd.v4f16(half {s},<4 x half> <half {s},half 0xH0000,half 0xH0000,half 0xH0000>)\n", .{ if (form == 2) "tail " else "notail ", seed, value[1] });
        }
        try out.ir.writer.writeAll(" %raw = bitcast half %sum to i16\n %nan = fcmp uno half %sum,0xH0000\n %stable = select i1 %nan,i16 32256,i16 %raw\n %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)\n");
        if (bits != 64) try out.ir.writer.print(" %wide = zext i{d} %kept to i64\n", .{bits});
        try out.ir.writer.print(" store i64 %{s},ptr %out,align 1\n %fp_out = getelementptr i8,ptr %out,i64 8\n store i16 %stable,ptr %fp_out,align 1\n %token_out = getelementptr i8,ptr %out,i64 10\n store i64 %token,ptr %token_out,align 1\n %answer = xor i64 %{s},%token\n ret i64 %answer\n}}\n", .{ if (bits == 64) "kept" else "wide", if (bits == 64) "kept" else "wide" });
    };
    if (out.count != 72) return error.CaseInventoryChanged;
    const entry = try out.finish(&c, root, "half_literal_live_values", "half-literal-live-values", contract);
    try c.writeJson(try c.join(&.{ root, "native_canaries.json" }), try u.toValue(c.a, .{ .schema = 1, .canaries = [_]u.Value{entry} }));
    if (args.get("verify-root")) |before| {
        if (!u.json.eql(try c.load(try c.join(&.{ before, "native_canaries.json" })), try c.load(try c.join(&.{ root, "native_canaries.json" })))) return error.RegistryChanged;
        for ([_][]const u8{ "half_literal_live_values.ll", "half_literal_live_values_driver.c" }) |file| {
            if (!std.mem.eql(u8, try c.digest(try c.join(&.{ before, file })), try c.digest(try c.join(&.{ root, file })))) return error.GeneratedFixtureChanged;
        }
    }
    try c.print("half literal live values:72 cases/36864 observations per route{s}\n", .{if (args.get("verify-root") != null) "; byte-exact verification passed" else ""});
}
