const std = @import("std");
const ir = @import("../../../ir.zig");
const fields = @import("cabi_aggregate_fields.zig");
const shared = @import("core_shared.zig");
const abi = @import("cabi_abi_helpers.zig");
const calls = @import("cabi_call_lowering.zig");

pub const ParameterAddress = struct { reg: shared.ArgReg, offset: u32 };

pub fn resolveParameter(function: ir.Function, block: ir.BasicBlock, ptr: ir.Value) ?ParameterAddress {
    var current = ptr;
    var offset: u32 = 0;
    var budget = block.instructions.items.len + 1;
    while (budget > 0) : (budget -= 1) {
        if (current != .named) return null;
        if (abi.sysvIntegerParamRegOrNull(function, current.named, .ptr) catch null) |reg| return .{ .reg = reg, .offset = offset };
        const inst = calls.findInstruction(block, current.named) orelse return null;
        switch (inst.kind) {
            .cast => |cast| {
                if (cast.op != .bitcast or cast.from_ty != .ptr or cast.to_ty != .ptr) return null;
                current = cast.value;
            },
            .gep => |gep| {
                offset = std.math.add(u32, offset, constantGepByteOffset(gep) orelse return null) catch return null;
                if (offset > std.math.maxInt(i32)) return null;
                current = gep.ptr;
            },
            else => return null,
        }
    }
    return null;
}

pub fn constantGepByteOffset(gep: ir.GepInst) ?u32 {
    const layout = shared.x86_64SysVDataLayout() catch return null;
    const offset = fields.aggregateGepByteOffset(layout, gep.source_ty, gep) orelse return null;
    if (offset > std.math.maxInt(i32)) return null;
    return @intCast(offset);
}

pub fn appendLoad64(allocator: std.mem.Allocator, machine: *shared.MachineFunction, reg: shared.ArgReg, offset: u32) !void {
    if (offset > std.math.maxInt(i32)) return error.UnsupportedCodegenAbi;
    try machine.instructions.append(allocator, if (offset <= std.math.maxInt(i8))
        .{ .load_arg_ptr_disp8_rax = .{ .reg = reg, .offset = @intCast(offset) } }
    else
        .{ .load_arg_ptr_disp32_rax = .{ .reg = reg, .offset = offset } });
}
