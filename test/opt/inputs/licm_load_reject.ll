define i32 @licm_load_reject(i32 %a) {
entry:
  %p = alloca i32
  store i32 %a, ptr %p
  br label %header
header:
  %v = load i32, ptr %p
  store i32 %v, ptr %p
  br i1 1, label %body, label %exit
body:
  br label %latch
latch:
  br label %header
exit:
  ret i32 %a
}
