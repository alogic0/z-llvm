const std = @import("std");
const ir = @import("../../../ir.zig");
const pairs = @import("flag_pair_values.zig");
const machine = @import("../machine.zig");
const selector = @import("../generic_cfg_selector.zig");
const verify = @import("../verify.zig");
const encoding = @import("../../../mc/encoding.zig");

fn executable(module: ir.Module) ![]align(std.heap.page_size_min) u8 {
    const function = module.functions.items[0];
    var output = machine.MachineFunction.init(function.name, function.ret_ty);
    defer output.deinit(std.testing.allocator);
    const selected = try selector.tryLower(std.testing.allocator, &output, function);
    if (selected == .unsupported) std.debug.print("flag pair {s}: {s}\n", .{ function.name, selected.unsupported.detail() });
    try std.testing.expectEqual(selector.SelectionResult.selected, selected);
    try verify.verifyFunction(output);
    const code = try encoding.encodeFunction(std.testing.allocator, output);
    defer std.testing.allocator.free(code);
    const memory = try std.posix.mmap(null, code.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    @memcpy(memory[0..code.len], code);
    return memory;
}

const atomic_ir =
    \\define i64 @probe(ptr %p, i64 %expected, i64 %desired, i1 %choose, ptr %out) {
    \\entry:
    \\  br i1 %choose, label %left, label %right
    \\left:
    \\  %a = cmpxchg ptr %p, i64 %expected, i64 %desired seq_cst seq_cst, align 8
    \\  br label %join
    \\right:
    \\  %b = cmpxchg ptr %p, i64 %desired, i64 %expected acquire monotonic, align 8
    \\  br label %join
    \\join:
    \\  %pair = phi { i64, i1 } [ %a, %left ], [ %b, %right ]
    \\  %stable = freeze { i64, i1 } %pair
    \\  %flag = extractvalue { i64, i1 } %stable, 1
    \\  %old = extractvalue { i64, i1 } %stable, 0
    \\  %wide = zext i1 %flag to i64
    \\  store i64 %wide, ptr %out, align 8
    \\  ret i64 %old
    \\}
;

test "flag pair PHIs preserve one atomic effect old value and success on both edges" {
    var module = try ir.Module.parse(std.testing.allocator, atomic_ir);
    defer module.deinit();
    try module.verify();
    const code = try executable(module);
    defer std.posix.munmap(code);
    const run: *const fn (*u64, u64, u64, bool, *u64) callconv(.c) u64 = @ptrCast(code.ptr);
    for ([_]u64{ 0, 1, 0x8000_0000_0000_0000, 0x1234_5678_9abc_def0, std.math.maxInt(u64) }) |old| {
        for ([_]bool{ false, true }) |choose| for ([_]bool{ false, true }) |success| {
            var cells = [_]u64{ 0xa5a5a5a5a5a5a5a5, old, 0x5a5a5a5a5a5a5a5a };
            const match = if (success) old else old ^ 1;
            const replacement = old ^ 0xfeed_face_1234_5678;
            const expected = if (choose) match else replacement;
            const desired = if (choose) replacement else match;
            var flag: u64 = 99;
            try std.testing.expectEqual(old, run(&cells[1], expected, desired, choose, &flag));
            try std.testing.expectEqual(@as(u64, @intFromBool(success)), flag);
            try std.testing.expectEqual(if (success) replacement else old, cells[1]);
            try std.testing.expectEqual(@as(u64, 0xa5a5a5a5a5a5a5a5), cells[0]);
            try std.testing.expectEqual(@as(u64, 0x5a5a5a5a5a5a5a5a), cells[2]);
        };
    }
}

test "flag pair loop PHIs transport parallel constructors and checked arithmetic" {
    const text =
        \\define i64 @probe(i32 %a, i32 %b, i32 %count, ptr %out) {
        \\entry:
        \\  %sum = call { i32, i1 } @llvm.uadd.with.overflow.i32(i32 %a, i32 %b)
        \\  br label %loop
        \\loop:
        \\  %x = phi { i32, i1 } [ %sum, %entry ], [ %y, %body ]
        \\  %y = phi { i32, i1 } [ { i32 17, i1 true }, %entry ], [ %x, %body ]
        \\  %i = phi i32 [ 0, %entry ], [ %next, %body ]
        \\  %done = icmp eq i32 %i, %count
        \\  br i1 %done, label %exit, label %body
        \\body:
        \\  %next = add i32 %i, 1
        \\  br label %loop
        \\exit:
        \\  %stable = freeze { i32, i1 } %x
        \\  %value = extractvalue { i32, i1 } %stable, 0
        \\  %flag = extractvalue { i32, i1 } %stable, 1
        \\  %wide = zext i32 %value to i64
        \\  %carry = zext i1 %flag to i64
        \\  store i64 %carry, ptr %out
        \\  ret i64 %wide
        \\}
        \\declare { i32, i1 } @llvm.uadd.with.overflow.i32(i32, i32)
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();
    try module.verify();
    const code = try executable(module);
    defer std.posix.munmap(code);
    const run: *const fn (u32, u32, u32, *u64) callconv(.c) u64 = @ptrCast(code.ptr);
    for ([_]u32{ 0, 1, 0x7fffffff, 0x80000000, 0xffffffff }) |a| for ([_]u32{ 0, 1, 0x80000000, 0xffffffff }) |b| {
        for (0..7) |count| {
            var flag: u64 = 99;
            const total = @as(u64, a) + b;
            try std.testing.expectEqual(if (count % 2 == 0) @as(u32, @truncate(total)) else @as(u32, 17), run(a, b, @intCast(count), &flag));
            try std.testing.expectEqual(if (count % 2 == 0) @intFromBool(total > std.math.maxInt(u32)) else @as(u64, 1), flag);
        }
    };
}

test "flag pair rewrite keeps source storage collision identities and producer count" {
    const text =
        \\define i32 @probe(i1 %choose, i32 %a, i32 %b, i32 %"__zllvm_flag_pair_\30") {
        \\entry:
        \\  %sum = call { i32, i1 } @llvm.uadd.with.overflow.i32(i32 %a, i32 %b)
        \\  %one = insertvalue { i32, i1 } poison, i32 %a, 0
        \\  %two = insertvalue { i32, i1 } %one, i1 false, 1
        \\  %pair = select i1 %choose, { i32, i1 } %sum, { i32, i1 } %two
        \\  %value = extractvalue { i32, i1 } %pair, 0
        \\  ret i32 %value
        \\}
        \\declare { i32, i1 } @llvm.uadd.with.overflow.i32(i32, i32)
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();
    try module.verify();
    const original = module.functions.items[0];
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const expanded = (try pairs.legalize(arena.allocator(), original)).?;
    try std.testing.expect(original.blocks.items[0].instructions.items[3].kind.select.ty == .aggregate);
    var calls: usize = 0;
    for (expanded.blocks.items) |block| for (block.instructions.items) |inst| {
        if (inst.kind == .call) calls += 1;
        if (inst.result) |name| try std.testing.expect(!ir.identifiers.eql(name, "__zllvm_flag_pair_0"));
        if (inst.kind == .select) try std.testing.expect(inst.kind.select.ty == .int);
    };
    try std.testing.expectEqual(@as(usize, 1), calls);
    try std.testing.expect((try pairs.legalize(arena.allocator(), expanded)) == null);
    const code = try executable(module);
    defer std.posix.munmap(code);
    const run: *const fn (bool, u32, u32, u32) callconv(.c) u32 = @ptrCast(code.ptr);
    try std.testing.expectEqual(@as(u32, 7), run(false, 7, 12, 91));
    try std.testing.expectEqual(@as(u32, 19), run(true, 7, 12, 91));
}

test "flag pair rewrite rejects aggregate escapes and opaque references unchanged" {
    for ([_][]const u8{
        "define { i32, i1 } @probe(i1 %c) {\nentry:\n %pair = select i1 %c, { i32, i1 } zeroinitializer, { i32, i1 } poison\n ret { i32, i1 } %pair\n}\n",
        "define void @probe(i1 %c, ptr %p) {\nentry:\n %pair = select i1 %c, { i32, i1 } zeroinitializer, { i32, i1 } poison\n store { i32, i1 } %pair, ptr %p\n ret void\n}\n",
        "define void @probe(i1 %c) {\nentry:\n %pair = select i1 %c, { i32, i1 } zeroinitializer, { i32, i1 } poison\n call void @sink({ i32, i1 } %pair)\n ret void\n}\n",
    }) |text| {
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        const function = module.functions.items[0];
        try std.testing.expect((try pairs.legalize(arena.allocator(), function)) == null);
        try std.testing.expect(function.blocks.items[0].instructions.items[0].kind.select.ty == .aggregate);
    }
}

fn allocationReplay(allocator: std.mem.Allocator, function: ir.Function) !void {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    _ = try pairs.legalize(arena.allocator(), function);
}

test "flag pair freezes refine undefined fields once and retain defined constants" {
    for ([_][]const u8{ "poison", "undef", "zeroinitializer", "{ i64 4294967297, i1 true }" }, 0..) |value, which| {
        const text = try std.fmt.allocPrint(std.testing.allocator,
            \\define i64 @probe() {{
            \\entry:
            \\  %pair = freeze {{ i64, i1 }} {s}
            \\  %a = extractvalue {{ i64, i1 }} %pair, 0
            \\  %b = extractvalue {{ i64, i1 }} %pair, 0
            \\  %flag = extractvalue {{ i64, i1 }} %pair, 1
            \\  %same = xor i64 %a, %b
            \\  %wide = zext i1 %flag to i64
            \\  %result = add i64 %same, %wide
            \\  ret i64 %result
            \\}}
        , .{value});
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        try module.verify();
        const code = try executable(module);
        defer std.posix.munmap(code);
        const run: *const fn () callconv(.c) u64 = @ptrCast(code.ptr);
        const result = run();
        if (which < 2) try std.testing.expect(result <= 1) else try std.testing.expectEqual(@as(u64, @intFromBool(which == 3)), result);
    }
}

test "flag pair removal rejects local references in opaque instruction metadata" {
    var module = try ir.Module.parse(std.testing.allocator, "define i64 @probe(i1 %c, i64 %x) {\nentry:\n %pair = select i1 %c, { i64, i1 } zeroinitializer, { i64, i1 } poison\n %result = add i64 %x, 0\n ret i64 %result\n}\n");
    defer module.deinit();
    module.functions.items[0].blocks.items[0].instructions.items[1].metadata = ", !opaque !{ { i64, i1 } %pair }";
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    try std.testing.expect((try pairs.legalize(arena.allocator(), module.functions.items[0])) == null);
}

test "flag pair allocation failures leave borrowed PHI operands intact" {
    var module = try ir.Module.parse(std.testing.allocator, atomic_ir);
    defer module.deinit();
    const original = module.functions.items[0];
    var moving = std.testing.FailingAllocator.init(std.testing.allocator, .{ .resize_fail_index = 0 });
    try std.testing.checkAllAllocationFailures(moving.allocator(), allocationReplay, .{original});
    try module.verify();
    try std.testing.expect(original.blocks.items[3].instructions.items[0].kind.phi.ty == .aggregate);
    try std.testing.expectEqualStrings("a", original.blocks.items[3].instructions.items[0].kind.phi.incoming.items[0].value.named);
}
