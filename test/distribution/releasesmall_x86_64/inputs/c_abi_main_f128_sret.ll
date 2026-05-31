target triple = "x86_64-unknown-linux-gnu"

%main.f128_f128_struct = type { fp128, fp128 }
%main.PD = type { ptr, double }
%Io.LockedStderr = type { ptr }
%main.BigStruct = type { i64, i64, i64, i64, i8, [7 x i8] }
%main.BigUnion = type { %main.BigStruct }

@__zllvm_f128_cmp0 = private unnamed_addr constant fp128 0xL00000000000000004002A00000000000, align 16
@__zllvm_f128_cmp1 = private unnamed_addr constant fp128 0xL00000000000000004004C80000000000, align 16
@__zllvm_f128_ret0 = private unnamed_addr constant fp128 0xL00000000000000004003800000000000, align 16
@__zllvm_f128_ret1 = private unnamed_addr constant fp128 0xL00000000000000004005100000000000, align 16
@__zllvm_f128_struct_cmp0 = private unnamed_addr constant fp128 0xL0000000000000000400C81C800000000, align 16
@__zllvm_f128_struct_ret0 = private unnamed_addr constant fp128 0xL0000000000000000400F81CD00000000, align 16
@__zllvm_f128_scalar_cmp0 = private unnamed_addr constant fp128 0xL00000000000000004002800000000000, align 16
@__zllvm_f128_scalar_ret0 = private unnamed_addr constant fp128 0xL00000000000000004004100000000000, align 16
@__anon_762 = private unnamed_addr constant [13 x i8] c"test failure\00", align 1
@__anon_15510 = private unnamed_addr constant %main.BigStruct { i64 20, i64 21, i64 22, i64 23, i8 24, [7 x i8] undef }, align 8
@zig_f128_f128_struct = alias void (ptr, ptr), ptr @main.zig_f128_f128_struct
@zig_f128_struct = alias { fp128 } (fp128), ptr @main.zig_f128_struct
@zig_f128 = alias fp128 (fp128), ptr @main.zig_f128
@zig_assert_PD = alias i32 (i64, double), ptr @main.zig_assert_PD
@zig_ret_PD = alias { i64, double } (), ptr @main.zig_ret_PD
@zig_ret_CFF = alias { i64, float } (), ptr @main.zig_ret_CFF
@zig_assert_CFF = alias i32 (i64, float), ptr @main.zig_assert_CFF
@zig_ret_DC = alias { double, i64 } (), ptr @main.zig_ret_DC
@zig_assert_DC = alias i32 (double, i64), ptr @main.zig_assert_DC
@zig_ret_split_struct_mixed = alias { i64, i64 } (), ptr @main.zig_ret_split_struct_mixed
@zig_ret_med_struct_mixed = alias { i64, i64 } (), ptr @main.zig_ret_med_struct_mixed
@zig_ret_med_struct_ints = alias { i64, i32 } (), ptr @main.zig_ret_med_struct_ints
@zig_ret_i64 = alias i64 (), ptr @main.zig_ret_i64
@zig_ret_i16 = alias i16 (), ptr @main.zig_ret_i16
@zig_ret_i8 = alias i8 (), ptr @main.zig_ret_i8
@zig_ret_u16 = alias i16 (), ptr @main.zig_ret_u16
@zig_ret_u8 = alias i8 (), ptr @main.zig_ret_u8
@zig_ret_bool = alias i1 (), ptr @main.zig_ret_bool
@zig_multiple_struct_floats = alias void (<2 x float>, <2 x float>, <2 x float>, <2 x float>), ptr @main.zig_multiple_struct_floats
@zig_multiple_struct_ints = alias void (i64, i64, i64, i64), ptr @main.zig_multiple_struct_ints
@zig_big_struct_both = alias void (ptr, ptr), ptr @main.zig_big_struct_both
@zig_split_struct_mixed = alias void (i64, i64), ptr @main.zig_split_struct_mixed
@zig_split_struct_ints = alias void (i64, i64), ptr @main.zig_split_struct_ints
@zig_big_packed_struct = alias void (i128), ptr @main.zig_big_packed_struct
@zig_small_packed_struct = alias void (i8), ptr @main.zig_small_packed_struct
@zig_med_struct_ints = alias void (i64, i32), ptr @main.zig_med_struct_ints
@zig_small_struct_ints = alias void (i32), ptr @main.zig_small_struct_ints
@zig_med_struct_mixed = alias void (i64, i64), ptr @main.zig_med_struct_mixed
@zig_big_union = alias void (ptr), ptr @main.zig_big_union
@zig_big_struct = alias void (ptr), ptr @main.zig_big_struct
@zig_struct_i32_i32 = alias void (i64), ptr @main.zig_struct_i32_i32
@zig_struct_f32_f32f32 = alias void (<2 x float>, float), ptr @main.zig_struct_f32_f32f32
@zig_struct_f32f32_f32 = alias void (<2 x float>, float), ptr @main.zig_struct_f32_f32f32
@zig_ret_struct_f32_f32f32 = alias { <2 x float>, float } (), ptr @main.zig_ret_struct_f32_f32f32
@zig_ret_struct_f32f32_f32 = alias { <2 x float>, float } (), ptr @main.zig_ret_struct_f32_f32f32
@zig_struct_f32a8_f32a8 = alias void (<2 x float>, float, float), ptr @main.zig_struct_f32a8_f32a8
@zig_ret_struct_f32a8_f32a8 = alias { <2 x float>, float } (), ptr @main.zig_ret_struct_f32a8_f32a8
@zig_struct_f32a8 = alias void (float, float), ptr @main.zig_struct_f32a8
@zig_ret_struct_f32a8 = alias { float } (), ptr @main.zig_ret_struct_f32a8
@zig_struct_f64 = alias void (double), ptr @main.zig_struct_f64
@zig_ret_struct_f64 = alias { double } (), ptr @main.zig_ret_struct_f64
@zig_struct_f32 = alias void (float), ptr @main.zig_struct_f32
@zig_ret_struct_f32 = alias { float } (), ptr @main.zig_ret_struct_f32
@zig_struct_u64_u64_8 = alias void (i64, i64, i64, i64, i64, i64, i64, i64, ptr, i64), ptr @main.zig_struct_u64_u64_8
@zig_struct_u64_u64_7 = alias void (i64, i64, i64, i64, i64, i64, i64, ptr, i64), ptr @main.zig_struct_u64_u64_7
@zig_struct_u64_u64_6 = alias void (i64, i64, i64, i64, i64, i64, ptr, i64), ptr @main.zig_struct_u64_u64_6
@zig_struct_u64_u64_5 = alias void (i64, i64, i64, i64, i64, ptr, i64), ptr @main.zig_struct_u64_u64_5
@zig_struct_u64_u64_4 = alias void (i64, i64, i64, i64, i64, i64, i64), ptr @main.zig_struct_u64_u64_4
@zig_struct_u64_u64_3 = alias void (i64, i64, i64, i64, i64, i64), ptr @main.zig_struct_u64_u64_3
@zig_struct_u64_u64_2 = alias void (i64, i64, i64, i64, i64), ptr @main.zig_struct_u64_u64_2
@zig_struct_u64_u64_1 = alias void (i64, i64, i64, i64), ptr @main.zig_struct_u64_u64_1

