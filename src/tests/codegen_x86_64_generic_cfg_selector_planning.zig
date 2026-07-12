const common = @import("codegen_x86_64_common.zig");

const std = common.std;
const codegen = common.codegen;
const ir = common.ir;
const mc = common.mc;
const selector = @import("../codegen/x86_64/generic_cfg_selector.zig");
const stage2_planning = @import("../codegen/x86_64/generic_cfg/stage2_planning.zig");

fn expectInstruction(instructions: []const codegen.x86_64.Instruction, expected: codegen.x86_64.Instruction) !void {
    for (instructions) |instruction| {
        if (std.meta.eql(instruction, expected)) return;
    }
    return error.ExpectedInstructionNotFound;
}

fn expectInstructionTag(instructions: []const codegen.x86_64.Instruction, comptime tag: std.meta.Tag(codegen.x86_64.Instruction)) !void {
    for (instructions) |instruction| {
        if (std.meta.activeTag(instruction) == tag) return;
    }
    return error.ExpectedInstructionNotFound;
}

fn expectNamedInstruction(instructions: []const codegen.x86_64.Instruction, comptime tag: std.meta.Tag(codegen.x86_64.Instruction), expected: []const u8) !void {
    for (instructions) |instruction| {
        switch (instruction) {
            tag => |actual| if (std.mem.eql(u8, actual, expected)) return,
            else => {},
        }
    }
    return error.ExpectedInstructionNotFound;
}

fn makeBranchChainIr(allocator: std.mem.Allocator, block_count: usize) ![]u8 {
    if (block_count < 2) return error.InvalidBlockCount;
    var text: std.ArrayList(u8) = .empty;
    errdefer text.deinit(allocator);

    try text.appendSlice(allocator,
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @branch_chain(i32 %x) {
        \\entry:
        \\  br label %b1
        \\
    );
    for (1..block_count) |index| {
        const block_text = if (index + 1 == block_count)
            try std.fmt.allocPrint(allocator,
                \\b{d}:
                \\  ret i32 %x
                \\
            , .{index})
        else
            try std.fmt.allocPrint(allocator,
                \\b{d}:
                \\  br label %b{d}
                \\
            , .{ index, index + 1 });
        defer allocator.free(block_text);
        try text.appendSlice(allocator, block_text);
    }
    try text.appendSlice(allocator, "}\n");
    return try text.toOwnedSlice(allocator);
}

test "generic cfg allocation places phi uses on predecessor edges" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @backward_layout_phi(i32 %value) {
        \\entry:
        \\  br label %later
        \\merge:
        \\  %merged = phi i32 [ %next, %later ]
        \\  ret i32 %merged
        \\later:
        \\  %next = add i32 %value, 1
        \\  br label %merge
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    var plan = try stage2_planning.buildSelectorAllocationPlan(std.testing.allocator, module.functions.items[0]);
    defer plan.deinit();

    try std.testing.expectEqual(@as(?usize, 5), plan.intervalEnd("next"));
}

test "generic cfg selector skeleton reports no emitter for supported straight-line integer shape" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @add32(i32 %a, i32 %b) {
        \\entry:
        \\  %sum = add i32 %a, %b
        \\  ret i32 %sum
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    const result = selector.inspectFunction(module.functions.items[0]);
    const diagnostic = switch (result) {
        .selected => return error.TestExpectedUnsupported,
        .unsupported => |diagnostic| diagnostic,
    };
    try std.testing.expectEqualStrings("no_emitter", diagnostic.tagName());
    try std.testing.expectEqualStrings("selector-skeleton-has-no-emitters", diagnostic.detail());
}

test "generic cfg selector inspection admits only typed i64 signed multiply overflow" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare { i64, i1 } @llvm.smul.with.overflow.i64(i64, i64)
        \\
        \\define i64 @accepted(i64 %lhs, i64 %rhs) {
        \\entry:
        \\  %pair = call { i64, i1 } @llvm.smul.with.overflow.i64(i64 %lhs, i64 %rhs)
        \\  %value = extractvalue { i64, i1 } %pair, 0
        \\  ret i64 %value
        \\}
        \\
        \\define i64 @rejected(i32 %lhs, i64 %rhs) {
        \\entry:
        \\  %pair = call { i64, i1 } @llvm.smul.with.overflow.i64(i32 %lhs, i64 %rhs)
        \\  %value = extractvalue { i64, i1 } %pair, 0
        \\  ret i64 %value
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    const accepted = switch (selector.inspectFunction(module.functions.items[0])) {
        .selected => return error.TestExpectedUnsupported,
        .unsupported => |diagnostic| diagnostic,
    };
    try std.testing.expectEqualStrings("no_emitter", accepted.tagName());
    try std.testing.expectEqualStrings("selector-skeleton-has-no-emitters", accepted.detail());

    const rejected = switch (selector.inspectFunction(module.functions.items[1])) {
        .selected => return error.TestExpectedUnsupported,
        .unsupported => |diagnostic| diagnostic,
    };
    try std.testing.expectEqualStrings("unsupported_type", rejected.tagName());
    try std.testing.expectEqualStrings("overflow-intrinsic-arg", rejected.detail());
}

test "generic cfg selector inspection admits only empty cold assume bundle" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare void @llvm.assume(i1)
        \\declare void @other()
        \\
        \\define void @accepted() {
        \\entry:
        \\  call void @llvm.assume(i1 true) [ "cold"() ]
        \\  ret void
        \\}
        \\
        \\define void @rejected() {
        \\entry:
        \\  call void @other() [ "cold"() ]
        \\  ret void
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    const accepted = switch (selector.inspectFunction(module.functions.items[0])) {
        .selected => return error.TestExpectedUnsupported,
        .unsupported => |diagnostic| diagnostic,
    };
    try std.testing.expectEqualStrings("no_emitter", accepted.tagName());
    try std.testing.expectEqualStrings("selector-skeleton-has-no-emitters", accepted.detail());

    const rejected = switch (selector.inspectFunction(module.functions.items[1])) {
        .selected => return error.TestExpectedUnsupported,
        .unsupported => |diagnostic| diagnostic,
    };
    try std.testing.expectEqualStrings("unsupported_instruction", rejected.tagName());
    try std.testing.expectEqualStrings("operand-bundle-call", rejected.detail());
}

test "generic cfg selector skeleton preserves recognizer fallback while opt-in" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @add32(i32 %a, i32 %b) {
        \\entry:
        \\  %sum = add i32 %a, %b
        \\  ret i32 %sum
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    var machine = try codegen.x86_64.lowerFunctionWithOptions(
        std.testing.allocator,
        module.target_triple.?,
        module.functions.items[0],
        .{ .generic_cfg_selector = true },
    );
    defer machine.deinit(std.testing.allocator);

    try std.testing.expectEqual(codegen.x86_64.CodegenPath.generic_cfg, machine.codegen_path);
}

test "generic cfg selector reports composed diagnostic over skeleton fallback" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i128 @mul128(i128 %a, i128 %b) {
        \\entry:
        \\  %product = mul i128 %a, %b
        \\  ret i128 %product
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    var machine = codegen.x86_64.MachineFunction.init("mul128", module.functions.items[0].ret_ty);
    defer machine.deinit(std.testing.allocator);

    const result = try selector.tryLower(std.testing.allocator, &machine, module.functions.items[0]);
    const diagnostic = switch (result) {
        .selected => return error.TestExpectedUnsupported,
        .unsupported => |diagnostic| diagnostic,
    };
    try std.testing.expectEqualStrings("no_emitter", diagnostic.tagName());
    try std.testing.expectEqualStrings("composed-block-pair-binary-op", diagnostic.detail());
    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
}

test "generic cfg selector stage two computes cross-block liveness" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @branch_live(i32 %a, i32 %b, i1 %cond) {
        \\entry:
        \\  br i1 %cond, label %then, label %else
        \\then:
        \\  %sum = add i32 %a, %b
        \\  ret i32 %sum
        \\else:
        \\  ret i32 %a
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    const summary = try selector.analyzeStageTwoNoSpillEnvelope(std.testing.allocator, module.functions.items[0]);
    try std.testing.expectEqual(@as(usize, 3), summary.blocks);
    try std.testing.expectEqual(@as(usize, 2), summary.edges);
    try std.testing.expect(summary.max_live_out >= 2);
    try std.testing.expect(!summary.exceedsNoSpill());
}

test "generic cfg selector stage two composes CFG above initial block envelope" {
    const text = try makeBranchChainIr(std.testing.allocator, 17);
    defer std.testing.allocator.free(text);
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    var machine = codegen.x86_64.MachineFunction.init("branch_chain", module.functions.items[0].ret_ty);
    defer machine.deinit(std.testing.allocator);

    const result = try selector.tryLower(std.testing.allocator, &machine, module.functions.items[0]);
    switch (result) {
        .selected => {},
        .unsupported => |diagnostic| {
            std.debug.print("unexpected selector diagnostic {s}: {s}\n", .{ diagnostic.tagName(), diagnostic.detail() });
            return error.TestExpectedSelected;
        },
    }

    try expectNamedInstruction(machine.instructions.items, .label, "b16");
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[machine.instructions.items.len - 1]);
}

test "generic cfg selector stage two composes 65-block CFG" {
    const text = try makeBranchChainIr(std.testing.allocator, 65);
    defer std.testing.allocator.free(text);
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    var machine = codegen.x86_64.MachineFunction.init("branch_chain", module.functions.items[0].ret_ty);
    defer machine.deinit(std.testing.allocator);

    const result = try selector.tryLower(std.testing.allocator, &machine, module.functions.items[0]);
    try std.testing.expectEqual(selector.SelectionResult.selected, result);
    try expectNamedInstruction(machine.instructions.items, .label, "b64");
}

test "generic cfg selector stage two rejects beyond block envelope" {
    const text = try makeBranchChainIr(std.testing.allocator, 129);
    defer std.testing.allocator.free(text);
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    var machine = codegen.x86_64.MachineFunction.init("branch_chain", module.functions.items[0].ret_ty);
    defer machine.deinit(std.testing.allocator);

    const result = try selector.tryLower(std.testing.allocator, &machine, module.functions.items[0]);
    const diagnostic = switch (result) {
        .selected => return error.TestExpectedUnsupported,
        .unsupported => |diagnostic| diagnostic,
    };
    try std.testing.expectEqualStrings("no_spill_envelope", diagnostic.tagName());
    try std.testing.expectEqualStrings("stage2-block-count", diagnostic.detail());
    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
}

test "generic cfg selector reports structured fallback diagnostic through codegen options" {
    const text = try makeBranchChainIr(std.testing.allocator, 129);
    defer std.testing.allocator.free(text);

    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    var diagnostic_tag: ?[]const u8 = null;
    var diagnostic_detail: ?[]const u8 = null;
    try std.testing.expectError(
        error.UnsupportedCodegenControlFlow,
        codegen.x86_64.lowerFunctionWithOptions(
            std.testing.allocator,
            module.target_triple.?,
            module.functions.items[0],
            .{
                .generic_cfg_selector = true,
                .generic_cfg_selector_diagnostic_tag = &diagnostic_tag,
                .generic_cfg_selector_diagnostic_detail = &diagnostic_detail,
            },
        ),
    );
    try std.testing.expectEqualStrings("no_spill_envelope", diagnostic_tag orelse return error.MissingSelectorDiagnostic);
    try std.testing.expectEqualStrings("stage2-block-count", diagnostic_detail orelse return error.MissingSelectorDiagnostic);
}

test "generic cfg selector stage two rejects unsupported loop condition operands" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @loop_live(i32 %a, i32 %b) {
        \\entry:
        \\  br label %loop
        \\loop:
        \\  %sum = add i32 %a, %b
        \\  %again = icmp ult i64 0, 1
        \\  br i1 %again, label %loop, label %exit
        \\exit:
        \\  ret i32 %sum
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    var machine = codegen.x86_64.MachineFunction.init("loop_live", .{ .int = 32 });
    defer machine.deinit(std.testing.allocator);

    const result = try selector.tryLower(std.testing.allocator, &machine, module.functions.items[0]);
    const diagnostic = switch (result) {
        .selected => return error.TestExpectedUnsupported,
        .unsupported => |diagnostic| diagnostic,
    };
    try std.testing.expectEqualStrings("unsupported_value", diagnostic.tagName());
    try std.testing.expectEqualStrings("composed-block-icmp-lhs", diagnostic.detail());
    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
}

test "generic cfg selector emits single-block void return" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define void @void_leaf() {
        \\entry:
        \\  ret void
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    var machine = codegen.x86_64.MachineFunction.init("void_leaf", module.functions.items[0].ret_ty);
    defer machine.deinit(std.testing.allocator);

    const result = try selector.tryLower(std.testing.allocator, &machine, module.functions.items[0]);
    try std.testing.expectEqual(selector.SelectionResult.selected, result);
    try std.testing.expectEqual(@as(usize, 1), machine.instructions.items.len);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[0]);
}

test "generic cfg selector stage two emits cross-block void returns" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define void @void_branch(i64 %n) {
        \\entry:
        \\  %cond = icmp ult i64 %n, 4
        \\  br i1 %cond, label %then, label %else
        \\then:
        \\  ret void
        \\else:
        \\  ret void
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    var machine = codegen.x86_64.MachineFunction.init("void_branch", module.functions.items[0].ret_ty);
    defer machine.deinit(std.testing.allocator);

    const result = try selector.tryLower(std.testing.allocator, &machine, module.functions.items[0]);
    try std.testing.expectEqual(selector.SelectionResult.selected, result);
    try expectNamedInstruction(machine.instructions.items, .jne, "then");
    try expectNamedInstruction(machine.instructions.items, .label, "then");
    try expectNamedInstruction(machine.instructions.items, .label, "else");
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[machine.instructions.items.len - 1]);
}

test "generic cfg selector composes scalar freeze as identity" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i64 @freeze_identity(i64 %x) {
        \\entry:
        \\  %frozen = freeze i64 %x
        \\  ret i64 %frozen
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    var machine = codegen.x86_64.MachineFunction.init("freeze_identity", module.functions.items[0].ret_ty);
    defer machine.deinit(std.testing.allocator);

    const result = try selector.tryLower(std.testing.allocator, &machine, module.functions.items[0]);
    try std.testing.expectEqual(selector.SelectionResult.selected, result);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .mov_arg_rax = .rdi }, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[machine.instructions.items.len - 1]);
}

test "generic cfg selector stage two composes scalar freeze across branch" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i64 @freeze_branch(i64 %x) {
        \\entry:
        \\  %cond = icmp ult i64 %x, 10
        \\  br i1 %cond, label %then, label %else
        \\then:
        \\  %frozen = freeze i64 %x
        \\  ret i64 %frozen
        \\else:
        \\  ret i64 %x
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    var machine = codegen.x86_64.MachineFunction.init("freeze_branch", module.functions.items[0].ret_ty);
    defer machine.deinit(std.testing.allocator);

    const result = try selector.tryLower(std.testing.allocator, &machine, module.functions.items[0]);
    switch (result) {
        .selected => {},
        .unsupported => |diagnostic| {
            std.debug.print("unexpected selector diagnostic {s}: {s}\n", .{ diagnostic.tagName(), diagnostic.detail() });
            return error.TestExpectedSelected;
        },
    }

    try expectNamedInstruction(machine.instructions.items, .label, "then");
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[machine.instructions.items.len - 1]);
}

test "generic cfg selector rejects value-bearing void return" {
    var function = ir.Function.init("bad_void_ret", .void);
    defer function.deinit(std.testing.allocator);

    var block = ir.BasicBlock.init("entry");
    errdefer block.deinit(std.testing.allocator);
    block.terminator = .{ .ret = .{
        .ty = .void,
        .value = .{ .int = 0 },
    } };
    try function.blocks.append(std.testing.allocator, block);

    var machine = codegen.x86_64.MachineFunction.init("bad_void_ret", function.ret_ty);
    defer machine.deinit(std.testing.allocator);

    const result = try selector.tryLower(std.testing.allocator, &machine, function);
    const diagnostic = switch (result) {
        .selected => return error.TestExpectedUnsupported,
        .unsupported => |diagnostic| diagnostic,
    };
    try std.testing.expectEqualStrings("unsupported_value", diagnostic.tagName());
    try std.testing.expectEqualStrings("composed-block-void-ret-value", diagnostic.detail());
    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
}

