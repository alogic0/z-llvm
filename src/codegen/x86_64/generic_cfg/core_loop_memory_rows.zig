const shared = @import("core_shared.zig");
const cabi_abi_helpers = @import("cabi_abi_helpers.zig");
const call_lowering = @import("cabi_call_lowering.zig");
const std = shared.std;
const ir = shared.ir;
const MachineFunction = shared.MachineFunction;

const isNamed = shared.isNamed;
const isInt = shared.isInt;
const isCalleeName = shared.isCalleeName;
const paramReg = cabi_abi_helpers.paramReg;
const appendDirectCall = shared.appendDirectCall;
const appendStackFrame = shared.appendStackFrame;
const appendStackFrameEnd = shared.appendStackFrameEnd;
const phiHasIncoming = call_lowering.phiHasIncoming;
const phiHasIncomingInt = call_lowering.phiHasIncomingInt;
const loop_matchers = @import("core_loop_matchers.zig");
const blockByName = loop_matchers.blockByName;
const matchI64BinaryNamedImm = loop_matchers.matchI64BinaryNamedImm;
const matchSpinlockGep = loop_matchers.matchSpinlockGep;
const isSpinlockedMemcpyCall = loop_matchers.isSpinlockedMemcpyCall;
const isByteSourceType = loop_matchers.isByteSourceType;

