const shared = @import("core_shared.zig");
const cabi_abi_helpers = @import("cabi_abi_helpers.zig");
const cabi_tls_global_lowering = @import("cabi_tls_global_lowering.zig");
const sysv_abi = @import("../sysv_abi.zig");

const std = shared.std;
const ir = shared.ir;
const MachineBinaryOp = shared.MachineBinaryOp;
const callIsFastcc = shared.callIsFastcc;
const globalSymbolName = shared.globalSymbolName;
const isCalleeName = shared.isCalleeName;
const isInt = shared.isInt;
const isNamed = shared.isNamed;
const validateDefaultCallConv = shared.validateDefaultCallConv;

const blockIndex = cabi_abi_helpers.blockIndex;
const paramRegOrNull = cabi_abi_helpers.paramRegOrNull;
const knownLocalExecTlsSymbol = cabi_tls_global_lowering.knownLocalExecTlsSymbol;
const tlsSymbolFromFunctionAttrs = cabi_tls_global_lowering.tlsSymbolFromFunctionAttrs;

fn findInstruction(block: ir.BasicBlock, result_name: []const u8) ?ir.Instruction {
    for (block.instructions.items) |instruction| {
        if (instruction.removed) continue;
        const result = instruction.result orelse continue;
        if (std.mem.eql(u8, result, result_name)) return instruction;
    }
    return null;
}

fn machineBinaryOp(op: ir.BinaryOp) ?MachineBinaryOp {
    return switch (op) {
        .add => .add,
        .sub => .sub,
        .@"and" => .@"and",
        .@"or" => .@"or",
        .xor => .xor,
        .fadd, .fsub, .fmul, .fdiv, .frem, .mul, .shl, .lshr, .ashr, .udiv, .sdiv, .urem, .srem => null,
    };
}

pub const GenericCfgAddress = union(enum) {
    param: []const u8,
    global: []const u8,
    tls: []const u8,
};

pub fn genericCfgI32Address(function: ir.Function, ptr: ir.Value) ?GenericCfgAddress {
    const name = switch (ptr) {
        .named => |name| name,
        else => return null,
    };
    if (genericCfgSupportsPointerParam(function, name)) return .{ .param = name };
    if (name.len == 0 or name[0] != '@') return null;
    const symbol = globalSymbolName(name) catch return null;
    if (tlsSymbolFromFunctionAttrs(function)) |tls_symbol| {
        if (std.mem.eql(u8, tls_symbol, symbol)) return .{ .tls = symbol };
    }
    if (knownLocalExecTlsSymbol(symbol)) return .{ .tls = symbol };
    return .{ .global = symbol };
}

pub fn genericCfgSupportsSingleBlockScalar(function: ir.Function) bool {
    if (!function.ret_ty.eql(.{ .int = 32 })) return false;
    if (function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    for (block.instructions.items) |instruction| {
        if (instruction.removed) return false;
        if (!genericCfgSupportsSingleBlockScalarInstruction(function, block, instruction)) return false;
    }
    const ret = switch (block.terminator orelse return false) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!ret.ty.eql(.{ .int = 32 })) return false;
    return genericCfgSupportsSingleBlockScalarReturnValue(function, block, ret.value orelse return false);
}

pub fn genericCfgSupportsSingleBlockScalarInstruction(function: ir.Function, block: ir.BasicBlock, instruction: ir.Instruction) bool {
    return switch (instruction.kind) {
        .binary => |binary| genericCfgSupportsSingleBlockBinary(function, block, binary),
        .icmp => |icmp| genericCfgSupportsSingleBlockIcmp(function, icmp),
        .select => |select| genericCfgSupportsSingleBlockSelect(function, block, select),
        .load => |load| genericCfgSupportsSingleBlockLoad(function, load),
        .store => |store| genericCfgSupportsSingleBlockStore(function, block, store),
        .call => |call| genericCfgSupportsSingleBlockCall(function, block, instruction.result, call),
        .phi, .fcmp, .cast, .freeze, .alloca, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue, .gep => false,
    };
}

