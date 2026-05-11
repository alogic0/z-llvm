define i32 @mem2reg_single_store(i1 %cond, i32 %a) {
entry:
  %slot = alloca i32
  store i32 %a, ptr %slot
  br i1 %cond, label %left, label %right
left:
  %l = load i32, ptr %slot
  ret i32 %l
right:
  %r = load i32, ptr %slot
  ret i32 %r
}

