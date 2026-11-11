const std = @import("std");
const ir = @import("../../../ir.zig");
const machine = @import("../machine.zig");
const verify = @import("../verify.zig");
const selector = @import("../generic_cfg_selector.zig");
const encoding = @import("../../../mc/encoding.zig");
const legalization = @import("narrow_abi.zig");

fn compile(module: ir.Module) ![]align(std.heap.page_size_min) u8 {
    const function = module.functions.items[0];
    var output = machine.MachineFunction.init(function.name, function.ret_ty);
    defer output.deinit(std.testing.allocator);
    const selected = try selector.tryLower(std.testing.allocator, &output, function);
    if (selected == .unsupported) std.debug.print("narrow ABI: {s} {s}\n", .{ selected.unsupported.tagName(), selected.unsupported.detail() });
    try std.testing.expectEqual(selector.SelectionResult.selected, selected);
    try verify.verifyFunction(output);
    const bytes = try encoding.encodeFunction(std.testing.allocator, output);
    defer std.testing.allocator.free(bytes);
    const executable = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    @memcpy(executable[0..bytes.len], bytes);
    return executable;
}

test "integer ABI entry normalizes dirty register bits at every non-native scalar width" {
    for (1..64) |bits| {
        if (bits == 32) continue;
        const text = try std.fmt.allocPrint(std.testing.allocator,
            \\define i64 @narrow_entry(i{d} %input, i64 %take) {{
            \\entry:
            \\  %condition = icmp ne i64 %take, 0
            \\  br i1 %condition, label %yes, label %no
            \\yes:
            \\  %result = zext i{d} %input to i64
            \\  ret i64 %result
            \\no:
            \\  ret i64 55
            \\}}
        , .{ bits, bits });
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        try module.verify();
        const executable = try compile(module);
        defer std.posix.munmap(executable);
        const run: *const fn (u64, u64) callconv(.c) u64 = @ptrCast(executable.ptr);
        const mask: u64 = (@as(u64, 1) << @intCast(bits)) - 1;
        for ([_]u64{ 0, 1, mask, mask + 1, 0xdeadbeefcafe0000, 0x123456789abcdef0, std.math.maxInt(u64) }) |input| {
            try std.testing.expectEqual(input & mask, run(input, 1));
            try std.testing.expectEqual(@as(u64, 55), run(input, 0));
        }
        try std.testing.expectEqual(bits, module.functions.items[0].params.items[0].ty.int);
        try std.testing.expectEqualStrings("input", module.functions.items[0].params.items[0].name);
    }
}

test "narrow ABI boolean xor branches on the defined low bit" {
    const text =
        \\define i32 @boolean(i1 %input) {
        \\entry:
        \\  %negated = xor i1 %input, 1
        \\  br i1 %negated, label %yes, label %no
        \\yes:
        \\  ret i32 7
        \\no:
        \\  ret i32 11
        \\}
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();
    try module.verify();
    const executable = try compile(module);
    defer std.posix.munmap(executable);
    const run: *const fn (u64) callconv(.c) u32 = @ptrCast(executable.ptr);
    for ([_]u64{ 0, 1, 2, 3, 0xdeadbeefcafe0000, 0xdeadbeefcafe0001, std.math.maxInt(u64) }) |input|
        try std.testing.expectEqual(@as(u32, if (input & 1 == 0) 7 else 11), run(input));
}

test "narrow ABI private carrier copies operands and avoids generated name collisions" {
    const text =
        \\declare fastcc i16 @callee(i3)
        \\define fastcc i16 @caller(i3 %__zllvm_narrow_0) {
        \\__zllvm_narrow_1:
        \\  %__zllvm_narrow_2 = call fastcc i16 @callee(i3 %__zllvm_narrow_0)
        \\  ret i16 %__zllvm_narrow_2
        \\}
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();
    try module.verify();
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const original = module.functions.items[0];
    const view = (try legalization.legalize(arena.allocator(), original)).?;
    try std.testing.expectEqualStrings("__zllvm_narrow_3", view.params.items[0].name);
    try std.testing.expectEqual(@as(u16, 32), view.ret_ty.int);
    try std.testing.expectEqual(@as(u16, 16), original.ret_ty.int);
    const call = original.blocks.items[0].instructions.items[0].kind.call;
    try std.testing.expectEqual(@as(u16, 16), call.ret_ty.int);
    try std.testing.expectEqual(@as(u16, 3), call.args.items[0].ty.int);
    try std.testing.expectEqualStrings("__zllvm_narrow_0", call.args.items[0].value.named);
    try std.testing.expect((try legalization.legalize(arena.allocator(), view)) == null);
    try module.verify();
}

