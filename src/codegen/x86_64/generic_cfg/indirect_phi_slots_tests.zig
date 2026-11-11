const std = @import("std");
const ir = @import("../../../ir.zig");
const forms = @import("indirect_phi_slots.zig");

const loop_source =
    \\define i64 @parallel(ptr %address, i64 %a, i64 %b, i1 %again) {
    \\entry:
    \\ indirectbr ptr %address, [label %loop, label %exit]
    \\loop:
    \\ %x = phi i64 [ %a, %entry ], [ %y, %loop ]
    \\ %y = phi i64 [ %b, %entry ], [ %x, %loop ]
    \\ %n = phi i32 [ 0, %entry ], [ %next, %loop ]
    \\ %next = add i32 %n, 1
    \\ br i1 %again, label %loop, label %exit
    \\exit:
    \\ %value = phi i64 [ %a, %entry ], [ %x, %loop ]
    \\ ret i64 %value
    \\}
;

test "owned PHI fallback preserves direct loop snapshots and original control flow" {
    const source = try std.mem.replaceOwned(u8, std.testing.allocator, loop_source, "indirectbr ptr %address, [label %loop, label %exit]", "br i1 %again, label %loop, label %exit");
    defer std.testing.allocator.free(source);
    var module = try ir.Module.parse(std.testing.allocator, source);
    defer module.deinit();
    try module.verify();
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    try std.testing.expect((try forms.legalize(arena.allocator(), module.functions.items[0])) == null);
    const rewritten = (try forms.legalizeAll(arena.allocator(), module.functions.items[0])).?;
    try verifyPrivate(arena.allocator(), module, rewritten);
    try std.testing.expectEqual(module.functions.items[0].blocks.items.len, rewritten.blocks.items.len);
    for (rewritten.blocks.items) |block| for (block.instructions.items) |inst| if (!inst.removed) try std.testing.expect(inst.kind != .phi);
    try std.testing.expect((try forms.legalizeAll(arena.allocator(), rewritten)) == null);
    try module.verify();
}

fn verifyPrivate(allocator: std.mem.Allocator, source: ir.Module, function: ir.Function) !void {
    var private = source;
    private.functions = try source.functions.clone(allocator);
    private.functions.items[0] = function;
    try private.verify();
}

test "indirect PHI slots preserve original targets source ownership and parallel loop SSA" {
    var module = try ir.Module.parse(std.testing.allocator, loop_source);
    defer module.deinit();
    try module.verify();
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const original = module.functions.items[0];
    const rewritten = (try forms.legalize(arena.allocator(), original)).?;
    try verifyPrivate(arena.allocator(), module, rewritten);
    try module.verify();
    try std.testing.expectEqual(original.blocks.items.len, rewritten.blocks.items.len);
    try std.testing.expectEqual(original.params.items.ptr, rewritten.params.items.ptr);
    try std.testing.expect(original.blocks.items.ptr != rewritten.blocks.items.ptr);
    const before = original.blocks.items[0].terminator.?.indirectbr;
    const after = rewritten.blocks.items[0].terminator.?.indirectbr;
    try std.testing.expectEqual(before.targets.items.ptr, after.targets.items.ptr);
    try std.testing.expect(before.addr.eql(after.addr));
    var allocations: usize = 0;
    var freezes: usize = 0;
    for (original.blocks.items, rewritten.blocks.items) |old, new| {
        try std.testing.expectEqualStrings(old.name, new.name);
        try std.testing.expect(old.instructions.items.ptr != new.instructions.items.ptr);
        for (new.instructions.items) |inst| {
            if (inst.removed) continue;
            try std.testing.expect(inst.kind != .phi);
            if (inst.kind == .alloca) allocations += 1;
            if (inst.kind == .freeze) freezes += 1;
        }
    }
    try std.testing.expectEqual(@as(usize, 4), allocations);
    try std.testing.expect(freezes >= 5);
    try std.testing.expect(original.blocks.items[1].instructions.items[0].kind == .phi);
    try std.testing.expect((try forms.legalize(arena.allocator(), rewritten)) == null);
}

