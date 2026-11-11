target triple = "x86_64-unknown-linux-gnu"
target datalayout = "e-i128:128-f80:128"
declare i64 @floating_sign_clobber(i64)
declare x86_fp80 @llvm.fabs.f80(x86_fp80)
declare x86_fp80 @llvm.copysign.f80(x86_fp80,x86_fp80)
define i64 @floating_sign_80_neg(ptr %left,ptr %right,ptr %output,i64 %live) {
entry:
 %x = load x86_fp80,ptr %left,align 1
 %y = load x86_fp80,ptr %right,align 1
 %z = fneg x86_fp80 %x
 %bits = bitcast x86_fp80 %z to i80
 %low = trunc i80 %bits to i64
 %probe = call i64 @floating_sign_clobber(i64 %live)
 store x86_fp80 %z,ptr %output,align 1
 %answer = xor i64 %low,%probe
 ret i64 %answer
}
define i64 @floating_sign_80_abs(ptr %left,ptr %right,ptr %output,i64 %live) {
entry:
 %x = load x86_fp80,ptr %left,align 1
 %y = load x86_fp80,ptr %right,align 1
 %z = call x86_fp80 @llvm.fabs.f80(x86_fp80 %x)
 %bits = bitcast x86_fp80 %z to i80
 %low = trunc i80 %bits to i64
 %probe = call i64 @floating_sign_clobber(i64 %live)
 store x86_fp80 %z,ptr %output,align 1
 %answer = xor i64 %low,%probe
 ret i64 %answer
}
define i64 @floating_sign_80_copy(ptr %left,ptr %right,ptr %output,i64 %live) {
entry:
 %x = load x86_fp80,ptr %left,align 1
 %y = load x86_fp80,ptr %right,align 1
 %z = call x86_fp80 @llvm.copysign.f80(x86_fp80 %x,x86_fp80 %y)
 %bits = bitcast x86_fp80 %z to i80
 %low = trunc i80 %bits to i64
 %probe = call i64 @floating_sign_clobber(i64 %live)
 store x86_fp80 %z,ptr %output,align 1
 %answer = xor i64 %low,%probe
 ret i64 %answer
}
declare fp128 @llvm.fabs.f128(fp128)
declare fp128 @llvm.copysign.f128(fp128,fp128)
define i64 @floating_sign_128_neg(ptr %left,ptr %right,ptr %output,i64 %live) {
entry:
 %x = load fp128,ptr %left,align 1
 %y = load fp128,ptr %right,align 1
 %z = fneg fp128 %x
 %bits = bitcast fp128 %z to i128
 %low = trunc i128 %bits to i64
 %probe = call i64 @floating_sign_clobber(i64 %live)
 store fp128 %z,ptr %output,align 1
 %answer = xor i64 %low,%probe
 ret i64 %answer
}
define i64 @floating_sign_128_abs(ptr %left,ptr %right,ptr %output,i64 %live) {
entry:
 %x = load fp128,ptr %left,align 1
 %y = load fp128,ptr %right,align 1
 %z = call fp128 @llvm.fabs.f128(fp128 %x)
 %bits = bitcast fp128 %z to i128
 %low = trunc i128 %bits to i64
 %probe = call i64 @floating_sign_clobber(i64 %live)
 store fp128 %z,ptr %output,align 1
 %answer = xor i64 %low,%probe
 ret i64 %answer
}
define i64 @floating_sign_128_copy(ptr %left,ptr %right,ptr %output,i64 %live) {
entry:
 %x = load fp128,ptr %left,align 1
 %y = load fp128,ptr %right,align 1
 %z = call fp128 @llvm.copysign.f128(fp128 %x,fp128 %y)
 %bits = bitcast fp128 %z to i128
 %low = trunc i128 %bits to i64
 %probe = call i64 @floating_sign_clobber(i64 %live)
 store fp128 %z,ptr %output,align 1
 %answer = xor i64 %low,%probe
 ret i64 %answer
}