pub fn genericCfgSupportsSingleBlockBinary(function: ir.Function, block: ir.BasicBlock, binary: ir.BinaryInst) bool {
    if (!binary.ty.eql(.{ .int = 32 })) return false;
    if (machineBinaryOp(binary.op) == null) return false;
    if (!genericCfgSupportsSingleBlockI32Value(function, block, binary.lhs)) return false;
    switch (binary.rhs) {
        .named => |rhs_name| {
            if (genericCfgSupportsI32Param(function, rhs_name)) return true;
            const rhs_instruction = findInstruction(block, rhs_name) orelse return false;
            switch (rhs_instruction.kind) {
                .load => |load| {
                    if (binary.op != .add or !load.ty.eql(.{ .int = 32 }) or load.attrs.isBarrier()) return false;
                    return switch (genericCfgI32Address(function, load.ptr) orelse return false) {
                        .tls => true,
                        .global => genericCfgSupportsSingleBlockI32Value(function, block, binary.lhs),
                        .param => false,
                    };
                },
                .binary, .select, .call => {
                    return binary.op == .add and
                        genericCfgSupportsSingleBlockI32Value(function, block, binary.lhs) and
                        genericCfgSupportsSingleBlockI32Value(function, block, binary.rhs);
                },
                else => return false,
            }
        },
        else => return genericCfgSupportsSingleBlockI32Value(function, block, binary.rhs),
    }
}

pub fn genericCfgSupportsLowerableI32OperandPair(function: ir.Function, lhs: ir.Value, rhs: ir.Value) bool {
    switch (lhs) {
        .int => return switch (rhs) {
            .int => true,
            .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
        },
        .named => |name| {
            if (!genericCfgSupportsI32Param(function, name)) return false;
            return switch (rhs) {
                .int => true,
                .named => |rhs_name| genericCfgSupportsI32Param(function, rhs_name),
                .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
            };
        },
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    }
}

pub fn genericCfgSupportsSingleBlockIcmp(function: ir.Function, icmp: ir.IcmpInst) bool {
    switch (icmp.predicate) {
        .eq, .ne, .slt => {},
        .ugt, .uge, .ult, .ule, .sgt, .sge, .sle => return false,
    }
    if (icmp.operand_ty.eql(.{ .int = 8 })) {
        if (icmp.predicate == .slt) return false;
        return genericCfgSupportsI8ParamOrConst(function, icmp.lhs) and
            genericCfgSupportsI8ParamOrConst(function, icmp.rhs);
    }
    if (icmp.operand_ty.eql(.{ .int = 16 })) {
        return genericCfgSupportsI16ParamOrConst(function, icmp.lhs) and
            genericCfgSupportsI16ParamOrConst(function, icmp.rhs);
    }
    if (!icmp.operand_ty.eql(.{ .int = 32 })) return false;
    return genericCfgSupportsI32ParamOrConst(function, icmp.lhs) and
        genericCfgSupportsI32ParamOrConst(function, icmp.rhs);
}

pub fn genericCfgSupportsBranchIcmp(function: ir.Function, icmp: ir.IcmpInst) bool {
    if (genericCfgSupportsSingleBlockIcmp(function, icmp)) return true;
    return genericCfgSupportsPointerNullIcmp(function, icmp);
}

pub fn genericCfgSupportsPointerNullIcmp(function: ir.Function, icmp: ir.IcmpInst) bool {
    if (!icmp.operand_ty.eql(.ptr)) return false;
    switch (icmp.predicate) {
        .eq, .ne => {},
        .ugt, .uge, .ult, .ule, .sgt, .sge, .slt, .sle => return false,
    }
    if (icmp.lhs == .null_value) {
        return switch (icmp.rhs) {
            .named => |name| genericCfgSupportsPointerParam(function, name),
            else => false,
        };
    }
    if (icmp.rhs == .null_value) {
        return switch (icmp.lhs) {
            .named => |name| genericCfgSupportsPointerParam(function, name),
            else => false,
        };
    }
    return false;
}

