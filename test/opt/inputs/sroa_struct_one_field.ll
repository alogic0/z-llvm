define i32 @sroa_struct_one_field(i32 %a) {
entry:
  %agg = alloca { i32, i32 }
  %p1 = getelementptr { i32, i32 }, ptr %agg, i32 0, i32 1
  store i32 %a, ptr %p1
  %x = load i32, ptr %p1
  ret i32 %x
}
