target triple = "x86_64-unknown-linux-gnu"
declare i64 @checked_scalar_clobber(i64)
declare {i33, i1} @llvm.uadd.with.overflow.i33(i33, i33)
declare {i33, i1} @llvm.usub.with.overflow.i33(i33, i33)
declare {i33, i1} @llvm.umul.with.overflow.i33(i33, i33)
declare {i33, i1} @llvm.sadd.with.overflow.i33(i33, i33)
declare {i33, i1} @llvm.ssub.with.overflow.i33(i33, i33)
declare {i33, i1} @llvm.smul.with.overflow.i33(i33, i33)
declare {i39, i1} @llvm.uadd.with.overflow.i39(i39, i39)
declare {i39, i1} @llvm.usub.with.overflow.i39(i39, i39)
declare {i39, i1} @llvm.umul.with.overflow.i39(i39, i39)
declare {i39, i1} @llvm.sadd.with.overflow.i39(i39, i39)
declare {i39, i1} @llvm.ssub.with.overflow.i39(i39, i39)
declare {i39, i1} @llvm.smul.with.overflow.i39(i39, i39)
declare {i63, i1} @llvm.uadd.with.overflow.i63(i63, i63)
declare {i63, i1} @llvm.usub.with.overflow.i63(i63, i63)
declare {i63, i1} @llvm.umul.with.overflow.i63(i63, i63)
declare {i63, i1} @llvm.sadd.with.overflow.i63(i63, i63)
declare {i63, i1} @llvm.ssub.with.overflow.i63(i63, i63)
declare {i63, i1} @llvm.smul.with.overflow.i63(i63, i63)

define i64 @checked_scalar_33_uadd(i64 %a, i64 %b, ptr %out) {
entry:
 %x = trunc i64 %a to i33
 %y = trunc i64 %b to i33
 %pair = call {i33, i1} @llvm.uadd.with.overflow.i33(i33 %x, i33 %y)
 %value = extractvalue {i33, i1} %pair, 0
 %overflow = extractvalue {i33, i1} %pair, 1
 %wrapped = zext i33 %value to i64
 %flag = zext i1 %overflow to i64
 %call = call i64 @checked_scalar_clobber(i64 %wrapped)
 store i64 %wrapped, ptr %out, align 8
 %flag_out = getelementptr i8, ptr %out, i64 8
 store i64 %flag, ptr %flag_out, align 8
 %ret = xor i64 %call, %a
 %result = xor i64 %ret, %b
 ret i64 %result
}

define i64 @checked_scalar_33_usub(i64 %a, i64 %b, ptr %out) {
entry:
 %x = trunc i64 %a to i33
 %y = trunc i64 %b to i33
 %pair = call {i33, i1} @llvm.usub.with.overflow.i33(i33 %x, i33 %y)
 %value = extractvalue {i33, i1} %pair, 0
 %overflow = extractvalue {i33, i1} %pair, 1
 %wrapped = zext i33 %value to i64
 %flag = zext i1 %overflow to i64
 %call = call i64 @checked_scalar_clobber(i64 %wrapped)
 store i64 %wrapped, ptr %out, align 8
 %flag_out = getelementptr i8, ptr %out, i64 8
 store i64 %flag, ptr %flag_out, align 8
 %ret = xor i64 %call, %a
 %result = xor i64 %ret, %b
 ret i64 %result
}

define i64 @checked_scalar_33_umul(i64 %a, i64 %b, ptr %out) {
entry:
 %x = trunc i64 %a to i33
 %y = trunc i64 %b to i33
 %pair = call {i33, i1} @llvm.umul.with.overflow.i33(i33 %x, i33 %y)
 %value = extractvalue {i33, i1} %pair, 0
 %overflow = extractvalue {i33, i1} %pair, 1
 %wrapped = zext i33 %value to i64
 %flag = zext i1 %overflow to i64
 %call = call i64 @checked_scalar_clobber(i64 %wrapped)
 store i64 %wrapped, ptr %out, align 8
 %flag_out = getelementptr i8, ptr %out, i64 8
 store i64 %flag, ptr %flag_out, align 8
 %ret = xor i64 %call, %a
 %result = xor i64 %ret, %b
 ret i64 %result
}

