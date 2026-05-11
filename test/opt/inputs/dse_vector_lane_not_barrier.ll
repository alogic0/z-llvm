define i32 @dse_vector_lane_not_barrier(i32 %a, i32 %b, <2 x i32> %v) {
entry:
  %slot = alloca i32
  store i32 %a, ptr %slot, align 4
  %lane = extractelement <2 x i32> %v, i32 0
  store i32 %b, ptr %slot, align 4
  %loaded = load i32, ptr %slot, align 4
  %sum = add i32 %loaded, %lane
  ret i32 %sum
}
