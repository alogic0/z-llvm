target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"
@packed_float_extract_global_0 = global <2 x float> zeroinitializer,align 8
define i64 @packed_float_extract_body_0(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out) noinline {
entry:
 %input_value = load <2 x float>,ptr %input,align 1
 store <2 x float> %input_value,ptr @packed_float_extract_global_0,align 8
 %again = load <2 x float>,ptr @packed_float_extract_global_0,align 8
 %lo = extractelement <2 x float> %again,i32 0
 %hi = extractelement <2 x float> %again,i32 1
 %out_lo_bits = bitcast float %lo to i32
 %out_hi_bits = bitcast float %hi to i32
 store i32 %out_lo_bits,ptr %out,align 1
 %out_hi = getelementptr i8,ptr %out,i64 4
 store i32 %out_hi_bits,ptr %out_hi,align 1
 %swap0 = insertelement <2 x float> poison,float %hi,i32 0
 %swap1 = insertelement <2 x float> %swap0,float %lo,i32 1
 store <2 x float> %swap1,ptr @packed_float_extract_global_0,align 8
 %lobits = bitcast float %lo to i32
 %hibits = bitcast float %hi to i32
 %lowide = zext i32 %lobits to i64
 %hiwide = zext i32 %hibits to i64
 %shifted = shl i64 %hiwide,32
 %raw = or i64 %lowide,%shifted
 %m0 = mul i64 %raw,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @packed_float_extract_probe_0(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %data = getelementptr i8,ptr %input,i64 48
 %answer = call i64 @packed_float_extract_body_0(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %data,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 8
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 16
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 24
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
@packed_float_extract_global_1 = global <2 x float> zeroinitializer,align 8
define fastcc i64 @packed_float_extract_body_1(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out) noinline {
entry:
 %input_value = load <2 x float>,ptr %input,align 1
 store <2 x float> %input_value,ptr @packed_float_extract_global_1,align 8
 %again = load <2 x float>,ptr @packed_float_extract_global_1,align 8
 %lo = extractelement <2 x float> %again,i32 0
 %hi = extractelement <2 x float> %again,i32 1
 %out_lo_bits = bitcast float %lo to i32
 %out_hi_bits = bitcast float %hi to i32
 store i32 %out_lo_bits,ptr %out,align 1
 %out_hi = getelementptr i8,ptr %out,i64 4
 store i32 %out_hi_bits,ptr %out_hi,align 1
 %swap0 = insertelement <2 x float> poison,float %hi,i32 0
 %swap1 = insertelement <2 x float> %swap0,float %lo,i32 1
 store <2 x float> %swap1,ptr @packed_float_extract_global_1,align 8
 %lobits = bitcast float %lo to i32
 %hibits = bitcast float %hi to i32
 %lowide = zext i32 %lobits to i64
 %hiwide = zext i32 %hibits to i64
 %shifted = shl i64 %hiwide,32
 %raw = or i64 %lowide,%shifted
 %m0 = mul i64 %raw,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @packed_float_extract_probe_1(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %data = getelementptr i8,ptr %input,i64 48
 %answer = call fastcc i64 @packed_float_extract_body_1(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %data,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 8
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 16
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 24
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
@packed_float_extract_global_2 = global <2 x float> zeroinitializer,align 8
define i64 @packed_float_extract_body_2(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out) noinline {
entry:
 %input_value = load <2 x float>,ptr %input,align 1
 store <2 x float> <float 0.000000e+00,float 1.000000e+00>,ptr @packed_float_extract_global_2,align 8
 %again = load <2 x float>,ptr @packed_float_extract_global_2,align 8
 %lo = extractelement <2 x float> %again,i32 0
 %hi = extractelement <2 x float> %again,i32 1
 %out_lo_bits = bitcast float %lo to i32
 %out_hi_bits = bitcast float %hi to i32
 store i32 %out_lo_bits,ptr %out,align 1
 %out_hi = getelementptr i8,ptr %out,i64 4
 store i32 %out_hi_bits,ptr %out_hi,align 1
 %swap0 = insertelement <2 x float> poison,float %hi,i32 0
 %swap1 = insertelement <2 x float> %swap0,float %lo,i32 1
 store <2 x float> %swap1,ptr @packed_float_extract_global_2,align 8
 %lobits = bitcast float %lo to i32
 %hibits = bitcast float %hi to i32
 %lowide = zext i32 %lobits to i64
 %hiwide = zext i32 %hibits to i64
 %shifted = shl i64 %hiwide,32
 %raw = or i64 %lowide,%shifted
 %m0 = mul i64 %raw,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @packed_float_extract_probe_2(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %data = getelementptr i8,ptr %input,i64 48
 %answer = call i64 @packed_float_extract_body_2(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %data,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 8
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 16
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 24
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
@packed_float_extract_global_3 = global <2 x float> zeroinitializer,align 8
define fastcc i64 @packed_float_extract_body_3(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out) noinline {
entry:
 %input_value = load <2 x float>,ptr %input,align 1
 store <2 x float> <float 0.000000e+00,float 1.000000e+00>,ptr @packed_float_extract_global_3,align 8
 %again = load <2 x float>,ptr @packed_float_extract_global_3,align 8
 %lo = extractelement <2 x float> %again,i32 0
 %hi = extractelement <2 x float> %again,i32 1
 %out_lo_bits = bitcast float %lo to i32
 %out_hi_bits = bitcast float %hi to i32
 store i32 %out_lo_bits,ptr %out,align 1
 %out_hi = getelementptr i8,ptr %out,i64 4
 store i32 %out_hi_bits,ptr %out_hi,align 1
 %swap0 = insertelement <2 x float> poison,float %hi,i32 0
 %swap1 = insertelement <2 x float> %swap0,float %lo,i32 1
 store <2 x float> %swap1,ptr @packed_float_extract_global_3,align 8
 %lobits = bitcast float %lo to i32
 %hibits = bitcast float %hi to i32
 %lowide = zext i32 %lobits to i64
 %hiwide = zext i32 %hibits to i64
 %shifted = shl i64 %hiwide,32
 %raw = or i64 %lowide,%shifted
 %m0 = mul i64 %raw,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @packed_float_extract_probe_3(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %data = getelementptr i8,ptr %input,i64 48
 %answer = call fastcc i64 @packed_float_extract_body_3(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %data,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 8
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 16
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 24
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
