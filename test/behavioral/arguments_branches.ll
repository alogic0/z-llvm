define i32 @probe(i32 %x, i32 %y) {
entry:
  %negative = icmp slt i32 %x, 0
  br i1 %negative, label %neg, label %pos
neg:
  %quotient = sdiv i32 %x, 8
  %a = xor i32 %quotient, %y
  br label %merge
pos:
  %shifted = lshr i32 %x, 3
  %b = add i32 %shifted, %y
  br label %merge
merge:
  %result = phi i32 [ %a, %neg ], [ %b, %pos ]
  ret i32 %result
}
