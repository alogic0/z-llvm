target triple = "x86_64-unknown-linux-gnu"
target datalayout = "e-m:e-p:64:64-i64:64-i128:128-n8:16:32:64-S128"
declare i64 @call_contracts_clobber(i64)
declare i64 @call_contracts_external(i64)
declare i64 @call_contracts_apply(ptr, i64)
declare i64 @call_contracts_alias(ptr, ptr)
declare i64 @call_contracts_varargs_0_0_sink(ptr, ...)
declare i64 @call_contracts_varargs_0_1_sink(ptr, ...)
declare i64 @call_contracts_varargs_0_2_sink(ptr, ...)
declare i64 @call_contracts_varargs_0_5_sink(ptr, ...)
declare i64 @call_contracts_varargs_0_10_sink(ptr, ...)
declare i64 @call_contracts_varargs_1_0_sink(i32, ...)
declare i64 @call_contracts_varargs_1_1_sink(i32, ...)
declare i64 @call_contracts_varargs_1_2_sink(i32, ...)
declare i64 @call_contracts_varargs_1_5_sink(i32, ...)
declare i64 @call_contracts_varargs_1_10_sink(i32, ...)
declare i64 @call_contracts_varargs_2_0_sink(i64, ...)
declare i64 @call_contracts_varargs_2_1_sink(i64, ...)
declare i64 @call_contracts_varargs_2_2_sink(i64, ...)
declare i64 @call_contracts_varargs_2_5_sink(i64, ...)
declare i64 @call_contracts_varargs_2_10_sink(i64, ...)
declare i64 @call_contracts_varargs_3_0_sink(ptr, i32, ...)
declare i64 @call_contracts_varargs_3_1_sink(ptr, i32, ...)
declare i64 @call_contracts_varargs_3_2_sink(ptr, i32, ...)
declare i64 @call_contracts_varargs_3_5_sink(ptr, i32, ...)
declare i64 @call_contracts_varargs_3_10_sink(ptr, i32, ...)
declare i64 @call_contracts_varargs_4_0_sink(i32, ptr, i32, ...)
declare i64 @call_contracts_varargs_4_1_sink(i32, ptr, i32, ...)
declare i64 @call_contracts_varargs_4_2_sink(i32, ptr, i32, ...)
declare i64 @call_contracts_varargs_4_5_sink(i32, ptr, i32, ...)
declare i64 @call_contracts_varargs_4_10_sink(i32, ptr, i32, ...)
declare i64 @call_contracts_varargs_5_0_sink(ptr, i64, i64, i32, ...)
declare i64 @call_contracts_varargs_5_1_sink(ptr, i64, i64, i32, ...)
declare i64 @call_contracts_varargs_5_2_sink(ptr, i64, i64, i32, ...)
declare i64 @call_contracts_varargs_5_5_sink(ptr, i64, i64, i32, ...)
declare i64 @call_contracts_varargs_5_10_sink(ptr, i64, i64, i32, ...)
declare i64 @call_contracts_varargs_6_0_sink(i64, ptr, i32, i64, i32, ptr, ...)
declare i64 @call_contracts_varargs_6_1_sink(i64, ptr, i32, i64, i32, ptr, ...)
declare i64 @call_contracts_varargs_6_2_sink(i64, ptr, i32, i64, i32, ptr, ...)
declare i64 @call_contracts_varargs_6_5_sink(i64, ptr, i32, i64, i32, ptr, ...)
declare i64 @call_contracts_varargs_6_10_sink(i64, ptr, i32, i64, i32, ptr, ...)
declare i32 @call_contracts_return_i32_sink(i32, ...)
declare ptr @call_contracts_return_ptr_sink(i32, ...)
declare void @call_contracts_return_void_sink(i32, ...)
define i64 @call_contracts_varargs_0_0(ptr %p, i64 %a, i64 %b, ptr %out) {
entry:
  %lo = trunc i64 %a to i32
  %answer = call i64 (ptr, ...) @call_contracts_varargs_0_0_sink(ptr %p)
  %clobber = call i64 @call_contracts_clobber(i64 %b)
  store i64 %clobber, ptr %out
  ret i64 %answer
}

define i64 @call_contracts_varargs_0_1(ptr %p, i64 %a, i64 %b, ptr %out) {
entry:
  %lo = trunc i64 %a to i32
  %answer = call i64 (ptr, ...) @call_contracts_varargs_0_1_sink(ptr %p, i32 %lo)
  %clobber = call i64 @call_contracts_clobber(i64 %b)
  store i64 %clobber, ptr %out
  ret i64 %answer
}

