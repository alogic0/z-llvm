@h = internal global i32 7
declare void @use(ptr) local_unnamed_addr

define i32 @store_h(i32 %x) local_unnamed_addr {
entry:
  store i32 %x, ptr @h, align 4
  %v = load i32, ptr @h, align 4
  ret i32 %v
}

define void @addr_h() local_unnamed_addr {
entry:
  call void @use(ptr @h)
  ret void
}
