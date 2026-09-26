@dce_value = internal global i32 23
@dce_pointer_array = global [1 x ptr] [ptr @dce_value]
@dce_callback = global ptr @dce_middle
@dce_middle = internal alias i32 (), ptr @dce_leaf
@dce_export = alias i32 (), ptr @dce_middle

define internal i32 @dce_leaf() {
entry:
  ret i32 19
}

define ptr @dce_alias_pointer() {
entry:
  ret ptr @dce_middle
}

define i32 @dce_call_callback() {
entry:
  %p = load ptr, ptr @dce_callback
  %v = call i32 %p()
  ret i32 %v
}

define i32 @dce_read_array() {
entry:
  %p = load ptr, ptr @dce_pointer_array
  %v = load i32, ptr %p
  ret i32 %v
}

define i32 @dce_read_expression() {
entry:
  %v = load i32, ptr getelementptr (i32, ptr @dce_value, i64 0)
  ret i32 %v
}
