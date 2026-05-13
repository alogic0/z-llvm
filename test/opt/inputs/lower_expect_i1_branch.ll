declare i1 @llvm.expect.i1(i1, i1) #0

define i32 @lower_expect(i1 %cond) {
entry:
  %e = call i1 @llvm.expect.i1(i1 %cond, i1 1)
  br i1 %e, label %hot, label %cold

hot:
  ret i32 1

cold:
  ret i32 0
}

attributes #0 = { nocallback nofree nosync nounwind willreturn memory(none) }