test "indirect PHI slots use native carriers and restore every scalar source type" {
    for ([_][]const u8{ "i1", "i2", "i8", "i16", "i24", "i32", "i40", "i56", "i64", "i65", "i96", "i128", "ptr", "half", "float", "double", "<2 x double>" }) |ty| {
        const text = try std.fmt.allocPrint(
            std.testing.allocator,
            "define {s} @carrier(ptr %address, {s} %input) {{\nentry:\n indirectbr ptr %address, [label %target]\ntarget:\n %value = phi {s} [ %input, %entry ]\n ret {s} %value\n}}\n",
            .{ ty, ty, ty, ty },
        );
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        try module.verify();
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        const original = module.functions.items[0];
        const rewritten = (try forms.legalize(arena.allocator(), original)).?;
        try verifyPrivate(arena.allocator(), module, rewritten);
        try std.testing.expectEqual(original.ret_ty, rewritten.ret_ty);
        try std.testing.expectEqual(original.params.items.ptr, rewritten.params.items.ptr);
        for (rewritten.blocks.items) |block| for (block.instructions.items) |inst| if (inst.kind == .load or inst.kind == .store) {
            const memory_ty = if (inst.kind == .load) inst.kind.load.ty else inst.kind.store.ty;
            try std.testing.expect(memory_ty == .ptr or (memory_ty == .int and (memory_ty.int == 32 or memory_ty.int == 64 or memory_ty.int == 128)) or
                memory_ty.eql(.{ .vector = .{ .len = 2, .elem_ty = .double } }));
        };
        try std.testing.expect((try forms.legalize(arena.allocator(), rewritten)) == null);
        try module.verify();
    }
}

test "indirect PHI slots keep unsupported graphs and ordinary direct PHIs unchanged" {
    for ([_][]const u8{ "i129", "{ i64, i64 }", "<2 x i64>" }) |ty| {
        const text = try std.fmt.allocPrint(
            std.testing.allocator,
            "define {s} @unsupported(ptr %address, {s} %input) {{\nentry:\n indirectbr ptr %address, [label %target]\ntarget:\n %value = phi {s} [ %input, %entry ]\n ret {s} %value\n}}\n",
            .{ ty, ty, ty, ty },
        );
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        try std.testing.expect((try forms.legalize(arena.allocator(), module.functions.items[0])) == null);
    }
    var module = try ir.Module.parse(std.testing.allocator,
        \\define i64 @ordinary(i64 %input) {
        \\entry:
        \\ br label %target
        \\target:
        \\ %value = phi i64 [ %input, %entry ]
        \\ ret i64 %value
        \\}
    );
    defer module.deinit();
    try std.testing.expect((try forms.legalize(std.testing.allocator, module.functions.items[0])) == null);
}

fn checkAllocation(allocator: std.mem.Allocator, module: ir.Module) !void {
    // Optional rewrites are arena-owned, including discarded partial graphs.
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const rewritten = (try forms.legalize(arena.allocator(), module.functions.items[0])).?;
    try verifyPrivate(arena.allocator(), module, rewritten);
    try std.testing.expectEqual(@as(usize, 3), rewritten.blocks.items.len);
}

test "indirect PHI slots release every partial arena and preserve source on allocation failure" {
    var module = try ir.Module.parse(std.testing.allocator, loop_source);
    defer module.deinit();
    var moving = std.testing.FailingAllocator.init(std.testing.allocator, .{ .resize_fail_index = 0 });
    try std.testing.checkAllAllocationFailures(moving.allocator(), checkAllocation, .{module});
    try module.verify();
    try std.testing.expect(module.functions.items[0].blocks.items[1].instructions.items[0].kind == .phi);
}
