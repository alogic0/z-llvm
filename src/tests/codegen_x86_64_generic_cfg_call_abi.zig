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
        error.UnsupportedVarargsAbi,
        codegen.x86_64.sysvCallPlanCountsForTest(std.testing.allocator, module.functions.items[0], call),
    );
}

test "x86_64 SysV call planner rejects indirect varargs explicitly" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @caller(ptr %fn, ptr %fmt) {
        \\entry:
        \\  %r = call i32 (ptr, ...) %fn(ptr %fmt, i32 7)
        \\  ret i32 %r
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    const call = module.functions.items[0].blocks.items[0].instructions.items[0].kind.call;
    try std.testing.expect(call.callee_value != null);
    try std.testing.expectError(
        error.UnsupportedVarargsAbi,
        codegen.x86_64.sysvCallPlanCountsForTest(std.testing.allocator, module.functions.items[0], call),
    );
    try std.testing.expectError(
        error.UnsupportedVarargsAbi,
        codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]),
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
        error.UnsupportedTailCallAbi,
        codegen.x86_64.sysvCallPlanCountsForTest(std.testing.allocator, tail_module.functions.items[0], tail_call),
    );

    const indirect_tail_input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @caller(ptr %fn, i32 %a) {
        \\entry:
        \\  %r = tail call i32 %fn(i32 %a)
        \\  ret i32 %r
        \\}
        \\
    ;
    var indirect_tail_module = try ir.Module.parse(std.testing.allocator, indirect_tail_input);
    defer indirect_tail_module.deinit();
    try indirect_tail_module.verify();
    const indirect_tail_call = indirect_tail_module.functions.items[0].blocks.items[0].instructions.items[0].kind.call;
    try std.testing.expect(indirect_tail_call.callee_value != null);
    try std.testing.expectError(
        error.UnsupportedTailCallAbi,
        codegen.x86_64.sysvCallPlanCountsForTest(std.testing.allocator, indirect_tail_module.functions.items[0], indirect_tail_call),
    );
    try std.testing.expectError(
        error.UnsupportedTailCallAbi,
        codegen.x86_64.lowerFunction(std.testing.allocator, indirect_tail_module.target_triple.?, indirect_tail_module.functions.items[0]),
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
        error.UnsupportedCallConvAbi,
        codegen.x86_64.sysvCallPlanCountsForTest(std.testing.allocator, callconv_module.functions.items[0], callconv_call),
    );

    const indirect_callconv_input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @caller(ptr %fn, i32 %a) {
        \\entry:
        \\  %r = call coldcc i32 %fn(i32 %a)
        \\  ret i32 %r
        \\}
        \\
    ;
    var indirect_callconv_module = try ir.Module.parse(std.testing.allocator, indirect_callconv_input);
    defer indirect_callconv_module.deinit();
    try indirect_callconv_module.verify();
    const indirect_callconv_call = indirect_callconv_module.functions.items[0].blocks.items[0].instructions.items[0].kind.call;
    try std.testing.expect(indirect_callconv_call.callee_value != null);
    try std.testing.expectError(
        error.UnsupportedCallConvAbi,
        codegen.x86_64.sysvCallPlanCountsForTest(std.testing.allocator, indirect_callconv_module.functions.items[0], indirect_callconv_call),
    );
    try std.testing.expectError(
        error.UnsupportedCallConvAbi,
        codegen.x86_64.lowerFunction(std.testing.allocator, indirect_callconv_module.target_triple.?, indirect_callconv_module.functions.items[0]),
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

test "x86_64 SysV call planner assigns memory aggregates through stack passthrough" {
    const direct_input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare i32 @callee({ i64, i64, i64 })
        \\
        \\define i32 @caller({ i64, i64, i64 } %value) {
        \\entry:
        \\  %r = call i32 @callee({ i64, i64, i64 } %value)
        \\  ret i32 %r
        \\}
        \\
    ;
    var direct_module = try ir.Module.parse(std.testing.allocator, direct_input);
    defer direct_module.deinit();
    try direct_module.verify();
    const direct_call = direct_module.functions.items[0].blocks.items[0].instructions.items[0].kind.call;
    const direct_counts = try codegen.x86_64.sysvCallPlanCountsForTest(std.testing.allocator, direct_module.functions.items[0], direct_call);
    try std.testing.expectEqual(@as(usize, 3), direct_counts.stack_args);
    try std.testing.expectEqual(@as(usize, 0), direct_counts.register_aggregate_args);
    try std.testing.expectEqual(@as(usize, 1), direct_counts.gpr_returns);

    const indirect_input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @caller(ptr %fn, { i64, i64, i64 } %value) {
        \\entry:
        \\  %r = call i32 %fn({ i64, i64, i64 } %value)
        \\  ret i32 %r
        \\}
        \\
    ;
    var indirect_module = try ir.Module.parse(std.testing.allocator, indirect_input);
    defer indirect_module.deinit();
    try indirect_module.verify();
    const indirect_call = indirect_module.functions.items[0].blocks.items[0].instructions.items[0].kind.call;
    try std.testing.expect(indirect_call.callee_value != null);
    const indirect_counts = try codegen.x86_64.sysvCallPlanCountsForTest(std.testing.allocator, indirect_module.functions.items[0], indirect_call);
    try std.testing.expectEqual(direct_counts.stack_args, indirect_counts.stack_args);
    try std.testing.expectEqual(direct_counts.gpr_returns, indirect_counts.gpr_returns);
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
        error.UnsupportedVectorAbi,
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
        error.UnsupportedVectorAbi,
        codegen.x86_64.sysvCallPlanCountsForTest(std.testing.allocator, module.functions.items[0], call),
    );
}

