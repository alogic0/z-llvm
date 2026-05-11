define i32 @sccp_phi_edge() {
entry:
  %cond = icmp eq i32 1, 1
  br i1 %cond, label %then, label %else
then:
  br label %merge
else:
  br label %merge
merge:
  %p = phi i32 [ 42, %then ], [ 13, %else ]
  ret i32 %p
}
