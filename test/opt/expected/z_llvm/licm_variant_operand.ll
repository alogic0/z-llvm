define i32 @licm_variant_operand(i32 %a) {
entry:
  br label %header
header:
  %i = phi i32 [ 0, %entry ], [ %next, %latch ]
  %x = icmp sgt i32 %i, 0
  br i1 %x, label %body, label %exit
body:
  br label %latch
latch:
  %next = add i32 %i, 1
  br label %header
exit:
  ret i32 %a
}
