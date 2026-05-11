define i32 @mem2reg_single_store(i1 %cond, i32 %a) {
entry:
  br i1 %cond, label %left, label %right
left:
  ret i32 %a
right:
  ret i32 %a
}

