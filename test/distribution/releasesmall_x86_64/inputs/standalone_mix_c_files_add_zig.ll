source_filename = "main"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux5.10.0-gnu2.31.0"

@C_k = external thread_local local_unnamed_addr global i32, align 4
@main.zig_k = private unnamed_addr global i32 1, align 4

@add_zig = alias i32 (i32), ptr @main.add_zig
@zig_k = alias i32, ptr @main.zig_k

define private i32 @main.add_zig(i32 %0) unnamed_addr #0 align 1 {
1:
  %2 = load i32, ptr @main.zig_k, align 4
  %3 = add nsw i32 %2, %0
  %4 = load i32, ptr @C_k, align 4
  %5 = add nsw i32 %3, %4
  ret i32 %5
}

attributes #0 = { minsize mustprogress nofree norecurse nosync nounwind optsize willreturn memory(read, inaccessiblemem: none) uwtable "frame-pointer"="all" }

!llvm.module.flags = !{}
