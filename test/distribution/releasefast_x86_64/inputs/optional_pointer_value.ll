source_filename = "optional_pointer"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux5.10.0-gnu2.31.0"

@optional_ptr_value = alias i32 (ptr), ptr @optional_pointer.optional_ptr_value

define private i32 @optional_pointer.optional_ptr_value(ptr readonly captures(address_is_null) %0) unnamed_addr #0 align 1 {
1:
  %.not = icmp eq ptr %0, null
  br i1 %.not, label %common.ret, label %2
common.ret:
  %common.ret.op = phi i32 [ %3, %2 ], [ -1, %1 ]
  ret i32 %common.ret.op
2:
  %3 = load i32, ptr %0, align 4
  br label %common.ret
}

!llvm.module.flags = !{}