define i64 @call_contracts_varargs_0_2(ptr %p, i64 %a, i64 %b, ptr %out) {
entry:
  %lo = trunc i64 %a to i32
  %answer = call i64 (ptr, ...) @call_contracts_varargs_0_2_sink(ptr %p, i32 %lo, i64 %b)
  %clobber = call i64 @call_contracts_clobber(i64 %b)
  store i64 %clobber, ptr %out
  ret i64 %answer
}

define i64 @call_contracts_varargs_0_5(ptr %p, i64 %a, i64 %b, ptr %out) {
entry:
  %lo = trunc i64 %a to i32
  %answer = call i64 (ptr, ...) @call_contracts_varargs_0_5_sink(ptr %p, i32 %lo, i64 %b, ptr %p, i32 %lo, i64 %a)
  %clobber = call i64 @call_contracts_clobber(i64 %b)
  store i64 %clobber, ptr %out
  ret i64 %answer
}

define i64 @call_contracts_varargs_0_10(ptr %p, i64 %a, i64 %b, ptr %out) {
entry:
  %lo = trunc i64 %a to i32
  %answer = call i64 (ptr, ...) @call_contracts_varargs_0_10_sink(ptr %p, i32 %lo, i64 %b, ptr %p, i32 %lo, i64 %a, ptr %p, i32 %lo, i64 %b, ptr %p, i32 %lo)
  %clobber = call i64 @call_contracts_clobber(i64 %b)
  store i64 %clobber, ptr %out
  ret i64 %answer
}

define i64 @call_contracts_varargs_1_0(ptr %p, i64 %a, i64 %b, ptr %out) {
entry:
  %lo = trunc i64 %a to i32
  %answer = call i64 (i32, ...) @call_contracts_varargs_1_0_sink(i32 %lo)
  %clobber = call i64 @call_contracts_clobber(i64 %b)
  store i64 %clobber, ptr %out
  ret i64 %answer
}

define i64 @call_contracts_varargs_1_1(ptr %p, i64 %a, i64 %b, ptr %out) {
entry:
  %lo = trunc i64 %a to i32
  %answer = call i64 (i32, ...) @call_contracts_varargs_1_1_sink(i32 %lo, i32 %lo)
  %clobber = call i64 @call_contracts_clobber(i64 %b)
  store i64 %clobber, ptr %out
  ret i64 %answer
}

define i64 @call_contracts_varargs_1_2(ptr %p, i64 %a, i64 %b, ptr %out) {
entry:
  %lo = trunc i64 %a to i32
  %answer = call i64 (i32, ...) @call_contracts_varargs_1_2_sink(i32 %lo, i32 %lo, i64 %b)
  %clobber = call i64 @call_contracts_clobber(i64 %b)
  store i64 %clobber, ptr %out
  ret i64 %answer
}

define i64 @call_contracts_varargs_1_5(ptr %p, i64 %a, i64 %b, ptr %out) {
entry:
  %lo = trunc i64 %a to i32
  %answer = call i64 (i32, ...) @call_contracts_varargs_1_5_sink(i32 %lo, i32 %lo, i64 %b, ptr %p, i32 %lo, i64 %a)
  %clobber = call i64 @call_contracts_clobber(i64 %b)
  store i64 %clobber, ptr %out
  ret i64 %answer
}

define i64 @call_contracts_varargs_1_10(ptr %p, i64 %a, i64 %b, ptr %out) {
entry:
  %lo = trunc i64 %a to i32
  %answer = call i64 (i32, ...) @call_contracts_varargs_1_10_sink(i32 %lo, i32 %lo, i64 %b, ptr %p, i32 %lo, i64 %a, ptr %p, i32 %lo, i64 %b, ptr %p, i32 %lo)
  %clobber = call i64 @call_contracts_clobber(i64 %b)
  store i64 %clobber, ptr %out
  ret i64 %answer
}

define i64 @call_contracts_varargs_2_0(ptr %p, i64 %a, i64 %b, ptr %out) {
entry:
  %lo = trunc i64 %a to i32
  %answer = call i64 (i64, ...) @call_contracts_varargs_2_0_sink(i64 %b)
  %clobber = call i64 @call_contracts_clobber(i64 %b)
  store i64 %clobber, ptr %out
  ret i64 %answer
}

