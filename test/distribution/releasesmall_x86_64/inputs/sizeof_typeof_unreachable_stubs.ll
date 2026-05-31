source_filename = "sizeof_and_typeof"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux5.10.0-gnu2.31.0"

@c_fopen = alias ptr (ptr, ptr), ptr @sizeof_and_typeof.exp.c_fopen
@c_ftell = alias i64 (ptr), ptr @sizeof_and_typeof.exp.c_ftell
@c_fputs = alias i32 (ptr, ptr), ptr @sizeof_and_typeof.exp.c_fputs
@c_printf = alias i32 (ptr), ptr @sizeof_and_typeof.exp.c_printf

define private noalias noundef nonnull ptr @sizeof_and_typeof.exp.c_fopen(ptr readonly captures(none) %0, ptr readonly captures(none) %1) unnamed_addr #0 align 1 {
2:
  unreachable
}

define private noundef i64 @sizeof_and_typeof.exp.c_ftell(ptr readnone align 1 captures(none) %0) unnamed_addr #0 align 1 {
1:
  unreachable
}

define private noundef i32 @sizeof_and_typeof.exp.c_fputs(ptr readonly captures(none) %0, ptr noalias readnone align 1 captures(none) %1) unnamed_addr #0 align 1 {
2:
  unreachable
}

define private noundef i32 @sizeof_and_typeof.exp.c_printf(ptr readonly captures(none) %0) unnamed_addr #0 align 1 {
1:
  unreachable
}

attributes #0 = { minsize mustprogress nofree norecurse noreturn nosync nounwind optsize willreturn memory(none) uwtable "frame-pointer"="all" "target-cpu"="x86-64" }

!llvm.module.flags = !{}
