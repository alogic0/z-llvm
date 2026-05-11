@exported = alias i32 (), ptr @live

define internal i32 @live() {
entry:
  ret i32 1
}

