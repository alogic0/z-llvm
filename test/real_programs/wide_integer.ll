target triple = "x86_64-unknown-linux-gnu"
declare i64 @wide_clobber(i64)
declare { i65, i1 } @llvm.uadd.with.overflow.i65(i65, i65)
declare { i65, i1 } @llvm.usub.with.overflow.i65(i65, i65)
declare { i65, i1 } @llvm.sadd.with.overflow.i65(i65, i65)
declare { i65, i1 } @llvm.ssub.with.overflow.i65(i65, i65)
declare { i96, i1 } @llvm.uadd.with.overflow.i96(i96, i96)
declare { i96, i1 } @llvm.usub.with.overflow.i96(i96, i96)
declare { i96, i1 } @llvm.sadd.with.overflow.i96(i96, i96)
declare { i96, i1 } @llvm.ssub.with.overflow.i96(i96, i96)

define i64 @wide_65_add(i65 %a, i65 %b, i64 %live, ptr %out) {
entry:
  %v = add i65 %a, %b
  %noise = call i64 @wide_clobber(i64 %live)
  %lo = trunc i65 %v to i64
  %upper = lshr i65 %v, 64
  %hi = trunc i65 %upper to i64
  %p = getelementptr i8, ptr %out, i64 8
  %fp = getelementptr i8, ptr %out, i64 16
  store i64 %lo, ptr %out, align 8
  store i64 %hi, ptr %p, align 8
  store i64 0, ptr %fp, align 8
  %sum = add i64 %lo, %hi
  %answer = xor i64 %sum, %noise
  ret i64 %answer
}

define i64 @wide_65_sub(i65 %a, i65 %b, i64 %live, ptr %out) {
entry:
  %v = sub i65 %a, %b
  %noise = call i64 @wide_clobber(i64 %live)
  %lo = trunc i65 %v to i64
  %upper = lshr i65 %v, 64
  %hi = trunc i65 %upper to i64
  %p = getelementptr i8, ptr %out, i64 8
  %fp = getelementptr i8, ptr %out, i64 16
  store i64 %lo, ptr %out, align 8
  store i64 %hi, ptr %p, align 8
  store i64 0, ptr %fp, align 8
  %sum = add i64 %lo, %hi
  %answer = xor i64 %sum, %noise
  ret i64 %answer
}

define i64 @wide_65_mul(i65 %a, i65 %b, i64 %live, ptr %out) {
entry:
  %v = mul i65 %a, %b
  %noise = call i64 @wide_clobber(i64 %live)
  %lo = trunc i65 %v to i64
  %upper = lshr i65 %v, 64
  %hi = trunc i65 %upper to i64
  %p = getelementptr i8, ptr %out, i64 8
  %fp = getelementptr i8, ptr %out, i64 16
  store i64 %lo, ptr %out, align 8
  store i64 %hi, ptr %p, align 8
  store i64 0, ptr %fp, align 8
  %sum = add i64 %lo, %hi
  %answer = xor i64 %sum, %noise
  ret i64 %answer
}

define i64 @wide_65_and(i65 %a, i65 %b, i64 %live, ptr %out) {
entry:
  %v = and i65 %a, %b
  %noise = call i64 @wide_clobber(i64 %live)
  %lo = trunc i65 %v to i64
  %upper = lshr i65 %v, 64
  %hi = trunc i65 %upper to i64
  %p = getelementptr i8, ptr %out, i64 8
  %fp = getelementptr i8, ptr %out, i64 16
  store i64 %lo, ptr %out, align 8
  store i64 %hi, ptr %p, align 8
  store i64 0, ptr %fp, align 8
  %sum = add i64 %lo, %hi
  %answer = xor i64 %sum, %noise
  ret i64 %answer
}

define i64 @wide_65_xor(i65 %a, i65 %b, i64 %live, ptr %out) {
entry:
  %v = xor i65 %a, %b
  %noise = call i64 @wide_clobber(i64 %live)
  %lo = trunc i65 %v to i64
  %upper = lshr i65 %v, 64
  %hi = trunc i65 %upper to i64
  %p = getelementptr i8, ptr %out, i64 8
  %fp = getelementptr i8, ptr %out, i64 16
  store i64 %lo, ptr %out, align 8
  store i64 %hi, ptr %p, align 8
  store i64 0, ptr %fp, align 8
  %sum = add i64 %lo, %hi
  %answer = xor i64 %sum, %noise
  ret i64 %answer
}

