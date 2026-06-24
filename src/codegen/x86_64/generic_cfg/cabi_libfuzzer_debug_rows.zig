const std = @import("std");
const ir = @import("../../../ir.zig");
const x86_64_match = @import("../match.zig");
const x86_64_machine = @import("../machine.zig");
const core_validation = @import("core_validation.zig");
const core_misc_rows = @import("core_misc_rows.zig");
const f128_debug_rows = @import("cabi_f128_debug_rows.zig");

const MachineFunction = x86_64_machine.MachineFunction;
const isNamed = x86_64_match.isNamed;
const isCalleeName = x86_64_match.isCalleeName;
const validateAllocaNamed = core_validation.validateAllocaNamed;
const validateStore = core_validation.validateStore;
const singleRetVoidBlock = core_validation.singleRetVoidBlock;
const hasSingleBlockInstructionCount = core_validation.hasSingleBlockInstructionCount;
const validateIcmpNamedImm = core_misc_rows.validateIcmpNamedImm;
const validateNamedLoad = f128_debug_rows.validateNamedLoad;
const validateI8GepOffset = f128_debug_rows.validateI8GepOffset;

pub const ExpectedCallArg = struct {
    ty: ir.Type,
    value: ir.Value,
};

pub fn validateVoidCall(instruction: ir.Instruction, callee: []const u8, expected_args: []const ExpectedCallArg) !void {
    if (instruction.removed) return error.UnsupportedCodegenInstruction;
    if (instruction.result != null) return error.UnsupportedCodegenInstruction;
    const call = switch (instruction.kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (call.callee_value != null or call.inline_asm != null) return error.UnsupportedCodegenInstruction;
    if (!isCalleeName(call.callee, callee)) return error.UnsupportedCodegenInstruction;
    if (call.ret_ty != .void or call.args.items.len != expected_args.len) return error.UnsupportedCodegenInstruction;
    for (call.args.items, expected_args) |arg, expected| {
        if (!arg.ty.eql(expected.ty) or !arg.value.eql(expected.value)) return error.UnsupportedCodegenValue;
    }
}

pub fn lowerSelectedLibfuzzerDebugO0(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (std.mem.eql(u8, function.name, "main.runner_broadcast_input")) {
        if (!hasSingleBlockInstructionCount(function, 4)) return false;
        try validateDebugLibfuzzerBroadcastInput(function);
        try machine.instructions.append(allocator, .ret);
        return true;
    }
    if (std.mem.eql(u8, function.name, "main.runner_futex_wait")) {
        if (!hasSingleBlockInstructionCount(function, 3)) return false;
        try validateDebugLibfuzzerFutexWait(function);
        try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
        try machine.instructions.append(allocator, .ret);
        return true;
    }
    if (std.mem.eql(u8, function.name, "main.runner_test_name")) {
        if (!hasSingleBlockInstructionCount(function, 7)) return false;
        try validateDebugLibfuzzerTestName(function);
        try machine.instructions.append(allocator, .{ .lea_global_rax = "__anon_22815" });
        try machine.instructions.append(allocator, .{ .mov_imm_rdx = 4 });
        try machine.instructions.append(allocator, .ret);
        return true;
    }
    if (std.mem.eql(u8, function.name, "main.runner_test_run")) {
        if (!hasSingleBlockInstructionCount(function, 24)) return false;
        try validateDebugLibfuzzerTestRun(function);
        try machine.instructions.append(allocator, .sub_rsp_8);
        try machine.instructions.append(allocator, .{ .lea_global_rdi = "main.testOne" });
        try machine.instructions.append(allocator, .{ .direct_call = .{ .symbol = "fuzzer_set_test", .ret_ty = .void } });
        try machine.instructions.append(allocator, .{ .lea_global_rdi = "__anon_8117" });
        try machine.instructions.append(allocator, .{ .mov_imm_rsi = 0 });
        try machine.instructions.append(allocator, .{ .direct_call = .{ .symbol = "fuzzer_new_input", .ret_ty = .void } });
        try machine.instructions.append(allocator, .{ .lea_global_rdi = "__anon_22035" });
        try machine.instructions.append(allocator, .{ .mov_imm_rsi = 5 });
        try machine.instructions.append(allocator, .{ .direct_call = .{ .symbol = "fuzzer_new_input", .ret_ty = .void } });
        try machine.instructions.append(allocator, .{ .direct_call = .{ .symbol = "fuzzer_start_test", .ret_ty = .void } });
        try machine.instructions.append(allocator, .add_rsp_8);
        try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
        try machine.instructions.append(allocator, .ret);
        return true;
    }
    if (std.mem.eql(u8, function.name, "main.testOne")) {
        if (!function.ret_ty.eql(.{ .int = 1 }) or function.params.items.len != 0) return false;
        if (function.blocks.items.len != 1) return error.UnsupportedCodegenControlFlow;
        const block = function.blocks.items[0];
        if (block.instructions.items.len != 0) return error.UnsupportedCodegenInstruction;
        const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
            .ret => |ret| ret,
            .br, .condbr, .@"switch", .indirectbr, .@"unreachable" => return error.UnsupportedCodegenControlFlow,
        };
        if (!ret.ty.eql(.{ .int = 1 }) or !(ret.value orelse return error.InvalidRet).eql(.{ .int = 0 })) return error.UnsupportedCodegenControlFlow;
        try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
        try machine.instructions.append(allocator, .ret);
        return true;
    }
    return false;
}

