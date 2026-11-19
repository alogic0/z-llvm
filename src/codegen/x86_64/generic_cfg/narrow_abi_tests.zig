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
        if (std.mem.eql(u8, attrs, "signext")) {
            const view = (try legalization.legalize(arena.allocator(), function)).?;
            try std.testing.expect(view.ret_ty.eql(.{ .int = 32 }) and view.ret_attrs == null);
        } else try std.testing.expect(try legalization.legalize(arena.allocator(), function) == null);
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
        const signed_case = std.mem.eql(u8, call, "%result = call signext i8 @callee()") or std.mem.eql(u8, call, "%result = call i8 @callee(i8 signext 1)");
        try std.testing.expect(((try legalization.legalize(arena.allocator(), module.functions.items[0])) != null) == signed_case);
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

test "internal self musttail becomes verified entry PHIs without changing source" {
    const text = "define internal fastcc i64 @loop(i64 %n,i64 %a,i64 %b) {\nentry:\n %done = icmp eq i64 %n,0\n br i1 %done,label %exit,label %step\nstep:\n %next = sub i64 %n,1\n %answer = musttail call fastcc i64 @loop(i64 %next,i64 %b,i64 %a)\n ret i64 %answer\nexit:\n ret i64 %a\n}\n";
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();
    try module.verify();
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    var before: std.Io.Writer.Allocating = .init(arena.allocator());
    try module.print(&before.writer);
    const source = module.functions.items[0];
    const view = (try legalization.legalizeSelfTail(arena.allocator(), source)).?;
    try std.testing.expectEqual(source.blocks.items.len + 1, view.blocks.items.len);
    for (source.params.items, view.params.items, 0..) |original, incoming, index| {
        try std.testing.expect(!ir.identifiers.eql(original.name, incoming.name));
        const inst = view.blocks.items[1].instructions.items[index];
        try std.testing.expect(inst.kind == .phi);
        try std.testing.expectEqualStrings(original.name, inst.result.?);
        try std.testing.expectEqual(@as(usize, 2), inst.kind.phi.incoming.items.len);
        try std.testing.expectEqualStrings(incoming.name, inst.kind.phi.incoming.items[0].value.named);
    }
    for (view.blocks.items) |block| for (block.instructions.items) |inst| try std.testing.expect(inst.kind != .call);
    var private = module;
    private.functions = try module.functions.clone(arena.allocator());
    private.functions.items[0] = view;
    try private.verify();
    try module.verify();
    var after: std.Io.Writer.Allocating = .init(arena.allocator());
    try module.print(&after.writer);
    try std.testing.expectEqualStrings(before.written(), after.written());
}

test "self tail keeps public floating mismatched and non-tail forms closed" {
    const bodies = [_][]const u8{
        "define i64 @f(i64 %x) {\nentry:\n %r = musttail call i64 @f(i64 %x)\n ret i64 %r\n}\n",
        "define internal float @f(float %x) {\nentry:\n %r = musttail call float @f(float %x)\n ret float %r\n}\n",
        "define internal i64 @f(i64 %x) {\nentry:\n %r = musttail call fastcc i64 @f(i64 %x)\n ret i64 %r\n}\n",
        "define internal i64 @f(i64 %x) {\nentry:\n %r = tail call i64 @f(i64 %x)\n ret i64 %r\n}\n",
        "define internal i64 @f(i64 %x) {\nentry:\n %r = musttail call i64 @f(i64 %x)\n %s = add i64 %r,1\n ret i64 %s\n}\n",
        "declare i64 @g(i64)\ndefine internal i64 @f(i64 %x) {\nentry:\n %r = musttail call i64 @g(i64 %x)\n ret i64 %r\n}\n",
    };
    for (bodies) |text| {
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        try std.testing.expect(try legalization.legalizeSelfTail(arena.allocator(), module.functions.items[0]) == null);
    }
}

