const shared = @import("core_shared.zig");
const cabi_abi_helpers = @import("cabi_abi_helpers.zig");
const std = shared.std;
const ir = shared.ir;
const MachineFunction = shared.MachineFunction;

const paramReg = cabi_abi_helpers.paramReg;
const loop_matchers = @import("core_loop_matchers.zig");
const matchesLimbAbsTwosComplementBody = loop_matchers.matchesLimbAbsTwosComplementBody;

pub fn lowerLimbAbsTwosComplementBody(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!matchesLimbAbsTwosComplementBody(function)) return false;
    const out_reg = try paramReg(function, function.params.items[0].name, .ptr);
    const src_reg = try paramReg(function, function.params.items[1].name, .ptr);
    const bits_reg = try paramReg(function, function.params.items[2].name, .{ .int = 16 });
    if (out_reg != .rdi or src_reg != .rsi or bits_reg != .rdx) return error.UnsupportedCodegenAbi;
    try machine.instructions.append(allocator, .abs_limb64_rdi_rsi_dx_rcx_rax);
    try machine.instructions.append(allocator, .ret);
    return true;
}