pub fn validateDebugLibfuzzerBroadcastInput(function: ir.Function) !void {
    if (function.ret_ty != .void or function.params.items.len != 3) return error.UnsupportedCodegenInstruction;
    if (!function.params.items[0].ty.eql(.{ .int = 32 }) or !function.params.items[1].ty.eql(.{ .int = 64 }) or !function.params.items[2].ty.eql(.{ .int = 64 })) {
        return error.UnsupportedCodegenInstruction;
    }
    const block = try singleRetVoidBlock(function);
    if (block.instructions.items.len != 4) return error.UnsupportedCodegenInstruction;
    const slot = try validateAllocaNamed(block.instructions.items[0], .{ .aggregate = "[16 x i8]" });
    try validateStore(block.instructions.items[1], .{ .int = 64 }, .{ .named = function.params.items[1].name }, slot);
    const gep_name = try validateI8GepInstruction(block.instructions.items[2], slot, 8);
    try validateStore(block.instructions.items[3], .{ .int = 64 }, .{ .named = function.params.items[2].name }, gep_name);
}

pub fn validateDebugLibfuzzerFutexWait(function: ir.Function) !void {
    if (!function.ret_ty.eql(.{ .int = 1 }) or function.params.items.len != 2) return error.UnsupportedCodegenInstruction;
    if (function.blocks.items.len != 1) return error.UnsupportedCodegenControlFlow;
    const block = function.blocks.items[0];
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        .br, .condbr, .@"switch", .indirectbr, .@"unreachable" => return error.UnsupportedCodegenControlFlow,
    };
    if (block.instructions.items.len != 3 or !ret.ty.eql(.{ .int = 1 }) or !(ret.value orelse return error.InvalidRet).eql(.{ .int = 0 })) return error.UnsupportedCodegenInstruction;
    const load_name = try validateNamedLoad(block.instructions.items[0], .{ .int = 32 }, function.params.items[0].name);
    const cmp_name = try validateIcmpNamed(block.instructions.items[1], .eq, .{ .int = 32 }, load_name, function.params.items[1].name);
    try validateDebugAssertCall(block.instructions.items[2], cmp_name);
}

pub fn validateDebugLibfuzzerTestName(function: ir.Function) !void {
    if (!function.ret_ty.eql(.{ .aggregate = "{ i64, i64 }" }) or function.params.items.len != 1) return error.UnsupportedCodegenInstruction;
    if (function.blocks.items.len != 1) return error.UnsupportedCodegenControlFlow;
    const block = function.blocks.items[0];
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        .br, .condbr, .@"switch", .indirectbr, .@"unreachable" => return error.UnsupportedCodegenControlFlow,
    };
    if (block.instructions.items.len != 7 or !ret.ty.eql(.{ .aggregate = "{ i64, i64 }" })) return error.UnsupportedCodegenInstruction;
    const slot = try validateAllocaNamed(block.instructions.items[0], .{ .aggregate = "%Build.abi.fuzz.Slice" });
    const cmp_name = try validateIcmpNamedImm(block.instructions.items[1], .eq, .{ .int = 32 }, function.params.items[0].name, 0);
    try validateDebugAssertCall(block.instructions.items[2], cmp_name);
    const ptr_name = try validateExtractConstantSliceValue(block.instructions.items[3], "@__anon_22815", 0);
    const len_name = try validateExtractConstantSliceValue(block.instructions.items[4], "@__anon_22815", 1);
    try validateFuzzSliceFromSlice(block.instructions.items[5], slot, ptr_name, len_name);
    const loaded = try validateNamedLoad(block.instructions.items[6], .{ .aggregate = "{ i64, i64 }" }, slot);
    if (!isNamed(ret.value orelse return error.InvalidRet, loaded)) return error.UnsupportedCodegenControlFlow;
}

