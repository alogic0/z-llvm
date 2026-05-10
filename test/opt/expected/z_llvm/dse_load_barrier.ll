define i32 @dse_load_barrier(i32 %a, i32 %b) {
entry:
  %slot = alloca i32
  store i32 %a, ptr %slot
  %v0 = load i32, ptr %slot
  store i32 %b, ptr %slot
  %v1 = load i32, ptr %slot
  %sum = add i32 %v0, %v1
  ret i32 %sum
}
