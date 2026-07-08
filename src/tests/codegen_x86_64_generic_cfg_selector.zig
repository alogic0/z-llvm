const common = @import("codegen_x86_64_common.zig");

const std = common.std;
const codegen = common.codegen;
const ir = common.ir;
const selector = @import("../codegen/x86_64/generic_cfg_selector.zig");

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

test "generic cfg selector emits limb64 multiply envelope through opt-in selector" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i1 @candidate(ptr %out, ptr %a, ptr %b, i1 %signed, i16 %bits) {
        \\entry:
        \\  %overflow_slot = alloca i8, align 1
        \\  %bytes = call fastcc i16 @zig.target.intByteSize(i16 %bits)
        \\  %a0p = getelementptr inbounds [8 x i8], ptr %a, i64 0
        \\  %b0p = getelementptr inbounds [8 x i8], ptr %b, i64 0
        \\  %a0 = load i64, ptr %a0p, align 8
        \\  %b0 = load i64, ptr %b0p, align 8
        \\  %a_lo = and i64 %a0, 4294967295
        \\  %b_lo = and i64 %b0, 4294967295
        \\  %a_hi = lshr i64 %a0, 32
        \\  %b_hi = lshr i64 %b0, 32
        \\  %p0 = mul nuw i64 %a_lo, %b_lo
        \\  %p1 = mul nuw i64 %a_hi, %b_lo
        \\  %p2 = mul nuw i64 %a_lo, %b_hi
        \\  %p3 = mul nuw i64 %a_hi, %b_hi
        \\  %sum_pair = call { i64, i1 } @llvm.uadd.with.overflow.i64(i64 %p0, i64 %p1)
        \\  %sum = extractvalue { i64, i1 } %sum_pair, 0
        \\  %carry0 = extractvalue { i64, i1 } %sum_pair, 1
        \\  %sum_pair2 = call { i64, i1 } @llvm.uadd.with.overflow.i64(i64 %sum, i64 %p2)
        \\  %sum2 = extractvalue { i64, i1 } %sum_pair2, 0
        \\  %carry1 = extractvalue { i64, i1 } %sum_pair2, 1
        \\  %sub_pair = call { i64, i1 } @llvm.usub.with.overflow.i64(i64 %sum2, i64 %p3)
        \\  %diff = extractvalue { i64, i1 } %sub_pair, 0
        \\  %borrow = extractvalue { i64, i1 } %sub_pair, 1
        \\  store i1 %borrow, ptr %overflow_slot, align 1
        \\  %out0 = getelementptr inbounds [8 x i8], ptr %out, i64 0
        \\  store i64 %sum2, ptr %out0, align 8
        \\  %out1 = getelementptr inbounds [8 x i8], ptr %out, i64 1
        \\  store i64 %diff, ptr %out1, align 8
        \\  ret i1 %borrow
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
    try std.testing.expectEqual(@as(usize, 1), machine.instructions.items.len);
    try std.testing.expectEqual(.mulo_limb64_rdi_rsi_rdx_cl_r8w_al, machine.instructions.items[0]);
}

test "generic cfg selector keeps limb64 multiply near miss fail-closed" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i1 @near_miss(ptr %out, ptr %a, ptr %b, i1 %signed, i16 %bits) {
        \\entry:
        \\  %overflow_slot = alloca i8, align 1
        \\  %bytes = call fastcc i16 @zig.target.intByteSize(i16 %bits)
        \\  %a0 = load i64, ptr %a, align 8
        \\  %b0 = load i64, ptr %b, align 8
        \\  %p0 = mul nuw i64 %a0, %b0
        \\  %p1 = mul nuw i64 %a0, %b0
        \\  %p2 = mul nuw i64 %a0, %b0
        \\  %p3 = mul nuw i64 %a0, %b0
        \\  %sum_pair = call { i64, i1 } @llvm.uadd.with.overflow.i64(i64 %p0, i64 %p1)
        \\  %sum = extractvalue { i64, i1 } %sum_pair, 0
        \\  %carry = extractvalue { i64, i1 } %sum_pair, 1
        \\  store i1 %carry, ptr %overflow_slot, align 1
        \\  store i64 %sum, ptr %out, align 8
        \\  ret i1 %carry
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    var machine = codegen.x86_64.MachineFunction.init("near_miss", module.functions.items[0].ret_ty);
    defer machine.deinit(std.testing.allocator);

    const result = try selector.tryLower(std.testing.allocator, &machine, module.functions.items[0]);
    const diagnostic = switch (result) {
        .selected => return error.TestExpectedUnsupported,
        .unsupported => |diagnostic| diagnostic,
    };
    try std.testing.expectEqualStrings("no_emitter", diagnostic.tagName());
}

