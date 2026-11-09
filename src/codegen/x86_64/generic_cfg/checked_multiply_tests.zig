const std = @import("std");
const ir = @import("../../../ir.zig");
const machine = @import("../machine.zig");
const types = @import("../types.zig");
const selector = @import("../generic_cfg_selector.zig");
const state = @import("composed_selector_state.zig");
const planning = @import("stage2_planning.zig");
const verify = @import("../verify.zig");
const encoding = @import("../../../mc/encoding.zig");

fn executable(function: machine.MachineFunction) ![]align(std.heap.page_size_min) u8 {
    try verify.verifyFunction(function);
    const bytes = try encoding.encodeFunction(std.testing.allocator, function);
    defer std.testing.allocator.free(bytes);
    const code = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    @memcpy(code[0..bytes.len], bytes);
    return code;
}

test "checked multiply scratch literals preserve wide narrow and accumulator aliases and flags" {
    for ([_]u16{ 32, 64 }) |bits| for ([_]types.ArgReg{ .rdi, .rsi, .rdx, .rcx, .r8, .r9 }) |reg| {
        const literals = if (bits == 64) &[_]i128{ 0, 24, -1, std.math.minInt(i64), std.math.maxInt(u64) } else &[_]i128{ 0, 24, -1, std.math.minInt(i32), std.math.maxInt(u32) };
        for (literals) |literal| for (0..4) |observation| {
            var output = machine.MachineFunction.init("literal-aliases", .{ .int = 64 });
            defer output.deinit(std.testing.allocator);
            var plan = planning.SelectorAllocationPlan.init(std.testing.allocator);
            defer plan.deinit();
            for ([_][]const u8{ "wide", "narrow", "accumulator" }) |name| try plan.interval_ends.put(name, 3);
            var current = state.ComposedBlockSelector.init(std.testing.allocator, &output);
            defer current.deinit();
            current.allocation_plan = &plan;
            current.stack_frame_bytes = 136;
            try output.instructions.appendSlice(std.testing.allocator, &.{ .{ .sub_rsp_imm32 = 136 }, .{ .mov_arg_rax = .rdi } });
            if (reg != .rdi) try output.instructions.append(std.testing.allocator, .{ .mov_arg64_arg = .{ .dst = reg, .src = .rdi } });
            try state.bindValueLoc(&current, "wide", .{ .arg64 = reg });
            try state.bindValueLoc(&current, "narrow", .{ .arg32 = reg });
            try state.bindValueLoc(&current, "accumulator", .rax);
            try current.eflags.apply(.definition);
            const flags = current.eflags.snapshot();
            try state.emitValueIntoScratch(&current, .{ .int = literal }, reg, bits);
            try std.testing.expectEqual(flags, current.eflags.snapshot());
            switch (observation) {
                0 => try output.instructions.append(std.testing.allocator, .{ .mov_arg_rax = reg }),
                1 => try state.emitValueIntoAccumulator(&current, .{ .named = "wide" }, 64),
                2 => try state.emitValueIntoAccumulator(&current, .{ .named = "narrow" }, 32),
                3 => try state.emitValueIntoAccumulator(&current, .{ .named = "accumulator" }, 64),
                else => unreachable,
            }
            try output.instructions.appendSlice(std.testing.allocator, &.{ .{ .add_rsp_imm32 = 136 }, .ret });
            const code = try executable(output);
            defer std.posix.munmap(code);
            const run: *const fn (u64) callconv(.c) u64 = @ptrCast(code.ptr);
            for ([_]u64{ 0, 0xfedcba9876543210, std.math.maxInt(u64) }) |input| {
                const expected: u64 = if (observation == 0) @as(u64, @truncate(@as(u128, @bitCast(literal)))) & (if (bits == 32) @as(u64, 0xffffffff) else std.math.maxInt(u64)) else if (observation == 2) input & 0xffffffff else input;
                try std.testing.expectEqual(expected, run(input));
            }
        };
    };
}

test "checked multiply scratch literals reject invalid widths and ranges before preservation" {
    const cases = [_]struct { bits: u16, literal: i128 }{
        .{ .bits = 64, .literal = @as(i128, std.math.minInt(i64)) - 1 },
        .{ .bits = 64, .literal = @as(i128, std.math.maxInt(u64)) + 1 },
        .{ .bits = 32, .literal = @as(i128, std.math.minInt(i32)) - 1 },
        .{ .bits = 32, .literal = @as(i128, std.math.maxInt(u32)) + 1 },
        .{ .bits = 0, .literal = 1 },
        .{ .bits = 16, .literal = 1 },
        .{ .bits = 128, .literal = 1 },
    };
    for (cases) |case| {
        var output = machine.MachineFunction.init("invalid-literal", .{ .int = 64 });
        defer output.deinit(std.testing.allocator);
        var current = state.ComposedBlockSelector.init(std.testing.allocator, &output);
        defer current.deinit();
        try state.bindValueLoc(&current, "live", .{ .arg64 = .rcx });
        const binding = current.values.get("live").?;
        try std.testing.expectError(error.UnsupportedCodegenValue, state.emitValueIntoScratch(&current, .{ .int = case.literal }, .rcx, case.bits));
        try std.testing.expectEqual(binding, current.values.get("live").?);
        try std.testing.expectEqual(@as(usize, 0), output.instructions.items.len);
        try std.testing.expectEqual(@as(usize, 0), current.next_spill_slot);
    }
}

