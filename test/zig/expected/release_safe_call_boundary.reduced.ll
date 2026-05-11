source_filename = "release_safe_call_boundary"

declare void @zig_panic(ptr)

define void @release_safe_call_boundary(i1 %ok, ptr %msg) {
entry:
  br i1 %ok, label %cont, label %panic, !prof !0
panic:
  call void @zig_panic(ptr %msg)
  unreachable
cont:
  ret void
}

!0 = !{!"branch_weights", i32 1000, i32 1}
