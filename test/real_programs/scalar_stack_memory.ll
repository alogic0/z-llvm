target datalayout = "e-m:e-p:64:64-i64:64-i128:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

define i64 @scalar_stack_roundtrip(i64 %value, i64 %live, ptr %output) {
entry:
  %slot = alloca i64, align 8
  store i64 %value, ptr %slot, align 8
  %loaded = load i64, ptr %slot, align 8
  store i64 %loaded, ptr %output, align 8
  %result = xor i64 %loaded, %live
  ret i64 %result
}

define void @scalar_stack_constants(ptr %output) {
entry:
  %slot = alloca i64, align 8
  store i64 0, ptr %slot, align 8
  %v0 = load i64, ptr %slot, align 8
  store i64 %v0, ptr %output, align 8
  %o1 = getelementptr i8, ptr %output, i64 8
  store i64 2147483648, ptr %slot, align 8
  %v1 = load i64, ptr %slot, align 8
  store i64 %v1, ptr %o1, align 8
  %o2 = getelementptr i8, ptr %output, i64 16
  store i64 4294967295, ptr %slot, align 8
  %v2 = load i64, ptr %slot, align 8
  store i64 %v2, ptr %o2, align 8
  %o3 = getelementptr i8, ptr %output, i64 24
  store i64 4294967296, ptr %slot, align 8
  %v3 = load i64, ptr %slot, align 8
  store i64 %v3, ptr %o3, align 8
  %o4 = getelementptr i8, ptr %output, i64 32
  store i64 9223372036854775807, ptr %slot, align 8
  %v4 = load i64, ptr %slot, align 8
  store i64 %v4, ptr %o4, align 8
  %o5 = getelementptr i8, ptr %output, i64 40
  store i64 9223372036854775808, ptr %slot, align 8
  %v5 = load i64, ptr %slot, align 8
  store i64 %v5, ptr %o5, align 8
  %o6 = getelementptr i8, ptr %output, i64 48
  store i64 18446744073709551615, ptr %slot, align 8
  %v6 = load i64, ptr %slot, align 8
  store i64 %v6, ptr %o6, align 8
  %o7 = getelementptr i8, ptr %output, i64 56
  store i64 16045690981116495207, ptr %slot, align 8
  %v7 = load i64, ptr %slot, align 8
  store i64 %v7, ptr %o7, align 8
  %o8 = getelementptr i8, ptr %output, i64 64
  store i64 0, ptr %o8, align 8
  %o9 = getelementptr i8, ptr %output, i64 72
  store i64 2147483648, ptr %o9, align 8
  %o10 = getelementptr i8, ptr %output, i64 80
  store i64 4294967295, ptr %o10, align 8
  %o11 = getelementptr i8, ptr %output, i64 88
  store i64 4294967296, ptr %o11, align 8
  %o12 = getelementptr i8, ptr %output, i64 96
  store i64 9223372036854775807, ptr %o12, align 8
  %o13 = getelementptr i8, ptr %output, i64 104
  store i64 9223372036854775808, ptr %o13, align 8
  %o14 = getelementptr i8, ptr %output, i64 112
  store i64 18446744073709551615, ptr %o14, align 8
  %o15 = getelementptr i8, ptr %output, i64 120
  store i64 16045690981116495207, ptr %o15, align 8
  ret void
}

define i64 @scalar_stack_null(ptr %output) {
entry:
  %slot = alloca ptr, align 8
  store ptr null, ptr %slot, align 8
  %loaded = load ptr, ptr %slot, align 8
  store ptr %loaded, ptr %output, align 8
  %bits = ptrtoint ptr %loaded to i64
  ret i64 %bits
}
