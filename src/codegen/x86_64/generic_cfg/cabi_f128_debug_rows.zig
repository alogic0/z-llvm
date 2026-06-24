const std = @import("std");
const ir = @import("../../../ir.zig");
const x86_64_match = @import("../match.zig");

const isNamed = x86_64_match.isNamed;

fn blockIndex(function: ir.Function, name: []const u8) ?usize {
    return function.blockIndex(name);
}

pub fn validateDebugAssertPDShape(function: ir.Function) !void {
    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 11) return error.UnsupportedCodegenInstruction;

    const print_alloca = entry.instructions.items[0].result orelse return error.UnsupportedCodegenInstruction;
    switch (entry.instructions.items[0].kind) {
        .alloca => |alloca| if (!alloca.allocated_ty.eql(.{ .aggregate = "{ %main.PD }" })) return error.UnsupportedCodegenType,
        else => return error.UnsupportedCodegenInstruction,
    }
    const code_alloca = entry.instructions.items[1].result orelse return error.UnsupportedCodegenInstruction;
    switch (entry.instructions.items[1].kind) {
        .alloca => |alloca| if (!alloca.allocated_ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenType,
        else => return error.UnsupportedCodegenInstruction,
    }
    const pd_alloca = entry.instructions.items[2].result orelse return error.UnsupportedCodegenInstruction;
    switch (entry.instructions.items[2].kind) {
        .alloca => |alloca| if (!alloca.allocated_ty.eql(.{ .aggregate = "%main.PD" })) return error.UnsupportedCodegenType,
        else => return error.UnsupportedCodegenInstruction,
    }
    const raw_alloca = entry.instructions.items[3].result orelse return error.UnsupportedCodegenInstruction;
    switch (entry.instructions.items[3].kind) {
        .alloca => |alloca| if (!alloca.allocated_ty.eql(.{ .aggregate = "[16 x i8]" })) return error.UnsupportedCodegenType,
        else => return error.UnsupportedCodegenInstruction,
    }

    const ptr_store = switch (entry.instructions.items[4].kind) {
        .store => |store| store,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!ptr_store.ty.eql(.{ .int = 64 }) or !isNamed(ptr_store.value, function.params.items[0].name) or !isNamed(ptr_store.ptr, raw_alloca)) return error.UnsupportedCodegenValue;
    const double_slot = entry.instructions.items[5].result orelse return error.UnsupportedCodegenInstruction;
    const double_gep = switch (entry.instructions.items[5].kind) {
        .gep => |gep| gep,
        else => return error.UnsupportedCodegenInstruction,
    };
    try validateI8GepOffset(double_gep, raw_alloca, 8);
    const double_store = switch (entry.instructions.items[6].kind) {
        .store => |store| store,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!double_store.ty.eql(.double) or !isNamed(double_store.value, function.params.items[1].name) or !isNamed(double_store.ptr, double_slot)) return error.UnsupportedCodegenValue;
    try validateDebugF128Memcpy(entry.instructions.items[7], pd_alloca, raw_alloca, 16);
    try validateI32Store(entry.instructions.items[8], code_alloca, 0);
    const ptr_load_name = try validateNamedLoad(entry.instructions.items[9], .ptr, pd_alloca);
    const ptr_ne_name = entry.instructions.items[10].result orelse return error.UnsupportedCodegenInstruction;
    const ptr_ne = switch (entry.instructions.items[10].kind) {
        .icmp => |icmp| icmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (ptr_ne.predicate != .ne or !ptr_ne.operand_ty.eql(.ptr) or !isNamed(ptr_ne.lhs, ptr_load_name) or !ptr_ne.rhs.eql(.null_value)) return error.UnsupportedCodegenInstruction;
    const ptr_branch = try validateDebugCondBr(entry, ptr_ne_name);

    const ptr_fail = function.blocks.items[blockIndex(function, ptr_branch.then_target) orelse return error.InvalidBranchTarget];
    if (ptr_fail.instructions.items.len != 1) return error.UnsupportedCodegenInstruction;
    try validateI32Store(ptr_fail.instructions.items[0], code_alloca, 1);
    const double_check_label = try validateTerminatorBr(ptr_fail);
    const ptr_ok = function.blocks.items[blockIndex(function, ptr_branch.else_target) orelse return error.InvalidBranchTarget];
    if (!std.mem.eql(u8, try validateEmptyBr(ptr_ok), double_check_label)) return error.UnsupportedCodegenControlFlow;

    const double_check = function.blocks.items[blockIndex(function, double_check_label) orelse return error.InvalidBranchTarget];
    if (double_check.instructions.items.len != 3) return error.UnsupportedCodegenInstruction;
    const loaded_double_slot = double_check.instructions.items[0].result orelse return error.UnsupportedCodegenInstruction;
    const loaded_double_gep = switch (double_check.instructions.items[0].kind) {
        .gep => |gep| gep,
        else => return error.UnsupportedCodegenInstruction,
    };
    try validateI8GepOffset(loaded_double_gep, pd_alloca, 8);
    const loaded_double = try validateNamedLoad(double_check.instructions.items[1], .double, loaded_double_slot);
    const double_ne_name = double_check.instructions.items[2].result orelse return error.UnsupportedCodegenInstruction;
    const double_ne = switch (double_check.instructions.items[2].kind) {
        .fcmp => |fcmp| fcmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (double_ne.predicate != .une or !double_ne.operand_ty.eql(.double) or !isNamed(double_ne.lhs, loaded_double)) return error.UnsupportedCodegenInstruction;
    switch (double_ne.rhs) {
        .fp => |text| if (!std.mem.eql(u8, text, "5.000000e-01")) return error.UnsupportedCodegenValue,
        .named, .int, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    }
    const double_branch = try validateDebugCondBr(double_check, double_ne_name);

    const double_fail = function.blocks.items[blockIndex(function, double_branch.then_target) orelse return error.InvalidBranchTarget];
    if (double_fail.instructions.items.len != 1) return error.UnsupportedCodegenInstruction;
    try validateI32Store(double_fail.instructions.items[0], code_alloca, 2);
    const return_check_label = try validateTerminatorBr(double_fail);
    const double_ok = function.blocks.items[blockIndex(function, double_branch.else_target) orelse return error.InvalidBranchTarget];
    if (!std.mem.eql(u8, try validateEmptyBr(double_ok), return_check_label)) return error.UnsupportedCodegenControlFlow;

    const return_check = function.blocks.items[blockIndex(function, return_check_label) orelse return error.InvalidBranchTarget];
    if (return_check.instructions.items.len != 2) return error.UnsupportedCodegenInstruction;
    const code_for_check = try validateNamedLoad(return_check.instructions.items[0], .{ .int = 32 }, code_alloca);
    const code_nonzero_name = return_check.instructions.items[1].result orelse return error.UnsupportedCodegenInstruction;
    const code_nonzero = switch (return_check.instructions.items[1].kind) {
        .icmp => |icmp| icmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (code_nonzero.predicate != .ne or !code_nonzero.operand_ty.eql(.{ .int = 32 }) or !isNamed(code_nonzero.lhs, code_for_check) or !code_nonzero.rhs.eql(.{ .int = 0 })) return error.UnsupportedCodegenValue;
    const print_branch = try validateDebugCondBr(return_check, code_nonzero_name);

    const print_block = function.blocks.items[blockIndex(function, print_branch.then_target) orelse return error.InvalidBranchTarget];
    if (print_block.instructions.items.len != 2) return error.UnsupportedCodegenInstruction;
    try validateDebugF128Memcpy(print_block.instructions.items[0], print_alloca, raw_alloca, 16);
    const print_call = switch (print_block.instructions.items[1].kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!std.mem.startsWith(u8, print_call.callee, "debug.print__anon_") or print_call.ret_ty != .void) return error.UnsupportedCodegenInstruction;
    const return_label = try validateTerminatorBr(print_block);
    const no_print = function.blocks.items[blockIndex(function, print_branch.else_target) orelse return error.InvalidBranchTarget];
    if (!std.mem.eql(u8, try validateEmptyBr(no_print), return_label)) return error.UnsupportedCodegenControlFlow;

    const return_block = function.blocks.items[blockIndex(function, return_label) orelse return error.InvalidBranchTarget];
    if (return_block.instructions.items.len != 1) return error.UnsupportedCodegenInstruction;
    const ret_code = try validateNamedLoad(return_block.instructions.items[0], .{ .int = 32 }, code_alloca);
    const ret = switch (return_block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!ret.ty.eql(.{ .int = 32 }) or !isNamed(ret.value orelse return error.InvalidRet, ret_code)) return error.UnsupportedCodegenValue;
}

pub fn validateDebugRetPD(block: ir.BasicBlock) !void {
    const alloca_name = block.instructions.items[0].result orelse return error.UnsupportedCodegenInstruction;
    switch (block.instructions.items[0].kind) {
        .alloca => |alloca| if (!alloca.allocated_ty.eql(.{ .aggregate = "%main.PD" })) return error.UnsupportedCodegenType,
        else => return error.UnsupportedCodegenInstruction,
    }
    const ptr_store = switch (block.instructions.items[1].kind) {
        .store => |store| store,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!ptr_store.ty.eql(.ptr) or !isNamed(ptr_store.ptr, alloca_name) or !ptr_store.value.eql(.null_value)) return error.UnsupportedCodegenValue;
    const double_slot = block.instructions.items[2].result orelse return error.UnsupportedCodegenInstruction;
    const double_gep = switch (block.instructions.items[2].kind) {
        .gep => |gep| gep,
        else => return error.UnsupportedCodegenInstruction,
    };
    try validateI8GepOffset(double_gep, alloca_name, 8);
    const double_store = switch (block.instructions.items[3].kind) {
        .store => |store| store,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!double_store.ty.eql(.double) or !isNamed(double_store.ptr, double_slot)) return error.UnsupportedCodegenValue;
    switch (double_store.value) {
        .fp => |text| if (!std.mem.eql(u8, text, "5.000000e-01")) return error.UnsupportedCodegenValue,
        .named, .int, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    }
    const load_name = try validateNamedLoad(block.instructions.items[4], .{ .aggregate = "{ i64, double }" }, alloca_name);
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!ret.ty.eql(.{ .aggregate = "{ i64, double }" }) or !isNamed(ret.value orelse return error.InvalidRet, load_name)) return error.InvalidRet;
}

pub fn validateDebugRetCFF(block: ir.BasicBlock) !void {
    const alloca_name = block.instructions.items[0].result orelse return error.UnsupportedCodegenInstruction;
    switch (block.instructions.items[0].kind) {
        .alloca => |alloca| if (!alloca.allocated_ty.eql(.{ .aggregate = "%main.CFF" })) return error.UnsupportedCodegenType,
        else => return error.UnsupportedCodegenInstruction,
    }
    const low_store = switch (block.instructions.items[1].kind) {
        .store => |store| store,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!low_store.ty.eql(.{ .int = 8 }) or !isNamed(low_store.ptr, alloca_name) or !low_store.value.eql(.{ .int = 39 })) return error.UnsupportedCodegenValue;
    const payload_slot = block.instructions.items[2].result orelse return error.UnsupportedCodegenInstruction;
    const payload_gep = switch (block.instructions.items[2].kind) {
        .gep => |gep| gep,
        else => return error.UnsupportedCodegenInstruction,
    };
    try validateI8GepOffset(payload_gep, alloca_name, 4);
    try validateFloatStore(block.instructions.items[3], payload_slot, .float, "8.750000e-01");
    const arg_slot = block.instructions.items[4].result orelse return error.UnsupportedCodegenInstruction;
    const arg_gep = switch (block.instructions.items[4].kind) {
        .gep => |gep| gep,
        else => return error.UnsupportedCodegenInstruction,
    };
    try validateI8GepOffset(arg_gep, alloca_name, 8);
    try validateFloatStore(block.instructions.items[5], arg_slot, .float, "1.000000e+00");
    const load_name = try validateNamedLoad(block.instructions.items[6], .{ .aggregate = "{ i64, float }" }, alloca_name);
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!ret.ty.eql(.{ .aggregate = "{ i64, float }" }) or !isNamed(ret.value orelse return error.InvalidRet, load_name)) return error.InvalidRet;
}

pub fn validateDebugRetDC(block: ir.BasicBlock) !void {
    const alloca_name = block.instructions.items[0].result orelse return error.UnsupportedCodegenInstruction;
    switch (block.instructions.items[0].kind) {
        .alloca => |alloca| if (!alloca.allocated_ty.eql(.{ .aggregate = "%main.DC" })) return error.UnsupportedCodegenType,
        else => return error.UnsupportedCodegenInstruction,
    }
    try validateFloatStore(block.instructions.items[1], alloca_name, .double, "-2.500000e-01");
    const byte_slot = block.instructions.items[2].result orelse return error.UnsupportedCodegenInstruction;
    const byte_gep = switch (block.instructions.items[2].kind) {
        .gep => |gep| gep,
        else => return error.UnsupportedCodegenInstruction,
    };
    try validateI8GepOffset(byte_gep, alloca_name, 8);
    const byte_store = switch (block.instructions.items[3].kind) {
        .store => |store| store,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!byte_store.ty.eql(.{ .int = 8 }) or !isNamed(byte_store.ptr, byte_slot) or !byte_store.value.eql(.{ .int = 15 })) return error.UnsupportedCodegenValue;
    const load_name = try validateNamedLoad(block.instructions.items[4], .{ .aggregate = "{ double, i64 }" }, alloca_name);
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!ret.ty.eql(.{ .aggregate = "{ double, i64 }" }) or !isNamed(ret.value orelse return error.InvalidRet, load_name)) return error.InvalidRet;
}

