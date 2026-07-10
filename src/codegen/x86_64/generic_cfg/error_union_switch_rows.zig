const shared = @import("core_shared.zig");
const core_cfg_emit = @import("core_cfg_emit.zig");
const cabi_abi_helpers = @import("cabi_abi_helpers.zig");
const cabi_call_lowering = @import("cabi_call_lowering.zig");
const terminal_values = @import("terminal_values.zig");

const std = shared.std;
const ir = shared.ir;
const MachineFunction = shared.MachineFunction;
const MachineBinaryOp = shared.MachineBinaryOp;
const ArgReg = shared.ArgReg;

const appendStackFrame = shared.appendStackFrame;
const appendStackFrameEnd = shared.appendStackFrameEnd;
const appendGenericCfgBlockLabel = core_cfg_emit.appendGenericCfgBlockLabel;
const appendGenericCfgConditionalBranch = core_cfg_emit.appendGenericCfgConditionalBranch;
const appendGenericCfgReturn = core_cfg_emit.appendGenericCfgReturn;
const appendAlignedCallPreservingI32Params = cabi_call_lowering.appendAlignedCallPreservingI32Params;
const blockIndex = cabi_abi_helpers.blockIndex;
const blockHasCondbr = terminal_values.blockHasCondbr;
const blockIsUnreachable = terminal_values.blockIsUnreachable;
const blockSwitchTerminator = terminal_values.blockSwitchTerminator;
const commonSwitchMergeBlock = terminal_values.commonSwitchMergeBlock;
const firstPhiReturn = terminal_values.firstPhiReturn;
const i32Value = shared.i32Value;
const i64Value = shared.i64Value;
const isInt = shared.isInt;
const isNamed = shared.isNamed;
const LiveParamSet = cabi_call_lowering.LiveParamSet;
const machineBinaryOp = cabi_call_lowering.machineBinaryOp;
const noteLiveValueSet = cabi_call_lowering.noteLiveValueSet;
const paramReg = cabi_abi_helpers.paramReg;
const findInstruction = cabi_call_lowering.findInstruction;
const blockBranchesTo = terminal_values.blockBranchesTo;
const linearTerminalBranchUsesAllBlocks = terminal_values.linearTerminalBranchUsesAllBlocks;
const ownedMachineLabel = terminal_values.ownedMachineLabel;
const emitGenericCfgTerminalI32ValueIntoEax = terminal_values.emitGenericCfgTerminalI32ValueIntoEax;
const emitGenericCfgTerminalI64ValueIntoRax = terminal_values.emitGenericCfgTerminalI64ValueIntoRax;
const emitGenericCfgTerminalReturnBlock = terminal_values.emitGenericCfgTerminalReturnBlock;
const genericCfgSupportsTerminalReturnBlock = terminal_values.genericCfgSupportsTerminalReturnBlock;
const phiIncomingForBlock = terminal_values.phiIncomingForBlock;
const singleBrTarget = terminal_values.singleBrTarget;
const paramRegOrNull = cabi_abi_helpers.paramRegOrNull;
const try_rows = @import("error_union_try_rows.zig");
const supportsDirectI64Call = try_rows.supportsDirectI64Call;
const supportsDirectI16I32ToI32Call = try_rows.supportsDirectI16I32ToI32Call;
const errorUnionTryGuardCallResult = try_rows.errorUnionTryGuardCallResult;
const blockReturnsNamedValue = try_rows.blockReturnsNamedValue;
const payloadAddFromCallResult = try_rows.payloadAddFromCallResult;
const emitTwoI32ArgCallIntoRax = try_rows.emitTwoI32ArgCallIntoRax;
const terminalConstI32Return = try_rows.terminalConstI32Return;
const PayloadBinaryWrapReturn = try_rows.PayloadBinaryWrapReturn;
const payloadValueFromCallResult = try_rows.payloadValueFromCallResult;

pub const ErrorUnionTryPayloadBranchReturn = struct {
    entry: ir.BasicBlock,
    call_name: []const u8,
    call: ir.CallInst,
    err_block: ir.BasicBlock,
    cont_block: ir.BasicBlock,
    true_block: ir.BasicBlock,
    false_block: ir.BasicBlock,
    compare: PayloadGreaterConst,
    delta_reg: ArgReg,
    true_op: MachineBinaryOp,
    false_op: MachineBinaryOp,
};

pub const PayloadGreaterConstPredicate = enum {
    signed_gt,
    unsigned_gt,
};

pub const PayloadGreaterConst = union(PayloadGreaterConstPredicate) {
    signed_gt: i32,
    unsigned_gt: i32,
};

pub fn lowerGenericCfgErrorUnionTryPayloadBranchReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    const plan = errorUnionTryPayloadBranchReturn(function) orelse return false;
    const frame_bytes: u8 = 24;
    const epilogue_label = try ownedMachineLabel(
        allocator,
        machine,
        "generic_cfg_try_payload_branch_{}_generic_cfg_select_end",
        .{machine.instructions.items.len},
    );

    try appendStackFrame(allocator, machine, frame_bytes);
    try machine.instructions.append(allocator, .{ .spill_arg_rsp = .{ .frame_index = .slot2, .reg = plan.delta_reg } });

    try emitTwoI32ArgCallIntoRax(allocator, machine, function, plan.entry, plan.call);
    try machine.instructions.append(allocator, .{ .spill_rax_rsp = .slot0 });
    try machine.instructions.append(allocator, .{ .and_eax_imm32 = 65535 });
    try machine.instructions.append(allocator, .test_eax_eax);
    try appendGenericCfgConditionalBranch(allocator, machine, .jne, plan.err_block.name);

    try appendGenericCfgBlockLabel(allocator, machine, plan.cont_block.name);
    try machine.instructions.append(allocator, .{ .reload_rsp_rax = .slot0 });
    try machine.instructions.append(allocator, .{ .shr_rax_imm6 = 16 });
    switch (plan.compare) {
        .signed_gt => |imm| {
            try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = imm });
            try machine.instructions.append(allocator, .{ .jle = plan.false_block.name });

            try appendGenericCfgBlockLabel(allocator, machine, plan.true_block.name);
            try emitPayloadBinaryWrapReturn(allocator, machine, plan.true_op, plan.delta_reg, epilogue_label);

            try appendGenericCfgBlockLabel(allocator, machine, plan.false_block.name);
            try emitPayloadBinaryWrapReturn(allocator, machine, plan.false_op, plan.delta_reg, epilogue_label);
        },
        .unsigned_gt => |imm| {
            if (imm == std.math.maxInt(i32)) return error.UnsupportedCodegenControlFlow;
            try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = imm + 1 });
            try machine.instructions.append(allocator, .{ .jae = plan.true_block.name });

            try appendGenericCfgBlockLabel(allocator, machine, plan.false_block.name);
            try emitPayloadBinaryWrapReturn(allocator, machine, plan.false_op, plan.delta_reg, epilogue_label);

            try appendGenericCfgBlockLabel(allocator, machine, plan.true_block.name);
            try emitPayloadBinaryWrapReturn(allocator, machine, plan.true_op, plan.delta_reg, epilogue_label);
        },
    }

    try appendGenericCfgBlockLabel(allocator, machine, plan.err_block.name);
    try machine.instructions.append(allocator, .{ .reload_rsp_rax = .slot0 });
    try machine.instructions.append(allocator, .{ .jmp = epilogue_label });

    try appendGenericCfgBlockLabel(allocator, machine, epilogue_label);
    try appendStackFrameEnd(allocator, machine, frame_bytes);
    try appendGenericCfgReturn(allocator, machine);
    return true;
}

pub fn emitPayloadBinaryWrapReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    op: MachineBinaryOp,
    delta_reg: ArgReg,
    epilogue_label: []const u8,
) !void {
    try machine.instructions.append(allocator, .{ .reload_rsp_rax = .slot0 });
    try machine.instructions.append(allocator, .{ .shr_rax_imm6 = 16 });
    try machine.instructions.append(allocator, .{ .reload_arg_rsp = .{ .frame_index = .slot2, .reg = delta_reg } });
    try machine.instructions.append(allocator, .{ .binary_arg_eax = .{ .op = op, .reg = delta_reg } });
    try machine.instructions.append(allocator, .{ .shl_rax_imm6 = 16 });
    try machine.instructions.append(allocator, .{ .jmp = epilogue_label });
}

pub fn errorUnionTryPayloadBranchReturn(function: ir.Function) ?ErrorUnionTryPayloadBranchReturn {
    if (!function.ret_ty.eql(.{ .int = 64 }) or function.blocks.items.len != 5) return null;
    const entry = function.blocks.items[0];
    const entry_condbr = switch (entry.terminator orelse return null) {
        .condbr => |condbr| condbr,
        else => return null,
    };
    if (!entry_condbr.cond_ty.eql(.{ .int = 1 })) return null;
    const call_name = errorUnionTryGuardCallResult(entry, entry_condbr.cond) orelse return null;
    const call_instruction = findInstruction(entry, call_name) orelse return null;
    const call = switch (call_instruction.kind) {
        .call => |call| call,
        else => return null,
    };
    if (!supportsDirectI64Call(call) or call.args.items.len != 2) return null;

    const then_block = function.blocks.items[blockIndex(function, entry_condbr.then_target) orelse return null];
    const else_block = function.blocks.items[blockIndex(function, entry_condbr.else_target) orelse return null];
    const then_is_cont = blockHasCondbr(then_block);
    const else_is_cont = blockHasCondbr(else_block);
    if (then_is_cont == else_is_cont) return null;
    const cont_block = if (then_is_cont) then_block else else_block;
    const err_block = if (then_is_cont) else_block else then_block;
    if (!blockReturnsNamedValue(err_block, call_name, .{ .int = 64 })) return null;

    const cont_condbr = switch (cont_block.terminator orelse return null) {
        .condbr => |condbr| condbr,
        else => return null,
    };
    if (!cont_condbr.cond_ty.eql(.{ .int = 1 })) return null;
    const compare = payloadGreaterConst(cont_block, cont_condbr.cond, call_name) orelse return null;
    const true_block = function.blocks.items[blockIndex(function, cont_condbr.then_target) orelse return null];
    const false_block = function.blocks.items[blockIndex(function, cont_condbr.else_target) orelse return null];
    const true_return = payloadBinaryWrapReturn(function, cont_block, true_block, call_name) orelse return null;
    const false_return = payloadBinaryWrapReturn(function, cont_block, false_block, call_name) orelse return null;
    if (true_return.reg != false_return.reg) return null;
    if (!linearTerminalBranchUsesAllBlocks(
        function,
        blockIndex(function, cont_block.name) orelse return null,
        blockIndex(function, err_block.name) orelse return null,
        blockIndex(function, true_block.name) orelse return null,
        blockIndex(function, false_block.name) orelse return null,
    )) return null;

    return .{
        .entry = entry,
        .call_name = call_name,
        .call = call,
        .err_block = err_block,
        .cont_block = cont_block,
        .true_block = true_block,
        .false_block = false_block,
        .compare = compare,
        .delta_reg = true_return.reg,
        .true_op = true_return.op,
        .false_op = false_return.op,
    };
}

