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

test "x86_64 codegen lowers add args to assembly" {
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

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try mc.assembly.printFunction(machine, &output.writer);

    const expected =
        "\t.text\n" ++
        "\t.globl add_args\n" ++
        "add_args:\n" ++
        "\tmovl %edi, %eax\n" ++
        "\taddl %esi, %eax\n" ++
        "\tretq\n";
    try std.testing.expectEqualStrings(expected, output.writer.buffered());
}

test "x86_64 codegen lowers return constant and argument" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @return_constant() {
        \\entry:
        \\  ret i32 42
        \\}
        \\
        \\define i32 @return_arg(i32 %a) {
        \\entry:
        \\  ret i32 %a
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var constant = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer constant.deinit(std.testing.allocator);
    var arg = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[1]);
    defer arg.deinit(std.testing.allocator);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try mc.assembly.printFunction(constant, &output.writer);
    try mc.assembly.printFunction(arg, &output.writer);

    const expected =
        "\t.text\n" ++
        "\t.globl return_constant\n" ++
        "return_constant:\n" ++
        "\tmovl $42, %eax\n" ++
        "\tretq\n" ++
        "\t.text\n" ++
        "\t.globl return_arg\n" ++
        "return_arg:\n" ++
        "\tmovl %edi, %eax\n" ++
        "\tretq\n";
    try std.testing.expectEqualStrings(expected, output.writer.buffered());
}

test "x86_64 codegen lowers bitwise args to assembly" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @bitwise_args(i32 %a, i32 %b) {
        \\entry:
        \\  %v = xor i32 %a, %b
        \\  ret i32 %v
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try mc.assembly.printFunction(machine, &output.writer);

    const expected =
        "\t.text\n" ++
        "\t.globl bitwise_args\n" ++
        "bitwise_args:\n" ++
        "\tmovl %edi, %eax\n" ++
        "\txorl %esi, %eax\n" ++
        "\tretq\n";
    try std.testing.expectEqualStrings(expected, output.writer.buffered());
}

test "x86_64 codegen lowers simple conditional returns to assembly" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @select_return(i1 %cond, i32 %a, i32 %b) {
        \\entry:
        \\  br i1 %cond, label %then, label %else
        \\then:
        \\  ret i32 %a
        \\else:
        \\  ret i32 %b
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try mc.assembly.printFunction(machine, &output.writer);

    const expected =
        "\t.text\n" ++
        "\t.globl select_return\n" ++
        "select_return:\n" ++
        "\ttestb %dil, %dil\n" ++
        "\tje .Lselect_return_else\n" ++
        ".Lselect_return_then:\n" ++
        "\tmovl %esi, %eax\n" ++
        "\tretq\n" ++
        ".Lselect_return_else:\n" ++
        "\tmovl %edx, %eax\n" ++
        "\tretq\n";
    try std.testing.expectEqualStrings(expected, output.writer.buffered());
}

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
    try machine.instructions.append(std.testing.allocator, .{ .spill_arg_rsp = .{ .frame_index = .slot1, .reg = .rsi } });
    try machine.instructions.append(std.testing.allocator, .{ .reload_arg_rsp = .{ .reg = .rdx, .frame_index = .slot2 } });
    try machine.instructions.append(std.testing.allocator, .{ .spill_arg_rsp = .{ .frame_index = .slot5, .reg = .r9 } });
    try machine.instructions.append(std.testing.allocator, .{ .reload_arg_rsp = .{ .reg = .r8, .frame_index = .slot4 } });
    try machine.instructions.append(std.testing.allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(std.testing.allocator, .add_rsp_40);
    try machine.instructions.append(std.testing.allocator, .ret);

    try std.testing.expectEqual(@as(u32, 4), mc.encoding.instructionSize(.{ .spill_arg_rsp = .{ .frame_index = .slot1, .reg = .rsi } }));
    try std.testing.expectEqual(@as(u32, 4), mc.encoding.instructionSize(.{ .reload_arg_rsp = .{ .reg = .rdx, .frame_index = .slot2 } }));
    try std.testing.expectEqual(@as(u32, 5), mc.encoding.instructionSize(.{ .spill_arg_rsp = .{ .frame_index = .slot5, .reg = .r9 } }));
    try std.testing.expectEqual(@as(u32, 5), mc.encoding.instructionSize(.{ .reload_arg_rsp = .{ .reg = .r8, .frame_index = .slot4 } }));
    const bytes = try mc.encoding.encodeFunction(std.testing.allocator, machine);
    defer std.testing.allocator.free(bytes);
    try std.testing.expectEqualSlices(u8, &.{
        0x48, 0x83, 0xec, 0x28,
        0x89, 0x74, 0x24, 0x04,
        0x8b, 0x54, 0x24, 0x08,
        0x44, 0x89, 0x4c, 0x24,
        0x14, 0x44, 0x8b, 0x44,
        0x24, 0x10, 0xb8, 0x00,
        0x00, 0x00, 0x00, 0x48,
        0x83, 0xc4, 0x28, 0xc3,
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

test "x86_64 elf writer emits relocatable object metadata" {
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

    const object = try mc.elf.buildObject(std.testing.allocator, &.{machine});
    defer std.testing.allocator.free(object);

    try std.testing.expect(object.len >= 64);
    try std.testing.expectEqualSlices(u8, "\x7fELF", object[0..4]);
    try std.testing.expectEqual(@as(u8, 2), object[4]);
    try std.testing.expect(std.mem.indexOf(u8, object, ".text") != null);
    try std.testing.expect(std.mem.indexOf(u8, object, ".symtab") != null);
    try std.testing.expect(std.mem.indexOf(u8, object, "add_args") != null);
}

test "x86_64 elf writer emits direct call relocation metadata" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare i32 @callee()
        \\
        \\define i32 @call_no_args() {
        \\entry:
        \\  %r = call i32 @callee()
        \\  ret i32 %r
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);

    const object = try mc.elf.buildObject(std.testing.allocator, &.{machine});
    defer std.testing.allocator.free(object);

    try std.testing.expect(std.mem.indexOf(u8, object, ".rela.text") != null);
    try std.testing.expect(std.mem.indexOf(u8, object, "callee") != null);
}

test "x86_64 elf writer emits selected local function aliases" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\@public_add = alias i32 (i32, i32), ptr @internal_add
        \\
        \\define private i32 @internal_add(i32 %a, i32 %b) {
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

    const object = try mc.elf.buildObjectWithAliases(std.testing.allocator, &.{machine}, module.aliases.items);
    defer std.testing.allocator.free(object);

    try std.testing.expect(std.mem.indexOf(u8, object, "internal_add") != null);
    try std.testing.expect(std.mem.indexOf(u8, object, "public_add") != null);
}

test "x86_64 codegen rejects unsupported control flow" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @branch(i32 %a) {
        \\entry:
        \\  br label %exit
        \\exit:
        \\  ret i32 %a
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    try std.testing.expectError(
        error.UnsupportedCodegenControlFlow,
        codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]),
    );
}

test "x86_64 codegen loads first stack-passed i32 parameter" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @stack_arg(i32 %a, i32 %b, i32 %c, i32 %d, i32 %e, i32 %f, i32 %g) {
        \\entry:
        \\  ret i32 %g
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .load_stack_disp8_rax = 8 }, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[1]);
}

test "x86_64 codegen stores selected sret i64 aggregate fields" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define void @make(ptr sret({ i64, i64, i64 }) %out, i64 %a, i64 %b, i64 %c) {
        \\entry:
        \\  %field0 = getelementptr { i64, i64, i64 }, ptr %out, i64 0, i32 0
        \\  store i64 %a, ptr %field0
        \\  %field1 = getelementptr { i64, i64, i64 }, ptr %out, i64 0, i32 1
        \\  store i64 %b, ptr %field1
        \\  %field2 = getelementptr { i64, i64, i64 }, ptr %out, i64 0, i32 2
        \\  store i64 %c, ptr %field2
        \\  ret void
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_arg64_arg_ptr_disp8 = .{ .ptr_reg = .rdi, .src_reg = .rsi, .offset = 0 } }, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_arg64_arg_ptr_disp8 = .{ .ptr_reg = .rdi, .src_reg = .rdx, .offset = 8 } }, machine.instructions.items[1]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_arg64_arg_ptr_disp8 = .{ .ptr_reg = .rdi, .src_reg = .rcx, .offset = 16 } }, machine.instructions.items[2]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[3]);
}

test "x86_64 codegen stores four-field sret i64 aggregate fields" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define void @make(ptr sret({ i64, i64, i64, i64 }) %out, i64 %a, i64 %b, i64 %c, i64 %d) {
        \\entry:
        \\  %field0 = getelementptr { i64, i64, i64, i64 }, ptr %out, i64 0, i32 0
        \\  store i64 %a, ptr %field0
        \\  %field1 = getelementptr { i64, i64, i64, i64 }, ptr %out, i64 0, i32 1
        \\  store i64 %b, ptr %field1
        \\  %field2 = getelementptr { i64, i64, i64, i64 }, ptr %out, i64 0, i32 2
        \\  store i64 %c, ptr %field2
        \\  %field3 = getelementptr { i64, i64, i64, i64 }, ptr %out, i64 0, i32 3
        \\  store i64 %d, ptr %field3
        \\  ret void
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_arg64_arg_ptr_disp8 = .{ .ptr_reg = .rdi, .src_reg = .rsi, .offset = 0 } }, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_arg64_arg_ptr_disp8 = .{ .ptr_reg = .rdi, .src_reg = .rdx, .offset = 8 } }, machine.instructions.items[1]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_arg64_arg_ptr_disp8 = .{ .ptr_reg = .rdi, .src_reg = .rcx, .offset = 16 } }, machine.instructions.items[2]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_arg64_arg_ptr_disp8 = .{ .ptr_reg = .rdi, .src_reg = .r8, .offset = 24 } }, machine.instructions.items[3]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[4]);
}

