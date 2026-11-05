target triple = "x86_64-unknown-linux-gnu"

declare ptr @calls_get_target(ptr)

declare i64 @llvm.usub.sat.i64(i64, i64)

declare i32 @llvm.usub.sat.i32(i32, i32)

define i64 @calls_plain(ptr %callee, i64 %a, i64 %b, ptr %out) {
entry:
  %r = call i64 %callee(i64 %b, i64 %a)
  store i64 %r, ptr %out, align 8
  %live = xor i64 %a, %b
  %result = add i64 %r, %live
  ret i64 %result
}


define i64 @calls_loaded(ptr %callee, i64 %a, i64 %b, ptr %out) {
entry:
  %target = load ptr, ptr %callee, align 8
  %r = call i64 %target(i64 %b, i64 %a)
  store i64 %r, ptr %out, align 8
  %live = xor i64 %a, %b
  %result = add i64 %r, %live
  ret i64 %result
}


define i64 @calls_returned(ptr %callee, i64 %a, i64 %b, ptr %out) {
entry:
  %target = call ptr @calls_get_target(ptr %callee)
  %r = call i64 %target(i64 %b, i64 %a)
  store i64 %r, ptr %out, align 8
  %live = xor i64 %a, %b
  %result = add i64 %r, %live
  ret i64 %result
}


define i64 @calls_alias(ptr %callee, i64 %a) {
entry:
  %r = call i64 %callee(ptr %callee, i64 %a)
  ret i64 %r
}


define i64 @calls_pair(ptr %callee, ptr %p, i64 %a, ptr %out) {
entry:
  %r = call { ptr, i64 } %callee(ptr %p, i64 %a)
  store { ptr, i64 } %r, ptr %out, align 8
  %n = extractvalue { ptr, i64 } %r, 1
  %result = xor i64 %n, %a
  ret i64 %result
}


define ptr @calls_pointer(ptr %callee, ptr %p) {
entry:
  %r = call ptr %callee(ptr %p)
  ret ptr %r
}


define i64 @calls_noargs(ptr %callee) {
entry:
  %r = call i64 %callee()
  ret i64 %r
}


define i64 @calls_narrow_1(ptr %callee, i64 %a, i64 %b, ptr %out) {
entry:
  %x = trunc i64 %a to i1
  %r = call i1 %callee(i1 %x)
  %wide = zext i1 %r to i64
  store i64 %wide, ptr %out, align 8
  %live = xor i64 %a, %b
  %result = add i64 %wide, %live
  ret i64 %result
}


define i64 @calls_narrow_8(ptr %callee, i64 %a, i64 %b, ptr %out) {
entry:
  %x = trunc i64 %a to i8
  %r = call i8 %callee(i8 %x)
  %wide = zext i8 %r to i64
  store i64 %wide, ptr %out, align 8
  %live = xor i64 %a, %b
  %result = add i64 %wide, %live
  ret i64 %result
}


define i64 @calls_narrow_16(ptr %callee, i64 %a, i64 %b, ptr %out) {
entry:
  %x = trunc i64 %a to i16
  %r = call i16 %callee(i16 %x)
  %wide = zext i16 %r to i64
  store i64 %wide, ptr %out, align 8
  %live = xor i64 %a, %b
  %result = add i64 %wide, %live
  ret i64 %result
}


define i64 @calls_entry_7(i64 %a0, i64 %a1, i64 %a2, i64 %a3, i64 %a4, i64 %a5, i64 %a6) {
entry:
  %v0 = mul i64 %a0, 1
  %v1 = mul i64 %a1, 3
  %sum1 = add i64 %v0, %v1
  %v2 = mul i64 %a2, 5
  %sum2 = add i64 %sum1, %v2
  %v3 = mul i64 %a3, 7
  %sum3 = add i64 %sum2, %v3
  %v4 = mul i64 %a4, 9
  %sum4 = add i64 %sum3, %v4
  %v5 = mul i64 %a5, 11
  %sum5 = add i64 %sum4, %v5
  %v6 = mul i64 %a6, 13
  %sum6 = add i64 %sum5, %v6
  ret i64 %sum6
}


declare i64 @calls_helper_7(i64, i64, i64, i64, i64, i64, i64)