declare i32 @__eqtf2(fp128, fp128)
declare fastcc void @debug.defaultPanic(ptr, i64)
declare fastcc void @debug.print__anon_14634(ptr)
declare void @llvm.memcpy.p0.p0.i64(ptr, ptr, i64, i1)

define private void @main.zig_f128_f128_struct(ptr noalias nonnull writeonly sret(%main.f128_f128_struct) captures(none) %0, ptr nonnull readonly byval(%main.f128_f128_struct) align 16 captures(none) %1) unnamed_addr align 1 {
2:
  %.sroa.0.0.copyload = load fp128, ptr %1, align 16
  %.sroa.2.0..sroa_idx = getelementptr i8, ptr %1, i64 16
  %.sroa.2.0.copyload = load fp128, ptr %.sroa.2.0..sroa_idx, align 16
  %3 = tail call i32 @__eqtf2(fp128 %.sroa.0.0.copyload, fp128 0xL00000000000000004002A00000000000)
  %4 = icmp eq i32 %3, 0
  br i1 %4, label %5, label %8
5:
  %6 = tail call i32 @__eqtf2(fp128 %.sroa.2.0.copyload, fp128 0xL00000000000000004004C80000000000)
  %7 = icmp eq i32 %6, 0
  br i1 %7, label %9, label %11
8:
  tail call fastcc void @debug.defaultPanic(ptr nonnull readonly @__anon_762, i64 12)
  unreachable
9:
  store fp128 0xL00000000000000004003800000000000, ptr %0, align 16
  %10 = getelementptr i8, ptr %0, i64 16
  store fp128 0xL00000000000000004005100000000000, ptr %10, align 16
  ret void
11:
  tail call fastcc void @debug.defaultPanic(ptr nonnull readonly @__anon_762, i64 12)
  unreachable
}

define private { <2 x float>, float } @main.zig_ret_struct_f32_f32f32() unnamed_addr align 1 {
0:
  ret { <2 x float>, float } { <2 x float> <float 1.000000e+00, float 2.000000e+00>, float 3.000000e+00 }
}

define private void @main.zig_struct_f32a8_f32a8(<2 x float> %0, float %1, float %2) unnamed_addr align 1 {
3:
  %.sroa.01.0.vec.extract = extractelement <2 x float> %0, i64 0
  %4 = fcmp oeq float %.sroa.01.0.vec.extract, 3.125000e+00
  br i1 %4, label %5, label %7
5:
  %6 = fcmp oeq float %1, 4.375000e+00
  br i1 %6, label %8, label %10
7:
  tail call fastcc void @debug.defaultPanic(ptr nonnull readonly @__anon_762, i64 12)
  unreachable
8:
  %9 = fcmp oeq float %2, 5.500000e+00
  br i1 %9, label %11, label %12
10:
  tail call fastcc void @debug.defaultPanic(ptr nonnull readonly @__anon_762, i64 12)
  unreachable
11:
  ret void
12:
  tail call fastcc void @debug.defaultPanic(ptr nonnull readonly @__anon_762, i64 12)
  unreachable
}

define private { <2 x float>, float } @main.zig_ret_struct_f32a8_f32a8() unnamed_addr align 1 {
0:
  ret { <2 x float>, float } { <2 x float> <float 1.250000e+00, float undef>, float 2.750000e+00 }
}

define private void @main.zig_struct_f32a8(float %0, float %1) unnamed_addr align 1 {
2:
  %3 = fcmp oeq float %0, 2.750000e+00
  br i1 %3, label %4, label %6
4:
  %5 = fcmp oeq float %1, 3.500000e+00
  br i1 %5, label %7, label %8
6:
  tail call fastcc void @debug.defaultPanic(ptr nonnull readonly @__anon_762, i64 12)
  unreachable
7:
  ret void
8:
  tail call fastcc void @debug.defaultPanic(ptr nonnull readonly @__anon_762, i64 12)
  unreachable
}

define private { float } @main.zig_ret_struct_f32a8() unnamed_addr align 1 {
0:
  ret { float } { float 1.250000e+00 }
}

define private void @main.zig_struct_f64(double %0) unnamed_addr align 1 {
1:
  %2 = fcmp oeq double %0, 2.500000e+00
  br i1 %2, label %3, label %4
3:
  ret void
4:
  tail call fastcc void @debug.defaultPanic(ptr nonnull readonly @__anon_762, i64 12)
  unreachable
}

define private { double } @main.zig_ret_struct_f64() unnamed_addr align 1 {
0:
  ret { double } { double 2.500000e+00 }
}

define private void @main.zig_struct_f32(float %0) unnamed_addr align 1 {
1:
  %2 = fcmp oeq float %0, 2.500000e+00
  br i1 %2, label %3, label %4
3:
  ret void
4:
  tail call fastcc void @debug.defaultPanic(ptr nonnull readonly @__anon_762, i64 12)
  unreachable
}

