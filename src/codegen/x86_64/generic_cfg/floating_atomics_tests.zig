const std = @import("std");
const ir = @import("../../../ir.zig");
const machine = @import("../machine.zig");
const selector = @import("../generic_cfg_selector.zig");
const forms = @import("floating_atomics.zig");
const encoding = @import("../../../mc/encoding.zig");

test "floating atomic loops preserve returned bits neighboring bytes and live integers" {
    inline for (.{ f32, f64 }) |F| for ([_][]const u8{ "fadd", "fsub", "fmax", "fmin" }, 0..) |op, op_index| {
        const bits = @bitSizeOf(F);
        const U = if (bits == 32) u32 else u64;
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        const a = arena.allocator();
        const input = if (bits == 32) " %low = trunc i64 %input to i32\n %value = bitcast i32 %low to float\n" else " %value = bitcast i64 %input to double\n";
        const output = if (bits == 32) " %old_bits = bitcast float %old to i32\n %wide = zext i32 %old_bits to i64\n" else " %wide = bitcast double %old to i64\n";
        const text = try std.fmt.allocPrint(a, "define i64 @probe(ptr %p, i64 %input, ptr %out, i64 %salt) {{\nentry:\n{s} %old = atomicrmw volatile {s} ptr %p, {s} %value seq_cst, align {d}\n{s} store i64 %wide, ptr %out\n %next = getelementptr i8, ptr %out, i64 8\n %live = xor i64 %input, %salt\n store i64 %live, ptr %next\n ret i64 %wide\n}}\n", .{ input, op, if (bits == 32) "float" else "double", bits / 8, output });
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        try module.verify();
        var output_machine = machine.MachineFunction.init("probe", .{ .int = 64 });
        defer output_machine.deinit(std.testing.allocator);
        const selected = try selector.tryLower(std.testing.allocator, &output_machine, module.functions.items[0]);
        if (selected == .unsupported) std.debug.print("floating atomic {s}/{d}: {s}\n", .{ op, bits, selected.unsupported.detail() });
        try std.testing.expectEqual(selector.SelectionResult.selected, selected);
        try @import("../verify.zig").verifyFunction(output_machine);
        const code = try encoding.encodeFunction(std.testing.allocator, output_machine);
        defer std.testing.allocator.free(code);
        const memory = try std.posix.mmap(null, code.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
        defer std.posix.munmap(memory);
        @memcpy(memory[0..code.len], code);
        const run: *const fn (*u64, u64, *[2]u64, u64) callconv(.c) u64 = @ptrCast(memory.ptr);
        const samples = [_]F{ 0.0, -0.0, 1.5, -3.25, std.math.inf(F), -std.math.inf(F), std.math.nan(F) };
        const mask: u64 = std.math.maxInt(U);
        for (samples) |lhs| for (samples) |rhs| {
            const lhs_bits: U = @bitCast(lhs);
            const rhs_bits: U = @bitCast(rhs);
            var cells = [_]u64{ 0x1234_5678_9abc_def0, @as(u64, lhs_bits) | (0xa5a5_a5a5_a5a5_a5a5 & ~mask), 0xfedc_ba98_7654_3210 };
            var out: [2]u64 = @splat(0);
            try std.testing.expectEqual(@as(u64, lhs_bits), run(&cells[1], rhs_bits, &out, 0x7349));
            try std.testing.expectEqual(@as(u64, lhs_bits), out[0]);
            try std.testing.expectEqual(@as(u64, rhs_bits) ^ 0x7349, out[1]);
            try std.testing.expectEqual(@as(u64, 0x1234_5678_9abc_def0), cells[0]);
            try std.testing.expectEqual(@as(u64, 0xfedc_ba98_7654_3210), cells[2]);
            try std.testing.expectEqual(0xa5a5_a5a5_a5a5_a5a5 & ~mask, cells[1] & ~mask);
            const actual: F = @bitCast(@as(U, @truncate(cells[1])));
            const expected: F = switch (op_index) { 0 => lhs + rhs, 1 => lhs - rhs, 2 => @max(lhs, rhs), 3 => @min(lhs, rhs), else => unreachable };
            if (std.math.isNan(expected)) {
                try std.testing.expect(std.math.isNan(actual));
            } else {
                try std.testing.expectEqual(expected, actual);
            }
        };
        try module.verify();
    };
}

test "floating atomic block splitting clones source PHIs and retains closed forms" {
    var module = try ir.Module.parse(std.testing.allocator,
        \\define i32 @probe(ptr %p, i1 zeroext %again) {
        \\entry:
        \\ br label %body
        \\body:
        \\ %count = phi i32 [ 0, %entry ], [ %next, %body ]
        \\ %old = atomicrmw fmin ptr %p, float 2.000000e+00 acq_rel, align 4
        \\ %next = add i32 %count, 1
        \\ br i1 %again, label %body, label %exit
        \\exit:
        \\ %answer = phi i32 [ %next, %body ]
        \\ ret i32 %answer
        \\}
    );
    defer module.deinit();
    try module.verify();
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const source = module.functions.items[0];
    const rewritten = (try forms.legalize(arena.allocator(), source)).?;
    var private_module = module;
    private_module.functions = try module.functions.clone(arena.allocator());
    private_module.functions.items[0] = rewritten;
    try private_module.verify();
    try std.testing.expectEqualStrings("body", source.blocks.items[1].instructions.items[0].kind.phi.incoming.items[1].block);
    try module.verify();
    source.blocks.items[1].instructions.items[1].kind.atomicrmw.@"align" = 2;
    try std.testing.expect(try forms.legalize(arena.allocator(), source) == null);
}
