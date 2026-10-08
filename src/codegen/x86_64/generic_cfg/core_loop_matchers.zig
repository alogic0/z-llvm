const shared = @import("core_shared.zig");
const diagnostics = @import("core_diagnostics.zig");
const call_lowering = @import("cabi_call_lowering.zig");
const std = shared.std;
const ir = shared.ir;

const isNamed = shared.isNamed;
const isInt = shared.isInt;
const isCalleeName = shared.isCalleeName;
const globalSymbolNameFromValue = shared.globalSymbolNameFromValue;
const phiHasIncoming = call_lowering.phiHasIncoming;
const phiHasIncomingInt = call_lowering.phiHasIncomingInt;

pub fn blockByName(function: ir.Function, name: []const u8) ?ir.BasicBlock {
    for (function.blocks.items) |block| {
        if (std.mem.eql(u8, block.name, name)) return block;
    }
    return null;
}

pub fn functionHasCall(function: ir.Function, callee: []const u8) bool {
    return diagnostics.functionHasCall(function, callee);
}

pub fn matchI64BinaryNamedImm(instruction: ir.Instruction, op: ir.BinaryOp, lhs_name: []const u8, rhs: i128) bool {
    const binary = switch (instruction.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    return binary.op == op and binary.ty.eql(.{ .int = 64 }) and isNamed(binary.lhs, lhs_name) and isInt(binary.rhs, rhs);
}

pub fn functionHasNoRemovedInstructions(function: ir.Function) bool {
    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) return false;
        }
    }
    return true;
}

pub fn matchesLimbAbsTwosComplementBody(function: ir.Function) bool {
    if (function.ret_ty != .void or function.params.items.len != 3) return false;
    if (!function.params.items[0].ty.eql(.ptr) or
        !function.params.items[1].ty.eql(.ptr) or
        !function.params.items[2].ty.eql(.{ .int = 16 })) return false;
    if (function.blocks.items.len != 5 or !functionHasNoRemovedInstructions(function)) return false;
    const out_name = function.params.items[0].name;
    const src_name = function.params.items[1].name;
    const bits_name = function.params.items[2].name;
    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 9) return false;

    const overflow_alloca_name = entry.instructions.items[0].result orelse return false;
    const carry_alloca_name = entry.instructions.items[1].result orelse return false;
    const byte_count_name = entry.instructions.items[2].result orelse return false;
    const limb_count16_name = entry.instructions.items[3].result orelse return false;
    const limb_count_name = entry.instructions.items[4].result orelse return false;
    const high_base_name = entry.instructions.items[5].result orelse return false;
    const high_ptr_name = entry.instructions.items[6].result orelse return false;
    const high_load_name = entry.instructions.items[7].result orelse return false;
    const sign_cmp_name = entry.instructions.items[8].result orelse return false;

    if (!matchI8Alloca(entry.instructions.items[0])) return false;
    if (!matchI8Alloca(entry.instructions.items[1])) return false;
    if (!matchIntByteSizeCall(entry.instructions.items[2], bits_name)) return false;
    if (!matchI16LshrImm(entry.instructions.items[3], byte_count_name, 3)) return false;
    if (!matchZext(entry.instructions.items[4], .{ .int = 16 }, limb_count16_name, .{ .int = 64 })) return false;
    if (!matchByteArrayGep(entry.instructions.items[5], src_name, limb_count_name)) return false;
    if (!matchI8GepImm(entry.instructions.items[6], high_base_name, -8)) return false;
    if (!matchPlainLoad(entry.instructions.items[7], .{ .int = 64 }, high_ptr_name)) return false;
    if (!matchIcmpNamedImm(entry.instructions.items[8], .sgt, .{ .int = 64 }, high_load_name, -1)) return false;

    const entry_br = switch (entry.terminator orelse return false) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!entry_br.cond_ty.eql(.{ .int = 1 }) or !isNamed(entry_br.cond, sign_cmp_name)) return false;
    const positive = blockByName(function, entry_br.then_target) orelse return false;
    const negative_entry = blockByName(function, entry_br.else_target) orelse return false;
    const common_ret = limbAbsRetBlock(function, positive.name, negative_entry.name) orelse return false;
    const loop = limbAbsLoopBlock(function, negative_entry.name) orelse return false;

    return matchLimbAbsPositiveBlock(positive, common_ret.name, out_name, src_name, limb_count_name) and
        matchLimbAbsNegativeEntry(negative_entry, common_ret.name, loop.name, carry_alloca_name, byte_count_name) and
        matchLimbAbsLoop(loop, negative_entry.name, common_ret.name, out_name, src_name, overflow_alloca_name, carry_alloca_name, limb_count_name);
}

