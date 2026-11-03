declare i32 @zllvm_varargs_one(ptr, ...)
declare i32 @zllvm_varargs_two(ptr, ptr, ...)
declare noalias ptr @zllvm_alloc(i64)
declare void @free(ptr)

define i32 @exercise_one(i32 %value, ptr %p) {
entry:
  %live = add i32 %value, 17
  %result = call i32 (ptr, ...) @zllvm_varargs_one(ptr %p, i32 %value)
  %sum = add i32 %result, %live
  ret i32 %sum
}

define i32 @exercise_two(i32 %value, ptr %p, ptr %q) {
entry:
  %live = add i32 %value, 29
  %result = call i32 (ptr, ptr, ...) @zllvm_varargs_two(ptr %p, ptr %q, i32 %value)
  %sum = add i32 %result, %live
  ret i32 %sum
}

define i32 @exercise_immediate(ptr %p) {
entry:
  %result = call i32 (ptr, ...) @zllvm_varargs_one(ptr %p, i32 4294967295)
  ret i32 %result
}

define i32 @exercise_heap() {
entry:
  %p = call noalias ptr @zllvm_alloc(i64 4)
  store i32 123, ptr %p, align 4
  %value = load i32, ptr %p, align 4
  call void @free(ptr %p)
  ret i32 %value
}

define i32 @exercise_one_no_live(i32 %value, ptr %p) {
entry:
  %result = call i32 (ptr, ...) @zllvm_varargs_one(ptr %p, i32 %value)
  ret i32 %result
}

define i32 @exercise_heap_value(i32 %value) {
entry:
  %p = call noalias ptr @zllvm_alloc(i64 4)
  store i32 %value, ptr %p, align 4
  %loaded = load i32, ptr %p, align 4
  call void @free(ptr %p)
  ret i32 %loaded
}
