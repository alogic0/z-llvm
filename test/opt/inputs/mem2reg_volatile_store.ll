define i32 @mem2reg_volatile_store(i32 %a) {
entry:
  %slot = alloca i32
  store volatile i32 %a, ptr %slot, align 4
  %v = load i32, ptr %slot
  ret i32 %v
}
