target triple = "x86_64-unknown-linux-gnu"
target datalayout = "e-i128:128-f80:128"
declare i64 @scalar_sqrt_clobber(i64)
declare float @llvm.sqrt.f32(float)
define i64 @scalar_sqrt_32_sqrt(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {
entry:
 %a = load float,ptr %left,align 1
 %b = load float,ptr %right,align 1
 %c = load float,ptr %third,align 1
 %r = call float @llvm.sqrt.f32(float %a)
 %probe = call i64 @scalar_sqrt_clobber(i64 %live)
 store float %r,ptr %output,align 1
 ret i64 %probe
}
declare double @llvm.sqrt.f64(double)
define i64 @scalar_sqrt_64_sqrt(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {
entry:
 %a = load double,ptr %left,align 1
 %b = load double,ptr %right,align 1
 %c = load double,ptr %third,align 1
 %r = call double @llvm.sqrt.f64(double %a)
 %probe = call i64 @scalar_sqrt_clobber(i64 %live)
 store double %r,ptr %output,align 1
 ret i64 %probe
}
