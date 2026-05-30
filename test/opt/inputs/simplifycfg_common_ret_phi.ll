declare void @side()

define i32 @simplifycfg_common_ret_phi(i1 %c, i1 %d, ptr %p) {
entry:
  br i1 %c, label %left, label %right

left:
  br i1 %d, label %join, label %common.ret

right:
  call void @side()
  br label %join

common.ret:
  ret i32 0

join:
  %y = load i32, ptr %p
  ret i32 %y
}
