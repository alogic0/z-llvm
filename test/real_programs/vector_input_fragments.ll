target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"
define i64 @vector_input_body_0(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,<32 x i8> %v,i64 %salt) noinline {
entry:
 %s0 = xor i64 %salt,%p0
 %s1 = xor i64 %s0,%p1
 %s2 = xor i64 %s1,%p2
 %s3 = xor i64 %s2,%p3
 %s4 = xor i64 %s3,%p4
 %s5 = xor i64 %s4,%p5
 %lane0 = extractelement <32 x i8> %v,i64 0
 %word0 = zext i8 %lane0 to i64
 %mix0 = mul i64 %s5,1099511628211
 %r0 = xor i64 %mix0,%word0
 %lane1 = extractelement <32 x i8> %v,i64 1
 %word1 = zext i8 %lane1 to i64
 %mix1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %mix1,%word1
 %lane2 = extractelement <32 x i8> %v,i64 2
 %word2 = zext i8 %lane2 to i64
 %mix2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %mix2,%word2
 %lane3 = extractelement <32 x i8> %v,i64 3
 %word3 = zext i8 %lane3 to i64
 %mix3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %mix3,%word3
 %lane4 = extractelement <32 x i8> %v,i64 4
 %word4 = zext i8 %lane4 to i64
 %mix4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %mix4,%word4
 %lane5 = extractelement <32 x i8> %v,i64 5
 %word5 = zext i8 %lane5 to i64
 %mix5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %mix5,%word5
 %lane6 = extractelement <32 x i8> %v,i64 6
 %word6 = zext i8 %lane6 to i64
 %mix6 = mul i64 %r5,1099511628211
 %r6 = xor i64 %mix6,%word6
 %lane7 = extractelement <32 x i8> %v,i64 7
 %word7 = zext i8 %lane7 to i64
 %mix7 = mul i64 %r6,1099511628211
 %r7 = xor i64 %mix7,%word7
 %lane8 = extractelement <32 x i8> %v,i64 8
 %word8 = zext i8 %lane8 to i64
 %mix8 = mul i64 %r7,1099511628211
 %r8 = xor i64 %mix8,%word8
 %lane9 = extractelement <32 x i8> %v,i64 9
 %word9 = zext i8 %lane9 to i64
 %mix9 = mul i64 %r8,1099511628211
 %r9 = xor i64 %mix9,%word9
 %lane10 = extractelement <32 x i8> %v,i64 10
 %word10 = zext i8 %lane10 to i64
 %mix10 = mul i64 %r9,1099511628211
 %r10 = xor i64 %mix10,%word10
 %lane11 = extractelement <32 x i8> %v,i64 11
 %word11 = zext i8 %lane11 to i64
 %mix11 = mul i64 %r10,1099511628211
 %r11 = xor i64 %mix11,%word11
 %lane12 = extractelement <32 x i8> %v,i64 12
 %word12 = zext i8 %lane12 to i64
 %mix12 = mul i64 %r11,1099511628211
 %r12 = xor i64 %mix12,%word12
 %lane13 = extractelement <32 x i8> %v,i64 13
 %word13 = zext i8 %lane13 to i64
 %mix13 = mul i64 %r12,1099511628211
 %r13 = xor i64 %mix13,%word13
 %lane14 = extractelement <32 x i8> %v,i64 14
 %word14 = zext i8 %lane14 to i64
 %mix14 = mul i64 %r13,1099511628211
 %r14 = xor i64 %mix14,%word14
 %lane15 = extractelement <32 x i8> %v,i64 15
 %word15 = zext i8 %lane15 to i64
 %mix15 = mul i64 %r14,1099511628211
 %r15 = xor i64 %mix15,%word15
 %lane16 = extractelement <32 x i8> %v,i64 16
 %word16 = zext i8 %lane16 to i64
 %mix16 = mul i64 %r15,1099511628211
 %r16 = xor i64 %mix16,%word16
 %lane17 = extractelement <32 x i8> %v,i64 17
 %word17 = zext i8 %lane17 to i64
 %mix17 = mul i64 %r16,1099511628211
 %r17 = xor i64 %mix17,%word17
 %lane18 = extractelement <32 x i8> %v,i64 18
 %word18 = zext i8 %lane18 to i64
 %mix18 = mul i64 %r17,1099511628211
 %r18 = xor i64 %mix18,%word18
 %lane19 = extractelement <32 x i8> %v,i64 19
 %word19 = zext i8 %lane19 to i64
 %mix19 = mul i64 %r18,1099511628211
 %r19 = xor i64 %mix19,%word19
 %lane20 = extractelement <32 x i8> %v,i64 20
 %word20 = zext i8 %lane20 to i64
 %mix20 = mul i64 %r19,1099511628211
 %r20 = xor i64 %mix20,%word20
 %lane21 = extractelement <32 x i8> %v,i64 21
 %word21 = zext i8 %lane21 to i64
 %mix21 = mul i64 %r20,1099511628211
 %r21 = xor i64 %mix21,%word21
 %lane22 = extractelement <32 x i8> %v,i64 22
 %word22 = zext i8 %lane22 to i64
 %mix22 = mul i64 %r21,1099511628211
 %r22 = xor i64 %mix22,%word22
 %lane23 = extractelement <32 x i8> %v,i64 23
 %word23 = zext i8 %lane23 to i64
 %mix23 = mul i64 %r22,1099511628211
 %r23 = xor i64 %mix23,%word23
 %lane24 = extractelement <32 x i8> %v,i64 24
 %word24 = zext i8 %lane24 to i64
 %mix24 = mul i64 %r23,1099511628211
 %r24 = xor i64 %mix24,%word24
 %lane25 = extractelement <32 x i8> %v,i64 25
 %word25 = zext i8 %lane25 to i64
 %mix25 = mul i64 %r24,1099511628211
 %r25 = xor i64 %mix25,%word25
 %lane26 = extractelement <32 x i8> %v,i64 26
 %word26 = zext i8 %lane26 to i64
 %mix26 = mul i64 %r25,1099511628211
 %r26 = xor i64 %mix26,%word26
 %lane27 = extractelement <32 x i8> %v,i64 27
 %word27 = zext i8 %lane27 to i64
 %mix27 = mul i64 %r26,1099511628211
 %r27 = xor i64 %mix27,%word27
 %lane28 = extractelement <32 x i8> %v,i64 28
 %word28 = zext i8 %lane28 to i64
 %mix28 = mul i64 %r27,1099511628211
 %r28 = xor i64 %mix28,%word28
 %lane29 = extractelement <32 x i8> %v,i64 29
 %word29 = zext i8 %lane29 to i64
 %mix29 = mul i64 %r28,1099511628211
 %r29 = xor i64 %mix29,%word29
 %lane30 = extractelement <32 x i8> %v,i64 30
 %word30 = zext i8 %lane30 to i64
 %mix30 = mul i64 %r29,1099511628211
 %r30 = xor i64 %mix30,%word30
 %lane31 = extractelement <32 x i8> %v,i64 31
 %word31 = zext i8 %lane31 to i64
 %mix31 = mul i64 %r30,1099511628211
 %r31 = xor i64 %mix31,%word31
 ret i64 %r31
}
declare i64 @vector_input_provider_0(i64,i64,i64,i64,i64,i64,<32 x i8>,i64)
define i64 @vector_input_probe_0(ptr %out,ptr %input,i64 %salt) {
entry:
 %v = load <32 x i8>,ptr %input,align 1
 %local = call i64 @vector_input_body_0(i64 1311768467463790320,i64 18364758544493064720,i64 1234605616436508552,i64 12379552201711258095,i64 9756277981056907928,i64 1161981756646125696,<32 x i8> %v,i64 %salt)
 %external = call i64 @vector_input_provider_0(i64 1311768467463790320,i64 18364758544493064720,i64 1234605616436508552,i64 12379552201711258095,i64 9756277981056907928,i64 1161981756646125696,<32 x i8> %v,i64 %salt)
 store i64 %local,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %external,ptr %next,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc i64 @vector_input_body_1(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,<32 x i8> %v,i64 %salt) noinline {
entry:
 %s0 = xor i64 %salt,%p0
 %s1 = xor i64 %s0,%p1
 %s2 = xor i64 %s1,%p2
 %s3 = xor i64 %s2,%p3
 %s4 = xor i64 %s3,%p4
 %s5 = xor i64 %s4,%p5
 %lane0 = extractelement <32 x i8> %v,i64 0
 %word0 = zext i8 %lane0 to i64
 %mix0 = mul i64 %s5,1099511628211
 %r0 = xor i64 %mix0,%word0
 %lane1 = extractelement <32 x i8> %v,i64 1
 %word1 = zext i8 %lane1 to i64
 %mix1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %mix1,%word1
 %lane2 = extractelement <32 x i8> %v,i64 2
 %word2 = zext i8 %lane2 to i64
 %mix2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %mix2,%word2
 %lane3 = extractelement <32 x i8> %v,i64 3
 %word3 = zext i8 %lane3 to i64
 %mix3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %mix3,%word3
 %lane4 = extractelement <32 x i8> %v,i64 4
 %word4 = zext i8 %lane4 to i64
 %mix4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %mix4,%word4
 %lane5 = extractelement <32 x i8> %v,i64 5
 %word5 = zext i8 %lane5 to i64
 %mix5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %mix5,%word5
 %lane6 = extractelement <32 x i8> %v,i64 6
 %word6 = zext i8 %lane6 to i64
 %mix6 = mul i64 %r5,1099511628211
 %r6 = xor i64 %mix6,%word6
 %lane7 = extractelement <32 x i8> %v,i64 7
 %word7 = zext i8 %lane7 to i64
 %mix7 = mul i64 %r6,1099511628211
 %r7 = xor i64 %mix7,%word7
 %lane8 = extractelement <32 x i8> %v,i64 8
 %word8 = zext i8 %lane8 to i64
 %mix8 = mul i64 %r7,1099511628211
 %r8 = xor i64 %mix8,%word8
 %lane9 = extractelement <32 x i8> %v,i64 9
 %word9 = zext i8 %lane9 to i64
 %mix9 = mul i64 %r8,1099511628211
 %r9 = xor i64 %mix9,%word9
 %lane10 = extractelement <32 x i8> %v,i64 10
 %word10 = zext i8 %lane10 to i64
 %mix10 = mul i64 %r9,1099511628211
 %r10 = xor i64 %mix10,%word10
 %lane11 = extractelement <32 x i8> %v,i64 11
 %word11 = zext i8 %lane11 to i64
 %mix11 = mul i64 %r10,1099511628211
 %r11 = xor i64 %mix11,%word11
 %lane12 = extractelement <32 x i8> %v,i64 12
 %word12 = zext i8 %lane12 to i64
 %mix12 = mul i64 %r11,1099511628211
 %r12 = xor i64 %mix12,%word12
 %lane13 = extractelement <32 x i8> %v,i64 13
 %word13 = zext i8 %lane13 to i64
 %mix13 = mul i64 %r12,1099511628211
 %r13 = xor i64 %mix13,%word13
 %lane14 = extractelement <32 x i8> %v,i64 14
 %word14 = zext i8 %lane14 to i64
 %mix14 = mul i64 %r13,1099511628211
 %r14 = xor i64 %mix14,%word14
 %lane15 = extractelement <32 x i8> %v,i64 15
 %word15 = zext i8 %lane15 to i64
 %mix15 = mul i64 %r14,1099511628211
 %r15 = xor i64 %mix15,%word15
 %lane16 = extractelement <32 x i8> %v,i64 16
 %word16 = zext i8 %lane16 to i64
 %mix16 = mul i64 %r15,1099511628211
 %r16 = xor i64 %mix16,%word16
 %lane17 = extractelement <32 x i8> %v,i64 17
 %word17 = zext i8 %lane17 to i64
 %mix17 = mul i64 %r16,1099511628211
 %r17 = xor i64 %mix17,%word17
 %lane18 = extractelement <32 x i8> %v,i64 18
 %word18 = zext i8 %lane18 to i64
 %mix18 = mul i64 %r17,1099511628211
 %r18 = xor i64 %mix18,%word18
 %lane19 = extractelement <32 x i8> %v,i64 19
 %word19 = zext i8 %lane19 to i64
 %mix19 = mul i64 %r18,1099511628211
 %r19 = xor i64 %mix19,%word19
 %lane20 = extractelement <32 x i8> %v,i64 20
 %word20 = zext i8 %lane20 to i64
 %mix20 = mul i64 %r19,1099511628211
 %r20 = xor i64 %mix20,%word20
 %lane21 = extractelement <32 x i8> %v,i64 21
 %word21 = zext i8 %lane21 to i64
 %mix21 = mul i64 %r20,1099511628211
 %r21 = xor i64 %mix21,%word21
 %lane22 = extractelement <32 x i8> %v,i64 22
 %word22 = zext i8 %lane22 to i64
 %mix22 = mul i64 %r21,1099511628211
 %r22 = xor i64 %mix22,%word22
 %lane23 = extractelement <32 x i8> %v,i64 23
 %word23 = zext i8 %lane23 to i64
 %mix23 = mul i64 %r22,1099511628211
 %r23 = xor i64 %mix23,%word23
 %lane24 = extractelement <32 x i8> %v,i64 24
 %word24 = zext i8 %lane24 to i64
 %mix24 = mul i64 %r23,1099511628211
 %r24 = xor i64 %mix24,%word24
 %lane25 = extractelement <32 x i8> %v,i64 25
 %word25 = zext i8 %lane25 to i64
 %mix25 = mul i64 %r24,1099511628211
 %r25 = xor i64 %mix25,%word25
 %lane26 = extractelement <32 x i8> %v,i64 26
 %word26 = zext i8 %lane26 to i64
 %mix26 = mul i64 %r25,1099511628211
 %r26 = xor i64 %mix26,%word26
 %lane27 = extractelement <32 x i8> %v,i64 27
 %word27 = zext i8 %lane27 to i64
 %mix27 = mul i64 %r26,1099511628211
 %r27 = xor i64 %mix27,%word27
 %lane28 = extractelement <32 x i8> %v,i64 28
 %word28 = zext i8 %lane28 to i64
 %mix28 = mul i64 %r27,1099511628211
 %r28 = xor i64 %mix28,%word28
 %lane29 = extractelement <32 x i8> %v,i64 29
 %word29 = zext i8 %lane29 to i64
 %mix29 = mul i64 %r28,1099511628211
 %r29 = xor i64 %mix29,%word29
 %lane30 = extractelement <32 x i8> %v,i64 30
 %word30 = zext i8 %lane30 to i64
 %mix30 = mul i64 %r29,1099511628211
 %r30 = xor i64 %mix30,%word30
 %lane31 = extractelement <32 x i8> %v,i64 31
 %word31 = zext i8 %lane31 to i64
 %mix31 = mul i64 %r30,1099511628211
 %r31 = xor i64 %mix31,%word31
 ret i64 %r31
}
declare i64 @vector_input_provider_1(i64,i64,i64,i64,i64,i64,<32 x i8>,i64)
define i64 @vector_input_probe_1(ptr %out,ptr %input,i64 %salt) {
entry:
 %v = load <32 x i8>,ptr %input,align 1
 %local = call fastcc i64 @vector_input_body_1(i64 1311768467463790320,i64 18364758544493064720,i64 1234605616436508552,i64 12379552201711258095,i64 9756277981056907928,i64 1161981756646125696,<32 x i8> %v,i64 %salt)
 %external = call i64 @vector_input_provider_1(i64 1311768467463790320,i64 18364758544493064720,i64 1234605616436508552,i64 12379552201711258095,i64 9756277981056907928,i64 1161981756646125696,<32 x i8> %v,i64 %salt)
 store i64 %local,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %external,ptr %next,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define i64 @vector_input_body_2(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,<64 x i8> %v,i64 %salt) noinline {
entry:
 %s0 = xor i64 %salt,%p0
 %s1 = xor i64 %s0,%p1
 %s2 = xor i64 %s1,%p2
 %s3 = xor i64 %s2,%p3
 %s4 = xor i64 %s3,%p4
 %s5 = xor i64 %s4,%p5
 %lane0 = extractelement <64 x i8> %v,i64 0
 %word0 = zext i8 %lane0 to i64
 %mix0 = mul i64 %s5,1099511628211
 %r0 = xor i64 %mix0,%word0
 %lane1 = extractelement <64 x i8> %v,i64 1
 %word1 = zext i8 %lane1 to i64
 %mix1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %mix1,%word1
 %lane2 = extractelement <64 x i8> %v,i64 2
 %word2 = zext i8 %lane2 to i64
 %mix2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %mix2,%word2
 %lane3 = extractelement <64 x i8> %v,i64 3
 %word3 = zext i8 %lane3 to i64
 %mix3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %mix3,%word3
 %lane4 = extractelement <64 x i8> %v,i64 4
 %word4 = zext i8 %lane4 to i64
 %mix4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %mix4,%word4
 %lane5 = extractelement <64 x i8> %v,i64 5
 %word5 = zext i8 %lane5 to i64
 %mix5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %mix5,%word5
 %lane6 = extractelement <64 x i8> %v,i64 6
 %word6 = zext i8 %lane6 to i64
 %mix6 = mul i64 %r5,1099511628211
 %r6 = xor i64 %mix6,%word6
 %lane7 = extractelement <64 x i8> %v,i64 7
 %word7 = zext i8 %lane7 to i64
 %mix7 = mul i64 %r6,1099511628211
 %r7 = xor i64 %mix7,%word7
 %lane8 = extractelement <64 x i8> %v,i64 8
 %word8 = zext i8 %lane8 to i64
 %mix8 = mul i64 %r7,1099511628211
 %r8 = xor i64 %mix8,%word8
 %lane9 = extractelement <64 x i8> %v,i64 9
 %word9 = zext i8 %lane9 to i64
 %mix9 = mul i64 %r8,1099511628211
 %r9 = xor i64 %mix9,%word9
 %lane10 = extractelement <64 x i8> %v,i64 10
 %word10 = zext i8 %lane10 to i64
 %mix10 = mul i64 %r9,1099511628211
 %r10 = xor i64 %mix10,%word10
 %lane11 = extractelement <64 x i8> %v,i64 11
 %word11 = zext i8 %lane11 to i64
 %mix11 = mul i64 %r10,1099511628211
 %r11 = xor i64 %mix11,%word11
 %lane12 = extractelement <64 x i8> %v,i64 12
 %word12 = zext i8 %lane12 to i64
 %mix12 = mul i64 %r11,1099511628211
 %r12 = xor i64 %mix12,%word12
 %lane13 = extractelement <64 x i8> %v,i64 13
 %word13 = zext i8 %lane13 to i64
 %mix13 = mul i64 %r12,1099511628211
 %r13 = xor i64 %mix13,%word13
 %lane14 = extractelement <64 x i8> %v,i64 14
 %word14 = zext i8 %lane14 to i64
 %mix14 = mul i64 %r13,1099511628211
 %r14 = xor i64 %mix14,%word14
 %lane15 = extractelement <64 x i8> %v,i64 15
 %word15 = zext i8 %lane15 to i64
 %mix15 = mul i64 %r14,1099511628211
 %r15 = xor i64 %mix15,%word15
 %lane16 = extractelement <64 x i8> %v,i64 16
 %word16 = zext i8 %lane16 to i64
 %mix16 = mul i64 %r15,1099511628211
 %r16 = xor i64 %mix16,%word16
 %lane17 = extractelement <64 x i8> %v,i64 17
 %word17 = zext i8 %lane17 to i64
 %mix17 = mul i64 %r16,1099511628211
 %r17 = xor i64 %mix17,%word17
 %lane18 = extractelement <64 x i8> %v,i64 18
 %word18 = zext i8 %lane18 to i64
 %mix18 = mul i64 %r17,1099511628211
 %r18 = xor i64 %mix18,%word18
 %lane19 = extractelement <64 x i8> %v,i64 19
 %word19 = zext i8 %lane19 to i64
 %mix19 = mul i64 %r18,1099511628211
 %r19 = xor i64 %mix19,%word19
 %lane20 = extractelement <64 x i8> %v,i64 20
 %word20 = zext i8 %lane20 to i64
 %mix20 = mul i64 %r19,1099511628211
 %r20 = xor i64 %mix20,%word20
 %lane21 = extractelement <64 x i8> %v,i64 21
 %word21 = zext i8 %lane21 to i64
 %mix21 = mul i64 %r20,1099511628211
 %r21 = xor i64 %mix21,%word21
 %lane22 = extractelement <64 x i8> %v,i64 22
 %word22 = zext i8 %lane22 to i64
 %mix22 = mul i64 %r21,1099511628211
 %r22 = xor i64 %mix22,%word22
 %lane23 = extractelement <64 x i8> %v,i64 23
 %word23 = zext i8 %lane23 to i64
 %mix23 = mul i64 %r22,1099511628211
 %r23 = xor i64 %mix23,%word23
 %lane24 = extractelement <64 x i8> %v,i64 24
 %word24 = zext i8 %lane24 to i64
 %mix24 = mul i64 %r23,1099511628211
 %r24 = xor i64 %mix24,%word24
 %lane25 = extractelement <64 x i8> %v,i64 25
 %word25 = zext i8 %lane25 to i64
 %mix25 = mul i64 %r24,1099511628211
 %r25 = xor i64 %mix25,%word25
 %lane26 = extractelement <64 x i8> %v,i64 26
 %word26 = zext i8 %lane26 to i64
 %mix26 = mul i64 %r25,1099511628211
 %r26 = xor i64 %mix26,%word26
 %lane27 = extractelement <64 x i8> %v,i64 27
 %word27 = zext i8 %lane27 to i64
 %mix27 = mul i64 %r26,1099511628211
 %r27 = xor i64 %mix27,%word27
 %lane28 = extractelement <64 x i8> %v,i64 28
 %word28 = zext i8 %lane28 to i64
 %mix28 = mul i64 %r27,1099511628211
 %r28 = xor i64 %mix28,%word28
 %lane29 = extractelement <64 x i8> %v,i64 29
 %word29 = zext i8 %lane29 to i64
 %mix29 = mul i64 %r28,1099511628211
 %r29 = xor i64 %mix29,%word29
 %lane30 = extractelement <64 x i8> %v,i64 30
 %word30 = zext i8 %lane30 to i64
 %mix30 = mul i64 %r29,1099511628211
 %r30 = xor i64 %mix30,%word30
 %lane31 = extractelement <64 x i8> %v,i64 31
 %word31 = zext i8 %lane31 to i64
 %mix31 = mul i64 %r30,1099511628211
 %r31 = xor i64 %mix31,%word31
 %lane32 = extractelement <64 x i8> %v,i64 32
 %word32 = zext i8 %lane32 to i64
 %mix32 = mul i64 %r31,1099511628211
 %r32 = xor i64 %mix32,%word32
 %lane33 = extractelement <64 x i8> %v,i64 33
 %word33 = zext i8 %lane33 to i64
 %mix33 = mul i64 %r32,1099511628211
 %r33 = xor i64 %mix33,%word33
 %lane34 = extractelement <64 x i8> %v,i64 34
 %word34 = zext i8 %lane34 to i64
 %mix34 = mul i64 %r33,1099511628211
 %r34 = xor i64 %mix34,%word34
 %lane35 = extractelement <64 x i8> %v,i64 35
 %word35 = zext i8 %lane35 to i64
 %mix35 = mul i64 %r34,1099511628211
 %r35 = xor i64 %mix35,%word35
 %lane36 = extractelement <64 x i8> %v,i64 36
 %word36 = zext i8 %lane36 to i64
 %mix36 = mul i64 %r35,1099511628211
 %r36 = xor i64 %mix36,%word36
 %lane37 = extractelement <64 x i8> %v,i64 37
 %word37 = zext i8 %lane37 to i64
 %mix37 = mul i64 %r36,1099511628211
 %r37 = xor i64 %mix37,%word37
 %lane38 = extractelement <64 x i8> %v,i64 38
 %word38 = zext i8 %lane38 to i64
 %mix38 = mul i64 %r37,1099511628211
 %r38 = xor i64 %mix38,%word38
 %lane39 = extractelement <64 x i8> %v,i64 39
 %word39 = zext i8 %lane39 to i64
 %mix39 = mul i64 %r38,1099511628211
 %r39 = xor i64 %mix39,%word39
 %lane40 = extractelement <64 x i8> %v,i64 40
 %word40 = zext i8 %lane40 to i64
 %mix40 = mul i64 %r39,1099511628211
 %r40 = xor i64 %mix40,%word40
 %lane41 = extractelement <64 x i8> %v,i64 41
 %word41 = zext i8 %lane41 to i64
 %mix41 = mul i64 %r40,1099511628211
 %r41 = xor i64 %mix41,%word41
 %lane42 = extractelement <64 x i8> %v,i64 42
 %word42 = zext i8 %lane42 to i64
 %mix42 = mul i64 %r41,1099511628211
 %r42 = xor i64 %mix42,%word42
 %lane43 = extractelement <64 x i8> %v,i64 43
 %word43 = zext i8 %lane43 to i64
 %mix43 = mul i64 %r42,1099511628211
 %r43 = xor i64 %mix43,%word43
 %lane44 = extractelement <64 x i8> %v,i64 44
 %word44 = zext i8 %lane44 to i64
 %mix44 = mul i64 %r43,1099511628211
 %r44 = xor i64 %mix44,%word44
 %lane45 = extractelement <64 x i8> %v,i64 45
 %word45 = zext i8 %lane45 to i64
 %mix45 = mul i64 %r44,1099511628211
 %r45 = xor i64 %mix45,%word45
 %lane46 = extractelement <64 x i8> %v,i64 46
 %word46 = zext i8 %lane46 to i64
 %mix46 = mul i64 %r45,1099511628211
 %r46 = xor i64 %mix46,%word46
 %lane47 = extractelement <64 x i8> %v,i64 47
 %word47 = zext i8 %lane47 to i64
 %mix47 = mul i64 %r46,1099511628211
 %r47 = xor i64 %mix47,%word47
 %lane48 = extractelement <64 x i8> %v,i64 48
 %word48 = zext i8 %lane48 to i64
 %mix48 = mul i64 %r47,1099511628211
 %r48 = xor i64 %mix48,%word48
 %lane49 = extractelement <64 x i8> %v,i64 49
 %word49 = zext i8 %lane49 to i64
 %mix49 = mul i64 %r48,1099511628211
 %r49 = xor i64 %mix49,%word49
 %lane50 = extractelement <64 x i8> %v,i64 50
 %word50 = zext i8 %lane50 to i64
 %mix50 = mul i64 %r49,1099511628211
 %r50 = xor i64 %mix50,%word50
 %lane51 = extractelement <64 x i8> %v,i64 51
 %word51 = zext i8 %lane51 to i64
 %mix51 = mul i64 %r50,1099511628211
 %r51 = xor i64 %mix51,%word51
 %lane52 = extractelement <64 x i8> %v,i64 52
 %word52 = zext i8 %lane52 to i64
 %mix52 = mul i64 %r51,1099511628211
 %r52 = xor i64 %mix52,%word52
 %lane53 = extractelement <64 x i8> %v,i64 53
 %word53 = zext i8 %lane53 to i64
 %mix53 = mul i64 %r52,1099511628211
 %r53 = xor i64 %mix53,%word53
 %lane54 = extractelement <64 x i8> %v,i64 54
 %word54 = zext i8 %lane54 to i64
 %mix54 = mul i64 %r53,1099511628211
 %r54 = xor i64 %mix54,%word54
 %lane55 = extractelement <64 x i8> %v,i64 55
 %word55 = zext i8 %lane55 to i64
 %mix55 = mul i64 %r54,1099511628211
 %r55 = xor i64 %mix55,%word55
 %lane56 = extractelement <64 x i8> %v,i64 56
 %word56 = zext i8 %lane56 to i64
 %mix56 = mul i64 %r55,1099511628211
 %r56 = xor i64 %mix56,%word56
 %lane57 = extractelement <64 x i8> %v,i64 57
 %word57 = zext i8 %lane57 to i64
 %mix57 = mul i64 %r56,1099511628211
 %r57 = xor i64 %mix57,%word57
 %lane58 = extractelement <64 x i8> %v,i64 58
 %word58 = zext i8 %lane58 to i64
 %mix58 = mul i64 %r57,1099511628211
 %r58 = xor i64 %mix58,%word58
 %lane59 = extractelement <64 x i8> %v,i64 59
 %word59 = zext i8 %lane59 to i64
 %mix59 = mul i64 %r58,1099511628211
 %r59 = xor i64 %mix59,%word59
 %lane60 = extractelement <64 x i8> %v,i64 60
 %word60 = zext i8 %lane60 to i64
 %mix60 = mul i64 %r59,1099511628211
 %r60 = xor i64 %mix60,%word60
 %lane61 = extractelement <64 x i8> %v,i64 61
 %word61 = zext i8 %lane61 to i64
 %mix61 = mul i64 %r60,1099511628211
 %r61 = xor i64 %mix61,%word61
 %lane62 = extractelement <64 x i8> %v,i64 62
 %word62 = zext i8 %lane62 to i64
 %mix62 = mul i64 %r61,1099511628211
 %r62 = xor i64 %mix62,%word62
 %lane63 = extractelement <64 x i8> %v,i64 63
 %word63 = zext i8 %lane63 to i64
 %mix63 = mul i64 %r62,1099511628211
 %r63 = xor i64 %mix63,%word63
 ret i64 %r63
}
declare i64 @vector_input_provider_2(i64,i64,i64,i64,i64,i64,<64 x i8>,i64)
define i64 @vector_input_probe_2(ptr %out,ptr %input,i64 %salt) {
entry:
 %v = load <64 x i8>,ptr %input,align 1
 %local = call i64 @vector_input_body_2(i64 1311768467463790320,i64 18364758544493064720,i64 1234605616436508552,i64 12379552201711258095,i64 9756277981056907928,i64 1161981756646125696,<64 x i8> %v,i64 %salt)
 %external = call i64 @vector_input_provider_2(i64 1311768467463790320,i64 18364758544493064720,i64 1234605616436508552,i64 12379552201711258095,i64 9756277981056907928,i64 1161981756646125696,<64 x i8> %v,i64 %salt)
 store i64 %local,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %external,ptr %next,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc i64 @vector_input_body_3(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,<64 x i8> %v,i64 %salt) noinline {
entry:
 %s0 = xor i64 %salt,%p0
 %s1 = xor i64 %s0,%p1
 %s2 = xor i64 %s1,%p2
 %s3 = xor i64 %s2,%p3
 %s4 = xor i64 %s3,%p4
 %s5 = xor i64 %s4,%p5
 %lane0 = extractelement <64 x i8> %v,i64 0
 %word0 = zext i8 %lane0 to i64
 %mix0 = mul i64 %s5,1099511628211
 %r0 = xor i64 %mix0,%word0
 %lane1 = extractelement <64 x i8> %v,i64 1
 %word1 = zext i8 %lane1 to i64
 %mix1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %mix1,%word1
 %lane2 = extractelement <64 x i8> %v,i64 2
 %word2 = zext i8 %lane2 to i64
 %mix2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %mix2,%word2
 %lane3 = extractelement <64 x i8> %v,i64 3
 %word3 = zext i8 %lane3 to i64
 %mix3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %mix3,%word3
 %lane4 = extractelement <64 x i8> %v,i64 4
 %word4 = zext i8 %lane4 to i64
 %mix4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %mix4,%word4
 %lane5 = extractelement <64 x i8> %v,i64 5
 %word5 = zext i8 %lane5 to i64
 %mix5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %mix5,%word5
 %lane6 = extractelement <64 x i8> %v,i64 6
 %word6 = zext i8 %lane6 to i64
 %mix6 = mul i64 %r5,1099511628211
 %r6 = xor i64 %mix6,%word6
 %lane7 = extractelement <64 x i8> %v,i64 7
 %word7 = zext i8 %lane7 to i64
 %mix7 = mul i64 %r6,1099511628211
 %r7 = xor i64 %mix7,%word7
 %lane8 = extractelement <64 x i8> %v,i64 8
 %word8 = zext i8 %lane8 to i64
 %mix8 = mul i64 %r7,1099511628211
 %r8 = xor i64 %mix8,%word8
 %lane9 = extractelement <64 x i8> %v,i64 9
 %word9 = zext i8 %lane9 to i64
 %mix9 = mul i64 %r8,1099511628211
 %r9 = xor i64 %mix9,%word9
 %lane10 = extractelement <64 x i8> %v,i64 10
 %word10 = zext i8 %lane10 to i64
 %mix10 = mul i64 %r9,1099511628211
 %r10 = xor i64 %mix10,%word10
 %lane11 = extractelement <64 x i8> %v,i64 11
 %word11 = zext i8 %lane11 to i64
 %mix11 = mul i64 %r10,1099511628211
 %r11 = xor i64 %mix11,%word11
 %lane12 = extractelement <64 x i8> %v,i64 12
 %word12 = zext i8 %lane12 to i64
 %mix12 = mul i64 %r11,1099511628211
 %r12 = xor i64 %mix12,%word12
 %lane13 = extractelement <64 x i8> %v,i64 13
 %word13 = zext i8 %lane13 to i64
 %mix13 = mul i64 %r12,1099511628211
 %r13 = xor i64 %mix13,%word13
 %lane14 = extractelement <64 x i8> %v,i64 14
 %word14 = zext i8 %lane14 to i64
 %mix14 = mul i64 %r13,1099511628211
 %r14 = xor i64 %mix14,%word14
 %lane15 = extractelement <64 x i8> %v,i64 15
 %word15 = zext i8 %lane15 to i64
 %mix15 = mul i64 %r14,1099511628211
 %r15 = xor i64 %mix15,%word15
 %lane16 = extractelement <64 x i8> %v,i64 16
 %word16 = zext i8 %lane16 to i64
 %mix16 = mul i64 %r15,1099511628211
 %r16 = xor i64 %mix16,%word16
 %lane17 = extractelement <64 x i8> %v,i64 17
 %word17 = zext i8 %lane17 to i64
 %mix17 = mul i64 %r16,1099511628211
 %r17 = xor i64 %mix17,%word17
 %lane18 = extractelement <64 x i8> %v,i64 18
 %word18 = zext i8 %lane18 to i64
 %mix18 = mul i64 %r17,1099511628211
 %r18 = xor i64 %mix18,%word18
 %lane19 = extractelement <64 x i8> %v,i64 19
 %word19 = zext i8 %lane19 to i64
 %mix19 = mul i64 %r18,1099511628211
 %r19 = xor i64 %mix19,%word19
 %lane20 = extractelement <64 x i8> %v,i64 20
 %word20 = zext i8 %lane20 to i64
 %mix20 = mul i64 %r19,1099511628211
 %r20 = xor i64 %mix20,%word20
 %lane21 = extractelement <64 x i8> %v,i64 21
 %word21 = zext i8 %lane21 to i64
 %mix21 = mul i64 %r20,1099511628211
 %r21 = xor i64 %mix21,%word21
 %lane22 = extractelement <64 x i8> %v,i64 22
 %word22 = zext i8 %lane22 to i64
 %mix22 = mul i64 %r21,1099511628211
 %r22 = xor i64 %mix22,%word22
 %lane23 = extractelement <64 x i8> %v,i64 23
 %word23 = zext i8 %lane23 to i64
 %mix23 = mul i64 %r22,1099511628211
 %r23 = xor i64 %mix23,%word23
 %lane24 = extractelement <64 x i8> %v,i64 24
 %word24 = zext i8 %lane24 to i64
 %mix24 = mul i64 %r23,1099511628211
 %r24 = xor i64 %mix24,%word24
 %lane25 = extractelement <64 x i8> %v,i64 25
 %word25 = zext i8 %lane25 to i64
 %mix25 = mul i64 %r24,1099511628211
 %r25 = xor i64 %mix25,%word25
 %lane26 = extractelement <64 x i8> %v,i64 26
 %word26 = zext i8 %lane26 to i64
 %mix26 = mul i64 %r25,1099511628211
 %r26 = xor i64 %mix26,%word26
 %lane27 = extractelement <64 x i8> %v,i64 27
 %word27 = zext i8 %lane27 to i64
 %mix27 = mul i64 %r26,1099511628211
 %r27 = xor i64 %mix27,%word27
 %lane28 = extractelement <64 x i8> %v,i64 28
 %word28 = zext i8 %lane28 to i64
 %mix28 = mul i64 %r27,1099511628211
 %r28 = xor i64 %mix28,%word28
 %lane29 = extractelement <64 x i8> %v,i64 29
 %word29 = zext i8 %lane29 to i64
 %mix29 = mul i64 %r28,1099511628211
 %r29 = xor i64 %mix29,%word29
 %lane30 = extractelement <64 x i8> %v,i64 30
 %word30 = zext i8 %lane30 to i64
 %mix30 = mul i64 %r29,1099511628211
 %r30 = xor i64 %mix30,%word30
 %lane31 = extractelement <64 x i8> %v,i64 31
 %word31 = zext i8 %lane31 to i64
 %mix31 = mul i64 %r30,1099511628211
 %r31 = xor i64 %mix31,%word31
 %lane32 = extractelement <64 x i8> %v,i64 32
 %word32 = zext i8 %lane32 to i64
 %mix32 = mul i64 %r31,1099511628211
 %r32 = xor i64 %mix32,%word32
 %lane33 = extractelement <64 x i8> %v,i64 33
 %word33 = zext i8 %lane33 to i64
 %mix33 = mul i64 %r32,1099511628211
 %r33 = xor i64 %mix33,%word33
 %lane34 = extractelement <64 x i8> %v,i64 34
 %word34 = zext i8 %lane34 to i64
 %mix34 = mul i64 %r33,1099511628211
 %r34 = xor i64 %mix34,%word34
 %lane35 = extractelement <64 x i8> %v,i64 35
 %word35 = zext i8 %lane35 to i64
 %mix35 = mul i64 %r34,1099511628211
 %r35 = xor i64 %mix35,%word35
 %lane36 = extractelement <64 x i8> %v,i64 36
 %word36 = zext i8 %lane36 to i64
 %mix36 = mul i64 %r35,1099511628211
 %r36 = xor i64 %mix36,%word36
 %lane37 = extractelement <64 x i8> %v,i64 37
 %word37 = zext i8 %lane37 to i64
 %mix37 = mul i64 %r36,1099511628211
 %r37 = xor i64 %mix37,%word37
 %lane38 = extractelement <64 x i8> %v,i64 38
 %word38 = zext i8 %lane38 to i64
 %mix38 = mul i64 %r37,1099511628211
 %r38 = xor i64 %mix38,%word38
 %lane39 = extractelement <64 x i8> %v,i64 39
 %word39 = zext i8 %lane39 to i64
 %mix39 = mul i64 %r38,1099511628211
 %r39 = xor i64 %mix39,%word39
 %lane40 = extractelement <64 x i8> %v,i64 40
 %word40 = zext i8 %lane40 to i64
 %mix40 = mul i64 %r39,1099511628211
 %r40 = xor i64 %mix40,%word40
 %lane41 = extractelement <64 x i8> %v,i64 41
 %word41 = zext i8 %lane41 to i64
 %mix41 = mul i64 %r40,1099511628211
 %r41 = xor i64 %mix41,%word41
 %lane42 = extractelement <64 x i8> %v,i64 42
 %word42 = zext i8 %lane42 to i64
 %mix42 = mul i64 %r41,1099511628211
 %r42 = xor i64 %mix42,%word42
 %lane43 = extractelement <64 x i8> %v,i64 43
 %word43 = zext i8 %lane43 to i64
 %mix43 = mul i64 %r42,1099511628211
 %r43 = xor i64 %mix43,%word43
 %lane44 = extractelement <64 x i8> %v,i64 44
 %word44 = zext i8 %lane44 to i64
 %mix44 = mul i64 %r43,1099511628211
 %r44 = xor i64 %mix44,%word44
 %lane45 = extractelement <64 x i8> %v,i64 45
 %word45 = zext i8 %lane45 to i64
 %mix45 = mul i64 %r44,1099511628211
 %r45 = xor i64 %mix45,%word45
 %lane46 = extractelement <64 x i8> %v,i64 46
 %word46 = zext i8 %lane46 to i64
 %mix46 = mul i64 %r45,1099511628211
 %r46 = xor i64 %mix46,%word46
 %lane47 = extractelement <64 x i8> %v,i64 47
 %word47 = zext i8 %lane47 to i64
 %mix47 = mul i64 %r46,1099511628211
 %r47 = xor i64 %mix47,%word47
 %lane48 = extractelement <64 x i8> %v,i64 48
 %word48 = zext i8 %lane48 to i64
 %mix48 = mul i64 %r47,1099511628211
 %r48 = xor i64 %mix48,%word48
 %lane49 = extractelement <64 x i8> %v,i64 49
 %word49 = zext i8 %lane49 to i64
 %mix49 = mul i64 %r48,1099511628211
 %r49 = xor i64 %mix49,%word49
 %lane50 = extractelement <64 x i8> %v,i64 50
 %word50 = zext i8 %lane50 to i64
 %mix50 = mul i64 %r49,1099511628211
 %r50 = xor i64 %mix50,%word50
 %lane51 = extractelement <64 x i8> %v,i64 51
 %word51 = zext i8 %lane51 to i64
 %mix51 = mul i64 %r50,1099511628211
 %r51 = xor i64 %mix51,%word51
 %lane52 = extractelement <64 x i8> %v,i64 52
 %word52 = zext i8 %lane52 to i64
 %mix52 = mul i64 %r51,1099511628211
 %r52 = xor i64 %mix52,%word52
 %lane53 = extractelement <64 x i8> %v,i64 53
 %word53 = zext i8 %lane53 to i64
 %mix53 = mul i64 %r52,1099511628211
 %r53 = xor i64 %mix53,%word53
 %lane54 = extractelement <64 x i8> %v,i64 54
 %word54 = zext i8 %lane54 to i64
 %mix54 = mul i64 %r53,1099511628211
 %r54 = xor i64 %mix54,%word54
 %lane55 = extractelement <64 x i8> %v,i64 55
 %word55 = zext i8 %lane55 to i64
 %mix55 = mul i64 %r54,1099511628211
 %r55 = xor i64 %mix55,%word55
 %lane56 = extractelement <64 x i8> %v,i64 56
 %word56 = zext i8 %lane56 to i64
 %mix56 = mul i64 %r55,1099511628211
 %r56 = xor i64 %mix56,%word56
 %lane57 = extractelement <64 x i8> %v,i64 57
 %word57 = zext i8 %lane57 to i64
 %mix57 = mul i64 %r56,1099511628211
 %r57 = xor i64 %mix57,%word57
 %lane58 = extractelement <64 x i8> %v,i64 58
 %word58 = zext i8 %lane58 to i64
 %mix58 = mul i64 %r57,1099511628211
 %r58 = xor i64 %mix58,%word58
 %lane59 = extractelement <64 x i8> %v,i64 59
 %word59 = zext i8 %lane59 to i64
 %mix59 = mul i64 %r58,1099511628211
 %r59 = xor i64 %mix59,%word59
 %lane60 = extractelement <64 x i8> %v,i64 60
 %word60 = zext i8 %lane60 to i64
 %mix60 = mul i64 %r59,1099511628211
 %r60 = xor i64 %mix60,%word60
 %lane61 = extractelement <64 x i8> %v,i64 61
 %word61 = zext i8 %lane61 to i64
 %mix61 = mul i64 %r60,1099511628211
 %r61 = xor i64 %mix61,%word61
 %lane62 = extractelement <64 x i8> %v,i64 62
 %word62 = zext i8 %lane62 to i64
 %mix62 = mul i64 %r61,1099511628211
 %r62 = xor i64 %mix62,%word62
 %lane63 = extractelement <64 x i8> %v,i64 63
 %word63 = zext i8 %lane63 to i64
 %mix63 = mul i64 %r62,1099511628211
 %r63 = xor i64 %mix63,%word63
 ret i64 %r63
}
declare i64 @vector_input_provider_3(i64,i64,i64,i64,i64,i64,<64 x i8>,i64)
define i64 @vector_input_probe_3(ptr %out,ptr %input,i64 %salt) {
entry:
 %v = load <64 x i8>,ptr %input,align 1
 %local = call fastcc i64 @vector_input_body_3(i64 1311768467463790320,i64 18364758544493064720,i64 1234605616436508552,i64 12379552201711258095,i64 9756277981056907928,i64 1161981756646125696,<64 x i8> %v,i64 %salt)
 %external = call i64 @vector_input_provider_3(i64 1311768467463790320,i64 18364758544493064720,i64 1234605616436508552,i64 12379552201711258095,i64 9756277981056907928,i64 1161981756646125696,<64 x i8> %v,i64 %salt)
 store i64 %local,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %external,ptr %next,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define i64 @vector_input_body_4(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,<16 x i16> %v,i64 %salt) noinline {
entry:
 %s0 = xor i64 %salt,%p0
 %s1 = xor i64 %s0,%p1
 %s2 = xor i64 %s1,%p2
 %s3 = xor i64 %s2,%p3
 %s4 = xor i64 %s3,%p4
 %s5 = xor i64 %s4,%p5
 %lane0 = extractelement <16 x i16> %v,i64 0
 %word0 = zext i16 %lane0 to i64
 %mix0 = mul i64 %s5,1099511628211
 %r0 = xor i64 %mix0,%word0
 %lane1 = extractelement <16 x i16> %v,i64 1
 %word1 = zext i16 %lane1 to i64
 %mix1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %mix1,%word1
 %lane2 = extractelement <16 x i16> %v,i64 2
 %word2 = zext i16 %lane2 to i64
 %mix2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %mix2,%word2
 %lane3 = extractelement <16 x i16> %v,i64 3
 %word3 = zext i16 %lane3 to i64
 %mix3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %mix3,%word3
 %lane4 = extractelement <16 x i16> %v,i64 4
 %word4 = zext i16 %lane4 to i64
 %mix4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %mix4,%word4
 %lane5 = extractelement <16 x i16> %v,i64 5
 %word5 = zext i16 %lane5 to i64
 %mix5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %mix5,%word5
 %lane6 = extractelement <16 x i16> %v,i64 6
 %word6 = zext i16 %lane6 to i64
 %mix6 = mul i64 %r5,1099511628211
 %r6 = xor i64 %mix6,%word6
 %lane7 = extractelement <16 x i16> %v,i64 7
 %word7 = zext i16 %lane7 to i64
 %mix7 = mul i64 %r6,1099511628211
 %r7 = xor i64 %mix7,%word7
 %lane8 = extractelement <16 x i16> %v,i64 8
 %word8 = zext i16 %lane8 to i64
 %mix8 = mul i64 %r7,1099511628211
 %r8 = xor i64 %mix8,%word8
 %lane9 = extractelement <16 x i16> %v,i64 9
 %word9 = zext i16 %lane9 to i64
 %mix9 = mul i64 %r8,1099511628211
 %r9 = xor i64 %mix9,%word9
 %lane10 = extractelement <16 x i16> %v,i64 10
 %word10 = zext i16 %lane10 to i64
 %mix10 = mul i64 %r9,1099511628211
 %r10 = xor i64 %mix10,%word10
 %lane11 = extractelement <16 x i16> %v,i64 11
 %word11 = zext i16 %lane11 to i64
 %mix11 = mul i64 %r10,1099511628211
 %r11 = xor i64 %mix11,%word11
 %lane12 = extractelement <16 x i16> %v,i64 12
 %word12 = zext i16 %lane12 to i64
 %mix12 = mul i64 %r11,1099511628211
 %r12 = xor i64 %mix12,%word12
 %lane13 = extractelement <16 x i16> %v,i64 13
 %word13 = zext i16 %lane13 to i64
 %mix13 = mul i64 %r12,1099511628211
 %r13 = xor i64 %mix13,%word13
 %lane14 = extractelement <16 x i16> %v,i64 14
 %word14 = zext i16 %lane14 to i64
 %mix14 = mul i64 %r13,1099511628211
 %r14 = xor i64 %mix14,%word14
 %lane15 = extractelement <16 x i16> %v,i64 15
 %word15 = zext i16 %lane15 to i64
 %mix15 = mul i64 %r14,1099511628211
 %r15 = xor i64 %mix15,%word15
 ret i64 %r15
}
declare i64 @vector_input_provider_4(i64,i64,i64,i64,i64,i64,<16 x i16>,i64)
define i64 @vector_input_probe_4(ptr %out,ptr %input,i64 %salt) {
entry:
 %v = load <16 x i16>,ptr %input,align 1
 %local = call i64 @vector_input_body_4(i64 1311768467463790320,i64 18364758544493064720,i64 1234605616436508552,i64 12379552201711258095,i64 9756277981056907928,i64 1161981756646125696,<16 x i16> %v,i64 %salt)
 %external = call i64 @vector_input_provider_4(i64 1311768467463790320,i64 18364758544493064720,i64 1234605616436508552,i64 12379552201711258095,i64 9756277981056907928,i64 1161981756646125696,<16 x i16> %v,i64 %salt)
 store i64 %local,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %external,ptr %next,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc i64 @vector_input_body_5(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,<16 x i16> %v,i64 %salt) noinline {
entry:
 %s0 = xor i64 %salt,%p0
 %s1 = xor i64 %s0,%p1
 %s2 = xor i64 %s1,%p2
 %s3 = xor i64 %s2,%p3
 %s4 = xor i64 %s3,%p4
 %s5 = xor i64 %s4,%p5
 %lane0 = extractelement <16 x i16> %v,i64 0
 %word0 = zext i16 %lane0 to i64
 %mix0 = mul i64 %s5,1099511628211
 %r0 = xor i64 %mix0,%word0
 %lane1 = extractelement <16 x i16> %v,i64 1
 %word1 = zext i16 %lane1 to i64
 %mix1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %mix1,%word1
 %lane2 = extractelement <16 x i16> %v,i64 2
 %word2 = zext i16 %lane2 to i64
 %mix2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %mix2,%word2
 %lane3 = extractelement <16 x i16> %v,i64 3
 %word3 = zext i16 %lane3 to i64
 %mix3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %mix3,%word3
 %lane4 = extractelement <16 x i16> %v,i64 4
 %word4 = zext i16 %lane4 to i64
 %mix4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %mix4,%word4
 %lane5 = extractelement <16 x i16> %v,i64 5
 %word5 = zext i16 %lane5 to i64
 %mix5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %mix5,%word5
 %lane6 = extractelement <16 x i16> %v,i64 6
 %word6 = zext i16 %lane6 to i64
 %mix6 = mul i64 %r5,1099511628211
 %r6 = xor i64 %mix6,%word6
 %lane7 = extractelement <16 x i16> %v,i64 7
 %word7 = zext i16 %lane7 to i64
 %mix7 = mul i64 %r6,1099511628211
 %r7 = xor i64 %mix7,%word7
 %lane8 = extractelement <16 x i16> %v,i64 8
 %word8 = zext i16 %lane8 to i64
 %mix8 = mul i64 %r7,1099511628211
 %r8 = xor i64 %mix8,%word8
 %lane9 = extractelement <16 x i16> %v,i64 9
 %word9 = zext i16 %lane9 to i64
 %mix9 = mul i64 %r8,1099511628211
 %r9 = xor i64 %mix9,%word9
 %lane10 = extractelement <16 x i16> %v,i64 10
 %word10 = zext i16 %lane10 to i64
 %mix10 = mul i64 %r9,1099511628211
 %r10 = xor i64 %mix10,%word10
 %lane11 = extractelement <16 x i16> %v,i64 11
 %word11 = zext i16 %lane11 to i64
 %mix11 = mul i64 %r10,1099511628211
 %r11 = xor i64 %mix11,%word11
 %lane12 = extractelement <16 x i16> %v,i64 12
 %word12 = zext i16 %lane12 to i64
 %mix12 = mul i64 %r11,1099511628211
 %r12 = xor i64 %mix12,%word12
 %lane13 = extractelement <16 x i16> %v,i64 13
 %word13 = zext i16 %lane13 to i64
 %mix13 = mul i64 %r12,1099511628211
 %r13 = xor i64 %mix13,%word13
 %lane14 = extractelement <16 x i16> %v,i64 14
 %word14 = zext i16 %lane14 to i64
 %mix14 = mul i64 %r13,1099511628211
 %r14 = xor i64 %mix14,%word14
 %lane15 = extractelement <16 x i16> %v,i64 15
 %word15 = zext i16 %lane15 to i64
 %mix15 = mul i64 %r14,1099511628211
 %r15 = xor i64 %mix15,%word15
 ret i64 %r15
}
declare i64 @vector_input_provider_5(i64,i64,i64,i64,i64,i64,<16 x i16>,i64)
define i64 @vector_input_probe_5(ptr %out,ptr %input,i64 %salt) {
entry:
 %v = load <16 x i16>,ptr %input,align 1
 %local = call fastcc i64 @vector_input_body_5(i64 1311768467463790320,i64 18364758544493064720,i64 1234605616436508552,i64 12379552201711258095,i64 9756277981056907928,i64 1161981756646125696,<16 x i16> %v,i64 %salt)
 %external = call i64 @vector_input_provider_5(i64 1311768467463790320,i64 18364758544493064720,i64 1234605616436508552,i64 12379552201711258095,i64 9756277981056907928,i64 1161981756646125696,<16 x i16> %v,i64 %salt)
 store i64 %local,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %external,ptr %next,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define i64 @vector_input_body_6(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,<32 x i16> %v,i64 %salt) noinline {
entry:
 %s0 = xor i64 %salt,%p0
 %s1 = xor i64 %s0,%p1
 %s2 = xor i64 %s1,%p2
 %s3 = xor i64 %s2,%p3
 %s4 = xor i64 %s3,%p4
 %s5 = xor i64 %s4,%p5
 %lane0 = extractelement <32 x i16> %v,i64 0
 %word0 = zext i16 %lane0 to i64
 %mix0 = mul i64 %s5,1099511628211
 %r0 = xor i64 %mix0,%word0
 %lane1 = extractelement <32 x i16> %v,i64 1
 %word1 = zext i16 %lane1 to i64
 %mix1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %mix1,%word1
 %lane2 = extractelement <32 x i16> %v,i64 2
 %word2 = zext i16 %lane2 to i64
 %mix2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %mix2,%word2
 %lane3 = extractelement <32 x i16> %v,i64 3
 %word3 = zext i16 %lane3 to i64
 %mix3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %mix3,%word3
 %lane4 = extractelement <32 x i16> %v,i64 4
 %word4 = zext i16 %lane4 to i64
 %mix4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %mix4,%word4
 %lane5 = extractelement <32 x i16> %v,i64 5
 %word5 = zext i16 %lane5 to i64
 %mix5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %mix5,%word5
 %lane6 = extractelement <32 x i16> %v,i64 6
 %word6 = zext i16 %lane6 to i64
 %mix6 = mul i64 %r5,1099511628211
 %r6 = xor i64 %mix6,%word6
 %lane7 = extractelement <32 x i16> %v,i64 7
 %word7 = zext i16 %lane7 to i64
 %mix7 = mul i64 %r6,1099511628211
 %r7 = xor i64 %mix7,%word7
 %lane8 = extractelement <32 x i16> %v,i64 8
 %word8 = zext i16 %lane8 to i64
 %mix8 = mul i64 %r7,1099511628211
 %r8 = xor i64 %mix8,%word8
 %lane9 = extractelement <32 x i16> %v,i64 9
 %word9 = zext i16 %lane9 to i64
 %mix9 = mul i64 %r8,1099511628211
 %r9 = xor i64 %mix9,%word9
 %lane10 = extractelement <32 x i16> %v,i64 10
 %word10 = zext i16 %lane10 to i64
 %mix10 = mul i64 %r9,1099511628211
 %r10 = xor i64 %mix10,%word10
 %lane11 = extractelement <32 x i16> %v,i64 11
 %word11 = zext i16 %lane11 to i64
 %mix11 = mul i64 %r10,1099511628211
 %r11 = xor i64 %mix11,%word11
 %lane12 = extractelement <32 x i16> %v,i64 12
 %word12 = zext i16 %lane12 to i64
 %mix12 = mul i64 %r11,1099511628211
 %r12 = xor i64 %mix12,%word12
 %lane13 = extractelement <32 x i16> %v,i64 13
 %word13 = zext i16 %lane13 to i64
 %mix13 = mul i64 %r12,1099511628211
 %r13 = xor i64 %mix13,%word13
 %lane14 = extractelement <32 x i16> %v,i64 14
 %word14 = zext i16 %lane14 to i64
 %mix14 = mul i64 %r13,1099511628211
 %r14 = xor i64 %mix14,%word14
 %lane15 = extractelement <32 x i16> %v,i64 15
 %word15 = zext i16 %lane15 to i64
 %mix15 = mul i64 %r14,1099511628211
 %r15 = xor i64 %mix15,%word15
 %lane16 = extractelement <32 x i16> %v,i64 16
 %word16 = zext i16 %lane16 to i64
 %mix16 = mul i64 %r15,1099511628211
 %r16 = xor i64 %mix16,%word16
 %lane17 = extractelement <32 x i16> %v,i64 17
 %word17 = zext i16 %lane17 to i64
 %mix17 = mul i64 %r16,1099511628211
 %r17 = xor i64 %mix17,%word17
 %lane18 = extractelement <32 x i16> %v,i64 18
 %word18 = zext i16 %lane18 to i64
 %mix18 = mul i64 %r17,1099511628211
 %r18 = xor i64 %mix18,%word18
 %lane19 = extractelement <32 x i16> %v,i64 19
 %word19 = zext i16 %lane19 to i64
 %mix19 = mul i64 %r18,1099511628211
 %r19 = xor i64 %mix19,%word19
 %lane20 = extractelement <32 x i16> %v,i64 20
 %word20 = zext i16 %lane20 to i64
 %mix20 = mul i64 %r19,1099511628211
 %r20 = xor i64 %mix20,%word20
 %lane21 = extractelement <32 x i16> %v,i64 21
 %word21 = zext i16 %lane21 to i64
 %mix21 = mul i64 %r20,1099511628211
 %r21 = xor i64 %mix21,%word21
 %lane22 = extractelement <32 x i16> %v,i64 22
 %word22 = zext i16 %lane22 to i64
 %mix22 = mul i64 %r21,1099511628211
 %r22 = xor i64 %mix22,%word22
 %lane23 = extractelement <32 x i16> %v,i64 23
 %word23 = zext i16 %lane23 to i64
 %mix23 = mul i64 %r22,1099511628211
 %r23 = xor i64 %mix23,%word23
 %lane24 = extractelement <32 x i16> %v,i64 24
 %word24 = zext i16 %lane24 to i64
 %mix24 = mul i64 %r23,1099511628211
 %r24 = xor i64 %mix24,%word24
 %lane25 = extractelement <32 x i16> %v,i64 25
 %word25 = zext i16 %lane25 to i64
 %mix25 = mul i64 %r24,1099511628211
 %r25 = xor i64 %mix25,%word25
 %lane26 = extractelement <32 x i16> %v,i64 26
 %word26 = zext i16 %lane26 to i64
 %mix26 = mul i64 %r25,1099511628211
 %r26 = xor i64 %mix26,%word26
 %lane27 = extractelement <32 x i16> %v,i64 27
 %word27 = zext i16 %lane27 to i64
 %mix27 = mul i64 %r26,1099511628211
 %r27 = xor i64 %mix27,%word27
 %lane28 = extractelement <32 x i16> %v,i64 28
 %word28 = zext i16 %lane28 to i64
 %mix28 = mul i64 %r27,1099511628211
 %r28 = xor i64 %mix28,%word28
 %lane29 = extractelement <32 x i16> %v,i64 29
 %word29 = zext i16 %lane29 to i64
 %mix29 = mul i64 %r28,1099511628211
 %r29 = xor i64 %mix29,%word29
 %lane30 = extractelement <32 x i16> %v,i64 30
 %word30 = zext i16 %lane30 to i64
 %mix30 = mul i64 %r29,1099511628211
 %r30 = xor i64 %mix30,%word30
 %lane31 = extractelement <32 x i16> %v,i64 31
 %word31 = zext i16 %lane31 to i64
 %mix31 = mul i64 %r30,1099511628211
 %r31 = xor i64 %mix31,%word31
 ret i64 %r31
}
declare i64 @vector_input_provider_6(i64,i64,i64,i64,i64,i64,<32 x i16>,i64)
define i64 @vector_input_probe_6(ptr %out,ptr %input,i64 %salt) {
entry:
 %v = load <32 x i16>,ptr %input,align 1
 %local = call i64 @vector_input_body_6(i64 1311768467463790320,i64 18364758544493064720,i64 1234605616436508552,i64 12379552201711258095,i64 9756277981056907928,i64 1161981756646125696,<32 x i16> %v,i64 %salt)
 %external = call i64 @vector_input_provider_6(i64 1311768467463790320,i64 18364758544493064720,i64 1234605616436508552,i64 12379552201711258095,i64 9756277981056907928,i64 1161981756646125696,<32 x i16> %v,i64 %salt)
 store i64 %local,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %external,ptr %next,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc i64 @vector_input_body_7(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,<32 x i16> %v,i64 %salt) noinline {
entry:
 %s0 = xor i64 %salt,%p0
 %s1 = xor i64 %s0,%p1
 %s2 = xor i64 %s1,%p2
 %s3 = xor i64 %s2,%p3
 %s4 = xor i64 %s3,%p4
 %s5 = xor i64 %s4,%p5
 %lane0 = extractelement <32 x i16> %v,i64 0
 %word0 = zext i16 %lane0 to i64
 %mix0 = mul i64 %s5,1099511628211
 %r0 = xor i64 %mix0,%word0
 %lane1 = extractelement <32 x i16> %v,i64 1
 %word1 = zext i16 %lane1 to i64
 %mix1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %mix1,%word1
 %lane2 = extractelement <32 x i16> %v,i64 2
 %word2 = zext i16 %lane2 to i64
 %mix2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %mix2,%word2
 %lane3 = extractelement <32 x i16> %v,i64 3
 %word3 = zext i16 %lane3 to i64
 %mix3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %mix3,%word3
 %lane4 = extractelement <32 x i16> %v,i64 4
 %word4 = zext i16 %lane4 to i64
 %mix4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %mix4,%word4
 %lane5 = extractelement <32 x i16> %v,i64 5
 %word5 = zext i16 %lane5 to i64
 %mix5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %mix5,%word5
 %lane6 = extractelement <32 x i16> %v,i64 6
 %word6 = zext i16 %lane6 to i64
 %mix6 = mul i64 %r5,1099511628211
 %r6 = xor i64 %mix6,%word6
 %lane7 = extractelement <32 x i16> %v,i64 7
 %word7 = zext i16 %lane7 to i64
 %mix7 = mul i64 %r6,1099511628211
 %r7 = xor i64 %mix7,%word7
 %lane8 = extractelement <32 x i16> %v,i64 8
 %word8 = zext i16 %lane8 to i64
 %mix8 = mul i64 %r7,1099511628211
 %r8 = xor i64 %mix8,%word8
 %lane9 = extractelement <32 x i16> %v,i64 9
 %word9 = zext i16 %lane9 to i64
 %mix9 = mul i64 %r8,1099511628211
 %r9 = xor i64 %mix9,%word9
 %lane10 = extractelement <32 x i16> %v,i64 10
 %word10 = zext i16 %lane10 to i64
 %mix10 = mul i64 %r9,1099511628211
 %r10 = xor i64 %mix10,%word10
 %lane11 = extractelement <32 x i16> %v,i64 11
 %word11 = zext i16 %lane11 to i64
 %mix11 = mul i64 %r10,1099511628211
 %r11 = xor i64 %mix11,%word11
 %lane12 = extractelement <32 x i16> %v,i64 12
 %word12 = zext i16 %lane12 to i64
 %mix12 = mul i64 %r11,1099511628211
 %r12 = xor i64 %mix12,%word12
 %lane13 = extractelement <32 x i16> %v,i64 13
 %word13 = zext i16 %lane13 to i64
 %mix13 = mul i64 %r12,1099511628211
 %r13 = xor i64 %mix13,%word13
 %lane14 = extractelement <32 x i16> %v,i64 14
 %word14 = zext i16 %lane14 to i64
 %mix14 = mul i64 %r13,1099511628211
 %r14 = xor i64 %mix14,%word14
 %lane15 = extractelement <32 x i16> %v,i64 15
 %word15 = zext i16 %lane15 to i64
 %mix15 = mul i64 %r14,1099511628211
 %r15 = xor i64 %mix15,%word15
 %lane16 = extractelement <32 x i16> %v,i64 16
 %word16 = zext i16 %lane16 to i64
 %mix16 = mul i64 %r15,1099511628211
 %r16 = xor i64 %mix16,%word16
 %lane17 = extractelement <32 x i16> %v,i64 17
 %word17 = zext i16 %lane17 to i64
 %mix17 = mul i64 %r16,1099511628211
 %r17 = xor i64 %mix17,%word17
 %lane18 = extractelement <32 x i16> %v,i64 18
 %word18 = zext i16 %lane18 to i64
 %mix18 = mul i64 %r17,1099511628211
 %r18 = xor i64 %mix18,%word18
 %lane19 = extractelement <32 x i16> %v,i64 19
 %word19 = zext i16 %lane19 to i64
 %mix19 = mul i64 %r18,1099511628211
 %r19 = xor i64 %mix19,%word19
 %lane20 = extractelement <32 x i16> %v,i64 20
 %word20 = zext i16 %lane20 to i64
 %mix20 = mul i64 %r19,1099511628211
 %r20 = xor i64 %mix20,%word20
 %lane21 = extractelement <32 x i16> %v,i64 21
 %word21 = zext i16 %lane21 to i64
 %mix21 = mul i64 %r20,1099511628211
 %r21 = xor i64 %mix21,%word21
 %lane22 = extractelement <32 x i16> %v,i64 22
 %word22 = zext i16 %lane22 to i64
 %mix22 = mul i64 %r21,1099511628211
 %r22 = xor i64 %mix22,%word22
 %lane23 = extractelement <32 x i16> %v,i64 23
 %word23 = zext i16 %lane23 to i64
 %mix23 = mul i64 %r22,1099511628211
 %r23 = xor i64 %mix23,%word23
 %lane24 = extractelement <32 x i16> %v,i64 24
 %word24 = zext i16 %lane24 to i64
 %mix24 = mul i64 %r23,1099511628211
 %r24 = xor i64 %mix24,%word24
 %lane25 = extractelement <32 x i16> %v,i64 25
 %word25 = zext i16 %lane25 to i64
 %mix25 = mul i64 %r24,1099511628211
 %r25 = xor i64 %mix25,%word25
 %lane26 = extractelement <32 x i16> %v,i64 26
 %word26 = zext i16 %lane26 to i64
 %mix26 = mul i64 %r25,1099511628211
 %r26 = xor i64 %mix26,%word26
 %lane27 = extractelement <32 x i16> %v,i64 27
 %word27 = zext i16 %lane27 to i64
 %mix27 = mul i64 %r26,1099511628211
 %r27 = xor i64 %mix27,%word27
 %lane28 = extractelement <32 x i16> %v,i64 28
 %word28 = zext i16 %lane28 to i64
 %mix28 = mul i64 %r27,1099511628211
 %r28 = xor i64 %mix28,%word28
 %lane29 = extractelement <32 x i16> %v,i64 29
 %word29 = zext i16 %lane29 to i64
 %mix29 = mul i64 %r28,1099511628211
 %r29 = xor i64 %mix29,%word29
 %lane30 = extractelement <32 x i16> %v,i64 30
 %word30 = zext i16 %lane30 to i64
 %mix30 = mul i64 %r29,1099511628211
 %r30 = xor i64 %mix30,%word30
 %lane31 = extractelement <32 x i16> %v,i64 31
 %word31 = zext i16 %lane31 to i64
 %mix31 = mul i64 %r30,1099511628211
 %r31 = xor i64 %mix31,%word31
 ret i64 %r31
}
declare i64 @vector_input_provider_7(i64,i64,i64,i64,i64,i64,<32 x i16>,i64)
define i64 @vector_input_probe_7(ptr %out,ptr %input,i64 %salt) {
entry:
 %v = load <32 x i16>,ptr %input,align 1
 %local = call fastcc i64 @vector_input_body_7(i64 1311768467463790320,i64 18364758544493064720,i64 1234605616436508552,i64 12379552201711258095,i64 9756277981056907928,i64 1161981756646125696,<32 x i16> %v,i64 %salt)
 %external = call i64 @vector_input_provider_7(i64 1311768467463790320,i64 18364758544493064720,i64 1234605616436508552,i64 12379552201711258095,i64 9756277981056907928,i64 1161981756646125696,<32 x i16> %v,i64 %salt)
 store i64 %local,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %external,ptr %next,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define i64 @vector_input_body_8(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,<64 x i16> %v,i64 %salt) noinline {
entry:
 %s0 = xor i64 %salt,%p0
 %s1 = xor i64 %s0,%p1
 %s2 = xor i64 %s1,%p2
 %s3 = xor i64 %s2,%p3
 %s4 = xor i64 %s3,%p4
 %s5 = xor i64 %s4,%p5
 %lane0 = extractelement <64 x i16> %v,i64 0
 %word0 = zext i16 %lane0 to i64
 %mix0 = mul i64 %s5,1099511628211
 %r0 = xor i64 %mix0,%word0
 %lane1 = extractelement <64 x i16> %v,i64 1
 %word1 = zext i16 %lane1 to i64
 %mix1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %mix1,%word1
 %lane2 = extractelement <64 x i16> %v,i64 2
 %word2 = zext i16 %lane2 to i64
 %mix2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %mix2,%word2
 %lane3 = extractelement <64 x i16> %v,i64 3
 %word3 = zext i16 %lane3 to i64
 %mix3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %mix3,%word3
 %lane4 = extractelement <64 x i16> %v,i64 4
 %word4 = zext i16 %lane4 to i64
 %mix4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %mix4,%word4
 %lane5 = extractelement <64 x i16> %v,i64 5
 %word5 = zext i16 %lane5 to i64
 %mix5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %mix5,%word5
 %lane6 = extractelement <64 x i16> %v,i64 6
 %word6 = zext i16 %lane6 to i64
 %mix6 = mul i64 %r5,1099511628211
 %r6 = xor i64 %mix6,%word6
 %lane7 = extractelement <64 x i16> %v,i64 7
 %word7 = zext i16 %lane7 to i64
 %mix7 = mul i64 %r6,1099511628211
 %r7 = xor i64 %mix7,%word7
 %lane8 = extractelement <64 x i16> %v,i64 8
 %word8 = zext i16 %lane8 to i64
 %mix8 = mul i64 %r7,1099511628211
 %r8 = xor i64 %mix8,%word8
 %lane9 = extractelement <64 x i16> %v,i64 9
 %word9 = zext i16 %lane9 to i64
 %mix9 = mul i64 %r8,1099511628211
 %r9 = xor i64 %mix9,%word9
 %lane10 = extractelement <64 x i16> %v,i64 10
 %word10 = zext i16 %lane10 to i64
 %mix10 = mul i64 %r9,1099511628211
 %r10 = xor i64 %mix10,%word10
 %lane11 = extractelement <64 x i16> %v,i64 11
 %word11 = zext i16 %lane11 to i64
 %mix11 = mul i64 %r10,1099511628211
 %r11 = xor i64 %mix11,%word11
 %lane12 = extractelement <64 x i16> %v,i64 12
 %word12 = zext i16 %lane12 to i64
 %mix12 = mul i64 %r11,1099511628211
 %r12 = xor i64 %mix12,%word12
 %lane13 = extractelement <64 x i16> %v,i64 13
 %word13 = zext i16 %lane13 to i64
 %mix13 = mul i64 %r12,1099511628211
 %r13 = xor i64 %mix13,%word13
 %lane14 = extractelement <64 x i16> %v,i64 14
 %word14 = zext i16 %lane14 to i64
 %mix14 = mul i64 %r13,1099511628211
 %r14 = xor i64 %mix14,%word14
 %lane15 = extractelement <64 x i16> %v,i64 15
 %word15 = zext i16 %lane15 to i64
 %mix15 = mul i64 %r14,1099511628211
 %r15 = xor i64 %mix15,%word15
 %lane16 = extractelement <64 x i16> %v,i64 16
 %word16 = zext i16 %lane16 to i64
 %mix16 = mul i64 %r15,1099511628211
 %r16 = xor i64 %mix16,%word16
 %lane17 = extractelement <64 x i16> %v,i64 17
 %word17 = zext i16 %lane17 to i64
 %mix17 = mul i64 %r16,1099511628211
 %r17 = xor i64 %mix17,%word17
 %lane18 = extractelement <64 x i16> %v,i64 18
 %word18 = zext i16 %lane18 to i64
 %mix18 = mul i64 %r17,1099511628211
 %r18 = xor i64 %mix18,%word18
 %lane19 = extractelement <64 x i16> %v,i64 19
 %word19 = zext i16 %lane19 to i64
 %mix19 = mul i64 %r18,1099511628211
 %r19 = xor i64 %mix19,%word19
 %lane20 = extractelement <64 x i16> %v,i64 20
 %word20 = zext i16 %lane20 to i64
 %mix20 = mul i64 %r19,1099511628211
 %r20 = xor i64 %mix20,%word20
 %lane21 = extractelement <64 x i16> %v,i64 21
 %word21 = zext i16 %lane21 to i64
 %mix21 = mul i64 %r20,1099511628211
 %r21 = xor i64 %mix21,%word21
 %lane22 = extractelement <64 x i16> %v,i64 22
 %word22 = zext i16 %lane22 to i64
 %mix22 = mul i64 %r21,1099511628211
 %r22 = xor i64 %mix22,%word22
 %lane23 = extractelement <64 x i16> %v,i64 23
 %word23 = zext i16 %lane23 to i64
 %mix23 = mul i64 %r22,1099511628211
 %r23 = xor i64 %mix23,%word23
 %lane24 = extractelement <64 x i16> %v,i64 24
 %word24 = zext i16 %lane24 to i64
 %mix24 = mul i64 %r23,1099511628211
 %r24 = xor i64 %mix24,%word24
 %lane25 = extractelement <64 x i16> %v,i64 25
 %word25 = zext i16 %lane25 to i64
 %mix25 = mul i64 %r24,1099511628211
 %r25 = xor i64 %mix25,%word25
 %lane26 = extractelement <64 x i16> %v,i64 26
 %word26 = zext i16 %lane26 to i64
 %mix26 = mul i64 %r25,1099511628211
 %r26 = xor i64 %mix26,%word26
 %lane27 = extractelement <64 x i16> %v,i64 27
 %word27 = zext i16 %lane27 to i64
 %mix27 = mul i64 %r26,1099511628211
 %r27 = xor i64 %mix27,%word27
 %lane28 = extractelement <64 x i16> %v,i64 28
 %word28 = zext i16 %lane28 to i64
 %mix28 = mul i64 %r27,1099511628211
 %r28 = xor i64 %mix28,%word28
 %lane29 = extractelement <64 x i16> %v,i64 29
 %word29 = zext i16 %lane29 to i64
 %mix29 = mul i64 %r28,1099511628211
 %r29 = xor i64 %mix29,%word29
 %lane30 = extractelement <64 x i16> %v,i64 30
 %word30 = zext i16 %lane30 to i64
 %mix30 = mul i64 %r29,1099511628211
 %r30 = xor i64 %mix30,%word30
 %lane31 = extractelement <64 x i16> %v,i64 31
 %word31 = zext i16 %lane31 to i64
 %mix31 = mul i64 %r30,1099511628211
 %r31 = xor i64 %mix31,%word31
 %lane32 = extractelement <64 x i16> %v,i64 32
 %word32 = zext i16 %lane32 to i64
 %mix32 = mul i64 %r31,1099511628211
 %r32 = xor i64 %mix32,%word32
 %lane33 = extractelement <64 x i16> %v,i64 33
 %word33 = zext i16 %lane33 to i64
 %mix33 = mul i64 %r32,1099511628211
 %r33 = xor i64 %mix33,%word33
 %lane34 = extractelement <64 x i16> %v,i64 34
 %word34 = zext i16 %lane34 to i64
 %mix34 = mul i64 %r33,1099511628211
 %r34 = xor i64 %mix34,%word34
 %lane35 = extractelement <64 x i16> %v,i64 35
 %word35 = zext i16 %lane35 to i64
 %mix35 = mul i64 %r34,1099511628211
 %r35 = xor i64 %mix35,%word35
 %lane36 = extractelement <64 x i16> %v,i64 36
 %word36 = zext i16 %lane36 to i64
 %mix36 = mul i64 %r35,1099511628211
 %r36 = xor i64 %mix36,%word36
 %lane37 = extractelement <64 x i16> %v,i64 37
 %word37 = zext i16 %lane37 to i64
 %mix37 = mul i64 %r36,1099511628211
 %r37 = xor i64 %mix37,%word37
 %lane38 = extractelement <64 x i16> %v,i64 38
 %word38 = zext i16 %lane38 to i64
 %mix38 = mul i64 %r37,1099511628211
 %r38 = xor i64 %mix38,%word38
 %lane39 = extractelement <64 x i16> %v,i64 39
 %word39 = zext i16 %lane39 to i64
 %mix39 = mul i64 %r38,1099511628211
 %r39 = xor i64 %mix39,%word39
 %lane40 = extractelement <64 x i16> %v,i64 40
 %word40 = zext i16 %lane40 to i64
 %mix40 = mul i64 %r39,1099511628211
 %r40 = xor i64 %mix40,%word40
 %lane41 = extractelement <64 x i16> %v,i64 41
 %word41 = zext i16 %lane41 to i64
 %mix41 = mul i64 %r40,1099511628211
 %r41 = xor i64 %mix41,%word41
 %lane42 = extractelement <64 x i16> %v,i64 42
 %word42 = zext i16 %lane42 to i64
 %mix42 = mul i64 %r41,1099511628211
 %r42 = xor i64 %mix42,%word42
 %lane43 = extractelement <64 x i16> %v,i64 43
 %word43 = zext i16 %lane43 to i64
 %mix43 = mul i64 %r42,1099511628211
 %r43 = xor i64 %mix43,%word43
 %lane44 = extractelement <64 x i16> %v,i64 44
 %word44 = zext i16 %lane44 to i64
 %mix44 = mul i64 %r43,1099511628211
 %r44 = xor i64 %mix44,%word44
 %lane45 = extractelement <64 x i16> %v,i64 45
 %word45 = zext i16 %lane45 to i64
 %mix45 = mul i64 %r44,1099511628211
 %r45 = xor i64 %mix45,%word45
 %lane46 = extractelement <64 x i16> %v,i64 46
 %word46 = zext i16 %lane46 to i64
 %mix46 = mul i64 %r45,1099511628211
 %r46 = xor i64 %mix46,%word46
 %lane47 = extractelement <64 x i16> %v,i64 47
 %word47 = zext i16 %lane47 to i64
 %mix47 = mul i64 %r46,1099511628211
 %r47 = xor i64 %mix47,%word47
 %lane48 = extractelement <64 x i16> %v,i64 48
 %word48 = zext i16 %lane48 to i64
 %mix48 = mul i64 %r47,1099511628211
 %r48 = xor i64 %mix48,%word48
 %lane49 = extractelement <64 x i16> %v,i64 49
 %word49 = zext i16 %lane49 to i64
 %mix49 = mul i64 %r48,1099511628211
 %r49 = xor i64 %mix49,%word49
 %lane50 = extractelement <64 x i16> %v,i64 50
 %word50 = zext i16 %lane50 to i64
 %mix50 = mul i64 %r49,1099511628211
 %r50 = xor i64 %mix50,%word50
 %lane51 = extractelement <64 x i16> %v,i64 51
 %word51 = zext i16 %lane51 to i64
 %mix51 = mul i64 %r50,1099511628211
 %r51 = xor i64 %mix51,%word51
 %lane52 = extractelement <64 x i16> %v,i64 52
 %word52 = zext i16 %lane52 to i64
 %mix52 = mul i64 %r51,1099511628211
 %r52 = xor i64 %mix52,%word52
 %lane53 = extractelement <64 x i16> %v,i64 53
 %word53 = zext i16 %lane53 to i64
 %mix53 = mul i64 %r52,1099511628211
 %r53 = xor i64 %mix53,%word53
 %lane54 = extractelement <64 x i16> %v,i64 54
 %word54 = zext i16 %lane54 to i64
 %mix54 = mul i64 %r53,1099511628211
 %r54 = xor i64 %mix54,%word54
 %lane55 = extractelement <64 x i16> %v,i64 55
 %word55 = zext i16 %lane55 to i64
 %mix55 = mul i64 %r54,1099511628211
 %r55 = xor i64 %mix55,%word55
 %lane56 = extractelement <64 x i16> %v,i64 56
 %word56 = zext i16 %lane56 to i64
 %mix56 = mul i64 %r55,1099511628211
 %r56 = xor i64 %mix56,%word56
 %lane57 = extractelement <64 x i16> %v,i64 57
 %word57 = zext i16 %lane57 to i64
 %mix57 = mul i64 %r56,1099511628211
 %r57 = xor i64 %mix57,%word57
 %lane58 = extractelement <64 x i16> %v,i64 58
 %word58 = zext i16 %lane58 to i64
 %mix58 = mul i64 %r57,1099511628211
 %r58 = xor i64 %mix58,%word58
 %lane59 = extractelement <64 x i16> %v,i64 59
 %word59 = zext i16 %lane59 to i64
 %mix59 = mul i64 %r58,1099511628211
 %r59 = xor i64 %mix59,%word59
 %lane60 = extractelement <64 x i16> %v,i64 60
 %word60 = zext i16 %lane60 to i64
 %mix60 = mul i64 %r59,1099511628211
 %r60 = xor i64 %mix60,%word60
 %lane61 = extractelement <64 x i16> %v,i64 61
 %word61 = zext i16 %lane61 to i64
 %mix61 = mul i64 %r60,1099511628211
 %r61 = xor i64 %mix61,%word61
 %lane62 = extractelement <64 x i16> %v,i64 62
 %word62 = zext i16 %lane62 to i64
 %mix62 = mul i64 %r61,1099511628211
 %r62 = xor i64 %mix62,%word62
 %lane63 = extractelement <64 x i16> %v,i64 63
 %word63 = zext i16 %lane63 to i64
 %mix63 = mul i64 %r62,1099511628211
 %r63 = xor i64 %mix63,%word63
 ret i64 %r63
}
declare i64 @vector_input_provider_8(i64,i64,i64,i64,i64,i64,<64 x i16>,i64)
define i64 @vector_input_probe_8(ptr %out,ptr %input,i64 %salt) {
entry:
 %v = load <64 x i16>,ptr %input,align 1
 %local = call i64 @vector_input_body_8(i64 1311768467463790320,i64 18364758544493064720,i64 1234605616436508552,i64 12379552201711258095,i64 9756277981056907928,i64 1161981756646125696,<64 x i16> %v,i64 %salt)
 %external = call i64 @vector_input_provider_8(i64 1311768467463790320,i64 18364758544493064720,i64 1234605616436508552,i64 12379552201711258095,i64 9756277981056907928,i64 1161981756646125696,<64 x i16> %v,i64 %salt)
 store i64 %local,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %external,ptr %next,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc i64 @vector_input_body_9(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,<64 x i16> %v,i64 %salt) noinline {
entry:
 %s0 = xor i64 %salt,%p0
 %s1 = xor i64 %s0,%p1
 %s2 = xor i64 %s1,%p2
 %s3 = xor i64 %s2,%p3
 %s4 = xor i64 %s3,%p4
 %s5 = xor i64 %s4,%p5
 %lane0 = extractelement <64 x i16> %v,i64 0
 %word0 = zext i16 %lane0 to i64
 %mix0 = mul i64 %s5,1099511628211
 %r0 = xor i64 %mix0,%word0
 %lane1 = extractelement <64 x i16> %v,i64 1
 %word1 = zext i16 %lane1 to i64
 %mix1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %mix1,%word1
 %lane2 = extractelement <64 x i16> %v,i64 2
 %word2 = zext i16 %lane2 to i64
 %mix2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %mix2,%word2
 %lane3 = extractelement <64 x i16> %v,i64 3
 %word3 = zext i16 %lane3 to i64
 %mix3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %mix3,%word3
 %lane4 = extractelement <64 x i16> %v,i64 4
 %word4 = zext i16 %lane4 to i64
 %mix4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %mix4,%word4
 %lane5 = extractelement <64 x i16> %v,i64 5
 %word5 = zext i16 %lane5 to i64
 %mix5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %mix5,%word5
 %lane6 = extractelement <64 x i16> %v,i64 6
 %word6 = zext i16 %lane6 to i64
 %mix6 = mul i64 %r5,1099511628211
 %r6 = xor i64 %mix6,%word6
 %lane7 = extractelement <64 x i16> %v,i64 7
 %word7 = zext i16 %lane7 to i64
 %mix7 = mul i64 %r6,1099511628211
 %r7 = xor i64 %mix7,%word7
 %lane8 = extractelement <64 x i16> %v,i64 8
 %word8 = zext i16 %lane8 to i64
 %mix8 = mul i64 %r7,1099511628211
 %r8 = xor i64 %mix8,%word8
 %lane9 = extractelement <64 x i16> %v,i64 9
 %word9 = zext i16 %lane9 to i64
 %mix9 = mul i64 %r8,1099511628211
 %r9 = xor i64 %mix9,%word9
 %lane10 = extractelement <64 x i16> %v,i64 10
 %word10 = zext i16 %lane10 to i64
 %mix10 = mul i64 %r9,1099511628211
 %r10 = xor i64 %mix10,%word10
 %lane11 = extractelement <64 x i16> %v,i64 11
 %word11 = zext i16 %lane11 to i64
 %mix11 = mul i64 %r10,1099511628211
 %r11 = xor i64 %mix11,%word11
 %lane12 = extractelement <64 x i16> %v,i64 12
 %word12 = zext i16 %lane12 to i64
 %mix12 = mul i64 %r11,1099511628211
 %r12 = xor i64 %mix12,%word12
 %lane13 = extractelement <64 x i16> %v,i64 13
 %word13 = zext i16 %lane13 to i64
 %mix13 = mul i64 %r12,1099511628211
 %r13 = xor i64 %mix13,%word13
 %lane14 = extractelement <64 x i16> %v,i64 14
 %word14 = zext i16 %lane14 to i64
 %mix14 = mul i64 %r13,1099511628211
 %r14 = xor i64 %mix14,%word14
 %lane15 = extractelement <64 x i16> %v,i64 15
 %word15 = zext i16 %lane15 to i64
 %mix15 = mul i64 %r14,1099511628211
 %r15 = xor i64 %mix15,%word15
 %lane16 = extractelement <64 x i16> %v,i64 16
 %word16 = zext i16 %lane16 to i64
 %mix16 = mul i64 %r15,1099511628211
 %r16 = xor i64 %mix16,%word16
 %lane17 = extractelement <64 x i16> %v,i64 17
 %word17 = zext i16 %lane17 to i64
 %mix17 = mul i64 %r16,1099511628211
 %r17 = xor i64 %mix17,%word17
 %lane18 = extractelement <64 x i16> %v,i64 18
 %word18 = zext i16 %lane18 to i64
 %mix18 = mul i64 %r17,1099511628211
 %r18 = xor i64 %mix18,%word18
 %lane19 = extractelement <64 x i16> %v,i64 19
 %word19 = zext i16 %lane19 to i64
 %mix19 = mul i64 %r18,1099511628211
 %r19 = xor i64 %mix19,%word19
 %lane20 = extractelement <64 x i16> %v,i64 20
 %word20 = zext i16 %lane20 to i64
 %mix20 = mul i64 %r19,1099511628211
 %r20 = xor i64 %mix20,%word20
 %lane21 = extractelement <64 x i16> %v,i64 21
 %word21 = zext i16 %lane21 to i64
 %mix21 = mul i64 %r20,1099511628211
 %r21 = xor i64 %mix21,%word21
 %lane22 = extractelement <64 x i16> %v,i64 22
 %word22 = zext i16 %lane22 to i64
 %mix22 = mul i64 %r21,1099511628211
 %r22 = xor i64 %mix22,%word22
 %lane23 = extractelement <64 x i16> %v,i64 23
 %word23 = zext i16 %lane23 to i64
 %mix23 = mul i64 %r22,1099511628211
 %r23 = xor i64 %mix23,%word23
 %lane24 = extractelement <64 x i16> %v,i64 24
 %word24 = zext i16 %lane24 to i64
 %mix24 = mul i64 %r23,1099511628211
 %r24 = xor i64 %mix24,%word24
 %lane25 = extractelement <64 x i16> %v,i64 25
 %word25 = zext i16 %lane25 to i64
 %mix25 = mul i64 %r24,1099511628211
 %r25 = xor i64 %mix25,%word25
 %lane26 = extractelement <64 x i16> %v,i64 26
 %word26 = zext i16 %lane26 to i64
 %mix26 = mul i64 %r25,1099511628211
 %r26 = xor i64 %mix26,%word26
 %lane27 = extractelement <64 x i16> %v,i64 27
 %word27 = zext i16 %lane27 to i64
 %mix27 = mul i64 %r26,1099511628211
 %r27 = xor i64 %mix27,%word27
 %lane28 = extractelement <64 x i16> %v,i64 28
 %word28 = zext i16 %lane28 to i64
 %mix28 = mul i64 %r27,1099511628211
 %r28 = xor i64 %mix28,%word28
 %lane29 = extractelement <64 x i16> %v,i64 29
 %word29 = zext i16 %lane29 to i64
 %mix29 = mul i64 %r28,1099511628211
 %r29 = xor i64 %mix29,%word29
 %lane30 = extractelement <64 x i16> %v,i64 30
 %word30 = zext i16 %lane30 to i64
 %mix30 = mul i64 %r29,1099511628211
 %r30 = xor i64 %mix30,%word30
 %lane31 = extractelement <64 x i16> %v,i64 31
 %word31 = zext i16 %lane31 to i64
 %mix31 = mul i64 %r30,1099511628211
 %r31 = xor i64 %mix31,%word31
 %lane32 = extractelement <64 x i16> %v,i64 32
 %word32 = zext i16 %lane32 to i64
 %mix32 = mul i64 %r31,1099511628211
 %r32 = xor i64 %mix32,%word32
 %lane33 = extractelement <64 x i16> %v,i64 33
 %word33 = zext i16 %lane33 to i64
 %mix33 = mul i64 %r32,1099511628211
 %r33 = xor i64 %mix33,%word33
 %lane34 = extractelement <64 x i16> %v,i64 34
 %word34 = zext i16 %lane34 to i64
 %mix34 = mul i64 %r33,1099511628211
 %r34 = xor i64 %mix34,%word34
 %lane35 = extractelement <64 x i16> %v,i64 35
 %word35 = zext i16 %lane35 to i64
 %mix35 = mul i64 %r34,1099511628211
 %r35 = xor i64 %mix35,%word35
 %lane36 = extractelement <64 x i16> %v,i64 36
 %word36 = zext i16 %lane36 to i64
 %mix36 = mul i64 %r35,1099511628211
 %r36 = xor i64 %mix36,%word36
 %lane37 = extractelement <64 x i16> %v,i64 37
 %word37 = zext i16 %lane37 to i64
 %mix37 = mul i64 %r36,1099511628211
 %r37 = xor i64 %mix37,%word37
 %lane38 = extractelement <64 x i16> %v,i64 38
 %word38 = zext i16 %lane38 to i64
 %mix38 = mul i64 %r37,1099511628211
 %r38 = xor i64 %mix38,%word38
 %lane39 = extractelement <64 x i16> %v,i64 39
 %word39 = zext i16 %lane39 to i64
 %mix39 = mul i64 %r38,1099511628211
 %r39 = xor i64 %mix39,%word39
 %lane40 = extractelement <64 x i16> %v,i64 40
 %word40 = zext i16 %lane40 to i64
 %mix40 = mul i64 %r39,1099511628211
 %r40 = xor i64 %mix40,%word40
 %lane41 = extractelement <64 x i16> %v,i64 41
 %word41 = zext i16 %lane41 to i64
 %mix41 = mul i64 %r40,1099511628211
 %r41 = xor i64 %mix41,%word41
 %lane42 = extractelement <64 x i16> %v,i64 42
 %word42 = zext i16 %lane42 to i64
 %mix42 = mul i64 %r41,1099511628211
 %r42 = xor i64 %mix42,%word42
 %lane43 = extractelement <64 x i16> %v,i64 43
 %word43 = zext i16 %lane43 to i64
 %mix43 = mul i64 %r42,1099511628211
 %r43 = xor i64 %mix43,%word43
 %lane44 = extractelement <64 x i16> %v,i64 44
 %word44 = zext i16 %lane44 to i64
 %mix44 = mul i64 %r43,1099511628211
 %r44 = xor i64 %mix44,%word44
 %lane45 = extractelement <64 x i16> %v,i64 45
 %word45 = zext i16 %lane45 to i64
 %mix45 = mul i64 %r44,1099511628211
 %r45 = xor i64 %mix45,%word45
 %lane46 = extractelement <64 x i16> %v,i64 46
 %word46 = zext i16 %lane46 to i64
 %mix46 = mul i64 %r45,1099511628211
 %r46 = xor i64 %mix46,%word46
 %lane47 = extractelement <64 x i16> %v,i64 47
 %word47 = zext i16 %lane47 to i64
 %mix47 = mul i64 %r46,1099511628211
 %r47 = xor i64 %mix47,%word47
 %lane48 = extractelement <64 x i16> %v,i64 48
 %word48 = zext i16 %lane48 to i64
 %mix48 = mul i64 %r47,1099511628211
 %r48 = xor i64 %mix48,%word48
 %lane49 = extractelement <64 x i16> %v,i64 49
 %word49 = zext i16 %lane49 to i64
 %mix49 = mul i64 %r48,1099511628211
 %r49 = xor i64 %mix49,%word49
 %lane50 = extractelement <64 x i16> %v,i64 50
 %word50 = zext i16 %lane50 to i64
 %mix50 = mul i64 %r49,1099511628211
 %r50 = xor i64 %mix50,%word50
 %lane51 = extractelement <64 x i16> %v,i64 51
 %word51 = zext i16 %lane51 to i64
 %mix51 = mul i64 %r50,1099511628211
 %r51 = xor i64 %mix51,%word51
 %lane52 = extractelement <64 x i16> %v,i64 52
 %word52 = zext i16 %lane52 to i64
 %mix52 = mul i64 %r51,1099511628211
 %r52 = xor i64 %mix52,%word52
 %lane53 = extractelement <64 x i16> %v,i64 53
 %word53 = zext i16 %lane53 to i64
 %mix53 = mul i64 %r52,1099511628211
 %r53 = xor i64 %mix53,%word53
 %lane54 = extractelement <64 x i16> %v,i64 54
 %word54 = zext i16 %lane54 to i64
 %mix54 = mul i64 %r53,1099511628211
 %r54 = xor i64 %mix54,%word54
 %lane55 = extractelement <64 x i16> %v,i64 55
 %word55 = zext i16 %lane55 to i64
 %mix55 = mul i64 %r54,1099511628211
 %r55 = xor i64 %mix55,%word55
 %lane56 = extractelement <64 x i16> %v,i64 56
 %word56 = zext i16 %lane56 to i64
 %mix56 = mul i64 %r55,1099511628211
 %r56 = xor i64 %mix56,%word56
 %lane57 = extractelement <64 x i16> %v,i64 57
 %word57 = zext i16 %lane57 to i64
 %mix57 = mul i64 %r56,1099511628211
 %r57 = xor i64 %mix57,%word57
 %lane58 = extractelement <64 x i16> %v,i64 58
 %word58 = zext i16 %lane58 to i64
 %mix58 = mul i64 %r57,1099511628211
 %r58 = xor i64 %mix58,%word58
 %lane59 = extractelement <64 x i16> %v,i64 59
 %word59 = zext i16 %lane59 to i64
 %mix59 = mul i64 %r58,1099511628211
 %r59 = xor i64 %mix59,%word59
 %lane60 = extractelement <64 x i16> %v,i64 60
 %word60 = zext i16 %lane60 to i64
 %mix60 = mul i64 %r59,1099511628211
 %r60 = xor i64 %mix60,%word60
 %lane61 = extractelement <64 x i16> %v,i64 61
 %word61 = zext i16 %lane61 to i64
 %mix61 = mul i64 %r60,1099511628211
 %r61 = xor i64 %mix61,%word61
 %lane62 = extractelement <64 x i16> %v,i64 62
 %word62 = zext i16 %lane62 to i64
 %mix62 = mul i64 %r61,1099511628211
 %r62 = xor i64 %mix62,%word62
 %lane63 = extractelement <64 x i16> %v,i64 63
 %word63 = zext i16 %lane63 to i64
 %mix63 = mul i64 %r62,1099511628211
 %r63 = xor i64 %mix63,%word63
 ret i64 %r63
}
declare i64 @vector_input_provider_9(i64,i64,i64,i64,i64,i64,<64 x i16>,i64)
define i64 @vector_input_probe_9(ptr %out,ptr %input,i64 %salt) {
entry:
 %v = load <64 x i16>,ptr %input,align 1
 %local = call fastcc i64 @vector_input_body_9(i64 1311768467463790320,i64 18364758544493064720,i64 1234605616436508552,i64 12379552201711258095,i64 9756277981056907928,i64 1161981756646125696,<64 x i16> %v,i64 %salt)
 %external = call i64 @vector_input_provider_9(i64 1311768467463790320,i64 18364758544493064720,i64 1234605616436508552,i64 12379552201711258095,i64 9756277981056907928,i64 1161981756646125696,<64 x i16> %v,i64 %salt)
 store i64 %local,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %external,ptr %next,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define i64 @vector_input_body_10(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,<8 x i32> %v,i64 %salt) noinline {
entry:
 %s0 = xor i64 %salt,%p0
 %s1 = xor i64 %s0,%p1
 %s2 = xor i64 %s1,%p2
 %s3 = xor i64 %s2,%p3
 %s4 = xor i64 %s3,%p4
 %s5 = xor i64 %s4,%p5
 %lane0 = extractelement <8 x i32> %v,i64 0
 %word0 = zext i32 %lane0 to i64
 %mix0 = mul i64 %s5,1099511628211
 %r0 = xor i64 %mix0,%word0
 %lane1 = extractelement <8 x i32> %v,i64 1
 %word1 = zext i32 %lane1 to i64
 %mix1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %mix1,%word1
 %lane2 = extractelement <8 x i32> %v,i64 2
 %word2 = zext i32 %lane2 to i64
 %mix2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %mix2,%word2
 %lane3 = extractelement <8 x i32> %v,i64 3
 %word3 = zext i32 %lane3 to i64
 %mix3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %mix3,%word3
 %lane4 = extractelement <8 x i32> %v,i64 4
 %word4 = zext i32 %lane4 to i64
 %mix4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %mix4,%word4
 %lane5 = extractelement <8 x i32> %v,i64 5
 %word5 = zext i32 %lane5 to i64
 %mix5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %mix5,%word5
 %lane6 = extractelement <8 x i32> %v,i64 6
 %word6 = zext i32 %lane6 to i64
 %mix6 = mul i64 %r5,1099511628211
 %r6 = xor i64 %mix6,%word6
 %lane7 = extractelement <8 x i32> %v,i64 7
 %word7 = zext i32 %lane7 to i64
 %mix7 = mul i64 %r6,1099511628211
 %r7 = xor i64 %mix7,%word7
 ret i64 %r7
}
declare i64 @vector_input_provider_10(i64,i64,i64,i64,i64,i64,<8 x i32>,i64)
define i64 @vector_input_probe_10(ptr %out,ptr %input,i64 %salt) {
entry:
 %v = load <8 x i32>,ptr %input,align 1
 %local = call i64 @vector_input_body_10(i64 1311768467463790320,i64 18364758544493064720,i64 1234605616436508552,i64 12379552201711258095,i64 9756277981056907928,i64 1161981756646125696,<8 x i32> %v,i64 %salt)
 %external = call i64 @vector_input_provider_10(i64 1311768467463790320,i64 18364758544493064720,i64 1234605616436508552,i64 12379552201711258095,i64 9756277981056907928,i64 1161981756646125696,<8 x i32> %v,i64 %salt)
 store i64 %local,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %external,ptr %next,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc i64 @vector_input_body_11(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,<8 x i32> %v,i64 %salt) noinline {
entry:
 %s0 = xor i64 %salt,%p0
 %s1 = xor i64 %s0,%p1
 %s2 = xor i64 %s1,%p2
 %s3 = xor i64 %s2,%p3
 %s4 = xor i64 %s3,%p4
 %s5 = xor i64 %s4,%p5
 %lane0 = extractelement <8 x i32> %v,i64 0
 %word0 = zext i32 %lane0 to i64
 %mix0 = mul i64 %s5,1099511628211
 %r0 = xor i64 %mix0,%word0
 %lane1 = extractelement <8 x i32> %v,i64 1
 %word1 = zext i32 %lane1 to i64
 %mix1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %mix1,%word1
 %lane2 = extractelement <8 x i32> %v,i64 2
 %word2 = zext i32 %lane2 to i64
 %mix2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %mix2,%word2
 %lane3 = extractelement <8 x i32> %v,i64 3
 %word3 = zext i32 %lane3 to i64
 %mix3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %mix3,%word3
 %lane4 = extractelement <8 x i32> %v,i64 4
 %word4 = zext i32 %lane4 to i64
 %mix4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %mix4,%word4
 %lane5 = extractelement <8 x i32> %v,i64 5
 %word5 = zext i32 %lane5 to i64
 %mix5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %mix5,%word5
 %lane6 = extractelement <8 x i32> %v,i64 6
 %word6 = zext i32 %lane6 to i64
 %mix6 = mul i64 %r5,1099511628211
 %r6 = xor i64 %mix6,%word6
 %lane7 = extractelement <8 x i32> %v,i64 7
 %word7 = zext i32 %lane7 to i64
 %mix7 = mul i64 %r6,1099511628211
 %r7 = xor i64 %mix7,%word7
 ret i64 %r7
}
declare i64 @vector_input_provider_11(i64,i64,i64,i64,i64,i64,<8 x i32>,i64)
define i64 @vector_input_probe_11(ptr %out,ptr %input,i64 %salt) {
entry:
 %v = load <8 x i32>,ptr %input,align 1
 %local = call fastcc i64 @vector_input_body_11(i64 1311768467463790320,i64 18364758544493064720,i64 1234605616436508552,i64 12379552201711258095,i64 9756277981056907928,i64 1161981756646125696,<8 x i32> %v,i64 %salt)
 %external = call i64 @vector_input_provider_11(i64 1311768467463790320,i64 18364758544493064720,i64 1234605616436508552,i64 12379552201711258095,i64 9756277981056907928,i64 1161981756646125696,<8 x i32> %v,i64 %salt)
 store i64 %local,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %external,ptr %next,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define i64 @vector_input_body_12(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,<16 x i32> %v,i64 %salt) noinline {
entry:
 %s0 = xor i64 %salt,%p0
 %s1 = xor i64 %s0,%p1
 %s2 = xor i64 %s1,%p2
 %s3 = xor i64 %s2,%p3
 %s4 = xor i64 %s3,%p4
 %s5 = xor i64 %s4,%p5
 %lane0 = extractelement <16 x i32> %v,i64 0
 %word0 = zext i32 %lane0 to i64
 %mix0 = mul i64 %s5,1099511628211
 %r0 = xor i64 %mix0,%word0
 %lane1 = extractelement <16 x i32> %v,i64 1
 %word1 = zext i32 %lane1 to i64
 %mix1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %mix1,%word1
 %lane2 = extractelement <16 x i32> %v,i64 2
 %word2 = zext i32 %lane2 to i64
 %mix2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %mix2,%word2
 %lane3 = extractelement <16 x i32> %v,i64 3
 %word3 = zext i32 %lane3 to i64
 %mix3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %mix3,%word3
 %lane4 = extractelement <16 x i32> %v,i64 4
 %word4 = zext i32 %lane4 to i64
 %mix4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %mix4,%word4
 %lane5 = extractelement <16 x i32> %v,i64 5
 %word5 = zext i32 %lane5 to i64
 %mix5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %mix5,%word5
 %lane6 = extractelement <16 x i32> %v,i64 6
 %word6 = zext i32 %lane6 to i64
 %mix6 = mul i64 %r5,1099511628211
 %r6 = xor i64 %mix6,%word6
 %lane7 = extractelement <16 x i32> %v,i64 7
 %word7 = zext i32 %lane7 to i64
 %mix7 = mul i64 %r6,1099511628211
 %r7 = xor i64 %mix7,%word7
 %lane8 = extractelement <16 x i32> %v,i64 8
 %word8 = zext i32 %lane8 to i64
 %mix8 = mul i64 %r7,1099511628211
 %r8 = xor i64 %mix8,%word8
 %lane9 = extractelement <16 x i32> %v,i64 9
 %word9 = zext i32 %lane9 to i64
 %mix9 = mul i64 %r8,1099511628211
 %r9 = xor i64 %mix9,%word9
 %lane10 = extractelement <16 x i32> %v,i64 10
 %word10 = zext i32 %lane10 to i64
 %mix10 = mul i64 %r9,1099511628211
 %r10 = xor i64 %mix10,%word10
 %lane11 = extractelement <16 x i32> %v,i64 11
 %word11 = zext i32 %lane11 to i64
 %mix11 = mul i64 %r10,1099511628211
 %r11 = xor i64 %mix11,%word11
 %lane12 = extractelement <16 x i32> %v,i64 12
 %word12 = zext i32 %lane12 to i64
 %mix12 = mul i64 %r11,1099511628211
 %r12 = xor i64 %mix12,%word12
 %lane13 = extractelement <16 x i32> %v,i64 13
 %word13 = zext i32 %lane13 to i64
 %mix13 = mul i64 %r12,1099511628211
 %r13 = xor i64 %mix13,%word13
 %lane14 = extractelement <16 x i32> %v,i64 14
 %word14 = zext i32 %lane14 to i64
 %mix14 = mul i64 %r13,1099511628211
 %r14 = xor i64 %mix14,%word14
 %lane15 = extractelement <16 x i32> %v,i64 15
 %word15 = zext i32 %lane15 to i64
 %mix15 = mul i64 %r14,1099511628211
 %r15 = xor i64 %mix15,%word15
 ret i64 %r15
}
declare i64 @vector_input_provider_12(i64,i64,i64,i64,i64,i64,<16 x i32>,i64)
define i64 @vector_input_probe_12(ptr %out,ptr %input,i64 %salt) {
entry:
 %v = load <16 x i32>,ptr %input,align 1
 %local = call i64 @vector_input_body_12(i64 1311768467463790320,i64 18364758544493064720,i64 1234605616436508552,i64 12379552201711258095,i64 9756277981056907928,i64 1161981756646125696,<16 x i32> %v,i64 %salt)
 %external = call i64 @vector_input_provider_12(i64 1311768467463790320,i64 18364758544493064720,i64 1234605616436508552,i64 12379552201711258095,i64 9756277981056907928,i64 1161981756646125696,<16 x i32> %v,i64 %salt)
 store i64 %local,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %external,ptr %next,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc i64 @vector_input_body_13(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,<16 x i32> %v,i64 %salt) noinline {
entry:
 %s0 = xor i64 %salt,%p0
 %s1 = xor i64 %s0,%p1
 %s2 = xor i64 %s1,%p2
 %s3 = xor i64 %s2,%p3
 %s4 = xor i64 %s3,%p4
 %s5 = xor i64 %s4,%p5
 %lane0 = extractelement <16 x i32> %v,i64 0
 %word0 = zext i32 %lane0 to i64
 %mix0 = mul i64 %s5,1099511628211
 %r0 = xor i64 %mix0,%word0
 %lane1 = extractelement <16 x i32> %v,i64 1
 %word1 = zext i32 %lane1 to i64
 %mix1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %mix1,%word1
 %lane2 = extractelement <16 x i32> %v,i64 2
 %word2 = zext i32 %lane2 to i64
 %mix2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %mix2,%word2
 %lane3 = extractelement <16 x i32> %v,i64 3
 %word3 = zext i32 %lane3 to i64
 %mix3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %mix3,%word3
 %lane4 = extractelement <16 x i32> %v,i64 4
 %word4 = zext i32 %lane4 to i64
 %mix4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %mix4,%word4
 %lane5 = extractelement <16 x i32> %v,i64 5
 %word5 = zext i32 %lane5 to i64
 %mix5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %mix5,%word5
 %lane6 = extractelement <16 x i32> %v,i64 6
 %word6 = zext i32 %lane6 to i64
 %mix6 = mul i64 %r5,1099511628211
 %r6 = xor i64 %mix6,%word6
 %lane7 = extractelement <16 x i32> %v,i64 7
 %word7 = zext i32 %lane7 to i64
 %mix7 = mul i64 %r6,1099511628211
 %r7 = xor i64 %mix7,%word7
 %lane8 = extractelement <16 x i32> %v,i64 8
 %word8 = zext i32 %lane8 to i64
 %mix8 = mul i64 %r7,1099511628211
 %r8 = xor i64 %mix8,%word8
 %lane9 = extractelement <16 x i32> %v,i64 9
 %word9 = zext i32 %lane9 to i64
 %mix9 = mul i64 %r8,1099511628211
 %r9 = xor i64 %mix9,%word9
 %lane10 = extractelement <16 x i32> %v,i64 10
 %word10 = zext i32 %lane10 to i64
 %mix10 = mul i64 %r9,1099511628211
 %r10 = xor i64 %mix10,%word10
 %lane11 = extractelement <16 x i32> %v,i64 11
 %word11 = zext i32 %lane11 to i64
 %mix11 = mul i64 %r10,1099511628211
 %r11 = xor i64 %mix11,%word11
 %lane12 = extractelement <16 x i32> %v,i64 12
 %word12 = zext i32 %lane12 to i64
 %mix12 = mul i64 %r11,1099511628211
 %r12 = xor i64 %mix12,%word12
 %lane13 = extractelement <16 x i32> %v,i64 13
 %word13 = zext i32 %lane13 to i64
 %mix13 = mul i64 %r12,1099511628211
 %r13 = xor i64 %mix13,%word13
 %lane14 = extractelement <16 x i32> %v,i64 14
 %word14 = zext i32 %lane14 to i64
 %mix14 = mul i64 %r13,1099511628211
 %r14 = xor i64 %mix14,%word14
 %lane15 = extractelement <16 x i32> %v,i64 15
 %word15 = zext i32 %lane15 to i64
 %mix15 = mul i64 %r14,1099511628211
 %r15 = xor i64 %mix15,%word15
 ret i64 %r15
}
declare i64 @vector_input_provider_13(i64,i64,i64,i64,i64,i64,<16 x i32>,i64)
define i64 @vector_input_probe_13(ptr %out,ptr %input,i64 %salt) {
entry:
 %v = load <16 x i32>,ptr %input,align 1
 %local = call fastcc i64 @vector_input_body_13(i64 1311768467463790320,i64 18364758544493064720,i64 1234605616436508552,i64 12379552201711258095,i64 9756277981056907928,i64 1161981756646125696,<16 x i32> %v,i64 %salt)
 %external = call i64 @vector_input_provider_13(i64 1311768467463790320,i64 18364758544493064720,i64 1234605616436508552,i64 12379552201711258095,i64 9756277981056907928,i64 1161981756646125696,<16 x i32> %v,i64 %salt)
 store i64 %local,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %external,ptr %next,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define i64 @vector_input_body_14(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,<32 x i32> %v,i64 %salt) noinline {
entry:
 %s0 = xor i64 %salt,%p0
 %s1 = xor i64 %s0,%p1
 %s2 = xor i64 %s1,%p2
 %s3 = xor i64 %s2,%p3
 %s4 = xor i64 %s3,%p4
 %s5 = xor i64 %s4,%p5
 %lane0 = extractelement <32 x i32> %v,i64 0
 %word0 = zext i32 %lane0 to i64
 %mix0 = mul i64 %s5,1099511628211
 %r0 = xor i64 %mix0,%word0
 %lane1 = extractelement <32 x i32> %v,i64 1
 %word1 = zext i32 %lane1 to i64
 %mix1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %mix1,%word1
 %lane2 = extractelement <32 x i32> %v,i64 2
 %word2 = zext i32 %lane2 to i64
 %mix2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %mix2,%word2
 %lane3 = extractelement <32 x i32> %v,i64 3
 %word3 = zext i32 %lane3 to i64
 %mix3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %mix3,%word3
 %lane4 = extractelement <32 x i32> %v,i64 4
 %word4 = zext i32 %lane4 to i64
 %mix4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %mix4,%word4
 %lane5 = extractelement <32 x i32> %v,i64 5
 %word5 = zext i32 %lane5 to i64
 %mix5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %mix5,%word5
 %lane6 = extractelement <32 x i32> %v,i64 6
 %word6 = zext i32 %lane6 to i64
 %mix6 = mul i64 %r5,1099511628211
 %r6 = xor i64 %mix6,%word6
 %lane7 = extractelement <32 x i32> %v,i64 7
 %word7 = zext i32 %lane7 to i64
 %mix7 = mul i64 %r6,1099511628211
 %r7 = xor i64 %mix7,%word7
 %lane8 = extractelement <32 x i32> %v,i64 8
 %word8 = zext i32 %lane8 to i64
 %mix8 = mul i64 %r7,1099511628211
 %r8 = xor i64 %mix8,%word8
 %lane9 = extractelement <32 x i32> %v,i64 9
 %word9 = zext i32 %lane9 to i64
 %mix9 = mul i64 %r8,1099511628211
 %r9 = xor i64 %mix9,%word9
 %lane10 = extractelement <32 x i32> %v,i64 10
 %word10 = zext i32 %lane10 to i64
 %mix10 = mul i64 %r9,1099511628211
 %r10 = xor i64 %mix10,%word10
 %lane11 = extractelement <32 x i32> %v,i64 11
 %word11 = zext i32 %lane11 to i64
 %mix11 = mul i64 %r10,1099511628211
 %r11 = xor i64 %mix11,%word11
 %lane12 = extractelement <32 x i32> %v,i64 12
 %word12 = zext i32 %lane12 to i64
 %mix12 = mul i64 %r11,1099511628211
 %r12 = xor i64 %mix12,%word12
 %lane13 = extractelement <32 x i32> %v,i64 13
 %word13 = zext i32 %lane13 to i64
 %mix13 = mul i64 %r12,1099511628211
 %r13 = xor i64 %mix13,%word13
 %lane14 = extractelement <32 x i32> %v,i64 14
 %word14 = zext i32 %lane14 to i64
 %mix14 = mul i64 %r13,1099511628211
 %r14 = xor i64 %mix14,%word14
 %lane15 = extractelement <32 x i32> %v,i64 15
 %word15 = zext i32 %lane15 to i64
 %mix15 = mul i64 %r14,1099511628211
 %r15 = xor i64 %mix15,%word15
 %lane16 = extractelement <32 x i32> %v,i64 16
 %word16 = zext i32 %lane16 to i64
 %mix16 = mul i64 %r15,1099511628211
 %r16 = xor i64 %mix16,%word16
 %lane17 = extractelement <32 x i32> %v,i64 17
 %word17 = zext i32 %lane17 to i64
 %mix17 = mul i64 %r16,1099511628211
 %r17 = xor i64 %mix17,%word17
 %lane18 = extractelement <32 x i32> %v,i64 18
 %word18 = zext i32 %lane18 to i64
 %mix18 = mul i64 %r17,1099511628211
 %r18 = xor i64 %mix18,%word18
 %lane19 = extractelement <32 x i32> %v,i64 19
 %word19 = zext i32 %lane19 to i64
 %mix19 = mul i64 %r18,1099511628211
 %r19 = xor i64 %mix19,%word19
 %lane20 = extractelement <32 x i32> %v,i64 20
 %word20 = zext i32 %lane20 to i64
 %mix20 = mul i64 %r19,1099511628211
 %r20 = xor i64 %mix20,%word20
 %lane21 = extractelement <32 x i32> %v,i64 21
 %word21 = zext i32 %lane21 to i64
 %mix21 = mul i64 %r20,1099511628211
 %r21 = xor i64 %mix21,%word21
 %lane22 = extractelement <32 x i32> %v,i64 22
 %word22 = zext i32 %lane22 to i64
 %mix22 = mul i64 %r21,1099511628211
 %r22 = xor i64 %mix22,%word22
 %lane23 = extractelement <32 x i32> %v,i64 23
 %word23 = zext i32 %lane23 to i64
 %mix23 = mul i64 %r22,1099511628211
 %r23 = xor i64 %mix23,%word23
 %lane24 = extractelement <32 x i32> %v,i64 24
 %word24 = zext i32 %lane24 to i64
 %mix24 = mul i64 %r23,1099511628211
 %r24 = xor i64 %mix24,%word24
 %lane25 = extractelement <32 x i32> %v,i64 25
 %word25 = zext i32 %lane25 to i64
 %mix25 = mul i64 %r24,1099511628211
 %r25 = xor i64 %mix25,%word25
 %lane26 = extractelement <32 x i32> %v,i64 26
 %word26 = zext i32 %lane26 to i64
 %mix26 = mul i64 %r25,1099511628211
 %r26 = xor i64 %mix26,%word26
 %lane27 = extractelement <32 x i32> %v,i64 27
 %word27 = zext i32 %lane27 to i64
 %mix27 = mul i64 %r26,1099511628211
 %r27 = xor i64 %mix27,%word27
 %lane28 = extractelement <32 x i32> %v,i64 28
 %word28 = zext i32 %lane28 to i64
 %mix28 = mul i64 %r27,1099511628211
 %r28 = xor i64 %mix28,%word28
 %lane29 = extractelement <32 x i32> %v,i64 29
 %word29 = zext i32 %lane29 to i64
 %mix29 = mul i64 %r28,1099511628211
 %r29 = xor i64 %mix29,%word29
 %lane30 = extractelement <32 x i32> %v,i64 30
 %word30 = zext i32 %lane30 to i64
 %mix30 = mul i64 %r29,1099511628211
 %r30 = xor i64 %mix30,%word30
 %lane31 = extractelement <32 x i32> %v,i64 31
 %word31 = zext i32 %lane31 to i64
 %mix31 = mul i64 %r30,1099511628211
 %r31 = xor i64 %mix31,%word31
 ret i64 %r31
}
declare i64 @vector_input_provider_14(i64,i64,i64,i64,i64,i64,<32 x i32>,i64)
define i64 @vector_input_probe_14(ptr %out,ptr %input,i64 %salt) {
entry:
 %v = load <32 x i32>,ptr %input,align 1
 %local = call i64 @vector_input_body_14(i64 1311768467463790320,i64 18364758544493064720,i64 1234605616436508552,i64 12379552201711258095,i64 9756277981056907928,i64 1161981756646125696,<32 x i32> %v,i64 %salt)
 %external = call i64 @vector_input_provider_14(i64 1311768467463790320,i64 18364758544493064720,i64 1234605616436508552,i64 12379552201711258095,i64 9756277981056907928,i64 1161981756646125696,<32 x i32> %v,i64 %salt)
 store i64 %local,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %external,ptr %next,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc i64 @vector_input_body_15(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,<32 x i32> %v,i64 %salt) noinline {
entry:
 %s0 = xor i64 %salt,%p0
 %s1 = xor i64 %s0,%p1
 %s2 = xor i64 %s1,%p2
 %s3 = xor i64 %s2,%p3
 %s4 = xor i64 %s3,%p4
 %s5 = xor i64 %s4,%p5
 %lane0 = extractelement <32 x i32> %v,i64 0
 %word0 = zext i32 %lane0 to i64
 %mix0 = mul i64 %s5,1099511628211
 %r0 = xor i64 %mix0,%word0
 %lane1 = extractelement <32 x i32> %v,i64 1
 %word1 = zext i32 %lane1 to i64
 %mix1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %mix1,%word1
 %lane2 = extractelement <32 x i32> %v,i64 2
 %word2 = zext i32 %lane2 to i64
 %mix2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %mix2,%word2
 %lane3 = extractelement <32 x i32> %v,i64 3
 %word3 = zext i32 %lane3 to i64
 %mix3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %mix3,%word3
 %lane4 = extractelement <32 x i32> %v,i64 4
 %word4 = zext i32 %lane4 to i64
 %mix4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %mix4,%word4
 %lane5 = extractelement <32 x i32> %v,i64 5
 %word5 = zext i32 %lane5 to i64
 %mix5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %mix5,%word5
 %lane6 = extractelement <32 x i32> %v,i64 6
 %word6 = zext i32 %lane6 to i64
 %mix6 = mul i64 %r5,1099511628211
 %r6 = xor i64 %mix6,%word6
 %lane7 = extractelement <32 x i32> %v,i64 7
 %word7 = zext i32 %lane7 to i64
 %mix7 = mul i64 %r6,1099511628211
 %r7 = xor i64 %mix7,%word7
 %lane8 = extractelement <32 x i32> %v,i64 8
 %word8 = zext i32 %lane8 to i64
 %mix8 = mul i64 %r7,1099511628211
 %r8 = xor i64 %mix8,%word8
 %lane9 = extractelement <32 x i32> %v,i64 9
 %word9 = zext i32 %lane9 to i64
 %mix9 = mul i64 %r8,1099511628211
 %r9 = xor i64 %mix9,%word9
 %lane10 = extractelement <32 x i32> %v,i64 10
 %word10 = zext i32 %lane10 to i64
 %mix10 = mul i64 %r9,1099511628211
 %r10 = xor i64 %mix10,%word10
 %lane11 = extractelement <32 x i32> %v,i64 11
 %word11 = zext i32 %lane11 to i64
 %mix11 = mul i64 %r10,1099511628211
 %r11 = xor i64 %mix11,%word11
 %lane12 = extractelement <32 x i32> %v,i64 12
 %word12 = zext i32 %lane12 to i64
 %mix12 = mul i64 %r11,1099511628211
 %r12 = xor i64 %mix12,%word12
 %lane13 = extractelement <32 x i32> %v,i64 13
 %word13 = zext i32 %lane13 to i64
 %mix13 = mul i64 %r12,1099511628211
 %r13 = xor i64 %mix13,%word13
 %lane14 = extractelement <32 x i32> %v,i64 14
 %word14 = zext i32 %lane14 to i64
 %mix14 = mul i64 %r13,1099511628211
 %r14 = xor i64 %mix14,%word14
 %lane15 = extractelement <32 x i32> %v,i64 15
 %word15 = zext i32 %lane15 to i64
 %mix15 = mul i64 %r14,1099511628211
 %r15 = xor i64 %mix15,%word15
 %lane16 = extractelement <32 x i32> %v,i64 16
 %word16 = zext i32 %lane16 to i64
 %mix16 = mul i64 %r15,1099511628211
 %r16 = xor i64 %mix16,%word16
 %lane17 = extractelement <32 x i32> %v,i64 17
 %word17 = zext i32 %lane17 to i64
 %mix17 = mul i64 %r16,1099511628211
 %r17 = xor i64 %mix17,%word17
 %lane18 = extractelement <32 x i32> %v,i64 18
 %word18 = zext i32 %lane18 to i64
 %mix18 = mul i64 %r17,1099511628211
 %r18 = xor i64 %mix18,%word18
 %lane19 = extractelement <32 x i32> %v,i64 19
 %word19 = zext i32 %lane19 to i64
 %mix19 = mul i64 %r18,1099511628211
 %r19 = xor i64 %mix19,%word19
 %lane20 = extractelement <32 x i32> %v,i64 20
 %word20 = zext i32 %lane20 to i64
 %mix20 = mul i64 %r19,1099511628211
 %r20 = xor i64 %mix20,%word20
 %lane21 = extractelement <32 x i32> %v,i64 21
 %word21 = zext i32 %lane21 to i64
 %mix21 = mul i64 %r20,1099511628211
 %r21 = xor i64 %mix21,%word21
 %lane22 = extractelement <32 x i32> %v,i64 22
 %word22 = zext i32 %lane22 to i64
 %mix22 = mul i64 %r21,1099511628211
 %r22 = xor i64 %mix22,%word22
 %lane23 = extractelement <32 x i32> %v,i64 23
 %word23 = zext i32 %lane23 to i64
 %mix23 = mul i64 %r22,1099511628211
 %r23 = xor i64 %mix23,%word23
 %lane24 = extractelement <32 x i32> %v,i64 24
 %word24 = zext i32 %lane24 to i64
 %mix24 = mul i64 %r23,1099511628211
 %r24 = xor i64 %mix24,%word24
 %lane25 = extractelement <32 x i32> %v,i64 25
 %word25 = zext i32 %lane25 to i64
 %mix25 = mul i64 %r24,1099511628211
 %r25 = xor i64 %mix25,%word25
 %lane26 = extractelement <32 x i32> %v,i64 26
 %word26 = zext i32 %lane26 to i64
 %mix26 = mul i64 %r25,1099511628211
 %r26 = xor i64 %mix26,%word26
 %lane27 = extractelement <32 x i32> %v,i64 27
 %word27 = zext i32 %lane27 to i64
 %mix27 = mul i64 %r26,1099511628211
 %r27 = xor i64 %mix27,%word27
 %lane28 = extractelement <32 x i32> %v,i64 28
 %word28 = zext i32 %lane28 to i64
 %mix28 = mul i64 %r27,1099511628211
 %r28 = xor i64 %mix28,%word28
 %lane29 = extractelement <32 x i32> %v,i64 29
 %word29 = zext i32 %lane29 to i64
 %mix29 = mul i64 %r28,1099511628211
 %r29 = xor i64 %mix29,%word29
 %lane30 = extractelement <32 x i32> %v,i64 30
 %word30 = zext i32 %lane30 to i64
 %mix30 = mul i64 %r29,1099511628211
 %r30 = xor i64 %mix30,%word30
 %lane31 = extractelement <32 x i32> %v,i64 31
 %word31 = zext i32 %lane31 to i64
 %mix31 = mul i64 %r30,1099511628211
 %r31 = xor i64 %mix31,%word31
 ret i64 %r31
}
declare i64 @vector_input_provider_15(i64,i64,i64,i64,i64,i64,<32 x i32>,i64)
define i64 @vector_input_probe_15(ptr %out,ptr %input,i64 %salt) {
entry:
 %v = load <32 x i32>,ptr %input,align 1
 %local = call fastcc i64 @vector_input_body_15(i64 1311768467463790320,i64 18364758544493064720,i64 1234605616436508552,i64 12379552201711258095,i64 9756277981056907928,i64 1161981756646125696,<32 x i32> %v,i64 %salt)
 %external = call i64 @vector_input_provider_15(i64 1311768467463790320,i64 18364758544493064720,i64 1234605616436508552,i64 12379552201711258095,i64 9756277981056907928,i64 1161981756646125696,<32 x i32> %v,i64 %salt)
 store i64 %local,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %external,ptr %next,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define i64 @vector_input_body_16(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,<4 x i64> %v,i64 %salt) noinline {
entry:
 %s0 = xor i64 %salt,%p0
 %s1 = xor i64 %s0,%p1
 %s2 = xor i64 %s1,%p2
 %s3 = xor i64 %s2,%p3
 %s4 = xor i64 %s3,%p4
 %s5 = xor i64 %s4,%p5
 %lane0 = extractelement <4 x i64> %v,i64 0
 %word0 = add i64 %lane0,0
 %mix0 = mul i64 %s5,1099511628211
 %r0 = xor i64 %mix0,%word0
 %lane1 = extractelement <4 x i64> %v,i64 1
 %word1 = add i64 %lane1,0
 %mix1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %mix1,%word1
 %lane2 = extractelement <4 x i64> %v,i64 2
 %word2 = add i64 %lane2,0
 %mix2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %mix2,%word2
 %lane3 = extractelement <4 x i64> %v,i64 3
 %word3 = add i64 %lane3,0
 %mix3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %mix3,%word3
 ret i64 %r3
}
declare i64 @vector_input_provider_16(i64,i64,i64,i64,i64,i64,<4 x i64>,i64)
define i64 @vector_input_probe_16(ptr %out,ptr %input,i64 %salt) {
entry:
 %v = load <4 x i64>,ptr %input,align 1
 %local = call i64 @vector_input_body_16(i64 1311768467463790320,i64 18364758544493064720,i64 1234605616436508552,i64 12379552201711258095,i64 9756277981056907928,i64 1161981756646125696,<4 x i64> %v,i64 %salt)
 %external = call i64 @vector_input_provider_16(i64 1311768467463790320,i64 18364758544493064720,i64 1234605616436508552,i64 12379552201711258095,i64 9756277981056907928,i64 1161981756646125696,<4 x i64> %v,i64 %salt)
 store i64 %local,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %external,ptr %next,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc i64 @vector_input_body_17(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,<4 x i64> %v,i64 %salt) noinline {
entry:
 %s0 = xor i64 %salt,%p0
 %s1 = xor i64 %s0,%p1
 %s2 = xor i64 %s1,%p2
 %s3 = xor i64 %s2,%p3
 %s4 = xor i64 %s3,%p4
 %s5 = xor i64 %s4,%p5
 %lane0 = extractelement <4 x i64> %v,i64 0
 %word0 = add i64 %lane0,0
 %mix0 = mul i64 %s5,1099511628211
 %r0 = xor i64 %mix0,%word0
 %lane1 = extractelement <4 x i64> %v,i64 1
 %word1 = add i64 %lane1,0
 %mix1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %mix1,%word1
 %lane2 = extractelement <4 x i64> %v,i64 2
 %word2 = add i64 %lane2,0
 %mix2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %mix2,%word2
 %lane3 = extractelement <4 x i64> %v,i64 3
 %word3 = add i64 %lane3,0
 %mix3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %mix3,%word3
 ret i64 %r3
}
declare i64 @vector_input_provider_17(i64,i64,i64,i64,i64,i64,<4 x i64>,i64)
define i64 @vector_input_probe_17(ptr %out,ptr %input,i64 %salt) {
entry:
 %v = load <4 x i64>,ptr %input,align 1
 %local = call fastcc i64 @vector_input_body_17(i64 1311768467463790320,i64 18364758544493064720,i64 1234605616436508552,i64 12379552201711258095,i64 9756277981056907928,i64 1161981756646125696,<4 x i64> %v,i64 %salt)
 %external = call i64 @vector_input_provider_17(i64 1311768467463790320,i64 18364758544493064720,i64 1234605616436508552,i64 12379552201711258095,i64 9756277981056907928,i64 1161981756646125696,<4 x i64> %v,i64 %salt)
 store i64 %local,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %external,ptr %next,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define i64 @vector_input_body_18(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,<8 x i64> %v,i64 %salt) noinline {
entry:
 %s0 = xor i64 %salt,%p0
 %s1 = xor i64 %s0,%p1
 %s2 = xor i64 %s1,%p2
 %s3 = xor i64 %s2,%p3
 %s4 = xor i64 %s3,%p4
 %s5 = xor i64 %s4,%p5
 %lane0 = extractelement <8 x i64> %v,i64 0
 %word0 = add i64 %lane0,0
 %mix0 = mul i64 %s5,1099511628211
 %r0 = xor i64 %mix0,%word0
 %lane1 = extractelement <8 x i64> %v,i64 1
 %word1 = add i64 %lane1,0
 %mix1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %mix1,%word1
 %lane2 = extractelement <8 x i64> %v,i64 2
 %word2 = add i64 %lane2,0
 %mix2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %mix2,%word2
 %lane3 = extractelement <8 x i64> %v,i64 3
 %word3 = add i64 %lane3,0
 %mix3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %mix3,%word3
 %lane4 = extractelement <8 x i64> %v,i64 4
 %word4 = add i64 %lane4,0
 %mix4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %mix4,%word4
 %lane5 = extractelement <8 x i64> %v,i64 5
 %word5 = add i64 %lane5,0
 %mix5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %mix5,%word5
 %lane6 = extractelement <8 x i64> %v,i64 6
 %word6 = add i64 %lane6,0
 %mix6 = mul i64 %r5,1099511628211
 %r6 = xor i64 %mix6,%word6
 %lane7 = extractelement <8 x i64> %v,i64 7
 %word7 = add i64 %lane7,0
 %mix7 = mul i64 %r6,1099511628211
 %r7 = xor i64 %mix7,%word7
 ret i64 %r7
}
declare i64 @vector_input_provider_18(i64,i64,i64,i64,i64,i64,<8 x i64>,i64)
define i64 @vector_input_probe_18(ptr %out,ptr %input,i64 %salt) {
entry:
 %v = load <8 x i64>,ptr %input,align 1
 %local = call i64 @vector_input_body_18(i64 1311768467463790320,i64 18364758544493064720,i64 1234605616436508552,i64 12379552201711258095,i64 9756277981056907928,i64 1161981756646125696,<8 x i64> %v,i64 %salt)
 %external = call i64 @vector_input_provider_18(i64 1311768467463790320,i64 18364758544493064720,i64 1234605616436508552,i64 12379552201711258095,i64 9756277981056907928,i64 1161981756646125696,<8 x i64> %v,i64 %salt)
 store i64 %local,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %external,ptr %next,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc i64 @vector_input_body_19(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,<8 x i64> %v,i64 %salt) noinline {
entry:
 %s0 = xor i64 %salt,%p0
 %s1 = xor i64 %s0,%p1
 %s2 = xor i64 %s1,%p2
 %s3 = xor i64 %s2,%p3
 %s4 = xor i64 %s3,%p4
 %s5 = xor i64 %s4,%p5
 %lane0 = extractelement <8 x i64> %v,i64 0
 %word0 = add i64 %lane0,0
 %mix0 = mul i64 %s5,1099511628211
 %r0 = xor i64 %mix0,%word0
 %lane1 = extractelement <8 x i64> %v,i64 1
 %word1 = add i64 %lane1,0
 %mix1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %mix1,%word1
 %lane2 = extractelement <8 x i64> %v,i64 2
 %word2 = add i64 %lane2,0
 %mix2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %mix2,%word2
 %lane3 = extractelement <8 x i64> %v,i64 3
 %word3 = add i64 %lane3,0
 %mix3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %mix3,%word3
 %lane4 = extractelement <8 x i64> %v,i64 4
 %word4 = add i64 %lane4,0
 %mix4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %mix4,%word4
 %lane5 = extractelement <8 x i64> %v,i64 5
 %word5 = add i64 %lane5,0
 %mix5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %mix5,%word5
 %lane6 = extractelement <8 x i64> %v,i64 6
 %word6 = add i64 %lane6,0
 %mix6 = mul i64 %r5,1099511628211
 %r6 = xor i64 %mix6,%word6
 %lane7 = extractelement <8 x i64> %v,i64 7
 %word7 = add i64 %lane7,0
 %mix7 = mul i64 %r6,1099511628211
 %r7 = xor i64 %mix7,%word7
 ret i64 %r7
}
declare i64 @vector_input_provider_19(i64,i64,i64,i64,i64,i64,<8 x i64>,i64)
define i64 @vector_input_probe_19(ptr %out,ptr %input,i64 %salt) {
entry:
 %v = load <8 x i64>,ptr %input,align 1
 %local = call fastcc i64 @vector_input_body_19(i64 1311768467463790320,i64 18364758544493064720,i64 1234605616436508552,i64 12379552201711258095,i64 9756277981056907928,i64 1161981756646125696,<8 x i64> %v,i64 %salt)
 %external = call i64 @vector_input_provider_19(i64 1311768467463790320,i64 18364758544493064720,i64 1234605616436508552,i64 12379552201711258095,i64 9756277981056907928,i64 1161981756646125696,<8 x i64> %v,i64 %salt)
 store i64 %local,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %external,ptr %next,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define i64 @vector_input_body_20(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,<16 x i64> %v,i64 %salt) noinline {
entry:
 %s0 = xor i64 %salt,%p0
 %s1 = xor i64 %s0,%p1
 %s2 = xor i64 %s1,%p2
 %s3 = xor i64 %s2,%p3
 %s4 = xor i64 %s3,%p4
 %s5 = xor i64 %s4,%p5
 %lane0 = extractelement <16 x i64> %v,i64 0
 %word0 = add i64 %lane0,0
 %mix0 = mul i64 %s5,1099511628211
 %r0 = xor i64 %mix0,%word0
 %lane1 = extractelement <16 x i64> %v,i64 1
 %word1 = add i64 %lane1,0
 %mix1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %mix1,%word1
 %lane2 = extractelement <16 x i64> %v,i64 2
 %word2 = add i64 %lane2,0
 %mix2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %mix2,%word2
 %lane3 = extractelement <16 x i64> %v,i64 3
 %word3 = add i64 %lane3,0
 %mix3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %mix3,%word3
 %lane4 = extractelement <16 x i64> %v,i64 4
 %word4 = add i64 %lane4,0
 %mix4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %mix4,%word4
 %lane5 = extractelement <16 x i64> %v,i64 5
 %word5 = add i64 %lane5,0
 %mix5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %mix5,%word5
 %lane6 = extractelement <16 x i64> %v,i64 6
 %word6 = add i64 %lane6,0
 %mix6 = mul i64 %r5,1099511628211
 %r6 = xor i64 %mix6,%word6
 %lane7 = extractelement <16 x i64> %v,i64 7
 %word7 = add i64 %lane7,0
 %mix7 = mul i64 %r6,1099511628211
 %r7 = xor i64 %mix7,%word7
 %lane8 = extractelement <16 x i64> %v,i64 8
 %word8 = add i64 %lane8,0
 %mix8 = mul i64 %r7,1099511628211
 %r8 = xor i64 %mix8,%word8
 %lane9 = extractelement <16 x i64> %v,i64 9
 %word9 = add i64 %lane9,0
 %mix9 = mul i64 %r8,1099511628211
 %r9 = xor i64 %mix9,%word9
 %lane10 = extractelement <16 x i64> %v,i64 10
 %word10 = add i64 %lane10,0
 %mix10 = mul i64 %r9,1099511628211
 %r10 = xor i64 %mix10,%word10
 %lane11 = extractelement <16 x i64> %v,i64 11
 %word11 = add i64 %lane11,0
 %mix11 = mul i64 %r10,1099511628211
 %r11 = xor i64 %mix11,%word11
 %lane12 = extractelement <16 x i64> %v,i64 12
 %word12 = add i64 %lane12,0
 %mix12 = mul i64 %r11,1099511628211
 %r12 = xor i64 %mix12,%word12
 %lane13 = extractelement <16 x i64> %v,i64 13
 %word13 = add i64 %lane13,0
 %mix13 = mul i64 %r12,1099511628211
 %r13 = xor i64 %mix13,%word13
 %lane14 = extractelement <16 x i64> %v,i64 14
 %word14 = add i64 %lane14,0
 %mix14 = mul i64 %r13,1099511628211
 %r14 = xor i64 %mix14,%word14
 %lane15 = extractelement <16 x i64> %v,i64 15
 %word15 = add i64 %lane15,0
 %mix15 = mul i64 %r14,1099511628211
 %r15 = xor i64 %mix15,%word15
 ret i64 %r15
}
declare i64 @vector_input_provider_20(i64,i64,i64,i64,i64,i64,<16 x i64>,i64)
define i64 @vector_input_probe_20(ptr %out,ptr %input,i64 %salt) {
entry:
 %v = load <16 x i64>,ptr %input,align 1
 %local = call i64 @vector_input_body_20(i64 1311768467463790320,i64 18364758544493064720,i64 1234605616436508552,i64 12379552201711258095,i64 9756277981056907928,i64 1161981756646125696,<16 x i64> %v,i64 %salt)
 %external = call i64 @vector_input_provider_20(i64 1311768467463790320,i64 18364758544493064720,i64 1234605616436508552,i64 12379552201711258095,i64 9756277981056907928,i64 1161981756646125696,<16 x i64> %v,i64 %salt)
 store i64 %local,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %external,ptr %next,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc i64 @vector_input_body_21(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,<16 x i64> %v,i64 %salt) noinline {
entry:
 %s0 = xor i64 %salt,%p0
 %s1 = xor i64 %s0,%p1
 %s2 = xor i64 %s1,%p2
 %s3 = xor i64 %s2,%p3
 %s4 = xor i64 %s3,%p4
 %s5 = xor i64 %s4,%p5
 %lane0 = extractelement <16 x i64> %v,i64 0
 %word0 = add i64 %lane0,0
 %mix0 = mul i64 %s5,1099511628211
 %r0 = xor i64 %mix0,%word0
 %lane1 = extractelement <16 x i64> %v,i64 1
 %word1 = add i64 %lane1,0
 %mix1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %mix1,%word1
 %lane2 = extractelement <16 x i64> %v,i64 2
 %word2 = add i64 %lane2,0
 %mix2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %mix2,%word2
 %lane3 = extractelement <16 x i64> %v,i64 3
 %word3 = add i64 %lane3,0
 %mix3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %mix3,%word3
 %lane4 = extractelement <16 x i64> %v,i64 4
 %word4 = add i64 %lane4,0
 %mix4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %mix4,%word4
 %lane5 = extractelement <16 x i64> %v,i64 5
 %word5 = add i64 %lane5,0
 %mix5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %mix5,%word5
 %lane6 = extractelement <16 x i64> %v,i64 6
 %word6 = add i64 %lane6,0
 %mix6 = mul i64 %r5,1099511628211
 %r6 = xor i64 %mix6,%word6
 %lane7 = extractelement <16 x i64> %v,i64 7
 %word7 = add i64 %lane7,0
 %mix7 = mul i64 %r6,1099511628211
 %r7 = xor i64 %mix7,%word7
 %lane8 = extractelement <16 x i64> %v,i64 8
 %word8 = add i64 %lane8,0
 %mix8 = mul i64 %r7,1099511628211
 %r8 = xor i64 %mix8,%word8
 %lane9 = extractelement <16 x i64> %v,i64 9
 %word9 = add i64 %lane9,0
 %mix9 = mul i64 %r8,1099511628211
 %r9 = xor i64 %mix9,%word9
 %lane10 = extractelement <16 x i64> %v,i64 10
 %word10 = add i64 %lane10,0
 %mix10 = mul i64 %r9,1099511628211
 %r10 = xor i64 %mix10,%word10
 %lane11 = extractelement <16 x i64> %v,i64 11
 %word11 = add i64 %lane11,0
 %mix11 = mul i64 %r10,1099511628211
 %r11 = xor i64 %mix11,%word11
 %lane12 = extractelement <16 x i64> %v,i64 12
 %word12 = add i64 %lane12,0
 %mix12 = mul i64 %r11,1099511628211
 %r12 = xor i64 %mix12,%word12
 %lane13 = extractelement <16 x i64> %v,i64 13
 %word13 = add i64 %lane13,0
 %mix13 = mul i64 %r12,1099511628211
 %r13 = xor i64 %mix13,%word13
 %lane14 = extractelement <16 x i64> %v,i64 14
 %word14 = add i64 %lane14,0
 %mix14 = mul i64 %r13,1099511628211
 %r14 = xor i64 %mix14,%word14
 %lane15 = extractelement <16 x i64> %v,i64 15
 %word15 = add i64 %lane15,0
 %mix15 = mul i64 %r14,1099511628211
 %r15 = xor i64 %mix15,%word15
 ret i64 %r15
}
declare i64 @vector_input_provider_21(i64,i64,i64,i64,i64,i64,<16 x i64>,i64)
define i64 @vector_input_probe_21(ptr %out,ptr %input,i64 %salt) {
entry:
 %v = load <16 x i64>,ptr %input,align 1
 %local = call fastcc i64 @vector_input_body_21(i64 1311768467463790320,i64 18364758544493064720,i64 1234605616436508552,i64 12379552201711258095,i64 9756277981056907928,i64 1161981756646125696,<16 x i64> %v,i64 %salt)
 %external = call i64 @vector_input_provider_21(i64 1311768467463790320,i64 18364758544493064720,i64 1234605616436508552,i64 12379552201711258095,i64 9756277981056907928,i64 1161981756646125696,<16 x i64> %v,i64 %salt)
 store i64 %local,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %external,ptr %next,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define i64 @vector_input_body_22(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,<3 x i8> %v,i64 %salt) noinline {
entry:
 %s0 = xor i64 %salt,%p0
 %s1 = xor i64 %s0,%p1
 %s2 = xor i64 %s1,%p2
 %s3 = xor i64 %s2,%p3
 %s4 = xor i64 %s3,%p4
 %s5 = xor i64 %s4,%p5
 %lane0 = extractelement <3 x i8> %v,i64 0
 %word0 = zext i8 %lane0 to i64
 %mix0 = mul i64 %s5,1099511628211
 %r0 = xor i64 %mix0,%word0
 %lane1 = extractelement <3 x i8> %v,i64 1
 %word1 = zext i8 %lane1 to i64
 %mix1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %mix1,%word1
 %lane2 = extractelement <3 x i8> %v,i64 2
 %word2 = zext i8 %lane2 to i64
 %mix2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %mix2,%word2
 ret i64 %r2
}
declare i64 @vector_input_provider_22(i64,i64,i64,i64,i64,i64,<3 x i8>,i64)
define i64 @vector_input_probe_22(ptr %out,ptr %input,i64 %salt) {
entry:
 %v = load <3 x i8>,ptr %input,align 1
 %local = call i64 @vector_input_body_22(i64 1311768467463790320,i64 18364758544493064720,i64 1234605616436508552,i64 12379552201711258095,i64 9756277981056907928,i64 1161981756646125696,<3 x i8> %v,i64 %salt)
 %external = call i64 @vector_input_provider_22(i64 1311768467463790320,i64 18364758544493064720,i64 1234605616436508552,i64 12379552201711258095,i64 9756277981056907928,i64 1161981756646125696,<3 x i8> %v,i64 %salt)
 store i64 %local,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %external,ptr %next,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc i64 @vector_input_body_23(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,<3 x i8> %v,i64 %salt) noinline {
entry:
 %s0 = xor i64 %salt,%p0
 %s1 = xor i64 %s0,%p1
 %s2 = xor i64 %s1,%p2
 %s3 = xor i64 %s2,%p3
 %s4 = xor i64 %s3,%p4
 %s5 = xor i64 %s4,%p5
 %lane0 = extractelement <3 x i8> %v,i64 0
 %word0 = zext i8 %lane0 to i64
 %mix0 = mul i64 %s5,1099511628211
 %r0 = xor i64 %mix0,%word0
 %lane1 = extractelement <3 x i8> %v,i64 1
 %word1 = zext i8 %lane1 to i64
 %mix1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %mix1,%word1
 %lane2 = extractelement <3 x i8> %v,i64 2
 %word2 = zext i8 %lane2 to i64
 %mix2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %mix2,%word2
 ret i64 %r2
}
declare i64 @vector_input_provider_23(i64,i64,i64,i64,i64,i64,<3 x i8>,i64)
define i64 @vector_input_probe_23(ptr %out,ptr %input,i64 %salt) {
entry:
 %v = load <3 x i8>,ptr %input,align 1
 %local = call fastcc i64 @vector_input_body_23(i64 1311768467463790320,i64 18364758544493064720,i64 1234605616436508552,i64 12379552201711258095,i64 9756277981056907928,i64 1161981756646125696,<3 x i8> %v,i64 %salt)
 %external = call i64 @vector_input_provider_23(i64 1311768467463790320,i64 18364758544493064720,i64 1234605616436508552,i64 12379552201711258095,i64 9756277981056907928,i64 1161981756646125696,<3 x i8> %v,i64 %salt)
 store i64 %local,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %external,ptr %next,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define i64 @vector_input_body_24(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,<3 x i16> %v,i64 %salt) noinline {
entry:
 %s0 = xor i64 %salt,%p0
 %s1 = xor i64 %s0,%p1
 %s2 = xor i64 %s1,%p2
 %s3 = xor i64 %s2,%p3
 %s4 = xor i64 %s3,%p4
 %s5 = xor i64 %s4,%p5
 %lane0 = extractelement <3 x i16> %v,i64 0
 %word0 = zext i16 %lane0 to i64
 %mix0 = mul i64 %s5,1099511628211
 %r0 = xor i64 %mix0,%word0
 %lane1 = extractelement <3 x i16> %v,i64 1
 %word1 = zext i16 %lane1 to i64
 %mix1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %mix1,%word1
 %lane2 = extractelement <3 x i16> %v,i64 2
 %word2 = zext i16 %lane2 to i64
 %mix2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %mix2,%word2
 ret i64 %r2
}
declare i64 @vector_input_provider_24(i64,i64,i64,i64,i64,i64,<3 x i16>,i64)
define i64 @vector_input_probe_24(ptr %out,ptr %input,i64 %salt) {
entry:
 %v = load <3 x i16>,ptr %input,align 1
 %local = call i64 @vector_input_body_24(i64 1311768467463790320,i64 18364758544493064720,i64 1234605616436508552,i64 12379552201711258095,i64 9756277981056907928,i64 1161981756646125696,<3 x i16> %v,i64 %salt)
 %external = call i64 @vector_input_provider_24(i64 1311768467463790320,i64 18364758544493064720,i64 1234605616436508552,i64 12379552201711258095,i64 9756277981056907928,i64 1161981756646125696,<3 x i16> %v,i64 %salt)
 store i64 %local,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %external,ptr %next,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc i64 @vector_input_body_25(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,<3 x i16> %v,i64 %salt) noinline {
entry:
 %s0 = xor i64 %salt,%p0
 %s1 = xor i64 %s0,%p1
 %s2 = xor i64 %s1,%p2
 %s3 = xor i64 %s2,%p3
 %s4 = xor i64 %s3,%p4
 %s5 = xor i64 %s4,%p5
 %lane0 = extractelement <3 x i16> %v,i64 0
 %word0 = zext i16 %lane0 to i64
 %mix0 = mul i64 %s5,1099511628211
 %r0 = xor i64 %mix0,%word0
 %lane1 = extractelement <3 x i16> %v,i64 1
 %word1 = zext i16 %lane1 to i64
 %mix1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %mix1,%word1
 %lane2 = extractelement <3 x i16> %v,i64 2
 %word2 = zext i16 %lane2 to i64
 %mix2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %mix2,%word2
 ret i64 %r2
}
declare i64 @vector_input_provider_25(i64,i64,i64,i64,i64,i64,<3 x i16>,i64)
define i64 @vector_input_probe_25(ptr %out,ptr %input,i64 %salt) {
entry:
 %v = load <3 x i16>,ptr %input,align 1
 %local = call fastcc i64 @vector_input_body_25(i64 1311768467463790320,i64 18364758544493064720,i64 1234605616436508552,i64 12379552201711258095,i64 9756277981056907928,i64 1161981756646125696,<3 x i16> %v,i64 %salt)
 %external = call i64 @vector_input_provider_25(i64 1311768467463790320,i64 18364758544493064720,i64 1234605616436508552,i64 12379552201711258095,i64 9756277981056907928,i64 1161981756646125696,<3 x i16> %v,i64 %salt)
 store i64 %local,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %external,ptr %next,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define i64 @vector_input_body_26(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,<3 x i64> %v,i64 %salt) noinline {
entry:
 %s0 = xor i64 %salt,%p0
 %s1 = xor i64 %s0,%p1
 %s2 = xor i64 %s1,%p2
 %s3 = xor i64 %s2,%p3
 %s4 = xor i64 %s3,%p4
 %s5 = xor i64 %s4,%p5
 %lane0 = extractelement <3 x i64> %v,i64 0
 %word0 = add i64 %lane0,0
 %mix0 = mul i64 %s5,1099511628211
 %r0 = xor i64 %mix0,%word0
 %lane1 = extractelement <3 x i64> %v,i64 1
 %word1 = add i64 %lane1,0
 %mix1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %mix1,%word1
 %lane2 = extractelement <3 x i64> %v,i64 2
 %word2 = add i64 %lane2,0
 %mix2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %mix2,%word2
 ret i64 %r2
}
declare i64 @vector_input_provider_26(i64,i64,i64,i64,i64,i64,<3 x i64>,i64)
define i64 @vector_input_probe_26(ptr %out,ptr %input,i64 %salt) {
entry:
 %v = load <3 x i64>,ptr %input,align 1
 %local = call i64 @vector_input_body_26(i64 1311768467463790320,i64 18364758544493064720,i64 1234605616436508552,i64 12379552201711258095,i64 9756277981056907928,i64 1161981756646125696,<3 x i64> %v,i64 %salt)
 %external = call i64 @vector_input_provider_26(i64 1311768467463790320,i64 18364758544493064720,i64 1234605616436508552,i64 12379552201711258095,i64 9756277981056907928,i64 1161981756646125696,<3 x i64> %v,i64 %salt)
 store i64 %local,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %external,ptr %next,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc i64 @vector_input_body_27(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,<3 x i64> %v,i64 %salt) noinline {
entry:
 %s0 = xor i64 %salt,%p0
 %s1 = xor i64 %s0,%p1
 %s2 = xor i64 %s1,%p2
 %s3 = xor i64 %s2,%p3
 %s4 = xor i64 %s3,%p4
 %s5 = xor i64 %s4,%p5
 %lane0 = extractelement <3 x i64> %v,i64 0
 %word0 = add i64 %lane0,0
 %mix0 = mul i64 %s5,1099511628211
 %r0 = xor i64 %mix0,%word0
 %lane1 = extractelement <3 x i64> %v,i64 1
 %word1 = add i64 %lane1,0
 %mix1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %mix1,%word1
 %lane2 = extractelement <3 x i64> %v,i64 2
 %word2 = add i64 %lane2,0
 %mix2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %mix2,%word2
 ret i64 %r2
}
declare i64 @vector_input_provider_27(i64,i64,i64,i64,i64,i64,<3 x i64>,i64)
define i64 @vector_input_probe_27(ptr %out,ptr %input,i64 %salt) {
entry:
 %v = load <3 x i64>,ptr %input,align 1
 %local = call fastcc i64 @vector_input_body_27(i64 1311768467463790320,i64 18364758544493064720,i64 1234605616436508552,i64 12379552201711258095,i64 9756277981056907928,i64 1161981756646125696,<3 x i64> %v,i64 %salt)
 %external = call i64 @vector_input_provider_27(i64 1311768467463790320,i64 18364758544493064720,i64 1234605616436508552,i64 12379552201711258095,i64 9756277981056907928,i64 1161981756646125696,<3 x i64> %v,i64 %salt)
 store i64 %local,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %external,ptr %next,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define i64 @vector_input_body_28(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,<5 x i32> %v,i64 %salt) noinline {
entry:
 %s0 = xor i64 %salt,%p0
 %s1 = xor i64 %s0,%p1
 %s2 = xor i64 %s1,%p2
 %s3 = xor i64 %s2,%p3
 %s4 = xor i64 %s3,%p4
 %s5 = xor i64 %s4,%p5
 %lane0 = extractelement <5 x i32> %v,i64 0
 %word0 = zext i32 %lane0 to i64
 %mix0 = mul i64 %s5,1099511628211
 %r0 = xor i64 %mix0,%word0
 %lane1 = extractelement <5 x i32> %v,i64 1
 %word1 = zext i32 %lane1 to i64
 %mix1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %mix1,%word1
 %lane2 = extractelement <5 x i32> %v,i64 2
 %word2 = zext i32 %lane2 to i64
 %mix2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %mix2,%word2
 %lane3 = extractelement <5 x i32> %v,i64 3
 %word3 = zext i32 %lane3 to i64
 %mix3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %mix3,%word3
 %lane4 = extractelement <5 x i32> %v,i64 4
 %word4 = zext i32 %lane4 to i64
 %mix4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %mix4,%word4
 ret i64 %r4
}
declare i64 @vector_input_provider_28(i64,i64,i64,i64,i64,i64,<5 x i32>,i64)
define i64 @vector_input_probe_28(ptr %out,ptr %input,i64 %salt) {
entry:
 %v = load <5 x i32>,ptr %input,align 1
 %local = call i64 @vector_input_body_28(i64 1311768467463790320,i64 18364758544493064720,i64 1234605616436508552,i64 12379552201711258095,i64 9756277981056907928,i64 1161981756646125696,<5 x i32> %v,i64 %salt)
 %external = call i64 @vector_input_provider_28(i64 1311768467463790320,i64 18364758544493064720,i64 1234605616436508552,i64 12379552201711258095,i64 9756277981056907928,i64 1161981756646125696,<5 x i32> %v,i64 %salt)
 store i64 %local,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %external,ptr %next,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc i64 @vector_input_body_29(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,<5 x i32> %v,i64 %salt) noinline {
entry:
 %s0 = xor i64 %salt,%p0
 %s1 = xor i64 %s0,%p1
 %s2 = xor i64 %s1,%p2
 %s3 = xor i64 %s2,%p3
 %s4 = xor i64 %s3,%p4
 %s5 = xor i64 %s4,%p5
 %lane0 = extractelement <5 x i32> %v,i64 0
 %word0 = zext i32 %lane0 to i64
 %mix0 = mul i64 %s5,1099511628211
 %r0 = xor i64 %mix0,%word0
 %lane1 = extractelement <5 x i32> %v,i64 1
 %word1 = zext i32 %lane1 to i64
 %mix1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %mix1,%word1
 %lane2 = extractelement <5 x i32> %v,i64 2
 %word2 = zext i32 %lane2 to i64
 %mix2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %mix2,%word2
 %lane3 = extractelement <5 x i32> %v,i64 3
 %word3 = zext i32 %lane3 to i64
 %mix3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %mix3,%word3
 %lane4 = extractelement <5 x i32> %v,i64 4
 %word4 = zext i32 %lane4 to i64
 %mix4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %mix4,%word4
 ret i64 %r4
}
declare i64 @vector_input_provider_29(i64,i64,i64,i64,i64,i64,<5 x i32>,i64)
define i64 @vector_input_probe_29(ptr %out,ptr %input,i64 %salt) {
entry:
 %v = load <5 x i32>,ptr %input,align 1
 %local = call fastcc i64 @vector_input_body_29(i64 1311768467463790320,i64 18364758544493064720,i64 1234605616436508552,i64 12379552201711258095,i64 9756277981056907928,i64 1161981756646125696,<5 x i32> %v,i64 %salt)
 %external = call i64 @vector_input_provider_29(i64 1311768467463790320,i64 18364758544493064720,i64 1234605616436508552,i64 12379552201711258095,i64 9756277981056907928,i64 1161981756646125696,<5 x i32> %v,i64 %salt)
 store i64 %local,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %external,ptr %next,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define i64 @vector_input_body_30(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,<3 x ptr> %v,i64 %salt) noinline {
entry:
 %s0 = xor i64 %salt,%p0
 %s1 = xor i64 %s0,%p1
 %s2 = xor i64 %s1,%p2
 %s3 = xor i64 %s2,%p3
 %s4 = xor i64 %s3,%p4
 %s5 = xor i64 %s4,%p5
 %lane0 = extractelement <3 x ptr> %v,i64 0
 %word0 = ptrtoint ptr %lane0 to i64
 %mix0 = mul i64 %s5,1099511628211
 %r0 = xor i64 %mix0,%word0
 %lane1 = extractelement <3 x ptr> %v,i64 1
 %word1 = ptrtoint ptr %lane1 to i64
 %mix1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %mix1,%word1
 %lane2 = extractelement <3 x ptr> %v,i64 2
 %word2 = ptrtoint ptr %lane2 to i64
 %mix2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %mix2,%word2
 ret i64 %r2
}
declare i64 @vector_input_provider_30(i64,i64,i64,i64,i64,i64,<3 x ptr>,i64)
define i64 @vector_input_probe_30(ptr %out,ptr %input,i64 %salt) {
entry:
 %v = load <3 x ptr>,ptr %input,align 1
 %local = call i64 @vector_input_body_30(i64 1311768467463790320,i64 18364758544493064720,i64 1234605616436508552,i64 12379552201711258095,i64 9756277981056907928,i64 1161981756646125696,<3 x ptr> %v,i64 %salt)
 %external = call i64 @vector_input_provider_30(i64 1311768467463790320,i64 18364758544493064720,i64 1234605616436508552,i64 12379552201711258095,i64 9756277981056907928,i64 1161981756646125696,<3 x ptr> %v,i64 %salt)
 store i64 %local,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %external,ptr %next,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc i64 @vector_input_body_31(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,<3 x ptr> %v,i64 %salt) noinline {
entry:
 %s0 = xor i64 %salt,%p0
 %s1 = xor i64 %s0,%p1
 %s2 = xor i64 %s1,%p2
 %s3 = xor i64 %s2,%p3
 %s4 = xor i64 %s3,%p4
 %s5 = xor i64 %s4,%p5
 %lane0 = extractelement <3 x ptr> %v,i64 0
 %word0 = ptrtoint ptr %lane0 to i64
 %mix0 = mul i64 %s5,1099511628211
 %r0 = xor i64 %mix0,%word0
 %lane1 = extractelement <3 x ptr> %v,i64 1
 %word1 = ptrtoint ptr %lane1 to i64
 %mix1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %mix1,%word1
 %lane2 = extractelement <3 x ptr> %v,i64 2
 %word2 = ptrtoint ptr %lane2 to i64
 %mix2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %mix2,%word2
 ret i64 %r2
}
declare i64 @vector_input_provider_31(i64,i64,i64,i64,i64,i64,<3 x ptr>,i64)
define i64 @vector_input_probe_31(ptr %out,ptr %input,i64 %salt) {
entry:
 %v = load <3 x ptr>,ptr %input,align 1
 %local = call fastcc i64 @vector_input_body_31(i64 1311768467463790320,i64 18364758544493064720,i64 1234605616436508552,i64 12379552201711258095,i64 9756277981056907928,i64 1161981756646125696,<3 x ptr> %v,i64 %salt)
 %external = call i64 @vector_input_provider_31(i64 1311768467463790320,i64 18364758544493064720,i64 1234605616436508552,i64 12379552201711258095,i64 9756277981056907928,i64 1161981756646125696,<3 x ptr> %v,i64 %salt)
 store i64 %local,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %external,ptr %next,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare void @vector_input_void_provider(<8 x i32>)
define void @vector_input_void_probe(ptr %p) {
entry:
 %v = load <8 x i32>,ptr %p,align 1
 call void @vector_input_void_provider(<8 x i32> %v)
 ret void
}
