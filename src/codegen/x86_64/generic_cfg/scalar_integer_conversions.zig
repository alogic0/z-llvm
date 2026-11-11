//! Exact integer bridges for the remaining ordinary scalar floating casts.
const std = @import("std");
const ir = @import("../../../ir.zig");
const Candidate = @import("rewrite_candidate.zig").Candidate;
const forms = @import("scalar_forms.zig");
const pair: ir.Type = .{ .int = 128 };
const word: ir.Type = .{ .int = 64 };

fn integer(ty: ir.Type) bool {
    return ty == .int and ty.int > 0 and ty.int <= 128;
}
fn symbol(cast: ir.CastInst) ?[]const u8 {
    if (integer(cast.to_ty) and (cast.op == .fptosi or cast.op == .fptoui)) return switch (cast.from_ty) {
        .half, .float => if (cast.op == .fptosi) "__fixsfti" else "__fixunssfti",
        .double => if (cast.op == .fptosi) "__fixdfti" else "__fixunsdfti",
        .fp128 => if (cast.op == .fptosi) "__fixtfti" else "__fixunstfti",
        else => null,
    };
    if (cast.to_ty == .fp128 and integer(cast.from_ty)) return switch (cast.op) {
        .sitofp => "__floattitf",
        .uitofp => "__floatuntitf",
        else => null,
    };
    return null;
}

const Builder = struct {
    allocator: std.mem.Allocator,
    function: ir.Function,
    block: *ir.BasicBlock,
    names: *forms.TemporaryNames,
    fn emit(b: Builder, kind: @FieldType(ir.Instruction, "kind")) !ir.Value {
        const name = try forms.temporary(b.allocator, b.function, b.names);
        try b.block.instructions.append(b.allocator, .{ .result = name, .kind = kind });
        return .{ .named = name };
    }
    fn argument(b: Builder, cast: ir.CastInst) !ir.Value {
        var input = cast.value;
        if (input == .undef or input == .poison or input == .zero_initializer) input = .{ .int = 0 };
        if (input == .int) {
            const bits = cast.from_ty.int;
            var raw: u128 = @bitCast(input.int);
            if (bits < 128) {
                const mask = (@as(u128, 1) << @as(u7, @intCast(bits))) - 1;
                raw &= mask;
                if (cast.op == .sitofp and raw & (@as(u128, 1) << @as(u7, @intCast(bits - 1))) != 0) raw |= ~mask;
            }
            return @import("binary128_arithmetic.zig").materializeIntegerArgument(b.allocator, b.function, b.block, b.names, .{ .op = cast.op, .from_ty = pair, .value = .{ .int = @bitCast(raw) }, .to_ty = cast.to_ty });
        }
        if (cast.from_ty.eql(pair)) return input;
        return b.emit(.{ .cast = .{ .op = if (cast.op == .sitofp) .sext else .zext, .from_ty = cast.from_ty, .value = input, .to_ty = pair } });
    }
    fn rewrite(b: Builder, original: ir.Instruction, callee: []const u8) !void {
        const cast = original.kind.cast;
        var call: ir.CallInst = .{ .callee = callee, .ret_ty = if (cast.to_ty == .fp128) .fp128 else pair, .args = .empty };
        if (cast.to_ty == .fp128) {
            try call.args.append(b.allocator, .{ .ty = pair, .value = try b.argument(cast) });
        } else {
            var value = cast.value;
            if (value == .undef or value == .poison or value == .zero_initializer) value = .{ .fp = "0.000000e+00" };
            const ty = if (cast.from_ty == .half) ir.Type.float else cast.from_ty;
            if (cast.from_ty == .half) value = try b.emit(.{ .cast = .{ .op = .fpext, .from_ty = .half, .value = value, .to_ty = .float } });
            try call.args.append(b.allocator, .{ .ty = ty, .value = value });
        }
        if (cast.to_ty == .fp128 or cast.to_ty.eql(pair)) {
            try b.block.instructions.append(b.allocator, .{ .result = original.result, .kind = .{ .call = call } });
        } else {
            const wide = try b.emit(.{ .call = call });
            const narrow_word = cast.to_ty.int < 64;
            const value = if (narrow_word) try b.emit(.{ .cast = .{ .op = .trunc, .from_ty = pair, .value = wide, .to_ty = word } }) else wide;
            try b.block.instructions.append(b.allocator, .{ .result = original.result, .kind = .{ .cast = .{ .op = .trunc, .from_ty = if (narrow_word) word else pair, .value = value, .to_ty = cast.to_ty } } });
        }
    }
};

pub fn legalize(allocator: std.mem.Allocator, function: ir.Function) !?ir.Function {
    var candidate = Candidate.init(allocator, function);
    var names: forms.TemporaryNames = .{};
    defer names.deinit(allocator);
    for (function.blocks.items, 0..) |original, block_index| {
        var block = original;
        block.instructions = .empty;
        const b: Builder = .{ .allocator = allocator, .function = function, .block = &block, .names = &names };
        for (original.instructions.items, 0..) |inst, instruction_index| {
            if (!inst.removed and inst.result != null and inst.kind == .cast) if (symbol(inst.kind.cast)) |callee| {
                if (!ir.identifiers.eql(function.name, callee) and
                    !(inst.kind.cast.from_ty == .half and ir.identifiers.eql(function.name, "__extendhfsf2")))
                {
                    try candidate.begin(&block, block_index, instruction_index);
                    try b.rewrite(inst, callee);
                    continue;
                }
            };
            try candidate.keep(&block, inst);
        }
        try candidate.finishBlock(block);
    }
    return candidate.finish();
}
