//! Expand scalar saturation and narrow bit permutations into existing integer
//! operations without changing the original function or its ABI.
const std = @import("std");
const Candidate = @import("rewrite_candidate.zig").Candidate;
const ir = @import("../../../ir.zig");
const forms = @import("scalar_forms.zig");
const sysv = @import("../sysv_abi.zig");

const Operation = enum { uadd_sat, usub_sat, reverse, umin, umax, smin, smax };

fn minimumMaximum(op: Operation) bool {
    return op == .umin or op == .umax or op == .smin or op == .smax;
}

fn emit(allocator: std.mem.Allocator, function: ir.Function, block: *ir.BasicBlock, serial: *forms.TemporaryNames, kind: @FieldType(ir.Instruction, "kind")) !ir.Value {
    const name = try forms.temporary(allocator, function, serial);
    try block.instructions.append(allocator, .{ .result = name, .kind = kind });
    return .{ .named = name };
}

fn extend(allocator: std.mem.Allocator, function: ir.Function, block: *ir.BasicBlock, serial: *forms.TemporaryNames, ty: ir.Type, wide: ir.Type, value: ir.Value) !ir.Value {
    if (value == .int) return emit(allocator, function, block, serial, .{ .binary = .{
        .op = .add,
        .ty = wide,
        .lhs = .{ .int = value.int & ((@as(i128, 1) << @as(u7, @intCast(ty.int))) - 1) },
        .rhs = .{ .int = 0 },
    } });
    return emit(allocator, function, block, serial, .{ .cast = .{ .op = .zext, .from_ty = ty, .value = value, .to_ty = wide } });
}

fn operation(call: ir.CallInst) ?Operation {
    if (call.ret_ty != .int or call.ret_ty.int == 0 or call.ret_ty.int > 64 or
        call.callee_value != null or call.inline_asm != null or call.raw_args != null or
        call.operand_bundle != null or call.callee_function_ty != null or call.calling_conv != null or call.ret_attrs != null) return null;
    sysv.rejectUnsupportedCallEnvelope(call) catch return null;
    const bits = call.ret_ty.int;
    for (call.args.items) |arg| {
        if (!arg.ty.eql(call.ret_ty) or arg.attrs != null or (arg.value != .named and arg.value != .int)) return null;
        if (arg.value == .named and std.mem.startsWith(u8, arg.value.named, "@")) return null;
        if (arg.value == .int and (arg.value.int < -(@as(i128, 1) << @as(u7, @intCast(bits - 1))) or
            arg.value.int >= (@as(i128, 1) << @as(u7, @intCast(bits))))) return null;
    }
    var buffer: [64]u8 = undefined;
    for ([_][]const u8{ "uadd.sat", "usub.sat", "bitreverse", "umin", "umax", "smin", "smax" }, [_]Operation{ .uadd_sat, .usub_sat, .reverse, .umin, .umax, .smin, .smax }) |name, op| {
        const spelling = std.fmt.bufPrint(&buffer, "llvm.{s}.i{d}", .{ name, bits }) catch return null;
        if (!std.mem.eql(u8, call.callee, spelling)) continue;
        if (op == .reverse) {
            if (bits == 32 or bits == 64 or call.args.items.len != 1) return null;
        } else if (minimumMaximum(op)) {
            if (bits == 32 or bits == 64 or call.args.items.len != 2) return null;
        } else if ((bits > 32 and bits != 64) or call.args.items.len != 2) return null;
        return op;
    }
    return null;
}