test "generic cfg selector composes constant i32 stack array gep load store" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @stack_array_const_gep(i32 %x) {
        \\entry:
        \\  %buf = alloca [4 x i32], align 4
        \\  %slot = getelementptr inbounds [4 x i32], ptr %buf, i64 0, i64 2
        \\  store i32 %x, ptr %slot, align 4
        \\  %value = load i32, ptr %slot, align 4
        \\  ret i32 %value
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    var machine = codegen.x86_64.MachineFunction.init("stack_array_const_gep", module.functions.items[0].ret_ty);
    defer machine.deinit(std.testing.allocator);

    const result = try selector.tryLower(std.testing.allocator, &machine, module.functions.items[0]);
    try std.testing.expectEqual(selector.SelectionResult.selected, result);
    try expectInstruction(machine.instructions.items, .{ .sub_rsp_imm32 = 280 });
    try expectInstruction(machine.instructions.items, .{ .store_eax_stack_disp32 = 264 });
    try expectInstruction(machine.instructions.items, .{ .load_stack_disp32_eax = 264 });
    try expectInstruction(machine.instructions.items, .{ .add_rsp_imm32 = 280 });
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[machine.instructions.items.len - 1]);
}

test "generic cfg selector loads element zero directly from stack array" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @stack_array_base_load(i32 %value) {
        \\entry:
        \\  %buf = alloca [4 x i32], align 4
        \\  store i32 %value, ptr %buf, align 4
        \\  %loaded = load i32, ptr %buf, align 4
        \\  ret i32 %loaded
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    var machine = codegen.x86_64.MachineFunction.init("stack_array_base_load", module.functions.items[0].ret_ty);
    defer machine.deinit(std.testing.allocator);

    const result = try selector.tryLower(std.testing.allocator, &machine, module.functions.items[0]);
    try std.testing.expectEqual(selector.SelectionResult.selected, result);
    try expectInstruction(machine.instructions.items, .{ .store_eax_stack_disp32 = 256 });
    try expectInstruction(machine.instructions.items, .{ .load_stack_disp32_eax = 256 });
}

test "generic cfg selector composes dynamic i32 stack array gep index" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @stack_array_dynamic_gep(i64 %i, i32 %x) {
        \\entry:
        \\  %buf = alloca [4 x i32], align 4
        \\  %slot = getelementptr inbounds [4 x i32], ptr %buf, i64 0, i64 %i
        \\  store i32 %x, ptr %slot, align 4
        \\  %value = load i32, ptr %slot, align 4
        \\  ret i32 %value
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    var machine = codegen.x86_64.MachineFunction.init("stack_array_dynamic_gep", module.functions.items[0].ret_ty);
    defer machine.deinit(std.testing.allocator);

    const result = try selector.tryLower(std.testing.allocator, &machine, module.functions.items[0]);
    try std.testing.expectEqual(selector.SelectionResult.selected, result);
    try expectInstruction(machine.instructions.items, .{ .sub_rsp_imm32 = 280 });
    try expectInstruction(machine.instructions.items, .{ .mov_arg64_arg = .{ .dst = .rcx, .src = .rdi } });
    try expectInstruction(machine.instructions.items, .{ .store_eax_stack_rcx4_disp32 = 256 });
    try expectInstruction(machine.instructions.items, .{ .load_stack_rcx4_disp32_eax = 256 });
    try expectInstruction(machine.instructions.items, .{ .add_rsp_imm32 = 280 });
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[machine.instructions.items.len - 1]);
}

test "generic cfg selector composes multiple constant i32 stack arrays in one frame" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @stack_array_pair_const_gep(i32 %x, i32 %y) {
        \\entry:
        \\  %left = alloca [4 x i32], align 4
        \\  %right = alloca [2 x i32], align 4
        \\  %left_slot = getelementptr inbounds [4 x i32], ptr %left, i64 0, i64 2
        \\  %right_slot = getelementptr inbounds [2 x i32], ptr %right, i64 0, i64 1
        \\  store i32 %x, ptr %left_slot, align 4
        \\  store i32 %y, ptr %right_slot, align 4
        \\  %value = load i32, ptr %right_slot, align 4
        \\  ret i32 %value
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    var machine = codegen.x86_64.MachineFunction.init("stack_array_pair_const_gep", module.functions.items[0].ret_ty);
    defer machine.deinit(std.testing.allocator);

    const result = try selector.tryLower(std.testing.allocator, &machine, module.functions.items[0]);
    try std.testing.expectEqual(selector.SelectionResult.selected, result);
    try expectInstruction(machine.instructions.items, .{ .sub_rsp_imm32 = 296 });
    try expectInstruction(machine.instructions.items, .{ .store_eax_stack_disp32 = 264 });
    try expectInstruction(machine.instructions.items, .{ .store_eax_stack_disp32 = 276 });
    try expectInstruction(machine.instructions.items, .{ .load_stack_disp32_eax = 276 });
    try expectInstruction(machine.instructions.items, .{ .add_rsp_imm32 = 296 });
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[machine.instructions.items.len - 1]);
}

test "generic cfg selector stage two composes acyclic branch with labels" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i64 @branch_live(i64 %a, i64 %b) {
        \\entry:
        \\  %cond = icmp ult i64 %a, 10
        \\  br i1 %cond, label %then, label %else
        \\then:
        \\  %sum = add i64 %a, %b
        \\  ret i64 %sum
        \\else:
        \\  ret i64 %a
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    var machine = codegen.x86_64.MachineFunction.init("branch_live", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);

    const result = try selector.tryLower(std.testing.allocator, &machine, module.functions.items[0]);
    switch (result) {
        .selected => {},
        .unsupported => |diagnostic| {
            std.debug.print("unexpected selector diagnostic {s}: {s}\n", .{ diagnostic.tagName(), diagnostic.detail() });
            return std.testing.expectEqualStrings("selected", diagnostic.tagName());
        },
    }

    try expectInstruction(machine.instructions.items, .test_eax_eax);
    try expectNamedInstruction(machine.instructions.items, .jne, "then");
    try expectNamedInstruction(machine.instructions.items, .jmp, "else");
    try expectNamedInstruction(machine.instructions.items, .label, "then");
    try expectNamedInstruction(machine.instructions.items, .label, "else");
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[machine.instructions.items.len - 1]);
}

test "generic cfg selector stage two shares framed return epilogue" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @framed_early_return(i64 %flag, i32 %value) {
        \\entry:
        \\  %buf = alloca [1 x i32], align 4
        \\  %cond = icmp ult i64 %flag, 1
        \\  br i1 %cond, label %early, label %later
        \\early:
        \\  ret i32 1
        \\later:
        \\  %slot = getelementptr inbounds [1 x i32], ptr %buf, i64 0, i64 0
        \\  store i32 %value, ptr %slot, align 4
        \\  %loaded = load i32, ptr %slot, align 4
        \\  ret i32 %loaded
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    var machine = codegen.x86_64.MachineFunction.init("framed_early_return", .{ .int = 32 });
    defer machine.deinit(std.testing.allocator);

    const result = try selector.tryLower(std.testing.allocator, &machine, module.functions.items[0]);
    switch (result) {
        .selected => {},
        .unsupported => |diagnostic| {
            std.debug.print("unexpected selector diagnostic {s}: {s}\n", .{ diagnostic.tagName(), diagnostic.detail() });
            return error.TestExpectedSelected;
        },
    }
    try codegen.x86_64.verifyFunction(machine);

    var restore_count: usize = 0;
    var return_count: usize = 0;
    for (machine.instructions.items) |instruction| switch (instruction) {
        .add_rsp_imm32 => restore_count += 1,
        .ret => return_count += 1,
        else => {},
    };
    try std.testing.expectEqual(@as(usize, 1), restore_count);
    try std.testing.expectEqual(@as(usize, 1), return_count);
    try expectNamedInstruction(machine.instructions.items, .jmp, "__zllvm_stage2_return_generic_cfg_select_end");
    try expectNamedInstruction(machine.instructions.items, .label, "__zllvm_stage2_return_generic_cfg_select_end");
}

test "generic cfg selector stage two materializes unconditional phi edges" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i64 @branch_phi(i64 %a, i64 %b) {
        \\entry:
        \\  %cond = icmp ult i64 %a, 10
        \\  br i1 %cond, label %then, label %else
        \\then:
        \\  %left = add i64 %a, 1
        \\  br label %merge
        \\else:
        \\  %right = add i64 %b, 2
        \\  br label %merge
        \\merge:
        \\  %value = phi i64 [ %left, %then ], [ %right, %else ]
        \\  ret i64 %value
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    var machine = codegen.x86_64.MachineFunction.init("branch_phi", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);

    const result = try selector.tryLower(std.testing.allocator, &machine, module.functions.items[0]);
    switch (result) {
        .selected => {},
        .unsupported => |diagnostic| {
            std.debug.print("unexpected selector diagnostic {s}: {s}\n", .{ diagnostic.tagName(), diagnostic.detail() });
            return std.testing.expectEqualStrings("selected", diagnostic.tagName());
        },
    }

    var phi_moves: usize = 0;
    for (machine.instructions.items) |instruction| {
        switch (instruction) {
            .mov_arg64_arg => |mov| {
                if (mov.dst == .r8) phi_moves += 1;
            },
            else => {},
        }
    }
    try std.testing.expectEqual(@as(usize, 2), phi_moves);
    try expectNamedInstruction(machine.instructions.items, .label, "merge");
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[machine.instructions.items.len - 1]);
}

test "generic cfg selector stage two materializes pointer phi edges" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @ptr_phi(ptr %a, ptr %b, i32 %value, i64 %choice) {
        \\entry:
        \\  %cond = icmp ult i64 %choice, 1
        \\  br i1 %cond, label %left, label %right
        \\left:
        \\  br label %merge
        \\right:
        \\  br label %merge
        \\merge:
        \\  %ptr = phi ptr [ %a, %left ], [ %b, %right ]
        \\  store i32 %value, ptr %ptr, align 4
        \\  ret i32 %value
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    var machine = codegen.x86_64.MachineFunction.init("ptr_phi", .{ .int = 32 });
    defer machine.deinit(std.testing.allocator);

    const result = try selector.tryLower(std.testing.allocator, &machine, module.functions.items[0]);
    switch (result) {
        .selected => {},
        .unsupported => |diagnostic| {
            std.debug.print("unexpected selector diagnostic {s}: {s}\n", .{ diagnostic.tagName(), diagnostic.detail() });
            return std.testing.expectEqualStrings("selected", diagnostic.tagName());
        },
    }

    try expectInstruction(machine.instructions.items, .{ .mov_arg64_arg = .{ .dst = .r8, .src = .rdi } });
    try expectInstruction(machine.instructions.items, .{ .mov_arg64_arg = .{ .dst = .r8, .src = .rsi } });
    try expectInstruction(machine.instructions.items, .{ .store_eax_arg_ptr = .r8 });
    try expectNamedInstruction(machine.instructions.items, .label, "merge");
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[machine.instructions.items.len - 1]);
}

test "generic cfg selector stage two ignores tail llvm assume" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @tail_assume(i32 %x) {
        \\entry:
        \\  %cond = icmp eq i32 %x, 0
        \\  tail call void @llvm.assume(i1 %cond)
        \\  %sum = add i32 %x, 1
        \\  ret i32 %sum
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    var machine = codegen.x86_64.MachineFunction.init("tail_assume", .{ .int = 32 });
    defer machine.deinit(std.testing.allocator);

    const result = try selector.tryLower(std.testing.allocator, &machine, module.functions.items[0]);
    switch (result) {
        .selected => {},
        .unsupported => |diagnostic| {
            std.debug.print("unexpected selector diagnostic {s}: {s}\n", .{ diagnostic.tagName(), diagnostic.detail() });
            return std.testing.expectEqualStrings("selected", diagnostic.tagName());
        },
    }

    for (machine.instructions.items) |instruction| {
        switch (instruction) {
            .direct_call => |call| try std.testing.expect(!std.mem.eql(u8, call.symbol, "llvm.assume")),
            else => {},
        }
    }
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[machine.instructions.items.len - 1]);
}

test "generic cfg selector stage two lowers tail int byte size helper" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @tail_int_byte_size(i32 %bits32) {
        \\entry:
        \\  %bits = trunc i32 %bits32 to i16
        \\  %bytes = tail call fastcc i16 @zig.target.intByteSize(i16 %bits)
        \\  %wide = zext i16 %bytes to i32
        \\  ret i32 %wide
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    var machine = codegen.x86_64.MachineFunction.init("tail_int_byte_size", .{ .int = 32 });
    defer machine.deinit(std.testing.allocator);

    const result = try selector.tryLower(std.testing.allocator, &machine, module.functions.items[0]);
    switch (result) {
        .selected => {},
        .unsupported => |diagnostic| {
            std.debug.print("unexpected selector diagnostic {s}: {s}\n", .{ diagnostic.tagName(), diagnostic.detail() });
            return std.testing.expectEqualStrings("selected", diagnostic.tagName());
        },
    }

    var saw_int_byte_size = false;
    for (machine.instructions.items) |instruction| {
        switch (instruction) {
            .direct_call => |call| {
                if (std.mem.eql(u8, call.symbol, "zig.target.intByteSize")) {
                    saw_int_byte_size = true;
                    try std.testing.expect(call.ret_ty.eql(.{ .int = 16 }));
                }
            },
            else => {},
        }
    }
    try std.testing.expect(saw_int_byte_size);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[machine.instructions.items.len - 1]);
}

test "generic cfg selector stage two materializes conditional phi edge blocks" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i64 @cond_phi_edge(i64 %a, i64 %b) {
        \\entry:
        \\  %cond = icmp ult i64 %a, 10
        \\  br i1 %cond, label %merge, label %else
        \\else:
        \\  br label %merge
        \\merge:
        \\  %value = phi i64 [ %a, %entry ], [ %b, %else ]
        \\  ret i64 %value
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    var machine = codegen.x86_64.MachineFunction.init("cond_phi_edge", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);

    const result = try selector.tryLower(std.testing.allocator, &machine, module.functions.items[0]);
    switch (result) {
        .selected => {},
        .unsupported => |diagnostic| {
            std.debug.print("unexpected selector diagnostic {s}: {s}\n", .{ diagnostic.tagName(), diagnostic.detail() });
            return std.testing.expectEqualStrings("selected", diagnostic.tagName());
        },
    }

    try expectNamedInstruction(machine.instructions.items, .label, "__zllvm_stage2_phi_edge_0");
    try expectNamedInstruction(machine.instructions.items, .jmp, "merge");
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[machine.instructions.items.len - 1]);
}

test "generic cfg selector stage two materializes loop backedge phi moves" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i64 @loop_phi(i64 %a) {
        \\entry:
        \\  br label %loop
        \\loop:
        \\  %iv = phi i64 [ %a, %entry ], [ %next, %loop ]
        \\  %next = add i64 %iv, 1
        \\  %cond = icmp ult i64 %next, 5
        \\  br i1 %cond, label %loop, label %exit
        \\exit:
        \\  %out = phi i64 [ %next, %loop ]
        \\  ret i64 %out
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    var machine = codegen.x86_64.MachineFunction.init("loop_phi", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);

    const result = try selector.tryLower(std.testing.allocator, &machine, module.functions.items[0]);
    switch (result) {
        .selected => {},
        .unsupported => |diagnostic| {
            std.debug.print("unexpected selector diagnostic {s}: {s}\n", .{ diagnostic.tagName(), diagnostic.detail() });
            return std.testing.expectEqualStrings("selected", diagnostic.tagName());
        },
    }

    try expectNamedInstruction(machine.instructions.items, .label, "loop");
    try expectNamedInstruction(machine.instructions.items, .label, "__zllvm_stage2_phi_edge_0");
    try expectNamedInstruction(machine.instructions.items, .jmp, "loop");
    try expectNamedInstruction(machine.instructions.items, .label, "exit");
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[machine.instructions.items.len - 1]);
}