test "self musttail precedes scalar retries and retains private loop labels" {
    var module = try ir.Module.parse(std.testing.allocator, "define internal i16 @loop(i64 %n,i16 %x) {\nentry:\n %done = icmp eq i64 %n,0\n br i1 %done,label %exit,label %step\nstep:\n %next = sub i64 %n,1\n %value = add i16 %x,7\n %r = musttail call i16 @loop(i64 %next,i16 %value)\n ret i16 %r\nexit:\n ret i16 %x\n}\n");
    defer module.deinit();
    try module.verify();
    const memory = try compile(module);
    defer std.posix.munmap(memory);
    const function: *const fn (u64, u16) callconv(.c) u16 = @ptrCast(memory.ptr);
    for ([_]u64{ 0, 1, 2, 257, 4097 }) |count| for ([_]u16{ 0, 1, 32767, 65535 }) |value| try std.testing.expectEqual(@as(u16, @truncate(@as(u64, value) + count * 7)), function(count, value));
    try module.verify();
}

test "signed narrow ABI returns the chosen clean signed 32-bit carrier" {
    for ([_]u16{ 8, 16 }) |bits| {
        const text = try std.fmt.allocPrint(std.testing.allocator,
            \\define noundef signext i{0d} @signed_entry(i{0d} noundef signext %input, ptr %out) {{
            \\entry:
            \\ %w = sext i{0d} %input to i64
            \\ store i64 %w,ptr %out,align 8
            \\ ret i{0d} %input
            \\}}
        , .{bits});
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        try module.verify();
        const original = module.functions.items[0];
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        const view = (try legalization.legalize(arena.allocator(), original)).?;
        try std.testing.expect(view.ret_ty.eql(.{ .int = 32 }));
        try std.testing.expect(view.ret_attrs == null and view.params.items[0].attrs == null);
        try std.testing.expectEqualStrings("noundef signext", original.ret_attrs.?);
        try std.testing.expectEqualStrings("noundef signext", original.params.items[0].attrs.?);
        const executable = try compile(module);
        defer std.posix.munmap(executable);
        const run: *const fn (u64, *i64) callconv(.c) u32 = @ptrCast(executable.ptr);
        const mask = (@as(u64, 1) << @intCast(bits)) - 1;
        for ([_]u64{ 0, 1, mask / 2, mask / 2 + 1, mask, 0xdeadbeefcafe1234 }) |input| {
            const payload: i64 = @intCast(input & mask);
            const expected = if (payload & @as(i64, @intCast((mask + 1) / 2)) != 0) payload - @as(i64, @intCast(mask + 1)) else payload;
            var stored: i64 = 0;
            try std.testing.expectEqual(@as(u32, @bitCast(@as(i32, @intCast(expected)))), run(input, &stored));
            try std.testing.expectEqual(expected, stored);
        }
        try module.verify();
    }
}

test "signed narrow ABI extends named and literal outgoing payloads before calls" {
    const text =
        \\declare signext i8 @callee(i8 signext, i16 signext, i8 zeroext)
        \\define signext i8 @caller(i8 signext %a, i16 signext %b) {
        \\entry:
        \\ %r = call signext i8 @callee(i8 signext %a,i16 signext -2,i8 zeroext -1)
        \\ ret i8 %r
        \\}
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();
    try module.verify();
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const original = module.functions.items[0];
    const view = (try legalization.legalize(arena.allocator(), original)).?;
    var calls: usize = 0;
    var extensions: usize = 0;
    for (view.blocks.items) |block| for (block.instructions.items) |inst| {
        if (inst.kind == .cast and inst.kind.cast.op == .sext) extensions += 1;
        if (inst.kind != .call) continue;
        calls += 1;
        const call = inst.kind.call;
        try std.testing.expect(call.ret_ty.eql(.{ .int = 32 }) and call.ret_attrs == null);
        for (call.args.items) |arg| try std.testing.expect(arg.ty.eql(.{ .int = 32 }) and arg.attrs == null);
        try std.testing.expectEqual(@as(i128, -2), call.args.items[1].value.int);
        try std.testing.expectEqual(@as(i128, 255), call.args.items[2].value.int);
    };
    try std.testing.expectEqual(@as(usize, 1), calls);
    try std.testing.expectEqual(@as(usize, 2), extensions);
    try std.testing.expectEqualStrings("signext", original.ret_attrs.?);
    try module.verify();
}

