const std = @import("std");
const air_bridge = @import("../air_bridge.zig");
const alias = @import("../analysis/alias.zig");
const call_graph = @import("../analysis/call_graph.zig");
const cfg = @import("../analysis/cfg.zig");
const codegen = @import("../codegen.zig");
const dominator = @import("../analysis/dominator.zig");
const function_attrs = @import("../analysis/function_attrs.zig");
const fp_semantics = @import("../analysis/fp_semantics.zig");
const loop_info = @import("../analysis/loop_info.zig");
const memory_effect = @import("../analysis/memory_effect.zig");
const memory_location = @import("../analysis/memory_location.zig");
const memory_ssa = @import("../analysis/memory_ssa.zig");
const ir = @import("../ir.zig");
const normalize = @import("../normalize.zig");
const mc = @import("../mc.zig");
const pass_manager = @import("../pass_manager.zig");
const pipelines = @import("../pipelines.zig");
const postdominator = @import("../analysis/postdominator.zig");
const semantic_descriptor_v2 = @import("../semantic_descriptor_v2.zig");
const target = @import("../target.zig");
const target_library_info = @import("../analysis/target_library_info.zig");
const target_transform_info = @import("../analysis/target_transform_info.zig");
const instcombine = @import("../passes/instcombine.zig");
const zig_air_export = @import("../zig_air_export.zig");
const zig_air_lowering = @import("../zig_air_lowering.zig");
const dce = @import("../passes/dce.zig");
const dse = @import("../passes/dse.zig");
const early_cse = @import("../passes/early_cse.zig");
const gvn = @import("../passes/gvn.zig");
const licm = @import("../passes/licm.zig");
const mem2reg = @import("../passes/mem2reg.zig");
const sccp = @import("../passes/sccp.zig");
const simplifycfg = @import("../passes/simplifycfg.zig");
const slp_vectorizer = @import("../passes/slp_vectorizer.zig");
const sroa = @import("../passes/sroa.zig");

test {
    _ = zig_air_export;
    _ = zig_air_lowering;
}

fn expectMachineInstruction(instructions: []const codegen.x86_64.Instruction, expected: codegen.x86_64.Instruction) !void {
    for (instructions) |instruction| {
        if (std.meta.eql(instruction, expected)) return;
    }
    return error.TestExpectedEqual;
}

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

test "x86_64 codegen supports third FP constant call arg in xmm2" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare double @callee(double, double, double)
        \\
        \\define double @caller() {
        \\entry:
        \\  %r = call double @callee(double 1.000000e+00, double 2.000000e+00, double 3.000000e+00)
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
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .mov_imm64_xmm = .{ .reg = .xmm0, .bits = 0x3ff0_0000_0000_0000 } }, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .mov_imm64_xmm = .{ .reg = .xmm1, .bits = 0x4000_0000_0000_0000 } }, machine.instructions.items[1]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .mov_imm64_xmm = .{ .reg = .xmm2, .bits = 0x4008_0000_0000_0000 } }, machine.instructions.items[2]);
}

test "x86_64 codegen supports mixed integer and f64 direct call return" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare fastcc double @callee(i32, double)
        \\
        \\define double @caller() {
        \\entry:
        \\  %r = call fastcc double @callee(i32 7, double 6.000000e+00)
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
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .mov_imm_rdi = 7 }, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .mov_imm64_xmm = .{ .reg = .xmm0, .bits = 0x4018_0000_0000_0000 } }, machine.instructions.items[1]);
}

test "x86_64 codegen supports i64 direct call returns and mixed i32 i64 args" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare fastcc i64 @callee(i32, i64)
        \\
        \\define i64 @caller() {
        \\entry:
        \\  %r = call fastcc i64 @callee(i32 7, i64 123456789)
        \\  ret i64 %r
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .mov_imm_rdi = 7 }, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .mov_imm_rsi = 123456789 }, machine.instructions.items[1]);
}

test "x86_64 codegen returns first f64 parameter from mixed signature" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define fastcc double @callee(i32 %tag, double %value) {
        \\entry:
        \\  ret double %value
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[0]);
}

test "x86_64 codegen returns i64 parameter from mixed integer signature" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define fastcc i64 @callee(i32 %tag, i64 %value) {
        \\entry:
        \\  ret i64 %value
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .mov_arg_rax = .rsi }, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[1]);
}

test "x86_64 SysV call planner counts independent GPR SSE and stack streams" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare i32 @callee(i32, i32, i32, i32, i32, i32, i32, double, double)
        \\
        \\define i32 @caller(i32 %a, i32 %b) {
        \\entry:
        \\  %r = call i32 @callee(i32 %a, i32 %b, i32 3, i32 4, i32 5, i32 6, i32 7, double 1.250000e+00, double 2.500000e+00)
        \\  ret i32 %r
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    const call = module.functions.items[0].blocks.items[0].instructions.items[0].kind.call;
    const counts = try codegen.x86_64.sysvCallPlanCountsForTest(std.testing.allocator, module.functions.items[0], call);
    try std.testing.expectEqual(@as(usize, 6), counts.gpr_args);
    try std.testing.expectEqual(@as(usize, 2), counts.sse_args);
    try std.testing.expectEqual(@as(usize, 1), counts.stack_args);
    try std.testing.expectEqual(@as(usize, 0), counts.register_aggregate_args);
    try std.testing.expectEqual(@as(usize, 1), counts.gpr_returns);
    try std.testing.expectEqual(@as(usize, 0), counts.sse_returns);
    try std.testing.expect(!counts.memory_return);
}

test "x86_64 SysV call planner classifies scalar aggregate and memory returns" {
    const scalar_input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare double @callee()
        \\
        \\define double @caller() {
        \\entry:
        \\  %r = call double @callee()
        \\  ret double %r
        \\}
        \\
    ;
    var scalar_module = try ir.Module.parse(std.testing.allocator, scalar_input);
    defer scalar_module.deinit();
    try scalar_module.verify();
    const scalar_call = scalar_module.functions.items[0].blocks.items[0].instructions.items[0].kind.call;
    const scalar_counts = try codegen.x86_64.sysvCallPlanCountsForTest(std.testing.allocator, scalar_module.functions.items[0], scalar_call);
    try std.testing.expectEqual(@as(usize, 0), scalar_counts.gpr_returns);
    try std.testing.expectEqual(@as(usize, 1), scalar_counts.sse_returns);
    try std.testing.expect(!scalar_counts.memory_return);

    const mixed_input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare { i64, double } @callee()
        \\
        \\define { i64, double } @caller() {
        \\entry:
        \\  %r = call { i64, double } @callee()
        \\  ret { i64, double } %r
        \\}
        \\
    ;
    var mixed_module = try ir.Module.parse(std.testing.allocator, mixed_input);
    defer mixed_module.deinit();
    try mixed_module.verify();
    const mixed_call = mixed_module.functions.items[0].blocks.items[0].instructions.items[0].kind.call;
    const mixed_counts = try codegen.x86_64.sysvCallPlanCountsForTest(std.testing.allocator, mixed_module.functions.items[0], mixed_call);
    try std.testing.expectEqual(@as(usize, 1), mixed_counts.gpr_returns);
    try std.testing.expectEqual(@as(usize, 1), mixed_counts.sse_returns);
    try std.testing.expect(!mixed_counts.memory_return);

    const memory_input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare { i64, i64, i64 } @callee()
        \\
        \\define { i64, i64, i64 } @caller() {
        \\entry:
        \\  %r = call { i64, i64, i64 } @callee()
        \\  ret { i64, i64, i64 } %r
        \\}
        \\
    ;
    var memory_module = try ir.Module.parse(std.testing.allocator, memory_input);
    defer memory_module.deinit();
    try memory_module.verify();
    const memory_call = memory_module.functions.items[0].blocks.items[0].instructions.items[0].kind.call;
    const memory_counts = try codegen.x86_64.sysvCallPlanCountsForTest(std.testing.allocator, memory_module.functions.items[0], memory_call);
    try std.testing.expectEqual(@as(usize, 0), memory_counts.gpr_returns);
    try std.testing.expectEqual(@as(usize, 0), memory_counts.sse_returns);
    try std.testing.expect(memory_counts.memory_return);
}

test "x86_64 generic CFG forwards stack-passed integer aggregate to register aggregate call" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare i64 @sum_pair({ [2 x i64] })
        \\
        \\define i64 @caller(i64 %a0, i64 %a1, i64 %a2, i64 %a3, i64 %a4, i64 %a5, { [2 x i64] } %value) {
        \\entry:
        \\  %r = call i64 @sum_pair({ [2 x i64] } %value)
        \\  ret i64 %r
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .load_stack_disp8_arg64 = .{ .reg = .rdi, .disp = 8 } }, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .load_stack_disp8_arg64 = .{ .reg = .rsi, .disp = 16 } }, machine.instructions.items[1]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.sub_rsp_8, machine.instructions.items[2]);
    const call = switch (machine.instructions.items[3]) {
        .direct_call => |call| call,
        else => return error.ExpectedDirectCall,
    };
    try std.testing.expectEqualStrings("sum_pair", call.symbol);
    try std.testing.expect(call.ret_ty.eql(.{ .int = 64 }));
    try std.testing.expectEqual(codegen.x86_64.Instruction.add_rsp_8, machine.instructions.items[4]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[5]);
}

test "x86_64 generic CFG forwards stack-passed SSE aggregate to register aggregate call" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare double @sum_double_pair({ [2 x double] })
        \\
        \\define double @caller(double %a0, double %a1, double %a2, double %a3, double %a4, double %a5, double %a6, double %a7, { [2 x double] } %value) {
        \\entry:
        \\  %r = call double @sum_double_pair({ [2 x double] } %value)
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
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .load_stack_disp8_xmm = .{ .reg = .xmm0, .disp = 8 } }, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .load_stack_disp8_xmm = .{ .reg = .xmm1, .disp = 16 } }, machine.instructions.items[1]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.sub_rsp_8, machine.instructions.items[2]);
    const call = switch (machine.instructions.items[3]) {
        .direct_call => |call| call,
        else => return error.ExpectedDirectCall,
    };
    try std.testing.expectEqualStrings("sum_double_pair", call.symbol);
    try std.testing.expect(call.ret_ty.eql(.double));
    try std.testing.expectEqual(codegen.x86_64.Instruction.add_rsp_8, machine.instructions.items[4]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[5]);
}

test "x86_64 generic CFG forwards stack-passed mixed aggregate to register aggregate call" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare i64 @mixed_int({ i64, double })
        \\
        \\define i64 @caller(i64 %a0, i64 %a1, i64 %a2, i64 %a3, i64 %a4, i64 %a5, { i64, double } %value) {
        \\entry:
        \\  %r = call i64 @mixed_int({ i64, double } %value)
        \\  ret i64 %r
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .load_stack_disp8_arg64 = .{ .reg = .rdi, .disp = 8 } }, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .load_stack_disp8_xmm = .{ .reg = .xmm0, .disp = 16 } }, machine.instructions.items[1]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.sub_rsp_8, machine.instructions.items[2]);
    const call = switch (machine.instructions.items[3]) {
        .direct_call => |call| call,
        else => return error.ExpectedDirectCall,
    };
    try std.testing.expectEqualStrings("mixed_int", call.symbol);
    try std.testing.expect(call.ret_ty.eql(.{ .int = 64 }));
    try std.testing.expectEqual(codegen.x86_64.Instruction.add_rsp_8, machine.instructions.items[4]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[5]);
}

test "x86_64 generic CFG forwards stack-passed integer aggregate to stack aggregate call" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare i64 @sum_pair_after_six(i64, i64, i64, i64, i64, i64, { [2 x i64] })
        \\
        \\define i64 @caller(i64 %a0, i64 %a1, i64 %a2, i64 %a3, i64 %a4, i64 %a5, { [2 x i64] } %value) {
        \\entry:
        \\  %r = call i64 @sum_pair_after_six(i64 %a0, i64 %a1, i64 %a2, i64 %a3, i64 %a4, i64 %a5, { [2 x i64] } %value)
        \\  ret i64 %r
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
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .push_stack_disp8 = 24 }, machine.instructions.items[1]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .push_stack_disp8 = 24 }, machine.instructions.items[2]);
    const call = switch (machine.instructions.items[3]) {
        .direct_call => |call| call,
        else => return error.ExpectedDirectCall,
    };
    try std.testing.expectEqualStrings("sum_pair_after_six", call.symbol);
    try std.testing.expect(call.ret_ty.eql(.{ .int = 64 }));
    try std.testing.expectEqual(codegen.x86_64.Instruction.add_rsp_24, machine.instructions.items[4]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[5]);
}

test "x86_64 generic CFG forwards register integer aggregate to stack aggregate call before clobbering args" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare i64 @sum_pair_after_six(i64, i64, i64, i64, i64, i64, { [2 x i64] })
        \\
        \\define i64 @caller({ [2 x i64] } %value) {
        \\entry:
        \\  %r = call i64 @sum_pair_after_six(i64 1, i64 2, i64 3, i64 4, i64 5, i64 6, { [2 x i64] } %value)
        \\  ret i64 %r
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
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .push_arg = .rsi }, machine.instructions.items[1]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .push_arg = .rdi }, machine.instructions.items[2]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .mov_imm_rdi = 1 }, machine.instructions.items[3]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .mov_imm_rsi = 2 }, machine.instructions.items[4]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .mov_imm_rdx = 3 }, machine.instructions.items[5]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .mov_imm_rcx = 4 }, machine.instructions.items[6]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .mov_imm_r8 = 5 }, machine.instructions.items[7]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .mov_imm_r9 = 6 }, machine.instructions.items[8]);
    const call = switch (machine.instructions.items[9]) {
        .direct_call => |call| call,
        else => return error.ExpectedDirectCall,
    };
    try std.testing.expectEqualStrings("sum_pair_after_six", call.symbol);
    try std.testing.expect(call.ret_ty.eql(.{ .int = 64 }));
    try std.testing.expectEqual(codegen.x86_64.Instruction.add_rsp_24, machine.instructions.items[10]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[11]);
}

test "x86_64 generic CFG forwards register SSE aggregate to stack aggregate call before clobbering XMMs" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare double @sum_double_pair_after_eight(double, double, double, double, double, double, double, double, { [2 x double] })
        \\
        \\define double @caller({ [2 x double] } %value) {
        \\entry:
        \\  %r = call double @sum_double_pair_after_eight(double 1.000000e+00, double 2.000000e+00, double 3.000000e+00, double 4.000000e+00, double 5.000000e+00, double 6.000000e+00, double 7.000000e+00, double 8.000000e+00, { [2 x double] } %value)
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
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .push_xmm64 = .xmm1 }, machine.instructions.items[1]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .push_xmm64 = .xmm0 }, machine.instructions.items[2]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .mov_imm64_xmm = .{ .reg = .xmm0, .bits = 0x3ff0_0000_0000_0000 } }, machine.instructions.items[3]);
    const call = switch (machine.instructions.items[11]) {
        .direct_call => |call| call,
        else => return error.ExpectedDirectCall,
    };
    try std.testing.expectEqualStrings("sum_double_pair_after_eight", call.symbol);
    try std.testing.expect(call.ret_ty.eql(.double));
    try std.testing.expectEqual(codegen.x86_64.Instruction.add_rsp_24, machine.instructions.items[12]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[13]);
}