define i64 @call_contracts_varargs_2_1(ptr %p, i64 %a, i64 %b, ptr %out) {
entry:
  %lo = trunc i64 %a to i32
  %answer = call i64 (i64, ...) @call_contracts_varargs_2_1_sink(i64 %b, i32 %lo)
  %clobber = call i64 @call_contracts_clobber(i64 %b)
  store i64 %clobber, ptr %out
  ret i64 %answer
}

define i64 @call_contracts_varargs_2_2(ptr %p, i64 %a, i64 %b, ptr %out) {
entry:
  %lo = trunc i64 %a to i32
  %answer = call i64 (i64, ...) @call_contracts_varargs_2_2_sink(i64 %b, i32 %lo, i64 %b)
  %clobber = call i64 @call_contracts_clobber(i64 %b)
  store i64 %clobber, ptr %out
  ret i64 %answer
}

define i64 @call_contracts_varargs_2_5(ptr %p, i64 %a, i64 %b, ptr %out) {
entry:
  %lo = trunc i64 %a to i32
  %answer = call i64 (i64, ...) @call_contracts_varargs_2_5_sink(i64 %b, i32 %lo, i64 %b, ptr %p, i32 %lo, i64 %a)
  %clobber = call i64 @call_contracts_clobber(i64 %b)
  store i64 %clobber, ptr %out
  ret i64 %answer
}

define i64 @call_contracts_varargs_2_10(ptr %p, i64 %a, i64 %b, ptr %out) {
entry:
  %lo = trunc i64 %a to i32
  %answer = call i64 (i64, ...) @call_contracts_varargs_2_10_sink(i64 %b, i32 %lo, i64 %b, ptr %p, i32 %lo, i64 %a, ptr %p, i32 %lo, i64 %b, ptr %p, i32 %lo)
  %clobber = call i64 @call_contracts_clobber(i64 %b)
  store i64 %clobber, ptr %out
  ret i64 %answer
}

define i64 @call_contracts_varargs_3_0(ptr %p, i64 %a, i64 %b, ptr %out) {
entry:
  %lo = trunc i64 %a to i32
  %answer = call i64 (ptr, i32, ...) @call_contracts_varargs_3_0_sink(ptr %p, i32 %lo)
  %clobber = call i64 @call_contracts_clobber(i64 %b)
  store i64 %clobber, ptr %out
  ret i64 %answer
}

define i64 @call_contracts_varargs_3_1(ptr %p, i64 %a, i64 %b, ptr %out) {
entry:
  %lo = trunc i64 %a to i32
  %answer = call i64 (ptr, i32, ...) @call_contracts_varargs_3_1_sink(ptr %p, i32 %lo, i32 %lo)
  %clobber = call i64 @call_contracts_clobber(i64 %b)
  store i64 %clobber, ptr %out
  ret i64 %answer
}

define i64 @call_contracts_varargs_3_2(ptr %p, i64 %a, i64 %b, ptr %out) {
entry:
  %lo = trunc i64 %a to i32
  %answer = call i64 (ptr, i32, ...) @call_contracts_varargs_3_2_sink(ptr %p, i32 %lo, i32 %lo, i64 %a)
  %clobber = call i64 @call_contracts_clobber(i64 %b)
  store i64 %clobber, ptr %out
  ret i64 %answer
}

define i64 @call_contracts_varargs_3_5(ptr %p, i64 %a, i64 %b, ptr %out) {
entry:
  %lo = trunc i64 %a to i32
  %answer = call i64 (ptr, i32, ...) @call_contracts_varargs_3_5_sink(ptr %p, i32 %lo, i32 %lo, i64 %a, ptr %p, i32 %lo, i64 %b)
  %clobber = call i64 @call_contracts_clobber(i64 %b)
  store i64 %clobber, ptr %out
  ret i64 %answer
}

define i64 @call_contracts_varargs_3_10(ptr %p, i64 %a, i64 %b, ptr %out) {
entry:
  %lo = trunc i64 %a to i32
  %answer = call i64 (ptr, i32, ...) @call_contracts_varargs_3_10_sink(ptr %p, i32 %lo, i32 %lo, i64 %a, ptr %p, i32 %lo, i64 %b, ptr %p, i32 %lo, i64 %a, ptr %p, i32 %lo)
  %clobber = call i64 @call_contracts_clobber(i64 %b)
  store i64 %clobber, ptr %out
  ret i64 %answer
}

