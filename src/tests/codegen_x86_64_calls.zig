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

test "x86_64 codegen argument register model excludes callee-saved GPRs" {
    try std.testing.expectEqual(codegen.x86_64.ArgReg.rdi, try codegen.x86_64.ArgReg.fromIndex(0));
    try std.testing.expectEqual(codegen.x86_64.ArgReg.rsi, try codegen.x86_64.ArgReg.fromIndex(1));
    try std.testing.expectEqual(codegen.x86_64.ArgReg.rdx, try codegen.x86_64.ArgReg.fromIndex(2));
    try std.testing.expectEqual(codegen.x86_64.ArgReg.rcx, try codegen.x86_64.ArgReg.fromIndex(3));
    try std.testing.expectEqual(codegen.x86_64.ArgReg.r8, try codegen.x86_64.ArgReg.fromIndex(4));
    try std.testing.expectEqual(codegen.x86_64.ArgReg.r9, try codegen.x86_64.ArgReg.fromIndex(5));
    try std.testing.expectError(error.UnsupportedCodegenAbi, codegen.x86_64.ArgReg.fromIndex(6));
}

test "x86_64 codegen stack argument cap matches Big256 byval frontier proof" {
    try std.testing.expectEqual(@as(usize, 256), codegen.x86_64.maxSysVStackCallArgsForTest);
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

test "x86_64 codegen rejects unsupported call ABI shapes and lowers advisory tail calls" {
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
        error.UnsupportedCallConvAbi,
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
    var tail_machine = try codegen.x86_64.lowerFunction(std.testing.allocator, tail_call_module.target_triple.?, tail_call_module.functions.items[0]);
    defer tail_machine.deinit(std.testing.allocator);
    var saw_ordinary_call = false;
    for (tail_machine.instructions.items) |instruction| switch (instruction) {
        .direct_call => saw_ordinary_call = true,
        .direct_jump => return error.UnexpectedTailJump,
        else => {},
    };
    try std.testing.expect(saw_ordinary_call);
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

test "x86_64 codegen preserves mixed f32 f64 call results across calls" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare float @first(float)
        \\declare double @second(double)
        \\
        \\define double @caller(float %a, double %b) {
        \\entry:
        \\  %first = call float @first(float %a)
        \\  %second = call double @second(double %b)
        \\  %wide = fpext float %first to double
        \\  %sum = fadd double %wide, %second
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
    try expectMachineInstruction(machine.instructions.items, .{ .spill_xmm64_rsp = .{ .reg = .xmm1, .frame_index = .slot0 } });
    try expectMachineInstruction(machine.instructions.items, .{ .spill_xmm32_rsp = .{ .reg = .xmm0, .frame_index = .slot2 } });
    try expectMachineInstruction(machine.instructions.items, .cvtss2sd_xmm0_xmm0);
    try expectMachineInstruction(machine.instructions.items, .addsd_xmm1_xmm0);
}

test "x86_64 codegen preserves mixed f64 f32 call results across calls" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare double @first(double)
        \\declare float @second(float)
        \\
        \\define double @caller(double %a, float %b) {
        \\entry:
        \\  %first = call double @first(double %a)
        \\  %second = call float @second(float %b)
        \\  %wide = fpext float %second to double
        \\  %sum = fadd double %first, %wide
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
    try expectMachineInstruction(machine.instructions.items, .{ .spill_xmm32_rsp = .{ .reg = .xmm1, .frame_index = .slot0 } });
    try expectMachineInstruction(machine.instructions.items, .{ .spill_xmm64_rsp = .{ .reg = .xmm0, .frame_index = .slot2 } });
    try expectMachineInstruction(machine.instructions.items, .cvtss2sd_xmm0_xmm0);
    try expectMachineInstruction(machine.instructions.items, .addsd_xmm1_xmm0);
}

test "x86_64 codegen preserves mixed fp call results and live f64 addend" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare float @first(float)
        \\declare double @second(double)
        \\
        \\define double @caller(float %a, double %b, double %c) {
        \\entry:
        \\  %first = call float @first(float %a)
        \\  %second = call double @second(double %b)
        \\  %wide = fpext float %first to double
        \\  %sum0 = fadd double %wide, %second
        \\  %sum1 = fadd double %sum0, %c
        \\  ret double %sum1
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
    try expectMachineInstruction(machine.instructions.items, .{ .spill_xmm64_rsp = .{ .reg = .xmm1, .frame_index = .slot0 } });
    try expectMachineInstruction(machine.instructions.items, .{ .spill_xmm64_rsp = .{ .reg = .xmm2, .frame_index = .slot6 } });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_xmm64_rsp = .{ .reg = .xmm1, .frame_index = .slot6 } });
    var add_count: usize = 0;
    for (machine.instructions.items) |instruction| {
        if (instruction == .addsd_xmm1_xmm0) add_count += 1;
    }
    try std.testing.expectEqual(@as(usize, 2), add_count);
    try expectMachineInstruction(machine.instructions.items, .add_rsp_40);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[machine.instructions.items.len - 1]);
}

test "x86_64 codegen preserves indirect mixed fp call results and live f64 addend" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define double @caller(ptr %first, ptr %second, float %a, double %b, double %c) {
        \\entry:
        \\  %first_result = call float %first(float %a)
        \\  %second_result = call double %second(double %b)
        \\  %wide = fpext float %first_result to double
        \\  %sum0 = fadd double %wide, %second_result
        \\  %sum1 = fadd double %sum0, %c
        \\  ret double %sum1
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
    try expectMachineInstruction(machine.instructions.items, .{ .spill_xmm64_rsp = .{ .reg = .xmm1, .frame_index = .slot0 } });
    try expectMachineInstruction(machine.instructions.items, .{ .spill_xmm64_rsp = .{ .reg = .xmm2, .frame_index = .slot6 } });
    try expectMachineInstruction(machine.instructions.items, .{ .spill_arg64_rsp = .{ .reg = .rsi, .frame_index = .slot4 } });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_arg64_rsp = .{ .reg = .rsi, .frame_index = .slot4 } });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_xmm64_rsp = .{ .reg = .xmm1, .frame_index = .slot6 } });
    var add_count: usize = 0;
    for (machine.instructions.items) |instruction| {
        if (instruction == .addsd_xmm1_xmm0) add_count += 1;
    }
    try std.testing.expectEqual(@as(usize, 2), add_count);
    try expectMachineInstruction(machine.instructions.items, .add_rsp_40);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[machine.instructions.items.len - 1]);
}

