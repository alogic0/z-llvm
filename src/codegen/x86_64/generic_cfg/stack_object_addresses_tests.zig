const std = @import("std");
const ir = @import("../../../ir.zig");
const machine = @import("../machine.zig");
const selector = @import("../generic_cfg_selector.zig");
const verify = @import("../verify.zig");
const encoding = @import("../../../mc/encoding.zig");
const support = @import("value_use/test_support.zig");

fn executable(source: []const u8) ![]align(std.heap.page_size_min) u8 {
    var module = try ir.Module.parse(std.testing.allocator, source);
    defer module.deinit();
    try module.verify();
    const function = module.functions.items[0];
    var output = machine.MachineFunction.init(function.name, function.ret_ty);
    defer output.deinit(std.testing.allocator);
    const selected = try selector.tryLower(std.testing.allocator, &output, function);
    if (selected == .unsupported) std.debug.print("stack object {s}: {s}\n", .{ function.name, selected.unsupported.detail() });
    try std.testing.expectEqual(selector.SelectionResult.selected, selected);
    try verify.verifyFunction(output);
    try std.testing.expect(output.selection_owner == .composed_block or output.selection_owner == .composed_cfg);
    const bytes = try encoding.encodeFunction(std.testing.allocator, output);
    defer std.testing.allocator.free(bytes);
    const code = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    @memcpy(code[0..bytes.len], bytes);
    return code;
}

test "stack object pointer PHIs choose local arrays and external storage on both edges" {
    for ([_][]const u8{ "i64", "i128", "[3 x i32]", "[16 x i32]" }) |ty| {
        const source = try std.fmt.allocPrint(std.testing.allocator,
            \\define i64 @choose(ptr %external, i64 %value, i1 %take_local, i64 %seed) {{
            \\entry:
            \\ %slot = alloca {s}, align 8
            \\ store i64 %value, ptr %slot, align 8
            \\ br i1 %take_local, label %local, label %outside
            \\local:
            \\ br label %join
            \\outside:
            \\ br label %join
            \\join:
            \\ %p = phi ptr [ %slot, %local ], [ %external, %outside ]
            \\ %read = load i64, ptr %p, align 8
            \\ %result = xor i64 %read, %seed
            \\ ret i64 %result
            \\}}
        , .{ty});
        defer std.testing.allocator.free(source);
        const code = try executable(source);
        defer std.posix.munmap(code);
        const run: *const fn (*const u64, u64, bool, u64) callconv(.c) u64 = @ptrCast(code.ptr);
        for ([_]u64{ 0, 0x0123456789abcdef, 0xfedcba9876543210, std.math.maxInt(u64) }) |value| {
            const external = value ^ 0x8000000000000001;
            const seed: u64 = 0xa55aa55a12345678;
            for ([_]bool{ false, true }) |take_local| {
                try std.testing.expectEqual((if (take_local) value else external) ^ seed, run(&external, value, take_local, seed));
                try std.testing.expectEqual(value ^ 0x8000000000000001, external);
            }
        }
    }
}

test "stack object scalar memcpy preserves exact lengths source and live values" {
    const code = try executable(
        \\declare void @llvm.memcpy.p0.p0.i64(ptr, ptr, i64, i1)
        \\define i64 @copy(ptr %out, i64 %value, i64 %length, i64 %seed) {
        \\entry:
        \\ %slot = alloca i64, align 8
        \\ store i64 %value, ptr %slot, align 8
        \\ call void @llvm.memcpy.p0.p0.i64(ptr %out, ptr %slot, i64 %length, i1 false)
        \\ %read = load i64, ptr %slot, align 8
        \\ %result = xor i64 %read, %seed
        \\ ret i64 %result
        \\}
    );
    defer std.posix.munmap(code);
    const run: *const fn (*u8, u64, u64, u64) callconv(.c) u64 = @ptrCast(code.ptr);
    for ([_]u64{ 0, 0x0123456789abcdef, 0xfedcba9876543210, std.math.maxInt(u64) }) |value| {
        for ([_]u64{ 0, 0xa55aa55a12345678, std.math.maxInt(u64) }) |seed| {
            for (0..9) |len| {
                var destination: [24]u8 = @splat(0x93);
                var expected = destination;
                @memcpy(expected[5 .. 5 + len], std.mem.asBytes(&value)[0..len]);
                try std.testing.expectEqual(value ^ seed, run(&destination[5], value, len, seed));
                try std.testing.expectEqualSlices(u8, &expected, &destination);
            }
        }
    }
}

