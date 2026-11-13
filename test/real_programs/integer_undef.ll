target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"
define i64 @integer_undef_body_0(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %header = alloca [6 x i64],align 8
 %h0 = getelementptr i8,ptr %header,i64 0
 store i64 %p0,ptr %h0,align 8
 %h1 = getelementptr i8,ptr %header,i64 8
 store i64 %p1,ptr %h1,align 8
 %h2 = getelementptr i8,ptr %header,i64 16
 store i64 %p2,ptr %h2,align 8
 %h3 = getelementptr i8,ptr %header,i64 24
 store i64 %p3,ptr %h3,align 8
 %h4 = getelementptr i8,ptr %header,i64 32
 store i64 %p4,ptr %h4,align 8
 %h5 = getelementptr i8,ptr %header,i64 40
 store i64 %p5,ptr %h5,align 8
 %value = zext i1 undef to i8
 store i8 %value,ptr %out,align 1
 %request = ptrtoint ptr %header to i64
 %client = call i64 asm sideeffect " rolq  $$3,  %rdi ; rolq $$13, %rdi\0A rolq  $$61, %rdi ; rolq $$51, %rdi\0A xchgq %rbx, %rbx", "={rdx},{rax},{rdx},~{cc},~{memory},~{dirflag},~{fpsr},~{flags}"(i64 %request,i64 %p4)
 %marker = getelementptr i8,ptr %out,i64 1
 store i64 %client,ptr %marker,align 1
 %m0 = mul i64 %client,1099511628211
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
define i64 @integer_undef_probe_0(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @integer_undef_body_0(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 9
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 17
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 25
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @integer_undef_body_1(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %header = alloca [6 x i64],align 8
 %h0 = getelementptr i8,ptr %header,i64 0
 store i64 %p0,ptr %h0,align 8
 %h1 = getelementptr i8,ptr %header,i64 8
 store i64 %p1,ptr %h1,align 8
 %h2 = getelementptr i8,ptr %header,i64 16
 store i64 %p2,ptr %h2,align 8
 %h3 = getelementptr i8,ptr %header,i64 24
 store i64 %p3,ptr %h3,align 8
 %h4 = getelementptr i8,ptr %header,i64 32
 store i64 %p4,ptr %h4,align 8
 %h5 = getelementptr i8,ptr %header,i64 40
 store i64 %p5,ptr %h5,align 8
 %value = zext i1 undef to i8
 store i8 %value,ptr %out,align 1
 %request = ptrtoint ptr %header to i64
 %client = call i64 asm sideeffect " rolq  $$3,  %rdi ; rolq $$13, %rdi\0A rolq  $$61, %rdi ; rolq $$51, %rdi\0A xchgq %rbx, %rbx", "={rdx},{rax},{rdx},~{cc},~{memory},~{dirflag},~{fpsr},~{flags}"(i64 %request,i64 %p4)
 %marker = getelementptr i8,ptr %out,i64 1
 store i64 %client,ptr %marker,align 1
 %m0 = mul i64 %client,1099511628211
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
define i64 @integer_undef_probe_1(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @integer_undef_body_1(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 9
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 17
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 25
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define i64 @integer_undef_body_2(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %header = alloca [6 x i64],align 8
 %h0 = getelementptr i8,ptr %header,i64 0
 store i64 %p0,ptr %h0,align 8
 %h1 = getelementptr i8,ptr %header,i64 8
 store i64 %p1,ptr %h1,align 8
 %h2 = getelementptr i8,ptr %header,i64 16
 store i64 %p2,ptr %h2,align 8
 %h3 = getelementptr i8,ptr %header,i64 24
 store i64 %p3,ptr %h3,align 8
 %h4 = getelementptr i8,ptr %header,i64 32
 store i64 %p4,ptr %h4,align 8
 %h5 = getelementptr i8,ptr %header,i64 40
 store i64 %p5,ptr %h5,align 8
 %value = sext i1 undef to i8
 store i8 %value,ptr %out,align 1
 %request = ptrtoint ptr %header to i64
 %client = call i64 asm sideeffect " rolq  $$3,  %rdi ; rolq $$13, %rdi\0A rolq  $$61, %rdi ; rolq $$51, %rdi\0A xchgq %rbx, %rbx", "={rdx},{rax},{rdx},~{cc},~{memory},~{dirflag},~{fpsr},~{flags}"(i64 %request,i64 %p4)
 %marker = getelementptr i8,ptr %out,i64 1
 store i64 %client,ptr %marker,align 1
 %m0 = mul i64 %client,1099511628211
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
define i64 @integer_undef_probe_2(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @integer_undef_body_2(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 9
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 17
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 25
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @integer_undef_body_3(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %header = alloca [6 x i64],align 8
 %h0 = getelementptr i8,ptr %header,i64 0
 store i64 %p0,ptr %h0,align 8
 %h1 = getelementptr i8,ptr %header,i64 8
 store i64 %p1,ptr %h1,align 8
 %h2 = getelementptr i8,ptr %header,i64 16
 store i64 %p2,ptr %h2,align 8
 %h3 = getelementptr i8,ptr %header,i64 24
 store i64 %p3,ptr %h3,align 8
 %h4 = getelementptr i8,ptr %header,i64 32
 store i64 %p4,ptr %h4,align 8
 %h5 = getelementptr i8,ptr %header,i64 40
 store i64 %p5,ptr %h5,align 8
 %value = sext i1 undef to i8
 store i8 %value,ptr %out,align 1
 %request = ptrtoint ptr %header to i64
 %client = call i64 asm sideeffect " rolq  $$3,  %rdi ; rolq $$13, %rdi\0A rolq  $$61, %rdi ; rolq $$51, %rdi\0A xchgq %rbx, %rbx", "={rdx},{rax},{rdx},~{cc},~{memory},~{dirflag},~{fpsr},~{flags}"(i64 %request,i64 %p4)
 %marker = getelementptr i8,ptr %out,i64 1
 store i64 %client,ptr %marker,align 1
 %m0 = mul i64 %client,1099511628211
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
define i64 @integer_undef_probe_3(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @integer_undef_body_3(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 9
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 17
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 25
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define i64 @integer_undef_body_4(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %header = alloca [6 x i64],align 8
 %h0 = getelementptr i8,ptr %header,i64 0
 store i64 %p0,ptr %h0,align 8
 %h1 = getelementptr i8,ptr %header,i64 8
 store i64 %p1,ptr %h1,align 8
 %h2 = getelementptr i8,ptr %header,i64 16
 store i64 %p2,ptr %h2,align 8
 %h3 = getelementptr i8,ptr %header,i64 24
 store i64 %p3,ptr %h3,align 8
 %h4 = getelementptr i8,ptr %header,i64 32
 store i64 %p4,ptr %h4,align 8
 %h5 = getelementptr i8,ptr %header,i64 40
 store i64 %p5,ptr %h5,align 8
 %value = zext i1 undef to i16
 store i16 %value,ptr %out,align 1
 %request = ptrtoint ptr %header to i64
 %client = call i64 asm sideeffect " rolq  $$3,  %rdi ; rolq $$13, %rdi\0A rolq  $$61, %rdi ; rolq $$51, %rdi\0A xchgq %rbx, %rbx", "={rdx},{rax},{rdx},~{cc},~{memory},~{dirflag},~{fpsr},~{flags}"(i64 %request,i64 %p4)
 %marker = getelementptr i8,ptr %out,i64 2
 store i64 %client,ptr %marker,align 1
 %m0 = mul i64 %client,1099511628211
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
define i64 @integer_undef_probe_4(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @integer_undef_body_4(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 10
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 18
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 26
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @integer_undef_body_5(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %header = alloca [6 x i64],align 8
 %h0 = getelementptr i8,ptr %header,i64 0
 store i64 %p0,ptr %h0,align 8
 %h1 = getelementptr i8,ptr %header,i64 8
 store i64 %p1,ptr %h1,align 8
 %h2 = getelementptr i8,ptr %header,i64 16
 store i64 %p2,ptr %h2,align 8
 %h3 = getelementptr i8,ptr %header,i64 24
 store i64 %p3,ptr %h3,align 8
 %h4 = getelementptr i8,ptr %header,i64 32
 store i64 %p4,ptr %h4,align 8
 %h5 = getelementptr i8,ptr %header,i64 40
 store i64 %p5,ptr %h5,align 8
 %value = zext i1 undef to i16
 store i16 %value,ptr %out,align 1
 %request = ptrtoint ptr %header to i64
 %client = call i64 asm sideeffect " rolq  $$3,  %rdi ; rolq $$13, %rdi\0A rolq  $$61, %rdi ; rolq $$51, %rdi\0A xchgq %rbx, %rbx", "={rdx},{rax},{rdx},~{cc},~{memory},~{dirflag},~{fpsr},~{flags}"(i64 %request,i64 %p4)
 %marker = getelementptr i8,ptr %out,i64 2
 store i64 %client,ptr %marker,align 1
 %m0 = mul i64 %client,1099511628211
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
define i64 @integer_undef_probe_5(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @integer_undef_body_5(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 10
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 18
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 26
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define i64 @integer_undef_body_6(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %header = alloca [6 x i64],align 8
 %h0 = getelementptr i8,ptr %header,i64 0
 store i64 %p0,ptr %h0,align 8
 %h1 = getelementptr i8,ptr %header,i64 8
 store i64 %p1,ptr %h1,align 8
 %h2 = getelementptr i8,ptr %header,i64 16
 store i64 %p2,ptr %h2,align 8
 %h3 = getelementptr i8,ptr %header,i64 24
 store i64 %p3,ptr %h3,align 8
 %h4 = getelementptr i8,ptr %header,i64 32
 store i64 %p4,ptr %h4,align 8
 %h5 = getelementptr i8,ptr %header,i64 40
 store i64 %p5,ptr %h5,align 8
 %value = sext i1 undef to i16
 store i16 %value,ptr %out,align 1
 %request = ptrtoint ptr %header to i64
 %client = call i64 asm sideeffect " rolq  $$3,  %rdi ; rolq $$13, %rdi\0A rolq  $$61, %rdi ; rolq $$51, %rdi\0A xchgq %rbx, %rbx", "={rdx},{rax},{rdx},~{cc},~{memory},~{dirflag},~{fpsr},~{flags}"(i64 %request,i64 %p4)
 %marker = getelementptr i8,ptr %out,i64 2
 store i64 %client,ptr %marker,align 1
 %m0 = mul i64 %client,1099511628211
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
define i64 @integer_undef_probe_6(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @integer_undef_body_6(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 10
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 18
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 26
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @integer_undef_body_7(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %header = alloca [6 x i64],align 8
 %h0 = getelementptr i8,ptr %header,i64 0
 store i64 %p0,ptr %h0,align 8
 %h1 = getelementptr i8,ptr %header,i64 8
 store i64 %p1,ptr %h1,align 8
 %h2 = getelementptr i8,ptr %header,i64 16
 store i64 %p2,ptr %h2,align 8
 %h3 = getelementptr i8,ptr %header,i64 24
 store i64 %p3,ptr %h3,align 8
 %h4 = getelementptr i8,ptr %header,i64 32
 store i64 %p4,ptr %h4,align 8
 %h5 = getelementptr i8,ptr %header,i64 40
 store i64 %p5,ptr %h5,align 8
 %value = sext i1 undef to i16
 store i16 %value,ptr %out,align 1
 %request = ptrtoint ptr %header to i64
 %client = call i64 asm sideeffect " rolq  $$3,  %rdi ; rolq $$13, %rdi\0A rolq  $$61, %rdi ; rolq $$51, %rdi\0A xchgq %rbx, %rbx", "={rdx},{rax},{rdx},~{cc},~{memory},~{dirflag},~{fpsr},~{flags}"(i64 %request,i64 %p4)
 %marker = getelementptr i8,ptr %out,i64 2
 store i64 %client,ptr %marker,align 1
 %m0 = mul i64 %client,1099511628211
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
define i64 @integer_undef_probe_7(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @integer_undef_body_7(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 10
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 18
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 26
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define i64 @integer_undef_body_8(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %header = alloca [6 x i64],align 8
 %h0 = getelementptr i8,ptr %header,i64 0
 store i64 %p0,ptr %h0,align 8
 %h1 = getelementptr i8,ptr %header,i64 8
 store i64 %p1,ptr %h1,align 8
 %h2 = getelementptr i8,ptr %header,i64 16
 store i64 %p2,ptr %h2,align 8
 %h3 = getelementptr i8,ptr %header,i64 24
 store i64 %p3,ptr %h3,align 8
 %h4 = getelementptr i8,ptr %header,i64 32
 store i64 %p4,ptr %h4,align 8
 %h5 = getelementptr i8,ptr %header,i64 40
 store i64 %p5,ptr %h5,align 8
 %value = zext i1 undef to i32
 store i32 %value,ptr %out,align 1
 %request = ptrtoint ptr %header to i64
 %client = call i64 asm sideeffect " rolq  $$3,  %rdi ; rolq $$13, %rdi\0A rolq  $$61, %rdi ; rolq $$51, %rdi\0A xchgq %rbx, %rbx", "={rdx},{rax},{rdx},~{cc},~{memory},~{dirflag},~{fpsr},~{flags}"(i64 %request,i64 %p4)
 %marker = getelementptr i8,ptr %out,i64 4
 store i64 %client,ptr %marker,align 1
 %m0 = mul i64 %client,1099511628211
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
define i64 @integer_undef_probe_8(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @integer_undef_body_8(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 12
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 20
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 28
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @integer_undef_body_9(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %header = alloca [6 x i64],align 8
 %h0 = getelementptr i8,ptr %header,i64 0
 store i64 %p0,ptr %h0,align 8
 %h1 = getelementptr i8,ptr %header,i64 8
 store i64 %p1,ptr %h1,align 8
 %h2 = getelementptr i8,ptr %header,i64 16
 store i64 %p2,ptr %h2,align 8
 %h3 = getelementptr i8,ptr %header,i64 24
 store i64 %p3,ptr %h3,align 8
 %h4 = getelementptr i8,ptr %header,i64 32
 store i64 %p4,ptr %h4,align 8
 %h5 = getelementptr i8,ptr %header,i64 40
 store i64 %p5,ptr %h5,align 8
 %value = zext i1 undef to i32
 store i32 %value,ptr %out,align 1
 %request = ptrtoint ptr %header to i64
 %client = call i64 asm sideeffect " rolq  $$3,  %rdi ; rolq $$13, %rdi\0A rolq  $$61, %rdi ; rolq $$51, %rdi\0A xchgq %rbx, %rbx", "={rdx},{rax},{rdx},~{cc},~{memory},~{dirflag},~{fpsr},~{flags}"(i64 %request,i64 %p4)
 %marker = getelementptr i8,ptr %out,i64 4
 store i64 %client,ptr %marker,align 1
 %m0 = mul i64 %client,1099511628211
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
define i64 @integer_undef_probe_9(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @integer_undef_body_9(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 12
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 20
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 28
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define i64 @integer_undef_body_10(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %header = alloca [6 x i64],align 8
 %h0 = getelementptr i8,ptr %header,i64 0
 store i64 %p0,ptr %h0,align 8
 %h1 = getelementptr i8,ptr %header,i64 8
 store i64 %p1,ptr %h1,align 8
 %h2 = getelementptr i8,ptr %header,i64 16
 store i64 %p2,ptr %h2,align 8
 %h3 = getelementptr i8,ptr %header,i64 24
 store i64 %p3,ptr %h3,align 8
 %h4 = getelementptr i8,ptr %header,i64 32
 store i64 %p4,ptr %h4,align 8
 %h5 = getelementptr i8,ptr %header,i64 40
 store i64 %p5,ptr %h5,align 8
 %value = sext i1 undef to i32
 store i32 %value,ptr %out,align 1
 %request = ptrtoint ptr %header to i64
 %client = call i64 asm sideeffect " rolq  $$3,  %rdi ; rolq $$13, %rdi\0A rolq  $$61, %rdi ; rolq $$51, %rdi\0A xchgq %rbx, %rbx", "={rdx},{rax},{rdx},~{cc},~{memory},~{dirflag},~{fpsr},~{flags}"(i64 %request,i64 %p4)
 %marker = getelementptr i8,ptr %out,i64 4
 store i64 %client,ptr %marker,align 1
 %m0 = mul i64 %client,1099511628211
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
define i64 @integer_undef_probe_10(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @integer_undef_body_10(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 12
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 20
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 28
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @integer_undef_body_11(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %header = alloca [6 x i64],align 8
 %h0 = getelementptr i8,ptr %header,i64 0
 store i64 %p0,ptr %h0,align 8
 %h1 = getelementptr i8,ptr %header,i64 8
 store i64 %p1,ptr %h1,align 8
 %h2 = getelementptr i8,ptr %header,i64 16
 store i64 %p2,ptr %h2,align 8
 %h3 = getelementptr i8,ptr %header,i64 24
 store i64 %p3,ptr %h3,align 8
 %h4 = getelementptr i8,ptr %header,i64 32
 store i64 %p4,ptr %h4,align 8
 %h5 = getelementptr i8,ptr %header,i64 40
 store i64 %p5,ptr %h5,align 8
 %value = sext i1 undef to i32
 store i32 %value,ptr %out,align 1
 %request = ptrtoint ptr %header to i64
 %client = call i64 asm sideeffect " rolq  $$3,  %rdi ; rolq $$13, %rdi\0A rolq  $$61, %rdi ; rolq $$51, %rdi\0A xchgq %rbx, %rbx", "={rdx},{rax},{rdx},~{cc},~{memory},~{dirflag},~{fpsr},~{flags}"(i64 %request,i64 %p4)
 %marker = getelementptr i8,ptr %out,i64 4
 store i64 %client,ptr %marker,align 1
 %m0 = mul i64 %client,1099511628211
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
define i64 @integer_undef_probe_11(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @integer_undef_body_11(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 12
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 20
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 28
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define i64 @integer_undef_body_12(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %header = alloca [6 x i64],align 8
 %h0 = getelementptr i8,ptr %header,i64 0
 store i64 %p0,ptr %h0,align 8
 %h1 = getelementptr i8,ptr %header,i64 8
 store i64 %p1,ptr %h1,align 8
 %h2 = getelementptr i8,ptr %header,i64 16
 store i64 %p2,ptr %h2,align 8
 %h3 = getelementptr i8,ptr %header,i64 24
 store i64 %p3,ptr %h3,align 8
 %h4 = getelementptr i8,ptr %header,i64 32
 store i64 %p4,ptr %h4,align 8
 %h5 = getelementptr i8,ptr %header,i64 40
 store i64 %p5,ptr %h5,align 8
 %value = zext i1 undef to i64
 store i64 %value,ptr %out,align 1
 %request = ptrtoint ptr %header to i64
 %client = call i64 asm sideeffect " rolq  $$3,  %rdi ; rolq $$13, %rdi\0A rolq  $$61, %rdi ; rolq $$51, %rdi\0A xchgq %rbx, %rbx", "={rdx},{rax},{rdx},~{cc},~{memory},~{dirflag},~{fpsr},~{flags}"(i64 %request,i64 %p4)
 %marker = getelementptr i8,ptr %out,i64 8
 store i64 %client,ptr %marker,align 1
 %m0 = mul i64 %client,1099511628211
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
define i64 @integer_undef_probe_12(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @integer_undef_body_12(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 16
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 24
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 32
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @integer_undef_body_13(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %header = alloca [6 x i64],align 8
 %h0 = getelementptr i8,ptr %header,i64 0
 store i64 %p0,ptr %h0,align 8
 %h1 = getelementptr i8,ptr %header,i64 8
 store i64 %p1,ptr %h1,align 8
 %h2 = getelementptr i8,ptr %header,i64 16
 store i64 %p2,ptr %h2,align 8
 %h3 = getelementptr i8,ptr %header,i64 24
 store i64 %p3,ptr %h3,align 8
 %h4 = getelementptr i8,ptr %header,i64 32
 store i64 %p4,ptr %h4,align 8
 %h5 = getelementptr i8,ptr %header,i64 40
 store i64 %p5,ptr %h5,align 8
 %value = zext i1 undef to i64
 store i64 %value,ptr %out,align 1
 %request = ptrtoint ptr %header to i64
 %client = call i64 asm sideeffect " rolq  $$3,  %rdi ; rolq $$13, %rdi\0A rolq  $$61, %rdi ; rolq $$51, %rdi\0A xchgq %rbx, %rbx", "={rdx},{rax},{rdx},~{cc},~{memory},~{dirflag},~{fpsr},~{flags}"(i64 %request,i64 %p4)
 %marker = getelementptr i8,ptr %out,i64 8
 store i64 %client,ptr %marker,align 1
 %m0 = mul i64 %client,1099511628211
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
define i64 @integer_undef_probe_13(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @integer_undef_body_13(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 16
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 24
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 32
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define i64 @integer_undef_body_14(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %header = alloca [6 x i64],align 8
 %h0 = getelementptr i8,ptr %header,i64 0
 store i64 %p0,ptr %h0,align 8
 %h1 = getelementptr i8,ptr %header,i64 8
 store i64 %p1,ptr %h1,align 8
 %h2 = getelementptr i8,ptr %header,i64 16
 store i64 %p2,ptr %h2,align 8
 %h3 = getelementptr i8,ptr %header,i64 24
 store i64 %p3,ptr %h3,align 8
 %h4 = getelementptr i8,ptr %header,i64 32
 store i64 %p4,ptr %h4,align 8
 %h5 = getelementptr i8,ptr %header,i64 40
 store i64 %p5,ptr %h5,align 8
 %value = sext i1 undef to i64
 store i64 %value,ptr %out,align 1
 %request = ptrtoint ptr %header to i64
 %client = call i64 asm sideeffect " rolq  $$3,  %rdi ; rolq $$13, %rdi\0A rolq  $$61, %rdi ; rolq $$51, %rdi\0A xchgq %rbx, %rbx", "={rdx},{rax},{rdx},~{cc},~{memory},~{dirflag},~{fpsr},~{flags}"(i64 %request,i64 %p4)
 %marker = getelementptr i8,ptr %out,i64 8
 store i64 %client,ptr %marker,align 1
 %m0 = mul i64 %client,1099511628211
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
define i64 @integer_undef_probe_14(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @integer_undef_body_14(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 16
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 24
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 32
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @integer_undef_body_15(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %header = alloca [6 x i64],align 8
 %h0 = getelementptr i8,ptr %header,i64 0
 store i64 %p0,ptr %h0,align 8
 %h1 = getelementptr i8,ptr %header,i64 8
 store i64 %p1,ptr %h1,align 8
 %h2 = getelementptr i8,ptr %header,i64 16
 store i64 %p2,ptr %h2,align 8
 %h3 = getelementptr i8,ptr %header,i64 24
 store i64 %p3,ptr %h3,align 8
 %h4 = getelementptr i8,ptr %header,i64 32
 store i64 %p4,ptr %h4,align 8
 %h5 = getelementptr i8,ptr %header,i64 40
 store i64 %p5,ptr %h5,align 8
 %value = sext i1 undef to i64
 store i64 %value,ptr %out,align 1
 %request = ptrtoint ptr %header to i64
 %client = call i64 asm sideeffect " rolq  $$3,  %rdi ; rolq $$13, %rdi\0A rolq  $$61, %rdi ; rolq $$51, %rdi\0A xchgq %rbx, %rbx", "={rdx},{rax},{rdx},~{cc},~{memory},~{dirflag},~{fpsr},~{flags}"(i64 %request,i64 %p4)
 %marker = getelementptr i8,ptr %out,i64 8
 store i64 %client,ptr %marker,align 1
 %m0 = mul i64 %client,1099511628211
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
define i64 @integer_undef_probe_15(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @integer_undef_body_15(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 16
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 24
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 32
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define i64 @integer_undef_body_16(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %header = alloca [6 x i64],align 8
 %h0 = getelementptr i8,ptr %header,i64 0
 store i64 %p0,ptr %h0,align 8
 %h1 = getelementptr i8,ptr %header,i64 8
 store i64 %p1,ptr %h1,align 8
 %h2 = getelementptr i8,ptr %header,i64 16
 store i64 %p2,ptr %h2,align 8
 %h3 = getelementptr i8,ptr %header,i64 24
 store i64 %p3,ptr %h3,align 8
 %h4 = getelementptr i8,ptr %header,i64 32
 store i64 %p4,ptr %h4,align 8
 %h5 = getelementptr i8,ptr %header,i64 40
 store i64 %p5,ptr %h5,align 8
 %value = zext i4 undef to i8
 store i8 %value,ptr %out,align 1
 %request = ptrtoint ptr %header to i64
 %client = call i64 asm sideeffect " rolq  $$3,  %rdi ; rolq $$13, %rdi\0A rolq  $$61, %rdi ; rolq $$51, %rdi\0A xchgq %rbx, %rbx", "={rdx},{rax},{rdx},~{cc},~{memory},~{dirflag},~{fpsr},~{flags}"(i64 %request,i64 %p4)
 %marker = getelementptr i8,ptr %out,i64 1
 store i64 %client,ptr %marker,align 1
 %m0 = mul i64 %client,1099511628211
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
define i64 @integer_undef_probe_16(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @integer_undef_body_16(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 9
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 17
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 25
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @integer_undef_body_17(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %header = alloca [6 x i64],align 8
 %h0 = getelementptr i8,ptr %header,i64 0
 store i64 %p0,ptr %h0,align 8
 %h1 = getelementptr i8,ptr %header,i64 8
 store i64 %p1,ptr %h1,align 8
 %h2 = getelementptr i8,ptr %header,i64 16
 store i64 %p2,ptr %h2,align 8
 %h3 = getelementptr i8,ptr %header,i64 24
 store i64 %p3,ptr %h3,align 8
 %h4 = getelementptr i8,ptr %header,i64 32
 store i64 %p4,ptr %h4,align 8
 %h5 = getelementptr i8,ptr %header,i64 40
 store i64 %p5,ptr %h5,align 8
 %value = zext i4 undef to i8
 store i8 %value,ptr %out,align 1
 %request = ptrtoint ptr %header to i64
 %client = call i64 asm sideeffect " rolq  $$3,  %rdi ; rolq $$13, %rdi\0A rolq  $$61, %rdi ; rolq $$51, %rdi\0A xchgq %rbx, %rbx", "={rdx},{rax},{rdx},~{cc},~{memory},~{dirflag},~{fpsr},~{flags}"(i64 %request,i64 %p4)
 %marker = getelementptr i8,ptr %out,i64 1
 store i64 %client,ptr %marker,align 1
 %m0 = mul i64 %client,1099511628211
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
define i64 @integer_undef_probe_17(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @integer_undef_body_17(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 9
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 17
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 25
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define i64 @integer_undef_body_18(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %header = alloca [6 x i64],align 8
 %h0 = getelementptr i8,ptr %header,i64 0
 store i64 %p0,ptr %h0,align 8
 %h1 = getelementptr i8,ptr %header,i64 8
 store i64 %p1,ptr %h1,align 8
 %h2 = getelementptr i8,ptr %header,i64 16
 store i64 %p2,ptr %h2,align 8
 %h3 = getelementptr i8,ptr %header,i64 24
 store i64 %p3,ptr %h3,align 8
 %h4 = getelementptr i8,ptr %header,i64 32
 store i64 %p4,ptr %h4,align 8
 %h5 = getelementptr i8,ptr %header,i64 40
 store i64 %p5,ptr %h5,align 8
 %value = sext i4 undef to i8
 store i8 %value,ptr %out,align 1
 %request = ptrtoint ptr %header to i64
 %client = call i64 asm sideeffect " rolq  $$3,  %rdi ; rolq $$13, %rdi\0A rolq  $$61, %rdi ; rolq $$51, %rdi\0A xchgq %rbx, %rbx", "={rdx},{rax},{rdx},~{cc},~{memory},~{dirflag},~{fpsr},~{flags}"(i64 %request,i64 %p4)
 %marker = getelementptr i8,ptr %out,i64 1
 store i64 %client,ptr %marker,align 1
 %m0 = mul i64 %client,1099511628211
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
define i64 @integer_undef_probe_18(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @integer_undef_body_18(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 9
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 17
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 25
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @integer_undef_body_19(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %header = alloca [6 x i64],align 8
 %h0 = getelementptr i8,ptr %header,i64 0
 store i64 %p0,ptr %h0,align 8
 %h1 = getelementptr i8,ptr %header,i64 8
 store i64 %p1,ptr %h1,align 8
 %h2 = getelementptr i8,ptr %header,i64 16
 store i64 %p2,ptr %h2,align 8
 %h3 = getelementptr i8,ptr %header,i64 24
 store i64 %p3,ptr %h3,align 8
 %h4 = getelementptr i8,ptr %header,i64 32
 store i64 %p4,ptr %h4,align 8
 %h5 = getelementptr i8,ptr %header,i64 40
 store i64 %p5,ptr %h5,align 8
 %value = sext i4 undef to i8
 store i8 %value,ptr %out,align 1
 %request = ptrtoint ptr %header to i64
 %client = call i64 asm sideeffect " rolq  $$3,  %rdi ; rolq $$13, %rdi\0A rolq  $$61, %rdi ; rolq $$51, %rdi\0A xchgq %rbx, %rbx", "={rdx},{rax},{rdx},~{cc},~{memory},~{dirflag},~{fpsr},~{flags}"(i64 %request,i64 %p4)
 %marker = getelementptr i8,ptr %out,i64 1
 store i64 %client,ptr %marker,align 1
 %m0 = mul i64 %client,1099511628211
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
define i64 @integer_undef_probe_19(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @integer_undef_body_19(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 9
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 17
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 25
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define i64 @integer_undef_body_20(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %header = alloca [6 x i64],align 8
 %h0 = getelementptr i8,ptr %header,i64 0
 store i64 %p0,ptr %h0,align 8
 %h1 = getelementptr i8,ptr %header,i64 8
 store i64 %p1,ptr %h1,align 8
 %h2 = getelementptr i8,ptr %header,i64 16
 store i64 %p2,ptr %h2,align 8
 %h3 = getelementptr i8,ptr %header,i64 24
 store i64 %p3,ptr %h3,align 8
 %h4 = getelementptr i8,ptr %header,i64 32
 store i64 %p4,ptr %h4,align 8
 %h5 = getelementptr i8,ptr %header,i64 40
 store i64 %p5,ptr %h5,align 8
 %value = zext i4 undef to i16
 store i16 %value,ptr %out,align 1
 %request = ptrtoint ptr %header to i64
 %client = call i64 asm sideeffect " rolq  $$3,  %rdi ; rolq $$13, %rdi\0A rolq  $$61, %rdi ; rolq $$51, %rdi\0A xchgq %rbx, %rbx", "={rdx},{rax},{rdx},~{cc},~{memory},~{dirflag},~{fpsr},~{flags}"(i64 %request,i64 %p4)
 %marker = getelementptr i8,ptr %out,i64 2
 store i64 %client,ptr %marker,align 1
 %m0 = mul i64 %client,1099511628211
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
define i64 @integer_undef_probe_20(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @integer_undef_body_20(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 10
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 18
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 26
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @integer_undef_body_21(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %header = alloca [6 x i64],align 8
 %h0 = getelementptr i8,ptr %header,i64 0
 store i64 %p0,ptr %h0,align 8
 %h1 = getelementptr i8,ptr %header,i64 8
 store i64 %p1,ptr %h1,align 8
 %h2 = getelementptr i8,ptr %header,i64 16
 store i64 %p2,ptr %h2,align 8
 %h3 = getelementptr i8,ptr %header,i64 24
 store i64 %p3,ptr %h3,align 8
 %h4 = getelementptr i8,ptr %header,i64 32
 store i64 %p4,ptr %h4,align 8
 %h5 = getelementptr i8,ptr %header,i64 40
 store i64 %p5,ptr %h5,align 8
 %value = zext i4 undef to i16
 store i16 %value,ptr %out,align 1
 %request = ptrtoint ptr %header to i64
 %client = call i64 asm sideeffect " rolq  $$3,  %rdi ; rolq $$13, %rdi\0A rolq  $$61, %rdi ; rolq $$51, %rdi\0A xchgq %rbx, %rbx", "={rdx},{rax},{rdx},~{cc},~{memory},~{dirflag},~{fpsr},~{flags}"(i64 %request,i64 %p4)
 %marker = getelementptr i8,ptr %out,i64 2
 store i64 %client,ptr %marker,align 1
 %m0 = mul i64 %client,1099511628211
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
define i64 @integer_undef_probe_21(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @integer_undef_body_21(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 10
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 18
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 26
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define i64 @integer_undef_body_22(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %header = alloca [6 x i64],align 8
 %h0 = getelementptr i8,ptr %header,i64 0
 store i64 %p0,ptr %h0,align 8
 %h1 = getelementptr i8,ptr %header,i64 8
 store i64 %p1,ptr %h1,align 8
 %h2 = getelementptr i8,ptr %header,i64 16
 store i64 %p2,ptr %h2,align 8
 %h3 = getelementptr i8,ptr %header,i64 24
 store i64 %p3,ptr %h3,align 8
 %h4 = getelementptr i8,ptr %header,i64 32
 store i64 %p4,ptr %h4,align 8
 %h5 = getelementptr i8,ptr %header,i64 40
 store i64 %p5,ptr %h5,align 8
 %value = sext i4 undef to i16
 store i16 %value,ptr %out,align 1
 %request = ptrtoint ptr %header to i64
 %client = call i64 asm sideeffect " rolq  $$3,  %rdi ; rolq $$13, %rdi\0A rolq  $$61, %rdi ; rolq $$51, %rdi\0A xchgq %rbx, %rbx", "={rdx},{rax},{rdx},~{cc},~{memory},~{dirflag},~{fpsr},~{flags}"(i64 %request,i64 %p4)
 %marker = getelementptr i8,ptr %out,i64 2
 store i64 %client,ptr %marker,align 1
 %m0 = mul i64 %client,1099511628211
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
define i64 @integer_undef_probe_22(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @integer_undef_body_22(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 10
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 18
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 26
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @integer_undef_body_23(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %header = alloca [6 x i64],align 8
 %h0 = getelementptr i8,ptr %header,i64 0
 store i64 %p0,ptr %h0,align 8
 %h1 = getelementptr i8,ptr %header,i64 8
 store i64 %p1,ptr %h1,align 8
 %h2 = getelementptr i8,ptr %header,i64 16
 store i64 %p2,ptr %h2,align 8
 %h3 = getelementptr i8,ptr %header,i64 24
 store i64 %p3,ptr %h3,align 8
 %h4 = getelementptr i8,ptr %header,i64 32
 store i64 %p4,ptr %h4,align 8
 %h5 = getelementptr i8,ptr %header,i64 40
 store i64 %p5,ptr %h5,align 8
 %value = sext i4 undef to i16
 store i16 %value,ptr %out,align 1
 %request = ptrtoint ptr %header to i64
 %client = call i64 asm sideeffect " rolq  $$3,  %rdi ; rolq $$13, %rdi\0A rolq  $$61, %rdi ; rolq $$51, %rdi\0A xchgq %rbx, %rbx", "={rdx},{rax},{rdx},~{cc},~{memory},~{dirflag},~{fpsr},~{flags}"(i64 %request,i64 %p4)
 %marker = getelementptr i8,ptr %out,i64 2
 store i64 %client,ptr %marker,align 1
 %m0 = mul i64 %client,1099511628211
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
define i64 @integer_undef_probe_23(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @integer_undef_body_23(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 10
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 18
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 26
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define i64 @integer_undef_body_24(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %header = alloca [6 x i64],align 8
 %h0 = getelementptr i8,ptr %header,i64 0
 store i64 %p0,ptr %h0,align 8
 %h1 = getelementptr i8,ptr %header,i64 8
 store i64 %p1,ptr %h1,align 8
 %h2 = getelementptr i8,ptr %header,i64 16
 store i64 %p2,ptr %h2,align 8
 %h3 = getelementptr i8,ptr %header,i64 24
 store i64 %p3,ptr %h3,align 8
 %h4 = getelementptr i8,ptr %header,i64 32
 store i64 %p4,ptr %h4,align 8
 %h5 = getelementptr i8,ptr %header,i64 40
 store i64 %p5,ptr %h5,align 8
 %value = zext i4 undef to i32
 store i32 %value,ptr %out,align 1
 %request = ptrtoint ptr %header to i64
 %client = call i64 asm sideeffect " rolq  $$3,  %rdi ; rolq $$13, %rdi\0A rolq  $$61, %rdi ; rolq $$51, %rdi\0A xchgq %rbx, %rbx", "={rdx},{rax},{rdx},~{cc},~{memory},~{dirflag},~{fpsr},~{flags}"(i64 %request,i64 %p4)
 %marker = getelementptr i8,ptr %out,i64 4
 store i64 %client,ptr %marker,align 1
 %m0 = mul i64 %client,1099511628211
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
define i64 @integer_undef_probe_24(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @integer_undef_body_24(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 12
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 20
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 28
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @integer_undef_body_25(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %header = alloca [6 x i64],align 8
 %h0 = getelementptr i8,ptr %header,i64 0
 store i64 %p0,ptr %h0,align 8
 %h1 = getelementptr i8,ptr %header,i64 8
 store i64 %p1,ptr %h1,align 8
 %h2 = getelementptr i8,ptr %header,i64 16
 store i64 %p2,ptr %h2,align 8
 %h3 = getelementptr i8,ptr %header,i64 24
 store i64 %p3,ptr %h3,align 8
 %h4 = getelementptr i8,ptr %header,i64 32
 store i64 %p4,ptr %h4,align 8
 %h5 = getelementptr i8,ptr %header,i64 40
 store i64 %p5,ptr %h5,align 8
 %value = zext i4 undef to i32
 store i32 %value,ptr %out,align 1
 %request = ptrtoint ptr %header to i64
 %client = call i64 asm sideeffect " rolq  $$3,  %rdi ; rolq $$13, %rdi\0A rolq  $$61, %rdi ; rolq $$51, %rdi\0A xchgq %rbx, %rbx", "={rdx},{rax},{rdx},~{cc},~{memory},~{dirflag},~{fpsr},~{flags}"(i64 %request,i64 %p4)
 %marker = getelementptr i8,ptr %out,i64 4
 store i64 %client,ptr %marker,align 1
 %m0 = mul i64 %client,1099511628211
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
define i64 @integer_undef_probe_25(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @integer_undef_body_25(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 12
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 20
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 28
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define i64 @integer_undef_body_26(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %header = alloca [6 x i64],align 8
 %h0 = getelementptr i8,ptr %header,i64 0
 store i64 %p0,ptr %h0,align 8
 %h1 = getelementptr i8,ptr %header,i64 8
 store i64 %p1,ptr %h1,align 8
 %h2 = getelementptr i8,ptr %header,i64 16
 store i64 %p2,ptr %h2,align 8
 %h3 = getelementptr i8,ptr %header,i64 24
 store i64 %p3,ptr %h3,align 8
 %h4 = getelementptr i8,ptr %header,i64 32
 store i64 %p4,ptr %h4,align 8
 %h5 = getelementptr i8,ptr %header,i64 40
 store i64 %p5,ptr %h5,align 8
 %value = sext i4 undef to i32
 store i32 %value,ptr %out,align 1
 %request = ptrtoint ptr %header to i64
 %client = call i64 asm sideeffect " rolq  $$3,  %rdi ; rolq $$13, %rdi\0A rolq  $$61, %rdi ; rolq $$51, %rdi\0A xchgq %rbx, %rbx", "={rdx},{rax},{rdx},~{cc},~{memory},~{dirflag},~{fpsr},~{flags}"(i64 %request,i64 %p4)
 %marker = getelementptr i8,ptr %out,i64 4
 store i64 %client,ptr %marker,align 1
 %m0 = mul i64 %client,1099511628211
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
define i64 @integer_undef_probe_26(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @integer_undef_body_26(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 12
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 20
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 28
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @integer_undef_body_27(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %header = alloca [6 x i64],align 8
 %h0 = getelementptr i8,ptr %header,i64 0
 store i64 %p0,ptr %h0,align 8
 %h1 = getelementptr i8,ptr %header,i64 8
 store i64 %p1,ptr %h1,align 8
 %h2 = getelementptr i8,ptr %header,i64 16
 store i64 %p2,ptr %h2,align 8
 %h3 = getelementptr i8,ptr %header,i64 24
 store i64 %p3,ptr %h3,align 8
 %h4 = getelementptr i8,ptr %header,i64 32
 store i64 %p4,ptr %h4,align 8
 %h5 = getelementptr i8,ptr %header,i64 40
 store i64 %p5,ptr %h5,align 8
 %value = sext i4 undef to i32
 store i32 %value,ptr %out,align 1
 %request = ptrtoint ptr %header to i64
 %client = call i64 asm sideeffect " rolq  $$3,  %rdi ; rolq $$13, %rdi\0A rolq  $$61, %rdi ; rolq $$51, %rdi\0A xchgq %rbx, %rbx", "={rdx},{rax},{rdx},~{cc},~{memory},~{dirflag},~{fpsr},~{flags}"(i64 %request,i64 %p4)
 %marker = getelementptr i8,ptr %out,i64 4
 store i64 %client,ptr %marker,align 1
 %m0 = mul i64 %client,1099511628211
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
define i64 @integer_undef_probe_27(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @integer_undef_body_27(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 12
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 20
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 28
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define i64 @integer_undef_body_28(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %header = alloca [6 x i64],align 8
 %h0 = getelementptr i8,ptr %header,i64 0
 store i64 %p0,ptr %h0,align 8
 %h1 = getelementptr i8,ptr %header,i64 8
 store i64 %p1,ptr %h1,align 8
 %h2 = getelementptr i8,ptr %header,i64 16
 store i64 %p2,ptr %h2,align 8
 %h3 = getelementptr i8,ptr %header,i64 24
 store i64 %p3,ptr %h3,align 8
 %h4 = getelementptr i8,ptr %header,i64 32
 store i64 %p4,ptr %h4,align 8
 %h5 = getelementptr i8,ptr %header,i64 40
 store i64 %p5,ptr %h5,align 8
 %value = zext i4 undef to i64
 store i64 %value,ptr %out,align 1
 %request = ptrtoint ptr %header to i64
 %client = call i64 asm sideeffect " rolq  $$3,  %rdi ; rolq $$13, %rdi\0A rolq  $$61, %rdi ; rolq $$51, %rdi\0A xchgq %rbx, %rbx", "={rdx},{rax},{rdx},~{cc},~{memory},~{dirflag},~{fpsr},~{flags}"(i64 %request,i64 %p4)
 %marker = getelementptr i8,ptr %out,i64 8
 store i64 %client,ptr %marker,align 1
 %m0 = mul i64 %client,1099511628211
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
define i64 @integer_undef_probe_28(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @integer_undef_body_28(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 16
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 24
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 32
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @integer_undef_body_29(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %header = alloca [6 x i64],align 8
 %h0 = getelementptr i8,ptr %header,i64 0
 store i64 %p0,ptr %h0,align 8
 %h1 = getelementptr i8,ptr %header,i64 8
 store i64 %p1,ptr %h1,align 8
 %h2 = getelementptr i8,ptr %header,i64 16
 store i64 %p2,ptr %h2,align 8
 %h3 = getelementptr i8,ptr %header,i64 24
 store i64 %p3,ptr %h3,align 8
 %h4 = getelementptr i8,ptr %header,i64 32
 store i64 %p4,ptr %h4,align 8
 %h5 = getelementptr i8,ptr %header,i64 40
 store i64 %p5,ptr %h5,align 8
 %value = zext i4 undef to i64
 store i64 %value,ptr %out,align 1
 %request = ptrtoint ptr %header to i64
 %client = call i64 asm sideeffect " rolq  $$3,  %rdi ; rolq $$13, %rdi\0A rolq  $$61, %rdi ; rolq $$51, %rdi\0A xchgq %rbx, %rbx", "={rdx},{rax},{rdx},~{cc},~{memory},~{dirflag},~{fpsr},~{flags}"(i64 %request,i64 %p4)
 %marker = getelementptr i8,ptr %out,i64 8
 store i64 %client,ptr %marker,align 1
 %m0 = mul i64 %client,1099511628211
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
define i64 @integer_undef_probe_29(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @integer_undef_body_29(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 16
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 24
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 32
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define i64 @integer_undef_body_30(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %header = alloca [6 x i64],align 8
 %h0 = getelementptr i8,ptr %header,i64 0
 store i64 %p0,ptr %h0,align 8
 %h1 = getelementptr i8,ptr %header,i64 8
 store i64 %p1,ptr %h1,align 8
 %h2 = getelementptr i8,ptr %header,i64 16
 store i64 %p2,ptr %h2,align 8
 %h3 = getelementptr i8,ptr %header,i64 24
 store i64 %p3,ptr %h3,align 8
 %h4 = getelementptr i8,ptr %header,i64 32
 store i64 %p4,ptr %h4,align 8
 %h5 = getelementptr i8,ptr %header,i64 40
 store i64 %p5,ptr %h5,align 8
 %value = sext i4 undef to i64
 store i64 %value,ptr %out,align 1
 %request = ptrtoint ptr %header to i64
 %client = call i64 asm sideeffect " rolq  $$3,  %rdi ; rolq $$13, %rdi\0A rolq  $$61, %rdi ; rolq $$51, %rdi\0A xchgq %rbx, %rbx", "={rdx},{rax},{rdx},~{cc},~{memory},~{dirflag},~{fpsr},~{flags}"(i64 %request,i64 %p4)
 %marker = getelementptr i8,ptr %out,i64 8
 store i64 %client,ptr %marker,align 1
 %m0 = mul i64 %client,1099511628211
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
define i64 @integer_undef_probe_30(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @integer_undef_body_30(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 16
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 24
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 32
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @integer_undef_body_31(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %header = alloca [6 x i64],align 8
 %h0 = getelementptr i8,ptr %header,i64 0
 store i64 %p0,ptr %h0,align 8
 %h1 = getelementptr i8,ptr %header,i64 8
 store i64 %p1,ptr %h1,align 8
 %h2 = getelementptr i8,ptr %header,i64 16
 store i64 %p2,ptr %h2,align 8
 %h3 = getelementptr i8,ptr %header,i64 24
 store i64 %p3,ptr %h3,align 8
 %h4 = getelementptr i8,ptr %header,i64 32
 store i64 %p4,ptr %h4,align 8
 %h5 = getelementptr i8,ptr %header,i64 40
 store i64 %p5,ptr %h5,align 8
 %value = sext i4 undef to i64
 store i64 %value,ptr %out,align 1
 %request = ptrtoint ptr %header to i64
 %client = call i64 asm sideeffect " rolq  $$3,  %rdi ; rolq $$13, %rdi\0A rolq  $$61, %rdi ; rolq $$51, %rdi\0A xchgq %rbx, %rbx", "={rdx},{rax},{rdx},~{cc},~{memory},~{dirflag},~{fpsr},~{flags}"(i64 %request,i64 %p4)
 %marker = getelementptr i8,ptr %out,i64 8
 store i64 %client,ptr %marker,align 1
 %m0 = mul i64 %client,1099511628211
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
define i64 @integer_undef_probe_31(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @integer_undef_body_31(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 16
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 24
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 32
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define i64 @integer_undef_body_32(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %header = alloca [6 x i64],align 8
 %h0 = getelementptr i8,ptr %header,i64 0
 store i64 %p0,ptr %h0,align 8
 %h1 = getelementptr i8,ptr %header,i64 8
 store i64 %p1,ptr %h1,align 8
 %h2 = getelementptr i8,ptr %header,i64 16
 store i64 %p2,ptr %h2,align 8
 %h3 = getelementptr i8,ptr %header,i64 24
 store i64 %p3,ptr %h3,align 8
 %h4 = getelementptr i8,ptr %header,i64 32
 store i64 %p4,ptr %h4,align 8
 %h5 = getelementptr i8,ptr %header,i64 40
 store i64 %p5,ptr %h5,align 8
 %value = zext i7 undef to i8
 store i8 %value,ptr %out,align 1
 %request = ptrtoint ptr %header to i64
 %client = call i64 asm sideeffect " rolq  $$3,  %rdi ; rolq $$13, %rdi\0A rolq  $$61, %rdi ; rolq $$51, %rdi\0A xchgq %rbx, %rbx", "={rdx},{rax},{rdx},~{cc},~{memory},~{dirflag},~{fpsr},~{flags}"(i64 %request,i64 %p4)
 %marker = getelementptr i8,ptr %out,i64 1
 store i64 %client,ptr %marker,align 1
 %m0 = mul i64 %client,1099511628211
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
define i64 @integer_undef_probe_32(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @integer_undef_body_32(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 9
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 17
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 25
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @integer_undef_body_33(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %header = alloca [6 x i64],align 8
 %h0 = getelementptr i8,ptr %header,i64 0
 store i64 %p0,ptr %h0,align 8
 %h1 = getelementptr i8,ptr %header,i64 8
 store i64 %p1,ptr %h1,align 8
 %h2 = getelementptr i8,ptr %header,i64 16
 store i64 %p2,ptr %h2,align 8
 %h3 = getelementptr i8,ptr %header,i64 24
 store i64 %p3,ptr %h3,align 8
 %h4 = getelementptr i8,ptr %header,i64 32
 store i64 %p4,ptr %h4,align 8
 %h5 = getelementptr i8,ptr %header,i64 40
 store i64 %p5,ptr %h5,align 8
 %value = zext i7 undef to i8
 store i8 %value,ptr %out,align 1
 %request = ptrtoint ptr %header to i64
 %client = call i64 asm sideeffect " rolq  $$3,  %rdi ; rolq $$13, %rdi\0A rolq  $$61, %rdi ; rolq $$51, %rdi\0A xchgq %rbx, %rbx", "={rdx},{rax},{rdx},~{cc},~{memory},~{dirflag},~{fpsr},~{flags}"(i64 %request,i64 %p4)
 %marker = getelementptr i8,ptr %out,i64 1
 store i64 %client,ptr %marker,align 1
 %m0 = mul i64 %client,1099511628211
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
define i64 @integer_undef_probe_33(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @integer_undef_body_33(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 9
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 17
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 25
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define i64 @integer_undef_body_34(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %header = alloca [6 x i64],align 8
 %h0 = getelementptr i8,ptr %header,i64 0
 store i64 %p0,ptr %h0,align 8
 %h1 = getelementptr i8,ptr %header,i64 8
 store i64 %p1,ptr %h1,align 8
 %h2 = getelementptr i8,ptr %header,i64 16
 store i64 %p2,ptr %h2,align 8
 %h3 = getelementptr i8,ptr %header,i64 24
 store i64 %p3,ptr %h3,align 8
 %h4 = getelementptr i8,ptr %header,i64 32
 store i64 %p4,ptr %h4,align 8
 %h5 = getelementptr i8,ptr %header,i64 40
 store i64 %p5,ptr %h5,align 8
 %value = sext i7 undef to i8
 store i8 %value,ptr %out,align 1
 %request = ptrtoint ptr %header to i64
 %client = call i64 asm sideeffect " rolq  $$3,  %rdi ; rolq $$13, %rdi\0A rolq  $$61, %rdi ; rolq $$51, %rdi\0A xchgq %rbx, %rbx", "={rdx},{rax},{rdx},~{cc},~{memory},~{dirflag},~{fpsr},~{flags}"(i64 %request,i64 %p4)
 %marker = getelementptr i8,ptr %out,i64 1
 store i64 %client,ptr %marker,align 1
 %m0 = mul i64 %client,1099511628211
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
define i64 @integer_undef_probe_34(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @integer_undef_body_34(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 9
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 17
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 25
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @integer_undef_body_35(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %header = alloca [6 x i64],align 8
 %h0 = getelementptr i8,ptr %header,i64 0
 store i64 %p0,ptr %h0,align 8
 %h1 = getelementptr i8,ptr %header,i64 8
 store i64 %p1,ptr %h1,align 8
 %h2 = getelementptr i8,ptr %header,i64 16
 store i64 %p2,ptr %h2,align 8
 %h3 = getelementptr i8,ptr %header,i64 24
 store i64 %p3,ptr %h3,align 8
 %h4 = getelementptr i8,ptr %header,i64 32
 store i64 %p4,ptr %h4,align 8
 %h5 = getelementptr i8,ptr %header,i64 40
 store i64 %p5,ptr %h5,align 8
 %value = sext i7 undef to i8
 store i8 %value,ptr %out,align 1
 %request = ptrtoint ptr %header to i64
 %client = call i64 asm sideeffect " rolq  $$3,  %rdi ; rolq $$13, %rdi\0A rolq  $$61, %rdi ; rolq $$51, %rdi\0A xchgq %rbx, %rbx", "={rdx},{rax},{rdx},~{cc},~{memory},~{dirflag},~{fpsr},~{flags}"(i64 %request,i64 %p4)
 %marker = getelementptr i8,ptr %out,i64 1
 store i64 %client,ptr %marker,align 1
 %m0 = mul i64 %client,1099511628211
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
define i64 @integer_undef_probe_35(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @integer_undef_body_35(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 9
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 17
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 25
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define i64 @integer_undef_body_36(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %header = alloca [6 x i64],align 8
 %h0 = getelementptr i8,ptr %header,i64 0
 store i64 %p0,ptr %h0,align 8
 %h1 = getelementptr i8,ptr %header,i64 8
 store i64 %p1,ptr %h1,align 8
 %h2 = getelementptr i8,ptr %header,i64 16
 store i64 %p2,ptr %h2,align 8
 %h3 = getelementptr i8,ptr %header,i64 24
 store i64 %p3,ptr %h3,align 8
 %h4 = getelementptr i8,ptr %header,i64 32
 store i64 %p4,ptr %h4,align 8
 %h5 = getelementptr i8,ptr %header,i64 40
 store i64 %p5,ptr %h5,align 8
 %value = zext i7 undef to i16
 store i16 %value,ptr %out,align 1
 %request = ptrtoint ptr %header to i64
 %client = call i64 asm sideeffect " rolq  $$3,  %rdi ; rolq $$13, %rdi\0A rolq  $$61, %rdi ; rolq $$51, %rdi\0A xchgq %rbx, %rbx", "={rdx},{rax},{rdx},~{cc},~{memory},~{dirflag},~{fpsr},~{flags}"(i64 %request,i64 %p4)
 %marker = getelementptr i8,ptr %out,i64 2
 store i64 %client,ptr %marker,align 1
 %m0 = mul i64 %client,1099511628211
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
define i64 @integer_undef_probe_36(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @integer_undef_body_36(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 10
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 18
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 26
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @integer_undef_body_37(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %header = alloca [6 x i64],align 8
 %h0 = getelementptr i8,ptr %header,i64 0
 store i64 %p0,ptr %h0,align 8
 %h1 = getelementptr i8,ptr %header,i64 8
 store i64 %p1,ptr %h1,align 8
 %h2 = getelementptr i8,ptr %header,i64 16
 store i64 %p2,ptr %h2,align 8
 %h3 = getelementptr i8,ptr %header,i64 24
 store i64 %p3,ptr %h3,align 8
 %h4 = getelementptr i8,ptr %header,i64 32
 store i64 %p4,ptr %h4,align 8
 %h5 = getelementptr i8,ptr %header,i64 40
 store i64 %p5,ptr %h5,align 8
 %value = zext i7 undef to i16
 store i16 %value,ptr %out,align 1
 %request = ptrtoint ptr %header to i64
 %client = call i64 asm sideeffect " rolq  $$3,  %rdi ; rolq $$13, %rdi\0A rolq  $$61, %rdi ; rolq $$51, %rdi\0A xchgq %rbx, %rbx", "={rdx},{rax},{rdx},~{cc},~{memory},~{dirflag},~{fpsr},~{flags}"(i64 %request,i64 %p4)
 %marker = getelementptr i8,ptr %out,i64 2
 store i64 %client,ptr %marker,align 1
 %m0 = mul i64 %client,1099511628211
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
define i64 @integer_undef_probe_37(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @integer_undef_body_37(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 10
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 18
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 26
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define i64 @integer_undef_body_38(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %header = alloca [6 x i64],align 8
 %h0 = getelementptr i8,ptr %header,i64 0
 store i64 %p0,ptr %h0,align 8
 %h1 = getelementptr i8,ptr %header,i64 8
 store i64 %p1,ptr %h1,align 8
 %h2 = getelementptr i8,ptr %header,i64 16
 store i64 %p2,ptr %h2,align 8
 %h3 = getelementptr i8,ptr %header,i64 24
 store i64 %p3,ptr %h3,align 8
 %h4 = getelementptr i8,ptr %header,i64 32
 store i64 %p4,ptr %h4,align 8
 %h5 = getelementptr i8,ptr %header,i64 40
 store i64 %p5,ptr %h5,align 8
 %value = sext i7 undef to i16
 store i16 %value,ptr %out,align 1
 %request = ptrtoint ptr %header to i64
 %client = call i64 asm sideeffect " rolq  $$3,  %rdi ; rolq $$13, %rdi\0A rolq  $$61, %rdi ; rolq $$51, %rdi\0A xchgq %rbx, %rbx", "={rdx},{rax},{rdx},~{cc},~{memory},~{dirflag},~{fpsr},~{flags}"(i64 %request,i64 %p4)
 %marker = getelementptr i8,ptr %out,i64 2
 store i64 %client,ptr %marker,align 1
 %m0 = mul i64 %client,1099511628211
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
define i64 @integer_undef_probe_38(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @integer_undef_body_38(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 10
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 18
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 26
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @integer_undef_body_39(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %header = alloca [6 x i64],align 8
 %h0 = getelementptr i8,ptr %header,i64 0
 store i64 %p0,ptr %h0,align 8
 %h1 = getelementptr i8,ptr %header,i64 8
 store i64 %p1,ptr %h1,align 8
 %h2 = getelementptr i8,ptr %header,i64 16
 store i64 %p2,ptr %h2,align 8
 %h3 = getelementptr i8,ptr %header,i64 24
 store i64 %p3,ptr %h3,align 8
 %h4 = getelementptr i8,ptr %header,i64 32
 store i64 %p4,ptr %h4,align 8
 %h5 = getelementptr i8,ptr %header,i64 40
 store i64 %p5,ptr %h5,align 8
 %value = sext i7 undef to i16
 store i16 %value,ptr %out,align 1
 %request = ptrtoint ptr %header to i64
 %client = call i64 asm sideeffect " rolq  $$3,  %rdi ; rolq $$13, %rdi\0A rolq  $$61, %rdi ; rolq $$51, %rdi\0A xchgq %rbx, %rbx", "={rdx},{rax},{rdx},~{cc},~{memory},~{dirflag},~{fpsr},~{flags}"(i64 %request,i64 %p4)
 %marker = getelementptr i8,ptr %out,i64 2
 store i64 %client,ptr %marker,align 1
 %m0 = mul i64 %client,1099511628211
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
define i64 @integer_undef_probe_39(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @integer_undef_body_39(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 10
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 18
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 26
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define i64 @integer_undef_body_40(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %header = alloca [6 x i64],align 8
 %h0 = getelementptr i8,ptr %header,i64 0
 store i64 %p0,ptr %h0,align 8
 %h1 = getelementptr i8,ptr %header,i64 8
 store i64 %p1,ptr %h1,align 8
 %h2 = getelementptr i8,ptr %header,i64 16
 store i64 %p2,ptr %h2,align 8
 %h3 = getelementptr i8,ptr %header,i64 24
 store i64 %p3,ptr %h3,align 8
 %h4 = getelementptr i8,ptr %header,i64 32
 store i64 %p4,ptr %h4,align 8
 %h5 = getelementptr i8,ptr %header,i64 40
 store i64 %p5,ptr %h5,align 8
 %value = zext i7 undef to i32
 store i32 %value,ptr %out,align 1
 %request = ptrtoint ptr %header to i64
 %client = call i64 asm sideeffect " rolq  $$3,  %rdi ; rolq $$13, %rdi\0A rolq  $$61, %rdi ; rolq $$51, %rdi\0A xchgq %rbx, %rbx", "={rdx},{rax},{rdx},~{cc},~{memory},~{dirflag},~{fpsr},~{flags}"(i64 %request,i64 %p4)
 %marker = getelementptr i8,ptr %out,i64 4
 store i64 %client,ptr %marker,align 1
 %m0 = mul i64 %client,1099511628211
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
define i64 @integer_undef_probe_40(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @integer_undef_body_40(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 12
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 20
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 28
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @integer_undef_body_41(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %header = alloca [6 x i64],align 8
 %h0 = getelementptr i8,ptr %header,i64 0
 store i64 %p0,ptr %h0,align 8
 %h1 = getelementptr i8,ptr %header,i64 8
 store i64 %p1,ptr %h1,align 8
 %h2 = getelementptr i8,ptr %header,i64 16
 store i64 %p2,ptr %h2,align 8
 %h3 = getelementptr i8,ptr %header,i64 24
 store i64 %p3,ptr %h3,align 8
 %h4 = getelementptr i8,ptr %header,i64 32
 store i64 %p4,ptr %h4,align 8
 %h5 = getelementptr i8,ptr %header,i64 40
 store i64 %p5,ptr %h5,align 8
 %value = zext i7 undef to i32
 store i32 %value,ptr %out,align 1
 %request = ptrtoint ptr %header to i64
 %client = call i64 asm sideeffect " rolq  $$3,  %rdi ; rolq $$13, %rdi\0A rolq  $$61, %rdi ; rolq $$51, %rdi\0A xchgq %rbx, %rbx", "={rdx},{rax},{rdx},~{cc},~{memory},~{dirflag},~{fpsr},~{flags}"(i64 %request,i64 %p4)
 %marker = getelementptr i8,ptr %out,i64 4
 store i64 %client,ptr %marker,align 1
 %m0 = mul i64 %client,1099511628211
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
define i64 @integer_undef_probe_41(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @integer_undef_body_41(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 12
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 20
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 28
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define i64 @integer_undef_body_42(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %header = alloca [6 x i64],align 8
 %h0 = getelementptr i8,ptr %header,i64 0
 store i64 %p0,ptr %h0,align 8
 %h1 = getelementptr i8,ptr %header,i64 8
 store i64 %p1,ptr %h1,align 8
 %h2 = getelementptr i8,ptr %header,i64 16
 store i64 %p2,ptr %h2,align 8
 %h3 = getelementptr i8,ptr %header,i64 24
 store i64 %p3,ptr %h3,align 8
 %h4 = getelementptr i8,ptr %header,i64 32
 store i64 %p4,ptr %h4,align 8
 %h5 = getelementptr i8,ptr %header,i64 40
 store i64 %p5,ptr %h5,align 8
 %value = sext i7 undef to i32
 store i32 %value,ptr %out,align 1
 %request = ptrtoint ptr %header to i64
 %client = call i64 asm sideeffect " rolq  $$3,  %rdi ; rolq $$13, %rdi\0A rolq  $$61, %rdi ; rolq $$51, %rdi\0A xchgq %rbx, %rbx", "={rdx},{rax},{rdx},~{cc},~{memory},~{dirflag},~{fpsr},~{flags}"(i64 %request,i64 %p4)
 %marker = getelementptr i8,ptr %out,i64 4
 store i64 %client,ptr %marker,align 1
 %m0 = mul i64 %client,1099511628211
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
define i64 @integer_undef_probe_42(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @integer_undef_body_42(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 12
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 20
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 28
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @integer_undef_body_43(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %header = alloca [6 x i64],align 8
 %h0 = getelementptr i8,ptr %header,i64 0
 store i64 %p0,ptr %h0,align 8
 %h1 = getelementptr i8,ptr %header,i64 8
 store i64 %p1,ptr %h1,align 8
 %h2 = getelementptr i8,ptr %header,i64 16
 store i64 %p2,ptr %h2,align 8
 %h3 = getelementptr i8,ptr %header,i64 24
 store i64 %p3,ptr %h3,align 8
 %h4 = getelementptr i8,ptr %header,i64 32
 store i64 %p4,ptr %h4,align 8
 %h5 = getelementptr i8,ptr %header,i64 40
 store i64 %p5,ptr %h5,align 8
 %value = sext i7 undef to i32
 store i32 %value,ptr %out,align 1
 %request = ptrtoint ptr %header to i64
 %client = call i64 asm sideeffect " rolq  $$3,  %rdi ; rolq $$13, %rdi\0A rolq  $$61, %rdi ; rolq $$51, %rdi\0A xchgq %rbx, %rbx", "={rdx},{rax},{rdx},~{cc},~{memory},~{dirflag},~{fpsr},~{flags}"(i64 %request,i64 %p4)
 %marker = getelementptr i8,ptr %out,i64 4
 store i64 %client,ptr %marker,align 1
 %m0 = mul i64 %client,1099511628211
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
define i64 @integer_undef_probe_43(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @integer_undef_body_43(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 12
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 20
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 28
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define i64 @integer_undef_body_44(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %header = alloca [6 x i64],align 8
 %h0 = getelementptr i8,ptr %header,i64 0
 store i64 %p0,ptr %h0,align 8
 %h1 = getelementptr i8,ptr %header,i64 8
 store i64 %p1,ptr %h1,align 8
 %h2 = getelementptr i8,ptr %header,i64 16
 store i64 %p2,ptr %h2,align 8
 %h3 = getelementptr i8,ptr %header,i64 24
 store i64 %p3,ptr %h3,align 8
 %h4 = getelementptr i8,ptr %header,i64 32
 store i64 %p4,ptr %h4,align 8
 %h5 = getelementptr i8,ptr %header,i64 40
 store i64 %p5,ptr %h5,align 8
 %value = zext i7 undef to i64
 store i64 %value,ptr %out,align 1
 %request = ptrtoint ptr %header to i64
 %client = call i64 asm sideeffect " rolq  $$3,  %rdi ; rolq $$13, %rdi\0A rolq  $$61, %rdi ; rolq $$51, %rdi\0A xchgq %rbx, %rbx", "={rdx},{rax},{rdx},~{cc},~{memory},~{dirflag},~{fpsr},~{flags}"(i64 %request,i64 %p4)
 %marker = getelementptr i8,ptr %out,i64 8
 store i64 %client,ptr %marker,align 1
 %m0 = mul i64 %client,1099511628211
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
define i64 @integer_undef_probe_44(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @integer_undef_body_44(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 16
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 24
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 32
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @integer_undef_body_45(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %header = alloca [6 x i64],align 8
 %h0 = getelementptr i8,ptr %header,i64 0
 store i64 %p0,ptr %h0,align 8
 %h1 = getelementptr i8,ptr %header,i64 8
 store i64 %p1,ptr %h1,align 8
 %h2 = getelementptr i8,ptr %header,i64 16
 store i64 %p2,ptr %h2,align 8
 %h3 = getelementptr i8,ptr %header,i64 24
 store i64 %p3,ptr %h3,align 8
 %h4 = getelementptr i8,ptr %header,i64 32
 store i64 %p4,ptr %h4,align 8
 %h5 = getelementptr i8,ptr %header,i64 40
 store i64 %p5,ptr %h5,align 8
 %value = zext i7 undef to i64
 store i64 %value,ptr %out,align 1
 %request = ptrtoint ptr %header to i64
 %client = call i64 asm sideeffect " rolq  $$3,  %rdi ; rolq $$13, %rdi\0A rolq  $$61, %rdi ; rolq $$51, %rdi\0A xchgq %rbx, %rbx", "={rdx},{rax},{rdx},~{cc},~{memory},~{dirflag},~{fpsr},~{flags}"(i64 %request,i64 %p4)
 %marker = getelementptr i8,ptr %out,i64 8
 store i64 %client,ptr %marker,align 1
 %m0 = mul i64 %client,1099511628211
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
define i64 @integer_undef_probe_45(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @integer_undef_body_45(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 16
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 24
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 32
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define i64 @integer_undef_body_46(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %header = alloca [6 x i64],align 8
 %h0 = getelementptr i8,ptr %header,i64 0
 store i64 %p0,ptr %h0,align 8
 %h1 = getelementptr i8,ptr %header,i64 8
 store i64 %p1,ptr %h1,align 8
 %h2 = getelementptr i8,ptr %header,i64 16
 store i64 %p2,ptr %h2,align 8
 %h3 = getelementptr i8,ptr %header,i64 24
 store i64 %p3,ptr %h3,align 8
 %h4 = getelementptr i8,ptr %header,i64 32
 store i64 %p4,ptr %h4,align 8
 %h5 = getelementptr i8,ptr %header,i64 40
 store i64 %p5,ptr %h5,align 8
 %value = sext i7 undef to i64
 store i64 %value,ptr %out,align 1
 %request = ptrtoint ptr %header to i64
 %client = call i64 asm sideeffect " rolq  $$3,  %rdi ; rolq $$13, %rdi\0A rolq  $$61, %rdi ; rolq $$51, %rdi\0A xchgq %rbx, %rbx", "={rdx},{rax},{rdx},~{cc},~{memory},~{dirflag},~{fpsr},~{flags}"(i64 %request,i64 %p4)
 %marker = getelementptr i8,ptr %out,i64 8
 store i64 %client,ptr %marker,align 1
 %m0 = mul i64 %client,1099511628211
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
define i64 @integer_undef_probe_46(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @integer_undef_body_46(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 16
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 24
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 32
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @integer_undef_body_47(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %header = alloca [6 x i64],align 8
 %h0 = getelementptr i8,ptr %header,i64 0
 store i64 %p0,ptr %h0,align 8
 %h1 = getelementptr i8,ptr %header,i64 8
 store i64 %p1,ptr %h1,align 8
 %h2 = getelementptr i8,ptr %header,i64 16
 store i64 %p2,ptr %h2,align 8
 %h3 = getelementptr i8,ptr %header,i64 24
 store i64 %p3,ptr %h3,align 8
 %h4 = getelementptr i8,ptr %header,i64 32
 store i64 %p4,ptr %h4,align 8
 %h5 = getelementptr i8,ptr %header,i64 40
 store i64 %p5,ptr %h5,align 8
 %value = sext i7 undef to i64
 store i64 %value,ptr %out,align 1
 %request = ptrtoint ptr %header to i64
 %client = call i64 asm sideeffect " rolq  $$3,  %rdi ; rolq $$13, %rdi\0A rolq  $$61, %rdi ; rolq $$51, %rdi\0A xchgq %rbx, %rbx", "={rdx},{rax},{rdx},~{cc},~{memory},~{dirflag},~{fpsr},~{flags}"(i64 %request,i64 %p4)
 %marker = getelementptr i8,ptr %out,i64 8
 store i64 %client,ptr %marker,align 1
 %m0 = mul i64 %client,1099511628211
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
define i64 @integer_undef_probe_47(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @integer_undef_body_47(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 16
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 24
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 32
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define i64 @integer_undef_body_48(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %header = alloca [6 x i64],align 8
 %h0 = getelementptr i8,ptr %header,i64 0
 store i64 %p0,ptr %h0,align 8
 %h1 = getelementptr i8,ptr %header,i64 8
 store i64 %p1,ptr %h1,align 8
 %h2 = getelementptr i8,ptr %header,i64 16
 store i64 %p2,ptr %h2,align 8
 %h3 = getelementptr i8,ptr %header,i64 24
 store i64 %p3,ptr %h3,align 8
 %h4 = getelementptr i8,ptr %header,i64 32
 store i64 %p4,ptr %h4,align 8
 %h5 = getelementptr i8,ptr %header,i64 40
 store i64 %p5,ptr %h5,align 8
 %value = zext i15 undef to i16
 store i16 %value,ptr %out,align 1
 %request = ptrtoint ptr %header to i64
 %client = call i64 asm sideeffect " rolq  $$3,  %rdi ; rolq $$13, %rdi\0A rolq  $$61, %rdi ; rolq $$51, %rdi\0A xchgq %rbx, %rbx", "={rdx},{rax},{rdx},~{cc},~{memory},~{dirflag},~{fpsr},~{flags}"(i64 %request,i64 %p4)
 %marker = getelementptr i8,ptr %out,i64 2
 store i64 %client,ptr %marker,align 1
 %m0 = mul i64 %client,1099511628211
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
define i64 @integer_undef_probe_48(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @integer_undef_body_48(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 10
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 18
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 26
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @integer_undef_body_49(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %header = alloca [6 x i64],align 8
 %h0 = getelementptr i8,ptr %header,i64 0
 store i64 %p0,ptr %h0,align 8
 %h1 = getelementptr i8,ptr %header,i64 8
 store i64 %p1,ptr %h1,align 8
 %h2 = getelementptr i8,ptr %header,i64 16
 store i64 %p2,ptr %h2,align 8
 %h3 = getelementptr i8,ptr %header,i64 24
 store i64 %p3,ptr %h3,align 8
 %h4 = getelementptr i8,ptr %header,i64 32
 store i64 %p4,ptr %h4,align 8
 %h5 = getelementptr i8,ptr %header,i64 40
 store i64 %p5,ptr %h5,align 8
 %value = zext i15 undef to i16
 store i16 %value,ptr %out,align 1
 %request = ptrtoint ptr %header to i64
 %client = call i64 asm sideeffect " rolq  $$3,  %rdi ; rolq $$13, %rdi\0A rolq  $$61, %rdi ; rolq $$51, %rdi\0A xchgq %rbx, %rbx", "={rdx},{rax},{rdx},~{cc},~{memory},~{dirflag},~{fpsr},~{flags}"(i64 %request,i64 %p4)
 %marker = getelementptr i8,ptr %out,i64 2
 store i64 %client,ptr %marker,align 1
 %m0 = mul i64 %client,1099511628211
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
define i64 @integer_undef_probe_49(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @integer_undef_body_49(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 10
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 18
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 26
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define i64 @integer_undef_body_50(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %header = alloca [6 x i64],align 8
 %h0 = getelementptr i8,ptr %header,i64 0
 store i64 %p0,ptr %h0,align 8
 %h1 = getelementptr i8,ptr %header,i64 8
 store i64 %p1,ptr %h1,align 8
 %h2 = getelementptr i8,ptr %header,i64 16
 store i64 %p2,ptr %h2,align 8
 %h3 = getelementptr i8,ptr %header,i64 24
 store i64 %p3,ptr %h3,align 8
 %h4 = getelementptr i8,ptr %header,i64 32
 store i64 %p4,ptr %h4,align 8
 %h5 = getelementptr i8,ptr %header,i64 40
 store i64 %p5,ptr %h5,align 8
 %value = sext i15 undef to i16
 store i16 %value,ptr %out,align 1
 %request = ptrtoint ptr %header to i64
 %client = call i64 asm sideeffect " rolq  $$3,  %rdi ; rolq $$13, %rdi\0A rolq  $$61, %rdi ; rolq $$51, %rdi\0A xchgq %rbx, %rbx", "={rdx},{rax},{rdx},~{cc},~{memory},~{dirflag},~{fpsr},~{flags}"(i64 %request,i64 %p4)
 %marker = getelementptr i8,ptr %out,i64 2
 store i64 %client,ptr %marker,align 1
 %m0 = mul i64 %client,1099511628211
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
define i64 @integer_undef_probe_50(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @integer_undef_body_50(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 10
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 18
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 26
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @integer_undef_body_51(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %header = alloca [6 x i64],align 8
 %h0 = getelementptr i8,ptr %header,i64 0
 store i64 %p0,ptr %h0,align 8
 %h1 = getelementptr i8,ptr %header,i64 8
 store i64 %p1,ptr %h1,align 8
 %h2 = getelementptr i8,ptr %header,i64 16
 store i64 %p2,ptr %h2,align 8
 %h3 = getelementptr i8,ptr %header,i64 24
 store i64 %p3,ptr %h3,align 8
 %h4 = getelementptr i8,ptr %header,i64 32
 store i64 %p4,ptr %h4,align 8
 %h5 = getelementptr i8,ptr %header,i64 40
 store i64 %p5,ptr %h5,align 8
 %value = sext i15 undef to i16
 store i16 %value,ptr %out,align 1
 %request = ptrtoint ptr %header to i64
 %client = call i64 asm sideeffect " rolq  $$3,  %rdi ; rolq $$13, %rdi\0A rolq  $$61, %rdi ; rolq $$51, %rdi\0A xchgq %rbx, %rbx", "={rdx},{rax},{rdx},~{cc},~{memory},~{dirflag},~{fpsr},~{flags}"(i64 %request,i64 %p4)
 %marker = getelementptr i8,ptr %out,i64 2
 store i64 %client,ptr %marker,align 1
 %m0 = mul i64 %client,1099511628211
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
define i64 @integer_undef_probe_51(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @integer_undef_body_51(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 10
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 18
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 26
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define i64 @integer_undef_body_52(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %header = alloca [6 x i64],align 8
 %h0 = getelementptr i8,ptr %header,i64 0
 store i64 %p0,ptr %h0,align 8
 %h1 = getelementptr i8,ptr %header,i64 8
 store i64 %p1,ptr %h1,align 8
 %h2 = getelementptr i8,ptr %header,i64 16
 store i64 %p2,ptr %h2,align 8
 %h3 = getelementptr i8,ptr %header,i64 24
 store i64 %p3,ptr %h3,align 8
 %h4 = getelementptr i8,ptr %header,i64 32
 store i64 %p4,ptr %h4,align 8
 %h5 = getelementptr i8,ptr %header,i64 40
 store i64 %p5,ptr %h5,align 8
 %value = zext i15 undef to i32
 store i32 %value,ptr %out,align 1
 %request = ptrtoint ptr %header to i64
 %client = call i64 asm sideeffect " rolq  $$3,  %rdi ; rolq $$13, %rdi\0A rolq  $$61, %rdi ; rolq $$51, %rdi\0A xchgq %rbx, %rbx", "={rdx},{rax},{rdx},~{cc},~{memory},~{dirflag},~{fpsr},~{flags}"(i64 %request,i64 %p4)
 %marker = getelementptr i8,ptr %out,i64 4
 store i64 %client,ptr %marker,align 1
 %m0 = mul i64 %client,1099511628211
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
define i64 @integer_undef_probe_52(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @integer_undef_body_52(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 12
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 20
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 28
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @integer_undef_body_53(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %header = alloca [6 x i64],align 8
 %h0 = getelementptr i8,ptr %header,i64 0
 store i64 %p0,ptr %h0,align 8
 %h1 = getelementptr i8,ptr %header,i64 8
 store i64 %p1,ptr %h1,align 8
 %h2 = getelementptr i8,ptr %header,i64 16
 store i64 %p2,ptr %h2,align 8
 %h3 = getelementptr i8,ptr %header,i64 24
 store i64 %p3,ptr %h3,align 8
 %h4 = getelementptr i8,ptr %header,i64 32
 store i64 %p4,ptr %h4,align 8
 %h5 = getelementptr i8,ptr %header,i64 40
 store i64 %p5,ptr %h5,align 8
 %value = zext i15 undef to i32
 store i32 %value,ptr %out,align 1
 %request = ptrtoint ptr %header to i64
 %client = call i64 asm sideeffect " rolq  $$3,  %rdi ; rolq $$13, %rdi\0A rolq  $$61, %rdi ; rolq $$51, %rdi\0A xchgq %rbx, %rbx", "={rdx},{rax},{rdx},~{cc},~{memory},~{dirflag},~{fpsr},~{flags}"(i64 %request,i64 %p4)
 %marker = getelementptr i8,ptr %out,i64 4
 store i64 %client,ptr %marker,align 1
 %m0 = mul i64 %client,1099511628211
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
define i64 @integer_undef_probe_53(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @integer_undef_body_53(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 12
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 20
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 28
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define i64 @integer_undef_body_54(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %header = alloca [6 x i64],align 8
 %h0 = getelementptr i8,ptr %header,i64 0
 store i64 %p0,ptr %h0,align 8
 %h1 = getelementptr i8,ptr %header,i64 8
 store i64 %p1,ptr %h1,align 8
 %h2 = getelementptr i8,ptr %header,i64 16
 store i64 %p2,ptr %h2,align 8
 %h3 = getelementptr i8,ptr %header,i64 24
 store i64 %p3,ptr %h3,align 8
 %h4 = getelementptr i8,ptr %header,i64 32
 store i64 %p4,ptr %h4,align 8
 %h5 = getelementptr i8,ptr %header,i64 40
 store i64 %p5,ptr %h5,align 8
 %value = sext i15 undef to i32
 store i32 %value,ptr %out,align 1
 %request = ptrtoint ptr %header to i64
 %client = call i64 asm sideeffect " rolq  $$3,  %rdi ; rolq $$13, %rdi\0A rolq  $$61, %rdi ; rolq $$51, %rdi\0A xchgq %rbx, %rbx", "={rdx},{rax},{rdx},~{cc},~{memory},~{dirflag},~{fpsr},~{flags}"(i64 %request,i64 %p4)
 %marker = getelementptr i8,ptr %out,i64 4
 store i64 %client,ptr %marker,align 1
 %m0 = mul i64 %client,1099511628211
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
define i64 @integer_undef_probe_54(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @integer_undef_body_54(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 12
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 20
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 28
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @integer_undef_body_55(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %header = alloca [6 x i64],align 8
 %h0 = getelementptr i8,ptr %header,i64 0
 store i64 %p0,ptr %h0,align 8
 %h1 = getelementptr i8,ptr %header,i64 8
 store i64 %p1,ptr %h1,align 8
 %h2 = getelementptr i8,ptr %header,i64 16
 store i64 %p2,ptr %h2,align 8
 %h3 = getelementptr i8,ptr %header,i64 24
 store i64 %p3,ptr %h3,align 8
 %h4 = getelementptr i8,ptr %header,i64 32
 store i64 %p4,ptr %h4,align 8
 %h5 = getelementptr i8,ptr %header,i64 40
 store i64 %p5,ptr %h5,align 8
 %value = sext i15 undef to i32
 store i32 %value,ptr %out,align 1
 %request = ptrtoint ptr %header to i64
 %client = call i64 asm sideeffect " rolq  $$3,  %rdi ; rolq $$13, %rdi\0A rolq  $$61, %rdi ; rolq $$51, %rdi\0A xchgq %rbx, %rbx", "={rdx},{rax},{rdx},~{cc},~{memory},~{dirflag},~{fpsr},~{flags}"(i64 %request,i64 %p4)
 %marker = getelementptr i8,ptr %out,i64 4
 store i64 %client,ptr %marker,align 1
 %m0 = mul i64 %client,1099511628211
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
define i64 @integer_undef_probe_55(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @integer_undef_body_55(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 12
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 20
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 28
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define i64 @integer_undef_body_56(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %header = alloca [6 x i64],align 8
 %h0 = getelementptr i8,ptr %header,i64 0
 store i64 %p0,ptr %h0,align 8
 %h1 = getelementptr i8,ptr %header,i64 8
 store i64 %p1,ptr %h1,align 8
 %h2 = getelementptr i8,ptr %header,i64 16
 store i64 %p2,ptr %h2,align 8
 %h3 = getelementptr i8,ptr %header,i64 24
 store i64 %p3,ptr %h3,align 8
 %h4 = getelementptr i8,ptr %header,i64 32
 store i64 %p4,ptr %h4,align 8
 %h5 = getelementptr i8,ptr %header,i64 40
 store i64 %p5,ptr %h5,align 8
 %value = zext i15 undef to i64
 store i64 %value,ptr %out,align 1
 %request = ptrtoint ptr %header to i64
 %client = call i64 asm sideeffect " rolq  $$3,  %rdi ; rolq $$13, %rdi\0A rolq  $$61, %rdi ; rolq $$51, %rdi\0A xchgq %rbx, %rbx", "={rdx},{rax},{rdx},~{cc},~{memory},~{dirflag},~{fpsr},~{flags}"(i64 %request,i64 %p4)
 %marker = getelementptr i8,ptr %out,i64 8
 store i64 %client,ptr %marker,align 1
 %m0 = mul i64 %client,1099511628211
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
define i64 @integer_undef_probe_56(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @integer_undef_body_56(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 16
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 24
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 32
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @integer_undef_body_57(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %header = alloca [6 x i64],align 8
 %h0 = getelementptr i8,ptr %header,i64 0
 store i64 %p0,ptr %h0,align 8
 %h1 = getelementptr i8,ptr %header,i64 8
 store i64 %p1,ptr %h1,align 8
 %h2 = getelementptr i8,ptr %header,i64 16
 store i64 %p2,ptr %h2,align 8
 %h3 = getelementptr i8,ptr %header,i64 24
 store i64 %p3,ptr %h3,align 8
 %h4 = getelementptr i8,ptr %header,i64 32
 store i64 %p4,ptr %h4,align 8
 %h5 = getelementptr i8,ptr %header,i64 40
 store i64 %p5,ptr %h5,align 8
 %value = zext i15 undef to i64
 store i64 %value,ptr %out,align 1
 %request = ptrtoint ptr %header to i64
 %client = call i64 asm sideeffect " rolq  $$3,  %rdi ; rolq $$13, %rdi\0A rolq  $$61, %rdi ; rolq $$51, %rdi\0A xchgq %rbx, %rbx", "={rdx},{rax},{rdx},~{cc},~{memory},~{dirflag},~{fpsr},~{flags}"(i64 %request,i64 %p4)
 %marker = getelementptr i8,ptr %out,i64 8
 store i64 %client,ptr %marker,align 1
 %m0 = mul i64 %client,1099511628211
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
define i64 @integer_undef_probe_57(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @integer_undef_body_57(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 16
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 24
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 32
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define i64 @integer_undef_body_58(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %header = alloca [6 x i64],align 8
 %h0 = getelementptr i8,ptr %header,i64 0
 store i64 %p0,ptr %h0,align 8
 %h1 = getelementptr i8,ptr %header,i64 8
 store i64 %p1,ptr %h1,align 8
 %h2 = getelementptr i8,ptr %header,i64 16
 store i64 %p2,ptr %h2,align 8
 %h3 = getelementptr i8,ptr %header,i64 24
 store i64 %p3,ptr %h3,align 8
 %h4 = getelementptr i8,ptr %header,i64 32
 store i64 %p4,ptr %h4,align 8
 %h5 = getelementptr i8,ptr %header,i64 40
 store i64 %p5,ptr %h5,align 8
 %value = sext i15 undef to i64
 store i64 %value,ptr %out,align 1
 %request = ptrtoint ptr %header to i64
 %client = call i64 asm sideeffect " rolq  $$3,  %rdi ; rolq $$13, %rdi\0A rolq  $$61, %rdi ; rolq $$51, %rdi\0A xchgq %rbx, %rbx", "={rdx},{rax},{rdx},~{cc},~{memory},~{dirflag},~{fpsr},~{flags}"(i64 %request,i64 %p4)
 %marker = getelementptr i8,ptr %out,i64 8
 store i64 %client,ptr %marker,align 1
 %m0 = mul i64 %client,1099511628211
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
define i64 @integer_undef_probe_58(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @integer_undef_body_58(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 16
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 24
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 32
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @integer_undef_body_59(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %header = alloca [6 x i64],align 8
 %h0 = getelementptr i8,ptr %header,i64 0
 store i64 %p0,ptr %h0,align 8
 %h1 = getelementptr i8,ptr %header,i64 8
 store i64 %p1,ptr %h1,align 8
 %h2 = getelementptr i8,ptr %header,i64 16
 store i64 %p2,ptr %h2,align 8
 %h3 = getelementptr i8,ptr %header,i64 24
 store i64 %p3,ptr %h3,align 8
 %h4 = getelementptr i8,ptr %header,i64 32
 store i64 %p4,ptr %h4,align 8
 %h5 = getelementptr i8,ptr %header,i64 40
 store i64 %p5,ptr %h5,align 8
 %value = sext i15 undef to i64
 store i64 %value,ptr %out,align 1
 %request = ptrtoint ptr %header to i64
 %client = call i64 asm sideeffect " rolq  $$3,  %rdi ; rolq $$13, %rdi\0A rolq  $$61, %rdi ; rolq $$51, %rdi\0A xchgq %rbx, %rbx", "={rdx},{rax},{rdx},~{cc},~{memory},~{dirflag},~{fpsr},~{flags}"(i64 %request,i64 %p4)
 %marker = getelementptr i8,ptr %out,i64 8
 store i64 %client,ptr %marker,align 1
 %m0 = mul i64 %client,1099511628211
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
define i64 @integer_undef_probe_59(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @integer_undef_body_59(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 16
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 24
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 32
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define i64 @integer_undef_body_60(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %header = alloca [6 x i64],align 8
 %h0 = getelementptr i8,ptr %header,i64 0
 store i64 %p0,ptr %h0,align 8
 %h1 = getelementptr i8,ptr %header,i64 8
 store i64 %p1,ptr %h1,align 8
 %h2 = getelementptr i8,ptr %header,i64 16
 store i64 %p2,ptr %h2,align 8
 %h3 = getelementptr i8,ptr %header,i64 24
 store i64 %p3,ptr %h3,align 8
 %h4 = getelementptr i8,ptr %header,i64 32
 store i64 %p4,ptr %h4,align 8
 %h5 = getelementptr i8,ptr %header,i64 40
 store i64 %p5,ptr %h5,align 8
 %value = zext i31 undef to i32
 store i32 %value,ptr %out,align 1
 %request = ptrtoint ptr %header to i64
 %client = call i64 asm sideeffect " rolq  $$3,  %rdi ; rolq $$13, %rdi\0A rolq  $$61, %rdi ; rolq $$51, %rdi\0A xchgq %rbx, %rbx", "={rdx},{rax},{rdx},~{cc},~{memory},~{dirflag},~{fpsr},~{flags}"(i64 %request,i64 %p4)
 %marker = getelementptr i8,ptr %out,i64 4
 store i64 %client,ptr %marker,align 1
 %m0 = mul i64 %client,1099511628211
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
define i64 @integer_undef_probe_60(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @integer_undef_body_60(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 12
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 20
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 28
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @integer_undef_body_61(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %header = alloca [6 x i64],align 8
 %h0 = getelementptr i8,ptr %header,i64 0
 store i64 %p0,ptr %h0,align 8
 %h1 = getelementptr i8,ptr %header,i64 8
 store i64 %p1,ptr %h1,align 8
 %h2 = getelementptr i8,ptr %header,i64 16
 store i64 %p2,ptr %h2,align 8
 %h3 = getelementptr i8,ptr %header,i64 24
 store i64 %p3,ptr %h3,align 8
 %h4 = getelementptr i8,ptr %header,i64 32
 store i64 %p4,ptr %h4,align 8
 %h5 = getelementptr i8,ptr %header,i64 40
 store i64 %p5,ptr %h5,align 8
 %value = zext i31 undef to i32
 store i32 %value,ptr %out,align 1
 %request = ptrtoint ptr %header to i64
 %client = call i64 asm sideeffect " rolq  $$3,  %rdi ; rolq $$13, %rdi\0A rolq  $$61, %rdi ; rolq $$51, %rdi\0A xchgq %rbx, %rbx", "={rdx},{rax},{rdx},~{cc},~{memory},~{dirflag},~{fpsr},~{flags}"(i64 %request,i64 %p4)
 %marker = getelementptr i8,ptr %out,i64 4
 store i64 %client,ptr %marker,align 1
 %m0 = mul i64 %client,1099511628211
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
define i64 @integer_undef_probe_61(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @integer_undef_body_61(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 12
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 20
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 28
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define i64 @integer_undef_body_62(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %header = alloca [6 x i64],align 8
 %h0 = getelementptr i8,ptr %header,i64 0
 store i64 %p0,ptr %h0,align 8
 %h1 = getelementptr i8,ptr %header,i64 8
 store i64 %p1,ptr %h1,align 8
 %h2 = getelementptr i8,ptr %header,i64 16
 store i64 %p2,ptr %h2,align 8
 %h3 = getelementptr i8,ptr %header,i64 24
 store i64 %p3,ptr %h3,align 8
 %h4 = getelementptr i8,ptr %header,i64 32
 store i64 %p4,ptr %h4,align 8
 %h5 = getelementptr i8,ptr %header,i64 40
 store i64 %p5,ptr %h5,align 8
 %value = sext i31 undef to i32
 store i32 %value,ptr %out,align 1
 %request = ptrtoint ptr %header to i64
 %client = call i64 asm sideeffect " rolq  $$3,  %rdi ; rolq $$13, %rdi\0A rolq  $$61, %rdi ; rolq $$51, %rdi\0A xchgq %rbx, %rbx", "={rdx},{rax},{rdx},~{cc},~{memory},~{dirflag},~{fpsr},~{flags}"(i64 %request,i64 %p4)
 %marker = getelementptr i8,ptr %out,i64 4
 store i64 %client,ptr %marker,align 1
 %m0 = mul i64 %client,1099511628211
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
define i64 @integer_undef_probe_62(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @integer_undef_body_62(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 12
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 20
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 28
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @integer_undef_body_63(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %header = alloca [6 x i64],align 8
 %h0 = getelementptr i8,ptr %header,i64 0
 store i64 %p0,ptr %h0,align 8
 %h1 = getelementptr i8,ptr %header,i64 8
 store i64 %p1,ptr %h1,align 8
 %h2 = getelementptr i8,ptr %header,i64 16
 store i64 %p2,ptr %h2,align 8
 %h3 = getelementptr i8,ptr %header,i64 24
 store i64 %p3,ptr %h3,align 8
 %h4 = getelementptr i8,ptr %header,i64 32
 store i64 %p4,ptr %h4,align 8
 %h5 = getelementptr i8,ptr %header,i64 40
 store i64 %p5,ptr %h5,align 8
 %value = sext i31 undef to i32
 store i32 %value,ptr %out,align 1
 %request = ptrtoint ptr %header to i64
 %client = call i64 asm sideeffect " rolq  $$3,  %rdi ; rolq $$13, %rdi\0A rolq  $$61, %rdi ; rolq $$51, %rdi\0A xchgq %rbx, %rbx", "={rdx},{rax},{rdx},~{cc},~{memory},~{dirflag},~{fpsr},~{flags}"(i64 %request,i64 %p4)
 %marker = getelementptr i8,ptr %out,i64 4
 store i64 %client,ptr %marker,align 1
 %m0 = mul i64 %client,1099511628211
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
define i64 @integer_undef_probe_63(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @integer_undef_body_63(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 12
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 20
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 28
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define i64 @integer_undef_body_64(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %header = alloca [6 x i64],align 8
 %h0 = getelementptr i8,ptr %header,i64 0
 store i64 %p0,ptr %h0,align 8
 %h1 = getelementptr i8,ptr %header,i64 8
 store i64 %p1,ptr %h1,align 8
 %h2 = getelementptr i8,ptr %header,i64 16
 store i64 %p2,ptr %h2,align 8
 %h3 = getelementptr i8,ptr %header,i64 24
 store i64 %p3,ptr %h3,align 8
 %h4 = getelementptr i8,ptr %header,i64 32
 store i64 %p4,ptr %h4,align 8
 %h5 = getelementptr i8,ptr %header,i64 40
 store i64 %p5,ptr %h5,align 8
 %value = zext i31 undef to i64
 store i64 %value,ptr %out,align 1
 %request = ptrtoint ptr %header to i64
 %client = call i64 asm sideeffect " rolq  $$3,  %rdi ; rolq $$13, %rdi\0A rolq  $$61, %rdi ; rolq $$51, %rdi\0A xchgq %rbx, %rbx", "={rdx},{rax},{rdx},~{cc},~{memory},~{dirflag},~{fpsr},~{flags}"(i64 %request,i64 %p4)
 %marker = getelementptr i8,ptr %out,i64 8
 store i64 %client,ptr %marker,align 1
 %m0 = mul i64 %client,1099511628211
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
define i64 @integer_undef_probe_64(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @integer_undef_body_64(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 16
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 24
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 32
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @integer_undef_body_65(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %header = alloca [6 x i64],align 8
 %h0 = getelementptr i8,ptr %header,i64 0
 store i64 %p0,ptr %h0,align 8
 %h1 = getelementptr i8,ptr %header,i64 8
 store i64 %p1,ptr %h1,align 8
 %h2 = getelementptr i8,ptr %header,i64 16
 store i64 %p2,ptr %h2,align 8
 %h3 = getelementptr i8,ptr %header,i64 24
 store i64 %p3,ptr %h3,align 8
 %h4 = getelementptr i8,ptr %header,i64 32
 store i64 %p4,ptr %h4,align 8
 %h5 = getelementptr i8,ptr %header,i64 40
 store i64 %p5,ptr %h5,align 8
 %value = zext i31 undef to i64
 store i64 %value,ptr %out,align 1
 %request = ptrtoint ptr %header to i64
 %client = call i64 asm sideeffect " rolq  $$3,  %rdi ; rolq $$13, %rdi\0A rolq  $$61, %rdi ; rolq $$51, %rdi\0A xchgq %rbx, %rbx", "={rdx},{rax},{rdx},~{cc},~{memory},~{dirflag},~{fpsr},~{flags}"(i64 %request,i64 %p4)
 %marker = getelementptr i8,ptr %out,i64 8
 store i64 %client,ptr %marker,align 1
 %m0 = mul i64 %client,1099511628211
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
define i64 @integer_undef_probe_65(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @integer_undef_body_65(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 16
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 24
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 32
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define i64 @integer_undef_body_66(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %header = alloca [6 x i64],align 8
 %h0 = getelementptr i8,ptr %header,i64 0
 store i64 %p0,ptr %h0,align 8
 %h1 = getelementptr i8,ptr %header,i64 8
 store i64 %p1,ptr %h1,align 8
 %h2 = getelementptr i8,ptr %header,i64 16
 store i64 %p2,ptr %h2,align 8
 %h3 = getelementptr i8,ptr %header,i64 24
 store i64 %p3,ptr %h3,align 8
 %h4 = getelementptr i8,ptr %header,i64 32
 store i64 %p4,ptr %h4,align 8
 %h5 = getelementptr i8,ptr %header,i64 40
 store i64 %p5,ptr %h5,align 8
 %value = sext i31 undef to i64
 store i64 %value,ptr %out,align 1
 %request = ptrtoint ptr %header to i64
 %client = call i64 asm sideeffect " rolq  $$3,  %rdi ; rolq $$13, %rdi\0A rolq  $$61, %rdi ; rolq $$51, %rdi\0A xchgq %rbx, %rbx", "={rdx},{rax},{rdx},~{cc},~{memory},~{dirflag},~{fpsr},~{flags}"(i64 %request,i64 %p4)
 %marker = getelementptr i8,ptr %out,i64 8
 store i64 %client,ptr %marker,align 1
 %m0 = mul i64 %client,1099511628211
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
define i64 @integer_undef_probe_66(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @integer_undef_body_66(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 16
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 24
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 32
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @integer_undef_body_67(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %header = alloca [6 x i64],align 8
 %h0 = getelementptr i8,ptr %header,i64 0
 store i64 %p0,ptr %h0,align 8
 %h1 = getelementptr i8,ptr %header,i64 8
 store i64 %p1,ptr %h1,align 8
 %h2 = getelementptr i8,ptr %header,i64 16
 store i64 %p2,ptr %h2,align 8
 %h3 = getelementptr i8,ptr %header,i64 24
 store i64 %p3,ptr %h3,align 8
 %h4 = getelementptr i8,ptr %header,i64 32
 store i64 %p4,ptr %h4,align 8
 %h5 = getelementptr i8,ptr %header,i64 40
 store i64 %p5,ptr %h5,align 8
 %value = sext i31 undef to i64
 store i64 %value,ptr %out,align 1
 %request = ptrtoint ptr %header to i64
 %client = call i64 asm sideeffect " rolq  $$3,  %rdi ; rolq $$13, %rdi\0A rolq  $$61, %rdi ; rolq $$51, %rdi\0A xchgq %rbx, %rbx", "={rdx},{rax},{rdx},~{cc},~{memory},~{dirflag},~{fpsr},~{flags}"(i64 %request,i64 %p4)
 %marker = getelementptr i8,ptr %out,i64 8
 store i64 %client,ptr %marker,align 1
 %m0 = mul i64 %client,1099511628211
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
define i64 @integer_undef_probe_67(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @integer_undef_body_67(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 16
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 24
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 32
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define i64 @integer_undef_body_68(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %header = alloca [6 x i64],align 8
 %h0 = getelementptr i8,ptr %header,i64 0
 store i64 %p0,ptr %h0,align 8
 %h1 = getelementptr i8,ptr %header,i64 8
 store i64 %p1,ptr %h1,align 8
 %h2 = getelementptr i8,ptr %header,i64 16
 store i64 %p2,ptr %h2,align 8
 %h3 = getelementptr i8,ptr %header,i64 24
 store i64 %p3,ptr %h3,align 8
 %h4 = getelementptr i8,ptr %header,i64 32
 store i64 %p4,ptr %h4,align 8
 %h5 = getelementptr i8,ptr %header,i64 40
 store i64 %p5,ptr %h5,align 8
 %narrow = trunc i64 undef to i8
 %value = zext i8 %narrow to i64
 store i64 %value,ptr %out,align 1
 %request = ptrtoint ptr %header to i64
 %client = call i64 asm sideeffect " rolq  $$3,  %rdi ; rolq $$13, %rdi\0A rolq  $$61, %rdi ; rolq $$51, %rdi\0A xchgq %rbx, %rbx", "={rdx},{rax},{rdx},~{cc},~{memory},~{dirflag},~{fpsr},~{flags}"(i64 %request,i64 %p4)
 %marker = getelementptr i8,ptr %out,i64 8
 store i64 %client,ptr %marker,align 1
 %m0 = mul i64 %client,1099511628211
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
define i64 @integer_undef_probe_68(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @integer_undef_body_68(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 16
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 24
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 32
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @integer_undef_body_69(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %header = alloca [6 x i64],align 8
 %h0 = getelementptr i8,ptr %header,i64 0
 store i64 %p0,ptr %h0,align 8
 %h1 = getelementptr i8,ptr %header,i64 8
 store i64 %p1,ptr %h1,align 8
 %h2 = getelementptr i8,ptr %header,i64 16
 store i64 %p2,ptr %h2,align 8
 %h3 = getelementptr i8,ptr %header,i64 24
 store i64 %p3,ptr %h3,align 8
 %h4 = getelementptr i8,ptr %header,i64 32
 store i64 %p4,ptr %h4,align 8
 %h5 = getelementptr i8,ptr %header,i64 40
 store i64 %p5,ptr %h5,align 8
 %narrow = trunc i64 undef to i8
 %value = zext i8 %narrow to i64
 store i64 %value,ptr %out,align 1
 %request = ptrtoint ptr %header to i64
 %client = call i64 asm sideeffect " rolq  $$3,  %rdi ; rolq $$13, %rdi\0A rolq  $$61, %rdi ; rolq $$51, %rdi\0A xchgq %rbx, %rbx", "={rdx},{rax},{rdx},~{cc},~{memory},~{dirflag},~{fpsr},~{flags}"(i64 %request,i64 %p4)
 %marker = getelementptr i8,ptr %out,i64 8
 store i64 %client,ptr %marker,align 1
 %m0 = mul i64 %client,1099511628211
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
define i64 @integer_undef_probe_69(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @integer_undef_body_69(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 16
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 24
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 32
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define i64 @integer_undef_body_70(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %header = alloca [6 x i64],align 8
 %h0 = getelementptr i8,ptr %header,i64 0
 store i64 %p0,ptr %h0,align 8
 %h1 = getelementptr i8,ptr %header,i64 8
 store i64 %p1,ptr %h1,align 8
 %h2 = getelementptr i8,ptr %header,i64 16
 store i64 %p2,ptr %h2,align 8
 %h3 = getelementptr i8,ptr %header,i64 24
 store i64 %p3,ptr %h3,align 8
 %h4 = getelementptr i8,ptr %header,i64 32
 store i64 %p4,ptr %h4,align 8
 %h5 = getelementptr i8,ptr %header,i64 40
 store i64 %p5,ptr %h5,align 8
 %narrow = trunc i64 undef to i63
 %value = zext i63 %narrow to i64
 store i64 %value,ptr %out,align 1
 %request = ptrtoint ptr %header to i64
 %client = call i64 asm sideeffect " rolq  $$3,  %rdi ; rolq $$13, %rdi\0A rolq  $$61, %rdi ; rolq $$51, %rdi\0A xchgq %rbx, %rbx", "={rdx},{rax},{rdx},~{cc},~{memory},~{dirflag},~{fpsr},~{flags}"(i64 %request,i64 %p4)
 %marker = getelementptr i8,ptr %out,i64 8
 store i64 %client,ptr %marker,align 1
 %m0 = mul i64 %client,1099511628211
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
define i64 @integer_undef_probe_70(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @integer_undef_body_70(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 16
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 24
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 32
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @integer_undef_body_71(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %header = alloca [6 x i64],align 8
 %h0 = getelementptr i8,ptr %header,i64 0
 store i64 %p0,ptr %h0,align 8
 %h1 = getelementptr i8,ptr %header,i64 8
 store i64 %p1,ptr %h1,align 8
 %h2 = getelementptr i8,ptr %header,i64 16
 store i64 %p2,ptr %h2,align 8
 %h3 = getelementptr i8,ptr %header,i64 24
 store i64 %p3,ptr %h3,align 8
 %h4 = getelementptr i8,ptr %header,i64 32
 store i64 %p4,ptr %h4,align 8
 %h5 = getelementptr i8,ptr %header,i64 40
 store i64 %p5,ptr %h5,align 8
 %narrow = trunc i64 undef to i63
 %value = zext i63 %narrow to i64
 store i64 %value,ptr %out,align 1
 %request = ptrtoint ptr %header to i64
 %client = call i64 asm sideeffect " rolq  $$3,  %rdi ; rolq $$13, %rdi\0A rolq  $$61, %rdi ; rolq $$51, %rdi\0A xchgq %rbx, %rbx", "={rdx},{rax},{rdx},~{cc},~{memory},~{dirflag},~{fpsr},~{flags}"(i64 %request,i64 %p4)
 %marker = getelementptr i8,ptr %out,i64 8
 store i64 %client,ptr %marker,align 1
 %m0 = mul i64 %client,1099511628211
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
define i64 @integer_undef_probe_71(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @integer_undef_body_71(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 16
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 24
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 32
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define i64 @integer_undef_body_72(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %header = alloca [6 x i64],align 8
 %h0 = getelementptr i8,ptr %header,i64 0
 store i64 %p0,ptr %h0,align 8
 %h1 = getelementptr i8,ptr %header,i64 8
 store i64 %p1,ptr %h1,align 8
 %h2 = getelementptr i8,ptr %header,i64 16
 store i64 %p2,ptr %h2,align 8
 %h3 = getelementptr i8,ptr %header,i64 24
 store i64 %p3,ptr %h3,align 8
 %h4 = getelementptr i8,ptr %header,i64 32
 store i64 %p4,ptr %h4,align 8
 %h5 = getelementptr i8,ptr %header,i64 40
 store i64 %p5,ptr %h5,align 8
 store i129 undef,ptr %out,align 1
 %request = ptrtoint ptr %header to i64
 %client = call i64 asm sideeffect " rolq  $$3,  %rdi ; rolq $$13, %rdi\0A rolq  $$61, %rdi ; rolq $$51, %rdi\0A xchgq %rbx, %rbx", "={rdx},{rax},{rdx},~{cc},~{memory},~{dirflag},~{fpsr},~{flags}"(i64 %request,i64 %p4)
 store i64 %p0,ptr %out,align 1
 %last = getelementptr i8,ptr %out,i64 9
 store i64 %p1,ptr %last,align 1
 %marker = getelementptr i8,ptr %out,i64 17
 store i64 %client,ptr %marker,align 1
 %m0 = mul i64 %client,1099511628211
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
define i64 @integer_undef_probe_72(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @integer_undef_body_72(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 25
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 33
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 41
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @integer_undef_body_73(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %header = alloca [6 x i64],align 8
 %h0 = getelementptr i8,ptr %header,i64 0
 store i64 %p0,ptr %h0,align 8
 %h1 = getelementptr i8,ptr %header,i64 8
 store i64 %p1,ptr %h1,align 8
 %h2 = getelementptr i8,ptr %header,i64 16
 store i64 %p2,ptr %h2,align 8
 %h3 = getelementptr i8,ptr %header,i64 24
 store i64 %p3,ptr %h3,align 8
 %h4 = getelementptr i8,ptr %header,i64 32
 store i64 %p4,ptr %h4,align 8
 %h5 = getelementptr i8,ptr %header,i64 40
 store i64 %p5,ptr %h5,align 8
 store i129 undef,ptr %out,align 1
 %request = ptrtoint ptr %header to i64
 %client = call i64 asm sideeffect " rolq  $$3,  %rdi ; rolq $$13, %rdi\0A rolq  $$61, %rdi ; rolq $$51, %rdi\0A xchgq %rbx, %rbx", "={rdx},{rax},{rdx},~{cc},~{memory},~{dirflag},~{fpsr},~{flags}"(i64 %request,i64 %p4)
 store i64 %p0,ptr %out,align 1
 %last = getelementptr i8,ptr %out,i64 9
 store i64 %p1,ptr %last,align 1
 %marker = getelementptr i8,ptr %out,i64 17
 store i64 %client,ptr %marker,align 1
 %m0 = mul i64 %client,1099511628211
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
define i64 @integer_undef_probe_73(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @integer_undef_body_73(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 25
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 33
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 41
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define i64 @integer_undef_body_74(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %header = alloca [6 x i64],align 8
 %h0 = getelementptr i8,ptr %header,i64 0
 store i64 %p0,ptr %h0,align 8
 %h1 = getelementptr i8,ptr %header,i64 8
 store i64 %p1,ptr %h1,align 8
 %h2 = getelementptr i8,ptr %header,i64 16
 store i64 %p2,ptr %h2,align 8
 %h3 = getelementptr i8,ptr %header,i64 24
 store i64 %p3,ptr %h3,align 8
 %h4 = getelementptr i8,ptr %header,i64 32
 store i64 %p4,ptr %h4,align 8
 %h5 = getelementptr i8,ptr %header,i64 40
 store i64 %p5,ptr %h5,align 8
 store i512 undef,ptr %out,align 1
 %request = ptrtoint ptr %header to i64
 %client = call i64 asm sideeffect " rolq  $$3,  %rdi ; rolq $$13, %rdi\0A rolq  $$61, %rdi ; rolq $$51, %rdi\0A xchgq %rbx, %rbx", "={rdx},{rax},{rdx},~{cc},~{memory},~{dirflag},~{fpsr},~{flags}"(i64 %request,i64 %p4)
 store i64 %p0,ptr %out,align 1
 %last = getelementptr i8,ptr %out,i64 56
 store i64 %p1,ptr %last,align 1
 %marker = getelementptr i8,ptr %out,i64 64
 store i64 %client,ptr %marker,align 1
 %m0 = mul i64 %client,1099511628211
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
define i64 @integer_undef_probe_74(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @integer_undef_body_74(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 72
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 80
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 88
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @integer_undef_body_75(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %header = alloca [6 x i64],align 8
 %h0 = getelementptr i8,ptr %header,i64 0
 store i64 %p0,ptr %h0,align 8
 %h1 = getelementptr i8,ptr %header,i64 8
 store i64 %p1,ptr %h1,align 8
 %h2 = getelementptr i8,ptr %header,i64 16
 store i64 %p2,ptr %h2,align 8
 %h3 = getelementptr i8,ptr %header,i64 24
 store i64 %p3,ptr %h3,align 8
 %h4 = getelementptr i8,ptr %header,i64 32
 store i64 %p4,ptr %h4,align 8
 %h5 = getelementptr i8,ptr %header,i64 40
 store i64 %p5,ptr %h5,align 8
 store i512 undef,ptr %out,align 1
 %request = ptrtoint ptr %header to i64
 %client = call i64 asm sideeffect " rolq  $$3,  %rdi ; rolq $$13, %rdi\0A rolq  $$61, %rdi ; rolq $$51, %rdi\0A xchgq %rbx, %rbx", "={rdx},{rax},{rdx},~{cc},~{memory},~{dirflag},~{fpsr},~{flags}"(i64 %request,i64 %p4)
 store i64 %p0,ptr %out,align 1
 %last = getelementptr i8,ptr %out,i64 56
 store i64 %p1,ptr %last,align 1
 %marker = getelementptr i8,ptr %out,i64 64
 store i64 %client,ptr %marker,align 1
 %m0 = mul i64 %client,1099511628211
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
define i64 @integer_undef_probe_75(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @integer_undef_body_75(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 72
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 80
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 88
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define i64 @integer_undef_body_76(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %header = alloca [6 x i64],align 8
 %h0 = getelementptr i8,ptr %header,i64 0
 store i64 %p0,ptr %h0,align 8
 %h1 = getelementptr i8,ptr %header,i64 8
 store i64 %p1,ptr %h1,align 8
 %h2 = getelementptr i8,ptr %header,i64 16
 store i64 %p2,ptr %h2,align 8
 %h3 = getelementptr i8,ptr %header,i64 24
 store i64 %p3,ptr %h3,align 8
 %h4 = getelementptr i8,ptr %header,i64 32
 store i64 %p4,ptr %h4,align 8
 %h5 = getelementptr i8,ptr %header,i64 40
 store i64 %p5,ptr %h5,align 8
 store i800 undef,ptr %out,align 1
 %request = ptrtoint ptr %header to i64
 %client = call i64 asm sideeffect " rolq  $$3,  %rdi ; rolq $$13, %rdi\0A rolq  $$61, %rdi ; rolq $$51, %rdi\0A xchgq %rbx, %rbx", "={rdx},{rax},{rdx},~{cc},~{memory},~{dirflag},~{fpsr},~{flags}"(i64 %request,i64 %p4)
 store i64 %p0,ptr %out,align 1
 %last = getelementptr i8,ptr %out,i64 92
 store i64 %p1,ptr %last,align 1
 %marker = getelementptr i8,ptr %out,i64 100
 store i64 %client,ptr %marker,align 1
 %m0 = mul i64 %client,1099511628211
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
define i64 @integer_undef_probe_76(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @integer_undef_body_76(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 108
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 116
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 124
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @integer_undef_body_77(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %header = alloca [6 x i64],align 8
 %h0 = getelementptr i8,ptr %header,i64 0
 store i64 %p0,ptr %h0,align 8
 %h1 = getelementptr i8,ptr %header,i64 8
 store i64 %p1,ptr %h1,align 8
 %h2 = getelementptr i8,ptr %header,i64 16
 store i64 %p2,ptr %h2,align 8
 %h3 = getelementptr i8,ptr %header,i64 24
 store i64 %p3,ptr %h3,align 8
 %h4 = getelementptr i8,ptr %header,i64 32
 store i64 %p4,ptr %h4,align 8
 %h5 = getelementptr i8,ptr %header,i64 40
 store i64 %p5,ptr %h5,align 8
 store i800 undef,ptr %out,align 1
 %request = ptrtoint ptr %header to i64
 %client = call i64 asm sideeffect " rolq  $$3,  %rdi ; rolq $$13, %rdi\0A rolq  $$61, %rdi ; rolq $$51, %rdi\0A xchgq %rbx, %rbx", "={rdx},{rax},{rdx},~{cc},~{memory},~{dirflag},~{fpsr},~{flags}"(i64 %request,i64 %p4)
 store i64 %p0,ptr %out,align 1
 %last = getelementptr i8,ptr %out,i64 92
 store i64 %p1,ptr %last,align 1
 %marker = getelementptr i8,ptr %out,i64 100
 store i64 %client,ptr %marker,align 1
 %m0 = mul i64 %client,1099511628211
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
define i64 @integer_undef_probe_77(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @integer_undef_body_77(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 108
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 116
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 124
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define i64 @integer_undef_body_78(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %header = alloca [6 x i64],align 8
 %h0 = getelementptr i8,ptr %header,i64 0
 store i64 %p0,ptr %h0,align 8
 %h1 = getelementptr i8,ptr %header,i64 8
 store i64 %p1,ptr %h1,align 8
 %h2 = getelementptr i8,ptr %header,i64 16
 store i64 %p2,ptr %h2,align 8
 %h3 = getelementptr i8,ptr %header,i64 24
 store i64 %p3,ptr %h3,align 8
 %h4 = getelementptr i8,ptr %header,i64 32
 store i64 %p4,ptr %h4,align 8
 %h5 = getelementptr i8,ptr %header,i64 40
 store i64 %p5,ptr %h5,align 8
 store i1024 undef,ptr %out,align 1
 %request = ptrtoint ptr %header to i64
 %client = call i64 asm sideeffect " rolq  $$3,  %rdi ; rolq $$13, %rdi\0A rolq  $$61, %rdi ; rolq $$51, %rdi\0A xchgq %rbx, %rbx", "={rdx},{rax},{rdx},~{cc},~{memory},~{dirflag},~{fpsr},~{flags}"(i64 %request,i64 %p4)
 store i64 %p0,ptr %out,align 1
 %last = getelementptr i8,ptr %out,i64 120
 store i64 %p1,ptr %last,align 1
 %marker = getelementptr i8,ptr %out,i64 128
 store i64 %client,ptr %marker,align 1
 %m0 = mul i64 %client,1099511628211
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
define i64 @integer_undef_probe_78(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @integer_undef_body_78(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 136
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 144
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 152
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @integer_undef_body_79(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %header = alloca [6 x i64],align 8
 %h0 = getelementptr i8,ptr %header,i64 0
 store i64 %p0,ptr %h0,align 8
 %h1 = getelementptr i8,ptr %header,i64 8
 store i64 %p1,ptr %h1,align 8
 %h2 = getelementptr i8,ptr %header,i64 16
 store i64 %p2,ptr %h2,align 8
 %h3 = getelementptr i8,ptr %header,i64 24
 store i64 %p3,ptr %h3,align 8
 %h4 = getelementptr i8,ptr %header,i64 32
 store i64 %p4,ptr %h4,align 8
 %h5 = getelementptr i8,ptr %header,i64 40
 store i64 %p5,ptr %h5,align 8
 store i1024 undef,ptr %out,align 1
 %request = ptrtoint ptr %header to i64
 %client = call i64 asm sideeffect " rolq  $$3,  %rdi ; rolq $$13, %rdi\0A rolq  $$61, %rdi ; rolq $$51, %rdi\0A xchgq %rbx, %rbx", "={rdx},{rax},{rdx},~{cc},~{memory},~{dirflag},~{fpsr},~{flags}"(i64 %request,i64 %p4)
 store i64 %p0,ptr %out,align 1
 %last = getelementptr i8,ptr %out,i64 120
 store i64 %p1,ptr %last,align 1
 %marker = getelementptr i8,ptr %out,i64 128
 store i64 %client,ptr %marker,align 1
 %m0 = mul i64 %client,1099511628211
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
define i64 @integer_undef_probe_79(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @integer_undef_body_79(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 136
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 144
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 152
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define i64 @integer_undef_body_80(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %header = alloca [6 x i64],align 8
 %h0 = getelementptr i8,ptr %header,i64 0
 store i64 %p0,ptr %h0,align 8
 %h1 = getelementptr i8,ptr %header,i64 8
 store i64 %p1,ptr %h1,align 8
 %h2 = getelementptr i8,ptr %header,i64 16
 store i64 %p2,ptr %h2,align 8
 %h3 = getelementptr i8,ptr %header,i64 24
 store i64 %p3,ptr %h3,align 8
 %h4 = getelementptr i8,ptr %header,i64 32
 store i64 %p4,ptr %h4,align 8
 %h5 = getelementptr i8,ptr %header,i64 40
 store i64 %p5,ptr %h5,align 8
 store i64000 undef,ptr %out,align 1
 %request = ptrtoint ptr %header to i64
 %client = call i64 asm sideeffect " rolq  $$3,  %rdi ; rolq $$13, %rdi\0A rolq  $$61, %rdi ; rolq $$51, %rdi\0A xchgq %rbx, %rbx", "={rdx},{rax},{rdx},~{cc},~{memory},~{dirflag},~{fpsr},~{flags}"(i64 %request,i64 %p4)
 store i64 %p0,ptr %out,align 1
 %last = getelementptr i8,ptr %out,i64 7992
 store i64 %p1,ptr %last,align 1
 %marker = getelementptr i8,ptr %out,i64 8000
 store i64 %client,ptr %marker,align 1
 %m0 = mul i64 %client,1099511628211
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
define i64 @integer_undef_probe_80(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @integer_undef_body_80(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 8008
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8016
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 8024
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @integer_undef_body_81(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %header = alloca [6 x i64],align 8
 %h0 = getelementptr i8,ptr %header,i64 0
 store i64 %p0,ptr %h0,align 8
 %h1 = getelementptr i8,ptr %header,i64 8
 store i64 %p1,ptr %h1,align 8
 %h2 = getelementptr i8,ptr %header,i64 16
 store i64 %p2,ptr %h2,align 8
 %h3 = getelementptr i8,ptr %header,i64 24
 store i64 %p3,ptr %h3,align 8
 %h4 = getelementptr i8,ptr %header,i64 32
 store i64 %p4,ptr %h4,align 8
 %h5 = getelementptr i8,ptr %header,i64 40
 store i64 %p5,ptr %h5,align 8
 store i64000 undef,ptr %out,align 1
 %request = ptrtoint ptr %header to i64
 %client = call i64 asm sideeffect " rolq  $$3,  %rdi ; rolq $$13, %rdi\0A rolq  $$61, %rdi ; rolq $$51, %rdi\0A xchgq %rbx, %rbx", "={rdx},{rax},{rdx},~{cc},~{memory},~{dirflag},~{fpsr},~{flags}"(i64 %request,i64 %p4)
 store i64 %p0,ptr %out,align 1
 %last = getelementptr i8,ptr %out,i64 7992
 store i64 %p1,ptr %last,align 1
 %marker = getelementptr i8,ptr %out,i64 8000
 store i64 %client,ptr %marker,align 1
 %m0 = mul i64 %client,1099511628211
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
define i64 @integer_undef_probe_81(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @integer_undef_body_81(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 8008
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8016
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 8024
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
