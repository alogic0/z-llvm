define i32 @dominating_expr(i32 %a, i1 %c) {
entry:
  %x = add i32 %a, 1
  br i1 %c, label %then, label %merge
then:
  %y = add i32 %a, 1
  br label %merge
merge:
  %z = phi i32 [ %x, %entry ], [ %y, %then ]
  ret i32 %z
}
