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
        abi_boundaries.Category.vector.errorValue(),
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
        abi_boundaries.Category.vector.errorValue(),
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
        abi_boundaries.Category.vector.errorValue(),
        codegen.x86_64.sysvCallPlanCountsForTest(std.testing.allocator, function, call),
    );
    try std.testing.expectError(
        abi_boundaries.Category.vector.errorValue(),
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
        abi_boundaries.Category.x87.errorValue(),
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
        abi_boundaries.Category.x87.errorValue(),
        codegen.x86_64.sysvCallPlanCountsForTest(std.testing.allocator, function, call),
    );
    try std.testing.expectError(
        abi_boundaries.Category.x87.errorValue(),
        codegen.x86_64.sysvReturnPlanCountsForTest(.{ .aggregate = "{ x86_fp80, i32 }" }),
    );
}

test "packed aggregate signatures parse but retain the explicit ABI boundary" {
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
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    const function = module.functions.items[0];
    const call = function.blocks.items[0].instructions.items[0].kind.call;
    try std.testing.expectError(error.UnsupportedPackedAggregateAbi, codegen.x86_64.sysvCallPlanCountsForTest(std.testing.allocator, function, call));
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
        abi_boundaries.Category.packed_aggregate.errorValue(),
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
        abi_boundaries.Category.packed_aggregate.errorValue(),
        codegen.x86_64.sysvCallPlanCountsForTest(std.testing.allocator, sret_module.functions.items[0], sret_call),
    );
    try std.testing.expectError(
        abi_boundaries.Category.packed_aggregate.errorValue(),
        codegen.x86_64.lowerFunction(std.testing.allocator, sret_module.target_triple.?, sret_module.functions.items[0]),
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
        abi_boundaries.Category.packed_aggregate.errorValue(),
        codegen.x86_64.sysvCallPlanCountsForTest(std.testing.allocator, byval_module.functions.items[0], byval_call),
    );
    try std.testing.expectError(
        abi_boundaries.Category.packed_aggregate.errorValue(),
        codegen.x86_64.lowerFunction(std.testing.allocator, byval_module.target_triple.?, byval_module.functions.items[0]),
    );
}

test "x86_64 SysV call planner accepts bounded vector sret and rejects vector byval" {
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
    const counts = try codegen.x86_64.sysvCallPlanCountsForTest(std.testing.allocator, sret_module.functions.items[0], sret_call);
    try std.testing.expectEqual(@as(usize, 1), counts.gpr_args);
    var lowered = try codegen.x86_64.lowerFunction(std.testing.allocator, sret_module.target_triple.?, sret_module.functions.items[0]);
    defer lowered.deinit(std.testing.allocator);

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
        abi_boundaries.Category.vector.errorValue(),
        codegen.x86_64.sysvCallPlanCountsForTest(std.testing.allocator, byval_module.functions.items[0], byval_call),
    );
    try std.testing.expectError(
        abi_boundaries.Category.vector.errorValue(),
        codegen.x86_64.lowerFunction(std.testing.allocator, byval_module.target_triple.?, byval_module.functions.items[0]),
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
        abi_boundaries.Category.x87.errorValue(),
        codegen.x86_64.sysvCallPlanCountsForTest(std.testing.allocator, sret_module.functions.items[0], sret_call),
    );
    try std.testing.expectError(
        abi_boundaries.Category.x87.errorValue(),
        codegen.x86_64.lowerFunction(std.testing.allocator, sret_module.target_triple.?, sret_module.functions.items[0]),
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
        abi_boundaries.Category.x87.errorValue(),
        codegen.x86_64.sysvCallPlanCountsForTest(std.testing.allocator, byval_module.functions.items[0], byval_call),
    );
    try std.testing.expectError(
        abi_boundaries.Category.x87.errorValue(),
        codegen.x86_64.lowerFunction(std.testing.allocator, byval_module.target_triple.?, byval_module.functions.items[0]),
    );
}

test "x86_64 SysV return planner rejects explicit ABI boundaries" {
    try std.testing.expectError(
        abi_boundaries.Category.packed_aggregate.errorValue(),
        codegen.x86_64.sysvReturnPlanCountsForTest(.{ .aggregate = "<{ i8, i64 }" }),
    );
    try std.testing.expectError(
        abi_boundaries.Category.vector.errorValue(),
        codegen.x86_64.sysvReturnPlanCountsForTest(.{ .vector = .{ .len = 4, .elem_ty = .{ .int = 64 } } }),
    );
    try std.testing.expectError(
        abi_boundaries.Category.x87.errorValue(),
        codegen.x86_64.sysvReturnPlanCountsForTest(.x86_fp80),
    );
    try std.testing.expectError(
        abi_boundaries.Category.x87.errorValue(),
        codegen.x86_64.sysvReturnPlanCountsForTest(.fp128),
    );
}

test "x86_64 SysV scalar FP and bounded vector returns use the SSE class" {
    inline for (.{ ir.Type.half, ir.Type.float, ir.Type.double, ir.Type{ .vector = .{ .len = 2, .elem_ty = .{ .int = 64 } } }, ir.Type{ .vector = .{ .len = 4, .elem_ty = .{ .int = 32 } } } }) |ty| {
        const counts = try codegen.x86_64.sysvReturnPlanCountsForTest(ty);
        try std.testing.expectEqual(@as(usize, 0), counts.gpr_returns);
        try std.testing.expectEqual(@as(usize, 1), counts.sse_returns);
        try std.testing.expect(!counts.memory_return);
    }
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
        abi_boundaries.Category.vector.errorValue(),
        codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]),
    );
}

