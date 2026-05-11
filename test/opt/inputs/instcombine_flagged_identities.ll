define i32 @instcombine_flagged_identities(i32 %a) {
entry:
  %x = add nsw i32 %a, 0
  %y = sub nuw i32 %x, 0
  %z = mul nsw i32 %y, 1
  %q = udiv exact i32 %z, 1
  ret i32 %q
}
