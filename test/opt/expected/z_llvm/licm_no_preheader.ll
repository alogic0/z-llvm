define i32 @licm_no_preheader(i32 %a) {
entry:
  br i1 1, label %header, label %exit
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
