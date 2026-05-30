define i32 @sroa_inner_aggregate_load(i32 %a, i32 %b) {
entry:
  %agg = alloca { { i32, i32 }, i32 }
  %inner = getelementptr { { i32, i32 }, i32 }, ptr %agg, i32 0, i32 0
  %p0 = getelementptr { i32, i32 }, ptr %inner, i32 0, i32 0
  %p1 = getelementptr { i32, i32 }, ptr %inner, i32 0, i32 1
  store i32 %a, ptr %p0
  store i32 %b, ptr %p1
  %pair = load { i32, i32 }, ptr %inner
  %x = extractvalue { i32, i32 } %pair, 0
  %y = extractvalue { i32, i32 } %pair, 1
  %sum = add i32 %x, %y
  ret i32 %sum
}
