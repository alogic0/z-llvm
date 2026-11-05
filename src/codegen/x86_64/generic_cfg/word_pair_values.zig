//! Split flat two-word integer/pointer SSA values. The public ABI still uses
//! RAX/RDX; only the private selector view uses the equivalent i128 carrier.
const std = @import("std");
const ir = @import("../../../ir.zig");
const machine = @import("../machine.zig");
const pairs = @import("word_pair_memory.zig");
const helpers = @import("composed_helpers.zig");
const uses = @import("stage2_planning.zig");
const syntax = @import("../../../ir/parser_syntax.zig");
const parser = @import("../../../ir/parser_types_values.zig");
const sysv = @import("../sysv_abi.zig");

const word: ir.Type = .{ .int = 64 };
const wide: ir.Type = .{ .int = 128 };
const Names = std.StringHashMap([2][]const u8);

fn fields(ty: ir.Type) ?[2]ir.Type {
    if (ty != .aggregate) return null;
    if (pairs.spelling(ty.aggregate, "{ptr,i64}")) return .{ .ptr, word };
    if (pairs.spelling(ty.aggregate, "{i64,ptr}")) return .{ word, .ptr };
    if (pairs.spelling(ty.aggregate, "{ptr,ptr}")) return .{ .ptr, .ptr };
    if (pairs.spelling(ty.aggregate, "{i64,i64}")) return .{ word, word };
    return null;
}

fn index(text: []const u8) ?usize {
    if (std.mem.eql(u8, text, "0")) return 0;
    if (std.mem.eql(u8, text, "1")) return 1;
    return null;
}

fn definition(function: ir.Function, name: []const u8) ?ir.Instruction {
    for (function.blocks.items) |block| for (block.instructions.items) |inst| {
        if (!inst.removed and inst.result != null and ir.identifiers.eql(inst.result.?, name)) return inst;
    };
    return null;
}

fn temporary(allocator: std.mem.Allocator, function: ir.Function, serial: *usize) ![]const u8 {
    while (true) {
        const name = try std.fmt.allocPrint(allocator, "__zllvm_pair_value_{d}", .{serial.*});
        serial.* += 1;
        var collision = definition(function, name) != null;
        for (function.params.items) |param| if (ir.identifiers.eql(param.name, name)) {
            collision = true;
        };
        for (function.blocks.items) |block| if (ir.identifiers.eql(block.name, name)) {
            collision = true;
        };
        if (!collision) return name;
    }
}

fn leaf(function: ir.Function, names: Names, value: ir.Value, ty: ir.Type, field: usize, depth: u8) ?ir.Value {
    if (depth >= 64) return null;
    if (value == .undef or value == .poison) return value;
    if (value == .zero_initializer) return if (fields(ty).?[field] == .ptr) .null_value else .{ .int = 0 };
    if (value == .constant_expr) {
        const text = std.mem.trim(u8, value.constant_expr, " \t");
        if (text.len < 2 or text[0] != '{' or text[text.len - 1] != '}') return null;
        const body = text[1 .. text.len - 1];
        const comma = syntax.findTopLevelComma(body) orelse return null;
        if (syntax.findTopLevelComma(body[comma + 1 ..]) != null) return null;
        const first = parser.parseTypedValue(std.mem.trim(u8, body[0..comma], " \t")) catch return null;
        const second = parser.parseTypedValue(std.mem.trim(u8, body[comma + 1 ..], " \t")) catch return null;
        const types = fields(ty).?;
        if (!first.ty.eql(types[0]) or !second.ty.eql(types[1])) return null;
        return if (field == 0) first.value else second.value;
    }
    if (value != .named) return null;
    if (names.get(value.named)) |parts| return .{ .named = parts[field] };
    const inst = definition(function, value.named) orelse return null;
    if (inst.kind != .insertvalue or !inst.kind.insertvalue.aggregate_ty.eql(ty)) return null;
    const insert = inst.kind.insertvalue;
    const which = index(insert.indices) orelse return null;
    if (!insert.value_ty.eql(fields(ty).?[which])) return null;
    if (which == field) return insert.value;
    return leaf(function, names, insert.aggregate, ty, field, depth + 1);
}

fn cast(allocator: std.mem.Allocator, function: ir.Function, block: *ir.BasicBlock, serial: *usize, op: ir.CastOp, from: ir.Type, value: ir.Value, to: ir.Type, result: ?[]const u8) !ir.Value {
    const name = result orelse try temporary(allocator, function, serial);
    try block.instructions.append(allocator, .{ .result = name, .kind = .{ .cast = .{ .op = op, .from_ty = from, .value = value, .to_ty = to } } });
    return .{ .named = name };
}

