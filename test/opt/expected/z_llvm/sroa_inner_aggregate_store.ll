define i32 @sroa_inner_aggregate_store({ i32, i32 } %pair) {
entry:
  %pair.fca.0.extract = extractvalue { i32, i32 } %pair, 0
  %pair.fca.1.extract = extractvalue { i32, i32 } %pair, 1
  %sum = add i32 %pair.fca.0.extract, %pair.fca.1.extract
  ret i32 %sum
}
