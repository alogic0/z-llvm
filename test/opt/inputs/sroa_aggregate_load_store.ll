define i32 @sroa_aggregate_load_store(i32 %a, i32 %b) {
entry:
  %slot = alloca { i32, i32 }
  %agg0 = insertvalue { i32, i32 } poison, i32 %a, 0
  %agg1 = insertvalue { i32, i32 } %agg0, i32 %b, 1
  store { i32, i32 } %agg1, ptr %slot
  %loaded = load { i32, i32 }, ptr %slot
  %field = extractvalue { i32, i32 } %loaded, 1
  ret i32 %field
}
