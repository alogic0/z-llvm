define i32 @licm_scalar_with_memory(i32 %a, ptr %p) {
entry:
  br label %header
header:
  %x = add i32 %a, 1
  store volatile i32 %a, ptr %p, align 4
  %c = icmp sgt i32 %x, 0
  br i1 %c, label %body, label %exit
body:
  br label %latch
latch:
  br label %header
exit:
  ret i32 %a
}
