declare i32 @llvm.expect.i32(i32, i32) #0

define i32 @expect_i32_preserve(i32 %x) {
entry:
  ret i32 %x
}

attributes #0 = { nocallback nofree nosync nounwind willreturn memory(none) }