define private { float } @main.zig_ret_struct_f32() unnamed_addr align 1 {
0:
  ret { float } { float 2.500000e+00 }
}

define private void @main.zig_struct_u64_u64_8(i64 %0, i64 %1, i64 %2, i64 %3, i64 %4, i64 %5, i64 %6, i64 %7, ptr nonnull readonly byval(%main.Struct_u64_u64) align 8 captures(none) %8, i64 %9) unnamed_addr align 1 {
10:
  %.sroa.0.0.copyload = load i64, ptr %8, align 8
  %11 = icmp eq i64 %.sroa.0.0.copyload, 19
  br i1 %11, label %12, label %14
12:
  %.sroa.2.0..sroa_idx = getelementptr i8, ptr %8, i64 8
  %.sroa.2.0.copyload = load i64, ptr %.sroa.2.0..sroa_idx, align 8
  %13 = icmp eq i64 %.sroa.2.0.copyload, 20
  br i1 %13, label %15, label %17
14:
  tail call fastcc void @debug.defaultPanic(ptr nonnull readonly @__anon_762, i64 12)
  unreachable
15:
  %16 = icmp eq i64 %9, 9
  br i1 %16, label %18, label %19
17:
  tail call fastcc void @debug.defaultPanic(ptr nonnull readonly @__anon_762, i64 12)
  unreachable
18:
  ret void
19:
  tail call fastcc void @debug.defaultPanic(ptr nonnull readonly @__anon_762, i64 12)
  unreachable
}

define private void @main.zig_struct_u64_u64_7(i64 %0, i64 %1, i64 %2, i64 %3, i64 %4, i64 %5, i64 %6, ptr nonnull readonly byval(%main.Struct_u64_u64) align 8 captures(none) %7, i64 %8) unnamed_addr align 1 {
9:
  %.sroa.0.0.copyload = load i64, ptr %7, align 8
  %10 = icmp eq i64 %.sroa.0.0.copyload, 17
  br i1 %10, label %11, label %13
11:
  %.sroa.2.0..sroa_idx = getelementptr i8, ptr %7, i64 8
  %.sroa.2.0.copyload = load i64, ptr %.sroa.2.0..sroa_idx, align 8
  %12 = icmp eq i64 %.sroa.2.0.copyload, 18
  br i1 %12, label %14, label %16
13:
  tail call fastcc void @debug.defaultPanic(ptr nonnull readonly @__anon_762, i64 12)
  unreachable
14:
  %15 = icmp eq i64 %8, 8
  br i1 %15, label %17, label %18
16:
  tail call fastcc void @debug.defaultPanic(ptr nonnull readonly @__anon_762, i64 12)
  unreachable
17:
  ret void
18:
  tail call fastcc void @debug.defaultPanic(ptr nonnull readonly @__anon_762, i64 12)
  unreachable
}

define private void @main.zig_struct_u64_u64_6(i64 %0, i64 %1, i64 %2, i64 %3, i64 %4, i64 %5, ptr nonnull readonly byval(%main.Struct_u64_u64) align 8 captures(none) %6, i64 %7) unnamed_addr align 1 {
8:
  %.sroa.0.0.copyload = load i64, ptr %6, align 8
  %9 = icmp eq i64 %.sroa.0.0.copyload, 15
  br i1 %9, label %10, label %12
10:
  %.sroa.2.0..sroa_idx = getelementptr i8, ptr %6, i64 8
  %.sroa.2.0.copyload = load i64, ptr %.sroa.2.0..sroa_idx, align 8
  %11 = icmp eq i64 %.sroa.2.0.copyload, 16
  br i1 %11, label %13, label %15
12:
  tail call fastcc void @debug.defaultPanic(ptr nonnull readonly @__anon_762, i64 12)
  unreachable
13:
  %14 = icmp eq i64 %7, 7
  br i1 %14, label %16, label %17
15:
  tail call fastcc void @debug.defaultPanic(ptr nonnull readonly @__anon_762, i64 12)
  unreachable
16:
  ret void
17:
  tail call fastcc void @debug.defaultPanic(ptr nonnull readonly @__anon_762, i64 12)
  unreachable
}

define private void @main.zig_struct_u64_u64_5(i64 %0, i64 %1, i64 %2, i64 %3, i64 %4, ptr nonnull readonly byval(%main.Struct_u64_u64) align 8 captures(none) %5, i64 %6) unnamed_addr align 1 {
7:
  %.sroa.0.0.copyload = load i64, ptr %5, align 8
  %8 = icmp eq i64 %.sroa.0.0.copyload, 13
  br i1 %8, label %9, label %11
9:
  %.sroa.2.0..sroa_idx = getelementptr i8, ptr %5, i64 8
  %.sroa.2.0.copyload = load i64, ptr %.sroa.2.0..sroa_idx, align 8
  %10 = icmp eq i64 %.sroa.2.0.copyload, 14
  br i1 %10, label %12, label %14
11:
  tail call fastcc void @debug.defaultPanic(ptr nonnull readonly @__anon_762, i64 12)
  unreachable
12:
  %13 = icmp eq i64 %6, 6
  br i1 %13, label %15, label %16
14:
  tail call fastcc void @debug.defaultPanic(ptr nonnull readonly @__anon_762, i64 12)
  unreachable
15:
  ret void
16:
  tail call fastcc void @debug.defaultPanic(ptr nonnull readonly @__anon_762, i64 12)
  unreachable
}

define private void @main.zig_struct_u64_u64_4(i64 %0, i64 %1, i64 %2, i64 %3, i64 %4, i64 %5, i64 %6) unnamed_addr align 1 {
7:
  %8 = icmp eq i64 %4, 11
  br i1 %8, label %9, label %11
9:
  %10 = icmp eq i64 %5, 12
  br i1 %10, label %12, label %14
11:
  tail call fastcc void @debug.defaultPanic(ptr nonnull readonly @__anon_762, i64 12)
  unreachable
12:
  %13 = icmp eq i64 %6, 5
  br i1 %13, label %15, label %16
14:
  tail call fastcc void @debug.defaultPanic(ptr nonnull readonly @__anon_762, i64 12)
  unreachable
15:
  ret void
16:
  tail call fastcc void @debug.defaultPanic(ptr nonnull readonly @__anon_762, i64 12)
  unreachable
}

