target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"
define i64 @pointer_constants_body_0(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out) noinline {
entry:
 %a = load <1 x i64>,ptr %input,align 1
 %p = inttoptr <1 x i64> %a to <1 x ptr>
 %bits = ptrtoint <1 x ptr> %p to <1 x i64>
 store <1 x i64> %bits,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 8
 store <1 x ptr> <ptr null>,ptr %out1,align 1
 %insert0 = insertelement <1 x ptr> poison,ptr null,i32 0
 %out2 = getelementptr i8,ptr %out,i64 16
 store <1 x ptr> %insert0,ptr %out2,align 1
 %m0 = mul i64 0,1099511628211
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
define i64 @pointer_constants_probe_0(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @pointer_constants_body_0(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %data,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 24
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 32
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 40
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @pointer_constants_body_1(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out) noinline {
entry:
 %a = load <1 x i64>,ptr %input,align 1
 %p = inttoptr <1 x i64> %a to <1 x ptr>
 %bits = ptrtoint <1 x ptr> %p to <1 x i64>
 store <1 x i64> %bits,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 8
 store <1 x ptr> <ptr null>,ptr %out1,align 1
 %insert0 = insertelement <1 x ptr> poison,ptr null,i32 0
 %out2 = getelementptr i8,ptr %out,i64 16
 store <1 x ptr> %insert0,ptr %out2,align 1
 %m0 = mul i64 0,1099511628211
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
define i64 @pointer_constants_probe_1(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @pointer_constants_body_1(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %data,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 24
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 32
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 40
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define i64 @pointer_constants_body_2(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out) noinline {
entry:
 %a = load <2 x i64>,ptr %input,align 1
 %p = inttoptr <2 x i64> %a to <2 x ptr>
 %bits = ptrtoint <2 x ptr> %p to <2 x i64>
 store <2 x i64> %bits,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x ptr> <ptr null,ptr inttoptr (i64 1 to ptr)>,ptr %out1,align 1
 %insert0 = insertelement <2 x ptr> poison,ptr inttoptr (i64 1 to ptr),i32 1
 %insert1 = insertelement <2 x ptr> %insert0,ptr null,i32 0
 %out2 = getelementptr i8,ptr %out,i64 32
 store <2 x ptr> %insert1,ptr %out2,align 1
 %m0 = mul i64 0,1099511628211
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
define i64 @pointer_constants_probe_2(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @pointer_constants_body_2(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %data,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 48
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 56
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 64
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @pointer_constants_body_3(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out) noinline {
entry:
 %a = load <2 x i64>,ptr %input,align 1
 %p = inttoptr <2 x i64> %a to <2 x ptr>
 %bits = ptrtoint <2 x ptr> %p to <2 x i64>
 store <2 x i64> %bits,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x ptr> <ptr null,ptr inttoptr (i64 1 to ptr)>,ptr %out1,align 1
 %insert0 = insertelement <2 x ptr> poison,ptr inttoptr (i64 1 to ptr),i32 1
 %insert1 = insertelement <2 x ptr> %insert0,ptr null,i32 0
 %out2 = getelementptr i8,ptr %out,i64 32
 store <2 x ptr> %insert1,ptr %out2,align 1
 %m0 = mul i64 0,1099511628211
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
define i64 @pointer_constants_probe_3(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @pointer_constants_body_3(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %data,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 48
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 56
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 64
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define i64 @pointer_constants_body_4(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out) noinline {
entry:
 %a = load <3 x i64>,ptr %input,align 1
 %p = inttoptr <3 x i64> %a to <3 x ptr>
 %bits = ptrtoint <3 x ptr> %p to <3 x i64>
 store <3 x i64> %bits,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 24
 store <3 x ptr> <ptr null,ptr inttoptr (i64 1 to ptr),ptr inttoptr (i64 -1 to ptr)>,ptr %out1,align 1
 %insert0 = insertelement <3 x ptr> poison,ptr inttoptr (i64 -1 to ptr),i32 2
 %insert1 = insertelement <3 x ptr> %insert0,ptr inttoptr (i64 1 to ptr),i32 1
 %insert2 = insertelement <3 x ptr> %insert1,ptr null,i32 0
 %out2 = getelementptr i8,ptr %out,i64 48
 store <3 x ptr> %insert2,ptr %out2,align 1
 %m0 = mul i64 0,1099511628211
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
define i64 @pointer_constants_probe_4(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @pointer_constants_body_4(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %data,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 72
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 80
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 88
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @pointer_constants_body_5(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out) noinline {
entry:
 %a = load <3 x i64>,ptr %input,align 1
 %p = inttoptr <3 x i64> %a to <3 x ptr>
 %bits = ptrtoint <3 x ptr> %p to <3 x i64>
 store <3 x i64> %bits,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 24
 store <3 x ptr> <ptr null,ptr inttoptr (i64 1 to ptr),ptr inttoptr (i64 -1 to ptr)>,ptr %out1,align 1
 %insert0 = insertelement <3 x ptr> poison,ptr inttoptr (i64 -1 to ptr),i32 2
 %insert1 = insertelement <3 x ptr> %insert0,ptr inttoptr (i64 1 to ptr),i32 1
 %insert2 = insertelement <3 x ptr> %insert1,ptr null,i32 0
 %out2 = getelementptr i8,ptr %out,i64 48
 store <3 x ptr> %insert2,ptr %out2,align 1
 %m0 = mul i64 0,1099511628211
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
define i64 @pointer_constants_probe_5(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @pointer_constants_body_5(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %data,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 72
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 80
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 88
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define i64 @pointer_constants_body_6(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out) noinline {
entry:
 %a = load <4 x i64>,ptr %input,align 1
 %p = inttoptr <4 x i64> %a to <4 x ptr>
 %bits = ptrtoint <4 x ptr> %p to <4 x i64>
 store <4 x i64> %bits,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 32
 store <4 x ptr> <ptr null,ptr inttoptr (i64 1 to ptr),ptr inttoptr (i64 -1 to ptr),ptr inttoptr (i64 9223372036854775808 to ptr)>,ptr %out1,align 1
 %insert0 = insertelement <4 x ptr> poison,ptr inttoptr (i64 9223372036854775808 to ptr),i32 3
 %insert1 = insertelement <4 x ptr> %insert0,ptr inttoptr (i64 -1 to ptr),i32 2
 %insert2 = insertelement <4 x ptr> %insert1,ptr inttoptr (i64 1 to ptr),i32 1
 %insert3 = insertelement <4 x ptr> %insert2,ptr null,i32 0
 %out2 = getelementptr i8,ptr %out,i64 64
 store <4 x ptr> %insert3,ptr %out2,align 1
 %m0 = mul i64 0,1099511628211
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
define i64 @pointer_constants_probe_6(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @pointer_constants_body_6(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %data,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 96
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 104
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 112
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @pointer_constants_body_7(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out) noinline {
entry:
 %a = load <4 x i64>,ptr %input,align 1
 %p = inttoptr <4 x i64> %a to <4 x ptr>
 %bits = ptrtoint <4 x ptr> %p to <4 x i64>
 store <4 x i64> %bits,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 32
 store <4 x ptr> <ptr null,ptr inttoptr (i64 1 to ptr),ptr inttoptr (i64 -1 to ptr),ptr inttoptr (i64 9223372036854775808 to ptr)>,ptr %out1,align 1
 %insert0 = insertelement <4 x ptr> poison,ptr inttoptr (i64 9223372036854775808 to ptr),i32 3
 %insert1 = insertelement <4 x ptr> %insert0,ptr inttoptr (i64 -1 to ptr),i32 2
 %insert2 = insertelement <4 x ptr> %insert1,ptr inttoptr (i64 1 to ptr),i32 1
 %insert3 = insertelement <4 x ptr> %insert2,ptr null,i32 0
 %out2 = getelementptr i8,ptr %out,i64 64
 store <4 x ptr> %insert3,ptr %out2,align 1
 %m0 = mul i64 0,1099511628211
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
define i64 @pointer_constants_probe_7(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @pointer_constants_body_7(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %data,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 96
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 104
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 112
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define i64 @pointer_constants_body_8(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out) noinline {
entry:
 %a = load <8 x i64>,ptr %input,align 1
 %p = inttoptr <8 x i64> %a to <8 x ptr>
 %bits = ptrtoint <8 x ptr> %p to <8 x i64>
 store <8 x i64> %bits,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 64
 store <8 x ptr> <ptr null,ptr inttoptr (i64 1 to ptr),ptr inttoptr (i64 -1 to ptr),ptr inttoptr (i64 9223372036854775808 to ptr),ptr inttoptr (i64 4294967295 to ptr),ptr inttoptr (i64 1311768467463790320 to ptr),ptr null,ptr inttoptr (i64 1 to ptr)>,ptr %out1,align 1
 %insert0 = insertelement <8 x ptr> poison,ptr inttoptr (i64 1 to ptr),i32 7
 %insert1 = insertelement <8 x ptr> %insert0,ptr null,i32 6
 %insert2 = insertelement <8 x ptr> %insert1,ptr inttoptr (i64 1311768467463790320 to ptr),i32 5
 %insert3 = insertelement <8 x ptr> %insert2,ptr inttoptr (i64 4294967295 to ptr),i32 4
 %insert4 = insertelement <8 x ptr> %insert3,ptr inttoptr (i64 9223372036854775808 to ptr),i32 3
 %insert5 = insertelement <8 x ptr> %insert4,ptr inttoptr (i64 -1 to ptr),i32 2
 %insert6 = insertelement <8 x ptr> %insert5,ptr inttoptr (i64 1 to ptr),i32 1
 %insert7 = insertelement <8 x ptr> %insert6,ptr null,i32 0
 %out2 = getelementptr i8,ptr %out,i64 128
 store <8 x ptr> %insert7,ptr %out2,align 1
 %m0 = mul i64 0,1099511628211
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
define i64 @pointer_constants_probe_8(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @pointer_constants_body_8(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %data,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 192
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 200
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 208
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @pointer_constants_body_9(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out) noinline {
entry:
 %a = load <8 x i64>,ptr %input,align 1
 %p = inttoptr <8 x i64> %a to <8 x ptr>
 %bits = ptrtoint <8 x ptr> %p to <8 x i64>
 store <8 x i64> %bits,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 64
 store <8 x ptr> <ptr null,ptr inttoptr (i64 1 to ptr),ptr inttoptr (i64 -1 to ptr),ptr inttoptr (i64 9223372036854775808 to ptr),ptr inttoptr (i64 4294967295 to ptr),ptr inttoptr (i64 1311768467463790320 to ptr),ptr null,ptr inttoptr (i64 1 to ptr)>,ptr %out1,align 1
 %insert0 = insertelement <8 x ptr> poison,ptr inttoptr (i64 1 to ptr),i32 7
 %insert1 = insertelement <8 x ptr> %insert0,ptr null,i32 6
 %insert2 = insertelement <8 x ptr> %insert1,ptr inttoptr (i64 1311768467463790320 to ptr),i32 5
 %insert3 = insertelement <8 x ptr> %insert2,ptr inttoptr (i64 4294967295 to ptr),i32 4
 %insert4 = insertelement <8 x ptr> %insert3,ptr inttoptr (i64 9223372036854775808 to ptr),i32 3
 %insert5 = insertelement <8 x ptr> %insert4,ptr inttoptr (i64 -1 to ptr),i32 2
 %insert6 = insertelement <8 x ptr> %insert5,ptr inttoptr (i64 1 to ptr),i32 1
 %insert7 = insertelement <8 x ptr> %insert6,ptr null,i32 0
 %out2 = getelementptr i8,ptr %out,i64 128
 store <8 x ptr> %insert7,ptr %out2,align 1
 %m0 = mul i64 0,1099511628211
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
define i64 @pointer_constants_probe_9(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @pointer_constants_body_9(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %data,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 192
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 200
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 208
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define i64 @pointer_constants_body_10(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out) noinline {
entry:
 %a = load <16 x i64>,ptr %input,align 1
 %p = inttoptr <16 x i64> %a to <16 x ptr>
 %bits = ptrtoint <16 x ptr> %p to <16 x i64>
 store <16 x i64> %bits,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 128
 store <16 x ptr> <ptr null,ptr inttoptr (i64 1 to ptr),ptr inttoptr (i64 -1 to ptr),ptr inttoptr (i64 9223372036854775808 to ptr),ptr inttoptr (i64 4294967295 to ptr),ptr inttoptr (i64 1311768467463790320 to ptr),ptr null,ptr inttoptr (i64 1 to ptr),ptr inttoptr (i64 -1 to ptr),ptr inttoptr (i64 9223372036854775808 to ptr),ptr inttoptr (i64 4294967295 to ptr),ptr inttoptr (i64 1311768467463790320 to ptr),ptr null,ptr inttoptr (i64 1 to ptr),ptr inttoptr (i64 -1 to ptr),ptr inttoptr (i64 9223372036854775808 to ptr)>,ptr %out1,align 1
 %insert0 = insertelement <16 x ptr> poison,ptr inttoptr (i64 9223372036854775808 to ptr),i32 15
 %insert1 = insertelement <16 x ptr> %insert0,ptr inttoptr (i64 -1 to ptr),i32 14
 %insert2 = insertelement <16 x ptr> %insert1,ptr inttoptr (i64 1 to ptr),i32 13
 %insert3 = insertelement <16 x ptr> %insert2,ptr null,i32 12
 %insert4 = insertelement <16 x ptr> %insert3,ptr inttoptr (i64 1311768467463790320 to ptr),i32 11
 %insert5 = insertelement <16 x ptr> %insert4,ptr inttoptr (i64 4294967295 to ptr),i32 10
 %insert6 = insertelement <16 x ptr> %insert5,ptr inttoptr (i64 9223372036854775808 to ptr),i32 9
 %insert7 = insertelement <16 x ptr> %insert6,ptr inttoptr (i64 -1 to ptr),i32 8
 %insert8 = insertelement <16 x ptr> %insert7,ptr inttoptr (i64 1 to ptr),i32 7
 %insert9 = insertelement <16 x ptr> %insert8,ptr null,i32 6
 %insert10 = insertelement <16 x ptr> %insert9,ptr inttoptr (i64 1311768467463790320 to ptr),i32 5
 %insert11 = insertelement <16 x ptr> %insert10,ptr inttoptr (i64 4294967295 to ptr),i32 4
 %insert12 = insertelement <16 x ptr> %insert11,ptr inttoptr (i64 9223372036854775808 to ptr),i32 3
 %insert13 = insertelement <16 x ptr> %insert12,ptr inttoptr (i64 -1 to ptr),i32 2
 %insert14 = insertelement <16 x ptr> %insert13,ptr inttoptr (i64 1 to ptr),i32 1
 %insert15 = insertelement <16 x ptr> %insert14,ptr null,i32 0
 %out2 = getelementptr i8,ptr %out,i64 256
 store <16 x ptr> %insert15,ptr %out2,align 1
 %m0 = mul i64 0,1099511628211
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
define i64 @pointer_constants_probe_10(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @pointer_constants_body_10(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %data,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 384
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 392
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 400
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @pointer_constants_body_11(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out) noinline {
entry:
 %a = load <16 x i64>,ptr %input,align 1
 %p = inttoptr <16 x i64> %a to <16 x ptr>
 %bits = ptrtoint <16 x ptr> %p to <16 x i64>
 store <16 x i64> %bits,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 128
 store <16 x ptr> <ptr null,ptr inttoptr (i64 1 to ptr),ptr inttoptr (i64 -1 to ptr),ptr inttoptr (i64 9223372036854775808 to ptr),ptr inttoptr (i64 4294967295 to ptr),ptr inttoptr (i64 1311768467463790320 to ptr),ptr null,ptr inttoptr (i64 1 to ptr),ptr inttoptr (i64 -1 to ptr),ptr inttoptr (i64 9223372036854775808 to ptr),ptr inttoptr (i64 4294967295 to ptr),ptr inttoptr (i64 1311768467463790320 to ptr),ptr null,ptr inttoptr (i64 1 to ptr),ptr inttoptr (i64 -1 to ptr),ptr inttoptr (i64 9223372036854775808 to ptr)>,ptr %out1,align 1
 %insert0 = insertelement <16 x ptr> poison,ptr inttoptr (i64 9223372036854775808 to ptr),i32 15
 %insert1 = insertelement <16 x ptr> %insert0,ptr inttoptr (i64 -1 to ptr),i32 14
 %insert2 = insertelement <16 x ptr> %insert1,ptr inttoptr (i64 1 to ptr),i32 13
 %insert3 = insertelement <16 x ptr> %insert2,ptr null,i32 12
 %insert4 = insertelement <16 x ptr> %insert3,ptr inttoptr (i64 1311768467463790320 to ptr),i32 11
 %insert5 = insertelement <16 x ptr> %insert4,ptr inttoptr (i64 4294967295 to ptr),i32 10
 %insert6 = insertelement <16 x ptr> %insert5,ptr inttoptr (i64 9223372036854775808 to ptr),i32 9
 %insert7 = insertelement <16 x ptr> %insert6,ptr inttoptr (i64 -1 to ptr),i32 8
 %insert8 = insertelement <16 x ptr> %insert7,ptr inttoptr (i64 1 to ptr),i32 7
 %insert9 = insertelement <16 x ptr> %insert8,ptr null,i32 6
 %insert10 = insertelement <16 x ptr> %insert9,ptr inttoptr (i64 1311768467463790320 to ptr),i32 5
 %insert11 = insertelement <16 x ptr> %insert10,ptr inttoptr (i64 4294967295 to ptr),i32 4
 %insert12 = insertelement <16 x ptr> %insert11,ptr inttoptr (i64 9223372036854775808 to ptr),i32 3
 %insert13 = insertelement <16 x ptr> %insert12,ptr inttoptr (i64 -1 to ptr),i32 2
 %insert14 = insertelement <16 x ptr> %insert13,ptr inttoptr (i64 1 to ptr),i32 1
 %insert15 = insertelement <16 x ptr> %insert14,ptr null,i32 0
 %out2 = getelementptr i8,ptr %out,i64 256
 store <16 x ptr> %insert15,ptr %out2,align 1
 %m0 = mul i64 0,1099511628211
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
define i64 @pointer_constants_probe_11(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @pointer_constants_body_11(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %data,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 384
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 392
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 400
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define i64 @pointer_constants_body_12(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out) noinline {
entry:
 %a = load <32 x i64>,ptr %input,align 1
 %p = inttoptr <32 x i64> %a to <32 x ptr>
 %bits = ptrtoint <32 x ptr> %p to <32 x i64>
 store <32 x i64> %bits,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 256
 store <32 x ptr> <ptr null,ptr inttoptr (i64 1 to ptr),ptr inttoptr (i64 -1 to ptr),ptr inttoptr (i64 9223372036854775808 to ptr),ptr inttoptr (i64 4294967295 to ptr),ptr inttoptr (i64 1311768467463790320 to ptr),ptr null,ptr inttoptr (i64 1 to ptr),ptr inttoptr (i64 -1 to ptr),ptr inttoptr (i64 9223372036854775808 to ptr),ptr inttoptr (i64 4294967295 to ptr),ptr inttoptr (i64 1311768467463790320 to ptr),ptr null,ptr inttoptr (i64 1 to ptr),ptr inttoptr (i64 -1 to ptr),ptr inttoptr (i64 9223372036854775808 to ptr),ptr inttoptr (i64 4294967295 to ptr),ptr inttoptr (i64 1311768467463790320 to ptr),ptr null,ptr inttoptr (i64 1 to ptr),ptr inttoptr (i64 -1 to ptr),ptr inttoptr (i64 9223372036854775808 to ptr),ptr inttoptr (i64 4294967295 to ptr),ptr inttoptr (i64 1311768467463790320 to ptr),ptr null,ptr inttoptr (i64 1 to ptr),ptr inttoptr (i64 -1 to ptr),ptr inttoptr (i64 9223372036854775808 to ptr),ptr inttoptr (i64 4294967295 to ptr),ptr inttoptr (i64 1311768467463790320 to ptr),ptr null,ptr inttoptr (i64 1 to ptr)>,ptr %out1,align 1
 %insert0 = insertelement <32 x ptr> poison,ptr inttoptr (i64 1 to ptr),i32 31
 %insert1 = insertelement <32 x ptr> %insert0,ptr null,i32 30
 %insert2 = insertelement <32 x ptr> %insert1,ptr inttoptr (i64 1311768467463790320 to ptr),i32 29
 %insert3 = insertelement <32 x ptr> %insert2,ptr inttoptr (i64 4294967295 to ptr),i32 28
 %insert4 = insertelement <32 x ptr> %insert3,ptr inttoptr (i64 9223372036854775808 to ptr),i32 27
 %insert5 = insertelement <32 x ptr> %insert4,ptr inttoptr (i64 -1 to ptr),i32 26
 %insert6 = insertelement <32 x ptr> %insert5,ptr inttoptr (i64 1 to ptr),i32 25
 %insert7 = insertelement <32 x ptr> %insert6,ptr null,i32 24
 %insert8 = insertelement <32 x ptr> %insert7,ptr inttoptr (i64 1311768467463790320 to ptr),i32 23
 %insert9 = insertelement <32 x ptr> %insert8,ptr inttoptr (i64 4294967295 to ptr),i32 22
 %insert10 = insertelement <32 x ptr> %insert9,ptr inttoptr (i64 9223372036854775808 to ptr),i32 21
 %insert11 = insertelement <32 x ptr> %insert10,ptr inttoptr (i64 -1 to ptr),i32 20
 %insert12 = insertelement <32 x ptr> %insert11,ptr inttoptr (i64 1 to ptr),i32 19
 %insert13 = insertelement <32 x ptr> %insert12,ptr null,i32 18
 %insert14 = insertelement <32 x ptr> %insert13,ptr inttoptr (i64 1311768467463790320 to ptr),i32 17
 %insert15 = insertelement <32 x ptr> %insert14,ptr inttoptr (i64 4294967295 to ptr),i32 16
 %insert16 = insertelement <32 x ptr> %insert15,ptr inttoptr (i64 9223372036854775808 to ptr),i32 15
 %insert17 = insertelement <32 x ptr> %insert16,ptr inttoptr (i64 -1 to ptr),i32 14
 %insert18 = insertelement <32 x ptr> %insert17,ptr inttoptr (i64 1 to ptr),i32 13
 %insert19 = insertelement <32 x ptr> %insert18,ptr null,i32 12
 %insert20 = insertelement <32 x ptr> %insert19,ptr inttoptr (i64 1311768467463790320 to ptr),i32 11
 %insert21 = insertelement <32 x ptr> %insert20,ptr inttoptr (i64 4294967295 to ptr),i32 10
 %insert22 = insertelement <32 x ptr> %insert21,ptr inttoptr (i64 9223372036854775808 to ptr),i32 9
 %insert23 = insertelement <32 x ptr> %insert22,ptr inttoptr (i64 -1 to ptr),i32 8
 %insert24 = insertelement <32 x ptr> %insert23,ptr inttoptr (i64 1 to ptr),i32 7
 %insert25 = insertelement <32 x ptr> %insert24,ptr null,i32 6
 %insert26 = insertelement <32 x ptr> %insert25,ptr inttoptr (i64 1311768467463790320 to ptr),i32 5
 %insert27 = insertelement <32 x ptr> %insert26,ptr inttoptr (i64 4294967295 to ptr),i32 4
 %insert28 = insertelement <32 x ptr> %insert27,ptr inttoptr (i64 9223372036854775808 to ptr),i32 3
 %insert29 = insertelement <32 x ptr> %insert28,ptr inttoptr (i64 -1 to ptr),i32 2
 %insert30 = insertelement <32 x ptr> %insert29,ptr inttoptr (i64 1 to ptr),i32 1
 %insert31 = insertelement <32 x ptr> %insert30,ptr null,i32 0
 %out2 = getelementptr i8,ptr %out,i64 512
 store <32 x ptr> %insert31,ptr %out2,align 1
 %m0 = mul i64 0,1099511628211
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
define i64 @pointer_constants_probe_12(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @pointer_constants_body_12(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %data,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 768
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 776
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 784
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @pointer_constants_body_13(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out) noinline {
entry:
 %a = load <32 x i64>,ptr %input,align 1
 %p = inttoptr <32 x i64> %a to <32 x ptr>
 %bits = ptrtoint <32 x ptr> %p to <32 x i64>
 store <32 x i64> %bits,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 256
 store <32 x ptr> <ptr null,ptr inttoptr (i64 1 to ptr),ptr inttoptr (i64 -1 to ptr),ptr inttoptr (i64 9223372036854775808 to ptr),ptr inttoptr (i64 4294967295 to ptr),ptr inttoptr (i64 1311768467463790320 to ptr),ptr null,ptr inttoptr (i64 1 to ptr),ptr inttoptr (i64 -1 to ptr),ptr inttoptr (i64 9223372036854775808 to ptr),ptr inttoptr (i64 4294967295 to ptr),ptr inttoptr (i64 1311768467463790320 to ptr),ptr null,ptr inttoptr (i64 1 to ptr),ptr inttoptr (i64 -1 to ptr),ptr inttoptr (i64 9223372036854775808 to ptr),ptr inttoptr (i64 4294967295 to ptr),ptr inttoptr (i64 1311768467463790320 to ptr),ptr null,ptr inttoptr (i64 1 to ptr),ptr inttoptr (i64 -1 to ptr),ptr inttoptr (i64 9223372036854775808 to ptr),ptr inttoptr (i64 4294967295 to ptr),ptr inttoptr (i64 1311768467463790320 to ptr),ptr null,ptr inttoptr (i64 1 to ptr),ptr inttoptr (i64 -1 to ptr),ptr inttoptr (i64 9223372036854775808 to ptr),ptr inttoptr (i64 4294967295 to ptr),ptr inttoptr (i64 1311768467463790320 to ptr),ptr null,ptr inttoptr (i64 1 to ptr)>,ptr %out1,align 1
 %insert0 = insertelement <32 x ptr> poison,ptr inttoptr (i64 1 to ptr),i32 31
 %insert1 = insertelement <32 x ptr> %insert0,ptr null,i32 30
 %insert2 = insertelement <32 x ptr> %insert1,ptr inttoptr (i64 1311768467463790320 to ptr),i32 29
 %insert3 = insertelement <32 x ptr> %insert2,ptr inttoptr (i64 4294967295 to ptr),i32 28
 %insert4 = insertelement <32 x ptr> %insert3,ptr inttoptr (i64 9223372036854775808 to ptr),i32 27
 %insert5 = insertelement <32 x ptr> %insert4,ptr inttoptr (i64 -1 to ptr),i32 26
 %insert6 = insertelement <32 x ptr> %insert5,ptr inttoptr (i64 1 to ptr),i32 25
 %insert7 = insertelement <32 x ptr> %insert6,ptr null,i32 24
 %insert8 = insertelement <32 x ptr> %insert7,ptr inttoptr (i64 1311768467463790320 to ptr),i32 23
 %insert9 = insertelement <32 x ptr> %insert8,ptr inttoptr (i64 4294967295 to ptr),i32 22
 %insert10 = insertelement <32 x ptr> %insert9,ptr inttoptr (i64 9223372036854775808 to ptr),i32 21
 %insert11 = insertelement <32 x ptr> %insert10,ptr inttoptr (i64 -1 to ptr),i32 20
 %insert12 = insertelement <32 x ptr> %insert11,ptr inttoptr (i64 1 to ptr),i32 19
 %insert13 = insertelement <32 x ptr> %insert12,ptr null,i32 18
 %insert14 = insertelement <32 x ptr> %insert13,ptr inttoptr (i64 1311768467463790320 to ptr),i32 17
 %insert15 = insertelement <32 x ptr> %insert14,ptr inttoptr (i64 4294967295 to ptr),i32 16
 %insert16 = insertelement <32 x ptr> %insert15,ptr inttoptr (i64 9223372036854775808 to ptr),i32 15
 %insert17 = insertelement <32 x ptr> %insert16,ptr inttoptr (i64 -1 to ptr),i32 14
 %insert18 = insertelement <32 x ptr> %insert17,ptr inttoptr (i64 1 to ptr),i32 13
 %insert19 = insertelement <32 x ptr> %insert18,ptr null,i32 12
 %insert20 = insertelement <32 x ptr> %insert19,ptr inttoptr (i64 1311768467463790320 to ptr),i32 11
 %insert21 = insertelement <32 x ptr> %insert20,ptr inttoptr (i64 4294967295 to ptr),i32 10
 %insert22 = insertelement <32 x ptr> %insert21,ptr inttoptr (i64 9223372036854775808 to ptr),i32 9
 %insert23 = insertelement <32 x ptr> %insert22,ptr inttoptr (i64 -1 to ptr),i32 8
 %insert24 = insertelement <32 x ptr> %insert23,ptr inttoptr (i64 1 to ptr),i32 7
 %insert25 = insertelement <32 x ptr> %insert24,ptr null,i32 6
 %insert26 = insertelement <32 x ptr> %insert25,ptr inttoptr (i64 1311768467463790320 to ptr),i32 5
 %insert27 = insertelement <32 x ptr> %insert26,ptr inttoptr (i64 4294967295 to ptr),i32 4
 %insert28 = insertelement <32 x ptr> %insert27,ptr inttoptr (i64 9223372036854775808 to ptr),i32 3
 %insert29 = insertelement <32 x ptr> %insert28,ptr inttoptr (i64 -1 to ptr),i32 2
 %insert30 = insertelement <32 x ptr> %insert29,ptr inttoptr (i64 1 to ptr),i32 1
 %insert31 = insertelement <32 x ptr> %insert30,ptr null,i32 0
 %out2 = getelementptr i8,ptr %out,i64 512
 store <32 x ptr> %insert31,ptr %out2,align 1
 %m0 = mul i64 0,1099511628211
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
define i64 @pointer_constants_probe_13(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @pointer_constants_body_13(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %data,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 768
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 776
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 784
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define i64 @pointer_constants_body_14(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out) noinline {
entry:
 %a = load <64 x i64>,ptr %input,align 1
 %p = inttoptr <64 x i64> %a to <64 x ptr>
 %bits = ptrtoint <64 x ptr> %p to <64 x i64>
 store <64 x i64> %bits,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 512
 store <64 x ptr> <ptr null,ptr inttoptr (i64 1 to ptr),ptr inttoptr (i64 -1 to ptr),ptr inttoptr (i64 9223372036854775808 to ptr),ptr inttoptr (i64 4294967295 to ptr),ptr inttoptr (i64 1311768467463790320 to ptr),ptr null,ptr inttoptr (i64 1 to ptr),ptr inttoptr (i64 -1 to ptr),ptr inttoptr (i64 9223372036854775808 to ptr),ptr inttoptr (i64 4294967295 to ptr),ptr inttoptr (i64 1311768467463790320 to ptr),ptr null,ptr inttoptr (i64 1 to ptr),ptr inttoptr (i64 -1 to ptr),ptr inttoptr (i64 9223372036854775808 to ptr),ptr inttoptr (i64 4294967295 to ptr),ptr inttoptr (i64 1311768467463790320 to ptr),ptr null,ptr inttoptr (i64 1 to ptr),ptr inttoptr (i64 -1 to ptr),ptr inttoptr (i64 9223372036854775808 to ptr),ptr inttoptr (i64 4294967295 to ptr),ptr inttoptr (i64 1311768467463790320 to ptr),ptr null,ptr inttoptr (i64 1 to ptr),ptr inttoptr (i64 -1 to ptr),ptr inttoptr (i64 9223372036854775808 to ptr),ptr inttoptr (i64 4294967295 to ptr),ptr inttoptr (i64 1311768467463790320 to ptr),ptr null,ptr inttoptr (i64 1 to ptr),ptr inttoptr (i64 -1 to ptr),ptr inttoptr (i64 9223372036854775808 to ptr),ptr inttoptr (i64 4294967295 to ptr),ptr inttoptr (i64 1311768467463790320 to ptr),ptr null,ptr inttoptr (i64 1 to ptr),ptr inttoptr (i64 -1 to ptr),ptr inttoptr (i64 9223372036854775808 to ptr),ptr inttoptr (i64 4294967295 to ptr),ptr inttoptr (i64 1311768467463790320 to ptr),ptr null,ptr inttoptr (i64 1 to ptr),ptr inttoptr (i64 -1 to ptr),ptr inttoptr (i64 9223372036854775808 to ptr),ptr inttoptr (i64 4294967295 to ptr),ptr inttoptr (i64 1311768467463790320 to ptr),ptr null,ptr inttoptr (i64 1 to ptr),ptr inttoptr (i64 -1 to ptr),ptr inttoptr (i64 9223372036854775808 to ptr),ptr inttoptr (i64 4294967295 to ptr),ptr inttoptr (i64 1311768467463790320 to ptr),ptr null,ptr inttoptr (i64 1 to ptr),ptr inttoptr (i64 -1 to ptr),ptr inttoptr (i64 9223372036854775808 to ptr),ptr inttoptr (i64 4294967295 to ptr),ptr inttoptr (i64 1311768467463790320 to ptr),ptr null,ptr inttoptr (i64 1 to ptr),ptr inttoptr (i64 -1 to ptr),ptr inttoptr (i64 9223372036854775808 to ptr)>,ptr %out1,align 1
 %insert0 = insertelement <64 x ptr> poison,ptr inttoptr (i64 9223372036854775808 to ptr),i32 63
 %insert1 = insertelement <64 x ptr> %insert0,ptr inttoptr (i64 -1 to ptr),i32 62
 %insert2 = insertelement <64 x ptr> %insert1,ptr inttoptr (i64 1 to ptr),i32 61
 %insert3 = insertelement <64 x ptr> %insert2,ptr null,i32 60
 %insert4 = insertelement <64 x ptr> %insert3,ptr inttoptr (i64 1311768467463790320 to ptr),i32 59
 %insert5 = insertelement <64 x ptr> %insert4,ptr inttoptr (i64 4294967295 to ptr),i32 58
 %insert6 = insertelement <64 x ptr> %insert5,ptr inttoptr (i64 9223372036854775808 to ptr),i32 57
 %insert7 = insertelement <64 x ptr> %insert6,ptr inttoptr (i64 -1 to ptr),i32 56
 %insert8 = insertelement <64 x ptr> %insert7,ptr inttoptr (i64 1 to ptr),i32 55
 %insert9 = insertelement <64 x ptr> %insert8,ptr null,i32 54
 %insert10 = insertelement <64 x ptr> %insert9,ptr inttoptr (i64 1311768467463790320 to ptr),i32 53
 %insert11 = insertelement <64 x ptr> %insert10,ptr inttoptr (i64 4294967295 to ptr),i32 52
 %insert12 = insertelement <64 x ptr> %insert11,ptr inttoptr (i64 9223372036854775808 to ptr),i32 51
 %insert13 = insertelement <64 x ptr> %insert12,ptr inttoptr (i64 -1 to ptr),i32 50
 %insert14 = insertelement <64 x ptr> %insert13,ptr inttoptr (i64 1 to ptr),i32 49
 %insert15 = insertelement <64 x ptr> %insert14,ptr null,i32 48
 %insert16 = insertelement <64 x ptr> %insert15,ptr inttoptr (i64 1311768467463790320 to ptr),i32 47
 %insert17 = insertelement <64 x ptr> %insert16,ptr inttoptr (i64 4294967295 to ptr),i32 46
 %insert18 = insertelement <64 x ptr> %insert17,ptr inttoptr (i64 9223372036854775808 to ptr),i32 45
 %insert19 = insertelement <64 x ptr> %insert18,ptr inttoptr (i64 -1 to ptr),i32 44
 %insert20 = insertelement <64 x ptr> %insert19,ptr inttoptr (i64 1 to ptr),i32 43
 %insert21 = insertelement <64 x ptr> %insert20,ptr null,i32 42
 %insert22 = insertelement <64 x ptr> %insert21,ptr inttoptr (i64 1311768467463790320 to ptr),i32 41
 %insert23 = insertelement <64 x ptr> %insert22,ptr inttoptr (i64 4294967295 to ptr),i32 40
 %insert24 = insertelement <64 x ptr> %insert23,ptr inttoptr (i64 9223372036854775808 to ptr),i32 39
 %insert25 = insertelement <64 x ptr> %insert24,ptr inttoptr (i64 -1 to ptr),i32 38
 %insert26 = insertelement <64 x ptr> %insert25,ptr inttoptr (i64 1 to ptr),i32 37
 %insert27 = insertelement <64 x ptr> %insert26,ptr null,i32 36
 %insert28 = insertelement <64 x ptr> %insert27,ptr inttoptr (i64 1311768467463790320 to ptr),i32 35
 %insert29 = insertelement <64 x ptr> %insert28,ptr inttoptr (i64 4294967295 to ptr),i32 34
 %insert30 = insertelement <64 x ptr> %insert29,ptr inttoptr (i64 9223372036854775808 to ptr),i32 33
 %insert31 = insertelement <64 x ptr> %insert30,ptr inttoptr (i64 -1 to ptr),i32 32
 %insert32 = insertelement <64 x ptr> %insert31,ptr inttoptr (i64 1 to ptr),i32 31
 %insert33 = insertelement <64 x ptr> %insert32,ptr null,i32 30
 %insert34 = insertelement <64 x ptr> %insert33,ptr inttoptr (i64 1311768467463790320 to ptr),i32 29
 %insert35 = insertelement <64 x ptr> %insert34,ptr inttoptr (i64 4294967295 to ptr),i32 28
 %insert36 = insertelement <64 x ptr> %insert35,ptr inttoptr (i64 9223372036854775808 to ptr),i32 27
 %insert37 = insertelement <64 x ptr> %insert36,ptr inttoptr (i64 -1 to ptr),i32 26
 %insert38 = insertelement <64 x ptr> %insert37,ptr inttoptr (i64 1 to ptr),i32 25
 %insert39 = insertelement <64 x ptr> %insert38,ptr null,i32 24
 %insert40 = insertelement <64 x ptr> %insert39,ptr inttoptr (i64 1311768467463790320 to ptr),i32 23
 %insert41 = insertelement <64 x ptr> %insert40,ptr inttoptr (i64 4294967295 to ptr),i32 22
 %insert42 = insertelement <64 x ptr> %insert41,ptr inttoptr (i64 9223372036854775808 to ptr),i32 21
 %insert43 = insertelement <64 x ptr> %insert42,ptr inttoptr (i64 -1 to ptr),i32 20
 %insert44 = insertelement <64 x ptr> %insert43,ptr inttoptr (i64 1 to ptr),i32 19
 %insert45 = insertelement <64 x ptr> %insert44,ptr null,i32 18
 %insert46 = insertelement <64 x ptr> %insert45,ptr inttoptr (i64 1311768467463790320 to ptr),i32 17
 %insert47 = insertelement <64 x ptr> %insert46,ptr inttoptr (i64 4294967295 to ptr),i32 16
 %insert48 = insertelement <64 x ptr> %insert47,ptr inttoptr (i64 9223372036854775808 to ptr),i32 15
 %insert49 = insertelement <64 x ptr> %insert48,ptr inttoptr (i64 -1 to ptr),i32 14
 %insert50 = insertelement <64 x ptr> %insert49,ptr inttoptr (i64 1 to ptr),i32 13
 %insert51 = insertelement <64 x ptr> %insert50,ptr null,i32 12
 %insert52 = insertelement <64 x ptr> %insert51,ptr inttoptr (i64 1311768467463790320 to ptr),i32 11
 %insert53 = insertelement <64 x ptr> %insert52,ptr inttoptr (i64 4294967295 to ptr),i32 10
 %insert54 = insertelement <64 x ptr> %insert53,ptr inttoptr (i64 9223372036854775808 to ptr),i32 9
 %insert55 = insertelement <64 x ptr> %insert54,ptr inttoptr (i64 -1 to ptr),i32 8
 %insert56 = insertelement <64 x ptr> %insert55,ptr inttoptr (i64 1 to ptr),i32 7
 %insert57 = insertelement <64 x ptr> %insert56,ptr null,i32 6
 %insert58 = insertelement <64 x ptr> %insert57,ptr inttoptr (i64 1311768467463790320 to ptr),i32 5
 %insert59 = insertelement <64 x ptr> %insert58,ptr inttoptr (i64 4294967295 to ptr),i32 4
 %insert60 = insertelement <64 x ptr> %insert59,ptr inttoptr (i64 9223372036854775808 to ptr),i32 3
 %insert61 = insertelement <64 x ptr> %insert60,ptr inttoptr (i64 -1 to ptr),i32 2
 %insert62 = insertelement <64 x ptr> %insert61,ptr inttoptr (i64 1 to ptr),i32 1
 %insert63 = insertelement <64 x ptr> %insert62,ptr null,i32 0
 %out2 = getelementptr i8,ptr %out,i64 1024
 store <64 x ptr> %insert63,ptr %out2,align 1
 %m0 = mul i64 0,1099511628211
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
define i64 @pointer_constants_probe_14(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @pointer_constants_body_14(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %data,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 1536
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 1544
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 1552
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @pointer_constants_body_15(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out) noinline {
entry:
 %a = load <64 x i64>,ptr %input,align 1
 %p = inttoptr <64 x i64> %a to <64 x ptr>
 %bits = ptrtoint <64 x ptr> %p to <64 x i64>
 store <64 x i64> %bits,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 512
 store <64 x ptr> <ptr null,ptr inttoptr (i64 1 to ptr),ptr inttoptr (i64 -1 to ptr),ptr inttoptr (i64 9223372036854775808 to ptr),ptr inttoptr (i64 4294967295 to ptr),ptr inttoptr (i64 1311768467463790320 to ptr),ptr null,ptr inttoptr (i64 1 to ptr),ptr inttoptr (i64 -1 to ptr),ptr inttoptr (i64 9223372036854775808 to ptr),ptr inttoptr (i64 4294967295 to ptr),ptr inttoptr (i64 1311768467463790320 to ptr),ptr null,ptr inttoptr (i64 1 to ptr),ptr inttoptr (i64 -1 to ptr),ptr inttoptr (i64 9223372036854775808 to ptr),ptr inttoptr (i64 4294967295 to ptr),ptr inttoptr (i64 1311768467463790320 to ptr),ptr null,ptr inttoptr (i64 1 to ptr),ptr inttoptr (i64 -1 to ptr),ptr inttoptr (i64 9223372036854775808 to ptr),ptr inttoptr (i64 4294967295 to ptr),ptr inttoptr (i64 1311768467463790320 to ptr),ptr null,ptr inttoptr (i64 1 to ptr),ptr inttoptr (i64 -1 to ptr),ptr inttoptr (i64 9223372036854775808 to ptr),ptr inttoptr (i64 4294967295 to ptr),ptr inttoptr (i64 1311768467463790320 to ptr),ptr null,ptr inttoptr (i64 1 to ptr),ptr inttoptr (i64 -1 to ptr),ptr inttoptr (i64 9223372036854775808 to ptr),ptr inttoptr (i64 4294967295 to ptr),ptr inttoptr (i64 1311768467463790320 to ptr),ptr null,ptr inttoptr (i64 1 to ptr),ptr inttoptr (i64 -1 to ptr),ptr inttoptr (i64 9223372036854775808 to ptr),ptr inttoptr (i64 4294967295 to ptr),ptr inttoptr (i64 1311768467463790320 to ptr),ptr null,ptr inttoptr (i64 1 to ptr),ptr inttoptr (i64 -1 to ptr),ptr inttoptr (i64 9223372036854775808 to ptr),ptr inttoptr (i64 4294967295 to ptr),ptr inttoptr (i64 1311768467463790320 to ptr),ptr null,ptr inttoptr (i64 1 to ptr),ptr inttoptr (i64 -1 to ptr),ptr inttoptr (i64 9223372036854775808 to ptr),ptr inttoptr (i64 4294967295 to ptr),ptr inttoptr (i64 1311768467463790320 to ptr),ptr null,ptr inttoptr (i64 1 to ptr),ptr inttoptr (i64 -1 to ptr),ptr inttoptr (i64 9223372036854775808 to ptr),ptr inttoptr (i64 4294967295 to ptr),ptr inttoptr (i64 1311768467463790320 to ptr),ptr null,ptr inttoptr (i64 1 to ptr),ptr inttoptr (i64 -1 to ptr),ptr inttoptr (i64 9223372036854775808 to ptr)>,ptr %out1,align 1
 %insert0 = insertelement <64 x ptr> poison,ptr inttoptr (i64 9223372036854775808 to ptr),i32 63
 %insert1 = insertelement <64 x ptr> %insert0,ptr inttoptr (i64 -1 to ptr),i32 62
 %insert2 = insertelement <64 x ptr> %insert1,ptr inttoptr (i64 1 to ptr),i32 61
 %insert3 = insertelement <64 x ptr> %insert2,ptr null,i32 60
 %insert4 = insertelement <64 x ptr> %insert3,ptr inttoptr (i64 1311768467463790320 to ptr),i32 59
 %insert5 = insertelement <64 x ptr> %insert4,ptr inttoptr (i64 4294967295 to ptr),i32 58
 %insert6 = insertelement <64 x ptr> %insert5,ptr inttoptr (i64 9223372036854775808 to ptr),i32 57
 %insert7 = insertelement <64 x ptr> %insert6,ptr inttoptr (i64 -1 to ptr),i32 56
 %insert8 = insertelement <64 x ptr> %insert7,ptr inttoptr (i64 1 to ptr),i32 55
 %insert9 = insertelement <64 x ptr> %insert8,ptr null,i32 54
 %insert10 = insertelement <64 x ptr> %insert9,ptr inttoptr (i64 1311768467463790320 to ptr),i32 53
 %insert11 = insertelement <64 x ptr> %insert10,ptr inttoptr (i64 4294967295 to ptr),i32 52
 %insert12 = insertelement <64 x ptr> %insert11,ptr inttoptr (i64 9223372036854775808 to ptr),i32 51
 %insert13 = insertelement <64 x ptr> %insert12,ptr inttoptr (i64 -1 to ptr),i32 50
 %insert14 = insertelement <64 x ptr> %insert13,ptr inttoptr (i64 1 to ptr),i32 49
 %insert15 = insertelement <64 x ptr> %insert14,ptr null,i32 48
 %insert16 = insertelement <64 x ptr> %insert15,ptr inttoptr (i64 1311768467463790320 to ptr),i32 47
 %insert17 = insertelement <64 x ptr> %insert16,ptr inttoptr (i64 4294967295 to ptr),i32 46
 %insert18 = insertelement <64 x ptr> %insert17,ptr inttoptr (i64 9223372036854775808 to ptr),i32 45
 %insert19 = insertelement <64 x ptr> %insert18,ptr inttoptr (i64 -1 to ptr),i32 44
 %insert20 = insertelement <64 x ptr> %insert19,ptr inttoptr (i64 1 to ptr),i32 43
 %insert21 = insertelement <64 x ptr> %insert20,ptr null,i32 42
 %insert22 = insertelement <64 x ptr> %insert21,ptr inttoptr (i64 1311768467463790320 to ptr),i32 41
 %insert23 = insertelement <64 x ptr> %insert22,ptr inttoptr (i64 4294967295 to ptr),i32 40
 %insert24 = insertelement <64 x ptr> %insert23,ptr inttoptr (i64 9223372036854775808 to ptr),i32 39
 %insert25 = insertelement <64 x ptr> %insert24,ptr inttoptr (i64 -1 to ptr),i32 38
 %insert26 = insertelement <64 x ptr> %insert25,ptr inttoptr (i64 1 to ptr),i32 37
 %insert27 = insertelement <64 x ptr> %insert26,ptr null,i32 36
 %insert28 = insertelement <64 x ptr> %insert27,ptr inttoptr (i64 1311768467463790320 to ptr),i32 35
 %insert29 = insertelement <64 x ptr> %insert28,ptr inttoptr (i64 4294967295 to ptr),i32 34
 %insert30 = insertelement <64 x ptr> %insert29,ptr inttoptr (i64 9223372036854775808 to ptr),i32 33
 %insert31 = insertelement <64 x ptr> %insert30,ptr inttoptr (i64 -1 to ptr),i32 32
 %insert32 = insertelement <64 x ptr> %insert31,ptr inttoptr (i64 1 to ptr),i32 31
 %insert33 = insertelement <64 x ptr> %insert32,ptr null,i32 30
 %insert34 = insertelement <64 x ptr> %insert33,ptr inttoptr (i64 1311768467463790320 to ptr),i32 29
 %insert35 = insertelement <64 x ptr> %insert34,ptr inttoptr (i64 4294967295 to ptr),i32 28
 %insert36 = insertelement <64 x ptr> %insert35,ptr inttoptr (i64 9223372036854775808 to ptr),i32 27
 %insert37 = insertelement <64 x ptr> %insert36,ptr inttoptr (i64 -1 to ptr),i32 26
 %insert38 = insertelement <64 x ptr> %insert37,ptr inttoptr (i64 1 to ptr),i32 25
 %insert39 = insertelement <64 x ptr> %insert38,ptr null,i32 24
 %insert40 = insertelement <64 x ptr> %insert39,ptr inttoptr (i64 1311768467463790320 to ptr),i32 23
 %insert41 = insertelement <64 x ptr> %insert40,ptr inttoptr (i64 4294967295 to ptr),i32 22
 %insert42 = insertelement <64 x ptr> %insert41,ptr inttoptr (i64 9223372036854775808 to ptr),i32 21
 %insert43 = insertelement <64 x ptr> %insert42,ptr inttoptr (i64 -1 to ptr),i32 20
 %insert44 = insertelement <64 x ptr> %insert43,ptr inttoptr (i64 1 to ptr),i32 19
 %insert45 = insertelement <64 x ptr> %insert44,ptr null,i32 18
 %insert46 = insertelement <64 x ptr> %insert45,ptr inttoptr (i64 1311768467463790320 to ptr),i32 17
 %insert47 = insertelement <64 x ptr> %insert46,ptr inttoptr (i64 4294967295 to ptr),i32 16
 %insert48 = insertelement <64 x ptr> %insert47,ptr inttoptr (i64 9223372036854775808 to ptr),i32 15
 %insert49 = insertelement <64 x ptr> %insert48,ptr inttoptr (i64 -1 to ptr),i32 14
 %insert50 = insertelement <64 x ptr> %insert49,ptr inttoptr (i64 1 to ptr),i32 13
 %insert51 = insertelement <64 x ptr> %insert50,ptr null,i32 12
 %insert52 = insertelement <64 x ptr> %insert51,ptr inttoptr (i64 1311768467463790320 to ptr),i32 11
 %insert53 = insertelement <64 x ptr> %insert52,ptr inttoptr (i64 4294967295 to ptr),i32 10
 %insert54 = insertelement <64 x ptr> %insert53,ptr inttoptr (i64 9223372036854775808 to ptr),i32 9
 %insert55 = insertelement <64 x ptr> %insert54,ptr inttoptr (i64 -1 to ptr),i32 8
 %insert56 = insertelement <64 x ptr> %insert55,ptr inttoptr (i64 1 to ptr),i32 7
 %insert57 = insertelement <64 x ptr> %insert56,ptr null,i32 6
 %insert58 = insertelement <64 x ptr> %insert57,ptr inttoptr (i64 1311768467463790320 to ptr),i32 5
 %insert59 = insertelement <64 x ptr> %insert58,ptr inttoptr (i64 4294967295 to ptr),i32 4
 %insert60 = insertelement <64 x ptr> %insert59,ptr inttoptr (i64 9223372036854775808 to ptr),i32 3
 %insert61 = insertelement <64 x ptr> %insert60,ptr inttoptr (i64 -1 to ptr),i32 2
 %insert62 = insertelement <64 x ptr> %insert61,ptr inttoptr (i64 1 to ptr),i32 1
 %insert63 = insertelement <64 x ptr> %insert62,ptr null,i32 0
 %out2 = getelementptr i8,ptr %out,i64 1024
 store <64 x ptr> %insert63,ptr %out2,align 1
 %m0 = mul i64 0,1099511628211
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
define i64 @pointer_constants_probe_15(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @pointer_constants_body_15(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %data,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 1536
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 1544
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 1552
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