pub fn genericCfgSupportsSingleBlockSelect(function: ir.Function, block: ir.BasicBlock, select: ir.SelectInst) bool {
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    const cond_name = switch (select.cond) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (genericCfgSupportsI1Param(function, cond_name)) {
        return genericCfgSupportsSingleBlockI32Value(function, block, select.true_value) and
            genericCfgSupportsSingleBlockI32Value(function, block, select.false_value);
    }
    const cond_inst = findInstruction(block, cond_name) orelse return false;
    const cond = switch (cond_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (genericCfgSupportsSminSelect(function, select, cond) or genericCfgSupportsSmaxSelect(function, select, cond)) return true;
    if (!genericCfgSupportsSingleBlockIcmp(function, cond)) return false;
    return genericCfgSupportsSingleBlockI32Value(function, block, select.true_value) and
        genericCfgSupportsSingleBlockI32Value(function, block, select.false_value);
}

pub fn genericCfgSupportsSminSelect(function: ir.Function, select: ir.SelectInst, icmp: ir.IcmpInst) bool {
    if (icmp.predicate != .slt or !icmp.operand_ty.eql(.{ .int = 32 })) return false;
    const lhs = switch (icmp.lhs) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    const rhs = switch (icmp.rhs) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!isNamed(select.true_value, lhs) or !isNamed(select.false_value, rhs)) return false;
    return (paramRegOrNull(function, lhs, .{ .int = 32 }) catch null) != null and
        (paramRegOrNull(function, rhs, .{ .int = 32 }) catch null) != null;
}

pub fn genericCfgSupportsSmaxSelect(function: ir.Function, select: ir.SelectInst, icmp: ir.IcmpInst) bool {
    if (icmp.predicate != .slt or !icmp.operand_ty.eql(.{ .int = 32 })) return false;
    const lhs = switch (icmp.lhs) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    const rhs = switch (icmp.rhs) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!isNamed(select.true_value, rhs) or !isNamed(select.false_value, lhs)) return false;
    return (paramRegOrNull(function, lhs, .{ .int = 32 }) catch null) != null and
        (paramRegOrNull(function, rhs, .{ .int = 32 }) catch null) != null;
}

pub fn genericCfgSupportsSingleBlockScalarReturnValue(function: ir.Function, block: ir.BasicBlock, value: ir.Value) bool {
    return genericCfgSupportsSingleBlockI32Value(function, block, value);
}

pub fn genericCfgSupportsSingleBlockI32Value(function: ir.Function, maybe_block: ?ir.BasicBlock, value: ir.Value) bool {
    return switch (value) {
        .int => true,
        .named => |name| {
            if (genericCfgSupportsI32Param(function, name)) return true;
            const block = maybe_block orelse return false;
            const instruction = findInstruction(block, name) orelse return false;
            return switch (instruction.kind) {
                .binary => |binary| genericCfgSupportsSingleBlockBinary(function, block, binary),
                .select => |select| genericCfgSupportsSingleBlockSelect(function, block, select),
                .load => |load| genericCfgSupportsSingleBlockLoad(function, load),
                .call => |call| genericCfgSupportsSingleBlockCall(function, block, instruction.result, call),
                .icmp, .phi, .fcmp, .cast, .freeze, .alloca, .store, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue, .gep => false,
            };
        },
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
    };
}

pub fn genericCfgSupportsSingleBlockLoad(function: ir.Function, load: ir.LoadInst) bool {
    if (!load.ty.eql(.{ .int = 32 }) or load.attrs.isBarrier()) return false;
    return genericCfgI32Address(function, load.ptr) != null;
}

pub fn genericCfgSupportsSingleBlockStore(function: ir.Function, block: ir.BasicBlock, store: ir.StoreInst) bool {
    if (!store.ty.eql(.{ .int = 32 }) or store.attrs.isBarrier()) return false;
    if (genericCfgI32Address(function, store.ptr) == null) return false;
    return genericCfgSupportsSingleBlockI32Value(function, block, store.value);
}

