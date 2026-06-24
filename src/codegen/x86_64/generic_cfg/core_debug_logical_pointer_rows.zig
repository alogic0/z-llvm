const impl = @import("core_impl.zig");
const std = impl.std;
const ir = impl.ir;
const MachineFunction = impl.MachineFunction;

const hasSingleBlockInstructionCount = impl.hasSingleBlockInstructionCount;
const isNamed = impl.isNamed;
const singleRetVoidBlock = impl.singleRetVoidBlock;
const validateAllocaNamed = impl.validateAllocaNamed;
const validateAssumeTrue = impl.validateAssumeTrue;
const validateBr = impl.validateBr;
const validateCondbr = impl.validateCondbr;
const validateMemset = impl.validateMemset;
const validateNamedLoad = impl.validateNamedLoad;
const validateRetVoid = impl.validateRetVoid;
const validateStore = impl.validateStore;
const validateVoidCall = impl.validateVoidCall;
const validateZeroArrayGep = impl.validateZeroArrayGep;

pub fn lowerDebugLogicalPointerCompileError(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.startsWith(u8, function.name, "illegal_operation_on_logical_ptr.")) return false;
    if (function.ret_ty != .void or function.params.items.len != 0) return false;
    if (function.attrs == null) return false;

    if (std.mem.eql(u8, function.name, "illegal_operation_on_logical_ptr.ptrIntArithmetic")) {
        try validateDebugLogicalPointerPtrIntArithmetic(function);
    } else if (std.mem.eql(u8, function.name, "illegal_operation_on_logical_ptr.ptrPtrArithmetic")) {
        try validateDebugLogicalPointerTwoLocalStores(function);
    } else if (std.mem.eql(u8, function.name, "illegal_operation_on_logical_ptr.ptrFromInt")) {
        try validateDebugLogicalPointerPtrFromInt(function);
    } else if (std.mem.eql(u8, function.name, "illegal_operation_on_logical_ptr.intFromPtr")) {
        try validateDebugLogicalPointerOneLocalStore(function);
    } else if (std.mem.eql(u8, function.name, "illegal_operation_on_logical_ptr.elemVal")) {
        if (!hasSingleBlockInstructionCount(function, 7)) return false;
        try validateDebugLogicalPointerElemVal(function);
    } else if (std.mem.eql(u8, function.name, "illegal_operation_on_logical_ptr.elemPtr")) {
        if (!hasSingleBlockInstructionCount(function, 5)) return false;
        try validateDebugLogicalPointerElemPtr(function);
    } else {
        return false;
    }

    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn validateDebugLogicalPointerPtrIntArithmetic(function: ir.Function) !void {
    const block = try singleRetVoidBlock(function);
    if (block.instructions.items.len != 2) return error.UnsupportedCodegenInstruction;
    const slot = try validateAllocaNamed(block.instructions.items[0], .ptr);
    try validateMemset(block.instructions.items[1], slot, 8);
}

pub fn validateDebugLogicalPointerTwoLocalStores(function: ir.Function) !void {
    const block = try singleRetVoidBlock(function);
    if (block.instructions.items.len != 4) return error.UnsupportedCodegenInstruction;
    const first_slot = try validateAllocaNamed(block.instructions.items[0], .{ .int = 8 });
    const second_slot = try validateAllocaNamed(block.instructions.items[1], .{ .int = 8 });
    try validateStore(block.instructions.items[2], .{ .int = 8 }, .{ .int = 0 }, second_slot);
    try validateStore(block.instructions.items[3], .{ .int = 8 }, .{ .int = 0 }, first_slot);
}

pub fn validateDebugLogicalPointerOneLocalStore(function: ir.Function) !void {
    const block = try singleRetVoidBlock(function);
    if (block.instructions.items.len != 2) return error.UnsupportedCodegenInstruction;
    const slot = try validateAllocaNamed(block.instructions.items[0], .{ .int = 8 });
    try validateStore(block.instructions.items[1], .{ .int = 8 }, .{ .int = 0 }, slot);
}

