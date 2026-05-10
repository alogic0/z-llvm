define i32 @licm_dominates_uses(i32 %a) {
entry:
  br label %header
header:
  br label %body
body:
  %x = add i32 %a, 1
  br label %latch
latch:
  %y = add i32 %x, 2
  %z = icmp sgt i32 %y, 0
  br i1 %z, label %header, label %exit
exit:
  ret i32 %a
}
