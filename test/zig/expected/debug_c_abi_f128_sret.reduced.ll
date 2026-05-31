source_filename = "debug_c_abi_f128_sret"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

%main.f128_f128_struct = type { fp128, fp128 }

@__anon_762 = private unnamed_addr constant [12 x i8] c"test failed\00", align 1
@__anon_854 = private unnamed_addr constant { i64, i8, [7 x i8] } { i64 0, i8 1, [7 x i8] undef }, align 8
@zig_f128_f128_struct = alias void (ptr, ptr), ptr @main.zig_f128_f128_struct

declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg)
declare i32 @__eqtf2(fp128, fp128)
declare fastcc i16 @testing.expect(i1)
declare fastcc void @debug.defaultPanic(ptr nonnull readonly, i64, ptr nonnull readonly align 8)

define private void @main.zig_f128_f128_struct(ptr noalias nonnull sret(%main.f128_f128_struct) %0, ptr nonnull readonly byval(%main.f128_f128_struct) align 16 %1) unnamed_addr #0 align 1 {
entry:
  %3 = alloca %main.f128_f128_struct, align 16
  call void @llvm.memcpy.p0.p0.i64(ptr align 16 %3, ptr align 16 %1, i64 32, i1 false)
  %4 = load fp128, ptr %3, align 16
  %5 = call i32 @__eqtf2(fp128 %4, fp128 0xL00000000000000004002A00000000000)
  %6 = icmp eq i32 %5, 0
  %7 = call fastcc i16 @testing.expect(i1 %6)
  %8 = icmp eq i16 %7, 0
  br i1 %8, label %16, label %17

9:
  %10 = getelementptr inbounds i8, ptr %3, i64 16
  %11 = load fp128, ptr %10, align 16
  %12 = call i32 @__eqtf2(fp128 %11, fp128 0xL00000000000000004004C80000000000)
  %13 = icmp eq i32 %12, 0
  %14 = call fastcc i16 @testing.expect(i1 %13)
  %15 = icmp eq i16 %14, 0
  br i1 %15, label %22, label %23

16:
  br label %9

17:
  %18 = extractvalue { ptr, i64 } { ptr @__anon_762, i64 12 }, 0
  %19 = extractvalue { ptr, i64 } { ptr @__anon_762, i64 12 }, 1
  call fastcc void @debug.defaultPanic(ptr nonnull readonly %18, i64 %19, ptr nonnull readonly align 8 @__anon_854)
  unreachable

20:
  store fp128 0xL00000000000000004003800000000000, ptr %0, align 16
  %21 = getelementptr inbounds i8, ptr %0, i64 16
  store fp128 0xL00000000000000004005100000000000, ptr %21, align 16
  ret void

22:
  br label %20

23:
  %24 = extractvalue { ptr, i64 } { ptr @__anon_762, i64 12 }, 0
  %25 = extractvalue { ptr, i64 } { ptr @__anon_762, i64 12 }, 1
  call fastcc void @debug.defaultPanic(ptr nonnull readonly %24, i64 %25, ptr nonnull readonly align 8 @__anon_854)
  unreachable
}

attributes #0 = { nounwind uwtable "frame-pointer"="all" "target-cpu"="x86-64" }

!llvm.module.flags = !{}
