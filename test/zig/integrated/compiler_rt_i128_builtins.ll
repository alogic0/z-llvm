source_filename = "compiler_rt_i128_builtins"
target datalayout = "e-m:e-p270:32:32-p271:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i128 @llvm.abs.i128(i128, i1)
declare i32 @llvm.ctlz.i32(i32, i1 immarg)
declare i128 @compiler_rt.udivmod.udivmod__anon_15304(i128, i128, ptr)

define dso_local i32 @zllvm_ne_zero_i16(i32 %value) {
Entry:
  %narrow = trunc i32 %value to i16
  %not_zero = icmp ne i16 %narrow, 0
  %result = zext i1 %not_zero to i32
  ret i32 %result
}

define dso_local i32 @zllvm_store_i32_index(ptr %base, i64 %index, i32 %value) {
Entry:
  %element = getelementptr [4 x i8], ptr %base, i64 %index
  store i32 %value, ptr %element, align 4
  ret i32 %value
}

define dso_local i32 @zllvm_load_i32_index(ptr %base, i64 %index) {
Entry:
  %element = getelementptr [4 x i8], ptr %base, i64 %index
  %value = load i32, ptr %element, align 4
  ret i32 %value
}

define dso_local i32 @zllvm_ptr_eq(ptr %lhs, ptr %rhs) {
Entry:
  %equal = icmp eq ptr %lhs, %rhs
  %result = zext i1 %equal to i32
  ret i32 %result
}

define dso_local i32 @zllvm_load_i32_spilled_ptr(ptr %base) {
Entry:
  %p1 = getelementptr i8, ptr %base, i64 0
  %p2 = getelementptr i8, ptr %base, i64 4
  %p3 = getelementptr i8, ptr %base, i64 8
  %p4 = getelementptr i8, ptr %base, i64 12
  %p5 = getelementptr i8, ptr %base, i64 16
  %p6 = getelementptr i8, ptr %base, i64 20
  %spilled = getelementptr i8, ptr %base, i64 24
  %value = load i32, ptr %spilled, align 4
  %eq1 = icmp eq ptr %p1, %p1
  %eq2 = icmp eq ptr %p2, %p2
  %eq3 = icmp eq ptr %p3, %p3
  %eq4 = icmp eq ptr %p4, %p4
  %eq5 = icmp eq ptr %p5, %p5
  %eq6 = icmp eq ptr %p6, %p6
  %v1 = zext i1 %eq1 to i32
  %v2 = zext i1 %eq2 to i32
  %v3 = zext i1 %eq3 to i32
  %v4 = zext i1 %eq4 to i32
  %v5 = zext i1 %eq5 to i32
  %v6 = zext i1 %eq6 to i32
  %sum1 = add i32 %value, %v1
  %sum2 = add i32 %sum1, %v2
  %sum3 = add i32 %sum2, %v3
  %sum4 = add i32 %sum3, %v4
  %sum5 = add i32 %sum4, %v5
  %result = add i32 %sum5, %v6
  ret i32 %result
}

define dso_local i32 @zllvm_store_i32_spilled_ptr(ptr %base, i32 %value) {
Entry:
  %p1 = getelementptr i8, ptr %base, i64 0
  %p2 = getelementptr i8, ptr %base, i64 4
  %p3 = getelementptr i8, ptr %base, i64 8
  %p4 = getelementptr i8, ptr %base, i64 12
  %p5 = getelementptr i8, ptr %base, i64 16
  %p6 = getelementptr i8, ptr %base, i64 20
  %spilled = getelementptr i8, ptr %base, i64 24
  store i32 %value, ptr %spilled, align 4
  %eq1 = icmp eq ptr %p1, %p1
  %eq2 = icmp eq ptr %p2, %p2
  %eq3 = icmp eq ptr %p3, %p3
  %eq4 = icmp eq ptr %p4, %p4
  %eq5 = icmp eq ptr %p5, %p5
  %eq6 = icmp eq ptr %p6, %p6
  %loaded = load i32, ptr %spilled, align 4
  %v1 = zext i1 %eq1 to i32
  %v2 = zext i1 %eq2 to i32
  %v3 = zext i1 %eq3 to i32
  %v4 = zext i1 %eq4 to i32
  %v5 = zext i1 %eq5 to i32
  %v6 = zext i1 %eq6 to i32
  %sum1 = add i32 %loaded, %v1
  %sum2 = add i32 %sum1, %v2
  %sum3 = add i32 %sum2, %v3
  %sum4 = add i32 %sum3, %v4
  %sum5 = add i32 %sum4, %v5
  %result = add i32 %sum5, %v6
  ret i32 %result
}

define dso_local i32 @zllvm_store_array_base(i32 %value) {
Entry:
  %slot = alloca [3 x i32], align 4
  store i32 %value, ptr %slot, align 4
  %base = getelementptr [3 x i32], ptr %slot, i64 0, i64 0
  %loaded = load i32, ptr %base, align 4
  ret i32 %loaded
}

