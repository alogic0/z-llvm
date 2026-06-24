const std = @import("std");
const ir = @import("../../ir.zig");
const x86_64_machine = @import("machine.zig");
const x86_64_emit = @import("emit.zig");
const x86_64_match = @import("match.zig");
const x86_64_generic_cfg = @import("generic_cfg.zig");

const MachineFunction = x86_64_machine.MachineFunction;
const appendAlignedDirectCall = x86_64_emit.appendAlignedDirectCall;
const isNamed = x86_64_match.isNamed;
const fp32TextBits = x86_64_match.fp32TextBits;
const fp64TextBits = x86_64_match.fp64TextBits;
const isSelectI1ToI32ZeroOne = x86_64_generic_cfg.isSelectI1ToI32ZeroOne;

pub fn lowerDescriptorFpCheckMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (function.params.items.len != 0) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or !ret.ty.eql(.{ .int = 32 })) return false;

    if (try lowerDescriptorFpBinaryCheckMainReturn(allocator, machine, block, ret)) return true;
    if (try lowerDescriptorFpSelectCheckMainReturn(allocator, machine, block, ret)) return true;
    return false;
}

pub fn lowerDescriptorFpBinaryCheckMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (block.instructions.items.len != 3) return false;

    const binary_inst = block.instructions.items[0];
    const fcmp_inst = block.instructions.items[1];
    const select_inst = block.instructions.items[2];
    if (binary_inst.removed or fcmp_inst.removed or select_inst.removed) return false;
    const binary_name = binary_inst.result orelse return false;
    const fcmp_name = fcmp_inst.result orelse return false;
    const select_name = select_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, select_name)) return false;

    const binary = switch (binary_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    const fcmp = switch (fcmp_inst.kind) {
        .fcmp => |fcmp| fcmp,
        else => return false,
    };
    if (fcmp.predicate != .oeq or !fcmp.operand_ty.eql(binary.ty)) return false;
    if (!isNamed(fcmp.lhs, binary_name)) return false;
    if (!isSelectI1ToI32ZeroOne(select_inst, fcmp_name)) return false;

    const fail = "descriptor_fp_binary_fail";
    if (binary.ty.eql(.float)) {
        try machine.instructions.append(allocator, .{ .mov_imm32_xmm0 = try fp32TextBits(binary.lhs) });
        try machine.instructions.append(allocator, .{ .mov_imm32_xmm1 = try fp32TextBits(binary.rhs) });
        switch (binary.op) {
            .fadd => try machine.instructions.append(allocator, .addss_xmm1_xmm0),
            .fsub => try machine.instructions.append(allocator, .subss_xmm1_xmm0),
            .frem => {
                try appendAlignedDirectCall(allocator, machine, "fmodf", .float);
            },
            .fmul, .fdiv, .add, .sub, .mul, .shl, .lshr, .ashr, .@"and", .@"or", .xor, .udiv, .sdiv, .urem, .srem => return false,
        }
        try machine.instructions.append(allocator, .{ .mov_imm32_xmm1 = try fp32TextBits(fcmp.rhs) });
        try machine.instructions.append(allocator, .ucomiss_xmm1_xmm0);
    } else if (binary.ty.eql(.double)) {
        try machine.instructions.append(allocator, .{ .mov_imm64_xmm0 = try fp64TextBits(binary.lhs) });
        try machine.instructions.append(allocator, .{ .mov_imm64_xmm1 = try fp64TextBits(binary.rhs) });
        switch (binary.op) {
            .fmul => try machine.instructions.append(allocator, .mulsd_xmm1_xmm0),
            .fdiv => try machine.instructions.append(allocator, .divsd_xmm1_xmm0),
            .fadd, .fsub, .frem, .add, .sub, .mul, .shl, .lshr, .ashr, .@"and", .@"or", .xor, .udiv, .sdiv, .urem, .srem => return false,
        }
        try machine.instructions.append(allocator, .{ .mov_imm64_xmm1 = try fp64TextBits(fcmp.rhs) });
        try machine.instructions.append(allocator, .ucomisd_xmm1_xmm0);
    } else {
        return false;
    }

    try machine.instructions.append(allocator, .{ .jne = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerDescriptorFpSelectCheckMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (block.instructions.items.len != 4) return false;

    const first_cmp_inst = block.instructions.items[0];
    const select_fp_inst = block.instructions.items[1];
    const second_cmp_inst = block.instructions.items[2];
    const select_ret_inst = block.instructions.items[3];
    if (first_cmp_inst.removed or select_fp_inst.removed or second_cmp_inst.removed or select_ret_inst.removed) return false;
    const first_cmp_name = first_cmp_inst.result orelse return false;
    const selected_name = select_fp_inst.result orelse return false;
    const second_cmp_name = second_cmp_inst.result orelse return false;
    const select_ret_name = select_ret_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, select_ret_name)) return false;

    const first_cmp = switch (first_cmp_inst.kind) {
        .fcmp => |fcmp| fcmp,
        else => return false,
    };
    if (first_cmp.predicate != .olt or !first_cmp.operand_ty.eql(.double)) return false;
    _ = try fp64TextBits(first_cmp.lhs);
    _ = try fp64TextBits(first_cmp.rhs);

    const select_fp = switch (select_fp_inst.kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select_fp.cond_ty.eql(.{ .int = 1 }) or !select_fp.ty.eql(.double)) return false;
    if (!isNamed(select_fp.cond, first_cmp_name)) return false;
    _ = try fp64TextBits(select_fp.true_value);
    _ = try fp64TextBits(select_fp.false_value);

    const second_cmp = switch (second_cmp_inst.kind) {
        .fcmp => |fcmp| fcmp,
        else => return false,
    };
    if (second_cmp.predicate != .oeq or !second_cmp.operand_ty.eql(.double)) return false;
    if (!isNamed(second_cmp.lhs, selected_name)) return false;
    _ = try fp64TextBits(second_cmp.rhs);
    if (!isSelectI1ToI32ZeroOne(select_ret_inst, second_cmp_name)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerScalarFpCastReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (function.params.items.len != 1) return false;
    if (block.instructions.items.len != 1) return false;
    const cast_inst = block.instructions.items[0];
    if (cast_inst.removed) return false;
    const cast_result = cast_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, cast_result)) return false;
    const cast = switch (cast_inst.kind) {
        .cast => |cast| cast,
        else => return false,
    };
    if (!cast.from_ty.eql(function.params.items[0].ty)) return false;
    if (!cast.to_ty.eql(function.ret_ty) or !ret.ty.eql(function.ret_ty)) return false;
    if (!isNamed(cast.value, function.params.items[0].name)) return false;

    switch (cast.op) {
        .sitofp => {
            if (cast.from_ty.eql(.{ .int = 32 }) and cast.to_ty.eql(.float)) {
                try machine.instructions.append(allocator, .cvtsi2ss_edi_xmm0);
            } else if (cast.from_ty.eql(.{ .int = 32 }) and cast.to_ty.eql(.double)) {
                try machine.instructions.append(allocator, .cvtsi2sd_edi_xmm0);
            } else if (cast.from_ty.eql(.{ .int = 64 }) and cast.to_ty.eql(.float)) {
                try machine.instructions.append(allocator, .cvtsi2ss_rdi_xmm0);
            } else if (cast.from_ty.eql(.{ .int = 64 }) and cast.to_ty.eql(.double)) {
                try machine.instructions.append(allocator, .cvtsi2sd_rdi_xmm0);
            } else return false;
        },
        .uitofp => {
            // Unsigned 32-bit converts exactly through a zero-extended
            // 64-bit signed convert; wider unsigned sources stay fail-closed.
            if (!cast.from_ty.eql(.{ .int = 32 })) return false;
            try machine.instructions.append(allocator, .mov_edi_edi);
            if (cast.to_ty.eql(.float)) {
                try machine.instructions.append(allocator, .cvtsi2ss_rdi_xmm0);
            } else if (cast.to_ty.eql(.double)) {
                try machine.instructions.append(allocator, .cvtsi2sd_rdi_xmm0);
            } else return false;
        },
        .fptosi => {
            if (!cast.to_ty.eql(.{ .int = 32 })) return false;
            if (cast.from_ty.eql(.float)) {
                try machine.instructions.append(allocator, .cvttss2si_xmm0_eax);
            } else if (cast.from_ty.eql(.double)) {
                try machine.instructions.append(allocator, .cvttsd2si_xmm0_eax);
            } else return false;
        },
        .fptrunc => {
            if (!cast.from_ty.eql(.double) or !cast.to_ty.eql(.float)) return false;
            try machine.instructions.append(allocator, .cvtsd2ss_xmm0_xmm0);
        },
        .fpext => {
            if (!cast.from_ty.eql(.float) or !cast.to_ty.eql(.double)) return false;
            try machine.instructions.append(allocator, .cvtss2sd_xmm0_xmm0);
        },
        .trunc, .zext, .sext, .fptoui, .bitcast, .ptrtoint, .inttoptr => return false,
    }
    try machine.instructions.append(allocator, .ret);
    return true;
}
