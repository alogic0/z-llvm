define i32 @vector_lane_dead_dce(<2 x i32> %v, i32 %x) {
entry:
  ret i32 %x
}