pub fn genericCfgSupportsSingleBlockCall(function: ir.Function, block: ir.BasicBlock, result: ?[]const u8, call: ir.CallInst) bool {
    if (call.isDebugVariableLocation()) return result == null and call.ret_ty == .void;
    if (genericCfgSupportsSminIntrinsicCall(function, call)) return result != null;
    if (call.ret_ty == .void) {
        if (result != null) return false;
    } else if (!call.ret_ty.eql(.{ .int = 32 }) or result == null) return false;
    if (call.args.items.len > 18) return false;
    if (call.inline_asm != null) return false;
    if (call.callee_value) |callee_value| {
        const callee_name = switch (callee_value) {
            .named => |name| name,
            .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
        };
        if (paramRegOrNull(function, callee_name, .ptr) catch null == null) return false;
    }
    if (!callIsFastcc(call.calling_conv)) validateDefaultCallConv(call.calling_conv) catch return false;
    sysv_abi.rejectUnsupportedCallEnvelope(call) catch return false;
    var gpr_index: usize = 0;
    var sse_index: usize = 0;
    for (call.args.items) |arg| {
        if (!genericCfgSupportsScalarCallArg(function, block, arg, &gpr_index, &sse_index)) return false;
    }
    if (result) |name| return genericCfgSingleBlockResultIsUsed(block, name);
    return call.ret_ty == .void;
}

fn genericCfgSupportsScalarCallArg(
    function: ir.Function,
    block: ir.BasicBlock,
    arg: ir.CallArg,
    gpr_index: *usize,
    sse_index: *usize,
) bool {
    if (arg.attrs != null) return false;
    if (arg.ty.eql(.{ .int = 32 })) {
        defer gpr_index.* += 1;
        return switch (arg.value) {
            .int => true,
            .named => |name| if (gpr_index.* >= 6)
                genericCfgSupportsSingleBlockI32Value(function, block, arg.value)
            else
                genericCfgSupportsI32Param(function, name),
            .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
        };
    }
    if (arg.ty.eql(.{ .int = 64 })) {
        defer gpr_index.* += 1;
        return switch (arg.value) {
            .int => true,
            .named => |name| genericCfgSupportsTypedParam(function, name, .{ .int = 64 }),
            .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
        };
    }
    if (arg.ty.eql(.float) or arg.ty.eql(.double)) {
        if (sse_index.* >= 8) return false;
        defer sse_index.* += 1;
        return switch (arg.value) {
            .fp => true,
            .named => |name| genericCfgSupportsTypedParam(function, name, arg.ty),
            .int, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
        };
    }
    return false;
}

pub fn genericCfgSupportsSminIntrinsicCall(function: ir.Function, call: ir.CallInst) bool {
    if (!isCalleeName(call.callee, "llvm.smin.i32") or call.args.items.len != 2) return false;
    if (!call.ret_ty.eql(.{ .int = 32 }) or call.callee_value != null or call.inline_asm != null) return false;
    for (call.args.items) |arg| {
        if (!arg.ty.eql(.{ .int = 32 })) return false;
        const name = switch (arg.value) {
            .named => |name| name,
            .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
        };
        if (paramRegOrNull(function, name, .{ .int = 32 }) catch null == null) return false;
    }
    return true;
}

pub fn genericCfgSingleBlockResultIsUsed(block: ir.BasicBlock, name: []const u8) bool {
    for (block.instructions.items) |instruction| {
        switch (instruction.kind) {
            .store => |store| if (genericCfgValueReferencesName(block, store.value, name)) return true,
            .binary => |binary| {
                if (genericCfgValueReferencesName(block, binary.lhs, name) or
                    genericCfgValueReferencesName(block, binary.rhs, name)) return true;
            },
            else => {},
        }
    }
    const ret = switch (block.terminator orelse return false) {
        .ret => |ret| ret,
        else => return false,
    };
    return genericCfgValueReferencesName(block, ret.value orelse return false, name);
}

pub fn genericCfgValueReferencesName(block: ir.BasicBlock, value: ir.Value, name: []const u8) bool {
    switch (value) {
        .named => |candidate| {
            if (std.mem.eql(u8, candidate, name)) return true;
            const instruction = findInstruction(block, candidate) orelse return false;
            return switch (instruction.kind) {
                .binary => |binary| genericCfgValueReferencesName(block, binary.lhs, name) or
                    genericCfgValueReferencesName(block, binary.rhs, name),
                .select => |select| genericCfgValueReferencesName(block, select.true_value, name) or
                    genericCfgValueReferencesName(block, select.false_value, name),
                else => false,
            };
        },
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    }
}