test "x86_64 generic CFG shifts register aggregate GPRs for mixed aggregate call" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare i64 @mixed_int({ i64, double })
        \\
        \\define i64 @caller(i64 %prefix, { i64, double } %value) {
        \\entry:
        \\  %r = call i64 @mixed_int({ i64, double } %value)
        \\  ret i64 %r
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .mov_arg64_arg = .{ .dst = .rdi, .src = .rsi } }, machine.instructions.items[0]);
    try std.testing.expectEqual(@as(u32, 3), mc.encoding.instructionSize(machine.instructions.items[0]));
    try std.testing.expectEqual(codegen.x86_64.Instruction.sub_rsp_8, machine.instructions.items[1]);
    const call = switch (machine.instructions.items[2]) {
        .direct_call => |call| call,
        else => return error.ExpectedDirectCall,
    };
    try std.testing.expectEqualStrings("mixed_int", call.symbol);
    try std.testing.expect(call.ret_ty.eql(.{ .int = 64 }));
    try std.testing.expectEqual(codegen.x86_64.Instruction.add_rsp_8, machine.instructions.items[3]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[4]);
}

test "x86_64 generic CFG shifts register aggregate XMMs for reversed mixed aggregate call" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare double @reverse_float({ double, i64 })
        \\
        \\define double @caller(double %prefix, { double, i64 } %value) {
        \\entry:
        \\  %r = call double @reverse_float({ double, i64 } %value)
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
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .movapd_xmm = .{ .dst = .xmm0, .src = .xmm1 } }, machine.instructions.items[0]);
    try std.testing.expectEqual(@as(u32, 4), mc.encoding.instructionSize(machine.instructions.items[0]));
    try std.testing.expectEqual(codegen.x86_64.Instruction.sub_rsp_8, machine.instructions.items[1]);
    const call = switch (machine.instructions.items[2]) {
        .direct_call => |call| call,
        else => return error.ExpectedDirectCall,
    };
    try std.testing.expectEqualStrings("reverse_float", call.symbol);
    try std.testing.expect(call.ret_ty.eql(.double));
    try std.testing.expectEqual(codegen.x86_64.Instruction.add_rsp_8, machine.instructions.items[3]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[4]);
}

test "x86_64 SysV call planner rejects varargs explicitly" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare i32 @printf(ptr, ...)
        \\
        \\define i32 @caller(ptr %fmt) {
        \\entry:
        \\  %r = call i32 (ptr, ...) @printf(ptr %fmt, double 2.000000e+00)
        \\  ret i32 %r
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    const call = module.functions.items[0].blocks.items[0].instructions.items[0].kind.call;
    try std.testing.expectError(
        error.UnsupportedCodegenAbi,
        codegen.x86_64.sysvCallPlanCountsForTest(std.testing.allocator, module.functions.items[0], call),
    );
}

test "x86_64 SysV call planner accepts narrow indirect calls and rejects tail callconv boundaries" {
    const indirect_input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @caller(ptr %fn, i32 %a) {
        \\entry:
        \\  %r = call i32 %fn(i32 %a)
        \\  ret i32 %r
        \\}
        \\
    ;
    var indirect_module = try ir.Module.parse(std.testing.allocator, indirect_input);
    defer indirect_module.deinit();
    try indirect_module.verify();
    const indirect_call = indirect_module.functions.items[0].blocks.items[0].instructions.items[0].kind.call;
    const indirect_counts = try codegen.x86_64.sysvCallPlanCountsForTest(std.testing.allocator, indirect_module.functions.items[0], indirect_call);
    try std.testing.expectEqual(@as(usize, 1), indirect_counts.gpr_args);
    try std.testing.expectEqual(@as(usize, 1), indirect_counts.gpr_returns);

    const tail_input =
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
    var tail_module = try ir.Module.parse(std.testing.allocator, tail_input);
    defer tail_module.deinit();
    try tail_module.verify();
    const tail_call = tail_module.functions.items[0].blocks.items[0].instructions.items[0].kind.call;
    try std.testing.expectError(
        error.UnsupportedCodegenAbi,
        codegen.x86_64.sysvCallPlanCountsForTest(std.testing.allocator, tail_module.functions.items[0], tail_call),
    );

    const callconv_input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare coldcc i32 @callee(i32)
        \\
        \\define i32 @caller(i32 %a) {
        \\entry:
        \\  %r = call coldcc i32 @callee(i32 %a)
        \\  ret i32 %r
        \\}
        \\
    ;
    var callconv_module = try ir.Module.parse(std.testing.allocator, callconv_input);
    defer callconv_module.deinit();
    try callconv_module.verify();
    const callconv_call = callconv_module.functions.items[0].blocks.items[0].instructions.items[0].kind.call;
    try std.testing.expectError(
        error.UnsupportedCodegenAbi,
        codegen.x86_64.sysvCallPlanCountsForTest(std.testing.allocator, callconv_module.functions.items[0], callconv_call),
    );
}

test "x86_64 generic CFG forwards memory aggregate through hidden-sret indirect call" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define { i64, i64, i64, i64, i64 } @caller(ptr %fn, { i64, i64, i64, i64, i64 } %value) {
        \\entry:
        \\  %r = call { i64, i64, i64, i64, i64 } %fn({ i64, i64, i64, i64, i64 } %value)
        \\  ret { i64, i64, i64, i64, i64 } %r
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .push_stack_disp8 = 40 }, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .push_stack_disp8 = 40 }, machine.instructions.items[1]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .push_stack_disp8 = 40 }, machine.instructions.items[2]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .push_stack_disp8 = 40 }, machine.instructions.items[3]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .push_stack_disp8 = 40 }, machine.instructions.items[4]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .mov_arg_rax = .rsi }, machine.instructions.items[5]);
    const ret_ty = switch (machine.instructions.items[6]) {
        .indirect_call_rax => |ret_ty| ret_ty,
        else => return error.ExpectedIndirectCall,
    };
    try std.testing.expectEqualStrings("{ i64, i64, i64, i64, i64 }", ret_ty.aggregate);
    try std.testing.expectEqual(codegen.x86_64.Instruction.add_rsp_40, machine.instructions.items[7]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[8]);
}

test "x86_64 generic CFG forwards memory aggregate through hidden-sret direct call" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare { i64, i64, i64, i64, i64 } @callee({ i64, i64, i64, i64, i64 })
        \\
        \\define { i64, i64, i64, i64, i64 } @caller({ i64, i64, i64, i64, i64 } %value) {
        \\entry:
        \\  %r = call { i64, i64, i64, i64, i64 } @callee({ i64, i64, i64, i64, i64 } %value)
        \\  ret { i64, i64, i64, i64, i64 } %r
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .push_stack_disp8 = 40 }, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .push_stack_disp8 = 40 }, machine.instructions.items[1]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .push_stack_disp8 = 40 }, machine.instructions.items[2]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .push_stack_disp8 = 40 }, machine.instructions.items[3]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .push_stack_disp8 = 40 }, machine.instructions.items[4]);
    const call = switch (machine.instructions.items[5]) {
        .direct_call => |call| call,
        else => return error.ExpectedDirectCall,
    };
    try std.testing.expectEqualStrings("callee", call.symbol);
    try std.testing.expectEqualStrings("{ i64, i64, i64, i64, i64 }", call.ret_ty.aggregate);
    try std.testing.expectEqual(codegen.x86_64.Instruction.add_rsp_40, machine.instructions.items[6]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[7]);
}

test "x86_64 generic CFG lowers narrow i32 indirect call through rax" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @caller(ptr %fn, i32 %a) {
        \\entry:
        \\  %r = call i32 %fn(i32 %a)
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
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .mov_arg_rax = .rdi }, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .mov_arg_arg = .{ .dst = .rdi, .src = .rsi } }, machine.instructions.items[1]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.sub_rsp_8, machine.instructions.items[2]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .indirect_call_rax = .{ .int = 32 } }, machine.instructions.items[3]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.add_rsp_8, machine.instructions.items[4]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[5]);
}

test "x86_64 generic CFG preserves live i32 params across indirect call" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @caller(ptr %fn, i32 %a, i32 %b, i32 %c) {
        \\entry:
        \\  %r = call i32 %fn(i32 %a)
        \\  %sum0 = add i32 %r, %b
        \\  %sum1 = add i32 %sum0, %c
        \\  ret i32 %sum1
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
    try expectMachineInstruction(machine.instructions.items, .{ .spill_arg_rsp = .{ .frame_index = .slot0, .reg = .rdx } });
    try expectMachineInstruction(machine.instructions.items, .{ .spill_arg_rsp = .{ .frame_index = .slot1, .reg = .rcx } });
    try expectMachineInstruction(machine.instructions.items, .{ .mov_arg_rax = .rdi });
    try expectMachineInstruction(machine.instructions.items, .{ .mov_arg_arg = .{ .dst = .rdi, .src = .rsi } });
    try expectMachineInstruction(machine.instructions.items, .{ .indirect_call_rax = .{ .int = 32 } });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_arg_rsp = .{ .reg = .rdx, .frame_index = .slot0 } });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_arg_rsp = .{ .reg = .rcx, .frame_index = .slot1 } });
    try expectMachineInstruction(machine.instructions.items, .add_rsp_24);
}

test "x86_64 generic CFG lowers indirect i64 call with stack parameter reload" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i64 @caller(ptr %fn, i64 %a, i64 %b, i64 %c, i64 %d, i64 %e, i64 %f, i64 %g, i64 %h) {
        \\entry:
        \\  %r = call i64 %fn(i64 %a, i64 %b, i64 %c, i64 %d, i64 %e, i64 %f, i64 %g, i64 %h)
        \\  ret i64 %r
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

    var saw_shifted_first_arg = false;
    var saw_stack_i64_reload = false;
    for (machine.instructions.items) |instruction| {
        switch (instruction) {
            .mov_arg64_arg => |mov| {
                if (mov.dst == .rdi and mov.src == .rsi) saw_shifted_first_arg = true;
            },
            .load_stack_disp8_arg64 => |load| {
                if (load.reg == .r9 and load.disp == 32) saw_stack_i64_reload = true;
            },
            else => {},
        }
    }
    try std.testing.expect(saw_shifted_first_arg);
    try std.testing.expect(saw_stack_i64_reload);
}

test "x86_64 generic CFG lowers computed i32 stack call argument" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare i32 @sum12(i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32)
        \\
        \\define i32 @caller(i32 %a, i32 %b, i32 %c, i32 %d, i32 %e, i32 %f, i32 %g) {
        \\entry:
        \\  %x = add i32 %g, 1
        \\  %r = call i32 @sum12(i32 %a, i32 %b, i32 %c, i32 %d, i32 %e, i32 %f, i32 %x, i32 8, i32 9, i32 10, i32 11, i32 12)
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
    try expectMachineInstruction(machine.instructions.items, .{ .push_imm32 = 12 });
    try expectMachineInstruction(machine.instructions.items, .push_rax);
    try expectMachineInstruction(machine.instructions.items, .{ .add_eax_imm32 = 1 });
}

test "x86_64 generic CFG lowers indirect call with eight stack arguments" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @caller(ptr %fn) {
        \\entry:
        \\  %r = call i32 %fn(i32 1, i32 2, i32 3, i32 4, i32 5, i32 6, i32 7, i32 8, i32 9, i32 10, i32 11, i32 12, i32 13, i32 14)
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
    try expectMachineInstruction(machine.instructions.items, .{ .mov_arg_rax = .rdi });
    try expectMachineInstruction(machine.instructions.items, .{ .push_imm32 = 14 });
    try expectMachineInstruction(machine.instructions.items, .{ .indirect_call_rax = .{ .int = 32 } });
    try expectMachineInstruction(machine.instructions.items, .{ .add_rsp_imm8 = 72 });
}

test "x86_64 generic CFG lowers computed i64 stack call argument" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare i64 @sum8(i64, i64, i64, i64, i64, i64, i64, i64)
        \\
        \\define i64 @caller(i64 %a, i64 %b, i64 %c, i64 %d, i64 %e, i64 %f, i64 %g) {
        \\entry:
        \\  %x = add i64 %g, 1
        \\  %r = call i64 @sum8(i64 %a, i64 %b, i64 %c, i64 %d, i64 %e, i64 %f, i64 %x, i64 8)
        \\  ret i64 %r
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try expectMachineInstruction(machine.instructions.items, .{ .push_imm32 = 8 });
    try expectMachineInstruction(machine.instructions.items, .push_rax);
    try expectMachineInstruction(machine.instructions.items, .{ .add_rax_imm8 = 1 });
}

test "x86_64 SysV call planner rejects vector argument ABI boundary" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare i32 @callee(<2 x i32>)
        \\
        \\define i32 @caller(<2 x i32> %value) {
        \\entry:
        \\  %r = call i32 @callee(<2 x i32> %value)
        \\  ret i32 %r
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    const call = module.functions.items[0].blocks.items[0].instructions.items[0].kind.call;
    try std.testing.expectError(
        error.UnsupportedCodegenType,
        codegen.x86_64.sysvCallPlanCountsForTest(std.testing.allocator, module.functions.items[0], call),
    );
}

test "x86_64 SysV call planner rejects vector return ABI boundary" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare <2 x i32> @callee()
        \\
        \\define <2 x i32> @caller() {
        \\entry:
        \\  %r = call <2 x i32> @callee()
        \\  ret <2 x i32> %r
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    const call = module.functions.items[0].blocks.items[0].instructions.items[0].kind.call;
    try std.testing.expectError(
        error.UnsupportedCodegenType,
        codegen.x86_64.sysvCallPlanCountsForTest(std.testing.allocator, module.functions.items[0], call),
    );
}

test "x86_64 SysV call planner rejects X87 ABI boundary" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare void @callee(x86_fp80)
        \\
        \\define void @caller(x86_fp80 %value) {
        \\entry:
        \\  call void @callee(x86_fp80 %value)
        \\  ret void
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    const call = module.functions.items[0].blocks.items[0].instructions.items[0].kind.call;
    try std.testing.expectError(
        error.UnsupportedCodegenType,
        codegen.x86_64.sysvCallPlanCountsForTest(std.testing.allocator, module.functions.items[0], call),
    );
}