define i64 @wide_65_or_literal(i65 %a, i65 %b, i64 %live, ptr %out) {
entry:
  %v = or i65 %a, 9223372036854775811
  %noise = call i64 @wide_clobber(i64 %live)
  %lo = trunc i65 %v to i64
  %upper = lshr i65 %v, 64
  %hi = trunc i65 %upper to i64
  %p = getelementptr i8, ptr %out, i64 8
  %fp = getelementptr i8, ptr %out, i64 16
  store i64 %lo, ptr %out, align 8
  store i64 %hi, ptr %p, align 8
  store i64 0, ptr %fp, align 8
  %sum = add i64 %lo, %hi
  %answer = xor i64 %sum, %noise
  ret i64 %answer
}

define i64 @wide_65_shl(i65 %a, i65 %b, i64 %live, ptr %out) {
entry:
  %count = and i65 %b, 63
  %v = shl i65 %a, %count
  %noise = call i64 @wide_clobber(i64 %live)
  %lo = trunc i65 %v to i64
  %upper = lshr i65 %v, 64
  %hi = trunc i65 %upper to i64
  %p = getelementptr i8, ptr %out, i64 8
  %fp = getelementptr i8, ptr %out, i64 16
  store i64 %lo, ptr %out, align 8
  store i64 %hi, ptr %p, align 8
  store i64 0, ptr %fp, align 8
  %sum = add i64 %lo, %hi
  %answer = xor i64 %sum, %noise
  ret i64 %answer
}

define i64 @wide_65_shl_top(i65 %a, i65 %b, i64 %live, ptr %out) {
entry:
  %v = shl i65 %a, 64
  %noise = call i64 @wide_clobber(i64 %live)
  %lo = trunc i65 %v to i64
  %upper = lshr i65 %v, 64
  %hi = trunc i65 %upper to i64
  %p = getelementptr i8, ptr %out, i64 8
  %fp = getelementptr i8, ptr %out, i64 16
  store i64 %lo, ptr %out, align 8
  store i64 %hi, ptr %p, align 8
  store i64 0, ptr %fp, align 8
  %sum = add i64 %lo, %hi
  %answer = xor i64 %sum, %noise
  ret i64 %answer
}

define i64 @wide_65_lshr(i65 %a, i65 %b, i64 %live, ptr %out) {
entry:
  %count = and i65 %b, 63
  %v = lshr i65 %a, %count
  %noise = call i64 @wide_clobber(i64 %live)
  %lo = trunc i65 %v to i64
  %upper = lshr i65 %v, 64
  %hi = trunc i65 %upper to i64
  %p = getelementptr i8, ptr %out, i64 8
  %fp = getelementptr i8, ptr %out, i64 16
  store i64 %lo, ptr %out, align 8
  store i64 %hi, ptr %p, align 8
  store i64 0, ptr %fp, align 8
  %sum = add i64 %lo, %hi
  %answer = xor i64 %sum, %noise
  ret i64 %answer
}

define i64 @wide_65_lshr_top(i65 %a, i65 %b, i64 %live, ptr %out) {
entry:
  %v = lshr i65 %a, 64
  %noise = call i64 @wide_clobber(i64 %live)
  %lo = trunc i65 %v to i64
  %upper = lshr i65 %v, 64
  %hi = trunc i65 %upper to i64
  %p = getelementptr i8, ptr %out, i64 8
  %fp = getelementptr i8, ptr %out, i64 16
  store i64 %lo, ptr %out, align 8
  store i64 %hi, ptr %p, align 8
  store i64 0, ptr %fp, align 8
  %sum = add i64 %lo, %hi
  %answer = xor i64 %sum, %noise
  ret i64 %answer
}

define i64 @wide_65_ashr(i65 %a, i65 %b, i64 %live, ptr %out) {
entry:
  %count = and i65 %b, 63
  %v = ashr i65 %a, %count
  %noise = call i64 @wide_clobber(i64 %live)
  %lo = trunc i65 %v to i64
  %upper = lshr i65 %v, 64
  %hi = trunc i65 %upper to i64
  %p = getelementptr i8, ptr %out, i64 8
  %fp = getelementptr i8, ptr %out, i64 16
  store i64 %lo, ptr %out, align 8
  store i64 %hi, ptr %p, align 8
  store i64 0, ptr %fp, align 8
  %sum = add i64 %lo, %hi
  %answer = xor i64 %sum, %noise
  ret i64 %answer
}

define i64 @wide_65_ashr_top(i65 %a, i65 %b, i64 %live, ptr %out) {
entry:
  %v = ashr i65 %a, 64
  %noise = call i64 @wide_clobber(i64 %live)
  %lo = trunc i65 %v to i64
  %upper = lshr i65 %v, 64
  %hi = trunc i65 %upper to i64
  %p = getelementptr i8, ptr %out, i64 8
  %fp = getelementptr i8, ptr %out, i64 16
  store i64 %lo, ptr %out, align 8
  store i64 %hi, ptr %p, align 8
  store i64 0, ptr %fp, align 8
  %sum = add i64 %lo, %hi
  %answer = xor i64 %sum, %noise
  ret i64 %answer
}

