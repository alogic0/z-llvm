target triple = "x86_64-unknown-linux-gnu"
target datalayout = "e-m:e-p:64:64-i64:64-i128:128-n8:16:32:64-S128"
@address_flow_data = global [8 x i64] zeroinitializer, align 8
declare i64 @address_flow_clobber(i64)
declare void @llvm.memset.p0.i64(ptr, i8, i64, i1)
declare void @llvm.memcpy.p0.p0.i64(ptr, ptr, i64, i1)
define i64 @address_flow_stride_0_dynamic(ptr %p, i64 %index, i64 %live, ptr %out) {
entry:
  %address = getelementptr [0 x i8], ptr %p, i64 %index
  %bits = ptrtoint ptr %address to i64
  %clobber = call i64 @address_flow_clobber(i64 %live)
  store i64 %clobber, ptr %out
  ret i64 %bits
}

define i64 @address_flow_stride_0_constant(ptr %p, i64 %index, i64 %live, ptr %out) {
entry:
  %address = getelementptr [0 x i8], ptr %p, i64 -1
  %bits = ptrtoint ptr %address to i64
  %clobber = call i64 @address_flow_clobber(i64 %live)
  store i64 %clobber, ptr %out
  ret i64 %bits
}

define i64 @address_flow_stride_1_dynamic(ptr %p, i64 %index, i64 %live, ptr %out) {
entry:
  %address = getelementptr [1 x i8], ptr %p, i64 %index
  %bits = ptrtoint ptr %address to i64
  %clobber = call i64 @address_flow_clobber(i64 %live)
  store i64 %clobber, ptr %out
  ret i64 %bits
}

define i64 @address_flow_stride_1_constant(ptr %p, i64 %index, i64 %live, ptr %out) {
entry:
  %address = getelementptr [1 x i8], ptr %p, i64 -1
  %bits = ptrtoint ptr %address to i64
  %clobber = call i64 @address_flow_clobber(i64 %live)
  store i64 %clobber, ptr %out
  ret i64 %bits
}

define i64 @address_flow_stride_4_dynamic(ptr %p, i64 %index, i64 %live, ptr %out) {
entry:
  %address = getelementptr [4 x i8], ptr %p, i64 %index
  %bits = ptrtoint ptr %address to i64
  %clobber = call i64 @address_flow_clobber(i64 %live)
  store i64 %clobber, ptr %out
  ret i64 %bits
}

define i64 @address_flow_stride_4_constant(ptr %p, i64 %index, i64 %live, ptr %out) {
entry:
  %address = getelementptr [4 x i8], ptr %p, i64 -1
  %bits = ptrtoint ptr %address to i64
  %clobber = call i64 @address_flow_clobber(i64 %live)
  store i64 %clobber, ptr %out
  ret i64 %bits
}

define i64 @address_flow_stride_24_dynamic(ptr %p, i64 %index, i64 %live, ptr %out) {
entry:
  %address = getelementptr [24 x i8], ptr %p, i64 %index
  %bits = ptrtoint ptr %address to i64
  %clobber = call i64 @address_flow_clobber(i64 %live)
  store i64 %clobber, ptr %out
  ret i64 %bits
}

define i64 @address_flow_stride_24_constant(ptr %p, i64 %index, i64 %live, ptr %out) {
entry:
  %address = getelementptr [24 x i8], ptr %p, i64 -1
  %bits = ptrtoint ptr %address to i64
  %clobber = call i64 @address_flow_clobber(i64 %live)
  store i64 %clobber, ptr %out
  ret i64 %bits
}

define i64 @address_flow_stride_256_dynamic(ptr %p, i64 %index, i64 %live, ptr %out) {
entry:
  %address = getelementptr [256 x i8], ptr %p, i64 %index
  %bits = ptrtoint ptr %address to i64
  %clobber = call i64 @address_flow_clobber(i64 %live)
  store i64 %clobber, ptr %out
  ret i64 %bits
}