test "generic cfg selector emits limb64 byteswap envelope through opt-in selector" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define void @candidate(ptr %out, ptr %a, i1 %signed, i16 %bits) {
        \\entry:
        \\  %frozen = freeze i16 %bits
        \\  %is_zero = icmp eq i16 %frozen, 0
        \\  %minus_one = add i16 %frozen, -1
        \\  %limb_index = lshr i16 %minus_one, 6
        \\  %limb_count = add i16 %limb_index, 1
        \\  %bytes = call fastcc i16 @zig.target.intByteSize(i16 %frozen)
        \\  %rem = and i16 %frozen, 7
        \\  %byte_aligned = icmp eq i16 %rem, 0
        \\  call void @llvm.assume(i1 %byte_aligned)
        \\  br i1 %is_zero, label %done, label %loop
        \\
        \\loop:
        \\  %i = phi i64 [ 0, %entry ], [ %next, %loop ]
        \\  %src = getelementptr inbounds nuw [8 x i8], ptr %a, i64 %i
        \\  %value = load i64, ptr %src, align 8
        \\  %swapped = call i64 @llvm.bswap.i64(i64 %value)
        \\  %dst_index16 = sub i16 %limb_count, 1
        \\  %dst_index = zext i16 %dst_index16 to i64
        \\  %dst = getelementptr inbounds nuw [8 x i8], ptr %out, i64 %dst_index
        \\  store i64 %swapped, ptr %dst, align 8
        \\  %next = add nuw nsw i64 %i, 1
        \\  %exit = icmp eq i64 %next, 1
        \\  br i1 %exit, label %done, label %loop
        \\
        \\done:
        \\  ret void
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
    try std.testing.expectEqual(@as(usize, 1), machine.instructions.items.len);
    try std.testing.expectEqual(.byteswap_limb64_rdi_rsi_dl_cx, machine.instructions.items[0]);
}

test "generic cfg selector keeps limb64 byteswap near miss fail-closed" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define void @near_miss(ptr %out, ptr %a, i1 %signed, i16 %bits) {
        \\entry:
        \\  %frozen = freeze i16 %bits
        \\  %minus_one = add i16 %frozen, -1
        \\  %limb_index = lshr i16 %minus_one, 6
        \\  %bytes = call fastcc i16 @zig.target.intByteSize(i16 %frozen)
        \\  %rem = and i16 %frozen, 7
        \\  %byte_aligned = icmp eq i16 %rem, 0
        \\  call void @llvm.assume(i1 %byte_aligned)
        \\  %value = load i64, ptr %a, align 8
        \\  store i64 %value, ptr %out, align 8
        \\  ret void
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    var machine = codegen.x86_64.MachineFunction.init("near_miss", module.functions.items[0].ret_ty);
    defer machine.deinit(std.testing.allocator);

    const result = try selector.tryLower(std.testing.allocator, &machine, module.functions.items[0]);
    const diagnostic = switch (result) {
        .selected => return error.TestExpectedUnsupported,
        .unsupported => |diagnostic| diagnostic,
    };
    try std.testing.expectEqualStrings("unsupported_instruction", diagnostic.tagName());
}

