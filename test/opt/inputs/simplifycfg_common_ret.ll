define i32 @common_ret(i1 %cond, i32 %a) {
entry:
  br i1 %cond, label %then, label %else
then:
  ret i32 %a
else:
  ret i32 %a
}