test "narrow ABI mixed parameters survive normalization and direct boolean branching" {
    const text =
        \\define i64 @mixed(i1 %flag, i3 %a, i8 %b, i16 %c, i64 %live) {
        \\entry:
        \\  br i1 %flag, label %yes, label %no
        \\yes:
        \\  %aw = zext i3 %a to i32
        \\  %bw = zext i8 %b to i32
        \\  %ab = add i32 %aw, %bw
        \\  %cw = zext i16 %c to i32
        \\  %abc = add i32 %ab, %cw
        \\  %wide = zext i32 %abc to i64
        \\  %result = xor i64 %wide, %live
        \\  ret i64 %result
        \\no:
        \\  ret i64 %live
        \\}
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();
    try module.verify();
    const executable = try compile(module);
    defer std.posix.munmap(executable);
    const run: *const fn (u64, u64, u64, u64, u64) callconv(.c) u64 = @ptrCast(executable.ptr);
    const values = [_]u64{ 0, 1, 0xdeadbeefcafe1234, std.math.maxInt(u64) };
    const live: u64 = 0x123456789abcdef0;
    for (values) |flag| for (values) |a| for (values) |b| for (values) |c| {
        const payload = (a & 7) + (b & 255) + (c & 65535);
        try std.testing.expectEqual(if (flag & 1 == 0) live else live ^ payload, run(flag, a, b, c, live));
    };
}

test "integer ABI validated payload facts do not constrain dirty carrier padding" {
    for (1..64) |bits| {
        if (bits == 32) continue;
        const text = try std.fmt.allocPrint(std.testing.allocator,
            \\define noundef range(i{d} -1, 0) i{d} @facts(i{d} noundef range(i{d} -1, 0) %input, ptr %output) {{
            \\entry:
            \\  %wide = zext i{d} %input to i64
            \\  store i64 %wide, ptr %output, align 8
            \\  ret i{d} %input
            \\}}
        , .{ bits, bits, bits, bits, bits, bits });
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        try module.verify();
        const original = module.functions.items[0];
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        const view = (try legalization.legalize(arena.allocator(), original)).?;
        try std.testing.expect(view.ret_attrs == null and view.params.items[0].attrs == null);
        try std.testing.expect(original.ret_attrs != null and original.params.items[0].attrs != null);
        try std.testing.expectEqual(@as(u16, if (bits < 32) 32 else 64), view.ret_ty.int);
        try std.testing.expectEqual(@as(u16, if (bits < 32) 32 else 64), view.params.items[0].ty.int);
        try std.testing.expect(try legalization.legalize(arena.allocator(), view) == null);
        const executable = try compile(module);
        defer std.posix.munmap(executable);
        const run: *const fn (u64, *u64) callconv(.c) u64 = @ptrCast(executable.ptr);
        const mask = (@as(u64, 1) << @intCast(bits)) - 1;
        for ([_]u64{ 0, 0xdeadbeefcafe0000, std.math.maxInt(u64) }) |padding| {
            var stored: u64 = 0;
            try std.testing.expectEqual(mask, run((padding & ~mask) | mask, &stored) & mask);
            try std.testing.expectEqual(mask, stored);
        }
        try module.verify();
    }
}

