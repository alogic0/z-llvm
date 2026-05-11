define i32 @licm_header_load(i32 %a, ptr %p) {
entry:
  br label %header

header:
  %loaded = load i32, ptr %p
  %cond = icmp sgt i32 %loaded, 0
  br i1 %cond, label %body, label %exit

body:
  br label %latch

latch:
  br label %header

exit:
  ret i32 %a
}
