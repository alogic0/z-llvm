target triple = "x86_64-unknown-linux-gnu"
declare i64 @llvm.ctpop.i64(i64)
declare i16 @llvm.ctlz.i16(i16,i1)
declare i16 @llvm.bswap.i16(i16)
declare i32 @llvm.bswap.i32(i32)
declare i64 @llvm.bswap.i64(i64)
declare i32 @llvm.bitreverse.i32(i32)
declare i64 @llvm.bitreverse.i64(i64)
declare i32 @llvm.fshl.i32(i32,i32,i32)
define i64 @intrinsic_preservation_count64_register(i64 %raw,ptr %source,ptr %out,i64 %salt) {
entry:
 %narrow = add i64 %raw,0
 %value = add i64 %narrow,0
 %alias = add i64 %value,0
 %result = call i64 @llvm.ctpop.i64(i64 %value)
 store i64 %value,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %alias,ptr %next,align 1
 %wide = add i64 %result,0
 %original = add i64 %value,0
 %mixed = xor i64 %wide,%original
 %answer = xor i64 %mixed,%salt
 ret i64 %answer
}
define i64 @intrinsic_preservation_count64_computed(i64 %raw,ptr %source,ptr %out,i64 %salt) {
entry:
 %narrow = add i64 %raw,0
 %value = xor i64 %narrow,23205
 %alias = add i64 %value,0
 %result = call i64 @llvm.ctpop.i64(i64 %value)
 store i64 %value,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %alias,ptr %next,align 1
 %wide = add i64 %result,0
 %original = add i64 %value,0
 %mixed = xor i64 %wide,%original
 %answer = xor i64 %mixed,%salt
 ret i64 %answer
}
define i64 @intrinsic_preservation_count64_load(i64 %raw,ptr %source,ptr %out,i64 %salt) {
entry:
 %value = load i64,ptr %source,align 1
 %alias = add i64 %value,0
 %result = call i64 @llvm.ctpop.i64(i64 %value)
 store i64 %value,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %alias,ptr %next,align 1
 %wide = add i64 %result,0
 %original = add i64 %value,0
 %mixed = xor i64 %wide,%original
 %answer = xor i64 %mixed,%salt
 ret i64 %answer
}
define i64 @intrinsic_preservation_leading16_register(i64 %raw,ptr %source,ptr %out,i64 %salt) {
entry:
 %narrow = trunc i64 %raw to i16
 %value = add i16 %narrow,0
 %alias = add i16 %value,0
 %result = call i16 @llvm.ctlz.i16(i16 %value,i1 false)
 store i16 %value,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i16 %alias,ptr %next,align 1
 %wide = zext i16 %result to i64
 %original = zext i16 %value to i64
 %mixed = xor i64 %wide,%original
 %answer = xor i64 %mixed,%salt
 ret i64 %answer
}
define i64 @intrinsic_preservation_leading16_computed(i64 %raw,ptr %source,ptr %out,i64 %salt) {
entry:
 %narrow = trunc i64 %raw to i16
 %value = xor i16 %narrow,23205
 %alias = add i16 %value,0
 %result = call i16 @llvm.ctlz.i16(i16 %value,i1 false)
 store i16 %value,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i16 %alias,ptr %next,align 1
 %wide = zext i16 %result to i64
 %original = zext i16 %value to i64
 %mixed = xor i64 %wide,%original
 %answer = xor i64 %mixed,%salt
 ret i64 %answer
}
define i64 @intrinsic_preservation_leading16_load(i64 %raw,ptr %source,ptr %out,i64 %salt) {
entry:
 %value = load i16,ptr %source,align 1
 %alias = add i16 %value,0
 %result = call i16 @llvm.ctlz.i16(i16 %value,i1 false)
 store i16 %value,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i16 %alias,ptr %next,align 1
 %wide = zext i16 %result to i64
 %original = zext i16 %value to i64
 %mixed = xor i64 %wide,%original
 %answer = xor i64 %mixed,%salt
 ret i64 %answer
}
define i64 @intrinsic_preservation_swap16_register(i64 %raw,ptr %source,ptr %out,i64 %salt) {
entry:
 %narrow = trunc i64 %raw to i16
 %value = add i16 %narrow,0
 %alias = add i16 %value,0
 %result = call i16 @llvm.bswap.i16(i16 %value)
 store i16 %value,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i16 %alias,ptr %next,align 1
 %wide = zext i16 %result to i64
 %original = zext i16 %value to i64
 %mixed = xor i64 %wide,%original
 %answer = xor i64 %mixed,%salt
 ret i64 %answer
}
define i64 @intrinsic_preservation_swap16_computed(i64 %raw,ptr %source,ptr %out,i64 %salt) {
entry:
 %narrow = trunc i64 %raw to i16
 %value = xor i16 %narrow,23205
 %alias = add i16 %value,0
 %result = call i16 @llvm.bswap.i16(i16 %value)
 store i16 %value,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i16 %alias,ptr %next,align 1
 %wide = zext i16 %result to i64
 %original = zext i16 %value to i64
 %mixed = xor i64 %wide,%original
 %answer = xor i64 %mixed,%salt
 ret i64 %answer
}
define i64 @intrinsic_preservation_swap16_load(i64 %raw,ptr %source,ptr %out,i64 %salt) {
entry:
 %value = load i16,ptr %source,align 1
 %alias = add i16 %value,0
 %result = call i16 @llvm.bswap.i16(i16 %value)
 store i16 %value,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i16 %alias,ptr %next,align 1
 %wide = zext i16 %result to i64
 %original = zext i16 %value to i64
 %mixed = xor i64 %wide,%original
 %answer = xor i64 %mixed,%salt
 ret i64 %answer
}
define i64 @intrinsic_preservation_swap32_register(i64 %raw,ptr %source,ptr %out,i64 %salt) {
entry:
 %narrow = trunc i64 %raw to i32
 %value = add i32 %narrow,0
 %alias = add i32 %value,0
 %result = call i32 @llvm.bswap.i32(i32 %value)
 store i32 %value,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i32 %alias,ptr %next,align 1
 %wide = zext i32 %result to i64
 %original = zext i32 %value to i64
 %mixed = xor i64 %wide,%original
 %answer = xor i64 %mixed,%salt
 ret i64 %answer
}
define i64 @intrinsic_preservation_swap32_computed(i64 %raw,ptr %source,ptr %out,i64 %salt) {
entry:
 %narrow = trunc i64 %raw to i32
 %value = xor i32 %narrow,23205
 %alias = add i32 %value,0
 %result = call i32 @llvm.bswap.i32(i32 %value)
 store i32 %value,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i32 %alias,ptr %next,align 1
 %wide = zext i32 %result to i64
 %original = zext i32 %value to i64
 %mixed = xor i64 %wide,%original
 %answer = xor i64 %mixed,%salt
 ret i64 %answer
}
define i64 @intrinsic_preservation_swap32_load(i64 %raw,ptr %source,ptr %out,i64 %salt) {
entry:
 %value = load i32,ptr %source,align 1
 %alias = add i32 %value,0
 %result = call i32 @llvm.bswap.i32(i32 %value)
 store i32 %value,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i32 %alias,ptr %next,align 1
 %wide = zext i32 %result to i64
 %original = zext i32 %value to i64
 %mixed = xor i64 %wide,%original
 %answer = xor i64 %mixed,%salt
 ret i64 %answer
}
define i64 @intrinsic_preservation_swap64_register(i64 %raw,ptr %source,ptr %out,i64 %salt) {
entry:
 %narrow = add i64 %raw,0
 %value = add i64 %narrow,0
 %alias = add i64 %value,0
 %result = call i64 @llvm.bswap.i64(i64 %value)
 store i64 %value,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %alias,ptr %next,align 1
 %wide = add i64 %result,0
 %original = add i64 %value,0
 %mixed = xor i64 %wide,%original
 %answer = xor i64 %mixed,%salt
 ret i64 %answer
}
define i64 @intrinsic_preservation_swap64_computed(i64 %raw,ptr %source,ptr %out,i64 %salt) {
entry:
 %narrow = add i64 %raw,0
 %value = xor i64 %narrow,23205
 %alias = add i64 %value,0
 %result = call i64 @llvm.bswap.i64(i64 %value)
 store i64 %value,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %alias,ptr %next,align 1
 %wide = add i64 %result,0
 %original = add i64 %value,0
 %mixed = xor i64 %wide,%original
 %answer = xor i64 %mixed,%salt
 ret i64 %answer
}
define i64 @intrinsic_preservation_swap64_load(i64 %raw,ptr %source,ptr %out,i64 %salt) {
entry:
 %value = load i64,ptr %source,align 1
 %alias = add i64 %value,0
 %result = call i64 @llvm.bswap.i64(i64 %value)
 store i64 %value,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %alias,ptr %next,align 1
 %wide = add i64 %result,0
 %original = add i64 %value,0
 %mixed = xor i64 %wide,%original
 %answer = xor i64 %mixed,%salt
 ret i64 %answer
}
define i64 @intrinsic_preservation_reverse32_register(i64 %raw,ptr %source,ptr %out,i64 %salt) {
entry:
 %narrow = trunc i64 %raw to i32
 %value = add i32 %narrow,0
 %alias = add i32 %value,0
 %result = call i32 @llvm.bitreverse.i32(i32 %value)
 store i32 %value,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i32 %alias,ptr %next,align 1
 %wide = zext i32 %result to i64
 %original = zext i32 %value to i64
 %mixed = xor i64 %wide,%original
 %answer = xor i64 %mixed,%salt
 ret i64 %answer
}
define i64 @intrinsic_preservation_reverse32_computed(i64 %raw,ptr %source,ptr %out,i64 %salt) {
entry:
 %narrow = trunc i64 %raw to i32
 %value = xor i32 %narrow,23205
 %alias = add i32 %value,0
 %result = call i32 @llvm.bitreverse.i32(i32 %value)
 store i32 %value,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i32 %alias,ptr %next,align 1
 %wide = zext i32 %result to i64
 %original = zext i32 %value to i64
 %mixed = xor i64 %wide,%original
 %answer = xor i64 %mixed,%salt
 ret i64 %answer
}
define i64 @intrinsic_preservation_reverse32_load(i64 %raw,ptr %source,ptr %out,i64 %salt) {
entry:
 %value = load i32,ptr %source,align 1
 %alias = add i32 %value,0
 %result = call i32 @llvm.bitreverse.i32(i32 %value)
 store i32 %value,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i32 %alias,ptr %next,align 1
 %wide = zext i32 %result to i64
 %original = zext i32 %value to i64
 %mixed = xor i64 %wide,%original
 %answer = xor i64 %mixed,%salt
 ret i64 %answer
}
define i64 @intrinsic_preservation_reverse64_register(i64 %raw,ptr %source,ptr %out,i64 %salt) {
entry:
 %narrow = add i64 %raw,0
 %value = add i64 %narrow,0
 %alias = add i64 %value,0
 %result = call i64 @llvm.bitreverse.i64(i64 %value)
 store i64 %value,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %alias,ptr %next,align 1
 %wide = add i64 %result,0
 %original = add i64 %value,0
 %mixed = xor i64 %wide,%original
 %answer = xor i64 %mixed,%salt
 ret i64 %answer
}
define i64 @intrinsic_preservation_reverse64_computed(i64 %raw,ptr %source,ptr %out,i64 %salt) {
entry:
 %narrow = add i64 %raw,0
 %value = xor i64 %narrow,23205
 %alias = add i64 %value,0
 %result = call i64 @llvm.bitreverse.i64(i64 %value)
 store i64 %value,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %alias,ptr %next,align 1
 %wide = add i64 %result,0
 %original = add i64 %value,0
 %mixed = xor i64 %wide,%original
 %answer = xor i64 %mixed,%salt
 ret i64 %answer
}
define i64 @intrinsic_preservation_reverse64_load(i64 %raw,ptr %source,ptr %out,i64 %salt) {
entry:
 %value = load i64,ptr %source,align 1
 %alias = add i64 %value,0
 %result = call i64 @llvm.bitreverse.i64(i64 %value)
 store i64 %value,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %alias,ptr %next,align 1
 %wide = add i64 %result,0
 %original = add i64 %value,0
 %mixed = xor i64 %wide,%original
 %answer = xor i64 %mixed,%salt
 ret i64 %answer
}
define i64 @intrinsic_preservation_funnel32_register(i64 %raw,ptr %source,ptr %out,i64 %salt) {
entry:
 %narrow = trunc i64 %raw to i32
 %value = add i32 %narrow,0
 %alias = add i32 %value,0
 %result = call i32 @llvm.fshl.i32(i32 %value,i32 %value,i32 7)
 store i32 %value,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i32 %alias,ptr %next,align 1
 %wide = zext i32 %result to i64
 %original = zext i32 %value to i64
 %mixed = xor i64 %wide,%original
 %answer = xor i64 %mixed,%salt
 ret i64 %answer
}
define i64 @intrinsic_preservation_funnel32_computed(i64 %raw,ptr %source,ptr %out,i64 %salt) {
entry:
 %narrow = trunc i64 %raw to i32
 %value = xor i32 %narrow,23205
 %alias = add i32 %value,0
 %result = call i32 @llvm.fshl.i32(i32 %value,i32 %value,i32 7)
 store i32 %value,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i32 %alias,ptr %next,align 1
 %wide = zext i32 %result to i64
 %original = zext i32 %value to i64
 %mixed = xor i64 %wide,%original
 %answer = xor i64 %mixed,%salt
 ret i64 %answer
}
define i64 @intrinsic_preservation_funnel32_load(i64 %raw,ptr %source,ptr %out,i64 %salt) {
entry:
 %value = load i32,ptr %source,align 1
 %alias = add i32 %value,0
 %result = call i32 @llvm.fshl.i32(i32 %value,i32 %value,i32 7)
 store i32 %value,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i32 %alias,ptr %next,align 1
 %wide = zext i32 %result to i64
 %original = zext i32 %value to i64
 %mixed = xor i64 %wide,%original
 %answer = xor i64 %mixed,%salt
 ret i64 %answer
}
define i64 @intrinsic_preservation_roundup(i16 %raw) {
entry:
 %value = zext i16 %raw to i64
 %count = call i64 @llvm.ctpop.i64(i64 %value)
 %sum = add i64 %value,9
 %negative = sub i64 0,%value
 %aligned = and i64 %sum,%negative
 %answer = add i64 %aligned,%count
 ret i64 %answer
}