pub fn genericCfgSupportsI32Param(function: ir.Function, name: []const u8) bool {
    for (function.params.items) |param| {
        if (std.mem.eql(u8, param.name, name)) return param.ty.eql(.{ .int = 32 });
    }
    return false;
}

fn genericCfgSupportsTypedParam(function: ir.Function, name: []const u8, ty: ir.Type) bool {
    for (function.params.items) |param| {
        if (std.mem.eql(u8, param.name, name)) return param.ty.eql(ty);
    }
    return false;
}

pub fn genericCfgSupportsPointerParam(function: ir.Function, name: []const u8) bool {
    for (function.params.items) |param| {
        if (std.mem.eql(u8, param.name, name)) return param.ty.eql(.ptr);
    }
    return false;
}

pub fn genericCfgSupportsI1Param(function: ir.Function, name: []const u8) bool {
    for (function.params.items) |param| {
        if (std.mem.eql(u8, param.name, name)) return param.ty.eql(.{ .int = 1 });
    }
    return false;
}

pub fn genericCfgSupportsI32ParamOrConst(function: ir.Function, value: ir.Value) bool {
    return switch (value) {
        .int => true,
        .named => |name| genericCfgSupportsI32Param(function, name),
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
    };
}

pub fn genericCfgSupportsI8ParamOrConst(function: ir.Function, value: ir.Value) bool {
    return switch (value) {
        .int => |int| int >= 0 and int <= std.math.maxInt(u8),
        .named => |name| (paramRegOrNull(function, name, .{ .int = 8 }) catch null) != null,
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
    };
}

pub fn genericCfgSupportsI16ParamOrConst(function: ir.Function, value: ir.Value) bool {
    return switch (value) {
        .int => |int| int >= std.math.minInt(i16) and int <= std.math.maxInt(i16),
        .named => |name| (paramRegOrNull(function, name, .{ .int = 16 }) catch null) != null,
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
    };
}

pub fn genericCfgSupportsSelectedI32Value(function: ir.Function, value: ir.Value) bool {
    return switch (value) {
        .int => true,
        .named => |name| genericCfgSupportsI32Param(function, name),
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
    };
}

pub fn functionHasCall(function: ir.Function, callee: []const u8) bool {
    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            const call = switch (instruction.kind) {
                .call => |call| call,
                else => continue,
            };
            if (std.mem.eql(u8, call.callee, callee)) return true;
        }
    }
    return false;
}

pub fn genericCfgSupportsLoopSum(function: ir.Function) bool {
    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) return false;
            if (!genericCfgSupportsInstruction(function, instruction)) return false;
        }
        if (!genericCfgSupportsTerminator(function, block)) return false;
    }
    return true;
}

pub fn genericCfgSupportsInstruction(function: ir.Function, instruction: ir.Instruction) bool {
    if (instruction.result) |result| {
        if (result.len == 0) return false;
    }
    return switch (instruction.kind) {
        .phi => |phi| genericCfgSupportsPhi(function, phi),
        .binary => |binary| genericCfgSupportsBinary(function, binary),
        .icmp => |icmp| genericCfgSupportsIcmp(function, icmp),
        .fcmp => |fcmp| genericCfgSupportsFcmp(function, fcmp),
        .cast => |cast| genericCfgSupportsCast(function, cast),
        .gep => |gep| genericCfgSupportsGep(function, gep),
        .load => |load| genericCfgSupportsLoad(function, load),
        .call => |call| genericCfgSupportsCall(function, call),
        .extractvalue => |extractvalue| genericCfgSupportsExtractValue(function, extractvalue.result_ty, extractvalue.aggregate, extractvalue.indices),
        .freeze, .select, .alloca, .store, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .insertvalue => false,
    };
}

pub fn genericCfgSupportsPhi(function: ir.Function, phi: ir.PhiInst) bool {
    if (!phi.ty.eql(.{ .int = 32 }) or phi.incoming.items.len < 2) return false;
    for (phi.incoming.items) |incoming| {
        if (blockIndex(function, incoming.block) == null) return false;
        if (!genericCfgSupportsI32Value(function, incoming.value)) return false;
    }
    return true;
}

