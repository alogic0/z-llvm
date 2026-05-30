define i32 @sroa_inner_aggregate_load(i32 %a, i32 %b) {
entry:
  %pair.fca.0.insert = insertvalue { i32, i32 } poison, i32 %a, 0
  %pair.fca.1.insert = insertvalue { i32, i32 } %pair.fca.0.insert, i32 %b, 1
  %x = extractvalue { i32, i32 } %pair.fca.1.insert, 0
  %y = extractvalue { i32, i32 } %pair.fca.1.insert, 1
  %sum = add i32 %x, %y
  ret i32 %sum
}
