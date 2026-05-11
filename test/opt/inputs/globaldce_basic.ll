@live_global = global i32 1
@dead_global = internal global i32 2

define internal i32 @helper(i32 %x) {
entry:
  ret i32 %x
}

define internal i32 @dead(i32 %x) {
entry:
  ret i32 %x
}

define i32 @entry(i32 %a) {
entry:
  %r = call i32 @helper(i32 %a)
  ret i32 %r
}
