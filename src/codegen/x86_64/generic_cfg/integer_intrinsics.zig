//! Expand scalar saturation and narrow bit permutations into existing integer
//! operations without changing the original function or its ABI.
const std = @import("std");
const Candidate = @import("rewrite_candidate.zig").Candidate;
const ir = @import("../../../ir.zig");
const forms = @import("scalar_forms.zig");
const intrinsic_attrs = @import("intrinsic_attrs.zig");
const bit_intrinsics = @import("integer_bit_intrinsics.zig");

const PairOperation = enum { uadd, usub, sadd, ssub, smin, smax };
fn pairOperation(call: ir.CallInst) ?PairOperation {
    if (!call.ret_ty.eql(.{ .int = 128 }) or call.args.items.len != 2 or !intrinsic_attrs.scalarIntegerCallSupported(call)) return null;
    for (call.args.items) |arg| if (!arg.ty.eql(call.ret_ty) or (arg.value != .named and arg.value != .int) or (arg.value == .named and std.mem.startsWith(u8, arg.value.named, "@"))) return null;
    var buffer: [64]u8 = undefined;
    for (std.enums.values(PairOperation)) |op| {
        const name = @tagName(op);
        const sat = op == .uadd or op == .usub or op == .sadd or op == .ssub;
        const spelling = std.fmt.bufPrint(&buffer, "llvm.{s}{s}.i128", .{ name, if (sat) ".sat" else "" }) catch return null;
        if (std.mem.eql(u8, spelling, call.callee)) return op;
    }
    return null;
}

fn expandPair(allocator: std.mem.Allocator, function: ir.Function, block: *ir.BasicBlock, serial: *forms.TemporaryNames, inst: ir.Instruction, op: PairOperation) !void {
    const pair: ir.Type = .{ .int = 128 };
    const word: ir.Type = .{ .int = 64 };
    const boolean: ir.Type = .{ .int = 1 };
    var values: [2]ir.Value = undefined;
    for (&values, inst.kind.call.args.items) |*value, arg| value.* = if (arg.value == .int)
        try @import("binary128_arithmetic.zig").materializeIntegerArgument(allocator, function, block, serial, .{ .op = .uitofp, .from_ty = pair, .value = arg.value, .to_ty = .fp128 })
    else
        arg.value;
    const x = values[0];
    const y = values[1];
    var answer: ir.Value = undefined;
    if (op == .smin or op == .smax) {
        const minimum = op == .smin;
        const less = try emit(allocator, function, block, serial, .{ .icmp = .{ .predicate = .slt, .operand_ty = pair, .lhs = if (minimum) x else y, .rhs = if (minimum) y else x } });
        answer = try emit(allocator, function, block, serial, .{ .select = .{ .cond_ty = boolean, .cond = less, .ty = pair, .true_value = x, .false_value = y } });
    } else {
        const subtract = op == .usub or op == .ssub;
        const signed = op == .sadd or op == .ssub;
        const wrapped = try emit(allocator, function, block, serial, .{ .binary = .{ .op = if (subtract) .sub else .add, .ty = pair, .lhs = x, .rhs = y } });
        var overflow: ir.Value = undefined;
        var limit: ir.Value = undefined;
        if (!signed) {
            overflow = try emit(allocator, function, block, serial, .{ .icmp = .{ .predicate = .ult, .operand_ty = pair, .lhs = if (subtract) x else wrapped, .rhs = if (subtract) y else x } });
            limit = .{ .int = if (subtract) 0 else -1 };
        } else {
            const first = try emit(allocator, function, block, serial, .{ .binary = .{ .op = .xor, .ty = pair, .lhs = x, .rhs = if (subtract) y else wrapped } });
            const second = try emit(allocator, function, block, serial, .{ .binary = .{ .op = .xor, .ty = pair, .lhs = if (subtract) x else y, .rhs = wrapped } });
            const both = try emit(allocator, function, block, serial, .{ .binary = .{ .op = .@"and", .ty = pair, .lhs = first, .rhs = second } });
            const high = try emit(allocator, function, block, serial, .{ .binary = .{ .op = .lshr, .ty = pair, .lhs = both, .rhs = .{ .int = 64 } } });
            const sign = try emit(allocator, function, block, serial, .{ .cast = .{ .op = .trunc, .from_ty = pair, .value = high, .to_ty = word } });
            overflow = try emit(allocator, function, block, serial, .{ .icmp = .{ .predicate = .slt, .operand_ty = word, .lhs = sign, .rhs = .{ .int = 0 } } });
            const xhigh = try emit(allocator, function, block, serial, .{ .binary = .{ .op = .lshr, .ty = pair, .lhs = x, .rhs = .{ .int = 64 } } });
            const xsign = try emit(allocator, function, block, serial, .{ .cast = .{ .op = .trunc, .from_ty = pair, .value = xhigh, .to_ty = word } });
            const negative = try emit(allocator, function, block, serial, .{ .icmp = .{ .predicate = .slt, .operand_ty = word, .lhs = xsign, .rhs = .{ .int = 0 } } });
            limit = try emit(allocator, function, block, serial, .{ .select = .{ .cond_ty = boolean, .cond = negative, .ty = pair, .true_value = .{ .int = std.math.minInt(i128) }, .false_value = .{ .int = std.math.maxInt(i128) } } });
        }
        answer = try emit(allocator, function, block, serial, .{ .select = .{ .cond_ty = boolean, .cond = overflow, .ty = pair, .true_value = limit, .false_value = wrapped } });
    }
    try block.instructions.append(allocator, .{ .result = inst.result, .metadata = inst.metadata, .kind = .{ .binary = .{ .op = .@"or", .ty = pair, .lhs = answer, .rhs = .{ .int = 0 } } } });
}

