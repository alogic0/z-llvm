define i32 @select_fold(i1 %cond, i32 %a, i32 %b) {
entry:
  %x = select i1 1, i32 %a, i32 %b
  %y = select i1 %cond, i32 %x, i32 %x
  ret i32 %y
}