test "x86_64 codegen rejects indirect vector call ABI boundary" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @caller(ptr %fn, <2 x i32> %value) {
        \\entry:
        \\  %r = call i32 %fn(<2 x i32> %value)
        \\  ret i32 %r
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    try std.testing.expectError(
        abi_boundaries.Category.vector.errorValue(),
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
        abi_boundaries.Category.varargs.errorValue(),
        codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]),
    );
}

test "x86_64 codegen accepts supported sret pointer call argument" {
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
    const sret_call = sret_module.functions.items[0].blocks.items[0].instructions.items[0].kind.call;
    const counts = try codegen.x86_64.sysvCallPlanCountsForTest(std.testing.allocator, sret_module.functions.items[0], sret_call);
    try std.testing.expectEqual(@as(usize, 2), counts.gpr_args);
    try std.testing.expectEqual(@as(usize, 0), counts.stack_args);
    try std.testing.expect(!codegen.x86_64.sysvScalarCallNeedsStackArgsForTest(sret_call));

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, sret_module.target_triple.?, sret_module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);
    var saw_direct_call = false;
    for (machine.instructions.items) |instruction| switch (instruction) {
        .direct_call => |call| {
            saw_direct_call = true;
            try std.testing.expectEqualStrings("callee", call.symbol);
            try std.testing.expect(call.ret_ty == .void);
        },
        else => {},
    };
    try std.testing.expect(saw_direct_call);
}

test "x86_64 codegen accepts supported sret pointer with stack-passed user arg" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare void @callee(ptr sret({ i64, i64, i64 }), i32, i32, i32, i32, i32, i32)
        \\
        \\define void @caller(ptr %out, i32 %a0, i32 %a1, i32 %a2, i32 %a3, i32 %a4, i32 %a5) {
        \\entry:
        \\  call void @callee(ptr sret({ i64, i64, i64 }) %out, i32 %a0, i32 %a1, i32 %a2, i32 %a3, i32 %a4, i32 %a5)
        \\  ret void
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    const call = module.functions.items[0].blocks.items[0].instructions.items[0].kind.call;
    const counts = try codegen.x86_64.sysvCallPlanCountsForTest(std.testing.allocator, module.functions.items[0], call);
    try std.testing.expectEqual(@as(usize, 6), counts.gpr_args);
    try std.testing.expectEqual(@as(usize, 1), counts.stack_args);
    try std.testing.expect(codegen.x86_64.sysvScalarCallNeedsStackArgsForTest(call));

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);
    try expectMachineInstruction(machine.instructions.items, .{ .push_stack_disp8 = 8 });
    var saw_direct_call = false;
    for (machine.instructions.items) |instruction| switch (instruction) {
        .direct_call => |direct_call| {
            saw_direct_call = true;
            try std.testing.expectEqualStrings("callee", direct_call.symbol);
            try std.testing.expect(direct_call.ret_ty == .void);
        },
        else => {},
    };
    try std.testing.expect(saw_direct_call);
}

test "x86_64 codegen accepts indirect sret pointer with stack-passed user arg" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define void @caller(ptr %fn, ptr %out, i32 %a0, i32 %a1, i32 %a2, i32 %a3, i32 %a4, i32 %a5) {
        \\entry:
        \\  call void %fn(ptr sret({ i64, i64, i64 }) %out, i32 %a0, i32 %a1, i32 %a2, i32 %a3, i32 %a4, i32 %a5)
        \\  ret void
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    const call = module.functions.items[0].blocks.items[0].instructions.items[0].kind.call;
    try std.testing.expect(call.callee_value != null);
    const counts = try codegen.x86_64.sysvCallPlanCountsForTest(std.testing.allocator, module.functions.items[0], call);
    try std.testing.expectEqual(@as(usize, 6), counts.gpr_args);
    try std.testing.expectEqual(@as(usize, 1), counts.stack_args);

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);
    try expectMachineInstruction(machine.instructions.items, .{ .indirect_call_rax = .void });
}

test "x86_64 codegen accepts stack-sourced hidden sret pointer call argument" {
    const direct_input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare void @callee(ptr sret({ i64, i64, i64 }))
        \\
        \\define void @caller(i32 %a0, i32 %a1, i32 %a2, i32 %a3, i32 %a4, i32 %a5, ptr %out) {
        \\entry:
        \\  call void @callee(ptr sret({ i64, i64, i64 }) %out)
        \\  ret void
        \\}
        \\
    ;
    var direct_module = try ir.Module.parse(std.testing.allocator, direct_input);
    defer direct_module.deinit();
    try direct_module.verify();
    const direct_call = direct_module.functions.items[0].blocks.items[0].instructions.items[0].kind.call;
    const direct_counts = try codegen.x86_64.sysvCallPlanCountsForTest(std.testing.allocator, direct_module.functions.items[0], direct_call);
    try std.testing.expectEqual(@as(usize, 1), direct_counts.gpr_args);
    try std.testing.expectEqual(@as(usize, 0), direct_counts.stack_args);
    var direct_machine = try codegen.x86_64.lowerFunction(std.testing.allocator, direct_module.target_triple.?, direct_module.functions.items[0]);
    defer direct_machine.deinit(std.testing.allocator);
    try expectMachineInstruction(direct_machine.instructions.items, .{ .load_stack_disp8_arg64 = .{ .reg = .rdi, .disp = 8 } });

    const indirect_input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define void @caller(ptr %fn, i32 %a0, i32 %a1, i32 %a2, i32 %a3, i32 %a4, ptr %out) {
        \\entry:
        \\  call void %fn(ptr sret({ i64, i64, i64 }) %out)
        \\  ret void
        \\}
        \\
    ;
    var indirect_module = try ir.Module.parse(std.testing.allocator, indirect_input);
    defer indirect_module.deinit();
    try indirect_module.verify();
    const indirect_call = indirect_module.functions.items[0].blocks.items[0].instructions.items[0].kind.call;
    try std.testing.expect(indirect_call.callee_value != null);
    const indirect_counts = try codegen.x86_64.sysvCallPlanCountsForTest(std.testing.allocator, indirect_module.functions.items[0], indirect_call);
    try std.testing.expectEqual(@as(usize, 1), indirect_counts.gpr_args);
    try std.testing.expectEqual(@as(usize, 0), indirect_counts.stack_args);
    var indirect_machine = try codegen.x86_64.lowerFunction(std.testing.allocator, indirect_module.target_triple.?, indirect_module.functions.items[0]);
    defer indirect_machine.deinit(std.testing.allocator);
    var target_setup_index: ?usize = null;
    var sret_load_index: ?usize = null;
    var indirect_call_index: ?usize = null;
    for (indirect_machine.instructions.items, 0..) |instruction, index| {
        switch (instruction) {
            .mov_arg_rax => |reg| {
                if (reg == .rdi) target_setup_index = index;
            },
            .load_stack_disp8_arg64 => |load| {
                if (load.reg == .rdi and load.disp == 8) sret_load_index = index;
            },
            .indirect_call_rax => |ret_ty| {
                if (ret_ty == .void) indirect_call_index = index;
            },
            else => {},
        }
    }
    try std.testing.expect((target_setup_index orelse return error.TestExpectedEqual) < (sret_load_index orelse return error.TestExpectedEqual));
    try std.testing.expect((sret_load_index orelse return error.TestExpectedEqual) < (indirect_call_index orelse return error.TestExpectedEqual));
}

