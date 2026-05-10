define i32 @mem2reg_two_slots(i1 %cond, i32 %a, i32 %b, i32 %c, i32 %d) {
entry:
  %x = alloca i32
  %y = alloca i32
  br i1 %cond, label %left, label %right
left:
  store i32 %a, ptr %x
  store i32 %b, ptr %y
  br label %merge
right:
  store i32 %c, ptr %x
  store i32 %d, ptr %y
  br label %merge
merge:
  %vx = load i32, ptr %x
  %vy = load i32, ptr %y
  %sum = add i32 %vx, %vy
  ret i32 %sum
}
