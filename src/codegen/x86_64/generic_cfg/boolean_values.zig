//! Give i1 truncations and byte loads a canonical 0/1 representation. Truncation
//! aliases otherwise retain upper bits that an ordinary branch test can observe.
const std = @import("std");
const Candidate = @import("rewrite_candidate.zig").Candidate;
const ir = @import("../../../ir.zig");
const forms = @import("scalar_forms.zig");

fn normalize(allocator: std.mem.Allocator, function: ir.Function, block: *ir.BasicBlock, serial: *usize, value: ir.Value, bits: u16, result: []const u8) !void {
    var low = value;
    if (value == .int) {
        low = .{ .int = value.int & 1 };
    } else if (bits != 32) {
        const name = try forms.temporary(allocator, function, serial);
        try block.instructions.append(allocator, .{ .result = name, .kind = .{ .cast = .{
            .op = if (bits < 32) .zext else .trunc,
            .from_ty = .{ .int = bits },
            .value = value,
            .to_ty = .{ .int = 32 },
        } } });
        low = .{ .named = name };
    }
    const masked = try forms.temporary(allocator, function, serial);
    try block.instructions.append(allocator, .{ .result = masked, .kind = .{ .binary = .{
        .op = if (value == .int) .add else .@"and",
        .ty = .{ .int = 32 },
        .lhs = low,
        .rhs = .{ .int = if (value == .int) 0 else 1 },
    } } });
    try block.instructions.append(allocator, .{ .result = result, .kind = .{ .icmp = .{
        .predicate = .ne,
        .operand_ty = .{ .int = 32 },
        .lhs = .{ .named = masked },
        .rhs = .{ .int = 0 },
    } } });
}

pub fn legalize(allocator: std.mem.Allocator, function: ir.Function) !?ir.Function {
    var candidate = Candidate.init(allocator, function);
    var serial: usize = 0;
    for (function.blocks.items, 0..) |original, block_index| {
        var block = original;
        block.instructions = .empty;
        for (original.instructions.items, 0..) |inst, instruction_index| {
            if (!inst.removed and inst.result != null) switch (inst.kind) {
                .cast => |cast| if (cast.op == .trunc and cast.to_ty.eql(.{ .int = 1 }) and
                    cast.from_ty == .int and cast.from_ty.int > 1 and cast.from_ty.int <= 128 and
                    (cast.value == .named or cast.value == .int))
                {
                    try candidate.begin(&block, block_index, instruction_index);
                    try normalize(allocator, function, &block, &serial, cast.value, cast.from_ty.int, inst.result.?);
                    continue;
                },
                .load => |load| if (load.ty.eql(.{ .int = 1 }) and load.ty_addrspace == null and
                    load.ptr_addrspace == null and !load.attrs.isBarrier() and load.attrs.syncscope == null)
                {
                    try candidate.begin(&block, block_index, instruction_index);
                    var byte = inst;
                    byte.result = try forms.temporary(allocator, function, &serial);
                    byte.kind.load.ty = .{ .int = 8 };
                    try block.instructions.append(allocator, byte);
                    try normalize(allocator, function, &block, &serial, .{ .named = byte.result.? }, 8, inst.result.?);
                    continue;
                },
                else => {},
            };
            try candidate.keep(&block, inst);
        }
        try candidate.finishBlock(block);
    }
    return candidate.finish();
}