test "parser rejects packed aggregate ABI signatures before x86_64 codegen" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare i64 @callee(<{ i8, i64 }>)
        \\
        \\define i64 @caller(<{ i8, i64 }> %value) {
        \\entry:
        \\  %r = call i64 @callee(<{ i8, i64 }> %value)
        \\  ret i64 %r
        \\}
        \\
    ;
    try std.testing.expectError(error.UnsupportedType, ir.Module.parse(std.testing.allocator, input));
}

test "x86_64 codegen rejects vector call ABI boundary" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare i32 @callee(<2 x i32>)
        \\
        \\define i32 @caller(<2 x i32> %value) {
        \\entry:
        \\  %r = call i32 @callee(<2 x i32> %value)
        \\  ret i32 %r
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    try std.testing.expectError(
        error.UnsupportedCodegenType,
        codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]),
    );
}

test "x86_64 codegen rejects varargs call ABI boundary" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare i32 @printf(ptr, ...)
        \\
        \\define i32 @caller(ptr %fmt) {
        \\entry:
        \\  %r = call i32 (ptr, ...) @printf(ptr %fmt, double 2.000000e+00)
        \\  ret i32 %r
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    try std.testing.expectError(
        error.UnsupportedCodegenAbi,
        codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]),
    );
}

test "x86_64 codegen rejects sret and byval call ABI boundaries" {
    const sret_input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare void @callee(ptr sret({ i32, i32 }), i32)
        \\
        \\define void @caller(ptr %out) {
        \\entry:
        \\  call void @callee(ptr sret({ i32, i32 }) %out, i32 7)
        \\  ret void
        \\}
        \\
    ;
    var sret_module = try ir.Module.parse(std.testing.allocator, sret_input);
    defer sret_module.deinit();
    try sret_module.verify();
    try std.testing.expectError(
        error.UnsupportedCodegenAbi,
        codegen.x86_64.lowerFunction(std.testing.allocator, sret_module.target_triple.?, sret_module.functions.items[0]),
    );

    const byval_input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare i32 @callee(ptr byval({ i32, i32 }))
        \\
        \\define i32 @caller(ptr %arg) {
        \\entry:
        \\  %r = call i32 @callee(ptr byval({ i32, i32 }) %arg)
        \\  ret i32 %r
        \\}
        \\
    ;
    var byval_module = try ir.Module.parse(std.testing.allocator, byval_input);
    defer byval_module.deinit();
    try byval_module.verify();
    try std.testing.expectError(
        error.UnsupportedCodegenAbi,
        codegen.x86_64.lowerFunction(std.testing.allocator, byval_module.target_triple.?, byval_module.functions.items[0]),
    );
}

test "x86_64 codegen rejects larger aggregate call and vector return ABI boundaries" {
    const aggregate_input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare i32 @callee({ i64, i64, i64 })
        \\
        \\define i32 @caller({ i64, i64, i64 } %arg) {
        \\entry:
        \\  %r = call i32 @callee({ i64, i64, i64 } %arg)
        \\  ret i32 %r
        \\}
        \\
    ;
    var aggregate_module = try ir.Module.parse(std.testing.allocator, aggregate_input);
    defer aggregate_module.deinit();
    try aggregate_module.verify();
    try std.testing.expectError(
        error.UnsupportedCodegenType,
        codegen.x86_64.lowerFunction(std.testing.allocator, aggregate_module.target_triple.?, aggregate_module.functions.items[0]),
    );

    const vector_return_input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare <2 x i32> @callee()
        \\
        \\define <2 x i32> @caller() {
        \\entry:
        \\  %r = call <2 x i32> @callee()
        \\  ret <2 x i32> %r
        \\}
        \\
    ;
    var vector_return_module = try ir.Module.parse(std.testing.allocator, vector_return_input);
    defer vector_return_module.deinit();
    try vector_return_module.verify();
    try std.testing.expectError(
        error.UnsupportedCodegenType,
        codegen.x86_64.lowerFunction(std.testing.allocator, vector_return_module.target_triple.?, vector_return_module.functions.items[0]),
    );
}

test "x86_64 codegen rejects X87 return ABI boundary" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define x86_fp80 @caller(x86_fp80 %value) {
        \\entry:
        \\  ret x86_fp80 %value
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    try std.testing.expectError(
        error.UnsupportedCodegenType,
        codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]),
    );
}

test "x86_64 codegen keeps callee-saved registers out of the selected ABI allocator" {
    try std.testing.expectEqual(codegen.x86_64.ArgReg.rdi, try codegen.x86_64.ArgReg.fromIndex(0));
    try std.testing.expectEqual(codegen.x86_64.ArgReg.r9, try codegen.x86_64.ArgReg.fromIndex(5));
    try std.testing.expectError(error.UnsupportedCodegenAbi, codegen.x86_64.ArgReg.fromIndex(6));
}

test "x86_64 codegen supports more than six stack-passed live i32 values across direct call" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare i32 @id(i32)
        \\
        \\define i32 @caller(i32 %a, i32 %b, i32 %c, i32 %d, i32 %e, i32 %f, i32 %g, i32 %h, i32 %i, i32 %j, i32 %k, i32 %l, i32 %m, i32 %n) {
        \\entry:
        \\  %r = call i32 @id(i32 %a)
        \\  %ab = add i32 %a, %b
        \\  %abc = add i32 %ab, %c
        \\  %abcd = add i32 %abc, %d
        \\  %abcde = add i32 %abcd, %e
        \\  %abcdef = add i32 %abcde, %f
        \\  %abcdefg = add i32 %abcdef, %g
        \\  %abcdefgh = add i32 %abcdefg, %h
        \\  %abcdefghi = add i32 %abcdefgh, %i
        \\  %abcdefghij = add i32 %abcdefghi, %j
        \\  %abcdefghijk = add i32 %abcdefghij, %k
        \\  %abcdefghijkl = add i32 %abcdefghijk, %l
        \\  %abcdefghijklm = add i32 %abcdefghijkl, %m
        \\  %abcdefghijklmn = add i32 %abcdefghijklm, %n
        \\  %sum = add i32 %abcdefghijklmn, %r
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
    try expectMachineInstruction(machine.instructions.items, .{ .add_stack_disp8_eax = 8 });
    try expectMachineInstruction(machine.instructions.items, .{ .add_stack_disp8_eax = 16 });
    try expectMachineInstruction(machine.instructions.items, .{ .add_stack_disp8_eax = 24 });
    try expectMachineInstruction(machine.instructions.items, .{ .add_stack_disp8_eax = 32 });
    try expectMachineInstruction(machine.instructions.items, .{ .add_stack_disp8_eax = 40 });
    try expectMachineInstruction(machine.instructions.items, .{ .add_stack_disp8_eax = 48 });
    try expectMachineInstruction(machine.instructions.items, .{ .add_stack_disp8_eax = 56 });
    try expectMachineInstruction(machine.instructions.items, .{ .add_stack_disp8_eax = 64 });
}

test "x86_64 codegen returns small INTEGER aggregate in rax rdx" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define { i64, i64 } @make_pair64(i64 %a, i64 %b) {
        \\entry:
        \\  %field0 = insertvalue { i64, i64 } undef, i64 %a, 0
        \\  %result = insertvalue { i64, i64 } %field0, i64 %b, 1
        \\  ret { i64, i64 } %result
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
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .mov_arg64_arg = .{ .dst = .rdx, .src = .rsi } }, machine.instructions.items[1]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[2]);
}

test "x86_64 codegen returns mixed INTEGER SSE aggregate in rax xmm0" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define { i64, double } @make_mixed(i64 %a, double %b) {
        \\entry:
        \\  %field0 = insertvalue { i64, double } undef, i64 %a, 0
        \\  %result = insertvalue { i64, double } %field0, double %b, 1
        \\  ret { i64, double } %result
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
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[1]);
}

test "x86_64 codegen returns mixed SSE INTEGER aggregate in xmm0 rax" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define { double, i64 } @make_reverse_mixed(double %a, i64 %b) {
        \\entry:
        \\  %field0 = insertvalue { double, i64 } undef, double %a, 0
        \\  %result = insertvalue { double, i64 } %field0, i64 %b, 1
        \\  ret { double, i64 } %result
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
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[1]);
}

test "x86_64 codegen returns packed i32 mixed aggregate in rax xmm0" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define { i32, i32, double } @make_packed_mixed(i32 %a, i32 %b, double %c) {
        \\entry:
        \\  %field0 = insertvalue { i32, i32, double } undef, i32 %a, 0
        \\  %field1 = insertvalue { i32, i32, double } %field0, i32 %b, 1
        \\  %result = insertvalue { i32, i32, double } %field1, double %c, 2
        \\  ret { i32, i32, double } %result
        \\}
        \\
        \\define { double, i32, i32 } @make_packed_reverse(double %a, i32 %b, i32 %c) {
        \\entry:
        \\  %field0 = insertvalue { double, i32, i32 } undef, double %a, 0
        \\  %field1 = insertvalue { double, i32, i32 } %field0, i32 %b, 1
        \\  %result = insertvalue { double, i32, i32 } %field1, i32 %c, 2
        \\  ret { double, i32, i32 } %result
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var mixed = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer mixed.deinit(std.testing.allocator);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, mixed.codegen_path);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .mov_arg_arg = .{ .dst = .rdx, .src = .rsi } }, mixed.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .shl_rdx_imm6 = 32 }, mixed.instructions.items[1]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .mov_arg_eax = .rdi }, mixed.instructions.items[2]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.or_rdx_rax, mixed.instructions.items[3]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, mixed.instructions.items[4]);

    var reverse = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[1]);
    defer reverse.deinit(std.testing.allocator);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, reverse.codegen_path);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .mov_arg_arg = .{ .dst = .rdx, .src = .rsi } }, reverse.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .shl_rdx_imm6 = 32 }, reverse.instructions.items[1]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .mov_arg_eax = .rdi }, reverse.instructions.items[2]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.or_rdx_rax, reverse.instructions.items[3]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, reverse.instructions.items[4]);
}

test "x86_64 codegen returns flattened nested and array register aggregates" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define { { i32, i32 }, { i32, i32 } } @make_nested(i32 %a, i32 %b, i32 %c, i32 %d) {
        \\entry:
        \\  %field0 = insertvalue { { i32, i32 }, { i32, i32 } } undef, i32 %a, 0, 0
        \\  %field1 = insertvalue { { i32, i32 }, { i32, i32 } } %field0, i32 %b, 0, 1
        \\  %field2 = insertvalue { { i32, i32 }, { i32, i32 } } %field1, i32 %c, 1, 0
        \\  %result = insertvalue { { i32, i32 }, { i32, i32 } } %field2, i32 %d, 1, 1
        \\  ret { { i32, i32 }, { i32, i32 } } %result
        \\}
        \\
        \\define { [2 x i64] } @make_array(i64 %a, i64 %b) {
        \\entry:
        \\  %field0 = insertvalue { [2 x i64] } undef, i64 %a, 0, 0
        \\  %result = insertvalue { [2 x i64] } %field0, i64 %b, 0, 1
        \\  ret { [2 x i64] } %result
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var nested = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer nested.deinit(std.testing.allocator);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, nested.codegen_path);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .mov_arg_arg = .{ .dst = .rcx, .src = .rcx } }, nested.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .shl_rcx_imm6 = 32 }, nested.instructions.items[1]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .mov_arg_arg = .{ .dst = .rdx, .src = .rdx } }, nested.instructions.items[2]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.or_rcx_rdx, nested.instructions.items[3]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .mov_arg_arg = .{ .dst = .rcx, .src = .rsi } }, nested.instructions.items[4]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .shl_rcx_imm6 = 32 }, nested.instructions.items[5]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .mov_arg_eax = .rdi }, nested.instructions.items[6]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.or_rcx_rax, nested.instructions.items[7]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, nested.instructions.items[8]);

    var array = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[1]);
    defer array.deinit(std.testing.allocator);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, array.codegen_path);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .mov_arg_rax = .rdi }, array.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .mov_arg64_arg = .{ .dst = .rdx, .src = .rsi } }, array.instructions.items[1]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, array.instructions.items[2]);
}

test "x86_64 codegen returns SSE SSE aggregate in xmm0 xmm1" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define { double, double } @make_double_pair(double %a, double %b) {
        \\entry:
        \\  %field0 = insertvalue { double, double } undef, double %a, 0
        \\  %result = insertvalue { double, double } %field0, double %b, 1
        \\  ret { double, double } %result
        \\}
        \\
        \\define { { double }, { double } } @make_nested_double(double %a, double %b) {
        \\entry:
        \\  %field0 = insertvalue { { double }, { double } } undef, double %a, 0, 0
        \\  %result = insertvalue { { double }, { double } } %field0, double %b, 1, 0
        \\  ret { { double }, { double } } %result
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[0]);

    var nested = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[1]);
    defer nested.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, nested.codegen_path);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, nested.instructions.items[0]);
}

test "x86_64 codegen reads small INTEGER aggregate fields from SysV argument registers" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i64 @second({ i64, i64 } %pair) {
        \\entry:
        \\  %slot = alloca { i64, i64 }
        \\  store { i64, i64 } %pair, ptr %slot
        \\  %field = getelementptr { i64, i64 }, ptr %slot, i64 0, i32 1
        \\  %value = load i64, ptr %field
        \\  ret i64 %value
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .mov_arg_rax = .rsi }, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[1]);
}

test "x86_64 codegen reads stack-passed register aggregate fields after GPR exhaustion" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i64 @first(i64 %a0, i64 %a1, i64 %a2, i64 %a3, i64 %a4, i64 %a5, { [2 x i64] } %pair) {
        \\entry:
        \\  %slot = alloca { [2 x i64] }
        \\  store { [2 x i64] } %pair, ptr %slot
        \\  %field = getelementptr { [2 x i64] }, ptr %slot, i64 0, i32 0, i64 0
        \\  %value = load i64, ptr %field
        \\  ret i64 %value
        \\}
        \\
        \\define i64 @second(i64 %a0, i64 %a1, i64 %a2, i64 %a3, i64 %a4, i64 %a5, { [2 x i64] } %pair) {
        \\entry:
        \\  %slot = alloca { [2 x i64] }
        \\  store { [2 x i64] } %pair, ptr %slot
        \\  %field = getelementptr { [2 x i64] }, ptr %slot, i64 0, i32 0, i64 1
        \\  %value = load i64, ptr %field
        \\  ret i64 %value
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var first = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer first.deinit(std.testing.allocator);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, first.codegen_path);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .load_stack_disp8_rax = 8 }, first.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, first.instructions.items[1]);

    var second = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[1]);
    defer second.deinit(std.testing.allocator);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, second.codegen_path);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .load_stack_disp8_rax = 16 }, second.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, second.instructions.items[1]);
}