pub fn payloadGreaterConst(block: ir.BasicBlock, cond: ir.Value, call_name: []const u8) ?PayloadGreaterConst {
    const cond_name = switch (cond) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    const cond_inst = findInstruction(block, cond_name) orelse return null;
    const icmp = switch (cond_inst.kind) {
        .icmp => |icmp| icmp,
        else => return null,
    };
    if (!icmp.operand_ty.eql(.{ .int = 32 })) return null;
    const predicate: PayloadGreaterConstPredicate = switch (icmp.predicate) {
        .sgt => .signed_gt,
        .ugt => .unsigned_gt,
        else => return null,
    };
    const rhs = switch (icmp.rhs) {
        .int => |int| i32Value(int) catch return null,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    if (!payloadValueFromCallResult(block, icmp.lhs, call_name)) return null;
    return switch (predicate) {
        .signed_gt => .{ .signed_gt = rhs },
        .unsigned_gt => .{ .unsigned_gt = rhs },
    };
}

pub fn payloadBinaryWrapReturn(function: ir.Function, payload_scope: ir.BasicBlock, block: ir.BasicBlock, call_name: []const u8) ?PayloadBinaryWrapReturn {
    const ret = switch (block.terminator orelse return null) {
        .ret => |ret| ret,
        else => return null,
    };
    if (!ret.ty.eql(.{ .int = 64 })) return null;
    const shl_name = switch (ret.value orelse return null) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    const shl_inst = findInstruction(block, shl_name) orelse return null;
    const shl = switch (shl_inst.kind) {
        .binary => |binary| binary,
        else => return null,
    };
    if (!shl.ty.eql(.{ .int = 64 }) or shl.op != .shl or !isInt(shl.rhs, 16)) return null;
    const zext_name = switch (shl.lhs) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    const zext_inst = findInstruction(block, zext_name) orelse return null;
    const zext = switch (zext_inst.kind) {
        .cast => |cast| cast,
        else => return null,
    };
    if (zext.op != .zext or !zext.from_ty.eql(.{ .int = 32 }) or !zext.to_ty.eql(.{ .int = 64 })) return null;
    const binary_name = switch (zext.value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    const binary_inst = findInstruction(block, binary_name) orelse return null;
    const binary = switch (binary_inst.kind) {
        .binary => |binary| binary,
        else => return null,
    };
    if (!binary.ty.eql(.{ .int = 32 }) or (binary.op != .add and binary.op != .sub)) return null;
    if (!payloadValueFromCallResult(payload_scope, binary.lhs, call_name)) return null;
    const reg = switch (binary.rhs) {
        .named => |name| paramReg(function, name, .{ .int = 32 }) catch return null,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    const op: MachineBinaryOp = switch (binary.op) {
        .add => .add,
        .sub => .sub,
        else => unreachable,
    };
    return .{ .op = op, .reg = reg };
}

pub const ErrorUnionTrySwitchCase = struct {
    value: i32,
    block: ir.BasicBlock,
    add_imm: u8,
};

pub const ErrorUnionTrySwitchReturn = struct {
    entry: ir.BasicBlock,
    call_name: []const u8,
    call: ir.CallInst,
    err_block: ir.BasicBlock,
    switch_block: ir.BasicBlock,
    merge_block: ir.BasicBlock,
    mask: i32,
    cases: [8]ErrorUnionTrySwitchCase,
    case_count: usize,
    default_case: ErrorUnionTrySwitchCase,
};

pub fn lowerGenericCfgErrorUnionTrySwitchReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    const plan = errorUnionTrySwitchReturn(function) orelse return false;
    const frame_bytes: u8 = 24;
    const epilogue_label = try ownedMachineLabel(
        allocator,
        machine,
        "generic_cfg_try_switch_{}_generic_cfg_select_end",
        .{machine.instructions.items.len},
    );

    try appendStackFrame(allocator, machine, frame_bytes);
    try emitTwoI32ArgCallIntoRax(allocator, machine, function, plan.entry, plan.call);
    try machine.instructions.append(allocator, .{ .spill_rax_rsp = .slot0 });
    try machine.instructions.append(allocator, .{ .and_eax_imm32 = 65535 });
    try machine.instructions.append(allocator, .test_eax_eax);
    try appendGenericCfgConditionalBranch(allocator, machine, .jne, plan.err_block.name);

    try appendGenericCfgBlockLabel(allocator, machine, plan.switch_block.name);
    try machine.instructions.append(allocator, .{ .reload_rsp_rax = .slot0 });
    try machine.instructions.append(allocator, .{ .shr_rax_imm6 = 16 });
    try machine.instructions.append(allocator, .{ .spill_rax_rsp = .slot2 });
    if (plan.mask != 0) try machine.instructions.append(allocator, .{ .and_eax_imm32 = plan.mask });
    for (plan.cases[0..plan.case_count]) |case| {
        try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = case.value });
        try appendGenericCfgConditionalBranch(allocator, machine, .je, case.block.name);
    }
    try machine.instructions.append(allocator, .{ .jmp = plan.default_case.block.name });

    for (plan.cases[0..plan.case_count]) |case| {
        try appendGenericCfgBlockLabel(allocator, machine, case.block.name);
        try emitPayloadAddImmWrapFromSlot(allocator, machine, case.add_imm, epilogue_label);
    }
    try appendGenericCfgBlockLabel(allocator, machine, plan.default_case.block.name);
    try emitPayloadAddImmWrapFromSlot(allocator, machine, plan.default_case.add_imm, epilogue_label);

    try appendGenericCfgBlockLabel(allocator, machine, plan.err_block.name);
    try machine.instructions.append(allocator, .{ .reload_rsp_rax = .slot0 });
    try machine.instructions.append(allocator, .{ .jmp = epilogue_label });

    try appendGenericCfgBlockLabel(allocator, machine, epilogue_label);
    try appendStackFrameEnd(allocator, machine, frame_bytes);
    try appendGenericCfgReturn(allocator, machine);
    return true;
}

pub fn emitPayloadAddImmWrapFromSlot(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    add_imm: u8,
    epilogue_label: []const u8,
) !void {
    try machine.instructions.append(allocator, .{ .reload_rsp_rax = .slot2 });
    if (add_imm != 0) try machine.instructions.append(allocator, .{ .add_rax_imm8 = add_imm });
    try machine.instructions.append(allocator, .{ .shl_rax_imm6 = 16 });
    try machine.instructions.append(allocator, .{ .jmp = epilogue_label });
}

pub fn errorUnionTrySwitchReturn(function: ir.Function) ?ErrorUnionTrySwitchReturn {
    if (!function.ret_ty.eql(.{ .int = 64 }) or function.blocks.items.len < 6) return null;
    const entry = function.blocks.items[0];
    const entry_condbr = switch (entry.terminator orelse return null) {
        .condbr => |condbr| condbr,
        else => return null,
    };
    if (!entry_condbr.cond_ty.eql(.{ .int = 1 })) return null;
    const call_name = errorUnionTryGuardCallResult(entry, entry_condbr.cond) orelse return null;
    const call_instruction = findInstruction(entry, call_name) orelse return null;
    const call = switch (call_instruction.kind) {
        .call => |call| call,
        else => return null,
    };
    if (!supportsDirectI64Call(call) or call.args.items.len != 2) return null;

    const then_block = function.blocks.items[blockIndex(function, entry_condbr.then_target) orelse return null];
    const else_block = function.blocks.items[blockIndex(function, entry_condbr.else_target) orelse return null];
    const then_is_switch = blockSwitchTerminator(then_block) != null;
    const else_is_switch = blockSwitchTerminator(else_block) != null;
    if (then_is_switch == else_is_switch) return null;
    const switch_block = if (then_is_switch) then_block else else_block;
    const err_block = if (then_is_switch) else_block else then_block;
    if (!blockReturnsNamedValue(err_block, call_name, .{ .int = 64 })) return null;

    const switch_term = blockSwitchTerminator(switch_block) orelse return null;
    if (!switch_term.cond_ty.eql(.{ .int = 32 })) return null;
    const mask = payloadMaskConst(switch_block, switch_term.cond, call_name) orelse return null;
    if (switch_term.cases.items.len == 0 or switch_term.cases.items.len > 8) return null;
    const merge_block = commonSwitchMergeBlock(function, switch_term) orelse return null;
    const phi = firstPhiReturn(function, merge_block) orelse return null;
    if (!phi.ty.eql(.{ .int = 64 })) return null;

    var cases: [8]ErrorUnionTrySwitchCase = undefined;
    for (switch_term.cases.items, 0..) |case, case_index| {
        if (!case.value_ty.eql(.{ .int = 32 })) return null;
        const value = switch (case.value) {
            .int => |int| i32Value(int) catch return null,
            .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
        };
        const block = function.blocks.items[blockIndex(function, case.target) orelse return null];
        if (!blockBranchesTo(block, merge_block.name)) return null;
        cases[case_index] = .{
            .value = value,
            .block = block,
            .add_imm = payloadAddWrapPhiIncoming(function, switch_block, phi, block.name, call_name) orelse return null,
        };
    }
    const default_block = function.blocks.items[blockIndex(function, switch_term.default_target) orelse return null];
    if (!blockBranchesTo(default_block, merge_block.name)) return null;
    const default_case: ErrorUnionTrySwitchCase = .{
        .value = 0,
        .block = default_block,
        .add_imm = payloadAddWrapPhiIncoming(function, switch_block, phi, default_block.name, call_name) orelse return null,
    };
    if (!trySwitchUsesAllBlocks(function, switch_block.name, err_block.name, merge_block.name, switch_term)) return null;

    return .{
        .entry = entry,
        .call_name = call_name,
        .call = call,
        .err_block = err_block,
        .switch_block = switch_block,
        .merge_block = merge_block,
        .mask = mask,
        .cases = cases,
        .case_count = switch_term.cases.items.len,
        .default_case = default_case,
    };
}

