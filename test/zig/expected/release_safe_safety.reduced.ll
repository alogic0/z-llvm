source_filename = "release_safe_safety"

define i32 @release_safe_bounds(i1 %ok, i32 %value) {
entry:
  br i1 %ok, label %cont, label %trap, !prof !0
trap:
  unreachable
cont:
  ret i32 %value
}

!0 = !{!"branch_weights", i32 2000, i32 1}
