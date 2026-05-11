define i32 @cast_bitpatterns() {
entry:
  %z = zext i8 -1 to i32
  %s = sext i8 255 to i32
  %sum = add i32 %z, %s
  ret i32 %sum
}
