define <2 x i32> @vector_select_same_arms(i1 %cond, <2 x i32> %v) {
entry:
  ret <2 x i32> %v
}
