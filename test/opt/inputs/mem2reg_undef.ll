define i32 @mem2reg_undef() {
entry:
  %slot = alloca i32
  %v = load i32, ptr %slot
  ret i32 %v
}
