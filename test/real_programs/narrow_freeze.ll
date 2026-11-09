target datalayout = "e-m:e-p:64:64-i64:64-i128:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i64 @freeze_clobber(i64)

define i64 @freeze_alias3(i64 %a, i64 %b, i64 %c, i64 %d, i64 %e, ptr %out) {
entry:
  %wide = add i64 %a, %b
  %low = trunc i64 %wide to i3
  %frozen = freeze i3 %low
  %result = zext i3 %frozen to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %ab = xor i64 %a, %b
  %cd = xor i64 %c, %d
  %abcd = xor i64 %ab, %cd
  %live = xor i64 %abcd, %e
  store i64 %live, ptr %next, align 8
  ret i64 %result
}

define i64 @freeze_alias8(i64 %a, i64 %b, i64 %c, i64 %d, i64 %e, ptr %out) {
entry:
  %wide = add i64 %a, %b
  %low = trunc i64 %wide to i8
  %frozen = freeze i8 %low
  %again = freeze i8 %frozen
  %result = zext i8 %again to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %ab = xor i64 %a, %b
  %cd = xor i64 %c, %d
  %abcd = xor i64 %ab, %cd
  %live = xor i64 %abcd, %e
  store i64 %live, ptr %next, align 8
  ret i64 %result
}

define i64 @freeze_alias10(i64 %a, i64 %b, i64 %c, i64 %d, i64 %e, ptr %out) {
entry:
  %wide = add i64 %a, %b
  %low = trunc i64 %wide to i10
  %frozen = freeze i10 %low
  %result = zext i10 %frozen to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %ab = xor i64 %a, %b
  %cd = xor i64 %c, %d
  %abcd = xor i64 %ab, %cd
  %live = xor i64 %abcd, %e
  store i64 %live, ptr %next, align 8
  ret i64 %result
}

define i64 @freeze_alias16(i64 %a, i64 %b, i64 %c, i64 %d, i64 %e, ptr %out) {
entry:
  %wide = add i64 %a, %b
  %low = trunc i64 %wide to i16
  %frozen = freeze i16 %low
  %result = zext i16 %frozen to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %ab = xor i64 %a, %b
  %cd = xor i64 %c, %d
  %abcd = xor i64 %ab, %cd
  %live = xor i64 %abcd, %e
  store i64 %live, ptr %next, align 8
  ret i64 %result
}

define i64 @freeze_alias31(i64 %a, i64 %b, i64 %c, i64 %d, i64 %e, ptr %out) {
entry:
  %wide = add i64 %a, %b
  %low = trunc i64 %wide to i31
  %frozen = freeze i31 %low
  %result = zext i31 %frozen to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %ab = xor i64 %a, %b
  %cd = xor i64 %c, %d
  %abcd = xor i64 %ab, %cd
  %live = xor i64 %abcd, %e
  store i64 %live, ptr %next, align 8
  ret i64 %result
}

define i64 @freeze_load8(i64 %a, i64 %b, i64 %c, i64 %d, i64 %e, ptr %out) {
entry:
  %low = load i8, ptr %out, align 1
  %frozen = freeze i8 %low
  %result = zext i8 %frozen to i64
  %wide = add i64 %a, %b
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %ab = xor i64 %a, %b
  %cd = xor i64 %c, %d
  %abcd = xor i64 %ab, %cd
  %live = xor i64 %abcd, %e
  store i64 %live, ptr %next, align 8
  ret i64 %result
}

define i64 @freeze_calls16(i64 %a, i64 %b, i64 %c, i64 %d, i64 %e, ptr %out) {
entry:
  %low = trunc i64 %c to i16
  %frozen = freeze i16 %low
  %before = call i64 @freeze_clobber(i64 %a)
  %again = freeze i16 %frozen
  %after = call i64 @freeze_clobber(i64 %b)
  %extended = zext i16 %again to i64
  %calls = xor i64 %before, %after
  %result = xor i64 %extended, %calls
  %wide = add i64 %a, %b
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %ab = xor i64 %a, %b
  %cd = xor i64 %c, %d
  %abcd = xor i64 %ab, %cd
  %live = xor i64 %abcd, %e
  store i64 %live, ptr %next, align 8
  ret i64 %result
}

define i64 @freeze_phi8(i64 %a, i64 %b, i64 %c, i64 %d, i64 %e, ptr %out) {
entry:
  %cond = icmp ult i64 %a, %b
  br i1 %cond, label %left, label %right
left:
  %x = trunc i64 %a to i8
  %xf = freeze i8 %x
  br label %join
right:
  %y = trunc i64 %b to i8
  %yf = freeze i8 %y
  br label %join
join:
  %chosen = phi i8 [ %xf, %left ], [ %yf, %right ]
  %frozen = freeze i8 %chosen
  %result = zext i8 %frozen to i64
  %wide = add i64 %a, %b
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %ab = xor i64 %a, %b
  %cd = xor i64 %c, %d
  %abcd = xor i64 %ab, %cd
  %live = xor i64 %abcd, %e
  store i64 %live, ptr %next, align 8
  ret i64 %result
}

define i64 @freeze_branch1(i64 %a, i64 %b, i64 %c, i64 %d, i64 %e, ptr %out) {
entry:
  %low = trunc i64 %a to i1
  %frozen = freeze i1 %low
  br i1 %frozen, label %left, label %right
left:
  br label %join
right:
  br label %join
join:
  %result = phi i64 [ %a, %left ], [ %b, %right ]
  %wide = add i64 %a, %b
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %ab = xor i64 %a, %b
  %cd = xor i64 %c, %d
  %abcd = xor i64 %ab, %cd
  %live = xor i64 %abcd, %e
  store i64 %live, ptr %next, align 8
  ret i64 %result
}

define i64 @freeze_parameter8(i8 %low, i64 %b, i64 %c, i64 %d, i64 %e, ptr %out) {
entry:
  %frozen = freeze i8 %low
  %result = zext i8 %frozen to i64
  store i64 %result, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %ab = xor i64 %result, %b
  %cd = xor i64 %c, %d
  %abcd = xor i64 %ab, %cd
  %live = xor i64 %abcd, %e
  store i64 %live, ptr %next, align 8
  ret i64 %result
}