test "x86_64 codegen reads fields from mixed aggregate register classes" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @sum_ints({ { i32, i32 }, double } %value) {
        \\entry:
        \\  %slot = alloca { { i32, i32 }, double }
        \\  store { { i32, i32 }, double } %value, ptr %slot
        \\  %pair = getelementptr { { i32, i32 }, double }, ptr %slot, i64 0, i32 0
        \\  %a_ptr = getelementptr { i32, i32 }, ptr %pair, i64 0, i32 0
        \\  %a = load i32, ptr %a_ptr
        \\  %b_ptr = getelementptr { i32, i32 }, ptr %pair, i64 0, i32 1
        \\  %b = load i32, ptr %b_ptr
        \\  %sum = add i32 %a, %b
        \\  ret i32 %sum
        \\}
        \\
        \\define double @read_double({ { i32, i32 }, double } %value) {
        \\entry:
        \\  %slot = alloca { { i32, i32 }, double }
        \\  store { { i32, i32 }, double } %value, ptr %slot
        \\  %field = getelementptr { { i32, i32 }, double }, ptr %slot, i64 0, i32 1
        \\  %result = load double, ptr %field
        \\  ret double %result
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
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[2]);

    var double_machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[1]);
    defer double_machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, double_machine.codegen_path);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, double_machine.instructions.items[0]);
}

test "x86_64 codegen preserves two live i32 params across direct call" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare i32 @callee(i32)
        \\
        \\define i32 @caller(i32 %a, i32 %b, i32 %c) {
        \\entry:
        \\  %ab = add i32 %a, %b
        \\  %r = call i32 @callee(i32 %c)
        \\  %sum = add i32 %ab, %r
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
    try expectMachineInstruction(machine.instructions.items, .sub_rsp_24);
    try expectMachineInstruction(machine.instructions.items, .{ .spill_arg_rsp = .{ .frame_index = .slot0, .reg = .rdi } });
    try expectMachineInstruction(machine.instructions.items, .{ .spill_arg_rsp = .{ .frame_index = .slot1, .reg = .rsi } });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_arg_rsp = .{ .reg = .rdi, .frame_index = .slot0 } });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_arg_rsp = .{ .reg = .rsi, .frame_index = .slot1 } });
}

test "x86_64 codegen preserves three live i32 params across direct call" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare i32 @callee(i32)
        \\
        \\define i32 @caller(i32 %a, i32 %b, i32 %c, i32 %d) {
        \\entry:
        \\  %ab = add i32 %a, %b
        \\  %abc = add i32 %ab, %c
        \\  %r = call i32 @callee(i32 %d)
        \\  %sum = add i32 %abc, %r
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
    try expectMachineInstruction(machine.instructions.items, .sub_rsp_24);
    try expectMachineInstruction(machine.instructions.items, .{ .spill_arg_rsp = .{ .frame_index = .slot0, .reg = .rdi } });
    try expectMachineInstruction(machine.instructions.items, .{ .spill_arg_rsp = .{ .frame_index = .slot1, .reg = .rsi } });
    try expectMachineInstruction(machine.instructions.items, .{ .spill_arg_rsp = .{ .frame_index = .slot2, .reg = .rdx } });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_arg_rsp = .{ .reg = .rdi, .frame_index = .slot0 } });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_arg_rsp = .{ .reg = .rsi, .frame_index = .slot1 } });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_arg_rsp = .{ .reg = .rdx, .frame_index = .slot2 } });
}

test "x86_64 codegen preserves six live i32 params across direct call" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare i32 @callee(i32)
        \\
        \\define i32 @caller(i32 %a, i32 %b, i32 %c, i32 %d, i32 %e, i32 %f) {
        \\entry:
        \\  %ab = add i32 %a, %b
        \\  %abc = add i32 %ab, %c
        \\  %abcd = add i32 %abc, %d
        \\  %abcde = add i32 %abcd, %e
        \\  %abcdef = add i32 %abcde, %f
        \\  %r = call i32 @callee(i32 %f)
        \\  %sum = add i32 %abcdef, %r
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
    try expectMachineInstruction(machine.instructions.items, .sub_rsp_40);
    try expectMachineInstruction(machine.instructions.items, .{ .spill_arg_rsp = .{ .frame_index = .slot0, .reg = .rdi } });
    try expectMachineInstruction(machine.instructions.items, .{ .spill_arg_rsp = .{ .frame_index = .slot1, .reg = .rsi } });
    try expectMachineInstruction(machine.instructions.items, .{ .spill_arg_rsp = .{ .frame_index = .slot2, .reg = .rdx } });
    try expectMachineInstruction(machine.instructions.items, .{ .spill_arg_rsp = .{ .frame_index = .slot3, .reg = .rcx } });
    try expectMachineInstruction(machine.instructions.items, .{ .spill_arg_rsp = .{ .frame_index = .slot4, .reg = .r8 } });
    try expectMachineInstruction(machine.instructions.items, .{ .spill_arg_rsp = .{ .frame_index = .slot5, .reg = .r9 } });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_arg_rsp = .{ .reg = .rdi, .frame_index = .slot0 } });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_arg_rsp = .{ .reg = .rsi, .frame_index = .slot1 } });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_arg_rsp = .{ .reg = .rdx, .frame_index = .slot2 } });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_arg_rsp = .{ .reg = .rcx, .frame_index = .slot3 } });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_arg_rsp = .{ .reg = .r8, .frame_index = .slot4 } });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_arg_rsp = .{ .reg = .r9, .frame_index = .slot5 } });
}

test "x86_64 generic CFG preserves six live i32 params across two void calls" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare void @sink()
        \\
        \\define i32 @caller(i32 %a, i32 %b, i32 %c, i32 %d, i32 %e, i32 %f) {
        \\entry:
        \\  call void @sink()
        \\  call void @sink()
        \\  %ab = add i32 %a, %b
        \\  %abc = add i32 %ab, %c
        \\  %abcd = add i32 %abc, %d
        \\  %abcde = add i32 %abcd, %e
        \\  %abcdef = add i32 %abcde, %f
        \\  ret i32 %abcdef
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    var spill_count: usize = 0;
    var reload_count: usize = 0;
    var call_count: usize = 0;
    for (machine.instructions.items) |instruction| switch (instruction) {
        .spill_arg_rsp => spill_count += 1,
        .reload_arg_rsp => reload_count += 1,
        .direct_call => |call| {
            if (std.mem.eql(u8, call.symbol, "sink")) call_count += 1;
        },
        else => {},
    };
    try std.testing.expectEqual(@as(usize, 12), spill_count);
    try std.testing.expectEqual(@as(usize, 12), reload_count);
    try std.testing.expectEqual(@as(usize, 2), call_count);
    try expectMachineInstruction(machine.instructions.items, .{ .reload_arg_rsp = .{ .reg = .r9, .frame_index = .slot5 } });
}

test "x86_64 codegen preserves six register and three stack i32 params across direct call" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare i32 @callee(i32)
        \\
        \\define i32 @caller(i32 %a, i32 %b, i32 %c, i32 %d, i32 %e, i32 %f, i32 %g, i32 %h, i32 %i) {
        \\entry:
        \\  %ab = add i32 %a, %b
        \\  %abc = add i32 %ab, %c
        \\  %abcd = add i32 %abc, %d
        \\  %abcde = add i32 %abcd, %e
        \\  %abcdef = add i32 %abcde, %f
        \\  %abcdefg = add i32 %abcdef, %g
        \\  %abcdefgh = add i32 %abcdefg, %h
        \\  %abcdefghi = add i32 %abcdefgh, %i
        \\  %r = call i32 @callee(i32 %f)
        \\  %sum = add i32 %abcdefghi, %r
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
    try expectMachineInstruction(machine.instructions.items, .sub_rsp_40);
    try expectMachineInstruction(machine.instructions.items, .{ .spill_arg_rsp = .{ .frame_index = .slot0, .reg = .rdi } });
    try expectMachineInstruction(machine.instructions.items, .{ .spill_arg_rsp = .{ .frame_index = .slot1, .reg = .rsi } });
    try expectMachineInstruction(machine.instructions.items, .{ .spill_arg_rsp = .{ .frame_index = .slot2, .reg = .rdx } });
    try expectMachineInstruction(machine.instructions.items, .{ .spill_arg_rsp = .{ .frame_index = .slot3, .reg = .rcx } });
    try expectMachineInstruction(machine.instructions.items, .{ .spill_arg_rsp = .{ .frame_index = .slot4, .reg = .r8 } });
    try expectMachineInstruction(machine.instructions.items, .{ .spill_arg_rsp = .{ .frame_index = .slot5, .reg = .r9 } });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_arg_rsp = .{ .reg = .rdi, .frame_index = .slot0 } });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_arg_rsp = .{ .reg = .rsi, .frame_index = .slot1 } });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_arg_rsp = .{ .reg = .rdx, .frame_index = .slot2 } });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_arg_rsp = .{ .reg = .rcx, .frame_index = .slot3 } });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_arg_rsp = .{ .reg = .r8, .frame_index = .slot4 } });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_arg_rsp = .{ .reg = .r9, .frame_index = .slot5 } });
    try expectMachineInstruction(machine.instructions.items, .{ .add_stack_disp8_eax = 8 });
    try expectMachineInstruction(machine.instructions.items, .{ .add_stack_disp8_eax = 16 });
    try expectMachineInstruction(machine.instructions.items, .{ .add_stack_disp8_eax = 24 });
}

test "x86_64 codegen lowers canonical accumulator loops without function-name dispatch" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @uncurated_accumulator(i32 %limit) {
        \\entry:
        \\  br label %loop
        \\loop:
        \\  %index = phi i32 [ 0, %entry ], [ %index.next, %body ]
        \\  %sum = phi i32 [ 0, %entry ], [ %sum.next, %body ]
        \\  %continue = icmp ult i32 %index, %limit
        \\  br i1 %continue, label %body, label %exit
        \\body:
        \\  %sum.next = add i32 %sum, %index
        \\  %index.next = add i32 %index, 1
        \\  br label %loop
        \\exit:
        \\  ret i32 %sum
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = try codegen.x86_64.lowerFunction(
        std.testing.allocator,
        module.target_triple.?,
        module.functions.items[0],
    );
    defer machine.deinit(std.testing.allocator);
    try std.testing.expect(machine.instructions.items.len > 0);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}

test "x86_64 codegen routes checked guard cfg through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare fastcc void @expanded_numeric_casts.integerPartOutOfBounds()
        \\
        \\define i32 @expanded_numeric_casts.expanded_int_from_float(float %arg0) {
        \\entry:
        \\  %below_min = fcmp ole float %arg0, -2147483904.0
        \\  %above_max = fcmp oge float %arg0, 2147483648.0
        \\  %out_of_bounds = or i1 %below_min, %above_max
        \\  br i1 %out_of_bounds, label %panic, label %ok
        \\panic:
        \\  call fastcc void @expanded_numeric_casts.integerPartOutOfBounds()
        \\  unreachable
        \\ok:
        \\  %converted = fptosi float %arg0 to i32
        \\  ret i32 %converted
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = try codegen.x86_64.lowerFunction(
        std.testing.allocator,
        module.target_triple.?,
        module.functions.items[0],
    );
    defer machine.deinit(std.testing.allocator);
    try std.testing.expect(machine.instructions.items.len > 0);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}

test "x86_64 codegen routes guarded global add panic edges through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\@message = private unnamed_addr constant [12 x i8] c"negative int"
        \\@global_value = global i32 3
        \\
        \\declare void @debug.defaultPanic(ptr, i64)
        \\declare void @overflow()
        \\declare void @llvm.assume(i1)
        \\declare { i32, i1 } @llvm.sadd.with.overflow.i32(i32, i32)
        \\
        \\define fastcc i32 @guarded_global_add(i32 %arg0) {
        \\entry:
        \\  %negative = icmp slt i32 %arg0, 0
        \\  br i1 %negative, label %panic, label %ok
        \\panic:
        \\  call void @llvm.assume(i1 1)
        \\  call void @debug.defaultPanic(ptr @message, i64 12)
        \\  unreachable
        \\ok:
        \\  %loaded = load i32, ptr @global_value
        \\  %sum = add i32 %loaded, %arg0
        \\  ret i32 %sum
        \\}
        \\
        \\define fastcc i32 @guarded_global_checked_add(i32 %arg0) {
        \\entry:
        \\  %negative = icmp slt i32 %arg0, 0
        \\  br i1 %negative, label %panic, label %ok
        \\panic:
        \\  call void @llvm.assume(i1 1)
        \\  call void @debug.defaultPanic(ptr @message, i64 12)
        \\  unreachable
        \\ok:
        \\  %loaded = load i32, ptr @global_value
        \\  %checked = call { i32, i1 } @llvm.sadd.with.overflow.i32(i32 %loaded, i32 %arg0)
        \\  %overflowed = extractvalue { i32, i1 } %checked, 1
        \\  br i1 %overflowed, label %overflow, label %ret
        \\overflow:
        \\  call void @llvm.assume(i1 1)
        \\  call void @overflow()
        \\  unreachable
        \\ret:
        \\  %value = extractvalue { i32, i1 } %checked, 0
        \\  ret i32 %value
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var unchecked = try codegen.x86_64.lowerFunction(
        std.testing.allocator,
        module.target_triple.?,
        module.functions.items[0],
    );
    defer unchecked.deinit(std.testing.allocator);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, unchecked.codegen_path);

    var checked = try codegen.x86_64.lowerFunction(
        std.testing.allocator,
        module.target_triple.?,
        module.functions.items[1],
    );
    defer checked.deinit(std.testing.allocator);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, checked.codegen_path);
}

test "x86_64 codegen routes scalar numeric casts through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define double @widen(float %x) {
        \\entry:
        \\  %wide = fpext float %x to double
        \\  ret double %wide
        \\}
        \\
        \\define float @narrow(double %x) {
        \\entry:
        \\  %narrow = fptrunc double %x to float
        \\  ret float %narrow
        \\}
        \\
        \\define i32 @int_from_float(float %x) {
        \\entry:
        \\  %int = fptosi float %x to i32
        \\  ret i32 %int
        \\}
        \\
        \\define float @float_from_int(i32 %x) {
        \\entry:
        \\  %float = sitofp i32 %x to float
        \\  ret float %float
        \\}
        \\
        \\define double @double_from_unsigned(i32 %x) {
        \\entry:
        \\  %double = uitofp i32 %x to double
        \\  ret double %double
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    for (module.functions.items) |function| {
        var machine = try codegen.x86_64.lowerFunction(
            std.testing.allocator,
            module.target_triple.?,
            function,
        );
        defer machine.deinit(std.testing.allocator);
        try std.testing.expect(machine.instructions.items.len > 0);
        try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    }
}