define i64 @calls_out_7(ptr %callee, i64 %a, i64 %b, ptr %out) {
entry:
  %r = call i64 %callee(i64 %b, i64 %a, i64 %b, i64 %a, i64 %b, i64 %a, i64 %b)
  store i64 %r, ptr %out, align 8
  %live = xor i64 %a, %b
  %result = add i64 %r, %live
  ret i64 %result
}


define i64 @calls_entry_8(i64 %a0, i64 %a1, i64 %a2, i64 %a3, i64 %a4, i64 %a5, i64 %a6, i64 %a7) {
entry:
  %v0 = mul i64 %a0, 1
  %v1 = mul i64 %a1, 3
  %sum1 = add i64 %v0, %v1
  %v2 = mul i64 %a2, 5
  %sum2 = add i64 %sum1, %v2
  %v3 = mul i64 %a3, 7
  %sum3 = add i64 %sum2, %v3
  %v4 = mul i64 %a4, 9
  %sum4 = add i64 %sum3, %v4
  %v5 = mul i64 %a5, 11
  %sum5 = add i64 %sum4, %v5
  %v6 = mul i64 %a6, 13
  %sum6 = add i64 %sum5, %v6
  %v7 = mul i64 %a7, 15
  %sum7 = add i64 %sum6, %v7
  ret i64 %sum7
}


declare i64 @calls_helper_8(i64, i64, i64, i64, i64, i64, i64, i64)

define i64 @calls_out_8(ptr %callee, i64 %a, i64 %b, ptr %out) {
entry:
  %r = call i64 @calls_helper_8(i64 %b, i64 %a, i64 %b, i64 %a, i64 %b, i64 %a, i64 %b, i64 %a)
  store i64 %r, ptr %out, align 8
  %live = xor i64 %a, %b
  %result = add i64 %r, %live
  ret i64 %result
}


define i64 @calls_entry_9(i64 %a0, i64 %a1, i64 %a2, i64 %a3, i64 %a4, i64 %a5, i64 %a6, i64 %a7, i64 %a8) {
entry:
  %v0 = mul i64 %a0, 1
  %v1 = mul i64 %a1, 3
  %sum1 = add i64 %v0, %v1
  %v2 = mul i64 %a2, 5
  %sum2 = add i64 %sum1, %v2
  %v3 = mul i64 %a3, 7
  %sum3 = add i64 %sum2, %v3
  %v4 = mul i64 %a4, 9
  %sum4 = add i64 %sum3, %v4
  %v5 = mul i64 %a5, 11
  %sum5 = add i64 %sum4, %v5
  %v6 = mul i64 %a6, 13
  %sum6 = add i64 %sum5, %v6
  %v7 = mul i64 %a7, 15
  %sum7 = add i64 %sum6, %v7
  %v8 = mul i64 %a8, 17
  %sum8 = add i64 %sum7, %v8
  ret i64 %sum8
}


declare i64 @calls_helper_9(i64, i64, i64, i64, i64, i64, i64, i64, i64)

define i64 @calls_out_9(ptr %callee, i64 %a, i64 %b, ptr %out) {
entry:
  %r = call i64 %callee(i64 %b, i64 %a, i64 %b, i64 %a, i64 %b, i64 %a, i64 %b, i64 %a, i64 %b)
  store i64 %r, ptr %out, align 8
  %live = xor i64 %a, %b
  %result = add i64 %r, %live
  ret i64 %result
}


define i64 @calls_entry_16(i64 %a0, i64 %a1, i64 %a2, i64 %a3, i64 %a4, i64 %a5, i64 %a6, i64 %a7, i64 %a8, i64 %a9, i64 %a10, i64 %a11, i64 %a12, i64 %a13, i64 %a14, i64 %a15) {
entry:
  %v0 = mul i64 %a0, 1
  %v1 = mul i64 %a1, 3
  %sum1 = add i64 %v0, %v1
  %v2 = mul i64 %a2, 5
  %sum2 = add i64 %sum1, %v2
  %v3 = mul i64 %a3, 7
  %sum3 = add i64 %sum2, %v3
  %v4 = mul i64 %a4, 9
  %sum4 = add i64 %sum3, %v4
  %v5 = mul i64 %a5, 11
  %sum5 = add i64 %sum4, %v5
  %v6 = mul i64 %a6, 13
  %sum6 = add i64 %sum5, %v6
  %v7 = mul i64 %a7, 15
  %sum7 = add i64 %sum6, %v7
  %v8 = mul i64 %a8, 17
  %sum8 = add i64 %sum7, %v8
  %v9 = mul i64 %a9, 19
  %sum9 = add i64 %sum8, %v9
  %v10 = mul i64 %a10, 21
  %sum10 = add i64 %sum9, %v10
  %v11 = mul i64 %a11, 23
  %sum11 = add i64 %sum10, %v11
  %v12 = mul i64 %a12, 25
  %sum12 = add i64 %sum11, %v12
  %v13 = mul i64 %a13, 27
  %sum13 = add i64 %sum12, %v13
  %v14 = mul i64 %a14, 29
  %sum14 = add i64 %sum13, %v14
  %v15 = mul i64 %a15, 31
  %sum15 = add i64 %sum14, %v15
  ret i64 %sum15
}


