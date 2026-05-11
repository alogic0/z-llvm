declare void @unknown()

define void @dse_unknown_call_barrier(ptr %p, i32 %a, i32 %b) {
entry:
  store i32 %a, ptr %p, align 4
  call void @unknown()
  store i32 %b, ptr %p, align 4
  ret void
}
