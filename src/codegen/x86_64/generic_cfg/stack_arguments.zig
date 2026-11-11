//! Shared LLVM x86-64 integer locations. i128 stays whole and 16-byte aligned;
//! other wide integers use independent words and can split register/stack.
//! SSE and indirect stack-pair envelopes stay separate.
const std = @import("std");
const ir = @import("../../../ir.zig");
const sysv = @import("../sysv_abi.zig");

pub const max_arguments = 32;
pub const max_indirect_arguments = 16;
pub const max_stack_words = max_arguments * 2;

pub const Location = union(enum) {
    sse: usize,
    register: usize,
    pair: usize,
    stack: usize,
    split: struct { register: usize, stack: usize },
};
pub const Layout = struct {
    locations: [max_arguments]Location = undefined,
    count: usize = 0,
    stack_words: usize = 0,
};

pub fn scalar(ty: ir.Type) bool {
    return ty == .ptr or ty.eql(.{ .int = 32 }) or ty.eql(.{ .int = 64 });
}

fn words(ty: ir.Type) ?usize {
    if (ty == .ptr) return 1;
    if (ty != .int or ty.int == 0 or ty.int > 128) return null;
    return if (ty.int <= 64) 1 else 2;
}

/// Consumers still validate types and attributes. A physical layout does not
/// itself legalize a scalar width or an unsupported call envelope.
fn integerLayout(items: anytype) ?Layout {
    if (items.len > max_arguments) return null;
    var result: Layout = .{ .count = items.len };
    var next_register: usize = 0;
    var next_sse: usize = 0;
    for (items, 0..) |item, index| {
        if (sysv.isScalarSseAbiType(item.ty) or sysv.isVector128AbiType(item.ty)) {
            // SSE stack overflow remains a separate, closed contract.
            if (item.abi_x87_memory or next_sse >= 8) return null;
            result.locations[index] = .{ .sse = next_sse };
            next_sse += 1;
            continue;
        }
        const width = words(item.ty) orelse return null;
        if (item.abi_x87_memory) {
            if (!item.ty.eql(.{ .int = 80 }) and !item.ty.eql(.{ .int = 128 })) return null;
            result.stack_words = std.mem.alignForward(usize, result.stack_words, 2);
            result.locations[index] = .{ .stack = result.stack_words };
            result.stack_words += 2;
            continue;
        }
        const split_words = width == 2 and (item.ty.int != 128 or item.abi_split_integer);
        if (next_register + width <= 6) {
            result.locations[index] = if (width == 1) .{ .register = next_register } else .{ .pair = next_register };
            next_register += width;
        } else if (split_words and next_register == 5) {
            result.locations[index] = .{ .split = .{ .register = next_register, .stack = result.stack_words } };
            next_register += 1;
            result.stack_words += 1;
        } else {
            result.stack_words = std.mem.alignForward(usize, result.stack_words, if (split_words) 1 else width);
            result.locations[index] = .{ .stack = result.stack_words };
            result.stack_words += width;
        }
    }
    return result;
}

pub fn parameters(function: ir.Function) ?Layout {
    return integerLayout(function.params.items);
}

pub fn callLayout(call: ir.CallInst) ?Layout {
    if (call.callee_value != null) {
        if (call.args.items.len > max_indirect_arguments) return null;
        var register_words: usize = 0;
        var all_scalar = true;
        for (call.args.items) |arg| {
            if (arg.abi_x87_memory) return null;
            register_words += words(arg.ty) orelse return null;
            all_scalar = all_scalar and scalar(arg.ty);
        }
        // Keep the closed indirect scalar-stack and register-pair bounds.
        if (!all_scalar and register_words > 6) return null;
    }
    return integerLayout(call.args.items);
}

pub fn callCount(call: ir.CallInst) ?usize {
    const layout = callLayout(call) orelse return null;
    return if (layout.stack_words == 0) null else layout.stack_words;
}

pub fn hasParameters(function: ir.Function) bool {
    const layout = parameters(function) orelse return false;
    return layout.stack_words != 0;
}

