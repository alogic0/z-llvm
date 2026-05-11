define i32 @adce_nested_dead_diamond(i1 %outer, i1 %inner_cond, i32 %a) {
entry:
  br i1 %outer, label %left, label %right
left:
  br i1 %inner_cond, label %inner, label %left_join
inner:
  %x = add i32 %a, 1
  br label %left_join
left_join:
  br label %exit
right:
  %y = add i32 %a, 2
  br label %exit
exit:
  ret i32 %a
}
