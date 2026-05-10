define i32 @safe_scalar(i32 %a) {
entry:
  %sum1 = add i32 %a, 42
  ret i32 %sum1
}
