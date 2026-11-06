//! Private scalar expansions reuse the selector's ordinary compare/select and
//! memory paths. The caller owns an arena; the original IR is never changed.
const std = @import("std");
const ir = @import("../../../ir.zig");
const sysv = @import("../sysv_abi.zig");

pub fn temporary(allocator: std.mem.Allocator, function: ir.Function, serial: *usize) ![]const u8 {
    while (true) {
        const name = try std.fmt.allocPrint(allocator, "__zllvm_scalar_form_{d}", .{serial.*});
        serial.* += 1;
        var collision = false;
        for (function.params.items) |param| if (ir.identifiers.eql(param.name, name)) {
            collision = true;
        };
        for (function.blocks.items) |block| {
            if (ir.identifiers.eql(block.name, name)) collision = true;
            for (block.instructions.items) |inst| if (inst.result) |result| {
                if (ir.identifiers.eql(result, name)) collision = true;
            };
        }
        if (!collision) return name;
        allocator.free(name);
    }
}

fn unsignedMin(call: ir.CallInst) bool {
    const bits: u16 = if (std.mem.eql(u8, call.callee, "llvm.umin.i64")) 64 else if (std.mem.eql(u8, call.callee, "llvm.umin.i32")) 32 else return false;
    if (call.callee_value != null or call.inline_asm != null or call.raw_args != null or
        call.operand_bundle != null or call.callee_function_ty != null or call.calling_conv != null or
        call.ret_attrs != null or call.args.items.len != 2 or !call.ret_ty.eql(.{ .int = bits })) return false;
    sysv.rejectUnsupportedCallEnvelope(call) catch return false;
    for (call.args.items) |arg| if (!arg.ty.eql(call.ret_ty) or arg.attrs != null or
        (arg.value != .named and arg.value != .int)) return false;
    return call.args.items[0].value == .named or call.args.items[1].value == .named;
}

fn signedLe(icmp: ir.IcmpInst) bool {
    return !icmp.samesign and icmp.predicate == .sle and
        (icmp.operand_ty.eql(.{ .int = 32 }) or icmp.operand_ty.eql(.{ .int = 64 })) and
        icmp.lhs == .named and (icmp.rhs == .named or icmp.rhs == .int);
}

fn unsignedSaturatingSub(call: ir.CallInst) bool {
    const bits: u16 = if (std.mem.eql(u8, call.callee, "llvm.usub.sat.i64")) 64 else if (std.mem.eql(u8, call.callee, "llvm.usub.sat.i32")) 32 else return false;
    if (call.callee_value != null or call.inline_asm != null or call.raw_args != null or
        call.operand_bundle != null or call.callee_function_ty != null or call.calling_conv != null or
        call.ret_attrs != null or call.args.items.len != 2 or !call.ret_ty.eql(.{ .int = bits })) return false;
    sysv.rejectUnsupportedCallEnvelope(call) catch return false;
    for (call.args.items) |arg| if (!arg.ty.eql(call.ret_ty) or arg.attrs != null or arg.value != .named) return false;
    return true;
}

pub fn legalize(allocator: std.mem.Allocator, function: ir.Function) !?ir.Function {
    var result = function;
    result.blocks = .empty;
    var changed = false;
    var serial: usize = 0;
    for (function.blocks.items) |original| {
        var block = original;
        block.instructions = .empty;
        for (original.instructions.items) |inst| {
            if (!inst.removed and inst.result != null) switch (inst.kind) {
                .call => |call| if (unsignedMin(call)) {
                    const condition = try temporary(allocator, function, &serial);
                    const swapped = call.args.items[0].value == .int;
                    const lhs = call.args.items[@intFromBool(swapped)].value;
                    const rhs = call.args.items[@intFromBool(!swapped)].value;
                    try block.instructions.append(allocator, .{ .result = condition, .kind = .{ .icmp = .{
                        .predicate = .ult,
                        .operand_ty = call.ret_ty,
                        .lhs = lhs,
                        .rhs = rhs,
                    } } });
                    try block.instructions.append(allocator, .{ .result = inst.result, .kind = .{ .select = .{
                        .cond_ty = .{ .int = 1 },
                        .cond = .{ .named = condition },
                        .ty = call.ret_ty,
                        .true_value = lhs,
                        .false_value = rhs,
                    } } });
                    changed = true;
                    continue;
                } else if (unsignedSaturatingSub(call)) {
                    const condition = try temporary(allocator, function, &serial);
                    const difference = try temporary(allocator, function, &serial);
                    const lhs = call.args.items[0].value;
                    const rhs = call.args.items[1].value;
                    try block.instructions.append(allocator, .{ .result = condition, .kind = .{ .icmp = .{
                        .predicate = .ult,
                        .operand_ty = call.ret_ty,
                        .lhs = lhs,
                        .rhs = rhs,
                    } } });
                    // Wrapping subtraction is defined even on the discarded
                    // underflow arm; attaching nuw here would create poison.
                    try block.instructions.append(allocator, .{ .result = difference, .kind = .{ .binary = .{
                        .op = .sub,
                        .ty = call.ret_ty,
                        .lhs = lhs,
                        .rhs = rhs,
                    } } });
                    try block.instructions.append(allocator, .{ .result = inst.result, .kind = .{ .select = .{
                        .cond_ty = .{ .int = 1 },
                        .cond = .{ .named = condition },
                        .ty = call.ret_ty,
                        .true_value = .{ .int = 0 },
                        .false_value = .{ .named = difference },
                    } } });
                    changed = true;
                    continue;
                },
                .icmp => |icmp| if (!icmp.samesign and
                    (icmp.predicate == .eq or icmp.predicate == .ne) and
                    (((icmp.operand_ty.eql(.{ .int = 32 }) or icmp.operand_ty.eql(.{ .int = 64 })) and icmp.lhs == .int) or
                        (icmp.operand_ty == .ptr and icmp.lhs == .null_value)) and icmp.rhs == .named)
                {
                    var comparison = inst;
                    comparison.kind.icmp.lhs = icmp.rhs;
                    comparison.kind.icmp.rhs = icmp.lhs;
                    try block.instructions.append(allocator, comparison);
                    changed = true;
                    continue;
                } else if (signedLe(icmp)) {
                    var comparison = inst;
                    comparison.result = try temporary(allocator, function, &serial);
                    comparison.kind.icmp.predicate = .sgt;
                    try block.instructions.append(allocator, comparison);
                    try block.instructions.append(allocator, .{ .result = inst.result, .kind = .{ .binary = .{
                        .op = .xor,
                        .ty = .{ .int = 1 },
                        .lhs = .{ .named = comparison.result.? },
                        .rhs = .{ .int = 1 },
                    } } });
                    changed = true;
                    continue;
                },
                else => {},
            };
            try block.instructions.append(allocator, inst);
        }
        try result.blocks.append(allocator, block);
    }
    return if (changed) result else null;
}
