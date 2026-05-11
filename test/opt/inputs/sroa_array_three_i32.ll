define i32 @sroa_array_three_i32(i32 %a, i32 %b, i32 %c) {
entry:
  %arr = alloca [3 x i32]
  %p0 = getelementptr [3 x i32], ptr %arr, i32 0, i32 0
  %p1 = getelementptr [3 x i32], ptr %arr, i32 0, i32 1
  %p2 = getelementptr [3 x i32], ptr %arr, i32 0, i32 2
  store i32 %a, ptr %p0
  store i32 %b, ptr %p1
  store i32 %c, ptr %p2
  %x = load i32, ptr %p0
  %y = load i32, ptr %p1
  %xy = add i32 %x, %y
  %z = load i32, ptr %p2
  %sum = add i32 %xy, %z
  ret i32 %sum
}
