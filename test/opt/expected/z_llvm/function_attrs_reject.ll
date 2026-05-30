declare void @unknown()

define i32 @store_reject(ptr writeonly captures(none) initializes((0, 4)) %p, i32 returned %v) memory(argmem: write) norecurse nofree nosync nounwind mustprogress willreturn {
entry:
  store i32 %v, ptr %p, align 4
  ret i32 %v
}

define i32 @unknown_call_reject(i32 returned %x) {
entry:
  call void @unknown()
  ret i32 %x
}

define i32 @self_recursive(i32 %x) nofree nosync nounwind {
entry:
  %r = call i32 @self_recursive(i32 %x)
  ret i32 %r
}

define i32 @mutual_a(i32 %x) nofree nosync nounwind {
entry:
  %r = call i32 @mutual_b(i32 %x)
  ret i32 %r
}

define i32 @mutual_b(i32 %x) nofree nosync nounwind {
entry:
  %r = call i32 @mutual_a(i32 %x)
  ret i32 %r
}