const Operation = enum { uadd_sat, usub_sat, ushl_one, sadd_sat, ssub_sat, scmp, ucmp, reverse, umin, umax, smin, smax };

fn minimumMaximum(op: Operation) bool {
    return op == .umin or op == .umax or op == .smin or op == .smax;
}

fn emit(allocator: std.mem.Allocator, function: ir.Function, block: *ir.BasicBlock, serial: *forms.TemporaryNames, kind: @FieldType(ir.Instruction, "kind")) !ir.Value {
    const name = try forms.temporary(allocator, function, serial);
    try block.instructions.append(allocator, .{ .result = name, .kind = kind });
    return .{ .named = name };
}

fn extend(allocator: std.mem.Allocator, function: ir.Function, block: *ir.BasicBlock, serial: *forms.TemporaryNames, ty: ir.Type, wide: ir.Type, value: ir.Value) !ir.Value {
    if (value == .int and ty.eql(.{ .int = 128 })) return @import("binary128_arithmetic.zig").materializeIntegerArgument(allocator, function, block, serial, .{ .op = .uitofp, .from_ty = ty, .value = value, .to_ty = .fp128 });
    if (value == .int) return emit(allocator, function, block, serial, .{ .binary = .{
        .op = .add,
        .ty = wide,
        .lhs = .{ .int = value.int & ((@as(i128, 1) << @as(u7, @intCast(ty.int))) - 1) },
        .rhs = .{ .int = 0 },
    } });
    if (ty.eql(wide)) return value;
    return emit(allocator, function, block, serial, .{ .cast = .{ .op = .zext, .from_ty = ty, .value = value, .to_ty = wide } });
}

fn signedExtend(allocator: std.mem.Allocator, function: ir.Function, block: *ir.BasicBlock, serial: *forms.TemporaryNames, ty: ir.Type, wide: ir.Type, value: ir.Value) !ir.Value {
    if (value == .int) {
        const modulus = @as(i128, 1) << @as(u7, @intCast(ty.int));
        const raw = value.int & (modulus - 1);
        return emit(allocator, function, block, serial, .{ .binary = .{
            .op = .add,
            .ty = wide,
            .lhs = .{ .int = if (raw >= @divExact(modulus, 2)) raw - modulus else raw },
            .rhs = .{ .int = 0 },
        } });
    }
    return emit(allocator, function, block, serial, .{ .cast = .{ .op = .sext, .from_ty = ty, .value = value, .to_ty = wide } });
}

