declare void @write_arg(ptr) #0

define i32 @gvn_argmemonly_call_no_clobber(ptr %p) {
entry:
  %right = alloca i32, align 4
  store i32 0, ptr %right, align 4
  %a = load i32, ptr %p, align 4
  call void @write_arg(ptr %right)
  %b = load i32, ptr %p, align 4
  %sum = add i32 %a, %b
  ret i32 %sum
}

attributes #0 = { memory(argmem: write) }
