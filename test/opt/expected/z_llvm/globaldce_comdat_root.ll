$grp = comdat any

@member = internal global i32 1, comdat($grp)

define internal i32 @helper(i32 %x) comdat($grp) {
entry:
  ret i32 %x
}