test "stack object copies roundtrip every scalar width and local destination" {
    for ([_]u16{ 8, 16, 32, 64 }) |bits| {
        const narrow = if (bits == 64) try std.testing.allocator.dupe(u8, "freeze i64 %value") else try std.fmt.allocPrint(std.testing.allocator, "trunc i64 %value to i{d}", .{bits});
        defer std.testing.allocator.free(narrow);
        const wide = if (bits == 64) try std.testing.allocator.dupe(u8, "freeze i64 %read") else try std.fmt.allocPrint(std.testing.allocator, "zext i{d} %read to i64", .{bits});
        defer std.testing.allocator.free(wide);
        const source = try std.fmt.allocPrint(std.testing.allocator,
            \\declare void @llvm.memcpy.p0.p0.i64(ptr, ptr, i64, i1)
            \\define i64 @copy(ptr %out, i64 %value, i64 %seed) {{
            \\entry:
            \\ %src = alloca i{0d}, align {1d}
            \\ %dst = alloca i{0d}, align {1d}
            \\ %narrow = {2s}
            \\ store i{0d} %narrow, ptr %src, align {1d}
            \\ call void @llvm.memcpy.p0.p0.i64(ptr %dst, ptr %src, i64 {1d}, i1 false)
            \\ call void @llvm.memcpy.p0.p0.i64(ptr %out, ptr %dst, i64 {1d}, i1 false)
            \\ %read = load i{0d}, ptr %src, align {1d}
            \\ %wide = {3s}
            \\ %result = xor i64 %wide, %seed
            \\ ret i64 %result
            \\}}
        , .{ bits, bits / 8, narrow, wide });
        defer std.testing.allocator.free(source);
        const code = try executable(source);
        defer std.posix.munmap(code);
        const run: *const fn (*u8, u64, u64) callconv(.c) u64 = @ptrCast(code.ptr);
        for ([_]u64{ 0, 0x0123456789abcdef, 0xfedcba9876543210, std.math.maxInt(u64) }) |value| {
            const mask = @as(u64, std.math.maxInt(u64)) >> @as(u6, @intCast(64 - bits));
            const seed: u64 = 0xa55aa55a12345678;
            var destination: [24]u8 = @splat(0x93);
            var expected = destination;
            @memcpy(expected[5 .. 5 + bits / 8], std.mem.asBytes(&value)[0 .. bits / 8]);
            try std.testing.expectEqual((value & mask) ^ seed, run(&destination[5], value, seed));
            try std.testing.expectEqualSlices(u8, &expected, &destination);
        }
    }
}

test "stack object pointer PHIs select frame addresses across a swapping loop" {
    const code = try executable(
        \\define i64 @choose(i64 %a, i64 %b, i32 %count, i64 %seed) {
        \\entry:
        \\ %first = alloca [2 x i32], align 8
        \\ %second = alloca i64, align 8
        \\ store i64 %a, ptr %first, align 8
        \\ store i64 %b, ptr %second, align 8
        \\ br label %loop
        \\loop:
        \\ %p = phi ptr [ %first, %entry ], [ %q, %loop ]
        \\ %q = phi ptr [ %second, %entry ], [ %p, %loop ]
        \\ %n = phi i32 [ 0, %entry ], [ %next, %loop ]
        \\ %next = add i32 %n, 1
        \\ %more = icmp ult i32 %n, %count
        \\ br i1 %more, label %loop, label %exit
        \\exit:
        \\ %x = load i64, ptr %p, align 8
        \\ %y = load i64, ptr %q, align 8
        \\ %difference = sub i64 %x, %y
        \\ %result = xor i64 %difference, %seed
        \\ ret i64 %result
        \\}
    );
    defer std.posix.munmap(code);
    const run: *const fn (u64, u64, u32, u64) callconv(.c) u64 = @ptrCast(code.ptr);
    for ([_]u64{ 0, 0x0123456789abcdef, 0xfedcba9876543210, std.math.maxInt(u64) }) |a| {
        for ([_]u64{ 0, 0x8000000000000001, std.math.maxInt(u64) }) |b| {
            for (0..19) |count| {
                const seed: u64 = 0xa55aa55a12345678;
                const difference = if (count % 2 == 0) a -% b else b -% a;
                const actual = run(a, b, @intCast(count), seed);
                if (actual != difference ^ seed) std.debug.print("a={x} b={x} count={d} expected={x} actual={x}\n", .{ a, b, count, difference ^ seed, actual });
                try std.testing.expectEqual(difference ^ seed, actual);
            }
        }
    }
}