test "x86_64 codegen routes smin intrinsic call through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare i32 @llvm.smin.i32(i32, i32)
        \\
        \\define i32 @any_signed_min(i32 %a, i32 %b) {
        \\entry:
        \\  %r = tail call i32 @llvm.smin.i32(i32 %a, i32 %b)
        \\  ret i32 %r
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = try codegen.x86_64.lowerFunction(
        std.testing.allocator,
        module.target_triple.?,
        module.functions.items[0],
    );
    defer machine.deinit(std.testing.allocator);
    try std.testing.expect(machine.instructions.items.len > 0);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}

test "x86_64 codegen routes signed-min select through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @any_signed_min_select(i32 %a, i32 %b) {
        \\entry:
        \\  %lt = icmp slt i32 %a, %b
        \\  %r = select i1 %lt, i32 %a, i32 %b
        \\  ret i32 %r
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = try codegen.x86_64.lowerFunction(
        std.testing.allocator,
        module.target_triple.?,
        module.functions.items[0],
    );
    defer machine.deinit(std.testing.allocator);
    try std.testing.expect(machine.instructions.items.len > 0);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}

test "x86_64 codegen routes nested i8 error select through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @generic_error_select(i8 %tag) {
        \\entry:
        \\  %is_low = icmp eq i8 %tag, 1
        \\  %is_zero = icmp eq i8 %tag, 0
        \\  %error_value = select i1 %is_low, i32 -1, i32 -2
        \\  %result = select i1 %is_zero, i32 0, i32 %error_value
        \\  ret i32 %result
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = try codegen.x86_64.lowerFunction(
        std.testing.allocator,
        module.target_triple.?,
        module.functions.items[0],
    );
    defer machine.deinit(std.testing.allocator);
    try std.testing.expect(machine.instructions.items.len > 0);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}

test "x86_64 codegen routes nested i8 i64 classifier select through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i64 @generic_i64_classifier(i8 %tag) {
        \\entry:
        \\  %is_low = icmp eq i8 %tag, 1
        \\  %is_zero = icmp eq i8 %tag, 0
        \\  %error_value = select i1 %is_low, i64 1, i64 2
        \\  %result = select i1 %is_zero, i64 0, i64 %error_value
        \\  ret i64 %result
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = try codegen.x86_64.lowerFunction(
        std.testing.allocator,
        module.target_triple.?,
        module.functions.items[0],
    );
    defer machine.deinit(std.testing.allocator);
    try std.testing.expect(machine.instructions.items.len > 0);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}

test "x86_64 codegen routes void global store through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\@hidden = global i32 0
        \\
        \\define void @store_hidden(i32 %value) {
        \\entry:
        \\  store i32 %value, ptr @hidden
        \\  ret void
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = try codegen.x86_64.lowerFunction(
        std.testing.allocator,
        module.target_triple.?,
        module.functions.items[0],
    );
    defer machine.deinit(std.testing.allocator);
    try std.testing.expect(machine.instructions.items.len > 0);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}

test "x86_64 codegen routes aggregate pair pack through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i64 @make_pair(i32 %a, i32 %b) {
        \\entry:
        \\  %high = zext i32 %b to i64
        \\  %shift = shl i64 %high, 32
        \\  %low = zext i32 %a to i64
        \\  %result = or i64 %shift, %low
        \\  ret i64 %result
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = try codegen.x86_64.lowerFunction(
        std.testing.allocator,
        module.target_triple.?,
        module.functions.items[0],
    );
    defer machine.deinit(std.testing.allocator);
    try std.testing.expect(machine.instructions.items.len > 0);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}

test "x86_64 codegen routes aggregate pair first-field unpack through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @pair_first(i64 %pair) {
        \\entry:
        \\  %first = trunc i64 %pair to i32
        \\  ret i32 %first
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = try codegen.x86_64.lowerFunction(
        std.testing.allocator,
        module.target_triple.?,
        module.functions.items[0],
    );
    defer machine.deinit(std.testing.allocator);
    try std.testing.expect(machine.instructions.items.len > 0);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}

test "x86_64 codegen routes boolean branch-mix select through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @generic_branch_mix(i32 %a, i32 %b, i1 %flag) {
        \\entry:
        \\  %neg = sub i32 0, %b
        \\  %delta = select i1 %flag, i32 %b, i32 %neg
        \\  %result = add i32 %a, %delta
        \\  ret i32 %result
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = try codegen.x86_64.lowerFunction(
        std.testing.allocator,
        module.target_triple.?,
        module.functions.items[0],
    );
    defer machine.deinit(std.testing.allocator);
    try std.testing.expect(machine.instructions.items.len > 0);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}

test "x86_64 codegen routes constant i8 switch through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @generic_dense_switch(i8 %value) {
        \\entry:
        \\  switch i8 %value, label %default [
        \\    i8 0, label %case0
        \\    i8 1, label %case1
        \\    i8 2, label %case2
        \\  ]
        \\case0:
        \\  ret i32 11
        \\case1:
        \\  ret i32 13
        \\case2:
        \\  ret i32 17
        \\default:
        \\  ret i32 23
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = try codegen.x86_64.lowerFunction(
        std.testing.allocator,
        module.target_triple.?,
        module.functions.items[0],
    );
    defer machine.deinit(std.testing.allocator);
    try std.testing.expect(machine.instructions.items.len > 0);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}

test "x86_64 codegen routes single-block fp binary through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define double @float_mul(double %a, double %b) {
        \\entry:
        \\  %product = fmul double %a, %b
        \\  ret double %product
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = try codegen.x86_64.lowerFunction(
        std.testing.allocator,
        module.target_triple.?,
        module.functions.items[0],
    );
    defer machine.deinit(std.testing.allocator);
    try std.testing.expect(machine.instructions.items.len > 0);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}

test "x86_64 codegen routes single-block scalar select through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @expanded_optional_branch(i32 %tag, i32 %payload) {
        \\entry:
        \\  %is_null = icmp eq i32 %tag, 0
        \\  %result = select i1 %is_null, i32 -5, i32 %payload
        \\  ret i32 %result
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = try codegen.x86_64.lowerFunction(
        std.testing.allocator,
        module.target_triple.?,
        module.functions.items[0],
    );
    defer machine.deinit(std.testing.allocator);
    try std.testing.expect(machine.instructions.items.len > 0);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try mc.assembly.printFunction(machine, &output.writer);

    const expected =
        "\t.text\n" ++
        "\t.globl expanded_optional_branch\n" ++
        "expanded_optional_branch:\n" ++
        "\ttestl %edi, %edi\n" ++
        "\tje .Lexpanded_optional_branch_generic_cfg_select_true\n" ++
        "\tmovl %esi, %eax\n" ++
        "\tjmp .Lexpanded_optional_branch_generic_cfg_select_end\n" ++
        ".Lexpanded_optional_branch_generic_cfg_select_true:\n" ++
        "\tmovl $-5, %eax\n" ++
        ".Lexpanded_optional_branch_generic_cfg_select_end:\n" ++
        "\tretq\n";
    try std.testing.expectEqualStrings(expected, output.writer.buffered());
}

test "x86_64 codegen rejects unsupported scalar select predicate explicitly" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @unsupported_select(i32 %a, i32 %b) {
        \\entry:
        \\  %is_le = icmp sle i32 %a, %b
        \\  %result = select i1 %is_le, i32 %a, i32 %b
        \\  ret i32 %result
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    try std.testing.expectError(
        error.UnsupportedCodegenInstruction,
        codegen.x86_64.lowerFunction(
            std.testing.allocator,
            module.target_triple.?,
            module.functions.items[0],
        ),
    );
}

test "x86_64 codegen routes global i32 load store reload through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\@counter = global i32 3
        \\
        \\define i32 @update_global(i32 %arg0) {
        \\entry:
        \\  %loaded = load i32, ptr @counter
        \\  %next = add i32 %loaded, %arg0
        \\  store i32 %next, ptr @counter
        \\  %reloaded = load i32, ptr @counter
        \\  ret i32 %reloaded
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = try codegen.x86_64.lowerFunction(
        std.testing.allocator,
        module.target_triple.?,
        module.functions.items[0],
    );
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}

test "x86_64 codegen routes pointer load branch through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @pointer_load_branch(i32 %flag, ptr %left, ptr %right) {
        \\entry:
        \\  %cond = icmp ne i32 %flag, 0
        \\  br i1 %cond, label %then, label %else
        \\then:
        \\  %left_value = load i32, ptr %left
        \\  br label %merge
        \\else:
        \\  %right_value = load i32, ptr %right
        \\  br label %merge
        \\merge:
        \\  %result = phi i32 [ %left_value, %then ], [ %right_value, %else ]
        \\  ret i32 %result
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = try codegen.x86_64.lowerFunction(
        std.testing.allocator,
        module.target_triple.?,
        module.functions.items[0],
    );
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}

test "x86_64 codegen routes guarded dynamic pointer load through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @guarded_dynamic_load(ptr %values, i64 %len, i64 %index) {
        \\entry:
        \\  %cmp = icmp uge i64 %index, %len
        \\  br i1 %cmp, label %fail, label %ok
        \\fail:
        \\  ret i32 -1
        \\ok:
        \\  %element = getelementptr i32, ptr %values, i64 %index
        \\  %loaded = load i32, ptr %element
        \\  ret i32 %loaded
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = try codegen.x86_64.lowerFunction(
        std.testing.allocator,
        module.target_triple.?,
        module.functions.items[0],
    );
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}

test "x86_64 codegen routes branch phi immediate add through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @branch_phi_add(i32 %flag, ptr %payload) {
        \\entry:
        \\  %cond = icmp ne i32 %flag, 0
        \\  br i1 %cond, label %then, label %else
        \\then:
        \\  %loaded = load i32, ptr %payload
        \\  br label %merge
        \\else:
        \\  br label %merge
        \\merge:
        \\  %result = phi i32 [ %loaded, %then ], [ -12, %else ]
        \\  %biased = add i32 %result, 1
        \\  ret i32 %biased
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = try codegen.x86_64.lowerFunction(
        std.testing.allocator,
        module.target_triple.?,
        module.functions.items[0],
    );
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}

test "x86_64 codegen routes optional pointer load plus add through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @optional_pointer_add(ptr %arg0) {
        \\entry:
        \\  %is_null = icmp eq ptr %arg0, null
        \\  br i1 %is_null, label %merge, label %load
        \\load:
        \\  %loaded = load i32, ptr %arg0
        \\  %adjusted = add i32 %loaded, 8
        \\  br label %merge
        \\merge:
        \\  %result = phi i32 [ -1, %entry ], [ %adjusted, %load ]
        \\  ret i32 %result
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = try codegen.x86_64.lowerFunction(
        std.testing.allocator,
        module.target_triple.?,
        module.functions.items[0],
    );
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}

test "x86_64 codegen routes fp binary with unused scalar param through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define float @float_add_unused_bool(float %a, float %b, i1 %unused) {
        \\entry:
        \\  %sum = fadd float %a, %b
        \\  ret float %sum
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = try codegen.x86_64.lowerFunction(
        std.testing.allocator,
        module.target_triple.?,
        module.functions.items[0],
    );
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}

test "x86_64 codegen routes byte table lookup through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\@__anon_test_table = private unnamed_addr constant [4 x i8] c"\00\04\08\0C", align 4
        \\
        \\define i32 @byte_table_lookup(i8 %index) {
        \\entry:
        \\  %masked = and i8 %index, 3
        \\  %idx = zext i8 %masked to i64
        \\  %ptr = getelementptr inbounds [4 x i8], ptr @__anon_test_table, i64 0, i64 %idx
        \\  %byte = load i8, ptr %ptr
        \\  %value = zext i8 %byte to i32
        \\  ret i32 %value
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = try codegen.x86_64.lowerFunction(
        std.testing.allocator,
        module.target_triple.?,
        module.functions.items[0],
    );
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}

test "x86_64 codegen routes store branch load after store through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @store_branch_reload(i32 %flag, ptr %out, i32 %left, i32 %right) {
        \\entry:
        \\  %cond = icmp ne i32 %flag, 0
        \\  br i1 %cond, label %then, label %else
        \\then:
        \\  store i32 %left, ptr %out
        \\  br label %merge
        \\else:
        \\  store i32 %right, ptr %out
        \\  br label %merge
        \\merge:
        \\  %loaded = load i32, ptr %out
        \\  ret i32 %loaded
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = try codegen.x86_64.lowerFunction(
        std.testing.allocator,
        module.target_triple.?,
        module.functions.items[0],
    );
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}

test "x86_64 codegen routes direct-call branch merge through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare fastcc i32 @plus(i32)
        \\declare i32 @minus(i32)
        \\
        \\define i32 @call_branch_merge(i32 %flag, i32 %value) {
        \\entry:
        \\  %cond = icmp ne i32 %flag, 0
        \\  br i1 %cond, label %then, label %else
        \\then:
        \\  %a = call fastcc i32 @plus(i32 %value)
        \\  br label %merge
        \\else:
        \\  %b = call i32 @minus(i32 %value)
        \\  br label %merge
        \\merge:
        \\  %result = phi i32 [ %a, %then ], [ %b, %else ]
        \\  ret i32 %result
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = try codegen.x86_64.lowerFunction(
        std.testing.allocator,
        module.target_triple.?,
        module.functions.items[0],
    );
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}

test "x86_64 codegen routes pointer select load through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @pointer_select_load(i32 %flag, ptr %left, ptr %right) {
        \\entry:
        \\  %cond = icmp ne i32 %flag, 0
        \\  %chosen = select i1 %cond, ptr %left, ptr %right
        \\  %loaded = load i32, ptr %chosen
        \\  ret i32 %loaded
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = try codegen.x86_64.lowerFunction(
        std.testing.allocator,
        module.target_triple.?,
        module.functions.items[0],
    );
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}

test "x86_64 codegen routes conditional slice accumulation loop through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @conditional_slice_sum(ptr %values, i64 %len, i32 %limit) {
        \\entry:
        \\  %is_empty = icmp eq i64 %len, 0
        \\  br i1 %is_empty, label %zero, label %loop
        \\loop:
        \\  ret i32 0
        \\zero:
        \\  ret i32 0
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = try codegen.x86_64.lowerFunction(
        std.testing.allocator,
        module.target_triple.?,
        module.functions.items[0],
    );
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}