define i64 @wide_65_sdiv(i65 %a, i65 %b, i64 %live, ptr %out) {
entry:
  %v = sdiv i65 %a, 3
  %noise = call i64 @wide_clobber(i64 %live)
  %lo = trunc i65 %v to i64
  %upper = lshr i65 %v, 64
  %hi = trunc i65 %upper to i64
  %p = getelementptr i8, ptr %out, i64 8
  %fp = getelementptr i8, ptr %out, i64 16
  store i64 %lo, ptr %out, align 8
  store i64 %hi, ptr %p, align 8
  store i64 0, ptr %fp, align 8
  %sum = add i64 %lo, %hi
  %answer = xor i64 %sum, %noise
  ret i64 %answer
}

define i64 @wide_65_srem(i65 %a, i65 %b, i64 %live, ptr %out) {
entry:
  %v = srem i65 %a, 3
  %noise = call i64 @wide_clobber(i64 %live)
  %lo = trunc i65 %v to i64
  %upper = lshr i65 %v, 64
  %hi = trunc i65 %upper to i64
  %p = getelementptr i8, ptr %out, i64 8
  %fp = getelementptr i8, ptr %out, i64 16
  store i64 %lo, ptr %out, align 8
  store i64 %hi, ptr %p, align 8
  store i64 0, ptr %fp, align 8
  %sum = add i64 %lo, %hi
  %answer = xor i64 %sum, %noise
  ret i64 %answer
}

define i64 @wide_65_udiv(i65 %a, i65 %b, i64 %live, ptr %out) {
entry:
  %v = udiv i65 %a, 3
  %noise = call i64 @wide_clobber(i64 %live)
  %lo = trunc i65 %v to i64
  %upper = lshr i65 %v, 64
  %hi = trunc i65 %upper to i64
  %p = getelementptr i8, ptr %out, i64 8
  %fp = getelementptr i8, ptr %out, i64 16
  store i64 %lo, ptr %out, align 8
  store i64 %hi, ptr %p, align 8
  store i64 0, ptr %fp, align 8
  %sum = add i64 %lo, %hi
  %answer = xor i64 %sum, %noise
  ret i64 %answer
}

define i64 @wide_65_urem(i65 %a, i65 %b, i64 %live, ptr %out) {
entry:
  %v = urem i65 %a, 3
  %noise = call i64 @wide_clobber(i64 %live)
  %lo = trunc i65 %v to i64
  %upper = lshr i65 %v, 64
  %hi = trunc i65 %upper to i64
  %p = getelementptr i8, ptr %out, i64 8
  %fp = getelementptr i8, ptr %out, i64 16
  store i64 %lo, ptr %out, align 8
  store i64 %hi, ptr %p, align 8
  store i64 0, ptr %fp, align 8
  %sum = add i64 %lo, %hi
  %answer = xor i64 %sum, %noise
  ret i64 %answer
}

define i64 @wide_65_zext(i65 %a, i65 %b, i64 %live, ptr %out) {
entry:
  %byte = trunc i65 %a to i8
  %v = zext i8 %byte to i65
  %noise = call i64 @wide_clobber(i64 %live)
  %lo = trunc i65 %v to i64
  %upper = lshr i65 %v, 64
  %hi = trunc i65 %upper to i64
  %p = getelementptr i8, ptr %out, i64 8
  %fp = getelementptr i8, ptr %out, i64 16
  store i64 %lo, ptr %out, align 8
  store i64 %hi, ptr %p, align 8
  store i64 0, ptr %fp, align 8
  %sum = add i64 %lo, %hi
  %answer = xor i64 %sum, %noise
  ret i64 %answer
}

define i64 @wide_65_sext(i65 %a, i65 %b, i64 %live, ptr %out) {
entry:
  %byte = trunc i65 %a to i8
  %v = sext i8 %byte to i65
  %noise = call i64 @wide_clobber(i64 %live)
  %lo = trunc i65 %v to i64
  %upper = lshr i65 %v, 64
  %hi = trunc i65 %upper to i64
  %p = getelementptr i8, ptr %out, i64 8
  %fp = getelementptr i8, ptr %out, i64 16
  store i64 %lo, ptr %out, align 8
  store i64 %hi, ptr %p, align 8
  store i64 0, ptr %fp, align 8
  %sum = add i64 %lo, %hi
  %answer = xor i64 %sum, %noise
  ret i64 %answer
}