pub fn validateDebugStackLoadReturn(block: ir.BasicBlock, alloca_ty: ir.Type, ret_ty: ir.Type) !void {
    if (block.instructions.items.len < 2) return error.UnsupportedCodegenInstruction;
    const alloca_name = block.instructions.items[0].result orelse return error.UnsupportedCodegenInstruction;
    switch (block.instructions.items[0].kind) {
        .alloca => |alloca| if (!alloca.allocated_ty.eql(alloca_ty)) return error.UnsupportedCodegenType,
        else => return error.UnsupportedCodegenInstruction,
    }
    for (block.instructions.items[1 .. block.instructions.items.len - 1]) |instruction| {
        if (instruction.result != null) {
            switch (instruction.kind) {
                .gep => {},
                else => return error.UnsupportedCodegenInstruction,
            }
        } else {
            switch (instruction.kind) {
                .store => {},
                else => return error.UnsupportedCodegenInstruction,
            }
        }
    }
    const load_name = try validateNamedLoad(block.instructions.items[block.instructions.items.len - 1], ret_ty, alloca_name);
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!ret.ty.eql(ret_ty) or !isNamed(ret.value orelse return error.InvalidRet, load_name)) return error.InvalidRet;
}

pub fn validateDebugAssertCFFShape(function: ir.Function) !void {
    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 11) return error.UnsupportedCodegenInstruction;

    const print_alloca = entry.instructions.items[0].result orelse return error.UnsupportedCodegenInstruction;
    switch (entry.instructions.items[0].kind) {
        .alloca => |alloca| if (!alloca.allocated_ty.eql(.{ .aggregate = "{ %main.CFF }" })) return error.UnsupportedCodegenType,
        else => return error.UnsupportedCodegenInstruction,
    }
    const code_alloca = entry.instructions.items[1].result orelse return error.UnsupportedCodegenInstruction;
    switch (entry.instructions.items[1].kind) {
        .alloca => |alloca| if (!alloca.allocated_ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenType,
        else => return error.UnsupportedCodegenInstruction,
    }
    const cff_alloca = entry.instructions.items[2].result orelse return error.UnsupportedCodegenInstruction;
    switch (entry.instructions.items[2].kind) {
        .alloca => |alloca| if (!alloca.allocated_ty.eql(.{ .aggregate = "%main.CFF" })) return error.UnsupportedCodegenType,
        else => return error.UnsupportedCodegenInstruction,
    }
    const raw_alloca = entry.instructions.items[3].result orelse return error.UnsupportedCodegenInstruction;
    switch (entry.instructions.items[3].kind) {
        .alloca => |alloca| if (!alloca.allocated_ty.eql(.{ .aggregate = "[16 x i8]" })) return error.UnsupportedCodegenType,
        else => return error.UnsupportedCodegenInstruction,
    }

    const packed_store = switch (entry.instructions.items[4].kind) {
        .store => |store| store,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!packed_store.ty.eql(.{ .int = 64 }) or !isNamed(packed_store.value, function.params.items[0].name) or !isNamed(packed_store.ptr, raw_alloca)) return error.UnsupportedCodegenValue;
    const arg_slot = entry.instructions.items[5].result orelse return error.UnsupportedCodegenInstruction;
    const arg_gep = switch (entry.instructions.items[5].kind) {
        .gep => |gep| gep,
        else => return error.UnsupportedCodegenInstruction,
    };
    try validateI8GepOffset(arg_gep, raw_alloca, 8);
    const arg_store = switch (entry.instructions.items[6].kind) {
        .store => |store| store,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!arg_store.ty.eql(.float) or !isNamed(arg_store.value, function.params.items[1].name) or !isNamed(arg_store.ptr, arg_slot)) return error.UnsupportedCodegenValue;
    try validateDebugF128Memcpy(entry.instructions.items[7], cff_alloca, raw_alloca, 12);
    try validateI32Store(entry.instructions.items[8], code_alloca, 0);
    const low_name = try validateNamedLoad(entry.instructions.items[9], .{ .int = 8 }, cff_alloca);
    const low_ne_name = try validateIcmpImm(entry.instructions.items[10], .ne, .{ .int = 8 }, low_name, 39);
    const low_branch = try validateDebugCondBr(entry, low_ne_name);

    const low_fail = function.blocks.items[blockIndex(function, low_branch.then_target) orelse return error.InvalidBranchTarget];
    if (low_fail.instructions.items.len != 1) return error.UnsupportedCodegenInstruction;
    try validateI32Store(low_fail.instructions.items[0], code_alloca, 1);
    const payload_check_label = try validateTerminatorBr(low_fail);
    const low_ok = function.blocks.items[blockIndex(function, low_branch.else_target) orelse return error.InvalidBranchTarget];
    if (!std.mem.eql(u8, try validateEmptyBr(low_ok), payload_check_label)) return error.UnsupportedCodegenControlFlow;

    const payload_check = function.blocks.items[blockIndex(function, payload_check_label) orelse return error.InvalidBranchTarget];
    if (payload_check.instructions.items.len != 3) return error.UnsupportedCodegenInstruction;
    const payload_slot = payload_check.instructions.items[0].result orelse return error.UnsupportedCodegenInstruction;
    const payload_gep = switch (payload_check.instructions.items[0].kind) {
        .gep => |gep| gep,
        else => return error.UnsupportedCodegenInstruction,
    };
    try validateI8GepOffset(payload_gep, cff_alloca, 4);
    const payload_name = try validateNamedLoad(payload_check.instructions.items[1], .float, payload_slot);
    const payload_ne_name = try validateFcmpImm(payload_check.instructions.items[2], .une, .float, payload_name, "8.750000e-01");
    const payload_branch = try validateDebugCondBr(payload_check, payload_ne_name);

    const payload_fail = function.blocks.items[blockIndex(function, payload_branch.then_target) orelse return error.InvalidBranchTarget];
    if (payload_fail.instructions.items.len != 1) return error.UnsupportedCodegenInstruction;
    try validateI32Store(payload_fail.instructions.items[0], code_alloca, 2);
    const arg_check_label = try validateTerminatorBr(payload_fail);
    const payload_ok = function.blocks.items[blockIndex(function, payload_branch.else_target) orelse return error.InvalidBranchTarget];
    if (!std.mem.eql(u8, try validateEmptyBr(payload_ok), arg_check_label)) return error.UnsupportedCodegenControlFlow;

    const arg_check = function.blocks.items[blockIndex(function, arg_check_label) orelse return error.InvalidBranchTarget];
    if (arg_check.instructions.items.len != 3) return error.UnsupportedCodegenInstruction;
    const loaded_arg_slot = arg_check.instructions.items[0].result orelse return error.UnsupportedCodegenInstruction;
    const loaded_arg_gep = switch (arg_check.instructions.items[0].kind) {
        .gep => |gep| gep,
        else => return error.UnsupportedCodegenInstruction,
    };
    try validateI8GepOffset(loaded_arg_gep, cff_alloca, 8);
    const loaded_arg = try validateNamedLoad(arg_check.instructions.items[1], .float, loaded_arg_slot);
    const arg_ne_name = try validateFcmpImm(arg_check.instructions.items[2], .une, .float, loaded_arg, "1.000000e+00");
    const arg_branch = try validateDebugCondBr(arg_check, arg_ne_name);

    const arg_fail = function.blocks.items[blockIndex(function, arg_branch.then_target) orelse return error.InvalidBranchTarget];
    if (arg_fail.instructions.items.len != 1) return error.UnsupportedCodegenInstruction;
    try validateI32Store(arg_fail.instructions.items[0], code_alloca, 3);
    const return_check_label = try validateTerminatorBr(arg_fail);
    const arg_ok = function.blocks.items[blockIndex(function, arg_branch.else_target) orelse return error.InvalidBranchTarget];
    if (!std.mem.eql(u8, try validateEmptyBr(arg_ok), return_check_label)) return error.UnsupportedCodegenControlFlow;

    try validateDebugReturnCodeTail(function, return_check_label, code_alloca, print_alloca, raw_alloca, 12);
}