declare i64 @calls_helper_16(i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64)

define i64 @calls_out_16(ptr %callee, i64 %a, i64 %b, ptr %out) {
entry:
  %r = call i64 @calls_helper_16(i64 %b, i64 %a, i64 %b, i64 %a, i64 %b, i64 %a, i64 %b, i64 %a, i64 %b, i64 %a, i64 %b, i64 %a, i64 %b, i64 %a, i64 %b, i64 %a)
  store i64 %r, ptr %out, align 8
  %live = xor i64 %a, %b
  %result = add i64 %r, %live
  ret i64 %result
}


define i64 @calls_frame(ptr %callee, i64 %a, i64 %b, ptr %out) {
entry:
  %slot = alloca i64, align 8
  store i64 %b, ptr %slot, align 8
  %x = trunc i64 %a to i32
  %r = call i64 %callee(i64 1, i64 2, i64 3, i64 4, i64 5, i64 6, i32 %x, ptr %slot, ptr null)
  %after = load i64, ptr %slot, align 8
  store i64 %after, ptr %out, align 8
  %live = xor i64 %a, %b
  %result = add i64 %r, %live
  ret i64 %result
}


define i32 @calls_sat32(i32 %a, i32 %b) {
entry:
  %r = call i32 @llvm.usub.sat.i32(i32 %a, i32 %b)
  ret i32 %r
}


define i64 @calls_sat64(i64 %a, i64 %b) {
entry:
  %r = call i64 @llvm.usub.sat.i64(i64 %a, i64 %b)
  ret i64 %r
}


define i64 @calls_sat_loaded(ptr %ap, ptr %bp, ptr %out) {
entry:
  %a = load i64, ptr %ap, align 8
  %b = load i64, ptr %bp, align 8
  %r = call i64 @llvm.usub.sat.i64(i64 %a, i64 %b)
  store i64 %r, ptr %out, align 8
  %live = xor i64 %a, %b
  ret i64 %live
}


define i64 @calls_constant(i64 %a, ptr %out) {
entry:
  %constant = extractvalue { ptr, i64 } { ptr null, i64 -9223372036854775808 }, 1
  store i64 %constant, ptr %out, align 8
  %cmp = icmp eq i64 0, %a
  %result = zext i1 %cmp to i64
  ret i64 %result
}


define i64 @calls_entry_mixed(i64 %a, i64 %b, i64 %c, i64 %d, i64 %e, i64 %f, i32 %x, ptr %p) {
entry:
  %wide = zext i32 %x to i64
  %word = load i64, ptr %p, align 8
  %sum = add i64 %wide, %word
  %r = xor i64 %sum, %a
  ret i64 %r
}

define i64 @calls_entry_branch(i64 %a, i64 %b, i64 %c, i64 %d, i64 %e, i64 %f, i64 %g) {
entry:
  %condition = icmp eq i64 %g, 0
  br i1 %condition, label %zero, label %other
zero:
  %x = add i64 %a, %f
  ret i64 %x
other:
  %y = xor i64 %g, %b
  ret i64 %y
}

define i64 @calls_repeated(ptr %callee, i64 %a, i64 %b, ptr %out) {
entry:
  %first = call i64 %callee(i64 %b, i64 %a, i64 %b, i64 %a, i64 %b, i64 %a, i64 %b, i64 %a, i64 %b)
  %second = call i64 %callee(i64 %a, i64 %b, i64 %a, i64 %b, i64 %a, i64 %b, i64 %a, i64 %b, i64 %a)
  store i64 %first, ptr %out, align 8
  %live = xor i64 %first, %second
  %r = add i64 %live, %a
  ret i64 %r
}
