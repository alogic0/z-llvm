define i32 @sroa_struct_volatile_reject(i32 %a) {
entry:
  %agg = alloca { i32, i32 }
  %p0 = getelementptr { i32, i32 }, ptr %agg, i32 0, i32 0
  store volatile i32 %a, ptr %p0
  %x = load i32, ptr %p0
  ret i32 %x
}
