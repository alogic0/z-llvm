const codegen_x86_64_common = @import("codegen_x86_64_common.zig");

const std = codegen_x86_64_common.std;
const air_bridge = codegen_x86_64_common.air_bridge;
const alias = codegen_x86_64_common.alias;
const call_graph = codegen_x86_64_common.call_graph;
const cfg = codegen_x86_64_common.cfg;
const codegen = codegen_x86_64_common.codegen;
const dominator = codegen_x86_64_common.dominator;
const function_attrs = codegen_x86_64_common.function_attrs;
const fp_semantics = codegen_x86_64_common.fp_semantics;
const loop_info = codegen_x86_64_common.loop_info;
const memory_effect = codegen_x86_64_common.memory_effect;
const memory_location = codegen_x86_64_common.memory_location;
const memory_ssa = codegen_x86_64_common.memory_ssa;
const ir = codegen_x86_64_common.ir;
const normalize = codegen_x86_64_common.normalize;
const mc = codegen_x86_64_common.mc;
const pass_manager = codegen_x86_64_common.pass_manager;
const pipelines = codegen_x86_64_common.pipelines;
const postdominator = codegen_x86_64_common.postdominator;
const semantic_descriptor_v2 = codegen_x86_64_common.semantic_descriptor_v2;
const target = codegen_x86_64_common.target;
const target_library_info = codegen_x86_64_common.target_library_info;
const target_transform_info = codegen_x86_64_common.target_transform_info;
const instcombine = codegen_x86_64_common.instcombine;
const zig_air_export = codegen_x86_64_common.zig_air_export;
const zig_air_lowering = codegen_x86_64_common.zig_air_lowering;
const dce = codegen_x86_64_common.dce;
const dse = codegen_x86_64_common.dse;
const early_cse = codegen_x86_64_common.early_cse;
const gvn = codegen_x86_64_common.gvn;
const licm = codegen_x86_64_common.licm;
const mem2reg = codegen_x86_64_common.mem2reg;
const sccp = codegen_x86_64_common.sccp;
const simplifycfg = codegen_x86_64_common.simplifycfg;
const slp_vectorizer = codegen_x86_64_common.slp_vectorizer;
const sroa = codegen_x86_64_common.sroa;
const expectMachineInstruction = codegen_x86_64_common.expectMachineInstruction;
test "x86_64 encoding emits expected add args bytes" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @add_args(i32 %a, i32 %b) {
        \\entry:
        \\  %sum = add i32 %a, %b
        \\  ret i32 %sum
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);

    const bytes = try mc.encoding.encodeFunction(std.testing.allocator, machine);
    defer std.testing.allocator.free(bytes);
    try std.testing.expectEqualSlices(u8, &.{ 0x89, 0xf8, 0x01, 0xf0, 0xc3 }, bytes);
}

test "x86_64 encoding sizes i64 add before direct call relocation" {
    var machine = codegen.x86_64.MachineFunction.init("add64_call", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);
    try machine.instructions.append(std.testing.allocator, .{ .mov_arg_rax = .rdi });
    try machine.instructions.append(std.testing.allocator, .{ .add_arg64_rax = .rsi });
    try machine.instructions.append(std.testing.allocator, .sub_rsp_8);
    try machine.instructions.append(std.testing.allocator, .{ .direct_call = .{ .symbol = "callee", .ret_ty = .{ .int = 64 } } });
    try machine.instructions.append(std.testing.allocator, .add_rsp_8);
    try machine.instructions.append(std.testing.allocator, .ret);

    try std.testing.expectEqual(@as(u32, 3), mc.encoding.instructionSize(.{ .add_arg64_rax = .rsi }));
    const bytes = try mc.encoding.encodeFunction(std.testing.allocator, machine);
    defer std.testing.allocator.free(bytes);
    try std.testing.expectEqualSlices(u8, &.{
        0x48, 0x8b, 0xc7,
        0x48, 0x01, 0xf0,
        0x48, 0x83, 0xec,
        0x08, 0xe8, 0x00,
        0x00, 0x00, 0x00,
        0x48, 0x83, 0xc4,
        0x08, 0xc3,
    }, bytes);
}

test "x86_64 encoding sizes high-register binary rax operands" {
    var machine = codegen.x86_64.MachineFunction.init("high_reg_binary_rax", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);
    try machine.instructions.append(std.testing.allocator, .{ .mov_arg_rax = .rdi });
    try machine.instructions.append(std.testing.allocator, .{ .binary_arg_rax = .{ .op = .xor, .reg = .r8 } });
    try machine.instructions.append(std.testing.allocator, .{ .sbb_arg64_rax = .r9 });
    try machine.instructions.append(std.testing.allocator, .ret);

    try std.testing.expectEqual(@as(u32, 3), mc.encoding.instructionSize(.{ .binary_arg_rax = .{ .op = .xor, .reg = .r8 } }));
    try std.testing.expectEqual(@as(u32, 3), mc.encoding.instructionSize(.{ .sbb_arg64_rax = .r9 }));
    const bytes = try mc.encoding.encodeFunction(std.testing.allocator, machine);
    defer std.testing.allocator.free(bytes);
    try std.testing.expectEqualSlices(u8, &.{
        0x48, 0x8b, 0xc7,
        0x4c, 0x31, 0xc0,
        0x4c, 0x19, 0xc8,
        0xc3,
    }, bytes);
}

test "x86_64 encoding emits named i32 multiply operands" {
    var machine = codegen.x86_64.MachineFunction.init("mul_i32", .{ .int = 32 });
    defer machine.deinit(std.testing.allocator);
    try machine.instructions.append(std.testing.allocator, .{ .imul_eax_arg32 = .rcx });
    try machine.instructions.append(std.testing.allocator, .{ .imul_eax_arg32 = .r8 });
    try machine.instructions.append(std.testing.allocator, .ret);

    try std.testing.expectEqual(@as(u32, 3), mc.encoding.instructionSize(.{ .imul_eax_arg32 = .rcx }));
    try std.testing.expectEqual(@as(u32, 4), mc.encoding.instructionSize(.{ .imul_eax_arg32 = .r8 }));
    const bytes = try mc.encoding.encodeFunction(std.testing.allocator, machine);
    defer std.testing.allocator.free(bytes);
    try std.testing.expectEqualSlices(u8, &.{
        0x0f, 0xaf, 0xc1,
        0x41, 0x0f, 0xaf,
        0xc0, 0xc3,
    }, bytes);
}

