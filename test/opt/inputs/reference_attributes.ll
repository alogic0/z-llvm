; Attribute groups must not hide ordinary loads, stores, calls or alias uses.
@attribute_constant = internal global i32 23, align 4
@attribute_mutable = internal global i32 0, align 4
@attribute_dead = internal global i32 99
@attribute_a = internal unnamed_addr constant i32 7
@attribute_b = internal unnamed_addr constant i32 7
@attribute_alias = alias i32, ptr @attribute_mutable

define i32 @attribute_read_constant(i32 noundef %x) #0 {
entry:
  %constant = load i32, ptr @attribute_constant
  %sum = add i32 %constant, %x
  ret i32 %sum
}

define i32 @attribute_store_load(i32 noundef %x) #0 {
entry:
  store i32 %x, ptr @"attribute_mut\61ble"
  %loaded = load i32, ptr @attribute_mutable
  ret i32 %loaded
}

define internal i32 @attribute_helper(i32 noundef %x) #1 {
entry:
  %sum = add i32 %x, 5
  ret i32 %sum
}

define i32 @attribute_call_chain(i32 noundef %x) #0 {
entry:
  %called = call noundef i32 @attribute_helper(i32 noundef %x) #1
  store i32 %called, ptr @attribute_mutable
  %loaded = load i32, ptr @attribute_mutable
  ret i32 %loaded
}

define i32 @attribute_alias_load(i32 noundef %x) #0 {
entry:
  store i32 %x, ptr @attribute_alias
  %loaded = load i32, ptr @attribute_mutable
  ret i32 %loaded
}

define i32 @attribute_merged_load() #0 {
entry:
  %a = load i32, ptr @attribute_a
  %b = load i32, ptr @attribute_b
  %sum = add i32 %a, %b
  ret i32 %sum
}

define internal i32 @attribute_dead_function() #1 {
entry:
  ret i32 99
}

attributes #0 = { nounwind "frame-pointer"="all" "target-cpu"="x86-64" "target-features"="+sse2" }
attributes #1 = { nocallback nofree nosync nounwind willreturn memory(none) }
