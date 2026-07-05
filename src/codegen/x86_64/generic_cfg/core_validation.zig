const shared = @import("core_shared.zig");
const cabi_abi_helpers = @import("cabi_abi_helpers.zig");

const std = shared.std;
const ir = shared.ir;
const ArgReg = shared.ArgReg;
const globalSymbolName = shared.globalSymbolName;
const isNamed = shared.isNamed;
const paramValueReg = cabi_abi_helpers.paramValueReg;

fn valueReferencesGlobal(value: ir.Value, name: []const u8) bool {
    return switch (value) {
        .named => |value_name| blk: {
            const symbol = globalSymbolName(value_name) catch break :blk false;
            break :blk std.mem.eql(u8, symbol, name);
        },
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
    };
}

pub fn hasSingleBlockInstructionCount(function: ir.Function, count: usize) bool {
    return function.blocks.items.len == 1 and function.blocks.items[0].instructions.items.len == count;
}

pub fn typeIsI128(ty: ir.Type) bool {
    return switch (ty) {
        .int => |bits| bits == 128,
        .vector => |vector| switch (vector.elem_ty) {
            .int => |bits| bits == 128,
            .half, .float, .double, .fp128, .ptr => false,
        },
        .void, .half, .float, .double, .x86_fp80, .fp128, .metadata, .ptr, .aggregate => false,
    };
}

pub fn callHasPointerArg(call: ir.CallInst) bool {
    for (call.args.items) |arg| {
        if (arg.ty == .ptr) return true;
    }
    return false;
}

pub fn validateAlloca(instruction: ir.Instruction, expected_ty: ir.Type) ![]const u8 {
    const name = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const alloca = switch (instruction.kind) {
        .alloca => |alloca| alloca,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!alloca.allocated_ty.eql(expected_ty)) return error.UnsupportedCodegenType;
    return name;
}

pub fn validateGepOffsetResult(instruction: ir.Instruction, ptr_name: []const u8, offset: i128) ![]const u8 {
    const name = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const gep = switch (instruction.kind) {
        .gep => |gep| gep,
        else => return error.UnsupportedCodegenInstruction,
    };
    try validateI8GepOffset(gep, ptr_name, offset);
    return name;
}

pub fn validateI8GepOffset(gep: ir.GepInst, ptr_name: []const u8, offset: i128) !void {
    if (!gep.source_ty.eql(.{ .int = 8 }) or !isNamed(gep.ptr, ptr_name)) return error.UnsupportedCodegenInstruction;
    if (gep.indices.items.len != 1) return error.UnsupportedCodegenInstruction;
    const index = gep.indices.items[0];
    if (!index.ty.eql(.{ .int = 64 }) or !index.value.eql(.{ .int = offset })) return error.UnsupportedCodegenInstruction;
}

pub fn validateGlobalPtrStore(instruction: ir.Instruction, global_name: []const u8, ptr_name: []const u8) !void {
    if (instruction.result != null) return error.UnsupportedCodegenInstruction;
    const store = switch (instruction.kind) {
        .store => |store| store,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!store.ty.eql(.ptr) or !valueReferencesGlobal(store.value, global_name) or !isNamed(store.ptr, ptr_name) or store.attrs.isBarrier()) return error.UnsupportedCodegenInstruction;
}

pub fn singleRetVoidBlock(function: ir.Function) !ir.BasicBlock {
    if (function.blocks.items.len != 1) return error.UnsupportedCodegenControlFlow;
    const block = function.blocks.items[0];
    try validateRetVoid(block);
    return block;
}

pub fn validateRetVoid(block: ir.BasicBlock) !void {
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        .br, .condbr, .@"switch", .indirectbr, .@"unreachable" => return error.UnsupportedCodegenControlFlow,
    };
    if (ret.ty != .void or ret.value != null) return error.UnsupportedCodegenControlFlow;
}

pub fn validateAllocaNamed(instruction: ir.Instruction, ty: ir.Type) ![]const u8 {
    const name = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const alloca = switch (instruction.kind) {
        .alloca => |alloca| alloca,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!alloca.allocated_ty.eql(ty)) return error.UnsupportedCodegenInstruction;
    return name;
}

