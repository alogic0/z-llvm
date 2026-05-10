define i32 @gep_memory(i32 %a) {
entry:
  %slot = alloca i32
  %p = getelementptr i32, ptr %slot, i32 0
  store i32 %a, ptr %p
  %v = load i32, ptr %p
  ret i32 %v
}
