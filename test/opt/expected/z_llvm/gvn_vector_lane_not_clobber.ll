define i32 @gvn_vector_lane_not_clobber(ptr %p, <2 x i32> %v) {
entry:
  %lane = extractelement <2 x i32> %v, i32 0
  %b = load i32, ptr %p, align 4
  %sum = add i32 %b, %lane
  ret i32 %sum
}
