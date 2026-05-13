declare i32 @llvm.expect.i32(i32, i32)

define i32 @expect_i32_preserve(i32 %x) {
entry:
  %e = call i32 @llvm.expect.i32(i32 %x, i32 7)
  ret i32 %e
}