pub fn limbAbsRetBlock(function: ir.Function, positive_name: []const u8, negative_entry_name: []const u8) ?ir.BasicBlock {
    for (function.blocks.items) |block| {
        if (std.mem.eql(u8, block.name, positive_name) or std.mem.eql(u8, block.name, negative_entry_name)) continue;
        if (block.instructions.items.len != 0) continue;
        const ret = switch (block.terminator orelse continue) {
            .ret => |ret| ret,
            else => continue,
        };
        if (ret.ty == .void and ret.value == null) return block;
    }
    return null;
}

pub fn limbAbsLoopBlock(function: ir.Function, negative_entry_name: []const u8) ?ir.BasicBlock {
    for (function.blocks.items) |block| {
        if (std.mem.eql(u8, block.name, negative_entry_name)) continue;
        if (block.instructions.items.len == 0) continue;
        const phi = switch (block.instructions.items[0].kind) {
            .phi => |phi| phi,
            else => continue,
        };
        if (phi.ty.eql(.{ .int = 64 })) return block;
    }
    return null;
}

pub fn matchLimbAbsPositiveBlock(block: ir.BasicBlock, ret_name: []const u8, out_name: []const u8, src_name: []const u8, limb_count_name: []const u8) bool {
    if (block.instructions.items.len != 2) return false;
    const byte_len_name = block.instructions.items[0].result orelse return false;
    if (!matchI64ShlImm(block.instructions.items[0], limb_count_name, 3)) return false;
    if (!matchMemcpyInlineCall(block.instructions.items[1], out_name, src_name, byte_len_name)) return false;
    const br = switch (block.terminator orelse return false) {
        .br => |br| br,
        else => return false,
    };
    return std.mem.eql(u8, br.target, ret_name);
}

pub fn matchLimbAbsNegativeEntry(block: ir.BasicBlock, ret_name: []const u8, loop_name: []const u8, carry_alloca_name: []const u8, byte_count_name: []const u8) bool {
    if (block.instructions.items.len != 2) return false;
    const zero_name = block.instructions.items[1].result orelse return false;
    if (!matchStoreInt(block.instructions.items[0], .{ .int = 1 }, 1, carry_alloca_name)) return false;
    if (!matchIcmpNamedImm(block.instructions.items[1], .eq, .{ .int = 16 }, byte_count_name, 0)) return false;
    const condbr = switch (block.terminator orelse return false) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    return condbr.cond_ty.eql(.{ .int = 1 }) and isNamed(condbr.cond, zero_name) and
        std.mem.eql(u8, condbr.then_target, ret_name) and std.mem.eql(u8, condbr.else_target, loop_name);
}

