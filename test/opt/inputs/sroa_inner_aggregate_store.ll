define i32 @sroa_inner_aggregate_store({ i32, i32 } %pair) {
entry:
  %agg = alloca { { i32, i32 }, i32 }
  %inner = getelementptr { { i32, i32 }, i32 }, ptr %agg, i32 0, i32 0
  store { i32, i32 } %pair, ptr %inner
  %p0 = getelementptr { i32, i32 }, ptr %inner, i32 0, i32 0
  %p1 = getelementptr { i32, i32 }, ptr %inner, i32 0, i32 1
  %x = load i32, ptr %p0
  %y = load i32, ptr %p1
  %sum = add i32 %x, %y
  ret i32 %sum
}