test "x86_64 codegen stores five-field sret i64 aggregate fields" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define void @make(ptr sret({ i64, i64, i64, i64, i64 }) %out, i64 %a, i64 %b, i64 %c, i64 %d, i64 %e) {
        \\entry:
        \\  %field0 = getelementptr { i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 0
        \\  store i64 %a, ptr %field0
        \\  %field1 = getelementptr { i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 1
        \\  store i64 %b, ptr %field1
        \\  %field2 = getelementptr { i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 2
        \\  store i64 %c, ptr %field2
        \\  %field3 = getelementptr { i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 3
        \\  store i64 %d, ptr %field3
        \\  %field4 = getelementptr { i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 4
        \\  store i64 %e, ptr %field4
        \\  ret void
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_arg64_arg_ptr_disp8 = .{ .ptr_reg = .rdi, .src_reg = .rsi, .offset = 0 } }, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_arg64_arg_ptr_disp8 = .{ .ptr_reg = .rdi, .src_reg = .rdx, .offset = 8 } }, machine.instructions.items[1]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_arg64_arg_ptr_disp8 = .{ .ptr_reg = .rdi, .src_reg = .rcx, .offset = 16 } }, machine.instructions.items[2]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_arg64_arg_ptr_disp8 = .{ .ptr_reg = .rdi, .src_reg = .r8, .offset = 24 } }, machine.instructions.items[3]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_arg64_arg_ptr_disp8 = .{ .ptr_reg = .rdi, .src_reg = .r9, .offset = 32 } }, machine.instructions.items[4]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[5]);
}

test "x86_64 codegen stores six-field sret i64 aggregate fields with stack arg" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define void @make(ptr sret({ i64, i64, i64, i64, i64, i64 }) %out, i64 %a, i64 %b, i64 %c, i64 %d, i64 %e, i64 %f) {
        \\entry:
        \\  %field0 = getelementptr { i64, i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 0
        \\  store i64 %a, ptr %field0
        \\  %field1 = getelementptr { i64, i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 1
        \\  store i64 %b, ptr %field1
        \\  %field2 = getelementptr { i64, i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 2
        \\  store i64 %c, ptr %field2
        \\  %field3 = getelementptr { i64, i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 3
        \\  store i64 %d, ptr %field3
        \\  %field4 = getelementptr { i64, i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 4
        \\  store i64 %e, ptr %field4
        \\  %field5 = getelementptr { i64, i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 5
        \\  store i64 %f, ptr %field5
        \\  ret void
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_arg64_arg_ptr_disp8 = .{ .ptr_reg = .rdi, .src_reg = .rsi, .offset = 0 } }, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_arg64_arg_ptr_disp8 = .{ .ptr_reg = .rdi, .src_reg = .rdx, .offset = 8 } }, machine.instructions.items[1]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_arg64_arg_ptr_disp8 = .{ .ptr_reg = .rdi, .src_reg = .rcx, .offset = 16 } }, machine.instructions.items[2]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_arg64_arg_ptr_disp8 = .{ .ptr_reg = .rdi, .src_reg = .r8, .offset = 24 } }, machine.instructions.items[3]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_arg64_arg_ptr_disp8 = .{ .ptr_reg = .rdi, .src_reg = .r9, .offset = 32 } }, machine.instructions.items[4]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .load_stack_disp8_rax = 8 }, machine.instructions.items[5]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_rax_arg_ptr_disp8 = .{ .reg = .rdi, .offset = 40 } }, machine.instructions.items[6]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[7]);
}

test "x86_64 codegen stores seven-field sret i64 aggregate fields with multiple stack args" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define void @make(ptr sret({ i64, i64, i64, i64, i64, i64, i64 }) %out, i64 %a, i64 %b, i64 %c, i64 %d, i64 %e, i64 %f, i64 %g) {
        \\entry:
        \\  %field0 = getelementptr { i64, i64, i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 0
        \\  store i64 %a, ptr %field0
        \\  %field1 = getelementptr { i64, i64, i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 1
        \\  store i64 %b, ptr %field1
        \\  %field2 = getelementptr { i64, i64, i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 2
        \\  store i64 %c, ptr %field2
        \\  %field3 = getelementptr { i64, i64, i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 3
        \\  store i64 %d, ptr %field3
        \\  %field4 = getelementptr { i64, i64, i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 4
        \\  store i64 %e, ptr %field4
        \\  %field5 = getelementptr { i64, i64, i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 5
        \\  store i64 %f, ptr %field5
        \\  %field6 = getelementptr { i64, i64, i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 6
        \\  store i64 %g, ptr %field6
        \\  ret void
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_arg64_arg_ptr_disp8 = .{ .ptr_reg = .rdi, .src_reg = .rsi, .offset = 0 } }, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_arg64_arg_ptr_disp8 = .{ .ptr_reg = .rdi, .src_reg = .rdx, .offset = 8 } }, machine.instructions.items[1]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_arg64_arg_ptr_disp8 = .{ .ptr_reg = .rdi, .src_reg = .rcx, .offset = 16 } }, machine.instructions.items[2]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_arg64_arg_ptr_disp8 = .{ .ptr_reg = .rdi, .src_reg = .r8, .offset = 24 } }, machine.instructions.items[3]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_arg64_arg_ptr_disp8 = .{ .ptr_reg = .rdi, .src_reg = .r9, .offset = 32 } }, machine.instructions.items[4]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .load_stack_disp8_rax = 8 }, machine.instructions.items[5]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_rax_arg_ptr_disp8 = .{ .reg = .rdi, .offset = 40 } }, machine.instructions.items[6]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .load_stack_disp8_rax = 16 }, machine.instructions.items[7]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_rax_arg_ptr_disp8 = .{ .reg = .rdi, .offset = 48 } }, machine.instructions.items[8]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[9]);
}

test "x86_64 codegen stores eight-field sret i64 aggregate fields with multiple stack args" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define void @make(ptr sret({ i64, i64, i64, i64, i64, i64, i64, i64 }) %out, i64 %a, i64 %b, i64 %c, i64 %d, i64 %e, i64 %f, i64 %g, i64 %h) {
        \\entry:
        \\  %field0 = getelementptr { i64, i64, i64, i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 0
        \\  store i64 %a, ptr %field0
        \\  %field1 = getelementptr { i64, i64, i64, i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 1
        \\  store i64 %b, ptr %field1
        \\  %field2 = getelementptr { i64, i64, i64, i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 2
        \\  store i64 %c, ptr %field2
        \\  %field3 = getelementptr { i64, i64, i64, i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 3
        \\  store i64 %d, ptr %field3
        \\  %field4 = getelementptr { i64, i64, i64, i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 4
        \\  store i64 %e, ptr %field4
        \\  %field5 = getelementptr { i64, i64, i64, i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 5
        \\  store i64 %f, ptr %field5
        \\  %field6 = getelementptr { i64, i64, i64, i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 6
        \\  store i64 %g, ptr %field6
        \\  %field7 = getelementptr { i64, i64, i64, i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 7
        \\  store i64 %h, ptr %field7
        \\  ret void
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_arg64_arg_ptr_disp8 = .{ .ptr_reg = .rdi, .src_reg = .rsi, .offset = 0 } }, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_arg64_arg_ptr_disp8 = .{ .ptr_reg = .rdi, .src_reg = .rdx, .offset = 8 } }, machine.instructions.items[1]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_arg64_arg_ptr_disp8 = .{ .ptr_reg = .rdi, .src_reg = .rcx, .offset = 16 } }, machine.instructions.items[2]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_arg64_arg_ptr_disp8 = .{ .ptr_reg = .rdi, .src_reg = .r8, .offset = 24 } }, machine.instructions.items[3]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_arg64_arg_ptr_disp8 = .{ .ptr_reg = .rdi, .src_reg = .r9, .offset = 32 } }, machine.instructions.items[4]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .load_stack_disp8_rax = 8 }, machine.instructions.items[5]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_rax_arg_ptr_disp8 = .{ .reg = .rdi, .offset = 40 } }, machine.instructions.items[6]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .load_stack_disp8_rax = 16 }, machine.instructions.items[7]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_rax_arg_ptr_disp8 = .{ .reg = .rdi, .offset = 48 } }, machine.instructions.items[8]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .load_stack_disp8_rax = 24 }, machine.instructions.items[9]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_rax_arg_ptr_disp8 = .{ .reg = .rdi, .offset = 56 } }, machine.instructions.items[10]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[11]);
}

test "x86_64 codegen copies five-field memory aggregate from byval to sret" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define void @copy(ptr sret({ i64, i64, i64, i64, i64 }) %out, ptr byval({ i64, i64, i64, i64, i64 }) %value) {
        \\entry:
        \\  %src0 = getelementptr { i64, i64, i64, i64, i64 }, ptr %value, i64 0, i32 0
        \\  %load0 = load i64, ptr %src0
        \\  %dst0 = getelementptr { i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 0
        \\  store i64 %load0, ptr %dst0
        \\  %src1 = getelementptr { i64, i64, i64, i64, i64 }, ptr %value, i64 0, i32 1
        \\  %load1 = load i64, ptr %src1
        \\  %dst1 = getelementptr { i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 1
        \\  store i64 %load1, ptr %dst1
        \\  %src2 = getelementptr { i64, i64, i64, i64, i64 }, ptr %value, i64 0, i32 2
        \\  %load2 = load i64, ptr %src2
        \\  %dst2 = getelementptr { i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 2
        \\  store i64 %load2, ptr %dst2
        \\  %src3 = getelementptr { i64, i64, i64, i64, i64 }, ptr %value, i64 0, i32 3
        \\  %load3 = load i64, ptr %src3
        \\  %dst3 = getelementptr { i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 3
        \\  store i64 %load3, ptr %dst3
        \\  %src4 = getelementptr { i64, i64, i64, i64, i64 }, ptr %value, i64 0, i32 4
        \\  %load4 = load i64, ptr %src4
        \\  %dst4 = getelementptr { i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 4
        \\  store i64 %load4, ptr %dst4
        \\  ret void
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .load_stack_disp8_rax = 8 }, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_rax_arg_ptr_disp8 = .{ .reg = .rdi, .offset = 0 } }, machine.instructions.items[1]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .load_stack_disp8_rax = 16 }, machine.instructions.items[2]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_rax_arg_ptr_disp8 = .{ .reg = .rdi, .offset = 8 } }, machine.instructions.items[3]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .load_stack_disp8_rax = 24 }, machine.instructions.items[4]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_rax_arg_ptr_disp8 = .{ .reg = .rdi, .offset = 16 } }, machine.instructions.items[5]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .load_stack_disp8_rax = 32 }, machine.instructions.items[6]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_rax_arg_ptr_disp8 = .{ .reg = .rdi, .offset = 24 } }, machine.instructions.items[7]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .load_stack_disp8_rax = 40 }, machine.instructions.items[8]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_rax_arg_ptr_disp8 = .{ .reg = .rdi, .offset = 32 } }, machine.instructions.items[9]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[10]);
}

