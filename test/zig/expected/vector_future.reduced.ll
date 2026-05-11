source_filename = "vector_future"

define <2 x i32> @add_vector(<2 x i32> %a, <2 x i32> %b) {
entry:
  %sum = add <2 x i32> %a, %b
  ret <2 x i32> %sum
}
