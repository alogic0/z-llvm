target triple = "x86_64-unknown-linux-gnu"
target datalayout = "e-i128:128"
declare i64 @scalar_integer_clobber(i64)
define i128 @scalar_integer_to_quad_1_0_0(i128 %raw,ptr %output,i64 %live) {
entry:
 %narrow = trunc i128 %raw to i1
 %converted = uitofp i1 %narrow to fp128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store fp128 %converted,ptr %output,align 1
 %wide = zext i64 %probe to i128
 %answer = xor i128 %raw,%wide
 ret i128 %answer
}
define i128 @scalar_integer_to_quad_1_1_0(i128 %raw,ptr %output,i64 %live) {
entry:
 %narrow = trunc i128 %raw to i1
 %converted = sitofp i1 %narrow to fp128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store fp128 %converted,ptr %output,align 1
 %wide = zext i64 %probe to i128
 %answer = xor i128 %raw,%wide
 ret i128 %answer
}
define i128 @scalar_integer_to_quad_8_0_0(i128 %raw,ptr %output,i64 %live) {
entry:
 %narrow = trunc i128 %raw to i8
 %converted = uitofp i8 %narrow to fp128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store fp128 %converted,ptr %output,align 1
 %wide = zext i64 %probe to i128
 %answer = xor i128 %raw,%wide
 ret i128 %answer
}
define i128 @scalar_integer_to_quad_8_1_0(i128 %raw,ptr %output,i64 %live) {
entry:
 %narrow = trunc i128 %raw to i8
 %converted = sitofp i8 %narrow to fp128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store fp128 %converted,ptr %output,align 1
 %wide = zext i64 %probe to i128
 %answer = xor i128 %raw,%wide
 ret i128 %answer
}
define i128 @scalar_integer_to_quad_16_0_0(i128 %raw,ptr %output,i64 %live) {
entry:
 %narrow = trunc i128 %raw to i16
 %converted = uitofp i16 %narrow to fp128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store fp128 %converted,ptr %output,align 1
 %wide = zext i64 %probe to i128
 %answer = xor i128 %raw,%wide
 ret i128 %answer
}
define i128 @scalar_integer_to_quad_16_1_0(i128 %raw,ptr %output,i64 %live) {
entry:
 %narrow = trunc i128 %raw to i16
 %converted = sitofp i16 %narrow to fp128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store fp128 %converted,ptr %output,align 1
 %wide = zext i64 %probe to i128
 %answer = xor i128 %raw,%wide
 ret i128 %answer
}
define i128 @scalar_integer_to_quad_32_0_0(i128 %raw,ptr %output,i64 %live) {
entry:
 %narrow = trunc i128 %raw to i32
 %converted = uitofp i32 %narrow to fp128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store fp128 %converted,ptr %output,align 1
 %wide = zext i64 %probe to i128
 %answer = xor i128 %raw,%wide
 ret i128 %answer
}
define i128 @scalar_integer_to_quad_32_1_0(i128 %raw,ptr %output,i64 %live) {
entry:
 %narrow = trunc i128 %raw to i32
 %converted = sitofp i32 %narrow to fp128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store fp128 %converted,ptr %output,align 1
 %wide = zext i64 %probe to i128
 %answer = xor i128 %raw,%wide
 ret i128 %answer
}
define i128 @scalar_integer_to_quad_52_0_0(i128 %raw,ptr %output,i64 %live) {
entry:
 %narrow = trunc i128 %raw to i52
 %converted = uitofp i52 %narrow to fp128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store fp128 %converted,ptr %output,align 1
 %wide = zext i64 %probe to i128
 %answer = xor i128 %raw,%wide
 ret i128 %answer
}
define i128 @scalar_integer_to_quad_52_1_0(i128 %raw,ptr %output,i64 %live) {
entry:
 %narrow = trunc i128 %raw to i52
 %converted = sitofp i52 %narrow to fp128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store fp128 %converted,ptr %output,align 1
 %wide = zext i64 %probe to i128
 %answer = xor i128 %raw,%wide
 ret i128 %answer
}
define i128 @scalar_integer_to_quad_64_0_0(i128 %raw,ptr %output,i64 %live) {
entry:
 %narrow = trunc i128 %raw to i64
 %converted = uitofp i64 %narrow to fp128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store fp128 %converted,ptr %output,align 1
 %wide = zext i64 %probe to i128
 %answer = xor i128 %raw,%wide
 ret i128 %answer
}
define i128 @scalar_integer_to_quad_64_1_0(i128 %raw,ptr %output,i64 %live) {
entry:
 %narrow = trunc i128 %raw to i64
 %converted = sitofp i64 %narrow to fp128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store fp128 %converted,ptr %output,align 1
 %wide = zext i64 %probe to i128
 %answer = xor i128 %raw,%wide
 ret i128 %answer
}
define i128 @scalar_integer_to_quad_65_0_0(i128 %raw,ptr %output,i64 %live) {
entry:
 %narrow = trunc i128 %raw to i65
 %converted = uitofp i65 %narrow to fp128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store fp128 %converted,ptr %output,align 1
 %wide = zext i64 %probe to i128
 %answer = xor i128 %raw,%wide
 ret i128 %answer
}
define i128 @scalar_integer_to_quad_65_1_0(i128 %raw,ptr %output,i64 %live) {
entry:
 %narrow = trunc i128 %raw to i65
 %converted = sitofp i65 %narrow to fp128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store fp128 %converted,ptr %output,align 1
 %wide = zext i64 %probe to i128
 %answer = xor i128 %raw,%wide
 ret i128 %answer
}
define i128 @scalar_integer_to_quad_80_0_0(i128 %raw,ptr %output,i64 %live) {
entry:
 %narrow = trunc i128 %raw to i80
 %converted = uitofp i80 %narrow to fp128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store fp128 %converted,ptr %output,align 1
 %wide = zext i64 %probe to i128
 %answer = xor i128 %raw,%wide
 ret i128 %answer
}
define i128 @scalar_integer_to_quad_80_1_0(i128 %raw,ptr %output,i64 %live) {
entry:
 %narrow = trunc i128 %raw to i80
 %converted = sitofp i80 %narrow to fp128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store fp128 %converted,ptr %output,align 1
 %wide = zext i64 %probe to i128
 %answer = xor i128 %raw,%wide
 ret i128 %answer
}
define i128 @scalar_integer_to_quad_113_0_0(i128 %raw,ptr %output,i64 %live) {
entry:
 %narrow = trunc i128 %raw to i113
 %converted = uitofp i113 %narrow to fp128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store fp128 %converted,ptr %output,align 1
 %wide = zext i64 %probe to i128
 %answer = xor i128 %raw,%wide
 ret i128 %answer
}
define i128 @scalar_integer_to_quad_113_1_0(i128 %raw,ptr %output,i64 %live) {
entry:
 %narrow = trunc i128 %raw to i113
 %converted = sitofp i113 %narrow to fp128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store fp128 %converted,ptr %output,align 1
 %wide = zext i64 %probe to i128
 %answer = xor i128 %raw,%wide
 ret i128 %answer
}
define i128 @scalar_integer_to_quad_127_0_0(i128 %raw,ptr %output,i64 %live) {
entry:
 %narrow = trunc i128 %raw to i127
 %converted = uitofp i127 %narrow to fp128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store fp128 %converted,ptr %output,align 1
 %wide = zext i64 %probe to i128
 %answer = xor i128 %raw,%wide
 ret i128 %answer
}
define i128 @scalar_integer_to_quad_127_1_0(i128 %raw,ptr %output,i64 %live) {
entry:
 %narrow = trunc i128 %raw to i127
 %converted = sitofp i127 %narrow to fp128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store fp128 %converted,ptr %output,align 1
 %wide = zext i64 %probe to i128
 %answer = xor i128 %raw,%wide
 ret i128 %answer
}
define i128 @scalar_integer_to_quad_128_0_0(i128 %raw,ptr %output,i64 %live) {
entry:
 %narrow = add i128 %raw,0
 %converted = uitofp i128 %narrow to fp128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store fp128 %converted,ptr %output,align 1
 %wide = zext i64 %probe to i128
 %answer = xor i128 %raw,%wide
 ret i128 %answer
}
define i128 @scalar_integer_to_quad_128_1_0(i128 %raw,ptr %output,i64 %live) {
entry:
 %narrow = add i128 %raw,0
 %converted = sitofp i128 %narrow to fp128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store fp128 %converted,ptr %output,align 1
 %wide = zext i64 %probe to i128
 %answer = xor i128 %raw,%wide
 ret i128 %answer
}
define i128 @scalar_integer_to_quad_128_0_1(i128 %raw,ptr %output,i64 %live) {
entry:
 %narrow = add i128 %raw,0
 %converted = uitofp i128 -1512366075204170947332355369683137041 to fp128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store fp128 %converted,ptr %output,align 1
 %wide = zext i64 %probe to i128
 %answer = xor i128 %raw,%wide
 ret i128 %answer
}
define i128 @scalar_integer_to_quad_128_1_1(i128 %raw,ptr %output,i64 %live) {
entry:
 %narrow = add i128 %raw,0
 %converted = sitofp i128 -1512366075204170947332355369683137041 to fp128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store fp128 %converted,ptr %output,align 1
 %wide = zext i64 %probe to i128
 %answer = xor i128 %raw,%wide
 ret i128 %answer
}
define i128 @scalar_integer_from_0_1_0(ptr %input,ptr %output,i64 %live) {
entry:
 %value = load half,ptr %input,align 1
 %converted = fptoui half %value to i1
 %wide = zext i1 %converted to i128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @scalar_integer_from_0_1_1(ptr %input,ptr %output,i64 %live) {
entry:
 %value = load half,ptr %input,align 1
 %converted = fptosi half %value to i1
 %wide = zext i1 %converted to i128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @scalar_integer_from_0_8_0(ptr %input,ptr %output,i64 %live) {
entry:
 %value = load half,ptr %input,align 1
 %converted = fptoui half %value to i8
 %wide = zext i8 %converted to i128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @scalar_integer_from_0_8_1(ptr %input,ptr %output,i64 %live) {
entry:
 %value = load half,ptr %input,align 1
 %converted = fptosi half %value to i8
 %wide = zext i8 %converted to i128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @scalar_integer_from_0_16_0(ptr %input,ptr %output,i64 %live) {
entry:
 %value = load half,ptr %input,align 1
 %converted = fptoui half %value to i16
 %wide = zext i16 %converted to i128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @scalar_integer_from_0_16_1(ptr %input,ptr %output,i64 %live) {
entry:
 %value = load half,ptr %input,align 1
 %converted = fptosi half %value to i16
 %wide = zext i16 %converted to i128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @scalar_integer_from_0_32_0(ptr %input,ptr %output,i64 %live) {
entry:
 %value = load half,ptr %input,align 1
 %converted = fptoui half %value to i32
 %wide = zext i32 %converted to i128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @scalar_integer_from_0_32_1(ptr %input,ptr %output,i64 %live) {
entry:
 %value = load half,ptr %input,align 1
 %converted = fptosi half %value to i32
 %wide = zext i32 %converted to i128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @scalar_integer_from_0_52_0(ptr %input,ptr %output,i64 %live) {
entry:
 %value = load half,ptr %input,align 1
 %converted = fptoui half %value to i52
 %wide = zext i52 %converted to i128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @scalar_integer_from_0_52_1(ptr %input,ptr %output,i64 %live) {
entry:
 %value = load half,ptr %input,align 1
 %converted = fptosi half %value to i52
 %wide = zext i52 %converted to i128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @scalar_integer_from_0_64_0(ptr %input,ptr %output,i64 %live) {
entry:
 %value = load half,ptr %input,align 1
 %converted = fptoui half %value to i64
 %wide = zext i64 %converted to i128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @scalar_integer_from_0_64_1(ptr %input,ptr %output,i64 %live) {
entry:
 %value = load half,ptr %input,align 1
 %converted = fptosi half %value to i64
 %wide = zext i64 %converted to i128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @scalar_integer_from_0_65_0(ptr %input,ptr %output,i64 %live) {
entry:
 %value = load half,ptr %input,align 1
 %converted = fptoui half %value to i65
 %wide = zext i65 %converted to i128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @scalar_integer_from_0_65_1(ptr %input,ptr %output,i64 %live) {
entry:
 %value = load half,ptr %input,align 1
 %converted = fptosi half %value to i65
 %wide = zext i65 %converted to i128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @scalar_integer_from_0_80_0(ptr %input,ptr %output,i64 %live) {
entry:
 %value = load half,ptr %input,align 1
 %converted = fptoui half %value to i80
 %wide = zext i80 %converted to i128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @scalar_integer_from_0_80_1(ptr %input,ptr %output,i64 %live) {
entry:
 %value = load half,ptr %input,align 1
 %converted = fptosi half %value to i80
 %wide = zext i80 %converted to i128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @scalar_integer_from_0_113_0(ptr %input,ptr %output,i64 %live) {
entry:
 %value = load half,ptr %input,align 1
 %converted = fptoui half %value to i113
 %wide = zext i113 %converted to i128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @scalar_integer_from_0_113_1(ptr %input,ptr %output,i64 %live) {
entry:
 %value = load half,ptr %input,align 1
 %converted = fptosi half %value to i113
 %wide = zext i113 %converted to i128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @scalar_integer_from_0_127_0(ptr %input,ptr %output,i64 %live) {
entry:
 %value = load half,ptr %input,align 1
 %converted = fptoui half %value to i127
 %wide = zext i127 %converted to i128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @scalar_integer_from_0_127_1(ptr %input,ptr %output,i64 %live) {
entry:
 %value = load half,ptr %input,align 1
 %converted = fptosi half %value to i127
 %wide = zext i127 %converted to i128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @scalar_integer_from_0_128_0(ptr %input,ptr %output,i64 %live) {
entry:
 %value = load half,ptr %input,align 1
 %converted = fptoui half %value to i128
 %wide = add i128 %converted,0
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @scalar_integer_from_0_128_1(ptr %input,ptr %output,i64 %live) {
entry:
 %value = load half,ptr %input,align 1
 %converted = fptosi half %value to i128
 %wide = add i128 %converted,0
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @scalar_integer_from_1_1_0(ptr %input,ptr %output,i64 %live) {
entry:
 %value = load float,ptr %input,align 1
 %converted = fptoui float %value to i1
 %wide = zext i1 %converted to i128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @scalar_integer_from_1_1_1(ptr %input,ptr %output,i64 %live) {
entry:
 %value = load float,ptr %input,align 1
 %converted = fptosi float %value to i1
 %wide = zext i1 %converted to i128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @scalar_integer_from_1_8_0(ptr %input,ptr %output,i64 %live) {
entry:
 %value = load float,ptr %input,align 1
 %converted = fptoui float %value to i8
 %wide = zext i8 %converted to i128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @scalar_integer_from_1_8_1(ptr %input,ptr %output,i64 %live) {
entry:
 %value = load float,ptr %input,align 1
 %converted = fptosi float %value to i8
 %wide = zext i8 %converted to i128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @scalar_integer_from_1_16_0(ptr %input,ptr %output,i64 %live) {
entry:
 %value = load float,ptr %input,align 1
 %converted = fptoui float %value to i16
 %wide = zext i16 %converted to i128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @scalar_integer_from_1_16_1(ptr %input,ptr %output,i64 %live) {
entry:
 %value = load float,ptr %input,align 1
 %converted = fptosi float %value to i16
 %wide = zext i16 %converted to i128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @scalar_integer_from_1_32_0(ptr %input,ptr %output,i64 %live) {
entry:
 %value = load float,ptr %input,align 1
 %converted = fptoui float %value to i32
 %wide = zext i32 %converted to i128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @scalar_integer_from_1_32_1(ptr %input,ptr %output,i64 %live) {
entry:
 %value = load float,ptr %input,align 1
 %converted = fptosi float %value to i32
 %wide = zext i32 %converted to i128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @scalar_integer_from_1_52_0(ptr %input,ptr %output,i64 %live) {
entry:
 %value = load float,ptr %input,align 1
 %converted = fptoui float %value to i52
 %wide = zext i52 %converted to i128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @scalar_integer_from_1_52_1(ptr %input,ptr %output,i64 %live) {
entry:
 %value = load float,ptr %input,align 1
 %converted = fptosi float %value to i52
 %wide = zext i52 %converted to i128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @scalar_integer_from_1_64_0(ptr %input,ptr %output,i64 %live) {
entry:
 %value = load float,ptr %input,align 1
 %converted = fptoui float %value to i64
 %wide = zext i64 %converted to i128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @scalar_integer_from_1_64_1(ptr %input,ptr %output,i64 %live) {
entry:
 %value = load float,ptr %input,align 1
 %converted = fptosi float %value to i64
 %wide = zext i64 %converted to i128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @scalar_integer_from_1_65_0(ptr %input,ptr %output,i64 %live) {
entry:
 %value = load float,ptr %input,align 1
 %converted = fptoui float %value to i65
 %wide = zext i65 %converted to i128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @scalar_integer_from_1_65_1(ptr %input,ptr %output,i64 %live) {
entry:
 %value = load float,ptr %input,align 1
 %converted = fptosi float %value to i65
 %wide = zext i65 %converted to i128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @scalar_integer_from_1_80_0(ptr %input,ptr %output,i64 %live) {
entry:
 %value = load float,ptr %input,align 1
 %converted = fptoui float %value to i80
 %wide = zext i80 %converted to i128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @scalar_integer_from_1_80_1(ptr %input,ptr %output,i64 %live) {
entry:
 %value = load float,ptr %input,align 1
 %converted = fptosi float %value to i80
 %wide = zext i80 %converted to i128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @scalar_integer_from_1_113_0(ptr %input,ptr %output,i64 %live) {
entry:
 %value = load float,ptr %input,align 1
 %converted = fptoui float %value to i113
 %wide = zext i113 %converted to i128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @scalar_integer_from_1_113_1(ptr %input,ptr %output,i64 %live) {
entry:
 %value = load float,ptr %input,align 1
 %converted = fptosi float %value to i113
 %wide = zext i113 %converted to i128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @scalar_integer_from_1_127_0(ptr %input,ptr %output,i64 %live) {
entry:
 %value = load float,ptr %input,align 1
 %converted = fptoui float %value to i127
 %wide = zext i127 %converted to i128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @scalar_integer_from_1_127_1(ptr %input,ptr %output,i64 %live) {
entry:
 %value = load float,ptr %input,align 1
 %converted = fptosi float %value to i127
 %wide = zext i127 %converted to i128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @scalar_integer_from_1_128_0(ptr %input,ptr %output,i64 %live) {
entry:
 %value = load float,ptr %input,align 1
 %converted = fptoui float %value to i128
 %wide = add i128 %converted,0
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @scalar_integer_from_1_128_1(ptr %input,ptr %output,i64 %live) {
entry:
 %value = load float,ptr %input,align 1
 %converted = fptosi float %value to i128
 %wide = add i128 %converted,0
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @scalar_integer_from_2_1_0(ptr %input,ptr %output,i64 %live) {
entry:
 %value = load double,ptr %input,align 1
 %converted = fptoui double %value to i1
 %wide = zext i1 %converted to i128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @scalar_integer_from_2_1_1(ptr %input,ptr %output,i64 %live) {
entry:
 %value = load double,ptr %input,align 1
 %converted = fptosi double %value to i1
 %wide = zext i1 %converted to i128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @scalar_integer_from_2_8_0(ptr %input,ptr %output,i64 %live) {
entry:
 %value = load double,ptr %input,align 1
 %converted = fptoui double %value to i8
 %wide = zext i8 %converted to i128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @scalar_integer_from_2_8_1(ptr %input,ptr %output,i64 %live) {
entry:
 %value = load double,ptr %input,align 1
 %converted = fptosi double %value to i8
 %wide = zext i8 %converted to i128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @scalar_integer_from_2_16_0(ptr %input,ptr %output,i64 %live) {
entry:
 %value = load double,ptr %input,align 1
 %converted = fptoui double %value to i16
 %wide = zext i16 %converted to i128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @scalar_integer_from_2_16_1(ptr %input,ptr %output,i64 %live) {
entry:
 %value = load double,ptr %input,align 1
 %converted = fptosi double %value to i16
 %wide = zext i16 %converted to i128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @scalar_integer_from_2_32_0(ptr %input,ptr %output,i64 %live) {
entry:
 %value = load double,ptr %input,align 1
 %converted = fptoui double %value to i32
 %wide = zext i32 %converted to i128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @scalar_integer_from_2_32_1(ptr %input,ptr %output,i64 %live) {
entry:
 %value = load double,ptr %input,align 1
 %converted = fptosi double %value to i32
 %wide = zext i32 %converted to i128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @scalar_integer_from_2_52_0(ptr %input,ptr %output,i64 %live) {
entry:
 %value = load double,ptr %input,align 1
 %converted = fptoui double %value to i52
 %wide = zext i52 %converted to i128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @scalar_integer_from_2_52_1(ptr %input,ptr %output,i64 %live) {
entry:
 %value = load double,ptr %input,align 1
 %converted = fptosi double %value to i52
 %wide = zext i52 %converted to i128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @scalar_integer_from_2_64_0(ptr %input,ptr %output,i64 %live) {
entry:
 %value = load double,ptr %input,align 1
 %converted = fptoui double %value to i64
 %wide = zext i64 %converted to i128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @scalar_integer_from_2_64_1(ptr %input,ptr %output,i64 %live) {
entry:
 %value = load double,ptr %input,align 1
 %converted = fptosi double %value to i64
 %wide = zext i64 %converted to i128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @scalar_integer_from_2_65_0(ptr %input,ptr %output,i64 %live) {
entry:
 %value = load double,ptr %input,align 1
 %converted = fptoui double %value to i65
 %wide = zext i65 %converted to i128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @scalar_integer_from_2_65_1(ptr %input,ptr %output,i64 %live) {
entry:
 %value = load double,ptr %input,align 1
 %converted = fptosi double %value to i65
 %wide = zext i65 %converted to i128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @scalar_integer_from_2_80_0(ptr %input,ptr %output,i64 %live) {
entry:
 %value = load double,ptr %input,align 1
 %converted = fptoui double %value to i80
 %wide = zext i80 %converted to i128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @scalar_integer_from_2_80_1(ptr %input,ptr %output,i64 %live) {
entry:
 %value = load double,ptr %input,align 1
 %converted = fptosi double %value to i80
 %wide = zext i80 %converted to i128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @scalar_integer_from_2_113_0(ptr %input,ptr %output,i64 %live) {
entry:
 %value = load double,ptr %input,align 1
 %converted = fptoui double %value to i113
 %wide = zext i113 %converted to i128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @scalar_integer_from_2_113_1(ptr %input,ptr %output,i64 %live) {
entry:
 %value = load double,ptr %input,align 1
 %converted = fptosi double %value to i113
 %wide = zext i113 %converted to i128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @scalar_integer_from_2_127_0(ptr %input,ptr %output,i64 %live) {
entry:
 %value = load double,ptr %input,align 1
 %converted = fptoui double %value to i127
 %wide = zext i127 %converted to i128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @scalar_integer_from_2_127_1(ptr %input,ptr %output,i64 %live) {
entry:
 %value = load double,ptr %input,align 1
 %converted = fptosi double %value to i127
 %wide = zext i127 %converted to i128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @scalar_integer_from_2_128_0(ptr %input,ptr %output,i64 %live) {
entry:
 %value = load double,ptr %input,align 1
 %converted = fptoui double %value to i128
 %wide = add i128 %converted,0
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @scalar_integer_from_2_128_1(ptr %input,ptr %output,i64 %live) {
entry:
 %value = load double,ptr %input,align 1
 %converted = fptosi double %value to i128
 %wide = add i128 %converted,0
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @scalar_integer_from_3_1_0(ptr %input,ptr %output,i64 %live) {
entry:
 %value = load fp128,ptr %input,align 1
 %converted = fptoui fp128 %value to i1
 %wide = zext i1 %converted to i128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @scalar_integer_from_3_1_1(ptr %input,ptr %output,i64 %live) {
entry:
 %value = load fp128,ptr %input,align 1
 %converted = fptosi fp128 %value to i1
 %wide = zext i1 %converted to i128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @scalar_integer_from_3_8_0(ptr %input,ptr %output,i64 %live) {
entry:
 %value = load fp128,ptr %input,align 1
 %converted = fptoui fp128 %value to i8
 %wide = zext i8 %converted to i128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @scalar_integer_from_3_8_1(ptr %input,ptr %output,i64 %live) {
entry:
 %value = load fp128,ptr %input,align 1
 %converted = fptosi fp128 %value to i8
 %wide = zext i8 %converted to i128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @scalar_integer_from_3_16_0(ptr %input,ptr %output,i64 %live) {
entry:
 %value = load fp128,ptr %input,align 1
 %converted = fptoui fp128 %value to i16
 %wide = zext i16 %converted to i128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @scalar_integer_from_3_16_1(ptr %input,ptr %output,i64 %live) {
entry:
 %value = load fp128,ptr %input,align 1
 %converted = fptosi fp128 %value to i16
 %wide = zext i16 %converted to i128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @scalar_integer_from_3_32_0(ptr %input,ptr %output,i64 %live) {
entry:
 %value = load fp128,ptr %input,align 1
 %converted = fptoui fp128 %value to i32
 %wide = zext i32 %converted to i128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @scalar_integer_from_3_32_1(ptr %input,ptr %output,i64 %live) {
entry:
 %value = load fp128,ptr %input,align 1
 %converted = fptosi fp128 %value to i32
 %wide = zext i32 %converted to i128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @scalar_integer_from_3_52_0(ptr %input,ptr %output,i64 %live) {
entry:
 %value = load fp128,ptr %input,align 1
 %converted = fptoui fp128 %value to i52
 %wide = zext i52 %converted to i128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @scalar_integer_from_3_52_1(ptr %input,ptr %output,i64 %live) {
entry:
 %value = load fp128,ptr %input,align 1
 %converted = fptosi fp128 %value to i52
 %wide = zext i52 %converted to i128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @scalar_integer_from_3_64_0(ptr %input,ptr %output,i64 %live) {
entry:
 %value = load fp128,ptr %input,align 1
 %converted = fptoui fp128 %value to i64
 %wide = zext i64 %converted to i128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @scalar_integer_from_3_64_1(ptr %input,ptr %output,i64 %live) {
entry:
 %value = load fp128,ptr %input,align 1
 %converted = fptosi fp128 %value to i64
 %wide = zext i64 %converted to i128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @scalar_integer_from_3_65_0(ptr %input,ptr %output,i64 %live) {
entry:
 %value = load fp128,ptr %input,align 1
 %converted = fptoui fp128 %value to i65
 %wide = zext i65 %converted to i128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @scalar_integer_from_3_65_1(ptr %input,ptr %output,i64 %live) {
entry:
 %value = load fp128,ptr %input,align 1
 %converted = fptosi fp128 %value to i65
 %wide = zext i65 %converted to i128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @scalar_integer_from_3_80_0(ptr %input,ptr %output,i64 %live) {
entry:
 %value = load fp128,ptr %input,align 1
 %converted = fptoui fp128 %value to i80
 %wide = zext i80 %converted to i128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @scalar_integer_from_3_80_1(ptr %input,ptr %output,i64 %live) {
entry:
 %value = load fp128,ptr %input,align 1
 %converted = fptosi fp128 %value to i80
 %wide = zext i80 %converted to i128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @scalar_integer_from_3_113_0(ptr %input,ptr %output,i64 %live) {
entry:
 %value = load fp128,ptr %input,align 1
 %converted = fptoui fp128 %value to i113
 %wide = zext i113 %converted to i128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @scalar_integer_from_3_113_1(ptr %input,ptr %output,i64 %live) {
entry:
 %value = load fp128,ptr %input,align 1
 %converted = fptosi fp128 %value to i113
 %wide = zext i113 %converted to i128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @scalar_integer_from_3_127_0(ptr %input,ptr %output,i64 %live) {
entry:
 %value = load fp128,ptr %input,align 1
 %converted = fptoui fp128 %value to i127
 %wide = zext i127 %converted to i128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @scalar_integer_from_3_127_1(ptr %input,ptr %output,i64 %live) {
entry:
 %value = load fp128,ptr %input,align 1
 %converted = fptosi fp128 %value to i127
 %wide = zext i127 %converted to i128
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @scalar_integer_from_3_128_0(ptr %input,ptr %output,i64 %live) {
entry:
 %value = load fp128,ptr %input,align 1
 %converted = fptoui fp128 %value to i128
 %wide = add i128 %converted,0
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @scalar_integer_from_3_128_1(ptr %input,ptr %output,i64 %live) {
entry:
 %value = load fp128,ptr %input,align 1
 %converted = fptosi fp128 %value to i128
 %wide = add i128 %converted,0
 %probe = call i64 @scalar_integer_clobber(i64 %live)
 store i128 %wide,ptr %output,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
