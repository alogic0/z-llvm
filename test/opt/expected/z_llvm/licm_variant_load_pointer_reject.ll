define i32 @licm_variant_load_pointer_reject(ptr %base) {
entry:
  br label %preheader
preheader:
  br label %loop
loop:
  %iv = phi i32 [ 0, %preheader ], [ %next, %loop ]
  %next = add i32 %iv, 1
  %again = icmp slt i32 %next, 4
  br i1 %again, label %loop, label %exit
exit:
  %iv.lcssa = phi i32 [ %iv, %loop ]
  %ptr.le = getelementptr i32, ptr %base, i32 %iv.lcssa
  %loaded.le = load i32, ptr %ptr.le
  ret i32 %loaded.le
}
