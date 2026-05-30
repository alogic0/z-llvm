define i32 @gvn_diamond_load_no_memory_phi(i1 %cond, ptr %p) {
entry:
  br i1 %cond, label %left, label %right
left:
  br label %join
right:
  br label %join
join:
  %second = load i32, ptr %p
  ret i32 %second
}
