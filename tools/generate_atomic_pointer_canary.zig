//! Scalar atomic operations on symbolic byte addresses, with an independent C model.
const std = @import("std");
const u = @import("validation/common.zig");
const Output = @import("generate_optimized_fact_canaries.zig").Output;
pub fn main(init: std.process.Init) !void {
    var c = try u.Context.init(init);
    const argv = try init.minimal.args.toSlice(c.a);
    const args = try u.Args.parse(c.a, argv[1..], &.{ "output-root", "verify-root" }, &.{});
    const root = try c.newOutput(try args.require("output-root"));
    const contract = "independent-c-atomic-state-model=symbolic-byte-addresses=scalar-and-pointer-cmpxchg=all-admitted-rmw-operations=atomic-load-and-store=ordering-volatility-and-singlethread-scope=neighbor-bytes=call-clobbers=preserved";
    var out = try Output.init(&c, "atomic-pointer-facts", "atomic_pointer_facts_model.c", contract);
    try out.ir.writer.writeAll("@atomic_pointer_storage = global [128 x i8] zeroinitializer,align 64\ndeclare void @complete_atomic_snapshot(ptr)\ndeclare void @complete_atomic_touch(ptr)\n");
    for ([_]usize{ 8, 16, 32, 64, 0 }) |kind| for (0..12) |operation| {
        if (kind == 0 and operation > 0 and operation < 9) continue;
        for (0..@as(usize, if (operation == 9) 2 else 1)) |success| for (0..2) |offset_kind| for (0..2) |variant| {
            const bits = if (kind == 0) 64 else kind;
            const ty = if (kind == 0) "ptr" else try c.fmt("i{d}", .{bits});
            const probe = try c.fmt("atomic_pointer_probe_{d}", .{out.count});
            const offset: usize = if (offset_kind == 0) 16 else 64;
            const cell = try c.fmt("getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 {d})", .{offset});
            // The parsed atomic value grammar uses SSA operands. Symbolic
            // byte expressions are exercised in every memory address.
            const expected = "%expected";
            const desired = "%desired";
            const scope = if (variant != 0) "syncscope(\"singlethread\") " else "";
            const volatility = if (variant != 0) "volatile " else "";
            const order = if (variant != 0) "seq_cst" else "monotonic";
            try out.probe(&c, probe, kind, operation * 16 + success * 8 + offset_kind * 4 + variant);
            try out.ir.writer.print("define i64 @{s}(ptr %out,ptr %source,ptr %unused,i64 %salt) {{\nentry:\n %expected_ptr = getelementptr i8,ptr %source,i64 8\n %expected = load {s},ptr %expected_ptr,align 1\n %desired_ptr = getelementptr i8,ptr %source,i64 16\n %desired = load {s},ptr %desired_ptr,align 1\n call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))\n %bit = and i64 %salt,1\n %condition = icmp ne i64 %bit,0\n br i1 %condition,label %clobber,label %atomic\nclobber:\n %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)\n br label %atomic\natomic:\n", .{ probe, ty, ty });
            if (operation < 9) {
                const name = ([_][]const u8{ "xchg", "add", "sub", "and", "or", "xor", "nand", "umin", "umax" })[operation];
                try out.ir.writer.print(" %old = atomicrmw {s}{s} ptr {s},{s} {s} {s}{s},align {d}\n", .{ volatility, name, cell, ty, desired, scope, order, bits / 8 });
            } else if (operation == 9) {
                try out.ir.writer.print(" %pair = cmpxchg {s}ptr {s},{s} {s},{s} {s} {s}{s} {s},align {d}\n %old = extractvalue {{ {s}, i1 }} %pair,0\n %success = extractvalue {{ {s}, i1 }} %pair,1\n %flag = zext i1 %success to i64\n", .{ volatility, cell, ty, expected, ty, desired, scope, if (variant != 0) "acq_rel" else "monotonic", if (variant != 0) "acquire" else "monotonic", bits / 8, ty, ty });
            } else if (operation == 10) {
                try out.ir.writer.print(" %old = load atomic {s}{s},ptr {s} {s}{s},align {d}\n", .{ volatility, ty, cell, scope, if (variant != 0) "acquire" else "monotonic", bits / 8 });
            } else {
                try out.ir.writer.print(" %old = load {s},ptr {s},align {d}\n store atomic {s}{s} {s},ptr {s} {s}{s},align {d}\n", .{ ty, cell, bits / 8, volatility, ty, desired, cell, scope, if (variant != 0) "release" else "monotonic", bits / 8 });
            }
            if (kind == 0) {
                try out.ir.writer.writeAll(" %wide = ptrtoint ptr %old to i64\n");
            } else if (bits != 64) {
                try out.ir.writer.print(" %wide = zext {s} %old to i64\n", .{ty});
            }
            const old = if (kind != 0 and bits == 64) "%old" else "%wide";
            try out.ir.writer.print(" %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)\n store i64 {s},ptr %out,align 1\n %flag_out = getelementptr i8,ptr %out,i64 8\n store i64 {s},ptr %flag_out,align 1\n %token_out = getelementptr i8,ptr %out,i64 16\n store i64 %token,ptr %token_out,align 1\n", .{ old, if (operation == 9) "%flag" else "0" });
            try out.ir.writer.writeAll(" %snapshot_out = getelementptr i8,ptr %out,i64 24\n call void @complete_atomic_snapshot(ptr %snapshot_out)\n");
            try out.ir.writer.print(" %answer = xor i64 {s},%token\n ret i64 %answer\n}}\n", .{old});
        };
    };
    if (out.count != 228) return error.AtomicPointerInventoryChanged;
    const entry = try out.finish(&c, root, "atomic_pointer_facts", "atomic-pointer-facts", contract);
    try c.writeJson(try c.join(&.{ root, "native_canaries.json" }), try u.toValue(c.a, .{ .schema = 1, .canaries = &.{entry} }));
    if (args.get("verify-root")) |before| {
        const previous = try c.load(try c.join(&.{ before, "native_canaries.json" }));
        if (!u.json.eql(previous, try c.load(try c.join(&.{ root, "native_canaries.json" })))) return error.RegistryContractMismatch;
        for ([_][]const u8{ "atomic_pointer_facts.ll", "atomic_pointer_facts_driver.c" }) |file| if (!std.mem.eql(u8, try c.digest(try c.join(&.{ root, file })), try c.digest(try c.join(&.{ before, file })))) return error.GeneratedFixtureMismatch;
    }
    try c.print("atomic pointer facts:228 cases/116736 observations per route{s}\n", .{if (args.get("verify-root") != null) "; byte-exact verification passed" else ""});
}
