declare void @unknown()

define i32 @store_reject(ptr %p, i32 %v) norecurse {
entry:
  store i32 %v, ptr %p, align 4
  ret i32 %v
}

define i32 @unknown_call_reject(i32 %x) {
entry:
  call void @unknown()
  ret i32 %x
}

define i32 @self_recursive(i32 %x) {
entry:
  %r = call i32 @self_recursive(i32 %x)
  ret i32 %r
}

define i32 @mutual_a(i32 %x) {
entry:
  %r = call i32 @mutual_b(i32 %x)
  ret i32 %r
}

define i32 @mutual_b(i32 %x) {
entry:
  %r = call i32 @mutual_a(i32 %x)
  ret i32 %r
}