define i64 @wide_65_slt(i65 %a, i65 %b, i64 %live, ptr %out) {
entry:
  %cmp = icmp slt i65 %a, %b
  %v = zext i1 %cmp to i65
  %noise = call i64 @wide_clobber(i64 %live)
  %lo = trunc i65 %v to i64
  %upper = lshr i65 %v, 64
  %hi = trunc i65 %upper to i64
  %p = getelementptr i8, ptr %out, i64 8
  %fp = getelementptr i8, ptr %out, i64 16
  store i64 %lo, ptr %out, align 8
  store i64 %hi, ptr %p, align 8
  store i64 0, ptr %fp, align 8
  %sum = add i64 %lo, %hi
  %answer = xor i64 %sum, %noise
  ret i64 %answer
}

define i64 @wide_65_select(i65 %a, i65 %b, i64 %live, ptr %out) {
entry:
  %cond = trunc i65 %b to i1
  %v = select i1 %cond, i65 %a, i65 %b
  %noise = call i64 @wide_clobber(i64 %live)
  %lo = trunc i65 %v to i64
  %upper = lshr i65 %v, 64
  %hi = trunc i65 %upper to i64
  %p = getelementptr i8, ptr %out, i64 8
  %fp = getelementptr i8, ptr %out, i64 16
  store i64 %lo, ptr %out, align 8
  store i64 %hi, ptr %p, align 8
  store i64 0, ptr %fp, align 8
  %sum = add i64 %lo, %hi
  %answer = xor i64 %sum, %noise
  ret i64 %answer
}

define i64 @wide_65_uadd_checked(i65 %a, i65 %b, i64 %live, ptr %out) {
entry:
  %checked = call { i65, i1 } @llvm.uadd.with.overflow.i65(i65 %a, i65 %b)
  %v = extractvalue { i65, i1 } %checked, 0
  %overflow = extractvalue { i65, i1 } %checked, 1
  %flag = zext i1 %overflow to i64
  %noise = call i64 @wide_clobber(i64 %live)
  %lo = trunc i65 %v to i64
  %upper = lshr i65 %v, 64
  %hi = trunc i65 %upper to i64
  %p = getelementptr i8, ptr %out, i64 8
  %fp = getelementptr i8, ptr %out, i64 16
  store i64 %lo, ptr %out, align 8
  store i64 %hi, ptr %p, align 8
  store i64 %flag, ptr %fp, align 8
  %sum = add i64 %lo, %hi
  %answer = xor i64 %sum, %noise
  ret i64 %answer
}

define i64 @wide_65_usub_checked(i65 %a, i65 %b, i64 %live, ptr %out) {
entry:
  %checked = call { i65, i1 } @llvm.usub.with.overflow.i65(i65 %a, i65 %b)
  %v = extractvalue { i65, i1 } %checked, 0
  %overflow = extractvalue { i65, i1 } %checked, 1
  %flag = zext i1 %overflow to i64
  %noise = call i64 @wide_clobber(i64 %live)
  %lo = trunc i65 %v to i64
  %upper = lshr i65 %v, 64
  %hi = trunc i65 %upper to i64
  %p = getelementptr i8, ptr %out, i64 8
  %fp = getelementptr i8, ptr %out, i64 16
  store i64 %lo, ptr %out, align 8
  store i64 %hi, ptr %p, align 8
  store i64 %flag, ptr %fp, align 8
  %sum = add i64 %lo, %hi
  %answer = xor i64 %sum, %noise
  ret i64 %answer
}

define i64 @wide_65_sadd_checked(i65 %a, i65 %b, i64 %live, ptr %out) {
entry:
  %checked = call { i65, i1 } @llvm.sadd.with.overflow.i65(i65 %a, i65 %b)
  %v = extractvalue { i65, i1 } %checked, 0
  %overflow = extractvalue { i65, i1 } %checked, 1
  %flag = zext i1 %overflow to i64
  %noise = call i64 @wide_clobber(i64 %live)
  %lo = trunc i65 %v to i64
  %upper = lshr i65 %v, 64
  %hi = trunc i65 %upper to i64
  %p = getelementptr i8, ptr %out, i64 8
  %fp = getelementptr i8, ptr %out, i64 16
  store i64 %lo, ptr %out, align 8
  store i64 %hi, ptr %p, align 8
  store i64 %flag, ptr %fp, align 8
  %sum = add i64 %lo, %hi
  %answer = xor i64 %sum, %noise
  ret i64 %answer
}

define i64 @wide_65_ssub_checked(i65 %a, i65 %b, i64 %live, ptr %out) {
entry:
  %checked = call { i65, i1 } @llvm.ssub.with.overflow.i65(i65 %a, i65 %b)
  %v = extractvalue { i65, i1 } %checked, 0
  %overflow = extractvalue { i65, i1 } %checked, 1
  %flag = zext i1 %overflow to i64
  %noise = call i64 @wide_clobber(i64 %live)
  %lo = trunc i65 %v to i64
  %upper = lshr i65 %v, 64
  %hi = trunc i65 %upper to i64
  %p = getelementptr i8, ptr %out, i64 8
  %fp = getelementptr i8, ptr %out, i64 16
  store i64 %lo, ptr %out, align 8
  store i64 %hi, ptr %p, align 8
  store i64 %flag, ptr %fp, align 8
  %sum = add i64 %lo, %hi
  %answer = xor i64 %sum, %noise
  ret i64 %answer
}

