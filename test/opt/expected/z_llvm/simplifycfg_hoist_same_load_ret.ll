define i32 @simplifycfg_hoist_same_load_ret(i1 %c, ptr %p) {
entry:
  %a = load i32, ptr %p
  ret i32 %a
}
