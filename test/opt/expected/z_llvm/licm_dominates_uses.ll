define i32 @licm_dominates_uses(i32 %a) {
entry:
  %x = add i32 %a, 1
  %y = add i32 %x, 2
  %z = icmp sgt i32 %y, 0
  br label %header
header:
  br label %body
body:
  br label %latch
latch:
  br i1 %z, label %header, label %exit
exit:
  ret i32 %a
}
