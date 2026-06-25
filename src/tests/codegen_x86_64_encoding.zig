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
    try machine.instructions.append(std.testing.allocator, .ret);

    try std.testing.expectEqual(@as(u32, 6), mc.encoding.instructionSize(.{ .load_stack_disp8_xmm = .{ .reg = .xmm1, .disp = 16 } }));
    try std.testing.expectEqual(@as(u32, 9), mc.encoding.instructionSize(.{ .load_stack_disp32_xmm = .{ .reg = .xmm2, .disp = 128 } }));
    const bytes = try mc.encoding.encodeFunction(std.testing.allocator, machine);
    defer std.testing.allocator.free(bytes);
    try std.testing.expectEqualSlices(u8, &.{
        0xf2, 0x0f, 0x10, 0x4c, 0x24, 0x10,
        0xf2, 0x0f, 0x10, 0x94, 0x24, 0x80,
        0x00, 0x00, 0x00, 0xc3,
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

    try std.testing.expectEqual(@as(u32, 6), mc.encoding.instructionSize(.{ .spill_xmm64_rsp = .{ .reg = .xmm1, .frame_index = .slot0 } }));
    try std.testing.expectEqual(@as(u32, 6), mc.encoding.instructionSize(.{ .reload_xmm64_rsp = .{ .reg = .xmm0, .frame_index = .slot0 } }));
    const bytes = try mc.encoding.encodeFunction(std.testing.allocator, machine);
    defer std.testing.allocator.free(bytes);
    try std.testing.expectEqualSlices(u8, &.{
        0x48, 0x83, 0xec, 0x08,
        0xf2, 0x0f, 0x11, 0x4c,
        0x24, 0x00, 0xf2, 0x0f,
        0x10, 0x44, 0x24, 0x00,
        0x48, 0x83, 0xc4, 0x08,
        0xc3,
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