test "stack object byte offsets copy exact suffixes and preserve live inputs" {
    const code = try executable(
        \\declare void @llvm.memcpy.p0.p0.i64(ptr, ptr, i64, i1)
        \\define i64 @window(ptr %out, i64 %value, i64 %length, i64 %offset, i64 %seed) {
        \\entry:
        \\ %slot = alloca i64, align 8
        \\ store i64 %value, ptr %slot, align 8
        \\ %start = getelementptr inbounds [1 x i8], ptr %slot, i64 %offset
        \\ call void @llvm.memcpy.p0.p0.i64(ptr %out, ptr %start, i64 %length, i1 false)
        \\ %read = load i64, ptr %slot, align 8
        \\ %result = xor i64 %read, %seed
        \\ ret i64 %result
        \\}
    );
    defer std.posix.munmap(code);
    const run: *const fn (*u8, u64, u64, u64, u64) callconv(.c) u64 = @ptrCast(code.ptr);
    for ([_]u64{ 0, 0x0123456789abcdef, 0xfedcba9876543210, std.math.maxInt(u64) }) |value| {
        for (0..9) |offset| for (0..9 - offset) |length| {
            const seed: u64 = 0xa55aa55a12345678;
            var destination: [24]u8 = @splat(0x93);
            var expected = destination;
            @memcpy(expected[5 .. 5 + length], std.mem.asBytes(&value)[offset .. offset + length]);
            try std.testing.expectEqual(value ^ seed, run(&destination[5], value, length, offset, seed));
            try std.testing.expectEqualSlices(u8, &expected, &destination);
        };
    }
}

test "stack object copy destination preserves a pending source in the address scratch register" {
    const code = try executable(
        \\declare void @llvm.memcpy.p0.p0.i64(ptr, ptr, i64, i1)
        \\define i64 @copy_input(ptr %input, i64 %seed) {
        \\entry:
        \\ %slot = alloca [16 x i32], align 16
        \\ call void @llvm.memcpy.p0.p0.i64(ptr %slot, ptr %input, i64 64, i1 false)
        \\ %start = getelementptr i8, ptr %slot, i64 0
        \\ %end = getelementptr i8, ptr %slot, i64 56
        \\ %first = load i64, ptr %start, align 8
        \\ %last = load i64, ptr %end, align 8
        \\ %sum = add i64 %first, %last
        \\ %r = xor i64 %sum, %seed
        \\ ret i64 %r
        \\}
    );
    defer std.posix.munmap(code);
    const run: *const fn (*const [8]u64, u64) callconv(.c) u64 = @ptrCast(code.ptr);
    for ([_]u64{ 0, 0x0123456789abcdef, 0xfedcba9876543210, std.math.maxInt(u64) }) |value| {
        var input: [8]u64 = @splat(value);
        input[7] = value ^ 0x8000000000000001;
        const before = input;
        for ([_]u64{ 0, 1, std.math.maxInt(u64) }) |seed| {
            try std.testing.expectEqual((input[0] +% input[7]) ^ seed, run(&input, seed));
            try std.testing.expectEqualSlices(u64, &before, &input);
        }
    }
}

test "stack object copy transactions restore every boundary and live alias" {
    const homes = [_]support.ValueLoc{
        .{ .stack_scalar = .{ .base_disp = 32, .bits = 8, .kind = .integer } },
        .{ .stack_scalar = .{ .base_disp = 32, .bits = 64, .kind = .fp } },
        .{ .stack128 = 32 },
        .{ .stack_i32_array = .{ .base_disp = 32, .len = 4 } },
    };
    for (homes) |home| for (std.meta.tags(support.Transaction.MemcpyTestFailure)) |failure| {
        var output = support.MachineFunction.init("stack-object-rollback", .void);
        defer output.deinit(std.testing.allocator);
        var plan = support.SelectorAllocationPlan.init(std.testing.allocator);
        defer plan.deinit();
        inline for (&.{ "slot", "out", "length" }) |name| try support.addAtCurrent(&plan, name);
        try support.addLive(&plan, "live");
        var state = support.ComposedBlockSelector.init(std.testing.allocator, &output);
        defer state.deinit();
        state.allocation_plan = &plan;
        state.stack_frame_bytes = 128;
        try support.selector_state.bindValueLoc(&state, "slot", home);
        try support.selector_state.bindValueLoc(&state, "out", .{ .arg64 = .rdi });
        try support.selector_state.bindValueLoc(&state, "length", .{ .arg64 = .rdx });
        try support.selector_state.bindValueLoc(&state, "live", .{ .arg64 = .rcx });
        const live = state.values.get("live").?;
        const slot = state.values.get("slot").?;
        const next_vreg = state.next_virtual_reg;
        const next_spill = state.next_spill_slot;
        const flags = state.eflags.snapshot();
        const addresses = state.address_dependencies;
        var transaction = try support.Transaction.begin(&state);
        defer transaction.deinit();
        const action = try support.registerMemcpyAction(&transaction, .{ .named = "out" }, .{ .named = "slot" }, .{ .named = "length" });
        try transaction.setMemcpyTestFailure(failure);
        try transaction.seal();
        try transaction.prepare();
        try transaction.materializeAll();
        try std.testing.expectError(error.ValueUseMemcpyTestFailure, transaction.executePreparedAction(try transaction.preparedView(action)));
        try std.testing.expectEqual(@as(usize, 0), output.instructions.items.len);
        try std.testing.expectEqual(live, state.values.get("live").?);
        try std.testing.expectEqual(slot, state.values.get("slot").?);
        try std.testing.expectEqual(next_vreg, state.next_virtual_reg);
        try std.testing.expectEqual(next_spill, state.next_spill_slot);
        try std.testing.expectEqual(@as(usize, 0), state.spill_slots.count());
        try std.testing.expect(state.address_dependencies.eql(&addresses));
        try state.eflags.validateSnapshot(flags);
    };
}