pub fn payloadMaskConst(block: ir.BasicBlock, value: ir.Value, call_name: []const u8) ?i32 {
    const mask_name = switch (value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    const mask_inst = findInstruction(block, mask_name) orelse return null;
    const mask = switch (mask_inst.kind) {
        .binary => |binary| binary,
        else => return null,
    };
    if (!mask.ty.eql(.{ .int = 32 }) or mask.op != .@"and") return null;
    const rhs = switch (mask.rhs) {
        .int => |int| i32Value(int) catch return null,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    if (!payloadValueFromCallResult(block, mask.lhs, call_name)) return null;
    return rhs;
}

pub fn payloadAddWrapPhiIncoming(
    function: ir.Function,
    payload_scope: ir.BasicBlock,
    phi: ir.PhiInst,
    predecessor: []const u8,
    call_name: []const u8,
) ?u8 {
    for (phi.incoming.items) |incoming| {
        if (!std.mem.eql(u8, incoming.block, predecessor)) continue;
        const value_block = function.blocks.items[blockIndex(function, predecessor) orelse return null];
        return payloadAddWrapValue(value_block, payload_scope, incoming.value, call_name);
    }
    return null;
}

pub fn payloadAddWrapValue(value_block: ir.BasicBlock, payload_scope: ir.BasicBlock, value: ir.Value, call_name: []const u8) ?u8 {
    const shl_name = switch (value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    const shl_inst = findInstruction(value_block, shl_name) orelse return null;
    const shl = switch (shl_inst.kind) {
        .binary => |binary| binary,
        else => return null,
    };
    if (!shl.ty.eql(.{ .int = 64 }) or shl.op != .shl or !isInt(shl.rhs, 16)) return null;
    const zext_name = switch (shl.lhs) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    const zext_inst = findInstruction(value_block, zext_name) orelse return null;
    const zext = switch (zext_inst.kind) {
        .cast => |cast| cast,
        else => return null,
    };
    if (zext.op != .zext or !zext.from_ty.eql(.{ .int = 32 }) or !zext.to_ty.eql(.{ .int = 64 })) return null;
    const add_name = switch (zext.value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    const add_inst = findInstruction(value_block, add_name) orelse return null;
    const add = switch (add_inst.kind) {
        .binary => |binary| binary,
        else => return null,
    };
    if (!add.ty.eql(.{ .int = 32 }) or add.op != .add) return null;
    const rhs = switch (add.rhs) {
        .int => |int| i32Value(int) catch return null,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    if (rhs < 0 or rhs > std.math.maxInt(u8)) return null;
    if (!payloadValueFromCallResult(payload_scope, add.lhs, call_name)) return null;
    return @intCast(rhs);
}

pub fn trySwitchUsesAllBlocks(
    function: ir.Function,
    switch_block: []const u8,
    err_block: []const u8,
    merge_block: []const u8,
    switch_term: ir.SwitchTerminator,
) bool {
    for (function.blocks.items, 0..) |block, index| {
        if (index == 0 or
            std.mem.eql(u8, block.name, switch_block) or
            std.mem.eql(u8, block.name, err_block) or
            std.mem.eql(u8, block.name, merge_block) or
            std.mem.eql(u8, block.name, switch_term.default_target))
        {
            continue;
        }
        var matched_case = false;
        for (switch_term.cases.items) |case| {
            if (std.mem.eql(u8, block.name, case.target)) {
                matched_case = true;
                break;
            }
        }
        if (!matched_case) return false;
    }
    return true;
}

pub const ErrorUnionSwitchPhiCase = struct {
    value: i32,
    block: ir.BasicBlock,
    incoming: ir.Value,
};

pub const ErrorUnionSwitchCond = union(enum) {
    param: ArgReg,
    masked_param: struct {
        reg: ArgReg,
        mask: i32,
    },
};

pub const ErrorUnionSwitchPhiReturn = struct {
    entry: ir.BasicBlock,
    cond: ErrorUnionSwitchCond,
    cases: [8]ErrorUnionSwitchPhiCase,
    case_count: usize,
    default_block: ir.BasicBlock,
    default_incoming: ir.Value,
};

pub const ErrorUnionErrorTagSwitchReturn = struct {
    entry: ir.BasicBlock,
    call_name: []const u8,
    call: ir.CallInst,
    success_block: ir.BasicBlock,
    success_return: ErrorUnionI32ReturnValue,
    switch_block: ir.BasicBlock,
    cases: [8]ErrorUnionSwitchPhiCase,
    case_count: usize,
    default_block: ir.BasicBlock,
    merge_block: ir.BasicBlock,
    live_param_reg: ?ArgReg,
};

pub const ErrorUnionErrorTagBranchReturn = struct {
    entry: ir.BasicBlock,
    call_name: []const u8,
    call: ir.CallInst,
    payload_block: ir.BasicBlock,
    payload_return: ErrorUnionI32ReturnValue,
    branch_block: ir.BasicBlock,
    error_value: i32,
    true_block: ir.BasicBlock,
    true_value: i32,
    false_block: ir.BasicBlock,
    false_value: i32,
};

pub const ErrorUnionCatchValueMergeReturn = struct {
    entry: ir.BasicBlock,
    call_name: []const u8,
    call: ir.CallInst,
    payload_block: ir.BasicBlock,
    fallback_block: ir.BasicBlock,
    merge_block: ir.BasicBlock,
    fallback: ErrorUnionCatchFallbackValue,
    add_imm: i32,
};

pub const ErrorUnionCatchFallbackValue = union(enum) {
    int: i32,
    param: ArgReg,
};

pub const NamedPhi = struct {
    name: []const u8,
    phi: ir.PhiInst,
};

pub const ErrorUnionCatchSwitchReturn = struct {
    entry: ir.BasicBlock,
    call_name: []const u8,
    call: ir.CallInst,
    payload_block: ir.BasicBlock,
    payload_add_imm: u8,
    switch_block: ir.BasicBlock,
    cases: [8]ErrorUnionSwitchPhiCase,
    case_count: usize,
    default_block: ir.BasicBlock,
    merge_block: ir.BasicBlock,
};

pub const ErrorUnionCatchBranchReturn = struct {
    entry: ir.BasicBlock,
    call_name: []const u8,
    call: ir.CallInst,
    payload_block: ir.BasicBlock,
    payload_add_imm: u8,
    branch_block: ir.BasicBlock,
    error_value: i32,
    true_block: ir.BasicBlock,
    true_value: i64,
    false_block: ir.BasicBlock,
    false_value: i64,
};

pub const ErrorUnionCatchCallReturn = struct {
    entry: ir.BasicBlock,
    call_name: []const u8,
    call: ir.CallInst,
    success_block: ir.BasicBlock,
    success_return: ErrorUnionI32ReturnValue,
    catch_block: ir.BasicBlock,
    catch_call: ir.CallInst,
    live_param_reg: ArgReg,
};

pub const ErrorUnionCatchTerminalReturn = struct {
    entry: ir.BasicBlock,
    call_name: []const u8,
    call: ir.CallInst,
    success_block: ir.BasicBlock,
    catch_block: ir.BasicBlock,
    live_params: LiveParamSet,
};

pub const ErrorSetParamSwitchCase = struct {
    value: u16,
    block: ir.BasicBlock,
    incoming: ir.Value,
};

pub const ErrorSetParamSwitchReturn = struct {
    entry: ir.BasicBlock,
    tag_reg: ArgReg,
    cases: [8]ErrorSetParamSwitchCase,
    case_count: usize,
    default_block: ir.BasicBlock,
    merge_block: ir.BasicBlock,
};

pub const ErrorUnionI32ReturnValue = union(enum) {
    generic: ir.Value,
    payload_add_imm: i32,
    payload_binary: PayloadBinaryWrapReturn,
};

pub fn lowerGenericCfgErrorUnionSwitchPhiReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    const plan = errorUnionSwitchPhiReturn(function) orelse return false;
    try emitErrorUnionSwitchCondIntoEax(allocator, machine, plan.cond);
    for (plan.cases[0..plan.case_count]) |case| {
        try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = case.value });
        try appendGenericCfgConditionalBranch(allocator, machine, .je, case.block.name);
    }
    try machine.instructions.append(allocator, .{ .jmp = plan.default_block.name });

    for (plan.cases[0..plan.case_count]) |case| {
        try appendGenericCfgBlockLabel(allocator, machine, case.block.name);
        try emitGenericCfgTerminalI64ValueIntoRax(allocator, machine, function, plan.entry, case.block, case.incoming);
        try appendGenericCfgReturn(allocator, machine);
    }
    try appendGenericCfgBlockLabel(allocator, machine, plan.default_block.name);
    try emitGenericCfgTerminalI64ValueIntoRax(allocator, machine, function, plan.entry, plan.default_block, plan.default_incoming);
    try appendGenericCfgReturn(allocator, machine);
    return true;
}

pub fn lowerGenericCfgErrorUnionErrorTagSwitchReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    const plan = errorUnionErrorTagSwitchReturn(function) orelse return false;
    const frame_bytes: u8 = if (plan.live_param_reg != null) 24 else 8;
    const epilogue_label = try ownedMachineLabel(
        allocator,
        machine,
        "generic_cfg_error_tag_switch_{}_generic_cfg_select_end",
        .{machine.instructions.items.len},
    );

    try appendStackFrame(allocator, machine, frame_bytes);
    if (plan.live_param_reg) |reg| {
        try machine.instructions.append(allocator, .{ .spill_arg_rsp = .{ .frame_index = .slot2, .reg = reg } });
    }
    try emitTwoI32ArgCallIntoRax(allocator, machine, function, plan.entry, plan.call);
    try machine.instructions.append(allocator, .{ .spill_rax_rsp = .slot0 });
    try machine.instructions.append(allocator, .{ .and_eax_imm32 = 65535 });
    try machine.instructions.append(allocator, .test_eax_eax);
    try appendGenericCfgConditionalBranch(allocator, machine, .je, plan.success_block.name);

    try appendGenericCfgBlockLabel(allocator, machine, plan.switch_block.name);
    try machine.instructions.append(allocator, .{ .reload_rsp_rax = .slot0 });
    try machine.instructions.append(allocator, .{ .and_eax_imm32 = 65535 });
    for (plan.cases[0..plan.case_count]) |case| {
        try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = case.value });
        try appendGenericCfgConditionalBranch(allocator, machine, .je, case.block.name);
    }
    try machine.instructions.append(allocator, .{ .jmp = plan.default_block.name });

    for (plan.cases[0..plan.case_count]) |case| {
        try appendGenericCfgBlockLabel(allocator, machine, case.block.name);
        try emitErrorUnionI32ReturnValueIntoEax(allocator, machine, function, plan.entry, case.block, .{ .generic = case.incoming }, plan.live_param_reg);
        try machine.instructions.append(allocator, .{ .jmp = epilogue_label });
    }

    try appendGenericCfgBlockLabel(allocator, machine, plan.success_block.name);
    try emitErrorUnionI32ReturnValueIntoEax(allocator, machine, function, plan.entry, plan.success_block, plan.success_return, plan.live_param_reg);
    try machine.instructions.append(allocator, .{ .jmp = epilogue_label });

    try appendGenericCfgBlockLabel(allocator, machine, epilogue_label);
    try appendStackFrameEnd(allocator, machine, frame_bytes);
    try appendGenericCfgReturn(allocator, machine);

    try appendGenericCfgBlockLabel(allocator, machine, plan.default_block.name);
    try machine.instructions.append(allocator, .ud2);
    return true;
}

