define i32 @gvn_vector_lane_not_clobber(ptr %p, <2 x i32> %v) {
entry:
  %a = load i32, ptr %p, align 4
  %lane = extractelement <2 x i32> %v, i32 0
  %sum = add i32 %a, %lane
  ret i32 %sum
}
