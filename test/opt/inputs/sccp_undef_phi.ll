define i32 @sccp_undef_phi(i1 %c) {
entry:
  br i1 %c, label %then, label %else
then:
  br label %merge
else:
  br label %merge
merge:
  %p = phi i32 [ undef, %then ], [ 5, %else ]
  ret i32 %p
}
