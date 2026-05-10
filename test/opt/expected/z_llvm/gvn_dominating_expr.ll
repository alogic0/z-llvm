define i32 @dominating_expr(i32 %a, i1 %c) {
entry:
  %x = add i32 %a, 1
  br i1 %c, label %then, label %merge
then:
  br label %merge
merge:
  ret i32 %x
}
