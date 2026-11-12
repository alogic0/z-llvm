target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"
declare i64 @vector_storage_touch(ptr,ptr,ptr,ptr,ptr,i64,i64)
define i64 @vector_storage_16_32(ptr %out,ptr %xp,ptr %yp,i64 %salt) {
entry:
 %av = alloca <16 x i32>,align 64
 %bv = alloca <16 x i32>,align 64
 %array = alloca [3 x <16 x i32>],align 64
 %ar0 = getelementptr [3 x <16 x i32>],ptr %array,i64 0,i64 0
 %ar1 = getelementptr [3 x <16 x i32>],ptr %array,i64 0,i64 1
 %ar2 = getelementptr [3 x <16 x i32>],ptr %array,i64 0,i64 2
 %x = load <16 x i32>,ptr %xp,align 1
 %y = load <16 x i32>,ptr %yp,align 1
 %v0 = add <16 x i32> %x,%y
 store <16 x i32> %v0,ptr %ar0,align 64
 %v1 = sub <16 x i32> %x,%y
 store <16 x i32> %v1,ptr %ar1,align 64
 %v2 = xor <16 x i32> %x,%y
 store <16 x i32> %v2,ptr %ar2,align 64
 store <16 x i32> %x,ptr %av,align 64
 store <16 x i32> %y,ptr %bv,align 64
 %h = call i64 @vector_storage_touch(ptr %av,ptr %bv,ptr %ar0,ptr %ar1,ptr %ar2,i64 64,i64 64)
 %o0 = getelementptr i8,ptr %out,i64 0
 %r0 = load <16 x i32>,ptr %av,align 64
 store <16 x i32> %r0,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 512
 %r1 = load <16 x i32>,ptr %bv,align 64
 store <16 x i32> %r1,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 1024
 %r2 = load <16 x i32>,ptr %ar0,align 64
 store <16 x i32> %r2,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 1536
 %r3 = load <16 x i32>,ptr %ar1,align 64
 store <16 x i32> %r3,ptr %o3,align 1
 %o4 = getelementptr i8,ptr %out,i64 2048
 %r4 = load <16 x i32>,ptr %ar2,align 64
 store <16 x i32> %r4,ptr %o4,align 1
 %answer = xor i64 %h,%salt
 ret i64 %answer
}
define i64 @vector_storage_17_32(ptr %out,ptr %xp,ptr %yp,i64 %salt) {
entry:
 %av = alloca <17 x i32>,align 128
 %bv = alloca <17 x i32>,align 128
 %array = alloca [3 x <17 x i32>],align 128
 %ar0 = getelementptr [3 x <17 x i32>],ptr %array,i64 0,i64 0
 %ar1 = getelementptr [3 x <17 x i32>],ptr %array,i64 0,i64 1
 %ar2 = getelementptr [3 x <17 x i32>],ptr %array,i64 0,i64 2
 %x = load <17 x i32>,ptr %xp,align 1
 %y = load <17 x i32>,ptr %yp,align 1
 %v0 = add <17 x i32> %x,%y
 store <17 x i32> %v0,ptr %ar0,align 128
 %v1 = sub <17 x i32> %x,%y
 store <17 x i32> %v1,ptr %ar1,align 128
 %v2 = xor <17 x i32> %x,%y
 store <17 x i32> %v2,ptr %ar2,align 128
 store <17 x i32> %x,ptr %av,align 128
 store <17 x i32> %y,ptr %bv,align 128
 %h = call i64 @vector_storage_touch(ptr %av,ptr %bv,ptr %ar0,ptr %ar1,ptr %ar2,i64 68,i64 128)
 %o0 = getelementptr i8,ptr %out,i64 0
 %r0 = load <17 x i32>,ptr %av,align 128
 store <17 x i32> %r0,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 512
 %r1 = load <17 x i32>,ptr %bv,align 128
 store <17 x i32> %r1,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 1024
 %r2 = load <17 x i32>,ptr %ar0,align 128
 store <17 x i32> %r2,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 1536
 %r3 = load <17 x i32>,ptr %ar1,align 128
 store <17 x i32> %r3,ptr %o3,align 1
 %o4 = getelementptr i8,ptr %out,i64 2048
 %r4 = load <17 x i32>,ptr %ar2,align 128
 store <17 x i32> %r4,ptr %o4,align 1
 %answer = xor i64 %h,%salt
 ret i64 %answer
}
define i64 @vector_storage_3_64(ptr %out,ptr %xp,ptr %yp,i64 %salt) {
entry:
 %av = alloca <3 x i64>,align 32
 %bv = alloca <3 x i64>,align 32
 %array = alloca [3 x <3 x i64>],align 32
 %ar0 = getelementptr [3 x <3 x i64>],ptr %array,i64 0,i64 0
 %ar1 = getelementptr [3 x <3 x i64>],ptr %array,i64 0,i64 1
 %ar2 = getelementptr [3 x <3 x i64>],ptr %array,i64 0,i64 2
 %x = load <3 x i64>,ptr %xp,align 1
 %y = load <3 x i64>,ptr %yp,align 1
 %v0 = add <3 x i64> %x,%y
 store <3 x i64> %v0,ptr %ar0,align 32
 %v1 = sub <3 x i64> %x,%y
 store <3 x i64> %v1,ptr %ar1,align 32
 %v2 = xor <3 x i64> %x,%y
 store <3 x i64> %v2,ptr %ar2,align 32
 store <3 x i64> %x,ptr %av,align 32
 store <3 x i64> %y,ptr %bv,align 32
 %h = call i64 @vector_storage_touch(ptr %av,ptr %bv,ptr %ar0,ptr %ar1,ptr %ar2,i64 24,i64 32)
 %o0 = getelementptr i8,ptr %out,i64 0
 %r0 = load <3 x i64>,ptr %av,align 32
 store <3 x i64> %r0,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 512
 %r1 = load <3 x i64>,ptr %bv,align 32
 store <3 x i64> %r1,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 1024
 %r2 = load <3 x i64>,ptr %ar0,align 32
 store <3 x i64> %r2,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 1536
 %r3 = load <3 x i64>,ptr %ar1,align 32
 store <3 x i64> %r3,ptr %o3,align 1
 %o4 = getelementptr i8,ptr %out,i64 2048
 %r4 = load <3 x i64>,ptr %ar2,align 32
 store <3 x i64> %r4,ptr %o4,align 1
 %answer = xor i64 %h,%salt
 ret i64 %answer
}
define i64 @vector_storage_64_64(ptr %out,ptr %xp,ptr %yp,i64 %salt) {
entry:
 %av = alloca <64 x i64>,align 512
 %bv = alloca <64 x i64>,align 512
 %array = alloca [3 x <64 x i64>],align 512
 %ar0 = getelementptr [3 x <64 x i64>],ptr %array,i64 0,i64 0
 %ar1 = getelementptr [3 x <64 x i64>],ptr %array,i64 0,i64 1
 %ar2 = getelementptr [3 x <64 x i64>],ptr %array,i64 0,i64 2
 %x = load <64 x i64>,ptr %xp,align 1
 %y = load <64 x i64>,ptr %yp,align 1
 %v0 = add <64 x i64> %x,%y
 store <64 x i64> %v0,ptr %ar0,align 512
 %v1 = sub <64 x i64> %x,%y
 store <64 x i64> %v1,ptr %ar1,align 512
 %v2 = xor <64 x i64> %x,%y
 store <64 x i64> %v2,ptr %ar2,align 512
 store <64 x i64> %x,ptr %av,align 512
 store <64 x i64> %y,ptr %bv,align 512
 %h = call i64 @vector_storage_touch(ptr %av,ptr %bv,ptr %ar0,ptr %ar1,ptr %ar2,i64 512,i64 512)
 %o0 = getelementptr i8,ptr %out,i64 0
 %r0 = load <64 x i64>,ptr %av,align 512
 store <64 x i64> %r0,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 512
 %r1 = load <64 x i64>,ptr %bv,align 512
 store <64 x i64> %r1,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 1024
 %r2 = load <64 x i64>,ptr %ar0,align 512
 store <64 x i64> %r2,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 1536
 %r3 = load <64 x i64>,ptr %ar1,align 512
 store <64 x i64> %r3,ptr %o3,align 1
 %o4 = getelementptr i8,ptr %out,i64 2048
 %r4 = load <64 x i64>,ptr %ar2,align 512
 store <64 x i64> %r4,ptr %o4,align 1
 %answer = xor i64 %h,%salt
 ret i64 %answer
}
