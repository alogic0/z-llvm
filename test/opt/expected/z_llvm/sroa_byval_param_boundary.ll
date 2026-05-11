define i32 @sroa_byval_param_boundary(ptr byval({ i32, i32 }) %agg) {
entry:
  %p0 = getelementptr { i32, i32 }, ptr %agg, i32 0, i32 0
  %x = load i32, ptr %p0
  ret i32 %x
}
