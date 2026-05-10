define i32 @zero_gep(i32 %x) {
entry:
  %slot = alloca i32
  %p = getelementptr i32, ptr %slot, i32 0
  store i32 %x, ptr %p
  %v = load i32, ptr %p
  ret i32 %v
}
