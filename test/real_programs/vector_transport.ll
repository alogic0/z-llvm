target triple = "x86_64-unknown-linux-gnu"
declare i64 @vector_transport_clobber(i64)
declare fp128 @vector_transport_probe(fp128,fp128)
define i80 @vector_transport_wide80_body(i80 %raw,ptr %out) {
entry:
 store i80 %raw,ptr %out,align 1
 %one = insertelement <8 x i80> poison,i80 %raw,i64 0
 %all = shufflevector <8 x i80> %one,<8 x i80> poison,<8 x i32> zeroinitializer
 %parts = lshr <8 x i80> %all,<i80 0,i80 8,i80 16,i80 24,i80 32,i80 40,i80 48,i80 56>
 %small = trunc <8 x i80> %parts to <8 x i8>
 store <8 x i8> %small,ptr %out,align 1
 ret i80 %raw
}
define i128 @vector_transport_wide80(i128 %raw,ptr %input,ptr %out,i64 %live) {
entry:
 %narrow = trunc i128 %raw to i80
 %value = call i80 @vector_transport_wide80_body(i80 %narrow,ptr %out)
 %saved = call i64 @vector_transport_clobber(i64 %live)
 %wide = zext i80 %value to i128
 %extended = zext i64 %saved to i128
 %result = xor i128 %wide,%extended
 ret i128 %result
}
define i113 @vector_transport_wide113_body(i113 %raw,ptr %out) {
entry:
 store i113 %raw,ptr %out,align 1
 %one = insertelement <8 x i113> poison,i113 %raw,i64 0
 %all = shufflevector <8 x i113> %one,<8 x i113> poison,<8 x i32> zeroinitializer
 %parts = lshr <8 x i113> %all,<i113 0,i113 8,i113 16,i113 24,i113 32,i113 40,i113 48,i113 56>
 %small = trunc <8 x i113> %parts to <8 x i8>
 store <8 x i8> %small,ptr %out,align 1
 ret i113 %raw
}
define i128 @vector_transport_wide113(i128 %raw,ptr %input,ptr %out,i64 %live) {
entry:
 %narrow = trunc i128 %raw to i113
 %value = call i113 @vector_transport_wide113_body(i113 %narrow,ptr %out)
 %saved = call i64 @vector_transport_clobber(i64 %live)
 %wide = zext i113 %value to i128
 %extended = zext i64 %saved to i128
 %result = xor i128 %wide,%extended
 ret i128 %result
}
define i127 @vector_transport_wide127_body(i127 %raw,ptr %out) {
entry:
 store i127 %raw,ptr %out,align 1
 %one = insertelement <8 x i127> poison,i127 %raw,i64 0
 %all = shufflevector <8 x i127> %one,<8 x i127> poison,<8 x i32> zeroinitializer
 %parts = lshr <8 x i127> %all,<i127 0,i127 8,i127 16,i127 24,i127 32,i127 40,i127 48,i127 56>
 %small = trunc <8 x i127> %parts to <8 x i8>
 store <8 x i8> %small,ptr %out,align 1
 ret i127 %raw
}
define i128 @vector_transport_wide127(i128 %raw,ptr %input,ptr %out,i64 %live) {
entry:
 %narrow = trunc i128 %raw to i127
 %value = call i127 @vector_transport_wide127_body(i127 %narrow,ptr %out)
 %saved = call i64 @vector_transport_clobber(i64 %live)
 %wide = zext i127 %value to i128
 %extended = zext i64 %saved to i128
 %result = xor i128 %wide,%extended
 ret i128 %result
}
define i128 @vector_transport_gep0(i128 %raw,ptr %input,ptr %out,i64 %live) {
entry:
 %base = getelementptr i8,ptr %input,i64 8
 %pointers = getelementptr i8,ptr %base,<4 x i64> <i64 -8,i64 0,i64 8,i64 16>
 %index = and i64 %live,3
 %picked = extractelement <4 x ptr> %pointers,i64 %index
 %value = load i64,ptr %picked,align 1
 %saved = call i64 @vector_transport_clobber(i64 %live)
 store i64 %value,ptr %out,align 1
 %wide = zext i64 %value to i128
 %extended = zext i64 %saved to i128
 %result = xor i128 %wide,%extended
 ret i128 %result
}
define i128 @vector_transport_gep1(i128 %raw,ptr %input,ptr %out,i64 %live) {
entry:
 %base = getelementptr i8,ptr %input,i64 8
 %offsets = add <4 x i64> zeroinitializer,<i64 -8,i64 0,i64 8,i64 16>
 %pointers = getelementptr i8,ptr %base,<4 x i64> %offsets
 %index = and i64 %live,3
 %picked = extractelement <4 x ptr> %pointers,i64 %index
 %value = load i64,ptr %picked,align 1
 %saved = call i64 @vector_transport_clobber(i64 %live)
 store i64 %value,ptr %out,align 1
 %wide = zext i64 %value to i128
 %extended = zext i64 %saved to i128
 %result = xor i128 %wide,%extended
 ret i128 %result
}
@vector_transport_phi0_table = internal constant [2 x ptr] [ptr blockaddress(@vector_transport_phi0,%exit),ptr blockaddress(@vector_transport_phi0,%loop)]
define i128 @vector_transport_phi0(i128 %raw,ptr %input,ptr %out,i64 %live) {
entry:
 %a = bitcast i128 %raw to fp128
 %b = load fp128,ptr %input,align 1
 %low = trunc i128 %raw to i64
 %masked = and i64 %low,3
 %limit = add i64 %masked,1
 %narrow_limit = trunc i64 %limit to i56
 %choice = trunc i64 %live to i1
 %branch_index = and i64 %live,1
 %branch_slot = getelementptr ptr,ptr @vector_transport_phi0_table,i64 %branch_index
 %address = load ptr,ptr %branch_slot,align 8
 indirectbr ptr %address,[label %loop,label %exit]
loop:
 %x = phi fp128 [ %a,%entry ],[ %y,%loop ]
 %y = phi fp128 [ %b,%entry ],[ %x,%loop ]
 %flag = phi i32 [ 4294967295,%entry ],[ %flag_next,%loop ]
 %n = phi i56 [ 0,%entry ],[ %next,%loop ]
 %flag_next = or i32 %flag,0
 %next = add i56 %n,1
 %again = icmp ult i56 %next,%narrow_limit
 br i1 %again,label %loop,label %exit
exit:
 %picked = phi fp128 [ %a,%entry ],[ %x,%loop ]
 %return_flag = phi i32 [ 4294967295,%entry ],[ %flag,%loop ]
 %saved_raw = call i64 @vector_transport_clobber(i64 %live)
 %flag_bits = zext i32 %return_flag to i64
 %saved = xor i64 %saved_raw,%flag_bits
 store fp128 %picked,ptr %out,align 1
 %bits = bitcast fp128 %picked to i128
 %extended = zext i64 %saved to i128
 %result = xor i128 %bits,%extended
 ret i128 %result
}
define i128 @vector_transport_phi1(i128 %raw,ptr %input,ptr %out,i64 %live) {
entry:
 %a = bitcast i128 %raw to fp128
 %b = load fp128,ptr %input,align 1
 %low = trunc i128 %raw to i64
 %masked = and i64 %low,3
 %limit = add i64 %masked,1
 %narrow_limit = trunc i64 %limit to i56
 %choice = trunc i64 %live to i1
 br i1 %choice,label %loop,label %exit
loop:
 %x = phi fp128 [ %a,%entry ],[ %y,%loop ]
 %y = phi fp128 [ 0xL0123456789ABCDEF7FFF800000000123,%entry ],[ %x,%loop ]
 %flag = phi i32 [ 4294967295,%entry ],[ %flag_next,%loop ]
 %n = phi i56 [ 0,%entry ],[ %next,%loop ]
 %flag_next = or i32 %flag,0
 %next = add i56 %n,1
 %again = icmp ult i56 %next,%narrow_limit
 br i1 %again,label %loop,label %exit
exit:
 %picked = phi fp128 [ 0xL0123456789ABCDEF7FFF800000000123,%entry ],[ %x,%loop ]
 %return_flag = phi i32 [ 4294967295,%entry ],[ %flag,%loop ]
 %saved_raw = call i64 @vector_transport_clobber(i64 %live)
 %flag_bits = zext i32 %return_flag to i64
 %saved = xor i64 %saved_raw,%flag_bits
 store fp128 %picked,ptr %out,align 1
 %bits = bitcast fp128 %picked to i128
 %extended = zext i64 %saved to i128
 %result = xor i128 %bits,%extended
 ret i128 %result
}
define i128 @vector_transport_literal_chain(i128 %raw,ptr %input,ptr %out,i64 %live) {
entry:
 %a = bitcast i128 %raw to fp128
 %r0 = call fp128 @vector_transport_probe(fp128 %a,fp128 0xL00000000000000004000400000000000)
 %r1 = call fp128 @vector_transport_probe(fp128 %r0,fp128 0xL00000000000000004000400000000000)
 %r2 = call fp128 @vector_transport_probe(fp128 %r1,fp128 0xL00000000000000004000400000000000)
 %r3 = call fp128 @vector_transport_probe(fp128 %r2,fp128 0xL00000000000000004000400000000000)
 %r4 = call fp128 @vector_transport_probe(fp128 %r3,fp128 0xL00000000000000004000400000000000)
 %r5 = call fp128 @vector_transport_probe(fp128 %r4,fp128 0xL00000000000000004000400000000000)
 %r6 = call fp128 @vector_transport_probe(fp128 %r5,fp128 0xL00000000000000004000400000000000)
 %r7 = call fp128 @vector_transport_probe(fp128 %r6,fp128 0xL00000000000000004000400000000000)
 %r8 = call fp128 @vector_transport_probe(fp128 %r7,fp128 0xL00000000000000004000400000000000)
 %r9 = call fp128 @vector_transport_probe(fp128 %r8,fp128 0xL00000000000000004000400000000000)
 %r10 = call fp128 @vector_transport_probe(fp128 %r9,fp128 0xL00000000000000004000400000000000)
 %r11 = call fp128 @vector_transport_probe(fp128 %r10,fp128 0xL00000000000000004000400000000000)
 %r12 = call fp128 @vector_transport_probe(fp128 %r11,fp128 0xL00000000000000004000400000000000)
 %r13 = call fp128 @vector_transport_probe(fp128 %r12,fp128 0xL00000000000000004000400000000000)
 %r14 = call fp128 @vector_transport_probe(fp128 %r13,fp128 0xL00000000000000004000400000000000)
 %r15 = call fp128 @vector_transport_probe(fp128 %r14,fp128 0xL00000000000000004000400000000000)
 %r16 = call fp128 @vector_transport_probe(fp128 %r15,fp128 0xL00000000000000004000400000000000)
 %r17 = call fp128 @vector_transport_probe(fp128 %r16,fp128 0xL00000000000000004000400000000000)
 %r18 = call fp128 @vector_transport_probe(fp128 %r17,fp128 0xL00000000000000004000400000000000)
 %r19 = call fp128 @vector_transport_probe(fp128 %r18,fp128 0xL00000000000000004000400000000000)
 %r20 = call fp128 @vector_transport_probe(fp128 %r19,fp128 0xL00000000000000004000400000000000)
 %r21 = call fp128 @vector_transport_probe(fp128 %r20,fp128 0xL00000000000000004000400000000000)
 %r22 = call fp128 @vector_transport_probe(fp128 %r21,fp128 0xL00000000000000004000400000000000)
 %r23 = call fp128 @vector_transport_probe(fp128 %r22,fp128 0xL00000000000000004000400000000000)
 %r24 = call fp128 @vector_transport_probe(fp128 %r23,fp128 0xL00000000000000004000400000000000)
 %r25 = call fp128 @vector_transport_probe(fp128 %r24,fp128 0xL00000000000000004000400000000000)
 %r26 = call fp128 @vector_transport_probe(fp128 %r25,fp128 0xL00000000000000004000400000000000)
 %r27 = call fp128 @vector_transport_probe(fp128 %r26,fp128 0xL00000000000000004000400000000000)
 %r28 = call fp128 @vector_transport_probe(fp128 %r27,fp128 0xL00000000000000004000400000000000)
 %r29 = call fp128 @vector_transport_probe(fp128 %r28,fp128 0xL00000000000000004000400000000000)
 %r30 = call fp128 @vector_transport_probe(fp128 %r29,fp128 0xL00000000000000004000400000000000)
 %r31 = call fp128 @vector_transport_probe(fp128 %r30,fp128 0xL00000000000000004000400000000000)
 %r32 = call fp128 @vector_transport_probe(fp128 %r31,fp128 0xL00000000000000004000400000000000)
 %r33 = call fp128 @vector_transport_probe(fp128 %r32,fp128 0xL00000000000000004000400000000000)
 %r34 = call fp128 @vector_transport_probe(fp128 %r33,fp128 0xL00000000000000004000400000000000)
 %r35 = call fp128 @vector_transport_probe(fp128 %r34,fp128 0xL00000000000000004000400000000000)
 %r36 = call fp128 @vector_transport_probe(fp128 %r35,fp128 0xL00000000000000004000400000000000)
 %r37 = call fp128 @vector_transport_probe(fp128 %r36,fp128 0xL00000000000000004000400000000000)
 %r38 = call fp128 @vector_transport_probe(fp128 %r37,fp128 0xL00000000000000004000400000000000)
 %r39 = call fp128 @vector_transport_probe(fp128 %r38,fp128 0xL00000000000000004000400000000000)
 %r40 = call fp128 @vector_transport_probe(fp128 %r39,fp128 0xL00000000000000004000400000000000)
 %r41 = call fp128 @vector_transport_probe(fp128 %r40,fp128 0xL00000000000000004000400000000000)
 %r42 = call fp128 @vector_transport_probe(fp128 %r41,fp128 0xL00000000000000004000400000000000)
 %r43 = call fp128 @vector_transport_probe(fp128 %r42,fp128 0xL00000000000000004000400000000000)
 %r44 = call fp128 @vector_transport_probe(fp128 %r43,fp128 0xL00000000000000004000400000000000)
 %r45 = call fp128 @vector_transport_probe(fp128 %r44,fp128 0xL00000000000000004000400000000000)
 %r46 = call fp128 @vector_transport_probe(fp128 %r45,fp128 0xL00000000000000004000400000000000)
 %r47 = call fp128 @vector_transport_probe(fp128 %r46,fp128 0xL00000000000000004000400000000000)
 %r48 = call fp128 @vector_transport_probe(fp128 %r47,fp128 0xL00000000000000004000400000000000)
 %r49 = call fp128 @vector_transport_probe(fp128 %r48,fp128 0xL00000000000000004000400000000000)
 %r50 = call fp128 @vector_transport_probe(fp128 %r49,fp128 0xL00000000000000004000400000000000)
 %r51 = call fp128 @vector_transport_probe(fp128 %r50,fp128 0xL00000000000000004000400000000000)
 %r52 = call fp128 @vector_transport_probe(fp128 %r51,fp128 0xL00000000000000004000400000000000)
 %r53 = call fp128 @vector_transport_probe(fp128 %r52,fp128 0xL00000000000000004000400000000000)
 %r54 = call fp128 @vector_transport_probe(fp128 %r53,fp128 0xL00000000000000004000400000000000)
 %r55 = call fp128 @vector_transport_probe(fp128 %r54,fp128 0xL00000000000000004000400000000000)
 %r56 = call fp128 @vector_transport_probe(fp128 %r55,fp128 0xL00000000000000004000400000000000)
 %r57 = call fp128 @vector_transport_probe(fp128 %r56,fp128 0xL00000000000000004000400000000000)
 %r58 = call fp128 @vector_transport_probe(fp128 %r57,fp128 0xL00000000000000004000400000000000)
 %r59 = call fp128 @vector_transport_probe(fp128 %r58,fp128 0xL00000000000000004000400000000000)
 %r60 = call fp128 @vector_transport_probe(fp128 %r59,fp128 0xL00000000000000004000400000000000)
 %r61 = call fp128 @vector_transport_probe(fp128 %r60,fp128 0xL00000000000000004000400000000000)
 %r62 = call fp128 @vector_transport_probe(fp128 %r61,fp128 0xL00000000000000004000400000000000)
 %r63 = call fp128 @vector_transport_probe(fp128 %r62,fp128 0xL00000000000000004000400000000000)
 %r64 = call fp128 @vector_transport_probe(fp128 %r63,fp128 0xL00000000000000004000400000000000)
 %r65 = call fp128 @vector_transport_probe(fp128 %r64,fp128 0xL00000000000000004000400000000000)
 %r66 = call fp128 @vector_transport_probe(fp128 %r65,fp128 0xL00000000000000004000400000000000)
 %r67 = call fp128 @vector_transport_probe(fp128 %r66,fp128 0xL00000000000000004000400000000000)
 %r68 = call fp128 @vector_transport_probe(fp128 %r67,fp128 0xL00000000000000004000400000000000)
 %r69 = call fp128 @vector_transport_probe(fp128 %r68,fp128 0xL00000000000000004000400000000000)
 %r70 = call fp128 @vector_transport_probe(fp128 %r69,fp128 0xL00000000000000004000400000000000)
 %r71 = call fp128 @vector_transport_probe(fp128 %r70,fp128 0xL00000000000000004000400000000000)
 %r72 = call fp128 @vector_transport_probe(fp128 %r71,fp128 0xL00000000000000004000400000000000)
 %r73 = call fp128 @vector_transport_probe(fp128 %r72,fp128 0xL00000000000000004000400000000000)
 %r74 = call fp128 @vector_transport_probe(fp128 %r73,fp128 0xL00000000000000004000400000000000)
 %r75 = call fp128 @vector_transport_probe(fp128 %r74,fp128 0xL00000000000000004000400000000000)
 %r76 = call fp128 @vector_transport_probe(fp128 %r75,fp128 0xL00000000000000004000400000000000)
 %r77 = call fp128 @vector_transport_probe(fp128 %r76,fp128 0xL00000000000000004000400000000000)
 %r78 = call fp128 @vector_transport_probe(fp128 %r77,fp128 0xL00000000000000004000400000000000)
 %r79 = call fp128 @vector_transport_probe(fp128 %r78,fp128 0xL00000000000000004000400000000000)
 %r80 = call fp128 @vector_transport_probe(fp128 %r79,fp128 0xL00000000000000004000400000000000)
 %r81 = call fp128 @vector_transport_probe(fp128 %r80,fp128 0xL00000000000000004000400000000000)
 %r82 = call fp128 @vector_transport_probe(fp128 %r81,fp128 0xL00000000000000004000400000000000)
 %r83 = call fp128 @vector_transport_probe(fp128 %r82,fp128 0xL00000000000000004000400000000000)
 %r84 = call fp128 @vector_transport_probe(fp128 %r83,fp128 0xL00000000000000004000400000000000)
 %r85 = call fp128 @vector_transport_probe(fp128 %r84,fp128 0xL00000000000000004000400000000000)
 %r86 = call fp128 @vector_transport_probe(fp128 %r85,fp128 0xL00000000000000004000400000000000)
 %r87 = call fp128 @vector_transport_probe(fp128 %r86,fp128 0xL00000000000000004000400000000000)
 %r88 = call fp128 @vector_transport_probe(fp128 %r87,fp128 0xL00000000000000004000400000000000)
 %r89 = call fp128 @vector_transport_probe(fp128 %r88,fp128 0xL00000000000000004000400000000000)
 %r90 = call fp128 @vector_transport_probe(fp128 %r89,fp128 0xL00000000000000004000400000000000)
 %r91 = call fp128 @vector_transport_probe(fp128 %r90,fp128 0xL00000000000000004000400000000000)
 %r92 = call fp128 @vector_transport_probe(fp128 %r91,fp128 0xL00000000000000004000400000000000)
 %r93 = call fp128 @vector_transport_probe(fp128 %r92,fp128 0xL00000000000000004000400000000000)
 %r94 = call fp128 @vector_transport_probe(fp128 %r93,fp128 0xL00000000000000004000400000000000)
 %r95 = call fp128 @vector_transport_probe(fp128 %r94,fp128 0xL00000000000000004000400000000000)
 %r96 = call fp128 @vector_transport_probe(fp128 %r95,fp128 0xL00000000000000004000400000000000)
 %saved = call i64 @vector_transport_clobber(i64 %live)
 store fp128 %r96,ptr %out,align 1
 %bits = bitcast fp128 %r96 to i128
 %extended = zext i64 %saved to i128
 %result = xor i128 %bits,%extended
 ret i128 %result
}
define i128 @vector_transport_stack_sentinel(i128 %raw,ptr %input,ptr %out,i64 %live) {
entry:
 %slot = alloca [8 x i8],align 8
 %low = trunc i128 %raw to i64
 store i64 %low,ptr %slot,align 8
 %before = getelementptr i8,ptr %slot,i64 -1
 %pointer = getelementptr i8,ptr %before,i64 1
 %value = load i64,ptr %pointer,align 1
 %saved = call i64 @vector_transport_clobber(i64 %live)
 store i64 %value,ptr %out,align 1
 %wide = zext i64 %value to i128
 %extended = zext i64 %saved to i128
 %result = xor i128 %wide,%extended
 ret i128 %result
}