define i64 @address_flow_stride_256_constant(ptr %p, i64 %index, i64 %live, ptr %out) {
entry:
  %address = getelementptr [256 x i8], ptr %p, i64 -1
  %bits = ptrtoint ptr %address to i64
  %clobber = call i64 @address_flow_clobber(i64 %live)
  store i64 %clobber, ptr %out
  ret i64 %bits
}

define i64 @address_flow_stride_257_dynamic(ptr %p, i64 %index, i64 %live, ptr %out) {
entry:
  %address = getelementptr [257 x i8], ptr %p, i64 %index
  %bits = ptrtoint ptr %address to i64
  %clobber = call i64 @address_flow_clobber(i64 %live)
  store i64 %clobber, ptr %out
  ret i64 %bits
}

define i64 @address_flow_stride_257_constant(ptr %p, i64 %index, i64 %live, ptr %out) {
entry:
  %address = getelementptr [257 x i8], ptr %p, i64 -1
  %bits = ptrtoint ptr %address to i64
  %clobber = call i64 @address_flow_clobber(i64 %live)
  store i64 %clobber, ptr %out
  ret i64 %bits
}

define i64 @address_flow_stride_4096_dynamic(ptr %p, i64 %index, i64 %live, ptr %out) {
entry:
  %address = getelementptr [4096 x i8], ptr %p, i64 %index
  %bits = ptrtoint ptr %address to i64
  %clobber = call i64 @address_flow_clobber(i64 %live)
  store i64 %clobber, ptr %out
  ret i64 %bits
}

define i64 @address_flow_stride_4096_constant(ptr %p, i64 %index, i64 %live, ptr %out) {
entry:
  %address = getelementptr [4096 x i8], ptr %p, i64 -1
  %bits = ptrtoint ptr %address to i64
  %clobber = call i64 @address_flow_clobber(i64 %live)
  store i64 %clobber, ptr %out
  ret i64 %bits
}

define i64 @address_flow_compare_eq_left(ptr %p, i64 %index, i64 %live, ptr %out) {
entry:
  %comparison = icmp eq ptr getelementptr (i8, ptr @address_flow_data, i64 8), %p
  %answer = zext i1 %comparison to i64
  %clobber = call i64 @address_flow_clobber(i64 %live)
  store i64 %clobber, ptr %out
  ret i64 %answer
}

define i64 @address_flow_compare_eq_right(ptr %p, i64 %index, i64 %live, ptr %out) {
entry:
  %comparison = icmp eq ptr %p, getelementptr (i8, ptr @address_flow_data, i64 8)
  %answer = zext i1 %comparison to i64
  %clobber = call i64 @address_flow_clobber(i64 %live)
  store i64 %clobber, ptr %out
  ret i64 %answer
}

define i64 @address_flow_compare_ne_left(ptr %p, i64 %index, i64 %live, ptr %out) {
entry:
  %comparison = icmp ne ptr getelementptr (i8, ptr @address_flow_data, i64 8), %p
  %answer = zext i1 %comparison to i64
  %clobber = call i64 @address_flow_clobber(i64 %live)
  store i64 %clobber, ptr %out
  ret i64 %answer
}

define i64 @address_flow_compare_ne_right(ptr %p, i64 %index, i64 %live, ptr %out) {
entry:
  %comparison = icmp ne ptr %p, getelementptr (i8, ptr @address_flow_data, i64 8)
  %answer = zext i1 %comparison to i64
  %clobber = call i64 @address_flow_clobber(i64 %live)
  store i64 %clobber, ptr %out
  ret i64 %answer
}

define i64 @address_flow_compare_ult_left(ptr %p, i64 %index, i64 %live, ptr %out) {
entry:
  %comparison = icmp ult ptr getelementptr (i8, ptr @address_flow_data, i64 8), %p
  %answer = zext i1 %comparison to i64
  %clobber = call i64 @address_flow_clobber(i64 %live)
  store i64 %clobber, ptr %out
  ret i64 %answer
}

define i64 @address_flow_compare_ult_right(ptr %p, i64 %index, i64 %live, ptr %out) {
entry:
  %comparison = icmp ult ptr %p, getelementptr (i8, ptr @address_flow_data, i64 8)
  %answer = zext i1 %comparison to i64
  %clobber = call i64 @address_flow_clobber(i64 %live)
  store i64 %clobber, ptr %out
  ret i64 %answer
}

