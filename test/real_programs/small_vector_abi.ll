target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
declare <2 x i8> @small_peer_c_2_8(<2 x i8>,i64,<2 x i8>)
define <2 x i8> @small_add_c_2_8(ptr %out,<2 x i8> %a,i64 %live,<2 x i8> %b) #0 {
entry:
 %v = add <2 x i8> %a,%b
 %slot = getelementptr i8,ptr %out,i64 8
 store i64 %live,ptr %slot,align 1
 ret <2 x i8> %v
}
define i64 @small_relay_c_2_8(ptr %out,ptr %xp,ptr %yp,i64 %live) {
entry:
 %x = load <2 x i8>,ptr %xp,align 1
 %y = load <2 x i8>,ptr %yp,align 1
 %v = call <2 x i8> @small_peer_c_2_8(<2 x i8> %x,i64 %live,<2 x i8> %y)
 store <2 x i8> %v,ptr %out,align 1
 %slot = getelementptr i8,ptr %out,i64 8
 store i64 %live,ptr %slot,align 1
 %answer = xor i64 %live,123
 ret i64 %answer
}
define <2 x i8> @small_eight_c_2_8(ptr %out,<2 x i8> %a0,<2 x i8> %a1,<2 x i8> %a2,<2 x i8> %a3,<2 x i8> %a4,<2 x i8> %a5,<2 x i8> %a6,<2 x i8> %a7,i64 %live) #0 {
entry:
 %s1 = add <2 x i8> %a0,%a1
 %s2 = add <2 x i8> %s1,%a2
 %s3 = add <2 x i8> %s2,%a3
 %s4 = add <2 x i8> %s3,%a4
 %s5 = add <2 x i8> %s4,%a5
 %s6 = add <2 x i8> %s5,%a6
 %s7 = add <2 x i8> %s6,%a7
 %slot = getelementptr i8,ptr %out,i64 8
 store i64 %live,ptr %slot,align 1
 ret <2 x i8> %s7
}
declare <4 x i8> @small_peer_c_4_8(<4 x i8>,i64,<4 x i8>)
define <4 x i8> @small_add_c_4_8(ptr %out,<4 x i8> %a,i64 %live,<4 x i8> %b) #0 {
entry:
 %v = add <4 x i8> %a,%b
 %slot = getelementptr i8,ptr %out,i64 8
 store i64 %live,ptr %slot,align 1
 ret <4 x i8> %v
}
define i64 @small_relay_c_4_8(ptr %out,ptr %xp,ptr %yp,i64 %live) {
entry:
 %x = load <4 x i8>,ptr %xp,align 1
 %y = load <4 x i8>,ptr %yp,align 1
 %v = call <4 x i8> @small_peer_c_4_8(<4 x i8> %x,i64 %live,<4 x i8> %y)
 store <4 x i8> %v,ptr %out,align 1
 %slot = getelementptr i8,ptr %out,i64 8
 store i64 %live,ptr %slot,align 1
 %answer = xor i64 %live,123
 ret i64 %answer
}
define <4 x i8> @small_eight_c_4_8(ptr %out,<4 x i8> %a0,<4 x i8> %a1,<4 x i8> %a2,<4 x i8> %a3,<4 x i8> %a4,<4 x i8> %a5,<4 x i8> %a6,<4 x i8> %a7,i64 %live) #0 {
entry:
 %s1 = add <4 x i8> %a0,%a1
 %s2 = add <4 x i8> %s1,%a2
 %s3 = add <4 x i8> %s2,%a3
 %s4 = add <4 x i8> %s3,%a4
 %s5 = add <4 x i8> %s4,%a5
 %s6 = add <4 x i8> %s5,%a6
 %s7 = add <4 x i8> %s6,%a7
 %slot = getelementptr i8,ptr %out,i64 8
 store i64 %live,ptr %slot,align 1
 ret <4 x i8> %s7
}
declare <8 x i8> @small_peer_c_8_8(<8 x i8>,i64,<8 x i8>)
define <8 x i8> @small_add_c_8_8(ptr %out,<8 x i8> %a,i64 %live,<8 x i8> %b) #0 {
entry:
 %v = add <8 x i8> %a,%b
 %slot = getelementptr i8,ptr %out,i64 8
 store i64 %live,ptr %slot,align 1
 ret <8 x i8> %v
}
define i64 @small_relay_c_8_8(ptr %out,ptr %xp,ptr %yp,i64 %live) {
entry:
 %x = load <8 x i8>,ptr %xp,align 1
 %y = load <8 x i8>,ptr %yp,align 1
 %v = call <8 x i8> @small_peer_c_8_8(<8 x i8> %x,i64 %live,<8 x i8> %y)
 store <8 x i8> %v,ptr %out,align 1
 %slot = getelementptr i8,ptr %out,i64 8
 store i64 %live,ptr %slot,align 1
 %answer = xor i64 %live,123
 ret i64 %answer
}
define <8 x i8> @small_eight_c_8_8(ptr %out,<8 x i8> %a0,<8 x i8> %a1,<8 x i8> %a2,<8 x i8> %a3,<8 x i8> %a4,<8 x i8> %a5,<8 x i8> %a6,<8 x i8> %a7,i64 %live) #0 {
entry:
 %s1 = add <8 x i8> %a0,%a1
 %s2 = add <8 x i8> %s1,%a2
 %s3 = add <8 x i8> %s2,%a3
 %s4 = add <8 x i8> %s3,%a4
 %s5 = add <8 x i8> %s4,%a5
 %s6 = add <8 x i8> %s5,%a6
 %s7 = add <8 x i8> %s6,%a7
 %slot = getelementptr i8,ptr %out,i64 8
 store i64 %live,ptr %slot,align 1
 ret <8 x i8> %s7
}
declare <2 x i16> @small_peer_c_2_16(<2 x i16>,i64,<2 x i16>)
define <2 x i16> @small_add_c_2_16(ptr %out,<2 x i16> %a,i64 %live,<2 x i16> %b) #0 {
entry:
 %v = add <2 x i16> %a,%b
 %slot = getelementptr i8,ptr %out,i64 8
 store i64 %live,ptr %slot,align 1
 ret <2 x i16> %v
}
define i64 @small_relay_c_2_16(ptr %out,ptr %xp,ptr %yp,i64 %live) {
entry:
 %x = load <2 x i16>,ptr %xp,align 1
 %y = load <2 x i16>,ptr %yp,align 1
 %v = call <2 x i16> @small_peer_c_2_16(<2 x i16> %x,i64 %live,<2 x i16> %y)
 store <2 x i16> %v,ptr %out,align 1
 %slot = getelementptr i8,ptr %out,i64 8
 store i64 %live,ptr %slot,align 1
 %answer = xor i64 %live,123
 ret i64 %answer
}
define <2 x i16> @small_eight_c_2_16(ptr %out,<2 x i16> %a0,<2 x i16> %a1,<2 x i16> %a2,<2 x i16> %a3,<2 x i16> %a4,<2 x i16> %a5,<2 x i16> %a6,<2 x i16> %a7,i64 %live) #0 {
entry:
 %s1 = add <2 x i16> %a0,%a1
 %s2 = add <2 x i16> %s1,%a2
 %s3 = add <2 x i16> %s2,%a3
 %s4 = add <2 x i16> %s3,%a4
 %s5 = add <2 x i16> %s4,%a5
 %s6 = add <2 x i16> %s5,%a6
 %s7 = add <2 x i16> %s6,%a7
 %slot = getelementptr i8,ptr %out,i64 8
 store i64 %live,ptr %slot,align 1
 ret <2 x i16> %s7
}
declare <4 x i16> @small_peer_c_4_16(<4 x i16>,i64,<4 x i16>)
define <4 x i16> @small_add_c_4_16(ptr %out,<4 x i16> %a,i64 %live,<4 x i16> %b) #0 {
entry:
 %v = add <4 x i16> %a,%b
 %slot = getelementptr i8,ptr %out,i64 8
 store i64 %live,ptr %slot,align 1
 ret <4 x i16> %v
}
define i64 @small_relay_c_4_16(ptr %out,ptr %xp,ptr %yp,i64 %live) {
entry:
 %x = load <4 x i16>,ptr %xp,align 1
 %y = load <4 x i16>,ptr %yp,align 1
 %v = call <4 x i16> @small_peer_c_4_16(<4 x i16> %x,i64 %live,<4 x i16> %y)
 store <4 x i16> %v,ptr %out,align 1
 %slot = getelementptr i8,ptr %out,i64 8
 store i64 %live,ptr %slot,align 1
 %answer = xor i64 %live,123
 ret i64 %answer
}
define <4 x i16> @small_eight_c_4_16(ptr %out,<4 x i16> %a0,<4 x i16> %a1,<4 x i16> %a2,<4 x i16> %a3,<4 x i16> %a4,<4 x i16> %a5,<4 x i16> %a6,<4 x i16> %a7,i64 %live) #0 {
entry:
 %s1 = add <4 x i16> %a0,%a1
 %s2 = add <4 x i16> %s1,%a2
 %s3 = add <4 x i16> %s2,%a3
 %s4 = add <4 x i16> %s3,%a4
 %s5 = add <4 x i16> %s4,%a5
 %s6 = add <4 x i16> %s5,%a6
 %s7 = add <4 x i16> %s6,%a7
 %slot = getelementptr i8,ptr %out,i64 8
 store i64 %live,ptr %slot,align 1
 ret <4 x i16> %s7
}
declare <2 x i32> @small_peer_c_2_32(<2 x i32>,i64,<2 x i32>)
define <2 x i32> @small_add_c_2_32(ptr %out,<2 x i32> %a,i64 %live,<2 x i32> %b) #0 {
entry:
 %v = add <2 x i32> %a,%b
 %slot = getelementptr i8,ptr %out,i64 8
 store i64 %live,ptr %slot,align 1
 ret <2 x i32> %v
}
define i64 @small_relay_c_2_32(ptr %out,ptr %xp,ptr %yp,i64 %live) {
entry:
 %x = load <2 x i32>,ptr %xp,align 1
 %y = load <2 x i32>,ptr %yp,align 1
 %v = call <2 x i32> @small_peer_c_2_32(<2 x i32> %x,i64 %live,<2 x i32> %y)
 store <2 x i32> %v,ptr %out,align 1
 %slot = getelementptr i8,ptr %out,i64 8
 store i64 %live,ptr %slot,align 1
 %answer = xor i64 %live,123
 ret i64 %answer
}
define <2 x i32> @small_eight_c_2_32(ptr %out,<2 x i32> %a0,<2 x i32> %a1,<2 x i32> %a2,<2 x i32> %a3,<2 x i32> %a4,<2 x i32> %a5,<2 x i32> %a6,<2 x i32> %a7,i64 %live) #0 {
entry:
 %s1 = add <2 x i32> %a0,%a1
 %s2 = add <2 x i32> %s1,%a2
 %s3 = add <2 x i32> %s2,%a3
 %s4 = add <2 x i32> %s3,%a4
 %s5 = add <2 x i32> %s4,%a5
 %s6 = add <2 x i32> %s5,%a6
 %s7 = add <2 x i32> %s6,%a7
 %slot = getelementptr i8,ptr %out,i64 8
 store i64 %live,ptr %slot,align 1
 ret <2 x i32> %s7
}
declare fastcc <2 x i8> @small_peer_fast_2_8(<2 x i8>,i64,<2 x i8>)
define fastcc <2 x i8> @small_add_fast_2_8(ptr %out,<2 x i8> %a,i64 %live,<2 x i8> %b) #0 {
entry:
 %v = add <2 x i8> %a,%b
 %slot = getelementptr i8,ptr %out,i64 8
 store i64 %live,ptr %slot,align 1
 ret <2 x i8> %v
}
define i64 @small_relay_fast_2_8(ptr %out,ptr %xp,ptr %yp,i64 %live) {
entry:
 %x = load <2 x i8>,ptr %xp,align 1
 %y = load <2 x i8>,ptr %yp,align 1
 %v = call fastcc <2 x i8> @small_peer_fast_2_8(<2 x i8> %x,i64 %live,<2 x i8> %y)
 store <2 x i8> %v,ptr %out,align 1
 %slot = getelementptr i8,ptr %out,i64 8
 store i64 %live,ptr %slot,align 1
 %answer = xor i64 %live,123
 ret i64 %answer
}
define fastcc <2 x i8> @small_eight_fast_2_8(ptr %out,<2 x i8> %a0,<2 x i8> %a1,<2 x i8> %a2,<2 x i8> %a3,<2 x i8> %a4,<2 x i8> %a5,<2 x i8> %a6,<2 x i8> %a7,i64 %live) #0 {
entry:
 %s1 = add <2 x i8> %a0,%a1
 %s2 = add <2 x i8> %s1,%a2
 %s3 = add <2 x i8> %s2,%a3
 %s4 = add <2 x i8> %s3,%a4
 %s5 = add <2 x i8> %s4,%a5
 %s6 = add <2 x i8> %s5,%a6
 %s7 = add <2 x i8> %s6,%a7
 %slot = getelementptr i8,ptr %out,i64 8
 store i64 %live,ptr %slot,align 1
 ret <2 x i8> %s7
}
declare fastcc <4 x i8> @small_peer_fast_4_8(<4 x i8>,i64,<4 x i8>)
define fastcc <4 x i8> @small_add_fast_4_8(ptr %out,<4 x i8> %a,i64 %live,<4 x i8> %b) #0 {
entry:
 %v = add <4 x i8> %a,%b
 %slot = getelementptr i8,ptr %out,i64 8
 store i64 %live,ptr %slot,align 1
 ret <4 x i8> %v
}
define i64 @small_relay_fast_4_8(ptr %out,ptr %xp,ptr %yp,i64 %live) {
entry:
 %x = load <4 x i8>,ptr %xp,align 1
 %y = load <4 x i8>,ptr %yp,align 1
 %v = call fastcc <4 x i8> @small_peer_fast_4_8(<4 x i8> %x,i64 %live,<4 x i8> %y)
 store <4 x i8> %v,ptr %out,align 1
 %slot = getelementptr i8,ptr %out,i64 8
 store i64 %live,ptr %slot,align 1
 %answer = xor i64 %live,123
 ret i64 %answer
}
define fastcc <4 x i8> @small_eight_fast_4_8(ptr %out,<4 x i8> %a0,<4 x i8> %a1,<4 x i8> %a2,<4 x i8> %a3,<4 x i8> %a4,<4 x i8> %a5,<4 x i8> %a6,<4 x i8> %a7,i64 %live) #0 {
entry:
 %s1 = add <4 x i8> %a0,%a1
 %s2 = add <4 x i8> %s1,%a2
 %s3 = add <4 x i8> %s2,%a3
 %s4 = add <4 x i8> %s3,%a4
 %s5 = add <4 x i8> %s4,%a5
 %s6 = add <4 x i8> %s5,%a6
 %s7 = add <4 x i8> %s6,%a7
 %slot = getelementptr i8,ptr %out,i64 8
 store i64 %live,ptr %slot,align 1
 ret <4 x i8> %s7
}
declare fastcc <8 x i8> @small_peer_fast_8_8(<8 x i8>,i64,<8 x i8>)
define fastcc <8 x i8> @small_add_fast_8_8(ptr %out,<8 x i8> %a,i64 %live,<8 x i8> %b) #0 {
entry:
 %v = add <8 x i8> %a,%b
 %slot = getelementptr i8,ptr %out,i64 8
 store i64 %live,ptr %slot,align 1
 ret <8 x i8> %v
}
define i64 @small_relay_fast_8_8(ptr %out,ptr %xp,ptr %yp,i64 %live) {
entry:
 %x = load <8 x i8>,ptr %xp,align 1
 %y = load <8 x i8>,ptr %yp,align 1
 %v = call fastcc <8 x i8> @small_peer_fast_8_8(<8 x i8> %x,i64 %live,<8 x i8> %y)
 store <8 x i8> %v,ptr %out,align 1
 %slot = getelementptr i8,ptr %out,i64 8
 store i64 %live,ptr %slot,align 1
 %answer = xor i64 %live,123
 ret i64 %answer
}
define fastcc <8 x i8> @small_eight_fast_8_8(ptr %out,<8 x i8> %a0,<8 x i8> %a1,<8 x i8> %a2,<8 x i8> %a3,<8 x i8> %a4,<8 x i8> %a5,<8 x i8> %a6,<8 x i8> %a7,i64 %live) #0 {
entry:
 %s1 = add <8 x i8> %a0,%a1
 %s2 = add <8 x i8> %s1,%a2
 %s3 = add <8 x i8> %s2,%a3
 %s4 = add <8 x i8> %s3,%a4
 %s5 = add <8 x i8> %s4,%a5
 %s6 = add <8 x i8> %s5,%a6
 %s7 = add <8 x i8> %s6,%a7
 %slot = getelementptr i8,ptr %out,i64 8
 store i64 %live,ptr %slot,align 1
 ret <8 x i8> %s7
}
declare fastcc <2 x i16> @small_peer_fast_2_16(<2 x i16>,i64,<2 x i16>)
define fastcc <2 x i16> @small_add_fast_2_16(ptr %out,<2 x i16> %a,i64 %live,<2 x i16> %b) #0 {
entry:
 %v = add <2 x i16> %a,%b
 %slot = getelementptr i8,ptr %out,i64 8
 store i64 %live,ptr %slot,align 1
 ret <2 x i16> %v
}
define i64 @small_relay_fast_2_16(ptr %out,ptr %xp,ptr %yp,i64 %live) {
entry:
 %x = load <2 x i16>,ptr %xp,align 1
 %y = load <2 x i16>,ptr %yp,align 1
 %v = call fastcc <2 x i16> @small_peer_fast_2_16(<2 x i16> %x,i64 %live,<2 x i16> %y)
 store <2 x i16> %v,ptr %out,align 1
 %slot = getelementptr i8,ptr %out,i64 8
 store i64 %live,ptr %slot,align 1
 %answer = xor i64 %live,123
 ret i64 %answer
}
define fastcc <2 x i16> @small_eight_fast_2_16(ptr %out,<2 x i16> %a0,<2 x i16> %a1,<2 x i16> %a2,<2 x i16> %a3,<2 x i16> %a4,<2 x i16> %a5,<2 x i16> %a6,<2 x i16> %a7,i64 %live) #0 {
entry:
 %s1 = add <2 x i16> %a0,%a1
 %s2 = add <2 x i16> %s1,%a2
 %s3 = add <2 x i16> %s2,%a3
 %s4 = add <2 x i16> %s3,%a4
 %s5 = add <2 x i16> %s4,%a5
 %s6 = add <2 x i16> %s5,%a6
 %s7 = add <2 x i16> %s6,%a7
 %slot = getelementptr i8,ptr %out,i64 8
 store i64 %live,ptr %slot,align 1
 ret <2 x i16> %s7
}
declare fastcc <4 x i16> @small_peer_fast_4_16(<4 x i16>,i64,<4 x i16>)
define fastcc <4 x i16> @small_add_fast_4_16(ptr %out,<4 x i16> %a,i64 %live,<4 x i16> %b) #0 {
entry:
 %v = add <4 x i16> %a,%b
 %slot = getelementptr i8,ptr %out,i64 8
 store i64 %live,ptr %slot,align 1
 ret <4 x i16> %v
}
define i64 @small_relay_fast_4_16(ptr %out,ptr %xp,ptr %yp,i64 %live) {
entry:
 %x = load <4 x i16>,ptr %xp,align 1
 %y = load <4 x i16>,ptr %yp,align 1
 %v = call fastcc <4 x i16> @small_peer_fast_4_16(<4 x i16> %x,i64 %live,<4 x i16> %y)
 store <4 x i16> %v,ptr %out,align 1
 %slot = getelementptr i8,ptr %out,i64 8
 store i64 %live,ptr %slot,align 1
 %answer = xor i64 %live,123
 ret i64 %answer
}
define fastcc <4 x i16> @small_eight_fast_4_16(ptr %out,<4 x i16> %a0,<4 x i16> %a1,<4 x i16> %a2,<4 x i16> %a3,<4 x i16> %a4,<4 x i16> %a5,<4 x i16> %a6,<4 x i16> %a7,i64 %live) #0 {
entry:
 %s1 = add <4 x i16> %a0,%a1
 %s2 = add <4 x i16> %s1,%a2
 %s3 = add <4 x i16> %s2,%a3
 %s4 = add <4 x i16> %s3,%a4
 %s5 = add <4 x i16> %s4,%a5
 %s6 = add <4 x i16> %s5,%a6
 %s7 = add <4 x i16> %s6,%a7
 %slot = getelementptr i8,ptr %out,i64 8
 store i64 %live,ptr %slot,align 1
 ret <4 x i16> %s7
}
declare fastcc <2 x i32> @small_peer_fast_2_32(<2 x i32>,i64,<2 x i32>)
define fastcc <2 x i32> @small_add_fast_2_32(ptr %out,<2 x i32> %a,i64 %live,<2 x i32> %b) #0 {
entry:
 %v = add <2 x i32> %a,%b
 %slot = getelementptr i8,ptr %out,i64 8
 store i64 %live,ptr %slot,align 1
 ret <2 x i32> %v
}
define i64 @small_relay_fast_2_32(ptr %out,ptr %xp,ptr %yp,i64 %live) {
entry:
 %x = load <2 x i32>,ptr %xp,align 1
 %y = load <2 x i32>,ptr %yp,align 1
 %v = call fastcc <2 x i32> @small_peer_fast_2_32(<2 x i32> %x,i64 %live,<2 x i32> %y)
 store <2 x i32> %v,ptr %out,align 1
 %slot = getelementptr i8,ptr %out,i64 8
 store i64 %live,ptr %slot,align 1
 %answer = xor i64 %live,123
 ret i64 %answer
}
define fastcc <2 x i32> @small_eight_fast_2_32(ptr %out,<2 x i32> %a0,<2 x i32> %a1,<2 x i32> %a2,<2 x i32> %a3,<2 x i32> %a4,<2 x i32> %a5,<2 x i32> %a6,<2 x i32> %a7,i64 %live) #0 {
entry:
 %s1 = add <2 x i32> %a0,%a1
 %s2 = add <2 x i32> %s1,%a2
 %s3 = add <2 x i32> %s2,%a3
 %s4 = add <2 x i32> %s3,%a4
 %s5 = add <2 x i32> %s4,%a5
 %s6 = add <2 x i32> %s5,%a6
 %s7 = add <2 x i32> %s6,%a7
 %slot = getelementptr i8,ptr %out,i64 8
 store i64 %live,ptr %slot,align 1
 ret <2 x i32> %s7
}
attributes #0 = { noinline }