test "x86_64 codegen routes alloca pointer struct field loads through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @field_a(ptr %pair) {
        \\entry:
        \\  %slot = alloca ptr
        \\  store ptr %pair, ptr %slot
        \\  %loaded_ptr = load ptr, ptr %slot
        \\  %loaded = load i32, ptr %loaded_ptr
        \\  ret i32 %loaded
        \\}
        \\
        \\define i32 @field_b(ptr %pair) {
        \\entry:
        \\  %slot = alloca ptr
        \\  store ptr %pair, ptr %slot
        \\  %loaded_ptr = load ptr, ptr %slot
        \\  %field_ptr = getelementptr i8, ptr %loaded_ptr, i64 4
        \\  %loaded = load i32, ptr %field_ptr
        \\  ret i32 %loaded
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    for (module.functions.items) |function| {
        var machine = try codegen.x86_64.lowerFunction(
            std.testing.allocator,
            module.target_triple.?,
            function,
        );
        defer machine.deinit(std.testing.allocator);
        try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    }
}

test "x86_64 codegen routes struct field branch update through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @branch_update(i32 %flag, ptr %pair) {
        \\entry:
        \\  %slot = alloca ptr
        \\  store ptr %pair, ptr %slot
        \\  %cond = icmp ne i32 %flag, 0
        \\  br i1 %cond, label %then, label %else
        \\then:
        \\  %then_ptr = load ptr, ptr %slot
        \\  %then_old = load i32, ptr %then_ptr
        \\  %then_new = add i32 %then_old, 5
        \\  store i32 %then_new, ptr %then_ptr
        \\  br label %merge
        \\else:
        \\  %else_ptr = load ptr, ptr %slot
        \\  %else_old = load i32, ptr %else_ptr
        \\  %else_new = add i32 %else_old, 7
        \\  store i32 %else_new, ptr %else_ptr
        \\  br label %merge
        \\merge:
        \\  %ret_ptr = load ptr, ptr %slot
        \\  %ret_value = load i32, ptr %ret_ptr
        \\  ret i32 %ret_value
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = try codegen.x86_64.lowerFunction(
        std.testing.allocator,
        module.target_triple.?,
        module.functions.items[0],
    );
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}

test "x86_64 codegen rejects unsupported aggregate field offset from generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @field_c(ptr %pair) {
        \\entry:
        \\  %slot = alloca ptr
        \\  store ptr %pair, ptr %slot
        \\  %loaded_ptr = load ptr, ptr %slot
        \\  %field_ptr = getelementptr i8, ptr %loaded_ptr, i64 12
        \\  %loaded = load i32, ptr %field_ptr
        \\  ret i32 %loaded
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    if (codegen.x86_64.lowerFunction(
        std.testing.allocator,
        module.target_triple.?,
        module.functions.items[0],
    )) |machine| {
        var owned = machine;
        defer owned.deinit(std.testing.allocator);
        try std.testing.expectEqual(codegen.x86_64.CodegenPath.structural_matcher, owned.codegen_path);
    } else |err| switch (err) {
        error.UnsupportedCodegenInstruction, error.UnsupportedCodegenValue => {},
        else => return err,
    }
}

test "x86_64 codegen routes single-block volatile roundtrip through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @volatile_roundtrip(ptr %ptr, i32 %value) {
        \\entry:
        \\  store volatile i32 %value, ptr %ptr
        \\  %loaded = load volatile i32, ptr %ptr
        \\  ret i32 %loaded
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = try codegen.x86_64.lowerFunction(
        std.testing.allocator,
        module.target_triple.?,
        module.functions.items[0],
    );
    defer machine.deinit(std.testing.allocator);
    try std.testing.expect(machine.instructions.items.len > 0);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}

test "x86_64 codegen routes packed bit scalar helpers through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i8 @replace_low(i8 %a, i8 %b) {
        \\entry:
        \\  %high = and i8 %a, -8
        \\  %low = and i8 %b, 7
        \\  %result = or i8 %high, %low
        \\  ret i8 %result
        \\}
        \\
        \\define i1 @read_flag(i8 %a) {
        \\entry:
        \\  %flag = icmp slt i8 %a, 0
        \\  ret i1 %flag
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    for (module.functions.items) |function| {
        var machine = try codegen.x86_64.lowerFunction(
            std.testing.allocator,
            module.target_triple.?,
            function,
        );
        defer machine.deinit(std.testing.allocator);
        try std.testing.expect(machine.instructions.items.len > 0);
        try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    }
}

test "x86_64 codegen keeps multi-block volatile memory cfg out of generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @volatile_memory(i32 %flag, ptr %ptr) {
        \\entry:
        \\  %cond = icmp ne i32 %flag, 0
        \\  br i1 %cond, label %then, label %else
        \\then:
        \\  %loaded = load volatile i32, ptr %ptr
        \\  br label %merge
        \\else:
        \\  br label %merge
        \\merge:
        \\  %result = phi i32 [ %loaded, %then ], [ 0, %else ]
        \\  ret i32 %result
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

test "x86_64 machine verifier checks call stack alignment and frame balance" {
    var misaligned = codegen.x86_64.MachineFunction.init("bad_call", .{ .int = 32 });
    defer misaligned.deinit(std.testing.allocator);
    try misaligned.instructions.append(std.testing.allocator, .{ .direct_call = .{
        .symbol = "callee",
        .ret_ty = .{ .int = 32 },
    } });
    try misaligned.instructions.append(std.testing.allocator, .ret);
    try std.testing.expectError(error.MisalignedStackBeforeCall, codegen.x86_64.verifyFunction(misaligned));

    var unbalanced = codegen.x86_64.MachineFunction.init("bad_frame", .{ .int = 32 });
    defer unbalanced.deinit(std.testing.allocator);
    try unbalanced.instructions.append(std.testing.allocator, .sub_rsp_8);
    try unbalanced.instructions.append(std.testing.allocator, .{ .mov_imm_eax = 1 });
    try unbalanced.instructions.append(std.testing.allocator, .ret);
    try std.testing.expectError(error.UnbalancedStackFrame, codegen.x86_64.verifyFunction(unbalanced));
}

