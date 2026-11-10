target triple = "x86_64-unknown-linux-gnu"
declare void @llvm.memcpy.p0.p0.i64(ptr, ptr, i64, i1)
define i64 @eligibility_i8_false(ptr %external, i64 %value, i1 %choose, i64 %length, i64 %seed) {
entry:
 %slot = alloca i8, align 16
 %other = alloca [3 x i32], align 4
 %small = trunc i64 %value to i8
 store i8 %small, ptr %slot, align 1
 %copy_value = xor i64 %value, 72623859790382856
 %copy_low = trunc i64 %copy_value to i32
 %high = lshr i64 %value, 32
 %copy_high = trunc i64 %high to i32
 %copy_last = xor i32 %copy_low, 1516880852
 %other_high = getelementptr i8, ptr %other, i64 4
 %other_last = getelementptr i8, ptr %other, i64 8
 store i32 %copy_low, ptr %other, align 4
 store i32 %copy_high, ptr %other_high, align 4
 store i32 %copy_last, ptr %other_last, align 4
 call void @llvm.memcpy.p0.p0.i64(ptr %external, ptr %other, i64 %length, i1 false)
 %p = select i1 %choose, ptr %external, ptr %slot
 %selected = load i8, ptr %p, align 1
 %original = load i8, ptr %slot, align 1
 %selected_wide = zext i8 %selected to i64
 %original_wide = zext i8 %original to i64
 %shifted = shl i64 %original_wide, 17
 %both = xor i64 %selected_wide, %shifted
 %with_seed = xor i64 %both, %seed
 %result = xor i64 %with_seed, %value
 ret i64 %result
}
define i64 @eligibility_i8_true(ptr %external, i64 %value, i1 %choose, i64 %length, i64 %seed) {
entry:
 %slot = alloca i8, align 16
 %other = alloca [3 x i32], align 4
 %small = trunc i64 %value to i8
 store i8 %small, ptr %slot, align 1
 %copy_value = xor i64 %value, 72623859790382856
 %copy_low = trunc i64 %copy_value to i32
 %high = lshr i64 %value, 32
 %copy_high = trunc i64 %high to i32
 %copy_last = xor i32 %copy_low, 1516880852
 %other_high = getelementptr i8, ptr %other, i64 4
 %other_last = getelementptr i8, ptr %other, i64 8
 store i32 %copy_low, ptr %other, align 4
 store i32 %copy_high, ptr %other_high, align 4
 store i32 %copy_last, ptr %other_last, align 4
 call void @llvm.memcpy.p0.p0.i64(ptr %external, ptr %other, i64 %length, i1 false)
 %p = select i1 %choose, ptr %slot, ptr %external
 %selected = load i8, ptr %p, align 1
 %original = load i8, ptr %slot, align 1
 %selected_wide = zext i8 %selected to i64
 %original_wide = zext i8 %original to i64
 %shifted = shl i64 %original_wide, 17
 %both = xor i64 %selected_wide, %shifted
 %with_seed = xor i64 %both, %seed
 %result = xor i64 %with_seed, %value
 ret i64 %result
}
define i64 @eligibility_i16_false(ptr %external, i64 %value, i1 %choose, i64 %length, i64 %seed) {
entry:
 %slot = alloca i16, align 16
 %other = alloca [3 x i32], align 4
 %small = trunc i64 %value to i16
 store i16 %small, ptr %slot, align 1
 %copy_value = xor i64 %value, 72623859790382856
 %copy_low = trunc i64 %copy_value to i32
 %high = lshr i64 %value, 32
 %copy_high = trunc i64 %high to i32
 %copy_last = xor i32 %copy_low, 1516880852
 %other_high = getelementptr i8, ptr %other, i64 4
 %other_last = getelementptr i8, ptr %other, i64 8
 store i32 %copy_low, ptr %other, align 4
 store i32 %copy_high, ptr %other_high, align 4
 store i32 %copy_last, ptr %other_last, align 4
 call void @llvm.memcpy.p0.p0.i64(ptr %external, ptr %other, i64 %length, i1 false)
 %p = select i1 %choose, ptr %external, ptr %slot
 %selected = load i16, ptr %p, align 1
 %original = load i16, ptr %slot, align 1
 %selected_wide = zext i16 %selected to i64
 %original_wide = zext i16 %original to i64
 %shifted = shl i64 %original_wide, 17
 %both = xor i64 %selected_wide, %shifted
 %with_seed = xor i64 %both, %seed
 %result = xor i64 %with_seed, %value
 ret i64 %result
}
define i64 @eligibility_i16_true(ptr %external, i64 %value, i1 %choose, i64 %length, i64 %seed) {
entry:
 %slot = alloca i16, align 16
 %other = alloca [3 x i32], align 4
 %small = trunc i64 %value to i16
 store i16 %small, ptr %slot, align 1
 %copy_value = xor i64 %value, 72623859790382856
 %copy_low = trunc i64 %copy_value to i32
 %high = lshr i64 %value, 32
 %copy_high = trunc i64 %high to i32
 %copy_last = xor i32 %copy_low, 1516880852
 %other_high = getelementptr i8, ptr %other, i64 4
 %other_last = getelementptr i8, ptr %other, i64 8
 store i32 %copy_low, ptr %other, align 4
 store i32 %copy_high, ptr %other_high, align 4
 store i32 %copy_last, ptr %other_last, align 4
 call void @llvm.memcpy.p0.p0.i64(ptr %external, ptr %other, i64 %length, i1 false)
 %p = select i1 %choose, ptr %slot, ptr %external
 %selected = load i16, ptr %p, align 1
 %original = load i16, ptr %slot, align 1
 %selected_wide = zext i16 %selected to i64
 %original_wide = zext i16 %original to i64
 %shifted = shl i64 %original_wide, 17
 %both = xor i64 %selected_wide, %shifted
 %with_seed = xor i64 %both, %seed
 %result = xor i64 %with_seed, %value
 ret i64 %result
}
define i64 @eligibility_i32_false(ptr %external, i64 %value, i1 %choose, i64 %length, i64 %seed) {
entry:
 %slot = alloca i32, align 16
 %other = alloca [3 x i32], align 4
 %small = trunc i64 %value to i32
 store i32 %small, ptr %slot, align 1
 %copy_value = xor i64 %value, 72623859790382856
 %copy_low = trunc i64 %copy_value to i32
 %high = lshr i64 %value, 32
 %copy_high = trunc i64 %high to i32
 %copy_last = xor i32 %copy_low, 1516880852
 %other_high = getelementptr i8, ptr %other, i64 4
 %other_last = getelementptr i8, ptr %other, i64 8
 store i32 %copy_low, ptr %other, align 4
 store i32 %copy_high, ptr %other_high, align 4
 store i32 %copy_last, ptr %other_last, align 4
 call void @llvm.memcpy.p0.p0.i64(ptr %external, ptr %other, i64 %length, i1 false)
 %p = select i1 %choose, ptr %external, ptr %slot
 %selected = load i32, ptr %p, align 1
 %original = load i32, ptr %slot, align 1
 %selected_wide = zext i32 %selected to i64
 %original_wide = zext i32 %original to i64
 %shifted = shl i64 %original_wide, 17
 %both = xor i64 %selected_wide, %shifted
 %with_seed = xor i64 %both, %seed
 %result = xor i64 %with_seed, %value
 ret i64 %result
}
define i64 @eligibility_i32_true(ptr %external, i64 %value, i1 %choose, i64 %length, i64 %seed) {
entry:
 %slot = alloca i32, align 16
 %other = alloca [3 x i32], align 4
 %small = trunc i64 %value to i32
 store i32 %small, ptr %slot, align 1
 %copy_value = xor i64 %value, 72623859790382856
 %copy_low = trunc i64 %copy_value to i32
 %high = lshr i64 %value, 32
 %copy_high = trunc i64 %high to i32
 %copy_last = xor i32 %copy_low, 1516880852
 %other_high = getelementptr i8, ptr %other, i64 4
 %other_last = getelementptr i8, ptr %other, i64 8
 store i32 %copy_low, ptr %other, align 4
 store i32 %copy_high, ptr %other_high, align 4
 store i32 %copy_last, ptr %other_last, align 4
 call void @llvm.memcpy.p0.p0.i64(ptr %external, ptr %other, i64 %length, i1 false)
 %p = select i1 %choose, ptr %slot, ptr %external
 %selected = load i32, ptr %p, align 1
 %original = load i32, ptr %slot, align 1
 %selected_wide = zext i32 %selected to i64
 %original_wide = zext i32 %original to i64
 %shifted = shl i64 %original_wide, 17
 %both = xor i64 %selected_wide, %shifted
 %with_seed = xor i64 %both, %seed
 %result = xor i64 %with_seed, %value
 ret i64 %result
}
define i64 @eligibility_i64_false(ptr %external, i64 %value, i1 %choose, i64 %length, i64 %seed) {
entry:
 %slot = alloca i64, align 16
 %other = alloca [3 x i32], align 4
 %small = trunc i64 %value to i32
 store i32 %small, ptr %slot, align 1
 %copy_value = xor i64 %value, 72623859790382856
 %copy_low = trunc i64 %copy_value to i32
 %high = lshr i64 %value, 32
 %copy_high = trunc i64 %high to i32
 %copy_last = xor i32 %copy_low, 1516880852
 %other_high = getelementptr i8, ptr %other, i64 4
 %other_last = getelementptr i8, ptr %other, i64 8
 store i32 %copy_low, ptr %other, align 4
 store i32 %copy_high, ptr %other_high, align 4
 store i32 %copy_last, ptr %other_last, align 4
 call void @llvm.memcpy.p0.p0.i64(ptr %external, ptr %other, i64 %length, i1 false)
 %p = select i1 %choose, ptr %external, ptr %slot
 %selected = load i32, ptr %p, align 1
 %original = load i32, ptr %slot, align 1
 %selected_wide = zext i32 %selected to i64
 %original_wide = zext i32 %original to i64
 %shifted = shl i64 %original_wide, 17
 %both = xor i64 %selected_wide, %shifted
 %with_seed = xor i64 %both, %seed
 %result = xor i64 %with_seed, %value
 ret i64 %result
}
define i64 @eligibility_i64_true(ptr %external, i64 %value, i1 %choose, i64 %length, i64 %seed) {
entry:
 %slot = alloca i64, align 16
 %other = alloca [3 x i32], align 4
 %small = trunc i64 %value to i32
 store i32 %small, ptr %slot, align 1
 %copy_value = xor i64 %value, 72623859790382856
 %copy_low = trunc i64 %copy_value to i32
 %high = lshr i64 %value, 32
 %copy_high = trunc i64 %high to i32
 %copy_last = xor i32 %copy_low, 1516880852
 %other_high = getelementptr i8, ptr %other, i64 4
 %other_last = getelementptr i8, ptr %other, i64 8
 store i32 %copy_low, ptr %other, align 4
 store i32 %copy_high, ptr %other_high, align 4
 store i32 %copy_last, ptr %other_last, align 4
 call void @llvm.memcpy.p0.p0.i64(ptr %external, ptr %other, i64 %length, i1 false)
 %p = select i1 %choose, ptr %slot, ptr %external
 %selected = load i32, ptr %p, align 1
 %original = load i32, ptr %slot, align 1
 %selected_wide = zext i32 %selected to i64
 %original_wide = zext i32 %original to i64
 %shifted = shl i64 %original_wide, 17
 %both = xor i64 %selected_wide, %shifted
 %with_seed = xor i64 %both, %seed
 %result = xor i64 %with_seed, %value
 ret i64 %result
}
define i64 @eligibility_i128_false(ptr %external, i64 %value, i1 %choose, i64 %length, i64 %seed) {
entry:
 %slot = alloca i128, align 16
 %other = alloca [3 x i32], align 4
 %small = trunc i64 %value to i32
 store i32 %small, ptr %slot, align 1
 %copy_value = xor i64 %value, 72623859790382856
 %copy_low = trunc i64 %copy_value to i32
 %high = lshr i64 %value, 32
 %copy_high = trunc i64 %high to i32
 %copy_last = xor i32 %copy_low, 1516880852
 %other_high = getelementptr i8, ptr %other, i64 4
 %other_last = getelementptr i8, ptr %other, i64 8
 store i32 %copy_low, ptr %other, align 4
 store i32 %copy_high, ptr %other_high, align 4
 store i32 %copy_last, ptr %other_last, align 4
 call void @llvm.memcpy.p0.p0.i64(ptr %external, ptr %other, i64 %length, i1 false)
 %p = select i1 %choose, ptr %external, ptr %slot
 %selected = load i32, ptr %p, align 1
 %original = load i32, ptr %slot, align 1
 %selected_wide = zext i32 %selected to i64
 %original_wide = zext i32 %original to i64
 %shifted = shl i64 %original_wide, 17
 %both = xor i64 %selected_wide, %shifted
 %with_seed = xor i64 %both, %seed
 %result = xor i64 %with_seed, %value
 ret i64 %result
}
define i64 @eligibility_i128_true(ptr %external, i64 %value, i1 %choose, i64 %length, i64 %seed) {
entry:
 %slot = alloca i128, align 16
 %other = alloca [3 x i32], align 4
 %small = trunc i64 %value to i32
 store i32 %small, ptr %slot, align 1
 %copy_value = xor i64 %value, 72623859790382856
 %copy_low = trunc i64 %copy_value to i32
 %high = lshr i64 %value, 32
 %copy_high = trunc i64 %high to i32
 %copy_last = xor i32 %copy_low, 1516880852
 %other_high = getelementptr i8, ptr %other, i64 4
 %other_last = getelementptr i8, ptr %other, i64 8
 store i32 %copy_low, ptr %other, align 4
 store i32 %copy_high, ptr %other_high, align 4
 store i32 %copy_last, ptr %other_last, align 4
 call void @llvm.memcpy.p0.p0.i64(ptr %external, ptr %other, i64 %length, i1 false)
 %p = select i1 %choose, ptr %slot, ptr %external
 %selected = load i32, ptr %p, align 1
 %original = load i32, ptr %slot, align 1
 %selected_wide = zext i32 %selected to i64
 %original_wide = zext i32 %original to i64
 %shifted = shl i64 %original_wide, 17
 %both = xor i64 %selected_wide, %shifted
 %with_seed = xor i64 %both, %seed
 %result = xor i64 %with_seed, %value
 ret i64 %result
}
define i64 @eligibility_array16_false(ptr %external, i64 %value, i1 %choose, i64 %length, i64 %seed) {
entry:
 %slot = alloca [16 x i32], align 16
 %other = alloca [3 x i32], align 4
 %small = trunc i64 %value to i32
 store i32 %small, ptr %slot, align 1
 %copy_value = xor i64 %value, 72623859790382856
 %copy_low = trunc i64 %copy_value to i32
 %high = lshr i64 %value, 32
 %copy_high = trunc i64 %high to i32
 %copy_last = xor i32 %copy_low, 1516880852
 %other_high = getelementptr i8, ptr %other, i64 4
 %other_last = getelementptr i8, ptr %other, i64 8
 store i32 %copy_low, ptr %other, align 4
 store i32 %copy_high, ptr %other_high, align 4
 store i32 %copy_last, ptr %other_last, align 4
 call void @llvm.memcpy.p0.p0.i64(ptr %external, ptr %other, i64 %length, i1 false)
 %p = select i1 %choose, ptr %external, ptr %slot
 %selected = load i32, ptr %p, align 1
 %original = load i32, ptr %slot, align 1
 %selected_wide = zext i32 %selected to i64
 %original_wide = zext i32 %original to i64
 %shifted = shl i64 %original_wide, 17
 %both = xor i64 %selected_wide, %shifted
 %with_seed = xor i64 %both, %seed
 %result = xor i64 %with_seed, %value
 ret i64 %result
}
define i64 @eligibility_array16_true(ptr %external, i64 %value, i1 %choose, i64 %length, i64 %seed) {
entry:
 %slot = alloca [16 x i32], align 16
 %other = alloca [3 x i32], align 4
 %small = trunc i64 %value to i32
 store i32 %small, ptr %slot, align 1
 %copy_value = xor i64 %value, 72623859790382856
 %copy_low = trunc i64 %copy_value to i32
 %high = lshr i64 %value, 32
 %copy_high = trunc i64 %high to i32
 %copy_last = xor i32 %copy_low, 1516880852
 %other_high = getelementptr i8, ptr %other, i64 4
 %other_last = getelementptr i8, ptr %other, i64 8
 store i32 %copy_low, ptr %other, align 4
 store i32 %copy_high, ptr %other_high, align 4
 store i32 %copy_last, ptr %other_last, align 4
 call void @llvm.memcpy.p0.p0.i64(ptr %external, ptr %other, i64 %length, i1 false)
 %p = select i1 %choose, ptr %slot, ptr %external
 %selected = load i32, ptr %p, align 1
 %original = load i32, ptr %slot, align 1
 %selected_wide = zext i32 %selected to i64
 %original_wide = zext i32 %original to i64
 %shifted = shl i64 %original_wide, 17
 %both = xor i64 %selected_wide, %shifted
 %with_seed = xor i64 %both, %seed
 %result = xor i64 %with_seed, %value
 ret i64 %result
}