define i64 @checked_scalar_33_sadd(i64 %a, i64 %b, ptr %out) {
entry:
 %x = trunc i64 %a to i33
 %y = trunc i64 %b to i33
 %pair = call {i33, i1} @llvm.sadd.with.overflow.i33(i33 %x, i33 %y)
 %value = extractvalue {i33, i1} %pair, 0
 %overflow = extractvalue {i33, i1} %pair, 1
 %wrapped = zext i33 %value to i64
 %flag = zext i1 %overflow to i64
 %call = call i64 @checked_scalar_clobber(i64 %wrapped)
 store i64 %wrapped, ptr %out, align 8
 %flag_out = getelementptr i8, ptr %out, i64 8
 store i64 %flag, ptr %flag_out, align 8
 %ret = xor i64 %call, %a
 %result = xor i64 %ret, %b
 ret i64 %result
}

define i64 @checked_scalar_33_ssub(i64 %a, i64 %b, ptr %out) {
entry:
 %x = trunc i64 %a to i33
 %y = trunc i64 %b to i33
 %pair = call {i33, i1} @llvm.ssub.with.overflow.i33(i33 %x, i33 %y)
 %value = extractvalue {i33, i1} %pair, 0
 %overflow = extractvalue {i33, i1} %pair, 1
 %wrapped = zext i33 %value to i64
 %flag = zext i1 %overflow to i64
 %call = call i64 @checked_scalar_clobber(i64 %wrapped)
 store i64 %wrapped, ptr %out, align 8
 %flag_out = getelementptr i8, ptr %out, i64 8
 store i64 %flag, ptr %flag_out, align 8
 %ret = xor i64 %call, %a
 %result = xor i64 %ret, %b
 ret i64 %result
}

define i64 @checked_scalar_33_smul(i64 %a, i64 %b, ptr %out) {
entry:
 %x = trunc i64 %a to i33
 %y = trunc i64 %b to i33
 %pair = call {i33, i1} @llvm.smul.with.overflow.i33(i33 %x, i33 %y)
 %value = extractvalue {i33, i1} %pair, 0
 %overflow = extractvalue {i33, i1} %pair, 1
 %wrapped = zext i33 %value to i64
 %flag = zext i1 %overflow to i64
 %call = call i64 @checked_scalar_clobber(i64 %wrapped)
 store i64 %wrapped, ptr %out, align 8
 %flag_out = getelementptr i8, ptr %out, i64 8
 store i64 %flag, ptr %flag_out, align 8
 %ret = xor i64 %call, %a
 %result = xor i64 %ret, %b
 ret i64 %result
}

define i64 @checked_scalar_39_uadd(i64 %a, i64 %b, ptr %out) {
entry:
 %x = trunc i64 %a to i39
 %y = trunc i64 %b to i39
 %pair = call {i39, i1} @llvm.uadd.with.overflow.i39(i39 %x, i39 %y)
 %value = extractvalue {i39, i1} %pair, 0
 %overflow = extractvalue {i39, i1} %pair, 1
 %wrapped = zext i39 %value to i64
 %flag = zext i1 %overflow to i64
 %call = call i64 @checked_scalar_clobber(i64 %wrapped)
 store i64 %wrapped, ptr %out, align 8
 %flag_out = getelementptr i8, ptr %out, i64 8
 store i64 %flag, ptr %flag_out, align 8
 %ret = xor i64 %call, %a
 %result = xor i64 %ret, %b
 ret i64 %result
}

define i64 @checked_scalar_39_usub(i64 %a, i64 %b, ptr %out) {
entry:
 %x = trunc i64 %a to i39
 %y = trunc i64 %b to i39
 %pair = call {i39, i1} @llvm.usub.with.overflow.i39(i39 %x, i39 %y)
 %value = extractvalue {i39, i1} %pair, 0
 %overflow = extractvalue {i39, i1} %pair, 1
 %wrapped = zext i39 %value to i64
 %flag = zext i1 %overflow to i64
 %call = call i64 @checked_scalar_clobber(i64 %wrapped)
 store i64 %wrapped, ptr %out, align 8
 %flag_out = getelementptr i8, ptr %out, i64 8
 store i64 %flag, ptr %flag_out, align 8
 %ret = xor i64 %call, %a
 %result = xor i64 %ret, %b
 ret i64 %result
}

