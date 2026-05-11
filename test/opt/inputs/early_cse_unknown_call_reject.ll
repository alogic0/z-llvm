declare void @unknown()

define i32 @early_cse_unknown_call_reject(i32 %a, ptr %p) {
entry:
  store i32 %a, ptr %p
  call void @unknown()
  %x = load i32, ptr %p
  ret i32 %x
}
