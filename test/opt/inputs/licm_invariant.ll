define i32 @licm_invariant(i32 %a) {
entry:
  br label %header
header:
  %x = icmp sgt i32 %a, 0
  br i1 %x, label %body, label %exit
body:
  br label %latch
latch:
  br label %header
exit:
  ret i32 %a
}
