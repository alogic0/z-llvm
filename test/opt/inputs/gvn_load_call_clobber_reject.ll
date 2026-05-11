declare void @unknown()

define i32 @gvn_load_call_clobber_reject(ptr %p) {
entry:
  %x = load i32, ptr %p
  call void @unknown()
  %y = load i32, ptr %p
  %sum = add i32 %x, %y
  ret i32 %sum
}
