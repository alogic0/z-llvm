define i32 @licm_multi_latch(i32 %a) {
entry:
  br label %header
header:
  %x = icmp sgt i32 %a, 0
  br i1 %x, label %left, label %right
left:
  br label %latch_left
latch_left:
  br label %header
right:
  br label %latch_right
latch_right:
  br label %header
}
