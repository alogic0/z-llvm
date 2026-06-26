const std = @import("std");
const ir = @import("../../ir.zig");
const machine_ir = @import("machine.zig");
const types = @import("types.zig");

const ArgReg = types.ArgReg;
const XmmReg = types.XmmReg;
const MachineFunction = machine_ir.MachineFunction;

pub const max_sysv_stack_call_args = 256;

pub const SysVCallTarget = union(enum) {
    direct: []const u8,
    indirect_from_reg: ArgReg,
};

pub fn appendIntegerOverflowCall(allocator: std.mem.Allocator, machine: *MachineFunction, label: []const u8) !void {
    try appendPanicCall(allocator, machine, label, "debug.FullPanic((function 'defaultPanic')).integerOverflow");
}

pub fn appendStackFrame(allocator: std.mem.Allocator, machine: *MachineFunction, bytes: u8) !void {
    switch (bytes) {
        8 => try machine.instructions.append(allocator, .sub_rsp_8),
        24 => try machine.instructions.append(allocator, .sub_rsp_24),
        40 => try machine.instructions.append(allocator, .sub_rsp_40),
        56 => try machine.instructions.append(allocator, .sub_rsp_56),
        else => return error.UnsupportedCodegenAbi,
    }
}

pub fn appendStackFrameEnd(allocator: std.mem.Allocator, machine: *MachineFunction, bytes: u8) !void {
    switch (bytes) {
        8 => try machine.instructions.append(allocator, .add_rsp_8),
        24 => try machine.instructions.append(allocator, .add_rsp_24),
        40 => try machine.instructions.append(allocator, .add_rsp_40),
        56 => try machine.instructions.append(allocator, .add_rsp_56),
        else => return error.UnsupportedCodegenAbi,
    }
}

pub fn appendDirectCall(allocator: std.mem.Allocator, machine: *MachineFunction, symbol: []const u8, ret_ty: ir.Type) !void {
    try machine.instructions.append(allocator, .{ .direct_call = .{
        .symbol = symbol,
        .ret_ty = ret_ty,
    } });
}

pub fn appendIndirectCallRax(allocator: std.mem.Allocator, machine: *MachineFunction, ret_ty: ir.Type) !void {
    try machine.instructions.append(allocator, .{ .indirect_call_rax = ret_ty });
}

pub fn appendAlignedDirectCall(allocator: std.mem.Allocator, machine: *MachineFunction, symbol: []const u8, ret_ty: ir.Type) !void {
    try appendStackFrame(allocator, machine, 8);
    try appendDirectCall(allocator, machine, symbol, ret_ty);
    try appendStackFrameEnd(allocator, machine, 8);
}

pub fn appendAlignedIndirectCallRax(allocator: std.mem.Allocator, machine: *MachineFunction, ret_ty: ir.Type) !void {
    try appendStackFrame(allocator, machine, 8);
    try appendIndirectCallRax(allocator, machine, ret_ty);
    try appendStackFrameEnd(allocator, machine, 8);
}

pub fn appendDirectCallWithStackArgs(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    symbol: []const u8,
    ret_ty: ir.Type,
    stack_arg_count: usize,
) !void {
    if (stack_arg_count == 0) return appendAlignedDirectCall(allocator, machine, symbol, ret_ty);
    try appendDirectCall(allocator, machine, symbol, ret_ty);
    try appendStackArgCallCleanup(allocator, machine, stack_arg_count);
}

pub fn appendIndirectCallRaxWithStackArgs(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    ret_ty: ir.Type,
    stack_arg_count: usize,
) !void {
    if (stack_arg_count == 0) return appendAlignedIndirectCallRax(allocator, machine, ret_ty);
    try appendIndirectCallRax(allocator, machine, ret_ty);
    try appendStackArgCallCleanup(allocator, machine, stack_arg_count);
}

pub fn appendStackArgCallCleanup(allocator: std.mem.Allocator, machine: *MachineFunction, stack_arg_count: usize) !void {
    if (stack_arg_count == 0 or stack_arg_count > max_sysv_stack_call_args) return error.UnsupportedCodegenAbi;
    const cleanup_bytes = stack_arg_count * 8 + if (stack_arg_count % 2 == 0) @as(usize, 8) else 0;
    switch (cleanup_bytes) {
        8 => try machine.instructions.append(allocator, .add_rsp_8),
        24 => try machine.instructions.append(allocator, .add_rsp_24),
        40 => try machine.instructions.append(allocator, .add_rsp_40),
        56 => try machine.instructions.append(allocator, .add_rsp_56),
        else => {
            if (cleanup_bytes <= std.math.maxInt(i8)) {
                try machine.instructions.append(allocator, .{ .add_rsp_imm8 = @intCast(cleanup_bytes) });
            } else if (cleanup_bytes <= std.math.maxInt(u32)) {
                try machine.instructions.append(allocator, .{ .add_rsp_imm32 = @intCast(cleanup_bytes) });
            } else {
                return error.UnsupportedCodegenAbi;
            }
        },
    }
}