test "x86_64 codegen copies six-field memory aggregate from byval to sret" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define void @copy(ptr noalias sret({ i64, i64, i64, i64, i64, i64 }) %out, ptr byval({ i64, i64, i64, i64, i64, i64 }) %value) {
        \\entry:
        \\  %src0 = getelementptr { i64, i64, i64, i64, i64, i64 }, ptr %value, i64 0, i32 0
        \\  %load0 = load i64, ptr %src0
        \\  %dst0 = getelementptr { i64, i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 0
        \\  store i64 %load0, ptr %dst0
        \\  %src1 = getelementptr { i64, i64, i64, i64, i64, i64 }, ptr %value, i64 0, i32 1
        \\  %load1 = load i64, ptr %src1
        \\  %dst1 = getelementptr { i64, i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 1
        \\  store i64 %load1, ptr %dst1
        \\  %src2 = getelementptr { i64, i64, i64, i64, i64, i64 }, ptr %value, i64 0, i32 2
        \\  %load2 = load i64, ptr %src2
        \\  %dst2 = getelementptr { i64, i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 2
        \\  store i64 %load2, ptr %dst2
        \\  %src3 = getelementptr { i64, i64, i64, i64, i64, i64 }, ptr %value, i64 0, i32 3
        \\  %load3 = load i64, ptr %src3
        \\  %dst3 = getelementptr { i64, i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 3
        \\  store i64 %load3, ptr %dst3
        \\  %src4 = getelementptr { i64, i64, i64, i64, i64, i64 }, ptr %value, i64 0, i32 4
        \\  %load4 = load i64, ptr %src4
        \\  %dst4 = getelementptr { i64, i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 4
        \\  store i64 %load4, ptr %dst4
        \\  %src5 = getelementptr { i64, i64, i64, i64, i64, i64 }, ptr %value, i64 0, i32 5
        \\  %load5 = load i64, ptr %src5
        \\  %dst5 = getelementptr { i64, i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 5
        \\  store i64 %load5, ptr %dst5
        \\  ret void
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .load_stack_disp8_rax = 8 }, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_rax_arg_ptr_disp8 = .{ .reg = .rdi, .offset = 0 } }, machine.instructions.items[1]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .load_stack_disp8_rax = 16 }, machine.instructions.items[2]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_rax_arg_ptr_disp8 = .{ .reg = .rdi, .offset = 8 } }, machine.instructions.items[3]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .load_stack_disp8_rax = 24 }, machine.instructions.items[4]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_rax_arg_ptr_disp8 = .{ .reg = .rdi, .offset = 16 } }, machine.instructions.items[5]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .load_stack_disp8_rax = 32 }, machine.instructions.items[6]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_rax_arg_ptr_disp8 = .{ .reg = .rdi, .offset = 24 } }, machine.instructions.items[7]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .load_stack_disp8_rax = 40 }, machine.instructions.items[8]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_rax_arg_ptr_disp8 = .{ .reg = .rdi, .offset = 32 } }, machine.instructions.items[9]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .load_stack_disp8_rax = 48 }, machine.instructions.items[10]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_rax_arg_ptr_disp8 = .{ .reg = .rdi, .offset = 40 } }, machine.instructions.items[11]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[12]);
}

test "x86_64 codegen copies seven-field memory aggregate from byval to sret" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define void @copy(ptr noalias sret({ i64, i64, i64, i64, i64, i64, i64 }) %out, ptr byval({ i64, i64, i64, i64, i64, i64, i64 }) %value) {
        \\entry:
        \\  %src0 = getelementptr { i64, i64, i64, i64, i64, i64, i64 }, ptr %value, i64 0, i32 0
        \\  %load0 = load i64, ptr %src0
        \\  %dst0 = getelementptr { i64, i64, i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 0
        \\  store i64 %load0, ptr %dst0
        \\  %src1 = getelementptr { i64, i64, i64, i64, i64, i64, i64 }, ptr %value, i64 0, i32 1
        \\  %load1 = load i64, ptr %src1
        \\  %dst1 = getelementptr { i64, i64, i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 1
        \\  store i64 %load1, ptr %dst1
        \\  %src2 = getelementptr { i64, i64, i64, i64, i64, i64, i64 }, ptr %value, i64 0, i32 2
        \\  %load2 = load i64, ptr %src2
        \\  %dst2 = getelementptr { i64, i64, i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 2
        \\  store i64 %load2, ptr %dst2
        \\  %src3 = getelementptr { i64, i64, i64, i64, i64, i64, i64 }, ptr %value, i64 0, i32 3
        \\  %load3 = load i64, ptr %src3
        \\  %dst3 = getelementptr { i64, i64, i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 3
        \\  store i64 %load3, ptr %dst3
        \\  %src4 = getelementptr { i64, i64, i64, i64, i64, i64, i64 }, ptr %value, i64 0, i32 4
        \\  %load4 = load i64, ptr %src4
        \\  %dst4 = getelementptr { i64, i64, i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 4
        \\  store i64 %load4, ptr %dst4
        \\  %src5 = getelementptr { i64, i64, i64, i64, i64, i64, i64 }, ptr %value, i64 0, i32 5
        \\  %load5 = load i64, ptr %src5
        \\  %dst5 = getelementptr { i64, i64, i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 5
        \\  store i64 %load5, ptr %dst5
        \\  %src6 = getelementptr { i64, i64, i64, i64, i64, i64, i64 }, ptr %value, i64 0, i32 6
        \\  %load6 = load i64, ptr %src6
        \\  %dst6 = getelementptr { i64, i64, i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 6
        \\  store i64 %load6, ptr %dst6
        \\  ret void
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    var field_index: usize = 0;
    while (field_index < 7) : (field_index += 1) {
        try std.testing.expectEqual(codegen.x86_64.Instruction{ .load_stack_disp8_rax = @intCast(8 + field_index * 8) }, machine.instructions.items[field_index * 2]);
        try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_rax_arg_ptr_disp8 = .{ .reg = .rdi, .offset = @intCast(field_index * 8) } }, machine.instructions.items[field_index * 2 + 1]);
    }
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[14]);
}

test "x86_64 codegen copies eight-field memory aggregate from byval to sret" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define void @copy(ptr noalias sret({ i64, i64, i64, i64, i64, i64, i64, i64 }) %out, ptr byval({ i64, i64, i64, i64, i64, i64, i64, i64 }) %value) {
        \\entry:
        \\  %src0 = getelementptr { i64, i64, i64, i64, i64, i64, i64, i64 }, ptr %value, i64 0, i32 0
        \\  %load0 = load i64, ptr %src0
        \\  %dst0 = getelementptr { i64, i64, i64, i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 0
        \\  store i64 %load0, ptr %dst0
        \\  %src1 = getelementptr { i64, i64, i64, i64, i64, i64, i64, i64 }, ptr %value, i64 0, i32 1
        \\  %load1 = load i64, ptr %src1
        \\  %dst1 = getelementptr { i64, i64, i64, i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 1
        \\  store i64 %load1, ptr %dst1
        \\  %src2 = getelementptr { i64, i64, i64, i64, i64, i64, i64, i64 }, ptr %value, i64 0, i32 2
        \\  %load2 = load i64, ptr %src2
        \\  %dst2 = getelementptr { i64, i64, i64, i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 2
        \\  store i64 %load2, ptr %dst2
        \\  %src3 = getelementptr { i64, i64, i64, i64, i64, i64, i64, i64 }, ptr %value, i64 0, i32 3
        \\  %load3 = load i64, ptr %src3
        \\  %dst3 = getelementptr { i64, i64, i64, i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 3
        \\  store i64 %load3, ptr %dst3
        \\  %src4 = getelementptr { i64, i64, i64, i64, i64, i64, i64, i64 }, ptr %value, i64 0, i32 4
        \\  %load4 = load i64, ptr %src4
        \\  %dst4 = getelementptr { i64, i64, i64, i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 4
        \\  store i64 %load4, ptr %dst4
        \\  %src5 = getelementptr { i64, i64, i64, i64, i64, i64, i64, i64 }, ptr %value, i64 0, i32 5
        \\  %load5 = load i64, ptr %src5
        \\  %dst5 = getelementptr { i64, i64, i64, i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 5
        \\  store i64 %load5, ptr %dst5
        \\  %src6 = getelementptr { i64, i64, i64, i64, i64, i64, i64, i64 }, ptr %value, i64 0, i32 6
        \\  %load6 = load i64, ptr %src6
        \\  %dst6 = getelementptr { i64, i64, i64, i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 6
        \\  store i64 %load6, ptr %dst6
        \\  %src7 = getelementptr { i64, i64, i64, i64, i64, i64, i64, i64 }, ptr %value, i64 0, i32 7
        \\  %load7 = load i64, ptr %src7
        \\  %dst7 = getelementptr { i64, i64, i64, i64, i64, i64, i64, i64 }, ptr %out, i64 0, i32 7
        \\  store i64 %load7, ptr %dst7
        \\  ret void
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    var field_index: usize = 0;
    while (field_index < 8) : (field_index += 1) {
        try std.testing.expectEqual(codegen.x86_64.Instruction{ .load_stack_disp8_rax = @intCast(8 + field_index * 8) }, machine.instructions.items[field_index * 2]);
        try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_rax_arg_ptr_disp8 = .{ .reg = .rdi, .offset = @intCast(field_index * 8) } }, machine.instructions.items[field_index * 2 + 1]);
    }
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[16]);
}

test "x86_64 codegen copies nested memory aggregate leaves from byval to sret" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define void @copy(ptr noalias sret({ { i64, i64, i64 }, { i64, i64, i64 } }) %out, ptr byval({ { i64, i64, i64 }, { i64, i64, i64 } }) %value) {
        \\entry:
        \\  %src0 = getelementptr i8, ptr %value, i64 0
        \\  %load0 = load i64, ptr %src0
        \\  %dst0 = getelementptr i8, ptr %out, i64 0
        \\  store i64 %load0, ptr %dst0
        \\  %src1 = getelementptr i8, ptr %value, i64 8
        \\  %load1 = load i64, ptr %src1
        \\  %dst1 = getelementptr i8, ptr %out, i64 8
        \\  store i64 %load1, ptr %dst1
        \\  %src2 = getelementptr i8, ptr %value, i64 16
        \\  %load2 = load i64, ptr %src2
        \\  %dst2 = getelementptr i8, ptr %out, i64 16
        \\  store i64 %load2, ptr %dst2
        \\  %src3 = getelementptr i8, ptr %value, i64 24
        \\  %load3 = load i64, ptr %src3
        \\  %dst3 = getelementptr i8, ptr %out, i64 24
        \\  store i64 %load3, ptr %dst3
        \\  %src4 = getelementptr i8, ptr %value, i64 32
        \\  %load4 = load i64, ptr %src4
        \\  %dst4 = getelementptr i8, ptr %out, i64 32
        \\  store i64 %load4, ptr %dst4
        \\  %src5 = getelementptr i8, ptr %value, i64 40
        \\  %load5 = load i64, ptr %src5
        \\  %dst5 = getelementptr i8, ptr %out, i64 40
        \\  store i64 %load5, ptr %dst5
        \\  ret void
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    var field_index: usize = 0;
    while (field_index < 6) : (field_index += 1) {
        try std.testing.expectEqual(codegen.x86_64.Instruction{ .load_stack_disp8_rax = @intCast(8 + field_index * 8) }, machine.instructions.items[field_index * 2]);
        try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_rax_arg_ptr_disp8 = .{ .reg = .rdi, .offset = @intCast(field_index * 8) } }, machine.instructions.items[field_index * 2 + 1]);
    }
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[12]);
}

test "x86_64 codegen reads selected memory aggregate by-value fields" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i64 @edges({ i64, i64, i64 } %value) {
        \\entry:
        \\  %slot = alloca { i64, i64, i64 }
        \\  store { i64, i64, i64 } %value, ptr %slot
        \\  %field0 = getelementptr { i64, i64, i64 }, ptr %slot, i64 0, i32 0
        \\  %a = load i64, ptr %field0
        \\  %field2 = getelementptr { i64, i64, i64 }, ptr %slot, i64 0, i32 2
        \\  %c = load i64, ptr %field2
        \\  %sum = add i64 %a, %c
        \\  ret i64 %sum
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .load_stack_disp8_rax = 8 }, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .add_stack_disp8_rax = 24 }, machine.instructions.items[1]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[2]);
}

test "x86_64 codegen reads four-field memory aggregate by-value fields" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i64 @edges({ i64, i64, i64, i64 } %value) {
        \\entry:
        \\  %slot = alloca { i64, i64, i64, i64 }
        \\  store { i64, i64, i64, i64 } %value, ptr %slot
        \\  %field0 = getelementptr { i64, i64, i64, i64 }, ptr %slot, i64 0, i32 0
        \\  %a = load i64, ptr %field0
        \\  %field3 = getelementptr { i64, i64, i64, i64 }, ptr %slot, i64 0, i32 3
        \\  %d = load i64, ptr %field3
        \\  %sum = add i64 %a, %d
        \\  ret i64 %sum
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .load_stack_disp8_rax = 8 }, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .add_stack_disp8_rax = 32 }, machine.instructions.items[1]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[2]);
}

