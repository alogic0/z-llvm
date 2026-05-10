define i32 @mem2reg_unreachable(i32 %a, i32 %b) {
entry:
  %slot = alloca i32
  store i32 %a, ptr %slot
  br label %merge
dead:
  store i32 %b, ptr %slot
  br label %merge
merge:
  %v = load i32, ptr %slot
  ret i32 %v
}