test "generic cfg selector materializes displaced phi destinations" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i64 @spilled_phi(i64 %limit, i32 %value, i32 %amount) {
        \\entry:
        \\  br label %loop
        \\loop:
        \\  %acc = phi i64 [ 1, %entry ], [ %next_acc, %body ]
        \\  %carry = phi i64 [ 2, %entry ], [ %next_carry, %body ]
        \\  %index = phi i64 [ 0, %entry ], [ %next_index, %body ]
        \\  %done = icmp eq i64 %index, %limit
        \\  br i1 %done, label %exit, label %body
        \\body:
        \\  %shifted = shl i32 %value, %amount
        \\  %wide = zext i32 %shifted to i64
        \\  %next_acc = add i64 %acc, %wide
        \\  %next_carry = add i64 %carry, 1
        \\  %next_index = add i64 %index, 1
        \\  br label %loop
        \\exit:
        \\  ret i64 %acc
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    var machine = codegen.x86_64.MachineFunction.init("spilled_phi", module.functions.items[0].ret_ty);
    defer machine.deinit(std.testing.allocator);

    const result = try selector.tryLower(std.testing.allocator, &machine, module.functions.items[0]);
    switch (result) {
        .selected => {},
        .unsupported => |diagnostic| {
            std.debug.print("unexpected selector diagnostic {s}: {s}\n", .{ diagnostic.tagName(), diagnostic.detail() });
            return error.TestExpectedSelected;
        },
    }

    try expectInstruction(machine.instructions.items, .shl_eax_cl);
    try expectInstructionTag(machine.instructions.items, .spill_arg64_rsp);
    try expectInstructionTag(machine.instructions.items, .reload_arg64_rsp);
}

test "generic cfg selector stage two composes i32 multiply loop" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @mul_loop_i32(i32 %a, i32 %b) {
        \\entry:
        \\  %zero = icmp eq i32 %a, 0
        \\  br i1 %zero, label %exit, label %loop
        \\loop:
        \\  %multiplicand = phi i32 [ %next_multiplicand, %loop ], [ %a, %entry ]
        \\  %multiplier = phi i32 [ %next_multiplier, %loop ], [ %b, %entry ]
        \\  %acc = phi i32 [ %next_acc, %loop ], [ 0, %entry ]
        \\  %low_bit = and i32 %multiplicand, 1
        \\  %skip_add = icmp eq i32 %low_bit, 0
        \\  %addend = select i1 %skip_add, i32 0, i32 %multiplier
        \\  %next_acc = add i32 %addend, %acc
        \\  %next_multiplicand = lshr i32 %multiplicand, 1
        \\  %next_multiplier = shl i32 %multiplier, 1
        \\  %done = icmp eq i32 %next_multiplicand, 0
        \\  br i1 %done, label %exit, label %loop
        \\exit:
        \\  %result = phi i32 [ 0, %entry ], [ %next_acc, %loop ]
        \\  ret i32 %result
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    const summary = try selector.analyzeStageTwoNoSpillEnvelope(std.testing.allocator, module.functions.items[0]);
    try std.testing.expectEqual(@as(usize, 4), summary.max_pressure);
    try std.testing.expect(!summary.exceedsNoSpill());

    var machine = codegen.x86_64.MachineFunction.init("mul_loop_i32", module.functions.items[0].ret_ty);
    defer machine.deinit(std.testing.allocator);

    const result = try selector.tryLower(std.testing.allocator, &machine, module.functions.items[0]);
    switch (result) {
        .selected => {},
        .unsupported => |diagnostic| {
            std.debug.print("unexpected selector diagnostic {s}: {s}\n", .{ diagnostic.tagName(), diagnostic.detail() });
            return std.testing.expectEqualStrings("selected", diagnostic.tagName());
        },
    }

    try expectInstruction(machine.instructions.items, .{ .mov_eax_to_arg = .rdx });
    try expectInstruction(machine.instructions.items, .{ .shl_eax_imm5 = 1 });
    try expectNamedInstruction(machine.instructions.items, .label, "loop");
    try expectNamedInstruction(machine.instructions.items, .label, "exit");
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[machine.instructions.items.len - 1]);
}

test "generic cfg selector stage two composes variable i32 shifts" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @variable_shl(i32 %value, i32 %amount) {
        \\entry:
        \\  %result = shl i32 %value, %amount
        \\  ret i32 %result
        \\}
        \\
        \\define i32 @variable_lshr(i32 %value, i32 %amount) {
        \\entry:
        \\  %result = lshr i32 %value, %amount
        \\  ret i32 %result
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    for (module.functions.items, 0..) |function, index| {
        var machine = codegen.x86_64.MachineFunction.init(function.name, function.ret_ty);
        defer machine.deinit(std.testing.allocator);

        const result = try selector.tryLower(std.testing.allocator, &machine, function);
        switch (result) {
            .selected => {},
            .unsupported => |diagnostic| {
                std.debug.print("unexpected selector diagnostic {s}: {s}\n", .{ diagnostic.tagName(), diagnostic.detail() });
                return error.TestExpectedSelected;
            },
        }

        try expectInstruction(machine.instructions.items, if (index == 0) .shl_eax_cl else .shr_eax_cl);
    }
}

test "generic cfg selector stage two computes pressure above no-spill envelope" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @pressure(i32 %a, i32 %b, i32 %c, i32 %d, i32 %e, i32 %f, i32 %g) {
        \\entry:
        \\  br label %body
        \\body:
        \\  %s1 = add i32 %a, %b
        \\  %s2 = add i32 %c, %d
        \\  %s3 = add i32 %e, %f
        \\  %s4 = add i32 %s1, %s2
        \\  %s5 = add i32 %s4, %s3
        \\  %s6 = add i32 %s5, %g
        \\  ret i32 %s6
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    const summary = try selector.analyzeStageTwoNoSpillEnvelope(std.testing.allocator, module.functions.items[0]);
    try std.testing.expectEqual(@as(usize, 2), summary.blocks);
    try std.testing.expect(summary.max_pressure > summary.no_spill_limit);
    try std.testing.expect(summary.exceedsNoSpill());
    try std.testing.expectEqual(@as(usize, 32), summary.spill_slot_count);
    try std.testing.expectEqual(@as(usize, 1), summary.max_pressure_spill_slots_needed);
    try std.testing.expectEqual(@as(usize, 0), summary.max_pressure_spill_slots_over_envelope);
    try std.testing.expectEqualStrings("-", summary.first_exceeding_block);
    try std.testing.expectEqual(@as(usize, 0), summary.first_exceeding_live_values);
    try std.testing.expect(!summary.exceedsSpillEnvelope());
}

test "generic cfg selector stage two reports intra-block pressure" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @single_block_pressure(i32 %a, i32 %b, i32 %c, i32 %d, i32 %e, i32 %f, i32 %g, i32 %h) {
        \\entry:
        \\  %p1 = add i32 %a, %b
        \\  %p2 = add i32 %c, %d
        \\  %p3 = add i32 %e, %f
        \\  %p4 = add i32 %g, %h
        \\  %s1 = add i32 %p1, %p2
        \\  %s2 = add i32 %p3, %p4
        \\  %result = add i32 %s1, %s2
        \\  ret i32 %result
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    const summary = try selector.analyzeStageTwoNoSpillEnvelope(std.testing.allocator, module.functions.items[0]);
    try std.testing.expectEqual(@as(usize, 1), summary.blocks);
    try std.testing.expectEqual(@as(usize, 0), summary.max_live_in);
    try std.testing.expectEqual(@as(usize, 0), summary.max_live_out);
    try std.testing.expectEqual(@as(usize, 8), summary.max_pressure);
    try std.testing.expectEqualStrings("entry", summary.max_pressure_block);
    try std.testing.expectEqualStrings("p1", summary.max_pressure_boundary);
    try std.testing.expect(summary.exceedsNoSpill());
    try std.testing.expect(!summary.exceedsSpillEnvelope());
    try std.testing.expectEqual(@as(usize, 2), summary.max_pressure_spill_slots_needed);
    try std.testing.expectEqual(@as(usize, 0), summary.max_pressure_spill_slots_over_envelope);
    try std.testing.expectEqualStrings("-", summary.first_exceeding_block);
}

test "generic cfg selector stage two rejects pressure above spill envelope" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @pressure(i32 %a, i32 %b, i32 %c, i32 %d, i32 %e, i32 %f) {
        \\entry:
        \\  %p1 = add i32 %a, %b
        \\  %p2 = add i32 %c, %d
        \\  %p3 = add i32 %e, %f
        \\  %p4 = add i32 %a, %f
        \\  %p5 = add i32 %b, %e
        \\  %p6 = add i32 %c, %f
        \\  %p7 = add i32 %d, %e
        \\  %p8 = add i32 %a, %c
        \\  %p9 = add i32 %a, %d
        \\  %p10 = add i32 %a, %e
        \\  %p11 = add i32 %a, %f
        \\  %p12 = add i32 %b, %c
        \\  %p13 = add i32 %b, %d
        \\  %p14 = add i32 %b, %f
        \\  %p15 = add i32 %c, %e
        \\  %p16 = add i32 %d, %f
        \\  %p17 = add i32 %a, %p1
        \\  %p18 = add i32 %b, %p2
        \\  %p19 = add i32 %c, %p3
        \\  %p20 = add i32 %d, %p4
        \\  %p21 = add i32 %e, %p5
        \\  %p22 = add i32 %f, %p6
        \\  %p23 = add i32 %p1, %p7
        \\  %p24 = add i32 %p2, %p8
        \\  %p25 = add i32 %p3, %p9
        \\  %p26 = add i32 %p4, %p10
        \\  %p27 = add i32 %p5, %p11
        \\  %p28 = add i32 %p6, %p12
        \\  %p29 = add i32 %p7, %p13
        \\  %p30 = add i32 %p8, %p14
        \\  %p31 = add i32 %p9, %p15
        \\  %p32 = add i32 %p10, %p16
        \\  %p33 = add i32 %p11, %p17
        \\  br label %body
        \\body:
        \\  %s1 = add i32 %a, %b
        \\  %s2 = add i32 %c, %d
        \\  %s3 = add i32 %e, %f
        \\  %s4 = add i32 %p1, %p2
        \\  %s5 = add i32 %p3, %p4
        \\  %s6 = add i32 %p5, %p6
        \\  %s7 = add i32 %p7, %p8
        \\  %s8 = add i32 %s1, %s2
        \\  %s9 = add i32 %s3, %s4
        \\  %s10 = add i32 %s5, %s6
        \\  %s11 = add i32 %s7, %s8
        \\  %s12 = add i32 %s9, %s10
        \\  %s13 = add i32 %p9, %p10
        \\  %s14 = add i32 %p11, %p12
        \\  %s15 = add i32 %p13, %p14
        \\  %s16 = add i32 %p15, %p16
        \\  %s17 = add i32 %p17, %p18
        \\  %s18 = add i32 %p19, %p20
        \\  %s19 = add i32 %p21, %p22
        \\  %s20 = add i32 %p23, %p24
        \\  %s21 = add i32 %p25, %p26
        \\  %s22 = add i32 %p27, %p28
        \\  %s23 = add i32 %p29, %p30
        \\  %s24 = add i32 %p31, %p32
        \\  %s25 = add i32 %p33, %s11
        \\  %s26 = add i32 %s12, %s13
        \\  %s27 = add i32 %s14, %s15
        \\  %s28 = add i32 %s16, %s17
        \\  %s29 = add i32 %s18, %s19
        \\  %s30 = add i32 %s20, %s21
        \\  %s31 = add i32 %s22, %s23
        \\  %s32 = add i32 %s24, %s25
        \\  %s33 = add i32 %s26, %s27
        \\  %s34 = add i32 %s28, %s29
        \\  %s35 = add i32 %s30, %s31
        \\  %s36 = add i32 %s32, %s33
        \\  %s37 = add i32 %s34, %s35
        \\  %s38 = add i32 %s36, %s37
        \\  ret i32 %s38
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    const summary = try selector.analyzeStageTwoNoSpillEnvelope(std.testing.allocator, module.functions.items[0]);
    try std.testing.expect(summary.max_pressure > summary.spill_envelope_limit);
    try std.testing.expect(summary.exceedsSpillEnvelope());
    try std.testing.expectEqualStrings("entry", summary.max_pressure_block);
    try std.testing.expectEqualStrings("terminator", summary.max_pressure_boundary);
    try std.testing.expectEqual(summary.max_pressure - summary.no_spill_limit, summary.max_pressure_spill_slots_needed);
    try std.testing.expect(summary.max_pressure_spill_slots_over_envelope > 0);
    try std.testing.expectEqualStrings("entry", summary.first_exceeding_block);
    try std.testing.expectEqualStrings("terminator", summary.first_exceeding_boundary);
    try std.testing.expect(summary.first_exceeding_live_values > summary.spill_envelope_limit);

    var machine = codegen.x86_64.MachineFunction.init("pressure", module.functions.items[0].ret_ty);
    defer machine.deinit(std.testing.allocator);

    const result = try selector.tryLower(std.testing.allocator, &machine, module.functions.items[0]);
    const diagnostic = switch (result) {
        .selected => return error.TestExpectedUnsupported,
        .unsupported => |diagnostic| diagnostic,
    };
    try std.testing.expectEqualStrings("no_spill_envelope", diagnostic.tagName());
    try std.testing.expectEqualStrings("stage2-register-pressure", diagnostic.detail());
    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
}

test "generic cfg selector stage two excludes stack objects from register pressure" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @stack_pressure(i32 %a, i32 %b, i32 %c, i32 %d, i32 %e, i32 %f, i1 %cond) {
        \\entry:
        \\  %slot = alloca [4 x i32], align 4
        \\  %ptr = getelementptr inbounds [4 x i32], ptr %slot, i64 0, i64 0
        \\  store i32 %a, ptr %ptr, align 4
        \\  br i1 %cond, label %body, label %exit
        \\body:
        \\  %loaded = load i32, ptr %ptr, align 4
        \\  %s1 = add i32 %a, %b
        \\  %s2 = add i32 %c, %d
        \\  %s3 = add i32 %e, %f
        \\  %s4 = add i32 %s1, %s2
        \\  %s5 = add i32 %s4, %s3
        \\  %s6 = add i32 %s5, %loaded
        \\  ret i32 %s6
        \\exit:
        \\  ret i32 %a
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    const summary = try selector.analyzeStageTwoNoSpillEnvelope(std.testing.allocator, module.functions.items[0]);
    try std.testing.expectEqual(@as(usize, 3), summary.blocks);
    try std.testing.expectEqual(@as(usize, 7), summary.max_pressure);
    try std.testing.expect(summary.exceedsNoSpill());
    try std.testing.expect(!summary.exceedsSpillEnvelope());
}

test "generic cfg selector composes single-block i32 add through machine instructions" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @add32(i32 %a, i32 %b) {
        \\entry:
        \\  %sum = add i32 %a, %b
        \\  ret i32 %sum
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    var machine = codegen.x86_64.MachineFunction.init("add32", module.functions.items[0].ret_ty);
    defer machine.deinit(std.testing.allocator);

    const result = try selector.tryLower(std.testing.allocator, &machine, module.functions.items[0]);
    switch (result) {
        .selected => {},
        .unsupported => |diagnostic| {
            std.debug.print("unexpected selector diagnostic {s}: {s}\n", .{ diagnostic.tagName(), diagnostic.detail() });
            return error.TestExpectedSelected;
        },
    }

    try std.testing.expectEqual(@as(usize, 3), machine.instructions.items.len);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .mov_arg_eax = .rdi }, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .binary_arg_eax = .{ .op = .add, .reg = .rsi } }, machine.instructions.items[1]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[2]);
}

test "generic cfg selector composes i64 unsigned quotient through assigned registers" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i64 @quotient(i64 %a, i64 %b) {
        \\entry:
        \\  %q = udiv i64 %a, %b
        \\  ret i64 %q
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    var machine = codegen.x86_64.MachineFunction.init("quotient", module.functions.items[0].ret_ty);
    defer machine.deinit(std.testing.allocator);

    const result = try selector.tryLower(std.testing.allocator, &machine, module.functions.items[0]);
    switch (result) {
        .selected => {},
        .unsupported => |diagnostic| {
            std.debug.print("unexpected selector diagnostic {s}: {s}\n", .{ diagnostic.tagName(), diagnostic.detail() });
            return error.TestExpectedSelected;
        },
    }

    try std.testing.expectEqual(@as(usize, 5), machine.instructions.items.len);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .mov_arg_rax = .rdi }, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .mov_arg64_arg = .{ .dst = .rcx, .src = .rsi } }, machine.instructions.items[1]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.xor_edx_edx, machine.instructions.items[2]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .div_arg64 = .rcx }, machine.instructions.items[3]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[4]);
}