pub fn validateDebugAssertDCShape(function: ir.Function) !void {
    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 11) return error.UnsupportedCodegenInstruction;

    const print_alloca = entry.instructions.items[0].result orelse return error.UnsupportedCodegenInstruction;
    switch (entry.instructions.items[0].kind) {
        .alloca => |alloca| if (!alloca.allocated_ty.eql(.{ .aggregate = "{ %main.DC }" })) return error.UnsupportedCodegenType,
        else => return error.UnsupportedCodegenInstruction,
    }
    const code_alloca = entry.instructions.items[1].result orelse return error.UnsupportedCodegenInstruction;
    switch (entry.instructions.items[1].kind) {
        .alloca => |alloca| if (!alloca.allocated_ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenType,
        else => return error.UnsupportedCodegenInstruction,
    }
    const dc_alloca = entry.instructions.items[2].result orelse return error.UnsupportedCodegenInstruction;
    switch (entry.instructions.items[2].kind) {
        .alloca => |alloca| if (!alloca.allocated_ty.eql(.{ .aggregate = "%main.DC" })) return error.UnsupportedCodegenType,
        else => return error.UnsupportedCodegenInstruction,
    }
    const raw_alloca = entry.instructions.items[3].result orelse return error.UnsupportedCodegenInstruction;
    switch (entry.instructions.items[3].kind) {
        .alloca => |alloca| if (!alloca.allocated_ty.eql(.{ .aggregate = "[16 x i8]" })) return error.UnsupportedCodegenType,
        else => return error.UnsupportedCodegenInstruction,
    }

    const double_store = switch (entry.instructions.items[4].kind) {
        .store => |store| store,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!double_store.ty.eql(.double) or !isNamed(double_store.value, function.params.items[0].name) or !isNamed(double_store.ptr, raw_alloca)) return error.UnsupportedCodegenValue;
    const raw_int_slot = entry.instructions.items[5].result orelse return error.UnsupportedCodegenInstruction;
    const raw_int_gep = switch (entry.instructions.items[5].kind) {
        .gep => |gep| gep,
        else => return error.UnsupportedCodegenInstruction,
    };
    try validateI8GepOffset(raw_int_gep, raw_alloca, 8);
    const int_store = switch (entry.instructions.items[6].kind) {
        .store => |store| store,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!int_store.ty.eql(.{ .int = 64 }) or !isNamed(int_store.value, function.params.items[1].name) or !isNamed(int_store.ptr, raw_int_slot)) return error.UnsupportedCodegenValue;
    try validateDebugF128Memcpy(entry.instructions.items[7], dc_alloca, raw_alloca, 16);
    try validateI32Store(entry.instructions.items[8], code_alloca, 0);
    const double_name = try validateNamedLoad(entry.instructions.items[9], .double, dc_alloca);
    const double_ne_name = try validateFcmpImm(entry.instructions.items[10], .une, .double, double_name, "-2.500000e-01");
    const double_branch = try validateDebugCondBr(entry, double_ne_name);

    const double_fail = function.blocks.items[blockIndex(function, double_branch.then_target) orelse return error.InvalidBranchTarget];
    if (double_fail.instructions.items.len != 1) return error.UnsupportedCodegenInstruction;
    try validateI32Store(double_fail.instructions.items[0], code_alloca, 1);
    const low_check_label = try validateTerminatorBr(double_fail);
    const double_ok = function.blocks.items[blockIndex(function, double_branch.else_target) orelse return error.InvalidBranchTarget];
    if (!std.mem.eql(u8, try validateEmptyBr(double_ok), low_check_label)) return error.UnsupportedCodegenControlFlow;

    const low_check = function.blocks.items[blockIndex(function, low_check_label) orelse return error.InvalidBranchTarget];
    if (low_check.instructions.items.len != 3) return error.UnsupportedCodegenInstruction;
    const low_slot = low_check.instructions.items[0].result orelse return error.UnsupportedCodegenInstruction;
    const low_gep = switch (low_check.instructions.items[0].kind) {
        .gep => |gep| gep,
        else => return error.UnsupportedCodegenInstruction,
    };
    try validateI8GepOffset(low_gep, dc_alloca, 8);
    const low_name = try validateNamedLoad(low_check.instructions.items[1], .{ .int = 8 }, low_slot);
    const low_ne_name = try validateIcmpImm(low_check.instructions.items[2], .ne, .{ .int = 8 }, low_name, 15);
    const low_branch = try validateDebugCondBr(low_check, low_ne_name);

    const low_fail = function.blocks.items[blockIndex(function, low_branch.then_target) orelse return error.InvalidBranchTarget];
    if (low_fail.instructions.items.len != 1) return error.UnsupportedCodegenInstruction;
    try validateI32Store(low_fail.instructions.items[0], code_alloca, 2);
    const return_check_label = try validateTerminatorBr(low_fail);
    const low_ok = function.blocks.items[blockIndex(function, low_branch.else_target) orelse return error.InvalidBranchTarget];
    if (!std.mem.eql(u8, try validateEmptyBr(low_ok), return_check_label)) return error.UnsupportedCodegenControlFlow;

    try validateDebugReturnCodeTail(function, return_check_label, code_alloca, print_alloca, raw_alloca, 16);
}

