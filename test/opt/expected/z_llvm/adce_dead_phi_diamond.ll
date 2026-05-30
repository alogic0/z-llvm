define i32 @adce_dead_phi_diamond(i1 %cond, i32 %a) {
entry:
  br label %left
left:
  br label %join
right:
  br label %join
join:
  ret i32 0
}
