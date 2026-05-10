define i32 @mem2reg_volatile_load(i32 %a) {
entry:
  %slot = alloca i32
  store i32 %a, ptr %slot
  %v = load volatile i32, ptr %slot, align 4
  ret i32 %v
}
