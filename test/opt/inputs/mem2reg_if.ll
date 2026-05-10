define i32 @mem2reg_if(i1 %cond, i32 %a, i32 %b) {
entry:
  %slot = alloca i32
  br i1 %cond, label %left, label %right
left:
  store i32 %a, ptr %slot
  br label %merge
right:
  store i32 %b, ptr %slot
  br label %merge
merge:
  %v = load i32, ptr %slot
  ret i32 %v
}