define private void @main.zig_struct_u64_u64_3(i64 %0, i64 %1, i64 %2, i64 %3, i64 %4, i64 %5) unnamed_addr align 1 {
6:
  %7 = icmp eq i64 %3, 9
  br i1 %7, label %8, label %10
8:
  %9 = icmp eq i64 %4, 10
  br i1 %9, label %11, label %13
10:
  tail call fastcc void @debug.defaultPanic(ptr nonnull readonly @__anon_762, i64 12)
  unreachable
11:
  %12 = icmp eq i64 %5, 4
  br i1 %12, label %14, label %15
13:
  tail call fastcc void @debug.defaultPanic(ptr nonnull readonly @__anon_762, i64 12)
  unreachable
14:
  ret void
15:
  tail call fastcc void @debug.defaultPanic(ptr nonnull readonly @__anon_762, i64 12)
  unreachable
}

define private void @main.zig_struct_u64_u64_2(i64 %0, i64 %1, i64 %2, i64 %3, i64 %4) unnamed_addr align 1 {
5:
  %6 = icmp eq i64 %2, 7
  br i1 %6, label %7, label %9
7:
  %8 = icmp eq i64 %3, 8
  br i1 %8, label %10, label %12
9:
  tail call fastcc void @debug.defaultPanic(ptr nonnull readonly @__anon_762, i64 12)
  unreachable
10:
  %11 = icmp eq i64 %4, 3
  br i1 %11, label %13, label %14
12:
  tail call fastcc void @debug.defaultPanic(ptr nonnull readonly @__anon_762, i64 12)
  unreachable
13:
  ret void
14:
  tail call fastcc void @debug.defaultPanic(ptr nonnull readonly @__anon_762, i64 12)
  unreachable
}

define private void @main.zig_struct_u64_u64_1(i64 %0, i64 %1, i64 %2, i64 %3) unnamed_addr align 1 {
4:
  %5 = icmp eq i64 %1, 5
  br i1 %5, label %6, label %8
6:
  %7 = icmp eq i64 %2, 6
  br i1 %7, label %9, label %11
8:
  tail call fastcc void @debug.defaultPanic(ptr nonnull readonly @__anon_762, i64 12)
  unreachable
9:
  %10 = icmp eq i64 %3, 2
  br i1 %10, label %12, label %13
11:
  tail call fastcc void @debug.defaultPanic(ptr nonnull readonly @__anon_762, i64 12)
  unreachable
12:
  ret void
13:
  tail call fastcc void @debug.defaultPanic(ptr nonnull readonly @__anon_762, i64 12)
  unreachable
}

define private { fp128 } @main.zig_f128_struct(fp128 %0) unnamed_addr align 1 {
1:
  %2 = tail call i32 @__eqtf2(fp128 %0, fp128 0xL0000000000000000400C81C800000000)
  %3 = icmp eq i32 %2, 0
  br i1 %3, label %4, label %5
4:
  ret { fp128 } { fp128 0xL0000000000000000400F81CD00000000 }
5:
  tail call fastcc void @debug.defaultPanic(ptr nonnull readonly @__anon_762, i64 12)
  unreachable
}

define private fp128 @main.zig_f128(fp128 %0) unnamed_addr align 1 {
1:
  %2 = tail call i32 @__eqtf2(fp128 %0, fp128 0xL00000000000000004002800000000000)
  %3 = icmp eq i32 %2, 0
  br i1 %3, label %4, label %5
4:
  ret fp128 0xL00000000000000004004100000000000
5:
  tail call fastcc void @debug.defaultPanic(ptr nonnull readonly @__anon_762, i64 12)
  unreachable
}

define private i32 @main.zig_assert_PD(i64 %0, double %1) unnamed_addr align 1 {
2:
  %3 = alloca { %main.PD }, align 8
  %.not = icmp ne i64 %0, 0
  %spec.store.select = zext i1 %.not to i32
  %4 = fcmp une double %1, 5.000000e-01
  %.0 = select i1 %4, i32 2, i32 %spec.store.select
  %.not6 = icmp eq i32 %.0, 0
  br i1 %.not6, label %5, label %6
5:
  ret i32 %.0
6:
  store i64 %0, ptr %3, align 8
  %.sroa.3.0..sroa_idx2 = getelementptr i8, ptr %3, i64 8
  store double %1, ptr %.sroa.3.0..sroa_idx2, align 8
  call fastcc void @debug.print__anon_14634(ptr nonnull readonly align 8 %3)
  br label %5
}

define private { i64, double } @main.zig_ret_PD() unnamed_addr align 1 {
0:
  ret { i64, double } { i64 0, double 5.000000e-01 }
}

define private { i64, float } @main.zig_ret_CFF() unnamed_addr align 1 {
0:
  ret { i64, float } { i64 4566650022153682983, float 1.000000e+00 }
}

define private i32 @main.zig_assert_CFF(i64 %0, float %1) unnamed_addr align 1 {
2:
  %3 = alloca %main.PD, align 8
  %4 = alloca [64 x i8], align 1
  %.sroa.0.sroa.3.0.extract.shift = lshr i64 %0, 32
  %.sroa.0.sroa.3.0.extract.trunc = trunc nuw i64 %.sroa.0.sroa.3.0.extract.shift to i32
  %5 = bitcast i32 %.sroa.0.sroa.3.0.extract.trunc to float
  %6 = and i64 %0, 255
  %.not = icmp ne i64 %6, 39
  %spec.store.select = zext i1 %.not to i32
  %7 = fcmp une float %5, 8.750000e-01
  %.0 = select i1 %7, i32 2, i32 %spec.store.select
  %8 = fcmp une float %1, 1.000000e+00
  %.1 = select i1 %8, i32 3, i32 %.0
  %.not8 = icmp eq i32 %.1, 0
  br i1 %.not8, label %9, label %10
9:
  ret i32 %.1
10:
  br label %9
}

