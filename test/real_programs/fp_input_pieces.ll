target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"
define i64 @fp_piece_body_0(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,<4 x double> %a,<4 x double> %b,i64 %tail,ptr %out) noinline {
entry:
 store <4 x double> %a,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 32
 store <4 x double> %b,ptr %next,align 1
 %m0 = mul i64 %tail,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 %checksum = getelementptr i8,ptr %out,i64 64
 store i64 %r5,ptr %checksum,align 1
 ret i64 %r5
}
declare i64 @fp_piece_provider_0(i64,i64,i64,i64,i64,i64,<4 x double>,<4 x double>,i64,ptr)
define i64 @fp_piece_probe_0(ptr %out,ptr %a_ptr,ptr %b_ptr,i64 %salt) {
entry:
 %a = load <4 x double>,ptr %a_ptr,align 1
 %b = load <4 x double>,ptr %b_ptr,align 1
 %p0 = xor i64 %salt,1311768467463790321
 %p1 = xor i64 %salt,2623536934927580642
 %p2 = xor i64 %salt,3935305402391370963
 %p3 = xor i64 %salt,5247073869855161284
 %p4 = xor i64 %salt,6558842337318951605
 %p5 = xor i64 %salt,7870610804782741926
 %tail = xor i64 %salt,9305357566071262703
 %local = call i64 @fp_piece_body_0(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,<4 x double> %a,<4 x double> %b,i64 %tail,ptr %out)
 %other = getelementptr i8,ptr %out,i64 72
 %external = call i64 @fp_piece_provider_0(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,<4 x double> %a,<4 x double> %b,i64 %tail,ptr %other)
 %mixed = xor i64 %local,%external
 %r = xor i64 %mixed,%salt
 ret i64 %r
}
define fastcc i64 @fp_piece_body_1(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,<4 x double> %a,<4 x double> %b,i64 %tail,ptr %out) noinline {
entry:
 store <4 x double> %a,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 32
 store <4 x double> %b,ptr %next,align 1
 %m0 = mul i64 %tail,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 %checksum = getelementptr i8,ptr %out,i64 64
 store i64 %r5,ptr %checksum,align 1
 ret i64 %r5
}
declare i64 @fp_piece_provider_1(i64,i64,i64,i64,i64,i64,<4 x double>,<4 x double>,i64,ptr)
define i64 @fp_piece_probe_1(ptr %out,ptr %a_ptr,ptr %b_ptr,i64 %salt) {
entry:
 %a = load <4 x double>,ptr %a_ptr,align 1
 %b = load <4 x double>,ptr %b_ptr,align 1
 %p0 = xor i64 %salt,1311768467463790321
 %p1 = xor i64 %salt,2623536934927580642
 %p2 = xor i64 %salt,3935305402391370963
 %p3 = xor i64 %salt,5247073869855161284
 %p4 = xor i64 %salt,6558842337318951605
 %p5 = xor i64 %salt,7870610804782741926
 %tail = xor i64 %salt,9305357566071262703
 %local = call fastcc i64 @fp_piece_body_1(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,<4 x double> %a,<4 x double> %b,i64 %tail,ptr %out)
 %other = getelementptr i8,ptr %out,i64 72
 %external = call i64 @fp_piece_provider_1(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,<4 x double> %a,<4 x double> %b,i64 %tail,ptr %other)
 %mixed = xor i64 %local,%external
 %r = xor i64 %mixed,%salt
 ret i64 %r
}
define i64 @fp_piece_body_2(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,<4 x fp128> %a,<4 x fp128> %b,i64 %tail,ptr %out) noinline {
entry:
 store <4 x fp128> %a,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 64
 store <4 x fp128> %b,ptr %next,align 1
 %m0 = mul i64 %tail,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 %checksum = getelementptr i8,ptr %out,i64 128
 store i64 %r5,ptr %checksum,align 1
 ret i64 %r5
}
declare i64 @fp_piece_provider_2(i64,i64,i64,i64,i64,i64,<4 x fp128>,<4 x fp128>,i64,ptr)
define i64 @fp_piece_probe_2(ptr %out,ptr %a_ptr,ptr %b_ptr,i64 %salt) {
entry:
 %a = load <4 x fp128>,ptr %a_ptr,align 1
 %b = load <4 x fp128>,ptr %b_ptr,align 1
 %p0 = xor i64 %salt,1311768467463790321
 %p1 = xor i64 %salt,2623536934927580642
 %p2 = xor i64 %salt,3935305402391370963
 %p3 = xor i64 %salt,5247073869855161284
 %p4 = xor i64 %salt,6558842337318951605
 %p5 = xor i64 %salt,7870610804782741926
 %tail = xor i64 %salt,9305357566071262703
 %local = call i64 @fp_piece_body_2(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,<4 x fp128> %a,<4 x fp128> %b,i64 %tail,ptr %out)
 %other = getelementptr i8,ptr %out,i64 136
 %external = call i64 @fp_piece_provider_2(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,<4 x fp128> %a,<4 x fp128> %b,i64 %tail,ptr %other)
 %mixed = xor i64 %local,%external
 %r = xor i64 %mixed,%salt
 ret i64 %r
}
define fastcc i64 @fp_piece_body_3(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,<4 x fp128> %a,<4 x fp128> %b,i64 %tail,ptr %out) noinline {
entry:
 store <4 x fp128> %a,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 64
 store <4 x fp128> %b,ptr %next,align 1
 %m0 = mul i64 %tail,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 %checksum = getelementptr i8,ptr %out,i64 128
 store i64 %r5,ptr %checksum,align 1
 ret i64 %r5
}
declare i64 @fp_piece_provider_3(i64,i64,i64,i64,i64,i64,<4 x fp128>,<4 x fp128>,i64,ptr)
define i64 @fp_piece_probe_3(ptr %out,ptr %a_ptr,ptr %b_ptr,i64 %salt) {
entry:
 %a = load <4 x fp128>,ptr %a_ptr,align 1
 %b = load <4 x fp128>,ptr %b_ptr,align 1
 %p0 = xor i64 %salt,1311768467463790321
 %p1 = xor i64 %salt,2623536934927580642
 %p2 = xor i64 %salt,3935305402391370963
 %p3 = xor i64 %salt,5247073869855161284
 %p4 = xor i64 %salt,6558842337318951605
 %p5 = xor i64 %salt,7870610804782741926
 %tail = xor i64 %salt,9305357566071262703
 %local = call fastcc i64 @fp_piece_body_3(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,<4 x fp128> %a,<4 x fp128> %b,i64 %tail,ptr %out)
 %other = getelementptr i8,ptr %out,i64 136
 %external = call i64 @fp_piece_provider_3(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,<4 x fp128> %a,<4 x fp128> %b,i64 %tail,ptr %other)
 %mixed = xor i64 %local,%external
 %r = xor i64 %mixed,%salt
 ret i64 %r
}
define i64 @fp_piece_body_4(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,<4 x x86_fp80> %a,<4 x x86_fp80> %b,i64 %tail,ptr %out) noinline {
entry:
 store <4 x x86_fp80> %a,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 40
 store <4 x x86_fp80> %b,ptr %next,align 1
 %m0 = mul i64 %tail,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 %checksum = getelementptr i8,ptr %out,i64 80
 store i64 %r5,ptr %checksum,align 1
 ret i64 %r5
}
declare i64 @fp_piece_provider_4(i64,i64,i64,i64,i64,i64,<4 x x86_fp80>,<4 x x86_fp80>,i64,ptr)
define i64 @fp_piece_probe_4(ptr %out,ptr %a_ptr,ptr %b_ptr,i64 %salt) {
entry:
 %a = load <4 x x86_fp80>,ptr %a_ptr,align 1
 %b = load <4 x x86_fp80>,ptr %b_ptr,align 1
 %p0 = xor i64 %salt,1311768467463790321
 %p1 = xor i64 %salt,2623536934927580642
 %p2 = xor i64 %salt,3935305402391370963
 %p3 = xor i64 %salt,5247073869855161284
 %p4 = xor i64 %salt,6558842337318951605
 %p5 = xor i64 %salt,7870610804782741926
 %tail = xor i64 %salt,9305357566071262703
 %local = call i64 @fp_piece_body_4(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,<4 x x86_fp80> %a,<4 x x86_fp80> %b,i64 %tail,ptr %out)
 %other = getelementptr i8,ptr %out,i64 88
 %external = call i64 @fp_piece_provider_4(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,<4 x x86_fp80> %a,<4 x x86_fp80> %b,i64 %tail,ptr %other)
 %mixed = xor i64 %local,%external
 %r = xor i64 %mixed,%salt
 ret i64 %r
}
define fastcc i64 @fp_piece_body_5(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,<4 x x86_fp80> %a,<4 x x86_fp80> %b,i64 %tail,ptr %out) noinline {
entry:
 store <4 x x86_fp80> %a,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 40
 store <4 x x86_fp80> %b,ptr %next,align 1
 %m0 = mul i64 %tail,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 %checksum = getelementptr i8,ptr %out,i64 80
 store i64 %r5,ptr %checksum,align 1
 ret i64 %r5
}
declare i64 @fp_piece_provider_5(i64,i64,i64,i64,i64,i64,<4 x x86_fp80>,<4 x x86_fp80>,i64,ptr)
define i64 @fp_piece_probe_5(ptr %out,ptr %a_ptr,ptr %b_ptr,i64 %salt) {
entry:
 %a = load <4 x x86_fp80>,ptr %a_ptr,align 1
 %b = load <4 x x86_fp80>,ptr %b_ptr,align 1
 %p0 = xor i64 %salt,1311768467463790321
 %p1 = xor i64 %salt,2623536934927580642
 %p2 = xor i64 %salt,3935305402391370963
 %p3 = xor i64 %salt,5247073869855161284
 %p4 = xor i64 %salt,6558842337318951605
 %p5 = xor i64 %salt,7870610804782741926
 %tail = xor i64 %salt,9305357566071262703
 %local = call fastcc i64 @fp_piece_body_5(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,<4 x x86_fp80> %a,<4 x x86_fp80> %b,i64 %tail,ptr %out)
 %other = getelementptr i8,ptr %out,i64 88
 %external = call i64 @fp_piece_provider_5(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,<4 x x86_fp80> %a,<4 x x86_fp80> %b,i64 %tail,ptr %other)
 %mixed = xor i64 %local,%external
 %r = xor i64 %mixed,%salt
 ret i64 %r
}
