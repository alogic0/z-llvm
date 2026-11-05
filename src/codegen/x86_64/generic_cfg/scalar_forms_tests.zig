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

test "safe comparison forms preserve every narrow signed and unsigned predicate" {
    const values = [_]u64{ 0, 1, 2, 63, 127, 128, 255, 32767, 32768, 65535, 0x3fffffff, 0x40000000, 0x7fffffff, 0x80000000, 0x7fffffffffffffff, 0x8000000000000000, std.math.maxInt(u64) };
    for ([_]u16{ 1, 2, 6, 7, 8, 16, 31, 32, 64 }) |bits| {
        for (std.enums.values(ir.IcmpPredicate)) |predicate| {
            const operands = if (bits == 64) "" else try std.fmt.allocPrint(std.testing.allocator, "  %x = trunc i64 %a to i{d}\n  %y = trunc i64 %b to i{d}\n", .{ bits, bits });
            defer if (bits != 64) std.testing.allocator.free(operands);
            const text = try std.fmt.allocPrint(std.testing.allocator, "define i64 @compare(i64 %a, i64 %b, ptr %out) {{\nentry:\n{s}" ++
                "  %c = icmp {s} i{d} %{s}, %{s}\n  %r = zext i1 %c to i32\n" ++
                "  store i32 %r, ptr %out, align 4\n  %live = xor i64 %a, %b\n  ret i64 %live\n}}\n", .{ operands, @tagName(predicate), bits, if (bits == 64) "a" else "x", if (bits == 64) "b" else "y" });
            defer std.testing.allocator.free(text);
            var module = try ir.Module.parse(std.testing.allocator, text);
            defer module.deinit();
            try module.verify();
            const code = executable(module) catch |err| {
                std.debug.print("comparison input: {s}\n", .{text});
                return err;
            };
            defer std.posix.munmap(code);
            const run: *const fn (u64, u64, *u32) callconv(.c) u64 = @ptrCast(code.ptr);
            const mask: u64 = if (bits == 64) std.math.maxInt(u64) else (@as(u64, 1) << @as(u6, @intCast(bits))) - 1;
            const sign = @as(u64, 1) << @as(u6, @intCast(bits - 1));
            for (values) |a| for (values) |b| {
                const x = a & mask;
                const y = b & mask;
                const expected = switch (predicate) {
                    .eq => x == y,
                    .ne => x != y,
                    .ult => x < y,
                    .ule => x <= y,
                    .ugt => x > y,
                    .uge => x >= y,
                    .slt => (x ^ sign) < (y ^ sign),
                    .sle => (x ^ sign) <= (y ^ sign),
                    .sgt => (x ^ sign) > (y ^ sign),
                    .sge => (x ^ sign) >= (y ^ sign),
                };
                var out = [_]u32{ 0xa5a5a5a5, 0xdeadbeef, 0xa5a5a5a5 };
                try std.testing.expectEqual(a ^ b, run(a, b, &out[1]));
                std.testing.expectEqual(@as(u32, @intFromBool(expected)), out[1]) catch |err| {
                    std.debug.print("failed compare i{d} {s}: a={x} b={x}\n", .{ bits, @tagName(predicate), a, b });
                    return err;
                };
                try std.testing.expectEqual(@as(u32, 0xa5a5a5a5), out[0]);
                try std.testing.expectEqual(out[0], out[2]);
            };
            var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
            defer arena.deinit();
            const comparisons = @import("comparison_forms.zig");
            if (try comparisons.legalize(arena.allocator(), module.functions.items[0], null)) |view| {
                try std.testing.expect(try comparisons.legalize(arena.allocator(), view, null) == null);
                var private_module = module;
                private_module.functions = try module.functions.clone(arena.allocator());
                private_module.functions.items[0] = view;
                try private_module.verify();
            }
            try module.verify();
        }
    }
}