pub fn matchLimbAbsLoop(block: ir.BasicBlock, negative_entry_name: []const u8, ret_name: []const u8, out_name: []const u8, src_name: []const u8, overflow_alloca_name: []const u8, carry_alloca_name: []const u8, limb_count_name: []const u8) bool {
    if (block.instructions.items.len != 18) return false;
    const index_name = block.instructions.items[0].result orelse return false;
    const src_gep_name = block.instructions.items[1].result orelse return false;
    const src_load_name = block.instructions.items[2].result orelse return false;
    const inverted_name = block.instructions.items[3].result orelse return false;
    const carry_load_name = block.instructions.items[4].result orelse return false;
    const carry_bit_name = block.instructions.items[5].result orelse return false;
    const carry64_name = block.instructions.items[6].result orelse return false;
    const add_name = block.instructions.items[7].result orelse return false;
    const result_name = block.instructions.items[8].result orelse return false;
    const carry_name = block.instructions.items[9].result orelse return false;
    const carry_reload_name = block.instructions.items[11].result orelse return false;
    const out_gep_name = block.instructions.items[12].result orelse return false;
    const carry_trunc_name = block.instructions.items[14].result orelse return false;
    const next_index_name = block.instructions.items[16].result orelse return false;
    const exit_cmp_name = block.instructions.items[17].result orelse return false;

    const phi = switch (block.instructions.items[0].kind) {
        .phi => |phi| phi,
        else => return false,
    };
    if (!phi.ty.eql(.{ .int = 64 }) or !phiHasIncomingInt(phi, 0, negative_entry_name) or
        !phiHasIncoming(phi, next_index_name, block.name)) return false;
    if (!matchByteArrayGep(block.instructions.items[1], src_name, index_name)) return false;
    if (!matchPlainLoad(block.instructions.items[2], .{ .int = 64 }, src_gep_name)) return false;
    if (!matchI64XorImm(block.instructions.items[3], src_load_name, -1)) return false;
    if (!matchPlainLoad(block.instructions.items[4], .{ .int = 8 }, carry_alloca_name)) return false;
    if (!matchI8AndImm(block.instructions.items[5], carry_load_name, 1)) return false;
    if (!matchZext(block.instructions.items[6], .{ .int = 8 }, carry_bit_name, .{ .int = 64 })) return false;
    if (!matchUaddOverflowI64(block.instructions.items[7], inverted_name, carry64_name)) return false;
    if (!matchExtractValue(block.instructions.items[8], add_name, "0", .{ .int = 64 })) return false;
    if (!matchExtractValue(block.instructions.items[9], add_name, "1", .{ .int = 1 })) return false;
    if (!matchStoreNamed(block.instructions.items[10], .{ .int = 1 }, carry_name, overflow_alloca_name)) return false;
    if (!matchPlainLoad(block.instructions.items[11], .{ .int = 8 }, overflow_alloca_name)) return false;
    if (!matchByteArrayGep(block.instructions.items[12], out_name, index_name)) return false;
    if (!matchStoreNamed(block.instructions.items[13], .{ .int = 64 }, result_name, out_gep_name)) return false;
    if (!matchTrunc(block.instructions.items[14], .{ .int = 8 }, carry_reload_name, .{ .int = 1 })) return false;
    if (!matchStoreNamed(block.instructions.items[15], .{ .int = 1 }, carry_trunc_name, carry_alloca_name)) return false;
    if (!matchI64AddImm(block.instructions.items[16], index_name, 1)) return false;
    if (!matchIcmpNamedNamed(block.instructions.items[17], .eq, .{ .int = 64 }, next_index_name, limb_count_name)) return false;

    const condbr = switch (block.terminator orelse return false) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    return condbr.cond_ty.eql(.{ .int = 1 }) and isNamed(condbr.cond, exit_cmp_name) and
        std.mem.eql(u8, condbr.then_target, ret_name) and std.mem.eql(u8, condbr.else_target, block.name);
}

pub fn matchI8Alloca(instruction: ir.Instruction) bool {
    const alloca = switch (instruction.kind) {
        .alloca => |alloca| alloca,
        else => return false,
    };
    return alloca.allocated_ty.eql(.{ .int = 8 }) and alloca.allocated_ty_addrspace == null;
}

pub fn matchIntByteSizeCall(instruction: ir.Instruction, bits_name: []const u8) bool {
    const call = switch (instruction.kind) {
        .call => |call| call,
        else => return false,
    };
    return call.callee_value == null and call.inline_asm == null and call.calling_conv != null and
        std.mem.eql(u8, call.calling_conv.?, "fastcc") and call.ret_ty.eql(.{ .int = 16 }) and
        isCalleeName(call.callee, "zig.target.intByteSize") and call.args.items.len == 1 and
        call.args.items[0].ty.eql(.{ .int = 16 }) and isNamed(call.args.items[0].value, bits_name);
}

