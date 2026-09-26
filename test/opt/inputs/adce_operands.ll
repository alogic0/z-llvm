define i32 @adce_vector_result(i32 %x, i32 %index) {
entry:
  %a = add i32 %x, 3
  %b = add i32 %x, 4
  %i = and i32 %index, 1
  %v0 = insertelement <2 x i32> zeroinitializer, i32 %a, i32 %i
  %v1 = insertelement <2 x i32> zeroinitializer, i32 %b, i32 0
  %v2 = shufflevector <2 x i32> %v0, <2 x i32> %v1, <2 x i32> zeroinitializer
  %out = extractelement <2 x i32> %v2, i32 %i
  %dead = add i32 %x, 5
  ret i32 %out
}
