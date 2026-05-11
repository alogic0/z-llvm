define i32 @extract_lane(<2 x i32> %v, i32 %idx) {
entry:
  %r = extractelement <2 x i32> %v, i32 %idx
  ret i32 %r
}

define <2 x i32> @insert_lane(<2 x i32> %v, i32 %x, i32 %idx) {
entry:
  %r = insertelement <2 x i32> %v, i32 %x, i32 %idx
  ret <2 x i32> %r
}

define <2 x i32> @shuffle_lane(<2 x i32> %a, <2 x i32> %b) {
entry:
  %r = shufflevector <2 x i32> %a, <2 x i32> %b, <2 x i32> <i32 0, i32 3>
  ret <2 x i32> %r
}