define dso_local i32 @zllvm_select_shifted(i32 %value, i32 %amount, i32 %flag) {
Entry:
  %slot = alloca [1 x i32], align 4
  %cond = icmp eq i32 %flag, 0
  %shifted = shl i32 %value, %amount
  %result = select i1 %cond, i32 %shifted, i32 0
  store i32 %result, ptr %slot, align 4
  ret i32 %result
}

define dso_local i64 @zllvm_or_i64_imm(i64 %value) {
Entry:
  %result = or i64 %value, 1
  ret i64 %result
}

define dso_local i32 @zllvm_stack_index_dependency(i64 %base_index, i32 %value, i32 %amount) {
Entry:
  %slot = alloca [3 x i32], align 4
  store i32 11, ptr %slot, align 4
  %index = add i64 %base_index, 1
  %ptr = getelementptr [4 x i8], ptr %slot, i64 %index
  %shifted = shl i32 %value, %amount
  store i32 %shifted, ptr %ptr, align 4
  %base = getelementptr [3 x i32], ptr %slot, i64 0, i64 0
  %loaded = load i32, ptr %base, align 4
  ret i32 %loaded
}

define dso_local i32 @zllvm_backward_layout_phi(i32 %value) {
Entry:
  br label %Later

Merge:
  %merged = phi i32 [ %next, %Later ]
  ret i32 %merged

Later:
  %next = add i32 %value, 1
  br label %Merge
}

define dso_local i32 @zllvm_ugt_i64(i64 %lhs, i64 %rhs) {
Entry:
  %greater = icmp ugt i64 %lhs, %rhs
  %result = zext i1 %greater to i32
  ret i32 %result
}

define dso_local i32 @zllvm_ugt_i64_imm(i64 %value) {
Entry:
  %greater = icmp ugt i64 %value, 4294967295
  %result = zext i1 %greater to i32
  ret i32 %result
}

define dso_local i32 @zllvm_nonnegative_i6(i32 %value) {
Entry:
  %narrow = trunc i32 %value to i6
  %nonnegative = icmp sgt i6 %narrow, -1
  %result = zext i1 %nonnegative to i32
  ret i32 %result
}

define dso_local i32 @zllvm_negative_i64(i64 %value) {
Entry:
  %negative = icmp slt i64 %value, 0
  %result = zext i1 %negative to i32
  ret i32 %result
}

define dso_local i32 @zllvm_ne_zero_i64(i64 %value) {
Entry:
  %not_zero = icmp ne i64 %value, 0
  %result = zext i1 %not_zero to i32
  ret i32 %result
}

define dso_local i32 @zllvm_ctlz_i32(i32 %value) {
Entry:
  %count = tail call range(i32 0, 33) i32 @llvm.ctlz.i32(i32 %value, i1 true)
  ret i32 %count
}

define dso_local i32 @zllvm_sub_i6(i32 %value) {
Entry:
  %narrow = trunc i32 %value to i6
  %difference = sub i6 -32, %narrow
  %result = zext i6 %difference to i32
  ret i32 %result
}

define dso_local i32 @zllvm_spilled_cond(i32 %value) {
Entry:
  %v1 = add i32 %value, 1
  %v2 = add i32 %value, 2
  %v3 = add i32 %value, 3
  %v4 = add i32 %value, 4
  %v5 = add i32 %value, 5
  %v6 = add i32 %value, 6
  %cond = icmp eq i32 %value, 0
  %extra = add i32 %v1, %v2
  br i1 %cond, label %Done, label %Then
Then:
  %s2 = add i32 %extra, %v3
  %s3 = add i32 %s2, %v4
  %s4 = add i32 %s3, %v5
  %s5 = add i32 %s4, %v6
  br label %Merge
Done:
  br label %Merge
Merge:
  %result = phi i32 [ %s5, %Then ], [ 0, %Done ]
  ret i32 %result
}

define dso_local i32 @zllvm_variable_shl_i32(i32 %value, i32 %amount) {
Entry:
  %result = shl i32 %value, %amount
  ret i32 %result
}

define dso_local i32 @zllvm_variable_lshr_i32(i32 %value, i32 %amount) {
Entry:
  %result = lshr i32 %value, %amount
  ret i32 %result
}

define dso_local i32 @zllvm_stack_byte_gep(i64 %index, i32 %value) {
Entry:
  %slot = alloca [3 x i32], align 4
  %base = getelementptr inbounds [3 x i32], ptr %slot, i64 0, i64 %index
  store i32 11, ptr %base, align 4
  %next = getelementptr i8, ptr %base, i64 4
  store i32 %value, ptr %next, align 4
  %base_value = load i32, ptr %base, align 4
  ret i32 %base_value
}