test "x86_64 codegen preserves mixed fp call results and live i64 addend" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare float @first(float)
        \\declare double @second(double)
        \\
        \\define double @caller(float %a, double %b, i64 %c) {
        \\entry:
        \\  %first = call float @first(float %a)
        \\  %second = call double @second(double %b)
        \\  %wide = fpext float %first to double
        \\  %sum0 = fadd double %wide, %second
        \\  %live = sitofp i64 %c to double
        \\  %sum1 = fadd double %sum0, %live
        \\  ret double %sum1
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
    try expectMachineInstruction(machine.instructions.items, .{ .spill_xmm64_rsp = .{ .reg = .xmm1, .frame_index = .slot0 } });
    try expectMachineInstruction(machine.instructions.items, .{ .spill_arg64_rsp = .{ .reg = .rdi, .frame_index = .slot6 } });
    try expectMachineInstruction(machine.instructions.items, .{ .movapd_xmm = .{ .dst = .xmm1, .src = .xmm0 } });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_arg64_rsp = .{ .reg = .rdi, .frame_index = .slot6 } });
    try expectMachineInstruction(machine.instructions.items, .cvtsi2sd_rdi_xmm0);
    var add_count: usize = 0;
    for (machine.instructions.items) |instruction| {
        if (instruction == .addsd_xmm1_xmm0) add_count += 1;
    }
    try std.testing.expectEqual(@as(usize, 2), add_count);
    try expectMachineInstruction(machine.instructions.items, .add_rsp_40);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[machine.instructions.items.len - 1]);
}

test "x86_64 codegen preserves indirect mixed fp call results and live i64 addend" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define double @caller(ptr %first, ptr %second, float %a, double %b, i64 %c) {
        \\entry:
        \\  %first_result = call float %first(float %a)
        \\  %second_result = call double %second(double %b)
        \\  %wide = fpext float %first_result to double
        \\  %sum0 = fadd double %wide, %second_result
        \\  %live = sitofp i64 %c to double
        \\  %sum1 = fadd double %sum0, %live
        \\  ret double %sum1
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
    try expectMachineInstruction(machine.instructions.items, .{ .spill_xmm64_rsp = .{ .reg = .xmm1, .frame_index = .slot0 } });
    try expectMachineInstruction(machine.instructions.items, .{ .spill_arg64_rsp = .{ .reg = .rdx, .frame_index = .slot6 } });
    try expectMachineInstruction(machine.instructions.items, .{ .spill_arg64_rsp = .{ .reg = .rsi, .frame_index = .slot4 } });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_arg64_rsp = .{ .reg = .rsi, .frame_index = .slot4 } });
    try expectMachineInstruction(machine.instructions.items, .{ .movapd_xmm = .{ .dst = .xmm1, .src = .xmm0 } });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_arg64_rsp = .{ .reg = .rdi, .frame_index = .slot6 } });
    try expectMachineInstruction(machine.instructions.items, .cvtsi2sd_rdi_xmm0);
    var add_count: usize = 0;
    for (machine.instructions.items) |instruction| {
        if (instruction == .addsd_xmm1_xmm0) add_count += 1;
    }
    try std.testing.expectEqual(@as(usize, 2), add_count);
    try expectMachineInstruction(machine.instructions.items, .add_rsp_40);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[machine.instructions.items.len - 1]);
}

test "x86_64 codegen preserves reversed mixed fp call results and live f64 addend" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare double @first(double)
        \\declare float @second(float)
        \\
        \\define double @caller(double %a, float %b, double %c) {
        \\entry:
        \\  %first = call double @first(double %a)
        \\  %second = call float @second(float %b)
        \\  %wide = fpext float %second to double
        \\  %sum0 = fadd double %first, %wide
        \\  %sum1 = fadd double %sum0, %c
        \\  ret double %sum1
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
    try expectMachineInstruction(machine.instructions.items, .{ .spill_xmm32_rsp = .{ .reg = .xmm1, .frame_index = .slot0 } });
    try expectMachineInstruction(machine.instructions.items, .{ .spill_xmm64_rsp = .{ .reg = .xmm2, .frame_index = .slot6 } });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_xmm64_rsp = .{ .reg = .xmm1, .frame_index = .slot6 } });
    var add_count: usize = 0;
    for (machine.instructions.items) |instruction| {
        if (instruction == .addsd_xmm1_xmm0) add_count += 1;
    }
    try std.testing.expectEqual(@as(usize, 2), add_count);
    try expectMachineInstruction(machine.instructions.items, .add_rsp_40);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[machine.instructions.items.len - 1]);
}