define i64 @address_flow_compare_ule_left(ptr %p, i64 %index, i64 %live, ptr %out) {
entry:
  %comparison = icmp ule ptr getelementptr (i8, ptr @address_flow_data, i64 8), %p
  %answer = zext i1 %comparison to i64
  %clobber = call i64 @address_flow_clobber(i64 %live)
  store i64 %clobber, ptr %out
  ret i64 %answer
}

define i64 @address_flow_compare_ule_right(ptr %p, i64 %index, i64 %live, ptr %out) {
entry:
  %comparison = icmp ule ptr %p, getelementptr (i8, ptr @address_flow_data, i64 8)
  %answer = zext i1 %comparison to i64
  %clobber = call i64 @address_flow_clobber(i64 %live)
  store i64 %clobber, ptr %out
  ret i64 %answer
}

define i64 @address_flow_compare_ugt_left(ptr %p, i64 %index, i64 %live, ptr %out) {
entry:
  %comparison = icmp ugt ptr getelementptr (i8, ptr @address_flow_data, i64 8), %p
  %answer = zext i1 %comparison to i64
  %clobber = call i64 @address_flow_clobber(i64 %live)
  store i64 %clobber, ptr %out
  ret i64 %answer
}

define i64 @address_flow_compare_ugt_right(ptr %p, i64 %index, i64 %live, ptr %out) {
entry:
  %comparison = icmp ugt ptr %p, getelementptr (i8, ptr @address_flow_data, i64 8)
  %answer = zext i1 %comparison to i64
  %clobber = call i64 @address_flow_clobber(i64 %live)
  store i64 %clobber, ptr %out
  ret i64 %answer
}

define i64 @address_flow_compare_uge_left(ptr %p, i64 %index, i64 %live, ptr %out) {
entry:
  %comparison = icmp uge ptr getelementptr (i8, ptr @address_flow_data, i64 8), %p
  %answer = zext i1 %comparison to i64
  %clobber = call i64 @address_flow_clobber(i64 %live)
  store i64 %clobber, ptr %out
  ret i64 %answer
}

define i64 @address_flow_compare_uge_right(ptr %p, i64 %index, i64 %live, ptr %out) {
entry:
  %comparison = icmp uge ptr %p, getelementptr (i8, ptr @address_flow_data, i64 8)
  %answer = zext i1 %comparison to i64
  %clobber = call i64 @address_flow_clobber(i64 %live)
  store i64 %clobber, ptr %out
  ret i64 %answer
}

define i64 @address_flow_frame_8_memset(ptr %p, i64 %index, i64 %live, ptr %out) {
entry:
  %slot = alloca i8, align 8
  call void @llvm.memset.p0.i64(ptr align 8 %slot, i8 -86, i64 1, i1 false)
  %loaded = load i8, ptr %slot, align 8
  %extended = zext i8 %loaded to i64
  %clobber = call i64 @address_flow_clobber(i64 %live)
  store i64 %clobber, ptr %out
  ret i64 %extended
}

define i64 @address_flow_frame_8_memcpy(ptr %p, i64 %index, i64 %live, ptr %out) {
entry:
  %slot = alloca i8, align 8
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %slot, ptr align 1 %p, i64 1, i1 false)
  %loaded = load i8, ptr %slot, align 8
  %extended = zext i8 %loaded to i64
  %clobber = call i64 @address_flow_clobber(i64 %live)
  store i64 %clobber, ptr %out
  ret i64 %extended
}

define i64 @address_flow_frame_16_memset(ptr %p, i64 %index, i64 %live, ptr %out) {
entry:
  %slot = alloca i16, align 8
  call void @llvm.memset.p0.i64(ptr align 8 %slot, i8 -86, i64 2, i1 false)
  %loaded = load i16, ptr %slot, align 8
  %extended = zext i16 %loaded to i64
  %clobber = call i64 @address_flow_clobber(i64 %live)
  store i64 %clobber, ptr %out
  ret i64 %extended
}

