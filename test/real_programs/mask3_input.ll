target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"
declare i64 @mask3_input_provider_0(i64,i64,i64,i64,i64,i64,<3 x i1>,<3 x i1>,ptr)
define i64 @mask3_input_body_0(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,<3 x i1> %a,<3 x i1> %b,ptr %out) noinline {
entry:
 %lane0 = extractelement <3 x i1> %a,i32 0
 %v0 = zext i1 %lane0 to i64
 %shift0 = shl i64 %v0,0
 %bits0 = or i64 0,%shift0
 %lane1 = extractelement <3 x i1> %a,i32 1
 %v1 = zext i1 %lane1 to i64
 %shift1 = shl i64 %v1,1
 %bits1 = or i64 %bits0,%shift1
 %lane2 = extractelement <3 x i1> %a,i32 2
 %v2 = zext i1 %lane2 to i64
 %shift2 = shl i64 %v2,2
 %bits2 = or i64 %bits1,%shift2
 %lane3 = extractelement <3 x i1> %b,i32 0
 %v3 = zext i1 %lane3 to i64
 %shift3 = shl i64 %v3,3
 %bits3 = or i64 %bits2,%shift3
 %lane4 = extractelement <3 x i1> %b,i32 1
 %v4 = zext i1 %lane4 to i64
 %shift4 = shl i64 %v4,4
 %bits4 = or i64 %bits3,%shift4
 %lane5 = extractelement <3 x i1> %b,i32 2
 %v5 = zext i1 %lane5 to i64
 %shift5 = shl i64 %v5,5
 %bits5 = or i64 %bits4,%shift5
 %oa = getelementptr i8,ptr %out,i64 24
 %ob = getelementptr i8,ptr %out,i64 25
 store <3 x i1> %a,ptr %oa,align 1
 store <3 x i1> %b,ptr %ob,align 1
 %m0 = mul i64 %bits5,1099511628211
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
define i64 @mask3_input_probe_0(ptr %input,ptr %out,i64 %salt) {
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
 %av = getelementptr i8,ptr %input,i64 48
 %bv = getelementptr i8,ptr %input,i64 49
 %a = load <3 x i1>,ptr %av,align 1
 %b = load <3 x i1>,ptr %bv,align 1
 %answer0 = call i64 @mask3_input_body_0(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,<3 x i1> %a,<3 x i1> %b,ptr %out)
 %answer1 = call i64 @mask3_input_provider_0(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,<3 x i1> %a,<3 x i1> %b,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %answer0,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %answer1,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %p0,ptr %o2,align 1
 %result = xor i64 %answer0,%salt
 ret i64 %result
}
declare fastcc i64 @mask3_input_provider_1(i64,i64,i64,i64,i64,i64,<3 x i1>,<3 x i1>,ptr)
define fastcc i64 @mask3_input_body_1(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,<3 x i1> %a,<3 x i1> %b,ptr %out) noinline {
entry:
 %lane0 = extractelement <3 x i1> %a,i32 0
 %v0 = zext i1 %lane0 to i64
 %shift0 = shl i64 %v0,0
 %bits0 = or i64 0,%shift0
 %lane1 = extractelement <3 x i1> %a,i32 1
 %v1 = zext i1 %lane1 to i64
 %shift1 = shl i64 %v1,1
 %bits1 = or i64 %bits0,%shift1
 %lane2 = extractelement <3 x i1> %a,i32 2
 %v2 = zext i1 %lane2 to i64
 %shift2 = shl i64 %v2,2
 %bits2 = or i64 %bits1,%shift2
 %lane3 = extractelement <3 x i1> %b,i32 0
 %v3 = zext i1 %lane3 to i64
 %shift3 = shl i64 %v3,3
 %bits3 = or i64 %bits2,%shift3
 %lane4 = extractelement <3 x i1> %b,i32 1
 %v4 = zext i1 %lane4 to i64
 %shift4 = shl i64 %v4,4
 %bits4 = or i64 %bits3,%shift4
 %lane5 = extractelement <3 x i1> %b,i32 2
 %v5 = zext i1 %lane5 to i64
 %shift5 = shl i64 %v5,5
 %bits5 = or i64 %bits4,%shift5
 %oa = getelementptr i8,ptr %out,i64 24
 %ob = getelementptr i8,ptr %out,i64 25
 store <3 x i1> %a,ptr %oa,align 1
 store <3 x i1> %b,ptr %ob,align 1
 %m0 = mul i64 %bits5,1099511628211
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
define i64 @mask3_input_probe_1(ptr %input,ptr %out,i64 %salt) {
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
 %av = getelementptr i8,ptr %input,i64 48
 %bv = getelementptr i8,ptr %input,i64 49
 %a = load <3 x i1>,ptr %av,align 1
 %b = load <3 x i1>,ptr %bv,align 1
 %answer0 = call fastcc i64 @mask3_input_body_1(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,<3 x i1> %a,<3 x i1> %b,ptr %out)
 %answer1 = call fastcc i64 @mask3_input_provider_1(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,<3 x i1> %a,<3 x i1> %b,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %answer0,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %answer1,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %p0,ptr %o2,align 1
 %result = xor i64 %answer0,%salt
 ret i64 %result
}
declare i64 @mask3_input_provider_2(<3 x i1>,<3 x i1>,i64,i64,i64,i64,i64,i64,ptr)
define i64 @mask3_input_body_2(<3 x i1> %a,<3 x i1> %b,i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %lane0 = extractelement <3 x i1> %a,i32 0
 %v0 = zext i1 %lane0 to i64
 %shift0 = shl i64 %v0,0
 %bits0 = or i64 0,%shift0
 %lane1 = extractelement <3 x i1> %a,i32 1
 %v1 = zext i1 %lane1 to i64
 %shift1 = shl i64 %v1,1
 %bits1 = or i64 %bits0,%shift1
 %lane2 = extractelement <3 x i1> %a,i32 2
 %v2 = zext i1 %lane2 to i64
 %shift2 = shl i64 %v2,2
 %bits2 = or i64 %bits1,%shift2
 %lane3 = extractelement <3 x i1> %b,i32 0
 %v3 = zext i1 %lane3 to i64
 %shift3 = shl i64 %v3,3
 %bits3 = or i64 %bits2,%shift3
 %lane4 = extractelement <3 x i1> %b,i32 1
 %v4 = zext i1 %lane4 to i64
 %shift4 = shl i64 %v4,4
 %bits4 = or i64 %bits3,%shift4
 %lane5 = extractelement <3 x i1> %b,i32 2
 %v5 = zext i1 %lane5 to i64
 %shift5 = shl i64 %v5,5
 %bits5 = or i64 %bits4,%shift5
 %oa = getelementptr i8,ptr %out,i64 24
 %ob = getelementptr i8,ptr %out,i64 25
 store <3 x i1> %a,ptr %oa,align 1
 store <3 x i1> %b,ptr %ob,align 1
 %m0 = mul i64 %bits5,1099511628211
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
define i64 @mask3_input_probe_2(ptr %input,ptr %out,i64 %salt) {
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
 %av = getelementptr i8,ptr %input,i64 48
 %bv = getelementptr i8,ptr %input,i64 49
 %a = load <3 x i1>,ptr %av,align 1
 %b = load <3 x i1>,ptr %bv,align 1
 %answer0 = call i64 @mask3_input_body_2(<3 x i1> %a,<3 x i1> %b,i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out)
 %answer1 = call i64 @mask3_input_provider_2(<3 x i1> %a,<3 x i1> %b,i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %answer0,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %answer1,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %p0,ptr %o2,align 1
 %result = xor i64 %answer0,%salt
 ret i64 %result
}
declare fastcc i64 @mask3_input_provider_3(<3 x i1>,<3 x i1>,i64,i64,i64,i64,i64,i64,ptr)
define fastcc i64 @mask3_input_body_3(<3 x i1> %a,<3 x i1> %b,i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %lane0 = extractelement <3 x i1> %a,i32 0
 %v0 = zext i1 %lane0 to i64
 %shift0 = shl i64 %v0,0
 %bits0 = or i64 0,%shift0
 %lane1 = extractelement <3 x i1> %a,i32 1
 %v1 = zext i1 %lane1 to i64
 %shift1 = shl i64 %v1,1
 %bits1 = or i64 %bits0,%shift1
 %lane2 = extractelement <3 x i1> %a,i32 2
 %v2 = zext i1 %lane2 to i64
 %shift2 = shl i64 %v2,2
 %bits2 = or i64 %bits1,%shift2
 %lane3 = extractelement <3 x i1> %b,i32 0
 %v3 = zext i1 %lane3 to i64
 %shift3 = shl i64 %v3,3
 %bits3 = or i64 %bits2,%shift3
 %lane4 = extractelement <3 x i1> %b,i32 1
 %v4 = zext i1 %lane4 to i64
 %shift4 = shl i64 %v4,4
 %bits4 = or i64 %bits3,%shift4
 %lane5 = extractelement <3 x i1> %b,i32 2
 %v5 = zext i1 %lane5 to i64
 %shift5 = shl i64 %v5,5
 %bits5 = or i64 %bits4,%shift5
 %oa = getelementptr i8,ptr %out,i64 24
 %ob = getelementptr i8,ptr %out,i64 25
 store <3 x i1> %a,ptr %oa,align 1
 store <3 x i1> %b,ptr %ob,align 1
 %m0 = mul i64 %bits5,1099511628211
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
define i64 @mask3_input_probe_3(ptr %input,ptr %out,i64 %salt) {
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
 %av = getelementptr i8,ptr %input,i64 48
 %bv = getelementptr i8,ptr %input,i64 49
 %a = load <3 x i1>,ptr %av,align 1
 %b = load <3 x i1>,ptr %bv,align 1
 %answer0 = call fastcc i64 @mask3_input_body_3(<3 x i1> %a,<3 x i1> %b,i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out)
 %answer1 = call fastcc i64 @mask3_input_provider_3(<3 x i1> %a,<3 x i1> %b,i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %answer0,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %answer1,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %p0,ptr %o2,align 1
 %result = xor i64 %answer0,%salt
 ret i64 %result
}
