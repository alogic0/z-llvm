declare i32 @external_read(ptr) #0

define i32 @leaf(i32 %x) #1 {
entry:
  %a = add i32 %x, 1
  ret i32 %a
}

define i32 @load_only(ptr readonly captures(none) %p) #2 {
entry:
  %v = load i32, ptr %p, align 4
  ret i32 %v
}

define i32 @caller(i32 %x, ptr %p) #3 {
entry:
  %a = call i32 @leaf(i32 %x)
  %b = call i32 @external_read(ptr %p)
  %c = add i32 %a, %b
  ret i32 %c
}

attributes #0 = { norecurse memory(read) }
attributes #1 = { mustprogress nofree norecurse nosync nounwind willreturn memory(none) }
attributes #2 = { mustprogress nofree norecurse nosync nounwind willreturn memory(argmem: read) }
attributes #3 = { nofree norecurse memory(read) }