test "x86_64 codegen reads five-field memory aggregate by-value fields" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i64 @edges({ i64, i64, i64, i64, i64 } %value) {
        \\entry:
        \\  %slot = alloca { i64, i64, i64, i64, i64 }
        \\  store { i64, i64, i64, i64, i64 } %value, ptr %slot
        \\  %field1 = getelementptr { i64, i64, i64, i64, i64 }, ptr %slot, i64 0, i32 1
        \\  %b = load i64, ptr %field1
        \\  %field4 = getelementptr { i64, i64, i64, i64, i64 }, ptr %slot, i64 0, i32 4
        \\  %e = load i64, ptr %field4
        \\  %sum = add i64 %b, %e
        \\  ret i64 %sum
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .load_stack_disp8_rax = 16 }, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .add_stack_disp8_rax = 40 }, machine.instructions.items[1]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[2]);
}

test "x86_64 codegen reads sixteen-field memory aggregate by-value fields with disp32" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i64 @inner({ i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64 } %value) {
        \\entry:
        \\  %slot = alloca { i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64 }
        \\  store { i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64 } %value, ptr %slot
        \\  %field3 = getelementptr { i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64 }, ptr %slot, i64 0, i32 3
        \\  %d = load i64, ptr %field3
        \\  %field10 = getelementptr { i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64 }, ptr %slot, i64 0, i32 10
        \\  %k = load i64, ptr %field10
        \\  %sum = add i64 %d, %k
        \\  %field15 = getelementptr { i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64 }, ptr %slot, i64 0, i32 15
        \\  %p = load i64, ptr %field15
        \\  %total = add i64 %sum, %p
        \\  ret i64 %total
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .load_stack_disp8_rax = 32 }, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .add_stack_disp8_rax = 88 }, machine.instructions.items[1]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .add_stack_disp32_rax = 128 }, machine.instructions.items[2]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[3]);
}

test "x86_64 codegen reads nested memory aggregate by-value fields" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i64 @sum({ { i64, i64, i64 }, { i64, i64, i64 } } %value) {
        \\entry:
        \\  %slot = alloca { { i64, i64, i64 }, { i64, i64, i64 } }
        \\  store { { i64, i64, i64 }, { i64, i64, i64 } } %value, ptr %slot
        \\  %left_b_ptr = getelementptr i8, ptr %slot, i64 8
        \\  %left_b = load i64, ptr %left_b_ptr
        \\  %right_ptr = getelementptr i8, ptr %slot, i64 24
        \\  %right_c_ptr = getelementptr i8, ptr %right_ptr, i64 16
        \\  %right_c = load i64, ptr %right_c_ptr
        \\  %sum = add i64 %left_b, %right_c
        \\  ret i64 %sum
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .load_stack_disp8_rax = 16 }, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .add_stack_disp8_rax = 48 }, machine.instructions.items[1]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[2]);
}

test "x86_64 codegen sums nested INTEGER aggregate fields from SysV GPR pair" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @nested_sum({ { i32, i32 }, { i32, i32 } } %value) {
        \\entry:
        \\  %slot = alloca { { i32, i32 }, { i32, i32 } }
        \\  store { { i32, i32 }, { i32, i32 } } %value, ptr %slot
        \\  %a = load i32, ptr %slot
        \\  %b_ptr = getelementptr i8, ptr %slot, i64 4
        \\  %b = load i32, ptr %b_ptr
        \\  %ab = add i32 %a, %b
        \\  %c_ptr = getelementptr i8, ptr %slot, i64 8
        \\  %c = load i32, ptr %c_ptr
        \\  %abc = add i32 %ab, %c
        \\  %right_ptr = getelementptr i8, ptr %slot, i64 8
        \\  %d_ptr = getelementptr i8, ptr %right_ptr, i64 4
        \\  %d = load i32, ptr %d_ptr
        \\  %sum = add i32 %abc, %d
        \\  ret i32 %sum
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .mov_arg_eax = .rdi }, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .add_arg_high32_eax = .rdi }, machine.instructions.items[1]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .binary_arg_eax = .{ .op = .add, .reg = .rsi } }, machine.instructions.items[2]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .add_arg_high32_eax = .rsi }, machine.instructions.items[3]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[4]);
}

test "x86_64 codegen sums array-in-struct INTEGER aggregate fields from SysV GPR pair" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i64 @array_sum({ [2 x i64] } %value) {
        \\entry:
        \\  %slot = alloca { [2 x i64] }
        \\  store { [2 x i64] } %value, ptr %slot
        \\  %a_ptr = getelementptr i64, ptr %slot, i64 0
        \\  %a = load i64, ptr %a_ptr
        \\  %b_ptr = getelementptr i64, ptr %slot, i64 1
        \\  %b = load i64, ptr %b_ptr
        \\  %sum = add i64 %a, %b
        \\  ret i64 %sum
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .mov_arg_rax = .rdi }, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .add_arg64_rax = .rsi }, machine.instructions.items[1]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[2]);
}

test "x86_64 codegen sums f32 fields from single-eightbyte SSE aggregate" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define float @sum({ float, float } %value) {
        \\entry:
        \\  %slot = alloca { float, float }
        \\  store { float, float } %value, ptr %slot
        \\  %a = load float, ptr %slot
        \\  %b_ptr = getelementptr i8, ptr %slot, i64 4
        \\  %b = load float, ptr %b_ptr
        \\  %sum = fadd float %a, %b
        \\  ret float %sum
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .movapd_xmm = .{ .dst = .xmm1, .src = .xmm0 } }, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .shufps_high_f32_to_low = .xmm1 }, machine.instructions.items[1]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.addss_xmm1_xmm0, machine.instructions.items[2]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[3]);
}

test "x86_64 codegen lowers mixed integer to FP arithmetic pipelines" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define float @f32_add(i32 %value, float %addend) {
        \\entry:
        \\  %cast = sitofp i32 %value to float
        \\  %sum = fadd float %cast, %addend
        \\  ret float %sum
        \\}
        \\
        \\define float @f32_mul_add(i32 %value, float %scale, float %addend) {
        \\entry:
        \\  %cast = sitofp i32 %value to float
        \\  %product = fmul float %cast, %scale
        \\  %sum = fadd float %product, %addend
        \\  ret float %sum
        \\}
        \\
        \\define double @f64_mul_add(i32 %value, double %scale, double %addend) {
        \\entry:
        \\  %cast = sitofp i32 %value to double
        \\  %product = fmul double %cast, %scale
        \\  %sum = fadd double %product, %addend
        \\  ret double %sum
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var f32_machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer f32_machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, f32_machine.codegen_path);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .movapd_xmm = .{ .dst = .xmm1, .src = .xmm0 } }, f32_machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.cvtsi2ss_edi_xmm0, f32_machine.instructions.items[1]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.addss_xmm1_xmm0, f32_machine.instructions.items[2]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, f32_machine.instructions.items[3]);

    var f32_mul_machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[1]);
    defer f32_mul_machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, f32_mul_machine.codegen_path);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .movapd_xmm = .{ .dst = .xmm2, .src = .xmm1 } }, f32_mul_machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .movapd_xmm = .{ .dst = .xmm1, .src = .xmm0 } }, f32_mul_machine.instructions.items[1]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.cvtsi2ss_edi_xmm0, f32_mul_machine.instructions.items[2]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.mulss_xmm1_xmm0, f32_mul_machine.instructions.items[3]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .movapd_xmm = .{ .dst = .xmm1, .src = .xmm2 } }, f32_mul_machine.instructions.items[4]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.addss_xmm1_xmm0, f32_mul_machine.instructions.items[5]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, f32_mul_machine.instructions.items[6]);

    var f64_machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[2]);
    defer f64_machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, f64_machine.codegen_path);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .movapd_xmm = .{ .dst = .xmm2, .src = .xmm1 } }, f64_machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .movapd_xmm = .{ .dst = .xmm1, .src = .xmm0 } }, f64_machine.instructions.items[1]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.cvtsi2sd_edi_xmm0, f64_machine.instructions.items[2]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.mulsd_xmm1_xmm0, f64_machine.instructions.items[3]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .movapd_xmm = .{ .dst = .xmm1, .src = .xmm2 } }, f64_machine.instructions.items[4]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.addsd_xmm1_xmm0, f64_machine.instructions.items[5]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, f64_machine.instructions.items[6]);
}

