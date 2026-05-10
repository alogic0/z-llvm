define i32 @licm_aligned_load_reject(i32 %a, ptr %p) {
entry:
  br label %header
header:
  %v = load i32, ptr %p, align 4
  %c = icmp sgt i32 %v, 0
  br i1 %c, label %body, label %exit
body:
  br label %latch
latch:
  br label %header
exit:
  ret i32 %a
}
