const std = @import("std");
const loop_info = @import("loop_info.zig");
const ir = @import("../ir.zig");

pub const AffineAddRec = struct {
    phi_result: []const u8,
    initial_value: ir.Value,
    step_value: ir.Value,
    next_value: []const u8,
    ty: ir.Type,

    pub fn isIntegerConstantStartStep(add_rec: AffineAddRec, start: i128, step: i128) bool {
        return valueIsInt(add_rec.initial_value, start) and valueIsInt(add_rec.step_value, step);
    }
};

pub fn affineAddRecs(allocator: std.mem.Allocator, function: ir.Function, natural_loop: loop_info.NaturalLoop) !std.ArrayList(AffineAddRec) {
    var simple = try natural_loop.simpleInductionVariables(allocator, function);
    defer simple.deinit(allocator);

    var add_recs: std.ArrayList(AffineAddRec) = .empty;
    errdefer add_recs.deinit(allocator);

    for (simple.items) |iv| {
        const ty = findPhiType(function, natural_loop.header, iv.phi_result) orelse continue;
        if (ty != .int) continue;
        try add_recs.append(allocator, .{
            .phi_result = iv.phi_result,
            .initial_value = iv.initial_value,
            .step_value = iv.step_value,
            .next_value = iv.next_value,
            .ty = ty,
        });
    }

    return add_recs;
}

pub fn valueIsInt(value: ir.Value, expected: i128) bool {
    return value == .int and value.int == expected;
}

fn findPhiType(function: ir.Function, header_index: usize, phi_result: []const u8) ?ir.Type {
    if (header_index >= function.blocks.items.len) return null;
    for (function.blocks.items[header_index].instructions.items) |instruction| {
        if (!std.mem.eql(u8, instruction.result orelse "", phi_result)) continue;
        return switch (instruction.kind) {
            .phi => |phi| phi.ty,
            .binary, .cast, .freeze, .icmp, .fcmp, .select, .alloca, .load, .store, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue, .gep, .call => null,
        };
    }
    return null;
}