test "x86_64 codegen preserves reversed mixed fp call results and live i64 addend" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare double @first(double)
        \\declare float @second(float)
        \\
        \\define double @caller(double %a, float %b, i64 %c) {
        \\entry:
        \\  %first = call double @first(double %a)
        \\  %second = call float @second(float %b)
        \\  %wide = fpext float %second to double
        \\  %sum0 = fadd double %first, %wide
        \\  %live = sitofp i64 %c to double
        \\  %sum1 = fadd double %sum0, %live
        \\  ret double %sum1
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
    try expectMachineInstruction(machine.instructions.items, .{ .spill_xmm32_rsp = .{ .reg = .xmm1, .frame_index = .slot0 } });
    try expectMachineInstruction(machine.instructions.items, .{ .spill_arg64_rsp = .{ .reg = .rdi, .frame_index = .slot6 } });
    try expectMachineInstruction(machine.instructions.items, .{ .movapd_xmm = .{ .dst = .xmm1, .src = .xmm0 } });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_arg64_rsp = .{ .reg = .rdi, .frame_index = .slot6 } });
    try expectMachineInstruction(machine.instructions.items, .cvtsi2sd_rdi_xmm0);
    var add_count: usize = 0;
    for (machine.instructions.items) |instruction| {
        if (instruction == .addsd_xmm1_xmm0) add_count += 1;
    }
    try std.testing.expectEqual(@as(usize, 2), add_count);
    try expectMachineInstruction(machine.instructions.items, .add_rsp_40);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[machine.instructions.items.len - 1]);
}

test "x86_64 codegen preserves i64 and f64 call results across calls" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare i64 @first(i64)
        \\declare double @second(double)
        \\
        \\define double @caller(i64 %a, double %b) {
        \\entry:
        \\  %first = call i64 @first(i64 %a)
        \\  %second = call double @second(double %b)
        \\  %wide = sitofp i64 %first to double
        \\  %sum = fadd double %wide, %second
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
    try expectMachineInstruction(machine.instructions.items, .{ .spill_xmm64_rsp = .{ .reg = .xmm0, .frame_index = .slot2 } });
    try expectMachineInstruction(machine.instructions.items, .{ .spill_rax_rsp = .slot0 });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_xmm64_rsp = .{ .reg = .xmm0, .frame_index = .slot2 } });
    try expectMachineInstruction(machine.instructions.items, .{ .movapd_xmm = .{ .dst = .xmm1, .src = .xmm0 } });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_arg64_rsp = .{ .reg = .rdi, .frame_index = .slot0 } });
    try expectMachineInstruction(machine.instructions.items, .cvtsi2sd_rdi_xmm0);
    try expectMachineInstruction(machine.instructions.items, .addsd_xmm1_xmm0);
    try expectMachineInstruction(machine.instructions.items, .add_rsp_24);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[machine.instructions.items.len - 1]);
}

test "x86_64 codegen preserves indirect i64 and f64 call results across calls" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define double @caller(ptr %first, ptr %second, i64 %a, double %b) {
        \\entry:
        \\  %first_result = call i64 %first(i64 %a)
        \\  %second_result = call double %second(double %b)
        \\  %wide = sitofp i64 %first_result to double
        \\  %sum = fadd double %wide, %second_result
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
    try expectMachineInstruction(machine.instructions.items, .{ .spill_xmm64_rsp = .{ .reg = .xmm0, .frame_index = .slot2 } });
    try expectMachineInstruction(machine.instructions.items, .{ .spill_arg64_rsp = .{ .reg = .rsi, .frame_index = .slot4 } });
    try expectMachineInstruction(machine.instructions.items, .{ .spill_rax_rsp = .slot0 });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_arg64_rsp = .{ .reg = .rsi, .frame_index = .slot4 } });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_xmm64_rsp = .{ .reg = .xmm0, .frame_index = .slot2 } });
    try expectMachineInstruction(machine.instructions.items, .{ .movapd_xmm = .{ .dst = .xmm1, .src = .xmm0 } });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_arg64_rsp = .{ .reg = .rdi, .frame_index = .slot0 } });
    try expectMachineInstruction(machine.instructions.items, .cvtsi2sd_rdi_xmm0);
    try expectMachineInstruction(machine.instructions.items, .addsd_xmm1_xmm0);
    try expectMachineInstruction(machine.instructions.items, .add_rsp_40);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[machine.instructions.items.len - 1]);
}

test "x86_64 codegen preserves i64 and f32 call results across calls" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare i64 @first(i64)
        \\declare float @second(float)
        \\
        \\define double @caller(i64 %a, float %b) {
        \\entry:
        \\  %first = call i64 @first(i64 %a)
        \\  %second = call float @second(float %b)
        \\  %wide_first = sitofp i64 %first to double
        \\  %wide_second = fpext float %second to double
        \\  %sum = fadd double %wide_first, %wide_second
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
    try expectMachineInstruction(machine.instructions.items, .{ .spill_xmm32_rsp = .{ .reg = .xmm0, .frame_index = .slot2 } });
    try expectMachineInstruction(machine.instructions.items, .{ .spill_rax_rsp = .slot0 });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_xmm32_rsp = .{ .reg = .xmm0, .frame_index = .slot2 } });
    try expectMachineInstruction(machine.instructions.items, .cvtss2sd_xmm0_xmm0);
    try expectMachineInstruction(machine.instructions.items, .{ .movapd_xmm = .{ .dst = .xmm1, .src = .xmm0 } });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_arg64_rsp = .{ .reg = .rdi, .frame_index = .slot0 } });
    try expectMachineInstruction(machine.instructions.items, .cvtsi2sd_rdi_xmm0);
    try expectMachineInstruction(machine.instructions.items, .addsd_xmm1_xmm0);
    try expectMachineInstruction(machine.instructions.items, .add_rsp_24);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[machine.instructions.items.len - 1]);
}