pub fn matchI16LshrImm(instruction: ir.Instruction, lhs_name: []const u8, rhs: i128) bool {
    const binary = switch (instruction.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    return binary.op == .lshr and binary.flags.exact and !binary.flags.nsw and !binary.flags.nuw and
        !binary.flags.disjoint and binary.ty.eql(.{ .int = 16 }) and isNamed(binary.lhs, lhs_name) and
        isInt(binary.rhs, rhs);
}

pub fn matchI64ShlImm(instruction: ir.Instruction, lhs_name: []const u8, rhs: i128) bool {
    const binary = switch (instruction.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    return binary.op == .shl and binary.ty.eql(.{ .int = 64 }) and isNamed(binary.lhs, lhs_name) and
        isInt(binary.rhs, rhs);
}

pub fn matchI64AddImm(instruction: ir.Instruction, lhs_name: []const u8, rhs: i128) bool {
    const binary = switch (instruction.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    return binary.op == .add and binary.ty.eql(.{ .int = 64 }) and isNamed(binary.lhs, lhs_name) and
        isInt(binary.rhs, rhs);
}

pub fn matchI64XorImm(instruction: ir.Instruction, lhs_name: []const u8, rhs: i128) bool {
    const binary = switch (instruction.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    return binary.op == .xor and binary.ty.eql(.{ .int = 64 }) and isNamed(binary.lhs, lhs_name) and
        isInt(binary.rhs, rhs);
}

pub fn matchI8AndImm(instruction: ir.Instruction, lhs_name: []const u8, rhs: i128) bool {
    const binary = switch (instruction.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    return binary.op == .@"and" and binary.ty.eql(.{ .int = 8 }) and isNamed(binary.lhs, lhs_name) and
        isInt(binary.rhs, rhs);
}

pub fn matchZext(instruction: ir.Instruction, from_ty: ir.Type, value_name: []const u8, to_ty: ir.Type) bool {
    const cast = switch (instruction.kind) {
        .cast => |cast| cast,
        else => return false,
    };
    return cast.op == .zext and cast.from_ty.eql(from_ty) and isNamed(cast.value, value_name) and
        cast.to_ty.eql(to_ty);
}

pub fn matchTrunc(instruction: ir.Instruction, from_ty: ir.Type, value_name: []const u8, to_ty: ir.Type) bool {
    const cast = switch (instruction.kind) {
        .cast => |cast| cast,
        else => return false,
    };
    return cast.op == .trunc and cast.from_ty.eql(from_ty) and isNamed(cast.value, value_name) and
        cast.to_ty.eql(to_ty);
}

pub fn matchByteArrayGep(instruction: ir.Instruction, ptr_name: []const u8, index_name: []const u8) bool {
    const gep = switch (instruction.kind) {
        .gep => |gep| gep,
        else => return false,
    };
    if (!gep.source_ty.eql(.{ .aggregate = "[8 x i8]" }) or !isNamed(gep.ptr, ptr_name)) return false;
    if (gep.indices.items.len != 1) return false;
    const index = gep.indices.items[0];
    return index.ty.eql(.{ .int = 64 }) and isNamed(index.value, index_name);
}

pub fn matchI8GepImm(instruction: ir.Instruction, ptr_name: []const u8, index_value: i128) bool {
    const gep = switch (instruction.kind) {
        .gep => |gep| gep,
        else => return false,
    };
    if (!gep.source_ty.eql(.{ .int = 8 }) or !isNamed(gep.ptr, ptr_name)) return false;
    if (gep.indices.items.len != 1) return false;
    const index = gep.indices.items[0];
    return index.ty.eql(.{ .int = 64 }) and isInt(index.value, index_value);
}

pub fn matchPlainLoad(instruction: ir.Instruction, ty: ir.Type, ptr_name: []const u8) bool {
    const load = switch (instruction.kind) {
        .load => |load| load,
        else => return false,
    };
    return load.ty.eql(ty) and !load.attrs.isBarrier() and isNamed(load.ptr, ptr_name);
}

pub fn matchStoreInt(instruction: ir.Instruction, ty: ir.Type, value: i128, ptr_name: []const u8) bool {
    const store = switch (instruction.kind) {
        .store => |store| store,
        else => return false,
    };
    return store.ty.eql(ty) and !store.attrs.isBarrier() and isInt(store.value, value) and
        isNamed(store.ptr, ptr_name);
}

pub fn matchStoreNamed(instruction: ir.Instruction, ty: ir.Type, value_name: []const u8, ptr_name: []const u8) bool {
    const store = switch (instruction.kind) {
        .store => |store| store,
        else => return false,
    };
    return store.ty.eql(ty) and !store.attrs.isBarrier() and isNamed(store.value, value_name) and
        isNamed(store.ptr, ptr_name);
}

pub fn matchIcmpNamedImm(instruction: ir.Instruction, predicate: ir.IcmpPredicate, ty: ir.Type, lhs_name: []const u8, rhs: i128) bool {
    const icmp = switch (instruction.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    return icmp.predicate == predicate and icmp.operand_ty.eql(ty) and isNamed(icmp.lhs, lhs_name) and
        isInt(icmp.rhs, rhs);
}

pub fn matchIcmpNamedNamed(instruction: ir.Instruction, predicate: ir.IcmpPredicate, ty: ir.Type, lhs_name: []const u8, rhs_name: []const u8) bool {
    const icmp = switch (instruction.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    return icmp.predicate == predicate and icmp.operand_ty.eql(ty) and isNamed(icmp.lhs, lhs_name) and
        isNamed(icmp.rhs, rhs_name);
}

pub fn matchMemcpyInlineCall(instruction: ir.Instruction, dst_name: []const u8, src_name: []const u8, len_name: []const u8) bool {
    const call = switch (instruction.kind) {
        .call => |call| call,
        else => return false,
    };
    if (call.callee_value != null or call.inline_asm != null or call.ret_ty != .void or call.args.items.len != 4) return false;
    if (!isCalleeName(call.callee, "llvm.memcpy.inline.p0.p0.i64")) return false;
    return call.args.items[0].ty.eql(.ptr) and isNamed(call.args.items[0].value, dst_name) and
        call.args.items[1].ty.eql(.ptr) and isNamed(call.args.items[1].value, src_name) and
        call.args.items[2].ty.eql(.{ .int = 64 }) and isNamed(call.args.items[2].value, len_name) and
        call.args.items[3].ty.eql(.{ .int = 1 }) and isInt(call.args.items[3].value, 0);
}

pub fn matchUaddOverflowI64(instruction: ir.Instruction, lhs_name: []const u8, rhs_name: []const u8) bool {
    const call = switch (instruction.kind) {
        .call => |call| call,
        else => return false,
    };
    if (call.callee_value != null or call.inline_asm != null or !call.ret_ty.eql(.{ .aggregate = "{ i64, i1 }" }) or
        call.args.items.len != 2 or !isCalleeName(call.callee, "llvm.uadd.with.overflow.i64")) return false;
    return call.args.items[0].ty.eql(.{ .int = 64 }) and isNamed(call.args.items[0].value, lhs_name) and
        call.args.items[1].ty.eql(.{ .int = 64 }) and isNamed(call.args.items[1].value, rhs_name);
}

pub fn scalarAtomicCompareExchangeBits(ty: ir.Type) ?u16 {
    const bits = switch (ty) {
        .int => |bits| bits,
        else => return null,
    };
    return switch (bits) {
        8, 16, 32, 64, 128 => @intCast(bits),
        else => null,
    };
}

pub fn matchExtractValue(instruction: ir.Instruction, aggregate_name: []const u8, indices: []const u8, result_ty: ir.Type) bool {
    const extract = switch (instruction.kind) {
        .extractvalue => |extractvalue| extractvalue,
        else => return false,
    };
    return extract.result_ty.eql(result_ty) and
        isNamed(extract.aggregate, aggregate_name) and
        std.mem.eql(u8, extract.indices, indices);
}

pub fn isByteSourceType(ty: ir.Type) bool {
    return ty.eql(.{ .int = 8 }) or ty.eql(.{ .aggregate = "[1 x i8]" });
}

pub fn matchByteGep(instruction: ir.Instruction, ptr_name: []const u8, index_name: []const u8) bool {
    const gep = switch (instruction.kind) {
        .gep => |gep| gep,
        else => return false,
    };
    if (!isByteSourceType(gep.source_ty) or !isNamed(gep.ptr, ptr_name)) return false;
    if (gep.indices.items.len != 1) return false;
    const index = gep.indices.items[0];
    return index.ty.eql(.{ .int = 64 }) and isNamed(index.value, index_name);
}

pub fn matchPlainI8Load(instruction: ir.Instruction, ptr_name: []const u8) bool {
    const load = switch (instruction.kind) {
        .load => |load| load,
        else => return false,
    };
    return load.ty.eql(.{ .int = 8 }) and !load.attrs.isBarrier() and isNamed(load.ptr, ptr_name);
}

pub fn matchSpinlockAcquireLoop(loop: ir.BasicBlock, lock_ptr_name: []const u8, acquired_target: []const u8) bool {
    if (loop.instructions.items.len != 2) return false;
    const old_lock_name = loop.instructions.items[0].result orelse return false;
    const atomic = switch (loop.instructions.items[0].kind) {
        .atomicrmw => |atomicrmw| atomicrmw,
        else => return false,
    };
    if (!std.mem.eql(u8, atomic.op, "xchg") or !atomic.ty.eql(.{ .int = 64 }) or
        !isNamed(atomic.ptr, lock_ptr_name) or !isInt(atomic.value, 1) or
        !std.mem.eql(u8, atomic.ordering, "acquire") or atomic.syncscope != null or
        atomic.is_volatile or atomic.@"align" != 8) return false;

    const acquired_name = loop.instructions.items[1].result orelse return false;
    const acquired = switch (loop.instructions.items[1].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (acquired.predicate != .eq or !acquired.operand_ty.eql(.{ .int = 64 }) or
        !isNamed(acquired.lhs, old_lock_name) or !isInt(acquired.rhs, 0)) return false;
    const loop_br = switch (loop.terminator orelse return false) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    return loop_br.cond_ty.eql(.{ .int = 1 }) and isNamed(loop_br.cond, acquired_name) and
        std.mem.eql(u8, loop_br.then_target, acquired_target) and
        std.mem.eql(u8, loop_br.else_target, loop.name);
}

pub fn matchSpinlockGep(instruction: ir.Instruction, index_name: []const u8) ![]const u8 {
    const gep = switch (instruction.kind) {
        .gep => |gep| gep,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (gep.indices.items.len != 1) return error.UnsupportedCodegenInstruction;
    const index = gep.indices.items[0];
    if (!index.ty.eql(.{ .int = 64 }) or !isNamed(index.value, index_name)) return error.UnsupportedCodegenInstruction;
    return globalSymbolNameFromValue(gep.ptr) catch return error.UnsupportedCodegenValue;
}

pub fn isSpinlockedMemcpyCall(call: ir.CallInst, dst_name: []const u8, src_name: []const u8, len_name: []const u8) bool {
    if (call.callee_value != null or call.inline_asm != null or call.ret_ty != .void or call.args.items.len != 4) return false;
    if (!isCalleeName(call.callee, "llvm.memcpy.inline.p0.p0.i64")) return false;
    return call.args.items[0].ty.eql(.ptr) and isNamed(call.args.items[0].value, dst_name) and
        call.args.items[1].ty.eql(.ptr) and isNamed(call.args.items[1].value, src_name) and
        call.args.items[2].ty.eql(.{ .int = 64 }) and isNamed(call.args.items[2].value, len_name) and
        call.args.items[3].ty.eql(.{ .int = 1 }) and isInt(call.args.items[3].value, 0);
}
