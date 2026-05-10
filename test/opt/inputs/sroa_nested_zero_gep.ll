define i32 @sroa_nested_zero_gep(i32 %a) {
entry:
  %slot = alloca i32
  %p0 = getelementptr i32, ptr %slot, i32 0
  %p1 = getelementptr i32, ptr %p0, i32 0
  store i32 %a, ptr %p1
  %v = load i32, ptr %p0
  ret i32 %v
}
