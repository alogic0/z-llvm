const std = @import("std");
const ir = @import("../ir.zig");
const target = @import("../target.zig");

pub const ParamReg = enum {
    edi,
    esi,

    pub fn name(reg: ParamReg) []const u8 {
        return switch (reg) {
            .edi => "%edi",
            .esi => "%esi",
        };
    }
};

pub const Instruction = union(enum) {
    mov_imm_eax: i32,
    mov_param_eax: ParamReg,
    add_param_eax: ParamReg,
    ret,
};

pub const MachineFunction = struct {
    name: []const u8,
    instructions: std.ArrayList(Instruction),

    pub fn init(name: []const u8) MachineFunction {
        return .{
            .name = name,
            .instructions = .empty,
        };
    }

    pub fn deinit(function: *MachineFunction, allocator: std.mem.Allocator) void {
        function.instructions.deinit(allocator);
    }
};

pub fn lowerFunction(allocator: std.mem.Allocator, triple_text: []const u8, function: ir.Function) !MachineFunction {
    const parsed_triple = try target.Triple.parse(triple_text);
    if (!parsed_triple.isX86_64() or !parsed_triple.isLinux()) return error.UnsupportedTarget;
    if (function.blocks.items.len != 1) return error.UnsupportedCodegenControlFlow;

    var machine = MachineFunction.init(function.name);
    errdefer machine.deinit(allocator);

    const block = function.blocks.items[0];
    const terminator = block.terminator orelse return error.BlockWithoutTerminator;
    switch (terminator) {
        .ret => |ret| {
            if (!ret.ty.eql(function.ret_ty)) return error.ReturnTypeMismatch;
            if (ret.ty == .void) {
                try machine.instructions.append(allocator, .ret);
                return machine;
            }
            if (!ret.ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenType;
            try lowerReturnValue(allocator, &machine, function, block, ret.value orelse return error.InvalidRet);
            try machine.instructions.append(allocator, .ret);
        },
        .br, .condbr, .@"unreachable" => return error.UnsupportedCodegenControlFlow,
    }

    return machine;
}

fn lowerReturnValue(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    value: ir.Value,
) !void {
    switch (value) {
        .int => |int| try machine.instructions.append(allocator, .{ .mov_imm_eax = try i32Value(int) }),
        .undef => return error.UnsupportedCodegenValue,
        .named => |name| {
            if (paramReg(function, name)) |reg| {
                try machine.instructions.append(allocator, .{ .mov_param_eax = reg });
                return;
            }
            const instruction = findInstruction(block, name) orelse return error.UnsupportedCodegenValue;
            switch (instruction.kind) {
                .binary => |binary| {
                    if (binary.op != .add or !binary.ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenInstruction;
                    const lhs = paramValueReg(function, binary.lhs) orelse return error.UnsupportedCodegenValue;
                    const rhs = paramValueReg(function, binary.rhs) orelse return error.UnsupportedCodegenValue;
                    try machine.instructions.append(allocator, .{ .mov_param_eax = lhs });
                    try machine.instructions.append(allocator, .{ .add_param_eax = rhs });
                },
                .cast, .freeze, .icmp, .select, .phi, .alloca, .load, .store, .gep => return error.UnsupportedCodegenInstruction,
            }
        },
    }
}

fn findInstruction(block: ir.BasicBlock, result_name: []const u8) ?ir.Instruction {
    for (block.instructions.items) |instruction| {
        if (instruction.removed) continue;
        const result = instruction.result orelse continue;
        if (std.mem.eql(u8, result, result_name)) return instruction;
    }
    return null;
}

fn paramValueReg(function: ir.Function, value: ir.Value) ?ParamReg {
    return switch (value) {
        .named => |name| paramReg(function, name),
        .int, .undef => null,
    };
}

fn paramReg(function: ir.Function, name: []const u8) ?ParamReg {
    for (function.params.items, 0..) |param, index| {
        if (!std.mem.eql(u8, param.name, name)) continue;
        if (!param.ty.eql(.{ .int = 32 })) return null;
        return switch (index) {
            0 => .edi,
            1 => .esi,
            else => null,
        };
    }
    return null;
}

fn i32Value(value: i128) !i32 {
    if (value < std.math.minInt(i32) or value > std.math.maxInt(i32)) return error.UnsupportedCodegenValue;
    return @intCast(value);
}
