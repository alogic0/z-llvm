declare i32 @llvm.smin.i32(i32, i32) #0
declare i32 @llvm.umax.i32(i32, i32) #0

define i32 @same_min(i32 %a) {
entry:
  %r = tail call i32 @llvm.smin.i32(i32 %a, i32 %a)
  ret i32 %r
}

define i32 @const_umax() {
entry:
  %r = tail call i32 @llvm.umax.i32(i32 4, i32 7)
  ret i32 %r
}

attributes #0 = { nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none) }