define i64 @wide_96_add(i96 %a, i96 %b, i64 %live, ptr %out) {
entry:
  %v = add i96 %a, %b
  %noise = call i64 @wide_clobber(i64 %live)
  %lo = trunc i96 %v to i64
  %upper = lshr i96 %v, 64
  %hi = trunc i96 %upper to i64
  %p = getelementptr i8, ptr %out, i64 8
  %fp = getelementptr i8, ptr %out, i64 16
  store i64 %lo, ptr %out, align 8
  store i64 %hi, ptr %p, align 8
  store i64 0, ptr %fp, align 8
  %sum = add i64 %lo, %hi
  %answer = xor i64 %sum, %noise
  ret i64 %answer
}

define i64 @wide_96_sub(i96 %a, i96 %b, i64 %live, ptr %out) {
entry:
  %v = sub i96 %a, %b
  %noise = call i64 @wide_clobber(i64 %live)
  %lo = trunc i96 %v to i64
  %upper = lshr i96 %v, 64
  %hi = trunc i96 %upper to i64
  %p = getelementptr i8, ptr %out, i64 8
  %fp = getelementptr i8, ptr %out, i64 16
  store i64 %lo, ptr %out, align 8
  store i64 %hi, ptr %p, align 8
  store i64 0, ptr %fp, align 8
  %sum = add i64 %lo, %hi
  %answer = xor i64 %sum, %noise
  ret i64 %answer
}

define i64 @wide_96_mul(i96 %a, i96 %b, i64 %live, ptr %out) {
entry:
  %v = mul i96 %a, %b
  %noise = call i64 @wide_clobber(i64 %live)
  %lo = trunc i96 %v to i64
  %upper = lshr i96 %v, 64
  %hi = trunc i96 %upper to i64
  %p = getelementptr i8, ptr %out, i64 8
  %fp = getelementptr i8, ptr %out, i64 16
  store i64 %lo, ptr %out, align 8
  store i64 %hi, ptr %p, align 8
  store i64 0, ptr %fp, align 8
  %sum = add i64 %lo, %hi
  %answer = xor i64 %sum, %noise
  ret i64 %answer
}

define i64 @wide_96_and(i96 %a, i96 %b, i64 %live, ptr %out) {
entry:
  %v = and i96 %a, %b
  %noise = call i64 @wide_clobber(i64 %live)
  %lo = trunc i96 %v to i64
  %upper = lshr i96 %v, 64
  %hi = trunc i96 %upper to i64
  %p = getelementptr i8, ptr %out, i64 8
  %fp = getelementptr i8, ptr %out, i64 16
  store i64 %lo, ptr %out, align 8
  store i64 %hi, ptr %p, align 8
  store i64 0, ptr %fp, align 8
  %sum = add i64 %lo, %hi
  %answer = xor i64 %sum, %noise
  ret i64 %answer
}

define i64 @wide_96_xor(i96 %a, i96 %b, i64 %live, ptr %out) {
entry:
  %v = xor i96 %a, %b
  %noise = call i64 @wide_clobber(i64 %live)
  %lo = trunc i96 %v to i64
  %upper = lshr i96 %v, 64
  %hi = trunc i96 %upper to i64
  %p = getelementptr i8, ptr %out, i64 8
  %fp = getelementptr i8, ptr %out, i64 16
  store i64 %lo, ptr %out, align 8
  store i64 %hi, ptr %p, align 8
  store i64 0, ptr %fp, align 8
  %sum = add i64 %lo, %hi
  %answer = xor i64 %sum, %noise
  ret i64 %answer
}

define i64 @wide_96_or_literal(i96 %a, i96 %b, i64 %live, ptr %out) {
entry:
  %v = or i96 %a, 9223372036854775811
  %noise = call i64 @wide_clobber(i64 %live)
  %lo = trunc i96 %v to i64
  %upper = lshr i96 %v, 64
  %hi = trunc i96 %upper to i64
  %p = getelementptr i8, ptr %out, i64 8
  %fp = getelementptr i8, ptr %out, i64 16
  store i64 %lo, ptr %out, align 8
  store i64 %hi, ptr %p, align 8
  store i64 0, ptr %fp, align 8
  %sum = add i64 %lo, %hi
  %answer = xor i64 %sum, %noise
  ret i64 %answer
}

