declare i32 @pure(i32) #0

define i32 @simplifycfg_hoist_same_readnone_call_ret(i1 %c, i32 %x) {
entry:
  br i1 %c, label %left, label %right

left:
  %a = call i32 @pure(i32 %x)
  ret i32 %a

right:
  %b = call i32 @pure(i32 %x)
  ret i32 %b
}

attributes #0 = { memory(none) }
