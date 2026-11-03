target datalayout = "e-m:e-p:64:64-i64:64-i128:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare void @pointer_stack_clobber()
declare ptr @pointer_stack_echo(ptr)
declare i64 @pointer_stack_read_byte(ptr)

define i64 @pointer_stack_roundtrip(ptr %value, i64 %live, ptr %output) {
entry:
  %slot = alloca ptr, align 8
  store ptr %value, ptr %slot, align 8
  %loaded = load ptr, ptr %slot, align 8
  store ptr %loaded, ptr %output, align 8
  %bits = ptrtoint ptr %loaded to i64
  %result = xor i64 %bits, %live
  ret i64 %result
}

define i64 @pointer_stack_pressure(ptr %a, ptr %b, ptr %c, ptr %d, ptr %e, ptr %output) {
entry:
  %s0 = alloca ptr, align 8
  %s1 = alloca ptr, align 8
  %s2 = alloca ptr, align 8
  %s3 = alloca ptr, align 8
  %s4 = alloca ptr, align 8
  call void @pointer_stack_clobber()
  store ptr %a, ptr %s0, align 8
  store ptr %b, ptr %s1, align 8
  store ptr %c, ptr %s2, align 8
  store ptr %d, ptr %s3, align 8
  store ptr %e, ptr %s4, align 8
  %v0 = load ptr, ptr %s0, align 8
  %v1 = load ptr, ptr %s1, align 8
  %v2 = load ptr, ptr %s2, align 8
  %v3 = load ptr, ptr %s3, align 8
  %v4 = load ptr, ptr %s4, align 8
  %o1 = getelementptr i8, ptr %output, i64 8
  %o2 = getelementptr i8, ptr %output, i64 16
  %o3 = getelementptr i8, ptr %output, i64 24
  %o4 = getelementptr i8, ptr %output, i64 32
  store ptr %v0, ptr %output, align 8
  store ptr %v1, ptr %o1, align 8
  store ptr %v2, ptr %o2, align 8
  store ptr %v3, ptr %o3, align 8
  store ptr %v4, ptr %o4, align 8
  %bits = ptrtoint ptr %v4 to i64
  ret i64 %bits
}

define i64 @pointer_stack_returned(ptr %value, i64 %live, ptr %output) {
entry:
  %slot = alloca ptr, align 8
  %returned = call ptr @pointer_stack_echo(ptr %value)
  store ptr %returned, ptr %slot, align 8
  %loaded = load ptr, ptr %slot, align 8
  store ptr %loaded, ptr %output, align 8
  %bits = ptrtoint ptr %loaded to i64
  %result = xor i64 %bits, %live
  ret i64 %result
}

define i64 @pointer_stack_object_address(i64 %live) {
entry:
  %object = alloca i8, align 1
  %slot = alloca ptr, align 8
  store i8 127, ptr %object, align 1
  store ptr %object, ptr %slot, align 8
  %address = load ptr, ptr %slot, align 8
  %wide = call i64 @pointer_stack_read_byte(ptr %address)
  %result = xor i64 %wide, %live
  ret i64 %result
}
