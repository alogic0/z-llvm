//! Private two-register carriers with an explicit physical integer ABI view.
//! Mask at incoming boundaries and original definitions; memory stays separate.
const std = @import("std");
const ir = @import("../../../ir.zig");
const forms = @import("scalar_forms.zig");
const helpers = @import("composed_helpers.zig");
const sysv = @import("../sysv_abi.zig");
const stack_arguments = @import("stack_arguments.zig");
const pair: ir.Type = .{ .int = 128 };
const word: ir.Type = .{ .int = 64 };
const Mode = enum { legacy_registers, physical_abi };

fn wide(mode: Mode, ty: ir.Type) bool {
    return ty == .int and (if (mode == .physical_abi) ty.int > 64 and ty.int < 128 else ty.int == 65 or ty.int == 96);
}
fn operand(value: ir.Value) bool {
    return value == .int or (value == .named and !std.mem.startsWith(u8, value.named, "@"));
}
fn mask(bits: u16) i128 {
    return @intCast((@as(u128, 1) << @as(u7, @intCast(bits))) - 1);
}
fn normalized(value: ir.Value, bits: u16) ir.Value {
    return if (value == .int) .{ .int = value.int & mask(bits) } else value;
}
fn advisory(mode: Mode, ty: ir.Type, attrs: ?[]const u8) bool {
    if (mode == .physical_abi) return sysv.callReturnAttrsSupported(.{ .callee = "", .ret_ty = ty, .ret_attrs = attrs, .args = .empty });
    return attrs == null or std.mem.eql(u8, std.mem.trim(u8, attrs.?, " \t"), "noundef");
}
fn registers(mode: Mode, ty: ir.Type) ?usize {
    if (ty == .ptr) return 1;
    if (ty != .int or ty.int == 0) return null;
    if (ty.int <= 64) return 1;
    if (wide(mode, ty) or ty.eql(pair)) return 2;
    return null;
}
fn supported(op: ir.BinaryOp) bool {
    return switch (op) {
        .add, .sub, .mul, .@"and", .@"or", .xor, .shl, .lshr, .ashr, .udiv, .urem, .sdiv, .srem => true,
        else => false,
    };
}
const WideUse = struct {
    pub const Error = error{};
    mode: Mode,
    found: *bool,
    pub fn visit(self: WideUse, _: *const ir.Value, ty: ir.Type) Error!void {
        if (wide(self.mode, ty)) self.found.* = true;
    }
};
fn touches(mode: Mode, inst: *const ir.Instruction) bool {
    var found = if (inst.resultType()) |ty| wide(mode, ty) else false;
    _ = ir.operands.instruction(inst, WideUse{ .mode = mode, .found = &found }) catch unreachable;
    return found;
}
fn callForm(mode: Mode, call: ir.CallInst) bool {
    if (!helpers.isDefaultOrFastcc(call.calling_conv) or call.inline_asm != null or
        call.raw_args != null or call.operand_bundle != null or call.callee_function_ty != null or
        std.mem.startsWith(u8, call.callee, "llvm.")) return false;
    if (wide(mode, call.ret_ty) and !advisory(mode, call.ret_ty, call.ret_attrs)) return false;
    if (mode == .legacy_registers and wide(mode, call.ret_ty) and call.ret_attrs != null) return false;
    sysv.rejectUnsupportedCallEnvelope(call) catch return false;
    var count: usize = 0;
    for (call.args.items) |arg| {
        sysv.rejectUnsupportedCallArgAttrs(arg) catch return false;
        count += registers(mode, arg.ty) orelse if (mode == .physical_abi and
            (sysv.isScalarSseAbiType(arg.ty) or sysv.isVector128AbiType(arg.ty))) @as(usize, 0) else return false;
        if (wide(mode, arg.ty) and (!advisory(mode, arg.ty, arg.attrs) or !operand(arg.value))) return false;
    }
    return if (mode == .physical_abi) stack_arguments.callLayout(call) != null else count <= 6;
}
const Builder = struct {
    allocator: std.mem.Allocator,
    function: ir.Function,
    block: *ir.BasicBlock,
    serial: *forms.TemporaryNames,
    fn emit(self: Builder, kind: @FieldType(ir.Instruction, "kind")) !ir.Value {
        const name = try forms.temporary(self.allocator, self.function, self.serial);
        try self.block.instructions.append(self.allocator, .{ .result = name, .kind = kind });
        return .{ .named = name };
    }
    fn binary(self: Builder, op: ir.BinaryOp, lhs: ir.Value, rhs: ir.Value) !ir.Value {
        return self.emit(.{ .binary = .{ .op = op, .ty = pair, .lhs = lhs, .rhs = rhs } });
    }
    fn cast(self: Builder, op: ir.CastOp, from: ir.Type, value: ir.Value, to: ir.Type) !ir.Value {
        return self.emit(.{ .cast = .{ .op = op, .from_ty = from, .value = value, .to_ty = to } });
    }
    fn signed(self: Builder, value: ir.Value, bits: u16) !ir.Value {
        if (value == .int) {
            const v = value.int & mask(bits);
            const sign = @as(i128, 1) << @as(u7, @intCast(bits - 1));
            return .{ .int = if (v & sign == 0) v else v | ~mask(bits) };
        }
        const count: ir.Value = .{ .int = 128 - bits };
        return self.binary(.ashr, try self.binary(.shl, value, count), count);
    }
    fn finish(self: Builder, inst: ir.Instruction, value: ir.Value, bits: u16) !void {
        var copy = inst;
        copy.kind = .{ .binary = .{ .op = .@"and", .ty = pair, .lhs = value, .rhs = .{ .int = mask(bits) } } };
        try self.block.instructions.append(self.allocator, copy);
    }
};