test "safe comparison forms canonicalize reversed and full width constants" {
    for ([_]u16{ 8, 16, 32, 64 }) |bits| {
        const high: u64 = @as(u64, 1) << @as(u6, @intCast(bits - 1));
        const mask: u64 = if (bits == 64) std.math.maxInt(u64) else high * 2 - 1;
        for ([_]bool{ false, true }) |reversed| {
            for ([_]u64{ 0, high, mask }) |constant| {
                const operands = if (bits == 64) "" else try std.fmt.allocPrint(std.testing.allocator, "  %x = trunc i64 %a to i{d}\n", .{bits});
                defer if (bits != 64) std.testing.allocator.free(operands);
                const name = if (bits == 64) "%a" else "%x";
                const literal = try std.fmt.allocPrint(std.testing.allocator, "{d}", .{constant});
                defer std.testing.allocator.free(literal);
                const text = try std.fmt.allocPrint(std.testing.allocator, "define i32 @constant(i64 %a) {{\nentry:\n{s}  %c = icmp ule i{d} {s}, {s}\n  %r = zext i1 %c to i32\n  ret i32 %r\n}}\n", .{ operands, bits, if (reversed) literal else name, if (reversed) name else literal });
                defer std.testing.allocator.free(text);
                var module = try ir.Module.parse(std.testing.allocator, text);
                defer module.deinit();
                const code = executable(module) catch |err| {
                    std.debug.print("comparison input: {s}\n", .{text});
                    return err;
                };
                defer std.posix.munmap(code);
                const run: *const fn (u64) callconv(.c) u32 = @ptrCast(code.ptr);
                for ([_]u64{ 0, 1, high - 1, high, high + 1, mask, std.math.maxInt(u64) }) |input| {
                    const x = input & mask;
                    const expected = if (reversed) constant <= x else x <= constant;
                    std.testing.expectEqual(@as(u32, @intFromBool(expected)), run(input)) catch |err| {
                        std.debug.print("failed constant i{d} reversed={any} value={x} input={x}\n", .{ bits, reversed, constant, input });
                        return err;
                    };
                }
            }
        }
    }
}

test "safe comparison forms preserve pointer order and layout boundaries" {
    const comparisons = @import("comparison_forms.zig");
    for ([_]ir.IcmpPredicate{ .ne, .ult, .ule, .ugt, .uge }) |predicate| {
        const text = try std.fmt.allocPrint(std.testing.allocator, "define i32 @pointer(ptr %a, ptr %b) {{\nentry:\n  %c = icmp {s} ptr %a, %b\n  %r = zext i1 %c to i32\n  ret i32 %r\n}}\n", .{@tagName(predicate)});
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        const code = executable(module) catch |err| {
            std.debug.print("comparison input: {s}\n", .{text});
            return err;
        };
        defer std.posix.munmap(code);
        const run: *const fn (usize, usize) callconv(.c) u32 = @ptrCast(code.ptr);
        const values = [_]usize{ 0, 1, 0x7fffffffffffffff, 0x8000000000000000, std.math.maxInt(usize) };
        for (values) |a| for (values) |b| {
            const expected = switch (predicate) {
                .ne => a != b,
                .ult => a < b,
                .ule => a <= b,
                .ugt => a > b,
                .uge => a >= b,
                else => unreachable,
            };
            try std.testing.expectEqual(@as(u32, @intFromBool(expected)), run(a, b));
        };
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        var context = machine.ReadOnlyModuleContext{ .globals = &.{}, .named_types = &.{}, .target_datalayout = "e-p:32:32" };
        try std.testing.expect(try comparisons.legalize(arena.allocator(), module.functions.items[0], &context) == null);
        context.target_datalayout = "e-p:64:64-ni:0";
        try std.testing.expect(try comparisons.legalize(arena.allocator(), module.functions.items[0], &context) == null);
        module.functions.items[0].blocks.items[0].instructions.items[0].kind.icmp.samesign = true;
        try std.testing.expect(try comparisons.legalize(arena.allocator(), module.functions.items[0], null) == null);
    }
}

