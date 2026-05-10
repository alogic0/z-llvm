define i1 @icmp_rel(i32 %x) {
entry:
  %a = icmp slt i32 1, 2
  %b = icmp sge i32 %x, %x
  %c = icmp ult i32 3, 4
  %d = and i1 %a, %b
  %e = and i1 %d, %c
  ret i1 %e
}