define i64 @wide_96_shl(i96 %a, i96 %b, i64 %live, ptr %out) {
entry:
  %count = and i96 %b, 63
  %v = shl i96 %a, %count
  %noise = call i64 @wide_clobber(i64 %live)
  %lo = trunc i96 %v to i64
  %upper = lshr i96 %v, 64
  %hi = trunc i96 %upper to i64
  %p = getelementptr i8, ptr %out, i64 8
  %fp = getelementptr i8, ptr %out, i64 16
  store i64 %lo, ptr %out, align 8
  store i64 %hi, ptr %p, align 8
  store i64 0, ptr %fp, align 8
  %sum = add i64 %lo, %hi
  %answer = xor i64 %sum, %noise
  ret i64 %answer
}

define i64 @wide_96_shl_top(i96 %a, i96 %b, i64 %live, ptr %out) {
entry:
  %v = shl i96 %a, 95
  %noise = call i64 @wide_clobber(i64 %live)
  %lo = trunc i96 %v to i64
  %upper = lshr i96 %v, 64
  %hi = trunc i96 %upper to i64
  %p = getelementptr i8, ptr %out, i64 8
  %fp = getelementptr i8, ptr %out, i64 16
  store i64 %lo, ptr %out, align 8
  store i64 %hi, ptr %p, align 8
  store i64 0, ptr %fp, align 8
  %sum = add i64 %lo, %hi
  %answer = xor i64 %sum, %noise
  ret i64 %answer
}

define i64 @wide_96_lshr(i96 %a, i96 %b, i64 %live, ptr %out) {
entry:
  %count = and i96 %b, 63
  %v = lshr i96 %a, %count
  %noise = call i64 @wide_clobber(i64 %live)
  %lo = trunc i96 %v to i64
  %upper = lshr i96 %v, 64
  %hi = trunc i96 %upper to i64
  %p = getelementptr i8, ptr %out, i64 8
  %fp = getelementptr i8, ptr %out, i64 16
  store i64 %lo, ptr %out, align 8
  store i64 %hi, ptr %p, align 8
  store i64 0, ptr %fp, align 8
  %sum = add i64 %lo, %hi
  %answer = xor i64 %sum, %noise
  ret i64 %answer
}

define i64 @wide_96_lshr_top(i96 %a, i96 %b, i64 %live, ptr %out) {
entry:
  %v = lshr i96 %a, 95
  %noise = call i64 @wide_clobber(i64 %live)
  %lo = trunc i96 %v to i64
  %upper = lshr i96 %v, 64
  %hi = trunc i96 %upper to i64
  %p = getelementptr i8, ptr %out, i64 8
  %fp = getelementptr i8, ptr %out, i64 16
  store i64 %lo, ptr %out, align 8
  store i64 %hi, ptr %p, align 8
  store i64 0, ptr %fp, align 8
  %sum = add i64 %lo, %hi
  %answer = xor i64 %sum, %noise
  ret i64 %answer
}

define i64 @wide_96_ashr(i96 %a, i96 %b, i64 %live, ptr %out) {
entry:
  %count = and i96 %b, 63
  %v = ashr i96 %a, %count
  %noise = call i64 @wide_clobber(i64 %live)
  %lo = trunc i96 %v to i64
  %upper = lshr i96 %v, 64
  %hi = trunc i96 %upper to i64
  %p = getelementptr i8, ptr %out, i64 8
  %fp = getelementptr i8, ptr %out, i64 16
  store i64 %lo, ptr %out, align 8
  store i64 %hi, ptr %p, align 8
  store i64 0, ptr %fp, align 8
  %sum = add i64 %lo, %hi
  %answer = xor i64 %sum, %noise
  ret i64 %answer
}

define i64 @wide_96_ashr_top(i96 %a, i96 %b, i64 %live, ptr %out) {
entry:
  %v = ashr i96 %a, 95
  %noise = call i64 @wide_clobber(i64 %live)
  %lo = trunc i96 %v to i64
  %upper = lshr i96 %v, 64
  %hi = trunc i96 %upper to i64
  %p = getelementptr i8, ptr %out, i64 8
  %fp = getelementptr i8, ptr %out, i64 16
  store i64 %lo, ptr %out, align 8
  store i64 %hi, ptr %p, align 8
  store i64 0, ptr %fp, align 8
  %sum = add i64 %lo, %hi
  %answer = xor i64 %sum, %noise
  ret i64 %answer
}

