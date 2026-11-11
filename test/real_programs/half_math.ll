target triple = "x86_64-unknown-linux-gnu"
declare i64 @half_math_clobber(i64)
declare half @llvm.trunc.f16(half)
define i64 @half_math_trunc(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {
entry:
 %a = load half,ptr %left,align 1
 %b = load half,ptr %right,align 1
 %c = load half,ptr %third,align 1
 %r = call half @llvm.trunc.f16(half %a)
 %probe = call i64 @half_math_clobber(i64 %live)
 store half %r,ptr %output,align 1
 ret i64 %probe
}
declare half @llvm.round.f16(half)
define i64 @half_math_round(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {
entry:
 %a = load half,ptr %left,align 1
 %b = load half,ptr %right,align 1
 %c = load half,ptr %third,align 1
 %r = call half @llvm.round.f16(half %a)
 %probe = call i64 @half_math_clobber(i64 %live)
 store half %r,ptr %output,align 1
 ret i64 %probe
}
declare half @llvm.ceil.f16(half)
define i64 @half_math_ceil(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {
entry:
 %a = load half,ptr %left,align 1
 %b = load half,ptr %right,align 1
 %c = load half,ptr %third,align 1
 %r = call half @llvm.ceil.f16(half %a)
 %probe = call i64 @half_math_clobber(i64 %live)
 store half %r,ptr %output,align 1
 ret i64 %probe
}
declare half @llvm.floor.f16(half)
define i64 @half_math_floor(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {
entry:
 %a = load half,ptr %left,align 1
 %b = load half,ptr %right,align 1
 %c = load half,ptr %third,align 1
 %r = call half @llvm.floor.f16(half %a)
 %probe = call i64 @half_math_clobber(i64 %live)
 store half %r,ptr %output,align 1
 ret i64 %probe
}
declare half @llvm.log10.f16(half)
define i64 @half_math_log10(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {
entry:
 %a = load half,ptr %left,align 1
 %b = load half,ptr %right,align 1
 %c = load half,ptr %third,align 1
 %r = call half @llvm.log10.f16(half %a)
 %probe = call i64 @half_math_clobber(i64 %live)
 store half %r,ptr %output,align 1
 ret i64 %probe
}
declare half @llvm.log2.f16(half)
define i64 @half_math_log2(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {
entry:
 %a = load half,ptr %left,align 1
 %b = load half,ptr %right,align 1
 %c = load half,ptr %third,align 1
 %r = call half @llvm.log2.f16(half %a)
 %probe = call i64 @half_math_clobber(i64 %live)
 store half %r,ptr %output,align 1
 ret i64 %probe
}
declare half @llvm.log.f16(half)
define i64 @half_math_log(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {
entry:
 %a = load half,ptr %left,align 1
 %b = load half,ptr %right,align 1
 %c = load half,ptr %third,align 1
 %r = call half @llvm.log.f16(half %a)
 %probe = call i64 @half_math_clobber(i64 %live)
 store half %r,ptr %output,align 1
 ret i64 %probe
}
declare half @llvm.exp2.f16(half)
define i64 @half_math_exp2(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {
entry:
 %a = load half,ptr %left,align 1
 %b = load half,ptr %right,align 1
 %c = load half,ptr %third,align 1
 %r = call half @llvm.exp2.f16(half %a)
 %probe = call i64 @half_math_clobber(i64 %live)
 store half %r,ptr %output,align 1
 ret i64 %probe
}
declare half @llvm.exp.f16(half)
define i64 @half_math_exp(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {
entry:
 %a = load half,ptr %left,align 1
 %b = load half,ptr %right,align 1
 %c = load half,ptr %third,align 1
 %r = call half @llvm.exp.f16(half %a)
 %probe = call i64 @half_math_clobber(i64 %live)
 store half %r,ptr %output,align 1
 ret i64 %probe
}
declare half @llvm.tan.f16(half)
define i64 @half_math_tan(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {
entry:
 %a = load half,ptr %left,align 1
 %b = load half,ptr %right,align 1
 %c = load half,ptr %third,align 1
 %r = call half @llvm.tan.f16(half %a)
 %probe = call i64 @half_math_clobber(i64 %live)
 store half %r,ptr %output,align 1
 ret i64 %probe
}
declare half @llvm.cos.f16(half)
define i64 @half_math_cos(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {
entry:
 %a = load half,ptr %left,align 1
 %b = load half,ptr %right,align 1
 %c = load half,ptr %third,align 1
 %r = call half @llvm.cos.f16(half %a)
 %probe = call i64 @half_math_clobber(i64 %live)
 store half %r,ptr %output,align 1
 ret i64 %probe
}
declare half @llvm.sin.f16(half)
define i64 @half_math_sin(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {
entry:
 %a = load half,ptr %left,align 1
 %b = load half,ptr %right,align 1
 %c = load half,ptr %third,align 1
 %r = call half @llvm.sin.f16(half %a)
 %probe = call i64 @half_math_clobber(i64 %live)
 store half %r,ptr %output,align 1
 ret i64 %probe
}
declare half @llvm.sqrt.f16(half)
define i64 @half_math_sqrt(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {
entry:
 %a = load half,ptr %left,align 1
 %b = load half,ptr %right,align 1
 %c = load half,ptr %third,align 1
 %r = call half @llvm.sqrt.f16(half %a)
 %probe = call i64 @half_math_clobber(i64 %live)
 store half %r,ptr %output,align 1
 ret i64 %probe
}
declare half @llvm.fma.f16(half,half,half)
define i64 @half_math_fma(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {
entry:
 %a = load half,ptr %left,align 1
 %b = load half,ptr %right,align 1
 %c = load half,ptr %third,align 1
 %r = call half @llvm.fma.f16(half %a,half %b,half %c)
 %probe = call i64 @half_math_clobber(i64 %live)
 store half %r,ptr %output,align 1
 ret i64 %probe
}