pub fn validateDebugReturnCodeTail(
    function: ir.Function,
    return_check_label: []const u8,
    code_alloca: []const u8,
    print_alloca: []const u8,
    raw_alloca: []const u8,
    print_size: i128,
) !void {
    const return_check = function.blocks.items[blockIndex(function, return_check_label) orelse return error.InvalidBranchTarget];
    if (return_check.instructions.items.len != 2) return error.UnsupportedCodegenInstruction;
    const code_for_check = try validateNamedLoad(return_check.instructions.items[0], .{ .int = 32 }, code_alloca);
    const code_nonzero_name = try validateIcmpImm(return_check.instructions.items[1], .ne, .{ .int = 32 }, code_for_check, 0);
    const print_branch = try validateDebugCondBr(return_check, code_nonzero_name);

    const print_block = function.blocks.items[blockIndex(function, print_branch.then_target) orelse return error.InvalidBranchTarget];
    if (print_block.instructions.items.len != 2) return error.UnsupportedCodegenInstruction;
    try validateDebugF128Memcpy(print_block.instructions.items[0], print_alloca, raw_alloca, print_size);
    const print_call = switch (print_block.instructions.items[1].kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!std.mem.startsWith(u8, print_call.callee, "debug.print__anon_") or print_call.ret_ty != .void) return error.UnsupportedCodegenInstruction;
    const return_label = try validateTerminatorBr(print_block);
    const no_print = function.blocks.items[blockIndex(function, print_branch.else_target) orelse return error.InvalidBranchTarget];
    if (!std.mem.eql(u8, try validateEmptyBr(no_print), return_label)) return error.UnsupportedCodegenControlFlow;

    const return_block = function.blocks.items[blockIndex(function, return_label) orelse return error.InvalidBranchTarget];
    if (return_block.instructions.items.len != 1) return error.UnsupportedCodegenInstruction;
    const ret_code = try validateNamedLoad(return_block.instructions.items[0], .{ .int = 32 }, code_alloca);
    const ret = switch (return_block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!ret.ty.eql(.{ .int = 32 }) or !isNamed(ret.value orelse return error.InvalidRet, ret_code)) return error.UnsupportedCodegenValue;
}

