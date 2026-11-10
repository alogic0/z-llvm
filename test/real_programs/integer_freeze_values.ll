target triple = "x86_64-unknown-linux-gnu"
declare i64 @frontier_views_clobber(i64)

define i64 @freeze_values_33_alias(i64 %a, i64 %b, i64 %salt, ptr %out) {
entry:
  %raw = trunc i64 %a to i33
  %stable = freeze i33 %raw
  %clobber = call i64 @frontier_views_clobber(i64 %salt)
  %low = zext i33 %stable to i64
  %high = add i64 0, 0
  %again = freeze i33 %stable
  %same2 = xor i33 %stable, %again
  %check = icmp ne i33 %same2, 0
  %check64 = zext i1 %check to i64
  store i64 %low, ptr %out, align 8
  %p1 = getelementptr i8, ptr %out, i64 8
  store i64 %high, ptr %p1, align 8
  %p2 = getelementptr i8, ptr %out, i64 16
  store i64 %check64, ptr %p2, align 8
  %p3 = getelementptr i8, ptr %out, i64 24
  store i64 %clobber, ptr %p3, align 8
  %r0 = xor i64 %low, %high
  %r1 = xor i64 %r0, %check64
  %r2 = xor i64 %r1, %a
  %result = xor i64 %r2, %clobber
  ret i64 %result
}

define i64 @freeze_values_40_alias(i64 %a, i64 %b, i64 %salt, ptr %out) {
entry:
  %raw = trunc i64 %a to i40
  %stable = freeze i40 %raw
  %clobber = call i64 @frontier_views_clobber(i64 %salt)
  %low = zext i40 %stable to i64
  %high = add i64 0, 0
  %again = freeze i40 %stable
  %same2 = xor i40 %stable, %again
  %check = icmp ne i40 %same2, 0
  %check64 = zext i1 %check to i64
  store i64 %low, ptr %out, align 8
  %p1 = getelementptr i8, ptr %out, i64 8
  store i64 %high, ptr %p1, align 8
  %p2 = getelementptr i8, ptr %out, i64 16
  store i64 %check64, ptr %p2, align 8
  %p3 = getelementptr i8, ptr %out, i64 24
  store i64 %clobber, ptr %p3, align 8
  %r0 = xor i64 %low, %high
  %r1 = xor i64 %r0, %check64
  %r2 = xor i64 %r1, %a
  %result = xor i64 %r2, %clobber
  ret i64 %result
}

define i64 @freeze_values_48_alias(i64 %a, i64 %b, i64 %salt, ptr %out) {
entry:
  %raw = trunc i64 %a to i48
  %stable = freeze i48 %raw
  %clobber = call i64 @frontier_views_clobber(i64 %salt)
  %low = zext i48 %stable to i64
  %high = add i64 0, 0
  %again = freeze i48 %stable
  %same2 = xor i48 %stable, %again
  %check = icmp ne i48 %same2, 0
  %check64 = zext i1 %check to i64
  store i64 %low, ptr %out, align 8
  %p1 = getelementptr i8, ptr %out, i64 8
  store i64 %high, ptr %p1, align 8
  %p2 = getelementptr i8, ptr %out, i64 16
  store i64 %check64, ptr %p2, align 8
  %p3 = getelementptr i8, ptr %out, i64 24
  store i64 %clobber, ptr %p3, align 8
  %r0 = xor i64 %low, %high
  %r1 = xor i64 %r0, %check64
  %r2 = xor i64 %r1, %a
  %result = xor i64 %r2, %clobber
  ret i64 %result
}

define i64 @freeze_values_56_alias(i64 %a, i64 %b, i64 %salt, ptr %out) {
entry:
  %raw = trunc i64 %a to i56
  %stable = freeze i56 %raw
  %clobber = call i64 @frontier_views_clobber(i64 %salt)
  %low = zext i56 %stable to i64
  %high = add i64 0, 0
  %again = freeze i56 %stable
  %same2 = xor i56 %stable, %again
  %check = icmp ne i56 %same2, 0
  %check64 = zext i1 %check to i64
  store i64 %low, ptr %out, align 8
  %p1 = getelementptr i8, ptr %out, i64 8
  store i64 %high, ptr %p1, align 8
  %p2 = getelementptr i8, ptr %out, i64 16
  store i64 %check64, ptr %p2, align 8
  %p3 = getelementptr i8, ptr %out, i64 24
  store i64 %clobber, ptr %p3, align 8
  %r0 = xor i64 %low, %high
  %r1 = xor i64 %r0, %check64
  %r2 = xor i64 %r1, %a
  %result = xor i64 %r2, %clobber
  ret i64 %result
}

