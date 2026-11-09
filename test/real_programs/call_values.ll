target triple = "x86_64-unknown-linux-gnu"
target datalayout = "e-m:e-p:64:64-i64:64-i128:128-n8:16:32:64-S128"

declare void @call_values_clobber()

; These LLVM-defined callees never observe their undefined parameters. Keeping
; those parameters free of noundef makes every oracle execution well defined.
define i64 @call_values_ignore_i32(i64 %a, i32 %ignored, i64 %b, ptr %out) #0 {
entry:
  call void @call_values_clobber()
  br label %finish
finish:
  %sum = add i64 %a, %b
  store i64 %sum, ptr %out, align 1
  %r = xor i64 %sum, 17
  ret i64 %r
}

define i64 @call_values_ignore_i64(i64 %a, i64 %ignored, i64 %b, ptr %out) #0 {
entry:
  call void @call_values_clobber()
  br label %finish
finish:
  %sum = add i64 %a, %b
  store i64 %sum, ptr %out, align 1
  %r = xor i64 %sum, 37
  ret i64 %r
}

define i64 @call_values_ignore_ptr(i64 %a, ptr %ignored, i64 %b, ptr %out) #0 {
entry:
  call void @call_values_clobber()
  br label %finish
finish:
  %sum = add i64 %a, %b
  store i64 %sum, ptr %out, align 1
  %r = xor i64 %sum, 53
  ret i64 %r
}

define i64 @call_values_undef_i32(i64 %a, i64 %b, ptr %out, i64 %cookie, ptr %p) {
entry:
  %v = call i64 @call_values_ignore_i32(i64 %a, i32 undef, i64 %b, ptr %out)
  br label %finish
finish:
  %bits = ptrtoint ptr %p to i64
  %r0 = add i64 %v, %a
  %r1 = xor i64 %r0, %b
  %r2 = xor i64 %r1, %cookie
  %r3 = xor i64 %r2, %bits
  ret i64 %r3
}

define i64 @call_values_poison_i64(i64 %a, i64 %b, ptr %out, i64 %cookie, ptr %p) {
entry:
  %v = call i64 @call_values_ignore_i64(i64 %a, i64 poison, i64 %b, ptr %out)
  br label %finish
finish:
  %bits = ptrtoint ptr %p to i64
  %r0 = add i64 %v, %a
  %r1 = xor i64 %r0, %b
  %r2 = xor i64 %r1, %cookie
  %r3 = xor i64 %r2, %bits
  ret i64 %r3
}

define i64 @call_values_undef_i64(i64 %a, i64 %b, ptr %out, i64 %cookie, ptr %p) {
entry:
  %v = call i64 @call_values_ignore_i64(i64 %a, i64 undef, i64 %b, ptr %out)
  br label %finish
finish:
  %bits = ptrtoint ptr %p to i64
  %r0 = add i64 %v, %a
  %r1 = xor i64 %r0, %b
  %r2 = xor i64 %r1, %cookie
  %r3 = xor i64 %r2, %bits
  ret i64 %r3
}

define i64 @call_values_poison_ptr(i64 %a, i64 %b, ptr %out, i64 %cookie, ptr %p) {
entry:
  %v = call i64 @call_values_ignore_ptr(i64 %a, ptr poison, i64 %b, ptr %out)
  br label %finish
finish:
  %bits = ptrtoint ptr %p to i64
  %r0 = add i64 %v, %a
  %r1 = xor i64 %r0, %b
  %r2 = xor i64 %r1, %cookie
  %r3 = xor i64 %r2, %bits
  ret i64 %r3
}

define i64 @call_values_undef_ptr(i64 %a, i64 %b, ptr %out, i64 %cookie, ptr %p) {
entry:
  %v = call i64 @call_values_ignore_ptr(i64 %a, ptr undef, i64 %b, ptr %out)
  br label %finish
finish:
  %bits = ptrtoint ptr %p to i64
  %r0 = add i64 %v, %a
  %r1 = xor i64 %r0, %b
  %r2 = xor i64 %r1, %cookie
  %r3 = xor i64 %r2, %bits
  ret i64 %r3
}

define i64 @call_values_init_body(i64 %a, i64 %b, ptr %out, i64 %cookie, ptr %p) #0 {
entry:
  %value = xor i64 %a, %b
  %small = trunc i64 %value to i16
  %field = getelementptr i8, ptr %out, i64 4
  store i16 %small, ptr %field, align 1
  call void @call_values_clobber()
  br label %finish
finish:
  %read = load i16, ptr %field, align 1
  %wide = zext i16 %read to i64
  %r0 = xor i64 %wide, %a
  %r1 = xor i64 %r0, %b
  %r2 = xor i64 %r1, %cookie
  ret i64 %r2
}

define i64 @call_values_init(i64 %a, i64 %b, ptr nonnull align 1 captures(none) initializes((4, 6)) %out, i64 %cookie, ptr %p) {
entry:
  %v = call i64 @call_values_init_body(i64 %a, i64 %b, ptr nonnull align 1 captures(none) initializes((4, 6)) %out, i64 %cookie, ptr %p)
  br label %finish
finish:
  %r = add i64 %v, %cookie
  ret i64 %r
}

define i64 @call_values_capture(i64 %a, i64 %b, ptr %out, i64 %cookie, ptr readonly align 8 captures(address) %p) {
entry:
  %bits = ptrtoint ptr %p to i64
  call void @call_values_clobber()
  br label %finish
finish:
  %r0 = xor i64 %bits, %a
  %r1 = xor i64 %r0, %b
  %r2 = xor i64 %r1, %cookie
  ret i64 %r2
}

define i64 @call_values_is_null(i64 %a, i64 %b, ptr %out, i64 %cookie, ptr readnone align 1 captures(address_is_null) %p) {
entry:
  %is_null = icmp eq ptr %p, null
  call void @call_values_clobber()
  br label %finish
finish:
  %wide = zext i1 %is_null to i64
  %r0 = add i64 %a, %b
  %r1 = xor i64 %r0, %cookie
  %r2 = xor i64 %r1, %wide
  ret i64 %r2
}

attributes #0 = { noinline }
