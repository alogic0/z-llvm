define i32 @vector_combine_extract_insert_mismatch(<2 x i32> %v, i32 %x) {
entry:
  %e = extractelement <2 x i32> %v, i64 0
  ret i32 %e
}