pub fn genericCfgSupportsBinary(function: ir.Function, binary: ir.BinaryInst) bool {
    if (!binary.ty.eql(.{ .int = 1 }) and !binary.ty.eql(.{ .int = 8 }) and !binary.ty.eql(.{ .int = 32 })) return false;
    if (machineBinaryOp(binary.op) == null) return false;
    return genericCfgSupportsScalarValue(function, binary.lhs) and
        genericCfgSupportsScalarValue(function, binary.rhs);
}

pub fn genericCfgSupportsIcmp(function: ir.Function, icmp: ir.IcmpInst) bool {
    if (!icmp.operand_ty.eql(.{ .int = 32 }) and !icmp.operand_ty.eql(.{ .int = 64 })) return false;
    switch (icmp.predicate) {
        .eq, .ne, .ult, .slt, .sgt => {},
        .uge, .ugt, .ule, .sle, .sge => return false,
    }
    return genericCfgSupportsI32Value(function, icmp.lhs) and
        genericCfgSupportsI32Value(function, icmp.rhs);
}

pub fn genericCfgSupportsFcmp(function: ir.Function, fcmp: ir.FcmpInst) bool {
    if (!fcmp.operand_ty.eql(.float) and !fcmp.operand_ty.eql(.double)) return false;
    switch (fcmp.predicate) {
        .ole, .oge => {},
        else => return false,
    }
    return genericCfgSupportsScalarValue(function, fcmp.lhs) and
        genericCfgSupportsScalarValue(function, fcmp.rhs);
}

pub fn genericCfgSupportsCast(function: ir.Function, cast: ir.CastInst) bool {
    switch (cast.op) {
        .zext => {
            if ((!cast.from_ty.eql(.{ .int = 8 }) and !cast.from_ty.eql(.{ .int = 32 })) or
                (!cast.to_ty.eql(.{ .int = 32 }) and !cast.to_ty.eql(.{ .int = 64 }))) return false;
        },
        .fptosi => {
            if ((!cast.from_ty.eql(.float) and !cast.from_ty.eql(.double)) or !cast.to_ty.eql(.{ .int = 32 })) return false;
        },
        .fpext, .fptrunc, .sitofp, .uitofp => {
            if (!genericCfgSupportsScalarType(cast.from_ty) or !genericCfgSupportsScalarType(cast.to_ty)) return false;
        },
        .trunc, .sext, .fptoui, .bitcast, .ptrtoint, .inttoptr => return false,
    }
    return genericCfgSupportsScalarValue(function, cast.value);
}

pub fn genericCfgSupportsGep(function: ir.Function, gep: ir.GepInst) bool {
    if (!gep.source_ty.eql(.{ .aggregate = "[4 x i8]" })) return false;
    if (gep.ptr_addrspace != null) return false;
    if (!genericCfgSupportsPointerValue(function, gep.ptr)) return false;
    if (gep.indices.items.len != 2) return false;
    const first = gep.indices.items[0];
    const second = gep.indices.items[1];
    return first.ty.eql(.{ .int = 64 }) and isInt(first.value, 0) and
        second.ty.eql(.{ .int = 64 }) and genericCfgSupportsI64Value(function, second.value);
}

pub fn genericCfgSupportsLoad(function: ir.Function, load: ir.LoadInst) bool {
    if (!load.ty.eql(.{ .int = 8 }) or load.attrs.isBarrier()) return false;
    if (load.ty_addrspace != null or load.ptr_addrspace != null) return false;
    return genericCfgSupportsPointerValue(function, load.ptr);
}

