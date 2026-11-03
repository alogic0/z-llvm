target datalayout = "e-m:e-p:64:64-i64:64-i128:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare void @signed_nonnegative_clobber()
declare i32 @signed_nonnegative_echo(i32)

define i64 @nonnegative_i32(i32 %value, i64 %live, ptr %output) {
entry:
  %condition = icmp sge i32 %value, 0
  %wide = zext i1 %condition to i64
  store i64 %wide, ptr %output, align 8
  %result = xor i64 %wide, %live
  ret i64 %result
}

define i64 @nonnegative_i64(i64 %value, i64 %live, ptr %output) {
entry:
  %condition = icmp sge i64 %value, 0
  %wide = zext i1 %condition to i64
  store i64 %wide, ptr %output, align 8
  %result = xor i64 %wide, %live
  ret i64 %result
}

define i64 @nonnegative_returned(i32 %value, i64 %live, ptr %output) {
entry:
  %returned = call i32 @signed_nonnegative_echo(i32 %value)
  %condition = icmp sge i32 %returned, 0
  %wide = zext i1 %condition to i64
  store i64 %wide, ptr %output, align 8
  %result = xor i64 %wide, %live
  ret i64 %result
}

define i64 @nonnegative_spilled(i32 %a, i32 %b, i32 %c, i32 %d, i32 %e, ptr %output) {
entry:
  call void @signed_nonnegative_clobber()
  %c0 = icmp sge i32 %a, 0
  %v0 = zext i1 %c0 to i64
  store i64 %v0, ptr %output, align 8
  %o1 = getelementptr i8, ptr %output, i64 8
  %c1 = icmp sge i32 %b, 0
  %v1 = zext i1 %c1 to i64
  store i64 %v1, ptr %o1, align 8
  %o2 = getelementptr i8, ptr %output, i64 16
  %c2 = icmp sge i32 %c, 0
  %v2 = zext i1 %c2 to i64
  store i64 %v2, ptr %o2, align 8
  %o3 = getelementptr i8, ptr %output, i64 24
  %c3 = icmp sge i32 %d, 0
  %v3 = zext i1 %c3 to i64
  store i64 %v3, ptr %o3, align 8
  %o4 = getelementptr i8, ptr %output, i64 32
  %c4 = icmp sge i32 %e, 0
  %v4 = zext i1 %c4 to i64
  store i64 %v4, ptr %o4, align 8
  ret i64 %v4
}