pub fn lowerByteScanLenLoop(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!matchesByteScanLenLoop(function)) return false;
    const ptr_reg = try paramReg(function, function.params.items[0].name, .ptr);
    if (ptr_reg != .rdi) return error.UnsupportedCodegenAbi;

    const loop_label = "byte_scan_len_loop";
    const done_label = "byte_scan_len_done";
    try machine.instructions.append(allocator, .{ .mov_arg64_arg = .{ .dst = .r8, .src = ptr_reg } });
    try machine.instructions.append(allocator, .{ .mov_arg64_arg = .{ .dst = .rcx, .src = ptr_reg } });
    try machine.instructions.append(allocator, .{ .label = loop_label });
    try machine.instructions.append(allocator, .load_rcx_ptr_u8_eax);
    try machine.instructions.append(allocator, .test_eax_eax);
    try machine.instructions.append(allocator, .{ .je = done_label });
    try machine.instructions.append(allocator, .inc_rcx);
    try machine.instructions.append(allocator, .{ .jmp = loop_label });
    try machine.instructions.append(allocator, .{ .label = done_label });
    try machine.instructions.append(allocator, .sub_r8_rcx);
    try machine.instructions.append(allocator, .{ .mov_arg_rax = .rcx });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerByteCompareEqualLoop(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!matchesByteCompareEqualLoop(function)) return false;
    const lhs_reg = try paramReg(function, function.params.items[0].name, .ptr);
    const rhs_reg = try paramReg(function, function.params.items[1].name, .ptr);
    const len_reg = try paramReg(function, function.params.items[2].name, .{ .int = 64 });
    if (lhs_reg != .rdi or rhs_reg != .rsi or len_reg != .rdx) return error.UnsupportedCodegenAbi;

    try machine.instructions.append(allocator, .bcmp_rdi_rsi_rdx_eax);
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerByteCompareDiffLoop(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!matchesByteCompareDiffLoop(function)) return false;
    const lhs_reg = try paramReg(function, function.params.items[0].name, .ptr);
    const rhs_reg = try paramReg(function, function.params.items[1].name, .ptr);
    const len_reg = try paramReg(function, function.params.items[2].name, .{ .int = 64 });
    if (lhs_reg != .rdi or rhs_reg != .rsi or len_reg != .rdx) return error.UnsupportedCodegenAbi;

    try machine.instructions.append(allocator, .memcmp_rdi_rsi_rdx_eax);
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerGuardedByteMemsetLoop(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!matchesGuardedByteMemsetLoop(function)) return false;
    const ptr_reg = try paramReg(function, function.params.items[0].name, .ptr);
    const byte_reg = try paramReg(function, function.params.items[1].name, .{ .int = 8 });
    const len_reg = try paramReg(function, function.params.items[2].name, .{ .int = 64 });
    const guard_reg = try paramReg(function, function.params.items[3].name, .{ .int = 64 });
    if (ptr_reg != .rdi or byte_reg != .rsi or len_reg != .rdx or guard_reg != .rcx) return error.UnsupportedCodegenAbi;

    try machine.instructions.append(allocator, .guarded_memset_rdi_sil_rdx_rcx_rax);
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerGuardedMemmoveCall(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    const callee = matchesGuardedMemmoveCall(function) orelse return false;
    const dst_reg = try paramReg(function, function.params.items[0].name, .ptr);
    const src_reg = try paramReg(function, function.params.items[1].name, .ptr);
    const len_reg = try paramReg(function, function.params.items[2].name, .{ .int = 64 });
    const guard_reg = try paramReg(function, function.params.items[3].name, .{ .int = 64 });
    if (dst_reg != .rdi or src_reg != .rsi or len_reg != .rdx or guard_reg != .rcx) return error.UnsupportedCodegenAbi;

    const ok_label = "guarded_memmove_ok";
    try machine.instructions.append(allocator, .cmp_rdx_rcx);
    try machine.instructions.append(allocator, .{ .jae = ok_label });
    try machine.instructions.append(allocator, .ud2);
    try machine.instructions.append(allocator, .{ .label = ok_label });
    try appendStackFrame(allocator, machine, 8);
    try machine.instructions.append(allocator, .{ .spill_arg64_rsp = .{ .frame_index = .slot0, .reg = .rdi } });
    try appendDirectCall(allocator, machine, callee, .ptr);
    try machine.instructions.append(allocator, .{ .reload_rsp_rax = .slot0 });
    try appendStackFrameEnd(allocator, machine, 8);
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerGuardedMemcpyBody(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!matchesGuardedMemcpyBody(function)) return false;
    const dst_reg = try paramReg(function, function.params.items[0].name, .ptr);
    const src_reg = try paramReg(function, function.params.items[1].name, .ptr);
    const len_reg = try paramReg(function, function.params.items[2].name, .{ .int = 64 });
    const guard_reg = try paramReg(function, function.params.items[3].name, .{ .int = 64 });
    if (dst_reg != .rdi or src_reg != .rsi or len_reg != .rdx or guard_reg != .rcx) return error.UnsupportedCodegenAbi;

    try machine.instructions.append(allocator, .guarded_memcpy_rdi_rsi_rdx_rcx_rax);
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerMemmoveBody(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!matchesMemmoveBody(function)) return false;
    const dst_reg = try paramReg(function, function.params.items[0].name, .ptr);
    const src_reg = try paramReg(function, function.params.items[1].name, .ptr);
    const len_reg = try paramReg(function, function.params.items[2].name, .{ .int = 64 });
    if (dst_reg != .rdi or src_reg != .rsi or len_reg != .rdx) return error.UnsupportedCodegenAbi;

    try machine.instructions.append(allocator, .memmove_rdi_rsi_rdx_rax);
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerMemcpyBody(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!matchesMemcpyBody(function)) return false;
    const dst_reg = try paramReg(function, function.params.items[0].name, .ptr);
    const src_reg = try paramReg(function, function.params.items[1].name, .ptr);
    const len_reg = try paramReg(function, function.params.items[2].name, .{ .int = 64 });
    if (dst_reg != .rdi or src_reg != .rsi or len_reg != .rdx) return error.UnsupportedCodegenAbi;

    try machine.instructions.append(allocator, .memcpy_rdi_rsi_rdx_rax);
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerSpinlockedMemcpyBody(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    const spinlock_symbol = (try matchSpinlockedMemcpyBody(function)) orelse return false;
    const len_reg = try paramReg(function, function.params.items[0].name, .{ .int = 32 });
    const src_reg = try paramReg(function, function.params.items[1].name, .ptr);
    const dst_reg = try paramReg(function, function.params.items[2].name, .ptr);
    if (len_reg != .rdi or src_reg != .rsi or dst_reg != .rdx) return error.UnsupportedCodegenAbi;

    try machine.instructions.append(allocator, .{ .spinlocked_memcpy_rsi_to_rdx_len_edi = spinlock_symbol });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerValgrindDiscardTranslationsClientRequest(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (function.ret_ty != .void or function.params.items.len != 2) return false;
    if (!function.params.items[0].ty.eql(.{ .int = 64 }) or !function.params.items[1].ty.eql(.{ .int = 64 })) return false;
    const start_name = function.params.items[0].name;
    const end_name = function.params.items[1].name;

    if (function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    if (block.instructions.items.len != 16) return false;

    const request_name = block.instructions.items[0].result orelse return false;
    const request_alloca = switch (block.instructions.items[0].kind) {
        .alloca => |alloca| alloca,
        else => return false,
    };
    if (!request_alloca.allocated_ty.eql(.{ .aggregate = "[6 x i64]" }) or
        request_alloca.allocated_ty_addrspace != null)
    {
        return false;
    }

    const len_name = block.instructions.items[1].result orelse return false;
    const len_sub = switch (block.instructions.items[1].kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (len_sub.op != .sub or !len_sub.flags.nuw or len_sub.flags.nsw or
        len_sub.flags.exact or len_sub.flags.disjoint or !len_sub.ty.eql(.{ .int = 64 }) or
        !isNamed(len_sub.lhs, end_name) or !isNamed(len_sub.rhs, start_name))
    {
        return false;
    }

    try validateLifetimeCall(block.instructions.items[2], "llvm.lifetime.start.p0", request_name);
    try validateRequestStore(block.instructions.items[3], 4098, request_name);
    const start_slot = try validateRequestGep(block.instructions.items[4], request_name, 8);
    try validateRequestStoreNamed(block.instructions.items[5], start_name, start_slot);
    const len_slot = try validateRequestGep(block.instructions.items[6], request_name, 16);
    try validateRequestStoreNamed(block.instructions.items[7], len_name, len_slot);
    const arg3_slot = try validateRequestGep(block.instructions.items[8], request_name, 24);
    try validateRequestStore(block.instructions.items[9], 0, arg3_slot);
    const arg4_slot = try validateRequestGep(block.instructions.items[10], request_name, 32);
    try validateRequestStore(block.instructions.items[11], 0, arg4_slot);
    const arg5_slot = try validateRequestGep(block.instructions.items[12], request_name, 40);
    try validateRequestStore(block.instructions.items[13], 0, arg5_slot);
    try validateValgrindClientRequestAsm(block.instructions.items[14], request_name);
    try validateLifetimeCall(block.instructions.items[15], "llvm.lifetime.end.p0", request_name);

    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (ret.ty != .void or ret.value != null) return false;

    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerGuardedStrncatBody(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!matchesGuardedStrncatBody(function)) return false;
    const dst_reg = try paramReg(function, function.params.items[0].name, .ptr);
    const src_reg = try paramReg(function, function.params.items[1].name, .ptr);
    const max_reg = try paramReg(function, function.params.items[2].name, .{ .int = 64 });
    const guard_reg = try paramReg(function, function.params.items[3].name, .{ .int = 64 });
    if (dst_reg != .rdi or src_reg != .rsi or max_reg != .rdx or guard_reg != .rcx) return error.UnsupportedCodegenAbi;

    try machine.instructions.append(allocator, .guarded_strncat_rdi_rsi_rdx_rcx_rax);
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerGuardedStrcatBody(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!matchesGuardedStrcatBody(function)) return false;
    const dst_reg = try paramReg(function, function.params.items[0].name, .ptr);
    const src_reg = try paramReg(function, function.params.items[1].name, .ptr);
    const guard_reg = try paramReg(function, function.params.items[2].name, .{ .int = 64 });
    if (dst_reg != .rdi or src_reg != .rsi or guard_reg != .rdx) return error.UnsupportedCodegenAbi;

    try machine.instructions.append(allocator, .guarded_strcat_rdi_rsi_rdx_rax);
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerGuardedStrncpyBody(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!matchesGuardedStrncpyBody(function)) return false;
    const dst_reg = try paramReg(function, function.params.items[0].name, .ptr);
    const src_reg = try paramReg(function, function.params.items[1].name, .ptr);
    const len_reg = try paramReg(function, function.params.items[2].name, .{ .int = 64 });
    const guard_reg = try paramReg(function, function.params.items[3].name, .{ .int = 64 });
    if (dst_reg != .rdi or src_reg != .rsi or len_reg != .rdx or guard_reg != .rcx) return error.UnsupportedCodegenAbi;

    try machine.instructions.append(allocator, .guarded_strncpy_rdi_rsi_rdx_rcx_rax);
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerGuardedStrcpyBody(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!matchesGuardedStrcpyBody(function)) return false;
    const dst_reg = try paramReg(function, function.params.items[0].name, .ptr);
    const src_reg = try paramReg(function, function.params.items[1].name, .ptr);
    const guard_reg = try paramReg(function, function.params.items[2].name, .{ .int = 64 });
    if (dst_reg != .rdi or src_reg != .rsi or guard_reg != .rdx) return error.UnsupportedCodegenAbi;

    try machine.instructions.append(allocator, .guarded_strcpy_rdi_rsi_rdx_rax);
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerByteMemsetLoop(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!matchesByteMemsetLoop(function)) return false;
    const ptr_reg = try paramReg(function, function.params.items[0].name, .ptr);
    const byte_reg = try paramReg(function, function.params.items[1].name, .{ .int = 8 });
    const len_reg = try paramReg(function, function.params.items[2].name, .{ .int = 64 });
    if (ptr_reg != .rdi or byte_reg != .rsi or len_reg != .rdx) return error.UnsupportedCodegenAbi;

    try machine.instructions.append(allocator, .{ .memset_rdi_sil_rdx_rax = .byte_loop });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn matchesGuardedMemmoveCall(function: ir.Function) ?[]const u8 {
    if (!function.ret_ty.eql(.ptr)) return null;
    if (function.params.items.len != 4 or function.params.items[0].ty != .ptr or
        function.params.items[1].ty != .ptr or !function.params.items[2].ty.eql(.{ .int = 64 }) or
        !function.params.items[3].ty.eql(.{ .int = 64 })) return null;
    if (function.blocks.items.len != 3) return null;

    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 1) return null;
    const guard_cmp_name = entry.instructions.items[0].result orelse return null;
    const guard_cmp = switch (entry.instructions.items[0].kind) {
        .icmp => |icmp| icmp,
        else => return null,
    };
    if (guard_cmp.predicate != .ult or !guard_cmp.operand_ty.eql(.{ .int = 64 }) or
        !isNamed(guard_cmp.lhs, function.params.items[3].name) or !isNamed(guard_cmp.rhs, function.params.items[2].name)) return null;
    const entry_br = switch (entry.terminator orelse return null) {
        .condbr => |condbr| condbr,
        else => return null,
    };
    if (!entry_br.cond_ty.eql(.{ .int = 1 }) or !isNamed(entry_br.cond, guard_cmp_name)) return null;

    const trap_block = blockByName(function, entry_br.then_target) orelse return null;
    const call_block = blockByName(function, entry_br.else_target) orelse return null;
    if (!matchesTrapBlock(trap_block)) return null;
    if (call_block.instructions.items.len != 1) return null;

    const call = switch (call_block.instructions.items[0].kind) {
        .call => |call| call,
        else => return null,
    };
    if (call.callee_value != null or call.inline_asm != null or !call.ret_ty.eql(.ptr) or call.args.items.len != 3) return null;
    if (!call.args.items[0].ty.eql(.ptr) or !isNamed(call.args.items[0].value, function.params.items[0].name)) return null;
    if (!call.args.items[1].ty.eql(.ptr) or !isNamed(call.args.items[1].value, function.params.items[1].name)) return null;
    if (!call.args.items[2].ty.eql(.{ .int = 64 }) or !isNamed(call.args.items[2].value, function.params.items[2].name)) return null;

    const ret = switch (call_block.terminator orelse return null) {
        .ret => |ret| ret,
        else => return null,
    };
    if (!ret.ty.eql(.ptr) or !isNamed(ret.value orelse return null, function.params.items[0].name)) return null;
    return call.callee;
}

fn matchesTrapBlock(block: ir.BasicBlock) bool {
    if (block.instructions.items.len != 1) return false;
    if (block.instructions.items[0].result != null) return false;
    const call = switch (block.instructions.items[0].kind) {
        .call => |call| call,
        else => return false,
    };
    if (!isCalleeName(call.callee, "llvm.trap") or call.callee_value != null or call.inline_asm != null or call.ret_ty != .void or call.args.items.len != 0) return false;
    return switch (block.terminator orelse return false) {
        .@"unreachable" => true,
        else => false,
    };
}

fn validateLifetimeCall(instruction: ir.Instruction, callee: []const u8, ptr_name: []const u8) !void {
    if (instruction.removed or instruction.result != null) return error.UnsupportedCodegenInstruction;
    const call = switch (instruction.kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!std.mem.eql(u8, call.callee, callee) or call.ret_ty != .void or call.args.items.len != 1) return error.UnsupportedCodegenInstruction;
    if (call.callee_value != null or call.inline_asm != null or call.calling_conv != null or call.ret_attrs != null or call.operand_bundle != null) return error.UnsupportedCodegenInstruction;
    const arg = call.args.items[0];
    if (arg.ty != .ptr or !isNamed(arg.value, ptr_name)) return error.UnsupportedCodegenInstruction;
}

fn validateRequestGep(instruction: ir.Instruction, request_name: []const u8, offset: i128) ![]const u8 {
    if (instruction.removed) return error.UnsupportedCodegenInstruction;
    const result = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const gep = switch (instruction.kind) {
        .gep => |gep| gep,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!gep.source_ty.eql(.{ .int = 8 }) or !isNamed(gep.ptr, request_name) or gep.ptr_addrspace != null) return error.UnsupportedCodegenInstruction;
    if (gep.indices.items.len != 1) return error.UnsupportedCodegenInstruction;
    const index = gep.indices.items[0];
    if (!index.ty.eql(.{ .int = 64 }) or !isInt(index.value, offset)) return error.UnsupportedCodegenInstruction;
    return result;
}

fn validateRequestStore(instruction: ir.Instruction, value: i128, ptr_name: []const u8) !void {
    if (instruction.removed or instruction.result != null) return error.UnsupportedCodegenInstruction;
    const store = switch (instruction.kind) {
        .store => |store| store,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!store.ty.eql(.{ .int = 64 }) or !isInt(store.value, value) or !isNamed(store.ptr, ptr_name)) return error.UnsupportedCodegenInstruction;
    if (store.ty_addrspace != null or store.ptr_addrspace != null or store.attrs.isBarrier()) return error.UnsupportedCodegenInstruction;
}

fn validateRequestStoreNamed(instruction: ir.Instruction, value_name: []const u8, ptr_name: []const u8) !void {
    if (instruction.removed or instruction.result != null) return error.UnsupportedCodegenInstruction;
    const store = switch (instruction.kind) {
        .store => |store| store,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!store.ty.eql(.{ .int = 64 }) or !isNamed(store.value, value_name) or !isNamed(store.ptr, ptr_name)) return error.UnsupportedCodegenInstruction;
    if (store.ty_addrspace != null or store.ptr_addrspace != null or store.attrs.isBarrier()) return error.UnsupportedCodegenInstruction;
}

fn validateValgrindClientRequestAsm(instruction: ir.Instruction, request_name: []const u8) !void {
    if (instruction.removed or instruction.result == null) return error.UnsupportedCodegenInstruction;
    const call = switch (instruction.kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    const inline_asm = call.inline_asm orelse return error.UnsupportedCodegenInstruction;
    if (!call.ret_ty.eql(.{ .int = 64 }) or call.args.items.len != 2) return error.UnsupportedCodegenInstruction;
    if (call.callee_value != null or call.calling_conv != null or call.ret_attrs != null or call.operand_bundle != null) return error.UnsupportedCodegenInstruction;
    if (!inline_asm.sideeffect) return error.UnsupportedCodegenInstruction;
    if (!std.mem.eql(u8, inline_asm.template, " rolq  $$3,    %rdi ; rolq $$13, %rdi\\0A rolq  $$61,   %rdi ; rolq $$51, %rdi\\0A xchgq %rbx, %rbx")) {
        return error.UnsupportedCodegenInstruction;
    }
    if (!std.mem.eql(u8, inline_asm.constraints, "={rdx},{rax},{rdx},~{memory},~{dirflag},~{fpsr},~{flags}")) return error.UnsupportedCodegenInstruction;
    if (call.args.items[0].ty != .ptr or !isNamed(call.args.items[0].value, request_name)) return error.UnsupportedCodegenInstruction;
    if (!call.args.items[1].ty.eql(.{ .int = 64 }) or !isInt(call.args.items[1].value, 0)) return error.UnsupportedCodegenInstruction;
}

fn matchesGuardedMemcpyBody(function: ir.Function) bool {
    if (!function.ret_ty.eql(.ptr)) return false;
    if (function.params.items.len != 4 or function.params.items[0].ty != .ptr or
        function.params.items[1].ty != .ptr or !function.params.items[2].ty.eql(.{ .int = 64 }) or
        !function.params.items[3].ty.eql(.{ .int = 64 })) return false;
    if (function.blocks.items.len < 4) return false;

    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 1) return false;
    const guard_cmp_name = entry.instructions.items[0].result orelse return false;
    const guard_cmp = switch (entry.instructions.items[0].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (guard_cmp.predicate != .ult or !guard_cmp.operand_ty.eql(.{ .int = 64 }) or
        !isNamed(guard_cmp.lhs, function.params.items[3].name) or !isNamed(guard_cmp.rhs, function.params.items[2].name)) return false;
    const entry_br = switch (entry.terminator orelse return false) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!entry_br.cond_ty.eql(.{ .int = 1 }) or !isNamed(entry_br.cond, guard_cmp_name)) return false;

    const trap_block = blockByName(function, entry_br.then_target) orelse return false;
    if (!matchesTrapBlock(trap_block)) return false;
    const body_entry = blockByName(function, entry_br.else_target) orelse return false;

    var saw_body_entry = false;
    var saw_load = false;
    var saw_store = false;
    var saw_ret = false;
    for (function.blocks.items) |block| {
        if (std.mem.eql(u8, block.name, entry.name) or std.mem.eql(u8, block.name, trap_block.name)) continue;
        if (std.mem.eql(u8, block.name, body_entry.name)) saw_body_entry = true;
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            switch (instruction.kind) {
                .binary, .icmp, .phi, .gep, .cast => {},
                .load => |load| {
                    if (load.attrs.isBarrier()) return false;
                    if (!valueDerivedFromPointer(function, load.ptr, function.params.items[1].name, 0)) return false;
                    saw_load = true;
                },
                .store => |store| {
                    if (store.attrs.isBarrier()) return false;
                    if (!valueDerivedFromPointer(function, store.ptr, function.params.items[0].name, 0)) return false;
                    if (!valueIsLoadFromPointer(function, store.value, function.params.items[1].name)) return false;
                    saw_store = true;
                },
                .call => |call| {
                    if (!isMemcpyBodyMetadataCall(call)) return false;
                },
                .freeze, .fcmp, .select, .alloca, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue => return false,
            }
        }

        switch (block.terminator orelse return false) {
            .br, .condbr => {},
            .ret => |ret| {
                if (!ret.ty.eql(.ptr) or !isNamed(ret.value orelse return false, function.params.items[0].name)) return false;
                saw_ret = true;
            },
            .@"unreachable", .@"switch", .indirectbr => return false,
        }
    }

    return saw_body_entry and saw_load and saw_store and saw_ret;
}

fn matchesMemmoveBody(function: ir.Function) bool {
    if (!function.ret_ty.eql(.ptr)) return false;
    if (function.params.items.len != 3 or function.params.items[0].ty != .ptr or
        function.params.items[1].ty != .ptr or !function.params.items[2].ty.eql(.{ .int = 64 })) return false;
    if (function.blocks.items.len < 4) return false;

    var saw_overlap_split = false;
    var saw_src_load = false;
    var saw_dst_store = false;
    var saw_temp_alloca = false;
    var saw_temp_copy = false;
    var saw_ret = false;

    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            switch (instruction.kind) {
                .alloca => |alloca| {
                    if (alloca.allocated_ty.eql(.{ .aggregate = "[16 x i8]" })) saw_temp_alloca = true;
                },
                .binary, .phi, .gep, .cast => {},
                .icmp => |icmp| {
                    if (icmp.predicate == .ult and icmp.operand_ty.eql(.ptr) and
                        isNamed(icmp.lhs, function.params.items[1].name) and
                        isNamed(icmp.rhs, function.params.items[0].name)) saw_overlap_split = true;
                },
                .load => |load| {
                    if (load.attrs.isBarrier()) return false;
                    if (valueDerivedFromMemmovePointer(function, load.ptr, function.params.items[1].name, 0)) {
                        saw_src_load = true;
                    } else if (!valueDerivedFromAlloca(function, load.ptr, 0)) {
                        return false;
                    }
                },
                .store => |store| {
                    if (store.attrs.isBarrier()) return false;
                    if (valueDerivedFromMemmovePointer(function, store.ptr, function.params.items[0].name, 0)) {
                        if (!valueIsLoadFromPointer(function, store.value, function.params.items[1].name)) return false;
                        saw_dst_store = true;
                    } else if (!valueDerivedFromAlloca(function, store.ptr, 0)) {
                        return false;
                    }
                },
                .call => |call| {
                    if (isMemcpyInline16BetweenMemmoveStorage(function, call)) {
                        saw_temp_copy = true;
                    } else if (!isMemcpyBodyMetadataCall(call)) {
                        return false;
                    }
                },
                .freeze, .fcmp, .select, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue => return false,
            }
        }

        switch (block.terminator orelse return false) {
            .br, .condbr => {},
            .ret => |ret| {
                if (!ret.ty.eql(.ptr) or !isNamed(ret.value orelse return false, function.params.items[0].name)) return false;
                saw_ret = true;
            },
            .@"unreachable", .@"switch", .indirectbr => return false,
        }
    }

    return saw_overlap_split and saw_src_load and saw_dst_store and saw_temp_alloca and saw_temp_copy and saw_ret;
}

fn matchesMemcpyBody(function: ir.Function) bool {
    if (!function.ret_ty.eql(.ptr)) return false;
    if (function.params.items.len != 3 or function.params.items[0].ty != .ptr or
        function.params.items[1].ty != .ptr or !function.params.items[2].ty.eql(.{ .int = 64 })) return false;
    if (function.blocks.items.len < 4) return false;

    var saw_len_split = false;
    var saw_src_load = false;
    var saw_dst_store = false;
    var saw_ret = false;

    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            switch (instruction.kind) {
                .binary, .phi, .gep, .cast => {},
                .icmp => |icmp| {
                    if (icmp.predicate == .ult and icmp.operand_ty.eql(.{ .int = 64 }) and
                        isNamed(icmp.lhs, function.params.items[2].name) and icmp.rhs.eql(.{ .int = 16 })) saw_len_split = true;
                },
                .load => |load| {
                    if (load.attrs.isBarrier()) return false;
                    if (!valueDerivedFromPointer(function, load.ptr, function.params.items[1].name, 0)) return false;
                    saw_src_load = true;
                },
                .store => |store| {
                    if (store.attrs.isBarrier()) return false;
                    if (!valueDerivedFromPointer(function, store.ptr, function.params.items[0].name, 0)) return false;
                    if (!valueIsLoadFromPointer(function, store.value, function.params.items[1].name)) return false;
                    saw_dst_store = true;
                },
                .call => |call| {
                    if (!isMemcpyBodyMetadataCall(call)) return false;
                },
                .alloca, .freeze, .fcmp, .select, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue => return false,
            }
        }

        switch (block.terminator orelse return false) {
            .br, .condbr => {},
            .ret => |ret| {
                if (!ret.ty.eql(.ptr) or !isNamed(ret.value orelse return false, function.params.items[0].name)) return false;
                saw_ret = true;
            },
            .@"unreachable", .@"switch", .indirectbr => return false,
        }
    }

    return saw_len_split and saw_src_load and saw_dst_store and saw_ret;
}