pub fn lowerGenericCfgErrorUnionErrorTagBranchReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    const plan = errorUnionErrorTagBranchReturn(function) orelse return false;
    const frame_bytes: u8 = 8;
    const epilogue_label = try ownedMachineLabel(
        allocator,
        machine,
        "generic_cfg_error_tag_branch_{}_generic_cfg_select_end",
        .{machine.instructions.items.len},
    );

    try appendStackFrame(allocator, machine, frame_bytes);
    try emitTwoI32ArgCallIntoRax(allocator, machine, function, plan.entry, plan.call);
    try machine.instructions.append(allocator, .{ .spill_rax_rsp = .slot0 });
    try machine.instructions.append(allocator, .{ .and_eax_imm32 = 65535 });
    try machine.instructions.append(allocator, .test_eax_eax);
    try appendGenericCfgConditionalBranch(allocator, machine, .je, plan.payload_block.name);

    try appendGenericCfgBlockLabel(allocator, machine, plan.branch_block.name);
    try machine.instructions.append(allocator, .{ .reload_rsp_rax = .slot0 });
    try machine.instructions.append(allocator, .{ .and_eax_imm32 = 65535 });
    try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = plan.error_value });
    try appendGenericCfgConditionalBranch(allocator, machine, .je, plan.true_block.name);
    try appendGenericCfgBlockLabel(allocator, machine, plan.false_block.name);
    try machine.instructions.append(allocator, .{ .mov_imm_eax = plan.false_value });
    try machine.instructions.append(allocator, .{ .jmp = epilogue_label });

    try appendGenericCfgBlockLabel(allocator, machine, plan.true_block.name);
    try machine.instructions.append(allocator, .{ .mov_imm_eax = plan.true_value });
    try machine.instructions.append(allocator, .{ .jmp = epilogue_label });

    try appendGenericCfgBlockLabel(allocator, machine, plan.payload_block.name);
    try emitErrorUnionI32ReturnValueIntoEax(allocator, machine, function, plan.entry, plan.payload_block, plan.payload_return, null);
    try machine.instructions.append(allocator, .{ .jmp = epilogue_label });

    try appendGenericCfgBlockLabel(allocator, machine, epilogue_label);
    try appendStackFrameEnd(allocator, machine, frame_bytes);
    try appendGenericCfgReturn(allocator, machine);
    return true;
}

pub fn lowerGenericCfgErrorUnionCatchValueMergeReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    const plan = errorUnionCatchValueMergeReturn(function) orelse return false;
    const live_fallback_reg: ?ArgReg = switch (plan.fallback) {
        .param => |reg| reg,
        .int => null,
    };
    const frame_bytes: u8 = if (live_fallback_reg != null) 24 else 8;
    const fallback_label = try ownedMachineLabel(
        allocator,
        machine,
        "generic_cfg_error_catch_value_{}_fallback",
        .{machine.instructions.items.len},
    );
    const epilogue_label = try ownedMachineLabel(
        allocator,
        machine,
        "generic_cfg_error_catch_value_{}_generic_cfg_select_end",
        .{machine.instructions.items.len},
    );

    try appendStackFrame(allocator, machine, frame_bytes);
    if (live_fallback_reg) |reg| {
        try machine.instructions.append(allocator, .{ .spill_arg_rsp = .{ .frame_index = .slot2, .reg = reg } });
    }
    try emitTwoI32ArgCallIntoRax(allocator, machine, function, plan.entry, plan.call);
    try machine.instructions.append(allocator, .{ .spill_rax_rsp = .slot0 });
    try machine.instructions.append(allocator, .{ .and_eax_imm32 = 65535 });
    try machine.instructions.append(allocator, .test_eax_eax);
    try appendGenericCfgConditionalBranch(allocator, machine, .jne, fallback_label);

    try appendGenericCfgBlockLabel(allocator, machine, plan.payload_block.name);
    try machine.instructions.append(allocator, .{ .reload_rsp_rax = .slot0 });
    try machine.instructions.append(allocator, .{ .shr_rax_imm6 = 16 });
    if (plan.add_imm != 0) try machine.instructions.append(allocator, .{ .add_eax_imm32 = plan.add_imm });
    try machine.instructions.append(allocator, .{ .jmp = epilogue_label });

    try appendGenericCfgBlockLabel(allocator, machine, fallback_label);
    switch (plan.fallback) {
        .int => |value| try machine.instructions.append(allocator, .{ .mov_imm_eax = value }),
        .param => |reg| {
            try machine.instructions.append(allocator, .{ .reload_arg_rsp = .{ .frame_index = .slot2, .reg = reg } });
            try machine.instructions.append(allocator, .{ .mov_arg_eax = reg });
        },
    }
    if (plan.add_imm != 0) try machine.instructions.append(allocator, .{ .add_eax_imm32 = plan.add_imm });
    try machine.instructions.append(allocator, .{ .jmp = epilogue_label });

    try appendGenericCfgBlockLabel(allocator, machine, epilogue_label);
    try appendStackFrameEnd(allocator, machine, frame_bytes);
    try appendGenericCfgReturn(allocator, machine);
    return true;
}

pub fn lowerGenericCfgErrorUnionCatchSwitchReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    const plan = errorUnionCatchSwitchReturn(function) orelse return false;
    const frame_bytes: u8 = 8;
    const epilogue_label = try ownedMachineLabel(
        allocator,
        machine,
        "generic_cfg_error_catch_switch_{}_generic_cfg_select_end",
        .{machine.instructions.items.len},
    );

    try appendStackFrame(allocator, machine, frame_bytes);
    try emitTwoI32ArgCallIntoRax(allocator, machine, function, plan.entry, plan.call);
    try machine.instructions.append(allocator, .{ .spill_rax_rsp = .slot0 });
    try machine.instructions.append(allocator, .{ .and_eax_imm32 = 65535 });
    try machine.instructions.append(allocator, .test_eax_eax);
    try appendGenericCfgConditionalBranch(allocator, machine, .je, plan.payload_block.name);

    try appendGenericCfgBlockLabel(allocator, machine, plan.switch_block.name);
    try machine.instructions.append(allocator, .{ .reload_rsp_rax = .slot0 });
    try machine.instructions.append(allocator, .{ .and_eax_imm32 = 65535 });
    for (plan.cases[0..plan.case_count]) |case| {
        try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = case.value });
        try appendGenericCfgConditionalBranch(allocator, machine, .je, case.block.name);
    }
    try machine.instructions.append(allocator, .{ .jmp = plan.default_block.name });

    for (plan.cases[0..plan.case_count]) |case| {
        try appendGenericCfgBlockLabel(allocator, machine, case.block.name);
        try emitGenericCfgTerminalI64ValueIntoRax(allocator, machine, function, plan.entry, case.block, case.incoming);
        try machine.instructions.append(allocator, .{ .jmp = epilogue_label });
    }

    try appendGenericCfgBlockLabel(allocator, machine, plan.payload_block.name);
    try machine.instructions.append(allocator, .{ .reload_rsp_rax = .slot0 });
    try machine.instructions.append(allocator, .{ .shr_rax_imm6 = 16 });
    if (plan.payload_add_imm != 0) try machine.instructions.append(allocator, .{ .add_rax_imm8 = plan.payload_add_imm });
    try machine.instructions.append(allocator, .{ .shl_rax_imm6 = 16 });
    try machine.instructions.append(allocator, .{ .jmp = epilogue_label });

    try appendGenericCfgBlockLabel(allocator, machine, epilogue_label);
    try appendStackFrameEnd(allocator, machine, frame_bytes);
    try appendGenericCfgReturn(allocator, machine);

    try appendGenericCfgBlockLabel(allocator, machine, plan.default_block.name);
    try machine.instructions.append(allocator, .ud2);
    return true;
}

pub fn lowerGenericCfgErrorUnionCatchBranchReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    const plan = errorUnionCatchBranchReturn(function) orelse return false;
    const frame_bytes: u8 = 8;
    const epilogue_label = try ownedMachineLabel(
        allocator,
        machine,
        "generic_cfg_error_catch_branch_{}_generic_cfg_select_end",
        .{machine.instructions.items.len},
    );

    try appendStackFrame(allocator, machine, frame_bytes);
    try emitTwoI32ArgCallIntoRax(allocator, machine, function, plan.entry, plan.call);
    try machine.instructions.append(allocator, .{ .spill_rax_rsp = .slot0 });
    try machine.instructions.append(allocator, .{ .and_eax_imm32 = 65535 });
    try machine.instructions.append(allocator, .test_eax_eax);
    try appendGenericCfgConditionalBranch(allocator, machine, .je, plan.payload_block.name);

    try appendGenericCfgBlockLabel(allocator, machine, plan.branch_block.name);
    try machine.instructions.append(allocator, .{ .reload_rsp_rax = .slot0 });
    try machine.instructions.append(allocator, .{ .and_eax_imm32 = 65535 });
    try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = plan.error_value });
    try appendGenericCfgConditionalBranch(allocator, machine, .je, plan.true_block.name);

    try appendGenericCfgBlockLabel(allocator, machine, plan.false_block.name);
    try machine.instructions.append(allocator, .{ .mov_imm_rax = plan.false_value });
    try machine.instructions.append(allocator, .{ .jmp = epilogue_label });

    try appendGenericCfgBlockLabel(allocator, machine, plan.true_block.name);
    try machine.instructions.append(allocator, .{ .mov_imm_rax = plan.true_value });
    try machine.instructions.append(allocator, .{ .jmp = epilogue_label });

    try appendGenericCfgBlockLabel(allocator, machine, plan.payload_block.name);
    try machine.instructions.append(allocator, .{ .reload_rsp_rax = .slot0 });
    try machine.instructions.append(allocator, .{ .shr_rax_imm6 = 16 });
    if (plan.payload_add_imm != 0) try machine.instructions.append(allocator, .{ .add_rax_imm8 = plan.payload_add_imm });
    try machine.instructions.append(allocator, .{ .shl_rax_imm6 = 16 });
    try machine.instructions.append(allocator, .{ .jmp = epilogue_label });

    try appendGenericCfgBlockLabel(allocator, machine, epilogue_label);
    try appendStackFrameEnd(allocator, machine, frame_bytes);
    try appendGenericCfgReturn(allocator, machine);
    return true;
}

pub fn lowerGenericCfgErrorUnionCatchCallReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    const plan = errorUnionCatchCallReturn(function) orelse return false;
    const frame_bytes: u8 = 24;
    const epilogue_label = try ownedMachineLabel(
        allocator,
        machine,
        "generic_cfg_error_catch_call_{}_generic_cfg_select_end",
        .{machine.instructions.items.len},
    );

    try appendStackFrame(allocator, machine, frame_bytes);
    try machine.instructions.append(allocator, .{ .spill_arg_rsp = .{ .frame_index = .slot2, .reg = plan.live_param_reg } });
    try emitTwoI32ArgCallIntoRax(allocator, machine, function, plan.entry, plan.call);
    try machine.instructions.append(allocator, .{ .spill_rax_rsp = .slot0 });
    try machine.instructions.append(allocator, .{ .and_eax_imm32 = 65535 });
    try machine.instructions.append(allocator, .test_eax_eax);
    try appendGenericCfgConditionalBranch(allocator, machine, .je, plan.success_block.name);

    try appendGenericCfgBlockLabel(allocator, machine, plan.catch_block.name);
    try machine.instructions.append(allocator, .{ .reload_rsp_rax = .slot0 });
    try machine.instructions.append(allocator, .{ .and_eax_imm32 = 65535 });
    try machine.instructions.append(allocator, .mov_rax_rdi);
    try machine.instructions.append(allocator, .{ .reload_arg_rsp = .{ .frame_index = .slot2, .reg = .rsi } });
    try machine.instructions.append(allocator, .{ .direct_call = .{ .symbol = plan.catch_call.callee, .ret_ty = plan.catch_call.ret_ty } });
    try machine.instructions.append(allocator, .{ .jmp = epilogue_label });

    try appendGenericCfgBlockLabel(allocator, machine, plan.success_block.name);
    try emitErrorUnionI32ReturnValueIntoEax(allocator, machine, function, plan.entry, plan.success_block, plan.success_return, plan.live_param_reg);
    try machine.instructions.append(allocator, .{ .jmp = epilogue_label });

    try appendGenericCfgBlockLabel(allocator, machine, epilogue_label);
    try appendStackFrameEnd(allocator, machine, frame_bytes);
    try appendGenericCfgReturn(allocator, machine);
    return true;
}

