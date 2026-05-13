define i32 @sroa_aggregate_load_store(i32 %a, i32 %b) {
entry:
  %agg0 = insertvalue { i32, i32 } poison, i32 %a, 0
  %agg1 = insertvalue { i32, i32 } %agg0, i32 %b, 1
  %agg1.fca.0.extract = extractvalue { i32, i32 } %agg1, 0
  %agg1.fca.1.extract = extractvalue { i32, i32 } %agg1, 1
  %loaded.fca.0.insert = insertvalue { i32, i32 } poison, i32 %agg1.fca.0.extract, 0
  %loaded.fca.1.insert = insertvalue { i32, i32 } %loaded.fca.0.insert, i32 %agg1.fca.1.extract, 1
  %field = extractvalue { i32, i32 } %loaded.fca.1.insert, 1
  ret i32 %field
}
