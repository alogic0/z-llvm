const shared = @import("core_shared.zig");
const core_cfg_emit = @import("core_cfg_emit.zig");
const core_value_emit = @import("core_value_emit.zig");
const cabi_abi_helpers = @import("cabi_abi_helpers.zig");
const cabi_call_lowering = @import("cabi_call_lowering.zig");

const std = shared.std;
const ir = shared.ir;
const MachineFunction = shared.MachineFunction;
const ArgReg = shared.ArgReg;

const appendAlignedDirectCall = shared.appendAlignedDirectCall;
const appendGenericCfgBlockLabel = core_cfg_emit.appendGenericCfgBlockLabel;
const appendGenericCfgConditionalBranch = core_cfg_emit.appendGenericCfgConditionalBranch;
const appendMoveImmToArgReg = shared.appendMoveImmToArgReg;
const callIsFastcc = shared.callIsFastcc;
const emitGenericCfgI64ValueIntoRax = core_value_emit.emitGenericCfgI64ValueIntoRax;
const globalSymbolName = shared.globalSymbolName;
const globalSymbolNameFromValue = shared.globalSymbolNameFromValue;
const i64Value = shared.i64Value;
const isInt = shared.isInt;
const isNamed = shared.isNamed;
const paramRegOrNull = cabi_abi_helpers.paramRegOrNull;
const paramValueReg = cabi_abi_helpers.paramValueReg;
const validateDefaultCallConv = shared.validateDefaultCallConv;
const findInstruction = cabi_call_lowering.findInstruction;

