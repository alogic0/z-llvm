//! Exact volatile scalar reads through ordinary and quoted symbolic addresses.
const std = @import("std");
const u = @import("validation/common.zig");
const Output = @import("generate_optimized_fact_canaries.zig").Output;
pub fn main(init: std.process.Init) !void {
    var c = try u.Context.init(init);
    const argv = try init.minimal.args.toSlice(c.a);
    const args = try u.Args.parse(c.a, argv[1..], &.{ "output-root", "verify-root" }, &.{});
    const root = try c.newOutput(try args.require("output-root"));
    const contract = "independent-c-memory-goldens=symbolic-and-quoted-globals=exact-volatile-8-through-64-bit-and-pointer-reads=defined-external-mutation=unaligned-and-page-end-accesses=neighbor-bytes=call-clobbers=guard-pages=preserved";
    var out = try Output.init(&c, "symbolic-volatile-loads", "symbolic_volatile_model.c", contract);
    try out.ir.writer.writeAll("@symbolic_volatile_plain = global [8192 x i8] zeroinitializer,align 4096\n@\"symbolic volatile storage\" = global [8192 x i8] zeroinitializer,align 4096\ndeclare void @complete_volatile_change(ptr,i64)\ndeclare void @complete_volatile_snapshot(ptr)\n");
    for ([_]usize{ 8, 16, 32, 64, 0 }) |bits| for (0..2) |symbol| {
        const bytes: usize = if (bits == 0) 8 else bits / 8;
        const ty = if (bits == 0) "ptr" else try c.fmt("i{d}", .{bits});
        const global = if (symbol == 0) "@symbolic_volatile_plain" else "@\"symbolic volatile storage\"";
        for ([_]usize{ 0, 8, 31, 4096 - bytes }) |offset| {
            const name = try c.fmt("symbolic_volatile_probe_{d}", .{out.count});
            const pointer = if (offset == 0 and bits != 0) global else try c.fmt("getelementptr inbounds (i8,ptr {s},i64 {d})", .{ global, offset });
            try out.probe(&c, name, bits, symbol * 8192 + offset);
            try out.ir.writer.print("define i64 @{s}(ptr %out,ptr %unused,ptr %expected,i64 %salt) {{\nentry:\n %before = load volatile {s},ptr {s},align 1\n call void @complete_volatile_change(ptr {s},i64 {d})\n %after = load volatile {s},ptr {s},align 1\n %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)\n store {s} %before,ptr %out,align 1\n %after_out = getelementptr i8,ptr %out,i64 {d}\n store {s} %after,ptr %after_out,align 1\n %token_out = getelementptr i8,ptr %out,i64 {d}\n store i64 %token,ptr %token_out,align 1\n %snapshot_out = getelementptr i8,ptr %out,i64 {d}\n call void @complete_volatile_snapshot(ptr %snapshot_out)\n ret i64 %token\n}}\n", .{ name, ty, pointer, pointer, bytes, ty, pointer, ty, bytes, ty, 2 * bytes, 2 * bytes + 8 });
        }
    };
    if (out.count != 40) return error.SymbolicVolatileInventoryChanged;
    const entry = try out.finish(&c, root, "symbolic_volatile_loads", "symbolic-volatile-loads", contract);
    try c.writeJson(try c.join(&.{ root, "native_canaries.json" }), try u.toValue(c.a, .{ .schema = 1, .canaries = &.{entry} }));
    if (args.get("verify-root")) |before| {
        if (!u.json.eql(try c.load(try c.join(&.{ before, "native_canaries.json" })), try c.load(try c.join(&.{ root, "native_canaries.json" })))) return error.RegistryContractMismatch;
        for ([_][]const u8{ "symbolic_volatile_loads.ll", "symbolic_volatile_loads_driver.c" }) |file| if (!std.mem.eql(u8, try c.digest(try c.join(&.{ root, file })), try c.digest(try c.join(&.{ before, file })))) return error.GeneratedFixtureMismatch;
    }
    try c.print("symbolic volatile loads:40 cases/20480 observations per route{s}\n", .{if (args.get("verify-root") != null) "; byte-exact verification passed" else ""});
}
