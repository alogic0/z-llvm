define i32 @adce_dead_switch(i32 %tag, i32 %a) {
entry:
  switch i32 %tag, label %default [
    i32 0, label %left
    i32 1, label %right
  ]
default:
  %d = add i32 %a, 3
  br label %join
left:
  %x = add i32 %a, 1
  br label %join
right:
  %y = add i32 %a, 2
  br label %join
join:
  ret i32 0
}
