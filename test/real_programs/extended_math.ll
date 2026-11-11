target triple = "x86_64-unknown-linux-gnu"
target datalayout = "e-i128:128-f80:128"
declare i64 @extended_math_clobber(i64)
declare x86_fp80 @llvm.trunc.f80(x86_fp80)
define i64 @extended_math_80_trunc(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {
entry:
 %a = load x86_fp80,ptr %left,align 1
 %b = load x86_fp80,ptr %right,align 1
 %c = load x86_fp80,ptr %third,align 1
 %r = call x86_fp80 @llvm.trunc.f80(x86_fp80 %a)
 %probe = call i64 @extended_math_clobber(i64 %live)
 store x86_fp80 %r,ptr %output,align 1
 ret i64 %probe
}
declare x86_fp80 @llvm.round.f80(x86_fp80)
define i64 @extended_math_80_round(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {
entry:
 %a = load x86_fp80,ptr %left,align 1
 %b = load x86_fp80,ptr %right,align 1
 %c = load x86_fp80,ptr %third,align 1
 %r = call x86_fp80 @llvm.round.f80(x86_fp80 %a)
 %probe = call i64 @extended_math_clobber(i64 %live)
 store x86_fp80 %r,ptr %output,align 1
 ret i64 %probe
}
declare x86_fp80 @llvm.ceil.f80(x86_fp80)
define i64 @extended_math_80_ceil(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {
entry:
 %a = load x86_fp80,ptr %left,align 1
 %b = load x86_fp80,ptr %right,align 1
 %c = load x86_fp80,ptr %third,align 1
 %r = call x86_fp80 @llvm.ceil.f80(x86_fp80 %a)
 %probe = call i64 @extended_math_clobber(i64 %live)
 store x86_fp80 %r,ptr %output,align 1
 ret i64 %probe
}
declare x86_fp80 @llvm.floor.f80(x86_fp80)
define i64 @extended_math_80_floor(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {
entry:
 %a = load x86_fp80,ptr %left,align 1
 %b = load x86_fp80,ptr %right,align 1
 %c = load x86_fp80,ptr %third,align 1
 %r = call x86_fp80 @llvm.floor.f80(x86_fp80 %a)
 %probe = call i64 @extended_math_clobber(i64 %live)
 store x86_fp80 %r,ptr %output,align 1
 ret i64 %probe
}
declare x86_fp80 @llvm.log10.f80(x86_fp80)
define i64 @extended_math_80_log10(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {
entry:
 %a = load x86_fp80,ptr %left,align 1
 %b = load x86_fp80,ptr %right,align 1
 %c = load x86_fp80,ptr %third,align 1
 %r = call x86_fp80 @llvm.log10.f80(x86_fp80 %a)
 %probe = call i64 @extended_math_clobber(i64 %live)
 store x86_fp80 %r,ptr %output,align 1
 ret i64 %probe
}
declare x86_fp80 @llvm.log2.f80(x86_fp80)
define i64 @extended_math_80_log2(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {
entry:
 %a = load x86_fp80,ptr %left,align 1
 %b = load x86_fp80,ptr %right,align 1
 %c = load x86_fp80,ptr %third,align 1
 %r = call x86_fp80 @llvm.log2.f80(x86_fp80 %a)
 %probe = call i64 @extended_math_clobber(i64 %live)
 store x86_fp80 %r,ptr %output,align 1
 ret i64 %probe
}
declare x86_fp80 @llvm.log.f80(x86_fp80)
define i64 @extended_math_80_log(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {
entry:
 %a = load x86_fp80,ptr %left,align 1
 %b = load x86_fp80,ptr %right,align 1
 %c = load x86_fp80,ptr %third,align 1
 %r = call x86_fp80 @llvm.log.f80(x86_fp80 %a)
 %probe = call i64 @extended_math_clobber(i64 %live)
 store x86_fp80 %r,ptr %output,align 1
 ret i64 %probe
}
declare x86_fp80 @llvm.exp2.f80(x86_fp80)
define i64 @extended_math_80_exp2(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {
entry:
 %a = load x86_fp80,ptr %left,align 1
 %b = load x86_fp80,ptr %right,align 1
 %c = load x86_fp80,ptr %third,align 1
 %r = call x86_fp80 @llvm.exp2.f80(x86_fp80 %a)
 %probe = call i64 @extended_math_clobber(i64 %live)
 store x86_fp80 %r,ptr %output,align 1
 ret i64 %probe
}
declare x86_fp80 @llvm.exp.f80(x86_fp80)
define i64 @extended_math_80_exp(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {
entry:
 %a = load x86_fp80,ptr %left,align 1
 %b = load x86_fp80,ptr %right,align 1
 %c = load x86_fp80,ptr %third,align 1
 %r = call x86_fp80 @llvm.exp.f80(x86_fp80 %a)
 %probe = call i64 @extended_math_clobber(i64 %live)
 store x86_fp80 %r,ptr %output,align 1
 ret i64 %probe
}
declare x86_fp80 @llvm.tan.f80(x86_fp80)
define i64 @extended_math_80_tan(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {
entry:
 %a = load x86_fp80,ptr %left,align 1
 %b = load x86_fp80,ptr %right,align 1
 %c = load x86_fp80,ptr %third,align 1
 %r = call x86_fp80 @llvm.tan.f80(x86_fp80 %a)
 %probe = call i64 @extended_math_clobber(i64 %live)
 store x86_fp80 %r,ptr %output,align 1
 ret i64 %probe
}
declare x86_fp80 @llvm.cos.f80(x86_fp80)
define i64 @extended_math_80_cos(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {
entry:
 %a = load x86_fp80,ptr %left,align 1
 %b = load x86_fp80,ptr %right,align 1
 %c = load x86_fp80,ptr %third,align 1
 %r = call x86_fp80 @llvm.cos.f80(x86_fp80 %a)
 %probe = call i64 @extended_math_clobber(i64 %live)
 store x86_fp80 %r,ptr %output,align 1
 ret i64 %probe
}
declare x86_fp80 @llvm.sin.f80(x86_fp80)
define i64 @extended_math_80_sin(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {
entry:
 %a = load x86_fp80,ptr %left,align 1
 %b = load x86_fp80,ptr %right,align 1
 %c = load x86_fp80,ptr %third,align 1
 %r = call x86_fp80 @llvm.sin.f80(x86_fp80 %a)
 %probe = call i64 @extended_math_clobber(i64 %live)
 store x86_fp80 %r,ptr %output,align 1
 ret i64 %probe
}
declare x86_fp80 @llvm.fma.f80(x86_fp80,x86_fp80,x86_fp80)
define i64 @extended_math_80_fma(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {
entry:
 %a = load x86_fp80,ptr %left,align 1
 %b = load x86_fp80,ptr %right,align 1
 %c = load x86_fp80,ptr %third,align 1
 %r = call x86_fp80 @llvm.fma.f80(x86_fp80 %a,x86_fp80 %b,x86_fp80 %c)
 %probe = call i64 @extended_math_clobber(i64 %live)
 store x86_fp80 %r,ptr %output,align 1
 ret i64 %probe
}
declare fp128 @llvm.trunc.f128(fp128)
define i64 @extended_math_128_trunc(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {
entry:
 %a = load fp128,ptr %left,align 1
 %b = load fp128,ptr %right,align 1
 %c = load fp128,ptr %third,align 1
 %r = call fp128 @llvm.trunc.f128(fp128 %a)
 %probe = call i64 @extended_math_clobber(i64 %live)
 store fp128 %r,ptr %output,align 1
 ret i64 %probe
}
declare fp128 @llvm.round.f128(fp128)
define i64 @extended_math_128_round(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {
entry:
 %a = load fp128,ptr %left,align 1
 %b = load fp128,ptr %right,align 1
 %c = load fp128,ptr %third,align 1
 %r = call fp128 @llvm.round.f128(fp128 %a)
 %probe = call i64 @extended_math_clobber(i64 %live)
 store fp128 %r,ptr %output,align 1
 ret i64 %probe
}
declare fp128 @llvm.ceil.f128(fp128)
define i64 @extended_math_128_ceil(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {
entry:
 %a = load fp128,ptr %left,align 1
 %b = load fp128,ptr %right,align 1
 %c = load fp128,ptr %third,align 1
 %r = call fp128 @llvm.ceil.f128(fp128 %a)
 %probe = call i64 @extended_math_clobber(i64 %live)
 store fp128 %r,ptr %output,align 1
 ret i64 %probe
}
declare fp128 @llvm.floor.f128(fp128)
define i64 @extended_math_128_floor(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {
entry:
 %a = load fp128,ptr %left,align 1
 %b = load fp128,ptr %right,align 1
 %c = load fp128,ptr %third,align 1
 %r = call fp128 @llvm.floor.f128(fp128 %a)
 %probe = call i64 @extended_math_clobber(i64 %live)
 store fp128 %r,ptr %output,align 1
 ret i64 %probe
}
declare fp128 @llvm.log10.f128(fp128)
define i64 @extended_math_128_log10(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {
entry:
 %a = load fp128,ptr %left,align 1
 %b = load fp128,ptr %right,align 1
 %c = load fp128,ptr %third,align 1
 %r = call fp128 @llvm.log10.f128(fp128 %a)
 %probe = call i64 @extended_math_clobber(i64 %live)
 store fp128 %r,ptr %output,align 1
 ret i64 %probe
}
declare fp128 @llvm.log2.f128(fp128)
define i64 @extended_math_128_log2(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {
entry:
 %a = load fp128,ptr %left,align 1
 %b = load fp128,ptr %right,align 1
 %c = load fp128,ptr %third,align 1
 %r = call fp128 @llvm.log2.f128(fp128 %a)
 %probe = call i64 @extended_math_clobber(i64 %live)
 store fp128 %r,ptr %output,align 1
 ret i64 %probe
}
declare fp128 @llvm.log.f128(fp128)
define i64 @extended_math_128_log(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {
entry:
 %a = load fp128,ptr %left,align 1
 %b = load fp128,ptr %right,align 1
 %c = load fp128,ptr %third,align 1
 %r = call fp128 @llvm.log.f128(fp128 %a)
 %probe = call i64 @extended_math_clobber(i64 %live)
 store fp128 %r,ptr %output,align 1
 ret i64 %probe
}
declare fp128 @llvm.exp2.f128(fp128)
define i64 @extended_math_128_exp2(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {
entry:
 %a = load fp128,ptr %left,align 1
 %b = load fp128,ptr %right,align 1
 %c = load fp128,ptr %third,align 1
 %r = call fp128 @llvm.exp2.f128(fp128 %a)
 %probe = call i64 @extended_math_clobber(i64 %live)
 store fp128 %r,ptr %output,align 1
 ret i64 %probe
}
declare fp128 @llvm.exp.f128(fp128)
define i64 @extended_math_128_exp(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {
entry:
 %a = load fp128,ptr %left,align 1
 %b = load fp128,ptr %right,align 1
 %c = load fp128,ptr %third,align 1
 %r = call fp128 @llvm.exp.f128(fp128 %a)
 %probe = call i64 @extended_math_clobber(i64 %live)
 store fp128 %r,ptr %output,align 1
 ret i64 %probe
}
declare fp128 @llvm.tan.f128(fp128)
define i64 @extended_math_128_tan(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {
entry:
 %a = load fp128,ptr %left,align 1
 %b = load fp128,ptr %right,align 1
 %c = load fp128,ptr %third,align 1
 %r = call fp128 @llvm.tan.f128(fp128 %a)
 %probe = call i64 @extended_math_clobber(i64 %live)
 store fp128 %r,ptr %output,align 1
 ret i64 %probe
}
declare fp128 @llvm.cos.f128(fp128)
define i64 @extended_math_128_cos(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {
entry:
 %a = load fp128,ptr %left,align 1
 %b = load fp128,ptr %right,align 1
 %c = load fp128,ptr %third,align 1
 %r = call fp128 @llvm.cos.f128(fp128 %a)
 %probe = call i64 @extended_math_clobber(i64 %live)
 store fp128 %r,ptr %output,align 1
 ret i64 %probe
}
declare fp128 @llvm.sin.f128(fp128)
define i64 @extended_math_128_sin(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {
entry:
 %a = load fp128,ptr %left,align 1
 %b = load fp128,ptr %right,align 1
 %c = load fp128,ptr %third,align 1
 %r = call fp128 @llvm.sin.f128(fp128 %a)
 %probe = call i64 @extended_math_clobber(i64 %live)
 store fp128 %r,ptr %output,align 1
 ret i64 %probe
}
declare fp128 @llvm.sqrt.f128(fp128)
define i64 @extended_math_128_sqrt(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {
entry:
 %a = load fp128,ptr %left,align 1
 %b = load fp128,ptr %right,align 1
 %c = load fp128,ptr %third,align 1
 %r = call fp128 @llvm.sqrt.f128(fp128 %a)
 %probe = call i64 @extended_math_clobber(i64 %live)
 store fp128 %r,ptr %output,align 1
 ret i64 %probe
}
declare fp128 @llvm.fma.f128(fp128,fp128,fp128)
define i64 @extended_math_128_fma(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {
entry:
 %a = load fp128,ptr %left,align 1
 %b = load fp128,ptr %right,align 1
 %c = load fp128,ptr %third,align 1
 %r = call fp128 @llvm.fma.f128(fp128 %a,fp128 %b,fp128 %c)
 %probe = call i64 @extended_math_clobber(i64 %live)
 store fp128 %r,ptr %output,align 1
 ret i64 %probe
}
declare float @llvm.trunc.f32(float)
define i64 @extended_math_32_trunc(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {
entry:
 %a = load float,ptr %left,align 1
 %b = load float,ptr %right,align 1
 %c = load float,ptr %third,align 1
 %r = call float @llvm.trunc.f32(float %a)
 %probe = call i64 @extended_math_clobber(i64 %live)
 store float %r,ptr %output,align 1
 ret i64 %probe
}
declare float @llvm.round.f32(float)
define i64 @extended_math_32_round(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {
entry:
 %a = load float,ptr %left,align 1
 %b = load float,ptr %right,align 1
 %c = load float,ptr %third,align 1
 %r = call float @llvm.round.f32(float %a)
 %probe = call i64 @extended_math_clobber(i64 %live)
 store float %r,ptr %output,align 1
 ret i64 %probe
}
declare float @llvm.ceil.f32(float)
define i64 @extended_math_32_ceil(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {
entry:
 %a = load float,ptr %left,align 1
 %b = load float,ptr %right,align 1
 %c = load float,ptr %third,align 1
 %r = call float @llvm.ceil.f32(float %a)
 %probe = call i64 @extended_math_clobber(i64 %live)
 store float %r,ptr %output,align 1
 ret i64 %probe
}
declare float @llvm.floor.f32(float)
define i64 @extended_math_32_floor(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {
entry:
 %a = load float,ptr %left,align 1
 %b = load float,ptr %right,align 1
 %c = load float,ptr %third,align 1
 %r = call float @llvm.floor.f32(float %a)
 %probe = call i64 @extended_math_clobber(i64 %live)
 store float %r,ptr %output,align 1
 ret i64 %probe
}
declare float @llvm.log10.f32(float)
define i64 @extended_math_32_log10(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {
entry:
 %a = load float,ptr %left,align 1
 %b = load float,ptr %right,align 1
 %c = load float,ptr %third,align 1
 %r = call float @llvm.log10.f32(float %a)
 %probe = call i64 @extended_math_clobber(i64 %live)
 store float %r,ptr %output,align 1
 ret i64 %probe
}
declare float @llvm.log2.f32(float)
define i64 @extended_math_32_log2(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {
entry:
 %a = load float,ptr %left,align 1
 %b = load float,ptr %right,align 1
 %c = load float,ptr %third,align 1
 %r = call float @llvm.log2.f32(float %a)
 %probe = call i64 @extended_math_clobber(i64 %live)
 store float %r,ptr %output,align 1
 ret i64 %probe
}
declare float @llvm.log.f32(float)
define i64 @extended_math_32_log(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {
entry:
 %a = load float,ptr %left,align 1
 %b = load float,ptr %right,align 1
 %c = load float,ptr %third,align 1
 %r = call float @llvm.log.f32(float %a)
 %probe = call i64 @extended_math_clobber(i64 %live)
 store float %r,ptr %output,align 1
 ret i64 %probe
}
declare float @llvm.exp2.f32(float)
define i64 @extended_math_32_exp2(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {
entry:
 %a = load float,ptr %left,align 1
 %b = load float,ptr %right,align 1
 %c = load float,ptr %third,align 1
 %r = call float @llvm.exp2.f32(float %a)
 %probe = call i64 @extended_math_clobber(i64 %live)
 store float %r,ptr %output,align 1
 ret i64 %probe
}
declare float @llvm.exp.f32(float)
define i64 @extended_math_32_exp(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {
entry:
 %a = load float,ptr %left,align 1
 %b = load float,ptr %right,align 1
 %c = load float,ptr %third,align 1
 %r = call float @llvm.exp.f32(float %a)
 %probe = call i64 @extended_math_clobber(i64 %live)
 store float %r,ptr %output,align 1
 ret i64 %probe
}
declare float @llvm.tan.f32(float)
define i64 @extended_math_32_tan(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {
entry:
 %a = load float,ptr %left,align 1
 %b = load float,ptr %right,align 1
 %c = load float,ptr %third,align 1
 %r = call float @llvm.tan.f32(float %a)
 %probe = call i64 @extended_math_clobber(i64 %live)
 store float %r,ptr %output,align 1
 ret i64 %probe
}
declare float @llvm.cos.f32(float)
define i64 @extended_math_32_cos(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {
entry:
 %a = load float,ptr %left,align 1
 %b = load float,ptr %right,align 1
 %c = load float,ptr %third,align 1
 %r = call float @llvm.cos.f32(float %a)
 %probe = call i64 @extended_math_clobber(i64 %live)
 store float %r,ptr %output,align 1
 ret i64 %probe
}
declare float @llvm.sin.f32(float)
define i64 @extended_math_32_sin(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {
entry:
 %a = load float,ptr %left,align 1
 %b = load float,ptr %right,align 1
 %c = load float,ptr %third,align 1
 %r = call float @llvm.sin.f32(float %a)
 %probe = call i64 @extended_math_clobber(i64 %live)
 store float %r,ptr %output,align 1
 ret i64 %probe
}
declare float @llvm.fma.f32(float,float,float)
define i64 @extended_math_32_fma(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {
entry:
 %a = load float,ptr %left,align 1
 %b = load float,ptr %right,align 1
 %c = load float,ptr %third,align 1
 %r = call float @llvm.fma.f32(float %a,float %b,float %c)
 %probe = call i64 @extended_math_clobber(i64 %live)
 store float %r,ptr %output,align 1
 ret i64 %probe
}
declare double @llvm.trunc.f64(double)
define i64 @extended_math_64_trunc(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {
entry:
 %a = load double,ptr %left,align 1
 %b = load double,ptr %right,align 1
 %c = load double,ptr %third,align 1
 %r = call double @llvm.trunc.f64(double %a)
 %probe = call i64 @extended_math_clobber(i64 %live)
 store double %r,ptr %output,align 1
 ret i64 %probe
}
declare double @llvm.round.f64(double)
define i64 @extended_math_64_round(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {
entry:
 %a = load double,ptr %left,align 1
 %b = load double,ptr %right,align 1
 %c = load double,ptr %third,align 1
 %r = call double @llvm.round.f64(double %a)
 %probe = call i64 @extended_math_clobber(i64 %live)
 store double %r,ptr %output,align 1
 ret i64 %probe
}
declare double @llvm.ceil.f64(double)
define i64 @extended_math_64_ceil(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {
entry:
 %a = load double,ptr %left,align 1
 %b = load double,ptr %right,align 1
 %c = load double,ptr %third,align 1
 %r = call double @llvm.ceil.f64(double %a)
 %probe = call i64 @extended_math_clobber(i64 %live)
 store double %r,ptr %output,align 1
 ret i64 %probe
}
declare double @llvm.floor.f64(double)
define i64 @extended_math_64_floor(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {
entry:
 %a = load double,ptr %left,align 1
 %b = load double,ptr %right,align 1
 %c = load double,ptr %third,align 1
 %r = call double @llvm.floor.f64(double %a)
 %probe = call i64 @extended_math_clobber(i64 %live)
 store double %r,ptr %output,align 1
 ret i64 %probe
}
declare double @llvm.log10.f64(double)
define i64 @extended_math_64_log10(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {
entry:
 %a = load double,ptr %left,align 1
 %b = load double,ptr %right,align 1
 %c = load double,ptr %third,align 1
 %r = call double @llvm.log10.f64(double %a)
 %probe = call i64 @extended_math_clobber(i64 %live)
 store double %r,ptr %output,align 1
 ret i64 %probe
}
declare double @llvm.log2.f64(double)
define i64 @extended_math_64_log2(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {
entry:
 %a = load double,ptr %left,align 1
 %b = load double,ptr %right,align 1
 %c = load double,ptr %third,align 1
 %r = call double @llvm.log2.f64(double %a)
 %probe = call i64 @extended_math_clobber(i64 %live)
 store double %r,ptr %output,align 1
 ret i64 %probe
}
declare double @llvm.log.f64(double)
define i64 @extended_math_64_log(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {
entry:
 %a = load double,ptr %left,align 1
 %b = load double,ptr %right,align 1
 %c = load double,ptr %third,align 1
 %r = call double @llvm.log.f64(double %a)
 %probe = call i64 @extended_math_clobber(i64 %live)
 store double %r,ptr %output,align 1
 ret i64 %probe
}
declare double @llvm.exp2.f64(double)
define i64 @extended_math_64_exp2(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {
entry:
 %a = load double,ptr %left,align 1
 %b = load double,ptr %right,align 1
 %c = load double,ptr %third,align 1
 %r = call double @llvm.exp2.f64(double %a)
 %probe = call i64 @extended_math_clobber(i64 %live)
 store double %r,ptr %output,align 1
 ret i64 %probe
}
declare double @llvm.exp.f64(double)
define i64 @extended_math_64_exp(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {
entry:
 %a = load double,ptr %left,align 1
 %b = load double,ptr %right,align 1
 %c = load double,ptr %third,align 1
 %r = call double @llvm.exp.f64(double %a)
 %probe = call i64 @extended_math_clobber(i64 %live)
 store double %r,ptr %output,align 1
 ret i64 %probe
}
declare double @llvm.tan.f64(double)
define i64 @extended_math_64_tan(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {
entry:
 %a = load double,ptr %left,align 1
 %b = load double,ptr %right,align 1
 %c = load double,ptr %third,align 1
 %r = call double @llvm.tan.f64(double %a)
 %probe = call i64 @extended_math_clobber(i64 %live)
 store double %r,ptr %output,align 1
 ret i64 %probe
}
declare double @llvm.cos.f64(double)
define i64 @extended_math_64_cos(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {
entry:
 %a = load double,ptr %left,align 1
 %b = load double,ptr %right,align 1
 %c = load double,ptr %third,align 1
 %r = call double @llvm.cos.f64(double %a)
 %probe = call i64 @extended_math_clobber(i64 %live)
 store double %r,ptr %output,align 1
 ret i64 %probe
}
declare double @llvm.sin.f64(double)
define i64 @extended_math_64_sin(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {
entry:
 %a = load double,ptr %left,align 1
 %b = load double,ptr %right,align 1
 %c = load double,ptr %third,align 1
 %r = call double @llvm.sin.f64(double %a)
 %probe = call i64 @extended_math_clobber(i64 %live)
 store double %r,ptr %output,align 1
 ret i64 %probe
}
declare double @llvm.fma.f64(double,double,double)
define i64 @extended_math_64_fma(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {
entry:
 %a = load double,ptr %left,align 1
 %b = load double,ptr %right,align 1
 %c = load double,ptr %third,align 1
 %r = call double @llvm.fma.f64(double %a,double %b,double %c)
 %probe = call i64 @extended_math_clobber(i64 %live)
 store double %r,ptr %output,align 1
 ret i64 %probe
}
