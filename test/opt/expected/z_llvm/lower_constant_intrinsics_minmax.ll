declare i32 @llvm.smin.i32(i32, i32) #0
declare i32 @llvm.umax.i32(i32, i32) #0

define i32 @same_min(i32 %a) {
entry:
  ret i32 %a
}

define i32 @const_umax() {
entry:
  ret i32 7
}

attributes #0 = { nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none) }