define i64 @wide_96_sdiv(i96 %a, i96 %b, i64 %live, ptr %out) {
entry:
  %v = sdiv i96 %a, 3
  %noise = call i64 @wide_clobber(i64 %live)
  %lo = trunc i96 %v to i64
  %upper = lshr i96 %v, 64
  %hi = trunc i96 %upper to i64
  %p = getelementptr i8, ptr %out, i64 8
  %fp = getelementptr i8, ptr %out, i64 16
  store i64 %lo, ptr %out, align 8
  store i64 %hi, ptr %p, align 8
  store i64 0, ptr %fp, align 8
  %sum = add i64 %lo, %hi
  %answer = xor i64 %sum, %noise
  ret i64 %answer
}

define i64 @wide_96_srem(i96 %a, i96 %b, i64 %live, ptr %out) {
entry:
  %v = srem i96 %a, 3
  %noise = call i64 @wide_clobber(i64 %live)
  %lo = trunc i96 %v to i64
  %upper = lshr i96 %v, 64
  %hi = trunc i96 %upper to i64
  %p = getelementptr i8, ptr %out, i64 8
  %fp = getelementptr i8, ptr %out, i64 16
  store i64 %lo, ptr %out, align 8
  store i64 %hi, ptr %p, align 8
  store i64 0, ptr %fp, align 8
  %sum = add i64 %lo, %hi
  %answer = xor i64 %sum, %noise
  ret i64 %answer
}

define i64 @wide_96_udiv(i96 %a, i96 %b, i64 %live, ptr %out) {
entry:
  %v = udiv i96 %a, 3
  %noise = call i64 @wide_clobber(i64 %live)
  %lo = trunc i96 %v to i64
  %upper = lshr i96 %v, 64
  %hi = trunc i96 %upper to i64
  %p = getelementptr i8, ptr %out, i64 8
  %fp = getelementptr i8, ptr %out, i64 16
  store i64 %lo, ptr %out, align 8
  store i64 %hi, ptr %p, align 8
  store i64 0, ptr %fp, align 8
  %sum = add i64 %lo, %hi
  %answer = xor i64 %sum, %noise
  ret i64 %answer
}

define i64 @wide_96_urem(i96 %a, i96 %b, i64 %live, ptr %out) {
entry:
  %v = urem i96 %a, 3
  %noise = call i64 @wide_clobber(i64 %live)
  %lo = trunc i96 %v to i64
  %upper = lshr i96 %v, 64
  %hi = trunc i96 %upper to i64
  %p = getelementptr i8, ptr %out, i64 8
  %fp = getelementptr i8, ptr %out, i64 16
  store i64 %lo, ptr %out, align 8
  store i64 %hi, ptr %p, align 8
  store i64 0, ptr %fp, align 8
  %sum = add i64 %lo, %hi
  %answer = xor i64 %sum, %noise
  ret i64 %answer
}

define i64 @wide_96_zext(i96 %a, i96 %b, i64 %live, ptr %out) {
entry:
  %byte = trunc i96 %a to i8
  %v = zext i8 %byte to i96
  %noise = call i64 @wide_clobber(i64 %live)
  %lo = trunc i96 %v to i64
  %upper = lshr i96 %v, 64
  %hi = trunc i96 %upper to i64
  %p = getelementptr i8, ptr %out, i64 8
  %fp = getelementptr i8, ptr %out, i64 16
  store i64 %lo, ptr %out, align 8
  store i64 %hi, ptr %p, align 8
  store i64 0, ptr %fp, align 8
  %sum = add i64 %lo, %hi
  %answer = xor i64 %sum, %noise
  ret i64 %answer
}

define i64 @wide_96_sext(i96 %a, i96 %b, i64 %live, ptr %out) {
entry:
  %byte = trunc i96 %a to i8
  %v = sext i8 %byte to i96
  %noise = call i64 @wide_clobber(i64 %live)
  %lo = trunc i96 %v to i64
  %upper = lshr i96 %v, 64
  %hi = trunc i96 %upper to i64
  %p = getelementptr i8, ptr %out, i64 8
  %fp = getelementptr i8, ptr %out, i64 16
  store i64 %lo, ptr %out, align 8
  store i64 %hi, ptr %p, align 8
  store i64 0, ptr %fp, align 8
  %sum = add i64 %lo, %hi
  %answer = xor i64 %sum, %noise
  ret i64 %answer
}

define i64 @wide_96_slt(i96 %a, i96 %b, i64 %live, ptr %out) {
entry:
  %cmp = icmp slt i96 %a, %b
  %v = zext i1 %cmp to i96
  %noise = call i64 @wide_clobber(i64 %live)
  %lo = trunc i96 %v to i64
  %upper = lshr i96 %v, 64
  %hi = trunc i96 %upper to i64
  %p = getelementptr i8, ptr %out, i64 8
  %fp = getelementptr i8, ptr %out, i64 16
  store i64 %lo, ptr %out, align 8
  store i64 %hi, ptr %p, align 8
  store i64 0, ptr %fp, align 8
  %sum = add i64 %lo, %hi
  %answer = xor i64 %sum, %noise
  ret i64 %answer
}