pub fn validateMemset(instruction: ir.Instruction, ptr_name: []const u8, len: i64) !void {
    if (instruction.result != null) return error.UnsupportedCodegenInstruction;
    const call = switch (instruction.kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!std.mem.eql(u8, call.callee, "llvm.memset.p0.i64") or call.ret_ty != .void or call.args.items.len != 4) return error.UnsupportedCodegenInstruction;
    if (call.args.items[0].ty != .ptr or !isNamed(call.args.items[0].value, ptr_name)) return error.UnsupportedCodegenInstruction;
    if (!call.args.items[1].ty.eql(.{ .int = 8 }) or !call.args.items[1].value.eql(.{ .int = -86 })) return error.UnsupportedCodegenInstruction;
    if (!call.args.items[2].ty.eql(.{ .int = 64 }) or !call.args.items[2].value.eql(.{ .int = len })) return error.UnsupportedCodegenInstruction;
    if (!call.args.items[3].ty.eql(.{ .int = 1 }) or !call.args.items[3].value.eql(.{ .int = 0 })) return error.UnsupportedCodegenInstruction;
}

pub fn validateStore(instruction: ir.Instruction, ty: ir.Type, value: ir.Value, ptr_name: []const u8) !void {
    if (instruction.result != null) return error.UnsupportedCodegenInstruction;
    const store = switch (instruction.kind) {
        .store => |store| store,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!store.ty.eql(ty) or !store.value.eql(value) or !isNamed(store.ptr, ptr_name) or store.attrs.isBarrier()) return error.UnsupportedCodegenInstruction;
}

pub fn validateNamedLoad(instruction: ir.Instruction, expected_ty: ir.Type, ptr_name: []const u8) ![]const u8 {
    const result = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const load = switch (instruction.kind) {
        .load => |load| load,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!load.ty.eql(expected_ty) or load.attrs.isBarrier() or !isNamed(load.ptr, ptr_name)) return error.UnsupportedCodegenInstruction;
    return result;
}

pub fn validateZeroArrayGep(instruction: ir.Instruction, ptr_name: []const u8) ![]const u8 {
    const name = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const gep = switch (instruction.kind) {
        .gep => |gep| gep,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!gep.source_ty.eql(.{ .aggregate = "[1 x i8]" }) or !isNamed(gep.ptr, ptr_name)) return error.UnsupportedCodegenInstruction;
    if (gep.indices.items.len != 1) return error.UnsupportedCodegenInstruction;
    const index = gep.indices.items[0];
    if (!index.ty.eql(.{ .int = 64 }) or !index.value.eql(.{ .int = 0 })) return error.UnsupportedCodegenInstruction;
    return name;
}
pub fn matchGlobalUpdate(function: ir.Function, block: ir.BasicBlock, ret: anytype, expected_global: []const u8) !?ArgReg {
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 1) return null;
    const has_reload = block.instructions.items.len == 4;
    if (block.instructions.items.len != 3 and !has_reload) return null;

    const load_inst = block.instructions.items[0];
    const add_inst = block.instructions.items[1];
    const store_inst = block.instructions.items[2];
    if (load_inst.removed or add_inst.removed or store_inst.removed) return null;
    const load_result = load_inst.result orelse return null;
    const add_result = add_inst.result orelse return null;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    if (!has_reload and !std.mem.eql(u8, ret_name, add_result)) return null;

    const load = switch (load_inst.kind) {
        .load => |load| load,
        else => return null,
    };
    if (!load.ty.eql(.{ .int = 32 }) or load.attrs.isBarrier()) return null;
    const global_name = switch (load.ptr) {
        .named => |name| try globalSymbolName(name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    if (!std.mem.eql(u8, global_name, expected_global)) return null;

    const add = switch (add_inst.kind) {
        .binary => |binary| binary,
        else => return null,
    };
    if (add.op != .add or !add.ty.eql(.{ .int = 32 })) return null;
    const arg_reg = if (isNamed(add.lhs, load_result))
        try paramValueReg(function, add.rhs, .{ .int = 32 })
    else if (isNamed(add.rhs, load_result))
        try paramValueReg(function, add.lhs, .{ .int = 32 })
    else
        return null;

    const store = switch (store_inst.kind) {
        .store => |store| store,
        else => return null,
    };
    if (!store.ty.eql(.{ .int = 32 }) or store.attrs.isBarrier()) return null;
    if (!store.ptr.eql(load.ptr) or !isNamed(store.value, add_result)) return null;
    if (has_reload) {
        const reload_inst = block.instructions.items[3];
        if (reload_inst.removed or !isNamed(ret.value orelse return error.InvalidRet, reload_inst.result orelse return null)) return null;
        const reload = switch (reload_inst.kind) {
            .load => |reload_load| reload_load,
            else => return null,
        };
        if (!reload.ty.eql(.{ .int = 32 }) or reload.attrs.isBarrier() or !reload.ptr.eql(load.ptr)) return null;
    }
    return arg_reg;
}
