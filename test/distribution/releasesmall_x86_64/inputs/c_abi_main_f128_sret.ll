target triple = "x86_64-unknown-linux-gnu"

%main.f128_f128_struct = type { fp128, fp128 }

@__zllvm_f128_cmp0 = private unnamed_addr constant fp128 0xL00000000000000004002A00000000000, align 16
@__zllvm_f128_cmp1 = private unnamed_addr constant fp128 0xL00000000000000004004C80000000000, align 16
@__zllvm_f128_ret0 = private unnamed_addr constant fp128 0xL00000000000000004003800000000000, align 16
@__zllvm_f128_ret1 = private unnamed_addr constant fp128 0xL00000000000000004005100000000000, align 16
@__anon_762 = private unnamed_addr constant [13 x i8] c"test failure\00", align 1
@zig_f128_f128_struct = alias void (ptr, ptr), ptr @main.zig_f128_f128_struct

declare i32 @__eqtf2(fp128, fp128)
declare fastcc void @debug.defaultPanic(ptr, i64)

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
