define i32 @gvn_load_pre_diamond(i1 %cond, ptr %p) {
entry:
  br i1 %cond, label %left, label %right
left:
  %left_load = load i32, ptr %p
  br label %join
right:
  br label %join
join:
  %side = phi i32 [ %left_load, %left ], [ 0, %right ]
  %value = load i32, ptr %p
  %sum = add i32 %side, %value
  ret i32 %sum
}