test "checked integer pairs preserve signed and unsigned overflow at every narrow width" {
    const ops = [_][]const u8{ "uadd", "usub", "umul", "sadd", "ssub", "smul" };
    for (1..33) |bits| for (ops, 0..) |op, operation_index| {
        for (0..3) |constant_side| {
            const lhs = if (constant_side == 1) "-1" else "%a";
            const rhs = if (constant_side == 2) "-1" else "%b";
            const text = try std.fmt.allocPrint(std.testing.allocator, "declare {{ i{0d}, i1 }} @llvm.{1s}.with.overflow.i{0d}(i{0d}, i{0d})\n" ++
                "define i64 @checked(i64 %input_a, i64 %input_b, ptr %out) {{\nentry:\n" ++
                "  %a = trunc i64 %input_a to i{0d}\n  %b = trunc i64 %input_b to i{0d}\n" ++
                "  %pair = call {{ i{0d}, i1 }} @llvm.{1s}.with.overflow.i{0d}(i{0d} {2s}, i{0d} {3s})\n" ++
                "  %flag = extractvalue {{ i{0d}, i1 }} %pair, 1\n  %value = extractvalue {{ i{0d}, i1 }} %pair, 0\n" ++
                "  %wide = zext i{0d} %value to i64\n  store i64 %wide, ptr %out, align 8\n" ++
                "  %next = getelementptr i8, ptr %out, i64 8\n  %live = xor i64 %input_a, %input_b\n" ++
                "  store i64 %live, ptr %next, align 8\n  %result = zext i1 %flag to i64\n  ret i64 %result\n}}\n", .{ bits, op, lhs, rhs });
            defer std.testing.allocator.free(text);
            var module = try ir.Module.parse(std.testing.allocator, text);
            defer module.deinit();
            try module.verify();
            const code = try executable(module);
            defer std.posix.munmap(code);
            const run: *const fn (u64, u64, *u64) callconv(.c) u64 = @ptrCast(code.ptr);
            const sign = @as(u64, 1) << @intCast(bits - 1);
            const mask = 2 * sign - 1;
            const values = [_]u64{ 0, 1, sign - 1, sign, sign + 1, mask, mask + 1, std.math.maxInt(u64) };
            for (values) |a| for (values) |b| {
                const x: i128 = if (constant_side == 1) mask else a & mask;
                const y: i128 = if (constant_side == 2) mask else b & mask;
                const signed = operation_index >= 3;
                const sx = if (signed) (x ^ sign) - sign else x;
                const sy = if (signed) (y ^ sign) - sign else y;
                const mathematical: i128 = switch (operation_index % 3) {
                    0 => sx + sy,
                    1 => sx - sy,
                    else => sx * sy,
                };
                const low: i128 = if (signed) -@as(i128, sign) else 0;
                const high: i128 = if (signed) sign - 1 else mask;
                const guard = 0xa5a5a5a5a5a5a5a5;
                var output = [_]u64{ guard, 0, 0, guard };
                const actual = run(a, b, &output[1]);
                const expected: u64 = @intFromBool(mathematical < low or mathematical > high);
                if (actual != expected) std.debug.print("checked {s} i{d} constants={d} a={x} b={x} value={x} flag={d} expected={d}\n", .{ op, bits, constant_side, a, b, output[1], actual, expected });
                try std.testing.expectEqual(expected, actual);
                try std.testing.expectEqual(@as(u64, @intCast(mathematical & mask)), output[1]);
                try std.testing.expectEqual(a ^ b, output[2]);
                try std.testing.expectEqual(@as(u64, guard), output[0]);
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
            try std.testing.expect(module.functions.items[0].blocks.items[0].instructions.items[2].kind == .call);
        }
    };
}

test "checked integer pairs normalize an i32 alias of a live full accumulator" {
    const text =
        \\define i64 @roundtrip(i64 %input, ptr %out) {
        \\entry:
        \\  %full = add i64 %input, 7
        \\  %low = trunc i64 %full to i32
        \\  %result = zext i32 %low to i64
        \\  store i64 %full, ptr %out, align 8
        \\  ret i64 %result
        \\}
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();
    try module.verify();
    const code = try executable(module);
    defer std.posix.munmap(code);
    const run: *const fn (u64, *u64) callconv(.c) u64 = @ptrCast(code.ptr);
    for ([_]u64{ 0, 0xfffffff9, 0xffffffff, 0x100000000, 0x7fffffffffffffff, 0x8000000000000000, std.math.maxInt(u64) }) |input| {
        var output: u64 = 0;
        try std.testing.expectEqual((input +% 7) & 0xffffffff, run(input, &output));
        try std.testing.expectEqual(input +% 7, output);
    }
}

test "word arithmetic unsigned word product preserves both halves overflow and live inputs" {
    const values = [_]u64{ 0, 1, 2, 0xffffffff, 0x100000000, 0x7fffffffffffffff, 0x8000000000000000, std.math.maxInt(u64) };
    for (0..3) |constant_side| {
        const text = try std.fmt.allocPrint(std.testing.allocator, "declare {{ i64, i1 }} @llvm.umul.with.overflow.i64(i64, i64)\n" ++
            "define i64 @product{d}(i64 %a, i64 %b, ptr %out) {{\nentry:\n" ++
            "  %pair = call {{ i64, i1 }} @llvm.umul.with.overflow.i64(i64 {s}, i64 {s})\n" ++
            "  %flag = extractvalue {{ i64, i1 }} %pair, 1\n  %value = extractvalue {{ i64, i1 }} %pair, 0\n" ++
            "  store i64 %value, ptr %out, align 8\n  %next = getelementptr i8, ptr %out, i64 8\n" ++
            "  %live = xor i64 %a, %b\n  store i64 %live, ptr %next, align 8\n" ++
            "  %result = zext i1 %flag to i64\n  ret i64 %result\n}}\n", .{ constant_side, if (constant_side == 1) "-1" else "%a", if (constant_side == 2) "-1" else "%b" });
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        try module.verify();
        const code = try executable(module);
        defer std.posix.munmap(code);
        const run: *const fn (u64, u64, *u64) callconv(.c) u64 = @ptrCast(code.ptr);
        for (values) |a| for (values) |b| {
            const expected = @as(u128, if (constant_side == 1) std.math.maxInt(u64) else a) * @as(u128, if (constant_side == 2) std.math.maxInt(u64) else b);
            var out = [_]u64{ 0xa5a5a5a5a5a5a5a5, 0, 0, 0xa5a5a5a5a5a5a5a5 };
            try std.testing.expectEqual(@as(u64, @intFromBool(expected > std.math.maxInt(u64))), run(a, b, &out[1]));
            try std.testing.expectEqual(@as(u64, @truncate(expected)), out[1]);
            try std.testing.expectEqual(a ^ b, out[2]);
            try std.testing.expectEqual(@as(u64, 0xa5a5a5a5a5a5a5a5), out[0]);
            try std.testing.expectEqual(out[0], out[3]);
        };
    }
}

test "word arithmetic constant unsigned division and remainder retain high-bit divisors" {
    for ([_]u16{ 32, 64 }) |bits| for ([_][]const u8{ "udiv", "urem" }) |op| {
        const mask: u64 = if (bits == 64) std.math.maxInt(u64) else std.math.maxInt(u32);
        const sign: u64 = @as(u64, 1) << @intCast(bits - 1);
        for ([_]u64{ 1, 2, 3, 24, 100, sign, mask }) |divisor| {
            const text = try std.fmt.allocPrint(std.testing.allocator, "define i{0d} @divide(i{0d} %a, ptr %out) {{\nentry:\n" ++
                "  %value = {1s} i{0d} %a, {2d}\n  store i{0d} %value, ptr %out\n" ++
                "  %live = xor i{0d} %a, 55\n  ret i{0d} %live\n}}\n", .{ bits, op, divisor });
            defer std.testing.allocator.free(text);
            var module = try ir.Module.parse(std.testing.allocator, text);
            defer module.deinit();
            try module.verify();
            const code = try executable(module);
            defer std.posix.munmap(code);
            for ([_]u64{ 0, 1, 2, 23, 24, 99, 100, sign - 1, sign, mask }) |a| {
                const expected = if (std.mem.eql(u8, op, "udiv")) a / divisor else a % divisor;
                var out = [_]u64{ 0xa5a5a5a5a5a5a5a5, 0, 0xa5a5a5a5a5a5a5a5 };
                if (bits == 64) {
                    const run: *const fn (u64, *u64) callconv(.c) u64 = @ptrCast(code.ptr);
                    try std.testing.expectEqual(a ^ 55, run(a, &out[1]));
                } else {
                    const run: *const fn (u32, *u32) callconv(.c) u32 = @ptrCast(code.ptr);
                    try std.testing.expectEqual(@as(u32, @intCast(a)) ^ 55, run(@intCast(a), @ptrCast(&out[1])));
                }
                try std.testing.expectEqual(expected, out[1]);
                try std.testing.expectEqual(@as(u64, 0xa5a5a5a5a5a5a5a5), out[0]);
                try std.testing.expectEqual(out[0], out[2]);
            }
        }
    };
}

test "word arithmetic zero extension clears a truncated named sum in RAX" {
    const text =
        \\define i64 @roundtrip(i64 %input, i64 %addend, ptr %out) {
        \\entry:
        \\  %full = add i64 %input, %addend
        \\  %low = trunc i64 %full to i32
        \\  %result = zext i32 %low to i64
        \\  store i64 %full, ptr %out, align 8
        \\  ret i64 %result
        \\}
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();
    try module.verify();
    const code = try executable(module);
    defer std.posix.munmap(code);
    const run: *const fn (u64, u64, *u64) callconv(.c) u64 = @ptrCast(code.ptr);
    for ([_]u64{ 0, 0xffffffff, 0x100000000, 0x8000000000000000, std.math.maxInt(u64) }) |input| {
        var output: u64 = 0;
        try std.testing.expectEqual((input +% 7) & 0xffffffff, run(input, 7, &output));
        try std.testing.expectEqual(input +% 7, output);
    }
}

test "word arithmetic byte permutations preserve exact width and dirty upper inputs" {
    for ([_]u16{ 16, 32, 64 }) |bits| {
        const narrow = if (bits == 64) "" else try std.fmt.allocPrint(std.testing.allocator, "  %narrow = trunc i64 %input to i{d}\n", .{bits});
        defer if (bits != 64) std.testing.allocator.free(narrow);
        const wide = if (bits == 64) "" else try std.fmt.allocPrint(std.testing.allocator, "  %wide = zext i{d} %value to i64\n", .{bits});
        defer if (bits != 64) std.testing.allocator.free(wide);
        const text = try std.fmt.allocPrint(std.testing.allocator, "declare i{0d} @llvm.bswap.i{0d}(i{0d})\ndefine i64 @swap(i64 %input, ptr %out) {{\nentry:\n{1s}" ++
            "  %value = call i{0d} @llvm.bswap.i{0d}(i{0d} %{2s})\n{3s}" ++
            "  store i64 %{4s}, ptr %out\n  %live = xor i64 %input, 55\n  ret i64 %live\n}}\n", .{ bits, narrow, if (bits == 64) "input" else "narrow", wide, if (bits == 64) "value" else "wide" });
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        try module.verify();
        const code = try executable(module);
        defer std.posix.munmap(code);
        const run: *const fn (u64, *u64) callconv(.c) u64 = @ptrCast(code.ptr);
        for ([_]u64{ 0, 1, 255, 256, 0x123456789abcdef0, 0x8000000000000000, std.math.maxInt(u64) }) |input| {
            const expected: u64 = switch (bits) {
                16 => @byteSwap(@as(u16, @truncate(input))),
                32 => @byteSwap(@as(u32, @truncate(input))),
                else => @byteSwap(input),
            };
            var output: u64 = 0;
            try std.testing.expectEqual(input ^ 55, run(input, &output));
            try std.testing.expectEqual(expected, output);
        }
    }
}

test "word arithmetic signed and unsigned extrema select full-word values" {
    const ops = [_][]const u8{ "umax", "smin", "smax" };
    for ([_]u16{ 32, 64 }) |bits| for (ops, 0..) |op, op_index| {
        for (0..3) |constant_side| {
            const text = try std.fmt.allocPrint(std.testing.allocator, "declare i{0d} @llvm.{1s}.i{0d}(i{0d}, i{0d})\ndefine i{0d} @extrema(i{0d} %a, i{0d} %b) {{\nentry:\n" ++
                "  %result = call i{0d} @llvm.{1s}.i{0d}(i{0d} {2s}, i{0d} {3s})\n  ret i{0d} %result\n}}\n", .{ bits, op, if (constant_side == 1) "-1" else "%a", if (constant_side == 2) "-1" else "%b" });
            defer std.testing.allocator.free(text);
            var module = try ir.Module.parse(std.testing.allocator, text);
            defer module.deinit();
            try module.verify();
            const code = try executable(module);
            defer std.posix.munmap(code);
            const mask: u64 = if (bits == 64) std.math.maxInt(u64) else std.math.maxInt(u32);
            const sign: u64 = @as(u64, 1) << @intCast(bits - 1);
            const values = [_]u64{ 0, 1, sign - 1, sign, sign + 1, mask };
            for (values) |a| for (values) |b| {
                const x = if (constant_side == 1) mask else a;
                const y = if (constant_side == 2) mask else b;
                const expected = if (op_index == 0) @max(x, y) else if (op_index == 1) (if ((x ^ sign) < (y ^ sign)) x else y) else (if ((x ^ sign) > (y ^ sign)) x else y);
                if (bits == 64) {
                    const run: *const fn (u64, u64) callconv(.c) u64 = @ptrCast(code.ptr);
                    try std.testing.expectEqual(expected, run(a, b));
                } else {
                    const run: *const fn (u32, u32) callconv(.c) u32 = @ptrCast(code.ptr);
                    try std.testing.expectEqual(@as(u32, @intCast(expected)), run(@intCast(a), @intCast(b)));
                }
            };
        }
    };
}

test "word arithmetic signed checked add and subtract preserve extrema and constants" {
    const values = [_]i64{ std.math.minInt(i64), std.math.minInt(i64) + 1, -1, 0, 1, 2, std.math.maxInt(i64) - 1, std.math.maxInt(i64) };
    for ([_][]const u8{ "sadd", "ssub" }) |op| for (0..3) |side| {
        const text = try std.fmt.allocPrint(std.testing.allocator, "declare {{ i64, i1 }} @llvm.{s}.with.overflow.i64(i64, i64)\ndefine i64 @signed(i64 %a, i64 %b, ptr %out) {{\nentry:\n" ++
            "  %pair = call {{ i64, i1 }} @llvm.{s}.with.overflow.i64(i64 {s}, i64 {s})\n" ++
            "  %flag = extractvalue {{ i64, i1 }} %pair, 1\n  %value = extractvalue {{ i64, i1 }} %pair, 0\n" ++
            "  store i64 %value, ptr %out\n  %result = zext i1 %flag to i64\n  ret i64 %result\n}}\n", .{ op, op, if (side == 1) "-1" else "%a", if (side == 2) "-1" else "%b" });
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        try module.verify();
        const code = try executable(module);
        defer std.posix.munmap(code);
        const run: *const fn (i64, i64, *i64) callconv(.c) u64 = @ptrCast(code.ptr);
        for (values) |a| for (values) |b| {
            const x: i64 = if (side == 1) -1 else a;
            const y: i64 = if (side == 2) -1 else b;
            const expected = if (std.mem.eql(u8, op, "sadd")) @addWithOverflow(x, y) else @subWithOverflow(x, y);
            var output: i64 = 0;
            try std.testing.expectEqual(@as(u64, expected[1]), run(a, b, &output));
            try std.testing.expectEqual(expected[0], output);
        };
    };
}

test "word arithmetic private legalization is idempotent and rejects invalid envelopes" {
    const words = @import("word_arithmetic.zig");
    for ([_][]const u8{
        "  %result = udiv i64 %a, 24",
        "  %result = call i64 @llvm.umax.i64(i64 %a, i64 -1)",
    }) |instruction| {
        const text = try std.fmt.allocPrint(std.testing.allocator, "define i64 @probe(i64 %a) {{\nentry:\n{s}\n  ret i64 %result\n}}\n", .{instruction});
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        const original = module.functions.items[0];
        const count = original.blocks.items[0].instructions.items.len;
        const kind = std.meta.activeTag(original.blocks.items[0].instructions.items[0].kind);
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        const view = (try words.legalize(arena.allocator(), original)).?;
        try std.testing.expect(try words.legalize(arena.allocator(), view) == null);
        try std.testing.expectEqual(count, original.blocks.items[0].instructions.items.len);
        try std.testing.expectEqual(kind, std.meta.activeTag(original.blocks.items[0].instructions.items[0].kind));
    }
    for ([_][]const u8{
        "  %result = udiv i64 %a, 0",
        "  %result = udiv i64 %a, 18446744073709551616",
        "  %result = udiv i64 %a, -9223372036854775809",
        "  %result = call fastcc i64 @llvm.umax.i64(i64 %a, i64 2)",
        "  %result = call i64 @llvm.umax.i64(i64 inreg %a, i64 2)",
        "  %result = call i64 @llvm.umax.i64(i64 %a, i64 poison)",
    }) |instruction| {
        const text = try std.fmt.allocPrint(std.testing.allocator, "define i64 @probe(i64 %a) {{\nentry:\n{s}\n  ret i64 %result\n}}\n", .{instruction});
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        try std.testing.expect(try words.legalize(arena.allocator(), module.functions.items[0]) == null);
    }
}
