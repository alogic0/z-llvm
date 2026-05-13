declare i1 @llvm.expect.i1(i1, i1) #0

define i32 @lower_expect(i1 %cond) {
entry:
  br i1 %cond, label %hot, label %cold, !prof !0

hot:
  ret i32 1

cold:
  ret i32 0
}

attributes #0 = { nocallback nofree nosync nounwind willreturn memory(none) }

!0 = !{!"branch_weights", !"expected", i32 2000, i32 1}