pub fn lowerGenericCfgErrorUnionCatchTerminalReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    const plan = errorUnionCatchTerminalReturn(function) orelse return false;

    try appendAlignedCallPreservingI32Params(allocator, machine, function, plan.call, plan.live_params, .{ .direct = plan.call.callee });
    try machine.instructions.append(allocator, .{ .and_eax_imm32 = 65535 });
    try machine.instructions.append(allocator, .test_eax_eax);
    try appendGenericCfgConditionalBranch(allocator, machine, .je, plan.success_block.name);

    try appendGenericCfgBlockLabel(allocator, machine, plan.catch_block.name);
    try emitGenericCfgTerminalReturnBlock(allocator, machine, function, plan.entry, plan.catch_block);

    try appendGenericCfgBlockLabel(allocator, machine, plan.success_block.name);
    try emitGenericCfgTerminalReturnBlock(allocator, machine, function, plan.entry, plan.success_block);
    return true;
}

pub fn lowerGenericCfgErrorSetParamSwitchReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    const plan = errorSetParamSwitchReturn(function) orelse return false;
    for (plan.cases[0..plan.case_count]) |case| {
        try machine.instructions.append(allocator, .{ .cmp_arg16_imm16 = .{ .reg = plan.tag_reg, .imm = case.value } });
        try appendGenericCfgConditionalBranch(allocator, machine, .je, case.block.name);
    }
    try machine.instructions.append(allocator, .{ .jmp = plan.default_block.name });

    for (plan.cases[0..plan.case_count]) |case| {
        try appendGenericCfgBlockLabel(allocator, machine, case.block.name);
        try emitGenericCfgTerminalI32ValueIntoEax(allocator, machine, function, plan.entry, case.block, case.incoming);
        try appendGenericCfgReturn(allocator, machine);
    }

    try appendGenericCfgBlockLabel(allocator, machine, plan.default_block.name);
    try machine.instructions.append(allocator, .ud2);
    return true;
}

pub fn errorUnionSwitchPhiReturn(function: ir.Function) ?ErrorUnionSwitchPhiReturn {
    if (!function.ret_ty.eql(.{ .int = 64 }) or function.blocks.items.len < 4) return null;
    const entry = function.blocks.items[0];
    const switch_term = blockSwitchTerminator(entry) orelse return null;
    if (!switch_term.cond_ty.eql(.{ .int = 32 })) return null;
    const cond = errorUnionSwitchCond(function, entry, switch_term.cond) orelse return null;
    if (switch_term.cases.items.len == 0 or switch_term.cases.items.len > 8) return null;
    const merge_block = commonSwitchMergeBlock(function, switch_term) orelse return null;
    const phi = firstPhiReturn(function, merge_block) orelse return null;
    if (!phi.ty.eql(.{ .int = 64 })) return null;

    var cases: [8]ErrorUnionSwitchPhiCase = undefined;
    for (switch_term.cases.items, 0..) |case, case_index| {
        if (!case.value_ty.eql(.{ .int = 32 })) return null;
        const value = switch (case.value) {
            .int => |int| i32Value(int) catch return null,
            .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
        };
        const block = function.blocks.items[blockIndex(function, case.target) orelse return null];
        if (!blockBranchesTo(block, merge_block.name)) return null;
        cases[case_index] = .{
            .value = value,
            .block = block,
            .incoming = phiIncomingForBlock(phi, block.name) orelse return null,
        };
    }
    const default_block = function.blocks.items[blockIndex(function, switch_term.default_target) orelse return null];
    if (!blockBranchesTo(default_block, merge_block.name)) return null;
    if (!switchPhiUsesAllBlocks(function, merge_block.name, switch_term)) return null;

    return .{
        .entry = entry,
        .cond = cond,
        .cases = cases,
        .case_count = switch_term.cases.items.len,
        .default_block = default_block,
        .default_incoming = phiIncomingForBlock(phi, default_block.name) orelse return null,
    };
}

pub fn errorUnionSwitchCond(function: ir.Function, entry: ir.BasicBlock, value: ir.Value) ?ErrorUnionSwitchCond {
    const name = switch (value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    if (entry.instructions.items.len == 0) {
        const reg = paramRegOrNull(function, name, .{ .int = 32 }) catch return null;
        return .{ .param = reg orelse return null };
    }
    if (entry.instructions.items.len != 1) return null;
    const instruction = findInstruction(entry, name) orelse return null;
    const binary = switch (instruction.kind) {
        .binary => |binary| binary,
        else => return null,
    };
    if (binary.op != .@"and" or !binary.ty.eql(.{ .int = 32 })) return null;
    const reg = switch (binary.lhs) {
        .named => |lhs| paramRegOrNull(function, lhs, .{ .int = 32 }) catch return null,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    } orelse return null;
    const mask = switch (binary.rhs) {
        .int => |int| i32Value(int) catch return null,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    return .{ .masked_param = .{ .reg = reg, .mask = mask } };
}

pub fn emitErrorUnionSwitchCondIntoEax(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    cond: ErrorUnionSwitchCond,
) !void {
    switch (cond) {
        .param => |reg| try machine.instructions.append(allocator, .{ .mov_arg_eax = reg }),
        .masked_param => |masked| {
            try machine.instructions.append(allocator, .{ .mov_arg_eax = masked.reg });
            try machine.instructions.append(allocator, .{ .and_eax_imm32 = masked.mask });
        },
    }
}

pub fn switchPhiUsesAllBlocks(
    function: ir.Function,
    merge_block: []const u8,
    switch_term: ir.SwitchTerminator,
) bool {
    for (function.blocks.items, 0..) |block, index| {
        if (index == 0 or
            std.mem.eql(u8, block.name, merge_block) or
            std.mem.eql(u8, block.name, switch_term.default_target))
        {
            continue;
        }
        var matched_case = false;
        for (switch_term.cases.items) |case| {
            if (std.mem.eql(u8, block.name, case.target)) {
                matched_case = true;
                break;
            }
        }
        if (!matched_case) return false;
    }
    return true;
}

pub fn errorUnionErrorTagSwitchReturn(function: ir.Function) ?ErrorUnionErrorTagSwitchReturn {
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.blocks.items.len < 6) return null;
    const entry = function.blocks.items[0];
    const entry_condbr = switch (entry.terminator orelse return null) {
        .condbr => |condbr| condbr,
        else => return null,
    };
    if (!entry_condbr.cond_ty.eql(.{ .int = 1 })) return null;
    const call_name = errorUnionTryGuardCallResult(entry, entry_condbr.cond) orelse return null;
    const call_instruction = findInstruction(entry, call_name) orelse return null;
    const call = switch (call_instruction.kind) {
        .call => |call| call,
        else => return null,
    };
    if (!supportsDirectI64Call(call)) return null;

    const then_block = function.blocks.items[blockIndex(function, entry_condbr.then_target) orelse return null];
    const else_block = function.blocks.items[blockIndex(function, entry_condbr.else_target) orelse return null];
    const then_is_switch = errorUnionErrorTagSwitchBlock(then_block, call_name);
    const else_is_switch = errorUnionErrorTagSwitchBlock(else_block, call_name);
    if (then_is_switch == else_is_switch) return null;
    const success_block = if (then_is_switch) else_block else then_block;
    const switch_block = if (then_is_switch) then_block else else_block;
    const success_return = errorUnionPayloadI32Return(function, success_block, call_name) orelse
        errorUnionGenericI32Return(success_block) orelse return null;

    const switch_term = blockSwitchTerminator(switch_block) orelse return null;
    if (switch_term.cases.items.len == 0 or switch_term.cases.items.len > 8) return null;
    const merge_block = exhaustiveSwitchMergeBlock(function, switch_term) orelse return null;
    const phi = firstPhiReturn(function, merge_block) orelse return null;
    if (!phi.ty.eql(.{ .int = 32 })) return null;

    var cases: [8]ErrorUnionSwitchPhiCase = undefined;
    var live_param_reg = errorUnionI32ReturnLiveParam(function, success_block, success_return);
    for (switch_term.cases.items, 0..) |case, case_index| {
        if (!case.value_ty.eql(.{ .int = 16 })) return null;
        const value = switch (case.value) {
            .int => |int| i32Value(int) catch return null,
            .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
        };
        const block = function.blocks.items[blockIndex(function, case.target) orelse return null];
        if (!blockBranchesTo(block, merge_block.name)) return null;
        const incoming = phiIncomingForBlock(phi, block.name) orelse return null;
        if (!mergeLiveParam(&live_param_reg, errorUnionI32ReturnLiveParam(function, block, .{ .generic = incoming }))) return null;
        cases[case_index] = .{
            .value = value,
            .block = block,
            .incoming = incoming,
        };
    }
    const default_block = function.blocks.items[blockIndex(function, switch_term.default_target) orelse return null];
    if (!blockIsUnreachable(default_block)) return null;
    if (!errorTagSwitchUsesAllBlocks(function, success_block.name, switch_block.name, merge_block.name, switch_term)) return null;

    return .{
        .entry = entry,
        .call_name = call_name,
        .call = call,
        .success_block = success_block,
        .success_return = success_return,
        .switch_block = switch_block,
        .cases = cases,
        .case_count = switch_term.cases.items.len,
        .default_block = default_block,
        .merge_block = merge_block,
        .live_param_reg = live_param_reg,
    };
}

pub fn errorUnionErrorTagSwitchBlock(block: ir.BasicBlock, call_name: []const u8) bool {
    const switch_term = blockSwitchTerminator(block) orelse return false;
    return switch_term.cond_ty.eql(.{ .int = 16 }) and errorTagValueFromCallResult(block, switch_term.cond, call_name);
}

pub fn errorUnionErrorTagBranchReturn(function: ir.Function) ?ErrorUnionErrorTagBranchReturn {
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.blocks.items.len < 5) return null;
    const entry = function.blocks.items[0];
    const entry_condbr = switch (entry.terminator orelse return null) {
        .condbr => |condbr| condbr,
        else => return null,
    };
    if (!entry_condbr.cond_ty.eql(.{ .int = 1 })) return null;
    const call_name = errorUnionTryGuardCallResult(entry, entry_condbr.cond) orelse return null;
    const call_instruction = findInstruction(entry, call_name) orelse return null;
    const call = switch (call_instruction.kind) {
        .call => |call| call,
        else => return null,
    };
    if (!supportsDirectI64Call(call) or call.args.items.len != 2) return null;

    const then_block = function.blocks.items[blockIndex(function, entry_condbr.then_target) orelse return null];
    const else_block = function.blocks.items[blockIndex(function, entry_condbr.else_target) orelse return null];
    const then_payload_return = errorUnionPayloadI32Return(function, then_block, call_name);
    const else_payload_return = errorUnionPayloadI32Return(function, else_block, call_name);
    if ((then_payload_return != null) == (else_payload_return != null)) return null;
    const payload_block = if (then_payload_return != null) then_block else else_block;
    const branch_block = if (then_payload_return != null) else_block else then_block;
    const payload_return = then_payload_return orelse else_payload_return.?;
    if (errorUnionI32ReturnLiveParam(function, payload_block, payload_return) != null) return null;

    const branch_condbr = switch (branch_block.terminator orelse return null) {
        .condbr => |condbr| condbr,
        else => return null,
    };
    if (!branch_condbr.cond_ty.eql(.{ .int = 1 })) return null;
    const error_value = errorTagIcmpValueFromCallResult(branch_block, branch_condbr.cond, call_name) orelse return null;
    const true_block = function.blocks.items[blockIndex(function, branch_condbr.then_target) orelse return null];
    const false_block = function.blocks.items[blockIndex(function, branch_condbr.else_target) orelse return null];
    const true_value = terminalConstI32Return(true_block) orelse return null;
    const false_value = terminalConstI32Return(false_block) orelse return null;
    if (!errorTagBranchUsesOnlyExpectedBlocks(function, entry.name, payload_block.name, branch_block.name, true_block.name, false_block.name)) return null;

    return .{
        .entry = entry,
        .call_name = call_name,
        .call = call,
        .payload_block = payload_block,
        .payload_return = payload_return,
        .branch_block = branch_block,
        .error_value = error_value,
        .true_block = true_block,
        .true_value = true_value,
        .false_block = false_block,
        .false_value = false_value,
    };
}