test "x86_64 codegen preserves indirect i64 and f32 call results across calls" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define double @caller(ptr %first, ptr %second, i64 %a, float %b) {
        \\entry:
        \\  %first_result = call i64 %first(i64 %a)
        \\  %second_result = call float %second(float %b)
        \\  %wide_first = sitofp i64 %first_result to double
        \\  %wide_second = fpext float %second_result to double
        \\  %sum = fadd double %wide_first, %wide_second
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
    try expectMachineInstruction(machine.instructions.items, .{ .spill_xmm32_rsp = .{ .reg = .xmm0, .frame_index = .slot2 } });
    try expectMachineInstruction(machine.instructions.items, .{ .spill_arg64_rsp = .{ .reg = .rsi, .frame_index = .slot4 } });
    try expectMachineInstruction(machine.instructions.items, .{ .spill_rax_rsp = .slot0 });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_arg64_rsp = .{ .reg = .rsi, .frame_index = .slot4 } });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_xmm32_rsp = .{ .reg = .xmm0, .frame_index = .slot2 } });
    try expectMachineInstruction(machine.instructions.items, .cvtss2sd_xmm0_xmm0);
    try expectMachineInstruction(machine.instructions.items, .{ .movapd_xmm = .{ .dst = .xmm1, .src = .xmm0 } });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_arg64_rsp = .{ .reg = .rdi, .frame_index = .slot0 } });
    try expectMachineInstruction(machine.instructions.items, .cvtsi2sd_rdi_xmm0);
    try expectMachineInstruction(machine.instructions.items, .addsd_xmm1_xmm0);
    try expectMachineInstruction(machine.instructions.items, .add_rsp_40);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[machine.instructions.items.len - 1]);
}

test "x86_64 codegen preserves f64 and i64 call results across calls" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare double @first(double)
        \\declare i64 @second(i64)
        \\
        \\define double @caller(double %a, i64 %b) {
        \\entry:
        \\  %first = call double @first(double %a)
        \\  %second = call i64 @second(i64 %b)
        \\  %wide = sitofp i64 %second to double
        \\  %sum = fadd double %first, %wide
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
    try expectMachineInstruction(machine.instructions.items, .{ .spill_arg64_rsp = .{ .reg = .rdi, .frame_index = .slot2 } });
    try expectMachineInstruction(machine.instructions.items, .{ .spill_xmm64_rsp = .{ .reg = .xmm0, .frame_index = .slot0 } });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_arg64_rsp = .{ .reg = .rdi, .frame_index = .slot2 } });
    try expectMachineInstruction(machine.instructions.items, .mov_rax_rdi);
    try expectMachineInstruction(machine.instructions.items, .cvtsi2sd_rdi_xmm0);
    try expectMachineInstruction(machine.instructions.items, .{ .reload_xmm64_rsp = .{ .reg = .xmm1, .frame_index = .slot0 } });
    try expectMachineInstruction(machine.instructions.items, .addsd_xmm1_xmm0);
    try expectMachineInstruction(machine.instructions.items, .add_rsp_24);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[machine.instructions.items.len - 1]);
}

test "x86_64 codegen preserves indirect f64 and i64 call results across calls" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define double @caller(ptr %first, ptr %second, double %a, i64 %b) {
        \\entry:
        \\  %first_result = call double %first(double %a)
        \\  %second_result = call i64 %second(i64 %b)
        \\  %wide = sitofp i64 %second_result to double
        \\  %sum = fadd double %first_result, %wide
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
    try expectMachineInstruction(machine.instructions.items, .{ .spill_arg64_rsp = .{ .reg = .rdx, .frame_index = .slot2 } });
    try expectMachineInstruction(machine.instructions.items, .{ .spill_arg64_rsp = .{ .reg = .rsi, .frame_index = .slot4 } });
    try expectMachineInstruction(machine.instructions.items, .{ .spill_xmm64_rsp = .{ .reg = .xmm0, .frame_index = .slot0 } });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_arg64_rsp = .{ .reg = .rsi, .frame_index = .slot4 } });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_arg64_rsp = .{ .reg = .rdx, .frame_index = .slot2 } });
    try expectMachineInstruction(machine.instructions.items, .mov_rax_rdi);
    try expectMachineInstruction(machine.instructions.items, .cvtsi2sd_rdi_xmm0);
    try expectMachineInstruction(machine.instructions.items, .{ .reload_xmm64_rsp = .{ .reg = .xmm1, .frame_index = .slot0 } });
    try expectMachineInstruction(machine.instructions.items, .addsd_xmm1_xmm0);
    try expectMachineInstruction(machine.instructions.items, .add_rsp_40);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[machine.instructions.items.len - 1]);
}

test "x86_64 codegen preserves f32 and i64 call results across calls" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare float @first(float)
        \\declare i64 @second(i64)
        \\
        \\define double @caller(float %a, i64 %b) {
        \\entry:
        \\  %first = call float @first(float %a)
        \\  %second = call i64 @second(i64 %b)
        \\  %wide_first = fpext float %first to double
        \\  %wide_second = sitofp i64 %second to double
        \\  %sum = fadd double %wide_first, %wide_second
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
    try expectMachineInstruction(machine.instructions.items, .{ .spill_arg64_rsp = .{ .reg = .rdi, .frame_index = .slot2 } });
    try expectMachineInstruction(machine.instructions.items, .{ .spill_xmm32_rsp = .{ .reg = .xmm0, .frame_index = .slot0 } });
    try expectMachineInstruction(machine.instructions.items, .mov_rax_rdi);
    try expectMachineInstruction(machine.instructions.items, .cvtsi2sd_rdi_xmm0);
    try expectMachineInstruction(machine.instructions.items, .{ .movapd_xmm = .{ .dst = .xmm1, .src = .xmm0 } });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_xmm32_rsp = .{ .reg = .xmm0, .frame_index = .slot0 } });
    try expectMachineInstruction(machine.instructions.items, .cvtss2sd_xmm0_xmm0);
    try expectMachineInstruction(machine.instructions.items, .addsd_xmm1_xmm0);
    try expectMachineInstruction(machine.instructions.items, .add_rsp_24);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[machine.instructions.items.len - 1]);
}

