declare i32 @external_read(ptr) memory(read) norecurse

define i32 @leaf(i32 %x) memory(none) norecurse {
entry:
  %a = add i32 %x, 1
  ret i32 %a
}

define i32 @load_only(ptr %p) memory(read) norecurse {
entry:
  %v = load i32, ptr %p, align 4
  ret i32 %v
}

define i32 @caller(i32 %x, ptr %p) memory(read) norecurse {
entry:
  %a = call i32 @leaf(i32 %x)
  %b = call i32 @external_read(ptr %p)
  %c = add i32 %a, %b
  ret i32 %c
}
