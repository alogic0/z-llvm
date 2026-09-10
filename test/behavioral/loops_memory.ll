define i32 @probe(i32 %x, i32 %y) {
entry:
  %slot = alloca [1 x i32], align 4
  store i32 %x, ptr %slot, align 4
  br label %loop
loop:
  %i = phi i32 [ 0, %entry ], [ %next, %body ]
  %done = icmp eq i32 %i, %y
  br i1 %done, label %exit, label %body
body:
  %old = load i32, ptr %slot, align 4
  %mixed = xor i32 %old, %i
  %new = add i32 %mixed, 7
  store i32 %new, ptr %slot, align 4
  %next = add i32 %i, 1
  br label %loop
exit:
  %result = load i32, ptr %slot, align 4
  ret i32 %result
}
