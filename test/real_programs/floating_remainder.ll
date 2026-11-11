target triple = "x86_64-unknown-linux-gnu"
target datalayout = "e-i128:128-f80:128"
declare i64 @floating_remainder_clobber(i64)
define i64 @floating_remainder_0_0(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {
entry:
 %a = load x86_fp80,ptr %left,align 1
 %b = load x86_fp80,ptr %right,align 1
 %r = frem x86_fp80 %a,%b
 %probe = call i64 @floating_remainder_clobber(i64 %live)
 store x86_fp80 %r,ptr %output,align 1
 ret i64 %probe
}
define i64 @floating_remainder_0_1(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {
entry:
 %a = load x86_fp80,ptr %left,align 1
 %b = load x86_fp80,ptr %right,align 1
 %r = frem x86_fp80 0xK3FFFC000000000000000,%b
 %probe = call i64 @floating_remainder_clobber(i64 %live)
 store x86_fp80 %r,ptr %output,align 1
 ret i64 %probe
}
define i64 @floating_remainder_0_2(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {
entry:
 %a = load x86_fp80,ptr %left,align 1
 %b = load x86_fp80,ptr %right,align 1
 %r = frem x86_fp80 %a,0xK4000A000000000000000
 %probe = call i64 @floating_remainder_clobber(i64 %live)
 store x86_fp80 %r,ptr %output,align 1
 ret i64 %probe
}
define i64 @floating_remainder_1_0(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {
entry:
 %a = load fp128,ptr %left,align 1
 %b = load fp128,ptr %right,align 1
 %r = frem fp128 %a,%b
 %probe = call i64 @floating_remainder_clobber(i64 %live)
 store fp128 %r,ptr %output,align 1
 ret i64 %probe
}
define i64 @floating_remainder_1_1(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {
entry:
 %a = load fp128,ptr %left,align 1
 %b = load fp128,ptr %right,align 1
 %r = frem fp128 0xL00000000000000003FFF800000000000,%b
 %probe = call i64 @floating_remainder_clobber(i64 %live)
 store fp128 %r,ptr %output,align 1
 ret i64 %probe
}
define i64 @floating_remainder_1_2(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {
entry:
 %a = load fp128,ptr %left,align 1
 %b = load fp128,ptr %right,align 1
 %r = frem fp128 %a,0xL00000000000000004000400000000000
 %probe = call i64 @floating_remainder_clobber(i64 %live)
 store fp128 %r,ptr %output,align 1
 ret i64 %probe
}
define i64 @floating_remainder_2_0(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {
entry:
 %a = load float,ptr %left,align 1
 %b = load float,ptr %right,align 1
 %r = frem float %a,%b
 %probe = call i64 @floating_remainder_clobber(i64 %live)
 store float %r,ptr %output,align 1
 ret i64 %probe
}
define i64 @floating_remainder_2_1(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {
entry:
 %a = load float,ptr %left,align 1
 %b = load float,ptr %right,align 1
 %r = frem float 1.500000e+00,%b
 %probe = call i64 @floating_remainder_clobber(i64 %live)
 store float %r,ptr %output,align 1
 ret i64 %probe
}
define i64 @floating_remainder_2_2(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {
entry:
 %a = load float,ptr %left,align 1
 %b = load float,ptr %right,align 1
 %r = frem float %a,2.500000e+00
 %probe = call i64 @floating_remainder_clobber(i64 %live)
 store float %r,ptr %output,align 1
 ret i64 %probe
}
define i64 @floating_remainder_3_0(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {
entry:
 %a = load double,ptr %left,align 1
 %b = load double,ptr %right,align 1
 %r = frem double %a,%b
 %probe = call i64 @floating_remainder_clobber(i64 %live)
 store double %r,ptr %output,align 1
 ret i64 %probe
}
define i64 @floating_remainder_3_1(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {
entry:
 %a = load double,ptr %left,align 1
 %b = load double,ptr %right,align 1
 %r = frem double 1.500000e+00,%b
 %probe = call i64 @floating_remainder_clobber(i64 %live)
 store double %r,ptr %output,align 1
 ret i64 %probe
}
define i64 @floating_remainder_3_2(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {
entry:
 %a = load double,ptr %left,align 1
 %b = load double,ptr %right,align 1
 %r = frem double %a,2.500000e+00
 %probe = call i64 @floating_remainder_clobber(i64 %live)
 store double %r,ptr %output,align 1
 ret i64 %probe
}
define i64 @floating_remainder_4_0(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {
entry:
 %a = load half,ptr %left,align 1
 %b = load half,ptr %right,align 1
 %r = frem half %a,%b
 %probe = call i64 @floating_remainder_clobber(i64 %live)
 store half %r,ptr %output,align 1
 ret i64 %probe
}
define i64 @floating_remainder_4_1(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {
entry:
 %a = load half,ptr %left,align 1
 %b = load half,ptr %right,align 1
 %r = frem half 0xH3E00,%b
 %probe = call i64 @floating_remainder_clobber(i64 %live)
 store half %r,ptr %output,align 1
 ret i64 %probe
}
define i64 @floating_remainder_4_2(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {
entry:
 %a = load half,ptr %left,align 1
 %b = load half,ptr %right,align 1
 %r = frem half %a,0xH4100
 %probe = call i64 @floating_remainder_clobber(i64 %live)
 store half %r,ptr %output,align 1
 ret i64 %probe
}
define i64 @floating_remainder_5_0(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {
entry:
 %a = load half,ptr %left,align 1
 %b = load half,ptr %right,align 1
 %r = fsub half %a,%b
 %probe = call i64 @floating_remainder_clobber(i64 %live)
 store half %r,ptr %output,align 1
 ret i64 %probe
}
define i64 @floating_remainder_5_1(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {
entry:
 %a = load half,ptr %left,align 1
 %b = load half,ptr %right,align 1
 %r = fsub half 0xH3E00,%b
 %probe = call i64 @floating_remainder_clobber(i64 %live)
 store half %r,ptr %output,align 1
 ret i64 %probe
}
define i64 @floating_remainder_5_2(ptr %left,ptr %right,ptr %third,ptr %output,i64 %live) {
entry:
 %a = load half,ptr %left,align 1
 %b = load half,ptr %right,align 1
 %r = fsub half %a,0xH4100
 %probe = call i64 @floating_remainder_clobber(i64 %live)
 store half %r,ptr %output,align 1
 ret i64 %probe
}