pub fn errorUnionCatchValueMergeReturn(function: ir.Function) ?ErrorUnionCatchValueMergeReturn {
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.blocks.items.len < 4) return null;
    const entry = function.blocks.items[0];
    const entry_condbr = switch (entry.terminator orelse return null) {
        .condbr => |condbr| condbr,
        else => return null,
    };
    if (!entry_condbr.cond_ty.eql(.{ .int = 1 })) return null;
    const call_name = errorUnionTryGuardCallResult(entry, entry_condbr.cond) orelse return null;
    const call_instruction = findInstruction(entry, call_name) orelse return null;
    const call = switch (call_instruction.kind) {
        .call => |call| call,
        else => return null,
    };
    if (!supportsDirectI64Call(call) or call.args.items.len != 2) return null;

    const then_block = function.blocks.items[blockIndex(function, entry_condbr.then_target) orelse return null];
    const else_block = function.blocks.items[blockIndex(function, entry_condbr.else_target) orelse return null];
    const then_target = singleBrTarget(then_block) orelse return null;
    const else_target = singleBrTarget(else_block) orelse return null;
    if (!std.mem.eql(u8, then_target, else_target)) return null;
    const merge_block = function.blocks.items[blockIndex(function, then_target) orelse return null];
    const named_phi = firstNamedPhi(merge_block) orelse return null;
    const phi = named_phi.phi;
    if (!phi.ty.eql(.{ .int = 32 })) return null;

    const then_incoming = phiIncomingForBlock(phi, then_block.name) orelse return null;
    const else_incoming = phiIncomingForBlock(phi, else_block.name) orelse return null;
    const then_is_payload = payloadValueFromCallResult(then_block, then_incoming, call_name);
    const else_is_payload = payloadValueFromCallResult(else_block, else_incoming, call_name);
    if (then_is_payload == else_is_payload) return null;
    const payload_block = if (then_is_payload) then_block else else_block;
    const fallback_block = if (then_is_payload) else_block else then_block;
    const fallback_value = if (then_is_payload) else_incoming else then_incoming;
    const fallback = catchFallbackValue(function, fallback_value) orelse return null;
    const add_imm = phiAddReturnImm(merge_block, named_phi.name) orelse return null;
    if (!catchValueMergeUsesOnlyExpectedBlocks(function, entry.name, payload_block.name, fallback_block.name, merge_block.name)) return null;

    return .{
        .entry = entry,
        .call_name = call_name,
        .call = call,
        .payload_block = payload_block,
        .fallback_block = fallback_block,
        .merge_block = merge_block,
        .fallback = fallback,
        .add_imm = add_imm,
    };
}

pub fn errorUnionCatchSwitchReturn(function: ir.Function) ?ErrorUnionCatchSwitchReturn {
    if (!function.ret_ty.eql(.{ .int = 64 }) or function.blocks.items.len < 6) return null;
    const entry = function.blocks.items[0];
    const entry_condbr = switch (entry.terminator orelse return null) {
        .condbr => |condbr| condbr,
        else => return null,
    };
    if (!entry_condbr.cond_ty.eql(.{ .int = 1 })) return null;
    const call_name = errorUnionTryGuardCallResult(entry, entry_condbr.cond) orelse return null;
    const call_instruction = findInstruction(entry, call_name) orelse return null;
    const call = switch (call_instruction.kind) {
        .call => |call| call,
        else => return null,
    };
    if (!supportsDirectI64Call(call) or call.args.items.len != 2) return null;

    const then_block = function.blocks.items[blockIndex(function, entry_condbr.then_target) orelse return null];
    const else_block = function.blocks.items[blockIndex(function, entry_condbr.else_target) orelse return null];
    const then_payload_add = payloadAddWrapReturnFromCallResult(then_block, call_name);
    const else_payload_add = payloadAddWrapReturnFromCallResult(else_block, call_name);
    if ((then_payload_add != null) == (else_payload_add != null)) return null;
    const payload_block = if (then_payload_add != null) then_block else else_block;
    const switch_block = if (then_payload_add != null) else_block else then_block;
    const payload_add_imm = then_payload_add orelse else_payload_add.?;

    const switch_term = blockSwitchTerminator(switch_block) orelse return null;
    if (!switch_term.cond_ty.eql(.{ .int = 16 })) return null;
    if (!errorTagValueFromCallResult(switch_block, switch_term.cond, call_name)) return null;
    if (switch_term.cases.items.len == 0 or switch_term.cases.items.len > 8) return null;
    const merge_block = exhaustiveSwitchMergeBlock(function, switch_term) orelse return null;
    const phi = firstPhiReturn(function, merge_block) orelse return null;
    if (!phi.ty.eql(.{ .int = 64 })) return null;

    var cases: [8]ErrorUnionSwitchPhiCase = undefined;
    for (switch_term.cases.items, 0..) |case, case_index| {
        if (!case.value_ty.eql(.{ .int = 16 })) return null;
        const value = switch (case.value) {
            .int => |int| i32Value(int) catch return null,
            .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
        };
        const block = function.blocks.items[blockIndex(function, case.target) orelse return null];
        if (!blockBranchesTo(block, merge_block.name)) return null;
        cases[case_index] = .{
            .value = value,
            .block = block,
            .incoming = phiIncomingForBlock(phi, block.name) orelse return null,
        };
    }
    const default_block = function.blocks.items[blockIndex(function, switch_term.default_target) orelse return null];
    if (!blockIsUnreachable(default_block)) return null;
    if (!errorTagSwitchUsesAllBlocks(function, payload_block.name, switch_block.name, merge_block.name, switch_term)) return null;

    return .{
        .entry = entry,
        .call_name = call_name,
        .call = call,
        .payload_block = payload_block,
        .payload_add_imm = payload_add_imm,
        .switch_block = switch_block,
        .cases = cases,
        .case_count = switch_term.cases.items.len,
        .default_block = default_block,
        .merge_block = merge_block,
    };
}

pub fn errorUnionCatchBranchReturn(function: ir.Function) ?ErrorUnionCatchBranchReturn {
    if (!function.ret_ty.eql(.{ .int = 64 }) or function.blocks.items.len < 5) return null;
    const entry = function.blocks.items[0];
    const entry_condbr = switch (entry.terminator orelse return null) {
        .condbr => |condbr| condbr,
        else => return null,
    };
    if (!entry_condbr.cond_ty.eql(.{ .int = 1 })) return null;
    const call_name = errorUnionTryGuardCallResult(entry, entry_condbr.cond) orelse return null;
    const call_instruction = findInstruction(entry, call_name) orelse return null;
    const call = switch (call_instruction.kind) {
        .call => |call| call,
        else => return null,
    };
    if (!supportsDirectI64Call(call) or call.args.items.len != 2) return null;

    const then_block = function.blocks.items[blockIndex(function, entry_condbr.then_target) orelse return null];
    const else_block = function.blocks.items[blockIndex(function, entry_condbr.else_target) orelse return null];
    const then_payload_add = payloadAddWrapReturnFromCallResult(then_block, call_name);
    const else_payload_add = payloadAddWrapReturnFromCallResult(else_block, call_name);
    if ((then_payload_add != null) == (else_payload_add != null)) return null;
    const payload_block = if (then_payload_add != null) then_block else else_block;
    const branch_block = if (then_payload_add != null) else_block else then_block;
    const payload_add_imm = then_payload_add orelse else_payload_add.?;

    const branch_condbr = switch (branch_block.terminator orelse return null) {
        .condbr => |condbr| condbr,
        else => return null,
    };
    if (!branch_condbr.cond_ty.eql(.{ .int = 1 })) return null;
    const error_value = errorTagIcmpValueFromCallResult(branch_block, branch_condbr.cond, call_name) orelse return null;
    const true_block = function.blocks.items[blockIndex(function, branch_condbr.then_target) orelse return null];
    const false_block = function.blocks.items[blockIndex(function, branch_condbr.else_target) orelse return null];
    const true_value = terminalConstI64Return(true_block) orelse return null;
    const false_value = terminalConstI64Return(false_block) orelse return null;
    if (!errorTagBranchUsesOnlyExpectedBlocks(function, entry.name, payload_block.name, branch_block.name, true_block.name, false_block.name)) return null;

    return .{
        .entry = entry,
        .call_name = call_name,
        .call = call,
        .payload_block = payload_block,
        .payload_add_imm = payload_add_imm,
        .branch_block = branch_block,
        .error_value = error_value,
        .true_block = true_block,
        .true_value = true_value,
        .false_block = false_block,
        .false_value = false_value,
    };
}

