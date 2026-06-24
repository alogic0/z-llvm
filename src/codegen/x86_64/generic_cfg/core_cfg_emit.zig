const shared = @import("core_shared.zig");

const std = shared.std;
const ArgReg = shared.ArgReg;
const MachineFunction = shared.MachineFunction;

pub const GenericCfgLocalReg = enum {
    eax,
    ecx,
};

pub const GenericCfgBranchKind = enum {
    je,
    jne,
    jo,
    js,
    jae,
};

pub fn appendGenericCfgBlockLabel(allocator: std.mem.Allocator, machine: *MachineFunction, label: []const u8) !void {
    try machine.instructions.append(allocator, .{ .label = label });
}

pub fn appendGenericCfgConditionalBranch(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    kind: GenericCfgBranchKind,
    label: []const u8,
) !void {
    try machine.instructions.append(allocator, switch (kind) {
        .je => .{ .je = label },
        .jne => .{ .jne = label },
        .jo => .{ .jo = label },
        .js => .{ .js = label },
        .jae => .{ .jae = label },
    });
}

pub fn appendGenericCfgReturn(allocator: std.mem.Allocator, machine: *MachineFunction) !void {
    try machine.instructions.append(allocator, .ret);
}

pub fn appendGenericCfgI32Zero(allocator: std.mem.Allocator, machine: *MachineFunction, reg: GenericCfgLocalReg) !void {
    try machine.instructions.append(allocator, switch (reg) {
        .eax => .{ .mov_imm_eax = 0 },
        .ecx => .xor_ecx_ecx,
    });
}

pub fn appendGenericCfgAccumulatorAdd(allocator: std.mem.Allocator, machine: *MachineFunction) !void {
    try machine.instructions.append(allocator, .add_ecx_eax);
}

pub fn appendGenericCfgAccumulatorIncrement(allocator: std.mem.Allocator, machine: *MachineFunction) !void {
    try machine.instructions.append(allocator, .inc_rcx);
}

pub fn appendGenericCfgCompareParamZero(allocator: std.mem.Allocator, machine: *MachineFunction, reg: ArgReg) !void {
    try machine.instructions.append(allocator, .{ .test_arg32 = reg });
}

pub fn appendGenericCfgCompareLocalImm(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    reg: GenericCfgLocalReg,
    imm: i32,
) !void {
    try machine.instructions.append(allocator, switch (reg) {
        .ecx => .{ .cmp_ecx_imm32 = imm },
        .eax => .{ .cmp_eax_imm32 = imm },
    });
}

pub fn appendGenericCfgCompareLocalParam(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    reg: GenericCfgLocalReg,
    param: ArgReg,
) !void {
    if (reg != .ecx) return error.UnsupportedCodegenInstruction;
    try machine.instructions.append(allocator, .{ .cmp_ecx_arg32 = param });
}