test "generic cfg selector composes i64 low32 mask through zero-extending eax" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i64 @mask64(i64 %x) {
        \\entry:
        \\  %masked = and i64 %x, 4294967295
        \\  ret i64 %masked
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    var machine = codegen.x86_64.MachineFunction.init("mask64", module.functions.items[0].ret_ty);
    defer machine.deinit(std.testing.allocator);

    const result = try selector.tryLower(std.testing.allocator, &machine, module.functions.items[0]);
    switch (result) {
        .selected => {},
        .unsupported => |diagnostic| {
            std.debug.print("unexpected selector diagnostic {s}: {s}\n", .{ diagnostic.tagName(), diagnostic.detail() });
            return error.TestExpectedSelected;
        },
    }

    try std.testing.expectEqual(@as(usize, 3), machine.instructions.items.len);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .mov_arg_rax = .rdi }, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .and_eax_imm32 = -1 }, machine.instructions.items[1]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[2]);
}

test "generic cfg selector composes i64 immediate left shift through rax" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i64 @shift64(i64 %x) {
        \\entry:
        \\  %shifted = shl i64 %x, 32
        \\  ret i64 %shifted
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    var machine = codegen.x86_64.MachineFunction.init("shift64", module.functions.items[0].ret_ty);
    defer machine.deinit(std.testing.allocator);

    const result = try selector.tryLower(std.testing.allocator, &machine, module.functions.items[0]);
    switch (result) {
        .selected => {},
        .unsupported => |diagnostic| {
            std.debug.print("unexpected selector diagnostic {s}: {s}\n", .{ diagnostic.tagName(), diagnostic.detail() });
            return error.TestExpectedSelected;
        },
    }

    try std.testing.expectEqual(@as(usize, 3), machine.instructions.items.len);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .mov_arg_rax = .rdi }, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .shl_rax_imm6 = 32 }, machine.instructions.items[1]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[2]);
}

test "generic cfg selector composes zext i64 to i128 through zero high lane" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i128 @widen64(i64 %x) {
        \\entry:
        \\  %wide = zext i64 %x to i128
        \\  ret i128 %wide
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    var machine = codegen.x86_64.MachineFunction.init("widen64", module.functions.items[0].ret_ty);
    defer machine.deinit(std.testing.allocator);

    const result = try selector.tryLower(std.testing.allocator, &machine, module.functions.items[0]);
    switch (result) {
        .selected => {},
        .unsupported => |diagnostic| {
            std.debug.print("unexpected selector diagnostic {s}: {s}\n", .{ diagnostic.tagName(), diagnostic.detail() });
            return error.TestExpectedSelected;
        },
    }

    try std.testing.expectEqual(@as(usize, 5), machine.instructions.items.len);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .mov_arg64_arg = .{ .dst = .rcx, .src = .rdi } }, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .mov_imm_rdx = 0 }, machine.instructions.items[1]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .mov_arg64_arg = .{ .dst = .rdi, .src = .rcx } }, machine.instructions.items[2]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .mov_arg_rax = .rdi }, machine.instructions.items[3]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[4]);
}

test "generic cfg selector composes narrow zext to i64 through eax" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i64 @widen16(i32 %x) {
        \\entry:
        \\  %narrow = trunc i32 %x to i16
        \\  %wide = zext i16 %narrow to i64
        \\  ret i64 %wide
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    var machine = codegen.x86_64.MachineFunction.init("widen16", module.functions.items[0].ret_ty);
    defer machine.deinit(std.testing.allocator);

    const result = try selector.tryLower(std.testing.allocator, &machine, module.functions.items[0]);
    switch (result) {
        .selected => {},
        .unsupported => |diagnostic| {
            std.debug.print("unexpected selector diagnostic {s}: {s}\n", .{ diagnostic.tagName(), diagnostic.detail() });
            return error.TestExpectedSelected;
        },
    }

    try std.testing.expectEqual(@as(usize, 3), machine.instructions.items.len);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .mov_arg_eax = .rdi }, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .and_eax_imm32 = 0xffff }, machine.instructions.items[1]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[2]);
}

test "generic cfg selector composes dynamic byte pointer gep" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define void @byte_gep(ptr %dst, i64 %offset, i32 %value) {
        \\entry:
        \\  %ptr = getelementptr inbounds i8, ptr %dst, i64 %offset
        \\  store i32 %value, ptr %ptr, align 4
        \\  ret void
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    var machine = codegen.x86_64.MachineFunction.init("byte_gep", module.functions.items[0].ret_ty);
    defer machine.deinit(std.testing.allocator);

    const result = try selector.tryLower(std.testing.allocator, &machine, module.functions.items[0]);
    switch (result) {
        .selected => {},
        .unsupported => |diagnostic| {
            std.debug.print("unexpected selector diagnostic {s}: {s}\n", .{ diagnostic.tagName(), diagnostic.detail() });
            return error.TestExpectedSelected;
        },
    }

    try expectInstruction(machine.instructions.items, .add_r8_rcx);
    try expectInstruction(machine.instructions.items, .{ .store_eax_arg_ptr = .rcx });
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[machine.instructions.items.len - 1]);
}

test "generic cfg selector composes constant byte pointer gep" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define void @byte_gep_const(ptr %dst, i32 %value) {
        \\entry:
        \\  %ptr = getelementptr inbounds i8, ptr %dst, i64 4
        \\  store i32 %value, ptr %ptr, align 4
        \\  ret void
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    var machine = codegen.x86_64.MachineFunction.init("byte_gep_const", module.functions.items[0].ret_ty);
    defer machine.deinit(std.testing.allocator);

    const result = try selector.tryLower(std.testing.allocator, &machine, module.functions.items[0]);
    switch (result) {
        .selected => {},
        .unsupported => |diagnostic| {
            std.debug.print("unexpected selector diagnostic {s}: {s}\n", .{ diagnostic.tagName(), diagnostic.detail() });
            return error.TestExpectedSelected;
        },
    }

    try expectInstruction(machine.instructions.items, .{ .add_rcx_imm32 = 4 });
    try expectInstruction(machine.instructions.items, .{ .store_eax_arg_ptr = .rcx });
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[machine.instructions.items.len - 1]);
}

test "generic cfg selector folds constant byte gep into stack array pointer" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @stack_byte_gep(i64 %index, i32 %value) {
        \\entry:
        \\  %slot = alloca [3 x i32], align 4
        \\  %base = getelementptr inbounds [3 x i32], ptr %slot, i64 0, i64 %index
        \\  store i32 11, ptr %base, align 4
        \\  %next = getelementptr i8, ptr %base, i64 4
        \\  store i32 %value, ptr %next, align 4
        \\  %base_value = load i32, ptr %base, align 4
        \\  ret i32 %base_value
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    var machine = codegen.x86_64.MachineFunction.init("stack_byte_gep", module.functions.items[0].ret_ty);
    defer machine.deinit(std.testing.allocator);

    const result = try selector.tryLower(std.testing.allocator, &machine, module.functions.items[0]);
    switch (result) {
        .selected => {},
        .unsupported => |diagnostic| {
            std.debug.print("unexpected selector diagnostic {s}: {s}\n", .{ diagnostic.tagName(), diagnostic.detail() });
            return error.TestExpectedSelected;
        },
    }

    try expectInstruction(machine.instructions.items, .{ .store_eax_stack_rcx4_disp32 = 256 });
    try expectInstruction(machine.instructions.items, .{ .store_eax_stack_rcx4_disp32 = 260 });
    try expectInstruction(machine.instructions.items, .{ .load_stack_rcx4_disp32_eax = 256 });
}

test "generic cfg selector composes direct local i32 element gep" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @stack_element_gep(i64 %index, i32 %value) {
        \\entry:
        \\  %slot = alloca [4 x i32], align 4
        \\  %base = getelementptr [4 x i32], ptr %slot, i64 0, i64 0
        \\  store i32 11, ptr %base, align 4
        \\  %element = getelementptr [4 x i8], ptr %slot, i64 %index
        \\  store i32 %value, ptr %element, align 4
        \\  %base_value = load i32, ptr %base, align 4
        \\  ret i32 %base_value
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    var machine = codegen.x86_64.MachineFunction.init("stack_element_gep", module.functions.items[0].ret_ty);
    defer machine.deinit(std.testing.allocator);

    const result = try selector.tryLower(std.testing.allocator, &machine, module.functions.items[0]);
    switch (result) {
        .selected => {},
        .unsupported => |diagnostic| {
            std.debug.print("unexpected selector diagnostic {s}: {s}\n", .{ diagnostic.tagName(), diagnostic.detail() });
            return error.TestExpectedSelected;
        },
    }

    try expectInstruction(machine.instructions.items, .{ .store_eax_stack_rcx4_disp32 = 256 });
}

test "generic cfg selector combines chained stack array indices" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @stack_chained_gep(i64 %base_index, i64 %offset, i32 %value) {
        \\entry:
        \\  %slot = alloca [4 x i32], align 4
        \\  %base = getelementptr inbounds [4 x i32], ptr %slot, i64 0, i64 %base_index
        \\  store i32 11, ptr %base, align 4
        \\  %next = getelementptr [4 x i8], ptr %base, i64 %offset
        \\  store i32 %value, ptr %next, align 4
        \\  %base_value = load i32, ptr %base, align 4
        \\  ret i32 %base_value
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    var machine = codegen.x86_64.MachineFunction.init("stack_chained_gep", module.functions.items[0].ret_ty);
    defer machine.deinit(std.testing.allocator);

    const result = try selector.tryLower(std.testing.allocator, &machine, module.functions.items[0]);
    switch (result) {
        .selected => {},
        .unsupported => |diagnostic| {
            std.debug.print("unexpected selector diagnostic {s}: {s}\n", .{ diagnostic.tagName(), diagnostic.detail() });
            return error.TestExpectedSelected;
        },
    }

    try expectInstruction(machine.instructions.items, .add_r8_rcx);
    try expectInstruction(machine.instructions.items, .{ .store_eax_stack_rcx4_disp32 = 256 });
}

test "generic cfg selector composes i64 immediate mask" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i64 @mask64(i64 %value) {
        \\entry:
        \\  %masked = and i64 %value, 7
        \\  ret i64 %masked
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    var machine = codegen.x86_64.MachineFunction.init("mask64", module.functions.items[0].ret_ty);
    defer machine.deinit(std.testing.allocator);

    const result = try selector.tryLower(std.testing.allocator, &machine, module.functions.items[0]);
    switch (result) {
        .selected => {},
        .unsupported => |diagnostic| {
            std.debug.print("unexpected selector diagnostic {s}: {s}\n", .{ diagnostic.tagName(), diagnostic.detail() });
            return error.TestExpectedSelected;
        },
    }

    try expectInstruction(machine.instructions.items, .{ .mov_imm_rcx = 7 });
    try expectInstruction(machine.instructions.items, .{ .binary_arg_rax = .{ .op = .@"and", .reg = .rcx } });
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[machine.instructions.items.len - 1]);
}

test "generic cfg selector composes i64 equality immediate" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @eq64(i64 %value) {
        \\entry:
        \\  %equal = icmp eq i64 %value, 28
        \\  %result = zext i1 %equal to i32
        \\  ret i32 %result
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    var machine = codegen.x86_64.MachineFunction.init("eq64", module.functions.items[0].ret_ty);
    defer machine.deinit(std.testing.allocator);

    const result = try selector.tryLower(std.testing.allocator, &machine, module.functions.items[0]);
    switch (result) {
        .selected => {},
        .unsupported => |diagnostic| {
            std.debug.print("unexpected selector diagnostic {s}: {s}\n", .{ diagnostic.tagName(), diagnostic.detail() });
            return error.TestExpectedSelected;
        },
    }

    try expectInstruction(machine.instructions.items, .{ .cmp_arg64_imm64 = .{ .reg = .rcx, .imm = 28 } });
    try expectInstruction(machine.instructions.items, .sete_eax);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[machine.instructions.items.len - 1]);
}

test "generic cfg selector composes i64 equality values" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @eq64_values(i64 %lhs, i64 %rhs) {
        \\entry:
        \\  %equal = icmp eq i64 %lhs, %rhs
        \\  %result = zext i1 %equal to i32
        \\  ret i32 %result
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    var machine = codegen.x86_64.MachineFunction.init("eq64_values", module.functions.items[0].ret_ty);
    defer machine.deinit(std.testing.allocator);

    const result = try selector.tryLower(std.testing.allocator, &machine, module.functions.items[0]);
    switch (result) {
        .selected => {},
        .unsupported => |diagnostic| {
            std.debug.print("unexpected selector diagnostic {s}: {s}\n", .{ diagnostic.tagName(), diagnostic.detail() });
            return error.TestExpectedSelected;
        },
    }

    try expectInstruction(machine.instructions.items, .{ .cmp_rcx_arg64 = .r8 });
    try expectInstruction(machine.instructions.items, .sete_eax);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[machine.instructions.items.len - 1]);
}

test "generic cfg selector composes pointer equality values" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @eq_ptr_values(ptr %lhs, ptr %rhs) {
        \\entry:
        \\  %equal = icmp eq ptr %lhs, %rhs
        \\  %result = zext i1 %equal to i32
        \\  ret i32 %result
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    var machine = codegen.x86_64.MachineFunction.init("eq_ptr_values", module.functions.items[0].ret_ty);
    defer machine.deinit(std.testing.allocator);

    const result = try selector.tryLower(std.testing.allocator, &machine, module.functions.items[0]);
    switch (result) {
        .selected => {},
        .unsupported => |diagnostic| {
            std.debug.print("unexpected selector diagnostic {s}: {s}\n", .{ diagnostic.tagName(), diagnostic.detail() });
            return error.TestExpectedSelected;
        },
    }

    try expectInstruction(machine.instructions.items, .{ .cmp_rcx_arg64 = .r8 });
    try expectInstruction(machine.instructions.items, .sete_eax);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[machine.instructions.items.len - 1]);
}

test "generic cfg selector composes unsigned greater i64 values" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @ugt64_values(i64 %lhs, i64 %rhs) {
        \\entry:
        \\  %greater = icmp ugt i64 %lhs, %rhs
        \\  %result = zext i1 %greater to i32
        \\  ret i32 %result
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    var machine = codegen.x86_64.MachineFunction.init("ugt64_values", module.functions.items[0].ret_ty);
    defer machine.deinit(std.testing.allocator);

    const result = try selector.tryLower(std.testing.allocator, &machine, module.functions.items[0]);
    switch (result) {
        .selected => {},
        .unsupported => |diagnostic| {
            std.debug.print("unexpected selector diagnostic {s}: {s}\n", .{ diagnostic.tagName(), diagnostic.detail() });
            return error.TestExpectedSelected;
        },
    }

    try expectInstruction(machine.instructions.items, .{ .cmp_rcx_arg64 = .r8 });
    try expectInstruction(machine.instructions.items, .setb_eax);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .mov_arg64_arg = .{ .dst = .rcx, .src = .rdi } }, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .mov_arg64_arg = .{ .dst = .r8, .src = .rsi } }, machine.instructions.items[1]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[machine.instructions.items.len - 1]);
}

test "generic cfg selector composes unsigned greater i64 immediate" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @ugt64_imm(i64 %value) {
        \\entry:
        \\  %greater = icmp ugt i64 %value, 4294967295
        \\  %result = zext i1 %greater to i32
        \\  ret i32 %result
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    var machine = codegen.x86_64.MachineFunction.init("ugt64_imm", module.functions.items[0].ret_ty);
    defer machine.deinit(std.testing.allocator);

    const result = try selector.tryLower(std.testing.allocator, &machine, module.functions.items[0]);
    switch (result) {
        .selected => {},
        .unsupported => |diagnostic| {
            std.debug.print("unexpected selector diagnostic {s}: {s}\n", .{ diagnostic.tagName(), diagnostic.detail() });
            return error.TestExpectedSelected;
        },
    }

    try expectInstruction(machine.instructions.items, .{ .mov_imm_r8 = 4294967295 });
    try expectInstruction(machine.instructions.items, .{ .cmp_rcx_arg64 = .r8 });
    try expectInstruction(machine.instructions.items, .setb_eax);
}

test "generic cfg selector composes signed i6 nonnegative test" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @nonnegative_i6(i32 %value) {
        \\entry:
        \\  %narrow = trunc i32 %value to i6
        \\  %nonnegative = icmp sgt i6 %narrow, -1
        \\  %result = zext i1 %nonnegative to i32
        \\  ret i32 %result
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    var machine = codegen.x86_64.MachineFunction.init("nonnegative_i6", module.functions.items[0].ret_ty);
    defer machine.deinit(std.testing.allocator);

    const result = try selector.tryLower(std.testing.allocator, &machine, module.functions.items[0]);
    switch (result) {
        .selected => {},
        .unsupported => |diagnostic| {
            std.debug.print("unexpected selector diagnostic {s}: {s}\n", .{ diagnostic.tagName(), diagnostic.detail() });
            return error.TestExpectedSelected;
        },
    }

    try expectInstruction(machine.instructions.items, .{ .and_eax_imm32 = 32 });
    try expectInstruction(machine.instructions.items, .sete_eax);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[machine.instructions.items.len - 1]);
}