define i64 @freeze_values_63_alias(i64 %a, i64 %b, i64 %salt, ptr %out) {
entry:
  %raw = trunc i64 %a to i63
  %stable = freeze i63 %raw
  %clobber = call i64 @frontier_views_clobber(i64 %salt)
  %low = zext i63 %stable to i64
  %high = add i64 0, 0
  %again = freeze i63 %stable
  %same2 = xor i63 %stable, %again
  %check = icmp ne i63 %same2, 0
  %check64 = zext i1 %check to i64
  store i64 %low, ptr %out, align 8
  %p1 = getelementptr i8, ptr %out, i64 8
  store i64 %high, ptr %p1, align 8
  %p2 = getelementptr i8, ptr %out, i64 16
  store i64 %check64, ptr %p2, align 8
  %p3 = getelementptr i8, ptr %out, i64 24
  store i64 %clobber, ptr %p3, align 8
  %r0 = xor i64 %low, %high
  %r1 = xor i64 %r0, %check64
  %r2 = xor i64 %r1, %a
  %result = xor i64 %r2, %clobber
  ret i64 %result
}

define i64 @freeze_values_65_bits(i64 %a, i64 %b, i64 %salt, ptr %out) {
entry:
  %al = zext i64 %a to i128
  %bh = zext i64 %b to i128
  %shift = shl i128 %bh, 64
  %bits = or i128 %al, %shift
  %raw = trunc i128 %bits to i65
  %stable = freeze i65 %raw
  %clobber = call i64 @frontier_views_clobber(i64 %salt)
  %full = zext i65 %stable to i128
  %low = trunc i128 %full to i64
  %upper = lshr i128 %full, 64
  %high = trunc i128 %upper to i64
  %again = freeze i65 %stable
  %same2 = xor i65 %stable, %again
  %check = icmp ne i65 %same2, 0
  %check64 = zext i1 %check to i64
  store i64 %low, ptr %out, align 8
  %p1 = getelementptr i8, ptr %out, i64 8
  store i64 %high, ptr %p1, align 8
  %p2 = getelementptr i8, ptr %out, i64 16
  store i64 %check64, ptr %p2, align 8
  %p3 = getelementptr i8, ptr %out, i64 24
  store i64 %clobber, ptr %p3, align 8
  %r0 = xor i64 %low, %high
  %r1 = xor i64 %r0, %check64
  %r2 = xor i64 %r1, %a
  %result = xor i64 %r2, %clobber
  ret i64 %result
}

define i64 @freeze_values_65_signed(i64 %a, i64 %b, i64 %salt, ptr %out) {
entry:
  %raw = sext i64 %a to i65
  %stable = freeze i65 %raw
  %clobber = call i64 @frontier_views_clobber(i64 %salt)
  %full = zext i65 %stable to i128
  %low = trunc i128 %full to i64
  %upper = lshr i128 %full, 64
  %high = trunc i128 %upper to i64
  %again = freeze i65 %stable
  %same2 = xor i65 %stable, %again
  %check = icmp ne i65 %same2, 0
  %check64 = zext i1 %check to i64
  store i64 %low, ptr %out, align 8
  %p1 = getelementptr i8, ptr %out, i64 8
  store i64 %high, ptr %p1, align 8
  %p2 = getelementptr i8, ptr %out, i64 16
  store i64 %check64, ptr %p2, align 8
  %p3 = getelementptr i8, ptr %out, i64 24
  store i64 %clobber, ptr %p3, align 8
  %r0 = xor i64 %low, %high
  %r1 = xor i64 %r0, %check64
  %r2 = xor i64 %r1, %a
  %result = xor i64 %r2, %clobber
  ret i64 %result
}

define i64 @freeze_values_65_poison(i64 %a, i64 %b, i64 %salt, ptr %out) {
entry:
  %stable = freeze i65 poison
  %clobber = call i64 @frontier_views_clobber(i64 %salt)
  %same = xor i65 %stable, %stable
  %low = trunc i65 %same to i64
  %high = add i64 0, 0
  %again = freeze i65 %stable
  %same2 = xor i65 %stable, %again
  %check = icmp ne i65 %same2, 0
  %check64 = zext i1 %check to i64
  store i64 %low, ptr %out, align 8
  %p1 = getelementptr i8, ptr %out, i64 8
  store i64 %high, ptr %p1, align 8
  %p2 = getelementptr i8, ptr %out, i64 16
  store i64 %check64, ptr %p2, align 8
  %p3 = getelementptr i8, ptr %out, i64 24
  store i64 %clobber, ptr %p3, align 8
  %r0 = xor i64 %low, %high
  %r1 = xor i64 %r0, %check64
  %r2 = xor i64 %r1, %a
  %result = xor i64 %r2, %clobber
  ret i64 %result
}

define i64 @freeze_values_65_constant(i64 %a, i64 %b, i64 %salt, ptr %out) {
entry:
  %stable = freeze i65 -1
  %clobber = call i64 @frontier_views_clobber(i64 %salt)
  %full = zext i65 %stable to i128
  %low = trunc i128 %full to i64
  %upper = lshr i128 %full, 64
  %high = trunc i128 %upper to i64
  %again = freeze i65 %stable
  %same2 = xor i65 %stable, %again
  %check = icmp ne i65 %same2, 0
  %check64 = zext i1 %check to i64
  store i64 %low, ptr %out, align 8
  %p1 = getelementptr i8, ptr %out, i64 8
  store i64 %high, ptr %p1, align 8
  %p2 = getelementptr i8, ptr %out, i64 16
  store i64 %check64, ptr %p2, align 8
  %p3 = getelementptr i8, ptr %out, i64 24
  store i64 %clobber, ptr %p3, align 8
  %r0 = xor i64 %low, %high
  %r1 = xor i64 %r0, %check64
  %r2 = xor i64 %r1, %a
  %result = xor i64 %r2, %clobber
  ret i64 %result
}

