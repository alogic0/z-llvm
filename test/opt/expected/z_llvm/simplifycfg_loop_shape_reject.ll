define i32 @simplifycfg_loop_shape_reject(i1 %cond, i32 %a, i32 %b) {
entry:
  br label %loop
loop:
  %v = phi i32 [ %a, %entry ], [ %b, %loop ]
  br i1 %cond, label %loop, label %exit
exit:
  ret i32 %v
}
