source_filename = "main"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux5.10.0-gnu2.31.0"

@main.zig_k = private unnamed_addr global i32 1, align 4
@__anon_14658 = private unnamed_addr constant [13 x i8] c"negative int\00", align 1

@add_may_panic = alias i32 (i32), ptr @main.add_may_panic
@zig_k = alias i32, ptr @main.zig_k

declare void @llvm.assume(i1 noundef) #1
declare fastcc void @debug.defaultPanic(ptr nonnull readonly align 1, i64) #2

define private i32 @main.add_may_panic(i32 %0) unnamed_addr #0 align 1 {
1:
  %2 = icmp slt i32 %0, 0
  br i1 %2, label %3, label %4

3:
  call void @llvm.assume(i1 1) [ "cold"() ]
  tail call fastcc void @debug.defaultPanic(ptr nonnull readonly align 1 @__anon_14658, i64 12)
  unreachable

4:
  %5 = load i32, ptr @main.zig_k, align 4
  %6 = add nsw i32 %5, %0
  ret i32 %6
}

attributes #0 = { minsize nounwind optsize uwtable "frame-pointer"="all" }
attributes #1 = { nocallback nofree nosync nounwind willreturn memory(inaccessiblemem: readwrite) }
attributes #2 = { minsize noreturn nounwind }

!llvm.module.flags = !{}
