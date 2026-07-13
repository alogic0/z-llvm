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

test "x86_64 assembly prints variable eax shifts" {
    var machine = codegen.x86_64.MachineFunction.init("variable_eax_shifts", .{ .int = 32 });
    defer machine.deinit(std.testing.allocator);
    try machine.instructions.append(std.testing.allocator, .shl_eax_cl);
    try machine.instructions.append(std.testing.allocator, .shr_eax_cl);
    try machine.instructions.append(std.testing.allocator, .sar_eax_cl);
    try machine.instructions.append(std.testing.allocator, .shl_rax_cl);
    try machine.instructions.append(std.testing.allocator, .shr_rax_cl);
    try machine.instructions.append(std.testing.allocator, .sar_rax_cl);
    try machine.instructions.append(std.testing.allocator, .{ .sar_eax_imm5 = 7 });
    try machine.instructions.append(std.testing.allocator, .ret);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try mc.assembly.printFunction(machine, &output.writer);
    try std.testing.expectEqualStrings(
        "\t.text\n" ++
            "\t.globl variable_eax_shifts\n" ++
            "variable_eax_shifts:\n" ++
            "\tshll %cl, %eax\n" ++
            "\tshrl %cl, %eax\n" ++
            "\tsarl %cl, %eax\n" ++
            "\tshlq %cl, %rax\n" ++
            "\tshrq %cl, %rax\n" ++
            "\tsarq %cl, %rax\n" ++
            "\tsarl $7, %eax\n" ++
            "\tretq\n",
        output.writer.buffered(),
    );
}

test "x86_64 assembly prints flag-preserving signed greater setcc" {
    var machine = codegen.x86_64.MachineFunction.init("setg", .{ .int = 32 });
    defer machine.deinit(std.testing.allocator);
    try machine.instructions.append(std.testing.allocator, .{ .cmp_eax_imm32 = 15 });
    try machine.instructions.append(std.testing.allocator, .setg_eax);
    try machine.instructions.append(std.testing.allocator, .ret);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try mc.assembly.printFunction(machine, &output.writer);

    try std.testing.expectEqualStrings(
        "\t.text\n" ++
            "\t.globl setg\n" ++
            "setg:\n" ++
            "\tcmpl $15, %eax\n" ++
            "\tsetg %al\n" ++
            "\tmovzbl %al, %eax\n" ++
            "\tretq\n",
        output.writer.buffered(),
    );
}

test "x86_64 assembly prints scalar FP bit moves and unsigned above setcc" {
    var machine = codegen.x86_64.MachineFunction.init("fp_bits_seta", .{ .int = 32 });
    defer machine.deinit(std.testing.allocator);
    try machine.instructions.append(std.testing.allocator, .{ .movd_xmm_eax = .xmm2 });
    try machine.instructions.append(std.testing.allocator, .{ .movd_eax_xmm = .xmm3 });
    try machine.instructions.append(std.testing.allocator, .seta_eax);
    try machine.instructions.append(std.testing.allocator, .ret);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try mc.assembly.printFunction(machine, &output.writer);

    try std.testing.expectEqualStrings(
        "\t.text\n" ++
            "\t.globl fp_bits_seta\n" ++
            "fp_bits_seta:\n" ++
            "\tmovd %xmm2, %eax\n" ++
            "\tmovd %eax, %xmm3\n" ++
            "\tseta %al\n" ++
            "\tmovzbl %al, %eax\n" ++
            "\tretq\n",
        output.writer.buffered(),
    );
}

test "x86_64 assembly prints unsigned i32 division" {
    var machine = codegen.x86_64.MachineFunction.init("unsigned_div_i32", .{ .int = 32 });
    defer machine.deinit(std.testing.allocator);
    try machine.instructions.append(std.testing.allocator, .xor_edx_edx);
    try machine.instructions.append(std.testing.allocator, .{ .div_arg32 = .rcx });
    try machine.instructions.append(std.testing.allocator, .ret);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try mc.assembly.printFunction(machine, &output.writer);
    try std.testing.expectEqualStrings(
        "\t.text\n" ++
            "\t.globl unsigned_div_i32\n" ++
            "unsigned_div_i32:\n" ++
            "\txorl %edx, %edx\n" ++
            "\tdivl %ecx\n" ++
            "\tretq\n",
        output.writer.buffered(),
    );
}

test "x86_64 assembly prints full-width multiply forms" {
    var machine = codegen.x86_64.MachineFunction.init("full_width_multiply", .{ .int = 128 });
    defer machine.deinit(std.testing.allocator);
    try machine.instructions.append(std.testing.allocator, .{ .mul_rax_arg64_full = .rsi });
    try machine.instructions.append(std.testing.allocator, .{ .imul_rax_arg64_full = .r8 });
    try machine.instructions.append(std.testing.allocator, .ret);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try mc.assembly.printFunction(machine, &output.writer);
    try std.testing.expectEqualStrings(
        "\t.text\n" ++
            "\t.globl full_width_multiply\n" ++
            "full_width_multiply:\n" ++
            "\tmulq %rsi\n" ++
            "\timulq %r8\n" ++
            "\tretq\n",
        output.writer.buffered(),
    );
}

test "x86_64 assembly prints add-carry immediate zero" {
    var machine = codegen.x86_64.MachineFunction.init("add_carry_zero", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);
    try machine.instructions.append(std.testing.allocator, .adc_rax_imm0);
    try machine.instructions.append(std.testing.allocator, .ret);

    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try mc.assembly.printFunction(machine, &output.writer);
    try std.testing.expectEqualStrings(
        "\t.text\n" ++
            "\t.globl add_carry_zero\n" ++
            "add_carry_zero:\n" ++
            "\tadcq $0, %rax\n" ++
            "\tretq\n",
        output.writer.buffered(),
    );
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
