define i32 @thread_non_phi_reject(i1 %c) {
entry:
  br i1 %c, label %then, label %else

then:
  ret i32 1

else:
  ret i32 0
}