fn binary(allocator: std.mem.Allocator, function: ir.Function, block: *ir.BasicBlock, serial: *usize, op: ir.BinaryOp, ty: ir.Type, lhs: ir.Value, rhs: ir.Value, result: ?[]const u8) !ir.Value {
    const name = result orelse try temporary(allocator, function, serial);
    try block.instructions.append(allocator, .{ .result = name, .kind = .{ .binary = .{ .op = op, .ty = ty, .lhs = lhs, .rhs = rhs } } });
    return .{ .named = name };
}

fn address(allocator: std.mem.Allocator, function: ir.Function, block: *ir.BasicBlock, serial: *usize, ptr: ir.Value, offset: usize, result: ?[]const u8) !ir.Value {
    const name = result orelse try temporary(allocator, function, serial);
    var indices: std.ArrayList(ir.GepIndex) = .empty;
    try indices.append(allocator, .{ .ty = word, .value = .{ .int = @intCast(offset) } });
    try block.instructions.append(allocator, .{ .result = name, .kind = .{ .gep = .{ .source_ty = .{ .int = 8 }, .ptr = ptr, .indices = indices } } });
    return .{ .named = name };
}

fn memory(attrs: ir.MemoryAttrs, ty_space: ?[]const u8, ptr_space: ?[]const u8) bool {
    return !attrs.isBarrier() and attrs.syncscope == null and ty_space == null and ptr_space == null;
}