define i64 @address_flow_frame_16_memcpy(ptr %p, i64 %index, i64 %live, ptr %out) {
entry:
  %slot = alloca i16, align 8
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %slot, ptr align 1 %p, i64 2, i1 false)
  %loaded = load i16, ptr %slot, align 8
  %extended = zext i16 %loaded to i64
  %clobber = call i64 @address_flow_clobber(i64 %live)
  store i64 %clobber, ptr %out
  ret i64 %extended
}

define i64 @address_flow_frame_32_memset(ptr %p, i64 %index, i64 %live, ptr %out) {
entry:
  %slot = alloca i32, align 8
  call void @llvm.memset.p0.i64(ptr align 8 %slot, i8 -86, i64 4, i1 false)
  %loaded = load i32, ptr %slot, align 8
  %extended = zext i32 %loaded to i64
  %clobber = call i64 @address_flow_clobber(i64 %live)
  store i64 %clobber, ptr %out
  ret i64 %extended
}

define i64 @address_flow_frame_32_memcpy(ptr %p, i64 %index, i64 %live, ptr %out) {
entry:
  %slot = alloca i32, align 8
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %slot, ptr align 1 %p, i64 4, i1 false)
  %loaded = load i32, ptr %slot, align 8
  %extended = zext i32 %loaded to i64
  %clobber = call i64 @address_flow_clobber(i64 %live)
  store i64 %clobber, ptr %out
  ret i64 %extended
}

define i64 @address_flow_frame_64_memset(ptr %p, i64 %index, i64 %live, ptr %out) {
entry:
  %slot = alloca i64, align 8
  call void @llvm.memset.p0.i64(ptr align 8 %slot, i8 -86, i64 8, i1 false)
  %loaded = load i64, ptr %slot, align 8
  %clobber = call i64 @address_flow_clobber(i64 %live)
  store i64 %clobber, ptr %out
  ret i64 %loaded
}

define i64 @address_flow_frame_64_memcpy(ptr %p, i64 %index, i64 %live, ptr %out) {
entry:
  %slot = alloca i64, align 8
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %slot, ptr align 1 %p, i64 8, i1 false)
  %loaded = load i64, ptr %slot, align 8
  %clobber = call i64 @address_flow_clobber(i64 %live)
  store i64 %clobber, ptr %out
  ret i64 %loaded
}

define i64 @address_flow_forward(ptr %p, i64 %index, i64 %live, ptr %out) {
entry:
  br label %define
use:
  %answer = add i64 %late, %live
  %clobber = call i64 @address_flow_clobber(i64 %live)
  store i64 %clobber, ptr %out
  ret i64 %answer
define:
  %late = mul i64 %index, 3
  br label %use
}

define i64 @address_flow_forward_loop(ptr %p, i64 %index, i64 %live, ptr %out) {
entry:
  %count = and i64 %index, 7
  br label %loop
body:
  %next = add i64 %sum, %live
  %increment = add i64 %i, 1
  br label %loop
finish:
  %clobber = call i64 @address_flow_clobber(i64 %live)
  store i64 %clobber, ptr %out
  ret i64 %sum
loop:
  %i = phi i64 [ 0, %entry ], [ %increment, %body ]
  %sum = phi i64 [ 0, %entry ], [ %next, %body ]
  %done = icmp eq i64 %i, %count
  br i1 %done, label %finish, label %body
}

define i64 @address_flow_forward_diamond(ptr %p, i64 %index, i64 %live, ptr %out) {
entry:
  br label %define
merge:
  %selected = phi i64 [ %first, %yes ], [ %second, %no ]
  %answer = xor i64 %selected, %shared
  %clobber = call i64 @address_flow_clobber(i64 %live)
  store i64 %clobber, ptr %out
  ret i64 %answer
yes:
  %first = add i64 %shared, 7
  br label %merge
no:
  %second = sub i64 %shared, 3
  br label %merge
define:
  %shared = add i64 %index, %live
  %condition = trunc i64 %index to i1
  br i1 %condition, label %yes, label %no
}
