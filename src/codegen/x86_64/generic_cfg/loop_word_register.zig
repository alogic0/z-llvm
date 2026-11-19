//! Keep one private i32 object in an unused caller-saved register for a leaf
//! loop. The composed selector has already chosen and compacted this frame.
const std = @import("std");
const ir = @import("../../../ir.zig");
const Instruction = @import("../machine.zig").Instruction;
const ArgReg = @import("../types.zig").ArgReg;
const cfg = @import("composed_selector_cfg.zig");
const helpers = @import("composed_helpers.zig");

const word = ir.Type{ .int = 32 };
const scratch = ArgReg.r9;

fn latchIndex(function: ir.Function) ?usize {
    const blocks = function.blocks.items;
    if (blocks.len != 4 or !function.ret_ty.eql(word)) return null;
    // An unreferenced R9 is available only under the ordinary caller-save
    // contract. Attribute groups can change that contract as well.
    if (function.is_varargs or function.ret_attrs != null or function.attrs != null) return null;
    if (function.calling_conv) |cc| if (!std.mem.eql(u8, cc, "ccc")) return null;
    for (function.params.items) |param| {
        if (!param.ty.eql(word) or param.attrs != null or param.abi_incoming_address != null or
            param.abi_x87_memory or param.abi_split_integer) return null;
    }
    const entry = blocks[0].terminator orelse return null;
    if (entry != .br) return null;
    const header = function.blockIndex(entry.br.target) orelse return null;
    if (header == 0) return null;
    const branch = blocks[header].terminator orelse return null;
    if (branch != .condbr) return null;
    const a = function.blockIndex(branch.condbr.then_target) orelse return null;
    const b = function.blockIndex(branch.condbr.else_target) orelse return null;
    if (a == b or a == 0 or b == 0 or a == header or b == header) return null;
    const a_end = blocks[a].terminator orelse return null;
    const b_end = blocks[b].terminator orelse return null;
    if (a_end == .br and b_end == .ret and std.mem.eql(u8, a_end.br.target, blocks[header].name)) return a;
    if (b_end == .br and a_end == .ret and std.mem.eql(u8, b_end.br.target, blocks[header].name)) return b;
    return null;
}

fn hasPrivateRecurrence(function: ir.Function, latch: usize) bool {
    var slot: ?ir.Value = null;
    var initialized = false;
    var latch_read = false;
    var latch_write = false;
    for (function.blocks.items, 0..) |block, index| {
        for (block.instructions.items) |inst| {
            if (inst.removed) continue;
            switch (inst.kind) {
                .alloca => |alloca| {
                    if (index != 0 or slot != null or !alloca.isSingleObject() or alloca.allocated_ty_addrspace != null) return false;
                    if (!alloca.allocated_ty.eql(word) and helpers.parseI32ArrayType(alloca.allocated_ty) != 1) return false;
                    if (alloca.attrs) |attrs| if (!cfg.isLiteralAlignment(attrs)) return false;
                    slot = .{ .named = inst.result orelse return false };
                },
                .load => |load| {
                    if (!initialized or !load.ptr.eql(slot orelse return false) or !load.ty.eql(word) or
                        load.ptr_addrspace != null or load.ty_addrspace != null or load.attrs.isBarrier()) return false;
                    if (index == latch) latch_read = true;
                },
                .store => |store| {
                    if (!store.ptr.eql(slot orelse return false) or !store.ty.eql(word) or
                        store.ptr_addrspace != null or store.ty_addrspace != null or store.attrs.isBarrier()) return false;
                    if (index == 0) initialized = true;
                    if (index == latch) latch_write = true;
                },
                // These instructions only consume integers. All other uses,
                // including calls, casts and derived addresses, stop promotion.
                .binary => |binary| if (!binary.ty.eql(word)) return false,
                .icmp => |cmp| if (!cmp.operand_ty.eql(word)) return false,
                .phi => |phi| if (!phi.ty.eql(word)) return false,
                else => return false,
            }
        }
    }
    return initialized and latch_read and latch_write;
}

fn frameWord(instructions: []const Instruction) ?u32 {
    for (instructions) |inst| switch (inst) {
        .store_eax_stack_disp8 => |disp| return disp,
        .store_eax_stack_disp32 => |disp| return disp,
        .label, .je, .jne, .jmp, .load_stack_disp8_eax, .load_stack_disp32_eax => return null,
        else => {},
    };
    return null;
}

fn safeEffect(inst: Instruction, disp: u32) bool {
    // Each admitted stack access is 32 bits. Aligned spill homes alias the
    // promoted word exactly or are disjoint. Unknown and partial-width
    // effects, implicit clobbers, escaped addresses and stack bias stop here.
    return switch (inst) {
        .load_stack_disp8_eax, .store_eax_stack_disp8 => |offset| offset == disp,
        .load_stack_disp32_eax, .store_eax_stack_disp32 => |offset| offset == disp,
        .reload_rsp_eax, .spill_eax_rsp => |frame| frame.slot != disp / 4,
        .spill_arg_rsp => |spill| spill.reg != scratch and spill.frame_index.slot != disp / 4,
        .reload_arg_rsp => |load| load.reg != scratch and load.frame_index.slot != disp / 4,
        .mov_arg_eax, .mov_eax_to_arg, .cmp_ecx_arg32, .cmp_r8d_arg32 => |reg| reg != scratch,
        .mov_arg_arg => |move| move.src != scratch and move.dst != scratch,
        .binary_arg_eax => |op| op.reg != scratch,
        .label, .mov_imm_eax, .mov_imm_rcx, .add_eax_imm32, .and_eax_imm32, .or_eax_imm32, .xor_eax_imm32, .imul_eax_imm32, .cmp_ecx_imm32, .cmp_eax_imm32, .je, .jne, .jmp => true,
        else => false,
    };
}

pub fn promote(function: ir.Function, code: []Instruction) void {
    const latch = latchIndex(function) orelse return;
    if (!hasPrivateRecurrence(function, latch) or code.len < 4 or code[code.len - 1] != .ret) return;
    const frame: u32 = switch (code[0]) {
        .sub_rsp_imm8 => |bytes| bytes,
        .sub_rsp_imm32 => |bytes| bytes,
        else => return,
    };
    const restored: u32 = switch (code[code.len - 2]) {
        .add_rsp_imm8 => |bytes| bytes,
        .add_rsp_imm32 => |bytes| bytes,
        else => return,
    };
    const body = code[1 .. code.len - 2];
    const disp = frameWord(body) orelse return;
    if (frame != restored or disp % 4 != 0 or @as(u64, disp) + 4 > frame) return;
    for (body) |inst| if (!safeEffect(inst, disp)) return;

    // Replace every access, including initialization and the zero-trip exit.
    // Both register moves preserve flags and the existing instruction order.
    for (body) |*inst| switch (inst.*) {
        .load_stack_disp8_eax, .load_stack_disp32_eax => inst.* = .{ .mov_arg_eax = scratch },
        .store_eax_stack_disp8, .store_eax_stack_disp32 => inst.* = .{ .mov_eax_to_arg = scratch },
        else => {},
    };
}