pub fn validateF128AggregateRet(block: ir.BasicBlock, expected: []const u8) !void {
    if (block.instructions.items.len != 0) return error.UnsupportedCodegenInstruction;
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!ret.ty.eql(.{ .aggregate = "{ fp128 }" })) return error.ReturnTypeMismatch;
    const value = ret.value orelse return error.InvalidRet;
    switch (value) {
        .constant_expr => |text| {
            var expected_text_buffer: [96]u8 = undefined;
            const expected_text = try std.fmt.bufPrint(&expected_text_buffer, "{{ fp128 {s} }}", .{expected});
            if (!std.mem.eql(u8, text, expected_text)) return error.UnsupportedCodegenValue;
        },
        .named, .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector => return error.UnsupportedCodegenValue,
    }
}

pub fn validateF128ScalarRet(block: ir.BasicBlock, expected: []const u8) !void {
    if (block.instructions.items.len != 0) return error.UnsupportedCodegenInstruction;
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!ret.ty.eql(.fp128)) return error.ReturnTypeMismatch;
    const value = ret.value orelse return error.InvalidRet;
    switch (value) {
        .fp => |text| if (!std.mem.eql(u8, text, expected)) return error.UnsupportedCodegenValue,
        .named, .int, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    }
}

pub const F128Branch = struct {
    then_label: []const u8,
    else_label: []const u8,
    second_load: []const u8,
};

pub const DebugF128Sret = struct {
    first_panic_label: []const u8,
    second_panic_label: []const u8,
};

pub fn validateDebugF128Sret(function: ir.Function) !DebugF128Sret {
    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 7) return error.UnsupportedCodegenInstruction;

    const alloca_name = entry.instructions.items[0].result orelse return error.UnsupportedCodegenInstruction;
    switch (entry.instructions.items[0].kind) {
        .alloca => |alloca| if (!alloca.allocated_ty.eql(.{ .aggregate = "%main.f128_f128_struct" })) return error.UnsupportedCodegenType,
        else => return error.UnsupportedCodegenInstruction,
    }

    try validateDebugF128Memcpy(entry.instructions.items[1], alloca_name, function.params.items[1].name, 32);
    const first_load_name = try validateDebugF128Load(entry.instructions.items[2], alloca_name);
    const first_call_name = try validateDebugF128EqCall(entry.instructions.items[3], first_load_name, "0xL00000000000000004002A00000000000");
    const first_eq_name = try validateDebugEqZeroI32(entry.instructions.items[4], first_call_name);
    const first_expect_name = try validateDebugTestingExpect(entry.instructions.items[5], first_eq_name);
    const first_ok_name = try validateDebugEqZeroI16(entry.instructions.items[6], first_expect_name);
    const first_branch = try validateDebugCondBr(entry, first_ok_name);

    const first_bridge = function.blocks.items[blockIndex(function, first_branch.then_target) orelse return error.InvalidBranchTarget];
    const second_label = try validateEmptyBr(first_bridge);
    const second = function.blocks.items[blockIndex(function, second_label) orelse return error.InvalidBranchTarget];
    if (second.instructions.items.len != 6) return error.UnsupportedCodegenInstruction;
    const second_gep_name = second.instructions.items[0].result orelse return error.UnsupportedCodegenInstruction;
    const gep = switch (second.instructions.items[0].kind) {
        .gep => |gep| gep,
        else => return error.UnsupportedCodegenInstruction,
    };
    try validateI8GepOffset(gep, alloca_name, 16);
    const second_load_name = try validateDebugF128Load(second.instructions.items[1], second_gep_name);
    const second_call_name = try validateDebugF128EqCall(second.instructions.items[2], second_load_name, "0xL00000000000000004004C80000000000");
    const second_eq_name = try validateDebugEqZeroI32(second.instructions.items[3], second_call_name);
    const second_expect_name = try validateDebugTestingExpect(second.instructions.items[4], second_eq_name);
    const second_ok_name = try validateDebugEqZeroI16(second.instructions.items[5], second_expect_name);
    const second_branch = try validateDebugCondBr(second, second_ok_name);

    const success_bridge = function.blocks.items[blockIndex(function, second_branch.then_target) orelse return error.InvalidBranchTarget];
    const success_label = try validateEmptyBr(success_bridge);
    const success = function.blocks.items[blockIndex(function, success_label) orelse return error.InvalidBranchTarget];
    try validateF128SretSuccess(success, function.params.items[0].name);
    try validateDebugPanicUnreachableBlock(function.blocks.items[blockIndex(function, first_branch.else_target) orelse return error.InvalidBranchTarget]);
    try validateDebugPanicUnreachableBlock(function.blocks.items[blockIndex(function, second_branch.else_target) orelse return error.InvalidBranchTarget]);

    return .{
        .first_panic_label = first_branch.else_target,
        .second_panic_label = second_branch.else_target,
    };
}

