target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"
declare i8 @llvm.vector.reduce.mul.v1i8(<1 x i8>)
define i64 @integer_vector_product_8_1_0(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load <1 x i8>,ptr %input,align 1
 %r = call i8 @llvm.vector.reduce.mul.v1i8(<1 x i8> %v)
 store i8 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc i64 @integer_vector_product_8_1_1(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load <1 x i8>,ptr %input,align 1
 %r = call i8 @llvm.vector.reduce.mul.v1i8(<1 x i8> %v)
 store i8 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i8 @llvm.vector.reduce.mul.v2i8(<2 x i8>)
define i64 @integer_vector_product_8_2_0(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load <2 x i8>,ptr %input,align 1
 %r = call i8 @llvm.vector.reduce.mul.v2i8(<2 x i8> %v)
 store i8 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc i64 @integer_vector_product_8_2_1(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load <2 x i8>,ptr %input,align 1
 %r = call i8 @llvm.vector.reduce.mul.v2i8(<2 x i8> %v)
 store i8 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i8 @llvm.vector.reduce.mul.v3i8(<3 x i8>)
define i64 @integer_vector_product_8_3_0(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load <3 x i8>,ptr %input,align 1
 %r = call i8 @llvm.vector.reduce.mul.v3i8(<3 x i8> %v)
 store i8 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc i64 @integer_vector_product_8_3_1(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load <3 x i8>,ptr %input,align 1
 %r = call i8 @llvm.vector.reduce.mul.v3i8(<3 x i8> %v)
 store i8 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i8 @llvm.vector.reduce.mul.v4i8(<4 x i8>)
define i64 @integer_vector_product_8_4_0(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load <4 x i8>,ptr %input,align 1
 %r = call i8 @llvm.vector.reduce.mul.v4i8(<4 x i8> %v)
 store i8 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc i64 @integer_vector_product_8_4_1(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load <4 x i8>,ptr %input,align 1
 %r = call i8 @llvm.vector.reduce.mul.v4i8(<4 x i8> %v)
 store i8 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i8 @llvm.vector.reduce.mul.v8i8(<8 x i8>)
define i64 @integer_vector_product_8_8_0(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load <8 x i8>,ptr %input,align 1
 %r = call i8 @llvm.vector.reduce.mul.v8i8(<8 x i8> %v)
 store i8 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc i64 @integer_vector_product_8_8_1(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load <8 x i8>,ptr %input,align 1
 %r = call i8 @llvm.vector.reduce.mul.v8i8(<8 x i8> %v)
 store i8 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i8 @llvm.vector.reduce.mul.v16i8(<16 x i8>)
define i64 @integer_vector_product_8_16_0(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load <16 x i8>,ptr %input,align 1
 %r = call i8 @llvm.vector.reduce.mul.v16i8(<16 x i8> %v)
 store i8 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc i64 @integer_vector_product_8_16_1(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load <16 x i8>,ptr %input,align 1
 %r = call i8 @llvm.vector.reduce.mul.v16i8(<16 x i8> %v)
 store i8 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i8 @llvm.vector.reduce.mul.v64i8(<64 x i8>)
define i64 @integer_vector_product_8_64_0(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load <64 x i8>,ptr %input,align 1
 %r = call i8 @llvm.vector.reduce.mul.v64i8(<64 x i8> %v)
 store i8 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc i64 @integer_vector_product_8_64_1(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load <64 x i8>,ptr %input,align 1
 %r = call i8 @llvm.vector.reduce.mul.v64i8(<64 x i8> %v)
 store i8 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i16 @llvm.vector.reduce.mul.v1i16(<1 x i16>)
define i64 @integer_vector_product_16_1_0(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load <1 x i16>,ptr %input,align 1
 %r = call i16 @llvm.vector.reduce.mul.v1i16(<1 x i16> %v)
 store i16 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc i64 @integer_vector_product_16_1_1(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load <1 x i16>,ptr %input,align 1
 %r = call i16 @llvm.vector.reduce.mul.v1i16(<1 x i16> %v)
 store i16 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i16 @llvm.vector.reduce.mul.v2i16(<2 x i16>)
define i64 @integer_vector_product_16_2_0(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load <2 x i16>,ptr %input,align 1
 %r = call i16 @llvm.vector.reduce.mul.v2i16(<2 x i16> %v)
 store i16 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc i64 @integer_vector_product_16_2_1(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load <2 x i16>,ptr %input,align 1
 %r = call i16 @llvm.vector.reduce.mul.v2i16(<2 x i16> %v)
 store i16 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i16 @llvm.vector.reduce.mul.v3i16(<3 x i16>)
define i64 @integer_vector_product_16_3_0(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load <3 x i16>,ptr %input,align 1
 %r = call i16 @llvm.vector.reduce.mul.v3i16(<3 x i16> %v)
 store i16 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc i64 @integer_vector_product_16_3_1(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load <3 x i16>,ptr %input,align 1
 %r = call i16 @llvm.vector.reduce.mul.v3i16(<3 x i16> %v)
 store i16 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i16 @llvm.vector.reduce.mul.v4i16(<4 x i16>)
define i64 @integer_vector_product_16_4_0(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load <4 x i16>,ptr %input,align 1
 %r = call i16 @llvm.vector.reduce.mul.v4i16(<4 x i16> %v)
 store i16 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc i64 @integer_vector_product_16_4_1(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load <4 x i16>,ptr %input,align 1
 %r = call i16 @llvm.vector.reduce.mul.v4i16(<4 x i16> %v)
 store i16 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i16 @llvm.vector.reduce.mul.v8i16(<8 x i16>)
define i64 @integer_vector_product_16_8_0(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load <8 x i16>,ptr %input,align 1
 %r = call i16 @llvm.vector.reduce.mul.v8i16(<8 x i16> %v)
 store i16 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc i64 @integer_vector_product_16_8_1(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load <8 x i16>,ptr %input,align 1
 %r = call i16 @llvm.vector.reduce.mul.v8i16(<8 x i16> %v)
 store i16 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i16 @llvm.vector.reduce.mul.v16i16(<16 x i16>)
define i64 @integer_vector_product_16_16_0(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load <16 x i16>,ptr %input,align 1
 %r = call i16 @llvm.vector.reduce.mul.v16i16(<16 x i16> %v)
 store i16 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc i64 @integer_vector_product_16_16_1(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load <16 x i16>,ptr %input,align 1
 %r = call i16 @llvm.vector.reduce.mul.v16i16(<16 x i16> %v)
 store i16 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i16 @llvm.vector.reduce.mul.v64i16(<64 x i16>)
define i64 @integer_vector_product_16_64_0(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load <64 x i16>,ptr %input,align 1
 %r = call i16 @llvm.vector.reduce.mul.v64i16(<64 x i16> %v)
 store i16 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc i64 @integer_vector_product_16_64_1(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load <64 x i16>,ptr %input,align 1
 %r = call i16 @llvm.vector.reduce.mul.v64i16(<64 x i16> %v)
 store i16 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i24 @llvm.vector.reduce.mul.v1i24(<1 x i24>)
define i64 @integer_vector_product_24_1_0(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load <1 x i24>,ptr %input,align 1
 %r = call i24 @llvm.vector.reduce.mul.v1i24(<1 x i24> %v)
 store i24 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc i64 @integer_vector_product_24_1_1(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load <1 x i24>,ptr %input,align 1
 %r = call i24 @llvm.vector.reduce.mul.v1i24(<1 x i24> %v)
 store i24 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i24 @llvm.vector.reduce.mul.v2i24(<2 x i24>)
define i64 @integer_vector_product_24_2_0(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load <2 x i24>,ptr %input,align 1
 %r = call i24 @llvm.vector.reduce.mul.v2i24(<2 x i24> %v)
 store i24 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc i64 @integer_vector_product_24_2_1(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load <2 x i24>,ptr %input,align 1
 %r = call i24 @llvm.vector.reduce.mul.v2i24(<2 x i24> %v)
 store i24 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i24 @llvm.vector.reduce.mul.v3i24(<3 x i24>)
define i64 @integer_vector_product_24_3_0(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load <3 x i24>,ptr %input,align 1
 %r = call i24 @llvm.vector.reduce.mul.v3i24(<3 x i24> %v)
 store i24 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc i64 @integer_vector_product_24_3_1(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load <3 x i24>,ptr %input,align 1
 %r = call i24 @llvm.vector.reduce.mul.v3i24(<3 x i24> %v)
 store i24 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i24 @llvm.vector.reduce.mul.v4i24(<4 x i24>)
define i64 @integer_vector_product_24_4_0(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load <4 x i24>,ptr %input,align 1
 %r = call i24 @llvm.vector.reduce.mul.v4i24(<4 x i24> %v)
 store i24 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc i64 @integer_vector_product_24_4_1(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load <4 x i24>,ptr %input,align 1
 %r = call i24 @llvm.vector.reduce.mul.v4i24(<4 x i24> %v)
 store i24 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i24 @llvm.vector.reduce.mul.v8i24(<8 x i24>)
define i64 @integer_vector_product_24_8_0(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load <8 x i24>,ptr %input,align 1
 %r = call i24 @llvm.vector.reduce.mul.v8i24(<8 x i24> %v)
 store i24 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc i64 @integer_vector_product_24_8_1(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load <8 x i24>,ptr %input,align 1
 %r = call i24 @llvm.vector.reduce.mul.v8i24(<8 x i24> %v)
 store i24 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i24 @llvm.vector.reduce.mul.v16i24(<16 x i24>)
define i64 @integer_vector_product_24_16_0(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load <16 x i24>,ptr %input,align 1
 %r = call i24 @llvm.vector.reduce.mul.v16i24(<16 x i24> %v)
 store i24 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc i64 @integer_vector_product_24_16_1(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load <16 x i24>,ptr %input,align 1
 %r = call i24 @llvm.vector.reduce.mul.v16i24(<16 x i24> %v)
 store i24 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i24 @llvm.vector.reduce.mul.v64i24(<64 x i24>)
define i64 @integer_vector_product_24_64_0(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load <64 x i24>,ptr %input,align 1
 %r = call i24 @llvm.vector.reduce.mul.v64i24(<64 x i24> %v)
 store i24 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc i64 @integer_vector_product_24_64_1(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load <64 x i24>,ptr %input,align 1
 %r = call i24 @llvm.vector.reduce.mul.v64i24(<64 x i24> %v)
 store i24 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i32 @llvm.vector.reduce.mul.v1i32(<1 x i32>)
define i64 @integer_vector_product_32_1_0(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load <1 x i32>,ptr %input,align 1
 %r = call i32 @llvm.vector.reduce.mul.v1i32(<1 x i32> %v)
 store i32 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc i64 @integer_vector_product_32_1_1(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load <1 x i32>,ptr %input,align 1
 %r = call i32 @llvm.vector.reduce.mul.v1i32(<1 x i32> %v)
 store i32 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i32 @llvm.vector.reduce.mul.v2i32(<2 x i32>)
define i64 @integer_vector_product_32_2_0(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load <2 x i32>,ptr %input,align 1
 %r = call i32 @llvm.vector.reduce.mul.v2i32(<2 x i32> %v)
 store i32 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc i64 @integer_vector_product_32_2_1(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load <2 x i32>,ptr %input,align 1
 %r = call i32 @llvm.vector.reduce.mul.v2i32(<2 x i32> %v)
 store i32 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i32 @llvm.vector.reduce.mul.v3i32(<3 x i32>)
define i64 @integer_vector_product_32_3_0(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load <3 x i32>,ptr %input,align 1
 %r = call i32 @llvm.vector.reduce.mul.v3i32(<3 x i32> %v)
 store i32 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc i64 @integer_vector_product_32_3_1(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load <3 x i32>,ptr %input,align 1
 %r = call i32 @llvm.vector.reduce.mul.v3i32(<3 x i32> %v)
 store i32 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i32 @llvm.vector.reduce.mul.v4i32(<4 x i32>)
define i64 @integer_vector_product_32_4_0(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load <4 x i32>,ptr %input,align 1
 %r = call i32 @llvm.vector.reduce.mul.v4i32(<4 x i32> %v)
 store i32 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc i64 @integer_vector_product_32_4_1(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load <4 x i32>,ptr %input,align 1
 %r = call i32 @llvm.vector.reduce.mul.v4i32(<4 x i32> %v)
 store i32 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i32 @llvm.vector.reduce.mul.v8i32(<8 x i32>)
define i64 @integer_vector_product_32_8_0(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load <8 x i32>,ptr %input,align 1
 %r = call i32 @llvm.vector.reduce.mul.v8i32(<8 x i32> %v)
 store i32 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc i64 @integer_vector_product_32_8_1(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load <8 x i32>,ptr %input,align 1
 %r = call i32 @llvm.vector.reduce.mul.v8i32(<8 x i32> %v)
 store i32 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i32 @llvm.vector.reduce.mul.v16i32(<16 x i32>)
define i64 @integer_vector_product_32_16_0(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load <16 x i32>,ptr %input,align 1
 %r = call i32 @llvm.vector.reduce.mul.v16i32(<16 x i32> %v)
 store i32 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc i64 @integer_vector_product_32_16_1(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load <16 x i32>,ptr %input,align 1
 %r = call i32 @llvm.vector.reduce.mul.v16i32(<16 x i32> %v)
 store i32 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i32 @llvm.vector.reduce.mul.v64i32(<64 x i32>)
define i64 @integer_vector_product_32_64_0(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load <64 x i32>,ptr %input,align 1
 %r = call i32 @llvm.vector.reduce.mul.v64i32(<64 x i32> %v)
 store i32 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc i64 @integer_vector_product_32_64_1(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load <64 x i32>,ptr %input,align 1
 %r = call i32 @llvm.vector.reduce.mul.v64i32(<64 x i32> %v)
 store i32 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i48 @llvm.vector.reduce.mul.v1i48(<1 x i48>)
define i64 @integer_vector_product_48_1_0(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load <1 x i48>,ptr %input,align 1
 %r = call i48 @llvm.vector.reduce.mul.v1i48(<1 x i48> %v)
 store i48 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc i64 @integer_vector_product_48_1_1(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load <1 x i48>,ptr %input,align 1
 %r = call i48 @llvm.vector.reduce.mul.v1i48(<1 x i48> %v)
 store i48 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i48 @llvm.vector.reduce.mul.v2i48(<2 x i48>)
define i64 @integer_vector_product_48_2_0(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load <2 x i48>,ptr %input,align 1
 %r = call i48 @llvm.vector.reduce.mul.v2i48(<2 x i48> %v)
 store i48 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc i64 @integer_vector_product_48_2_1(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load <2 x i48>,ptr %input,align 1
 %r = call i48 @llvm.vector.reduce.mul.v2i48(<2 x i48> %v)
 store i48 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i48 @llvm.vector.reduce.mul.v3i48(<3 x i48>)
define i64 @integer_vector_product_48_3_0(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load <3 x i48>,ptr %input,align 1
 %r = call i48 @llvm.vector.reduce.mul.v3i48(<3 x i48> %v)
 store i48 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc i64 @integer_vector_product_48_3_1(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load <3 x i48>,ptr %input,align 1
 %r = call i48 @llvm.vector.reduce.mul.v3i48(<3 x i48> %v)
 store i48 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i48 @llvm.vector.reduce.mul.v4i48(<4 x i48>)
define i64 @integer_vector_product_48_4_0(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load <4 x i48>,ptr %input,align 1
 %r = call i48 @llvm.vector.reduce.mul.v4i48(<4 x i48> %v)
 store i48 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc i64 @integer_vector_product_48_4_1(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load <4 x i48>,ptr %input,align 1
 %r = call i48 @llvm.vector.reduce.mul.v4i48(<4 x i48> %v)
 store i48 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i48 @llvm.vector.reduce.mul.v8i48(<8 x i48>)
define i64 @integer_vector_product_48_8_0(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load <8 x i48>,ptr %input,align 1
 %r = call i48 @llvm.vector.reduce.mul.v8i48(<8 x i48> %v)
 store i48 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc i64 @integer_vector_product_48_8_1(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load <8 x i48>,ptr %input,align 1
 %r = call i48 @llvm.vector.reduce.mul.v8i48(<8 x i48> %v)
 store i48 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i48 @llvm.vector.reduce.mul.v16i48(<16 x i48>)
define i64 @integer_vector_product_48_16_0(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load <16 x i48>,ptr %input,align 1
 %r = call i48 @llvm.vector.reduce.mul.v16i48(<16 x i48> %v)
 store i48 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc i64 @integer_vector_product_48_16_1(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load <16 x i48>,ptr %input,align 1
 %r = call i48 @llvm.vector.reduce.mul.v16i48(<16 x i48> %v)
 store i48 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i48 @llvm.vector.reduce.mul.v64i48(<64 x i48>)
define i64 @integer_vector_product_48_64_0(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load <64 x i48>,ptr %input,align 1
 %r = call i48 @llvm.vector.reduce.mul.v64i48(<64 x i48> %v)
 store i48 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc i64 @integer_vector_product_48_64_1(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load <64 x i48>,ptr %input,align 1
 %r = call i48 @llvm.vector.reduce.mul.v64i48(<64 x i48> %v)
 store i48 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i64 @llvm.vector.reduce.mul.v1i64(<1 x i64>)
define i64 @integer_vector_product_64_1_0(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load <1 x i64>,ptr %input,align 1
 %r = call i64 @llvm.vector.reduce.mul.v1i64(<1 x i64> %v)
 store i64 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc i64 @integer_vector_product_64_1_1(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load <1 x i64>,ptr %input,align 1
 %r = call i64 @llvm.vector.reduce.mul.v1i64(<1 x i64> %v)
 store i64 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i64 @llvm.vector.reduce.mul.v2i64(<2 x i64>)
define i64 @integer_vector_product_64_2_0(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load <2 x i64>,ptr %input,align 1
 %r = call i64 @llvm.vector.reduce.mul.v2i64(<2 x i64> %v)
 store i64 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc i64 @integer_vector_product_64_2_1(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load <2 x i64>,ptr %input,align 1
 %r = call i64 @llvm.vector.reduce.mul.v2i64(<2 x i64> %v)
 store i64 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i64 @llvm.vector.reduce.mul.v3i64(<3 x i64>)
define i64 @integer_vector_product_64_3_0(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load <3 x i64>,ptr %input,align 1
 %r = call i64 @llvm.vector.reduce.mul.v3i64(<3 x i64> %v)
 store i64 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc i64 @integer_vector_product_64_3_1(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load <3 x i64>,ptr %input,align 1
 %r = call i64 @llvm.vector.reduce.mul.v3i64(<3 x i64> %v)
 store i64 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i64 @llvm.vector.reduce.mul.v4i64(<4 x i64>)
define i64 @integer_vector_product_64_4_0(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load <4 x i64>,ptr %input,align 1
 %r = call i64 @llvm.vector.reduce.mul.v4i64(<4 x i64> %v)
 store i64 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc i64 @integer_vector_product_64_4_1(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load <4 x i64>,ptr %input,align 1
 %r = call i64 @llvm.vector.reduce.mul.v4i64(<4 x i64> %v)
 store i64 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i64 @llvm.vector.reduce.mul.v8i64(<8 x i64>)
define i64 @integer_vector_product_64_8_0(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load <8 x i64>,ptr %input,align 1
 %r = call i64 @llvm.vector.reduce.mul.v8i64(<8 x i64> %v)
 store i64 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc i64 @integer_vector_product_64_8_1(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load <8 x i64>,ptr %input,align 1
 %r = call i64 @llvm.vector.reduce.mul.v8i64(<8 x i64> %v)
 store i64 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i64 @llvm.vector.reduce.mul.v16i64(<16 x i64>)
define i64 @integer_vector_product_64_16_0(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load <16 x i64>,ptr %input,align 1
 %r = call i64 @llvm.vector.reduce.mul.v16i64(<16 x i64> %v)
 store i64 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc i64 @integer_vector_product_64_16_1(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load <16 x i64>,ptr %input,align 1
 %r = call i64 @llvm.vector.reduce.mul.v16i64(<16 x i64> %v)
 store i64 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i64 @llvm.vector.reduce.mul.v64i64(<64 x i64>)
define i64 @integer_vector_product_64_64_0(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load <64 x i64>,ptr %input,align 1
 %r = call i64 @llvm.vector.reduce.mul.v64i64(<64 x i64> %v)
 store i64 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc i64 @integer_vector_product_64_64_1(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load <64 x i64>,ptr %input,align 1
 %r = call i64 @llvm.vector.reduce.mul.v64i64(<64 x i64> %v)
 store i64 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i128 @llvm.vector.reduce.mul.v1i128(<1 x i128>)
define i64 @integer_vector_product_128_1_0(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load <1 x i128>,ptr %input,align 1
 %r = call i128 @llvm.vector.reduce.mul.v1i128(<1 x i128> %v)
 store i128 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc i64 @integer_vector_product_128_1_1(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load <1 x i128>,ptr %input,align 1
 %r = call i128 @llvm.vector.reduce.mul.v1i128(<1 x i128> %v)
 store i128 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i128 @llvm.vector.reduce.mul.v2i128(<2 x i128>)
define i64 @integer_vector_product_128_2_0(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load <2 x i128>,ptr %input,align 1
 %r = call i128 @llvm.vector.reduce.mul.v2i128(<2 x i128> %v)
 store i128 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc i64 @integer_vector_product_128_2_1(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load <2 x i128>,ptr %input,align 1
 %r = call i128 @llvm.vector.reduce.mul.v2i128(<2 x i128> %v)
 store i128 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i128 @llvm.vector.reduce.mul.v3i128(<3 x i128>)
define i64 @integer_vector_product_128_3_0(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load <3 x i128>,ptr %input,align 1
 %r = call i128 @llvm.vector.reduce.mul.v3i128(<3 x i128> %v)
 store i128 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc i64 @integer_vector_product_128_3_1(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load <3 x i128>,ptr %input,align 1
 %r = call i128 @llvm.vector.reduce.mul.v3i128(<3 x i128> %v)
 store i128 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i128 @llvm.vector.reduce.mul.v4i128(<4 x i128>)
define i64 @integer_vector_product_128_4_0(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load <4 x i128>,ptr %input,align 1
 %r = call i128 @llvm.vector.reduce.mul.v4i128(<4 x i128> %v)
 store i128 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc i64 @integer_vector_product_128_4_1(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load <4 x i128>,ptr %input,align 1
 %r = call i128 @llvm.vector.reduce.mul.v4i128(<4 x i128> %v)
 store i128 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i128 @llvm.vector.reduce.mul.v8i128(<8 x i128>)
define i64 @integer_vector_product_128_8_0(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load <8 x i128>,ptr %input,align 1
 %r = call i128 @llvm.vector.reduce.mul.v8i128(<8 x i128> %v)
 store i128 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc i64 @integer_vector_product_128_8_1(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load <8 x i128>,ptr %input,align 1
 %r = call i128 @llvm.vector.reduce.mul.v8i128(<8 x i128> %v)
 store i128 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i128 @llvm.vector.reduce.mul.v16i128(<16 x i128>)
define i64 @integer_vector_product_128_16_0(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load <16 x i128>,ptr %input,align 1
 %r = call i128 @llvm.vector.reduce.mul.v16i128(<16 x i128> %v)
 store i128 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc i64 @integer_vector_product_128_16_1(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load <16 x i128>,ptr %input,align 1
 %r = call i128 @llvm.vector.reduce.mul.v16i128(<16 x i128> %v)
 store i128 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i128 @llvm.vector.reduce.mul.v64i128(<64 x i128>)
define i64 @integer_vector_product_128_64_0(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load <64 x i128>,ptr %input,align 1
 %r = call i128 @llvm.vector.reduce.mul.v64i128(<64 x i128> %v)
 store i128 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc i64 @integer_vector_product_128_64_1(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load <64 x i128>,ptr %input,align 1
 %r = call i128 @llvm.vector.reduce.mul.v64i128(<64 x i128> %v)
 store i128 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
