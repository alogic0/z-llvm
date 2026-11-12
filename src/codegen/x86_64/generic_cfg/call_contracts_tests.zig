const std = @import("std");
const ir = @import("../../../ir.zig");
const machine = @import("../machine.zig");
const abi = @import("../sysv_abi.zig");
const selector = @import("../generic_cfg_selector.zig");
const encoding = @import("../../../mc/encoding.zig");

test "call contracts admit exact direct scalar varargs and reject ABI changing forms" {
    const text =
        \\declare i64 @sink(i32, ptr, ...)
        \\define i64 @f(ptr %p, i64 %a) {
        \\entry:
        \\  %r = call i64 (i32, ptr, ...) @sink(i32 7, ptr %p, i64 %a, i32 255, ptr %p)
        \\  ret i64 %r
        \\}
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();
    try module.verify();
    const original = module.functions.items[0].blocks.items[0].instructions.items[0].kind.call;
    try std.testing.expect(abi.isSupportedPointerVariadicCall(original));
    var no_fixed = original;
    no_fixed.callee_function_ty = "(...)";
    try std.testing.expect(abi.isSupportedPointerVariadicCall(no_fixed));
    for ([_]ir.Type{ .void, .ptr, .{ .int = 32 }, .{ .int = 64 } }) |ty| {
        var call = original;
        call.ret_ty = ty;
        try std.testing.expect(abi.isSupportedPointerVariadicCall(call));
    }
    for (0..10) |boundary| {
        var call = original;
        switch (boundary) {
            0 => call.calling_conv = "fastcc",
            1 => call.callee_value = .{ .named = "p" },
            2 => call.ret_ty = .double,
            3 => call.ret_attrs = "signext",
            4 => call.callee_function_ty = "(ptr, i32, ...)",
            5 => call.callee_function_ty = "(i32, ptr, ..., i32)",
            6 => call.callee_function_ty = "(..., ...)",
            7 => call.callee_function_ty = "(i32, ptr, double, ...)",
            8 => call.operand_bundle = "[ \"deopt\"() ]",
            9 => call.raw_args = "i32 7",
            else => unreachable,
        }
        try std.testing.expect(!abi.isSupportedPointerVariadicCall(call));
    }
    var output = machine.MachineFunction.init("f", .{ .int = 64 });
    defer output.deinit(std.testing.allocator);
    try std.testing.expectEqual(selector.SelectionResult.selected, try selector.tryLower(std.testing.allocator, &output, module.functions.items[0]));
    var calls: usize = 0;
    for (output.instructions.items, 0..) |instruction, index| if (instruction == .direct_call) {
        calls += 1;
        try std.testing.expect(index != 0);
        try std.testing.expectEqual(machine.Instruction{ .mov_imm_eax = 0 }, output.instructions.items[index - 1]);
    };
    try std.testing.expectEqual(@as(usize, 1), calls);
    const bytes = try encoding.encodeFunction(std.testing.allocator, output);
    defer std.testing.allocator.free(bytes);
    try std.testing.expect(bytes.len > 0);
}

test "call contracts retain module owned function names and reject missing weak and offset symbols" {
    const text =
        \\declare i64 @external(i64)
        \\define ptr @getter() {
        \\entry:
        \\  ret ptr @callee
        \\}
        \\define internal i64 @callee(i64 %a) {
        \\entry:
        \\  %r = add i64 %a, 1
        \\  ret i64 %r
        \\}
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();
    try module.verify();
    var context: machine.ReadOnlyModuleContext = .{
        .globals = module.globals.items, .named_types = module.named_types.items,
        .target_datalayout = module.target_datalayout,
        .functions = module.functions.items, .declarations = module.declarations.items,
    };
    const local = context.functionAddress("callee").?;
    const external = context.functionAddress("@external").?;
    try std.testing.expect(local.ptr == module.functions.items[1].name.ptr);
    try std.testing.expect(external.ptr == module.declarations.items[0].name.ptr);
    try std.testing.expect(context.functionAddress("unknown") == null);
    module.functions.items[1].linkage = .weak;
    try std.testing.expect(context.functionAddress("callee") == null);
    module.functions.items[1].linkage = .internal;
    module.declarations.items[0].linkage = .extern_weak;
    try std.testing.expect(context.functionAddress("external") == null);
    module.declarations.items[0].linkage = .default;
    for (0..3) |boundary| {
        var output = machine.MachineFunction.init("getter", .ptr);
        defer output.deinit(std.testing.allocator);
        const selected = try selector.tryLowerWithContext(std.testing.allocator, &output, module.functions.items[0], &context);
        if (boundary == 0) {
            try std.testing.expectEqual(selector.SelectionResult.selected, selected);
            try std.testing.expectEqual(@as(usize, 0), module.functions.items[0].blocks.items[0].instructions.items.len);
        } else try std.testing.expect(selected == .unsupported);
        if (boundary == 0) context.functions = &.{};
        if (boundary == 1) {
            context.functions = module.functions.items;
            module.functions.items[0].blocks.items[0].terminator.?.ret.value = .{ .constant_expr = "getelementptr (i8, ptr @callee, i64 1)" };
        }
    }
}