test "narrow ABI range and noundef calls retain source contracts while widening private operands" {
    const text =
        \\declare noundef range(i8 -16, 16) i8 @helper(i8, i16)
        \\define range(i16 0, 32768) i16 @caller(i8 range(i8 -16, 16) %a, i16 noundef %b) {
        \\entry:
        \\  %r = call noundef range(i8 -16, 16) i8 @helper(i8 range(i8 -16, 16) %a, i16 noundef %b)
        \\  %wide = zext i8 %r to i16
        \\  ret i16 %wide
        \\}
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();
    try module.verify();
    const source = module.functions.items[0];
    const call = source.blocks.items[0].instructions.items[0].kind.call;
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const view = (try legalization.legalize(arena.allocator(), source)).?;
    var found = false;
    for (view.blocks.items[0].instructions.items) |inst| if (inst.kind == .call) {
        found = true;
        try std.testing.expectEqual(@as(u16, 32), inst.kind.call.ret_ty.int);
        try std.testing.expect(inst.kind.call.ret_attrs == null);
        for (inst.kind.call.args.items) |arg| {
            try std.testing.expectEqual(@as(u16, 32), arg.ty.int);
            try std.testing.expect(arg.attrs == null);
        }
    };
    try std.testing.expect(found);
    try std.testing.expectEqualStrings("noundef range(i8 -16, 16)", call.ret_attrs.?);
    try std.testing.expectEqualStrings("range(i8 -16, 16)", call.args.items[0].attrs.?);
    try std.testing.expectEqualStrings("noundef", call.args.items[1].attrs.?);
    var output = machine.MachineFunction.init(source.name, source.ret_ty);
    defer output.deinit(std.testing.allocator);
    try std.testing.expectEqual(selector.SelectionResult.selected, try selector.tryLower(std.testing.allocator, &output, source));
    try verify.verifyFunction(output);
    try module.verify();
}

test "wide integer ABI reuses mixed carriers and preserves source call attributes" {
    const text =
        \\declare noundef i49 @helper(i33, i37, i49, i63, i8)
        \\define noundef i37 @caller(i33 %a, i37 %b, i49 %c, i63 %d, i8 %e) {
        \\entry:
        \\ %r = call noundef i49 @helper(i33 noundef %a, i37 noundef %b, i49 noundef %c, i63 noundef %d, i8 noundef %e)
        \\ %result = trunc i49 %r to i37
        \\ ret i37 %result
        \\}
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();
    try module.verify();
    const original = module.functions.items[0];
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const view = (try legalization.legalize(arena.allocator(), original)).?;
    try std.testing.expectEqual(@as(u16, 64), view.ret_ty.int);
    var calls: usize = 0;
    for (view.blocks.items[0].instructions.items) |inst| if (inst.kind == .call) {
        calls += 1;
        try std.testing.expectEqual(@as(u16, 64), inst.kind.call.ret_ty.int);
        try std.testing.expect(inst.kind.call.ret_attrs == null);
        for (inst.kind.call.args.items, [_]u16{ 64, 64, 64, 64, 32 }) |arg, bits| {
            try std.testing.expectEqual(bits, arg.ty.int);
            try std.testing.expect(arg.attrs == null);
        }
    };
    try std.testing.expectEqual(@as(usize, 1), calls);
    for (original.params.items, [_]u16{ 33, 37, 49, 63, 8 }) |param, bits| try std.testing.expectEqual(bits, param.ty.int);
    const source_call = original.blocks.items[0].instructions.items[0].kind.call;
    try std.testing.expectEqualStrings("noundef", source_call.ret_attrs.?);
    for (source_call.args.items) |arg| try std.testing.expectEqualStrings("noundef", arg.attrs.?);
    try std.testing.expect(try legalization.legalize(arena.allocator(), view) == null);
    var output = machine.MachineFunction.init(original.name, original.ret_ty);
    defer output.deinit(std.testing.allocator);
    try std.testing.expectEqual(selector.SelectionResult.selected, try selector.tryLower(std.testing.allocator, &output, original));
    try verify.verifyFunction(output);
    try module.verify();
}

test "wide integer ABI retains explicit extension and unsupported call boundaries" {
    for ([_]u16{ 33, 37, 49, 63 }) |bits| for ([_][]const u8{ "signext", "zeroext", "inreg", "range(i32 0, 32)" }) |attrs| {
        const text = try std.fmt.allocPrint(std.testing.allocator, "define i64 @invalid(i{d} {s} %a) {{\nentry:\n %r = call i64 @helper(i{d} {s} %a)\n ret i64 %r\n}}\n", .{ bits, attrs, bits, attrs });
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        try std.testing.expect(try legalization.legalize(arena.allocator(), module.functions.items[0]) == null);
        try std.testing.expectEqual(bits, module.functions.items[0].params.items[0].ty.int);
    };
}

