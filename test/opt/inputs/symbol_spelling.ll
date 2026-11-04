@0 = internal global i32 11
@"0" = internal global i32 19
@mutable_state = internal global i32 7
@"reverse_state" = internal global i32 17
@escape_state = internal global i32 23
@alias_state = internal global i32 31
@"dotted.constant" = internal global i32 29
@unused_state = internal global i32 99
@spelling_alias = alias i32, ptr @alias_state

define i32 @spelling_store_load(i32 %x) {
entry:
  store i32 %x, ptr @"mutable\5Fstate"
  %v = load i32, ptr @mutable_state
  ret i32 %v
}

define i32 @spelling_reverse_store_load(i32 %x) {
entry:
  store i32 %x, ptr @reverse_state
  %v = load i32, ptr @"reverse\5fstate"
  ret i32 %v
}

define internal ptr @spelling_address() {
entry:
  ret ptr @"escape\5Fstate"
}

define i32 @spelling_escape_store_load(i32 %x) {
entry:
  %p = call ptr @spelling_address()
  store i32 %x, ptr %p
  %v = load i32, ptr @escape_state
  ret i32 %v
}

define i32 @spelling_alias_store_load(i32 %x) {
entry:
  store i32 %x, ptr @"spelling\5Falias"
  %v = load i32, ptr @alias_state
  ret i32 %v
}

define i32 @spelling_read_constants() {
entry:
  %a = load i32, ptr @0
  %b = load i32, ptr @"\30"
  %c = load i32, ptr @dotted.constant
  %scaled = mul i32 %a, 100
  %ab = add i32 %scaled, %b
  %v = add i32 %ab, %c
  ret i32 %v
}