test "x86_64 encoding emits unsigned i32 division operands" {
    var machine = codegen.x86_64.MachineFunction.init("div_i32", .{ .int = 32 });
    defer machine.deinit(std.testing.allocator);
    try machine.instructions.append(std.testing.allocator, .{ .mov_arg_eax = .rdi });
    try machine.instructions.append(std.testing.allocator, .xor_edx_edx);
    try machine.instructions.append(std.testing.allocator, .{ .div_arg32 = .rcx });
    try machine.instructions.append(std.testing.allocator, .{ .div_arg32 = .r8 });
    try machine.instructions.append(std.testing.allocator, .ret);

    try std.testing.expectEqual(@as(u32, 2), mc.encoding.instructionSize(.{ .div_arg32 = .rcx }));
    try std.testing.expectEqual(@as(u32, 3), mc.encoding.instructionSize(.{ .div_arg32 = .r8 }));
    const bytes = try mc.encoding.encodeFunction(std.testing.allocator, machine);
    defer std.testing.allocator.free(bytes);
    try std.testing.expectEqualSlices(u8, &.{
        0x89, 0xf8,
        0x31, 0xd2,
        0xf7, 0xf1,
        0x41, 0xf7,
        0xf0, 0xc3,
    }, bytes);
}

test "x86_64 encoding emits i32 funnel shift operands" {
    var machine = codegen.x86_64.MachineFunction.init("fshl_i32", .{ .int = 32 });
    defer machine.deinit(std.testing.allocator);
    try machine.instructions.append(std.testing.allocator, .{ .fshl_eax_arg32_imm5 = .{ .reg = .rcx, .amount = 1 } });
    try machine.instructions.append(std.testing.allocator, .{ .fshl_eax_arg32_imm5 = .{ .reg = .r8, .amount = 1 } });
    try machine.instructions.append(std.testing.allocator, .ret);

    try std.testing.expectEqual(@as(u32, 4), mc.encoding.instructionSize(.{ .fshl_eax_arg32_imm5 = .{ .reg = .rcx, .amount = 1 } }));
    try std.testing.expectEqual(@as(u32, 5), mc.encoding.instructionSize(.{ .fshl_eax_arg32_imm5 = .{ .reg = .r8, .amount = 1 } }));
    const bytes = try mc.encoding.encodeFunction(std.testing.allocator, machine);
    defer std.testing.allocator.free(bytes);
    try std.testing.expectEqualSlices(u8, &.{
        0x0f, 0xa4, 0xc8, 0x01,
        0x44, 0x0f, 0xa4, 0xc0,
        0x01, 0xc3,
    }, bytes);
}

test "x86_64 encoding emits i32 absolute value" {
    var machine = codegen.x86_64.MachineFunction.init("abs_i32", .{ .int = 32 });
    defer machine.deinit(std.testing.allocator);
    try machine.instructions.append(std.testing.allocator, .abs_i32_edi_eax);
    try machine.instructions.append(std.testing.allocator, .ret);

    try std.testing.expectEqual(@as(u32, 11), mc.encoding.instructionSize(.abs_i32_edi_eax));
    const bytes = try mc.encoding.encodeFunction(std.testing.allocator, machine);
    defer std.testing.allocator.free(bytes);
    try std.testing.expectEqualSlices(u8, &.{
        0x89, 0xf8,
        0x89, 0xfa,
        0xf7, 0xda,
        0x85, 0xff,
        0x0f, 0x48,
        0xc2, 0xc3,
    }, bytes);
}

test "x86_64 encoding emits variable eax shifts" {
    var machine = codegen.x86_64.MachineFunction.init("variable_eax_shifts", .{ .int = 32 });
    defer machine.deinit(std.testing.allocator);
    try machine.instructions.append(std.testing.allocator, .shl_eax_cl);
    try machine.instructions.append(std.testing.allocator, .shr_eax_cl);
    try machine.instructions.append(std.testing.allocator, .sar_eax_cl);
    try machine.instructions.append(std.testing.allocator, .shr_rax_cl);
    try machine.instructions.append(std.testing.allocator, .{ .sar_eax_imm5 = 7 });
    try machine.instructions.append(std.testing.allocator, .ret);

    try std.testing.expectEqual(@as(u32, 2), mc.encoding.instructionSize(.shl_eax_cl));
    try std.testing.expectEqual(@as(u32, 2), mc.encoding.instructionSize(.shr_eax_cl));
    try std.testing.expectEqual(@as(u32, 2), mc.encoding.instructionSize(.sar_eax_cl));
    try std.testing.expectEqual(@as(u32, 3), mc.encoding.instructionSize(.shr_rax_cl));
    try std.testing.expectEqual(@as(u32, 3), mc.encoding.instructionSize(.{ .sar_eax_imm5 = 7 }));
    const bytes = try mc.encoding.encodeFunction(std.testing.allocator, machine);
    defer std.testing.allocator.free(bytes);
    try std.testing.expectEqualSlices(u8, &.{ 0xd3, 0xe0, 0xd3, 0xe8, 0xd3, 0xf8, 0x48, 0xd3, 0xe8, 0xc1, 0xf8, 0x07, 0xc3 }, bytes);
}

