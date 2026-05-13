define i32 @loop_simplifycfg_const_body_branch(i32 %n) {
entry:
  br label %header

header:
  %i = phi i32 [ 0, %entry ], [ %inc, %header ]
  %inc = add i32 %i, 1
  %cond = icmp slt i32 %inc, %n
  br i1 %cond, label %header, label %exit

exit:
  %inc.lcssa = phi i32 [ %inc, %header ]
  ret i32 %inc.lcssa
}
