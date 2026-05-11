define i32 @early_cse_vector_lane_store_forward(i32 %x, <2 x i32> %v) {
entry:
  %slot = alloca i32
  store i32 %x, ptr %slot, align 4
  %lane = extractelement <2 x i32> %v, i32 0
  %sum = add i32 %x, %lane
  ret i32 %sum
}
