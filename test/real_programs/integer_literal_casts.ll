target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"
define i64 @integer_literal_casts(ptr %out,i64 %salt,i64 %seed) {
entry:
 %s0 = zext i2 0 to i8
 %w0 = zext i8 %s0 to i64
 %m0 = xor i64 %w0,%salt
 %v0 = add i64 %m0,%seed
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %v0,ptr %p0,align 1
 %s1 = zext i2 1 to i8
 %w1 = zext i8 %s1 to i64
 %m1 = xor i64 %w1,%salt
 %v1 = add i64 %m1,%seed
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %v1,ptr %p1,align 1
 %s2 = zext i2 -1 to i8
 %w2 = zext i8 %s2 to i64
 %m2 = xor i64 %w2,%salt
 %v2 = add i64 %m2,%seed
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %v2,ptr %p2,align 1
 %s3 = zext i2 -2 to i8
 %w3 = zext i8 %s3 to i64
 %m3 = xor i64 %w3,%salt
 %v3 = add i64 %m3,%seed
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %v3,ptr %p3,align 1
 %s4 = zext i2 1 to i8
 %w4 = zext i8 %s4 to i64
 %m4 = xor i64 %w4,%salt
 %v4 = add i64 %m4,%seed
 %p4 = getelementptr i8,ptr %out,i64 32
 store i64 %v4,ptr %p4,align 1
 %s5 = zext i2 3 to i8
 %w5 = zext i8 %s5 to i64
 %m5 = xor i64 %w5,%salt
 %v5 = add i64 %m5,%seed
 %p5 = getelementptr i8,ptr %out,i64 40
 store i64 %v5,ptr %p5,align 1
 %s6 = zext i2 0 to i16
 %w6 = zext i16 %s6 to i64
 %m6 = xor i64 %w6,%salt
 %v6 = add i64 %m6,%seed
 %p6 = getelementptr i8,ptr %out,i64 48
 store i64 %v6,ptr %p6,align 1
 %s7 = zext i2 1 to i16
 %w7 = zext i16 %s7 to i64
 %m7 = xor i64 %w7,%salt
 %v7 = add i64 %m7,%seed
 %p7 = getelementptr i8,ptr %out,i64 56
 store i64 %v7,ptr %p7,align 1
 %s8 = zext i2 -1 to i16
 %w8 = zext i16 %s8 to i64
 %m8 = xor i64 %w8,%salt
 %v8 = add i64 %m8,%seed
 %p8 = getelementptr i8,ptr %out,i64 64
 store i64 %v8,ptr %p8,align 1
 %s9 = zext i2 -2 to i16
 %w9 = zext i16 %s9 to i64
 %m9 = xor i64 %w9,%salt
 %v9 = add i64 %m9,%seed
 %p9 = getelementptr i8,ptr %out,i64 72
 store i64 %v9,ptr %p9,align 1
 %s10 = zext i2 1 to i16
 %w10 = zext i16 %s10 to i64
 %m10 = xor i64 %w10,%salt
 %v10 = add i64 %m10,%seed
 %p10 = getelementptr i8,ptr %out,i64 80
 store i64 %v10,ptr %p10,align 1
 %s11 = zext i2 3 to i16
 %w11 = zext i16 %s11 to i64
 %m11 = xor i64 %w11,%salt
 %v11 = add i64 %m11,%seed
 %p11 = getelementptr i8,ptr %out,i64 88
 store i64 %v11,ptr %p11,align 1
 %s12 = zext i2 0 to i32
 %w12 = zext i32 %s12 to i64
 %m12 = xor i64 %w12,%salt
 %v12 = add i64 %m12,%seed
 %p12 = getelementptr i8,ptr %out,i64 96
 store i64 %v12,ptr %p12,align 1
 %s13 = zext i2 1 to i32
 %w13 = zext i32 %s13 to i64
 %m13 = xor i64 %w13,%salt
 %v13 = add i64 %m13,%seed
 %p13 = getelementptr i8,ptr %out,i64 104
 store i64 %v13,ptr %p13,align 1
 %s14 = zext i2 -1 to i32
 %w14 = zext i32 %s14 to i64
 %m14 = xor i64 %w14,%salt
 %v14 = add i64 %m14,%seed
 %p14 = getelementptr i8,ptr %out,i64 112
 store i64 %v14,ptr %p14,align 1
 %s15 = zext i2 -2 to i32
 %w15 = zext i32 %s15 to i64
 %m15 = xor i64 %w15,%salt
 %v15 = add i64 %m15,%seed
 %p15 = getelementptr i8,ptr %out,i64 120
 store i64 %v15,ptr %p15,align 1
 %s16 = zext i2 1 to i32
 %w16 = zext i32 %s16 to i64
 %m16 = xor i64 %w16,%salt
 %v16 = add i64 %m16,%seed
 %p16 = getelementptr i8,ptr %out,i64 128
 store i64 %v16,ptr %p16,align 1
 %s17 = zext i2 3 to i32
 %w17 = zext i32 %s17 to i64
 %m17 = xor i64 %w17,%salt
 %v17 = add i64 %m17,%seed
 %p17 = getelementptr i8,ptr %out,i64 136
 store i64 %v17,ptr %p17,align 1
 %s18 = zext i2 0 to i64
 %w18 = xor i64 %s18,0
 %m18 = xor i64 %w18,%salt
 %v18 = add i64 %m18,%seed
 %p18 = getelementptr i8,ptr %out,i64 144
 store i64 %v18,ptr %p18,align 1
 %s19 = zext i2 1 to i64
 %w19 = xor i64 %s19,0
 %m19 = xor i64 %w19,%salt
 %v19 = add i64 %m19,%seed
 %p19 = getelementptr i8,ptr %out,i64 152
 store i64 %v19,ptr %p19,align 1
 %s20 = zext i2 -1 to i64
 %w20 = xor i64 %s20,0
 %m20 = xor i64 %w20,%salt
 %v20 = add i64 %m20,%seed
 %p20 = getelementptr i8,ptr %out,i64 160
 store i64 %v20,ptr %p20,align 1
 %s21 = zext i2 -2 to i64
 %w21 = xor i64 %s21,0
 %m21 = xor i64 %w21,%salt
 %v21 = add i64 %m21,%seed
 %p21 = getelementptr i8,ptr %out,i64 168
 store i64 %v21,ptr %p21,align 1
 %s22 = zext i2 1 to i64
 %w22 = xor i64 %s22,0
 %m22 = xor i64 %w22,%salt
 %v22 = add i64 %m22,%seed
 %p22 = getelementptr i8,ptr %out,i64 176
 store i64 %v22,ptr %p22,align 1
 %s23 = zext i2 3 to i64
 %w23 = xor i64 %s23,0
 %m23 = xor i64 %w23,%salt
 %v23 = add i64 %m23,%seed
 %p23 = getelementptr i8,ptr %out,i64 184
 store i64 %v23,ptr %p23,align 1
 %s24 = zext i3 0 to i8
 %w24 = zext i8 %s24 to i64
 %m24 = xor i64 %w24,%salt
 %v24 = add i64 %m24,%seed
 %p24 = getelementptr i8,ptr %out,i64 192
 store i64 %v24,ptr %p24,align 1
 %s25 = zext i3 1 to i8
 %w25 = zext i8 %s25 to i64
 %m25 = xor i64 %w25,%salt
 %v25 = add i64 %m25,%seed
 %p25 = getelementptr i8,ptr %out,i64 200
 store i64 %v25,ptr %p25,align 1
 %s26 = zext i3 -1 to i8
 %w26 = zext i8 %s26 to i64
 %m26 = xor i64 %w26,%salt
 %v26 = add i64 %m26,%seed
 %p26 = getelementptr i8,ptr %out,i64 208
 store i64 %v26,ptr %p26,align 1
 %s27 = zext i3 -4 to i8
 %w27 = zext i8 %s27 to i64
 %m27 = xor i64 %w27,%salt
 %v27 = add i64 %m27,%seed
 %p27 = getelementptr i8,ptr %out,i64 216
 store i64 %v27,ptr %p27,align 1
 %s28 = zext i3 3 to i8
 %w28 = zext i8 %s28 to i64
 %m28 = xor i64 %w28,%salt
 %v28 = add i64 %m28,%seed
 %p28 = getelementptr i8,ptr %out,i64 224
 store i64 %v28,ptr %p28,align 1
 %s29 = zext i3 7 to i8
 %w29 = zext i8 %s29 to i64
 %m29 = xor i64 %w29,%salt
 %v29 = add i64 %m29,%seed
 %p29 = getelementptr i8,ptr %out,i64 232
 store i64 %v29,ptr %p29,align 1
 %s30 = zext i3 0 to i16
 %w30 = zext i16 %s30 to i64
 %m30 = xor i64 %w30,%salt
 %v30 = add i64 %m30,%seed
 %p30 = getelementptr i8,ptr %out,i64 240
 store i64 %v30,ptr %p30,align 1
 %s31 = zext i3 1 to i16
 %w31 = zext i16 %s31 to i64
 %m31 = xor i64 %w31,%salt
 %v31 = add i64 %m31,%seed
 %p31 = getelementptr i8,ptr %out,i64 248
 store i64 %v31,ptr %p31,align 1
 %s32 = zext i3 -1 to i16
 %w32 = zext i16 %s32 to i64
 %m32 = xor i64 %w32,%salt
 %v32 = add i64 %m32,%seed
 %p32 = getelementptr i8,ptr %out,i64 256
 store i64 %v32,ptr %p32,align 1
 %s33 = zext i3 -4 to i16
 %w33 = zext i16 %s33 to i64
 %m33 = xor i64 %w33,%salt
 %v33 = add i64 %m33,%seed
 %p33 = getelementptr i8,ptr %out,i64 264
 store i64 %v33,ptr %p33,align 1
 %s34 = zext i3 3 to i16
 %w34 = zext i16 %s34 to i64
 %m34 = xor i64 %w34,%salt
 %v34 = add i64 %m34,%seed
 %p34 = getelementptr i8,ptr %out,i64 272
 store i64 %v34,ptr %p34,align 1
 %s35 = zext i3 7 to i16
 %w35 = zext i16 %s35 to i64
 %m35 = xor i64 %w35,%salt
 %v35 = add i64 %m35,%seed
 %p35 = getelementptr i8,ptr %out,i64 280
 store i64 %v35,ptr %p35,align 1
 %s36 = zext i3 0 to i32
 %w36 = zext i32 %s36 to i64
 %m36 = xor i64 %w36,%salt
 %v36 = add i64 %m36,%seed
 %p36 = getelementptr i8,ptr %out,i64 288
 store i64 %v36,ptr %p36,align 1
 %s37 = zext i3 1 to i32
 %w37 = zext i32 %s37 to i64
 %m37 = xor i64 %w37,%salt
 %v37 = add i64 %m37,%seed
 %p37 = getelementptr i8,ptr %out,i64 296
 store i64 %v37,ptr %p37,align 1
 %s38 = zext i3 -1 to i32
 %w38 = zext i32 %s38 to i64
 %m38 = xor i64 %w38,%salt
 %v38 = add i64 %m38,%seed
 %p38 = getelementptr i8,ptr %out,i64 304
 store i64 %v38,ptr %p38,align 1
 %s39 = zext i3 -4 to i32
 %w39 = zext i32 %s39 to i64
 %m39 = xor i64 %w39,%salt
 %v39 = add i64 %m39,%seed
 %p39 = getelementptr i8,ptr %out,i64 312
 store i64 %v39,ptr %p39,align 1
 %s40 = zext i3 3 to i32
 %w40 = zext i32 %s40 to i64
 %m40 = xor i64 %w40,%salt
 %v40 = add i64 %m40,%seed
 %p40 = getelementptr i8,ptr %out,i64 320
 store i64 %v40,ptr %p40,align 1
 %s41 = zext i3 7 to i32
 %w41 = zext i32 %s41 to i64
 %m41 = xor i64 %w41,%salt
 %v41 = add i64 %m41,%seed
 %p41 = getelementptr i8,ptr %out,i64 328
 store i64 %v41,ptr %p41,align 1
 %s42 = zext i3 0 to i64
 %w42 = xor i64 %s42,0
 %m42 = xor i64 %w42,%salt
 %v42 = add i64 %m42,%seed
 %p42 = getelementptr i8,ptr %out,i64 336
 store i64 %v42,ptr %p42,align 1
 %s43 = zext i3 1 to i64
 %w43 = xor i64 %s43,0
 %m43 = xor i64 %w43,%salt
 %v43 = add i64 %m43,%seed
 %p43 = getelementptr i8,ptr %out,i64 344
 store i64 %v43,ptr %p43,align 1
 %s44 = zext i3 -1 to i64
 %w44 = xor i64 %s44,0
 %m44 = xor i64 %w44,%salt
 %v44 = add i64 %m44,%seed
 %p44 = getelementptr i8,ptr %out,i64 352
 store i64 %v44,ptr %p44,align 1
 %s45 = zext i3 -4 to i64
 %w45 = xor i64 %s45,0
 %m45 = xor i64 %w45,%salt
 %v45 = add i64 %m45,%seed
 %p45 = getelementptr i8,ptr %out,i64 360
 store i64 %v45,ptr %p45,align 1
 %s46 = zext i3 3 to i64
 %w46 = xor i64 %s46,0
 %m46 = xor i64 %w46,%salt
 %v46 = add i64 %m46,%seed
 %p46 = getelementptr i8,ptr %out,i64 368
 store i64 %v46,ptr %p46,align 1
 %s47 = zext i3 7 to i64
 %w47 = xor i64 %s47,0
 %m47 = xor i64 %w47,%salt
 %v47 = add i64 %m47,%seed
 %p47 = getelementptr i8,ptr %out,i64 376
 store i64 %v47,ptr %p47,align 1
 %s48 = zext i6 0 to i8
 %w48 = zext i8 %s48 to i64
 %m48 = xor i64 %w48,%salt
 %v48 = add i64 %m48,%seed
 %p48 = getelementptr i8,ptr %out,i64 384
 store i64 %v48,ptr %p48,align 1
 %s49 = zext i6 1 to i8
 %w49 = zext i8 %s49 to i64
 %m49 = xor i64 %w49,%salt
 %v49 = add i64 %m49,%seed
 %p49 = getelementptr i8,ptr %out,i64 392
 store i64 %v49,ptr %p49,align 1
 %s50 = zext i6 -1 to i8
 %w50 = zext i8 %s50 to i64
 %m50 = xor i64 %w50,%salt
 %v50 = add i64 %m50,%seed
 %p50 = getelementptr i8,ptr %out,i64 400
 store i64 %v50,ptr %p50,align 1
 %s51 = zext i6 -32 to i8
 %w51 = zext i8 %s51 to i64
 %m51 = xor i64 %w51,%salt
 %v51 = add i64 %m51,%seed
 %p51 = getelementptr i8,ptr %out,i64 408
 store i64 %v51,ptr %p51,align 1
 %s52 = zext i6 31 to i8
 %w52 = zext i8 %s52 to i64
 %m52 = xor i64 %w52,%salt
 %v52 = add i64 %m52,%seed
 %p52 = getelementptr i8,ptr %out,i64 416
 store i64 %v52,ptr %p52,align 1
 %s53 = zext i6 63 to i8
 %w53 = zext i8 %s53 to i64
 %m53 = xor i64 %w53,%salt
 %v53 = add i64 %m53,%seed
 %p53 = getelementptr i8,ptr %out,i64 424
 store i64 %v53,ptr %p53,align 1
 %s54 = zext i6 0 to i16
 %w54 = zext i16 %s54 to i64
 %m54 = xor i64 %w54,%salt
 %v54 = add i64 %m54,%seed
 %p54 = getelementptr i8,ptr %out,i64 432
 store i64 %v54,ptr %p54,align 1
 %s55 = zext i6 1 to i16
 %w55 = zext i16 %s55 to i64
 %m55 = xor i64 %w55,%salt
 %v55 = add i64 %m55,%seed
 %p55 = getelementptr i8,ptr %out,i64 440
 store i64 %v55,ptr %p55,align 1
 %s56 = zext i6 -1 to i16
 %w56 = zext i16 %s56 to i64
 %m56 = xor i64 %w56,%salt
 %v56 = add i64 %m56,%seed
 %p56 = getelementptr i8,ptr %out,i64 448
 store i64 %v56,ptr %p56,align 1
 %s57 = zext i6 -32 to i16
 %w57 = zext i16 %s57 to i64
 %m57 = xor i64 %w57,%salt
 %v57 = add i64 %m57,%seed
 %p57 = getelementptr i8,ptr %out,i64 456
 store i64 %v57,ptr %p57,align 1
 %s58 = zext i6 31 to i16
 %w58 = zext i16 %s58 to i64
 %m58 = xor i64 %w58,%salt
 %v58 = add i64 %m58,%seed
 %p58 = getelementptr i8,ptr %out,i64 464
 store i64 %v58,ptr %p58,align 1
 %s59 = zext i6 63 to i16
 %w59 = zext i16 %s59 to i64
 %m59 = xor i64 %w59,%salt
 %v59 = add i64 %m59,%seed
 %p59 = getelementptr i8,ptr %out,i64 472
 store i64 %v59,ptr %p59,align 1
 %s60 = zext i6 0 to i32
 %w60 = zext i32 %s60 to i64
 %m60 = xor i64 %w60,%salt
 %v60 = add i64 %m60,%seed
 %p60 = getelementptr i8,ptr %out,i64 480
 store i64 %v60,ptr %p60,align 1
 %s61 = zext i6 1 to i32
 %w61 = zext i32 %s61 to i64
 %m61 = xor i64 %w61,%salt
 %v61 = add i64 %m61,%seed
 %p61 = getelementptr i8,ptr %out,i64 488
 store i64 %v61,ptr %p61,align 1
 %s62 = zext i6 -1 to i32
 %w62 = zext i32 %s62 to i64
 %m62 = xor i64 %w62,%salt
 %v62 = add i64 %m62,%seed
 %p62 = getelementptr i8,ptr %out,i64 496
 store i64 %v62,ptr %p62,align 1
 %s63 = zext i6 -32 to i32
 %w63 = zext i32 %s63 to i64
 %m63 = xor i64 %w63,%salt
 %v63 = add i64 %m63,%seed
 %p63 = getelementptr i8,ptr %out,i64 504
 store i64 %v63,ptr %p63,align 1
 %s64 = zext i6 31 to i32
 %w64 = zext i32 %s64 to i64
 %m64 = xor i64 %w64,%salt
 %v64 = add i64 %m64,%seed
 %p64 = getelementptr i8,ptr %out,i64 512
 store i64 %v64,ptr %p64,align 1
 %s65 = zext i6 63 to i32
 %w65 = zext i32 %s65 to i64
 %m65 = xor i64 %w65,%salt
 %v65 = add i64 %m65,%seed
 %p65 = getelementptr i8,ptr %out,i64 520
 store i64 %v65,ptr %p65,align 1
 %s66 = zext i6 0 to i64
 %w66 = xor i64 %s66,0
 %m66 = xor i64 %w66,%salt
 %v66 = add i64 %m66,%seed
 %p66 = getelementptr i8,ptr %out,i64 528
 store i64 %v66,ptr %p66,align 1
 %s67 = zext i6 1 to i64
 %w67 = xor i64 %s67,0
 %m67 = xor i64 %w67,%salt
 %v67 = add i64 %m67,%seed
 %p67 = getelementptr i8,ptr %out,i64 536
 store i64 %v67,ptr %p67,align 1
 %s68 = zext i6 -1 to i64
 %w68 = xor i64 %s68,0
 %m68 = xor i64 %w68,%salt
 %v68 = add i64 %m68,%seed
 %p68 = getelementptr i8,ptr %out,i64 544
 store i64 %v68,ptr %p68,align 1
 %s69 = zext i6 -32 to i64
 %w69 = xor i64 %s69,0
 %m69 = xor i64 %w69,%salt
 %v69 = add i64 %m69,%seed
 %p69 = getelementptr i8,ptr %out,i64 552
 store i64 %v69,ptr %p69,align 1
 %s70 = zext i6 31 to i64
 %w70 = xor i64 %s70,0
 %m70 = xor i64 %w70,%salt
 %v70 = add i64 %m70,%seed
 %p70 = getelementptr i8,ptr %out,i64 560
 store i64 %v70,ptr %p70,align 1
 %s71 = zext i6 63 to i64
 %w71 = xor i64 %s71,0
 %m71 = xor i64 %w71,%salt
 %v71 = add i64 %m71,%seed
 %p71 = getelementptr i8,ptr %out,i64 568
 store i64 %v71,ptr %p71,align 1
 %s72 = zext i7 0 to i8
 %w72 = zext i8 %s72 to i64
 %m72 = xor i64 %w72,%salt
 %v72 = add i64 %m72,%seed
 %p72 = getelementptr i8,ptr %out,i64 576
 store i64 %v72,ptr %p72,align 1
 %s73 = zext i7 1 to i8
 %w73 = zext i8 %s73 to i64
 %m73 = xor i64 %w73,%salt
 %v73 = add i64 %m73,%seed
 %p73 = getelementptr i8,ptr %out,i64 584
 store i64 %v73,ptr %p73,align 1
 %s74 = zext i7 -1 to i8
 %w74 = zext i8 %s74 to i64
 %m74 = xor i64 %w74,%salt
 %v74 = add i64 %m74,%seed
 %p74 = getelementptr i8,ptr %out,i64 592
 store i64 %v74,ptr %p74,align 1
 %s75 = zext i7 -64 to i8
 %w75 = zext i8 %s75 to i64
 %m75 = xor i64 %w75,%salt
 %v75 = add i64 %m75,%seed
 %p75 = getelementptr i8,ptr %out,i64 600
 store i64 %v75,ptr %p75,align 1
 %s76 = zext i7 63 to i8
 %w76 = zext i8 %s76 to i64
 %m76 = xor i64 %w76,%salt
 %v76 = add i64 %m76,%seed
 %p76 = getelementptr i8,ptr %out,i64 608
 store i64 %v76,ptr %p76,align 1
 %s77 = zext i7 127 to i8
 %w77 = zext i8 %s77 to i64
 %m77 = xor i64 %w77,%salt
 %v77 = add i64 %m77,%seed
 %p77 = getelementptr i8,ptr %out,i64 616
 store i64 %v77,ptr %p77,align 1
 %s78 = zext i7 0 to i16
 %w78 = zext i16 %s78 to i64
 %m78 = xor i64 %w78,%salt
 %v78 = add i64 %m78,%seed
 %p78 = getelementptr i8,ptr %out,i64 624
 store i64 %v78,ptr %p78,align 1
 %s79 = zext i7 1 to i16
 %w79 = zext i16 %s79 to i64
 %m79 = xor i64 %w79,%salt
 %v79 = add i64 %m79,%seed
 %p79 = getelementptr i8,ptr %out,i64 632
 store i64 %v79,ptr %p79,align 1
 %s80 = zext i7 -1 to i16
 %w80 = zext i16 %s80 to i64
 %m80 = xor i64 %w80,%salt
 %v80 = add i64 %m80,%seed
 %p80 = getelementptr i8,ptr %out,i64 640
 store i64 %v80,ptr %p80,align 1
 %s81 = zext i7 -64 to i16
 %w81 = zext i16 %s81 to i64
 %m81 = xor i64 %w81,%salt
 %v81 = add i64 %m81,%seed
 %p81 = getelementptr i8,ptr %out,i64 648
 store i64 %v81,ptr %p81,align 1
 %s82 = zext i7 63 to i16
 %w82 = zext i16 %s82 to i64
 %m82 = xor i64 %w82,%salt
 %v82 = add i64 %m82,%seed
 %p82 = getelementptr i8,ptr %out,i64 656
 store i64 %v82,ptr %p82,align 1
 %s83 = zext i7 127 to i16
 %w83 = zext i16 %s83 to i64
 %m83 = xor i64 %w83,%salt
 %v83 = add i64 %m83,%seed
 %p83 = getelementptr i8,ptr %out,i64 664
 store i64 %v83,ptr %p83,align 1
 %s84 = zext i7 0 to i32
 %w84 = zext i32 %s84 to i64
 %m84 = xor i64 %w84,%salt
 %v84 = add i64 %m84,%seed
 %p84 = getelementptr i8,ptr %out,i64 672
 store i64 %v84,ptr %p84,align 1
 %s85 = zext i7 1 to i32
 %w85 = zext i32 %s85 to i64
 %m85 = xor i64 %w85,%salt
 %v85 = add i64 %m85,%seed
 %p85 = getelementptr i8,ptr %out,i64 680
 store i64 %v85,ptr %p85,align 1
 %s86 = zext i7 -1 to i32
 %w86 = zext i32 %s86 to i64
 %m86 = xor i64 %w86,%salt
 %v86 = add i64 %m86,%seed
 %p86 = getelementptr i8,ptr %out,i64 688
 store i64 %v86,ptr %p86,align 1
 %s87 = zext i7 -64 to i32
 %w87 = zext i32 %s87 to i64
 %m87 = xor i64 %w87,%salt
 %v87 = add i64 %m87,%seed
 %p87 = getelementptr i8,ptr %out,i64 696
 store i64 %v87,ptr %p87,align 1
 %s88 = zext i7 63 to i32
 %w88 = zext i32 %s88 to i64
 %m88 = xor i64 %w88,%salt
 %v88 = add i64 %m88,%seed
 %p88 = getelementptr i8,ptr %out,i64 704
 store i64 %v88,ptr %p88,align 1
 %s89 = zext i7 127 to i32
 %w89 = zext i32 %s89 to i64
 %m89 = xor i64 %w89,%salt
 %v89 = add i64 %m89,%seed
 %p89 = getelementptr i8,ptr %out,i64 712
 store i64 %v89,ptr %p89,align 1
 %s90 = zext i7 0 to i64
 %w90 = xor i64 %s90,0
 %m90 = xor i64 %w90,%salt
 %v90 = add i64 %m90,%seed
 %p90 = getelementptr i8,ptr %out,i64 720
 store i64 %v90,ptr %p90,align 1
 %s91 = zext i7 1 to i64
 %w91 = xor i64 %s91,0
 %m91 = xor i64 %w91,%salt
 %v91 = add i64 %m91,%seed
 %p91 = getelementptr i8,ptr %out,i64 728
 store i64 %v91,ptr %p91,align 1
 %s92 = zext i7 -1 to i64
 %w92 = xor i64 %s92,0
 %m92 = xor i64 %w92,%salt
 %v92 = add i64 %m92,%seed
 %p92 = getelementptr i8,ptr %out,i64 736
 store i64 %v92,ptr %p92,align 1
 %s93 = zext i7 -64 to i64
 %w93 = xor i64 %s93,0
 %m93 = xor i64 %w93,%salt
 %v93 = add i64 %m93,%seed
 %p93 = getelementptr i8,ptr %out,i64 744
 store i64 %v93,ptr %p93,align 1
 %s94 = zext i7 63 to i64
 %w94 = xor i64 %s94,0
 %m94 = xor i64 %w94,%salt
 %v94 = add i64 %m94,%seed
 %p94 = getelementptr i8,ptr %out,i64 752
 store i64 %v94,ptr %p94,align 1
 %s95 = zext i7 127 to i64
 %w95 = xor i64 %s95,0
 %m95 = xor i64 %w95,%salt
 %v95 = add i64 %m95,%seed
 %p95 = getelementptr i8,ptr %out,i64 760
 store i64 %v95,ptr %p95,align 1
 %s96 = zext i9 0 to i16
 %w96 = zext i16 %s96 to i64
 %m96 = xor i64 %w96,%salt
 %v96 = add i64 %m96,%seed
 %p96 = getelementptr i8,ptr %out,i64 768
 store i64 %v96,ptr %p96,align 1
 %s97 = zext i9 1 to i16
 %w97 = zext i16 %s97 to i64
 %m97 = xor i64 %w97,%salt
 %v97 = add i64 %m97,%seed
 %p97 = getelementptr i8,ptr %out,i64 776
 store i64 %v97,ptr %p97,align 1
 %s98 = zext i9 -1 to i16
 %w98 = zext i16 %s98 to i64
 %m98 = xor i64 %w98,%salt
 %v98 = add i64 %m98,%seed
 %p98 = getelementptr i8,ptr %out,i64 784
 store i64 %v98,ptr %p98,align 1
 %s99 = zext i9 -256 to i16
 %w99 = zext i16 %s99 to i64
 %m99 = xor i64 %w99,%salt
 %v99 = add i64 %m99,%seed
 %p99 = getelementptr i8,ptr %out,i64 792
 store i64 %v99,ptr %p99,align 1
 %s100 = zext i9 255 to i16
 %w100 = zext i16 %s100 to i64
 %m100 = xor i64 %w100,%salt
 %v100 = add i64 %m100,%seed
 %p100 = getelementptr i8,ptr %out,i64 800
 store i64 %v100,ptr %p100,align 1
 %s101 = zext i9 511 to i16
 %w101 = zext i16 %s101 to i64
 %m101 = xor i64 %w101,%salt
 %v101 = add i64 %m101,%seed
 %p101 = getelementptr i8,ptr %out,i64 808
 store i64 %v101,ptr %p101,align 1
 %s102 = zext i9 0 to i32
 %w102 = zext i32 %s102 to i64
 %m102 = xor i64 %w102,%salt
 %v102 = add i64 %m102,%seed
 %p102 = getelementptr i8,ptr %out,i64 816
 store i64 %v102,ptr %p102,align 1
 %s103 = zext i9 1 to i32
 %w103 = zext i32 %s103 to i64
 %m103 = xor i64 %w103,%salt
 %v103 = add i64 %m103,%seed
 %p103 = getelementptr i8,ptr %out,i64 824
 store i64 %v103,ptr %p103,align 1
 %s104 = zext i9 -1 to i32
 %w104 = zext i32 %s104 to i64
 %m104 = xor i64 %w104,%salt
 %v104 = add i64 %m104,%seed
 %p104 = getelementptr i8,ptr %out,i64 832
 store i64 %v104,ptr %p104,align 1
 %s105 = zext i9 -256 to i32
 %w105 = zext i32 %s105 to i64
 %m105 = xor i64 %w105,%salt
 %v105 = add i64 %m105,%seed
 %p105 = getelementptr i8,ptr %out,i64 840
 store i64 %v105,ptr %p105,align 1
 %s106 = zext i9 255 to i32
 %w106 = zext i32 %s106 to i64
 %m106 = xor i64 %w106,%salt
 %v106 = add i64 %m106,%seed
 %p106 = getelementptr i8,ptr %out,i64 848
 store i64 %v106,ptr %p106,align 1
 %s107 = zext i9 511 to i32
 %w107 = zext i32 %s107 to i64
 %m107 = xor i64 %w107,%salt
 %v107 = add i64 %m107,%seed
 %p107 = getelementptr i8,ptr %out,i64 856
 store i64 %v107,ptr %p107,align 1
 %s108 = zext i9 0 to i64
 %w108 = xor i64 %s108,0
 %m108 = xor i64 %w108,%salt
 %v108 = add i64 %m108,%seed
 %p108 = getelementptr i8,ptr %out,i64 864
 store i64 %v108,ptr %p108,align 1
 %s109 = zext i9 1 to i64
 %w109 = xor i64 %s109,0
 %m109 = xor i64 %w109,%salt
 %v109 = add i64 %m109,%seed
 %p109 = getelementptr i8,ptr %out,i64 872
 store i64 %v109,ptr %p109,align 1
 %s110 = zext i9 -1 to i64
 %w110 = xor i64 %s110,0
 %m110 = xor i64 %w110,%salt
 %v110 = add i64 %m110,%seed
 %p110 = getelementptr i8,ptr %out,i64 880
 store i64 %v110,ptr %p110,align 1
 %s111 = zext i9 -256 to i64
 %w111 = xor i64 %s111,0
 %m111 = xor i64 %w111,%salt
 %v111 = add i64 %m111,%seed
 %p111 = getelementptr i8,ptr %out,i64 888
 store i64 %v111,ptr %p111,align 1
 %s112 = zext i9 255 to i64
 %w112 = xor i64 %s112,0
 %m112 = xor i64 %w112,%salt
 %v112 = add i64 %m112,%seed
 %p112 = getelementptr i8,ptr %out,i64 896
 store i64 %v112,ptr %p112,align 1
 %s113 = zext i9 511 to i64
 %w113 = xor i64 %s113,0
 %m113 = xor i64 %w113,%salt
 %v113 = add i64 %m113,%seed
 %p113 = getelementptr i8,ptr %out,i64 904
 store i64 %v113,ptr %p113,align 1
 %s114 = zext i15 0 to i16
 %w114 = zext i16 %s114 to i64
 %m114 = xor i64 %w114,%salt
 %v114 = add i64 %m114,%seed
 %p114 = getelementptr i8,ptr %out,i64 912
 store i64 %v114,ptr %p114,align 1
 %s115 = zext i15 1 to i16
 %w115 = zext i16 %s115 to i64
 %m115 = xor i64 %w115,%salt
 %v115 = add i64 %m115,%seed
 %p115 = getelementptr i8,ptr %out,i64 920
 store i64 %v115,ptr %p115,align 1
 %s116 = zext i15 -1 to i16
 %w116 = zext i16 %s116 to i64
 %m116 = xor i64 %w116,%salt
 %v116 = add i64 %m116,%seed
 %p116 = getelementptr i8,ptr %out,i64 928
 store i64 %v116,ptr %p116,align 1
 %s117 = zext i15 -16384 to i16
 %w117 = zext i16 %s117 to i64
 %m117 = xor i64 %w117,%salt
 %v117 = add i64 %m117,%seed
 %p117 = getelementptr i8,ptr %out,i64 936
 store i64 %v117,ptr %p117,align 1
 %s118 = zext i15 16383 to i16
 %w118 = zext i16 %s118 to i64
 %m118 = xor i64 %w118,%salt
 %v118 = add i64 %m118,%seed
 %p118 = getelementptr i8,ptr %out,i64 944
 store i64 %v118,ptr %p118,align 1
 %s119 = zext i15 32767 to i16
 %w119 = zext i16 %s119 to i64
 %m119 = xor i64 %w119,%salt
 %v119 = add i64 %m119,%seed
 %p119 = getelementptr i8,ptr %out,i64 952
 store i64 %v119,ptr %p119,align 1
 %s120 = zext i15 0 to i32
 %w120 = zext i32 %s120 to i64
 %m120 = xor i64 %w120,%salt
 %v120 = add i64 %m120,%seed
 %p120 = getelementptr i8,ptr %out,i64 960
 store i64 %v120,ptr %p120,align 1
 %s121 = zext i15 1 to i32
 %w121 = zext i32 %s121 to i64
 %m121 = xor i64 %w121,%salt
 %v121 = add i64 %m121,%seed
 %p121 = getelementptr i8,ptr %out,i64 968
 store i64 %v121,ptr %p121,align 1
 %s122 = zext i15 -1 to i32
 %w122 = zext i32 %s122 to i64
 %m122 = xor i64 %w122,%salt
 %v122 = add i64 %m122,%seed
 %p122 = getelementptr i8,ptr %out,i64 976
 store i64 %v122,ptr %p122,align 1
 %s123 = zext i15 -16384 to i32
 %w123 = zext i32 %s123 to i64
 %m123 = xor i64 %w123,%salt
 %v123 = add i64 %m123,%seed
 %p123 = getelementptr i8,ptr %out,i64 984
 store i64 %v123,ptr %p123,align 1
 %s124 = zext i15 16383 to i32
 %w124 = zext i32 %s124 to i64
 %m124 = xor i64 %w124,%salt
 %v124 = add i64 %m124,%seed
 %p124 = getelementptr i8,ptr %out,i64 992
 store i64 %v124,ptr %p124,align 1
 %s125 = zext i15 32767 to i32
 %w125 = zext i32 %s125 to i64
 %m125 = xor i64 %w125,%salt
 %v125 = add i64 %m125,%seed
 %p125 = getelementptr i8,ptr %out,i64 1000
 store i64 %v125,ptr %p125,align 1
 %s126 = zext i15 0 to i64
 %w126 = xor i64 %s126,0
 %m126 = xor i64 %w126,%salt
 %v126 = add i64 %m126,%seed
 %p126 = getelementptr i8,ptr %out,i64 1008
 store i64 %v126,ptr %p126,align 1
 %s127 = zext i15 1 to i64
 %w127 = xor i64 %s127,0
 %m127 = xor i64 %w127,%salt
 %v127 = add i64 %m127,%seed
 %p127 = getelementptr i8,ptr %out,i64 1016
 store i64 %v127,ptr %p127,align 1
 %s128 = zext i15 -1 to i64
 %w128 = xor i64 %s128,0
 %m128 = xor i64 %w128,%salt
 %v128 = add i64 %m128,%seed
 %p128 = getelementptr i8,ptr %out,i64 1024
 store i64 %v128,ptr %p128,align 1
 %s129 = zext i15 -16384 to i64
 %w129 = xor i64 %s129,0
 %m129 = xor i64 %w129,%salt
 %v129 = add i64 %m129,%seed
 %p129 = getelementptr i8,ptr %out,i64 1032
 store i64 %v129,ptr %p129,align 1
 %s130 = zext i15 16383 to i64
 %w130 = xor i64 %s130,0
 %m130 = xor i64 %w130,%salt
 %v130 = add i64 %m130,%seed
 %p130 = getelementptr i8,ptr %out,i64 1040
 store i64 %v130,ptr %p130,align 1
 %s131 = zext i15 32767 to i64
 %w131 = xor i64 %s131,0
 %m131 = xor i64 %w131,%salt
 %v131 = add i64 %m131,%seed
 %p131 = getelementptr i8,ptr %out,i64 1048
 store i64 %v131,ptr %p131,align 1
 %s132 = zext i17 0 to i32
 %w132 = zext i32 %s132 to i64
 %m132 = xor i64 %w132,%salt
 %v132 = add i64 %m132,%seed
 %p132 = getelementptr i8,ptr %out,i64 1056
 store i64 %v132,ptr %p132,align 1
 %s133 = zext i17 1 to i32
 %w133 = zext i32 %s133 to i64
 %m133 = xor i64 %w133,%salt
 %v133 = add i64 %m133,%seed
 %p133 = getelementptr i8,ptr %out,i64 1064
 store i64 %v133,ptr %p133,align 1
 %s134 = zext i17 -1 to i32
 %w134 = zext i32 %s134 to i64
 %m134 = xor i64 %w134,%salt
 %v134 = add i64 %m134,%seed
 %p134 = getelementptr i8,ptr %out,i64 1072
 store i64 %v134,ptr %p134,align 1
 %s135 = zext i17 -65536 to i32
 %w135 = zext i32 %s135 to i64
 %m135 = xor i64 %w135,%salt
 %v135 = add i64 %m135,%seed
 %p135 = getelementptr i8,ptr %out,i64 1080
 store i64 %v135,ptr %p135,align 1
 %s136 = zext i17 65535 to i32
 %w136 = zext i32 %s136 to i64
 %m136 = xor i64 %w136,%salt
 %v136 = add i64 %m136,%seed
 %p136 = getelementptr i8,ptr %out,i64 1088
 store i64 %v136,ptr %p136,align 1
 %s137 = zext i17 131071 to i32
 %w137 = zext i32 %s137 to i64
 %m137 = xor i64 %w137,%salt
 %v137 = add i64 %m137,%seed
 %p137 = getelementptr i8,ptr %out,i64 1096
 store i64 %v137,ptr %p137,align 1
 %s138 = zext i17 0 to i64
 %w138 = xor i64 %s138,0
 %m138 = xor i64 %w138,%salt
 %v138 = add i64 %m138,%seed
 %p138 = getelementptr i8,ptr %out,i64 1104
 store i64 %v138,ptr %p138,align 1
 %s139 = zext i17 1 to i64
 %w139 = xor i64 %s139,0
 %m139 = xor i64 %w139,%salt
 %v139 = add i64 %m139,%seed
 %p139 = getelementptr i8,ptr %out,i64 1112
 store i64 %v139,ptr %p139,align 1
 %s140 = zext i17 -1 to i64
 %w140 = xor i64 %s140,0
 %m140 = xor i64 %w140,%salt
 %v140 = add i64 %m140,%seed
 %p140 = getelementptr i8,ptr %out,i64 1120
 store i64 %v140,ptr %p140,align 1
 %s141 = zext i17 -65536 to i64
 %w141 = xor i64 %s141,0
 %m141 = xor i64 %w141,%salt
 %v141 = add i64 %m141,%seed
 %p141 = getelementptr i8,ptr %out,i64 1128
 store i64 %v141,ptr %p141,align 1
 %s142 = zext i17 65535 to i64
 %w142 = xor i64 %s142,0
 %m142 = xor i64 %w142,%salt
 %v142 = add i64 %m142,%seed
 %p142 = getelementptr i8,ptr %out,i64 1136
 store i64 %v142,ptr %p142,align 1
 %s143 = zext i17 131071 to i64
 %w143 = xor i64 %s143,0
 %m143 = xor i64 %w143,%salt
 %v143 = add i64 %m143,%seed
 %p143 = getelementptr i8,ptr %out,i64 1144
 store i64 %v143,ptr %p143,align 1
 %s144 = zext i31 0 to i32
 %w144 = zext i32 %s144 to i64
 %m144 = xor i64 %w144,%salt
 %v144 = add i64 %m144,%seed
 %p144 = getelementptr i8,ptr %out,i64 1152
 store i64 %v144,ptr %p144,align 1
 %s145 = zext i31 1 to i32
 %w145 = zext i32 %s145 to i64
 %m145 = xor i64 %w145,%salt
 %v145 = add i64 %m145,%seed
 %p145 = getelementptr i8,ptr %out,i64 1160
 store i64 %v145,ptr %p145,align 1
 %s146 = zext i31 -1 to i32
 %w146 = zext i32 %s146 to i64
 %m146 = xor i64 %w146,%salt
 %v146 = add i64 %m146,%seed
 %p146 = getelementptr i8,ptr %out,i64 1168
 store i64 %v146,ptr %p146,align 1
 %s147 = zext i31 -1073741824 to i32
 %w147 = zext i32 %s147 to i64
 %m147 = xor i64 %w147,%salt
 %v147 = add i64 %m147,%seed
 %p147 = getelementptr i8,ptr %out,i64 1176
 store i64 %v147,ptr %p147,align 1
 %s148 = zext i31 1073741823 to i32
 %w148 = zext i32 %s148 to i64
 %m148 = xor i64 %w148,%salt
 %v148 = add i64 %m148,%seed
 %p148 = getelementptr i8,ptr %out,i64 1184
 store i64 %v148,ptr %p148,align 1
 %s149 = zext i31 2147483647 to i32
 %w149 = zext i32 %s149 to i64
 %m149 = xor i64 %w149,%salt
 %v149 = add i64 %m149,%seed
 %p149 = getelementptr i8,ptr %out,i64 1192
 store i64 %v149,ptr %p149,align 1
 %s150 = zext i31 0 to i64
 %w150 = xor i64 %s150,0
 %m150 = xor i64 %w150,%salt
 %v150 = add i64 %m150,%seed
 %p150 = getelementptr i8,ptr %out,i64 1200
 store i64 %v150,ptr %p150,align 1
 %s151 = zext i31 1 to i64
 %w151 = xor i64 %s151,0
 %m151 = xor i64 %w151,%salt
 %v151 = add i64 %m151,%seed
 %p151 = getelementptr i8,ptr %out,i64 1208
 store i64 %v151,ptr %p151,align 1
 %s152 = zext i31 -1 to i64
 %w152 = xor i64 %s152,0
 %m152 = xor i64 %w152,%salt
 %v152 = add i64 %m152,%seed
 %p152 = getelementptr i8,ptr %out,i64 1216
 store i64 %v152,ptr %p152,align 1
 %s153 = zext i31 -1073741824 to i64
 %w153 = xor i64 %s153,0
 %m153 = xor i64 %w153,%salt
 %v153 = add i64 %m153,%seed
 %p153 = getelementptr i8,ptr %out,i64 1224
 store i64 %v153,ptr %p153,align 1
 %s154 = zext i31 1073741823 to i64
 %w154 = xor i64 %s154,0
 %m154 = xor i64 %w154,%salt
 %v154 = add i64 %m154,%seed
 %p154 = getelementptr i8,ptr %out,i64 1232
 store i64 %v154,ptr %p154,align 1
 %s155 = zext i31 2147483647 to i64
 %w155 = xor i64 %s155,0
 %m155 = xor i64 %w155,%salt
 %v155 = add i64 %m155,%seed
 %p155 = getelementptr i8,ptr %out,i64 1240
 store i64 %v155,ptr %p155,align 1
 %s156 = zext i33 0 to i64
 %w156 = xor i64 %s156,0
 %m156 = xor i64 %w156,%salt
 %v156 = add i64 %m156,%seed
 %p156 = getelementptr i8,ptr %out,i64 1248
 store i64 %v156,ptr %p156,align 1
 %s157 = zext i33 1 to i64
 %w157 = xor i64 %s157,0
 %m157 = xor i64 %w157,%salt
 %v157 = add i64 %m157,%seed
 %p157 = getelementptr i8,ptr %out,i64 1256
 store i64 %v157,ptr %p157,align 1
 %s158 = zext i33 -1 to i64
 %w158 = xor i64 %s158,0
 %m158 = xor i64 %w158,%salt
 %v158 = add i64 %m158,%seed
 %p158 = getelementptr i8,ptr %out,i64 1264
 store i64 %v158,ptr %p158,align 1
 %s159 = zext i33 -4294967296 to i64
 %w159 = xor i64 %s159,0
 %m159 = xor i64 %w159,%salt
 %v159 = add i64 %m159,%seed
 %p159 = getelementptr i8,ptr %out,i64 1272
 store i64 %v159,ptr %p159,align 1
 %s160 = zext i33 4294967295 to i64
 %w160 = xor i64 %s160,0
 %m160 = xor i64 %w160,%salt
 %v160 = add i64 %m160,%seed
 %p160 = getelementptr i8,ptr %out,i64 1280
 store i64 %v160,ptr %p160,align 1
 %s161 = zext i33 8589934591 to i64
 %w161 = xor i64 %s161,0
 %m161 = xor i64 %w161,%salt
 %v161 = add i64 %m161,%seed
 %p161 = getelementptr i8,ptr %out,i64 1288
 store i64 %v161,ptr %p161,align 1
 %s162 = zext i47 0 to i64
 %w162 = xor i64 %s162,0
 %m162 = xor i64 %w162,%salt
 %v162 = add i64 %m162,%seed
 %p162 = getelementptr i8,ptr %out,i64 1296
 store i64 %v162,ptr %p162,align 1
 %s163 = zext i47 1 to i64
 %w163 = xor i64 %s163,0
 %m163 = xor i64 %w163,%salt
 %v163 = add i64 %m163,%seed
 %p163 = getelementptr i8,ptr %out,i64 1304
 store i64 %v163,ptr %p163,align 1
 %s164 = zext i47 -1 to i64
 %w164 = xor i64 %s164,0
 %m164 = xor i64 %w164,%salt
 %v164 = add i64 %m164,%seed
 %p164 = getelementptr i8,ptr %out,i64 1312
 store i64 %v164,ptr %p164,align 1
 %s165 = zext i47 -70368744177664 to i64
 %w165 = xor i64 %s165,0
 %m165 = xor i64 %w165,%salt
 %v165 = add i64 %m165,%seed
 %p165 = getelementptr i8,ptr %out,i64 1320
 store i64 %v165,ptr %p165,align 1
 %s166 = zext i47 70368744177663 to i64
 %w166 = xor i64 %s166,0
 %m166 = xor i64 %w166,%salt
 %v166 = add i64 %m166,%seed
 %p166 = getelementptr i8,ptr %out,i64 1328
 store i64 %v166,ptr %p166,align 1
 %s167 = zext i47 140737488355327 to i64
 %w167 = xor i64 %s167,0
 %m167 = xor i64 %w167,%salt
 %v167 = add i64 %m167,%seed
 %p167 = getelementptr i8,ptr %out,i64 1336
 store i64 %v167,ptr %p167,align 1
 %s168 = zext i52 0 to i64
 %w168 = xor i64 %s168,0
 %m168 = xor i64 %w168,%salt
 %v168 = add i64 %m168,%seed
 %p168 = getelementptr i8,ptr %out,i64 1344
 store i64 %v168,ptr %p168,align 1
 %s169 = zext i52 1 to i64
 %w169 = xor i64 %s169,0
 %m169 = xor i64 %w169,%salt
 %v169 = add i64 %m169,%seed
 %p169 = getelementptr i8,ptr %out,i64 1352
 store i64 %v169,ptr %p169,align 1
 %s170 = zext i52 -1 to i64
 %w170 = xor i64 %s170,0
 %m170 = xor i64 %w170,%salt
 %v170 = add i64 %m170,%seed
 %p170 = getelementptr i8,ptr %out,i64 1360
 store i64 %v170,ptr %p170,align 1
 %s171 = zext i52 -2251799813685248 to i64
 %w171 = xor i64 %s171,0
 %m171 = xor i64 %w171,%salt
 %v171 = add i64 %m171,%seed
 %p171 = getelementptr i8,ptr %out,i64 1368
 store i64 %v171,ptr %p171,align 1
 %s172 = zext i52 2251799813685247 to i64
 %w172 = xor i64 %s172,0
 %m172 = xor i64 %w172,%salt
 %v172 = add i64 %m172,%seed
 %p172 = getelementptr i8,ptr %out,i64 1376
 store i64 %v172,ptr %p172,align 1
 %s173 = zext i52 4503599627370495 to i64
 %w173 = xor i64 %s173,0
 %m173 = xor i64 %w173,%salt
 %v173 = add i64 %m173,%seed
 %p173 = getelementptr i8,ptr %out,i64 1384
 store i64 %v173,ptr %p173,align 1
 %s174 = zext i62 0 to i64
 %w174 = xor i64 %s174,0
 %m174 = xor i64 %w174,%salt
 %v174 = add i64 %m174,%seed
 %p174 = getelementptr i8,ptr %out,i64 1392
 store i64 %v174,ptr %p174,align 1
 %s175 = zext i62 1 to i64
 %w175 = xor i64 %s175,0
 %m175 = xor i64 %w175,%salt
 %v175 = add i64 %m175,%seed
 %p175 = getelementptr i8,ptr %out,i64 1400
 store i64 %v175,ptr %p175,align 1
 %s176 = zext i62 -1 to i64
 %w176 = xor i64 %s176,0
 %m176 = xor i64 %w176,%salt
 %v176 = add i64 %m176,%seed
 %p176 = getelementptr i8,ptr %out,i64 1408
 store i64 %v176,ptr %p176,align 1
 %s177 = zext i62 -2305843009213693952 to i64
 %w177 = xor i64 %s177,0
 %m177 = xor i64 %w177,%salt
 %v177 = add i64 %m177,%seed
 %p177 = getelementptr i8,ptr %out,i64 1416
 store i64 %v177,ptr %p177,align 1
 %s178 = zext i62 2305843009213693951 to i64
 %w178 = xor i64 %s178,0
 %m178 = xor i64 %w178,%salt
 %v178 = add i64 %m178,%seed
 %p178 = getelementptr i8,ptr %out,i64 1424
 store i64 %v178,ptr %p178,align 1
 %s179 = zext i62 4611686018427387903 to i64
 %w179 = xor i64 %s179,0
 %m179 = xor i64 %w179,%salt
 %v179 = add i64 %m179,%seed
 %p179 = getelementptr i8,ptr %out,i64 1432
 store i64 %v179,ptr %p179,align 1
 %s180 = zext i63 0 to i64
 %w180 = xor i64 %s180,0
 %m180 = xor i64 %w180,%salt
 %v180 = add i64 %m180,%seed
 %p180 = getelementptr i8,ptr %out,i64 1440
 store i64 %v180,ptr %p180,align 1
 %s181 = zext i63 1 to i64
 %w181 = xor i64 %s181,0
 %m181 = xor i64 %w181,%salt
 %v181 = add i64 %m181,%seed
 %p181 = getelementptr i8,ptr %out,i64 1448
 store i64 %v181,ptr %p181,align 1
 %s182 = zext i63 -1 to i64
 %w182 = xor i64 %s182,0
 %m182 = xor i64 %w182,%salt
 %v182 = add i64 %m182,%seed
 %p182 = getelementptr i8,ptr %out,i64 1456
 store i64 %v182,ptr %p182,align 1
 %s183 = zext i63 -4611686018427387904 to i64
 %w183 = xor i64 %s183,0
 %m183 = xor i64 %w183,%salt
 %v183 = add i64 %m183,%seed
 %p183 = getelementptr i8,ptr %out,i64 1464
 store i64 %v183,ptr %p183,align 1
 %s184 = zext i63 4611686018427387903 to i64
 %w184 = xor i64 %s184,0
 %m184 = xor i64 %w184,%salt
 %v184 = add i64 %m184,%seed
 %p184 = getelementptr i8,ptr %out,i64 1472
 store i64 %v184,ptr %p184,align 1
 %s185 = zext i63 9223372036854775807 to i64
 %w185 = xor i64 %s185,0
 %m185 = xor i64 %w185,%salt
 %v185 = add i64 %m185,%seed
 %p185 = getelementptr i8,ptr %out,i64 1480
 store i64 %v185,ptr %p185,align 1
 %r = xor i64 %seed,%salt
 ret i64 %r
}