pub fn legalize(allocator: std.mem.Allocator, function: ir.Function) !?ir.Function {
    var candidate = Candidate.init(allocator, function);
    var serial: forms.TemporaryNames = .{};
    defer serial.deinit(allocator);
    for (function.blocks.items, 0..) |original, block_index| {
        var block = original;
        block.instructions = .empty;
        for (original.instructions.items, 0..) |inst, instruction_index| {
            if (!inst.removed and inst.result != null and inst.kind == .call) if (operation(inst.kind.call)) |op| {
                try candidate.begin(&block, block_index, instruction_index);
                const call = inst.kind.call;
                const bits = call.ret_ty.int;
                if (minimumMaximum(op)) {
                    const wide: ir.Type = .{ .int = if (bits < 32) 32 else 64 };
                    const lhs = try extend(allocator, function, &block, &serial, call.ret_ty, wide, call.args.items[0].value);
                    const rhs = try extend(allocator, function, &block, &serial, call.ret_ty, wide, call.args.items[1].value);
                    var compare_lhs = lhs;
                    var compare_rhs = rhs;
                    if (op == .smin or op == .smax) {
                        const sign: ir.Value = .{ .int = @as(i128, 1) << @as(u7, @intCast(bits - 1)) };
                        compare_lhs = try emit(allocator, function, &block, &serial, .{ .binary = .{ .op = .xor, .ty = wide, .lhs = lhs, .rhs = sign } });
                        compare_rhs = try emit(allocator, function, &block, &serial, .{ .binary = .{ .op = .xor, .ty = wide, .lhs = rhs, .rhs = sign } });
                    }
                    const condition = try emit(allocator, function, &block, &serial, .{ .icmp = .{
                        .predicate = .ugt,
                        .operand_ty = wide,
                        .lhs = if (op == .umin or op == .smin) compare_rhs else compare_lhs,
                        .rhs = if (op == .umin or op == .smin) compare_lhs else compare_rhs,
                    } });
                    const selected = try emit(allocator, function, &block, &serial, .{ .select = .{
                        .cond_ty = .{ .int = 1 },
                        .cond = condition,
                        .ty = wide,
                        .true_value = lhs,
                        .false_value = rhs,
                    } });
                    try block.instructions.append(allocator, .{ .result = inst.result, .metadata = inst.metadata, .kind = .{ .cast = .{
                        .op = .trunc,
                        .from_ty = wide,
                        .value = selected,
                        .to_ty = call.ret_ty,
                    } } });
                } else if (op == .reverse) {
                    const wide: ir.Type = .{ .int = if (bits < 32) 32 else 64 };
                    const input = try extend(allocator, function, &block, &serial, call.ret_ty, wide, call.args.items[0].value);
                    const reversed = try forms.temporary(allocator, function, &serial);
                    var extended = call;
                    extended.ret_ty = wide;
                    extended.callee = try std.fmt.allocPrint(allocator, "llvm.bitreverse.i{d}", .{wide.int});
                    extended.args = .empty;
                    try extended.args.append(allocator, .{ .ty = wide, .value = input });
                    try block.instructions.append(allocator, .{ .result = reversed, .kind = .{ .call = extended } });
                    const shifted = try forms.temporary(allocator, function, &serial);
                    try block.instructions.append(allocator, .{ .result = shifted, .kind = .{ .binary = .{
                        .op = .lshr,
                        .ty = wide,
                        .lhs = .{ .named = reversed },
                        .rhs = .{ .int = wide.int - bits },
                    } } });
                    try block.instructions.append(allocator, .{ .result = inst.result, .metadata = inst.metadata, .kind = .{ .cast = .{
                        .op = .trunc,
                        .from_ty = wide,
                        .value = .{ .named = shifted },
                        .to_ty = call.ret_ty,
                    } } });
                } else {
                    const pair_name = try forms.temporary(allocator, function, &serial);
                    const value_name = try forms.temporary(allocator, function, &serial);
                    const flag_name = try forms.temporary(allocator, function, &serial);
                    const pair_type: ir.Type = .{ .aggregate = try std.fmt.allocPrint(allocator, "{{ i{d}, i1 }}", .{bits}) };
                    var checked = call;
                    checked.ret_ty = pair_type;
                    checked.callee = try std.fmt.allocPrint(allocator, "llvm.{s}.with.overflow.i{d}", .{ if (op == .uadd_sat) "uadd" else "usub", bits });
                    try block.instructions.append(allocator, .{ .result = pair_name, .kind = .{ .call = checked } });
                    try block.instructions.append(allocator, .{ .result = value_name, .kind = .{ .extractvalue = .{
                        .aggregate_ty = pair_type,
                        .aggregate = .{ .named = pair_name },
                        .indices = "0",
                        .result_ty = call.ret_ty,
                    } } });
                    try block.instructions.append(allocator, .{ .result = flag_name, .kind = .{ .extractvalue = .{
                        .aggregate_ty = pair_type,
                        .aggregate = .{ .named = pair_name },
                        .indices = "1",
                        .result_ty = .{ .int = 1 },
                    } } });
                    try block.instructions.append(allocator, .{ .result = inst.result, .metadata = inst.metadata, .kind = .{ .select = .{
                        .cond_ty = .{ .int = 1 },
                        .cond = .{ .named = flag_name },
                        .ty = call.ret_ty,
                        .true_value = .{ .int = if (op == .uadd_sat) (@as(i128, 1) << @as(u7, @intCast(bits))) - 1 else 0 },
                        .false_value = .{ .named = value_name },
                    } } });
                }
                continue;
            };
            try candidate.keep(&block, inst);
        }
        try candidate.finishBlock(block);
    }
    return candidate.finish();
}
