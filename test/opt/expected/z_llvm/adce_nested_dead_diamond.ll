define i32 @adce_nested_dead_diamond(i1 %outer, i1 %inner_cond, i32 %a) {
entry:
  br label %left
left:
  br label %left_join
inner:
  br label %left_join
left_join:
  br label %exit
right:
  br label %exit
exit:
  ret i32 %a
}
