define i32 @mem2reg_loop(i32 %a) {
entry:
  %slot = alloca i32
  store i32 %a, ptr %slot
  br label %loop
loop:
  %v = load i32, ptr %slot
  %more = icmp ne i32 %v, 0
  br i1 %more, label %body, label %exit
body:
  %next = sub i32 %v, 1
  store i32 %next, ptr %slot
  br label %loop
exit:
  ret i32 %v
}