fn matchesGuardedStrncatBody(function: ir.Function) bool {
    if (!function.ret_ty.eql(.ptr)) return false;
    if (function.params.items.len != 4 or function.params.items[0].ty != .ptr or
        function.params.items[1].ty != .ptr or !function.params.items[2].ty.eql(.{ .int = 64 }) or
        !function.params.items[3].ty.eql(.{ .int = 64 })) return false;
    if (function.blocks.items.len < 6) return false;

    const entry = function.blocks.items[0];
    if (entry.instructions.items.len == 0) return false;
    const guard_zero_name = entry.instructions.items[entry.instructions.items.len - 1].result orelse return false;
    const guard_zero = switch (entry.instructions.items[entry.instructions.items.len - 1].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (guard_zero.predicate != .eq or !guard_zero.operand_ty.eql(.{ .int = 64 }) or
        !isNamed(guard_zero.lhs, function.params.items[3].name) or !guard_zero.rhs.eql(.{ .int = 0 })) return false;
    const entry_br = switch (entry.terminator orelse return false) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!entry_br.cond_ty.eql(.{ .int = 1 }) or !isNamed(entry_br.cond, guard_zero_name)) return false;

    var saw_dst_load = false;
    var saw_src_load = false;
    var saw_src_store = false;
    var saw_zero_terminator = false;
    var saw_ret = false;
    var saw_trap = false;
    var saw_max_bound = false;

    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            switch (instruction.kind) {
                .binary, .phi, .gep, .cast, .select => {},
                .icmp => |icmp| {
                    if (icmp.operand_ty.eql(.{ .int = 64 }) and
                        (isNamed(icmp.lhs, function.params.items[2].name) or isNamed(icmp.rhs, function.params.items[2].name))) saw_max_bound = true;
                },
                .load => |load| {
                    if (load.attrs.isBarrier()) return false;
                    if (valueDerivedFromPointer(function, load.ptr, function.params.items[0].name, 0)) {
                        if (!load.ty.eql(.{ .int = 8 })) return false;
                        saw_dst_load = true;
                    } else if (valueDerivedFromPointer(function, load.ptr, function.params.items[1].name, 0)) {
                        if (!load.ty.eql(.{ .int = 8 })) return false;
                        saw_src_load = true;
                    } else {
                        return false;
                    }
                },
                .store => |store| {
                    if (store.attrs.isBarrier()) return false;
                    if (!valueDerivedFromPointer(function, store.ptr, function.params.items[0].name, 0)) return false;
                    if (valueIsLoadFromPointer(function, store.value, function.params.items[1].name)) {
                        saw_src_store = true;
                    } else if (store.value.eql(.{ .int = 0 })) {
                        saw_zero_terminator = true;
                    } else {
                        return false;
                    }
                },
                .call => |call| {
                    if (isCalleeName(call.callee, "llvm.trap")) {
                        if (call.callee_value != null or call.inline_asm != null or call.ret_ty != .void or call.args.items.len != 0) return false;
                        saw_trap = true;
                    } else if (!isMemcpyBodyMetadataCall(call)) {
                        return false;
                    }
                },
                .freeze, .fcmp, .alloca, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue => return false,
            }
        }

        switch (block.terminator orelse return false) {
            .br, .condbr => {},
            .ret => |ret| {
                if (!ret.ty.eql(.ptr) or !isNamed(ret.value orelse return false, function.params.items[0].name)) return false;
                saw_ret = true;
            },
            .@"unreachable" => {},
            .@"switch", .indirectbr => return false,
        }
    }

    return saw_dst_load and saw_src_load and saw_src_store and saw_zero_terminator and
        saw_ret and saw_trap and saw_max_bound;
}

