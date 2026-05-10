define i32 @safe_scalar(i32 %a) {
entry:
  %d = udiv i32 %a, 1
  %r = srem i32 %d, 1
  %f = freeze i32 42
  %sum0 = add i32 %r, %f
  %sum1 = add i32 %sum0, %d
  ret i32 %sum1
}