test "stack object copy admission preserves integer length memset and address-space boundaries" {
    for (0..4) |case| {
        var output = support.MachineFunction.init("stack-object-rejection", .void);
        defer output.deinit(std.testing.allocator);
        var plan = support.SelectorAllocationPlan.init(std.testing.allocator);
        defer plan.deinit();
        try support.addAtCurrent(&plan, "slot");
        var state = support.ComposedBlockSelector.init(std.testing.allocator, &output);
        defer state.deinit();
        state.allocation_plan = &plan;
        state.stack_frame_bytes = 128;
        try support.selector_state.bindValueLoc(&state, "slot", .{ .stack_scalar = .{ .base_disp = 32, .bits = 64, .kind = .integer } });
        if (case == 3) state.values.getPtr("slot").?.vreg.bits = 64;
        const saved = state.values.get("slot").?;
        var transaction = try support.Transaction.begin(&state);
        defer transaction.deinit();
        var request = support.preparedSourceRequest("slot", .ptr, .gpr64, .memcpy_pointer);
        const expected_error = switch (case) {
            0 => blk: {
                request.expected = support.expected(.{ .int = 64 }, .gpr64);
                request.form = .memcpy_length;
                break :blk error.ValueUseMemcpyLengthWidthMismatch;
            },
            1 => blk: {
                request.destination = .prepared_view;
                request.prepared_action = .{ .inline_memset = .{ .length_immediate = 4 } };
                break :blk error.ValueUseMemcpyPointerWidthMismatch;
            },
            2 => blk: {
                request.expected.pointer_address_space = 1;
                break :blk error.ValueUseTypeMismatch;
            },
            else => error.ValueUseMemcpyPointerHomeUnsupported,
        };
        _ = try transaction.register(request);
        try std.testing.expectError(expected_error, transaction.seal());
        try std.testing.expectEqual(@as(usize, 0), output.instructions.items.len);
        try std.testing.expectEqual(saved, state.values.get("slot").?);
    }
}

test "stack object addresses reject invalid frame extents before preserving live registers" {
    const invalid = [_]support.ValueLoc{
        .{ .stack_scalar = .{ .base_disp = 125, .bits = 64, .kind = .integer } },
        .{ .stack128 = 113 },
        .{ .stack_i32_array = .{ .base_disp = 128, .len = 1 } },
        .{ .stack_i32_array = .{ .base_disp = 0, .len = std.math.maxInt(u32) } },
    };
    for (invalid) |home| {
        var output = support.MachineFunction.init("stack-object-frame-rejection", .void);
        defer output.deinit(std.testing.allocator);
        var plan = support.SelectorAllocationPlan.init(std.testing.allocator);
        defer plan.deinit();
        try support.addLive(&plan, "live");
        var state = support.ComposedBlockSelector.init(std.testing.allocator, &output);
        defer state.deinit();
        state.allocation_plan = &plan;
        state.stack_frame_bytes = 128;
        try support.selector_state.bindValueLoc(&state, "live", .{ .arg64 = .rcx });
        const saved = state.values.get("live").?;
        try std.testing.expectError(error.UnsupportedCodegenValue, support.selector_state.materializeLocIntoLocWithBits(&state, home, .{ .scratch64 = .rcx }, 64));
        try std.testing.expectEqual(saved, state.values.get("live").?);
        try std.testing.expectEqual(@as(usize, 0), output.instructions.items.len);
        try std.testing.expectEqual(@as(usize, 0), state.spill_slots.count());
    }
}