test "x86_64 codegen preserves live i32 across supported sret pointer call" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare void @callee(ptr sret({ i32, i32 }))
        \\
        \\define i32 @caller(ptr %out, i32 %keep) {
        \\entry:
        \\  call void @callee(ptr sret({ i32, i32 }) %out)
        \\  ret i32 %keep
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    const call = module.functions.items[0].blocks.items[0].instructions.items[0].kind.call;
    const counts = try codegen.x86_64.sysvCallPlanCountsForTest(std.testing.allocator, module.functions.items[0], call);
    try std.testing.expectEqual(@as(usize, 1), counts.gpr_args);
    try std.testing.expectEqual(@as(usize, 0), counts.stack_args);
    try std.testing.expect(!codegen.x86_64.sysvScalarCallNeedsStackArgsForTest(call));

    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);
    try expectMachineInstruction(machine.instructions.items, .{ .spill_arg_rsp = .{ .frame_index = .slot0, .reg = .rsi } });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_arg_rsp = .{ .reg = .rsi, .frame_index = .slot0 } });
}

test "x86_64 codegen preserves live value across sret stack-arg call" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare void @callee(ptr sret({ i64, i64, i64 }), i32, i32, i32, i32, i32, i32)
        \\
        \\define i32 @caller(ptr %out, i32 %keep, i32 %a0, i32 %a1, i32 %a2, i32 %a3, i32 %a4, i32 %a5) {
        \\entry:
        \\  call void @callee(ptr sret({ i64, i64, i64 }) %out, i32 %a0, i32 %a1, i32 %a2, i32 %a3, i32 %a4, i32 %a5)
        \\  ret i32 %keep
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    const call = module.functions.items[0].blocks.items[0].instructions.items[0].kind.call;
    const counts = try codegen.x86_64.sysvCallPlanCountsForTest(std.testing.allocator, module.functions.items[0], call);
    try std.testing.expectEqual(@as(usize, 6), counts.gpr_args);
    try std.testing.expectEqual(@as(usize, 1), counts.stack_args);
    try std.testing.expect(codegen.x86_64.sysvScalarCallNeedsStackArgsForTest(call));
    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);
    try expectMachineInstruction(machine.instructions.items, .{ .spill_arg_rsp = .{ .frame_index = .slot0, .reg = .rsi } });
    var found_call = false;
    for (machine.instructions.items) |instruction| {
        switch (instruction) {
            .direct_call => |direct_call| {
                try std.testing.expectEqualStrings("callee", direct_call.symbol);
                try std.testing.expect(direct_call.ret_ty == .void);
                found_call = true;
            },
            else => {},
        }
    }
    try std.testing.expect(found_call);
    try expectMachineInstruction(machine.instructions.items, .{ .add_rsp_imm8 = 16 });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_arg_rsp = .{ .reg = .rsi, .frame_index = .slot0 } });
}

test "x86_64 codegen preserves live value across indirect sret stack-arg call" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @caller(ptr %fn, ptr %out, i32 %keep, i32 %a0, i32 %a1, i32 %a2, i32 %a3, i32 %a4, i32 %a5) {
        \\entry:
        \\  call void %fn(ptr sret({ i64, i64, i64 }) %out, i32 %a0, i32 %a1, i32 %a2, i32 %a3, i32 %a4, i32 %a5)
        \\  ret i32 %keep
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    const call = module.functions.items[0].blocks.items[0].instructions.items[0].kind.call;
    try std.testing.expect(call.callee_value != null);
    const counts = try codegen.x86_64.sysvCallPlanCountsForTest(std.testing.allocator, module.functions.items[0], call);
    try std.testing.expectEqual(@as(usize, 6), counts.gpr_args);
    try std.testing.expectEqual(@as(usize, 1), counts.stack_args);
    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);
    try expectMachineInstruction(machine.instructions.items, .{ .spill_arg_rsp = .{ .frame_index = .slot0, .reg = .rdx } });
    try expectMachineInstruction(machine.instructions.items, .{ .mov_arg_rax = .rdi });
    try expectMachineInstruction(machine.instructions.items, .{ .indirect_call_rax = .void });
    try expectMachineInstruction(machine.instructions.items, .{ .add_rsp_imm8 = 16 });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_arg_rsp = .{ .reg = .rdx, .frame_index = .slot0 } });
}

