target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"
declare i65 @llvm.bitreverse.i65(i65)
define i64 @odd_pair_reverse_body_0(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,i65 %a,ptr %out) noinline {
entry:
 %reverse = call i65 @llvm.bitreverse.i65(i65 %a)
 store i65 %reverse,ptr %out,align 1
 %wide = zext i65 %reverse to i128
 %lo = trunc i128 %wide to i64
 %shifted = lshr i128 %wide,64
 %hi = trunc i128 %shifted to i64
 %raw = xor i64 %lo,%hi
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
define i64 @odd_pair_reverse_probe_0(ptr %input,ptr %out,i64 %salt) {
entry:
 %ap0 = getelementptr i8,ptr %input,i64 0
 %p0 = load i64,ptr %ap0,align 1
 %ap1 = getelementptr i8,ptr %input,i64 8
 %p1 = load i64,ptr %ap1,align 1
 %ap2 = getelementptr i8,ptr %input,i64 16
 %p2 = load i64,ptr %ap2,align 1
 %ap3 = getelementptr i8,ptr %input,i64 24
 %p3 = load i64,ptr %ap3,align 1
 %ap4 = getelementptr i8,ptr %input,i64 32
 %p4 = load i64,ptr %ap4,align 1
 %ap5 = getelementptr i8,ptr %input,i64 40
 %p5 = load i64,ptr %ap5,align 1
 %data = getelementptr i8,ptr %input,i64 48
 %a = load i65,ptr %data,align 1
 %answer = call i64 @odd_pair_reverse_body_0(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,i65 %a,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 9
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 17
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 25
 store i64 %p0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @odd_pair_reverse_body_1(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,i65 %a,ptr %out) noinline {
entry:
 %reverse = call i65 @llvm.bitreverse.i65(i65 %a)
 store i65 %reverse,ptr %out,align 1
 %wide = zext i65 %reverse to i128
 %lo = trunc i128 %wide to i64
 %shifted = lshr i128 %wide,64
 %hi = trunc i128 %shifted to i64
 %raw = xor i64 %lo,%hi
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
define i64 @odd_pair_reverse_probe_1(ptr %input,ptr %out,i64 %salt) {
entry:
 %ap0 = getelementptr i8,ptr %input,i64 0
 %p0 = load i64,ptr %ap0,align 1
 %ap1 = getelementptr i8,ptr %input,i64 8
 %p1 = load i64,ptr %ap1,align 1
 %ap2 = getelementptr i8,ptr %input,i64 16
 %p2 = load i64,ptr %ap2,align 1
 %ap3 = getelementptr i8,ptr %input,i64 24
 %p3 = load i64,ptr %ap3,align 1
 %ap4 = getelementptr i8,ptr %input,i64 32
 %p4 = load i64,ptr %ap4,align 1
 %ap5 = getelementptr i8,ptr %input,i64 40
 %p5 = load i64,ptr %ap5,align 1
 %data = getelementptr i8,ptr %input,i64 48
 %a = load i65,ptr %data,align 1
 %answer = call fastcc i64 @odd_pair_reverse_body_1(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,i65 %a,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 9
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 17
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 25
 store i64 %p0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
declare i66 @llvm.bitreverse.i66(i66)
define i64 @odd_pair_reverse_body_2(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,i66 %a,ptr %out) noinline {
entry:
 %reverse = call i66 @llvm.bitreverse.i66(i66 %a)
 store i66 %reverse,ptr %out,align 1
 %wide = zext i66 %reverse to i128
 %lo = trunc i128 %wide to i64
 %shifted = lshr i128 %wide,64
 %hi = trunc i128 %shifted to i64
 %raw = xor i64 %lo,%hi
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
define i64 @odd_pair_reverse_probe_2(ptr %input,ptr %out,i64 %salt) {
entry:
 %ap0 = getelementptr i8,ptr %input,i64 0
 %p0 = load i64,ptr %ap0,align 1
 %ap1 = getelementptr i8,ptr %input,i64 8
 %p1 = load i64,ptr %ap1,align 1
 %ap2 = getelementptr i8,ptr %input,i64 16
 %p2 = load i64,ptr %ap2,align 1
 %ap3 = getelementptr i8,ptr %input,i64 24
 %p3 = load i64,ptr %ap3,align 1
 %ap4 = getelementptr i8,ptr %input,i64 32
 %p4 = load i64,ptr %ap4,align 1
 %ap5 = getelementptr i8,ptr %input,i64 40
 %p5 = load i64,ptr %ap5,align 1
 %data = getelementptr i8,ptr %input,i64 48
 %a = load i66,ptr %data,align 1
 %answer = call i64 @odd_pair_reverse_body_2(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,i66 %a,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 9
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 17
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 25
 store i64 %p0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @odd_pair_reverse_body_3(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,i66 %a,ptr %out) noinline {
entry:
 %reverse = call i66 @llvm.bitreverse.i66(i66 %a)
 store i66 %reverse,ptr %out,align 1
 %wide = zext i66 %reverse to i128
 %lo = trunc i128 %wide to i64
 %shifted = lshr i128 %wide,64
 %hi = trunc i128 %shifted to i64
 %raw = xor i64 %lo,%hi
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
define i64 @odd_pair_reverse_probe_3(ptr %input,ptr %out,i64 %salt) {
entry:
 %ap0 = getelementptr i8,ptr %input,i64 0
 %p0 = load i64,ptr %ap0,align 1
 %ap1 = getelementptr i8,ptr %input,i64 8
 %p1 = load i64,ptr %ap1,align 1
 %ap2 = getelementptr i8,ptr %input,i64 16
 %p2 = load i64,ptr %ap2,align 1
 %ap3 = getelementptr i8,ptr %input,i64 24
 %p3 = load i64,ptr %ap3,align 1
 %ap4 = getelementptr i8,ptr %input,i64 32
 %p4 = load i64,ptr %ap4,align 1
 %ap5 = getelementptr i8,ptr %input,i64 40
 %p5 = load i64,ptr %ap5,align 1
 %data = getelementptr i8,ptr %input,i64 48
 %a = load i66,ptr %data,align 1
 %answer = call fastcc i64 @odd_pair_reverse_body_3(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,i66 %a,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 9
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 17
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 25
 store i64 %p0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
declare i79 @llvm.bitreverse.i79(i79)
define i64 @odd_pair_reverse_body_4(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,i79 %a,ptr %out) noinline {
entry:
 %reverse = call i79 @llvm.bitreverse.i79(i79 %a)
 store i79 %reverse,ptr %out,align 1
 %wide = zext i79 %reverse to i128
 %lo = trunc i128 %wide to i64
 %shifted = lshr i128 %wide,64
 %hi = trunc i128 %shifted to i64
 %raw = xor i64 %lo,%hi
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
define i64 @odd_pair_reverse_probe_4(ptr %input,ptr %out,i64 %salt) {
entry:
 %ap0 = getelementptr i8,ptr %input,i64 0
 %p0 = load i64,ptr %ap0,align 1
 %ap1 = getelementptr i8,ptr %input,i64 8
 %p1 = load i64,ptr %ap1,align 1
 %ap2 = getelementptr i8,ptr %input,i64 16
 %p2 = load i64,ptr %ap2,align 1
 %ap3 = getelementptr i8,ptr %input,i64 24
 %p3 = load i64,ptr %ap3,align 1
 %ap4 = getelementptr i8,ptr %input,i64 32
 %p4 = load i64,ptr %ap4,align 1
 %ap5 = getelementptr i8,ptr %input,i64 40
 %p5 = load i64,ptr %ap5,align 1
 %data = getelementptr i8,ptr %input,i64 48
 %a = load i79,ptr %data,align 1
 %answer = call i64 @odd_pair_reverse_body_4(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,i79 %a,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 10
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 18
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 26
 store i64 %p0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @odd_pair_reverse_body_5(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,i79 %a,ptr %out) noinline {
entry:
 %reverse = call i79 @llvm.bitreverse.i79(i79 %a)
 store i79 %reverse,ptr %out,align 1
 %wide = zext i79 %reverse to i128
 %lo = trunc i128 %wide to i64
 %shifted = lshr i128 %wide,64
 %hi = trunc i128 %shifted to i64
 %raw = xor i64 %lo,%hi
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
define i64 @odd_pair_reverse_probe_5(ptr %input,ptr %out,i64 %salt) {
entry:
 %ap0 = getelementptr i8,ptr %input,i64 0
 %p0 = load i64,ptr %ap0,align 1
 %ap1 = getelementptr i8,ptr %input,i64 8
 %p1 = load i64,ptr %ap1,align 1
 %ap2 = getelementptr i8,ptr %input,i64 16
 %p2 = load i64,ptr %ap2,align 1
 %ap3 = getelementptr i8,ptr %input,i64 24
 %p3 = load i64,ptr %ap3,align 1
 %ap4 = getelementptr i8,ptr %input,i64 32
 %p4 = load i64,ptr %ap4,align 1
 %ap5 = getelementptr i8,ptr %input,i64 40
 %p5 = load i64,ptr %ap5,align 1
 %data = getelementptr i8,ptr %input,i64 48
 %a = load i79,ptr %data,align 1
 %answer = call fastcc i64 @odd_pair_reverse_body_5(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,i79 %a,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 10
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 18
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 26
 store i64 %p0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
declare i80 @llvm.bitreverse.i80(i80)
define i64 @odd_pair_reverse_body_6(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,i80 %a,ptr %out) noinline {
entry:
 %reverse = call i80 @llvm.bitreverse.i80(i80 %a)
 store i80 %reverse,ptr %out,align 1
 %wide = zext i80 %reverse to i128
 %lo = trunc i128 %wide to i64
 %shifted = lshr i128 %wide,64
 %hi = trunc i128 %shifted to i64
 %raw = xor i64 %lo,%hi
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
define i64 @odd_pair_reverse_probe_6(ptr %input,ptr %out,i64 %salt) {
entry:
 %ap0 = getelementptr i8,ptr %input,i64 0
 %p0 = load i64,ptr %ap0,align 1
 %ap1 = getelementptr i8,ptr %input,i64 8
 %p1 = load i64,ptr %ap1,align 1
 %ap2 = getelementptr i8,ptr %input,i64 16
 %p2 = load i64,ptr %ap2,align 1
 %ap3 = getelementptr i8,ptr %input,i64 24
 %p3 = load i64,ptr %ap3,align 1
 %ap4 = getelementptr i8,ptr %input,i64 32
 %p4 = load i64,ptr %ap4,align 1
 %ap5 = getelementptr i8,ptr %input,i64 40
 %p5 = load i64,ptr %ap5,align 1
 %data = getelementptr i8,ptr %input,i64 48
 %a = load i80,ptr %data,align 1
 %answer = call i64 @odd_pair_reverse_body_6(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,i80 %a,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 10
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 18
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 26
 store i64 %p0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @odd_pair_reverse_body_7(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,i80 %a,ptr %out) noinline {
entry:
 %reverse = call i80 @llvm.bitreverse.i80(i80 %a)
 store i80 %reverse,ptr %out,align 1
 %wide = zext i80 %reverse to i128
 %lo = trunc i128 %wide to i64
 %shifted = lshr i128 %wide,64
 %hi = trunc i128 %shifted to i64
 %raw = xor i64 %lo,%hi
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
define i64 @odd_pair_reverse_probe_7(ptr %input,ptr %out,i64 %salt) {
entry:
 %ap0 = getelementptr i8,ptr %input,i64 0
 %p0 = load i64,ptr %ap0,align 1
 %ap1 = getelementptr i8,ptr %input,i64 8
 %p1 = load i64,ptr %ap1,align 1
 %ap2 = getelementptr i8,ptr %input,i64 16
 %p2 = load i64,ptr %ap2,align 1
 %ap3 = getelementptr i8,ptr %input,i64 24
 %p3 = load i64,ptr %ap3,align 1
 %ap4 = getelementptr i8,ptr %input,i64 32
 %p4 = load i64,ptr %ap4,align 1
 %ap5 = getelementptr i8,ptr %input,i64 40
 %p5 = load i64,ptr %ap5,align 1
 %data = getelementptr i8,ptr %input,i64 48
 %a = load i80,ptr %data,align 1
 %answer = call fastcc i64 @odd_pair_reverse_body_7(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,i80 %a,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 10
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 18
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 26
 store i64 %p0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
declare i94 @llvm.bitreverse.i94(i94)
define i64 @odd_pair_reverse_body_8(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,i94 %a,ptr %out) noinline {
entry:
 %reverse = call i94 @llvm.bitreverse.i94(i94 %a)
 store i94 %reverse,ptr %out,align 1
 %wide = zext i94 %reverse to i128
 %lo = trunc i128 %wide to i64
 %shifted = lshr i128 %wide,64
 %hi = trunc i128 %shifted to i64
 %raw = xor i64 %lo,%hi
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
define i64 @odd_pair_reverse_probe_8(ptr %input,ptr %out,i64 %salt) {
entry:
 %ap0 = getelementptr i8,ptr %input,i64 0
 %p0 = load i64,ptr %ap0,align 1
 %ap1 = getelementptr i8,ptr %input,i64 8
 %p1 = load i64,ptr %ap1,align 1
 %ap2 = getelementptr i8,ptr %input,i64 16
 %p2 = load i64,ptr %ap2,align 1
 %ap3 = getelementptr i8,ptr %input,i64 24
 %p3 = load i64,ptr %ap3,align 1
 %ap4 = getelementptr i8,ptr %input,i64 32
 %p4 = load i64,ptr %ap4,align 1
 %ap5 = getelementptr i8,ptr %input,i64 40
 %p5 = load i64,ptr %ap5,align 1
 %data = getelementptr i8,ptr %input,i64 48
 %a = load i94,ptr %data,align 1
 %answer = call i64 @odd_pair_reverse_body_8(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,i94 %a,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 12
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 20
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 28
 store i64 %p0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @odd_pair_reverse_body_9(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,i94 %a,ptr %out) noinline {
entry:
 %reverse = call i94 @llvm.bitreverse.i94(i94 %a)
 store i94 %reverse,ptr %out,align 1
 %wide = zext i94 %reverse to i128
 %lo = trunc i128 %wide to i64
 %shifted = lshr i128 %wide,64
 %hi = trunc i128 %shifted to i64
 %raw = xor i64 %lo,%hi
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
define i64 @odd_pair_reverse_probe_9(ptr %input,ptr %out,i64 %salt) {
entry:
 %ap0 = getelementptr i8,ptr %input,i64 0
 %p0 = load i64,ptr %ap0,align 1
 %ap1 = getelementptr i8,ptr %input,i64 8
 %p1 = load i64,ptr %ap1,align 1
 %ap2 = getelementptr i8,ptr %input,i64 16
 %p2 = load i64,ptr %ap2,align 1
 %ap3 = getelementptr i8,ptr %input,i64 24
 %p3 = load i64,ptr %ap3,align 1
 %ap4 = getelementptr i8,ptr %input,i64 32
 %p4 = load i64,ptr %ap4,align 1
 %ap5 = getelementptr i8,ptr %input,i64 40
 %p5 = load i64,ptr %ap5,align 1
 %data = getelementptr i8,ptr %input,i64 48
 %a = load i94,ptr %data,align 1
 %answer = call fastcc i64 @odd_pair_reverse_body_9(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,i94 %a,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 12
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 20
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 28
 store i64 %p0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
declare i95 @llvm.bitreverse.i95(i95)
define i64 @odd_pair_reverse_body_10(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,i95 %a,ptr %out) noinline {
entry:
 %reverse = call i95 @llvm.bitreverse.i95(i95 %a)
 store i95 %reverse,ptr %out,align 1
 %wide = zext i95 %reverse to i128
 %lo = trunc i128 %wide to i64
 %shifted = lshr i128 %wide,64
 %hi = trunc i128 %shifted to i64
 %raw = xor i64 %lo,%hi
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
define i64 @odd_pair_reverse_probe_10(ptr %input,ptr %out,i64 %salt) {
entry:
 %ap0 = getelementptr i8,ptr %input,i64 0
 %p0 = load i64,ptr %ap0,align 1
 %ap1 = getelementptr i8,ptr %input,i64 8
 %p1 = load i64,ptr %ap1,align 1
 %ap2 = getelementptr i8,ptr %input,i64 16
 %p2 = load i64,ptr %ap2,align 1
 %ap3 = getelementptr i8,ptr %input,i64 24
 %p3 = load i64,ptr %ap3,align 1
 %ap4 = getelementptr i8,ptr %input,i64 32
 %p4 = load i64,ptr %ap4,align 1
 %ap5 = getelementptr i8,ptr %input,i64 40
 %p5 = load i64,ptr %ap5,align 1
 %data = getelementptr i8,ptr %input,i64 48
 %a = load i95,ptr %data,align 1
 %answer = call i64 @odd_pair_reverse_body_10(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,i95 %a,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 12
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 20
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 28
 store i64 %p0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @odd_pair_reverse_body_11(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,i95 %a,ptr %out) noinline {
entry:
 %reverse = call i95 @llvm.bitreverse.i95(i95 %a)
 store i95 %reverse,ptr %out,align 1
 %wide = zext i95 %reverse to i128
 %lo = trunc i128 %wide to i64
 %shifted = lshr i128 %wide,64
 %hi = trunc i128 %shifted to i64
 %raw = xor i64 %lo,%hi
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
define i64 @odd_pair_reverse_probe_11(ptr %input,ptr %out,i64 %salt) {
entry:
 %ap0 = getelementptr i8,ptr %input,i64 0
 %p0 = load i64,ptr %ap0,align 1
 %ap1 = getelementptr i8,ptr %input,i64 8
 %p1 = load i64,ptr %ap1,align 1
 %ap2 = getelementptr i8,ptr %input,i64 16
 %p2 = load i64,ptr %ap2,align 1
 %ap3 = getelementptr i8,ptr %input,i64 24
 %p3 = load i64,ptr %ap3,align 1
 %ap4 = getelementptr i8,ptr %input,i64 32
 %p4 = load i64,ptr %ap4,align 1
 %ap5 = getelementptr i8,ptr %input,i64 40
 %p5 = load i64,ptr %ap5,align 1
 %data = getelementptr i8,ptr %input,i64 48
 %a = load i95,ptr %data,align 1
 %answer = call fastcc i64 @odd_pair_reverse_body_11(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,i95 %a,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 12
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 20
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 28
 store i64 %p0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
declare i96 @llvm.bitreverse.i96(i96)
define i64 @odd_pair_reverse_body_12(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,i96 %a,ptr %out) noinline {
entry:
 %reverse = call i96 @llvm.bitreverse.i96(i96 %a)
 store i96 %reverse,ptr %out,align 1
 %wide = zext i96 %reverse to i128
 %lo = trunc i128 %wide to i64
 %shifted = lshr i128 %wide,64
 %hi = trunc i128 %shifted to i64
 %raw = xor i64 %lo,%hi
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
define i64 @odd_pair_reverse_probe_12(ptr %input,ptr %out,i64 %salt) {
entry:
 %ap0 = getelementptr i8,ptr %input,i64 0
 %p0 = load i64,ptr %ap0,align 1
 %ap1 = getelementptr i8,ptr %input,i64 8
 %p1 = load i64,ptr %ap1,align 1
 %ap2 = getelementptr i8,ptr %input,i64 16
 %p2 = load i64,ptr %ap2,align 1
 %ap3 = getelementptr i8,ptr %input,i64 24
 %p3 = load i64,ptr %ap3,align 1
 %ap4 = getelementptr i8,ptr %input,i64 32
 %p4 = load i64,ptr %ap4,align 1
 %ap5 = getelementptr i8,ptr %input,i64 40
 %p5 = load i64,ptr %ap5,align 1
 %data = getelementptr i8,ptr %input,i64 48
 %a = load i96,ptr %data,align 1
 %answer = call i64 @odd_pair_reverse_body_12(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,i96 %a,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 12
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 20
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 28
 store i64 %p0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @odd_pair_reverse_body_13(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,i96 %a,ptr %out) noinline {
entry:
 %reverse = call i96 @llvm.bitreverse.i96(i96 %a)
 store i96 %reverse,ptr %out,align 1
 %wide = zext i96 %reverse to i128
 %lo = trunc i128 %wide to i64
 %shifted = lshr i128 %wide,64
 %hi = trunc i128 %shifted to i64
 %raw = xor i64 %lo,%hi
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
define i64 @odd_pair_reverse_probe_13(ptr %input,ptr %out,i64 %salt) {
entry:
 %ap0 = getelementptr i8,ptr %input,i64 0
 %p0 = load i64,ptr %ap0,align 1
 %ap1 = getelementptr i8,ptr %input,i64 8
 %p1 = load i64,ptr %ap1,align 1
 %ap2 = getelementptr i8,ptr %input,i64 16
 %p2 = load i64,ptr %ap2,align 1
 %ap3 = getelementptr i8,ptr %input,i64 24
 %p3 = load i64,ptr %ap3,align 1
 %ap4 = getelementptr i8,ptr %input,i64 32
 %p4 = load i64,ptr %ap4,align 1
 %ap5 = getelementptr i8,ptr %input,i64 40
 %p5 = load i64,ptr %ap5,align 1
 %data = getelementptr i8,ptr %input,i64 48
 %a = load i96,ptr %data,align 1
 %answer = call fastcc i64 @odd_pair_reverse_body_13(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,i96 %a,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 12
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 20
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 28
 store i64 %p0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
declare i97 @llvm.bitreverse.i97(i97)
define i64 @odd_pair_reverse_body_14(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,i97 %a,ptr %out) noinline {
entry:
 %reverse = call i97 @llvm.bitreverse.i97(i97 %a)
 store i97 %reverse,ptr %out,align 1
 %wide = zext i97 %reverse to i128
 %lo = trunc i128 %wide to i64
 %shifted = lshr i128 %wide,64
 %hi = trunc i128 %shifted to i64
 %raw = xor i64 %lo,%hi
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
define i64 @odd_pair_reverse_probe_14(ptr %input,ptr %out,i64 %salt) {
entry:
 %ap0 = getelementptr i8,ptr %input,i64 0
 %p0 = load i64,ptr %ap0,align 1
 %ap1 = getelementptr i8,ptr %input,i64 8
 %p1 = load i64,ptr %ap1,align 1
 %ap2 = getelementptr i8,ptr %input,i64 16
 %p2 = load i64,ptr %ap2,align 1
 %ap3 = getelementptr i8,ptr %input,i64 24
 %p3 = load i64,ptr %ap3,align 1
 %ap4 = getelementptr i8,ptr %input,i64 32
 %p4 = load i64,ptr %ap4,align 1
 %ap5 = getelementptr i8,ptr %input,i64 40
 %p5 = load i64,ptr %ap5,align 1
 %data = getelementptr i8,ptr %input,i64 48
 %a = load i97,ptr %data,align 1
 %answer = call i64 @odd_pair_reverse_body_14(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,i97 %a,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 13
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 21
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 29
 store i64 %p0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @odd_pair_reverse_body_15(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,i97 %a,ptr %out) noinline {
entry:
 %reverse = call i97 @llvm.bitreverse.i97(i97 %a)
 store i97 %reverse,ptr %out,align 1
 %wide = zext i97 %reverse to i128
 %lo = trunc i128 %wide to i64
 %shifted = lshr i128 %wide,64
 %hi = trunc i128 %shifted to i64
 %raw = xor i64 %lo,%hi
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
define i64 @odd_pair_reverse_probe_15(ptr %input,ptr %out,i64 %salt) {
entry:
 %ap0 = getelementptr i8,ptr %input,i64 0
 %p0 = load i64,ptr %ap0,align 1
 %ap1 = getelementptr i8,ptr %input,i64 8
 %p1 = load i64,ptr %ap1,align 1
 %ap2 = getelementptr i8,ptr %input,i64 16
 %p2 = load i64,ptr %ap2,align 1
 %ap3 = getelementptr i8,ptr %input,i64 24
 %p3 = load i64,ptr %ap3,align 1
 %ap4 = getelementptr i8,ptr %input,i64 32
 %p4 = load i64,ptr %ap4,align 1
 %ap5 = getelementptr i8,ptr %input,i64 40
 %p5 = load i64,ptr %ap5,align 1
 %data = getelementptr i8,ptr %input,i64 48
 %a = load i97,ptr %data,align 1
 %answer = call fastcc i64 @odd_pair_reverse_body_15(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,i97 %a,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 13
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 21
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 29
 store i64 %p0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
declare i111 @llvm.bitreverse.i111(i111)
define i64 @odd_pair_reverse_body_16(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,i111 %a,ptr %out) noinline {
entry:
 %reverse = call i111 @llvm.bitreverse.i111(i111 %a)
 store i111 %reverse,ptr %out,align 1
 %wide = zext i111 %reverse to i128
 %lo = trunc i128 %wide to i64
 %shifted = lshr i128 %wide,64
 %hi = trunc i128 %shifted to i64
 %raw = xor i64 %lo,%hi
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
define i64 @odd_pair_reverse_probe_16(ptr %input,ptr %out,i64 %salt) {
entry:
 %ap0 = getelementptr i8,ptr %input,i64 0
 %p0 = load i64,ptr %ap0,align 1
 %ap1 = getelementptr i8,ptr %input,i64 8
 %p1 = load i64,ptr %ap1,align 1
 %ap2 = getelementptr i8,ptr %input,i64 16
 %p2 = load i64,ptr %ap2,align 1
 %ap3 = getelementptr i8,ptr %input,i64 24
 %p3 = load i64,ptr %ap3,align 1
 %ap4 = getelementptr i8,ptr %input,i64 32
 %p4 = load i64,ptr %ap4,align 1
 %ap5 = getelementptr i8,ptr %input,i64 40
 %p5 = load i64,ptr %ap5,align 1
 %data = getelementptr i8,ptr %input,i64 48
 %a = load i111,ptr %data,align 1
 %answer = call i64 @odd_pair_reverse_body_16(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,i111 %a,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 14
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 22
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 30
 store i64 %p0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @odd_pair_reverse_body_17(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,i111 %a,ptr %out) noinline {
entry:
 %reverse = call i111 @llvm.bitreverse.i111(i111 %a)
 store i111 %reverse,ptr %out,align 1
 %wide = zext i111 %reverse to i128
 %lo = trunc i128 %wide to i64
 %shifted = lshr i128 %wide,64
 %hi = trunc i128 %shifted to i64
 %raw = xor i64 %lo,%hi
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
define i64 @odd_pair_reverse_probe_17(ptr %input,ptr %out,i64 %salt) {
entry:
 %ap0 = getelementptr i8,ptr %input,i64 0
 %p0 = load i64,ptr %ap0,align 1
 %ap1 = getelementptr i8,ptr %input,i64 8
 %p1 = load i64,ptr %ap1,align 1
 %ap2 = getelementptr i8,ptr %input,i64 16
 %p2 = load i64,ptr %ap2,align 1
 %ap3 = getelementptr i8,ptr %input,i64 24
 %p3 = load i64,ptr %ap3,align 1
 %ap4 = getelementptr i8,ptr %input,i64 32
 %p4 = load i64,ptr %ap4,align 1
 %ap5 = getelementptr i8,ptr %input,i64 40
 %p5 = load i64,ptr %ap5,align 1
 %data = getelementptr i8,ptr %input,i64 48
 %a = load i111,ptr %data,align 1
 %answer = call fastcc i64 @odd_pair_reverse_body_17(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,i111 %a,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 14
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 22
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 30
 store i64 %p0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
declare i112 @llvm.bitreverse.i112(i112)
define i64 @odd_pair_reverse_body_18(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,i112 %a,ptr %out) noinline {
entry:
 %reverse = call i112 @llvm.bitreverse.i112(i112 %a)
 store i112 %reverse,ptr %out,align 1
 %wide = zext i112 %reverse to i128
 %lo = trunc i128 %wide to i64
 %shifted = lshr i128 %wide,64
 %hi = trunc i128 %shifted to i64
 %raw = xor i64 %lo,%hi
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
define i64 @odd_pair_reverse_probe_18(ptr %input,ptr %out,i64 %salt) {
entry:
 %ap0 = getelementptr i8,ptr %input,i64 0
 %p0 = load i64,ptr %ap0,align 1
 %ap1 = getelementptr i8,ptr %input,i64 8
 %p1 = load i64,ptr %ap1,align 1
 %ap2 = getelementptr i8,ptr %input,i64 16
 %p2 = load i64,ptr %ap2,align 1
 %ap3 = getelementptr i8,ptr %input,i64 24
 %p3 = load i64,ptr %ap3,align 1
 %ap4 = getelementptr i8,ptr %input,i64 32
 %p4 = load i64,ptr %ap4,align 1
 %ap5 = getelementptr i8,ptr %input,i64 40
 %p5 = load i64,ptr %ap5,align 1
 %data = getelementptr i8,ptr %input,i64 48
 %a = load i112,ptr %data,align 1
 %answer = call i64 @odd_pair_reverse_body_18(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,i112 %a,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 14
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 22
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 30
 store i64 %p0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @odd_pair_reverse_body_19(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,i112 %a,ptr %out) noinline {
entry:
 %reverse = call i112 @llvm.bitreverse.i112(i112 %a)
 store i112 %reverse,ptr %out,align 1
 %wide = zext i112 %reverse to i128
 %lo = trunc i128 %wide to i64
 %shifted = lshr i128 %wide,64
 %hi = trunc i128 %shifted to i64
 %raw = xor i64 %lo,%hi
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
define i64 @odd_pair_reverse_probe_19(ptr %input,ptr %out,i64 %salt) {
entry:
 %ap0 = getelementptr i8,ptr %input,i64 0
 %p0 = load i64,ptr %ap0,align 1
 %ap1 = getelementptr i8,ptr %input,i64 8
 %p1 = load i64,ptr %ap1,align 1
 %ap2 = getelementptr i8,ptr %input,i64 16
 %p2 = load i64,ptr %ap2,align 1
 %ap3 = getelementptr i8,ptr %input,i64 24
 %p3 = load i64,ptr %ap3,align 1
 %ap4 = getelementptr i8,ptr %input,i64 32
 %p4 = load i64,ptr %ap4,align 1
 %ap5 = getelementptr i8,ptr %input,i64 40
 %p5 = load i64,ptr %ap5,align 1
 %data = getelementptr i8,ptr %input,i64 48
 %a = load i112,ptr %data,align 1
 %answer = call fastcc i64 @odd_pair_reverse_body_19(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,i112 %a,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 14
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 22
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 30
 store i64 %p0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
declare i126 @llvm.bitreverse.i126(i126)
define i64 @odd_pair_reverse_body_20(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,i126 %a,ptr %out) noinline {
entry:
 %reverse = call i126 @llvm.bitreverse.i126(i126 %a)
 store i126 %reverse,ptr %out,align 1
 %wide = zext i126 %reverse to i128
 %lo = trunc i128 %wide to i64
 %shifted = lshr i128 %wide,64
 %hi = trunc i128 %shifted to i64
 %raw = xor i64 %lo,%hi
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
define i64 @odd_pair_reverse_probe_20(ptr %input,ptr %out,i64 %salt) {
entry:
 %ap0 = getelementptr i8,ptr %input,i64 0
 %p0 = load i64,ptr %ap0,align 1
 %ap1 = getelementptr i8,ptr %input,i64 8
 %p1 = load i64,ptr %ap1,align 1
 %ap2 = getelementptr i8,ptr %input,i64 16
 %p2 = load i64,ptr %ap2,align 1
 %ap3 = getelementptr i8,ptr %input,i64 24
 %p3 = load i64,ptr %ap3,align 1
 %ap4 = getelementptr i8,ptr %input,i64 32
 %p4 = load i64,ptr %ap4,align 1
 %ap5 = getelementptr i8,ptr %input,i64 40
 %p5 = load i64,ptr %ap5,align 1
 %data = getelementptr i8,ptr %input,i64 48
 %a = load i126,ptr %data,align 1
 %answer = call i64 @odd_pair_reverse_body_20(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,i126 %a,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 16
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 24
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 32
 store i64 %p0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @odd_pair_reverse_body_21(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,i126 %a,ptr %out) noinline {
entry:
 %reverse = call i126 @llvm.bitreverse.i126(i126 %a)
 store i126 %reverse,ptr %out,align 1
 %wide = zext i126 %reverse to i128
 %lo = trunc i128 %wide to i64
 %shifted = lshr i128 %wide,64
 %hi = trunc i128 %shifted to i64
 %raw = xor i64 %lo,%hi
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
define i64 @odd_pair_reverse_probe_21(ptr %input,ptr %out,i64 %salt) {
entry:
 %ap0 = getelementptr i8,ptr %input,i64 0
 %p0 = load i64,ptr %ap0,align 1
 %ap1 = getelementptr i8,ptr %input,i64 8
 %p1 = load i64,ptr %ap1,align 1
 %ap2 = getelementptr i8,ptr %input,i64 16
 %p2 = load i64,ptr %ap2,align 1
 %ap3 = getelementptr i8,ptr %input,i64 24
 %p3 = load i64,ptr %ap3,align 1
 %ap4 = getelementptr i8,ptr %input,i64 32
 %p4 = load i64,ptr %ap4,align 1
 %ap5 = getelementptr i8,ptr %input,i64 40
 %p5 = load i64,ptr %ap5,align 1
 %data = getelementptr i8,ptr %input,i64 48
 %a = load i126,ptr %data,align 1
 %answer = call fastcc i64 @odd_pair_reverse_body_21(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,i126 %a,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 16
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 24
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 32
 store i64 %p0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
declare i127 @llvm.bitreverse.i127(i127)
define i64 @odd_pair_reverse_body_22(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,i127 %a,ptr %out) noinline {
entry:
 %reverse = call i127 @llvm.bitreverse.i127(i127 %a)
 store i127 %reverse,ptr %out,align 1
 %wide = zext i127 %reverse to i128
 %lo = trunc i128 %wide to i64
 %shifted = lshr i128 %wide,64
 %hi = trunc i128 %shifted to i64
 %raw = xor i64 %lo,%hi
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
define i64 @odd_pair_reverse_probe_22(ptr %input,ptr %out,i64 %salt) {
entry:
 %ap0 = getelementptr i8,ptr %input,i64 0
 %p0 = load i64,ptr %ap0,align 1
 %ap1 = getelementptr i8,ptr %input,i64 8
 %p1 = load i64,ptr %ap1,align 1
 %ap2 = getelementptr i8,ptr %input,i64 16
 %p2 = load i64,ptr %ap2,align 1
 %ap3 = getelementptr i8,ptr %input,i64 24
 %p3 = load i64,ptr %ap3,align 1
 %ap4 = getelementptr i8,ptr %input,i64 32
 %p4 = load i64,ptr %ap4,align 1
 %ap5 = getelementptr i8,ptr %input,i64 40
 %p5 = load i64,ptr %ap5,align 1
 %data = getelementptr i8,ptr %input,i64 48
 %a = load i127,ptr %data,align 1
 %answer = call i64 @odd_pair_reverse_body_22(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,i127 %a,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 16
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 24
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 32
 store i64 %p0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @odd_pair_reverse_body_23(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,i127 %a,ptr %out) noinline {
entry:
 %reverse = call i127 @llvm.bitreverse.i127(i127 %a)
 store i127 %reverse,ptr %out,align 1
 %wide = zext i127 %reverse to i128
 %lo = trunc i128 %wide to i64
 %shifted = lshr i128 %wide,64
 %hi = trunc i128 %shifted to i64
 %raw = xor i64 %lo,%hi
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
define i64 @odd_pair_reverse_probe_23(ptr %input,ptr %out,i64 %salt) {
entry:
 %ap0 = getelementptr i8,ptr %input,i64 0
 %p0 = load i64,ptr %ap0,align 1
 %ap1 = getelementptr i8,ptr %input,i64 8
 %p1 = load i64,ptr %ap1,align 1
 %ap2 = getelementptr i8,ptr %input,i64 16
 %p2 = load i64,ptr %ap2,align 1
 %ap3 = getelementptr i8,ptr %input,i64 24
 %p3 = load i64,ptr %ap3,align 1
 %ap4 = getelementptr i8,ptr %input,i64 32
 %p4 = load i64,ptr %ap4,align 1
 %ap5 = getelementptr i8,ptr %input,i64 40
 %p5 = load i64,ptr %ap5,align 1
 %data = getelementptr i8,ptr %input,i64 48
 %a = load i127,ptr %data,align 1
 %answer = call fastcc i64 @odd_pair_reverse_body_23(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,i127 %a,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 16
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 24
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 32
 store i64 %p0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
