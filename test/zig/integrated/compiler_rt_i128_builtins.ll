source_filename = "compiler_rt_i128_builtins"
target datalayout = "e-m:e-p270:32:32-p271:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i128 @llvm.abs.i128(i128, i1)
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