test "x86_64 codegen returns i32 fields from mixed SysV aggregate classes" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @small_mixed_int({ i32, double } %value) {
        \\entry:
        \\  %slot = alloca { i32, double }
        \\  store { i32, double } %value, ptr %slot
        \\  %a_ptr = getelementptr { i32, double }, ptr %slot, i64 0, i32 0
        \\  %a = load i32, ptr %a_ptr
        \\  ret i32 %a
        \\}
        \\
        \\define i32 @small_reverse_mixed_int({ double, i32 } %value) {
        \\entry:
        \\  %slot = alloca { double, i32 }
        \\  store { double, i32 } %value, ptr %slot
        \\  %b_ptr = getelementptr { double, i32 }, ptr %slot, i64 0, i32 1
        \\  %b = load i32, ptr %b_ptr
        \\  ret i32 %b
        \\}
        \\
        \\define i32 @packed_mixed_high_int({ i32, i32, double } %value) {
        \\entry:
        \\  %slot = alloca { i32, i32, double }
        \\  store { i32, i32, double } %value, ptr %slot
        \\  %b_ptr = getelementptr { i32, i32, double }, ptr %slot, i64 0, i32 1
        \\  %b = load i32, ptr %b_ptr
        \\  ret i32 %b
        \\}
        \\
        \\define i32 @packed_reverse_mixed_high_int({ double, i32, i32 } %value) {
        \\entry:
        \\  %slot = alloca { double, i32, i32 }
        \\  store { double, i32, i32 } %value, ptr %slot
        \\  %c_ptr = getelementptr { double, i32, i32 }, ptr %slot, i64 0, i32 2
        \\  %c = load i32, ptr %c_ptr
        \\  ret i32 %c
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var small_mixed = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer small_mixed.deinit(std.testing.allocator);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, small_mixed.codegen_path);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .mov_arg_eax = .rdi }, small_mixed.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, small_mixed.instructions.items[1]);

    var small_reverse = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[1]);
    defer small_reverse.deinit(std.testing.allocator);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, small_reverse.codegen_path);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .mov_arg_eax = .rdi }, small_reverse.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, small_reverse.instructions.items[1]);

    var packed_mixed = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[2]);
    defer packed_mixed.deinit(std.testing.allocator);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, packed_mixed.codegen_path);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .mov_arg_rax = .rdi }, packed_mixed.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .shr_rax_imm6 = 32 }, packed_mixed.instructions.items[1]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, packed_mixed.instructions.items[2]);

    var packed_reverse = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[3]);
    defer packed_reverse.deinit(std.testing.allocator);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, packed_reverse.codegen_path);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .mov_arg_rax = .rdi }, packed_reverse.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .shr_rax_imm6 = 32 }, packed_reverse.instructions.items[1]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, packed_reverse.instructions.items[2]);
}

test "x86_64 codegen copies mixed-width memory aggregate leaves from byval to sret" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define void @copy(ptr noalias sret({ i64, i32, i64, i32 }) %out, ptr byval({ i64, i32, i64, i32 }) %value) {
        \\entry:
        \\  %src0 = getelementptr i8, ptr %value, i64 0
        \\  %load0 = load i64, ptr %src0
        \\  %dst0 = getelementptr i8, ptr %out, i64 0
        \\  store i64 %load0, ptr %dst0
        \\  %src1 = getelementptr i8, ptr %value, i64 8
        \\  %load1 = load i32, ptr %src1
        \\  %dst1 = getelementptr i8, ptr %out, i64 8
        \\  store i32 %load1, ptr %dst1
        \\  %src2 = getelementptr i8, ptr %value, i64 16
        \\  %load2 = load i64, ptr %src2
        \\  %dst2 = getelementptr i8, ptr %out, i64 16
        \\  store i64 %load2, ptr %dst2
        \\  %src3 = getelementptr i8, ptr %value, i64 24
        \\  %load3 = load i32, ptr %src3
        \\  %dst3 = getelementptr i8, ptr %out, i64 24
        \\  store i32 %load3, ptr %dst3
        \\  ret void
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .load_stack_disp8_rax = 8 }, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_rax_arg_ptr_disp8 = .{ .reg = .rdi, .offset = 0 } }, machine.instructions.items[1]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .load_stack_disp8_rax = 16 }, machine.instructions.items[2]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_eax_arg_ptr_disp8 = .{ .reg = .rdi, .offset = 8 } }, machine.instructions.items[3]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .load_stack_disp8_rax = 24 }, machine.instructions.items[4]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_rax_arg_ptr_disp8 = .{ .reg = .rdi, .offset = 16 } }, machine.instructions.items[5]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .load_stack_disp8_rax = 32 }, machine.instructions.items[6]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_eax_arg_ptr_disp8 = .{ .reg = .rdi, .offset = 24 } }, machine.instructions.items[7]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[8]);
}

test "x86_64 codegen copies pointer and double memory aggregate leaves from byval to sret" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define void @copy(ptr noalias sret({ ptr, double, i64 }) %out, ptr byval({ ptr, double, i64 }) %value) {
        \\entry:
        \\  %src0 = getelementptr i8, ptr %value, i64 0
        \\  %load0 = load ptr, ptr %src0
        \\  %dst0 = getelementptr i8, ptr %out, i64 0
        \\  store ptr %load0, ptr %dst0
        \\  %src1 = getelementptr i8, ptr %value, i64 8
        \\  %load1 = load double, ptr %src1
        \\  %dst1 = getelementptr i8, ptr %out, i64 8
        \\  store double %load1, ptr %dst1
        \\  %src2 = getelementptr i8, ptr %value, i64 16
        \\  %load2 = load i64, ptr %src2
        \\  %dst2 = getelementptr i8, ptr %out, i64 16
        \\  store i64 %load2, ptr %dst2
        \\  ret void
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .load_stack_disp8_rax = 8 }, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_rax_arg_ptr_disp8 = .{ .reg = .rdi, .offset = 0 } }, machine.instructions.items[1]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .load_stack_disp8_xmm0 = 16 }, machine.instructions.items[2]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_xmm0_arg_ptr_disp8 = .{ .reg = .rdi, .offset = 8 } }, machine.instructions.items[3]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .load_stack_disp8_rax = 24 }, machine.instructions.items[4]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_rax_arg_ptr_disp8 = .{ .reg = .rdi, .offset = 16 } }, machine.instructions.items[5]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[6]);
}

test "x86_64 codegen copies f32 memory aggregate leaves from byval to sret" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define void @copy(ptr noalias sret({ float, float, float, float, float }) %out, ptr byval({ float, float, float, float, float }) %value) {
        \\entry:
        \\  %src0 = getelementptr i8, ptr %value, i64 0
        \\  %load0 = load float, ptr %src0
        \\  %dst0 = getelementptr i8, ptr %out, i64 0
        \\  store float %load0, ptr %dst0
        \\  %src1 = getelementptr i8, ptr %value, i64 4
        \\  %load1 = load float, ptr %src1
        \\  %dst1 = getelementptr i8, ptr %out, i64 4
        \\  store float %load1, ptr %dst1
        \\  %src2 = getelementptr i8, ptr %value, i64 8
        \\  %load2 = load float, ptr %src2
        \\  %dst2 = getelementptr i8, ptr %out, i64 8
        \\  store float %load2, ptr %dst2
        \\  %src3 = getelementptr i8, ptr %value, i64 12
        \\  %load3 = load float, ptr %src3
        \\  %dst3 = getelementptr i8, ptr %out, i64 12
        \\  store float %load3, ptr %dst3
        \\  %src4 = getelementptr i8, ptr %value, i64 16
        \\  %load4 = load float, ptr %src4
        \\  %dst4 = getelementptr i8, ptr %out, i64 16
        \\  store float %load4, ptr %dst4
        \\  ret void
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    var field_index: usize = 0;
    while (field_index < 5) : (field_index += 1) {
        try std.testing.expectEqual(codegen.x86_64.Instruction{ .load_stack_disp8_xmm0_f32 = @intCast(8 + field_index * 4) }, machine.instructions.items[field_index * 2]);
        try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_xmm0_f32_arg_ptr_disp8 = .{ .reg = .rdi, .offset = @intCast(field_index * 4) } }, machine.instructions.items[field_index * 2 + 1]);
    }
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[10]);
}

test "x86_64 codegen returns register aggregate from direct helper call" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare fastcc { i64, double } @callee(i64, double)
        \\
        \\define { i64, double } @caller(i64 %a, double %b) {
        \\entry:
        \\  %r = call fastcc { i64, double } @callee(i64 %a, double %b)
        \\  ret { i64, double } %r
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try std.testing.expectEqual(codegen.x86_64.Instruction.sub_rsp_8, machine.instructions.items[0]);
    switch (machine.instructions.items[1]) {
        .direct_call => |call| {
            try std.testing.expectEqualStrings("callee", call.symbol);
            try std.testing.expect(call.ret_ty.eql(.{ .aggregate = "{ i64, double }" }));
        },
        else => return error.ExpectedDirectCall,
    }
    try std.testing.expectEqual(codegen.x86_64.Instruction.add_rsp_8, machine.instructions.items[2]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[3]);
}

test "x86_64 codegen passes register aggregate argument through direct helper call" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare fastcc i32 @sum({ { i32, i32 }, { i32, i32 } })
        \\
        \\define i32 @caller({ { i32, i32 }, { i32, i32 } } %value) {
        \\entry:
        \\  %r = call fastcc i32 @sum({ { i32, i32 }, { i32, i32 } } %value)
        \\  ret i32 %r
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try std.testing.expectEqual(codegen.x86_64.Instruction.sub_rsp_8, machine.instructions.items[0]);
    switch (machine.instructions.items[1]) {
        .direct_call => |call| {
            try std.testing.expectEqualStrings("sum", call.symbol);
            try std.testing.expect(call.ret_ty.eql(.{ .int = 32 }));
        },
        else => return error.ExpectedDirectCall,
    }
    try std.testing.expectEqual(codegen.x86_64.Instruction.add_rsp_8, machine.instructions.items[2]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[3]);
}