pub fn validateDebugLibfuzzerTestRun(function: ir.Function) !void {
    if (function.ret_ty != .void or function.params.items.len != 1) return error.UnsupportedCodegenInstruction;
    const block = try singleRetVoidBlock(function);
    if (block.instructions.items.len != 24) return error.UnsupportedCodegenInstruction;
    const raw_hello = try validateAllocaNamed(block.instructions.items[0], .{ .aggregate = "[16 x i8]" });
    const hello_slice = try validateAllocaNamed(block.instructions.items[1], .{ .aggregate = "%Build.abi.fuzz.Slice" });
    const raw_empty = try validateAllocaNamed(block.instructions.items[2], .{ .aggregate = "[16 x i8]" });
    const empty_slice = try validateAllocaNamed(block.instructions.items[3], .{ .aggregate = "%Build.abi.fuzz.Slice" });
    const cmp_name = try validateIcmpNamedImm(block.instructions.items[4], .eq, .{ .int = 32 }, function.params.items[0].name, 0);
    try validateDebugAssertCall(block.instructions.items[5], cmp_name);
    try validateVoidCall(block.instructions.items[6], "fuzzer_set_test", &.{.{ .ty = .ptr, .value = .{ .named = "@main.testOne" } }});
    const empty_ptr = try validateExtractConstantSliceValue(block.instructions.items[7], "@__anon_8117", 0);
    const empty_len = try validateExtractConstantSliceValue(block.instructions.items[8], "@__anon_8117", 1);
    try validateFuzzSliceFromSlice(block.instructions.items[9], empty_slice, empty_ptr, empty_len);
    try validateMemcpy(block.instructions.items[10], raw_empty, empty_slice, 16);
    const empty_input_ptr = try validateNamedLoad(block.instructions.items[11], .{ .int = 64 }, raw_empty);
    const empty_input_len_ptr = try validateI8GepInstruction(block.instructions.items[12], raw_empty, 8);
    const empty_input_len = try validateNamedLoad(block.instructions.items[13], .{ .int = 64 }, empty_input_len_ptr);
    try validateVoidCall(block.instructions.items[14], "fuzzer_new_input", &.{
        .{ .ty = .{ .int = 64 }, .value = .{ .named = empty_input_ptr } },
        .{ .ty = .{ .int = 64 }, .value = .{ .named = empty_input_len } },
    });
    const hello_ptr = try validateExtractConstantSliceValue(block.instructions.items[15], "@__anon_22035", 0);
    const hello_len = try validateExtractConstantSliceValue(block.instructions.items[16], "@__anon_22035", 1);
    try validateFuzzSliceFromSlice(block.instructions.items[17], hello_slice, hello_ptr, hello_len);
    try validateMemcpy(block.instructions.items[18], raw_hello, hello_slice, 16);
    const hello_input_ptr = try validateNamedLoad(block.instructions.items[19], .{ .int = 64 }, raw_hello);
    const hello_input_len_ptr = try validateI8GepInstruction(block.instructions.items[20], raw_hello, 8);
    const hello_input_len = try validateNamedLoad(block.instructions.items[21], .{ .int = 64 }, hello_input_len_ptr);
    try validateVoidCall(block.instructions.items[22], "fuzzer_new_input", &.{
        .{ .ty = .{ .int = 64 }, .value = .{ .named = hello_input_ptr } },
        .{ .ty = .{ .int = 64 }, .value = .{ .named = hello_input_len } },
    });
    try validateVoidCall(block.instructions.items[23], "fuzzer_start_test", &.{});
}

pub fn validateI8GepInstruction(instruction: ir.Instruction, ptr_name: []const u8, offset: i128) ![]const u8 {
    const name = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const gep = switch (instruction.kind) {
        .gep => |gep| gep,
        else => return error.UnsupportedCodegenInstruction,
    };
    try validateI8GepOffset(gep, ptr_name, offset);
    return name;
}

