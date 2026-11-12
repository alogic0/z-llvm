target triple = "x86_64-unknown-linux-gnu"
define i64 @sign_extension_body_0(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5) noinline {
entry:
 %narrow = trunc i64 %a0 to i32
 %wide = sext i32 %narrow to i64
 %mix0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %mix0,%a0
 %mix1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %mix1,%a1
 %mix2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %mix2,%a2
 %mix3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %mix3,%a3
 %mix4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %mix4,%a4
 %mix5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %mix5,%a5
 ret i64 %r5
}
declare i64 @sign_extension_provider_0(i64,i64,i64,i64,i64,i64)
define i64 @sign_extension_probe_0(ptr %out,ptr %input,i64 %salt) {
entry:
 %p0 = getelementptr i8,ptr %input,i64 0
 %a0 = load i64,ptr %p0,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %a1 = load i64,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %input,i64 16
 %a2 = load i64,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %input,i64 24
 %a3 = load i64,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %input,i64 32
 %a4 = load i64,ptr %p4,align 1
 %p5 = getelementptr i8,ptr %input,i64 40
 %a5 = load i64,ptr %p5,align 1
 %local = call i64 @sign_extension_body_0(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5)
 %external = call i64 @sign_extension_provider_0(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5)
 store i64 %local,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %external,ptr %next,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define i64 @sign_extension_body_1(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5) noinline {
entry:
 %narrow = trunc i64 %a1 to i32
 %wide = sext i32 %narrow to i64
 %mix0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %mix0,%a0
 %mix1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %mix1,%a1
 %mix2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %mix2,%a2
 %mix3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %mix3,%a3
 %mix4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %mix4,%a4
 %mix5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %mix5,%a5
 ret i64 %r5
}
declare i64 @sign_extension_provider_1(i64,i64,i64,i64,i64,i64)
define i64 @sign_extension_probe_1(ptr %out,ptr %input,i64 %salt) {
entry:
 %p0 = getelementptr i8,ptr %input,i64 0
 %a0 = load i64,ptr %p0,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %a1 = load i64,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %input,i64 16
 %a2 = load i64,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %input,i64 24
 %a3 = load i64,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %input,i64 32
 %a4 = load i64,ptr %p4,align 1
 %p5 = getelementptr i8,ptr %input,i64 40
 %a5 = load i64,ptr %p5,align 1
 %local = call i64 @sign_extension_body_1(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5)
 %external = call i64 @sign_extension_provider_1(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5)
 store i64 %local,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %external,ptr %next,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define i64 @sign_extension_body_2(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5) noinline {
entry:
 %narrow = trunc i64 %a2 to i32
 %wide = sext i32 %narrow to i64
 %mix0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %mix0,%a0
 %mix1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %mix1,%a1
 %mix2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %mix2,%a2
 %mix3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %mix3,%a3
 %mix4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %mix4,%a4
 %mix5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %mix5,%a5
 ret i64 %r5
}
declare i64 @sign_extension_provider_2(i64,i64,i64,i64,i64,i64)
define i64 @sign_extension_probe_2(ptr %out,ptr %input,i64 %salt) {
entry:
 %p0 = getelementptr i8,ptr %input,i64 0
 %a0 = load i64,ptr %p0,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %a1 = load i64,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %input,i64 16
 %a2 = load i64,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %input,i64 24
 %a3 = load i64,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %input,i64 32
 %a4 = load i64,ptr %p4,align 1
 %p5 = getelementptr i8,ptr %input,i64 40
 %a5 = load i64,ptr %p5,align 1
 %local = call i64 @sign_extension_body_2(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5)
 %external = call i64 @sign_extension_provider_2(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5)
 store i64 %local,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %external,ptr %next,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define i64 @sign_extension_body_3(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5) noinline {
entry:
 %narrow = trunc i64 %a3 to i32
 %wide = sext i32 %narrow to i64
 %mix0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %mix0,%a0
 %mix1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %mix1,%a1
 %mix2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %mix2,%a2
 %mix3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %mix3,%a3
 %mix4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %mix4,%a4
 %mix5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %mix5,%a5
 ret i64 %r5
}
declare i64 @sign_extension_provider_3(i64,i64,i64,i64,i64,i64)
define i64 @sign_extension_probe_3(ptr %out,ptr %input,i64 %salt) {
entry:
 %p0 = getelementptr i8,ptr %input,i64 0
 %a0 = load i64,ptr %p0,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %a1 = load i64,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %input,i64 16
 %a2 = load i64,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %input,i64 24
 %a3 = load i64,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %input,i64 32
 %a4 = load i64,ptr %p4,align 1
 %p5 = getelementptr i8,ptr %input,i64 40
 %a5 = load i64,ptr %p5,align 1
 %local = call i64 @sign_extension_body_3(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5)
 %external = call i64 @sign_extension_provider_3(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5)
 store i64 %local,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %external,ptr %next,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define i64 @sign_extension_body_4(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5) noinline {
entry:
 %narrow = trunc i64 %a4 to i32
 %wide = sext i32 %narrow to i64
 %mix0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %mix0,%a0
 %mix1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %mix1,%a1
 %mix2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %mix2,%a2
 %mix3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %mix3,%a3
 %mix4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %mix4,%a4
 %mix5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %mix5,%a5
 ret i64 %r5
}
declare i64 @sign_extension_provider_4(i64,i64,i64,i64,i64,i64)
define i64 @sign_extension_probe_4(ptr %out,ptr %input,i64 %salt) {
entry:
 %p0 = getelementptr i8,ptr %input,i64 0
 %a0 = load i64,ptr %p0,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %a1 = load i64,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %input,i64 16
 %a2 = load i64,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %input,i64 24
 %a3 = load i64,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %input,i64 32
 %a4 = load i64,ptr %p4,align 1
 %p5 = getelementptr i8,ptr %input,i64 40
 %a5 = load i64,ptr %p5,align 1
 %local = call i64 @sign_extension_body_4(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5)
 %external = call i64 @sign_extension_provider_4(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5)
 store i64 %local,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %external,ptr %next,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define i64 @sign_extension_body_5(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5) noinline {
entry:
 %narrow = trunc i64 %a5 to i32
 %wide = sext i32 %narrow to i64
 %mix0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %mix0,%a0
 %mix1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %mix1,%a1
 %mix2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %mix2,%a2
 %mix3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %mix3,%a3
 %mix4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %mix4,%a4
 %mix5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %mix5,%a5
 ret i64 %r5
}
declare i64 @sign_extension_provider_5(i64,i64,i64,i64,i64,i64)
define i64 @sign_extension_probe_5(ptr %out,ptr %input,i64 %salt) {
entry:
 %p0 = getelementptr i8,ptr %input,i64 0
 %a0 = load i64,ptr %p0,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %a1 = load i64,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %input,i64 16
 %a2 = load i64,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %input,i64 24
 %a3 = load i64,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %input,i64 32
 %a4 = load i64,ptr %p4,align 1
 %p5 = getelementptr i8,ptr %input,i64 40
 %a5 = load i64,ptr %p5,align 1
 %local = call i64 @sign_extension_body_5(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5)
 %external = call i64 @sign_extension_provider_5(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5)
 store i64 %local,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %external,ptr %next,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define i64 @sign_extension_body_6(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5) noinline {
entry:
 %narrow = trunc i64 %a0 to i32
 %wide = sext i32 %narrow to i64
 %condition = icmp eq i64 %a0,0
 br i1 %condition,label %left,label %right
left:
 br label %join
right:
 br label %join
join:
 %carried = phi i64 [%wide,%left],[%wide,%right]
 %mix0 = mul i64 %carried,1099511628211
 %r0 = xor i64 %mix0,%a0
 %mix1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %mix1,%a1
 %mix2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %mix2,%a2
 %mix3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %mix3,%a3
 %mix4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %mix4,%a4
 %mix5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %mix5,%a5
 ret i64 %r5
}
declare i64 @sign_extension_provider_6(i64,i64,i64,i64,i64,i64)
define i64 @sign_extension_probe_6(ptr %out,ptr %input,i64 %salt) {
entry:
 %p0 = getelementptr i8,ptr %input,i64 0
 %a0 = load i64,ptr %p0,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %a1 = load i64,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %input,i64 16
 %a2 = load i64,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %input,i64 24
 %a3 = load i64,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %input,i64 32
 %a4 = load i64,ptr %p4,align 1
 %p5 = getelementptr i8,ptr %input,i64 40
 %a5 = load i64,ptr %p5,align 1
 %local = call i64 @sign_extension_body_6(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5)
 %external = call i64 @sign_extension_provider_6(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5)
 store i64 %local,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %external,ptr %next,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define i64 @sign_extension_body_7(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5) noinline {
entry:
 %narrow = trunc i64 %a1 to i32
 %wide = sext i32 %narrow to i64
 %condition = icmp eq i64 %a0,0
 br i1 %condition,label %left,label %right
left:
 br label %join
right:
 br label %join
join:
 %carried = phi i64 [%wide,%left],[%wide,%right]
 %mix0 = mul i64 %carried,1099511628211
 %r0 = xor i64 %mix0,%a0
 %mix1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %mix1,%a1
 %mix2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %mix2,%a2
 %mix3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %mix3,%a3
 %mix4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %mix4,%a4
 %mix5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %mix5,%a5
 ret i64 %r5
}
declare i64 @sign_extension_provider_7(i64,i64,i64,i64,i64,i64)
define i64 @sign_extension_probe_7(ptr %out,ptr %input,i64 %salt) {
entry:
 %p0 = getelementptr i8,ptr %input,i64 0
 %a0 = load i64,ptr %p0,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %a1 = load i64,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %input,i64 16
 %a2 = load i64,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %input,i64 24
 %a3 = load i64,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %input,i64 32
 %a4 = load i64,ptr %p4,align 1
 %p5 = getelementptr i8,ptr %input,i64 40
 %a5 = load i64,ptr %p5,align 1
 %local = call i64 @sign_extension_body_7(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5)
 %external = call i64 @sign_extension_provider_7(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5)
 store i64 %local,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %external,ptr %next,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define i64 @sign_extension_body_8(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5) noinline {
entry:
 %narrow = trunc i64 %a2 to i32
 %wide = sext i32 %narrow to i64
 %condition = icmp eq i64 %a0,0
 br i1 %condition,label %left,label %right
left:
 br label %join
right:
 br label %join
join:
 %carried = phi i64 [%wide,%left],[%wide,%right]
 %mix0 = mul i64 %carried,1099511628211
 %r0 = xor i64 %mix0,%a0
 %mix1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %mix1,%a1
 %mix2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %mix2,%a2
 %mix3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %mix3,%a3
 %mix4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %mix4,%a4
 %mix5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %mix5,%a5
 ret i64 %r5
}
declare i64 @sign_extension_provider_8(i64,i64,i64,i64,i64,i64)
define i64 @sign_extension_probe_8(ptr %out,ptr %input,i64 %salt) {
entry:
 %p0 = getelementptr i8,ptr %input,i64 0
 %a0 = load i64,ptr %p0,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %a1 = load i64,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %input,i64 16
 %a2 = load i64,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %input,i64 24
 %a3 = load i64,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %input,i64 32
 %a4 = load i64,ptr %p4,align 1
 %p5 = getelementptr i8,ptr %input,i64 40
 %a5 = load i64,ptr %p5,align 1
 %local = call i64 @sign_extension_body_8(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5)
 %external = call i64 @sign_extension_provider_8(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5)
 store i64 %local,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %external,ptr %next,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define i64 @sign_extension_body_9(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5) noinline {
entry:
 %narrow = trunc i64 %a3 to i32
 %wide = sext i32 %narrow to i64
 %condition = icmp eq i64 %a0,0
 br i1 %condition,label %left,label %right
left:
 br label %join
right:
 br label %join
join:
 %carried = phi i64 [%wide,%left],[%wide,%right]
 %mix0 = mul i64 %carried,1099511628211
 %r0 = xor i64 %mix0,%a0
 %mix1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %mix1,%a1
 %mix2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %mix2,%a2
 %mix3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %mix3,%a3
 %mix4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %mix4,%a4
 %mix5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %mix5,%a5
 ret i64 %r5
}
declare i64 @sign_extension_provider_9(i64,i64,i64,i64,i64,i64)
define i64 @sign_extension_probe_9(ptr %out,ptr %input,i64 %salt) {
entry:
 %p0 = getelementptr i8,ptr %input,i64 0
 %a0 = load i64,ptr %p0,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %a1 = load i64,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %input,i64 16
 %a2 = load i64,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %input,i64 24
 %a3 = load i64,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %input,i64 32
 %a4 = load i64,ptr %p4,align 1
 %p5 = getelementptr i8,ptr %input,i64 40
 %a5 = load i64,ptr %p5,align 1
 %local = call i64 @sign_extension_body_9(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5)
 %external = call i64 @sign_extension_provider_9(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5)
 store i64 %local,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %external,ptr %next,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define i64 @sign_extension_body_10(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5) noinline {
entry:
 %narrow = trunc i64 %a4 to i32
 %wide = sext i32 %narrow to i64
 %condition = icmp eq i64 %a0,0
 br i1 %condition,label %left,label %right
left:
 br label %join
right:
 br label %join
join:
 %carried = phi i64 [%wide,%left],[%wide,%right]
 %mix0 = mul i64 %carried,1099511628211
 %r0 = xor i64 %mix0,%a0
 %mix1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %mix1,%a1
 %mix2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %mix2,%a2
 %mix3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %mix3,%a3
 %mix4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %mix4,%a4
 %mix5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %mix5,%a5
 ret i64 %r5
}
declare i64 @sign_extension_provider_10(i64,i64,i64,i64,i64,i64)
define i64 @sign_extension_probe_10(ptr %out,ptr %input,i64 %salt) {
entry:
 %p0 = getelementptr i8,ptr %input,i64 0
 %a0 = load i64,ptr %p0,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %a1 = load i64,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %input,i64 16
 %a2 = load i64,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %input,i64 24
 %a3 = load i64,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %input,i64 32
 %a4 = load i64,ptr %p4,align 1
 %p5 = getelementptr i8,ptr %input,i64 40
 %a5 = load i64,ptr %p5,align 1
 %local = call i64 @sign_extension_body_10(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5)
 %external = call i64 @sign_extension_provider_10(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5)
 store i64 %local,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %external,ptr %next,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define i64 @sign_extension_body_11(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5) noinline {
entry:
 %narrow = trunc i64 %a5 to i32
 %wide = sext i32 %narrow to i64
 %condition = icmp eq i64 %a0,0
 br i1 %condition,label %left,label %right
left:
 br label %join
right:
 br label %join
join:
 %carried = phi i64 [%wide,%left],[%wide,%right]
 %mix0 = mul i64 %carried,1099511628211
 %r0 = xor i64 %mix0,%a0
 %mix1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %mix1,%a1
 %mix2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %mix2,%a2
 %mix3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %mix3,%a3
 %mix4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %mix4,%a4
 %mix5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %mix5,%a5
 ret i64 %r5
}
declare i64 @sign_extension_provider_11(i64,i64,i64,i64,i64,i64)
define i64 @sign_extension_probe_11(ptr %out,ptr %input,i64 %salt) {
entry:
 %p0 = getelementptr i8,ptr %input,i64 0
 %a0 = load i64,ptr %p0,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %a1 = load i64,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %input,i64 16
 %a2 = load i64,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %input,i64 24
 %a3 = load i64,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %input,i64 32
 %a4 = load i64,ptr %p4,align 1
 %p5 = getelementptr i8,ptr %input,i64 40
 %a5 = load i64,ptr %p5,align 1
 %local = call i64 @sign_extension_body_11(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5)
 %external = call i64 @sign_extension_provider_11(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5)
 store i64 %local,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %external,ptr %next,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
