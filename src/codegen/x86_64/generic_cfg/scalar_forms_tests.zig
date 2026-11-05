const std = @import("std");
const ir = @import("../../../ir.zig");
const machine = @import("../machine.zig");
const selector = @import("../generic_cfg_selector.zig");
const verify = @import("../verify.zig");
const encoding = @import("../../../mc/encoding.zig");
const forms = @import("scalar_forms.zig");
const edges = @import("switch_phi_edges.zig");

fn executable(module: ir.Module) ![]align(std.heap.page_size_min) u8 {
    const function = module.functions.items[0];
    var output = machine.MachineFunction.init(function.name, function.ret_ty);
    defer output.deinit(std.testing.allocator);
    const selected = try selector.tryLower(std.testing.allocator, &output, function);
    if (selected == .unsupported) std.debug.print("scalar forms {s}: {s}\n", .{ function.name, selected.unsupported.detail() });
    try std.testing.expectEqual(selector.SelectionResult.selected, selected);
    try verify.verifyFunction(output);
    const code = try encoding.encodeFunction(std.testing.allocator, output);
    defer std.testing.allocator.free(code);
    const memory = try std.posix.mmap(null, code.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    @memcpy(memory[0..code.len], code);
    return memory;
}

test "scalar forms unsigned minimum preserves full width and live operands" {
    const text =
        \\declare i64 @llvm.umin.i64(i64, i64)
        \\define i64 @minimum(i64 %a, i64 %b, ptr %output) {
        \\entry:
        \\  %value = call i64 @llvm.umin.i64(i64 %a, i64 %b)
        \\  store i64 %value, ptr %output
        \\  %live = xor i64 %a, %b
        \\  ret i64 %live
        \\}
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();
    try module.verify();
    const code = try executable(module);
    defer std.posix.munmap(code);
    const run: *const fn (u64, u64, *u64) callconv(.c) u64 = @ptrCast(code.ptr);
    const inputs = [_]u64{ 0, 1, 65535, 65536, 0x7fffffffffffffff, 0x8000000000000000, 0xdeadbeefcafe0123, std.math.maxInt(u64) };
    for (inputs) |a| for (inputs) |b| {
        var out: u64 = 0;
        try std.testing.expectEqual(a ^ b, run(a, b, &out));
        try std.testing.expectEqual(@min(a, b), out);
    };
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const view = (try forms.legalize(arena.allocator(), module.functions.items[0])).?;
    try std.testing.expect(try forms.legalize(arena.allocator(), view) == null);
    try std.testing.expect(module.functions.items[0].blocks.items[0].instructions.items[0].kind == .call);
    try module.verify();
}

test "scalar forms signed less equal compares extrema and immediate boundaries" {
    for ([_]u16{ 32, 64 }) |bits| {
        const text = try std.fmt.allocPrint(std.testing.allocator, "define i32 @less_equal(i{d} %x) {{\nentry:\n  %c = icmp sle i{d} %x, 65535\n  %r = zext i1 %c to i32\n  ret i32 %r\n}}\n", .{ bits, bits });
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        try module.verify();
        const code = try executable(module);
        defer std.posix.munmap(code);
        const inputs = [_]i64{ std.math.minInt(i64), std.math.minInt(i32), -1, 0, 65534, 65535, 65536, std.math.maxInt(i32), std.math.maxInt(i64) };
        for (inputs) |x| {
            if (bits == 32) {
                const run: *const fn (i32) callconv(.c) u32 = @ptrCast(code.ptr);
                const narrow: i32 = @truncate(x);
                try std.testing.expectEqual(@as(u32, @intFromBool(narrow <= 65535)), run(narrow));
            } else {
                const run: *const fn (i64) callconv(.c) u32 = @ptrCast(code.ptr);
                try std.testing.expectEqual(@as(u32, @intFromBool(x <= 65535)), run(x));
            }
        }
    }
}

test "scalar forms switch edges preserve duplicate PHI edges and original block identities" {
    const text =
        \\define i32 @edges(i32 %__zllvm_scalar_form_0) {
        \\__zllvm_scalar_form_1:
        \\  switch i32 %__zllvm_scalar_form_0, label %merge [
        \\    i32 0, label %merge
        \\    i32 1, label %one
        \\    i32 2, label %merge
        \\  ]
        \\one:
        \\  %value = add i32 %__zllvm_scalar_form_0, 7
        \\  br label %merge
        \\merge:
        \\  %result = phi i32 [ 55, %__zllvm_scalar_form_1 ], [ 55, %__zllvm_scalar_form_1 ], [ 55, %__zllvm_scalar_form_1 ], [ %value, %one ]
        \\  ret i32 %result
        \\}
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();
    try module.verify();
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const view = (try edges.legalize(arena.allocator(), module.functions.items[0])).?;
    try std.testing.expectEqual(@as(usize, 4), view.blocks.items.len);
    try std.testing.expectEqualStrings("__zllvm_scalar_form_2", view.blocks.items[3].name);
    try std.testing.expectEqual(@as(usize, 2), view.blocks.items[2].instructions.items[0].kind.phi.incoming.items.len);
    try std.testing.expect(try edges.legalize(arena.allocator(), view) == null);
    var private_module = module;
    private_module.functions = try module.functions.clone(arena.allocator());
    private_module.functions.items[0] = view;
    try private_module.verify();
    const code = try executable(module);
    defer std.posix.munmap(code);
    const run: *const fn (i32) callconv(.c) i32 = @ptrCast(code.ptr);
    for ([_]i32{ -1, 0, 1, 2, 3, std.math.minInt(i32), std.math.maxInt(i32) }) |x|
        try std.testing.expectEqual(@as(i32, if (x == 1) 8 else 55), run(x));
    try std.testing.expectEqual(@as(usize, 3), module.functions.items[0].blocks.items.len);
    try module.verify();
}

test "scalar forms reject unsupported intrinsic envelopes and mismatched duplicate PHI values" {
    const text =
        \\declare i64 @llvm.umin.i64(i64, i64)
        \\define i64 @minimum(i64 %a, i64 %b) {
        \\entry:
        \\  %value = call i64 @llvm.umin.i64(i64 %a, i64 %b)
        \\  ret i64 %value
        \\}
    ;
    for (0..6) |boundary| {
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        const function = &module.functions.items[0];
        const call = &function.blocks.items[0].instructions.items[0].kind.call;
        switch (boundary) {
            0 => call.calling_conv = "fastcc",
            1 => call.tail_kind = "musttail",
            2 => call.ret_attrs = "signext",
            3 => call.args.items[0].attrs = "inreg",
            4 => call.callee_function_ty = "i64 (i64, i64)",
            5 => call.operand_bundle = "[ \"deopt\"() ]",
            else => unreachable,
        }
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        try std.testing.expect(try forms.legalize(arena.allocator(), function.*) == null);
        try std.testing.expect(function.blocks.items[0].instructions.items[0].kind == .call);
    }
    const malformed =
        \\define i32 @bad(i32 %x) {
        \\entry:
        \\  switch i32 %x, label %merge [ i32 0, label %merge ]
        \\merge:
        \\  %r = phi i32 [ 1, %entry ], [ 2, %entry ]
        \\  ret i32 %r
        \\}
    ;
    var module = try ir.Module.parse(std.testing.allocator, malformed);
    defer module.deinit();
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    try std.testing.expect(try edges.legalize(arena.allocator(), module.functions.items[0]) == null);
    try std.testing.expectEqual(@as(usize, 2), module.functions.items[0].blocks.items.len);
}

test "scalar forms bounded stack memset retains unknown extent and volatile boundaries" {
    const text =
        \\declare void @llvm.memset.p0.i64(ptr, i8, i64, i1)
        \\define i64 @fill(i64 %length) {
        \\entry:
        \\  %slot = alloca i128, align 8
        \\  call void @llvm.memset.p0.i64(ptr align 8 %slot, i8 -91, i64 16, i1 false)
        \\  %address = getelementptr i8, ptr %slot, i64 0
        \\  %result = load i64, ptr %address, align 8
        \\  ret i64 %result
        \\}
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();
    try module.verify();
    const code = try executable(module);
    defer std.posix.munmap(code);
    const run: *const fn (u64) callconv(.c) u64 = @ptrCast(code.ptr);
    try std.testing.expectEqual(@as(u64, 0xa5a5a5a5a5a5a5a5), run(16));
    const original = module.functions.items[0].blocks.items[0].instructions.items[1].kind.call;
    for (0..5) |boundary| {
        const call = &module.functions.items[0].blocks.items[0].instructions.items[1].kind.call;
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        call.* = original;
        call.args = try original.args.clone(arena.allocator());
        defer call.* = original;
        switch (boundary) {
            0 => call.args.items[2].value = .{ .int = 17 },
            1 => call.args.items[2].value = .{ .named = "length" },
            2 => call.args.items[3].value = .{ .int = 1 },
            3 => call.args.items[1].value = .poison,
            4 => call.args.items[0].attrs = "align 8 addrspace(1)",
            else => unreachable,
        }
        var output = machine.MachineFunction.init("fill", .{ .int = 64 });
        defer output.deinit(std.testing.allocator);
        try std.testing.expect((try selector.tryLower(std.testing.allocator, &output, module.functions.items[0])) == .unsupported);
        try std.testing.expectEqual(@as(usize, 0), output.instructions.items.len);
        try std.testing.expectEqual(@as(usize, 0), output.owned_labels.items.len);
    }
}

test "safe scalar mask i31 zero extension preserves unsigned boundary and live accumulator inputs" {
    for ([_]u16{ 32, 64 }) |destination_bits| {
        const bridge = if (destination_bits == 32) "  %wide = zext i32 %extended to i64\n" else "";
        const result_name = if (destination_bits == 32) "wide" else "extended";
        const text = try std.fmt.allocPrint(std.testing.allocator, "define i64 @mask31(i64 %input, ptr %out) {{\nentry:\n" ++
            "  %live = xor i64 %input, 55\n  %narrow = trunc i64 %input to i31\n" ++
            "  %extended = zext i31 %narrow to i{d}\n{s}" ++
            "  store i64 %{s}, ptr %out, align 8\n  ret i64 %live\n}}\n", .{ destination_bits, bridge, result_name });
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        try module.verify();
        const code = try executable(module);
        defer std.posix.munmap(code);
        const run: *const fn (u64, *u64) callconv(.c) u64 = @ptrCast(code.ptr);
        for ([_]u64{ 0, 1, 0x7ffffffe, 0x7fffffff, 0x80000000, 0xffffffff, 0x8000000000000000, std.math.maxInt(u64) }) |input| {
            var output = [_]u64{ 0xa5a5a5a5a5a5a5a5, 0, 0xa5a5a5a5a5a5a5a5 };
            try std.testing.expectEqual(input ^ 55, run(input, &output[1]));
            try std.testing.expectEqual(input & 0x7fffffff, output[1]);
            try std.testing.expectEqual(@as(u64, 0xa5a5a5a5a5a5a5a5), output[0]);
            try std.testing.expectEqual(output[0], output[2]);
        }
    }
}

test "safe scalar overflow words preserve wrap flags and live values at unsigned boundaries" {
    const values = [_]u64{ 0, 1, 2, 0xffffffff, 0x7fffffffffffffff, 0x8000000000000000, 0xfffffffffffffffe, std.math.maxInt(u64) };
    for ([_][]const u8{ "uadd", "usub" }) |op| {
        for ([_][]const u8{ "%b", "-1", "9223372036854775808" }) |rhs| {
            const text = try std.fmt.allocPrint(std.testing.allocator, "declare {{ i64, i1 }} @llvm.{s}.with.overflow.i64(i64, i64)\n" ++
                "define i64 @overflow(i64 %a, i64 %b, ptr %out) {{\nentry:\n" ++
                "  %pair = call {{ i64, i1 }} @llvm.{s}.with.overflow.i64(i64 %a, i64 {s})\n" ++
                "  %flag = extractvalue {{ i64, i1 }} %pair, 1\n  %wrapped = extractvalue {{ i64, i1 }} %pair, 0\n" ++
                "  store i64 %wrapped, ptr %out, align 8\n  %second = getelementptr i8, ptr %out, i64 8\n" ++
                "  %live = xor i64 %a, %b\n  store i64 %live, ptr %second, align 8\n" ++
                "  %result = zext i1 %flag to i64\n  ret i64 %result\n}}\n", .{ op, op, rhs });
            defer std.testing.allocator.free(text);
            var module = try ir.Module.parse(std.testing.allocator, text);
            defer module.deinit();
            try module.verify();
            const code = try executable(module);
            defer std.posix.munmap(code);
            const run: *const fn (u64, u64, *u64) callconv(.c) u64 = @ptrCast(code.ptr);
            for (values) |a| for (values) |b| {
                const y: u64 = if (std.mem.eql(u8, rhs, "%b")) b else if (std.mem.eql(u8, rhs, "-1")) std.math.maxInt(u64) else 0x8000000000000000;
                const expected = if (std.mem.eql(u8, op, "uadd")) @addWithOverflow(a, y) else @subWithOverflow(a, y);
                var output = [_]u64{ 0xa5a5a5a5a5a5a5a5, 0, 0, 0xa5a5a5a5a5a5a5a5 };
                try std.testing.expectEqual(@as(u64, expected[1]), run(a, b, &output[1]));
                try std.testing.expectEqual(expected[0], output[1]);
                try std.testing.expectEqual(a ^ b, output[2]);
                try std.testing.expectEqual(@as(u64, 0xa5a5a5a5a5a5a5a5), output[0]);
                try std.testing.expectEqual(output[0], output[3]);
            };
            var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
            defer arena.deinit();
            const overflow = @import("overflow_values.zig");
            const view = (try overflow.legalize(arena.allocator(), module.functions.items[0])).?;
            try std.testing.expect(try overflow.legalize(arena.allocator(), view) == null);
            var private_module = module;
            private_module.functions = try module.functions.clone(arena.allocator());
            private_module.functions.items[0] = view;
            try private_module.verify();
            try std.testing.expect(module.functions.items[0].blocks.items[0].instructions.items[0].kind == .call);
            try module.verify();
        }
    }
}

test "safe scalar overflow rejects aggregate escapes and unsupported call envelopes" {
    const overflow = @import("overflow_values.zig");
    const text =
        \\declare { i64, i1 } @llvm.uadd.with.overflow.i64(i64, i64)
        \\define i64 @f(i64 %a, i64 %b) {
        \\entry:
        \\  %pair = call { i64, i1 } @llvm.uadd.with.overflow.i64(i64 %a, i64 %b)
        \\  %x = extractvalue { i64, i1 } %pair, 0
        \\  ret i64 %x
        \\}
    ;
    for (0..5) |boundary| {
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        const function = &module.functions.items[0];
        const call = &function.blocks.items[0].instructions.items[0].kind.call;
        switch (boundary) {
            0 => call.calling_conv = "fastcc",
            1 => call.tail_kind = "musttail",
            2 => call.operand_bundle = "[ \"deopt\"() ]",
            3 => call.args.items[0].attrs = "inreg",
            4 => function.blocks.items[0].instructions.items[1].kind = .{ .store = .{
                .ty = call.ret_ty,
                .value = .{ .named = "pair" },
                .ptr = .null_value,
            } },
            else => unreachable,
        }
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        try std.testing.expect(try overflow.legalize(arena.allocator(), function.*) == null);
        try std.testing.expect(function.blocks.items[0].instructions.items[0].kind == .call);
    }
}

test "safe scalar unreachable preserves preceding calls and terminates with a trap" {
    const text =
        \\declare void @stop()
        \\define void @f() {
        \\entry:
        \\  call void @stop()
        \\  unreachable
        \\}
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();
    try module.verify();
    var output = machine.MachineFunction.init("f", .void);
    defer output.deinit(std.testing.allocator);
    try std.testing.expectEqual(selector.SelectionResult.selected, try selector.tryLower(std.testing.allocator, &output, module.functions.items[0]));
    try verify.verifyFunction(output);
    try std.testing.expect(output.instructions.items[output.instructions.items.len - 1] == .ud2);
    var calls: usize = 0;
    for (output.instructions.items) |inst| if (inst == .direct_call) {
        try std.testing.expectEqualStrings("stop", inst.direct_call.symbol);
        calls += 1;
    };
    try std.testing.expectEqual(@as(usize, 1), calls);
}

test "safe scalar return address rejects unsupported depths and ABI annotations" {
    const text =
        \\declare ptr @llvm.returnaddress(i32)
        \\define ptr @f(i32 %depth) {
        \\entry:
        \\  %address = call ptr @llvm.returnaddress(i32 0)
        \\  ret ptr %address
        \\}
    ;
    for (0..5) |boundary| {
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        const call = &module.functions.items[0].blocks.items[0].instructions.items[0].kind.call;
        switch (boundary) {
            0 => call.args.items[0].value = .{ .int = 1 },
            1 => call.args.items[0].value = .{ .named = "depth" },
            2 => call.args.items[0].attrs = "inreg",
            3 => call.operand_bundle = "[ \"deopt\"() ]",
            4 => call.tail_kind = "musttail",
            else => unreachable,
        }
        var output = machine.MachineFunction.init("f", .ptr);
        defer output.deinit(std.testing.allocator);
        const selected = selector.tryLower(std.testing.allocator, &output, module.functions.items[0]) catch null;
        if (selected) |result| try std.testing.expect(result == .unsupported);
        try std.testing.expectEqual(@as(usize, 0), output.instructions.items.len);
        try std.testing.expectEqual(@as(usize, 0), output.owned_labels.items.len);
    }
}