test "generic cfg selector emits limb64 shift-right envelope through opt-in selector" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define void @candidate(ptr %out, ptr %a, i16 %shift, i1 %signed, i16 %bits) {
        \\entry:
        \\  %frozen_shift = freeze i16 %shift
        \\  %minus_one = add i16 %bits, -1
        \\  %limb_index = lshr i16 %minus_one, 6
        \\  %limb_count = add i16 %limb_index, 1
        \\  %bytes = call fastcc i16 @zig.target.intByteSize(i16 %bits)
        \\  %shift_ok = icmp ult i16 %frozen_shift, %bits
        \\  call void @llvm.assume(i1 %shift_ok)
        \\  %limb_shift = lshr i16 %frozen_shift, 6
        \\  %bit_shift = and i16 %frozen_shift, 63
        \\  %top_ptr = getelementptr inbounds nuw [8 x i8], ptr %a, i64 1
        \\  %top = load i64, ptr %top_ptr, align 8
        \\  %top_neg = icmp slt i64 %top, 0
        \\  %sign = select i1 %signed, i1 %top_neg, i1 false
        \\  br i1 %sign, label %loop, label %loop
        \\
        \\loop:
        \\  %i = phi i64 [ 0, %entry ], [ %next, %loop ]
        \\  %src = getelementptr inbounds nuw [8 x i8], ptr %a, i64 %i
        \\  %limb = load i64, ptr %src, align 8
        \\  %right = lshr i64 %limb, 1
        \\  %left = shl i64 %top, 63
        \\  %shifted = or i64 %right, %left
        \\  %dst = getelementptr inbounds nuw [8 x i8], ptr %out, i64 %i
        \\  store i64 %shifted, ptr %dst, align 8
        \\  %fill = ashr i64 %top, 63
        \\  %dst2 = getelementptr inbounds nuw [8 x i8], ptr %out, i64 1
        \\  store i64 %fill, ptr %dst2, align 8
        \\  %next = add nuw nsw i64 %i, 1
        \\  %exit = icmp eq i64 %next, 1
        \\  br i1 %exit, label %done, label %loop
        \\
        \\done:
        \\  ret void
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
    try std.testing.expectEqual(@as(usize, 1), machine.instructions.items.len);
    try std.testing.expectEqual(.shr_limb64_rdi_rsi_dx_cl_r8w, machine.instructions.items[0]);
}

test "generic cfg selector keeps limb64 shift-right near miss fail-closed" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define void @near_miss(ptr %out, ptr %a, i16 %shift, i1 %signed, i16 %bits) {
        \\entry:
        \\  %frozen_shift = freeze i16 %shift
        \\  %minus_one = add i16 %bits, -1
        \\  %limb_index = lshr i16 %minus_one, 6
        \\  %bytes = call fastcc i16 @zig.target.intByteSize(i16 %bits)
        \\  %shift_ok = icmp ult i16 %frozen_shift, %bits
        \\  call void @llvm.assume(i1 %shift_ok)
        \\  %bit_shift = and i16 %frozen_shift, 63
        \\  %top = load i64, ptr %a, align 8
        \\  %top_neg = icmp slt i64 %top, 0
        \\  %sign = select i1 %signed, i1 %top_neg, i1 false
        \\  %right = lshr i64 %top, 1
        \\  store i64 %right, ptr %out, align 8
        \\  ret void
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    var machine = codegen.x86_64.MachineFunction.init("near_miss", module.functions.items[0].ret_ty);
    defer machine.deinit(std.testing.allocator);

    const result = try selector.tryLower(std.testing.allocator, &machine, module.functions.items[0]);
    const diagnostic = switch (result) {
        .selected => return error.TestExpectedUnsupported,
        .unsupported => |diagnostic| diagnostic,
    };
    try std.testing.expectEqualStrings("unsupported_instruction", diagnostic.tagName());
}

test "generic cfg selector emits limb64 bitreverse envelope through opt-in selector" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define void @candidate(ptr %out, ptr %a, i1 %signed, i16 %bits) {
        \\entry:
        \\  %frozen = freeze i16 %bits
        \\  %is_zero = icmp eq i16 %frozen, 0
        \\  %minus_one = add i16 %frozen, -1
        \\  %limb_index = lshr i16 %minus_one, 6
        \\  %limb_count = add i16 %limb_index, 1
        \\  %bytes = call fastcc i16 @zig.target.intByteSize(i16 %frozen)
        \\  %limb_count64 = zext i16 %limb_count to i64
        \\  %umax = call i64 @llvm.umax.i64(i64 %limb_count64, i64 1)
        \\  br i1 %is_zero, label %done, label %loop
        \\
        \\loop:
        \\  %i = phi i64 [ 0, %entry ], [ %next, %loop ]
        \\  %src = getelementptr inbounds nuw [8 x i8], ptr %a, i64 %i
        \\  %value = load i64, ptr %src, align 8
        \\  %reversed = call i64 @llvm.bitreverse.i64(i64 %value)
        \\  %dst_index = sub i64 %umax, %i
        \\  %dst_index2 = add i64 %dst_index, -1
        \\  %dst = getelementptr inbounds nuw [8 x i8], ptr %out, i64 %dst_index2
        \\  store i64 %reversed, ptr %dst, align 8
        \\  %next = add nuw nsw i64 %i, 1
        \\  %exit = icmp eq i64 %next, %umax
        \\  br i1 %exit, label %tail, label %loop
        \\
        \\tail:
        \\  %rem = and i16 %frozen, 63
        \\  %needs_shift = icmp eq i16 %rem, 0
        \\  %top_ptr = getelementptr inbounds nuw [8 x i8], ptr %out, i64 1
        \\  %top = load i64, ptr %top_ptr, align 8
        \\  %sign_fill = ashr i64 %top, 63
        \\  %right = lshr i64 %top, 1
        \\  %left = shl i64 %sign_fill, 63
        \\  %shifted = or i64 %right, %left
        \\  store i64 %shifted, ptr %top_ptr, align 8
        \\  br i1 %needs_shift, label %done, label %done
        \\
        \\done:
        \\  ret void
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
    try std.testing.expectEqual(@as(usize, 1), machine.instructions.items.len);
    try std.testing.expectEqual(.bitreverse_limb64_rdi_rsi_dl_cx, machine.instructions.items[0]);
}

