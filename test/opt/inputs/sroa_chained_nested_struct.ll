define i32 @sroa_chained_nested_struct(i32 %a, i32 %b, i32 %c) {
entry:
  %agg = alloca { { i32, i32 }, i32 }
  %inner = getelementptr { { i32, i32 }, i32 }, ptr %agg, i32 0, i32 0
  %p0 = getelementptr { i32, i32 }, ptr %inner, i32 0, i32 0
  %p1 = getelementptr { i32, i32 }, ptr %inner, i32 0, i32 1
  %p2 = getelementptr { { i32, i32 }, i32 }, ptr %agg, i32 0, i32 1
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