define i64 @freeze_values_96_bits(i64 %a, i64 %b, i64 %salt, ptr %out) {
entry:
  %al = zext i64 %a to i128
  %bh = zext i64 %b to i128
  %shift = shl i128 %bh, 64
  %bits = or i128 %al, %shift
  %raw = trunc i128 %bits to i96
  %stable = freeze i96 %raw
  %clobber = call i64 @frontier_views_clobber(i64 %salt)
  %full = zext i96 %stable to i128
  %low = trunc i128 %full to i64
  %upper = lshr i128 %full, 64
  %high = trunc i128 %upper to i64
  %again = freeze i96 %stable
  %same2 = xor i96 %stable, %again
  %check = icmp ne i96 %same2, 0
  %check64 = zext i1 %check to i64
  store i64 %low, ptr %out, align 8
  %p1 = getelementptr i8, ptr %out, i64 8
  store i64 %high, ptr %p1, align 8
  %p2 = getelementptr i8, ptr %out, i64 16
  store i64 %check64, ptr %p2, align 8
  %p3 = getelementptr i8, ptr %out, i64 24
  store i64 %clobber, ptr %p3, align 8
  %r0 = xor i64 %low, %high
  %r1 = xor i64 %r0, %check64
  %r2 = xor i64 %r1, %a
  %result = xor i64 %r2, %clobber
  ret i64 %result
}

define i64 @freeze_values_96_signed(i64 %a, i64 %b, i64 %salt, ptr %out) {
entry:
  %raw = sext i64 %a to i96
  %stable = freeze i96 %raw
  %clobber = call i64 @frontier_views_clobber(i64 %salt)
  %full = zext i96 %stable to i128
  %low = trunc i128 %full to i64
  %upper = lshr i128 %full, 64
  %high = trunc i128 %upper to i64
  %again = freeze i96 %stable
  %same2 = xor i96 %stable, %again
  %check = icmp ne i96 %same2, 0
  %check64 = zext i1 %check to i64
  store i64 %low, ptr %out, align 8
  %p1 = getelementptr i8, ptr %out, i64 8
  store i64 %high, ptr %p1, align 8
  %p2 = getelementptr i8, ptr %out, i64 16
  store i64 %check64, ptr %p2, align 8
  %p3 = getelementptr i8, ptr %out, i64 24
  store i64 %clobber, ptr %p3, align 8
  %r0 = xor i64 %low, %high
  %r1 = xor i64 %r0, %check64
  %r2 = xor i64 %r1, %a
  %result = xor i64 %r2, %clobber
  ret i64 %result
}

define i64 @freeze_values_96_poison(i64 %a, i64 %b, i64 %salt, ptr %out) {
entry:
  %stable = freeze i96 poison
  %clobber = call i64 @frontier_views_clobber(i64 %salt)
  %same = xor i96 %stable, %stable
  %low = trunc i96 %same to i64
  %high = add i64 0, 0
  %again = freeze i96 %stable
  %same2 = xor i96 %stable, %again
  %check = icmp ne i96 %same2, 0
  %check64 = zext i1 %check to i64
  store i64 %low, ptr %out, align 8
  %p1 = getelementptr i8, ptr %out, i64 8
  store i64 %high, ptr %p1, align 8
  %p2 = getelementptr i8, ptr %out, i64 16
  store i64 %check64, ptr %p2, align 8
  %p3 = getelementptr i8, ptr %out, i64 24
  store i64 %clobber, ptr %p3, align 8
  %r0 = xor i64 %low, %high
  %r1 = xor i64 %r0, %check64
  %r2 = xor i64 %r1, %a
  %result = xor i64 %r2, %clobber
  ret i64 %result
}

define i64 @freeze_values_96_constant(i64 %a, i64 %b, i64 %salt, ptr %out) {
entry:
  %stable = freeze i96 -1
  %clobber = call i64 @frontier_views_clobber(i64 %salt)
  %full = zext i96 %stable to i128
  %low = trunc i128 %full to i64
  %upper = lshr i128 %full, 64
  %high = trunc i128 %upper to i64
  %again = freeze i96 %stable
  %same2 = xor i96 %stable, %again
  %check = icmp ne i96 %same2, 0
  %check64 = zext i1 %check to i64
  store i64 %low, ptr %out, align 8
  %p1 = getelementptr i8, ptr %out, i64 8
  store i64 %high, ptr %p1, align 8
  %p2 = getelementptr i8, ptr %out, i64 16
  store i64 %check64, ptr %p2, align 8
  %p3 = getelementptr i8, ptr %out, i64 24
  store i64 %clobber, ptr %p3, align 8
  %r0 = xor i64 %low, %high
  %r1 = xor i64 %r0, %check64
  %r2 = xor i64 %r1, %a
  %result = xor i64 %r2, %clobber
  ret i64 %result
}