test "x86_64 codegen preserves indirect f32 and i64 call results across calls" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define double @caller(ptr %first, ptr %second, float %a, i64 %b) {
        \\entry:
        \\  %first_result = call float %first(float %a)
        \\  %second_result = call i64 %second(i64 %b)
        \\  %wide_first = fpext float %first_result to double
        \\  %wide_second = sitofp i64 %second_result to double
        \\  %sum = fadd double %wide_first, %wide_second
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
    try expectMachineInstruction(machine.instructions.items, .{ .spill_arg64_rsp = .{ .reg = .rdx, .frame_index = .slot2 } });
    try expectMachineInstruction(machine.instructions.items, .{ .spill_arg64_rsp = .{ .reg = .rsi, .frame_index = .slot4 } });
    try expectMachineInstruction(machine.instructions.items, .{ .spill_xmm32_rsp = .{ .reg = .xmm0, .frame_index = .slot0 } });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_arg64_rsp = .{ .reg = .rsi, .frame_index = .slot4 } });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_arg64_rsp = .{ .reg = .rdx, .frame_index = .slot2 } });
    try expectMachineInstruction(machine.instructions.items, .mov_rax_rdi);
    try expectMachineInstruction(machine.instructions.items, .cvtsi2sd_rdi_xmm0);
    try expectMachineInstruction(machine.instructions.items, .{ .movapd_xmm = .{ .dst = .xmm1, .src = .xmm0 } });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_xmm32_rsp = .{ .reg = .xmm0, .frame_index = .slot0 } });
    try expectMachineInstruction(machine.instructions.items, .cvtss2sd_xmm0_xmm0);
    try expectMachineInstruction(machine.instructions.items, .addsd_xmm1_xmm0);
    try expectMachineInstruction(machine.instructions.items, .add_rsp_40);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[machine.instructions.items.len - 1]);
}

test "x86_64 codegen preserves two i64 call results across calls" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare i64 @first(i64)
        \\declare i64 @second(i64)
        \\
        \\define i64 @caller(i64 %a, i64 %b) {
        \\entry:
        \\  %first = call i64 @first(i64 %a)
        \\  %second = call i64 @second(i64 %b)
        \\  %sum = add i64 %first, %second
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
    try expectMachineInstruction(machine.instructions.items, .{ .spill_rax_rsp = .slot0 });
    try expectMachineInstruction(machine.instructions.items, .{ .add_stack_disp8_rax = 0 });
}

test "x86_64 codegen preserves i64 call result across pointer-callee i64 call" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare i64 @first(i64)
        \\
        \\define i64 @caller(ptr %second, i64 %a, i64 %b) {
        \\entry:
        \\  %first = call i64 @first(i64 %a)
        \\  %next = call i64 %second(i64 %b)
        \\  %sum = add i64 %first, %next
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
    try expectMachineInstruction(machine.instructions.items, .{ .spill_arg64_rsp = .{ .frame_index = .slot2, .reg = .rdi } });
    try expectMachineInstruction(machine.instructions.items, .{ .spill_rax_rsp = .slot0 });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_arg64_rsp = .{ .reg = .rdi, .frame_index = .slot2 } });
    try expectMachineInstruction(machine.instructions.items, .{ .add_stack_disp8_rax = 0 });
}

test "x86_64 codegen preserves pointer-callee i64 result across direct i64 call" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare i64 @second(i64)
        \\
        \\define i64 @caller(ptr %first, i64 %a, i64 %b) {
        \\entry:
        \\  %first_result = call i64 %first(i64 %a)
        \\  %second_result = call i64 @second(i64 %b)
        \\  %sum = add i64 %first_result, %second_result
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
    try expectMachineInstruction(machine.instructions.items, .{ .mov_arg_rax = .rdi });
    try expectMachineInstruction(machine.instructions.items, .{ .spill_rax_rsp = .slot0 });
    try expectMachineInstruction(machine.instructions.items, .{ .add_stack_disp8_rax = 0 });
}

test "x86_64 codegen preserves two pointer-callee i64 results across calls" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i64 @caller(ptr %first, ptr %second, i64 %a, i64 %b) {
        \\entry:
        \\  %first_result = call i64 %first(i64 %a)
        \\  %second_result = call i64 %second(i64 %b)
        \\  %sum = add i64 %first_result, %second_result
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
    try expectMachineInstruction(machine.instructions.items, .{ .spill_arg64_rsp = .{ .frame_index = .slot2, .reg = .rsi } });
    try expectMachineInstruction(machine.instructions.items, .{ .mov_arg_rax = .rdi });
    try expectMachineInstruction(machine.instructions.items, .{ .spill_rax_rsp = .slot0 });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_arg64_rsp = .{ .reg = .rsi, .frame_index = .slot2 } });
    try expectMachineInstruction(machine.instructions.items, .{ .mov_arg_rax = .rsi });
    try expectMachineInstruction(machine.instructions.items, .{ .add_stack_disp8_rax = 0 });
}

test "x86_64 codegen preserves i64 call result across later void call" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare i64 @first(i64)
        \\declare void @touch()
        \\
        \\define i64 @caller(i64 %a, i64 %b) {
        \\entry:
        \\  %first_result = call i64 @first(i64 %a)
        \\  call void @touch()
        \\  %sum = add i64 %first_result, %b
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
    try expectMachineInstruction(machine.instructions.items, .{ .spill_arg64_rsp = .{ .frame_index = .slot2, .reg = .rsi } });
    try expectMachineInstruction(machine.instructions.items, .{ .spill_rax_rsp = .slot0 });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_rsp_rax = .slot0 });
    try expectMachineInstruction(machine.instructions.items, .{ .add_stack_disp8_rax = 8 });
}