test "x86_64 codegen accepts supported byval stack-copy call ABI subset" {
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
    const byval_call = byval_module.functions.items[0].blocks.items[0].instructions.items[0].kind.call;
    const byval_counts = try codegen.x86_64.sysvCallPlanCountsForTest(std.testing.allocator, byval_module.functions.items[0], byval_call);
    try std.testing.expectEqual(@as(usize, 0), byval_counts.gpr_args);
    try std.testing.expectEqual(@as(usize, 1), byval_counts.stack_args);
    var byval_machine = try codegen.x86_64.lowerFunction(std.testing.allocator, byval_module.target_triple.?, byval_module.functions.items[0]);
    defer byval_machine.deinit(std.testing.allocator);
    try expectMachineInstruction(byval_machine.instructions.items, .{ .load_arg_ptr_disp8_rax = .{ .reg = .rdi, .offset = 0 } });
    try expectMachineInstruction(byval_machine.instructions.items, .push_rax);
    var saw_byval_direct_call = false;
    for (byval_machine.instructions.items) |instruction| switch (instruction) {
        .direct_call => |direct_call| {
            saw_byval_direct_call = true;
            try std.testing.expectEqualStrings("callee", direct_call.symbol);
            try std.testing.expect(direct_call.ret_ty.eql(.{ .int = 32 }));
        },
        else => {},
    };
    try std.testing.expect(saw_byval_direct_call);

    const indirect_byval_input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @caller(ptr %fn, ptr %arg) {
        \\entry:
        \\  %r = call i32 %fn(ptr byval({ i32, i32 }) %arg)
        \\  ret i32 %r
        \\}
        \\
    ;
    var indirect_byval_module = try ir.Module.parse(std.testing.allocator, indirect_byval_input);
    defer indirect_byval_module.deinit();
    try indirect_byval_module.verify();
    const indirect_byval_call = indirect_byval_module.functions.items[0].blocks.items[0].instructions.items[0].kind.call;
    try std.testing.expect(indirect_byval_call.callee_value != null);
    try std.testing.expect(codegen.x86_64.sysvScalarCallNeedsStackArgsForTest(indirect_byval_call));
    const indirect_byval_counts = try codegen.x86_64.sysvCallPlanCountsForTest(std.testing.allocator, indirect_byval_module.functions.items[0], indirect_byval_call);
    try std.testing.expectEqual(@as(usize, 0), indirect_byval_counts.gpr_args);
    try std.testing.expectEqual(@as(usize, 1), indirect_byval_counts.stack_args);
    var indirect_byval_machine = try codegen.x86_64.lowerFunction(std.testing.allocator, indirect_byval_module.target_triple.?, indirect_byval_module.functions.items[0]);
    defer indirect_byval_machine.deinit(std.testing.allocator);
    var payload_load_index: ?usize = null;
    var final_target_setup_index: ?usize = null;
    var indirect_call_index: ?usize = null;
    for (indirect_byval_machine.instructions.items, 0..) |instruction, index| {
        switch (instruction) {
            .load_arg_ptr_disp8_rax => |load| {
                if (load.reg == .rsi and load.offset == 0) payload_load_index = index;
            },
            .mov_arg_rax => |reg| {
                if (reg == .rdi) final_target_setup_index = index;
            },
            .indirect_call_rax => |ret_ty| {
                if (ret_ty.eql(.{ .int = 32 })) indirect_call_index = index;
            },
            else => {},
        }
    }
    try std.testing.expect((payload_load_index orelse return error.TestExpectedEqual) < (final_target_setup_index orelse return error.TestExpectedEqual));
    try std.testing.expect((final_target_setup_index orelse return error.TestExpectedEqual) < (indirect_call_index orelse return error.TestExpectedEqual));

    const indirect_byval_live_input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @caller(ptr %fn, ptr %arg, i32 %keep) {
        \\entry:
        \\  call void %fn(ptr byval({ i32, i32 }) %arg)
        \\  ret i32 %keep
        \\}
        \\
    ;
    var indirect_byval_live_module = try ir.Module.parse(std.testing.allocator, indirect_byval_live_input);
    defer indirect_byval_live_module.deinit();
    try indirect_byval_live_module.verify();
    var indirect_byval_live_machine = try codegen.x86_64.lowerFunction(std.testing.allocator, indirect_byval_live_module.target_triple.?, indirect_byval_live_module.functions.items[0]);
    defer indirect_byval_live_machine.deinit(std.testing.allocator);
    try expectMachineInstruction(indirect_byval_live_machine.instructions.items, .{ .spill_arg_rsp = .{ .frame_index = .slot0, .reg = .rdx } });
    var live_payload_load_index: ?usize = null;
    var live_target_setup_index: ?usize = null;
    var live_indirect_call_index: ?usize = null;
    for (indirect_byval_live_machine.instructions.items, 0..) |instruction, index| {
        switch (instruction) {
            .load_arg_ptr_disp8_rax => |load| {
                if (load.reg == .rsi and load.offset == 0) live_payload_load_index = index;
            },
            .mov_arg_rax => |reg| {
                if (reg == .rdi) live_target_setup_index = index;
            },
            .indirect_call_rax => |ret_ty| {
                if (ret_ty == .void) live_indirect_call_index = index;
            },
            else => {},
        }
    }
    try std.testing.expect((live_payload_load_index orelse return error.TestExpectedEqual) < (live_target_setup_index orelse return error.TestExpectedEqual));
    try std.testing.expect((live_target_setup_index orelse return error.TestExpectedEqual) < (live_indirect_call_index orelse return error.TestExpectedEqual));
    try expectMachineInstruction(indirect_byval_live_machine.instructions.items, .{ .add_rsp_imm8 = 16 });
    try expectMachineInstruction(indirect_byval_live_machine.instructions.items, .{ .reload_arg_rsp = .{ .reg = .rdx, .frame_index = .slot0 } });
}

