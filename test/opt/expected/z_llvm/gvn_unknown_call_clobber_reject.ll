declare void @unknown(ptr)

define i32 @gvn_unknown_call_clobber_reject(ptr %p) {
entry:
  %a = load i32, ptr %p, align 4
  call void @unknown(ptr %p)
  %b = load i32, ptr %p, align 4
  %sum = add i32 %a, %b
  ret i32 %sum
}
