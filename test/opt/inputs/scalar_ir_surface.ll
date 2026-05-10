define i32 @scalar_surface(i64 %wide, i8 %small, i32 %a, i32 %b) {
entry:
  %t = trunc i64 %wide to i32
  %z = zext i8 %small to i32
  %s = sext i8 %small to i32
  %d = udiv exact i32 %a, 3
  %r = srem i32 %b, 5
  %sum0 = add nsw i32 %t, %z
  %sum1 = add nuw i32 %sum0, %s
  %sum2 = add i32 %sum1, %d
  %sum3 = add i32 %sum2, %r
  %f = freeze i32 %sum3
  ret i32 %f
}