fn fixedMultiply(call: ir.CallInst) bool {
    if (!intrinsic_attrs.scalarIntegerCallSupported(call) or call.ret_ty.int > 64 or call.args.items.len != 3) return false;
    var buffer: [64]u8 = undefined;
    const named = for ([_][]const u8{ "umul", "smul" }) |name| {
        const spelling = std.fmt.bufPrint(&buffer, "llvm.{s}.fix.sat.i{d}", .{ name, call.ret_ty.int }) catch return false;
        if (std.mem.eql(u8, call.callee, spelling)) break true;
    } else false;
    if (!named) return false;
    const sem = @import("../../../analysis/integer_semantics.zig").Integer.init(call.ret_ty) orelse return false;
    for (call.args.items[0..2]) |arg| {
        if (!arg.ty.eql(call.ret_ty) or (arg.value != .named and arg.value != .int)) return false;
        if (arg.value == .named and std.mem.startsWith(u8, arg.value.named, "@")) return false;
        if (arg.value == .int and (arg.value.int < sem.signedMin() or arg.value.int > sem.unsignedMax())) return false;
    }
    const scale = call.args.items[2];
    return scale.ty.eql(.{ .int = 32 }) and scale.value == .int and scale.value.int == 0;
}

fn saturatingShift(call: ir.CallInst) ?bool {
    if (!intrinsic_attrs.scalarIntegerCallSupported(call) or call.ret_ty.int == 0 or
        call.ret_ty.int > 64 or call.args.items.len != 2) return null;
    var buffer: [64]u8 = undefined;
    const signed = for ([_][]const u8{ "ushl", "sshl" }, [_]bool{ false, true }) |name, sign| {
        const spelling = std.fmt.bufPrint(&buffer, "llvm.{s}.sat.i{d}", .{ name, call.ret_ty.int }) catch return null;
        if (std.mem.eql(u8, call.callee, spelling)) break sign;
    } else return null;
    // Retain the established doubling expansion and its artifact contract.
    if (!signed and call.ret_ty.int == 64 and call.args.items[1].value == .int and call.args.items[1].value.int == 1) return null;
    const sem = @import("../../../analysis/integer_semantics.zig").Integer.init(call.ret_ty) orelse return null;
    for (call.args.items) |arg| {
        if (!arg.ty.eql(call.ret_ty) or (arg.value != .named and arg.value != .int)) return null;
        if (arg.value == .named and std.mem.startsWith(u8, arg.value.named, "@")) return null;
        if (arg.value == .int and (arg.value.int < sem.signedMin() or arg.value.int > sem.unsignedMax())) return null;
    }
    return signed;
}

fn expandSaturatingShift(allocator: std.mem.Allocator, function: ir.Function, block: *ir.BasicBlock, serial: *forms.TemporaryNames, inst: ir.Instruction, signed: bool) !void {
    const call = inst.kind.call;
    const bits = call.ret_ty.int;
    const wide: ir.Type = .{ .int = if (bits <= 32) 64 else 128 };
    const x = if (signed)
        try signedExtend(allocator, function, block, serial, call.ret_ty, wide, call.args.items[0].value)
    else
        try extend(allocator, function, block, serial, call.ret_ty, wide, call.args.items[0].value);
    const amount = try extend(allocator, function, block, serial, call.ret_ty, wide, call.args.items[1].value);
    const valid = try emit(allocator, function, block, serial, .{ .icmp = .{ .predicate = .ult, .operand_ty = wide, .lhs = amount, .rhs = .{ .int = bits } } });
    // The LLVM intrinsic is poison for an out-of-range amount. Select zero
    // privately so an unselected poison result never introduces a new trap.
    const safe = try emit(allocator, function, block, serial, .{ .select = .{ .cond_ty = .{ .int = 1 }, .cond = valid, .ty = wide, .true_value = amount, .false_value = .{ .int = 0 } } });
    const shifted = try emit(allocator, function, block, serial, .{ .binary = .{ .op = .shl, .ty = wide, .lhs = x, .rhs = safe } });
    const minimum: i128 = if (signed) -(@as(i128, 1) << @as(u7, @intCast(bits - 1))) else 0;
    const maximum: i128 = if (signed) -minimum - 1 else (@as(i128, 1) << @as(u7, @intCast(bits))) - 1;
    const below = try emit(allocator, function, block, serial, .{ .icmp = .{ .predicate = .slt, .operand_ty = wide, .lhs = shifted, .rhs = .{ .int = minimum } } });
    const lower = try emit(allocator, function, block, serial, .{ .select = .{ .cond_ty = .{ .int = 1 }, .cond = below, .ty = wide, .true_value = .{ .int = minimum }, .false_value = shifted } });
    const above = try emit(allocator, function, block, serial, .{ .icmp = .{ .predicate = if (signed) .sgt else .ugt, .operand_ty = wide, .lhs = lower, .rhs = .{ .int = maximum } } });
    const clamped = try emit(allocator, function, block, serial, .{ .select = .{ .cond_ty = .{ .int = 1 }, .cond = above, .ty = wide, .true_value = .{ .int = maximum }, .false_value = lower } });
    try block.instructions.append(allocator, .{ .result = inst.result, .metadata = inst.metadata, .kind = .{ .cast = .{ .op = .trunc, .from_ty = wide, .value = clamped, .to_ty = call.ret_ty } } });
}

