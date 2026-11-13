//! Native integer-address pointer ordering and annotated register snapshots.
const std = @import("std");
const u = @import("validation/common.zig");
const Output = @import("generate_optimized_fact_canaries.zig").Output;
const snapshot = " movq %rax, 0x00(%rdi)\\0A movq %rdx, 0x08(%rdi)\\0A movq %rcx, 0x10(%rdi)\\0A movq %rbx, 0x18(%rdi)\\0A movq %rsi, 0x20(%rdi)\\0A movq %rdi, 0x28(%rdi)\\0A movq %rbp, 0x30(%rdi)\\0A movq %rsp, 0x38(%rdi)\\0A movq %r8,  0x40(%rdi)\\0A movq %r9,  0x48(%rdi)\\0A movq %r10, 0x50(%rdi)\\0A movq %r11, 0x58(%rdi)\\0A movq %r12, 0x60(%rdi)\\0A movq %r13, 0x68(%rdi)\\0A movq %r14, 0x70(%rdi)\\0A movq %r15, 0x78(%rdi)\\0A leaq (%rip), %rax\\0A movq %rax, 0x80(%rdi)";
pub fn main(init: std.process.Init) !void {
    var c = try u.Context.init(init);
    const argv = try init.minimal.args.toSlice(c.a);
    const args = try u.Args.parse(c.a, argv[1..], &.{ "output-root", "verify-root" }, &.{});
    const root = try c.newOutput(try args.require("output-root"));
    const entries = [_]u.Value{ try pointerOrder(&c, root), try snapshotFacts(&c, root) };
    try c.writeJson(try c.join(&.{ root, "native_canaries.json" }), try u.toValue(c.a, .{ .schema = 1, .canaries = entries }));
    if (args.get("verify-root")) |before| {
        if (!u.json.eql(try c.load(try c.join(&.{ before, "native_canaries.json" })), try c.load(try c.join(&.{ root, "native_canaries.json" })))) return error.RegistryChanged;
        for (entries) |entry| for ([_][]const u8{ ".ll", "_driver.c" }) |suffix| {
            const file = try c.fmt("{s}{s}", .{ try u.str(entry, "population"), suffix });
            if (!std.mem.eql(u8, try c.digest(try c.join(&.{ root, file })), try c.digest(try c.join(&.{ before, file })))) return error.GeneratedFixtureChanged;
        };
    }
    try c.print("pointer ordering:80 cases;register snapshot facts:24 cases{s}\n", .{if (args.get("verify-root") != null) "; byte-exact verification passed" else ""});
}
fn pointerOrder(c: *u.Context, root: []const u8) !u.Value {
    const contract = "independent-c-integer-address-order=all-eight-relational-predicates=high-address-bits=null-and-constant-pointers-on-either-side=caller-and-owned-and-global-geps=quoted-symbols=exact-differences=live-results-after-clobbers=guard-pages=preserved";
    var out = try Output.init(c, "pointer-order-facts", "pointer_order_facts_model.c", contract);
    try out.ir.writer.writeAll("@pointer_order_global = global [128 x i8] zeroinitializer,align 16\n@\"pointer order quoted\" = global [128 x i8] zeroinitializer,align 16\n");
    for ([_][]const u8{ "ult", "ule", "ugt", "uge", "slt", "sle", "sgt", "sge" }, 0..) |predicate, pred| for (0..10) |form| {
        const probe = try c.fmt("pointer_order_probe_{d}", .{out.count});
        try out.probe(c, probe, 64, form * 8 + pred);
        try out.ir.writer.print("define i64 @{s}(ptr %out,ptr %input,ptr %unused,i64 %salt) {{\nentry:\n %left_bits = load i64,ptr %input,align 1\n %rp = getelementptr i8,ptr %input,i64 8\n %right_bits = load i64,ptr %rp,align 1\n", .{probe});
        switch (form) {
            0 => try out.ir.writer.writeAll(" %left = inttoptr i64 %left_bits to ptr\n %right = inttoptr i64 %right_bits to ptr\n"),
            1, 3 => {
                if (form == 3) try out.ir.writer.writeAll(" %owned = alloca [128 x i8],align 16\n");
                try out.ir.writer.print(" %left = getelementptr i8,ptr {0s},i64 %left_bits\n %right = getelementptr i8,ptr {0s},i64 %right_bits\n", .{if (form == 1) "%input" else "%owned"});
            },
            2 => try out.ir.writer.writeAll(" %right = getelementptr i8,ptr @pointer_order_global,i64 %right_bits\n"),
            4, 5, 6 => try out.ir.writer.writeAll(" %right = inttoptr i64 %right_bits to ptr\n"),
            7 => try out.ir.writer.writeAll(" %right = getelementptr i8,ptr @\"pointer order quoted\",i64 %right_bits\n"),
            8, 9 => try out.ir.writer.writeAll(" %left = inttoptr i64 %left_bits to ptr\n"),
            else => unreachable,
        }
        const left = switch (form) {
            2, 6 => "@pointer_order_global",
            4 => "null",
            5 => "inttoptr (i64 9223372036854775808 to ptr)",
            7 => "getelementptr (i8,ptr @\"pointer order quoted\",i64 31)",
            else => "%left",
        };
        const right = switch (form) {
            8 => "null",
            9 => "inttoptr (i64 -1 to ptr)",
            else => "%right",
        };
        try out.ir.writer.print(" %c = icmp {0s} ptr {1s},{2s}\n %comparison = zext i1 %c to i64\n %li = ptrtoint ptr {1s} to i64\n %ri = ptrtoint ptr {2s} to i64\n %delta = sub i64 %ri,%li\n %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)\n store i64 %comparison,ptr %out,align 1\n %dp = getelementptr i8,ptr %out,i64 8\n store i64 %delta,ptr %dp,align 1\n %op = getelementptr i8,ptr %out,i64 16\n store i64 %token,ptr %op,align 1\n %answer = xor i64 %comparison,%token\n ret i64 %answer\n}}\n", .{ predicate, left, right });
    };
    if (out.count != 80) return error.PointerCaseInventoryChanged;
    return out.finish(c, root, "pointer_order_facts", "pointer-order-facts", contract);
}
fn snapshotFacts(c: *u.Context, root: []const u8) !u.Value {
    const contract = "independent-c-assembly-observer=exact-existing-register-snapshot=validated-pointer-facts=optional-tail-hints=caller-and-owned-buffers=preserved-callee-registers=exact-stack-and-frame-pointers=bounded-code-address=exact-memory-extent=call-clobbers=guard-pages=preserved";
    var out = try Output.init(c, "register-snapshot-facts", "register_snapshot_facts_model.c", contract);
    try out.ir.writer.writeAll("declare i64 @snapshot_check(ptr,ptr)\nattributes #7 = { nounwind }\n");
    for ([_][]const u8{ "", "nonnull ", "noundef nonnull ", "nonnull align 8 dereferenceable(136) " }) |facts| for ([_][]const u8{ "", "tail ", "notail " }) |hint| for (0..2) |owned| {
        const probe = try c.fmt("register_snapshot_fact_probe_{d}", .{out.count});
        try out.probe(c, probe, 64, owned);
        try out.ir.writer.print("define i64 @{s}(ptr %out,ptr %input,ptr %unused,i64 %salt) {{\nentry:\n", .{probe});
        if (owned != 0) try out.ir.writer.writeAll(" %buffer = alloca [136 x i8],align 16\n") else try out.ir.writer.writeAll(" %buffer = getelementptr i8,ptr %out,i64 0\n");
        try out.ir.writer.print(" {0s}call void asm sideeffect \"{1s}\",\"{{rdi}},~{{memory}},~{{rax}},~{{dirflag}},~{{fpsr}},~{{flags}}\"(ptr {2s}%buffer) #7\n %checked = call i64 @snapshot_check(ptr %buffer,ptr @{3s})\n %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)\n store i64 %checked,ptr %out,align 1\n", .{ hint, snapshot, facts, probe });
        for (1..17) |word| try out.ir.writer.print(" %zero{0d} = getelementptr i8,ptr %out,i64 {1d}\n store i64 0,ptr %zero{0d},align 1\n", .{ word, word * 8 });
        try out.ir.writer.writeAll(" %op = getelementptr i8,ptr %out,i64 136\n store i64 %token,ptr %op,align 1\n %answer = xor i64 %checked,%token\n ret i64 %answer\n}\n");
    };
    if (out.count != 24) return error.SnapshotCaseInventoryChanged;
    return out.finish(c, root, "register_snapshot_facts", "register-snapshot-facts", contract);
}
