source_filename = "aggregates"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux5.10.0-gnu2.31.0"

@optional_payload = alias i32 (i32, i32), ptr @aggregates.optional_payload

define private i32 @aggregates.optional_payload(i32 %0, i32 %1) unnamed_addr #0 align 1 {
.critedge:
  %.not = icmp eq i32 %0, 0
  %spec.select = select i1 %.not, i32 -1, i32 %1
  ret i32 %spec.select
}

!llvm.module.flags = !{}
