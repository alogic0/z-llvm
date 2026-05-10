target triple = "x86_64-unknown-linux-gnu"

define i32 @conditional_return(i1 %cond, i32 %a, i32 %b) {
entry:
  br i1 %cond, label %then, label %else
then:
  ret i32 %a
else:
  ret i32 %b
}
