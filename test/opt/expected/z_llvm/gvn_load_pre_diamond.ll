define i32 @gvn_load_pre_diamond(i1 %cond, ptr %p) {
entry:
  br i1 %cond, label %left, label %right
left:
  %left_load = load i32, ptr %p
  br label %join
right:
  %value.pre = load i32, ptr %p
  br label %join
join:
  %value = phi i32 [ %left_load, %left ], [ %value.pre, %right ]
  %side = phi i32 [ %left_load, %left ], [ 0, %right ]
  %sum = add i32 %side, %value
  ret i32 %sum
}