pub fn appendLoadStackDispArg32(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    reg: ArgReg,
    offset: usize,
) !void {
    if (offset <= std.math.maxInt(i8)) {
        try machine.instructions.append(allocator, .{ .load_stack_disp8_arg32 = .{ .reg = reg, .disp = @intCast(offset) } });
    } else if (offset <= std.math.maxInt(u32)) {
        try machine.instructions.append(allocator, .{ .load_stack_disp32_arg32 = .{ .reg = reg, .disp = @intCast(offset) } });
    } else {
        return error.UnsupportedCodegenAbi;
    }
}

pub fn appendLoadStackDispArg64(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    reg: ArgReg,
    offset: usize,
) !void {
    if (offset <= std.math.maxInt(i8)) {
        try machine.instructions.append(allocator, .{ .load_stack_disp8_arg64 = .{ .reg = reg, .disp = @intCast(offset) } });
    } else if (offset <= std.math.maxInt(u32)) {
        try machine.instructions.append(allocator, .{ .load_stack_disp32_arg64 = .{ .reg = reg, .disp = @intCast(offset) } });
    } else {
        return error.UnsupportedCodegenAbi;
    }
}

pub fn appendMoveImmToArgReg(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    reg: ArgReg,
    value: i64,
) !void {
    switch (reg) {
        .rdi => try machine.instructions.append(allocator, .{ .mov_imm_rdi = value }),
        .rsi => try machine.instructions.append(allocator, .{ .mov_imm_rsi = value }),
        .rdx => try machine.instructions.append(allocator, .{ .mov_imm_rdx = value }),
        .rcx => try machine.instructions.append(allocator, .{ .mov_imm_rcx = value }),
        .r8 => try machine.instructions.append(allocator, .{ .mov_imm_r8 = value }),
        .r9 => try machine.instructions.append(allocator, .{ .mov_imm_r9 = value }),
    }
}

pub fn appendMoveImm32ToXmm(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    reg: XmmReg,
    bits: u32,
) !void {
    try machine.instructions.append(allocator, .{ .mov_imm32_xmm = .{ .reg = reg, .bits = bits } });
}

pub fn appendMoveImm64ToXmm(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    reg: XmmReg,
    bits: u64,
) !void {
    try machine.instructions.append(allocator, .{ .mov_imm64_xmm = .{ .reg = reg, .bits = bits } });
}

pub fn setupSysVCallTarget(allocator: std.mem.Allocator, machine: *MachineFunction, call_target: SysVCallTarget) !void {
    switch (call_target) {
        .direct => {},
        .indirect_from_reg => |reg| try machine.instructions.append(allocator, .{ .mov_arg_rax = reg }),
    }
}

pub fn appendSysVCallTarget(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    call_target: SysVCallTarget,
    ret_ty: ir.Type,
) !void {
    switch (call_target) {
        .direct => |symbol| try appendDirectCall(allocator, machine, symbol, ret_ty),
        .indirect_from_reg => try appendIndirectCallRax(allocator, machine, ret_ty),
    }
}

pub fn appendAlignedSysVCallTarget(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    call_target: SysVCallTarget,
    ret_ty: ir.Type,
) !void {
    switch (call_target) {
        .direct => |symbol| try appendAlignedDirectCall(allocator, machine, symbol, ret_ty),
        .indirect_from_reg => {
            try setupSysVCallTarget(allocator, machine, call_target);
            try appendAlignedIndirectCallRax(allocator, machine, ret_ty);
        },
    }
}

pub fn appendSysVCallTargetWithStackArgs(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    call_target: SysVCallTarget,
    ret_ty: ir.Type,
    stack_arg_count: usize,
) !void {
    switch (call_target) {
        .direct => |symbol| try appendDirectCallWithStackArgs(allocator, machine, symbol, ret_ty, stack_arg_count),
        .indirect_from_reg => try appendIndirectCallRaxWithStackArgs(allocator, machine, ret_ty, stack_arg_count),
    }
}

pub fn appendPanicCall(allocator: std.mem.Allocator, machine: *MachineFunction, label: []const u8, symbol: []const u8) !void {
    try machine.instructions.append(allocator, .{ .label = label });
    try appendAlignedDirectCall(allocator, machine, symbol, .void);
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
}
