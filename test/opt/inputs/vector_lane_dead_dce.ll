define i32 @vector_lane_dead_dce(<2 x i32> %v, i32 %x) {
entry:
  %i = insertelement <2 x i32> %v, i32 %x, i32 0
  %e = extractelement <2 x i32> %i, i32 0
  %s = shufflevector <2 x i32> %i, <2 x i32> %v, <2 x i32> <i32 0, i32 3>
  ret i32 %x
}
