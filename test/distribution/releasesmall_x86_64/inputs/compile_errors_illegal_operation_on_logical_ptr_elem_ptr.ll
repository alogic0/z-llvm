source_filename = "illegal_operation_on_logical_ptr"
target datalayout = "e-m:e-p270:32:32-p271:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

@elemVal = alias void (), ptr @illegal_operation_on_logical_ptr.elemVal
@elemPtr = alias void (), ptr @illegal_operation_on_logical_ptr.elemPtr

define private void @illegal_operation_on_logical_ptr.elemVal() unnamed_addr align 1 {
0:
  ret void
}

define private void @illegal_operation_on_logical_ptr.elemPtr() unnamed_addr #0 align 1 {
0:
  unreachable
}

attributes #0 = { noreturn }
