target triple = "x86_64-unknown-linux-gnu"
declare i1 @llvm.sadd.sat.i1(i1,i1)
define i64 @odd_saturation_1_0(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i1
 %y = trunc i64 %b to i1
 %v0 = call i1 @llvm.sadd.sat.i1(i1 %x,i1 %y)
 %wide0 = zext i1 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i1 @llvm.sadd.sat.i1(i1 -1,i1 %y)
 %wide1 = zext i1 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i1 @llvm.sadd.sat.i1(i1 %x,i1 1)
 %wide2 = zext i1 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i1 @llvm.sadd.sat.i1(i1 -1,i1 1)
 %wide3 = zext i1 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i1 @llvm.ssub.sat.i1(i1,i1)
define i64 @odd_saturation_1_1(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i1
 %y = trunc i64 %b to i1
 %v0 = call i1 @llvm.ssub.sat.i1(i1 %x,i1 %y)
 %wide0 = zext i1 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i1 @llvm.ssub.sat.i1(i1 -1,i1 %y)
 %wide1 = zext i1 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i1 @llvm.ssub.sat.i1(i1 %x,i1 1)
 %wide2 = zext i1 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i1 @llvm.ssub.sat.i1(i1 -1,i1 1)
 %wide3 = zext i1 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i2 @llvm.sadd.sat.i2(i2,i2)
define i64 @odd_saturation_2_0(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i2
 %y = trunc i64 %b to i2
 %v0 = call i2 @llvm.sadd.sat.i2(i2 %x,i2 %y)
 %wide0 = zext i2 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i2 @llvm.sadd.sat.i2(i2 -1,i2 %y)
 %wide1 = zext i2 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i2 @llvm.sadd.sat.i2(i2 %x,i2 1)
 %wide2 = zext i2 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i2 @llvm.sadd.sat.i2(i2 -1,i2 1)
 %wide3 = zext i2 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i2 @llvm.ssub.sat.i2(i2,i2)
define i64 @odd_saturation_2_1(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i2
 %y = trunc i64 %b to i2
 %v0 = call i2 @llvm.ssub.sat.i2(i2 %x,i2 %y)
 %wide0 = zext i2 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i2 @llvm.ssub.sat.i2(i2 -1,i2 %y)
 %wide1 = zext i2 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i2 @llvm.ssub.sat.i2(i2 %x,i2 1)
 %wide2 = zext i2 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i2 @llvm.ssub.sat.i2(i2 -1,i2 1)
 %wide3 = zext i2 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i3 @llvm.sadd.sat.i3(i3,i3)
define i64 @odd_saturation_3_0(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i3
 %y = trunc i64 %b to i3
 %v0 = call i3 @llvm.sadd.sat.i3(i3 %x,i3 %y)
 %wide0 = zext i3 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i3 @llvm.sadd.sat.i3(i3 -1,i3 %y)
 %wide1 = zext i3 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i3 @llvm.sadd.sat.i3(i3 %x,i3 1)
 %wide2 = zext i3 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i3 @llvm.sadd.sat.i3(i3 -1,i3 1)
 %wide3 = zext i3 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i3 @llvm.ssub.sat.i3(i3,i3)
define i64 @odd_saturation_3_1(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i3
 %y = trunc i64 %b to i3
 %v0 = call i3 @llvm.ssub.sat.i3(i3 %x,i3 %y)
 %wide0 = zext i3 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i3 @llvm.ssub.sat.i3(i3 -1,i3 %y)
 %wide1 = zext i3 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i3 @llvm.ssub.sat.i3(i3 %x,i3 1)
 %wide2 = zext i3 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i3 @llvm.ssub.sat.i3(i3 -1,i3 1)
 %wide3 = zext i3 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i4 @llvm.sadd.sat.i4(i4,i4)
define i64 @odd_saturation_4_0(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i4
 %y = trunc i64 %b to i4
 %v0 = call i4 @llvm.sadd.sat.i4(i4 %x,i4 %y)
 %wide0 = zext i4 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i4 @llvm.sadd.sat.i4(i4 -1,i4 %y)
 %wide1 = zext i4 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i4 @llvm.sadd.sat.i4(i4 %x,i4 1)
 %wide2 = zext i4 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i4 @llvm.sadd.sat.i4(i4 -1,i4 1)
 %wide3 = zext i4 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i4 @llvm.ssub.sat.i4(i4,i4)
define i64 @odd_saturation_4_1(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i4
 %y = trunc i64 %b to i4
 %v0 = call i4 @llvm.ssub.sat.i4(i4 %x,i4 %y)
 %wide0 = zext i4 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i4 @llvm.ssub.sat.i4(i4 -1,i4 %y)
 %wide1 = zext i4 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i4 @llvm.ssub.sat.i4(i4 %x,i4 1)
 %wide2 = zext i4 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i4 @llvm.ssub.sat.i4(i4 -1,i4 1)
 %wide3 = zext i4 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i5 @llvm.sadd.sat.i5(i5,i5)
define i64 @odd_saturation_5_0(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i5
 %y = trunc i64 %b to i5
 %v0 = call i5 @llvm.sadd.sat.i5(i5 %x,i5 %y)
 %wide0 = zext i5 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i5 @llvm.sadd.sat.i5(i5 -1,i5 %y)
 %wide1 = zext i5 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i5 @llvm.sadd.sat.i5(i5 %x,i5 1)
 %wide2 = zext i5 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i5 @llvm.sadd.sat.i5(i5 -1,i5 1)
 %wide3 = zext i5 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i5 @llvm.ssub.sat.i5(i5,i5)
define i64 @odd_saturation_5_1(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i5
 %y = trunc i64 %b to i5
 %v0 = call i5 @llvm.ssub.sat.i5(i5 %x,i5 %y)
 %wide0 = zext i5 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i5 @llvm.ssub.sat.i5(i5 -1,i5 %y)
 %wide1 = zext i5 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i5 @llvm.ssub.sat.i5(i5 %x,i5 1)
 %wide2 = zext i5 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i5 @llvm.ssub.sat.i5(i5 -1,i5 1)
 %wide3 = zext i5 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i6 @llvm.sadd.sat.i6(i6,i6)
define i64 @odd_saturation_6_0(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i6
 %y = trunc i64 %b to i6
 %v0 = call i6 @llvm.sadd.sat.i6(i6 %x,i6 %y)
 %wide0 = zext i6 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i6 @llvm.sadd.sat.i6(i6 -1,i6 %y)
 %wide1 = zext i6 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i6 @llvm.sadd.sat.i6(i6 %x,i6 1)
 %wide2 = zext i6 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i6 @llvm.sadd.sat.i6(i6 -1,i6 1)
 %wide3 = zext i6 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i6 @llvm.ssub.sat.i6(i6,i6)
define i64 @odd_saturation_6_1(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i6
 %y = trunc i64 %b to i6
 %v0 = call i6 @llvm.ssub.sat.i6(i6 %x,i6 %y)
 %wide0 = zext i6 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i6 @llvm.ssub.sat.i6(i6 -1,i6 %y)
 %wide1 = zext i6 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i6 @llvm.ssub.sat.i6(i6 %x,i6 1)
 %wide2 = zext i6 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i6 @llvm.ssub.sat.i6(i6 -1,i6 1)
 %wide3 = zext i6 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i7 @llvm.sadd.sat.i7(i7,i7)
define i64 @odd_saturation_7_0(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i7
 %y = trunc i64 %b to i7
 %v0 = call i7 @llvm.sadd.sat.i7(i7 %x,i7 %y)
 %wide0 = zext i7 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i7 @llvm.sadd.sat.i7(i7 -1,i7 %y)
 %wide1 = zext i7 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i7 @llvm.sadd.sat.i7(i7 %x,i7 1)
 %wide2 = zext i7 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i7 @llvm.sadd.sat.i7(i7 -1,i7 1)
 %wide3 = zext i7 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i7 @llvm.ssub.sat.i7(i7,i7)
define i64 @odd_saturation_7_1(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i7
 %y = trunc i64 %b to i7
 %v0 = call i7 @llvm.ssub.sat.i7(i7 %x,i7 %y)
 %wide0 = zext i7 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i7 @llvm.ssub.sat.i7(i7 -1,i7 %y)
 %wide1 = zext i7 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i7 @llvm.ssub.sat.i7(i7 %x,i7 1)
 %wide2 = zext i7 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i7 @llvm.ssub.sat.i7(i7 -1,i7 1)
 %wide3 = zext i7 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i8 @llvm.sadd.sat.i8(i8,i8)
define i64 @odd_saturation_8_0(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i8
 %y = trunc i64 %b to i8
 %v0 = call i8 @llvm.sadd.sat.i8(i8 %x,i8 %y)
 %wide0 = zext i8 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i8 @llvm.sadd.sat.i8(i8 -1,i8 %y)
 %wide1 = zext i8 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i8 @llvm.sadd.sat.i8(i8 %x,i8 1)
 %wide2 = zext i8 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i8 @llvm.sadd.sat.i8(i8 -1,i8 1)
 %wide3 = zext i8 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i8 @llvm.ssub.sat.i8(i8,i8)
define i64 @odd_saturation_8_1(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i8
 %y = trunc i64 %b to i8
 %v0 = call i8 @llvm.ssub.sat.i8(i8 %x,i8 %y)
 %wide0 = zext i8 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i8 @llvm.ssub.sat.i8(i8 -1,i8 %y)
 %wide1 = zext i8 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i8 @llvm.ssub.sat.i8(i8 %x,i8 1)
 %wide2 = zext i8 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i8 @llvm.ssub.sat.i8(i8 -1,i8 1)
 %wide3 = zext i8 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i9 @llvm.sadd.sat.i9(i9,i9)
define i64 @odd_saturation_9_0(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i9
 %y = trunc i64 %b to i9
 %v0 = call i9 @llvm.sadd.sat.i9(i9 %x,i9 %y)
 %wide0 = zext i9 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i9 @llvm.sadd.sat.i9(i9 -1,i9 %y)
 %wide1 = zext i9 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i9 @llvm.sadd.sat.i9(i9 %x,i9 1)
 %wide2 = zext i9 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i9 @llvm.sadd.sat.i9(i9 -1,i9 1)
 %wide3 = zext i9 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i9 @llvm.ssub.sat.i9(i9,i9)
define i64 @odd_saturation_9_1(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i9
 %y = trunc i64 %b to i9
 %v0 = call i9 @llvm.ssub.sat.i9(i9 %x,i9 %y)
 %wide0 = zext i9 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i9 @llvm.ssub.sat.i9(i9 -1,i9 %y)
 %wide1 = zext i9 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i9 @llvm.ssub.sat.i9(i9 %x,i9 1)
 %wide2 = zext i9 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i9 @llvm.ssub.sat.i9(i9 -1,i9 1)
 %wide3 = zext i9 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i10 @llvm.sadd.sat.i10(i10,i10)
define i64 @odd_saturation_10_0(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i10
 %y = trunc i64 %b to i10
 %v0 = call i10 @llvm.sadd.sat.i10(i10 %x,i10 %y)
 %wide0 = zext i10 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i10 @llvm.sadd.sat.i10(i10 -1,i10 %y)
 %wide1 = zext i10 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i10 @llvm.sadd.sat.i10(i10 %x,i10 1)
 %wide2 = zext i10 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i10 @llvm.sadd.sat.i10(i10 -1,i10 1)
 %wide3 = zext i10 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i10 @llvm.ssub.sat.i10(i10,i10)
define i64 @odd_saturation_10_1(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i10
 %y = trunc i64 %b to i10
 %v0 = call i10 @llvm.ssub.sat.i10(i10 %x,i10 %y)
 %wide0 = zext i10 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i10 @llvm.ssub.sat.i10(i10 -1,i10 %y)
 %wide1 = zext i10 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i10 @llvm.ssub.sat.i10(i10 %x,i10 1)
 %wide2 = zext i10 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i10 @llvm.ssub.sat.i10(i10 -1,i10 1)
 %wide3 = zext i10 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i11 @llvm.sadd.sat.i11(i11,i11)
define i64 @odd_saturation_11_0(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i11
 %y = trunc i64 %b to i11
 %v0 = call i11 @llvm.sadd.sat.i11(i11 %x,i11 %y)
 %wide0 = zext i11 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i11 @llvm.sadd.sat.i11(i11 -1,i11 %y)
 %wide1 = zext i11 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i11 @llvm.sadd.sat.i11(i11 %x,i11 1)
 %wide2 = zext i11 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i11 @llvm.sadd.sat.i11(i11 -1,i11 1)
 %wide3 = zext i11 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i11 @llvm.ssub.sat.i11(i11,i11)
define i64 @odd_saturation_11_1(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i11
 %y = trunc i64 %b to i11
 %v0 = call i11 @llvm.ssub.sat.i11(i11 %x,i11 %y)
 %wide0 = zext i11 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i11 @llvm.ssub.sat.i11(i11 -1,i11 %y)
 %wide1 = zext i11 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i11 @llvm.ssub.sat.i11(i11 %x,i11 1)
 %wide2 = zext i11 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i11 @llvm.ssub.sat.i11(i11 -1,i11 1)
 %wide3 = zext i11 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i12 @llvm.sadd.sat.i12(i12,i12)
define i64 @odd_saturation_12_0(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i12
 %y = trunc i64 %b to i12
 %v0 = call i12 @llvm.sadd.sat.i12(i12 %x,i12 %y)
 %wide0 = zext i12 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i12 @llvm.sadd.sat.i12(i12 -1,i12 %y)
 %wide1 = zext i12 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i12 @llvm.sadd.sat.i12(i12 %x,i12 1)
 %wide2 = zext i12 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i12 @llvm.sadd.sat.i12(i12 -1,i12 1)
 %wide3 = zext i12 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i12 @llvm.ssub.sat.i12(i12,i12)
define i64 @odd_saturation_12_1(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i12
 %y = trunc i64 %b to i12
 %v0 = call i12 @llvm.ssub.sat.i12(i12 %x,i12 %y)
 %wide0 = zext i12 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i12 @llvm.ssub.sat.i12(i12 -1,i12 %y)
 %wide1 = zext i12 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i12 @llvm.ssub.sat.i12(i12 %x,i12 1)
 %wide2 = zext i12 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i12 @llvm.ssub.sat.i12(i12 -1,i12 1)
 %wide3 = zext i12 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i13 @llvm.sadd.sat.i13(i13,i13)
define i64 @odd_saturation_13_0(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i13
 %y = trunc i64 %b to i13
 %v0 = call i13 @llvm.sadd.sat.i13(i13 %x,i13 %y)
 %wide0 = zext i13 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i13 @llvm.sadd.sat.i13(i13 -1,i13 %y)
 %wide1 = zext i13 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i13 @llvm.sadd.sat.i13(i13 %x,i13 1)
 %wide2 = zext i13 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i13 @llvm.sadd.sat.i13(i13 -1,i13 1)
 %wide3 = zext i13 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i13 @llvm.ssub.sat.i13(i13,i13)
define i64 @odd_saturation_13_1(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i13
 %y = trunc i64 %b to i13
 %v0 = call i13 @llvm.ssub.sat.i13(i13 %x,i13 %y)
 %wide0 = zext i13 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i13 @llvm.ssub.sat.i13(i13 -1,i13 %y)
 %wide1 = zext i13 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i13 @llvm.ssub.sat.i13(i13 %x,i13 1)
 %wide2 = zext i13 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i13 @llvm.ssub.sat.i13(i13 -1,i13 1)
 %wide3 = zext i13 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i14 @llvm.sadd.sat.i14(i14,i14)
define i64 @odd_saturation_14_0(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i14
 %y = trunc i64 %b to i14
 %v0 = call i14 @llvm.sadd.sat.i14(i14 %x,i14 %y)
 %wide0 = zext i14 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i14 @llvm.sadd.sat.i14(i14 -1,i14 %y)
 %wide1 = zext i14 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i14 @llvm.sadd.sat.i14(i14 %x,i14 1)
 %wide2 = zext i14 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i14 @llvm.sadd.sat.i14(i14 -1,i14 1)
 %wide3 = zext i14 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i14 @llvm.ssub.sat.i14(i14,i14)
define i64 @odd_saturation_14_1(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i14
 %y = trunc i64 %b to i14
 %v0 = call i14 @llvm.ssub.sat.i14(i14 %x,i14 %y)
 %wide0 = zext i14 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i14 @llvm.ssub.sat.i14(i14 -1,i14 %y)
 %wide1 = zext i14 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i14 @llvm.ssub.sat.i14(i14 %x,i14 1)
 %wide2 = zext i14 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i14 @llvm.ssub.sat.i14(i14 -1,i14 1)
 %wide3 = zext i14 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i15 @llvm.sadd.sat.i15(i15,i15)
define i64 @odd_saturation_15_0(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i15
 %y = trunc i64 %b to i15
 %v0 = call i15 @llvm.sadd.sat.i15(i15 %x,i15 %y)
 %wide0 = zext i15 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i15 @llvm.sadd.sat.i15(i15 -1,i15 %y)
 %wide1 = zext i15 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i15 @llvm.sadd.sat.i15(i15 %x,i15 1)
 %wide2 = zext i15 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i15 @llvm.sadd.sat.i15(i15 -1,i15 1)
 %wide3 = zext i15 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i15 @llvm.ssub.sat.i15(i15,i15)
define i64 @odd_saturation_15_1(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i15
 %y = trunc i64 %b to i15
 %v0 = call i15 @llvm.ssub.sat.i15(i15 %x,i15 %y)
 %wide0 = zext i15 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i15 @llvm.ssub.sat.i15(i15 -1,i15 %y)
 %wide1 = zext i15 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i15 @llvm.ssub.sat.i15(i15 %x,i15 1)
 %wide2 = zext i15 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i15 @llvm.ssub.sat.i15(i15 -1,i15 1)
 %wide3 = zext i15 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i16 @llvm.sadd.sat.i16(i16,i16)
define i64 @odd_saturation_16_0(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i16
 %y = trunc i64 %b to i16
 %v0 = call i16 @llvm.sadd.sat.i16(i16 %x,i16 %y)
 %wide0 = zext i16 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i16 @llvm.sadd.sat.i16(i16 -1,i16 %y)
 %wide1 = zext i16 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i16 @llvm.sadd.sat.i16(i16 %x,i16 1)
 %wide2 = zext i16 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i16 @llvm.sadd.sat.i16(i16 -1,i16 1)
 %wide3 = zext i16 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i16 @llvm.ssub.sat.i16(i16,i16)
define i64 @odd_saturation_16_1(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i16
 %y = trunc i64 %b to i16
 %v0 = call i16 @llvm.ssub.sat.i16(i16 %x,i16 %y)
 %wide0 = zext i16 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i16 @llvm.ssub.sat.i16(i16 -1,i16 %y)
 %wide1 = zext i16 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i16 @llvm.ssub.sat.i16(i16 %x,i16 1)
 %wide2 = zext i16 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i16 @llvm.ssub.sat.i16(i16 -1,i16 1)
 %wide3 = zext i16 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i17 @llvm.sadd.sat.i17(i17,i17)
define i64 @odd_saturation_17_0(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i17
 %y = trunc i64 %b to i17
 %v0 = call i17 @llvm.sadd.sat.i17(i17 %x,i17 %y)
 %wide0 = zext i17 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i17 @llvm.sadd.sat.i17(i17 -1,i17 %y)
 %wide1 = zext i17 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i17 @llvm.sadd.sat.i17(i17 %x,i17 1)
 %wide2 = zext i17 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i17 @llvm.sadd.sat.i17(i17 -1,i17 1)
 %wide3 = zext i17 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i17 @llvm.ssub.sat.i17(i17,i17)
define i64 @odd_saturation_17_1(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i17
 %y = trunc i64 %b to i17
 %v0 = call i17 @llvm.ssub.sat.i17(i17 %x,i17 %y)
 %wide0 = zext i17 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i17 @llvm.ssub.sat.i17(i17 -1,i17 %y)
 %wide1 = zext i17 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i17 @llvm.ssub.sat.i17(i17 %x,i17 1)
 %wide2 = zext i17 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i17 @llvm.ssub.sat.i17(i17 -1,i17 1)
 %wide3 = zext i17 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i18 @llvm.sadd.sat.i18(i18,i18)
define i64 @odd_saturation_18_0(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i18
 %y = trunc i64 %b to i18
 %v0 = call i18 @llvm.sadd.sat.i18(i18 %x,i18 %y)
 %wide0 = zext i18 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i18 @llvm.sadd.sat.i18(i18 -1,i18 %y)
 %wide1 = zext i18 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i18 @llvm.sadd.sat.i18(i18 %x,i18 1)
 %wide2 = zext i18 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i18 @llvm.sadd.sat.i18(i18 -1,i18 1)
 %wide3 = zext i18 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i18 @llvm.ssub.sat.i18(i18,i18)
define i64 @odd_saturation_18_1(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i18
 %y = trunc i64 %b to i18
 %v0 = call i18 @llvm.ssub.sat.i18(i18 %x,i18 %y)
 %wide0 = zext i18 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i18 @llvm.ssub.sat.i18(i18 -1,i18 %y)
 %wide1 = zext i18 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i18 @llvm.ssub.sat.i18(i18 %x,i18 1)
 %wide2 = zext i18 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i18 @llvm.ssub.sat.i18(i18 -1,i18 1)
 %wide3 = zext i18 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i19 @llvm.sadd.sat.i19(i19,i19)
define i64 @odd_saturation_19_0(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i19
 %y = trunc i64 %b to i19
 %v0 = call i19 @llvm.sadd.sat.i19(i19 %x,i19 %y)
 %wide0 = zext i19 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i19 @llvm.sadd.sat.i19(i19 -1,i19 %y)
 %wide1 = zext i19 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i19 @llvm.sadd.sat.i19(i19 %x,i19 1)
 %wide2 = zext i19 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i19 @llvm.sadd.sat.i19(i19 -1,i19 1)
 %wide3 = zext i19 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i19 @llvm.ssub.sat.i19(i19,i19)
define i64 @odd_saturation_19_1(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i19
 %y = trunc i64 %b to i19
 %v0 = call i19 @llvm.ssub.sat.i19(i19 %x,i19 %y)
 %wide0 = zext i19 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i19 @llvm.ssub.sat.i19(i19 -1,i19 %y)
 %wide1 = zext i19 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i19 @llvm.ssub.sat.i19(i19 %x,i19 1)
 %wide2 = zext i19 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i19 @llvm.ssub.sat.i19(i19 -1,i19 1)
 %wide3 = zext i19 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i20 @llvm.sadd.sat.i20(i20,i20)
define i64 @odd_saturation_20_0(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i20
 %y = trunc i64 %b to i20
 %v0 = call i20 @llvm.sadd.sat.i20(i20 %x,i20 %y)
 %wide0 = zext i20 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i20 @llvm.sadd.sat.i20(i20 -1,i20 %y)
 %wide1 = zext i20 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i20 @llvm.sadd.sat.i20(i20 %x,i20 1)
 %wide2 = zext i20 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i20 @llvm.sadd.sat.i20(i20 -1,i20 1)
 %wide3 = zext i20 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i20 @llvm.ssub.sat.i20(i20,i20)
define i64 @odd_saturation_20_1(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i20
 %y = trunc i64 %b to i20
 %v0 = call i20 @llvm.ssub.sat.i20(i20 %x,i20 %y)
 %wide0 = zext i20 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i20 @llvm.ssub.sat.i20(i20 -1,i20 %y)
 %wide1 = zext i20 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i20 @llvm.ssub.sat.i20(i20 %x,i20 1)
 %wide2 = zext i20 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i20 @llvm.ssub.sat.i20(i20 -1,i20 1)
 %wide3 = zext i20 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i21 @llvm.sadd.sat.i21(i21,i21)
define i64 @odd_saturation_21_0(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i21
 %y = trunc i64 %b to i21
 %v0 = call i21 @llvm.sadd.sat.i21(i21 %x,i21 %y)
 %wide0 = zext i21 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i21 @llvm.sadd.sat.i21(i21 -1,i21 %y)
 %wide1 = zext i21 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i21 @llvm.sadd.sat.i21(i21 %x,i21 1)
 %wide2 = zext i21 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i21 @llvm.sadd.sat.i21(i21 -1,i21 1)
 %wide3 = zext i21 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i21 @llvm.ssub.sat.i21(i21,i21)
define i64 @odd_saturation_21_1(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i21
 %y = trunc i64 %b to i21
 %v0 = call i21 @llvm.ssub.sat.i21(i21 %x,i21 %y)
 %wide0 = zext i21 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i21 @llvm.ssub.sat.i21(i21 -1,i21 %y)
 %wide1 = zext i21 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i21 @llvm.ssub.sat.i21(i21 %x,i21 1)
 %wide2 = zext i21 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i21 @llvm.ssub.sat.i21(i21 -1,i21 1)
 %wide3 = zext i21 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i22 @llvm.sadd.sat.i22(i22,i22)
define i64 @odd_saturation_22_0(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i22
 %y = trunc i64 %b to i22
 %v0 = call i22 @llvm.sadd.sat.i22(i22 %x,i22 %y)
 %wide0 = zext i22 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i22 @llvm.sadd.sat.i22(i22 -1,i22 %y)
 %wide1 = zext i22 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i22 @llvm.sadd.sat.i22(i22 %x,i22 1)
 %wide2 = zext i22 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i22 @llvm.sadd.sat.i22(i22 -1,i22 1)
 %wide3 = zext i22 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i22 @llvm.ssub.sat.i22(i22,i22)
define i64 @odd_saturation_22_1(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i22
 %y = trunc i64 %b to i22
 %v0 = call i22 @llvm.ssub.sat.i22(i22 %x,i22 %y)
 %wide0 = zext i22 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i22 @llvm.ssub.sat.i22(i22 -1,i22 %y)
 %wide1 = zext i22 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i22 @llvm.ssub.sat.i22(i22 %x,i22 1)
 %wide2 = zext i22 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i22 @llvm.ssub.sat.i22(i22 -1,i22 1)
 %wide3 = zext i22 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i23 @llvm.sadd.sat.i23(i23,i23)
define i64 @odd_saturation_23_0(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i23
 %y = trunc i64 %b to i23
 %v0 = call i23 @llvm.sadd.sat.i23(i23 %x,i23 %y)
 %wide0 = zext i23 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i23 @llvm.sadd.sat.i23(i23 -1,i23 %y)
 %wide1 = zext i23 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i23 @llvm.sadd.sat.i23(i23 %x,i23 1)
 %wide2 = zext i23 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i23 @llvm.sadd.sat.i23(i23 -1,i23 1)
 %wide3 = zext i23 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i23 @llvm.ssub.sat.i23(i23,i23)
define i64 @odd_saturation_23_1(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i23
 %y = trunc i64 %b to i23
 %v0 = call i23 @llvm.ssub.sat.i23(i23 %x,i23 %y)
 %wide0 = zext i23 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i23 @llvm.ssub.sat.i23(i23 -1,i23 %y)
 %wide1 = zext i23 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i23 @llvm.ssub.sat.i23(i23 %x,i23 1)
 %wide2 = zext i23 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i23 @llvm.ssub.sat.i23(i23 -1,i23 1)
 %wide3 = zext i23 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i24 @llvm.sadd.sat.i24(i24,i24)
define i64 @odd_saturation_24_0(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i24
 %y = trunc i64 %b to i24
 %v0 = call i24 @llvm.sadd.sat.i24(i24 %x,i24 %y)
 %wide0 = zext i24 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i24 @llvm.sadd.sat.i24(i24 -1,i24 %y)
 %wide1 = zext i24 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i24 @llvm.sadd.sat.i24(i24 %x,i24 1)
 %wide2 = zext i24 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i24 @llvm.sadd.sat.i24(i24 -1,i24 1)
 %wide3 = zext i24 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i24 @llvm.ssub.sat.i24(i24,i24)
define i64 @odd_saturation_24_1(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i24
 %y = trunc i64 %b to i24
 %v0 = call i24 @llvm.ssub.sat.i24(i24 %x,i24 %y)
 %wide0 = zext i24 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i24 @llvm.ssub.sat.i24(i24 -1,i24 %y)
 %wide1 = zext i24 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i24 @llvm.ssub.sat.i24(i24 %x,i24 1)
 %wide2 = zext i24 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i24 @llvm.ssub.sat.i24(i24 -1,i24 1)
 %wide3 = zext i24 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i25 @llvm.sadd.sat.i25(i25,i25)
define i64 @odd_saturation_25_0(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i25
 %y = trunc i64 %b to i25
 %v0 = call i25 @llvm.sadd.sat.i25(i25 %x,i25 %y)
 %wide0 = zext i25 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i25 @llvm.sadd.sat.i25(i25 -1,i25 %y)
 %wide1 = zext i25 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i25 @llvm.sadd.sat.i25(i25 %x,i25 1)
 %wide2 = zext i25 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i25 @llvm.sadd.sat.i25(i25 -1,i25 1)
 %wide3 = zext i25 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i25 @llvm.ssub.sat.i25(i25,i25)
define i64 @odd_saturation_25_1(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i25
 %y = trunc i64 %b to i25
 %v0 = call i25 @llvm.ssub.sat.i25(i25 %x,i25 %y)
 %wide0 = zext i25 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i25 @llvm.ssub.sat.i25(i25 -1,i25 %y)
 %wide1 = zext i25 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i25 @llvm.ssub.sat.i25(i25 %x,i25 1)
 %wide2 = zext i25 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i25 @llvm.ssub.sat.i25(i25 -1,i25 1)
 %wide3 = zext i25 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i26 @llvm.sadd.sat.i26(i26,i26)
define i64 @odd_saturation_26_0(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i26
 %y = trunc i64 %b to i26
 %v0 = call i26 @llvm.sadd.sat.i26(i26 %x,i26 %y)
 %wide0 = zext i26 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i26 @llvm.sadd.sat.i26(i26 -1,i26 %y)
 %wide1 = zext i26 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i26 @llvm.sadd.sat.i26(i26 %x,i26 1)
 %wide2 = zext i26 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i26 @llvm.sadd.sat.i26(i26 -1,i26 1)
 %wide3 = zext i26 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i26 @llvm.ssub.sat.i26(i26,i26)
define i64 @odd_saturation_26_1(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i26
 %y = trunc i64 %b to i26
 %v0 = call i26 @llvm.ssub.sat.i26(i26 %x,i26 %y)
 %wide0 = zext i26 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i26 @llvm.ssub.sat.i26(i26 -1,i26 %y)
 %wide1 = zext i26 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i26 @llvm.ssub.sat.i26(i26 %x,i26 1)
 %wide2 = zext i26 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i26 @llvm.ssub.sat.i26(i26 -1,i26 1)
 %wide3 = zext i26 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i27 @llvm.sadd.sat.i27(i27,i27)
define i64 @odd_saturation_27_0(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i27
 %y = trunc i64 %b to i27
 %v0 = call i27 @llvm.sadd.sat.i27(i27 %x,i27 %y)
 %wide0 = zext i27 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i27 @llvm.sadd.sat.i27(i27 -1,i27 %y)
 %wide1 = zext i27 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i27 @llvm.sadd.sat.i27(i27 %x,i27 1)
 %wide2 = zext i27 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i27 @llvm.sadd.sat.i27(i27 -1,i27 1)
 %wide3 = zext i27 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i27 @llvm.ssub.sat.i27(i27,i27)
define i64 @odd_saturation_27_1(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i27
 %y = trunc i64 %b to i27
 %v0 = call i27 @llvm.ssub.sat.i27(i27 %x,i27 %y)
 %wide0 = zext i27 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i27 @llvm.ssub.sat.i27(i27 -1,i27 %y)
 %wide1 = zext i27 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i27 @llvm.ssub.sat.i27(i27 %x,i27 1)
 %wide2 = zext i27 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i27 @llvm.ssub.sat.i27(i27 -1,i27 1)
 %wide3 = zext i27 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i28 @llvm.sadd.sat.i28(i28,i28)
define i64 @odd_saturation_28_0(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i28
 %y = trunc i64 %b to i28
 %v0 = call i28 @llvm.sadd.sat.i28(i28 %x,i28 %y)
 %wide0 = zext i28 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i28 @llvm.sadd.sat.i28(i28 -1,i28 %y)
 %wide1 = zext i28 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i28 @llvm.sadd.sat.i28(i28 %x,i28 1)
 %wide2 = zext i28 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i28 @llvm.sadd.sat.i28(i28 -1,i28 1)
 %wide3 = zext i28 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i28 @llvm.ssub.sat.i28(i28,i28)
define i64 @odd_saturation_28_1(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i28
 %y = trunc i64 %b to i28
 %v0 = call i28 @llvm.ssub.sat.i28(i28 %x,i28 %y)
 %wide0 = zext i28 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i28 @llvm.ssub.sat.i28(i28 -1,i28 %y)
 %wide1 = zext i28 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i28 @llvm.ssub.sat.i28(i28 %x,i28 1)
 %wide2 = zext i28 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i28 @llvm.ssub.sat.i28(i28 -1,i28 1)
 %wide3 = zext i28 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i29 @llvm.sadd.sat.i29(i29,i29)
define i64 @odd_saturation_29_0(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i29
 %y = trunc i64 %b to i29
 %v0 = call i29 @llvm.sadd.sat.i29(i29 %x,i29 %y)
 %wide0 = zext i29 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i29 @llvm.sadd.sat.i29(i29 -1,i29 %y)
 %wide1 = zext i29 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i29 @llvm.sadd.sat.i29(i29 %x,i29 1)
 %wide2 = zext i29 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i29 @llvm.sadd.sat.i29(i29 -1,i29 1)
 %wide3 = zext i29 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i29 @llvm.ssub.sat.i29(i29,i29)
define i64 @odd_saturation_29_1(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i29
 %y = trunc i64 %b to i29
 %v0 = call i29 @llvm.ssub.sat.i29(i29 %x,i29 %y)
 %wide0 = zext i29 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i29 @llvm.ssub.sat.i29(i29 -1,i29 %y)
 %wide1 = zext i29 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i29 @llvm.ssub.sat.i29(i29 %x,i29 1)
 %wide2 = zext i29 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i29 @llvm.ssub.sat.i29(i29 -1,i29 1)
 %wide3 = zext i29 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i30 @llvm.sadd.sat.i30(i30,i30)
define i64 @odd_saturation_30_0(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i30
 %y = trunc i64 %b to i30
 %v0 = call i30 @llvm.sadd.sat.i30(i30 %x,i30 %y)
 %wide0 = zext i30 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i30 @llvm.sadd.sat.i30(i30 -1,i30 %y)
 %wide1 = zext i30 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i30 @llvm.sadd.sat.i30(i30 %x,i30 1)
 %wide2 = zext i30 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i30 @llvm.sadd.sat.i30(i30 -1,i30 1)
 %wide3 = zext i30 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i30 @llvm.ssub.sat.i30(i30,i30)
define i64 @odd_saturation_30_1(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i30
 %y = trunc i64 %b to i30
 %v0 = call i30 @llvm.ssub.sat.i30(i30 %x,i30 %y)
 %wide0 = zext i30 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i30 @llvm.ssub.sat.i30(i30 -1,i30 %y)
 %wide1 = zext i30 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i30 @llvm.ssub.sat.i30(i30 %x,i30 1)
 %wide2 = zext i30 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i30 @llvm.ssub.sat.i30(i30 -1,i30 1)
 %wide3 = zext i30 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i31 @llvm.sadd.sat.i31(i31,i31)
define i64 @odd_saturation_31_0(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i31
 %y = trunc i64 %b to i31
 %v0 = call i31 @llvm.sadd.sat.i31(i31 %x,i31 %y)
 %wide0 = zext i31 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i31 @llvm.sadd.sat.i31(i31 -1,i31 %y)
 %wide1 = zext i31 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i31 @llvm.sadd.sat.i31(i31 %x,i31 1)
 %wide2 = zext i31 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i31 @llvm.sadd.sat.i31(i31 -1,i31 1)
 %wide3 = zext i31 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i31 @llvm.ssub.sat.i31(i31,i31)
define i64 @odd_saturation_31_1(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i31
 %y = trunc i64 %b to i31
 %v0 = call i31 @llvm.ssub.sat.i31(i31 %x,i31 %y)
 %wide0 = zext i31 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i31 @llvm.ssub.sat.i31(i31 -1,i31 %y)
 %wide1 = zext i31 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i31 @llvm.ssub.sat.i31(i31 %x,i31 1)
 %wide2 = zext i31 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i31 @llvm.ssub.sat.i31(i31 -1,i31 1)
 %wide3 = zext i31 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i32 @llvm.sadd.sat.i32(i32,i32)
define i64 @odd_saturation_32_0(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i32
 %y = trunc i64 %b to i32
 %v0 = call i32 @llvm.sadd.sat.i32(i32 %x,i32 %y)
 %wide0 = zext i32 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i32 @llvm.sadd.sat.i32(i32 -1,i32 %y)
 %wide1 = zext i32 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i32 @llvm.sadd.sat.i32(i32 %x,i32 1)
 %wide2 = zext i32 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i32 @llvm.sadd.sat.i32(i32 -1,i32 1)
 %wide3 = zext i32 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i32 @llvm.ssub.sat.i32(i32,i32)
define i64 @odd_saturation_32_1(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i32
 %y = trunc i64 %b to i32
 %v0 = call i32 @llvm.ssub.sat.i32(i32 %x,i32 %y)
 %wide0 = zext i32 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i32 @llvm.ssub.sat.i32(i32 -1,i32 %y)
 %wide1 = zext i32 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i32 @llvm.ssub.sat.i32(i32 %x,i32 1)
 %wide2 = zext i32 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i32 @llvm.ssub.sat.i32(i32 -1,i32 1)
 %wide3 = zext i32 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i33 @llvm.sadd.sat.i33(i33,i33)
define i64 @odd_saturation_33_0(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i33
 %y = trunc i64 %b to i33
 %v0 = call i33 @llvm.sadd.sat.i33(i33 %x,i33 %y)
 %wide0 = zext i33 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i33 @llvm.sadd.sat.i33(i33 -1,i33 %y)
 %wide1 = zext i33 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i33 @llvm.sadd.sat.i33(i33 %x,i33 1)
 %wide2 = zext i33 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i33 @llvm.sadd.sat.i33(i33 -1,i33 1)
 %wide3 = zext i33 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i33 @llvm.ssub.sat.i33(i33,i33)
define i64 @odd_saturation_33_1(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i33
 %y = trunc i64 %b to i33
 %v0 = call i33 @llvm.ssub.sat.i33(i33 %x,i33 %y)
 %wide0 = zext i33 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i33 @llvm.ssub.sat.i33(i33 -1,i33 %y)
 %wide1 = zext i33 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i33 @llvm.ssub.sat.i33(i33 %x,i33 1)
 %wide2 = zext i33 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i33 @llvm.ssub.sat.i33(i33 -1,i33 1)
 %wide3 = zext i33 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i34 @llvm.sadd.sat.i34(i34,i34)
define i64 @odd_saturation_34_0(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i34
 %y = trunc i64 %b to i34
 %v0 = call i34 @llvm.sadd.sat.i34(i34 %x,i34 %y)
 %wide0 = zext i34 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i34 @llvm.sadd.sat.i34(i34 -1,i34 %y)
 %wide1 = zext i34 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i34 @llvm.sadd.sat.i34(i34 %x,i34 1)
 %wide2 = zext i34 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i34 @llvm.sadd.sat.i34(i34 -1,i34 1)
 %wide3 = zext i34 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i34 @llvm.ssub.sat.i34(i34,i34)
define i64 @odd_saturation_34_1(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i34
 %y = trunc i64 %b to i34
 %v0 = call i34 @llvm.ssub.sat.i34(i34 %x,i34 %y)
 %wide0 = zext i34 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i34 @llvm.ssub.sat.i34(i34 -1,i34 %y)
 %wide1 = zext i34 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i34 @llvm.ssub.sat.i34(i34 %x,i34 1)
 %wide2 = zext i34 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i34 @llvm.ssub.sat.i34(i34 -1,i34 1)
 %wide3 = zext i34 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i35 @llvm.sadd.sat.i35(i35,i35)
define i64 @odd_saturation_35_0(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i35
 %y = trunc i64 %b to i35
 %v0 = call i35 @llvm.sadd.sat.i35(i35 %x,i35 %y)
 %wide0 = zext i35 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i35 @llvm.sadd.sat.i35(i35 -1,i35 %y)
 %wide1 = zext i35 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i35 @llvm.sadd.sat.i35(i35 %x,i35 1)
 %wide2 = zext i35 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i35 @llvm.sadd.sat.i35(i35 -1,i35 1)
 %wide3 = zext i35 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i35 @llvm.ssub.sat.i35(i35,i35)
define i64 @odd_saturation_35_1(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i35
 %y = trunc i64 %b to i35
 %v0 = call i35 @llvm.ssub.sat.i35(i35 %x,i35 %y)
 %wide0 = zext i35 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i35 @llvm.ssub.sat.i35(i35 -1,i35 %y)
 %wide1 = zext i35 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i35 @llvm.ssub.sat.i35(i35 %x,i35 1)
 %wide2 = zext i35 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i35 @llvm.ssub.sat.i35(i35 -1,i35 1)
 %wide3 = zext i35 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i36 @llvm.sadd.sat.i36(i36,i36)
define i64 @odd_saturation_36_0(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i36
 %y = trunc i64 %b to i36
 %v0 = call i36 @llvm.sadd.sat.i36(i36 %x,i36 %y)
 %wide0 = zext i36 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i36 @llvm.sadd.sat.i36(i36 -1,i36 %y)
 %wide1 = zext i36 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i36 @llvm.sadd.sat.i36(i36 %x,i36 1)
 %wide2 = zext i36 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i36 @llvm.sadd.sat.i36(i36 -1,i36 1)
 %wide3 = zext i36 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i36 @llvm.ssub.sat.i36(i36,i36)
define i64 @odd_saturation_36_1(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i36
 %y = trunc i64 %b to i36
 %v0 = call i36 @llvm.ssub.sat.i36(i36 %x,i36 %y)
 %wide0 = zext i36 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i36 @llvm.ssub.sat.i36(i36 -1,i36 %y)
 %wide1 = zext i36 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i36 @llvm.ssub.sat.i36(i36 %x,i36 1)
 %wide2 = zext i36 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i36 @llvm.ssub.sat.i36(i36 -1,i36 1)
 %wide3 = zext i36 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i37 @llvm.sadd.sat.i37(i37,i37)
define i64 @odd_saturation_37_0(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i37
 %y = trunc i64 %b to i37
 %v0 = call i37 @llvm.sadd.sat.i37(i37 %x,i37 %y)
 %wide0 = zext i37 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i37 @llvm.sadd.sat.i37(i37 -1,i37 %y)
 %wide1 = zext i37 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i37 @llvm.sadd.sat.i37(i37 %x,i37 1)
 %wide2 = zext i37 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i37 @llvm.sadd.sat.i37(i37 -1,i37 1)
 %wide3 = zext i37 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i37 @llvm.ssub.sat.i37(i37,i37)
define i64 @odd_saturation_37_1(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i37
 %y = trunc i64 %b to i37
 %v0 = call i37 @llvm.ssub.sat.i37(i37 %x,i37 %y)
 %wide0 = zext i37 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i37 @llvm.ssub.sat.i37(i37 -1,i37 %y)
 %wide1 = zext i37 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i37 @llvm.ssub.sat.i37(i37 %x,i37 1)
 %wide2 = zext i37 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i37 @llvm.ssub.sat.i37(i37 -1,i37 1)
 %wide3 = zext i37 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i38 @llvm.sadd.sat.i38(i38,i38)
define i64 @odd_saturation_38_0(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i38
 %y = trunc i64 %b to i38
 %v0 = call i38 @llvm.sadd.sat.i38(i38 %x,i38 %y)
 %wide0 = zext i38 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i38 @llvm.sadd.sat.i38(i38 -1,i38 %y)
 %wide1 = zext i38 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i38 @llvm.sadd.sat.i38(i38 %x,i38 1)
 %wide2 = zext i38 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i38 @llvm.sadd.sat.i38(i38 -1,i38 1)
 %wide3 = zext i38 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i38 @llvm.ssub.sat.i38(i38,i38)
define i64 @odd_saturation_38_1(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i38
 %y = trunc i64 %b to i38
 %v0 = call i38 @llvm.ssub.sat.i38(i38 %x,i38 %y)
 %wide0 = zext i38 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i38 @llvm.ssub.sat.i38(i38 -1,i38 %y)
 %wide1 = zext i38 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i38 @llvm.ssub.sat.i38(i38 %x,i38 1)
 %wide2 = zext i38 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i38 @llvm.ssub.sat.i38(i38 -1,i38 1)
 %wide3 = zext i38 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i39 @llvm.sadd.sat.i39(i39,i39)
define i64 @odd_saturation_39_0(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i39
 %y = trunc i64 %b to i39
 %v0 = call i39 @llvm.sadd.sat.i39(i39 %x,i39 %y)
 %wide0 = zext i39 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i39 @llvm.sadd.sat.i39(i39 -1,i39 %y)
 %wide1 = zext i39 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i39 @llvm.sadd.sat.i39(i39 %x,i39 1)
 %wide2 = zext i39 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i39 @llvm.sadd.sat.i39(i39 -1,i39 1)
 %wide3 = zext i39 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i39 @llvm.ssub.sat.i39(i39,i39)
define i64 @odd_saturation_39_1(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i39
 %y = trunc i64 %b to i39
 %v0 = call i39 @llvm.ssub.sat.i39(i39 %x,i39 %y)
 %wide0 = zext i39 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i39 @llvm.ssub.sat.i39(i39 -1,i39 %y)
 %wide1 = zext i39 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i39 @llvm.ssub.sat.i39(i39 %x,i39 1)
 %wide2 = zext i39 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i39 @llvm.ssub.sat.i39(i39 -1,i39 1)
 %wide3 = zext i39 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i40 @llvm.sadd.sat.i40(i40,i40)
define i64 @odd_saturation_40_0(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i40
 %y = trunc i64 %b to i40
 %v0 = call i40 @llvm.sadd.sat.i40(i40 %x,i40 %y)
 %wide0 = zext i40 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i40 @llvm.sadd.sat.i40(i40 -1,i40 %y)
 %wide1 = zext i40 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i40 @llvm.sadd.sat.i40(i40 %x,i40 1)
 %wide2 = zext i40 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i40 @llvm.sadd.sat.i40(i40 -1,i40 1)
 %wide3 = zext i40 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i40 @llvm.ssub.sat.i40(i40,i40)
define i64 @odd_saturation_40_1(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i40
 %y = trunc i64 %b to i40
 %v0 = call i40 @llvm.ssub.sat.i40(i40 %x,i40 %y)
 %wide0 = zext i40 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i40 @llvm.ssub.sat.i40(i40 -1,i40 %y)
 %wide1 = zext i40 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i40 @llvm.ssub.sat.i40(i40 %x,i40 1)
 %wide2 = zext i40 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i40 @llvm.ssub.sat.i40(i40 -1,i40 1)
 %wide3 = zext i40 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i41 @llvm.sadd.sat.i41(i41,i41)
define i64 @odd_saturation_41_0(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i41
 %y = trunc i64 %b to i41
 %v0 = call i41 @llvm.sadd.sat.i41(i41 %x,i41 %y)
 %wide0 = zext i41 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i41 @llvm.sadd.sat.i41(i41 -1,i41 %y)
 %wide1 = zext i41 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i41 @llvm.sadd.sat.i41(i41 %x,i41 1)
 %wide2 = zext i41 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i41 @llvm.sadd.sat.i41(i41 -1,i41 1)
 %wide3 = zext i41 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i41 @llvm.ssub.sat.i41(i41,i41)
define i64 @odd_saturation_41_1(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i41
 %y = trunc i64 %b to i41
 %v0 = call i41 @llvm.ssub.sat.i41(i41 %x,i41 %y)
 %wide0 = zext i41 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i41 @llvm.ssub.sat.i41(i41 -1,i41 %y)
 %wide1 = zext i41 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i41 @llvm.ssub.sat.i41(i41 %x,i41 1)
 %wide2 = zext i41 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i41 @llvm.ssub.sat.i41(i41 -1,i41 1)
 %wide3 = zext i41 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i42 @llvm.sadd.sat.i42(i42,i42)
define i64 @odd_saturation_42_0(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i42
 %y = trunc i64 %b to i42
 %v0 = call i42 @llvm.sadd.sat.i42(i42 %x,i42 %y)
 %wide0 = zext i42 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i42 @llvm.sadd.sat.i42(i42 -1,i42 %y)
 %wide1 = zext i42 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i42 @llvm.sadd.sat.i42(i42 %x,i42 1)
 %wide2 = zext i42 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i42 @llvm.sadd.sat.i42(i42 -1,i42 1)
 %wide3 = zext i42 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i42 @llvm.ssub.sat.i42(i42,i42)
define i64 @odd_saturation_42_1(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i42
 %y = trunc i64 %b to i42
 %v0 = call i42 @llvm.ssub.sat.i42(i42 %x,i42 %y)
 %wide0 = zext i42 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i42 @llvm.ssub.sat.i42(i42 -1,i42 %y)
 %wide1 = zext i42 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i42 @llvm.ssub.sat.i42(i42 %x,i42 1)
 %wide2 = zext i42 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i42 @llvm.ssub.sat.i42(i42 -1,i42 1)
 %wide3 = zext i42 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i43 @llvm.sadd.sat.i43(i43,i43)
define i64 @odd_saturation_43_0(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i43
 %y = trunc i64 %b to i43
 %v0 = call i43 @llvm.sadd.sat.i43(i43 %x,i43 %y)
 %wide0 = zext i43 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i43 @llvm.sadd.sat.i43(i43 -1,i43 %y)
 %wide1 = zext i43 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i43 @llvm.sadd.sat.i43(i43 %x,i43 1)
 %wide2 = zext i43 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i43 @llvm.sadd.sat.i43(i43 -1,i43 1)
 %wide3 = zext i43 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i43 @llvm.ssub.sat.i43(i43,i43)
define i64 @odd_saturation_43_1(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i43
 %y = trunc i64 %b to i43
 %v0 = call i43 @llvm.ssub.sat.i43(i43 %x,i43 %y)
 %wide0 = zext i43 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i43 @llvm.ssub.sat.i43(i43 -1,i43 %y)
 %wide1 = zext i43 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i43 @llvm.ssub.sat.i43(i43 %x,i43 1)
 %wide2 = zext i43 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i43 @llvm.ssub.sat.i43(i43 -1,i43 1)
 %wide3 = zext i43 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i44 @llvm.sadd.sat.i44(i44,i44)
define i64 @odd_saturation_44_0(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i44
 %y = trunc i64 %b to i44
 %v0 = call i44 @llvm.sadd.sat.i44(i44 %x,i44 %y)
 %wide0 = zext i44 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i44 @llvm.sadd.sat.i44(i44 -1,i44 %y)
 %wide1 = zext i44 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i44 @llvm.sadd.sat.i44(i44 %x,i44 1)
 %wide2 = zext i44 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i44 @llvm.sadd.sat.i44(i44 -1,i44 1)
 %wide3 = zext i44 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i44 @llvm.ssub.sat.i44(i44,i44)
define i64 @odd_saturation_44_1(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i44
 %y = trunc i64 %b to i44
 %v0 = call i44 @llvm.ssub.sat.i44(i44 %x,i44 %y)
 %wide0 = zext i44 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i44 @llvm.ssub.sat.i44(i44 -1,i44 %y)
 %wide1 = zext i44 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i44 @llvm.ssub.sat.i44(i44 %x,i44 1)
 %wide2 = zext i44 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i44 @llvm.ssub.sat.i44(i44 -1,i44 1)
 %wide3 = zext i44 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i45 @llvm.sadd.sat.i45(i45,i45)
define i64 @odd_saturation_45_0(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i45
 %y = trunc i64 %b to i45
 %v0 = call i45 @llvm.sadd.sat.i45(i45 %x,i45 %y)
 %wide0 = zext i45 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i45 @llvm.sadd.sat.i45(i45 -1,i45 %y)
 %wide1 = zext i45 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i45 @llvm.sadd.sat.i45(i45 %x,i45 1)
 %wide2 = zext i45 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i45 @llvm.sadd.sat.i45(i45 -1,i45 1)
 %wide3 = zext i45 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i45 @llvm.ssub.sat.i45(i45,i45)
define i64 @odd_saturation_45_1(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i45
 %y = trunc i64 %b to i45
 %v0 = call i45 @llvm.ssub.sat.i45(i45 %x,i45 %y)
 %wide0 = zext i45 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i45 @llvm.ssub.sat.i45(i45 -1,i45 %y)
 %wide1 = zext i45 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i45 @llvm.ssub.sat.i45(i45 %x,i45 1)
 %wide2 = zext i45 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i45 @llvm.ssub.sat.i45(i45 -1,i45 1)
 %wide3 = zext i45 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i46 @llvm.sadd.sat.i46(i46,i46)
define i64 @odd_saturation_46_0(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i46
 %y = trunc i64 %b to i46
 %v0 = call i46 @llvm.sadd.sat.i46(i46 %x,i46 %y)
 %wide0 = zext i46 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i46 @llvm.sadd.sat.i46(i46 -1,i46 %y)
 %wide1 = zext i46 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i46 @llvm.sadd.sat.i46(i46 %x,i46 1)
 %wide2 = zext i46 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i46 @llvm.sadd.sat.i46(i46 -1,i46 1)
 %wide3 = zext i46 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i46 @llvm.ssub.sat.i46(i46,i46)
define i64 @odd_saturation_46_1(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i46
 %y = trunc i64 %b to i46
 %v0 = call i46 @llvm.ssub.sat.i46(i46 %x,i46 %y)
 %wide0 = zext i46 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i46 @llvm.ssub.sat.i46(i46 -1,i46 %y)
 %wide1 = zext i46 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i46 @llvm.ssub.sat.i46(i46 %x,i46 1)
 %wide2 = zext i46 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i46 @llvm.ssub.sat.i46(i46 -1,i46 1)
 %wide3 = zext i46 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i47 @llvm.sadd.sat.i47(i47,i47)
define i64 @odd_saturation_47_0(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i47
 %y = trunc i64 %b to i47
 %v0 = call i47 @llvm.sadd.sat.i47(i47 %x,i47 %y)
 %wide0 = zext i47 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i47 @llvm.sadd.sat.i47(i47 -1,i47 %y)
 %wide1 = zext i47 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i47 @llvm.sadd.sat.i47(i47 %x,i47 1)
 %wide2 = zext i47 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i47 @llvm.sadd.sat.i47(i47 -1,i47 1)
 %wide3 = zext i47 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i47 @llvm.ssub.sat.i47(i47,i47)
define i64 @odd_saturation_47_1(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i47
 %y = trunc i64 %b to i47
 %v0 = call i47 @llvm.ssub.sat.i47(i47 %x,i47 %y)
 %wide0 = zext i47 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i47 @llvm.ssub.sat.i47(i47 -1,i47 %y)
 %wide1 = zext i47 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i47 @llvm.ssub.sat.i47(i47 %x,i47 1)
 %wide2 = zext i47 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i47 @llvm.ssub.sat.i47(i47 -1,i47 1)
 %wide3 = zext i47 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i48 @llvm.sadd.sat.i48(i48,i48)
define i64 @odd_saturation_48_0(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i48
 %y = trunc i64 %b to i48
 %v0 = call i48 @llvm.sadd.sat.i48(i48 %x,i48 %y)
 %wide0 = zext i48 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i48 @llvm.sadd.sat.i48(i48 -1,i48 %y)
 %wide1 = zext i48 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i48 @llvm.sadd.sat.i48(i48 %x,i48 1)
 %wide2 = zext i48 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i48 @llvm.sadd.sat.i48(i48 -1,i48 1)
 %wide3 = zext i48 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i48 @llvm.ssub.sat.i48(i48,i48)
define i64 @odd_saturation_48_1(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i48
 %y = trunc i64 %b to i48
 %v0 = call i48 @llvm.ssub.sat.i48(i48 %x,i48 %y)
 %wide0 = zext i48 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i48 @llvm.ssub.sat.i48(i48 -1,i48 %y)
 %wide1 = zext i48 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i48 @llvm.ssub.sat.i48(i48 %x,i48 1)
 %wide2 = zext i48 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i48 @llvm.ssub.sat.i48(i48 -1,i48 1)
 %wide3 = zext i48 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i49 @llvm.sadd.sat.i49(i49,i49)
define i64 @odd_saturation_49_0(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i49
 %y = trunc i64 %b to i49
 %v0 = call i49 @llvm.sadd.sat.i49(i49 %x,i49 %y)
 %wide0 = zext i49 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i49 @llvm.sadd.sat.i49(i49 -1,i49 %y)
 %wide1 = zext i49 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i49 @llvm.sadd.sat.i49(i49 %x,i49 1)
 %wide2 = zext i49 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i49 @llvm.sadd.sat.i49(i49 -1,i49 1)
 %wide3 = zext i49 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i49 @llvm.ssub.sat.i49(i49,i49)
define i64 @odd_saturation_49_1(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i49
 %y = trunc i64 %b to i49
 %v0 = call i49 @llvm.ssub.sat.i49(i49 %x,i49 %y)
 %wide0 = zext i49 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i49 @llvm.ssub.sat.i49(i49 -1,i49 %y)
 %wide1 = zext i49 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i49 @llvm.ssub.sat.i49(i49 %x,i49 1)
 %wide2 = zext i49 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i49 @llvm.ssub.sat.i49(i49 -1,i49 1)
 %wide3 = zext i49 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i50 @llvm.sadd.sat.i50(i50,i50)
define i64 @odd_saturation_50_0(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i50
 %y = trunc i64 %b to i50
 %v0 = call i50 @llvm.sadd.sat.i50(i50 %x,i50 %y)
 %wide0 = zext i50 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i50 @llvm.sadd.sat.i50(i50 -1,i50 %y)
 %wide1 = zext i50 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i50 @llvm.sadd.sat.i50(i50 %x,i50 1)
 %wide2 = zext i50 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i50 @llvm.sadd.sat.i50(i50 -1,i50 1)
 %wide3 = zext i50 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i50 @llvm.ssub.sat.i50(i50,i50)
define i64 @odd_saturation_50_1(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i50
 %y = trunc i64 %b to i50
 %v0 = call i50 @llvm.ssub.sat.i50(i50 %x,i50 %y)
 %wide0 = zext i50 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i50 @llvm.ssub.sat.i50(i50 -1,i50 %y)
 %wide1 = zext i50 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i50 @llvm.ssub.sat.i50(i50 %x,i50 1)
 %wide2 = zext i50 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i50 @llvm.ssub.sat.i50(i50 -1,i50 1)
 %wide3 = zext i50 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i53 @llvm.sadd.sat.i53(i53,i53)
define i64 @odd_saturation_53_0(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i53
 %y = trunc i64 %b to i53
 %v0 = call i53 @llvm.sadd.sat.i53(i53 %x,i53 %y)
 %wide0 = zext i53 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i53 @llvm.sadd.sat.i53(i53 -1,i53 %y)
 %wide1 = zext i53 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i53 @llvm.sadd.sat.i53(i53 %x,i53 1)
 %wide2 = zext i53 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i53 @llvm.sadd.sat.i53(i53 -1,i53 1)
 %wide3 = zext i53 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i53 @llvm.ssub.sat.i53(i53,i53)
define i64 @odd_saturation_53_1(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i53
 %y = trunc i64 %b to i53
 %v0 = call i53 @llvm.ssub.sat.i53(i53 %x,i53 %y)
 %wide0 = zext i53 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i53 @llvm.ssub.sat.i53(i53 -1,i53 %y)
 %wide1 = zext i53 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i53 @llvm.ssub.sat.i53(i53 %x,i53 1)
 %wide2 = zext i53 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i53 @llvm.ssub.sat.i53(i53 -1,i53 1)
 %wide3 = zext i53 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i54 @llvm.sadd.sat.i54(i54,i54)
define i64 @odd_saturation_54_0(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i54
 %y = trunc i64 %b to i54
 %v0 = call i54 @llvm.sadd.sat.i54(i54 %x,i54 %y)
 %wide0 = zext i54 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i54 @llvm.sadd.sat.i54(i54 -1,i54 %y)
 %wide1 = zext i54 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i54 @llvm.sadd.sat.i54(i54 %x,i54 1)
 %wide2 = zext i54 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i54 @llvm.sadd.sat.i54(i54 -1,i54 1)
 %wide3 = zext i54 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i54 @llvm.ssub.sat.i54(i54,i54)
define i64 @odd_saturation_54_1(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i54
 %y = trunc i64 %b to i54
 %v0 = call i54 @llvm.ssub.sat.i54(i54 %x,i54 %y)
 %wide0 = zext i54 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i54 @llvm.ssub.sat.i54(i54 -1,i54 %y)
 %wide1 = zext i54 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i54 @llvm.ssub.sat.i54(i54 %x,i54 1)
 %wide2 = zext i54 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i54 @llvm.ssub.sat.i54(i54 -1,i54 1)
 %wide3 = zext i54 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i55 @llvm.sadd.sat.i55(i55,i55)
define i64 @odd_saturation_55_0(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i55
 %y = trunc i64 %b to i55
 %v0 = call i55 @llvm.sadd.sat.i55(i55 %x,i55 %y)
 %wide0 = zext i55 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i55 @llvm.sadd.sat.i55(i55 -1,i55 %y)
 %wide1 = zext i55 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i55 @llvm.sadd.sat.i55(i55 %x,i55 1)
 %wide2 = zext i55 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i55 @llvm.sadd.sat.i55(i55 -1,i55 1)
 %wide3 = zext i55 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i55 @llvm.ssub.sat.i55(i55,i55)
define i64 @odd_saturation_55_1(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i55
 %y = trunc i64 %b to i55
 %v0 = call i55 @llvm.ssub.sat.i55(i55 %x,i55 %y)
 %wide0 = zext i55 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i55 @llvm.ssub.sat.i55(i55 -1,i55 %y)
 %wide1 = zext i55 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i55 @llvm.ssub.sat.i55(i55 %x,i55 1)
 %wide2 = zext i55 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i55 @llvm.ssub.sat.i55(i55 -1,i55 1)
 %wide3 = zext i55 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i56 @llvm.sadd.sat.i56(i56,i56)
define i64 @odd_saturation_56_0(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i56
 %y = trunc i64 %b to i56
 %v0 = call i56 @llvm.sadd.sat.i56(i56 %x,i56 %y)
 %wide0 = zext i56 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i56 @llvm.sadd.sat.i56(i56 -1,i56 %y)
 %wide1 = zext i56 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i56 @llvm.sadd.sat.i56(i56 %x,i56 1)
 %wide2 = zext i56 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i56 @llvm.sadd.sat.i56(i56 -1,i56 1)
 %wide3 = zext i56 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i56 @llvm.ssub.sat.i56(i56,i56)
define i64 @odd_saturation_56_1(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i56
 %y = trunc i64 %b to i56
 %v0 = call i56 @llvm.ssub.sat.i56(i56 %x,i56 %y)
 %wide0 = zext i56 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i56 @llvm.ssub.sat.i56(i56 -1,i56 %y)
 %wide1 = zext i56 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i56 @llvm.ssub.sat.i56(i56 %x,i56 1)
 %wide2 = zext i56 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i56 @llvm.ssub.sat.i56(i56 -1,i56 1)
 %wide3 = zext i56 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i57 @llvm.sadd.sat.i57(i57,i57)
define i64 @odd_saturation_57_0(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i57
 %y = trunc i64 %b to i57
 %v0 = call i57 @llvm.sadd.sat.i57(i57 %x,i57 %y)
 %wide0 = zext i57 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i57 @llvm.sadd.sat.i57(i57 -1,i57 %y)
 %wide1 = zext i57 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i57 @llvm.sadd.sat.i57(i57 %x,i57 1)
 %wide2 = zext i57 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i57 @llvm.sadd.sat.i57(i57 -1,i57 1)
 %wide3 = zext i57 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i57 @llvm.ssub.sat.i57(i57,i57)
define i64 @odd_saturation_57_1(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i57
 %y = trunc i64 %b to i57
 %v0 = call i57 @llvm.ssub.sat.i57(i57 %x,i57 %y)
 %wide0 = zext i57 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i57 @llvm.ssub.sat.i57(i57 -1,i57 %y)
 %wide1 = zext i57 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i57 @llvm.ssub.sat.i57(i57 %x,i57 1)
 %wide2 = zext i57 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i57 @llvm.ssub.sat.i57(i57 -1,i57 1)
 %wide3 = zext i57 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i58 @llvm.sadd.sat.i58(i58,i58)
define i64 @odd_saturation_58_0(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i58
 %y = trunc i64 %b to i58
 %v0 = call i58 @llvm.sadd.sat.i58(i58 %x,i58 %y)
 %wide0 = zext i58 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i58 @llvm.sadd.sat.i58(i58 -1,i58 %y)
 %wide1 = zext i58 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i58 @llvm.sadd.sat.i58(i58 %x,i58 1)
 %wide2 = zext i58 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i58 @llvm.sadd.sat.i58(i58 -1,i58 1)
 %wide3 = zext i58 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i58 @llvm.ssub.sat.i58(i58,i58)
define i64 @odd_saturation_58_1(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i58
 %y = trunc i64 %b to i58
 %v0 = call i58 @llvm.ssub.sat.i58(i58 %x,i58 %y)
 %wide0 = zext i58 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i58 @llvm.ssub.sat.i58(i58 -1,i58 %y)
 %wide1 = zext i58 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i58 @llvm.ssub.sat.i58(i58 %x,i58 1)
 %wide2 = zext i58 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i58 @llvm.ssub.sat.i58(i58 -1,i58 1)
 %wide3 = zext i58 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i59 @llvm.sadd.sat.i59(i59,i59)
define i64 @odd_saturation_59_0(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i59
 %y = trunc i64 %b to i59
 %v0 = call i59 @llvm.sadd.sat.i59(i59 %x,i59 %y)
 %wide0 = zext i59 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i59 @llvm.sadd.sat.i59(i59 -1,i59 %y)
 %wide1 = zext i59 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i59 @llvm.sadd.sat.i59(i59 %x,i59 1)
 %wide2 = zext i59 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i59 @llvm.sadd.sat.i59(i59 -1,i59 1)
 %wide3 = zext i59 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i59 @llvm.ssub.sat.i59(i59,i59)
define i64 @odd_saturation_59_1(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i59
 %y = trunc i64 %b to i59
 %v0 = call i59 @llvm.ssub.sat.i59(i59 %x,i59 %y)
 %wide0 = zext i59 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i59 @llvm.ssub.sat.i59(i59 -1,i59 %y)
 %wide1 = zext i59 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i59 @llvm.ssub.sat.i59(i59 %x,i59 1)
 %wide2 = zext i59 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i59 @llvm.ssub.sat.i59(i59 -1,i59 1)
 %wide3 = zext i59 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i60 @llvm.sadd.sat.i60(i60,i60)
define i64 @odd_saturation_60_0(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i60
 %y = trunc i64 %b to i60
 %v0 = call i60 @llvm.sadd.sat.i60(i60 %x,i60 %y)
 %wide0 = zext i60 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i60 @llvm.sadd.sat.i60(i60 -1,i60 %y)
 %wide1 = zext i60 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i60 @llvm.sadd.sat.i60(i60 %x,i60 1)
 %wide2 = zext i60 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i60 @llvm.sadd.sat.i60(i60 -1,i60 1)
 %wide3 = zext i60 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i60 @llvm.ssub.sat.i60(i60,i60)
define i64 @odd_saturation_60_1(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i60
 %y = trunc i64 %b to i60
 %v0 = call i60 @llvm.ssub.sat.i60(i60 %x,i60 %y)
 %wide0 = zext i60 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i60 @llvm.ssub.sat.i60(i60 -1,i60 %y)
 %wide1 = zext i60 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i60 @llvm.ssub.sat.i60(i60 %x,i60 1)
 %wide2 = zext i60 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i60 @llvm.ssub.sat.i60(i60 -1,i60 1)
 %wide3 = zext i60 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i61 @llvm.sadd.sat.i61(i61,i61)
define i64 @odd_saturation_61_0(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i61
 %y = trunc i64 %b to i61
 %v0 = call i61 @llvm.sadd.sat.i61(i61 %x,i61 %y)
 %wide0 = zext i61 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i61 @llvm.sadd.sat.i61(i61 -1,i61 %y)
 %wide1 = zext i61 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i61 @llvm.sadd.sat.i61(i61 %x,i61 1)
 %wide2 = zext i61 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i61 @llvm.sadd.sat.i61(i61 -1,i61 1)
 %wide3 = zext i61 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i61 @llvm.ssub.sat.i61(i61,i61)
define i64 @odd_saturation_61_1(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i61
 %y = trunc i64 %b to i61
 %v0 = call i61 @llvm.ssub.sat.i61(i61 %x,i61 %y)
 %wide0 = zext i61 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i61 @llvm.ssub.sat.i61(i61 -1,i61 %y)
 %wide1 = zext i61 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i61 @llvm.ssub.sat.i61(i61 %x,i61 1)
 %wide2 = zext i61 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i61 @llvm.ssub.sat.i61(i61 -1,i61 1)
 %wide3 = zext i61 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i62 @llvm.sadd.sat.i62(i62,i62)
define i64 @odd_saturation_62_0(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i62
 %y = trunc i64 %b to i62
 %v0 = call i62 @llvm.sadd.sat.i62(i62 %x,i62 %y)
 %wide0 = zext i62 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i62 @llvm.sadd.sat.i62(i62 -1,i62 %y)
 %wide1 = zext i62 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i62 @llvm.sadd.sat.i62(i62 %x,i62 1)
 %wide2 = zext i62 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i62 @llvm.sadd.sat.i62(i62 -1,i62 1)
 %wide3 = zext i62 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i62 @llvm.ssub.sat.i62(i62,i62)
define i64 @odd_saturation_62_1(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i62
 %y = trunc i64 %b to i62
 %v0 = call i62 @llvm.ssub.sat.i62(i62 %x,i62 %y)
 %wide0 = zext i62 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i62 @llvm.ssub.sat.i62(i62 -1,i62 %y)
 %wide1 = zext i62 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i62 @llvm.ssub.sat.i62(i62 %x,i62 1)
 %wide2 = zext i62 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i62 @llvm.ssub.sat.i62(i62 -1,i62 1)
 %wide3 = zext i62 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i63 @llvm.sadd.sat.i63(i63,i63)
define i64 @odd_saturation_63_0(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i63
 %y = trunc i64 %b to i63
 %v0 = call i63 @llvm.sadd.sat.i63(i63 %x,i63 %y)
 %wide0 = zext i63 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i63 @llvm.sadd.sat.i63(i63 -1,i63 %y)
 %wide1 = zext i63 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i63 @llvm.sadd.sat.i63(i63 %x,i63 1)
 %wide2 = zext i63 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i63 @llvm.sadd.sat.i63(i63 -1,i63 1)
 %wide3 = zext i63 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i63 @llvm.ssub.sat.i63(i63,i63)
define i64 @odd_saturation_63_1(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = trunc i64 %a to i63
 %y = trunc i64 %b to i63
 %v0 = call i63 @llvm.ssub.sat.i63(i63 %x,i63 %y)
 %wide0 = zext i63 %v0 to i64
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i63 @llvm.ssub.sat.i63(i63 -1,i63 %y)
 %wide1 = zext i63 %v1 to i64
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i63 @llvm.ssub.sat.i63(i63 %x,i63 1)
 %wide2 = zext i63 %v2 to i64
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i63 @llvm.ssub.sat.i63(i63 -1,i63 1)
 %wide3 = zext i63 %v3 to i64
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i64 @llvm.sadd.sat.i64(i64,i64)
define i64 @odd_saturation_64_0(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = add i64 %a,0
 %y = add i64 %b,0
 %v0 = call i64 @llvm.sadd.sat.i64(i64 %x,i64 %y)
 %wide0 = add i64 %v0,0
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i64 @llvm.sadd.sat.i64(i64 -1,i64 %y)
 %wide1 = add i64 %v1,0
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i64 @llvm.sadd.sat.i64(i64 %x,i64 1)
 %wide2 = add i64 %v2,0
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i64 @llvm.sadd.sat.i64(i64 -1,i64 1)
 %wide3 = add i64 %v3,0
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i64 @llvm.ssub.sat.i64(i64,i64)
define i64 @odd_saturation_64_1(ptr %out,i64 %a,i64 %b,i64 %salt) {
entry:
 %x = add i64 %a,0
 %y = add i64 %b,0
 %v0 = call i64 @llvm.ssub.sat.i64(i64 %x,i64 %y)
 %wide0 = add i64 %v0,0
 %r0 = xor i64 %wide0,%salt
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %r0,ptr %p0,align 1
 %v1 = call i64 @llvm.ssub.sat.i64(i64 -1,i64 %y)
 %wide1 = add i64 %v1,0
 %r1 = xor i64 %wide1,%salt
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %r1,ptr %p1,align 1
 %v2 = call i64 @llvm.ssub.sat.i64(i64 %x,i64 1)
 %wide2 = add i64 %v2,0
 %r2 = xor i64 %wide2,%salt
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %r2,ptr %p2,align 1
 %v3 = call i64 @llvm.ssub.sat.i64(i64 -1,i64 1)
 %wide3 = add i64 %v3,0
 %r3 = xor i64 %wide3,%salt
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %r3,ptr %p3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
