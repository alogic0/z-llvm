//! Exact sign-bit operations for extended80 and binary128, including NaN bits.
const std = @import("std");
const ir = @import("../../../ir.zig");
const Candidate = @import("rewrite_candidate.zig").Candidate;
const forms = @import("scalar_forms.zig");
const sysv = @import("../sysv_abi.zig");
const helpers = @import("composed_helpers.zig");
const Operation = enum { negate, absolute, copy_sign };
const Form = struct { operation: Operation, ty: ir.Type, lhs: ir.Value, rhs: ?ir.Value = null };

fn bits(ty: ir.Type) ?u16 {
    return if (ty == .x86_fp80) 80 else if (ty == .fp128) 128 else null;
}
fn operand(value: ir.Value) bool {
    return switch (value) {
        .named => !std.mem.startsWith(u8, value.named, "@"),
        .fp, .undef, .poison, .zero_initializer => true,
        else => false,
    };
}
fn advisory(attrs: ?[]const u8) bool {
    return attrs == null or std.mem.eql(u8, std.mem.trim(u8, attrs.?, " \t"), "noundef");
}
fn classify(inst: ir.Instruction) ?Form {
    if (inst.removed or inst.result == null) return null;
    if (inst.kind == .binary) {
        const binary = inst.kind.binary;
        if (bits(binary.ty) != null and binary.op == .fsub and binary.lhs == .fp and
            @import("../../../analysis/fp_semantics.zig").isNegativeZeroLiteral(binary.ty, binary.lhs.fp) and operand(binary.rhs))
            return .{ .operation = .negate, .ty = binary.ty, .lhs = binary.rhs };
        return null;
    }
    if (inst.kind != .call) return null;
    const call = inst.kind.call;
    const width = bits(call.ret_ty) orelse return null;
    const operation: Operation = if (std.mem.eql(u8, call.callee, if (width == 80) "llvm.fabs.f80" else "llvm.fabs.f128")) .absolute else if (std.mem.eql(u8, call.callee, if (width == 80) "llvm.copysign.f80" else "llvm.copysign.f128")) .copy_sign else return null;
    if (call.args.items.len != (if (operation == .copy_sign) @as(usize, 2) else 1) or
        call.callee_value != null or call.callee_function_ty != null or call.inline_asm != null or
        call.raw_args != null or call.operand_bundle != null or !helpers.isDefaultOrFastcc(call.calling_conv) or
        !advisory(call.ret_attrs)) return null;
    sysv.rejectUnsupportedCallEnvelope(call) catch return null;
    for (call.args.items) |arg| if (!arg.ty.eql(call.ret_ty) or !advisory(arg.attrs) or !operand(arg.value)) return null;
    return .{ .operation = operation, .ty = call.ret_ty, .lhs = call.args.items[0].value, .rhs = if (operation == .copy_sign) call.args.items[1].value else null };
}

const Builder = struct {
    allocator: std.mem.Allocator,
    function: ir.Function,
    block: *ir.BasicBlock,
    serial: *forms.TemporaryNames,
    fn emit(b: Builder, kind: @FieldType(ir.Instruction, "kind")) !ir.Value {
        const name = try forms.temporary(b.allocator, b.function, b.serial);
        try b.block.instructions.append(b.allocator, .{ .result = name, .kind = kind });
        return .{ .named = name };
    }
    fn raw(b: Builder, ty: ir.Type, source: ir.Value, integer: ir.Type) !ir.Value {
        const stable = if (source == .undef or source == .poison) ir.Value.zero_initializer else source;
        return b.emit(.{ .cast = .{ .op = .bitcast, .from_ty = ty, .value = stable, .to_ty = integer } });
    }
    fn binary(b: Builder, ty: ir.Type, op: ir.BinaryOp, lhs: ir.Value, rhs: ir.Value) !ir.Value {
        return b.emit(.{ .binary = .{ .op = op, .ty = ty, .lhs = lhs, .rhs = rhs } });
    }
};

pub fn legalize(allocator: std.mem.Allocator, function: ir.Function) !?ir.Function {
    // Keep the established structural return authority for its exact shape.
    // Broader graphs gain the private bitwise representation below.
    if (function.blocks.items.len == 1 and bits(function.ret_ty) != null) {
        const block = function.blocks.items[0];
        if (block.terminator) |term| if (term == .ret and
            try @import("../air_patterns_fp.zig").matchesExtendedNegReturn(function, block, term.ret, function.ret_ty)) return null;
    }
    var candidate = Candidate.init(allocator, function);
    var serial: forms.TemporaryNames = .{};
    defer serial.deinit(allocator);
    for (function.blocks.items, 0..) |original, block_index| {
        var block = original;
        block.instructions = .empty;
        const b: Builder = .{ .allocator = allocator, .function = function, .block = &block, .serial = &serial };
        for (original.instructions.items, 0..) |inst, instruction_index| {
            if (classify(inst)) |form| {
                try candidate.begin(&block, block_index, instruction_index);
                const width = bits(form.ty).?;
                const integer: ir.Type = .{ .int = width };
                const sign: u128 = @as(u128, 1) << @as(u7, @intCast(width - 1));
                const sign_value: ir.Value = .{ .int = @bitCast(sign) };
                const magnitude: ir.Value = .{ .int = @intCast(sign - 1) };
                const raw = try b.raw(form.ty, form.lhs, integer);
                const changed = switch (form.operation) {
                    .negate => try b.binary(integer, .xor, raw, sign_value),
                    .absolute => try b.binary(integer, .@"and", raw, magnitude),
                    .copy_sign => try b.binary(integer, .@"or", try b.binary(integer, .@"and", raw, magnitude), try b.binary(integer, .@"and", try b.raw(form.ty, form.rhs.?, integer), sign_value)),
                };
                var copy = inst;
                copy.kind = .{ .cast = .{ .op = .bitcast, .from_ty = integer, .value = changed, .to_ty = form.ty } };
                copy.metadata = null;
                try block.instructions.append(allocator, copy);
            } else try candidate.keep(&block, inst);
        }
        try candidate.finishBlock(block);
    }
    return candidate.finish();
}
