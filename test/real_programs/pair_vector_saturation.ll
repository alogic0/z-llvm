target triple = "x86_64-unknown-linux-gnu"
declare <2 x i128> @llvm.uadd.sat.v2i128(<2 x i128>,<2 x i128>)
define i64 @pair_vector_saturation_2_0(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %slot = alloca <2 x i128>,align 32
 %a = load <2 x i128>,ptr %ap,align 1
 %b = load <2 x i128>,ptr %bp,align 1
 store <2 x i128> %a,ptr %slot,align 1
 %again = load <2 x i128>,ptr %slot,align 1
 %r = call <2 x i128> @llvm.uadd.sat.v2i128(<2 x i128> %again,<2 x i128> %b)
 store <2 x i128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <2 x i128> @llvm.usub.sat.v2i128(<2 x i128>,<2 x i128>)
define i64 @pair_vector_saturation_2_1(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %slot = alloca <2 x i128>,align 32
 %a = load <2 x i128>,ptr %ap,align 1
 %b = load <2 x i128>,ptr %bp,align 1
 store <2 x i128> %a,ptr %slot,align 1
 %again = load <2 x i128>,ptr %slot,align 1
 %r = call <2 x i128> @llvm.usub.sat.v2i128(<2 x i128> %again,<2 x i128> %b)
 store <2 x i128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <2 x i128> @llvm.sadd.sat.v2i128(<2 x i128>,<2 x i128>)
define i64 @pair_vector_saturation_2_2(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %slot = alloca <2 x i128>,align 32
 %a = load <2 x i128>,ptr %ap,align 1
 %b = load <2 x i128>,ptr %bp,align 1
 store <2 x i128> %a,ptr %slot,align 1
 %again = load <2 x i128>,ptr %slot,align 1
 %r = call <2 x i128> @llvm.sadd.sat.v2i128(<2 x i128> %again,<2 x i128> %b)
 store <2 x i128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <2 x i128> @llvm.ssub.sat.v2i128(<2 x i128>,<2 x i128>)
define i64 @pair_vector_saturation_2_3(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %slot = alloca <2 x i128>,align 32
 %a = load <2 x i128>,ptr %ap,align 1
 %b = load <2 x i128>,ptr %bp,align 1
 store <2 x i128> %a,ptr %slot,align 1
 %again = load <2 x i128>,ptr %slot,align 1
 %r = call <2 x i128> @llvm.ssub.sat.v2i128(<2 x i128> %again,<2 x i128> %b)
 store <2 x i128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <2 x i128> @llvm.umin.v2i128(<2 x i128>,<2 x i128>)
define i64 @pair_vector_saturation_2_4(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %slot = alloca <2 x i128>,align 32
 %a = load <2 x i128>,ptr %ap,align 1
 %b = load <2 x i128>,ptr %bp,align 1
 store <2 x i128> %a,ptr %slot,align 1
 %again = load <2 x i128>,ptr %slot,align 1
 %r = call <2 x i128> @llvm.umin.v2i128(<2 x i128> %again,<2 x i128> %b)
 store <2 x i128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <2 x i128> @llvm.umax.v2i128(<2 x i128>,<2 x i128>)
define i64 @pair_vector_saturation_2_5(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %slot = alloca <2 x i128>,align 32
 %a = load <2 x i128>,ptr %ap,align 1
 %b = load <2 x i128>,ptr %bp,align 1
 store <2 x i128> %a,ptr %slot,align 1
 %again = load <2 x i128>,ptr %slot,align 1
 %r = call <2 x i128> @llvm.umax.v2i128(<2 x i128> %again,<2 x i128> %b)
 store <2 x i128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <2 x i128> @llvm.smin.v2i128(<2 x i128>,<2 x i128>)
define i64 @pair_vector_saturation_2_6(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %slot = alloca <2 x i128>,align 32
 %a = load <2 x i128>,ptr %ap,align 1
 %b = load <2 x i128>,ptr %bp,align 1
 store <2 x i128> %a,ptr %slot,align 1
 %again = load <2 x i128>,ptr %slot,align 1
 %r = call <2 x i128> @llvm.smin.v2i128(<2 x i128> %again,<2 x i128> %b)
 store <2 x i128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <2 x i128> @llvm.smax.v2i128(<2 x i128>,<2 x i128>)
define i64 @pair_vector_saturation_2_7(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %slot = alloca <2 x i128>,align 32
 %a = load <2 x i128>,ptr %ap,align 1
 %b = load <2 x i128>,ptr %bp,align 1
 store <2 x i128> %a,ptr %slot,align 1
 %again = load <2 x i128>,ptr %slot,align 1
 %r = call <2 x i128> @llvm.smax.v2i128(<2 x i128> %again,<2 x i128> %b)
 store <2 x i128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <3 x i128> @llvm.uadd.sat.v3i128(<3 x i128>,<3 x i128>)
define i64 @pair_vector_saturation_3_0(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %slot = alloca <3 x i128>,align 64
 %a = load <3 x i128>,ptr %ap,align 1
 %b = load <3 x i128>,ptr %bp,align 1
 store <3 x i128> %a,ptr %slot,align 1
 %again = load <3 x i128>,ptr %slot,align 1
 %r = call <3 x i128> @llvm.uadd.sat.v3i128(<3 x i128> %again,<3 x i128> %b)
 store <3 x i128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <3 x i128> @llvm.usub.sat.v3i128(<3 x i128>,<3 x i128>)
define i64 @pair_vector_saturation_3_1(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %slot = alloca <3 x i128>,align 64
 %a = load <3 x i128>,ptr %ap,align 1
 %b = load <3 x i128>,ptr %bp,align 1
 store <3 x i128> %a,ptr %slot,align 1
 %again = load <3 x i128>,ptr %slot,align 1
 %r = call <3 x i128> @llvm.usub.sat.v3i128(<3 x i128> %again,<3 x i128> %b)
 store <3 x i128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <3 x i128> @llvm.sadd.sat.v3i128(<3 x i128>,<3 x i128>)
define i64 @pair_vector_saturation_3_2(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %slot = alloca <3 x i128>,align 64
 %a = load <3 x i128>,ptr %ap,align 1
 %b = load <3 x i128>,ptr %bp,align 1
 store <3 x i128> %a,ptr %slot,align 1
 %again = load <3 x i128>,ptr %slot,align 1
 %r = call <3 x i128> @llvm.sadd.sat.v3i128(<3 x i128> %again,<3 x i128> %b)
 store <3 x i128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <3 x i128> @llvm.ssub.sat.v3i128(<3 x i128>,<3 x i128>)
define i64 @pair_vector_saturation_3_3(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %slot = alloca <3 x i128>,align 64
 %a = load <3 x i128>,ptr %ap,align 1
 %b = load <3 x i128>,ptr %bp,align 1
 store <3 x i128> %a,ptr %slot,align 1
 %again = load <3 x i128>,ptr %slot,align 1
 %r = call <3 x i128> @llvm.ssub.sat.v3i128(<3 x i128> %again,<3 x i128> %b)
 store <3 x i128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <3 x i128> @llvm.umin.v3i128(<3 x i128>,<3 x i128>)
define i64 @pair_vector_saturation_3_4(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %slot = alloca <3 x i128>,align 64
 %a = load <3 x i128>,ptr %ap,align 1
 %b = load <3 x i128>,ptr %bp,align 1
 store <3 x i128> %a,ptr %slot,align 1
 %again = load <3 x i128>,ptr %slot,align 1
 %r = call <3 x i128> @llvm.umin.v3i128(<3 x i128> %again,<3 x i128> %b)
 store <3 x i128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <3 x i128> @llvm.umax.v3i128(<3 x i128>,<3 x i128>)
define i64 @pair_vector_saturation_3_5(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %slot = alloca <3 x i128>,align 64
 %a = load <3 x i128>,ptr %ap,align 1
 %b = load <3 x i128>,ptr %bp,align 1
 store <3 x i128> %a,ptr %slot,align 1
 %again = load <3 x i128>,ptr %slot,align 1
 %r = call <3 x i128> @llvm.umax.v3i128(<3 x i128> %again,<3 x i128> %b)
 store <3 x i128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <3 x i128> @llvm.smin.v3i128(<3 x i128>,<3 x i128>)
define i64 @pair_vector_saturation_3_6(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %slot = alloca <3 x i128>,align 64
 %a = load <3 x i128>,ptr %ap,align 1
 %b = load <3 x i128>,ptr %bp,align 1
 store <3 x i128> %a,ptr %slot,align 1
 %again = load <3 x i128>,ptr %slot,align 1
 %r = call <3 x i128> @llvm.smin.v3i128(<3 x i128> %again,<3 x i128> %b)
 store <3 x i128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <3 x i128> @llvm.smax.v3i128(<3 x i128>,<3 x i128>)
define i64 @pair_vector_saturation_3_7(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %slot = alloca <3 x i128>,align 64
 %a = load <3 x i128>,ptr %ap,align 1
 %b = load <3 x i128>,ptr %bp,align 1
 store <3 x i128> %a,ptr %slot,align 1
 %again = load <3 x i128>,ptr %slot,align 1
 %r = call <3 x i128> @llvm.smax.v3i128(<3 x i128> %again,<3 x i128> %b)
 store <3 x i128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <4 x i128> @llvm.uadd.sat.v4i128(<4 x i128>,<4 x i128>)
define i64 @pair_vector_saturation_4_0(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %slot = alloca <4 x i128>,align 64
 %a = load <4 x i128>,ptr %ap,align 1
 %b = load <4 x i128>,ptr %bp,align 1
 store <4 x i128> %a,ptr %slot,align 1
 %again = load <4 x i128>,ptr %slot,align 1
 %r = call <4 x i128> @llvm.uadd.sat.v4i128(<4 x i128> %again,<4 x i128> %b)
 store <4 x i128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <4 x i128> @llvm.usub.sat.v4i128(<4 x i128>,<4 x i128>)
define i64 @pair_vector_saturation_4_1(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %slot = alloca <4 x i128>,align 64
 %a = load <4 x i128>,ptr %ap,align 1
 %b = load <4 x i128>,ptr %bp,align 1
 store <4 x i128> %a,ptr %slot,align 1
 %again = load <4 x i128>,ptr %slot,align 1
 %r = call <4 x i128> @llvm.usub.sat.v4i128(<4 x i128> %again,<4 x i128> %b)
 store <4 x i128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <4 x i128> @llvm.sadd.sat.v4i128(<4 x i128>,<4 x i128>)
define i64 @pair_vector_saturation_4_2(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %slot = alloca <4 x i128>,align 64
 %a = load <4 x i128>,ptr %ap,align 1
 %b = load <4 x i128>,ptr %bp,align 1
 store <4 x i128> %a,ptr %slot,align 1
 %again = load <4 x i128>,ptr %slot,align 1
 %r = call <4 x i128> @llvm.sadd.sat.v4i128(<4 x i128> %again,<4 x i128> %b)
 store <4 x i128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <4 x i128> @llvm.ssub.sat.v4i128(<4 x i128>,<4 x i128>)
define i64 @pair_vector_saturation_4_3(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %slot = alloca <4 x i128>,align 64
 %a = load <4 x i128>,ptr %ap,align 1
 %b = load <4 x i128>,ptr %bp,align 1
 store <4 x i128> %a,ptr %slot,align 1
 %again = load <4 x i128>,ptr %slot,align 1
 %r = call <4 x i128> @llvm.ssub.sat.v4i128(<4 x i128> %again,<4 x i128> %b)
 store <4 x i128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <4 x i128> @llvm.umin.v4i128(<4 x i128>,<4 x i128>)
define i64 @pair_vector_saturation_4_4(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %slot = alloca <4 x i128>,align 64
 %a = load <4 x i128>,ptr %ap,align 1
 %b = load <4 x i128>,ptr %bp,align 1
 store <4 x i128> %a,ptr %slot,align 1
 %again = load <4 x i128>,ptr %slot,align 1
 %r = call <4 x i128> @llvm.umin.v4i128(<4 x i128> %again,<4 x i128> %b)
 store <4 x i128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <4 x i128> @llvm.umax.v4i128(<4 x i128>,<4 x i128>)
define i64 @pair_vector_saturation_4_5(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %slot = alloca <4 x i128>,align 64
 %a = load <4 x i128>,ptr %ap,align 1
 %b = load <4 x i128>,ptr %bp,align 1
 store <4 x i128> %a,ptr %slot,align 1
 %again = load <4 x i128>,ptr %slot,align 1
 %r = call <4 x i128> @llvm.umax.v4i128(<4 x i128> %again,<4 x i128> %b)
 store <4 x i128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <4 x i128> @llvm.smin.v4i128(<4 x i128>,<4 x i128>)
define i64 @pair_vector_saturation_4_6(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %slot = alloca <4 x i128>,align 64
 %a = load <4 x i128>,ptr %ap,align 1
 %b = load <4 x i128>,ptr %bp,align 1
 store <4 x i128> %a,ptr %slot,align 1
 %again = load <4 x i128>,ptr %slot,align 1
 %r = call <4 x i128> @llvm.smin.v4i128(<4 x i128> %again,<4 x i128> %b)
 store <4 x i128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <4 x i128> @llvm.smax.v4i128(<4 x i128>,<4 x i128>)
define i64 @pair_vector_saturation_4_7(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %slot = alloca <4 x i128>,align 64
 %a = load <4 x i128>,ptr %ap,align 1
 %b = load <4 x i128>,ptr %bp,align 1
 store <4 x i128> %a,ptr %slot,align 1
 %again = load <4 x i128>,ptr %slot,align 1
 %r = call <4 x i128> @llvm.smax.v4i128(<4 x i128> %again,<4 x i128> %b)
 store <4 x i128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <8 x i128> @llvm.uadd.sat.v8i128(<8 x i128>,<8 x i128>)
define i64 @pair_vector_saturation_8_0(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %slot = alloca <8 x i128>,align 128
 %a = load <8 x i128>,ptr %ap,align 1
 %b = load <8 x i128>,ptr %bp,align 1
 store <8 x i128> %a,ptr %slot,align 1
 %again = load <8 x i128>,ptr %slot,align 1
 %r = call <8 x i128> @llvm.uadd.sat.v8i128(<8 x i128> %again,<8 x i128> %b)
 store <8 x i128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <8 x i128> @llvm.usub.sat.v8i128(<8 x i128>,<8 x i128>)
define i64 @pair_vector_saturation_8_1(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %slot = alloca <8 x i128>,align 128
 %a = load <8 x i128>,ptr %ap,align 1
 %b = load <8 x i128>,ptr %bp,align 1
 store <8 x i128> %a,ptr %slot,align 1
 %again = load <8 x i128>,ptr %slot,align 1
 %r = call <8 x i128> @llvm.usub.sat.v8i128(<8 x i128> %again,<8 x i128> %b)
 store <8 x i128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <8 x i128> @llvm.sadd.sat.v8i128(<8 x i128>,<8 x i128>)
define i64 @pair_vector_saturation_8_2(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %slot = alloca <8 x i128>,align 128
 %a = load <8 x i128>,ptr %ap,align 1
 %b = load <8 x i128>,ptr %bp,align 1
 store <8 x i128> %a,ptr %slot,align 1
 %again = load <8 x i128>,ptr %slot,align 1
 %r = call <8 x i128> @llvm.sadd.sat.v8i128(<8 x i128> %again,<8 x i128> %b)
 store <8 x i128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <8 x i128> @llvm.ssub.sat.v8i128(<8 x i128>,<8 x i128>)
define i64 @pair_vector_saturation_8_3(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %slot = alloca <8 x i128>,align 128
 %a = load <8 x i128>,ptr %ap,align 1
 %b = load <8 x i128>,ptr %bp,align 1
 store <8 x i128> %a,ptr %slot,align 1
 %again = load <8 x i128>,ptr %slot,align 1
 %r = call <8 x i128> @llvm.ssub.sat.v8i128(<8 x i128> %again,<8 x i128> %b)
 store <8 x i128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <8 x i128> @llvm.umin.v8i128(<8 x i128>,<8 x i128>)
define i64 @pair_vector_saturation_8_4(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %slot = alloca <8 x i128>,align 128
 %a = load <8 x i128>,ptr %ap,align 1
 %b = load <8 x i128>,ptr %bp,align 1
 store <8 x i128> %a,ptr %slot,align 1
 %again = load <8 x i128>,ptr %slot,align 1
 %r = call <8 x i128> @llvm.umin.v8i128(<8 x i128> %again,<8 x i128> %b)
 store <8 x i128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <8 x i128> @llvm.umax.v8i128(<8 x i128>,<8 x i128>)
define i64 @pair_vector_saturation_8_5(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %slot = alloca <8 x i128>,align 128
 %a = load <8 x i128>,ptr %ap,align 1
 %b = load <8 x i128>,ptr %bp,align 1
 store <8 x i128> %a,ptr %slot,align 1
 %again = load <8 x i128>,ptr %slot,align 1
 %r = call <8 x i128> @llvm.umax.v8i128(<8 x i128> %again,<8 x i128> %b)
 store <8 x i128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <8 x i128> @llvm.smin.v8i128(<8 x i128>,<8 x i128>)
define i64 @pair_vector_saturation_8_6(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %slot = alloca <8 x i128>,align 128
 %a = load <8 x i128>,ptr %ap,align 1
 %b = load <8 x i128>,ptr %bp,align 1
 store <8 x i128> %a,ptr %slot,align 1
 %again = load <8 x i128>,ptr %slot,align 1
 %r = call <8 x i128> @llvm.smin.v8i128(<8 x i128> %again,<8 x i128> %b)
 store <8 x i128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <8 x i128> @llvm.smax.v8i128(<8 x i128>,<8 x i128>)
define i64 @pair_vector_saturation_8_7(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %slot = alloca <8 x i128>,align 128
 %a = load <8 x i128>,ptr %ap,align 1
 %b = load <8 x i128>,ptr %bp,align 1
 store <8 x i128> %a,ptr %slot,align 1
 %again = load <8 x i128>,ptr %slot,align 1
 %r = call <8 x i128> @llvm.smax.v8i128(<8 x i128> %again,<8 x i128> %b)
 store <8 x i128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <16 x i128> @llvm.uadd.sat.v16i128(<16 x i128>,<16 x i128>)
define i64 @pair_vector_saturation_16_0(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %slot = alloca <16 x i128>,align 256
 %a = load <16 x i128>,ptr %ap,align 1
 %b = load <16 x i128>,ptr %bp,align 1
 store <16 x i128> %a,ptr %slot,align 1
 %again = load <16 x i128>,ptr %slot,align 1
 %r = call <16 x i128> @llvm.uadd.sat.v16i128(<16 x i128> %again,<16 x i128> %b)
 store <16 x i128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <16 x i128> @llvm.usub.sat.v16i128(<16 x i128>,<16 x i128>)
define i64 @pair_vector_saturation_16_1(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %slot = alloca <16 x i128>,align 256
 %a = load <16 x i128>,ptr %ap,align 1
 %b = load <16 x i128>,ptr %bp,align 1
 store <16 x i128> %a,ptr %slot,align 1
 %again = load <16 x i128>,ptr %slot,align 1
 %r = call <16 x i128> @llvm.usub.sat.v16i128(<16 x i128> %again,<16 x i128> %b)
 store <16 x i128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <16 x i128> @llvm.sadd.sat.v16i128(<16 x i128>,<16 x i128>)
define i64 @pair_vector_saturation_16_2(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %slot = alloca <16 x i128>,align 256
 %a = load <16 x i128>,ptr %ap,align 1
 %b = load <16 x i128>,ptr %bp,align 1
 store <16 x i128> %a,ptr %slot,align 1
 %again = load <16 x i128>,ptr %slot,align 1
 %r = call <16 x i128> @llvm.sadd.sat.v16i128(<16 x i128> %again,<16 x i128> %b)
 store <16 x i128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <16 x i128> @llvm.ssub.sat.v16i128(<16 x i128>,<16 x i128>)
define i64 @pair_vector_saturation_16_3(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %slot = alloca <16 x i128>,align 256
 %a = load <16 x i128>,ptr %ap,align 1
 %b = load <16 x i128>,ptr %bp,align 1
 store <16 x i128> %a,ptr %slot,align 1
 %again = load <16 x i128>,ptr %slot,align 1
 %r = call <16 x i128> @llvm.ssub.sat.v16i128(<16 x i128> %again,<16 x i128> %b)
 store <16 x i128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <16 x i128> @llvm.umin.v16i128(<16 x i128>,<16 x i128>)
define i64 @pair_vector_saturation_16_4(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %slot = alloca <16 x i128>,align 256
 %a = load <16 x i128>,ptr %ap,align 1
 %b = load <16 x i128>,ptr %bp,align 1
 store <16 x i128> %a,ptr %slot,align 1
 %again = load <16 x i128>,ptr %slot,align 1
 %r = call <16 x i128> @llvm.umin.v16i128(<16 x i128> %again,<16 x i128> %b)
 store <16 x i128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <16 x i128> @llvm.umax.v16i128(<16 x i128>,<16 x i128>)
define i64 @pair_vector_saturation_16_5(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %slot = alloca <16 x i128>,align 256
 %a = load <16 x i128>,ptr %ap,align 1
 %b = load <16 x i128>,ptr %bp,align 1
 store <16 x i128> %a,ptr %slot,align 1
 %again = load <16 x i128>,ptr %slot,align 1
 %r = call <16 x i128> @llvm.umax.v16i128(<16 x i128> %again,<16 x i128> %b)
 store <16 x i128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <16 x i128> @llvm.smin.v16i128(<16 x i128>,<16 x i128>)
define i64 @pair_vector_saturation_16_6(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %slot = alloca <16 x i128>,align 256
 %a = load <16 x i128>,ptr %ap,align 1
 %b = load <16 x i128>,ptr %bp,align 1
 store <16 x i128> %a,ptr %slot,align 1
 %again = load <16 x i128>,ptr %slot,align 1
 %r = call <16 x i128> @llvm.smin.v16i128(<16 x i128> %again,<16 x i128> %b)
 store <16 x i128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <16 x i128> @llvm.smax.v16i128(<16 x i128>,<16 x i128>)
define i64 @pair_vector_saturation_16_7(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %slot = alloca <16 x i128>,align 256
 %a = load <16 x i128>,ptr %ap,align 1
 %b = load <16 x i128>,ptr %bp,align 1
 store <16 x i128> %a,ptr %slot,align 1
 %again = load <16 x i128>,ptr %slot,align 1
 %r = call <16 x i128> @llvm.smax.v16i128(<16 x i128> %again,<16 x i128> %b)
 store <16 x i128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <32 x i128> @llvm.uadd.sat.v32i128(<32 x i128>,<32 x i128>)
define i64 @pair_vector_saturation_32_0(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %slot = alloca <32 x i128>,align 512
 %a = load <32 x i128>,ptr %ap,align 1
 %b = load <32 x i128>,ptr %bp,align 1
 store <32 x i128> %a,ptr %slot,align 1
 %again = load <32 x i128>,ptr %slot,align 1
 %r = call <32 x i128> @llvm.uadd.sat.v32i128(<32 x i128> %again,<32 x i128> %b)
 store <32 x i128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <32 x i128> @llvm.usub.sat.v32i128(<32 x i128>,<32 x i128>)
define i64 @pair_vector_saturation_32_1(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %slot = alloca <32 x i128>,align 512
 %a = load <32 x i128>,ptr %ap,align 1
 %b = load <32 x i128>,ptr %bp,align 1
 store <32 x i128> %a,ptr %slot,align 1
 %again = load <32 x i128>,ptr %slot,align 1
 %r = call <32 x i128> @llvm.usub.sat.v32i128(<32 x i128> %again,<32 x i128> %b)
 store <32 x i128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <32 x i128> @llvm.sadd.sat.v32i128(<32 x i128>,<32 x i128>)
define i64 @pair_vector_saturation_32_2(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %slot = alloca <32 x i128>,align 512
 %a = load <32 x i128>,ptr %ap,align 1
 %b = load <32 x i128>,ptr %bp,align 1
 store <32 x i128> %a,ptr %slot,align 1
 %again = load <32 x i128>,ptr %slot,align 1
 %r = call <32 x i128> @llvm.sadd.sat.v32i128(<32 x i128> %again,<32 x i128> %b)
 store <32 x i128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <32 x i128> @llvm.ssub.sat.v32i128(<32 x i128>,<32 x i128>)
define i64 @pair_vector_saturation_32_3(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %slot = alloca <32 x i128>,align 512
 %a = load <32 x i128>,ptr %ap,align 1
 %b = load <32 x i128>,ptr %bp,align 1
 store <32 x i128> %a,ptr %slot,align 1
 %again = load <32 x i128>,ptr %slot,align 1
 %r = call <32 x i128> @llvm.ssub.sat.v32i128(<32 x i128> %again,<32 x i128> %b)
 store <32 x i128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <32 x i128> @llvm.umin.v32i128(<32 x i128>,<32 x i128>)
define i64 @pair_vector_saturation_32_4(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %slot = alloca <32 x i128>,align 512
 %a = load <32 x i128>,ptr %ap,align 1
 %b = load <32 x i128>,ptr %bp,align 1
 store <32 x i128> %a,ptr %slot,align 1
 %again = load <32 x i128>,ptr %slot,align 1
 %r = call <32 x i128> @llvm.umin.v32i128(<32 x i128> %again,<32 x i128> %b)
 store <32 x i128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <32 x i128> @llvm.umax.v32i128(<32 x i128>,<32 x i128>)
define i64 @pair_vector_saturation_32_5(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %slot = alloca <32 x i128>,align 512
 %a = load <32 x i128>,ptr %ap,align 1
 %b = load <32 x i128>,ptr %bp,align 1
 store <32 x i128> %a,ptr %slot,align 1
 %again = load <32 x i128>,ptr %slot,align 1
 %r = call <32 x i128> @llvm.umax.v32i128(<32 x i128> %again,<32 x i128> %b)
 store <32 x i128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <32 x i128> @llvm.smin.v32i128(<32 x i128>,<32 x i128>)
define i64 @pair_vector_saturation_32_6(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %slot = alloca <32 x i128>,align 512
 %a = load <32 x i128>,ptr %ap,align 1
 %b = load <32 x i128>,ptr %bp,align 1
 store <32 x i128> %a,ptr %slot,align 1
 %again = load <32 x i128>,ptr %slot,align 1
 %r = call <32 x i128> @llvm.smin.v32i128(<32 x i128> %again,<32 x i128> %b)
 store <32 x i128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <32 x i128> @llvm.smax.v32i128(<32 x i128>,<32 x i128>)
define i64 @pair_vector_saturation_32_7(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %slot = alloca <32 x i128>,align 512
 %a = load <32 x i128>,ptr %ap,align 1
 %b = load <32 x i128>,ptr %bp,align 1
 store <32 x i128> %a,ptr %slot,align 1
 %again = load <32 x i128>,ptr %slot,align 1
 %r = call <32 x i128> @llvm.smax.v32i128(<32 x i128> %again,<32 x i128> %b)
 store <32 x i128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