pub fn genericCfgSupportsCall(function: ir.Function, call: ir.CallInst) bool {
    if (call.isDebugVariableLocation()) return call.ret_ty == .void;
    if (call.callee_value != null or call.inline_asm != null) return false;
    if (std.mem.eql(u8, call.callee, "llvm.assume")) {
        return call.ret_ty == .void and call.args.items.len == 1 and genericCfgSupportsI1Value(function, call.args.items[0].value);
    }
    if (std.mem.eql(u8, call.callee, "llvm.sadd.with.overflow.i32")) {
        if (!call.ret_ty.eql(.{ .aggregate = "{ i32, i1 }" }) or call.args.items.len != 2) return false;
        return genericCfgSupportsI32Value(function, call.args.items[0].value) and
            genericCfgSupportsI32Value(function, call.args.items[1].value);
    }
    if (isCalleeName(call.callee, "debug.FullPanic((function 'defaultPanic')).integerOverflow") or
        isCalleeName(call.callee, "debug.FullPanic((function 'defaultPanic')).integerOutOfBounds") or
        isCalleeName(call.callee, "expanded_numeric_casts.integerPartOutOfBounds") or
        isCalleeName(call.callee, "base64_table_lookup.outOfBounds"))
    {
        if (call.ret_ty != .void) return false;
        for (call.args.items) |arg| {
            if (!genericCfgSupportsScalarValue(function, arg.value)) return false;
        }
        return true;
    }
    return false;
}

pub fn genericCfgSupportsExtractValue(function: ir.Function, result_ty: ir.Type, aggregate: ir.Value, indices: []const u8) bool {
    if (!result_ty.eql(.{ .int = 32 }) and !result_ty.eql(.{ .int = 1 })) return false;
    if (!std.mem.eql(u8, indices, "0") and !std.mem.eql(u8, indices, "1")) return false;
    return switch (aggregate) {
        .named => |name| genericCfgSupportsNamedValue(function, name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
    };
}

pub fn genericCfgSupportsTerminator(function: ir.Function, block: ir.BasicBlock) bool {
    const terminator = block.terminator orelse return false;
    return switch (terminator) {
        .br => |br| blockIndex(function, br.target) != null,
        .condbr => |condbr| condbr.cond_ty.eql(.{ .int = 1 }) and
            genericCfgSupportsI1Value(function, condbr.cond) and
            blockIndex(function, condbr.then_target) != null and
            blockIndex(function, condbr.else_target) != null,
        .ret => |ret| ret.ty.eql(.{ .int = 32 }) and
            genericCfgSupportsI32Value(function, ret.value orelse return false),
        .@"unreachable" => true,
        .@"switch", .indirectbr => false,
    };
}

pub fn genericCfgSupportsI32Value(function: ir.Function, value: ir.Value) bool {
    return switch (value) {
        .int => true,
        .named => |name| genericCfgSupportsNamedValue(function, name),
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
    };
}

pub fn genericCfgSupportsI64Value(function: ir.Function, value: ir.Value) bool {
    return switch (value) {
        .int => true,
        .named => |name| genericCfgSupportsNamedValue(function, name),
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
    };
}

pub fn genericCfgSupportsI1Value(function: ir.Function, value: ir.Value) bool {
    return switch (value) {
        .named => |name| genericCfgSupportsNamedValue(function, name),
        .int => |int| int == 0 or int == 1,
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
    };
}

pub fn genericCfgSupportsScalarValue(function: ir.Function, value: ir.Value) bool {
    return switch (value) {
        .int, .fp => true,
        .named => |name| genericCfgSupportsNamedValue(function, name),
        .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
    };
}

pub fn genericCfgSupportsPointerValue(function: ir.Function, value: ir.Value) bool {
    return switch (value) {
        .named => |name| genericCfgSupportsNamedValue(function, name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
    };
}

pub fn genericCfgSupportsScalarType(ty: ir.Type) bool {
    return ty.eql(.float) or ty.eql(.double) or ty.eql(.{ .int = 8 }) or
        ty.eql(.{ .int = 32 }) or ty.eql(.{ .int = 64 });
}

pub fn genericCfgSupportsNamedValue(function: ir.Function, name: []const u8) bool {
    if (name.len > 0 and name[0] == '@') return true;
    for (function.params.items) |param| {
        if (std.mem.eql(u8, param.name, name)) return true;
    }
    for (function.blocks.items) |block| {
        if (findInstruction(block, name) != null) return true;
    }
    return false;
}

pub fn genericCfgSupportsCheckedGuard(function: ir.Function) bool {
    if (!genericCfgSupportsLoopSum(function)) return false;
    return functionHasCall(function, "expanded_numeric_casts.integerPartOutOfBounds") or
        functionHasCall(function, "base64_table_lookup.outOfBounds");
}