test "generic cfg selector composes signed i64 less than zero" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @negative_i64(i64 %value) {
        \\entry:
        \\  %negative = icmp slt i64 %value, 0
        \\  %result = zext i1 %negative to i32
        \\  ret i32 %result
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    var machine = codegen.x86_64.MachineFunction.init("negative_i64", module.functions.items[0].ret_ty);
    defer machine.deinit(std.testing.allocator);

    const result = try selector.tryLower(std.testing.allocator, &machine, module.functions.items[0]);
    switch (result) {
        .selected => {},
        .unsupported => |diagnostic| {
            std.debug.print("unexpected selector diagnostic {s}: {s}\n", .{ diagnostic.tagName(), diagnostic.detail() });
            return error.TestExpectedSelected;
        },
    }

    try expectInstruction(machine.instructions.items, .{ .shr_rax_imm6 = 63 });
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[machine.instructions.items.len - 1]);
}

test "generic cfg selector composes narrow integer inequality with zero" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @ne16_zero(i32 %value) {
        \\entry:
        \\  %narrow = trunc i32 %value to i16
        \\  %not_zero = icmp ne i16 %narrow, 0
        \\  %result = zext i1 %not_zero to i32
        \\  ret i32 %result
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    var machine = codegen.x86_64.MachineFunction.init("ne16_zero", module.functions.items[0].ret_ty);
    defer machine.deinit(std.testing.allocator);

    const result = try selector.tryLower(std.testing.allocator, &machine, module.functions.items[0]);
    switch (result) {
        .selected => {},
        .unsupported => |diagnostic| {
            std.debug.print("unexpected selector diagnostic {s}: {s}\n", .{ diagnostic.tagName(), diagnostic.detail() });
            return error.TestExpectedSelected;
        },
    }

    try expectInstruction(machine.instructions.items, .{ .cmp_arg16_imm16 = .{ .reg = .rcx, .imm = 0 } });
    try expectInstruction(machine.instructions.items, .setne_eax);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[machine.instructions.items.len - 1]);
}

test "generic cfg selector composes i64 inequality with zero" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @ne64_zero(i64 %value) {
        \\entry:
        \\  %not_zero = icmp ne i64 %value, 0
        \\  %result = zext i1 %not_zero to i32
        \\  ret i32 %result
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    var machine = codegen.x86_64.MachineFunction.init("ne64_zero", module.functions.items[0].ret_ty);
    defer machine.deinit(std.testing.allocator);

    const result = try selector.tryLower(std.testing.allocator, &machine, module.functions.items[0]);
    switch (result) {
        .selected => {},
        .unsupported => |diagnostic| {
            std.debug.print("unexpected selector diagnostic {s}: {s}\n", .{ diagnostic.tagName(), diagnostic.detail() });
            return error.TestExpectedSelected;
        },
    }

    try expectInstruction(machine.instructions.items, .{ .cmp_arg64_imm64 = .{ .reg = .rcx, .imm = 0 } });
    try expectInstruction(machine.instructions.items, .setne_eax);
}

test "generic cfg selector composes ctlz i32 intrinsic" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\declare i32 @llvm.ctlz.i32(i32, i1 immarg)
        \\
        \\define i32 @ctlz32(i32 %value) {
        \\entry:
        \\  %count = tail call range(i32 0, 33) i32 @llvm.ctlz.i32(i32 %value, i1 true)
        \\  ret i32 %count
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    var machine = codegen.x86_64.MachineFunction.init("ctlz32", module.functions.items[0].ret_ty);
    defer machine.deinit(std.testing.allocator);

    const result = try selector.tryLower(std.testing.allocator, &machine, module.functions.items[0]);
    switch (result) {
        .selected => {},
        .unsupported => |diagnostic| {
            std.debug.print("unexpected selector diagnostic {s}: {s}\n", .{ diagnostic.tagName(), diagnostic.detail() });
            return error.TestExpectedSelected;
        },
    }

    try expectInstruction(machine.instructions.items, .clz_i32_edi_eax);
}

test "generic cfg selector composes wrapping i6 immediate lhs subtraction" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @sub_i6(i32 %value) {
        \\entry:
        \\  %narrow = trunc i32 %value to i6
        \\  %difference = sub i6 -32, %narrow
        \\  %result = zext i6 %difference to i32
        \\  ret i32 %result
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    var machine = codegen.x86_64.MachineFunction.init("sub_i6", module.functions.items[0].ret_ty);
    defer machine.deinit(std.testing.allocator);

    const result = try selector.tryLower(std.testing.allocator, &machine, module.functions.items[0]);
    switch (result) {
        .selected => {},
        .unsupported => |diagnostic| {
            std.debug.print("unexpected selector diagnostic {s}: {s}\n", .{ diagnostic.tagName(), diagnostic.detail() });
            return error.TestExpectedSelected;
        },
    }

    try expectInstruction(machine.instructions.items, .{ .mov_imm_eax = -32 });
    try expectInstruction(machine.instructions.items, .{ .binary_arg_eax = .{ .op = .sub, .reg = .rcx } });
    try expectInstruction(machine.instructions.items, .{ .and_eax_imm32 = 63 });
}

test "generic cfg selector branches on spilled condition" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @spilled_cond(i32 %value) {
        \\entry:
        \\  %v1 = add i32 %value, 1
        \\  %v2 = add i32 %value, 2
        \\  %v3 = add i32 %value, 3
        \\  %v4 = add i32 %value, 4
        \\  %v5 = add i32 %value, 5
        \\  %v6 = add i32 %value, 6
        \\  %cond = icmp eq i32 %value, 0
        \\  %extra = add i32 %v1, %v2
        \\  br i1 %cond, label %done, label %then
        \\then:
        \\  %s2 = add i32 %extra, %v3
        \\  %s3 = add i32 %s2, %v4
        \\  %s4 = add i32 %s3, %v5
        \\  %s5 = add i32 %s4, %v6
        \\  br label %merge
        \\done:
        \\  br label %merge
        \\merge:
        \\  %result = phi i32 [ %s5, %then ], [ 0, %done ]
        \\  ret i32 %result
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    var machine = codegen.x86_64.MachineFunction.init("spilled_cond", module.functions.items[0].ret_ty);
    defer machine.deinit(std.testing.allocator);

    const result = try selector.tryLower(std.testing.allocator, &machine, module.functions.items[0]);
    switch (result) {
        .selected => {},
        .unsupported => |diagnostic| {
            std.debug.print("unexpected selector diagnostic {s}: {s}\n", .{ diagnostic.tagName(), diagnostic.detail() });
            return error.TestExpectedSelected;
        },
    }

    try expectInstructionTag(machine.instructions.items, .test_arg8);
}

test "generic cfg selector composes dynamic i32 element pointer" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @store_i32_index(ptr %base, i64 %index, i32 %value) {
        \\entry:
        \\  %element = getelementptr [4 x i8], ptr %base, i64 %index
        \\  store i32 %value, ptr %element, align 4
        \\  ret i32 %value
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    var machine = codegen.x86_64.MachineFunction.init("store_i32_index", module.functions.items[0].ret_ty);
    defer machine.deinit(std.testing.allocator);

    const result = try selector.tryLower(std.testing.allocator, &machine, module.functions.items[0]);
    switch (result) {
        .selected => {},
        .unsupported => |diagnostic| {
            std.debug.print("unexpected selector diagnostic {s}: {s}\n", .{ diagnostic.tagName(), diagnostic.detail() });
            return error.TestExpectedSelected;
        },
    }

    try expectInstruction(machine.instructions.items, .{ .shl_r8_imm6 = 2 });
    try expectInstruction(machine.instructions.items, .add_r8_rcx);
    try expectInstruction(machine.instructions.items, .{ .store_eax_arg_ptr = .rcx });
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[machine.instructions.items.len - 1]);
}

test "generic cfg selector loads i32 through dynamic element pointer" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @load_i32_index(ptr %base, i64 %index) {
        \\entry:
        \\  %element = getelementptr [4 x i8], ptr %base, i64 %index
        \\  %value = load i32, ptr %element, align 4
        \\  ret i32 %value
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    var machine = codegen.x86_64.MachineFunction.init("load_i32_index", module.functions.items[0].ret_ty);
    defer machine.deinit(std.testing.allocator);

    const result = try selector.tryLower(std.testing.allocator, &machine, module.functions.items[0]);
    switch (result) {
        .selected => {},
        .unsupported => |diagnostic| {
            std.debug.print("unexpected selector diagnostic {s}: {s}\n", .{ diagnostic.tagName(), diagnostic.detail() });
            return error.TestExpectedSelected;
        },
    }

    try expectInstruction(machine.instructions.items, .{ .load_arg_ptr_eax = .rcx });
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[machine.instructions.items.len - 1]);
}

test "generic cfg selector loads i32 through spilled pointer" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @load_spilled_ptr(ptr %base) {
        \\entry:
        \\  %p1 = getelementptr i8, ptr %base, i64 0
        \\  %p2 = getelementptr i8, ptr %base, i64 4
        \\  %p3 = getelementptr i8, ptr %base, i64 8
        \\  %p4 = getelementptr i8, ptr %base, i64 12
        \\  %p5 = getelementptr i8, ptr %base, i64 16
        \\  %p6 = getelementptr i8, ptr %base, i64 20
        \\  %spilled = getelementptr i8, ptr %base, i64 24
        \\  %value = load i32, ptr %spilled, align 4
        \\  %eq1 = icmp eq ptr %p1, %p1
        \\  %eq2 = icmp eq ptr %p2, %p2
        \\  %eq3 = icmp eq ptr %p3, %p3
        \\  %eq4 = icmp eq ptr %p4, %p4
        \\  %eq5 = icmp eq ptr %p5, %p5
        \\  %eq6 = icmp eq ptr %p6, %p6
        \\  %v1 = zext i1 %eq1 to i32
        \\  %v2 = zext i1 %eq2 to i32
        \\  %v3 = zext i1 %eq3 to i32
        \\  %v4 = zext i1 %eq4 to i32
        \\  %v5 = zext i1 %eq5 to i32
        \\  %v6 = zext i1 %eq6 to i32
        \\  %sum1 = add i32 %value, %v1
        \\  %sum2 = add i32 %sum1, %v2
        \\  %sum3 = add i32 %sum2, %v3
        \\  %sum4 = add i32 %sum3, %v4
        \\  %sum5 = add i32 %sum4, %v5
        \\  %result = add i32 %sum5, %v6
        \\  ret i32 %result
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    var machine = codegen.x86_64.MachineFunction.init("load_spilled_ptr", module.functions.items[0].ret_ty);
    defer machine.deinit(std.testing.allocator);

    const result = try selector.tryLower(std.testing.allocator, &machine, module.functions.items[0]);
    switch (result) {
        .selected => {},
        .unsupported => |diagnostic| {
            std.debug.print("unexpected selector diagnostic {s}: {s}\n", .{ diagnostic.tagName(), diagnostic.detail() });
            return error.TestExpectedSelected;
        },
    }

    var saw_pointer_reload = false;
    for (machine.instructions.items) |instruction| switch (instruction) {
        .reload_arg64_rsp => |reload| if (reload.reg == .rcx) {
            saw_pointer_reload = true;
        },
        else => {},
    };
    try std.testing.expect(saw_pointer_reload);
    try expectInstruction(machine.instructions.items, .{ .load_arg_ptr_eax = .rcx });
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[machine.instructions.items.len - 1]);
}

test "generic cfg selector stores i32 through spilled pointer" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @store_spilled_ptr(ptr %base, i32 %value) {
        \\entry:
        \\  %p1 = getelementptr i8, ptr %base, i64 0
        \\  %p2 = getelementptr i8, ptr %base, i64 4
        \\  %p3 = getelementptr i8, ptr %base, i64 8
        \\  %p4 = getelementptr i8, ptr %base, i64 12
        \\  %p5 = getelementptr i8, ptr %base, i64 16
        \\  %p6 = getelementptr i8, ptr %base, i64 20
        \\  %spilled = getelementptr i8, ptr %base, i64 24
        \\  store i32 %value, ptr %spilled, align 4
        \\  %eq1 = icmp eq ptr %p1, %p1
        \\  %eq2 = icmp eq ptr %p2, %p2
        \\  %eq3 = icmp eq ptr %p3, %p3
        \\  %eq4 = icmp eq ptr %p4, %p4
        \\  %eq5 = icmp eq ptr %p5, %p5
        \\  %eq6 = icmp eq ptr %p6, %p6
        \\  %loaded = load i32, ptr %spilled, align 4
        \\  %v1 = zext i1 %eq1 to i32
        \\  %v2 = zext i1 %eq2 to i32
        \\  %v3 = zext i1 %eq3 to i32
        \\  %v4 = zext i1 %eq4 to i32
        \\  %v5 = zext i1 %eq5 to i32
        \\  %v6 = zext i1 %eq6 to i32
        \\  %sum1 = add i32 %loaded, %v1
        \\  %sum2 = add i32 %sum1, %v2
        \\  %sum3 = add i32 %sum2, %v3
        \\  %sum4 = add i32 %sum3, %v4
        \\  %sum5 = add i32 %sum4, %v5
        \\  %result = add i32 %sum5, %v6
        \\  ret i32 %result
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    var machine = codegen.x86_64.MachineFunction.init("store_spilled_ptr", module.functions.items[0].ret_ty);
    defer machine.deinit(std.testing.allocator);

    const result = try selector.tryLower(std.testing.allocator, &machine, module.functions.items[0]);
    switch (result) {
        .selected => {},
        .unsupported => |diagnostic| {
            std.debug.print("unexpected selector diagnostic {s}: {s}\n", .{ diagnostic.tagName(), diagnostic.detail() });
            return error.TestExpectedSelected;
        },
    }

    try expectInstructionTag(machine.instructions.items, .reload_arg64_rsp);
    try expectInstruction(machine.instructions.items, .{ .store_eax_arg_ptr = .rcx });
}

test "generic cfg selector stores i32 through local array base" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @store_array_base(i32 %value) {
        \\entry:
        \\  %slot = alloca [3 x i32], align 4
        \\  store i32 %value, ptr %slot, align 4
        \\  %base = getelementptr [3 x i32], ptr %slot, i64 0, i64 0
        \\  %loaded = load i32, ptr %base, align 4
        \\  ret i32 %loaded
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    var machine = codegen.x86_64.MachineFunction.init("store_array_base", module.functions.items[0].ret_ty);
    defer machine.deinit(std.testing.allocator);

    const result = try selector.tryLower(std.testing.allocator, &machine, module.functions.items[0]);
    switch (result) {
        .selected => {},
        .unsupported => |diagnostic| {
            std.debug.print("unexpected selector diagnostic {s}: {s}\n", .{ diagnostic.tagName(), diagnostic.detail() });
            return error.TestExpectedSelected;
        },
    }

    try expectInstruction(machine.instructions.items, .{ .store_eax_stack_disp32 = 256 });
    try expectInstruction(machine.instructions.items, .{ .load_stack_disp32_eax = 256 });
}

test "generic cfg selector preserves accumulator select true value" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @select_shifted(i32 %value, i32 %amount, i32 %flag) {
        \\entry:
        \\  %slot = alloca [1 x i32], align 4
        \\  %cond = icmp eq i32 %flag, 0
        \\  %shifted = shl i32 %value, %amount
        \\  %result = select i1 %cond, i32 %shifted, i32 0
        \\  store i32 %result, ptr %slot, align 4
        \\  ret i32 %result
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    var machine = codegen.x86_64.MachineFunction.init("select_shifted", module.functions.items[0].ret_ty);
    defer machine.deinit(std.testing.allocator);

    const result = try selector.tryLower(std.testing.allocator, &machine, module.functions.items[0]);
    switch (result) {
        .selected => {},
        .unsupported => |diagnostic| {
            std.debug.print("unexpected selector diagnostic {s}: {s}\n", .{ diagnostic.tagName(), diagnostic.detail() });
            return error.TestExpectedSelected;
        },
    }

    try expectInstruction(machine.instructions.items, .shl_eax_cl);
    try expectInstructionTag(machine.instructions.items, .spill_eax_rsp);
    try expectInstructionTag(machine.instructions.items, .reload_rsp_eax);
}

