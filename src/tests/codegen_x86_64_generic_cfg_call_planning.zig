const codegen_x86_64_common = @import("codegen_x86_64_common.zig");

const std = codegen_x86_64_common.std;
const abi_boundaries = codegen_x86_64_common.abi_boundaries;
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

test "x86_64 generic CFG returns sub-byte integer parameter from GPR" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define fastcc i2 @callee(i2 %tag) {
        \\entry:
        \\  ret i2 %tag
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

test "x86_64 SysV call planner assigns ninth f64 arg to stack" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare double @callee(double, double, double, double, double, double, double, double, double)
        \\
        \\define double @caller(double %a, double %b, double %c, double %d, double %e, double %f, double %g, double %h, double %i) {
        \\entry:
        \\  %r = call double @callee(double %a, double %b, double %c, double %d, double %e, double %f, double %g, double %h, double %i)
        \\  ret double %r
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    const call = module.functions.items[0].blocks.items[0].instructions.items[0].kind.call;
    const counts = try codegen.x86_64.sysvCallPlanCountsForTest(std.testing.allocator, module.functions.items[0], call);
    try std.testing.expectEqual(@as(usize, 0), counts.gpr_args);
    try std.testing.expectEqual(@as(usize, 8), counts.sse_args);
    try std.testing.expectEqual(@as(usize, 1), counts.stack_args);
    try std.testing.expectEqual(@as(usize, 0), counts.register_aggregate_args);
    try std.testing.expectEqual(@as(usize, 0), counts.gpr_returns);
    try std.testing.expectEqual(@as(usize, 1), counts.sse_returns);
    try std.testing.expect(!counts.memory_return);
}

test "x86_64 SysV call planner assigns ninth f32 arg to stack" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare float @callee(float, float, float, float, float, float, float, float, float)
        \\
        \\define float @caller(float %a, float %b, float %c, float %d, float %e, float %f, float %g, float %h, float %i) {
        \\entry:
        \\  %r = call float @callee(float %a, float %b, float %c, float %d, float %e, float %f, float %g, float %h, float %i)
        \\  ret float %r
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    const call = module.functions.items[0].blocks.items[0].instructions.items[0].kind.call;
    const counts = try codegen.x86_64.sysvCallPlanCountsForTest(std.testing.allocator, module.functions.items[0], call);
    try std.testing.expectEqual(@as(usize, 0), counts.gpr_args);
    try std.testing.expectEqual(@as(usize, 8), counts.sse_args);
    try std.testing.expectEqual(@as(usize, 1), counts.stack_args);
    try std.testing.expectEqual(@as(usize, 0), counts.register_aggregate_args);
    try std.testing.expectEqual(@as(usize, 0), counts.gpr_returns);
    try std.testing.expectEqual(@as(usize, 1), counts.sse_returns);
    try std.testing.expect(!counts.memory_return);
}

test "x86_64 SysV call planner assigns ninth FP constants to stack" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare float @callee_f32(float, float, float, float, float, float, float, float, float)
        \\declare double @callee_f64(double, double, double, double, double, double, double, double, double)
        \\
        \\define float @caller_f32() {
        \\entry:
        \\  %r = call float @callee_f32(float 1.000000e+00, float 2.000000e+00, float 3.000000e+00, float 4.000000e+00, float 5.000000e+00, float 6.000000e+00, float 7.000000e+00, float 8.000000e+00, float 9.000000e+00)
        \\  ret float %r
        \\}
        \\
        \\define double @caller_f64() {
        \\entry:
        \\  %r = call double @callee_f64(double 1.000000e+00, double 2.000000e+00, double 3.000000e+00, double 4.000000e+00, double 5.000000e+00, double 6.000000e+00, double 7.000000e+00, double 8.000000e+00, double 9.000000e+00)
        \\  ret double %r
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    inline for (.{ 0, 1 }) |function_index| {
        const call = module.functions.items[function_index].blocks.items[0].instructions.items[0].kind.call;
        const counts = try codegen.x86_64.sysvCallPlanCountsForTest(std.testing.allocator, module.functions.items[function_index], call);
        try std.testing.expectEqual(@as(usize, 0), counts.gpr_args);
        try std.testing.expectEqual(@as(usize, 8), counts.sse_args);
        try std.testing.expectEqual(@as(usize, 1), counts.stack_args);
        try std.testing.expectEqual(@as(usize, 0), counts.register_aggregate_args);
        try std.testing.expectEqual(@as(usize, 0), counts.gpr_returns);
        try std.testing.expectEqual(@as(usize, 1), counts.sse_returns);
        try std.testing.expect(!counts.memory_return);
    }
}

test "x86_64 SysV call planner assigns pointer args through GPR stream" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare i32 @callee(ptr, i64, ptr)
        \\
        \\define i32 @caller(ptr %a, i64 %b, ptr %c) {
        \\entry:
        \\  %r = call i32 @callee(ptr %a, i64 %b, ptr %c)
        \\  ret i32 %r
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    const call = module.functions.items[0].blocks.items[0].instructions.items[0].kind.call;
    const counts = try codegen.x86_64.sysvCallPlanCountsForTest(std.testing.allocator, module.functions.items[0], call);
    try std.testing.expectEqual(@as(usize, 3), counts.gpr_args);
    try std.testing.expectEqual(@as(usize, 0), counts.sse_args);
    try std.testing.expectEqual(@as(usize, 0), counts.stack_args);
    try std.testing.expectEqual(@as(usize, 1), counts.gpr_returns);
}

test "x86_64 generic CFG lowers direct pointer call args through planner" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare i32 @callee(ptr)
        \\
        \\define i32 @caller(ptr %a, ptr %b) {
        \\entry:
        \\  %r = call i32 @callee(ptr %b)
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
    try expectMachineInstruction(machine.instructions.items, .{ .mov_arg64_arg = .{ .dst = .rdi, .src = .rsi } });
    var saw_call = false;
    for (machine.instructions.items) |instruction| switch (instruction) {
        .direct_call => |call| {
            saw_call = true;
            try std.testing.expectEqualStrings("callee", call.symbol);
            try std.testing.expect(call.ret_ty.eql(.{ .int = 32 }));
        },
        else => {},
    };
    try std.testing.expect(saw_call);
}

test "x86_64 generic CFG lowers cyclic i32 GPR arg register shuffle with parallel copy" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare i32 @callee(i32, i32)
        \\
        \\define i32 @caller(i32 %a, i32 %b) {
        \\entry:
        \\  %r = call i32 @callee(i32 %b, i32 %a)
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
    try expectMachineInstruction(machine.instructions.items, .{ .push_arg = .rsi });
    try expectMachineInstruction(machine.instructions.items, .{ .push_arg = .rdi });
    try expectMachineInstruction(machine.instructions.items, .{ .pop_arg = .rsi });
    try expectMachineInstruction(machine.instructions.items, .{ .pop_arg = .rdi });
    var saw_call = false;
    for (machine.instructions.items) |instruction| switch (instruction) {
        .direct_call => |call| {
            saw_call = true;
            try std.testing.expectEqualStrings("callee", call.symbol);
            try std.testing.expect(call.ret_ty.eql(.{ .int = 32 }));
        },
        else => {},
    };
    try std.testing.expect(saw_call);
}

test "x86_64 generic CFG lowers cyclic i64 GPR arg register shuffle with parallel copy" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare i64 @callee(i64, i64)
        \\
        \\define i64 @caller(i64 %a, i64 %b) {
        \\entry:
        \\  %r = call i64 @callee(i64 %b, i64 %a)
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
    try expectMachineInstruction(machine.instructions.items, .{ .push_arg = .rsi });
    try expectMachineInstruction(machine.instructions.items, .{ .push_arg = .rdi });
    try expectMachineInstruction(machine.instructions.items, .{ .pop_arg = .rsi });
    try expectMachineInstruction(machine.instructions.items, .{ .pop_arg = .rdi });
    var saw_call = false;
    for (machine.instructions.items) |instruction| switch (instruction) {
        .direct_call => |call| {
            saw_call = true;
            try std.testing.expectEqualStrings("callee", call.symbol);
            try std.testing.expect(call.ret_ty.eql(.{ .int = 64 }));
        },
        else => {},
    };
    try std.testing.expect(saw_call);
}

test "x86_64 generic CFG lowers cyclic f32 XMM arg register shuffle with temporary stack copy" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare float @callee(float, float)
        \\
        \\define float @caller(float %a, float %b) {
        \\entry:
        \\  %r = call float @callee(float %b, float %a)
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
    try expectMachineInstruction(machine.instructions.items, .{ .push_xmm64 = .xmm1 });
    try expectMachineInstruction(machine.instructions.items, .{ .push_xmm64 = .xmm0 });
    try expectMachineInstruction(machine.instructions.items, .{ .load_stack_disp8_xmm = .{ .reg = .xmm0, .disp = 8 } });
    try expectMachineInstruction(machine.instructions.items, .{ .load_stack_disp8_xmm = .{ .reg = .xmm1, .disp = 0 } });
    try expectMachineInstruction(machine.instructions.items, .{ .add_rsp_imm8 = 16 });
    var saw_call = false;
    for (machine.instructions.items) |instruction| switch (instruction) {
        .direct_call => |call| {
            saw_call = true;
            try std.testing.expectEqualStrings("callee", call.symbol);
            try std.testing.expect(call.ret_ty.eql(.float));
        },
        else => {},
    };
    try std.testing.expect(saw_call);
}

test "x86_64 generic CFG lowers cyclic f64 XMM arg register shuffle with temporary stack copy" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare double @callee(double, double)
        \\
        \\define double @caller(double %a, double %b) {
        \\entry:
        \\  %r = call double @callee(double %b, double %a)
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
    try expectMachineInstruction(machine.instructions.items, .{ .push_xmm64 = .xmm1 });
    try expectMachineInstruction(machine.instructions.items, .{ .push_xmm64 = .xmm0 });
    try expectMachineInstruction(machine.instructions.items, .{ .load_stack_disp8_xmm = .{ .reg = .xmm0, .disp = 8 } });
    try expectMachineInstruction(machine.instructions.items, .{ .load_stack_disp8_xmm = .{ .reg = .xmm1, .disp = 0 } });
    try expectMachineInstruction(machine.instructions.items, .{ .add_rsp_imm8 = 16 });
    var saw_call = false;
    for (machine.instructions.items) |instruction| switch (instruction) {
        .direct_call => |call| {
            saw_call = true;
            try std.testing.expectEqualStrings("callee", call.symbol);
            try std.testing.expect(call.ret_ty.eql(.double));
        },
        else => {},
    };
    try std.testing.expect(saw_call);
}

test "x86_64 generic CFG lowers indirect pointer call args through planner" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @caller(ptr %fn, ptr %a, ptr %b) {
        \\entry:
        \\  %r = call i32 %fn(ptr %a, ptr %b)
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
    try expectMachineInstruction(machine.instructions.items, .{ .mov_arg64_arg = .{ .dst = .rdi, .src = .rsi } });
    try expectMachineInstruction(machine.instructions.items, .{ .mov_arg64_arg = .{ .dst = .rsi, .src = .rdx } });
    var saw_call = false;
    for (machine.instructions.items) |instruction| switch (instruction) {
        .indirect_call_rax => |ret_ty| {
            saw_call = true;
            try std.testing.expect(ret_ty.eql(.{ .int = 32 }));
        },
        else => {},
    };
    try std.testing.expect(saw_call);
}

test "x86_64 generic CFG lowers stack-passed pointer call args through planner" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare i32 @callee(ptr, ptr, ptr, ptr, ptr, ptr, ptr, ptr)
        \\
        \\define i32 @caller(ptr %a, ptr %b, ptr %c, ptr %d, ptr %e, ptr %f, ptr %g, ptr %h) {
        \\entry:
        \\  %r = call i32 @callee(ptr %a, ptr %b, ptr %c, ptr %d, ptr %e, ptr %f, ptr %g, ptr %h)
        \\  ret i32 %r
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    const call_inst = module.functions.items[0].blocks.items[0].instructions.items[0].kind.call;
    const counts = try codegen.x86_64.sysvCallPlanCountsForTest(std.testing.allocator, module.functions.items[0], call_inst);
    try std.testing.expectEqual(@as(usize, 6), counts.gpr_args);
    try std.testing.expectEqual(@as(usize, 2), counts.stack_args);

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try expectMachineInstruction(machine.instructions.items, .sub_rsp_8);
    try expectMachineInstruction(machine.instructions.items, .{ .push_stack_disp8 = 24 });
    var saw_call = false;
    for (machine.instructions.items) |instruction| switch (instruction) {
        .direct_call => |call| {
            saw_call = true;
            try std.testing.expectEqualStrings("callee", call.symbol);
            try std.testing.expect(call.ret_ty.eql(.{ .int = 32 }));
        },
        else => {},
    };
    try std.testing.expect(saw_call);
}

test "x86_64 generic CFG lowers null pointer call args through planner" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare i32 @callee(ptr, ptr, ptr, ptr, ptr, ptr, ptr)
        \\
        \\define i32 @caller(ptr %a, ptr %b, ptr %c, ptr %d, ptr %e, ptr %f) {
        \\entry:
        \\  %r = call i32 @callee(ptr %a, ptr %b, ptr %c, ptr %d, ptr %e, ptr %f, ptr null)
        \\  ret i32 %r
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    const call_inst = module.functions.items[0].blocks.items[0].instructions.items[0].kind.call;
    const counts = try codegen.x86_64.sysvCallPlanCountsForTest(std.testing.allocator, module.functions.items[0], call_inst);
    try std.testing.expectEqual(@as(usize, 6), counts.gpr_args);
    try std.testing.expectEqual(@as(usize, 1), counts.stack_args);

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    try expectMachineInstruction(machine.instructions.items, .{ .push_imm32 = 0 });
    var saw_call = false;
    for (machine.instructions.items) |instruction| switch (instruction) {
        .direct_call => |call| {
            saw_call = true;
            try std.testing.expectEqualStrings("callee", call.symbol);
            try std.testing.expect(call.ret_ty.eql(.{ .int = 32 }));
        },
        else => {},
    };
    try std.testing.expect(saw_call);
}

test "x86_64 generic CFG returns pointer parameter in rax" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define ptr @caller(i32 %tag, ptr %value) {
        \\entry:
        \\  ret ptr %value
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

test "x86_64 generic CFG returns direct pointer call result" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare ptr @callee(ptr, i64)
        \\
        \\define ptr @caller(ptr %value, i64 %tag) {
        \\entry:
        \\  %r = call ptr @callee(ptr %value, i64 %tag)
        \\  ret ptr %r
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
    var saw_call = false;
    for (machine.instructions.items) |instruction| switch (instruction) {
        .direct_call => |call| {
            saw_call = true;
            try std.testing.expectEqualStrings("callee", call.symbol);
            try std.testing.expect(call.ret_ty.eql(.ptr));
        },
        else => {},
    };
    try std.testing.expect(saw_call);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[machine.instructions.items.len - 1]);
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

test "x86_64 generic CFG forwards stack-sourced mixed aggregate to registers" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare i64 @mixed_int({ i64, double })
        \\
        \\define i64 @caller(i64 %i0, i64 %i1, i64 %i2, i64 %i3, i64 %i4, i64 %i5, double %f0, double %f1, double %f2, double %f3, double %f4, double %f5, double %f6, double %f7, { i64, double } %value) {
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
    try expectMachineInstruction(machine.instructions.items, .{ .load_stack_disp8_arg64 = .{ .reg = .rdi, .disp = 8 } });
    try expectMachineInstruction(machine.instructions.items, .{ .load_stack_disp8_xmm = .{ .reg = .xmm0, .disp = 16 } });
    var load_gpr_index: ?usize = null;
    var load_sse_index: ?usize = null;
    var call_index: ?usize = null;
    for (machine.instructions.items, 0..) |instruction, index| {
        switch (instruction) {
            .load_stack_disp8_arg64 => |load| {
                if (load.reg == .rdi and load.disp == 8) load_gpr_index = index;
            },
            .load_stack_disp8_xmm => |load| {
                if (load.reg == .xmm0 and load.disp == 16) load_sse_index = index;
            },
            .direct_call => |direct_call| {
                if (std.mem.eql(u8, direct_call.symbol, "mixed_int")) call_index = index;
            },
            else => {},
        }
    }
    try std.testing.expect((load_gpr_index orelse return error.TestExpectedEqual) < (call_index orelse return error.TestExpectedEqual));
    try std.testing.expect((load_sse_index orelse return error.TestExpectedEqual) < (call_index orelse return error.TestExpectedEqual));
}

test "x86_64 generic CFG forwards stack-sourced mixed aggregate through pointer callee" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i64 @caller(ptr %fn, i64 %i0, i64 %i1, i64 %i2, i64 %i3, i64 %i4, double %f0, double %f1, double %f2, double %f3, double %f4, double %f5, double %f6, double %f7, { i64, double } %value) {
        \\entry:
        \\  %r = call i64 %fn({ i64, double } %value)
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
    var target_setup_index: ?usize = null;
    var load_gpr_index: ?usize = null;
    var load_sse_index: ?usize = null;
    var call_index: ?usize = null;
    for (machine.instructions.items, 0..) |instruction, index| {
        switch (instruction) {
            .mov_arg_rax => |reg| {
                if (reg == .rdi) target_setup_index = index;
            },
            .load_stack_disp8_arg64 => |load| {
                if (load.reg == .rdi and load.disp == 8) load_gpr_index = index;
            },
            .load_stack_disp8_xmm => |load| {
                if (load.reg == .xmm0 and load.disp == 16) load_sse_index = index;
            },
            .indirect_call_rax => |ret_ty| {
                if (ret_ty.eql(.{ .int = 64 })) call_index = index;
            },
            else => {},
        }
    }
    try std.testing.expect((target_setup_index orelse return error.TestExpectedEqual) < (load_gpr_index orelse return error.TestExpectedEqual));
    try std.testing.expect((load_gpr_index orelse return error.TestExpectedEqual) < (call_index orelse return error.TestExpectedEqual));
    try std.testing.expect((load_sse_index orelse return error.TestExpectedEqual) < (call_index orelse return error.TestExpectedEqual));
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
        abi_boundaries.Category.varargs.errorValue(),
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
        abi_boundaries.Category.varargs.errorValue(),
        codegen.x86_64.sysvCallPlanCountsForTest(std.testing.allocator, module.functions.items[0], call),
    );
    try std.testing.expectError(
        abi_boundaries.Category.varargs.errorValue(),
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
        abi_boundaries.Category.tail_call.errorValue(),
        codegen.x86_64.sysvCallPlanCountsForTest(std.testing.allocator, tail_module.functions.items[0], tail_call),
    );
    try std.testing.expectError(
        abi_boundaries.Category.tail_call.errorValue(),
        codegen.x86_64.lowerFunction(std.testing.allocator, tail_module.target_triple.?, tail_module.functions.items[0]),
    );

    const musttail_input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare i32 @callee(i32)
        \\
        \\define i32 @caller(i32 %a) {
        \\entry:
        \\  %r = musttail call i32 @callee(i32 %a)
        \\  ret i32 %r
        \\}
        \\
    ;
    var musttail_module = try ir.Module.parse(std.testing.allocator, musttail_input);
    defer musttail_module.deinit();
    try musttail_module.verify();
    const musttail_call = musttail_module.functions.items[0].blocks.items[0].instructions.items[0].kind.call;
    try std.testing.expectError(
        abi_boundaries.Category.tail_call.errorValue(),
        codegen.x86_64.sysvCallPlanCountsForTest(std.testing.allocator, musttail_module.functions.items[0], musttail_call),
    );
    try std.testing.expectError(
        abi_boundaries.Category.tail_call.errorValue(),
        codegen.x86_64.lowerFunction(std.testing.allocator, musttail_module.target_triple.?, musttail_module.functions.items[0]),
    );

    const notail_input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare void @callee(i32)
        \\
        \\define void @caller(i32 %a) {
        \\entry:
        \\  notail call void @callee(i32 %a)
        \\  ret void
        \\}
        \\
    ;
    var notail_module = try ir.Module.parse(std.testing.allocator, notail_input);
    defer notail_module.deinit();
    try notail_module.verify();
    const notail_call = notail_module.functions.items[0].blocks.items[0].instructions.items[0].kind.call;
    try std.testing.expectError(
        abi_boundaries.Category.tail_call.errorValue(),
        codegen.x86_64.sysvCallPlanCountsForTest(std.testing.allocator, notail_module.functions.items[0], notail_call),
    );
    try std.testing.expectError(
        abi_boundaries.Category.tail_call.errorValue(),
        codegen.x86_64.lowerFunction(std.testing.allocator, notail_module.target_triple.?, notail_module.functions.items[0]),
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
        abi_boundaries.Category.tail_call.errorValue(),
        codegen.x86_64.sysvCallPlanCountsForTest(std.testing.allocator, indirect_tail_module.functions.items[0], indirect_tail_call),
    );
    try std.testing.expectError(
        abi_boundaries.Category.tail_call.errorValue(),
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
        abi_boundaries.Category.non_default_callconv.errorValue(),
        codegen.x86_64.sysvCallPlanCountsForTest(std.testing.allocator, callconv_module.functions.items[0], callconv_call),
    );
    try std.testing.expectError(
        abi_boundaries.Category.non_default_callconv.errorValue(),
        codegen.x86_64.lowerFunction(std.testing.allocator, callconv_module.target_triple.?, callconv_module.functions.items[0]),
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
        abi_boundaries.Category.non_default_callconv.errorValue(),
        codegen.x86_64.sysvCallPlanCountsForTest(std.testing.allocator, indirect_callconv_module.functions.items[0], indirect_callconv_call),
    );
    try std.testing.expectError(
        abi_boundaries.Category.non_default_callconv.errorValue(),
        codegen.x86_64.lowerFunction(std.testing.allocator, indirect_callconv_module.target_triple.?, indirect_callconv_module.functions.items[0]),
    );
}
