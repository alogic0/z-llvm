define i32 @licm_nested(i32 %a, i1 %outer_cond) {
entry:
  br label %outer.header
outer.header:
  br i1 %outer_cond, label %inner.preheader, label %exit
inner.preheader:
  br label %inner.header
inner.header:
  %x = add i32 %a, 1
  %y = icmp sgt i32 %x, 0
  br i1 %y, label %inner.latch, label %outer.latch
inner.latch:
  br label %inner.header
outer.latch:
  br label %outer.header
exit:
  ret i32 %a
}