fn validateAssumeColdCall(instruction: ir.Instruction) !void {
    if (instruction.removed) return error.UnsupportedCodegenInstruction;
    if (instruction.result != null) return error.UnsupportedCodegenInstruction;
    const call = switch (instruction.kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (call.callee_value != null or call.inline_asm != null) return error.UnsupportedCodegenInstruction;
    if (!std.mem.eql(u8, call.callee, "llvm.assume")) return error.UnsupportedCodegenInstruction;
    if (call.ret_ty != .void or call.args.items.len != 1) return error.UnsupportedCodegenInstruction;
    if (!call.args.items[0].ty.eql(.{ .int = 1 }) or !isInt(call.args.items[0].value, 1)) return error.UnsupportedCodegenValue;
}

pub fn emitGenericCfgNoreturnCallBlock(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
) !void {
    if (block.instructions.items.len >= 4) {
        if (validateNoreturnSliceRuntimeCall(block)) |call| {
            try emitSlicePointerIntoRdi(allocator, machine, function, block, call.args.items[0].value);
            try emitSliceLengthIntoRsi(allocator, machine, function, block, call.args.items[1].value);
            try appendAlignedDirectCall(allocator, machine, call.callee, .void);
            try machine.instructions.append(allocator, .ud2);
            return;
        } else |err| switch (err) {
            error.UnsupportedCodegenInstruction,
            error.UnsupportedCodegenType,
            error.UnsupportedCodegenValue,
            error.BlockWithoutTerminator,
            error.UnsupportedCodegenControlFlow,
            => {},
            else => return err,
        }
    }

    if (block.instructions.items.len == 0 or block.instructions.items.len > 2) return error.UnsupportedCodegenInstruction;
    var call_index: usize = 0;
    if (block.instructions.items.len == 2) {
        try validateAssumeColdCall(block.instructions.items[0]);
        call_index = 1;
    }
    const call = switch (block.instructions.items[call_index].kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (call.callee_value != null or call.inline_asm != null or call.ret_ty != .void) return error.UnsupportedCodegenInstruction;
    if (!callIsFastcc(call.calling_conv)) try validateDefaultCallConv(call.calling_conv);
    switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .@"unreachable" => {},
        else => return error.UnsupportedCodegenControlFlow,
    }

    if (call.args.items.len == 2) {
        try validateSliceRuntimeCallArgs(call);
        try emitSlicePointerIntoRdi(allocator, machine, function, block, call.args.items[0].value);
        try emitSliceLengthIntoRsi(allocator, machine, function, block, call.args.items[1].value);
    } else if (call.args.items.len != 0) {
        return error.UnsupportedCodegenInstruction;
    }
    try appendAlignedDirectCall(allocator, machine, call.callee, .void);
    try machine.instructions.append(allocator, .ud2);
}

pub fn validateNoreturnSliceRuntimeCall(block: ir.BasicBlock) !ir.CallInst {
    if (block.instructions.items.len == 0) return error.UnsupportedCodegenInstruction;
    if (block.instructions.items.len > 1) {
        validateAssumeColdCall(block.instructions.items[0]) catch |err| switch (err) {
            error.UnsupportedCodegenInstruction, error.UnsupportedCodegenValue => {},
        };
    }
    const call_instruction = block.instructions.items[block.instructions.items.len - 1];
    const call = switch (call_instruction.kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (call.callee_value != null or call.inline_asm != null or call.ret_ty != .void) return error.UnsupportedCodegenInstruction;
    if (!callIsFastcc(call.calling_conv)) try validateDefaultCallConv(call.calling_conv);
    try validateSliceRuntimeCallArgs(call);
    if (call.args.items.len == 3 and call.args.items[2].ty != .ptr) return error.UnsupportedCodegenType;
    _ = try resolveSlicePointerValue(block, call.args.items[0].value);
    switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .@"unreachable" => {},
        else => return error.UnsupportedCodegenControlFlow,
    }
    return call;
}

fn validateSliceRuntimeCallArgs(call: ir.CallInst) !void {
    if (call.args.items.len != 2 and call.args.items.len != 3) return error.UnsupportedCodegenInstruction;
    if (call.args.items[0].ty != .ptr) return error.UnsupportedCodegenType;
    if (!call.args.items[1].ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenType;
}

pub const SlicePointerValue = union(enum) {
    global: []const u8,
    materialize: ir.Value,
};

pub fn resolveSlicePointerValue(block: ir.BasicBlock, value: ir.Value) !SlicePointerValue {
    switch (value) {
        .named => |name| {
            if (std.mem.startsWith(u8, name, "@")) return .{ .global = try globalSymbolName(name) };
            const instruction = findInstruction(block, name) orelse return error.UnsupportedCodegenValue;
            const extract = switch (instruction.kind) {
                .extractvalue => |extractvalue| extractvalue,
                else => return error.UnsupportedCodegenInstruction,
            };
            if (!extract.result_ty.eql(.ptr) or !std.mem.eql(u8, extract.indices, "0")) return error.UnsupportedCodegenInstruction;
            if (resolveSlicePointerFromInsertedAggregate(block, extract.aggregate)) |resolved| return resolved;
            return .{ .global = try globalSymbolNameFromValue(extract.aggregate) };
        },
        .constant_expr => return .{ .global = try globalSymbolNameFromValue(value) },
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector => return error.UnsupportedCodegenValue,
    }
}

fn resolveSlicePointerFromInsertedAggregate(block: ir.BasicBlock, aggregate: ir.Value) ?SlicePointerValue {
    const aggregate_name = switch (aggregate) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    const len_insert = findInstruction(block, aggregate_name) orelse return null;
    const len_insertvalue = switch (len_insert.kind) {
        .insertvalue => |insertvalue| insertvalue,
        else => return null,
    };
    if (!std.mem.eql(u8, len_insertvalue.indices, "1")) return null;
    const ptr_insert_name = switch (len_insertvalue.aggregate) {
        .named => |name| name,
        .undef => return null,
        .int, .fp, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    const ptr_insert = findInstruction(block, ptr_insert_name) orelse return null;
    const ptr_insertvalue = switch (ptr_insert.kind) {
        .insertvalue => |insertvalue| insertvalue,
        else => return null,
    };
    if (!std.mem.eql(u8, ptr_insertvalue.indices, "0") or !ptr_insertvalue.value_ty.eql(.ptr)) return null;
    if (globalSymbolNameFromValue(ptr_insertvalue.value)) |symbol| return .{ .global = symbol } else |_| {}
    return switch (ptr_insertvalue.value) {
        .named => .{ .materialize = ptr_insertvalue.value },
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => null,
    };
}

pub fn resolveSliceLengthValue(function: ir.Function, block: ir.BasicBlock, value: ir.Value) anyerror!SliceLengthValue {
    switch (value) {
        .int => |int| return .{ .imm = try i64Value(int) },
        .named => |name| {
            if (paramRegOrNull(function, name, .{ .int = 64 }) catch null) |reg| return .{ .reg = reg };
            const instruction = findInstructionInFunction(function, block, name) orelse return error.UnsupportedCodegenValue;
            switch (instruction.kind) {
                .extractvalue => |extract| {
                    if (!extract.result_ty.eql(.{ .int = 64 }) or !std.mem.eql(u8, extract.indices, "1")) return error.UnsupportedCodegenInstruction;
                    if (try resolveSliceLengthFromInsertedAggregate(function, block, extract.aggregate)) |len| return len;
                    return .{ .imm = try sliceLengthFromAggregateConstant(extract.aggregate) };
                },
                .cast, .load, .binary, .select => return .{ .materialize = value },
                .phi => |phi| {
                    if (!phi.ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenType;
                    return .{ .materialize = value };
                },
                else => return error.UnsupportedCodegenInstruction,
            }
        },
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    }
}

fn resolveSliceLengthFromInsertedAggregate(function: ir.Function, block: ir.BasicBlock, aggregate: ir.Value) anyerror!?SliceLengthValue {
    const aggregate_name = switch (aggregate) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    const instruction = findInstructionInFunction(function, block, aggregate_name) orelse return null;
    switch (instruction.kind) {
        .insertvalue => |insert| {
            if (!std.mem.eql(u8, insert.indices, "1") or !insert.value_ty.eql(.{ .int = 64 })) return null;
            return try resolveSliceLengthValue(function, block, insert.value);
        },
        .load => |load| {
            if (!load.ty.eql(.{ .aggregate = "{ ptr, i64 }" }) or load.attrs.isBarrier()) return null;
            const slot_name = switch (load.ptr) {
                .named => |slot| slot,
                .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
            };
            const stored = storedValueInFunction(function, block, slot_name, .{ .aggregate = "{ ptr, i64 }" }) orelse return null;
            return try resolveSliceLengthFromInsertedAggregate(function, block, stored);
        },
        else => return null,
    }
}

fn storedValueInFunction(function: ir.Function, preferred_block: ir.BasicBlock, slot_name: []const u8, ty: ir.Type) ?ir.Value {
    if (storedValueInBlock(preferred_block, slot_name, ty)) |value| return value;
    for (function.blocks.items) |block| {
        if (std.mem.eql(u8, block.name, preferred_block.name)) continue;
        if (storedValueInBlock(block, slot_name, ty)) |value| return value;
    }
    return null;
}

fn storedValueInBlock(block: ir.BasicBlock, slot_name: []const u8, ty: ir.Type) ?ir.Value {
    for (block.instructions.items) |instruction| {
        if (instruction.removed) continue;
        const store = switch (instruction.kind) {
            .store => |store| store,
            else => continue,
        };
        if (!store.ty.eql(ty) or store.attrs.isBarrier() or !isNamed(store.ptr, slot_name)) continue;
        return store.value;
    }
    return null;
}

pub const SliceLengthValue = union(enum) {
    imm: i64,
    reg: ArgReg,
    materialize: ir.Value,
};

pub fn emitSlicePointerIntoRdi(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    value: ir.Value,
) !void {
    switch (try resolveSlicePointerValue(block, value)) {
        .global => |symbol| try machine.instructions.append(allocator, .{ .lea_global_rdi = symbol }),
        .materialize => |materialized| try emitPointerValueIntoArgReg(allocator, machine, function, block, .rdi, materialized),
    }
}

pub fn emitSliceLengthIntoRsi(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    value: ir.Value,
) !void {
    switch (try resolveSliceLengthValue(function, block, value)) {
        .imm => |len| try appendMoveImmToArgReg(allocator, machine, .rsi, len),
        .reg => |reg| if (reg != .rsi) try machine.instructions.append(allocator, .{ .mov_arg64_arg = .{ .dst = .rsi, .src = reg } }),
        .materialize => |materialized| try emitI64ValueIntoArgReg(allocator, machine, function, block, .rsi, materialized),
    }
}

pub fn emitI64ValueIntoArgReg(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    dst: ArgReg,
    value: ir.Value,
) anyerror!void {
    switch (value) {
        .int => |int| return try appendMoveImmToArgReg(allocator, machine, dst, try i64Value(int)),
        .named => |name| {
            if (try emitNamedI64ValueIntoArgReg(allocator, machine, function, block, dst, name)) return;
            return error.UnsupportedCodegenValue;
        },
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    }
}

pub fn emitNamedI64ValueIntoArgReg(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    dst: ArgReg,
    name: []const u8,
) anyerror!bool {
    if (paramRegOrNull(function, name, .{ .int = 64 }) catch null) |reg| {
        if (reg != dst) try machine.instructions.append(allocator, .{ .mov_arg64_arg = .{ .dst = dst, .src = reg } });
        return true;
    }
    const instruction = findInstructionInFunction(function, block, name) orelse return false;
    switch (instruction.kind) {
        .cast => |cast| {
            if (cast.op != .bitcast or !cast.from_ty.eql(.{ .int = 64 }) or !cast.to_ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenInstruction;
            try emitI64ValueIntoArgReg(allocator, machine, function, block, dst, cast.value);
            return true;
        },
        .load => |load| {
            try emitLoadedI64IntoArgReg(allocator, machine, function, dst, load);
            return true;
        },
        .binary => |binary| {
            try emitComputedI64IntoArgReg(allocator, machine, function, block, dst, binary);
            return true;
        },
        .select => |select| {
            try emitSelectedI64IntoArgReg(allocator, machine, function, block, dst, name, select);
            return true;
        },
        .phi => |phi| {
            try emitPhiSelectedI64IntoArgReg(allocator, machine, function, block, dst, phi);
            return true;
        },
        .extractvalue => |extract| {
            if (!extract.result_ty.eql(.{ .int = 64 }) or !std.mem.eql(u8, extract.indices, "1")) return error.UnsupportedCodegenInstruction;
            if (try resolveSliceLengthFromInsertedAggregate(function, block, extract.aggregate)) |len| {
                switch (len) {
                    .imm => |imm| try appendMoveImmToArgReg(allocator, machine, dst, imm),
                    .reg => |reg| if (reg != dst) try machine.instructions.append(allocator, .{ .mov_arg64_arg = .{ .dst = dst, .src = reg } }),
                    .materialize => |materialized| try emitI64ValueIntoArgReg(allocator, machine, function, block, dst, materialized),
                }
                return true;
            }
            try appendMoveImmToArgReg(allocator, machine, dst, try sliceLengthFromAggregateConstant(extract.aggregate));
            return true;
        },
        else => return error.UnsupportedCodegenInstruction,
    }
}

fn emitPointerValueIntoArgReg(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    dst: ArgReg,
    value: ir.Value,
) anyerror!void {
    switch (value) {
        .named => |name| {
            if (paramRegOrNull(function, name, .ptr) catch null) |reg| {
                if (reg != dst) try machine.instructions.append(allocator, .{ .mov_arg64_arg = .{ .dst = dst, .src = reg } });
                return;
            }
            const instruction = findInstructionInFunction(function, block, name) orelse return error.UnsupportedCodegenValue;
            switch (instruction.kind) {
                .load => |load| {
                    try emitLoadedPointerIntoArgReg(allocator, machine, function, dst, load);
                    return;
                },
                .cast => |cast| {
                    if (cast.op != .bitcast or cast.to_ty != .ptr) return error.UnsupportedCodegenInstruction;
                    try emitPointerValueIntoArgReg(allocator, machine, function, block, dst, cast.value);
                    return;
                },
                .extractvalue => {
                    switch (try resolveSlicePointerValue(block, value)) {
                        .global => |symbol| {
                            if (dst != .rdi) return error.UnsupportedCodegenAbi;
                            try machine.instructions.append(allocator, .{ .lea_global_rdi = symbol });
                        },
                        .materialize => |materialized| try emitPointerValueIntoArgReg(allocator, machine, function, block, dst, materialized),
                    }
                    return;
                },
                else => return error.UnsupportedCodegenInstruction,
            }
        },
        .constant_expr => {
            if (dst != .rdi) return error.UnsupportedCodegenAbi;
            try machine.instructions.append(allocator, .{ .lea_global_rdi = try globalSymbolNameFromValue(value) });
        },
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector => return error.UnsupportedCodegenValue,
    }
}

fn emitLoadedPointerIntoArgReg(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    dst: ArgReg,
    load: ir.LoadInst,
) anyerror!void {
    if (load.ty != .ptr or load.attrs.isBarrier()) return error.UnsupportedCodegenInstruction;
    switch (load.ptr) {
        .named => |name| {
            if (paramRegOrNull(function, name, .ptr) catch null) |reg| {
                try machine.instructions.append(allocator, .{ .load_arg_ptr_disp8_rax = .{ .reg = reg, .offset = 0 } });
            } else if (std.mem.startsWith(u8, name, "@")) {
                try machine.instructions.append(allocator, .{ .load_global_ptr_rax = try globalSymbolName(name) });
            } else {
                return error.UnsupportedCodegenValue;
            }
        },
        .constant_expr => try machine.instructions.append(allocator, .{ .load_global_ptr_rax = try globalSymbolNameFromValue(load.ptr) }),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector => return error.UnsupportedCodegenValue,
    }
    try emitRaxIntoArgReg(allocator, machine, dst);
}

pub fn emitLoadedI64IntoArgReg(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    dst: ArgReg,
    load: ir.LoadInst,
) anyerror!void {
    if (!load.ty.eql(.{ .int = 64 }) or load.attrs.isBarrier()) return error.UnsupportedCodegenInstruction;
    switch (load.ptr) {
        .named => |name| {
            if (paramRegOrNull(function, name, .ptr) catch null) |reg| {
                try machine.instructions.append(allocator, .{ .load_arg_ptr_disp8_rax = .{ .reg = reg, .offset = 0 } });
            } else if (std.mem.startsWith(u8, name, "@")) {
                try machine.instructions.append(allocator, .{ .load_global_ptr_rax = try globalSymbolName(name) });
            } else {
                return error.UnsupportedCodegenValue;
            }
        },
        .constant_expr => try machine.instructions.append(allocator, .{ .load_global_ptr_rax = try globalSymbolNameFromValue(load.ptr) }),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector => return error.UnsupportedCodegenValue,
    }
    try emitRaxIntoArgReg(allocator, machine, dst);
}

fn emitSelectedI64IntoArgReg(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    dst: ArgReg,
    result_name: []const u8,
    select: ir.SelectInst,
) anyerror!void {
    _ = result_name;
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenInstruction;
    const cond_reg = paramValueReg(function, select.cond, .{ .int = 1 }) catch return error.UnsupportedCodegenValue;
    const true_label = "generic_cfg_i64_select_true";
    const end_label = "generic_cfg_i64_select_end";
    try machine.instructions.append(allocator, .{ .test_arg8 = cond_reg });
    try appendGenericCfgConditionalBranch(allocator, machine, .jne, true_label);
    try emitI64ValueIntoArgReg(allocator, machine, function, block, dst, select.false_value);
    try machine.instructions.append(allocator, .{ .jmp = end_label });
    try appendGenericCfgBlockLabel(allocator, machine, true_label);
    try emitI64ValueIntoArgReg(allocator, machine, function, block, dst, select.true_value);
    try appendGenericCfgBlockLabel(allocator, machine, end_label);
}

pub fn emitComputedI64IntoArgReg(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    dst: ArgReg,
    binary: ir.BinaryInst,
) anyerror!void {
    if (!binary.ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenType;
    switch (binary.op) {
        .add => {
            try emitGenericCfgI64ValueIntoRax(allocator, machine, function, block, binary.lhs);
            switch (binary.rhs) {
                .int => |int| {
                    const rhs = try i64Value(int);
                    if (rhs < 0 or rhs > std.math.maxInt(u8)) return error.UnsupportedCodegenValue;
                    if (rhs != 0) try machine.instructions.append(allocator, .{ .add_rax_imm8 = @intCast(rhs) });
                },
                .named => |name| {
                    const reg = (paramRegOrNull(function, name, .{ .int = 64 }) catch null) orelse return error.UnsupportedCodegenValue;
                    try machine.instructions.append(allocator, .{ .add_arg64_rax = reg });
                },
                .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
            }
        },
        .sub => {
            const rhs = switch (binary.rhs) {
                .int => |int| try i64Value(int),
                .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
            };
            if (rhs != 0) return error.UnsupportedCodegenInstruction;
            try emitI64ValueIntoArgReg(allocator, machine, function, block, dst, binary.lhs);
            return;
        },
        else => return error.UnsupportedCodegenInstruction,
    }
    try emitRaxIntoArgReg(allocator, machine, dst);
}

fn emitPhiSelectedI64IntoArgReg(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    dst: ArgReg,
    phi: ir.PhiInst,
) anyerror!void {
    if (phi.incoming.items.len != 1) return error.UnsupportedCodegenControlFlow;
    try emitI64ValueIntoArgReg(allocator, machine, function, block, dst, phi.incoming.items[0].value);
}

pub fn emitRaxIntoArgReg(allocator: std.mem.Allocator, machine: *MachineFunction, dst: ArgReg) !void {
    switch (dst) {
        .rdi => try machine.instructions.append(allocator, .mov_rax_rdi),
        .rsi => try machine.instructions.append(allocator, .mov_rax_rsi),
        .rdx, .rcx, .r8, .r9 => return error.UnsupportedCodegenAbi,
    }
}

pub fn lowerSliceAggregateInternalAbiReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (try lowerSliceParamChecksumReturn(allocator, machine, function, block, ret)) return true;
    if (try lowerSliceReturnThenI32CallReturn(allocator, machine, function, block, ret)) return true;
    return false;
}

fn lowerSliceParamChecksumReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!function.ret_ty.eql(.{ .int = 32 }) or !ret.ty.eql(.{ .int = 32 })) return false;
    if (!callIsFastcc(function.calling_conv)) return false;
    if (function.params.items.len != 1 or !isSliceAggregateType(function.params.items[0].ty)) return false;
    if (block.instructions.items.len != 9) return false;

    const slot_name = validateSliceAggregateAlloca(block.instructions.items[0]) orelse return false;
    if (!validateSliceAggregateStore(block.instructions.items[1], function.params.items[0].name, slot_name)) return false;

    const ptr_extract_name = validateSliceAggregateFieldLoad(block.instructions.items[2], block.instructions.items[3], slot_name, "0", .ptr) orelse return false;
    const first_load_name = validateI32LoadFromPtr(block.instructions.items[4], ptr_extract_name) orelse return false;
    const len_extract_name = validateSliceAggregateFieldLoad(block.instructions.items[5], block.instructions.items[6], slot_name, "1", .{ .int = 64 }) orelse return false;
    const trunc_name = validateI64ToI32Trunc(block.instructions.items[7], len_extract_name) orelse return false;
    const add_name = validateI32Add(block.instructions.items[8], first_load_name, trunc_name) orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, add_name)) return false;

    try machine.instructions.append(allocator, .{ .load_arg_ptr_disp8_eax = .{ .reg = .rdi, .offset = 0 } });
    try machine.instructions.append(allocator, .{ .binary_arg_eax = .{ .op = .add, .reg = .rsi } });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerSliceReturnThenI32CallReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!function.ret_ty.eql(.{ .int = 32 }) or !ret.ty.eql(.{ .int = 32 })) return false;
    if (function.calling_conv != null or function.params.items.len != 2) return false;
    if (!function.params.items[0].ty.eql(.ptr) or !function.params.items[1].ty.eql(.{ .int = 64 })) return false;
    if (block.instructions.items.len != 8) return false;

    const ptr_slot = validatePtrAlloca(block.instructions.items[0]) orelse return false;
    if (!validateStoreValueToSlot(block.instructions.items[1], function.params.items[0].name, ptr_slot, .ptr)) return false;
    const loaded_ptr = validateLoadFromSlot(block.instructions.items[2], ptr_slot, .ptr) orelse return false;
    const len_name = validateI64SubZero(block.instructions.items[3], function.params.items[1].name) orelse return false;
    const first_insert_name = validateSlicePtrInsert(block.instructions.items[4], loaded_ptr) orelse return false;
    const slice_name = validateSliceLenInsert(block.instructions.items[5], first_insert_name, len_name) orelse return false;
    const slice_call_name = validateFastccSliceIdentityCall(block.instructions.items[6], slice_name) orelse return false;
    const checksum_call_name = validateFastccSliceChecksumCall(block.instructions.items[7], slice_call_name) orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, checksum_call_name)) return false;

    try appendAlignedDirectCall(allocator, machine, switch (block.instructions.items[6].kind) {
        .call => |call| call.callee,
        else => return error.UnsupportedCodegenInstruction,
    }, .{ .aggregate = "{ ptr, i64 }" });
    try machine.instructions.append(allocator, .mov_rax_rdi);
    try machine.instructions.append(allocator, .{ .mov_arg64_arg = .{ .dst = .rsi, .src = .rdx } });
    try appendAlignedDirectCall(allocator, machine, switch (block.instructions.items[7].kind) {
        .call => |call| call.callee,
        else => return error.UnsupportedCodegenInstruction,
    }, .{ .int = 32 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn isSliceAggregateType(ty: ir.Type) bool {
    return ty.eql(.{ .aggregate = "{ ptr, i64 }" });
}

fn validateSliceAggregateAlloca(instruction: ir.Instruction) ?[]const u8 {
    if (instruction.removed) return null;
    const name = instruction.result orelse return null;
    const alloca = switch (instruction.kind) {
        .alloca => |alloca| alloca,
        else => return null,
    };
    if (!isSliceAggregateType(alloca.allocated_ty)) return null;
    return name;
}

fn validatePtrAlloca(instruction: ir.Instruction) ?[]const u8 {
    if (instruction.removed) return null;
    const name = instruction.result orelse return null;
    const alloca = switch (instruction.kind) {
        .alloca => |alloca| alloca,
        else => return null,
    };
    if (!alloca.allocated_ty.eql(.ptr)) return null;
    return name;
}

fn validateSliceAggregateStore(instruction: ir.Instruction, value_name: []const u8, slot_name: []const u8) bool {
    return validateStoreValueToSlot(instruction, value_name, slot_name, .{ .aggregate = "{ ptr, i64 }" });
}

fn validateStoreValueToSlot(instruction: ir.Instruction, value_name: []const u8, slot_name: []const u8, ty: ir.Type) bool {
    if (instruction.removed or instruction.result != null) return false;
    const store = switch (instruction.kind) {
        .store => |store| store,
        else => return false,
    };
    return store.ty.eql(ty) and !store.attrs.isBarrier() and isNamed(store.value, value_name) and isNamed(store.ptr, slot_name);
}

fn validateLoadFromSlot(instruction: ir.Instruction, slot_name: []const u8, ty: ir.Type) ?[]const u8 {
    if (instruction.removed) return null;
    const name = instruction.result orelse return null;
    const load = switch (instruction.kind) {
        .load => |load| load,
        else => return null,
    };
    if (!load.ty.eql(ty) or load.attrs.isBarrier() or !isNamed(load.ptr, slot_name)) return null;
    return name;
}

fn validateSliceAggregateFieldLoad(load_instruction: ir.Instruction, extract_instruction: ir.Instruction, slot_name: []const u8, index: []const u8, result_ty: ir.Type) ?[]const u8 {
    const load_name = validateLoadFromSlot(load_instruction, slot_name, .{ .aggregate = "{ ptr, i64 }" }) orelse return null;
    if (extract_instruction.removed) return null;
    const extract_name = extract_instruction.result orelse return null;
    const extract = switch (extract_instruction.kind) {
        .extractvalue => |extract| extract,
        else => return null,
    };
    if (!isSliceAggregateType(extract.aggregate_ty) or !extract.result_ty.eql(result_ty)) return null;
    if (!isNamed(extract.aggregate, load_name) or !std.mem.eql(u8, extract.indices, index)) return null;
    return extract_name;
}

fn validateI32LoadFromPtr(instruction: ir.Instruction, ptr_name: []const u8) ?[]const u8 {
    if (instruction.removed) return null;
    const name = instruction.result orelse return null;
    const load = switch (instruction.kind) {
        .load => |load| load,
        else => return null,
    };
    if (!load.ty.eql(.{ .int = 32 }) or load.attrs.isBarrier() or !isNamed(load.ptr, ptr_name)) return null;
    return name;
}

fn validateI64ToI32Trunc(instruction: ir.Instruction, value_name: []const u8) ?[]const u8 {
    if (instruction.removed) return null;
    const name = instruction.result orelse return null;
    const cast = switch (instruction.kind) {
        .cast => |cast| cast,
        else => return null,
    };
    if (cast.op != .trunc or !cast.from_ty.eql(.{ .int = 64 }) or !cast.to_ty.eql(.{ .int = 32 })) return null;
    if (!isNamed(cast.value, value_name)) return null;
    return name;
}

fn validateI32Add(instruction: ir.Instruction, lhs_name: []const u8, rhs_name: []const u8) ?[]const u8 {
    if (instruction.removed) return null;
    const name = instruction.result orelse return null;
    const binary = switch (instruction.kind) {
        .binary => |binary| binary,
        else => return null,
    };
    if (binary.op != .add or !binary.ty.eql(.{ .int = 32 })) return null;
    if (!((isNamed(binary.lhs, lhs_name) and isNamed(binary.rhs, rhs_name)) or
        (isNamed(binary.lhs, rhs_name) and isNamed(binary.rhs, lhs_name)))) return null;
    return name;
}

fn validateI64SubZero(instruction: ir.Instruction, lhs_name: []const u8) ?[]const u8 {
    if (instruction.removed) return null;
    const name = instruction.result orelse return null;
    const binary = switch (instruction.kind) {
        .binary => |binary| binary,
        else => return null,
    };
    if (binary.op != .sub or !binary.ty.eql(.{ .int = 64 }) or !isNamed(binary.lhs, lhs_name) or !isInt(binary.rhs, 0)) return null;
    return name;
}

fn validateSlicePtrInsert(instruction: ir.Instruction, ptr_name: []const u8) ?[]const u8 {
    if (instruction.removed) return null;
    const name = instruction.result orelse return null;
    const insert = switch (instruction.kind) {
        .insertvalue => |insert| insert,
        else => return null,
    };
    if (!isSliceAggregateType(insert.aggregate_ty) or insert.aggregate != .undef) return null;
    if (!insert.value_ty.eql(.ptr) or !isNamed(insert.value, ptr_name) or !std.mem.eql(u8, insert.indices, "0")) return null;
    return name;
}

fn validateSliceLenInsert(instruction: ir.Instruction, aggregate_name: []const u8, len_name: []const u8) ?[]const u8 {
    if (instruction.removed) return null;
    const name = instruction.result orelse return null;
    const insert = switch (instruction.kind) {
        .insertvalue => |insert| insert,
        else => return null,
    };
    if (!isSliceAggregateType(insert.aggregate_ty)) return null;
    if (!isNamed(insert.aggregate, aggregate_name) or !insert.value_ty.eql(.{ .int = 64 })) return null;
    if (!isNamed(insert.value, len_name) or !std.mem.eql(u8, insert.indices, "1")) return null;
    return name;
}

fn validateFastccSliceIdentityCall(instruction: ir.Instruction, arg_name: []const u8) ?[]const u8 {
    if (instruction.removed) return null;
    const name = instruction.result orelse return null;
    const call = switch (instruction.kind) {
        .call => |call| call,
        else => return null,
    };
    if (!callIsFastcc(call.calling_conv) or !isSliceAggregateType(call.ret_ty)) return null;
    if (call.callee_value != null or call.inline_asm != null or call.args.items.len != 1) return null;
    if (!isSliceAggregateType(call.args.items[0].ty) or !isNamed(call.args.items[0].value, arg_name)) return null;
    return name;
}

fn validateFastccSliceChecksumCall(instruction: ir.Instruction, arg_name: []const u8) ?[]const u8 {
    if (instruction.removed) return null;
    const name = instruction.result orelse return null;
    const call = switch (instruction.kind) {
        .call => |call| call,
        else => return null,
    };
    if (!callIsFastcc(call.calling_conv) or !call.ret_ty.eql(.{ .int = 32 })) return null;
    if (call.callee_value != null or call.inline_asm != null or call.args.items.len != 1) return null;
    if (!isSliceAggregateType(call.args.items[0].ty) or !isNamed(call.args.items[0].value, arg_name)) return null;
    return name;
}

pub fn findInstructionInFunction(function: ir.Function, preferred_block: ir.BasicBlock, result_name: []const u8) ?ir.Instruction {
    if (findInstruction(preferred_block, result_name)) |instruction| return instruction;
    for (function.blocks.items) |candidate_block| {
        if (std.mem.eql(u8, candidate_block.name, preferred_block.name)) continue;
        if (findInstruction(candidate_block, result_name)) |instruction| return instruction;
    }
    return null;
}

fn sliceLengthFromAggregateConstant(value: ir.Value) !i64 {
    const text = switch (value) {
        .constant_expr => |text| text,
        .named, .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector => return error.UnsupportedCodegenValue,
    };
    const marker = "i64 ";
    const start_marker = std.mem.lastIndexOf(u8, text, marker) orelse return error.UnsupportedCodegenValue;
    var start = start_marker + marker.len;
    while (start < text.len and text[start] == ' ') : (start += 1) {}
    var end = start;
    while (end < text.len and (std.ascii.isDigit(text[end]) or text[end] == '-')) : (end += 1) {}
    if (end == start) return error.UnsupportedCodegenValue;
    return std.fmt.parseInt(i64, text[start..end], 10) catch return error.UnsupportedCodegenValue;
}
