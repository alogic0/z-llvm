@h = internal global i32 7

define i32 @read_h() local_unnamed_addr {
entry:
  %v = load i32, ptr @h, align 4
  ret i32 %v
}
