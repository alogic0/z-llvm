//! Private scalar expansion of checked integer pairs. Only structured
//! extractvalue users are admitted; the borrowed source function stays intact.
const std = @import("std");
const ir = @import("../../../ir.zig");
const forms = @import("scalar_forms.zig");
const pairs = @import("word_pair_memory.zig");
const uses = @import("stage2_planning.zig");
const sysv = @import("../sysv_abi.zig");

const word: ir.Type = .{ .int = 64 };
const Operation = struct { op: ir.BinaryOp, signed: bool, bits: u16 };
const Entry = struct { operation: Operation, ty: ir.Type, wrapped: []const u8, overflow: []const u8, wide_overflow: []const u8, literal: ?[]const u8, lhs_literal: ?[]const u8 };

fn operation(call: ir.CallInst) ?Operation {
    if (call.ret_ty != .aggregate or call.callee_value != null or
        call.inline_asm != null or call.raw_args != null or call.operand_bundle != null or call.callee_function_ty != null or
        call.calling_conv != null or call.ret_attrs != null or call.args.items.len != 2) return null;
    const ty = call.args.items[0].ty;
    if (ty != .int or ty.int == 0 or (ty.int > 65 and ty.int != 96 and ty.int != 128)) return null;
    var buffer: [80]u8 = undefined;
    const pair = std.fmt.bufPrint(&buffer, "{{i{d},i1}}", .{ty.int}) catch return null;
    if (!pairs.spelling(call.ret_ty.aggregate, pair)) return null;
    sysv.rejectUnsupportedCallEnvelope(call) catch return null;
    for (call.args.items) |arg| {
        if (!arg.ty.eql(ty) or arg.attrs != null or (arg.value != .named and arg.value != .int)) return null;
        if (arg.value == .named and std.mem.startsWith(u8, arg.value.named, "@")) return null;
        if (arg.value == .int and ty.int < 128 and (arg.value.int < -(@as(i128, 1) << @as(u7, @intCast(ty.int - 1))) or
            arg.value.int >= (@as(i128, 1) << @as(u7, @intCast(ty.int))))) return null;
    }
    for ([_][]const u8{ "uadd", "usub", "umul", "sadd", "ssub", "smul" }, [_]ir.BinaryOp{ .add, .sub, .mul, .add, .sub, .mul }) |name, op| {
        const spelling = std.fmt.bufPrint(&buffer, "llvm.{s}.with.overflow.i{d}", .{ name, ty.int }) catch return null;
        if (std.mem.eql(u8, call.callee, spelling)) {
            const signed = name[0] == 's';
            if (ty.int >= 64 and op == .mul) {
                // A positive constant divisor allows an exact round-trip
                // overflow check after wrapping multiplication. General wide
                // products still require an independently lowered high half.
                const rhs = call.args.items[1].value;
                if (ty.int != 128 or rhs != .int or rhs.int < 1 or rhs.int > std.math.maxInt(u32)) return null;
            }
            return .{ .op = op, .signed = signed, .bits = ty.int };
        }
    }
    return null;
}

const Builder = struct {
    allocator: std.mem.Allocator,
    function: ir.Function,
    block: *ir.BasicBlock,
    serial: *usize,
    carrier: ir.Type = word,

    fn emit(self: Builder, kind: @FieldType(ir.Instruction, "kind")) !ir.Value {
        const name = try forms.temporary(self.allocator, self.function, self.serial);
        try self.block.instructions.append(self.allocator, .{ .result = name, .kind = kind });
        return .{ .named = name };
    }

    fn literal(self: Builder, value: i128) !ir.Value {
        return self.emit(.{ .binary = .{ .op = .add, .ty = self.carrier, .lhs = .{ .int = value }, .rhs = .{ .int = 0 } } });
    }

    fn extend(self: Builder, op: Operation, value: ir.Value) !ir.Value {
        if (value == .int) {
            const mask = (@as(i128, 1) << @as(u7, @intCast(op.bits))) - 1;
            const sign = @as(i128, 1) << @as(u7, @intCast(op.bits - 1));
            const bits = value.int & mask;
            return self.literal(if (op.signed) (bits ^ sign) - sign else bits);
        }
        var result = try self.emit(.{ .cast = .{ .op = .zext, .from_ty = .{ .int = op.bits }, .value = value, .to_ty = self.carrier } });
        if (op.signed) {
            const sign = try self.literal(@as(i128, 1) << @as(u7, @intCast(op.bits - 1)));
            result = try self.emit(.{ .binary = .{ .op = .xor, .ty = self.carrier, .lhs = result, .rhs = sign } });
            result = try self.emit(.{ .binary = .{ .op = .sub, .ty = self.carrier, .lhs = result, .rhs = sign } });
        }
        return result;
    }

    fn narrowPair(self: Builder, inst: ir.Instruction, entry: Entry) !void {
        const lhs = try self.extend(entry.operation, inst.kind.call.args.items[0].value);
        const rhs = try self.extend(entry.operation, inst.kind.call.args.items[1].value);
        // Products through i32 fit in i64, and products through i63 plus
        // i65/i96 sums and differences fit in i128. Unsigned subtraction wraps
        // only below zero, so a narrow round trip detects every overflow.
        const full = try self.emit(.{ .binary = .{ .op = entry.operation.op, .ty = self.carrier, .lhs = lhs, .rhs = rhs } });
        try self.block.instructions.append(self.allocator, .{ .result = entry.wrapped, .metadata = inst.metadata, .kind = .{ .cast = .{
            .op = .trunc,
            .from_ty = self.carrier,
            .value = full,
            .to_ty = .{ .int = entry.operation.bits },
        } } });
        const round_trip = try self.extend(entry.operation, .{ .named = entry.wrapped });
        try self.block.instructions.append(self.allocator, .{ .result = entry.overflow, .kind = .{ .icmp = .{
            .predicate = .ne,
            .operand_ty = self.carrier,
            .lhs = full,
            .rhs = round_trip,
        } } });
    }
};

