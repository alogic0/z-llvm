define <2 x i32> @vector_shuffle_undef_mask_preserve(<2 x i32> %a, <2 x i32> %b) {
entry:
  %s = shufflevector <2 x i32> %a, <2 x i32> %b, <2 x i32> <i32 0, i32 undef>
  ret <2 x i32> %s
}
