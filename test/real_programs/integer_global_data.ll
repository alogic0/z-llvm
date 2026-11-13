target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"
declare void @llvm.memcpy.p0.p0.i64(ptr,ptr,i64,i1)
declare void @llvm.memset.p0.i64(ptr,i8,i64,i1)
@pair = internal constant <2 x i32> <i32 287454020,i32 -1>
@nested = internal constant {i8,[2 x <3 x i32>],i8} {i8 7,[2 x <3 x i32>] [<3 x i32> <i32 1,i32 2,i32 3>,<3 x i32> <i32 4,i32 5,i32 6>],i8 9},section ".rodata",align 16
@mask = internal constant <4 x i1> <i1 true,i1 false,i1 true,i1 true>
@packed = internal constant <4 x i5> <i5 1,i5 2,i5 3,i5 4>
@left = internal constant {[3 x i8],i8} {[3 x i8] c"{,X",i8 7}
@right = internal constant {[3 x i8],i8} {[3 x i8] c"},Y",i8 9}
@writable = internal global i32 123,section ".data",align 4
@readonly = internal constant i32 456,section ".rodata",align 4
@ro_pointer = internal constant ptr @pair,section ".rodata",align 8
@counter = internal global i64 0,section ".data",align 8
define ptr @integer_globals_readonly() {
entry:
 ret ptr @nested
}
define i64 @integer_globals_probe(ptr %out,ptr %unused,ptr %other,i64 %salt) {
entry:
 %first = load ptr,ptr @ro_pointer,align 8
 %p0 = getelementptr i8,ptr %out,i64 0
 call void @llvm.memcpy.p0.p0.i64(ptr %p0,ptr %first,i64 8,i1 0)
 %p1 = getelementptr i8,ptr %out,i64 8
 call void @llvm.memcpy.p0.p0.i64(ptr %p1,ptr @nested,i64 64,i1 0)
 %p2 = getelementptr i8,ptr %out,i64 72
 call void @llvm.memcpy.p0.p0.i64(ptr %p2,ptr @mask,i64 1,i1 0)
 %p3 = getelementptr i8,ptr %out,i64 73
 call void @llvm.memcpy.p0.p0.i64(ptr %p3,ptr @packed,i64 4,i1 0)
 %p4 = getelementptr i8,ptr %out,i64 77
 call void @llvm.memcpy.p0.p0.i64(ptr %p4,ptr @left,i64 4,i1 0)
 %p5 = getelementptr i8,ptr %out,i64 81
 call void @llvm.memcpy.p0.p0.i64(ptr %p5,ptr @right,i64 4,i1 0)
 %p6 = getelementptr i8,ptr %out,i64 85
 call void @llvm.memcpy.p0.p0.i64(ptr %p6,ptr @writable,i64 4,i1 0)
 %p7 = getelementptr i8,ptr %out,i64 89
 call void @llvm.memcpy.p0.p0.i64(ptr %p7,ptr @readonly,i64 4,i1 0)
 %old = load i64,ptr @counter,align 8
 store i64 %salt,ptr @counter,align 8
 %r = xor i64 %old,%salt
 ret i64 %r
}