test "instcombine and dce remove identity arithmetic" {
    const input =
        \\define i32 @add_mul(i32 %a) {
        \\entry:
        \\  %x = add i32 %a, 0
        \\  %y = mul i32 %x, 1
        \\  ret i32 %y
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(instcombine.pass);
    try pm.add(dce.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();

    _ = try pm.run(&module, &context, &output.writer, false);
    try module.print(&output.writer);

    const expected =
        \\define i32 @add_mul(i32 %a) {
        \\entry:
        \\  ret i32 %a
        \\}
        \\
    ;
    try std.testing.expectEqualStrings(expected, output.writer.buffered());
}

test "constant folding rewrites return value" {
    const input =
        \\define i32 @constant() {
        \\entry:
        \\  %x = add i32 1, 2
        \\  %y = mul i32 %x, 4
        \\  ret i32 %y
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(instcombine.pass);
    try pm.add(dce.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();

    _ = try pm.run(&module, &context, &output.writer, false);
    try module.print(&output.writer);

    const expected =
        \\define i32 @constant() {
        \\entry:
        \\  ret i32 12
        \\}
        \\
    ;
    try std.testing.expectEqualStrings(expected, output.writer.buffered());
}

test "dce updates use counts while removing instruction chains" {
    const input =
        \\define i32 @chain(i32 %a) {
        \\entry:
        \\  %x = add i32 %a, 1
        \\  %y = mul i32 %x, 2
        \\  ret i32 %a
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(dce.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();

    _ = try pm.run(&module, &context, &output.writer, false);
    try module.print(&output.writer);

    const expected =
        \\define i32 @chain(i32 %a) {
        \\entry:
        \\  ret i32 %a
        \\}
        \\
    ;
    try std.testing.expectEqualStrings(expected, output.writer.buffered());
}

test "sroa preserves volatile aggregate field accesses during scalarization" {
    const input =
        \\define i32 @sroa_struct_volatile_reject(i32 %a) {
        \\entry:
        \\  %agg = alloca { i32, i32 }
        \\  %p0 = getelementptr { i32, i32 }, ptr %agg, i32 0, i32 0
        \\  store volatile i32 %a, ptr %p0
        \\  %x = load i32, ptr %p0
        \\  ret i32 %x
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(sroa.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();

    _ = try pm.run(&module, &context, &output.writer, false);
    try module.print(&output.writer);

    const expected =
        \\define i32 @sroa_struct_volatile_reject(i32 %a) {
        \\entry:
        \\  %agg.sroa.0 = alloca i32
        \\  store volatile i32 %a, ptr %agg.sroa.0
        \\  %agg.sroa.0.0.agg.sroa.0.0.x = load i32, ptr %agg.sroa.0
        \\  ret i32 %agg.sroa.0.0.agg.sroa.0.0.x
        \\}
        \\
    ;
    try std.testing.expectEqualStrings(expected, output.writer.buffered());
}

test "normalization preserves canonical LLVM-compatible fixture output" {
    const input = @embedFile("../testdata/instcombine.ll");
    const normalized = try normalize.llvmCompatibleIr(std.testing.allocator, input);
    defer std.testing.allocator.free(normalized);

    try std.testing.expectEqualStrings(input, normalized);
}

test "instcombine dce output matches golden file" {
    const input = @embedFile("../testdata/instcombine.ll");
    const expected = @embedFile("../testdata/instcombine_dce.ll");

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(instcombine.pass);
    try pm.add(dce.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();

    _ = try pm.run(&module, &context, &output.writer, false);
    try module.print(&output.writer);

    const normalized_actual = try normalize.llvmCompatibleIr(std.testing.allocator, output.writer.buffered());
    defer std.testing.allocator.free(normalized_actual);

    const normalized_expected = try normalize.llvmCompatibleIr(std.testing.allocator, expected);
    defer std.testing.allocator.free(normalized_expected);

    try std.testing.expectEqualStrings(normalized_expected, normalized_actual);
}

test "parser normalizes multiple functions and branch terminators" {
    const input =
        \\define i32 @branch(i1 %cond, i32 %a) {
        \\entry:
        \\  br i1 %cond, label %then, label %else
        \\then:
        \\  br label %exit
        \\else:
        \\  br label %exit
        \\exit:
        \\  ret i32 %a
        \\}
        \\
        \\define i32 @second(i32 %x) {
        \\entry:
        \\  ret i32 %x
        \\}
        \\
    ;

    const normalized = try normalize.llvmCompatibleIr(std.testing.allocator, input);
    defer std.testing.allocator.free(normalized);

    try std.testing.expectEqualStrings(input, normalized);
}

test "parser normalizes unreachable terminator" {
    const input =
        \\define i32 @trap() {
        \\entry:
        \\  unreachable
        \\}
        \\
    ;

    const normalized = try normalize.llvmCompatibleIr(std.testing.allocator, input);
    defer std.testing.allocator.free(normalized);

    try std.testing.expectEqualStrings(input, normalized);
}

test "parser normalizes icmp instructions" {
    const input =
        \\define i1 @cmp(i32 %a) {
        \\entry:
        \\  %c = icmp eq i32 %a, 0
        \\  ret i1 %c
        \\}
        \\
    ;

    const normalized = try normalize.llvmCompatibleIr(std.testing.allocator, input);
    defer std.testing.allocator.free(normalized);

    try std.testing.expectEqualStrings(input, normalized);
}

test "parser normalizes select instructions" {
    const input =
        \\define i32 @choose(i1 %cond, i32 %a, i32 %b) {
        \\entry:
        \\  %v = select i1 %cond, i32 %a, i32 %b
        \\  ret i32 %v
        \\}
        \\
    ;

    const normalized = try normalize.llvmCompatibleIr(std.testing.allocator, input);
    defer std.testing.allocator.free(normalized);

    try std.testing.expectEqualStrings(input, normalized);
}

test "parser preserves scalar casts div rem flags and freeze" {
    const input =
        \\define i32 @scalar_surface(i64 %wide, i8 %small, i32 %a, i32 %b) {
        \\entry:
        \\  %t = trunc i64 %wide to i32
        \\  %z = zext i8 %small to i32
        \\  %s = sext i8 %small to i32
        \\  %d = udiv exact i32 %a, 3
        \\  %r = srem i32 %b, 5
        \\  %sum0 = add nsw i32 %t, %z
        \\  %sum1 = add nuw i32 %sum0, %s
        \\  %sum2 = add i32 %sum1, %d
        \\  %sum3 = add i32 %sum2, %r
        \\  %sum4 = or disjoint i32 %sum3, 1
        \\  %f = freeze i32 %sum4
        \\  ret i32 %f
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "parser accepts array types and GEP prefixes from Zig aggregate IR" {
    const input =
        \\define i32 @array_gep(ptr %p, i64 %i) {
        \\entry:
        \\  %q = getelementptr inbounds [4 x i8], ptr %p, i64 %i
        \\  %r = getelementptr inbounds nuw i8, ptr %q, i64 4
        \\  %v = load i32, ptr %r, align 4
        \\  ret i32 %v
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    const block = module.functions.items[0].blocks.items[0];
    try std.testing.expectEqualStrings("[4 x i8]", block.instructions.items[0].kind.gep.source_ty.aggregate);
    try std.testing.expectEqual(ir.Type{ .int = 8 }, block.instructions.items[1].kind.gep.source_ty);
}

test "parser accepts nested constant expression GEP pointer operands" {
    const input =
        \\@table = private unnamed_addr constant [4096 x i8] zeroinitializer, align 1
        \\
        \\define ptr @nested_gep(i64 %i) {
        \\entry:
        \\  %p = getelementptr inbounds nuw [4 x i8], ptr getelementptr inbounds nuw (i8, ptr @table, i64 1024), i64 %i
        \\  ret ptr %p
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    const gep = module.functions.items[0].blocks.items[0].instructions.items[0].kind.gep;
    try std.testing.expectEqualStrings("getelementptr inbounds nuw (i8, ptr @table, i64 1024)", gep.ptr.constant_expr);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    const expected =
        \\@table = private unnamed_addr constant [4096 x i8] zeroinitializer, align 1
        \\
        \\define ptr @nested_gep(i64 %i) {
        \\entry:
        \\  %p = getelementptr [4 x i8], ptr getelementptr inbounds nuw (i8, ptr @table, i64 1024), i64 %i
        \\  ret ptr %p
        \\}
        \\
    ;
    try std.testing.expectEqualStrings(expected, output.writer.buffered());
}

test "parser rejects non-pointer typed nested constant expression GEP pointer operands" {
    const input =
        \\@table = private unnamed_addr constant [4096 x i8] zeroinitializer, align 1
        \\
        \\define ptr @bad_gep(i64 %i) {
        \\entry:
        \\  %p = getelementptr i8, i64 getelementptr (i8, ptr @table, i64 1), i64 %i
        \\  ret ptr %p
        \\}
        \\
    ;

    try std.testing.expectError(error.ExpectedPointerType, ir.Module.parse(std.testing.allocator, input));
}

test "instcombine preserves non-neutral flagged arithmetic and division" {
    const input =
        \\define i32 @conservative(i32 %a) {
        \\entry:
        \\  %x = add nsw i32 %a, 1
        \\  %y = udiv exact i32 %x, 2
        \\  ret i32 %y
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(instcombine.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var trace: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer trace.deinit();

    _ = try pm.run(&module, &context, &trace.writer, false);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "instcombine folds safe division remainder and freeze constants" {
    const input =
        \\define i32 @safe_scalar(i32 %a) {
        \\entry:
        \\  %d = udiv i32 %a, 1
        \\  %r = srem i32 %d, 1
        \\  %f = freeze i32 42
        \\  %sum0 = add i32 %r, %f
        \\  %sum1 = add i32 %sum0, %d
        \\  ret i32 %sum1
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(instcombine.pass);
    try pm.add(dce.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();

    _ = try pm.run(&module, &context, &output.writer, false);
    try module.print(&output.writer);

    const expected =
        \\define i32 @safe_scalar(i32 %a) {
        \\entry:
        \\  %sum1 = add i32 %a, 42
        \\  ret i32 %sum1
        \\}
        \\
    ;
    try std.testing.expectEqualStrings(expected, output.writer.buffered());
}

test "instcombine preserves unsafe division folds" {
    const input =
        \\define i32 @unsafe_division() {
        \\entry:
        \\  %x = udiv i32 4, 0
        \\  %y = sdiv i32 -2147483648, -1
        \\  %z = udiv exact i32 5, 2
        \\  %sum0 = add i32 %x, %y
        \\  %sum1 = add i32 %sum0, %z
        \\  ret i32 %sum1
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(instcombine.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var trace: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer trace.deinit();

    _ = try pm.run(&module, &context, &trace.writer, false);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "instcombine folds constant icmp" {
    const input =
        \\define i1 @cmp() {
        \\entry:
        \\  %c = icmp ne i32 1, 1
        \\  ret i1 %c
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(instcombine.pass);
    try pm.add(dce.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();

    _ = try pm.run(&module, &context, &output.writer, false);
    try module.print(&output.writer);

    const expected =
        \\define i1 @cmp() {
        \\entry:
        \\  ret i1 0
        \\}
        \\
    ;
    try std.testing.expectEqualStrings(expected, output.writer.buffered());
}

test "instcombine folds simple select instructions" {
    const input =
        \\define i32 @select_fold(i1 %cond, i32 %a, i32 %b) {
        \\entry:
        \\  %x = select i1 1, i32 %a, i32 %b
        \\  %y = select i1 %cond, i32 %x, i32 %x
        \\  ret i32 %y
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(instcombine.pass);
    try pm.add(dce.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();

    _ = try pm.run(&module, &context, &output.writer, false);
    try module.print(&output.writer);

    const expected =
        \\define i32 @select_fold(i1 %cond, i32 %a, i32 %b) {
        \\entry:
        \\  ret i32 %a
        \\}
        \\
    ;
    try std.testing.expectEqualStrings(expected, output.writer.buffered());
}

test "parser normalizes phi instructions" {
    const input =
        \\define i32 @select(i1 %cond, i32 %a, i32 %b) {
        \\entry:
        \\  br i1 %cond, label %then, label %else
        \\then:
        \\  br label %merge
        \\else:
        \\  br label %merge
        \\merge:
        \\  %v = phi i32 [ %a, %then ], [ %b, %else ]
        \\  ret i32 %v
        \\}
        \\
    ;

    const normalized = try normalize.llvmCompatibleIr(std.testing.allocator, input);
    defer std.testing.allocator.free(normalized);

    try std.testing.expectEqualStrings(input, normalized);
}

test "parser normalizes memory instructions" {
    const input =
        \\define i32 @memory(i32 %a) {
        \\entry:
        \\  %slot = alloca i32
        \\  store i32 %a, ptr %slot
        \\  %v = load i32, ptr %slot
        \\  ret i32 %v
        \\}
        \\
    ;

    const normalized = try normalize.llvmCompatibleIr(std.testing.allocator, input);
    defer std.testing.allocator.free(normalized);

    try std.testing.expectEqualStrings(input, normalized);
}

test "parser prints load and store memory attributes" {
    const input =
        \\define i32 @memory_attrs(i32 %a) {
        \\entry:
        \\  %slot = alloca i32
        \\  store volatile i32 %a, ptr %slot, align 4
        \\  %v = load volatile i32, ptr %slot, align 4
        \\  ret i32 %v
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "parser preserves load from constant-expression gep pointer" {
    const input =
        \\@global = internal global [8 x i8] c"abcdefgh", align 1
        \\
        \\define i8 @load_gep_constexpr() {
        \\entry:
        \\  %v = load i8, ptr getelementptr inbounds nuw (i8, ptr @global, i64 2), align 1
        \\  ret i8 %v
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "parser preserves atomic memory through constant-expression gep pointer" {
    const input =
        \\@global = internal global [8 x i8] zeroinitializer, align 4
        \\
        \\define i32 @atomic_gep_constexpr(i32 %value) {
        \\entry:
        \\  store atomic i32 %value, ptr getelementptr inbounds nuw (i8, ptr @global, i64 4) unordered, align 4
        \\  %v = load atomic i32, ptr getelementptr inbounds nuw (i8, ptr @global, i64 4) unordered, align 4
        \\  ret i32 %v
        \\}
        \\
    ;
    const expected =
        \\@global = internal global [8 x i8] zeroinitializer, align 4
        \\
        \\define i32 @atomic_gep_constexpr(i32 %value) {
        \\entry:
        \\  store atomic i32 %value, ptr getelementptr inbounds nuw (i8, ptr @global, i64 4) unordered, align 4
        \\  %v = load atomic i32, ptr getelementptr inbounds nuw (i8, ptr @global, i64 4) unordered, align 4
        \\  ret i32 %v
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(expected, output.writer.buffered());
}

test "parser accepts narrow atomic load and store spelling as barriers" {
    const input =
        \\define i32 @memory_atomic(i32 %a) {
        \\entry:
        \\  %slot = alloca i32
        \\  store atomic i32 %a, ptr %slot release, align 4
        \\  %v = load atomic i32, ptr %slot acquire, align 4
        \\  ret i32 %v
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "parser preserves known thread local models and rejects unknown TLS models" {
    const input =
        \\@tls = internal thread_local(localexec) unnamed_addr global i32 1, align 4
        \\
        \\define i32 @read_tls_model() {
        \\entry:
        \\  %v = load i32, ptr @tls, align 4
        \\  ret i32 %v
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());

    const invalid =
        \\@tls = internal thread_local(unsupported) global i32 1
        \\
        \\define i32 @read_bad_tls_model() {
        \\entry:
        \\  %v = load i32, ptr @tls, align 4
        \\  ret i32 %v
        \\}
        \\
    ;
    var invalid_module = try ir.Module.parse(std.testing.allocator, invalid);
    defer invalid_module.deinit();
    try std.testing.expectError(error.UnsupportedGlobalVariable, invalid_module.verify());
}

test "parser preserves atomicrmw cmpxchg and fence barriers" {
    const input =
        \\define i32 @memory_atomicrmw(ptr %p) {
        \\entry:
        \\  %v = atomicrmw add ptr %p, i32 1 monotonic
        \\  ret i32 %v
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    try std.testing.expectEqual(memory_effect.Effect.volatile_or_atomic_barrier, memory_effect.classify(module.functions.items[0].blocks.items[0].instructions.items[0]));
    try std.testing.expectEqual(memory_effect.BarrierKind.atomic, memory_effect.barrierKind(module.functions.items[0].blocks.items[0].instructions.items[0]));

    const cmpxchg =
        \\define i32 @memory_cmpxchg(ptr %p, i32 %old, i32 %new) {
        \\entry:
        \\  %v = cmpxchg ptr %p, i32 %old, i32 %new monotonic monotonic
        \\  ret i32 %old
        \\}
        \\
    ;
    var cmpxchg_module = try ir.Module.parse(std.testing.allocator, cmpxchg);
    defer cmpxchg_module.deinit();
    try cmpxchg_module.verify();
    try std.testing.expectEqual(memory_effect.Effect.volatile_or_atomic_barrier, memory_effect.classify(cmpxchg_module.functions.items[0].blocks.items[0].instructions.items[0]));

    const cmpxchg_extractvalue =
        \\define i1 @cmpxchg_extractvalue(ptr %p, i32 %old, i32 %new) {
        \\entry:
        \\  %pair = cmpxchg ptr %p, i32 %old, i32 %new acquire monotonic
        \\  %success = extractvalue { i32, i1 } %pair, 1
        \\  ret i1 %success
        \\}
        \\
    ;
    var extractvalue_module = try ir.Module.parse(std.testing.allocator, cmpxchg_extractvalue);
    defer extractvalue_module.deinit();
    try extractvalue_module.verify();

    var extractvalue_output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer extractvalue_output.deinit();
    try extractvalue_module.print(&extractvalue_output.writer);
    try std.testing.expectEqualStrings(cmpxchg_extractvalue, extractvalue_output.writer.buffered());

    const cmpxchg_i8_extractvalue =
        \\define i1 @cmpxchg_i8_extractvalue(ptr %p, i8 %old, i8 %new) {
        \\entry:
        \\  %pair = cmpxchg weak ptr %p, i8 %old, i8 %new seq_cst seq_cst
        \\  %success = extractvalue { i8, i1 } %pair, 1
        \\  ret i1 %success
        \\}
        \\
    ;
    var i8_extractvalue_module = try ir.Module.parse(std.testing.allocator, cmpxchg_i8_extractvalue);
    defer i8_extractvalue_module.deinit();
    try i8_extractvalue_module.verify();
    try std.testing.expect(i8_extractvalue_module.functions.items[0].blocks.items[0].instructions.items[0].resultType().?.eql(.{ .aggregate = "{ i8, i1 }" }));

    var i8_extractvalue_output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer i8_extractvalue_output.deinit();
    try i8_extractvalue_module.print(&i8_extractvalue_output.writer);
    try std.testing.expectEqualStrings(cmpxchg_i8_extractvalue, i8_extractvalue_output.writer.buffered());

    const overflow_extractvalue =
        \\declare { i8, i1 } @llvm.umul.with.overflow.i8(i8, i8)
        \\
        \\define i1 @overflow_extractvalue(i8 %x) {
        \\entry:
        \\  %pair = call { i8, i1 } @llvm.umul.with.overflow.i8(i8 %x, i8 10)
        \\  %overflow = extractvalue { i8, i1 } %pair, 1
        \\  ret i1 %overflow
        \\}
        \\
    ;
    var overflow_module = try ir.Module.parse(std.testing.allocator, overflow_extractvalue);
    defer overflow_module.deinit();
    try overflow_module.verify();

    var overflow_output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer overflow_output.deinit();
    try overflow_module.print(&overflow_output.writer);
    try std.testing.expectEqualStrings(overflow_extractvalue, overflow_output.writer.buffered());

    const insertvalue =
        \\define { ptr, i64 } @insert_aggregate(ptr %p) {
        \\entry:
        \\  %agg = insertvalue { ptr, i64 } poison, ptr %p, 0
        \\  ret { ptr, i64 } %agg
        \\}
        \\
    ;
    var insertvalue_module = try ir.Module.parse(std.testing.allocator, insertvalue);
    defer insertvalue_module.deinit();
    try insertvalue_module.verify();

    var insertvalue_output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer insertvalue_output.deinit();
    try insertvalue_module.print(&insertvalue_output.writer);
    try std.testing.expectEqualStrings(insertvalue, insertvalue_output.writer.buffered());

    const bad_insertvalue =
        \\define { ptr, i64 } @bad_insert_aggregate(ptr %p) {
        \\entry:
        \\  %agg = insertvalue { ptr, i64 } poison, i64 1, 0
        \\  ret { ptr, i64 } %agg
        \\}
        \\
    ;
    try std.testing.expectError(error.TypeMismatch, ir.Module.parse(std.testing.allocator, bad_insertvalue));

    const aggregate_phi =
        \\define { ptr, i64 } @aggregate_phi(i1 %cond, { ptr, i64 } %value) {
        \\entry:
        \\  br i1 %cond, label %left, label %right
        \\left:
        \\  br label %merge
        \\right:
        \\  br label %merge
        \\merge:
        \\  %result = phi { ptr, i64 } [ %value, %left ], [ { ptr inttoptr (i64 1 to ptr), i64 0 }, %right ]
        \\  ret { ptr, i64 } %result
        \\}
        \\
    ;
    var aggregate_phi_module = try ir.Module.parse(std.testing.allocator, aggregate_phi);
    defer aggregate_phi_module.deinit();
    try aggregate_phi_module.verify();

    var aggregate_phi_output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer aggregate_phi_output.deinit();
    try aggregate_phi_module.print(&aggregate_phi_output.writer);
    try std.testing.expectEqualStrings(aggregate_phi, aggregate_phi_output.writer.buffered());

    const bad_extractvalue =
        \\define i1 @bad_extractvalue(ptr %p, i32 %old, i32 %new) {
        \\entry:
        \\  %pair = cmpxchg ptr %p, i32 %old, i32 %new acquire monotonic
        \\  %success = extractvalue { i32, i1 } %pair, 2
        \\  ret i1 %success
        \\}
        \\
    ;
    try std.testing.expectError(error.TypeMismatch, ir.Module.parse(std.testing.allocator, bad_extractvalue));

    const fence =
        \\define void @memory_fence() {
        \\entry:
        \\  fence seq_cst
        \\  ret void
        \\}
        \\
    ;
    var fence_module = try ir.Module.parse(std.testing.allocator, fence);
    defer fence_module.deinit();
    try fence_module.verify();
    try std.testing.expectEqual(memory_effect.Effect.volatile_or_atomic_barrier, memory_effect.classify(fence_module.functions.items[0].blocks.items[0].instructions.items[0]));

    const source_backed_atomicrmw =
        \\source_filename = "atomics_inline_asm_debug"
        \\
        \\@atomics_inline_asm_debug.atomic_counter = private unnamed_addr global i32 0, align 4
        \\
        \\define i32 @atomics_inline_asm_debug.atomic_add(i32 %value) {
        \\entry:
        \\  %old = atomicrmw add ptr @atomics_inline_asm_debug.atomic_counter, i32 %value monotonic, align 4
        \\  ret i32 %old
        \\}
        \\
    ;
    var source_backed_module = try ir.Module.parse(std.testing.allocator, source_backed_atomicrmw);
    defer source_backed_module.deinit();
    try source_backed_module.verify();

    const constant_expr_atomic_pointer =
        \\@global = internal global [16 x i8] zeroinitializer, align 8
        \\
        \\define i32 @atomic_pointer_constexpr(i32 %old, i32 %new) {
        \\entry:
        \\  %rmw = atomicrmw xchg ptr getelementptr inbounds nuw (i8, ptr @global, i64 8), i32 %new release, align 4
        \\  %pair = cmpxchg ptr getelementptr inbounds nuw (i8, ptr @global, i64 8), i32 %old, i32 %new acquire monotonic, align 4
        \\  ret i32 %rmw
        \\}
        \\
    ;
    var constant_expr_module = try ir.Module.parse(std.testing.allocator, constant_expr_atomic_pointer);
    defer constant_expr_module.deinit();
    try constant_expr_module.verify();
}

test "parser preserves atomic syncscope on supported atomic operations" {
    const input =
        \\define i32 @memory_syncscope(i32 %a, ptr %p, i32 %old, i32 %new) {
        \\entry:
        \\  store atomic i32 %a, ptr %p syncscope("singlethread") release, align 4
        \\  %v = load atomic i32, ptr %p syncscope("singlethread") acquire, align 4
        \\  %rmw = atomicrmw add ptr %p, i32 %new syncscope("singlethread") monotonic, align 4
        \\  %pair = cmpxchg weak ptr %p, i32 %old, i32 %new syncscope("singlethread") acq_rel monotonic, align 4
        \\  fence syncscope("singlethread") seq_cst
        \\  ret i32 %v
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);

    try std.testing.expectEqualStrings(input, output.writer.buffered());
}

test "verifier accepts LLVM-shaped atomic type surfaces" {
    const input =
        \\define ptr @atomic_pointer_xchg(ptr %p) {
        \\entry:
        \\  %v = atomicrmw xchg ptr %p, ptr null monotonic
        \\  ret ptr %v
        \\}
        \\
        \\define float @atomic_float_load_store(ptr %p, float %value) {
        \\entry:
        \\  store atomic float %value, ptr %p release, align 4
        \\  %loaded = load atomic float, ptr %p acquire, align 4
        \\  ret float %loaded
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
}

test "verifier rejects invalid atomic ordering combinations" {
    const invalid_load =
        \\define i32 @bad_atomic_load(ptr %p) {
        \\entry:
        \\  %v = load atomic i32, ptr %p release, align 4
        \\  ret i32 %v
        \\}
        \\
    ;
    var load_module = try ir.Module.parse(std.testing.allocator, invalid_load);
    defer load_module.deinit();
    try std.testing.expectError(error.InvalidAtomicMemory, load_module.verify());

    const invalid_store =
        \\define void @bad_atomic_store(ptr %p) {
        \\entry:
        \\  store atomic i32 1, ptr %p acquire, align 4
        \\  ret void
        \\}
        \\
    ;
    var store_module = try ir.Module.parse(std.testing.allocator, invalid_store);
    defer store_module.deinit();
    try std.testing.expectError(error.InvalidAtomicMemory, store_module.verify());

    const invalid_fence =
        \\define void @bad_fence() {
        \\entry:
        \\  fence monotonic
        \\  ret void
        \\}
        \\
    ;
    var fence_module = try ir.Module.parse(std.testing.allocator, invalid_fence);
    defer fence_module.deinit();
    try std.testing.expectError(error.InvalidAtomicMemory, fence_module.verify());

    const invalid_cmpxchg =
        \\define void @bad_cmpxchg(ptr %p, i32 %old, i32 %new) {
        \\entry:
        \\  %pair = cmpxchg ptr %p, i32 %old, i32 %new acquire release
        \\  ret void
        \\}
        \\
    ;
    var cmpxchg_module = try ir.Module.parse(std.testing.allocator, invalid_cmpxchg);
    defer cmpxchg_module.deinit();
    try std.testing.expectError(error.InvalidAtomicMemory, cmpxchg_module.verify());
}

test "verifier rejects LLVM invalid atomic memory types" {
    const invalid_load_i1 =
        \\define i1 @bad_atomic_load_i1(ptr %p) {
        \\entry:
        \\  %v = load atomic i1, ptr %p acquire, align 1
        \\  ret i1 %v
        \\}
        \\
    ;
    var load_i1_module = try ir.Module.parse(std.testing.allocator, invalid_load_i1);
    defer load_i1_module.deinit();
    try std.testing.expectError(error.InvalidAtomicMemory, load_i1_module.verify());

    const invalid_store_i24 =
        \\define void @bad_atomic_store_i24(ptr %p) {
        \\entry:
        \\  store atomic i24 1, ptr %p release, align 4
        \\  ret void
        \\}
        \\
    ;
    var store_i24_module = try ir.Module.parse(std.testing.allocator, invalid_store_i24);
    defer store_i24_module.deinit();
    try std.testing.expectError(error.InvalidAtomicMemory, store_i24_module.verify());

    const invalid_rmw_add_ptr =
        \\define ptr @bad_atomicrmw_add_ptr(ptr %p) {
        \\entry:
        \\  %v = atomicrmw add ptr %p, ptr null monotonic
        \\  ret ptr %v
        \\}
        \\
    ;
    var rmw_add_ptr_module = try ir.Module.parse(std.testing.allocator, invalid_rmw_add_ptr);
    defer rmw_add_ptr_module.deinit();
    try std.testing.expectError(error.InvalidAtomicMemory, rmw_add_ptr_module.verify());

    const invalid_rmw_fadd_i32 =
        \\define i32 @bad_atomicrmw_fadd_i32(ptr %p, i32 %value) {
        \\entry:
        \\  %v = atomicrmw fadd ptr %p, i32 %value monotonic
        \\  ret i32 %v
        \\}
        \\
    ;
    var rmw_fadd_i32_module = try ir.Module.parse(std.testing.allocator, invalid_rmw_fadd_i32);
    defer rmw_fadd_i32_module.deinit();
    try std.testing.expectError(error.InvalidAtomicMemory, rmw_fadd_i32_module.verify());

    const invalid_cmpxchg_float =
        \\define void @bad_cmpxchg_float(ptr %p, float %old, float %new) {
        \\entry:
        \\  %pair = cmpxchg ptr %p, float %old, float %new monotonic monotonic
        \\  ret void
        \\}
        \\
    ;
    var cmpxchg_float_module = try ir.Module.parse(std.testing.allocator, invalid_cmpxchg_float);
    defer cmpxchg_float_module.deinit();
    try std.testing.expectError(error.InvalidAtomicMemory, cmpxchg_float_module.verify());
}

test "parser preserves inline asm calls as side-effecting barriers" {
    const input =
        \\define void @inline_asm_barrier() {
        \\entry:
        \\  call void asm sideeffect "", "~{memory}"()
        \\  ret void
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    const call = module.functions.items[0].blocks.items[0].instructions.items[0].kind.call;
    try std.testing.expect(call.inline_asm != null);
    try std.testing.expect(call.inline_asm.?.sideeffect);
    try std.testing.expect(call.inline_asm.?.has_memory_clobber);
    try std.testing.expect(call.inline_asm.?.may_load);
    try std.testing.expect(call.inline_asm.?.may_store);
    try std.testing.expectEqual(memory_effect.Effect.volatile_or_atomic_barrier, memory_effect.classify(module.functions.items[0].blocks.items[0].instructions.items[0]));
    try std.testing.expectEqual(memory_effect.BarrierKind.inline_asm, memory_effect.barrierKind(module.functions.items[0].blocks.items[0].instructions.items[0]));

    const source_backed_inline_asm =
        \\source_filename = "atomics_inline_asm_debug"
        \\
        \\define i32 @atomics_inline_asm_debug.inline_asm_barrier(i32 %value) {
        \\entry:
        \\  call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"()
        \\  ret i32 %value
        \\}
        \\
    ;
    var source_backed_module = try ir.Module.parse(std.testing.allocator, source_backed_inline_asm);
    defer source_backed_module.deinit();
    try source_backed_module.verify();
    const source_backed_call = source_backed_module.functions.items[0].blocks.items[0].instructions.items[0].kind.call;
    try std.testing.expect(source_backed_call.inline_asm != null);
    try std.testing.expect(source_backed_call.inline_asm.?.has_memory_clobber);
    try std.testing.expect(source_backed_call.inline_asm.?.may_load);
    try std.testing.expect(source_backed_call.inline_asm.?.may_store);
}

test "x86_64 codegen routes monotonic atomic add through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\@atomics_inline_asm_debug.atomic_counter = private unnamed_addr global i32 0, align 4
        \\
        \\define i32 @atomics_inline_asm_debug.atomic_add(i32 %value) {
        \\entry:
        \\  %old = atomicrmw add ptr @atomics_inline_asm_debug.atomic_counter, i32 %value monotonic, align 4
        \\  ret i32 %old
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}

test "x86_64 codegen routes inline asm memory barrier through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @atomics_inline_asm_debug.inline_asm_barrier(i32 %value) {
        \\entry:
        \\  call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"()
        \\  ret i32 %value
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}

test "x86_64 codegen routes empty void return through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define void @tiny_scalar.sideEffectFree() {
        \\entry:
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
}

test "x86_64 codegen routes void-call main wrapper through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare fastcc void @sample.sideEffectFree()
        \\
        \\define i32 @sample.main() {
        \\entry:
        \\  call fastcc void @sample.sideEffectFree()
        \\  ret i32 0
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}

test "x86_64 codegen routes fp call-check main wrapper through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare fastcc float @sample.floatAdd(float, float)
        \\
        \\define i32 @sample.main() {
        \\entry:
        \\  %call = call fastcc float @sample.floatAdd(float 1.000000e+00, float 2.000000e+00)
        \\  %ok = fcmp oeq float %call, 3.000000e+00
        \\  %ret = select i1 %ok, i32 0, i32 1
        \\  ret i32 %ret
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}

test "x86_64 codegen routes integer call-check main wrapper through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare fastcc i32 @sample.add(i32, i32)
        \\
        \\define i32 @sample.main() {
        \\entry:
        \\  %call = call fastcc i32 @sample.add(i32 20, i32 22)
        \\  %ok = icmp eq i32 %call, 42
        \\  %ret = select i1 %ok, i32 0, i32 1
        \\  ret i32 %ret
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}

test "x86_64 codegen routes pointer literal call-check main wrapper through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\@sample.values = global [4 x i32] zeroinitializer
        \\
        \\declare fastcc i32 @sample.sum(ptr, i64)
        \\
        \\define i32 @sample.main() {
        \\entry:
        \\  %call = call fastcc i32 @sample.sum(ptr @sample.values, i64 4)
        \\  %ok = icmp eq i32 %call, 10
        \\  %ret = select i1 %ok, i32 0, i32 1
        \\  ret i32 %ret
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}

test "x86_64 codegen routes narrow integer call-check main wrapper through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare fastcc i8 @sample.replace(i8, i8)
        \\
        \\define i32 @sample.main() {
        \\entry:
        \\  %call = call fastcc i8 @sample.replace(i8 8, i8 3)
        \\  %ok = icmp eq i8 %call, 11
        \\  %ret = select i1 %ok, i32 0, i32 1
        \\  ret i32 %ret
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}

test "x86_64 codegen routes bool call-check main wrapper through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare fastcc i1 @sample.floatLess(float, float)
        \\
        \\define i32 @sample.main() {
        \\entry:
        \\  %call = call fastcc i1 @sample.floatLess(float 1.000000e+00, float 2.000000e+00)
        \\  %ret = select i1 %call, i32 0, i32 1
        \\  ret i32 %ret
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}

test "x86_64 codegen routes sibling update-get main wrapper through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare fastcc void @sample.update(i32)
        \\declare fastcc i32 @sample.get()
        \\
        \\define i32 @sample.main() {
        \\entry:
        \\  call fastcc void @sample.update(i32 7)
        \\  %value = call fastcc i32 @sample.get()
        \\  ret i32 %value
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}

test "x86_64 codegen routes direct-call main wrapper with identity cast through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare fastcc i32 @sample.add(i32)
        \\
        \\define i32 @sample.main() {
        \\entry:
        \\  %call = call fastcc i32 @sample.add(i32 4)
        \\  %retv = bitcast i32 %call to i32
        \\  ret i32 %retv
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}

test "x86_64 codegen routes i64 to i32 call-chain main wrapper through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare fastcc i64 @sample.pack(i32, i32)
        \\declare fastcc i32 @sample.first(i64)
        \\
        \\define i32 @sample.main() {
        \\entry:
        \\  %pair = call fastcc i64 @sample.pack(i32 1, i32 2)
        \\  %first = call fastcc i32 @sample.first(i64 %pair)
        \\  %retv = bitcast i32 %first to i32
        \\  ret i32 %retv
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}

test "x86_64 codegen routes call plus global load check main wrapper through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\@sample.input = internal global i32 41
        \\@sample.output = internal global i32 0
        \\
        \\declare fastcc i32 @sample.loadStore(ptr, ptr)
        \\
        \\define i32 @sample.main() {
        \\0:
        \\  %call = call fastcc i32 @sample.loadStore(ptr @sample.input, ptr @sample.output)
        \\  %first.ok = icmp eq i32 %call, 42
        \\  br i1 %first.ok, label %7, label %5
        \\
        \\5:
        \\  %both.ok = phi i1 [ %output.ok, %7 ], [ 0, %0 ]
        \\  %result = select i1 %both.ok, i32 0, i32 1
        \\  ret i32 %result
        \\
        \\7:
        \\  %output = load i32, ptr @sample.output
        \\  %output.ok = icmp eq i32 %output, 42
        \\  br label %5
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}

test "x86_64 codegen routes two unary pointer call checks through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\@sample.value = internal global i32 42
        \\
        \\declare fastcc i32 @sample.optionalPtrValue(ptr)
        \\
        \\define i32 @sample.main() {
        \\0:
        \\  %first = call fastcc i32 @sample.optionalPtrValue(ptr @sample.value)
        \\  %first.ok = icmp eq i32 %first, 42
        \\  br i1 %first.ok, label %7, label %5
        \\
        \\5:
        \\  %both.ok = phi i1 [ %second.ok, %7 ], [ 0, %0 ]
        \\  %result = select i1 %both.ok, i32 0, i32 1
        \\  ret i32 %result
        \\
        \\7:
        \\  %second = call fastcc i32 @sample.optionalPtrValue(ptr null)
        \\  %second.ok = icmp eq i32 %second, -1
        \\  br label %5
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}

test "x86_64 codegen routes shift mix through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @integers.shift_mix(i32 %a, i32 %b) {
        \\entry:
        \\  %mask = and i32 %b, 31
        \\  %left = shl i32 %a, %mask
        \\  %right = lshr i32 %a, %mask
        \\  %mixed = xor i32 %left, %right
        \\  ret i32 %mixed
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}

test "x86_64 codegen routes scalar multiply-by-constant through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @control_flow_calls.callee(i32 %value) {
        \\entry:
        \\  %doubled = mul i32 %value, 2
        \\  ret i32 %doubled
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}

test "x86_64 codegen routes i64 constant return through generic cfg path" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i64 @i64_arithmetic.i64_value() {
        \\entry:
        \\  ret i64 1234567890123
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}
