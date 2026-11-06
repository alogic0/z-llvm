target triple = "x86_64-unknown-linux-gnu"
declare i64 @checked_pair_clobber(i64)
declare { i128, i1 } @llvm.uadd.with.overflow.i128(i128, i128)
declare { i128, i1 } @llvm.usub.with.overflow.i128(i128, i128)
declare { i128, i1 } @llvm.sadd.with.overflow.i128(i128, i128)
declare { i128, i1 } @llvm.ssub.with.overflow.i128(i128, i128)
declare { i128, i1 } @llvm.smul.with.overflow.i128(i128, i128)
declare { i128, i1 } @llvm.umul.with.overflow.i128(i128, i128)

define i64 @checked_pair_uadd(i128 %a, i128 %b, ptr %out) {
entry:
 %checked = call { i128, i1 } @llvm.uadd.with.overflow.i128(i128 %a, i128 %b)
 %value = extractvalue { i128, i1 } %checked, 0
 %overflow = extractvalue { i128, i1 } %checked, 1
 %low = trunc i128 %value to i64
 %shift = lshr i128 %value, 64
 %high = trunc i128 %shift to i64
 %flag = zext i1 %overflow to i64
 %noise = call i64 @checked_pair_clobber(i64 %low)
 store i128 %value, ptr %out, align 8
 %flagptr = getelementptr i8, ptr %out, i64 16
 store i64 %flag, ptr %flagptr, align 8
 %fold = xor i64 %low, %high
 %result = xor i64 %fold, %noise
 ret i64 %result
}

define i64 @checked_pair_usub(i128 %a, i128 %b, ptr %out) {
entry:
 %checked = call { i128, i1 } @llvm.usub.with.overflow.i128(i128 %a, i128 %b)
 %value = extractvalue { i128, i1 } %checked, 0
 %overflow = extractvalue { i128, i1 } %checked, 1
 %low = trunc i128 %value to i64
 %shift = lshr i128 %value, 64
 %high = trunc i128 %shift to i64
 %flag = zext i1 %overflow to i64
 %noise = call i64 @checked_pair_clobber(i64 %low)
 store i128 %value, ptr %out, align 8
 %flagptr = getelementptr i8, ptr %out, i64 16
 store i64 %flag, ptr %flagptr, align 8
 %fold = xor i64 %low, %high
 %result = xor i64 %fold, %noise
 ret i64 %result
}

define i64 @checked_pair_sadd(i128 %a, i128 %b, ptr %out) {
entry:
 %checked = call { i128, i1 } @llvm.sadd.with.overflow.i128(i128 %a, i128 %b)
 %value = extractvalue { i128, i1 } %checked, 0
 %overflow = extractvalue { i128, i1 } %checked, 1
 %low = trunc i128 %value to i64
 %shift = lshr i128 %value, 64
 %high = trunc i128 %shift to i64
 %flag = zext i1 %overflow to i64
 %noise = call i64 @checked_pair_clobber(i64 %low)
 store i128 %value, ptr %out, align 8
 %flagptr = getelementptr i8, ptr %out, i64 16
 store i64 %flag, ptr %flagptr, align 8
 %fold = xor i64 %low, %high
 %result = xor i64 %fold, %noise
 ret i64 %result
}

define i64 @checked_pair_ssub(i128 %a, i128 %b, ptr %out) {
entry:
 %checked = call { i128, i1 } @llvm.ssub.with.overflow.i128(i128 %a, i128 %b)
 %value = extractvalue { i128, i1 } %checked, 0
 %overflow = extractvalue { i128, i1 } %checked, 1
 %low = trunc i128 %value to i64
 %shift = lshr i128 %value, 64
 %high = trunc i128 %shift to i64
 %flag = zext i1 %overflow to i64
 %noise = call i64 @checked_pair_clobber(i64 %low)
 store i128 %value, ptr %out, align 8
 %flagptr = getelementptr i8, ptr %out, i64 16
 store i64 %flag, ptr %flagptr, align 8
 %fold = xor i64 %low, %high
 %result = xor i64 %fold, %noise
 ret i64 %result
}

define i64 @checked_pair_smul3(i128 %a, i128 %b, ptr %out) {
entry:
 %checked = call { i128, i1 } @llvm.smul.with.overflow.i128(i128 %a, i128 3)
 %value = extractvalue { i128, i1 } %checked, 0
 %overflow = extractvalue { i128, i1 } %checked, 1
 %low = trunc i128 %value to i64
 %shift = lshr i128 %value, 64
 %high = trunc i128 %shift to i64
 %flag = zext i1 %overflow to i64
 %noise = call i64 @checked_pair_clobber(i64 %low)
 store i128 %value, ptr %out, align 8
 %flagptr = getelementptr i8, ptr %out, i64 16
 store i64 %flag, ptr %flagptr, align 8
 %fold = xor i64 %low, %high
 %result = xor i64 %fold, %noise
 ret i64 %result
}

define i64 @checked_pair_umul3(i128 %a, i128 %b, ptr %out) {
entry:
 %checked = call { i128, i1 } @llvm.umul.with.overflow.i128(i128 %a, i128 3)
 %value = extractvalue { i128, i1 } %checked, 0
 %overflow = extractvalue { i128, i1 } %checked, 1
 %low = trunc i128 %value to i64
 %shift = lshr i128 %value, 64
 %high = trunc i128 %shift to i64
 %flag = zext i1 %overflow to i64
 %noise = call i64 @checked_pair_clobber(i64 %low)
 store i128 %value, ptr %out, align 8
 %flagptr = getelementptr i8, ptr %out, i64 16
 store i64 %flag, ptr %flagptr, align 8
 %fold = xor i64 %low, %high
 %result = xor i64 %fold, %noise
 ret i64 %result
}

define i64 @checked_pair_smul_billion(i128 %a, i128 %b, ptr %out) {
entry:
 %checked = call { i128, i1 } @llvm.smul.with.overflow.i128(i128 %a, i128 1000000000)
 %value = extractvalue { i128, i1 } %checked, 0
 %overflow = extractvalue { i128, i1 } %checked, 1
 %low = trunc i128 %value to i64
 %shift = lshr i128 %value, 64
 %high = trunc i128 %shift to i64
 %flag = zext i1 %overflow to i64
 %noise = call i64 @checked_pair_clobber(i64 %low)
 store i128 %value, ptr %out, align 8
 %flagptr = getelementptr i8, ptr %out, i64 16
 store i64 %flag, ptr %flagptr, align 8
 %fold = xor i64 %low, %high
 %result = xor i64 %fold, %noise
 ret i64 %result
}

define i64 @checked_pair_umul_billion(i128 %a, i128 %b, ptr %out) {
entry:
 %checked = call { i128, i1 } @llvm.umul.with.overflow.i128(i128 %a, i128 1000000000)
 %value = extractvalue { i128, i1 } %checked, 0
 %overflow = extractvalue { i128, i1 } %checked, 1
 %low = trunc i128 %value to i64
 %shift = lshr i128 %value, 64
 %high = trunc i128 %shift to i64
 %flag = zext i1 %overflow to i64
 %noise = call i64 @checked_pair_clobber(i64 %low)
 store i128 %value, ptr %out, align 8
 %flagptr = getelementptr i8, ptr %out, i64 16
 store i64 %flag, ptr %flagptr, align 8
 %fold = xor i64 %low, %high
 %result = xor i64 %fold, %noise
 ret i64 %result
}
