target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"
@bounded_asm_global = internal global i64 1311768467463790321,align 8
define i64 @bounded_asm_body_0(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = call i32 asm sideeffect "mov $$0, ${0}", "=r,~{dirflag},~{fpsr},~{flags}"()
 %result = zext i32 %value to i64
 %m0 = mul i64 %result,1099511628211
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
define i64 @bounded_asm_probe_0(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @bounded_asm_body_0(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @bounded_asm_body_1(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = call i32 asm sideeffect "mov $$1, ${0}", "=r,~{dirflag},~{fpsr},~{flags}"()
 %result = zext i32 %value to i64
 %m0 = mul i64 %result,1099511628211
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
define i64 @bounded_asm_probe_1(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @bounded_asm_body_1(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @bounded_asm_body_2(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = call i32 asm sideeffect "mov $$-1, ${0}", "=r,~{dirflag},~{fpsr},~{flags}"()
 %result = zext i32 %value to i64
 %m0 = mul i64 %result,1099511628211
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
define i64 @bounded_asm_probe_2(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @bounded_asm_body_2(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @bounded_asm_body_3(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = call i32 asm sideeffect "mov $$123, ${0}", "=r,~{dirflag},~{fpsr},~{flags}"()
 %result = zext i32 %value to i64
 %m0 = mul i64 %result,1099511628211
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
define i64 @bounded_asm_probe_3(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @bounded_asm_body_3(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @bounded_asm_body_4(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = call i32 asm sideeffect "mov $$-2147483648, ${0}", "=r,~{dirflag},~{fpsr},~{flags}"()
 %result = zext i32 %value to i64
 %m0 = mul i64 %result,1099511628211
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
define i64 @bounded_asm_probe_4(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @bounded_asm_body_4(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @bounded_asm_body_5(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = call i32 asm sideeffect "mov $$4294967295, ${0}", "=r,~{dirflag},~{fpsr},~{flags}"()
 %result = zext i32 %value to i64
 %m0 = mul i64 %result,1099511628211
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
define i64 @bounded_asm_probe_5(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @bounded_asm_body_5(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @bounded_asm_body_6(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = call i64 asm sideeffect "mov $$0, ${0}", "=r,~{dirflag},~{fpsr},~{flags}"()
 %result = add i64 %value,0
 %m0 = mul i64 %result,1099511628211
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
define i64 @bounded_asm_probe_6(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @bounded_asm_body_6(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @bounded_asm_body_7(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = call i64 asm sideeffect "mov $$1, ${0}", "=r,~{dirflag},~{fpsr},~{flags}"()
 %result = add i64 %value,0
 %m0 = mul i64 %result,1099511628211
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
define i64 @bounded_asm_probe_7(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @bounded_asm_body_7(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @bounded_asm_body_8(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = call i64 asm sideeffect "mov $$-1, ${0}", "=r,~{dirflag},~{fpsr},~{flags}"()
 %result = add i64 %value,0
 %m0 = mul i64 %result,1099511628211
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
define i64 @bounded_asm_probe_8(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @bounded_asm_body_8(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @bounded_asm_body_9(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = call i64 asm sideeffect "mov $$123, ${0}", "=r,~{dirflag},~{fpsr},~{flags}"()
 %result = add i64 %value,0
 %m0 = mul i64 %result,1099511628211
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
define i64 @bounded_asm_probe_9(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @bounded_asm_body_9(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @bounded_asm_body_10(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = call i64 asm sideeffect "mov $$-9223372036854775808, ${0}", "=r,~{dirflag},~{fpsr},~{flags}"()
 %result = add i64 %value,0
 %m0 = mul i64 %result,1099511628211
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
define i64 @bounded_asm_probe_10(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @bounded_asm_body_10(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @bounded_asm_body_11(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = call i64 asm sideeffect "mov $$18446744073709551615, ${0}", "=r,~{dirflag},~{fpsr},~{flags}"()
 %result = add i64 %value,0
 %m0 = mul i64 %result,1099511628211
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
define i64 @bounded_asm_probe_11(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @bounded_asm_body_11(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @bounded_asm_body_12(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %x = trunc i64 %p0 to i32
 %y = trunc i64 %p1 to i32
 %value = call i32 asm "addl ${1}, ${0}", "=r,r,0,~{flags},~{dirflag},~{fpsr},~{flags}"(i32 %y,i32 %x)
 %result = zext i32 %value to i64
 %m0 = mul i64 %result,1099511628211
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
define i64 @bounded_asm_probe_12(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @bounded_asm_body_12(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @bounded_asm_body_13(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %x = trunc i64 %p0 to i32
 %value = call i32 asm "addl ${1}, ${0}", "=r,r,0,~{flags},~{dirflag},~{fpsr},~{flags}"(i32 13,i32 %x)
 %result = zext i32 %value to i64
 %m0 = mul i64 %result,1099511628211
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
define i64 @bounded_asm_probe_13(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @bounded_asm_body_13(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @bounded_asm_body_14(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %x = trunc i64 %p1 to i32
 %y = trunc i64 %p2 to i32
 %value = call i32 asm "addl ${1}, ${0}", "=r,r,0,~{flags},~{dirflag},~{fpsr},~{flags}"(i32 %y,i32 %x)
 %result = zext i32 %value to i64
 %m0 = mul i64 %result,1099511628211
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
define i64 @bounded_asm_probe_14(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @bounded_asm_body_14(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @bounded_asm_body_15(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %x = trunc i64 %p1 to i32
 %value = call i32 asm "addl ${1}, ${0}", "=r,r,0,~{flags},~{dirflag},~{fpsr},~{flags}"(i32 13,i32 %x)
 %result = zext i32 %value to i64
 %m0 = mul i64 %result,1099511628211
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
define i64 @bounded_asm_probe_15(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @bounded_asm_body_15(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @bounded_asm_body_16(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %x = trunc i64 %p2 to i32
 %y = trunc i64 %p3 to i32
 %value = call i32 asm "addl ${1}, ${0}", "=r,r,0,~{flags},~{dirflag},~{fpsr},~{flags}"(i32 %y,i32 %x)
 %result = zext i32 %value to i64
 %m0 = mul i64 %result,1099511628211
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
define i64 @bounded_asm_probe_16(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @bounded_asm_body_16(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @bounded_asm_body_17(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %x = trunc i64 %p2 to i32
 %value = call i32 asm "addl ${1}, ${0}", "=r,r,0,~{flags},~{dirflag},~{fpsr},~{flags}"(i32 13,i32 %x)
 %result = zext i32 %value to i64
 %m0 = mul i64 %result,1099511628211
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
define i64 @bounded_asm_probe_17(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @bounded_asm_body_17(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @bounded_asm_body_18(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %x = trunc i64 %p3 to i32
 %y = trunc i64 %p4 to i32
 %value = call i32 asm "addl ${1}, ${0}", "=r,r,0,~{flags},~{dirflag},~{fpsr},~{flags}"(i32 %y,i32 %x)
 %result = zext i32 %value to i64
 %m0 = mul i64 %result,1099511628211
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
define i64 @bounded_asm_probe_18(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @bounded_asm_body_18(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @bounded_asm_body_19(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %x = trunc i64 %p3 to i32
 %value = call i32 asm "addl ${1}, ${0}", "=r,r,0,~{flags},~{dirflag},~{fpsr},~{flags}"(i32 13,i32 %x)
 %result = zext i32 %value to i64
 %m0 = mul i64 %result,1099511628211
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
define i64 @bounded_asm_probe_19(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @bounded_asm_body_19(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @bounded_asm_body_20(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %x = trunc i64 %p4 to i32
 %y = trunc i64 %p5 to i32
 %value = call i32 asm "addl ${1}, ${0}", "=r,r,0,~{flags},~{dirflag},~{fpsr},~{flags}"(i32 %y,i32 %x)
 %result = zext i32 %value to i64
 %m0 = mul i64 %result,1099511628211
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
define i64 @bounded_asm_probe_20(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @bounded_asm_body_20(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @bounded_asm_body_21(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %x = trunc i64 %p4 to i32
 %value = call i32 asm "addl ${1}, ${0}", "=r,r,0,~{flags},~{dirflag},~{fpsr},~{flags}"(i32 13,i32 %x)
 %result = zext i32 %value to i64
 %m0 = mul i64 %result,1099511628211
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
define i64 @bounded_asm_probe_21(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @bounded_asm_body_21(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @bounded_asm_body_22(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %x = trunc i64 %p5 to i32
 %y = trunc i64 %p0 to i32
 %value = call i32 asm "addl ${1}, ${0}", "=r,r,0,~{flags},~{dirflag},~{fpsr},~{flags}"(i32 %y,i32 %x)
 %result = zext i32 %value to i64
 %m0 = mul i64 %result,1099511628211
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
define i64 @bounded_asm_probe_22(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @bounded_asm_body_22(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @bounded_asm_body_23(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %x = trunc i64 %p5 to i32
 %value = call i32 asm "addl ${1}, ${0}", "=r,r,0,~{flags},~{dirflag},~{fpsr},~{flags}"(i32 13,i32 %x)
 %result = zext i32 %value to i64
 %m0 = mul i64 %result,1099511628211
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
define i64 @bounded_asm_probe_23(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @bounded_asm_body_23(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @bounded_asm_body_24(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 store i64 %p0,ptr %out,align 1
 call void asm sideeffect "", "m,~{dirflag},~{fpsr},~{flags}"(ptr %out)
 store i64 %p0,ptr %out,align 1
 %result = load i64,ptr %out,align 1
 %m0 = mul i64 %result,1099511628211
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
define i64 @bounded_asm_probe_24(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @bounded_asm_body_24(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @bounded_asm_body_25(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 store i64 %p0,ptr %out,align 1
 call void asm sideeffect "", "=*m|r,~{dirflag},~{fpsr},~{flags}"(ptr elementtype(i64) %out)
 store i64 %p0,ptr %out,align 1
 %result = load i64,ptr %out,align 1
 %m0 = mul i64 %result,1099511628211
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
define i64 @bounded_asm_probe_25(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @bounded_asm_body_25(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @bounded_asm_body_26(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 store i64 %p0,ptr %out,align 1
 call void asm sideeffect "", "=*r|m,~{dirflag},~{fpsr},~{flags}"(ptr elementtype(i64) %out)
 store i64 %p0,ptr %out,align 1
 %result = load i64,ptr %out,align 1
 %m0 = mul i64 %result,1099511628211
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
define i64 @bounded_asm_probe_26(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @bounded_asm_body_26(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @bounded_asm_body_27(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 store i64 %p0,ptr %out,align 1
 %extra = trunc i64 %p1 to i32
 call void asm sideeffect "", "=*r|m,r|m,~{dirflag},~{fpsr},~{flags}"(ptr elementtype(i64) %out,i32 %extra)
 store i64 %p0,ptr %out,align 1
 %result = load i64,ptr %out,align 1
 %m0 = mul i64 %result,1099511628211
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
define i64 @bounded_asm_probe_27(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @bounded_asm_body_27(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @bounded_asm_body_28(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 call void asm sideeffect "", "m,~{dirflag},~{fpsr},~{flags}"(ptr @bounded_asm_global)
 %result = load i64,ptr @bounded_asm_global,align 1
 %m0 = mul i64 %result,1099511628211
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
define i64 @bounded_asm_probe_28(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @bounded_asm_body_28(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @bounded_asm_body_29(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = call i32 asm sideeffect "mov $$0, ${0}", "=r,~{dirflag},~{fpsr},~{flags}"()
 %result = zext i32 %value to i64
 %m0 = mul i64 %result,1099511628211
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
define i64 @bounded_asm_probe_29(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @bounded_asm_body_29(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @bounded_asm_body_30(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = call i32 asm sideeffect "mov $$1, ${0}", "=r,~{dirflag},~{fpsr},~{flags}"()
 %result = zext i32 %value to i64
 %m0 = mul i64 %result,1099511628211
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
define i64 @bounded_asm_probe_30(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @bounded_asm_body_30(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @bounded_asm_body_31(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = call i32 asm sideeffect "mov $$-1, ${0}", "=r,~{dirflag},~{fpsr},~{flags}"()
 %result = zext i32 %value to i64
 %m0 = mul i64 %result,1099511628211
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
define i64 @bounded_asm_probe_31(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @bounded_asm_body_31(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @bounded_asm_body_32(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = call i32 asm sideeffect "mov $$123, ${0}", "=r,~{dirflag},~{fpsr},~{flags}"()
 %result = zext i32 %value to i64
 %m0 = mul i64 %result,1099511628211
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
define i64 @bounded_asm_probe_32(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @bounded_asm_body_32(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @bounded_asm_body_33(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = call i32 asm sideeffect "mov $$-2147483648, ${0}", "=r,~{dirflag},~{fpsr},~{flags}"()
 %result = zext i32 %value to i64
 %m0 = mul i64 %result,1099511628211
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
define i64 @bounded_asm_probe_33(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @bounded_asm_body_33(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @bounded_asm_body_34(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = call i32 asm sideeffect "mov $$4294967295, ${0}", "=r,~{dirflag},~{fpsr},~{flags}"()
 %result = zext i32 %value to i64
 %m0 = mul i64 %result,1099511628211
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
define i64 @bounded_asm_probe_34(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @bounded_asm_body_34(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @bounded_asm_body_35(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = call i64 asm sideeffect "mov $$0, ${0}", "=r,~{dirflag},~{fpsr},~{flags}"()
 %result = add i64 %value,0
 %m0 = mul i64 %result,1099511628211
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
define i64 @bounded_asm_probe_35(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @bounded_asm_body_35(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @bounded_asm_body_36(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = call i64 asm sideeffect "mov $$1, ${0}", "=r,~{dirflag},~{fpsr},~{flags}"()
 %result = add i64 %value,0
 %m0 = mul i64 %result,1099511628211
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
define i64 @bounded_asm_probe_36(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @bounded_asm_body_36(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @bounded_asm_body_37(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = call i64 asm sideeffect "mov $$-1, ${0}", "=r,~{dirflag},~{fpsr},~{flags}"()
 %result = add i64 %value,0
 %m0 = mul i64 %result,1099511628211
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
define i64 @bounded_asm_probe_37(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @bounded_asm_body_37(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @bounded_asm_body_38(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = call i64 asm sideeffect "mov $$123, ${0}", "=r,~{dirflag},~{fpsr},~{flags}"()
 %result = add i64 %value,0
 %m0 = mul i64 %result,1099511628211
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
define i64 @bounded_asm_probe_38(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @bounded_asm_body_38(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @bounded_asm_body_39(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = call i64 asm sideeffect "mov $$-9223372036854775808, ${0}", "=r,~{dirflag},~{fpsr},~{flags}"()
 %result = add i64 %value,0
 %m0 = mul i64 %result,1099511628211
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
define i64 @bounded_asm_probe_39(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @bounded_asm_body_39(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @bounded_asm_body_40(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = call i64 asm sideeffect "mov $$18446744073709551615, ${0}", "=r,~{dirflag},~{fpsr},~{flags}"()
 %result = add i64 %value,0
 %m0 = mul i64 %result,1099511628211
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
define i64 @bounded_asm_probe_40(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @bounded_asm_body_40(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @bounded_asm_body_41(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %x = trunc i64 %p0 to i32
 %y = trunc i64 %p1 to i32
 %value = call i32 asm "addl ${1}, ${0}", "=r,r,0,~{flags},~{dirflag},~{fpsr},~{flags}"(i32 %y,i32 %x)
 %result = zext i32 %value to i64
 %m0 = mul i64 %result,1099511628211
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
define i64 @bounded_asm_probe_41(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @bounded_asm_body_41(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @bounded_asm_body_42(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %x = trunc i64 %p0 to i32
 %value = call i32 asm "addl ${1}, ${0}", "=r,r,0,~{flags},~{dirflag},~{fpsr},~{flags}"(i32 13,i32 %x)
 %result = zext i32 %value to i64
 %m0 = mul i64 %result,1099511628211
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
define i64 @bounded_asm_probe_42(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @bounded_asm_body_42(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @bounded_asm_body_43(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %x = trunc i64 %p1 to i32
 %y = trunc i64 %p2 to i32
 %value = call i32 asm "addl ${1}, ${0}", "=r,r,0,~{flags},~{dirflag},~{fpsr},~{flags}"(i32 %y,i32 %x)
 %result = zext i32 %value to i64
 %m0 = mul i64 %result,1099511628211
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
define i64 @bounded_asm_probe_43(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @bounded_asm_body_43(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @bounded_asm_body_44(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %x = trunc i64 %p1 to i32
 %value = call i32 asm "addl ${1}, ${0}", "=r,r,0,~{flags},~{dirflag},~{fpsr},~{flags}"(i32 13,i32 %x)
 %result = zext i32 %value to i64
 %m0 = mul i64 %result,1099511628211
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
define i64 @bounded_asm_probe_44(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @bounded_asm_body_44(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @bounded_asm_body_45(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %x = trunc i64 %p2 to i32
 %y = trunc i64 %p3 to i32
 %value = call i32 asm "addl ${1}, ${0}", "=r,r,0,~{flags},~{dirflag},~{fpsr},~{flags}"(i32 %y,i32 %x)
 %result = zext i32 %value to i64
 %m0 = mul i64 %result,1099511628211
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
define i64 @bounded_asm_probe_45(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @bounded_asm_body_45(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @bounded_asm_body_46(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %x = trunc i64 %p2 to i32
 %value = call i32 asm "addl ${1}, ${0}", "=r,r,0,~{flags},~{dirflag},~{fpsr},~{flags}"(i32 13,i32 %x)
 %result = zext i32 %value to i64
 %m0 = mul i64 %result,1099511628211
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
define i64 @bounded_asm_probe_46(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @bounded_asm_body_46(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @bounded_asm_body_47(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %x = trunc i64 %p3 to i32
 %y = trunc i64 %p4 to i32
 %value = call i32 asm "addl ${1}, ${0}", "=r,r,0,~{flags},~{dirflag},~{fpsr},~{flags}"(i32 %y,i32 %x)
 %result = zext i32 %value to i64
 %m0 = mul i64 %result,1099511628211
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
define i64 @bounded_asm_probe_47(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @bounded_asm_body_47(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @bounded_asm_body_48(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %x = trunc i64 %p3 to i32
 %value = call i32 asm "addl ${1}, ${0}", "=r,r,0,~{flags},~{dirflag},~{fpsr},~{flags}"(i32 13,i32 %x)
 %result = zext i32 %value to i64
 %m0 = mul i64 %result,1099511628211
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
define i64 @bounded_asm_probe_48(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @bounded_asm_body_48(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @bounded_asm_body_49(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %x = trunc i64 %p4 to i32
 %y = trunc i64 %p5 to i32
 %value = call i32 asm "addl ${1}, ${0}", "=r,r,0,~{flags},~{dirflag},~{fpsr},~{flags}"(i32 %y,i32 %x)
 %result = zext i32 %value to i64
 %m0 = mul i64 %result,1099511628211
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
define i64 @bounded_asm_probe_49(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @bounded_asm_body_49(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @bounded_asm_body_50(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %x = trunc i64 %p4 to i32
 %value = call i32 asm "addl ${1}, ${0}", "=r,r,0,~{flags},~{dirflag},~{fpsr},~{flags}"(i32 13,i32 %x)
 %result = zext i32 %value to i64
 %m0 = mul i64 %result,1099511628211
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
define i64 @bounded_asm_probe_50(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @bounded_asm_body_50(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @bounded_asm_body_51(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %x = trunc i64 %p5 to i32
 %y = trunc i64 %p0 to i32
 %value = call i32 asm "addl ${1}, ${0}", "=r,r,0,~{flags},~{dirflag},~{fpsr},~{flags}"(i32 %y,i32 %x)
 %result = zext i32 %value to i64
 %m0 = mul i64 %result,1099511628211
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
define i64 @bounded_asm_probe_51(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @bounded_asm_body_51(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @bounded_asm_body_52(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %x = trunc i64 %p5 to i32
 %value = call i32 asm "addl ${1}, ${0}", "=r,r,0,~{flags},~{dirflag},~{fpsr},~{flags}"(i32 13,i32 %x)
 %result = zext i32 %value to i64
 %m0 = mul i64 %result,1099511628211
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
define i64 @bounded_asm_probe_52(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @bounded_asm_body_52(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @bounded_asm_body_53(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 store i64 %p0,ptr %out,align 1
 call void asm sideeffect "", "m,~{dirflag},~{fpsr},~{flags}"(ptr %out)
 store i64 %p0,ptr %out,align 1
 %result = load i64,ptr %out,align 1
 %m0 = mul i64 %result,1099511628211
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
define i64 @bounded_asm_probe_53(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @bounded_asm_body_53(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @bounded_asm_body_54(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 store i64 %p0,ptr %out,align 1
 call void asm sideeffect "", "=*m|r,~{dirflag},~{fpsr},~{flags}"(ptr elementtype(i64) %out)
 store i64 %p0,ptr %out,align 1
 %result = load i64,ptr %out,align 1
 %m0 = mul i64 %result,1099511628211
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
define i64 @bounded_asm_probe_54(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @bounded_asm_body_54(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @bounded_asm_body_55(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 store i64 %p0,ptr %out,align 1
 call void asm sideeffect "", "=*r|m,~{dirflag},~{fpsr},~{flags}"(ptr elementtype(i64) %out)
 store i64 %p0,ptr %out,align 1
 %result = load i64,ptr %out,align 1
 %m0 = mul i64 %result,1099511628211
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
define i64 @bounded_asm_probe_55(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @bounded_asm_body_55(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @bounded_asm_body_56(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 store i64 %p0,ptr %out,align 1
 %extra = trunc i64 %p1 to i32
 call void asm sideeffect "", "=*r|m,r|m,~{dirflag},~{fpsr},~{flags}"(ptr elementtype(i64) %out,i32 %extra)
 store i64 %p0,ptr %out,align 1
 %result = load i64,ptr %out,align 1
 %m0 = mul i64 %result,1099511628211
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
define i64 @bounded_asm_probe_56(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @bounded_asm_body_56(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @bounded_asm_body_57(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 call void asm sideeffect "", "m,~{dirflag},~{fpsr},~{flags}"(ptr @bounded_asm_global)
 %result = load i64,ptr @bounded_asm_global,align 1
 %m0 = mul i64 %result,1099511628211
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
define i64 @bounded_asm_probe_57(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @bounded_asm_body_57(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