test "generic cfg selector composes i64 immediate or" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i64 @or_i64_imm(i64 %value) {
        \\entry:
        \\  %result = or i64 %value, 1
        \\  ret i64 %result
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    var machine = codegen.x86_64.MachineFunction.init("or_i64_imm", module.functions.items[0].ret_ty);
    defer machine.deinit(std.testing.allocator);

    const result = try selector.tryLower(std.testing.allocator, &machine, module.functions.items[0]);
    switch (result) {
        .selected => {},
        .unsupported => |diagnostic| {
            std.debug.print("unexpected selector diagnostic {s}: {s}\n", .{ diagnostic.tagName(), diagnostic.detail() });
            return error.TestExpectedSelected;
        },
    }

    try expectInstruction(machine.instructions.items, .{ .mov_imm_rcx = 1 });
    try expectInstruction(machine.instructions.items, .{ .binary_arg_rax = .{ .op = .@"or", .reg = .rcx } });
}

test "generic cfg selector composes i32 immediate xor" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @xor_i32_imm(i32 %value) {
        \\entry:
        \\  %result = xor i32 %value, -1
        \\  ret i32 %result
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    var machine = codegen.x86_64.MachineFunction.init("xor_i32_imm", module.functions.items[0].ret_ty);
    defer machine.deinit(std.testing.allocator);

    const result = try selector.tryLower(std.testing.allocator, &machine, module.functions.items[0]);
    switch (result) {
        .selected => {},
        .unsupported => |diagnostic| {
            std.debug.print("unexpected selector diagnostic {s}: {s}\n", .{ diagnostic.tagName(), diagnostic.detail() });
            return error.TestExpectedSelected;
        },
    }

    try expectInstruction(machine.instructions.items, .{ .mov_imm_rcx = -1 });
    try expectInstruction(machine.instructions.items, .{ .binary_arg_eax = .{ .op = .xor, .reg = .rcx } });
}

test "generic cfg selector composes i8 immediate and" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @and_i8_imm(i32 %value) {
        \\entry:
        \\  %narrow = trunc i32 %value to i8
        \\  %masked = and i8 %narrow, 1
        \\  %result = zext i8 %masked to i32
        \\  ret i32 %result
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    var machine = codegen.x86_64.MachineFunction.init("and_i8_imm", module.functions.items[0].ret_ty);
    defer machine.deinit(std.testing.allocator);

    const result = try selector.tryLower(std.testing.allocator, &machine, module.functions.items[0]);
    switch (result) {
        .selected => {},
        .unsupported => |diagnostic| {
            std.debug.print("unexpected selector diagnostic {s}: {s}\n", .{ diagnostic.tagName(), diagnostic.detail() });
            return error.TestExpectedSelected;
        },
    }

    try expectInstruction(machine.instructions.items, .{ .and_eax_imm32 = 1 });
}

test "generic cfg selector treats one-byte array GEP as byte pointer arithmetic" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @byte_array_gep_eq(ptr %base, ptr %expected, i64 %index) {
        \\entry:
        \\  %array_ptr = getelementptr [1 x i8], ptr %base, i64 %index
        \\  %equal = icmp eq ptr %array_ptr, %expected
        \\  %result = zext i1 %equal to i32
        \\  ret i32 %result
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    var machine = codegen.x86_64.MachineFunction.init("byte_array_gep_eq", module.functions.items[0].ret_ty);
    defer machine.deinit(std.testing.allocator);

    const result = try selector.tryLower(std.testing.allocator, &machine, module.functions.items[0]);
    switch (result) {
        .selected => {},
        .unsupported => |diagnostic| {
            std.debug.print("unexpected selector diagnostic {s}: {s}\n", .{ diagnostic.tagName(), diagnostic.detail() });
            return error.TestExpectedSelected;
        },
    }

    try expectInstruction(machine.instructions.items, .sete_eax);
}

test "generic cfg selector composes signed i32 nonnegative comparison" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @nonnegative_i32(i32 %value) {
        \\entry:
        \\  %nonnegative = icmp sgt i32 %value, -1
        \\  %result = zext i1 %nonnegative to i32
        \\  ret i32 %result
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    var machine = codegen.x86_64.MachineFunction.init("nonnegative_i32", module.functions.items[0].ret_ty);
    defer machine.deinit(std.testing.allocator);

    const result = try selector.tryLower(std.testing.allocator, &machine, module.functions.items[0]);
    switch (result) {
        .selected => {},
        .unsupported => |diagnostic| {
            std.debug.print("unexpected selector diagnostic {s}: {s}\n", .{ diagnostic.tagName(), diagnostic.detail() });
            return error.TestExpectedSelected;
        },
    }

    try expectInstruction(machine.instructions.items, .{ .and_eax_imm32 = std.math.minInt(i32) });
    try expectInstruction(machine.instructions.items, .sete_eax);
}

test "generic cfg selector composes pointer select" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @select_ptr_eq(i32 %selector, ptr %expected, ptr %left, ptr %right) {
        \\entry:
        \\  %cond = icmp eq i32 %selector, 0
        \\  %selected = select i1 %cond, ptr %left, ptr %right
        \\  %equal = icmp eq ptr %selected, %expected
        \\  %result = zext i1 %equal to i32
        \\  ret i32 %result
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    var machine = codegen.x86_64.MachineFunction.init("select_ptr_eq", module.functions.items[0].ret_ty);
    defer machine.deinit(std.testing.allocator);

    const result = try selector.tryLower(std.testing.allocator, &machine, module.functions.items[0]);
    switch (result) {
        .selected => {},
        .unsupported => |diagnostic| {
            std.debug.print("unexpected selector diagnostic {s}: {s}\n", .{ diagnostic.tagName(), diagnostic.detail() });
            return error.TestExpectedSelected;
        },
    }

    try expectInstructionTag(machine.instructions.items, .je);
    try expectInstruction(machine.instructions.items, .sete_eax);
}

test "generic cfg selector lowers i128 signed multiply overflow product" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare { i128, i1 } @llvm.smul.with.overflow.i128(i128, i128)
        \\
        \\define i128 @smul_overflow_i128(i128 %lhs, i128 %rhs) {
        \\entry:
        \\  %pair = call { i128, i1 } @llvm.smul.with.overflow.i128(i128 %lhs, i128 %rhs)
        \\  %value = extractvalue { i128, i1 } %pair, 0
        \\  ret i128 %value
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    var machine = codegen.x86_64.MachineFunction.init("smul_overflow_i128", module.functions.items[0].ret_ty);
    defer machine.deinit(std.testing.allocator);

    const result = try selector.tryLower(std.testing.allocator, &machine, module.functions.items[0]);
    switch (result) {
        .selected => {},
        .unsupported => |diagnostic| {
            std.debug.print("unexpected selector diagnostic {s}: {s}\n", .{ diagnostic.tagName(), diagnostic.detail() });
            return error.TestExpectedSelected;
        },
    }
    try expectInstruction(machine.instructions.items, .{ .mul_rax_arg64_full = .rcx });
    try expectInstruction(machine.instructions.items, .adc_rax_imm0);
    try expectInstruction(machine.instructions.items, .setne_eax);
}

test "generic cfg selector pressure-exempts i128 signed multiply overflow tuple" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare { i128, i1 } @llvm.smul.with.overflow.i128(i128, i128)
        \\
        \\define i128 @smul_overflow_i128_cfg(i128 %lhs, i128 %rhs, i32 %selector) {
        \\entry:
        \\  %pair = call { i128, i1 } @llvm.smul.with.overflow.i128(i128 %lhs, i128 %rhs)
        \\  %cond = icmp eq i32 %selector, 0
        \\  br i1 %cond, label %value_block, label %overflow_block
        \\value_block:
        \\  %value = extractvalue { i128, i1 } %pair, 0
        \\  ret i128 %value
        \\overflow_block:
        \\  %overflow = extractvalue { i128, i1 } %pair, 1
        \\  br i1 %overflow, label %value_block, label %value_block
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    var machine = codegen.x86_64.MachineFunction.init("smul_overflow_i128_cfg", module.functions.items[0].ret_ty);
    defer machine.deinit(std.testing.allocator);

    const result = try selector.tryLower(std.testing.allocator, &machine, module.functions.items[0]);
    switch (result) {
        .selected => {},
        .unsupported => |diagnostic| {
            std.debug.print("unexpected selector diagnostic {s}: {s}\n", .{ diagnostic.tagName(), diagnostic.detail() });
            return error.TestExpectedSelected;
        },
    }
    try expectInstruction(machine.instructions.items, .{ .mul_rax_arg64_full = .rcx });
    try expectInstruction(machine.instructions.items, .setne_eax);
}

test "generic cfg selector pressure-exempts i64 signed multiply overflow tuple" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare { i64, i1 } @llvm.smul.with.overflow.i64(i64, i64)
        \\
        \\define i64 @smul_overflow_i64(i64 %lhs, i64 %rhs) {
        \\entry:
        \\  %pair = call { i64, i1 } @llvm.smul.with.overflow.i64(i64 %lhs, i64 %rhs)
        \\  %overflow = extractvalue { i64, i1 } %pair, 1
        \\  %value = extractvalue { i64, i1 } %pair, 0
        \\  br i1 %overflow, label %done, label %done
        \\done:
        \\  ret i64 %value
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    var plan = try stage2_planning.buildSelectorAllocationPlan(std.testing.allocator, module.functions.items[0]);
    defer plan.deinit();

    try std.testing.expectEqual(@as(?stage2_planning.PlannedValueAssignment, null), plan.assignment("pair"));
    try std.testing.expect(plan.assignment("overflow") != null);
    try std.testing.expect(plan.assignment("value") != null);
}

test "generic cfg selector lowers i64 signed multiply overflow components" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare { i64, i1 } @llvm.smul.with.overflow.i64(i64, i64)
        \\
        \\define i32 @smul_overflow_i64(i64 %lhs, i64 %rhs) {
        \\entry:
        \\  %pair = tail call { i64, i1 } @llvm.smul.with.overflow.i64(i64 %lhs, i64 %rhs)
        \\  %value = extractvalue { i64, i1 } %pair, 0
        \\  %overflow = extractvalue { i64, i1 } %pair, 1
        \\  %wide = zext i1 %overflow to i32
        \\  ret i32 %wide
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    var machine = codegen.x86_64.MachineFunction.init("smul_overflow_i64", module.functions.items[0].ret_ty);
    defer machine.deinit(std.testing.allocator);
    switch (try selector.tryLower(std.testing.allocator, &machine, module.functions.items[0])) {
        .selected => {},
        .unsupported => |diagnostic| {
            std.debug.print("unexpected selector diagnostic {s}: {s}\n", .{ diagnostic.tagName(), diagnostic.detail() });
            return error.TestExpectedSelected;
        },
    }
    try expectInstruction(machine.instructions.items, .{ .imul_rax_arg64_full = .rcx });
    try expectInstruction(machine.instructions.items, .{ .cmp_rcx_arg64 = .rdx });
    try expectInstruction(machine.instructions.items, .setne_eax);
}

test "generic cfg selector lowers large i64 immediate add through scratch" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i64 @add_large_i64(i64 %value) {
        \\entry:
        \\  %sum = add i64 %value, 2147483648
        \\  ret i64 %sum
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    var machine = codegen.x86_64.MachineFunction.init("add_large_i64", module.functions.items[0].ret_ty);
    defer machine.deinit(std.testing.allocator);
    switch (try selector.tryLower(std.testing.allocator, &machine, module.functions.items[0])) {
        .selected => {},
        .unsupported => |diagnostic| {
            std.debug.print("unexpected selector diagnostic {s}: {s}\n", .{ diagnostic.tagName(), diagnostic.detail() });
            return error.TestExpectedSelected;
        },
    }
    try expectInstruction(machine.instructions.items, .{ .mov_imm_rcx = 2147483648 });
    try expectInstruction(machine.instructions.items, .{ .binary_arg_rax = .{ .op = .add, .reg = .rcx } });
}