test "x86_64 encoding sizes high-register rcx compare before backedge" {
    var machine = codegen.x86_64.MachineFunction.init("high_reg_compare_backedge", .void);
    defer machine.deinit(std.testing.allocator);
    try machine.instructions.append(std.testing.allocator, .{ .label = "loop" });
    try machine.instructions.append(std.testing.allocator, .{ .cmp_rcx_arg64 = .r8 });
    try machine.instructions.append(std.testing.allocator, .{ .jmp = "loop" });
    try machine.instructions.append(std.testing.allocator, .ret);

    try std.testing.expectEqual(@as(u32, 3), mc.encoding.instructionSize(.{ .cmp_rcx_arg64 = .r8 }));
    const bytes = try mc.encoding.encodeFunction(std.testing.allocator, machine);
    defer std.testing.allocator.free(bytes);
    try std.testing.expectEqualSlices(u8, &.{
        0x49, 0x39, 0xc8,
        0xe9, 0xf8, 0xff,
        0xff, 0xff, 0xc3,
    }, bytes);
}

test "x86_64 encoding emits flag-preserving signed greater setcc" {
    var machine = codegen.x86_64.MachineFunction.init("setg", .{ .int = 32 });
    defer machine.deinit(std.testing.allocator);
    try machine.instructions.append(std.testing.allocator, .{ .cmp_eax_imm32 = 15 });
    try machine.instructions.append(std.testing.allocator, .setg_eax);
    try machine.instructions.append(std.testing.allocator, .ret);

    try std.testing.expectEqual(@as(u32, 6), mc.encoding.instructionSize(.setg_eax));
    const bytes = try mc.encoding.encodeFunction(std.testing.allocator, machine);
    defer std.testing.allocator.free(bytes);
    try std.testing.expectEqualSlices(u8, &.{
        0x3d, 0x0f, 0x00, 0x00, 0x00,
        0x0f, 0x9f, 0xc0, 0x0f, 0xb6,
        0xc0, 0xc3,
    }, bytes);
}

test "x86_64 encoding emits imul arg64 by rax" {
    var machine = codegen.x86_64.MachineFunction.init("imul_rax", .void);
    defer machine.deinit(std.testing.allocator);
    try machine.instructions.append(std.testing.allocator, .{ .imul_arg64_rax = .rdx });
    try machine.instructions.append(std.testing.allocator, .{ .imul_arg64_rax = .r8 });
    try machine.instructions.append(std.testing.allocator, .{ .imul_rax_arg64 = .rsi });
    try machine.instructions.append(std.testing.allocator, .{ .imul_rax_arg64 = .r9 });
    try machine.instructions.append(std.testing.allocator, .{ .imul_rax_rsp = .slot10 });
    try machine.instructions.append(std.testing.allocator, .ret);

    try std.testing.expectEqual(@as(u32, 4), mc.encoding.instructionSize(.{ .imul_arg64_rax = .rdx }));
    try std.testing.expectEqual(@as(u32, 4), mc.encoding.instructionSize(.{ .imul_arg64_rax = .r8 }));
    try std.testing.expectEqual(@as(u32, 4), mc.encoding.instructionSize(.{ .imul_rax_arg64 = .rsi }));
    try std.testing.expectEqual(@as(u32, 4), mc.encoding.instructionSize(.{ .imul_rax_arg64 = .r9 }));
    try std.testing.expectEqual(@as(u32, 6), mc.encoding.instructionSize(.{ .imul_rax_rsp = .slot10 }));
    const bytes = try mc.encoding.encodeFunction(std.testing.allocator, machine);
    defer std.testing.allocator.free(bytes);
    try std.testing.expectEqualSlices(u8, &.{
        0x48, 0x0f, 0xaf, 0xd0,
        0x4c, 0x0f, 0xaf, 0xc0,
        0x48, 0x0f, 0xaf, 0xc6,
        0x49, 0x0f, 0xaf, 0xc1,
        0x48, 0x0f, 0xaf, 0x44,
        0x24, 0x28, 0xc3,
    }, bytes);
}

test "x86_64 encoding emits and executes full-width multiply" {
    var encoding_machine = codegen.x86_64.MachineFunction.init("full_mul_encoding", .void);
    defer encoding_machine.deinit(std.testing.allocator);
    try encoding_machine.instructions.append(std.testing.allocator, .{ .mul_rax_arg64_full = .rsi });
    try encoding_machine.instructions.append(std.testing.allocator, .{ .mul_rax_arg64_full = .r9 });
    try encoding_machine.instructions.append(std.testing.allocator, .{ .imul_rax_arg64_full = .rdx });
    try encoding_machine.instructions.append(std.testing.allocator, .{ .imul_rax_arg64_full = .r8 });
    try encoding_machine.instructions.append(std.testing.allocator, .ret);

    try std.testing.expectEqual(@as(u32, 3), mc.encoding.instructionSize(.{ .mul_rax_arg64_full = .rsi }));
    try std.testing.expectEqual(@as(u32, 4), mc.encoding.instructionSize(.{ .mul_rax_arg64_full = .r9 }));
    try std.testing.expectEqual(@as(u32, 3), mc.encoding.instructionSize(.{ .imul_rax_arg64_full = .rdx }));
    try std.testing.expectEqual(@as(u32, 4), mc.encoding.instructionSize(.{ .imul_rax_arg64_full = .r8 }));
    const encoding_bytes = try mc.encoding.encodeFunction(std.testing.allocator, encoding_machine);
    defer std.testing.allocator.free(encoding_bytes);
    try std.testing.expectEqualSlices(u8, &.{
        0x48, 0xf7, 0xe6,
        0x49, 0xf7, 0xe1,
        0x48, 0xf7, 0xea,
        0x49, 0xf7, 0xe8,
        0xc3,
    }, encoding_bytes);

    const FullUnsignedProduct = *const fn (u64, u64) callconv(.c) u128;
    var unsigned_machine = codegen.x86_64.MachineFunction.init("full_unsigned_product", .{ .int = 128 });
    defer unsigned_machine.deinit(std.testing.allocator);
    try unsigned_machine.instructions.append(std.testing.allocator, .{ .mov_arg_rax = .rdi });
    try unsigned_machine.instructions.append(std.testing.allocator, .{ .mul_rax_arg64_full = .rsi });
    try unsigned_machine.instructions.append(std.testing.allocator, .ret);
    const unsigned_bytes = try mc.encoding.encodeFunction(std.testing.allocator, unsigned_machine);
    defer std.testing.allocator.free(unsigned_bytes);
    const unsigned_mapping = try std.posix.mmap(
        null,
        unsigned_bytes.len,
        .{ .READ = true, .WRITE = true, .EXEC = true },
        .{ .TYPE = .PRIVATE, .ANONYMOUS = true },
        -1,
        0,
    );
    defer std.posix.munmap(unsigned_mapping);
    @memcpy(unsigned_mapping, unsigned_bytes);
    const fullUnsignedProduct: FullUnsignedProduct = @ptrCast(unsigned_mapping.ptr);
    const unsigned_lhs = std.math.maxInt(u64);
    const unsigned_rhs: u64 = 2;
    try std.testing.expectEqual(@as(u128, unsigned_lhs) * unsigned_rhs, fullUnsignedProduct(unsigned_lhs, unsigned_rhs));

    const FullSignedProduct = *const fn (i64, i64) callconv(.c) i128;
    var signed_machine = codegen.x86_64.MachineFunction.init("full_signed_product", .{ .int = 128 });
    defer signed_machine.deinit(std.testing.allocator);
    try signed_machine.instructions.append(std.testing.allocator, .{ .mov_arg_rax = .rdi });
    try signed_machine.instructions.append(std.testing.allocator, .{ .imul_rax_arg64_full = .rsi });
    try signed_machine.instructions.append(std.testing.allocator, .ret);
    const signed_bytes = try mc.encoding.encodeFunction(std.testing.allocator, signed_machine);
    defer std.testing.allocator.free(signed_bytes);
    const signed_mapping = try std.posix.mmap(
        null,
        signed_bytes.len,
        .{ .READ = true, .WRITE = true, .EXEC = true },
        .{ .TYPE = .PRIVATE, .ANONYMOUS = true },
        -1,
        0,
    );
    defer std.posix.munmap(signed_mapping);
    @memcpy(signed_mapping, signed_bytes);
    const fullSignedProduct: FullSignedProduct = @ptrCast(signed_mapping.ptr);
    try std.testing.expectEqual(@as(i128, -3) * 7, fullSignedProduct(-3, 7));
}