test "generic cfg selector keeps limb64 bitreverse near miss fail-closed" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define void @near_miss(ptr %out, ptr %a, i1 %signed, i16 %bits) {
        \\entry:
        \\  %frozen = freeze i16 %bits
        \\  %minus_one = add i16 %frozen, -1
        \\  %limb_index = lshr i16 %minus_one, 6
        \\  %bytes = call fastcc i16 @zig.target.intByteSize(i16 %frozen)
        \\  %limb_count64 = zext i16 %limb_index to i64
        \\  %umax = call i64 @llvm.umax.i64(i64 %limb_count64, i64 1)
        \\  %rem = and i16 %frozen, 63
        \\  %value = load i64, ptr %a, align 8
        \\  store i64 %value, ptr %out, align 8
        \\  ret void
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    var machine = codegen.x86_64.MachineFunction.init("near_miss", module.functions.items[0].ret_ty);
    defer machine.deinit(std.testing.allocator);

    const result = try selector.tryLower(std.testing.allocator, &machine, module.functions.items[0]);
    const diagnostic = switch (result) {
        .selected => return error.TestExpectedUnsupported,
        .unsupported => |diagnostic| diagnostic,
    };
    try std.testing.expectEqualStrings("unsupported_instruction", diagnostic.tagName());
}

test "generic cfg selector skeleton fails closed with first unsupported instruction form" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define float @float_add(float %a, float %b) {
        \\entry:
        \\  %sum = fadd float %a, %b
        \\  ret float %sum
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
    try std.testing.expectEqualStrings("unsupported_type", diagnostic.tagName());
    try std.testing.expectEqualStrings("unsupported-return-type", diagnostic.detail());
}

test "generic cfg selector planning accepts scalar phi and overflow extracts" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i64 @phi_overflow(i64 %a, i1 %cond) {
        \\entry:
        \\  br i1 %cond, label %then, label %merge
        \\then:
        \\  %pair = call { i64, i1 } @llvm.uadd.with.overflow.i64(i64 %a, i64 1)
        \\  %sum = extractvalue { i64, i1 } %pair, 0
        \\  %overflow = extractvalue { i64, i1 } %pair, 1
        \\  call void @llvm.assume(i1 %overflow)
        \\  br label %merge
        \\merge:
        \\  %value = phi i64 [ %a, %entry ], [ %sum, %then ]
        \\  ret i64 %value
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

test "generic cfg selector rejects unsupported aggregate extract" {
    var function = ir.Function.init("bad_extract", .{ .int = 32 });
    defer function.deinit(std.testing.allocator);

    var block = ir.BasicBlock.init("entry");
    errdefer block.deinit(std.testing.allocator);
    try block.instructions.append(std.testing.allocator, .{
        .result = "value",
        .kind = .{ .extractvalue = .{
            .aggregate_ty = .{ .aggregate = "{ i32, i32 }" },
            .aggregate = .undef,
            .indices = "0",
            .result_ty = .{ .int = 32 },
        } },
    });
    block.terminator = .{ .ret = .{
        .ty = .{ .int = 32 },
        .value = .{ .named = "value" },
    } };
    try function.blocks.append(std.testing.allocator, block);

    const result = selector.inspectFunction(function);
    const diagnostic = switch (result) {
        .selected => return error.TestExpectedUnsupported,
        .unsupported => |diagnostic| diagnostic,
    };
    try std.testing.expectEqualStrings("unsupported_type", diagnostic.tagName());
    try std.testing.expectEqualStrings("extractvalue-aggregate", diagnostic.detail());
}