test "x86_64 codegen accepts two-eightbyte byval stack-copy calls" {
    const direct_input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare i64 @callee(ptr byval({ i64, i64 }))
        \\
        \\define i64 @caller(ptr %arg) {
        \\entry:
        \\  %r = call i64 @callee(ptr byval({ i64, i64 }) %arg)
        \\  ret i64 %r
        \\}
        \\
    ;
    var direct_module = try ir.Module.parse(std.testing.allocator, direct_input);
    defer direct_module.deinit();
    try direct_module.verify();
    const direct_call = direct_module.functions.items[0].blocks.items[0].instructions.items[0].kind.call;
    const direct_counts = try codegen.x86_64.sysvCallPlanCountsForTest(std.testing.allocator, direct_module.functions.items[0], direct_call);
    try std.testing.expectEqual(@as(usize, 0), direct_counts.gpr_args);
    try std.testing.expectEqual(@as(usize, 2), direct_counts.stack_args);
    var direct_machine = try codegen.x86_64.lowerFunction(std.testing.allocator, direct_module.target_triple.?, direct_module.functions.items[0]);
    defer direct_machine.deinit(std.testing.allocator);
    try expectMachineInstruction(direct_machine.instructions.items, .{ .load_arg_ptr_disp8_rax = .{ .reg = .rdi, .offset = 8 } });
    try expectMachineInstruction(direct_machine.instructions.items, .{ .load_arg_ptr_disp8_rax = .{ .reg = .rdi, .offset = 0 } });

    const indirect_input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i64 @caller(ptr %fn, ptr %arg) {
        \\entry:
        \\  %r = call i64 %fn(ptr byval({ i64, i64 }) %arg)
        \\  ret i64 %r
        \\}
        \\
    ;
    var indirect_module = try ir.Module.parse(std.testing.allocator, indirect_input);
    defer indirect_module.deinit();
    try indirect_module.verify();
    const indirect_call = indirect_module.functions.items[0].blocks.items[0].instructions.items[0].kind.call;
    const indirect_counts = try codegen.x86_64.sysvCallPlanCountsForTest(std.testing.allocator, indirect_module.functions.items[0], indirect_call);
    try std.testing.expectEqual(@as(usize, 0), indirect_counts.gpr_args);
    try std.testing.expectEqual(@as(usize, 2), indirect_counts.stack_args);
    var indirect_machine = try codegen.x86_64.lowerFunction(std.testing.allocator, indirect_module.target_triple.?, indirect_module.functions.items[0]);
    defer indirect_machine.deinit(std.testing.allocator);
    try expectMachineInstruction(indirect_machine.instructions.items, .{ .load_arg_ptr_disp8_rax = .{ .reg = .rsi, .offset = 8 } });
    try expectMachineInstruction(indirect_machine.instructions.items, .{ .load_arg_ptr_disp8_rax = .{ .reg = .rsi, .offset = 0 } });
    try expectMachineInstruction(indirect_machine.instructions.items, .{ .indirect_call_rax = .{ .int = 64 } });
}

test "x86_64 codegen accepts array-backed byval stack-copy payload" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare i64 @callee(ptr byval({ [2 x i64], i64 }))
        \\
        \\define i64 @caller(ptr %arg) {
        \\entry:
        \\  %r = call i64 @callee(ptr byval({ [2 x i64], i64 }) %arg)
        \\  ret i64 %r
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    const call = module.functions.items[0].blocks.items[0].instructions.items[0].kind.call;
    const counts = try codegen.x86_64.sysvCallPlanCountsForTest(std.testing.allocator, module.functions.items[0], call);
    try std.testing.expectEqual(@as(usize, 0), counts.gpr_args);
    try std.testing.expectEqual(@as(usize, 3), counts.stack_args);
    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);
    try expectMachineInstruction(machine.instructions.items, .{ .load_arg_ptr_disp8_rax = .{ .reg = .rdi, .offset = 16 } });
    try expectMachineInstruction(machine.instructions.items, .{ .load_arg_ptr_disp8_rax = .{ .reg = .rdi, .offset = 8 } });
    try expectMachineInstruction(machine.instructions.items, .{ .load_arg_ptr_disp8_rax = .{ .reg = .rdi, .offset = 0 } });
}

test "x86_64 codegen accepts nested byval stack-copy payload" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare i64 @callee(ptr byval({ { i64, i64 }, i64 }))
        \\
        \\define i64 @caller(ptr %arg) {
        \\entry:
        \\  %r = call i64 @callee(ptr byval({ { i64, i64 }, i64 }) %arg)
        \\  ret i64 %r
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    const call = module.functions.items[0].blocks.items[0].instructions.items[0].kind.call;
    const counts = try codegen.x86_64.sysvCallPlanCountsForTest(std.testing.allocator, module.functions.items[0], call);
    try std.testing.expectEqual(@as(usize, 0), counts.gpr_args);
    try std.testing.expectEqual(@as(usize, 3), counts.stack_args);
    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);
    try expectMachineInstruction(machine.instructions.items, .{ .load_arg_ptr_disp8_rax = .{ .reg = .rdi, .offset = 16 } });
    try expectMachineInstruction(machine.instructions.items, .{ .load_arg_ptr_disp8_rax = .{ .reg = .rdi, .offset = 8 } });
    try expectMachineInstruction(machine.instructions.items, .{ .load_arg_ptr_disp8_rax = .{ .reg = .rdi, .offset = 0 } });
}

