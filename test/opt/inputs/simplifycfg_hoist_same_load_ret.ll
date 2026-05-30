define i32 @simplifycfg_hoist_same_load_ret(i1 %c, ptr %p) {
entry:
  br i1 %c, label %left, label %right

left:
  %a = load i32, ptr %p
  ret i32 %a

right:
  %b = load i32, ptr %p
  ret i32 %b
}