test "signed narrow ABI keeps unproved widths attributes and musttail envelopes closed" {
    for ([_]u16{ 1, 3, 24, 32, 64 }) |bits| {
        const text = try std.fmt.allocPrint(std.testing.allocator,
            \\define signext i{0d} @closed(i{0d} signext %x) {{
            \\entry:
            \\ ret i{0d} %x
            \\}}
        , .{bits});
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        try module.verify();
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        try std.testing.expect((try legalization.legalize(arena.allocator(), module.functions.items[0])) == null);
    }
    var module = try ir.Module.parse(std.testing.allocator,
        \\define signext i8 @closed(i8 signext %x) {
        \\entry:
        \\ %r = musttail call signext i8 @closed(i8 signext %x)
        \\ ret i8 %r
        \\}
    );
    defer module.deinit();
    try module.verify();
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const view = (try legalization.legalize(arena.allocator(), module.functions.items[0])).?;
    const call = view.blocks.items[0].instructions.items[2].kind.call;
    try std.testing.expectEqualStrings("musttail", call.tail_kind.?);
    try std.testing.expectEqualStrings("signext", call.ret_attrs.?);
}

test "signed narrow ABI normalizes before stack signature rejection" {
    const text =
        \\define i64 @stack_entry(i8 signext %a,i8 signext %b,i8 signext %c,i8 signext %d,i8 signext %e,i8 signext %f,i8 signext %g,i8 signext %h,i8 signext %i) {
        \\entry:
        \\ %a0 = sext i8 %a to i64
        \\ %b0 = sext i8 %b to i64
        \\ %c0 = sext i8 %c to i64
        \\ %d0 = sext i8 %d to i64
        \\ %e0 = sext i8 %e to i64
        \\ %f0 = sext i8 %f to i64
        \\ %g0 = sext i8 %g to i64
        \\ %h0 = sext i8 %h to i64
        \\ %i0 = sext i8 %i to i64
        \\ %r0 = add i64 %a0,%b0
        \\ %r1 = add i64 %r0,%c0
        \\ %r2 = add i64 %r1,%d0
        \\ %r3 = add i64 %r2,%e0
        \\ %r4 = add i64 %r3,%f0
        \\ %r5 = add i64 %r4,%g0
        \\ %r6 = add i64 %r5,%h0
        \\ %r7 = add i64 %r6,%i0
        \\ ret i64 %r7
        \\}
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();
    try module.verify();
    const executable = try compile(module);
    defer std.posix.munmap(executable);
    const run: *const fn (u64, u64, u64, u64, u64, u64, u64, u64, u64) callconv(.c) u64 = @ptrCast(executable.ptr);
    try std.testing.expectEqual(@as(u64, 45), run(1, 2, 3, 4, 5, 6, 7, 8, 9));
    try std.testing.expectEqual(@as(u64, @bitCast(@as(i64, -9))), run(0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff));
    try module.verify();
}

test "scalar tail transfer encodes an indirect jump and requires exact restored stack depth" {
    var output = machine.MachineFunction.init("tail", .{ .int = 64 });
    defer output.deinit(std.testing.allocator);
    try output.instructions.appendSlice(std.testing.allocator, &.{ .{ .mov_imm_rax = 1 }, .tail_jump_rax });
    try verify.verifyFunction(output);
    const bytes = try encoding.encodeFunction(std.testing.allocator, output);
    defer std.testing.allocator.free(bytes);
    try std.testing.expectEqualSlices(u8, &.{ 0xff, 0xe0 }, bytes[bytes.len - 2 ..]);
    try output.instructions.insert(std.testing.allocator, 0, .{ .sub_rsp_imm32 = 32 });
    try std.testing.expectError(error.UnbalancedStackFrame, verify.verifyFunction(output));
    output.instructions.items[0] = .{ .sub_rsp_imm32 = 16 };
    try std.testing.expectError(error.UnbalancedStackFrame, verify.verifyFunction(output));
}