test "integer stack ABI keeps a whole pair on stack and reuses the last register" {
    var args: [7]ir.CallArg = @splat(.{ .ty = .{ .int = 64 }, .value = .{ .int = 0 } });
    args[5].ty = .{ .int = 128 };
    var call: ir.CallInst = .{ .callee = "callee", .ret_ty = .void, .args = .fromOwnedSlice(&args) };
    const layout = callLayout(call).?;
    try std.testing.expectEqual(@as(usize, 0), layout.locations[5].stack);
    try std.testing.expectEqual(@as(usize, 5), layout.locations[6].register);
    try std.testing.expectEqual(@as(usize, 2), layout.stack_words);
    call.callee_value = .{ .named = "target" };
    try std.testing.expect(callLayout(call) == null);
}

test "integer stack ABI aligns pairs after scalar stack slots and retains indirect limits" {
    var args: [9]ir.CallArg = @splat(.{ .ty = .{ .int = 64 }, .value = .{ .int = 0 } });
    args[7].ty = .{ .int = 128 };
    var call: ir.CallInst = .{ .callee = "callee", .ret_ty = .void, .args = .fromOwnedSlice(&args) };
    const layout = callLayout(call).?;
    try std.testing.expectEqual(@as(usize, 0), layout.locations[6].stack);
    try std.testing.expectEqual(@as(usize, 2), layout.locations[7].stack);
    try std.testing.expectEqual(@as(usize, 4), layout.locations[8].stack);
    try std.testing.expectEqual(@as(usize, 5), layout.stack_words);
    var many: [33]ir.CallArg = @splat(.{ .ty = .{ .int = 64 }, .value = .{ .int = 0 } });
    call.args = .fromOwnedSlice(many[0..32]);
    try std.testing.expectEqual(@as(usize, 26), callLayout(call).?.stack_words);
    call.callee_value = .{ .named = "target" };
    try std.testing.expect(callLayout(call) == null);
    call.args.items = many[0..16];
    try std.testing.expectEqual(@as(usize, 10), callLayout(call).?.stack_words);
    call.callee_value = null;
    call.args.items = &many;
    try std.testing.expect(callLayout(call) == null);
}

test "integer stack ABI retains the source width's independent word locations" {
    var args: [7]ir.CallArg = @splat(.{ .ty = .{ .int = 64 }, .value = .{ .int = 0 } });
    args[5].ty = .{ .int = 65 };
    var call: ir.CallInst = .{ .callee = "callee", .ret_ty = .void, .args = .fromOwnedSlice(&args) };
    const original = callLayout(call).?;
    try std.testing.expectEqual(@as(usize, 5), original.locations[5].split.register);
    try std.testing.expectEqual(@as(usize, 0), original.locations[5].split.stack);
    try std.testing.expectEqual(@as(usize, 1), original.locations[6].stack);
    try std.testing.expectEqual(@as(usize, 2), original.stack_words);
    args[5].ty = .{ .int = 128 };
    args[5].abi_split_integer = true;
    const carrier = callLayout(call).?;
    try std.testing.expectEqual(original.count, carrier.count);
    try std.testing.expectEqual(original.stack_words, carrier.stack_words);
    try std.testing.expectEqualDeep(original.locations[0..args.len], carrier.locations[0..args.len]);
    call.callee_value = .{ .named = "target" };
    try std.testing.expect(callLayout(call) == null);

    var padding: [9]ir.CallArg = @splat(.{ .ty = .{ .int = 64 }, .value = .{ .int = 0 } });
    padding[7].ty = .{ .int = 80 };
    call.callee_value = null;
    call.args = .fromOwnedSlice(&padding);
    const unaligned = callLayout(call).?;
    try std.testing.expectEqual(@as(usize, 1), unaligned.locations[7].stack);
    try std.testing.expectEqual(@as(usize, 3), unaligned.locations[8].stack);
    try std.testing.expectEqual(@as(usize, 4), unaligned.stack_words);
}