test "x86_64 codegen accepts max-sized byval stack-copy payload" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare i64 @callee(ptr byval([24 x i64]))
        \\
        \\define i64 @caller(ptr %arg) {
        \\entry:
        \\  %r = call i64 @callee(ptr byval([24 x i64]) %arg)
        \\  ret i64 %r
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    const call = module.functions.items[0].blocks.items[0].instructions.items[0].kind.call;
    const counts = try codegen.x86_64.sysvCallPlanCountsForTest(std.testing.allocator, module.functions.items[0], call);
    try std.testing.expectEqual(@as(usize, 0), counts.gpr_args);
    try std.testing.expectEqual(@as(usize, 24), counts.stack_args);
    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);
    try expectMachineInstruction(machine.instructions.items, .{ .load_arg_ptr_disp8_rax = .{ .reg = .rdi, .offset = 0 } });
    try expectMachineInstruction(machine.instructions.items, .{ .load_arg_ptr_disp32_rax = .{ .reg = .rdi, .offset = 184 } });
    try expectMachineInstruction(machine.instructions.items, .{ .add_rsp_imm32 = 200 });
}

test "x86_64 codegen accepts stack-sourced byval stack-copy payload" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare i64 @callee(ptr byval({ i64, i64 }))
        \\
        \\define i64 @caller(ptr %a, ptr %b, ptr %c, ptr %d, ptr %e, ptr %f, ptr %arg) {
        \\entry:
        \\  %r = call i64 @callee(ptr byval({ i64, i64 }) %arg)
        \\  ret i64 %r
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    const call = module.functions.items[0].blocks.items[0].instructions.items[0].kind.call;
    const counts = try codegen.x86_64.sysvCallPlanCountsForTest(std.testing.allocator, module.functions.items[0], call);
    try std.testing.expectEqual(@as(usize, 0), counts.gpr_args);
    try std.testing.expectEqual(@as(usize, 2), counts.stack_args);
    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);
    try expectMachineInstruction(machine.instructions.items, .{ .sub_rsp_8 = {} });
    try expectMachineInstruction(machine.instructions.items, .{ .load_stack_disp8_rax = 16 });
    try expectMachineInstruction(machine.instructions.items, .{ .load_rax_ptr_disp8_rax = 8 });
    try expectMachineInstruction(machine.instructions.items, .{ .load_stack_disp8_rax = 24 });
    try expectMachineInstruction(machine.instructions.items, .{ .load_rax_ptr_disp8_rax = 0 });
    try expectMachineInstruction(machine.instructions.items, .{ .add_rsp_24 = {} });
}

test "x86_64 codegen accepts live indirect stack-sourced byval payload" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @caller(ptr %fn, i32 %keep, ptr %a, ptr %b, ptr %c, ptr %d, ptr %arg) {
        \\entry:
        \\  call void %fn(ptr byval({ i64, i64 }) %arg)
        \\  ret i32 %keep
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    const call = module.functions.items[0].blocks.items[0].instructions.items[0].kind.call;
    const counts = try codegen.x86_64.sysvCallPlanCountsForTest(std.testing.allocator, module.functions.items[0], call);
    try std.testing.expectEqual(@as(usize, 0), counts.gpr_args);
    try std.testing.expectEqual(@as(usize, 2), counts.stack_args);
    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);

    try expectMachineInstruction(machine.instructions.items, .{ .spill_arg_rsp = .{ .frame_index = .slot0, .reg = .rsi } });
    var stack_source_load_index: ?usize = null;
    var payload_load_index: ?usize = null;
    var target_setup_index: ?usize = null;
    var call_index: ?usize = null;
    for (machine.instructions.items, 0..) |instruction, index| {
        switch (instruction) {
            .load_stack_disp8_rax => {
                if (stack_source_load_index == null) stack_source_load_index = index;
            },
            .load_rax_ptr_disp8_rax => |offset| {
                if (offset == 8 and payload_load_index == null) payload_load_index = index;
            },
            .mov_arg_rax => |reg| {
                if (reg == .rdi) target_setup_index = index;
            },
            .indirect_call_rax => |ret_ty| {
                if (ret_ty == .void) call_index = index;
            },
            else => {},
        }
    }
    try std.testing.expect((stack_source_load_index orelse return error.TestExpectedEqual) < (payload_load_index orelse return error.TestExpectedEqual));
    try std.testing.expect((payload_load_index orelse return error.TestExpectedEqual) < (target_setup_index orelse return error.TestExpectedEqual));
    try std.testing.expect((target_setup_index orelse return error.TestExpectedEqual) < (call_index orelse return error.TestExpectedEqual));
    try expectMachineInstruction(machine.instructions.items, .{ .add_rsp_imm8 = 16 });
    try expectMachineInstruction(machine.instructions.items, .{ .reload_arg_rsp = .{ .reg = .rsi, .frame_index = .slot0 } });
    try expectMachineInstruction(machine.instructions.items, .add_rsp_8);
}

