declare void @readonly_call(ptr) #0

define i32 @early_cse_readonly_call_no_clobber(ptr %p) {
entry:
  %x = load i32, ptr %p
  call void @readonly_call(ptr %p)
  %y = load i32, ptr %p
  %sum = add i32 %x, %y
  ret i32 %sum
}

attributes #0 = { nounwind memory(read) }