define private { double, i64 } @main.zig_ret_DC() unnamed_addr align 1 {
0:
  ret { double, i64 } { double -2.500000e-01, i64 15 }
}

define private i32 @main.zig_assert_DC(double %0, i64 %1) unnamed_addr align 1 {
2:
  %3 = alloca %Io.LockedStderr, align 8
  %4 = alloca [64 x i8], align 1
  %5 = fcmp une double %0, -2.500000e-01
  %.0 = zext i1 %5 to i32
  %6 = and i64 %1, 255
  %.not = icmp eq i64 %6, 15
  %.1 = select i1 %.not, i32 %.0, i32 2
  %.not6 = icmp eq i32 %.1, 0
  br i1 %.not6, label %7, label %8
7:
  ret i32 %.1
8:
  br label %7
}

define private { i64, i64 } @main.zig_ret_split_struct_mixed() unnamed_addr align 1 {
0:
  ret { i64, i64 } { i64 1234, i64 4946957900061868132 }
}

define private { i64, i64 } @main.zig_ret_med_struct_mixed() unnamed_addr align 1 {
0:
  ret { i64, i64 } { i64 4812096201845376210, i64 1151803392 }
}

define private { i64, i32 } @main.zig_ret_med_struct_ints() unnamed_addr align 1 {
0:
  ret { i64, i32 } { i64 8589934593, i32 3 }
}

define private i64 @main.zig_ret_i64() unnamed_addr align 1 {
0:
  ret i64 -1
}

define private i16 @main.zig_ret_i16() unnamed_addr align 1 {
0:
  ret i16 -1
}

define private i8 @main.zig_ret_i8() unnamed_addr align 1 {
0:
  ret i8 -1
}

define private i16 @main.zig_ret_u16() unnamed_addr align 1 {
0:
  ret i16 -1
}

define private i8 @main.zig_ret_u8() unnamed_addr align 1 {
0:
  ret i8 -1
}

define private i1 @main.zig_ret_bool() unnamed_addr align 1 {
0:
  ret i1 1
}

define private void @main.zig_multiple_struct_floats(<2 x float> %0, <2 x float> %1, <2 x float> %2, <2 x float> %3) unnamed_addr align 1 {
4:
  %.sroa.03.0.vec.extract = extractelement <2 x float> %0, i64 0
  %5 = fcmp oeq float %.sroa.03.0.vec.extract, 1.000000e+00
  br i1 %5, label %6, label %8
6:
  %.sroa.03.4.vec.extract = extractelement <2 x float> %0, i64 1
  %7 = fcmp oeq float %.sroa.03.4.vec.extract, 2.100000e+01
  br i1 %7, label %9, label %11
8:
  tail call fastcc void @debug.defaultPanic(ptr nonnull readonly @__anon_762, i64 12)
  unreachable
9:
  %.sroa.3.8.vec.extract = extractelement <2 x float> %1, i64 0
  %10 = fcmp oeq float %.sroa.3.8.vec.extract, 1.600000e+01
  br i1 %10, label %12, label %14
11:
  tail call fastcc void @debug.defaultPanic(ptr nonnull readonly @__anon_762, i64 12)
  unreachable
12:
  %.sroa.3.12.vec.extract = extractelement <2 x float> %1, i64 1
  %13 = fcmp oeq float %.sroa.3.12.vec.extract, 4.000000e+00
  br i1 %13, label %15, label %17
14:
  tail call fastcc void @debug.defaultPanic(ptr nonnull readonly @__anon_762, i64 12)
  unreachable
15:
  %.sroa.04.0.vec.extract = extractelement <2 x float> %2, i64 0
  %16 = fcmp oeq float %.sroa.04.0.vec.extract, 1.780000e+02
  br i1 %16, label %18, label %20
17:
  tail call fastcc void @debug.defaultPanic(ptr nonnull readonly @__anon_762, i64 12)
  unreachable
18:
  %.sroa.04.4.vec.extract = extractelement <2 x float> %2, i64 1
  %19 = fcmp oeq float %.sroa.04.4.vec.extract, 1.890000e+02
  br i1 %19, label %21, label %23
20:
  tail call fastcc void @debug.defaultPanic(ptr nonnull readonly @__anon_762, i64 12)
  unreachable
21:
  %.sroa.35.8.vec.extract = extractelement <2 x float> %3, i64 0
  %22 = fcmp oeq float %.sroa.35.8.vec.extract, 2.100000e+01
  br i1 %22, label %24, label %26
23:
  tail call fastcc void @debug.defaultPanic(ptr nonnull readonly @__anon_762, i64 12)
  unreachable
24:
  %.sroa.35.12.vec.extract = extractelement <2 x float> %3, i64 1
  %25 = fcmp oeq float %.sroa.35.12.vec.extract, 1.500000e+01
  br i1 %25, label %27, label %28
26:
  tail call fastcc void @debug.defaultPanic(ptr nonnull readonly @__anon_762, i64 12)
  unreachable
27:
  ret void
28:
  tail call fastcc void @debug.defaultPanic(ptr nonnull readonly @__anon_762, i64 12)
  unreachable
}