test "x86_64 codegen preserves indirect two i32 call results across later pointer-callee void call" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @caller(ptr %first, ptr %second, ptr %touch, i32 %a, i32 %b) {
        \\entry:
        \\  %first_result = call i32 %first(i32 %a)
        \\  %second_result = call i32 %second(i32 %b)
        \\  call void %touch()
        \\  %sum0 = add i32 %first_result, %second_result
        \\  %sum1 = add i32 %sum0, %a
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
    try expectMachineInstruction(machine.instructions.items, .{ .spill_arg_rsp = .{ .frame_index = .slot1, .reg = .rcx } });
    try expectMachineInstruction(machine.instructions.items, .{ .spill_arg_rsp = .{ .frame_index = .slot4, .reg = .r8 } });
    try expectMachineInstruction(machine.instructions.items, .{ .spill_arg64_rsp = .{ .frame_index = .slot6, .reg = .rsi } });
    try expectMachineInstruction(machine.instructions.items, .{ .spill_arg64_rsp = .{ .frame_index = .slot8, .reg = .rdx } });
    try expectMachineInstruction(machine.instructions.items, .{ .mov_arg_rax = .rdi });
    try expectMachineInstruction(machine.instructions.items, .{ .spill_eax_rsp = .slot0 });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_arg64_rsp = .{ .reg = .rsi, .frame_index = .slot6 } });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_arg_rsp = .{ .reg = .r8, .frame_index = .slot4 } });
    try expectMachineInstruction(machine.instructions.items, .{ .mov_arg_rax = .rsi });
    try expectMachineInstruction(machine.instructions.items, .{ .spill_eax_rsp = .slot2 });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_arg64_rsp = .{ .reg = .rdx, .frame_index = .slot8 } });
    try expectMachineInstruction(machine.instructions.items, .{ .mov_arg_rax = .rdx });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_rsp_eax = .slot0 });
    try expectMachineInstruction(machine.instructions.items, .{ .add_stack_disp8_eax = 8 });
    try expectMachineInstruction(machine.instructions.items, .{ .add_stack_disp8_eax = 4 });
}

test "x86_64 codegen preserves indirect two i32 call results across calls" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @caller(ptr %first, ptr %second, i32 %a, i32 %b) {
        \\entry:
        \\  %first_result = call i32 %first(i32 %a)
        \\  %second_result = call i32 %second(i32 %b)
        \\  %sum0 = add i32 %first_result, %second_result
        \\  %sum1 = add i32 %sum0, %a
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
    try expectMachineInstruction(machine.instructions.items, .{ .spill_arg_rsp = .{ .frame_index = .slot1, .reg = .rdx } });
    try expectMachineInstruction(machine.instructions.items, .{ .spill_arg64_rsp = .{ .frame_index = .slot2, .reg = .rsi } });
    try expectMachineInstruction(machine.instructions.items, .{ .spill_arg_rsp = .{ .frame_index = .slot4, .reg = .rcx } });
    try expectMachineInstruction(machine.instructions.items, .{ .mov_arg_rax = .rdi });
    try expectMachineInstruction(machine.instructions.items, .{ .spill_eax_rsp = .slot0 });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_arg64_rsp = .{ .reg = .rsi, .frame_index = .slot2 } });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_arg_rsp = .{ .reg = .rcx, .frame_index = .slot4 } });
    try expectMachineInstruction(machine.instructions.items, .{ .mov_arg_rax = .rsi });
    try expectMachineInstruction(machine.instructions.items, .{ .add_stack_disp8_eax = 0 });
    try expectMachineInstruction(machine.instructions.items, .{ .add_stack_disp8_eax = 4 });
}

test "x86_64 codegen uses disp32 for high incoming stack i32 addends" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare fastcc i32 @id(i32)
        \\
        \\define i32 @caller(i32 %arg0, i32 %arg1, i32 %arg2, i32 %arg3, i32 %arg4, i32 %arg5, i32 %arg6, i32 %arg7, i32 %arg8, i32 %arg9, i32 %arg10, i32 %arg11, i32 %arg12, i32 %arg13, i32 %arg14, i32 %arg15, i32 %arg16, i32 %arg17, i32 %arg18, i32 %arg19, i32 %arg20, i32 %arg21, i32 %arg22, i32 %arg23) {
        \\entry:
        \\  %call = call fastcc i32 @id(i32 %arg5)
        \\  %sum01 = add i32 %arg0, %arg1
        \\  %sum02 = add i32 %sum01, %arg2
        \\  %sum03 = add i32 %sum02, %arg3
        \\  %sum04 = add i32 %sum03, %arg4
        \\  %sum05 = add i32 %sum04, %arg5
        \\  %sum06 = add i32 %sum05, %arg6
        \\  %sum07 = add i32 %sum06, %arg7
        \\  %sum08 = add i32 %sum07, %arg8
        \\  %sum09 = add i32 %sum08, %arg9
        \\  %sum10 = add i32 %sum09, %arg10
        \\  %sum11 = add i32 %sum10, %arg11
        \\  %sum12 = add i32 %sum11, %arg12
        \\  %sum13 = add i32 %sum12, %arg13
        \\  %sum14 = add i32 %sum13, %arg14
        \\  %sum15 = add i32 %sum14, %arg15
        \\  %sum16 = add i32 %sum15, %arg16
        \\  %sum17 = add i32 %sum16, %arg17
        \\  %sum18 = add i32 %sum17, %arg18
        \\  %sum19 = add i32 %sum18, %arg19
        \\  %sum20 = add i32 %sum19, %arg20
        \\  %sum21 = add i32 %sum20, %arg21
        \\  %sum22 = add i32 %sum21, %arg22
        \\  %sum23 = add i32 %sum22, %arg23
        \\  %result = add i32 %sum23, %call
        \\  ret i32 %result
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try expectMachineInstruction(machine.instructions.items, .{ .add_stack_disp8_eax = 120 });
    try expectMachineInstruction(machine.instructions.items, .{ .add_stack_disp32_eax = 128 });
    try expectMachineInstruction(machine.instructions.items, .{ .add_stack_disp32_eax = 136 });
    try expectMachineInstruction(machine.instructions.items, .{ .add_stack_disp32_eax = 144 });
}