test "x86_64 encoding executes add-carry immediate zero" {
    var machine = codegen.x86_64.MachineFunction.init("add_carry_zero", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);
    try machine.instructions.append(std.testing.allocator, .{ .mov_imm_rax = -1 });
    try machine.instructions.append(std.testing.allocator, .{ .mov_imm_rcx = 1 });
    try machine.instructions.append(std.testing.allocator, .{ .add_arg64_rax = .rcx });
    try machine.instructions.append(std.testing.allocator, .adc_rax_imm0);
    try machine.instructions.append(std.testing.allocator, .ret);

    try std.testing.expectEqual(@as(u32, 4), mc.encoding.instructionSize(.adc_rax_imm0));
    const bytes = try mc.encoding.encodeFunction(std.testing.allocator, machine);
    defer std.testing.allocator.free(bytes);
    try std.testing.expectEqualSlices(u8, &.{
        0x48, 0xb8, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
        0x48, 0xb9, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x48, 0x01, 0xc8, 0x48, 0x83, 0xd0, 0x00, 0xc3,
    }, bytes);

    const mapping = try std.posix.mmap(
        null,
        bytes.len,
        .{ .READ = true, .WRITE = true, .EXEC = true },
        .{ .TYPE = .PRIVATE, .ANONYMOUS = true },
        -1,
        0,
    );
    defer std.posix.munmap(mapping);
    @memcpy(mapping, bytes);
    const addCarry: *const fn () callconv(.c) u64 = @ptrCast(mapping.ptr);
    try std.testing.expectEqual(@as(u64, 1), addCarry());
}

