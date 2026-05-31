source_filename = "aggregates"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux5.10.0-gnu2.31.0"

@error_union_payload = alias i32 (i32), ptr @aggregates.error_union_payload

define private range(i32 -1, 8) i32 @aggregates.error_union_payload(i32 %0) unnamed_addr #0 align 1 {
1:
  %.not.i = icmp eq i32 %0, 0
  %2 = select i1 %.not.i, i32 7, i32 -1
  ret i32 %2
}

!llvm.module.flags = !{}