define i64 @call_contracts_varargs_4_0(ptr %p, i64 %a, i64 %b, ptr %out) {
entry:
  %lo = trunc i64 %a to i32
  %answer = call i64 (i32, ptr, i32, ...) @call_contracts_varargs_4_0_sink(i32 %lo, ptr %p, i32 %lo)
  %clobber = call i64 @call_contracts_clobber(i64 %b)
  store i64 %clobber, ptr %out
  ret i64 %answer
}

define i64 @call_contracts_varargs_4_1(ptr %p, i64 %a, i64 %b, ptr %out) {
entry:
  %lo = trunc i64 %a to i32
  %answer = call i64 (i32, ptr, i32, ...) @call_contracts_varargs_4_1_sink(i32 %lo, ptr %p, i32 %lo, i32 %lo)
  %clobber = call i64 @call_contracts_clobber(i64 %b)
  store i64 %clobber, ptr %out
  ret i64 %answer
}

define i64 @call_contracts_varargs_4_2(ptr %p, i64 %a, i64 %b, ptr %out) {
entry:
  %lo = trunc i64 %a to i32
  %answer = call i64 (i32, ptr, i32, ...) @call_contracts_varargs_4_2_sink(i32 %lo, ptr %p, i32 %lo, i32 %lo, i64 %b)
  %clobber = call i64 @call_contracts_clobber(i64 %b)
  store i64 %clobber, ptr %out
  ret i64 %answer
}

define i64 @call_contracts_varargs_4_5(ptr %p, i64 %a, i64 %b, ptr %out) {
entry:
  %lo = trunc i64 %a to i32
  %answer = call i64 (i32, ptr, i32, ...) @call_contracts_varargs_4_5_sink(i32 %lo, ptr %p, i32 %lo, i32 %lo, i64 %b, ptr %p, i32 %lo, i64 %a)
  %clobber = call i64 @call_contracts_clobber(i64 %b)
  store i64 %clobber, ptr %out
  ret i64 %answer
}

define i64 @call_contracts_varargs_4_10(ptr %p, i64 %a, i64 %b, ptr %out) {
entry:
  %lo = trunc i64 %a to i32
  %answer = call i64 (i32, ptr, i32, ...) @call_contracts_varargs_4_10_sink(i32 %lo, ptr %p, i32 %lo, i32 %lo, i64 %b, ptr %p, i32 %lo, i64 %a, ptr %p, i32 %lo, i64 %b, ptr %p, i32 %lo)
  %clobber = call i64 @call_contracts_clobber(i64 %b)
  store i64 %clobber, ptr %out
  ret i64 %answer
}

define i64 @call_contracts_varargs_5_0(ptr %p, i64 %a, i64 %b, ptr %out) {
entry:
  %lo = trunc i64 %a to i32
  %answer = call i64 (ptr, i64, i64, i32, ...) @call_contracts_varargs_5_0_sink(ptr %p, i64 %a, i64 %b, i32 %lo)
  %clobber = call i64 @call_contracts_clobber(i64 %b)
  store i64 %clobber, ptr %out
  ret i64 %answer
}

define i64 @call_contracts_varargs_5_1(ptr %p, i64 %a, i64 %b, ptr %out) {
entry:
  %lo = trunc i64 %a to i32
  %answer = call i64 (ptr, i64, i64, i32, ...) @call_contracts_varargs_5_1_sink(ptr %p, i64 %a, i64 %b, i32 %lo, i32 %lo)
  %clobber = call i64 @call_contracts_clobber(i64 %b)
  store i64 %clobber, ptr %out
  ret i64 %answer
}

define i64 @call_contracts_varargs_5_2(ptr %p, i64 %a, i64 %b, ptr %out) {
entry:
  %lo = trunc i64 %a to i32
  %answer = call i64 (ptr, i64, i64, i32, ...) @call_contracts_varargs_5_2_sink(ptr %p, i64 %a, i64 %b, i32 %lo, i32 %lo, i64 %a)
  %clobber = call i64 @call_contracts_clobber(i64 %b)
  store i64 %clobber, ptr %out
  ret i64 %answer
}