fn matchesGuardedStrcatBody(function: ir.Function) bool {
    if (!function.ret_ty.eql(.ptr)) return false;
    if (function.params.items.len != 3 or function.params.items[0].ty != .ptr or
        function.params.items[1].ty != .ptr or !function.params.items[2].ty.eql(.{ .int = 64 })) return false;
    if (function.blocks.items.len < 6) return false;

    const entry = function.blocks.items[0];
    if (entry.instructions.items.len == 0) return false;
    const guard_zero_name = entry.instructions.items[entry.instructions.items.len - 1].result orelse return false;
    const guard_zero = switch (entry.instructions.items[entry.instructions.items.len - 1].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (guard_zero.predicate != .eq or !guard_zero.operand_ty.eql(.{ .int = 64 }) or
        !isNamed(guard_zero.lhs, function.params.items[2].name) or !guard_zero.rhs.eql(.{ .int = 0 })) return false;
    const entry_br = switch (entry.terminator orelse return false) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!entry_br.cond_ty.eql(.{ .int = 1 }) or !isNamed(entry_br.cond, guard_zero_name)) return false;

    var saw_dst_load = false;
    var saw_src_load = false;
    var saw_src_store = false;
    var saw_zero_terminator = false;
    var saw_ret = false;
    var saw_trap = false;

    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            switch (instruction.kind) {
                .binary, .phi, .gep, .cast => {},
                .icmp => {},
                .load => |load| {
                    if (load.attrs.isBarrier()) return false;
                    if (valueDerivedFromPointer(function, load.ptr, function.params.items[0].name, 0)) {
                        if (!load.ty.eql(.{ .int = 8 })) return false;
                        saw_dst_load = true;
                    } else if (valueDerivedFromPointer(function, load.ptr, function.params.items[1].name, 0)) {
                        if (!load.ty.eql(.{ .int = 8 })) return false;
                        saw_src_load = true;
                    } else {
                        return false;
                    }
                },
                .store => |store| {
                    if (store.attrs.isBarrier()) return false;
                    if (!valueDerivedFromPointer(function, store.ptr, function.params.items[0].name, 0)) return false;
                    if (valueIsLoadFromPointer(function, store.value, function.params.items[1].name)) {
                        saw_src_store = true;
                    } else if (store.value.eql(.{ .int = 0 })) {
                        saw_zero_terminator = true;
                    } else {
                        return false;
                    }
                },
                .call => |call| {
                    if (isCalleeName(call.callee, "llvm.trap")) {
                        if (call.callee_value != null or call.inline_asm != null or call.ret_ty != .void or call.args.items.len != 0) return false;
                        saw_trap = true;
                    } else if (!isMemcpyBodyMetadataCall(call)) {
                        return false;
                    }
                },
                .freeze, .fcmp, .select, .alloca, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue => return false,
            }
        }

        switch (block.terminator orelse return false) {
            .br, .condbr => {},
            .ret => |ret| {
                if (!ret.ty.eql(.ptr) or !isNamed(ret.value orelse return false, function.params.items[0].name)) return false;
                saw_ret = true;
            },
            .@"unreachable" => {},
            .@"switch", .indirectbr => return false,
        }
    }

    return saw_dst_load and saw_src_load and saw_src_store and saw_zero_terminator and
        saw_ret and saw_trap;
}

fn matchesGuardedStrncpyBody(function: ir.Function) bool {
    if (!function.ret_ty.eql(.ptr)) return false;
    if (function.params.items.len != 4 or function.params.items[0].ty != .ptr or
        function.params.items[1].ty != .ptr or !function.params.items[2].ty.eql(.{ .int = 64 }) or
        !function.params.items[3].ty.eql(.{ .int = 64 })) return false;
    if (function.blocks.items.len < 5) return false;

    const entry = function.blocks.items[0];
    if (entry.instructions.items.len == 0) return false;
    const guard_cmp_name = entry.instructions.items[entry.instructions.items.len - 1].result orelse return false;
    const guard_cmp = switch (entry.instructions.items[entry.instructions.items.len - 1].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (guard_cmp.predicate != .ult or !guard_cmp.operand_ty.eql(.{ .int = 64 }) or
        !isNamed(guard_cmp.lhs, function.params.items[3].name) or !isNamed(guard_cmp.rhs, function.params.items[2].name)) return false;
    const entry_br = switch (entry.terminator orelse return false) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!entry_br.cond_ty.eql(.{ .int = 1 }) or !isNamed(entry_br.cond, guard_cmp_name)) return false;

    var saw_src_load = false;
    var saw_src_store = false;
    var saw_zero_padding = false;
    var saw_ret = false;
    var saw_trap = false;
    var saw_len_bound = false;

    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            switch (instruction.kind) {
                .binary, .phi, .gep, .cast => {},
                .icmp => |icmp| {
                    if (icmp.operand_ty.eql(.{ .int = 64 }) and
                        (isNamed(icmp.lhs, function.params.items[2].name) or isNamed(icmp.rhs, function.params.items[2].name))) saw_len_bound = true;
                },
                .load => |load| {
                    if (load.attrs.isBarrier() or !load.ty.eql(.{ .int = 8 })) return false;
                    if (!valueDerivedFromPointer(function, load.ptr, function.params.items[1].name, 0)) return false;
                    saw_src_load = true;
                },
                .store => |store| {
                    if (store.attrs.isBarrier()) return false;
                    if (!valueDerivedFromPointer(function, store.ptr, function.params.items[0].name, 0)) return false;
                    if (valueIsLoadFromPointer(function, store.value, function.params.items[1].name)) {
                        saw_src_store = true;
                    } else if (store.value.eql(.{ .int = 0 })) {
                        saw_zero_padding = true;
                    } else {
                        return false;
                    }
                },
                .call => |call| {
                    if (isCalleeName(call.callee, "llvm.trap")) {
                        if (call.callee_value != null or call.inline_asm != null or call.ret_ty != .void or call.args.items.len != 0) return false;
                        saw_trap = true;
                    } else if (!isMemcpyBodyMetadataCall(call)) {
                        return false;
                    }
                },
                .freeze, .fcmp, .select, .alloca, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue => return false,
            }
        }

        switch (block.terminator orelse return false) {
            .br, .condbr => {},
            .ret => |ret| {
                if (!ret.ty.eql(.ptr) or !isNamed(ret.value orelse return false, function.params.items[0].name)) return false;
                saw_ret = true;
            },
            .@"unreachable" => {},
            .@"switch", .indirectbr => return false,
        }
    }

    return saw_src_load and saw_src_store and saw_zero_padding and saw_ret and
        saw_trap and saw_len_bound;
}

