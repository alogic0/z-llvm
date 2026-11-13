target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"
define half @literal_fp_bitcasts_body_0(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out) noinline {
entry:
 %v = bitcast i16 0 to half
 store half %v,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%a0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%a1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%a2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%a3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%a4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%a5
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %r5,ptr %next,align 1
 ret half %v
}
define i64 @literal_fp_bitcasts_probe_0(ptr %input,ptr %out,i64 %salt) {
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
 %v = call half @literal_fp_bitcasts_body_0(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out)
 %raw = bitcast half %v to i16
 %wide = zext i16 %raw to i64
 %liveptr = getelementptr i8,ptr %out,i64 8
 %live = load i64,ptr %liveptr,align 1
 %tail = getelementptr i8,ptr %out,i64 16
 store i64 %wide,ptr %tail,align 1
 %mix = xor i64 %live,%wide
 %r = xor i64 %mix,%salt
 ret i64 %r
}
define fastcc half @literal_fp_bitcasts_body_1(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out) noinline {
entry:
 %v = bitcast i16 0 to half
 store half %v,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%a0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%a1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%a2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%a3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%a4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%a5
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %r5,ptr %next,align 1
 ret half %v
}
define i64 @literal_fp_bitcasts_probe_1(ptr %input,ptr %out,i64 %salt) {
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
 %v = call fastcc half @literal_fp_bitcasts_body_1(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out)
 %raw = bitcast half %v to i16
 %wide = zext i16 %raw to i64
 %liveptr = getelementptr i8,ptr %out,i64 8
 %live = load i64,ptr %liveptr,align 1
 %tail = getelementptr i8,ptr %out,i64 16
 store i64 %wide,ptr %tail,align 1
 %mix = xor i64 %live,%wide
 %r = xor i64 %mix,%salt
 ret i64 %r
}
define half @literal_fp_bitcasts_body_2(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out) noinline {
entry:
 %v = bitcast i16 1 to half
 store half %v,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%a0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%a1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%a2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%a3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%a4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%a5
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %r5,ptr %next,align 1
 ret half %v
}
define i64 @literal_fp_bitcasts_probe_2(ptr %input,ptr %out,i64 %salt) {
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
 %v = call half @literal_fp_bitcasts_body_2(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out)
 %raw = bitcast half %v to i16
 %wide = zext i16 %raw to i64
 %liveptr = getelementptr i8,ptr %out,i64 8
 %live = load i64,ptr %liveptr,align 1
 %tail = getelementptr i8,ptr %out,i64 16
 store i64 %wide,ptr %tail,align 1
 %mix = xor i64 %live,%wide
 %r = xor i64 %mix,%salt
 ret i64 %r
}
define fastcc half @literal_fp_bitcasts_body_3(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out) noinline {
entry:
 %v = bitcast i16 1 to half
 store half %v,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%a0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%a1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%a2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%a3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%a4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%a5
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %r5,ptr %next,align 1
 ret half %v
}
define i64 @literal_fp_bitcasts_probe_3(ptr %input,ptr %out,i64 %salt) {
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
 %v = call fastcc half @literal_fp_bitcasts_body_3(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out)
 %raw = bitcast half %v to i16
 %wide = zext i16 %raw to i64
 %liveptr = getelementptr i8,ptr %out,i64 8
 %live = load i64,ptr %liveptr,align 1
 %tail = getelementptr i8,ptr %out,i64 16
 store i64 %wide,ptr %tail,align 1
 %mix = xor i64 %live,%wide
 %r = xor i64 %mix,%salt
 ret i64 %r
}
define half @literal_fp_bitcasts_body_4(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out) noinline {
entry:
 %v = bitcast i16 65535 to half
 store half %v,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%a0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%a1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%a2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%a3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%a4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%a5
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %r5,ptr %next,align 1
 ret half %v
}
define i64 @literal_fp_bitcasts_probe_4(ptr %input,ptr %out,i64 %salt) {
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
 %v = call half @literal_fp_bitcasts_body_4(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out)
 %raw = bitcast half %v to i16
 %wide = zext i16 %raw to i64
 %liveptr = getelementptr i8,ptr %out,i64 8
 %live = load i64,ptr %liveptr,align 1
 %tail = getelementptr i8,ptr %out,i64 16
 store i64 %wide,ptr %tail,align 1
 %mix = xor i64 %live,%wide
 %r = xor i64 %mix,%salt
 ret i64 %r
}
define fastcc half @literal_fp_bitcasts_body_5(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out) noinline {
entry:
 %v = bitcast i16 65535 to half
 store half %v,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%a0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%a1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%a2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%a3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%a4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%a5
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %r5,ptr %next,align 1
 ret half %v
}
define i64 @literal_fp_bitcasts_probe_5(ptr %input,ptr %out,i64 %salt) {
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
 %v = call fastcc half @literal_fp_bitcasts_body_5(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out)
 %raw = bitcast half %v to i16
 %wide = zext i16 %raw to i64
 %liveptr = getelementptr i8,ptr %out,i64 8
 %live = load i64,ptr %liveptr,align 1
 %tail = getelementptr i8,ptr %out,i64 16
 store i64 %wide,ptr %tail,align 1
 %mix = xor i64 %live,%wide
 %r = xor i64 %mix,%salt
 ret i64 %r
}
define half @literal_fp_bitcasts_body_6(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out) noinline {
entry:
 %v = bitcast i16 32768 to half
 store half %v,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%a0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%a1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%a2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%a3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%a4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%a5
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %r5,ptr %next,align 1
 ret half %v
}
define i64 @literal_fp_bitcasts_probe_6(ptr %input,ptr %out,i64 %salt) {
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
 %v = call half @literal_fp_bitcasts_body_6(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out)
 %raw = bitcast half %v to i16
 %wide = zext i16 %raw to i64
 %liveptr = getelementptr i8,ptr %out,i64 8
 %live = load i64,ptr %liveptr,align 1
 %tail = getelementptr i8,ptr %out,i64 16
 store i64 %wide,ptr %tail,align 1
 %mix = xor i64 %live,%wide
 %r = xor i64 %mix,%salt
 ret i64 %r
}
define fastcc half @literal_fp_bitcasts_body_7(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out) noinline {
entry:
 %v = bitcast i16 32768 to half
 store half %v,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%a0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%a1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%a2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%a3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%a4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%a5
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %r5,ptr %next,align 1
 ret half %v
}
define i64 @literal_fp_bitcasts_probe_7(ptr %input,ptr %out,i64 %salt) {
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
 %v = call fastcc half @literal_fp_bitcasts_body_7(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out)
 %raw = bitcast half %v to i16
 %wide = zext i16 %raw to i64
 %liveptr = getelementptr i8,ptr %out,i64 8
 %live = load i64,ptr %liveptr,align 1
 %tail = getelementptr i8,ptr %out,i64 16
 store i64 %wide,ptr %tail,align 1
 %mix = xor i64 %live,%wide
 %r = xor i64 %mix,%salt
 ret i64 %r
}
define half @literal_fp_bitcasts_body_8(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out) noinline {
entry:
 %v = bitcast i16 0 to half
 store half %v,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%a0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%a1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%a2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%a3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%a4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%a5
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %r5,ptr %next,align 1
 ret half %v
}
define i64 @literal_fp_bitcasts_probe_8(ptr %input,ptr %out,i64 %salt) {
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
 %v = call half @literal_fp_bitcasts_body_8(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out)
 %raw = bitcast half %v to i16
 %wide = zext i16 %raw to i64
 %liveptr = getelementptr i8,ptr %out,i64 8
 %live = load i64,ptr %liveptr,align 1
 %tail = getelementptr i8,ptr %out,i64 16
 store i64 %wide,ptr %tail,align 1
 %mix = xor i64 %live,%wide
 %r = xor i64 %mix,%salt
 ret i64 %r
}
define fastcc half @literal_fp_bitcasts_body_9(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out) noinline {
entry:
 %v = bitcast i16 0 to half
 store half %v,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%a0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%a1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%a2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%a3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%a4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%a5
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %r5,ptr %next,align 1
 ret half %v
}
define i64 @literal_fp_bitcasts_probe_9(ptr %input,ptr %out,i64 %salt) {
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
 %v = call fastcc half @literal_fp_bitcasts_body_9(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out)
 %raw = bitcast half %v to i16
 %wide = zext i16 %raw to i64
 %liveptr = getelementptr i8,ptr %out,i64 8
 %live = load i64,ptr %liveptr,align 1
 %tail = getelementptr i8,ptr %out,i64 16
 store i64 %wide,ptr %tail,align 1
 %mix = xor i64 %live,%wide
 %r = xor i64 %mix,%salt
 ret i64 %r
}
define half @literal_fp_bitcasts_body_10(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out) noinline {
entry:
 %v = bitcast i16 4660 to half
 store half %v,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%a0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%a1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%a2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%a3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%a4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%a5
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %r5,ptr %next,align 1
 ret half %v
}
define i64 @literal_fp_bitcasts_probe_10(ptr %input,ptr %out,i64 %salt) {
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
 %v = call half @literal_fp_bitcasts_body_10(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out)
 %raw = bitcast half %v to i16
 %wide = zext i16 %raw to i64
 %liveptr = getelementptr i8,ptr %out,i64 8
 %live = load i64,ptr %liveptr,align 1
 %tail = getelementptr i8,ptr %out,i64 16
 store i64 %wide,ptr %tail,align 1
 %mix = xor i64 %live,%wide
 %r = xor i64 %mix,%salt
 ret i64 %r
}
define fastcc half @literal_fp_bitcasts_body_11(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out) noinline {
entry:
 %v = bitcast i16 4660 to half
 store half %v,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%a0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%a1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%a2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%a3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%a4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%a5
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %r5,ptr %next,align 1
 ret half %v
}
define i64 @literal_fp_bitcasts_probe_11(ptr %input,ptr %out,i64 %salt) {
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
 %v = call fastcc half @literal_fp_bitcasts_body_11(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out)
 %raw = bitcast half %v to i16
 %wide = zext i16 %raw to i64
 %liveptr = getelementptr i8,ptr %out,i64 8
 %live = load i64,ptr %liveptr,align 1
 %tail = getelementptr i8,ptr %out,i64 16
 store i64 %wide,ptr %tail,align 1
 %mix = xor i64 %live,%wide
 %r = xor i64 %mix,%salt
 ret i64 %r
}
define half @literal_fp_bitcasts_body_12(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out) noinline {
entry:
 %v = bitcast i16 1 to half
 store half %v,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%a0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%a1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%a2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%a3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%a4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%a5
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %r5,ptr %next,align 1
 ret half %v
}
define i64 @literal_fp_bitcasts_probe_12(ptr %input,ptr %out,i64 %salt) {
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
 %v = call half @literal_fp_bitcasts_body_12(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out)
 %raw = bitcast half %v to i16
 %wide = zext i16 %raw to i64
 %liveptr = getelementptr i8,ptr %out,i64 8
 %live = load i64,ptr %liveptr,align 1
 %tail = getelementptr i8,ptr %out,i64 16
 store i64 %wide,ptr %tail,align 1
 %mix = xor i64 %live,%wide
 %r = xor i64 %mix,%salt
 ret i64 %r
}
define fastcc half @literal_fp_bitcasts_body_13(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out) noinline {
entry:
 %v = bitcast i16 1 to half
 store half %v,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%a0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%a1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%a2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%a3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%a4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%a5
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %r5,ptr %next,align 1
 ret half %v
}
define i64 @literal_fp_bitcasts_probe_13(ptr %input,ptr %out,i64 %salt) {
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
 %v = call fastcc half @literal_fp_bitcasts_body_13(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out)
 %raw = bitcast half %v to i16
 %wide = zext i16 %raw to i64
 %liveptr = getelementptr i8,ptr %out,i64 8
 %live = load i64,ptr %liveptr,align 1
 %tail = getelementptr i8,ptr %out,i64 16
 store i64 %wide,ptr %tail,align 1
 %mix = xor i64 %live,%wide
 %r = xor i64 %mix,%salt
 ret i64 %r
}
define half @literal_fp_bitcasts_body_14(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out) noinline {
entry:
 %v = bitcast i16 4660 to half
 store half %v,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%a0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%a1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%a2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%a3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%a4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%a5
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %r5,ptr %next,align 1
 ret half %v
}
define i64 @literal_fp_bitcasts_probe_14(ptr %input,ptr %out,i64 %salt) {
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
 %v = call half @literal_fp_bitcasts_body_14(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out)
 %raw = bitcast half %v to i16
 %wide = zext i16 %raw to i64
 %liveptr = getelementptr i8,ptr %out,i64 8
 %live = load i64,ptr %liveptr,align 1
 %tail = getelementptr i8,ptr %out,i64 16
 store i64 %wide,ptr %tail,align 1
 %mix = xor i64 %live,%wide
 %r = xor i64 %mix,%salt
 ret i64 %r
}
define fastcc half @literal_fp_bitcasts_body_15(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out) noinline {
entry:
 %v = bitcast i16 4660 to half
 store half %v,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%a0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%a1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%a2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%a3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%a4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%a5
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %r5,ptr %next,align 1
 ret half %v
}
define i64 @literal_fp_bitcasts_probe_15(ptr %input,ptr %out,i64 %salt) {
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
 %v = call fastcc half @literal_fp_bitcasts_body_15(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out)
 %raw = bitcast half %v to i16
 %wide = zext i16 %raw to i64
 %liveptr = getelementptr i8,ptr %out,i64 8
 %live = load i64,ptr %liveptr,align 1
 %tail = getelementptr i8,ptr %out,i64 16
 store i64 %wide,ptr %tail,align 1
 %mix = xor i64 %live,%wide
 %r = xor i64 %mix,%salt
 ret i64 %r
}
define half @literal_fp_bitcasts_body_16(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out) noinline {
entry:
 %v = bitcast i16 0 to half
 store half %v,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%a0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%a1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%a2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%a3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%a4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%a5
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %r5,ptr %next,align 1
 ret half %v
}
define i64 @literal_fp_bitcasts_probe_16(ptr %input,ptr %out,i64 %salt) {
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
 %v = call half @literal_fp_bitcasts_body_16(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out)
 %raw = bitcast half %v to i16
 %wide = zext i16 %raw to i64
 %liveptr = getelementptr i8,ptr %out,i64 8
 %live = load i64,ptr %liveptr,align 1
 %tail = getelementptr i8,ptr %out,i64 16
 store i64 %wide,ptr %tail,align 1
 %mix = xor i64 %live,%wide
 %r = xor i64 %mix,%salt
 ret i64 %r
}
define fastcc half @literal_fp_bitcasts_body_17(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out) noinline {
entry:
 %v = bitcast i16 0 to half
 store half %v,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%a0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%a1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%a2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%a3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%a4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%a5
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %r5,ptr %next,align 1
 ret half %v
}
define i64 @literal_fp_bitcasts_probe_17(ptr %input,ptr %out,i64 %salt) {
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
 %v = call fastcc half @literal_fp_bitcasts_body_17(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out)
 %raw = bitcast half %v to i16
 %wide = zext i16 %raw to i64
 %liveptr = getelementptr i8,ptr %out,i64 8
 %live = load i64,ptr %liveptr,align 1
 %tail = getelementptr i8,ptr %out,i64 16
 store i64 %wide,ptr %tail,align 1
 %mix = xor i64 %live,%wide
 %r = xor i64 %mix,%salt
 ret i64 %r
}
define half @literal_fp_bitcasts_body_18(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out) noinline {
entry:
 %v = bitcast i16 57072 to half
 store half %v,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%a0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%a1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%a2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%a3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%a4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%a5
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %r5,ptr %next,align 1
 ret half %v
}
define i64 @literal_fp_bitcasts_probe_18(ptr %input,ptr %out,i64 %salt) {
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
 %v = call half @literal_fp_bitcasts_body_18(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out)
 %raw = bitcast half %v to i16
 %wide = zext i16 %raw to i64
 %liveptr = getelementptr i8,ptr %out,i64 8
 %live = load i64,ptr %liveptr,align 1
 %tail = getelementptr i8,ptr %out,i64 16
 store i64 %wide,ptr %tail,align 1
 %mix = xor i64 %live,%wide
 %r = xor i64 %mix,%salt
 ret i64 %r
}
define fastcc half @literal_fp_bitcasts_body_19(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out) noinline {
entry:
 %v = bitcast i16 57072 to half
 store half %v,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%a0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%a1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%a2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%a3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%a4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%a5
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %r5,ptr %next,align 1
 ret half %v
}
define i64 @literal_fp_bitcasts_probe_19(ptr %input,ptr %out,i64 %salt) {
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
 %v = call fastcc half @literal_fp_bitcasts_body_19(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out)
 %raw = bitcast half %v to i16
 %wide = zext i16 %raw to i64
 %liveptr = getelementptr i8,ptr %out,i64 8
 %live = load i64,ptr %liveptr,align 1
 %tail = getelementptr i8,ptr %out,i64 16
 store i64 %wide,ptr %tail,align 1
 %mix = xor i64 %live,%wide
 %r = xor i64 %mix,%salt
 ret i64 %r
}
define float @literal_fp_bitcasts_body_20(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out) noinline {
entry:
 %v = bitcast i32 0 to float
 store float %v,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%a0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%a1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%a2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%a3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%a4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%a5
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %r5,ptr %next,align 1
 ret float %v
}
define i64 @literal_fp_bitcasts_probe_20(ptr %input,ptr %out,i64 %salt) {
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
 %v = call float @literal_fp_bitcasts_body_20(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out)
 %raw = bitcast float %v to i32
 %wide = zext i32 %raw to i64
 %liveptr = getelementptr i8,ptr %out,i64 8
 %live = load i64,ptr %liveptr,align 1
 %tail = getelementptr i8,ptr %out,i64 16
 store i64 %wide,ptr %tail,align 1
 %mix = xor i64 %live,%wide
 %r = xor i64 %mix,%salt
 ret i64 %r
}
define fastcc float @literal_fp_bitcasts_body_21(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out) noinline {
entry:
 %v = bitcast i32 0 to float
 store float %v,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%a0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%a1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%a2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%a3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%a4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%a5
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %r5,ptr %next,align 1
 ret float %v
}
define i64 @literal_fp_bitcasts_probe_21(ptr %input,ptr %out,i64 %salt) {
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
 %v = call fastcc float @literal_fp_bitcasts_body_21(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out)
 %raw = bitcast float %v to i32
 %wide = zext i32 %raw to i64
 %liveptr = getelementptr i8,ptr %out,i64 8
 %live = load i64,ptr %liveptr,align 1
 %tail = getelementptr i8,ptr %out,i64 16
 store i64 %wide,ptr %tail,align 1
 %mix = xor i64 %live,%wide
 %r = xor i64 %mix,%salt
 ret i64 %r
}
define float @literal_fp_bitcasts_body_22(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out) noinline {
entry:
 %v = bitcast i32 1 to float
 store float %v,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%a0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%a1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%a2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%a3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%a4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%a5
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %r5,ptr %next,align 1
 ret float %v
}
define i64 @literal_fp_bitcasts_probe_22(ptr %input,ptr %out,i64 %salt) {
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
 %v = call float @literal_fp_bitcasts_body_22(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out)
 %raw = bitcast float %v to i32
 %wide = zext i32 %raw to i64
 %liveptr = getelementptr i8,ptr %out,i64 8
 %live = load i64,ptr %liveptr,align 1
 %tail = getelementptr i8,ptr %out,i64 16
 store i64 %wide,ptr %tail,align 1
 %mix = xor i64 %live,%wide
 %r = xor i64 %mix,%salt
 ret i64 %r
}
define fastcc float @literal_fp_bitcasts_body_23(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out) noinline {
entry:
 %v = bitcast i32 1 to float
 store float %v,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%a0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%a1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%a2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%a3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%a4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%a5
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %r5,ptr %next,align 1
 ret float %v
}
define i64 @literal_fp_bitcasts_probe_23(ptr %input,ptr %out,i64 %salt) {
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
 %v = call fastcc float @literal_fp_bitcasts_body_23(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out)
 %raw = bitcast float %v to i32
 %wide = zext i32 %raw to i64
 %liveptr = getelementptr i8,ptr %out,i64 8
 %live = load i64,ptr %liveptr,align 1
 %tail = getelementptr i8,ptr %out,i64 16
 store i64 %wide,ptr %tail,align 1
 %mix = xor i64 %live,%wide
 %r = xor i64 %mix,%salt
 ret i64 %r
}
define float @literal_fp_bitcasts_body_24(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out) noinline {
entry:
 %v = bitcast i32 4294967295 to float
 store float %v,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%a0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%a1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%a2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%a3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%a4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%a5
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %r5,ptr %next,align 1
 ret float %v
}
define i64 @literal_fp_bitcasts_probe_24(ptr %input,ptr %out,i64 %salt) {
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
 %v = call float @literal_fp_bitcasts_body_24(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out)
 %raw = bitcast float %v to i32
 %wide = zext i32 %raw to i64
 %liveptr = getelementptr i8,ptr %out,i64 8
 %live = load i64,ptr %liveptr,align 1
 %tail = getelementptr i8,ptr %out,i64 16
 store i64 %wide,ptr %tail,align 1
 %mix = xor i64 %live,%wide
 %r = xor i64 %mix,%salt
 ret i64 %r
}
define fastcc float @literal_fp_bitcasts_body_25(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out) noinline {
entry:
 %v = bitcast i32 4294967295 to float
 store float %v,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%a0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%a1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%a2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%a3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%a4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%a5
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %r5,ptr %next,align 1
 ret float %v
}
define i64 @literal_fp_bitcasts_probe_25(ptr %input,ptr %out,i64 %salt) {
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
 %v = call fastcc float @literal_fp_bitcasts_body_25(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out)
 %raw = bitcast float %v to i32
 %wide = zext i32 %raw to i64
 %liveptr = getelementptr i8,ptr %out,i64 8
 %live = load i64,ptr %liveptr,align 1
 %tail = getelementptr i8,ptr %out,i64 16
 store i64 %wide,ptr %tail,align 1
 %mix = xor i64 %live,%wide
 %r = xor i64 %mix,%salt
 ret i64 %r
}
define float @literal_fp_bitcasts_body_26(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out) noinline {
entry:
 %v = bitcast i32 32768 to float
 store float %v,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%a0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%a1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%a2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%a3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%a4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%a5
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %r5,ptr %next,align 1
 ret float %v
}
define i64 @literal_fp_bitcasts_probe_26(ptr %input,ptr %out,i64 %salt) {
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
 %v = call float @literal_fp_bitcasts_body_26(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out)
 %raw = bitcast float %v to i32
 %wide = zext i32 %raw to i64
 %liveptr = getelementptr i8,ptr %out,i64 8
 %live = load i64,ptr %liveptr,align 1
 %tail = getelementptr i8,ptr %out,i64 16
 store i64 %wide,ptr %tail,align 1
 %mix = xor i64 %live,%wide
 %r = xor i64 %mix,%salt
 ret i64 %r
}
define fastcc float @literal_fp_bitcasts_body_27(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out) noinline {
entry:
 %v = bitcast i32 32768 to float
 store float %v,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%a0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%a1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%a2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%a3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%a4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%a5
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %r5,ptr %next,align 1
 ret float %v
}
define i64 @literal_fp_bitcasts_probe_27(ptr %input,ptr %out,i64 %salt) {
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
 %v = call fastcc float @literal_fp_bitcasts_body_27(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out)
 %raw = bitcast float %v to i32
 %wide = zext i32 %raw to i64
 %liveptr = getelementptr i8,ptr %out,i64 8
 %live = load i64,ptr %liveptr,align 1
 %tail = getelementptr i8,ptr %out,i64 16
 store i64 %wide,ptr %tail,align 1
 %mix = xor i64 %live,%wide
 %r = xor i64 %mix,%salt
 ret i64 %r
}
define float @literal_fp_bitcasts_body_28(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out) noinline {
entry:
 %v = bitcast i32 2139095040 to float
 store float %v,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%a0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%a1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%a2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%a3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%a4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%a5
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %r5,ptr %next,align 1
 ret float %v
}
define i64 @literal_fp_bitcasts_probe_28(ptr %input,ptr %out,i64 %salt) {
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
 %v = call float @literal_fp_bitcasts_body_28(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out)
 %raw = bitcast float %v to i32
 %wide = zext i32 %raw to i64
 %liveptr = getelementptr i8,ptr %out,i64 8
 %live = load i64,ptr %liveptr,align 1
 %tail = getelementptr i8,ptr %out,i64 16
 store i64 %wide,ptr %tail,align 1
 %mix = xor i64 %live,%wide
 %r = xor i64 %mix,%salt
 ret i64 %r
}
define fastcc float @literal_fp_bitcasts_body_29(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out) noinline {
entry:
 %v = bitcast i32 2139095040 to float
 store float %v,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%a0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%a1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%a2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%a3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%a4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%a5
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %r5,ptr %next,align 1
 ret float %v
}
define i64 @literal_fp_bitcasts_probe_29(ptr %input,ptr %out,i64 %salt) {
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
 %v = call fastcc float @literal_fp_bitcasts_body_29(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out)
 %raw = bitcast float %v to i32
 %wide = zext i32 %raw to i64
 %liveptr = getelementptr i8,ptr %out,i64 8
 %live = load i64,ptr %liveptr,align 1
 %tail = getelementptr i8,ptr %out,i64 16
 store i64 %wide,ptr %tail,align 1
 %mix = xor i64 %live,%wide
 %r = xor i64 %mix,%salt
 ret i64 %r
}
define float @literal_fp_bitcasts_body_30(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out) noinline {
entry:
 %v = bitcast i32 2146964020 to float
 store float %v,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%a0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%a1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%a2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%a3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%a4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%a5
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %r5,ptr %next,align 1
 ret float %v
}
define i64 @literal_fp_bitcasts_probe_30(ptr %input,ptr %out,i64 %salt) {
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
 %v = call float @literal_fp_bitcasts_body_30(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out)
 %raw = bitcast float %v to i32
 %wide = zext i32 %raw to i64
 %liveptr = getelementptr i8,ptr %out,i64 8
 %live = load i64,ptr %liveptr,align 1
 %tail = getelementptr i8,ptr %out,i64 16
 store i64 %wide,ptr %tail,align 1
 %mix = xor i64 %live,%wide
 %r = xor i64 %mix,%salt
 ret i64 %r
}
define fastcc float @literal_fp_bitcasts_body_31(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out) noinline {
entry:
 %v = bitcast i32 2146964020 to float
 store float %v,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%a0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%a1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%a2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%a3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%a4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%a5
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %r5,ptr %next,align 1
 ret float %v
}
define i64 @literal_fp_bitcasts_probe_31(ptr %input,ptr %out,i64 %salt) {
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
 %v = call fastcc float @literal_fp_bitcasts_body_31(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out)
 %raw = bitcast float %v to i32
 %wide = zext i32 %raw to i64
 %liveptr = getelementptr i8,ptr %out,i64 8
 %live = load i64,ptr %liveptr,align 1
 %tail = getelementptr i8,ptr %out,i64 16
 store i64 %wide,ptr %tail,align 1
 %mix = xor i64 %live,%wide
 %r = xor i64 %mix,%salt
 ret i64 %r
}
define float @literal_fp_bitcasts_body_32(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out) noinline {
entry:
 %v = bitcast i32 1 to float
 store float %v,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%a0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%a1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%a2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%a3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%a4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%a5
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %r5,ptr %next,align 1
 ret float %v
}
define i64 @literal_fp_bitcasts_probe_32(ptr %input,ptr %out,i64 %salt) {
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
 %v = call float @literal_fp_bitcasts_body_32(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out)
 %raw = bitcast float %v to i32
 %wide = zext i32 %raw to i64
 %liveptr = getelementptr i8,ptr %out,i64 8
 %live = load i64,ptr %liveptr,align 1
 %tail = getelementptr i8,ptr %out,i64 16
 store i64 %wide,ptr %tail,align 1
 %mix = xor i64 %live,%wide
 %r = xor i64 %mix,%salt
 ret i64 %r
}
define fastcc float @literal_fp_bitcasts_body_33(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out) noinline {
entry:
 %v = bitcast i32 1 to float
 store float %v,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%a0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%a1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%a2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%a3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%a4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%a5
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %r5,ptr %next,align 1
 ret float %v
}
define i64 @literal_fp_bitcasts_probe_33(ptr %input,ptr %out,i64 %salt) {
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
 %v = call fastcc float @literal_fp_bitcasts_body_33(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out)
 %raw = bitcast float %v to i32
 %wide = zext i32 %raw to i64
 %liveptr = getelementptr i8,ptr %out,i64 8
 %live = load i64,ptr %liveptr,align 1
 %tail = getelementptr i8,ptr %out,i64 16
 store i64 %wide,ptr %tail,align 1
 %mix = xor i64 %live,%wide
 %r = xor i64 %mix,%salt
 ret i64 %r
}
define float @literal_fp_bitcasts_body_34(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out) noinline {
entry:
 %v = bitcast i32 4660 to float
 store float %v,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%a0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%a1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%a2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%a3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%a4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%a5
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %r5,ptr %next,align 1
 ret float %v
}
define i64 @literal_fp_bitcasts_probe_34(ptr %input,ptr %out,i64 %salt) {
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
 %v = call float @literal_fp_bitcasts_body_34(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out)
 %raw = bitcast float %v to i32
 %wide = zext i32 %raw to i64
 %liveptr = getelementptr i8,ptr %out,i64 8
 %live = load i64,ptr %liveptr,align 1
 %tail = getelementptr i8,ptr %out,i64 16
 store i64 %wide,ptr %tail,align 1
 %mix = xor i64 %live,%wide
 %r = xor i64 %mix,%salt
 ret i64 %r
}
define fastcc float @literal_fp_bitcasts_body_35(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out) noinline {
entry:
 %v = bitcast i32 4660 to float
 store float %v,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%a0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%a1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%a2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%a3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%a4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%a5
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %r5,ptr %next,align 1
 ret float %v
}
define i64 @literal_fp_bitcasts_probe_35(ptr %input,ptr %out,i64 %salt) {
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
 %v = call fastcc float @literal_fp_bitcasts_body_35(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out)
 %raw = bitcast float %v to i32
 %wide = zext i32 %raw to i64
 %liveptr = getelementptr i8,ptr %out,i64 8
 %live = load i64,ptr %liveptr,align 1
 %tail = getelementptr i8,ptr %out,i64 16
 store i64 %wide,ptr %tail,align 1
 %mix = xor i64 %live,%wide
 %r = xor i64 %mix,%salt
 ret i64 %r
}
define float @literal_fp_bitcasts_body_36(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out) noinline {
entry:
 %v = bitcast i32 0 to float
 store float %v,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%a0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%a1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%a2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%a3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%a4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%a5
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %r5,ptr %next,align 1
 ret float %v
}
define i64 @literal_fp_bitcasts_probe_36(ptr %input,ptr %out,i64 %salt) {
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
 %v = call float @literal_fp_bitcasts_body_36(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out)
 %raw = bitcast float %v to i32
 %wide = zext i32 %raw to i64
 %liveptr = getelementptr i8,ptr %out,i64 8
 %live = load i64,ptr %liveptr,align 1
 %tail = getelementptr i8,ptr %out,i64 16
 store i64 %wide,ptr %tail,align 1
 %mix = xor i64 %live,%wide
 %r = xor i64 %mix,%salt
 ret i64 %r
}
define fastcc float @literal_fp_bitcasts_body_37(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out) noinline {
entry:
 %v = bitcast i32 0 to float
 store float %v,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%a0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%a1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%a2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%a3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%a4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%a5
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %r5,ptr %next,align 1
 ret float %v
}
define i64 @literal_fp_bitcasts_probe_37(ptr %input,ptr %out,i64 %salt) {
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
 %v = call fastcc float @literal_fp_bitcasts_body_37(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out)
 %raw = bitcast float %v to i32
 %wide = zext i32 %raw to i64
 %liveptr = getelementptr i8,ptr %out,i64 8
 %live = load i64,ptr %liveptr,align 1
 %tail = getelementptr i8,ptr %out,i64 16
 store i64 %wide,ptr %tail,align 1
 %mix = xor i64 %live,%wide
 %r = xor i64 %mix,%salt
 ret i64 %r
}
define float @literal_fp_bitcasts_body_38(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out) noinline {
entry:
 %v = bitcast i32 2596069104 to float
 store float %v,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%a0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%a1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%a2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%a3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%a4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%a5
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %r5,ptr %next,align 1
 ret float %v
}
define i64 @literal_fp_bitcasts_probe_38(ptr %input,ptr %out,i64 %salt) {
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
 %v = call float @literal_fp_bitcasts_body_38(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out)
 %raw = bitcast float %v to i32
 %wide = zext i32 %raw to i64
 %liveptr = getelementptr i8,ptr %out,i64 8
 %live = load i64,ptr %liveptr,align 1
 %tail = getelementptr i8,ptr %out,i64 16
 store i64 %wide,ptr %tail,align 1
 %mix = xor i64 %live,%wide
 %r = xor i64 %mix,%salt
 ret i64 %r
}
define fastcc float @literal_fp_bitcasts_body_39(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out) noinline {
entry:
 %v = bitcast i32 2596069104 to float
 store float %v,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%a0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%a1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%a2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%a3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%a4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%a5
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %r5,ptr %next,align 1
 ret float %v
}
define i64 @literal_fp_bitcasts_probe_39(ptr %input,ptr %out,i64 %salt) {
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
 %v = call fastcc float @literal_fp_bitcasts_body_39(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out)
 %raw = bitcast float %v to i32
 %wide = zext i32 %raw to i64
 %liveptr = getelementptr i8,ptr %out,i64 8
 %live = load i64,ptr %liveptr,align 1
 %tail = getelementptr i8,ptr %out,i64 16
 store i64 %wide,ptr %tail,align 1
 %mix = xor i64 %live,%wide
 %r = xor i64 %mix,%salt
 ret i64 %r
}
define double @literal_fp_bitcasts_body_40(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out) noinline {
entry:
 %v = bitcast i64 0 to double
 store double %v,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%a0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%a1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%a2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%a3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%a4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%a5
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %r5,ptr %next,align 1
 ret double %v
}
define i64 @literal_fp_bitcasts_probe_40(ptr %input,ptr %out,i64 %salt) {
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
 %v = call double @literal_fp_bitcasts_body_40(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out)
 %raw = bitcast double %v to i64
 %wide = add i64 %raw,0
 %liveptr = getelementptr i8,ptr %out,i64 8
 %live = load i64,ptr %liveptr,align 1
 %tail = getelementptr i8,ptr %out,i64 16
 store i64 %wide,ptr %tail,align 1
 %mix = xor i64 %live,%wide
 %r = xor i64 %mix,%salt
 ret i64 %r
}
define fastcc double @literal_fp_bitcasts_body_41(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out) noinline {
entry:
 %v = bitcast i64 0 to double
 store double %v,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%a0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%a1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%a2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%a3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%a4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%a5
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %r5,ptr %next,align 1
 ret double %v
}
define i64 @literal_fp_bitcasts_probe_41(ptr %input,ptr %out,i64 %salt) {
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
 %v = call fastcc double @literal_fp_bitcasts_body_41(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out)
 %raw = bitcast double %v to i64
 %wide = add i64 %raw,0
 %liveptr = getelementptr i8,ptr %out,i64 8
 %live = load i64,ptr %liveptr,align 1
 %tail = getelementptr i8,ptr %out,i64 16
 store i64 %wide,ptr %tail,align 1
 %mix = xor i64 %live,%wide
 %r = xor i64 %mix,%salt
 ret i64 %r
}
define double @literal_fp_bitcasts_body_42(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out) noinline {
entry:
 %v = bitcast i64 1 to double
 store double %v,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%a0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%a1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%a2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%a3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%a4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%a5
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %r5,ptr %next,align 1
 ret double %v
}
define i64 @literal_fp_bitcasts_probe_42(ptr %input,ptr %out,i64 %salt) {
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
 %v = call double @literal_fp_bitcasts_body_42(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out)
 %raw = bitcast double %v to i64
 %wide = add i64 %raw,0
 %liveptr = getelementptr i8,ptr %out,i64 8
 %live = load i64,ptr %liveptr,align 1
 %tail = getelementptr i8,ptr %out,i64 16
 store i64 %wide,ptr %tail,align 1
 %mix = xor i64 %live,%wide
 %r = xor i64 %mix,%salt
 ret i64 %r
}
define fastcc double @literal_fp_bitcasts_body_43(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out) noinline {
entry:
 %v = bitcast i64 1 to double
 store double %v,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%a0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%a1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%a2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%a3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%a4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%a5
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %r5,ptr %next,align 1
 ret double %v
}
define i64 @literal_fp_bitcasts_probe_43(ptr %input,ptr %out,i64 %salt) {
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
 %v = call fastcc double @literal_fp_bitcasts_body_43(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out)
 %raw = bitcast double %v to i64
 %wide = add i64 %raw,0
 %liveptr = getelementptr i8,ptr %out,i64 8
 %live = load i64,ptr %liveptr,align 1
 %tail = getelementptr i8,ptr %out,i64 16
 store i64 %wide,ptr %tail,align 1
 %mix = xor i64 %live,%wide
 %r = xor i64 %mix,%salt
 ret i64 %r
}
define double @literal_fp_bitcasts_body_44(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out) noinline {
entry:
 %v = bitcast i64 18446744073709551615 to double
 store double %v,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%a0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%a1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%a2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%a3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%a4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%a5
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %r5,ptr %next,align 1
 ret double %v
}
define i64 @literal_fp_bitcasts_probe_44(ptr %input,ptr %out,i64 %salt) {
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
 %v = call double @literal_fp_bitcasts_body_44(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out)
 %raw = bitcast double %v to i64
 %wide = add i64 %raw,0
 %liveptr = getelementptr i8,ptr %out,i64 8
 %live = load i64,ptr %liveptr,align 1
 %tail = getelementptr i8,ptr %out,i64 16
 store i64 %wide,ptr %tail,align 1
 %mix = xor i64 %live,%wide
 %r = xor i64 %mix,%salt
 ret i64 %r
}
define fastcc double @literal_fp_bitcasts_body_45(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out) noinline {
entry:
 %v = bitcast i64 18446744073709551615 to double
 store double %v,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%a0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%a1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%a2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%a3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%a4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%a5
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %r5,ptr %next,align 1
 ret double %v
}
define i64 @literal_fp_bitcasts_probe_45(ptr %input,ptr %out,i64 %salt) {
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
 %v = call fastcc double @literal_fp_bitcasts_body_45(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out)
 %raw = bitcast double %v to i64
 %wide = add i64 %raw,0
 %liveptr = getelementptr i8,ptr %out,i64 8
 %live = load i64,ptr %liveptr,align 1
 %tail = getelementptr i8,ptr %out,i64 16
 store i64 %wide,ptr %tail,align 1
 %mix = xor i64 %live,%wide
 %r = xor i64 %mix,%salt
 ret i64 %r
}
define double @literal_fp_bitcasts_body_46(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out) noinline {
entry:
 %v = bitcast i64 9223372036854808576 to double
 store double %v,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%a0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%a1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%a2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%a3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%a4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%a5
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %r5,ptr %next,align 1
 ret double %v
}
define i64 @literal_fp_bitcasts_probe_46(ptr %input,ptr %out,i64 %salt) {
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
 %v = call double @literal_fp_bitcasts_body_46(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out)
 %raw = bitcast double %v to i64
 %wide = add i64 %raw,0
 %liveptr = getelementptr i8,ptr %out,i64 8
 %live = load i64,ptr %liveptr,align 1
 %tail = getelementptr i8,ptr %out,i64 16
 store i64 %wide,ptr %tail,align 1
 %mix = xor i64 %live,%wide
 %r = xor i64 %mix,%salt
 ret i64 %r
}
define fastcc double @literal_fp_bitcasts_body_47(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out) noinline {
entry:
 %v = bitcast i64 9223372036854808576 to double
 store double %v,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%a0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%a1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%a2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%a3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%a4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%a5
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %r5,ptr %next,align 1
 ret double %v
}
define i64 @literal_fp_bitcasts_probe_47(ptr %input,ptr %out,i64 %salt) {
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
 %v = call fastcc double @literal_fp_bitcasts_body_47(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out)
 %raw = bitcast double %v to i64
 %wide = add i64 %raw,0
 %liveptr = getelementptr i8,ptr %out,i64 8
 %live = load i64,ptr %liveptr,align 1
 %tail = getelementptr i8,ptr %out,i64 16
 store i64 %wide,ptr %tail,align 1
 %mix = xor i64 %live,%wide
 %r = xor i64 %mix,%salt
 ret i64 %r
}
define double @literal_fp_bitcasts_body_48(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out) noinline {
entry:
 %v = bitcast i64 8935281850574700544 to double
 store double %v,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%a0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%a1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%a2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%a3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%a4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%a5
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %r5,ptr %next,align 1
 ret double %v
}
define i64 @literal_fp_bitcasts_probe_48(ptr %input,ptr %out,i64 %salt) {
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
 %v = call double @literal_fp_bitcasts_body_48(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out)
 %raw = bitcast double %v to i64
 %wide = add i64 %raw,0
 %liveptr = getelementptr i8,ptr %out,i64 8
 %live = load i64,ptr %liveptr,align 1
 %tail = getelementptr i8,ptr %out,i64 16
 store i64 %wide,ptr %tail,align 1
 %mix = xor i64 %live,%wide
 %r = xor i64 %mix,%salt
 ret i64 %r
}
define fastcc double @literal_fp_bitcasts_body_49(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out) noinline {
entry:
 %v = bitcast i64 8935281850574700544 to double
 store double %v,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%a0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%a1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%a2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%a3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%a4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%a5
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %r5,ptr %next,align 1
 ret double %v
}
define i64 @literal_fp_bitcasts_probe_49(ptr %input,ptr %out,i64 %salt) {
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
 %v = call fastcc double @literal_fp_bitcasts_body_49(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out)
 %raw = bitcast double %v to i64
 %wide = add i64 %raw,0
 %liveptr = getelementptr i8,ptr %out,i64 8
 %live = load i64,ptr %liveptr,align 1
 %tail = getelementptr i8,ptr %out,i64 16
 store i64 %wide,ptr %tail,align 1
 %mix = xor i64 %live,%wide
 %r = xor i64 %mix,%salt
 ret i64 %r
}
define double @literal_fp_bitcasts_body_50(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out) noinline {
entry:
 %v = bitcast i64 9205677894728684084 to double
 store double %v,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%a0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%a1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%a2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%a3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%a4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%a5
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %r5,ptr %next,align 1
 ret double %v
}
define i64 @literal_fp_bitcasts_probe_50(ptr %input,ptr %out,i64 %salt) {
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
 %v = call double @literal_fp_bitcasts_body_50(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out)
 %raw = bitcast double %v to i64
 %wide = add i64 %raw,0
 %liveptr = getelementptr i8,ptr %out,i64 8
 %live = load i64,ptr %liveptr,align 1
 %tail = getelementptr i8,ptr %out,i64 16
 store i64 %wide,ptr %tail,align 1
 %mix = xor i64 %live,%wide
 %r = xor i64 %mix,%salt
 ret i64 %r
}
define fastcc double @literal_fp_bitcasts_body_51(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out) noinline {
entry:
 %v = bitcast i64 9205677894728684084 to double
 store double %v,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%a0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%a1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%a2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%a3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%a4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%a5
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %r5,ptr %next,align 1
 ret double %v
}
define i64 @literal_fp_bitcasts_probe_51(ptr %input,ptr %out,i64 %salt) {
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
 %v = call fastcc double @literal_fp_bitcasts_body_51(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out)
 %raw = bitcast double %v to i64
 %wide = add i64 %raw,0
 %liveptr = getelementptr i8,ptr %out,i64 8
 %live = load i64,ptr %liveptr,align 1
 %tail = getelementptr i8,ptr %out,i64 16
 store i64 %wide,ptr %tail,align 1
 %mix = xor i64 %live,%wide
 %r = xor i64 %mix,%salt
 ret i64 %r
}
define double @literal_fp_bitcasts_body_52(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out) noinline {
entry:
 %v = bitcast i64 9218868437227405313 to double
 store double %v,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%a0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%a1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%a2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%a3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%a4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%a5
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %r5,ptr %next,align 1
 ret double %v
}
define i64 @literal_fp_bitcasts_probe_52(ptr %input,ptr %out,i64 %salt) {
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
 %v = call double @literal_fp_bitcasts_body_52(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out)
 %raw = bitcast double %v to i64
 %wide = add i64 %raw,0
 %liveptr = getelementptr i8,ptr %out,i64 8
 %live = load i64,ptr %liveptr,align 1
 %tail = getelementptr i8,ptr %out,i64 16
 store i64 %wide,ptr %tail,align 1
 %mix = xor i64 %live,%wide
 %r = xor i64 %mix,%salt
 ret i64 %r
}
define fastcc double @literal_fp_bitcasts_body_53(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out) noinline {
entry:
 %v = bitcast i64 9218868437227405313 to double
 store double %v,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%a0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%a1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%a2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%a3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%a4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%a5
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %r5,ptr %next,align 1
 ret double %v
}
define i64 @literal_fp_bitcasts_probe_53(ptr %input,ptr %out,i64 %salt) {
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
 %v = call fastcc double @literal_fp_bitcasts_body_53(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out)
 %raw = bitcast double %v to i64
 %wide = add i64 %raw,0
 %liveptr = getelementptr i8,ptr %out,i64 8
 %live = load i64,ptr %liveptr,align 1
 %tail = getelementptr i8,ptr %out,i64 16
 store i64 %wide,ptr %tail,align 1
 %mix = xor i64 %live,%wide
 %r = xor i64 %mix,%salt
 ret i64 %r
}
define double @literal_fp_bitcasts_body_54(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out) noinline {
entry:
 %v = bitcast i64 9221120237041095220 to double
 store double %v,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%a0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%a1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%a2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%a3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%a4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%a5
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %r5,ptr %next,align 1
 ret double %v
}
define i64 @literal_fp_bitcasts_probe_54(ptr %input,ptr %out,i64 %salt) {
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
 %v = call double @literal_fp_bitcasts_body_54(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out)
 %raw = bitcast double %v to i64
 %wide = add i64 %raw,0
 %liveptr = getelementptr i8,ptr %out,i64 8
 %live = load i64,ptr %liveptr,align 1
 %tail = getelementptr i8,ptr %out,i64 16
 store i64 %wide,ptr %tail,align 1
 %mix = xor i64 %live,%wide
 %r = xor i64 %mix,%salt
 ret i64 %r
}
define fastcc double @literal_fp_bitcasts_body_55(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out) noinline {
entry:
 %v = bitcast i64 9221120237041095220 to double
 store double %v,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%a0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%a1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%a2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%a3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%a4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%a5
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %r5,ptr %next,align 1
 ret double %v
}
define i64 @literal_fp_bitcasts_probe_55(ptr %input,ptr %out,i64 %salt) {
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
 %v = call fastcc double @literal_fp_bitcasts_body_55(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out)
 %raw = bitcast double %v to i64
 %wide = add i64 %raw,0
 %liveptr = getelementptr i8,ptr %out,i64 8
 %live = load i64,ptr %liveptr,align 1
 %tail = getelementptr i8,ptr %out,i64 16
 store i64 %wide,ptr %tail,align 1
 %mix = xor i64 %live,%wide
 %r = xor i64 %mix,%salt
 ret i64 %r
}
define double @literal_fp_bitcasts_body_56(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out) noinline {
entry:
 %v = bitcast i64 9223372036854775808 to double
 store double %v,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%a0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%a1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%a2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%a3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%a4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%a5
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %r5,ptr %next,align 1
 ret double %v
}
define i64 @literal_fp_bitcasts_probe_56(ptr %input,ptr %out,i64 %salt) {
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
 %v = call double @literal_fp_bitcasts_body_56(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out)
 %raw = bitcast double %v to i64
 %wide = add i64 %raw,0
 %liveptr = getelementptr i8,ptr %out,i64 8
 %live = load i64,ptr %liveptr,align 1
 %tail = getelementptr i8,ptr %out,i64 16
 store i64 %wide,ptr %tail,align 1
 %mix = xor i64 %live,%wide
 %r = xor i64 %mix,%salt
 ret i64 %r
}
define fastcc double @literal_fp_bitcasts_body_57(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out) noinline {
entry:
 %v = bitcast i64 9223372036854775808 to double
 store double %v,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%a0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%a1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%a2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%a3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%a4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%a5
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %r5,ptr %next,align 1
 ret double %v
}
define i64 @literal_fp_bitcasts_probe_57(ptr %input,ptr %out,i64 %salt) {
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
 %v = call fastcc double @literal_fp_bitcasts_body_57(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out)
 %raw = bitcast double %v to i64
 %wide = add i64 %raw,0
 %liveptr = getelementptr i8,ptr %out,i64 8
 %live = load i64,ptr %liveptr,align 1
 %tail = getelementptr i8,ptr %out,i64 16
 store i64 %wide,ptr %tail,align 1
 %mix = xor i64 %live,%wide
 %r = xor i64 %mix,%salt
 ret i64 %r
}
define double @literal_fp_bitcasts_body_58(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out) noinline {
entry:
 %v = bitcast i64 1311768467463790320 to double
 store double %v,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%a0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%a1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%a2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%a3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%a4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%a5
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %r5,ptr %next,align 1
 ret double %v
}
define i64 @literal_fp_bitcasts_probe_58(ptr %input,ptr %out,i64 %salt) {
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
 %v = call double @literal_fp_bitcasts_body_58(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out)
 %raw = bitcast double %v to i64
 %wide = add i64 %raw,0
 %liveptr = getelementptr i8,ptr %out,i64 8
 %live = load i64,ptr %liveptr,align 1
 %tail = getelementptr i8,ptr %out,i64 16
 store i64 %wide,ptr %tail,align 1
 %mix = xor i64 %live,%wide
 %r = xor i64 %mix,%salt
 ret i64 %r
}
define fastcc double @literal_fp_bitcasts_body_59(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out) noinline {
entry:
 %v = bitcast i64 1311768467463790320 to double
 store double %v,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%a0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%a1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%a2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%a3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%a4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%a5
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %r5,ptr %next,align 1
 ret double %v
}
define i64 @literal_fp_bitcasts_probe_59(ptr %input,ptr %out,i64 %salt) {
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
 %v = call fastcc double @literal_fp_bitcasts_body_59(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5,ptr %out)
 %raw = bitcast double %v to i64
 %wide = add i64 %raw,0
 %liveptr = getelementptr i8,ptr %out,i64 8
 %live = load i64,ptr %liveptr,align 1
 %tail = getelementptr i8,ptr %out,i64 16
 store i64 %wide,ptr %tail,align 1
 %mix = xor i64 %live,%wide
 %r = xor i64 %mix,%salt
 ret i64 %r
}
