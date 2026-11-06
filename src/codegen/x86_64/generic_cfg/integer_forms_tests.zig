const std = @import("std");
const ir = @import("../../../ir.zig");
const forms = @import("integer_forms.zig");
const narrow = @import("narrow_abi.zig");
const machine = @import("../machine.zig");
const selector = @import("../generic_cfg_selector.zig");
const verify = @import("../verify.zig");
const encoding = @import("../../../mc/encoding.zig");

test "integer forms execute odd-width zero extension with dirty upper bits and live aliases" {
    for ([_][2]u16{ .{ 8, 33 }, .{ 32, 39 }, .{ 33, 39 }, .{ 39, 51 }, .{ 51, 52 }, .{ 52, 63 } }) |widths| {
        const source = try std.fmt.allocPrint(std.testing.allocator,
            \\define i64 @extend(i64 %input, i64 %live) {{
            \\entry:
            \\ %narrow = trunc i64 %input to i{d}
            \\ %middle = zext i{d} %narrow to i{d}
            \\ %wide = zext i{d} %middle to i64
            \\ %mixed = xor i64 %wide, %input
            \\ %result = xor i64 %mixed, %live
            \\ ret i64 %result
            \\}}
        , .{ widths[0], widths[0], widths[1], widths[1] });
        defer std.testing.allocator.free(source);
        var module = try ir.Module.parse(std.testing.allocator, source);
        defer module.deinit();
        try module.verify();
        var output = machine.MachineFunction.init("extend", .{ .int = 64 });
        defer output.deinit(std.testing.allocator);
        const selected = try selector.tryLower(std.testing.allocator, &output, module.functions.items[0]);
        if (selected == .unsupported) std.debug.print("zero extension {d}->{d}: {s}\n", .{ widths[0], widths[1], selected.unsupported.detail() });
        try std.testing.expectEqual(selector.SelectionResult.selected, selected);
        try verify.verifyFunction(output);
        const code = try encoding.encodeFunction(std.testing.allocator, output);
        defer std.testing.allocator.free(code);
        const memory = try std.posix.mmap(null, code.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
        defer std.posix.munmap(memory);
        @memcpy(memory[0..code.len], code);
        const run: *const fn (u64, u64) callconv(.c) u64 = @ptrCast(memory.ptr);
        const values = [_]u64{ 0, 1, 255, 0x7fffffff, 0xffffffff, 1 << 39, 1 << 51, 1 << 52, 0xdeadbeef12345678, std.math.maxInt(u64) };
        const mask = (@as(u64, 1) << @as(u6, @intCast(widths[0]))) - 1;
        for (values) |input| for (values) |live| try std.testing.expectEqual((input & mask) ^ input ^ live, run(input, live));
    }
}

test "integer forms private expansion preserves source widths and reaches a fixed point" {
    var module = try ir.Module.parse(std.testing.allocator,
        \\define i31 @narrow(i31 %a, i31 %b) {
        \\entry:
        \\  %sum = add nuw i31 %a, %b
        \\  %signed = sext i31 %sum to i64
        \\  %quotient = sdiv i64 %signed, 3
        \\  %answer = trunc i64 %quotient to i31
        \\  ret i31 %answer
        \\}
    );
    defer module.deinit();
    try module.verify();
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const original = module.functions.items[0];
    const expanded = (try forms.legalize(arena.allocator(), original)).?;
    try std.testing.expectEqual(@as(usize, 4), original.blocks.items[0].instructions.items.len);
    try std.testing.expect(original.blocks.items[0].instructions.items[0].kind.binary.flags.nuw);
    try std.testing.expectEqual(original.ret_ty, expanded.ret_ty);
    try std.testing.expectEqual(original.params.items.ptr, expanded.params.items.ptr);
    try std.testing.expect((try forms.legalize(arena.allocator(), expanded)) == null);
    var retained_sum = false;
    for (expanded.blocks.items[0].instructions.items) |inst| {
        if (inst.result) |name| if (std.mem.eql(u8, name, "sum")) {
            try std.testing.expect(inst.kind == .cast and inst.kind.cast.op == .trunc and inst.kind.cast.to_ty.eql(.{ .int = 31 }));
            retained_sum = true;
        };
        if (inst.kind == .binary) {
            try std.testing.expect(inst.kind.binary.ty.eql(.{ .int = 32 }) or inst.kind.binary.ty.eql(.{ .int = 64 }));
            try std.testing.expect(!inst.kind.binary.flags.any());
            try std.testing.expect(inst.kind.binary.op != .sdiv and inst.kind.binary.op != .srem);
        }
    }
    try std.testing.expect(retained_sum);
}

test "integer forms leave vectors wide integers and unsupported operands at their boundary" {
    for ([_][]const u8{
        "define i65 @wide(i65 %a, i65 %b) {\nentry:\n %sum = add i65 %a, %b\n ret i65 %sum\n}\n",
        "define <2 x i8> @vector(<2 x i8> %a, <2 x i8> %b) {\nentry:\n %sum = add <2 x i8> %a, %b\n ret <2 x i8> %sum\n}\n",
        "define i8 @undefined(i8 %a) {\nentry:\n %sum = add i8 %a, undef\n ret i8 %sum\n}\n",
        "define i128 @extend(i64 %a) {\nentry:\n %sum = sext i64 %a to i128\n ret i128 %sum\n}\n",
    }) |text| {
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        try module.verify();
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        try std.testing.expect((try forms.legalize(arena.allocator(), module.functions.items[0])) == null);
    }
}

test "integer forms narrow ABI carriers admit seventeen through thirty-one bits without extension attributes" {
    for ([_]u16{ 17, 18, 23, 24, 30, 31 }) |bits| {
        const text = try std.fmt.allocPrint(std.testing.allocator,
            \\declare i{d} @callee(i{d})
            \\define i{d} @caller(i{d} %value) {{
            \\entry:
            \\  %answer = call i{d} @callee(i{d} %value)
            \\  ret i{d} %answer
            \\}}
        , .{ bits, bits, bits, bits, bits, bits, bits });
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        try module.verify();
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        const expanded = (try narrow.legalize(arena.allocator(), module.functions.items[0])).?;
        try std.testing.expect(expanded.ret_ty.eql(.{ .int = 32 }));
        try std.testing.expect(expanded.params.items[0].ty.eql(.{ .int = 32 }));
        for (expanded.blocks.items[0].instructions.items) |inst| if (inst.kind == .call) {
            try std.testing.expect(inst.kind.call.ret_ty.eql(.{ .int = 32 }));
            try std.testing.expect(inst.kind.call.args.items[0].ty.eql(.{ .int = 32 }));
        };
        var excluded = module.functions.items[0];
        excluded.ret_attrs = "signext";
        try std.testing.expect((try narrow.legalize(arena.allocator(), excluded)) == null);
    }
}

test "integer forms execute signed narrow arithmetic with live values and dirty input padding" {
    const cases = [_]struct { operation: []const u8, expected: enum { shift, quotient, extend, zero52 } }{
        .{ .operation = "%n = trunc i64 %input to i7\n  %v = ashr i7 %n, 3\n  %wide = zext i7 %v to i64", .expected = .shift },
        .{ .operation = "%n = trunc i64 %input to i7\n  %v = ashr i7 %n, 3\n  %gate = icmp eq i64 %input, 64\n  %wide = zext i7 %v to i64", .expected = .shift },
        .{ .operation = "%n = trunc i64 %input to i31\n  %v = sdiv i31 %n, 3\n  %wide = zext i31 %v to i64", .expected = .quotient },
        .{ .operation = "%n = trunc i64 %input to i8\n  %v = sext i8 %n to i31\n  %wide = zext i31 %v to i64", .expected = .extend },
        .{ .operation = "%n = trunc i64 %input to i52\n  %v = icmp eq i52 %n, 0\n  %wide = zext i1 %v to i64", .expected = .zero52 },
    };
    for (cases) |case| {
        const text = try std.fmt.allocPrint(std.testing.allocator,
            \\define i64 @run(i64 %input, i64 %live) {{
            \\entry:
            \\  {s}
            \\  %answer = xor i64 %wide, %live
            \\  ret i64 %answer
            \\}}
        , .{case.operation});
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        try module.verify();
        var lowered = machine.MachineFunction.init("run", .{ .int = 64 });
        defer lowered.deinit(std.testing.allocator);
        try std.testing.expectEqual(selector.SelectionResult.selected, try selector.tryLower(std.testing.allocator, &lowered, module.functions.items[0]));
        try std.testing.expect(lowered.selection_owner == .composed_block or lowered.selection_owner == .composed_cfg);
        try verify.verifyFunction(lowered);
        const bytes = try encoding.encodeFunction(std.testing.allocator, lowered);
        defer std.testing.allocator.free(bytes);
        const executable = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
        defer std.posix.munmap(executable);
        @memcpy(executable[0..bytes.len], bytes);
        const run: *const fn (u64, u64) callconv(.c) u64 = @ptrCast(executable.ptr);
        const values = [_]u64{ 0, 1, 63, 64, 127, 128, 255, 0x3fffffff, 0x40000000, 0x7fffffff, 1 << 52, 0xdeadbeef12345678, std.math.maxInt(u64) };
        for (values) |input| for (values) |live| {
            const answer: i64 = switch (case.expected) {
                .shift => (@as(i64, @intCast((input & 127) ^ 64)) - 64) >> 3,
                .quotient => @divTrunc(@as(i64, @intCast((input & 0x7fffffff) ^ 0x40000000)) - 0x40000000, 3),
                .extend => @as(i64, @intCast((input & 255) ^ 128)) - 128,
                .zero52 => @intFromBool(input & ((@as(u64, 1) << 52) - 1) == 0),
            };
            const expected = @as(u64, @bitCast(answer)) & (if (case.expected == .shift) @as(u64, 127) else 0x7fffffff);
            try std.testing.expectEqual(expected ^ live, run(input, live));
        };
    }
}
