define i32 @licm_store_reject(i32 %a) {
entry:
  %p = alloca i32
  br label %header
header:
  %i = phi i32 [ 0, %entry ], [ %next, %latch ]
  store i32 %i, ptr %p
  br i1 1, label %body, label %exit
body:
  br label %latch
latch:
  %next = add i32 %i, 1
  br label %header
exit:
  ret i32 %a
}
