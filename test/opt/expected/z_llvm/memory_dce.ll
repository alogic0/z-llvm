define i32 @memory_dce(i32 %a) {
entry:
  %slot = alloca i32
  store i32 %a, ptr %slot
  ret i32 %a
}