fn operation(call: ir.CallInst) ?Operation {
    if (!std.mem.startsWith(u8, call.callee, "llvm.") or
        !intrinsic_attrs.scalarIntegerCallSupported(call) or (call.ret_ty.int > 64 and call.ret_ty.int != 96 and call.ret_ty.int != 128)) return null;
    const bits = call.ret_ty.int;
    // Comparison intrinsics overload the result and operand widths separately.
    // These scalar forms return -1, 0 or 1 in i32, irrespective of input width.
    if (bits == 32 and call.args.items.len == 2 and call.args.items[0].ty == .int and
        (call.args.items[0].ty.int == 32 or call.args.items[0].ty.int == 64) and call.args.items[1].ty.eql(call.args.items[0].ty))
    {
        const operand_bits = call.args.items[0].ty.int;
        var spelling_buffer: [64]u8 = undefined;
        for ([_][]const u8{ "scmp", "ucmp" }, [_]Operation{ .scmp, .ucmp }) |name, op| {
            const spelling = std.fmt.bufPrint(&spelling_buffer, "llvm.{s}.i32.i{d}", .{ name, operand_bits }) catch return null;
            if (!std.mem.eql(u8, call.callee, spelling)) continue;
            for (call.args.items) |arg| {
                if (arg.value != .named and arg.value != .int) return null;
                if (arg.value == .named and std.mem.startsWith(u8, arg.value.named, "@")) return null;
                if (arg.value == .int and (arg.value.int < -(@as(i128, 1) << @as(u7, @intCast(operand_bits - 1))) or arg.value.int >= (@as(i128, 1) << @as(u7, @intCast(operand_bits))))) return null;
            }
            return op;
        }
    }
    for (call.args.items) |arg| {
        if (!arg.ty.eql(call.ret_ty) or (arg.value != .named and arg.value != .int)) return null;
        if (arg.value == .named and std.mem.startsWith(u8, arg.value.named, "@")) return null;
        if (arg.value == .int and bits < 128 and (arg.value.int < -(@as(i128, 1) << @as(u7, @intCast(bits - 1))) or
            arg.value.int >= (@as(i128, 1) << @as(u7, @intCast(bits))))) return null;
    }
    var buffer: [64]u8 = undefined;
    for ([_][]const u8{ "uadd.sat", "usub.sat", "ushl.sat", "sadd.sat", "ssub.sat", "scmp.i32", "bitreverse", "umin", "umax", "smin", "smax" }, [_]Operation{ .uadd_sat, .usub_sat, .ushl_one, .sadd_sat, .ssub_sat, .scmp, .reverse, .umin, .umax, .smin, .smax }) |name, op| {
        const spelling = std.fmt.bufPrint(&buffer, "llvm.{s}.i{d}", .{ name, bits }) catch return null;
        if (!std.mem.eql(u8, call.callee, spelling)) continue;
        if (bits > 64 and op != .sadd_sat and op != .ssub_sat and !(bits == 128 and (op == .umin or op == .umax))) return null;
        if (op == .reverse) {
            if (bits == 64 or call.args.items.len != 1) return null;
        } else if (op == .ushl_one) {
            if (bits != 64 or call.args.items.len != 2 or call.args.items[1].value != .int or call.args.items[1].value.int != 1) return null;
        } else if (op == .ssub_sat or op == .sadd_sat) {
            if (call.args.items.len != 2) return null;
            switch (bits) {
                1...64 => if (bits == 51 or bits == 52) return null,
                96 => {},
                else => return null,
            }
        } else if (op == .scmp) {
            if (bits != 32 or call.args.items.len != 2) return null;
        } else if (minimumMaximum(op)) {
            if (call.args.items.len != 2) return null;
            if (bits == 32 or bits == 64) {
                var facts = call.ret_attrs != null;
                for (call.args.items) |arg| facts = facts or arg.attrs != null;
                if (!facts) return null;
            }
        } else if ((bits > 32 and bits != 40 and bits != 48 and bits != 56 and bits != 64) or call.args.items.len != 2) return null;
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
            if (!inst.removed and inst.result != null and inst.kind == .call) if (pairExtendedOperation(inst.kind.call)) |op| {
                try candidate.begin(&block, block_index, instruction_index);
                try expandPairExtended(allocator, function, &block, &serial, inst, op);
                continue;
            };
            if (!inst.removed and inst.result != null and inst.kind == .call) if (pairOperation(inst.kind.call)) |op| {
                try candidate.begin(&block, block_index, instruction_index);
                try expandPair(allocator, function, &block, &serial, inst, op);
                continue;
            };
            if (!inst.removed and inst.result != null and inst.kind == .call) if (saturatingShift(inst.kind.call)) |signed| {
                try candidate.begin(&block, block_index, instruction_index);
                try expandSaturatingShift(allocator, function, &block, &serial, inst, signed);
                continue;
            };
            if (!inst.removed and inst.result != null and inst.kind == .call and fixedMultiply(inst.kind.call)) {
                try candidate.begin(&block, block_index, instruction_index);
                const call = inst.kind.call;
                const signed = std.mem.startsWith(u8, call.callee, "llvm.smul.");
                const bits = call.ret_ty.int;
                const wide: ir.Type = .{ .int = if (bits <= 32) 64 else 128 };
                const lhs = if (signed) try signedExtend(allocator, function, &block, &serial, call.ret_ty, wide, call.args.items[0].value) else try extend(allocator, function, &block, &serial, call.ret_ty, wide, call.args.items[0].value);
                const rhs = if (signed) try signedExtend(allocator, function, &block, &serial, call.ret_ty, wide, call.args.items[1].value) else try extend(allocator, function, &block, &serial, call.ret_ty, wide, call.args.items[1].value);
                // Scale zero is exact multiplication without rounding. A
                // double-width carrier contains the complete signed/unsigned
                // product before saturation, including i64's high half.
                const product = try emit(allocator, function, &block, &serial, .{ .binary = .{ .op = .mul, .ty = wide, .lhs = lhs, .rhs = rhs } });
                const minimum: i128 = if (signed) -(@as(i128, 1) << @as(u7, @intCast(bits - 1))) else 0;
                const maximum: i128 = if (signed) -minimum - 1 else (@as(i128, 1) << @as(u7, @intCast(bits))) - 1;
                const lower = if (signed) blk: {
                    const below = try emit(allocator, function, &block, &serial, .{ .icmp = .{ .predicate = .slt, .operand_ty = wide, .lhs = product, .rhs = .{ .int = minimum } } });
                    break :blk try emit(allocator, function, &block, &serial, .{ .select = .{ .cond_ty = .{ .int = 1 }, .cond = below, .ty = wide, .true_value = .{ .int = minimum }, .false_value = product } });
                } else product;
                const overflow = try emit(allocator, function, &block, &serial, .{ .icmp = .{ .predicate = if (signed) .sgt else .ugt, .operand_ty = wide, .lhs = lower, .rhs = .{ .int = maximum } } });
                const clamped = try emit(allocator, function, &block, &serial, .{ .select = .{ .cond_ty = .{ .int = 1 }, .cond = overflow, .ty = wide, .true_value = .{ .int = maximum }, .false_value = lower } });
                try block.instructions.append(allocator, .{ .result = inst.result, .metadata = inst.metadata, .kind = .{ .cast = .{ .op = .trunc, .from_ty = wide, .value = clamped, .to_ty = call.ret_ty } } });
                continue;
            }
            if (!inst.removed and inst.result != null and inst.kind == .call) if (bit_intrinsics.operation(inst.kind.call)) |op| {
                try candidate.begin(&block, block_index, instruction_index);
                try bit_intrinsics.expand(allocator, function, &block, &serial, inst, op);
                continue;
            };
            if (!inst.removed and inst.result != null and inst.kind == .call) if (operation(inst.kind.call)) |op| {
                try candidate.begin(&block, block_index, instruction_index);
                const call = inst.kind.call;
                const bits = call.ret_ty.int;
                if (minimumMaximum(op)) {
                    const wide: ir.Type = .{ .int = if (bits < 32) 32 else if (bits == 128) 128 else 64 };
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
                    try block.instructions.append(allocator, .{ .result = inst.result, .metadata = inst.metadata, .kind = if (wide.eql(call.ret_ty))
                        .{ .binary = .{ .op = .add, .ty = wide, .lhs = selected, .rhs = .{ .int = 0 } } }
                    else
                        .{ .cast = .{ .op = .trunc, .from_ty = wide, .value = selected, .to_ty = call.ret_ty } } });
                } else if (op == .ssub_sat or op == .sadd_sat) {
                    // The wider carrier represents the exact mathematical
                    // sum or difference. Clamp before narrowing; normalize
                    // constants in their original signed logical width.
                    const wide: ir.Type = .{ .int = if (bits < 64) 64 else 128 };
                    const lhs = try signedExtend(allocator, function, &block, &serial, call.ret_ty, wide, call.args.items[0].value);
                    const rhs = try signedExtend(allocator, function, &block, &serial, call.ret_ty, wide, call.args.items[1].value);
                    const difference = try emit(allocator, function, &block, &serial, .{ .binary = .{ .op = if (op == .sadd_sat) .add else .sub, .ty = wide, .lhs = lhs, .rhs = rhs } });
                    const minimum: ir.Value = .{ .int = -(@as(i128, 1) << @as(u7, @intCast(bits - 1))) };
                    const maximum: ir.Value = .{ .int = -minimum.int - 1 };
                    const below = try emit(allocator, function, &block, &serial, .{ .icmp = .{ .predicate = .slt, .operand_ty = wide, .lhs = difference, .rhs = minimum } });
                    const lower = try emit(allocator, function, &block, &serial, .{ .select = .{ .cond_ty = .{ .int = 1 }, .cond = below, .ty = wide, .true_value = minimum, .false_value = difference } });
                    const above = try emit(allocator, function, &block, &serial, .{ .icmp = .{ .predicate = .sgt, .operand_ty = wide, .lhs = lower, .rhs = maximum } });
                    const clamped = try emit(allocator, function, &block, &serial, .{ .select = .{ .cond_ty = .{ .int = 1 }, .cond = above, .ty = wide, .true_value = maximum, .false_value = lower } });
                    try block.instructions.append(allocator, .{ .result = inst.result, .metadata = inst.metadata, .kind = .{ .cast = .{ .op = .trunc, .from_ty = wide, .value = clamped, .to_ty = call.ret_ty } } });
                } else if ((op == .uadd_sat or op == .usub_sat) and bits > 32 and bits < 64) {
                    // A word holds the complete unsigned sum for these widths.
                    const wide: ir.Type = .{ .int = 64 };
                    const lhs = try extend(allocator, function, &block, &serial, call.ret_ty, wide, call.args.items[0].value);
                    const rhs = try extend(allocator, function, &block, &serial, call.ret_ty, wide, call.args.items[1].value);
                    const subtract = op == .usub_sat;
                    const result = try emit(allocator, function, &block, &serial, .{ .binary = .{
                        .op = if (subtract) .sub else .add,
                        .ty = wide,
                        .lhs = lhs,
                        .rhs = rhs,
                    } });
                    const limit = try extend(allocator, function, &block, &serial, wide, wide, .{ .int = if (subtract) 0 else (@as(i128, 1) << @as(u7, @intCast(bits))) - 1 });
                    const overflow = try emit(allocator, function, &block, &serial, .{ .icmp = .{
                        .predicate = if (subtract) .ult else .ugt,
                        .operand_ty = wide,
                        .lhs = if (subtract) lhs else result,
                        .rhs = if (subtract) rhs else limit,
                    } });
                    const clamped = try emit(allocator, function, &block, &serial, .{ .select = .{
                        .cond_ty = .{ .int = 1 },
                        .cond = overflow,
                        .ty = wide,
                        .true_value = limit,
                        .false_value = result,
                    } });
                    try block.instructions.append(allocator, .{ .result = inst.result, .metadata = inst.metadata, .kind = .{ .cast = .{
                        .op = .trunc,
                        .from_ty = wide,
                        .value = clamped,
                        .to_ty = call.ret_ty,
                    } } });
                } else if (op == .scmp or op == .ucmp) {
                    const operand_ty = call.args.items[0].ty;
                    const lhs = try extend(allocator, function, &block, &serial, operand_ty, operand_ty, call.args.items[0].value);
                    const rhs = try extend(allocator, function, &block, &serial, operand_ty, operand_ty, call.args.items[1].value);
                    const less = try emit(allocator, function, &block, &serial, .{ .icmp = .{ .predicate = if (op == .scmp) .slt else .ult, .operand_ty = operand_ty, .lhs = lhs, .rhs = rhs } });
                    const greater = try emit(allocator, function, &block, &serial, .{ .icmp = .{ .predicate = if (op == .scmp) .sgt else .ugt, .operand_ty = operand_ty, .lhs = lhs, .rhs = rhs } });
                    const nonnegative = try emit(allocator, function, &block, &serial, .{ .select = .{ .cond_ty = .{ .int = 1 }, .cond = greater, .ty = call.ret_ty, .true_value = .{ .int = 1 }, .false_value = .{ .int = 0 } } });
                    try block.instructions.append(allocator, .{ .result = inst.result, .metadata = inst.metadata, .kind = .{ .select = .{ .cond_ty = .{ .int = 1 }, .cond = less, .ty = call.ret_ty, .true_value = .{ .int = -1 }, .false_value = nonnegative } } });
                } else if (op == .reverse) {
                    // The native i64 owner is terminal: all smaller widths
                    // normalize once without reintroducing an i32 intrinsic.
                    const wide: ir.Type = .{ .int = 64 };
                    const input = try extend(allocator, function, &block, &serial, call.ret_ty, wide, call.args.items[0].value);
                    const reversed = try forms.temporary(allocator, function, &serial);
                    var extended = call;
                    extended.ret_ty = wide;
                    extended.ret_attrs = null;
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
                    // Facts on the saturated scalar do not describe this
                    // overflow aggregate. Keep source facts untouched and omit
                    // validated advisory facts only on the private expansion.
                    checked.ret_attrs = null;
                    checked.args = try call.args.clone(allocator);
                    for (checked.args.items) |*arg| arg.attrs = null;
                    // Saturating unsigned shift by one equals a saturated
                    // doubling. Preserve simultaneous duplicate operands.
                    if (op == .ushl_one) checked.args.items[1].value = call.args.items[0].value;
                    checked.callee = try std.fmt.allocPrint(allocator, "llvm.{s}.with.overflow.i{d}", .{ if (op == .uadd_sat or op == .ushl_one) "uadd" else "usub", bits });
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
                        .true_value = .{ .int = if (op == .uadd_sat or op == .ushl_one) (@as(i128, 1) << @as(u7, @intCast(bits))) - 1 else 0 },
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

const PairExtendedOperation = enum { ushl, sshl, umul, smul };
fn pairExtendedOperation(call: ir.CallInst) ?PairExtendedOperation {
    if (!call.ret_ty.eql(.{ .int = 128 }) or !intrinsic_attrs.scalarIntegerCallSupported(call)) return null;
    var buffer: [64]u8 = undefined;
    for (std.enums.values(PairExtendedOperation)) |op| {
        const multiply = op == .umul or op == .smul;
        const spelling = std.fmt.bufPrint(&buffer, "llvm.{s}.{s}sat.i128", .{ @tagName(op), if (multiply) "fix." else "" }) catch return null;
        if (!std.mem.eql(u8, call.callee, spelling)) continue;
        if (call.args.items.len != (if (multiply) @as(usize, 3) else 2)) return null;
        for (call.args.items[0..2]) |arg| if (!arg.ty.eql(call.ret_ty) or (arg.value != .named and arg.value != .int) or (arg.value == .named and std.mem.startsWith(u8, arg.value.named, "@"))) return null;
        if (multiply) {
            const scale = call.args.items[2];
            if (!scale.ty.eql(.{ .int = 32 }) or scale.value != .int or scale.value.int != 0) return null;
        }
        return op;
    }
    return null;
}
fn expandPairExtended(a: std.mem.Allocator, f: ir.Function, block: *ir.BasicBlock, names: *forms.TemporaryNames, inst: ir.Instruction, op: PairExtendedOperation) !void {
    const narrow: ir.Type = .{ .int = 128 };
    const wide: ir.Type = .{ .int = 256 };
    const boolean: ir.Type = .{ .int = 1 };
    const multiply = op == .umul or op == .smul;
    const signed = op == .sshl or op == .smul;
    var inputs: [2]ir.Value = undefined;
    for (&inputs, inst.kind.call.args.items[0..2], 0..) |*input, arg, index| {
        const stable = if (arg.value == .int) try @import("binary128_arithmetic.zig").materializeIntegerArgument(a, f, block, names, .{ .op = .uitofp, .from_ty = narrow, .value = arg.value, .to_ty = .fp128 }) else arg.value;
        input.* = try emit(a, f, block, names, .{ .cast = .{ .op = if (signed and (multiply or index == 0)) .sext else .zext, .from_ty = narrow, .value = stable, .to_ty = wide } });
    }
    const value = if (multiply) try emit(a, f, block, names, .{ .binary = .{ .op = .mul, .ty = wide, .lhs = inputs[0], .rhs = inputs[1] } }) else blk: {
        const valid = try emit(a, f, block, names, .{ .icmp = .{ .predicate = .ult, .operand_ty = wide, .lhs = inputs[1], .rhs = .{ .int = 128 } } });
        const safe = try emit(a, f, block, names, .{ .select = .{ .cond_ty = boolean, .cond = valid, .ty = wide, .true_value = inputs[1], .false_value = .{ .int = 0 } } });
        break :blk try emit(a, f, block, names, .{ .binary = .{ .op = .shl, .ty = wide, .lhs = inputs[0], .rhs = safe } });
    };
    const minimum: ir.Value = .{ .int = if (signed) std.math.minInt(i128) else 0 };
    const maximum: ir.Value = if (signed) .{ .int = std.math.maxInt(i128) } else blk: {
        const ones = try @import("binary128_arithmetic.zig").materializeIntegerArgument(a, f, block, names, .{ .op = .uitofp, .from_ty = narrow, .value = .{ .int = -1 }, .to_ty = .fp128 });
        break :blk try emit(a, f, block, names, .{ .cast = .{ .op = .zext, .from_ty = narrow, .value = ones, .to_ty = wide } });
    };
    const lower = if (signed) blk: {
        const below = try emit(a, f, block, names, .{ .icmp = .{ .predicate = .slt, .operand_ty = wide, .lhs = value, .rhs = minimum } });
        break :blk try emit(a, f, block, names, .{ .select = .{ .cond_ty = boolean, .cond = below, .ty = wide, .true_value = minimum, .false_value = value } });
    } else value;
    const above = try emit(a, f, block, names, .{ .icmp = .{ .predicate = if (signed) .sgt else .ugt, .operand_ty = wide, .lhs = lower, .rhs = maximum } });
    const result = try emit(a, f, block, names, .{ .select = .{ .cond_ty = boolean, .cond = above, .ty = wide, .true_value = maximum, .false_value = lower } });
    try block.instructions.append(a, .{ .result = inst.result, .metadata = inst.metadata, .kind = .{ .cast = .{ .op = .trunc, .from_ty = wide, .value = result, .to_ty = narrow } } });
}
