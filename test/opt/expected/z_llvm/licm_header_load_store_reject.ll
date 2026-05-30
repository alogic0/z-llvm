define i32 @licm_header_load_store_reject(ptr %p, ptr %q, i32 %v, i32 %n) {
entry:
  br label %loop

loop:
  %i = phi i32 [ 0, %entry ], [ %next, %loop ]
  %loaded = load i32, ptr %p
  store i32 %v, ptr %q
  %next = add i32 %i, 1
  %cond = icmp slt i32 %next, %n
  br i1 %cond, label %loop, label %exit

exit:
  %i.lcssa = phi i32 [ %i, %loop ]
  %loaded.lcssa = phi i32 [ %loaded, %loop ]
  %sum.le = add i32 %loaded.lcssa, %i.lcssa
  ret i32 %sum.le
}
