define i32 @sccp_select_same_arms(i1 %cond) {
entry:
  %v = select i1 %cond, i32 7, i32 7
  ret i32 %v
}
