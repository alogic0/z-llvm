define i1 @cvp_eq(i32 %x) {
entry:
  %c = icmp eq i32 %x, 0
  br i1 %c, label %then, label %else

then:
  %again = icmp eq i32 %x, 0
  ret i1 %again

else:
  %neq = icmp ne i32 %x, 0
  ret i1 %neq
}