define dso_local i32 @zllvm_stack_chained_gep(i64 %base_index, i64 %offset, i32 %value) {
Entry:
  %slot = alloca [4 x i32], align 4
  %base = getelementptr inbounds [4 x i32], ptr %slot, i64 0, i64 %base_index
  store i32 11, ptr %base, align 4
  %next = getelementptr [4 x i8], ptr %base, i64 %offset
  store i32 %value, ptr %next, align 4
  %base_value = load i32, ptr %base, align 4
  ret i32 %base_value
}

define dso_local i32 @zllvm_stack_element_gep(i64 %index, i32 %value) {
Entry:
  %slot = alloca [4 x i32], align 4
  %base = getelementptr [4 x i32], ptr %slot, i64 0, i64 0
  store i32 11, ptr %base, align 4
  %element = getelementptr [4 x i8], ptr %slot, i64 %index
  store i32 %value, ptr %element, align 4
  %base_value = load i32, ptr %base, align 4
  ret i32 %base_value
}

define dso_local i64 @zllvm_spilled_phi(i64 %limit, i32 %value, i32 %amount) {
Entry:
  br label %Loop
Loop:
  %acc = phi i64 [ 1, %Entry ], [ %next_acc, %Body ]
  %carry = phi i64 [ 2, %Entry ], [ %next_carry, %Body ]
  %index = phi i64 [ 0, %Entry ], [ %next_index, %Body ]
  %done = icmp eq i64 %index, %limit
  br i1 %done, label %Exit, label %Body
Body:
  %shifted = shl i32 %value, %amount
  %wide = zext i32 %shifted to i64
  %next_acc = add i64 %acc, %wide
  %next_carry = add i64 %carry, 1
  %next_index = add i64 %index, 1
  br label %Loop
Exit:
  ret i64 %acc
}

define dso_local i128 @__modti3(i128 %0, i128 %1) {
Entry:
  %2 = alloca i128, align 16
  %3 = ashr i128 %0, 127
  %4 = xor i128 %3, %0
  %5 = sub i128 %4, %3
  %6 = tail call i128 @llvm.abs.i128(i128 %1, i1 false)
  %7 = call i128 @compiler_rt.udivmod.udivmod__anon_15304(i128 %5, i128 %6, ptr nonnull align 16 %2)
  %8 = load i128, ptr %2, align 16
  %9 = xor i128 %8, %3
  %10 = sub i128 %9, %3
  ret i128 %10
}

define dso_local i128 @__multi3(i128 %0, i128 %1) {
Entry:
  %.sroa.01.0.extract.trunc = trunc i128 %0 to i64
  %.sroa.3.0.extract.shift = lshr i128 %0, 64
  %.sroa.3.0.extract.trunc = trunc nuw i128 %.sroa.3.0.extract.shift to i64
  %.sroa.04.0.extract.trunc = trunc i128 %1 to i64
  %.sroa.36.0.extract.shift = lshr i128 %1, 64
  %.sroa.36.0.extract.trunc = trunc nuw i128 %.sroa.36.0.extract.shift to i64
  %2 = and i64 %.sroa.01.0.extract.trunc, 4294967295
  %3 = and i64 %.sroa.04.0.extract.trunc, 4294967295
  %4 = mul nuw i64 %3, %2
  %5 = lshr i64 %4, 32
  %6 = and i64 %4, 4294967295
  %7 = lshr i64 %.sroa.01.0.extract.trunc, 32
  %8 = mul nuw i64 %3, %7
  %9 = add nuw i64 %5, %8
  %10 = lshr i64 %9, 32
  %11 = and i64 %9, 4294967295
  %12 = lshr i64 %.sroa.04.0.extract.trunc, 32
  %13 = mul nuw i64 %12, %2
  %14 = add nuw i64 %11, %13
  %15 = shl i64 %14, 32
  %16 = or disjoint i64 %15, %6
  %17 = lshr i64 %14, 32
  %18 = mul nuw i64 %12, %7
  %.sroa.0.0.insert.ext.i = zext i64 %16 to i128
  %19 = mul i64 %.sroa.3.0.extract.trunc, %.sroa.04.0.extract.trunc
  %20 = mul i64 %.sroa.36.0.extract.trunc, %.sroa.01.0.extract.trunc
  %21 = add i64 %20, %19
  %22 = add i64 %21, %18
  %23 = add i64 %22, %10
  %24 = add i64 %23, %17
  %.sroa.2.0.insert.ext = zext i64 %24 to i128
  %.sroa.2.0.insert.shift = shl nuw i128 %.sroa.2.0.insert.ext, 64
  %.sroa.07.0.insert.insert = or disjoint i128 %.sroa.2.0.insert.shift, %.sroa.0.0.insert.ext.i
  ret i128 %.sroa.07.0.insert.insert
}
