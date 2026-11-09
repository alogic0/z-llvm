target datalayout = "e-m:e-p:64:64-i64:64-i128:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

define i64 @samesign_byte_named(i64 %input_a, i64 %input_b, i64 %c, i64 %d, i64 %e, ptr %out) {
entry:
  %a = trunc i64 %input_a to i8
  %b = trunc i64 %input_b to i8
  %different = xor i64 %input_a, %input_b
  %signs = and i64 %different, 128
  %defined = icmp eq i64 %signs, 0
  br i1 %defined, label %compare, label %skip
compare:
  %flag = icmp samesign ult i8 %a, %b
  %answer = zext i1 %flag to i64
  br label %join
skip:
  br label %join
join:
  %result = phi i64 [ %answer, %compare ], [ 2, %skip ]
  %ab = xor i64 %input_a, %input_b
  %cd = xor i64 %c, %d
  %abcd = xor i64 %ab, %cd
  %live = xor i64 %abcd, %e
  store i64 %live, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %input_a, ptr %next, align 8
  ret i64 %result
}

define i64 @samesign_byte_negative(i64 %input_a, i64 %input_b, i64 %c, i64 %d, i64 %e, ptr %out) {
entry:
  %a = trunc i64 %input_a to i8
  %signs = and i64 %input_a, 128
  %defined = icmp eq i64 %signs, 128
  br i1 %defined, label %compare, label %skip
compare:
  %flag = icmp samesign ult i8 %a, -7
  %answer = zext i1 %flag to i64
  br label %join
skip:
  br label %join
join:
  %result = phi i64 [ %answer, %compare ], [ 2, %skip ]
  %ab = xor i64 %input_a, %input_b
  %cd = xor i64 %c, %d
  %abcd = xor i64 %ab, %cd
  %live = xor i64 %abcd, %e
  store i64 %live, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %input_a, ptr %next, align 8
  ret i64 %result
}

define i64 @samesign_half_named(i64 %input_a, i64 %input_b, i64 %c, i64 %d, i64 %e, ptr %out) {
entry:
  %a = trunc i64 %input_a to i16
  %b = trunc i64 %input_b to i16
  %different = xor i64 %input_a, %input_b
  %signs = and i64 %different, 32768
  %defined = icmp eq i64 %signs, 0
  br i1 %defined, label %compare, label %skip
compare:
  %flag = icmp samesign uge i16 %a, %b
  %answer = zext i1 %flag to i64
  br label %join
skip:
  br label %join
join:
  %result = phi i64 [ %answer, %compare ], [ 2, %skip ]
  %ab = xor i64 %input_a, %input_b
  %cd = xor i64 %c, %d
  %abcd = xor i64 %ab, %cd
  %live = xor i64 %abcd, %e
  store i64 %live, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %input_a, ptr %next, align 8
  ret i64 %result
}

define i64 @samesign_i21_literal(i64 %input_a, i64 %input_b, i64 %c, i64 %d, i64 %e, ptr %out) {
entry:
  %a = trunc i64 %input_a to i21
  %signs = and i64 %input_a, 1048576
  %defined = icmp eq i64 %signs, 0
  br i1 %defined, label %compare, label %skip
compare:
  %flag = icmp samesign ult i21 %a, 2048
  %answer = zext i1 %flag to i64
  br label %join
skip:
  br label %join
join:
  %result = phi i64 [ %answer, %compare ], [ 2, %skip ]
  %ab = xor i64 %input_a, %input_b
  %cd = xor i64 %c, %d
  %abcd = xor i64 %ab, %cd
  %live = xor i64 %abcd, %e
  store i64 %live, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %input_a, ptr %next, align 8
  ret i64 %result
}

define i64 @samesign_i37_literal(i64 %input_a, i64 %input_b, i64 %c, i64 %d, i64 %e, ptr %out) {
entry:
  %a = trunc i64 %input_a to i37
  %signs = and i64 %input_a, 68719476736
  %defined = icmp eq i64 %signs, 0
  br i1 %defined, label %compare, label %skip
compare:
  %flag = icmp samesign ult i37 %a, 14
  %answer = zext i1 %flag to i64
  br label %join
skip:
  br label %join
join:
  %result = phi i64 [ %answer, %compare ], [ 2, %skip ]
  %ab = xor i64 %input_a, %input_b
  %cd = xor i64 %c, %d
  %abcd = xor i64 %ab, %cd
  %live = xor i64 %abcd, %e
  store i64 %live, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %input_a, ptr %next, align 8
  ret i64 %result
}

define i64 @samesign_signed_word(i64 %input_a, i64 %input_b, i64 %c, i64 %d, i64 %e, ptr %out) {
entry:
  %a = trunc i64 %input_a to i32
  %signs = and i64 %input_a, 2147483648
  %defined = icmp eq i64 %signs, 2147483648
  br i1 %defined, label %compare, label %skip
compare:
  %flag = icmp samesign sgt i32 %a, 2147483648
  %answer = zext i1 %flag to i64
  br label %join
skip:
  br label %join
join:
  %result = phi i64 [ %answer, %compare ], [ 2, %skip ]
  %ab = xor i64 %input_a, %input_b
  %cd = xor i64 %c, %d
  %abcd = xor i64 %ab, %cd
  %live = xor i64 %abcd, %e
  store i64 %live, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %input_a, ptr %next, align 8
  ret i64 %result
}

define i64 @samesign_dirty_byte(i64 %input_a, i64 %input_b, i64 %c, i64 %d, i64 %e, ptr %out) {
entry:
  %a = trunc i64 %input_a to i8
  %signs = and i64 %input_a, 128
  %defined = icmp eq i64 %signs, 0
  br i1 %defined, label %compare, label %skip
compare:
  %flag = icmp samesign ult i8 %a, 100
  %answer = zext i1 %flag to i64
  br label %join
skip:
  br label %join
join:
  %result = phi i64 [ %answer, %compare ], [ 2, %skip ]
  %ab = xor i64 %input_a, %input_b
  %cd = xor i64 %c, %d
  %abcd = xor i64 %ab, %cd
  %live = xor i64 %abcd, %e
  store i64 %live, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %input_a, ptr %next, align 8
  ret i64 %result
}

define i64 @samesign_signed_named(i64 %input_a, i64 %input_b, i64 %c, i64 %d, i64 %e, ptr %out) {
entry:
  %a = bitcast i64 %input_a to i64
  %b = bitcast i64 %input_b to i64
  %different = xor i64 %input_a, %input_b
  %signs = and i64 %different, 9223372036854775808
  %defined = icmp eq i64 %signs, 0
  br i1 %defined, label %compare, label %skip
compare:
  %flag = icmp samesign slt i64 %a, %b
  %answer = zext i1 %flag to i64
  br label %join
skip:
  br label %join
join:
  %result = phi i64 [ %answer, %compare ], [ 2, %skip ]
  %ab = xor i64 %input_a, %input_b
  %cd = xor i64 %c, %d
  %abcd = xor i64 %ab, %cd
  %live = xor i64 %abcd, %e
  store i64 %live, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %input_a, ptr %next, align 8
  ret i64 %result
}