test "scalar tail indirect recursion restores its frame for one million transfers" {
    const text =
        \\define internal i64 @indirect_tail(ptr %target,i64 %n,i64 %a) {
        \\entry:
        \\ %done = icmp eq i64 %n,0
        \\ br i1 %done,label %exit,label %step
        \\exit:
        \\ ret i64 %a
        \\step:
        \\ %next = sub i64 %n,1
        \\ %value = add i64 %a,17
        \\ %r = musttail call i64 %target(ptr %target,i64 %next,i64 %value)
        \\ ret i64 %r
        \\}
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();
    try module.verify();
    const executable = try compile(module);
    defer std.posix.munmap(executable);
    const run: *const fn (*const anyopaque, u64, u64) callconv(.c) u64 = @ptrCast(executable.ptr);
    for ([_]u64{ 0, 1, 2, 1000001 }) |n| try std.testing.expectEqual(@as(u64, 31) + n * 17, run(executable.ptr, n, 31));
    try module.verify();
}

test "scalar tail narrow carriers preserve signed arguments and terminal return homes" {
    const text =
        \\declare signext i8 @callee(i8 signext,i16 zeroext)
        \\define internal signext i8 @narrow_tail(i8 signext %a,i16 zeroext %b) {
        \\entry:
        \\ %r = musttail call signext i8 @callee(i8 signext %a,i16 zeroext %b)
        \\ ret i8 %r
        \\}
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();
    try module.verify();
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const original = module.functions.items[0];
    const view = (try legalization.legalizeTail(arena.allocator(), original)).?;
    const block = view.blocks.items[0];
    const last = block.instructions.items[block.instructions.items.len - 1];
    try std.testing.expectEqualStrings("musttail", last.kind.call.tail_kind.?);
    try std.testing.expect(last.kind.call.ret_ty.eql(.{ .int = 32 }));
    try std.testing.expectEqualStrings(last.result.?, block.terminator.?.ret.value.?.named);
    try std.testing.expect(block.terminator.?.ret.ty.eql(.{ .int = 32 }));
    try std.testing.expectEqual(@as(u16, 8), original.ret_ty.int);
    try std.testing.expect((try legalization.legalizeTail(arena.allocator(), view)) == null);
    var output = machine.MachineFunction.init(original.name, original.ret_ty);
    defer output.deinit(std.testing.allocator);
    try std.testing.expectEqual(selector.SelectionResult.selected, try selector.tryLower(std.testing.allocator, &output, original));
    try verify.verifyFunction(output);
    var jumps: usize = 0;
    for (output.instructions.items) |inst| if (inst == .direct_jump) {
        try std.testing.expectEqualStrings("callee", inst.direct_jump);
        jumps += 1;
    };
    try std.testing.expectEqual(@as(usize, 1), jumps);
    try module.verify();
}

test "symbolic musttail proves the original ABI before narrowing and jumps to the complete symbol" {
    const callee = "\"target with spaces\"";
    const gep = "getelementptr inbounds (i8, ptr @" ++ callee ++ ", i64 0)";
    var module = try ir.Module.parse(std.testing.allocator,
        "define internal fastcc void @" ++ callee ++ "(i8 %v) {\nentry:\n ret void\n}\n" ++
            "define internal fastcc void @caller(i8 %v) {\nentry:\n" ++
            " musttail call fastcc void " ++ gep ++ "(i8 %v)\n ret void\n}\n");
    defer module.deinit();
    try module.verify();
    const ctx: machine.ReadOnlyModuleContext = .{
        .globals = module.globals.items,
        .named_types = module.named_types.items,
        .target_datalayout = module.target_datalayout,
        .functions = module.functions.items,
    };
    const original = module.functions.items[1];
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const view = (try legalization.resolveTailSymbols(arena.allocator(), original, &ctx)).?;
    const call = view.blocks.items[0].instructions.items[0].kind.call;
    try std.testing.expectEqualStrings(callee, call.callee);
    try std.testing.expect(call.callee_value == null and call.args.items[0].ty.eql(.{ .int = 8 }));
    try std.testing.expectEqualStrings("musttail", call.tail_kind.?);
    var output = machine.MachineFunction.init(original.name, original.ret_ty);
    defer output.deinit(std.testing.allocator);
    try std.testing.expectEqual(selector.SelectionResult.selected, try selector.tryLowerWithContext(std.testing.allocator, &output, original, &ctx));
    try verify.verifyFunction(output);
    var jumps: usize = 0;
    for (output.instructions.items) |inst| switch (inst) {
        .direct_jump => |name| {
            try std.testing.expectEqualStrings(callee, name);
            jumps += 1;
        },
        .direct_call, .tail_jump_rax => return error.UnexpectedTransfer,
        else => {},
    };
    try std.testing.expectEqual(@as(usize, 1), jumps);
    try std.testing.expectEqualStrings(gep, original.blocks.items[0].instructions.items[0].kind.call.callee_value.?.constant_expr);
    try module.verify();
}