test "x86_64 SysV call planner rejects vector-containing aggregate ABI boundary" {
    var args: std.ArrayList(ir.CallArg) = .empty;
    defer args.deinit(std.testing.allocator);
    try args.append(std.testing.allocator, .{
        .ty = .{ .aggregate = "{ <2 x i32>, i32 }" },
        .value = .undef,
    });

    const call: ir.CallInst = .{
        .ret_ty = .{ .int = 32 },
        .callee = "callee",
        .args = args,
    };
    const function: ir.Function = .{
        .name = "caller",
        .ret_ty = .{ .int = 32 },
        .blocks = .empty,
        .params = .empty,
    };
    try std.testing.expectError(
        error.UnsupportedVectorAbi,
        codegen.x86_64.sysvCallPlanCountsForTest(std.testing.allocator, function, call),
    );
    try std.testing.expectError(
        error.UnsupportedVectorAbi,
        codegen.x86_64.sysvReturnPlanCountsForTest(.{ .aggregate = "{ <2 x i32>, i32 }" }),
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
        error.UnsupportedLongDoubleAbi,
        codegen.x86_64.sysvCallPlanCountsForTest(std.testing.allocator, module.functions.items[0], call),
    );
}

test "x86_64 SysV call planner rejects X87-containing aggregate ABI boundary" {
    var args: std.ArrayList(ir.CallArg) = .empty;
    defer args.deinit(std.testing.allocator);
    try args.append(std.testing.allocator, .{
        .ty = .{ .aggregate = "{ x86_fp80, i32 }" },
        .value = .undef,
    });

    const call: ir.CallInst = .{
        .ret_ty = .{ .int = 32 },
        .callee = "callee",
        .args = args,
    };
    const function: ir.Function = .{
        .name = "caller",
        .ret_ty = .{ .int = 32 },
        .blocks = .empty,
        .params = .empty,
    };
    try std.testing.expectError(
        error.UnsupportedLongDoubleAbi,
        codegen.x86_64.sysvCallPlanCountsForTest(std.testing.allocator, function, call),
    );
    try std.testing.expectError(
        error.UnsupportedLongDoubleAbi,
        codegen.x86_64.sysvReturnPlanCountsForTest(.{ .aggregate = "{ x86_fp80, i32 }" }),
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

test "x86_64 SysV call planner rejects packed aggregate call args directly" {
    var args: std.ArrayList(ir.CallArg) = .empty;
    defer args.deinit(std.testing.allocator);
    try args.append(std.testing.allocator, .{
        .ty = .{ .aggregate = "<{ i8, i64 }>" },
        .value = .undef,
    });

    const call: ir.CallInst = .{
        .ret_ty = .{ .int = 32 },
        .callee = "callee",
        .args = args,
    };
    const function: ir.Function = .{
        .name = "caller",
        .ret_ty = .{ .int = 32 },
        .blocks = .empty,
        .params = .empty,
    };
    try std.testing.expectError(
        error.UnsupportedPackedAggregateAbi,
        codegen.x86_64.sysvCallPlanCountsForTest(std.testing.allocator, function, call),
    );
}

test "x86_64 SysV call planner rejects packed sret and byval attributes directly" {
    const sret_input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare void @callee(ptr sret(<{ i32, i32 }>))
        \\
        \\define void @caller(ptr %out) {
        \\entry:
        \\  call void @callee(ptr sret(<{ i32, i32 }>) %out)
        \\  ret void
        \\}
        \\
    ;
    var sret_module = try ir.Module.parse(std.testing.allocator, sret_input);
    defer sret_module.deinit();
    try sret_module.verify();
    const sret_call = sret_module.functions.items[0].blocks.items[0].instructions.items[0].kind.call;
    try std.testing.expectError(
        error.UnsupportedPackedAggregateAbi,
        codegen.x86_64.sysvCallPlanCountsForTest(std.testing.allocator, sret_module.functions.items[0], sret_call),
    );

    const byval_input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare i32 @callee(ptr byval(<{ i32, i32 }>))
        \\
        \\define i32 @caller(ptr %arg) {
        \\entry:
        \\  %r = call i32 @callee(ptr byval(<{ i32, i32 }>) %arg)
        \\  ret i32 %r
        \\}
        \\
    ;
    var byval_module = try ir.Module.parse(std.testing.allocator, byval_input);
    defer byval_module.deinit();
    try byval_module.verify();
    const byval_call = byval_module.functions.items[0].blocks.items[0].instructions.items[0].kind.call;
    try std.testing.expectError(
        error.UnsupportedPackedAggregateAbi,
        codegen.x86_64.sysvCallPlanCountsForTest(std.testing.allocator, byval_module.functions.items[0], byval_call),
    );
}

test "x86_64 SysV call planner rejects vector sret and byval attributes directly" {
    const sret_input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare void @callee(ptr sret({ <2 x i32>, i32 }))
        \\
        \\define void @caller(ptr %out) {
        \\entry:
        \\  call void @callee(ptr sret({ <2 x i32>, i32 }) %out)
        \\  ret void
        \\}
        \\
    ;
    var sret_module = try ir.Module.parse(std.testing.allocator, sret_input);
    defer sret_module.deinit();
    try sret_module.verify();
    const sret_call = sret_module.functions.items[0].blocks.items[0].instructions.items[0].kind.call;
    try std.testing.expectError(
        error.UnsupportedVectorAbi,
        codegen.x86_64.sysvCallPlanCountsForTest(std.testing.allocator, sret_module.functions.items[0], sret_call),
    );

    const byval_input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare i32 @callee(ptr byval({ <2 x i32>, i32 }))
        \\
        \\define i32 @caller(ptr %arg) {
        \\entry:
        \\  %r = call i32 @callee(ptr byval({ <2 x i32>, i32 }) %arg)
        \\  ret i32 %r
        \\}
        \\
    ;
    var byval_module = try ir.Module.parse(std.testing.allocator, byval_input);
    defer byval_module.deinit();
    try byval_module.verify();
    const byval_call = byval_module.functions.items[0].blocks.items[0].instructions.items[0].kind.call;
    try std.testing.expectError(
        error.UnsupportedVectorAbi,
        codegen.x86_64.sysvCallPlanCountsForTest(std.testing.allocator, byval_module.functions.items[0], byval_call),
    );
}

test "x86_64 SysV call planner rejects long-double sret and byval attributes directly" {
    const sret_input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare void @callee(ptr sret({ x86_fp80, i32 }))
        \\
        \\define void @caller(ptr %out) {
        \\entry:
        \\  call void @callee(ptr sret({ x86_fp80, i32 }) %out)
        \\  ret void
        \\}
        \\
    ;
    var sret_module = try ir.Module.parse(std.testing.allocator, sret_input);
    defer sret_module.deinit();
    try sret_module.verify();
    const sret_call = sret_module.functions.items[0].blocks.items[0].instructions.items[0].kind.call;
    try std.testing.expectError(
        error.UnsupportedLongDoubleAbi,
        codegen.x86_64.sysvCallPlanCountsForTest(std.testing.allocator, sret_module.functions.items[0], sret_call),
    );

    const byval_input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare i32 @callee(ptr byval({ fp128, i32 }))
        \\
        \\define i32 @caller(ptr %arg) {
        \\entry:
        \\  %r = call i32 @callee(ptr byval({ fp128, i32 }) %arg)
        \\  ret i32 %r
        \\}
        \\
    ;
    var byval_module = try ir.Module.parse(std.testing.allocator, byval_input);
    defer byval_module.deinit();
    try byval_module.verify();
    const byval_call = byval_module.functions.items[0].blocks.items[0].instructions.items[0].kind.call;
    try std.testing.expectError(
        error.UnsupportedLongDoubleAbi,
        codegen.x86_64.sysvCallPlanCountsForTest(std.testing.allocator, byval_module.functions.items[0], byval_call),
    );
}

test "x86_64 SysV return planner rejects explicit ABI boundaries" {
    try std.testing.expectError(
        error.UnsupportedPackedAggregateAbi,
        codegen.x86_64.sysvReturnPlanCountsForTest(.{ .aggregate = "<{ i8, i64 }" }),
    );
    try std.testing.expectError(
        error.UnsupportedVectorAbi,
        codegen.x86_64.sysvReturnPlanCountsForTest(.{ .vector = .{ .len = 2, .elem_ty = .{ .int = 64 } } }),
    );
    try std.testing.expectError(
        error.UnsupportedLongDoubleAbi,
        codegen.x86_64.sysvReturnPlanCountsForTest(.x86_fp80),
    );
    try std.testing.expectError(
        error.UnsupportedLongDoubleAbi,
        codegen.x86_64.sysvReturnPlanCountsForTest(.fp128),
    );
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
        error.UnsupportedVectorAbi,
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
        error.UnsupportedVarargsAbi,
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
        error.UnsupportedSretByvalAbi,
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
        error.UnsupportedSretByvalAbi,
        codegen.x86_64.lowerFunction(std.testing.allocator, byval_module.target_triple.?, byval_module.functions.items[0]),
    );
}

test "x86_64 codegen accepts memory aggregate stack call and rejects vector return boundary" {
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
    var aggregate_machine = try codegen.x86_64.lowerFunction(std.testing.allocator, aggregate_module.target_triple.?, aggregate_module.functions.items[0]);
    defer aggregate_machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, aggregate_machine.codegen_path);
    try expectMachineInstruction(aggregate_machine.instructions.items, .{ .push_stack_disp8 = 24 });
    var saw_direct_call = false;
    for (aggregate_machine.instructions.items) |instruction| switch (instruction) {
        .direct_call => |call| {
            saw_direct_call = true;
            try std.testing.expectEqualStrings("callee", call.symbol);
            try std.testing.expect(call.ret_ty.eql(.{ .int = 32 }));
        },
        else => {},
    };
    try std.testing.expect(saw_direct_call);

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
        error.UnsupportedVectorAbi,
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
        error.UnsupportedLongDoubleAbi,
        codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]),
    );
}
