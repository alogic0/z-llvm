//! Private scalar forms for full-word division and min/max intrinsics.
const std = @import("std");
const Candidate = @import("rewrite_candidate.zig").Candidate;
const ir = @import("../../../ir.zig");
const forms = @import("scalar_forms.zig");
const sysv = @import("../sysv_abi.zig");

fn integer(ty: ir.Type) bool {
    return ty.eql(.{ .int = 32 }) or ty.eql(.{ .int = 64 });
}

fn operand(value: ir.Value, bits: u16) bool {
    if (value == .named) return !std.mem.startsWith(u8, value.named, "@");
    if (value != .int) return false;
    return value.int >= -(@as(i128, 1) << @as(u7, @intCast(bits - 1))) and
        value.int < (@as(i128, 1) << @as(u7, @intCast(bits)));
}

fn literal(allocator: std.mem.Allocator, function: ir.Function, block: *ir.BasicBlock, serial: *forms.TemporaryNames, ty: ir.Type, value: ir.Value) !ir.Value {
    if (value == .named) return value;
    const name = try forms.temporary(allocator, function, serial);
    try block.instructions.append(allocator, .{ .result = name, .kind = .{ .binary = .{ .op = .add, .ty = ty, .lhs = value, .rhs = .{ .int = 0 } } } });
    return .{ .named = name };
}

fn minMax(call: ir.CallInst) ?ir.IcmpPredicate {
    if (!integer(call.ret_ty) or call.callee_value != null or call.inline_asm != null or call.raw_args != null or
        call.operand_bundle != null or call.callee_function_ty != null or call.calling_conv != null or
        call.ret_attrs != null or call.args.items.len != 2) return null;
    sysv.rejectUnsupportedCallEnvelope(call) catch return null;
    for (call.args.items) |arg| if (!arg.ty.eql(call.ret_ty) or arg.attrs != null or !operand(arg.value, call.ret_ty.int)) return null;
    var buffer: [40]u8 = undefined;
    for ([_][]const u8{ "umax", "smin", "smax" }, [_]ir.IcmpPredicate{ .ugt, .slt, .sgt }) |name, predicate| {
        const spelling = std.fmt.bufPrint(&buffer, "llvm.{s}.i{d}", .{ name, call.ret_ty.int }) catch return null;
        if (std.mem.eql(u8, call.callee, spelling)) return predicate;
    }
    return null;
}

fn constantProduct(call: ir.CallInst) bool {
    if (!std.mem.eql(u8, call.callee, "llvm.umul.with.overflow.i64") and !std.mem.eql(u8, call.callee, "llvm.smul.with.overflow.i64")) return false;
    if (call.ret_ty != .aggregate or call.callee_value != null or call.inline_asm != null or call.raw_args != null or
        call.operand_bundle != null or call.callee_function_ty != null or call.calling_conv != null or call.ret_attrs != null or call.args.items.len != 2) return false;
    sysv.rejectUnsupportedCallEnvelope(call) catch return false;
    if (!@import("word_pair_memory.zig").spelling(call.ret_ty.aggregate, "{i64,i1}")) return false;
    for (call.args.items) |arg| if (!arg.ty.eql(.{ .int = 64 }) or arg.attrs != null or !operand(arg.value, 64)) return false;
    return call.args.items[0].value == .int or call.args.items[1].value == .int;
}

pub fn legalize(allocator: std.mem.Allocator, function: ir.Function) !?ir.Function {
    var candidate = Candidate.init(allocator, function);
    var serial: forms.TemporaryNames = .{};
    defer serial.deinit(allocator);
    for (function.blocks.items, 0..) |original, block_index| {
        var block = original;
        block.instructions = .empty;
        for (original.instructions.items, 0..) |inst, instruction_index| {
            if (!inst.removed and inst.result != null) {
                if (inst.kind == .binary) {
                    var binary = inst.kind.binary;
                    if (integer(binary.ty) and (binary.op == .udiv or binary.op == .urem) and
                        operand(binary.lhs, binary.ty.int) and operand(binary.rhs, binary.ty.int) and
                        (binary.lhs == .int or binary.rhs == .int))
                    {
                        const mask = (@as(i128, 1) << @as(u7, @intCast(binary.ty.int))) - 1;
                        const divisor = if (binary.rhs == .int) binary.rhs.int & mask else null;
                        // Leave zero-divisor UB and the already admitted power-of-two
                        // remainder action under their existing boundaries.
                        if (divisor == null or (divisor.? != 0 and (binary.op != .urem or !std.math.isPowerOfTwo(@as(u128, @intCast(divisor.?)))))) {
                            try candidate.begin(&block, block_index, instruction_index);
                            binary.lhs = try literal(allocator, function, &block, &serial, binary.ty, binary.lhs);
                            binary.rhs = try literal(allocator, function, &block, &serial, binary.ty, binary.rhs);
                            var copy = inst;
                            copy.kind.binary = binary;
                            try block.instructions.append(allocator, copy);
                            continue;
                        }
                    }
                } else if (inst.kind == .call and constantProduct(inst.kind.call)) {
                    try candidate.begin(&block, block_index, instruction_index);
                    var copy = inst;
                    copy.kind.call.args = try inst.kind.call.args.clone(allocator);
                    for (copy.kind.call.args.items) |*arg| arg.value = try literal(allocator, function, &block, &serial, arg.ty, arg.value);
                    try block.instructions.append(allocator, copy);
                    continue;
                } else if (inst.kind == .call) if (minMax(inst.kind.call)) |predicate| {
                    try candidate.begin(&block, block_index, instruction_index);
                    const call = inst.kind.call;
                    const lhs = try literal(allocator, function, &block, &serial, call.ret_ty, call.args.items[0].value);
                    const rhs = try literal(allocator, function, &block, &serial, call.ret_ty, call.args.items[1].value);
                    const condition = try forms.temporary(allocator, function, &serial);
                    try block.instructions.append(allocator, .{ .result = condition, .kind = .{ .icmp = .{
                        .predicate = predicate,
                        .operand_ty = call.ret_ty,
                        .lhs = lhs,
                        .rhs = rhs,
                    } } });
                    try block.instructions.append(allocator, .{ .result = inst.result, .metadata = inst.metadata, .kind = .{ .select = .{
                        .cond_ty = .{ .int = 1 },
                        .cond = .{ .named = condition },
                        .ty = call.ret_ty,
                        .true_value = lhs,
                        .false_value = rhs,
                    } } });
                    continue;
                };
            }
            try candidate.keep(&block, inst);
        }
        try candidate.finishBlock(block);
    }
    return candidate.finish();
}