pub fn validateDebugF128AggregateReturn(function: ir.Function) !struct { panic_label: []const u8 } {
    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 10) return error.UnsupportedCodegenInstruction;

    const result_alloca = entry.instructions.items[0].result orelse return error.UnsupportedCodegenInstruction;
    switch (entry.instructions.items[0].kind) {
        .alloca => |alloca| if (!alloca.allocated_ty.eql(.{ .aggregate = "%main.f128_struct" })) return error.UnsupportedCodegenType,
        else => return error.UnsupportedCodegenInstruction,
    }
    const arg_alloca = entry.instructions.items[1].result orelse return error.UnsupportedCodegenInstruction;
    switch (entry.instructions.items[1].kind) {
        .alloca => |alloca| if (!alloca.allocated_ty.eql(.{ .aggregate = "%main.f128_struct" })) return error.UnsupportedCodegenType,
        else => return error.UnsupportedCodegenInstruction,
    }
    const raw_alloca = entry.instructions.items[2].result orelse return error.UnsupportedCodegenInstruction;
    switch (entry.instructions.items[2].kind) {
        .alloca => |alloca| if (!alloca.allocated_ty.eql(.{ .aggregate = "[16 x i8]" })) return error.UnsupportedCodegenType,
        else => return error.UnsupportedCodegenInstruction,
    }

    const param_store = switch (entry.instructions.items[3].kind) {
        .store => |store| store,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!param_store.ty.eql(.fp128) or !isNamed(param_store.value, function.params.items[0].name) or !isNamed(param_store.ptr, raw_alloca)) return error.UnsupportedCodegenValue;
    try validateDebugF128Memcpy(entry.instructions.items[4], arg_alloca, raw_alloca, 16);
    const load_name = try validateDebugF128Load(entry.instructions.items[5], arg_alloca);
    const call_name = try validateDebugF128EqCall(entry.instructions.items[6], load_name, "0xL0000000000000000400C81C800000000");
    const eq_name = try validateDebugEqZeroI32(entry.instructions.items[7], call_name);
    const expect_name = try validateDebugTestingExpect(entry.instructions.items[8], eq_name);
    const ok_name = try validateDebugEqZeroI16(entry.instructions.items[9], expect_name);
    const branch = try validateDebugCondBr(entry, ok_name);

    const bridge = function.blocks.items[blockIndex(function, branch.then_target) orelse return error.InvalidBranchTarget];
    const success_label = try validateEmptyBr(bridge);
    const success = function.blocks.items[blockIndex(function, success_label) orelse return error.InvalidBranchTarget];
    try validateDebugF128AggregateSuccess(success, result_alloca);
    try validateDebugPanicUnreachableBlock(function.blocks.items[blockIndex(function, branch.else_target) orelse return error.InvalidBranchTarget]);
    return .{ .panic_label = branch.else_target };
}

pub fn validateDebugF128AggregateSuccess(block: ir.BasicBlock, result_alloca: []const u8) !void {
    if (block.instructions.items.len != 2) return error.UnsupportedCodegenInstruction;
    const store = switch (block.instructions.items[0].kind) {
        .store => |store| store,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!store.ty.eql(.fp128) or !isNamed(store.ptr, result_alloca)) return error.UnsupportedCodegenInstruction;
    switch (store.value) {
        .fp => |text| if (!std.mem.eql(u8, text, "0xL0000000000000000400F81CD00000000")) return error.UnsupportedCodegenValue,
        .named, .int, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    }

    const load_name = block.instructions.items[1].result orelse return error.UnsupportedCodegenInstruction;
    const load = switch (block.instructions.items[1].kind) {
        .load => |load| load,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!load.ty.eql(.{ .aggregate = "{ fp128 }" }) or load.attrs.isBarrier() or !isNamed(load.ptr, result_alloca)) return error.UnsupportedCodegenInstruction;

    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!ret.ty.eql(.{ .aggregate = "{ fp128 }" }) or !(ret.value orelse return error.InvalidRet).eql(.{ .named = load_name })) return error.InvalidRet;
}

pub fn validateDebugF128ScalarReturn(function: ir.Function) !struct { panic_label: []const u8 } {
    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 4) return error.UnsupportedCodegenInstruction;

    const call_name = try validateDebugF128EqCall(entry.instructions.items[0], function.params.items[0].name, "0xL00000000000000004002800000000000");
    const eq_name = try validateDebugEqZeroI32(entry.instructions.items[1], call_name);
    const expect_name = try validateDebugTestingExpect(entry.instructions.items[2], eq_name);
    const ok_name = try validateDebugEqZeroI16(entry.instructions.items[3], expect_name);
    const branch = try validateDebugCondBr(entry, ok_name);

    const bridge = function.blocks.items[blockIndex(function, branch.then_target) orelse return error.InvalidBranchTarget];
    const success_label = try validateEmptyBr(bridge);
    const success = function.blocks.items[blockIndex(function, success_label) orelse return error.InvalidBranchTarget];
    try validateF128ScalarRet(success, "0xL00000000000000004004100000000000");
    try validateDebugPanicUnreachableBlock(function.blocks.items[blockIndex(function, branch.else_target) orelse return error.InvalidBranchTarget]);
    return .{ .panic_label = branch.else_target };
}

