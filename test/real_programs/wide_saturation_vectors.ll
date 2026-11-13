target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"
declare i64 @complete_clobber(i64,i64,i64,i64,i64,i64,i64,i64)
declare i140 @llvm.ushl.sat.i140(i140,i140)
declare i140 @llvm.sshl.sat.i140(i140,i140)
declare i200 @llvm.ushl.sat.i200(i200,i200)
declare i200 @llvm.sshl.sat.i200(i200,i200)
define internal void @wide_sat_140_u_0(ptr %out,ptr %input,i64 %shift) noinline {
entry:
 %a = load i140,ptr %input,align 1
 %s = zext i64 %shift to i140
 %r = call i140 @llvm.ushl.sat.i140(i140 %a,i140 %s)
 %word0 = trunc i140 %r to i64
 %out0 = getelementptr i8,ptr %out,i64 0
 store i64 %word0,ptr %out0,align 1
 %shift1 = lshr i140 %r,64
 %word1 = trunc i140 %shift1 to i64
 %out1 = getelementptr i8,ptr %out,i64 8
 store i64 %word1,ptr %out1,align 1
 %shift2 = lshr i140 %r,128
 %word2 = trunc i140 %shift2 to i64
 %out2 = getelementptr i8,ptr %out,i64 16
 store i64 %word2,ptr %out2,align 1
 ret void
}
define internal void @wide_sat_140_u_1(ptr %out,ptr %input,i64 %shift) noinline {
entry:
 %a = load i140,ptr %input,align 1
 %s = zext i64 %shift to i140
 %r = tail call i140 @llvm.ushl.sat.i140(i140 %a,i140 %s)
 %word0 = trunc i140 %r to i64
 %out0 = getelementptr i8,ptr %out,i64 0
 store i64 %word0,ptr %out0,align 1
 %shift1 = lshr i140 %r,64
 %word1 = trunc i140 %shift1 to i64
 %out1 = getelementptr i8,ptr %out,i64 8
 store i64 %word1,ptr %out1,align 1
 %shift2 = lshr i140 %r,128
 %word2 = trunc i140 %shift2 to i64
 %out2 = getelementptr i8,ptr %out,i64 16
 store i64 %word2,ptr %out2,align 1
 ret void
}
define internal void @wide_sat_140_u_2(ptr %out,ptr %input,i64 %shift) noinline {
entry:
 %a = load i140,ptr %input,align 1
 %s = zext i64 %shift to i140
 %r = notail call i140 @llvm.ushl.sat.i140(i140 %a,i140 %s)
 %word0 = trunc i140 %r to i64
 %out0 = getelementptr i8,ptr %out,i64 0
 store i64 %word0,ptr %out0,align 1
 %shift1 = lshr i140 %r,64
 %word1 = trunc i140 %shift1 to i64
 %out1 = getelementptr i8,ptr %out,i64 8
 store i64 %word1,ptr %out1,align 1
 %shift2 = lshr i140 %r,128
 %word2 = trunc i140 %shift2 to i64
 %out2 = getelementptr i8,ptr %out,i64 16
 store i64 %word2,ptr %out2,align 1
 ret void
}
define internal void @wide_sat_140_s_0(ptr %out,ptr %input,i64 %shift) noinline {
entry:
 %a = load i140,ptr %input,align 1
 %s = zext i64 %shift to i140
 %r = call i140 @llvm.sshl.sat.i140(i140 %a,i140 %s)
 %word0 = trunc i140 %r to i64
 %out0 = getelementptr i8,ptr %out,i64 0
 store i64 %word0,ptr %out0,align 1
 %shift1 = lshr i140 %r,64
 %word1 = trunc i140 %shift1 to i64
 %out1 = getelementptr i8,ptr %out,i64 8
 store i64 %word1,ptr %out1,align 1
 %shift2 = lshr i140 %r,128
 %word2 = trunc i140 %shift2 to i64
 %out2 = getelementptr i8,ptr %out,i64 16
 store i64 %word2,ptr %out2,align 1
 ret void
}
define internal void @wide_sat_140_s_1(ptr %out,ptr %input,i64 %shift) noinline {
entry:
 %a = load i140,ptr %input,align 1
 %s = zext i64 %shift to i140
 %r = tail call i140 @llvm.sshl.sat.i140(i140 %a,i140 %s)
 %word0 = trunc i140 %r to i64
 %out0 = getelementptr i8,ptr %out,i64 0
 store i64 %word0,ptr %out0,align 1
 %shift1 = lshr i140 %r,64
 %word1 = trunc i140 %shift1 to i64
 %out1 = getelementptr i8,ptr %out,i64 8
 store i64 %word1,ptr %out1,align 1
 %shift2 = lshr i140 %r,128
 %word2 = trunc i140 %shift2 to i64
 %out2 = getelementptr i8,ptr %out,i64 16
 store i64 %word2,ptr %out2,align 1
 ret void
}
define internal void @wide_sat_140_s_2(ptr %out,ptr %input,i64 %shift) noinline {
entry:
 %a = load i140,ptr %input,align 1
 %s = zext i64 %shift to i140
 %r = notail call i140 @llvm.sshl.sat.i140(i140 %a,i140 %s)
 %word0 = trunc i140 %r to i64
 %out0 = getelementptr i8,ptr %out,i64 0
 store i64 %word0,ptr %out0,align 1
 %shift1 = lshr i140 %r,64
 %word1 = trunc i140 %shift1 to i64
 %out1 = getelementptr i8,ptr %out,i64 8
 store i64 %word1,ptr %out1,align 1
 %shift2 = lshr i140 %r,128
 %word2 = trunc i140 %shift2 to i64
 %out2 = getelementptr i8,ptr %out,i64 16
 store i64 %word2,ptr %out2,align 1
 ret void
}
define internal void @wide_sat_200_u_0(ptr %out,ptr %input,i64 %shift) noinline {
entry:
 %a = load i200,ptr %input,align 1
 %s = zext i64 %shift to i200
 %r = call i200 @llvm.ushl.sat.i200(i200 %a,i200 %s)
 %word0 = trunc i200 %r to i64
 %out0 = getelementptr i8,ptr %out,i64 0
 store i64 %word0,ptr %out0,align 1
 %shift1 = lshr i200 %r,64
 %word1 = trunc i200 %shift1 to i64
 %out1 = getelementptr i8,ptr %out,i64 8
 store i64 %word1,ptr %out1,align 1
 %shift2 = lshr i200 %r,128
 %word2 = trunc i200 %shift2 to i64
 %out2 = getelementptr i8,ptr %out,i64 16
 store i64 %word2,ptr %out2,align 1
 %shift3 = lshr i200 %r,192
 %word3 = trunc i200 %shift3 to i64
 %out3 = getelementptr i8,ptr %out,i64 24
 store i64 %word3,ptr %out3,align 1
 ret void
}
define internal void @wide_sat_200_u_1(ptr %out,ptr %input,i64 %shift) noinline {
entry:
 %a = load i200,ptr %input,align 1
 %s = zext i64 %shift to i200
 %r = tail call i200 @llvm.ushl.sat.i200(i200 %a,i200 %s)
 %word0 = trunc i200 %r to i64
 %out0 = getelementptr i8,ptr %out,i64 0
 store i64 %word0,ptr %out0,align 1
 %shift1 = lshr i200 %r,64
 %word1 = trunc i200 %shift1 to i64
 %out1 = getelementptr i8,ptr %out,i64 8
 store i64 %word1,ptr %out1,align 1
 %shift2 = lshr i200 %r,128
 %word2 = trunc i200 %shift2 to i64
 %out2 = getelementptr i8,ptr %out,i64 16
 store i64 %word2,ptr %out2,align 1
 %shift3 = lshr i200 %r,192
 %word3 = trunc i200 %shift3 to i64
 %out3 = getelementptr i8,ptr %out,i64 24
 store i64 %word3,ptr %out3,align 1
 ret void
}
define internal void @wide_sat_200_u_2(ptr %out,ptr %input,i64 %shift) noinline {
entry:
 %a = load i200,ptr %input,align 1
 %s = zext i64 %shift to i200
 %r = notail call i200 @llvm.ushl.sat.i200(i200 %a,i200 %s)
 %word0 = trunc i200 %r to i64
 %out0 = getelementptr i8,ptr %out,i64 0
 store i64 %word0,ptr %out0,align 1
 %shift1 = lshr i200 %r,64
 %word1 = trunc i200 %shift1 to i64
 %out1 = getelementptr i8,ptr %out,i64 8
 store i64 %word1,ptr %out1,align 1
 %shift2 = lshr i200 %r,128
 %word2 = trunc i200 %shift2 to i64
 %out2 = getelementptr i8,ptr %out,i64 16
 store i64 %word2,ptr %out2,align 1
 %shift3 = lshr i200 %r,192
 %word3 = trunc i200 %shift3 to i64
 %out3 = getelementptr i8,ptr %out,i64 24
 store i64 %word3,ptr %out3,align 1
 ret void
}
define internal void @wide_sat_200_s_0(ptr %out,ptr %input,i64 %shift) noinline {
entry:
 %a = load i200,ptr %input,align 1
 %s = zext i64 %shift to i200
 %r = call i200 @llvm.sshl.sat.i200(i200 %a,i200 %s)
 %word0 = trunc i200 %r to i64
 %out0 = getelementptr i8,ptr %out,i64 0
 store i64 %word0,ptr %out0,align 1
 %shift1 = lshr i200 %r,64
 %word1 = trunc i200 %shift1 to i64
 %out1 = getelementptr i8,ptr %out,i64 8
 store i64 %word1,ptr %out1,align 1
 %shift2 = lshr i200 %r,128
 %word2 = trunc i200 %shift2 to i64
 %out2 = getelementptr i8,ptr %out,i64 16
 store i64 %word2,ptr %out2,align 1
 %shift3 = lshr i200 %r,192
 %word3 = trunc i200 %shift3 to i64
 %out3 = getelementptr i8,ptr %out,i64 24
 store i64 %word3,ptr %out3,align 1
 ret void
}
define internal void @wide_sat_200_s_1(ptr %out,ptr %input,i64 %shift) noinline {
entry:
 %a = load i200,ptr %input,align 1
 %s = zext i64 %shift to i200
 %r = tail call i200 @llvm.sshl.sat.i200(i200 %a,i200 %s)
 %word0 = trunc i200 %r to i64
 %out0 = getelementptr i8,ptr %out,i64 0
 store i64 %word0,ptr %out0,align 1
 %shift1 = lshr i200 %r,64
 %word1 = trunc i200 %shift1 to i64
 %out1 = getelementptr i8,ptr %out,i64 8
 store i64 %word1,ptr %out1,align 1
 %shift2 = lshr i200 %r,128
 %word2 = trunc i200 %shift2 to i64
 %out2 = getelementptr i8,ptr %out,i64 16
 store i64 %word2,ptr %out2,align 1
 %shift3 = lshr i200 %r,192
 %word3 = trunc i200 %shift3 to i64
 %out3 = getelementptr i8,ptr %out,i64 24
 store i64 %word3,ptr %out3,align 1
 ret void
}
define internal void @wide_sat_200_s_2(ptr %out,ptr %input,i64 %shift) noinline {
entry:
 %a = load i200,ptr %input,align 1
 %s = zext i64 %shift to i200
 %r = notail call i200 @llvm.sshl.sat.i200(i200 %a,i200 %s)
 %word0 = trunc i200 %r to i64
 %out0 = getelementptr i8,ptr %out,i64 0
 store i64 %word0,ptr %out0,align 1
 %shift1 = lshr i200 %r,64
 %word1 = trunc i200 %shift1 to i64
 %out1 = getelementptr i8,ptr %out,i64 8
 store i64 %word1,ptr %out1,align 1
 %shift2 = lshr i200 %r,128
 %word2 = trunc i200 %shift2 to i64
 %out2 = getelementptr i8,ptr %out,i64 16
 store i64 %word2,ptr %out2,align 1
 %shift3 = lshr i200 %r,192
 %word3 = trunc i200 %shift3 to i64
 %out3 = getelementptr i8,ptr %out,i64 24
 store i64 %word3,ptr %out3,align 1
 ret void
}
define i64 @wide_saturation_vector_probe_0(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %temporary = alloca [160 x i8],align 16
 %constant = alloca i140,align 16
 store i140 1267650600228229401496703205376,ptr %constant,align 16
 %bp = getelementptr i8,ptr %input,i64 32
 %sp = getelementptr i8,ptr %input,i64 64
 %s0 = load i64,ptr %sp,align 1
 %tp = getelementptr i8,ptr %input,i64 72
 %t0 = load i64,ptr %tp,align 1
 %temporary0 = getelementptr i8,ptr %temporary,i64 0
 call void @wide_sat_140_u_0(ptr %temporary0,ptr %input,i64 %s0)
 %temporary1 = getelementptr i8,ptr %temporary,i64 24
 call void @wide_sat_140_s_0(ptr %temporary1,ptr %input,i64 %s0)
 %temporary2 = getelementptr i8,ptr %temporary,i64 48
 call void @wide_sat_140_u_0(ptr %temporary2,ptr %constant,i64 %s0)
 %temporary3 = getelementptr i8,ptr %temporary,i64 72
 call void @wide_sat_140_s_0(ptr %temporary3,ptr %constant,i64 %s0)
 %temporary4 = getelementptr i8,ptr %temporary,i64 96
 call void @wide_sat_200_u_0(ptr %temporary4,ptr %bp,i64 %t0)
 %temporary5 = getelementptr i8,ptr %temporary,i64 128
 call void @wide_sat_200_s_0(ptr %temporary5,ptr %bp,i64 %t0)
 %r0 = load i140,ptr %temporary0,align 1
 %r1 = load i140,ptr %temporary1,align 1
 %r2 = load i140,ptr %temporary2,align 1
 %r3 = load i140,ptr %temporary3,align 1
 %r4 = load i200,ptr %temporary4,align 1
 %r5 = load i200,ptr %temporary5,align 1
 %v0 = insertelement <4 x i140> poison,i140 %r0,i64 0
 %v1 = insertelement <4 x i140> %v0,i140 %r1,i64 1
 %v2 = insertelement <4 x i140> %v1,i140 %r2,i64 2
 %v3 = insertelement <4 x i140> %v2,i140 %r3,i64 3
 %cmp = icmp eq <4 x i140> %v3,<i140 0,i140 -1,i140 696898287454081973172991196020261297061887,i140 -696898287454081973172991196020261297061888>
 %packed_mask = bitcast <4 x i1> %cmp to i4
 %mask = zext i4 %packed_mask to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %word0_0 = trunc i140 %r0 to i64
 %out0_0 = getelementptr i8,ptr %out,i64 0
 store i64 %word0_0,ptr %out0_0,align 1
 %shift0_1 = lshr i140 %r0,64
 %word0_1 = trunc i140 %shift0_1 to i64
 %out0_1 = getelementptr i8,ptr %out,i64 8
 store i64 %word0_1,ptr %out0_1,align 1
 %shift0_2 = lshr i140 %r0,128
 %word0_2 = trunc i140 %shift0_2 to i64
 %out0_2 = getelementptr i8,ptr %out,i64 16
 store i64 %word0_2,ptr %out0_2,align 1
 %word1_0 = trunc i140 %r1 to i64
 %out1_0 = getelementptr i8,ptr %out,i64 24
 store i64 %word1_0,ptr %out1_0,align 1
 %shift1_1 = lshr i140 %r1,64
 %word1_1 = trunc i140 %shift1_1 to i64
 %out1_1 = getelementptr i8,ptr %out,i64 32
 store i64 %word1_1,ptr %out1_1,align 1
 %shift1_2 = lshr i140 %r1,128
 %word1_2 = trunc i140 %shift1_2 to i64
 %out1_2 = getelementptr i8,ptr %out,i64 40
 store i64 %word1_2,ptr %out1_2,align 1
 %word2_0 = trunc i140 %r2 to i64
 %out2_0 = getelementptr i8,ptr %out,i64 48
 store i64 %word2_0,ptr %out2_0,align 1
 %shift2_1 = lshr i140 %r2,64
 %word2_1 = trunc i140 %shift2_1 to i64
 %out2_1 = getelementptr i8,ptr %out,i64 56
 store i64 %word2_1,ptr %out2_1,align 1
 %shift2_2 = lshr i140 %r2,128
 %word2_2 = trunc i140 %shift2_2 to i64
 %out2_2 = getelementptr i8,ptr %out,i64 64
 store i64 %word2_2,ptr %out2_2,align 1
 %word3_0 = trunc i140 %r3 to i64
 %out3_0 = getelementptr i8,ptr %out,i64 72
 store i64 %word3_0,ptr %out3_0,align 1
 %shift3_1 = lshr i140 %r3,64
 %word3_1 = trunc i140 %shift3_1 to i64
 %out3_1 = getelementptr i8,ptr %out,i64 80
 store i64 %word3_1,ptr %out3_1,align 1
 %shift3_2 = lshr i140 %r3,128
 %word3_2 = trunc i140 %shift3_2 to i64
 %out3_2 = getelementptr i8,ptr %out,i64 88
 store i64 %word3_2,ptr %out3_2,align 1
 %word4_0 = trunc i200 %r4 to i64
 %out4_0 = getelementptr i8,ptr %out,i64 96
 store i64 %word4_0,ptr %out4_0,align 1
 %shift4_1 = lshr i200 %r4,64
 %word4_1 = trunc i200 %shift4_1 to i64
 %out4_1 = getelementptr i8,ptr %out,i64 104
 store i64 %word4_1,ptr %out4_1,align 1
 %shift4_2 = lshr i200 %r4,128
 %word4_2 = trunc i200 %shift4_2 to i64
 %out4_2 = getelementptr i8,ptr %out,i64 112
 store i64 %word4_2,ptr %out4_2,align 1
 %shift4_3 = lshr i200 %r4,192
 %word4_3 = trunc i200 %shift4_3 to i64
 %out4_3 = getelementptr i8,ptr %out,i64 120
 store i64 %word4_3,ptr %out4_3,align 1
 %word5_0 = trunc i200 %r5 to i64
 %out5_0 = getelementptr i8,ptr %out,i64 128
 store i64 %word5_0,ptr %out5_0,align 1
 %shift5_1 = lshr i200 %r5,64
 %word5_1 = trunc i200 %shift5_1 to i64
 %out5_1 = getelementptr i8,ptr %out,i64 136
 store i64 %word5_1,ptr %out5_1,align 1
 %shift5_2 = lshr i200 %r5,128
 %word5_2 = trunc i200 %shift5_2 to i64
 %out5_2 = getelementptr i8,ptr %out,i64 144
 store i64 %word5_2,ptr %out5_2,align 1
 %shift5_3 = lshr i200 %r5,192
 %word5_3 = trunc i200 %shift5_3 to i64
 %out5_3 = getelementptr i8,ptr %out,i64 152
 store i64 %word5_3,ptr %out5_3,align 1
 %mp = getelementptr i8,ptr %out,i64 160
 store i64 %mask,ptr %mp,align 1
 %op = getelementptr i8,ptr %out,i64 168
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %mask,%token
 ret i64 %answer
}
define i64 @wide_saturation_vector_probe_1(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %temporary = alloca [160 x i8],align 16
 %constant = alloca i140,align 16
 store i140 1267650600228229401496703205376,ptr %constant,align 16
 %bp = getelementptr i8,ptr %input,i64 32
 %sp = getelementptr i8,ptr %input,i64 64
 %s0 = load i64,ptr %sp,align 1
 %tp = getelementptr i8,ptr %input,i64 72
 %t0 = load i64,ptr %tp,align 1
 %temporary0 = getelementptr i8,ptr %temporary,i64 0
 call void @wide_sat_140_u_1(ptr %temporary0,ptr %input,i64 %s0)
 %temporary1 = getelementptr i8,ptr %temporary,i64 24
 call void @wide_sat_140_s_1(ptr %temporary1,ptr %input,i64 %s0)
 %temporary2 = getelementptr i8,ptr %temporary,i64 48
 call void @wide_sat_140_u_1(ptr %temporary2,ptr %constant,i64 %s0)
 %temporary3 = getelementptr i8,ptr %temporary,i64 72
 call void @wide_sat_140_s_1(ptr %temporary3,ptr %constant,i64 %s0)
 %temporary4 = getelementptr i8,ptr %temporary,i64 96
 call void @wide_sat_200_u_1(ptr %temporary4,ptr %bp,i64 %t0)
 %temporary5 = getelementptr i8,ptr %temporary,i64 128
 call void @wide_sat_200_s_1(ptr %temporary5,ptr %bp,i64 %t0)
 %r0 = load i140,ptr %temporary0,align 1
 %r1 = load i140,ptr %temporary1,align 1
 %r2 = load i140,ptr %temporary2,align 1
 %r3 = load i140,ptr %temporary3,align 1
 %r4 = load i200,ptr %temporary4,align 1
 %r5 = load i200,ptr %temporary5,align 1
 %v0 = insertelement <4 x i140> poison,i140 %r0,i64 0
 %v1 = insertelement <4 x i140> %v0,i140 %r1,i64 1
 %v2 = insertelement <4 x i140> %v1,i140 %r2,i64 2
 %v3 = insertelement <4 x i140> %v2,i140 %r3,i64 3
 %cmp = icmp eq <4 x i140> %v3,<i140 0,i140 -1,i140 696898287454081973172991196020261297061887,i140 -696898287454081973172991196020261297061888>
 %packed_mask = bitcast <4 x i1> %cmp to i4
 %mask = zext i4 %packed_mask to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %word0_0 = trunc i140 %r0 to i64
 %out0_0 = getelementptr i8,ptr %out,i64 0
 store i64 %word0_0,ptr %out0_0,align 1
 %shift0_1 = lshr i140 %r0,64
 %word0_1 = trunc i140 %shift0_1 to i64
 %out0_1 = getelementptr i8,ptr %out,i64 8
 store i64 %word0_1,ptr %out0_1,align 1
 %shift0_2 = lshr i140 %r0,128
 %word0_2 = trunc i140 %shift0_2 to i64
 %out0_2 = getelementptr i8,ptr %out,i64 16
 store i64 %word0_2,ptr %out0_2,align 1
 %word1_0 = trunc i140 %r1 to i64
 %out1_0 = getelementptr i8,ptr %out,i64 24
 store i64 %word1_0,ptr %out1_0,align 1
 %shift1_1 = lshr i140 %r1,64
 %word1_1 = trunc i140 %shift1_1 to i64
 %out1_1 = getelementptr i8,ptr %out,i64 32
 store i64 %word1_1,ptr %out1_1,align 1
 %shift1_2 = lshr i140 %r1,128
 %word1_2 = trunc i140 %shift1_2 to i64
 %out1_2 = getelementptr i8,ptr %out,i64 40
 store i64 %word1_2,ptr %out1_2,align 1
 %word2_0 = trunc i140 %r2 to i64
 %out2_0 = getelementptr i8,ptr %out,i64 48
 store i64 %word2_0,ptr %out2_0,align 1
 %shift2_1 = lshr i140 %r2,64
 %word2_1 = trunc i140 %shift2_1 to i64
 %out2_1 = getelementptr i8,ptr %out,i64 56
 store i64 %word2_1,ptr %out2_1,align 1
 %shift2_2 = lshr i140 %r2,128
 %word2_2 = trunc i140 %shift2_2 to i64
 %out2_2 = getelementptr i8,ptr %out,i64 64
 store i64 %word2_2,ptr %out2_2,align 1
 %word3_0 = trunc i140 %r3 to i64
 %out3_0 = getelementptr i8,ptr %out,i64 72
 store i64 %word3_0,ptr %out3_0,align 1
 %shift3_1 = lshr i140 %r3,64
 %word3_1 = trunc i140 %shift3_1 to i64
 %out3_1 = getelementptr i8,ptr %out,i64 80
 store i64 %word3_1,ptr %out3_1,align 1
 %shift3_2 = lshr i140 %r3,128
 %word3_2 = trunc i140 %shift3_2 to i64
 %out3_2 = getelementptr i8,ptr %out,i64 88
 store i64 %word3_2,ptr %out3_2,align 1
 %word4_0 = trunc i200 %r4 to i64
 %out4_0 = getelementptr i8,ptr %out,i64 96
 store i64 %word4_0,ptr %out4_0,align 1
 %shift4_1 = lshr i200 %r4,64
 %word4_1 = trunc i200 %shift4_1 to i64
 %out4_1 = getelementptr i8,ptr %out,i64 104
 store i64 %word4_1,ptr %out4_1,align 1
 %shift4_2 = lshr i200 %r4,128
 %word4_2 = trunc i200 %shift4_2 to i64
 %out4_2 = getelementptr i8,ptr %out,i64 112
 store i64 %word4_2,ptr %out4_2,align 1
 %shift4_3 = lshr i200 %r4,192
 %word4_3 = trunc i200 %shift4_3 to i64
 %out4_3 = getelementptr i8,ptr %out,i64 120
 store i64 %word4_3,ptr %out4_3,align 1
 %word5_0 = trunc i200 %r5 to i64
 %out5_0 = getelementptr i8,ptr %out,i64 128
 store i64 %word5_0,ptr %out5_0,align 1
 %shift5_1 = lshr i200 %r5,64
 %word5_1 = trunc i200 %shift5_1 to i64
 %out5_1 = getelementptr i8,ptr %out,i64 136
 store i64 %word5_1,ptr %out5_1,align 1
 %shift5_2 = lshr i200 %r5,128
 %word5_2 = trunc i200 %shift5_2 to i64
 %out5_2 = getelementptr i8,ptr %out,i64 144
 store i64 %word5_2,ptr %out5_2,align 1
 %shift5_3 = lshr i200 %r5,192
 %word5_3 = trunc i200 %shift5_3 to i64
 %out5_3 = getelementptr i8,ptr %out,i64 152
 store i64 %word5_3,ptr %out5_3,align 1
 %mp = getelementptr i8,ptr %out,i64 160
 store i64 %mask,ptr %mp,align 1
 %op = getelementptr i8,ptr %out,i64 168
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %mask,%token
 ret i64 %answer
}
define i64 @wide_saturation_vector_probe_2(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %temporary = alloca [160 x i8],align 16
 %constant = alloca i140,align 16
 store i140 1267650600228229401496703205376,ptr %constant,align 16
 %bp = getelementptr i8,ptr %input,i64 32
 %sp = getelementptr i8,ptr %input,i64 64
 %s0 = load i64,ptr %sp,align 1
 %tp = getelementptr i8,ptr %input,i64 72
 %t0 = load i64,ptr %tp,align 1
 %temporary0 = getelementptr i8,ptr %temporary,i64 0
 call void @wide_sat_140_u_2(ptr %temporary0,ptr %input,i64 %s0)
 %temporary1 = getelementptr i8,ptr %temporary,i64 24
 call void @wide_sat_140_s_2(ptr %temporary1,ptr %input,i64 %s0)
 %temporary2 = getelementptr i8,ptr %temporary,i64 48
 call void @wide_sat_140_u_2(ptr %temporary2,ptr %constant,i64 %s0)
 %temporary3 = getelementptr i8,ptr %temporary,i64 72
 call void @wide_sat_140_s_2(ptr %temporary3,ptr %constant,i64 %s0)
 %temporary4 = getelementptr i8,ptr %temporary,i64 96
 call void @wide_sat_200_u_2(ptr %temporary4,ptr %bp,i64 %t0)
 %temporary5 = getelementptr i8,ptr %temporary,i64 128
 call void @wide_sat_200_s_2(ptr %temporary5,ptr %bp,i64 %t0)
 %r0 = load i140,ptr %temporary0,align 1
 %r1 = load i140,ptr %temporary1,align 1
 %r2 = load i140,ptr %temporary2,align 1
 %r3 = load i140,ptr %temporary3,align 1
 %r4 = load i200,ptr %temporary4,align 1
 %r5 = load i200,ptr %temporary5,align 1
 %v0 = insertelement <4 x i140> poison,i140 %r0,i64 0
 %v1 = insertelement <4 x i140> %v0,i140 %r1,i64 1
 %v2 = insertelement <4 x i140> %v1,i140 %r2,i64 2
 %v3 = insertelement <4 x i140> %v2,i140 %r3,i64 3
 %cmp = icmp eq <4 x i140> %v3,<i140 0,i140 -1,i140 696898287454081973172991196020261297061887,i140 -696898287454081973172991196020261297061888>
 %packed_mask = bitcast <4 x i1> %cmp to i4
 %mask = zext i4 %packed_mask to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %word0_0 = trunc i140 %r0 to i64
 %out0_0 = getelementptr i8,ptr %out,i64 0
 store i64 %word0_0,ptr %out0_0,align 1
 %shift0_1 = lshr i140 %r0,64
 %word0_1 = trunc i140 %shift0_1 to i64
 %out0_1 = getelementptr i8,ptr %out,i64 8
 store i64 %word0_1,ptr %out0_1,align 1
 %shift0_2 = lshr i140 %r0,128
 %word0_2 = trunc i140 %shift0_2 to i64
 %out0_2 = getelementptr i8,ptr %out,i64 16
 store i64 %word0_2,ptr %out0_2,align 1
 %word1_0 = trunc i140 %r1 to i64
 %out1_0 = getelementptr i8,ptr %out,i64 24
 store i64 %word1_0,ptr %out1_0,align 1
 %shift1_1 = lshr i140 %r1,64
 %word1_1 = trunc i140 %shift1_1 to i64
 %out1_1 = getelementptr i8,ptr %out,i64 32
 store i64 %word1_1,ptr %out1_1,align 1
 %shift1_2 = lshr i140 %r1,128
 %word1_2 = trunc i140 %shift1_2 to i64
 %out1_2 = getelementptr i8,ptr %out,i64 40
 store i64 %word1_2,ptr %out1_2,align 1
 %word2_0 = trunc i140 %r2 to i64
 %out2_0 = getelementptr i8,ptr %out,i64 48
 store i64 %word2_0,ptr %out2_0,align 1
 %shift2_1 = lshr i140 %r2,64
 %word2_1 = trunc i140 %shift2_1 to i64
 %out2_1 = getelementptr i8,ptr %out,i64 56
 store i64 %word2_1,ptr %out2_1,align 1
 %shift2_2 = lshr i140 %r2,128
 %word2_2 = trunc i140 %shift2_2 to i64
 %out2_2 = getelementptr i8,ptr %out,i64 64
 store i64 %word2_2,ptr %out2_2,align 1
 %word3_0 = trunc i140 %r3 to i64
 %out3_0 = getelementptr i8,ptr %out,i64 72
 store i64 %word3_0,ptr %out3_0,align 1
 %shift3_1 = lshr i140 %r3,64
 %word3_1 = trunc i140 %shift3_1 to i64
 %out3_1 = getelementptr i8,ptr %out,i64 80
 store i64 %word3_1,ptr %out3_1,align 1
 %shift3_2 = lshr i140 %r3,128
 %word3_2 = trunc i140 %shift3_2 to i64
 %out3_2 = getelementptr i8,ptr %out,i64 88
 store i64 %word3_2,ptr %out3_2,align 1
 %word4_0 = trunc i200 %r4 to i64
 %out4_0 = getelementptr i8,ptr %out,i64 96
 store i64 %word4_0,ptr %out4_0,align 1
 %shift4_1 = lshr i200 %r4,64
 %word4_1 = trunc i200 %shift4_1 to i64
 %out4_1 = getelementptr i8,ptr %out,i64 104
 store i64 %word4_1,ptr %out4_1,align 1
 %shift4_2 = lshr i200 %r4,128
 %word4_2 = trunc i200 %shift4_2 to i64
 %out4_2 = getelementptr i8,ptr %out,i64 112
 store i64 %word4_2,ptr %out4_2,align 1
 %shift4_3 = lshr i200 %r4,192
 %word4_3 = trunc i200 %shift4_3 to i64
 %out4_3 = getelementptr i8,ptr %out,i64 120
 store i64 %word4_3,ptr %out4_3,align 1
 %word5_0 = trunc i200 %r5 to i64
 %out5_0 = getelementptr i8,ptr %out,i64 128
 store i64 %word5_0,ptr %out5_0,align 1
 %shift5_1 = lshr i200 %r5,64
 %word5_1 = trunc i200 %shift5_1 to i64
 %out5_1 = getelementptr i8,ptr %out,i64 136
 store i64 %word5_1,ptr %out5_1,align 1
 %shift5_2 = lshr i200 %r5,128
 %word5_2 = trunc i200 %shift5_2 to i64
 %out5_2 = getelementptr i8,ptr %out,i64 144
 store i64 %word5_2,ptr %out5_2,align 1
 %shift5_3 = lshr i200 %r5,192
 %word5_3 = trunc i200 %shift5_3 to i64
 %out5_3 = getelementptr i8,ptr %out,i64 152
 store i64 %word5_3,ptr %out5_3,align 1
 %mp = getelementptr i8,ptr %out,i64 160
 store i64 %mask,ptr %mp,align 1
 %op = getelementptr i8,ptr %out,i64 168
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %mask,%token
 ret i64 %answer
}
define i64 @wide_saturation_vector_probe_3(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %temporary = alloca [160 x i8],align 16
 %constant = alloca i140,align 16
 store i140 1267650600228229401496703205376,ptr %constant,align 16
 %bp = getelementptr i8,ptr %input,i64 32
 %sp = getelementptr i8,ptr %input,i64 64
 %s0 = load i64,ptr %sp,align 1
 %tp = getelementptr i8,ptr %input,i64 72
 %t0 = load i64,ptr %tp,align 1
 %temporary0 = getelementptr i8,ptr %temporary,i64 0
 call void @wide_sat_140_u_0(ptr %temporary0,ptr %input,i64 %s0)
 %temporary1 = getelementptr i8,ptr %temporary,i64 24
 call void @wide_sat_140_s_0(ptr %temporary1,ptr %input,i64 %s0)
 %temporary2 = getelementptr i8,ptr %temporary,i64 48
 call void @wide_sat_140_u_0(ptr %temporary2,ptr %constant,i64 %s0)
 %temporary3 = getelementptr i8,ptr %temporary,i64 72
 call void @wide_sat_140_s_0(ptr %temporary3,ptr %constant,i64 %s0)
 %temporary4 = getelementptr i8,ptr %temporary,i64 96
 call void @wide_sat_200_u_0(ptr %temporary4,ptr %bp,i64 %t0)
 %temporary5 = getelementptr i8,ptr %temporary,i64 128
 call void @wide_sat_200_s_0(ptr %temporary5,ptr %bp,i64 %t0)
 %r0 = load i140,ptr %temporary0,align 1
 %r1 = load i140,ptr %temporary1,align 1
 %r2 = load i140,ptr %temporary2,align 1
 %r3 = load i140,ptr %temporary3,align 1
 %r4 = load i200,ptr %temporary4,align 1
 %r5 = load i200,ptr %temporary5,align 1
 %v0 = insertelement <4 x i140> poison,i140 %r0,i64 0
 %v1 = insertelement <4 x i140> %v0,i140 %r1,i64 1
 %v2 = insertelement <4 x i140> %v1,i140 %r2,i64 2
 %v3 = insertelement <4 x i140> %v2,i140 %r3,i64 3
 %w0 = insertelement <4 x i140> poison,i140 0,i32 0
 %w1 = insertelement <4 x i140> %w0,i140 -1,i32 1
 %w2 = insertelement <4 x i140> %w1,i140 696898287454081973172991196020261297061887,i32 2
 %w3 = insertelement <4 x i140> %w2,i140 -696898287454081973172991196020261297061888,i32 3
 %cmp = icmp eq <4 x i140> %v3,%w3
 %packed_mask = bitcast <4 x i1> %cmp to i4
 %mask = zext i4 %packed_mask to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %word0_0 = trunc i140 %r0 to i64
 %out0_0 = getelementptr i8,ptr %out,i64 0
 store i64 %word0_0,ptr %out0_0,align 1
 %shift0_1 = lshr i140 %r0,64
 %word0_1 = trunc i140 %shift0_1 to i64
 %out0_1 = getelementptr i8,ptr %out,i64 8
 store i64 %word0_1,ptr %out0_1,align 1
 %shift0_2 = lshr i140 %r0,128
 %word0_2 = trunc i140 %shift0_2 to i64
 %out0_2 = getelementptr i8,ptr %out,i64 16
 store i64 %word0_2,ptr %out0_2,align 1
 %word1_0 = trunc i140 %r1 to i64
 %out1_0 = getelementptr i8,ptr %out,i64 24
 store i64 %word1_0,ptr %out1_0,align 1
 %shift1_1 = lshr i140 %r1,64
 %word1_1 = trunc i140 %shift1_1 to i64
 %out1_1 = getelementptr i8,ptr %out,i64 32
 store i64 %word1_1,ptr %out1_1,align 1
 %shift1_2 = lshr i140 %r1,128
 %word1_2 = trunc i140 %shift1_2 to i64
 %out1_2 = getelementptr i8,ptr %out,i64 40
 store i64 %word1_2,ptr %out1_2,align 1
 %word2_0 = trunc i140 %r2 to i64
 %out2_0 = getelementptr i8,ptr %out,i64 48
 store i64 %word2_0,ptr %out2_0,align 1
 %shift2_1 = lshr i140 %r2,64
 %word2_1 = trunc i140 %shift2_1 to i64
 %out2_1 = getelementptr i8,ptr %out,i64 56
 store i64 %word2_1,ptr %out2_1,align 1
 %shift2_2 = lshr i140 %r2,128
 %word2_2 = trunc i140 %shift2_2 to i64
 %out2_2 = getelementptr i8,ptr %out,i64 64
 store i64 %word2_2,ptr %out2_2,align 1
 %word3_0 = trunc i140 %r3 to i64
 %out3_0 = getelementptr i8,ptr %out,i64 72
 store i64 %word3_0,ptr %out3_0,align 1
 %shift3_1 = lshr i140 %r3,64
 %word3_1 = trunc i140 %shift3_1 to i64
 %out3_1 = getelementptr i8,ptr %out,i64 80
 store i64 %word3_1,ptr %out3_1,align 1
 %shift3_2 = lshr i140 %r3,128
 %word3_2 = trunc i140 %shift3_2 to i64
 %out3_2 = getelementptr i8,ptr %out,i64 88
 store i64 %word3_2,ptr %out3_2,align 1
 %word4_0 = trunc i200 %r4 to i64
 %out4_0 = getelementptr i8,ptr %out,i64 96
 store i64 %word4_0,ptr %out4_0,align 1
 %shift4_1 = lshr i200 %r4,64
 %word4_1 = trunc i200 %shift4_1 to i64
 %out4_1 = getelementptr i8,ptr %out,i64 104
 store i64 %word4_1,ptr %out4_1,align 1
 %shift4_2 = lshr i200 %r4,128
 %word4_2 = trunc i200 %shift4_2 to i64
 %out4_2 = getelementptr i8,ptr %out,i64 112
 store i64 %word4_2,ptr %out4_2,align 1
 %shift4_3 = lshr i200 %r4,192
 %word4_3 = trunc i200 %shift4_3 to i64
 %out4_3 = getelementptr i8,ptr %out,i64 120
 store i64 %word4_3,ptr %out4_3,align 1
 %word5_0 = trunc i200 %r5 to i64
 %out5_0 = getelementptr i8,ptr %out,i64 128
 store i64 %word5_0,ptr %out5_0,align 1
 %shift5_1 = lshr i200 %r5,64
 %word5_1 = trunc i200 %shift5_1 to i64
 %out5_1 = getelementptr i8,ptr %out,i64 136
 store i64 %word5_1,ptr %out5_1,align 1
 %shift5_2 = lshr i200 %r5,128
 %word5_2 = trunc i200 %shift5_2 to i64
 %out5_2 = getelementptr i8,ptr %out,i64 144
 store i64 %word5_2,ptr %out5_2,align 1
 %shift5_3 = lshr i200 %r5,192
 %word5_3 = trunc i200 %shift5_3 to i64
 %out5_3 = getelementptr i8,ptr %out,i64 152
 store i64 %word5_3,ptr %out5_3,align 1
 %mp = getelementptr i8,ptr %out,i64 160
 store i64 %mask,ptr %mp,align 1
 %op = getelementptr i8,ptr %out,i64 168
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %mask,%token
 ret i64 %answer
}
define i64 @wide_saturation_vector_probe_4(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %temporary = alloca [160 x i8],align 16
 %constant = alloca i140,align 16
 store i140 1267650600228229401496703205376,ptr %constant,align 16
 %bp = getelementptr i8,ptr %input,i64 32
 %sp = getelementptr i8,ptr %input,i64 64
 %s0 = load i64,ptr %sp,align 1
 %tp = getelementptr i8,ptr %input,i64 72
 %t0 = load i64,ptr %tp,align 1
 %temporary0 = getelementptr i8,ptr %temporary,i64 0
 call void @wide_sat_140_u_1(ptr %temporary0,ptr %input,i64 %s0)
 %temporary1 = getelementptr i8,ptr %temporary,i64 24
 call void @wide_sat_140_s_1(ptr %temporary1,ptr %input,i64 %s0)
 %temporary2 = getelementptr i8,ptr %temporary,i64 48
 call void @wide_sat_140_u_1(ptr %temporary2,ptr %constant,i64 %s0)
 %temporary3 = getelementptr i8,ptr %temporary,i64 72
 call void @wide_sat_140_s_1(ptr %temporary3,ptr %constant,i64 %s0)
 %temporary4 = getelementptr i8,ptr %temporary,i64 96
 call void @wide_sat_200_u_1(ptr %temporary4,ptr %bp,i64 %t0)
 %temporary5 = getelementptr i8,ptr %temporary,i64 128
 call void @wide_sat_200_s_1(ptr %temporary5,ptr %bp,i64 %t0)
 %r0 = load i140,ptr %temporary0,align 1
 %r1 = load i140,ptr %temporary1,align 1
 %r2 = load i140,ptr %temporary2,align 1
 %r3 = load i140,ptr %temporary3,align 1
 %r4 = load i200,ptr %temporary4,align 1
 %r5 = load i200,ptr %temporary5,align 1
 %v0 = insertelement <4 x i140> poison,i140 %r0,i64 0
 %v1 = insertelement <4 x i140> %v0,i140 %r1,i64 1
 %v2 = insertelement <4 x i140> %v1,i140 %r2,i64 2
 %v3 = insertelement <4 x i140> %v2,i140 %r3,i64 3
 %w0 = insertelement <4 x i140> poison,i140 0,i32 0
 %w1 = insertelement <4 x i140> %w0,i140 -1,i32 1
 %w2 = insertelement <4 x i140> %w1,i140 696898287454081973172991196020261297061887,i32 2
 %w3 = insertelement <4 x i140> %w2,i140 -696898287454081973172991196020261297061888,i32 3
 %cmp = icmp eq <4 x i140> %v3,%w3
 %packed_mask = bitcast <4 x i1> %cmp to i4
 %mask = zext i4 %packed_mask to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %word0_0 = trunc i140 %r0 to i64
 %out0_0 = getelementptr i8,ptr %out,i64 0
 store i64 %word0_0,ptr %out0_0,align 1
 %shift0_1 = lshr i140 %r0,64
 %word0_1 = trunc i140 %shift0_1 to i64
 %out0_1 = getelementptr i8,ptr %out,i64 8
 store i64 %word0_1,ptr %out0_1,align 1
 %shift0_2 = lshr i140 %r0,128
 %word0_2 = trunc i140 %shift0_2 to i64
 %out0_2 = getelementptr i8,ptr %out,i64 16
 store i64 %word0_2,ptr %out0_2,align 1
 %word1_0 = trunc i140 %r1 to i64
 %out1_0 = getelementptr i8,ptr %out,i64 24
 store i64 %word1_0,ptr %out1_0,align 1
 %shift1_1 = lshr i140 %r1,64
 %word1_1 = trunc i140 %shift1_1 to i64
 %out1_1 = getelementptr i8,ptr %out,i64 32
 store i64 %word1_1,ptr %out1_1,align 1
 %shift1_2 = lshr i140 %r1,128
 %word1_2 = trunc i140 %shift1_2 to i64
 %out1_2 = getelementptr i8,ptr %out,i64 40
 store i64 %word1_2,ptr %out1_2,align 1
 %word2_0 = trunc i140 %r2 to i64
 %out2_0 = getelementptr i8,ptr %out,i64 48
 store i64 %word2_0,ptr %out2_0,align 1
 %shift2_1 = lshr i140 %r2,64
 %word2_1 = trunc i140 %shift2_1 to i64
 %out2_1 = getelementptr i8,ptr %out,i64 56
 store i64 %word2_1,ptr %out2_1,align 1
 %shift2_2 = lshr i140 %r2,128
 %word2_2 = trunc i140 %shift2_2 to i64
 %out2_2 = getelementptr i8,ptr %out,i64 64
 store i64 %word2_2,ptr %out2_2,align 1
 %word3_0 = trunc i140 %r3 to i64
 %out3_0 = getelementptr i8,ptr %out,i64 72
 store i64 %word3_0,ptr %out3_0,align 1
 %shift3_1 = lshr i140 %r3,64
 %word3_1 = trunc i140 %shift3_1 to i64
 %out3_1 = getelementptr i8,ptr %out,i64 80
 store i64 %word3_1,ptr %out3_1,align 1
 %shift3_2 = lshr i140 %r3,128
 %word3_2 = trunc i140 %shift3_2 to i64
 %out3_2 = getelementptr i8,ptr %out,i64 88
 store i64 %word3_2,ptr %out3_2,align 1
 %word4_0 = trunc i200 %r4 to i64
 %out4_0 = getelementptr i8,ptr %out,i64 96
 store i64 %word4_0,ptr %out4_0,align 1
 %shift4_1 = lshr i200 %r4,64
 %word4_1 = trunc i200 %shift4_1 to i64
 %out4_1 = getelementptr i8,ptr %out,i64 104
 store i64 %word4_1,ptr %out4_1,align 1
 %shift4_2 = lshr i200 %r4,128
 %word4_2 = trunc i200 %shift4_2 to i64
 %out4_2 = getelementptr i8,ptr %out,i64 112
 store i64 %word4_2,ptr %out4_2,align 1
 %shift4_3 = lshr i200 %r4,192
 %word4_3 = trunc i200 %shift4_3 to i64
 %out4_3 = getelementptr i8,ptr %out,i64 120
 store i64 %word4_3,ptr %out4_3,align 1
 %word5_0 = trunc i200 %r5 to i64
 %out5_0 = getelementptr i8,ptr %out,i64 128
 store i64 %word5_0,ptr %out5_0,align 1
 %shift5_1 = lshr i200 %r5,64
 %word5_1 = trunc i200 %shift5_1 to i64
 %out5_1 = getelementptr i8,ptr %out,i64 136
 store i64 %word5_1,ptr %out5_1,align 1
 %shift5_2 = lshr i200 %r5,128
 %word5_2 = trunc i200 %shift5_2 to i64
 %out5_2 = getelementptr i8,ptr %out,i64 144
 store i64 %word5_2,ptr %out5_2,align 1
 %shift5_3 = lshr i200 %r5,192
 %word5_3 = trunc i200 %shift5_3 to i64
 %out5_3 = getelementptr i8,ptr %out,i64 152
 store i64 %word5_3,ptr %out5_3,align 1
 %mp = getelementptr i8,ptr %out,i64 160
 store i64 %mask,ptr %mp,align 1
 %op = getelementptr i8,ptr %out,i64 168
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %mask,%token
 ret i64 %answer
}
define i64 @wide_saturation_vector_probe_5(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %temporary = alloca [160 x i8],align 16
 %constant = alloca i140,align 16
 store i140 1267650600228229401496703205376,ptr %constant,align 16
 %bp = getelementptr i8,ptr %input,i64 32
 %sp = getelementptr i8,ptr %input,i64 64
 %s0 = load i64,ptr %sp,align 1
 %tp = getelementptr i8,ptr %input,i64 72
 %t0 = load i64,ptr %tp,align 1
 %temporary0 = getelementptr i8,ptr %temporary,i64 0
 call void @wide_sat_140_u_2(ptr %temporary0,ptr %input,i64 %s0)
 %temporary1 = getelementptr i8,ptr %temporary,i64 24
 call void @wide_sat_140_s_2(ptr %temporary1,ptr %input,i64 %s0)
 %temporary2 = getelementptr i8,ptr %temporary,i64 48
 call void @wide_sat_140_u_2(ptr %temporary2,ptr %constant,i64 %s0)
 %temporary3 = getelementptr i8,ptr %temporary,i64 72
 call void @wide_sat_140_s_2(ptr %temporary3,ptr %constant,i64 %s0)
 %temporary4 = getelementptr i8,ptr %temporary,i64 96
 call void @wide_sat_200_u_2(ptr %temporary4,ptr %bp,i64 %t0)
 %temporary5 = getelementptr i8,ptr %temporary,i64 128
 call void @wide_sat_200_s_2(ptr %temporary5,ptr %bp,i64 %t0)
 %r0 = load i140,ptr %temporary0,align 1
 %r1 = load i140,ptr %temporary1,align 1
 %r2 = load i140,ptr %temporary2,align 1
 %r3 = load i140,ptr %temporary3,align 1
 %r4 = load i200,ptr %temporary4,align 1
 %r5 = load i200,ptr %temporary5,align 1
 %v0 = insertelement <4 x i140> poison,i140 %r0,i64 0
 %v1 = insertelement <4 x i140> %v0,i140 %r1,i64 1
 %v2 = insertelement <4 x i140> %v1,i140 %r2,i64 2
 %v3 = insertelement <4 x i140> %v2,i140 %r3,i64 3
 %w0 = insertelement <4 x i140> poison,i140 0,i32 0
 %w1 = insertelement <4 x i140> %w0,i140 -1,i32 1
 %w2 = insertelement <4 x i140> %w1,i140 696898287454081973172991196020261297061887,i32 2
 %w3 = insertelement <4 x i140> %w2,i140 -696898287454081973172991196020261297061888,i32 3
 %cmp = icmp eq <4 x i140> %v3,%w3
 %packed_mask = bitcast <4 x i1> %cmp to i4
 %mask = zext i4 %packed_mask to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %word0_0 = trunc i140 %r0 to i64
 %out0_0 = getelementptr i8,ptr %out,i64 0
 store i64 %word0_0,ptr %out0_0,align 1
 %shift0_1 = lshr i140 %r0,64
 %word0_1 = trunc i140 %shift0_1 to i64
 %out0_1 = getelementptr i8,ptr %out,i64 8
 store i64 %word0_1,ptr %out0_1,align 1
 %shift0_2 = lshr i140 %r0,128
 %word0_2 = trunc i140 %shift0_2 to i64
 %out0_2 = getelementptr i8,ptr %out,i64 16
 store i64 %word0_2,ptr %out0_2,align 1
 %word1_0 = trunc i140 %r1 to i64
 %out1_0 = getelementptr i8,ptr %out,i64 24
 store i64 %word1_0,ptr %out1_0,align 1
 %shift1_1 = lshr i140 %r1,64
 %word1_1 = trunc i140 %shift1_1 to i64
 %out1_1 = getelementptr i8,ptr %out,i64 32
 store i64 %word1_1,ptr %out1_1,align 1
 %shift1_2 = lshr i140 %r1,128
 %word1_2 = trunc i140 %shift1_2 to i64
 %out1_2 = getelementptr i8,ptr %out,i64 40
 store i64 %word1_2,ptr %out1_2,align 1
 %word2_0 = trunc i140 %r2 to i64
 %out2_0 = getelementptr i8,ptr %out,i64 48
 store i64 %word2_0,ptr %out2_0,align 1
 %shift2_1 = lshr i140 %r2,64
 %word2_1 = trunc i140 %shift2_1 to i64
 %out2_1 = getelementptr i8,ptr %out,i64 56
 store i64 %word2_1,ptr %out2_1,align 1
 %shift2_2 = lshr i140 %r2,128
 %word2_2 = trunc i140 %shift2_2 to i64
 %out2_2 = getelementptr i8,ptr %out,i64 64
 store i64 %word2_2,ptr %out2_2,align 1
 %word3_0 = trunc i140 %r3 to i64
 %out3_0 = getelementptr i8,ptr %out,i64 72
 store i64 %word3_0,ptr %out3_0,align 1
 %shift3_1 = lshr i140 %r3,64
 %word3_1 = trunc i140 %shift3_1 to i64
 %out3_1 = getelementptr i8,ptr %out,i64 80
 store i64 %word3_1,ptr %out3_1,align 1
 %shift3_2 = lshr i140 %r3,128
 %word3_2 = trunc i140 %shift3_2 to i64
 %out3_2 = getelementptr i8,ptr %out,i64 88
 store i64 %word3_2,ptr %out3_2,align 1
 %word4_0 = trunc i200 %r4 to i64
 %out4_0 = getelementptr i8,ptr %out,i64 96
 store i64 %word4_0,ptr %out4_0,align 1
 %shift4_1 = lshr i200 %r4,64
 %word4_1 = trunc i200 %shift4_1 to i64
 %out4_1 = getelementptr i8,ptr %out,i64 104
 store i64 %word4_1,ptr %out4_1,align 1
 %shift4_2 = lshr i200 %r4,128
 %word4_2 = trunc i200 %shift4_2 to i64
 %out4_2 = getelementptr i8,ptr %out,i64 112
 store i64 %word4_2,ptr %out4_2,align 1
 %shift4_3 = lshr i200 %r4,192
 %word4_3 = trunc i200 %shift4_3 to i64
 %out4_3 = getelementptr i8,ptr %out,i64 120
 store i64 %word4_3,ptr %out4_3,align 1
 %word5_0 = trunc i200 %r5 to i64
 %out5_0 = getelementptr i8,ptr %out,i64 128
 store i64 %word5_0,ptr %out5_0,align 1
 %shift5_1 = lshr i200 %r5,64
 %word5_1 = trunc i200 %shift5_1 to i64
 %out5_1 = getelementptr i8,ptr %out,i64 136
 store i64 %word5_1,ptr %out5_1,align 1
 %shift5_2 = lshr i200 %r5,128
 %word5_2 = trunc i200 %shift5_2 to i64
 %out5_2 = getelementptr i8,ptr %out,i64 144
 store i64 %word5_2,ptr %out5_2,align 1
 %shift5_3 = lshr i200 %r5,192
 %word5_3 = trunc i200 %shift5_3 to i64
 %out5_3 = getelementptr i8,ptr %out,i64 152
 store i64 %word5_3,ptr %out5_3,align 1
 %mp = getelementptr i8,ptr %out,i64 160
 store i64 %mask,ptr %mp,align 1
 %op = getelementptr i8,ptr %out,i64 168
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %mask,%token
 ret i64 %answer
}
define i64 @wide_saturation_vector_probe_6(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %temporary = alloca [160 x i8],align 16
 %constant = alloca i140,align 16
 store i140 1267650600228229401496703205376,ptr %constant,align 16
 %bp = getelementptr i8,ptr %input,i64 32
 %sp = getelementptr i8,ptr %input,i64 64
 %s0 = load i64,ptr %sp,align 1
 %tp = getelementptr i8,ptr %input,i64 72
 %t0 = load i64,ptr %tp,align 1
 %temporary0 = getelementptr i8,ptr %temporary,i64 0
 call void @wide_sat_140_u_0(ptr %temporary0,ptr %input,i64 %s0)
 %temporary1 = getelementptr i8,ptr %temporary,i64 24
 call void @wide_sat_140_s_0(ptr %temporary1,ptr %input,i64 %s0)
 %temporary2 = getelementptr i8,ptr %temporary,i64 48
 call void @wide_sat_140_u_0(ptr %temporary2,ptr %constant,i64 %s0)
 %temporary3 = getelementptr i8,ptr %temporary,i64 72
 call void @wide_sat_140_s_0(ptr %temporary3,ptr %constant,i64 %s0)
 %temporary4 = getelementptr i8,ptr %temporary,i64 96
 call void @wide_sat_200_u_0(ptr %temporary4,ptr %bp,i64 %t0)
 %temporary5 = getelementptr i8,ptr %temporary,i64 128
 call void @wide_sat_200_s_0(ptr %temporary5,ptr %bp,i64 %t0)
 %r0 = load i140,ptr %temporary0,align 1
 %r1 = load i140,ptr %temporary1,align 1
 %r2 = load i140,ptr %temporary2,align 1
 %r3 = load i140,ptr %temporary3,align 1
 %r4 = load i200,ptr %temporary4,align 1
 %r5 = load i200,ptr %temporary5,align 1
 %v0 = insertelement <4 x i140> poison,i140 %r0,i64 0
 %v1 = insertelement <4 x i140> %v0,i140 %r1,i64 1
 %v2 = insertelement <4 x i140> %v1,i140 %r2,i64 2
 %v3 = insertelement <4 x i140> %v2,i140 %r3,i64 3
 %cmp = icmp ne <4 x i140> %v3,<i140 0,i140 -1,i140 696898287454081973172991196020261297061887,i140 -696898287454081973172991196020261297061888>
 %packed_mask = bitcast <4 x i1> %cmp to i4
 %mask = zext i4 %packed_mask to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %word0_0 = trunc i140 %r0 to i64
 %out0_0 = getelementptr i8,ptr %out,i64 0
 store i64 %word0_0,ptr %out0_0,align 1
 %shift0_1 = lshr i140 %r0,64
 %word0_1 = trunc i140 %shift0_1 to i64
 %out0_1 = getelementptr i8,ptr %out,i64 8
 store i64 %word0_1,ptr %out0_1,align 1
 %shift0_2 = lshr i140 %r0,128
 %word0_2 = trunc i140 %shift0_2 to i64
 %out0_2 = getelementptr i8,ptr %out,i64 16
 store i64 %word0_2,ptr %out0_2,align 1
 %word1_0 = trunc i140 %r1 to i64
 %out1_0 = getelementptr i8,ptr %out,i64 24
 store i64 %word1_0,ptr %out1_0,align 1
 %shift1_1 = lshr i140 %r1,64
 %word1_1 = trunc i140 %shift1_1 to i64
 %out1_1 = getelementptr i8,ptr %out,i64 32
 store i64 %word1_1,ptr %out1_1,align 1
 %shift1_2 = lshr i140 %r1,128
 %word1_2 = trunc i140 %shift1_2 to i64
 %out1_2 = getelementptr i8,ptr %out,i64 40
 store i64 %word1_2,ptr %out1_2,align 1
 %word2_0 = trunc i140 %r2 to i64
 %out2_0 = getelementptr i8,ptr %out,i64 48
 store i64 %word2_0,ptr %out2_0,align 1
 %shift2_1 = lshr i140 %r2,64
 %word2_1 = trunc i140 %shift2_1 to i64
 %out2_1 = getelementptr i8,ptr %out,i64 56
 store i64 %word2_1,ptr %out2_1,align 1
 %shift2_2 = lshr i140 %r2,128
 %word2_2 = trunc i140 %shift2_2 to i64
 %out2_2 = getelementptr i8,ptr %out,i64 64
 store i64 %word2_2,ptr %out2_2,align 1
 %word3_0 = trunc i140 %r3 to i64
 %out3_0 = getelementptr i8,ptr %out,i64 72
 store i64 %word3_0,ptr %out3_0,align 1
 %shift3_1 = lshr i140 %r3,64
 %word3_1 = trunc i140 %shift3_1 to i64
 %out3_1 = getelementptr i8,ptr %out,i64 80
 store i64 %word3_1,ptr %out3_1,align 1
 %shift3_2 = lshr i140 %r3,128
 %word3_2 = trunc i140 %shift3_2 to i64
 %out3_2 = getelementptr i8,ptr %out,i64 88
 store i64 %word3_2,ptr %out3_2,align 1
 %word4_0 = trunc i200 %r4 to i64
 %out4_0 = getelementptr i8,ptr %out,i64 96
 store i64 %word4_0,ptr %out4_0,align 1
 %shift4_1 = lshr i200 %r4,64
 %word4_1 = trunc i200 %shift4_1 to i64
 %out4_1 = getelementptr i8,ptr %out,i64 104
 store i64 %word4_1,ptr %out4_1,align 1
 %shift4_2 = lshr i200 %r4,128
 %word4_2 = trunc i200 %shift4_2 to i64
 %out4_2 = getelementptr i8,ptr %out,i64 112
 store i64 %word4_2,ptr %out4_2,align 1
 %shift4_3 = lshr i200 %r4,192
 %word4_3 = trunc i200 %shift4_3 to i64
 %out4_3 = getelementptr i8,ptr %out,i64 120
 store i64 %word4_3,ptr %out4_3,align 1
 %word5_0 = trunc i200 %r5 to i64
 %out5_0 = getelementptr i8,ptr %out,i64 128
 store i64 %word5_0,ptr %out5_0,align 1
 %shift5_1 = lshr i200 %r5,64
 %word5_1 = trunc i200 %shift5_1 to i64
 %out5_1 = getelementptr i8,ptr %out,i64 136
 store i64 %word5_1,ptr %out5_1,align 1
 %shift5_2 = lshr i200 %r5,128
 %word5_2 = trunc i200 %shift5_2 to i64
 %out5_2 = getelementptr i8,ptr %out,i64 144
 store i64 %word5_2,ptr %out5_2,align 1
 %shift5_3 = lshr i200 %r5,192
 %word5_3 = trunc i200 %shift5_3 to i64
 %out5_3 = getelementptr i8,ptr %out,i64 152
 store i64 %word5_3,ptr %out5_3,align 1
 %mp = getelementptr i8,ptr %out,i64 160
 store i64 %mask,ptr %mp,align 1
 %op = getelementptr i8,ptr %out,i64 168
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %mask,%token
 ret i64 %answer
}
define i64 @wide_saturation_vector_probe_7(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %temporary = alloca [160 x i8],align 16
 %constant = alloca i140,align 16
 store i140 1267650600228229401496703205376,ptr %constant,align 16
 %bp = getelementptr i8,ptr %input,i64 32
 %sp = getelementptr i8,ptr %input,i64 64
 %s0 = load i64,ptr %sp,align 1
 %tp = getelementptr i8,ptr %input,i64 72
 %t0 = load i64,ptr %tp,align 1
 %temporary0 = getelementptr i8,ptr %temporary,i64 0
 call void @wide_sat_140_u_1(ptr %temporary0,ptr %input,i64 %s0)
 %temporary1 = getelementptr i8,ptr %temporary,i64 24
 call void @wide_sat_140_s_1(ptr %temporary1,ptr %input,i64 %s0)
 %temporary2 = getelementptr i8,ptr %temporary,i64 48
 call void @wide_sat_140_u_1(ptr %temporary2,ptr %constant,i64 %s0)
 %temporary3 = getelementptr i8,ptr %temporary,i64 72
 call void @wide_sat_140_s_1(ptr %temporary3,ptr %constant,i64 %s0)
 %temporary4 = getelementptr i8,ptr %temporary,i64 96
 call void @wide_sat_200_u_1(ptr %temporary4,ptr %bp,i64 %t0)
 %temporary5 = getelementptr i8,ptr %temporary,i64 128
 call void @wide_sat_200_s_1(ptr %temporary5,ptr %bp,i64 %t0)
 %r0 = load i140,ptr %temporary0,align 1
 %r1 = load i140,ptr %temporary1,align 1
 %r2 = load i140,ptr %temporary2,align 1
 %r3 = load i140,ptr %temporary3,align 1
 %r4 = load i200,ptr %temporary4,align 1
 %r5 = load i200,ptr %temporary5,align 1
 %v0 = insertelement <4 x i140> poison,i140 %r0,i64 0
 %v1 = insertelement <4 x i140> %v0,i140 %r1,i64 1
 %v2 = insertelement <4 x i140> %v1,i140 %r2,i64 2
 %v3 = insertelement <4 x i140> %v2,i140 %r3,i64 3
 %cmp = icmp ne <4 x i140> %v3,<i140 0,i140 -1,i140 696898287454081973172991196020261297061887,i140 -696898287454081973172991196020261297061888>
 %packed_mask = bitcast <4 x i1> %cmp to i4
 %mask = zext i4 %packed_mask to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %word0_0 = trunc i140 %r0 to i64
 %out0_0 = getelementptr i8,ptr %out,i64 0
 store i64 %word0_0,ptr %out0_0,align 1
 %shift0_1 = lshr i140 %r0,64
 %word0_1 = trunc i140 %shift0_1 to i64
 %out0_1 = getelementptr i8,ptr %out,i64 8
 store i64 %word0_1,ptr %out0_1,align 1
 %shift0_2 = lshr i140 %r0,128
 %word0_2 = trunc i140 %shift0_2 to i64
 %out0_2 = getelementptr i8,ptr %out,i64 16
 store i64 %word0_2,ptr %out0_2,align 1
 %word1_0 = trunc i140 %r1 to i64
 %out1_0 = getelementptr i8,ptr %out,i64 24
 store i64 %word1_0,ptr %out1_0,align 1
 %shift1_1 = lshr i140 %r1,64
 %word1_1 = trunc i140 %shift1_1 to i64
 %out1_1 = getelementptr i8,ptr %out,i64 32
 store i64 %word1_1,ptr %out1_1,align 1
 %shift1_2 = lshr i140 %r1,128
 %word1_2 = trunc i140 %shift1_2 to i64
 %out1_2 = getelementptr i8,ptr %out,i64 40
 store i64 %word1_2,ptr %out1_2,align 1
 %word2_0 = trunc i140 %r2 to i64
 %out2_0 = getelementptr i8,ptr %out,i64 48
 store i64 %word2_0,ptr %out2_0,align 1
 %shift2_1 = lshr i140 %r2,64
 %word2_1 = trunc i140 %shift2_1 to i64
 %out2_1 = getelementptr i8,ptr %out,i64 56
 store i64 %word2_1,ptr %out2_1,align 1
 %shift2_2 = lshr i140 %r2,128
 %word2_2 = trunc i140 %shift2_2 to i64
 %out2_2 = getelementptr i8,ptr %out,i64 64
 store i64 %word2_2,ptr %out2_2,align 1
 %word3_0 = trunc i140 %r3 to i64
 %out3_0 = getelementptr i8,ptr %out,i64 72
 store i64 %word3_0,ptr %out3_0,align 1
 %shift3_1 = lshr i140 %r3,64
 %word3_1 = trunc i140 %shift3_1 to i64
 %out3_1 = getelementptr i8,ptr %out,i64 80
 store i64 %word3_1,ptr %out3_1,align 1
 %shift3_2 = lshr i140 %r3,128
 %word3_2 = trunc i140 %shift3_2 to i64
 %out3_2 = getelementptr i8,ptr %out,i64 88
 store i64 %word3_2,ptr %out3_2,align 1
 %word4_0 = trunc i200 %r4 to i64
 %out4_0 = getelementptr i8,ptr %out,i64 96
 store i64 %word4_0,ptr %out4_0,align 1
 %shift4_1 = lshr i200 %r4,64
 %word4_1 = trunc i200 %shift4_1 to i64
 %out4_1 = getelementptr i8,ptr %out,i64 104
 store i64 %word4_1,ptr %out4_1,align 1
 %shift4_2 = lshr i200 %r4,128
 %word4_2 = trunc i200 %shift4_2 to i64
 %out4_2 = getelementptr i8,ptr %out,i64 112
 store i64 %word4_2,ptr %out4_2,align 1
 %shift4_3 = lshr i200 %r4,192
 %word4_3 = trunc i200 %shift4_3 to i64
 %out4_3 = getelementptr i8,ptr %out,i64 120
 store i64 %word4_3,ptr %out4_3,align 1
 %word5_0 = trunc i200 %r5 to i64
 %out5_0 = getelementptr i8,ptr %out,i64 128
 store i64 %word5_0,ptr %out5_0,align 1
 %shift5_1 = lshr i200 %r5,64
 %word5_1 = trunc i200 %shift5_1 to i64
 %out5_1 = getelementptr i8,ptr %out,i64 136
 store i64 %word5_1,ptr %out5_1,align 1
 %shift5_2 = lshr i200 %r5,128
 %word5_2 = trunc i200 %shift5_2 to i64
 %out5_2 = getelementptr i8,ptr %out,i64 144
 store i64 %word5_2,ptr %out5_2,align 1
 %shift5_3 = lshr i200 %r5,192
 %word5_3 = trunc i200 %shift5_3 to i64
 %out5_3 = getelementptr i8,ptr %out,i64 152
 store i64 %word5_3,ptr %out5_3,align 1
 %mp = getelementptr i8,ptr %out,i64 160
 store i64 %mask,ptr %mp,align 1
 %op = getelementptr i8,ptr %out,i64 168
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %mask,%token
 ret i64 %answer
}
define i64 @wide_saturation_vector_probe_8(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %temporary = alloca [160 x i8],align 16
 %constant = alloca i140,align 16
 store i140 1267650600228229401496703205376,ptr %constant,align 16
 %bp = getelementptr i8,ptr %input,i64 32
 %sp = getelementptr i8,ptr %input,i64 64
 %s0 = load i64,ptr %sp,align 1
 %tp = getelementptr i8,ptr %input,i64 72
 %t0 = load i64,ptr %tp,align 1
 %temporary0 = getelementptr i8,ptr %temporary,i64 0
 call void @wide_sat_140_u_2(ptr %temporary0,ptr %input,i64 %s0)
 %temporary1 = getelementptr i8,ptr %temporary,i64 24
 call void @wide_sat_140_s_2(ptr %temporary1,ptr %input,i64 %s0)
 %temporary2 = getelementptr i8,ptr %temporary,i64 48
 call void @wide_sat_140_u_2(ptr %temporary2,ptr %constant,i64 %s0)
 %temporary3 = getelementptr i8,ptr %temporary,i64 72
 call void @wide_sat_140_s_2(ptr %temporary3,ptr %constant,i64 %s0)
 %temporary4 = getelementptr i8,ptr %temporary,i64 96
 call void @wide_sat_200_u_2(ptr %temporary4,ptr %bp,i64 %t0)
 %temporary5 = getelementptr i8,ptr %temporary,i64 128
 call void @wide_sat_200_s_2(ptr %temporary5,ptr %bp,i64 %t0)
 %r0 = load i140,ptr %temporary0,align 1
 %r1 = load i140,ptr %temporary1,align 1
 %r2 = load i140,ptr %temporary2,align 1
 %r3 = load i140,ptr %temporary3,align 1
 %r4 = load i200,ptr %temporary4,align 1
 %r5 = load i200,ptr %temporary5,align 1
 %v0 = insertelement <4 x i140> poison,i140 %r0,i64 0
 %v1 = insertelement <4 x i140> %v0,i140 %r1,i64 1
 %v2 = insertelement <4 x i140> %v1,i140 %r2,i64 2
 %v3 = insertelement <4 x i140> %v2,i140 %r3,i64 3
 %cmp = icmp ne <4 x i140> %v3,<i140 0,i140 -1,i140 696898287454081973172991196020261297061887,i140 -696898287454081973172991196020261297061888>
 %packed_mask = bitcast <4 x i1> %cmp to i4
 %mask = zext i4 %packed_mask to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %word0_0 = trunc i140 %r0 to i64
 %out0_0 = getelementptr i8,ptr %out,i64 0
 store i64 %word0_0,ptr %out0_0,align 1
 %shift0_1 = lshr i140 %r0,64
 %word0_1 = trunc i140 %shift0_1 to i64
 %out0_1 = getelementptr i8,ptr %out,i64 8
 store i64 %word0_1,ptr %out0_1,align 1
 %shift0_2 = lshr i140 %r0,128
 %word0_2 = trunc i140 %shift0_2 to i64
 %out0_2 = getelementptr i8,ptr %out,i64 16
 store i64 %word0_2,ptr %out0_2,align 1
 %word1_0 = trunc i140 %r1 to i64
 %out1_0 = getelementptr i8,ptr %out,i64 24
 store i64 %word1_0,ptr %out1_0,align 1
 %shift1_1 = lshr i140 %r1,64
 %word1_1 = trunc i140 %shift1_1 to i64
 %out1_1 = getelementptr i8,ptr %out,i64 32
 store i64 %word1_1,ptr %out1_1,align 1
 %shift1_2 = lshr i140 %r1,128
 %word1_2 = trunc i140 %shift1_2 to i64
 %out1_2 = getelementptr i8,ptr %out,i64 40
 store i64 %word1_2,ptr %out1_2,align 1
 %word2_0 = trunc i140 %r2 to i64
 %out2_0 = getelementptr i8,ptr %out,i64 48
 store i64 %word2_0,ptr %out2_0,align 1
 %shift2_1 = lshr i140 %r2,64
 %word2_1 = trunc i140 %shift2_1 to i64
 %out2_1 = getelementptr i8,ptr %out,i64 56
 store i64 %word2_1,ptr %out2_1,align 1
 %shift2_2 = lshr i140 %r2,128
 %word2_2 = trunc i140 %shift2_2 to i64
 %out2_2 = getelementptr i8,ptr %out,i64 64
 store i64 %word2_2,ptr %out2_2,align 1
 %word3_0 = trunc i140 %r3 to i64
 %out3_0 = getelementptr i8,ptr %out,i64 72
 store i64 %word3_0,ptr %out3_0,align 1
 %shift3_1 = lshr i140 %r3,64
 %word3_1 = trunc i140 %shift3_1 to i64
 %out3_1 = getelementptr i8,ptr %out,i64 80
 store i64 %word3_1,ptr %out3_1,align 1
 %shift3_2 = lshr i140 %r3,128
 %word3_2 = trunc i140 %shift3_2 to i64
 %out3_2 = getelementptr i8,ptr %out,i64 88
 store i64 %word3_2,ptr %out3_2,align 1
 %word4_0 = trunc i200 %r4 to i64
 %out4_0 = getelementptr i8,ptr %out,i64 96
 store i64 %word4_0,ptr %out4_0,align 1
 %shift4_1 = lshr i200 %r4,64
 %word4_1 = trunc i200 %shift4_1 to i64
 %out4_1 = getelementptr i8,ptr %out,i64 104
 store i64 %word4_1,ptr %out4_1,align 1
 %shift4_2 = lshr i200 %r4,128
 %word4_2 = trunc i200 %shift4_2 to i64
 %out4_2 = getelementptr i8,ptr %out,i64 112
 store i64 %word4_2,ptr %out4_2,align 1
 %shift4_3 = lshr i200 %r4,192
 %word4_3 = trunc i200 %shift4_3 to i64
 %out4_3 = getelementptr i8,ptr %out,i64 120
 store i64 %word4_3,ptr %out4_3,align 1
 %word5_0 = trunc i200 %r5 to i64
 %out5_0 = getelementptr i8,ptr %out,i64 128
 store i64 %word5_0,ptr %out5_0,align 1
 %shift5_1 = lshr i200 %r5,64
 %word5_1 = trunc i200 %shift5_1 to i64
 %out5_1 = getelementptr i8,ptr %out,i64 136
 store i64 %word5_1,ptr %out5_1,align 1
 %shift5_2 = lshr i200 %r5,128
 %word5_2 = trunc i200 %shift5_2 to i64
 %out5_2 = getelementptr i8,ptr %out,i64 144
 store i64 %word5_2,ptr %out5_2,align 1
 %shift5_3 = lshr i200 %r5,192
 %word5_3 = trunc i200 %shift5_3 to i64
 %out5_3 = getelementptr i8,ptr %out,i64 152
 store i64 %word5_3,ptr %out5_3,align 1
 %mp = getelementptr i8,ptr %out,i64 160
 store i64 %mask,ptr %mp,align 1
 %op = getelementptr i8,ptr %out,i64 168
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %mask,%token
 ret i64 %answer
}
define i64 @wide_saturation_vector_probe_9(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %temporary = alloca [160 x i8],align 16
 %constant = alloca i140,align 16
 store i140 1267650600228229401496703205376,ptr %constant,align 16
 %bp = getelementptr i8,ptr %input,i64 32
 %sp = getelementptr i8,ptr %input,i64 64
 %s0 = load i64,ptr %sp,align 1
 %tp = getelementptr i8,ptr %input,i64 72
 %t0 = load i64,ptr %tp,align 1
 %temporary0 = getelementptr i8,ptr %temporary,i64 0
 call void @wide_sat_140_u_0(ptr %temporary0,ptr %input,i64 %s0)
 %temporary1 = getelementptr i8,ptr %temporary,i64 24
 call void @wide_sat_140_s_0(ptr %temporary1,ptr %input,i64 %s0)
 %temporary2 = getelementptr i8,ptr %temporary,i64 48
 call void @wide_sat_140_u_0(ptr %temporary2,ptr %constant,i64 %s0)
 %temporary3 = getelementptr i8,ptr %temporary,i64 72
 call void @wide_sat_140_s_0(ptr %temporary3,ptr %constant,i64 %s0)
 %temporary4 = getelementptr i8,ptr %temporary,i64 96
 call void @wide_sat_200_u_0(ptr %temporary4,ptr %bp,i64 %t0)
 %temporary5 = getelementptr i8,ptr %temporary,i64 128
 call void @wide_sat_200_s_0(ptr %temporary5,ptr %bp,i64 %t0)
 %r0 = load i140,ptr %temporary0,align 1
 %r1 = load i140,ptr %temporary1,align 1
 %r2 = load i140,ptr %temporary2,align 1
 %r3 = load i140,ptr %temporary3,align 1
 %r4 = load i200,ptr %temporary4,align 1
 %r5 = load i200,ptr %temporary5,align 1
 %v0 = insertelement <4 x i140> poison,i140 %r0,i64 0
 %v1 = insertelement <4 x i140> %v0,i140 %r1,i64 1
 %v2 = insertelement <4 x i140> %v1,i140 %r2,i64 2
 %v3 = insertelement <4 x i140> %v2,i140 %r3,i64 3
 %w0 = insertelement <4 x i140> poison,i140 0,i32 0
 %w1 = insertelement <4 x i140> %w0,i140 -1,i32 1
 %w2 = insertelement <4 x i140> %w1,i140 696898287454081973172991196020261297061887,i32 2
 %w3 = insertelement <4 x i140> %w2,i140 -696898287454081973172991196020261297061888,i32 3
 %cmp = icmp ne <4 x i140> %v3,%w3
 %packed_mask = bitcast <4 x i1> %cmp to i4
 %mask = zext i4 %packed_mask to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %word0_0 = trunc i140 %r0 to i64
 %out0_0 = getelementptr i8,ptr %out,i64 0
 store i64 %word0_0,ptr %out0_0,align 1
 %shift0_1 = lshr i140 %r0,64
 %word0_1 = trunc i140 %shift0_1 to i64
 %out0_1 = getelementptr i8,ptr %out,i64 8
 store i64 %word0_1,ptr %out0_1,align 1
 %shift0_2 = lshr i140 %r0,128
 %word0_2 = trunc i140 %shift0_2 to i64
 %out0_2 = getelementptr i8,ptr %out,i64 16
 store i64 %word0_2,ptr %out0_2,align 1
 %word1_0 = trunc i140 %r1 to i64
 %out1_0 = getelementptr i8,ptr %out,i64 24
 store i64 %word1_0,ptr %out1_0,align 1
 %shift1_1 = lshr i140 %r1,64
 %word1_1 = trunc i140 %shift1_1 to i64
 %out1_1 = getelementptr i8,ptr %out,i64 32
 store i64 %word1_1,ptr %out1_1,align 1
 %shift1_2 = lshr i140 %r1,128
 %word1_2 = trunc i140 %shift1_2 to i64
 %out1_2 = getelementptr i8,ptr %out,i64 40
 store i64 %word1_2,ptr %out1_2,align 1
 %word2_0 = trunc i140 %r2 to i64
 %out2_0 = getelementptr i8,ptr %out,i64 48
 store i64 %word2_0,ptr %out2_0,align 1
 %shift2_1 = lshr i140 %r2,64
 %word2_1 = trunc i140 %shift2_1 to i64
 %out2_1 = getelementptr i8,ptr %out,i64 56
 store i64 %word2_1,ptr %out2_1,align 1
 %shift2_2 = lshr i140 %r2,128
 %word2_2 = trunc i140 %shift2_2 to i64
 %out2_2 = getelementptr i8,ptr %out,i64 64
 store i64 %word2_2,ptr %out2_2,align 1
 %word3_0 = trunc i140 %r3 to i64
 %out3_0 = getelementptr i8,ptr %out,i64 72
 store i64 %word3_0,ptr %out3_0,align 1
 %shift3_1 = lshr i140 %r3,64
 %word3_1 = trunc i140 %shift3_1 to i64
 %out3_1 = getelementptr i8,ptr %out,i64 80
 store i64 %word3_1,ptr %out3_1,align 1
 %shift3_2 = lshr i140 %r3,128
 %word3_2 = trunc i140 %shift3_2 to i64
 %out3_2 = getelementptr i8,ptr %out,i64 88
 store i64 %word3_2,ptr %out3_2,align 1
 %word4_0 = trunc i200 %r4 to i64
 %out4_0 = getelementptr i8,ptr %out,i64 96
 store i64 %word4_0,ptr %out4_0,align 1
 %shift4_1 = lshr i200 %r4,64
 %word4_1 = trunc i200 %shift4_1 to i64
 %out4_1 = getelementptr i8,ptr %out,i64 104
 store i64 %word4_1,ptr %out4_1,align 1
 %shift4_2 = lshr i200 %r4,128
 %word4_2 = trunc i200 %shift4_2 to i64
 %out4_2 = getelementptr i8,ptr %out,i64 112
 store i64 %word4_2,ptr %out4_2,align 1
 %shift4_3 = lshr i200 %r4,192
 %word4_3 = trunc i200 %shift4_3 to i64
 %out4_3 = getelementptr i8,ptr %out,i64 120
 store i64 %word4_3,ptr %out4_3,align 1
 %word5_0 = trunc i200 %r5 to i64
 %out5_0 = getelementptr i8,ptr %out,i64 128
 store i64 %word5_0,ptr %out5_0,align 1
 %shift5_1 = lshr i200 %r5,64
 %word5_1 = trunc i200 %shift5_1 to i64
 %out5_1 = getelementptr i8,ptr %out,i64 136
 store i64 %word5_1,ptr %out5_1,align 1
 %shift5_2 = lshr i200 %r5,128
 %word5_2 = trunc i200 %shift5_2 to i64
 %out5_2 = getelementptr i8,ptr %out,i64 144
 store i64 %word5_2,ptr %out5_2,align 1
 %shift5_3 = lshr i200 %r5,192
 %word5_3 = trunc i200 %shift5_3 to i64
 %out5_3 = getelementptr i8,ptr %out,i64 152
 store i64 %word5_3,ptr %out5_3,align 1
 %mp = getelementptr i8,ptr %out,i64 160
 store i64 %mask,ptr %mp,align 1
 %op = getelementptr i8,ptr %out,i64 168
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %mask,%token
 ret i64 %answer
}
define i64 @wide_saturation_vector_probe_10(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %temporary = alloca [160 x i8],align 16
 %constant = alloca i140,align 16
 store i140 1267650600228229401496703205376,ptr %constant,align 16
 %bp = getelementptr i8,ptr %input,i64 32
 %sp = getelementptr i8,ptr %input,i64 64
 %s0 = load i64,ptr %sp,align 1
 %tp = getelementptr i8,ptr %input,i64 72
 %t0 = load i64,ptr %tp,align 1
 %temporary0 = getelementptr i8,ptr %temporary,i64 0
 call void @wide_sat_140_u_1(ptr %temporary0,ptr %input,i64 %s0)
 %temporary1 = getelementptr i8,ptr %temporary,i64 24
 call void @wide_sat_140_s_1(ptr %temporary1,ptr %input,i64 %s0)
 %temporary2 = getelementptr i8,ptr %temporary,i64 48
 call void @wide_sat_140_u_1(ptr %temporary2,ptr %constant,i64 %s0)
 %temporary3 = getelementptr i8,ptr %temporary,i64 72
 call void @wide_sat_140_s_1(ptr %temporary3,ptr %constant,i64 %s0)
 %temporary4 = getelementptr i8,ptr %temporary,i64 96
 call void @wide_sat_200_u_1(ptr %temporary4,ptr %bp,i64 %t0)
 %temporary5 = getelementptr i8,ptr %temporary,i64 128
 call void @wide_sat_200_s_1(ptr %temporary5,ptr %bp,i64 %t0)
 %r0 = load i140,ptr %temporary0,align 1
 %r1 = load i140,ptr %temporary1,align 1
 %r2 = load i140,ptr %temporary2,align 1
 %r3 = load i140,ptr %temporary3,align 1
 %r4 = load i200,ptr %temporary4,align 1
 %r5 = load i200,ptr %temporary5,align 1
 %v0 = insertelement <4 x i140> poison,i140 %r0,i64 0
 %v1 = insertelement <4 x i140> %v0,i140 %r1,i64 1
 %v2 = insertelement <4 x i140> %v1,i140 %r2,i64 2
 %v3 = insertelement <4 x i140> %v2,i140 %r3,i64 3
 %w0 = insertelement <4 x i140> poison,i140 0,i32 0
 %w1 = insertelement <4 x i140> %w0,i140 -1,i32 1
 %w2 = insertelement <4 x i140> %w1,i140 696898287454081973172991196020261297061887,i32 2
 %w3 = insertelement <4 x i140> %w2,i140 -696898287454081973172991196020261297061888,i32 3
 %cmp = icmp ne <4 x i140> %v3,%w3
 %packed_mask = bitcast <4 x i1> %cmp to i4
 %mask = zext i4 %packed_mask to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %word0_0 = trunc i140 %r0 to i64
 %out0_0 = getelementptr i8,ptr %out,i64 0
 store i64 %word0_0,ptr %out0_0,align 1
 %shift0_1 = lshr i140 %r0,64
 %word0_1 = trunc i140 %shift0_1 to i64
 %out0_1 = getelementptr i8,ptr %out,i64 8
 store i64 %word0_1,ptr %out0_1,align 1
 %shift0_2 = lshr i140 %r0,128
 %word0_2 = trunc i140 %shift0_2 to i64
 %out0_2 = getelementptr i8,ptr %out,i64 16
 store i64 %word0_2,ptr %out0_2,align 1
 %word1_0 = trunc i140 %r1 to i64
 %out1_0 = getelementptr i8,ptr %out,i64 24
 store i64 %word1_0,ptr %out1_0,align 1
 %shift1_1 = lshr i140 %r1,64
 %word1_1 = trunc i140 %shift1_1 to i64
 %out1_1 = getelementptr i8,ptr %out,i64 32
 store i64 %word1_1,ptr %out1_1,align 1
 %shift1_2 = lshr i140 %r1,128
 %word1_2 = trunc i140 %shift1_2 to i64
 %out1_2 = getelementptr i8,ptr %out,i64 40
 store i64 %word1_2,ptr %out1_2,align 1
 %word2_0 = trunc i140 %r2 to i64
 %out2_0 = getelementptr i8,ptr %out,i64 48
 store i64 %word2_0,ptr %out2_0,align 1
 %shift2_1 = lshr i140 %r2,64
 %word2_1 = trunc i140 %shift2_1 to i64
 %out2_1 = getelementptr i8,ptr %out,i64 56
 store i64 %word2_1,ptr %out2_1,align 1
 %shift2_2 = lshr i140 %r2,128
 %word2_2 = trunc i140 %shift2_2 to i64
 %out2_2 = getelementptr i8,ptr %out,i64 64
 store i64 %word2_2,ptr %out2_2,align 1
 %word3_0 = trunc i140 %r3 to i64
 %out3_0 = getelementptr i8,ptr %out,i64 72
 store i64 %word3_0,ptr %out3_0,align 1
 %shift3_1 = lshr i140 %r3,64
 %word3_1 = trunc i140 %shift3_1 to i64
 %out3_1 = getelementptr i8,ptr %out,i64 80
 store i64 %word3_1,ptr %out3_1,align 1
 %shift3_2 = lshr i140 %r3,128
 %word3_2 = trunc i140 %shift3_2 to i64
 %out3_2 = getelementptr i8,ptr %out,i64 88
 store i64 %word3_2,ptr %out3_2,align 1
 %word4_0 = trunc i200 %r4 to i64
 %out4_0 = getelementptr i8,ptr %out,i64 96
 store i64 %word4_0,ptr %out4_0,align 1
 %shift4_1 = lshr i200 %r4,64
 %word4_1 = trunc i200 %shift4_1 to i64
 %out4_1 = getelementptr i8,ptr %out,i64 104
 store i64 %word4_1,ptr %out4_1,align 1
 %shift4_2 = lshr i200 %r4,128
 %word4_2 = trunc i200 %shift4_2 to i64
 %out4_2 = getelementptr i8,ptr %out,i64 112
 store i64 %word4_2,ptr %out4_2,align 1
 %shift4_3 = lshr i200 %r4,192
 %word4_3 = trunc i200 %shift4_3 to i64
 %out4_3 = getelementptr i8,ptr %out,i64 120
 store i64 %word4_3,ptr %out4_3,align 1
 %word5_0 = trunc i200 %r5 to i64
 %out5_0 = getelementptr i8,ptr %out,i64 128
 store i64 %word5_0,ptr %out5_0,align 1
 %shift5_1 = lshr i200 %r5,64
 %word5_1 = trunc i200 %shift5_1 to i64
 %out5_1 = getelementptr i8,ptr %out,i64 136
 store i64 %word5_1,ptr %out5_1,align 1
 %shift5_2 = lshr i200 %r5,128
 %word5_2 = trunc i200 %shift5_2 to i64
 %out5_2 = getelementptr i8,ptr %out,i64 144
 store i64 %word5_2,ptr %out5_2,align 1
 %shift5_3 = lshr i200 %r5,192
 %word5_3 = trunc i200 %shift5_3 to i64
 %out5_3 = getelementptr i8,ptr %out,i64 152
 store i64 %word5_3,ptr %out5_3,align 1
 %mp = getelementptr i8,ptr %out,i64 160
 store i64 %mask,ptr %mp,align 1
 %op = getelementptr i8,ptr %out,i64 168
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %mask,%token
 ret i64 %answer
}
define i64 @wide_saturation_vector_probe_11(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %temporary = alloca [160 x i8],align 16
 %constant = alloca i140,align 16
 store i140 1267650600228229401496703205376,ptr %constant,align 16
 %bp = getelementptr i8,ptr %input,i64 32
 %sp = getelementptr i8,ptr %input,i64 64
 %s0 = load i64,ptr %sp,align 1
 %tp = getelementptr i8,ptr %input,i64 72
 %t0 = load i64,ptr %tp,align 1
 %temporary0 = getelementptr i8,ptr %temporary,i64 0
 call void @wide_sat_140_u_2(ptr %temporary0,ptr %input,i64 %s0)
 %temporary1 = getelementptr i8,ptr %temporary,i64 24
 call void @wide_sat_140_s_2(ptr %temporary1,ptr %input,i64 %s0)
 %temporary2 = getelementptr i8,ptr %temporary,i64 48
 call void @wide_sat_140_u_2(ptr %temporary2,ptr %constant,i64 %s0)
 %temporary3 = getelementptr i8,ptr %temporary,i64 72
 call void @wide_sat_140_s_2(ptr %temporary3,ptr %constant,i64 %s0)
 %temporary4 = getelementptr i8,ptr %temporary,i64 96
 call void @wide_sat_200_u_2(ptr %temporary4,ptr %bp,i64 %t0)
 %temporary5 = getelementptr i8,ptr %temporary,i64 128
 call void @wide_sat_200_s_2(ptr %temporary5,ptr %bp,i64 %t0)
 %r0 = load i140,ptr %temporary0,align 1
 %r1 = load i140,ptr %temporary1,align 1
 %r2 = load i140,ptr %temporary2,align 1
 %r3 = load i140,ptr %temporary3,align 1
 %r4 = load i200,ptr %temporary4,align 1
 %r5 = load i200,ptr %temporary5,align 1
 %v0 = insertelement <4 x i140> poison,i140 %r0,i64 0
 %v1 = insertelement <4 x i140> %v0,i140 %r1,i64 1
 %v2 = insertelement <4 x i140> %v1,i140 %r2,i64 2
 %v3 = insertelement <4 x i140> %v2,i140 %r3,i64 3
 %w0 = insertelement <4 x i140> poison,i140 0,i32 0
 %w1 = insertelement <4 x i140> %w0,i140 -1,i32 1
 %w2 = insertelement <4 x i140> %w1,i140 696898287454081973172991196020261297061887,i32 2
 %w3 = insertelement <4 x i140> %w2,i140 -696898287454081973172991196020261297061888,i32 3
 %cmp = icmp ne <4 x i140> %v3,%w3
 %packed_mask = bitcast <4 x i1> %cmp to i4
 %mask = zext i4 %packed_mask to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %word0_0 = trunc i140 %r0 to i64
 %out0_0 = getelementptr i8,ptr %out,i64 0
 store i64 %word0_0,ptr %out0_0,align 1
 %shift0_1 = lshr i140 %r0,64
 %word0_1 = trunc i140 %shift0_1 to i64
 %out0_1 = getelementptr i8,ptr %out,i64 8
 store i64 %word0_1,ptr %out0_1,align 1
 %shift0_2 = lshr i140 %r0,128
 %word0_2 = trunc i140 %shift0_2 to i64
 %out0_2 = getelementptr i8,ptr %out,i64 16
 store i64 %word0_2,ptr %out0_2,align 1
 %word1_0 = trunc i140 %r1 to i64
 %out1_0 = getelementptr i8,ptr %out,i64 24
 store i64 %word1_0,ptr %out1_0,align 1
 %shift1_1 = lshr i140 %r1,64
 %word1_1 = trunc i140 %shift1_1 to i64
 %out1_1 = getelementptr i8,ptr %out,i64 32
 store i64 %word1_1,ptr %out1_1,align 1
 %shift1_2 = lshr i140 %r1,128
 %word1_2 = trunc i140 %shift1_2 to i64
 %out1_2 = getelementptr i8,ptr %out,i64 40
 store i64 %word1_2,ptr %out1_2,align 1
 %word2_0 = trunc i140 %r2 to i64
 %out2_0 = getelementptr i8,ptr %out,i64 48
 store i64 %word2_0,ptr %out2_0,align 1
 %shift2_1 = lshr i140 %r2,64
 %word2_1 = trunc i140 %shift2_1 to i64
 %out2_1 = getelementptr i8,ptr %out,i64 56
 store i64 %word2_1,ptr %out2_1,align 1
 %shift2_2 = lshr i140 %r2,128
 %word2_2 = trunc i140 %shift2_2 to i64
 %out2_2 = getelementptr i8,ptr %out,i64 64
 store i64 %word2_2,ptr %out2_2,align 1
 %word3_0 = trunc i140 %r3 to i64
 %out3_0 = getelementptr i8,ptr %out,i64 72
 store i64 %word3_0,ptr %out3_0,align 1
 %shift3_1 = lshr i140 %r3,64
 %word3_1 = trunc i140 %shift3_1 to i64
 %out3_1 = getelementptr i8,ptr %out,i64 80
 store i64 %word3_1,ptr %out3_1,align 1
 %shift3_2 = lshr i140 %r3,128
 %word3_2 = trunc i140 %shift3_2 to i64
 %out3_2 = getelementptr i8,ptr %out,i64 88
 store i64 %word3_2,ptr %out3_2,align 1
 %word4_0 = trunc i200 %r4 to i64
 %out4_0 = getelementptr i8,ptr %out,i64 96
 store i64 %word4_0,ptr %out4_0,align 1
 %shift4_1 = lshr i200 %r4,64
 %word4_1 = trunc i200 %shift4_1 to i64
 %out4_1 = getelementptr i8,ptr %out,i64 104
 store i64 %word4_1,ptr %out4_1,align 1
 %shift4_2 = lshr i200 %r4,128
 %word4_2 = trunc i200 %shift4_2 to i64
 %out4_2 = getelementptr i8,ptr %out,i64 112
 store i64 %word4_2,ptr %out4_2,align 1
 %shift4_3 = lshr i200 %r4,192
 %word4_3 = trunc i200 %shift4_3 to i64
 %out4_3 = getelementptr i8,ptr %out,i64 120
 store i64 %word4_3,ptr %out4_3,align 1
 %word5_0 = trunc i200 %r5 to i64
 %out5_0 = getelementptr i8,ptr %out,i64 128
 store i64 %word5_0,ptr %out5_0,align 1
 %shift5_1 = lshr i200 %r5,64
 %word5_1 = trunc i200 %shift5_1 to i64
 %out5_1 = getelementptr i8,ptr %out,i64 136
 store i64 %word5_1,ptr %out5_1,align 1
 %shift5_2 = lshr i200 %r5,128
 %word5_2 = trunc i200 %shift5_2 to i64
 %out5_2 = getelementptr i8,ptr %out,i64 144
 store i64 %word5_2,ptr %out5_2,align 1
 %shift5_3 = lshr i200 %r5,192
 %word5_3 = trunc i200 %shift5_3 to i64
 %out5_3 = getelementptr i8,ptr %out,i64 152
 store i64 %word5_3,ptr %out5_3,align 1
 %mp = getelementptr i8,ptr %out,i64 160
 store i64 %mask,ptr %mp,align 1
 %op = getelementptr i8,ptr %out,i64 168
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %mask,%token
 ret i64 %answer
}
define i64 @wide_saturation_vector_probe_12(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %temporary = alloca [160 x i8],align 16
 %constant = alloca i140,align 16
 store i140 1267650600228229401496703205376,ptr %constant,align 16
 %bp = getelementptr i8,ptr %input,i64 32
 %sp = getelementptr i8,ptr %input,i64 64
 %s0 = load i64,ptr %sp,align 1
 %tp = getelementptr i8,ptr %input,i64 72
 %t0 = load i64,ptr %tp,align 1
 %temporary0 = getelementptr i8,ptr %temporary,i64 0
 call void @wide_sat_140_u_0(ptr %temporary0,ptr %input,i64 %s0)
 %temporary1 = getelementptr i8,ptr %temporary,i64 24
 call void @wide_sat_140_s_0(ptr %temporary1,ptr %input,i64 %s0)
 %temporary2 = getelementptr i8,ptr %temporary,i64 48
 call void @wide_sat_140_u_0(ptr %temporary2,ptr %constant,i64 %s0)
 %temporary3 = getelementptr i8,ptr %temporary,i64 72
 call void @wide_sat_140_s_0(ptr %temporary3,ptr %constant,i64 %s0)
 %temporary4 = getelementptr i8,ptr %temporary,i64 96
 call void @wide_sat_200_u_0(ptr %temporary4,ptr %bp,i64 %t0)
 %temporary5 = getelementptr i8,ptr %temporary,i64 128
 call void @wide_sat_200_s_0(ptr %temporary5,ptr %bp,i64 %t0)
 %r0 = load i140,ptr %temporary0,align 1
 %r1 = load i140,ptr %temporary1,align 1
 %r2 = load i140,ptr %temporary2,align 1
 %r3 = load i140,ptr %temporary3,align 1
 %r4 = load i200,ptr %temporary4,align 1
 %r5 = load i200,ptr %temporary5,align 1
 %v0 = insertelement <4 x i140> poison,i140 %r0,i64 0
 %v1 = insertelement <4 x i140> %v0,i140 %r1,i64 1
 %v2 = insertelement <4 x i140> %v1,i140 %r2,i64 2
 %v3 = insertelement <4 x i140> %v2,i140 %r3,i64 3
 %cmp = icmp ugt <4 x i140> %v3,<i140 0,i140 -1,i140 696898287454081973172991196020261297061887,i140 -696898287454081973172991196020261297061888>
 %packed_mask = bitcast <4 x i1> %cmp to i4
 %mask = zext i4 %packed_mask to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %word0_0 = trunc i140 %r0 to i64
 %out0_0 = getelementptr i8,ptr %out,i64 0
 store i64 %word0_0,ptr %out0_0,align 1
 %shift0_1 = lshr i140 %r0,64
 %word0_1 = trunc i140 %shift0_1 to i64
 %out0_1 = getelementptr i8,ptr %out,i64 8
 store i64 %word0_1,ptr %out0_1,align 1
 %shift0_2 = lshr i140 %r0,128
 %word0_2 = trunc i140 %shift0_2 to i64
 %out0_2 = getelementptr i8,ptr %out,i64 16
 store i64 %word0_2,ptr %out0_2,align 1
 %word1_0 = trunc i140 %r1 to i64
 %out1_0 = getelementptr i8,ptr %out,i64 24
 store i64 %word1_0,ptr %out1_0,align 1
 %shift1_1 = lshr i140 %r1,64
 %word1_1 = trunc i140 %shift1_1 to i64
 %out1_1 = getelementptr i8,ptr %out,i64 32
 store i64 %word1_1,ptr %out1_1,align 1
 %shift1_2 = lshr i140 %r1,128
 %word1_2 = trunc i140 %shift1_2 to i64
 %out1_2 = getelementptr i8,ptr %out,i64 40
 store i64 %word1_2,ptr %out1_2,align 1
 %word2_0 = trunc i140 %r2 to i64
 %out2_0 = getelementptr i8,ptr %out,i64 48
 store i64 %word2_0,ptr %out2_0,align 1
 %shift2_1 = lshr i140 %r2,64
 %word2_1 = trunc i140 %shift2_1 to i64
 %out2_1 = getelementptr i8,ptr %out,i64 56
 store i64 %word2_1,ptr %out2_1,align 1
 %shift2_2 = lshr i140 %r2,128
 %word2_2 = trunc i140 %shift2_2 to i64
 %out2_2 = getelementptr i8,ptr %out,i64 64
 store i64 %word2_2,ptr %out2_2,align 1
 %word3_0 = trunc i140 %r3 to i64
 %out3_0 = getelementptr i8,ptr %out,i64 72
 store i64 %word3_0,ptr %out3_0,align 1
 %shift3_1 = lshr i140 %r3,64
 %word3_1 = trunc i140 %shift3_1 to i64
 %out3_1 = getelementptr i8,ptr %out,i64 80
 store i64 %word3_1,ptr %out3_1,align 1
 %shift3_2 = lshr i140 %r3,128
 %word3_2 = trunc i140 %shift3_2 to i64
 %out3_2 = getelementptr i8,ptr %out,i64 88
 store i64 %word3_2,ptr %out3_2,align 1
 %word4_0 = trunc i200 %r4 to i64
 %out4_0 = getelementptr i8,ptr %out,i64 96
 store i64 %word4_0,ptr %out4_0,align 1
 %shift4_1 = lshr i200 %r4,64
 %word4_1 = trunc i200 %shift4_1 to i64
 %out4_1 = getelementptr i8,ptr %out,i64 104
 store i64 %word4_1,ptr %out4_1,align 1
 %shift4_2 = lshr i200 %r4,128
 %word4_2 = trunc i200 %shift4_2 to i64
 %out4_2 = getelementptr i8,ptr %out,i64 112
 store i64 %word4_2,ptr %out4_2,align 1
 %shift4_3 = lshr i200 %r4,192
 %word4_3 = trunc i200 %shift4_3 to i64
 %out4_3 = getelementptr i8,ptr %out,i64 120
 store i64 %word4_3,ptr %out4_3,align 1
 %word5_0 = trunc i200 %r5 to i64
 %out5_0 = getelementptr i8,ptr %out,i64 128
 store i64 %word5_0,ptr %out5_0,align 1
 %shift5_1 = lshr i200 %r5,64
 %word5_1 = trunc i200 %shift5_1 to i64
 %out5_1 = getelementptr i8,ptr %out,i64 136
 store i64 %word5_1,ptr %out5_1,align 1
 %shift5_2 = lshr i200 %r5,128
 %word5_2 = trunc i200 %shift5_2 to i64
 %out5_2 = getelementptr i8,ptr %out,i64 144
 store i64 %word5_2,ptr %out5_2,align 1
 %shift5_3 = lshr i200 %r5,192
 %word5_3 = trunc i200 %shift5_3 to i64
 %out5_3 = getelementptr i8,ptr %out,i64 152
 store i64 %word5_3,ptr %out5_3,align 1
 %mp = getelementptr i8,ptr %out,i64 160
 store i64 %mask,ptr %mp,align 1
 %op = getelementptr i8,ptr %out,i64 168
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %mask,%token
 ret i64 %answer
}
define i64 @wide_saturation_vector_probe_13(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %temporary = alloca [160 x i8],align 16
 %constant = alloca i140,align 16
 store i140 1267650600228229401496703205376,ptr %constant,align 16
 %bp = getelementptr i8,ptr %input,i64 32
 %sp = getelementptr i8,ptr %input,i64 64
 %s0 = load i64,ptr %sp,align 1
 %tp = getelementptr i8,ptr %input,i64 72
 %t0 = load i64,ptr %tp,align 1
 %temporary0 = getelementptr i8,ptr %temporary,i64 0
 call void @wide_sat_140_u_1(ptr %temporary0,ptr %input,i64 %s0)
 %temporary1 = getelementptr i8,ptr %temporary,i64 24
 call void @wide_sat_140_s_1(ptr %temporary1,ptr %input,i64 %s0)
 %temporary2 = getelementptr i8,ptr %temporary,i64 48
 call void @wide_sat_140_u_1(ptr %temporary2,ptr %constant,i64 %s0)
 %temporary3 = getelementptr i8,ptr %temporary,i64 72
 call void @wide_sat_140_s_1(ptr %temporary3,ptr %constant,i64 %s0)
 %temporary4 = getelementptr i8,ptr %temporary,i64 96
 call void @wide_sat_200_u_1(ptr %temporary4,ptr %bp,i64 %t0)
 %temporary5 = getelementptr i8,ptr %temporary,i64 128
 call void @wide_sat_200_s_1(ptr %temporary5,ptr %bp,i64 %t0)
 %r0 = load i140,ptr %temporary0,align 1
 %r1 = load i140,ptr %temporary1,align 1
 %r2 = load i140,ptr %temporary2,align 1
 %r3 = load i140,ptr %temporary3,align 1
 %r4 = load i200,ptr %temporary4,align 1
 %r5 = load i200,ptr %temporary5,align 1
 %v0 = insertelement <4 x i140> poison,i140 %r0,i64 0
 %v1 = insertelement <4 x i140> %v0,i140 %r1,i64 1
 %v2 = insertelement <4 x i140> %v1,i140 %r2,i64 2
 %v3 = insertelement <4 x i140> %v2,i140 %r3,i64 3
 %cmp = icmp ugt <4 x i140> %v3,<i140 0,i140 -1,i140 696898287454081973172991196020261297061887,i140 -696898287454081973172991196020261297061888>
 %packed_mask = bitcast <4 x i1> %cmp to i4
 %mask = zext i4 %packed_mask to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %word0_0 = trunc i140 %r0 to i64
 %out0_0 = getelementptr i8,ptr %out,i64 0
 store i64 %word0_0,ptr %out0_0,align 1
 %shift0_1 = lshr i140 %r0,64
 %word0_1 = trunc i140 %shift0_1 to i64
 %out0_1 = getelementptr i8,ptr %out,i64 8
 store i64 %word0_1,ptr %out0_1,align 1
 %shift0_2 = lshr i140 %r0,128
 %word0_2 = trunc i140 %shift0_2 to i64
 %out0_2 = getelementptr i8,ptr %out,i64 16
 store i64 %word0_2,ptr %out0_2,align 1
 %word1_0 = trunc i140 %r1 to i64
 %out1_0 = getelementptr i8,ptr %out,i64 24
 store i64 %word1_0,ptr %out1_0,align 1
 %shift1_1 = lshr i140 %r1,64
 %word1_1 = trunc i140 %shift1_1 to i64
 %out1_1 = getelementptr i8,ptr %out,i64 32
 store i64 %word1_1,ptr %out1_1,align 1
 %shift1_2 = lshr i140 %r1,128
 %word1_2 = trunc i140 %shift1_2 to i64
 %out1_2 = getelementptr i8,ptr %out,i64 40
 store i64 %word1_2,ptr %out1_2,align 1
 %word2_0 = trunc i140 %r2 to i64
 %out2_0 = getelementptr i8,ptr %out,i64 48
 store i64 %word2_0,ptr %out2_0,align 1
 %shift2_1 = lshr i140 %r2,64
 %word2_1 = trunc i140 %shift2_1 to i64
 %out2_1 = getelementptr i8,ptr %out,i64 56
 store i64 %word2_1,ptr %out2_1,align 1
 %shift2_2 = lshr i140 %r2,128
 %word2_2 = trunc i140 %shift2_2 to i64
 %out2_2 = getelementptr i8,ptr %out,i64 64
 store i64 %word2_2,ptr %out2_2,align 1
 %word3_0 = trunc i140 %r3 to i64
 %out3_0 = getelementptr i8,ptr %out,i64 72
 store i64 %word3_0,ptr %out3_0,align 1
 %shift3_1 = lshr i140 %r3,64
 %word3_1 = trunc i140 %shift3_1 to i64
 %out3_1 = getelementptr i8,ptr %out,i64 80
 store i64 %word3_1,ptr %out3_1,align 1
 %shift3_2 = lshr i140 %r3,128
 %word3_2 = trunc i140 %shift3_2 to i64
 %out3_2 = getelementptr i8,ptr %out,i64 88
 store i64 %word3_2,ptr %out3_2,align 1
 %word4_0 = trunc i200 %r4 to i64
 %out4_0 = getelementptr i8,ptr %out,i64 96
 store i64 %word4_0,ptr %out4_0,align 1
 %shift4_1 = lshr i200 %r4,64
 %word4_1 = trunc i200 %shift4_1 to i64
 %out4_1 = getelementptr i8,ptr %out,i64 104
 store i64 %word4_1,ptr %out4_1,align 1
 %shift4_2 = lshr i200 %r4,128
 %word4_2 = trunc i200 %shift4_2 to i64
 %out4_2 = getelementptr i8,ptr %out,i64 112
 store i64 %word4_2,ptr %out4_2,align 1
 %shift4_3 = lshr i200 %r4,192
 %word4_3 = trunc i200 %shift4_3 to i64
 %out4_3 = getelementptr i8,ptr %out,i64 120
 store i64 %word4_3,ptr %out4_3,align 1
 %word5_0 = trunc i200 %r5 to i64
 %out5_0 = getelementptr i8,ptr %out,i64 128
 store i64 %word5_0,ptr %out5_0,align 1
 %shift5_1 = lshr i200 %r5,64
 %word5_1 = trunc i200 %shift5_1 to i64
 %out5_1 = getelementptr i8,ptr %out,i64 136
 store i64 %word5_1,ptr %out5_1,align 1
 %shift5_2 = lshr i200 %r5,128
 %word5_2 = trunc i200 %shift5_2 to i64
 %out5_2 = getelementptr i8,ptr %out,i64 144
 store i64 %word5_2,ptr %out5_2,align 1
 %shift5_3 = lshr i200 %r5,192
 %word5_3 = trunc i200 %shift5_3 to i64
 %out5_3 = getelementptr i8,ptr %out,i64 152
 store i64 %word5_3,ptr %out5_3,align 1
 %mp = getelementptr i8,ptr %out,i64 160
 store i64 %mask,ptr %mp,align 1
 %op = getelementptr i8,ptr %out,i64 168
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %mask,%token
 ret i64 %answer
}
define i64 @wide_saturation_vector_probe_14(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %temporary = alloca [160 x i8],align 16
 %constant = alloca i140,align 16
 store i140 1267650600228229401496703205376,ptr %constant,align 16
 %bp = getelementptr i8,ptr %input,i64 32
 %sp = getelementptr i8,ptr %input,i64 64
 %s0 = load i64,ptr %sp,align 1
 %tp = getelementptr i8,ptr %input,i64 72
 %t0 = load i64,ptr %tp,align 1
 %temporary0 = getelementptr i8,ptr %temporary,i64 0
 call void @wide_sat_140_u_2(ptr %temporary0,ptr %input,i64 %s0)
 %temporary1 = getelementptr i8,ptr %temporary,i64 24
 call void @wide_sat_140_s_2(ptr %temporary1,ptr %input,i64 %s0)
 %temporary2 = getelementptr i8,ptr %temporary,i64 48
 call void @wide_sat_140_u_2(ptr %temporary2,ptr %constant,i64 %s0)
 %temporary3 = getelementptr i8,ptr %temporary,i64 72
 call void @wide_sat_140_s_2(ptr %temporary3,ptr %constant,i64 %s0)
 %temporary4 = getelementptr i8,ptr %temporary,i64 96
 call void @wide_sat_200_u_2(ptr %temporary4,ptr %bp,i64 %t0)
 %temporary5 = getelementptr i8,ptr %temporary,i64 128
 call void @wide_sat_200_s_2(ptr %temporary5,ptr %bp,i64 %t0)
 %r0 = load i140,ptr %temporary0,align 1
 %r1 = load i140,ptr %temporary1,align 1
 %r2 = load i140,ptr %temporary2,align 1
 %r3 = load i140,ptr %temporary3,align 1
 %r4 = load i200,ptr %temporary4,align 1
 %r5 = load i200,ptr %temporary5,align 1
 %v0 = insertelement <4 x i140> poison,i140 %r0,i64 0
 %v1 = insertelement <4 x i140> %v0,i140 %r1,i64 1
 %v2 = insertelement <4 x i140> %v1,i140 %r2,i64 2
 %v3 = insertelement <4 x i140> %v2,i140 %r3,i64 3
 %cmp = icmp ugt <4 x i140> %v3,<i140 0,i140 -1,i140 696898287454081973172991196020261297061887,i140 -696898287454081973172991196020261297061888>
 %packed_mask = bitcast <4 x i1> %cmp to i4
 %mask = zext i4 %packed_mask to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %word0_0 = trunc i140 %r0 to i64
 %out0_0 = getelementptr i8,ptr %out,i64 0
 store i64 %word0_0,ptr %out0_0,align 1
 %shift0_1 = lshr i140 %r0,64
 %word0_1 = trunc i140 %shift0_1 to i64
 %out0_1 = getelementptr i8,ptr %out,i64 8
 store i64 %word0_1,ptr %out0_1,align 1
 %shift0_2 = lshr i140 %r0,128
 %word0_2 = trunc i140 %shift0_2 to i64
 %out0_2 = getelementptr i8,ptr %out,i64 16
 store i64 %word0_2,ptr %out0_2,align 1
 %word1_0 = trunc i140 %r1 to i64
 %out1_0 = getelementptr i8,ptr %out,i64 24
 store i64 %word1_0,ptr %out1_0,align 1
 %shift1_1 = lshr i140 %r1,64
 %word1_1 = trunc i140 %shift1_1 to i64
 %out1_1 = getelementptr i8,ptr %out,i64 32
 store i64 %word1_1,ptr %out1_1,align 1
 %shift1_2 = lshr i140 %r1,128
 %word1_2 = trunc i140 %shift1_2 to i64
 %out1_2 = getelementptr i8,ptr %out,i64 40
 store i64 %word1_2,ptr %out1_2,align 1
 %word2_0 = trunc i140 %r2 to i64
 %out2_0 = getelementptr i8,ptr %out,i64 48
 store i64 %word2_0,ptr %out2_0,align 1
 %shift2_1 = lshr i140 %r2,64
 %word2_1 = trunc i140 %shift2_1 to i64
 %out2_1 = getelementptr i8,ptr %out,i64 56
 store i64 %word2_1,ptr %out2_1,align 1
 %shift2_2 = lshr i140 %r2,128
 %word2_2 = trunc i140 %shift2_2 to i64
 %out2_2 = getelementptr i8,ptr %out,i64 64
 store i64 %word2_2,ptr %out2_2,align 1
 %word3_0 = trunc i140 %r3 to i64
 %out3_0 = getelementptr i8,ptr %out,i64 72
 store i64 %word3_0,ptr %out3_0,align 1
 %shift3_1 = lshr i140 %r3,64
 %word3_1 = trunc i140 %shift3_1 to i64
 %out3_1 = getelementptr i8,ptr %out,i64 80
 store i64 %word3_1,ptr %out3_1,align 1
 %shift3_2 = lshr i140 %r3,128
 %word3_2 = trunc i140 %shift3_2 to i64
 %out3_2 = getelementptr i8,ptr %out,i64 88
 store i64 %word3_2,ptr %out3_2,align 1
 %word4_0 = trunc i200 %r4 to i64
 %out4_0 = getelementptr i8,ptr %out,i64 96
 store i64 %word4_0,ptr %out4_0,align 1
 %shift4_1 = lshr i200 %r4,64
 %word4_1 = trunc i200 %shift4_1 to i64
 %out4_1 = getelementptr i8,ptr %out,i64 104
 store i64 %word4_1,ptr %out4_1,align 1
 %shift4_2 = lshr i200 %r4,128
 %word4_2 = trunc i200 %shift4_2 to i64
 %out4_2 = getelementptr i8,ptr %out,i64 112
 store i64 %word4_2,ptr %out4_2,align 1
 %shift4_3 = lshr i200 %r4,192
 %word4_3 = trunc i200 %shift4_3 to i64
 %out4_3 = getelementptr i8,ptr %out,i64 120
 store i64 %word4_3,ptr %out4_3,align 1
 %word5_0 = trunc i200 %r5 to i64
 %out5_0 = getelementptr i8,ptr %out,i64 128
 store i64 %word5_0,ptr %out5_0,align 1
 %shift5_1 = lshr i200 %r5,64
 %word5_1 = trunc i200 %shift5_1 to i64
 %out5_1 = getelementptr i8,ptr %out,i64 136
 store i64 %word5_1,ptr %out5_1,align 1
 %shift5_2 = lshr i200 %r5,128
 %word5_2 = trunc i200 %shift5_2 to i64
 %out5_2 = getelementptr i8,ptr %out,i64 144
 store i64 %word5_2,ptr %out5_2,align 1
 %shift5_3 = lshr i200 %r5,192
 %word5_3 = trunc i200 %shift5_3 to i64
 %out5_3 = getelementptr i8,ptr %out,i64 152
 store i64 %word5_3,ptr %out5_3,align 1
 %mp = getelementptr i8,ptr %out,i64 160
 store i64 %mask,ptr %mp,align 1
 %op = getelementptr i8,ptr %out,i64 168
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %mask,%token
 ret i64 %answer
}
define i64 @wide_saturation_vector_probe_15(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %temporary = alloca [160 x i8],align 16
 %constant = alloca i140,align 16
 store i140 1267650600228229401496703205376,ptr %constant,align 16
 %bp = getelementptr i8,ptr %input,i64 32
 %sp = getelementptr i8,ptr %input,i64 64
 %s0 = load i64,ptr %sp,align 1
 %tp = getelementptr i8,ptr %input,i64 72
 %t0 = load i64,ptr %tp,align 1
 %temporary0 = getelementptr i8,ptr %temporary,i64 0
 call void @wide_sat_140_u_0(ptr %temporary0,ptr %input,i64 %s0)
 %temporary1 = getelementptr i8,ptr %temporary,i64 24
 call void @wide_sat_140_s_0(ptr %temporary1,ptr %input,i64 %s0)
 %temporary2 = getelementptr i8,ptr %temporary,i64 48
 call void @wide_sat_140_u_0(ptr %temporary2,ptr %constant,i64 %s0)
 %temporary3 = getelementptr i8,ptr %temporary,i64 72
 call void @wide_sat_140_s_0(ptr %temporary3,ptr %constant,i64 %s0)
 %temporary4 = getelementptr i8,ptr %temporary,i64 96
 call void @wide_sat_200_u_0(ptr %temporary4,ptr %bp,i64 %t0)
 %temporary5 = getelementptr i8,ptr %temporary,i64 128
 call void @wide_sat_200_s_0(ptr %temporary5,ptr %bp,i64 %t0)
 %r0 = load i140,ptr %temporary0,align 1
 %r1 = load i140,ptr %temporary1,align 1
 %r2 = load i140,ptr %temporary2,align 1
 %r3 = load i140,ptr %temporary3,align 1
 %r4 = load i200,ptr %temporary4,align 1
 %r5 = load i200,ptr %temporary5,align 1
 %v0 = insertelement <4 x i140> poison,i140 %r0,i64 0
 %v1 = insertelement <4 x i140> %v0,i140 %r1,i64 1
 %v2 = insertelement <4 x i140> %v1,i140 %r2,i64 2
 %v3 = insertelement <4 x i140> %v2,i140 %r3,i64 3
 %w0 = insertelement <4 x i140> poison,i140 0,i32 0
 %w1 = insertelement <4 x i140> %w0,i140 -1,i32 1
 %w2 = insertelement <4 x i140> %w1,i140 696898287454081973172991196020261297061887,i32 2
 %w3 = insertelement <4 x i140> %w2,i140 -696898287454081973172991196020261297061888,i32 3
 %cmp = icmp ugt <4 x i140> %v3,%w3
 %packed_mask = bitcast <4 x i1> %cmp to i4
 %mask = zext i4 %packed_mask to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %word0_0 = trunc i140 %r0 to i64
 %out0_0 = getelementptr i8,ptr %out,i64 0
 store i64 %word0_0,ptr %out0_0,align 1
 %shift0_1 = lshr i140 %r0,64
 %word0_1 = trunc i140 %shift0_1 to i64
 %out0_1 = getelementptr i8,ptr %out,i64 8
 store i64 %word0_1,ptr %out0_1,align 1
 %shift0_2 = lshr i140 %r0,128
 %word0_2 = trunc i140 %shift0_2 to i64
 %out0_2 = getelementptr i8,ptr %out,i64 16
 store i64 %word0_2,ptr %out0_2,align 1
 %word1_0 = trunc i140 %r1 to i64
 %out1_0 = getelementptr i8,ptr %out,i64 24
 store i64 %word1_0,ptr %out1_0,align 1
 %shift1_1 = lshr i140 %r1,64
 %word1_1 = trunc i140 %shift1_1 to i64
 %out1_1 = getelementptr i8,ptr %out,i64 32
 store i64 %word1_1,ptr %out1_1,align 1
 %shift1_2 = lshr i140 %r1,128
 %word1_2 = trunc i140 %shift1_2 to i64
 %out1_2 = getelementptr i8,ptr %out,i64 40
 store i64 %word1_2,ptr %out1_2,align 1
 %word2_0 = trunc i140 %r2 to i64
 %out2_0 = getelementptr i8,ptr %out,i64 48
 store i64 %word2_0,ptr %out2_0,align 1
 %shift2_1 = lshr i140 %r2,64
 %word2_1 = trunc i140 %shift2_1 to i64
 %out2_1 = getelementptr i8,ptr %out,i64 56
 store i64 %word2_1,ptr %out2_1,align 1
 %shift2_2 = lshr i140 %r2,128
 %word2_2 = trunc i140 %shift2_2 to i64
 %out2_2 = getelementptr i8,ptr %out,i64 64
 store i64 %word2_2,ptr %out2_2,align 1
 %word3_0 = trunc i140 %r3 to i64
 %out3_0 = getelementptr i8,ptr %out,i64 72
 store i64 %word3_0,ptr %out3_0,align 1
 %shift3_1 = lshr i140 %r3,64
 %word3_1 = trunc i140 %shift3_1 to i64
 %out3_1 = getelementptr i8,ptr %out,i64 80
 store i64 %word3_1,ptr %out3_1,align 1
 %shift3_2 = lshr i140 %r3,128
 %word3_2 = trunc i140 %shift3_2 to i64
 %out3_2 = getelementptr i8,ptr %out,i64 88
 store i64 %word3_2,ptr %out3_2,align 1
 %word4_0 = trunc i200 %r4 to i64
 %out4_0 = getelementptr i8,ptr %out,i64 96
 store i64 %word4_0,ptr %out4_0,align 1
 %shift4_1 = lshr i200 %r4,64
 %word4_1 = trunc i200 %shift4_1 to i64
 %out4_1 = getelementptr i8,ptr %out,i64 104
 store i64 %word4_1,ptr %out4_1,align 1
 %shift4_2 = lshr i200 %r4,128
 %word4_2 = trunc i200 %shift4_2 to i64
 %out4_2 = getelementptr i8,ptr %out,i64 112
 store i64 %word4_2,ptr %out4_2,align 1
 %shift4_3 = lshr i200 %r4,192
 %word4_3 = trunc i200 %shift4_3 to i64
 %out4_3 = getelementptr i8,ptr %out,i64 120
 store i64 %word4_3,ptr %out4_3,align 1
 %word5_0 = trunc i200 %r5 to i64
 %out5_0 = getelementptr i8,ptr %out,i64 128
 store i64 %word5_0,ptr %out5_0,align 1
 %shift5_1 = lshr i200 %r5,64
 %word5_1 = trunc i200 %shift5_1 to i64
 %out5_1 = getelementptr i8,ptr %out,i64 136
 store i64 %word5_1,ptr %out5_1,align 1
 %shift5_2 = lshr i200 %r5,128
 %word5_2 = trunc i200 %shift5_2 to i64
 %out5_2 = getelementptr i8,ptr %out,i64 144
 store i64 %word5_2,ptr %out5_2,align 1
 %shift5_3 = lshr i200 %r5,192
 %word5_3 = trunc i200 %shift5_3 to i64
 %out5_3 = getelementptr i8,ptr %out,i64 152
 store i64 %word5_3,ptr %out5_3,align 1
 %mp = getelementptr i8,ptr %out,i64 160
 store i64 %mask,ptr %mp,align 1
 %op = getelementptr i8,ptr %out,i64 168
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %mask,%token
 ret i64 %answer
}
define i64 @wide_saturation_vector_probe_16(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %temporary = alloca [160 x i8],align 16
 %constant = alloca i140,align 16
 store i140 1267650600228229401496703205376,ptr %constant,align 16
 %bp = getelementptr i8,ptr %input,i64 32
 %sp = getelementptr i8,ptr %input,i64 64
 %s0 = load i64,ptr %sp,align 1
 %tp = getelementptr i8,ptr %input,i64 72
 %t0 = load i64,ptr %tp,align 1
 %temporary0 = getelementptr i8,ptr %temporary,i64 0
 call void @wide_sat_140_u_1(ptr %temporary0,ptr %input,i64 %s0)
 %temporary1 = getelementptr i8,ptr %temporary,i64 24
 call void @wide_sat_140_s_1(ptr %temporary1,ptr %input,i64 %s0)
 %temporary2 = getelementptr i8,ptr %temporary,i64 48
 call void @wide_sat_140_u_1(ptr %temporary2,ptr %constant,i64 %s0)
 %temporary3 = getelementptr i8,ptr %temporary,i64 72
 call void @wide_sat_140_s_1(ptr %temporary3,ptr %constant,i64 %s0)
 %temporary4 = getelementptr i8,ptr %temporary,i64 96
 call void @wide_sat_200_u_1(ptr %temporary4,ptr %bp,i64 %t0)
 %temporary5 = getelementptr i8,ptr %temporary,i64 128
 call void @wide_sat_200_s_1(ptr %temporary5,ptr %bp,i64 %t0)
 %r0 = load i140,ptr %temporary0,align 1
 %r1 = load i140,ptr %temporary1,align 1
 %r2 = load i140,ptr %temporary2,align 1
 %r3 = load i140,ptr %temporary3,align 1
 %r4 = load i200,ptr %temporary4,align 1
 %r5 = load i200,ptr %temporary5,align 1
 %v0 = insertelement <4 x i140> poison,i140 %r0,i64 0
 %v1 = insertelement <4 x i140> %v0,i140 %r1,i64 1
 %v2 = insertelement <4 x i140> %v1,i140 %r2,i64 2
 %v3 = insertelement <4 x i140> %v2,i140 %r3,i64 3
 %w0 = insertelement <4 x i140> poison,i140 0,i32 0
 %w1 = insertelement <4 x i140> %w0,i140 -1,i32 1
 %w2 = insertelement <4 x i140> %w1,i140 696898287454081973172991196020261297061887,i32 2
 %w3 = insertelement <4 x i140> %w2,i140 -696898287454081973172991196020261297061888,i32 3
 %cmp = icmp ugt <4 x i140> %v3,%w3
 %packed_mask = bitcast <4 x i1> %cmp to i4
 %mask = zext i4 %packed_mask to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %word0_0 = trunc i140 %r0 to i64
 %out0_0 = getelementptr i8,ptr %out,i64 0
 store i64 %word0_0,ptr %out0_0,align 1
 %shift0_1 = lshr i140 %r0,64
 %word0_1 = trunc i140 %shift0_1 to i64
 %out0_1 = getelementptr i8,ptr %out,i64 8
 store i64 %word0_1,ptr %out0_1,align 1
 %shift0_2 = lshr i140 %r0,128
 %word0_2 = trunc i140 %shift0_2 to i64
 %out0_2 = getelementptr i8,ptr %out,i64 16
 store i64 %word0_2,ptr %out0_2,align 1
 %word1_0 = trunc i140 %r1 to i64
 %out1_0 = getelementptr i8,ptr %out,i64 24
 store i64 %word1_0,ptr %out1_0,align 1
 %shift1_1 = lshr i140 %r1,64
 %word1_1 = trunc i140 %shift1_1 to i64
 %out1_1 = getelementptr i8,ptr %out,i64 32
 store i64 %word1_1,ptr %out1_1,align 1
 %shift1_2 = lshr i140 %r1,128
 %word1_2 = trunc i140 %shift1_2 to i64
 %out1_2 = getelementptr i8,ptr %out,i64 40
 store i64 %word1_2,ptr %out1_2,align 1
 %word2_0 = trunc i140 %r2 to i64
 %out2_0 = getelementptr i8,ptr %out,i64 48
 store i64 %word2_0,ptr %out2_0,align 1
 %shift2_1 = lshr i140 %r2,64
 %word2_1 = trunc i140 %shift2_1 to i64
 %out2_1 = getelementptr i8,ptr %out,i64 56
 store i64 %word2_1,ptr %out2_1,align 1
 %shift2_2 = lshr i140 %r2,128
 %word2_2 = trunc i140 %shift2_2 to i64
 %out2_2 = getelementptr i8,ptr %out,i64 64
 store i64 %word2_2,ptr %out2_2,align 1
 %word3_0 = trunc i140 %r3 to i64
 %out3_0 = getelementptr i8,ptr %out,i64 72
 store i64 %word3_0,ptr %out3_0,align 1
 %shift3_1 = lshr i140 %r3,64
 %word3_1 = trunc i140 %shift3_1 to i64
 %out3_1 = getelementptr i8,ptr %out,i64 80
 store i64 %word3_1,ptr %out3_1,align 1
 %shift3_2 = lshr i140 %r3,128
 %word3_2 = trunc i140 %shift3_2 to i64
 %out3_2 = getelementptr i8,ptr %out,i64 88
 store i64 %word3_2,ptr %out3_2,align 1
 %word4_0 = trunc i200 %r4 to i64
 %out4_0 = getelementptr i8,ptr %out,i64 96
 store i64 %word4_0,ptr %out4_0,align 1
 %shift4_1 = lshr i200 %r4,64
 %word4_1 = trunc i200 %shift4_1 to i64
 %out4_1 = getelementptr i8,ptr %out,i64 104
 store i64 %word4_1,ptr %out4_1,align 1
 %shift4_2 = lshr i200 %r4,128
 %word4_2 = trunc i200 %shift4_2 to i64
 %out4_2 = getelementptr i8,ptr %out,i64 112
 store i64 %word4_2,ptr %out4_2,align 1
 %shift4_3 = lshr i200 %r4,192
 %word4_3 = trunc i200 %shift4_3 to i64
 %out4_3 = getelementptr i8,ptr %out,i64 120
 store i64 %word4_3,ptr %out4_3,align 1
 %word5_0 = trunc i200 %r5 to i64
 %out5_0 = getelementptr i8,ptr %out,i64 128
 store i64 %word5_0,ptr %out5_0,align 1
 %shift5_1 = lshr i200 %r5,64
 %word5_1 = trunc i200 %shift5_1 to i64
 %out5_1 = getelementptr i8,ptr %out,i64 136
 store i64 %word5_1,ptr %out5_1,align 1
 %shift5_2 = lshr i200 %r5,128
 %word5_2 = trunc i200 %shift5_2 to i64
 %out5_2 = getelementptr i8,ptr %out,i64 144
 store i64 %word5_2,ptr %out5_2,align 1
 %shift5_3 = lshr i200 %r5,192
 %word5_3 = trunc i200 %shift5_3 to i64
 %out5_3 = getelementptr i8,ptr %out,i64 152
 store i64 %word5_3,ptr %out5_3,align 1
 %mp = getelementptr i8,ptr %out,i64 160
 store i64 %mask,ptr %mp,align 1
 %op = getelementptr i8,ptr %out,i64 168
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %mask,%token
 ret i64 %answer
}
define i64 @wide_saturation_vector_probe_17(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %temporary = alloca [160 x i8],align 16
 %constant = alloca i140,align 16
 store i140 1267650600228229401496703205376,ptr %constant,align 16
 %bp = getelementptr i8,ptr %input,i64 32
 %sp = getelementptr i8,ptr %input,i64 64
 %s0 = load i64,ptr %sp,align 1
 %tp = getelementptr i8,ptr %input,i64 72
 %t0 = load i64,ptr %tp,align 1
 %temporary0 = getelementptr i8,ptr %temporary,i64 0
 call void @wide_sat_140_u_2(ptr %temporary0,ptr %input,i64 %s0)
 %temporary1 = getelementptr i8,ptr %temporary,i64 24
 call void @wide_sat_140_s_2(ptr %temporary1,ptr %input,i64 %s0)
 %temporary2 = getelementptr i8,ptr %temporary,i64 48
 call void @wide_sat_140_u_2(ptr %temporary2,ptr %constant,i64 %s0)
 %temporary3 = getelementptr i8,ptr %temporary,i64 72
 call void @wide_sat_140_s_2(ptr %temporary3,ptr %constant,i64 %s0)
 %temporary4 = getelementptr i8,ptr %temporary,i64 96
 call void @wide_sat_200_u_2(ptr %temporary4,ptr %bp,i64 %t0)
 %temporary5 = getelementptr i8,ptr %temporary,i64 128
 call void @wide_sat_200_s_2(ptr %temporary5,ptr %bp,i64 %t0)
 %r0 = load i140,ptr %temporary0,align 1
 %r1 = load i140,ptr %temporary1,align 1
 %r2 = load i140,ptr %temporary2,align 1
 %r3 = load i140,ptr %temporary3,align 1
 %r4 = load i200,ptr %temporary4,align 1
 %r5 = load i200,ptr %temporary5,align 1
 %v0 = insertelement <4 x i140> poison,i140 %r0,i64 0
 %v1 = insertelement <4 x i140> %v0,i140 %r1,i64 1
 %v2 = insertelement <4 x i140> %v1,i140 %r2,i64 2
 %v3 = insertelement <4 x i140> %v2,i140 %r3,i64 3
 %w0 = insertelement <4 x i140> poison,i140 0,i32 0
 %w1 = insertelement <4 x i140> %w0,i140 -1,i32 1
 %w2 = insertelement <4 x i140> %w1,i140 696898287454081973172991196020261297061887,i32 2
 %w3 = insertelement <4 x i140> %w2,i140 -696898287454081973172991196020261297061888,i32 3
 %cmp = icmp ugt <4 x i140> %v3,%w3
 %packed_mask = bitcast <4 x i1> %cmp to i4
 %mask = zext i4 %packed_mask to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %word0_0 = trunc i140 %r0 to i64
 %out0_0 = getelementptr i8,ptr %out,i64 0
 store i64 %word0_0,ptr %out0_0,align 1
 %shift0_1 = lshr i140 %r0,64
 %word0_1 = trunc i140 %shift0_1 to i64
 %out0_1 = getelementptr i8,ptr %out,i64 8
 store i64 %word0_1,ptr %out0_1,align 1
 %shift0_2 = lshr i140 %r0,128
 %word0_2 = trunc i140 %shift0_2 to i64
 %out0_2 = getelementptr i8,ptr %out,i64 16
 store i64 %word0_2,ptr %out0_2,align 1
 %word1_0 = trunc i140 %r1 to i64
 %out1_0 = getelementptr i8,ptr %out,i64 24
 store i64 %word1_0,ptr %out1_0,align 1
 %shift1_1 = lshr i140 %r1,64
 %word1_1 = trunc i140 %shift1_1 to i64
 %out1_1 = getelementptr i8,ptr %out,i64 32
 store i64 %word1_1,ptr %out1_1,align 1
 %shift1_2 = lshr i140 %r1,128
 %word1_2 = trunc i140 %shift1_2 to i64
 %out1_2 = getelementptr i8,ptr %out,i64 40
 store i64 %word1_2,ptr %out1_2,align 1
 %word2_0 = trunc i140 %r2 to i64
 %out2_0 = getelementptr i8,ptr %out,i64 48
 store i64 %word2_0,ptr %out2_0,align 1
 %shift2_1 = lshr i140 %r2,64
 %word2_1 = trunc i140 %shift2_1 to i64
 %out2_1 = getelementptr i8,ptr %out,i64 56
 store i64 %word2_1,ptr %out2_1,align 1
 %shift2_2 = lshr i140 %r2,128
 %word2_2 = trunc i140 %shift2_2 to i64
 %out2_2 = getelementptr i8,ptr %out,i64 64
 store i64 %word2_2,ptr %out2_2,align 1
 %word3_0 = trunc i140 %r3 to i64
 %out3_0 = getelementptr i8,ptr %out,i64 72
 store i64 %word3_0,ptr %out3_0,align 1
 %shift3_1 = lshr i140 %r3,64
 %word3_1 = trunc i140 %shift3_1 to i64
 %out3_1 = getelementptr i8,ptr %out,i64 80
 store i64 %word3_1,ptr %out3_1,align 1
 %shift3_2 = lshr i140 %r3,128
 %word3_2 = trunc i140 %shift3_2 to i64
 %out3_2 = getelementptr i8,ptr %out,i64 88
 store i64 %word3_2,ptr %out3_2,align 1
 %word4_0 = trunc i200 %r4 to i64
 %out4_0 = getelementptr i8,ptr %out,i64 96
 store i64 %word4_0,ptr %out4_0,align 1
 %shift4_1 = lshr i200 %r4,64
 %word4_1 = trunc i200 %shift4_1 to i64
 %out4_1 = getelementptr i8,ptr %out,i64 104
 store i64 %word4_1,ptr %out4_1,align 1
 %shift4_2 = lshr i200 %r4,128
 %word4_2 = trunc i200 %shift4_2 to i64
 %out4_2 = getelementptr i8,ptr %out,i64 112
 store i64 %word4_2,ptr %out4_2,align 1
 %shift4_3 = lshr i200 %r4,192
 %word4_3 = trunc i200 %shift4_3 to i64
 %out4_3 = getelementptr i8,ptr %out,i64 120
 store i64 %word4_3,ptr %out4_3,align 1
 %word5_0 = trunc i200 %r5 to i64
 %out5_0 = getelementptr i8,ptr %out,i64 128
 store i64 %word5_0,ptr %out5_0,align 1
 %shift5_1 = lshr i200 %r5,64
 %word5_1 = trunc i200 %shift5_1 to i64
 %out5_1 = getelementptr i8,ptr %out,i64 136
 store i64 %word5_1,ptr %out5_1,align 1
 %shift5_2 = lshr i200 %r5,128
 %word5_2 = trunc i200 %shift5_2 to i64
 %out5_2 = getelementptr i8,ptr %out,i64 144
 store i64 %word5_2,ptr %out5_2,align 1
 %shift5_3 = lshr i200 %r5,192
 %word5_3 = trunc i200 %shift5_3 to i64
 %out5_3 = getelementptr i8,ptr %out,i64 152
 store i64 %word5_3,ptr %out5_3,align 1
 %mp = getelementptr i8,ptr %out,i64 160
 store i64 %mask,ptr %mp,align 1
 %op = getelementptr i8,ptr %out,i64 168
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %mask,%token
 ret i64 %answer
}
define i64 @wide_saturation_vector_probe_18(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %temporary = alloca [160 x i8],align 16
 %constant = alloca i140,align 16
 store i140 1267650600228229401496703205376,ptr %constant,align 16
 %bp = getelementptr i8,ptr %input,i64 32
 %sp = getelementptr i8,ptr %input,i64 64
 %s0 = load i64,ptr %sp,align 1
 %tp = getelementptr i8,ptr %input,i64 72
 %t0 = load i64,ptr %tp,align 1
 %temporary0 = getelementptr i8,ptr %temporary,i64 0
 call void @wide_sat_140_u_0(ptr %temporary0,ptr %input,i64 %s0)
 %temporary1 = getelementptr i8,ptr %temporary,i64 24
 call void @wide_sat_140_s_0(ptr %temporary1,ptr %input,i64 %s0)
 %temporary2 = getelementptr i8,ptr %temporary,i64 48
 call void @wide_sat_140_u_0(ptr %temporary2,ptr %constant,i64 %s0)
 %temporary3 = getelementptr i8,ptr %temporary,i64 72
 call void @wide_sat_140_s_0(ptr %temporary3,ptr %constant,i64 %s0)
 %temporary4 = getelementptr i8,ptr %temporary,i64 96
 call void @wide_sat_200_u_0(ptr %temporary4,ptr %bp,i64 %t0)
 %temporary5 = getelementptr i8,ptr %temporary,i64 128
 call void @wide_sat_200_s_0(ptr %temporary5,ptr %bp,i64 %t0)
 %r0 = load i140,ptr %temporary0,align 1
 %r1 = load i140,ptr %temporary1,align 1
 %r2 = load i140,ptr %temporary2,align 1
 %r3 = load i140,ptr %temporary3,align 1
 %r4 = load i200,ptr %temporary4,align 1
 %r5 = load i200,ptr %temporary5,align 1
 %v0 = insertelement <4 x i140> poison,i140 %r0,i64 0
 %v1 = insertelement <4 x i140> %v0,i140 %r1,i64 1
 %v2 = insertelement <4 x i140> %v1,i140 %r2,i64 2
 %v3 = insertelement <4 x i140> %v2,i140 %r3,i64 3
 %cmp = icmp uge <4 x i140> %v3,<i140 0,i140 -1,i140 696898287454081973172991196020261297061887,i140 -696898287454081973172991196020261297061888>
 %packed_mask = bitcast <4 x i1> %cmp to i4
 %mask = zext i4 %packed_mask to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %word0_0 = trunc i140 %r0 to i64
 %out0_0 = getelementptr i8,ptr %out,i64 0
 store i64 %word0_0,ptr %out0_0,align 1
 %shift0_1 = lshr i140 %r0,64
 %word0_1 = trunc i140 %shift0_1 to i64
 %out0_1 = getelementptr i8,ptr %out,i64 8
 store i64 %word0_1,ptr %out0_1,align 1
 %shift0_2 = lshr i140 %r0,128
 %word0_2 = trunc i140 %shift0_2 to i64
 %out0_2 = getelementptr i8,ptr %out,i64 16
 store i64 %word0_2,ptr %out0_2,align 1
 %word1_0 = trunc i140 %r1 to i64
 %out1_0 = getelementptr i8,ptr %out,i64 24
 store i64 %word1_0,ptr %out1_0,align 1
 %shift1_1 = lshr i140 %r1,64
 %word1_1 = trunc i140 %shift1_1 to i64
 %out1_1 = getelementptr i8,ptr %out,i64 32
 store i64 %word1_1,ptr %out1_1,align 1
 %shift1_2 = lshr i140 %r1,128
 %word1_2 = trunc i140 %shift1_2 to i64
 %out1_2 = getelementptr i8,ptr %out,i64 40
 store i64 %word1_2,ptr %out1_2,align 1
 %word2_0 = trunc i140 %r2 to i64
 %out2_0 = getelementptr i8,ptr %out,i64 48
 store i64 %word2_0,ptr %out2_0,align 1
 %shift2_1 = lshr i140 %r2,64
 %word2_1 = trunc i140 %shift2_1 to i64
 %out2_1 = getelementptr i8,ptr %out,i64 56
 store i64 %word2_1,ptr %out2_1,align 1
 %shift2_2 = lshr i140 %r2,128
 %word2_2 = trunc i140 %shift2_2 to i64
 %out2_2 = getelementptr i8,ptr %out,i64 64
 store i64 %word2_2,ptr %out2_2,align 1
 %word3_0 = trunc i140 %r3 to i64
 %out3_0 = getelementptr i8,ptr %out,i64 72
 store i64 %word3_0,ptr %out3_0,align 1
 %shift3_1 = lshr i140 %r3,64
 %word3_1 = trunc i140 %shift3_1 to i64
 %out3_1 = getelementptr i8,ptr %out,i64 80
 store i64 %word3_1,ptr %out3_1,align 1
 %shift3_2 = lshr i140 %r3,128
 %word3_2 = trunc i140 %shift3_2 to i64
 %out3_2 = getelementptr i8,ptr %out,i64 88
 store i64 %word3_2,ptr %out3_2,align 1
 %word4_0 = trunc i200 %r4 to i64
 %out4_0 = getelementptr i8,ptr %out,i64 96
 store i64 %word4_0,ptr %out4_0,align 1
 %shift4_1 = lshr i200 %r4,64
 %word4_1 = trunc i200 %shift4_1 to i64
 %out4_1 = getelementptr i8,ptr %out,i64 104
 store i64 %word4_1,ptr %out4_1,align 1
 %shift4_2 = lshr i200 %r4,128
 %word4_2 = trunc i200 %shift4_2 to i64
 %out4_2 = getelementptr i8,ptr %out,i64 112
 store i64 %word4_2,ptr %out4_2,align 1
 %shift4_3 = lshr i200 %r4,192
 %word4_3 = trunc i200 %shift4_3 to i64
 %out4_3 = getelementptr i8,ptr %out,i64 120
 store i64 %word4_3,ptr %out4_3,align 1
 %word5_0 = trunc i200 %r5 to i64
 %out5_0 = getelementptr i8,ptr %out,i64 128
 store i64 %word5_0,ptr %out5_0,align 1
 %shift5_1 = lshr i200 %r5,64
 %word5_1 = trunc i200 %shift5_1 to i64
 %out5_1 = getelementptr i8,ptr %out,i64 136
 store i64 %word5_1,ptr %out5_1,align 1
 %shift5_2 = lshr i200 %r5,128
 %word5_2 = trunc i200 %shift5_2 to i64
 %out5_2 = getelementptr i8,ptr %out,i64 144
 store i64 %word5_2,ptr %out5_2,align 1
 %shift5_3 = lshr i200 %r5,192
 %word5_3 = trunc i200 %shift5_3 to i64
 %out5_3 = getelementptr i8,ptr %out,i64 152
 store i64 %word5_3,ptr %out5_3,align 1
 %mp = getelementptr i8,ptr %out,i64 160
 store i64 %mask,ptr %mp,align 1
 %op = getelementptr i8,ptr %out,i64 168
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %mask,%token
 ret i64 %answer
}
define i64 @wide_saturation_vector_probe_19(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %temporary = alloca [160 x i8],align 16
 %constant = alloca i140,align 16
 store i140 1267650600228229401496703205376,ptr %constant,align 16
 %bp = getelementptr i8,ptr %input,i64 32
 %sp = getelementptr i8,ptr %input,i64 64
 %s0 = load i64,ptr %sp,align 1
 %tp = getelementptr i8,ptr %input,i64 72
 %t0 = load i64,ptr %tp,align 1
 %temporary0 = getelementptr i8,ptr %temporary,i64 0
 call void @wide_sat_140_u_1(ptr %temporary0,ptr %input,i64 %s0)
 %temporary1 = getelementptr i8,ptr %temporary,i64 24
 call void @wide_sat_140_s_1(ptr %temporary1,ptr %input,i64 %s0)
 %temporary2 = getelementptr i8,ptr %temporary,i64 48
 call void @wide_sat_140_u_1(ptr %temporary2,ptr %constant,i64 %s0)
 %temporary3 = getelementptr i8,ptr %temporary,i64 72
 call void @wide_sat_140_s_1(ptr %temporary3,ptr %constant,i64 %s0)
 %temporary4 = getelementptr i8,ptr %temporary,i64 96
 call void @wide_sat_200_u_1(ptr %temporary4,ptr %bp,i64 %t0)
 %temporary5 = getelementptr i8,ptr %temporary,i64 128
 call void @wide_sat_200_s_1(ptr %temporary5,ptr %bp,i64 %t0)
 %r0 = load i140,ptr %temporary0,align 1
 %r1 = load i140,ptr %temporary1,align 1
 %r2 = load i140,ptr %temporary2,align 1
 %r3 = load i140,ptr %temporary3,align 1
 %r4 = load i200,ptr %temporary4,align 1
 %r5 = load i200,ptr %temporary5,align 1
 %v0 = insertelement <4 x i140> poison,i140 %r0,i64 0
 %v1 = insertelement <4 x i140> %v0,i140 %r1,i64 1
 %v2 = insertelement <4 x i140> %v1,i140 %r2,i64 2
 %v3 = insertelement <4 x i140> %v2,i140 %r3,i64 3
 %cmp = icmp uge <4 x i140> %v3,<i140 0,i140 -1,i140 696898287454081973172991196020261297061887,i140 -696898287454081973172991196020261297061888>
 %packed_mask = bitcast <4 x i1> %cmp to i4
 %mask = zext i4 %packed_mask to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %word0_0 = trunc i140 %r0 to i64
 %out0_0 = getelementptr i8,ptr %out,i64 0
 store i64 %word0_0,ptr %out0_0,align 1
 %shift0_1 = lshr i140 %r0,64
 %word0_1 = trunc i140 %shift0_1 to i64
 %out0_1 = getelementptr i8,ptr %out,i64 8
 store i64 %word0_1,ptr %out0_1,align 1
 %shift0_2 = lshr i140 %r0,128
 %word0_2 = trunc i140 %shift0_2 to i64
 %out0_2 = getelementptr i8,ptr %out,i64 16
 store i64 %word0_2,ptr %out0_2,align 1
 %word1_0 = trunc i140 %r1 to i64
 %out1_0 = getelementptr i8,ptr %out,i64 24
 store i64 %word1_0,ptr %out1_0,align 1
 %shift1_1 = lshr i140 %r1,64
 %word1_1 = trunc i140 %shift1_1 to i64
 %out1_1 = getelementptr i8,ptr %out,i64 32
 store i64 %word1_1,ptr %out1_1,align 1
 %shift1_2 = lshr i140 %r1,128
 %word1_2 = trunc i140 %shift1_2 to i64
 %out1_2 = getelementptr i8,ptr %out,i64 40
 store i64 %word1_2,ptr %out1_2,align 1
 %word2_0 = trunc i140 %r2 to i64
 %out2_0 = getelementptr i8,ptr %out,i64 48
 store i64 %word2_0,ptr %out2_0,align 1
 %shift2_1 = lshr i140 %r2,64
 %word2_1 = trunc i140 %shift2_1 to i64
 %out2_1 = getelementptr i8,ptr %out,i64 56
 store i64 %word2_1,ptr %out2_1,align 1
 %shift2_2 = lshr i140 %r2,128
 %word2_2 = trunc i140 %shift2_2 to i64
 %out2_2 = getelementptr i8,ptr %out,i64 64
 store i64 %word2_2,ptr %out2_2,align 1
 %word3_0 = trunc i140 %r3 to i64
 %out3_0 = getelementptr i8,ptr %out,i64 72
 store i64 %word3_0,ptr %out3_0,align 1
 %shift3_1 = lshr i140 %r3,64
 %word3_1 = trunc i140 %shift3_1 to i64
 %out3_1 = getelementptr i8,ptr %out,i64 80
 store i64 %word3_1,ptr %out3_1,align 1
 %shift3_2 = lshr i140 %r3,128
 %word3_2 = trunc i140 %shift3_2 to i64
 %out3_2 = getelementptr i8,ptr %out,i64 88
 store i64 %word3_2,ptr %out3_2,align 1
 %word4_0 = trunc i200 %r4 to i64
 %out4_0 = getelementptr i8,ptr %out,i64 96
 store i64 %word4_0,ptr %out4_0,align 1
 %shift4_1 = lshr i200 %r4,64
 %word4_1 = trunc i200 %shift4_1 to i64
 %out4_1 = getelementptr i8,ptr %out,i64 104
 store i64 %word4_1,ptr %out4_1,align 1
 %shift4_2 = lshr i200 %r4,128
 %word4_2 = trunc i200 %shift4_2 to i64
 %out4_2 = getelementptr i8,ptr %out,i64 112
 store i64 %word4_2,ptr %out4_2,align 1
 %shift4_3 = lshr i200 %r4,192
 %word4_3 = trunc i200 %shift4_3 to i64
 %out4_3 = getelementptr i8,ptr %out,i64 120
 store i64 %word4_3,ptr %out4_3,align 1
 %word5_0 = trunc i200 %r5 to i64
 %out5_0 = getelementptr i8,ptr %out,i64 128
 store i64 %word5_0,ptr %out5_0,align 1
 %shift5_1 = lshr i200 %r5,64
 %word5_1 = trunc i200 %shift5_1 to i64
 %out5_1 = getelementptr i8,ptr %out,i64 136
 store i64 %word5_1,ptr %out5_1,align 1
 %shift5_2 = lshr i200 %r5,128
 %word5_2 = trunc i200 %shift5_2 to i64
 %out5_2 = getelementptr i8,ptr %out,i64 144
 store i64 %word5_2,ptr %out5_2,align 1
 %shift5_3 = lshr i200 %r5,192
 %word5_3 = trunc i200 %shift5_3 to i64
 %out5_3 = getelementptr i8,ptr %out,i64 152
 store i64 %word5_3,ptr %out5_3,align 1
 %mp = getelementptr i8,ptr %out,i64 160
 store i64 %mask,ptr %mp,align 1
 %op = getelementptr i8,ptr %out,i64 168
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %mask,%token
 ret i64 %answer
}
define i64 @wide_saturation_vector_probe_20(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %temporary = alloca [160 x i8],align 16
 %constant = alloca i140,align 16
 store i140 1267650600228229401496703205376,ptr %constant,align 16
 %bp = getelementptr i8,ptr %input,i64 32
 %sp = getelementptr i8,ptr %input,i64 64
 %s0 = load i64,ptr %sp,align 1
 %tp = getelementptr i8,ptr %input,i64 72
 %t0 = load i64,ptr %tp,align 1
 %temporary0 = getelementptr i8,ptr %temporary,i64 0
 call void @wide_sat_140_u_2(ptr %temporary0,ptr %input,i64 %s0)
 %temporary1 = getelementptr i8,ptr %temporary,i64 24
 call void @wide_sat_140_s_2(ptr %temporary1,ptr %input,i64 %s0)
 %temporary2 = getelementptr i8,ptr %temporary,i64 48
 call void @wide_sat_140_u_2(ptr %temporary2,ptr %constant,i64 %s0)
 %temporary3 = getelementptr i8,ptr %temporary,i64 72
 call void @wide_sat_140_s_2(ptr %temporary3,ptr %constant,i64 %s0)
 %temporary4 = getelementptr i8,ptr %temporary,i64 96
 call void @wide_sat_200_u_2(ptr %temporary4,ptr %bp,i64 %t0)
 %temporary5 = getelementptr i8,ptr %temporary,i64 128
 call void @wide_sat_200_s_2(ptr %temporary5,ptr %bp,i64 %t0)
 %r0 = load i140,ptr %temporary0,align 1
 %r1 = load i140,ptr %temporary1,align 1
 %r2 = load i140,ptr %temporary2,align 1
 %r3 = load i140,ptr %temporary3,align 1
 %r4 = load i200,ptr %temporary4,align 1
 %r5 = load i200,ptr %temporary5,align 1
 %v0 = insertelement <4 x i140> poison,i140 %r0,i64 0
 %v1 = insertelement <4 x i140> %v0,i140 %r1,i64 1
 %v2 = insertelement <4 x i140> %v1,i140 %r2,i64 2
 %v3 = insertelement <4 x i140> %v2,i140 %r3,i64 3
 %cmp = icmp uge <4 x i140> %v3,<i140 0,i140 -1,i140 696898287454081973172991196020261297061887,i140 -696898287454081973172991196020261297061888>
 %packed_mask = bitcast <4 x i1> %cmp to i4
 %mask = zext i4 %packed_mask to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %word0_0 = trunc i140 %r0 to i64
 %out0_0 = getelementptr i8,ptr %out,i64 0
 store i64 %word0_0,ptr %out0_0,align 1
 %shift0_1 = lshr i140 %r0,64
 %word0_1 = trunc i140 %shift0_1 to i64
 %out0_1 = getelementptr i8,ptr %out,i64 8
 store i64 %word0_1,ptr %out0_1,align 1
 %shift0_2 = lshr i140 %r0,128
 %word0_2 = trunc i140 %shift0_2 to i64
 %out0_2 = getelementptr i8,ptr %out,i64 16
 store i64 %word0_2,ptr %out0_2,align 1
 %word1_0 = trunc i140 %r1 to i64
 %out1_0 = getelementptr i8,ptr %out,i64 24
 store i64 %word1_0,ptr %out1_0,align 1
 %shift1_1 = lshr i140 %r1,64
 %word1_1 = trunc i140 %shift1_1 to i64
 %out1_1 = getelementptr i8,ptr %out,i64 32
 store i64 %word1_1,ptr %out1_1,align 1
 %shift1_2 = lshr i140 %r1,128
 %word1_2 = trunc i140 %shift1_2 to i64
 %out1_2 = getelementptr i8,ptr %out,i64 40
 store i64 %word1_2,ptr %out1_2,align 1
 %word2_0 = trunc i140 %r2 to i64
 %out2_0 = getelementptr i8,ptr %out,i64 48
 store i64 %word2_0,ptr %out2_0,align 1
 %shift2_1 = lshr i140 %r2,64
 %word2_1 = trunc i140 %shift2_1 to i64
 %out2_1 = getelementptr i8,ptr %out,i64 56
 store i64 %word2_1,ptr %out2_1,align 1
 %shift2_2 = lshr i140 %r2,128
 %word2_2 = trunc i140 %shift2_2 to i64
 %out2_2 = getelementptr i8,ptr %out,i64 64
 store i64 %word2_2,ptr %out2_2,align 1
 %word3_0 = trunc i140 %r3 to i64
 %out3_0 = getelementptr i8,ptr %out,i64 72
 store i64 %word3_0,ptr %out3_0,align 1
 %shift3_1 = lshr i140 %r3,64
 %word3_1 = trunc i140 %shift3_1 to i64
 %out3_1 = getelementptr i8,ptr %out,i64 80
 store i64 %word3_1,ptr %out3_1,align 1
 %shift3_2 = lshr i140 %r3,128
 %word3_2 = trunc i140 %shift3_2 to i64
 %out3_2 = getelementptr i8,ptr %out,i64 88
 store i64 %word3_2,ptr %out3_2,align 1
 %word4_0 = trunc i200 %r4 to i64
 %out4_0 = getelementptr i8,ptr %out,i64 96
 store i64 %word4_0,ptr %out4_0,align 1
 %shift4_1 = lshr i200 %r4,64
 %word4_1 = trunc i200 %shift4_1 to i64
 %out4_1 = getelementptr i8,ptr %out,i64 104
 store i64 %word4_1,ptr %out4_1,align 1
 %shift4_2 = lshr i200 %r4,128
 %word4_2 = trunc i200 %shift4_2 to i64
 %out4_2 = getelementptr i8,ptr %out,i64 112
 store i64 %word4_2,ptr %out4_2,align 1
 %shift4_3 = lshr i200 %r4,192
 %word4_3 = trunc i200 %shift4_3 to i64
 %out4_3 = getelementptr i8,ptr %out,i64 120
 store i64 %word4_3,ptr %out4_3,align 1
 %word5_0 = trunc i200 %r5 to i64
 %out5_0 = getelementptr i8,ptr %out,i64 128
 store i64 %word5_0,ptr %out5_0,align 1
 %shift5_1 = lshr i200 %r5,64
 %word5_1 = trunc i200 %shift5_1 to i64
 %out5_1 = getelementptr i8,ptr %out,i64 136
 store i64 %word5_1,ptr %out5_1,align 1
 %shift5_2 = lshr i200 %r5,128
 %word5_2 = trunc i200 %shift5_2 to i64
 %out5_2 = getelementptr i8,ptr %out,i64 144
 store i64 %word5_2,ptr %out5_2,align 1
 %shift5_3 = lshr i200 %r5,192
 %word5_3 = trunc i200 %shift5_3 to i64
 %out5_3 = getelementptr i8,ptr %out,i64 152
 store i64 %word5_3,ptr %out5_3,align 1
 %mp = getelementptr i8,ptr %out,i64 160
 store i64 %mask,ptr %mp,align 1
 %op = getelementptr i8,ptr %out,i64 168
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %mask,%token
 ret i64 %answer
}
define i64 @wide_saturation_vector_probe_21(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %temporary = alloca [160 x i8],align 16
 %constant = alloca i140,align 16
 store i140 1267650600228229401496703205376,ptr %constant,align 16
 %bp = getelementptr i8,ptr %input,i64 32
 %sp = getelementptr i8,ptr %input,i64 64
 %s0 = load i64,ptr %sp,align 1
 %tp = getelementptr i8,ptr %input,i64 72
 %t0 = load i64,ptr %tp,align 1
 %temporary0 = getelementptr i8,ptr %temporary,i64 0
 call void @wide_sat_140_u_0(ptr %temporary0,ptr %input,i64 %s0)
 %temporary1 = getelementptr i8,ptr %temporary,i64 24
 call void @wide_sat_140_s_0(ptr %temporary1,ptr %input,i64 %s0)
 %temporary2 = getelementptr i8,ptr %temporary,i64 48
 call void @wide_sat_140_u_0(ptr %temporary2,ptr %constant,i64 %s0)
 %temporary3 = getelementptr i8,ptr %temporary,i64 72
 call void @wide_sat_140_s_0(ptr %temporary3,ptr %constant,i64 %s0)
 %temporary4 = getelementptr i8,ptr %temporary,i64 96
 call void @wide_sat_200_u_0(ptr %temporary4,ptr %bp,i64 %t0)
 %temporary5 = getelementptr i8,ptr %temporary,i64 128
 call void @wide_sat_200_s_0(ptr %temporary5,ptr %bp,i64 %t0)
 %r0 = load i140,ptr %temporary0,align 1
 %r1 = load i140,ptr %temporary1,align 1
 %r2 = load i140,ptr %temporary2,align 1
 %r3 = load i140,ptr %temporary3,align 1
 %r4 = load i200,ptr %temporary4,align 1
 %r5 = load i200,ptr %temporary5,align 1
 %v0 = insertelement <4 x i140> poison,i140 %r0,i64 0
 %v1 = insertelement <4 x i140> %v0,i140 %r1,i64 1
 %v2 = insertelement <4 x i140> %v1,i140 %r2,i64 2
 %v3 = insertelement <4 x i140> %v2,i140 %r3,i64 3
 %w0 = insertelement <4 x i140> poison,i140 0,i32 0
 %w1 = insertelement <4 x i140> %w0,i140 -1,i32 1
 %w2 = insertelement <4 x i140> %w1,i140 696898287454081973172991196020261297061887,i32 2
 %w3 = insertelement <4 x i140> %w2,i140 -696898287454081973172991196020261297061888,i32 3
 %cmp = icmp uge <4 x i140> %v3,%w3
 %packed_mask = bitcast <4 x i1> %cmp to i4
 %mask = zext i4 %packed_mask to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %word0_0 = trunc i140 %r0 to i64
 %out0_0 = getelementptr i8,ptr %out,i64 0
 store i64 %word0_0,ptr %out0_0,align 1
 %shift0_1 = lshr i140 %r0,64
 %word0_1 = trunc i140 %shift0_1 to i64
 %out0_1 = getelementptr i8,ptr %out,i64 8
 store i64 %word0_1,ptr %out0_1,align 1
 %shift0_2 = lshr i140 %r0,128
 %word0_2 = trunc i140 %shift0_2 to i64
 %out0_2 = getelementptr i8,ptr %out,i64 16
 store i64 %word0_2,ptr %out0_2,align 1
 %word1_0 = trunc i140 %r1 to i64
 %out1_0 = getelementptr i8,ptr %out,i64 24
 store i64 %word1_0,ptr %out1_0,align 1
 %shift1_1 = lshr i140 %r1,64
 %word1_1 = trunc i140 %shift1_1 to i64
 %out1_1 = getelementptr i8,ptr %out,i64 32
 store i64 %word1_1,ptr %out1_1,align 1
 %shift1_2 = lshr i140 %r1,128
 %word1_2 = trunc i140 %shift1_2 to i64
 %out1_2 = getelementptr i8,ptr %out,i64 40
 store i64 %word1_2,ptr %out1_2,align 1
 %word2_0 = trunc i140 %r2 to i64
 %out2_0 = getelementptr i8,ptr %out,i64 48
 store i64 %word2_0,ptr %out2_0,align 1
 %shift2_1 = lshr i140 %r2,64
 %word2_1 = trunc i140 %shift2_1 to i64
 %out2_1 = getelementptr i8,ptr %out,i64 56
 store i64 %word2_1,ptr %out2_1,align 1
 %shift2_2 = lshr i140 %r2,128
 %word2_2 = trunc i140 %shift2_2 to i64
 %out2_2 = getelementptr i8,ptr %out,i64 64
 store i64 %word2_2,ptr %out2_2,align 1
 %word3_0 = trunc i140 %r3 to i64
 %out3_0 = getelementptr i8,ptr %out,i64 72
 store i64 %word3_0,ptr %out3_0,align 1
 %shift3_1 = lshr i140 %r3,64
 %word3_1 = trunc i140 %shift3_1 to i64
 %out3_1 = getelementptr i8,ptr %out,i64 80
 store i64 %word3_1,ptr %out3_1,align 1
 %shift3_2 = lshr i140 %r3,128
 %word3_2 = trunc i140 %shift3_2 to i64
 %out3_2 = getelementptr i8,ptr %out,i64 88
 store i64 %word3_2,ptr %out3_2,align 1
 %word4_0 = trunc i200 %r4 to i64
 %out4_0 = getelementptr i8,ptr %out,i64 96
 store i64 %word4_0,ptr %out4_0,align 1
 %shift4_1 = lshr i200 %r4,64
 %word4_1 = trunc i200 %shift4_1 to i64
 %out4_1 = getelementptr i8,ptr %out,i64 104
 store i64 %word4_1,ptr %out4_1,align 1
 %shift4_2 = lshr i200 %r4,128
 %word4_2 = trunc i200 %shift4_2 to i64
 %out4_2 = getelementptr i8,ptr %out,i64 112
 store i64 %word4_2,ptr %out4_2,align 1
 %shift4_3 = lshr i200 %r4,192
 %word4_3 = trunc i200 %shift4_3 to i64
 %out4_3 = getelementptr i8,ptr %out,i64 120
 store i64 %word4_3,ptr %out4_3,align 1
 %word5_0 = trunc i200 %r5 to i64
 %out5_0 = getelementptr i8,ptr %out,i64 128
 store i64 %word5_0,ptr %out5_0,align 1
 %shift5_1 = lshr i200 %r5,64
 %word5_1 = trunc i200 %shift5_1 to i64
 %out5_1 = getelementptr i8,ptr %out,i64 136
 store i64 %word5_1,ptr %out5_1,align 1
 %shift5_2 = lshr i200 %r5,128
 %word5_2 = trunc i200 %shift5_2 to i64
 %out5_2 = getelementptr i8,ptr %out,i64 144
 store i64 %word5_2,ptr %out5_2,align 1
 %shift5_3 = lshr i200 %r5,192
 %word5_3 = trunc i200 %shift5_3 to i64
 %out5_3 = getelementptr i8,ptr %out,i64 152
 store i64 %word5_3,ptr %out5_3,align 1
 %mp = getelementptr i8,ptr %out,i64 160
 store i64 %mask,ptr %mp,align 1
 %op = getelementptr i8,ptr %out,i64 168
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %mask,%token
 ret i64 %answer
}
define i64 @wide_saturation_vector_probe_22(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %temporary = alloca [160 x i8],align 16
 %constant = alloca i140,align 16
 store i140 1267650600228229401496703205376,ptr %constant,align 16
 %bp = getelementptr i8,ptr %input,i64 32
 %sp = getelementptr i8,ptr %input,i64 64
 %s0 = load i64,ptr %sp,align 1
 %tp = getelementptr i8,ptr %input,i64 72
 %t0 = load i64,ptr %tp,align 1
 %temporary0 = getelementptr i8,ptr %temporary,i64 0
 call void @wide_sat_140_u_1(ptr %temporary0,ptr %input,i64 %s0)
 %temporary1 = getelementptr i8,ptr %temporary,i64 24
 call void @wide_sat_140_s_1(ptr %temporary1,ptr %input,i64 %s0)
 %temporary2 = getelementptr i8,ptr %temporary,i64 48
 call void @wide_sat_140_u_1(ptr %temporary2,ptr %constant,i64 %s0)
 %temporary3 = getelementptr i8,ptr %temporary,i64 72
 call void @wide_sat_140_s_1(ptr %temporary3,ptr %constant,i64 %s0)
 %temporary4 = getelementptr i8,ptr %temporary,i64 96
 call void @wide_sat_200_u_1(ptr %temporary4,ptr %bp,i64 %t0)
 %temporary5 = getelementptr i8,ptr %temporary,i64 128
 call void @wide_sat_200_s_1(ptr %temporary5,ptr %bp,i64 %t0)
 %r0 = load i140,ptr %temporary0,align 1
 %r1 = load i140,ptr %temporary1,align 1
 %r2 = load i140,ptr %temporary2,align 1
 %r3 = load i140,ptr %temporary3,align 1
 %r4 = load i200,ptr %temporary4,align 1
 %r5 = load i200,ptr %temporary5,align 1
 %v0 = insertelement <4 x i140> poison,i140 %r0,i64 0
 %v1 = insertelement <4 x i140> %v0,i140 %r1,i64 1
 %v2 = insertelement <4 x i140> %v1,i140 %r2,i64 2
 %v3 = insertelement <4 x i140> %v2,i140 %r3,i64 3
 %w0 = insertelement <4 x i140> poison,i140 0,i32 0
 %w1 = insertelement <4 x i140> %w0,i140 -1,i32 1
 %w2 = insertelement <4 x i140> %w1,i140 696898287454081973172991196020261297061887,i32 2
 %w3 = insertelement <4 x i140> %w2,i140 -696898287454081973172991196020261297061888,i32 3
 %cmp = icmp uge <4 x i140> %v3,%w3
 %packed_mask = bitcast <4 x i1> %cmp to i4
 %mask = zext i4 %packed_mask to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %word0_0 = trunc i140 %r0 to i64
 %out0_0 = getelementptr i8,ptr %out,i64 0
 store i64 %word0_0,ptr %out0_0,align 1
 %shift0_1 = lshr i140 %r0,64
 %word0_1 = trunc i140 %shift0_1 to i64
 %out0_1 = getelementptr i8,ptr %out,i64 8
 store i64 %word0_1,ptr %out0_1,align 1
 %shift0_2 = lshr i140 %r0,128
 %word0_2 = trunc i140 %shift0_2 to i64
 %out0_2 = getelementptr i8,ptr %out,i64 16
 store i64 %word0_2,ptr %out0_2,align 1
 %word1_0 = trunc i140 %r1 to i64
 %out1_0 = getelementptr i8,ptr %out,i64 24
 store i64 %word1_0,ptr %out1_0,align 1
 %shift1_1 = lshr i140 %r1,64
 %word1_1 = trunc i140 %shift1_1 to i64
 %out1_1 = getelementptr i8,ptr %out,i64 32
 store i64 %word1_1,ptr %out1_1,align 1
 %shift1_2 = lshr i140 %r1,128
 %word1_2 = trunc i140 %shift1_2 to i64
 %out1_2 = getelementptr i8,ptr %out,i64 40
 store i64 %word1_2,ptr %out1_2,align 1
 %word2_0 = trunc i140 %r2 to i64
 %out2_0 = getelementptr i8,ptr %out,i64 48
 store i64 %word2_0,ptr %out2_0,align 1
 %shift2_1 = lshr i140 %r2,64
 %word2_1 = trunc i140 %shift2_1 to i64
 %out2_1 = getelementptr i8,ptr %out,i64 56
 store i64 %word2_1,ptr %out2_1,align 1
 %shift2_2 = lshr i140 %r2,128
 %word2_2 = trunc i140 %shift2_2 to i64
 %out2_2 = getelementptr i8,ptr %out,i64 64
 store i64 %word2_2,ptr %out2_2,align 1
 %word3_0 = trunc i140 %r3 to i64
 %out3_0 = getelementptr i8,ptr %out,i64 72
 store i64 %word3_0,ptr %out3_0,align 1
 %shift3_1 = lshr i140 %r3,64
 %word3_1 = trunc i140 %shift3_1 to i64
 %out3_1 = getelementptr i8,ptr %out,i64 80
 store i64 %word3_1,ptr %out3_1,align 1
 %shift3_2 = lshr i140 %r3,128
 %word3_2 = trunc i140 %shift3_2 to i64
 %out3_2 = getelementptr i8,ptr %out,i64 88
 store i64 %word3_2,ptr %out3_2,align 1
 %word4_0 = trunc i200 %r4 to i64
 %out4_0 = getelementptr i8,ptr %out,i64 96
 store i64 %word4_0,ptr %out4_0,align 1
 %shift4_1 = lshr i200 %r4,64
 %word4_1 = trunc i200 %shift4_1 to i64
 %out4_1 = getelementptr i8,ptr %out,i64 104
 store i64 %word4_1,ptr %out4_1,align 1
 %shift4_2 = lshr i200 %r4,128
 %word4_2 = trunc i200 %shift4_2 to i64
 %out4_2 = getelementptr i8,ptr %out,i64 112
 store i64 %word4_2,ptr %out4_2,align 1
 %shift4_3 = lshr i200 %r4,192
 %word4_3 = trunc i200 %shift4_3 to i64
 %out4_3 = getelementptr i8,ptr %out,i64 120
 store i64 %word4_3,ptr %out4_3,align 1
 %word5_0 = trunc i200 %r5 to i64
 %out5_0 = getelementptr i8,ptr %out,i64 128
 store i64 %word5_0,ptr %out5_0,align 1
 %shift5_1 = lshr i200 %r5,64
 %word5_1 = trunc i200 %shift5_1 to i64
 %out5_1 = getelementptr i8,ptr %out,i64 136
 store i64 %word5_1,ptr %out5_1,align 1
 %shift5_2 = lshr i200 %r5,128
 %word5_2 = trunc i200 %shift5_2 to i64
 %out5_2 = getelementptr i8,ptr %out,i64 144
 store i64 %word5_2,ptr %out5_2,align 1
 %shift5_3 = lshr i200 %r5,192
 %word5_3 = trunc i200 %shift5_3 to i64
 %out5_3 = getelementptr i8,ptr %out,i64 152
 store i64 %word5_3,ptr %out5_3,align 1
 %mp = getelementptr i8,ptr %out,i64 160
 store i64 %mask,ptr %mp,align 1
 %op = getelementptr i8,ptr %out,i64 168
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %mask,%token
 ret i64 %answer
}
define i64 @wide_saturation_vector_probe_23(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %temporary = alloca [160 x i8],align 16
 %constant = alloca i140,align 16
 store i140 1267650600228229401496703205376,ptr %constant,align 16
 %bp = getelementptr i8,ptr %input,i64 32
 %sp = getelementptr i8,ptr %input,i64 64
 %s0 = load i64,ptr %sp,align 1
 %tp = getelementptr i8,ptr %input,i64 72
 %t0 = load i64,ptr %tp,align 1
 %temporary0 = getelementptr i8,ptr %temporary,i64 0
 call void @wide_sat_140_u_2(ptr %temporary0,ptr %input,i64 %s0)
 %temporary1 = getelementptr i8,ptr %temporary,i64 24
 call void @wide_sat_140_s_2(ptr %temporary1,ptr %input,i64 %s0)
 %temporary2 = getelementptr i8,ptr %temporary,i64 48
 call void @wide_sat_140_u_2(ptr %temporary2,ptr %constant,i64 %s0)
 %temporary3 = getelementptr i8,ptr %temporary,i64 72
 call void @wide_sat_140_s_2(ptr %temporary3,ptr %constant,i64 %s0)
 %temporary4 = getelementptr i8,ptr %temporary,i64 96
 call void @wide_sat_200_u_2(ptr %temporary4,ptr %bp,i64 %t0)
 %temporary5 = getelementptr i8,ptr %temporary,i64 128
 call void @wide_sat_200_s_2(ptr %temporary5,ptr %bp,i64 %t0)
 %r0 = load i140,ptr %temporary0,align 1
 %r1 = load i140,ptr %temporary1,align 1
 %r2 = load i140,ptr %temporary2,align 1
 %r3 = load i140,ptr %temporary3,align 1
 %r4 = load i200,ptr %temporary4,align 1
 %r5 = load i200,ptr %temporary5,align 1
 %v0 = insertelement <4 x i140> poison,i140 %r0,i64 0
 %v1 = insertelement <4 x i140> %v0,i140 %r1,i64 1
 %v2 = insertelement <4 x i140> %v1,i140 %r2,i64 2
 %v3 = insertelement <4 x i140> %v2,i140 %r3,i64 3
 %w0 = insertelement <4 x i140> poison,i140 0,i32 0
 %w1 = insertelement <4 x i140> %w0,i140 -1,i32 1
 %w2 = insertelement <4 x i140> %w1,i140 696898287454081973172991196020261297061887,i32 2
 %w3 = insertelement <4 x i140> %w2,i140 -696898287454081973172991196020261297061888,i32 3
 %cmp = icmp uge <4 x i140> %v3,%w3
 %packed_mask = bitcast <4 x i1> %cmp to i4
 %mask = zext i4 %packed_mask to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %word0_0 = trunc i140 %r0 to i64
 %out0_0 = getelementptr i8,ptr %out,i64 0
 store i64 %word0_0,ptr %out0_0,align 1
 %shift0_1 = lshr i140 %r0,64
 %word0_1 = trunc i140 %shift0_1 to i64
 %out0_1 = getelementptr i8,ptr %out,i64 8
 store i64 %word0_1,ptr %out0_1,align 1
 %shift0_2 = lshr i140 %r0,128
 %word0_2 = trunc i140 %shift0_2 to i64
 %out0_2 = getelementptr i8,ptr %out,i64 16
 store i64 %word0_2,ptr %out0_2,align 1
 %word1_0 = trunc i140 %r1 to i64
 %out1_0 = getelementptr i8,ptr %out,i64 24
 store i64 %word1_0,ptr %out1_0,align 1
 %shift1_1 = lshr i140 %r1,64
 %word1_1 = trunc i140 %shift1_1 to i64
 %out1_1 = getelementptr i8,ptr %out,i64 32
 store i64 %word1_1,ptr %out1_1,align 1
 %shift1_2 = lshr i140 %r1,128
 %word1_2 = trunc i140 %shift1_2 to i64
 %out1_2 = getelementptr i8,ptr %out,i64 40
 store i64 %word1_2,ptr %out1_2,align 1
 %word2_0 = trunc i140 %r2 to i64
 %out2_0 = getelementptr i8,ptr %out,i64 48
 store i64 %word2_0,ptr %out2_0,align 1
 %shift2_1 = lshr i140 %r2,64
 %word2_1 = trunc i140 %shift2_1 to i64
 %out2_1 = getelementptr i8,ptr %out,i64 56
 store i64 %word2_1,ptr %out2_1,align 1
 %shift2_2 = lshr i140 %r2,128
 %word2_2 = trunc i140 %shift2_2 to i64
 %out2_2 = getelementptr i8,ptr %out,i64 64
 store i64 %word2_2,ptr %out2_2,align 1
 %word3_0 = trunc i140 %r3 to i64
 %out3_0 = getelementptr i8,ptr %out,i64 72
 store i64 %word3_0,ptr %out3_0,align 1
 %shift3_1 = lshr i140 %r3,64
 %word3_1 = trunc i140 %shift3_1 to i64
 %out3_1 = getelementptr i8,ptr %out,i64 80
 store i64 %word3_1,ptr %out3_1,align 1
 %shift3_2 = lshr i140 %r3,128
 %word3_2 = trunc i140 %shift3_2 to i64
 %out3_2 = getelementptr i8,ptr %out,i64 88
 store i64 %word3_2,ptr %out3_2,align 1
 %word4_0 = trunc i200 %r4 to i64
 %out4_0 = getelementptr i8,ptr %out,i64 96
 store i64 %word4_0,ptr %out4_0,align 1
 %shift4_1 = lshr i200 %r4,64
 %word4_1 = trunc i200 %shift4_1 to i64
 %out4_1 = getelementptr i8,ptr %out,i64 104
 store i64 %word4_1,ptr %out4_1,align 1
 %shift4_2 = lshr i200 %r4,128
 %word4_2 = trunc i200 %shift4_2 to i64
 %out4_2 = getelementptr i8,ptr %out,i64 112
 store i64 %word4_2,ptr %out4_2,align 1
 %shift4_3 = lshr i200 %r4,192
 %word4_3 = trunc i200 %shift4_3 to i64
 %out4_3 = getelementptr i8,ptr %out,i64 120
 store i64 %word4_3,ptr %out4_3,align 1
 %word5_0 = trunc i200 %r5 to i64
 %out5_0 = getelementptr i8,ptr %out,i64 128
 store i64 %word5_0,ptr %out5_0,align 1
 %shift5_1 = lshr i200 %r5,64
 %word5_1 = trunc i200 %shift5_1 to i64
 %out5_1 = getelementptr i8,ptr %out,i64 136
 store i64 %word5_1,ptr %out5_1,align 1
 %shift5_2 = lshr i200 %r5,128
 %word5_2 = trunc i200 %shift5_2 to i64
 %out5_2 = getelementptr i8,ptr %out,i64 144
 store i64 %word5_2,ptr %out5_2,align 1
 %shift5_3 = lshr i200 %r5,192
 %word5_3 = trunc i200 %shift5_3 to i64
 %out5_3 = getelementptr i8,ptr %out,i64 152
 store i64 %word5_3,ptr %out5_3,align 1
 %mp = getelementptr i8,ptr %out,i64 160
 store i64 %mask,ptr %mp,align 1
 %op = getelementptr i8,ptr %out,i64 168
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %mask,%token
 ret i64 %answer
}
define i64 @wide_saturation_vector_probe_24(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %temporary = alloca [160 x i8],align 16
 %constant = alloca i140,align 16
 store i140 1267650600228229401496703205376,ptr %constant,align 16
 %bp = getelementptr i8,ptr %input,i64 32
 %sp = getelementptr i8,ptr %input,i64 64
 %s0 = load i64,ptr %sp,align 1
 %tp = getelementptr i8,ptr %input,i64 72
 %t0 = load i64,ptr %tp,align 1
 %temporary0 = getelementptr i8,ptr %temporary,i64 0
 call void @wide_sat_140_u_0(ptr %temporary0,ptr %input,i64 %s0)
 %temporary1 = getelementptr i8,ptr %temporary,i64 24
 call void @wide_sat_140_s_0(ptr %temporary1,ptr %input,i64 %s0)
 %temporary2 = getelementptr i8,ptr %temporary,i64 48
 call void @wide_sat_140_u_0(ptr %temporary2,ptr %constant,i64 %s0)
 %temporary3 = getelementptr i8,ptr %temporary,i64 72
 call void @wide_sat_140_s_0(ptr %temporary3,ptr %constant,i64 %s0)
 %temporary4 = getelementptr i8,ptr %temporary,i64 96
 call void @wide_sat_200_u_0(ptr %temporary4,ptr %bp,i64 %t0)
 %temporary5 = getelementptr i8,ptr %temporary,i64 128
 call void @wide_sat_200_s_0(ptr %temporary5,ptr %bp,i64 %t0)
 %r0 = load i140,ptr %temporary0,align 1
 %r1 = load i140,ptr %temporary1,align 1
 %r2 = load i140,ptr %temporary2,align 1
 %r3 = load i140,ptr %temporary3,align 1
 %r4 = load i200,ptr %temporary4,align 1
 %r5 = load i200,ptr %temporary5,align 1
 %v0 = insertelement <4 x i140> poison,i140 %r0,i64 0
 %v1 = insertelement <4 x i140> %v0,i140 %r1,i64 1
 %v2 = insertelement <4 x i140> %v1,i140 %r2,i64 2
 %v3 = insertelement <4 x i140> %v2,i140 %r3,i64 3
 %cmp = icmp ult <4 x i140> %v3,<i140 0,i140 -1,i140 696898287454081973172991196020261297061887,i140 -696898287454081973172991196020261297061888>
 %packed_mask = bitcast <4 x i1> %cmp to i4
 %mask = zext i4 %packed_mask to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %word0_0 = trunc i140 %r0 to i64
 %out0_0 = getelementptr i8,ptr %out,i64 0
 store i64 %word0_0,ptr %out0_0,align 1
 %shift0_1 = lshr i140 %r0,64
 %word0_1 = trunc i140 %shift0_1 to i64
 %out0_1 = getelementptr i8,ptr %out,i64 8
 store i64 %word0_1,ptr %out0_1,align 1
 %shift0_2 = lshr i140 %r0,128
 %word0_2 = trunc i140 %shift0_2 to i64
 %out0_2 = getelementptr i8,ptr %out,i64 16
 store i64 %word0_2,ptr %out0_2,align 1
 %word1_0 = trunc i140 %r1 to i64
 %out1_0 = getelementptr i8,ptr %out,i64 24
 store i64 %word1_0,ptr %out1_0,align 1
 %shift1_1 = lshr i140 %r1,64
 %word1_1 = trunc i140 %shift1_1 to i64
 %out1_1 = getelementptr i8,ptr %out,i64 32
 store i64 %word1_1,ptr %out1_1,align 1
 %shift1_2 = lshr i140 %r1,128
 %word1_2 = trunc i140 %shift1_2 to i64
 %out1_2 = getelementptr i8,ptr %out,i64 40
 store i64 %word1_2,ptr %out1_2,align 1
 %word2_0 = trunc i140 %r2 to i64
 %out2_0 = getelementptr i8,ptr %out,i64 48
 store i64 %word2_0,ptr %out2_0,align 1
 %shift2_1 = lshr i140 %r2,64
 %word2_1 = trunc i140 %shift2_1 to i64
 %out2_1 = getelementptr i8,ptr %out,i64 56
 store i64 %word2_1,ptr %out2_1,align 1
 %shift2_2 = lshr i140 %r2,128
 %word2_2 = trunc i140 %shift2_2 to i64
 %out2_2 = getelementptr i8,ptr %out,i64 64
 store i64 %word2_2,ptr %out2_2,align 1
 %word3_0 = trunc i140 %r3 to i64
 %out3_0 = getelementptr i8,ptr %out,i64 72
 store i64 %word3_0,ptr %out3_0,align 1
 %shift3_1 = lshr i140 %r3,64
 %word3_1 = trunc i140 %shift3_1 to i64
 %out3_1 = getelementptr i8,ptr %out,i64 80
 store i64 %word3_1,ptr %out3_1,align 1
 %shift3_2 = lshr i140 %r3,128
 %word3_2 = trunc i140 %shift3_2 to i64
 %out3_2 = getelementptr i8,ptr %out,i64 88
 store i64 %word3_2,ptr %out3_2,align 1
 %word4_0 = trunc i200 %r4 to i64
 %out4_0 = getelementptr i8,ptr %out,i64 96
 store i64 %word4_0,ptr %out4_0,align 1
 %shift4_1 = lshr i200 %r4,64
 %word4_1 = trunc i200 %shift4_1 to i64
 %out4_1 = getelementptr i8,ptr %out,i64 104
 store i64 %word4_1,ptr %out4_1,align 1
 %shift4_2 = lshr i200 %r4,128
 %word4_2 = trunc i200 %shift4_2 to i64
 %out4_2 = getelementptr i8,ptr %out,i64 112
 store i64 %word4_2,ptr %out4_2,align 1
 %shift4_3 = lshr i200 %r4,192
 %word4_3 = trunc i200 %shift4_3 to i64
 %out4_3 = getelementptr i8,ptr %out,i64 120
 store i64 %word4_3,ptr %out4_3,align 1
 %word5_0 = trunc i200 %r5 to i64
 %out5_0 = getelementptr i8,ptr %out,i64 128
 store i64 %word5_0,ptr %out5_0,align 1
 %shift5_1 = lshr i200 %r5,64
 %word5_1 = trunc i200 %shift5_1 to i64
 %out5_1 = getelementptr i8,ptr %out,i64 136
 store i64 %word5_1,ptr %out5_1,align 1
 %shift5_2 = lshr i200 %r5,128
 %word5_2 = trunc i200 %shift5_2 to i64
 %out5_2 = getelementptr i8,ptr %out,i64 144
 store i64 %word5_2,ptr %out5_2,align 1
 %shift5_3 = lshr i200 %r5,192
 %word5_3 = trunc i200 %shift5_3 to i64
 %out5_3 = getelementptr i8,ptr %out,i64 152
 store i64 %word5_3,ptr %out5_3,align 1
 %mp = getelementptr i8,ptr %out,i64 160
 store i64 %mask,ptr %mp,align 1
 %op = getelementptr i8,ptr %out,i64 168
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %mask,%token
 ret i64 %answer
}
define i64 @wide_saturation_vector_probe_25(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %temporary = alloca [160 x i8],align 16
 %constant = alloca i140,align 16
 store i140 1267650600228229401496703205376,ptr %constant,align 16
 %bp = getelementptr i8,ptr %input,i64 32
 %sp = getelementptr i8,ptr %input,i64 64
 %s0 = load i64,ptr %sp,align 1
 %tp = getelementptr i8,ptr %input,i64 72
 %t0 = load i64,ptr %tp,align 1
 %temporary0 = getelementptr i8,ptr %temporary,i64 0
 call void @wide_sat_140_u_1(ptr %temporary0,ptr %input,i64 %s0)
 %temporary1 = getelementptr i8,ptr %temporary,i64 24
 call void @wide_sat_140_s_1(ptr %temporary1,ptr %input,i64 %s0)
 %temporary2 = getelementptr i8,ptr %temporary,i64 48
 call void @wide_sat_140_u_1(ptr %temporary2,ptr %constant,i64 %s0)
 %temporary3 = getelementptr i8,ptr %temporary,i64 72
 call void @wide_sat_140_s_1(ptr %temporary3,ptr %constant,i64 %s0)
 %temporary4 = getelementptr i8,ptr %temporary,i64 96
 call void @wide_sat_200_u_1(ptr %temporary4,ptr %bp,i64 %t0)
 %temporary5 = getelementptr i8,ptr %temporary,i64 128
 call void @wide_sat_200_s_1(ptr %temporary5,ptr %bp,i64 %t0)
 %r0 = load i140,ptr %temporary0,align 1
 %r1 = load i140,ptr %temporary1,align 1
 %r2 = load i140,ptr %temporary2,align 1
 %r3 = load i140,ptr %temporary3,align 1
 %r4 = load i200,ptr %temporary4,align 1
 %r5 = load i200,ptr %temporary5,align 1
 %v0 = insertelement <4 x i140> poison,i140 %r0,i64 0
 %v1 = insertelement <4 x i140> %v0,i140 %r1,i64 1
 %v2 = insertelement <4 x i140> %v1,i140 %r2,i64 2
 %v3 = insertelement <4 x i140> %v2,i140 %r3,i64 3
 %cmp = icmp ult <4 x i140> %v3,<i140 0,i140 -1,i140 696898287454081973172991196020261297061887,i140 -696898287454081973172991196020261297061888>
 %packed_mask = bitcast <4 x i1> %cmp to i4
 %mask = zext i4 %packed_mask to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %word0_0 = trunc i140 %r0 to i64
 %out0_0 = getelementptr i8,ptr %out,i64 0
 store i64 %word0_0,ptr %out0_0,align 1
 %shift0_1 = lshr i140 %r0,64
 %word0_1 = trunc i140 %shift0_1 to i64
 %out0_1 = getelementptr i8,ptr %out,i64 8
 store i64 %word0_1,ptr %out0_1,align 1
 %shift0_2 = lshr i140 %r0,128
 %word0_2 = trunc i140 %shift0_2 to i64
 %out0_2 = getelementptr i8,ptr %out,i64 16
 store i64 %word0_2,ptr %out0_2,align 1
 %word1_0 = trunc i140 %r1 to i64
 %out1_0 = getelementptr i8,ptr %out,i64 24
 store i64 %word1_0,ptr %out1_0,align 1
 %shift1_1 = lshr i140 %r1,64
 %word1_1 = trunc i140 %shift1_1 to i64
 %out1_1 = getelementptr i8,ptr %out,i64 32
 store i64 %word1_1,ptr %out1_1,align 1
 %shift1_2 = lshr i140 %r1,128
 %word1_2 = trunc i140 %shift1_2 to i64
 %out1_2 = getelementptr i8,ptr %out,i64 40
 store i64 %word1_2,ptr %out1_2,align 1
 %word2_0 = trunc i140 %r2 to i64
 %out2_0 = getelementptr i8,ptr %out,i64 48
 store i64 %word2_0,ptr %out2_0,align 1
 %shift2_1 = lshr i140 %r2,64
 %word2_1 = trunc i140 %shift2_1 to i64
 %out2_1 = getelementptr i8,ptr %out,i64 56
 store i64 %word2_1,ptr %out2_1,align 1
 %shift2_2 = lshr i140 %r2,128
 %word2_2 = trunc i140 %shift2_2 to i64
 %out2_2 = getelementptr i8,ptr %out,i64 64
 store i64 %word2_2,ptr %out2_2,align 1
 %word3_0 = trunc i140 %r3 to i64
 %out3_0 = getelementptr i8,ptr %out,i64 72
 store i64 %word3_0,ptr %out3_0,align 1
 %shift3_1 = lshr i140 %r3,64
 %word3_1 = trunc i140 %shift3_1 to i64
 %out3_1 = getelementptr i8,ptr %out,i64 80
 store i64 %word3_1,ptr %out3_1,align 1
 %shift3_2 = lshr i140 %r3,128
 %word3_2 = trunc i140 %shift3_2 to i64
 %out3_2 = getelementptr i8,ptr %out,i64 88
 store i64 %word3_2,ptr %out3_2,align 1
 %word4_0 = trunc i200 %r4 to i64
 %out4_0 = getelementptr i8,ptr %out,i64 96
 store i64 %word4_0,ptr %out4_0,align 1
 %shift4_1 = lshr i200 %r4,64
 %word4_1 = trunc i200 %shift4_1 to i64
 %out4_1 = getelementptr i8,ptr %out,i64 104
 store i64 %word4_1,ptr %out4_1,align 1
 %shift4_2 = lshr i200 %r4,128
 %word4_2 = trunc i200 %shift4_2 to i64
 %out4_2 = getelementptr i8,ptr %out,i64 112
 store i64 %word4_2,ptr %out4_2,align 1
 %shift4_3 = lshr i200 %r4,192
 %word4_3 = trunc i200 %shift4_3 to i64
 %out4_3 = getelementptr i8,ptr %out,i64 120
 store i64 %word4_3,ptr %out4_3,align 1
 %word5_0 = trunc i200 %r5 to i64
 %out5_0 = getelementptr i8,ptr %out,i64 128
 store i64 %word5_0,ptr %out5_0,align 1
 %shift5_1 = lshr i200 %r5,64
 %word5_1 = trunc i200 %shift5_1 to i64
 %out5_1 = getelementptr i8,ptr %out,i64 136
 store i64 %word5_1,ptr %out5_1,align 1
 %shift5_2 = lshr i200 %r5,128
 %word5_2 = trunc i200 %shift5_2 to i64
 %out5_2 = getelementptr i8,ptr %out,i64 144
 store i64 %word5_2,ptr %out5_2,align 1
 %shift5_3 = lshr i200 %r5,192
 %word5_3 = trunc i200 %shift5_3 to i64
 %out5_3 = getelementptr i8,ptr %out,i64 152
 store i64 %word5_3,ptr %out5_3,align 1
 %mp = getelementptr i8,ptr %out,i64 160
 store i64 %mask,ptr %mp,align 1
 %op = getelementptr i8,ptr %out,i64 168
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %mask,%token
 ret i64 %answer
}
define i64 @wide_saturation_vector_probe_26(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %temporary = alloca [160 x i8],align 16
 %constant = alloca i140,align 16
 store i140 1267650600228229401496703205376,ptr %constant,align 16
 %bp = getelementptr i8,ptr %input,i64 32
 %sp = getelementptr i8,ptr %input,i64 64
 %s0 = load i64,ptr %sp,align 1
 %tp = getelementptr i8,ptr %input,i64 72
 %t0 = load i64,ptr %tp,align 1
 %temporary0 = getelementptr i8,ptr %temporary,i64 0
 call void @wide_sat_140_u_2(ptr %temporary0,ptr %input,i64 %s0)
 %temporary1 = getelementptr i8,ptr %temporary,i64 24
 call void @wide_sat_140_s_2(ptr %temporary1,ptr %input,i64 %s0)
 %temporary2 = getelementptr i8,ptr %temporary,i64 48
 call void @wide_sat_140_u_2(ptr %temporary2,ptr %constant,i64 %s0)
 %temporary3 = getelementptr i8,ptr %temporary,i64 72
 call void @wide_sat_140_s_2(ptr %temporary3,ptr %constant,i64 %s0)
 %temporary4 = getelementptr i8,ptr %temporary,i64 96
 call void @wide_sat_200_u_2(ptr %temporary4,ptr %bp,i64 %t0)
 %temporary5 = getelementptr i8,ptr %temporary,i64 128
 call void @wide_sat_200_s_2(ptr %temporary5,ptr %bp,i64 %t0)
 %r0 = load i140,ptr %temporary0,align 1
 %r1 = load i140,ptr %temporary1,align 1
 %r2 = load i140,ptr %temporary2,align 1
 %r3 = load i140,ptr %temporary3,align 1
 %r4 = load i200,ptr %temporary4,align 1
 %r5 = load i200,ptr %temporary5,align 1
 %v0 = insertelement <4 x i140> poison,i140 %r0,i64 0
 %v1 = insertelement <4 x i140> %v0,i140 %r1,i64 1
 %v2 = insertelement <4 x i140> %v1,i140 %r2,i64 2
 %v3 = insertelement <4 x i140> %v2,i140 %r3,i64 3
 %cmp = icmp ult <4 x i140> %v3,<i140 0,i140 -1,i140 696898287454081973172991196020261297061887,i140 -696898287454081973172991196020261297061888>
 %packed_mask = bitcast <4 x i1> %cmp to i4
 %mask = zext i4 %packed_mask to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %word0_0 = trunc i140 %r0 to i64
 %out0_0 = getelementptr i8,ptr %out,i64 0
 store i64 %word0_0,ptr %out0_0,align 1
 %shift0_1 = lshr i140 %r0,64
 %word0_1 = trunc i140 %shift0_1 to i64
 %out0_1 = getelementptr i8,ptr %out,i64 8
 store i64 %word0_1,ptr %out0_1,align 1
 %shift0_2 = lshr i140 %r0,128
 %word0_2 = trunc i140 %shift0_2 to i64
 %out0_2 = getelementptr i8,ptr %out,i64 16
 store i64 %word0_2,ptr %out0_2,align 1
 %word1_0 = trunc i140 %r1 to i64
 %out1_0 = getelementptr i8,ptr %out,i64 24
 store i64 %word1_0,ptr %out1_0,align 1
 %shift1_1 = lshr i140 %r1,64
 %word1_1 = trunc i140 %shift1_1 to i64
 %out1_1 = getelementptr i8,ptr %out,i64 32
 store i64 %word1_1,ptr %out1_1,align 1
 %shift1_2 = lshr i140 %r1,128
 %word1_2 = trunc i140 %shift1_2 to i64
 %out1_2 = getelementptr i8,ptr %out,i64 40
 store i64 %word1_2,ptr %out1_2,align 1
 %word2_0 = trunc i140 %r2 to i64
 %out2_0 = getelementptr i8,ptr %out,i64 48
 store i64 %word2_0,ptr %out2_0,align 1
 %shift2_1 = lshr i140 %r2,64
 %word2_1 = trunc i140 %shift2_1 to i64
 %out2_1 = getelementptr i8,ptr %out,i64 56
 store i64 %word2_1,ptr %out2_1,align 1
 %shift2_2 = lshr i140 %r2,128
 %word2_2 = trunc i140 %shift2_2 to i64
 %out2_2 = getelementptr i8,ptr %out,i64 64
 store i64 %word2_2,ptr %out2_2,align 1
 %word3_0 = trunc i140 %r3 to i64
 %out3_0 = getelementptr i8,ptr %out,i64 72
 store i64 %word3_0,ptr %out3_0,align 1
 %shift3_1 = lshr i140 %r3,64
 %word3_1 = trunc i140 %shift3_1 to i64
 %out3_1 = getelementptr i8,ptr %out,i64 80
 store i64 %word3_1,ptr %out3_1,align 1
 %shift3_2 = lshr i140 %r3,128
 %word3_2 = trunc i140 %shift3_2 to i64
 %out3_2 = getelementptr i8,ptr %out,i64 88
 store i64 %word3_2,ptr %out3_2,align 1
 %word4_0 = trunc i200 %r4 to i64
 %out4_0 = getelementptr i8,ptr %out,i64 96
 store i64 %word4_0,ptr %out4_0,align 1
 %shift4_1 = lshr i200 %r4,64
 %word4_1 = trunc i200 %shift4_1 to i64
 %out4_1 = getelementptr i8,ptr %out,i64 104
 store i64 %word4_1,ptr %out4_1,align 1
 %shift4_2 = lshr i200 %r4,128
 %word4_2 = trunc i200 %shift4_2 to i64
 %out4_2 = getelementptr i8,ptr %out,i64 112
 store i64 %word4_2,ptr %out4_2,align 1
 %shift4_3 = lshr i200 %r4,192
 %word4_3 = trunc i200 %shift4_3 to i64
 %out4_3 = getelementptr i8,ptr %out,i64 120
 store i64 %word4_3,ptr %out4_3,align 1
 %word5_0 = trunc i200 %r5 to i64
 %out5_0 = getelementptr i8,ptr %out,i64 128
 store i64 %word5_0,ptr %out5_0,align 1
 %shift5_1 = lshr i200 %r5,64
 %word5_1 = trunc i200 %shift5_1 to i64
 %out5_1 = getelementptr i8,ptr %out,i64 136
 store i64 %word5_1,ptr %out5_1,align 1
 %shift5_2 = lshr i200 %r5,128
 %word5_2 = trunc i200 %shift5_2 to i64
 %out5_2 = getelementptr i8,ptr %out,i64 144
 store i64 %word5_2,ptr %out5_2,align 1
 %shift5_3 = lshr i200 %r5,192
 %word5_3 = trunc i200 %shift5_3 to i64
 %out5_3 = getelementptr i8,ptr %out,i64 152
 store i64 %word5_3,ptr %out5_3,align 1
 %mp = getelementptr i8,ptr %out,i64 160
 store i64 %mask,ptr %mp,align 1
 %op = getelementptr i8,ptr %out,i64 168
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %mask,%token
 ret i64 %answer
}
define i64 @wide_saturation_vector_probe_27(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %temporary = alloca [160 x i8],align 16
 %constant = alloca i140,align 16
 store i140 1267650600228229401496703205376,ptr %constant,align 16
 %bp = getelementptr i8,ptr %input,i64 32
 %sp = getelementptr i8,ptr %input,i64 64
 %s0 = load i64,ptr %sp,align 1
 %tp = getelementptr i8,ptr %input,i64 72
 %t0 = load i64,ptr %tp,align 1
 %temporary0 = getelementptr i8,ptr %temporary,i64 0
 call void @wide_sat_140_u_0(ptr %temporary0,ptr %input,i64 %s0)
 %temporary1 = getelementptr i8,ptr %temporary,i64 24
 call void @wide_sat_140_s_0(ptr %temporary1,ptr %input,i64 %s0)
 %temporary2 = getelementptr i8,ptr %temporary,i64 48
 call void @wide_sat_140_u_0(ptr %temporary2,ptr %constant,i64 %s0)
 %temporary3 = getelementptr i8,ptr %temporary,i64 72
 call void @wide_sat_140_s_0(ptr %temporary3,ptr %constant,i64 %s0)
 %temporary4 = getelementptr i8,ptr %temporary,i64 96
 call void @wide_sat_200_u_0(ptr %temporary4,ptr %bp,i64 %t0)
 %temporary5 = getelementptr i8,ptr %temporary,i64 128
 call void @wide_sat_200_s_0(ptr %temporary5,ptr %bp,i64 %t0)
 %r0 = load i140,ptr %temporary0,align 1
 %r1 = load i140,ptr %temporary1,align 1
 %r2 = load i140,ptr %temporary2,align 1
 %r3 = load i140,ptr %temporary3,align 1
 %r4 = load i200,ptr %temporary4,align 1
 %r5 = load i200,ptr %temporary5,align 1
 %v0 = insertelement <4 x i140> poison,i140 %r0,i64 0
 %v1 = insertelement <4 x i140> %v0,i140 %r1,i64 1
 %v2 = insertelement <4 x i140> %v1,i140 %r2,i64 2
 %v3 = insertelement <4 x i140> %v2,i140 %r3,i64 3
 %w0 = insertelement <4 x i140> poison,i140 0,i32 0
 %w1 = insertelement <4 x i140> %w0,i140 -1,i32 1
 %w2 = insertelement <4 x i140> %w1,i140 696898287454081973172991196020261297061887,i32 2
 %w3 = insertelement <4 x i140> %w2,i140 -696898287454081973172991196020261297061888,i32 3
 %cmp = icmp ult <4 x i140> %v3,%w3
 %packed_mask = bitcast <4 x i1> %cmp to i4
 %mask = zext i4 %packed_mask to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %word0_0 = trunc i140 %r0 to i64
 %out0_0 = getelementptr i8,ptr %out,i64 0
 store i64 %word0_0,ptr %out0_0,align 1
 %shift0_1 = lshr i140 %r0,64
 %word0_1 = trunc i140 %shift0_1 to i64
 %out0_1 = getelementptr i8,ptr %out,i64 8
 store i64 %word0_1,ptr %out0_1,align 1
 %shift0_2 = lshr i140 %r0,128
 %word0_2 = trunc i140 %shift0_2 to i64
 %out0_2 = getelementptr i8,ptr %out,i64 16
 store i64 %word0_2,ptr %out0_2,align 1
 %word1_0 = trunc i140 %r1 to i64
 %out1_0 = getelementptr i8,ptr %out,i64 24
 store i64 %word1_0,ptr %out1_0,align 1
 %shift1_1 = lshr i140 %r1,64
 %word1_1 = trunc i140 %shift1_1 to i64
 %out1_1 = getelementptr i8,ptr %out,i64 32
 store i64 %word1_1,ptr %out1_1,align 1
 %shift1_2 = lshr i140 %r1,128
 %word1_2 = trunc i140 %shift1_2 to i64
 %out1_2 = getelementptr i8,ptr %out,i64 40
 store i64 %word1_2,ptr %out1_2,align 1
 %word2_0 = trunc i140 %r2 to i64
 %out2_0 = getelementptr i8,ptr %out,i64 48
 store i64 %word2_0,ptr %out2_0,align 1
 %shift2_1 = lshr i140 %r2,64
 %word2_1 = trunc i140 %shift2_1 to i64
 %out2_1 = getelementptr i8,ptr %out,i64 56
 store i64 %word2_1,ptr %out2_1,align 1
 %shift2_2 = lshr i140 %r2,128
 %word2_2 = trunc i140 %shift2_2 to i64
 %out2_2 = getelementptr i8,ptr %out,i64 64
 store i64 %word2_2,ptr %out2_2,align 1
 %word3_0 = trunc i140 %r3 to i64
 %out3_0 = getelementptr i8,ptr %out,i64 72
 store i64 %word3_0,ptr %out3_0,align 1
 %shift3_1 = lshr i140 %r3,64
 %word3_1 = trunc i140 %shift3_1 to i64
 %out3_1 = getelementptr i8,ptr %out,i64 80
 store i64 %word3_1,ptr %out3_1,align 1
 %shift3_2 = lshr i140 %r3,128
 %word3_2 = trunc i140 %shift3_2 to i64
 %out3_2 = getelementptr i8,ptr %out,i64 88
 store i64 %word3_2,ptr %out3_2,align 1
 %word4_0 = trunc i200 %r4 to i64
 %out4_0 = getelementptr i8,ptr %out,i64 96
 store i64 %word4_0,ptr %out4_0,align 1
 %shift4_1 = lshr i200 %r4,64
 %word4_1 = trunc i200 %shift4_1 to i64
 %out4_1 = getelementptr i8,ptr %out,i64 104
 store i64 %word4_1,ptr %out4_1,align 1
 %shift4_2 = lshr i200 %r4,128
 %word4_2 = trunc i200 %shift4_2 to i64
 %out4_2 = getelementptr i8,ptr %out,i64 112
 store i64 %word4_2,ptr %out4_2,align 1
 %shift4_3 = lshr i200 %r4,192
 %word4_3 = trunc i200 %shift4_3 to i64
 %out4_3 = getelementptr i8,ptr %out,i64 120
 store i64 %word4_3,ptr %out4_3,align 1
 %word5_0 = trunc i200 %r5 to i64
 %out5_0 = getelementptr i8,ptr %out,i64 128
 store i64 %word5_0,ptr %out5_0,align 1
 %shift5_1 = lshr i200 %r5,64
 %word5_1 = trunc i200 %shift5_1 to i64
 %out5_1 = getelementptr i8,ptr %out,i64 136
 store i64 %word5_1,ptr %out5_1,align 1
 %shift5_2 = lshr i200 %r5,128
 %word5_2 = trunc i200 %shift5_2 to i64
 %out5_2 = getelementptr i8,ptr %out,i64 144
 store i64 %word5_2,ptr %out5_2,align 1
 %shift5_3 = lshr i200 %r5,192
 %word5_3 = trunc i200 %shift5_3 to i64
 %out5_3 = getelementptr i8,ptr %out,i64 152
 store i64 %word5_3,ptr %out5_3,align 1
 %mp = getelementptr i8,ptr %out,i64 160
 store i64 %mask,ptr %mp,align 1
 %op = getelementptr i8,ptr %out,i64 168
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %mask,%token
 ret i64 %answer
}
define i64 @wide_saturation_vector_probe_28(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %temporary = alloca [160 x i8],align 16
 %constant = alloca i140,align 16
 store i140 1267650600228229401496703205376,ptr %constant,align 16
 %bp = getelementptr i8,ptr %input,i64 32
 %sp = getelementptr i8,ptr %input,i64 64
 %s0 = load i64,ptr %sp,align 1
 %tp = getelementptr i8,ptr %input,i64 72
 %t0 = load i64,ptr %tp,align 1
 %temporary0 = getelementptr i8,ptr %temporary,i64 0
 call void @wide_sat_140_u_1(ptr %temporary0,ptr %input,i64 %s0)
 %temporary1 = getelementptr i8,ptr %temporary,i64 24
 call void @wide_sat_140_s_1(ptr %temporary1,ptr %input,i64 %s0)
 %temporary2 = getelementptr i8,ptr %temporary,i64 48
 call void @wide_sat_140_u_1(ptr %temporary2,ptr %constant,i64 %s0)
 %temporary3 = getelementptr i8,ptr %temporary,i64 72
 call void @wide_sat_140_s_1(ptr %temporary3,ptr %constant,i64 %s0)
 %temporary4 = getelementptr i8,ptr %temporary,i64 96
 call void @wide_sat_200_u_1(ptr %temporary4,ptr %bp,i64 %t0)
 %temporary5 = getelementptr i8,ptr %temporary,i64 128
 call void @wide_sat_200_s_1(ptr %temporary5,ptr %bp,i64 %t0)
 %r0 = load i140,ptr %temporary0,align 1
 %r1 = load i140,ptr %temporary1,align 1
 %r2 = load i140,ptr %temporary2,align 1
 %r3 = load i140,ptr %temporary3,align 1
 %r4 = load i200,ptr %temporary4,align 1
 %r5 = load i200,ptr %temporary5,align 1
 %v0 = insertelement <4 x i140> poison,i140 %r0,i64 0
 %v1 = insertelement <4 x i140> %v0,i140 %r1,i64 1
 %v2 = insertelement <4 x i140> %v1,i140 %r2,i64 2
 %v3 = insertelement <4 x i140> %v2,i140 %r3,i64 3
 %w0 = insertelement <4 x i140> poison,i140 0,i32 0
 %w1 = insertelement <4 x i140> %w0,i140 -1,i32 1
 %w2 = insertelement <4 x i140> %w1,i140 696898287454081973172991196020261297061887,i32 2
 %w3 = insertelement <4 x i140> %w2,i140 -696898287454081973172991196020261297061888,i32 3
 %cmp = icmp ult <4 x i140> %v3,%w3
 %packed_mask = bitcast <4 x i1> %cmp to i4
 %mask = zext i4 %packed_mask to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %word0_0 = trunc i140 %r0 to i64
 %out0_0 = getelementptr i8,ptr %out,i64 0
 store i64 %word0_0,ptr %out0_0,align 1
 %shift0_1 = lshr i140 %r0,64
 %word0_1 = trunc i140 %shift0_1 to i64
 %out0_1 = getelementptr i8,ptr %out,i64 8
 store i64 %word0_1,ptr %out0_1,align 1
 %shift0_2 = lshr i140 %r0,128
 %word0_2 = trunc i140 %shift0_2 to i64
 %out0_2 = getelementptr i8,ptr %out,i64 16
 store i64 %word0_2,ptr %out0_2,align 1
 %word1_0 = trunc i140 %r1 to i64
 %out1_0 = getelementptr i8,ptr %out,i64 24
 store i64 %word1_0,ptr %out1_0,align 1
 %shift1_1 = lshr i140 %r1,64
 %word1_1 = trunc i140 %shift1_1 to i64
 %out1_1 = getelementptr i8,ptr %out,i64 32
 store i64 %word1_1,ptr %out1_1,align 1
 %shift1_2 = lshr i140 %r1,128
 %word1_2 = trunc i140 %shift1_2 to i64
 %out1_2 = getelementptr i8,ptr %out,i64 40
 store i64 %word1_2,ptr %out1_2,align 1
 %word2_0 = trunc i140 %r2 to i64
 %out2_0 = getelementptr i8,ptr %out,i64 48
 store i64 %word2_0,ptr %out2_0,align 1
 %shift2_1 = lshr i140 %r2,64
 %word2_1 = trunc i140 %shift2_1 to i64
 %out2_1 = getelementptr i8,ptr %out,i64 56
 store i64 %word2_1,ptr %out2_1,align 1
 %shift2_2 = lshr i140 %r2,128
 %word2_2 = trunc i140 %shift2_2 to i64
 %out2_2 = getelementptr i8,ptr %out,i64 64
 store i64 %word2_2,ptr %out2_2,align 1
 %word3_0 = trunc i140 %r3 to i64
 %out3_0 = getelementptr i8,ptr %out,i64 72
 store i64 %word3_0,ptr %out3_0,align 1
 %shift3_1 = lshr i140 %r3,64
 %word3_1 = trunc i140 %shift3_1 to i64
 %out3_1 = getelementptr i8,ptr %out,i64 80
 store i64 %word3_1,ptr %out3_1,align 1
 %shift3_2 = lshr i140 %r3,128
 %word3_2 = trunc i140 %shift3_2 to i64
 %out3_2 = getelementptr i8,ptr %out,i64 88
 store i64 %word3_2,ptr %out3_2,align 1
 %word4_0 = trunc i200 %r4 to i64
 %out4_0 = getelementptr i8,ptr %out,i64 96
 store i64 %word4_0,ptr %out4_0,align 1
 %shift4_1 = lshr i200 %r4,64
 %word4_1 = trunc i200 %shift4_1 to i64
 %out4_1 = getelementptr i8,ptr %out,i64 104
 store i64 %word4_1,ptr %out4_1,align 1
 %shift4_2 = lshr i200 %r4,128
 %word4_2 = trunc i200 %shift4_2 to i64
 %out4_2 = getelementptr i8,ptr %out,i64 112
 store i64 %word4_2,ptr %out4_2,align 1
 %shift4_3 = lshr i200 %r4,192
 %word4_3 = trunc i200 %shift4_3 to i64
 %out4_3 = getelementptr i8,ptr %out,i64 120
 store i64 %word4_3,ptr %out4_3,align 1
 %word5_0 = trunc i200 %r5 to i64
 %out5_0 = getelementptr i8,ptr %out,i64 128
 store i64 %word5_0,ptr %out5_0,align 1
 %shift5_1 = lshr i200 %r5,64
 %word5_1 = trunc i200 %shift5_1 to i64
 %out5_1 = getelementptr i8,ptr %out,i64 136
 store i64 %word5_1,ptr %out5_1,align 1
 %shift5_2 = lshr i200 %r5,128
 %word5_2 = trunc i200 %shift5_2 to i64
 %out5_2 = getelementptr i8,ptr %out,i64 144
 store i64 %word5_2,ptr %out5_2,align 1
 %shift5_3 = lshr i200 %r5,192
 %word5_3 = trunc i200 %shift5_3 to i64
 %out5_3 = getelementptr i8,ptr %out,i64 152
 store i64 %word5_3,ptr %out5_3,align 1
 %mp = getelementptr i8,ptr %out,i64 160
 store i64 %mask,ptr %mp,align 1
 %op = getelementptr i8,ptr %out,i64 168
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %mask,%token
 ret i64 %answer
}
define i64 @wide_saturation_vector_probe_29(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %temporary = alloca [160 x i8],align 16
 %constant = alloca i140,align 16
 store i140 1267650600228229401496703205376,ptr %constant,align 16
 %bp = getelementptr i8,ptr %input,i64 32
 %sp = getelementptr i8,ptr %input,i64 64
 %s0 = load i64,ptr %sp,align 1
 %tp = getelementptr i8,ptr %input,i64 72
 %t0 = load i64,ptr %tp,align 1
 %temporary0 = getelementptr i8,ptr %temporary,i64 0
 call void @wide_sat_140_u_2(ptr %temporary0,ptr %input,i64 %s0)
 %temporary1 = getelementptr i8,ptr %temporary,i64 24
 call void @wide_sat_140_s_2(ptr %temporary1,ptr %input,i64 %s0)
 %temporary2 = getelementptr i8,ptr %temporary,i64 48
 call void @wide_sat_140_u_2(ptr %temporary2,ptr %constant,i64 %s0)
 %temporary3 = getelementptr i8,ptr %temporary,i64 72
 call void @wide_sat_140_s_2(ptr %temporary3,ptr %constant,i64 %s0)
 %temporary4 = getelementptr i8,ptr %temporary,i64 96
 call void @wide_sat_200_u_2(ptr %temporary4,ptr %bp,i64 %t0)
 %temporary5 = getelementptr i8,ptr %temporary,i64 128
 call void @wide_sat_200_s_2(ptr %temporary5,ptr %bp,i64 %t0)
 %r0 = load i140,ptr %temporary0,align 1
 %r1 = load i140,ptr %temporary1,align 1
 %r2 = load i140,ptr %temporary2,align 1
 %r3 = load i140,ptr %temporary3,align 1
 %r4 = load i200,ptr %temporary4,align 1
 %r5 = load i200,ptr %temporary5,align 1
 %v0 = insertelement <4 x i140> poison,i140 %r0,i64 0
 %v1 = insertelement <4 x i140> %v0,i140 %r1,i64 1
 %v2 = insertelement <4 x i140> %v1,i140 %r2,i64 2
 %v3 = insertelement <4 x i140> %v2,i140 %r3,i64 3
 %w0 = insertelement <4 x i140> poison,i140 0,i32 0
 %w1 = insertelement <4 x i140> %w0,i140 -1,i32 1
 %w2 = insertelement <4 x i140> %w1,i140 696898287454081973172991196020261297061887,i32 2
 %w3 = insertelement <4 x i140> %w2,i140 -696898287454081973172991196020261297061888,i32 3
 %cmp = icmp ult <4 x i140> %v3,%w3
 %packed_mask = bitcast <4 x i1> %cmp to i4
 %mask = zext i4 %packed_mask to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %word0_0 = trunc i140 %r0 to i64
 %out0_0 = getelementptr i8,ptr %out,i64 0
 store i64 %word0_0,ptr %out0_0,align 1
 %shift0_1 = lshr i140 %r0,64
 %word0_1 = trunc i140 %shift0_1 to i64
 %out0_1 = getelementptr i8,ptr %out,i64 8
 store i64 %word0_1,ptr %out0_1,align 1
 %shift0_2 = lshr i140 %r0,128
 %word0_2 = trunc i140 %shift0_2 to i64
 %out0_2 = getelementptr i8,ptr %out,i64 16
 store i64 %word0_2,ptr %out0_2,align 1
 %word1_0 = trunc i140 %r1 to i64
 %out1_0 = getelementptr i8,ptr %out,i64 24
 store i64 %word1_0,ptr %out1_0,align 1
 %shift1_1 = lshr i140 %r1,64
 %word1_1 = trunc i140 %shift1_1 to i64
 %out1_1 = getelementptr i8,ptr %out,i64 32
 store i64 %word1_1,ptr %out1_1,align 1
 %shift1_2 = lshr i140 %r1,128
 %word1_2 = trunc i140 %shift1_2 to i64
 %out1_2 = getelementptr i8,ptr %out,i64 40
 store i64 %word1_2,ptr %out1_2,align 1
 %word2_0 = trunc i140 %r2 to i64
 %out2_0 = getelementptr i8,ptr %out,i64 48
 store i64 %word2_0,ptr %out2_0,align 1
 %shift2_1 = lshr i140 %r2,64
 %word2_1 = trunc i140 %shift2_1 to i64
 %out2_1 = getelementptr i8,ptr %out,i64 56
 store i64 %word2_1,ptr %out2_1,align 1
 %shift2_2 = lshr i140 %r2,128
 %word2_2 = trunc i140 %shift2_2 to i64
 %out2_2 = getelementptr i8,ptr %out,i64 64
 store i64 %word2_2,ptr %out2_2,align 1
 %word3_0 = trunc i140 %r3 to i64
 %out3_0 = getelementptr i8,ptr %out,i64 72
 store i64 %word3_0,ptr %out3_0,align 1
 %shift3_1 = lshr i140 %r3,64
 %word3_1 = trunc i140 %shift3_1 to i64
 %out3_1 = getelementptr i8,ptr %out,i64 80
 store i64 %word3_1,ptr %out3_1,align 1
 %shift3_2 = lshr i140 %r3,128
 %word3_2 = trunc i140 %shift3_2 to i64
 %out3_2 = getelementptr i8,ptr %out,i64 88
 store i64 %word3_2,ptr %out3_2,align 1
 %word4_0 = trunc i200 %r4 to i64
 %out4_0 = getelementptr i8,ptr %out,i64 96
 store i64 %word4_0,ptr %out4_0,align 1
 %shift4_1 = lshr i200 %r4,64
 %word4_1 = trunc i200 %shift4_1 to i64
 %out4_1 = getelementptr i8,ptr %out,i64 104
 store i64 %word4_1,ptr %out4_1,align 1
 %shift4_2 = lshr i200 %r4,128
 %word4_2 = trunc i200 %shift4_2 to i64
 %out4_2 = getelementptr i8,ptr %out,i64 112
 store i64 %word4_2,ptr %out4_2,align 1
 %shift4_3 = lshr i200 %r4,192
 %word4_3 = trunc i200 %shift4_3 to i64
 %out4_3 = getelementptr i8,ptr %out,i64 120
 store i64 %word4_3,ptr %out4_3,align 1
 %word5_0 = trunc i200 %r5 to i64
 %out5_0 = getelementptr i8,ptr %out,i64 128
 store i64 %word5_0,ptr %out5_0,align 1
 %shift5_1 = lshr i200 %r5,64
 %word5_1 = trunc i200 %shift5_1 to i64
 %out5_1 = getelementptr i8,ptr %out,i64 136
 store i64 %word5_1,ptr %out5_1,align 1
 %shift5_2 = lshr i200 %r5,128
 %word5_2 = trunc i200 %shift5_2 to i64
 %out5_2 = getelementptr i8,ptr %out,i64 144
 store i64 %word5_2,ptr %out5_2,align 1
 %shift5_3 = lshr i200 %r5,192
 %word5_3 = trunc i200 %shift5_3 to i64
 %out5_3 = getelementptr i8,ptr %out,i64 152
 store i64 %word5_3,ptr %out5_3,align 1
 %mp = getelementptr i8,ptr %out,i64 160
 store i64 %mask,ptr %mp,align 1
 %op = getelementptr i8,ptr %out,i64 168
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %mask,%token
 ret i64 %answer
}
define i64 @wide_saturation_vector_probe_30(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %temporary = alloca [160 x i8],align 16
 %constant = alloca i140,align 16
 store i140 1267650600228229401496703205376,ptr %constant,align 16
 %bp = getelementptr i8,ptr %input,i64 32
 %sp = getelementptr i8,ptr %input,i64 64
 %s0 = load i64,ptr %sp,align 1
 %tp = getelementptr i8,ptr %input,i64 72
 %t0 = load i64,ptr %tp,align 1
 %temporary0 = getelementptr i8,ptr %temporary,i64 0
 call void @wide_sat_140_u_0(ptr %temporary0,ptr %input,i64 %s0)
 %temporary1 = getelementptr i8,ptr %temporary,i64 24
 call void @wide_sat_140_s_0(ptr %temporary1,ptr %input,i64 %s0)
 %temporary2 = getelementptr i8,ptr %temporary,i64 48
 call void @wide_sat_140_u_0(ptr %temporary2,ptr %constant,i64 %s0)
 %temporary3 = getelementptr i8,ptr %temporary,i64 72
 call void @wide_sat_140_s_0(ptr %temporary3,ptr %constant,i64 %s0)
 %temporary4 = getelementptr i8,ptr %temporary,i64 96
 call void @wide_sat_200_u_0(ptr %temporary4,ptr %bp,i64 %t0)
 %temporary5 = getelementptr i8,ptr %temporary,i64 128
 call void @wide_sat_200_s_0(ptr %temporary5,ptr %bp,i64 %t0)
 %r0 = load i140,ptr %temporary0,align 1
 %r1 = load i140,ptr %temporary1,align 1
 %r2 = load i140,ptr %temporary2,align 1
 %r3 = load i140,ptr %temporary3,align 1
 %r4 = load i200,ptr %temporary4,align 1
 %r5 = load i200,ptr %temporary5,align 1
 %v0 = insertelement <4 x i140> poison,i140 %r0,i64 0
 %v1 = insertelement <4 x i140> %v0,i140 %r1,i64 1
 %v2 = insertelement <4 x i140> %v1,i140 %r2,i64 2
 %v3 = insertelement <4 x i140> %v2,i140 %r3,i64 3
 %cmp = icmp ule <4 x i140> %v3,<i140 0,i140 -1,i140 696898287454081973172991196020261297061887,i140 -696898287454081973172991196020261297061888>
 %packed_mask = bitcast <4 x i1> %cmp to i4
 %mask = zext i4 %packed_mask to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %word0_0 = trunc i140 %r0 to i64
 %out0_0 = getelementptr i8,ptr %out,i64 0
 store i64 %word0_0,ptr %out0_0,align 1
 %shift0_1 = lshr i140 %r0,64
 %word0_1 = trunc i140 %shift0_1 to i64
 %out0_1 = getelementptr i8,ptr %out,i64 8
 store i64 %word0_1,ptr %out0_1,align 1
 %shift0_2 = lshr i140 %r0,128
 %word0_2 = trunc i140 %shift0_2 to i64
 %out0_2 = getelementptr i8,ptr %out,i64 16
 store i64 %word0_2,ptr %out0_2,align 1
 %word1_0 = trunc i140 %r1 to i64
 %out1_0 = getelementptr i8,ptr %out,i64 24
 store i64 %word1_0,ptr %out1_0,align 1
 %shift1_1 = lshr i140 %r1,64
 %word1_1 = trunc i140 %shift1_1 to i64
 %out1_1 = getelementptr i8,ptr %out,i64 32
 store i64 %word1_1,ptr %out1_1,align 1
 %shift1_2 = lshr i140 %r1,128
 %word1_2 = trunc i140 %shift1_2 to i64
 %out1_2 = getelementptr i8,ptr %out,i64 40
 store i64 %word1_2,ptr %out1_2,align 1
 %word2_0 = trunc i140 %r2 to i64
 %out2_0 = getelementptr i8,ptr %out,i64 48
 store i64 %word2_0,ptr %out2_0,align 1
 %shift2_1 = lshr i140 %r2,64
 %word2_1 = trunc i140 %shift2_1 to i64
 %out2_1 = getelementptr i8,ptr %out,i64 56
 store i64 %word2_1,ptr %out2_1,align 1
 %shift2_2 = lshr i140 %r2,128
 %word2_2 = trunc i140 %shift2_2 to i64
 %out2_2 = getelementptr i8,ptr %out,i64 64
 store i64 %word2_2,ptr %out2_2,align 1
 %word3_0 = trunc i140 %r3 to i64
 %out3_0 = getelementptr i8,ptr %out,i64 72
 store i64 %word3_0,ptr %out3_0,align 1
 %shift3_1 = lshr i140 %r3,64
 %word3_1 = trunc i140 %shift3_1 to i64
 %out3_1 = getelementptr i8,ptr %out,i64 80
 store i64 %word3_1,ptr %out3_1,align 1
 %shift3_2 = lshr i140 %r3,128
 %word3_2 = trunc i140 %shift3_2 to i64
 %out3_2 = getelementptr i8,ptr %out,i64 88
 store i64 %word3_2,ptr %out3_2,align 1
 %word4_0 = trunc i200 %r4 to i64
 %out4_0 = getelementptr i8,ptr %out,i64 96
 store i64 %word4_0,ptr %out4_0,align 1
 %shift4_1 = lshr i200 %r4,64
 %word4_1 = trunc i200 %shift4_1 to i64
 %out4_1 = getelementptr i8,ptr %out,i64 104
 store i64 %word4_1,ptr %out4_1,align 1
 %shift4_2 = lshr i200 %r4,128
 %word4_2 = trunc i200 %shift4_2 to i64
 %out4_2 = getelementptr i8,ptr %out,i64 112
 store i64 %word4_2,ptr %out4_2,align 1
 %shift4_3 = lshr i200 %r4,192
 %word4_3 = trunc i200 %shift4_3 to i64
 %out4_3 = getelementptr i8,ptr %out,i64 120
 store i64 %word4_3,ptr %out4_3,align 1
 %word5_0 = trunc i200 %r5 to i64
 %out5_0 = getelementptr i8,ptr %out,i64 128
 store i64 %word5_0,ptr %out5_0,align 1
 %shift5_1 = lshr i200 %r5,64
 %word5_1 = trunc i200 %shift5_1 to i64
 %out5_1 = getelementptr i8,ptr %out,i64 136
 store i64 %word5_1,ptr %out5_1,align 1
 %shift5_2 = lshr i200 %r5,128
 %word5_2 = trunc i200 %shift5_2 to i64
 %out5_2 = getelementptr i8,ptr %out,i64 144
 store i64 %word5_2,ptr %out5_2,align 1
 %shift5_3 = lshr i200 %r5,192
 %word5_3 = trunc i200 %shift5_3 to i64
 %out5_3 = getelementptr i8,ptr %out,i64 152
 store i64 %word5_3,ptr %out5_3,align 1
 %mp = getelementptr i8,ptr %out,i64 160
 store i64 %mask,ptr %mp,align 1
 %op = getelementptr i8,ptr %out,i64 168
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %mask,%token
 ret i64 %answer
}
define i64 @wide_saturation_vector_probe_31(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %temporary = alloca [160 x i8],align 16
 %constant = alloca i140,align 16
 store i140 1267650600228229401496703205376,ptr %constant,align 16
 %bp = getelementptr i8,ptr %input,i64 32
 %sp = getelementptr i8,ptr %input,i64 64
 %s0 = load i64,ptr %sp,align 1
 %tp = getelementptr i8,ptr %input,i64 72
 %t0 = load i64,ptr %tp,align 1
 %temporary0 = getelementptr i8,ptr %temporary,i64 0
 call void @wide_sat_140_u_1(ptr %temporary0,ptr %input,i64 %s0)
 %temporary1 = getelementptr i8,ptr %temporary,i64 24
 call void @wide_sat_140_s_1(ptr %temporary1,ptr %input,i64 %s0)
 %temporary2 = getelementptr i8,ptr %temporary,i64 48
 call void @wide_sat_140_u_1(ptr %temporary2,ptr %constant,i64 %s0)
 %temporary3 = getelementptr i8,ptr %temporary,i64 72
 call void @wide_sat_140_s_1(ptr %temporary3,ptr %constant,i64 %s0)
 %temporary4 = getelementptr i8,ptr %temporary,i64 96
 call void @wide_sat_200_u_1(ptr %temporary4,ptr %bp,i64 %t0)
 %temporary5 = getelementptr i8,ptr %temporary,i64 128
 call void @wide_sat_200_s_1(ptr %temporary5,ptr %bp,i64 %t0)
 %r0 = load i140,ptr %temporary0,align 1
 %r1 = load i140,ptr %temporary1,align 1
 %r2 = load i140,ptr %temporary2,align 1
 %r3 = load i140,ptr %temporary3,align 1
 %r4 = load i200,ptr %temporary4,align 1
 %r5 = load i200,ptr %temporary5,align 1
 %v0 = insertelement <4 x i140> poison,i140 %r0,i64 0
 %v1 = insertelement <4 x i140> %v0,i140 %r1,i64 1
 %v2 = insertelement <4 x i140> %v1,i140 %r2,i64 2
 %v3 = insertelement <4 x i140> %v2,i140 %r3,i64 3
 %cmp = icmp ule <4 x i140> %v3,<i140 0,i140 -1,i140 696898287454081973172991196020261297061887,i140 -696898287454081973172991196020261297061888>
 %packed_mask = bitcast <4 x i1> %cmp to i4
 %mask = zext i4 %packed_mask to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %word0_0 = trunc i140 %r0 to i64
 %out0_0 = getelementptr i8,ptr %out,i64 0
 store i64 %word0_0,ptr %out0_0,align 1
 %shift0_1 = lshr i140 %r0,64
 %word0_1 = trunc i140 %shift0_1 to i64
 %out0_1 = getelementptr i8,ptr %out,i64 8
 store i64 %word0_1,ptr %out0_1,align 1
 %shift0_2 = lshr i140 %r0,128
 %word0_2 = trunc i140 %shift0_2 to i64
 %out0_2 = getelementptr i8,ptr %out,i64 16
 store i64 %word0_2,ptr %out0_2,align 1
 %word1_0 = trunc i140 %r1 to i64
 %out1_0 = getelementptr i8,ptr %out,i64 24
 store i64 %word1_0,ptr %out1_0,align 1
 %shift1_1 = lshr i140 %r1,64
 %word1_1 = trunc i140 %shift1_1 to i64
 %out1_1 = getelementptr i8,ptr %out,i64 32
 store i64 %word1_1,ptr %out1_1,align 1
 %shift1_2 = lshr i140 %r1,128
 %word1_2 = trunc i140 %shift1_2 to i64
 %out1_2 = getelementptr i8,ptr %out,i64 40
 store i64 %word1_2,ptr %out1_2,align 1
 %word2_0 = trunc i140 %r2 to i64
 %out2_0 = getelementptr i8,ptr %out,i64 48
 store i64 %word2_0,ptr %out2_0,align 1
 %shift2_1 = lshr i140 %r2,64
 %word2_1 = trunc i140 %shift2_1 to i64
 %out2_1 = getelementptr i8,ptr %out,i64 56
 store i64 %word2_1,ptr %out2_1,align 1
 %shift2_2 = lshr i140 %r2,128
 %word2_2 = trunc i140 %shift2_2 to i64
 %out2_2 = getelementptr i8,ptr %out,i64 64
 store i64 %word2_2,ptr %out2_2,align 1
 %word3_0 = trunc i140 %r3 to i64
 %out3_0 = getelementptr i8,ptr %out,i64 72
 store i64 %word3_0,ptr %out3_0,align 1
 %shift3_1 = lshr i140 %r3,64
 %word3_1 = trunc i140 %shift3_1 to i64
 %out3_1 = getelementptr i8,ptr %out,i64 80
 store i64 %word3_1,ptr %out3_1,align 1
 %shift3_2 = lshr i140 %r3,128
 %word3_2 = trunc i140 %shift3_2 to i64
 %out3_2 = getelementptr i8,ptr %out,i64 88
 store i64 %word3_2,ptr %out3_2,align 1
 %word4_0 = trunc i200 %r4 to i64
 %out4_0 = getelementptr i8,ptr %out,i64 96
 store i64 %word4_0,ptr %out4_0,align 1
 %shift4_1 = lshr i200 %r4,64
 %word4_1 = trunc i200 %shift4_1 to i64
 %out4_1 = getelementptr i8,ptr %out,i64 104
 store i64 %word4_1,ptr %out4_1,align 1
 %shift4_2 = lshr i200 %r4,128
 %word4_2 = trunc i200 %shift4_2 to i64
 %out4_2 = getelementptr i8,ptr %out,i64 112
 store i64 %word4_2,ptr %out4_2,align 1
 %shift4_3 = lshr i200 %r4,192
 %word4_3 = trunc i200 %shift4_3 to i64
 %out4_3 = getelementptr i8,ptr %out,i64 120
 store i64 %word4_3,ptr %out4_3,align 1
 %word5_0 = trunc i200 %r5 to i64
 %out5_0 = getelementptr i8,ptr %out,i64 128
 store i64 %word5_0,ptr %out5_0,align 1
 %shift5_1 = lshr i200 %r5,64
 %word5_1 = trunc i200 %shift5_1 to i64
 %out5_1 = getelementptr i8,ptr %out,i64 136
 store i64 %word5_1,ptr %out5_1,align 1
 %shift5_2 = lshr i200 %r5,128
 %word5_2 = trunc i200 %shift5_2 to i64
 %out5_2 = getelementptr i8,ptr %out,i64 144
 store i64 %word5_2,ptr %out5_2,align 1
 %shift5_3 = lshr i200 %r5,192
 %word5_3 = trunc i200 %shift5_3 to i64
 %out5_3 = getelementptr i8,ptr %out,i64 152
 store i64 %word5_3,ptr %out5_3,align 1
 %mp = getelementptr i8,ptr %out,i64 160
 store i64 %mask,ptr %mp,align 1
 %op = getelementptr i8,ptr %out,i64 168
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %mask,%token
 ret i64 %answer
}
define i64 @wide_saturation_vector_probe_32(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %temporary = alloca [160 x i8],align 16
 %constant = alloca i140,align 16
 store i140 1267650600228229401496703205376,ptr %constant,align 16
 %bp = getelementptr i8,ptr %input,i64 32
 %sp = getelementptr i8,ptr %input,i64 64
 %s0 = load i64,ptr %sp,align 1
 %tp = getelementptr i8,ptr %input,i64 72
 %t0 = load i64,ptr %tp,align 1
 %temporary0 = getelementptr i8,ptr %temporary,i64 0
 call void @wide_sat_140_u_2(ptr %temporary0,ptr %input,i64 %s0)
 %temporary1 = getelementptr i8,ptr %temporary,i64 24
 call void @wide_sat_140_s_2(ptr %temporary1,ptr %input,i64 %s0)
 %temporary2 = getelementptr i8,ptr %temporary,i64 48
 call void @wide_sat_140_u_2(ptr %temporary2,ptr %constant,i64 %s0)
 %temporary3 = getelementptr i8,ptr %temporary,i64 72
 call void @wide_sat_140_s_2(ptr %temporary3,ptr %constant,i64 %s0)
 %temporary4 = getelementptr i8,ptr %temporary,i64 96
 call void @wide_sat_200_u_2(ptr %temporary4,ptr %bp,i64 %t0)
 %temporary5 = getelementptr i8,ptr %temporary,i64 128
 call void @wide_sat_200_s_2(ptr %temporary5,ptr %bp,i64 %t0)
 %r0 = load i140,ptr %temporary0,align 1
 %r1 = load i140,ptr %temporary1,align 1
 %r2 = load i140,ptr %temporary2,align 1
 %r3 = load i140,ptr %temporary3,align 1
 %r4 = load i200,ptr %temporary4,align 1
 %r5 = load i200,ptr %temporary5,align 1
 %v0 = insertelement <4 x i140> poison,i140 %r0,i64 0
 %v1 = insertelement <4 x i140> %v0,i140 %r1,i64 1
 %v2 = insertelement <4 x i140> %v1,i140 %r2,i64 2
 %v3 = insertelement <4 x i140> %v2,i140 %r3,i64 3
 %cmp = icmp ule <4 x i140> %v3,<i140 0,i140 -1,i140 696898287454081973172991196020261297061887,i140 -696898287454081973172991196020261297061888>
 %packed_mask = bitcast <4 x i1> %cmp to i4
 %mask = zext i4 %packed_mask to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %word0_0 = trunc i140 %r0 to i64
 %out0_0 = getelementptr i8,ptr %out,i64 0
 store i64 %word0_0,ptr %out0_0,align 1
 %shift0_1 = lshr i140 %r0,64
 %word0_1 = trunc i140 %shift0_1 to i64
 %out0_1 = getelementptr i8,ptr %out,i64 8
 store i64 %word0_1,ptr %out0_1,align 1
 %shift0_2 = lshr i140 %r0,128
 %word0_2 = trunc i140 %shift0_2 to i64
 %out0_2 = getelementptr i8,ptr %out,i64 16
 store i64 %word0_2,ptr %out0_2,align 1
 %word1_0 = trunc i140 %r1 to i64
 %out1_0 = getelementptr i8,ptr %out,i64 24
 store i64 %word1_0,ptr %out1_0,align 1
 %shift1_1 = lshr i140 %r1,64
 %word1_1 = trunc i140 %shift1_1 to i64
 %out1_1 = getelementptr i8,ptr %out,i64 32
 store i64 %word1_1,ptr %out1_1,align 1
 %shift1_2 = lshr i140 %r1,128
 %word1_2 = trunc i140 %shift1_2 to i64
 %out1_2 = getelementptr i8,ptr %out,i64 40
 store i64 %word1_2,ptr %out1_2,align 1
 %word2_0 = trunc i140 %r2 to i64
 %out2_0 = getelementptr i8,ptr %out,i64 48
 store i64 %word2_0,ptr %out2_0,align 1
 %shift2_1 = lshr i140 %r2,64
 %word2_1 = trunc i140 %shift2_1 to i64
 %out2_1 = getelementptr i8,ptr %out,i64 56
 store i64 %word2_1,ptr %out2_1,align 1
 %shift2_2 = lshr i140 %r2,128
 %word2_2 = trunc i140 %shift2_2 to i64
 %out2_2 = getelementptr i8,ptr %out,i64 64
 store i64 %word2_2,ptr %out2_2,align 1
 %word3_0 = trunc i140 %r3 to i64
 %out3_0 = getelementptr i8,ptr %out,i64 72
 store i64 %word3_0,ptr %out3_0,align 1
 %shift3_1 = lshr i140 %r3,64
 %word3_1 = trunc i140 %shift3_1 to i64
 %out3_1 = getelementptr i8,ptr %out,i64 80
 store i64 %word3_1,ptr %out3_1,align 1
 %shift3_2 = lshr i140 %r3,128
 %word3_2 = trunc i140 %shift3_2 to i64
 %out3_2 = getelementptr i8,ptr %out,i64 88
 store i64 %word3_2,ptr %out3_2,align 1
 %word4_0 = trunc i200 %r4 to i64
 %out4_0 = getelementptr i8,ptr %out,i64 96
 store i64 %word4_0,ptr %out4_0,align 1
 %shift4_1 = lshr i200 %r4,64
 %word4_1 = trunc i200 %shift4_1 to i64
 %out4_1 = getelementptr i8,ptr %out,i64 104
 store i64 %word4_1,ptr %out4_1,align 1
 %shift4_2 = lshr i200 %r4,128
 %word4_2 = trunc i200 %shift4_2 to i64
 %out4_2 = getelementptr i8,ptr %out,i64 112
 store i64 %word4_2,ptr %out4_2,align 1
 %shift4_3 = lshr i200 %r4,192
 %word4_3 = trunc i200 %shift4_3 to i64
 %out4_3 = getelementptr i8,ptr %out,i64 120
 store i64 %word4_3,ptr %out4_3,align 1
 %word5_0 = trunc i200 %r5 to i64
 %out5_0 = getelementptr i8,ptr %out,i64 128
 store i64 %word5_0,ptr %out5_0,align 1
 %shift5_1 = lshr i200 %r5,64
 %word5_1 = trunc i200 %shift5_1 to i64
 %out5_1 = getelementptr i8,ptr %out,i64 136
 store i64 %word5_1,ptr %out5_1,align 1
 %shift5_2 = lshr i200 %r5,128
 %word5_2 = trunc i200 %shift5_2 to i64
 %out5_2 = getelementptr i8,ptr %out,i64 144
 store i64 %word5_2,ptr %out5_2,align 1
 %shift5_3 = lshr i200 %r5,192
 %word5_3 = trunc i200 %shift5_3 to i64
 %out5_3 = getelementptr i8,ptr %out,i64 152
 store i64 %word5_3,ptr %out5_3,align 1
 %mp = getelementptr i8,ptr %out,i64 160
 store i64 %mask,ptr %mp,align 1
 %op = getelementptr i8,ptr %out,i64 168
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %mask,%token
 ret i64 %answer
}
define i64 @wide_saturation_vector_probe_33(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %temporary = alloca [160 x i8],align 16
 %constant = alloca i140,align 16
 store i140 1267650600228229401496703205376,ptr %constant,align 16
 %bp = getelementptr i8,ptr %input,i64 32
 %sp = getelementptr i8,ptr %input,i64 64
 %s0 = load i64,ptr %sp,align 1
 %tp = getelementptr i8,ptr %input,i64 72
 %t0 = load i64,ptr %tp,align 1
 %temporary0 = getelementptr i8,ptr %temporary,i64 0
 call void @wide_sat_140_u_0(ptr %temporary0,ptr %input,i64 %s0)
 %temporary1 = getelementptr i8,ptr %temporary,i64 24
 call void @wide_sat_140_s_0(ptr %temporary1,ptr %input,i64 %s0)
 %temporary2 = getelementptr i8,ptr %temporary,i64 48
 call void @wide_sat_140_u_0(ptr %temporary2,ptr %constant,i64 %s0)
 %temporary3 = getelementptr i8,ptr %temporary,i64 72
 call void @wide_sat_140_s_0(ptr %temporary3,ptr %constant,i64 %s0)
 %temporary4 = getelementptr i8,ptr %temporary,i64 96
 call void @wide_sat_200_u_0(ptr %temporary4,ptr %bp,i64 %t0)
 %temporary5 = getelementptr i8,ptr %temporary,i64 128
 call void @wide_sat_200_s_0(ptr %temporary5,ptr %bp,i64 %t0)
 %r0 = load i140,ptr %temporary0,align 1
 %r1 = load i140,ptr %temporary1,align 1
 %r2 = load i140,ptr %temporary2,align 1
 %r3 = load i140,ptr %temporary3,align 1
 %r4 = load i200,ptr %temporary4,align 1
 %r5 = load i200,ptr %temporary5,align 1
 %v0 = insertelement <4 x i140> poison,i140 %r0,i64 0
 %v1 = insertelement <4 x i140> %v0,i140 %r1,i64 1
 %v2 = insertelement <4 x i140> %v1,i140 %r2,i64 2
 %v3 = insertelement <4 x i140> %v2,i140 %r3,i64 3
 %w0 = insertelement <4 x i140> poison,i140 0,i32 0
 %w1 = insertelement <4 x i140> %w0,i140 -1,i32 1
 %w2 = insertelement <4 x i140> %w1,i140 696898287454081973172991196020261297061887,i32 2
 %w3 = insertelement <4 x i140> %w2,i140 -696898287454081973172991196020261297061888,i32 3
 %cmp = icmp ule <4 x i140> %v3,%w3
 %packed_mask = bitcast <4 x i1> %cmp to i4
 %mask = zext i4 %packed_mask to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %word0_0 = trunc i140 %r0 to i64
 %out0_0 = getelementptr i8,ptr %out,i64 0
 store i64 %word0_0,ptr %out0_0,align 1
 %shift0_1 = lshr i140 %r0,64
 %word0_1 = trunc i140 %shift0_1 to i64
 %out0_1 = getelementptr i8,ptr %out,i64 8
 store i64 %word0_1,ptr %out0_1,align 1
 %shift0_2 = lshr i140 %r0,128
 %word0_2 = trunc i140 %shift0_2 to i64
 %out0_2 = getelementptr i8,ptr %out,i64 16
 store i64 %word0_2,ptr %out0_2,align 1
 %word1_0 = trunc i140 %r1 to i64
 %out1_0 = getelementptr i8,ptr %out,i64 24
 store i64 %word1_0,ptr %out1_0,align 1
 %shift1_1 = lshr i140 %r1,64
 %word1_1 = trunc i140 %shift1_1 to i64
 %out1_1 = getelementptr i8,ptr %out,i64 32
 store i64 %word1_1,ptr %out1_1,align 1
 %shift1_2 = lshr i140 %r1,128
 %word1_2 = trunc i140 %shift1_2 to i64
 %out1_2 = getelementptr i8,ptr %out,i64 40
 store i64 %word1_2,ptr %out1_2,align 1
 %word2_0 = trunc i140 %r2 to i64
 %out2_0 = getelementptr i8,ptr %out,i64 48
 store i64 %word2_0,ptr %out2_0,align 1
 %shift2_1 = lshr i140 %r2,64
 %word2_1 = trunc i140 %shift2_1 to i64
 %out2_1 = getelementptr i8,ptr %out,i64 56
 store i64 %word2_1,ptr %out2_1,align 1
 %shift2_2 = lshr i140 %r2,128
 %word2_2 = trunc i140 %shift2_2 to i64
 %out2_2 = getelementptr i8,ptr %out,i64 64
 store i64 %word2_2,ptr %out2_2,align 1
 %word3_0 = trunc i140 %r3 to i64
 %out3_0 = getelementptr i8,ptr %out,i64 72
 store i64 %word3_0,ptr %out3_0,align 1
 %shift3_1 = lshr i140 %r3,64
 %word3_1 = trunc i140 %shift3_1 to i64
 %out3_1 = getelementptr i8,ptr %out,i64 80
 store i64 %word3_1,ptr %out3_1,align 1
 %shift3_2 = lshr i140 %r3,128
 %word3_2 = trunc i140 %shift3_2 to i64
 %out3_2 = getelementptr i8,ptr %out,i64 88
 store i64 %word3_2,ptr %out3_2,align 1
 %word4_0 = trunc i200 %r4 to i64
 %out4_0 = getelementptr i8,ptr %out,i64 96
 store i64 %word4_0,ptr %out4_0,align 1
 %shift4_1 = lshr i200 %r4,64
 %word4_1 = trunc i200 %shift4_1 to i64
 %out4_1 = getelementptr i8,ptr %out,i64 104
 store i64 %word4_1,ptr %out4_1,align 1
 %shift4_2 = lshr i200 %r4,128
 %word4_2 = trunc i200 %shift4_2 to i64
 %out4_2 = getelementptr i8,ptr %out,i64 112
 store i64 %word4_2,ptr %out4_2,align 1
 %shift4_3 = lshr i200 %r4,192
 %word4_3 = trunc i200 %shift4_3 to i64
 %out4_3 = getelementptr i8,ptr %out,i64 120
 store i64 %word4_3,ptr %out4_3,align 1
 %word5_0 = trunc i200 %r5 to i64
 %out5_0 = getelementptr i8,ptr %out,i64 128
 store i64 %word5_0,ptr %out5_0,align 1
 %shift5_1 = lshr i200 %r5,64
 %word5_1 = trunc i200 %shift5_1 to i64
 %out5_1 = getelementptr i8,ptr %out,i64 136
 store i64 %word5_1,ptr %out5_1,align 1
 %shift5_2 = lshr i200 %r5,128
 %word5_2 = trunc i200 %shift5_2 to i64
 %out5_2 = getelementptr i8,ptr %out,i64 144
 store i64 %word5_2,ptr %out5_2,align 1
 %shift5_3 = lshr i200 %r5,192
 %word5_3 = trunc i200 %shift5_3 to i64
 %out5_3 = getelementptr i8,ptr %out,i64 152
 store i64 %word5_3,ptr %out5_3,align 1
 %mp = getelementptr i8,ptr %out,i64 160
 store i64 %mask,ptr %mp,align 1
 %op = getelementptr i8,ptr %out,i64 168
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %mask,%token
 ret i64 %answer
}
define i64 @wide_saturation_vector_probe_34(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %temporary = alloca [160 x i8],align 16
 %constant = alloca i140,align 16
 store i140 1267650600228229401496703205376,ptr %constant,align 16
 %bp = getelementptr i8,ptr %input,i64 32
 %sp = getelementptr i8,ptr %input,i64 64
 %s0 = load i64,ptr %sp,align 1
 %tp = getelementptr i8,ptr %input,i64 72
 %t0 = load i64,ptr %tp,align 1
 %temporary0 = getelementptr i8,ptr %temporary,i64 0
 call void @wide_sat_140_u_1(ptr %temporary0,ptr %input,i64 %s0)
 %temporary1 = getelementptr i8,ptr %temporary,i64 24
 call void @wide_sat_140_s_1(ptr %temporary1,ptr %input,i64 %s0)
 %temporary2 = getelementptr i8,ptr %temporary,i64 48
 call void @wide_sat_140_u_1(ptr %temporary2,ptr %constant,i64 %s0)
 %temporary3 = getelementptr i8,ptr %temporary,i64 72
 call void @wide_sat_140_s_1(ptr %temporary3,ptr %constant,i64 %s0)
 %temporary4 = getelementptr i8,ptr %temporary,i64 96
 call void @wide_sat_200_u_1(ptr %temporary4,ptr %bp,i64 %t0)
 %temporary5 = getelementptr i8,ptr %temporary,i64 128
 call void @wide_sat_200_s_1(ptr %temporary5,ptr %bp,i64 %t0)
 %r0 = load i140,ptr %temporary0,align 1
 %r1 = load i140,ptr %temporary1,align 1
 %r2 = load i140,ptr %temporary2,align 1
 %r3 = load i140,ptr %temporary3,align 1
 %r4 = load i200,ptr %temporary4,align 1
 %r5 = load i200,ptr %temporary5,align 1
 %v0 = insertelement <4 x i140> poison,i140 %r0,i64 0
 %v1 = insertelement <4 x i140> %v0,i140 %r1,i64 1
 %v2 = insertelement <4 x i140> %v1,i140 %r2,i64 2
 %v3 = insertelement <4 x i140> %v2,i140 %r3,i64 3
 %w0 = insertelement <4 x i140> poison,i140 0,i32 0
 %w1 = insertelement <4 x i140> %w0,i140 -1,i32 1
 %w2 = insertelement <4 x i140> %w1,i140 696898287454081973172991196020261297061887,i32 2
 %w3 = insertelement <4 x i140> %w2,i140 -696898287454081973172991196020261297061888,i32 3
 %cmp = icmp ule <4 x i140> %v3,%w3
 %packed_mask = bitcast <4 x i1> %cmp to i4
 %mask = zext i4 %packed_mask to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %word0_0 = trunc i140 %r0 to i64
 %out0_0 = getelementptr i8,ptr %out,i64 0
 store i64 %word0_0,ptr %out0_0,align 1
 %shift0_1 = lshr i140 %r0,64
 %word0_1 = trunc i140 %shift0_1 to i64
 %out0_1 = getelementptr i8,ptr %out,i64 8
 store i64 %word0_1,ptr %out0_1,align 1
 %shift0_2 = lshr i140 %r0,128
 %word0_2 = trunc i140 %shift0_2 to i64
 %out0_2 = getelementptr i8,ptr %out,i64 16
 store i64 %word0_2,ptr %out0_2,align 1
 %word1_0 = trunc i140 %r1 to i64
 %out1_0 = getelementptr i8,ptr %out,i64 24
 store i64 %word1_0,ptr %out1_0,align 1
 %shift1_1 = lshr i140 %r1,64
 %word1_1 = trunc i140 %shift1_1 to i64
 %out1_1 = getelementptr i8,ptr %out,i64 32
 store i64 %word1_1,ptr %out1_1,align 1
 %shift1_2 = lshr i140 %r1,128
 %word1_2 = trunc i140 %shift1_2 to i64
 %out1_2 = getelementptr i8,ptr %out,i64 40
 store i64 %word1_2,ptr %out1_2,align 1
 %word2_0 = trunc i140 %r2 to i64
 %out2_0 = getelementptr i8,ptr %out,i64 48
 store i64 %word2_0,ptr %out2_0,align 1
 %shift2_1 = lshr i140 %r2,64
 %word2_1 = trunc i140 %shift2_1 to i64
 %out2_1 = getelementptr i8,ptr %out,i64 56
 store i64 %word2_1,ptr %out2_1,align 1
 %shift2_2 = lshr i140 %r2,128
 %word2_2 = trunc i140 %shift2_2 to i64
 %out2_2 = getelementptr i8,ptr %out,i64 64
 store i64 %word2_2,ptr %out2_2,align 1
 %word3_0 = trunc i140 %r3 to i64
 %out3_0 = getelementptr i8,ptr %out,i64 72
 store i64 %word3_0,ptr %out3_0,align 1
 %shift3_1 = lshr i140 %r3,64
 %word3_1 = trunc i140 %shift3_1 to i64
 %out3_1 = getelementptr i8,ptr %out,i64 80
 store i64 %word3_1,ptr %out3_1,align 1
 %shift3_2 = lshr i140 %r3,128
 %word3_2 = trunc i140 %shift3_2 to i64
 %out3_2 = getelementptr i8,ptr %out,i64 88
 store i64 %word3_2,ptr %out3_2,align 1
 %word4_0 = trunc i200 %r4 to i64
 %out4_0 = getelementptr i8,ptr %out,i64 96
 store i64 %word4_0,ptr %out4_0,align 1
 %shift4_1 = lshr i200 %r4,64
 %word4_1 = trunc i200 %shift4_1 to i64
 %out4_1 = getelementptr i8,ptr %out,i64 104
 store i64 %word4_1,ptr %out4_1,align 1
 %shift4_2 = lshr i200 %r4,128
 %word4_2 = trunc i200 %shift4_2 to i64
 %out4_2 = getelementptr i8,ptr %out,i64 112
 store i64 %word4_2,ptr %out4_2,align 1
 %shift4_3 = lshr i200 %r4,192
 %word4_3 = trunc i200 %shift4_3 to i64
 %out4_3 = getelementptr i8,ptr %out,i64 120
 store i64 %word4_3,ptr %out4_3,align 1
 %word5_0 = trunc i200 %r5 to i64
 %out5_0 = getelementptr i8,ptr %out,i64 128
 store i64 %word5_0,ptr %out5_0,align 1
 %shift5_1 = lshr i200 %r5,64
 %word5_1 = trunc i200 %shift5_1 to i64
 %out5_1 = getelementptr i8,ptr %out,i64 136
 store i64 %word5_1,ptr %out5_1,align 1
 %shift5_2 = lshr i200 %r5,128
 %word5_2 = trunc i200 %shift5_2 to i64
 %out5_2 = getelementptr i8,ptr %out,i64 144
 store i64 %word5_2,ptr %out5_2,align 1
 %shift5_3 = lshr i200 %r5,192
 %word5_3 = trunc i200 %shift5_3 to i64
 %out5_3 = getelementptr i8,ptr %out,i64 152
 store i64 %word5_3,ptr %out5_3,align 1
 %mp = getelementptr i8,ptr %out,i64 160
 store i64 %mask,ptr %mp,align 1
 %op = getelementptr i8,ptr %out,i64 168
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %mask,%token
 ret i64 %answer
}
define i64 @wide_saturation_vector_probe_35(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %temporary = alloca [160 x i8],align 16
 %constant = alloca i140,align 16
 store i140 1267650600228229401496703205376,ptr %constant,align 16
 %bp = getelementptr i8,ptr %input,i64 32
 %sp = getelementptr i8,ptr %input,i64 64
 %s0 = load i64,ptr %sp,align 1
 %tp = getelementptr i8,ptr %input,i64 72
 %t0 = load i64,ptr %tp,align 1
 %temporary0 = getelementptr i8,ptr %temporary,i64 0
 call void @wide_sat_140_u_2(ptr %temporary0,ptr %input,i64 %s0)
 %temporary1 = getelementptr i8,ptr %temporary,i64 24
 call void @wide_sat_140_s_2(ptr %temporary1,ptr %input,i64 %s0)
 %temporary2 = getelementptr i8,ptr %temporary,i64 48
 call void @wide_sat_140_u_2(ptr %temporary2,ptr %constant,i64 %s0)
 %temporary3 = getelementptr i8,ptr %temporary,i64 72
 call void @wide_sat_140_s_2(ptr %temporary3,ptr %constant,i64 %s0)
 %temporary4 = getelementptr i8,ptr %temporary,i64 96
 call void @wide_sat_200_u_2(ptr %temporary4,ptr %bp,i64 %t0)
 %temporary5 = getelementptr i8,ptr %temporary,i64 128
 call void @wide_sat_200_s_2(ptr %temporary5,ptr %bp,i64 %t0)
 %r0 = load i140,ptr %temporary0,align 1
 %r1 = load i140,ptr %temporary1,align 1
 %r2 = load i140,ptr %temporary2,align 1
 %r3 = load i140,ptr %temporary3,align 1
 %r4 = load i200,ptr %temporary4,align 1
 %r5 = load i200,ptr %temporary5,align 1
 %v0 = insertelement <4 x i140> poison,i140 %r0,i64 0
 %v1 = insertelement <4 x i140> %v0,i140 %r1,i64 1
 %v2 = insertelement <4 x i140> %v1,i140 %r2,i64 2
 %v3 = insertelement <4 x i140> %v2,i140 %r3,i64 3
 %w0 = insertelement <4 x i140> poison,i140 0,i32 0
 %w1 = insertelement <4 x i140> %w0,i140 -1,i32 1
 %w2 = insertelement <4 x i140> %w1,i140 696898287454081973172991196020261297061887,i32 2
 %w3 = insertelement <4 x i140> %w2,i140 -696898287454081973172991196020261297061888,i32 3
 %cmp = icmp ule <4 x i140> %v3,%w3
 %packed_mask = bitcast <4 x i1> %cmp to i4
 %mask = zext i4 %packed_mask to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %word0_0 = trunc i140 %r0 to i64
 %out0_0 = getelementptr i8,ptr %out,i64 0
 store i64 %word0_0,ptr %out0_0,align 1
 %shift0_1 = lshr i140 %r0,64
 %word0_1 = trunc i140 %shift0_1 to i64
 %out0_1 = getelementptr i8,ptr %out,i64 8
 store i64 %word0_1,ptr %out0_1,align 1
 %shift0_2 = lshr i140 %r0,128
 %word0_2 = trunc i140 %shift0_2 to i64
 %out0_2 = getelementptr i8,ptr %out,i64 16
 store i64 %word0_2,ptr %out0_2,align 1
 %word1_0 = trunc i140 %r1 to i64
 %out1_0 = getelementptr i8,ptr %out,i64 24
 store i64 %word1_0,ptr %out1_0,align 1
 %shift1_1 = lshr i140 %r1,64
 %word1_1 = trunc i140 %shift1_1 to i64
 %out1_1 = getelementptr i8,ptr %out,i64 32
 store i64 %word1_1,ptr %out1_1,align 1
 %shift1_2 = lshr i140 %r1,128
 %word1_2 = trunc i140 %shift1_2 to i64
 %out1_2 = getelementptr i8,ptr %out,i64 40
 store i64 %word1_2,ptr %out1_2,align 1
 %word2_0 = trunc i140 %r2 to i64
 %out2_0 = getelementptr i8,ptr %out,i64 48
 store i64 %word2_0,ptr %out2_0,align 1
 %shift2_1 = lshr i140 %r2,64
 %word2_1 = trunc i140 %shift2_1 to i64
 %out2_1 = getelementptr i8,ptr %out,i64 56
 store i64 %word2_1,ptr %out2_1,align 1
 %shift2_2 = lshr i140 %r2,128
 %word2_2 = trunc i140 %shift2_2 to i64
 %out2_2 = getelementptr i8,ptr %out,i64 64
 store i64 %word2_2,ptr %out2_2,align 1
 %word3_0 = trunc i140 %r3 to i64
 %out3_0 = getelementptr i8,ptr %out,i64 72
 store i64 %word3_0,ptr %out3_0,align 1
 %shift3_1 = lshr i140 %r3,64
 %word3_1 = trunc i140 %shift3_1 to i64
 %out3_1 = getelementptr i8,ptr %out,i64 80
 store i64 %word3_1,ptr %out3_1,align 1
 %shift3_2 = lshr i140 %r3,128
 %word3_2 = trunc i140 %shift3_2 to i64
 %out3_2 = getelementptr i8,ptr %out,i64 88
 store i64 %word3_2,ptr %out3_2,align 1
 %word4_0 = trunc i200 %r4 to i64
 %out4_0 = getelementptr i8,ptr %out,i64 96
 store i64 %word4_0,ptr %out4_0,align 1
 %shift4_1 = lshr i200 %r4,64
 %word4_1 = trunc i200 %shift4_1 to i64
 %out4_1 = getelementptr i8,ptr %out,i64 104
 store i64 %word4_1,ptr %out4_1,align 1
 %shift4_2 = lshr i200 %r4,128
 %word4_2 = trunc i200 %shift4_2 to i64
 %out4_2 = getelementptr i8,ptr %out,i64 112
 store i64 %word4_2,ptr %out4_2,align 1
 %shift4_3 = lshr i200 %r4,192
 %word4_3 = trunc i200 %shift4_3 to i64
 %out4_3 = getelementptr i8,ptr %out,i64 120
 store i64 %word4_3,ptr %out4_3,align 1
 %word5_0 = trunc i200 %r5 to i64
 %out5_0 = getelementptr i8,ptr %out,i64 128
 store i64 %word5_0,ptr %out5_0,align 1
 %shift5_1 = lshr i200 %r5,64
 %word5_1 = trunc i200 %shift5_1 to i64
 %out5_1 = getelementptr i8,ptr %out,i64 136
 store i64 %word5_1,ptr %out5_1,align 1
 %shift5_2 = lshr i200 %r5,128
 %word5_2 = trunc i200 %shift5_2 to i64
 %out5_2 = getelementptr i8,ptr %out,i64 144
 store i64 %word5_2,ptr %out5_2,align 1
 %shift5_3 = lshr i200 %r5,192
 %word5_3 = trunc i200 %shift5_3 to i64
 %out5_3 = getelementptr i8,ptr %out,i64 152
 store i64 %word5_3,ptr %out5_3,align 1
 %mp = getelementptr i8,ptr %out,i64 160
 store i64 %mask,ptr %mp,align 1
 %op = getelementptr i8,ptr %out,i64 168
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %mask,%token
 ret i64 %answer
}
define i64 @wide_saturation_vector_probe_36(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %temporary = alloca [160 x i8],align 16
 %constant = alloca i140,align 16
 store i140 1267650600228229401496703205376,ptr %constant,align 16
 %bp = getelementptr i8,ptr %input,i64 32
 %sp = getelementptr i8,ptr %input,i64 64
 %s0 = load i64,ptr %sp,align 1
 %tp = getelementptr i8,ptr %input,i64 72
 %t0 = load i64,ptr %tp,align 1
 %temporary0 = getelementptr i8,ptr %temporary,i64 0
 call void @wide_sat_140_u_0(ptr %temporary0,ptr %input,i64 %s0)
 %temporary1 = getelementptr i8,ptr %temporary,i64 24
 call void @wide_sat_140_s_0(ptr %temporary1,ptr %input,i64 %s0)
 %temporary2 = getelementptr i8,ptr %temporary,i64 48
 call void @wide_sat_140_u_0(ptr %temporary2,ptr %constant,i64 %s0)
 %temporary3 = getelementptr i8,ptr %temporary,i64 72
 call void @wide_sat_140_s_0(ptr %temporary3,ptr %constant,i64 %s0)
 %temporary4 = getelementptr i8,ptr %temporary,i64 96
 call void @wide_sat_200_u_0(ptr %temporary4,ptr %bp,i64 %t0)
 %temporary5 = getelementptr i8,ptr %temporary,i64 128
 call void @wide_sat_200_s_0(ptr %temporary5,ptr %bp,i64 %t0)
 %r0 = load i140,ptr %temporary0,align 1
 %r1 = load i140,ptr %temporary1,align 1
 %r2 = load i140,ptr %temporary2,align 1
 %r3 = load i140,ptr %temporary3,align 1
 %r4 = load i200,ptr %temporary4,align 1
 %r5 = load i200,ptr %temporary5,align 1
 %v0 = insertelement <4 x i140> poison,i140 %r0,i64 0
 %v1 = insertelement <4 x i140> %v0,i140 %r1,i64 1
 %v2 = insertelement <4 x i140> %v1,i140 %r2,i64 2
 %v3 = insertelement <4 x i140> %v2,i140 %r3,i64 3
 %cmp = icmp sgt <4 x i140> %v3,<i140 0,i140 -1,i140 696898287454081973172991196020261297061887,i140 -696898287454081973172991196020261297061888>
 %packed_mask = bitcast <4 x i1> %cmp to i4
 %mask = zext i4 %packed_mask to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %word0_0 = trunc i140 %r0 to i64
 %out0_0 = getelementptr i8,ptr %out,i64 0
 store i64 %word0_0,ptr %out0_0,align 1
 %shift0_1 = lshr i140 %r0,64
 %word0_1 = trunc i140 %shift0_1 to i64
 %out0_1 = getelementptr i8,ptr %out,i64 8
 store i64 %word0_1,ptr %out0_1,align 1
 %shift0_2 = lshr i140 %r0,128
 %word0_2 = trunc i140 %shift0_2 to i64
 %out0_2 = getelementptr i8,ptr %out,i64 16
 store i64 %word0_2,ptr %out0_2,align 1
 %word1_0 = trunc i140 %r1 to i64
 %out1_0 = getelementptr i8,ptr %out,i64 24
 store i64 %word1_0,ptr %out1_0,align 1
 %shift1_1 = lshr i140 %r1,64
 %word1_1 = trunc i140 %shift1_1 to i64
 %out1_1 = getelementptr i8,ptr %out,i64 32
 store i64 %word1_1,ptr %out1_1,align 1
 %shift1_2 = lshr i140 %r1,128
 %word1_2 = trunc i140 %shift1_2 to i64
 %out1_2 = getelementptr i8,ptr %out,i64 40
 store i64 %word1_2,ptr %out1_2,align 1
 %word2_0 = trunc i140 %r2 to i64
 %out2_0 = getelementptr i8,ptr %out,i64 48
 store i64 %word2_0,ptr %out2_0,align 1
 %shift2_1 = lshr i140 %r2,64
 %word2_1 = trunc i140 %shift2_1 to i64
 %out2_1 = getelementptr i8,ptr %out,i64 56
 store i64 %word2_1,ptr %out2_1,align 1
 %shift2_2 = lshr i140 %r2,128
 %word2_2 = trunc i140 %shift2_2 to i64
 %out2_2 = getelementptr i8,ptr %out,i64 64
 store i64 %word2_2,ptr %out2_2,align 1
 %word3_0 = trunc i140 %r3 to i64
 %out3_0 = getelementptr i8,ptr %out,i64 72
 store i64 %word3_0,ptr %out3_0,align 1
 %shift3_1 = lshr i140 %r3,64
 %word3_1 = trunc i140 %shift3_1 to i64
 %out3_1 = getelementptr i8,ptr %out,i64 80
 store i64 %word3_1,ptr %out3_1,align 1
 %shift3_2 = lshr i140 %r3,128
 %word3_2 = trunc i140 %shift3_2 to i64
 %out3_2 = getelementptr i8,ptr %out,i64 88
 store i64 %word3_2,ptr %out3_2,align 1
 %word4_0 = trunc i200 %r4 to i64
 %out4_0 = getelementptr i8,ptr %out,i64 96
 store i64 %word4_0,ptr %out4_0,align 1
 %shift4_1 = lshr i200 %r4,64
 %word4_1 = trunc i200 %shift4_1 to i64
 %out4_1 = getelementptr i8,ptr %out,i64 104
 store i64 %word4_1,ptr %out4_1,align 1
 %shift4_2 = lshr i200 %r4,128
 %word4_2 = trunc i200 %shift4_2 to i64
 %out4_2 = getelementptr i8,ptr %out,i64 112
 store i64 %word4_2,ptr %out4_2,align 1
 %shift4_3 = lshr i200 %r4,192
 %word4_3 = trunc i200 %shift4_3 to i64
 %out4_3 = getelementptr i8,ptr %out,i64 120
 store i64 %word4_3,ptr %out4_3,align 1
 %word5_0 = trunc i200 %r5 to i64
 %out5_0 = getelementptr i8,ptr %out,i64 128
 store i64 %word5_0,ptr %out5_0,align 1
 %shift5_1 = lshr i200 %r5,64
 %word5_1 = trunc i200 %shift5_1 to i64
 %out5_1 = getelementptr i8,ptr %out,i64 136
 store i64 %word5_1,ptr %out5_1,align 1
 %shift5_2 = lshr i200 %r5,128
 %word5_2 = trunc i200 %shift5_2 to i64
 %out5_2 = getelementptr i8,ptr %out,i64 144
 store i64 %word5_2,ptr %out5_2,align 1
 %shift5_3 = lshr i200 %r5,192
 %word5_3 = trunc i200 %shift5_3 to i64
 %out5_3 = getelementptr i8,ptr %out,i64 152
 store i64 %word5_3,ptr %out5_3,align 1
 %mp = getelementptr i8,ptr %out,i64 160
 store i64 %mask,ptr %mp,align 1
 %op = getelementptr i8,ptr %out,i64 168
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %mask,%token
 ret i64 %answer
}
define i64 @wide_saturation_vector_probe_37(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %temporary = alloca [160 x i8],align 16
 %constant = alloca i140,align 16
 store i140 1267650600228229401496703205376,ptr %constant,align 16
 %bp = getelementptr i8,ptr %input,i64 32
 %sp = getelementptr i8,ptr %input,i64 64
 %s0 = load i64,ptr %sp,align 1
 %tp = getelementptr i8,ptr %input,i64 72
 %t0 = load i64,ptr %tp,align 1
 %temporary0 = getelementptr i8,ptr %temporary,i64 0
 call void @wide_sat_140_u_1(ptr %temporary0,ptr %input,i64 %s0)
 %temporary1 = getelementptr i8,ptr %temporary,i64 24
 call void @wide_sat_140_s_1(ptr %temporary1,ptr %input,i64 %s0)
 %temporary2 = getelementptr i8,ptr %temporary,i64 48
 call void @wide_sat_140_u_1(ptr %temporary2,ptr %constant,i64 %s0)
 %temporary3 = getelementptr i8,ptr %temporary,i64 72
 call void @wide_sat_140_s_1(ptr %temporary3,ptr %constant,i64 %s0)
 %temporary4 = getelementptr i8,ptr %temporary,i64 96
 call void @wide_sat_200_u_1(ptr %temporary4,ptr %bp,i64 %t0)
 %temporary5 = getelementptr i8,ptr %temporary,i64 128
 call void @wide_sat_200_s_1(ptr %temporary5,ptr %bp,i64 %t0)
 %r0 = load i140,ptr %temporary0,align 1
 %r1 = load i140,ptr %temporary1,align 1
 %r2 = load i140,ptr %temporary2,align 1
 %r3 = load i140,ptr %temporary3,align 1
 %r4 = load i200,ptr %temporary4,align 1
 %r5 = load i200,ptr %temporary5,align 1
 %v0 = insertelement <4 x i140> poison,i140 %r0,i64 0
 %v1 = insertelement <4 x i140> %v0,i140 %r1,i64 1
 %v2 = insertelement <4 x i140> %v1,i140 %r2,i64 2
 %v3 = insertelement <4 x i140> %v2,i140 %r3,i64 3
 %cmp = icmp sgt <4 x i140> %v3,<i140 0,i140 -1,i140 696898287454081973172991196020261297061887,i140 -696898287454081973172991196020261297061888>
 %packed_mask = bitcast <4 x i1> %cmp to i4
 %mask = zext i4 %packed_mask to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %word0_0 = trunc i140 %r0 to i64
 %out0_0 = getelementptr i8,ptr %out,i64 0
 store i64 %word0_0,ptr %out0_0,align 1
 %shift0_1 = lshr i140 %r0,64
 %word0_1 = trunc i140 %shift0_1 to i64
 %out0_1 = getelementptr i8,ptr %out,i64 8
 store i64 %word0_1,ptr %out0_1,align 1
 %shift0_2 = lshr i140 %r0,128
 %word0_2 = trunc i140 %shift0_2 to i64
 %out0_2 = getelementptr i8,ptr %out,i64 16
 store i64 %word0_2,ptr %out0_2,align 1
 %word1_0 = trunc i140 %r1 to i64
 %out1_0 = getelementptr i8,ptr %out,i64 24
 store i64 %word1_0,ptr %out1_0,align 1
 %shift1_1 = lshr i140 %r1,64
 %word1_1 = trunc i140 %shift1_1 to i64
 %out1_1 = getelementptr i8,ptr %out,i64 32
 store i64 %word1_1,ptr %out1_1,align 1
 %shift1_2 = lshr i140 %r1,128
 %word1_2 = trunc i140 %shift1_2 to i64
 %out1_2 = getelementptr i8,ptr %out,i64 40
 store i64 %word1_2,ptr %out1_2,align 1
 %word2_0 = trunc i140 %r2 to i64
 %out2_0 = getelementptr i8,ptr %out,i64 48
 store i64 %word2_0,ptr %out2_0,align 1
 %shift2_1 = lshr i140 %r2,64
 %word2_1 = trunc i140 %shift2_1 to i64
 %out2_1 = getelementptr i8,ptr %out,i64 56
 store i64 %word2_1,ptr %out2_1,align 1
 %shift2_2 = lshr i140 %r2,128
 %word2_2 = trunc i140 %shift2_2 to i64
 %out2_2 = getelementptr i8,ptr %out,i64 64
 store i64 %word2_2,ptr %out2_2,align 1
 %word3_0 = trunc i140 %r3 to i64
 %out3_0 = getelementptr i8,ptr %out,i64 72
 store i64 %word3_0,ptr %out3_0,align 1
 %shift3_1 = lshr i140 %r3,64
 %word3_1 = trunc i140 %shift3_1 to i64
 %out3_1 = getelementptr i8,ptr %out,i64 80
 store i64 %word3_1,ptr %out3_1,align 1
 %shift3_2 = lshr i140 %r3,128
 %word3_2 = trunc i140 %shift3_2 to i64
 %out3_2 = getelementptr i8,ptr %out,i64 88
 store i64 %word3_2,ptr %out3_2,align 1
 %word4_0 = trunc i200 %r4 to i64
 %out4_0 = getelementptr i8,ptr %out,i64 96
 store i64 %word4_0,ptr %out4_0,align 1
 %shift4_1 = lshr i200 %r4,64
 %word4_1 = trunc i200 %shift4_1 to i64
 %out4_1 = getelementptr i8,ptr %out,i64 104
 store i64 %word4_1,ptr %out4_1,align 1
 %shift4_2 = lshr i200 %r4,128
 %word4_2 = trunc i200 %shift4_2 to i64
 %out4_2 = getelementptr i8,ptr %out,i64 112
 store i64 %word4_2,ptr %out4_2,align 1
 %shift4_3 = lshr i200 %r4,192
 %word4_3 = trunc i200 %shift4_3 to i64
 %out4_3 = getelementptr i8,ptr %out,i64 120
 store i64 %word4_3,ptr %out4_3,align 1
 %word5_0 = trunc i200 %r5 to i64
 %out5_0 = getelementptr i8,ptr %out,i64 128
 store i64 %word5_0,ptr %out5_0,align 1
 %shift5_1 = lshr i200 %r5,64
 %word5_1 = trunc i200 %shift5_1 to i64
 %out5_1 = getelementptr i8,ptr %out,i64 136
 store i64 %word5_1,ptr %out5_1,align 1
 %shift5_2 = lshr i200 %r5,128
 %word5_2 = trunc i200 %shift5_2 to i64
 %out5_2 = getelementptr i8,ptr %out,i64 144
 store i64 %word5_2,ptr %out5_2,align 1
 %shift5_3 = lshr i200 %r5,192
 %word5_3 = trunc i200 %shift5_3 to i64
 %out5_3 = getelementptr i8,ptr %out,i64 152
 store i64 %word5_3,ptr %out5_3,align 1
 %mp = getelementptr i8,ptr %out,i64 160
 store i64 %mask,ptr %mp,align 1
 %op = getelementptr i8,ptr %out,i64 168
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %mask,%token
 ret i64 %answer
}
define i64 @wide_saturation_vector_probe_38(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %temporary = alloca [160 x i8],align 16
 %constant = alloca i140,align 16
 store i140 1267650600228229401496703205376,ptr %constant,align 16
 %bp = getelementptr i8,ptr %input,i64 32
 %sp = getelementptr i8,ptr %input,i64 64
 %s0 = load i64,ptr %sp,align 1
 %tp = getelementptr i8,ptr %input,i64 72
 %t0 = load i64,ptr %tp,align 1
 %temporary0 = getelementptr i8,ptr %temporary,i64 0
 call void @wide_sat_140_u_2(ptr %temporary0,ptr %input,i64 %s0)
 %temporary1 = getelementptr i8,ptr %temporary,i64 24
 call void @wide_sat_140_s_2(ptr %temporary1,ptr %input,i64 %s0)
 %temporary2 = getelementptr i8,ptr %temporary,i64 48
 call void @wide_sat_140_u_2(ptr %temporary2,ptr %constant,i64 %s0)
 %temporary3 = getelementptr i8,ptr %temporary,i64 72
 call void @wide_sat_140_s_2(ptr %temporary3,ptr %constant,i64 %s0)
 %temporary4 = getelementptr i8,ptr %temporary,i64 96
 call void @wide_sat_200_u_2(ptr %temporary4,ptr %bp,i64 %t0)
 %temporary5 = getelementptr i8,ptr %temporary,i64 128
 call void @wide_sat_200_s_2(ptr %temporary5,ptr %bp,i64 %t0)
 %r0 = load i140,ptr %temporary0,align 1
 %r1 = load i140,ptr %temporary1,align 1
 %r2 = load i140,ptr %temporary2,align 1
 %r3 = load i140,ptr %temporary3,align 1
 %r4 = load i200,ptr %temporary4,align 1
 %r5 = load i200,ptr %temporary5,align 1
 %v0 = insertelement <4 x i140> poison,i140 %r0,i64 0
 %v1 = insertelement <4 x i140> %v0,i140 %r1,i64 1
 %v2 = insertelement <4 x i140> %v1,i140 %r2,i64 2
 %v3 = insertelement <4 x i140> %v2,i140 %r3,i64 3
 %cmp = icmp sgt <4 x i140> %v3,<i140 0,i140 -1,i140 696898287454081973172991196020261297061887,i140 -696898287454081973172991196020261297061888>
 %packed_mask = bitcast <4 x i1> %cmp to i4
 %mask = zext i4 %packed_mask to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %word0_0 = trunc i140 %r0 to i64
 %out0_0 = getelementptr i8,ptr %out,i64 0
 store i64 %word0_0,ptr %out0_0,align 1
 %shift0_1 = lshr i140 %r0,64
 %word0_1 = trunc i140 %shift0_1 to i64
 %out0_1 = getelementptr i8,ptr %out,i64 8
 store i64 %word0_1,ptr %out0_1,align 1
 %shift0_2 = lshr i140 %r0,128
 %word0_2 = trunc i140 %shift0_2 to i64
 %out0_2 = getelementptr i8,ptr %out,i64 16
 store i64 %word0_2,ptr %out0_2,align 1
 %word1_0 = trunc i140 %r1 to i64
 %out1_0 = getelementptr i8,ptr %out,i64 24
 store i64 %word1_0,ptr %out1_0,align 1
 %shift1_1 = lshr i140 %r1,64
 %word1_1 = trunc i140 %shift1_1 to i64
 %out1_1 = getelementptr i8,ptr %out,i64 32
 store i64 %word1_1,ptr %out1_1,align 1
 %shift1_2 = lshr i140 %r1,128
 %word1_2 = trunc i140 %shift1_2 to i64
 %out1_2 = getelementptr i8,ptr %out,i64 40
 store i64 %word1_2,ptr %out1_2,align 1
 %word2_0 = trunc i140 %r2 to i64
 %out2_0 = getelementptr i8,ptr %out,i64 48
 store i64 %word2_0,ptr %out2_0,align 1
 %shift2_1 = lshr i140 %r2,64
 %word2_1 = trunc i140 %shift2_1 to i64
 %out2_1 = getelementptr i8,ptr %out,i64 56
 store i64 %word2_1,ptr %out2_1,align 1
 %shift2_2 = lshr i140 %r2,128
 %word2_2 = trunc i140 %shift2_2 to i64
 %out2_2 = getelementptr i8,ptr %out,i64 64
 store i64 %word2_2,ptr %out2_2,align 1
 %word3_0 = trunc i140 %r3 to i64
 %out3_0 = getelementptr i8,ptr %out,i64 72
 store i64 %word3_0,ptr %out3_0,align 1
 %shift3_1 = lshr i140 %r3,64
 %word3_1 = trunc i140 %shift3_1 to i64
 %out3_1 = getelementptr i8,ptr %out,i64 80
 store i64 %word3_1,ptr %out3_1,align 1
 %shift3_2 = lshr i140 %r3,128
 %word3_2 = trunc i140 %shift3_2 to i64
 %out3_2 = getelementptr i8,ptr %out,i64 88
 store i64 %word3_2,ptr %out3_2,align 1
 %word4_0 = trunc i200 %r4 to i64
 %out4_0 = getelementptr i8,ptr %out,i64 96
 store i64 %word4_0,ptr %out4_0,align 1
 %shift4_1 = lshr i200 %r4,64
 %word4_1 = trunc i200 %shift4_1 to i64
 %out4_1 = getelementptr i8,ptr %out,i64 104
 store i64 %word4_1,ptr %out4_1,align 1
 %shift4_2 = lshr i200 %r4,128
 %word4_2 = trunc i200 %shift4_2 to i64
 %out4_2 = getelementptr i8,ptr %out,i64 112
 store i64 %word4_2,ptr %out4_2,align 1
 %shift4_3 = lshr i200 %r4,192
 %word4_3 = trunc i200 %shift4_3 to i64
 %out4_3 = getelementptr i8,ptr %out,i64 120
 store i64 %word4_3,ptr %out4_3,align 1
 %word5_0 = trunc i200 %r5 to i64
 %out5_0 = getelementptr i8,ptr %out,i64 128
 store i64 %word5_0,ptr %out5_0,align 1
 %shift5_1 = lshr i200 %r5,64
 %word5_1 = trunc i200 %shift5_1 to i64
 %out5_1 = getelementptr i8,ptr %out,i64 136
 store i64 %word5_1,ptr %out5_1,align 1
 %shift5_2 = lshr i200 %r5,128
 %word5_2 = trunc i200 %shift5_2 to i64
 %out5_2 = getelementptr i8,ptr %out,i64 144
 store i64 %word5_2,ptr %out5_2,align 1
 %shift5_3 = lshr i200 %r5,192
 %word5_3 = trunc i200 %shift5_3 to i64
 %out5_3 = getelementptr i8,ptr %out,i64 152
 store i64 %word5_3,ptr %out5_3,align 1
 %mp = getelementptr i8,ptr %out,i64 160
 store i64 %mask,ptr %mp,align 1
 %op = getelementptr i8,ptr %out,i64 168
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %mask,%token
 ret i64 %answer
}
define i64 @wide_saturation_vector_probe_39(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %temporary = alloca [160 x i8],align 16
 %constant = alloca i140,align 16
 store i140 1267650600228229401496703205376,ptr %constant,align 16
 %bp = getelementptr i8,ptr %input,i64 32
 %sp = getelementptr i8,ptr %input,i64 64
 %s0 = load i64,ptr %sp,align 1
 %tp = getelementptr i8,ptr %input,i64 72
 %t0 = load i64,ptr %tp,align 1
 %temporary0 = getelementptr i8,ptr %temporary,i64 0
 call void @wide_sat_140_u_0(ptr %temporary0,ptr %input,i64 %s0)
 %temporary1 = getelementptr i8,ptr %temporary,i64 24
 call void @wide_sat_140_s_0(ptr %temporary1,ptr %input,i64 %s0)
 %temporary2 = getelementptr i8,ptr %temporary,i64 48
 call void @wide_sat_140_u_0(ptr %temporary2,ptr %constant,i64 %s0)
 %temporary3 = getelementptr i8,ptr %temporary,i64 72
 call void @wide_sat_140_s_0(ptr %temporary3,ptr %constant,i64 %s0)
 %temporary4 = getelementptr i8,ptr %temporary,i64 96
 call void @wide_sat_200_u_0(ptr %temporary4,ptr %bp,i64 %t0)
 %temporary5 = getelementptr i8,ptr %temporary,i64 128
 call void @wide_sat_200_s_0(ptr %temporary5,ptr %bp,i64 %t0)
 %r0 = load i140,ptr %temporary0,align 1
 %r1 = load i140,ptr %temporary1,align 1
 %r2 = load i140,ptr %temporary2,align 1
 %r3 = load i140,ptr %temporary3,align 1
 %r4 = load i200,ptr %temporary4,align 1
 %r5 = load i200,ptr %temporary5,align 1
 %v0 = insertelement <4 x i140> poison,i140 %r0,i64 0
 %v1 = insertelement <4 x i140> %v0,i140 %r1,i64 1
 %v2 = insertelement <4 x i140> %v1,i140 %r2,i64 2
 %v3 = insertelement <4 x i140> %v2,i140 %r3,i64 3
 %w0 = insertelement <4 x i140> poison,i140 0,i32 0
 %w1 = insertelement <4 x i140> %w0,i140 -1,i32 1
 %w2 = insertelement <4 x i140> %w1,i140 696898287454081973172991196020261297061887,i32 2
 %w3 = insertelement <4 x i140> %w2,i140 -696898287454081973172991196020261297061888,i32 3
 %cmp = icmp sgt <4 x i140> %v3,%w3
 %packed_mask = bitcast <4 x i1> %cmp to i4
 %mask = zext i4 %packed_mask to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %word0_0 = trunc i140 %r0 to i64
 %out0_0 = getelementptr i8,ptr %out,i64 0
 store i64 %word0_0,ptr %out0_0,align 1
 %shift0_1 = lshr i140 %r0,64
 %word0_1 = trunc i140 %shift0_1 to i64
 %out0_1 = getelementptr i8,ptr %out,i64 8
 store i64 %word0_1,ptr %out0_1,align 1
 %shift0_2 = lshr i140 %r0,128
 %word0_2 = trunc i140 %shift0_2 to i64
 %out0_2 = getelementptr i8,ptr %out,i64 16
 store i64 %word0_2,ptr %out0_2,align 1
 %word1_0 = trunc i140 %r1 to i64
 %out1_0 = getelementptr i8,ptr %out,i64 24
 store i64 %word1_0,ptr %out1_0,align 1
 %shift1_1 = lshr i140 %r1,64
 %word1_1 = trunc i140 %shift1_1 to i64
 %out1_1 = getelementptr i8,ptr %out,i64 32
 store i64 %word1_1,ptr %out1_1,align 1
 %shift1_2 = lshr i140 %r1,128
 %word1_2 = trunc i140 %shift1_2 to i64
 %out1_2 = getelementptr i8,ptr %out,i64 40
 store i64 %word1_2,ptr %out1_2,align 1
 %word2_0 = trunc i140 %r2 to i64
 %out2_0 = getelementptr i8,ptr %out,i64 48
 store i64 %word2_0,ptr %out2_0,align 1
 %shift2_1 = lshr i140 %r2,64
 %word2_1 = trunc i140 %shift2_1 to i64
 %out2_1 = getelementptr i8,ptr %out,i64 56
 store i64 %word2_1,ptr %out2_1,align 1
 %shift2_2 = lshr i140 %r2,128
 %word2_2 = trunc i140 %shift2_2 to i64
 %out2_2 = getelementptr i8,ptr %out,i64 64
 store i64 %word2_2,ptr %out2_2,align 1
 %word3_0 = trunc i140 %r3 to i64
 %out3_0 = getelementptr i8,ptr %out,i64 72
 store i64 %word3_0,ptr %out3_0,align 1
 %shift3_1 = lshr i140 %r3,64
 %word3_1 = trunc i140 %shift3_1 to i64
 %out3_1 = getelementptr i8,ptr %out,i64 80
 store i64 %word3_1,ptr %out3_1,align 1
 %shift3_2 = lshr i140 %r3,128
 %word3_2 = trunc i140 %shift3_2 to i64
 %out3_2 = getelementptr i8,ptr %out,i64 88
 store i64 %word3_2,ptr %out3_2,align 1
 %word4_0 = trunc i200 %r4 to i64
 %out4_0 = getelementptr i8,ptr %out,i64 96
 store i64 %word4_0,ptr %out4_0,align 1
 %shift4_1 = lshr i200 %r4,64
 %word4_1 = trunc i200 %shift4_1 to i64
 %out4_1 = getelementptr i8,ptr %out,i64 104
 store i64 %word4_1,ptr %out4_1,align 1
 %shift4_2 = lshr i200 %r4,128
 %word4_2 = trunc i200 %shift4_2 to i64
 %out4_2 = getelementptr i8,ptr %out,i64 112
 store i64 %word4_2,ptr %out4_2,align 1
 %shift4_3 = lshr i200 %r4,192
 %word4_3 = trunc i200 %shift4_3 to i64
 %out4_3 = getelementptr i8,ptr %out,i64 120
 store i64 %word4_3,ptr %out4_3,align 1
 %word5_0 = trunc i200 %r5 to i64
 %out5_0 = getelementptr i8,ptr %out,i64 128
 store i64 %word5_0,ptr %out5_0,align 1
 %shift5_1 = lshr i200 %r5,64
 %word5_1 = trunc i200 %shift5_1 to i64
 %out5_1 = getelementptr i8,ptr %out,i64 136
 store i64 %word5_1,ptr %out5_1,align 1
 %shift5_2 = lshr i200 %r5,128
 %word5_2 = trunc i200 %shift5_2 to i64
 %out5_2 = getelementptr i8,ptr %out,i64 144
 store i64 %word5_2,ptr %out5_2,align 1
 %shift5_3 = lshr i200 %r5,192
 %word5_3 = trunc i200 %shift5_3 to i64
 %out5_3 = getelementptr i8,ptr %out,i64 152
 store i64 %word5_3,ptr %out5_3,align 1
 %mp = getelementptr i8,ptr %out,i64 160
 store i64 %mask,ptr %mp,align 1
 %op = getelementptr i8,ptr %out,i64 168
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %mask,%token
 ret i64 %answer
}
define i64 @wide_saturation_vector_probe_40(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %temporary = alloca [160 x i8],align 16
 %constant = alloca i140,align 16
 store i140 1267650600228229401496703205376,ptr %constant,align 16
 %bp = getelementptr i8,ptr %input,i64 32
 %sp = getelementptr i8,ptr %input,i64 64
 %s0 = load i64,ptr %sp,align 1
 %tp = getelementptr i8,ptr %input,i64 72
 %t0 = load i64,ptr %tp,align 1
 %temporary0 = getelementptr i8,ptr %temporary,i64 0
 call void @wide_sat_140_u_1(ptr %temporary0,ptr %input,i64 %s0)
 %temporary1 = getelementptr i8,ptr %temporary,i64 24
 call void @wide_sat_140_s_1(ptr %temporary1,ptr %input,i64 %s0)
 %temporary2 = getelementptr i8,ptr %temporary,i64 48
 call void @wide_sat_140_u_1(ptr %temporary2,ptr %constant,i64 %s0)
 %temporary3 = getelementptr i8,ptr %temporary,i64 72
 call void @wide_sat_140_s_1(ptr %temporary3,ptr %constant,i64 %s0)
 %temporary4 = getelementptr i8,ptr %temporary,i64 96
 call void @wide_sat_200_u_1(ptr %temporary4,ptr %bp,i64 %t0)
 %temporary5 = getelementptr i8,ptr %temporary,i64 128
 call void @wide_sat_200_s_1(ptr %temporary5,ptr %bp,i64 %t0)
 %r0 = load i140,ptr %temporary0,align 1
 %r1 = load i140,ptr %temporary1,align 1
 %r2 = load i140,ptr %temporary2,align 1
 %r3 = load i140,ptr %temporary3,align 1
 %r4 = load i200,ptr %temporary4,align 1
 %r5 = load i200,ptr %temporary5,align 1
 %v0 = insertelement <4 x i140> poison,i140 %r0,i64 0
 %v1 = insertelement <4 x i140> %v0,i140 %r1,i64 1
 %v2 = insertelement <4 x i140> %v1,i140 %r2,i64 2
 %v3 = insertelement <4 x i140> %v2,i140 %r3,i64 3
 %w0 = insertelement <4 x i140> poison,i140 0,i32 0
 %w1 = insertelement <4 x i140> %w0,i140 -1,i32 1
 %w2 = insertelement <4 x i140> %w1,i140 696898287454081973172991196020261297061887,i32 2
 %w3 = insertelement <4 x i140> %w2,i140 -696898287454081973172991196020261297061888,i32 3
 %cmp = icmp sgt <4 x i140> %v3,%w3
 %packed_mask = bitcast <4 x i1> %cmp to i4
 %mask = zext i4 %packed_mask to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %word0_0 = trunc i140 %r0 to i64
 %out0_0 = getelementptr i8,ptr %out,i64 0
 store i64 %word0_0,ptr %out0_0,align 1
 %shift0_1 = lshr i140 %r0,64
 %word0_1 = trunc i140 %shift0_1 to i64
 %out0_1 = getelementptr i8,ptr %out,i64 8
 store i64 %word0_1,ptr %out0_1,align 1
 %shift0_2 = lshr i140 %r0,128
 %word0_2 = trunc i140 %shift0_2 to i64
 %out0_2 = getelementptr i8,ptr %out,i64 16
 store i64 %word0_2,ptr %out0_2,align 1
 %word1_0 = trunc i140 %r1 to i64
 %out1_0 = getelementptr i8,ptr %out,i64 24
 store i64 %word1_0,ptr %out1_0,align 1
 %shift1_1 = lshr i140 %r1,64
 %word1_1 = trunc i140 %shift1_1 to i64
 %out1_1 = getelementptr i8,ptr %out,i64 32
 store i64 %word1_1,ptr %out1_1,align 1
 %shift1_2 = lshr i140 %r1,128
 %word1_2 = trunc i140 %shift1_2 to i64
 %out1_2 = getelementptr i8,ptr %out,i64 40
 store i64 %word1_2,ptr %out1_2,align 1
 %word2_0 = trunc i140 %r2 to i64
 %out2_0 = getelementptr i8,ptr %out,i64 48
 store i64 %word2_0,ptr %out2_0,align 1
 %shift2_1 = lshr i140 %r2,64
 %word2_1 = trunc i140 %shift2_1 to i64
 %out2_1 = getelementptr i8,ptr %out,i64 56
 store i64 %word2_1,ptr %out2_1,align 1
 %shift2_2 = lshr i140 %r2,128
 %word2_2 = trunc i140 %shift2_2 to i64
 %out2_2 = getelementptr i8,ptr %out,i64 64
 store i64 %word2_2,ptr %out2_2,align 1
 %word3_0 = trunc i140 %r3 to i64
 %out3_0 = getelementptr i8,ptr %out,i64 72
 store i64 %word3_0,ptr %out3_0,align 1
 %shift3_1 = lshr i140 %r3,64
 %word3_1 = trunc i140 %shift3_1 to i64
 %out3_1 = getelementptr i8,ptr %out,i64 80
 store i64 %word3_1,ptr %out3_1,align 1
 %shift3_2 = lshr i140 %r3,128
 %word3_2 = trunc i140 %shift3_2 to i64
 %out3_2 = getelementptr i8,ptr %out,i64 88
 store i64 %word3_2,ptr %out3_2,align 1
 %word4_0 = trunc i200 %r4 to i64
 %out4_0 = getelementptr i8,ptr %out,i64 96
 store i64 %word4_0,ptr %out4_0,align 1
 %shift4_1 = lshr i200 %r4,64
 %word4_1 = trunc i200 %shift4_1 to i64
 %out4_1 = getelementptr i8,ptr %out,i64 104
 store i64 %word4_1,ptr %out4_1,align 1
 %shift4_2 = lshr i200 %r4,128
 %word4_2 = trunc i200 %shift4_2 to i64
 %out4_2 = getelementptr i8,ptr %out,i64 112
 store i64 %word4_2,ptr %out4_2,align 1
 %shift4_3 = lshr i200 %r4,192
 %word4_3 = trunc i200 %shift4_3 to i64
 %out4_3 = getelementptr i8,ptr %out,i64 120
 store i64 %word4_3,ptr %out4_3,align 1
 %word5_0 = trunc i200 %r5 to i64
 %out5_0 = getelementptr i8,ptr %out,i64 128
 store i64 %word5_0,ptr %out5_0,align 1
 %shift5_1 = lshr i200 %r5,64
 %word5_1 = trunc i200 %shift5_1 to i64
 %out5_1 = getelementptr i8,ptr %out,i64 136
 store i64 %word5_1,ptr %out5_1,align 1
 %shift5_2 = lshr i200 %r5,128
 %word5_2 = trunc i200 %shift5_2 to i64
 %out5_2 = getelementptr i8,ptr %out,i64 144
 store i64 %word5_2,ptr %out5_2,align 1
 %shift5_3 = lshr i200 %r5,192
 %word5_3 = trunc i200 %shift5_3 to i64
 %out5_3 = getelementptr i8,ptr %out,i64 152
 store i64 %word5_3,ptr %out5_3,align 1
 %mp = getelementptr i8,ptr %out,i64 160
 store i64 %mask,ptr %mp,align 1
 %op = getelementptr i8,ptr %out,i64 168
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %mask,%token
 ret i64 %answer
}
define i64 @wide_saturation_vector_probe_41(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %temporary = alloca [160 x i8],align 16
 %constant = alloca i140,align 16
 store i140 1267650600228229401496703205376,ptr %constant,align 16
 %bp = getelementptr i8,ptr %input,i64 32
 %sp = getelementptr i8,ptr %input,i64 64
 %s0 = load i64,ptr %sp,align 1
 %tp = getelementptr i8,ptr %input,i64 72
 %t0 = load i64,ptr %tp,align 1
 %temporary0 = getelementptr i8,ptr %temporary,i64 0
 call void @wide_sat_140_u_2(ptr %temporary0,ptr %input,i64 %s0)
 %temporary1 = getelementptr i8,ptr %temporary,i64 24
 call void @wide_sat_140_s_2(ptr %temporary1,ptr %input,i64 %s0)
 %temporary2 = getelementptr i8,ptr %temporary,i64 48
 call void @wide_sat_140_u_2(ptr %temporary2,ptr %constant,i64 %s0)
 %temporary3 = getelementptr i8,ptr %temporary,i64 72
 call void @wide_sat_140_s_2(ptr %temporary3,ptr %constant,i64 %s0)
 %temporary4 = getelementptr i8,ptr %temporary,i64 96
 call void @wide_sat_200_u_2(ptr %temporary4,ptr %bp,i64 %t0)
 %temporary5 = getelementptr i8,ptr %temporary,i64 128
 call void @wide_sat_200_s_2(ptr %temporary5,ptr %bp,i64 %t0)
 %r0 = load i140,ptr %temporary0,align 1
 %r1 = load i140,ptr %temporary1,align 1
 %r2 = load i140,ptr %temporary2,align 1
 %r3 = load i140,ptr %temporary3,align 1
 %r4 = load i200,ptr %temporary4,align 1
 %r5 = load i200,ptr %temporary5,align 1
 %v0 = insertelement <4 x i140> poison,i140 %r0,i64 0
 %v1 = insertelement <4 x i140> %v0,i140 %r1,i64 1
 %v2 = insertelement <4 x i140> %v1,i140 %r2,i64 2
 %v3 = insertelement <4 x i140> %v2,i140 %r3,i64 3
 %w0 = insertelement <4 x i140> poison,i140 0,i32 0
 %w1 = insertelement <4 x i140> %w0,i140 -1,i32 1
 %w2 = insertelement <4 x i140> %w1,i140 696898287454081973172991196020261297061887,i32 2
 %w3 = insertelement <4 x i140> %w2,i140 -696898287454081973172991196020261297061888,i32 3
 %cmp = icmp sgt <4 x i140> %v3,%w3
 %packed_mask = bitcast <4 x i1> %cmp to i4
 %mask = zext i4 %packed_mask to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %word0_0 = trunc i140 %r0 to i64
 %out0_0 = getelementptr i8,ptr %out,i64 0
 store i64 %word0_0,ptr %out0_0,align 1
 %shift0_1 = lshr i140 %r0,64
 %word0_1 = trunc i140 %shift0_1 to i64
 %out0_1 = getelementptr i8,ptr %out,i64 8
 store i64 %word0_1,ptr %out0_1,align 1
 %shift0_2 = lshr i140 %r0,128
 %word0_2 = trunc i140 %shift0_2 to i64
 %out0_2 = getelementptr i8,ptr %out,i64 16
 store i64 %word0_2,ptr %out0_2,align 1
 %word1_0 = trunc i140 %r1 to i64
 %out1_0 = getelementptr i8,ptr %out,i64 24
 store i64 %word1_0,ptr %out1_0,align 1
 %shift1_1 = lshr i140 %r1,64
 %word1_1 = trunc i140 %shift1_1 to i64
 %out1_1 = getelementptr i8,ptr %out,i64 32
 store i64 %word1_1,ptr %out1_1,align 1
 %shift1_2 = lshr i140 %r1,128
 %word1_2 = trunc i140 %shift1_2 to i64
 %out1_2 = getelementptr i8,ptr %out,i64 40
 store i64 %word1_2,ptr %out1_2,align 1
 %word2_0 = trunc i140 %r2 to i64
 %out2_0 = getelementptr i8,ptr %out,i64 48
 store i64 %word2_0,ptr %out2_0,align 1
 %shift2_1 = lshr i140 %r2,64
 %word2_1 = trunc i140 %shift2_1 to i64
 %out2_1 = getelementptr i8,ptr %out,i64 56
 store i64 %word2_1,ptr %out2_1,align 1
 %shift2_2 = lshr i140 %r2,128
 %word2_2 = trunc i140 %shift2_2 to i64
 %out2_2 = getelementptr i8,ptr %out,i64 64
 store i64 %word2_2,ptr %out2_2,align 1
 %word3_0 = trunc i140 %r3 to i64
 %out3_0 = getelementptr i8,ptr %out,i64 72
 store i64 %word3_0,ptr %out3_0,align 1
 %shift3_1 = lshr i140 %r3,64
 %word3_1 = trunc i140 %shift3_1 to i64
 %out3_1 = getelementptr i8,ptr %out,i64 80
 store i64 %word3_1,ptr %out3_1,align 1
 %shift3_2 = lshr i140 %r3,128
 %word3_2 = trunc i140 %shift3_2 to i64
 %out3_2 = getelementptr i8,ptr %out,i64 88
 store i64 %word3_2,ptr %out3_2,align 1
 %word4_0 = trunc i200 %r4 to i64
 %out4_0 = getelementptr i8,ptr %out,i64 96
 store i64 %word4_0,ptr %out4_0,align 1
 %shift4_1 = lshr i200 %r4,64
 %word4_1 = trunc i200 %shift4_1 to i64
 %out4_1 = getelementptr i8,ptr %out,i64 104
 store i64 %word4_1,ptr %out4_1,align 1
 %shift4_2 = lshr i200 %r4,128
 %word4_2 = trunc i200 %shift4_2 to i64
 %out4_2 = getelementptr i8,ptr %out,i64 112
 store i64 %word4_2,ptr %out4_2,align 1
 %shift4_3 = lshr i200 %r4,192
 %word4_3 = trunc i200 %shift4_3 to i64
 %out4_3 = getelementptr i8,ptr %out,i64 120
 store i64 %word4_3,ptr %out4_3,align 1
 %word5_0 = trunc i200 %r5 to i64
 %out5_0 = getelementptr i8,ptr %out,i64 128
 store i64 %word5_0,ptr %out5_0,align 1
 %shift5_1 = lshr i200 %r5,64
 %word5_1 = trunc i200 %shift5_1 to i64
 %out5_1 = getelementptr i8,ptr %out,i64 136
 store i64 %word5_1,ptr %out5_1,align 1
 %shift5_2 = lshr i200 %r5,128
 %word5_2 = trunc i200 %shift5_2 to i64
 %out5_2 = getelementptr i8,ptr %out,i64 144
 store i64 %word5_2,ptr %out5_2,align 1
 %shift5_3 = lshr i200 %r5,192
 %word5_3 = trunc i200 %shift5_3 to i64
 %out5_3 = getelementptr i8,ptr %out,i64 152
 store i64 %word5_3,ptr %out5_3,align 1
 %mp = getelementptr i8,ptr %out,i64 160
 store i64 %mask,ptr %mp,align 1
 %op = getelementptr i8,ptr %out,i64 168
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %mask,%token
 ret i64 %answer
}
define i64 @wide_saturation_vector_probe_42(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %temporary = alloca [160 x i8],align 16
 %constant = alloca i140,align 16
 store i140 1267650600228229401496703205376,ptr %constant,align 16
 %bp = getelementptr i8,ptr %input,i64 32
 %sp = getelementptr i8,ptr %input,i64 64
 %s0 = load i64,ptr %sp,align 1
 %tp = getelementptr i8,ptr %input,i64 72
 %t0 = load i64,ptr %tp,align 1
 %temporary0 = getelementptr i8,ptr %temporary,i64 0
 call void @wide_sat_140_u_0(ptr %temporary0,ptr %input,i64 %s0)
 %temporary1 = getelementptr i8,ptr %temporary,i64 24
 call void @wide_sat_140_s_0(ptr %temporary1,ptr %input,i64 %s0)
 %temporary2 = getelementptr i8,ptr %temporary,i64 48
 call void @wide_sat_140_u_0(ptr %temporary2,ptr %constant,i64 %s0)
 %temporary3 = getelementptr i8,ptr %temporary,i64 72
 call void @wide_sat_140_s_0(ptr %temporary3,ptr %constant,i64 %s0)
 %temporary4 = getelementptr i8,ptr %temporary,i64 96
 call void @wide_sat_200_u_0(ptr %temporary4,ptr %bp,i64 %t0)
 %temporary5 = getelementptr i8,ptr %temporary,i64 128
 call void @wide_sat_200_s_0(ptr %temporary5,ptr %bp,i64 %t0)
 %r0 = load i140,ptr %temporary0,align 1
 %r1 = load i140,ptr %temporary1,align 1
 %r2 = load i140,ptr %temporary2,align 1
 %r3 = load i140,ptr %temporary3,align 1
 %r4 = load i200,ptr %temporary4,align 1
 %r5 = load i200,ptr %temporary5,align 1
 %v0 = insertelement <4 x i140> poison,i140 %r0,i64 0
 %v1 = insertelement <4 x i140> %v0,i140 %r1,i64 1
 %v2 = insertelement <4 x i140> %v1,i140 %r2,i64 2
 %v3 = insertelement <4 x i140> %v2,i140 %r3,i64 3
 %cmp = icmp sge <4 x i140> %v3,<i140 0,i140 -1,i140 696898287454081973172991196020261297061887,i140 -696898287454081973172991196020261297061888>
 %packed_mask = bitcast <4 x i1> %cmp to i4
 %mask = zext i4 %packed_mask to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %word0_0 = trunc i140 %r0 to i64
 %out0_0 = getelementptr i8,ptr %out,i64 0
 store i64 %word0_0,ptr %out0_0,align 1
 %shift0_1 = lshr i140 %r0,64
 %word0_1 = trunc i140 %shift0_1 to i64
 %out0_1 = getelementptr i8,ptr %out,i64 8
 store i64 %word0_1,ptr %out0_1,align 1
 %shift0_2 = lshr i140 %r0,128
 %word0_2 = trunc i140 %shift0_2 to i64
 %out0_2 = getelementptr i8,ptr %out,i64 16
 store i64 %word0_2,ptr %out0_2,align 1
 %word1_0 = trunc i140 %r1 to i64
 %out1_0 = getelementptr i8,ptr %out,i64 24
 store i64 %word1_0,ptr %out1_0,align 1
 %shift1_1 = lshr i140 %r1,64
 %word1_1 = trunc i140 %shift1_1 to i64
 %out1_1 = getelementptr i8,ptr %out,i64 32
 store i64 %word1_1,ptr %out1_1,align 1
 %shift1_2 = lshr i140 %r1,128
 %word1_2 = trunc i140 %shift1_2 to i64
 %out1_2 = getelementptr i8,ptr %out,i64 40
 store i64 %word1_2,ptr %out1_2,align 1
 %word2_0 = trunc i140 %r2 to i64
 %out2_0 = getelementptr i8,ptr %out,i64 48
 store i64 %word2_0,ptr %out2_0,align 1
 %shift2_1 = lshr i140 %r2,64
 %word2_1 = trunc i140 %shift2_1 to i64
 %out2_1 = getelementptr i8,ptr %out,i64 56
 store i64 %word2_1,ptr %out2_1,align 1
 %shift2_2 = lshr i140 %r2,128
 %word2_2 = trunc i140 %shift2_2 to i64
 %out2_2 = getelementptr i8,ptr %out,i64 64
 store i64 %word2_2,ptr %out2_2,align 1
 %word3_0 = trunc i140 %r3 to i64
 %out3_0 = getelementptr i8,ptr %out,i64 72
 store i64 %word3_0,ptr %out3_0,align 1
 %shift3_1 = lshr i140 %r3,64
 %word3_1 = trunc i140 %shift3_1 to i64
 %out3_1 = getelementptr i8,ptr %out,i64 80
 store i64 %word3_1,ptr %out3_1,align 1
 %shift3_2 = lshr i140 %r3,128
 %word3_2 = trunc i140 %shift3_2 to i64
 %out3_2 = getelementptr i8,ptr %out,i64 88
 store i64 %word3_2,ptr %out3_2,align 1
 %word4_0 = trunc i200 %r4 to i64
 %out4_0 = getelementptr i8,ptr %out,i64 96
 store i64 %word4_0,ptr %out4_0,align 1
 %shift4_1 = lshr i200 %r4,64
 %word4_1 = trunc i200 %shift4_1 to i64
 %out4_1 = getelementptr i8,ptr %out,i64 104
 store i64 %word4_1,ptr %out4_1,align 1
 %shift4_2 = lshr i200 %r4,128
 %word4_2 = trunc i200 %shift4_2 to i64
 %out4_2 = getelementptr i8,ptr %out,i64 112
 store i64 %word4_2,ptr %out4_2,align 1
 %shift4_3 = lshr i200 %r4,192
 %word4_3 = trunc i200 %shift4_3 to i64
 %out4_3 = getelementptr i8,ptr %out,i64 120
 store i64 %word4_3,ptr %out4_3,align 1
 %word5_0 = trunc i200 %r5 to i64
 %out5_0 = getelementptr i8,ptr %out,i64 128
 store i64 %word5_0,ptr %out5_0,align 1
 %shift5_1 = lshr i200 %r5,64
 %word5_1 = trunc i200 %shift5_1 to i64
 %out5_1 = getelementptr i8,ptr %out,i64 136
 store i64 %word5_1,ptr %out5_1,align 1
 %shift5_2 = lshr i200 %r5,128
 %word5_2 = trunc i200 %shift5_2 to i64
 %out5_2 = getelementptr i8,ptr %out,i64 144
 store i64 %word5_2,ptr %out5_2,align 1
 %shift5_3 = lshr i200 %r5,192
 %word5_3 = trunc i200 %shift5_3 to i64
 %out5_3 = getelementptr i8,ptr %out,i64 152
 store i64 %word5_3,ptr %out5_3,align 1
 %mp = getelementptr i8,ptr %out,i64 160
 store i64 %mask,ptr %mp,align 1
 %op = getelementptr i8,ptr %out,i64 168
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %mask,%token
 ret i64 %answer
}
define i64 @wide_saturation_vector_probe_43(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %temporary = alloca [160 x i8],align 16
 %constant = alloca i140,align 16
 store i140 1267650600228229401496703205376,ptr %constant,align 16
 %bp = getelementptr i8,ptr %input,i64 32
 %sp = getelementptr i8,ptr %input,i64 64
 %s0 = load i64,ptr %sp,align 1
 %tp = getelementptr i8,ptr %input,i64 72
 %t0 = load i64,ptr %tp,align 1
 %temporary0 = getelementptr i8,ptr %temporary,i64 0
 call void @wide_sat_140_u_1(ptr %temporary0,ptr %input,i64 %s0)
 %temporary1 = getelementptr i8,ptr %temporary,i64 24
 call void @wide_sat_140_s_1(ptr %temporary1,ptr %input,i64 %s0)
 %temporary2 = getelementptr i8,ptr %temporary,i64 48
 call void @wide_sat_140_u_1(ptr %temporary2,ptr %constant,i64 %s0)
 %temporary3 = getelementptr i8,ptr %temporary,i64 72
 call void @wide_sat_140_s_1(ptr %temporary3,ptr %constant,i64 %s0)
 %temporary4 = getelementptr i8,ptr %temporary,i64 96
 call void @wide_sat_200_u_1(ptr %temporary4,ptr %bp,i64 %t0)
 %temporary5 = getelementptr i8,ptr %temporary,i64 128
 call void @wide_sat_200_s_1(ptr %temporary5,ptr %bp,i64 %t0)
 %r0 = load i140,ptr %temporary0,align 1
 %r1 = load i140,ptr %temporary1,align 1
 %r2 = load i140,ptr %temporary2,align 1
 %r3 = load i140,ptr %temporary3,align 1
 %r4 = load i200,ptr %temporary4,align 1
 %r5 = load i200,ptr %temporary5,align 1
 %v0 = insertelement <4 x i140> poison,i140 %r0,i64 0
 %v1 = insertelement <4 x i140> %v0,i140 %r1,i64 1
 %v2 = insertelement <4 x i140> %v1,i140 %r2,i64 2
 %v3 = insertelement <4 x i140> %v2,i140 %r3,i64 3
 %cmp = icmp sge <4 x i140> %v3,<i140 0,i140 -1,i140 696898287454081973172991196020261297061887,i140 -696898287454081973172991196020261297061888>
 %packed_mask = bitcast <4 x i1> %cmp to i4
 %mask = zext i4 %packed_mask to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %word0_0 = trunc i140 %r0 to i64
 %out0_0 = getelementptr i8,ptr %out,i64 0
 store i64 %word0_0,ptr %out0_0,align 1
 %shift0_1 = lshr i140 %r0,64
 %word0_1 = trunc i140 %shift0_1 to i64
 %out0_1 = getelementptr i8,ptr %out,i64 8
 store i64 %word0_1,ptr %out0_1,align 1
 %shift0_2 = lshr i140 %r0,128
 %word0_2 = trunc i140 %shift0_2 to i64
 %out0_2 = getelementptr i8,ptr %out,i64 16
 store i64 %word0_2,ptr %out0_2,align 1
 %word1_0 = trunc i140 %r1 to i64
 %out1_0 = getelementptr i8,ptr %out,i64 24
 store i64 %word1_0,ptr %out1_0,align 1
 %shift1_1 = lshr i140 %r1,64
 %word1_1 = trunc i140 %shift1_1 to i64
 %out1_1 = getelementptr i8,ptr %out,i64 32
 store i64 %word1_1,ptr %out1_1,align 1
 %shift1_2 = lshr i140 %r1,128
 %word1_2 = trunc i140 %shift1_2 to i64
 %out1_2 = getelementptr i8,ptr %out,i64 40
 store i64 %word1_2,ptr %out1_2,align 1
 %word2_0 = trunc i140 %r2 to i64
 %out2_0 = getelementptr i8,ptr %out,i64 48
 store i64 %word2_0,ptr %out2_0,align 1
 %shift2_1 = lshr i140 %r2,64
 %word2_1 = trunc i140 %shift2_1 to i64
 %out2_1 = getelementptr i8,ptr %out,i64 56
 store i64 %word2_1,ptr %out2_1,align 1
 %shift2_2 = lshr i140 %r2,128
 %word2_2 = trunc i140 %shift2_2 to i64
 %out2_2 = getelementptr i8,ptr %out,i64 64
 store i64 %word2_2,ptr %out2_2,align 1
 %word3_0 = trunc i140 %r3 to i64
 %out3_0 = getelementptr i8,ptr %out,i64 72
 store i64 %word3_0,ptr %out3_0,align 1
 %shift3_1 = lshr i140 %r3,64
 %word3_1 = trunc i140 %shift3_1 to i64
 %out3_1 = getelementptr i8,ptr %out,i64 80
 store i64 %word3_1,ptr %out3_1,align 1
 %shift3_2 = lshr i140 %r3,128
 %word3_2 = trunc i140 %shift3_2 to i64
 %out3_2 = getelementptr i8,ptr %out,i64 88
 store i64 %word3_2,ptr %out3_2,align 1
 %word4_0 = trunc i200 %r4 to i64
 %out4_0 = getelementptr i8,ptr %out,i64 96
 store i64 %word4_0,ptr %out4_0,align 1
 %shift4_1 = lshr i200 %r4,64
 %word4_1 = trunc i200 %shift4_1 to i64
 %out4_1 = getelementptr i8,ptr %out,i64 104
 store i64 %word4_1,ptr %out4_1,align 1
 %shift4_2 = lshr i200 %r4,128
 %word4_2 = trunc i200 %shift4_2 to i64
 %out4_2 = getelementptr i8,ptr %out,i64 112
 store i64 %word4_2,ptr %out4_2,align 1
 %shift4_3 = lshr i200 %r4,192
 %word4_3 = trunc i200 %shift4_3 to i64
 %out4_3 = getelementptr i8,ptr %out,i64 120
 store i64 %word4_3,ptr %out4_3,align 1
 %word5_0 = trunc i200 %r5 to i64
 %out5_0 = getelementptr i8,ptr %out,i64 128
 store i64 %word5_0,ptr %out5_0,align 1
 %shift5_1 = lshr i200 %r5,64
 %word5_1 = trunc i200 %shift5_1 to i64
 %out5_1 = getelementptr i8,ptr %out,i64 136
 store i64 %word5_1,ptr %out5_1,align 1
 %shift5_2 = lshr i200 %r5,128
 %word5_2 = trunc i200 %shift5_2 to i64
 %out5_2 = getelementptr i8,ptr %out,i64 144
 store i64 %word5_2,ptr %out5_2,align 1
 %shift5_3 = lshr i200 %r5,192
 %word5_3 = trunc i200 %shift5_3 to i64
 %out5_3 = getelementptr i8,ptr %out,i64 152
 store i64 %word5_3,ptr %out5_3,align 1
 %mp = getelementptr i8,ptr %out,i64 160
 store i64 %mask,ptr %mp,align 1
 %op = getelementptr i8,ptr %out,i64 168
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %mask,%token
 ret i64 %answer
}
define i64 @wide_saturation_vector_probe_44(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %temporary = alloca [160 x i8],align 16
 %constant = alloca i140,align 16
 store i140 1267650600228229401496703205376,ptr %constant,align 16
 %bp = getelementptr i8,ptr %input,i64 32
 %sp = getelementptr i8,ptr %input,i64 64
 %s0 = load i64,ptr %sp,align 1
 %tp = getelementptr i8,ptr %input,i64 72
 %t0 = load i64,ptr %tp,align 1
 %temporary0 = getelementptr i8,ptr %temporary,i64 0
 call void @wide_sat_140_u_2(ptr %temporary0,ptr %input,i64 %s0)
 %temporary1 = getelementptr i8,ptr %temporary,i64 24
 call void @wide_sat_140_s_2(ptr %temporary1,ptr %input,i64 %s0)
 %temporary2 = getelementptr i8,ptr %temporary,i64 48
 call void @wide_sat_140_u_2(ptr %temporary2,ptr %constant,i64 %s0)
 %temporary3 = getelementptr i8,ptr %temporary,i64 72
 call void @wide_sat_140_s_2(ptr %temporary3,ptr %constant,i64 %s0)
 %temporary4 = getelementptr i8,ptr %temporary,i64 96
 call void @wide_sat_200_u_2(ptr %temporary4,ptr %bp,i64 %t0)
 %temporary5 = getelementptr i8,ptr %temporary,i64 128
 call void @wide_sat_200_s_2(ptr %temporary5,ptr %bp,i64 %t0)
 %r0 = load i140,ptr %temporary0,align 1
 %r1 = load i140,ptr %temporary1,align 1
 %r2 = load i140,ptr %temporary2,align 1
 %r3 = load i140,ptr %temporary3,align 1
 %r4 = load i200,ptr %temporary4,align 1
 %r5 = load i200,ptr %temporary5,align 1
 %v0 = insertelement <4 x i140> poison,i140 %r0,i64 0
 %v1 = insertelement <4 x i140> %v0,i140 %r1,i64 1
 %v2 = insertelement <4 x i140> %v1,i140 %r2,i64 2
 %v3 = insertelement <4 x i140> %v2,i140 %r3,i64 3
 %cmp = icmp sge <4 x i140> %v3,<i140 0,i140 -1,i140 696898287454081973172991196020261297061887,i140 -696898287454081973172991196020261297061888>
 %packed_mask = bitcast <4 x i1> %cmp to i4
 %mask = zext i4 %packed_mask to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %word0_0 = trunc i140 %r0 to i64
 %out0_0 = getelementptr i8,ptr %out,i64 0
 store i64 %word0_0,ptr %out0_0,align 1
 %shift0_1 = lshr i140 %r0,64
 %word0_1 = trunc i140 %shift0_1 to i64
 %out0_1 = getelementptr i8,ptr %out,i64 8
 store i64 %word0_1,ptr %out0_1,align 1
 %shift0_2 = lshr i140 %r0,128
 %word0_2 = trunc i140 %shift0_2 to i64
 %out0_2 = getelementptr i8,ptr %out,i64 16
 store i64 %word0_2,ptr %out0_2,align 1
 %word1_0 = trunc i140 %r1 to i64
 %out1_0 = getelementptr i8,ptr %out,i64 24
 store i64 %word1_0,ptr %out1_0,align 1
 %shift1_1 = lshr i140 %r1,64
 %word1_1 = trunc i140 %shift1_1 to i64
 %out1_1 = getelementptr i8,ptr %out,i64 32
 store i64 %word1_1,ptr %out1_1,align 1
 %shift1_2 = lshr i140 %r1,128
 %word1_2 = trunc i140 %shift1_2 to i64
 %out1_2 = getelementptr i8,ptr %out,i64 40
 store i64 %word1_2,ptr %out1_2,align 1
 %word2_0 = trunc i140 %r2 to i64
 %out2_0 = getelementptr i8,ptr %out,i64 48
 store i64 %word2_0,ptr %out2_0,align 1
 %shift2_1 = lshr i140 %r2,64
 %word2_1 = trunc i140 %shift2_1 to i64
 %out2_1 = getelementptr i8,ptr %out,i64 56
 store i64 %word2_1,ptr %out2_1,align 1
 %shift2_2 = lshr i140 %r2,128
 %word2_2 = trunc i140 %shift2_2 to i64
 %out2_2 = getelementptr i8,ptr %out,i64 64
 store i64 %word2_2,ptr %out2_2,align 1
 %word3_0 = trunc i140 %r3 to i64
 %out3_0 = getelementptr i8,ptr %out,i64 72
 store i64 %word3_0,ptr %out3_0,align 1
 %shift3_1 = lshr i140 %r3,64
 %word3_1 = trunc i140 %shift3_1 to i64
 %out3_1 = getelementptr i8,ptr %out,i64 80
 store i64 %word3_1,ptr %out3_1,align 1
 %shift3_2 = lshr i140 %r3,128
 %word3_2 = trunc i140 %shift3_2 to i64
 %out3_2 = getelementptr i8,ptr %out,i64 88
 store i64 %word3_2,ptr %out3_2,align 1
 %word4_0 = trunc i200 %r4 to i64
 %out4_0 = getelementptr i8,ptr %out,i64 96
 store i64 %word4_0,ptr %out4_0,align 1
 %shift4_1 = lshr i200 %r4,64
 %word4_1 = trunc i200 %shift4_1 to i64
 %out4_1 = getelementptr i8,ptr %out,i64 104
 store i64 %word4_1,ptr %out4_1,align 1
 %shift4_2 = lshr i200 %r4,128
 %word4_2 = trunc i200 %shift4_2 to i64
 %out4_2 = getelementptr i8,ptr %out,i64 112
 store i64 %word4_2,ptr %out4_2,align 1
 %shift4_3 = lshr i200 %r4,192
 %word4_3 = trunc i200 %shift4_3 to i64
 %out4_3 = getelementptr i8,ptr %out,i64 120
 store i64 %word4_3,ptr %out4_3,align 1
 %word5_0 = trunc i200 %r5 to i64
 %out5_0 = getelementptr i8,ptr %out,i64 128
 store i64 %word5_0,ptr %out5_0,align 1
 %shift5_1 = lshr i200 %r5,64
 %word5_1 = trunc i200 %shift5_1 to i64
 %out5_1 = getelementptr i8,ptr %out,i64 136
 store i64 %word5_1,ptr %out5_1,align 1
 %shift5_2 = lshr i200 %r5,128
 %word5_2 = trunc i200 %shift5_2 to i64
 %out5_2 = getelementptr i8,ptr %out,i64 144
 store i64 %word5_2,ptr %out5_2,align 1
 %shift5_3 = lshr i200 %r5,192
 %word5_3 = trunc i200 %shift5_3 to i64
 %out5_3 = getelementptr i8,ptr %out,i64 152
 store i64 %word5_3,ptr %out5_3,align 1
 %mp = getelementptr i8,ptr %out,i64 160
 store i64 %mask,ptr %mp,align 1
 %op = getelementptr i8,ptr %out,i64 168
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %mask,%token
 ret i64 %answer
}
define i64 @wide_saturation_vector_probe_45(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %temporary = alloca [160 x i8],align 16
 %constant = alloca i140,align 16
 store i140 1267650600228229401496703205376,ptr %constant,align 16
 %bp = getelementptr i8,ptr %input,i64 32
 %sp = getelementptr i8,ptr %input,i64 64
 %s0 = load i64,ptr %sp,align 1
 %tp = getelementptr i8,ptr %input,i64 72
 %t0 = load i64,ptr %tp,align 1
 %temporary0 = getelementptr i8,ptr %temporary,i64 0
 call void @wide_sat_140_u_0(ptr %temporary0,ptr %input,i64 %s0)
 %temporary1 = getelementptr i8,ptr %temporary,i64 24
 call void @wide_sat_140_s_0(ptr %temporary1,ptr %input,i64 %s0)
 %temporary2 = getelementptr i8,ptr %temporary,i64 48
 call void @wide_sat_140_u_0(ptr %temporary2,ptr %constant,i64 %s0)
 %temporary3 = getelementptr i8,ptr %temporary,i64 72
 call void @wide_sat_140_s_0(ptr %temporary3,ptr %constant,i64 %s0)
 %temporary4 = getelementptr i8,ptr %temporary,i64 96
 call void @wide_sat_200_u_0(ptr %temporary4,ptr %bp,i64 %t0)
 %temporary5 = getelementptr i8,ptr %temporary,i64 128
 call void @wide_sat_200_s_0(ptr %temporary5,ptr %bp,i64 %t0)
 %r0 = load i140,ptr %temporary0,align 1
 %r1 = load i140,ptr %temporary1,align 1
 %r2 = load i140,ptr %temporary2,align 1
 %r3 = load i140,ptr %temporary3,align 1
 %r4 = load i200,ptr %temporary4,align 1
 %r5 = load i200,ptr %temporary5,align 1
 %v0 = insertelement <4 x i140> poison,i140 %r0,i64 0
 %v1 = insertelement <4 x i140> %v0,i140 %r1,i64 1
 %v2 = insertelement <4 x i140> %v1,i140 %r2,i64 2
 %v3 = insertelement <4 x i140> %v2,i140 %r3,i64 3
 %w0 = insertelement <4 x i140> poison,i140 0,i32 0
 %w1 = insertelement <4 x i140> %w0,i140 -1,i32 1
 %w2 = insertelement <4 x i140> %w1,i140 696898287454081973172991196020261297061887,i32 2
 %w3 = insertelement <4 x i140> %w2,i140 -696898287454081973172991196020261297061888,i32 3
 %cmp = icmp sge <4 x i140> %v3,%w3
 %packed_mask = bitcast <4 x i1> %cmp to i4
 %mask = zext i4 %packed_mask to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %word0_0 = trunc i140 %r0 to i64
 %out0_0 = getelementptr i8,ptr %out,i64 0
 store i64 %word0_0,ptr %out0_0,align 1
 %shift0_1 = lshr i140 %r0,64
 %word0_1 = trunc i140 %shift0_1 to i64
 %out0_1 = getelementptr i8,ptr %out,i64 8
 store i64 %word0_1,ptr %out0_1,align 1
 %shift0_2 = lshr i140 %r0,128
 %word0_2 = trunc i140 %shift0_2 to i64
 %out0_2 = getelementptr i8,ptr %out,i64 16
 store i64 %word0_2,ptr %out0_2,align 1
 %word1_0 = trunc i140 %r1 to i64
 %out1_0 = getelementptr i8,ptr %out,i64 24
 store i64 %word1_0,ptr %out1_0,align 1
 %shift1_1 = lshr i140 %r1,64
 %word1_1 = trunc i140 %shift1_1 to i64
 %out1_1 = getelementptr i8,ptr %out,i64 32
 store i64 %word1_1,ptr %out1_1,align 1
 %shift1_2 = lshr i140 %r1,128
 %word1_2 = trunc i140 %shift1_2 to i64
 %out1_2 = getelementptr i8,ptr %out,i64 40
 store i64 %word1_2,ptr %out1_2,align 1
 %word2_0 = trunc i140 %r2 to i64
 %out2_0 = getelementptr i8,ptr %out,i64 48
 store i64 %word2_0,ptr %out2_0,align 1
 %shift2_1 = lshr i140 %r2,64
 %word2_1 = trunc i140 %shift2_1 to i64
 %out2_1 = getelementptr i8,ptr %out,i64 56
 store i64 %word2_1,ptr %out2_1,align 1
 %shift2_2 = lshr i140 %r2,128
 %word2_2 = trunc i140 %shift2_2 to i64
 %out2_2 = getelementptr i8,ptr %out,i64 64
 store i64 %word2_2,ptr %out2_2,align 1
 %word3_0 = trunc i140 %r3 to i64
 %out3_0 = getelementptr i8,ptr %out,i64 72
 store i64 %word3_0,ptr %out3_0,align 1
 %shift3_1 = lshr i140 %r3,64
 %word3_1 = trunc i140 %shift3_1 to i64
 %out3_1 = getelementptr i8,ptr %out,i64 80
 store i64 %word3_1,ptr %out3_1,align 1
 %shift3_2 = lshr i140 %r3,128
 %word3_2 = trunc i140 %shift3_2 to i64
 %out3_2 = getelementptr i8,ptr %out,i64 88
 store i64 %word3_2,ptr %out3_2,align 1
 %word4_0 = trunc i200 %r4 to i64
 %out4_0 = getelementptr i8,ptr %out,i64 96
 store i64 %word4_0,ptr %out4_0,align 1
 %shift4_1 = lshr i200 %r4,64
 %word4_1 = trunc i200 %shift4_1 to i64
 %out4_1 = getelementptr i8,ptr %out,i64 104
 store i64 %word4_1,ptr %out4_1,align 1
 %shift4_2 = lshr i200 %r4,128
 %word4_2 = trunc i200 %shift4_2 to i64
 %out4_2 = getelementptr i8,ptr %out,i64 112
 store i64 %word4_2,ptr %out4_2,align 1
 %shift4_3 = lshr i200 %r4,192
 %word4_3 = trunc i200 %shift4_3 to i64
 %out4_3 = getelementptr i8,ptr %out,i64 120
 store i64 %word4_3,ptr %out4_3,align 1
 %word5_0 = trunc i200 %r5 to i64
 %out5_0 = getelementptr i8,ptr %out,i64 128
 store i64 %word5_0,ptr %out5_0,align 1
 %shift5_1 = lshr i200 %r5,64
 %word5_1 = trunc i200 %shift5_1 to i64
 %out5_1 = getelementptr i8,ptr %out,i64 136
 store i64 %word5_1,ptr %out5_1,align 1
 %shift5_2 = lshr i200 %r5,128
 %word5_2 = trunc i200 %shift5_2 to i64
 %out5_2 = getelementptr i8,ptr %out,i64 144
 store i64 %word5_2,ptr %out5_2,align 1
 %shift5_3 = lshr i200 %r5,192
 %word5_3 = trunc i200 %shift5_3 to i64
 %out5_3 = getelementptr i8,ptr %out,i64 152
 store i64 %word5_3,ptr %out5_3,align 1
 %mp = getelementptr i8,ptr %out,i64 160
 store i64 %mask,ptr %mp,align 1
 %op = getelementptr i8,ptr %out,i64 168
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %mask,%token
 ret i64 %answer
}
define i64 @wide_saturation_vector_probe_46(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %temporary = alloca [160 x i8],align 16
 %constant = alloca i140,align 16
 store i140 1267650600228229401496703205376,ptr %constant,align 16
 %bp = getelementptr i8,ptr %input,i64 32
 %sp = getelementptr i8,ptr %input,i64 64
 %s0 = load i64,ptr %sp,align 1
 %tp = getelementptr i8,ptr %input,i64 72
 %t0 = load i64,ptr %tp,align 1
 %temporary0 = getelementptr i8,ptr %temporary,i64 0
 call void @wide_sat_140_u_1(ptr %temporary0,ptr %input,i64 %s0)
 %temporary1 = getelementptr i8,ptr %temporary,i64 24
 call void @wide_sat_140_s_1(ptr %temporary1,ptr %input,i64 %s0)
 %temporary2 = getelementptr i8,ptr %temporary,i64 48
 call void @wide_sat_140_u_1(ptr %temporary2,ptr %constant,i64 %s0)
 %temporary3 = getelementptr i8,ptr %temporary,i64 72
 call void @wide_sat_140_s_1(ptr %temporary3,ptr %constant,i64 %s0)
 %temporary4 = getelementptr i8,ptr %temporary,i64 96
 call void @wide_sat_200_u_1(ptr %temporary4,ptr %bp,i64 %t0)
 %temporary5 = getelementptr i8,ptr %temporary,i64 128
 call void @wide_sat_200_s_1(ptr %temporary5,ptr %bp,i64 %t0)
 %r0 = load i140,ptr %temporary0,align 1
 %r1 = load i140,ptr %temporary1,align 1
 %r2 = load i140,ptr %temporary2,align 1
 %r3 = load i140,ptr %temporary3,align 1
 %r4 = load i200,ptr %temporary4,align 1
 %r5 = load i200,ptr %temporary5,align 1
 %v0 = insertelement <4 x i140> poison,i140 %r0,i64 0
 %v1 = insertelement <4 x i140> %v0,i140 %r1,i64 1
 %v2 = insertelement <4 x i140> %v1,i140 %r2,i64 2
 %v3 = insertelement <4 x i140> %v2,i140 %r3,i64 3
 %w0 = insertelement <4 x i140> poison,i140 0,i32 0
 %w1 = insertelement <4 x i140> %w0,i140 -1,i32 1
 %w2 = insertelement <4 x i140> %w1,i140 696898287454081973172991196020261297061887,i32 2
 %w3 = insertelement <4 x i140> %w2,i140 -696898287454081973172991196020261297061888,i32 3
 %cmp = icmp sge <4 x i140> %v3,%w3
 %packed_mask = bitcast <4 x i1> %cmp to i4
 %mask = zext i4 %packed_mask to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %word0_0 = trunc i140 %r0 to i64
 %out0_0 = getelementptr i8,ptr %out,i64 0
 store i64 %word0_0,ptr %out0_0,align 1
 %shift0_1 = lshr i140 %r0,64
 %word0_1 = trunc i140 %shift0_1 to i64
 %out0_1 = getelementptr i8,ptr %out,i64 8
 store i64 %word0_1,ptr %out0_1,align 1
 %shift0_2 = lshr i140 %r0,128
 %word0_2 = trunc i140 %shift0_2 to i64
 %out0_2 = getelementptr i8,ptr %out,i64 16
 store i64 %word0_2,ptr %out0_2,align 1
 %word1_0 = trunc i140 %r1 to i64
 %out1_0 = getelementptr i8,ptr %out,i64 24
 store i64 %word1_0,ptr %out1_0,align 1
 %shift1_1 = lshr i140 %r1,64
 %word1_1 = trunc i140 %shift1_1 to i64
 %out1_1 = getelementptr i8,ptr %out,i64 32
 store i64 %word1_1,ptr %out1_1,align 1
 %shift1_2 = lshr i140 %r1,128
 %word1_2 = trunc i140 %shift1_2 to i64
 %out1_2 = getelementptr i8,ptr %out,i64 40
 store i64 %word1_2,ptr %out1_2,align 1
 %word2_0 = trunc i140 %r2 to i64
 %out2_0 = getelementptr i8,ptr %out,i64 48
 store i64 %word2_0,ptr %out2_0,align 1
 %shift2_1 = lshr i140 %r2,64
 %word2_1 = trunc i140 %shift2_1 to i64
 %out2_1 = getelementptr i8,ptr %out,i64 56
 store i64 %word2_1,ptr %out2_1,align 1
 %shift2_2 = lshr i140 %r2,128
 %word2_2 = trunc i140 %shift2_2 to i64
 %out2_2 = getelementptr i8,ptr %out,i64 64
 store i64 %word2_2,ptr %out2_2,align 1
 %word3_0 = trunc i140 %r3 to i64
 %out3_0 = getelementptr i8,ptr %out,i64 72
 store i64 %word3_0,ptr %out3_0,align 1
 %shift3_1 = lshr i140 %r3,64
 %word3_1 = trunc i140 %shift3_1 to i64
 %out3_1 = getelementptr i8,ptr %out,i64 80
 store i64 %word3_1,ptr %out3_1,align 1
 %shift3_2 = lshr i140 %r3,128
 %word3_2 = trunc i140 %shift3_2 to i64
 %out3_2 = getelementptr i8,ptr %out,i64 88
 store i64 %word3_2,ptr %out3_2,align 1
 %word4_0 = trunc i200 %r4 to i64
 %out4_0 = getelementptr i8,ptr %out,i64 96
 store i64 %word4_0,ptr %out4_0,align 1
 %shift4_1 = lshr i200 %r4,64
 %word4_1 = trunc i200 %shift4_1 to i64
 %out4_1 = getelementptr i8,ptr %out,i64 104
 store i64 %word4_1,ptr %out4_1,align 1
 %shift4_2 = lshr i200 %r4,128
 %word4_2 = trunc i200 %shift4_2 to i64
 %out4_2 = getelementptr i8,ptr %out,i64 112
 store i64 %word4_2,ptr %out4_2,align 1
 %shift4_3 = lshr i200 %r4,192
 %word4_3 = trunc i200 %shift4_3 to i64
 %out4_3 = getelementptr i8,ptr %out,i64 120
 store i64 %word4_3,ptr %out4_3,align 1
 %word5_0 = trunc i200 %r5 to i64
 %out5_0 = getelementptr i8,ptr %out,i64 128
 store i64 %word5_0,ptr %out5_0,align 1
 %shift5_1 = lshr i200 %r5,64
 %word5_1 = trunc i200 %shift5_1 to i64
 %out5_1 = getelementptr i8,ptr %out,i64 136
 store i64 %word5_1,ptr %out5_1,align 1
 %shift5_2 = lshr i200 %r5,128
 %word5_2 = trunc i200 %shift5_2 to i64
 %out5_2 = getelementptr i8,ptr %out,i64 144
 store i64 %word5_2,ptr %out5_2,align 1
 %shift5_3 = lshr i200 %r5,192
 %word5_3 = trunc i200 %shift5_3 to i64
 %out5_3 = getelementptr i8,ptr %out,i64 152
 store i64 %word5_3,ptr %out5_3,align 1
 %mp = getelementptr i8,ptr %out,i64 160
 store i64 %mask,ptr %mp,align 1
 %op = getelementptr i8,ptr %out,i64 168
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %mask,%token
 ret i64 %answer
}
define i64 @wide_saturation_vector_probe_47(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %temporary = alloca [160 x i8],align 16
 %constant = alloca i140,align 16
 store i140 1267650600228229401496703205376,ptr %constant,align 16
 %bp = getelementptr i8,ptr %input,i64 32
 %sp = getelementptr i8,ptr %input,i64 64
 %s0 = load i64,ptr %sp,align 1
 %tp = getelementptr i8,ptr %input,i64 72
 %t0 = load i64,ptr %tp,align 1
 %temporary0 = getelementptr i8,ptr %temporary,i64 0
 call void @wide_sat_140_u_2(ptr %temporary0,ptr %input,i64 %s0)
 %temporary1 = getelementptr i8,ptr %temporary,i64 24
 call void @wide_sat_140_s_2(ptr %temporary1,ptr %input,i64 %s0)
 %temporary2 = getelementptr i8,ptr %temporary,i64 48
 call void @wide_sat_140_u_2(ptr %temporary2,ptr %constant,i64 %s0)
 %temporary3 = getelementptr i8,ptr %temporary,i64 72
 call void @wide_sat_140_s_2(ptr %temporary3,ptr %constant,i64 %s0)
 %temporary4 = getelementptr i8,ptr %temporary,i64 96
 call void @wide_sat_200_u_2(ptr %temporary4,ptr %bp,i64 %t0)
 %temporary5 = getelementptr i8,ptr %temporary,i64 128
 call void @wide_sat_200_s_2(ptr %temporary5,ptr %bp,i64 %t0)
 %r0 = load i140,ptr %temporary0,align 1
 %r1 = load i140,ptr %temporary1,align 1
 %r2 = load i140,ptr %temporary2,align 1
 %r3 = load i140,ptr %temporary3,align 1
 %r4 = load i200,ptr %temporary4,align 1
 %r5 = load i200,ptr %temporary5,align 1
 %v0 = insertelement <4 x i140> poison,i140 %r0,i64 0
 %v1 = insertelement <4 x i140> %v0,i140 %r1,i64 1
 %v2 = insertelement <4 x i140> %v1,i140 %r2,i64 2
 %v3 = insertelement <4 x i140> %v2,i140 %r3,i64 3
 %w0 = insertelement <4 x i140> poison,i140 0,i32 0
 %w1 = insertelement <4 x i140> %w0,i140 -1,i32 1
 %w2 = insertelement <4 x i140> %w1,i140 696898287454081973172991196020261297061887,i32 2
 %w3 = insertelement <4 x i140> %w2,i140 -696898287454081973172991196020261297061888,i32 3
 %cmp = icmp sge <4 x i140> %v3,%w3
 %packed_mask = bitcast <4 x i1> %cmp to i4
 %mask = zext i4 %packed_mask to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %word0_0 = trunc i140 %r0 to i64
 %out0_0 = getelementptr i8,ptr %out,i64 0
 store i64 %word0_0,ptr %out0_0,align 1
 %shift0_1 = lshr i140 %r0,64
 %word0_1 = trunc i140 %shift0_1 to i64
 %out0_1 = getelementptr i8,ptr %out,i64 8
 store i64 %word0_1,ptr %out0_1,align 1
 %shift0_2 = lshr i140 %r0,128
 %word0_2 = trunc i140 %shift0_2 to i64
 %out0_2 = getelementptr i8,ptr %out,i64 16
 store i64 %word0_2,ptr %out0_2,align 1
 %word1_0 = trunc i140 %r1 to i64
 %out1_0 = getelementptr i8,ptr %out,i64 24
 store i64 %word1_0,ptr %out1_0,align 1
 %shift1_1 = lshr i140 %r1,64
 %word1_1 = trunc i140 %shift1_1 to i64
 %out1_1 = getelementptr i8,ptr %out,i64 32
 store i64 %word1_1,ptr %out1_1,align 1
 %shift1_2 = lshr i140 %r1,128
 %word1_2 = trunc i140 %shift1_2 to i64
 %out1_2 = getelementptr i8,ptr %out,i64 40
 store i64 %word1_2,ptr %out1_2,align 1
 %word2_0 = trunc i140 %r2 to i64
 %out2_0 = getelementptr i8,ptr %out,i64 48
 store i64 %word2_0,ptr %out2_0,align 1
 %shift2_1 = lshr i140 %r2,64
 %word2_1 = trunc i140 %shift2_1 to i64
 %out2_1 = getelementptr i8,ptr %out,i64 56
 store i64 %word2_1,ptr %out2_1,align 1
 %shift2_2 = lshr i140 %r2,128
 %word2_2 = trunc i140 %shift2_2 to i64
 %out2_2 = getelementptr i8,ptr %out,i64 64
 store i64 %word2_2,ptr %out2_2,align 1
 %word3_0 = trunc i140 %r3 to i64
 %out3_0 = getelementptr i8,ptr %out,i64 72
 store i64 %word3_0,ptr %out3_0,align 1
 %shift3_1 = lshr i140 %r3,64
 %word3_1 = trunc i140 %shift3_1 to i64
 %out3_1 = getelementptr i8,ptr %out,i64 80
 store i64 %word3_1,ptr %out3_1,align 1
 %shift3_2 = lshr i140 %r3,128
 %word3_2 = trunc i140 %shift3_2 to i64
 %out3_2 = getelementptr i8,ptr %out,i64 88
 store i64 %word3_2,ptr %out3_2,align 1
 %word4_0 = trunc i200 %r4 to i64
 %out4_0 = getelementptr i8,ptr %out,i64 96
 store i64 %word4_0,ptr %out4_0,align 1
 %shift4_1 = lshr i200 %r4,64
 %word4_1 = trunc i200 %shift4_1 to i64
 %out4_1 = getelementptr i8,ptr %out,i64 104
 store i64 %word4_1,ptr %out4_1,align 1
 %shift4_2 = lshr i200 %r4,128
 %word4_2 = trunc i200 %shift4_2 to i64
 %out4_2 = getelementptr i8,ptr %out,i64 112
 store i64 %word4_2,ptr %out4_2,align 1
 %shift4_3 = lshr i200 %r4,192
 %word4_3 = trunc i200 %shift4_3 to i64
 %out4_3 = getelementptr i8,ptr %out,i64 120
 store i64 %word4_3,ptr %out4_3,align 1
 %word5_0 = trunc i200 %r5 to i64
 %out5_0 = getelementptr i8,ptr %out,i64 128
 store i64 %word5_0,ptr %out5_0,align 1
 %shift5_1 = lshr i200 %r5,64
 %word5_1 = trunc i200 %shift5_1 to i64
 %out5_1 = getelementptr i8,ptr %out,i64 136
 store i64 %word5_1,ptr %out5_1,align 1
 %shift5_2 = lshr i200 %r5,128
 %word5_2 = trunc i200 %shift5_2 to i64
 %out5_2 = getelementptr i8,ptr %out,i64 144
 store i64 %word5_2,ptr %out5_2,align 1
 %shift5_3 = lshr i200 %r5,192
 %word5_3 = trunc i200 %shift5_3 to i64
 %out5_3 = getelementptr i8,ptr %out,i64 152
 store i64 %word5_3,ptr %out5_3,align 1
 %mp = getelementptr i8,ptr %out,i64 160
 store i64 %mask,ptr %mp,align 1
 %op = getelementptr i8,ptr %out,i64 168
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %mask,%token
 ret i64 %answer
}
define i64 @wide_saturation_vector_probe_48(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %temporary = alloca [160 x i8],align 16
 %constant = alloca i140,align 16
 store i140 1267650600228229401496703205376,ptr %constant,align 16
 %bp = getelementptr i8,ptr %input,i64 32
 %sp = getelementptr i8,ptr %input,i64 64
 %s0 = load i64,ptr %sp,align 1
 %tp = getelementptr i8,ptr %input,i64 72
 %t0 = load i64,ptr %tp,align 1
 %temporary0 = getelementptr i8,ptr %temporary,i64 0
 call void @wide_sat_140_u_0(ptr %temporary0,ptr %input,i64 %s0)
 %temporary1 = getelementptr i8,ptr %temporary,i64 24
 call void @wide_sat_140_s_0(ptr %temporary1,ptr %input,i64 %s0)
 %temporary2 = getelementptr i8,ptr %temporary,i64 48
 call void @wide_sat_140_u_0(ptr %temporary2,ptr %constant,i64 %s0)
 %temporary3 = getelementptr i8,ptr %temporary,i64 72
 call void @wide_sat_140_s_0(ptr %temporary3,ptr %constant,i64 %s0)
 %temporary4 = getelementptr i8,ptr %temporary,i64 96
 call void @wide_sat_200_u_0(ptr %temporary4,ptr %bp,i64 %t0)
 %temporary5 = getelementptr i8,ptr %temporary,i64 128
 call void @wide_sat_200_s_0(ptr %temporary5,ptr %bp,i64 %t0)
 %r0 = load i140,ptr %temporary0,align 1
 %r1 = load i140,ptr %temporary1,align 1
 %r2 = load i140,ptr %temporary2,align 1
 %r3 = load i140,ptr %temporary3,align 1
 %r4 = load i200,ptr %temporary4,align 1
 %r5 = load i200,ptr %temporary5,align 1
 %v0 = insertelement <4 x i140> poison,i140 %r0,i64 0
 %v1 = insertelement <4 x i140> %v0,i140 %r1,i64 1
 %v2 = insertelement <4 x i140> %v1,i140 %r2,i64 2
 %v3 = insertelement <4 x i140> %v2,i140 %r3,i64 3
 %cmp = icmp slt <4 x i140> %v3,<i140 0,i140 -1,i140 696898287454081973172991196020261297061887,i140 -696898287454081973172991196020261297061888>
 %packed_mask = bitcast <4 x i1> %cmp to i4
 %mask = zext i4 %packed_mask to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %word0_0 = trunc i140 %r0 to i64
 %out0_0 = getelementptr i8,ptr %out,i64 0
 store i64 %word0_0,ptr %out0_0,align 1
 %shift0_1 = lshr i140 %r0,64
 %word0_1 = trunc i140 %shift0_1 to i64
 %out0_1 = getelementptr i8,ptr %out,i64 8
 store i64 %word0_1,ptr %out0_1,align 1
 %shift0_2 = lshr i140 %r0,128
 %word0_2 = trunc i140 %shift0_2 to i64
 %out0_2 = getelementptr i8,ptr %out,i64 16
 store i64 %word0_2,ptr %out0_2,align 1
 %word1_0 = trunc i140 %r1 to i64
 %out1_0 = getelementptr i8,ptr %out,i64 24
 store i64 %word1_0,ptr %out1_0,align 1
 %shift1_1 = lshr i140 %r1,64
 %word1_1 = trunc i140 %shift1_1 to i64
 %out1_1 = getelementptr i8,ptr %out,i64 32
 store i64 %word1_1,ptr %out1_1,align 1
 %shift1_2 = lshr i140 %r1,128
 %word1_2 = trunc i140 %shift1_2 to i64
 %out1_2 = getelementptr i8,ptr %out,i64 40
 store i64 %word1_2,ptr %out1_2,align 1
 %word2_0 = trunc i140 %r2 to i64
 %out2_0 = getelementptr i8,ptr %out,i64 48
 store i64 %word2_0,ptr %out2_0,align 1
 %shift2_1 = lshr i140 %r2,64
 %word2_1 = trunc i140 %shift2_1 to i64
 %out2_1 = getelementptr i8,ptr %out,i64 56
 store i64 %word2_1,ptr %out2_1,align 1
 %shift2_2 = lshr i140 %r2,128
 %word2_2 = trunc i140 %shift2_2 to i64
 %out2_2 = getelementptr i8,ptr %out,i64 64
 store i64 %word2_2,ptr %out2_2,align 1
 %word3_0 = trunc i140 %r3 to i64
 %out3_0 = getelementptr i8,ptr %out,i64 72
 store i64 %word3_0,ptr %out3_0,align 1
 %shift3_1 = lshr i140 %r3,64
 %word3_1 = trunc i140 %shift3_1 to i64
 %out3_1 = getelementptr i8,ptr %out,i64 80
 store i64 %word3_1,ptr %out3_1,align 1
 %shift3_2 = lshr i140 %r3,128
 %word3_2 = trunc i140 %shift3_2 to i64
 %out3_2 = getelementptr i8,ptr %out,i64 88
 store i64 %word3_2,ptr %out3_2,align 1
 %word4_0 = trunc i200 %r4 to i64
 %out4_0 = getelementptr i8,ptr %out,i64 96
 store i64 %word4_0,ptr %out4_0,align 1
 %shift4_1 = lshr i200 %r4,64
 %word4_1 = trunc i200 %shift4_1 to i64
 %out4_1 = getelementptr i8,ptr %out,i64 104
 store i64 %word4_1,ptr %out4_1,align 1
 %shift4_2 = lshr i200 %r4,128
 %word4_2 = trunc i200 %shift4_2 to i64
 %out4_2 = getelementptr i8,ptr %out,i64 112
 store i64 %word4_2,ptr %out4_2,align 1
 %shift4_3 = lshr i200 %r4,192
 %word4_3 = trunc i200 %shift4_3 to i64
 %out4_3 = getelementptr i8,ptr %out,i64 120
 store i64 %word4_3,ptr %out4_3,align 1
 %word5_0 = trunc i200 %r5 to i64
 %out5_0 = getelementptr i8,ptr %out,i64 128
 store i64 %word5_0,ptr %out5_0,align 1
 %shift5_1 = lshr i200 %r5,64
 %word5_1 = trunc i200 %shift5_1 to i64
 %out5_1 = getelementptr i8,ptr %out,i64 136
 store i64 %word5_1,ptr %out5_1,align 1
 %shift5_2 = lshr i200 %r5,128
 %word5_2 = trunc i200 %shift5_2 to i64
 %out5_2 = getelementptr i8,ptr %out,i64 144
 store i64 %word5_2,ptr %out5_2,align 1
 %shift5_3 = lshr i200 %r5,192
 %word5_3 = trunc i200 %shift5_3 to i64
 %out5_3 = getelementptr i8,ptr %out,i64 152
 store i64 %word5_3,ptr %out5_3,align 1
 %mp = getelementptr i8,ptr %out,i64 160
 store i64 %mask,ptr %mp,align 1
 %op = getelementptr i8,ptr %out,i64 168
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %mask,%token
 ret i64 %answer
}
define i64 @wide_saturation_vector_probe_49(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %temporary = alloca [160 x i8],align 16
 %constant = alloca i140,align 16
 store i140 1267650600228229401496703205376,ptr %constant,align 16
 %bp = getelementptr i8,ptr %input,i64 32
 %sp = getelementptr i8,ptr %input,i64 64
 %s0 = load i64,ptr %sp,align 1
 %tp = getelementptr i8,ptr %input,i64 72
 %t0 = load i64,ptr %tp,align 1
 %temporary0 = getelementptr i8,ptr %temporary,i64 0
 call void @wide_sat_140_u_1(ptr %temporary0,ptr %input,i64 %s0)
 %temporary1 = getelementptr i8,ptr %temporary,i64 24
 call void @wide_sat_140_s_1(ptr %temporary1,ptr %input,i64 %s0)
 %temporary2 = getelementptr i8,ptr %temporary,i64 48
 call void @wide_sat_140_u_1(ptr %temporary2,ptr %constant,i64 %s0)
 %temporary3 = getelementptr i8,ptr %temporary,i64 72
 call void @wide_sat_140_s_1(ptr %temporary3,ptr %constant,i64 %s0)
 %temporary4 = getelementptr i8,ptr %temporary,i64 96
 call void @wide_sat_200_u_1(ptr %temporary4,ptr %bp,i64 %t0)
 %temporary5 = getelementptr i8,ptr %temporary,i64 128
 call void @wide_sat_200_s_1(ptr %temporary5,ptr %bp,i64 %t0)
 %r0 = load i140,ptr %temporary0,align 1
 %r1 = load i140,ptr %temporary1,align 1
 %r2 = load i140,ptr %temporary2,align 1
 %r3 = load i140,ptr %temporary3,align 1
 %r4 = load i200,ptr %temporary4,align 1
 %r5 = load i200,ptr %temporary5,align 1
 %v0 = insertelement <4 x i140> poison,i140 %r0,i64 0
 %v1 = insertelement <4 x i140> %v0,i140 %r1,i64 1
 %v2 = insertelement <4 x i140> %v1,i140 %r2,i64 2
 %v3 = insertelement <4 x i140> %v2,i140 %r3,i64 3
 %cmp = icmp slt <4 x i140> %v3,<i140 0,i140 -1,i140 696898287454081973172991196020261297061887,i140 -696898287454081973172991196020261297061888>
 %packed_mask = bitcast <4 x i1> %cmp to i4
 %mask = zext i4 %packed_mask to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %word0_0 = trunc i140 %r0 to i64
 %out0_0 = getelementptr i8,ptr %out,i64 0
 store i64 %word0_0,ptr %out0_0,align 1
 %shift0_1 = lshr i140 %r0,64
 %word0_1 = trunc i140 %shift0_1 to i64
 %out0_1 = getelementptr i8,ptr %out,i64 8
 store i64 %word0_1,ptr %out0_1,align 1
 %shift0_2 = lshr i140 %r0,128
 %word0_2 = trunc i140 %shift0_2 to i64
 %out0_2 = getelementptr i8,ptr %out,i64 16
 store i64 %word0_2,ptr %out0_2,align 1
 %word1_0 = trunc i140 %r1 to i64
 %out1_0 = getelementptr i8,ptr %out,i64 24
 store i64 %word1_0,ptr %out1_0,align 1
 %shift1_1 = lshr i140 %r1,64
 %word1_1 = trunc i140 %shift1_1 to i64
 %out1_1 = getelementptr i8,ptr %out,i64 32
 store i64 %word1_1,ptr %out1_1,align 1
 %shift1_2 = lshr i140 %r1,128
 %word1_2 = trunc i140 %shift1_2 to i64
 %out1_2 = getelementptr i8,ptr %out,i64 40
 store i64 %word1_2,ptr %out1_2,align 1
 %word2_0 = trunc i140 %r2 to i64
 %out2_0 = getelementptr i8,ptr %out,i64 48
 store i64 %word2_0,ptr %out2_0,align 1
 %shift2_1 = lshr i140 %r2,64
 %word2_1 = trunc i140 %shift2_1 to i64
 %out2_1 = getelementptr i8,ptr %out,i64 56
 store i64 %word2_1,ptr %out2_1,align 1
 %shift2_2 = lshr i140 %r2,128
 %word2_2 = trunc i140 %shift2_2 to i64
 %out2_2 = getelementptr i8,ptr %out,i64 64
 store i64 %word2_2,ptr %out2_2,align 1
 %word3_0 = trunc i140 %r3 to i64
 %out3_0 = getelementptr i8,ptr %out,i64 72
 store i64 %word3_0,ptr %out3_0,align 1
 %shift3_1 = lshr i140 %r3,64
 %word3_1 = trunc i140 %shift3_1 to i64
 %out3_1 = getelementptr i8,ptr %out,i64 80
 store i64 %word3_1,ptr %out3_1,align 1
 %shift3_2 = lshr i140 %r3,128
 %word3_2 = trunc i140 %shift3_2 to i64
 %out3_2 = getelementptr i8,ptr %out,i64 88
 store i64 %word3_2,ptr %out3_2,align 1
 %word4_0 = trunc i200 %r4 to i64
 %out4_0 = getelementptr i8,ptr %out,i64 96
 store i64 %word4_0,ptr %out4_0,align 1
 %shift4_1 = lshr i200 %r4,64
 %word4_1 = trunc i200 %shift4_1 to i64
 %out4_1 = getelementptr i8,ptr %out,i64 104
 store i64 %word4_1,ptr %out4_1,align 1
 %shift4_2 = lshr i200 %r4,128
 %word4_2 = trunc i200 %shift4_2 to i64
 %out4_2 = getelementptr i8,ptr %out,i64 112
 store i64 %word4_2,ptr %out4_2,align 1
 %shift4_3 = lshr i200 %r4,192
 %word4_3 = trunc i200 %shift4_3 to i64
 %out4_3 = getelementptr i8,ptr %out,i64 120
 store i64 %word4_3,ptr %out4_3,align 1
 %word5_0 = trunc i200 %r5 to i64
 %out5_0 = getelementptr i8,ptr %out,i64 128
 store i64 %word5_0,ptr %out5_0,align 1
 %shift5_1 = lshr i200 %r5,64
 %word5_1 = trunc i200 %shift5_1 to i64
 %out5_1 = getelementptr i8,ptr %out,i64 136
 store i64 %word5_1,ptr %out5_1,align 1
 %shift5_2 = lshr i200 %r5,128
 %word5_2 = trunc i200 %shift5_2 to i64
 %out5_2 = getelementptr i8,ptr %out,i64 144
 store i64 %word5_2,ptr %out5_2,align 1
 %shift5_3 = lshr i200 %r5,192
 %word5_3 = trunc i200 %shift5_3 to i64
 %out5_3 = getelementptr i8,ptr %out,i64 152
 store i64 %word5_3,ptr %out5_3,align 1
 %mp = getelementptr i8,ptr %out,i64 160
 store i64 %mask,ptr %mp,align 1
 %op = getelementptr i8,ptr %out,i64 168
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %mask,%token
 ret i64 %answer
}
define i64 @wide_saturation_vector_probe_50(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %temporary = alloca [160 x i8],align 16
 %constant = alloca i140,align 16
 store i140 1267650600228229401496703205376,ptr %constant,align 16
 %bp = getelementptr i8,ptr %input,i64 32
 %sp = getelementptr i8,ptr %input,i64 64
 %s0 = load i64,ptr %sp,align 1
 %tp = getelementptr i8,ptr %input,i64 72
 %t0 = load i64,ptr %tp,align 1
 %temporary0 = getelementptr i8,ptr %temporary,i64 0
 call void @wide_sat_140_u_2(ptr %temporary0,ptr %input,i64 %s0)
 %temporary1 = getelementptr i8,ptr %temporary,i64 24
 call void @wide_sat_140_s_2(ptr %temporary1,ptr %input,i64 %s0)
 %temporary2 = getelementptr i8,ptr %temporary,i64 48
 call void @wide_sat_140_u_2(ptr %temporary2,ptr %constant,i64 %s0)
 %temporary3 = getelementptr i8,ptr %temporary,i64 72
 call void @wide_sat_140_s_2(ptr %temporary3,ptr %constant,i64 %s0)
 %temporary4 = getelementptr i8,ptr %temporary,i64 96
 call void @wide_sat_200_u_2(ptr %temporary4,ptr %bp,i64 %t0)
 %temporary5 = getelementptr i8,ptr %temporary,i64 128
 call void @wide_sat_200_s_2(ptr %temporary5,ptr %bp,i64 %t0)
 %r0 = load i140,ptr %temporary0,align 1
 %r1 = load i140,ptr %temporary1,align 1
 %r2 = load i140,ptr %temporary2,align 1
 %r3 = load i140,ptr %temporary3,align 1
 %r4 = load i200,ptr %temporary4,align 1
 %r5 = load i200,ptr %temporary5,align 1
 %v0 = insertelement <4 x i140> poison,i140 %r0,i64 0
 %v1 = insertelement <4 x i140> %v0,i140 %r1,i64 1
 %v2 = insertelement <4 x i140> %v1,i140 %r2,i64 2
 %v3 = insertelement <4 x i140> %v2,i140 %r3,i64 3
 %cmp = icmp slt <4 x i140> %v3,<i140 0,i140 -1,i140 696898287454081973172991196020261297061887,i140 -696898287454081973172991196020261297061888>
 %packed_mask = bitcast <4 x i1> %cmp to i4
 %mask = zext i4 %packed_mask to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %word0_0 = trunc i140 %r0 to i64
 %out0_0 = getelementptr i8,ptr %out,i64 0
 store i64 %word0_0,ptr %out0_0,align 1
 %shift0_1 = lshr i140 %r0,64
 %word0_1 = trunc i140 %shift0_1 to i64
 %out0_1 = getelementptr i8,ptr %out,i64 8
 store i64 %word0_1,ptr %out0_1,align 1
 %shift0_2 = lshr i140 %r0,128
 %word0_2 = trunc i140 %shift0_2 to i64
 %out0_2 = getelementptr i8,ptr %out,i64 16
 store i64 %word0_2,ptr %out0_2,align 1
 %word1_0 = trunc i140 %r1 to i64
 %out1_0 = getelementptr i8,ptr %out,i64 24
 store i64 %word1_0,ptr %out1_0,align 1
 %shift1_1 = lshr i140 %r1,64
 %word1_1 = trunc i140 %shift1_1 to i64
 %out1_1 = getelementptr i8,ptr %out,i64 32
 store i64 %word1_1,ptr %out1_1,align 1
 %shift1_2 = lshr i140 %r1,128
 %word1_2 = trunc i140 %shift1_2 to i64
 %out1_2 = getelementptr i8,ptr %out,i64 40
 store i64 %word1_2,ptr %out1_2,align 1
 %word2_0 = trunc i140 %r2 to i64
 %out2_0 = getelementptr i8,ptr %out,i64 48
 store i64 %word2_0,ptr %out2_0,align 1
 %shift2_1 = lshr i140 %r2,64
 %word2_1 = trunc i140 %shift2_1 to i64
 %out2_1 = getelementptr i8,ptr %out,i64 56
 store i64 %word2_1,ptr %out2_1,align 1
 %shift2_2 = lshr i140 %r2,128
 %word2_2 = trunc i140 %shift2_2 to i64
 %out2_2 = getelementptr i8,ptr %out,i64 64
 store i64 %word2_2,ptr %out2_2,align 1
 %word3_0 = trunc i140 %r3 to i64
 %out3_0 = getelementptr i8,ptr %out,i64 72
 store i64 %word3_0,ptr %out3_0,align 1
 %shift3_1 = lshr i140 %r3,64
 %word3_1 = trunc i140 %shift3_1 to i64
 %out3_1 = getelementptr i8,ptr %out,i64 80
 store i64 %word3_1,ptr %out3_1,align 1
 %shift3_2 = lshr i140 %r3,128
 %word3_2 = trunc i140 %shift3_2 to i64
 %out3_2 = getelementptr i8,ptr %out,i64 88
 store i64 %word3_2,ptr %out3_2,align 1
 %word4_0 = trunc i200 %r4 to i64
 %out4_0 = getelementptr i8,ptr %out,i64 96
 store i64 %word4_0,ptr %out4_0,align 1
 %shift4_1 = lshr i200 %r4,64
 %word4_1 = trunc i200 %shift4_1 to i64
 %out4_1 = getelementptr i8,ptr %out,i64 104
 store i64 %word4_1,ptr %out4_1,align 1
 %shift4_2 = lshr i200 %r4,128
 %word4_2 = trunc i200 %shift4_2 to i64
 %out4_2 = getelementptr i8,ptr %out,i64 112
 store i64 %word4_2,ptr %out4_2,align 1
 %shift4_3 = lshr i200 %r4,192
 %word4_3 = trunc i200 %shift4_3 to i64
 %out4_3 = getelementptr i8,ptr %out,i64 120
 store i64 %word4_3,ptr %out4_3,align 1
 %word5_0 = trunc i200 %r5 to i64
 %out5_0 = getelementptr i8,ptr %out,i64 128
 store i64 %word5_0,ptr %out5_0,align 1
 %shift5_1 = lshr i200 %r5,64
 %word5_1 = trunc i200 %shift5_1 to i64
 %out5_1 = getelementptr i8,ptr %out,i64 136
 store i64 %word5_1,ptr %out5_1,align 1
 %shift5_2 = lshr i200 %r5,128
 %word5_2 = trunc i200 %shift5_2 to i64
 %out5_2 = getelementptr i8,ptr %out,i64 144
 store i64 %word5_2,ptr %out5_2,align 1
 %shift5_3 = lshr i200 %r5,192
 %word5_3 = trunc i200 %shift5_3 to i64
 %out5_3 = getelementptr i8,ptr %out,i64 152
 store i64 %word5_3,ptr %out5_3,align 1
 %mp = getelementptr i8,ptr %out,i64 160
 store i64 %mask,ptr %mp,align 1
 %op = getelementptr i8,ptr %out,i64 168
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %mask,%token
 ret i64 %answer
}
define i64 @wide_saturation_vector_probe_51(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %temporary = alloca [160 x i8],align 16
 %constant = alloca i140,align 16
 store i140 1267650600228229401496703205376,ptr %constant,align 16
 %bp = getelementptr i8,ptr %input,i64 32
 %sp = getelementptr i8,ptr %input,i64 64
 %s0 = load i64,ptr %sp,align 1
 %tp = getelementptr i8,ptr %input,i64 72
 %t0 = load i64,ptr %tp,align 1
 %temporary0 = getelementptr i8,ptr %temporary,i64 0
 call void @wide_sat_140_u_0(ptr %temporary0,ptr %input,i64 %s0)
 %temporary1 = getelementptr i8,ptr %temporary,i64 24
 call void @wide_sat_140_s_0(ptr %temporary1,ptr %input,i64 %s0)
 %temporary2 = getelementptr i8,ptr %temporary,i64 48
 call void @wide_sat_140_u_0(ptr %temporary2,ptr %constant,i64 %s0)
 %temporary3 = getelementptr i8,ptr %temporary,i64 72
 call void @wide_sat_140_s_0(ptr %temporary3,ptr %constant,i64 %s0)
 %temporary4 = getelementptr i8,ptr %temporary,i64 96
 call void @wide_sat_200_u_0(ptr %temporary4,ptr %bp,i64 %t0)
 %temporary5 = getelementptr i8,ptr %temporary,i64 128
 call void @wide_sat_200_s_0(ptr %temporary5,ptr %bp,i64 %t0)
 %r0 = load i140,ptr %temporary0,align 1
 %r1 = load i140,ptr %temporary1,align 1
 %r2 = load i140,ptr %temporary2,align 1
 %r3 = load i140,ptr %temporary3,align 1
 %r4 = load i200,ptr %temporary4,align 1
 %r5 = load i200,ptr %temporary5,align 1
 %v0 = insertelement <4 x i140> poison,i140 %r0,i64 0
 %v1 = insertelement <4 x i140> %v0,i140 %r1,i64 1
 %v2 = insertelement <4 x i140> %v1,i140 %r2,i64 2
 %v3 = insertelement <4 x i140> %v2,i140 %r3,i64 3
 %w0 = insertelement <4 x i140> poison,i140 0,i32 0
 %w1 = insertelement <4 x i140> %w0,i140 -1,i32 1
 %w2 = insertelement <4 x i140> %w1,i140 696898287454081973172991196020261297061887,i32 2
 %w3 = insertelement <4 x i140> %w2,i140 -696898287454081973172991196020261297061888,i32 3
 %cmp = icmp slt <4 x i140> %v3,%w3
 %packed_mask = bitcast <4 x i1> %cmp to i4
 %mask = zext i4 %packed_mask to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %word0_0 = trunc i140 %r0 to i64
 %out0_0 = getelementptr i8,ptr %out,i64 0
 store i64 %word0_0,ptr %out0_0,align 1
 %shift0_1 = lshr i140 %r0,64
 %word0_1 = trunc i140 %shift0_1 to i64
 %out0_1 = getelementptr i8,ptr %out,i64 8
 store i64 %word0_1,ptr %out0_1,align 1
 %shift0_2 = lshr i140 %r0,128
 %word0_2 = trunc i140 %shift0_2 to i64
 %out0_2 = getelementptr i8,ptr %out,i64 16
 store i64 %word0_2,ptr %out0_2,align 1
 %word1_0 = trunc i140 %r1 to i64
 %out1_0 = getelementptr i8,ptr %out,i64 24
 store i64 %word1_0,ptr %out1_0,align 1
 %shift1_1 = lshr i140 %r1,64
 %word1_1 = trunc i140 %shift1_1 to i64
 %out1_1 = getelementptr i8,ptr %out,i64 32
 store i64 %word1_1,ptr %out1_1,align 1
 %shift1_2 = lshr i140 %r1,128
 %word1_2 = trunc i140 %shift1_2 to i64
 %out1_2 = getelementptr i8,ptr %out,i64 40
 store i64 %word1_2,ptr %out1_2,align 1
 %word2_0 = trunc i140 %r2 to i64
 %out2_0 = getelementptr i8,ptr %out,i64 48
 store i64 %word2_0,ptr %out2_0,align 1
 %shift2_1 = lshr i140 %r2,64
 %word2_1 = trunc i140 %shift2_1 to i64
 %out2_1 = getelementptr i8,ptr %out,i64 56
 store i64 %word2_1,ptr %out2_1,align 1
 %shift2_2 = lshr i140 %r2,128
 %word2_2 = trunc i140 %shift2_2 to i64
 %out2_2 = getelementptr i8,ptr %out,i64 64
 store i64 %word2_2,ptr %out2_2,align 1
 %word3_0 = trunc i140 %r3 to i64
 %out3_0 = getelementptr i8,ptr %out,i64 72
 store i64 %word3_0,ptr %out3_0,align 1
 %shift3_1 = lshr i140 %r3,64
 %word3_1 = trunc i140 %shift3_1 to i64
 %out3_1 = getelementptr i8,ptr %out,i64 80
 store i64 %word3_1,ptr %out3_1,align 1
 %shift3_2 = lshr i140 %r3,128
 %word3_2 = trunc i140 %shift3_2 to i64
 %out3_2 = getelementptr i8,ptr %out,i64 88
 store i64 %word3_2,ptr %out3_2,align 1
 %word4_0 = trunc i200 %r4 to i64
 %out4_0 = getelementptr i8,ptr %out,i64 96
 store i64 %word4_0,ptr %out4_0,align 1
 %shift4_1 = lshr i200 %r4,64
 %word4_1 = trunc i200 %shift4_1 to i64
 %out4_1 = getelementptr i8,ptr %out,i64 104
 store i64 %word4_1,ptr %out4_1,align 1
 %shift4_2 = lshr i200 %r4,128
 %word4_2 = trunc i200 %shift4_2 to i64
 %out4_2 = getelementptr i8,ptr %out,i64 112
 store i64 %word4_2,ptr %out4_2,align 1
 %shift4_3 = lshr i200 %r4,192
 %word4_3 = trunc i200 %shift4_3 to i64
 %out4_3 = getelementptr i8,ptr %out,i64 120
 store i64 %word4_3,ptr %out4_3,align 1
 %word5_0 = trunc i200 %r5 to i64
 %out5_0 = getelementptr i8,ptr %out,i64 128
 store i64 %word5_0,ptr %out5_0,align 1
 %shift5_1 = lshr i200 %r5,64
 %word5_1 = trunc i200 %shift5_1 to i64
 %out5_1 = getelementptr i8,ptr %out,i64 136
 store i64 %word5_1,ptr %out5_1,align 1
 %shift5_2 = lshr i200 %r5,128
 %word5_2 = trunc i200 %shift5_2 to i64
 %out5_2 = getelementptr i8,ptr %out,i64 144
 store i64 %word5_2,ptr %out5_2,align 1
 %shift5_3 = lshr i200 %r5,192
 %word5_3 = trunc i200 %shift5_3 to i64
 %out5_3 = getelementptr i8,ptr %out,i64 152
 store i64 %word5_3,ptr %out5_3,align 1
 %mp = getelementptr i8,ptr %out,i64 160
 store i64 %mask,ptr %mp,align 1
 %op = getelementptr i8,ptr %out,i64 168
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %mask,%token
 ret i64 %answer
}
define i64 @wide_saturation_vector_probe_52(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %temporary = alloca [160 x i8],align 16
 %constant = alloca i140,align 16
 store i140 1267650600228229401496703205376,ptr %constant,align 16
 %bp = getelementptr i8,ptr %input,i64 32
 %sp = getelementptr i8,ptr %input,i64 64
 %s0 = load i64,ptr %sp,align 1
 %tp = getelementptr i8,ptr %input,i64 72
 %t0 = load i64,ptr %tp,align 1
 %temporary0 = getelementptr i8,ptr %temporary,i64 0
 call void @wide_sat_140_u_1(ptr %temporary0,ptr %input,i64 %s0)
 %temporary1 = getelementptr i8,ptr %temporary,i64 24
 call void @wide_sat_140_s_1(ptr %temporary1,ptr %input,i64 %s0)
 %temporary2 = getelementptr i8,ptr %temporary,i64 48
 call void @wide_sat_140_u_1(ptr %temporary2,ptr %constant,i64 %s0)
 %temporary3 = getelementptr i8,ptr %temporary,i64 72
 call void @wide_sat_140_s_1(ptr %temporary3,ptr %constant,i64 %s0)
 %temporary4 = getelementptr i8,ptr %temporary,i64 96
 call void @wide_sat_200_u_1(ptr %temporary4,ptr %bp,i64 %t0)
 %temporary5 = getelementptr i8,ptr %temporary,i64 128
 call void @wide_sat_200_s_1(ptr %temporary5,ptr %bp,i64 %t0)
 %r0 = load i140,ptr %temporary0,align 1
 %r1 = load i140,ptr %temporary1,align 1
 %r2 = load i140,ptr %temporary2,align 1
 %r3 = load i140,ptr %temporary3,align 1
 %r4 = load i200,ptr %temporary4,align 1
 %r5 = load i200,ptr %temporary5,align 1
 %v0 = insertelement <4 x i140> poison,i140 %r0,i64 0
 %v1 = insertelement <4 x i140> %v0,i140 %r1,i64 1
 %v2 = insertelement <4 x i140> %v1,i140 %r2,i64 2
 %v3 = insertelement <4 x i140> %v2,i140 %r3,i64 3
 %w0 = insertelement <4 x i140> poison,i140 0,i32 0
 %w1 = insertelement <4 x i140> %w0,i140 -1,i32 1
 %w2 = insertelement <4 x i140> %w1,i140 696898287454081973172991196020261297061887,i32 2
 %w3 = insertelement <4 x i140> %w2,i140 -696898287454081973172991196020261297061888,i32 3
 %cmp = icmp slt <4 x i140> %v3,%w3
 %packed_mask = bitcast <4 x i1> %cmp to i4
 %mask = zext i4 %packed_mask to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %word0_0 = trunc i140 %r0 to i64
 %out0_0 = getelementptr i8,ptr %out,i64 0
 store i64 %word0_0,ptr %out0_0,align 1
 %shift0_1 = lshr i140 %r0,64
 %word0_1 = trunc i140 %shift0_1 to i64
 %out0_1 = getelementptr i8,ptr %out,i64 8
 store i64 %word0_1,ptr %out0_1,align 1
 %shift0_2 = lshr i140 %r0,128
 %word0_2 = trunc i140 %shift0_2 to i64
 %out0_2 = getelementptr i8,ptr %out,i64 16
 store i64 %word0_2,ptr %out0_2,align 1
 %word1_0 = trunc i140 %r1 to i64
 %out1_0 = getelementptr i8,ptr %out,i64 24
 store i64 %word1_0,ptr %out1_0,align 1
 %shift1_1 = lshr i140 %r1,64
 %word1_1 = trunc i140 %shift1_1 to i64
 %out1_1 = getelementptr i8,ptr %out,i64 32
 store i64 %word1_1,ptr %out1_1,align 1
 %shift1_2 = lshr i140 %r1,128
 %word1_2 = trunc i140 %shift1_2 to i64
 %out1_2 = getelementptr i8,ptr %out,i64 40
 store i64 %word1_2,ptr %out1_2,align 1
 %word2_0 = trunc i140 %r2 to i64
 %out2_0 = getelementptr i8,ptr %out,i64 48
 store i64 %word2_0,ptr %out2_0,align 1
 %shift2_1 = lshr i140 %r2,64
 %word2_1 = trunc i140 %shift2_1 to i64
 %out2_1 = getelementptr i8,ptr %out,i64 56
 store i64 %word2_1,ptr %out2_1,align 1
 %shift2_2 = lshr i140 %r2,128
 %word2_2 = trunc i140 %shift2_2 to i64
 %out2_2 = getelementptr i8,ptr %out,i64 64
 store i64 %word2_2,ptr %out2_2,align 1
 %word3_0 = trunc i140 %r3 to i64
 %out3_0 = getelementptr i8,ptr %out,i64 72
 store i64 %word3_0,ptr %out3_0,align 1
 %shift3_1 = lshr i140 %r3,64
 %word3_1 = trunc i140 %shift3_1 to i64
 %out3_1 = getelementptr i8,ptr %out,i64 80
 store i64 %word3_1,ptr %out3_1,align 1
 %shift3_2 = lshr i140 %r3,128
 %word3_2 = trunc i140 %shift3_2 to i64
 %out3_2 = getelementptr i8,ptr %out,i64 88
 store i64 %word3_2,ptr %out3_2,align 1
 %word4_0 = trunc i200 %r4 to i64
 %out4_0 = getelementptr i8,ptr %out,i64 96
 store i64 %word4_0,ptr %out4_0,align 1
 %shift4_1 = lshr i200 %r4,64
 %word4_1 = trunc i200 %shift4_1 to i64
 %out4_1 = getelementptr i8,ptr %out,i64 104
 store i64 %word4_1,ptr %out4_1,align 1
 %shift4_2 = lshr i200 %r4,128
 %word4_2 = trunc i200 %shift4_2 to i64
 %out4_2 = getelementptr i8,ptr %out,i64 112
 store i64 %word4_2,ptr %out4_2,align 1
 %shift4_3 = lshr i200 %r4,192
 %word4_3 = trunc i200 %shift4_3 to i64
 %out4_3 = getelementptr i8,ptr %out,i64 120
 store i64 %word4_3,ptr %out4_3,align 1
 %word5_0 = trunc i200 %r5 to i64
 %out5_0 = getelementptr i8,ptr %out,i64 128
 store i64 %word5_0,ptr %out5_0,align 1
 %shift5_1 = lshr i200 %r5,64
 %word5_1 = trunc i200 %shift5_1 to i64
 %out5_1 = getelementptr i8,ptr %out,i64 136
 store i64 %word5_1,ptr %out5_1,align 1
 %shift5_2 = lshr i200 %r5,128
 %word5_2 = trunc i200 %shift5_2 to i64
 %out5_2 = getelementptr i8,ptr %out,i64 144
 store i64 %word5_2,ptr %out5_2,align 1
 %shift5_3 = lshr i200 %r5,192
 %word5_3 = trunc i200 %shift5_3 to i64
 %out5_3 = getelementptr i8,ptr %out,i64 152
 store i64 %word5_3,ptr %out5_3,align 1
 %mp = getelementptr i8,ptr %out,i64 160
 store i64 %mask,ptr %mp,align 1
 %op = getelementptr i8,ptr %out,i64 168
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %mask,%token
 ret i64 %answer
}
define i64 @wide_saturation_vector_probe_53(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %temporary = alloca [160 x i8],align 16
 %constant = alloca i140,align 16
 store i140 1267650600228229401496703205376,ptr %constant,align 16
 %bp = getelementptr i8,ptr %input,i64 32
 %sp = getelementptr i8,ptr %input,i64 64
 %s0 = load i64,ptr %sp,align 1
 %tp = getelementptr i8,ptr %input,i64 72
 %t0 = load i64,ptr %tp,align 1
 %temporary0 = getelementptr i8,ptr %temporary,i64 0
 call void @wide_sat_140_u_2(ptr %temporary0,ptr %input,i64 %s0)
 %temporary1 = getelementptr i8,ptr %temporary,i64 24
 call void @wide_sat_140_s_2(ptr %temporary1,ptr %input,i64 %s0)
 %temporary2 = getelementptr i8,ptr %temporary,i64 48
 call void @wide_sat_140_u_2(ptr %temporary2,ptr %constant,i64 %s0)
 %temporary3 = getelementptr i8,ptr %temporary,i64 72
 call void @wide_sat_140_s_2(ptr %temporary3,ptr %constant,i64 %s0)
 %temporary4 = getelementptr i8,ptr %temporary,i64 96
 call void @wide_sat_200_u_2(ptr %temporary4,ptr %bp,i64 %t0)
 %temporary5 = getelementptr i8,ptr %temporary,i64 128
 call void @wide_sat_200_s_2(ptr %temporary5,ptr %bp,i64 %t0)
 %r0 = load i140,ptr %temporary0,align 1
 %r1 = load i140,ptr %temporary1,align 1
 %r2 = load i140,ptr %temporary2,align 1
 %r3 = load i140,ptr %temporary3,align 1
 %r4 = load i200,ptr %temporary4,align 1
 %r5 = load i200,ptr %temporary5,align 1
 %v0 = insertelement <4 x i140> poison,i140 %r0,i64 0
 %v1 = insertelement <4 x i140> %v0,i140 %r1,i64 1
 %v2 = insertelement <4 x i140> %v1,i140 %r2,i64 2
 %v3 = insertelement <4 x i140> %v2,i140 %r3,i64 3
 %w0 = insertelement <4 x i140> poison,i140 0,i32 0
 %w1 = insertelement <4 x i140> %w0,i140 -1,i32 1
 %w2 = insertelement <4 x i140> %w1,i140 696898287454081973172991196020261297061887,i32 2
 %w3 = insertelement <4 x i140> %w2,i140 -696898287454081973172991196020261297061888,i32 3
 %cmp = icmp slt <4 x i140> %v3,%w3
 %packed_mask = bitcast <4 x i1> %cmp to i4
 %mask = zext i4 %packed_mask to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %word0_0 = trunc i140 %r0 to i64
 %out0_0 = getelementptr i8,ptr %out,i64 0
 store i64 %word0_0,ptr %out0_0,align 1
 %shift0_1 = lshr i140 %r0,64
 %word0_1 = trunc i140 %shift0_1 to i64
 %out0_1 = getelementptr i8,ptr %out,i64 8
 store i64 %word0_1,ptr %out0_1,align 1
 %shift0_2 = lshr i140 %r0,128
 %word0_2 = trunc i140 %shift0_2 to i64
 %out0_2 = getelementptr i8,ptr %out,i64 16
 store i64 %word0_2,ptr %out0_2,align 1
 %word1_0 = trunc i140 %r1 to i64
 %out1_0 = getelementptr i8,ptr %out,i64 24
 store i64 %word1_0,ptr %out1_0,align 1
 %shift1_1 = lshr i140 %r1,64
 %word1_1 = trunc i140 %shift1_1 to i64
 %out1_1 = getelementptr i8,ptr %out,i64 32
 store i64 %word1_1,ptr %out1_1,align 1
 %shift1_2 = lshr i140 %r1,128
 %word1_2 = trunc i140 %shift1_2 to i64
 %out1_2 = getelementptr i8,ptr %out,i64 40
 store i64 %word1_2,ptr %out1_2,align 1
 %word2_0 = trunc i140 %r2 to i64
 %out2_0 = getelementptr i8,ptr %out,i64 48
 store i64 %word2_0,ptr %out2_0,align 1
 %shift2_1 = lshr i140 %r2,64
 %word2_1 = trunc i140 %shift2_1 to i64
 %out2_1 = getelementptr i8,ptr %out,i64 56
 store i64 %word2_1,ptr %out2_1,align 1
 %shift2_2 = lshr i140 %r2,128
 %word2_2 = trunc i140 %shift2_2 to i64
 %out2_2 = getelementptr i8,ptr %out,i64 64
 store i64 %word2_2,ptr %out2_2,align 1
 %word3_0 = trunc i140 %r3 to i64
 %out3_0 = getelementptr i8,ptr %out,i64 72
 store i64 %word3_0,ptr %out3_0,align 1
 %shift3_1 = lshr i140 %r3,64
 %word3_1 = trunc i140 %shift3_1 to i64
 %out3_1 = getelementptr i8,ptr %out,i64 80
 store i64 %word3_1,ptr %out3_1,align 1
 %shift3_2 = lshr i140 %r3,128
 %word3_2 = trunc i140 %shift3_2 to i64
 %out3_2 = getelementptr i8,ptr %out,i64 88
 store i64 %word3_2,ptr %out3_2,align 1
 %word4_0 = trunc i200 %r4 to i64
 %out4_0 = getelementptr i8,ptr %out,i64 96
 store i64 %word4_0,ptr %out4_0,align 1
 %shift4_1 = lshr i200 %r4,64
 %word4_1 = trunc i200 %shift4_1 to i64
 %out4_1 = getelementptr i8,ptr %out,i64 104
 store i64 %word4_1,ptr %out4_1,align 1
 %shift4_2 = lshr i200 %r4,128
 %word4_2 = trunc i200 %shift4_2 to i64
 %out4_2 = getelementptr i8,ptr %out,i64 112
 store i64 %word4_2,ptr %out4_2,align 1
 %shift4_3 = lshr i200 %r4,192
 %word4_3 = trunc i200 %shift4_3 to i64
 %out4_3 = getelementptr i8,ptr %out,i64 120
 store i64 %word4_3,ptr %out4_3,align 1
 %word5_0 = trunc i200 %r5 to i64
 %out5_0 = getelementptr i8,ptr %out,i64 128
 store i64 %word5_0,ptr %out5_0,align 1
 %shift5_1 = lshr i200 %r5,64
 %word5_1 = trunc i200 %shift5_1 to i64
 %out5_1 = getelementptr i8,ptr %out,i64 136
 store i64 %word5_1,ptr %out5_1,align 1
 %shift5_2 = lshr i200 %r5,128
 %word5_2 = trunc i200 %shift5_2 to i64
 %out5_2 = getelementptr i8,ptr %out,i64 144
 store i64 %word5_2,ptr %out5_2,align 1
 %shift5_3 = lshr i200 %r5,192
 %word5_3 = trunc i200 %shift5_3 to i64
 %out5_3 = getelementptr i8,ptr %out,i64 152
 store i64 %word5_3,ptr %out5_3,align 1
 %mp = getelementptr i8,ptr %out,i64 160
 store i64 %mask,ptr %mp,align 1
 %op = getelementptr i8,ptr %out,i64 168
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %mask,%token
 ret i64 %answer
}
define i64 @wide_saturation_vector_probe_54(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %temporary = alloca [160 x i8],align 16
 %constant = alloca i140,align 16
 store i140 1267650600228229401496703205376,ptr %constant,align 16
 %bp = getelementptr i8,ptr %input,i64 32
 %sp = getelementptr i8,ptr %input,i64 64
 %s0 = load i64,ptr %sp,align 1
 %tp = getelementptr i8,ptr %input,i64 72
 %t0 = load i64,ptr %tp,align 1
 %temporary0 = getelementptr i8,ptr %temporary,i64 0
 call void @wide_sat_140_u_0(ptr %temporary0,ptr %input,i64 %s0)
 %temporary1 = getelementptr i8,ptr %temporary,i64 24
 call void @wide_sat_140_s_0(ptr %temporary1,ptr %input,i64 %s0)
 %temporary2 = getelementptr i8,ptr %temporary,i64 48
 call void @wide_sat_140_u_0(ptr %temporary2,ptr %constant,i64 %s0)
 %temporary3 = getelementptr i8,ptr %temporary,i64 72
 call void @wide_sat_140_s_0(ptr %temporary3,ptr %constant,i64 %s0)
 %temporary4 = getelementptr i8,ptr %temporary,i64 96
 call void @wide_sat_200_u_0(ptr %temporary4,ptr %bp,i64 %t0)
 %temporary5 = getelementptr i8,ptr %temporary,i64 128
 call void @wide_sat_200_s_0(ptr %temporary5,ptr %bp,i64 %t0)
 %r0 = load i140,ptr %temporary0,align 1
 %r1 = load i140,ptr %temporary1,align 1
 %r2 = load i140,ptr %temporary2,align 1
 %r3 = load i140,ptr %temporary3,align 1
 %r4 = load i200,ptr %temporary4,align 1
 %r5 = load i200,ptr %temporary5,align 1
 %v0 = insertelement <4 x i140> poison,i140 %r0,i64 0
 %v1 = insertelement <4 x i140> %v0,i140 %r1,i64 1
 %v2 = insertelement <4 x i140> %v1,i140 %r2,i64 2
 %v3 = insertelement <4 x i140> %v2,i140 %r3,i64 3
 %cmp = icmp sle <4 x i140> %v3,<i140 0,i140 -1,i140 696898287454081973172991196020261297061887,i140 -696898287454081973172991196020261297061888>
 %packed_mask = bitcast <4 x i1> %cmp to i4
 %mask = zext i4 %packed_mask to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %word0_0 = trunc i140 %r0 to i64
 %out0_0 = getelementptr i8,ptr %out,i64 0
 store i64 %word0_0,ptr %out0_0,align 1
 %shift0_1 = lshr i140 %r0,64
 %word0_1 = trunc i140 %shift0_1 to i64
 %out0_1 = getelementptr i8,ptr %out,i64 8
 store i64 %word0_1,ptr %out0_1,align 1
 %shift0_2 = lshr i140 %r0,128
 %word0_2 = trunc i140 %shift0_2 to i64
 %out0_2 = getelementptr i8,ptr %out,i64 16
 store i64 %word0_2,ptr %out0_2,align 1
 %word1_0 = trunc i140 %r1 to i64
 %out1_0 = getelementptr i8,ptr %out,i64 24
 store i64 %word1_0,ptr %out1_0,align 1
 %shift1_1 = lshr i140 %r1,64
 %word1_1 = trunc i140 %shift1_1 to i64
 %out1_1 = getelementptr i8,ptr %out,i64 32
 store i64 %word1_1,ptr %out1_1,align 1
 %shift1_2 = lshr i140 %r1,128
 %word1_2 = trunc i140 %shift1_2 to i64
 %out1_2 = getelementptr i8,ptr %out,i64 40
 store i64 %word1_2,ptr %out1_2,align 1
 %word2_0 = trunc i140 %r2 to i64
 %out2_0 = getelementptr i8,ptr %out,i64 48
 store i64 %word2_0,ptr %out2_0,align 1
 %shift2_1 = lshr i140 %r2,64
 %word2_1 = trunc i140 %shift2_1 to i64
 %out2_1 = getelementptr i8,ptr %out,i64 56
 store i64 %word2_1,ptr %out2_1,align 1
 %shift2_2 = lshr i140 %r2,128
 %word2_2 = trunc i140 %shift2_2 to i64
 %out2_2 = getelementptr i8,ptr %out,i64 64
 store i64 %word2_2,ptr %out2_2,align 1
 %word3_0 = trunc i140 %r3 to i64
 %out3_0 = getelementptr i8,ptr %out,i64 72
 store i64 %word3_0,ptr %out3_0,align 1
 %shift3_1 = lshr i140 %r3,64
 %word3_1 = trunc i140 %shift3_1 to i64
 %out3_1 = getelementptr i8,ptr %out,i64 80
 store i64 %word3_1,ptr %out3_1,align 1
 %shift3_2 = lshr i140 %r3,128
 %word3_2 = trunc i140 %shift3_2 to i64
 %out3_2 = getelementptr i8,ptr %out,i64 88
 store i64 %word3_2,ptr %out3_2,align 1
 %word4_0 = trunc i200 %r4 to i64
 %out4_0 = getelementptr i8,ptr %out,i64 96
 store i64 %word4_0,ptr %out4_0,align 1
 %shift4_1 = lshr i200 %r4,64
 %word4_1 = trunc i200 %shift4_1 to i64
 %out4_1 = getelementptr i8,ptr %out,i64 104
 store i64 %word4_1,ptr %out4_1,align 1
 %shift4_2 = lshr i200 %r4,128
 %word4_2 = trunc i200 %shift4_2 to i64
 %out4_2 = getelementptr i8,ptr %out,i64 112
 store i64 %word4_2,ptr %out4_2,align 1
 %shift4_3 = lshr i200 %r4,192
 %word4_3 = trunc i200 %shift4_3 to i64
 %out4_3 = getelementptr i8,ptr %out,i64 120
 store i64 %word4_3,ptr %out4_3,align 1
 %word5_0 = trunc i200 %r5 to i64
 %out5_0 = getelementptr i8,ptr %out,i64 128
 store i64 %word5_0,ptr %out5_0,align 1
 %shift5_1 = lshr i200 %r5,64
 %word5_1 = trunc i200 %shift5_1 to i64
 %out5_1 = getelementptr i8,ptr %out,i64 136
 store i64 %word5_1,ptr %out5_1,align 1
 %shift5_2 = lshr i200 %r5,128
 %word5_2 = trunc i200 %shift5_2 to i64
 %out5_2 = getelementptr i8,ptr %out,i64 144
 store i64 %word5_2,ptr %out5_2,align 1
 %shift5_3 = lshr i200 %r5,192
 %word5_3 = trunc i200 %shift5_3 to i64
 %out5_3 = getelementptr i8,ptr %out,i64 152
 store i64 %word5_3,ptr %out5_3,align 1
 %mp = getelementptr i8,ptr %out,i64 160
 store i64 %mask,ptr %mp,align 1
 %op = getelementptr i8,ptr %out,i64 168
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %mask,%token
 ret i64 %answer
}
define i64 @wide_saturation_vector_probe_55(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %temporary = alloca [160 x i8],align 16
 %constant = alloca i140,align 16
 store i140 1267650600228229401496703205376,ptr %constant,align 16
 %bp = getelementptr i8,ptr %input,i64 32
 %sp = getelementptr i8,ptr %input,i64 64
 %s0 = load i64,ptr %sp,align 1
 %tp = getelementptr i8,ptr %input,i64 72
 %t0 = load i64,ptr %tp,align 1
 %temporary0 = getelementptr i8,ptr %temporary,i64 0
 call void @wide_sat_140_u_1(ptr %temporary0,ptr %input,i64 %s0)
 %temporary1 = getelementptr i8,ptr %temporary,i64 24
 call void @wide_sat_140_s_1(ptr %temporary1,ptr %input,i64 %s0)
 %temporary2 = getelementptr i8,ptr %temporary,i64 48
 call void @wide_sat_140_u_1(ptr %temporary2,ptr %constant,i64 %s0)
 %temporary3 = getelementptr i8,ptr %temporary,i64 72
 call void @wide_sat_140_s_1(ptr %temporary3,ptr %constant,i64 %s0)
 %temporary4 = getelementptr i8,ptr %temporary,i64 96
 call void @wide_sat_200_u_1(ptr %temporary4,ptr %bp,i64 %t0)
 %temporary5 = getelementptr i8,ptr %temporary,i64 128
 call void @wide_sat_200_s_1(ptr %temporary5,ptr %bp,i64 %t0)
 %r0 = load i140,ptr %temporary0,align 1
 %r1 = load i140,ptr %temporary1,align 1
 %r2 = load i140,ptr %temporary2,align 1
 %r3 = load i140,ptr %temporary3,align 1
 %r4 = load i200,ptr %temporary4,align 1
 %r5 = load i200,ptr %temporary5,align 1
 %v0 = insertelement <4 x i140> poison,i140 %r0,i64 0
 %v1 = insertelement <4 x i140> %v0,i140 %r1,i64 1
 %v2 = insertelement <4 x i140> %v1,i140 %r2,i64 2
 %v3 = insertelement <4 x i140> %v2,i140 %r3,i64 3
 %cmp = icmp sle <4 x i140> %v3,<i140 0,i140 -1,i140 696898287454081973172991196020261297061887,i140 -696898287454081973172991196020261297061888>
 %packed_mask = bitcast <4 x i1> %cmp to i4
 %mask = zext i4 %packed_mask to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %word0_0 = trunc i140 %r0 to i64
 %out0_0 = getelementptr i8,ptr %out,i64 0
 store i64 %word0_0,ptr %out0_0,align 1
 %shift0_1 = lshr i140 %r0,64
 %word0_1 = trunc i140 %shift0_1 to i64
 %out0_1 = getelementptr i8,ptr %out,i64 8
 store i64 %word0_1,ptr %out0_1,align 1
 %shift0_2 = lshr i140 %r0,128
 %word0_2 = trunc i140 %shift0_2 to i64
 %out0_2 = getelementptr i8,ptr %out,i64 16
 store i64 %word0_2,ptr %out0_2,align 1
 %word1_0 = trunc i140 %r1 to i64
 %out1_0 = getelementptr i8,ptr %out,i64 24
 store i64 %word1_0,ptr %out1_0,align 1
 %shift1_1 = lshr i140 %r1,64
 %word1_1 = trunc i140 %shift1_1 to i64
 %out1_1 = getelementptr i8,ptr %out,i64 32
 store i64 %word1_1,ptr %out1_1,align 1
 %shift1_2 = lshr i140 %r1,128
 %word1_2 = trunc i140 %shift1_2 to i64
 %out1_2 = getelementptr i8,ptr %out,i64 40
 store i64 %word1_2,ptr %out1_2,align 1
 %word2_0 = trunc i140 %r2 to i64
 %out2_0 = getelementptr i8,ptr %out,i64 48
 store i64 %word2_0,ptr %out2_0,align 1
 %shift2_1 = lshr i140 %r2,64
 %word2_1 = trunc i140 %shift2_1 to i64
 %out2_1 = getelementptr i8,ptr %out,i64 56
 store i64 %word2_1,ptr %out2_1,align 1
 %shift2_2 = lshr i140 %r2,128
 %word2_2 = trunc i140 %shift2_2 to i64
 %out2_2 = getelementptr i8,ptr %out,i64 64
 store i64 %word2_2,ptr %out2_2,align 1
 %word3_0 = trunc i140 %r3 to i64
 %out3_0 = getelementptr i8,ptr %out,i64 72
 store i64 %word3_0,ptr %out3_0,align 1
 %shift3_1 = lshr i140 %r3,64
 %word3_1 = trunc i140 %shift3_1 to i64
 %out3_1 = getelementptr i8,ptr %out,i64 80
 store i64 %word3_1,ptr %out3_1,align 1
 %shift3_2 = lshr i140 %r3,128
 %word3_2 = trunc i140 %shift3_2 to i64
 %out3_2 = getelementptr i8,ptr %out,i64 88
 store i64 %word3_2,ptr %out3_2,align 1
 %word4_0 = trunc i200 %r4 to i64
 %out4_0 = getelementptr i8,ptr %out,i64 96
 store i64 %word4_0,ptr %out4_0,align 1
 %shift4_1 = lshr i200 %r4,64
 %word4_1 = trunc i200 %shift4_1 to i64
 %out4_1 = getelementptr i8,ptr %out,i64 104
 store i64 %word4_1,ptr %out4_1,align 1
 %shift4_2 = lshr i200 %r4,128
 %word4_2 = trunc i200 %shift4_2 to i64
 %out4_2 = getelementptr i8,ptr %out,i64 112
 store i64 %word4_2,ptr %out4_2,align 1
 %shift4_3 = lshr i200 %r4,192
 %word4_3 = trunc i200 %shift4_3 to i64
 %out4_3 = getelementptr i8,ptr %out,i64 120
 store i64 %word4_3,ptr %out4_3,align 1
 %word5_0 = trunc i200 %r5 to i64
 %out5_0 = getelementptr i8,ptr %out,i64 128
 store i64 %word5_0,ptr %out5_0,align 1
 %shift5_1 = lshr i200 %r5,64
 %word5_1 = trunc i200 %shift5_1 to i64
 %out5_1 = getelementptr i8,ptr %out,i64 136
 store i64 %word5_1,ptr %out5_1,align 1
 %shift5_2 = lshr i200 %r5,128
 %word5_2 = trunc i200 %shift5_2 to i64
 %out5_2 = getelementptr i8,ptr %out,i64 144
 store i64 %word5_2,ptr %out5_2,align 1
 %shift5_3 = lshr i200 %r5,192
 %word5_3 = trunc i200 %shift5_3 to i64
 %out5_3 = getelementptr i8,ptr %out,i64 152
 store i64 %word5_3,ptr %out5_3,align 1
 %mp = getelementptr i8,ptr %out,i64 160
 store i64 %mask,ptr %mp,align 1
 %op = getelementptr i8,ptr %out,i64 168
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %mask,%token
 ret i64 %answer
}
define i64 @wide_saturation_vector_probe_56(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %temporary = alloca [160 x i8],align 16
 %constant = alloca i140,align 16
 store i140 1267650600228229401496703205376,ptr %constant,align 16
 %bp = getelementptr i8,ptr %input,i64 32
 %sp = getelementptr i8,ptr %input,i64 64
 %s0 = load i64,ptr %sp,align 1
 %tp = getelementptr i8,ptr %input,i64 72
 %t0 = load i64,ptr %tp,align 1
 %temporary0 = getelementptr i8,ptr %temporary,i64 0
 call void @wide_sat_140_u_2(ptr %temporary0,ptr %input,i64 %s0)
 %temporary1 = getelementptr i8,ptr %temporary,i64 24
 call void @wide_sat_140_s_2(ptr %temporary1,ptr %input,i64 %s0)
 %temporary2 = getelementptr i8,ptr %temporary,i64 48
 call void @wide_sat_140_u_2(ptr %temporary2,ptr %constant,i64 %s0)
 %temporary3 = getelementptr i8,ptr %temporary,i64 72
 call void @wide_sat_140_s_2(ptr %temporary3,ptr %constant,i64 %s0)
 %temporary4 = getelementptr i8,ptr %temporary,i64 96
 call void @wide_sat_200_u_2(ptr %temporary4,ptr %bp,i64 %t0)
 %temporary5 = getelementptr i8,ptr %temporary,i64 128
 call void @wide_sat_200_s_2(ptr %temporary5,ptr %bp,i64 %t0)
 %r0 = load i140,ptr %temporary0,align 1
 %r1 = load i140,ptr %temporary1,align 1
 %r2 = load i140,ptr %temporary2,align 1
 %r3 = load i140,ptr %temporary3,align 1
 %r4 = load i200,ptr %temporary4,align 1
 %r5 = load i200,ptr %temporary5,align 1
 %v0 = insertelement <4 x i140> poison,i140 %r0,i64 0
 %v1 = insertelement <4 x i140> %v0,i140 %r1,i64 1
 %v2 = insertelement <4 x i140> %v1,i140 %r2,i64 2
 %v3 = insertelement <4 x i140> %v2,i140 %r3,i64 3
 %cmp = icmp sle <4 x i140> %v3,<i140 0,i140 -1,i140 696898287454081973172991196020261297061887,i140 -696898287454081973172991196020261297061888>
 %packed_mask = bitcast <4 x i1> %cmp to i4
 %mask = zext i4 %packed_mask to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %word0_0 = trunc i140 %r0 to i64
 %out0_0 = getelementptr i8,ptr %out,i64 0
 store i64 %word0_0,ptr %out0_0,align 1
 %shift0_1 = lshr i140 %r0,64
 %word0_1 = trunc i140 %shift0_1 to i64
 %out0_1 = getelementptr i8,ptr %out,i64 8
 store i64 %word0_1,ptr %out0_1,align 1
 %shift0_2 = lshr i140 %r0,128
 %word0_2 = trunc i140 %shift0_2 to i64
 %out0_2 = getelementptr i8,ptr %out,i64 16
 store i64 %word0_2,ptr %out0_2,align 1
 %word1_0 = trunc i140 %r1 to i64
 %out1_0 = getelementptr i8,ptr %out,i64 24
 store i64 %word1_0,ptr %out1_0,align 1
 %shift1_1 = lshr i140 %r1,64
 %word1_1 = trunc i140 %shift1_1 to i64
 %out1_1 = getelementptr i8,ptr %out,i64 32
 store i64 %word1_1,ptr %out1_1,align 1
 %shift1_2 = lshr i140 %r1,128
 %word1_2 = trunc i140 %shift1_2 to i64
 %out1_2 = getelementptr i8,ptr %out,i64 40
 store i64 %word1_2,ptr %out1_2,align 1
 %word2_0 = trunc i140 %r2 to i64
 %out2_0 = getelementptr i8,ptr %out,i64 48
 store i64 %word2_0,ptr %out2_0,align 1
 %shift2_1 = lshr i140 %r2,64
 %word2_1 = trunc i140 %shift2_1 to i64
 %out2_1 = getelementptr i8,ptr %out,i64 56
 store i64 %word2_1,ptr %out2_1,align 1
 %shift2_2 = lshr i140 %r2,128
 %word2_2 = trunc i140 %shift2_2 to i64
 %out2_2 = getelementptr i8,ptr %out,i64 64
 store i64 %word2_2,ptr %out2_2,align 1
 %word3_0 = trunc i140 %r3 to i64
 %out3_0 = getelementptr i8,ptr %out,i64 72
 store i64 %word3_0,ptr %out3_0,align 1
 %shift3_1 = lshr i140 %r3,64
 %word3_1 = trunc i140 %shift3_1 to i64
 %out3_1 = getelementptr i8,ptr %out,i64 80
 store i64 %word3_1,ptr %out3_1,align 1
 %shift3_2 = lshr i140 %r3,128
 %word3_2 = trunc i140 %shift3_2 to i64
 %out3_2 = getelementptr i8,ptr %out,i64 88
 store i64 %word3_2,ptr %out3_2,align 1
 %word4_0 = trunc i200 %r4 to i64
 %out4_0 = getelementptr i8,ptr %out,i64 96
 store i64 %word4_0,ptr %out4_0,align 1
 %shift4_1 = lshr i200 %r4,64
 %word4_1 = trunc i200 %shift4_1 to i64
 %out4_1 = getelementptr i8,ptr %out,i64 104
 store i64 %word4_1,ptr %out4_1,align 1
 %shift4_2 = lshr i200 %r4,128
 %word4_2 = trunc i200 %shift4_2 to i64
 %out4_2 = getelementptr i8,ptr %out,i64 112
 store i64 %word4_2,ptr %out4_2,align 1
 %shift4_3 = lshr i200 %r4,192
 %word4_3 = trunc i200 %shift4_3 to i64
 %out4_3 = getelementptr i8,ptr %out,i64 120
 store i64 %word4_3,ptr %out4_3,align 1
 %word5_0 = trunc i200 %r5 to i64
 %out5_0 = getelementptr i8,ptr %out,i64 128
 store i64 %word5_0,ptr %out5_0,align 1
 %shift5_1 = lshr i200 %r5,64
 %word5_1 = trunc i200 %shift5_1 to i64
 %out5_1 = getelementptr i8,ptr %out,i64 136
 store i64 %word5_1,ptr %out5_1,align 1
 %shift5_2 = lshr i200 %r5,128
 %word5_2 = trunc i200 %shift5_2 to i64
 %out5_2 = getelementptr i8,ptr %out,i64 144
 store i64 %word5_2,ptr %out5_2,align 1
 %shift5_3 = lshr i200 %r5,192
 %word5_3 = trunc i200 %shift5_3 to i64
 %out5_3 = getelementptr i8,ptr %out,i64 152
 store i64 %word5_3,ptr %out5_3,align 1
 %mp = getelementptr i8,ptr %out,i64 160
 store i64 %mask,ptr %mp,align 1
 %op = getelementptr i8,ptr %out,i64 168
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %mask,%token
 ret i64 %answer
}
define i64 @wide_saturation_vector_probe_57(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %temporary = alloca [160 x i8],align 16
 %constant = alloca i140,align 16
 store i140 1267650600228229401496703205376,ptr %constant,align 16
 %bp = getelementptr i8,ptr %input,i64 32
 %sp = getelementptr i8,ptr %input,i64 64
 %s0 = load i64,ptr %sp,align 1
 %tp = getelementptr i8,ptr %input,i64 72
 %t0 = load i64,ptr %tp,align 1
 %temporary0 = getelementptr i8,ptr %temporary,i64 0
 call void @wide_sat_140_u_0(ptr %temporary0,ptr %input,i64 %s0)
 %temporary1 = getelementptr i8,ptr %temporary,i64 24
 call void @wide_sat_140_s_0(ptr %temporary1,ptr %input,i64 %s0)
 %temporary2 = getelementptr i8,ptr %temporary,i64 48
 call void @wide_sat_140_u_0(ptr %temporary2,ptr %constant,i64 %s0)
 %temporary3 = getelementptr i8,ptr %temporary,i64 72
 call void @wide_sat_140_s_0(ptr %temporary3,ptr %constant,i64 %s0)
 %temporary4 = getelementptr i8,ptr %temporary,i64 96
 call void @wide_sat_200_u_0(ptr %temporary4,ptr %bp,i64 %t0)
 %temporary5 = getelementptr i8,ptr %temporary,i64 128
 call void @wide_sat_200_s_0(ptr %temporary5,ptr %bp,i64 %t0)
 %r0 = load i140,ptr %temporary0,align 1
 %r1 = load i140,ptr %temporary1,align 1
 %r2 = load i140,ptr %temporary2,align 1
 %r3 = load i140,ptr %temporary3,align 1
 %r4 = load i200,ptr %temporary4,align 1
 %r5 = load i200,ptr %temporary5,align 1
 %v0 = insertelement <4 x i140> poison,i140 %r0,i64 0
 %v1 = insertelement <4 x i140> %v0,i140 %r1,i64 1
 %v2 = insertelement <4 x i140> %v1,i140 %r2,i64 2
 %v3 = insertelement <4 x i140> %v2,i140 %r3,i64 3
 %w0 = insertelement <4 x i140> poison,i140 0,i32 0
 %w1 = insertelement <4 x i140> %w0,i140 -1,i32 1
 %w2 = insertelement <4 x i140> %w1,i140 696898287454081973172991196020261297061887,i32 2
 %w3 = insertelement <4 x i140> %w2,i140 -696898287454081973172991196020261297061888,i32 3
 %cmp = icmp sle <4 x i140> %v3,%w3
 %packed_mask = bitcast <4 x i1> %cmp to i4
 %mask = zext i4 %packed_mask to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %word0_0 = trunc i140 %r0 to i64
 %out0_0 = getelementptr i8,ptr %out,i64 0
 store i64 %word0_0,ptr %out0_0,align 1
 %shift0_1 = lshr i140 %r0,64
 %word0_1 = trunc i140 %shift0_1 to i64
 %out0_1 = getelementptr i8,ptr %out,i64 8
 store i64 %word0_1,ptr %out0_1,align 1
 %shift0_2 = lshr i140 %r0,128
 %word0_2 = trunc i140 %shift0_2 to i64
 %out0_2 = getelementptr i8,ptr %out,i64 16
 store i64 %word0_2,ptr %out0_2,align 1
 %word1_0 = trunc i140 %r1 to i64
 %out1_0 = getelementptr i8,ptr %out,i64 24
 store i64 %word1_0,ptr %out1_0,align 1
 %shift1_1 = lshr i140 %r1,64
 %word1_1 = trunc i140 %shift1_1 to i64
 %out1_1 = getelementptr i8,ptr %out,i64 32
 store i64 %word1_1,ptr %out1_1,align 1
 %shift1_2 = lshr i140 %r1,128
 %word1_2 = trunc i140 %shift1_2 to i64
 %out1_2 = getelementptr i8,ptr %out,i64 40
 store i64 %word1_2,ptr %out1_2,align 1
 %word2_0 = trunc i140 %r2 to i64
 %out2_0 = getelementptr i8,ptr %out,i64 48
 store i64 %word2_0,ptr %out2_0,align 1
 %shift2_1 = lshr i140 %r2,64
 %word2_1 = trunc i140 %shift2_1 to i64
 %out2_1 = getelementptr i8,ptr %out,i64 56
 store i64 %word2_1,ptr %out2_1,align 1
 %shift2_2 = lshr i140 %r2,128
 %word2_2 = trunc i140 %shift2_2 to i64
 %out2_2 = getelementptr i8,ptr %out,i64 64
 store i64 %word2_2,ptr %out2_2,align 1
 %word3_0 = trunc i140 %r3 to i64
 %out3_0 = getelementptr i8,ptr %out,i64 72
 store i64 %word3_0,ptr %out3_0,align 1
 %shift3_1 = lshr i140 %r3,64
 %word3_1 = trunc i140 %shift3_1 to i64
 %out3_1 = getelementptr i8,ptr %out,i64 80
 store i64 %word3_1,ptr %out3_1,align 1
 %shift3_2 = lshr i140 %r3,128
 %word3_2 = trunc i140 %shift3_2 to i64
 %out3_2 = getelementptr i8,ptr %out,i64 88
 store i64 %word3_2,ptr %out3_2,align 1
 %word4_0 = trunc i200 %r4 to i64
 %out4_0 = getelementptr i8,ptr %out,i64 96
 store i64 %word4_0,ptr %out4_0,align 1
 %shift4_1 = lshr i200 %r4,64
 %word4_1 = trunc i200 %shift4_1 to i64
 %out4_1 = getelementptr i8,ptr %out,i64 104
 store i64 %word4_1,ptr %out4_1,align 1
 %shift4_2 = lshr i200 %r4,128
 %word4_2 = trunc i200 %shift4_2 to i64
 %out4_2 = getelementptr i8,ptr %out,i64 112
 store i64 %word4_2,ptr %out4_2,align 1
 %shift4_3 = lshr i200 %r4,192
 %word4_3 = trunc i200 %shift4_3 to i64
 %out4_3 = getelementptr i8,ptr %out,i64 120
 store i64 %word4_3,ptr %out4_3,align 1
 %word5_0 = trunc i200 %r5 to i64
 %out5_0 = getelementptr i8,ptr %out,i64 128
 store i64 %word5_0,ptr %out5_0,align 1
 %shift5_1 = lshr i200 %r5,64
 %word5_1 = trunc i200 %shift5_1 to i64
 %out5_1 = getelementptr i8,ptr %out,i64 136
 store i64 %word5_1,ptr %out5_1,align 1
 %shift5_2 = lshr i200 %r5,128
 %word5_2 = trunc i200 %shift5_2 to i64
 %out5_2 = getelementptr i8,ptr %out,i64 144
 store i64 %word5_2,ptr %out5_2,align 1
 %shift5_3 = lshr i200 %r5,192
 %word5_3 = trunc i200 %shift5_3 to i64
 %out5_3 = getelementptr i8,ptr %out,i64 152
 store i64 %word5_3,ptr %out5_3,align 1
 %mp = getelementptr i8,ptr %out,i64 160
 store i64 %mask,ptr %mp,align 1
 %op = getelementptr i8,ptr %out,i64 168
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %mask,%token
 ret i64 %answer
}
define i64 @wide_saturation_vector_probe_58(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %temporary = alloca [160 x i8],align 16
 %constant = alloca i140,align 16
 store i140 1267650600228229401496703205376,ptr %constant,align 16
 %bp = getelementptr i8,ptr %input,i64 32
 %sp = getelementptr i8,ptr %input,i64 64
 %s0 = load i64,ptr %sp,align 1
 %tp = getelementptr i8,ptr %input,i64 72
 %t0 = load i64,ptr %tp,align 1
 %temporary0 = getelementptr i8,ptr %temporary,i64 0
 call void @wide_sat_140_u_1(ptr %temporary0,ptr %input,i64 %s0)
 %temporary1 = getelementptr i8,ptr %temporary,i64 24
 call void @wide_sat_140_s_1(ptr %temporary1,ptr %input,i64 %s0)
 %temporary2 = getelementptr i8,ptr %temporary,i64 48
 call void @wide_sat_140_u_1(ptr %temporary2,ptr %constant,i64 %s0)
 %temporary3 = getelementptr i8,ptr %temporary,i64 72
 call void @wide_sat_140_s_1(ptr %temporary3,ptr %constant,i64 %s0)
 %temporary4 = getelementptr i8,ptr %temporary,i64 96
 call void @wide_sat_200_u_1(ptr %temporary4,ptr %bp,i64 %t0)
 %temporary5 = getelementptr i8,ptr %temporary,i64 128
 call void @wide_sat_200_s_1(ptr %temporary5,ptr %bp,i64 %t0)
 %r0 = load i140,ptr %temporary0,align 1
 %r1 = load i140,ptr %temporary1,align 1
 %r2 = load i140,ptr %temporary2,align 1
 %r3 = load i140,ptr %temporary3,align 1
 %r4 = load i200,ptr %temporary4,align 1
 %r5 = load i200,ptr %temporary5,align 1
 %v0 = insertelement <4 x i140> poison,i140 %r0,i64 0
 %v1 = insertelement <4 x i140> %v0,i140 %r1,i64 1
 %v2 = insertelement <4 x i140> %v1,i140 %r2,i64 2
 %v3 = insertelement <4 x i140> %v2,i140 %r3,i64 3
 %w0 = insertelement <4 x i140> poison,i140 0,i32 0
 %w1 = insertelement <4 x i140> %w0,i140 -1,i32 1
 %w2 = insertelement <4 x i140> %w1,i140 696898287454081973172991196020261297061887,i32 2
 %w3 = insertelement <4 x i140> %w2,i140 -696898287454081973172991196020261297061888,i32 3
 %cmp = icmp sle <4 x i140> %v3,%w3
 %packed_mask = bitcast <4 x i1> %cmp to i4
 %mask = zext i4 %packed_mask to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %word0_0 = trunc i140 %r0 to i64
 %out0_0 = getelementptr i8,ptr %out,i64 0
 store i64 %word0_0,ptr %out0_0,align 1
 %shift0_1 = lshr i140 %r0,64
 %word0_1 = trunc i140 %shift0_1 to i64
 %out0_1 = getelementptr i8,ptr %out,i64 8
 store i64 %word0_1,ptr %out0_1,align 1
 %shift0_2 = lshr i140 %r0,128
 %word0_2 = trunc i140 %shift0_2 to i64
 %out0_2 = getelementptr i8,ptr %out,i64 16
 store i64 %word0_2,ptr %out0_2,align 1
 %word1_0 = trunc i140 %r1 to i64
 %out1_0 = getelementptr i8,ptr %out,i64 24
 store i64 %word1_0,ptr %out1_0,align 1
 %shift1_1 = lshr i140 %r1,64
 %word1_1 = trunc i140 %shift1_1 to i64
 %out1_1 = getelementptr i8,ptr %out,i64 32
 store i64 %word1_1,ptr %out1_1,align 1
 %shift1_2 = lshr i140 %r1,128
 %word1_2 = trunc i140 %shift1_2 to i64
 %out1_2 = getelementptr i8,ptr %out,i64 40
 store i64 %word1_2,ptr %out1_2,align 1
 %word2_0 = trunc i140 %r2 to i64
 %out2_0 = getelementptr i8,ptr %out,i64 48
 store i64 %word2_0,ptr %out2_0,align 1
 %shift2_1 = lshr i140 %r2,64
 %word2_1 = trunc i140 %shift2_1 to i64
 %out2_1 = getelementptr i8,ptr %out,i64 56
 store i64 %word2_1,ptr %out2_1,align 1
 %shift2_2 = lshr i140 %r2,128
 %word2_2 = trunc i140 %shift2_2 to i64
 %out2_2 = getelementptr i8,ptr %out,i64 64
 store i64 %word2_2,ptr %out2_2,align 1
 %word3_0 = trunc i140 %r3 to i64
 %out3_0 = getelementptr i8,ptr %out,i64 72
 store i64 %word3_0,ptr %out3_0,align 1
 %shift3_1 = lshr i140 %r3,64
 %word3_1 = trunc i140 %shift3_1 to i64
 %out3_1 = getelementptr i8,ptr %out,i64 80
 store i64 %word3_1,ptr %out3_1,align 1
 %shift3_2 = lshr i140 %r3,128
 %word3_2 = trunc i140 %shift3_2 to i64
 %out3_2 = getelementptr i8,ptr %out,i64 88
 store i64 %word3_2,ptr %out3_2,align 1
 %word4_0 = trunc i200 %r4 to i64
 %out4_0 = getelementptr i8,ptr %out,i64 96
 store i64 %word4_0,ptr %out4_0,align 1
 %shift4_1 = lshr i200 %r4,64
 %word4_1 = trunc i200 %shift4_1 to i64
 %out4_1 = getelementptr i8,ptr %out,i64 104
 store i64 %word4_1,ptr %out4_1,align 1
 %shift4_2 = lshr i200 %r4,128
 %word4_2 = trunc i200 %shift4_2 to i64
 %out4_2 = getelementptr i8,ptr %out,i64 112
 store i64 %word4_2,ptr %out4_2,align 1
 %shift4_3 = lshr i200 %r4,192
 %word4_3 = trunc i200 %shift4_3 to i64
 %out4_3 = getelementptr i8,ptr %out,i64 120
 store i64 %word4_3,ptr %out4_3,align 1
 %word5_0 = trunc i200 %r5 to i64
 %out5_0 = getelementptr i8,ptr %out,i64 128
 store i64 %word5_0,ptr %out5_0,align 1
 %shift5_1 = lshr i200 %r5,64
 %word5_1 = trunc i200 %shift5_1 to i64
 %out5_1 = getelementptr i8,ptr %out,i64 136
 store i64 %word5_1,ptr %out5_1,align 1
 %shift5_2 = lshr i200 %r5,128
 %word5_2 = trunc i200 %shift5_2 to i64
 %out5_2 = getelementptr i8,ptr %out,i64 144
 store i64 %word5_2,ptr %out5_2,align 1
 %shift5_3 = lshr i200 %r5,192
 %word5_3 = trunc i200 %shift5_3 to i64
 %out5_3 = getelementptr i8,ptr %out,i64 152
 store i64 %word5_3,ptr %out5_3,align 1
 %mp = getelementptr i8,ptr %out,i64 160
 store i64 %mask,ptr %mp,align 1
 %op = getelementptr i8,ptr %out,i64 168
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %mask,%token
 ret i64 %answer
}
define i64 @wide_saturation_vector_probe_59(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %temporary = alloca [160 x i8],align 16
 %constant = alloca i140,align 16
 store i140 1267650600228229401496703205376,ptr %constant,align 16
 %bp = getelementptr i8,ptr %input,i64 32
 %sp = getelementptr i8,ptr %input,i64 64
 %s0 = load i64,ptr %sp,align 1
 %tp = getelementptr i8,ptr %input,i64 72
 %t0 = load i64,ptr %tp,align 1
 %temporary0 = getelementptr i8,ptr %temporary,i64 0
 call void @wide_sat_140_u_2(ptr %temporary0,ptr %input,i64 %s0)
 %temporary1 = getelementptr i8,ptr %temporary,i64 24
 call void @wide_sat_140_s_2(ptr %temporary1,ptr %input,i64 %s0)
 %temporary2 = getelementptr i8,ptr %temporary,i64 48
 call void @wide_sat_140_u_2(ptr %temporary2,ptr %constant,i64 %s0)
 %temporary3 = getelementptr i8,ptr %temporary,i64 72
 call void @wide_sat_140_s_2(ptr %temporary3,ptr %constant,i64 %s0)
 %temporary4 = getelementptr i8,ptr %temporary,i64 96
 call void @wide_sat_200_u_2(ptr %temporary4,ptr %bp,i64 %t0)
 %temporary5 = getelementptr i8,ptr %temporary,i64 128
 call void @wide_sat_200_s_2(ptr %temporary5,ptr %bp,i64 %t0)
 %r0 = load i140,ptr %temporary0,align 1
 %r1 = load i140,ptr %temporary1,align 1
 %r2 = load i140,ptr %temporary2,align 1
 %r3 = load i140,ptr %temporary3,align 1
 %r4 = load i200,ptr %temporary4,align 1
 %r5 = load i200,ptr %temporary5,align 1
 %v0 = insertelement <4 x i140> poison,i140 %r0,i64 0
 %v1 = insertelement <4 x i140> %v0,i140 %r1,i64 1
 %v2 = insertelement <4 x i140> %v1,i140 %r2,i64 2
 %v3 = insertelement <4 x i140> %v2,i140 %r3,i64 3
 %w0 = insertelement <4 x i140> poison,i140 0,i32 0
 %w1 = insertelement <4 x i140> %w0,i140 -1,i32 1
 %w2 = insertelement <4 x i140> %w1,i140 696898287454081973172991196020261297061887,i32 2
 %w3 = insertelement <4 x i140> %w2,i140 -696898287454081973172991196020261297061888,i32 3
 %cmp = icmp sle <4 x i140> %v3,%w3
 %packed_mask = bitcast <4 x i1> %cmp to i4
 %mask = zext i4 %packed_mask to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %word0_0 = trunc i140 %r0 to i64
 %out0_0 = getelementptr i8,ptr %out,i64 0
 store i64 %word0_0,ptr %out0_0,align 1
 %shift0_1 = lshr i140 %r0,64
 %word0_1 = trunc i140 %shift0_1 to i64
 %out0_1 = getelementptr i8,ptr %out,i64 8
 store i64 %word0_1,ptr %out0_1,align 1
 %shift0_2 = lshr i140 %r0,128
 %word0_2 = trunc i140 %shift0_2 to i64
 %out0_2 = getelementptr i8,ptr %out,i64 16
 store i64 %word0_2,ptr %out0_2,align 1
 %word1_0 = trunc i140 %r1 to i64
 %out1_0 = getelementptr i8,ptr %out,i64 24
 store i64 %word1_0,ptr %out1_0,align 1
 %shift1_1 = lshr i140 %r1,64
 %word1_1 = trunc i140 %shift1_1 to i64
 %out1_1 = getelementptr i8,ptr %out,i64 32
 store i64 %word1_1,ptr %out1_1,align 1
 %shift1_2 = lshr i140 %r1,128
 %word1_2 = trunc i140 %shift1_2 to i64
 %out1_2 = getelementptr i8,ptr %out,i64 40
 store i64 %word1_2,ptr %out1_2,align 1
 %word2_0 = trunc i140 %r2 to i64
 %out2_0 = getelementptr i8,ptr %out,i64 48
 store i64 %word2_0,ptr %out2_0,align 1
 %shift2_1 = lshr i140 %r2,64
 %word2_1 = trunc i140 %shift2_1 to i64
 %out2_1 = getelementptr i8,ptr %out,i64 56
 store i64 %word2_1,ptr %out2_1,align 1
 %shift2_2 = lshr i140 %r2,128
 %word2_2 = trunc i140 %shift2_2 to i64
 %out2_2 = getelementptr i8,ptr %out,i64 64
 store i64 %word2_2,ptr %out2_2,align 1
 %word3_0 = trunc i140 %r3 to i64
 %out3_0 = getelementptr i8,ptr %out,i64 72
 store i64 %word3_0,ptr %out3_0,align 1
 %shift3_1 = lshr i140 %r3,64
 %word3_1 = trunc i140 %shift3_1 to i64
 %out3_1 = getelementptr i8,ptr %out,i64 80
 store i64 %word3_1,ptr %out3_1,align 1
 %shift3_2 = lshr i140 %r3,128
 %word3_2 = trunc i140 %shift3_2 to i64
 %out3_2 = getelementptr i8,ptr %out,i64 88
 store i64 %word3_2,ptr %out3_2,align 1
 %word4_0 = trunc i200 %r4 to i64
 %out4_0 = getelementptr i8,ptr %out,i64 96
 store i64 %word4_0,ptr %out4_0,align 1
 %shift4_1 = lshr i200 %r4,64
 %word4_1 = trunc i200 %shift4_1 to i64
 %out4_1 = getelementptr i8,ptr %out,i64 104
 store i64 %word4_1,ptr %out4_1,align 1
 %shift4_2 = lshr i200 %r4,128
 %word4_2 = trunc i200 %shift4_2 to i64
 %out4_2 = getelementptr i8,ptr %out,i64 112
 store i64 %word4_2,ptr %out4_2,align 1
 %shift4_3 = lshr i200 %r4,192
 %word4_3 = trunc i200 %shift4_3 to i64
 %out4_3 = getelementptr i8,ptr %out,i64 120
 store i64 %word4_3,ptr %out4_3,align 1
 %word5_0 = trunc i200 %r5 to i64
 %out5_0 = getelementptr i8,ptr %out,i64 128
 store i64 %word5_0,ptr %out5_0,align 1
 %shift5_1 = lshr i200 %r5,64
 %word5_1 = trunc i200 %shift5_1 to i64
 %out5_1 = getelementptr i8,ptr %out,i64 136
 store i64 %word5_1,ptr %out5_1,align 1
 %shift5_2 = lshr i200 %r5,128
 %word5_2 = trunc i200 %shift5_2 to i64
 %out5_2 = getelementptr i8,ptr %out,i64 144
 store i64 %word5_2,ptr %out5_2,align 1
 %shift5_3 = lshr i200 %r5,192
 %word5_3 = trunc i200 %shift5_3 to i64
 %out5_3 = getelementptr i8,ptr %out,i64 152
 store i64 %word5_3,ptr %out5_3,align 1
 %mp = getelementptr i8,ptr %out,i64 160
 store i64 %mask,ptr %mp,align 1
 %op = getelementptr i8,ptr %out,i64 168
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %mask,%token
 ret i64 %answer
}