test "x86_64 codegen preserves i64 pointer-callee result across later pointer-callee void call" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i64 @caller(ptr %first, ptr %touch, i64 %a, i64 %b) {
        \\entry:
        \\  %first_result = call i64 %first(i64 %a)
        \\  call void %touch()
        \\  %sum = add i64 %first_result, %b
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
    try expectMachineInstruction(machine.instructions.items, .{ .spill_arg64_rsp = .{ .frame_index = .slot2, .reg = .rcx } });
    try expectMachineInstruction(machine.instructions.items, .{ .spill_arg64_rsp = .{ .frame_index = .slot4, .reg = .rsi } });
    try expectMachineInstruction(machine.instructions.items, .{ .mov_arg_rax = .rdi });
    try expectMachineInstruction(machine.instructions.items, .{ .spill_rax_rsp = .slot0 });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_arg64_rsp = .{ .reg = .rsi, .frame_index = .slot4 } });
    try expectMachineInstruction(machine.instructions.items, .{ .mov_arg_rax = .rsi });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_rsp_rax = .slot0 });
    try expectMachineInstruction(machine.instructions.items, .{ .add_stack_disp8_rax = 8 });
}

test "x86_64 codegen preserves two i64 call results across later void call" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare i64 @first(i64)
        \\declare i64 @second(i64)
        \\declare void @touch()
        \\
        \\define i64 @caller(i64 %a, i64 %b) {
        \\entry:
        \\  %first_result = call i64 @first(i64 %a)
        \\  %second_result = call i64 @second(i64 %b)
        \\  call void @touch()
        \\  %sum = add i64 %first_result, %second_result
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
    try expectMachineInstruction(machine.instructions.items, .{ .spill_arg64_rsp = .{ .frame_index = .slot4, .reg = .rsi } });
    try expectMachineInstruction(machine.instructions.items, .{ .spill_rax_rsp = .slot0 });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_arg64_rsp = .{ .reg = .rsi, .frame_index = .slot4 } });
    try expectMachineInstruction(machine.instructions.items, .{ .spill_rax_rsp = .slot2 });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_rsp_rax = .slot0 });
    try expectMachineInstruction(machine.instructions.items, .{ .add_stack_disp8_rax = 8 });
}

test "x86_64 codegen preserves two i64 call results across later pointer-callee void call" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare i64 @first(i64)
        \\declare i64 @second(i64)
        \\
        \\define i64 @caller(ptr %touch, i64 %a, i64 %b) {
        \\entry:
        \\  %first_result = call i64 @first(i64 %a)
        \\  %second_result = call i64 @second(i64 %b)
        \\  call void %touch()
        \\  %sum = add i64 %first_result, %second_result
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
    try expectMachineInstruction(machine.instructions.items, .{ .spill_arg64_rsp = .{ .frame_index = .slot4, .reg = .rdx } });
    try expectMachineInstruction(machine.instructions.items, .{ .spill_arg64_rsp = .{ .frame_index = .slot8, .reg = .rdi } });
    try expectMachineInstruction(machine.instructions.items, .{ .spill_rax_rsp = .slot0 });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_arg64_rsp = .{ .reg = .rdx, .frame_index = .slot4 } });
    try expectMachineInstruction(machine.instructions.items, .{ .spill_rax_rsp = .slot2 });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_arg64_rsp = .{ .reg = .rdi, .frame_index = .slot8 } });
    try expectMachineInstruction(machine.instructions.items, .{ .mov_arg_rax = .rdi });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_rsp_rax = .slot0 });
    try expectMachineInstruction(machine.instructions.items, .{ .add_stack_disp8_rax = 8 });
}

test "x86_64 codegen preserves two i64 call results and live addend across later void call" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare i64 @first(i64)
        \\declare i64 @second(i64)
        \\declare void @touch()
        \\
        \\define i64 @caller(i64 %a, i64 %b) {
        \\entry:
        \\  %first_result = call i64 @first(i64 %a)
        \\  %second_result = call i64 @second(i64 %b)
        \\  call void @touch()
        \\  %sum0 = add i64 %first_result, %second_result
        \\  %sum1 = add i64 %sum0, %a
        \\  ret i64 %sum1
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try expectMachineInstruction(machine.instructions.items, .{ .spill_arg64_rsp = .{ .frame_index = .slot4, .reg = .rsi } });
    try expectMachineInstruction(machine.instructions.items, .{ .spill_arg64_rsp = .{ .frame_index = .slot10, .reg = .rdi } });
    try expectMachineInstruction(machine.instructions.items, .{ .spill_rax_rsp = .slot0 });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_arg64_rsp = .{ .reg = .rsi, .frame_index = .slot4 } });
    try expectMachineInstruction(machine.instructions.items, .{ .spill_rax_rsp = .slot2 });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_rsp_rax = .slot0 });
    try expectMachineInstruction(machine.instructions.items, .{ .add_stack_disp8_rax = 8 });
    try expectMachineInstruction(machine.instructions.items, .{ .add_stack_disp8_rax = 40 });
}

test "x86_64 codegen preserves i64 and f64 live values across void call before fp add" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare void @touch()
        \\
        \\define double @caller(i64 %a, double %b) {
        \\entry:
        \\  call void @touch()
        \\  %cast = sitofp i64 %a to double
        \\  %sum = fadd double %cast, %b
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
    try expectMachineInstruction(machine.instructions.items, .{ .spill_arg64_rsp = .{ .frame_index = .slot0, .reg = .rdi } });
    try expectMachineInstruction(machine.instructions.items, .{ .spill_xmm64_rsp = .{ .frame_index = .slot2, .reg = .xmm0 } });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_arg64_rsp = .{ .reg = .rdi, .frame_index = .slot0 } });
    try expectMachineInstruction(machine.instructions.items, .cvtsi2sd_rdi_xmm0);
    try expectMachineInstruction(machine.instructions.items, .{ .reload_xmm64_rsp = .{ .reg = .xmm1, .frame_index = .slot2 } });
    try expectMachineInstruction(machine.instructions.items, .addsd_xmm1_xmm0);
}