pub fn validateDebugF128Memcpy(instruction: ir.Instruction, dst_name: []const u8, src_name: []const u8, expected_size: i128) !void {
    if (instruction.result != null) return error.UnsupportedCodegenInstruction;
    const call = switch (instruction.kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!std.mem.eql(u8, call.callee, "llvm.memcpy.p0.p0.i64") or call.ret_ty != .void or call.args.items.len != 4) return error.UnsupportedCodegenInstruction;
    if (!call.args.items[0].ty.eql(.ptr) or !isNamed(call.args.items[0].value, dst_name)) return error.UnsupportedCodegenValue;
    if (!call.args.items[1].ty.eql(.ptr) or !isNamed(call.args.items[1].value, src_name)) return error.UnsupportedCodegenValue;
    if (!call.args.items[2].ty.eql(.{ .int = 64 }) or !call.args.items[2].value.eql(.{ .int = expected_size })) return error.UnsupportedCodegenValue;
    if (!call.args.items[3].ty.eql(.{ .int = 1 }) or !call.args.items[3].value.eql(.{ .int = 0 })) return error.UnsupportedCodegenValue;
}

pub fn validateDebugF128Load(instruction: ir.Instruction, ptr_name: []const u8) ![]const u8 {
    const result = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const load = switch (instruction.kind) {
        .load => |load| load,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!load.ty.eql(.fp128) or load.attrs.isBarrier() or !isNamed(load.ptr, ptr_name)) return error.UnsupportedCodegenInstruction;
    return result;
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

pub fn validateI32Store(instruction: ir.Instruction, ptr_name: []const u8, expected_value: i128) !void {
    if (instruction.result != null) return error.UnsupportedCodegenInstruction;
    const store = switch (instruction.kind) {
        .store => |store| store,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!store.ty.eql(.{ .int = 32 }) or !isNamed(store.ptr, ptr_name) or !store.value.eql(.{ .int = expected_value })) return error.UnsupportedCodegenValue;
}

pub fn validateIcmpImm(instruction: ir.Instruction, predicate: ir.IcmpPredicate, ty: ir.Type, lhs_name: []const u8, rhs_value: i128) ![]const u8 {
    const result = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const icmp = switch (instruction.kind) {
        .icmp => |icmp| icmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (icmp.predicate != predicate or !icmp.operand_ty.eql(ty) or !isNamed(icmp.lhs, lhs_name) or !icmp.rhs.eql(.{ .int = rhs_value })) return error.UnsupportedCodegenValue;
    return result;
}

pub fn validateFcmpImm(instruction: ir.Instruction, predicate: ir.FcmpPredicate, ty: ir.Type, lhs_name: []const u8, rhs_value: []const u8) ![]const u8 {
    const result = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const fcmp = switch (instruction.kind) {
        .fcmp => |fcmp| fcmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (fcmp.predicate != predicate or !fcmp.operand_ty.eql(ty) or !isNamed(fcmp.lhs, lhs_name)) return error.UnsupportedCodegenValue;
    switch (fcmp.rhs) {
        .fp => |text| if (!std.mem.eql(u8, text, rhs_value)) return error.UnsupportedCodegenValue,
        .named, .int, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    }
    return result;
}

pub fn validateFloatStore(instruction: ir.Instruction, ptr_name: []const u8, expected_ty: ir.Type, expected_value: []const u8) !void {
    if (instruction.result != null) return error.UnsupportedCodegenInstruction;
    const store = switch (instruction.kind) {
        .store => |store| store,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!store.ty.eql(expected_ty) or !isNamed(store.ptr, ptr_name)) return error.UnsupportedCodegenValue;
    switch (store.value) {
        .fp => |text| if (!std.mem.eql(u8, text, expected_value)) return error.UnsupportedCodegenValue,
        .named, .int, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    }
}

pub fn validateDebugF128EqCall(instruction: ir.Instruction, lhs_name: []const u8, expected: []const u8) ![]const u8 {
    const result = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const call = switch (instruction.kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    try validateF128EqCall(call, lhs_name, expected);
    return result;
}

pub fn validateDebugEqZeroI32(instruction: ir.Instruction, call_name: []const u8) ![]const u8 {
    const result = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const icmp = switch (instruction.kind) {
        .icmp => |icmp| icmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    try validateEqZeroIcmp(icmp, call_name);
    return result;
}

pub fn validateDebugTestingExpect(instruction: ir.Instruction, cond_name: []const u8) ![]const u8 {
    const result = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const call = switch (instruction.kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!std.mem.eql(u8, call.callee, "testing.expect") or !call.ret_ty.eql(.{ .int = 16 }) or call.args.items.len != 1) return error.UnsupportedCodegenInstruction;
    if (!call.args.items[0].ty.eql(.{ .int = 1 }) or !isNamed(call.args.items[0].value, cond_name)) return error.UnsupportedCodegenValue;
    return result;
}

pub fn validateDebugEqZeroI16(instruction: ir.Instruction, value_name: []const u8) ![]const u8 {
    const result = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const icmp = switch (instruction.kind) {
        .icmp => |icmp| icmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (icmp.predicate != .eq or !icmp.operand_ty.eql(.{ .int = 16 })) return error.UnsupportedCodegenInstruction;
    if (!isNamed(icmp.lhs, value_name) or !icmp.rhs.eql(.{ .int = 0 })) return error.UnsupportedCodegenValue;
    return result;
}

pub fn validateDebugCondBr(block: ir.BasicBlock, cond_name: []const u8) !struct { then_target: []const u8, else_target: []const u8 } {
    const condbr = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!condbr.cond_ty.eql(.{ .int = 1 }) or !isNamed(condbr.cond, cond_name)) return error.UnsupportedCodegenControlFlow;
    return .{ .then_target = condbr.then_target, .else_target = condbr.else_target };
}

pub fn validateEmptyBr(block: ir.BasicBlock) ![]const u8 {
    if (block.instructions.items.len != 0) return error.UnsupportedCodegenInstruction;
    return validateTerminatorBr(block);
}

pub fn validateTerminatorBr(block: ir.BasicBlock) ![]const u8 {
    return switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .br => |br| br.target,
        else => error.UnsupportedCodegenControlFlow,
    };
}

pub fn validateDebugPanicUnreachableBlock(block: ir.BasicBlock) !void {
    if (block.instructions.items.len != 3) return error.UnsupportedCodegenInstruction;
    for (block.instructions.items[0..2]) |instruction| {
        if (instruction.result == null) return error.UnsupportedCodegenInstruction;
        switch (instruction.kind) {
            .extractvalue => {},
            else => return error.UnsupportedCodegenInstruction,
        }
    }
    const call = switch (block.instructions.items[2].kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!std.mem.eql(u8, call.callee, "debug.defaultPanic") or call.ret_ty != .void) return error.UnsupportedCodegenInstruction;
    switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .@"unreachable" => {},
        else => return error.UnsupportedCodegenControlFlow,
    }
}

pub fn validateF128EntryEqBranch(block: ir.BasicBlock, byval_param: []const u8) !F128Branch {
    if (block.instructions.items.len != 5) return error.UnsupportedCodegenInstruction;
    const first_load_name = block.instructions.items[0].result orelse return error.UnsupportedCodegenInstruction;
    const first_load = switch (block.instructions.items[0].kind) {
        .load => |load| load,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!first_load.ty.eql(.fp128) or first_load.attrs.isBarrier()) return error.UnsupportedCodegenInstruction;
    if (!isNamed(first_load.ptr, byval_param)) return error.UnsupportedCodegenValue;

    const gep_name = block.instructions.items[1].result orelse return error.UnsupportedCodegenInstruction;
    const gep = switch (block.instructions.items[1].kind) {
        .gep => |gep| gep,
        else => return error.UnsupportedCodegenInstruction,
    };
    try validateI8GepOffset(gep, byval_param, 16);

    const second_load_name = block.instructions.items[2].result orelse return error.UnsupportedCodegenInstruction;
    const second_load = switch (block.instructions.items[2].kind) {
        .load => |load| load,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!second_load.ty.eql(.fp128) or second_load.attrs.isBarrier()) return error.UnsupportedCodegenInstruction;
    if (!isNamed(second_load.ptr, gep_name)) return error.UnsupportedCodegenValue;

    const call_name = block.instructions.items[3].result orelse return error.UnsupportedCodegenInstruction;
    const call = switch (block.instructions.items[3].kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    try validateF128EqCall(call, first_load_name, "0xL00000000000000004002A00000000000");

    const icmp_name = block.instructions.items[4].result orelse return error.UnsupportedCodegenInstruction;
    const icmp = switch (block.instructions.items[4].kind) {
        .icmp => |icmp| icmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    try validateEqZeroIcmp(icmp, call_name);

    const condbr = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!condbr.cond_ty.eql(.{ .int = 1 }) or !isNamed(condbr.cond, icmp_name)) return error.UnsupportedCodegenControlFlow;
    return .{ .then_label = condbr.then_target, .else_label = condbr.else_target, .second_load = second_load_name };
}

pub fn validateF128SecondEqBranch(block: ir.BasicBlock, second_load_name: []const u8) !F128Branch {
    if (block.instructions.items.len != 2) return error.UnsupportedCodegenInstruction;
    const call_name = block.instructions.items[0].result orelse return error.UnsupportedCodegenInstruction;
    const call = switch (block.instructions.items[0].kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    try validateF128EqCall(call, second_load_name, "0xL00000000000000004004C80000000000");

    const icmp_name = block.instructions.items[1].result orelse return error.UnsupportedCodegenInstruction;
    const icmp = switch (block.instructions.items[1].kind) {
        .icmp => |icmp| icmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    try validateEqZeroIcmp(icmp, call_name);

    const condbr = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!condbr.cond_ty.eql(.{ .int = 1 }) or !isNamed(condbr.cond, icmp_name)) return error.UnsupportedCodegenControlFlow;
    return .{ .then_label = condbr.then_target, .else_label = condbr.else_target, .second_load = second_load_name };
}

pub fn validateF128EqCall(call: ir.CallInst, lhs_name: []const u8, expected: []const u8) !void {
    if (!std.mem.eql(u8, call.callee, "__eqtf2") or !call.ret_ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenInstruction;
    if (call.args.items.len != 2) return error.UnsupportedCodegenInstruction;
    if (!call.args.items[0].ty.eql(.fp128) or !isNamed(call.args.items[0].value, lhs_name)) return error.UnsupportedCodegenValue;
    if (!call.args.items[1].ty.eql(.fp128)) return error.UnsupportedCodegenType;
    switch (call.args.items[1].value) {
        .fp => |text| if (!std.mem.eql(u8, text, expected)) return error.UnsupportedCodegenValue,
        .named, .int, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    }
}

pub fn validateEqZeroIcmp(icmp: ir.IcmpInst, call_name: []const u8) !void {
    if (icmp.predicate != .eq or !icmp.operand_ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenInstruction;
    if (!isNamed(icmp.lhs, call_name) or !icmp.rhs.eql(.{ .int = 0 })) return error.UnsupportedCodegenValue;
}

pub fn validateF128SretSuccess(block: ir.BasicBlock, sret_param: []const u8) !void {
    if (block.instructions.items.len != 3) return error.UnsupportedCodegenInstruction;
    const first_store = switch (block.instructions.items[0].kind) {
        .store => |store| store,
        else => return error.UnsupportedCodegenInstruction,
    };
    try validateF128Store(first_store, sret_param, "0xL00000000000000004003800000000000");

    const gep_name = block.instructions.items[1].result orelse return error.UnsupportedCodegenInstruction;
    const gep = switch (block.instructions.items[1].kind) {
        .gep => |gep| gep,
        else => return error.UnsupportedCodegenInstruction,
    };
    try validateI8GepOffset(gep, sret_param, 16);

    const second_store = switch (block.instructions.items[2].kind) {
        .store => |store| store,
        else => return error.UnsupportedCodegenInstruction,
    };
    try validateF128Store(second_store, gep_name, "0xL00000000000000004005100000000000");

    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (ret.ty != .void or ret.value != null) return error.InvalidRet;
}

pub fn validateF128Store(store: ir.StoreInst, ptr_name: []const u8, expected: []const u8) !void {
    if (!store.ty.eql(.fp128) or store.attrs.isBarrier()) return error.UnsupportedCodegenInstruction;
    if (!isNamed(store.ptr, ptr_name)) return error.UnsupportedCodegenValue;
    switch (store.value) {
        .fp => |text| if (!std.mem.eql(u8, text, expected)) return error.UnsupportedCodegenValue,
        .named, .int, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    }
}

pub fn validateI8GepOffset(gep: ir.GepInst, ptr_name: []const u8, offset: i128) !void {
    if (!gep.source_ty.eql(.{ .int = 8 }) or !isNamed(gep.ptr, ptr_name)) return error.UnsupportedCodegenInstruction;
    if (gep.indices.items.len != 1) return error.UnsupportedCodegenInstruction;
    const index = gep.indices.items[0];
    if (!index.ty.eql(.{ .int = 64 }) or !index.value.eql(.{ .int = offset })) return error.UnsupportedCodegenInstruction;
}

pub fn validatePanicUnreachableBlock(block: ir.BasicBlock) !void {
    if (block.instructions.items.len != 1) return error.UnsupportedCodegenInstruction;
    const call = switch (block.instructions.items[0].kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!std.mem.eql(u8, call.callee, "debug.defaultPanic") or call.ret_ty != .void) return error.UnsupportedCodegenInstruction;
    switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .@"unreachable" => {},
        else => return error.UnsupportedCodegenControlFlow,
    }
}