fn matchesGuardedStrcpyBody(function: ir.Function) bool {
    if (!function.ret_ty.eql(.ptr)) return false;
    if (function.params.items.len != 3 or function.params.items[0].ty != .ptr or
        function.params.items[1].ty != .ptr or !function.params.items[2].ty.eql(.{ .int = 64 })) return false;
    if (function.blocks.items.len < 4) return false;

    const entry = function.blocks.items[0];
    if (entry.instructions.items.len == 0) return false;
    const guard_zero_name = entry.instructions.items[entry.instructions.items.len - 1].result orelse return false;
    const guard_zero = switch (entry.instructions.items[entry.instructions.items.len - 1].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (guard_zero.predicate != .eq or !guard_zero.operand_ty.eql(.{ .int = 64 }) or
        !isNamed(guard_zero.lhs, function.params.items[2].name) or !guard_zero.rhs.eql(.{ .int = 0 })) return false;
    const entry_br = switch (entry.terminator orelse return false) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!entry_br.cond_ty.eql(.{ .int = 1 }) or !isNamed(entry_br.cond, guard_zero_name)) return false;

    var saw_src_load = false;
    var saw_src_store = false;
    var saw_zero_terminator = false;
    var saw_ret = false;
    var saw_trap = false;

    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            switch (instruction.kind) {
                .binary, .phi, .gep, .cast => {},
                .icmp => {},
                .load => |load| {
                    if (load.attrs.isBarrier() or !load.ty.eql(.{ .int = 8 })) return false;
                    if (!valueDerivedFromPointer(function, load.ptr, function.params.items[1].name, 0)) return false;
                    saw_src_load = true;
                },
                .store => |store| {
                    if (store.attrs.isBarrier()) return false;
                    if (!valueDerivedFromPointer(function, store.ptr, function.params.items[0].name, 0)) return false;
                    if (valueIsLoadFromPointer(function, store.value, function.params.items[1].name)) {
                        saw_src_store = true;
                    } else if (store.value.eql(.{ .int = 0 })) {
                        saw_zero_terminator = true;
                    } else {
                        return false;
                    }
                },
                .call => |call| {
                    if (isCalleeName(call.callee, "llvm.trap")) {
                        if (call.callee_value != null or call.inline_asm != null or call.ret_ty != .void or call.args.items.len != 0) return false;
                        saw_trap = true;
                    } else if (!isMemcpyBodyMetadataCall(call)) {
                        return false;
                    }
                },
                .freeze, .fcmp, .select, .alloca, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue => return false,
            }
        }

        switch (block.terminator orelse return false) {
            .br, .condbr => {},
            .ret => |ret| {
                if (!ret.ty.eql(.ptr) or !isNamed(ret.value orelse return false, function.params.items[0].name)) return false;
                saw_ret = true;
            },
            .@"unreachable" => {},
            .@"switch", .indirectbr => return false,
        }
    }

    return saw_src_load and saw_src_store and saw_zero_terminator and saw_ret and saw_trap;
}

fn valueIsLoadFromPointer(function: ir.Function, value: ir.Value, root_name: []const u8) bool {
    const name = switch (value) {
        .named => |name| name,
        else => return false,
    };
    const instruction = instructionByResult(function, name) orelse return false;
    const load = switch (instruction.kind) {
        .load => |load| load,
        else => return false,
    };
    return !load.attrs.isBarrier() and valueDerivedFromPointer(function, load.ptr, root_name, 0);
}

fn valueDerivedFromPointer(function: ir.Function, value: ir.Value, root_name: []const u8, depth: u8) bool {
    if (depth > 16) return false;
    const name = switch (value) {
        .named => |name| name,
        else => return false,
    };
    if (std.mem.eql(u8, name, root_name)) return true;
    const instruction = instructionByResult(function, name) orelse return false;
    return switch (instruction.kind) {
        .gep => |gep| valueDerivedFromPointer(function, gep.ptr, root_name, depth + 1),
        .cast => |cast| cast.to_ty.eql(.ptr) and valueDerivedFromPointer(function, cast.value, root_name, depth + 1),
        .phi => |phi| blk: {
            if (phi.incoming.items.len == 0 or !phi.ty.eql(.ptr)) break :blk false;
            for (phi.incoming.items) |incoming| {
                if (!valueDerivedFromPointer(function, incoming.value, root_name, depth + 1)) break :blk false;
            }
            break :blk true;
        },
        else => false,
    };
}

fn valueDerivedFromMemmovePointer(function: ir.Function, value: ir.Value, root_name: []const u8, depth: u8) bool {
    if (valueDerivedFromPointer(function, value, root_name, depth)) return true;
    if (depth > 16) return false;
    const name = switch (value) {
        .named => |name| name,
        else => return false,
    };
    const instruction = instructionByResult(function, name) orelse return false;
    return switch (instruction.kind) {
        .gep => |gep| valueDerivedFromMemmovePointer(function, gep.ptr, root_name, depth + 1),
        .cast => |cast| cast.op == .inttoptr and cast.to_ty.eql(.ptr) and
            intValueDerivedFromPointer(function, cast.value, root_name, depth + 1),
        else => false,
    };
}

fn intValueDerivedFromPointer(function: ir.Function, value: ir.Value, root_name: []const u8, depth: u8) bool {
    if (depth > 16) return false;
    const name = switch (value) {
        .named => |name| name,
        .int => return false,
        else => return false,
    };
    const instruction = instructionByResult(function, name) orelse return false;
    return switch (instruction.kind) {
        .cast => |cast| cast.op == .ptrtoint and cast.from_ty.eql(.ptr) and
            valueDerivedFromPointer(function, cast.value, root_name, depth + 1),
        .binary => |binary| switch (binary.op) {
            .add, .sub, .@"and", .@"or", .xor, .shl, .lshr, .ashr => intValueDerivedFromPointer(function, binary.lhs, root_name, depth + 1) or
                intValueDerivedFromPointer(function, binary.rhs, root_name, depth + 1),
            else => false,
        },
        .phi => |phi| blk: {
            if (phi.incoming.items.len == 0 or !phi.ty.eql(.{ .int = 64 })) break :blk false;
            for (phi.incoming.items) |incoming| {
                if (!intValueDerivedFromPointer(function, incoming.value, root_name, depth + 1)) break :blk false;
            }
            break :blk true;
        },
        else => false,
    };
}

fn valueDerivedFromAlloca(function: ir.Function, value: ir.Value, depth: u8) bool {
    if (depth > 16) return false;
    const name = switch (value) {
        .named => |name| name,
        else => return false,
    };
    const instruction = instructionByResult(function, name) orelse return false;
    return switch (instruction.kind) {
        .alloca => true,
        .gep => |gep| valueDerivedFromAlloca(function, gep.ptr, depth + 1),
        .cast => |cast| cast.to_ty.eql(.ptr) and valueDerivedFromAlloca(function, cast.value, depth + 1),
        .phi => |phi| blk: {
            if (phi.incoming.items.len == 0 or !phi.ty.eql(.ptr)) break :blk false;
            for (phi.incoming.items) |incoming| {
                if (!valueDerivedFromAlloca(function, incoming.value, depth + 1)) break :blk false;
            }
            break :blk true;
        },
        else => false,
    };
}

fn instructionByResult(function: ir.Function, result_name: []const u8) ?ir.Instruction {
    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            if (instruction.result) |result| {
                if (std.mem.eql(u8, result, result_name)) return instruction;
            }
        }
    }
    return null;
}

fn isMemcpyInline16BetweenMemmoveStorage(function: ir.Function, call: ir.CallInst) bool {
    if (call.callee_value != null or call.inline_asm != null or call.ret_ty != .void or call.args.items.len != 4) return false;
    if (!isCalleeName(call.callee, "llvm.memcpy.inline.p0.p0.i64")) return false;
    if (!call.args.items[0].ty.eql(.ptr) or !call.args.items[1].ty.eql(.ptr) or
        !call.args.items[2].ty.eql(.{ .int = 64 }) or !isInt(call.args.items[2].value, 16) or
        !call.args.items[3].ty.eql(.{ .int = 1 }) or !isInt(call.args.items[3].value, 0)) return false;

    const dst = call.args.items[0].value;
    const src = call.args.items[1].value;
    const dst_is_output = valueDerivedFromMemmovePointer(function, dst, function.params.items[0].name, 0);
    const src_is_input = valueDerivedFromMemmovePointer(function, src, function.params.items[1].name, 0);
    const dst_is_temp = valueDerivedFromAlloca(function, dst, 0);
    const src_is_temp = valueDerivedFromAlloca(function, src, 0);
    return (dst_is_temp and src_is_input) or (dst_is_output and src_is_temp);
}

