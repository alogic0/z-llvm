define i32 @gvn_load_branch_clobber_reject(ptr %p, i1 %cond, i32 %v) {
entry:
  %first = load i32, ptr %p
  br i1 %cond, label %store, label %join
join:
  %second = load i32, ptr %p
  %sum = add i32 %first, %second
  ret i32 %sum
store:
  store i32 %v, ptr %p
  br label %join
}
