define i32 @early_cse_store_to_load(i32 %a) {
entry:
  %slot = alloca i32
  store i32 %a, ptr %slot
  ret i32 %a
}