test "x86_64 codegen rejects unsupported call ABI shapes" {
    const unsupported_cc_input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare coldcc i32 @callee()
        \\
        \\define i32 @caller() {
        \\entry:
        \\  %r = call coldcc i32 @callee()
        \\  ret i32 %r
        \\}
        \\
    ;
    var unsupported_cc_module = try ir.Module.parse(std.testing.allocator, unsupported_cc_input);
    defer unsupported_cc_module.deinit();
    try unsupported_cc_module.verify();
    try std.testing.expectError(
        error.UnsupportedCodegenCallingConvention,
        codegen.x86_64.lowerFunction(std.testing.allocator, unsupported_cc_module.target_triple.?, unsupported_cc_module.functions.items[0]),
    );

    const tail_call_input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare i32 @callee(i32)
        \\
        \\define i32 @caller(i32 %a) {
        \\entry:
        \\  %r = tail call i32 @callee(i32 %a)
        \\  ret i32 %r
        \\}
        \\
    ;
    var tail_call_module = try ir.Module.parse(std.testing.allocator, tail_call_input);
    defer tail_call_module.deinit();
    try tail_call_module.verify();
    try std.testing.expectError(
        error.UnsupportedCodegenAbi,
        codegen.x86_64.lowerFunction(std.testing.allocator, tail_call_module.target_triple.?, tail_call_module.functions.items[0]),
    );
}

test "x86_64 codegen supports one stack-passed i32 call argument" {
    const stack_arg_input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare i32 @callee(i32, i32, i32, i32, i32, i32, i32)
        \\
        \\define i32 @caller() {
        \\entry:
        \\  %r = call i32 @callee(i32 1, i32 2, i32 3, i32 4, i32 5, i32 6, i32 7)
        \\  ret i32 %r
        \\}
        \\
    ;
    var stack_arg_module = try ir.Module.parse(std.testing.allocator, stack_arg_input);
    defer stack_arg_module.deinit();
    try stack_arg_module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, stack_arg_module.target_triple.?, stack_arg_module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .push_imm32 = 7 }, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .mov_imm_r8 = 5 }, machine.instructions.items[5]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .mov_imm_r9 = 6 }, machine.instructions.items[6]);
}

test "x86_64 codegen supports multiple stack-passed i32 call arguments" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare i32 @callee(i32, i32, i32, i32, i32, i32, i32, i32, i32)
        \\
        \\define i32 @caller() {
        \\entry:
        \\  %r = call i32 @callee(i32 1, i32 2, i32 3, i32 4, i32 5, i32 6, i32 7, i32 8, i32 9)
        \\  ret i32 %r
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .push_imm32 = 9 }, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .push_imm32 = 8 }, machine.instructions.items[1]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .push_imm32 = 7 }, machine.instructions.items[2]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.add_rsp_24, machine.instructions.items[machine.instructions.items.len - 2]);
}

test "x86_64 codegen supports six stack-passed i32 call arguments" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare i32 @callee(i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32)
        \\
        \\define i32 @caller() {
        \\entry:
        \\  %r = call i32 @callee(i32 1, i32 2, i32 3, i32 4, i32 5, i32 6, i32 7, i32 8, i32 9, i32 10, i32 11, i32 12)
        \\  ret i32 %r
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try std.testing.expectEqual(codegen.x86_64.Instruction.sub_rsp_8, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .push_imm32 = 12 }, machine.instructions.items[1]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .push_imm32 = 11 }, machine.instructions.items[2]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .push_imm32 = 10 }, machine.instructions.items[3]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .push_imm32 = 9 }, machine.instructions.items[4]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .push_imm32 = 8 }, machine.instructions.items[5]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .push_imm32 = 7 }, machine.instructions.items[6]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.add_rsp_56, machine.instructions.items[machine.instructions.items.len - 2]);
}

test "x86_64 codegen supports eight stack-passed i32 call arguments" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare i32 @callee(i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32)
        \\
        \\define i32 @caller() {
        \\entry:
        \\  %r = call i32 @callee(i32 1, i32 2, i32 3, i32 4, i32 5, i32 6, i32 7, i32 8, i32 9, i32 10, i32 11, i32 12, i32 13, i32 14)
        \\  ret i32 %r
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try std.testing.expectEqual(codegen.x86_64.Instruction.sub_rsp_8, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .push_imm32 = 14 }, machine.instructions.items[1]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .add_rsp_imm8 = 72 }, machine.instructions.items[machine.instructions.items.len - 2]);
}

test "x86_64 codegen supports twelve stack-passed i32 call arguments" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare i32 @callee(i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32)
        \\
        \\define i32 @caller() {
        \\entry:
        \\  %r = call i32 @callee(i32 1, i32 2, i32 3, i32 4, i32 5, i32 6, i32 7, i32 8, i32 9, i32 10, i32 11, i32 12, i32 13, i32 14, i32 15, i32 16, i32 17, i32 18)
        \\  ret i32 %r
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try std.testing.expectEqual(codegen.x86_64.Instruction.sub_rsp_8, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .push_imm32 = 18 }, machine.instructions.items[1]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .add_rsp_imm8 = 104 }, machine.instructions.items[machine.instructions.items.len - 2]);
}

test "x86_64 codegen forwards stack-passed i32 call arguments" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare i32 @callee(i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32)
        \\
        \\define i32 @caller(i32 %a, i32 %b, i32 %c, i32 %d, i32 %e, i32 %f, i32 %g, i32 %h, i32 %i, i32 %j, i32 %k, i32 %l) {
        \\entry:
        \\  %r = call i32 @callee(i32 %a, i32 %b, i32 %c, i32 %d, i32 %e, i32 %f, i32 %g, i32 %h, i32 %i, i32 %j, i32 %k, i32 %l)
        \\  ret i32 %r
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try std.testing.expectEqual(codegen.x86_64.Instruction.sub_rsp_8, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .push_stack_disp8 = 56 }, machine.instructions.items[1]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .push_stack_disp8 = 56 }, machine.instructions.items[2]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .push_stack_disp8 = 56 }, machine.instructions.items[3]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .push_stack_disp8 = 56 }, machine.instructions.items[4]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .push_stack_disp8 = 56 }, machine.instructions.items[5]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .push_stack_disp8 = 56 }, machine.instructions.items[6]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.add_rsp_56, machine.instructions.items[machine.instructions.items.len - 2]);
}

test "x86_64 codegen forwards stack-passed i32 params into call registers" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare i32 @callee(i32, i32, i32, i32, i32, i32)
        \\
        \\define i32 @caller(i32 %a, i32 %b, i32 %c, i32 %d, i32 %e, i32 %f, i32 %g, i32 %h, i32 %i, i32 %j, i32 %k, i32 %l) {
        \\entry:
        \\  %r = call i32 @callee(i32 %g, i32 %h, i32 %i, i32 %j, i32 %k, i32 %l)
        \\  ret i32 %r
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .load_stack_disp8_arg32 = .{ .reg = .rdi, .disp = 8 } }, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .load_stack_disp8_arg32 = .{ .reg = .rsi, .disp = 16 } }, machine.instructions.items[1]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .load_stack_disp8_arg32 = .{ .reg = .rdx, .disp = 24 } }, machine.instructions.items[2]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .load_stack_disp8_arg32 = .{ .reg = .rcx, .disp = 32 } }, machine.instructions.items[3]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .load_stack_disp8_arg32 = .{ .reg = .r8, .disp = 40 } }, machine.instructions.items[4]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .load_stack_disp8_arg32 = .{ .reg = .r9, .disp = 48 } }, machine.instructions.items[5]);
}

test "x86_64 codegen aligns calls with two stack-passed arguments" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare i32 @callee(i32, i32, i32, i32, i32, i32, i32, i32)
        \\
        \\define i32 @caller() {
        \\entry:
        \\  %r = call i32 @callee(i32 1, i32 2, i32 3, i32 4, i32 5, i32 6, i32 7, i32 8)
        \\  ret i32 %r
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try std.testing.expectEqual(codegen.x86_64.Instruction.sub_rsp_8, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .push_imm32 = 8 }, machine.instructions.items[1]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .push_imm32 = 7 }, machine.instructions.items[2]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.add_rsp_24, machine.instructions.items[machine.instructions.items.len - 2]);
}

test "x86_64 codegen supports direct f64 call return with SSE args" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare fastcc double @callee(double, double)
        \\
        \\define double @caller() {
        \\entry:
        \\  %r = call fastcc double @callee(double 6.000000e+00, double 2.000000e+00)
        \\  ret double %r
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .mov_imm64_xmm = .{ .reg = .xmm0, .bits = 0x4018_0000_0000_0000 } }, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .mov_imm64_xmm = .{ .reg = .xmm1, .bits = 0x4000_0000_0000_0000 } }, machine.instructions.items[1]);
}

test "x86_64 codegen preserves live f64 parameter across direct call" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare void @touch(double)
        \\
        \\define double @caller(double %a, double %b) {
        \\entry:
        \\  call void @touch(double %b)
        \\  ret double %a
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try std.testing.expectEqual(codegen.x86_64.Instruction.sub_rsp_8, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .spill_xmm64_rsp = .{ .reg = .xmm0, .frame_index = .slot0 } }, machine.instructions.items[1]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .movapd_xmm = .{ .dst = .xmm0, .src = .xmm1 } }, machine.instructions.items[2]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .reload_xmm64_rsp = .{ .reg = .xmm0, .frame_index = .slot0 } }, machine.instructions.items[4]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.add_rsp_8, machine.instructions.items[5]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[6]);
}

test "x86_64 codegen preserves live f32 parameter across direct call" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare void @touch(float)
        \\
        \\define float @caller(float %a, float %b) {
        \\entry:
        \\  call void @touch(float %b)
        \\  ret float %a
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try std.testing.expectEqual(codegen.x86_64.Instruction.sub_rsp_8, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .spill_xmm32_rsp = .{ .reg = .xmm0, .frame_index = .slot0 } }, machine.instructions.items[1]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .movapd_xmm = .{ .dst = .xmm0, .src = .xmm1 } }, machine.instructions.items[2]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .reload_xmm32_rsp = .{ .reg = .xmm0, .frame_index = .slot0 } }, machine.instructions.items[4]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.add_rsp_8, machine.instructions.items[5]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[6]);
}

