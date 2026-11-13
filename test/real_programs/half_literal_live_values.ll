target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"
declare i64 @complete_clobber(i64,i64,i64,i64,i64,i64,i64,i64)
declare half @llvm.vector.reduce.fadd.v4f16(half,<4 x half>)
define i64 @half_literal_live_probe_0(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %word = load i64,ptr %input,align 1
 %kept = icmp ult i64 %word,%salt
 %sum = fadd half 0xH0000,0xH3C00
 %raw = bitcast half %sum to i16
 %nan = fcmp uno half %sum,0xH0000
 %stable = select i1 %nan,i16 32256,i16 %raw
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %wide = zext i1 %kept to i64
 store i64 %wide,ptr %out,align 1
 %fp_out = getelementptr i8,ptr %out,i64 8
 store i16 %stable,ptr %fp_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 10
 store i64 %token,ptr %token_out,align 1
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @half_literal_live_probe_1(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %word = load i64,ptr %input,align 1
 %seed_pointer = getelementptr i8,ptr %input,i64 8
 %seed = load half,ptr %seed_pointer,align 1
 %kept = icmp ult i64 %word,%salt
 %sum = fadd half %seed,0xH3C00
 %raw = bitcast half %sum to i16
 %nan = fcmp uno half %sum,0xH0000
 %stable = select i1 %nan,i16 32256,i16 %raw
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %wide = zext i1 %kept to i64
 store i64 %wide,ptr %out,align 1
 %fp_out = getelementptr i8,ptr %out,i64 8
 store i16 %stable,ptr %fp_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 10
 store i64 %token,ptr %token_out,align 1
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @half_literal_live_probe_2(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %word = load i64,ptr %input,align 1
 %kept = icmp ult i64 %word,%salt
 %sum = tail call half @llvm.vector.reduce.fadd.v4f16(half 0xH0000,<4 x half> <half 0xH3C00,half 0xH0000,half 0xH0000,half 0xH0000>)
 %raw = bitcast half %sum to i16
 %nan = fcmp uno half %sum,0xH0000
 %stable = select i1 %nan,i16 32256,i16 %raw
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %wide = zext i1 %kept to i64
 store i64 %wide,ptr %out,align 1
 %fp_out = getelementptr i8,ptr %out,i64 8
 store i16 %stable,ptr %fp_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 10
 store i64 %token,ptr %token_out,align 1
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @half_literal_live_probe_3(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %word = load i64,ptr %input,align 1
 %seed_pointer = getelementptr i8,ptr %input,i64 8
 %seed = load half,ptr %seed_pointer,align 1
 %kept = icmp ult i64 %word,%salt
 %sum = notail call half @llvm.vector.reduce.fadd.v4f16(half %seed,<4 x half> <half 0xH3C00,half 0xH0000,half 0xH0000,half 0xH0000>)
 %raw = bitcast half %sum to i16
 %nan = fcmp uno half %sum,0xH0000
 %stable = select i1 %nan,i16 32256,i16 %raw
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %wide = zext i1 %kept to i64
 store i64 %wide,ptr %out,align 1
 %fp_out = getelementptr i8,ptr %out,i64 8
 store i16 %stable,ptr %fp_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 10
 store i64 %token,ptr %token_out,align 1
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @half_literal_live_probe_4(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %word = load i64,ptr %input,align 1
 %kept = icmp ult i64 %word,%salt
 %sum = fadd half 0xH8000,0xH8000
 %raw = bitcast half %sum to i16
 %nan = fcmp uno half %sum,0xH0000
 %stable = select i1 %nan,i16 32256,i16 %raw
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %wide = zext i1 %kept to i64
 store i64 %wide,ptr %out,align 1
 %fp_out = getelementptr i8,ptr %out,i64 8
 store i16 %stable,ptr %fp_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 10
 store i64 %token,ptr %token_out,align 1
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @half_literal_live_probe_5(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %word = load i64,ptr %input,align 1
 %seed_pointer = getelementptr i8,ptr %input,i64 8
 %seed = load half,ptr %seed_pointer,align 1
 %kept = icmp ult i64 %word,%salt
 %sum = fadd half %seed,0xH8000
 %raw = bitcast half %sum to i16
 %nan = fcmp uno half %sum,0xH0000
 %stable = select i1 %nan,i16 32256,i16 %raw
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %wide = zext i1 %kept to i64
 store i64 %wide,ptr %out,align 1
 %fp_out = getelementptr i8,ptr %out,i64 8
 store i16 %stable,ptr %fp_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 10
 store i64 %token,ptr %token_out,align 1
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @half_literal_live_probe_6(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %word = load i64,ptr %input,align 1
 %kept = icmp ult i64 %word,%salt
 %sum = tail call half @llvm.vector.reduce.fadd.v4f16(half 0xH8000,<4 x half> <half 0xH8000,half 0xH0000,half 0xH0000,half 0xH0000>)
 %raw = bitcast half %sum to i16
 %nan = fcmp uno half %sum,0xH0000
 %stable = select i1 %nan,i16 32256,i16 %raw
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %wide = zext i1 %kept to i64
 store i64 %wide,ptr %out,align 1
 %fp_out = getelementptr i8,ptr %out,i64 8
 store i16 %stable,ptr %fp_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 10
 store i64 %token,ptr %token_out,align 1
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @half_literal_live_probe_7(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %word = load i64,ptr %input,align 1
 %seed_pointer = getelementptr i8,ptr %input,i64 8
 %seed = load half,ptr %seed_pointer,align 1
 %kept = icmp ult i64 %word,%salt
 %sum = notail call half @llvm.vector.reduce.fadd.v4f16(half %seed,<4 x half> <half 0xH8000,half 0xH0000,half 0xH0000,half 0xH0000>)
 %raw = bitcast half %sum to i16
 %nan = fcmp uno half %sum,0xH0000
 %stable = select i1 %nan,i16 32256,i16 %raw
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %wide = zext i1 %kept to i64
 store i64 %wide,ptr %out,align 1
 %fp_out = getelementptr i8,ptr %out,i64 8
 store i16 %stable,ptr %fp_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 10
 store i64 %token,ptr %token_out,align 1
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @half_literal_live_probe_8(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %word = load i64,ptr %input,align 1
 %kept = icmp ult i64 %word,%salt
 %sum = fadd half 0xH3E00,0xH4080
 %raw = bitcast half %sum to i16
 %nan = fcmp uno half %sum,0xH0000
 %stable = select i1 %nan,i16 32256,i16 %raw
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %wide = zext i1 %kept to i64
 store i64 %wide,ptr %out,align 1
 %fp_out = getelementptr i8,ptr %out,i64 8
 store i16 %stable,ptr %fp_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 10
 store i64 %token,ptr %token_out,align 1
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @half_literal_live_probe_9(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %word = load i64,ptr %input,align 1
 %seed_pointer = getelementptr i8,ptr %input,i64 8
 %seed = load half,ptr %seed_pointer,align 1
 %kept = icmp ult i64 %word,%salt
 %sum = fadd half %seed,0xH4080
 %raw = bitcast half %sum to i16
 %nan = fcmp uno half %sum,0xH0000
 %stable = select i1 %nan,i16 32256,i16 %raw
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %wide = zext i1 %kept to i64
 store i64 %wide,ptr %out,align 1
 %fp_out = getelementptr i8,ptr %out,i64 8
 store i16 %stable,ptr %fp_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 10
 store i64 %token,ptr %token_out,align 1
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @half_literal_live_probe_10(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %word = load i64,ptr %input,align 1
 %kept = icmp ult i64 %word,%salt
 %sum = tail call half @llvm.vector.reduce.fadd.v4f16(half 0xH3E00,<4 x half> <half 0xH4080,half 0xH0000,half 0xH0000,half 0xH0000>)
 %raw = bitcast half %sum to i16
 %nan = fcmp uno half %sum,0xH0000
 %stable = select i1 %nan,i16 32256,i16 %raw
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %wide = zext i1 %kept to i64
 store i64 %wide,ptr %out,align 1
 %fp_out = getelementptr i8,ptr %out,i64 8
 store i16 %stable,ptr %fp_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 10
 store i64 %token,ptr %token_out,align 1
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @half_literal_live_probe_11(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %word = load i64,ptr %input,align 1
 %seed_pointer = getelementptr i8,ptr %input,i64 8
 %seed = load half,ptr %seed_pointer,align 1
 %kept = icmp ult i64 %word,%salt
 %sum = notail call half @llvm.vector.reduce.fadd.v4f16(half %seed,<4 x half> <half 0xH4080,half 0xH0000,half 0xH0000,half 0xH0000>)
 %raw = bitcast half %sum to i16
 %nan = fcmp uno half %sum,0xH0000
 %stable = select i1 %nan,i16 32256,i16 %raw
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %wide = zext i1 %kept to i64
 store i64 %wide,ptr %out,align 1
 %fp_out = getelementptr i8,ptr %out,i64 8
 store i16 %stable,ptr %fp_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 10
 store i64 %token,ptr %token_out,align 1
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @half_literal_live_probe_12(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %word = load i64,ptr %input,align 1
 %kept = icmp ult i64 %word,%salt
 %sum = fadd half 0xHC000,0xH3800
 %raw = bitcast half %sum to i16
 %nan = fcmp uno half %sum,0xH0000
 %stable = select i1 %nan,i16 32256,i16 %raw
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %wide = zext i1 %kept to i64
 store i64 %wide,ptr %out,align 1
 %fp_out = getelementptr i8,ptr %out,i64 8
 store i16 %stable,ptr %fp_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 10
 store i64 %token,ptr %token_out,align 1
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @half_literal_live_probe_13(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %word = load i64,ptr %input,align 1
 %seed_pointer = getelementptr i8,ptr %input,i64 8
 %seed = load half,ptr %seed_pointer,align 1
 %kept = icmp ult i64 %word,%salt
 %sum = fadd half %seed,0xH3800
 %raw = bitcast half %sum to i16
 %nan = fcmp uno half %sum,0xH0000
 %stable = select i1 %nan,i16 32256,i16 %raw
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %wide = zext i1 %kept to i64
 store i64 %wide,ptr %out,align 1
 %fp_out = getelementptr i8,ptr %out,i64 8
 store i16 %stable,ptr %fp_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 10
 store i64 %token,ptr %token_out,align 1
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @half_literal_live_probe_14(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %word = load i64,ptr %input,align 1
 %kept = icmp ult i64 %word,%salt
 %sum = tail call half @llvm.vector.reduce.fadd.v4f16(half 0xHC000,<4 x half> <half 0xH3800,half 0xH0000,half 0xH0000,half 0xH0000>)
 %raw = bitcast half %sum to i16
 %nan = fcmp uno half %sum,0xH0000
 %stable = select i1 %nan,i16 32256,i16 %raw
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %wide = zext i1 %kept to i64
 store i64 %wide,ptr %out,align 1
 %fp_out = getelementptr i8,ptr %out,i64 8
 store i16 %stable,ptr %fp_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 10
 store i64 %token,ptr %token_out,align 1
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @half_literal_live_probe_15(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %word = load i64,ptr %input,align 1
 %seed_pointer = getelementptr i8,ptr %input,i64 8
 %seed = load half,ptr %seed_pointer,align 1
 %kept = icmp ult i64 %word,%salt
 %sum = notail call half @llvm.vector.reduce.fadd.v4f16(half %seed,<4 x half> <half 0xH3800,half 0xH0000,half 0xH0000,half 0xH0000>)
 %raw = bitcast half %sum to i16
 %nan = fcmp uno half %sum,0xH0000
 %stable = select i1 %nan,i16 32256,i16 %raw
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %wide = zext i1 %kept to i64
 store i64 %wide,ptr %out,align 1
 %fp_out = getelementptr i8,ptr %out,i64 8
 store i16 %stable,ptr %fp_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 10
 store i64 %token,ptr %token_out,align 1
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @half_literal_live_probe_16(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %word = load i64,ptr %input,align 1
 %kept = icmp ult i64 %word,%salt
 %sum = fadd half 0xH7C00,0xHFC00
 %raw = bitcast half %sum to i16
 %nan = fcmp uno half %sum,0xH0000
 %stable = select i1 %nan,i16 32256,i16 %raw
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %wide = zext i1 %kept to i64
 store i64 %wide,ptr %out,align 1
 %fp_out = getelementptr i8,ptr %out,i64 8
 store i16 %stable,ptr %fp_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 10
 store i64 %token,ptr %token_out,align 1
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @half_literal_live_probe_17(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %word = load i64,ptr %input,align 1
 %seed_pointer = getelementptr i8,ptr %input,i64 8
 %seed = load half,ptr %seed_pointer,align 1
 %kept = icmp ult i64 %word,%salt
 %sum = fadd half %seed,0xHFC00
 %raw = bitcast half %sum to i16
 %nan = fcmp uno half %sum,0xH0000
 %stable = select i1 %nan,i16 32256,i16 %raw
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %wide = zext i1 %kept to i64
 store i64 %wide,ptr %out,align 1
 %fp_out = getelementptr i8,ptr %out,i64 8
 store i16 %stable,ptr %fp_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 10
 store i64 %token,ptr %token_out,align 1
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @half_literal_live_probe_18(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %word = load i64,ptr %input,align 1
 %kept = icmp ult i64 %word,%salt
 %sum = tail call half @llvm.vector.reduce.fadd.v4f16(half 0xH7C00,<4 x half> <half 0xHFC00,half 0xH0000,half 0xH0000,half 0xH0000>)
 %raw = bitcast half %sum to i16
 %nan = fcmp uno half %sum,0xH0000
 %stable = select i1 %nan,i16 32256,i16 %raw
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %wide = zext i1 %kept to i64
 store i64 %wide,ptr %out,align 1
 %fp_out = getelementptr i8,ptr %out,i64 8
 store i16 %stable,ptr %fp_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 10
 store i64 %token,ptr %token_out,align 1
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @half_literal_live_probe_19(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %word = load i64,ptr %input,align 1
 %seed_pointer = getelementptr i8,ptr %input,i64 8
 %seed = load half,ptr %seed_pointer,align 1
 %kept = icmp ult i64 %word,%salt
 %sum = notail call half @llvm.vector.reduce.fadd.v4f16(half %seed,<4 x half> <half 0xHFC00,half 0xH0000,half 0xH0000,half 0xH0000>)
 %raw = bitcast half %sum to i16
 %nan = fcmp uno half %sum,0xH0000
 %stable = select i1 %nan,i16 32256,i16 %raw
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %wide = zext i1 %kept to i64
 store i64 %wide,ptr %out,align 1
 %fp_out = getelementptr i8,ptr %out,i64 8
 store i16 %stable,ptr %fp_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 10
 store i64 %token,ptr %token_out,align 1
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @half_literal_live_probe_20(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %word = load i64,ptr %input,align 1
 %kept = icmp ult i64 %word,%salt
 %sum = fadd half 0xH7E00,0xH3C00
 %raw = bitcast half %sum to i16
 %nan = fcmp uno half %sum,0xH0000
 %stable = select i1 %nan,i16 32256,i16 %raw
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %wide = zext i1 %kept to i64
 store i64 %wide,ptr %out,align 1
 %fp_out = getelementptr i8,ptr %out,i64 8
 store i16 %stable,ptr %fp_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 10
 store i64 %token,ptr %token_out,align 1
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @half_literal_live_probe_21(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %word = load i64,ptr %input,align 1
 %seed_pointer = getelementptr i8,ptr %input,i64 8
 %seed = load half,ptr %seed_pointer,align 1
 %kept = icmp ult i64 %word,%salt
 %sum = fadd half %seed,0xH3C00
 %raw = bitcast half %sum to i16
 %nan = fcmp uno half %sum,0xH0000
 %stable = select i1 %nan,i16 32256,i16 %raw
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %wide = zext i1 %kept to i64
 store i64 %wide,ptr %out,align 1
 %fp_out = getelementptr i8,ptr %out,i64 8
 store i16 %stable,ptr %fp_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 10
 store i64 %token,ptr %token_out,align 1
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @half_literal_live_probe_22(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %word = load i64,ptr %input,align 1
 %kept = icmp ult i64 %word,%salt
 %sum = tail call half @llvm.vector.reduce.fadd.v4f16(half 0xH7E00,<4 x half> <half 0xH3C00,half 0xH0000,half 0xH0000,half 0xH0000>)
 %raw = bitcast half %sum to i16
 %nan = fcmp uno half %sum,0xH0000
 %stable = select i1 %nan,i16 32256,i16 %raw
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %wide = zext i1 %kept to i64
 store i64 %wide,ptr %out,align 1
 %fp_out = getelementptr i8,ptr %out,i64 8
 store i16 %stable,ptr %fp_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 10
 store i64 %token,ptr %token_out,align 1
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @half_literal_live_probe_23(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %word = load i64,ptr %input,align 1
 %seed_pointer = getelementptr i8,ptr %input,i64 8
 %seed = load half,ptr %seed_pointer,align 1
 %kept = icmp ult i64 %word,%salt
 %sum = notail call half @llvm.vector.reduce.fadd.v4f16(half %seed,<4 x half> <half 0xH3C00,half 0xH0000,half 0xH0000,half 0xH0000>)
 %raw = bitcast half %sum to i16
 %nan = fcmp uno half %sum,0xH0000
 %stable = select i1 %nan,i16 32256,i16 %raw
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %wide = zext i1 %kept to i64
 store i64 %wide,ptr %out,align 1
 %fp_out = getelementptr i8,ptr %out,i64 8
 store i16 %stable,ptr %fp_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 10
 store i64 %token,ptr %token_out,align 1
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @half_literal_live_probe_24(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %word = load i64,ptr %input,align 1
 %salt32 = trunc i64 %salt to i32
 %word32 = trunc i64 %word to i32
 %kept = xor i32 %salt32,%word32
 %sum = fadd half 0xH0000,0xH3C00
 %raw = bitcast half %sum to i16
 %nan = fcmp uno half %sum,0xH0000
 %stable = select i1 %nan,i16 32256,i16 %raw
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %wide = zext i32 %kept to i64
 store i64 %wide,ptr %out,align 1
 %fp_out = getelementptr i8,ptr %out,i64 8
 store i16 %stable,ptr %fp_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 10
 store i64 %token,ptr %token_out,align 1
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @half_literal_live_probe_25(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %word = load i64,ptr %input,align 1
 %seed_pointer = getelementptr i8,ptr %input,i64 8
 %seed = load half,ptr %seed_pointer,align 1
 %salt32 = trunc i64 %salt to i32
 %word32 = trunc i64 %word to i32
 %kept = xor i32 %salt32,%word32
 %sum = fadd half %seed,0xH3C00
 %raw = bitcast half %sum to i16
 %nan = fcmp uno half %sum,0xH0000
 %stable = select i1 %nan,i16 32256,i16 %raw
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %wide = zext i32 %kept to i64
 store i64 %wide,ptr %out,align 1
 %fp_out = getelementptr i8,ptr %out,i64 8
 store i16 %stable,ptr %fp_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 10
 store i64 %token,ptr %token_out,align 1
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @half_literal_live_probe_26(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %word = load i64,ptr %input,align 1
 %salt32 = trunc i64 %salt to i32
 %word32 = trunc i64 %word to i32
 %kept = xor i32 %salt32,%word32
 %sum = tail call half @llvm.vector.reduce.fadd.v4f16(half 0xH0000,<4 x half> <half 0xH3C00,half 0xH0000,half 0xH0000,half 0xH0000>)
 %raw = bitcast half %sum to i16
 %nan = fcmp uno half %sum,0xH0000
 %stable = select i1 %nan,i16 32256,i16 %raw
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %wide = zext i32 %kept to i64
 store i64 %wide,ptr %out,align 1
 %fp_out = getelementptr i8,ptr %out,i64 8
 store i16 %stable,ptr %fp_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 10
 store i64 %token,ptr %token_out,align 1
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @half_literal_live_probe_27(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %word = load i64,ptr %input,align 1
 %seed_pointer = getelementptr i8,ptr %input,i64 8
 %seed = load half,ptr %seed_pointer,align 1
 %salt32 = trunc i64 %salt to i32
 %word32 = trunc i64 %word to i32
 %kept = xor i32 %salt32,%word32
 %sum = notail call half @llvm.vector.reduce.fadd.v4f16(half %seed,<4 x half> <half 0xH3C00,half 0xH0000,half 0xH0000,half 0xH0000>)
 %raw = bitcast half %sum to i16
 %nan = fcmp uno half %sum,0xH0000
 %stable = select i1 %nan,i16 32256,i16 %raw
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %wide = zext i32 %kept to i64
 store i64 %wide,ptr %out,align 1
 %fp_out = getelementptr i8,ptr %out,i64 8
 store i16 %stable,ptr %fp_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 10
 store i64 %token,ptr %token_out,align 1
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @half_literal_live_probe_28(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %word = load i64,ptr %input,align 1
 %salt32 = trunc i64 %salt to i32
 %word32 = trunc i64 %word to i32
 %kept = xor i32 %salt32,%word32
 %sum = fadd half 0xH8000,0xH8000
 %raw = bitcast half %sum to i16
 %nan = fcmp uno half %sum,0xH0000
 %stable = select i1 %nan,i16 32256,i16 %raw
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %wide = zext i32 %kept to i64
 store i64 %wide,ptr %out,align 1
 %fp_out = getelementptr i8,ptr %out,i64 8
 store i16 %stable,ptr %fp_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 10
 store i64 %token,ptr %token_out,align 1
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @half_literal_live_probe_29(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %word = load i64,ptr %input,align 1
 %seed_pointer = getelementptr i8,ptr %input,i64 8
 %seed = load half,ptr %seed_pointer,align 1
 %salt32 = trunc i64 %salt to i32
 %word32 = trunc i64 %word to i32
 %kept = xor i32 %salt32,%word32
 %sum = fadd half %seed,0xH8000
 %raw = bitcast half %sum to i16
 %nan = fcmp uno half %sum,0xH0000
 %stable = select i1 %nan,i16 32256,i16 %raw
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %wide = zext i32 %kept to i64
 store i64 %wide,ptr %out,align 1
 %fp_out = getelementptr i8,ptr %out,i64 8
 store i16 %stable,ptr %fp_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 10
 store i64 %token,ptr %token_out,align 1
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @half_literal_live_probe_30(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %word = load i64,ptr %input,align 1
 %salt32 = trunc i64 %salt to i32
 %word32 = trunc i64 %word to i32
 %kept = xor i32 %salt32,%word32
 %sum = tail call half @llvm.vector.reduce.fadd.v4f16(half 0xH8000,<4 x half> <half 0xH8000,half 0xH0000,half 0xH0000,half 0xH0000>)
 %raw = bitcast half %sum to i16
 %nan = fcmp uno half %sum,0xH0000
 %stable = select i1 %nan,i16 32256,i16 %raw
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %wide = zext i32 %kept to i64
 store i64 %wide,ptr %out,align 1
 %fp_out = getelementptr i8,ptr %out,i64 8
 store i16 %stable,ptr %fp_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 10
 store i64 %token,ptr %token_out,align 1
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @half_literal_live_probe_31(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %word = load i64,ptr %input,align 1
 %seed_pointer = getelementptr i8,ptr %input,i64 8
 %seed = load half,ptr %seed_pointer,align 1
 %salt32 = trunc i64 %salt to i32
 %word32 = trunc i64 %word to i32
 %kept = xor i32 %salt32,%word32
 %sum = notail call half @llvm.vector.reduce.fadd.v4f16(half %seed,<4 x half> <half 0xH8000,half 0xH0000,half 0xH0000,half 0xH0000>)
 %raw = bitcast half %sum to i16
 %nan = fcmp uno half %sum,0xH0000
 %stable = select i1 %nan,i16 32256,i16 %raw
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %wide = zext i32 %kept to i64
 store i64 %wide,ptr %out,align 1
 %fp_out = getelementptr i8,ptr %out,i64 8
 store i16 %stable,ptr %fp_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 10
 store i64 %token,ptr %token_out,align 1
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @half_literal_live_probe_32(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %word = load i64,ptr %input,align 1
 %salt32 = trunc i64 %salt to i32
 %word32 = trunc i64 %word to i32
 %kept = xor i32 %salt32,%word32
 %sum = fadd half 0xH3E00,0xH4080
 %raw = bitcast half %sum to i16
 %nan = fcmp uno half %sum,0xH0000
 %stable = select i1 %nan,i16 32256,i16 %raw
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %wide = zext i32 %kept to i64
 store i64 %wide,ptr %out,align 1
 %fp_out = getelementptr i8,ptr %out,i64 8
 store i16 %stable,ptr %fp_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 10
 store i64 %token,ptr %token_out,align 1
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @half_literal_live_probe_33(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %word = load i64,ptr %input,align 1
 %seed_pointer = getelementptr i8,ptr %input,i64 8
 %seed = load half,ptr %seed_pointer,align 1
 %salt32 = trunc i64 %salt to i32
 %word32 = trunc i64 %word to i32
 %kept = xor i32 %salt32,%word32
 %sum = fadd half %seed,0xH4080
 %raw = bitcast half %sum to i16
 %nan = fcmp uno half %sum,0xH0000
 %stable = select i1 %nan,i16 32256,i16 %raw
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %wide = zext i32 %kept to i64
 store i64 %wide,ptr %out,align 1
 %fp_out = getelementptr i8,ptr %out,i64 8
 store i16 %stable,ptr %fp_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 10
 store i64 %token,ptr %token_out,align 1
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @half_literal_live_probe_34(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %word = load i64,ptr %input,align 1
 %salt32 = trunc i64 %salt to i32
 %word32 = trunc i64 %word to i32
 %kept = xor i32 %salt32,%word32
 %sum = tail call half @llvm.vector.reduce.fadd.v4f16(half 0xH3E00,<4 x half> <half 0xH4080,half 0xH0000,half 0xH0000,half 0xH0000>)
 %raw = bitcast half %sum to i16
 %nan = fcmp uno half %sum,0xH0000
 %stable = select i1 %nan,i16 32256,i16 %raw
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %wide = zext i32 %kept to i64
 store i64 %wide,ptr %out,align 1
 %fp_out = getelementptr i8,ptr %out,i64 8
 store i16 %stable,ptr %fp_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 10
 store i64 %token,ptr %token_out,align 1
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @half_literal_live_probe_35(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %word = load i64,ptr %input,align 1
 %seed_pointer = getelementptr i8,ptr %input,i64 8
 %seed = load half,ptr %seed_pointer,align 1
 %salt32 = trunc i64 %salt to i32
 %word32 = trunc i64 %word to i32
 %kept = xor i32 %salt32,%word32
 %sum = notail call half @llvm.vector.reduce.fadd.v4f16(half %seed,<4 x half> <half 0xH4080,half 0xH0000,half 0xH0000,half 0xH0000>)
 %raw = bitcast half %sum to i16
 %nan = fcmp uno half %sum,0xH0000
 %stable = select i1 %nan,i16 32256,i16 %raw
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %wide = zext i32 %kept to i64
 store i64 %wide,ptr %out,align 1
 %fp_out = getelementptr i8,ptr %out,i64 8
 store i16 %stable,ptr %fp_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 10
 store i64 %token,ptr %token_out,align 1
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @half_literal_live_probe_36(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %word = load i64,ptr %input,align 1
 %salt32 = trunc i64 %salt to i32
 %word32 = trunc i64 %word to i32
 %kept = xor i32 %salt32,%word32
 %sum = fadd half 0xHC000,0xH3800
 %raw = bitcast half %sum to i16
 %nan = fcmp uno half %sum,0xH0000
 %stable = select i1 %nan,i16 32256,i16 %raw
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %wide = zext i32 %kept to i64
 store i64 %wide,ptr %out,align 1
 %fp_out = getelementptr i8,ptr %out,i64 8
 store i16 %stable,ptr %fp_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 10
 store i64 %token,ptr %token_out,align 1
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @half_literal_live_probe_37(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %word = load i64,ptr %input,align 1
 %seed_pointer = getelementptr i8,ptr %input,i64 8
 %seed = load half,ptr %seed_pointer,align 1
 %salt32 = trunc i64 %salt to i32
 %word32 = trunc i64 %word to i32
 %kept = xor i32 %salt32,%word32
 %sum = fadd half %seed,0xH3800
 %raw = bitcast half %sum to i16
 %nan = fcmp uno half %sum,0xH0000
 %stable = select i1 %nan,i16 32256,i16 %raw
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %wide = zext i32 %kept to i64
 store i64 %wide,ptr %out,align 1
 %fp_out = getelementptr i8,ptr %out,i64 8
 store i16 %stable,ptr %fp_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 10
 store i64 %token,ptr %token_out,align 1
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @half_literal_live_probe_38(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %word = load i64,ptr %input,align 1
 %salt32 = trunc i64 %salt to i32
 %word32 = trunc i64 %word to i32
 %kept = xor i32 %salt32,%word32
 %sum = tail call half @llvm.vector.reduce.fadd.v4f16(half 0xHC000,<4 x half> <half 0xH3800,half 0xH0000,half 0xH0000,half 0xH0000>)
 %raw = bitcast half %sum to i16
 %nan = fcmp uno half %sum,0xH0000
 %stable = select i1 %nan,i16 32256,i16 %raw
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %wide = zext i32 %kept to i64
 store i64 %wide,ptr %out,align 1
 %fp_out = getelementptr i8,ptr %out,i64 8
 store i16 %stable,ptr %fp_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 10
 store i64 %token,ptr %token_out,align 1
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @half_literal_live_probe_39(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %word = load i64,ptr %input,align 1
 %seed_pointer = getelementptr i8,ptr %input,i64 8
 %seed = load half,ptr %seed_pointer,align 1
 %salt32 = trunc i64 %salt to i32
 %word32 = trunc i64 %word to i32
 %kept = xor i32 %salt32,%word32
 %sum = notail call half @llvm.vector.reduce.fadd.v4f16(half %seed,<4 x half> <half 0xH3800,half 0xH0000,half 0xH0000,half 0xH0000>)
 %raw = bitcast half %sum to i16
 %nan = fcmp uno half %sum,0xH0000
 %stable = select i1 %nan,i16 32256,i16 %raw
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %wide = zext i32 %kept to i64
 store i64 %wide,ptr %out,align 1
 %fp_out = getelementptr i8,ptr %out,i64 8
 store i16 %stable,ptr %fp_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 10
 store i64 %token,ptr %token_out,align 1
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @half_literal_live_probe_40(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %word = load i64,ptr %input,align 1
 %salt32 = trunc i64 %salt to i32
 %word32 = trunc i64 %word to i32
 %kept = xor i32 %salt32,%word32
 %sum = fadd half 0xH7C00,0xHFC00
 %raw = bitcast half %sum to i16
 %nan = fcmp uno half %sum,0xH0000
 %stable = select i1 %nan,i16 32256,i16 %raw
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %wide = zext i32 %kept to i64
 store i64 %wide,ptr %out,align 1
 %fp_out = getelementptr i8,ptr %out,i64 8
 store i16 %stable,ptr %fp_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 10
 store i64 %token,ptr %token_out,align 1
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @half_literal_live_probe_41(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %word = load i64,ptr %input,align 1
 %seed_pointer = getelementptr i8,ptr %input,i64 8
 %seed = load half,ptr %seed_pointer,align 1
 %salt32 = trunc i64 %salt to i32
 %word32 = trunc i64 %word to i32
 %kept = xor i32 %salt32,%word32
 %sum = fadd half %seed,0xHFC00
 %raw = bitcast half %sum to i16
 %nan = fcmp uno half %sum,0xH0000
 %stable = select i1 %nan,i16 32256,i16 %raw
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %wide = zext i32 %kept to i64
 store i64 %wide,ptr %out,align 1
 %fp_out = getelementptr i8,ptr %out,i64 8
 store i16 %stable,ptr %fp_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 10
 store i64 %token,ptr %token_out,align 1
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @half_literal_live_probe_42(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %word = load i64,ptr %input,align 1
 %salt32 = trunc i64 %salt to i32
 %word32 = trunc i64 %word to i32
 %kept = xor i32 %salt32,%word32
 %sum = tail call half @llvm.vector.reduce.fadd.v4f16(half 0xH7C00,<4 x half> <half 0xHFC00,half 0xH0000,half 0xH0000,half 0xH0000>)
 %raw = bitcast half %sum to i16
 %nan = fcmp uno half %sum,0xH0000
 %stable = select i1 %nan,i16 32256,i16 %raw
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %wide = zext i32 %kept to i64
 store i64 %wide,ptr %out,align 1
 %fp_out = getelementptr i8,ptr %out,i64 8
 store i16 %stable,ptr %fp_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 10
 store i64 %token,ptr %token_out,align 1
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @half_literal_live_probe_43(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %word = load i64,ptr %input,align 1
 %seed_pointer = getelementptr i8,ptr %input,i64 8
 %seed = load half,ptr %seed_pointer,align 1
 %salt32 = trunc i64 %salt to i32
 %word32 = trunc i64 %word to i32
 %kept = xor i32 %salt32,%word32
 %sum = notail call half @llvm.vector.reduce.fadd.v4f16(half %seed,<4 x half> <half 0xHFC00,half 0xH0000,half 0xH0000,half 0xH0000>)
 %raw = bitcast half %sum to i16
 %nan = fcmp uno half %sum,0xH0000
 %stable = select i1 %nan,i16 32256,i16 %raw
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %wide = zext i32 %kept to i64
 store i64 %wide,ptr %out,align 1
 %fp_out = getelementptr i8,ptr %out,i64 8
 store i16 %stable,ptr %fp_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 10
 store i64 %token,ptr %token_out,align 1
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @half_literal_live_probe_44(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %word = load i64,ptr %input,align 1
 %salt32 = trunc i64 %salt to i32
 %word32 = trunc i64 %word to i32
 %kept = xor i32 %salt32,%word32
 %sum = fadd half 0xH7E00,0xH3C00
 %raw = bitcast half %sum to i16
 %nan = fcmp uno half %sum,0xH0000
 %stable = select i1 %nan,i16 32256,i16 %raw
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %wide = zext i32 %kept to i64
 store i64 %wide,ptr %out,align 1
 %fp_out = getelementptr i8,ptr %out,i64 8
 store i16 %stable,ptr %fp_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 10
 store i64 %token,ptr %token_out,align 1
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @half_literal_live_probe_45(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %word = load i64,ptr %input,align 1
 %seed_pointer = getelementptr i8,ptr %input,i64 8
 %seed = load half,ptr %seed_pointer,align 1
 %salt32 = trunc i64 %salt to i32
 %word32 = trunc i64 %word to i32
 %kept = xor i32 %salt32,%word32
 %sum = fadd half %seed,0xH3C00
 %raw = bitcast half %sum to i16
 %nan = fcmp uno half %sum,0xH0000
 %stable = select i1 %nan,i16 32256,i16 %raw
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %wide = zext i32 %kept to i64
 store i64 %wide,ptr %out,align 1
 %fp_out = getelementptr i8,ptr %out,i64 8
 store i16 %stable,ptr %fp_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 10
 store i64 %token,ptr %token_out,align 1
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @half_literal_live_probe_46(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %word = load i64,ptr %input,align 1
 %salt32 = trunc i64 %salt to i32
 %word32 = trunc i64 %word to i32
 %kept = xor i32 %salt32,%word32
 %sum = tail call half @llvm.vector.reduce.fadd.v4f16(half 0xH7E00,<4 x half> <half 0xH3C00,half 0xH0000,half 0xH0000,half 0xH0000>)
 %raw = bitcast half %sum to i16
 %nan = fcmp uno half %sum,0xH0000
 %stable = select i1 %nan,i16 32256,i16 %raw
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %wide = zext i32 %kept to i64
 store i64 %wide,ptr %out,align 1
 %fp_out = getelementptr i8,ptr %out,i64 8
 store i16 %stable,ptr %fp_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 10
 store i64 %token,ptr %token_out,align 1
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @half_literal_live_probe_47(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %word = load i64,ptr %input,align 1
 %seed_pointer = getelementptr i8,ptr %input,i64 8
 %seed = load half,ptr %seed_pointer,align 1
 %salt32 = trunc i64 %salt to i32
 %word32 = trunc i64 %word to i32
 %kept = xor i32 %salt32,%word32
 %sum = notail call half @llvm.vector.reduce.fadd.v4f16(half %seed,<4 x half> <half 0xH3C00,half 0xH0000,half 0xH0000,half 0xH0000>)
 %raw = bitcast half %sum to i16
 %nan = fcmp uno half %sum,0xH0000
 %stable = select i1 %nan,i16 32256,i16 %raw
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %wide = zext i32 %kept to i64
 store i64 %wide,ptr %out,align 1
 %fp_out = getelementptr i8,ptr %out,i64 8
 store i16 %stable,ptr %fp_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 10
 store i64 %token,ptr %token_out,align 1
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @half_literal_live_probe_48(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %word = load i64,ptr %input,align 1
 %kept = xor i64 %salt,%word
 %sum = fadd half 0xH0000,0xH3C00
 %raw = bitcast half %sum to i16
 %nan = fcmp uno half %sum,0xH0000
 %stable = select i1 %nan,i16 32256,i16 %raw
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %kept,ptr %out,align 1
 %fp_out = getelementptr i8,ptr %out,i64 8
 store i16 %stable,ptr %fp_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 10
 store i64 %token,ptr %token_out,align 1
 %answer = xor i64 %kept,%token
 ret i64 %answer
}
define i64 @half_literal_live_probe_49(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %word = load i64,ptr %input,align 1
 %seed_pointer = getelementptr i8,ptr %input,i64 8
 %seed = load half,ptr %seed_pointer,align 1
 %kept = xor i64 %salt,%word
 %sum = fadd half %seed,0xH3C00
 %raw = bitcast half %sum to i16
 %nan = fcmp uno half %sum,0xH0000
 %stable = select i1 %nan,i16 32256,i16 %raw
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %kept,ptr %out,align 1
 %fp_out = getelementptr i8,ptr %out,i64 8
 store i16 %stable,ptr %fp_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 10
 store i64 %token,ptr %token_out,align 1
 %answer = xor i64 %kept,%token
 ret i64 %answer
}
define i64 @half_literal_live_probe_50(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %word = load i64,ptr %input,align 1
 %kept = xor i64 %salt,%word
 %sum = tail call half @llvm.vector.reduce.fadd.v4f16(half 0xH0000,<4 x half> <half 0xH3C00,half 0xH0000,half 0xH0000,half 0xH0000>)
 %raw = bitcast half %sum to i16
 %nan = fcmp uno half %sum,0xH0000
 %stable = select i1 %nan,i16 32256,i16 %raw
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %kept,ptr %out,align 1
 %fp_out = getelementptr i8,ptr %out,i64 8
 store i16 %stable,ptr %fp_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 10
 store i64 %token,ptr %token_out,align 1
 %answer = xor i64 %kept,%token
 ret i64 %answer
}
define i64 @half_literal_live_probe_51(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %word = load i64,ptr %input,align 1
 %seed_pointer = getelementptr i8,ptr %input,i64 8
 %seed = load half,ptr %seed_pointer,align 1
 %kept = xor i64 %salt,%word
 %sum = notail call half @llvm.vector.reduce.fadd.v4f16(half %seed,<4 x half> <half 0xH3C00,half 0xH0000,half 0xH0000,half 0xH0000>)
 %raw = bitcast half %sum to i16
 %nan = fcmp uno half %sum,0xH0000
 %stable = select i1 %nan,i16 32256,i16 %raw
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %kept,ptr %out,align 1
 %fp_out = getelementptr i8,ptr %out,i64 8
 store i16 %stable,ptr %fp_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 10
 store i64 %token,ptr %token_out,align 1
 %answer = xor i64 %kept,%token
 ret i64 %answer
}
define i64 @half_literal_live_probe_52(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %word = load i64,ptr %input,align 1
 %kept = xor i64 %salt,%word
 %sum = fadd half 0xH8000,0xH8000
 %raw = bitcast half %sum to i16
 %nan = fcmp uno half %sum,0xH0000
 %stable = select i1 %nan,i16 32256,i16 %raw
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %kept,ptr %out,align 1
 %fp_out = getelementptr i8,ptr %out,i64 8
 store i16 %stable,ptr %fp_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 10
 store i64 %token,ptr %token_out,align 1
 %answer = xor i64 %kept,%token
 ret i64 %answer
}
define i64 @half_literal_live_probe_53(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %word = load i64,ptr %input,align 1
 %seed_pointer = getelementptr i8,ptr %input,i64 8
 %seed = load half,ptr %seed_pointer,align 1
 %kept = xor i64 %salt,%word
 %sum = fadd half %seed,0xH8000
 %raw = bitcast half %sum to i16
 %nan = fcmp uno half %sum,0xH0000
 %stable = select i1 %nan,i16 32256,i16 %raw
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %kept,ptr %out,align 1
 %fp_out = getelementptr i8,ptr %out,i64 8
 store i16 %stable,ptr %fp_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 10
 store i64 %token,ptr %token_out,align 1
 %answer = xor i64 %kept,%token
 ret i64 %answer
}
define i64 @half_literal_live_probe_54(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %word = load i64,ptr %input,align 1
 %kept = xor i64 %salt,%word
 %sum = tail call half @llvm.vector.reduce.fadd.v4f16(half 0xH8000,<4 x half> <half 0xH8000,half 0xH0000,half 0xH0000,half 0xH0000>)
 %raw = bitcast half %sum to i16
 %nan = fcmp uno half %sum,0xH0000
 %stable = select i1 %nan,i16 32256,i16 %raw
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %kept,ptr %out,align 1
 %fp_out = getelementptr i8,ptr %out,i64 8
 store i16 %stable,ptr %fp_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 10
 store i64 %token,ptr %token_out,align 1
 %answer = xor i64 %kept,%token
 ret i64 %answer
}
define i64 @half_literal_live_probe_55(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %word = load i64,ptr %input,align 1
 %seed_pointer = getelementptr i8,ptr %input,i64 8
 %seed = load half,ptr %seed_pointer,align 1
 %kept = xor i64 %salt,%word
 %sum = notail call half @llvm.vector.reduce.fadd.v4f16(half %seed,<4 x half> <half 0xH8000,half 0xH0000,half 0xH0000,half 0xH0000>)
 %raw = bitcast half %sum to i16
 %nan = fcmp uno half %sum,0xH0000
 %stable = select i1 %nan,i16 32256,i16 %raw
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %kept,ptr %out,align 1
 %fp_out = getelementptr i8,ptr %out,i64 8
 store i16 %stable,ptr %fp_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 10
 store i64 %token,ptr %token_out,align 1
 %answer = xor i64 %kept,%token
 ret i64 %answer
}
define i64 @half_literal_live_probe_56(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %word = load i64,ptr %input,align 1
 %kept = xor i64 %salt,%word
 %sum = fadd half 0xH3E00,0xH4080
 %raw = bitcast half %sum to i16
 %nan = fcmp uno half %sum,0xH0000
 %stable = select i1 %nan,i16 32256,i16 %raw
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %kept,ptr %out,align 1
 %fp_out = getelementptr i8,ptr %out,i64 8
 store i16 %stable,ptr %fp_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 10
 store i64 %token,ptr %token_out,align 1
 %answer = xor i64 %kept,%token
 ret i64 %answer
}
define i64 @half_literal_live_probe_57(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %word = load i64,ptr %input,align 1
 %seed_pointer = getelementptr i8,ptr %input,i64 8
 %seed = load half,ptr %seed_pointer,align 1
 %kept = xor i64 %salt,%word
 %sum = fadd half %seed,0xH4080
 %raw = bitcast half %sum to i16
 %nan = fcmp uno half %sum,0xH0000
 %stable = select i1 %nan,i16 32256,i16 %raw
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %kept,ptr %out,align 1
 %fp_out = getelementptr i8,ptr %out,i64 8
 store i16 %stable,ptr %fp_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 10
 store i64 %token,ptr %token_out,align 1
 %answer = xor i64 %kept,%token
 ret i64 %answer
}
define i64 @half_literal_live_probe_58(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %word = load i64,ptr %input,align 1
 %kept = xor i64 %salt,%word
 %sum = tail call half @llvm.vector.reduce.fadd.v4f16(half 0xH3E00,<4 x half> <half 0xH4080,half 0xH0000,half 0xH0000,half 0xH0000>)
 %raw = bitcast half %sum to i16
 %nan = fcmp uno half %sum,0xH0000
 %stable = select i1 %nan,i16 32256,i16 %raw
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %kept,ptr %out,align 1
 %fp_out = getelementptr i8,ptr %out,i64 8
 store i16 %stable,ptr %fp_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 10
 store i64 %token,ptr %token_out,align 1
 %answer = xor i64 %kept,%token
 ret i64 %answer
}
define i64 @half_literal_live_probe_59(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %word = load i64,ptr %input,align 1
 %seed_pointer = getelementptr i8,ptr %input,i64 8
 %seed = load half,ptr %seed_pointer,align 1
 %kept = xor i64 %salt,%word
 %sum = notail call half @llvm.vector.reduce.fadd.v4f16(half %seed,<4 x half> <half 0xH4080,half 0xH0000,half 0xH0000,half 0xH0000>)
 %raw = bitcast half %sum to i16
 %nan = fcmp uno half %sum,0xH0000
 %stable = select i1 %nan,i16 32256,i16 %raw
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %kept,ptr %out,align 1
 %fp_out = getelementptr i8,ptr %out,i64 8
 store i16 %stable,ptr %fp_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 10
 store i64 %token,ptr %token_out,align 1
 %answer = xor i64 %kept,%token
 ret i64 %answer
}
define i64 @half_literal_live_probe_60(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %word = load i64,ptr %input,align 1
 %kept = xor i64 %salt,%word
 %sum = fadd half 0xHC000,0xH3800
 %raw = bitcast half %sum to i16
 %nan = fcmp uno half %sum,0xH0000
 %stable = select i1 %nan,i16 32256,i16 %raw
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %kept,ptr %out,align 1
 %fp_out = getelementptr i8,ptr %out,i64 8
 store i16 %stable,ptr %fp_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 10
 store i64 %token,ptr %token_out,align 1
 %answer = xor i64 %kept,%token
 ret i64 %answer
}
define i64 @half_literal_live_probe_61(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %word = load i64,ptr %input,align 1
 %seed_pointer = getelementptr i8,ptr %input,i64 8
 %seed = load half,ptr %seed_pointer,align 1
 %kept = xor i64 %salt,%word
 %sum = fadd half %seed,0xH3800
 %raw = bitcast half %sum to i16
 %nan = fcmp uno half %sum,0xH0000
 %stable = select i1 %nan,i16 32256,i16 %raw
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %kept,ptr %out,align 1
 %fp_out = getelementptr i8,ptr %out,i64 8
 store i16 %stable,ptr %fp_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 10
 store i64 %token,ptr %token_out,align 1
 %answer = xor i64 %kept,%token
 ret i64 %answer
}
define i64 @half_literal_live_probe_62(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %word = load i64,ptr %input,align 1
 %kept = xor i64 %salt,%word
 %sum = tail call half @llvm.vector.reduce.fadd.v4f16(half 0xHC000,<4 x half> <half 0xH3800,half 0xH0000,half 0xH0000,half 0xH0000>)
 %raw = bitcast half %sum to i16
 %nan = fcmp uno half %sum,0xH0000
 %stable = select i1 %nan,i16 32256,i16 %raw
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %kept,ptr %out,align 1
 %fp_out = getelementptr i8,ptr %out,i64 8
 store i16 %stable,ptr %fp_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 10
 store i64 %token,ptr %token_out,align 1
 %answer = xor i64 %kept,%token
 ret i64 %answer
}
define i64 @half_literal_live_probe_63(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %word = load i64,ptr %input,align 1
 %seed_pointer = getelementptr i8,ptr %input,i64 8
 %seed = load half,ptr %seed_pointer,align 1
 %kept = xor i64 %salt,%word
 %sum = notail call half @llvm.vector.reduce.fadd.v4f16(half %seed,<4 x half> <half 0xH3800,half 0xH0000,half 0xH0000,half 0xH0000>)
 %raw = bitcast half %sum to i16
 %nan = fcmp uno half %sum,0xH0000
 %stable = select i1 %nan,i16 32256,i16 %raw
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %kept,ptr %out,align 1
 %fp_out = getelementptr i8,ptr %out,i64 8
 store i16 %stable,ptr %fp_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 10
 store i64 %token,ptr %token_out,align 1
 %answer = xor i64 %kept,%token
 ret i64 %answer
}
define i64 @half_literal_live_probe_64(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %word = load i64,ptr %input,align 1
 %kept = xor i64 %salt,%word
 %sum = fadd half 0xH7C00,0xHFC00
 %raw = bitcast half %sum to i16
 %nan = fcmp uno half %sum,0xH0000
 %stable = select i1 %nan,i16 32256,i16 %raw
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %kept,ptr %out,align 1
 %fp_out = getelementptr i8,ptr %out,i64 8
 store i16 %stable,ptr %fp_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 10
 store i64 %token,ptr %token_out,align 1
 %answer = xor i64 %kept,%token
 ret i64 %answer
}
define i64 @half_literal_live_probe_65(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %word = load i64,ptr %input,align 1
 %seed_pointer = getelementptr i8,ptr %input,i64 8
 %seed = load half,ptr %seed_pointer,align 1
 %kept = xor i64 %salt,%word
 %sum = fadd half %seed,0xHFC00
 %raw = bitcast half %sum to i16
 %nan = fcmp uno half %sum,0xH0000
 %stable = select i1 %nan,i16 32256,i16 %raw
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %kept,ptr %out,align 1
 %fp_out = getelementptr i8,ptr %out,i64 8
 store i16 %stable,ptr %fp_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 10
 store i64 %token,ptr %token_out,align 1
 %answer = xor i64 %kept,%token
 ret i64 %answer
}
define i64 @half_literal_live_probe_66(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %word = load i64,ptr %input,align 1
 %kept = xor i64 %salt,%word
 %sum = tail call half @llvm.vector.reduce.fadd.v4f16(half 0xH7C00,<4 x half> <half 0xHFC00,half 0xH0000,half 0xH0000,half 0xH0000>)
 %raw = bitcast half %sum to i16
 %nan = fcmp uno half %sum,0xH0000
 %stable = select i1 %nan,i16 32256,i16 %raw
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %kept,ptr %out,align 1
 %fp_out = getelementptr i8,ptr %out,i64 8
 store i16 %stable,ptr %fp_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 10
 store i64 %token,ptr %token_out,align 1
 %answer = xor i64 %kept,%token
 ret i64 %answer
}
define i64 @half_literal_live_probe_67(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %word = load i64,ptr %input,align 1
 %seed_pointer = getelementptr i8,ptr %input,i64 8
 %seed = load half,ptr %seed_pointer,align 1
 %kept = xor i64 %salt,%word
 %sum = notail call half @llvm.vector.reduce.fadd.v4f16(half %seed,<4 x half> <half 0xHFC00,half 0xH0000,half 0xH0000,half 0xH0000>)
 %raw = bitcast half %sum to i16
 %nan = fcmp uno half %sum,0xH0000
 %stable = select i1 %nan,i16 32256,i16 %raw
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %kept,ptr %out,align 1
 %fp_out = getelementptr i8,ptr %out,i64 8
 store i16 %stable,ptr %fp_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 10
 store i64 %token,ptr %token_out,align 1
 %answer = xor i64 %kept,%token
 ret i64 %answer
}
define i64 @half_literal_live_probe_68(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %word = load i64,ptr %input,align 1
 %kept = xor i64 %salt,%word
 %sum = fadd half 0xH7E00,0xH3C00
 %raw = bitcast half %sum to i16
 %nan = fcmp uno half %sum,0xH0000
 %stable = select i1 %nan,i16 32256,i16 %raw
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %kept,ptr %out,align 1
 %fp_out = getelementptr i8,ptr %out,i64 8
 store i16 %stable,ptr %fp_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 10
 store i64 %token,ptr %token_out,align 1
 %answer = xor i64 %kept,%token
 ret i64 %answer
}
define i64 @half_literal_live_probe_69(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %word = load i64,ptr %input,align 1
 %seed_pointer = getelementptr i8,ptr %input,i64 8
 %seed = load half,ptr %seed_pointer,align 1
 %kept = xor i64 %salt,%word
 %sum = fadd half %seed,0xH3C00
 %raw = bitcast half %sum to i16
 %nan = fcmp uno half %sum,0xH0000
 %stable = select i1 %nan,i16 32256,i16 %raw
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %kept,ptr %out,align 1
 %fp_out = getelementptr i8,ptr %out,i64 8
 store i16 %stable,ptr %fp_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 10
 store i64 %token,ptr %token_out,align 1
 %answer = xor i64 %kept,%token
 ret i64 %answer
}
define i64 @half_literal_live_probe_70(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %word = load i64,ptr %input,align 1
 %kept = xor i64 %salt,%word
 %sum = tail call half @llvm.vector.reduce.fadd.v4f16(half 0xH7E00,<4 x half> <half 0xH3C00,half 0xH0000,half 0xH0000,half 0xH0000>)
 %raw = bitcast half %sum to i16
 %nan = fcmp uno half %sum,0xH0000
 %stable = select i1 %nan,i16 32256,i16 %raw
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %kept,ptr %out,align 1
 %fp_out = getelementptr i8,ptr %out,i64 8
 store i16 %stable,ptr %fp_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 10
 store i64 %token,ptr %token_out,align 1
 %answer = xor i64 %kept,%token
 ret i64 %answer
}
define i64 @half_literal_live_probe_71(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %word = load i64,ptr %input,align 1
 %seed_pointer = getelementptr i8,ptr %input,i64 8
 %seed = load half,ptr %seed_pointer,align 1
 %kept = xor i64 %salt,%word
 %sum = notail call half @llvm.vector.reduce.fadd.v4f16(half %seed,<4 x half> <half 0xH3C00,half 0xH0000,half 0xH0000,half 0xH0000>)
 %raw = bitcast half %sum to i16
 %nan = fcmp uno half %sum,0xH0000
 %stable = select i1 %nan,i16 32256,i16 %raw
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %kept,ptr %out,align 1
 %fp_out = getelementptr i8,ptr %out,i64 8
 store i16 %stable,ptr %fp_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 10
 store i64 %token,ptr %token_out,align 1
 %answer = xor i64 %kept,%token
 ret i64 %answer
}
