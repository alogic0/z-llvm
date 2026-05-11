define i32 @early_cse_unreachable_store_not_clobber(ptr %p, i1 %cond, i32 %v) {
entry:
  %first = load i32, ptr %p
  br i1 %cond, label %side, label %join

side:
  store i32 %v, ptr %p
  ret i32 0

join:
  %second = load i32, ptr %p
  ret i32 %second
}
