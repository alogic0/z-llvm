target triple = "x86_64-unknown-linux-gnu"
target datalayout = "e-i128:128-f80:128"
declare i64 @extended80_arithmetic_clobber(i64)
declare x86_fp80 @llvm.sqrt.f80(x86_fp80)
define i64 @extended80_arithmetic_add_0(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {
entry:
 %a = load x86_fp80,ptr %left,align 1
 %b = load x86_fp80,ptr %right,align 1
 %r = fadd x86_fp80 %a,%b
 %probe = call i64 @extended80_arithmetic_clobber(i64 %live)
 store x86_fp80 %r,ptr %output,align 1
 ret i64 %probe
}
define i64 @extended80_arithmetic_add_1(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {
entry:
 %a = load x86_fp80,ptr %left,align 1
 %b = load x86_fp80,ptr %right,align 1
 %r = fadd x86_fp80 0xK3FFFC000000000000000,%b
 %probe = call i64 @extended80_arithmetic_clobber(i64 %live)
 store x86_fp80 %r,ptr %output,align 1
 ret i64 %probe
}
define i64 @extended80_arithmetic_add_2(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {
entry:
 %a = load x86_fp80,ptr %left,align 1
 %b = load x86_fp80,ptr %right,align 1
 %r = fadd x86_fp80 %a,0xK4000A000000000000000
 %probe = call i64 @extended80_arithmetic_clobber(i64 %live)
 store x86_fp80 %r,ptr %output,align 1
 ret i64 %probe
}
define i64 @extended80_arithmetic_sub_0(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {
entry:
 %a = load x86_fp80,ptr %left,align 1
 %b = load x86_fp80,ptr %right,align 1
 %r = fsub x86_fp80 %a,%b
 %probe = call i64 @extended80_arithmetic_clobber(i64 %live)
 store x86_fp80 %r,ptr %output,align 1
 ret i64 %probe
}
define i64 @extended80_arithmetic_sub_1(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {
entry:
 %a = load x86_fp80,ptr %left,align 1
 %b = load x86_fp80,ptr %right,align 1
 %r = fsub x86_fp80 0xK3FFFC000000000000000,%b
 %probe = call i64 @extended80_arithmetic_clobber(i64 %live)
 store x86_fp80 %r,ptr %output,align 1
 ret i64 %probe
}
define i64 @extended80_arithmetic_sub_2(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {
entry:
 %a = load x86_fp80,ptr %left,align 1
 %b = load x86_fp80,ptr %right,align 1
 %r = fsub x86_fp80 %a,0xK4000A000000000000000
 %probe = call i64 @extended80_arithmetic_clobber(i64 %live)
 store x86_fp80 %r,ptr %output,align 1
 ret i64 %probe
}
define i64 @extended80_arithmetic_mul_0(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {
entry:
 %a = load x86_fp80,ptr %left,align 1
 %b = load x86_fp80,ptr %right,align 1
 %r = fmul x86_fp80 %a,%b
 %probe = call i64 @extended80_arithmetic_clobber(i64 %live)
 store x86_fp80 %r,ptr %output,align 1
 ret i64 %probe
}
define i64 @extended80_arithmetic_mul_1(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {
entry:
 %a = load x86_fp80,ptr %left,align 1
 %b = load x86_fp80,ptr %right,align 1
 %r = fmul x86_fp80 0xK3FFFC000000000000000,%b
 %probe = call i64 @extended80_arithmetic_clobber(i64 %live)
 store x86_fp80 %r,ptr %output,align 1
 ret i64 %probe
}
define i64 @extended80_arithmetic_mul_2(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {
entry:
 %a = load x86_fp80,ptr %left,align 1
 %b = load x86_fp80,ptr %right,align 1
 %r = fmul x86_fp80 %a,0xK4000A000000000000000
 %probe = call i64 @extended80_arithmetic_clobber(i64 %live)
 store x86_fp80 %r,ptr %output,align 1
 ret i64 %probe
}
define i64 @extended80_arithmetic_div_0(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {
entry:
 %a = load x86_fp80,ptr %left,align 1
 %b = load x86_fp80,ptr %right,align 1
 %r = fdiv x86_fp80 %a,%b
 %probe = call i64 @extended80_arithmetic_clobber(i64 %live)
 store x86_fp80 %r,ptr %output,align 1
 ret i64 %probe
}
define i64 @extended80_arithmetic_div_1(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {
entry:
 %a = load x86_fp80,ptr %left,align 1
 %b = load x86_fp80,ptr %right,align 1
 %r = fdiv x86_fp80 0xK3FFFC000000000000000,%b
 %probe = call i64 @extended80_arithmetic_clobber(i64 %live)
 store x86_fp80 %r,ptr %output,align 1
 ret i64 %probe
}
define i64 @extended80_arithmetic_div_2(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {
entry:
 %a = load x86_fp80,ptr %left,align 1
 %b = load x86_fp80,ptr %right,align 1
 %r = fdiv x86_fp80 %a,0xK4000A000000000000000
 %probe = call i64 @extended80_arithmetic_clobber(i64 %live)
 store x86_fp80 %r,ptr %output,align 1
 ret i64 %probe
}
define i64 @extended80_arithmetic_sqrt_0(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {
entry:
 %a = load x86_fp80,ptr %left,align 1
 %b = load x86_fp80,ptr %right,align 1
 %r = call x86_fp80 @llvm.sqrt.f80(x86_fp80 %a)
 %probe = call i64 @extended80_arithmetic_clobber(i64 %live)
 store x86_fp80 %r,ptr %output,align 1
 ret i64 %probe
}
define i64 @extended80_arithmetic_sqrt_1(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {
entry:
 %a = load x86_fp80,ptr %left,align 1
 %b = load x86_fp80,ptr %right,align 1
 %r = call x86_fp80 @llvm.sqrt.f80(x86_fp80 0xK3FFFC000000000000000)
 %probe = call i64 @extended80_arithmetic_clobber(i64 %live)
 store x86_fp80 %r,ptr %output,align 1
 ret i64 %probe
}
define i64 @extended80_arithmetic_sqrt_2(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {
entry:
 %a = load x86_fp80,ptr %left,align 1
 %b = load x86_fp80,ptr %right,align 1
 %r = call x86_fp80 @llvm.sqrt.f80(x86_fp80 0xK80000000000000000000)
 %probe = call i64 @extended80_arithmetic_clobber(i64 %live)
 store x86_fp80 %r,ptr %output,align 1
 ret i64 %probe
}
