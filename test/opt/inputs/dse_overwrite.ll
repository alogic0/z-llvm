define i32 @dse_overwrite(i32 %a, i32 %b) {
entry:
  %slot = alloca i32
  store i32 %a, ptr %slot
  store i32 %b, ptr %slot
  %v = load i32, ptr %slot
  ret i32 %v
}
