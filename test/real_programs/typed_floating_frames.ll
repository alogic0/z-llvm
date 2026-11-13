target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"
declare i64 @complete_clobber(i64,i64,i64,i64,i64,i64,i64,i64)
declare void @complete_touch(ptr)
define i64 @typed_floating_probe_0(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %frame = alloca [24 x i32],align 16
 %slot = getelementptr i8,ptr %frame,i64 16
 %before = getelementptr i8,ptr %slot,i64 -1
 %after = getelementptr i8,ptr %slot,i64 16
 store i8 81,ptr %before,align 1
 store i8 163,ptr %after,align 1
 %input = load <4 x float>,ptr %source,align 1
 store <4 x float> %input,ptr %slot,align 16
 call void @complete_touch(ptr %slot)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %value = load <4 x float>,ptr %slot,align 16
 store <4 x float> %value,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %first = load i8,ptr %before,align 1
 %last = load i8,ptr %after,align 1
 %first_out = getelementptr i8,ptr %out,i64 24
 %last_out = getelementptr i8,ptr %out,i64 25
 store i8 %first,ptr %first_out,align 1
 store i8 %last,ptr %last_out,align 1
 ret i64 %token
}
define i64 @typed_floating_probe_1(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %frame = alloca [24 x i32],align 16
 %slot = getelementptr i8,ptr %frame,i64 32
 %before = getelementptr i8,ptr %slot,i64 -1
 %after = getelementptr i8,ptr %slot,i64 16
 store i8 81,ptr %before,align 1
 store i8 163,ptr %after,align 1
 %input = load <4 x float>,ptr %source,align 1
 store <4 x float> %input,ptr %slot,align 16
 call void @complete_touch(ptr %slot)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %value = load <4 x float>,ptr %slot,align 16
 store <4 x float> %value,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %first = load i8,ptr %before,align 1
 %last = load i8,ptr %after,align 1
 %first_out = getelementptr i8,ptr %out,i64 24
 %last_out = getelementptr i8,ptr %out,i64 25
 store i8 %first,ptr %first_out,align 1
 store i8 %last,ptr %last_out,align 1
 ret i64 %token
}
define i64 @typed_floating_probe_2(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %frame = alloca [24 x i32],align 16
 %slot = getelementptr i8,ptr %frame,i64 48
 %before = getelementptr i8,ptr %slot,i64 -1
 %after = getelementptr i8,ptr %slot,i64 16
 store i8 81,ptr %before,align 1
 store i8 163,ptr %after,align 1
 %input = load <4 x float>,ptr %source,align 1
 store <4 x float> %input,ptr %slot,align 16
 call void @complete_touch(ptr %slot)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %value = load <4 x float>,ptr %slot,align 16
 store <4 x float> %value,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %first = load i8,ptr %before,align 1
 %last = load i8,ptr %after,align 1
 %first_out = getelementptr i8,ptr %out,i64 24
 %last_out = getelementptr i8,ptr %out,i64 25
 store i8 %first,ptr %first_out,align 1
 store i8 %last,ptr %last_out,align 1
 ret i64 %token
}
define i64 @typed_floating_probe_3(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %frame = alloca [24 x i32],align 16
 %slot = getelementptr i8,ptr %frame,i64 64
 %before = getelementptr i8,ptr %slot,i64 -1
 %after = getelementptr i8,ptr %slot,i64 16
 store i8 81,ptr %before,align 1
 store i8 163,ptr %after,align 1
 %input = load <4 x float>,ptr %source,align 1
 store <4 x float> %input,ptr %slot,align 16
 call void @complete_touch(ptr %slot)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %value = load <4 x float>,ptr %slot,align 16
 store <4 x float> %value,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %first = load i8,ptr %before,align 1
 %last = load i8,ptr %after,align 1
 %first_out = getelementptr i8,ptr %out,i64 24
 %last_out = getelementptr i8,ptr %out,i64 25
 store i8 %first,ptr %first_out,align 1
 store i8 %last,ptr %last_out,align 1
 ret i64 %token
}
define i64 @typed_floating_probe_4(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %frame = alloca [24 x i32],align 16
 %slot = getelementptr i8,ptr %frame,i64 16
 %before = getelementptr i8,ptr %slot,i64 -1
 %after = getelementptr i8,ptr %slot,i64 16
 store i8 81,ptr %before,align 1
 store i8 163,ptr %after,align 1
 store <4 x float> <float 1.000000e+00,float -0.000000e+00,float 0x7FF8000020000000,float 0x7FF4000000000000>,ptr %slot,align 16
 call void @complete_touch(ptr %slot)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %value = load <4 x float>,ptr %slot,align 16
 store <4 x float> %value,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %first = load i8,ptr %before,align 1
 %last = load i8,ptr %after,align 1
 %first_out = getelementptr i8,ptr %out,i64 24
 %last_out = getelementptr i8,ptr %out,i64 25
 store i8 %first,ptr %first_out,align 1
 store i8 %last,ptr %last_out,align 1
 ret i64 %token
}
define i64 @typed_floating_probe_5(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %frame = alloca [24 x i32],align 16
 %slot = getelementptr i8,ptr %frame,i64 32
 %before = getelementptr i8,ptr %slot,i64 -1
 %after = getelementptr i8,ptr %slot,i64 16
 store i8 81,ptr %before,align 1
 store i8 163,ptr %after,align 1
 store <4 x float> <float 1.000000e+00,float -0.000000e+00,float 0x7FF8000020000000,float 0x7FF4000000000000>,ptr %slot,align 16
 call void @complete_touch(ptr %slot)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %value = load <4 x float>,ptr %slot,align 16
 store <4 x float> %value,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %first = load i8,ptr %before,align 1
 %last = load i8,ptr %after,align 1
 %first_out = getelementptr i8,ptr %out,i64 24
 %last_out = getelementptr i8,ptr %out,i64 25
 store i8 %first,ptr %first_out,align 1
 store i8 %last,ptr %last_out,align 1
 ret i64 %token
}
define i64 @typed_floating_probe_6(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %frame = alloca [24 x i32],align 16
 %slot = getelementptr i8,ptr %frame,i64 48
 %before = getelementptr i8,ptr %slot,i64 -1
 %after = getelementptr i8,ptr %slot,i64 16
 store i8 81,ptr %before,align 1
 store i8 163,ptr %after,align 1
 store <4 x float> <float 1.000000e+00,float -0.000000e+00,float 0x7FF8000020000000,float 0x7FF4000000000000>,ptr %slot,align 16
 call void @complete_touch(ptr %slot)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %value = load <4 x float>,ptr %slot,align 16
 store <4 x float> %value,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %first = load i8,ptr %before,align 1
 %last = load i8,ptr %after,align 1
 %first_out = getelementptr i8,ptr %out,i64 24
 %last_out = getelementptr i8,ptr %out,i64 25
 store i8 %first,ptr %first_out,align 1
 store i8 %last,ptr %last_out,align 1
 ret i64 %token
}
define i64 @typed_floating_probe_7(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %frame = alloca [24 x i32],align 16
 %slot = getelementptr i8,ptr %frame,i64 64
 %before = getelementptr i8,ptr %slot,i64 -1
 %after = getelementptr i8,ptr %slot,i64 16
 store i8 81,ptr %before,align 1
 store i8 163,ptr %after,align 1
 store <4 x float> <float 1.000000e+00,float -0.000000e+00,float 0x7FF8000020000000,float 0x7FF4000000000000>,ptr %slot,align 16
 call void @complete_touch(ptr %slot)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %value = load <4 x float>,ptr %slot,align 16
 store <4 x float> %value,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %first = load i8,ptr %before,align 1
 %last = load i8,ptr %after,align 1
 %first_out = getelementptr i8,ptr %out,i64 24
 %last_out = getelementptr i8,ptr %out,i64 25
 store i8 %first,ptr %first_out,align 1
 store i8 %last,ptr %last_out,align 1
 ret i64 %token
}
define i64 @typed_floating_probe_8(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %frame = alloca [24 x i32],align 16
 %slot = getelementptr i8,ptr %frame,i64 16
 %before = getelementptr i8,ptr %slot,i64 -1
 %after = getelementptr i8,ptr %slot,i64 16
 store i8 81,ptr %before,align 1
 store i8 163,ptr %after,align 1
 %input = load <8 x half>,ptr %source,align 1
 store <8 x half> %input,ptr %slot,align 16
 call void @complete_touch(ptr %slot)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %value = load <8 x half>,ptr %slot,align 16
 store <8 x half> %value,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %first = load i8,ptr %before,align 1
 %last = load i8,ptr %after,align 1
 %first_out = getelementptr i8,ptr %out,i64 24
 %last_out = getelementptr i8,ptr %out,i64 25
 store i8 %first,ptr %first_out,align 1
 store i8 %last,ptr %last_out,align 1
 ret i64 %token
}
define i64 @typed_floating_probe_9(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %frame = alloca [24 x i32],align 16
 %slot = getelementptr i8,ptr %frame,i64 32
 %before = getelementptr i8,ptr %slot,i64 -1
 %after = getelementptr i8,ptr %slot,i64 16
 store i8 81,ptr %before,align 1
 store i8 163,ptr %after,align 1
 %input = load <8 x half>,ptr %source,align 1
 store <8 x half> %input,ptr %slot,align 16
 call void @complete_touch(ptr %slot)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %value = load <8 x half>,ptr %slot,align 16
 store <8 x half> %value,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %first = load i8,ptr %before,align 1
 %last = load i8,ptr %after,align 1
 %first_out = getelementptr i8,ptr %out,i64 24
 %last_out = getelementptr i8,ptr %out,i64 25
 store i8 %first,ptr %first_out,align 1
 store i8 %last,ptr %last_out,align 1
 ret i64 %token
}
define i64 @typed_floating_probe_10(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %frame = alloca [24 x i32],align 16
 %slot = getelementptr i8,ptr %frame,i64 48
 %before = getelementptr i8,ptr %slot,i64 -1
 %after = getelementptr i8,ptr %slot,i64 16
 store i8 81,ptr %before,align 1
 store i8 163,ptr %after,align 1
 %input = load <8 x half>,ptr %source,align 1
 store <8 x half> %input,ptr %slot,align 16
 call void @complete_touch(ptr %slot)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %value = load <8 x half>,ptr %slot,align 16
 store <8 x half> %value,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %first = load i8,ptr %before,align 1
 %last = load i8,ptr %after,align 1
 %first_out = getelementptr i8,ptr %out,i64 24
 %last_out = getelementptr i8,ptr %out,i64 25
 store i8 %first,ptr %first_out,align 1
 store i8 %last,ptr %last_out,align 1
 ret i64 %token
}
define i64 @typed_floating_probe_11(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %frame = alloca [24 x i32],align 16
 %slot = getelementptr i8,ptr %frame,i64 64
 %before = getelementptr i8,ptr %slot,i64 -1
 %after = getelementptr i8,ptr %slot,i64 16
 store i8 81,ptr %before,align 1
 store i8 163,ptr %after,align 1
 %input = load <8 x half>,ptr %source,align 1
 store <8 x half> %input,ptr %slot,align 16
 call void @complete_touch(ptr %slot)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %value = load <8 x half>,ptr %slot,align 16
 store <8 x half> %value,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %first = load i8,ptr %before,align 1
 %last = load i8,ptr %after,align 1
 %first_out = getelementptr i8,ptr %out,i64 24
 %last_out = getelementptr i8,ptr %out,i64 25
 store i8 %first,ptr %first_out,align 1
 store i8 %last,ptr %last_out,align 1
 ret i64 %token
}
define i64 @typed_floating_probe_12(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %frame = alloca [24 x i32],align 16
 %slot = getelementptr i8,ptr %frame,i64 16
 %before = getelementptr i8,ptr %slot,i64 -1
 %after = getelementptr i8,ptr %slot,i64 16
 store i8 81,ptr %before,align 1
 store i8 163,ptr %after,align 1
 store <8 x half> <half 0xH3C00,half 0xH8000,half 0xH7C00,half 0xHFC00,half 0xH7E01,half 0xH7D55,half 0xH0001,half 0xH03FF>,ptr %slot,align 16
 call void @complete_touch(ptr %slot)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %value = load <8 x half>,ptr %slot,align 16
 store <8 x half> %value,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %first = load i8,ptr %before,align 1
 %last = load i8,ptr %after,align 1
 %first_out = getelementptr i8,ptr %out,i64 24
 %last_out = getelementptr i8,ptr %out,i64 25
 store i8 %first,ptr %first_out,align 1
 store i8 %last,ptr %last_out,align 1
 ret i64 %token
}
define i64 @typed_floating_probe_13(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %frame = alloca [24 x i32],align 16
 %slot = getelementptr i8,ptr %frame,i64 32
 %before = getelementptr i8,ptr %slot,i64 -1
 %after = getelementptr i8,ptr %slot,i64 16
 store i8 81,ptr %before,align 1
 store i8 163,ptr %after,align 1
 store <8 x half> <half 0xH3C00,half 0xH8000,half 0xH7C00,half 0xHFC00,half 0xH7E01,half 0xH7D55,half 0xH0001,half 0xH03FF>,ptr %slot,align 16
 call void @complete_touch(ptr %slot)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %value = load <8 x half>,ptr %slot,align 16
 store <8 x half> %value,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %first = load i8,ptr %before,align 1
 %last = load i8,ptr %after,align 1
 %first_out = getelementptr i8,ptr %out,i64 24
 %last_out = getelementptr i8,ptr %out,i64 25
 store i8 %first,ptr %first_out,align 1
 store i8 %last,ptr %last_out,align 1
 ret i64 %token
}
define i64 @typed_floating_probe_14(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %frame = alloca [24 x i32],align 16
 %slot = getelementptr i8,ptr %frame,i64 48
 %before = getelementptr i8,ptr %slot,i64 -1
 %after = getelementptr i8,ptr %slot,i64 16
 store i8 81,ptr %before,align 1
 store i8 163,ptr %after,align 1
 store <8 x half> <half 0xH3C00,half 0xH8000,half 0xH7C00,half 0xHFC00,half 0xH7E01,half 0xH7D55,half 0xH0001,half 0xH03FF>,ptr %slot,align 16
 call void @complete_touch(ptr %slot)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %value = load <8 x half>,ptr %slot,align 16
 store <8 x half> %value,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %first = load i8,ptr %before,align 1
 %last = load i8,ptr %after,align 1
 %first_out = getelementptr i8,ptr %out,i64 24
 %last_out = getelementptr i8,ptr %out,i64 25
 store i8 %first,ptr %first_out,align 1
 store i8 %last,ptr %last_out,align 1
 ret i64 %token
}
define i64 @typed_floating_probe_15(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %frame = alloca [24 x i32],align 16
 %slot = getelementptr i8,ptr %frame,i64 64
 %before = getelementptr i8,ptr %slot,i64 -1
 %after = getelementptr i8,ptr %slot,i64 16
 store i8 81,ptr %before,align 1
 store i8 163,ptr %after,align 1
 store <8 x half> <half 0xH3C00,half 0xH8000,half 0xH7C00,half 0xHFC00,half 0xH7E01,half 0xH7D55,half 0xH0001,half 0xH03FF>,ptr %slot,align 16
 call void @complete_touch(ptr %slot)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %value = load <8 x half>,ptr %slot,align 16
 store <8 x half> %value,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %first = load i8,ptr %before,align 1
 %last = load i8,ptr %after,align 1
 %first_out = getelementptr i8,ptr %out,i64 24
 %last_out = getelementptr i8,ptr %out,i64 25
 store i8 %first,ptr %first_out,align 1
 store i8 %last,ptr %last_out,align 1
 ret i64 %token
}
