target triple = "x86_64-unknown-linux-gnu"
target datalayout = "e-i128:128-f80:128"
declare i64 @floating_predicate_clobber(i64)
define i64 @floating_predicate_half_false(ptr %left,ptr %right,ptr %output,i64 %live) {
entry:
 %x = load half,ptr %left,align 1
 %y = load half,ptr %right,align 1
 %c0 = fcmp false half %x,%y
 %w0 = zext i1 %c0 to i64
 %probe = call i64 @floating_predicate_clobber(i64 %live)
 store i64 %w0,ptr %output,align 1
 %answer = xor i64 %w0,%probe
 ret i64 %answer
}
define i64 @floating_predicate_half_oeq(ptr %left,ptr %right,ptr %output,i64 %live) {
entry:
 %x = load half,ptr %left,align 1
 %y = load half,ptr %right,align 1
 %c1 = fcmp oeq half %x,%y
 %w1 = zext i1 %c1 to i64
 %probe = call i64 @floating_predicate_clobber(i64 %live)
 store i64 %w1,ptr %output,align 1
 %answer = xor i64 %w1,%probe
 ret i64 %answer
}
define i64 @floating_predicate_half_ogt(ptr %left,ptr %right,ptr %output,i64 %live) {
entry:
 %x = load half,ptr %left,align 1
 %y = load half,ptr %right,align 1
 %c2 = fcmp ogt half %x,%y
 %w2 = zext i1 %c2 to i64
 %probe = call i64 @floating_predicate_clobber(i64 %live)
 store i64 %w2,ptr %output,align 1
 %answer = xor i64 %w2,%probe
 ret i64 %answer
}
define i64 @floating_predicate_half_oge(ptr %left,ptr %right,ptr %output,i64 %live) {
entry:
 %x = load half,ptr %left,align 1
 %y = load half,ptr %right,align 1
 %c3 = fcmp oge half %x,%y
 %w3 = zext i1 %c3 to i64
 %probe = call i64 @floating_predicate_clobber(i64 %live)
 store i64 %w3,ptr %output,align 1
 %answer = xor i64 %w3,%probe
 ret i64 %answer
}
define i64 @floating_predicate_half_olt(ptr %left,ptr %right,ptr %output,i64 %live) {
entry:
 %x = load half,ptr %left,align 1
 %y = load half,ptr %right,align 1
 %c4 = fcmp olt half %x,%y
 %w4 = zext i1 %c4 to i64
 %probe = call i64 @floating_predicate_clobber(i64 %live)
 store i64 %w4,ptr %output,align 1
 %answer = xor i64 %w4,%probe
 ret i64 %answer
}
define i64 @floating_predicate_half_ole(ptr %left,ptr %right,ptr %output,i64 %live) {
entry:
 %x = load half,ptr %left,align 1
 %y = load half,ptr %right,align 1
 %c5 = fcmp ole half %x,%y
 %w5 = zext i1 %c5 to i64
 %probe = call i64 @floating_predicate_clobber(i64 %live)
 store i64 %w5,ptr %output,align 1
 %answer = xor i64 %w5,%probe
 ret i64 %answer
}
define i64 @floating_predicate_half_one(ptr %left,ptr %right,ptr %output,i64 %live) {
entry:
 %x = load half,ptr %left,align 1
 %y = load half,ptr %right,align 1
 %c6 = fcmp one half %x,%y
 %w6 = zext i1 %c6 to i64
 %probe = call i64 @floating_predicate_clobber(i64 %live)
 store i64 %w6,ptr %output,align 1
 %answer = xor i64 %w6,%probe
 ret i64 %answer
}
define i64 @floating_predicate_half_ord(ptr %left,ptr %right,ptr %output,i64 %live) {
entry:
 %x = load half,ptr %left,align 1
 %y = load half,ptr %right,align 1
 %c7 = fcmp ord half %x,%y
 %w7 = zext i1 %c7 to i64
 %probe = call i64 @floating_predicate_clobber(i64 %live)
 store i64 %w7,ptr %output,align 1
 %answer = xor i64 %w7,%probe
 ret i64 %answer
}
define i64 @floating_predicate_half_ueq(ptr %left,ptr %right,ptr %output,i64 %live) {
entry:
 %x = load half,ptr %left,align 1
 %y = load half,ptr %right,align 1
 %c8 = fcmp ueq half %x,%y
 %w8 = zext i1 %c8 to i64
 %probe = call i64 @floating_predicate_clobber(i64 %live)
 store i64 %w8,ptr %output,align 1
 %answer = xor i64 %w8,%probe
 ret i64 %answer
}
define i64 @floating_predicate_half_ugt(ptr %left,ptr %right,ptr %output,i64 %live) {
entry:
 %x = load half,ptr %left,align 1
 %y = load half,ptr %right,align 1
 %c9 = fcmp ugt half %x,%y
 %w9 = zext i1 %c9 to i64
 %probe = call i64 @floating_predicate_clobber(i64 %live)
 store i64 %w9,ptr %output,align 1
 %answer = xor i64 %w9,%probe
 ret i64 %answer
}
define i64 @floating_predicate_half_uge(ptr %left,ptr %right,ptr %output,i64 %live) {
entry:
 %x = load half,ptr %left,align 1
 %y = load half,ptr %right,align 1
 %c10 = fcmp uge half %x,%y
 %w10 = zext i1 %c10 to i64
 %probe = call i64 @floating_predicate_clobber(i64 %live)
 store i64 %w10,ptr %output,align 1
 %answer = xor i64 %w10,%probe
 ret i64 %answer
}
define i64 @floating_predicate_half_ult(ptr %left,ptr %right,ptr %output,i64 %live) {
entry:
 %x = load half,ptr %left,align 1
 %y = load half,ptr %right,align 1
 %c11 = fcmp ult half %x,%y
 %w11 = zext i1 %c11 to i64
 %probe = call i64 @floating_predicate_clobber(i64 %live)
 store i64 %w11,ptr %output,align 1
 %answer = xor i64 %w11,%probe
 ret i64 %answer
}
define i64 @floating_predicate_half_ule(ptr %left,ptr %right,ptr %output,i64 %live) {
entry:
 %x = load half,ptr %left,align 1
 %y = load half,ptr %right,align 1
 %c12 = fcmp ule half %x,%y
 %w12 = zext i1 %c12 to i64
 %probe = call i64 @floating_predicate_clobber(i64 %live)
 store i64 %w12,ptr %output,align 1
 %answer = xor i64 %w12,%probe
 ret i64 %answer
}
define i64 @floating_predicate_half_une(ptr %left,ptr %right,ptr %output,i64 %live) {
entry:
 %x = load half,ptr %left,align 1
 %y = load half,ptr %right,align 1
 %c13 = fcmp une half %x,%y
 %w13 = zext i1 %c13 to i64
 %probe = call i64 @floating_predicate_clobber(i64 %live)
 store i64 %w13,ptr %output,align 1
 %answer = xor i64 %w13,%probe
 ret i64 %answer
}
define i64 @floating_predicate_half_uno(ptr %left,ptr %right,ptr %output,i64 %live) {
entry:
 %x = load half,ptr %left,align 1
 %y = load half,ptr %right,align 1
 %c14 = fcmp uno half %x,%y
 %w14 = zext i1 %c14 to i64
 %probe = call i64 @floating_predicate_clobber(i64 %live)
 store i64 %w14,ptr %output,align 1
 %answer = xor i64 %w14,%probe
 ret i64 %answer
}
define i64 @floating_predicate_half_true(ptr %left,ptr %right,ptr %output,i64 %live) {
entry:
 %x = load half,ptr %left,align 1
 %y = load half,ptr %right,align 1
 %c15 = fcmp true half %x,%y
 %w15 = zext i1 %c15 to i64
 %probe = call i64 @floating_predicate_clobber(i64 %live)
 store i64 %w15,ptr %output,align 1
 %answer = xor i64 %w15,%probe
 ret i64 %answer
}
define i64 @floating_predicate_half_mask(ptr %left,ptr %right,ptr %output,i64 %live) {
entry:
 %x = load half,ptr %left,align 1
 %y = load half,ptr %right,align 1
 %c0 = fcmp false half %x,%y
 %w0 = zext i1 %c0 to i64
 %s0 = shl i64 %w0,0
 %m0 = or i64 0,%s0
 %c1 = fcmp oeq half %x,%y
 %w1 = zext i1 %c1 to i64
 %s1 = shl i64 %w1,1
 %m1 = or i64 %m0,%s1
 %c2 = fcmp ogt half %x,%y
 %w2 = zext i1 %c2 to i64
 %s2 = shl i64 %w2,2
 %m2 = or i64 %m1,%s2
 %c3 = fcmp oge half %x,%y
 %w3 = zext i1 %c3 to i64
 %s3 = shl i64 %w3,3
 %m3 = or i64 %m2,%s3
 %c4 = fcmp olt half %x,%y
 %w4 = zext i1 %c4 to i64
 %s4 = shl i64 %w4,4
 %m4 = or i64 %m3,%s4
 %c5 = fcmp ole half %x,%y
 %w5 = zext i1 %c5 to i64
 %s5 = shl i64 %w5,5
 %m5 = or i64 %m4,%s5
 %c6 = fcmp one half %x,%y
 %w6 = zext i1 %c6 to i64
 %s6 = shl i64 %w6,6
 %m6 = or i64 %m5,%s6
 %c7 = fcmp ord half %x,%y
 %w7 = zext i1 %c7 to i64
 %s7 = shl i64 %w7,7
 %m7 = or i64 %m6,%s7
 %c8 = fcmp ueq half %x,%y
 %w8 = zext i1 %c8 to i64
 %s8 = shl i64 %w8,8
 %m8 = or i64 %m7,%s8
 %c9 = fcmp ugt half %x,%y
 %w9 = zext i1 %c9 to i64
 %s9 = shl i64 %w9,9
 %m9 = or i64 %m8,%s9
 %c10 = fcmp uge half %x,%y
 %w10 = zext i1 %c10 to i64
 %s10 = shl i64 %w10,10
 %m10 = or i64 %m9,%s10
 %c11 = fcmp ult half %x,%y
 %w11 = zext i1 %c11 to i64
 %s11 = shl i64 %w11,11
 %m11 = or i64 %m10,%s11
 %c12 = fcmp ule half %x,%y
 %w12 = zext i1 %c12 to i64
 %s12 = shl i64 %w12,12
 %m12 = or i64 %m11,%s12
 %c13 = fcmp une half %x,%y
 %w13 = zext i1 %c13 to i64
 %s13 = shl i64 %w13,13
 %m13 = or i64 %m12,%s13
 %c14 = fcmp uno half %x,%y
 %w14 = zext i1 %c14 to i64
 %s14 = shl i64 %w14,14
 %m14 = or i64 %m13,%s14
 %c15 = fcmp true half %x,%y
 %w15 = zext i1 %c15 to i64
 %s15 = shl i64 %w15,15
 %m15 = or i64 %m14,%s15
 %probe = call i64 @floating_predicate_clobber(i64 %live)
 store i64 %m15,ptr %output,align 1
 %answer = xor i64 %m15,%probe
 ret i64 %answer
}
define i64 @floating_predicate_extended_false(ptr %left,ptr %right,ptr %output,i64 %live) {
entry:
 %x = load x86_fp80,ptr %left,align 1
 %y = load x86_fp80,ptr %right,align 1
 %c0 = fcmp false x86_fp80 %x,%y
 %w0 = zext i1 %c0 to i64
 %probe = call i64 @floating_predicate_clobber(i64 %live)
 store i64 %w0,ptr %output,align 1
 %answer = xor i64 %w0,%probe
 ret i64 %answer
}
define i64 @floating_predicate_extended_oeq(ptr %left,ptr %right,ptr %output,i64 %live) {
entry:
 %x = load x86_fp80,ptr %left,align 1
 %y = load x86_fp80,ptr %right,align 1
 %c1 = fcmp oeq x86_fp80 %x,%y
 %w1 = zext i1 %c1 to i64
 %probe = call i64 @floating_predicate_clobber(i64 %live)
 store i64 %w1,ptr %output,align 1
 %answer = xor i64 %w1,%probe
 ret i64 %answer
}
define i64 @floating_predicate_extended_ogt(ptr %left,ptr %right,ptr %output,i64 %live) {
entry:
 %x = load x86_fp80,ptr %left,align 1
 %y = load x86_fp80,ptr %right,align 1
 %c2 = fcmp ogt x86_fp80 %x,%y
 %w2 = zext i1 %c2 to i64
 %probe = call i64 @floating_predicate_clobber(i64 %live)
 store i64 %w2,ptr %output,align 1
 %answer = xor i64 %w2,%probe
 ret i64 %answer
}
define i64 @floating_predicate_extended_oge(ptr %left,ptr %right,ptr %output,i64 %live) {
entry:
 %x = load x86_fp80,ptr %left,align 1
 %y = load x86_fp80,ptr %right,align 1
 %c3 = fcmp oge x86_fp80 %x,%y
 %w3 = zext i1 %c3 to i64
 %probe = call i64 @floating_predicate_clobber(i64 %live)
 store i64 %w3,ptr %output,align 1
 %answer = xor i64 %w3,%probe
 ret i64 %answer
}
define i64 @floating_predicate_extended_olt(ptr %left,ptr %right,ptr %output,i64 %live) {
entry:
 %x = load x86_fp80,ptr %left,align 1
 %y = load x86_fp80,ptr %right,align 1
 %c4 = fcmp olt x86_fp80 %x,%y
 %w4 = zext i1 %c4 to i64
 %probe = call i64 @floating_predicate_clobber(i64 %live)
 store i64 %w4,ptr %output,align 1
 %answer = xor i64 %w4,%probe
 ret i64 %answer
}
define i64 @floating_predicate_extended_ole(ptr %left,ptr %right,ptr %output,i64 %live) {
entry:
 %x = load x86_fp80,ptr %left,align 1
 %y = load x86_fp80,ptr %right,align 1
 %c5 = fcmp ole x86_fp80 %x,%y
 %w5 = zext i1 %c5 to i64
 %probe = call i64 @floating_predicate_clobber(i64 %live)
 store i64 %w5,ptr %output,align 1
 %answer = xor i64 %w5,%probe
 ret i64 %answer
}
define i64 @floating_predicate_extended_one(ptr %left,ptr %right,ptr %output,i64 %live) {
entry:
 %x = load x86_fp80,ptr %left,align 1
 %y = load x86_fp80,ptr %right,align 1
 %c6 = fcmp one x86_fp80 %x,%y
 %w6 = zext i1 %c6 to i64
 %probe = call i64 @floating_predicate_clobber(i64 %live)
 store i64 %w6,ptr %output,align 1
 %answer = xor i64 %w6,%probe
 ret i64 %answer
}
define i64 @floating_predicate_extended_ord(ptr %left,ptr %right,ptr %output,i64 %live) {
entry:
 %x = load x86_fp80,ptr %left,align 1
 %y = load x86_fp80,ptr %right,align 1
 %c7 = fcmp ord x86_fp80 %x,%y
 %w7 = zext i1 %c7 to i64
 %probe = call i64 @floating_predicate_clobber(i64 %live)
 store i64 %w7,ptr %output,align 1
 %answer = xor i64 %w7,%probe
 ret i64 %answer
}
define i64 @floating_predicate_extended_ueq(ptr %left,ptr %right,ptr %output,i64 %live) {
entry:
 %x = load x86_fp80,ptr %left,align 1
 %y = load x86_fp80,ptr %right,align 1
 %c8 = fcmp ueq x86_fp80 %x,%y
 %w8 = zext i1 %c8 to i64
 %probe = call i64 @floating_predicate_clobber(i64 %live)
 store i64 %w8,ptr %output,align 1
 %answer = xor i64 %w8,%probe
 ret i64 %answer
}
define i64 @floating_predicate_extended_ugt(ptr %left,ptr %right,ptr %output,i64 %live) {
entry:
 %x = load x86_fp80,ptr %left,align 1
 %y = load x86_fp80,ptr %right,align 1
 %c9 = fcmp ugt x86_fp80 %x,%y
 %w9 = zext i1 %c9 to i64
 %probe = call i64 @floating_predicate_clobber(i64 %live)
 store i64 %w9,ptr %output,align 1
 %answer = xor i64 %w9,%probe
 ret i64 %answer
}
define i64 @floating_predicate_extended_uge(ptr %left,ptr %right,ptr %output,i64 %live) {
entry:
 %x = load x86_fp80,ptr %left,align 1
 %y = load x86_fp80,ptr %right,align 1
 %c10 = fcmp uge x86_fp80 %x,%y
 %w10 = zext i1 %c10 to i64
 %probe = call i64 @floating_predicate_clobber(i64 %live)
 store i64 %w10,ptr %output,align 1
 %answer = xor i64 %w10,%probe
 ret i64 %answer
}
define i64 @floating_predicate_extended_ult(ptr %left,ptr %right,ptr %output,i64 %live) {
entry:
 %x = load x86_fp80,ptr %left,align 1
 %y = load x86_fp80,ptr %right,align 1
 %c11 = fcmp ult x86_fp80 %x,%y
 %w11 = zext i1 %c11 to i64
 %probe = call i64 @floating_predicate_clobber(i64 %live)
 store i64 %w11,ptr %output,align 1
 %answer = xor i64 %w11,%probe
 ret i64 %answer
}
define i64 @floating_predicate_extended_ule(ptr %left,ptr %right,ptr %output,i64 %live) {
entry:
 %x = load x86_fp80,ptr %left,align 1
 %y = load x86_fp80,ptr %right,align 1
 %c12 = fcmp ule x86_fp80 %x,%y
 %w12 = zext i1 %c12 to i64
 %probe = call i64 @floating_predicate_clobber(i64 %live)
 store i64 %w12,ptr %output,align 1
 %answer = xor i64 %w12,%probe
 ret i64 %answer
}
define i64 @floating_predicate_extended_une(ptr %left,ptr %right,ptr %output,i64 %live) {
entry:
 %x = load x86_fp80,ptr %left,align 1
 %y = load x86_fp80,ptr %right,align 1
 %c13 = fcmp une x86_fp80 %x,%y
 %w13 = zext i1 %c13 to i64
 %probe = call i64 @floating_predicate_clobber(i64 %live)
 store i64 %w13,ptr %output,align 1
 %answer = xor i64 %w13,%probe
 ret i64 %answer
}
define i64 @floating_predicate_extended_uno(ptr %left,ptr %right,ptr %output,i64 %live) {
entry:
 %x = load x86_fp80,ptr %left,align 1
 %y = load x86_fp80,ptr %right,align 1
 %c14 = fcmp uno x86_fp80 %x,%y
 %w14 = zext i1 %c14 to i64
 %probe = call i64 @floating_predicate_clobber(i64 %live)
 store i64 %w14,ptr %output,align 1
 %answer = xor i64 %w14,%probe
 ret i64 %answer
}
define i64 @floating_predicate_extended_true(ptr %left,ptr %right,ptr %output,i64 %live) {
entry:
 %x = load x86_fp80,ptr %left,align 1
 %y = load x86_fp80,ptr %right,align 1
 %c15 = fcmp true x86_fp80 %x,%y
 %w15 = zext i1 %c15 to i64
 %probe = call i64 @floating_predicate_clobber(i64 %live)
 store i64 %w15,ptr %output,align 1
 %answer = xor i64 %w15,%probe
 ret i64 %answer
}
define i64 @floating_predicate_extended_mask(ptr %left,ptr %right,ptr %output,i64 %live) {
entry:
 %x = load x86_fp80,ptr %left,align 1
 %y = load x86_fp80,ptr %right,align 1
 %c0 = fcmp false x86_fp80 %x,%y
 %w0 = zext i1 %c0 to i64
 %s0 = shl i64 %w0,0
 %m0 = or i64 0,%s0
 %c1 = fcmp oeq x86_fp80 %x,%y
 %w1 = zext i1 %c1 to i64
 %s1 = shl i64 %w1,1
 %m1 = or i64 %m0,%s1
 %c2 = fcmp ogt x86_fp80 %x,%y
 %w2 = zext i1 %c2 to i64
 %s2 = shl i64 %w2,2
 %m2 = or i64 %m1,%s2
 %c3 = fcmp oge x86_fp80 %x,%y
 %w3 = zext i1 %c3 to i64
 %s3 = shl i64 %w3,3
 %m3 = or i64 %m2,%s3
 %c4 = fcmp olt x86_fp80 %x,%y
 %w4 = zext i1 %c4 to i64
 %s4 = shl i64 %w4,4
 %m4 = or i64 %m3,%s4
 %c5 = fcmp ole x86_fp80 %x,%y
 %w5 = zext i1 %c5 to i64
 %s5 = shl i64 %w5,5
 %m5 = or i64 %m4,%s5
 %c6 = fcmp one x86_fp80 %x,%y
 %w6 = zext i1 %c6 to i64
 %s6 = shl i64 %w6,6
 %m6 = or i64 %m5,%s6
 %c7 = fcmp ord x86_fp80 %x,%y
 %w7 = zext i1 %c7 to i64
 %s7 = shl i64 %w7,7
 %m7 = or i64 %m6,%s7
 %c8 = fcmp ueq x86_fp80 %x,%y
 %w8 = zext i1 %c8 to i64
 %s8 = shl i64 %w8,8
 %m8 = or i64 %m7,%s8
 %c9 = fcmp ugt x86_fp80 %x,%y
 %w9 = zext i1 %c9 to i64
 %s9 = shl i64 %w9,9
 %m9 = or i64 %m8,%s9
 %c10 = fcmp uge x86_fp80 %x,%y
 %w10 = zext i1 %c10 to i64
 %s10 = shl i64 %w10,10
 %m10 = or i64 %m9,%s10
 %c11 = fcmp ult x86_fp80 %x,%y
 %w11 = zext i1 %c11 to i64
 %s11 = shl i64 %w11,11
 %m11 = or i64 %m10,%s11
 %c12 = fcmp ule x86_fp80 %x,%y
 %w12 = zext i1 %c12 to i64
 %s12 = shl i64 %w12,12
 %m12 = or i64 %m11,%s12
 %c13 = fcmp une x86_fp80 %x,%y
 %w13 = zext i1 %c13 to i64
 %s13 = shl i64 %w13,13
 %m13 = or i64 %m12,%s13
 %c14 = fcmp uno x86_fp80 %x,%y
 %w14 = zext i1 %c14 to i64
 %s14 = shl i64 %w14,14
 %m14 = or i64 %m13,%s14
 %c15 = fcmp true x86_fp80 %x,%y
 %w15 = zext i1 %c15 to i64
 %s15 = shl i64 %w15,15
 %m15 = or i64 %m14,%s15
 %probe = call i64 @floating_predicate_clobber(i64 %live)
 store i64 %m15,ptr %output,align 1
 %answer = xor i64 %m15,%probe
 ret i64 %answer
}