fn isMemcpyBodyMetadataCall(call: ir.CallInst) bool {
    if (call.callee_value != null or call.inline_asm != null or call.ret_ty != .void) return false;
    return isCalleeName(call.callee, "llvm.experimental.noalias.scope.decl") or
        isCalleeName(call.callee, "llvm.assume");
}

fn matchSpinlockedMemcpyBody(function: ir.Function) !?[]const u8 {
    if (function.ret_ty != .void or function.params.items.len != 4) return null;
    if (!function.params.items[0].ty.eql(.{ .int = 32 }) or
        !function.params.items[1].ty.eql(.ptr) or
        !function.params.items[2].ty.eql(.ptr) or
        !function.params.items[3].ty.eql(.{ .int = 32 })) return null;
    if (function.blocks.items.len != 3) return null;

    const len_name = function.params.items[0].name;
    const src_name = function.params.items[1].name;
    const dst_name = function.params.items[2].name;
    const entry = function.blocks.items[0];
    const loop = function.blocks.items[1];
    const exit = function.blocks.items[2];

    if (entry.instructions.items.len != 4 or loop.instructions.items.len != 2 or exit.instructions.items.len != 3) return null;
    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) return null;
        }
    }

    const ptr_int_name = entry.instructions.items[0].result orelse return null;
    const ptr_int = switch (entry.instructions.items[0].kind) {
        .cast => |cast| cast,
        else => return null,
    };
    if (ptr_int.op != .ptrtoint or !ptr_int.from_ty.eql(.ptr) or !ptr_int.to_ty.eql(.{ .int = 64 }) or !isNamed(ptr_int.value, src_name)) return null;

    const shifted_name = entry.instructions.items[1].result orelse return null;
    if (!matchI64BinaryNamedImm(entry.instructions.items[1], .lshr, ptr_int_name, 3)) return null;
    const slot_name = entry.instructions.items[2].result orelse return null;
    if (!matchI64BinaryNamedImm(entry.instructions.items[2], .@"and", shifted_name, 63)) return null;

    const lock_ptr_name = entry.instructions.items[3].result orelse return null;
    const spinlock_symbol = try matchSpinlockGep(entry.instructions.items[3], slot_name);
    const entry_br = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .br => |br| br,
        else => return null,
    };
    if (!std.mem.eql(u8, entry_br.target, loop.name)) return null;

    const old_lock_name = loop.instructions.items[0].result orelse return null;
    const atomic = switch (loop.instructions.items[0].kind) {
        .atomicrmw => |atomicrmw| atomicrmw,
        else => return null,
    };
    if (!std.mem.eql(u8, atomic.op, "xchg") or !atomic.ty.eql(.{ .int = 64 }) or
        !isNamed(atomic.ptr, lock_ptr_name) or !isInt(atomic.value, 1) or
        !std.mem.eql(u8, atomic.ordering, "acquire") or atomic.syncscope != null or
        atomic.is_volatile or atomic.@"align" != 8) return null;

    const acquired_name = loop.instructions.items[1].result orelse return null;
    const acquired = switch (loop.instructions.items[1].kind) {
        .icmp => |icmp| icmp,
        else => return null,
    };
    if (acquired.predicate != .eq or !acquired.operand_ty.eql(.{ .int = 64 }) or
        !isNamed(acquired.lhs, old_lock_name) or !isInt(acquired.rhs, 0)) return null;
    const loop_br = switch (loop.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return null,
    };
    if (!loop_br.cond_ty.eql(.{ .int = 1 }) or !isNamed(loop_br.cond, acquired_name) or
        !std.mem.eql(u8, loop_br.then_target, exit.name) or !std.mem.eql(u8, loop_br.else_target, loop.name)) return null;

    const len64_name = exit.instructions.items[0].result orelse return null;
    const len64 = switch (exit.instructions.items[0].kind) {
        .cast => |cast| cast,
        else => return null,
    };
    if (len64.op != .zext or !len64.from_ty.eql(.{ .int = 32 }) or !len64.to_ty.eql(.{ .int = 64 }) or !isNamed(len64.value, len_name)) return null;

    const memcpy = switch (exit.instructions.items[1].kind) {
        .call => |call| call,
        else => return null,
    };
    if (!isSpinlockedMemcpyCall(memcpy, dst_name, src_name, len64_name)) return null;

    const release = switch (exit.instructions.items[2].kind) {
        .store => |store| store,
        else => return null,
    };
    if (!release.ty.eql(.{ .int = 64 }) or !isInt(release.value, 0) or !isNamed(release.ptr, lock_ptr_name) or
        release.attrs.atomic_ordering == null or !std.mem.eql(u8, release.attrs.atomic_ordering.?, "release") or
        release.attrs.@"align" != 64 or release.attrs.is_volatile) return null;
    const ret = switch (exit.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return null,
    };
    if (ret.ty != .void or ret.value != null) return null;

    return spinlock_symbol;
}

