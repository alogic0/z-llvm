target datalayout = "e-m:e-p:64:64-i64:64-i128:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare { i64, i1 } @llvm.umul.with.overflow.i64(i64, i64)
declare { i64, i1 } @llvm.smul.with.overflow.i64(i64, i64)
declare i64 @checked_multiply_clobber(i64)

define i64 @checked_select24(i64 %a, i64 %b, i64 %c, i64 %d, i64 %e, ptr %out) {
entry:
  %x = or i64 %a, 16
  %y = or i64 %b, 16
  %cond = icmp ult i64 %x, %y
  %chosen = select i1 %cond, i64 %x, i64 %y
  %pair = tail call { i64, i1 } @llvm.umul.with.overflow.i64(i64 range(i64 10, 0) %chosen, i64 24)
  %flag = extractvalue { i64, i1 } %pair, 1
  %value = extractvalue { i64, i1 } %pair, 0
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %ab = xor i64 %a, %b
  %cd = xor i64 %c, %d
  %abcd = xor i64 %ab, %cd
  %live = xor i64 %abcd, %e
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}

define i64 @checked_binary40(i64 %a, i64 %b, i64 %c, i64 %d, i64 %e, ptr %out) {
entry:
  %sum = add i64 %a, %b
  %pair = call { i64, i1 } @llvm.umul.with.overflow.i64(i64 noundef %sum, i64 40)
  %value = extractvalue { i64, i1 } %pair, 0
  %flag = extractvalue { i64, i1 } %pair, 1
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %ab = xor i64 %a, %b
  %cd = xor i64 %c, %d
  %abcd = xor i64 %ab, %cd
  %live = xor i64 %abcd, %e
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}

define i64 @checked_rhs_high(i64 %a, i64 %b, i64 %c, i64 %d, i64 %e, ptr %out) {
entry:
  %pair = call { i64, i1 } @llvm.umul.with.overflow.i64(i64 noundef %a, i64 18446744073709551615)
  %flag = extractvalue { i64, i1 } %pair, 1
  %value = extractvalue { i64, i1 } %pair, 0
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %ab = xor i64 %a, %b
  %cd = xor i64 %c, %d
  %abcd = xor i64 %ab, %cd
  %live = xor i64 %abcd, %e
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}

define i64 @checked_spill_high(i64 %a, i64 %b, i64 %c, i64 %d, i64 %e, ptr %out) {
entry:
  %cond = icmp ult i64 %a, %b
  %chosen = select i1 %cond, i64 %a, i64 %b
  %pair = call { i64, i1 } @llvm.umul.with.overflow.i64(i64 noundef %chosen, i64 9223372036854775808)
  %flag = extractvalue { i64, i1 } %pair, 1
  %value = extractvalue { i64, i1 } %pair, 0
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %ab = xor i64 %a, %b
  %cd = xor i64 %c, %d
  %abcd = xor i64 %ab, %cd
  %live = xor i64 %abcd, %e
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}

define i64 @checked_signed120(i64 %a, i64 %b, i64 %c, i64 %d, i64 %e, ptr %out) {
entry:
  %pair = call { i64, i1 } @llvm.smul.with.overflow.i64(i64 noundef %a, i64 -120)
  %value = extractvalue { i64, i1 } %pair, 0
  %flag = extractvalue { i64, i1 } %pair, 1
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %ab = xor i64 %a, %b
  %cd = xor i64 %c, %d
  %abcd = xor i64 %ab, %cd
  %live = xor i64 %abcd, %e
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}

define i64 @checked_alias56(i64 %a, i64 %b, i64 %c, i64 %d, i64 %e, ptr %out) {
entry:
  %wide = add i64 %c, 7
  %low = trunc i64 %wide to i32
  %pair = call { i64, i1 } @llvm.umul.with.overflow.i64(i64 noundef %wide, i64 56)
  %flag = extractvalue { i64, i1 } %pair, 1
  %value = extractvalue { i64, i1 } %pair, 0
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %ab = xor i64 %a, %b
  %cd = xor i64 %c, %d
  %abcd = xor i64 %ab, %cd
  %all = xor i64 %abcd, %e
  %low64 = zext i32 %low to i64
  %aliases = xor i64 %wide, %low64
  %live = xor i64 %all, %aliases
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}

define i64 @checked_calls48(i64 %a, i64 %b, i64 %c, i64 %d, i64 %e, ptr %out) {
entry:
  %before = call i64 @checked_multiply_clobber(i64 %a)
  %cond = icmp ult i64 %before, %b
  %chosen = select i1 %cond, i64 %before, i64 %b
  %pair = call { i64, i1 } @llvm.umul.with.overflow.i64(i64 noundef %chosen, i64 48)
  %flag = extractvalue { i64, i1 } %pair, 1
  %value = extractvalue { i64, i1 } %pair, 0
  %after = call i64 @checked_multiply_clobber(i64 %c)
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %ab = xor i64 %a, %b
  %cd = xor i64 %c, %d
  %abcd = xor i64 %ab, %cd
  %all = xor i64 %abcd, %e
  %calls = xor i64 %before, %after
  %live = xor i64 %all, %calls
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}

define i64 @checked_phi12(i64 %a, i64 %b, i64 %c, i64 %d, i64 %e, ptr %out) {
entry:
  %cond = icmp ult i64 %a, %b
  br i1 %cond, label %left, label %right
left:
  %x = add i64 %a, 3
  br label %join
right:
  %y = xor i64 %b, 7
  br label %join
join:
  %chosen = phi i64 [ %x, %left ], [ %y, %right ]
  %pair = call { i64, i1 } @llvm.umul.with.overflow.i64(i64 noundef %chosen, i64 12)
  %flag = extractvalue { i64, i1 } %pair, 1
  %value = extractvalue { i64, i1 } %pair, 0
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %ab = xor i64 %a, %b
  %cd = xor i64 %c, %d
  %abcd = xor i64 %ab, %cd
  %live = xor i64 %abcd, %e
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}