test "x86_64 codegen preserves two live f32 params across direct call" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare void @touch()
        \\
        \\define float @caller(float %a, float %b) {
        \\entry:
        \\  call void @touch()
        \\  %sum = fadd float %a, %b
        \\  ret float %sum
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try expectMachineInstruction(machine.instructions.items, .sub_rsp_8);
    try expectMachineInstruction(machine.instructions.items, .{ .spill_xmm32_rsp = .{ .reg = .xmm0, .frame_index = .slot0 } });
    try expectMachineInstruction(machine.instructions.items, .{ .spill_xmm32_rsp = .{ .reg = .xmm1, .frame_index = .slot1 } });
    var saw_touch_call = false;
    for (machine.instructions.items) |instruction| switch (instruction) {
        .direct_call => |call| {
            if (std.mem.eql(u8, call.symbol, "touch") and call.ret_ty == .void) saw_touch_call = true;
        },
        else => {},
    };
    try std.testing.expect(saw_touch_call);
    try expectMachineInstruction(machine.instructions.items, .{ .reload_xmm32_rsp = .{ .reg = .xmm0, .frame_index = .slot0 } });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_xmm32_rsp = .{ .reg = .xmm1, .frame_index = .slot1 } });
    try expectMachineInstruction(machine.instructions.items, .addss_xmm1_xmm0);
    try expectMachineInstruction(machine.instructions.items, .add_rsp_8);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[machine.instructions.items.len - 1]);
}

test "x86_64 codegen preserves two live f64 params across direct call" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare void @touch()
        \\
        \\define double @caller(double %a, double %b) {
        \\entry:
        \\  call void @touch()
        \\  %sum = fadd double %a, %b
        \\  ret double %sum
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try expectMachineInstruction(machine.instructions.items, .sub_rsp_24);
    try expectMachineInstruction(machine.instructions.items, .{ .spill_xmm64_rsp = .{ .reg = .xmm0, .frame_index = .slot0 } });
    try expectMachineInstruction(machine.instructions.items, .{ .spill_xmm64_rsp = .{ .reg = .xmm1, .frame_index = .slot2 } });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_xmm64_rsp = .{ .reg = .xmm0, .frame_index = .slot0 } });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_xmm64_rsp = .{ .reg = .xmm1, .frame_index = .slot2 } });
    try expectMachineInstruction(machine.instructions.items, .addsd_xmm1_xmm0);
    try expectMachineInstruction(machine.instructions.items, .add_rsp_24);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[machine.instructions.items.len - 1]);
}

test "x86_64 codegen preserves two live f32 params across indirect call" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define float @caller(ptr %fn, float %a, float %b) {
        \\entry:
        \\  call void %fn()
        \\  %sum = fadd float %a, %b
        \\  ret float %sum
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try expectMachineInstruction(machine.instructions.items, .sub_rsp_8);
    try expectMachineInstruction(machine.instructions.items, .{ .spill_xmm32_rsp = .{ .reg = .xmm0, .frame_index = .slot0 } });
    try expectMachineInstruction(machine.instructions.items, .{ .spill_xmm32_rsp = .{ .reg = .xmm1, .frame_index = .slot1 } });
    try expectMachineInstruction(machine.instructions.items, .{ .mov_arg_rax = .rdi });
    try expectMachineInstruction(machine.instructions.items, .{ .indirect_call_rax = .void });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_xmm32_rsp = .{ .reg = .xmm0, .frame_index = .slot0 } });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_xmm32_rsp = .{ .reg = .xmm1, .frame_index = .slot1 } });
    try expectMachineInstruction(machine.instructions.items, .addss_xmm1_xmm0);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[machine.instructions.items.len - 1]);
}

test "x86_64 codegen preserves two live f64 params across indirect call" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define double @caller(ptr %fn, double %a, double %b) {
        \\entry:
        \\  call void %fn()
        \\  %sum = fadd double %a, %b
        \\  ret double %sum
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try expectMachineInstruction(machine.instructions.items, .sub_rsp_24);
    try expectMachineInstruction(machine.instructions.items, .{ .spill_xmm64_rsp = .{ .reg = .xmm0, .frame_index = .slot0 } });
    try expectMachineInstruction(machine.instructions.items, .{ .spill_xmm64_rsp = .{ .reg = .xmm1, .frame_index = .slot2 } });
    try expectMachineInstruction(machine.instructions.items, .{ .mov_arg_rax = .rdi });
    try expectMachineInstruction(machine.instructions.items, .{ .indirect_call_rax = .void });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_xmm64_rsp = .{ .reg = .xmm0, .frame_index = .slot0 } });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_xmm64_rsp = .{ .reg = .xmm1, .frame_index = .slot2 } });
    try expectMachineInstruction(machine.instructions.items, .addsd_xmm1_xmm0);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[machine.instructions.items.len - 1]);
}

test "x86_64 codegen preserves two live f32 params across FP argument call" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare void @touch(float)
        \\
        \\define float @caller(float %a, float %b) {
        \\entry:
        \\  call void @touch(float %b)
        \\  %sum = fadd float %a, %b
        \\  ret float %sum
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try expectMachineInstruction(machine.instructions.items, .{ .spill_xmm32_rsp = .{ .reg = .xmm0, .frame_index = .slot0 } });
    try expectMachineInstruction(machine.instructions.items, .{ .spill_xmm32_rsp = .{ .reg = .xmm1, .frame_index = .slot1 } });
    try expectMachineInstruction(machine.instructions.items, .{ .movapd_xmm = .{ .dst = .xmm0, .src = .xmm1 } });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_xmm32_rsp = .{ .reg = .xmm0, .frame_index = .slot0 } });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_xmm32_rsp = .{ .reg = .xmm1, .frame_index = .slot1 } });
    try expectMachineInstruction(machine.instructions.items, .addss_xmm1_xmm0);
}

test "x86_64 codegen preserves two live f64 params across FP argument call" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare void @touch(double)
        \\
        \\define double @caller(double %a, double %b) {
        \\entry:
        \\  call void @touch(double %b)
        \\  %sum = fadd double %a, %b
        \\  ret double %sum
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try expectMachineInstruction(machine.instructions.items, .{ .spill_xmm64_rsp = .{ .reg = .xmm0, .frame_index = .slot0 } });
    try expectMachineInstruction(machine.instructions.items, .{ .spill_xmm64_rsp = .{ .reg = .xmm1, .frame_index = .slot2 } });
    try expectMachineInstruction(machine.instructions.items, .{ .movapd_xmm = .{ .dst = .xmm0, .src = .xmm1 } });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_xmm64_rsp = .{ .reg = .xmm0, .frame_index = .slot0 } });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_xmm64_rsp = .{ .reg = .xmm1, .frame_index = .slot2 } });
    try expectMachineInstruction(machine.instructions.items, .addsd_xmm1_xmm0);
}

test "x86_64 codegen preserves three live f32 params across direct call" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare void @touch()
        \\
        \\define float @caller(float %a, float %b, float %c) {
        \\entry:
        \\  call void @touch()
        \\  %ab = fadd float %a, %b
        \\  %sum = fadd float %ab, %c
        \\  ret float %sum
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try expectMachineInstruction(machine.instructions.items, .sub_rsp_24);
    try expectMachineInstruction(machine.instructions.items, .{ .spill_xmm32_rsp = .{ .reg = .xmm0, .frame_index = .slot0 } });
    try expectMachineInstruction(machine.instructions.items, .{ .spill_xmm32_rsp = .{ .reg = .xmm1, .frame_index = .slot1 } });
    try expectMachineInstruction(machine.instructions.items, .{ .spill_xmm32_rsp = .{ .reg = .xmm2, .frame_index = .slot2 } });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_xmm32_rsp = .{ .reg = .xmm0, .frame_index = .slot0 } });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_xmm32_rsp = .{ .reg = .xmm1, .frame_index = .slot1 } });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_xmm32_rsp = .{ .reg = .xmm1, .frame_index = .slot2 } });
    var add_count: usize = 0;
    for (machine.instructions.items) |instruction| {
        if (instruction == .addss_xmm1_xmm0) add_count += 1;
    }
    try std.testing.expectEqual(@as(usize, 2), add_count);
    try expectMachineInstruction(machine.instructions.items, .add_rsp_24);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[machine.instructions.items.len - 1]);
}

test "x86_64 codegen preserves four live f32 params across direct call" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare void @touch()
        \\
        \\define float @caller(float %a, float %b, float %c, float %d) {
        \\entry:
        \\  call void @touch()
        \\  %ab = fadd float %a, %b
        \\  %abc = fadd float %ab, %c
        \\  %sum = fadd float %abc, %d
        \\  ret float %sum
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try expectMachineInstruction(machine.instructions.items, .sub_rsp_24);
    try expectMachineInstruction(machine.instructions.items, .{ .spill_xmm32_rsp = .{ .reg = .xmm0, .frame_index = .slot0 } });
    try expectMachineInstruction(machine.instructions.items, .{ .spill_xmm32_rsp = .{ .reg = .xmm1, .frame_index = .slot1 } });
    try expectMachineInstruction(machine.instructions.items, .{ .spill_xmm32_rsp = .{ .reg = .xmm2, .frame_index = .slot2 } });
    try expectMachineInstruction(machine.instructions.items, .{ .spill_xmm32_rsp = .{ .reg = .xmm3, .frame_index = .slot3 } });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_xmm32_rsp = .{ .reg = .xmm0, .frame_index = .slot0 } });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_xmm32_rsp = .{ .reg = .xmm1, .frame_index = .slot1 } });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_xmm32_rsp = .{ .reg = .xmm1, .frame_index = .slot2 } });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_xmm32_rsp = .{ .reg = .xmm1, .frame_index = .slot3 } });
    var add_count: usize = 0;
    for (machine.instructions.items) |instruction| {
        if (instruction == .addss_xmm1_xmm0) add_count += 1;
    }
    try std.testing.expectEqual(@as(usize, 3), add_count);
    try expectMachineInstruction(machine.instructions.items, .add_rsp_24);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[machine.instructions.items.len - 1]);
}

