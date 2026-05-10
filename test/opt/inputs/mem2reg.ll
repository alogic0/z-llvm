define i32 @mem2reg(i32 %a) {
entry:
  %slot = alloca i32
  store i32 %a, ptr %slot
  %v = load i32, ptr %slot
  ret i32 %v
}