test "x86_64 codegen accepts four-byte byval stack-copy tail" {
    const direct_input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare i32 @callee(ptr byval({ i32 }))
        \\
        \\define i32 @caller(ptr %arg) {
        \\entry:
        \\  %r = call i32 @callee(ptr byval({ i32 }) %arg)
        \\  ret i32 %r
        \\}
        \\
    ;
    var direct_module = try ir.Module.parse(std.testing.allocator, direct_input);
    defer direct_module.deinit();
    try direct_module.verify();
    const direct_call = direct_module.functions.items[0].blocks.items[0].instructions.items[0].kind.call;
    const direct_counts = try codegen.x86_64.sysvCallPlanCountsForTest(std.testing.allocator, direct_module.functions.items[0], direct_call);
    try std.testing.expectEqual(@as(usize, 0), direct_counts.gpr_args);
    try std.testing.expectEqual(@as(usize, 1), direct_counts.stack_args);
    var direct_machine = try codegen.x86_64.lowerFunction(std.testing.allocator, direct_module.target_triple.?, direct_module.functions.items[0]);
    defer direct_machine.deinit(std.testing.allocator);
    try expectMachineInstruction(direct_machine.instructions.items, .{ .load_arg_ptr_disp8_eax = .{ .reg = .rdi, .offset = 0 } });
    try expectMachineInstruction(direct_machine.instructions.items, .push_rax);

    const indirect_input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @caller(ptr %fn, ptr %arg) {
        \\entry:
        \\  %r = call i32 %fn(ptr byval({ i32 }) %arg)
        \\  ret i32 %r
        \\}
        \\
    ;
    var indirect_module = try ir.Module.parse(std.testing.allocator, indirect_input);
    defer indirect_module.deinit();
    try indirect_module.verify();
    const indirect_call = indirect_module.functions.items[0].blocks.items[0].instructions.items[0].kind.call;
    const indirect_counts = try codegen.x86_64.sysvCallPlanCountsForTest(std.testing.allocator, indirect_module.functions.items[0], indirect_call);
    try std.testing.expectEqual(@as(usize, 0), indirect_counts.gpr_args);
    try std.testing.expectEqual(@as(usize, 1), indirect_counts.stack_args);
    var indirect_machine = try codegen.x86_64.lowerFunction(std.testing.allocator, indirect_module.target_triple.?, indirect_module.functions.items[0]);
    defer indirect_machine.deinit(std.testing.allocator);
    try expectMachineInstruction(indirect_machine.instructions.items, .{ .load_arg_ptr_disp8_eax = .{ .reg = .rsi, .offset = 0 } });
    try expectMachineInstruction(indirect_machine.instructions.items, .{ .indirect_call_rax = .{ .int = 32 } });
}

test "x86_64 codegen accepts byte and word byval stack-copy tails" {
    const direct_byte_input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare i32 @callee(ptr byval({ i8 }))
        \\
        \\define i32 @caller(ptr %arg) {
        \\entry:
        \\  %r = call i32 @callee(ptr byval({ i8 }) %arg)
        \\  ret i32 %r
        \\}
        \\
    ;
    var direct_byte_module = try ir.Module.parse(std.testing.allocator, direct_byte_input);
    defer direct_byte_module.deinit();
    try direct_byte_module.verify();
    const direct_byte_call = direct_byte_module.functions.items[0].blocks.items[0].instructions.items[0].kind.call;
    const direct_byte_counts = try codegen.x86_64.sysvCallPlanCountsForTest(std.testing.allocator, direct_byte_module.functions.items[0], direct_byte_call);
    try std.testing.expectEqual(@as(usize, 0), direct_byte_counts.gpr_args);
    try std.testing.expectEqual(@as(usize, 1), direct_byte_counts.stack_args);
    var direct_byte_machine = try codegen.x86_64.lowerFunction(std.testing.allocator, direct_byte_module.target_triple.?, direct_byte_module.functions.items[0]);
    defer direct_byte_machine.deinit(std.testing.allocator);
    try expectMachineInstruction(direct_byte_machine.instructions.items, .{ .load_arg_ptr_disp8_u8_eax = .{ .reg = .rdi, .offset = 0 } });
    try expectMachineInstruction(direct_byte_machine.instructions.items, .push_rax);

    const indirect_stack_word_input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @caller(ptr %fn, ptr %a, ptr %b, ptr %c, ptr %d, ptr %e, ptr %arg) {
        \\entry:
        \\  %r = call i32 %fn(ptr byval({ i16 }) %arg)
        \\  ret i32 %r
        \\}
        \\
    ;
    var indirect_stack_word_module = try ir.Module.parse(std.testing.allocator, indirect_stack_word_input);
    defer indirect_stack_word_module.deinit();
    try indirect_stack_word_module.verify();
    const indirect_stack_word_call = indirect_stack_word_module.functions.items[0].blocks.items[0].instructions.items[0].kind.call;
    const indirect_stack_word_counts = try codegen.x86_64.sysvCallPlanCountsForTest(std.testing.allocator, indirect_stack_word_module.functions.items[0], indirect_stack_word_call);
    try std.testing.expectEqual(@as(usize, 0), indirect_stack_word_counts.gpr_args);
    try std.testing.expectEqual(@as(usize, 1), indirect_stack_word_counts.stack_args);
    var indirect_stack_word_machine = try codegen.x86_64.lowerFunction(std.testing.allocator, indirect_stack_word_module.target_triple.?, indirect_stack_word_module.functions.items[0]);
    defer indirect_stack_word_machine.deinit(std.testing.allocator);
    try expectMachineInstruction(indirect_stack_word_machine.instructions.items, .{ .load_stack_disp8_rax = 8 });
    try expectMachineInstruction(indirect_stack_word_machine.instructions.items, .{ .load_rax_ptr_disp8_u16_eax = 0 });
    try expectMachineInstruction(indirect_stack_word_machine.instructions.items, .{ .indirect_call_rax = .{ .int = 32 } });
}

