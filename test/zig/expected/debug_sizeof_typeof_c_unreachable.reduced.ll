source_filename = "debug_sizeof_typeof_c_unreachable"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

@c_fopen = alias ptr (ptr, ptr), ptr @sizeof_and_typeof.exp.c_fopen
@c_ftell = alias i64 (ptr), ptr @sizeof_and_typeof.exp.c_ftell
@c_fputs = alias i32 (ptr, ptr), ptr @sizeof_and_typeof.exp.c_fputs
@c_printf = alias i32 (ptr), ptr @sizeof_and_typeof.exp.c_printf

declare fastcc void @"debug.FullPanic((function 'defaultPanic')).reachedUnreachable"()

define private ptr @sizeof_and_typeof.exp.c_fopen(ptr readonly %0, ptr readonly %1) unnamed_addr #0 align 1 {
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).reachedUnreachable"()
  unreachable
}

define private i64 @sizeof_and_typeof.exp.c_ftell(ptr align 1 %0) unnamed_addr #0 align 1 {
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).reachedUnreachable"()
  unreachable
}

define private i32 @sizeof_and_typeof.exp.c_fputs(ptr readonly %0, ptr noalias align 1 %1) unnamed_addr #0 align 1 {
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).reachedUnreachable"()
  unreachable
}

define private i32 @sizeof_and_typeof.exp.c_printf(ptr readonly %0) unnamed_addr #0 align 1 {
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).reachedUnreachable"()
  unreachable
}

attributes #0 = { cold nounwind uwtable "frame-pointer"="all" "target-cpu"="x86-64" }

!llvm.module.flags = !{}