define i64 @call_contracts_varargs_5_5(ptr %p, i64 %a, i64 %b, ptr %out) {
entry:
  %lo = trunc i64 %a to i32
  %answer = call i64 (ptr, i64, i64, i32, ...) @call_contracts_varargs_5_5_sink(ptr %p, i64 %a, i64 %b, i32 %lo, i32 %lo, i64 %a, ptr %p, i32 %lo, i64 %b)
  %clobber = call i64 @call_contracts_clobber(i64 %b)
  store i64 %clobber, ptr %out
  ret i64 %answer
}

define i64 @call_contracts_varargs_5_10(ptr %p, i64 %a, i64 %b, ptr %out) {
entry:
  %lo = trunc i64 %a to i32
  %answer = call i64 (ptr, i64, i64, i32, ...) @call_contracts_varargs_5_10_sink(ptr %p, i64 %a, i64 %b, i32 %lo, i32 %lo, i64 %a, ptr %p, i32 %lo, i64 %b, ptr %p, i32 %lo, i64 %a, ptr %p, i32 %lo)
  %clobber = call i64 @call_contracts_clobber(i64 %b)
  store i64 %clobber, ptr %out
  ret i64 %answer
}

define i64 @call_contracts_varargs_6_0(ptr %p, i64 %a, i64 %b, ptr %out) {
entry:
  %lo = trunc i64 %a to i32
  %answer = call i64 (i64, ptr, i32, i64, i32, ptr, ...) @call_contracts_varargs_6_0_sink(i64 %b, ptr %p, i32 %lo, i64 %a, i32 %lo, ptr %p)
  %clobber = call i64 @call_contracts_clobber(i64 %b)
  store i64 %clobber, ptr %out
  ret i64 %answer
}

define i64 @call_contracts_varargs_6_1(ptr %p, i64 %a, i64 %b, ptr %out) {
entry:
  %lo = trunc i64 %a to i32
  %answer = call i64 (i64, ptr, i32, i64, i32, ptr, ...) @call_contracts_varargs_6_1_sink(i64 %b, ptr %p, i32 %lo, i64 %a, i32 %lo, ptr %p, i32 %lo)
  %clobber = call i64 @call_contracts_clobber(i64 %b)
  store i64 %clobber, ptr %out
  ret i64 %answer
}

define i64 @call_contracts_varargs_6_2(ptr %p, i64 %a, i64 %b, ptr %out) {
entry:
  %lo = trunc i64 %a to i32
  %answer = call i64 (i64, ptr, i32, i64, i32, ptr, ...) @call_contracts_varargs_6_2_sink(i64 %b, ptr %p, i32 %lo, i64 %a, i32 %lo, ptr %p, i32 %lo, i64 %a)
  %clobber = call i64 @call_contracts_clobber(i64 %b)
  store i64 %clobber, ptr %out
  ret i64 %answer
}

define i64 @call_contracts_varargs_6_5(ptr %p, i64 %a, i64 %b, ptr %out) {
entry:
  %lo = trunc i64 %a to i32
  %answer = call i64 (i64, ptr, i32, i64, i32, ptr, ...) @call_contracts_varargs_6_5_sink(i64 %b, ptr %p, i32 %lo, i64 %a, i32 %lo, ptr %p, i32 %lo, i64 %a, ptr %p, i32 %lo, i64 %b)
  %clobber = call i64 @call_contracts_clobber(i64 %b)
  store i64 %clobber, ptr %out
  ret i64 %answer
}

define i64 @call_contracts_varargs_6_10(ptr %p, i64 %a, i64 %b, ptr %out) {
entry:
  %lo = trunc i64 %a to i32
  %answer = call i64 (i64, ptr, i32, i64, i32, ptr, ...) @call_contracts_varargs_6_10_sink(i64 %b, ptr %p, i32 %lo, i64 %a, i32 %lo, ptr %p, i32 %lo, i64 %a, ptr %p, i32 %lo, i64 %b, ptr %p, i32 %lo, i64 %a, ptr %p, i32 %lo)
  %clobber = call i64 @call_contracts_clobber(i64 %b)
  store i64 %clobber, ptr %out
  ret i64 %answer
}

define i64 @call_contracts_return_i32(ptr %p, i64 %a, i64 %b, ptr %out) {
entry:
  %lo = trunc i64 %a to i32
  %returned = call i32 (i32, ...) @call_contracts_return_i32_sink(i32 %lo, i32 %lo)
  %answer = zext i32 %returned to i64
  %clobber = call i64 @call_contracts_clobber(i64 %b)
  store i64 %clobber, ptr %out
  ret i64 %answer
}

