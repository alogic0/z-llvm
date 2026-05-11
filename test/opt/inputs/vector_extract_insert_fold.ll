define i32 @vector_extract_insert_fold(<2 x i32> %v, i32 %x) {
entry:
  %i = insertelement <2 x i32> %v, i32 %x, i32 1
  %e = extractelement <2 x i32> %i, i32 1
  ret i32 %e
}