define i64 @checked_scalar_39_umul(i64 %a, i64 %b, ptr %out) {
entry:
 %x = trunc i64 %a to i39
 %y = trunc i64 %b to i39
 %pair = call {i39, i1} @llvm.umul.with.overflow.i39(i39 %x, i39 %y)
 %value = extractvalue {i39, i1} %pair, 0
 %overflow = extractvalue {i39, i1} %pair, 1
 %wrapped = zext i39 %value to i64
 %flag = zext i1 %overflow to i64
 %call = call i64 @checked_scalar_clobber(i64 %wrapped)
 store i64 %wrapped, ptr %out, align 8
 %flag_out = getelementptr i8, ptr %out, i64 8
 store i64 %flag, ptr %flag_out, align 8
 %ret = xor i64 %call, %a
 %result = xor i64 %ret, %b
 ret i64 %result
}

define i64 @checked_scalar_39_sadd(i64 %a, i64 %b, ptr %out) {
entry:
 %x = trunc i64 %a to i39
 %y = trunc i64 %b to i39
 %pair = call {i39, i1} @llvm.sadd.with.overflow.i39(i39 %x, i39 %y)
 %value = extractvalue {i39, i1} %pair, 0
 %overflow = extractvalue {i39, i1} %pair, 1
 %wrapped = zext i39 %value to i64
 %flag = zext i1 %overflow to i64
 %call = call i64 @checked_scalar_clobber(i64 %wrapped)
 store i64 %wrapped, ptr %out, align 8
 %flag_out = getelementptr i8, ptr %out, i64 8
 store i64 %flag, ptr %flag_out, align 8
 %ret = xor i64 %call, %a
 %result = xor i64 %ret, %b
 ret i64 %result
}

define i64 @checked_scalar_39_ssub(i64 %a, i64 %b, ptr %out) {
entry:
 %x = trunc i64 %a to i39
 %y = trunc i64 %b to i39
 %pair = call {i39, i1} @llvm.ssub.with.overflow.i39(i39 %x, i39 %y)
 %value = extractvalue {i39, i1} %pair, 0
 %overflow = extractvalue {i39, i1} %pair, 1
 %wrapped = zext i39 %value to i64
 %flag = zext i1 %overflow to i64
 %call = call i64 @checked_scalar_clobber(i64 %wrapped)
 store i64 %wrapped, ptr %out, align 8
 %flag_out = getelementptr i8, ptr %out, i64 8
 store i64 %flag, ptr %flag_out, align 8
 %ret = xor i64 %call, %a
 %result = xor i64 %ret, %b
 ret i64 %result
}

define i64 @checked_scalar_39_smul(i64 %a, i64 %b, ptr %out) {
entry:
 %x = trunc i64 %a to i39
 %y = trunc i64 %b to i39
 %pair = call {i39, i1} @llvm.smul.with.overflow.i39(i39 %x, i39 %y)
 %value = extractvalue {i39, i1} %pair, 0
 %overflow = extractvalue {i39, i1} %pair, 1
 %wrapped = zext i39 %value to i64
 %flag = zext i1 %overflow to i64
 %call = call i64 @checked_scalar_clobber(i64 %wrapped)
 store i64 %wrapped, ptr %out, align 8
 %flag_out = getelementptr i8, ptr %out, i64 8
 store i64 %flag, ptr %flag_out, align 8
 %ret = xor i64 %call, %a
 %result = xor i64 %ret, %b
 ret i64 %result
}

define i64 @checked_scalar_63_uadd(i64 %a, i64 %b, ptr %out) {
entry:
 %x = trunc i64 %a to i63
 %y = trunc i64 %b to i63
 %pair = call {i63, i1} @llvm.uadd.with.overflow.i63(i63 %x, i63 %y)
 %value = extractvalue {i63, i1} %pair, 0
 %overflow = extractvalue {i63, i1} %pair, 1
 %wrapped = zext i63 %value to i64
 %flag = zext i1 %overflow to i64
 %call = call i64 @checked_scalar_clobber(i64 %wrapped)
 store i64 %wrapped, ptr %out, align 8
 %flag_out = getelementptr i8, ptr %out, i64 8
 store i64 %flag, ptr %flag_out, align 8
 %ret = xor i64 %call, %a
 %result = xor i64 %ret, %b
 ret i64 %result
}

