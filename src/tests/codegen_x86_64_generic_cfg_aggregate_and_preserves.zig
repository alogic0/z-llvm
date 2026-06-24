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
