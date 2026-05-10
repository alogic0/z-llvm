define i32 @mem2reg_loop(i32 %a) {
entry:
  br label %loop
loop:
  %slot.0 = phi i32 [ %a, %entry ], [ %next, %body ]
  %more = icmp ne i32 %slot.0, 0
  br i1 %more, label %body, label %exit
body:
  %next = sub i32 %slot.0, 1
  br label %loop
exit:
  ret i32 %slot.0
}