fn matchesByteScanLenLoop(function: ir.Function) bool {
    if (!function.ret_ty.eql(.{ .int = 64 })) return false;
    if (function.params.items.len != 1 or function.params.items[0].ty != .ptr) return false;
    if (function.blocks.items.len != 3) return false;

    const entry = function.blocks.items[0];
    const loop = function.blocks.items[1];
    const exit = function.blocks.items[2];
    if (entry.instructions.items.len != 0 or loop.instructions.items.len != 5 or exit.instructions.items.len != 0) return false;

    const entry_br = switch (entry.terminator orelse return false) {
        .br => |br| br,
        else => return false,
    };
    if (!std.mem.eql(u8, entry_br.target, loop.name)) return false;

    const phi_name = loop.instructions.items[0].result orelse return false;
    const gep_name = loop.instructions.items[1].result orelse return false;
    const load_name = loop.instructions.items[2].result orelse return false;
    const icmp_name = loop.instructions.items[3].result orelse return false;
    const next_name = loop.instructions.items[4].result orelse return false;

    const phi = switch (loop.instructions.items[0].kind) {
        .phi => |phi| phi,
        else => return false,
    };
    if (!phi.ty.eql(.{ .int = 64 })) return false;
    if (!phiHasIncomingInt(phi, 0, entry.name) or !phiHasIncoming(phi, next_name, loop.name)) return false;

    const gep = switch (loop.instructions.items[1].kind) {
        .gep => |gep| gep,
        else => return false,
    };
    if (!isByteSourceType(gep.source_ty) or !isNamed(gep.ptr, function.params.items[0].name)) return false;
    if (gep.indices.items.len != 1) return false;
    const gep_index = gep.indices.items[0];
    if (!gep_index.ty.eql(.{ .int = 64 }) or !isNamed(gep_index.value, phi_name)) return false;

    const load = switch (loop.instructions.items[2].kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load.ty.eql(.{ .int = 8 }) or load.attrs.isBarrier() or !isNamed(load.ptr, gep_name)) return false;

    const icmp = switch (loop.instructions.items[3].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (icmp.predicate != .eq or !icmp.operand_ty.eql(.{ .int = 8 }) or !isNamed(icmp.lhs, load_name) or !isInt(icmp.rhs, 0)) return false;

    const next = switch (loop.instructions.items[4].kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (next.op != .add or !next.ty.eql(.{ .int = 64 }) or !isNamed(next.lhs, phi_name) or !isInt(next.rhs, 1)) return false;

    const condbr = switch (loop.terminator orelse return false) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!condbr.cond_ty.eql(.{ .int = 1 }) or !isNamed(condbr.cond, icmp_name)) return false;
    if (!std.mem.eql(u8, condbr.then_target, exit.name) or !std.mem.eql(u8, condbr.else_target, loop.name)) return false;

    const ret = switch (exit.terminator orelse return false) {
        .ret => |ret| ret,
        else => return false,
    };
    return ret.ty.eql(.{ .int = 64 }) and isNamed(ret.value orelse return false, phi_name);
}

fn matchesByteCompareEqualLoop(function: ir.Function) bool {
    if (!function.ret_ty.eql(.{ .int = 32 })) return false;
    if (function.params.items.len != 3 or function.params.items[0].ty != .ptr or
        function.params.items[1].ty != .ptr or !function.params.items[2].ty.eql(.{ .int = 64 })) return false;
    if (function.blocks.items.len != 4) return false;

    const entry = function.blocks.items[0];
    const common_ret = function.blocks.items[1];
    const loop = function.blocks.items[2];
    const then = function.blocks.items[3];
    if (entry.instructions.items.len != 1 or common_ret.instructions.items.len != 1 or
        loop.instructions.items.len != 2 or then.instructions.items.len != 6) return false;

    const entry_cmp_name = entry.instructions.items[0].result orelse return false;
    const entry_cmp = switch (entry.instructions.items[0].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (entry_cmp.predicate != .eq or !entry_cmp.operand_ty.eql(.{ .int = 64 }) or
        !isNamed(entry_cmp.lhs, function.params.items[2].name) or !isInt(entry_cmp.rhs, 0)) return false;
    const entry_br = switch (entry.terminator orelse return false) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!entry_br.cond_ty.eql(.{ .int = 1 }) or !isNamed(entry_br.cond, entry_cmp_name) or
        !std.mem.eql(u8, entry_br.then_target, common_ret.name) or !std.mem.eql(u8, entry_br.else_target, then.name)) return false;

    const ret_phi_name = common_ret.instructions.items[0].result orelse return false;
    const ret_phi = switch (common_ret.instructions.items[0].kind) {
        .phi => |phi| phi,
        else => return false,
    };
    if (!ret_phi.ty.eql(.{ .int = 32 })) return false;
    if (!phiHasIncomingInt(ret_phi, 0, entry.name) or !phiHasIncomingInt(ret_phi, 0, loop.name) or
        !phiHasIncomingInt(ret_phi, 1, then.name)) return false;
    const ret = switch (common_ret.terminator orelse return false) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!ret.ty.eql(.{ .int = 32 }) or !isNamed(ret.value orelse return false, ret_phi_name)) return false;

    const next_index_name = loop.instructions.items[0].result orelse return false;
    const loop_cmp_name = loop.instructions.items[1].result orelse return false;
    const index_name = then.instructions.items[0].result orelse return false;
    const lhs_gep_name = then.instructions.items[1].result orelse return false;
    const lhs_load_name = then.instructions.items[2].result orelse return false;
    const rhs_gep_name = then.instructions.items[3].result orelse return false;
    const rhs_load_name = then.instructions.items[4].result orelse return false;

    const next_index = switch (loop.instructions.items[0].kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (next_index.op != .add or !next_index.ty.eql(.{ .int = 64 }) or !isNamed(next_index.lhs, index_name) or !isInt(next_index.rhs, 1)) return false;
    const loop_cmp = switch (loop.instructions.items[1].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (loop_cmp.predicate != .eq or !loop_cmp.operand_ty.eql(.{ .int = 64 }) or
        !isNamed(loop_cmp.lhs, next_index_name) or !isNamed(loop_cmp.rhs, function.params.items[2].name)) return false;
    const loop_br = switch (loop.terminator orelse return false) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!loop_br.cond_ty.eql(.{ .int = 1 }) or !isNamed(loop_br.cond, loop_cmp_name) or
        !std.mem.eql(u8, loop_br.then_target, common_ret.name) or !std.mem.eql(u8, loop_br.else_target, then.name)) return false;

    const index_phi = switch (then.instructions.items[0].kind) {
        .phi => |phi| phi,
        else => return false,
    };
    if (!index_phi.ty.eql(.{ .int = 64 }) or !phiHasIncomingInt(index_phi, 0, entry.name) or
        !phiHasIncoming(index_phi, next_index_name, loop.name)) return false;
    const lhs_gep = switch (then.instructions.items[1].kind) {
        .gep => |gep| gep,
        else => return false,
    };
    if (!byteCompareGep(lhs_gep, function.params.items[0].name, index_name)) return false;
    const lhs_load = switch (then.instructions.items[2].kind) {
        .load => |load| load,
        else => return false,
    };
    if (!lhs_load.ty.eql(.{ .int = 8 }) or lhs_load.attrs.isBarrier() or !isNamed(lhs_load.ptr, lhs_gep_name)) return false;
    const rhs_gep = switch (then.instructions.items[3].kind) {
        .gep => |gep| gep,
        else => return false,
    };
    if (!byteCompareGep(rhs_gep, function.params.items[1].name, index_name)) return false;
    const rhs_load = switch (then.instructions.items[4].kind) {
        .load => |load| load,
        else => return false,
    };
    if (!rhs_load.ty.eql(.{ .int = 8 }) or rhs_load.attrs.isBarrier() or !isNamed(rhs_load.ptr, rhs_gep_name)) return false;

    const then_br = switch (then.terminator orelse return false) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    const value_cmp = switch (then_br.cond) {
        .named => |name| findIcmpEqI8(then, name) orelse return false,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!isNamed(value_cmp.lhs, lhs_load_name) or !isNamed(value_cmp.rhs, rhs_load_name)) return false;
    return then_br.cond_ty.eql(.{ .int = 1 }) and
        std.mem.eql(u8, then_br.then_target, loop.name) and
        std.mem.eql(u8, then_br.else_target, common_ret.name);
}

fn matchesByteCompareDiffLoop(function: ir.Function) bool {
    if (!function.ret_ty.eql(.{ .int = 32 })) return false;
    if (function.params.items.len != 3 or function.params.items[0].ty != .ptr or
        function.params.items[1].ty != .ptr or !function.params.items[2].ty.eql(.{ .int = 64 })) return false;
    if (function.blocks.items.len != 4) return false;

    const entry = function.blocks.items[0];
    const common_ret = function.blocks.items[1];
    const loop = function.blocks.items[2];
    const then = function.blocks.items[3];
    if (entry.instructions.items.len != 1 or common_ret.instructions.items.len != 1 or
        loop.instructions.items.len != 2 or then.instructions.items.len != 9) return false;

    const entry_cmp_name = entry.instructions.items[0].result orelse return false;
    const entry_cmp = switch (entry.instructions.items[0].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (entry_cmp.predicate != .eq or !entry_cmp.operand_ty.eql(.{ .int = 64 }) or
        !isNamed(entry_cmp.lhs, function.params.items[2].name) or !isInt(entry_cmp.rhs, 0)) return false;
    const entry_br = switch (entry.terminator orelse return false) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!entry_br.cond_ty.eql(.{ .int = 1 }) or !isNamed(entry_br.cond, entry_cmp_name) or
        !std.mem.eql(u8, entry_br.then_target, common_ret.name) or !std.mem.eql(u8, entry_br.else_target, then.name)) return false;

    const ret_phi_name = common_ret.instructions.items[0].result orelse return false;
    const ret_phi = switch (common_ret.instructions.items[0].kind) {
        .phi => |phi| phi,
        else => return false,
    };
    const diff_name = then.instructions.items[7].result orelse return false;
    if (!ret_phi.ty.eql(.{ .int = 32 }) or !phiHasIncomingInt(ret_phi, 0, entry.name) or
        !phiHasIncomingInt(ret_phi, 0, loop.name) or !phiHasIncoming(ret_phi, diff_name, then.name)) return false;
    const ret = switch (common_ret.terminator orelse return false) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!ret.ty.eql(.{ .int = 32 }) or !isNamed(ret.value orelse return false, ret_phi_name)) return false;

    const next_index_name = loop.instructions.items[0].result orelse return false;
    const loop_cmp_name = loop.instructions.items[1].result orelse return false;
    const index_name = then.instructions.items[0].result orelse return false;
    const lhs_gep_name = then.instructions.items[1].result orelse return false;
    const lhs_load_name = then.instructions.items[2].result orelse return false;
    const lhs_zext_name = then.instructions.items[3].result orelse return false;
    const rhs_gep_name = then.instructions.items[4].result orelse return false;
    const rhs_load_name = then.instructions.items[5].result orelse return false;
    const rhs_zext_name = then.instructions.items[6].result orelse return false;
    const value_cmp_name = then.instructions.items[8].result orelse return false;

    const next_index = switch (loop.instructions.items[0].kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (next_index.op != .add or !next_index.ty.eql(.{ .int = 64 }) or !isNamed(next_index.lhs, index_name) or !isInt(next_index.rhs, 1)) return false;
    const loop_cmp = switch (loop.instructions.items[1].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (loop_cmp.predicate != .eq or !loop_cmp.operand_ty.eql(.{ .int = 64 }) or
        !isNamed(loop_cmp.lhs, next_index_name) or !isNamed(loop_cmp.rhs, function.params.items[2].name)) return false;
    const loop_br = switch (loop.terminator orelse return false) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!loop_br.cond_ty.eql(.{ .int = 1 }) or !isNamed(loop_br.cond, loop_cmp_name) or
        !std.mem.eql(u8, loop_br.then_target, common_ret.name) or !std.mem.eql(u8, loop_br.else_target, then.name)) return false;

    const index_phi = switch (then.instructions.items[0].kind) {
        .phi => |phi| phi,
        else => return false,
    };
    if (!index_phi.ty.eql(.{ .int = 64 }) or !phiHasIncomingInt(index_phi, 0, entry.name) or
        !phiHasIncoming(index_phi, next_index_name, loop.name)) return false;
    const lhs_gep = switch (then.instructions.items[1].kind) {
        .gep => |gep| gep,
        else => return false,
    };
    if (!byteCompareGep(lhs_gep, function.params.items[0].name, index_name)) return false;
    const lhs_load = switch (then.instructions.items[2].kind) {
        .load => |load| load,
        else => return false,
    };
    if (!lhs_load.ty.eql(.{ .int = 8 }) or lhs_load.attrs.isBarrier() or !isNamed(lhs_load.ptr, lhs_gep_name)) return false;
    if (!byteCompareZext(then.instructions.items[3], lhs_load_name)) return false;
    const rhs_gep = switch (then.instructions.items[4].kind) {
        .gep => |gep| gep,
        else => return false,
    };
    if (!byteCompareGep(rhs_gep, function.params.items[1].name, index_name)) return false;
    const rhs_load = switch (then.instructions.items[5].kind) {
        .load => |load| load,
        else => return false,
    };
    if (!rhs_load.ty.eql(.{ .int = 8 }) or rhs_load.attrs.isBarrier() or !isNamed(rhs_load.ptr, rhs_gep_name)) return false;
    if (!byteCompareZext(then.instructions.items[6], rhs_load_name)) return false;

    const diff = switch (then.instructions.items[7].kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (diff.op != .sub or !diff.ty.eql(.{ .int = 32 }) or
        !isNamed(diff.lhs, lhs_zext_name) or !isNamed(diff.rhs, rhs_zext_name)) return false;
    const value_cmp = switch (then.instructions.items[8].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (value_cmp.predicate != .eq or !value_cmp.operand_ty.eql(.{ .int = 32 }) or
        !isNamed(value_cmp.lhs, diff_name) or !isInt(value_cmp.rhs, 0)) return false;

    const then_br = switch (then.terminator orelse return false) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    return then_br.cond_ty.eql(.{ .int = 1 }) and isNamed(then_br.cond, value_cmp_name) and
        std.mem.eql(u8, then_br.then_target, loop.name) and
        std.mem.eql(u8, then_br.else_target, common_ret.name);
}

fn matchesGuardedByteMemsetLoop(function: ir.Function) bool {
    if (!function.ret_ty.eql(.ptr)) return false;
    if (function.params.items.len != 4 or function.params.items[0].ty != .ptr or
        !function.params.items[1].ty.eql(.{ .int = 8 }) or
        !function.params.items[2].ty.eql(.{ .int = 64 }) or
        !function.params.items[3].ty.eql(.{ .int = 64 })) return false;
    if (function.blocks.items.len != 8) return false;
    if (!allCallsAreMemsetGuardCalls(function)) return false;
    if (!allStoresWriteMemsetByte(function, function.params.items[1].name)) return false;

    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 1) return false;
    const guard_name = entry.instructions.items[0].result orelse return false;
    const guard = switch (entry.instructions.items[0].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (guard.predicate != .ult or !guard.operand_ty.eql(.{ .int = 64 }) or
        !isNamed(guard.lhs, function.params.items[3].name) or !isNamed(guard.rhs, function.params.items[2].name)) return false;
    const entry_br = switch (entry.terminator orelse return false) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!entry_br.cond_ty.eql(.{ .int = 1 }) or !isNamed(entry_br.cond, guard_name)) return false;

    const trap_block = blockByName(function, entry_br.then_target) orelse return false;
    const normal_block = blockByName(function, entry_br.else_target) orelse return false;
    if (!blockHasTrapThenUnreachable(trap_block)) return false;

    const len_zero_name = if (normal_block.instructions.items.len == 1)
        normal_block.instructions.items[0].result orelse return false
    else
        return false;
    const len_zero = switch (normal_block.instructions.items[0].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (len_zero.predicate != .eq or !len_zero.operand_ty.eql(.{ .int = 64 }) or
        !isNamed(len_zero.lhs, function.params.items[2].name) or !isInt(len_zero.rhs, 0)) return false;
    const normal_br = switch (normal_block.terminator orelse return false) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!normal_br.cond_ty.eql(.{ .int = 1 }) or !isNamed(normal_br.cond, len_zero_name)) return false;

    const ret_block = blockByName(function, normal_br.then_target) orelse return false;
    const ret = switch (ret_block.terminator orelse return false) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!ret.ty.eql(.ptr) or !isNamed(ret.value orelse return false, function.params.items[0].name)) return false;

    return functionHasPointerAdvancingStoreLoop(function, function.params.items[0].name, function.params.items[2].name);
}

fn matchesByteMemsetLoop(function: ir.Function) bool {
    if (!function.ret_ty.eql(.ptr)) return false;
    if (function.params.items.len != 3 or function.params.items[0].ty != .ptr or
        !function.params.items[1].ty.eql(.{ .int = 8 }) or
        !function.params.items[2].ty.eql(.{ .int = 64 })) return false;
    if (function.blocks.items.len != 6) return false;
    if (!functionHasNoCalls(function)) return false;
    if (!allStoresWriteMemsetByte(function, function.params.items[1].name)) return false;

    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 1) return false;
    const len_zero_name = entry.instructions.items[0].result orelse return false;
    const len_zero = switch (entry.instructions.items[0].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (len_zero.predicate != .eq or !len_zero.operand_ty.eql(.{ .int = 64 }) or
        !isNamed(len_zero.lhs, function.params.items[2].name) or !isInt(len_zero.rhs, 0)) return false;
    const entry_br = switch (entry.terminator orelse return false) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!entry_br.cond_ty.eql(.{ .int = 1 }) or !isNamed(entry_br.cond, len_zero_name)) return false;

    const ret_block = blockByName(function, entry_br.then_target) orelse return false;
    const ret = switch (ret_block.terminator orelse return false) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!ret.ty.eql(.ptr) or !isNamed(ret.value orelse return false, function.params.items[0].name)) return false;

    return functionHasPointerAdvancingStoreLoop(function, function.params.items[0].name, function.params.items[2].name);
}

