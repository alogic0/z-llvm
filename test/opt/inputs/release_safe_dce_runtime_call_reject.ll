declare void @zig_panic(ptr)

define void @release_safe_dce_runtime_call_reject(ptr %msg) {
entry:
  %dead = add i32 1, 2
  call void @zig_panic(ptr %msg)
  ret void
}
