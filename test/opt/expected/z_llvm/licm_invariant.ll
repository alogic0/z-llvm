define i32 @licm_invariant(i32 %a) {
entry:
  %x = icmp sgt i32 %a, 0
  br label %header
header:
  br i1 %x, label %body, label %exit
body:
  br label %latch
latch:
  br label %header
exit:
  ret i32 %a
}