test "symbolic musttail refuses unproved targets and source ABI neighbors" {
    const Case = struct {
        target: []const u8 = "declare fastcc void @target(i8)",
        caller_param: []const u8 = "i8 %v",
        arg: []const u8 = "i8 %v",
        offset: u8 = 0,
        after: []const u8 = "",
    };
    for ([_]Case{
        .{ .offset = 1 },
        .{ .target = "@target = global i8 0" },
        .{ .target = "" },
        .{ .target = "declare extern_weak fastcc void @target(i8)" },
        .{ .target = "declare void @target(i8)" },
        .{ .target = "declare fastcc i8 @target(i8)" },
        .{ .target = "declare fastcc void @target(i8, ...)" },
        .{ .target = "declare fastcc void @target(i8 signext)" },
        .{ .target = "declare fastcc void @target(ptr byval(i8))", .caller_param = "ptr %v", .arg = "ptr %v" },
        .{ .target = "declare fastcc void @target(ptr sret(i8))", .caller_param = "ptr %v", .arg = "ptr %v" },
        .{ .target = "declare fastcc void @target(i32)", .arg = "i32 19" },
        .{ .after = " %other = add i8 %v, 1\n" },
    }) |case| {
        const text = try std.fmt.allocPrint(std.testing.allocator,
            "{s}\ndefine internal fastcc void @caller({s}) {{\nentry:\n musttail call fastcc void getelementptr (i8, ptr @target, i64 {d})({s})\n{s} ret void\n}}\n",
            .{ case.target, case.caller_param, case.offset, case.arg, case.after });
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        const ctx: machine.ReadOnlyModuleContext = .{
            .globals = module.globals.items,
            .named_types = module.named_types.items,
            .target_datalayout = module.target_datalayout,
            .functions = module.functions.items,
            .declarations = module.declarations.items,
        };
        const original = module.functions.items[0];
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        try std.testing.expect((try legalization.resolveTailSymbols(arena.allocator(), original, &ctx)) == null);
        var output = machine.MachineFunction.init(original.name, original.ret_ty);
        defer output.deinit(std.testing.allocator);
        const result = selector.tryLowerWithContext(std.testing.allocator, &output, original, &ctx) catch |err| switch (err) {
            error.UnsupportedTailCallAbi => continue,
            else => return err,
        };
        try std.testing.expect(result == .unsupported);
    }
}

test "scalar tail transfer keeps public floating and seventh-argument boundaries closed" {
    const cases = [_][]const u8{
        "declare i32 @callee(i32)\ndefine i32 @closed(i32 %x) {\nentry:\n %r = musttail call i32 @callee(i32 %x)\n ret i32 %r\n}\n",
        "declare float @callee(float)\ndefine internal float @closed(float %x) {\nentry:\n %r = musttail call float @callee(float %x)\n ret float %r\n}\n",
        "declare i32 @callee(i32,i32,i32,i32,i32,i32,i32)\ndefine internal i32 @closed(i32 %a,i32 %b,i32 %c,i32 %d,i32 %e,i32 %f,i32 %g) {\nentry:\n %r = musttail call i32 @callee(i32 %a,i32 %b,i32 %c,i32 %d,i32 %e,i32 %f,i32 %g)\n ret i32 %r\n}\n",
    };
    for (cases) |text| {
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        try module.verify();
        var output = machine.MachineFunction.init("closed", module.functions.items[0].ret_ty);
        defer output.deinit(std.testing.allocator);
        const selected = selector.tryLower(std.testing.allocator, &output, module.functions.items[0]) catch |err| switch (err) {
            error.UnsupportedTailCallAbi => continue,
            else => return err,
        };
        try std.testing.expect(selected == .unsupported);
    }
}
