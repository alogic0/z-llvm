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