define i64 @checked_scalar_63_usub(i64 %a, i64 %b, ptr %out) {
entry:
 %x = trunc i64 %a to i63
 %y = trunc i64 %b to i63
 %pair = call {i63, i1} @llvm.usub.with.overflow.i63(i63 %x, i63 %y)
 %value = extractvalue {i63, i1} %pair, 0
 %overflow = extractvalue {i63, i1} %pair, 1
 %wrapped = zext i63 %value to i64
 %flag = zext i1 %overflow to i64
 %call = call i64 @checked_scalar_clobber(i64 %wrapped)
 store i64 %wrapped, ptr %out, align 8
 %flag_out = getelementptr i8, ptr %out, i64 8
 store i64 %flag, ptr %flag_out, align 8
 %ret = xor i64 %call, %a
 %result = xor i64 %ret, %b
 ret i64 %result
}

define i64 @checked_scalar_63_umul(i64 %a, i64 %b, ptr %out) {
entry:
 %x = trunc i64 %a to i63
 %y = trunc i64 %b to i63
 %pair = call {i63, i1} @llvm.umul.with.overflow.i63(i63 %x, i63 %y)
 %value = extractvalue {i63, i1} %pair, 0
 %overflow = extractvalue {i63, i1} %pair, 1
 %wrapped = zext i63 %value to i64
 %flag = zext i1 %overflow to i64
 %call = call i64 @checked_scalar_clobber(i64 %wrapped)
 store i64 %wrapped, ptr %out, align 8
 %flag_out = getelementptr i8, ptr %out, i64 8
 store i64 %flag, ptr %flag_out, align 8
 %ret = xor i64 %call, %a
 %result = xor i64 %ret, %b
 ret i64 %result
}

define i64 @checked_scalar_63_sadd(i64 %a, i64 %b, ptr %out) {
entry:
 %x = trunc i64 %a to i63
 %y = trunc i64 %b to i63
 %pair = call {i63, i1} @llvm.sadd.with.overflow.i63(i63 %x, i63 %y)
 %value = extractvalue {i63, i1} %pair, 0
 %overflow = extractvalue {i63, i1} %pair, 1
 %wrapped = zext i63 %value to i64
 %flag = zext i1 %overflow to i64
 %call = call i64 @checked_scalar_clobber(i64 %wrapped)
 store i64 %wrapped, ptr %out, align 8
 %flag_out = getelementptr i8, ptr %out, i64 8
 store i64 %flag, ptr %flag_out, align 8
 %ret = xor i64 %call, %a
 %result = xor i64 %ret, %b
 ret i64 %result
}

define i64 @checked_scalar_63_ssub(i64 %a, i64 %b, ptr %out) {
entry:
 %x = trunc i64 %a to i63
 %y = trunc i64 %b to i63
 %pair = call {i63, i1} @llvm.ssub.with.overflow.i63(i63 %x, i63 %y)
 %value = extractvalue {i63, i1} %pair, 0
 %overflow = extractvalue {i63, i1} %pair, 1
 %wrapped = zext i63 %value to i64
 %flag = zext i1 %overflow to i64
 %call = call i64 @checked_scalar_clobber(i64 %wrapped)
 store i64 %wrapped, ptr %out, align 8
 %flag_out = getelementptr i8, ptr %out, i64 8
 store i64 %flag, ptr %flag_out, align 8
 %ret = xor i64 %call, %a
 %result = xor i64 %ret, %b
 ret i64 %result
}

define i64 @checked_scalar_63_smul(i64 %a, i64 %b, ptr %out) {
entry:
 %x = trunc i64 %a to i63
 %y = trunc i64 %b to i63
 %pair = call {i63, i1} @llvm.smul.with.overflow.i63(i63 %x, i63 %y)
 %value = extractvalue {i63, i1} %pair, 0
 %overflow = extractvalue {i63, i1} %pair, 1
 %wrapped = zext i63 %value to i64
 %flag = zext i1 %overflow to i64
 %call = call i64 @checked_scalar_clobber(i64 %wrapped)
 store i64 %wrapped, ptr %out, align 8
 %flag_out = getelementptr i8, ptr %out, i64 8
 store i64 %flag, ptr %flag_out, align 8
 %ret = xor i64 %call, %a
 %result = xor i64 %ret, %b
 ret i64 %result
}
