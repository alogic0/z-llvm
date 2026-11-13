//! Bounded private i140 vectors with independent bit-by-bit saturation models.
const std = @import("std");
const u = @import("validation/common.zig");
const Output = @import("generate_optimized_fact_canaries.zig").Output;
pub fn main(init: std.process.Init) !void {
    var c = try u.Context.init(init);
    const argv = try init.minimal.args.toSlice(c.a);
    const args = try u.Args.parse(c.a, argv[1..], &.{ "output-root", "verify-root" }, &.{});
    const root = try c.newOutput(try args.require("output-root"));
    const contract = "independent-c-bit-model=i140-and-i200-saturating-shifts=four-private-i140-lanes=all-ten-comparisons=literal-and-constructed-operands=optional-tail-hints=dirty-input-padding=live-limbs-after-clobbers=exact-output-bytes=guard-pages=preserved";
    var out = try Output.init(&c, "wide-saturation-vectors", "wide_saturation_vectors_model.c", contract);
    for ([_]usize{ 140, 200 }) |bits| for ([_][]const u8{ "u", "s" }) |sign|
        try out.ir.writer.print("declare i{0d} @llvm.{1s}shl.sat.i{0d}(i{0d},i{0d})\n", .{ bits, sign });
    // Share the expensive scalar saturation graphs. Each comparison kernel
    // still retains all six exact results across its clobbering call.
    for ([_]usize{ 140, 200 }) |bits| for ([_][]const u8{ "u", "s" }) |sign| for ([_][]const u8{ "", "tail ", "notail " }, 0..) |hint, hint_index| {
        const helper = try c.fmt("wide_sat_{d}_{s}_{d}", .{ bits, sign, hint_index });
        try u.add(&out.functions, u.s(helper));
        try out.ir.writer.print("define internal void @{0s}(ptr %out,ptr %input,i64 %shift) noinline {{\nentry:\n %a = load i{1d},ptr %input,align 1\n %s = zext i64 %shift to i{1d}\n %r = {2s}call i{1d} @llvm.{3s}shl.sat.i{1d}(i{1d} %a,i{1d} %s)\n", .{ helper, bits, hint, sign });
        for (0..(bits + 63) / 64) |limb| {
            const value = if (limb == 0) "%r" else try c.fmt("%shift{d}", .{limb});
            if (limb != 0) try out.ir.writer.print(" %shift{d} = lshr i{d} %r,{d}\n", .{ limb, bits, limb * 64 });
            try out.ir.writer.print(" %word{0d} = trunc i{1d} {2s} to i64\n %out{0d} = getelementptr i8,ptr %out,i64 {3d}\n store i64 %word{0d},ptr %out{0d},align 1\n", .{ limb, bits, value, limb * 8 });
        }
        try out.ir.writer.writeAll(" ret void\n}\n");
    };
    const rhs = [_]i256{ 0, -1, (@as(i256, 1) << 139) - 1, -(@as(i256, 1) << 139) };
    for ([_][]const u8{ "eq", "ne", "ugt", "uge", "ult", "ule", "sgt", "sge", "slt", "sle" }, 0..) |predicate, pred| for (0..2) |constructed| for (0..3) |hint_index| {
        const probe = try c.fmt("wide_saturation_vector_probe_{d}", .{out.count});
        try out.probe(&c, probe, 140, pred * 2 + constructed);
        try out.ir.writer.print("define i64 @{s}(ptr %out,ptr %input,ptr %unused,i64 %salt) {{\nentry:\n", .{probe});
        try out.ir.writer.writeAll(" %temporary = alloca [160 x i8],align 16\n %constant = alloca i140,align 16\n store i140 1267650600228229401496703205376,ptr %constant,align 16\n %bp = getelementptr i8,ptr %input,i64 32\n %sp = getelementptr i8,ptr %input,i64 64\n %s0 = load i64,ptr %sp,align 1\n %tp = getelementptr i8,ptr %input,i64 72\n %t0 = load i64,ptr %tp,align 1\n");
        for (0..6) |i| {
            const bits: usize = if (i < 4) 140 else 200;
            const input = if (i < 2) "%input" else if (i < 4) "%constant" else "%bp";
            const offset: usize = if (i < 4) i * 24 else 96 + (i - 4) * 32;
            try out.ir.writer.print(" %temporary{0d} = getelementptr i8,ptr %temporary,i64 {1d}\n call void @wide_sat_{2d}_{3s}_{4d}(ptr %temporary{0d},ptr {5s},i64 %{6s}0)\n", .{ i, offset, bits, if (i % 2 == 0) "u" else "s", hint_index, input, if (i < 4) "s" else "t" });
        }
        for (0..6) |i| try out.ir.writer.print(" %r{0d} = load i{1d},ptr %temporary{0d},align 1\n", .{ i, @as(usize, if (i < 4) 140 else 200) });
        for (0..4) |i| try out.ir.writer.print(" %v{0d} = insertelement <4 x i140> {1s},i140 %r{0d},i64 {0d}\n", .{ i, if (i == 0) "poison" else try c.fmt("%v{d}", .{i - 1}) });
        if (constructed != 0) for (rhs, 0..) |value, i| try out.ir.writer.print(" %w{0d} = insertelement <4 x i140> {1s},i140 {2d},i32 {0d}\n", .{ i, if (i == 0) "poison" else try c.fmt("%w{d}", .{i - 1}), value });
        const right = if (constructed != 0) "%w3" else try c.fmt("<i140 {d},i140 {d},i140 {d},i140 {d}>", .{ rhs[0], rhs[1], rhs[2], rhs[3] });
        try out.ir.writer.print(" %cmp = icmp {s} <4 x i140> %v3,{s}\n %packed_mask = bitcast <4 x i1> %cmp to i4\n %mask = zext i4 %packed_mask to i64\n %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)\n", .{ predicate, right });
        var offset: usize = 0;
        for (0..6) |i| {
            const bits: usize = if (i < 4) 140 else 200;
            for (0..(bits + 63) / 64) |limb| {
                const value = if (limb == 0) try c.fmt("%r{d}", .{i}) else try c.fmt("%shift{d}_{d}", .{ i, limb });
                if (limb != 0) try out.ir.writer.print(" %shift{d}_{d} = lshr i{d} %r{d},{d}\n", .{ i, limb, bits, i, limb * 64 });
                try out.ir.writer.print(" %word{0d}_{1d} = trunc i{2d} {3s} to i64\n %out{0d}_{1d} = getelementptr i8,ptr %out,i64 {4d}\n store i64 %word{0d}_{1d},ptr %out{0d}_{1d},align 1\n", .{ i, limb, bits, value, offset });
                offset += 8;
            }
        }
        if (offset != 160) return error.OutputExtentChanged;
        try out.ir.writer.writeAll(" %mp = getelementptr i8,ptr %out,i64 160\n store i64 %mask,ptr %mp,align 1\n %op = getelementptr i8,ptr %out,i64 168\n store i64 %token,ptr %op,align 1\n %answer = xor i64 %mask,%token\n ret i64 %answer\n}\n");
    };
    if (out.count != 60) return error.CaseInventoryChanged;
    const entry = try out.finish(&c, root, "wide_saturation_vectors", "wide-saturation-vectors", contract);
    try c.writeJson(try c.join(&.{ root, "native_canaries.json" }), try u.toValue(c.a, .{ .schema = 1, .canaries = &.{entry} }));
    if (args.get("verify-root")) |before| {
        if (!u.json.eql(try c.load(try c.join(&.{ before, "native_canaries.json" })), try c.load(try c.join(&.{ root, "native_canaries.json" })))) return error.RegistryChanged;
        for ([_][]const u8{ "wide_saturation_vectors.ll", "wide_saturation_vectors_driver.c" }) |file| if (!std.mem.eql(u8, try c.digest(try c.join(&.{ root, file })), try c.digest(try c.join(&.{ before, file })))) return error.GeneratedFixtureChanged;
    }
    try c.print("wide saturation vectors:60 cases/30720 observations per route{s}\n", .{if (args.get("verify-root") != null) "; byte-exact verification passed" else ""});
}