define i64 @wide_96_select(i96 %a, i96 %b, i64 %live, ptr %out) {
entry:
  %cond = trunc i96 %b to i1
  %v = select i1 %cond, i96 %a, i96 %b
  %noise = call i64 @wide_clobber(i64 %live)
  %lo = trunc i96 %v to i64
  %upper = lshr i96 %v, 64
  %hi = trunc i96 %upper to i64
  %p = getelementptr i8, ptr %out, i64 8
  %fp = getelementptr i8, ptr %out, i64 16
  store i64 %lo, ptr %out, align 8
  store i64 %hi, ptr %p, align 8
  store i64 0, ptr %fp, align 8
  %sum = add i64 %lo, %hi
  %answer = xor i64 %sum, %noise
  ret i64 %answer
}

define i64 @wide_96_uadd_checked(i96 %a, i96 %b, i64 %live, ptr %out) {
entry:
  %checked = call { i96, i1 } @llvm.uadd.with.overflow.i96(i96 %a, i96 %b)
  %v = extractvalue { i96, i1 } %checked, 0
  %overflow = extractvalue { i96, i1 } %checked, 1
  %flag = zext i1 %overflow to i64
  %noise = call i64 @wide_clobber(i64 %live)
  %lo = trunc i96 %v to i64
  %upper = lshr i96 %v, 64
  %hi = trunc i96 %upper to i64
  %p = getelementptr i8, ptr %out, i64 8
  %fp = getelementptr i8, ptr %out, i64 16
  store i64 %lo, ptr %out, align 8
  store i64 %hi, ptr %p, align 8
  store i64 %flag, ptr %fp, align 8
  %sum = add i64 %lo, %hi
  %answer = xor i64 %sum, %noise
  ret i64 %answer
}

define i64 @wide_96_usub_checked(i96 %a, i96 %b, i64 %live, ptr %out) {
entry:
  %checked = call { i96, i1 } @llvm.usub.with.overflow.i96(i96 %a, i96 %b)
  %v = extractvalue { i96, i1 } %checked, 0
  %overflow = extractvalue { i96, i1 } %checked, 1
  %flag = zext i1 %overflow to i64
  %noise = call i64 @wide_clobber(i64 %live)
  %lo = trunc i96 %v to i64
  %upper = lshr i96 %v, 64
  %hi = trunc i96 %upper to i64
  %p = getelementptr i8, ptr %out, i64 8
  %fp = getelementptr i8, ptr %out, i64 16
  store i64 %lo, ptr %out, align 8
  store i64 %hi, ptr %p, align 8
  store i64 %flag, ptr %fp, align 8
  %sum = add i64 %lo, %hi
  %answer = xor i64 %sum, %noise
  ret i64 %answer
}

define i64 @wide_96_sadd_checked(i96 %a, i96 %b, i64 %live, ptr %out) {
entry:
  %checked = call { i96, i1 } @llvm.sadd.with.overflow.i96(i96 %a, i96 %b)
  %v = extractvalue { i96, i1 } %checked, 0
  %overflow = extractvalue { i96, i1 } %checked, 1
  %flag = zext i1 %overflow to i64
  %noise = call i64 @wide_clobber(i64 %live)
  %lo = trunc i96 %v to i64
  %upper = lshr i96 %v, 64
  %hi = trunc i96 %upper to i64
  %p = getelementptr i8, ptr %out, i64 8
  %fp = getelementptr i8, ptr %out, i64 16
  store i64 %lo, ptr %out, align 8
  store i64 %hi, ptr %p, align 8
  store i64 %flag, ptr %fp, align 8
  %sum = add i64 %lo, %hi
  %answer = xor i64 %sum, %noise
  ret i64 %answer
}

define i64 @wide_96_ssub_checked(i96 %a, i96 %b, i64 %live, ptr %out) {
entry:
  %checked = call { i96, i1 } @llvm.ssub.with.overflow.i96(i96 %a, i96 %b)
  %v = extractvalue { i96, i1 } %checked, 0
  %overflow = extractvalue { i96, i1 } %checked, 1
  %flag = zext i1 %overflow to i64
  %noise = call i64 @wide_clobber(i64 %live)
  %lo = trunc i96 %v to i64
  %upper = lshr i96 %v, 64
  %hi = trunc i96 %upper to i64
  %p = getelementptr i8, ptr %out, i64 8
  %fp = getelementptr i8, ptr %out, i64 16
  store i64 %lo, ptr %out, align 8
  store i64 %hi, ptr %p, align 8
  store i64 %flag, ptr %fp, align 8
  %sum = add i64 %lo, %hi
  %answer = xor i64 %sum, %noise
  ret i64 %answer
}
