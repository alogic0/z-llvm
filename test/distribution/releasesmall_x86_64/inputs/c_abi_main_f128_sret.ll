target triple = "x86_64-unknown-linux-gnu"

%main.f128_f128_struct = type { fp128, fp128 }
%main.PD = type { ptr, double }
%Io.LockedStderr = type { ptr }

@__zllvm_f128_cmp0 = private unnamed_addr constant fp128 0xL00000000000000004002A00000000000, align 16
@__zllvm_f128_cmp1 = private unnamed_addr constant fp128 0xL00000000000000004004C80000000000, align 16
@__zllvm_f128_ret0 = private unnamed_addr constant fp128 0xL00000000000000004003800000000000, align 16
@__zllvm_f128_ret1 = private unnamed_addr constant fp128 0xL00000000000000004005100000000000, align 16
@__zllvm_f128_struct_cmp0 = private unnamed_addr constant fp128 0xL0000000000000000400C81C800000000, align 16
@__zllvm_f128_struct_ret0 = private unnamed_addr constant fp128 0xL0000000000000000400F81CD00000000, align 16
@__zllvm_f128_scalar_cmp0 = private unnamed_addr constant fp128 0xL00000000000000004002800000000000, align 16
@__zllvm_f128_scalar_ret0 = private unnamed_addr constant fp128 0xL00000000000000004004100000000000, align 16
@__anon_762 = private unnamed_addr constant [13 x i8] c"test failure\00", align 1
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

declare i32 @__eqtf2(fp128, fp128)
declare fastcc void @debug.defaultPanic(ptr, i64)
declare fastcc void @debug.print__anon_14634(ptr)

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