pub fn errorUnionCatchCallReturn(function: ir.Function) ?ErrorUnionCatchCallReturn {
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.blocks.items.len != 3) return null;
    const entry = function.blocks.items[0];
    const entry_condbr = switch (entry.terminator orelse return null) {
        .condbr => |condbr| condbr,
        else => return null,
    };
    if (!entry_condbr.cond_ty.eql(.{ .int = 1 })) return null;
    const call_name = errorUnionTryGuardCallResult(entry, entry_condbr.cond) orelse return null;
    const call_instruction = findInstruction(entry, call_name) orelse return null;
    const call = switch (call_instruction.kind) {
        .call => |call| call,
        else => return null,
    };
    if (!supportsDirectI64Call(call)) return null;

    const then_block = function.blocks.items[blockIndex(function, entry_condbr.then_target) orelse return null];
    const else_block = function.blocks.items[blockIndex(function, entry_condbr.else_target) orelse return null];
    const then_catch_call = catchErrorCallReturn(function, then_block, call_name);
    const else_catch_call = catchErrorCallReturn(function, else_block, call_name);
    if ((then_catch_call != null) == (else_catch_call != null)) return null;
    const success_block = if (then_catch_call != null) else_block else then_block;
    const catch_block = if (then_catch_call != null) then_block else else_block;
    const catch_call = then_catch_call orelse else_catch_call.?;
    const success_return = errorUnionPayloadI32Return(function, success_block, call_name) orelse
        errorUnionGenericI32Return(success_block) orelse return null;
    var live_param_reg: ?ArgReg = catch_call.live_param_reg;
    if (!mergeLiveParam(&live_param_reg, errorUnionI32ReturnLiveParam(function, success_block, success_return))) return null;
    if (!catchCallUsesOnlyExpectedBlocks(function, entry.name, success_block.name, catch_block.name)) return null;

    return .{
        .entry = entry,
        .call_name = call_name,
        .call = call,
        .success_block = success_block,
        .success_return = success_return,
        .catch_block = catch_block,
        .catch_call = catch_call.call,
        .live_param_reg = live_param_reg orelse return null,
    };
}

pub fn errorUnionCatchTerminalReturn(function: ir.Function) ?ErrorUnionCatchTerminalReturn {
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.blocks.items.len != 3) return null;
    const entry = function.blocks.items[0];
    const entry_condbr = switch (entry.terminator orelse return null) {
        .condbr => |condbr| condbr,
        else => return null,
    };
    if (!entry_condbr.cond_ty.eql(.{ .int = 1 })) return null;
    const call_name = errorUnionTryGuardCallResult(entry, entry_condbr.cond) orelse return null;
    const call_instruction = findInstruction(entry, call_name) orelse return null;
    const call = switch (call_instruction.kind) {
        .call => |call| call,
        else => return null,
    };
    if (!supportsDirectI64Call(call)) return null;

    const success_block = function.blocks.items[blockIndex(function, entry_condbr.then_target) orelse return null];
    const catch_block = function.blocks.items[blockIndex(function, entry_condbr.else_target) orelse return null];
    if (!genericCfgSupportsTerminalReturnBlock(function, entry, success_block)) return null;
    if (!genericCfgSupportsTerminalReturnBlock(function, entry, catch_block)) return null;

    var live_params: LiveParamSet = .{};
    noteTerminalReturnLiveParams(function, success_block, &live_params) catch return null;
    noteTerminalReturnLiveParams(function, catch_block, &live_params) catch return null;

    return .{
        .entry = entry,
        .call_name = call_name,
        .call = call,
        .success_block = success_block,
        .catch_block = catch_block,
        .live_params = live_params,
    };
}

pub fn noteTerminalReturnLiveParams(function: ir.Function, block: ir.BasicBlock, live_params: *LiveParamSet) !void {
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return error.UnsupportedCodegenControlFlow,
    };
    try noteLiveValueSet(function, block, ret.value orelse return error.InvalidRet, live_params);
}

pub const CatchErrorCallReturn = struct {
    call: ir.CallInst,
    live_param_reg: ArgReg,
};

pub fn catchErrorCallReturn(function: ir.Function, block: ir.BasicBlock, call_name: []const u8) ?CatchErrorCallReturn {
    const ret = switch (block.terminator orelse return null) {
        .ret => |ret| ret,
        else => return null,
    };
    if (!ret.ty.eql(.{ .int = 32 })) return null;
    const call_result = switch (ret.value orelse return null) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    const call_instruction = findInstruction(block, call_result) orelse return null;
    const call = switch (call_instruction.kind) {
        .call => |call| call,
        else => return null,
    };
    if (!supportsDirectI16I32ToI32Call(call) or call.args.items.len != 2) return null;

    var error_arg_count: usize = 0;
    var live_param_reg: ?ArgReg = null;
    for (call.args.items) |arg| {
        if (arg.ty.eql(.{ .int = 16 }) and errorTagValueFromCallResult(block, arg.value, call_name)) {
            error_arg_count += 1;
            continue;
        }
        if (!arg.ty.eql(.{ .int = 32 })) return null;
        const reg = switch (arg.value) {
            .named => |name| paramReg(function, name, .{ .int = 32 }) catch return null,
            .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
        };
        if (live_param_reg != null and live_param_reg.? != reg) return null;
        live_param_reg = reg;
    }
    if (error_arg_count != 1) return null;
    return .{ .call = call, .live_param_reg = live_param_reg orelse return null };
}

pub fn catchCallUsesOnlyExpectedBlocks(function: ir.Function, entry: []const u8, payload: []const u8, catch_block: []const u8) bool {
    for (function.blocks.items) |block| {
        if (std.mem.eql(u8, block.name, entry) or
            std.mem.eql(u8, block.name, payload) or
            std.mem.eql(u8, block.name, catch_block))
        {
            continue;
        }
        return false;
    }
    return true;
}

pub fn errorSetParamSwitchReturn(function: ir.Function) ?ErrorSetParamSwitchReturn {
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.blocks.items.len < 3) return null;
    const entry = function.blocks.items[0];
    const switch_term = blockSwitchTerminator(entry) orelse return null;
    if (!switch_term.cond_ty.eql(.{ .int = 16 }) or switch_term.cases.items.len == 0 or switch_term.cases.items.len > 8) return null;
    const cond_name = switch (switch_term.cond) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    const tag_reg = paramReg(function, cond_name, .{ .int = 16 }) catch return null;

    const merge_block = exhaustiveSwitchMergeBlock(function, switch_term) orelse return null;
    const phi = firstPhiReturn(function, merge_block) orelse return null;
    if (!phi.ty.eql(.{ .int = 32 })) return null;

    var cases: [8]ErrorSetParamSwitchCase = undefined;
    for (switch_term.cases.items, 0..) |case, case_index| {
        if (!case.value_ty.eql(.{ .int = 16 })) return null;
        const value_i32 = switch (case.value) {
            .int => |int| i32Value(int) catch return null,
            .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
        };
        if (value_i32 < 0 or value_i32 > std.math.maxInt(u16)) return null;
        const block = function.blocks.items[blockIndex(function, case.target) orelse return null];
        if (!blockBranchesTo(block, merge_block.name)) return null;
        cases[case_index] = .{
            .value = @intCast(value_i32),
            .block = block,
            .incoming = phiIncomingForBlock(phi, block.name) orelse return null,
        };
    }
    const default_block = function.blocks.items[blockIndex(function, switch_term.default_target) orelse return null];
    if (!blockIsUnreachable(default_block)) return null;
    if (!errorSetSwitchUsesAllBlocks(function, entry.name, default_block.name, merge_block.name, switch_term)) return null;
    return .{
        .entry = entry,
        .tag_reg = tag_reg,
        .cases = cases,
        .case_count = switch_term.cases.items.len,
        .default_block = default_block,
        .merge_block = merge_block,
    };
}

pub fn errorSetSwitchUsesAllBlocks(function: ir.Function, entry: []const u8, default_block: []const u8, merge_block: []const u8, switch_term: ir.SwitchTerminator) bool {
    for (function.blocks.items) |block| {
        if (std.mem.eql(u8, block.name, entry) or
            std.mem.eql(u8, block.name, default_block) or
            std.mem.eql(u8, block.name, merge_block))
        {
            continue;
        }
        var expected_case = false;
        for (switch_term.cases.items) |case| {
            if (std.mem.eql(u8, block.name, case.target)) {
                expected_case = true;
                break;
            }
        }
        if (!expected_case) return false;
    }
    return true;
}

