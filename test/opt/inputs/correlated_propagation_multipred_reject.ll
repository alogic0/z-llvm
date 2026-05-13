define i1 @cvp_multipred(i1 %flag, i32 %x) {
entry:
  %c = icmp eq i32 %x, 0
  br i1 %flag, label %left, label %right

left:
  br i1 %c, label %join, label %exit

right:
  br label %join

join:
  %again = icmp eq i32 %x, 0
  ret i1 %again

exit:
  ret i1 0
}
