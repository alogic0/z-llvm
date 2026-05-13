define i1 @cvp_eq(i32 %x) {
entry:
  %c = icmp eq i32 %x, 0
  br i1 %c, label %then, label %else

then:
  ret i1 1

else:
  ret i1 1
}