test "narrow ABI rejects malformed facts and extension promises before changing private contracts" {
    const text =
        \\define i8 @invalid(i8 %input) {
        \\entry:
        \\  ret i8 %input
        \\}
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();
    for ([_][]const u8{ "signext", "zeroext zeroext", "nonnull", "range(i16 0, 8)", "range(i8 5, 5)", "range(i8 0, 256)", "noundef noundef" }) |attrs| {
        var function = module.functions.items[0];
        function.ret_attrs = attrs;
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        try std.testing.expect(try legalization.legalize(arena.allocator(), function) == null);
        try std.testing.expectEqual(@as(u16, 8), function.params.items[0].ty.int);
    }
}

test "narrow ABI retains unsupported extension call convention and intrinsic boundaries" {
    const calls = [_][]const u8{
        "%result = call signext i8 @callee()",
        "%result = call zeroext i32 @callee()",
        "%result = call coldcc i8 @callee()",
        "%result = musttail call i8 @callee()",
        "%result = call i8 (i32, ...) @callee(i32 1)",
        "%result = call i8 @callee(i8 signext 1)",
        "%result = call i8 @callee(i32 zeroext 1)",
        "%result = call i32 @callee()",
        "%result = call i8 @llvm.unknown.i8()",
    };
    for (calls) |call| {
        const text = try std.fmt.allocPrint(std.testing.allocator, "define i32 @caller() {{\nentry:\n  {s}\n  ret i32 0\n}}\n", .{call});
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        try std.testing.expect((try legalization.legalize(arena.allocator(), module.functions.items[0])) == null);
    }
}

test "checked integer pairs boolean calls admit general pointers constants and stack arguments" {
    const cases = [_]struct { signature: []const u8, args: []const u8 }{
        .{ .signature = "ptr", .args = "ptr %p" },
        .{ .signature = "i64", .args = "i64 -1" },
        .{ .signature = "i64, i64, i64, i64, i64, i64, i64, i64", .args = "i64 %a, i64 %b, i64 7, i64 %a, i64 %b, i64 11, i64 %a, i64 %b" },
    };
    for (cases) |case| {
        const text = try std.fmt.allocPrint(std.testing.allocator, "declare i1 @helper({s})\ndefine i64 @caller(ptr %p, i64 %a, i64 %b) {{\nentry:\n" ++
            "  %flag = call i1 @helper({s})\n  %r = zext i1 %flag to i64\n  ret i64 %r\n}}\n", .{ case.signature, case.args });
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        try module.verify();
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        const view = (try legalization.legalize(arena.allocator(), module.functions.items[0])).?;
        try std.testing.expectEqual(@as(u16, 32), view.blocks.items[0].instructions.items[0].kind.call.ret_ty.int);
        try std.testing.expectEqual(@as(u16, 1), module.functions.items[0].blocks.items[0].instructions.items[0].kind.call.ret_ty.int);
        try std.testing.expect(try legalization.legalize(arena.allocator(), view) == null);
        var output = machine.MachineFunction.init("caller", .{ .int = 64 });
        defer output.deinit(std.testing.allocator);
        try std.testing.expectEqual(selector.SelectionResult.selected, try selector.tryLower(std.testing.allocator, &output, module.functions.items[0]));
        try verify.verifyFunction(output);
    }
}

test "checked integer pairs retain the typed boolean stack-object call" {
    const text =
        \\declare i1 @helper(ptr)
        \\define i64 @caller(i64 %a) {
        \\entry:
        \\  %slot = alloca i64, align 8
        \\  store i64 %a, ptr %slot, align 8
        \\  %flag = call i1 @helper(ptr %slot)
        \\  %r = zext i1 %flag to i64
        \\  ret i64 %r
        \\}
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();
    try module.verify();
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    try std.testing.expect(try legalization.legalize(arena.allocator(), module.functions.items[0]) == null);
    var output = machine.MachineFunction.init("caller", .{ .int = 64 });
    defer output.deinit(std.testing.allocator);
    try std.testing.expectEqual(selector.SelectionResult.selected, try selector.tryLower(std.testing.allocator, &output, module.functions.items[0]));
    try verify.verifyFunction(output);
    var calls: usize = 0;
    for (output.instructions.items) |inst| if (inst == .direct_call) {
        try std.testing.expectEqual(ir.Type{ .int = 1 }, inst.direct_call.ret_ty);
        calls += 1;
    };
    try std.testing.expectEqual(@as(usize, 1), calls);
}
