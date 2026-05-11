define i1 @instcombine_pointer_compare(ptr %p) {
entry:
  %a = icmp eq ptr null, null
  %b = icmp ne ptr %p, %p
  %r = and i1 %a, %b
  ret i1 %r
}
