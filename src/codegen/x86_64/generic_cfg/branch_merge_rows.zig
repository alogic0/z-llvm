const shared = @import("core_shared.zig");
const cabi_abi_helpers = @import("cabi_abi_helpers.zig");

const std = shared.std;
const ir = shared.ir;
const MachineFunction = shared.MachineFunction;

const i32Value = shared.i32Value;
const isNamed = shared.isNamed;
const paramRegOrNull = cabi_abi_helpers.paramRegOrNull;

pub const GenericCfgPointerPhiLoad = struct {
    phi_name: []const u8,
    load_name: []const u8,
    phi: ir.PhiInst,
};

pub const GenericCfgPhiBinaryReturn = struct {
    phi_name: []const u8,
    binary_name: []const u8,
    phi: ir.PhiInst,
    op: ir.BinaryOp,
    imm: i32,
};

pub fn appendGenericCfgPhiBinaryImmediate(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    phi_binary: GenericCfgPhiBinaryReturn,
) !void {
    switch (phi_binary.op) {
        .add => try machine.instructions.append(allocator, .{ .add_eax_imm32 = phi_binary.imm }),
        .sub => try machine.instructions.append(allocator, .{ .add_eax_imm32 = -phi_binary.imm }),
        else => return error.UnsupportedCodegenInstruction,
    }
}

pub fn genericCfgPhiBinaryReturn(merge_block: ir.BasicBlock) ?GenericCfgPhiBinaryReturn {
    if (merge_block.instructions.items.len != 2) return null;
    const phi_instruction = merge_block.instructions.items[0];
    const binary_instruction = merge_block.instructions.items[1];
    if (phi_instruction.removed or binary_instruction.removed) return null;
    const phi_name = phi_instruction.result orelse return null;
    const binary_name = binary_instruction.result orelse return null;
    const phi = switch (phi_instruction.kind) {
        .phi => |phi| phi,
        else => return null,
    };
    if (!phi.ty.eql(.{ .int = 32 }) or phi.incoming.items.len != 2) return null;
    const binary = switch (binary_instruction.kind) {
        .binary => |binary| binary,
        else => return null,
    };
    if (!binary.ty.eql(.{ .int = 32 }) or !isNamed(binary.lhs, phi_name)) return null;
    const imm = switch (binary.rhs) {
        .int => |int| i32Value(int) catch return null,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    switch (binary.op) {
        .add, .sub => {},
        else => return null,
    }
    const ret = switch (merge_block.terminator orelse return null) {
        .ret => |ret| ret,
        else => return null,
    };
    if (!ret.ty.eql(.{ .int = 32 }) or !isNamed(ret.value orelse return null, binary_name)) return null;
    return .{
        .phi_name = phi_name,
        .binary_name = binary_name,
        .phi = phi,
        .op = binary.op,
        .imm = imm,
    };
}

pub fn genericCfgPointerPhiLoadReturn(function: ir.Function, merge_block: ir.BasicBlock) ?GenericCfgPointerPhiLoad {
    if (merge_block.instructions.items.len != 2) return null;
    const phi_instruction = merge_block.instructions.items[0];
    const load_instruction = merge_block.instructions.items[1];
    if (phi_instruction.removed or load_instruction.removed) return null;
    const phi_name = phi_instruction.result orelse return null;
    const load_name = load_instruction.result orelse return null;
    const phi = switch (phi_instruction.kind) {
        .phi => |phi| phi,
        else => return null,
    };
    if (!phi.ty.eql(.ptr) or phi.incoming.items.len != 2) return null;
    for (phi.incoming.items) |incoming| {
        const ptr_name = switch (incoming.value) {
            .named => |name| name,
            else => return null,
        };
        if ((paramRegOrNull(function, ptr_name, .ptr) catch null) == null) return null;
    }
    const load = switch (load_instruction.kind) {
        .load => |load| load,
        else => return null,
    };
    if (!load.ty.eql(.{ .int = 32 }) or load.attrs.isBarrier() or !isNamed(load.ptr, phi_name)) return null;
    const ret = switch (merge_block.terminator orelse return null) {
        .ret => |ret| ret,
        else => return null,
    };
    if (!ret.ty.eql(.{ .int = 32 }) or !isNamed(ret.value orelse return null, load_name)) return null;
    return .{ .phi_name = phi_name, .load_name = load_name, .phi = phi };
}
