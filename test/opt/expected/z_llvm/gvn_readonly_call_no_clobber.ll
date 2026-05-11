declare void @observe(ptr) #0

define i32 @gvn_readonly_call_no_clobber(ptr %p) {
entry:
  %a = load i32, ptr %p, align 4
  call void @observe(ptr %p)
  %sum = add i32 %a, %a
  ret i32 %sum
}

attributes #0 = { nounwind memory(read) }