pub fn legalize(allocator: std.mem.Allocator, function: ir.Function) !?ir.Function {
    return legalizeImpl(.legacy_registers, allocator, function);
}

/// The source ABI remains immutable. The shared caller/callee layout supports
/// all two-word integer carriers and owns complete aligned stack arguments.
pub fn legalizeForPhysicalAbi(allocator: std.mem.Allocator, function: ir.Function) !?ir.Function {
    return legalizeImpl(.physical_abi, allocator, function);
}

fn legalizeImpl(mode: Mode, allocator: std.mem.Allocator, function: ir.Function) !?ir.Function {
    if (!helpers.isDefaultOrFastcc(function.calling_conv) or function.blocks.items.len == 0) return null;
    var needed = wide(mode, function.ret_ty);
    if (needed and (!advisory(mode, function.ret_ty, function.ret_attrs) or
        (mode == .legacy_registers and function.ret_attrs != null))) return null;
    var param_registers: usize = 0;
    for (function.params.items) |param| {
        param_registers += registers(mode, param.ty) orelse 7;
        if (wide(mode, param.ty)) {
            if (!advisory(mode, param.ty, param.attrs)) return null;
            needed = true;
        }
    }
    if (mode == .physical_abi) {
        if (stack_arguments.parameters(function) == null) return null;
    } else if (param_registers > 6) return null;
    for (function.blocks.items) |block| for (block.instructions.items) |*inst| {
        if (inst.removed or !touches(mode, inst)) continue;
        needed = true;
        switch (inst.kind) {
            .binary => |x| if (!wide(mode, x.ty) or !supported(x.op) or !operand(x.lhs) or !operand(x.rhs)) return null,
            .icmp => |x| if (!wide(mode, x.operand_ty) or !operand(x.lhs) or !operand(x.rhs)) return null,
            .select => |x| if (!wide(mode, x.ty) or !x.cond_ty.eql(.{ .int = 1 }) or !operand(x.cond) or !operand(x.true_value) or !operand(x.false_value)) return null,
            .freeze => |x| if (!wide(mode, x.ty) or (!operand(x.value) and x.value != .undef and x.value != .poison)) return null,
            .phi => |x| {
                if (!wide(mode, x.ty)) return null;
                for (x.incoming.items) |incoming| if (!operand(incoming.value)) return null;
            },
            .cast => |x| if (x.from_ty != .int or x.to_ty != .int or x.from_ty.int == 0 or x.to_ty.int == 0 or x.from_ty.int > 128 or x.to_ty.int > 128 or
                (x.from_ty.int > 64 and !wide(mode, x.from_ty) and !x.from_ty.eql(pair)) or
                (x.to_ty.int > 64 and !wide(mode, x.to_ty) and !x.to_ty.eql(pair)) or
                (x.op != .zext and x.op != .sext and x.op != .trunc) or !operand(x.value)) return null,
            .call => |x| if (!callForm(mode, x)) return null,
            // Do not widen a memory access along with its register carrier.
            // Loads and stores of these widths remain outside this form.
            else => return null,
        }
    };
    if (!needed) return null;
    var result = function;
    result.params = try function.params.clone(allocator);
    result.blocks = .empty;
    if (wide(mode, result.ret_ty)) {
        result.ret_ty = pair;
        if (mode == .physical_abi) result.ret_attrs = null;
    }
    var serial: forms.TemporaryNames = .{};
    defer serial.deinit(allocator);
    for (result.params.items) |*param| if (wide(mode, param.ty)) {
        param.ty = pair;
        if (mode == .physical_abi) param.abi_split_integer = true;
        if (mode == .physical_abi and !advisory(.legacy_registers, pair, param.attrs)) param.attrs = null;
        param.name = try forms.temporary(allocator, function, &serial);
    };
    for (function.blocks.items, 0..) |original, index| {
        var block = original;
        block.instructions = .empty;
        const b: Builder = .{ .allocator = allocator, .function = function, .block = &block, .serial = &serial };
        if (index == 0) for (function.params.items, result.params.items) |param, incoming| {
            if (wide(mode, param.ty)) try b.finish(.{ .result = param.name, .kind = undefined }, .{ .named = incoming.name }, param.ty.int);
        };
        for (original.instructions.items) |inst| {
            var copy = inst;
            if (!inst.removed and touches(mode, &inst)) switch (inst.kind) {
                .binary => |x| {
                    const sign = x.op == .sdiv or x.op == .srem or x.op == .ashr;
                    const lhs = if (sign) try b.signed(x.lhs, x.ty.int) else normalized(x.lhs, x.ty.int);
                    const rhs = if (x.op == .sdiv or x.op == .srem) try b.signed(x.rhs, x.ty.int) else normalized(x.rhs, x.ty.int);
                    try b.finish(inst, try b.binary(x.op, lhs, rhs), x.ty.int);
                    continue;
                },
                .icmp => |x| {
                    const sign = x.predicate == .slt or x.predicate == .sle or x.predicate == .sgt or x.predicate == .sge;
                    copy.kind.icmp.operand_ty = pair;
                    copy.kind.icmp.lhs = if (sign) try b.signed(x.lhs, x.operand_ty.int) else normalized(x.lhs, x.operand_ty.int);
                    copy.kind.icmp.rhs = if (sign) try b.signed(x.rhs, x.operand_ty.int) else normalized(x.rhs, x.operand_ty.int);
                },
                .select => |x| {
                    copy.kind.select.ty = pair;
                    copy.kind.select.true_value = normalized(x.true_value, x.ty.int);
                    copy.kind.select.false_value = normalized(x.false_value, x.ty.int);
                },
                .phi => |x| {
                    copy.kind.phi.ty = pair;
                    copy.kind.phi.incoming = try x.incoming.clone(allocator);
                    for (copy.kind.phi.incoming.items) |*incoming| incoming.value = normalized(incoming.value, x.ty.int);
                },
                .freeze => |x| {
                    var value: ir.Value = if (x.value == .undef or x.value == .poison) .{ .int = 0 } else normalized(x.value, x.ty.int);
                    if (value == .int) value = try b.binary(.add, value, .{ .int = 0 });
                    copy.result = try forms.temporary(allocator, function, &serial);
                    copy.kind.freeze.ty = pair;
                    copy.kind.freeze.value = value;
                    try block.instructions.append(allocator, copy);
                    try b.finish(inst, .{ .named = copy.result.? }, x.ty.int);
                    continue;
                },
                .cast => |x| {
                    var value: ir.Value = x.value;
                    if (wide(mode, x.from_ty)) {
                        value = if (x.op == .sext) try b.signed(value, x.from_ty.int) else normalized(value, x.from_ty.int);
                    } else if (x.from_ty.int <= 64) {
                        const low = if (x.from_ty.eql(word)) value else try b.cast(if (x.op == .sext) .sext else .zext, x.from_ty, value, word);
                        value = try b.cast(if (x.op == .sext) .sext else .zext, word, low, pair);
                    }
                    if (wide(mode, x.to_ty)) {
                        try b.finish(inst, value, x.to_ty.int);
                        continue;
                    }
                    copy.kind = if (x.to_ty.eql(pair)) .{ .binary = .{ .op = .add, .ty = pair, .lhs = value, .rhs = .{ .int = 0 } } } else .{ .cast = .{ .op = .trunc, .from_ty = pair, .value = value, .to_ty = x.to_ty } };
                },
                .call => |x| {
                    copy.kind.call.args = try x.args.clone(allocator);
                    for (copy.kind.call.args.items) |*arg| if (wide(mode, arg.ty)) {
                        arg.value = normalized(arg.value, arg.ty.int);
                        arg.ty = pair;
                        if (mode == .physical_abi) arg.abi_split_integer = true;
                        if (mode == .physical_abi and !advisory(.legacy_registers, pair, arg.attrs)) arg.attrs = null;
                    };
                    if (wide(mode, x.ret_ty)) {
                        copy.kind.call.ret_ty = pair;
                        if (mode == .physical_abi) copy.kind.call.ret_attrs = null;
                        if (inst.result != null) copy.result = try forms.temporary(allocator, function, &serial);
                        try block.instructions.append(allocator, copy);
                        if (inst.result != null) try b.finish(inst, .{ .named = copy.result.? }, x.ret_ty.int);
                        continue;
                    }
                },
                else => unreachable,
            };
            try block.instructions.append(allocator, copy);
        }
        if (wide(mode, function.ret_ty)) if (block.terminator) |*term| if (term.* == .ret) {
            term.ret.ty = pair;
            if (term.ret.value) |value| term.ret.value = normalized(value, function.ret_ty.int);
        };
        try result.blocks.append(allocator, block);
    }
    return result;
}