test "generic cfg selector executes owned llvm trap block" {
    if (@import("builtin").os.tag != .linux) return error.SkipZigTest;
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare void @llvm.trap()
        \\
        \\define i32 @trap_if_negative(i32 %value) {
        \\entry:
        \\  %bad = icmp slt i32 %value, 0
        \\  br i1 %bad, label %trap, label %done
        \\trap:
        \\  tail call void @llvm.trap()
        \\  unreachable
        \\done:
        \\  ret i32 7
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    var machine = codegen.x86_64.MachineFunction.init("trap_if_negative", module.functions.items[0].ret_ty);
    defer machine.deinit(std.testing.allocator);
    switch (try selector.tryLower(std.testing.allocator, &machine, module.functions.items[0])) {
        .selected => {},
        .unsupported => |diagnostic| {
            std.debug.print("unexpected selector diagnostic {s}: {s}\n", .{ diagnostic.tagName(), diagnostic.detail() });
            return error.TestExpectedSelected;
        },
    }
    try expectInstruction(machine.instructions.items, .ud2);

    const bytes = try mc.encoding.encodeFunction(std.testing.allocator, machine);
    defer std.testing.allocator.free(bytes);
    const mapping = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    defer std.posix.munmap(mapping);
    @memcpy(mapping, bytes);
    const trapIfNegative: *const fn (i32) callconv(.c) i32 = @ptrCast(mapping.ptr);
    try std.testing.expectEqual(@as(i32, 7), trapIfNegative(0));

    const pid = std.os.linux.fork();
    if (pid == 0) {
        const sigact: std.posix.Sigaction = .{
            .handler = .{ .handler = std.posix.SIG.DFL },
            .mask = std.posix.sigemptyset(),
            .flags = 0,
        };
        std.posix.sigaction(.ILL, &sigact, null);
        _ = trapIfNegative(-1);
        std.os.linux.exit_group(127);
    }
    var status: u32 = 0;
    _ = std.os.linux.waitpid(@intCast(pid), &status, 0);
    try std.testing.expectEqual(@as(u32, 4), status & 0x7f);
}

test "generic cfg selector preserves multi-use i64 binary lhs" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i64 @multi_use_i64(i64 %lhs, i64 %rhs) {
        \\entry:
        \\  %sum = add i64 %lhs, %rhs
        \\  %x = xor i64 %sum, %lhs
        \\  %y = xor i64 %sum, %rhs
        \\  %result = and i64 %x, %y
        \\  ret i64 %result
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    var machine = codegen.x86_64.MachineFunction.init("multi_use_i64", module.functions.items[0].ret_ty);
    defer machine.deinit(std.testing.allocator);
    switch (try selector.tryLower(std.testing.allocator, &machine, module.functions.items[0])) {
        .selected => {},
        .unsupported => |diagnostic| {
            std.debug.print("unexpected selector diagnostic {s}: {s}\n", .{ diagnostic.tagName(), diagnostic.detail() });
            return error.TestExpectedSelected;
        },
    }
    try expectInstructionTag(machine.instructions.items, .mov_rax_to_arg);
}

test "generic cfg selector lowers i32 minimum equality" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @eq_min_i32(i32 %value) {
        \\entry:
        \\  %equal = icmp eq i32 %value, -2147483648
        \\  %wide = zext i1 %equal to i32
        \\  ret i32 %wide
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    var machine = codegen.x86_64.MachineFunction.init("eq_min_i32", module.functions.items[0].ret_ty);
    defer machine.deinit(std.testing.allocator);
    switch (try selector.tryLower(std.testing.allocator, &machine, module.functions.items[0])) {
        .selected => {},
        .unsupported => |diagnostic| {
            std.debug.print("unexpected selector diagnostic {s}: {s}\n", .{ diagnostic.tagName(), diagnostic.detail() });
            return error.TestExpectedSelected;
        },
    }
    try expectInstruction(machine.instructions.items, .{ .cmp_eax_imm32 = std.math.minInt(i32) });
    try expectInstruction(machine.instructions.items, .sete_eax);
}

test "generic cfg selector lowers i32 immediate lhs subtraction" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @neg_i32(i32 %value) {
        \\entry:
        \\  %negated = sub i32 0, %value
        \\  ret i32 %negated
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    var machine = codegen.x86_64.MachineFunction.init("neg_i32", module.functions.items[0].ret_ty);
    defer machine.deinit(std.testing.allocator);
    switch (try selector.tryLower(std.testing.allocator, &machine, module.functions.items[0])) {
        .selected => {},
        .unsupported => |diagnostic| {
            std.debug.print("unexpected selector diagnostic {s}: {s}\n", .{ diagnostic.tagName(), diagnostic.detail() });
            return error.TestExpectedSelected;
        },
    }
    try expectInstruction(machine.instructions.items, .{ .mov_imm_eax = 0 });
    try expectInstruction(machine.instructions.items, .{ .binary_arg_eax = .{ .op = .sub, .reg = .rcx } });
}

test "generic cfg selector lowers i128 immediate lhs subtraction" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i128 @neg_i128(i128 %value) {
        \\entry:
        \\  %negated = sub i128 0, %value
        \\  ret i128 %negated
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    var machine = codegen.x86_64.MachineFunction.init("neg_i128", module.functions.items[0].ret_ty);
    defer machine.deinit(std.testing.allocator);
    switch (try selector.tryLower(std.testing.allocator, &machine, module.functions.items[0])) {
        .selected => {},
        .unsupported => |diagnostic| {
            std.debug.print("unexpected selector diagnostic {s}: {s}\n", .{ diagnostic.tagName(), diagnostic.detail() });
            return error.TestExpectedSelected;
        },
    }
    try expectInstruction(machine.instructions.items, .{ .mov_imm_r8 = 0 });
    try expectInstruction(machine.instructions.items, .{ .mov_imm_r9 = 0 });
    try expectInstruction(machine.instructions.items, .{ .binary_arg_rax = .{ .op = .sub, .reg = .rcx } });
    try expectInstruction(machine.instructions.items, .{ .sbb_arg64_rax = .rdx });
}

test "generic cfg selector lowers i64 immediate lhs subtraction" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i64 @neg_i64(i64 %value) {
        \\entry:
        \\  %negated = sub i64 0, %value
        \\  ret i64 %negated
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    var machine = codegen.x86_64.MachineFunction.init("neg_i64", module.functions.items[0].ret_ty);
    defer machine.deinit(std.testing.allocator);
    switch (try selector.tryLower(std.testing.allocator, &machine, module.functions.items[0])) {
        .selected => {},
        .unsupported => |diagnostic| {
            std.debug.print("unexpected selector diagnostic {s}: {s}\n", .{ diagnostic.tagName(), diagnostic.detail() });
            return error.TestExpectedSelected;
        },
    }
    try expectInstruction(machine.instructions.items, .{ .mov_imm_rax = 0 });
    try expectInstruction(machine.instructions.items, .{ .binary_arg_rax = .{ .op = .sub, .reg = .rcx } });
}

test "generic cfg selector executes framed i128 negation trap" {
    if (@import("builtin").os.tag != .linux) return error.SkipZigTest;
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare void @llvm.assume(i1)
        \\declare void @llvm.trap()
        \\
        \\define i128 @negv_i128(i128 %value) {
        \\entry:
        \\  %overflow = icmp eq i128 %value, -170141183460469231731687303715884105728
        \\  br i1 %overflow, label %trap, label %done
        \\trap:
        \\  call void @llvm.assume(i1 true) [ "cold"() ]
        \\  tail call void @llvm.trap()
        \\  unreachable
        \\done:
        \\  %negated = sub nsw i128 0, %value
        \\  ret i128 %negated
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    var machine = codegen.x86_64.MachineFunction.init("negv_i128", module.functions.items[0].ret_ty);
    defer machine.deinit(std.testing.allocator);
    switch (try selector.tryLower(std.testing.allocator, &machine, module.functions.items[0])) {
        .selected => {},
        .unsupported => |diagnostic| {
            std.debug.print("unexpected selector diagnostic {s}: {s}\n", .{ diagnostic.tagName(), diagnostic.detail() });
            return error.TestExpectedSelected;
        },
    }
    try codegen.x86_64.verifyFunction(machine);

    const bytes = try mc.encoding.encodeFunction(std.testing.allocator, machine);
    defer std.testing.allocator.free(bytes);
    const mapping = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    defer std.posix.munmap(mapping);
    @memcpy(mapping, bytes);
    const negvI128: *const fn (i128) callconv(.c) i128 = @ptrCast(mapping.ptr);
    try std.testing.expectEqual(@as(i128, -12), negvI128(12));
    try std.testing.expectEqual(@as(i128, 12), negvI128(-12));

    const pid = std.os.linux.fork();
    if (pid == 0) {
        const sigact: std.posix.Sigaction = .{
            .handler = .{ .handler = std.posix.SIG.DFL },
            .mask = std.posix.sigemptyset(),
            .flags = 0,
        };
        std.posix.sigaction(.ILL, &sigact, null);
        _ = negvI128(std.math.minInt(i128));
        std.os.linux.exit_group(127);
    }
    var status: u32 = 0;
    _ = std.os.linux.waitpid(@intCast(pid), &status, 0);
    try std.testing.expectEqual(@as(u32, 4), status & 0x7f);
}

test "generic cfg selector executes i128 signed multiply overflow semantics" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare { i128, i1 } @llvm.smul.with.overflow.i128(i128, i128)
        \\
        \\define i128 @smul_value(i128 %lhs, i128 %rhs) {
        \\entry:
        \\  %pair = call { i128, i1 } @llvm.smul.with.overflow.i128(i128 %lhs, i128 %rhs)
        \\  %value = extractvalue { i128, i1 } %pair, 0
        \\  ret i128 %value
        \\}
        \\
        \\define i32 @smul_overflow(i128 %lhs, i128 %rhs) {
        \\entry:
        \\  %pair = call { i128, i1 } @llvm.smul.with.overflow.i128(i128 %lhs, i128 %rhs)
        \\  %overflow = extractvalue { i128, i1 } %pair, 1
        \\  %wide = zext i1 %overflow to i32
        \\  ret i32 %wide
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    var value_machine = codegen.x86_64.MachineFunction.init("smul_value", module.functions.items[0].ret_ty);
    defer value_machine.deinit(std.testing.allocator);
    switch (try selector.tryLower(std.testing.allocator, &value_machine, module.functions.items[0])) {
        .selected => {},
        .unsupported => |diagnostic| {
            std.debug.print("unexpected value selector diagnostic {s}: {s}\n", .{ diagnostic.tagName(), diagnostic.detail() });
            return error.TestExpectedSelected;
        },
    }
    const value_bytes = try mc.encoding.encodeFunction(std.testing.allocator, value_machine);
    defer std.testing.allocator.free(value_bytes);
    const value_mapping = try std.posix.mmap(
        null,
        value_bytes.len,
        .{ .READ = true, .WRITE = true, .EXEC = true },
        .{ .TYPE = .PRIVATE, .ANONYMOUS = true },
        -1,
        0,
    );
    defer std.posix.munmap(value_mapping);
    @memcpy(value_mapping, value_bytes);
    const smulValue: *const fn (i128, i128) callconv(.c) i128 = @ptrCast(value_mapping.ptr);

    var overflow_machine = codegen.x86_64.MachineFunction.init("smul_overflow", module.functions.items[1].ret_ty);
    defer overflow_machine.deinit(std.testing.allocator);
    switch (try selector.tryLower(std.testing.allocator, &overflow_machine, module.functions.items[1])) {
        .selected => {},
        .unsupported => |diagnostic| {
            std.debug.print("unexpected overflow selector diagnostic {s}: {s}\n", .{ diagnostic.tagName(), diagnostic.detail() });
            return error.TestExpectedSelected;
        },
    }
    const overflow_bytes = try mc.encoding.encodeFunction(std.testing.allocator, overflow_machine);
    defer std.testing.allocator.free(overflow_bytes);
    const overflow_mapping = try std.posix.mmap(
        null,
        overflow_bytes.len,
        .{ .READ = true, .WRITE = true, .EXEC = true },
        .{ .TYPE = .PRIVATE, .ANONYMOUS = true },
        -1,
        0,
    );
    defer std.posix.munmap(overflow_mapping);
    @memcpy(overflow_mapping, overflow_bytes);
    const smulOverflow: *const fn (i128, i128) callconv(.c) i32 = @ptrCast(overflow_mapping.ptr);

    const cases = [_]struct { lhs: i128, rhs: i128, value: i128, overflow: i32 }{
        .{ .lhs = 12, .rhs = 11, .value = 132, .overflow = 0 },
        .{ .lhs = -12, .rhs = 11, .value = -132, .overflow = 0 },
        .{ .lhs = std.math.maxInt(i128), .rhs = 2, .value = -2, .overflow = 1 },
        .{ .lhs = std.math.minInt(i128), .rhs = 2, .value = 0, .overflow = 1 },
    };
    for (cases) |case| {
        try std.testing.expectEqual(case.value, smulValue(case.lhs, case.rhs));
        try std.testing.expectEqual(case.overflow, smulOverflow(case.lhs, case.rhs));
    }
}

test "generic cfg selector lowers i128 signed negative comparison" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @negative_i128(i128 %value) {
        \\entry:
        \\  %negative = icmp slt i128 %value, 0
        \\  %wide = zext i1 %negative to i32
        \\  ret i32 %wide
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    var machine = codegen.x86_64.MachineFunction.init("negative_i128", module.functions.items[0].ret_ty);
    defer machine.deinit(std.testing.allocator);
    switch (try selector.tryLower(std.testing.allocator, &machine, module.functions.items[0])) {
        .selected => {},
        .unsupported => |diagnostic| {
            std.debug.print("unexpected selector diagnostic {s}: {s}\n", .{ diagnostic.tagName(), diagnostic.detail() });
            return error.TestExpectedSelected;
        },
    }
    try expectInstruction(machine.instructions.items, .{ .mov_arg_rax = .rsi });
    try expectInstruction(machine.instructions.items, .{ .shr_rax_imm6 = 63 });
}

test "generic cfg selector lowers i128 minimum equality comparison" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @eq_min_i128(i128 %value) {
        \\entry:
        \\  %equal = icmp eq i128 %value, -170141183460469231731687303715884105728
        \\  %wide = zext i1 %equal to i32
        \\  ret i32 %wide
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    var machine = codegen.x86_64.MachineFunction.init("eq_min_i128", module.functions.items[0].ret_ty);
    defer machine.deinit(std.testing.allocator);
    switch (try selector.tryLower(std.testing.allocator, &machine, module.functions.items[0])) {
        .selected => {},
        .unsupported => |diagnostic| {
            std.debug.print("unexpected selector diagnostic {s}: {s}\n", .{ diagnostic.tagName(), diagnostic.detail() });
            return error.TestExpectedSelected;
        },
    }
    try expectInstruction(machine.instructions.items, .{ .mov_imm_r8 = std.math.minInt(i64) });
    try expectInstruction(machine.instructions.items, .sete_eax);
}

test "generic cfg selector lowers boolean and of i128 predicates" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @i128_guard_and(i128 %lhs, i128 %rhs) {
        \\entry:
        \\  %negative = icmp slt i128 %lhs, 0
        \\  %minimum = icmp eq i128 %rhs, -170141183460469231731687303715884105728
        \\  %both = and i1 %negative, %minimum
        \\  %wide = zext i1 %both to i32
        \\  ret i32 %wide
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    var machine = codegen.x86_64.MachineFunction.init("i128_guard_and", module.functions.items[0].ret_ty);
    defer machine.deinit(std.testing.allocator);
    switch (try selector.tryLower(std.testing.allocator, &machine, module.functions.items[0])) {
        .selected => {},
        .unsupported => |diagnostic| {
            std.debug.print("unexpected selector diagnostic {s}: {s}\n", .{ diagnostic.tagName(), diagnostic.detail() });
            return error.TestExpectedSelected;
        },
    }
    try expectInstruction(machine.instructions.items, .{ .binary_arg_eax = .{ .op = .@"and", .reg = .rcx } });
}

test "generic cfg selector preserves i128 freeze location" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i128 @freeze_i128(i128 %value) {
        \\entry:
        \\  %frozen = freeze i128 %value
        \\  ret i128 %frozen
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    var machine = codegen.x86_64.MachineFunction.init("freeze_i128", module.functions.items[0].ret_ty);
    defer machine.deinit(std.testing.allocator);

    const result = try selector.tryLower(std.testing.allocator, &machine, module.functions.items[0]);
    switch (result) {
        .selected => {},
        .unsupported => |diagnostic| {
            std.debug.print("unexpected selector diagnostic {s}: {s}\n", .{ diagnostic.tagName(), diagnostic.detail() });
            return error.TestExpectedSelected;
        },
    }

    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[machine.instructions.items.len - 1]);
}

test "generic cfg selector keeps stack pointer index dependencies live" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @stack_index_dependency(i64 %base_index, i32 %value, i32 %amount) {
        \\entry:
        \\  %slot = alloca [3 x i32], align 4
        \\  store i32 11, ptr %slot, align 4
        \\  %index = add i64 %base_index, 1
        \\  %ptr = getelementptr [4 x i8], ptr %slot, i64 %index
        \\  %shifted = shl i32 %value, %amount
        \\  store i32 %shifted, ptr %ptr, align 4
        \\  %base = getelementptr [3 x i32], ptr %slot, i64 0, i64 0
        \\  %loaded = load i32, ptr %base, align 4
        \\  ret i32 %loaded
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    var machine = codegen.x86_64.MachineFunction.init("stack_index_dependency", module.functions.items[0].ret_ty);
    defer machine.deinit(std.testing.allocator);

    const result = try selector.tryLower(std.testing.allocator, &machine, module.functions.items[0]);
    switch (result) {
        .selected => {},
        .unsupported => |diagnostic| {
            std.debug.print("unexpected selector diagnostic {s}: {s}\n", .{ diagnostic.tagName(), diagnostic.detail() });
            return error.TestExpectedSelected;
        },
    }

    try expectInstruction(machine.instructions.items, .shl_eax_cl);
    try expectInstructionTag(machine.instructions.items, .spill_arg64_rsp);
    try expectInstructionTag(machine.instructions.items, .reload_arg64_rsp);
}

test "generic cfg selector preserves accumulator binary rhs order" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i64 @sub_rhs_accumulator(i64 %lhs, i64 %a, i64 %b) {
        \\entry:
        \\  %rhs = add i64 %a, %b
        \\  %result = sub i64 %lhs, %rhs
        \\  ret i64 %result
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    var machine = codegen.x86_64.MachineFunction.init("sub_rhs_accumulator", module.functions.items[0].ret_ty);
    defer machine.deinit(std.testing.allocator);

    const result = try selector.tryLower(std.testing.allocator, &machine, module.functions.items[0]);
    switch (result) {
        .selected => {},
        .unsupported => |diagnostic| {
            std.debug.print("unexpected selector diagnostic {s}: {s}\n", .{ diagnostic.tagName(), diagnostic.detail() });
            return error.TestExpectedSelected;
        },
    }

    try expectInstruction(machine.instructions.items, .{ .mov_rax_to_arg = .rcx });
    try expectInstruction(machine.instructions.items, .{ .binary_arg_rax = .{ .op = .sub, .reg = .rcx } });
}

test "generic cfg selector spills every live accumulator binding" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i64 @sum_loaded_i32(ptr %values, i64 %base) {
        \\entry:
        \\  %slot = alloca [1 x i32], align 4
        \\  %first32 = load i32, ptr %values, align 4
        \\  %first64 = zext i32 %first32 to i64
        \\  %second_ptr = getelementptr i8, ptr %values, i64 4
        \\  %second32 = load i32, ptr %second_ptr, align 4
        \\  %second64 = zext i32 %second32 to i64
        \\  %sum1 = add i64 %base, %first64
        \\  %sum2 = add i64 %sum1, %second64
        \\  %low = trunc i64 %sum2 to i32
        \\  store i32 %low, ptr %slot, align 4
        \\  ret i64 %sum2
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    var machine = codegen.x86_64.MachineFunction.init("sum_loaded_i32", module.functions.items[0].ret_ty);
    defer machine.deinit(std.testing.allocator);

    const result = try selector.tryLower(std.testing.allocator, &machine, module.functions.items[0]);
    switch (result) {
        .selected => {},
        .unsupported => |diagnostic| {
            std.debug.print("unexpected selector diagnostic {s}: {s}\n", .{ diagnostic.tagName(), diagnostic.detail() });
            return error.TestExpectedSelected;
        },
    }

    try expectInstructionTag(machine.instructions.items, .spill_rax_rsp);
    try expectInstructionTag(machine.instructions.items, .reload_arg64_rsp);
}

test "generic cfg selector preserves aliased accumulator binary operands" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @double_low_bits(i32 %value) {
        \\entry:
        \\  %narrow = trunc i32 %value to i16
        \\  %wide = zext i16 %narrow to i32
        \\  %alias = freeze i32 %wide
        \\  %result = add i32 %wide, %alias
        \\  ret i32 %result
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    var machine = codegen.x86_64.MachineFunction.init("double_low_bits", module.functions.items[0].ret_ty);
    defer machine.deinit(std.testing.allocator);

    const result = try selector.tryLower(std.testing.allocator, &machine, module.functions.items[0]);
    try std.testing.expectEqual(selector.SelectionResult.selected, result);
    try expectInstruction(machine.instructions.items, .{ .binary_arg_eax = .{ .op = .add, .reg = .rcx } });
}

test "generic cfg selector narrows trunc result location class" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @add_truncated_rhs(i32 %lhs, i64 %value) {
        \\entry:
        \\  %narrow = trunc i64 %value to i32
        \\  %result = add i32 %lhs, %narrow
        \\  ret i32 %result
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    var machine = codegen.x86_64.MachineFunction.init("add_truncated_rhs", module.functions.items[0].ret_ty);
    defer machine.deinit(std.testing.allocator);

    const result = try selector.tryLower(std.testing.allocator, &machine, module.functions.items[0]);
    switch (result) {
        .selected => {},
        .unsupported => |diagnostic| {
            std.debug.print("unexpected selector diagnostic {s}: {s}\n", .{ diagnostic.tagName(), diagnostic.detail() });
            return error.TestExpectedSelected;
        },
    }

    try expectInstruction(machine.instructions.items, .{ .binary_arg_eax = .{ .op = .add, .reg = .rsi } });
}

test "generic cfg selector composes tail inline memcpy" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare void @llvm.memcpy.inline.p0.p0.i64(ptr, ptr, i64, i1)
        \\
        \\define void @copy_bytes(ptr %dst, ptr %src, i64 %len) {
        \\entry:
        \\  tail call void @llvm.memcpy.inline.p0.p0.i64(ptr %dst, ptr %src, i64 %len, i1 false)
        \\  ret void
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    var machine = codegen.x86_64.MachineFunction.init("copy_bytes", module.functions.items[0].ret_ty);
    defer machine.deinit(std.testing.allocator);

    const result = try selector.tryLower(std.testing.allocator, &machine, module.functions.items[0]);
    try std.testing.expectEqual(selector.SelectionResult.selected, result);
    try expectInstruction(machine.instructions.items, .memcpy_rdi_rsi_rdx_rax);
}

test "generic cfg selector aliases trunc through a call spill" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare void @llvm.memcpy.inline.p0.p0.i64(ptr, ptr, i64, i1)
        \\
        \\define i32 @spilled_trunc(ptr %dst, ptr %src, i64 %len, i32 %value) {
        \\entry:
        \\  %slot = alloca [1 x i32], align 4
        \\  store i32 %value, ptr %slot, align 4
        \\  tail call void @llvm.memcpy.inline.p0.p0.i64(ptr %dst, ptr %src, i64 %len, i1 false)
        \\  %narrow = trunc i32 %value to i6
        \\  %wide = zext i6 %narrow to i32
        \\  ret i32 %wide
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    var machine = codegen.x86_64.MachineFunction.init("spilled_trunc", module.functions.items[0].ret_ty);
    defer machine.deinit(std.testing.allocator);

    const result = try selector.tryLower(std.testing.allocator, &machine, module.functions.items[0]);
    switch (result) {
        .selected => {},
        .unsupported => |diagnostic| {
            std.debug.print("unexpected selector diagnostic {s}: {s}\n", .{ diagnostic.tagName(), diagnostic.detail() });
            return error.TestExpectedSelected;
        },
    }
    try expectInstructionTag(machine.instructions.items, .spill_arg_rsp);
    try expectInstructionTag(machine.instructions.items, .reload_rsp_eax);
}

test "generic cfg selector composes i128 left shift by one lane" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i128 @shift_hi(i64 %x) {
        \\entry:
        \\  %wide = zext i64 %x to i128
        \\  %shifted = shl i128 %wide, 64
        \\  ret i128 %shifted
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    var machine = codegen.x86_64.MachineFunction.init("shift_hi", module.functions.items[0].ret_ty);
    defer machine.deinit(std.testing.allocator);

    const result = try selector.tryLower(std.testing.allocator, &machine, module.functions.items[0]);
    switch (result) {
        .selected => {},
        .unsupported => |diagnostic| {
            std.debug.print("unexpected selector diagnostic {s}: {s}\n", .{ diagnostic.tagName(), diagnostic.detail() });
            return error.TestExpectedSelected;
        },
    }

    try std.testing.expectEqual(@as(usize, 7), machine.instructions.items.len);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .mov_arg64_arg = .{ .dst = .rcx, .src = .rdi } }, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .mov_imm_rdx = 0 }, machine.instructions.items[1]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .mov_arg64_arg = .{ .dst = .rdx, .src = .rcx } }, machine.instructions.items[2]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .mov_imm_rcx = 0 }, machine.instructions.items[3]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .mov_arg64_arg = .{ .dst = .rdi, .src = .rcx } }, machine.instructions.items[4]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .mov_arg_rax = .rdi }, machine.instructions.items[5]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[6]);
}

