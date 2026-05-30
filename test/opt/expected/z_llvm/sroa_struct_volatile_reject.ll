define i32 @sroa_struct_volatile_reject(i32 %a) {
entry:
  %agg.sroa.0 = alloca i32
  store volatile i32 %a, ptr %agg.sroa.0
  %agg.sroa.0.0.agg.sroa.0.0.x = load i32, ptr %agg.sroa.0
  ret i32 %agg.sroa.0.0.agg.sroa.0.0.x
}