pub fn legalize(allocator: std.mem.Allocator, function: ir.Function) !?ir.Function {
    var names = std.StringHashMap(Entry).init(allocator);
    var serial: usize = 0;
    for (function.blocks.items) |block| for (block.instructions.items) |inst| {
        if (inst.removed or inst.result == null or inst.kind != .call) continue;
        const op = operation(inst.kind.call) orelse continue;
        try names.put(inst.result.?, .{
            .operation = op,
            .ty = inst.kind.call.ret_ty,
            .wrapped = try forms.temporary(allocator, function, &serial),
            .overflow = try forms.temporary(allocator, function, &serial),
            .wide_overflow = try forms.temporary(allocator, function, &serial),
            .literal = if ((op.bits == 64 or op.bits == 128) and inst.kind.call.args.items[1].value == .int) try forms.temporary(allocator, function, &serial) else null,
            .lhs_literal = if ((op.bits == 64 or op.bits == 128) and inst.kind.call.args.items[0].value == .int) try forms.temporary(allocator, function, &serial) else null,
        });
    };
    if (names.count() == 0) return null;
    var iterator = names.iterator();
    while (iterator.next()) |item| {
        for (function.blocks.items) |block| {
            for (block.instructions.items) |inst| {
                if (inst.removed or !try uses.instructionUsesName(allocator, inst, item.key_ptr.*)) continue;
                if (inst.kind != .extractvalue or inst.result == null) return null;
                const extract = inst.kind.extractvalue;
                if (extract.aggregate != .named or !ir.identifiers.eql(extract.aggregate.named, item.key_ptr.*) or
                    !extract.aggregate_ty.eql(item.value_ptr.ty)) return null;
                if (std.mem.eql(u8, extract.indices, "0")) {
                    if (!extract.result_ty.eql(.{ .int = item.value_ptr.operation.bits })) return null;
                } else if (std.mem.eql(u8, extract.indices, "1")) {
                    if (!extract.result_ty.eql(.{ .int = 1 })) return null;
                } else return null;
            }
            if (block.terminator) |term| if (try uses.terminatorUsesName(allocator, term, item.key_ptr.*)) return null;
        }
    }
    var result = function;
    result.blocks = .empty;
    for (function.blocks.items) |original| {
        var block = original;
        block.instructions = .empty;
        for (original.instructions.items) |inst| {
            if (!inst.removed) {
                if (inst.kind == .call and inst.result != null) if (names.get(inst.result.?)) |entry| {
                    if (entry.operation.bits != 64 and entry.operation.bits != 128) {
                        try (Builder{ .allocator = allocator, .function = function, .block = &block, .serial = &serial, .carrier = if (entry.operation.bits > 32) .{ .int = 128 } else word }).narrowPair(inst, entry);
                    } else {
                        const full: ir.Type = .{ .int = entry.operation.bits };
                        const original_lhs = inst.kind.call.args.items[0].value;
                        if (entry.lhs_literal) |literal| try block.instructions.append(allocator, .{ .result = literal, .kind = .{ .binary = .{
                            .op = .add,
                            .ty = full,
                            .lhs = original_lhs,
                            .rhs = .{ .int = 0 },
                        } } });
                        const lhs: ir.Value = if (entry.lhs_literal) |literal| .{ .named = literal } else original_lhs;
                        const original_rhs = inst.kind.call.args.items[1].value;
                        if (entry.literal) |literal| try block.instructions.append(allocator, .{ .result = literal, .kind = .{ .binary = .{
                            .op = .add,
                            .ty = full,
                            .lhs = original_rhs,
                            .rhs = .{ .int = 0 },
                        } } });
                        const rhs: ir.Value = if (entry.literal) |literal| .{ .named = literal } else original_rhs;
                        // Wrapping arithmetic is defined on both overflow paths.
                        try block.instructions.append(allocator, .{ .result = entry.wrapped, .metadata = inst.metadata, .kind = .{ .binary = .{
                            .op = entry.operation.op,
                            .ty = full,
                            .lhs = lhs,
                            .rhs = rhs,
                        } } });
                        const builder: Builder = .{ .allocator = allocator, .function = function, .block = &block, .serial = &serial, .carrier = full };
                        if (entry.operation.op == .mul) {
                            const round_trip = try builder.emit(.{ .binary = .{
                                .op = if (entry.operation.signed) .sdiv else .udiv,
                                .ty = full,
                                .lhs = .{ .named = entry.wrapped },
                                .rhs = original_rhs,
                            } });
                            try block.instructions.append(allocator, .{ .result = entry.overflow, .kind = .{ .icmp = .{ .predicate = .ne, .operand_ty = full, .lhs = round_trip, .rhs = lhs } } });
                        } else if (entry.operation.signed) {
                            const changed_sign = try builder.emit(.{ .binary = .{ .op = .xor, .ty = full, .lhs = lhs, .rhs = .{ .named = entry.wrapped } } });
                            const other_sign = try builder.emit(.{ .binary = .{
                                .op = .xor,
                                .ty = full,
                                .lhs = if (entry.operation.op == .add) rhs else lhs,
                                .rhs = if (entry.operation.op == .add) .{ .named = entry.wrapped } else rhs,
                            } });
                            const both = try builder.emit(.{ .binary = .{ .op = .@"and", .ty = full, .lhs = changed_sign, .rhs = other_sign } });
                            try block.instructions.append(allocator, .{ .result = entry.overflow, .kind = .{ .icmp = .{
                                .predicate = .slt,
                                .operand_ty = full,
                                .lhs = both,
                                .rhs = .{ .int = 0 },
                            } } });
                        } else try block.instructions.append(allocator, .{ .result = entry.overflow, .kind = .{ .icmp = .{
                            .predicate = .ult,
                            .operand_ty = full,
                            .lhs = if (entry.operation.op == .add) .{ .named = entry.wrapped } else lhs,
                            .rhs = if (entry.operation.op == .add) lhs else rhs,
                        } } });
                    }
                    try block.instructions.append(allocator, .{ .result = entry.wide_overflow, .kind = .{ .cast = .{
                        .op = .zext,
                        .from_ty = .{ .int = 1 },
                        .value = .{ .named = entry.overflow },
                        .to_ty = .{ .int = 32 },
                    } } });
                    continue;
                };
                if (inst.kind == .extractvalue and inst.kind.extractvalue.aggregate == .named) if (names.get(inst.kind.extractvalue.aggregate.named)) |entry| {
                    var replacement = inst;
                    replacement.kind = if (std.mem.eql(u8, inst.kind.extractvalue.indices, "0") and entry.operation.bits < 64) .{ .cast = .{
                        .op = .bitcast,
                        .from_ty = .{ .int = entry.operation.bits },
                        .value = .{ .named = entry.wrapped },
                        .to_ty = .{ .int = entry.operation.bits },
                    } } else if (std.mem.eql(u8, inst.kind.extractvalue.indices, "0")) .{ .binary = .{
                        .op = .add,
                        .ty = .{ .int = entry.operation.bits },
                        .lhs = .{ .named = entry.wrapped },
                        .rhs = .{ .int = 0 },
                    } } else .{ .icmp = .{
                        .predicate = .ne,
                        .operand_ty = .{ .int = 32 },
                        .lhs = .{ .named = entry.wide_overflow },
                        .rhs = .{ .int = 0 },
                    } };
                    try block.instructions.append(allocator, replacement);
                    continue;
                };
            }
            try block.instructions.append(allocator, inst);
        }
        try result.blocks.append(allocator, block);
    }
    return result;
}
