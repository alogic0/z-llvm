define i32 @optional_ptr_value(ptr %p) {
entry:
  %is_null = icmp eq ptr %p, null
  br i1 %is_null, label %none, label %some
some:
  %v = load i32, ptr %p, align 4
  ret i32 %v
none:
  ret i32 -1
}
