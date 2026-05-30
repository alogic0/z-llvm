define i8 @shl_nsw_wrap() {
entry:
  ret i8 -128
}

define i8 @shl_nuw_wrap() {
entry:
  ret i8 0
}
