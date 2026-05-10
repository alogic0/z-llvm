define i32 @scalar_simplify() {
entry:
  %t = trunc i32 257 to i8
  %tw = zext i8 %t to i32
  %z = zext i8 7 to i32
  %s = sext i8 -1 to i32
  %d = udiv i32 12, 3
  %ed = udiv exact i32 12, 3
  %r = urem i32 14, 5
  %sd = sdiv i32 -9, 3
  %sr = srem i32 -10, 3
  %sum0 = add i32 %tw, %z
  %sum1 = add i32 %sum0, %s
  %sum2 = add i32 %sum1, %d
  %sum3 = add i32 %sum2, %ed
  %sum4 = add i32 %sum3, %r
  %sum5 = add i32 %sum4, %sd
  %sum6 = add i32 %sum5, %sr
  ret i32 %sum6
}