test "x86_64 codegen preserves indirect two i64 call results across later pointer-callee void call" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i64 @caller(ptr %first, ptr %second, ptr %touch, i64 %a, i64 %b) {
        \\entry:
        \\  %first_result = call i64 %first(i64 %a)
        \\  %second_result = call i64 %second(i64 %b)
        \\  call void %touch()
        \\  %sum = add i64 %first_result, %second_result
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
    try expectMachineInstruction(machine.instructions.items, .{ .spill_arg64_rsp = .{ .frame_index = .slot4, .reg = .r8 } });
    try expectMachineInstruction(machine.instructions.items, .{ .spill_arg64_rsp = .{ .frame_index = .slot6, .reg = .rsi } });
    try expectMachineInstruction(machine.instructions.items, .{ .spill_arg64_rsp = .{ .frame_index = .slot8, .reg = .rdx } });
    try expectMachineInstruction(machine.instructions.items, .{ .mov_arg_rax = .rdi });
    try expectMachineInstruction(machine.instructions.items, .{ .spill_rax_rsp = .slot0 });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_arg64_rsp = .{ .reg = .rsi, .frame_index = .slot6 } });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_arg64_rsp = .{ .reg = .r8, .frame_index = .slot4 } });
    try expectMachineInstruction(machine.instructions.items, .{ .mov_arg_rax = .rsi });
    try expectMachineInstruction(machine.instructions.items, .{ .spill_rax_rsp = .slot2 });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_arg64_rsp = .{ .reg = .rdx, .frame_index = .slot8 } });
    try expectMachineInstruction(machine.instructions.items, .{ .mov_arg_rax = .rdx });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_rsp_rax = .slot0 });
    try expectMachineInstruction(machine.instructions.items, .{ .add_stack_disp8_rax = 8 });
}

test "x86_64 codegen preserves indirect two i64 call results and live addend across later pointer-callee void call" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i64 @caller(ptr %first, ptr %second, ptr %touch, i64 %a, i64 %b) {
        \\entry:
        \\  %first_result = call i64 %first(i64 %a)
        \\  %second_result = call i64 %second(i64 %b)
        \\  call void %touch()
        \\  %sum0 = add i64 %first_result, %second_result
        \\  %sum1 = add i64 %sum0, %a
        \\  ret i64 %sum1
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try expectMachineInstruction(machine.instructions.items, .{ .spill_arg64_rsp = .{ .frame_index = .slot4, .reg = .r8 } });
    try expectMachineInstruction(machine.instructions.items, .{ .spill_arg64_rsp = .{ .frame_index = .slot6, .reg = .rsi } });
    try expectMachineInstruction(machine.instructions.items, .{ .spill_arg64_rsp = .{ .frame_index = .slot8, .reg = .rdx } });
    try expectMachineInstruction(machine.instructions.items, .{ .spill_arg64_rsp = .{ .frame_index = .slot10, .reg = .rcx } });
    try expectMachineInstruction(machine.instructions.items, .{ .mov_arg_rax = .rdi });
    try expectMachineInstruction(machine.instructions.items, .{ .spill_rax_rsp = .slot0 });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_arg64_rsp = .{ .reg = .rsi, .frame_index = .slot6 } });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_arg64_rsp = .{ .reg = .r8, .frame_index = .slot4 } });
    try expectMachineInstruction(machine.instructions.items, .{ .mov_arg_rax = .rsi });
    try expectMachineInstruction(machine.instructions.items, .{ .spill_rax_rsp = .slot2 });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_arg64_rsp = .{ .reg = .rdx, .frame_index = .slot8 } });
    try expectMachineInstruction(machine.instructions.items, .{ .mov_arg_rax = .rdx });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_rsp_rax = .slot0 });
    try expectMachineInstruction(machine.instructions.items, .{ .add_stack_disp8_rax = 8 });
    try expectMachineInstruction(machine.instructions.items, .{ .add_stack_disp8_rax = 40 });
}

test "x86_64 codegen preserves indirect two i64 call results with live addend" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i64 @caller(ptr %first, ptr %second, i64 %a, i64 %b) {
        \\entry:
        \\  %first_result = call i64 %first(i64 %a)
        \\  %second_result = call i64 %second(i64 %b)
        \\  %sum0 = add i64 %first_result, %second_result
        \\  %sum1 = add i64 %sum0, %a
        \\  ret i64 %sum1
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try expectMachineInstruction(machine.instructions.items, .{ .spill_arg64_rsp = .{ .frame_index = .slot2, .reg = .rsi } });
    try expectMachineInstruction(machine.instructions.items, .{ .spill_arg64_rsp = .{ .frame_index = .slot4, .reg = .rcx } });
    try expectMachineInstruction(machine.instructions.items, .{ .spill_arg64_rsp = .{ .frame_index = .slot6, .reg = .rdx } });
    try expectMachineInstruction(machine.instructions.items, .{ .mov_arg_rax = .rdi });
    try expectMachineInstruction(machine.instructions.items, .{ .spill_rax_rsp = .slot0 });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_arg64_rsp = .{ .reg = .rsi, .frame_index = .slot2 } });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_arg64_rsp = .{ .reg = .rcx, .frame_index = .slot4 } });
    try expectMachineInstruction(machine.instructions.items, .{ .mov_arg_rax = .rsi });
    try expectMachineInstruction(machine.instructions.items, .{ .add_stack_disp8_rax = 0 });
    try expectMachineInstruction(machine.instructions.items, .{ .add_stack_disp8_rax = 24 });
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
