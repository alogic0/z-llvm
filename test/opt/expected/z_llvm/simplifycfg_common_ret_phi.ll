declare void @side()

define i32 @simplifycfg_common_ret_phi(i1 %c, i1 %d, ptr %p) {
entry:
  br i1 %c, label %left, label %right
left:
  br i1 %d, label %join, label %common.ret1
right:
  call void @side()
  br label %join
common.ret1:
  %common.ret1.op = phi i32 [ %y, %join ], [ 0, %left ]
  ret i32 %common.ret1.op
join:
  %y = load i32, ptr %p
  br label %common.ret1
}
