const common = @import("codegen_x86_64_common.zig");

const std = common.std;
const codegen = common.codegen;
const ir = common.ir;
const selector = @import("../codegen/x86_64/generic_cfg_selector.zig");

fn expectInstruction(instructions: []const codegen.x86_64.Instruction, expected: codegen.x86_64.Instruction) !void {
    for (instructions) |instruction| {
        if (std.meta.eql(instruction, expected)) return;
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
    try std.testing.expectEqualStrings("no_emitter", diagnostic.tagName());
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
    try std.testing.expectEqualStrings("no_emitter", diagnostic.tagName());
}

test "generic cfg selector emits limb64 shift-left-overflow envelope through opt-in selector" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i1 @candidate(ptr %out, ptr %a, i16 %shift, i1 %signed, i16 %bits) {
        \\entry:
        \\  %frozen_shift = freeze i16 %shift
        \\  %minus_one = add i16 %bits, -1
        \\  %limb_index = lshr i16 %minus_one, 6
        \\  %limb_count = add i16 %limb_index, 1
        \\  %bytes = call fastcc i16 @zig.target.intByteSize(i16 %bits)
        \\  %shift_ok = icmp ult i16 %frozen_shift, %bits
        \\  call void @llvm.assume(i1 %shift_ok)
        \\  %limb_shift = lshr i16 %frozen_shift, 6
        \\  %bit_shift16 = and i16 %frozen_shift, 63
        \\  %bit_shift = zext i16 %bit_shift16 to i64
        \\  %neg_shift = sub i16 0, %frozen_shift
        \\  %carry_shift16 = and i16 %neg_shift, 63
        \\  %carry_shift = zext i16 %carry_shift16 to i64
        \\  %src0 = load i64, ptr %a, align 8
        \\  %left = shl i64 %src0, %bit_shift
        \\  %carry = lshr i64 %src0, %carry_shift
        \\  %raw_last = or i64 %left, 0
        \\  %tail_bits = and i16 %bits, 63
        \\  %tail_is_full = icmp eq i16 %tail_bits, 0
        \\  br i1 %tail_is_full, label %full, label %partial
        \\
        \\partial:
        \\  %neg_bits = sub i16 0, %bits
        \\  %mask_shift16 = and i16 %neg_bits, 63
        \\  %mask_shift = zext i16 %mask_shift16 to i64
        \\  %mask = lshr i64 -1, %mask_shift
        \\  %masked = and i64 %raw_last, %mask
        \\  %sign_shifted = shl i64 %raw_last, %mask_shift
        \\  %signed_tail = ashr exact i64 %sign_shifted, %mask_shift
        \\  %wrapped = select i1 %signed, i64 %signed_tail, i64 %masked
        \\  br label %full
        \\
        \\full:
        \\  %last = phi i64 [ %raw_last, %entry ], [ %wrapped, %partial ]
        \\  store i64 %last, ptr %out, align 8
        \\  %last_negative = icmp slt i64 %last, 0
        \\  %use_sign = select i1 %signed, i1 %last_negative, i1 false
        \\  %sign = sext i1 %use_sign to i64
        \\  %expected_carry = lshr i64 %sign, %carry_shift
        \\  %carry_overflow = icmp ne i64 %carry, %expected_carry
        \\  %wrap_overflow = icmp ne i64 %raw_last, %last
        \\  %overflow0 = select i1 %carry_overflow, i1 true, i1 %wrap_overflow
        \\  %src1_ptr = getelementptr inbounds nuw [8 x i8], ptr %a, i64 1
        \\  %src1 = load i64, ptr %src1_ptr, align 8
        \\  %src2_ptr = getelementptr inbounds nuw [8 x i8], ptr %a, i64 2
        \\  %src2 = load i64, ptr %src2_ptr, align 8
        \\  %extra = or i64 %src1, %src2
        \\  %extra_overflow = icmp ne i64 %extra, %sign
        \\  %overflow = select i1 %overflow0, i1 true, i1 %extra_overflow
        \\  %dst1 = getelementptr inbounds nuw [8 x i8], ptr %out, i64 1
        \\  store i64 %sign, ptr %dst1, align 8
        \\  ret i1 %overflow
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
    try std.testing.expectEqual(.shlo_limb64_rdi_rsi_dx_cl_r8w_al, machine.instructions.items[0]);
}

test "generic cfg selector keeps limb64 shift-left-overflow near miss fail-closed" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i1 @near_miss(ptr %out, ptr %a, i16 %shift, i1 %signed, i16 %bits) {
        \\entry:
        \\  %frozen_shift = freeze i16 %shift
        \\  %minus_one = add i16 %bits, -1
        \\  %limb_index = lshr i16 %minus_one, 6
        \\  %bytes = call fastcc i16 @zig.target.intByteSize(i16 %bits)
        \\  %shift_ok = icmp ult i16 %frozen_shift, %bits
        \\  call void @llvm.assume(i1 %shift_ok)
        \\  %bit_shift16 = and i16 %frozen_shift, 63
        \\  %bit_shift = zext i16 %bit_shift16 to i64
        \\  %src0 = load i64, ptr %a, align 8
        \\  %left = shl i64 %src0, %bit_shift
        \\  store i64 %left, ptr %out, align 8
        \\  ret i1 false
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
    try std.testing.expectEqualStrings("no_emitter", diagnostic.tagName());
}

test "generic cfg selector emits limb64 popcount envelope through opt-in selector" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i16 @candidate(ptr %a, i16 %bits) {
        \\entry:
        \\  %is_zero = icmp eq i16 %bits, 0
        \\  %minus_one = add i16 %bits, -1
        \\  %last = lshr i16 %minus_one, 6
        \\  %bytes = call fastcc i16 @zig.target.intByteSize(i16 %bits)
        \\  %selected_last = select i1 %is_zero, i16 -1, i16 %last
        \\  %last64 = zext i16 %selected_last to i64
        \\  %has_prefix = icmp eq i16 %selected_last, 0
        \\  br i1 %has_prefix, label %tail, label %loop
        \\
        \\loop:
        \\  %sum = phi i16 [ 0, %entry ], [ %sum_next, %loop ]
        \\  %i = phi i64 [ 0, %entry ], [ %next, %loop ]
        \\  %ptr = getelementptr inbounds nuw [8 x i8], ptr %a, i64 %i
        \\  %value = load i64, ptr %ptr, align 8
        \\  %count = call i64 @llvm.ctpop.i64(i64 %value)
        \\  %narrow = trunc i64 %count to i16
        \\  %sum_next = add i16 %sum, %narrow
        \\  %next = add i64 %i, 1
        \\  %exit = icmp eq i64 %next, %last64
        \\  br i1 %exit, label %tail, label %loop
        \\
        \\tail:
        \\  %prefix = phi i16 [ 0, %entry ], [ %sum_next, %loop ]
        \\  %tail_ptr = getelementptr inbounds nuw [8 x i8], ptr %a, i64 %last64
        \\  %tail_value = load i64, ptr %tail_ptr, align 8
        \\  %rem = and i16 %bits, 63
        \\  %neg_bits = sub i16 0, %bits
        \\  %tail_shift16 = and i16 %neg_bits, 63
        \\  %tail_shift = zext i16 %tail_shift16 to i64
        \\  %masked = shl i64 %tail_value, %tail_shift
        \\  %tail_count = call i64 @llvm.ctpop.i64(i64 %masked)
        \\  %tail_narrow = trunc i64 %tail_count to i16
        \\  %total = add i16 %prefix, %tail_narrow
        \\  ret i16 %total
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
    try std.testing.expectEqual(.popcount_limb64_rdi_si_ax, machine.instructions.items[0]);
}

test "generic cfg selector keeps limb64 popcount near miss fail-closed" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i16 @near_miss(ptr %a, i16 %bits) {
        \\entry:
        \\  %minus_one = add i16 %bits, -1
        \\  %last = lshr i16 %minus_one, 6
        \\  %bytes = call fastcc i16 @zig.target.intByteSize(i16 %bits)
        \\  %last64 = zext i16 %last to i64
        \\  %ptr = getelementptr inbounds nuw [8 x i8], ptr %a, i64 %last64
        \\  %value = load i64, ptr %ptr, align 8
        \\  %count = trunc i64 %value to i16
        \\  ret i16 %count
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

test "generic cfg selector emits limb64 ctz envelope through opt-in selector" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i16 @candidate(ptr %a, i16 %bits) {
        \\entry:
        \\  %is_zero = icmp eq i16 %bits, 0
        \\  %minus_one = add i16 %bits, -1
        \\  %last = lshr i16 %minus_one, 6
        \\  %bytes = call fastcc i16 @zig.target.intByteSize(i16 %bits)
        \\  %selected_last = select i1 %is_zero, i16 -1, i16 %last
        \\  %last64 = zext i16 %selected_last to i64
        \\  %has_prefix = icmp eq i16 %selected_last, 0
        \\  br i1 %has_prefix, label %tail, label %preheader
        \\
        \\preheader:
        \\  %prefix_bits = shl i16 %selected_last, 6
        \\  br label %loop
        \\
        \\loop:
        \\  %sum = phi i16 [ 0, %preheader ], [ %sum_next, %zero_limb ]
        \\  %i = phi i64 [ 0, %preheader ], [ %next, %zero_limb ]
        \\  %ptr = getelementptr inbounds nuw [8 x i8], ptr %a, i64 %i
        \\  %value = load i64, ptr %ptr, align 8
        \\  %value_is_zero = icmp eq i64 %value, 0
        \\  br i1 %value_is_zero, label %zero_limb, label %found
        \\
        \\zero_limb:
        \\  %sum_next = add i16 %sum, 64
        \\  %next = add i64 %i, 1
        \\  %exit = icmp eq i64 %next, %last64
        \\  br i1 %exit, label %tail, label %loop
        \\
        \\tail:
        \\  %prefix = phi i16 [ 0, %entry ], [ %prefix_bits, %zero_limb ]
        \\  %tail_ptr = getelementptr inbounds nuw [8 x i8], ptr %a, i64 %last64
        \\  %tail_value = load i64, ptr %tail_ptr, align 8
        \\  %rem = and i16 %bits, 63
        \\  %has_rem = icmp ne i16 %rem, 0
        \\  %tail_is_zero = icmp eq i64 %tail_value, 0
        \\  %partial_zero = select i1 %has_rem, i1 %tail_is_zero, i1 false
        \\  %partial_total = or i16 %prefix, %rem
        \\  %tail_count = call i64 @llvm.cttz.i64(i64 %tail_value, i1 false)
        \\  %tail_narrow = trunc i64 %tail_count to i16
        \\  %tail_total = add i16 %prefix, %tail_narrow
        \\  %total = select i1 %partial_zero, i16 %partial_total, i16 %tail_total
        \\  ret i16 %total
        \\
        \\found:
        \\  %count = call i64 @llvm.cttz.i64(i64 %value, i1 true)
        \\  %narrow = trunc i64 %count to i16
        \\  %found_total = or i16 %sum, %narrow
        \\  ret i16 %found_total
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
    try std.testing.expectEqual(.ctz_limb64_rdi_si_ax, machine.instructions.items[0]);
}

test "generic cfg selector keeps limb64 ctz near miss fail-closed" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i16 @near_miss(ptr %a, i16 %bits) {
        \\entry:
        \\  %minus_one = add i16 %bits, -1
        \\  %last = lshr i16 %minus_one, 6
        \\  %bytes = call fastcc i16 @zig.target.intByteSize(i16 %bits)
        \\  %last64 = zext i16 %last to i64
        \\  %ptr = getelementptr inbounds nuw [8 x i8], ptr %a, i64 %last64
        \\  %value = load i64, ptr %ptr, align 8
        \\  %count = trunc i64 %value to i16
        \\  ret i16 %count
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

test "generic cfg selector emits limb64 clz envelope through opt-in selector" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i16 @candidate(ptr %a, i16 %bits) {
        \\entry:
        \\  %is_zero = icmp eq i16 %bits, 0
        \\  %minus_one = add i16 %bits, -1
        \\  %last = lshr i16 %minus_one, 6
        \\  %nlimbs_raw = add i16 %last, 1
        \\  %nlimbs = select i1 %is_zero, i16 0, i16 %nlimbs_raw
        \\  %bytes = call fastcc i16 @zig.target.intByteSize(i16 %bits)
        \\  %nlimbs64 = zext i16 %nlimbs to i64
        \\  %rem = and i16 %bits, 63
        \\  %full_tail = icmp eq i16 %rem, 0
        \\  br i1 %full_tail, label %loop_check, label %partial
        \\
        \\partial:
        \\  %last64 = zext i16 %last to i64
        \\  %tail_ptr = getelementptr inbounds nuw [8 x i8], ptr %a, i64 %last64
        \\  %tail = load i64, ptr %tail_ptr, align 8
        \\  %tail_is_zero = icmp eq i64 %tail, 0
        \\  br i1 %tail_is_zero, label %loop_check_from_partial, label %partial_nonzero
        \\
        \\partial_nonzero:
        \\  %neg_bits = sub i16 0, %bits
        \\  %shift16 = and i16 %neg_bits, 63
        \\  %shift = zext i16 %shift16 to i64
        \\  %shifted = shl i64 %tail, %shift
        \\  %partial_count = call i64 @llvm.ctlz.i64(i64 %shifted, i1 false)
        \\  %partial_narrow = trunc i64 %partial_count to i16
        \\  ret i16 %partial_narrow
        \\
        \\loop_check_from_partial:
        \\  br label %loop_check
        \\
        \\loop_check:
        \\  %sum = phi i16 [ 0, %entry ], [ %rem, %loop_check_from_partial ], [ %sum_next, %zero_limb ]
        \\  %i = phi i64 [ 0, %entry ], [ 1, %loop_check_from_partial ], [ %next_i, %zero_limb ]
        \\  %has_limb = icmp ult i64 %i, %nlimbs64
        \\  br i1 %has_limb, label %loop_body, label %done
        \\
        \\loop_body:
        \\  %last_index = add i16 %nlimbs, -1
        \\  %last_index64 = zext i16 %last_index to i64
        \\  %index = sub i64 %last_index64, %i
        \\  %ptr = getelementptr inbounds nuw [8 x i8], ptr %a, i64 %index
        \\  %value = load i64, ptr %ptr, align 8
        \\  %value_is_zero = icmp eq i64 %value, 0
        \\  br i1 %value_is_zero, label %zero_limb, label %found
        \\
        \\zero_limb:
        \\  %sum_next = add i16 %sum, 64
        \\  %next_i = add i64 %i, 1
        \\  br label %loop_check
        \\
        \\found:
        \\  %count = call i64 @llvm.ctlz.i64(i64 %value, i1 true)
        \\  %narrow = trunc i64 %count to i16
        \\  %found_total = add i16 %sum, %narrow
        \\  ret i16 %found_total
        \\
        \\done:
        \\  ret i16 %sum
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
    try std.testing.expectEqual(.clz_limb64_rdi_si_ax, machine.instructions.items[0]);
}

test "generic cfg selector keeps limb64 clz near miss fail-closed" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i16 @near_miss(ptr %a, i16 %bits) {
        \\entry:
        \\  %minus_one = add i16 %bits, -1
        \\  %last = lshr i16 %minus_one, 6
        \\  %bytes = call fastcc i16 @zig.target.intByteSize(i16 %bits)
        \\  %last64 = zext i16 %last to i64
        \\  %ptr = getelementptr inbounds nuw [8 x i8], ptr %a, i64 %last64
        \\  %value = load i64, ptr %ptr, align 8
        \\  %count = trunc i64 %value to i16
        \\  ret i16 %count
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

test "generic cfg selector emits limb64 not envelope through opt-in selector" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define void @candidate(ptr %out, ptr %a, i1 %signed, i16 %bits) {
        \\entry:
        \\  %is_zero = icmp eq i16 %bits, 0
        \\  %minus_one = add i16 %bits, -1
        \\  %last = lshr i16 %minus_one, 6
        \\  %nlimbs_raw = add i16 %last, 1
        \\  %nlimbs = select i1 %is_zero, i16 0, i16 %nlimbs_raw
        \\  %bytes = call fastcc i16 @zig.target.intByteSize(i16 %bits)
        \\  %true_limb_count = lshr exact i16 %bytes, 3
        \\  %last64 = zext i16 %last to i64
        \\  %first_ptr = getelementptr inbounds nuw [8 x i8], ptr %a, i64 0
        \\  %first = load i64, ptr %first_ptr, align 8
        \\  %first_not = xor i64 %first, -1
        \\  %first_out = getelementptr inbounds nuw [8 x i8], ptr %out, i64 0
        \\  store i64 %first_not, ptr %first_out, align 8
        \\  %tail_ptr = getelementptr inbounds nuw [8 x i8], ptr %a, i64 %last64
        \\  %tail = load i64, ptr %tail_ptr, align 8
        \\  %tail_not = xor i64 %tail, -1
        \\  %rem = and i16 %bits, 63
        \\  %has_rem = icmp ne i16 %rem, 0
        \\  %neg_bits = sub i16 0, %bits
        \\  %shift16 = and i16 %neg_bits, 63
        \\  %shift = zext i16 %shift16 to i64
        \\  %mask = lshr i64 -1, %shift
        \\  %masked = and i64 %mask, %tail_not
        \\  %tail_value = select i1 %has_rem, i64 %masked, i64 %tail_not
        \\  %tail_out = getelementptr inbounds nuw [8 x i8], ptr %out, i64 %last64
        \\  store i64 %tail_value, ptr %tail_out, align 8
        \\  %same_limb_count = icmp eq i16 %nlimbs, %true_limb_count
        \\  br i1 %same_limb_count, label %done, label %fix
        \\
        \\fix:
        \\  %signed_tail = load i64, ptr %tail_out, align 8
        \\  %sign = ashr i64 %signed_tail, 63
        \\  %fill = select i1 %signed, i64 %sign, i64 0
        \\  %next_limb = zext i16 %nlimbs to i64
        \\  %fill_ptr = getelementptr inbounds nuw [8 x i8], ptr %out, i64 %next_limb
        \\  store i64 %fill, ptr %fill_ptr, align 8
        \\  %need_epil = icmp ne i64 %next_limb, 0
        \\  call void @llvm.assume(i1 %need_epil)
        \\  br label %done
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
    try std.testing.expectEqual(.not_limb64_rdi_rsi_dl_cx, machine.instructions.items[0]);
}

test "generic cfg selector keeps limb64 not near miss fail-closed" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define void @near_miss(ptr %out, ptr %a, i1 %signed, i16 %bits) {
        \\entry:
        \\  %bytes = call fastcc i16 @zig.target.intByteSize(i16 %bits)
        \\  %ptr = getelementptr inbounds nuw [8 x i8], ptr %a, i64 0
        \\  %value = load i64, ptr %ptr, align 8
        \\  %not_value = xor i64 %value, -1
        \\  store i64 %not_value, ptr %out, align 8
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
    try std.testing.expectEqualStrings("no_emitter", diagnostic.tagName());
}

test "generic cfg selector emits limb64 bitwise envelopes through opt-in selector" {
    const cases = [_]struct {
        op_text: []const u8,
        expected: codegen.x86_64.Instruction,
    }{
        .{ .op_text = "xor", .expected = .{ .bitwise_limb64_rdi_rsi_rdx_cx = .xor } },
        .{ .op_text = "or", .expected = .{ .bitwise_limb64_rdi_rsi_rdx_cx = .@"or" } },
        .{ .op_text = "and", .expected = .{ .bitwise_limb64_rdi_rsi_rdx_cx = .@"and" } },
    };

    for (cases) |case| {
        const text = try std.fmt.allocPrint(std.testing.allocator,
            \\target triple = "x86_64-unknown-linux-gnu"
            \\
            \\define void @candidate(ptr %out, ptr %a, ptr %b, i16 %bits) {{
            \\entry:
            \\  %bytes = call fastcc i16 @zig.target.intByteSize(i16 %bits)
            \\  %is_zero = icmp eq i16 %bytes, 0
            \\  br i1 %is_zero, label %done, label %pre
            \\
            \\pre:
            \\  %limbs = lshr exact i16 %bytes, 3
            \\  %limbs_min = call i16 @llvm.umax.i16(i16 %limbs, i16 1)
            \\  %limbs64 = zext i16 %limbs_min to i64
            \\  %xtraiter = and i64 %limbs64, 3
            \\  %has_epil = icmp ne i64 %xtraiter, 0
            \\  call void @llvm.assume(i1 %has_epil)
            \\  br label %body
            \\
            \\body:
            \\  %a0p = getelementptr inbounds nuw [8 x i8], ptr %a, i64 0
            \\  %a0 = load i64, ptr %a0p, align 8
            \\  %b0p = getelementptr inbounds nuw [8 x i8], ptr %b, i64 0
            \\  %b0 = load i64, ptr %b0p, align 8
            \\  %v0 = {s} i64 %a0, %b0
            \\  %out0 = getelementptr inbounds nuw [8 x i8], ptr %out, i64 0
            \\  store i64 %v0, ptr %out0, align 8
            \\  %a1p = getelementptr inbounds nuw [8 x i8], ptr %a, i64 1
            \\  %a1 = load i64, ptr %a1p, align 8
            \\  %b1p = getelementptr inbounds nuw [8 x i8], ptr %b, i64 1
            \\  %b1 = load i64, ptr %b1p, align 8
            \\  %v1 = {s} i64 %a1, %b1
            \\  %out1 = getelementptr inbounds nuw [8 x i8], ptr %out, i64 1
            \\  store i64 %v1, ptr %out1, align 8
            \\  br label %done
            \\
            \\done:
            \\  ret void
            \\}}
            \\
        , .{ case.op_text, case.op_text });
        defer std.testing.allocator.free(text);

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
        try std.testing.expectEqual(case.expected, machine.instructions.items[0]);
    }
}

test "generic cfg selector keeps limb64 bitwise near miss fail-closed" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define void @near_miss(ptr %out, ptr %a, ptr %b, i16 %bits) {
        \\entry:
        \\  %bytes = call fastcc i16 @zig.target.intByteSize(i16 %bits)
        \\  %a0 = load i64, ptr %a, align 8
        \\  %b0 = load i64, ptr %b, align 8
        \\  %v0 = xor i64 %a0, %b0
        \\  store i64 %v0, ptr %out, align 8
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
    try std.testing.expectEqualStrings("no_emitter", diagnostic.tagName());
}

test "generic cfg selector emits limb64 compare envelope through opt-in selector" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define signext i8 @candidate(ptr %a, ptr %b, i1 %signed, i16 %bits) {
        \\entry:
        \\  %is_zero = icmp eq i16 %bits, 0
        \\  %minus_one = add i16 %bits, -1
        \\  %last = lshr i16 %minus_one, 6
        \\  %nlimbs_raw = add i16 %last, 1
        \\  %nlimbs = select i1 %is_zero, i16 0, i16 %nlimbs_raw
        \\  %bytes = call fastcc i16 @zig.target.intByteSize(i16 %bits)
        \\  %nlimbs64 = zext i16 %nlimbs to i64
        \\  %last_index = add i16 %nlimbs, -1
        \\  %last_index64 = zext i16 %last_index to i64
        \\  br i1 %signed, label %signed_top, label %loop_check
        \\
        \\signed_top:
        \\  %sa_ptr = getelementptr inbounds nuw [8 x i8], ptr %a, i64 %last_index64
        \\  %sa = load i64, ptr %sa_ptr, align 8
        \\  %sb_ptr = getelementptr inbounds nuw [8 x i8], ptr %b, i64 %last_index64
        \\  %sb = load i64, ptr %sb_ptr, align 8
        \\  %signed_lt = icmp slt i64 %sa, %sb
        \\  br i1 %signed_lt, label %ret_neg, label %signed_gt_check
        \\
        \\signed_gt_check:
        \\  %signed_gt = icmp sgt i64 %sa, %sb
        \\  br i1 %signed_gt, label %ret_pos, label %loop_check
        \\
        \\loop_check:
        \\  %i = phi i64 [ 1, %signed_gt_check ], [ 0, %entry ], [ %next, %loop_continue ]
        \\  %in_range = icmp ult i64 %i, %nlimbs64
        \\  br i1 %in_range, label %loop_body, label %ret_zero
        \\
        \\loop_body:
        \\  %idx = sub i64 %last_index64, %i
        \\  %a_ptr = getelementptr inbounds nuw [8 x i8], ptr %a, i64 %idx
        \\  %av = load i64, ptr %a_ptr, align 8
        \\  %b_ptr = getelementptr inbounds nuw [8 x i8], ptr %b, i64 %idx
        \\  %bv = load i64, ptr %b_ptr, align 8
        \\  %unsigned_lt = icmp ult i64 %av, %bv
        \\  br i1 %unsigned_lt, label %ret_neg, label %unsigned_gt_check
        \\
        \\unsigned_gt_check:
        \\  %unsigned_gt = icmp ugt i64 %av, %bv
        \\  br i1 %unsigned_gt, label %ret_pos, label %loop_continue
        \\
        \\loop_continue:
        \\  %next = add i64 %i, 1
        \\  br label %loop_check
        \\
        \\ret_neg:
        \\  ret i8 -1
        \\ret_zero:
        \\  ret i8 0
        \\ret_pos:
        \\  ret i8 1
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
    try std.testing.expectEqual(.cmp_limb64_rdi_rsi_dl_cx_ax, machine.instructions.items[0]);
}

test "generic cfg selector keeps limb64 compare near miss fail-closed" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define signext i8 @near_miss(ptr %a, ptr %b, i1 %signed, i16 %bits) {
        \\entry:
        \\  %bytes = call fastcc i16 @zig.target.intByteSize(i16 %bits)
        \\  %a0 = load i64, ptr %a, align 8
        \\  %b0 = load i64, ptr %b, align 8
        \\  %lt = icmp ult i64 %a0, %b0
        \\  br i1 %lt, label %ret_neg, label %ret_zero
        \\
        \\ret_neg:
        \\  ret i8 -1
        \\ret_zero:
        \\  ret i8 0
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

test "generic cfg selector emits limb64 overflow envelopes through opt-in selector" {
    const cases = [_]struct {
        unsigned_op: []const u8,
        signed_op: []const u8,
        expected: codegen.x86_64.Instruction,
    }{
        .{
            .unsigned_op = "uadd",
            .signed_op = "sadd",
            .expected = .{ .overflow_limb64_rdi_rsi_rdx_cl_r8w_al = .add },
        },
        .{
            .unsigned_op = "usub",
            .signed_op = "ssub",
            .expected = .{ .overflow_limb64_rdi_rsi_rdx_cl_r8w_al = .sub },
        },
    };

    for (cases) |case| {
        const text = try std.fmt.allocPrint(std.testing.allocator,
            \\target triple = "x86_64-unknown-linux-gnu"
            \\
            \\define i1 @candidate(ptr %out, ptr %a, ptr %b, i1 %signed, i16 %bits) {{
            \\entry:
            \\  %slot = alloca i8, align 1
            \\  store i8 0, ptr %slot, align 1
            \\  %is_zero = icmp eq i16 %bits, 0
            \\  %minus_one = add i16 %bits, -1
            \\  %last = lshr i16 %minus_one, 6
            \\  %nraw = add i16 %last, 1
            \\  %nlimbs = select i1 %is_zero, i16 0, i16 %nraw
            \\  %bytes = call fastcc i16 @zig.target.intByteSize(i16 %bits)
            \\  %nlimbs64 = zext i16 %nlimbs to i64
            \\  %last_index = add i16 %nlimbs, -1
            \\  %last64 = zext i16 %last_index to i64
            \\  %a0p = getelementptr inbounds nuw [8 x i8], ptr %a, i64 0
            \\  %a0 = load i64, ptr %a0p, align 8
            \\  %b0p = getelementptr inbounds nuw [8 x i8], ptr %b, i64 0
            \\  %b0 = load i64, ptr %b0p, align 8
            \\  %lo0 = call {{ i64, i1 }} @llvm.{s}.with.overflow.i64(i64 %a0, i64 %b0)
            \\  %lo0v = extractvalue {{ i64, i1 }} %lo0, 0
            \\  %lo0o = extractvalue {{ i64, i1 }} %lo0, 1
            \\  %carry0 = zext i1 %lo0o to i64
            \\  %lo1 = call {{ i64, i1 }} @llvm.{s}.with.overflow.i64(i64 %lo0v, i64 %carry0)
            \\  %lo1v = extractvalue {{ i64, i1 }} %lo1, 0
            \\  store i64 %lo1v, ptr %out, align 8
            \\  %ap = getelementptr inbounds nuw [8 x i8], ptr %a, i64 %last64
            \\  %av = load i64, ptr %ap, align 8
            \\  %bp = getelementptr inbounds nuw [8 x i8], ptr %b, i64 %last64
            \\  %bv = load i64, ptr %bp, align 8
            \\  br i1 %signed, label %signed_final, label %unsigned_final
            \\
            \\unsigned_final:
            \\  %u0 = call {{ i64, i1 }} @llvm.{s}.with.overflow.i64(i64 %av, i64 %bv)
            \\  %u0v = extractvalue {{ i64, i1 }} %u0, 0
            \\  %u0o = extractvalue {{ i64, i1 }} %u0, 1
            \\  %ucarry = zext i1 %u0o to i64
            \\  %u1 = call {{ i64, i1 }} @llvm.{s}.with.overflow.i64(i64 %u0v, i64 %ucarry)
            \\  %uv = extractvalue {{ i64, i1 }} %u1, 0
            \\  br label %wrap
            \\
            \\signed_final:
            \\  %s0 = call {{ i64, i1 }} @llvm.{s}.with.overflow.i64(i64 %av, i64 %bv)
            \\  %s0v = extractvalue {{ i64, i1 }} %s0, 0
            \\  %s0o = extractvalue {{ i64, i1 }} %s0, 1
            \\  %scarry = zext i1 %s0o to i64
            \\  %s1 = call {{ i64, i1 }} @llvm.{s}.with.overflow.i64(i64 %s0v, i64 %scarry)
            \\  %sv = extractvalue {{ i64, i1 }} %s1, 0
            \\  br label %wrap
            \\
            \\wrap:
            \\  %result = phi i64 [ %uv, %unsigned_final ], [ %sv, %signed_final ]
            \\  %rem = and i16 %bits, 63
            \\  %rem64 = zext i16 %rem to i64
            \\  %shifted = shl i64 %result, %rem64
            \\  %wrapped = ashr i64 %shifted, %rem64
            \\  %fill = sub i64 %nlimbs64, %last64
            \\  %outp = getelementptr inbounds nuw [8 x i8], ptr %out, i64 %fill
            \\  store i64 %wrapped, ptr %outp, align 8
            \\  %overflow = icmp ne i64 %wrapped, %result
            \\  ret i1 %overflow
            \\}}
            \\
        , .{
            case.unsigned_op,
            case.unsigned_op,
            case.unsigned_op,
            case.unsigned_op,
            case.signed_op,
            case.signed_op,
        });
        defer std.testing.allocator.free(text);

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
        try std.testing.expectEqual(case.expected, machine.instructions.items[0]);
    }
}

test "generic cfg selector keeps limb64 overflow near miss fail-closed" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define i1 @near_miss(ptr %out, ptr %a, ptr %b, i1 %signed, i16 %bits) {
        \\entry:
        \\  %is_zero = icmp eq i16 %bits, 0
        \\  %minus_one = add i16 %bits, -1
        \\  %last = lshr i16 %minus_one, 6
        \\  %nraw = add i16 %last, 1
        \\  %nlimbs = select i1 %is_zero, i16 0, i16 %nraw
        \\  %bytes = call fastcc i16 @zig.target.intByteSize(i16 %bits)
        \\  %a0 = load i64, ptr %a, align 8
        \\  %b0 = load i64, ptr %b, align 8
        \\  %sum = call { i64, i1 } @llvm.uadd.with.overflow.i64(i64 %a0, i64 %b0)
        \\  %sumv = extractvalue { i64, i1 } %sum, 0
        \\  store i64 %sumv, ptr %out, align 8
        \\  ret i1 false
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

test "generic cfg selector composes stack out-param direct call and i64 return" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare i64 @callee(i64, i64, ptr)
        \\
        \\define i64 @stack_call(i64 %a, i64 %b) {
        \\entry:
        \\  %slot = alloca i64, align 8
        \\  %unused = call i64 @callee(i64 %a, i64 %b, ptr %slot)
        \\  %rem = load i64, ptr %slot, align 8
        \\  ret i64 %rem
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    var machine = codegen.x86_64.MachineFunction.init("stack_call", module.functions.items[0].ret_ty);
    defer machine.deinit(std.testing.allocator);

    const result = try selector.tryLower(std.testing.allocator, &machine, module.functions.items[0]);
    switch (result) {
        .selected => {},
        .unsupported => |diagnostic| return std.testing.expectEqualStrings("selected", diagnostic.tagName()),
    }

    try std.testing.expectEqual(@as(usize, 6), machine.instructions.items.len);
    try std.testing.expectEqual(codegen.x86_64.Instruction.sub_rsp_24, machine.instructions.items[0]);
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .mov_rsp_arg64 = .rdx }, machine.instructions.items[1]);
    try std.testing.expectEqualStrings("callee", machine.instructions.items[2].direct_call.symbol);
    try std.testing.expect(machine.instructions.items[2].direct_call.ret_ty.eql(.{ .int = 64 }));
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .load_stack_disp8_rax = 0 }, machine.instructions.items[3]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.add_rsp_24, machine.instructions.items[4]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[5]);
}

test "generic cfg selector composes i128 stack out-param direct call wrapper" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare fastcc i128 @callee(i128, i128, ptr)
        \\
        \\define i128 @stack_call(i128 %a, i128 %b) {
        \\entry:
        \\  %slot = alloca i128, align 16
        \\  %unused = call fastcc i128 @callee(i128 %a, i128 %b, ptr %slot)
        \\  %rem = load i128, ptr %slot, align 16
        \\  ret i128 %rem
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    var machine = codegen.x86_64.MachineFunction.init("stack_call", module.functions.items[0].ret_ty);
    defer machine.deinit(std.testing.allocator);

    const result = try selector.tryLower(std.testing.allocator, &machine, module.functions.items[0]);
    switch (result) {
        .selected => {},
        .unsupported => |diagnostic| return std.testing.expectEqualStrings("selected", diagnostic.tagName()),
    }

    try std.testing.expectEqual(codegen.x86_64.Instruction{ .sub_rsp_imm32 = 328 }, machine.instructions.items[0]);
    try expectInstruction(machine.instructions.items, .{ .mov_rsp_arg64 = .r8 });
    try expectInstruction(machine.instructions.items, .{ .add_arg64_imm32 = .{ .reg = .r8, .imm = 272 } });
    try expectInstruction(machine.instructions.items, .{ .load_stack_disp32_arg64 = .{ .reg = .rdx, .disp = 280 } });
    try expectInstruction(machine.instructions.items, .{ .load_stack_disp32_rax = 272 });
    try std.testing.expectEqual(codegen.x86_64.Instruction{ .add_rsp_imm32 = 328 }, machine.instructions.items[machine.instructions.items.len - 2]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[machine.instructions.items.len - 1]);
}

test "generic cfg selector composes signed i128 remainder stack call with pair spills" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare i128 @llvm.abs.i128(i128, i1)
        \\declare fastcc i128 @udivmod(i128, i128, ptr)
        \\
        \\define i128 @signed_rem(i128 %a, i128 %b) {
        \\entry:
        \\  %slot = alloca i128, align 16
        \\  %sign = ashr i128 %a, 127
        \\  %xor0 = xor i128 %sign, %a
        \\  %mag_a = sub i128 %xor0, %sign
        \\  %mag_b = tail call i128 @llvm.abs.i128(i128 %b, i1 false)
        \\  %unused = call fastcc i128 @udivmod(i128 %mag_a, i128 %mag_b, ptr %slot)
        \\  %rem = load i128, ptr %slot, align 16
        \\  %xor1 = xor i128 %rem, %sign
        \\  %signed = sub i128 %xor1, %sign
        \\  ret i128 %signed
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    var machine = codegen.x86_64.MachineFunction.init("signed_rem", module.functions.items[0].ret_ty);
    defer machine.deinit(std.testing.allocator);

    const result = try selector.tryLower(std.testing.allocator, &machine, module.functions.items[0]);
    switch (result) {
        .selected => {},
        .unsupported => |diagnostic| {
            std.debug.print("unexpected selector diagnostic {s}: {s}\n", .{ diagnostic.tagName(), diagnostic.detail() });
            return std.testing.expectEqualStrings("selected", diagnostic.tagName());
        },
    }

    try std.testing.expectEqual(codegen.x86_64.Instruction{ .sub_rsp_imm32 = 360 }, machine.instructions.items[0]);
    try expectInstruction(machine.instructions.items, .{ .sar_arg64_imm6 = .{ .reg = .rcx, .amount = 63 } });
    try expectInstruction(machine.instructions.items, .{ .spill_arg64_rsp = .{ .frame_index = .slot0, .reg = .rcx } });
    try expectInstruction(machine.instructions.items, .{ .spill_arg64_rsp = .{ .frame_index = .slot2, .reg = .rdx } });
    try expectInstruction(machine.instructions.items, .{ .sbb_arg64_rax = .rdx });
    try expectInstruction(machine.instructions.items, .{ .mov_rsp_arg64 = .r8 });
    try expectInstruction(machine.instructions.items, .{ .add_arg64_imm32 = .{ .reg = .r8, .imm = 304 } });
    try expectInstruction(machine.instructions.items, .{ .load_stack_disp32_arg64 = .{ .reg = .rdx, .disp = 312 } });
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[machine.instructions.items.len - 1]);
}

test "generic cfg selector composes signed i64 remainder stack call with spills" {
    const text =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\declare i64 @llvm.abs.i64(i64, i1)
        \\declare i64 @udivmod(i64, i64, ptr)
        \\
        \\define i64 @signed_rem(i64 %a, i64 %b) {
        \\entry:
        \\  %slot = alloca i64, align 8
        \\  %sign = ashr i64 %a, 63
        \\  %xor0 = xor i64 %sign, %a
        \\  %mag_a = sub i64 %xor0, %sign
        \\  %mag_b = tail call i64 @llvm.abs.i64(i64 %b, i1 false)
        \\  %unused = call i64 @udivmod(i64 %mag_a, i64 %mag_b, ptr %slot)
        \\  %rem = load i64, ptr %slot, align 8
        \\  %xor1 = xor i64 %rem, %sign
        \\  %signed = sub i64 %xor1, %sign
        \\  ret i64 %signed
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();

    var machine = codegen.x86_64.MachineFunction.init("signed_rem", module.functions.items[0].ret_ty);
    defer machine.deinit(std.testing.allocator);

    const result = try selector.tryLower(std.testing.allocator, &machine, module.functions.items[0]);
    switch (result) {
        .selected => {},
        .unsupported => |diagnostic| {
            std.debug.print("unexpected selector diagnostic {s}: {s}\n", .{ diagnostic.tagName(), diagnostic.detail() });
            return std.testing.expectEqualStrings("selected", diagnostic.tagName());
        },
    }

    try std.testing.expectEqual(codegen.x86_64.Instruction.sub_rsp_24, machine.instructions.items[0]);
    try expectInstruction(machine.instructions.items, .{ .sar_arg64_imm6 = .{ .reg = .rcx, .amount = 63 } });
    try expectInstruction(machine.instructions.items, .{ .spill_arg64_rsp = .{ .frame_index = .slot0, .reg = .rcx } });
    try expectInstruction(machine.instructions.items, .{ .spill_rax_rsp = .slot2 });
    try expectInstruction(machine.instructions.items, .abs_i64_rdi_rax);
    try expectInstruction(machine.instructions.items, .{ .reload_arg64_rsp = .{ .reg = .rdi, .frame_index = .slot2 } });
    var saw_rsi_materialization = false;
    for (machine.instructions.items) |instruction| switch (instruction) {
        .mov_rax_to_arg => |reg| if (reg == .rsi) {
            saw_rsi_materialization = true;
        },
        .reload_arg64_rsp => |reload| if (reload.reg == .rsi) {
            saw_rsi_materialization = true;
        },
        else => {},
    };
    try std.testing.expect(saw_rsi_materialization);
    try expectInstruction(machine.instructions.items, .{ .mov_rsp_arg64 = .rdx });
    try expectInstruction(machine.instructions.items, .{ .load_stack_disp8_rax = 0 });
    try std.testing.expectEqual(codegen.x86_64.Instruction.add_rsp_24, machine.instructions.items[machine.instructions.items.len - 2]);
    try std.testing.expectEqual(codegen.x86_64.Instruction.ret, machine.instructions.items[machine.instructions.items.len - 1]);
}

test "generic cfg selector skeleton admits supported scalar float addition" {
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
    try std.testing.expectEqualStrings("no_emitter", diagnostic.tagName());
    try std.testing.expectEqualStrings("selector-skeleton-has-no-emitters", diagnostic.detail());
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
