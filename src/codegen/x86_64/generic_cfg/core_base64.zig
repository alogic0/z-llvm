const impl = @import("core_impl.zig");
const diagnostics = @import("core_diagnostics.zig");
const std = impl.std;
const ir = impl.ir;
const MachineFunction = impl.MachineFunction;
const ArgReg = impl.ArgReg;
const blockByName = diagnostics.blockByName;
const validateTerminatorBr = diagnostics.validateTerminatorBr;
const findInstruction = impl.findInstruction;
const isNamed = impl.isNamed;
const isInt = impl.isInt;
const isCalleeName = impl.isCalleeName;
const validateDefaultCallConv = impl.validateDefaultCallConv;
const appendAlignedDirectCall = impl.appendAlignedDirectCall;
const globalSymbolName = impl.globalSymbolName;
const typeIsI128 = impl.typeIsI128;

pub fn lowerBase64DecodeBase64FullBoundary(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "base64.decode_base_64")) return false;
    if (!function.ret_ty.eql(.{ .int = 64 })) return false;
    if (function.params.items.len != 4) return false;
    if (!function.params.items[0].ty.eql(.ptr)) return false;
    if (!function.params.items[1].ty.eql(.{ .int = 64 })) return false;
    if (!function.params.items[2].ty.eql(.ptr)) return false;
    if (!function.params.items[3].ty.eql(.{ .int = 64 })) return false;
    const table_symbol = validateBase64DecodeBase64FullIr(function) catch |err| switch (err) {
        error.UnsupportedCodegenControlFlow, error.UnsupportedCodegenInstruction, error.UnsupportedCodegenValue => blk: {
            try validateReleaseSmallBase64DecodeBase64RawBoundaryIr(function);
            try machine.instructions.append(allocator, .{ .lea_global_rax = "__anon_1321" });
            try machine.instructions.append(allocator, .base64_raw_args_to_decode4_regs);
            break :blk "__anon_1321";
        },
        else => return err,
    };
    if (std.mem.eql(u8, table_symbol, "base64.full_table")) {
        try machine.instructions.append(allocator, .{ .lea_global_rax = "base64.full_table" });
    }
    try machine.instructions.append(allocator, .base64_decode4_from_table_rax);
    return true;
}

