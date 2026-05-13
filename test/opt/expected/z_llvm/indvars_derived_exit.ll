define i32 @indvars_derived_exit(i32 %n) {
entry:
  br label %loop

loop:
  br i1 1, label %exit, label %loop

exit:
  %0 = shl i32 %n, 1
  %1 = add i32 %0, 3
  ret i32 %1
}
