$grp = comdat any

@member = internal global i32 1, comdat($grp)
@dead = internal global i32 2

define internal i32 @helper(i32 %x) comdat($grp) {
entry:
  ret i32 %x
}

define internal i32 @dead_fn(i32 %x) {
entry:
  ret i32 %x
}
