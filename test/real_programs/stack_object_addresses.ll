target triple = "x86_64-unknown-linux-gnu"
declare void @llvm.memcpy.p0.p0.i64(ptr, ptr, i64, i1)
declare void @llvm.memmove.p0.p0.i64(ptr, ptr, i64, i1)
declare i64 @stack_object_touch(ptr, i64)
declare i1 @stack_object_predicate(ptr, i64)
define i64 @stack_copy_i8(ptr %out, ptr %input, ptr %alternate, ptr %source_out, i64 %length, i64 %seed) {
entry:
 %src = alloca i8, align 16
 %dst = alloca i8, align 16
 call void @llvm.memcpy.p0.p0.i64(ptr %src, ptr %input, i64 1, i1 false)
 call void @llvm.memcpy.p0.p0.i64(ptr %dst, ptr %alternate, i64 1, i1 false)
 call void @llvm.memcpy.p0.p0.i64(ptr %dst, ptr %src, i64 %length, i1 false)
 call void @llvm.memcpy.p0.p0.i64(ptr %out, ptr %dst, i64 1, i1 false)
 call void @llvm.memcpy.p0.p0.i64(ptr %source_out, ptr %src, i64 1, i1 false)
 %r = xor i64 %seed, 1
 ret i64 %r
}
define i64 @stack_copy_i16(ptr %out, ptr %input, ptr %alternate, ptr %source_out, i64 %length, i64 %seed) {
entry:
 %src = alloca i16, align 16
 %dst = alloca i16, align 16
 call void @llvm.memcpy.p0.p0.i64(ptr %src, ptr %input, i64 2, i1 false)
 call void @llvm.memcpy.p0.p0.i64(ptr %dst, ptr %alternate, i64 2, i1 false)
 call void @llvm.memcpy.p0.p0.i64(ptr %dst, ptr %src, i64 %length, i1 false)
 call void @llvm.memcpy.p0.p0.i64(ptr %out, ptr %dst, i64 2, i1 false)
 call void @llvm.memcpy.p0.p0.i64(ptr %source_out, ptr %src, i64 2, i1 false)
 %r = xor i64 %seed, 2
 ret i64 %r
}
define i64 @stack_copy_i32(ptr %out, ptr %input, ptr %alternate, ptr %source_out, i64 %length, i64 %seed) {
entry:
 %src = alloca i32, align 16
 %dst = alloca i32, align 16
 call void @llvm.memcpy.p0.p0.i64(ptr %src, ptr %input, i64 4, i1 false)
 call void @llvm.memcpy.p0.p0.i64(ptr %dst, ptr %alternate, i64 4, i1 false)
 call void @llvm.memcpy.p0.p0.i64(ptr %dst, ptr %src, i64 %length, i1 false)
 call void @llvm.memcpy.p0.p0.i64(ptr %out, ptr %dst, i64 4, i1 false)
 call void @llvm.memcpy.p0.p0.i64(ptr %source_out, ptr %src, i64 4, i1 false)
 %r = xor i64 %seed, 4
 ret i64 %r
}
define i64 @stack_copy_i64(ptr %out, ptr %input, ptr %alternate, ptr %source_out, i64 %length, i64 %seed) {
entry:
 %src = alloca i64, align 16
 %dst = alloca i64, align 16
 call void @llvm.memcpy.p0.p0.i64(ptr %src, ptr %input, i64 8, i1 false)
 call void @llvm.memcpy.p0.p0.i64(ptr %dst, ptr %alternate, i64 8, i1 false)
 call void @llvm.memcpy.p0.p0.i64(ptr %dst, ptr %src, i64 %length, i1 false)
 call void @llvm.memcpy.p0.p0.i64(ptr %out, ptr %dst, i64 8, i1 false)
 call void @llvm.memcpy.p0.p0.i64(ptr %source_out, ptr %src, i64 8, i1 false)
 %r = xor i64 %seed, 8
 ret i64 %r
}
define i64 @stack_copy_f32(ptr %out, ptr %input, ptr %alternate, ptr %source_out, i64 %length, i64 %seed) {
entry:
 %src = alloca float, align 16
 %dst = alloca float, align 16
 call void @llvm.memcpy.p0.p0.i64(ptr %src, ptr %input, i64 4, i1 false)
 call void @llvm.memcpy.p0.p0.i64(ptr %dst, ptr %alternate, i64 4, i1 false)
 call void @llvm.memcpy.p0.p0.i64(ptr %dst, ptr %src, i64 %length, i1 false)
 call void @llvm.memcpy.p0.p0.i64(ptr %out, ptr %dst, i64 4, i1 false)
 call void @llvm.memcpy.p0.p0.i64(ptr %source_out, ptr %src, i64 4, i1 false)
 %r = xor i64 %seed, 4
 ret i64 %r
}
define i64 @stack_copy_f64(ptr %out, ptr %input, ptr %alternate, ptr %source_out, i64 %length, i64 %seed) {
entry:
 %src = alloca double, align 16
 %dst = alloca double, align 16
 call void @llvm.memcpy.p0.p0.i64(ptr %src, ptr %input, i64 8, i1 false)
 call void @llvm.memcpy.p0.p0.i64(ptr %dst, ptr %alternate, i64 8, i1 false)
 call void @llvm.memcpy.p0.p0.i64(ptr %dst, ptr %src, i64 %length, i1 false)
 call void @llvm.memcpy.p0.p0.i64(ptr %out, ptr %dst, i64 8, i1 false)
 call void @llvm.memcpy.p0.p0.i64(ptr %source_out, ptr %src, i64 8, i1 false)
 %r = xor i64 %seed, 8
 ret i64 %r
}
define i64 @stack_copy_i128(ptr %out, ptr %input, ptr %alternate, ptr %source_out, i64 %length, i64 %seed) {
entry:
 %src = alloca i128, align 16
 %dst = alloca i128, align 16
 call void @llvm.memcpy.p0.p0.i64(ptr %src, ptr %input, i64 16, i1 false)
 call void @llvm.memcpy.p0.p0.i64(ptr %dst, ptr %alternate, i64 16, i1 false)
 call void @llvm.memcpy.p0.p0.i64(ptr %dst, ptr %src, i64 %length, i1 false)
 call void @llvm.memcpy.p0.p0.i64(ptr %out, ptr %dst, i64 16, i1 false)
 call void @llvm.memcpy.p0.p0.i64(ptr %source_out, ptr %src, i64 16, i1 false)
 %r = xor i64 %seed, 16
 ret i64 %r
}
define i64 @stack_copy_array3(ptr %out, ptr %input, ptr %alternate, ptr %source_out, i64 %length, i64 %seed) {
entry:
 %src = alloca [3 x i32], align 16
 %dst = alloca [3 x i32], align 16
 call void @llvm.memcpy.p0.p0.i64(ptr %src, ptr %input, i64 12, i1 false)
 call void @llvm.memcpy.p0.p0.i64(ptr %dst, ptr %alternate, i64 12, i1 false)
 call void @llvm.memcpy.p0.p0.i64(ptr %dst, ptr %src, i64 %length, i1 false)
 call void @llvm.memcpy.p0.p0.i64(ptr %out, ptr %dst, i64 12, i1 false)
 call void @llvm.memcpy.p0.p0.i64(ptr %source_out, ptr %src, i64 12, i1 false)
 %r = xor i64 %seed, 12
 ret i64 %r
}
define i64 @stack_copy_array16(ptr %out, ptr %input, ptr %alternate, ptr %source_out, i64 %length, i64 %seed) {
entry:
 %src = alloca [16 x i32], align 16
 %dst = alloca [16 x i32], align 16
 call void @llvm.memcpy.p0.p0.i64(ptr %src, ptr %input, i64 64, i1 false)
 call void @llvm.memcpy.p0.p0.i64(ptr %dst, ptr %alternate, i64 64, i1 false)
 call void @llvm.memcpy.p0.p0.i64(ptr %dst, ptr %src, i64 %length, i1 false)
 call void @llvm.memcpy.p0.p0.i64(ptr %out, ptr %dst, i64 64, i1 false)
 call void @llvm.memcpy.p0.p0.i64(ptr %source_out, ptr %src, i64 64, i1 false)
 %r = xor i64 %seed, 64
 ret i64 %r
}
define i64 @stack_phi_i64(ptr %external, i64 %value, i1 %take_local, i64 %seed) {
entry:
 %slot = alloca i64, align 16
 %address = getelementptr i8, ptr %slot, i64 0
 store i64 %value, ptr %address, align 8
 br i1 %take_local, label %local, label %outside
local:
 br label %join
outside:
 br label %join
join:
 %p = phi ptr [ %slot, %local ], [ %external, %outside ]
 %read = load i64, ptr %p, align 8
 %r = xor i64 %read, %seed
 ret i64 %r
}
define i64 @stack_phi_i128(ptr %external, i64 %value, i1 %take_local, i64 %seed) {
entry:
 %slot = alloca i128, align 16
 %address = getelementptr i8, ptr %slot, i64 0
 store i64 %value, ptr %address, align 8
 br i1 %take_local, label %local, label %outside
local:
 br label %join
outside:
 br label %join
join:
 %p = phi ptr [ %slot, %local ], [ %external, %outside ]
 %read = load i64, ptr %p, align 8
 %r = xor i64 %read, %seed
 ret i64 %r
}
define i64 @stack_phi_array3(ptr %external, i64 %value, i1 %take_local, i64 %seed) {
entry:
 %slot = alloca [3 x i32], align 16
 %address = getelementptr i8, ptr %slot, i64 0
 store i64 %value, ptr %address, align 8
 br i1 %take_local, label %local, label %outside
local:
 br label %join
outside:
 br label %join
join:
 %p = phi ptr [ %slot, %local ], [ %external, %outside ]
 %read = load i64, ptr %p, align 8
 %r = xor i64 %read, %seed
 ret i64 %r
}
define i64 @stack_phi_array16(ptr %external, i64 %value, i1 %take_local, i64 %seed) {
entry:
 %slot = alloca [16 x i32], align 16
 %address = getelementptr i8, ptr %slot, i64 0
 store i64 %value, ptr %address, align 8
 br i1 %take_local, label %local, label %outside
local:
 br label %join
outside:
 br label %join
join:
 %p = phi ptr [ %slot, %local ], [ %external, %outside ]
 %read = load i64, ptr %p, align 8
 %r = xor i64 %read, %seed
 ret i64 %r
}
define i64 @stack_phi_swap_2(i64 %a, i64 %b, i32 %count, i64 %seed) {
entry:
 %first = alloca [2 x i32], align 8
 %second = alloca [2 x i32], align 8
 %fa = getelementptr i8, ptr %first, i64 0
 %sa = getelementptr i8, ptr %second, i64 0
 store i64 %a, ptr %fa, align 8
 store i64 %b, ptr %sa, align 8
 br label %loop
loop:
 %p = phi ptr [ %first, %entry ], [ %q, %loop ]
 %q = phi ptr [ %second, %entry ], [ %p, %loop ]
 %n = phi i32 [ 0, %entry ], [ %next, %loop ]
 %next = add i32 %n, 1
 %more = icmp ult i32 %n, %count
 br i1 %more, label %loop, label %exit
exit:
 %x = load i64, ptr %p, align 8
 %y = load i64, ptr %q, align 8
 %difference = sub i64 %x, %y
 %r = xor i64 %difference, %seed
 ret i64 %r
}
define i64 @stack_phi_swap_16(i64 %a, i64 %b, i32 %count, i64 %seed) {
entry:
 %first = alloca [16 x i32], align 8
 %second = alloca [16 x i32], align 8
 %fa = getelementptr i8, ptr %first, i64 0
 %sa = getelementptr i8, ptr %second, i64 0
 store i64 %a, ptr %fa, align 8
 store i64 %b, ptr %sa, align 8
 br label %loop
loop:
 %p = phi ptr [ %first, %entry ], [ %q, %loop ]
 %q = phi ptr [ %second, %entry ], [ %p, %loop ]
 %n = phi i32 [ 0, %entry ], [ %next, %loop ]
 %next = add i32 %n, 1
 %more = icmp ult i32 %n, %count
 br i1 %more, label %loop, label %exit
exit:
 %x = load i64, ptr %p, align 8
 %y = load i64, ptr %q, align 8
 %difference = sub i64 %x, %y
 %r = xor i64 %difference, %seed
 ret i64 %r
}
define i64 @stack_window(ptr %out, i64 %value, i64 %offset, i64 %length, i64 %seed) {
entry:
 %slot = alloca i64, align 8
 store i64 %value, ptr %slot, align 8
 %start = getelementptr inbounds [1 x i8], ptr %slot, i64 %offset
 call void @llvm.memcpy.p0.p0.i64(ptr %out, ptr %start, i64 %length, i1 false)
 %read = load i64, ptr %slot, align 8
 %r = xor i64 %read, %seed
 ret i64 %r
}
define i64 @stack_move(ptr %out, ptr %input, i64 %offset, i64 %length, i64 %seed) {
entry:
 %slot = alloca [16 x i32], align 16
 call void @llvm.memcpy.p0.p0.i64(ptr %slot, ptr %input, i64 64, i1 false)
 %start = getelementptr i8, ptr %slot, i64 %offset
 %direction = trunc i64 %seed to i1
 br i1 %direction, label %forward, label %backward
forward:
 call void @llvm.memmove.p0.p0.i64(ptr %start, ptr %slot, i64 %length, i1 false)
 br label %exit
backward:
 call void @llvm.memmove.p0.p0.i64(ptr %slot, ptr %start, i64 %length, i1 false)
 br label %exit
exit:
 call void @llvm.memcpy.p0.p0.i64(ptr %out, ptr %slot, i64 64, i1 false)
 %r = xor i64 %seed, %length
 ret i64 %r
}
define i64 @stack_call_array(ptr %input, ptr %out, i64 %seed) {
entry:
 %slot = alloca [16 x i32], align 16
 call void @llvm.memcpy.p0.p0.i64(ptr %slot, ptr %input, i64 64, i1 false)
 %value = call i64 @stack_object_touch(ptr %slot, i64 %seed)
 call void @llvm.memcpy.p0.p0.i64(ptr %out, ptr %slot, i64 64, i1 false)
 %r = xor i64 %value, %seed
 ret i64 %r
}
define i64 @stack_call_bool(ptr %input, ptr %out, i64 %seed) {
entry:
 %slot = alloca [16 x i32], align 16
 call void @llvm.memcpy.p0.p0.i64(ptr %slot, ptr %input, i64 64, i1 false)
 %value = call i1 @stack_object_predicate(ptr %slot, i64 %seed)
 call void @llvm.memcpy.p0.p0.i64(ptr %out, ptr %slot, i64 64, i1 false)
 %wide = zext i1 %value to i64
 %r = xor i64 %wide, %seed
 ret i64 %r
}