define private void @main.zig_multiple_struct_ints(i64 %0, i64 %1, i64 %2, i64 %3) unnamed_addr align 1 {
4:
  %5 = and i64 %0, 4294967295
  %6 = icmp eq i64 %5, 1
  br i1 %6, label %7, label %9
7:
  %.sroa.24.0.extract.shift.mask = and i64 %0, -4294967296
  %8 = icmp eq i64 %.sroa.24.0.extract.shift.mask, 90194313216
  br i1 %8, label %10, label %13
9:
  tail call fastcc void @debug.defaultPanic(ptr nonnull readonly @__anon_762, i64 12)
  unreachable
10:
  %11 = and i64 %1, 4294967295
  %12 = icmp eq i64 %11, 16
  br i1 %12, label %14, label %16
13:
  tail call fastcc void @debug.defaultPanic(ptr nonnull readonly @__anon_762, i64 12)
  unreachable
14:
  %.sroa.5.8.extract.shift.mask = and i64 %1, -4294967296
  %15 = icmp eq i64 %.sroa.5.8.extract.shift.mask, 17179869184
  br i1 %15, label %17, label %20
16:
  tail call fastcc void @debug.defaultPanic(ptr nonnull readonly @__anon_762, i64 12)
  unreachable
17:
  %18 = and i64 %2, 4294967295
  %19 = icmp eq i64 %18, 178
  br i1 %19, label %21, label %23
20:
  tail call fastcc void @debug.defaultPanic(ptr nonnull readonly @__anon_762, i64 12)
  unreachable
21:
  %.sroa.26.0.extract.shift.mask = and i64 %2, -4294967296
  %22 = icmp eq i64 %.sroa.26.0.extract.shift.mask, 811748818944
  br i1 %22, label %24, label %27
23:
  tail call fastcc void @debug.defaultPanic(ptr nonnull readonly @__anon_762, i64 12)
  unreachable
24:
  %25 = and i64 %3, 4294967295
  %26 = icmp eq i64 %25, 21
  br i1 %26, label %28, label %30
27:
  tail call fastcc void @debug.defaultPanic(ptr nonnull readonly @__anon_762, i64 12)
  unreachable
28:
  %.sroa.58.8.extract.shift.mask = and i64 %3, -4294967296
  %29 = icmp eq i64 %.sroa.58.8.extract.shift.mask, 64424509440
  br i1 %29, label %31, label %32
30:
  tail call fastcc void @debug.defaultPanic(ptr nonnull readonly @__anon_762, i64 12)
  unreachable
31:
  ret void
32:
  tail call fastcc void @debug.defaultPanic(ptr nonnull readonly @__anon_762, i64 12)
  unreachable
}

define private void @main.zig_big_struct_both(ptr noalias nonnull writeonly sret(%main.BigStruct) %0, ptr nonnull readonly byval(%main.BigStruct) align 8 %1) unnamed_addr align 1 {
2:
  %.sroa.0.0.copyload = load i64, ptr %1, align 8
  %.sroa.3.0..sroa_idx = getelementptr i8, ptr %1, i64 16
  %.sroa.3.0.copyload = load i64, ptr %.sroa.3.0..sroa_idx, align 8
  %.sroa.4.0..sroa_idx = getelementptr i8, ptr %1, i64 24
  %.sroa.4.0.copyload = load i64, ptr %.sroa.4.0..sroa_idx, align 8
  %.sroa.5.0..sroa_idx = getelementptr i8, ptr %1, i64 32
  %.sroa.5.0.copyload = load i8, ptr %.sroa.5.0..sroa_idx, align 8
  %3 = icmp eq i64 %.sroa.0.0.copyload, 30
  br i1 %3, label %4, label %6
4:
  %.sroa.2.0..sroa_idx = getelementptr i8, ptr %1, i64 8
  %.sroa.2.0.copyload = load i64, ptr %.sroa.2.0..sroa_idx, align 8
  %5 = icmp eq i64 %.sroa.2.0.copyload, 31
  br i1 %5, label %7, label %9
6:
  tail call fastcc void @debug.defaultPanic(ptr nonnull readonly @__anon_762, i64 12)
  unreachable
7:
  %8 = icmp eq i64 %.sroa.3.0.copyload, 32
  br i1 %8, label %10, label %12
9:
  tail call fastcc void @debug.defaultPanic(ptr nonnull readonly @__anon_762, i64 12)
  unreachable
10:
  %11 = icmp eq i64 %.sroa.4.0.copyload, 33
  br i1 %11, label %13, label %15
12:
  tail call fastcc void @debug.defaultPanic(ptr nonnull readonly @__anon_762, i64 12)
  unreachable
13:
  %14 = icmp eq i8 %.sroa.5.0.copyload, 34
  br i1 %14, label %16, label %17
15:
  tail call fastcc void @debug.defaultPanic(ptr nonnull readonly @__anon_762, i64 12)
  unreachable
16:
  tail call void @llvm.memcpy.p0.p0.i64(ptr %0, ptr @__anon_15510, i64 40, i1 0)
  ret void
17:
  tail call fastcc void @debug.defaultPanic(ptr nonnull readonly @__anon_762, i64 12)
  unreachable
}

define private void @main.zig_split_struct_mixed(i64 %0, i64 %1) unnamed_addr align 1 {
2:
  %.sroa.2.sroa.2.0.extract.shift = lshr i64 %1, 32
  %.sroa.2.sroa.2.0.extract.trunc = trunc nuw i64 %.sroa.2.sroa.2.0.extract.shift to i32
  %3 = bitcast i32 %.sroa.2.sroa.2.0.extract.trunc to float
  %4 = icmp eq i64 %0, 1234
  br i1 %4, label %5, label %8
5:
  %6 = and i64 %1, 255
  %7 = icmp eq i64 %6, 100
  br i1 %7, label %9, label %11
8:
  tail call fastcc void @debug.defaultPanic(ptr nonnull readonly @__anon_762, i64 12)
  unreachable
9:
  %10 = fcmp oeq float %3, 1.337000e+03
  br i1 %10, label %12, label %13
11:
  tail call fastcc void @debug.defaultPanic(ptr nonnull readonly @__anon_762, i64 12)
  unreachable
12:
  ret void
13:
  tail call fastcc void @debug.defaultPanic(ptr nonnull readonly @__anon_762, i64 12)
  unreachable
}

define private void @main.zig_split_struct_ints(i64 %0, i64 %1) unnamed_addr align 1 {
2:
  %3 = icmp eq i64 %0, 1234
  br i1 %3, label %4, label %7
4:
  %5 = and i64 %1, 255
  %6 = icmp eq i64 %5, 100
  br i1 %6, label %8, label %10
7:
  tail call fastcc void @debug.defaultPanic(ptr nonnull readonly @__anon_762, i64 12)
  unreachable
8:
  %.sroa.43.8.extract.shift.mask = and i64 %1, -4294967296
  %9 = icmp eq i64 %.sroa.43.8.extract.shift.mask, 5742371274752
  br i1 %9, label %11, label %12
10:
  tail call fastcc void @debug.defaultPanic(ptr nonnull readonly @__anon_762, i64 12)
  unreachable
11:
  ret void
12:
  tail call fastcc void @debug.defaultPanic(ptr nonnull readonly @__anon_762, i64 12)
  unreachable
}