test "checked multiply literals execute attributed selected operands with live inputs" {
    for ([_]bool{ false, true }) |signed| for ([_]i128{ 0, 1, 12, 24, 40, 120, -1, std.math.minInt(i64), std.math.maxInt(u64) }) |literal| {
        const text = try std.fmt.allocPrint(
            std.testing.allocator,
            "declare {{ i64, i1 }} @llvm.{s}mul.with.overflow.i64(i64, i64)\n" ++
                "define i64 @product(i64 %a, i64 %b, i64 %c, i64 %d, i64 %e, ptr %out) {{\nentry:\n" ++
                " %cond = icmp ult i64 %a, %b\n %chosen = select i1 %cond, i64 %a, i64 %b\n" ++
                " %alias = trunc i64 %c to i32\n" ++
                " %pair = tail call {{ i64, i1 }} @llvm.{s}mul.with.overflow.i64(i64 noundef %chosen, i64 {d})\n" ++
                " %flag = extractvalue {{ i64, i1 }} %pair, 1\n %value = extractvalue {{ i64, i1 }} %pair, 0\n" ++
                " store i64 %value, ptr %out, align 8\n %next = getelementptr i8, ptr %out, i64 8\n" ++
                " %ab = xor i64 %a, %b\n %cd = xor i64 %c, %d\n %abcd = xor i64 %ab, %cd\n" ++
                " %all = xor i64 %abcd, %e\n %alias64 = zext i32 %alias to i64\n %live = xor i64 %all, %alias64\n" ++
                " store i64 %live, ptr %next, align 8\n %result = zext i1 %flag to i64\n ret i64 %result\n}}\n",
            .{ if (signed) "s" else "u", if (signed) "s" else "u", literal },
        );
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        try module.verify();
        for (0..2) |_| {
            var output = machine.MachineFunction.init("product", .{ .int = 64 });
            defer output.deinit(std.testing.allocator);
            try std.testing.expectEqual(selector.SelectionResult.selected, try selector.tryLower(std.testing.allocator, &output, module.functions.items[0]));
            const code = try executable(output);
            defer std.posix.munmap(code);
            const run: *const fn (u64, u64, u64, u64, u64, *u64) callconv(.c) u64 = @ptrCast(code.ptr);
            const values = [_]u64{ 0, 1, 2, 0xffffffff, 0x100000000, 0x7fffffffffffffff, 0x8000000000000000, std.math.maxInt(u64) };
            for (values, 0..) |a, i| for (values) |b| {
                const c = values[(i + 3) % values.len];
                const d = values[(i + 4) % values.len];
                const e = values[(i + 5) % values.len];
                const chosen = @min(a, b);
                const rhs: u64 = @truncate(@as(u128, @bitCast(literal)));
                const product: u128 = @as(u128, chosen) * rhs;
                const signed_product: i128 = @as(i128, @as(i64, @bitCast(chosen))) * @as(i64, @bitCast(rhs));
                const overflow = if (signed) signed_product < std.math.minInt(i64) or signed_product > std.math.maxInt(i64) else product > std.math.maxInt(u64);
                var out = [_]u64{ 0x123456789abcdef0, 0, 0, 0xfedcba9876543210 };
                try std.testing.expectEqual(@as(u64, @intFromBool(overflow)), run(a, b, c, d, e, &out[1]));
                try std.testing.expectEqual(@as(u64, @truncate(product)), out[1]);
                try std.testing.expectEqual(a ^ b ^ c ^ d ^ e ^ (c & 0xffffffff), out[2]);
                try std.testing.expectEqual(@as(u64, 0x123456789abcdef0), out[0]);
                try std.testing.expectEqual(@as(u64, 0xfedcba9876543210), out[3]);
            };
        }
        const call = module.functions.items[0].blocks.items[0].instructions.items[3].kind.call;
        try std.testing.expectEqualStrings("noundef", call.args.items[0].attrs.?);
        try std.testing.expectEqual(literal, call.args.items[1].value.int);
    };
}

test "checked multiply late rejection rolls back speculative emission and labels" {
    const text =
        \\declare { i64, i1 } @llvm.umul.with.overflow.i64(i64, i64)
        \\declare void @llvm.unimplemented.multiply.test()
        \\define i64 @rejected(i64 %input) {
        \\entry:
        \\ %pair = call { i64, i1 } @llvm.umul.with.overflow.i64(i64 noundef %input, i64 24)
        \\ %value = extractvalue { i64, i1 } %pair, 0
        \\ call void @llvm.unimplemented.multiply.test()
        \\ ret i64 %value
        \\}
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();
    try module.verify();
    var output = machine.MachineFunction.init("original-name", .{ .int = 64 });
    defer output.deinit(std.testing.allocator);
    try output.instructions.append(std.testing.allocator, .{ .mov_imm_rax = 91 });
    for (0..2) |_| {
        const result = try selector.tryLower(std.testing.allocator, &output, module.functions.items[0]);
        try std.testing.expect(result == .unsupported);
        try std.testing.expectEqualStrings("composed-block-llvm-intrinsic", result.unsupported.detail());
        try std.testing.expectEqualSlices(machine.Instruction, &.{.{ .mov_imm_rax = 91 }}, output.instructions.items);
        try std.testing.expectEqual(@as(usize, 0), output.owned_labels.items.len);
        try std.testing.expectEqual(machine.SelectionOwner.unassigned, output.selection_owner);
        try std.testing.expectEqualStrings("original-name", output.name);
    }
}
