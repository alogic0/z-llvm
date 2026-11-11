target triple = "x86_64-unknown-linux-gnu"
target datalayout = "e-i128:128-f80:128"
declare i64 @extended80_integer_clobber(i64)
define i128 @extended80_itof_u1(i128 %raw,ptr %output,i64 %live) {
entry:
 %word = trunc i128 %raw to i64
 %narrow = trunc i64 %word to i1
 %converted = uitofp i1 %narrow to x86_fp80
 %probe = call i64 @extended80_integer_clobber(i64 %live)
 store x86_fp80 %converted,ptr %output,align 1
 %mask = zext i64 %probe to i128
 %answer = xor i128 %raw,%mask
 ret i128 %answer
}
define i128 @extended80_ftoi_u1(ptr %input,ptr %output,i64 %live) {
entry:
 %x = load x86_fp80,ptr %input,align 1
 %narrow = fptoui x86_fp80 %x to i1
 %wide = zext i1 %narrow to i128
 %probe = call i64 @extended80_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %mask = zext i64 %probe to i128
 %answer = xor i128 %wide,%mask
 ret i128 %answer
}
define i128 @extended80_itof_s1(i128 %raw,ptr %output,i64 %live) {
entry:
 %word = trunc i128 %raw to i64
 %narrow = trunc i64 %word to i1
 %converted = sitofp i1 %narrow to x86_fp80
 %probe = call i64 @extended80_integer_clobber(i64 %live)
 store x86_fp80 %converted,ptr %output,align 1
 %mask = zext i64 %probe to i128
 %answer = xor i128 %raw,%mask
 ret i128 %answer
}
define i128 @extended80_ftoi_s1(ptr %input,ptr %output,i64 %live) {
entry:
 %x = load x86_fp80,ptr %input,align 1
 %narrow = fptosi x86_fp80 %x to i1
 %wide = sext i1 %narrow to i128
 %probe = call i64 @extended80_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %mask = zext i64 %probe to i128
 %answer = xor i128 %wide,%mask
 ret i128 %answer
}
define i128 @extended80_itof_u8(i128 %raw,ptr %output,i64 %live) {
entry:
 %word = trunc i128 %raw to i64
 %narrow = trunc i64 %word to i8
 %converted = uitofp i8 %narrow to x86_fp80
 %probe = call i64 @extended80_integer_clobber(i64 %live)
 store x86_fp80 %converted,ptr %output,align 1
 %mask = zext i64 %probe to i128
 %answer = xor i128 %raw,%mask
 ret i128 %answer
}
define i128 @extended80_ftoi_u8(ptr %input,ptr %output,i64 %live) {
entry:
 %x = load x86_fp80,ptr %input,align 1
 %narrow = fptoui x86_fp80 %x to i8
 %wide = zext i8 %narrow to i128
 %probe = call i64 @extended80_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %mask = zext i64 %probe to i128
 %answer = xor i128 %wide,%mask
 ret i128 %answer
}
define i128 @extended80_itof_s8(i128 %raw,ptr %output,i64 %live) {
entry:
 %word = trunc i128 %raw to i64
 %narrow = trunc i64 %word to i8
 %converted = sitofp i8 %narrow to x86_fp80
 %probe = call i64 @extended80_integer_clobber(i64 %live)
 store x86_fp80 %converted,ptr %output,align 1
 %mask = zext i64 %probe to i128
 %answer = xor i128 %raw,%mask
 ret i128 %answer
}
define i128 @extended80_ftoi_s8(ptr %input,ptr %output,i64 %live) {
entry:
 %x = load x86_fp80,ptr %input,align 1
 %narrow = fptosi x86_fp80 %x to i8
 %wide = sext i8 %narrow to i128
 %probe = call i64 @extended80_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %mask = zext i64 %probe to i128
 %answer = xor i128 %wide,%mask
 ret i128 %answer
}
define i128 @extended80_itof_u16(i128 %raw,ptr %output,i64 %live) {
entry:
 %word = trunc i128 %raw to i64
 %narrow = trunc i64 %word to i16
 %converted = uitofp i16 %narrow to x86_fp80
 %probe = call i64 @extended80_integer_clobber(i64 %live)
 store x86_fp80 %converted,ptr %output,align 1
 %mask = zext i64 %probe to i128
 %answer = xor i128 %raw,%mask
 ret i128 %answer
}
define i128 @extended80_ftoi_u16(ptr %input,ptr %output,i64 %live) {
entry:
 %x = load x86_fp80,ptr %input,align 1
 %narrow = fptoui x86_fp80 %x to i16
 %wide = zext i16 %narrow to i128
 %probe = call i64 @extended80_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %mask = zext i64 %probe to i128
 %answer = xor i128 %wide,%mask
 ret i128 %answer
}
define i128 @extended80_itof_s16(i128 %raw,ptr %output,i64 %live) {
entry:
 %word = trunc i128 %raw to i64
 %narrow = trunc i64 %word to i16
 %converted = sitofp i16 %narrow to x86_fp80
 %probe = call i64 @extended80_integer_clobber(i64 %live)
 store x86_fp80 %converted,ptr %output,align 1
 %mask = zext i64 %probe to i128
 %answer = xor i128 %raw,%mask
 ret i128 %answer
}
define i128 @extended80_ftoi_s16(ptr %input,ptr %output,i64 %live) {
entry:
 %x = load x86_fp80,ptr %input,align 1
 %narrow = fptosi x86_fp80 %x to i16
 %wide = sext i16 %narrow to i128
 %probe = call i64 @extended80_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %mask = zext i64 %probe to i128
 %answer = xor i128 %wide,%mask
 ret i128 %answer
}
define i128 @extended80_itof_u32(i128 %raw,ptr %output,i64 %live) {
entry:
 %word = trunc i128 %raw to i64
 %narrow = trunc i64 %word to i32
 %converted = uitofp i32 %narrow to x86_fp80
 %probe = call i64 @extended80_integer_clobber(i64 %live)
 store x86_fp80 %converted,ptr %output,align 1
 %mask = zext i64 %probe to i128
 %answer = xor i128 %raw,%mask
 ret i128 %answer
}
define i128 @extended80_ftoi_u32(ptr %input,ptr %output,i64 %live) {
entry:
 %x = load x86_fp80,ptr %input,align 1
 %narrow = fptoui x86_fp80 %x to i32
 %wide = zext i32 %narrow to i128
 %probe = call i64 @extended80_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %mask = zext i64 %probe to i128
 %answer = xor i128 %wide,%mask
 ret i128 %answer
}
define i128 @extended80_itof_s32(i128 %raw,ptr %output,i64 %live) {
entry:
 %word = trunc i128 %raw to i64
 %narrow = trunc i64 %word to i32
 %converted = sitofp i32 %narrow to x86_fp80
 %probe = call i64 @extended80_integer_clobber(i64 %live)
 store x86_fp80 %converted,ptr %output,align 1
 %mask = zext i64 %probe to i128
 %answer = xor i128 %raw,%mask
 ret i128 %answer
}
define i128 @extended80_ftoi_s32(ptr %input,ptr %output,i64 %live) {
entry:
 %x = load x86_fp80,ptr %input,align 1
 %narrow = fptosi x86_fp80 %x to i32
 %wide = sext i32 %narrow to i128
 %probe = call i64 @extended80_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %mask = zext i64 %probe to i128
 %answer = xor i128 %wide,%mask
 ret i128 %answer
}
define i128 @extended80_itof_u52(i128 %raw,ptr %output,i64 %live) {
entry:
 %word = trunc i128 %raw to i64
 %narrow = trunc i64 %word to i52
 %converted = uitofp i52 %narrow to x86_fp80
 %probe = call i64 @extended80_integer_clobber(i64 %live)
 store x86_fp80 %converted,ptr %output,align 1
 %mask = zext i64 %probe to i128
 %answer = xor i128 %raw,%mask
 ret i128 %answer
}
define i128 @extended80_ftoi_u52(ptr %input,ptr %output,i64 %live) {
entry:
 %x = load x86_fp80,ptr %input,align 1
 %narrow = fptoui x86_fp80 %x to i52
 %wide = zext i52 %narrow to i128
 %probe = call i64 @extended80_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %mask = zext i64 %probe to i128
 %answer = xor i128 %wide,%mask
 ret i128 %answer
}
define i128 @extended80_itof_s52(i128 %raw,ptr %output,i64 %live) {
entry:
 %word = trunc i128 %raw to i64
 %narrow = trunc i64 %word to i52
 %converted = sitofp i52 %narrow to x86_fp80
 %probe = call i64 @extended80_integer_clobber(i64 %live)
 store x86_fp80 %converted,ptr %output,align 1
 %mask = zext i64 %probe to i128
 %answer = xor i128 %raw,%mask
 ret i128 %answer
}
define i128 @extended80_ftoi_s52(ptr %input,ptr %output,i64 %live) {
entry:
 %x = load x86_fp80,ptr %input,align 1
 %narrow = fptosi x86_fp80 %x to i52
 %wide = sext i52 %narrow to i128
 %probe = call i64 @extended80_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %mask = zext i64 %probe to i128
 %answer = xor i128 %wide,%mask
 ret i128 %answer
}
define i128 @extended80_itof_u64(i128 %raw,ptr %output,i64 %live) {
entry:
 %word = trunc i128 %raw to i64
 %narrow = trunc i128 %raw to i64
 %converted = uitofp i64 %narrow to x86_fp80
 %probe = call i64 @extended80_integer_clobber(i64 %live)
 store x86_fp80 %converted,ptr %output,align 1
 %mask = zext i64 %probe to i128
 %answer = xor i128 %raw,%mask
 ret i128 %answer
}
define i128 @extended80_ftoi_u64(ptr %input,ptr %output,i64 %live) {
entry:
 %x = load x86_fp80,ptr %input,align 1
 %narrow = fptoui x86_fp80 %x to i64
 %wide = zext i64 %narrow to i128
 %probe = call i64 @extended80_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %mask = zext i64 %probe to i128
 %answer = xor i128 %wide,%mask
 ret i128 %answer
}
define i128 @extended80_itof_s64(i128 %raw,ptr %output,i64 %live) {
entry:
 %word = trunc i128 %raw to i64
 %narrow = trunc i128 %raw to i64
 %converted = sitofp i64 %narrow to x86_fp80
 %probe = call i64 @extended80_integer_clobber(i64 %live)
 store x86_fp80 %converted,ptr %output,align 1
 %mask = zext i64 %probe to i128
 %answer = xor i128 %raw,%mask
 ret i128 %answer
}
define i128 @extended80_ftoi_s64(ptr %input,ptr %output,i64 %live) {
entry:
 %x = load x86_fp80,ptr %input,align 1
 %narrow = fptosi x86_fp80 %x to i64
 %wide = sext i64 %narrow to i128
 %probe = call i64 @extended80_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %mask = zext i64 %probe to i128
 %answer = xor i128 %wide,%mask
 ret i128 %answer
}
define i128 @extended80_itof_u65(i128 %raw,ptr %output,i64 %live) {
entry:
 %word = trunc i128 %raw to i64
 %narrow = trunc i128 %raw to i65
 %converted = uitofp i65 %narrow to x86_fp80
 %probe = call i64 @extended80_integer_clobber(i64 %live)
 store x86_fp80 %converted,ptr %output,align 1
 %mask = zext i64 %probe to i128
 %answer = xor i128 %raw,%mask
 ret i128 %answer
}
define i128 @extended80_ftoi_u65(ptr %input,ptr %output,i64 %live) {
entry:
 %x = load x86_fp80,ptr %input,align 1
 %narrow = fptoui x86_fp80 %x to i65
 %wide = zext i65 %narrow to i128
 %probe = call i64 @extended80_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %mask = zext i64 %probe to i128
 %answer = xor i128 %wide,%mask
 ret i128 %answer
}
define i128 @extended80_itof_s65(i128 %raw,ptr %output,i64 %live) {
entry:
 %word = trunc i128 %raw to i64
 %narrow = trunc i128 %raw to i65
 %converted = sitofp i65 %narrow to x86_fp80
 %probe = call i64 @extended80_integer_clobber(i64 %live)
 store x86_fp80 %converted,ptr %output,align 1
 %mask = zext i64 %probe to i128
 %answer = xor i128 %raw,%mask
 ret i128 %answer
}
define i128 @extended80_ftoi_s65(ptr %input,ptr %output,i64 %live) {
entry:
 %x = load x86_fp80,ptr %input,align 1
 %narrow = fptosi x86_fp80 %x to i65
 %wide = sext i65 %narrow to i128
 %probe = call i64 @extended80_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %mask = zext i64 %probe to i128
 %answer = xor i128 %wide,%mask
 ret i128 %answer
}
define i128 @extended80_itof_u80(i128 %raw,ptr %output,i64 %live) {
entry:
 %word = trunc i128 %raw to i64
 %narrow = trunc i128 %raw to i80
 %converted = uitofp i80 %narrow to x86_fp80
 %probe = call i64 @extended80_integer_clobber(i64 %live)
 store x86_fp80 %converted,ptr %output,align 1
 %mask = zext i64 %probe to i128
 %answer = xor i128 %raw,%mask
 ret i128 %answer
}
define i128 @extended80_ftoi_u80(ptr %input,ptr %output,i64 %live) {
entry:
 %x = load x86_fp80,ptr %input,align 1
 %narrow = fptoui x86_fp80 %x to i80
 %wide = zext i80 %narrow to i128
 %probe = call i64 @extended80_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %mask = zext i64 %probe to i128
 %answer = xor i128 %wide,%mask
 ret i128 %answer
}
define i128 @extended80_itof_s80(i128 %raw,ptr %output,i64 %live) {
entry:
 %word = trunc i128 %raw to i64
 %narrow = trunc i128 %raw to i80
 %converted = sitofp i80 %narrow to x86_fp80
 %probe = call i64 @extended80_integer_clobber(i64 %live)
 store x86_fp80 %converted,ptr %output,align 1
 %mask = zext i64 %probe to i128
 %answer = xor i128 %raw,%mask
 ret i128 %answer
}
define i128 @extended80_ftoi_s80(ptr %input,ptr %output,i64 %live) {
entry:
 %x = load x86_fp80,ptr %input,align 1
 %narrow = fptosi x86_fp80 %x to i80
 %wide = sext i80 %narrow to i128
 %probe = call i64 @extended80_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %mask = zext i64 %probe to i128
 %answer = xor i128 %wide,%mask
 ret i128 %answer
}
define i128 @extended80_itof_u127(i128 %raw,ptr %output,i64 %live) {
entry:
 %word = trunc i128 %raw to i64
 %narrow = trunc i128 %raw to i127
 %converted = uitofp i127 %narrow to x86_fp80
 %probe = call i64 @extended80_integer_clobber(i64 %live)
 store x86_fp80 %converted,ptr %output,align 1
 %mask = zext i64 %probe to i128
 %answer = xor i128 %raw,%mask
 ret i128 %answer
}
define i128 @extended80_ftoi_u127(ptr %input,ptr %output,i64 %live) {
entry:
 %x = load x86_fp80,ptr %input,align 1
 %narrow = fptoui x86_fp80 %x to i127
 %wide = zext i127 %narrow to i128
 %probe = call i64 @extended80_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %mask = zext i64 %probe to i128
 %answer = xor i128 %wide,%mask
 ret i128 %answer
}
define i128 @extended80_itof_s127(i128 %raw,ptr %output,i64 %live) {
entry:
 %word = trunc i128 %raw to i64
 %narrow = trunc i128 %raw to i127
 %converted = sitofp i127 %narrow to x86_fp80
 %probe = call i64 @extended80_integer_clobber(i64 %live)
 store x86_fp80 %converted,ptr %output,align 1
 %mask = zext i64 %probe to i128
 %answer = xor i128 %raw,%mask
 ret i128 %answer
}
define i128 @extended80_ftoi_s127(ptr %input,ptr %output,i64 %live) {
entry:
 %x = load x86_fp80,ptr %input,align 1
 %narrow = fptosi x86_fp80 %x to i127
 %wide = sext i127 %narrow to i128
 %probe = call i64 @extended80_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %mask = zext i64 %probe to i128
 %answer = xor i128 %wide,%mask
 ret i128 %answer
}
define i128 @extended80_itof_u128(i128 %raw,ptr %output,i64 %live) {
entry:
 %word = trunc i128 %raw to i64
 %narrow = add i128 %raw,0
 %converted = uitofp i128 %narrow to x86_fp80
 %probe = call i64 @extended80_integer_clobber(i64 %live)
 store x86_fp80 %converted,ptr %output,align 1
 %mask = zext i64 %probe to i128
 %answer = xor i128 %raw,%mask
 ret i128 %answer
}
define i128 @extended80_ftoi_u128(ptr %input,ptr %output,i64 %live) {
entry:
 %x = load x86_fp80,ptr %input,align 1
 %narrow = fptoui x86_fp80 %x to i128
 %wide = add i128 %narrow,0
 %probe = call i64 @extended80_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %mask = zext i64 %probe to i128
 %answer = xor i128 %wide,%mask
 ret i128 %answer
}
define i128 @extended80_itof_s128(i128 %raw,ptr %output,i64 %live) {
entry:
 %word = trunc i128 %raw to i64
 %narrow = add i128 %raw,0
 %converted = sitofp i128 %narrow to x86_fp80
 %probe = call i64 @extended80_integer_clobber(i64 %live)
 store x86_fp80 %converted,ptr %output,align 1
 %mask = zext i64 %probe to i128
 %answer = xor i128 %raw,%mask
 ret i128 %answer
}
define i128 @extended80_ftoi_s128(ptr %input,ptr %output,i64 %live) {
entry:
 %x = load x86_fp80,ptr %input,align 1
 %narrow = fptosi x86_fp80 %x to i128
 %wide = add i128 %narrow,0
 %probe = call i64 @extended80_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %mask = zext i64 %probe to i128
 %answer = xor i128 %wide,%mask
 ret i128 %answer
}
define i128 @extended80_itof_constant_0(i128 %raw,ptr %output,i64 %live) {
entry:
 %converted = sitofp i128 -170141183460469231731687303715884105728 to x86_fp80
 %probe = call i64 @extended80_integer_clobber(i64 %live)
 store x86_fp80 %converted,ptr %output,align 1
 %mask = zext i64 %probe to i128
 %answer = xor i128 %raw,%mask
 ret i128 %answer
}
define i128 @extended80_itof_constant_1(i128 %raw,ptr %output,i64 %live) {
entry:
 %converted = uitofp i128 -1 to x86_fp80
 %probe = call i64 @extended80_integer_clobber(i64 %live)
 store x86_fp80 %converted,ptr %output,align 1
 %mask = zext i64 %probe to i128
 %answer = xor i128 %raw,%mask
 ret i128 %answer
}
define i128 @extended80_itof_constant_2(i128 %raw,ptr %output,i64 %live) {
entry:
 %converted = uitofp i128 0 to x86_fp80
 %probe = call i64 @extended80_integer_clobber(i64 %live)
 store x86_fp80 %converted,ptr %output,align 1
 %mask = zext i64 %probe to i128
 %answer = xor i128 %raw,%mask
 ret i128 %answer
}
define i128 @extended80_itof_constant_3(i128 %raw,ptr %output,i64 %live) {
entry:
 %converted = sitofp i128 9223372036854775809 to x86_fp80
 %probe = call i64 @extended80_integer_clobber(i64 %live)
 store x86_fp80 %converted,ptr %output,align 1
 %mask = zext i64 %probe to i128
 %answer = xor i128 %raw,%mask
 ret i128 %answer
}
