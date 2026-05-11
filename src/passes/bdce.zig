const std = @import("std");
const def_use = @import("../analysis/def_use.zig");
const ir = @import("../ir.zig");
const pass_manager = @import("../pass_manager.zig");

pub const pass: pass_manager.ModulePass = .{
    .name = "bdce",
    .category = .scalar,
    .target_status = "fixture-equivalent for listed demanded-bit fixtures",
    .upstream_owner = "llvm/lib/Transforms/Scalar/BDCE.cpp",
    .run = run,
};

fn run(module: *ir.Module, _: *pass_manager.Context) !pass_manager.PassResult {
    var changed = false;

    for (module.functions.items) |*function| {
        var uses = try def_use.UseCounts.collectFunction(module.allocator, function.*);
        defer uses.deinit();

        for (function.blocks.items) |*block| {
            for (block.instructions.items) |*instruction| {
                if (instruction.removed) continue;
                if (try simplifyAndMaskChain(function, &uses, instruction)) changed = true;
            }
        }
    }

    return if (changed) .changed else .unchanged;
}

fn simplifyAndMaskChain(function: *ir.Function, uses: *def_use.UseCounts, instruction: *ir.Instruction) !bool {
    const outer = switch (instruction.kind) {
        .binary => |*binary| binary,
        else => return false,
    };
    if (outer.op != .@"and" or outer.flags.any()) return false;
    if (outer.lhs != .named or outer.rhs != .int) return false;

    const producer = findLiveInstruction(function, outer.lhs.named) orelse return false;
    const producer_name = producer.result orelse return false;
    if ((uses.counts.get(producer_name) orelse 0) != 1) return false;

    const inner = switch (producer.kind) {
        .binary => |*binary| binary,
        else => return false,
    };
    if (inner.op != .@"and" or inner.flags.any()) return false;
    if (!inner.ty.eql(outer.ty)) return false;
    if (inner.rhs != .int) return false;

    const outer_mask = unsignedMask(outer.rhs.int, outer.ty) orelse return false;
    const inner_mask = unsignedMask(inner.rhs.int, inner.ty) orelse return false;
    if ((outer_mask & ~inner_mask) != 0) return false;

    uses.removeInstructionOperands(instruction.*);
    outer.lhs = inner.lhs;
    try uses.addInstructionOperands(instruction.*);
    producer.removed = true;
    return true;
}

fn findLiveInstruction(function: *ir.Function, result: []const u8) ?*ir.Instruction {
    for (function.blocks.items) |*block| {
        for (block.instructions.items) |*instruction| {
            if (instruction.removed) continue;
            const name = instruction.result orelse continue;
            if (std.mem.eql(u8, name, result)) return instruction;
        }
    }
    return null;
}

fn unsignedMask(value: i128, ty: ir.Type) ?u128 {
    const bits = switch (ty) {
        .int => |bits| bits,
        .void, .float, .double, .ptr, .aggregate, .vector => return null,
    };
    if (bits == 0 or bits > 64) return null;
    const full_mask = (@as(u128, 1) << @intCast(bits)) - 1;
    const raw: u128 = if (value >= 0)
        @intCast(value)
    else
        @intCast((@as(i128, 1) << @intCast(bits)) + value);
    return raw & full_mask;
}
