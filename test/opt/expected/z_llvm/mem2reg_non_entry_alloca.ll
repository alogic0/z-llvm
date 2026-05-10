define i32 @mem2reg_non_entry_alloca(i1 %cond, i32 %a) {
entry:
  br i1 %cond, label %then, label %else
then:
  %slot = alloca i32
  store i32 %a, ptr %slot
  %v = load i32, ptr %slot
  ret i32 %v
else:
  ret i32 0
}