pub fn errorUnionPayloadI32Return(function: ir.Function, block: ir.BasicBlock, call_name: []const u8) ?ErrorUnionI32ReturnValue {
    const ret = switch (block.terminator orelse return null) {
        .ret => |ret| ret,
        else => return null,
    };
    if (!ret.ty.eql(.{ .int = 32 })) return null;
    const ret_value = ret.value orelse return null;
    if (payloadValueFromCallResult(block, ret_value, call_name)) return .{ .payload_add_imm = 0 };
    const add_name = switch (ret_value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    if (payloadAddFromCallResult(block, add_name, call_name)) |imm| return .{ .payload_add_imm = imm };
    if (payloadBinaryI32Return(function, block, block, call_name)) |binary| return .{ .payload_binary = binary };
    return null;
}

pub fn errorUnionGenericI32Return(block: ir.BasicBlock) ?ErrorUnionI32ReturnValue {
    const ret = switch (block.terminator orelse return null) {
        .ret => |ret| ret,
        else => return null,
    };
    if (!ret.ty.eql(.{ .int = 32 })) return null;
    return .{ .generic = ret.value orelse return null };
}

pub fn payloadAddWrapReturnFromCallResult(block: ir.BasicBlock, call_name: []const u8) ?u8 {
    const ret = switch (block.terminator orelse return null) {
        .ret => |ret| ret,
        else => return null,
    };
    if (!ret.ty.eql(.{ .int = 64 })) return null;
    return payloadAddWrapValue(block, block, ret.value orelse return null, call_name);
}

pub fn terminalConstI64Return(block: ir.BasicBlock) ?i64 {
    const ret = switch (block.terminator orelse return null) {
        .ret => |ret| ret,
        else => return null,
    };
    if (!ret.ty.eql(.{ .int = 64 })) return null;
    const value = switch (ret.value orelse return null) {
        .int => |int| int,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    return i64Value(value) catch null;
}

pub fn payloadBinaryI32Return(
    function: ir.Function,
    payload_scope: ir.BasicBlock,
    block: ir.BasicBlock,
    call_name: []const u8,
) ?PayloadBinaryWrapReturn {
    const ret = switch (block.terminator orelse return null) {
        .ret => |ret| ret,
        else => return null,
    };
    if (!ret.ty.eql(.{ .int = 32 })) return null;
    const binary_name = switch (ret.value orelse return null) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    const binary_inst = findInstruction(block, binary_name) orelse return null;
    const binary = switch (binary_inst.kind) {
        .binary => |binary| binary,
        else => return null,
    };
    if (!binary.ty.eql(.{ .int = 32 }) or (binary.op != .add and binary.op != .sub)) return null;
    const payload_on_lhs = payloadValueFromCallResult(payload_scope, binary.lhs, call_name);
    const payload_on_rhs = payloadValueFromCallResult(payload_scope, binary.rhs, call_name);
    if (payload_on_lhs == payload_on_rhs) return null;
    if (binary.op == .sub and !payload_on_lhs) return null;
    const other_value = if (payload_on_lhs) binary.rhs else binary.lhs;
    const reg = switch (other_value) {
        .named => |name| paramReg(function, name, .{ .int = 32 }) catch return null,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    const op: MachineBinaryOp = switch (binary.op) {
        .add => .add,
        .sub => .sub,
        else => unreachable,
    };
    return .{ .op = op, .reg = reg };
}

pub fn errorUnionI32ReturnLiveParam(function: ir.Function, block: ir.BasicBlock, value: ErrorUnionI32ReturnValue) ?ArgReg {
    return switch (value) {
        .payload_binary => |binary| binary.reg,
        .payload_add_imm => null,
        .generic => |generic| i32ValueLiveParam(function, block, generic),
    };
}

pub fn i32ValueLiveParam(function: ir.Function, block: ir.BasicBlock, value: ir.Value) ?ArgReg {
    switch (value) {
        .int => return null,
        .named => |name| {
            if (paramRegOrNull(function, name, .{ .int = 32 }) catch null) |reg| return reg;
            const instruction = findInstruction(block, name) orelse return null;
            switch (instruction.kind) {
                .binary => |binary| {
                    if (!binary.ty.eql(.{ .int = 32 })) return null;
                    const lhs = i32ValueLiveParam(function, block, binary.lhs);
                    const rhs = i32ValueLiveParam(function, block, binary.rhs);
                    if (lhs != null and rhs != null) return null;
                    return lhs orelse rhs;
                },
                else => return null,
            }
        },
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    }
}

pub fn mergeLiveParam(existing: *?ArgReg, candidate: ?ArgReg) bool {
    const candidate_reg = candidate orelse return true;
    if (existing.*) |existing_reg| return existing_reg == candidate_reg;
    existing.* = candidate_reg;
    return true;
}

pub fn emitErrorUnionI32ReturnValueIntoEax(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    entry: ir.BasicBlock,
    block: ir.BasicBlock,
    value: ErrorUnionI32ReturnValue,
    live_param_reg: ?ArgReg,
) !void {
    switch (value) {
        .payload_add_imm => |imm| {
            try machine.instructions.append(allocator, .{ .reload_rsp_rax = .slot0 });
            try machine.instructions.append(allocator, .{ .shr_rax_imm6 = 16 });
            if (imm != 0) try machine.instructions.append(allocator, .{ .add_eax_imm32 = imm });
        },
        .payload_binary => |binary| {
            const live_reg = live_param_reg orelse return error.UnsupportedLiveAcrossCall;
            if (live_reg != binary.reg) return error.UnsupportedLiveAcrossCall;
            try machine.instructions.append(allocator, .{ .reload_rsp_rax = .slot0 });
            try machine.instructions.append(allocator, .{ .shr_rax_imm6 = 16 });
            try machine.instructions.append(allocator, .{ .reload_arg_rsp = .{ .frame_index = .slot2, .reg = binary.reg } });
            try machine.instructions.append(allocator, .{ .binary_arg_eax = .{ .op = binary.op, .reg = binary.reg } });
        },
        .generic => |generic| {
            if (live_param_reg) |reg| {
                try emitI32ValueWithLiveParamIntoEax(allocator, machine, function, entry, block, generic, reg);
            } else {
                try emitGenericCfgTerminalI32ValueIntoEax(allocator, machine, function, entry, block, generic);
            }
        },
    }
}

pub fn emitI32ValueWithLiveParamIntoEax(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    entry: ir.BasicBlock,
    block: ir.BasicBlock,
    value: ir.Value,
    live_param_reg: ArgReg,
) !void {
    switch (value) {
        .int => |int| try machine.instructions.append(allocator, .{ .mov_imm_eax = try i32Value(int) }),
        .named => |name| {
            if ((paramRegOrNull(function, name, .{ .int = 32 }) catch null)) |reg| {
                if (reg == live_param_reg) {
                    try machine.instructions.append(allocator, .{ .reload_arg_rsp = .{ .frame_index = .slot2, .reg = reg } });
                }
                try machine.instructions.append(allocator, .{ .mov_arg_eax = reg });
                return;
            }
            const instruction = findInstruction(block, name) orelse return error.UnsupportedCodegenValue;
            switch (instruction.kind) {
                .binary => |binary| {
                    if (!binary.ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenType;
                    try emitI32ValueWithLiveParamIntoEax(allocator, machine, function, entry, block, binary.lhs, live_param_reg);
                    switch (binary.rhs) {
                        .int => |int| switch (binary.op) {
                            .add => try machine.instructions.append(allocator, .{ .add_eax_imm32 = try i32Value(int) }),
                            .sub => try machine.instructions.append(allocator, .{ .add_eax_imm32 = -try i32Value(int) }),
                            else => return error.UnsupportedCodegenInstruction,
                        },
                        .named => |rhs_name| {
                            const rhs_reg = try paramReg(function, rhs_name, .{ .int = 32 });
                            if (rhs_reg == live_param_reg) {
                                try machine.instructions.append(allocator, .{ .reload_arg_rsp = .{ .frame_index = .slot2, .reg = rhs_reg } });
                            }
                            const op = machineBinaryOp(binary.op) orelse return error.UnsupportedCodegenInstruction;
                            try machine.instructions.append(allocator, .{ .binary_arg_eax = .{ .op = op, .reg = rhs_reg } });
                        },
                        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
                    }
                },
                else => try emitGenericCfgTerminalI32ValueIntoEax(allocator, machine, function, entry, block, value),
            }
        },
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    }
}

pub fn errorTagValueFromCallResult(block: ir.BasicBlock, value: ir.Value, call_name: []const u8) bool {
    const trunc_name = switch (value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    const trunc_inst = findInstruction(block, trunc_name) orelse return false;
    const trunc = switch (trunc_inst.kind) {
        .cast => |cast| cast,
        else => return false,
    };
    if (trunc.op != .trunc or !trunc.from_ty.eql(.{ .int = 64 }) or !trunc.to_ty.eql(.{ .int = 16 })) return false;
    const mask_name = switch (trunc.value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    const mask_inst = findInstruction(block, mask_name) orelse return false;
    const mask = switch (mask_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    return mask.ty.eql(.{ .int = 64 }) and mask.op == .@"and" and isInt(mask.rhs, 65535) and isNamed(mask.lhs, call_name);
}

pub fn errorTagIcmpValueFromCallResult(block: ir.BasicBlock, value: ir.Value, call_name: []const u8) ?i32 {
    const icmp_name = switch (value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    const icmp_inst = findInstruction(block, icmp_name) orelse return null;
    const icmp = switch (icmp_inst.kind) {
        .icmp => |icmp| icmp,
        else => return null,
    };
    if (icmp.predicate != .eq or !icmp.operand_ty.eql(.{ .int = 16 })) return null;
    if (errorTagValueFromCallResult(block, icmp.lhs, call_name)) {
        return switch (icmp.rhs) {
            .int => |int| i32Value(int) catch null,
            .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => null,
        };
    }
    if (errorTagValueFromCallResult(block, icmp.rhs, call_name)) {
        return switch (icmp.lhs) {
            .int => |int| i32Value(int) catch null,
            .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => null,
        };
    }
    return null;
}

pub fn errorTagBranchUsesOnlyExpectedBlocks(
    function: ir.Function,
    entry_name: []const u8,
    payload_name: []const u8,
    branch_name: []const u8,
    true_name: []const u8,
    false_name: []const u8,
) bool {
    for (function.blocks.items) |block| {
        if (std.mem.eql(u8, block.name, entry_name) or
            std.mem.eql(u8, block.name, payload_name) or
            std.mem.eql(u8, block.name, branch_name) or
            std.mem.eql(u8, block.name, true_name) or
            std.mem.eql(u8, block.name, false_name))
        {
            continue;
        }
        if (!blockIsUnreachable(block)) return false;
    }
    return true;
}

pub fn exhaustiveSwitchMergeBlock(function: ir.Function, switch_term: ir.SwitchTerminator) ?ir.BasicBlock {
    var target: ?[]const u8 = null;
    for (switch_term.cases.items) |case| {
        const block = function.blocks.items[blockIndex(function, case.target) orelse return null];
        const branch_target = singleBrTarget(block) orelse return null;
        if (target) |existing| {
            if (!std.mem.eql(u8, existing, branch_target)) return null;
        } else {
            target = branch_target;
        }
    }
    return function.blocks.items[blockIndex(function, target orelse return null) orelse return null];
}

pub fn errorTagSwitchUsesAllBlocks(
    function: ir.Function,
    payload_block: []const u8,
    switch_block: []const u8,
    merge_block: []const u8,
    switch_term: ir.SwitchTerminator,
) bool {
    for (function.blocks.items, 0..) |block, index| {
        if (index == 0 or
            std.mem.eql(u8, block.name, payload_block) or
            std.mem.eql(u8, block.name, switch_block) or
            std.mem.eql(u8, block.name, merge_block) or
            std.mem.eql(u8, block.name, switch_term.default_target))
        {
            continue;
        }
        var matched_case = false;
        for (switch_term.cases.items) |case| {
            if (std.mem.eql(u8, block.name, case.target)) {
                matched_case = true;
                break;
            }
        }
        if (matched_case) continue;
        if (blockIsUnreachable(block)) continue;
        return false;
    }
    return true;
}

pub fn firstNamedPhi(block: ir.BasicBlock) ?NamedPhi {
    if (block.instructions.items.len == 0) return null;
    const instruction = block.instructions.items[0];
    const name = instruction.result orelse return null;
    return .{
        .name = name,
        .phi = switch (instruction.kind) {
            .phi => |phi| phi,
            else => return null,
        },
    };
}

pub fn catchFallbackValue(function: ir.Function, value: ir.Value) ?ErrorUnionCatchFallbackValue {
    return switch (value) {
        .int => |int| .{ .int = i32Value(int) catch return null },
        .named => |name| {
            const reg = paramRegOrNull(function, name, .{ .int = 32 }) catch return null;
            return .{ .param = reg orelse return null };
        },
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => null,
    };
}

pub fn phiAddReturnImm(block: ir.BasicBlock, phi_name: []const u8) ?i32 {
    if (block.instructions.items.len != 2) return null;
    const add_name = block.instructions.items[1].result orelse return null;
    const add = switch (block.instructions.items[1].kind) {
        .binary => |binary| binary,
        else => return null,
    };
    if (!add.ty.eql(.{ .int = 32 }) or add.op != .add or !isNamed(add.lhs, phi_name)) return null;
    const imm = switch (add.rhs) {
        .int => |int| i32Value(int) catch return null,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    const ret = switch (block.terminator orelse return null) {
        .ret => |ret| ret,
        else => return null,
    };
    if (!ret.ty.eql(.{ .int = 32 }) or !isNamed(ret.value orelse return null, add_name)) return null;
    return imm;
}

pub fn catchValueMergeUsesOnlyExpectedBlocks(
    function: ir.Function,
    entry_name: []const u8,
    payload_name: []const u8,
    fallback_name: []const u8,
    merge_name: []const u8,
) bool {
    for (function.blocks.items) |block| {
        if (std.mem.eql(u8, block.name, entry_name) or
            std.mem.eql(u8, block.name, payload_name) or
            std.mem.eql(u8, block.name, fallback_name) or
            std.mem.eql(u8, block.name, merge_name))
        {
            continue;
        }
        if (!blockIsUnreachable(block)) return false;
    }
    return true;
}
