@live_global = global i32 1

define internal i32 @helper(i32 %x) {
entry:
  ret i32 %x
}

define i32 @entry(i32 %a) {
entry:
  %r = call i32 @helper(i32 %a)
  ret i32 %r
}
