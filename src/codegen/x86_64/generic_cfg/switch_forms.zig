//! Private compare chains for wide and large switches. PHI edges must already
//! have dedicated blocks, so every generated conditional edge keeps SSA valid.
const std = @import("std");
const ir = @import("../../../ir.zig");
const forms = @import("scalar_forms.zig");
const helpers = @import("composed_helpers.zig");
const planning = @import("stage2_planning.zig");

fn needsRewrite(term: ir.SwitchTerminator) bool {
    if (term.cond_ty != .int) return false;
    if (term.cond_ty.int > 32 or term.cond == .int or term.cases.items.len == 0 or term.cases.items.len > 8) return true;
    // The small-switch action accepts signed i32 spellings only. LLVM also
    // permits the corresponding nonnegative bit patterns through UINT32_MAX.
    if (term.cond_ty.int == 32) for (term.cases.items) |case| {
        if (case.value == .int and case.value.int > std.math.maxInt(i32)) return true;
    };
    return false;
}

fn bitsValue(value: ir.Value, bits: u16) ?i128 {
    if (bits == 0 or bits > 128) return null;
    const mask: u128 = if (bits == 128) std.math.maxInt(u128) else (@as(u128, 1) << @as(u7, @intCast(bits))) - 1;
    if (value == .int) {
        if (bits < 128 and value.int < -(@as(i128, 1) << @as(u7, @intCast(bits - 1)))) return null;
        if (value.int >= 0 and @as(u128, @intCast(value.int)) > mask) return null;
        return @bitCast(@as(u128, @bitCast(value.int)) & mask);
    }
    return null;
}

pub fn legalize(allocator: std.mem.Allocator, function: ir.Function) !?ir.Function {
    var added: usize = 0;
    var changed = false;
    for (function.blocks.items) |block| {
        const term = block.terminator orelse continue;
        if (term != .@"switch" or !needsRewrite(term.@"switch")) continue;
        const sw = term.@"switch";
        const bits = sw.cond_ty.int;
        if (bits == 0 or bits > 128 or sw.cases.items.len > planning.stage2_max_blocks) return null;
        if (sw.cond != .named and bitsValue(sw.cond, bits) == null) return null;
        const fallback = function.blockIndex(sw.default_target) orelse return null;
        if (helpers.blockHasPhiIncomingFrom(function.blocks.items[fallback], block.name)) return null;
        for (sw.cases.items, 0..) |case, index| {
            if (!case.value_ty.eql(sw.cond_ty)) return null;
            const value = bitsValue(case.value, bits) orelse return null;
            for (sw.cases.items[0..index]) |previous| if (value == bitsValue(previous.value, bits).?) return null;
            const target = function.blockIndex(case.target) orelse return null;
            if (helpers.blockHasPhiIncomingFrom(function.blocks.items[target], block.name)) return null;
        }
        added += sw.cases.items.len -| 1;
        if (added > planning.stage2_max_blocks or function.blocks.items.len > planning.stage2_max_blocks - added) return null;
        changed = true;
    }
    if (!changed) return null;
    var result = function;
    result.blocks = try function.blocks.clone(allocator);
    var serial: forms.TemporaryNames = .{};
    defer serial.deinit(allocator);
    for (function.blocks.items, 0..) |original, block_index| {
        const term = original.terminator orelse continue;
        if (term != .@"switch" or !needsRewrite(term.@"switch")) continue;
        const sw = term.@"switch";
        if (sw.cases.items.len == 0) {
            result.blocks.items[block_index].terminator = .{ .br = .{ .target = sw.default_target } };
            continue;
        }
        var block = original;
        block.instructions = try original.instructions.clone(allocator);
        const bits = sw.cond_ty.int;
        const wide: ir.Type = .{ .int = if (bits <= 32) 32 else if (bits <= 64) 64 else 128 };
        var condition = sw.cond;
        if (condition != .named or bits != wide.int) {
            const name = try forms.temporary(allocator, function, &serial);
            const kind: @FieldType(ir.Instruction, "kind") = if (condition != .named)
                .{ .binary = .{ .op = .add, .ty = wide, .lhs = .{ .int = bitsValue(condition, bits).? }, .rhs = .{ .int = 0 } } }
            else
                .{ .cast = .{ .op = .zext, .from_ty = sw.cond_ty, .value = condition, .to_ty = wide } };
            try block.instructions.append(allocator, .{ .result = name, .kind = kind });
            condition = .{ .named = name };
        }
        for (sw.cases.items, 0..) |case, index| {
            const name = try forms.temporary(allocator, function, &serial);
            const next = if (index + 1 == sw.cases.items.len) sw.default_target else try forms.temporary(allocator, function, &serial);
            try block.instructions.append(allocator, .{ .result = name, .kind = .{ .icmp = .{
                .predicate = .eq,
                .operand_ty = wide,
                .lhs = condition,
                .rhs = .{ .int = bitsValue(case.value, bits).? },
            } } });
            block.terminator = .{ .condbr = .{ .cond_ty = .{ .int = 1 }, .cond = .{ .named = name }, .then_target = case.target, .else_target = next } };
            if (index == 0) result.blocks.items[block_index] = block else try result.blocks.append(allocator, block);
            block = ir.BasicBlock.init(next);
        }
    }
    return result;
}