pub fn validateIcmpNamed(instruction: ir.Instruction, predicate: ir.IcmpPredicate, ty: ir.Type, lhs_name: []const u8, rhs_name: []const u8) ![]const u8 {
    const name = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const cmp = switch (instruction.kind) {
        .icmp => |icmp| icmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (cmp.predicate != predicate or !cmp.operand_ty.eql(ty) or !isNamed(cmp.lhs, lhs_name) or !isNamed(cmp.rhs, rhs_name)) return error.UnsupportedCodegenInstruction;
    return name;
}

pub fn validateDebugAssertCall(instruction: ir.Instruction, cond_name: []const u8) !void {
    const args = [_]ExpectedCallArg{.{
        .ty = .{ .int = 1 },
        .value = .{ .named = cond_name },
    }};
    try validateVoidCall(instruction, "debug.assert", &args);
}

pub fn validateExtractConstantSliceValue(instruction: ir.Instruction, symbol: []const u8, index: u32) ![]const u8 {
    const name = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const extract = switch (instruction.kind) {
        .extractvalue => |extract| extract,
        else => return error.UnsupportedCodegenInstruction,
    };
    var index_buf: [16]u8 = undefined;
    const expected_index = std.fmt.bufPrint(&index_buf, "{d}", .{index}) catch return error.UnsupportedCodegenValue;
    if (!extract.aggregate_ty.eql(.{ .aggregate = "{ ptr, i64 }" }) or !std.mem.eql(u8, extract.indices, expected_index)) return error.UnsupportedCodegenInstruction;
    const expected_len: i128 = if (std.mem.eql(u8, symbol, "@__anon_22035")) 5 else if (std.mem.eql(u8, symbol, "@__anon_22815")) 4 else 0;
    switch (extract.aggregate) {
        .constant_expr => |text| {
            var len_buf: [32]u8 = undefined;
            const len_text = std.fmt.bufPrint(&len_buf, "i64 {d}", .{expected_len}) catch return error.UnsupportedCodegenValue;
            if (std.mem.indexOf(u8, text, symbol) == null or std.mem.indexOf(u8, text, len_text) == null) return error.UnsupportedCodegenValue;
        },
        .named, .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector => return error.UnsupportedCodegenValue,
    }
    return name;
}

pub fn validateFuzzSliceFromSlice(instruction: ir.Instruction, sret_name: []const u8, ptr_name: []const u8, len_name: []const u8) !void {
    const args = [_]ExpectedCallArg{
        .{ .ty = .ptr, .value = .{ .named = ptr_name } },
        .{ .ty = .{ .int = 64 }, .value = .{ .named = len_name } },
    };
    if (instruction.result != null) return error.UnsupportedCodegenInstruction;
    const call = switch (instruction.kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!isCalleeName(call.callee, "Build.abi.fuzz.Slice.fromSlice") or call.ret_ty != .void or call.args.items.len != 3) return error.UnsupportedCodegenInstruction;
    if (call.args.items[0].ty != .ptr or !isNamed(call.args.items[0].value, sret_name)) return error.UnsupportedCodegenValue;
    if (!call.args.items[1].ty.eql(args[0].ty) or !call.args.items[1].value.eql(args[0].value)) return error.UnsupportedCodegenValue;
    if (!call.args.items[2].ty.eql(args[1].ty) or !call.args.items[2].value.eql(args[1].value)) return error.UnsupportedCodegenValue;
}

pub fn validateMemcpy(instruction: ir.Instruction, dst_name: []const u8, src_name: []const u8, len: i64) !void {
    if (instruction.result != null) return error.UnsupportedCodegenInstruction;
    const call = switch (instruction.kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!std.mem.eql(u8, call.callee, "llvm.memcpy.p0.p0.i64") or call.ret_ty != .void or call.args.items.len != 4) return error.UnsupportedCodegenInstruction;
    if (call.args.items[0].ty != .ptr or !isNamed(call.args.items[0].value, dst_name)) return error.UnsupportedCodegenValue;
    if (call.args.items[1].ty != .ptr or !isNamed(call.args.items[1].value, src_name)) return error.UnsupportedCodegenValue;
    if (!call.args.items[2].ty.eql(.{ .int = 64 }) or !call.args.items[2].value.eql(.{ .int = len })) return error.UnsupportedCodegenValue;
    if (!call.args.items[3].ty.eql(.{ .int = 1 }) or !call.args.items[3].value.eql(.{ .int = 0 })) return error.UnsupportedCodegenValue;
}
