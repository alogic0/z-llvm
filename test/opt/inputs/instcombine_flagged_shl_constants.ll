define i8 @shl_nsw_wrap() {
entry:
  %x = shl nsw i8 64, 1
  ret i8 %x
}

define i8 @shl_nuw_wrap() {
entry:
  %x = shl nuw i8 128, 1
  ret i8 %x
}