test "x86_64 codegen accepts array byval stack-copy with four-byte tail" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare i32 @callee(ptr byval([3 x i32]))
        \\
        \\define i32 @caller(ptr %arg) {
        \\entry:
        \\  %r = call i32 @callee(ptr byval([3 x i32]) %arg)
        \\  ret i32 %r
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    const call = module.functions.items[0].blocks.items[0].instructions.items[0].kind.call;
    const counts = try codegen.x86_64.sysvCallPlanCountsForTest(std.testing.allocator, module.functions.items[0], call);
    try std.testing.expectEqual(@as(usize, 0), counts.gpr_args);
    try std.testing.expectEqual(@as(usize, 2), counts.stack_args);
    var machine = try codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]);
    defer machine.deinit(std.testing.allocator);
    try expectMachineInstruction(machine.instructions.items, .{ .load_arg_ptr_disp8_eax = .{ .reg = .rdi, .offset = 8 } });
    try expectMachineInstruction(machine.instructions.items, .{ .load_arg_ptr_disp8_rax = .{ .reg = .rdi, .offset = 0 } });
}

test "x86_64 codegen accepts composite byval short-tail stack copies" {
    const direct_input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare i32 @callee(ptr byval([3 x i16]))
        \\
        \\define i32 @caller(ptr %arg) {
        \\entry:
        \\  %r = call i32 @callee(ptr byval([3 x i16]) %arg)
        \\  ret i32 %r
        \\}
        \\
    ;
    var direct_module = try ir.Module.parse(std.testing.allocator, direct_input);
    defer direct_module.deinit();
    try direct_module.verify();
    const direct_call = direct_module.functions.items[0].blocks.items[0].instructions.items[0].kind.call;
    const direct_counts = try codegen.x86_64.sysvCallPlanCountsForTest(std.testing.allocator, direct_module.functions.items[0], direct_call);
    try std.testing.expectEqual(@as(usize, 0), direct_counts.gpr_args);
    try std.testing.expectEqual(@as(usize, 1), direct_counts.stack_args);
    var direct_machine = try codegen.x86_64.lowerFunction(std.testing.allocator, direct_module.target_triple.?, direct_module.functions.items[0]);
    defer direct_machine.deinit(std.testing.allocator);
    try expectMachineInstruction(direct_machine.instructions.items, .{ .push_byval_tail_arg_ptr = .{
        .reg = .rdi,
        .offset = 0,
        .len = 6,
    } });

    const indirect_input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @caller(ptr %fn, ptr %arg) {
        \\entry:
        \\  %r = call i32 %fn(ptr byval([5 x i8]) %arg)
        \\  ret i32 %r
        \\}
        \\
    ;
    var indirect_module = try ir.Module.parse(std.testing.allocator, indirect_input);
    defer indirect_module.deinit();
    try indirect_module.verify();
    const indirect_call = indirect_module.functions.items[0].blocks.items[0].instructions.items[0].kind.call;
    const indirect_counts = try codegen.x86_64.sysvCallPlanCountsForTest(std.testing.allocator, indirect_module.functions.items[0], indirect_call);
    try std.testing.expectEqual(@as(usize, 0), indirect_counts.gpr_args);
    try std.testing.expectEqual(@as(usize, 1), indirect_counts.stack_args);
    var indirect_machine = try codegen.x86_64.lowerFunction(std.testing.allocator, indirect_module.target_triple.?, indirect_module.functions.items[0]);
    defer indirect_machine.deinit(std.testing.allocator);
    try expectMachineInstruction(indirect_machine.instructions.items, .{ .push_byval_tail_arg_ptr = .{
        .reg = .rsi,
        .offset = 0,
        .len = 5,
    } });
    try expectMachineInstruction(indirect_machine.instructions.items, .{ .indirect_call_rax = .{ .int = 32 } });

    const indirect_stack_input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @caller(ptr %fn, ptr %a, ptr %b, ptr %c, ptr %d, ptr %e, ptr %arg) {
        \\entry:
        \\  %r = call i32 %fn(ptr byval([7 x i8]) %arg)
        \\  ret i32 %r
        \\}
        \\
    ;
    var indirect_stack_module = try ir.Module.parse(std.testing.allocator, indirect_stack_input);
    defer indirect_stack_module.deinit();
    try indirect_stack_module.verify();
    const indirect_stack_call = indirect_stack_module.functions.items[0].blocks.items[0].instructions.items[0].kind.call;
    const indirect_stack_counts = try codegen.x86_64.sysvCallPlanCountsForTest(std.testing.allocator, indirect_stack_module.functions.items[0], indirect_stack_call);
    try std.testing.expectEqual(@as(usize, 0), indirect_stack_counts.gpr_args);
    try std.testing.expectEqual(@as(usize, 1), indirect_stack_counts.stack_args);
    var indirect_stack_machine = try codegen.x86_64.lowerFunction(std.testing.allocator, indirect_stack_module.target_triple.?, indirect_stack_module.functions.items[0]);
    defer indirect_stack_machine.deinit(std.testing.allocator);
    try expectMachineInstruction(indirect_stack_machine.instructions.items, .{ .push_byval_tail_stack_ptr = .{
        .stack_disp = 8,
        .offset = 0,
        .len = 7,
    } });
    try expectMachineInstruction(indirect_stack_machine.instructions.items, .{ .indirect_call_rax = .{ .int = 32 } });
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
        abi_boundaries.Category.vector.errorValue(),
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
        abi_boundaries.Category.x87.errorValue(),
        codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]),
    );
}

test "x86_64 codegen rejects indirect X87 call ABI boundary" {
    const input =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @caller(ptr %fn, x86_fp80 %value) {
        \\entry:
        \\  %r = call i32 %fn(x86_fp80 %value)
        \\  ret i32 %r
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    try std.testing.expectError(
        abi_boundaries.Category.x87.errorValue(),
        codegen.x86_64.lowerFunction(std.testing.allocator, module.target_triple.?, module.functions.items[0]),
    );
}
