target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"
define i64 @memory_limbs_body_0(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i800,ptr %input,align 1
 %value = freeze i800 %x
 store i800 %value,ptr %out,align 1
 %low = trunc i800 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 100
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 108
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 116
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_0(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 160
 %answer = call i64 @memory_limbs_body_0(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define i64 @memory_limbs_body_1(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i800,ptr %input,align 1
 %yp = getelementptr i800,ptr %input,i64 1
 %y = load i800,ptr %yp,align 1
 %condition = icmp eq i800 %x,%y
 %selected = select i1 %condition,i800 %x,i800 %y
 %slot = alloca i800,align 16
 store i800 %selected,ptr %slot,align 16
 %slot0 = getelementptr i800,ptr %slot,i64 0
 %roundtrip = load i800,ptr %slot0,align 16
 store i800 %roundtrip,ptr %out,align 1
 br i1 %condition,label %left,label %right
left:
 br label %join
right:
 br label %join
join:
 %chosen = phi i800 [%y,%left],[%x,%right]
 %defined = freeze i800 %chosen
 %other = getelementptr i8,ptr %out,i64 100
 store i800 %defined,ptr %other,align 1
 %first = trunc i800 %roundtrip to i64
 %second = trunc i800 %defined to i64
 %mix = xor i64 %first,%second
 %flag = zext i1 %condition to i64
 %initial = xor i64 %mix,%flag
 %m0 = mul i64 %initial,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 200
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 208
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 216
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_1(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 48
 %answer = call i64 @memory_limbs_body_1(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define i64 @memory_limbs_body_2(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i800,ptr %input,align 1
 %yp = getelementptr i800,ptr %input,i64 1
 %y = load i800,ptr %yp,align 1
 %condition = icmp ne i800 %x,%y
 %selected = select i1 %condition,i800 %x,i800 %y
 %slot = alloca i800,align 16
 store i800 %selected,ptr %slot,align 16
 %slot0 = getelementptr i800,ptr %slot,i64 0
 %roundtrip = load i800,ptr %slot0,align 16
 store i800 %roundtrip,ptr %out,align 1
 br i1 %condition,label %left,label %right
left:
 br label %join
right:
 br label %join
join:
 %chosen = phi i800 [%y,%left],[%x,%right]
 %defined = freeze i800 %chosen
 %other = getelementptr i8,ptr %out,i64 100
 store i800 %defined,ptr %other,align 1
 %first = trunc i800 %roundtrip to i64
 %second = trunc i800 %defined to i64
 %mix = xor i64 %first,%second
 %flag = zext i1 %condition to i64
 %initial = xor i64 %mix,%flag
 %m0 = mul i64 %initial,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 200
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 208
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 216
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_2(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 48
 %answer = call i64 @memory_limbs_body_2(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define i64 @memory_limbs_body_3(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i800,ptr %input,align 1
 %yp = getelementptr i800,ptr %input,i64 1
 %y = load i800,ptr %yp,align 1
 %condition = icmp ult i800 %x,%y
 %selected = select i1 %condition,i800 %x,i800 %y
 %slot = alloca i800,align 16
 store i800 %selected,ptr %slot,align 16
 %slot0 = getelementptr i800,ptr %slot,i64 0
 %roundtrip = load i800,ptr %slot0,align 16
 store i800 %roundtrip,ptr %out,align 1
 br i1 %condition,label %left,label %right
left:
 br label %join
right:
 br label %join
join:
 %chosen = phi i800 [%y,%left],[%x,%right]
 %defined = freeze i800 %chosen
 %other = getelementptr i8,ptr %out,i64 100
 store i800 %defined,ptr %other,align 1
 %first = trunc i800 %roundtrip to i64
 %second = trunc i800 %defined to i64
 %mix = xor i64 %first,%second
 %flag = zext i1 %condition to i64
 %initial = xor i64 %mix,%flag
 %m0 = mul i64 %initial,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 200
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 208
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 216
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_3(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 48
 %answer = call i64 @memory_limbs_body_3(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define i64 @memory_limbs_body_4(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i800,ptr %input,align 1
 %yp = getelementptr i800,ptr %input,i64 1
 %y = load i800,ptr %yp,align 1
 %condition = icmp ule i800 %x,%y
 %selected = select i1 %condition,i800 %x,i800 %y
 %slot = alloca i800,align 16
 store i800 %selected,ptr %slot,align 16
 %slot0 = getelementptr i800,ptr %slot,i64 0
 %roundtrip = load i800,ptr %slot0,align 16
 store i800 %roundtrip,ptr %out,align 1
 br i1 %condition,label %left,label %right
left:
 br label %join
right:
 br label %join
join:
 %chosen = phi i800 [%y,%left],[%x,%right]
 %defined = freeze i800 %chosen
 %other = getelementptr i8,ptr %out,i64 100
 store i800 %defined,ptr %other,align 1
 %first = trunc i800 %roundtrip to i64
 %second = trunc i800 %defined to i64
 %mix = xor i64 %first,%second
 %flag = zext i1 %condition to i64
 %initial = xor i64 %mix,%flag
 %m0 = mul i64 %initial,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 200
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 208
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 216
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_4(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 48
 %answer = call i64 @memory_limbs_body_4(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define i64 @memory_limbs_body_5(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i800,ptr %input,align 1
 %yp = getelementptr i800,ptr %input,i64 1
 %y = load i800,ptr %yp,align 1
 %condition = icmp ugt i800 %x,%y
 %selected = select i1 %condition,i800 %x,i800 %y
 %slot = alloca i800,align 16
 store i800 %selected,ptr %slot,align 16
 %slot0 = getelementptr i800,ptr %slot,i64 0
 %roundtrip = load i800,ptr %slot0,align 16
 store i800 %roundtrip,ptr %out,align 1
 br i1 %condition,label %left,label %right
left:
 br label %join
right:
 br label %join
join:
 %chosen = phi i800 [%y,%left],[%x,%right]
 %defined = freeze i800 %chosen
 %other = getelementptr i8,ptr %out,i64 100
 store i800 %defined,ptr %other,align 1
 %first = trunc i800 %roundtrip to i64
 %second = trunc i800 %defined to i64
 %mix = xor i64 %first,%second
 %flag = zext i1 %condition to i64
 %initial = xor i64 %mix,%flag
 %m0 = mul i64 %initial,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 200
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 208
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 216
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_5(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 48
 %answer = call i64 @memory_limbs_body_5(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define i64 @memory_limbs_body_6(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i800,ptr %input,align 1
 %yp = getelementptr i800,ptr %input,i64 1
 %y = load i800,ptr %yp,align 1
 %condition = icmp uge i800 %x,%y
 %selected = select i1 %condition,i800 %x,i800 %y
 %slot = alloca i800,align 16
 store i800 %selected,ptr %slot,align 16
 %slot0 = getelementptr i800,ptr %slot,i64 0
 %roundtrip = load i800,ptr %slot0,align 16
 store i800 %roundtrip,ptr %out,align 1
 br i1 %condition,label %left,label %right
left:
 br label %join
right:
 br label %join
join:
 %chosen = phi i800 [%y,%left],[%x,%right]
 %defined = freeze i800 %chosen
 %other = getelementptr i8,ptr %out,i64 100
 store i800 %defined,ptr %other,align 1
 %first = trunc i800 %roundtrip to i64
 %second = trunc i800 %defined to i64
 %mix = xor i64 %first,%second
 %flag = zext i1 %condition to i64
 %initial = xor i64 %mix,%flag
 %m0 = mul i64 %initial,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 200
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 208
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 216
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_6(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 48
 %answer = call i64 @memory_limbs_body_6(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define i64 @memory_limbs_body_7(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i800,ptr %input,align 1
 %yp = getelementptr i800,ptr %input,i64 1
 %y = load i800,ptr %yp,align 1
 %condition = icmp slt i800 %x,%y
 %selected = select i1 %condition,i800 %x,i800 %y
 %slot = alloca i800,align 16
 store i800 %selected,ptr %slot,align 16
 %slot0 = getelementptr i800,ptr %slot,i64 0
 %roundtrip = load i800,ptr %slot0,align 16
 store i800 %roundtrip,ptr %out,align 1
 br i1 %condition,label %left,label %right
left:
 br label %join
right:
 br label %join
join:
 %chosen = phi i800 [%y,%left],[%x,%right]
 %defined = freeze i800 %chosen
 %other = getelementptr i8,ptr %out,i64 100
 store i800 %defined,ptr %other,align 1
 %first = trunc i800 %roundtrip to i64
 %second = trunc i800 %defined to i64
 %mix = xor i64 %first,%second
 %flag = zext i1 %condition to i64
 %initial = xor i64 %mix,%flag
 %m0 = mul i64 %initial,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 200
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 208
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 216
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_7(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 48
 %answer = call i64 @memory_limbs_body_7(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define i64 @memory_limbs_body_8(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i800,ptr %input,align 1
 %yp = getelementptr i800,ptr %input,i64 1
 %y = load i800,ptr %yp,align 1
 %condition = icmp sle i800 %x,%y
 %selected = select i1 %condition,i800 %x,i800 %y
 %slot = alloca i800,align 16
 store i800 %selected,ptr %slot,align 16
 %slot0 = getelementptr i800,ptr %slot,i64 0
 %roundtrip = load i800,ptr %slot0,align 16
 store i800 %roundtrip,ptr %out,align 1
 br i1 %condition,label %left,label %right
left:
 br label %join
right:
 br label %join
join:
 %chosen = phi i800 [%y,%left],[%x,%right]
 %defined = freeze i800 %chosen
 %other = getelementptr i8,ptr %out,i64 100
 store i800 %defined,ptr %other,align 1
 %first = trunc i800 %roundtrip to i64
 %second = trunc i800 %defined to i64
 %mix = xor i64 %first,%second
 %flag = zext i1 %condition to i64
 %initial = xor i64 %mix,%flag
 %m0 = mul i64 %initial,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 200
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 208
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 216
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_8(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 48
 %answer = call i64 @memory_limbs_body_8(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define i64 @memory_limbs_body_9(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i800,ptr %input,align 1
 %yp = getelementptr i800,ptr %input,i64 1
 %y = load i800,ptr %yp,align 1
 %condition = icmp sgt i800 %x,%y
 %selected = select i1 %condition,i800 %x,i800 %y
 %slot = alloca i800,align 16
 store i800 %selected,ptr %slot,align 16
 %slot0 = getelementptr i800,ptr %slot,i64 0
 %roundtrip = load i800,ptr %slot0,align 16
 store i800 %roundtrip,ptr %out,align 1
 br i1 %condition,label %left,label %right
left:
 br label %join
right:
 br label %join
join:
 %chosen = phi i800 [%y,%left],[%x,%right]
 %defined = freeze i800 %chosen
 %other = getelementptr i8,ptr %out,i64 100
 store i800 %defined,ptr %other,align 1
 %first = trunc i800 %roundtrip to i64
 %second = trunc i800 %defined to i64
 %mix = xor i64 %first,%second
 %flag = zext i1 %condition to i64
 %initial = xor i64 %mix,%flag
 %m0 = mul i64 %initial,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 200
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 208
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 216
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_9(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 48
 %answer = call i64 @memory_limbs_body_9(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define i64 @memory_limbs_body_10(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i800,ptr %input,align 1
 %yp = getelementptr i800,ptr %input,i64 1
 %y = load i800,ptr %yp,align 1
 %condition = icmp sge i800 %x,%y
 %selected = select i1 %condition,i800 %x,i800 %y
 %slot = alloca i800,align 16
 store i800 %selected,ptr %slot,align 16
 %slot0 = getelementptr i800,ptr %slot,i64 0
 %roundtrip = load i800,ptr %slot0,align 16
 store i800 %roundtrip,ptr %out,align 1
 br i1 %condition,label %left,label %right
left:
 br label %join
right:
 br label %join
join:
 %chosen = phi i800 [%y,%left],[%x,%right]
 %defined = freeze i800 %chosen
 %other = getelementptr i8,ptr %out,i64 100
 store i800 %defined,ptr %other,align 1
 %first = trunc i800 %roundtrip to i64
 %second = trunc i800 %defined to i64
 %mix = xor i64 %first,%second
 %flag = zext i1 %condition to i64
 %initial = xor i64 %mix,%flag
 %m0 = mul i64 %initial,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 200
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 208
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 216
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_10(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 48
 %answer = call i64 @memory_limbs_body_10(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define i64 @memory_limbs_body_11(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 store i800 0,ptr %out,align 1
 %value = load i800,ptr %out,align 1
 store i800 %value,ptr %out,align 1
 %low = trunc i800 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 100
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 108
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 116
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_11(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 160
 %answer = call i64 @memory_limbs_body_11(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define i64 @memory_limbs_body_12(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 store i800 -1,ptr %out,align 1
 %value = load i800,ptr %out,align 1
 store i800 %value,ptr %out,align 1
 %low = trunc i800 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 100
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 108
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 116
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_12(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 160
 %answer = call i64 @memory_limbs_body_12(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define i64 @memory_limbs_body_13(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 store i800 -3334007216439927137039925895360628898572379161157954080198128905882018618908816035760716100435777145371464955296716620222944400827059682540181678026165415023047578789757007279231539142955907012364482508067943300990845374018738230645581938688,ptr %out,align 1
 %value = load i800,ptr %out,align 1
 store i800 %value,ptr %out,align 1
 %low = trunc i800 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 100
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 108
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 116
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_13(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 160
 %answer = call i64 @memory_limbs_body_13(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define i64 @memory_limbs_body_14(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 store i800 3334007216439927137039925895360628898572379161157954080198128905882018618908816035760716100435777145371464955296716620222944400827059682540181678026165415023047578789757007279231539142955907012364482508067943300990845374018738230645581938687,ptr %out,align 1
 %value = load i800,ptr %out,align 1
 store i800 %value,ptr %out,align 1
 %low = trunc i800 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 100
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 108
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 116
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_14(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 160
 %answer = call i64 @memory_limbs_body_14(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define i64 @memory_limbs_body_15(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i800,ptr %input,align 1
 %value = trunc i800 %x to i8
 store i8 %value,ptr %out,align 1
 %low = zext i8 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 1
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 9
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 17
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_15(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 160
 %answer = call i64 @memory_limbs_body_15(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define i64 @memory_limbs_body_16(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i8,ptr %input,align 1
 %value = zext i8 %x to i800
 store i800 %value,ptr %out,align 1
 %low = trunc i800 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 100
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 108
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 116
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_16(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 64
 %answer = call i64 @memory_limbs_body_16(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define i64 @memory_limbs_body_17(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i8,ptr %input,align 1
 %value = sext i8 %x to i800
 store i800 %value,ptr %out,align 1
 %low = trunc i800 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 100
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 108
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 116
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_17(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 64
 %answer = call i64 @memory_limbs_body_17(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define i64 @memory_limbs_body_18(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i800,ptr %input,align 1
 %value = trunc i800 %x to i16
 store i16 %value,ptr %out,align 1
 %low = zext i16 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 2
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 10
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 18
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_18(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 160
 %answer = call i64 @memory_limbs_body_18(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define i64 @memory_limbs_body_19(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i16,ptr %input,align 1
 %value = zext i16 %x to i800
 store i800 %value,ptr %out,align 1
 %low = trunc i800 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 100
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 108
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 116
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_19(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 64
 %answer = call i64 @memory_limbs_body_19(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define i64 @memory_limbs_body_20(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i16,ptr %input,align 1
 %value = sext i16 %x to i800
 store i800 %value,ptr %out,align 1
 %low = trunc i800 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 100
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 108
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 116
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_20(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 64
 %answer = call i64 @memory_limbs_body_20(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define i64 @memory_limbs_body_21(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i800,ptr %input,align 1
 %value = trunc i800 %x to i32
 store i32 %value,ptr %out,align 1
 %low = zext i32 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 4
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 12
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 20
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_21(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 160
 %answer = call i64 @memory_limbs_body_21(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define i64 @memory_limbs_body_22(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i32,ptr %input,align 1
 %value = zext i32 %x to i800
 store i800 %value,ptr %out,align 1
 %low = trunc i800 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 100
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 108
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 116
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_22(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 64
 %answer = call i64 @memory_limbs_body_22(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define i64 @memory_limbs_body_23(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i32,ptr %input,align 1
 %value = sext i32 %x to i800
 store i800 %value,ptr %out,align 1
 %low = trunc i800 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 100
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 108
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 116
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_23(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 64
 %answer = call i64 @memory_limbs_body_23(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define i64 @memory_limbs_body_24(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i800,ptr %input,align 1
 %value = trunc i800 %x to i64
 store i64 %value,ptr %out,align 1
 %m0 = mul i64 %value,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 8
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 16
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 24
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_24(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 160
 %answer = call i64 @memory_limbs_body_24(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define i64 @memory_limbs_body_25(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i64,ptr %input,align 1
 %value = zext i64 %x to i800
 store i800 %value,ptr %out,align 1
 %low = trunc i800 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 100
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 108
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 116
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_25(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 64
 %answer = call i64 @memory_limbs_body_25(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define i64 @memory_limbs_body_26(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i64,ptr %input,align 1
 %value = sext i64 %x to i800
 store i800 %value,ptr %out,align 1
 %low = trunc i800 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 100
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 108
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 116
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_26(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 64
 %answer = call i64 @memory_limbs_body_26(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define i64 @memory_limbs_body_27(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i800,ptr %input,align 1
 %value = trunc i800 %x to i128
 store i128 %value,ptr %out,align 1
 %low = trunc i128 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 16
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 24
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 32
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_27(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 160
 %answer = call i64 @memory_limbs_body_27(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define i64 @memory_limbs_body_28(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i128,ptr %input,align 1
 %value = zext i128 %x to i800
 store i800 %value,ptr %out,align 1
 %low = trunc i800 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 100
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 108
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 116
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_28(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 64
 %answer = call i64 @memory_limbs_body_28(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define i64 @memory_limbs_body_29(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i128,ptr %input,align 1
 %value = sext i128 %x to i800
 store i800 %value,ptr %out,align 1
 %low = trunc i800 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 100
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 108
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 116
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_29(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 64
 %answer = call i64 @memory_limbs_body_29(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define fastcc i64 @memory_limbs_body_30(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i800,ptr %input,align 1
 %value = freeze i800 %x
 store i800 %value,ptr %out,align 1
 %low = trunc i800 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 100
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 108
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 116
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_30(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 160
 %answer = call fastcc i64 @memory_limbs_body_30(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define fastcc i64 @memory_limbs_body_31(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i800,ptr %input,align 1
 %yp = getelementptr i800,ptr %input,i64 1
 %y = load i800,ptr %yp,align 1
 %condition = icmp eq i800 %x,%y
 %selected = select i1 %condition,i800 %x,i800 %y
 %slot = alloca i800,align 16
 store i800 %selected,ptr %slot,align 16
 %slot0 = getelementptr i800,ptr %slot,i64 0
 %roundtrip = load i800,ptr %slot0,align 16
 store i800 %roundtrip,ptr %out,align 1
 br i1 %condition,label %left,label %right
left:
 br label %join
right:
 br label %join
join:
 %chosen = phi i800 [%y,%left],[%x,%right]
 %defined = freeze i800 %chosen
 %other = getelementptr i8,ptr %out,i64 100
 store i800 %defined,ptr %other,align 1
 %first = trunc i800 %roundtrip to i64
 %second = trunc i800 %defined to i64
 %mix = xor i64 %first,%second
 %flag = zext i1 %condition to i64
 %initial = xor i64 %mix,%flag
 %m0 = mul i64 %initial,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 200
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 208
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 216
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_31(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 48
 %answer = call fastcc i64 @memory_limbs_body_31(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define fastcc i64 @memory_limbs_body_32(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i800,ptr %input,align 1
 %yp = getelementptr i800,ptr %input,i64 1
 %y = load i800,ptr %yp,align 1
 %condition = icmp ne i800 %x,%y
 %selected = select i1 %condition,i800 %x,i800 %y
 %slot = alloca i800,align 16
 store i800 %selected,ptr %slot,align 16
 %slot0 = getelementptr i800,ptr %slot,i64 0
 %roundtrip = load i800,ptr %slot0,align 16
 store i800 %roundtrip,ptr %out,align 1
 br i1 %condition,label %left,label %right
left:
 br label %join
right:
 br label %join
join:
 %chosen = phi i800 [%y,%left],[%x,%right]
 %defined = freeze i800 %chosen
 %other = getelementptr i8,ptr %out,i64 100
 store i800 %defined,ptr %other,align 1
 %first = trunc i800 %roundtrip to i64
 %second = trunc i800 %defined to i64
 %mix = xor i64 %first,%second
 %flag = zext i1 %condition to i64
 %initial = xor i64 %mix,%flag
 %m0 = mul i64 %initial,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 200
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 208
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 216
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_32(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 48
 %answer = call fastcc i64 @memory_limbs_body_32(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define fastcc i64 @memory_limbs_body_33(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i800,ptr %input,align 1
 %yp = getelementptr i800,ptr %input,i64 1
 %y = load i800,ptr %yp,align 1
 %condition = icmp ult i800 %x,%y
 %selected = select i1 %condition,i800 %x,i800 %y
 %slot = alloca i800,align 16
 store i800 %selected,ptr %slot,align 16
 %slot0 = getelementptr i800,ptr %slot,i64 0
 %roundtrip = load i800,ptr %slot0,align 16
 store i800 %roundtrip,ptr %out,align 1
 br i1 %condition,label %left,label %right
left:
 br label %join
right:
 br label %join
join:
 %chosen = phi i800 [%y,%left],[%x,%right]
 %defined = freeze i800 %chosen
 %other = getelementptr i8,ptr %out,i64 100
 store i800 %defined,ptr %other,align 1
 %first = trunc i800 %roundtrip to i64
 %second = trunc i800 %defined to i64
 %mix = xor i64 %first,%second
 %flag = zext i1 %condition to i64
 %initial = xor i64 %mix,%flag
 %m0 = mul i64 %initial,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 200
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 208
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 216
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_33(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 48
 %answer = call fastcc i64 @memory_limbs_body_33(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define fastcc i64 @memory_limbs_body_34(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i800,ptr %input,align 1
 %yp = getelementptr i800,ptr %input,i64 1
 %y = load i800,ptr %yp,align 1
 %condition = icmp ule i800 %x,%y
 %selected = select i1 %condition,i800 %x,i800 %y
 %slot = alloca i800,align 16
 store i800 %selected,ptr %slot,align 16
 %slot0 = getelementptr i800,ptr %slot,i64 0
 %roundtrip = load i800,ptr %slot0,align 16
 store i800 %roundtrip,ptr %out,align 1
 br i1 %condition,label %left,label %right
left:
 br label %join
right:
 br label %join
join:
 %chosen = phi i800 [%y,%left],[%x,%right]
 %defined = freeze i800 %chosen
 %other = getelementptr i8,ptr %out,i64 100
 store i800 %defined,ptr %other,align 1
 %first = trunc i800 %roundtrip to i64
 %second = trunc i800 %defined to i64
 %mix = xor i64 %first,%second
 %flag = zext i1 %condition to i64
 %initial = xor i64 %mix,%flag
 %m0 = mul i64 %initial,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 200
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 208
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 216
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_34(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 48
 %answer = call fastcc i64 @memory_limbs_body_34(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define fastcc i64 @memory_limbs_body_35(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i800,ptr %input,align 1
 %yp = getelementptr i800,ptr %input,i64 1
 %y = load i800,ptr %yp,align 1
 %condition = icmp ugt i800 %x,%y
 %selected = select i1 %condition,i800 %x,i800 %y
 %slot = alloca i800,align 16
 store i800 %selected,ptr %slot,align 16
 %slot0 = getelementptr i800,ptr %slot,i64 0
 %roundtrip = load i800,ptr %slot0,align 16
 store i800 %roundtrip,ptr %out,align 1
 br i1 %condition,label %left,label %right
left:
 br label %join
right:
 br label %join
join:
 %chosen = phi i800 [%y,%left],[%x,%right]
 %defined = freeze i800 %chosen
 %other = getelementptr i8,ptr %out,i64 100
 store i800 %defined,ptr %other,align 1
 %first = trunc i800 %roundtrip to i64
 %second = trunc i800 %defined to i64
 %mix = xor i64 %first,%second
 %flag = zext i1 %condition to i64
 %initial = xor i64 %mix,%flag
 %m0 = mul i64 %initial,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 200
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 208
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 216
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_35(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 48
 %answer = call fastcc i64 @memory_limbs_body_35(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define fastcc i64 @memory_limbs_body_36(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i800,ptr %input,align 1
 %yp = getelementptr i800,ptr %input,i64 1
 %y = load i800,ptr %yp,align 1
 %condition = icmp uge i800 %x,%y
 %selected = select i1 %condition,i800 %x,i800 %y
 %slot = alloca i800,align 16
 store i800 %selected,ptr %slot,align 16
 %slot0 = getelementptr i800,ptr %slot,i64 0
 %roundtrip = load i800,ptr %slot0,align 16
 store i800 %roundtrip,ptr %out,align 1
 br i1 %condition,label %left,label %right
left:
 br label %join
right:
 br label %join
join:
 %chosen = phi i800 [%y,%left],[%x,%right]
 %defined = freeze i800 %chosen
 %other = getelementptr i8,ptr %out,i64 100
 store i800 %defined,ptr %other,align 1
 %first = trunc i800 %roundtrip to i64
 %second = trunc i800 %defined to i64
 %mix = xor i64 %first,%second
 %flag = zext i1 %condition to i64
 %initial = xor i64 %mix,%flag
 %m0 = mul i64 %initial,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 200
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 208
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 216
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_36(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 48
 %answer = call fastcc i64 @memory_limbs_body_36(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define fastcc i64 @memory_limbs_body_37(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i800,ptr %input,align 1
 %yp = getelementptr i800,ptr %input,i64 1
 %y = load i800,ptr %yp,align 1
 %condition = icmp slt i800 %x,%y
 %selected = select i1 %condition,i800 %x,i800 %y
 %slot = alloca i800,align 16
 store i800 %selected,ptr %slot,align 16
 %slot0 = getelementptr i800,ptr %slot,i64 0
 %roundtrip = load i800,ptr %slot0,align 16
 store i800 %roundtrip,ptr %out,align 1
 br i1 %condition,label %left,label %right
left:
 br label %join
right:
 br label %join
join:
 %chosen = phi i800 [%y,%left],[%x,%right]
 %defined = freeze i800 %chosen
 %other = getelementptr i8,ptr %out,i64 100
 store i800 %defined,ptr %other,align 1
 %first = trunc i800 %roundtrip to i64
 %second = trunc i800 %defined to i64
 %mix = xor i64 %first,%second
 %flag = zext i1 %condition to i64
 %initial = xor i64 %mix,%flag
 %m0 = mul i64 %initial,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 200
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 208
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 216
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_37(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 48
 %answer = call fastcc i64 @memory_limbs_body_37(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define fastcc i64 @memory_limbs_body_38(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i800,ptr %input,align 1
 %yp = getelementptr i800,ptr %input,i64 1
 %y = load i800,ptr %yp,align 1
 %condition = icmp sle i800 %x,%y
 %selected = select i1 %condition,i800 %x,i800 %y
 %slot = alloca i800,align 16
 store i800 %selected,ptr %slot,align 16
 %slot0 = getelementptr i800,ptr %slot,i64 0
 %roundtrip = load i800,ptr %slot0,align 16
 store i800 %roundtrip,ptr %out,align 1
 br i1 %condition,label %left,label %right
left:
 br label %join
right:
 br label %join
join:
 %chosen = phi i800 [%y,%left],[%x,%right]
 %defined = freeze i800 %chosen
 %other = getelementptr i8,ptr %out,i64 100
 store i800 %defined,ptr %other,align 1
 %first = trunc i800 %roundtrip to i64
 %second = trunc i800 %defined to i64
 %mix = xor i64 %first,%second
 %flag = zext i1 %condition to i64
 %initial = xor i64 %mix,%flag
 %m0 = mul i64 %initial,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 200
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 208
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 216
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_38(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 48
 %answer = call fastcc i64 @memory_limbs_body_38(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define fastcc i64 @memory_limbs_body_39(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i800,ptr %input,align 1
 %yp = getelementptr i800,ptr %input,i64 1
 %y = load i800,ptr %yp,align 1
 %condition = icmp sgt i800 %x,%y
 %selected = select i1 %condition,i800 %x,i800 %y
 %slot = alloca i800,align 16
 store i800 %selected,ptr %slot,align 16
 %slot0 = getelementptr i800,ptr %slot,i64 0
 %roundtrip = load i800,ptr %slot0,align 16
 store i800 %roundtrip,ptr %out,align 1
 br i1 %condition,label %left,label %right
left:
 br label %join
right:
 br label %join
join:
 %chosen = phi i800 [%y,%left],[%x,%right]
 %defined = freeze i800 %chosen
 %other = getelementptr i8,ptr %out,i64 100
 store i800 %defined,ptr %other,align 1
 %first = trunc i800 %roundtrip to i64
 %second = trunc i800 %defined to i64
 %mix = xor i64 %first,%second
 %flag = zext i1 %condition to i64
 %initial = xor i64 %mix,%flag
 %m0 = mul i64 %initial,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 200
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 208
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 216
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_39(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 48
 %answer = call fastcc i64 @memory_limbs_body_39(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define fastcc i64 @memory_limbs_body_40(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i800,ptr %input,align 1
 %yp = getelementptr i800,ptr %input,i64 1
 %y = load i800,ptr %yp,align 1
 %condition = icmp sge i800 %x,%y
 %selected = select i1 %condition,i800 %x,i800 %y
 %slot = alloca i800,align 16
 store i800 %selected,ptr %slot,align 16
 %slot0 = getelementptr i800,ptr %slot,i64 0
 %roundtrip = load i800,ptr %slot0,align 16
 store i800 %roundtrip,ptr %out,align 1
 br i1 %condition,label %left,label %right
left:
 br label %join
right:
 br label %join
join:
 %chosen = phi i800 [%y,%left],[%x,%right]
 %defined = freeze i800 %chosen
 %other = getelementptr i8,ptr %out,i64 100
 store i800 %defined,ptr %other,align 1
 %first = trunc i800 %roundtrip to i64
 %second = trunc i800 %defined to i64
 %mix = xor i64 %first,%second
 %flag = zext i1 %condition to i64
 %initial = xor i64 %mix,%flag
 %m0 = mul i64 %initial,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 200
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 208
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 216
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_40(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 48
 %answer = call fastcc i64 @memory_limbs_body_40(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define fastcc i64 @memory_limbs_body_41(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 store i800 0,ptr %out,align 1
 %value = load i800,ptr %out,align 1
 store i800 %value,ptr %out,align 1
 %low = trunc i800 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 100
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 108
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 116
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_41(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 160
 %answer = call fastcc i64 @memory_limbs_body_41(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define fastcc i64 @memory_limbs_body_42(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 store i800 -1,ptr %out,align 1
 %value = load i800,ptr %out,align 1
 store i800 %value,ptr %out,align 1
 %low = trunc i800 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 100
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 108
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 116
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_42(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 160
 %answer = call fastcc i64 @memory_limbs_body_42(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define fastcc i64 @memory_limbs_body_43(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 store i800 -3334007216439927137039925895360628898572379161157954080198128905882018618908816035760716100435777145371464955296716620222944400827059682540181678026165415023047578789757007279231539142955907012364482508067943300990845374018738230645581938688,ptr %out,align 1
 %value = load i800,ptr %out,align 1
 store i800 %value,ptr %out,align 1
 %low = trunc i800 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 100
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 108
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 116
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_43(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 160
 %answer = call fastcc i64 @memory_limbs_body_43(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define fastcc i64 @memory_limbs_body_44(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 store i800 3334007216439927137039925895360628898572379161157954080198128905882018618908816035760716100435777145371464955296716620222944400827059682540181678026165415023047578789757007279231539142955907012364482508067943300990845374018738230645581938687,ptr %out,align 1
 %value = load i800,ptr %out,align 1
 store i800 %value,ptr %out,align 1
 %low = trunc i800 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 100
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 108
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 116
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_44(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 160
 %answer = call fastcc i64 @memory_limbs_body_44(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define fastcc i64 @memory_limbs_body_45(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i800,ptr %input,align 1
 %value = trunc i800 %x to i8
 store i8 %value,ptr %out,align 1
 %low = zext i8 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 1
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 9
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 17
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_45(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 160
 %answer = call fastcc i64 @memory_limbs_body_45(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define fastcc i64 @memory_limbs_body_46(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i8,ptr %input,align 1
 %value = zext i8 %x to i800
 store i800 %value,ptr %out,align 1
 %low = trunc i800 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 100
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 108
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 116
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_46(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 64
 %answer = call fastcc i64 @memory_limbs_body_46(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define fastcc i64 @memory_limbs_body_47(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i8,ptr %input,align 1
 %value = sext i8 %x to i800
 store i800 %value,ptr %out,align 1
 %low = trunc i800 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 100
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 108
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 116
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_47(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 64
 %answer = call fastcc i64 @memory_limbs_body_47(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define fastcc i64 @memory_limbs_body_48(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i800,ptr %input,align 1
 %value = trunc i800 %x to i16
 store i16 %value,ptr %out,align 1
 %low = zext i16 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 2
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 10
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 18
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_48(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 160
 %answer = call fastcc i64 @memory_limbs_body_48(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define fastcc i64 @memory_limbs_body_49(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i16,ptr %input,align 1
 %value = zext i16 %x to i800
 store i800 %value,ptr %out,align 1
 %low = trunc i800 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 100
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 108
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 116
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_49(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 64
 %answer = call fastcc i64 @memory_limbs_body_49(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define fastcc i64 @memory_limbs_body_50(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i16,ptr %input,align 1
 %value = sext i16 %x to i800
 store i800 %value,ptr %out,align 1
 %low = trunc i800 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 100
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 108
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 116
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_50(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 64
 %answer = call fastcc i64 @memory_limbs_body_50(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define fastcc i64 @memory_limbs_body_51(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i800,ptr %input,align 1
 %value = trunc i800 %x to i32
 store i32 %value,ptr %out,align 1
 %low = zext i32 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 4
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 12
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 20
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_51(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 160
 %answer = call fastcc i64 @memory_limbs_body_51(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define fastcc i64 @memory_limbs_body_52(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i32,ptr %input,align 1
 %value = zext i32 %x to i800
 store i800 %value,ptr %out,align 1
 %low = trunc i800 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 100
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 108
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 116
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_52(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 64
 %answer = call fastcc i64 @memory_limbs_body_52(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define fastcc i64 @memory_limbs_body_53(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i32,ptr %input,align 1
 %value = sext i32 %x to i800
 store i800 %value,ptr %out,align 1
 %low = trunc i800 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 100
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 108
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 116
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_53(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 64
 %answer = call fastcc i64 @memory_limbs_body_53(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define fastcc i64 @memory_limbs_body_54(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i800,ptr %input,align 1
 %value = trunc i800 %x to i64
 store i64 %value,ptr %out,align 1
 %m0 = mul i64 %value,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 8
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 16
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 24
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_54(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 160
 %answer = call fastcc i64 @memory_limbs_body_54(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define fastcc i64 @memory_limbs_body_55(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i64,ptr %input,align 1
 %value = zext i64 %x to i800
 store i800 %value,ptr %out,align 1
 %low = trunc i800 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 100
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 108
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 116
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_55(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 64
 %answer = call fastcc i64 @memory_limbs_body_55(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define fastcc i64 @memory_limbs_body_56(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i64,ptr %input,align 1
 %value = sext i64 %x to i800
 store i800 %value,ptr %out,align 1
 %low = trunc i800 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 100
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 108
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 116
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_56(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 64
 %answer = call fastcc i64 @memory_limbs_body_56(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define fastcc i64 @memory_limbs_body_57(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i800,ptr %input,align 1
 %value = trunc i800 %x to i128
 store i128 %value,ptr %out,align 1
 %low = trunc i128 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 16
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 24
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 32
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_57(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 160
 %answer = call fastcc i64 @memory_limbs_body_57(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define fastcc i64 @memory_limbs_body_58(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i128,ptr %input,align 1
 %value = zext i128 %x to i800
 store i800 %value,ptr %out,align 1
 %low = trunc i800 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 100
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 108
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 116
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_58(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 64
 %answer = call fastcc i64 @memory_limbs_body_58(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define fastcc i64 @memory_limbs_body_59(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i128,ptr %input,align 1
 %value = sext i128 %x to i800
 store i800 %value,ptr %out,align 1
 %low = trunc i800 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 100
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 108
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 116
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_59(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 64
 %answer = call fastcc i64 @memory_limbs_body_59(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define i64 @memory_limbs_body_60(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i896,ptr %input,align 1
 %value = freeze i896 %x
 store i896 %value,ptr %out,align 1
 %low = trunc i896 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 112
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 120
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 128
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_60(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 160
 %answer = call i64 @memory_limbs_body_60(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define i64 @memory_limbs_body_61(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i896,ptr %input,align 1
 %yp = getelementptr i896,ptr %input,i64 1
 %y = load i896,ptr %yp,align 1
 %condition = icmp eq i896 %x,%y
 %selected = select i1 %condition,i896 %x,i896 %y
 %slot = alloca i896,align 16
 store i896 %selected,ptr %slot,align 16
 %slot0 = getelementptr i896,ptr %slot,i64 0
 %roundtrip = load i896,ptr %slot0,align 16
 store i896 %roundtrip,ptr %out,align 1
 br i1 %condition,label %left,label %right
left:
 br label %join
right:
 br label %join
join:
 %chosen = phi i896 [%y,%left],[%x,%right]
 %defined = freeze i896 %chosen
 %other = getelementptr i8,ptr %out,i64 112
 store i896 %defined,ptr %other,align 1
 %first = trunc i896 %roundtrip to i64
 %second = trunc i896 %defined to i64
 %mix = xor i64 %first,%second
 %flag = zext i1 %condition to i64
 %initial = xor i64 %mix,%flag
 %m0 = mul i64 %initial,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 224
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 232
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 240
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_61(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 48
 %answer = call i64 @memory_limbs_body_61(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define i64 @memory_limbs_body_62(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i896,ptr %input,align 1
 %yp = getelementptr i896,ptr %input,i64 1
 %y = load i896,ptr %yp,align 1
 %condition = icmp ne i896 %x,%y
 %selected = select i1 %condition,i896 %x,i896 %y
 %slot = alloca i896,align 16
 store i896 %selected,ptr %slot,align 16
 %slot0 = getelementptr i896,ptr %slot,i64 0
 %roundtrip = load i896,ptr %slot0,align 16
 store i896 %roundtrip,ptr %out,align 1
 br i1 %condition,label %left,label %right
left:
 br label %join
right:
 br label %join
join:
 %chosen = phi i896 [%y,%left],[%x,%right]
 %defined = freeze i896 %chosen
 %other = getelementptr i8,ptr %out,i64 112
 store i896 %defined,ptr %other,align 1
 %first = trunc i896 %roundtrip to i64
 %second = trunc i896 %defined to i64
 %mix = xor i64 %first,%second
 %flag = zext i1 %condition to i64
 %initial = xor i64 %mix,%flag
 %m0 = mul i64 %initial,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 224
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 232
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 240
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_62(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 48
 %answer = call i64 @memory_limbs_body_62(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define i64 @memory_limbs_body_63(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i896,ptr %input,align 1
 %yp = getelementptr i896,ptr %input,i64 1
 %y = load i896,ptr %yp,align 1
 %condition = icmp ult i896 %x,%y
 %selected = select i1 %condition,i896 %x,i896 %y
 %slot = alloca i896,align 16
 store i896 %selected,ptr %slot,align 16
 %slot0 = getelementptr i896,ptr %slot,i64 0
 %roundtrip = load i896,ptr %slot0,align 16
 store i896 %roundtrip,ptr %out,align 1
 br i1 %condition,label %left,label %right
left:
 br label %join
right:
 br label %join
join:
 %chosen = phi i896 [%y,%left],[%x,%right]
 %defined = freeze i896 %chosen
 %other = getelementptr i8,ptr %out,i64 112
 store i896 %defined,ptr %other,align 1
 %first = trunc i896 %roundtrip to i64
 %second = trunc i896 %defined to i64
 %mix = xor i64 %first,%second
 %flag = zext i1 %condition to i64
 %initial = xor i64 %mix,%flag
 %m0 = mul i64 %initial,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 224
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 232
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 240
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_63(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 48
 %answer = call i64 @memory_limbs_body_63(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define i64 @memory_limbs_body_64(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i896,ptr %input,align 1
 %yp = getelementptr i896,ptr %input,i64 1
 %y = load i896,ptr %yp,align 1
 %condition = icmp ule i896 %x,%y
 %selected = select i1 %condition,i896 %x,i896 %y
 %slot = alloca i896,align 16
 store i896 %selected,ptr %slot,align 16
 %slot0 = getelementptr i896,ptr %slot,i64 0
 %roundtrip = load i896,ptr %slot0,align 16
 store i896 %roundtrip,ptr %out,align 1
 br i1 %condition,label %left,label %right
left:
 br label %join
right:
 br label %join
join:
 %chosen = phi i896 [%y,%left],[%x,%right]
 %defined = freeze i896 %chosen
 %other = getelementptr i8,ptr %out,i64 112
 store i896 %defined,ptr %other,align 1
 %first = trunc i896 %roundtrip to i64
 %second = trunc i896 %defined to i64
 %mix = xor i64 %first,%second
 %flag = zext i1 %condition to i64
 %initial = xor i64 %mix,%flag
 %m0 = mul i64 %initial,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 224
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 232
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 240
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_64(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 48
 %answer = call i64 @memory_limbs_body_64(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define i64 @memory_limbs_body_65(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i896,ptr %input,align 1
 %yp = getelementptr i896,ptr %input,i64 1
 %y = load i896,ptr %yp,align 1
 %condition = icmp ugt i896 %x,%y
 %selected = select i1 %condition,i896 %x,i896 %y
 %slot = alloca i896,align 16
 store i896 %selected,ptr %slot,align 16
 %slot0 = getelementptr i896,ptr %slot,i64 0
 %roundtrip = load i896,ptr %slot0,align 16
 store i896 %roundtrip,ptr %out,align 1
 br i1 %condition,label %left,label %right
left:
 br label %join
right:
 br label %join
join:
 %chosen = phi i896 [%y,%left],[%x,%right]
 %defined = freeze i896 %chosen
 %other = getelementptr i8,ptr %out,i64 112
 store i896 %defined,ptr %other,align 1
 %first = trunc i896 %roundtrip to i64
 %second = trunc i896 %defined to i64
 %mix = xor i64 %first,%second
 %flag = zext i1 %condition to i64
 %initial = xor i64 %mix,%flag
 %m0 = mul i64 %initial,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 224
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 232
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 240
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_65(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 48
 %answer = call i64 @memory_limbs_body_65(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define i64 @memory_limbs_body_66(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i896,ptr %input,align 1
 %yp = getelementptr i896,ptr %input,i64 1
 %y = load i896,ptr %yp,align 1
 %condition = icmp uge i896 %x,%y
 %selected = select i1 %condition,i896 %x,i896 %y
 %slot = alloca i896,align 16
 store i896 %selected,ptr %slot,align 16
 %slot0 = getelementptr i896,ptr %slot,i64 0
 %roundtrip = load i896,ptr %slot0,align 16
 store i896 %roundtrip,ptr %out,align 1
 br i1 %condition,label %left,label %right
left:
 br label %join
right:
 br label %join
join:
 %chosen = phi i896 [%y,%left],[%x,%right]
 %defined = freeze i896 %chosen
 %other = getelementptr i8,ptr %out,i64 112
 store i896 %defined,ptr %other,align 1
 %first = trunc i896 %roundtrip to i64
 %second = trunc i896 %defined to i64
 %mix = xor i64 %first,%second
 %flag = zext i1 %condition to i64
 %initial = xor i64 %mix,%flag
 %m0 = mul i64 %initial,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 224
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 232
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 240
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_66(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 48
 %answer = call i64 @memory_limbs_body_66(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define i64 @memory_limbs_body_67(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i896,ptr %input,align 1
 %yp = getelementptr i896,ptr %input,i64 1
 %y = load i896,ptr %yp,align 1
 %condition = icmp slt i896 %x,%y
 %selected = select i1 %condition,i896 %x,i896 %y
 %slot = alloca i896,align 16
 store i896 %selected,ptr %slot,align 16
 %slot0 = getelementptr i896,ptr %slot,i64 0
 %roundtrip = load i896,ptr %slot0,align 16
 store i896 %roundtrip,ptr %out,align 1
 br i1 %condition,label %left,label %right
left:
 br label %join
right:
 br label %join
join:
 %chosen = phi i896 [%y,%left],[%x,%right]
 %defined = freeze i896 %chosen
 %other = getelementptr i8,ptr %out,i64 112
 store i896 %defined,ptr %other,align 1
 %first = trunc i896 %roundtrip to i64
 %second = trunc i896 %defined to i64
 %mix = xor i64 %first,%second
 %flag = zext i1 %condition to i64
 %initial = xor i64 %mix,%flag
 %m0 = mul i64 %initial,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 224
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 232
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 240
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_67(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 48
 %answer = call i64 @memory_limbs_body_67(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define i64 @memory_limbs_body_68(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i896,ptr %input,align 1
 %yp = getelementptr i896,ptr %input,i64 1
 %y = load i896,ptr %yp,align 1
 %condition = icmp sle i896 %x,%y
 %selected = select i1 %condition,i896 %x,i896 %y
 %slot = alloca i896,align 16
 store i896 %selected,ptr %slot,align 16
 %slot0 = getelementptr i896,ptr %slot,i64 0
 %roundtrip = load i896,ptr %slot0,align 16
 store i896 %roundtrip,ptr %out,align 1
 br i1 %condition,label %left,label %right
left:
 br label %join
right:
 br label %join
join:
 %chosen = phi i896 [%y,%left],[%x,%right]
 %defined = freeze i896 %chosen
 %other = getelementptr i8,ptr %out,i64 112
 store i896 %defined,ptr %other,align 1
 %first = trunc i896 %roundtrip to i64
 %second = trunc i896 %defined to i64
 %mix = xor i64 %first,%second
 %flag = zext i1 %condition to i64
 %initial = xor i64 %mix,%flag
 %m0 = mul i64 %initial,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 224
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 232
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 240
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_68(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 48
 %answer = call i64 @memory_limbs_body_68(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define i64 @memory_limbs_body_69(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i896,ptr %input,align 1
 %yp = getelementptr i896,ptr %input,i64 1
 %y = load i896,ptr %yp,align 1
 %condition = icmp sgt i896 %x,%y
 %selected = select i1 %condition,i896 %x,i896 %y
 %slot = alloca i896,align 16
 store i896 %selected,ptr %slot,align 16
 %slot0 = getelementptr i896,ptr %slot,i64 0
 %roundtrip = load i896,ptr %slot0,align 16
 store i896 %roundtrip,ptr %out,align 1
 br i1 %condition,label %left,label %right
left:
 br label %join
right:
 br label %join
join:
 %chosen = phi i896 [%y,%left],[%x,%right]
 %defined = freeze i896 %chosen
 %other = getelementptr i8,ptr %out,i64 112
 store i896 %defined,ptr %other,align 1
 %first = trunc i896 %roundtrip to i64
 %second = trunc i896 %defined to i64
 %mix = xor i64 %first,%second
 %flag = zext i1 %condition to i64
 %initial = xor i64 %mix,%flag
 %m0 = mul i64 %initial,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 224
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 232
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 240
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_69(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 48
 %answer = call i64 @memory_limbs_body_69(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define i64 @memory_limbs_body_70(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i896,ptr %input,align 1
 %yp = getelementptr i896,ptr %input,i64 1
 %y = load i896,ptr %yp,align 1
 %condition = icmp sge i896 %x,%y
 %selected = select i1 %condition,i896 %x,i896 %y
 %slot = alloca i896,align 16
 store i896 %selected,ptr %slot,align 16
 %slot0 = getelementptr i896,ptr %slot,i64 0
 %roundtrip = load i896,ptr %slot0,align 16
 store i896 %roundtrip,ptr %out,align 1
 br i1 %condition,label %left,label %right
left:
 br label %join
right:
 br label %join
join:
 %chosen = phi i896 [%y,%left],[%x,%right]
 %defined = freeze i896 %chosen
 %other = getelementptr i8,ptr %out,i64 112
 store i896 %defined,ptr %other,align 1
 %first = trunc i896 %roundtrip to i64
 %second = trunc i896 %defined to i64
 %mix = xor i64 %first,%second
 %flag = zext i1 %condition to i64
 %initial = xor i64 %mix,%flag
 %m0 = mul i64 %initial,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 224
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 232
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 240
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_70(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 48
 %answer = call i64 @memory_limbs_body_70(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define i64 @memory_limbs_body_71(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 store i896 0,ptr %out,align 1
 %value = load i896,ptr %out,align 1
 store i896 %value,ptr %out,align 1
 %low = trunc i896 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 112
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 120
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 128
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_71(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 160
 %answer = call i64 @memory_limbs_body_71(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define i64 @memory_limbs_body_72(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 store i896 -1,ptr %out,align 1
 %value = load i896,ptr %out,align 1
 store i896 %value,ptr %out,align 1
 %low = trunc i896 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 112
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 120
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 128
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_72(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 160
 %answer = call i64 @memory_limbs_body_72(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define i64 @memory_limbs_body_73(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 store i896 -264147265567832623176169892458258303259423663018060761063980354513336951278362429737208627943828593947337197496628564339441173779751342768625269489231469788454193341999502542084365758838213220526512116454105594202074014146375780869419198449383518238244769290448868999168,ptr %out,align 1
 %value = load i896,ptr %out,align 1
 store i896 %value,ptr %out,align 1
 %low = trunc i896 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 112
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 120
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 128
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_73(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 160
 %answer = call i64 @memory_limbs_body_73(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define i64 @memory_limbs_body_74(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 store i896 264147265567832623176169892458258303259423663018060761063980354513336951278362429737208627943828593947337197496628564339441173779751342768625269489231469788454193341999502542084365758838213220526512116454105594202074014146375780869419198449383518238244769290448868999167,ptr %out,align 1
 %value = load i896,ptr %out,align 1
 store i896 %value,ptr %out,align 1
 %low = trunc i896 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 112
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 120
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 128
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_74(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 160
 %answer = call i64 @memory_limbs_body_74(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define i64 @memory_limbs_body_75(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i896,ptr %input,align 1
 %value = trunc i896 %x to i8
 store i8 %value,ptr %out,align 1
 %low = zext i8 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 1
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 9
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 17
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_75(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 160
 %answer = call i64 @memory_limbs_body_75(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define i64 @memory_limbs_body_76(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i8,ptr %input,align 1
 %value = zext i8 %x to i896
 store i896 %value,ptr %out,align 1
 %low = trunc i896 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 112
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 120
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 128
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_76(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 64
 %answer = call i64 @memory_limbs_body_76(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define i64 @memory_limbs_body_77(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i8,ptr %input,align 1
 %value = sext i8 %x to i896
 store i896 %value,ptr %out,align 1
 %low = trunc i896 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 112
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 120
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 128
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_77(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 64
 %answer = call i64 @memory_limbs_body_77(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define i64 @memory_limbs_body_78(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i896,ptr %input,align 1
 %value = trunc i896 %x to i16
 store i16 %value,ptr %out,align 1
 %low = zext i16 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 2
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 10
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 18
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_78(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 160
 %answer = call i64 @memory_limbs_body_78(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define i64 @memory_limbs_body_79(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i16,ptr %input,align 1
 %value = zext i16 %x to i896
 store i896 %value,ptr %out,align 1
 %low = trunc i896 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 112
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 120
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 128
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_79(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 64
 %answer = call i64 @memory_limbs_body_79(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define i64 @memory_limbs_body_80(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i16,ptr %input,align 1
 %value = sext i16 %x to i896
 store i896 %value,ptr %out,align 1
 %low = trunc i896 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 112
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 120
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 128
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_80(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 64
 %answer = call i64 @memory_limbs_body_80(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define i64 @memory_limbs_body_81(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i896,ptr %input,align 1
 %value = trunc i896 %x to i32
 store i32 %value,ptr %out,align 1
 %low = zext i32 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 4
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 12
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 20
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_81(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 160
 %answer = call i64 @memory_limbs_body_81(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define i64 @memory_limbs_body_82(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i32,ptr %input,align 1
 %value = zext i32 %x to i896
 store i896 %value,ptr %out,align 1
 %low = trunc i896 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 112
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 120
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 128
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_82(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 64
 %answer = call i64 @memory_limbs_body_82(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define i64 @memory_limbs_body_83(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i32,ptr %input,align 1
 %value = sext i32 %x to i896
 store i896 %value,ptr %out,align 1
 %low = trunc i896 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 112
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 120
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 128
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_83(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 64
 %answer = call i64 @memory_limbs_body_83(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define i64 @memory_limbs_body_84(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i896,ptr %input,align 1
 %value = trunc i896 %x to i64
 store i64 %value,ptr %out,align 1
 %m0 = mul i64 %value,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 8
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 16
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 24
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_84(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 160
 %answer = call i64 @memory_limbs_body_84(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define i64 @memory_limbs_body_85(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i64,ptr %input,align 1
 %value = zext i64 %x to i896
 store i896 %value,ptr %out,align 1
 %low = trunc i896 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 112
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 120
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 128
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_85(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 64
 %answer = call i64 @memory_limbs_body_85(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define i64 @memory_limbs_body_86(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i64,ptr %input,align 1
 %value = sext i64 %x to i896
 store i896 %value,ptr %out,align 1
 %low = trunc i896 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 112
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 120
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 128
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_86(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 64
 %answer = call i64 @memory_limbs_body_86(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define i64 @memory_limbs_body_87(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i896,ptr %input,align 1
 %value = trunc i896 %x to i128
 store i128 %value,ptr %out,align 1
 %low = trunc i128 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 16
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 24
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 32
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_87(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 160
 %answer = call i64 @memory_limbs_body_87(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define i64 @memory_limbs_body_88(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i128,ptr %input,align 1
 %value = zext i128 %x to i896
 store i896 %value,ptr %out,align 1
 %low = trunc i896 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 112
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 120
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 128
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_88(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 64
 %answer = call i64 @memory_limbs_body_88(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define i64 @memory_limbs_body_89(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i128,ptr %input,align 1
 %value = sext i128 %x to i896
 store i896 %value,ptr %out,align 1
 %low = trunc i896 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 112
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 120
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 128
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_89(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 64
 %answer = call i64 @memory_limbs_body_89(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define fastcc i64 @memory_limbs_body_90(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i896,ptr %input,align 1
 %value = freeze i896 %x
 store i896 %value,ptr %out,align 1
 %low = trunc i896 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 112
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 120
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 128
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_90(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 160
 %answer = call fastcc i64 @memory_limbs_body_90(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define fastcc i64 @memory_limbs_body_91(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i896,ptr %input,align 1
 %yp = getelementptr i896,ptr %input,i64 1
 %y = load i896,ptr %yp,align 1
 %condition = icmp eq i896 %x,%y
 %selected = select i1 %condition,i896 %x,i896 %y
 %slot = alloca i896,align 16
 store i896 %selected,ptr %slot,align 16
 %slot0 = getelementptr i896,ptr %slot,i64 0
 %roundtrip = load i896,ptr %slot0,align 16
 store i896 %roundtrip,ptr %out,align 1
 br i1 %condition,label %left,label %right
left:
 br label %join
right:
 br label %join
join:
 %chosen = phi i896 [%y,%left],[%x,%right]
 %defined = freeze i896 %chosen
 %other = getelementptr i8,ptr %out,i64 112
 store i896 %defined,ptr %other,align 1
 %first = trunc i896 %roundtrip to i64
 %second = trunc i896 %defined to i64
 %mix = xor i64 %first,%second
 %flag = zext i1 %condition to i64
 %initial = xor i64 %mix,%flag
 %m0 = mul i64 %initial,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 224
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 232
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 240
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_91(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 48
 %answer = call fastcc i64 @memory_limbs_body_91(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define fastcc i64 @memory_limbs_body_92(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i896,ptr %input,align 1
 %yp = getelementptr i896,ptr %input,i64 1
 %y = load i896,ptr %yp,align 1
 %condition = icmp ne i896 %x,%y
 %selected = select i1 %condition,i896 %x,i896 %y
 %slot = alloca i896,align 16
 store i896 %selected,ptr %slot,align 16
 %slot0 = getelementptr i896,ptr %slot,i64 0
 %roundtrip = load i896,ptr %slot0,align 16
 store i896 %roundtrip,ptr %out,align 1
 br i1 %condition,label %left,label %right
left:
 br label %join
right:
 br label %join
join:
 %chosen = phi i896 [%y,%left],[%x,%right]
 %defined = freeze i896 %chosen
 %other = getelementptr i8,ptr %out,i64 112
 store i896 %defined,ptr %other,align 1
 %first = trunc i896 %roundtrip to i64
 %second = trunc i896 %defined to i64
 %mix = xor i64 %first,%second
 %flag = zext i1 %condition to i64
 %initial = xor i64 %mix,%flag
 %m0 = mul i64 %initial,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 224
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 232
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 240
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_92(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 48
 %answer = call fastcc i64 @memory_limbs_body_92(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define fastcc i64 @memory_limbs_body_93(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i896,ptr %input,align 1
 %yp = getelementptr i896,ptr %input,i64 1
 %y = load i896,ptr %yp,align 1
 %condition = icmp ult i896 %x,%y
 %selected = select i1 %condition,i896 %x,i896 %y
 %slot = alloca i896,align 16
 store i896 %selected,ptr %slot,align 16
 %slot0 = getelementptr i896,ptr %slot,i64 0
 %roundtrip = load i896,ptr %slot0,align 16
 store i896 %roundtrip,ptr %out,align 1
 br i1 %condition,label %left,label %right
left:
 br label %join
right:
 br label %join
join:
 %chosen = phi i896 [%y,%left],[%x,%right]
 %defined = freeze i896 %chosen
 %other = getelementptr i8,ptr %out,i64 112
 store i896 %defined,ptr %other,align 1
 %first = trunc i896 %roundtrip to i64
 %second = trunc i896 %defined to i64
 %mix = xor i64 %first,%second
 %flag = zext i1 %condition to i64
 %initial = xor i64 %mix,%flag
 %m0 = mul i64 %initial,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 224
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 232
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 240
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_93(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 48
 %answer = call fastcc i64 @memory_limbs_body_93(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define fastcc i64 @memory_limbs_body_94(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i896,ptr %input,align 1
 %yp = getelementptr i896,ptr %input,i64 1
 %y = load i896,ptr %yp,align 1
 %condition = icmp ule i896 %x,%y
 %selected = select i1 %condition,i896 %x,i896 %y
 %slot = alloca i896,align 16
 store i896 %selected,ptr %slot,align 16
 %slot0 = getelementptr i896,ptr %slot,i64 0
 %roundtrip = load i896,ptr %slot0,align 16
 store i896 %roundtrip,ptr %out,align 1
 br i1 %condition,label %left,label %right
left:
 br label %join
right:
 br label %join
join:
 %chosen = phi i896 [%y,%left],[%x,%right]
 %defined = freeze i896 %chosen
 %other = getelementptr i8,ptr %out,i64 112
 store i896 %defined,ptr %other,align 1
 %first = trunc i896 %roundtrip to i64
 %second = trunc i896 %defined to i64
 %mix = xor i64 %first,%second
 %flag = zext i1 %condition to i64
 %initial = xor i64 %mix,%flag
 %m0 = mul i64 %initial,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 224
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 232
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 240
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_94(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 48
 %answer = call fastcc i64 @memory_limbs_body_94(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define fastcc i64 @memory_limbs_body_95(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i896,ptr %input,align 1
 %yp = getelementptr i896,ptr %input,i64 1
 %y = load i896,ptr %yp,align 1
 %condition = icmp ugt i896 %x,%y
 %selected = select i1 %condition,i896 %x,i896 %y
 %slot = alloca i896,align 16
 store i896 %selected,ptr %slot,align 16
 %slot0 = getelementptr i896,ptr %slot,i64 0
 %roundtrip = load i896,ptr %slot0,align 16
 store i896 %roundtrip,ptr %out,align 1
 br i1 %condition,label %left,label %right
left:
 br label %join
right:
 br label %join
join:
 %chosen = phi i896 [%y,%left],[%x,%right]
 %defined = freeze i896 %chosen
 %other = getelementptr i8,ptr %out,i64 112
 store i896 %defined,ptr %other,align 1
 %first = trunc i896 %roundtrip to i64
 %second = trunc i896 %defined to i64
 %mix = xor i64 %first,%second
 %flag = zext i1 %condition to i64
 %initial = xor i64 %mix,%flag
 %m0 = mul i64 %initial,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 224
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 232
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 240
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_95(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 48
 %answer = call fastcc i64 @memory_limbs_body_95(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define fastcc i64 @memory_limbs_body_96(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i896,ptr %input,align 1
 %yp = getelementptr i896,ptr %input,i64 1
 %y = load i896,ptr %yp,align 1
 %condition = icmp uge i896 %x,%y
 %selected = select i1 %condition,i896 %x,i896 %y
 %slot = alloca i896,align 16
 store i896 %selected,ptr %slot,align 16
 %slot0 = getelementptr i896,ptr %slot,i64 0
 %roundtrip = load i896,ptr %slot0,align 16
 store i896 %roundtrip,ptr %out,align 1
 br i1 %condition,label %left,label %right
left:
 br label %join
right:
 br label %join
join:
 %chosen = phi i896 [%y,%left],[%x,%right]
 %defined = freeze i896 %chosen
 %other = getelementptr i8,ptr %out,i64 112
 store i896 %defined,ptr %other,align 1
 %first = trunc i896 %roundtrip to i64
 %second = trunc i896 %defined to i64
 %mix = xor i64 %first,%second
 %flag = zext i1 %condition to i64
 %initial = xor i64 %mix,%flag
 %m0 = mul i64 %initial,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 224
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 232
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 240
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_96(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 48
 %answer = call fastcc i64 @memory_limbs_body_96(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define fastcc i64 @memory_limbs_body_97(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i896,ptr %input,align 1
 %yp = getelementptr i896,ptr %input,i64 1
 %y = load i896,ptr %yp,align 1
 %condition = icmp slt i896 %x,%y
 %selected = select i1 %condition,i896 %x,i896 %y
 %slot = alloca i896,align 16
 store i896 %selected,ptr %slot,align 16
 %slot0 = getelementptr i896,ptr %slot,i64 0
 %roundtrip = load i896,ptr %slot0,align 16
 store i896 %roundtrip,ptr %out,align 1
 br i1 %condition,label %left,label %right
left:
 br label %join
right:
 br label %join
join:
 %chosen = phi i896 [%y,%left],[%x,%right]
 %defined = freeze i896 %chosen
 %other = getelementptr i8,ptr %out,i64 112
 store i896 %defined,ptr %other,align 1
 %first = trunc i896 %roundtrip to i64
 %second = trunc i896 %defined to i64
 %mix = xor i64 %first,%second
 %flag = zext i1 %condition to i64
 %initial = xor i64 %mix,%flag
 %m0 = mul i64 %initial,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 224
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 232
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 240
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_97(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 48
 %answer = call fastcc i64 @memory_limbs_body_97(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define fastcc i64 @memory_limbs_body_98(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i896,ptr %input,align 1
 %yp = getelementptr i896,ptr %input,i64 1
 %y = load i896,ptr %yp,align 1
 %condition = icmp sle i896 %x,%y
 %selected = select i1 %condition,i896 %x,i896 %y
 %slot = alloca i896,align 16
 store i896 %selected,ptr %slot,align 16
 %slot0 = getelementptr i896,ptr %slot,i64 0
 %roundtrip = load i896,ptr %slot0,align 16
 store i896 %roundtrip,ptr %out,align 1
 br i1 %condition,label %left,label %right
left:
 br label %join
right:
 br label %join
join:
 %chosen = phi i896 [%y,%left],[%x,%right]
 %defined = freeze i896 %chosen
 %other = getelementptr i8,ptr %out,i64 112
 store i896 %defined,ptr %other,align 1
 %first = trunc i896 %roundtrip to i64
 %second = trunc i896 %defined to i64
 %mix = xor i64 %first,%second
 %flag = zext i1 %condition to i64
 %initial = xor i64 %mix,%flag
 %m0 = mul i64 %initial,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 224
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 232
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 240
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_98(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 48
 %answer = call fastcc i64 @memory_limbs_body_98(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define fastcc i64 @memory_limbs_body_99(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i896,ptr %input,align 1
 %yp = getelementptr i896,ptr %input,i64 1
 %y = load i896,ptr %yp,align 1
 %condition = icmp sgt i896 %x,%y
 %selected = select i1 %condition,i896 %x,i896 %y
 %slot = alloca i896,align 16
 store i896 %selected,ptr %slot,align 16
 %slot0 = getelementptr i896,ptr %slot,i64 0
 %roundtrip = load i896,ptr %slot0,align 16
 store i896 %roundtrip,ptr %out,align 1
 br i1 %condition,label %left,label %right
left:
 br label %join
right:
 br label %join
join:
 %chosen = phi i896 [%y,%left],[%x,%right]
 %defined = freeze i896 %chosen
 %other = getelementptr i8,ptr %out,i64 112
 store i896 %defined,ptr %other,align 1
 %first = trunc i896 %roundtrip to i64
 %second = trunc i896 %defined to i64
 %mix = xor i64 %first,%second
 %flag = zext i1 %condition to i64
 %initial = xor i64 %mix,%flag
 %m0 = mul i64 %initial,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 224
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 232
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 240
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_99(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 48
 %answer = call fastcc i64 @memory_limbs_body_99(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define fastcc i64 @memory_limbs_body_100(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i896,ptr %input,align 1
 %yp = getelementptr i896,ptr %input,i64 1
 %y = load i896,ptr %yp,align 1
 %condition = icmp sge i896 %x,%y
 %selected = select i1 %condition,i896 %x,i896 %y
 %slot = alloca i896,align 16
 store i896 %selected,ptr %slot,align 16
 %slot0 = getelementptr i896,ptr %slot,i64 0
 %roundtrip = load i896,ptr %slot0,align 16
 store i896 %roundtrip,ptr %out,align 1
 br i1 %condition,label %left,label %right
left:
 br label %join
right:
 br label %join
join:
 %chosen = phi i896 [%y,%left],[%x,%right]
 %defined = freeze i896 %chosen
 %other = getelementptr i8,ptr %out,i64 112
 store i896 %defined,ptr %other,align 1
 %first = trunc i896 %roundtrip to i64
 %second = trunc i896 %defined to i64
 %mix = xor i64 %first,%second
 %flag = zext i1 %condition to i64
 %initial = xor i64 %mix,%flag
 %m0 = mul i64 %initial,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 224
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 232
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 240
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_100(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 48
 %answer = call fastcc i64 @memory_limbs_body_100(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define fastcc i64 @memory_limbs_body_101(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 store i896 0,ptr %out,align 1
 %value = load i896,ptr %out,align 1
 store i896 %value,ptr %out,align 1
 %low = trunc i896 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 112
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 120
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 128
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_101(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 160
 %answer = call fastcc i64 @memory_limbs_body_101(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define fastcc i64 @memory_limbs_body_102(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 store i896 -1,ptr %out,align 1
 %value = load i896,ptr %out,align 1
 store i896 %value,ptr %out,align 1
 %low = trunc i896 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 112
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 120
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 128
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_102(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 160
 %answer = call fastcc i64 @memory_limbs_body_102(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define fastcc i64 @memory_limbs_body_103(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 store i896 -264147265567832623176169892458258303259423663018060761063980354513336951278362429737208627943828593947337197496628564339441173779751342768625269489231469788454193341999502542084365758838213220526512116454105594202074014146375780869419198449383518238244769290448868999168,ptr %out,align 1
 %value = load i896,ptr %out,align 1
 store i896 %value,ptr %out,align 1
 %low = trunc i896 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 112
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 120
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 128
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_103(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 160
 %answer = call fastcc i64 @memory_limbs_body_103(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define fastcc i64 @memory_limbs_body_104(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 store i896 264147265567832623176169892458258303259423663018060761063980354513336951278362429737208627943828593947337197496628564339441173779751342768625269489231469788454193341999502542084365758838213220526512116454105594202074014146375780869419198449383518238244769290448868999167,ptr %out,align 1
 %value = load i896,ptr %out,align 1
 store i896 %value,ptr %out,align 1
 %low = trunc i896 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 112
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 120
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 128
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_104(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 160
 %answer = call fastcc i64 @memory_limbs_body_104(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define fastcc i64 @memory_limbs_body_105(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i896,ptr %input,align 1
 %value = trunc i896 %x to i8
 store i8 %value,ptr %out,align 1
 %low = zext i8 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 1
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 9
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 17
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_105(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 160
 %answer = call fastcc i64 @memory_limbs_body_105(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define fastcc i64 @memory_limbs_body_106(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i8,ptr %input,align 1
 %value = zext i8 %x to i896
 store i896 %value,ptr %out,align 1
 %low = trunc i896 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 112
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 120
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 128
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_106(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 64
 %answer = call fastcc i64 @memory_limbs_body_106(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define fastcc i64 @memory_limbs_body_107(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i8,ptr %input,align 1
 %value = sext i8 %x to i896
 store i896 %value,ptr %out,align 1
 %low = trunc i896 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 112
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 120
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 128
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_107(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 64
 %answer = call fastcc i64 @memory_limbs_body_107(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define fastcc i64 @memory_limbs_body_108(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i896,ptr %input,align 1
 %value = trunc i896 %x to i16
 store i16 %value,ptr %out,align 1
 %low = zext i16 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 2
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 10
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 18
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_108(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 160
 %answer = call fastcc i64 @memory_limbs_body_108(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define fastcc i64 @memory_limbs_body_109(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i16,ptr %input,align 1
 %value = zext i16 %x to i896
 store i896 %value,ptr %out,align 1
 %low = trunc i896 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 112
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 120
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 128
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_109(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 64
 %answer = call fastcc i64 @memory_limbs_body_109(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define fastcc i64 @memory_limbs_body_110(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i16,ptr %input,align 1
 %value = sext i16 %x to i896
 store i896 %value,ptr %out,align 1
 %low = trunc i896 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 112
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 120
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 128
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_110(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 64
 %answer = call fastcc i64 @memory_limbs_body_110(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define fastcc i64 @memory_limbs_body_111(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i896,ptr %input,align 1
 %value = trunc i896 %x to i32
 store i32 %value,ptr %out,align 1
 %low = zext i32 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 4
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 12
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 20
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_111(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 160
 %answer = call fastcc i64 @memory_limbs_body_111(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define fastcc i64 @memory_limbs_body_112(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i32,ptr %input,align 1
 %value = zext i32 %x to i896
 store i896 %value,ptr %out,align 1
 %low = trunc i896 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 112
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 120
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 128
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_112(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 64
 %answer = call fastcc i64 @memory_limbs_body_112(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define fastcc i64 @memory_limbs_body_113(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i32,ptr %input,align 1
 %value = sext i32 %x to i896
 store i896 %value,ptr %out,align 1
 %low = trunc i896 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 112
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 120
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 128
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_113(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 64
 %answer = call fastcc i64 @memory_limbs_body_113(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define fastcc i64 @memory_limbs_body_114(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i896,ptr %input,align 1
 %value = trunc i896 %x to i64
 store i64 %value,ptr %out,align 1
 %m0 = mul i64 %value,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 8
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 16
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 24
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_114(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 160
 %answer = call fastcc i64 @memory_limbs_body_114(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define fastcc i64 @memory_limbs_body_115(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i64,ptr %input,align 1
 %value = zext i64 %x to i896
 store i896 %value,ptr %out,align 1
 %low = trunc i896 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 112
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 120
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 128
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_115(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 64
 %answer = call fastcc i64 @memory_limbs_body_115(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define fastcc i64 @memory_limbs_body_116(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i64,ptr %input,align 1
 %value = sext i64 %x to i896
 store i896 %value,ptr %out,align 1
 %low = trunc i896 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 112
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 120
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 128
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_116(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 64
 %answer = call fastcc i64 @memory_limbs_body_116(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define fastcc i64 @memory_limbs_body_117(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i896,ptr %input,align 1
 %value = trunc i896 %x to i128
 store i128 %value,ptr %out,align 1
 %low = trunc i128 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 16
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 24
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 32
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_117(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 160
 %answer = call fastcc i64 @memory_limbs_body_117(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define fastcc i64 @memory_limbs_body_118(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i128,ptr %input,align 1
 %value = zext i128 %x to i896
 store i896 %value,ptr %out,align 1
 %low = trunc i896 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 112
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 120
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 128
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_118(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 64
 %answer = call fastcc i64 @memory_limbs_body_118(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define fastcc i64 @memory_limbs_body_119(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i128,ptr %input,align 1
 %value = sext i128 %x to i896
 store i896 %value,ptr %out,align 1
 %low = trunc i896 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 112
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 120
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 128
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_119(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 64
 %answer = call fastcc i64 @memory_limbs_body_119(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define i64 @memory_limbs_body_120(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i1024,ptr %input,align 1
 %value = freeze i1024 %x
 store i1024 %value,ptr %out,align 1
 %low = trunc i1024 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 128
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 136
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 144
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_120(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 176
 %answer = call i64 @memory_limbs_body_120(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define i64 @memory_limbs_body_121(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i1024,ptr %input,align 1
 %yp = getelementptr i1024,ptr %input,i64 1
 %y = load i1024,ptr %yp,align 1
 %condition = icmp eq i1024 %x,%y
 %selected = select i1 %condition,i1024 %x,i1024 %y
 %slot = alloca i1024,align 16
 store i1024 %selected,ptr %slot,align 16
 %slot0 = getelementptr i1024,ptr %slot,i64 0
 %roundtrip = load i1024,ptr %slot0,align 16
 store i1024 %roundtrip,ptr %out,align 1
 br i1 %condition,label %left,label %right
left:
 br label %join
right:
 br label %join
join:
 %chosen = phi i1024 [%y,%left],[%x,%right]
 %defined = freeze i1024 %chosen
 %other = getelementptr i8,ptr %out,i64 128
 store i1024 %defined,ptr %other,align 1
 %first = trunc i1024 %roundtrip to i64
 %second = trunc i1024 %defined to i64
 %mix = xor i64 %first,%second
 %flag = zext i1 %condition to i64
 %initial = xor i64 %mix,%flag
 %m0 = mul i64 %initial,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 256
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 264
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 272
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_121(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 48
 %answer = call i64 @memory_limbs_body_121(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define i64 @memory_limbs_body_122(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i1024,ptr %input,align 1
 %yp = getelementptr i1024,ptr %input,i64 1
 %y = load i1024,ptr %yp,align 1
 %condition = icmp ne i1024 %x,%y
 %selected = select i1 %condition,i1024 %x,i1024 %y
 %slot = alloca i1024,align 16
 store i1024 %selected,ptr %slot,align 16
 %slot0 = getelementptr i1024,ptr %slot,i64 0
 %roundtrip = load i1024,ptr %slot0,align 16
 store i1024 %roundtrip,ptr %out,align 1
 br i1 %condition,label %left,label %right
left:
 br label %join
right:
 br label %join
join:
 %chosen = phi i1024 [%y,%left],[%x,%right]
 %defined = freeze i1024 %chosen
 %other = getelementptr i8,ptr %out,i64 128
 store i1024 %defined,ptr %other,align 1
 %first = trunc i1024 %roundtrip to i64
 %second = trunc i1024 %defined to i64
 %mix = xor i64 %first,%second
 %flag = zext i1 %condition to i64
 %initial = xor i64 %mix,%flag
 %m0 = mul i64 %initial,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 256
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 264
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 272
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_122(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 48
 %answer = call i64 @memory_limbs_body_122(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define i64 @memory_limbs_body_123(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i1024,ptr %input,align 1
 %yp = getelementptr i1024,ptr %input,i64 1
 %y = load i1024,ptr %yp,align 1
 %condition = icmp ult i1024 %x,%y
 %selected = select i1 %condition,i1024 %x,i1024 %y
 %slot = alloca i1024,align 16
 store i1024 %selected,ptr %slot,align 16
 %slot0 = getelementptr i1024,ptr %slot,i64 0
 %roundtrip = load i1024,ptr %slot0,align 16
 store i1024 %roundtrip,ptr %out,align 1
 br i1 %condition,label %left,label %right
left:
 br label %join
right:
 br label %join
join:
 %chosen = phi i1024 [%y,%left],[%x,%right]
 %defined = freeze i1024 %chosen
 %other = getelementptr i8,ptr %out,i64 128
 store i1024 %defined,ptr %other,align 1
 %first = trunc i1024 %roundtrip to i64
 %second = trunc i1024 %defined to i64
 %mix = xor i64 %first,%second
 %flag = zext i1 %condition to i64
 %initial = xor i64 %mix,%flag
 %m0 = mul i64 %initial,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 256
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 264
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 272
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_123(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 48
 %answer = call i64 @memory_limbs_body_123(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define i64 @memory_limbs_body_124(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i1024,ptr %input,align 1
 %yp = getelementptr i1024,ptr %input,i64 1
 %y = load i1024,ptr %yp,align 1
 %condition = icmp ule i1024 %x,%y
 %selected = select i1 %condition,i1024 %x,i1024 %y
 %slot = alloca i1024,align 16
 store i1024 %selected,ptr %slot,align 16
 %slot0 = getelementptr i1024,ptr %slot,i64 0
 %roundtrip = load i1024,ptr %slot0,align 16
 store i1024 %roundtrip,ptr %out,align 1
 br i1 %condition,label %left,label %right
left:
 br label %join
right:
 br label %join
join:
 %chosen = phi i1024 [%y,%left],[%x,%right]
 %defined = freeze i1024 %chosen
 %other = getelementptr i8,ptr %out,i64 128
 store i1024 %defined,ptr %other,align 1
 %first = trunc i1024 %roundtrip to i64
 %second = trunc i1024 %defined to i64
 %mix = xor i64 %first,%second
 %flag = zext i1 %condition to i64
 %initial = xor i64 %mix,%flag
 %m0 = mul i64 %initial,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 256
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 264
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 272
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_124(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 48
 %answer = call i64 @memory_limbs_body_124(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define i64 @memory_limbs_body_125(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i1024,ptr %input,align 1
 %yp = getelementptr i1024,ptr %input,i64 1
 %y = load i1024,ptr %yp,align 1
 %condition = icmp ugt i1024 %x,%y
 %selected = select i1 %condition,i1024 %x,i1024 %y
 %slot = alloca i1024,align 16
 store i1024 %selected,ptr %slot,align 16
 %slot0 = getelementptr i1024,ptr %slot,i64 0
 %roundtrip = load i1024,ptr %slot0,align 16
 store i1024 %roundtrip,ptr %out,align 1
 br i1 %condition,label %left,label %right
left:
 br label %join
right:
 br label %join
join:
 %chosen = phi i1024 [%y,%left],[%x,%right]
 %defined = freeze i1024 %chosen
 %other = getelementptr i8,ptr %out,i64 128
 store i1024 %defined,ptr %other,align 1
 %first = trunc i1024 %roundtrip to i64
 %second = trunc i1024 %defined to i64
 %mix = xor i64 %first,%second
 %flag = zext i1 %condition to i64
 %initial = xor i64 %mix,%flag
 %m0 = mul i64 %initial,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 256
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 264
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 272
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_125(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 48
 %answer = call i64 @memory_limbs_body_125(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define i64 @memory_limbs_body_126(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i1024,ptr %input,align 1
 %yp = getelementptr i1024,ptr %input,i64 1
 %y = load i1024,ptr %yp,align 1
 %condition = icmp uge i1024 %x,%y
 %selected = select i1 %condition,i1024 %x,i1024 %y
 %slot = alloca i1024,align 16
 store i1024 %selected,ptr %slot,align 16
 %slot0 = getelementptr i1024,ptr %slot,i64 0
 %roundtrip = load i1024,ptr %slot0,align 16
 store i1024 %roundtrip,ptr %out,align 1
 br i1 %condition,label %left,label %right
left:
 br label %join
right:
 br label %join
join:
 %chosen = phi i1024 [%y,%left],[%x,%right]
 %defined = freeze i1024 %chosen
 %other = getelementptr i8,ptr %out,i64 128
 store i1024 %defined,ptr %other,align 1
 %first = trunc i1024 %roundtrip to i64
 %second = trunc i1024 %defined to i64
 %mix = xor i64 %first,%second
 %flag = zext i1 %condition to i64
 %initial = xor i64 %mix,%flag
 %m0 = mul i64 %initial,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 256
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 264
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 272
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_126(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 48
 %answer = call i64 @memory_limbs_body_126(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define i64 @memory_limbs_body_127(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i1024,ptr %input,align 1
 %yp = getelementptr i1024,ptr %input,i64 1
 %y = load i1024,ptr %yp,align 1
 %condition = icmp slt i1024 %x,%y
 %selected = select i1 %condition,i1024 %x,i1024 %y
 %slot = alloca i1024,align 16
 store i1024 %selected,ptr %slot,align 16
 %slot0 = getelementptr i1024,ptr %slot,i64 0
 %roundtrip = load i1024,ptr %slot0,align 16
 store i1024 %roundtrip,ptr %out,align 1
 br i1 %condition,label %left,label %right
left:
 br label %join
right:
 br label %join
join:
 %chosen = phi i1024 [%y,%left],[%x,%right]
 %defined = freeze i1024 %chosen
 %other = getelementptr i8,ptr %out,i64 128
 store i1024 %defined,ptr %other,align 1
 %first = trunc i1024 %roundtrip to i64
 %second = trunc i1024 %defined to i64
 %mix = xor i64 %first,%second
 %flag = zext i1 %condition to i64
 %initial = xor i64 %mix,%flag
 %m0 = mul i64 %initial,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 256
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 264
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 272
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_127(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 48
 %answer = call i64 @memory_limbs_body_127(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define i64 @memory_limbs_body_128(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i1024,ptr %input,align 1
 %yp = getelementptr i1024,ptr %input,i64 1
 %y = load i1024,ptr %yp,align 1
 %condition = icmp sle i1024 %x,%y
 %selected = select i1 %condition,i1024 %x,i1024 %y
 %slot = alloca i1024,align 16
 store i1024 %selected,ptr %slot,align 16
 %slot0 = getelementptr i1024,ptr %slot,i64 0
 %roundtrip = load i1024,ptr %slot0,align 16
 store i1024 %roundtrip,ptr %out,align 1
 br i1 %condition,label %left,label %right
left:
 br label %join
right:
 br label %join
join:
 %chosen = phi i1024 [%y,%left],[%x,%right]
 %defined = freeze i1024 %chosen
 %other = getelementptr i8,ptr %out,i64 128
 store i1024 %defined,ptr %other,align 1
 %first = trunc i1024 %roundtrip to i64
 %second = trunc i1024 %defined to i64
 %mix = xor i64 %first,%second
 %flag = zext i1 %condition to i64
 %initial = xor i64 %mix,%flag
 %m0 = mul i64 %initial,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 256
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 264
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 272
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_128(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 48
 %answer = call i64 @memory_limbs_body_128(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define i64 @memory_limbs_body_129(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i1024,ptr %input,align 1
 %yp = getelementptr i1024,ptr %input,i64 1
 %y = load i1024,ptr %yp,align 1
 %condition = icmp sgt i1024 %x,%y
 %selected = select i1 %condition,i1024 %x,i1024 %y
 %slot = alloca i1024,align 16
 store i1024 %selected,ptr %slot,align 16
 %slot0 = getelementptr i1024,ptr %slot,i64 0
 %roundtrip = load i1024,ptr %slot0,align 16
 store i1024 %roundtrip,ptr %out,align 1
 br i1 %condition,label %left,label %right
left:
 br label %join
right:
 br label %join
join:
 %chosen = phi i1024 [%y,%left],[%x,%right]
 %defined = freeze i1024 %chosen
 %other = getelementptr i8,ptr %out,i64 128
 store i1024 %defined,ptr %other,align 1
 %first = trunc i1024 %roundtrip to i64
 %second = trunc i1024 %defined to i64
 %mix = xor i64 %first,%second
 %flag = zext i1 %condition to i64
 %initial = xor i64 %mix,%flag
 %m0 = mul i64 %initial,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 256
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 264
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 272
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_129(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 48
 %answer = call i64 @memory_limbs_body_129(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define i64 @memory_limbs_body_130(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i1024,ptr %input,align 1
 %yp = getelementptr i1024,ptr %input,i64 1
 %y = load i1024,ptr %yp,align 1
 %condition = icmp sge i1024 %x,%y
 %selected = select i1 %condition,i1024 %x,i1024 %y
 %slot = alloca i1024,align 16
 store i1024 %selected,ptr %slot,align 16
 %slot0 = getelementptr i1024,ptr %slot,i64 0
 %roundtrip = load i1024,ptr %slot0,align 16
 store i1024 %roundtrip,ptr %out,align 1
 br i1 %condition,label %left,label %right
left:
 br label %join
right:
 br label %join
join:
 %chosen = phi i1024 [%y,%left],[%x,%right]
 %defined = freeze i1024 %chosen
 %other = getelementptr i8,ptr %out,i64 128
 store i1024 %defined,ptr %other,align 1
 %first = trunc i1024 %roundtrip to i64
 %second = trunc i1024 %defined to i64
 %mix = xor i64 %first,%second
 %flag = zext i1 %condition to i64
 %initial = xor i64 %mix,%flag
 %m0 = mul i64 %initial,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 256
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 264
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 272
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_130(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 48
 %answer = call i64 @memory_limbs_body_130(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define i64 @memory_limbs_body_131(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 store i1024 0,ptr %out,align 1
 %value = load i1024,ptr %out,align 1
 store i1024 %value,ptr %out,align 1
 %low = trunc i1024 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 128
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 136
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 144
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_131(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 176
 %answer = call i64 @memory_limbs_body_131(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define i64 @memory_limbs_body_132(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 store i1024 -1,ptr %out,align 1
 %value = load i1024,ptr %out,align 1
 store i1024 %value,ptr %out,align 1
 %low = trunc i1024 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 128
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 136
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 144
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_132(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 176
 %answer = call i64 @memory_limbs_body_132(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define i64 @memory_limbs_body_133(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 store i1024 -89884656743115795386465259539451236680898848947115328636715040578866337902750481566354238661203768010560056939935696678829394884407208311246423715319737062188883946712432742638151109800623047059726541476042502884419075341171231440736956555270413618581675255342293149119973622969239858152417678164812112068608,ptr %out,align 1
 %value = load i1024,ptr %out,align 1
 store i1024 %value,ptr %out,align 1
 %low = trunc i1024 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 128
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 136
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 144
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_133(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 176
 %answer = call i64 @memory_limbs_body_133(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define i64 @memory_limbs_body_134(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 store i1024 89884656743115795386465259539451236680898848947115328636715040578866337902750481566354238661203768010560056939935696678829394884407208311246423715319737062188883946712432742638151109800623047059726541476042502884419075341171231440736956555270413618581675255342293149119973622969239858152417678164812112068607,ptr %out,align 1
 %value = load i1024,ptr %out,align 1
 store i1024 %value,ptr %out,align 1
 %low = trunc i1024 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 128
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 136
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 144
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_134(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 176
 %answer = call i64 @memory_limbs_body_134(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define i64 @memory_limbs_body_135(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i1024,ptr %input,align 1
 %value = trunc i1024 %x to i8
 store i8 %value,ptr %out,align 1
 %low = zext i8 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 1
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 9
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 17
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_135(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 176
 %answer = call i64 @memory_limbs_body_135(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define i64 @memory_limbs_body_136(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i8,ptr %input,align 1
 %value = zext i8 %x to i1024
 store i1024 %value,ptr %out,align 1
 %low = trunc i1024 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 128
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 136
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 144
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_136(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 64
 %answer = call i64 @memory_limbs_body_136(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define i64 @memory_limbs_body_137(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i8,ptr %input,align 1
 %value = sext i8 %x to i1024
 store i1024 %value,ptr %out,align 1
 %low = trunc i1024 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 128
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 136
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 144
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_137(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 64
 %answer = call i64 @memory_limbs_body_137(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define i64 @memory_limbs_body_138(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i1024,ptr %input,align 1
 %value = trunc i1024 %x to i16
 store i16 %value,ptr %out,align 1
 %low = zext i16 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 2
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 10
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 18
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_138(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 176
 %answer = call i64 @memory_limbs_body_138(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define i64 @memory_limbs_body_139(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i16,ptr %input,align 1
 %value = zext i16 %x to i1024
 store i1024 %value,ptr %out,align 1
 %low = trunc i1024 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 128
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 136
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 144
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_139(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 64
 %answer = call i64 @memory_limbs_body_139(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define i64 @memory_limbs_body_140(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i16,ptr %input,align 1
 %value = sext i16 %x to i1024
 store i1024 %value,ptr %out,align 1
 %low = trunc i1024 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 128
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 136
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 144
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_140(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 64
 %answer = call i64 @memory_limbs_body_140(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define i64 @memory_limbs_body_141(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i1024,ptr %input,align 1
 %value = trunc i1024 %x to i32
 store i32 %value,ptr %out,align 1
 %low = zext i32 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 4
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 12
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 20
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_141(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 176
 %answer = call i64 @memory_limbs_body_141(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define i64 @memory_limbs_body_142(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i32,ptr %input,align 1
 %value = zext i32 %x to i1024
 store i1024 %value,ptr %out,align 1
 %low = trunc i1024 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 128
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 136
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 144
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_142(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 64
 %answer = call i64 @memory_limbs_body_142(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define i64 @memory_limbs_body_143(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i32,ptr %input,align 1
 %value = sext i32 %x to i1024
 store i1024 %value,ptr %out,align 1
 %low = trunc i1024 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 128
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 136
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 144
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_143(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 64
 %answer = call i64 @memory_limbs_body_143(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define i64 @memory_limbs_body_144(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i1024,ptr %input,align 1
 %value = trunc i1024 %x to i64
 store i64 %value,ptr %out,align 1
 %m0 = mul i64 %value,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 8
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 16
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 24
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_144(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 176
 %answer = call i64 @memory_limbs_body_144(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define i64 @memory_limbs_body_145(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i64,ptr %input,align 1
 %value = zext i64 %x to i1024
 store i1024 %value,ptr %out,align 1
 %low = trunc i1024 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 128
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 136
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 144
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_145(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 64
 %answer = call i64 @memory_limbs_body_145(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define i64 @memory_limbs_body_146(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i64,ptr %input,align 1
 %value = sext i64 %x to i1024
 store i1024 %value,ptr %out,align 1
 %low = trunc i1024 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 128
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 136
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 144
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_146(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 64
 %answer = call i64 @memory_limbs_body_146(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define i64 @memory_limbs_body_147(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i1024,ptr %input,align 1
 %value = trunc i1024 %x to i128
 store i128 %value,ptr %out,align 1
 %low = trunc i128 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 16
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 24
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 32
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_147(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 176
 %answer = call i64 @memory_limbs_body_147(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define i64 @memory_limbs_body_148(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i128,ptr %input,align 1
 %value = zext i128 %x to i1024
 store i1024 %value,ptr %out,align 1
 %low = trunc i1024 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 128
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 136
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 144
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_148(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 64
 %answer = call i64 @memory_limbs_body_148(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define i64 @memory_limbs_body_149(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i128,ptr %input,align 1
 %value = sext i128 %x to i1024
 store i1024 %value,ptr %out,align 1
 %low = trunc i1024 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 128
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 136
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 144
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_149(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 64
 %answer = call i64 @memory_limbs_body_149(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define fastcc i64 @memory_limbs_body_150(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i1024,ptr %input,align 1
 %value = freeze i1024 %x
 store i1024 %value,ptr %out,align 1
 %low = trunc i1024 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 128
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 136
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 144
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_150(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 176
 %answer = call fastcc i64 @memory_limbs_body_150(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define fastcc i64 @memory_limbs_body_151(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i1024,ptr %input,align 1
 %yp = getelementptr i1024,ptr %input,i64 1
 %y = load i1024,ptr %yp,align 1
 %condition = icmp eq i1024 %x,%y
 %selected = select i1 %condition,i1024 %x,i1024 %y
 %slot = alloca i1024,align 16
 store i1024 %selected,ptr %slot,align 16
 %slot0 = getelementptr i1024,ptr %slot,i64 0
 %roundtrip = load i1024,ptr %slot0,align 16
 store i1024 %roundtrip,ptr %out,align 1
 br i1 %condition,label %left,label %right
left:
 br label %join
right:
 br label %join
join:
 %chosen = phi i1024 [%y,%left],[%x,%right]
 %defined = freeze i1024 %chosen
 %other = getelementptr i8,ptr %out,i64 128
 store i1024 %defined,ptr %other,align 1
 %first = trunc i1024 %roundtrip to i64
 %second = trunc i1024 %defined to i64
 %mix = xor i64 %first,%second
 %flag = zext i1 %condition to i64
 %initial = xor i64 %mix,%flag
 %m0 = mul i64 %initial,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 256
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 264
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 272
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_151(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 48
 %answer = call fastcc i64 @memory_limbs_body_151(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define fastcc i64 @memory_limbs_body_152(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i1024,ptr %input,align 1
 %yp = getelementptr i1024,ptr %input,i64 1
 %y = load i1024,ptr %yp,align 1
 %condition = icmp ne i1024 %x,%y
 %selected = select i1 %condition,i1024 %x,i1024 %y
 %slot = alloca i1024,align 16
 store i1024 %selected,ptr %slot,align 16
 %slot0 = getelementptr i1024,ptr %slot,i64 0
 %roundtrip = load i1024,ptr %slot0,align 16
 store i1024 %roundtrip,ptr %out,align 1
 br i1 %condition,label %left,label %right
left:
 br label %join
right:
 br label %join
join:
 %chosen = phi i1024 [%y,%left],[%x,%right]
 %defined = freeze i1024 %chosen
 %other = getelementptr i8,ptr %out,i64 128
 store i1024 %defined,ptr %other,align 1
 %first = trunc i1024 %roundtrip to i64
 %second = trunc i1024 %defined to i64
 %mix = xor i64 %first,%second
 %flag = zext i1 %condition to i64
 %initial = xor i64 %mix,%flag
 %m0 = mul i64 %initial,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 256
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 264
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 272
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_152(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 48
 %answer = call fastcc i64 @memory_limbs_body_152(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define fastcc i64 @memory_limbs_body_153(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i1024,ptr %input,align 1
 %yp = getelementptr i1024,ptr %input,i64 1
 %y = load i1024,ptr %yp,align 1
 %condition = icmp ult i1024 %x,%y
 %selected = select i1 %condition,i1024 %x,i1024 %y
 %slot = alloca i1024,align 16
 store i1024 %selected,ptr %slot,align 16
 %slot0 = getelementptr i1024,ptr %slot,i64 0
 %roundtrip = load i1024,ptr %slot0,align 16
 store i1024 %roundtrip,ptr %out,align 1
 br i1 %condition,label %left,label %right
left:
 br label %join
right:
 br label %join
join:
 %chosen = phi i1024 [%y,%left],[%x,%right]
 %defined = freeze i1024 %chosen
 %other = getelementptr i8,ptr %out,i64 128
 store i1024 %defined,ptr %other,align 1
 %first = trunc i1024 %roundtrip to i64
 %second = trunc i1024 %defined to i64
 %mix = xor i64 %first,%second
 %flag = zext i1 %condition to i64
 %initial = xor i64 %mix,%flag
 %m0 = mul i64 %initial,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 256
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 264
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 272
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_153(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 48
 %answer = call fastcc i64 @memory_limbs_body_153(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define fastcc i64 @memory_limbs_body_154(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i1024,ptr %input,align 1
 %yp = getelementptr i1024,ptr %input,i64 1
 %y = load i1024,ptr %yp,align 1
 %condition = icmp ule i1024 %x,%y
 %selected = select i1 %condition,i1024 %x,i1024 %y
 %slot = alloca i1024,align 16
 store i1024 %selected,ptr %slot,align 16
 %slot0 = getelementptr i1024,ptr %slot,i64 0
 %roundtrip = load i1024,ptr %slot0,align 16
 store i1024 %roundtrip,ptr %out,align 1
 br i1 %condition,label %left,label %right
left:
 br label %join
right:
 br label %join
join:
 %chosen = phi i1024 [%y,%left],[%x,%right]
 %defined = freeze i1024 %chosen
 %other = getelementptr i8,ptr %out,i64 128
 store i1024 %defined,ptr %other,align 1
 %first = trunc i1024 %roundtrip to i64
 %second = trunc i1024 %defined to i64
 %mix = xor i64 %first,%second
 %flag = zext i1 %condition to i64
 %initial = xor i64 %mix,%flag
 %m0 = mul i64 %initial,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 256
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 264
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 272
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_154(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 48
 %answer = call fastcc i64 @memory_limbs_body_154(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define fastcc i64 @memory_limbs_body_155(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i1024,ptr %input,align 1
 %yp = getelementptr i1024,ptr %input,i64 1
 %y = load i1024,ptr %yp,align 1
 %condition = icmp ugt i1024 %x,%y
 %selected = select i1 %condition,i1024 %x,i1024 %y
 %slot = alloca i1024,align 16
 store i1024 %selected,ptr %slot,align 16
 %slot0 = getelementptr i1024,ptr %slot,i64 0
 %roundtrip = load i1024,ptr %slot0,align 16
 store i1024 %roundtrip,ptr %out,align 1
 br i1 %condition,label %left,label %right
left:
 br label %join
right:
 br label %join
join:
 %chosen = phi i1024 [%y,%left],[%x,%right]
 %defined = freeze i1024 %chosen
 %other = getelementptr i8,ptr %out,i64 128
 store i1024 %defined,ptr %other,align 1
 %first = trunc i1024 %roundtrip to i64
 %second = trunc i1024 %defined to i64
 %mix = xor i64 %first,%second
 %flag = zext i1 %condition to i64
 %initial = xor i64 %mix,%flag
 %m0 = mul i64 %initial,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 256
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 264
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 272
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_155(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 48
 %answer = call fastcc i64 @memory_limbs_body_155(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define fastcc i64 @memory_limbs_body_156(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i1024,ptr %input,align 1
 %yp = getelementptr i1024,ptr %input,i64 1
 %y = load i1024,ptr %yp,align 1
 %condition = icmp uge i1024 %x,%y
 %selected = select i1 %condition,i1024 %x,i1024 %y
 %slot = alloca i1024,align 16
 store i1024 %selected,ptr %slot,align 16
 %slot0 = getelementptr i1024,ptr %slot,i64 0
 %roundtrip = load i1024,ptr %slot0,align 16
 store i1024 %roundtrip,ptr %out,align 1
 br i1 %condition,label %left,label %right
left:
 br label %join
right:
 br label %join
join:
 %chosen = phi i1024 [%y,%left],[%x,%right]
 %defined = freeze i1024 %chosen
 %other = getelementptr i8,ptr %out,i64 128
 store i1024 %defined,ptr %other,align 1
 %first = trunc i1024 %roundtrip to i64
 %second = trunc i1024 %defined to i64
 %mix = xor i64 %first,%second
 %flag = zext i1 %condition to i64
 %initial = xor i64 %mix,%flag
 %m0 = mul i64 %initial,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 256
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 264
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 272
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_156(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 48
 %answer = call fastcc i64 @memory_limbs_body_156(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define fastcc i64 @memory_limbs_body_157(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i1024,ptr %input,align 1
 %yp = getelementptr i1024,ptr %input,i64 1
 %y = load i1024,ptr %yp,align 1
 %condition = icmp slt i1024 %x,%y
 %selected = select i1 %condition,i1024 %x,i1024 %y
 %slot = alloca i1024,align 16
 store i1024 %selected,ptr %slot,align 16
 %slot0 = getelementptr i1024,ptr %slot,i64 0
 %roundtrip = load i1024,ptr %slot0,align 16
 store i1024 %roundtrip,ptr %out,align 1
 br i1 %condition,label %left,label %right
left:
 br label %join
right:
 br label %join
join:
 %chosen = phi i1024 [%y,%left],[%x,%right]
 %defined = freeze i1024 %chosen
 %other = getelementptr i8,ptr %out,i64 128
 store i1024 %defined,ptr %other,align 1
 %first = trunc i1024 %roundtrip to i64
 %second = trunc i1024 %defined to i64
 %mix = xor i64 %first,%second
 %flag = zext i1 %condition to i64
 %initial = xor i64 %mix,%flag
 %m0 = mul i64 %initial,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 256
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 264
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 272
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_157(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 48
 %answer = call fastcc i64 @memory_limbs_body_157(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define fastcc i64 @memory_limbs_body_158(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i1024,ptr %input,align 1
 %yp = getelementptr i1024,ptr %input,i64 1
 %y = load i1024,ptr %yp,align 1
 %condition = icmp sle i1024 %x,%y
 %selected = select i1 %condition,i1024 %x,i1024 %y
 %slot = alloca i1024,align 16
 store i1024 %selected,ptr %slot,align 16
 %slot0 = getelementptr i1024,ptr %slot,i64 0
 %roundtrip = load i1024,ptr %slot0,align 16
 store i1024 %roundtrip,ptr %out,align 1
 br i1 %condition,label %left,label %right
left:
 br label %join
right:
 br label %join
join:
 %chosen = phi i1024 [%y,%left],[%x,%right]
 %defined = freeze i1024 %chosen
 %other = getelementptr i8,ptr %out,i64 128
 store i1024 %defined,ptr %other,align 1
 %first = trunc i1024 %roundtrip to i64
 %second = trunc i1024 %defined to i64
 %mix = xor i64 %first,%second
 %flag = zext i1 %condition to i64
 %initial = xor i64 %mix,%flag
 %m0 = mul i64 %initial,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 256
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 264
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 272
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_158(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 48
 %answer = call fastcc i64 @memory_limbs_body_158(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define fastcc i64 @memory_limbs_body_159(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i1024,ptr %input,align 1
 %yp = getelementptr i1024,ptr %input,i64 1
 %y = load i1024,ptr %yp,align 1
 %condition = icmp sgt i1024 %x,%y
 %selected = select i1 %condition,i1024 %x,i1024 %y
 %slot = alloca i1024,align 16
 store i1024 %selected,ptr %slot,align 16
 %slot0 = getelementptr i1024,ptr %slot,i64 0
 %roundtrip = load i1024,ptr %slot0,align 16
 store i1024 %roundtrip,ptr %out,align 1
 br i1 %condition,label %left,label %right
left:
 br label %join
right:
 br label %join
join:
 %chosen = phi i1024 [%y,%left],[%x,%right]
 %defined = freeze i1024 %chosen
 %other = getelementptr i8,ptr %out,i64 128
 store i1024 %defined,ptr %other,align 1
 %first = trunc i1024 %roundtrip to i64
 %second = trunc i1024 %defined to i64
 %mix = xor i64 %first,%second
 %flag = zext i1 %condition to i64
 %initial = xor i64 %mix,%flag
 %m0 = mul i64 %initial,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 256
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 264
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 272
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_159(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 48
 %answer = call fastcc i64 @memory_limbs_body_159(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define fastcc i64 @memory_limbs_body_160(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i1024,ptr %input,align 1
 %yp = getelementptr i1024,ptr %input,i64 1
 %y = load i1024,ptr %yp,align 1
 %condition = icmp sge i1024 %x,%y
 %selected = select i1 %condition,i1024 %x,i1024 %y
 %slot = alloca i1024,align 16
 store i1024 %selected,ptr %slot,align 16
 %slot0 = getelementptr i1024,ptr %slot,i64 0
 %roundtrip = load i1024,ptr %slot0,align 16
 store i1024 %roundtrip,ptr %out,align 1
 br i1 %condition,label %left,label %right
left:
 br label %join
right:
 br label %join
join:
 %chosen = phi i1024 [%y,%left],[%x,%right]
 %defined = freeze i1024 %chosen
 %other = getelementptr i8,ptr %out,i64 128
 store i1024 %defined,ptr %other,align 1
 %first = trunc i1024 %roundtrip to i64
 %second = trunc i1024 %defined to i64
 %mix = xor i64 %first,%second
 %flag = zext i1 %condition to i64
 %initial = xor i64 %mix,%flag
 %m0 = mul i64 %initial,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 256
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 264
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 272
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_160(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 48
 %answer = call fastcc i64 @memory_limbs_body_160(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define fastcc i64 @memory_limbs_body_161(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 store i1024 0,ptr %out,align 1
 %value = load i1024,ptr %out,align 1
 store i1024 %value,ptr %out,align 1
 %low = trunc i1024 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 128
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 136
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 144
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_161(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 176
 %answer = call fastcc i64 @memory_limbs_body_161(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define fastcc i64 @memory_limbs_body_162(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 store i1024 -1,ptr %out,align 1
 %value = load i1024,ptr %out,align 1
 store i1024 %value,ptr %out,align 1
 %low = trunc i1024 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 128
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 136
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 144
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_162(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 176
 %answer = call fastcc i64 @memory_limbs_body_162(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define fastcc i64 @memory_limbs_body_163(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 store i1024 -89884656743115795386465259539451236680898848947115328636715040578866337902750481566354238661203768010560056939935696678829394884407208311246423715319737062188883946712432742638151109800623047059726541476042502884419075341171231440736956555270413618581675255342293149119973622969239858152417678164812112068608,ptr %out,align 1
 %value = load i1024,ptr %out,align 1
 store i1024 %value,ptr %out,align 1
 %low = trunc i1024 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 128
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 136
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 144
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_163(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 176
 %answer = call fastcc i64 @memory_limbs_body_163(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define fastcc i64 @memory_limbs_body_164(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 store i1024 89884656743115795386465259539451236680898848947115328636715040578866337902750481566354238661203768010560056939935696678829394884407208311246423715319737062188883946712432742638151109800623047059726541476042502884419075341171231440736956555270413618581675255342293149119973622969239858152417678164812112068607,ptr %out,align 1
 %value = load i1024,ptr %out,align 1
 store i1024 %value,ptr %out,align 1
 %low = trunc i1024 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 128
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 136
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 144
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_164(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 176
 %answer = call fastcc i64 @memory_limbs_body_164(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define fastcc i64 @memory_limbs_body_165(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i1024,ptr %input,align 1
 %value = trunc i1024 %x to i8
 store i8 %value,ptr %out,align 1
 %low = zext i8 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 1
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 9
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 17
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_165(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 176
 %answer = call fastcc i64 @memory_limbs_body_165(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define fastcc i64 @memory_limbs_body_166(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i8,ptr %input,align 1
 %value = zext i8 %x to i1024
 store i1024 %value,ptr %out,align 1
 %low = trunc i1024 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 128
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 136
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 144
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_166(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 64
 %answer = call fastcc i64 @memory_limbs_body_166(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define fastcc i64 @memory_limbs_body_167(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i8,ptr %input,align 1
 %value = sext i8 %x to i1024
 store i1024 %value,ptr %out,align 1
 %low = trunc i1024 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 128
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 136
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 144
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_167(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 64
 %answer = call fastcc i64 @memory_limbs_body_167(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define fastcc i64 @memory_limbs_body_168(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i1024,ptr %input,align 1
 %value = trunc i1024 %x to i16
 store i16 %value,ptr %out,align 1
 %low = zext i16 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 2
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 10
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 18
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_168(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 176
 %answer = call fastcc i64 @memory_limbs_body_168(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define fastcc i64 @memory_limbs_body_169(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i16,ptr %input,align 1
 %value = zext i16 %x to i1024
 store i1024 %value,ptr %out,align 1
 %low = trunc i1024 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 128
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 136
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 144
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_169(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 64
 %answer = call fastcc i64 @memory_limbs_body_169(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define fastcc i64 @memory_limbs_body_170(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i16,ptr %input,align 1
 %value = sext i16 %x to i1024
 store i1024 %value,ptr %out,align 1
 %low = trunc i1024 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 128
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 136
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 144
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_170(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 64
 %answer = call fastcc i64 @memory_limbs_body_170(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define fastcc i64 @memory_limbs_body_171(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i1024,ptr %input,align 1
 %value = trunc i1024 %x to i32
 store i32 %value,ptr %out,align 1
 %low = zext i32 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 4
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 12
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 20
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_171(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 176
 %answer = call fastcc i64 @memory_limbs_body_171(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define fastcc i64 @memory_limbs_body_172(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i32,ptr %input,align 1
 %value = zext i32 %x to i1024
 store i1024 %value,ptr %out,align 1
 %low = trunc i1024 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 128
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 136
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 144
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_172(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 64
 %answer = call fastcc i64 @memory_limbs_body_172(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define fastcc i64 @memory_limbs_body_173(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i32,ptr %input,align 1
 %value = sext i32 %x to i1024
 store i1024 %value,ptr %out,align 1
 %low = trunc i1024 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 128
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 136
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 144
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_173(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 64
 %answer = call fastcc i64 @memory_limbs_body_173(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define fastcc i64 @memory_limbs_body_174(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i1024,ptr %input,align 1
 %value = trunc i1024 %x to i64
 store i64 %value,ptr %out,align 1
 %m0 = mul i64 %value,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 8
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 16
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 24
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_174(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 176
 %answer = call fastcc i64 @memory_limbs_body_174(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define fastcc i64 @memory_limbs_body_175(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i64,ptr %input,align 1
 %value = zext i64 %x to i1024
 store i1024 %value,ptr %out,align 1
 %low = trunc i1024 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 128
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 136
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 144
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_175(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 64
 %answer = call fastcc i64 @memory_limbs_body_175(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define fastcc i64 @memory_limbs_body_176(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i64,ptr %input,align 1
 %value = sext i64 %x to i1024
 store i1024 %value,ptr %out,align 1
 %low = trunc i1024 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 128
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 136
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 144
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_176(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 64
 %answer = call fastcc i64 @memory_limbs_body_176(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define fastcc i64 @memory_limbs_body_177(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i1024,ptr %input,align 1
 %value = trunc i1024 %x to i128
 store i128 %value,ptr %out,align 1
 %low = trunc i128 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 16
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 24
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 32
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_177(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 176
 %answer = call fastcc i64 @memory_limbs_body_177(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define fastcc i64 @memory_limbs_body_178(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i128,ptr %input,align 1
 %value = zext i128 %x to i1024
 store i1024 %value,ptr %out,align 1
 %low = trunc i1024 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 128
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 136
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 144
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_178(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 64
 %answer = call fastcc i64 @memory_limbs_body_178(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define fastcc i64 @memory_limbs_body_179(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i128,ptr %input,align 1
 %value = sext i128 %x to i1024
 store i1024 %value,ptr %out,align 1
 %low = trunc i1024 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 128
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 136
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 144
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_179(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 64
 %answer = call fastcc i64 @memory_limbs_body_179(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define i64 @memory_limbs_body_180(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i800,ptr %input,align 1
 %value = zext i800 %x to i896
 store i896 %value,ptr %out,align 1
 %low = trunc i896 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 112
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 120
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 128
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_180(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 160
 %answer = call i64 @memory_limbs_body_180(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define i64 @memory_limbs_body_181(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i800,ptr %input,align 1
 %value = sext i800 %x to i896
 store i896 %value,ptr %out,align 1
 %low = trunc i896 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 112
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 120
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 128
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_181(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 160
 %answer = call i64 @memory_limbs_body_181(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define i64 @memory_limbs_body_182(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i896,ptr %input,align 1
 %value = trunc i896 %x to i800
 store i800 %value,ptr %out,align 1
 %low = trunc i800 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 100
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 108
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 116
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_182(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 160
 %answer = call i64 @memory_limbs_body_182(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define fastcc i64 @memory_limbs_body_183(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i800,ptr %input,align 1
 %value = zext i800 %x to i896
 store i896 %value,ptr %out,align 1
 %low = trunc i896 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 112
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 120
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 128
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_183(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 160
 %answer = call fastcc i64 @memory_limbs_body_183(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define fastcc i64 @memory_limbs_body_184(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i800,ptr %input,align 1
 %value = sext i800 %x to i896
 store i896 %value,ptr %out,align 1
 %low = trunc i896 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 112
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 120
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 128
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_184(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 160
 %answer = call fastcc i64 @memory_limbs_body_184(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define fastcc i64 @memory_limbs_body_185(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i896,ptr %input,align 1
 %value = trunc i896 %x to i800
 store i800 %value,ptr %out,align 1
 %low = trunc i800 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 100
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 108
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 116
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_185(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 160
 %answer = call fastcc i64 @memory_limbs_body_185(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define i64 @memory_limbs_body_186(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i800,ptr %input,align 1
 %value = zext i800 %x to i1024
 store i1024 %value,ptr %out,align 1
 %low = trunc i1024 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 128
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 136
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 144
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_186(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 160
 %answer = call i64 @memory_limbs_body_186(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define i64 @memory_limbs_body_187(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i800,ptr %input,align 1
 %value = sext i800 %x to i1024
 store i1024 %value,ptr %out,align 1
 %low = trunc i1024 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 128
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 136
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 144
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_187(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 160
 %answer = call i64 @memory_limbs_body_187(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define i64 @memory_limbs_body_188(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i1024,ptr %input,align 1
 %value = trunc i1024 %x to i800
 store i800 %value,ptr %out,align 1
 %low = trunc i800 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 100
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 108
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 116
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_188(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 176
 %answer = call i64 @memory_limbs_body_188(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define fastcc i64 @memory_limbs_body_189(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i800,ptr %input,align 1
 %value = zext i800 %x to i1024
 store i1024 %value,ptr %out,align 1
 %low = trunc i1024 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 128
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 136
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 144
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_189(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 160
 %answer = call fastcc i64 @memory_limbs_body_189(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define fastcc i64 @memory_limbs_body_190(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i800,ptr %input,align 1
 %value = sext i800 %x to i1024
 store i1024 %value,ptr %out,align 1
 %low = trunc i1024 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 128
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 136
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 144
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_190(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 160
 %answer = call fastcc i64 @memory_limbs_body_190(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define fastcc i64 @memory_limbs_body_191(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i1024,ptr %input,align 1
 %value = trunc i1024 %x to i800
 store i800 %value,ptr %out,align 1
 %low = trunc i800 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 100
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 108
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 116
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_191(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 176
 %answer = call fastcc i64 @memory_limbs_body_191(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define i64 @memory_limbs_body_192(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i896,ptr %input,align 1
 %value = zext i896 %x to i1024
 store i1024 %value,ptr %out,align 1
 %low = trunc i1024 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 128
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 136
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 144
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_192(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 160
 %answer = call i64 @memory_limbs_body_192(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define i64 @memory_limbs_body_193(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i896,ptr %input,align 1
 %value = sext i896 %x to i1024
 store i1024 %value,ptr %out,align 1
 %low = trunc i1024 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 128
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 136
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 144
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_193(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 160
 %answer = call i64 @memory_limbs_body_193(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define i64 @memory_limbs_body_194(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i1024,ptr %input,align 1
 %value = trunc i1024 %x to i896
 store i896 %value,ptr %out,align 1
 %low = trunc i896 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 112
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 120
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 128
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_194(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 176
 %answer = call i64 @memory_limbs_body_194(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define fastcc i64 @memory_limbs_body_195(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i896,ptr %input,align 1
 %value = zext i896 %x to i1024
 store i1024 %value,ptr %out,align 1
 %low = trunc i1024 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 128
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 136
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 144
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_195(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 160
 %answer = call fastcc i64 @memory_limbs_body_195(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define fastcc i64 @memory_limbs_body_196(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i896,ptr %input,align 1
 %value = sext i896 %x to i1024
 store i1024 %value,ptr %out,align 1
 %low = trunc i1024 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 128
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 136
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 144
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_196(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 160
 %answer = call fastcc i64 @memory_limbs_body_196(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
define fastcc i64 @memory_limbs_body_197(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %input,ptr %out,i64 %salt) noinline {
entry:
 %x = load i1024,ptr %input,align 1
 %value = trunc i1024 %x to i896
 store i896 %value,ptr %out,align 1
 %low = trunc i896 %value to i64
 %m0 = mul i64 %low,1099511628211
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
 %record0 = getelementptr i8,ptr %out,i64 112
 store i64 %r5,ptr %record0,align 1
 %record1 = getelementptr i8,ptr %out,i64 120
 store i64 %salt,ptr %record1,align 1
 %record2 = getelementptr i8,ptr %out,i64 128
 store i64 %p0,ptr %record2,align 1
 %result = xor i64 %r5,%salt
 ret i64 %result
}
define i64 @memory_limbs_probe_197(ptr %input,ptr %out,i64 %salt) {
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
 %xp = getelementptr i8,ptr %input,i64 176
 %answer = call fastcc i64 @memory_limbs_body_197(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %xp,ptr %out,i64 %salt)
 ret i64 %answer
}