pub fn legalize(allocator: std.mem.Allocator, function: ir.Function, context: ?*const machine.ReadOnlyModuleContext) !?ir.Function {
    if (!pairs.supportsLayout(context) or !helpers.isDefaultOrFastcc(function.calling_conv)) return null;
    for (function.params.items) |param| if (fields(param.ty) != null) return null;
    const returning = fields(function.ret_ty) != null;
    if (returning and function.ret_attrs != null) return null;
    var values = std.StringHashMap(ir.Type).init(allocator);
    var names = Names.init(allocator);
    var serial: usize = 0;
    var extracts = false;
    for (function.blocks.items) |block| for (block.instructions.items) |inst| {
        if (inst.removed) continue;
        if (inst.kind == .extractvalue and fields(inst.kind.extractvalue.aggregate_ty) != null) extracts = true;
        const ty = inst.resultType() orelse continue;
        if (fields(ty) == null) continue;
        const name = inst.result orelse return null;
        switch (inst.kind) {
            .load => |load| if (!memory(load.attrs, load.ty_addrspace, load.ptr_addrspace)) return null,
            .call => |call| {
                if (call.callee_value != null or call.inline_asm != null or call.raw_args != null or call.operand_bundle != null or
                    call.callee_function_ty != null or call.ret_attrs != null or !helpers.isDefaultOrFastcc(call.calling_conv) or
                    std.mem.startsWith(u8, call.callee, "llvm.")) return null;
                sysv.rejectUnsupportedCallEnvelope(call) catch return null;
            },
            .insertvalue => |insert| {
                const which = index(insert.indices) orelse return null;
                if (!insert.value_ty.eql(fields(ty).?[which])) return null;
            },
            else => return null,
        }
        try values.put(name, ty);
        if (inst.kind != .insertvalue) try names.put(name, .{ try temporary(allocator, function, &serial), try temporary(allocator, function, &serial) });
    };
    if (values.count() == 0 and !returning and !extracts) return null;
    var iterator = values.iterator();
    while (iterator.next()) |item| {
        for (function.blocks.items) |block| {
            for (block.instructions.items) |inst| {
                if (inst.removed or !try uses.instructionUsesName(allocator, inst, item.key_ptr.*)) continue;
                switch (inst.kind) {
                    .insertvalue => |insert| if (!values.contains(inst.result orelse return null) or insert.aggregate != .named or !ir.identifiers.eql(insert.aggregate.named, item.key_ptr.*)) return null,
                    .extractvalue => |extract| {
                        if (!extract.aggregate_ty.eql(item.value_ptr.*) or index(extract.indices) == null) return null;
                    },
                    .store => |store| {
                        if (!store.ty.eql(item.value_ptr.*) or store.value != .named or !ir.identifiers.eql(store.value.named, item.key_ptr.*) or
                            (store.ptr == .named and ir.identifiers.eql(store.ptr.named, item.key_ptr.*)) or !memory(store.attrs, store.ty_addrspace, store.ptr_addrspace)) return null;
                    },
                    else => return null,
                }
            }
            if (block.terminator) |term| if (try uses.terminatorUsesName(allocator, term, item.key_ptr.*)) {
                if (term != .ret or !term.ret.ty.eql(item.value_ptr.*) or !returning) return null;
            };
        }
    }
    var result = function;
    result.blocks = .empty;
    if (returning) result.ret_ty = wide;
    for (function.blocks.items) |original| {
        var block = original;
        block.instructions = .empty;
        for (original.instructions.items) |inst| {
            if (!inst.removed) switch (inst.kind) {
                .insertvalue => if (inst.result != null and values.contains(inst.result.?)) continue,
                .load => |load| if (fields(load.ty)) |types| {
                    for (types, 0..) |ty, part| {
                        var copy = inst;
                        copy.result = names.get(inst.result.?).?[part];
                        copy.kind.load.ty = ty;
                        copy.kind.load.ptr = try address(allocator, function, &block, &serial, load.ptr, part * 8, null);
                        if (copy.kind.load.attrs.@"align") |alignment| copy.kind.load.attrs.@"align" = @min(alignment, 8);
                        try block.instructions.append(allocator, copy);
                    }
                    continue;
                },
                .store => |store| if (fields(store.ty)) |types| {
                    if (!memory(store.attrs, store.ty_addrspace, store.ptr_addrspace)) return null;
                    for (types, 0..) |ty, part| {
                        var copy = inst;
                        copy.kind.store.ty = ty;
                        copy.kind.store.value = leaf(function, names, store.value, store.ty, part, 0) orelse return null;
                        copy.kind.store.ptr = try address(allocator, function, &block, &serial, store.ptr, part * 8, null);
                        if (copy.kind.store.attrs.@"align") |alignment| copy.kind.store.attrs.@"align" = @min(alignment, 8);
                        try block.instructions.append(allocator, copy);
                    }
                    continue;
                },
                .extractvalue => |extract| if (fields(extract.aggregate_ty)) |types| {
                    const part = index(extract.indices) orelse return null;
                    const value = leaf(function, names, extract.aggregate, extract.aggregate_ty, part, 0) orelse return null;
                    if (types[part] == .ptr) {
                        if (value == .null_value) {
                            _ = try cast(allocator, function, &block, &serial, .inttoptr, word, .{ .int = 0 }, .ptr, inst.result);
                        } else _ = try address(allocator, function, &block, &serial, value, 0, inst.result);
                    } else _ = try binary(allocator, function, &block, &serial, .add, word, value, .{ .int = 0 }, inst.result);
                    continue;
                },
                .call => |call| if (fields(call.ret_ty)) |types| {
                    var copy = inst;
                    copy.kind.call.ret_ty = wide;
                    copy.result = try temporary(allocator, function, &serial);
                    try block.instructions.append(allocator, copy);
                    for (types, 0..) |ty, part| {
                        const value: ir.Value = .{ .named = copy.result.? };
                        const limb = if (part == 0) value else try binary(allocator, function, &block, &serial, .lshr, wide, value, .{ .int = 64 }, null);
                        const name = names.get(inst.result.?).?[part];
                        const scalar = try cast(allocator, function, &block, &serial, .trunc, wide, limb, word, if (ty == .ptr) null else name);
                        if (ty == .ptr) _ = try cast(allocator, function, &block, &serial, .inttoptr, word, scalar, .ptr, name);
                    }
                    continue;
                },
                else => {},
            };
            try block.instructions.append(allocator, inst);
        }
        if (returning) if (block.terminator) |*term| if (term.* == .ret) {
            const value = term.ret.value orelse return null;
            var limbs: [2]ir.Value = undefined;
            for (fields(function.ret_ty).?, 0..) |ty, part| {
                var scalar = leaf(function, names, value, function.ret_ty, part, 0) orelse return null;
                if (ty == .ptr) scalar = try cast(allocator, function, &block, &serial, .ptrtoint, .ptr, scalar, word, null);
                limbs[part] = try cast(allocator, function, &block, &serial, .zext, word, scalar, wide, null);
            }
            limbs[1] = try binary(allocator, function, &block, &serial, .shl, wide, limbs[1], .{ .int = 64 }, null);
            term.ret.value = try binary(allocator, function, &block, &serial, .@"or", wide, limbs[0], limbs[1], null);
            term.ret.ty = wide;
        };
        try result.blocks.append(allocator, block);
    }
    return result;
}