test "x86_64 encoding sizes nonzero frame spill slots" {
    var machine = codegen.x86_64.MachineFunction.init("frame_slots", .{ .int = 32 });
    defer machine.deinit(std.testing.allocator);
    try machine.instructions.append(std.testing.allocator, .sub_rsp_40);
    try machine.instructions.append(std.testing.allocator, .{ .spill_eax_rsp = .slot0 });
    try machine.instructions.append(std.testing.allocator, .{ .spill_arg_rsp = .{ .frame_index = .slot1, .reg = .rsi } });
    try machine.instructions.append(std.testing.allocator, .{ .reload_arg_rsp = .{ .reg = .rdx, .frame_index = .slot2 } });
    try machine.instructions.append(std.testing.allocator, .{ .spill_arg64_rsp = .{ .frame_index = .slot2, .reg = .rdi } });
    try machine.instructions.append(std.testing.allocator, .{ .reload_arg64_rsp = .{ .reg = .rsi, .frame_index = .slot2 } });
    try machine.instructions.append(std.testing.allocator, .{ .spill_arg_rsp = .{ .frame_index = .slot5, .reg = .r9 } });
    try machine.instructions.append(std.testing.allocator, .{ .reload_arg_rsp = .{ .reg = .r8, .frame_index = .slot4 } });
    try machine.instructions.append(std.testing.allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(std.testing.allocator, .add_rsp_40);
    try machine.instructions.append(std.testing.allocator, .ret);

    try std.testing.expectEqual(@as(u32, 3), mc.encoding.instructionSize(.{ .spill_eax_rsp = .slot0 }));
    try std.testing.expectEqual(@as(u32, 4), mc.encoding.instructionSize(.{ .spill_arg_rsp = .{ .frame_index = .slot1, .reg = .rsi } }));
    try std.testing.expectEqual(@as(u32, 4), mc.encoding.instructionSize(.{ .reload_arg_rsp = .{ .reg = .rdx, .frame_index = .slot2 } }));
    try std.testing.expectEqual(@as(u32, 5), mc.encoding.instructionSize(.{ .spill_arg64_rsp = .{ .frame_index = .slot2, .reg = .rdi } }));
    try std.testing.expectEqual(@as(u32, 5), mc.encoding.instructionSize(.{ .reload_arg64_rsp = .{ .reg = .rsi, .frame_index = .slot2 } }));
    try std.testing.expectEqual(@as(u32, 5), mc.encoding.instructionSize(.{ .spill_arg_rsp = .{ .frame_index = .slot5, .reg = .r9 } }));
    try std.testing.expectEqual(@as(u32, 5), mc.encoding.instructionSize(.{ .reload_arg_rsp = .{ .reg = .r8, .frame_index = .slot4 } }));
    const bytes = try mc.encoding.encodeFunction(std.testing.allocator, machine);
    defer std.testing.allocator.free(bytes);
    try std.testing.expectEqualSlices(u8, &.{
        0x48, 0x83, 0xec, 0x28,
        0x89, 0x04, 0x24, 0x89,
        0x74, 0x24, 0x04, 0x8b,
        0x54, 0x24, 0x08, 0x48,
        0x89, 0x7c, 0x24, 0x08,
        0x48, 0x8b, 0x74, 0x24,
        0x08, 0x44, 0x89, 0x4c,
        0x24, 0x14, 0x44, 0x8b,
        0x44, 0x24, 0x10, 0xb8,
        0x00, 0x00, 0x00, 0x00,
        0x48, 0x83, 0xc4, 0x28,
        0xc3,
    }, bytes);
}

test "x86_64 encoding uses disp32 for high frame spill slots" {
    var machine = codegen.x86_64.MachineFunction.init("high_frame_slots", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);
    const high_slot = try codegen.x86_64.FrameIndex.fromSlot(80);
    try machine.instructions.append(std.testing.allocator, .{ .sub_rsp_imm32 = 328 });
    try machine.instructions.append(std.testing.allocator, .{ .spill_arg64_rsp = .{ .frame_index = high_slot, .reg = .rdi } });
    try machine.instructions.append(std.testing.allocator, .{ .reload_arg64_rsp = .{ .reg = .rsi, .frame_index = high_slot } });
    try machine.instructions.append(std.testing.allocator, .{ .spill_arg_rsp = .{ .frame_index = high_slot, .reg = .r9 } });
    try machine.instructions.append(std.testing.allocator, .{ .reload_arg_rsp = .{ .reg = .r8, .frame_index = high_slot } });
    try machine.instructions.append(std.testing.allocator, .{ .reload_rsp_eax = high_slot });
    try machine.instructions.append(std.testing.allocator, .{ .reload_rsp_rax = high_slot });
    try machine.instructions.append(std.testing.allocator, .{ .add_rsp_imm32 = 328 });
    try machine.instructions.append(std.testing.allocator, .ret);

    try std.testing.expectEqual(@as(u32, 8), mc.encoding.instructionSize(.{ .spill_arg64_rsp = .{ .frame_index = high_slot, .reg = .rdi } }));
    try std.testing.expectEqual(@as(u32, 8), mc.encoding.instructionSize(.{ .reload_arg64_rsp = .{ .reg = .rsi, .frame_index = high_slot } }));
    try std.testing.expectEqual(@as(u32, 8), mc.encoding.instructionSize(.{ .spill_arg_rsp = .{ .frame_index = high_slot, .reg = .r9 } }));
    try std.testing.expectEqual(@as(u32, 8), mc.encoding.instructionSize(.{ .reload_arg_rsp = .{ .reg = .r8, .frame_index = high_slot } }));
    try std.testing.expectEqual(@as(u32, 7), mc.encoding.instructionSize(.{ .reload_rsp_eax = high_slot }));
    try std.testing.expectEqual(@as(u32, 8), mc.encoding.instructionSize(.{ .reload_rsp_rax = high_slot }));
    const bytes = try mc.encoding.encodeFunction(std.testing.allocator, machine);
    defer std.testing.allocator.free(bytes);
    try std.testing.expectEqualSlices(u8, &.{
        0x48, 0x81, 0xec, 0x48,
        0x01, 0x00, 0x00, 0x48,
        0x89, 0xbc, 0x24, 0x40,
        0x01, 0x00, 0x00, 0x48,
        0x8b, 0xb4, 0x24, 0x40,
        0x01, 0x00, 0x00, 0x44,
        0x89, 0x8c, 0x24, 0x40,
        0x01, 0x00, 0x00, 0x44,
        0x8b, 0x84, 0x24, 0x40,
        0x01, 0x00, 0x00, 0x8b,
        0x84, 0x24, 0x40, 0x01,
        0x00, 0x00, 0x48, 0x8b,
        0x84, 0x24, 0x40, 0x01,
        0x00, 0x00, 0x48, 0x81,
        0xc4, 0x48, 0x01, 0x00,
        0x00, 0xc3,
    }, bytes);
}

test "x86_64 encoding sizes high-register 64-bit frame slots" {
    var machine = codegen.x86_64.MachineFunction.init("high_reg_frame_slots", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);
    try machine.instructions.append(std.testing.allocator, .sub_rsp_24);
    try machine.instructions.append(std.testing.allocator, .{ .spill_arg64_rsp = .{ .frame_index = .slot2, .reg = .r8 } });
    try machine.instructions.append(std.testing.allocator, .{ .reload_arg64_rsp = .{ .reg = .r9, .frame_index = .slot2 } });
    try machine.instructions.append(std.testing.allocator, .{ .reload_rsp_rax = .slot2 });
    try machine.instructions.append(std.testing.allocator, .add_rsp_24);
    try machine.instructions.append(std.testing.allocator, .ret);

    try std.testing.expectEqual(@as(u32, 5), mc.encoding.instructionSize(.{ .spill_arg64_rsp = .{ .frame_index = .slot2, .reg = .r8 } }));
    try std.testing.expectEqual(@as(u32, 5), mc.encoding.instructionSize(.{ .reload_arg64_rsp = .{ .reg = .r9, .frame_index = .slot2 } }));
    const bytes = try mc.encoding.encodeFunction(std.testing.allocator, machine);
    defer std.testing.allocator.free(bytes);
    try std.testing.expectEqualSlices(u8, &.{
        0x48, 0x83, 0xec, 0x18,
        0x4c, 0x89, 0x44, 0x24,
        0x08, 0x4c, 0x8b, 0x4c,
        0x24, 0x08, 0x48, 0x8b,
        0x44, 0x24, 0x08, 0x48,
        0x83, 0xc4, 0x18, 0xc3,
    }, bytes);
}

test "x86_64 encoding stores rax through argument pointer displacement" {
    var machine = codegen.x86_64.MachineFunction.init("store_rax_ptr", .void);
    defer machine.deinit(std.testing.allocator);
    try machine.instructions.append(std.testing.allocator, .{ .store_rax_arg_ptr_disp8 = .{ .reg = .rdi, .offset = 16 } });
    try machine.instructions.append(std.testing.allocator, .ret);

    try std.testing.expectEqual(@as(u32, 4), mc.encoding.instructionSize(.{ .store_rax_arg_ptr_disp8 = .{ .reg = .rdi, .offset = 16 } }));
    const bytes = try mc.encoding.encodeFunction(std.testing.allocator, machine);
    defer std.testing.allocator.free(bytes);
    try std.testing.expectEqualSlices(u8, &.{ 0x48, 0x89, 0x47, 0x10, 0xc3 }, bytes);
}

test "x86_64 encoding stores eax through argument pointer displacement" {
    var machine = codegen.x86_64.MachineFunction.init("store_eax_ptr", .void);
    defer machine.deinit(std.testing.allocator);
    try machine.instructions.append(std.testing.allocator, .{ .store_eax_arg_ptr_disp8 = .{ .reg = .rdi, .offset = 12 } });
    try machine.instructions.append(std.testing.allocator, .ret);

    try std.testing.expectEqual(@as(u32, 3), mc.encoding.instructionSize(.{ .store_eax_arg_ptr_disp8 = .{ .reg = .rdi, .offset = 12 } }));
    const bytes = try mc.encoding.encodeFunction(std.testing.allocator, machine);
    defer std.testing.allocator.free(bytes);
    try std.testing.expectEqualSlices(u8, &.{ 0x89, 0x47, 0x0c, 0xc3 }, bytes);
}

test "x86_64 encoding stores al through stack displacements" {
    var machine = codegen.x86_64.MachineFunction.init("store_al_stack", .void);
    defer machine.deinit(std.testing.allocator);
    try machine.instructions.append(std.testing.allocator, .{ .sub_rsp_imm32 = 264 });
    try machine.instructions.append(std.testing.allocator, .{ .store_al_stack_disp8 = 12 });
    try machine.instructions.append(std.testing.allocator, .{ .store_al_stack_disp32 = 260 });
    try machine.instructions.append(std.testing.allocator, .{ .add_rsp_imm32 = 264 });
    try machine.instructions.append(std.testing.allocator, .ret);

    try std.testing.expectEqual(@as(u32, 4), mc.encoding.instructionSize(.{ .store_al_stack_disp8 = 12 }));
    try std.testing.expectEqual(@as(u32, 7), mc.encoding.instructionSize(.{ .store_al_stack_disp32 = 260 }));
    const bytes = try mc.encoding.encodeFunction(std.testing.allocator, machine);
    defer std.testing.allocator.free(bytes);
    try std.testing.expectEqualSlices(u8, &.{
        0x48, 0x81, 0xec, 0x08, 0x01, 0x00, 0x00,
        0x88, 0x44, 0x24, 0x0c, 0x88, 0x84, 0x24,
        0x04, 0x01, 0x00, 0x00, 0x48, 0x81, 0xc4,
        0x08, 0x01, 0x00, 0x00, 0xc3,
    }, bytes);
}

test "x86_64 encoding copies narrow stack integers through argument pointer displacement" {
    var machine = codegen.x86_64.MachineFunction.init("copy_narrow_stack_ptr", .void);
    defer machine.deinit(std.testing.allocator);
    try machine.instructions.append(std.testing.allocator, .{ .load_stack_disp8_eax = 8 });
    try machine.instructions.append(std.testing.allocator, .{ .store_eax_arg_ptr_disp8 = .{ .reg = .rdi, .offset = 0 } });
    try machine.instructions.append(std.testing.allocator, .{ .load_stack_disp8_u8_eax = 16 });
    try machine.instructions.append(std.testing.allocator, .{ .store_al_arg_ptr_disp8 = .{ .reg = .rdi, .offset = 5 } });
    try machine.instructions.append(std.testing.allocator, .{ .load_stack_disp8_u16_eax = 24 });
    try machine.instructions.append(std.testing.allocator, .{ .store_ax_arg_ptr_disp8 = .{ .reg = .rdi, .offset = 6 } });
    try machine.instructions.append(std.testing.allocator, .ret);

    try std.testing.expectEqual(@as(u32, 4), mc.encoding.instructionSize(.{ .load_stack_disp8_eax = 8 }));
    try std.testing.expectEqual(@as(u32, 2), mc.encoding.instructionSize(.{ .store_eax_arg_ptr_disp8 = .{ .reg = .rdi, .offset = 0 } }));
    try std.testing.expectEqual(@as(u32, 5), mc.encoding.instructionSize(.{ .load_stack_disp8_u8_eax = 16 }));
    try std.testing.expectEqual(@as(u32, 3), mc.encoding.instructionSize(.{ .store_al_arg_ptr_disp8 = .{ .reg = .rdi, .offset = 5 } }));
    try std.testing.expectEqual(@as(u32, 5), mc.encoding.instructionSize(.{ .load_stack_disp8_u16_eax = 24 }));
    try std.testing.expectEqual(@as(u32, 4), mc.encoding.instructionSize(.{ .store_ax_arg_ptr_disp8 = .{ .reg = .rdi, .offset = 6 } }));
    const bytes = try mc.encoding.encodeFunction(std.testing.allocator, machine);
    defer std.testing.allocator.free(bytes);
    try std.testing.expectEqualSlices(u8, &.{
        0x8b, 0x44, 0x24, 0x08, 0x89,
        0x07, 0x0f, 0xb6, 0x44, 0x24,
        0x10, 0x88, 0x47, 0x05, 0x0f,
        0xb7, 0x44, 0x24, 0x18, 0x66,
        0x89, 0x47, 0x06, 0xc3,
    }, bytes);
}

test "x86_64 encoding stores through argument pointer disp32" {
    var machine = codegen.x86_64.MachineFunction.init("store_ptr_disp32", .void);
    defer machine.deinit(std.testing.allocator);
    try machine.instructions.append(std.testing.allocator, .{ .store_arg64_arg_ptr_disp32 = .{ .ptr_reg = .rdi, .src_reg = .rsi, .offset = 128 } });
    try machine.instructions.append(std.testing.allocator, .{ .store_rax_arg_ptr_disp32 = .{ .reg = .rdi, .offset = 136 } });
    try machine.instructions.append(std.testing.allocator, .{ .store_eax_arg_ptr_disp32 = .{ .reg = .rdi, .offset = 144 } });
    try machine.instructions.append(std.testing.allocator, .ret);

    try std.testing.expectEqual(@as(u32, 7), mc.encoding.instructionSize(.{ .store_arg64_arg_ptr_disp32 = .{ .ptr_reg = .rdi, .src_reg = .rsi, .offset = 128 } }));
    try std.testing.expectEqual(@as(u32, 7), mc.encoding.instructionSize(.{ .store_rax_arg_ptr_disp32 = .{ .reg = .rdi, .offset = 136 } }));
    try std.testing.expectEqual(@as(u32, 6), mc.encoding.instructionSize(.{ .store_eax_arg_ptr_disp32 = .{ .reg = .rdi, .offset = 144 } }));
    const bytes = try mc.encoding.encodeFunction(std.testing.allocator, machine);
    defer std.testing.allocator.free(bytes);
    try std.testing.expectEqualSlices(u8, &.{
        0x48, 0x89, 0xb7, 0x80, 0x00, 0x00, 0x00,
        0x48, 0x89, 0x87, 0x88, 0x00, 0x00, 0x00,
        0x89, 0x87, 0x90, 0x00, 0x00, 0x00, 0xc3,
    }, bytes);
}

test "x86_64 encoding loads and stores xmm0 through stack and argument pointer displacements" {
    var machine = codegen.x86_64.MachineFunction.init("copy_xmm0_ptr", .void);
    defer machine.deinit(std.testing.allocator);
    try machine.instructions.append(std.testing.allocator, .{ .load_stack_disp8_xmm0 = 16 });
    try machine.instructions.append(std.testing.allocator, .{ .store_xmm0_arg_ptr_disp8 = .{ .reg = .rdi, .offset = 24 } });
    try machine.instructions.append(std.testing.allocator, .{ .load_stack_disp32_xmm0 = 128 });
    try machine.instructions.append(std.testing.allocator, .{ .store_xmm0_arg_ptr_disp32 = .{ .reg = .rdi, .offset = 136 } });
    try machine.instructions.append(std.testing.allocator, .ret);

    try std.testing.expectEqual(@as(u32, 6), mc.encoding.instructionSize(.{ .load_stack_disp8_xmm0 = 16 }));
    try std.testing.expectEqual(@as(u32, 5), mc.encoding.instructionSize(.{ .store_xmm0_arg_ptr_disp8 = .{ .reg = .rdi, .offset = 24 } }));
    try std.testing.expectEqual(@as(u32, 9), mc.encoding.instructionSize(.{ .load_stack_disp32_xmm0 = 128 }));
    try std.testing.expectEqual(@as(u32, 8), mc.encoding.instructionSize(.{ .store_xmm0_arg_ptr_disp32 = .{ .reg = .rdi, .offset = 136 } }));
    const bytes = try mc.encoding.encodeFunction(std.testing.allocator, machine);
    defer std.testing.allocator.free(bytes);
    try std.testing.expectEqualSlices(u8, &.{
        0xf2, 0x0f, 0x10, 0x44, 0x24, 0x10,
        0xf2, 0x0f, 0x11, 0x47, 0x18, 0xf2,
        0x0f, 0x10, 0x84, 0x24, 0x80, 0x00,
        0x00, 0x00, 0xf2, 0x0f, 0x11, 0x87,
        0x88, 0x00, 0x00, 0x00, 0xc3,
    }, bytes);
}

test "x86_64 encoding loads and stores f32 xmm0 through stack and argument pointer displacements" {
    var machine = codegen.x86_64.MachineFunction.init("copy_xmm0_f32_ptr", .void);
    defer machine.deinit(std.testing.allocator);
    try machine.instructions.append(std.testing.allocator, .{ .load_stack_disp8_xmm0_f32 = 16 });
    try machine.instructions.append(std.testing.allocator, .{ .store_xmm0_f32_arg_ptr_disp8 = .{ .reg = .rdi, .offset = 24 } });
    try machine.instructions.append(std.testing.allocator, .{ .load_stack_disp32_xmm0_f32 = 128 });
    try machine.instructions.append(std.testing.allocator, .{ .store_xmm0_f32_arg_ptr_disp32 = .{ .reg = .rdi, .offset = 136 } });
    try machine.instructions.append(std.testing.allocator, .ret);

    try std.testing.expectEqual(@as(u32, 6), mc.encoding.instructionSize(.{ .load_stack_disp8_xmm0_f32 = 16 }));
    try std.testing.expectEqual(@as(u32, 5), mc.encoding.instructionSize(.{ .store_xmm0_f32_arg_ptr_disp8 = .{ .reg = .rdi, .offset = 24 } }));
    try std.testing.expectEqual(@as(u32, 9), mc.encoding.instructionSize(.{ .load_stack_disp32_xmm0_f32 = 128 }));
    try std.testing.expectEqual(@as(u32, 8), mc.encoding.instructionSize(.{ .store_xmm0_f32_arg_ptr_disp32 = .{ .reg = .rdi, .offset = 136 } }));
    const bytes = try mc.encoding.encodeFunction(std.testing.allocator, machine);
    defer std.testing.allocator.free(bytes);
    try std.testing.expectEqualSlices(u8, &.{
        0xf3, 0x0f, 0x10, 0x44, 0x24, 0x10,
        0xf3, 0x0f, 0x11, 0x47, 0x18, 0xf3,
        0x0f, 0x10, 0x84, 0x24, 0x80, 0x00,
        0x00, 0x00, 0xf3, 0x0f, 0x11, 0x87,
        0x88, 0x00, 0x00, 0x00, 0xc3,
    }, bytes);
}

test "x86_64 encoding loads stack displacements into arbitrary xmm registers" {
    var machine = codegen.x86_64.MachineFunction.init("load_xmm_stack", .void);
    defer machine.deinit(std.testing.allocator);
    try machine.instructions.append(std.testing.allocator, .{ .load_stack_disp8_xmm = .{ .reg = .xmm1, .disp = 16 } });
    try machine.instructions.append(std.testing.allocator, .{ .load_stack_disp32_xmm = .{ .reg = .xmm2, .disp = 128 } });
    try machine.instructions.append(std.testing.allocator, .{ .load_stack_disp8_xmm_f32 = .{ .reg = .xmm3, .disp = 24 } });
    try machine.instructions.append(std.testing.allocator, .{ .load_stack_disp32_xmm_f32 = .{ .reg = .xmm4, .disp = 136 } });
    try machine.instructions.append(std.testing.allocator, .ret);

    try std.testing.expectEqual(@as(u32, 6), mc.encoding.instructionSize(.{ .load_stack_disp8_xmm = .{ .reg = .xmm1, .disp = 16 } }));
    try std.testing.expectEqual(@as(u32, 9), mc.encoding.instructionSize(.{ .load_stack_disp32_xmm = .{ .reg = .xmm2, .disp = 128 } }));
    try std.testing.expectEqual(@as(u32, 6), mc.encoding.instructionSize(.{ .load_stack_disp8_xmm_f32 = .{ .reg = .xmm3, .disp = 24 } }));
    try std.testing.expectEqual(@as(u32, 9), mc.encoding.instructionSize(.{ .load_stack_disp32_xmm_f32 = .{ .reg = .xmm4, .disp = 136 } }));
    const bytes = try mc.encoding.encodeFunction(std.testing.allocator, machine);
    defer std.testing.allocator.free(bytes);
    try std.testing.expectEqualSlices(u8, &.{
        0xf2, 0x0f, 0x10, 0x4c, 0x24, 0x10,
        0xf2, 0x0f, 0x10, 0x94, 0x24, 0x80,
        0x00, 0x00, 0x00, 0xf3, 0x0f, 0x10,
        0x5c, 0x24, 0x18, 0xf3, 0x0f, 0x10,
        0xa4, 0x24, 0x88, 0x00, 0x00, 0x00,
        0xc3,
    }, bytes);
}

test "x86_64 encoding spills and reloads xmm frame slots" {
    var machine = codegen.x86_64.MachineFunction.init("xmm_frame_slots", .double);
    defer machine.deinit(std.testing.allocator);
    try machine.instructions.append(std.testing.allocator, .sub_rsp_8);
    try machine.instructions.append(std.testing.allocator, .{ .spill_xmm64_rsp = .{ .reg = .xmm1, .frame_index = .slot0 } });
    try machine.instructions.append(std.testing.allocator, .{ .reload_xmm64_rsp = .{ .reg = .xmm0, .frame_index = .slot0 } });
    try machine.instructions.append(std.testing.allocator, .add_rsp_8);
    try machine.instructions.append(std.testing.allocator, .ret);

    try std.testing.expectEqual(@as(u32, 5), mc.encoding.instructionSize(.{ .spill_xmm64_rsp = .{ .reg = .xmm1, .frame_index = .slot0 } }));
    try std.testing.expectEqual(@as(u32, 5), mc.encoding.instructionSize(.{ .reload_xmm64_rsp = .{ .reg = .xmm0, .frame_index = .slot0 } }));
    const bytes = try mc.encoding.encodeFunction(std.testing.allocator, machine);
    defer std.testing.allocator.free(bytes);
    try std.testing.expectEqualSlices(u8, &.{
        0x48, 0x83, 0xec, 0x08,
        0xf2, 0x0f, 0x11, 0x0c,
        0x24, 0xf2, 0x0f, 0x10,
        0x04, 0x24, 0x48, 0x83,
        0xc4, 0x08, 0xc3,
    }, bytes);
}

test "x86_64 encoding materializes FP immediates into generic xmm registers" {
    var machine = codegen.x86_64.MachineFunction.init("xmm_immediates", .void);
    defer machine.deinit(std.testing.allocator);
    try machine.instructions.append(std.testing.allocator, .{ .mov_imm32_xmm = .{ .reg = .xmm2, .bits = 0x4040_0000 } });
    try machine.instructions.append(std.testing.allocator, .{ .mov_imm64_xmm = .{ .reg = .xmm7, .bits = 0x4008_0000_0000_0000 } });
    try machine.instructions.append(std.testing.allocator, .ret);

    try std.testing.expectEqual(@as(u32, 9), mc.encoding.instructionSize(.{ .mov_imm32_xmm = .{ .reg = .xmm2, .bits = 0x4040_0000 } }));
    try std.testing.expectEqual(@as(u32, 15), mc.encoding.instructionSize(.{ .mov_imm64_xmm = .{ .reg = .xmm7, .bits = 0x4008_0000_0000_0000 } }));
    const bytes = try mc.encoding.encodeFunction(std.testing.allocator, machine);
    defer std.testing.allocator.free(bytes);
    try std.testing.expectEqualSlices(u8, &.{
        0xb8, 0x00, 0x00, 0x40, 0x40,
        0x66, 0x0f, 0x6e, 0xd0, 0x48,
        0xb8, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x08, 0x40, 0x66,
        0x48, 0x0f, 0x6e, 0xf8, 0xc3,
    }, bytes);
}
