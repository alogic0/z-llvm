target datalayout = "e-m:e-p:64:64-i64:64-i128:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

@tls_counter = internal thread_local global i64 17, align 64
@tls_bytes = private thread_local global [80 x i8] zeroinitializer, align 32
@tls_alias = internal alias i64, ptr @tls_counter

define ptr @tls_address_counter() {
entry:
  ret ptr @tls_counter
}

define ptr @tls_address_alias() {
entry:
  ret ptr @tls_alias
}

define ptr @tls_address_offset() {
entry:
  %address = getelementptr i8, ptr @tls_bytes, i64 7
  ret ptr %address
}

define i64 @tls_address_update(i64 %a, i64 %b, i64 %c, i64 %d, i64 %e, i64 %f) {
entry:
  %old = load i64, ptr @tls_counter, align 64
  %next = add i64 %old, %a
  store i64 %next, ptr @tls_counter, align 64
  %ab = xor i64 %a, %b
  %cd = xor i64 %c, %d
  %ef = xor i64 %e, %f
  %abcd = xor i64 %ab, %cd
  %all = xor i64 %abcd, %ef
  %result = xor i64 %all, %old
  ret i64 %result
}

define double @tls_address_double(double %x, double %y) {
entry:
  %old = load i64, ptr @tls_counter, align 64
  %next = add i64 %old, 1
  store i64 %next, ptr @tls_counter, align 64
  %result = fadd double %x, %y
  ret double %result
}

define i64 @tls_address_choose(i64 %x, i64 %y) {
entry:
  %flag = icmp ult i64 %x, %y
  br i1 %flag, label %yes, label %no
yes:
  %old = load i64, ptr @tls_counter, align 64
  br label %join
no:
  %alternative = xor i64 %x, %y
  br label %join
join:
  %value = phi i64 [ %old, %yes ], [ %alternative, %no ]
  %result = xor i64 %value, %x
  ret i64 %result
}