define private void @main.zig_small_struct_ints(i32 %0) unnamed_addr align 1 {
1:
  %2 = and i32 %0, 255
  %3 = icmp eq i32 %2, 1
  br i1 %3, label %4, label %7
4:
  %5 = and i32 %0, 65280
  %6 = icmp eq i32 %5, 512
  br i1 %6, label %8, label %11
7:
  tail call fastcc void @debug.defaultPanic(ptr nonnull readonly @__anon_762, i64 12)
  unreachable
8:
  %9 = and i32 %0, 16711680
  %10 = icmp eq i32 %9, 196608
  br i1 %10, label %12, label %14
11:
  tail call fastcc void @debug.defaultPanic(ptr nonnull readonly @__anon_762, i64 12)
  unreachable
12:
  %.sroa.4.0.extract.shift.mask = and i32 %0, -16777216
  %13 = icmp eq i32 %.sroa.4.0.extract.shift.mask, 67108864
  br i1 %13, label %15, label %16
14:
  tail call fastcc void @debug.defaultPanic(ptr nonnull readonly @__anon_762, i64 12)
  unreachable
15:
  ret void
16:
  tail call fastcc void @debug.defaultPanic(ptr nonnull readonly @__anon_762, i64 12)
  unreachable
}

define private void @main.zig_struct_i32_i32(i64 %0) unnamed_addr align 1 {
1:
  %2 = and i64 %0, 4294967295
  %3 = icmp eq i64 %2, 1
  br i1 %3, label %4, label %6
4:
  %.sroa.2.0.extract.shift.mask = and i64 %0, -4294967296
  %5 = icmp eq i64 %.sroa.2.0.extract.shift.mask, 8589934592
  br i1 %5, label %7, label %8
6:
  tail call fastcc void @debug.defaultPanic(ptr nonnull readonly @__anon_762, i64 12)
  unreachable
7:
  ret void
8:
  tail call fastcc void @debug.defaultPanic(ptr nonnull readonly @__anon_762, i64 12)
  unreachable
}

define private void @main.zig_struct_f32_f32f32(<2 x float> %0, float %1) unnamed_addr align 1 {
2:
  %.sroa.01.0.vec.extract = extractelement <2 x float> %0, i64 0
  %3 = fcmp oeq float %.sroa.01.0.vec.extract, 1.000000e+00
  br i1 %3, label %4, label %6
4:
  %.sroa.01.4.vec.extract = extractelement <2 x float> %0, i64 1
  %5 = fcmp oeq float %.sroa.01.4.vec.extract, 2.000000e+00
  br i1 %5, label %7, label %9
6:
  tail call fastcc void @debug.defaultPanic(ptr nonnull readonly @__anon_762, i64 12)
  unreachable
7:
  %8 = fcmp oeq float %1, 3.000000e+00
  br i1 %8, label %10, label %11
9:
  tail call fastcc void @debug.defaultPanic(ptr nonnull readonly @__anon_762, i64 12)
  unreachable
10:
  ret void
11:
  tail call fastcc void @debug.defaultPanic(ptr nonnull readonly @__anon_762, i64 12)
  unreachable
}

define private void @main.zig_big_struct(ptr nonnull readonly byval(%main.BigStruct) align 8 %0) unnamed_addr align 1 {
1:
  %.sroa.0.0.copyload = load i64, ptr %0, align 8
  %.sroa.3.0..sroa_idx = getelementptr i8, ptr %0, i64 16
  %.sroa.3.0.copyload = load i64, ptr %.sroa.3.0..sroa_idx, align 8
  %.sroa.4.0..sroa_idx = getelementptr i8, ptr %0, i64 24
  %.sroa.4.0.copyload = load i64, ptr %.sroa.4.0..sroa_idx, align 8
  %.sroa.5.0..sroa_idx = getelementptr i8, ptr %0, i64 32
  %.sroa.5.0.copyload = load i8, ptr %.sroa.5.0..sroa_idx, align 8
  %2 = icmp eq i64 %.sroa.0.0.copyload, 1
  br i1 %2, label %3, label %5
3:
  %.sroa.2.0..sroa_idx = getelementptr i8, ptr %0, i64 8
  %.sroa.2.0.copyload = load i64, ptr %.sroa.2.0..sroa_idx, align 8
  %4 = icmp eq i64 %.sroa.2.0.copyload, 2
  br i1 %4, label %6, label %8
5:
  tail call fastcc void @debug.defaultPanic(ptr nonnull readonly @__anon_762, i64 12)
  unreachable
6:
  %7 = icmp eq i64 %.sroa.3.0.copyload, 3
  br i1 %7, label %9, label %11
8:
  tail call fastcc void @debug.defaultPanic(ptr nonnull readonly @__anon_762, i64 12)
  unreachable
9:
  %10 = icmp eq i64 %.sroa.4.0.copyload, 4
  br i1 %10, label %12, label %14
11:
  tail call fastcc void @debug.defaultPanic(ptr nonnull readonly @__anon_762, i64 12)
  unreachable
12:
  %13 = icmp eq i8 %.sroa.5.0.copyload, 5
  br i1 %13, label %15, label %16
14:
  tail call fastcc void @debug.defaultPanic(ptr nonnull readonly @__anon_762, i64 12)
  unreachable
15:
  ret void
16:
  tail call fastcc void @debug.defaultPanic(ptr nonnull readonly @__anon_762, i64 12)
  unreachable
}