test "generic cfg selector composes i128 pair or" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i128 @or_pair(i128 %a, i128 %b) {
        \\entry:
        \\  %combined = or i128 %a, %b
        \\  ret i128 %combined
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    var machine = codegen.x86_64.MachineFunction.init("or_pair", module.functions.items[0].ret_ty);
    defer machine.deinit(std.testing.allocator);

    const result = try selector.tryLower(std.testing.allocator, &machine, module.functions.items[0]);
    switch (result) {
        .selected => {},
        .unsupported => |diagnostic| {
            std.debug.print("unexpected selector diagnostic {s}: {s}\n", .{ diagnostic.tagName(), diagnostic.detail() });
            return error.TestExpectedSelected;
        },
    }

    try std.testing.expectEqual(@as(usize, 9), machine.instructions.items.len);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .mov_arg_rax = .rdi }, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .binary_arg_rax = .{ .op = .@"or", .reg = .rdx } }, machine.instructions.items[1]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .mov_rax_to_arg = .rdi }, machine.instructions.items[2]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .mov_arg_rax = .rsi }, machine.instructions.items[3]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .binary_arg_rax = .{ .op = .@"or", .reg = .rcx } }, machine.instructions.items[4]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .mov_rax_to_arg = .rsi }, machine.instructions.items[5]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .mov_arg64_arg = .{ .dst = .rdx, .src = .rsi } }, machine.instructions.items[6]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .mov_arg_rax = .rdi }, machine.instructions.items[7]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[8]);
}

test "generic cfg selector composes i64 unsigned remainder through assigned registers" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i64 @remainder(i64 %a, i64 %b) {
        \\entry:
        \\  %r = urem i64 %a, %b
        \\  ret i64 %r
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    var machine = codegen.x86_64.MachineFunction.init("remainder", module.functions.items[0].ret_ty);
    defer machine.deinit(std.testing.allocator);

    const result = try selector.tryLower(std.testing.allocator, &machine, module.functions.items[0]);
    switch (result) {
        .selected => {},
        .unsupported => |diagnostic| {
            std.debug.print("unexpected selector diagnostic {s}: {s}\n", .{ diagnostic.tagName(), diagnostic.detail() });
            return error.TestExpectedSelected;
        },
    }

    try std.testing.expectEqual(@as(usize, 6), machine.instructions.items.len);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .mov_arg_rax = .rdi }, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .mov_arg64_arg = .{ .dst = .rcx, .src = .rsi } }, machine.instructions.items[1]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.xor_edx_edx, machine.instructions.items[2]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .div_arg64 = .rcx }, machine.instructions.items[3]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .mov_arg_rax = .rdx }, machine.instructions.items[4]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[5]);
}

test "generic cfg selector copies aliased accumulator operand" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @double_use(i32 %a, i32 %b) {
        \\entry:
        \\  %sum = add i32 %a, %b
        \\  %double = add i32 %sum, %sum
        \\  ret i32 %double
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    var machine = codegen.x86_64.MachineFunction.init("double_use", module.functions.items[0].ret_ty);
    defer machine.deinit(std.testing.allocator);

    const result = try selector.tryLower(std.testing.allocator, &machine, module.functions.items[0]);
    try std.testing.expectEqual(selector.SelectionResult.selected, result);
    try expectInstruction(machine.instructions.items, .{ .mov_eax_to_arg = .rcx });
    try expectInstruction(machine.instructions.items, .{ .binary_arg_eax = .{ .op = .add, .reg = .rcx } });
}

test "generic cfg selector composes mulo i32 overflow flag through assigned registers" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @mulosi4(i32 %a, i32 %b, ptr %overflow) {
        \\entry:
        \\  %sa = sext i32 %a to i64
        \\  %sb = sext i32 %b to i64
        \\  %product = mul nsw i64 %sb, %sa
        \\  %biased = add nsw i64 %product, -2147483648
        \\  %too_large = icmp ult i64 %biased, -4294967296
        \\  %flag = zext i1 %too_large to i32
        \\  store i32 %flag, ptr %overflow, align 4
        \\  %retv = trunc i64 %product to i32
        \\  ret i32 %retv
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    var machine = codegen.x86_64.MachineFunction.init("mulosi4", module.functions.items[0].ret_ty);
    defer machine.deinit(std.testing.allocator);

    const result = try selector.tryLower(std.testing.allocator, &machine, module.functions.items[0]);
    switch (result) {
        .selected => {},
        .unsupported => |diagnostic| {
            std.debug.print("unexpected selector diagnostic {s}: {s}\n", .{ diagnostic.tagName(), diagnostic.detail() });
            return error.TestExpectedSelected;
        },
    }

    try std.testing.expectEqual(@as(usize, 11), machine.instructions.items.len);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .movsxd_arg32_arg64 = .{ .dst = .r8, .src = .rdi } }, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .movsxd_arg32_arg64 = .{ .dst = .r9, .src = .rsi } }, machine.instructions.items[1]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .imul_arg64_arg64 = .{ .dst = .r9, .src = .r8 } }, machine.instructions.items[2]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .mov_arg64_arg = .{ .dst = .rcx, .src = .r9 } }, machine.instructions.items[3]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .add_arg64_imm32 = .{ .reg = .rcx, .imm = -2147483648 } }, machine.instructions.items[4]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .cmp_arg64_imm64 = .{ .reg = .rcx, .imm = -4294967296 } }, machine.instructions.items[5]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.setb_eax, machine.instructions.items[6]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .and_eax_imm32 = 1 }, machine.instructions.items[7]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .store_eax_arg_ptr = .rdx }, machine.instructions.items[8]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .mov_arg_eax = .r9 }, machine.instructions.items[9]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[10]);
}

test "generic cfg selector composes parity i32 through assigned scratch register" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @parity32(i32 %x) {
        \\entry:
        \\  %shr16 = lshr i32 %x, 16
        \\  %xor16 = xor i32 %shr16, %x
        \\  %shr8 = lshr i32 %xor16, 8
        \\  %xor8 = xor i32 %shr8, %xor16
        \\  %shr4 = lshr i32 %xor8, 4
        \\  %xor4 = xor i32 %shr4, %xor8
        \\  %narrow = trunc i32 %xor4 to i16
        \\  %nibble = and i16 %narrow, 15
        \\  %table = lshr i16 27030, %nibble
        \\  %bit = and i16 %table, 1
        \\  %ret = zext i16 %bit to i32
        \\  ret i32 %ret
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    var machine = codegen.x86_64.MachineFunction.init("parity32", module.functions.items[0].ret_ty);
    defer machine.deinit(std.testing.allocator);

    const result = try selector.tryLower(std.testing.allocator, &machine, module.functions.items[0]);
    switch (result) {
        .selected => {},
        .unsupported => |diagnostic| {
            std.debug.print("unexpected selector diagnostic {s}: {s}\n", .{ diagnostic.tagName(), diagnostic.detail() });
            return error.TestExpectedSelected;
        },
    }

    try std.testing.expectEqual(@as(usize, 17), machine.instructions.items.len);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .mov_arg_arg = .{ .dst = .rcx, .src = .rdi } }, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .shr_arg_imm5 = .{ .reg = .rcx, .amount = 16 } }, machine.instructions.items[1]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .binary_arg_eax = .{ .op = .xor, .reg = .rdi } }, machine.instructions.items[3]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .mov_eax_to_arg = .rcx }, machine.instructions.items[4]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.shr_eax_cl, machine.instructions.items[13]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[16]);
}

test "generic cfg selector composes parity i64 through assigned scratch register" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @parity64(i64 %x) {
        \\entry:
        \\  %shr32 = lshr i64 %x, 32
        \\  %xor32 = xor i64 %shr32, %x
        \\  %shr16 = lshr i64 %xor32, 16
        \\  %xor16 = xor i64 %shr16, %xor32
        \\  %shr8 = lshr i64 %xor16, 8
        \\  %xor8 = xor i64 %shr8, %xor16
        \\  %shr4 = lshr i64 %xor8, 4
        \\  %xor4 = xor i64 %shr4, %xor8
        \\  %narrow = trunc i64 %xor4 to i16
        \\  %nibble = and i16 %narrow, 15
        \\  %table = lshr i16 27030, %nibble
        \\  %bit = and i16 %table, 1
        \\  %ret = zext i16 %bit to i32
        \\  ret i32 %ret
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    var machine = codegen.x86_64.MachineFunction.init("parity64", module.functions.items[0].ret_ty);
    defer machine.deinit(std.testing.allocator);

    const result = try selector.tryLower(std.testing.allocator, &machine, module.functions.items[0]);
    switch (result) {
        .selected => {},
        .unsupported => |diagnostic| {
            std.debug.print("unexpected selector diagnostic {s}: {s}\n", .{ diagnostic.tagName(), diagnostic.detail() });
            return error.TestExpectedSelected;
        },
    }

    try std.testing.expectEqual(@as(usize, 20), machine.instructions.items.len);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .mov_arg64_arg = .{ .dst = .rsi, .src = .rdi } }, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .shr_arg64_imm6 = .{ .reg = .rsi, .amount = 32 } }, machine.instructions.items[1]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .binary_arg_rax = .{ .op = .xor, .reg = .rdi } }, machine.instructions.items[3]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .mov_rax_to_arg = .rdi }, machine.instructions.items[4]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.shr_eax_cl, machine.instructions.items[16]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[19]);
}

test "generic cfg selector composes parity i128 through assigned register pair" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i32 @parity128(i128 %x) {
        \\entry:
        \\  %shr64 = lshr i128 %x, 64
        \\  %xor64 = xor i128 %shr64, %x
        \\  %shr32 = lshr i128 %xor64, 32
        \\  %xor32 = xor i128 %shr32, %xor64
        \\  %shr16 = lshr i128 %xor32, 16
        \\  %xor16 = xor i128 %shr16, %xor32
        \\  %shr8 = lshr i128 %xor16, 8
        \\  %xor8 = xor i128 %shr8, %xor16
        \\  %shr4 = lshr i128 %xor8, 4
        \\  %xor4 = xor i128 %shr4, %xor8
        \\  %narrow = trunc i128 %xor4 to i16
        \\  %nibble = and i16 %narrow, 15
        \\  %table = lshr i16 27030, %nibble
        \\  %bit = and i16 %table, 1
        \\  %ret = zext i16 %bit to i32
        \\  ret i32 %ret
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    var machine = codegen.x86_64.MachineFunction.init("parity128", module.functions.items[0].ret_ty);
    defer machine.deinit(std.testing.allocator);

    const result = try selector.tryLower(std.testing.allocator, &machine, module.functions.items[0]);
    switch (result) {
        .selected => {},
        .unsupported => |diagnostic| {
            std.debug.print("unexpected selector diagnostic {s}: {s}\n", .{ diagnostic.tagName(), diagnostic.detail() });
            return error.TestExpectedSelected;
        },
    }

    try std.testing.expect(machine.instructions.items.len > 20);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .mov_arg64_arg = .{ .dst = .rcx, .src = .rsi } }, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .mov_imm_rdx = 0 }, machine.instructions.items[1]);
    try expectInstruction(machine.instructions.items, .{ .binary_arg_rax = .{ .op = .xor, .reg = .rcx } });
    try expectInstruction(machine.instructions.items, .{ .mov_rax_to_arg = .r8 });
    try expectInstruction(machine.instructions.items, .{ .binary_arg_rax = .{ .op = .xor, .reg = .rdx } });
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[machine.instructions.items.len - 1]);
}
