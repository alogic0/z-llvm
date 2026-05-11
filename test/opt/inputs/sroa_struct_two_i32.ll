define i32 @sroa_struct_two_i32(i32 %a, i32 %b) {
entry:
  %agg = alloca { i32, i32 }
  %p0 = getelementptr { i32, i32 }, ptr %agg, i32 0, i32 0
  %p1 = getelementptr { i32, i32 }, ptr %agg, i32 0, i32 1
  store i32 %a, ptr %p0
  store i32 %b, ptr %p1
  %x = load i32, ptr %p0
  %y = load i32, ptr %p1
  %sum = add i32 %x, %y
  ret i32 %sum
}