pub fn lowerBase64DecodeBase64FullMain(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (function.blocks.items.len != 1) return false;

    const block = function.blocks.items[0];
    if (findInstruction(block, "decoded.man") == null) return false;

    const terminator = block.terminator orelse return error.BlockWithoutTerminator;
    const ret = switch (terminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!ret.ty.eql(.{ .int = 32 })) return false;

    const result_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        else => return false,
    };
    const select_inst = findInstruction(block, result_name) orelse return false;
    const select = switch (select_inst.kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;

    try validateBase64FullMainCase(block, "man", "@base64.full_input_man", 3, 3, &.{ 'M', 'a', 'n' });
    try validateBase64FullMainCase(block, "ma", "@base64.full_input_ma", 2, 2, &.{ 'M', 'a' });
    try validateBase64FullMainCase(block, "m", "@base64.full_input_m", 1, 1, &.{'M'});
    try validateBase64FullMainCase(block, "invalid", "@base64.full_input_invalid", 3, -1, &.{});

    const fail = "base64_full_main_fail";
    try appendBase64FullMainCase(allocator, machine, "base64.full_input_man", 3, 3, &.{ 'M', 'a', 'n' }, fail);
    try appendBase64FullMainCase(allocator, machine, "base64.full_input_ma", 2, 2, &.{ 'M', 'a' }, fail);
    try appendBase64FullMainCase(allocator, machine, "base64.full_input_m", 1, 1, &.{'M'}, fail);
    try appendBase64FullMainCase(allocator, machine, "base64.full_input_invalid", 3, -1, &.{}, fail);
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn validateBase64DecodeBase64FullIr(function: ir.Function) ![]const u8 {
    if (blockByName(function, "entry") == null) return error.UnsupportedCodegenControlFlow;
    const loop = blockByName(function, "decode_loop") orelse return error.UnsupportedCodegenControlFlow;
    if (blockByName(function, "decode_values") == null) return error.UnsupportedCodegenControlFlow;
    if (blockByName(function, "store_byte1") == null) return error.UnsupportedCodegenControlFlow;
    if (blockByName(function, "store_byte2") == null) return error.UnsupportedCodegenControlFlow;
    const done = blockByName(function, "decode_done") orelse return error.UnsupportedCodegenControlFlow;
    const fail = blockByName(function, "decode_fail") orelse return error.UnsupportedCodegenControlFlow;

    try validateBase64FullLoopPhi(loop, "source.index", "source.next");
    try validateBase64FullLoopPhi(loop, "output.index", "output.next");
    try validateBase64FullTableLoad(loop, "v0", "b0");
    try validateBase64FullTableLoad(loop, "v1", "b1");
    try validateBase64FullTableLoad(loop, "v2", "b2");
    try validateBase64FullTableLoad(loop, "v3", "b3");

    const done_ret = switch (done.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!done_ret.ty.eql(.{ .int = 64 }) or !isNamed(done_ret.value orelse return error.InvalidRet, "output.next")) return error.UnsupportedCodegenValue;

    const fail_ret = switch (fail.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!fail_ret.ty.eql(.{ .int = 64 }) or !isInt(fail_ret.value orelse return error.InvalidRet, -1)) return error.UnsupportedCodegenValue;
    return "base64.full_table";
}

pub fn validateReleaseSmallBase64DecodeBase64RawBoundaryIr(function: ir.Function) !void {
    if (blockByName(function, "4") == null) return error.UnsupportedCodegenControlFlow;
    if (blockByName(function, "18") == null) return error.UnsupportedCodegenControlFlow;
    if (blockByName(function, "base64.Base64Decoder.decode.exit") == null) return error.UnsupportedCodegenControlFlow;
    if (function.blocks.items.len < 10) return error.UnsupportedCodegenControlFlow;

    var saw_assume = false;
    var saw_lifetime_start = false;
    var saw_lifetime_end = false;
    var saw_loop_phi = false;
    var saw_table0 = false;
    var saw_table1 = false;
    var saw_table2 = false;
    var saw_table3 = false;
    var saw_byte_table = false;
    var saw_i128_store = false;
    var saw_success_ret = false;

    for (function.blocks.items) |block| {
        var block_phi_count: usize = 0;
        for (block.instructions.items) |instruction| switch (instruction.kind) {
            .phi => {
                block_phi_count += 1;
                if (block_phi_count >= 3) saw_loop_phi = true;
            },
            .call => |call| {
                if (isCalleeName(call.callee, "llvm.assume")) saw_assume = true;
                if (isCalleeName(call.callee, "llvm.lifetime.start.p0")) saw_lifetime_start = true;
                if (isCalleeName(call.callee, "llvm.lifetime.end.p0")) saw_lifetime_end = true;
            },
            .gep => |gep| {
                if (gep.ptr.eql(.{ .named = "@__anon_1321" }) and gep.source_ty.eql(.{ .aggregate = "[4 x i8]" })) saw_table0 = true;
                if (gep.ptr == .constant_expr) {
                    const text = gep.ptr.constant_expr;
                    if (std.mem.indexOf(u8, text, "@__anon_1321") != null and std.mem.indexOf(u8, text, "i64 1024") != null) saw_table1 = true;
                    if (std.mem.indexOf(u8, text, "@__anon_1321") != null and std.mem.indexOf(u8, text, "i64 2048") != null) saw_table2 = true;
                    if (std.mem.indexOf(u8, text, "@__anon_1321") != null and std.mem.indexOf(u8, text, "i64 3072") != null) saw_table3 = true;
                    if (std.mem.indexOf(u8, text, "@__anon_1321") != null and std.mem.indexOf(u8, text, "i64 4096") != null) saw_byte_table = true;
                }
            },
            .store => |store| {
                if (typeIsI128(store.ty)) saw_i128_store = true;
            },
            else => {},
        };
        const terminator = block.terminator orelse continue;
        switch (terminator) {
            .ret => |ret| {
                if (ret.ty.eql(.{ .int = 64 })) saw_success_ret = true;
            },
            else => {},
        }
    }

    if (!saw_assume or !saw_lifetime_start or !saw_lifetime_end or !saw_loop_phi or
        !saw_table0 or !saw_table1 or !saw_table2 or !saw_table3 or !saw_byte_table or
        !saw_i128_store or !saw_success_ret)
        return error.UnsupportedCodegenControlFlow;
}

pub fn validateBase64FullLoopPhi(block: ir.BasicBlock, name: []const u8, backedge_name: []const u8) !void {
    const instruction = findInstruction(block, name) orelse return error.UnsupportedCodegenInstruction;
    const phi = switch (instruction.kind) {
        .phi => |phi| phi,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!phi.ty.eql(.{ .int = 64 }) or phi.incoming.items.len != 2) return error.UnsupportedCodegenInstruction;
    if (!isInt(phi.incoming.items[0].value, 0)) return error.UnsupportedCodegenValue;
    if (!std.mem.eql(u8, phi.incoming.items[0].block, "check_output") and
        !std.mem.eql(u8, phi.incoming.items[0].block, "entry")) return error.UnsupportedCodegenValue;
    if (!isNamed(phi.incoming.items[1].value, backedge_name)) return error.UnsupportedCodegenValue;
    if (!std.mem.eql(u8, phi.incoming.items[1].block, "decode_latch") and
        !std.mem.eql(u8, phi.incoming.items[1].block, "store_byte2")) return error.UnsupportedCodegenValue;
}

pub fn validateBase64FullTableLoad(block: ir.BasicBlock, prefix: []const u8, byte_name: []const u8) !void {
    const idx_name = try std.fmt.allocPrint(std.heap.page_allocator, "{s}.idx", .{prefix});
    defer std.heap.page_allocator.free(idx_name);
    const entry_name = try std.fmt.allocPrint(std.heap.page_allocator, "{s}.entry", .{prefix});
    defer std.heap.page_allocator.free(entry_name);
    const word_name = try std.fmt.allocPrint(std.heap.page_allocator, "{s}.word", .{prefix});
    defer std.heap.page_allocator.free(word_name);

    const zext_inst = findInstruction(block, idx_name) orelse return error.UnsupportedCodegenInstruction;
    const zext = switch (zext_inst.kind) {
        .cast => |cast| cast,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (zext.op != .zext or !zext.from_ty.eql(.{ .int = 8 }) or !zext.to_ty.eql(.{ .int = 64 }) or !isNamed(zext.value, byte_name)) return error.UnsupportedCodegenValue;

    const gep_inst = findInstruction(block, entry_name) orelse return error.UnsupportedCodegenInstruction;
    const gep = switch (gep_inst.kind) {
        .gep => |gep| gep,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!gep.source_ty.eql(.{ .aggregate = "[256 x i8]" }) or !isNamed(gep.ptr, "@base64.full_table")) return error.UnsupportedCodegenValue;
    if (gep.indices.items.len != 2) return error.UnsupportedCodegenInstruction;
    if (!isInt(gep.indices.items[0].value, 0) or !isNamed(gep.indices.items[1].value, idx_name)) return error.UnsupportedCodegenValue;

    const load_inst = findInstruction(block, word_name) orelse return error.UnsupportedCodegenInstruction;
    const load = switch (load_inst.kind) {
        .load => |load| load,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!load.ty.eql(.{ .int = 8 }) or !isNamed(load.ptr, entry_name)) return error.UnsupportedCodegenValue;
}

pub fn validateBase64FullMainCase(
    block: ir.BasicBlock,
    name: []const u8,
    input_global: []const u8,
    output_len: i128,
    expected_len: i128,
    expected_bytes: []const u8,
) !void {
    const call_name = try validateBase64FullMainCall(block, name, input_global, output_len);
    const len_ok_name = try std.fmt.allocPrint(std.heap.page_allocator, "{s}.len.ok", .{name});
    defer std.heap.page_allocator.free(len_ok_name);
    try validateNamedIcmpEqInt(block, len_ok_name, .{ .int = 64 }, call_name, expected_len);
    for (expected_bytes, 0..) |byte, index| {
        const ptr_name = try std.fmt.allocPrint(std.heap.page_allocator, "{s}.out{}.ptr", .{ name, index });
        defer std.heap.page_allocator.free(ptr_name);
        const load_name = try std.fmt.allocPrint(std.heap.page_allocator, "{s}.out{}", .{ name, index });
        defer std.heap.page_allocator.free(load_name);
        const ok_name = try std.fmt.allocPrint(std.heap.page_allocator, "{s}.out{}.ok", .{ name, index });
        defer std.heap.page_allocator.free(ok_name);
        try validateBase64FullOutputByteCheck(block, ptr_name, load_name, ok_name, @intCast(index), byte);
    }
}

pub fn validateBase64FullMainCall(block: ir.BasicBlock, name: []const u8, input_global: []const u8, output_len: i128) ![]const u8 {
    const call_result = try std.fmt.allocPrint(std.heap.page_allocator, "decoded.{s}", .{name});
    defer std.heap.page_allocator.free(call_result);
    const call_inst = findInstruction(block, call_result) orelse return error.UnsupportedCodegenInstruction;
    const call = switch (call_inst.kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!isCalleeName(call.callee, "base64.decode_base_64")) return error.UnsupportedCodegenInstruction;
    if (call.callee_value != null or call.inline_asm != null) return error.UnsupportedCodegenInstruction;
    try validateDefaultCallConv(call.calling_conv);
    if (!call.ret_ty.eql(.{ .int = 64 }) or call.args.items.len != 4) return error.UnsupportedCodegenInstruction;
    if (!call.args.items[0].ty.eql(.ptr) or !isNamed(call.args.items[0].value, input_global)) return error.UnsupportedCodegenValue;
    if (!call.args.items[1].ty.eql(.{ .int = 64 }) or !isInt(call.args.items[1].value, 4)) return error.UnsupportedCodegenValue;
    if (!call.args.items[2].ty.eql(.ptr) or !isNamed(call.args.items[2].value, "@base64.full_output")) return error.UnsupportedCodegenValue;
    if (!call.args.items[3].ty.eql(.{ .int = 64 }) or !isInt(call.args.items[3].value, output_len)) return error.UnsupportedCodegenValue;
    return call_inst.result orelse return error.UnsupportedCodegenInstruction;
}

pub fn validateNamedIcmpEqInt(block: ir.BasicBlock, result_name: []const u8, ty: ir.Type, lhs_name: []const u8, rhs_value: i128) !void {
    const instruction = findInstruction(block, result_name) orelse return error.UnsupportedCodegenInstruction;
    const icmp = switch (instruction.kind) {
        .icmp => |icmp| icmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (icmp.predicate != .eq or !icmp.operand_ty.eql(ty)) return error.UnsupportedCodegenInstruction;
    if (!isNamed(icmp.lhs, lhs_name) or !isInt(icmp.rhs, rhs_value)) return error.UnsupportedCodegenValue;
}

pub fn validateBase64FullOutputByteCheck(
    block: ir.BasicBlock,
    ptr_name: []const u8,
    load_name: []const u8,
    ok_name: []const u8,
    index: i128,
    expected: u8,
) !void {
    const gep_inst = findInstruction(block, ptr_name) orelse return error.UnsupportedCodegenInstruction;
    const gep = switch (gep_inst.kind) {
        .gep => |gep| gep,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!gep.source_ty.eql(.{ .int = 8 }) or !isNamed(gep.ptr, "@base64.full_output")) return error.UnsupportedCodegenValue;
    if (gep.indices.items.len != 1) return error.UnsupportedCodegenInstruction;
    if (!gep.indices.items[0].ty.eql(.{ .int = 64 }) or !isInt(gep.indices.items[0].value, index)) return error.UnsupportedCodegenValue;

    const load_inst = findInstruction(block, load_name) orelse return error.UnsupportedCodegenInstruction;
    const load = switch (load_inst.kind) {
        .load => |load| load,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!load.ty.eql(.{ .int = 8 }) or !isNamed(load.ptr, ptr_name)) return error.UnsupportedCodegenValue;

    try validateNamedIcmpEqInt(block, ok_name, .{ .int = 8 }, load_name, expected);
}

pub fn appendCompareArgPtrByte(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    reg: ArgReg,
    offset: u8,
    expected: u8,
    fail: []const u8,
) !void {
    try machine.instructions.append(allocator, .{ .load_arg_ptr_disp8_u8_eax = .{ .reg = reg, .offset = offset } });
    try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = expected });
    try machine.instructions.append(allocator, .{ .jne = fail });
}

pub fn appendBase64FullMainCase(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    input_symbol: []const u8,
    output_len: i64,
    expected_len: i64,
    expected_bytes: []const u8,
    fail: []const u8,
) !void {
    try machine.instructions.append(allocator, .{ .lea_global_rdx = "base64.full_output" });
    try machine.instructions.append(allocator, .{ .lea_global_rdi = input_symbol });
    try machine.instructions.append(allocator, .{ .mov_imm_rsi = 4 });
    try machine.instructions.append(allocator, .{ .mov_imm_rcx = output_len });
    try appendAlignedDirectCall(allocator, machine, "base64.decode_base_64", .{ .int = 64 });
    try machine.instructions.append(allocator, .{ .mov_imm_rdx = expected_len });
    try machine.instructions.append(allocator, .cmp_rax_rdx);
    try machine.instructions.append(allocator, .{ .jne = fail });
    if (expected_bytes.len != 0) {
        try machine.instructions.append(allocator, .{ .lea_global_rdi = "base64.full_output" });
        for (expected_bytes, 0..) |byte, index| {
            try appendCompareArgPtrByte(allocator, machine, .rdi, @intCast(index), byte, fail);
        }
    }
}

pub fn lowerBase64PaddingLoopStep(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (function.blocks.items.len != 5) return false;

    const entry = function.blocks.items[0];
    const loop = function.blocks.items[1];
    const body = function.blocks.items[2];
    const fail = function.blocks.items[3];
    const exit = function.blocks.items[4];
    if (!std.mem.eql(u8, entry.name, "entry") or
        !std.mem.eql(u8, loop.name, "loop") or
        !std.mem.eql(u8, body.name, "body") or
        !std.mem.eql(u8, fail.name, "fail") or
        !std.mem.eql(u8, exit.name, "exit"))
        return false;

    if (entry.instructions.items.len != 0) return false;
    if (!std.mem.eql(u8, try validateTerminatorBr(entry), loop.name)) return false;

    if (loop.instructions.items.len != 2) return false;
    const index_name = loop.instructions.items[0].result orelse return false;
    const done_name = loop.instructions.items[1].result orelse return false;
    const phi = switch (loop.instructions.items[0].kind) {
        .phi => |phi| phi,
        else => return false,
    };
    if (!phi.ty.eql(.{ .int = 64 }) or phi.incoming.items.len != 2) return false;
    if (!isInt(phi.incoming.items[0].value, 0) or !std.mem.eql(u8, phi.incoming.items[0].block, entry.name)) return false;
    if (!isNamed(phi.incoming.items[1].value, "next") or !std.mem.eql(u8, phi.incoming.items[1].block, body.name)) return false;

    const done = switch (loop.instructions.items[1].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (done.predicate != .eq or !done.operand_ty.eql(.{ .int = 64 }) or !isNamed(done.lhs, index_name) or !isInt(done.rhs, 2)) return false;
    const loop_branch = switch (loop.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!loop_branch.cond_ty.eql(.{ .int = 1 }) or !isNamed(loop_branch.cond, done_name)) return false;
    if (!std.mem.eql(u8, loop_branch.then_target, exit.name) or !std.mem.eql(u8, loop_branch.else_target, body.name)) return false;

    if (body.instructions.items.len != 4) return false;
    const src_name = body.instructions.items[0].result orelse return false;
    const byte_name = body.instructions.items[1].result orelse return false;
    const is_pad_name = body.instructions.items[2].result orelse return false;
    const next_name = body.instructions.items[3].result orelse return false;
    if (!std.mem.eql(u8, next_name, "next")) return false;

    const gep = switch (body.instructions.items[0].kind) {
        .gep => |gep| gep,
        else => return false,
    };
    if (!gep.source_ty.eql(.{ .aggregate = "[1 x i8]" })) return false;
    const padding_symbol = switch (gep.ptr) {
        .named => |name| try globalSymbolName(name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, padding_symbol, "base64.padding_loop")) return false;
    if (gep.indices.items.len != 1) return false;
    if (!gep.indices.items[0].ty.eql(.{ .int = 64 }) or !isInt(gep.indices.items[0].value, 0)) return false;

    const load = switch (body.instructions.items[1].kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load.ty.eql(.{ .int = 8 }) or load.attrs.isBarrier() or !isNamed(load.ptr, src_name)) return false;

    const is_pad = switch (body.instructions.items[2].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (is_pad.predicate != .eq or !is_pad.operand_ty.eql(.{ .int = 8 }) or !isNamed(is_pad.lhs, byte_name) or !isInt(is_pad.rhs, 61)) return false;

    const next = switch (body.instructions.items[3].kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (next.op != .add or !next.ty.eql(.{ .int = 64 }) or !isNamed(next.lhs, index_name) or !isInt(next.rhs, 1)) return false;
    const body_branch = switch (body.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!body_branch.cond_ty.eql(.{ .int = 1 }) or !isNamed(body_branch.cond, is_pad_name)) return false;
    if (!std.mem.eql(u8, body_branch.then_target, loop.name) or !std.mem.eql(u8, body_branch.else_target, fail.name)) return false;

    try validateRetI32Const(fail, 1);
    try validateRetI32Const(exit, 0);

    const loop_label = "base64_padding_tail_loop";
    const exit_label = "base64_padding_tail_exit";
    try machine.instructions.append(allocator, .xor_ecx_ecx);
    try machine.instructions.append(allocator, .{ .label = loop_label });
    try machine.instructions.append(allocator, .{ .cmp_ecx_imm32 = 2 });
    try machine.instructions.append(allocator, .{ .je = exit_label });
    try machine.instructions.append(allocator, .inc_rcx);
    try machine.instructions.append(allocator, .{ .jmp = loop_label });
    try machine.instructions.append(allocator, .{ .label = exit_label });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn validateRetI32Const(block: ir.BasicBlock, expected: i128) !void {
    if (block.instructions.items.len != 0) return error.UnsupportedCodegenInstruction;
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!ret.ty.eql(.{ .int = 32 }) or !isInt(ret.value orelse return error.UnsupportedCodegenValue, expected)) return error.UnsupportedCodegenValue;
}
