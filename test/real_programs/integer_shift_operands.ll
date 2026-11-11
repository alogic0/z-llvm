target triple = "x86_64-unknown-linux-gnu"
declare i64 @shift_operand_clobber(i64)
declare void @llvm.lifetime.start.p0(ptr)
declare void @llvm.lifetime.end.p0(ptr)
declare void @llvm.assume(i1)
declare void @llvm.memcpy.p0.p0.i64(ptr, ptr, i64, i1)
declare i64 @llvm.fshl.i64(i64, i64, i64)

define i64 @shift_word_shl32_0(i64 %count, i64 %a, i64 %b, i64 %c, i64 %d, i64 %e, i64 %f, i64 %g) {
entry:
 %masked = and i64 %count, 31
 %narrow_count = trunc i64 %masked to i32
 
 %shifted = shl i32 -2147483648, %narrow_count
 %wide = zext i32 %shifted to i64
 %marker = xor i64 %a, %b
 %one = xor i64 %wide, %marker
 %two = add i64 %one, %c
 %three = xor i64 %two, %d
 %four = sub i64 %three, %e
 %five = xor i64 %four, %f
 %result = add i64 %five, %g
 ret i64 %result
}
define i64 @shift_word_shl32_1(i64 %count, i64 %a, i64 %b, i64 %c, i64 %d, i64 %e, i64 %f, i64 %g) {
entry:
 %masked = and i64 %count, 31
 %narrow_count = trunc i64 %masked to i32
 %marker = xor i64 %a, %b
 %shifted = shl i32 2147483648, %narrow_count
 %wide = zext i32 %shifted to i64
 
 %one = xor i64 %wide, %marker
 %two = add i64 %one, %c
 %three = xor i64 %two, %d
 %four = sub i64 %three, %e
 %five = xor i64 %four, %f
 %result = add i64 %five, %g
 ret i64 %result
}
define i64 @shift_word_shl32_2(i64 %count, i64 %a, i64 %b, i64 %c, i64 %d, i64 %e, i64 %f, i64 %g) {
entry:
 %masked = and i64 %count, 31
 %narrow_count = trunc i64 %masked to i32
 
 %shifted = shl i32 4294967295, %narrow_count
 %wide = zext i32 %shifted to i64
 %marker = xor i64 %a, %b
 %one = xor i64 %wide, %marker
 %two = add i64 %one, %c
 %three = xor i64 %two, %d
 %four = sub i64 %three, %e
 %five = xor i64 %four, %f
 %result = add i64 %five, %g
 ret i64 %result
}
define i64 @shift_word_shl32_3(i64 %count, i64 %a, i64 %b, i64 %c, i64 %d, i64 %e, i64 %f, i64 %g) {
entry:
 %masked = and i64 %count, 31
 %narrow_count = trunc i64 %masked to i32
 %marker = xor i64 %a, %b
 %shifted = shl i32 1985229328, %narrow_count
 %wide = zext i32 %shifted to i64
 
 %one = xor i64 %wide, %marker
 %two = add i64 %one, %c
 %three = xor i64 %two, %d
 %four = sub i64 %three, %e
 %five = xor i64 %four, %f
 %result = add i64 %five, %g
 ret i64 %result
}
define i64 @shift_word_lshr32_0(i64 %count, i64 %a, i64 %b, i64 %c, i64 %d, i64 %e, i64 %f, i64 %g) {
entry:
 %masked = and i64 %count, 31
 %narrow_count = trunc i64 %masked to i32
 
 %shifted = lshr exact i32 -2147483648, %narrow_count
 %wide = zext i32 %shifted to i64
 %marker = xor i64 %a, %b
 %one = xor i64 %wide, %marker
 %two = add i64 %one, %c
 %three = xor i64 %two, %d
 %four = sub i64 %three, %e
 %five = xor i64 %four, %f
 %result = add i64 %five, %g
 ret i64 %result
}
define i64 @shift_word_lshr32_1(i64 %count, i64 %a, i64 %b, i64 %c, i64 %d, i64 %e, i64 %f, i64 %g) {
entry:
 %masked = and i64 %count, 31
 %narrow_count = trunc i64 %masked to i32
 %marker = xor i64 %a, %b
 %shifted = lshr exact i32 2147483648, %narrow_count
 %wide = zext i32 %shifted to i64
 
 %one = xor i64 %wide, %marker
 %two = add i64 %one, %c
 %three = xor i64 %two, %d
 %four = sub i64 %three, %e
 %five = xor i64 %four, %f
 %result = add i64 %five, %g
 ret i64 %result
}
define i64 @shift_word_lshr32_2(i64 %count, i64 %a, i64 %b, i64 %c, i64 %d, i64 %e, i64 %f, i64 %g) {
entry:
 %masked = and i64 %count, 31
 %narrow_count = trunc i64 %masked to i32
 
 %shifted = lshr i32 4294967295, %narrow_count
 %wide = zext i32 %shifted to i64
 %marker = xor i64 %a, %b
 %one = xor i64 %wide, %marker
 %two = add i64 %one, %c
 %three = xor i64 %two, %d
 %four = sub i64 %three, %e
 %five = xor i64 %four, %f
 %result = add i64 %five, %g
 ret i64 %result
}
define i64 @shift_word_lshr32_3(i64 %count, i64 %a, i64 %b, i64 %c, i64 %d, i64 %e, i64 %f, i64 %g) {
entry:
 %masked = and i64 %count, 31
 %narrow_count = trunc i64 %masked to i32
 %marker = xor i64 %a, %b
 %shifted = lshr i32 1985229328, %narrow_count
 %wide = zext i32 %shifted to i64
 
 %one = xor i64 %wide, %marker
 %two = add i64 %one, %c
 %three = xor i64 %two, %d
 %four = sub i64 %three, %e
 %five = xor i64 %four, %f
 %result = add i64 %five, %g
 ret i64 %result
}
define i64 @shift_word_ashr32_0(i64 %count, i64 %a, i64 %b, i64 %c, i64 %d, i64 %e, i64 %f, i64 %g) {
entry:
 %masked = and i64 %count, 31
 %narrow_count = trunc i64 %masked to i32
 
 %shifted = ashr exact i32 -2147483648, %narrow_count
 %wide = zext i32 %shifted to i64
 %marker = xor i64 %a, %b
 %one = xor i64 %wide, %marker
 %two = add i64 %one, %c
 %three = xor i64 %two, %d
 %four = sub i64 %three, %e
 %five = xor i64 %four, %f
 %result = add i64 %five, %g
 ret i64 %result
}
define i64 @shift_word_ashr32_1(i64 %count, i64 %a, i64 %b, i64 %c, i64 %d, i64 %e, i64 %f, i64 %g) {
entry:
 %masked = and i64 %count, 31
 %narrow_count = trunc i64 %masked to i32
 %marker = xor i64 %a, %b
 %shifted = ashr exact i32 2147483648, %narrow_count
 %wide = zext i32 %shifted to i64
 
 %one = xor i64 %wide, %marker
 %two = add i64 %one, %c
 %three = xor i64 %two, %d
 %four = sub i64 %three, %e
 %five = xor i64 %four, %f
 %result = add i64 %five, %g
 ret i64 %result
}
define i64 @shift_word_ashr32_2(i64 %count, i64 %a, i64 %b, i64 %c, i64 %d, i64 %e, i64 %f, i64 %g) {
entry:
 %masked = and i64 %count, 31
 %narrow_count = trunc i64 %masked to i32
 
 %shifted = ashr i32 4294967295, %narrow_count
 %wide = zext i32 %shifted to i64
 %marker = xor i64 %a, %b
 %one = xor i64 %wide, %marker
 %two = add i64 %one, %c
 %three = xor i64 %two, %d
 %four = sub i64 %three, %e
 %five = xor i64 %four, %f
 %result = add i64 %five, %g
 ret i64 %result
}
define i64 @shift_word_ashr32_3(i64 %count, i64 %a, i64 %b, i64 %c, i64 %d, i64 %e, i64 %f, i64 %g) {
entry:
 %masked = and i64 %count, 31
 %narrow_count = trunc i64 %masked to i32
 %marker = xor i64 %a, %b
 %shifted = ashr i32 1985229328, %narrow_count
 %wide = zext i32 %shifted to i64
 
 %one = xor i64 %wide, %marker
 %two = add i64 %one, %c
 %three = xor i64 %two, %d
 %four = sub i64 %three, %e
 %five = xor i64 %four, %f
 %result = add i64 %five, %g
 ret i64 %result
}
define i64 @shift_word_shl64_0(i64 %count, i64 %a, i64 %b, i64 %c, i64 %d, i64 %e, i64 %f, i64 %g) {
entry:
 %masked = and i64 %count, 63
 
 
 %shifted = shl i64 -9223372036854775808, %masked
 %wide = xor i64 %shifted, 0
 %marker = xor i64 %a, %b
 %one = xor i64 %wide, %marker
 %two = add i64 %one, %c
 %three = xor i64 %two, %d
 %four = sub i64 %three, %e
 %five = xor i64 %four, %f
 %result = add i64 %five, %g
 ret i64 %result
}
define i64 @shift_word_shl64_1(i64 %count, i64 %a, i64 %b, i64 %c, i64 %d, i64 %e, i64 %f, i64 %g) {
entry:
 %masked = and i64 %count, 63
 
 %marker = xor i64 %a, %b
 %shifted = shl i64 9223372036854775808, %masked
 %wide = xor i64 %shifted, 0
 
 %one = xor i64 %wide, %marker
 %two = add i64 %one, %c
 %three = xor i64 %two, %d
 %four = sub i64 %three, %e
 %five = xor i64 %four, %f
 %result = add i64 %five, %g
 ret i64 %result
}
define i64 @shift_word_shl64_2(i64 %count, i64 %a, i64 %b, i64 %c, i64 %d, i64 %e, i64 %f, i64 %g) {
entry:
 %masked = and i64 %count, 63
 
 
 %shifted = shl i64 18446744073709551615, %masked
 %wide = xor i64 %shifted, 0
 %marker = xor i64 %a, %b
 %one = xor i64 %wide, %marker
 %two = add i64 %one, %c
 %three = xor i64 %two, %d
 %four = sub i64 %three, %e
 %five = xor i64 %four, %f
 %result = add i64 %five, %g
 ret i64 %result
}
define i64 @shift_word_shl64_3(i64 %count, i64 %a, i64 %b, i64 %c, i64 %d, i64 %e, i64 %f, i64 %g) {
entry:
 %masked = and i64 %count, 63
 
 %marker = xor i64 %a, %b
 %shifted = shl i64 18364758544493064720, %masked
 %wide = xor i64 %shifted, 0
 
 %one = xor i64 %wide, %marker
 %two = add i64 %one, %c
 %three = xor i64 %two, %d
 %four = sub i64 %three, %e
 %five = xor i64 %four, %f
 %result = add i64 %five, %g
 ret i64 %result
}
define i64 @shift_word_lshr64_0(i64 %count, i64 %a, i64 %b, i64 %c, i64 %d, i64 %e, i64 %f, i64 %g) {
entry:
 %masked = and i64 %count, 63
 
 
 %shifted = lshr exact i64 -9223372036854775808, %masked
 %wide = xor i64 %shifted, 0
 %marker = xor i64 %a, %b
 %one = xor i64 %wide, %marker
 %two = add i64 %one, %c
 %three = xor i64 %two, %d
 %four = sub i64 %three, %e
 %five = xor i64 %four, %f
 %result = add i64 %five, %g
 ret i64 %result
}
define i64 @shift_word_lshr64_1(i64 %count, i64 %a, i64 %b, i64 %c, i64 %d, i64 %e, i64 %f, i64 %g) {
entry:
 %masked = and i64 %count, 63
 
 %marker = xor i64 %a, %b
 %shifted = lshr exact i64 9223372036854775808, %masked
 %wide = xor i64 %shifted, 0
 
 %one = xor i64 %wide, %marker
 %two = add i64 %one, %c
 %three = xor i64 %two, %d
 %four = sub i64 %three, %e
 %five = xor i64 %four, %f
 %result = add i64 %five, %g
 ret i64 %result
}
define i64 @shift_word_lshr64_2(i64 %count, i64 %a, i64 %b, i64 %c, i64 %d, i64 %e, i64 %f, i64 %g) {
entry:
 %masked = and i64 %count, 63
 
 
 %shifted = lshr i64 18446744073709551615, %masked
 %wide = xor i64 %shifted, 0
 %marker = xor i64 %a, %b
 %one = xor i64 %wide, %marker
 %two = add i64 %one, %c
 %three = xor i64 %two, %d
 %four = sub i64 %three, %e
 %five = xor i64 %four, %f
 %result = add i64 %five, %g
 ret i64 %result
}
define i64 @shift_word_lshr64_3(i64 %count, i64 %a, i64 %b, i64 %c, i64 %d, i64 %e, i64 %f, i64 %g) {
entry:
 %masked = and i64 %count, 63
 
 %marker = xor i64 %a, %b
 %shifted = lshr i64 18364758544493064720, %masked
 %wide = xor i64 %shifted, 0
 
 %one = xor i64 %wide, %marker
 %two = add i64 %one, %c
 %three = xor i64 %two, %d
 %four = sub i64 %three, %e
 %five = xor i64 %four, %f
 %result = add i64 %five, %g
 ret i64 %result
}
define i64 @shift_word_ashr64_0(i64 %count, i64 %a, i64 %b, i64 %c, i64 %d, i64 %e, i64 %f, i64 %g) {
entry:
 %masked = and i64 %count, 63
 
 
 %shifted = ashr exact i64 -9223372036854775808, %masked
 %wide = xor i64 %shifted, 0
 %marker = xor i64 %a, %b
 %one = xor i64 %wide, %marker
 %two = add i64 %one, %c
 %three = xor i64 %two, %d
 %four = sub i64 %three, %e
 %five = xor i64 %four, %f
 %result = add i64 %five, %g
 ret i64 %result
}
define i64 @shift_word_ashr64_1(i64 %count, i64 %a, i64 %b, i64 %c, i64 %d, i64 %e, i64 %f, i64 %g) {
entry:
 %masked = and i64 %count, 63
 
 %marker = xor i64 %a, %b
 %shifted = ashr exact i64 9223372036854775808, %masked
 %wide = xor i64 %shifted, 0
 
 %one = xor i64 %wide, %marker
 %two = add i64 %one, %c
 %three = xor i64 %two, %d
 %four = sub i64 %three, %e
 %five = xor i64 %four, %f
 %result = add i64 %five, %g
 ret i64 %result
}
define i64 @shift_word_ashr64_2(i64 %count, i64 %a, i64 %b, i64 %c, i64 %d, i64 %e, i64 %f, i64 %g) {
entry:
 %masked = and i64 %count, 63
 
 
 %shifted = ashr i64 18446744073709551615, %masked
 %wide = xor i64 %shifted, 0
 %marker = xor i64 %a, %b
 %one = xor i64 %wide, %marker
 %two = add i64 %one, %c
 %three = xor i64 %two, %d
 %four = sub i64 %three, %e
 %five = xor i64 %four, %f
 %result = add i64 %five, %g
 ret i64 %result
}
define i64 @shift_word_ashr64_3(i64 %count, i64 %a, i64 %b, i64 %c, i64 %d, i64 %e, i64 %f, i64 %g) {
entry:
 %masked = and i64 %count, 63
 
 %marker = xor i64 %a, %b
 %shifted = ashr i64 18364758544493064720, %masked
 %wide = xor i64 %shifted, 0
 
 %one = xor i64 %wide, %marker
 %two = add i64 %one, %c
 %three = xor i64 %two, %d
 %four = sub i64 %three, %e
 %five = xor i64 %four, %f
 %result = add i64 %five, %g
 ret i64 %result
}
define i64 @shift_pair_0(ptr %output, i64 %lo, i64 %hi, i64 %count, i64 %seed) {
entry:
 %low_pair = zext i64 %lo to i128
 %high_pair = zext i64 %hi to i128
 %upper = shl i128 %high_pair, 64
 %pair = or i128 %low_pair, %upper
 %masked = and i64 %count, 127
 %wide_count = zext i64 %masked to i128
 %shifted = lshr i128 %pair, 0
 %clobbered = call i64 @shift_operand_clobber(i64 %seed)
 %low = trunc i128 %shifted to i64
 %projection = lshr i128 %shifted, 64
 %high = trunc i128 %projection to i64
 store i64 %low, ptr %output, align 1
 %p1 = getelementptr i8, ptr %output, i64 8
 store i64 %high, ptr %p1, align 1
 %both = xor i64 %lo, %hi
 %with_seed = add i64 %both, %seed
 %result = xor i64 %with_seed, %clobbered
 ret i64 %result
}
define i64 @shift_pair_1(ptr %output, i64 %lo, i64 %hi, i64 %count, i64 %seed) {
entry:
 %low_pair = zext i64 %lo to i128
 %high_pair = zext i64 %hi to i128
 %upper = shl i128 %high_pair, 64
 %pair = or i128 %low_pair, %upper
 %masked = and i64 %count, 127
 %wide_count = zext i64 %masked to i128
 %shifted = lshr i128 %pair, 1
 %clobbered = call i64 @shift_operand_clobber(i64 %seed)
 %low = trunc i128 %shifted to i64
 %projection = lshr i128 %shifted, 64
 %high = trunc i128 %projection to i64
 store i64 %low, ptr %output, align 1
 %p1 = getelementptr i8, ptr %output, i64 8
 store i64 %high, ptr %p1, align 1
 %both = xor i64 %lo, %hi
 %with_seed = add i64 %both, %seed
 %result = xor i64 %with_seed, %clobbered
 ret i64 %result
}
define i64 @shift_pair_7(ptr %output, i64 %lo, i64 %hi, i64 %count, i64 %seed) {
entry:
 %low_pair = zext i64 %lo to i128
 %high_pair = zext i64 %hi to i128
 %upper = shl i128 %high_pair, 64
 %pair = or i128 %low_pair, %upper
 %masked = and i64 %count, 127
 %wide_count = zext i64 %masked to i128
 %shifted = lshr i128 %pair, 7
 %clobbered = call i64 @shift_operand_clobber(i64 %seed)
 %low = trunc i128 %shifted to i64
 %projection = lshr i128 %shifted, 64
 %high = trunc i128 %projection to i64
 store i64 %low, ptr %output, align 1
 %p1 = getelementptr i8, ptr %output, i64 8
 store i64 %high, ptr %p1, align 1
 %both = xor i64 %lo, %hi
 %with_seed = add i64 %both, %seed
 %result = xor i64 %with_seed, %clobbered
 ret i64 %result
}
define i64 @shift_pair_31(ptr %output, i64 %lo, i64 %hi, i64 %count, i64 %seed) {
entry:
 %low_pair = zext i64 %lo to i128
 %high_pair = zext i64 %hi to i128
 %upper = shl i128 %high_pair, 64
 %pair = or i128 %low_pair, %upper
 %masked = and i64 %count, 127
 %wide_count = zext i64 %masked to i128
 %shifted = lshr i128 %pair, 31
 %clobbered = call i64 @shift_operand_clobber(i64 %seed)
 %low = trunc i128 %shifted to i64
 %projection = lshr i128 %shifted, 64
 %high = trunc i128 %projection to i64
 store i64 %low, ptr %output, align 1
 %p1 = getelementptr i8, ptr %output, i64 8
 store i64 %high, ptr %p1, align 1
 %both = xor i64 %lo, %hi
 %with_seed = add i64 %both, %seed
 %result = xor i64 %with_seed, %clobbered
 ret i64 %result
}
define i64 @shift_pair_32(ptr %output, i64 %lo, i64 %hi, i64 %count, i64 %seed) {
entry:
 %low_pair = zext i64 %lo to i128
 %high_pair = zext i64 %hi to i128
 %upper = shl i128 %high_pair, 64
 %pair = or i128 %low_pair, %upper
 %masked = and i64 %count, 127
 %wide_count = zext i64 %masked to i128
 %shifted = lshr i128 %pair, 32
 %clobbered = call i64 @shift_operand_clobber(i64 %seed)
 %low = trunc i128 %shifted to i64
 %projection = lshr i128 %shifted, 64
 %high = trunc i128 %projection to i64
 store i64 %low, ptr %output, align 1
 %p1 = getelementptr i8, ptr %output, i64 8
 store i64 %high, ptr %p1, align 1
 %both = xor i64 %lo, %hi
 %with_seed = add i64 %both, %seed
 %result = xor i64 %with_seed, %clobbered
 ret i64 %result
}
define i64 @shift_pair_40(ptr %output, i64 %lo, i64 %hi, i64 %count, i64 %seed) {
entry:
 %low_pair = zext i64 %lo to i128
 %high_pair = zext i64 %hi to i128
 %upper = shl i128 %high_pair, 64
 %pair = or i128 %low_pair, %upper
 %masked = and i64 %count, 127
 %wide_count = zext i64 %masked to i128
 %shifted = lshr i128 %pair, 40
 %clobbered = call i64 @shift_operand_clobber(i64 %seed)
 %low = trunc i128 %shifted to i64
 %projection = lshr i128 %shifted, 64
 %high = trunc i128 %projection to i64
 store i64 %low, ptr %output, align 1
 %p1 = getelementptr i8, ptr %output, i64 8
 store i64 %high, ptr %p1, align 1
 %both = xor i64 %lo, %hi
 %with_seed = add i64 %both, %seed
 %result = xor i64 %with_seed, %clobbered
 ret i64 %result
}
define i64 @shift_pair_63(ptr %output, i64 %lo, i64 %hi, i64 %count, i64 %seed) {
entry:
 %low_pair = zext i64 %lo to i128
 %high_pair = zext i64 %hi to i128
 %upper = shl i128 %high_pair, 64
 %pair = or i128 %low_pair, %upper
 %masked = and i64 %count, 127
 %wide_count = zext i64 %masked to i128
 %shifted = lshr i128 %pair, 63
 %clobbered = call i64 @shift_operand_clobber(i64 %seed)
 %low = trunc i128 %shifted to i64
 %projection = lshr i128 %shifted, 64
 %high = trunc i128 %projection to i64
 store i64 %low, ptr %output, align 1
 %p1 = getelementptr i8, ptr %output, i64 8
 store i64 %high, ptr %p1, align 1
 %both = xor i64 %lo, %hi
 %with_seed = add i64 %both, %seed
 %result = xor i64 %with_seed, %clobbered
 ret i64 %result
}
define i64 @shift_pair_64(ptr %output, i64 %lo, i64 %hi, i64 %count, i64 %seed) {
entry:
 %low_pair = zext i64 %lo to i128
 %high_pair = zext i64 %hi to i128
 %upper = shl i128 %high_pair, 64
 %pair = or i128 %low_pair, %upper
 %masked = and i64 %count, 127
 %wide_count = zext i64 %masked to i128
 %shifted = lshr i128 %pair, 64
 %clobbered = call i64 @shift_operand_clobber(i64 %seed)
 %low = trunc i128 %shifted to i64
 %projection = lshr i128 %shifted, 64
 %high = trunc i128 %projection to i64
 store i64 %low, ptr %output, align 1
 %p1 = getelementptr i8, ptr %output, i64 8
 store i64 %high, ptr %p1, align 1
 %both = xor i64 %lo, %hi
 %with_seed = add i64 %both, %seed
 %result = xor i64 %with_seed, %clobbered
 ret i64 %result
}
define i64 @shift_pair_65(ptr %output, i64 %lo, i64 %hi, i64 %count, i64 %seed) {
entry:
 %low_pair = zext i64 %lo to i128
 %high_pair = zext i64 %hi to i128
 %upper = shl i128 %high_pair, 64
 %pair = or i128 %low_pair, %upper
 %masked = and i64 %count, 127
 %wide_count = zext i64 %masked to i128
 %shifted = lshr i128 %pair, 65
 %clobbered = call i64 @shift_operand_clobber(i64 %seed)
 %low = trunc i128 %shifted to i64
 %projection = lshr i128 %shifted, 64
 %high = trunc i128 %projection to i64
 store i64 %low, ptr %output, align 1
 %p1 = getelementptr i8, ptr %output, i64 8
 store i64 %high, ptr %p1, align 1
 %both = xor i64 %lo, %hi
 %with_seed = add i64 %both, %seed
 %result = xor i64 %with_seed, %clobbered
 ret i64 %result
}
define i64 @shift_pair_127(ptr %output, i64 %lo, i64 %hi, i64 %count, i64 %seed) {
entry:
 %low_pair = zext i64 %lo to i128
 %high_pair = zext i64 %hi to i128
 %upper = shl i128 %high_pair, 64
 %pair = or i128 %low_pair, %upper
 %masked = and i64 %count, 127
 %wide_count = zext i64 %masked to i128
 %shifted = lshr i128 %pair, 127
 %clobbered = call i64 @shift_operand_clobber(i64 %seed)
 %low = trunc i128 %shifted to i64
 %projection = lshr i128 %shifted, 64
 %high = trunc i128 %projection to i64
 store i64 %low, ptr %output, align 1
 %p1 = getelementptr i8, ptr %output, i64 8
 store i64 %high, ptr %p1, align 1
 %both = xor i64 %lo, %hi
 %with_seed = add i64 %both, %seed
 %result = xor i64 %with_seed, %clobbered
 ret i64 %result
}
define i64 @shift_pair_named(ptr %output, i64 %lo, i64 %hi, i64 %count, i64 %seed) {
entry:
 %low_pair = zext i64 %lo to i128
 %high_pair = zext i64 %hi to i128
 %upper = shl i128 %high_pair, 64
 %pair = or i128 %low_pair, %upper
 %masked = and i64 %count, 127
 %wide_count = zext i64 %masked to i128
 %shifted = lshr i128 %pair, %wide_count
 %clobbered = call i64 @shift_operand_clobber(i64 %seed)
 %low = trunc i128 %shifted to i64
 %projection = lshr i128 %shifted, 64
 %high = trunc i128 %projection to i64
 store i64 %low, ptr %output, align 1
 %p1 = getelementptr i8, ptr %output, i64 8
 store i64 %high, ptr %p1, align 1
 %both = xor i64 %lo, %hi
 %with_seed = add i64 %both, %seed
 %result = xor i64 %with_seed, %clobbered
 ret i64 %result
}
define void @integer_shift_digest(ptr nonnull align 8 captures(none) %0, ptr nonnull writeonly align 1 captures(none) initializes((0, 16)) %1) {
  %.sroa.0.i = alloca i64, align 8
  %3 = getelementptr inbounds nuw i8, ptr %0, i64 48
  %4 = getelementptr inbounds nuw i8, ptr %0, i64 40
  %5 = load i64, ptr %4, align 8
  call void @llvm.lifetime.start.p0(ptr nonnull %.sroa.0.i)
  %6 = icmp ult i64 %5, 8
  tail call void @llvm.assume(i1 %6)
  %7 = getelementptr inbounds nuw i8, ptr %0, i64 32
  %8 = load i8, ptr %7, align 8
  %9 = trunc nuw nsw i64 %5 to i8
  %10 = add i8 %8, %9
  store i8 %10, ptr %7, align 8
  store i64 0, ptr %.sroa.0.i, align 8
  call void @llvm.memcpy.p0.p0.i64(ptr nonnull align 8 %.sroa.0.i, ptr nonnull readonly align 8 %3, i64 %5, i1 false)
  %.sroa.0.i.7.i.7.i.7..sroa_idx = getelementptr inbounds nuw i8, ptr %.sroa.0.i, i64 7
  store i8 %10, ptr %.sroa.0.i.7.i.7.i.7..sroa_idx, align 1
  %.sroa.0.i.0..sroa.0.i.0..sroa.0.i.0..sroa.0.0..sroa.0.0..sroa.0.0..i = load i64, ptr %.sroa.0.i, align 8
  %11 = getelementptr inbounds nuw i8, ptr %0, i64 24
  %12 = load i64, ptr %11, align 8
  %13 = xor i64 %12, %.sroa.0.i.0..sroa.0.i.0..sroa.0.i.0..sroa.0.0..sroa.0.0..sroa.0.0..i
  %14 = load i64, ptr %0, align 8
  %15 = getelementptr inbounds nuw i8, ptr %0, i64 8
  %16 = load i64, ptr %15, align 8
  %17 = add i64 %16, %14
  %18 = tail call i64 @llvm.fshl.i64(i64 %16, i64 %16, i64 13)
  %19 = xor i64 %18, %17
  %20 = tail call i64 @llvm.fshl.i64(i64 %17, i64 %17, i64 32)
  %21 = getelementptr inbounds nuw i8, ptr %0, i64 16
  %22 = load i64, ptr %21, align 8
  %23 = add i64 %22, %13
  %24 = tail call i64 @llvm.fshl.i64(i64 %13, i64 %13, i64 16)
  %25 = xor i64 %23, %24
  %26 = add i64 %25, %20
  %27 = tail call i64 @llvm.fshl.i64(i64 %25, i64 %25, i64 21)
  %28 = xor i64 %27, %26
  %29 = add i64 %23, %19
  %30 = tail call i64 @llvm.fshl.i64(i64 %19, i64 %19, i64 17)
  %31 = xor i64 %29, %30
  %32 = tail call i64 @llvm.fshl.i64(i64 %29, i64 %29, i64 32)
  %33 = xor i64 %26, %.sroa.0.i.0..sroa.0.i.0..sroa.0.i.0..sroa.0.0..sroa.0.0..sroa.0.0..i
  %34 = xor i64 %32, 238
  %35 = add i64 %33, %31
  %36 = tail call i64 @llvm.fshl.i64(i64 %31, i64 %31, i64 13)
  %37 = xor i64 %35, %36
  %38 = tail call i64 @llvm.fshl.i64(i64 %35, i64 %35, i64 32)
  %39 = add i64 %34, %28
  %40 = tail call i64 @llvm.fshl.i64(i64 %28, i64 %28, i64 16)
  %41 = xor i64 %40, %39
  %42 = add i64 %38, %41
  %43 = tail call i64 @llvm.fshl.i64(i64 %41, i64 %41, i64 21)
  %44 = xor i64 %43, %42
  %45 = add i64 %37, %39
  %46 = tail call i64 @llvm.fshl.i64(i64 %37, i64 %37, i64 17)
  %47 = xor i64 %46, %45
  %48 = tail call i64 @llvm.fshl.i64(i64 %45, i64 %45, i64 32)
  %49 = add i64 %47, %42
  %50 = tail call i64 @llvm.fshl.i64(i64 %47, i64 %47, i64 13)
  %51 = xor i64 %50, %49
  %52 = tail call i64 @llvm.fshl.i64(i64 %49, i64 %49, i64 32)
  %53 = add i64 %48, %44
  %54 = tail call i64 @llvm.fshl.i64(i64 %44, i64 %44, i64 16)
  %55 = xor i64 %54, %53
  %56 = add i64 %52, %55
  %57 = tail call i64 @llvm.fshl.i64(i64 %55, i64 %55, i64 21)
  %58 = xor i64 %57, %56
  %59 = add i64 %51, %53
  %60 = tail call i64 @llvm.fshl.i64(i64 %51, i64 %51, i64 17)
  %61 = xor i64 %60, %59
  %62 = tail call i64 @llvm.fshl.i64(i64 %59, i64 %59, i64 32)
  %63 = add i64 %61, %56
  %64 = tail call i64 @llvm.fshl.i64(i64 %61, i64 %61, i64 13)
  %65 = xor i64 %64, %63
  %66 = tail call i64 @llvm.fshl.i64(i64 %63, i64 %63, i64 32)
  %67 = add i64 %62, %58
  %68 = tail call i64 @llvm.fshl.i64(i64 %58, i64 %58, i64 16)
  %69 = xor i64 %68, %67
  %70 = add i64 %66, %69
  %71 = tail call i64 @llvm.fshl.i64(i64 %69, i64 %69, i64 21)
  %72 = xor i64 %71, %70
  %73 = add i64 %65, %67
  %74 = tail call i64 @llvm.fshl.i64(i64 %65, i64 %65, i64 17)
  %75 = xor i64 %74, %73
  %76 = tail call i64 @llvm.fshl.i64(i64 %73, i64 %73, i64 32)
  %77 = xor i64 %75, %71
  %78 = xor i64 %77, %76
  %79 = xor i64 %75, 221
  %80 = add i64 %79, %70
  %81 = tail call i64 @llvm.fshl.i64(i64 %79, i64 %79, i64 13)
  %82 = xor i64 %81, %80
  %83 = tail call i64 @llvm.fshl.i64(i64 %80, i64 %80, i64 32)
  %84 = add i64 %76, %72
  %85 = tail call i64 @llvm.fshl.i64(i64 %72, i64 %72, i64 16)
  %86 = xor i64 %85, %84
  %87 = add i64 %83, %86
  %88 = tail call i64 @llvm.fshl.i64(i64 %86, i64 %86, i64 21)
  %89 = xor i64 %87, %88
  %90 = add i64 %82, %84
  %91 = tail call i64 @llvm.fshl.i64(i64 %82, i64 %82, i64 17)
  %92 = xor i64 %91, %90
  %93 = tail call i64 @llvm.fshl.i64(i64 %90, i64 %90, i64 32)
  %94 = add i64 %92, %87
  %95 = tail call i64 @llvm.fshl.i64(i64 %92, i64 %92, i64 13)
  %96 = xor i64 %95, %94
  %97 = tail call i64 @llvm.fshl.i64(i64 %94, i64 %94, i64 32)
  %98 = add i64 %93, %89
  %99 = tail call i64 @llvm.fshl.i64(i64 %89, i64 %89, i64 16)
  %100 = xor i64 %99, %98
  %101 = add i64 %97, %100
  %102 = tail call i64 @llvm.fshl.i64(i64 %100, i64 %100, i64 21)
  %103 = xor i64 %102, %101
  %104 = add i64 %96, %98
  %105 = tail call i64 @llvm.fshl.i64(i64 %96, i64 %96, i64 17)
  %106 = xor i64 %105, %104
  %107 = tail call i64 @llvm.fshl.i64(i64 %104, i64 %104, i64 32)
  %108 = add i64 %106, %101
  %109 = tail call i64 @llvm.fshl.i64(i64 %106, i64 %106, i64 13)
  %110 = xor i64 %109, %108
  %111 = tail call i64 @llvm.fshl.i64(i64 %108, i64 %108, i64 32)
  %112 = add i64 %107, %103
  %113 = tail call i64 @llvm.fshl.i64(i64 %103, i64 %103, i64 16)
  %114 = xor i64 %113, %112
  %115 = add i64 %111, %114
  store i64 %115, ptr %0, align 8
  %116 = tail call i64 @llvm.fshl.i64(i64 %114, i64 %114, i64 21)
  %117 = xor i64 %116, %115
  store i64 %117, ptr %11, align 8
  %118 = add i64 %110, %112
  %119 = tail call i64 @llvm.fshl.i64(i64 %110, i64 %110, i64 17)
  %120 = xor i64 %119, %118
  store i64 %120, ptr %15, align 8
  %121 = tail call i64 @llvm.fshl.i64(i64 %118, i64 %118, i64 32)
  store i64 %121, ptr %21, align 8
  %122 = xor i64 %120, %116
  %123 = xor i64 %122, %121
  %124 = zext i64 %123 to i128
  %125 = zext i64 %78 to i128
  call void @llvm.lifetime.end.p0(ptr nonnull %.sroa.0.i)
  %126 = trunc i64 %78 to i8
  %127 = lshr i128 %125, 40
  %128 = trunc i128 %127 to i8
  %129 = lshr i128 %125, 48
  %130 = trunc i128 %129 to i8
  %131 = lshr i128 %125, 56
  %132 = trunc nuw i128 %131 to i8
  %133 = trunc i64 %123 to i8
  %134 = lshr i128 %124, 40
  %135 = trunc i128 %134 to i8
  %136 = lshr i128 %124, 48
  %137 = trunc i128 %136 to i8
  %138 = lshr i128 %124, 56
  %139 = trunc nuw i128 %138 to i8
  store i8 %126, ptr %1, align 1
  %.sroa.24.0..sroa_idx = getelementptr inbounds nuw i8, ptr %1, i64 1
  %140 = insertelement <4 x i128> poison, i128 %125, i64 0
  %141 = shufflevector <4 x i128> %140, <4 x i128> poison, <4 x i32> zeroinitializer
  %142 = lshr <4 x i128> %141, <i128 8, i128 16, i128 24, i128 32>
  %143 = trunc <4 x i128> %142 to <4 x i8>
  store <4 x i8> %143, ptr %.sroa.24.0..sroa_idx, align 1
  %.sroa.68.0..sroa_idx = getelementptr inbounds nuw i8, ptr %1, i64 5
  store i8 %128, ptr %.sroa.68.0..sroa_idx, align 1
  %.sroa.79.0..sroa_idx = getelementptr inbounds nuw i8, ptr %1, i64 6
  store i8 %130, ptr %.sroa.79.0..sroa_idx, align 1
  %.sroa.810.0..sroa_idx = getelementptr inbounds nuw i8, ptr %1, i64 7
  store i8 %132, ptr %.sroa.810.0..sroa_idx, align 1
  %.sroa.911.0..sroa_idx = getelementptr inbounds nuw i8, ptr %1, i64 8
  store i8 %133, ptr %.sroa.911.0..sroa_idx, align 1
  %.sroa.1012.0..sroa_idx = getelementptr inbounds nuw i8, ptr %1, i64 9
  %144 = insertelement <4 x i128> poison, i128 %124, i64 0
  %145 = shufflevector <4 x i128> %144, <4 x i128> poison, <4 x i32> zeroinitializer
  %146 = lshr <4 x i128> %145, <i128 8, i128 16, i128 24, i128 32>
  %147 = trunc <4 x i128> %146 to <4 x i8>
  store <4 x i8> %147, ptr %.sroa.1012.0..sroa_idx, align 1
  %.sroa.1416.0..sroa_idx = getelementptr inbounds nuw i8, ptr %1, i64 13
  store i8 %135, ptr %.sroa.1416.0..sroa_idx, align 1
  %.sroa.1517.0..sroa_idx = getelementptr inbounds nuw i8, ptr %1, i64 14
  store i8 %137, ptr %.sroa.1517.0..sroa_idx, align 1
  %.sroa.1618.0..sroa_idx = getelementptr inbounds nuw i8, ptr %1, i64 15
  store i8 %139, ptr %.sroa.1618.0..sroa_idx, align 1
  ret void
}
