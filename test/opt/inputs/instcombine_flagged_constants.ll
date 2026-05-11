define i32 @instcombine_flagged_constants() {
entry:
  %x = add nuw i32 40, 2
  %y = mul nsw i32 %x, 1
  ret i32 %y
}