define i64 @call_contracts_return_ptr(ptr %p, i64 %a, i64 %b, ptr %out) {
entry:
  %lo = trunc i64 %a to i32
  %returned = call ptr (i32, ...) @call_contracts_return_ptr_sink(i32 %lo, ptr %p)
  %answer = ptrtoint ptr %returned to i64
  %clobber = call i64 @call_contracts_clobber(i64 %b)
  store i64 %clobber, ptr %out
  ret i64 %answer
}

define i64 @call_contracts_return_void(ptr %p, i64 %a, i64 %b, ptr %out) {
entry:
  %lo = trunc i64 %a to i32
  call void (i32, ...) @call_contracts_return_void_sink(i32 %lo, i64 %a)
  %clobber = call i64 @call_contracts_clobber(i64 %b)
  store i64 %clobber, ptr %out
  ret i64 %a
}

define i64 @call_contracts_advisory_0(ptr %p, i64 %a, i64 %b, ptr %out) {
entry:
  %answer = call i64 @call_contracts_alias(ptr noalias %p, ptr noalias nonnull align 8 %out)
  %clobber = call i64 @call_contracts_clobber(i64 %b)
  store i64 %clobber, ptr %out
  ret i64 %answer
}

define i64 @call_contracts_advisory_1(ptr %p, i64 %a, i64 %b, ptr %out) {
entry:
  %answer = call i64 @call_contracts_alias(ptr noalias nonnull align 8 %p, ptr noalias nonnull align 8 %out)
  %clobber = call i64 @call_contracts_clobber(i64 %b)
  store i64 %clobber, ptr %out
  ret i64 %answer
}

define i64 @call_contracts_advisory_2(ptr %p, i64 %a, i64 %b, ptr %out) {
entry:
  %answer = call i64 @call_contracts_alias(ptr noalias nonnull readonly align 8 %p, ptr noalias nonnull align 8 %out)
  %clobber = call i64 @call_contracts_clobber(i64 %b)
  store i64 %clobber, ptr %out
  ret i64 %answer
}

define internal i64 @call_contracts_local(i64 %a) {
entry:
  %answer = add i64 %a, 19
  ret i64 %answer
}

define internal i64 @call_contracts_other(i64 %a) {
entry:
  %answer = xor i64 %a, 6510615555426900570
  ret i64 %answer
}

define i64 @call_contracts_address_local(ptr %p, i64 %a, i64 %b, ptr %out) {
entry:
  %answer = call i64 @call_contracts_apply(ptr @call_contracts_local, i64 %a)
  %clobber = call i64 @call_contracts_clobber(i64 %b)
  store i64 %clobber, ptr %out
  ret i64 %answer
}

define i64 @call_contracts_address_external(ptr %p, i64 %a, i64 %b, ptr %out) {
entry:
  %answer = call i64 @call_contracts_apply(ptr @call_contracts_external, i64 %a)
  %clobber = call i64 @call_contracts_clobber(i64 %b)
  store i64 %clobber, ptr %out
  ret i64 %answer
}

define i64 @call_contracts_address_select(ptr %p, i64 %a, i64 %b, ptr %out) {
entry:
  %condition = trunc i64 %a to i1
  %target = select i1 %condition, ptr @call_contracts_local, ptr @call_contracts_other
  %answer = call i64 %target(i64 %a)
  %clobber = call i64 @call_contracts_clobber(i64 %b)
  store i64 %clobber, ptr %out
  ret i64 %answer
}

define i64 @call_contracts_address_phi(ptr %p, i64 %a, i64 %b, ptr %out) {
entry:
  %condition = trunc i64 %a to i1
  br i1 %condition, label %yes, label %no
yes:
  br label %merge
no:
  br label %merge
merge:
  %target = phi ptr [ @call_contracts_local, %yes ], [ @call_contracts_other, %no ]
  %answer = call i64 %target(i64 %a)
  %clobber = call i64 @call_contracts_clobber(i64 %b)
  store i64 %clobber, ptr %out
  ret i64 %answer
}

define i64 @call_contracts_address_store(ptr %p, i64 %a, i64 %b, ptr %out) {
entry:
  store ptr @call_contracts_external, ptr %out, align 8
  %loaded = load ptr, ptr %out, align 8
  %answer = call i64 %loaded(i64 %a)
  %clobber = call i64 @call_contracts_clobber(i64 %b)
  store i64 %clobber, ptr %out
  ret i64 %answer
}
