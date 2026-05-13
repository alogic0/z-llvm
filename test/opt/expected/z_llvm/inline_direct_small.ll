define i32 @inline_direct_small(i32 %x) {
entry:
  %a.i = add i32 %x, 1
  ret i32 %a.i
}