define private void @main.zig_med_struct_mixed(i64 %0, i64 %1) unnamed_addr align 1 {
2:
  %.sroa.2.sroa.0.0.extract.trunc = trunc i64 %1 to i32
  %3 = bitcast i32 %.sroa.2.sroa.0.0.extract.trunc to float
  %4 = and i64 %0, 4294967295
  %5 = icmp eq i64 %4, 1234
  br i1 %5, label %6, label %9
6:
  %.sroa.0.sroa.2.0.extract.shift = lshr i64 %0, 32
  %.sroa.0.sroa.2.0.extract.trunc = trunc nuw i64 %.sroa.0.sroa.2.0.extract.shift to i32
  %7 = bitcast i32 %.sroa.0.sroa.2.0.extract.trunc to float
  %8 = fcmp oeq float %7, 1.000000e+02
  br i1 %8, label %10, label %12
9:
  tail call fastcc void @debug.defaultPanic(ptr nonnull readonly @__anon_762, i64 12)
  unreachable
10:
  %11 = fcmp oeq float %3, 1.337000e+03
  br i1 %11, label %13, label %14
12:
  tail call fastcc void @debug.defaultPanic(ptr nonnull readonly @__anon_762, i64 12)
  unreachable
13:
  ret void
14:
  tail call fastcc void @debug.defaultPanic(ptr nonnull readonly @__anon_762, i64 12)
  unreachable
}

define private void @main.zig_big_union(ptr nonnull readonly byval(%main.BigUnion) align 8 %0) unnamed_addr align 1 {
1:
  %.sroa.0.0.copyload = load i64, ptr %0, align 8
  %.sroa.3.0..sroa_idx = getelementptr i8, ptr %0, i64 16
  %.sroa.3.0.copyload = load i64, ptr %.sroa.3.0..sroa_idx, align 8
  %.sroa.4.0..sroa_idx = getelementptr i8, ptr %0, i64 24
  %.sroa.4.0.copyload = load i64, ptr %.sroa.4.0..sroa_idx, align 8
  %.sroa.5.0..sroa_idx = getelementptr i8, ptr %0, i64 32
  %.sroa.5.0.copyload = load i8, ptr %.sroa.5.0..sroa_idx, align 8
  %2 = icmp eq i64 %.sroa.0.0.copyload, 1
  br i1 %2, label %3, label %5
3:
  %.sroa.2.0..sroa_idx = getelementptr i8, ptr %0, i64 8
  %.sroa.2.0.copyload = load i64, ptr %.sroa.2.0..sroa_idx, align 8
  %4 = icmp eq i64 %.sroa.2.0.copyload, 2
  br i1 %4, label %6, label %8
5:
  tail call fastcc void @debug.defaultPanic(ptr nonnull readonly @__anon_762, i64 12)
  unreachable
6:
  %7 = icmp eq i64 %.sroa.3.0.copyload, 3
  br i1 %7, label %9, label %11
8:
  tail call fastcc void @debug.defaultPanic(ptr nonnull readonly @__anon_762, i64 12)
  unreachable
9:
  %10 = icmp eq i64 %.sroa.4.0.copyload, 4
  br i1 %10, label %12, label %14
11:
  tail call fastcc void @debug.defaultPanic(ptr nonnull readonly @__anon_762, i64 12)
  unreachable
12:
  %13 = icmp eq i8 %.sroa.5.0.copyload, 5
  br i1 %13, label %15, label %16
14:
  tail call fastcc void @debug.defaultPanic(ptr nonnull readonly @__anon_762, i64 12)
  unreachable
15:
  ret void
16:
  tail call fastcc void @debug.defaultPanic(ptr nonnull readonly @__anon_762, i64 12)
  unreachable
}

define private void @main.zig_big_packed_struct(i128 %0) unnamed_addr align 1 {
1:
  %2 = trunc i128 %0 to i64
  %3 = icmp eq i64 %2, 1
  br i1 %3, label %4, label %6
4:
  %.mask = and i128 %0, -18446744073709551616
  %5 = icmp eq i128 %.mask, 36893488147419103232
  br i1 %5, label %7, label %8
6:
  tail call fastcc void @debug.defaultPanic(ptr nonnull readonly @__anon_762, i64 12)
  unreachable
7:
  ret void
8:
  tail call fastcc void @debug.defaultPanic(ptr nonnull readonly @__anon_762, i64 12)
  unreachable
}

define private void @main.zig_small_packed_struct(i8 zeroext %0) unnamed_addr align 1 {
1:
  %2 = and i8 %0, 3
  %3 = icmp eq i8 %2, 0
  br i1 %3, label %4, label %7
4:
  %5 = and i8 %0, 12
  %6 = icmp eq i8 %5, 4
  br i1 %6, label %8, label %11
7:
  tail call fastcc void @debug.defaultPanic(ptr nonnull readonly @__anon_762, i64 12)
  unreachable
8:
  %9 = and i8 %0, 48
  %10 = icmp eq i8 %9, 32
  br i1 %10, label %12, label %14
11:
  tail call fastcc void @debug.defaultPanic(ptr nonnull readonly @__anon_762, i64 12)
  unreachable
12:
  %13 = icmp ugt i8 %0, -65
  br i1 %13, label %15, label %16
14:
  tail call fastcc void @debug.defaultPanic(ptr nonnull readonly @__anon_762, i64 12)
  unreachable
15:
  ret void
16:
  tail call fastcc void @debug.defaultPanic(ptr nonnull readonly @__anon_762, i64 12)
  unreachable
}

define private void @main.zig_med_struct_ints(i64 %0, i32 %1) unnamed_addr align 1 {
2:
  %3 = and i64 %0, 4294967295
  %4 = icmp eq i64 %3, 1
  br i1 %4, label %5, label %7
5:
  %.sroa.22.0.extract.shift.mask = and i64 %0, -4294967296
  %6 = icmp eq i64 %.sroa.22.0.extract.shift.mask, 8589934592
  br i1 %6, label %8, label %10
7:
  tail call fastcc void @debug.defaultPanic(ptr nonnull readonly @__anon_762, i64 12)
  unreachable
8:
  %9 = icmp eq i32 %1, 3
  br i1 %9, label %11, label %12
10:
  tail call fastcc void @debug.defaultPanic(ptr nonnull readonly @__anon_762, i64 12)
  unreachable
11:
  ret void
12:
  tail call fastcc void @debug.defaultPanic(ptr nonnull readonly @__anon_762, i64 12)
  unreachable
}