pub fn validateDebugLogicalPointerPtrFromInt(function: ir.Function) !void {
    if (function.blocks.items.len != 4) return error.UnsupportedCodegenControlFlow;
    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 6) return error.UnsupportedCodegenInstruction;
    const ptr_slot = try validateAllocaNamed(entry.instructions.items[0], .ptr);
    const int_slot = try validateAllocaNamed(entry.instructions.items[1], .{ .int = 32 });
    try validateStore(entry.instructions.items[2], .{ .int = 32 }, .{ .int = 4660 }, int_slot);
    const load_name = try validateNamedLoad(entry.instructions.items[3], .{ .int = 32 }, int_slot);
    const zext_name = entry.instructions.items[4].result orelse return error.UnsupportedCodegenInstruction;
    const zext = switch (entry.instructions.items[4].kind) {
        .cast => |cast| cast,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (zext.op != .zext or !zext.from_ty.eql(.{ .int = 32 }) or !zext.to_ty.eql(.{ .int = 64 }) or !isNamed(zext.value, load_name)) return error.UnsupportedCodegenInstruction;
    const cmp_name = entry.instructions.items[5].result orelse return error.UnsupportedCodegenInstruction;
    const cmp = switch (entry.instructions.items[5].kind) {
        .icmp => |icmp| icmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (cmp.predicate != .ne or !cmp.operand_ty.eql(.{ .int = 64 }) or !isNamed(cmp.lhs, zext_name) or !cmp.rhs.eql(.{ .int = 0 })) return error.UnsupportedCodegenInstruction;
    try validateCondbr(entry, cmp_name, "8", "9");

    const success = function.blocks.items[1];
    if (!std.mem.eql(u8, success.name, "6")) return error.UnsupportedCodegenControlFlow;
    if (success.instructions.items.len != 2) return error.UnsupportedCodegenInstruction;
    const inttoptr_name = success.instructions.items[0].result orelse return error.UnsupportedCodegenInstruction;
    const inttoptr = switch (success.instructions.items[0].kind) {
        .cast => |cast| cast,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (inttoptr.op != .inttoptr or !inttoptr.from_ty.eql(.{ .int = 64 }) or inttoptr.to_ty != .ptr or !isNamed(inttoptr.value, zext_name)) return error.UnsupportedCodegenInstruction;
    try validateStore(success.instructions.items[1], .ptr, .{ .named = inttoptr_name }, ptr_slot);
    try validateRetVoid(success);

    const branch = function.blocks.items[2];
    if (!std.mem.eql(u8, branch.name, "8") or branch.instructions.items.len != 0) return error.UnsupportedCodegenControlFlow;
    try validateBr(branch, "6");

    const panic = function.blocks.items[3];
    if (!std.mem.eql(u8, panic.name, "9")) return error.UnsupportedCodegenControlFlow;
    if (panic.instructions.items.len != 2) return error.UnsupportedCodegenInstruction;
    try validateAssumeTrue(panic.instructions.items[0]);
    try validateVoidCall(panic.instructions.items[1], "debug.FullPanic((function 'defaultPanic')).castToNull", &.{});
    switch (panic.terminator orelse return error.BlockWithoutTerminator) {
        .@"unreachable" => {},
        .ret, .br, .condbr, .@"switch", .indirectbr => return error.UnsupportedCodegenControlFlow,
    }
}

pub fn validateDebugLogicalPointerElemVal(function: ir.Function) !void {
    const block = try singleRetVoidBlock(function);
    if (block.instructions.items.len != 7) return error.UnsupportedCodegenInstruction;
    const byte_slot = try validateAllocaNamed(block.instructions.items[0], .{ .int = 8 });
    const ptr_slot = try validateAllocaNamed(block.instructions.items[1], .ptr);
    try validateMemset(block.instructions.items[2], ptr_slot, 8);
    const loaded_ptr = try validateNamedLoad(block.instructions.items[3], .ptr, ptr_slot);
    const gep_name = try validateZeroArrayGep(block.instructions.items[4], loaded_ptr);
    const loaded_byte = try validateNamedLoad(block.instructions.items[5], .{ .int = 8 }, gep_name);
    try validateStore(block.instructions.items[6], .{ .int = 8 }, .{ .named = loaded_byte }, byte_slot);
}

pub fn validateDebugLogicalPointerElemPtr(function: ir.Function) !void {
    const block = try singleRetVoidBlock(function);
    if (block.instructions.items.len != 5) return error.UnsupportedCodegenInstruction;
    const ptr_slot = try validateAllocaNamed(block.instructions.items[0], .ptr);
    try validateMemset(block.instructions.items[1], ptr_slot, 8);
    const loaded_ptr = try validateNamedLoad(block.instructions.items[2], .ptr, ptr_slot);
    const gep_name = try validateZeroArrayGep(block.instructions.items[3], loaded_ptr);
    try validateStore(block.instructions.items[4], .{ .int = 8 }, .{ .int = 0 }, gep_name);
}
