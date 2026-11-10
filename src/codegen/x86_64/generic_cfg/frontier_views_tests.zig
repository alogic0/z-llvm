const std = @import("std");
const ir = @import("../../../ir.zig");
const machine = @import("../machine.zig");
const selector = @import("../generic_cfg_selector.zig");
const verify = @import("../verify.zig");
const encoding = @import("../../../mc/encoding.zig");
const frame = @import("padded_frame.zig");
const wide = @import("wide_integer_forms.zig");

fn executable(module: ir.Module) ![]align(std.heap.page_size_min) u8 {
    const function = module.functions.items[0];
    var output = machine.MachineFunction.init(function.name, function.ret_ty);
    defer output.deinit(std.testing.allocator);
    const result = try selector.tryLower(std.testing.allocator, &output, function);
    if (result == .unsupported) std.debug.print("frontier views {s}: {s}\n", .{ function.name, result.unsupported.detail() });
    try std.testing.expectEqual(selector.SelectionResult.selected, result);
    try verify.verifyFunction(output);
    const code = try encoding.encodeFunction(std.testing.allocator, output);
    defer std.testing.allocator.free(code);
    const memory = try std.posix.mmap(null, code.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    @memcpy(memory[0..code.len], code);
    return memory;
}

const inputs = [_]u64{ 0, 1, 2, 0x80000000, 0x100000001, 0x8000000000000000, std.math.maxInt(u64) };

test "frontier views integer freezes retain dirty upper bits of wider aliases" {
    for ([_]u16{ 33, 40, 48, 56, 63 }) |bits| {
        const source = try std.fmt.allocPrint(std.testing.allocator, "define i64 @probe(i64 %a) {{\nentry:\n %raw = trunc i64 %a to i{d}\n %stable = freeze i{d} %raw\n %value = zext i{d} %stable to i64\n %result = xor i64 %value, %a\n ret i64 %result\n}}\n", .{ bits, bits, bits });
        defer std.testing.allocator.free(source);
        var module = try ir.Module.parse(std.testing.allocator, source);
        defer module.deinit();
        try module.verify();
        const code = try executable(module);
        defer std.posix.munmap(code);
        const run: *const fn (u64) callconv(.c) u64 = @ptrCast(code.ptr);
        const mask = (@as(u64, 1) << @as(u6, @intCast(bits))) - 1;
        for (inputs) |a| try std.testing.expectEqual((a & mask) ^ a, run(a));
    }
}

const wide_template =
    \\define i64 @probe(i128 %input, ptr %out) {{
    \\entry:
    \\ %raw = trunc i128 %input to i{d}
    \\ %stable = freeze i{d} %raw
    \\ %same = xor i{d} %stable, %stable
    \\ %zero = zext i{d} %same to i128
    \\ %full = zext i{d} %stable to i128
    \\ %low = trunc i128 %full to i64
    \\ %upper = lshr i128 %full, 64
    \\ %high = trunc i128 %upper to i64
    \\ store i64 %high, ptr %out
    \\ %result = xor i64 %low, %high
    \\ ret i64 %result
    \\}}
;

fn allocationReplay(allocator: std.mem.Allocator, function: ir.Function) !void {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    _ = try wide.legalize(arena.allocator(), function);
}

test "frontier views wide freezes retain high limbs and borrowed source through allocation failures" {
    for ([_]u16{ 65, 96 }) |bits| {
        const source = try std.fmt.allocPrint(std.testing.allocator, wide_template, .{ bits, bits, bits, bits, bits });
        defer std.testing.allocator.free(source);
        var module = try ir.Module.parse(std.testing.allocator, source);
        defer module.deinit();
        try module.verify();
        const original = module.functions.items[0];
        var moving = std.testing.FailingAllocator.init(std.testing.allocator, .{ .resize_fail_index = 0 });
        try std.testing.checkAllAllocationFailures(moving.allocator(), allocationReplay, .{original});
        try module.verify();
        try std.testing.expectEqual(bits, original.blocks.items[0].instructions.items[1].kind.freeze.ty.int);
        const code = try executable(module);
        defer std.posix.munmap(code);
        const run: *const fn (u128, *u64) callconv(.c) u64 = @ptrCast(code.ptr);
        const mask = (@as(u128, 1) << @as(u7, @intCast(bits))) - 1;
        for (inputs) |a| for (inputs) |b| {
            const input = (@as(u128, b) << 64) | a;
            const value = input & mask;
            var high: u64 = 99;
            try std.testing.expectEqual(@as(u64, @truncate(value)) ^ @as(u64, @truncate(value >> 64)), run(input, &high));
            try std.testing.expectEqual(@as(u64, @truncate(value >> 64)), high);
        };
    }
}

test "frontier views aggregate atomic memory preserves access attributes and source" {
    const text = "define i32 @probe(i32 %a) {\nentry:\n %slot = alloca { i32, i64 }, align 16\n store atomic volatile i32 %a, ptr %slot syncscope(\"singlethread\") release, align 4\n %old = load atomic volatile i32, ptr %slot syncscope(\"singlethread\") acquire, align 4\n ret i32 %old\n}\n";
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();
    try module.verify();
    const original = module.functions.items[0];
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const view = (try frame.legalizeStorage(arena.allocator(), original, null)).?;
    var loads: usize = 0;
    var stores: usize = 0;
    for (view.blocks.items[0].instructions.items) |inst| switch (inst.kind) {
        .load => |load| {
            try std.testing.expectEqualDeep(original.blocks.items[0].instructions.items[2].kind.load.attrs, load.attrs);
            try std.testing.expect(!std.mem.eql(u8, load.ptr.named, "slot"));
            loads += 1;
        },
        .store => |store| {
            try std.testing.expectEqualDeep(original.blocks.items[0].instructions.items[1].kind.store.attrs, store.attrs);
            try std.testing.expect(!std.mem.eql(u8, store.ptr.named, "slot"));
            stores += 1;
        },
        else => {},
    };
    try std.testing.expectEqual(@as(usize, 1), loads);
    try std.testing.expectEqual(@as(usize, 1), stores);
    try std.testing.expectEqualStrings("slot", original.blocks.items[0].instructions.items[2].kind.load.ptr.named);
    const code = try executable(module);
    defer std.posix.munmap(code);
    const run: *const fn (u32) callconv(.c) u32 = @ptrCast(code.ptr);
    for (inputs) |a| try std.testing.expectEqual(@as(u32, @truncate(a)), run(@truncate(a)));
}

test "frontier views private pointer atomics keep old bits and neighboring storage" {
    const text =
        \\define i64 @probe(i64 %a, i64 %b) {
        \\entry:
        \\ %slot = alloca { ptr, i64 }, align 16
        \\ %tail = getelementptr i8, ptr %slot, i64 8
        \\ store i64 %b, ptr %tail
        \\ %pointer = inttoptr i64 %a to ptr
        \\ %replacement = inttoptr i64 %b to ptr
        \\ store atomic ptr %pointer, ptr %slot release, align 8
        \\ %old = atomicrmw xchg ptr %slot, ptr %replacement seq_cst, align 8
        \\ %round = load atomic ptr, ptr %slot acquire, align 8
        \\ %bits = ptrtoint ptr %round to i64
        \\ %before = ptrtoint ptr %old to i64
        \\ %guard = load i64, ptr %tail
        \\ %r0 = xor i64 %bits, %guard
        \\ %result = xor i64 %r0, %before
        \\ ret i64 %result
        \\}
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();
    try module.verify();
    const code = try executable(module);
    defer std.posix.munmap(code);
    const run: *const fn (u64, u64) callconv(.c) u64 = @ptrCast(code.ptr);
    for (inputs) |a| for (inputs) |b| try std.testing.expectEqual(a, run(a, b));
}

test "frontier views pointer flag PHIs preserve null and defined pointer choices" {
    const text =
        \\define i64 @probe(i64 %input, i1 %choose) {
        \\entry:
        \\ %p = inttoptr i64 %input to ptr
        \\ %first = insertvalue { ptr, i1 } poison, ptr %p, 0
        \\ %built = insertvalue { ptr, i1 } %first, i1 %choose, 1
        \\ br i1 %choose, label %have, label %empty
        \\have:
        \\ br label %exit
        \\empty:
        \\ br label %exit
        \\exit:
        \\ %pair = phi { ptr, i1 } [ %built, %have ], [ zeroinitializer, %empty ]
        \\ %stable = freeze { ptr, i1 } %pair
        \\ %value = extractvalue { ptr, i1 } %stable, 0
        \\ %flag = extractvalue { ptr, i1 } %stable, 1
        \\ %bits = ptrtoint ptr %value to i64
        \\ %wide = zext i1 %flag to i64
        \\ %result = xor i64 %bits, %wide
        \\ ret i64 %result
        \\}
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();
    try module.verify();
    const code = try executable(module);
    defer std.posix.munmap(code);
    const run: *const fn (u64, bool) callconv(.c) u64 = @ptrCast(code.ptr);
    for (inputs) |a| {
        try std.testing.expectEqual(@as(u64, 0), run(a, false));
        try std.testing.expectEqual(a ^ 1, run(a, true));
    }
}

test "frontier views unknown atomic global address rolls back and can be legalized with context" {
    const text = "@cells = global [3 x i64] zeroinitializer, align 16\ndefine i32 @probe() {\nentry:\n %old = load atomic i32, ptr getelementptr (i8, ptr @cells, i64 8) acquire, align 4\n ret i32 %old\n}\n";
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();
    try module.verify();
    const function = module.functions.items[0];
    var output = machine.MachineFunction.init(function.name, function.ret_ty);
    defer output.deinit(std.testing.allocator);
    try output.instructions.append(std.testing.allocator, .{ .mov_imm_eax = 7 });
    const rejected = try selector.tryLower(std.testing.allocator, &output, function);
    try std.testing.expect(rejected == .unsupported);
    try std.testing.expectEqual(@as(usize, 1), output.instructions.items.len);
    try std.testing.expectEqual(@as(i32, 7), output.instructions.items[0].mov_imm_eax);
    output.instructions.items.len = 0;
    const context: machine.ReadOnlyModuleContext = .{ .globals = module.globals.items, .aliases = module.aliases.items, .named_types = module.named_types.items, .target_datalayout = module.target_datalayout };
    const selected = try selector.tryLowerWithContext(std.testing.allocator, &output, function, &context);
    try std.testing.expect(selected == .selected);
    try verify.verifyFunction(output);
}

test "frontier views pointer flag constant freezes provide stable field choices" {
    for ([_][]const u8{ "poison", "undef", "zeroinitializer", "{ ptr null, i1 false }" }) |value| {
        const text = try std.fmt.allocPrint(std.testing.allocator,
            \\define i64 @probe() {{
            \\entry:
            \\ %pair = freeze {{ ptr, i1 }} {s}
            \\ %p0 = extractvalue {{ ptr, i1 }} %pair, 0
            \\ %p1 = extractvalue {{ ptr, i1 }} %pair, 0
            \\ %f0 = extractvalue {{ ptr, i1 }} %pair, 1
            \\ %f1 = extractvalue {{ ptr, i1 }} %pair, 1
            \\ %a = ptrtoint ptr %p0 to i64
            \\ %b = ptrtoint ptr %p1 to i64
            \\ %c = zext i1 %f0 to i64
            \\ %d = zext i1 %f1 to i64
            \\ %p = xor i64 %a, %b
            \\ %f = xor i64 %c, %d
            \\ %result = xor i64 %p, %f
            \\ ret i64 %result
            \\}}
        , .{value});
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        try module.verify();
        const code = try executable(module);
        defer std.posix.munmap(code);
        const run: *const fn () callconv(.c) u64 = @ptrCast(code.ptr);
        try std.testing.expectEqual(@as(u64, 0), run());
    }
}

test "frontier views atomic interior addresses preserve root extent and neighboring words" {
    const text =
        \\define i64 @probe(i64 %a, i64 %b, ptr %out) {
        \\entry:
        \\ %space = alloca [8 x i32], align 16
        \\ %head = getelementptr i8, ptr %space, i64 0
        \\ %slot = getelementptr i8, ptr %space, i64 8
        \\ %tail = getelementptr i8, ptr %space, i64 16
        \\ store i64 %a, ptr %head
        \\ store i64 %b, ptr %tail
        \\ store atomic i64 %a, ptr %slot release, align 8
        \\ %old = atomicrmw add ptr %slot, i64 %b acq_rel, align 8
        \\ %new = load atomic i64, ptr %slot acquire, align 8
        \\ %first = load i64, ptr %head
        \\ %last = load i64, ptr %tail
        \\ store i64 %new, ptr %out
        \\ %o1 = getelementptr i8, ptr %out, i64 8
        \\ store i64 %first, ptr %o1
        \\ %o2 = getelementptr i8, ptr %out, i64 16
        \\ store i64 %last, ptr %o2
        \\ ret i64 %old
        \\}
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();
    try module.verify();
    const code = try executable(module);
    defer std.posix.munmap(code);
    const run: *const fn (u64, u64, *[3]u64) callconv(.c) u64 = @ptrCast(code.ptr);
    for (inputs) |a| for (inputs) |b| {
        var out: [3]u64 = .{ 0, 0, 0 };
        try std.testing.expectEqual(a, run(a, b, &out));
        try std.testing.expectEqualDeep([3]u64{ a +% b, a, b }, out);
    };
}
