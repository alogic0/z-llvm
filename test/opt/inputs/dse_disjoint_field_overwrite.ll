define void @dse_disjoint_field_overwrite(ptr %p, i32 %a, i32 %b, i32 %c) {
entry:
  %field1 = getelementptr i8, ptr %p, i64 4
  store i32 %a, ptr %p, align 4
  store i32 %b, ptr %field1, align 4
  store i32 %c, ptr %p, align 4
  ret void
}