fn allCallsAreMemsetGuardCalls(function: ir.Function) bool {
    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            const call = switch (instruction.kind) {
                .call => |call| call,
                else => continue,
            };
            if (!std.mem.eql(u8, call.callee, "llvm.assume") and !std.mem.eql(u8, call.callee, "llvm.trap")) return false;
        }
    }
    return true;
}

fn functionHasNoCalls(function: ir.Function) bool {
    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            switch (instruction.kind) {
                .call => return false,
                else => {},
            }
        }
    }
    return true;
}

fn allStoresWriteMemsetByte(function: ir.Function, byte_param_name: []const u8) bool {
    var store_count: usize = 0;
    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            const store = switch (instruction.kind) {
                .store => |store| store,
                else => continue,
            };
            if (!store.ty.eql(.{ .int = 8 }) or !isNamed(store.value, byte_param_name) or store.attrs.isBarrier()) return false;
            store_count += 1;
        }
    }
    return store_count >= 2;
}

fn blockHasTrapThenUnreachable(block: ir.BasicBlock) bool {
    var has_trap = false;
    for (block.instructions.items) |instruction| {
        if (instruction.removed) continue;
        const call = switch (instruction.kind) {
            .call => |call| call,
            else => continue,
        };
        if (std.mem.eql(u8, call.callee, "llvm.trap") and call.ret_ty == .void and call.args.items.len == 0) has_trap = true;
    }
    return has_trap and switch (block.terminator orelse return false) {
        .@"unreachable" => true,
        else => false,
    };
}

fn functionHasPointerAdvancingStoreLoop(function: ir.Function, ptr_param_name: []const u8, len_param_name: []const u8) bool {
    for (function.blocks.items) |block| {
        const terminator = block.terminator orelse continue;
        const condbr = switch (terminator) {
            .condbr => |condbr| condbr,
            else => continue,
        };
        if (!std.mem.eql(u8, condbr.else_target, block.name)) continue;
        if (!blockHasGepFromPointer(block, ptr_param_name) and !blockHasGepFromBlockPointerPhi(block)) continue;
        if (!blockHasI64EqToLen(block, len_param_name)) continue;
        return true;
    }
    return false;
}

fn blockHasGepFromPointer(block: ir.BasicBlock, ptr_param_name: []const u8) bool {
    for (block.instructions.items) |instruction| {
        const gep = switch (instruction.kind) {
            .gep => |gep| gep,
            else => continue,
        };
        if (gep.source_ty.eql(.{ .int = 8 }) and isNamed(gep.ptr, ptr_param_name)) return true;
    }
    return false;
}

fn blockHasGepFromBlockPointerPhi(block: ir.BasicBlock) bool {
    for (block.instructions.items) |instruction| {
        const gep = switch (instruction.kind) {
            .gep => |gep| gep,
            else => continue,
        };
        if (!gep.source_ty.eql(.{ .int = 8 })) continue;
        for (block.instructions.items) |candidate| {
            if (!std.mem.eql(u8, candidate.result orelse continue, switch (gep.ptr) {
                .named => |name| name,
                .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => continue,
            })) continue;
            const phi = switch (candidate.kind) {
                .phi => |phi| phi,
                else => continue,
            };
            if (phi.ty.eql(.ptr)) return true;
        }
    }
    return false;
}

fn blockHasI64EqToLen(block: ir.BasicBlock, len_param_name: []const u8) bool {
    for (block.instructions.items) |instruction| {
        const icmp = switch (instruction.kind) {
            .icmp => |icmp| icmp,
            else => continue,
        };
        if (icmp.predicate == .eq and icmp.operand_ty.eql(.{ .int = 64 }) and
            (isNamed(icmp.lhs, len_param_name) or isNamed(icmp.rhs, len_param_name) or isInt(icmp.lhs, 0) or isInt(icmp.rhs, 0))) return true;
    }
    return false;
}

fn byteCompareGep(gep: ir.GepInst, ptr_param_name: []const u8, index_name: []const u8) bool {
    if (!isByteSourceType(gep.source_ty) or !isNamed(gep.ptr, ptr_param_name)) return false;
    if (gep.indices.items.len != 1) return false;
    const index = gep.indices.items[0];
    return index.ty.eql(.{ .int = 64 }) and isNamed(index.value, index_name);
}

fn byteCompareZext(instruction: ir.Instruction, load_name: []const u8) bool {
    const cast = switch (instruction.kind) {
        .cast => |cast| cast,
        else => return false,
    };
    return cast.op == .zext and cast.from_ty.eql(.{ .int = 8 }) and
        cast.to_ty.eql(.{ .int = 32 }) and isNamed(cast.value, load_name);
}

fn findIcmpEqI8(block: ir.BasicBlock, name: []const u8) ?ir.IcmpInst {
    for (block.instructions.items) |instruction| {
        if (!std.mem.eql(u8, instruction.result orelse continue, name)) continue;
        const icmp = switch (instruction.kind) {
            .icmp => |icmp| icmp,
            else => return null,
        };
        if (icmp.predicate == .eq and icmp.operand_ty.eql(.{ .int = 8 })) return icmp;
        return null;
    }
    return null;
}