test "x86_64 codegen preserves six live f32 params across direct call" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare void @touch()
        \\
        \\define float @caller(float %a, float %b, float %c, float %d, float %e, float %f) {
        \\entry:
        \\  call void @touch()
        \\  %ab = fadd float %a, %b
        \\  %abc = fadd float %ab, %c
        \\  %abcd = fadd float %abc, %d
        \\  %abcde = fadd float %abcd, %e
        \\  %sum = fadd float %abcde, %f
        \\  ret float %sum
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try expectMachineInstruction(machine.instructions.items, .sub_rsp_40);
    try expectMachineInstruction(machine.instructions.items, .{ .spill_xmm32_rsp = .{ .reg = .xmm0, .frame_index = .slot0 } });
    try expectMachineInstruction(machine.instructions.items, .{ .spill_xmm32_rsp = .{ .reg = .xmm1, .frame_index = .slot1 } });
    try expectMachineInstruction(machine.instructions.items, .{ .spill_xmm32_rsp = .{ .reg = .xmm2, .frame_index = .slot2 } });
    try expectMachineInstruction(machine.instructions.items, .{ .spill_xmm32_rsp = .{ .reg = .xmm3, .frame_index = .slot3 } });
    try expectMachineInstruction(machine.instructions.items, .{ .spill_xmm32_rsp = .{ .reg = .xmm4, .frame_index = .slot4 } });
    try expectMachineInstruction(machine.instructions.items, .{ .spill_xmm32_rsp = .{ .reg = .xmm5, .frame_index = .slot5 } });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_xmm32_rsp = .{ .reg = .xmm0, .frame_index = .slot0 } });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_xmm32_rsp = .{ .reg = .xmm1, .frame_index = .slot1 } });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_xmm32_rsp = .{ .reg = .xmm1, .frame_index = .slot2 } });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_xmm32_rsp = .{ .reg = .xmm1, .frame_index = .slot3 } });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_xmm32_rsp = .{ .reg = .xmm1, .frame_index = .slot4 } });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_xmm32_rsp = .{ .reg = .xmm1, .frame_index = .slot5 } });
    var add_count: usize = 0;
    for (machine.instructions.items) |instruction| {
        if (instruction == .addss_xmm1_xmm0) add_count += 1;
    }
    try std.testing.expectEqual(@as(usize, 5), add_count);
    try expectMachineInstruction(machine.instructions.items, .add_rsp_40);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[machine.instructions.items.len - 1]);
}

test "x86_64 codegen preserves three live f64 params across direct call" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare void @touch()
        \\
        \\define double @caller(double %a, double %b, double %c) {
        \\entry:
        \\  call void @touch()
        \\  %ab = fadd double %a, %b
        \\  %sum = fadd double %ab, %c
        \\  ret double %sum
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try expectMachineInstruction(machine.instructions.items, .sub_rsp_40);
    try expectMachineInstruction(machine.instructions.items, .{ .spill_xmm64_rsp = .{ .reg = .xmm0, .frame_index = .slot0 } });
    try expectMachineInstruction(machine.instructions.items, .{ .spill_xmm64_rsp = .{ .reg = .xmm1, .frame_index = .slot2 } });
    try expectMachineInstruction(machine.instructions.items, .{ .spill_xmm64_rsp = .{ .reg = .xmm2, .frame_index = .slot4 } });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_xmm64_rsp = .{ .reg = .xmm0, .frame_index = .slot0 } });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_xmm64_rsp = .{ .reg = .xmm1, .frame_index = .slot2 } });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_xmm64_rsp = .{ .reg = .xmm1, .frame_index = .slot4 } });
    var add_count: usize = 0;
    for (machine.instructions.items) |instruction| {
        if (instruction == .addsd_xmm1_xmm0) add_count += 1;
    }
    try std.testing.expectEqual(@as(usize, 2), add_count);
    try expectMachineInstruction(machine.instructions.items, .add_rsp_40);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[machine.instructions.items.len - 1]);
}

test "x86_64 codegen preserves four live f64 params across direct call" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare void @touch()
        \\
        \\define double @caller(double %a, double %b, double %c, double %d) {
        \\entry:
        \\  call void @touch()
        \\  %ab = fadd double %a, %b
        \\  %abc = fadd double %ab, %c
        \\  %sum = fadd double %abc, %d
        \\  ret double %sum
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try expectMachineInstruction(machine.instructions.items, .sub_rsp_40);
    try expectMachineInstruction(machine.instructions.items, .{ .spill_xmm64_rsp = .{ .reg = .xmm0, .frame_index = .slot0 } });
    try expectMachineInstruction(machine.instructions.items, .{ .spill_xmm64_rsp = .{ .reg = .xmm1, .frame_index = .slot2 } });
    try expectMachineInstruction(machine.instructions.items, .{ .spill_xmm64_rsp = .{ .reg = .xmm2, .frame_index = .slot4 } });
    try expectMachineInstruction(machine.instructions.items, .{ .spill_xmm64_rsp = .{ .reg = .xmm3, .frame_index = .slot6 } });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_xmm64_rsp = .{ .reg = .xmm0, .frame_index = .slot0 } });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_xmm64_rsp = .{ .reg = .xmm1, .frame_index = .slot2 } });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_xmm64_rsp = .{ .reg = .xmm1, .frame_index = .slot4 } });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_xmm64_rsp = .{ .reg = .xmm1, .frame_index = .slot6 } });
    var add_count: usize = 0;
    for (machine.instructions.items) |instruction| {
        if (instruction == .addsd_xmm1_xmm0) add_count += 1;
    }
    try std.testing.expectEqual(@as(usize, 3), add_count);
    try expectMachineInstruction(machine.instructions.items, .add_rsp_40);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[machine.instructions.items.len - 1]);
}

test "x86_64 codegen preserves six live f64 params across direct call" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare void @touch()
        \\
        \\define double @caller(double %a, double %b, double %c, double %d, double %e, double %f) {
        \\entry:
        \\  call void @touch()
        \\  %ab = fadd double %a, %b
        \\  %abc = fadd double %ab, %c
        \\  %abcd = fadd double %abc, %d
        \\  %abcde = fadd double %abcd, %e
        \\  %sum = fadd double %abcde, %f
        \\  ret double %sum
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try expectMachineInstruction(machine.instructions.items, .sub_rsp_56);
    try expectMachineInstruction(machine.instructions.items, .{ .spill_xmm64_rsp = .{ .reg = .xmm0, .frame_index = .slot0 } });
    try expectMachineInstruction(machine.instructions.items, .{ .spill_xmm64_rsp = .{ .reg = .xmm1, .frame_index = .slot2 } });
    try expectMachineInstruction(machine.instructions.items, .{ .spill_xmm64_rsp = .{ .reg = .xmm2, .frame_index = .slot4 } });
    try expectMachineInstruction(machine.instructions.items, .{ .spill_xmm64_rsp = .{ .reg = .xmm3, .frame_index = .slot6 } });
    try expectMachineInstruction(machine.instructions.items, .{ .spill_xmm64_rsp = .{ .reg = .xmm4, .frame_index = .slot8 } });
    try expectMachineInstruction(machine.instructions.items, .{ .spill_xmm64_rsp = .{ .reg = .xmm5, .frame_index = .slot10 } });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_xmm64_rsp = .{ .reg = .xmm0, .frame_index = .slot0 } });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_xmm64_rsp = .{ .reg = .xmm1, .frame_index = .slot2 } });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_xmm64_rsp = .{ .reg = .xmm1, .frame_index = .slot4 } });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_xmm64_rsp = .{ .reg = .xmm1, .frame_index = .slot6 } });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_xmm64_rsp = .{ .reg = .xmm1, .frame_index = .slot8 } });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_xmm64_rsp = .{ .reg = .xmm1, .frame_index = .slot10 } });
    var add_count: usize = 0;
    for (machine.instructions.items) |instruction| {
        if (instruction == .addsd_xmm1_xmm0) add_count += 1;
    }
    try std.testing.expectEqual(@as(usize, 5), add_count);
    try expectMachineInstruction(machine.instructions.items, .add_rsp_56);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[machine.instructions.items.len - 1]);
}

test "x86_64 codegen supports mixed integer and SSE call streams with stack args" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare fastcc double @callee(i32, float, i64, double, i32, i32, i32, i32, i32)
        \\
        \\define double @caller() {
        \\entry:
        \\  %r = call fastcc double @callee(i32 1, float 2.000000e+00, i64 3, double 4.000000e+00, i32 5, i32 6, i32 7, i32 8, i32 9)
        \\  ret double %r
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .push_imm32 = 9 }, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .mov_imm_rdi = 1 }, machine.instructions.items[1]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .mov_imm32_xmm = .{ .reg = .xmm0, .bits = 0x4000_0000 } }, machine.instructions.items[2]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .mov_imm_rsi = 3 }, machine.instructions.items[3]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .mov_imm64_xmm = .{ .reg = .xmm1, .bits = 0x4010_0000_0000_0000 } }, machine.instructions.items[4]);
}

test "x86_64 codegen supports five named f64 pass-through call args" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare double @callee(double, double, double, double, double)
        \\
        \\define double @caller(double %a, double %b, double %c, double %d, double %e) {
        \\entry:
        \\  %r = call double @callee(double %a, double %b, double %c, double %d, double %e)
        \\  ret double %r
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try std.testing.expectEqual(codegen.x86_64.Instruction.sub_rsp_8, machine.instructions.items[0]);
    const call = switch (machine.instructions.items[1]) {
        .direct_call => |call| call,
        else => return error.ExpectedDirectCall,
    };
    try std.testing.expectEqualStrings("callee", call.symbol);
    try std.testing.expectEqual(ir.Type.double, call.ret_ty);
    try std.testing.expectEqual(codegen.x86_64.Instruction.add_rsp_8, machine.instructions.items[2]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[3]);
}

test "x86_64 codegen supports five named f32 pass-through call args" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare float @callee(float, float, float, float, float)
        \\
        \\define float @caller(float %a, float %b, float %c, float %d, float %e) {
        \\entry:
        \\  %r = call float @callee(float %a, float %b, float %c, float %d, float %e)
        \\  ret float %r
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try std.testing.expectEqual(codegen.x86_64.Instruction.sub_rsp_8, machine.instructions.items[0]);
    const call = switch (machine.instructions.items[1]) {
        .direct_call => |call| call,
        else => return error.ExpectedDirectCall,
    };
    try std.testing.expectEqualStrings("callee", call.symbol);
    try std.testing.expectEqual(ir.Type.float, call.ret_ty);
    try std.testing.expectEqual(codegen.x86_64.Instruction.add_rsp_8, machine.instructions.items[2]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[3]);
}
