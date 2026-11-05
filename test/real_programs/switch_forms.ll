target triple = "x86_64-unknown-linux-gnu"

define i64 @switch_8_0(i64 %input, i64 %salt, ptr %out) {
entry:
  %narrow = trunc i64 %input to i8
  switch i8 %narrow, label %fallback [
  ]
fallback:
  %default = add i64 %salt, 999
  br label %merge
merge:
  %result = phi i64 [ %default, %fallback ]
  store i64 %result, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %result
}


define i64 @switch_8_9(i64 %input, i64 %salt, ptr %out) {
entry:
  %narrow = trunc i64 %input to i8
  switch i8 %narrow, label %fallback [
    i8 128, label %case0
    i8 129, label %case1
    i8 130, label %case2
    i8 131, label %case3
    i8 132, label %case4
    i8 133, label %case5
    i8 134, label %case6
    i8 135, label %case7
    i8 136, label %case8
  ]
fallback:
  %default = add i64 %salt, 999
  br label %merge
case0:
  %value0 = add i64 %salt, 0
  br label %merge
case1:
  %value1 = add i64 %salt, 1
  br label %merge
case2:
  %value2 = add i64 %salt, 2
  br label %merge
case3:
  %value3 = add i64 %salt, 3
  br label %merge
case4:
  %value4 = add i64 %salt, 4
  br label %merge
case5:
  %value5 = add i64 %salt, 5
  br label %merge
case6:
  %value6 = add i64 %salt, 6
  br label %merge
case7:
  %value7 = add i64 %salt, 7
  br label %merge
case8:
  %value8 = add i64 %salt, 8
  br label %merge
merge:
  %result = phi i64 [ %default, %fallback ], [ %value0, %case0 ], [ %value1, %case1 ], [ %value2, %case2 ], [ %value3, %case3 ], [ %value4, %case4 ], [ %value5, %case5 ], [ %value6, %case6 ], [ %value7, %case7 ], [ %value8, %case8 ]
  store i64 %result, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %result
}


define i64 @switch_8_61(i64 %input, i64 %salt, ptr %out) {
entry:
  %narrow = trunc i64 %input to i8
  switch i8 %narrow, label %fallback [
    i8 128, label %case0
    i8 129, label %case1
    i8 130, label %case2
    i8 131, label %case3
    i8 132, label %case4
    i8 133, label %case5
    i8 134, label %case6
    i8 135, label %case7
    i8 136, label %case8
    i8 137, label %case9
    i8 138, label %case10
    i8 139, label %case11
    i8 140, label %case12
    i8 141, label %case13
    i8 142, label %case14
    i8 143, label %case15
    i8 144, label %case16
    i8 145, label %case17
    i8 146, label %case18
    i8 147, label %case19
    i8 148, label %case20
    i8 149, label %case21
    i8 150, label %case22
    i8 151, label %case23
    i8 152, label %case24
    i8 153, label %case25
    i8 154, label %case26
    i8 155, label %case27
    i8 156, label %case28
    i8 157, label %case29
    i8 158, label %case30
    i8 159, label %case31
    i8 160, label %case32
    i8 161, label %case33
    i8 162, label %case34
    i8 163, label %case35
    i8 164, label %case36
    i8 165, label %case37
    i8 166, label %case38
    i8 167, label %case39
    i8 168, label %case40
    i8 169, label %case41
    i8 170, label %case42
    i8 171, label %case43
    i8 172, label %case44
    i8 173, label %case45
    i8 174, label %case46
    i8 175, label %case47
    i8 176, label %case48
    i8 177, label %case49
    i8 178, label %case50
    i8 179, label %case51
    i8 180, label %case52
    i8 181, label %case53
    i8 182, label %case54
    i8 183, label %case55
    i8 184, label %case56
    i8 185, label %case57
    i8 186, label %case58
    i8 187, label %case59
    i8 188, label %case60
  ]
fallback:
  %default = add i64 %salt, 999
  br label %merge
case0:
  %value0 = add i64 %salt, 0
  br label %merge
case1:
  %value1 = add i64 %salt, 1
  br label %merge
case2:
  %value2 = add i64 %salt, 2
  br label %merge
case3:
  %value3 = add i64 %salt, 3
  br label %merge
case4:
  %value4 = add i64 %salt, 4
  br label %merge
case5:
  %value5 = add i64 %salt, 5
  br label %merge
case6:
  %value6 = add i64 %salt, 6
  br label %merge
case7:
  %value7 = add i64 %salt, 7
  br label %merge
case8:
  %value8 = add i64 %salt, 8
  br label %merge
case9:
  %value9 = add i64 %salt, 9
  br label %merge
case10:
  %value10 = add i64 %salt, 10
  br label %merge
case11:
  %value11 = add i64 %salt, 11
  br label %merge
case12:
  %value12 = add i64 %salt, 12
  br label %merge
case13:
  %value13 = add i64 %salt, 13
  br label %merge
case14:
  %value14 = add i64 %salt, 14
  br label %merge
case15:
  %value15 = add i64 %salt, 15
  br label %merge
case16:
  %value16 = add i64 %salt, 16
  br label %merge
case17:
  %value17 = add i64 %salt, 17
  br label %merge
case18:
  %value18 = add i64 %salt, 18
  br label %merge
case19:
  %value19 = add i64 %salt, 19
  br label %merge
case20:
  %value20 = add i64 %salt, 20
  br label %merge
case21:
  %value21 = add i64 %salt, 21
  br label %merge
case22:
  %value22 = add i64 %salt, 22
  br label %merge
case23:
  %value23 = add i64 %salt, 23
  br label %merge
case24:
  %value24 = add i64 %salt, 24
  br label %merge
case25:
  %value25 = add i64 %salt, 25
  br label %merge
case26:
  %value26 = add i64 %salt, 26
  br label %merge
case27:
  %value27 = add i64 %salt, 27
  br label %merge
case28:
  %value28 = add i64 %salt, 28
  br label %merge
case29:
  %value29 = add i64 %salt, 29
  br label %merge
case30:
  %value30 = add i64 %salt, 30
  br label %merge
case31:
  %value31 = add i64 %salt, 31
  br label %merge
case32:
  %value32 = add i64 %salt, 32
  br label %merge
case33:
  %value33 = add i64 %salt, 33
  br label %merge
case34:
  %value34 = add i64 %salt, 34
  br label %merge
case35:
  %value35 = add i64 %salt, 35
  br label %merge
case36:
  %value36 = add i64 %salt, 36
  br label %merge
case37:
  %value37 = add i64 %salt, 37
  br label %merge
case38:
  %value38 = add i64 %salt, 38
  br label %merge
case39:
  %value39 = add i64 %salt, 39
  br label %merge
case40:
  %value40 = add i64 %salt, 40
  br label %merge
case41:
  %value41 = add i64 %salt, 41
  br label %merge
case42:
  %value42 = add i64 %salt, 42
  br label %merge
case43:
  %value43 = add i64 %salt, 43
  br label %merge
case44:
  %value44 = add i64 %salt, 44
  br label %merge
case45:
  %value45 = add i64 %salt, 45
  br label %merge
case46:
  %value46 = add i64 %salt, 46
  br label %merge
case47:
  %value47 = add i64 %salt, 47
  br label %merge
case48:
  %value48 = add i64 %salt, 48
  br label %merge
case49:
  %value49 = add i64 %salt, 49
  br label %merge
case50:
  %value50 = add i64 %salt, 50
  br label %merge
case51:
  %value51 = add i64 %salt, 51
  br label %merge
case52:
  %value52 = add i64 %salt, 52
  br label %merge
case53:
  %value53 = add i64 %salt, 53
  br label %merge
case54:
  %value54 = add i64 %salt, 54
  br label %merge
case55:
  %value55 = add i64 %salt, 55
  br label %merge
case56:
  %value56 = add i64 %salt, 56
  br label %merge
case57:
  %value57 = add i64 %salt, 57
  br label %merge
case58:
  %value58 = add i64 %salt, 58
  br label %merge
case59:
  %value59 = add i64 %salt, 59
  br label %merge
case60:
  %value60 = add i64 %salt, 60
  br label %merge
merge:
  %result = phi i64 [ %default, %fallback ], [ %value0, %case0 ], [ %value1, %case1 ], [ %value2, %case2 ], [ %value3, %case3 ], [ %value4, %case4 ], [ %value5, %case5 ], [ %value6, %case6 ], [ %value7, %case7 ], [ %value8, %case8 ], [ %value9, %case9 ], [ %value10, %case10 ], [ %value11, %case11 ], [ %value12, %case12 ], [ %value13, %case13 ], [ %value14, %case14 ], [ %value15, %case15 ], [ %value16, %case16 ], [ %value17, %case17 ], [ %value18, %case18 ], [ %value19, %case19 ], [ %value20, %case20 ], [ %value21, %case21 ], [ %value22, %case22 ], [ %value23, %case23 ], [ %value24, %case24 ], [ %value25, %case25 ], [ %value26, %case26 ], [ %value27, %case27 ], [ %value28, %case28 ], [ %value29, %case29 ], [ %value30, %case30 ], [ %value31, %case31 ], [ %value32, %case32 ], [ %value33, %case33 ], [ %value34, %case34 ], [ %value35, %case35 ], [ %value36, %case36 ], [ %value37, %case37 ], [ %value38, %case38 ], [ %value39, %case39 ], [ %value40, %case40 ], [ %value41, %case41 ], [ %value42, %case42 ], [ %value43, %case43 ], [ %value44, %case44 ], [ %value45, %case45 ], [ %value46, %case46 ], [ %value47, %case47 ], [ %value48, %case48 ], [ %value49, %case49 ], [ %value50, %case50 ], [ %value51, %case51 ], [ %value52, %case52 ], [ %value53, %case53 ], [ %value54, %case54 ], [ %value55, %case55 ], [ %value56, %case56 ], [ %value57, %case57 ], [ %value58, %case58 ], [ %value59, %case59 ], [ %value60, %case60 ]
  store i64 %result, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %result
}


define i64 @switch_8_127(i64 %input, i64 %salt, ptr %out) {
entry:
  %narrow = trunc i64 %input to i8
  switch i8 %narrow, label %fallback [
    i8 128, label %case0
    i8 129, label %case1
    i8 130, label %case2
    i8 131, label %case3
    i8 132, label %case4
    i8 133, label %case5
    i8 134, label %case6
    i8 135, label %case7
    i8 136, label %case8
    i8 137, label %case9
    i8 138, label %case10
    i8 139, label %case11
    i8 140, label %case12
    i8 141, label %case13
    i8 142, label %case14
    i8 143, label %case15
    i8 144, label %case16
    i8 145, label %case17
    i8 146, label %case18
    i8 147, label %case19
    i8 148, label %case20
    i8 149, label %case21
    i8 150, label %case22
    i8 151, label %case23
    i8 152, label %case24
    i8 153, label %case25
    i8 154, label %case26
    i8 155, label %case27
    i8 156, label %case28
    i8 157, label %case29
    i8 158, label %case30
    i8 159, label %case31
    i8 160, label %case32
    i8 161, label %case33
    i8 162, label %case34
    i8 163, label %case35
    i8 164, label %case36
    i8 165, label %case37
    i8 166, label %case38
    i8 167, label %case39
    i8 168, label %case40
    i8 169, label %case41
    i8 170, label %case42
    i8 171, label %case43
    i8 172, label %case44
    i8 173, label %case45
    i8 174, label %case46
    i8 175, label %case47
    i8 176, label %case48
    i8 177, label %case49
    i8 178, label %case50
    i8 179, label %case51
    i8 180, label %case52
    i8 181, label %case53
    i8 182, label %case54
    i8 183, label %case55
    i8 184, label %case56
    i8 185, label %case57
    i8 186, label %case58
    i8 187, label %case59
    i8 188, label %case60
    i8 189, label %case61
    i8 190, label %case62
    i8 191, label %case63
    i8 192, label %case64
    i8 193, label %case65
    i8 194, label %case66
    i8 195, label %case67
    i8 196, label %case68
    i8 197, label %case69
    i8 198, label %case70
    i8 199, label %case71
    i8 200, label %case72
    i8 201, label %case73
    i8 202, label %case74
    i8 203, label %case75
    i8 204, label %case76
    i8 205, label %case77
    i8 206, label %case78
    i8 207, label %case79
    i8 208, label %case80
    i8 209, label %case81
    i8 210, label %case82
    i8 211, label %case83
    i8 212, label %case84
    i8 213, label %case85
    i8 214, label %case86
    i8 215, label %case87
    i8 216, label %case88
    i8 217, label %case89
    i8 218, label %case90
    i8 219, label %case91
    i8 220, label %case92
    i8 221, label %case93
    i8 222, label %case94
    i8 223, label %case95
    i8 224, label %case96
    i8 225, label %case97
    i8 226, label %case98
    i8 227, label %case99
    i8 228, label %case100
    i8 229, label %case101
    i8 230, label %case102
    i8 231, label %case103
    i8 232, label %case104
    i8 233, label %case105
    i8 234, label %case106
    i8 235, label %case107
    i8 236, label %case108
    i8 237, label %case109
    i8 238, label %case110
    i8 239, label %case111
    i8 240, label %case112
    i8 241, label %case113
    i8 242, label %case114
    i8 243, label %case115
    i8 244, label %case116
    i8 245, label %case117
    i8 246, label %case118
    i8 247, label %case119
    i8 248, label %case120
    i8 249, label %case121
    i8 250, label %case122
    i8 251, label %case123
    i8 252, label %case124
    i8 253, label %case125
    i8 254, label %case126
  ]
fallback:
  %default = add i64 %salt, 999
  br label %merge
case0:
  %value0 = add i64 %salt, 0
  br label %merge
case1:
  %value1 = add i64 %salt, 1
  br label %merge
case2:
  %value2 = add i64 %salt, 2
  br label %merge
case3:
  %value3 = add i64 %salt, 3
  br label %merge
case4:
  %value4 = add i64 %salt, 4
  br label %merge
case5:
  %value5 = add i64 %salt, 5
  br label %merge
case6:
  %value6 = add i64 %salt, 6
  br label %merge
case7:
  %value7 = add i64 %salt, 7
  br label %merge
case8:
  %value8 = add i64 %salt, 8
  br label %merge
case9:
  %value9 = add i64 %salt, 9
  br label %merge
case10:
  %value10 = add i64 %salt, 10
  br label %merge
case11:
  %value11 = add i64 %salt, 11
  br label %merge
case12:
  %value12 = add i64 %salt, 12
  br label %merge
case13:
  %value13 = add i64 %salt, 13
  br label %merge
case14:
  %value14 = add i64 %salt, 14
  br label %merge
case15:
  %value15 = add i64 %salt, 15
  br label %merge
case16:
  %value16 = add i64 %salt, 16
  br label %merge
case17:
  %value17 = add i64 %salt, 17
  br label %merge
case18:
  %value18 = add i64 %salt, 18
  br label %merge
case19:
  %value19 = add i64 %salt, 19
  br label %merge
case20:
  %value20 = add i64 %salt, 20
  br label %merge
case21:
  %value21 = add i64 %salt, 21
  br label %merge
case22:
  %value22 = add i64 %salt, 22
  br label %merge
case23:
  %value23 = add i64 %salt, 23
  br label %merge
case24:
  %value24 = add i64 %salt, 24
  br label %merge
case25:
  %value25 = add i64 %salt, 25
  br label %merge
case26:
  %value26 = add i64 %salt, 26
  br label %merge
case27:
  %value27 = add i64 %salt, 27
  br label %merge
case28:
  %value28 = add i64 %salt, 28
  br label %merge
case29:
  %value29 = add i64 %salt, 29
  br label %merge
case30:
  %value30 = add i64 %salt, 30
  br label %merge
case31:
  %value31 = add i64 %salt, 31
  br label %merge
case32:
  %value32 = add i64 %salt, 32
  br label %merge
case33:
  %value33 = add i64 %salt, 33
  br label %merge
case34:
  %value34 = add i64 %salt, 34
  br label %merge
case35:
  %value35 = add i64 %salt, 35
  br label %merge
case36:
  %value36 = add i64 %salt, 36
  br label %merge
case37:
  %value37 = add i64 %salt, 37
  br label %merge
case38:
  %value38 = add i64 %salt, 38
  br label %merge
case39:
  %value39 = add i64 %salt, 39
  br label %merge
case40:
  %value40 = add i64 %salt, 40
  br label %merge
case41:
  %value41 = add i64 %salt, 41
  br label %merge
case42:
  %value42 = add i64 %salt, 42
  br label %merge
case43:
  %value43 = add i64 %salt, 43
  br label %merge
case44:
  %value44 = add i64 %salt, 44
  br label %merge
case45:
  %value45 = add i64 %salt, 45
  br label %merge
case46:
  %value46 = add i64 %salt, 46
  br label %merge
case47:
  %value47 = add i64 %salt, 47
  br label %merge
case48:
  %value48 = add i64 %salt, 48
  br label %merge
case49:
  %value49 = add i64 %salt, 49
  br label %merge
case50:
  %value50 = add i64 %salt, 50
  br label %merge
case51:
  %value51 = add i64 %salt, 51
  br label %merge
case52:
  %value52 = add i64 %salt, 52
  br label %merge
case53:
  %value53 = add i64 %salt, 53
  br label %merge
case54:
  %value54 = add i64 %salt, 54
  br label %merge
case55:
  %value55 = add i64 %salt, 55
  br label %merge
case56:
  %value56 = add i64 %salt, 56
  br label %merge
case57:
  %value57 = add i64 %salt, 57
  br label %merge
case58:
  %value58 = add i64 %salt, 58
  br label %merge
case59:
  %value59 = add i64 %salt, 59
  br label %merge
case60:
  %value60 = add i64 %salt, 60
  br label %merge
case61:
  %value61 = add i64 %salt, 61
  br label %merge
case62:
  %value62 = add i64 %salt, 62
  br label %merge
case63:
  %value63 = add i64 %salt, 63
  br label %merge
case64:
  %value64 = add i64 %salt, 64
  br label %merge
case65:
  %value65 = add i64 %salt, 65
  br label %merge
case66:
  %value66 = add i64 %salt, 66
  br label %merge
case67:
  %value67 = add i64 %salt, 67
  br label %merge
case68:
  %value68 = add i64 %salt, 68
  br label %merge
case69:
  %value69 = add i64 %salt, 69
  br label %merge
case70:
  %value70 = add i64 %salt, 70
  br label %merge
case71:
  %value71 = add i64 %salt, 71
  br label %merge
case72:
  %value72 = add i64 %salt, 72
  br label %merge
case73:
  %value73 = add i64 %salt, 73
  br label %merge
case74:
  %value74 = add i64 %salt, 74
  br label %merge
case75:
  %value75 = add i64 %salt, 75
  br label %merge
case76:
  %value76 = add i64 %salt, 76
  br label %merge
case77:
  %value77 = add i64 %salt, 77
  br label %merge
case78:
  %value78 = add i64 %salt, 78
  br label %merge
case79:
  %value79 = add i64 %salt, 79
  br label %merge
case80:
  %value80 = add i64 %salt, 80
  br label %merge
case81:
  %value81 = add i64 %salt, 81
  br label %merge
case82:
  %value82 = add i64 %salt, 82
  br label %merge
case83:
  %value83 = add i64 %salt, 83
  br label %merge
case84:
  %value84 = add i64 %salt, 84
  br label %merge
case85:
  %value85 = add i64 %salt, 85
  br label %merge
case86:
  %value86 = add i64 %salt, 86
  br label %merge
case87:
  %value87 = add i64 %salt, 87
  br label %merge
case88:
  %value88 = add i64 %salt, 88
  br label %merge
case89:
  %value89 = add i64 %salt, 89
  br label %merge
case90:
  %value90 = add i64 %salt, 90
  br label %merge
case91:
  %value91 = add i64 %salt, 91
  br label %merge
case92:
  %value92 = add i64 %salt, 92
  br label %merge
case93:
  %value93 = add i64 %salt, 93
  br label %merge
case94:
  %value94 = add i64 %salt, 94
  br label %merge
case95:
  %value95 = add i64 %salt, 95
  br label %merge
case96:
  %value96 = add i64 %salt, 96
  br label %merge
case97:
  %value97 = add i64 %salt, 97
  br label %merge
case98:
  %value98 = add i64 %salt, 98
  br label %merge
case99:
  %value99 = add i64 %salt, 99
  br label %merge
case100:
  %value100 = add i64 %salt, 100
  br label %merge
case101:
  %value101 = add i64 %salt, 101
  br label %merge
case102:
  %value102 = add i64 %salt, 102
  br label %merge
case103:
  %value103 = add i64 %salt, 103
  br label %merge
case104:
  %value104 = add i64 %salt, 104
  br label %merge
case105:
  %value105 = add i64 %salt, 105
  br label %merge
case106:
  %value106 = add i64 %salt, 106
  br label %merge
case107:
  %value107 = add i64 %salt, 107
  br label %merge
case108:
  %value108 = add i64 %salt, 108
  br label %merge
case109:
  %value109 = add i64 %salt, 109
  br label %merge
case110:
  %value110 = add i64 %salt, 110
  br label %merge
case111:
  %value111 = add i64 %salt, 111
  br label %merge
case112:
  %value112 = add i64 %salt, 112
  br label %merge
case113:
  %value113 = add i64 %salt, 113
  br label %merge
case114:
  %value114 = add i64 %salt, 114
  br label %merge
case115:
  %value115 = add i64 %salt, 115
  br label %merge
case116:
  %value116 = add i64 %salt, 116
  br label %merge
case117:
  %value117 = add i64 %salt, 117
  br label %merge
case118:
  %value118 = add i64 %salt, 118
  br label %merge
case119:
  %value119 = add i64 %salt, 119
  br label %merge
case120:
  %value120 = add i64 %salt, 120
  br label %merge
case121:
  %value121 = add i64 %salt, 121
  br label %merge
case122:
  %value122 = add i64 %salt, 122
  br label %merge
case123:
  %value123 = add i64 %salt, 123
  br label %merge
case124:
  %value124 = add i64 %salt, 124
  br label %merge
case125:
  %value125 = add i64 %salt, 125
  br label %merge
case126:
  %value126 = add i64 %salt, 126
  br label %merge
merge:
  %result = phi i64 [ %default, %fallback ], [ %value0, %case0 ], [ %value1, %case1 ], [ %value2, %case2 ], [ %value3, %case3 ], [ %value4, %case4 ], [ %value5, %case5 ], [ %value6, %case6 ], [ %value7, %case7 ], [ %value8, %case8 ], [ %value9, %case9 ], [ %value10, %case10 ], [ %value11, %case11 ], [ %value12, %case12 ], [ %value13, %case13 ], [ %value14, %case14 ], [ %value15, %case15 ], [ %value16, %case16 ], [ %value17, %case17 ], [ %value18, %case18 ], [ %value19, %case19 ], [ %value20, %case20 ], [ %value21, %case21 ], [ %value22, %case22 ], [ %value23, %case23 ], [ %value24, %case24 ], [ %value25, %case25 ], [ %value26, %case26 ], [ %value27, %case27 ], [ %value28, %case28 ], [ %value29, %case29 ], [ %value30, %case30 ], [ %value31, %case31 ], [ %value32, %case32 ], [ %value33, %case33 ], [ %value34, %case34 ], [ %value35, %case35 ], [ %value36, %case36 ], [ %value37, %case37 ], [ %value38, %case38 ], [ %value39, %case39 ], [ %value40, %case40 ], [ %value41, %case41 ], [ %value42, %case42 ], [ %value43, %case43 ], [ %value44, %case44 ], [ %value45, %case45 ], [ %value46, %case46 ], [ %value47, %case47 ], [ %value48, %case48 ], [ %value49, %case49 ], [ %value50, %case50 ], [ %value51, %case51 ], [ %value52, %case52 ], [ %value53, %case53 ], [ %value54, %case54 ], [ %value55, %case55 ], [ %value56, %case56 ], [ %value57, %case57 ], [ %value58, %case58 ], [ %value59, %case59 ], [ %value60, %case60 ], [ %value61, %case61 ], [ %value62, %case62 ], [ %value63, %case63 ], [ %value64, %case64 ], [ %value65, %case65 ], [ %value66, %case66 ], [ %value67, %case67 ], [ %value68, %case68 ], [ %value69, %case69 ], [ %value70, %case70 ], [ %value71, %case71 ], [ %value72, %case72 ], [ %value73, %case73 ], [ %value74, %case74 ], [ %value75, %case75 ], [ %value76, %case76 ], [ %value77, %case77 ], [ %value78, %case78 ], [ %value79, %case79 ], [ %value80, %case80 ], [ %value81, %case81 ], [ %value82, %case82 ], [ %value83, %case83 ], [ %value84, %case84 ], [ %value85, %case85 ], [ %value86, %case86 ], [ %value87, %case87 ], [ %value88, %case88 ], [ %value89, %case89 ], [ %value90, %case90 ], [ %value91, %case91 ], [ %value92, %case92 ], [ %value93, %case93 ], [ %value94, %case94 ], [ %value95, %case95 ], [ %value96, %case96 ], [ %value97, %case97 ], [ %value98, %case98 ], [ %value99, %case99 ], [ %value100, %case100 ], [ %value101, %case101 ], [ %value102, %case102 ], [ %value103, %case103 ], [ %value104, %case104 ], [ %value105, %case105 ], [ %value106, %case106 ], [ %value107, %case107 ], [ %value108, %case108 ], [ %value109, %case109 ], [ %value110, %case110 ], [ %value111, %case111 ], [ %value112, %case112 ], [ %value113, %case113 ], [ %value114, %case114 ], [ %value115, %case115 ], [ %value116, %case116 ], [ %value117, %case117 ], [ %value118, %case118 ], [ %value119, %case119 ], [ %value120, %case120 ], [ %value121, %case121 ], [ %value122, %case122 ], [ %value123, %case123 ], [ %value124, %case124 ], [ %value125, %case125 ], [ %value126, %case126 ]
  store i64 %result, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %result
}


define i64 @switch_32_0(i64 %input, i64 %salt, ptr %out) {
entry:
  %narrow = trunc i64 %input to i32
  switch i32 %narrow, label %fallback [
  ]
fallback:
  %default = add i64 %salt, 999
  br label %merge
merge:
  %result = phi i64 [ %default, %fallback ]
  store i64 %result, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %result
}


define i64 @switch_32_9(i64 %input, i64 %salt, ptr %out) {
entry:
  %narrow = trunc i64 %input to i32
  switch i32 %narrow, label %fallback [
    i32 2147483648, label %case0
    i32 2147483649, label %case1
    i32 2147483650, label %case2
    i32 2147483651, label %case3
    i32 2147483652, label %case4
    i32 2147483653, label %case5
    i32 2147483654, label %case6
    i32 2147483655, label %case7
    i32 2147483656, label %case8
  ]
fallback:
  %default = add i64 %salt, 999
  br label %merge
case0:
  %value0 = add i64 %salt, 0
  br label %merge
case1:
  %value1 = add i64 %salt, 1
  br label %merge
case2:
  %value2 = add i64 %salt, 2
  br label %merge
case3:
  %value3 = add i64 %salt, 3
  br label %merge
case4:
  %value4 = add i64 %salt, 4
  br label %merge
case5:
  %value5 = add i64 %salt, 5
  br label %merge
case6:
  %value6 = add i64 %salt, 6
  br label %merge
case7:
  %value7 = add i64 %salt, 7
  br label %merge
case8:
  %value8 = add i64 %salt, 8
  br label %merge
merge:
  %result = phi i64 [ %default, %fallback ], [ %value0, %case0 ], [ %value1, %case1 ], [ %value2, %case2 ], [ %value3, %case3 ], [ %value4, %case4 ], [ %value5, %case5 ], [ %value6, %case6 ], [ %value7, %case7 ], [ %value8, %case8 ]
  store i64 %result, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %result
}


define i64 @switch_32_61(i64 %input, i64 %salt, ptr %out) {
entry:
  %narrow = trunc i64 %input to i32
  switch i32 %narrow, label %fallback [
    i32 2147483648, label %case0
    i32 2147483649, label %case1
    i32 2147483650, label %case2
    i32 2147483651, label %case3
    i32 2147483652, label %case4
    i32 2147483653, label %case5
    i32 2147483654, label %case6
    i32 2147483655, label %case7
    i32 2147483656, label %case8
    i32 2147483657, label %case9
    i32 2147483658, label %case10
    i32 2147483659, label %case11
    i32 2147483660, label %case12
    i32 2147483661, label %case13
    i32 2147483662, label %case14
    i32 2147483663, label %case15
    i32 2147483664, label %case16
    i32 2147483665, label %case17
    i32 2147483666, label %case18
    i32 2147483667, label %case19
    i32 2147483668, label %case20
    i32 2147483669, label %case21
    i32 2147483670, label %case22
    i32 2147483671, label %case23
    i32 2147483672, label %case24
    i32 2147483673, label %case25
    i32 2147483674, label %case26
    i32 2147483675, label %case27
    i32 2147483676, label %case28
    i32 2147483677, label %case29
    i32 2147483678, label %case30
    i32 2147483679, label %case31
    i32 2147483680, label %case32
    i32 2147483681, label %case33
    i32 2147483682, label %case34
    i32 2147483683, label %case35
    i32 2147483684, label %case36
    i32 2147483685, label %case37
    i32 2147483686, label %case38
    i32 2147483687, label %case39
    i32 2147483688, label %case40
    i32 2147483689, label %case41
    i32 2147483690, label %case42
    i32 2147483691, label %case43
    i32 2147483692, label %case44
    i32 2147483693, label %case45
    i32 2147483694, label %case46
    i32 2147483695, label %case47
    i32 2147483696, label %case48
    i32 2147483697, label %case49
    i32 2147483698, label %case50
    i32 2147483699, label %case51
    i32 2147483700, label %case52
    i32 2147483701, label %case53
    i32 2147483702, label %case54
    i32 2147483703, label %case55
    i32 2147483704, label %case56
    i32 2147483705, label %case57
    i32 2147483706, label %case58
    i32 2147483707, label %case59
    i32 2147483708, label %case60
  ]
fallback:
  %default = add i64 %salt, 999
  br label %merge
case0:
  %value0 = add i64 %salt, 0
  br label %merge
case1:
  %value1 = add i64 %salt, 1
  br label %merge
case2:
  %value2 = add i64 %salt, 2
  br label %merge
case3:
  %value3 = add i64 %salt, 3
  br label %merge
case4:
  %value4 = add i64 %salt, 4
  br label %merge
case5:
  %value5 = add i64 %salt, 5
  br label %merge
case6:
  %value6 = add i64 %salt, 6
  br label %merge
case7:
  %value7 = add i64 %salt, 7
  br label %merge
case8:
  %value8 = add i64 %salt, 8
  br label %merge
case9:
  %value9 = add i64 %salt, 9
  br label %merge
case10:
  %value10 = add i64 %salt, 10
  br label %merge
case11:
  %value11 = add i64 %salt, 11
  br label %merge
case12:
  %value12 = add i64 %salt, 12
  br label %merge
case13:
  %value13 = add i64 %salt, 13
  br label %merge
case14:
  %value14 = add i64 %salt, 14
  br label %merge
case15:
  %value15 = add i64 %salt, 15
  br label %merge
case16:
  %value16 = add i64 %salt, 16
  br label %merge
case17:
  %value17 = add i64 %salt, 17
  br label %merge
case18:
  %value18 = add i64 %salt, 18
  br label %merge
case19:
  %value19 = add i64 %salt, 19
  br label %merge
case20:
  %value20 = add i64 %salt, 20
  br label %merge
case21:
  %value21 = add i64 %salt, 21
  br label %merge
case22:
  %value22 = add i64 %salt, 22
  br label %merge
case23:
  %value23 = add i64 %salt, 23
  br label %merge
case24:
  %value24 = add i64 %salt, 24
  br label %merge
case25:
  %value25 = add i64 %salt, 25
  br label %merge
case26:
  %value26 = add i64 %salt, 26
  br label %merge
case27:
  %value27 = add i64 %salt, 27
  br label %merge
case28:
  %value28 = add i64 %salt, 28
  br label %merge
case29:
  %value29 = add i64 %salt, 29
  br label %merge
case30:
  %value30 = add i64 %salt, 30
  br label %merge
case31:
  %value31 = add i64 %salt, 31
  br label %merge
case32:
  %value32 = add i64 %salt, 32
  br label %merge
case33:
  %value33 = add i64 %salt, 33
  br label %merge
case34:
  %value34 = add i64 %salt, 34
  br label %merge
case35:
  %value35 = add i64 %salt, 35
  br label %merge
case36:
  %value36 = add i64 %salt, 36
  br label %merge
case37:
  %value37 = add i64 %salt, 37
  br label %merge
case38:
  %value38 = add i64 %salt, 38
  br label %merge
case39:
  %value39 = add i64 %salt, 39
  br label %merge
case40:
  %value40 = add i64 %salt, 40
  br label %merge
case41:
  %value41 = add i64 %salt, 41
  br label %merge
case42:
  %value42 = add i64 %salt, 42
  br label %merge
case43:
  %value43 = add i64 %salt, 43
  br label %merge
case44:
  %value44 = add i64 %salt, 44
  br label %merge
case45:
  %value45 = add i64 %salt, 45
  br label %merge
case46:
  %value46 = add i64 %salt, 46
  br label %merge
case47:
  %value47 = add i64 %salt, 47
  br label %merge
case48:
  %value48 = add i64 %salt, 48
  br label %merge
case49:
  %value49 = add i64 %salt, 49
  br label %merge
case50:
  %value50 = add i64 %salt, 50
  br label %merge
case51:
  %value51 = add i64 %salt, 51
  br label %merge
case52:
  %value52 = add i64 %salt, 52
  br label %merge
case53:
  %value53 = add i64 %salt, 53
  br label %merge
case54:
  %value54 = add i64 %salt, 54
  br label %merge
case55:
  %value55 = add i64 %salt, 55
  br label %merge
case56:
  %value56 = add i64 %salt, 56
  br label %merge
case57:
  %value57 = add i64 %salt, 57
  br label %merge
case58:
  %value58 = add i64 %salt, 58
  br label %merge
case59:
  %value59 = add i64 %salt, 59
  br label %merge
case60:
  %value60 = add i64 %salt, 60
  br label %merge
merge:
  %result = phi i64 [ %default, %fallback ], [ %value0, %case0 ], [ %value1, %case1 ], [ %value2, %case2 ], [ %value3, %case3 ], [ %value4, %case4 ], [ %value5, %case5 ], [ %value6, %case6 ], [ %value7, %case7 ], [ %value8, %case8 ], [ %value9, %case9 ], [ %value10, %case10 ], [ %value11, %case11 ], [ %value12, %case12 ], [ %value13, %case13 ], [ %value14, %case14 ], [ %value15, %case15 ], [ %value16, %case16 ], [ %value17, %case17 ], [ %value18, %case18 ], [ %value19, %case19 ], [ %value20, %case20 ], [ %value21, %case21 ], [ %value22, %case22 ], [ %value23, %case23 ], [ %value24, %case24 ], [ %value25, %case25 ], [ %value26, %case26 ], [ %value27, %case27 ], [ %value28, %case28 ], [ %value29, %case29 ], [ %value30, %case30 ], [ %value31, %case31 ], [ %value32, %case32 ], [ %value33, %case33 ], [ %value34, %case34 ], [ %value35, %case35 ], [ %value36, %case36 ], [ %value37, %case37 ], [ %value38, %case38 ], [ %value39, %case39 ], [ %value40, %case40 ], [ %value41, %case41 ], [ %value42, %case42 ], [ %value43, %case43 ], [ %value44, %case44 ], [ %value45, %case45 ], [ %value46, %case46 ], [ %value47, %case47 ], [ %value48, %case48 ], [ %value49, %case49 ], [ %value50, %case50 ], [ %value51, %case51 ], [ %value52, %case52 ], [ %value53, %case53 ], [ %value54, %case54 ], [ %value55, %case55 ], [ %value56, %case56 ], [ %value57, %case57 ], [ %value58, %case58 ], [ %value59, %case59 ], [ %value60, %case60 ]
  store i64 %result, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %result
}


define i64 @switch_32_127(i64 %input, i64 %salt, ptr %out) {
entry:
  %narrow = trunc i64 %input to i32
  switch i32 %narrow, label %fallback [
    i32 2147483648, label %case0
    i32 2147483649, label %case1
    i32 2147483650, label %case2
    i32 2147483651, label %case3
    i32 2147483652, label %case4
    i32 2147483653, label %case5
    i32 2147483654, label %case6
    i32 2147483655, label %case7
    i32 2147483656, label %case8
    i32 2147483657, label %case9
    i32 2147483658, label %case10
    i32 2147483659, label %case11
    i32 2147483660, label %case12
    i32 2147483661, label %case13
    i32 2147483662, label %case14
    i32 2147483663, label %case15
    i32 2147483664, label %case16
    i32 2147483665, label %case17
    i32 2147483666, label %case18
    i32 2147483667, label %case19
    i32 2147483668, label %case20
    i32 2147483669, label %case21
    i32 2147483670, label %case22
    i32 2147483671, label %case23
    i32 2147483672, label %case24
    i32 2147483673, label %case25
    i32 2147483674, label %case26
    i32 2147483675, label %case27
    i32 2147483676, label %case28
    i32 2147483677, label %case29
    i32 2147483678, label %case30
    i32 2147483679, label %case31
    i32 2147483680, label %case32
    i32 2147483681, label %case33
    i32 2147483682, label %case34
    i32 2147483683, label %case35
    i32 2147483684, label %case36
    i32 2147483685, label %case37
    i32 2147483686, label %case38
    i32 2147483687, label %case39
    i32 2147483688, label %case40
    i32 2147483689, label %case41
    i32 2147483690, label %case42
    i32 2147483691, label %case43
    i32 2147483692, label %case44
    i32 2147483693, label %case45
    i32 2147483694, label %case46
    i32 2147483695, label %case47
    i32 2147483696, label %case48
    i32 2147483697, label %case49
    i32 2147483698, label %case50
    i32 2147483699, label %case51
    i32 2147483700, label %case52
    i32 2147483701, label %case53
    i32 2147483702, label %case54
    i32 2147483703, label %case55
    i32 2147483704, label %case56
    i32 2147483705, label %case57
    i32 2147483706, label %case58
    i32 2147483707, label %case59
    i32 2147483708, label %case60
    i32 2147483709, label %case61
    i32 2147483710, label %case62
    i32 2147483711, label %case63
    i32 2147483712, label %case64
    i32 2147483713, label %case65
    i32 2147483714, label %case66
    i32 2147483715, label %case67
    i32 2147483716, label %case68
    i32 2147483717, label %case69
    i32 2147483718, label %case70
    i32 2147483719, label %case71
    i32 2147483720, label %case72
    i32 2147483721, label %case73
    i32 2147483722, label %case74
    i32 2147483723, label %case75
    i32 2147483724, label %case76
    i32 2147483725, label %case77
    i32 2147483726, label %case78
    i32 2147483727, label %case79
    i32 2147483728, label %case80
    i32 2147483729, label %case81
    i32 2147483730, label %case82
    i32 2147483731, label %case83
    i32 2147483732, label %case84
    i32 2147483733, label %case85
    i32 2147483734, label %case86
    i32 2147483735, label %case87
    i32 2147483736, label %case88
    i32 2147483737, label %case89
    i32 2147483738, label %case90
    i32 2147483739, label %case91
    i32 2147483740, label %case92
    i32 2147483741, label %case93
    i32 2147483742, label %case94
    i32 2147483743, label %case95
    i32 2147483744, label %case96
    i32 2147483745, label %case97
    i32 2147483746, label %case98
    i32 2147483747, label %case99
    i32 2147483748, label %case100
    i32 2147483749, label %case101
    i32 2147483750, label %case102
    i32 2147483751, label %case103
    i32 2147483752, label %case104
    i32 2147483753, label %case105
    i32 2147483754, label %case106
    i32 2147483755, label %case107
    i32 2147483756, label %case108
    i32 2147483757, label %case109
    i32 2147483758, label %case110
    i32 2147483759, label %case111
    i32 2147483760, label %case112
    i32 2147483761, label %case113
    i32 2147483762, label %case114
    i32 2147483763, label %case115
    i32 2147483764, label %case116
    i32 2147483765, label %case117
    i32 2147483766, label %case118
    i32 2147483767, label %case119
    i32 2147483768, label %case120
    i32 2147483769, label %case121
    i32 2147483770, label %case122
    i32 2147483771, label %case123
    i32 2147483772, label %case124
    i32 2147483773, label %case125
    i32 2147483774, label %case126
  ]
fallback:
  %default = add i64 %salt, 999
  br label %merge
case0:
  %value0 = add i64 %salt, 0
  br label %merge
case1:
  %value1 = add i64 %salt, 1
  br label %merge
case2:
  %value2 = add i64 %salt, 2
  br label %merge
case3:
  %value3 = add i64 %salt, 3
  br label %merge
case4:
  %value4 = add i64 %salt, 4
  br label %merge
case5:
  %value5 = add i64 %salt, 5
  br label %merge
case6:
  %value6 = add i64 %salt, 6
  br label %merge
case7:
  %value7 = add i64 %salt, 7
  br label %merge
case8:
  %value8 = add i64 %salt, 8
  br label %merge
case9:
  %value9 = add i64 %salt, 9
  br label %merge
case10:
  %value10 = add i64 %salt, 10
  br label %merge
case11:
  %value11 = add i64 %salt, 11
  br label %merge
case12:
  %value12 = add i64 %salt, 12
  br label %merge
case13:
  %value13 = add i64 %salt, 13
  br label %merge
case14:
  %value14 = add i64 %salt, 14
  br label %merge
case15:
  %value15 = add i64 %salt, 15
  br label %merge
case16:
  %value16 = add i64 %salt, 16
  br label %merge
case17:
  %value17 = add i64 %salt, 17
  br label %merge
case18:
  %value18 = add i64 %salt, 18
  br label %merge
case19:
  %value19 = add i64 %salt, 19
  br label %merge
case20:
  %value20 = add i64 %salt, 20
  br label %merge
case21:
  %value21 = add i64 %salt, 21
  br label %merge
case22:
  %value22 = add i64 %salt, 22
  br label %merge
case23:
  %value23 = add i64 %salt, 23
  br label %merge
case24:
  %value24 = add i64 %salt, 24
  br label %merge
case25:
  %value25 = add i64 %salt, 25
  br label %merge
case26:
  %value26 = add i64 %salt, 26
  br label %merge
case27:
  %value27 = add i64 %salt, 27
  br label %merge
case28:
  %value28 = add i64 %salt, 28
  br label %merge
case29:
  %value29 = add i64 %salt, 29
  br label %merge
case30:
  %value30 = add i64 %salt, 30
  br label %merge
case31:
  %value31 = add i64 %salt, 31
  br label %merge
case32:
  %value32 = add i64 %salt, 32
  br label %merge
case33:
  %value33 = add i64 %salt, 33
  br label %merge
case34:
  %value34 = add i64 %salt, 34
  br label %merge
case35:
  %value35 = add i64 %salt, 35
  br label %merge
case36:
  %value36 = add i64 %salt, 36
  br label %merge
case37:
  %value37 = add i64 %salt, 37
  br label %merge
case38:
  %value38 = add i64 %salt, 38
  br label %merge
case39:
  %value39 = add i64 %salt, 39
  br label %merge
case40:
  %value40 = add i64 %salt, 40
  br label %merge
case41:
  %value41 = add i64 %salt, 41
  br label %merge
case42:
  %value42 = add i64 %salt, 42
  br label %merge
case43:
  %value43 = add i64 %salt, 43
  br label %merge
case44:
  %value44 = add i64 %salt, 44
  br label %merge
case45:
  %value45 = add i64 %salt, 45
  br label %merge
case46:
  %value46 = add i64 %salt, 46
  br label %merge
case47:
  %value47 = add i64 %salt, 47
  br label %merge
case48:
  %value48 = add i64 %salt, 48
  br label %merge
case49:
  %value49 = add i64 %salt, 49
  br label %merge
case50:
  %value50 = add i64 %salt, 50
  br label %merge
case51:
  %value51 = add i64 %salt, 51
  br label %merge
case52:
  %value52 = add i64 %salt, 52
  br label %merge
case53:
  %value53 = add i64 %salt, 53
  br label %merge
case54:
  %value54 = add i64 %salt, 54
  br label %merge
case55:
  %value55 = add i64 %salt, 55
  br label %merge
case56:
  %value56 = add i64 %salt, 56
  br label %merge
case57:
  %value57 = add i64 %salt, 57
  br label %merge
case58:
  %value58 = add i64 %salt, 58
  br label %merge
case59:
  %value59 = add i64 %salt, 59
  br label %merge
case60:
  %value60 = add i64 %salt, 60
  br label %merge
case61:
  %value61 = add i64 %salt, 61
  br label %merge
case62:
  %value62 = add i64 %salt, 62
  br label %merge
case63:
  %value63 = add i64 %salt, 63
  br label %merge
case64:
  %value64 = add i64 %salt, 64
  br label %merge
case65:
  %value65 = add i64 %salt, 65
  br label %merge
case66:
  %value66 = add i64 %salt, 66
  br label %merge
case67:
  %value67 = add i64 %salt, 67
  br label %merge
case68:
  %value68 = add i64 %salt, 68
  br label %merge
case69:
  %value69 = add i64 %salt, 69
  br label %merge
case70:
  %value70 = add i64 %salt, 70
  br label %merge
case71:
  %value71 = add i64 %salt, 71
  br label %merge
case72:
  %value72 = add i64 %salt, 72
  br label %merge
case73:
  %value73 = add i64 %salt, 73
  br label %merge
case74:
  %value74 = add i64 %salt, 74
  br label %merge
case75:
  %value75 = add i64 %salt, 75
  br label %merge
case76:
  %value76 = add i64 %salt, 76
  br label %merge
case77:
  %value77 = add i64 %salt, 77
  br label %merge
case78:
  %value78 = add i64 %salt, 78
  br label %merge
case79:
  %value79 = add i64 %salt, 79
  br label %merge
case80:
  %value80 = add i64 %salt, 80
  br label %merge
case81:
  %value81 = add i64 %salt, 81
  br label %merge
case82:
  %value82 = add i64 %salt, 82
  br label %merge
case83:
  %value83 = add i64 %salt, 83
  br label %merge
case84:
  %value84 = add i64 %salt, 84
  br label %merge
case85:
  %value85 = add i64 %salt, 85
  br label %merge
case86:
  %value86 = add i64 %salt, 86
  br label %merge
case87:
  %value87 = add i64 %salt, 87
  br label %merge
case88:
  %value88 = add i64 %salt, 88
  br label %merge
case89:
  %value89 = add i64 %salt, 89
  br label %merge
case90:
  %value90 = add i64 %salt, 90
  br label %merge
case91:
  %value91 = add i64 %salt, 91
  br label %merge
case92:
  %value92 = add i64 %salt, 92
  br label %merge
case93:
  %value93 = add i64 %salt, 93
  br label %merge
case94:
  %value94 = add i64 %salt, 94
  br label %merge
case95:
  %value95 = add i64 %salt, 95
  br label %merge
case96:
  %value96 = add i64 %salt, 96
  br label %merge
case97:
  %value97 = add i64 %salt, 97
  br label %merge
case98:
  %value98 = add i64 %salt, 98
  br label %merge
case99:
  %value99 = add i64 %salt, 99
  br label %merge
case100:
  %value100 = add i64 %salt, 100
  br label %merge
case101:
  %value101 = add i64 %salt, 101
  br label %merge
case102:
  %value102 = add i64 %salt, 102
  br label %merge
case103:
  %value103 = add i64 %salt, 103
  br label %merge
case104:
  %value104 = add i64 %salt, 104
  br label %merge
case105:
  %value105 = add i64 %salt, 105
  br label %merge
case106:
  %value106 = add i64 %salt, 106
  br label %merge
case107:
  %value107 = add i64 %salt, 107
  br label %merge
case108:
  %value108 = add i64 %salt, 108
  br label %merge
case109:
  %value109 = add i64 %salt, 109
  br label %merge
case110:
  %value110 = add i64 %salt, 110
  br label %merge
case111:
  %value111 = add i64 %salt, 111
  br label %merge
case112:
  %value112 = add i64 %salt, 112
  br label %merge
case113:
  %value113 = add i64 %salt, 113
  br label %merge
case114:
  %value114 = add i64 %salt, 114
  br label %merge
case115:
  %value115 = add i64 %salt, 115
  br label %merge
case116:
  %value116 = add i64 %salt, 116
  br label %merge
case117:
  %value117 = add i64 %salt, 117
  br label %merge
case118:
  %value118 = add i64 %salt, 118
  br label %merge
case119:
  %value119 = add i64 %salt, 119
  br label %merge
case120:
  %value120 = add i64 %salt, 120
  br label %merge
case121:
  %value121 = add i64 %salt, 121
  br label %merge
case122:
  %value122 = add i64 %salt, 122
  br label %merge
case123:
  %value123 = add i64 %salt, 123
  br label %merge
case124:
  %value124 = add i64 %salt, 124
  br label %merge
case125:
  %value125 = add i64 %salt, 125
  br label %merge
case126:
  %value126 = add i64 %salt, 126
  br label %merge
merge:
  %result = phi i64 [ %default, %fallback ], [ %value0, %case0 ], [ %value1, %case1 ], [ %value2, %case2 ], [ %value3, %case3 ], [ %value4, %case4 ], [ %value5, %case5 ], [ %value6, %case6 ], [ %value7, %case7 ], [ %value8, %case8 ], [ %value9, %case9 ], [ %value10, %case10 ], [ %value11, %case11 ], [ %value12, %case12 ], [ %value13, %case13 ], [ %value14, %case14 ], [ %value15, %case15 ], [ %value16, %case16 ], [ %value17, %case17 ], [ %value18, %case18 ], [ %value19, %case19 ], [ %value20, %case20 ], [ %value21, %case21 ], [ %value22, %case22 ], [ %value23, %case23 ], [ %value24, %case24 ], [ %value25, %case25 ], [ %value26, %case26 ], [ %value27, %case27 ], [ %value28, %case28 ], [ %value29, %case29 ], [ %value30, %case30 ], [ %value31, %case31 ], [ %value32, %case32 ], [ %value33, %case33 ], [ %value34, %case34 ], [ %value35, %case35 ], [ %value36, %case36 ], [ %value37, %case37 ], [ %value38, %case38 ], [ %value39, %case39 ], [ %value40, %case40 ], [ %value41, %case41 ], [ %value42, %case42 ], [ %value43, %case43 ], [ %value44, %case44 ], [ %value45, %case45 ], [ %value46, %case46 ], [ %value47, %case47 ], [ %value48, %case48 ], [ %value49, %case49 ], [ %value50, %case50 ], [ %value51, %case51 ], [ %value52, %case52 ], [ %value53, %case53 ], [ %value54, %case54 ], [ %value55, %case55 ], [ %value56, %case56 ], [ %value57, %case57 ], [ %value58, %case58 ], [ %value59, %case59 ], [ %value60, %case60 ], [ %value61, %case61 ], [ %value62, %case62 ], [ %value63, %case63 ], [ %value64, %case64 ], [ %value65, %case65 ], [ %value66, %case66 ], [ %value67, %case67 ], [ %value68, %case68 ], [ %value69, %case69 ], [ %value70, %case70 ], [ %value71, %case71 ], [ %value72, %case72 ], [ %value73, %case73 ], [ %value74, %case74 ], [ %value75, %case75 ], [ %value76, %case76 ], [ %value77, %case77 ], [ %value78, %case78 ], [ %value79, %case79 ], [ %value80, %case80 ], [ %value81, %case81 ], [ %value82, %case82 ], [ %value83, %case83 ], [ %value84, %case84 ], [ %value85, %case85 ], [ %value86, %case86 ], [ %value87, %case87 ], [ %value88, %case88 ], [ %value89, %case89 ], [ %value90, %case90 ], [ %value91, %case91 ], [ %value92, %case92 ], [ %value93, %case93 ], [ %value94, %case94 ], [ %value95, %case95 ], [ %value96, %case96 ], [ %value97, %case97 ], [ %value98, %case98 ], [ %value99, %case99 ], [ %value100, %case100 ], [ %value101, %case101 ], [ %value102, %case102 ], [ %value103, %case103 ], [ %value104, %case104 ], [ %value105, %case105 ], [ %value106, %case106 ], [ %value107, %case107 ], [ %value108, %case108 ], [ %value109, %case109 ], [ %value110, %case110 ], [ %value111, %case111 ], [ %value112, %case112 ], [ %value113, %case113 ], [ %value114, %case114 ], [ %value115, %case115 ], [ %value116, %case116 ], [ %value117, %case117 ], [ %value118, %case118 ], [ %value119, %case119 ], [ %value120, %case120 ], [ %value121, %case121 ], [ %value122, %case122 ], [ %value123, %case123 ], [ %value124, %case124 ], [ %value125, %case125 ], [ %value126, %case126 ]
  store i64 %result, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %result
}


define i64 @switch_64_0(i64 %input, i64 %salt, ptr %out) {
entry:
  switch i64 %input, label %fallback [
  ]
fallback:
  %default = add i64 %salt, 999
  br label %merge
merge:
  %result = phi i64 [ %default, %fallback ]
  store i64 %result, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %result
}


define i64 @switch_64_9(i64 %input, i64 %salt, ptr %out) {
entry:
  switch i64 %input, label %fallback [
    i64 9223372036854775808, label %case0
    i64 9223372036854775809, label %case1
    i64 9223372036854775810, label %case2
    i64 9223372036854775811, label %case3
    i64 9223372036854775812, label %case4
    i64 9223372036854775813, label %case5
    i64 9223372036854775814, label %case6
    i64 9223372036854775815, label %case7
    i64 9223372036854775816, label %case8
  ]
fallback:
  %default = add i64 %salt, 999
  br label %merge
case0:
  %value0 = add i64 %salt, 0
  br label %merge
case1:
  %value1 = add i64 %salt, 1
  br label %merge
case2:
  %value2 = add i64 %salt, 2
  br label %merge
case3:
  %value3 = add i64 %salt, 3
  br label %merge
case4:
  %value4 = add i64 %salt, 4
  br label %merge
case5:
  %value5 = add i64 %salt, 5
  br label %merge
case6:
  %value6 = add i64 %salt, 6
  br label %merge
case7:
  %value7 = add i64 %salt, 7
  br label %merge
case8:
  %value8 = add i64 %salt, 8
  br label %merge
merge:
  %result = phi i64 [ %default, %fallback ], [ %value0, %case0 ], [ %value1, %case1 ], [ %value2, %case2 ], [ %value3, %case3 ], [ %value4, %case4 ], [ %value5, %case5 ], [ %value6, %case6 ], [ %value7, %case7 ], [ %value8, %case8 ]
  store i64 %result, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %result
}


define i64 @switch_64_61(i64 %input, i64 %salt, ptr %out) {
entry:
  switch i64 %input, label %fallback [
    i64 9223372036854775808, label %case0
    i64 9223372036854775809, label %case1
    i64 9223372036854775810, label %case2
    i64 9223372036854775811, label %case3
    i64 9223372036854775812, label %case4
    i64 9223372036854775813, label %case5
    i64 9223372036854775814, label %case6
    i64 9223372036854775815, label %case7
    i64 9223372036854775816, label %case8
    i64 9223372036854775817, label %case9
    i64 9223372036854775818, label %case10
    i64 9223372036854775819, label %case11
    i64 9223372036854775820, label %case12
    i64 9223372036854775821, label %case13
    i64 9223372036854775822, label %case14
    i64 9223372036854775823, label %case15
    i64 9223372036854775824, label %case16
    i64 9223372036854775825, label %case17
    i64 9223372036854775826, label %case18
    i64 9223372036854775827, label %case19
    i64 9223372036854775828, label %case20
    i64 9223372036854775829, label %case21
    i64 9223372036854775830, label %case22
    i64 9223372036854775831, label %case23
    i64 9223372036854775832, label %case24
    i64 9223372036854775833, label %case25
    i64 9223372036854775834, label %case26
    i64 9223372036854775835, label %case27
    i64 9223372036854775836, label %case28
    i64 9223372036854775837, label %case29
    i64 9223372036854775838, label %case30
    i64 9223372036854775839, label %case31
    i64 9223372036854775840, label %case32
    i64 9223372036854775841, label %case33
    i64 9223372036854775842, label %case34
    i64 9223372036854775843, label %case35
    i64 9223372036854775844, label %case36
    i64 9223372036854775845, label %case37
    i64 9223372036854775846, label %case38
    i64 9223372036854775847, label %case39
    i64 9223372036854775848, label %case40
    i64 9223372036854775849, label %case41
    i64 9223372036854775850, label %case42
    i64 9223372036854775851, label %case43
    i64 9223372036854775852, label %case44
    i64 9223372036854775853, label %case45
    i64 9223372036854775854, label %case46
    i64 9223372036854775855, label %case47
    i64 9223372036854775856, label %case48
    i64 9223372036854775857, label %case49
    i64 9223372036854775858, label %case50
    i64 9223372036854775859, label %case51
    i64 9223372036854775860, label %case52
    i64 9223372036854775861, label %case53
    i64 9223372036854775862, label %case54
    i64 9223372036854775863, label %case55
    i64 9223372036854775864, label %case56
    i64 9223372036854775865, label %case57
    i64 9223372036854775866, label %case58
    i64 9223372036854775867, label %case59
    i64 9223372036854775868, label %case60
  ]
fallback:
  %default = add i64 %salt, 999
  br label %merge
case0:
  %value0 = add i64 %salt, 0
  br label %merge
case1:
  %value1 = add i64 %salt, 1
  br label %merge
case2:
  %value2 = add i64 %salt, 2
  br label %merge
case3:
  %value3 = add i64 %salt, 3
  br label %merge
case4:
  %value4 = add i64 %salt, 4
  br label %merge
case5:
  %value5 = add i64 %salt, 5
  br label %merge
case6:
  %value6 = add i64 %salt, 6
  br label %merge
case7:
  %value7 = add i64 %salt, 7
  br label %merge
case8:
  %value8 = add i64 %salt, 8
  br label %merge
case9:
  %value9 = add i64 %salt, 9
  br label %merge
case10:
  %value10 = add i64 %salt, 10
  br label %merge
case11:
  %value11 = add i64 %salt, 11
  br label %merge
case12:
  %value12 = add i64 %salt, 12
  br label %merge
case13:
  %value13 = add i64 %salt, 13
  br label %merge
case14:
  %value14 = add i64 %salt, 14
  br label %merge
case15:
  %value15 = add i64 %salt, 15
  br label %merge
case16:
  %value16 = add i64 %salt, 16
  br label %merge
case17:
  %value17 = add i64 %salt, 17
  br label %merge
case18:
  %value18 = add i64 %salt, 18
  br label %merge
case19:
  %value19 = add i64 %salt, 19
  br label %merge
case20:
  %value20 = add i64 %salt, 20
  br label %merge
case21:
  %value21 = add i64 %salt, 21
  br label %merge
case22:
  %value22 = add i64 %salt, 22
  br label %merge
case23:
  %value23 = add i64 %salt, 23
  br label %merge
case24:
  %value24 = add i64 %salt, 24
  br label %merge
case25:
  %value25 = add i64 %salt, 25
  br label %merge
case26:
  %value26 = add i64 %salt, 26
  br label %merge
case27:
  %value27 = add i64 %salt, 27
  br label %merge
case28:
  %value28 = add i64 %salt, 28
  br label %merge
case29:
  %value29 = add i64 %salt, 29
  br label %merge
case30:
  %value30 = add i64 %salt, 30
  br label %merge
case31:
  %value31 = add i64 %salt, 31
  br label %merge
case32:
  %value32 = add i64 %salt, 32
  br label %merge
case33:
  %value33 = add i64 %salt, 33
  br label %merge
case34:
  %value34 = add i64 %salt, 34
  br label %merge
case35:
  %value35 = add i64 %salt, 35
  br label %merge
case36:
  %value36 = add i64 %salt, 36
  br label %merge
case37:
  %value37 = add i64 %salt, 37
  br label %merge
case38:
  %value38 = add i64 %salt, 38
  br label %merge
case39:
  %value39 = add i64 %salt, 39
  br label %merge
case40:
  %value40 = add i64 %salt, 40
  br label %merge
case41:
  %value41 = add i64 %salt, 41
  br label %merge
case42:
  %value42 = add i64 %salt, 42
  br label %merge
case43:
  %value43 = add i64 %salt, 43
  br label %merge
case44:
  %value44 = add i64 %salt, 44
  br label %merge
case45:
  %value45 = add i64 %salt, 45
  br label %merge
case46:
  %value46 = add i64 %salt, 46
  br label %merge
case47:
  %value47 = add i64 %salt, 47
  br label %merge
case48:
  %value48 = add i64 %salt, 48
  br label %merge
case49:
  %value49 = add i64 %salt, 49
  br label %merge
case50:
  %value50 = add i64 %salt, 50
  br label %merge
case51:
  %value51 = add i64 %salt, 51
  br label %merge
case52:
  %value52 = add i64 %salt, 52
  br label %merge
case53:
  %value53 = add i64 %salt, 53
  br label %merge
case54:
  %value54 = add i64 %salt, 54
  br label %merge
case55:
  %value55 = add i64 %salt, 55
  br label %merge
case56:
  %value56 = add i64 %salt, 56
  br label %merge
case57:
  %value57 = add i64 %salt, 57
  br label %merge
case58:
  %value58 = add i64 %salt, 58
  br label %merge
case59:
  %value59 = add i64 %salt, 59
  br label %merge
case60:
  %value60 = add i64 %salt, 60
  br label %merge
merge:
  %result = phi i64 [ %default, %fallback ], [ %value0, %case0 ], [ %value1, %case1 ], [ %value2, %case2 ], [ %value3, %case3 ], [ %value4, %case4 ], [ %value5, %case5 ], [ %value6, %case6 ], [ %value7, %case7 ], [ %value8, %case8 ], [ %value9, %case9 ], [ %value10, %case10 ], [ %value11, %case11 ], [ %value12, %case12 ], [ %value13, %case13 ], [ %value14, %case14 ], [ %value15, %case15 ], [ %value16, %case16 ], [ %value17, %case17 ], [ %value18, %case18 ], [ %value19, %case19 ], [ %value20, %case20 ], [ %value21, %case21 ], [ %value22, %case22 ], [ %value23, %case23 ], [ %value24, %case24 ], [ %value25, %case25 ], [ %value26, %case26 ], [ %value27, %case27 ], [ %value28, %case28 ], [ %value29, %case29 ], [ %value30, %case30 ], [ %value31, %case31 ], [ %value32, %case32 ], [ %value33, %case33 ], [ %value34, %case34 ], [ %value35, %case35 ], [ %value36, %case36 ], [ %value37, %case37 ], [ %value38, %case38 ], [ %value39, %case39 ], [ %value40, %case40 ], [ %value41, %case41 ], [ %value42, %case42 ], [ %value43, %case43 ], [ %value44, %case44 ], [ %value45, %case45 ], [ %value46, %case46 ], [ %value47, %case47 ], [ %value48, %case48 ], [ %value49, %case49 ], [ %value50, %case50 ], [ %value51, %case51 ], [ %value52, %case52 ], [ %value53, %case53 ], [ %value54, %case54 ], [ %value55, %case55 ], [ %value56, %case56 ], [ %value57, %case57 ], [ %value58, %case58 ], [ %value59, %case59 ], [ %value60, %case60 ]
  store i64 %result, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %result
}


define i64 @switch_64_127(i64 %input, i64 %salt, ptr %out) {
entry:
  switch i64 %input, label %fallback [
    i64 9223372036854775808, label %case0
    i64 9223372036854775809, label %case1
    i64 9223372036854775810, label %case2
    i64 9223372036854775811, label %case3
    i64 9223372036854775812, label %case4
    i64 9223372036854775813, label %case5
    i64 9223372036854775814, label %case6
    i64 9223372036854775815, label %case7
    i64 9223372036854775816, label %case8
    i64 9223372036854775817, label %case9
    i64 9223372036854775818, label %case10
    i64 9223372036854775819, label %case11
    i64 9223372036854775820, label %case12
    i64 9223372036854775821, label %case13
    i64 9223372036854775822, label %case14
    i64 9223372036854775823, label %case15
    i64 9223372036854775824, label %case16
    i64 9223372036854775825, label %case17
    i64 9223372036854775826, label %case18
    i64 9223372036854775827, label %case19
    i64 9223372036854775828, label %case20
    i64 9223372036854775829, label %case21
    i64 9223372036854775830, label %case22
    i64 9223372036854775831, label %case23
    i64 9223372036854775832, label %case24
    i64 9223372036854775833, label %case25
    i64 9223372036854775834, label %case26
    i64 9223372036854775835, label %case27
    i64 9223372036854775836, label %case28
    i64 9223372036854775837, label %case29
    i64 9223372036854775838, label %case30
    i64 9223372036854775839, label %case31
    i64 9223372036854775840, label %case32
    i64 9223372036854775841, label %case33
    i64 9223372036854775842, label %case34
    i64 9223372036854775843, label %case35
    i64 9223372036854775844, label %case36
    i64 9223372036854775845, label %case37
    i64 9223372036854775846, label %case38
    i64 9223372036854775847, label %case39
    i64 9223372036854775848, label %case40
    i64 9223372036854775849, label %case41
    i64 9223372036854775850, label %case42
    i64 9223372036854775851, label %case43
    i64 9223372036854775852, label %case44
    i64 9223372036854775853, label %case45
    i64 9223372036854775854, label %case46
    i64 9223372036854775855, label %case47
    i64 9223372036854775856, label %case48
    i64 9223372036854775857, label %case49
    i64 9223372036854775858, label %case50
    i64 9223372036854775859, label %case51
    i64 9223372036854775860, label %case52
    i64 9223372036854775861, label %case53
    i64 9223372036854775862, label %case54
    i64 9223372036854775863, label %case55
    i64 9223372036854775864, label %case56
    i64 9223372036854775865, label %case57
    i64 9223372036854775866, label %case58
    i64 9223372036854775867, label %case59
    i64 9223372036854775868, label %case60
    i64 9223372036854775869, label %case61
    i64 9223372036854775870, label %case62
    i64 9223372036854775871, label %case63
    i64 9223372036854775872, label %case64
    i64 9223372036854775873, label %case65
    i64 9223372036854775874, label %case66
    i64 9223372036854775875, label %case67
    i64 9223372036854775876, label %case68
    i64 9223372036854775877, label %case69
    i64 9223372036854775878, label %case70
    i64 9223372036854775879, label %case71
    i64 9223372036854775880, label %case72
    i64 9223372036854775881, label %case73
    i64 9223372036854775882, label %case74
    i64 9223372036854775883, label %case75
    i64 9223372036854775884, label %case76
    i64 9223372036854775885, label %case77
    i64 9223372036854775886, label %case78
    i64 9223372036854775887, label %case79
    i64 9223372036854775888, label %case80
    i64 9223372036854775889, label %case81
    i64 9223372036854775890, label %case82
    i64 9223372036854775891, label %case83
    i64 9223372036854775892, label %case84
    i64 9223372036854775893, label %case85
    i64 9223372036854775894, label %case86
    i64 9223372036854775895, label %case87
    i64 9223372036854775896, label %case88
    i64 9223372036854775897, label %case89
    i64 9223372036854775898, label %case90
    i64 9223372036854775899, label %case91
    i64 9223372036854775900, label %case92
    i64 9223372036854775901, label %case93
    i64 9223372036854775902, label %case94
    i64 9223372036854775903, label %case95
    i64 9223372036854775904, label %case96
    i64 9223372036854775905, label %case97
    i64 9223372036854775906, label %case98
    i64 9223372036854775907, label %case99
    i64 9223372036854775908, label %case100
    i64 9223372036854775909, label %case101
    i64 9223372036854775910, label %case102
    i64 9223372036854775911, label %case103
    i64 9223372036854775912, label %case104
    i64 9223372036854775913, label %case105
    i64 9223372036854775914, label %case106
    i64 9223372036854775915, label %case107
    i64 9223372036854775916, label %case108
    i64 9223372036854775917, label %case109
    i64 9223372036854775918, label %case110
    i64 9223372036854775919, label %case111
    i64 9223372036854775920, label %case112
    i64 9223372036854775921, label %case113
    i64 9223372036854775922, label %case114
    i64 9223372036854775923, label %case115
    i64 9223372036854775924, label %case116
    i64 9223372036854775925, label %case117
    i64 9223372036854775926, label %case118
    i64 9223372036854775927, label %case119
    i64 9223372036854775928, label %case120
    i64 9223372036854775929, label %case121
    i64 9223372036854775930, label %case122
    i64 9223372036854775931, label %case123
    i64 9223372036854775932, label %case124
    i64 9223372036854775933, label %case125
    i64 9223372036854775934, label %case126
  ]
fallback:
  %default = add i64 %salt, 999
  br label %merge
case0:
  %value0 = add i64 %salt, 0
  br label %merge
case1:
  %value1 = add i64 %salt, 1
  br label %merge
case2:
  %value2 = add i64 %salt, 2
  br label %merge
case3:
  %value3 = add i64 %salt, 3
  br label %merge
case4:
  %value4 = add i64 %salt, 4
  br label %merge
case5:
  %value5 = add i64 %salt, 5
  br label %merge
case6:
  %value6 = add i64 %salt, 6
  br label %merge
case7:
  %value7 = add i64 %salt, 7
  br label %merge
case8:
  %value8 = add i64 %salt, 8
  br label %merge
case9:
  %value9 = add i64 %salt, 9
  br label %merge
case10:
  %value10 = add i64 %salt, 10
  br label %merge
case11:
  %value11 = add i64 %salt, 11
  br label %merge
case12:
  %value12 = add i64 %salt, 12
  br label %merge
case13:
  %value13 = add i64 %salt, 13
  br label %merge
case14:
  %value14 = add i64 %salt, 14
  br label %merge
case15:
  %value15 = add i64 %salt, 15
  br label %merge
case16:
  %value16 = add i64 %salt, 16
  br label %merge
case17:
  %value17 = add i64 %salt, 17
  br label %merge
case18:
  %value18 = add i64 %salt, 18
  br label %merge
case19:
  %value19 = add i64 %salt, 19
  br label %merge
case20:
  %value20 = add i64 %salt, 20
  br label %merge
case21:
  %value21 = add i64 %salt, 21
  br label %merge
case22:
  %value22 = add i64 %salt, 22
  br label %merge
case23:
  %value23 = add i64 %salt, 23
  br label %merge
case24:
  %value24 = add i64 %salt, 24
  br label %merge
case25:
  %value25 = add i64 %salt, 25
  br label %merge
case26:
  %value26 = add i64 %salt, 26
  br label %merge
case27:
  %value27 = add i64 %salt, 27
  br label %merge
case28:
  %value28 = add i64 %salt, 28
  br label %merge
case29:
  %value29 = add i64 %salt, 29
  br label %merge
case30:
  %value30 = add i64 %salt, 30
  br label %merge
case31:
  %value31 = add i64 %salt, 31
  br label %merge
case32:
  %value32 = add i64 %salt, 32
  br label %merge
case33:
  %value33 = add i64 %salt, 33
  br label %merge
case34:
  %value34 = add i64 %salt, 34
  br label %merge
case35:
  %value35 = add i64 %salt, 35
  br label %merge
case36:
  %value36 = add i64 %salt, 36
  br label %merge
case37:
  %value37 = add i64 %salt, 37
  br label %merge
case38:
  %value38 = add i64 %salt, 38
  br label %merge
case39:
  %value39 = add i64 %salt, 39
  br label %merge
case40:
  %value40 = add i64 %salt, 40
  br label %merge
case41:
  %value41 = add i64 %salt, 41
  br label %merge
case42:
  %value42 = add i64 %salt, 42
  br label %merge
case43:
  %value43 = add i64 %salt, 43
  br label %merge
case44:
  %value44 = add i64 %salt, 44
  br label %merge
case45:
  %value45 = add i64 %salt, 45
  br label %merge
case46:
  %value46 = add i64 %salt, 46
  br label %merge
case47:
  %value47 = add i64 %salt, 47
  br label %merge
case48:
  %value48 = add i64 %salt, 48
  br label %merge
case49:
  %value49 = add i64 %salt, 49
  br label %merge
case50:
  %value50 = add i64 %salt, 50
  br label %merge
case51:
  %value51 = add i64 %salt, 51
  br label %merge
case52:
  %value52 = add i64 %salt, 52
  br label %merge
case53:
  %value53 = add i64 %salt, 53
  br label %merge
case54:
  %value54 = add i64 %salt, 54
  br label %merge
case55:
  %value55 = add i64 %salt, 55
  br label %merge
case56:
  %value56 = add i64 %salt, 56
  br label %merge
case57:
  %value57 = add i64 %salt, 57
  br label %merge
case58:
  %value58 = add i64 %salt, 58
  br label %merge
case59:
  %value59 = add i64 %salt, 59
  br label %merge
case60:
  %value60 = add i64 %salt, 60
  br label %merge
case61:
  %value61 = add i64 %salt, 61
  br label %merge
case62:
  %value62 = add i64 %salt, 62
  br label %merge
case63:
  %value63 = add i64 %salt, 63
  br label %merge
case64:
  %value64 = add i64 %salt, 64
  br label %merge
case65:
  %value65 = add i64 %salt, 65
  br label %merge
case66:
  %value66 = add i64 %salt, 66
  br label %merge
case67:
  %value67 = add i64 %salt, 67
  br label %merge
case68:
  %value68 = add i64 %salt, 68
  br label %merge
case69:
  %value69 = add i64 %salt, 69
  br label %merge
case70:
  %value70 = add i64 %salt, 70
  br label %merge
case71:
  %value71 = add i64 %salt, 71
  br label %merge
case72:
  %value72 = add i64 %salt, 72
  br label %merge
case73:
  %value73 = add i64 %salt, 73
  br label %merge
case74:
  %value74 = add i64 %salt, 74
  br label %merge
case75:
  %value75 = add i64 %salt, 75
  br label %merge
case76:
  %value76 = add i64 %salt, 76
  br label %merge
case77:
  %value77 = add i64 %salt, 77
  br label %merge
case78:
  %value78 = add i64 %salt, 78
  br label %merge
case79:
  %value79 = add i64 %salt, 79
  br label %merge
case80:
  %value80 = add i64 %salt, 80
  br label %merge
case81:
  %value81 = add i64 %salt, 81
  br label %merge
case82:
  %value82 = add i64 %salt, 82
  br label %merge
case83:
  %value83 = add i64 %salt, 83
  br label %merge
case84:
  %value84 = add i64 %salt, 84
  br label %merge
case85:
  %value85 = add i64 %salt, 85
  br label %merge
case86:
  %value86 = add i64 %salt, 86
  br label %merge
case87:
  %value87 = add i64 %salt, 87
  br label %merge
case88:
  %value88 = add i64 %salt, 88
  br label %merge
case89:
  %value89 = add i64 %salt, 89
  br label %merge
case90:
  %value90 = add i64 %salt, 90
  br label %merge
case91:
  %value91 = add i64 %salt, 91
  br label %merge
case92:
  %value92 = add i64 %salt, 92
  br label %merge
case93:
  %value93 = add i64 %salt, 93
  br label %merge
case94:
  %value94 = add i64 %salt, 94
  br label %merge
case95:
  %value95 = add i64 %salt, 95
  br label %merge
case96:
  %value96 = add i64 %salt, 96
  br label %merge
case97:
  %value97 = add i64 %salt, 97
  br label %merge
case98:
  %value98 = add i64 %salt, 98
  br label %merge
case99:
  %value99 = add i64 %salt, 99
  br label %merge
case100:
  %value100 = add i64 %salt, 100
  br label %merge
case101:
  %value101 = add i64 %salt, 101
  br label %merge
case102:
  %value102 = add i64 %salt, 102
  br label %merge
case103:
  %value103 = add i64 %salt, 103
  br label %merge
case104:
  %value104 = add i64 %salt, 104
  br label %merge
case105:
  %value105 = add i64 %salt, 105
  br label %merge
case106:
  %value106 = add i64 %salt, 106
  br label %merge
case107:
  %value107 = add i64 %salt, 107
  br label %merge
case108:
  %value108 = add i64 %salt, 108
  br label %merge
case109:
  %value109 = add i64 %salt, 109
  br label %merge
case110:
  %value110 = add i64 %salt, 110
  br label %merge
case111:
  %value111 = add i64 %salt, 111
  br label %merge
case112:
  %value112 = add i64 %salt, 112
  br label %merge
case113:
  %value113 = add i64 %salt, 113
  br label %merge
case114:
  %value114 = add i64 %salt, 114
  br label %merge
case115:
  %value115 = add i64 %salt, 115
  br label %merge
case116:
  %value116 = add i64 %salt, 116
  br label %merge
case117:
  %value117 = add i64 %salt, 117
  br label %merge
case118:
  %value118 = add i64 %salt, 118
  br label %merge
case119:
  %value119 = add i64 %salt, 119
  br label %merge
case120:
  %value120 = add i64 %salt, 120
  br label %merge
case121:
  %value121 = add i64 %salt, 121
  br label %merge
case122:
  %value122 = add i64 %salt, 122
  br label %merge
case123:
  %value123 = add i64 %salt, 123
  br label %merge
case124:
  %value124 = add i64 %salt, 124
  br label %merge
case125:
  %value125 = add i64 %salt, 125
  br label %merge
case126:
  %value126 = add i64 %salt, 126
  br label %merge
merge:
  %result = phi i64 [ %default, %fallback ], [ %value0, %case0 ], [ %value1, %case1 ], [ %value2, %case2 ], [ %value3, %case3 ], [ %value4, %case4 ], [ %value5, %case5 ], [ %value6, %case6 ], [ %value7, %case7 ], [ %value8, %case8 ], [ %value9, %case9 ], [ %value10, %case10 ], [ %value11, %case11 ], [ %value12, %case12 ], [ %value13, %case13 ], [ %value14, %case14 ], [ %value15, %case15 ], [ %value16, %case16 ], [ %value17, %case17 ], [ %value18, %case18 ], [ %value19, %case19 ], [ %value20, %case20 ], [ %value21, %case21 ], [ %value22, %case22 ], [ %value23, %case23 ], [ %value24, %case24 ], [ %value25, %case25 ], [ %value26, %case26 ], [ %value27, %case27 ], [ %value28, %case28 ], [ %value29, %case29 ], [ %value30, %case30 ], [ %value31, %case31 ], [ %value32, %case32 ], [ %value33, %case33 ], [ %value34, %case34 ], [ %value35, %case35 ], [ %value36, %case36 ], [ %value37, %case37 ], [ %value38, %case38 ], [ %value39, %case39 ], [ %value40, %case40 ], [ %value41, %case41 ], [ %value42, %case42 ], [ %value43, %case43 ], [ %value44, %case44 ], [ %value45, %case45 ], [ %value46, %case46 ], [ %value47, %case47 ], [ %value48, %case48 ], [ %value49, %case49 ], [ %value50, %case50 ], [ %value51, %case51 ], [ %value52, %case52 ], [ %value53, %case53 ], [ %value54, %case54 ], [ %value55, %case55 ], [ %value56, %case56 ], [ %value57, %case57 ], [ %value58, %case58 ], [ %value59, %case59 ], [ %value60, %case60 ], [ %value61, %case61 ], [ %value62, %case62 ], [ %value63, %case63 ], [ %value64, %case64 ], [ %value65, %case65 ], [ %value66, %case66 ], [ %value67, %case67 ], [ %value68, %case68 ], [ %value69, %case69 ], [ %value70, %case70 ], [ %value71, %case71 ], [ %value72, %case72 ], [ %value73, %case73 ], [ %value74, %case74 ], [ %value75, %case75 ], [ %value76, %case76 ], [ %value77, %case77 ], [ %value78, %case78 ], [ %value79, %case79 ], [ %value80, %case80 ], [ %value81, %case81 ], [ %value82, %case82 ], [ %value83, %case83 ], [ %value84, %case84 ], [ %value85, %case85 ], [ %value86, %case86 ], [ %value87, %case87 ], [ %value88, %case88 ], [ %value89, %case89 ], [ %value90, %case90 ], [ %value91, %case91 ], [ %value92, %case92 ], [ %value93, %case93 ], [ %value94, %case94 ], [ %value95, %case95 ], [ %value96, %case96 ], [ %value97, %case97 ], [ %value98, %case98 ], [ %value99, %case99 ], [ %value100, %case100 ], [ %value101, %case101 ], [ %value102, %case102 ], [ %value103, %case103 ], [ %value104, %case104 ], [ %value105, %case105 ], [ %value106, %case106 ], [ %value107, %case107 ], [ %value108, %case108 ], [ %value109, %case109 ], [ %value110, %case110 ], [ %value111, %case111 ], [ %value112, %case112 ], [ %value113, %case113 ], [ %value114, %case114 ], [ %value115, %case115 ], [ %value116, %case116 ], [ %value117, %case117 ], [ %value118, %case118 ], [ %value119, %case119 ], [ %value120, %case120 ], [ %value121, %case121 ], [ %value122, %case122 ], [ %value123, %case123 ], [ %value124, %case124 ], [ %value125, %case125 ], [ %value126, %case126 ]
  store i64 %result, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %result
}


define i64 @cfg_129(i64 %input, i64 %salt, ptr %out) {
b0:
  %sum = add i64 %input, %salt
  br label %b1
b1:
  br label %b2
b2:
  br label %b3
b3:
  br label %b4
b4:
  br label %b5
b5:
  br label %b6
b6:
  br label %b7
b7:
  br label %b8
b8:
  br label %b9
b9:
  br label %b10
b10:
  br label %b11
b11:
  br label %b12
b12:
  br label %b13
b13:
  br label %b14
b14:
  br label %b15
b15:
  br label %b16
b16:
  br label %b17
b17:
  br label %b18
b18:
  br label %b19
b19:
  br label %b20
b20:
  br label %b21
b21:
  br label %b22
b22:
  br label %b23
b23:
  br label %b24
b24:
  br label %b25
b25:
  br label %b26
b26:
  br label %b27
b27:
  br label %b28
b28:
  br label %b29
b29:
  br label %b30
b30:
  br label %b31
b31:
  br label %b32
b32:
  br label %b33
b33:
  br label %b34
b34:
  br label %b35
b35:
  br label %b36
b36:
  br label %b37
b37:
  br label %b38
b38:
  br label %b39
b39:
  br label %b40
b40:
  br label %b41
b41:
  br label %b42
b42:
  br label %b43
b43:
  br label %b44
b44:
  br label %b45
b45:
  br label %b46
b46:
  br label %b47
b47:
  br label %b48
b48:
  br label %b49
b49:
  br label %b50
b50:
  br label %b51
b51:
  br label %b52
b52:
  br label %b53
b53:
  br label %b54
b54:
  br label %b55
b55:
  br label %b56
b56:
  br label %b57
b57:
  br label %b58
b58:
  br label %b59
b59:
  br label %b60
b60:
  br label %b61
b61:
  br label %b62
b62:
  br label %b63
b63:
  br label %b64
b64:
  br label %b65
b65:
  br label %b66
b66:
  br label %b67
b67:
  br label %b68
b68:
  br label %b69
b69:
  br label %b70
b70:
  br label %b71
b71:
  br label %b72
b72:
  br label %b73
b73:
  br label %b74
b74:
  br label %b75
b75:
  br label %b76
b76:
  br label %b77
b77:
  br label %b78
b78:
  br label %b79
b79:
  br label %b80
b80:
  br label %b81
b81:
  br label %b82
b82:
  br label %b83
b83:
  br label %b84
b84:
  br label %b85
b85:
  br label %b86
b86:
  br label %b87
b87:
  br label %b88
b88:
  br label %b89
b89:
  br label %b90
b90:
  br label %b91
b91:
  br label %b92
b92:
  br label %b93
b93:
  br label %b94
b94:
  br label %b95
b95:
  br label %b96
b96:
  br label %b97
b97:
  br label %b98
b98:
  br label %b99
b99:
  br label %b100
b100:
  br label %b101
b101:
  br label %b102
b102:
  br label %b103
b103:
  br label %b104
b104:
  br label %b105
b105:
  br label %b106
b106:
  br label %b107
b107:
  br label %b108
b108:
  br label %b109
b109:
  br label %b110
b110:
  br label %b111
b111:
  br label %b112
b112:
  br label %b113
b113:
  br label %b114
b114:
  br label %b115
b115:
  br label %b116
b116:
  br label %b117
b117:
  br label %b118
b118:
  br label %b119
b119:
  br label %b120
b120:
  br label %b121
b121:
  br label %b122
b122:
  br label %b123
b123:
  br label %b124
b124:
  br label %b125
b125:
  br label %b126
b126:
  br label %b127
b127:
  br label %b128
b128:
  %result = add i64 %sum, 129
  store i64 %result, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %result
}


define i64 @cfg_779(i64 %input, i64 %salt, ptr %out) {
b0:
  %sum = add i64 %input, %salt
  br label %b1
b1:
  br label %b2
b2:
  br label %b3
b3:
  br label %b4
b4:
  br label %b5
b5:
  br label %b6
b6:
  br label %b7
b7:
  br label %b8
b8:
  br label %b9
b9:
  br label %b10
b10:
  br label %b11
b11:
  br label %b12
b12:
  br label %b13
b13:
  br label %b14
b14:
  br label %b15
b15:
  br label %b16
b16:
  br label %b17
b17:
  br label %b18
b18:
  br label %b19
b19:
  br label %b20
b20:
  br label %b21
b21:
  br label %b22
b22:
  br label %b23
b23:
  br label %b24
b24:
  br label %b25
b25:
  br label %b26
b26:
  br label %b27
b27:
  br label %b28
b28:
  br label %b29
b29:
  br label %b30
b30:
  br label %b31
b31:
  br label %b32
b32:
  br label %b33
b33:
  br label %b34
b34:
  br label %b35
b35:
  br label %b36
b36:
  br label %b37
b37:
  br label %b38
b38:
  br label %b39
b39:
  br label %b40
b40:
  br label %b41
b41:
  br label %b42
b42:
  br label %b43
b43:
  br label %b44
b44:
  br label %b45
b45:
  br label %b46
b46:
  br label %b47
b47:
  br label %b48
b48:
  br label %b49
b49:
  br label %b50
b50:
  br label %b51
b51:
  br label %b52
b52:
  br label %b53
b53:
  br label %b54
b54:
  br label %b55
b55:
  br label %b56
b56:
  br label %b57
b57:
  br label %b58
b58:
  br label %b59
b59:
  br label %b60
b60:
  br label %b61
b61:
  br label %b62
b62:
  br label %b63
b63:
  br label %b64
b64:
  br label %b65
b65:
  br label %b66
b66:
  br label %b67
b67:
  br label %b68
b68:
  br label %b69
b69:
  br label %b70
b70:
  br label %b71
b71:
  br label %b72
b72:
  br label %b73
b73:
  br label %b74
b74:
  br label %b75
b75:
  br label %b76
b76:
  br label %b77
b77:
  br label %b78
b78:
  br label %b79
b79:
  br label %b80
b80:
  br label %b81
b81:
  br label %b82
b82:
  br label %b83
b83:
  br label %b84
b84:
  br label %b85
b85:
  br label %b86
b86:
  br label %b87
b87:
  br label %b88
b88:
  br label %b89
b89:
  br label %b90
b90:
  br label %b91
b91:
  br label %b92
b92:
  br label %b93
b93:
  br label %b94
b94:
  br label %b95
b95:
  br label %b96
b96:
  br label %b97
b97:
  br label %b98
b98:
  br label %b99
b99:
  br label %b100
b100:
  br label %b101
b101:
  br label %b102
b102:
  br label %b103
b103:
  br label %b104
b104:
  br label %b105
b105:
  br label %b106
b106:
  br label %b107
b107:
  br label %b108
b108:
  br label %b109
b109:
  br label %b110
b110:
  br label %b111
b111:
  br label %b112
b112:
  br label %b113
b113:
  br label %b114
b114:
  br label %b115
b115:
  br label %b116
b116:
  br label %b117
b117:
  br label %b118
b118:
  br label %b119
b119:
  br label %b120
b120:
  br label %b121
b121:
  br label %b122
b122:
  br label %b123
b123:
  br label %b124
b124:
  br label %b125
b125:
  br label %b126
b126:
  br label %b127
b127:
  br label %b128
b128:
  br label %b129
b129:
  br label %b130
b130:
  br label %b131
b131:
  br label %b132
b132:
  br label %b133
b133:
  br label %b134
b134:
  br label %b135
b135:
  br label %b136
b136:
  br label %b137
b137:
  br label %b138
b138:
  br label %b139
b139:
  br label %b140
b140:
  br label %b141
b141:
  br label %b142
b142:
  br label %b143
b143:
  br label %b144
b144:
  br label %b145
b145:
  br label %b146
b146:
  br label %b147
b147:
  br label %b148
b148:
  br label %b149
b149:
  br label %b150
b150:
  br label %b151
b151:
  br label %b152
b152:
  br label %b153
b153:
  br label %b154
b154:
  br label %b155
b155:
  br label %b156
b156:
  br label %b157
b157:
  br label %b158
b158:
  br label %b159
b159:
  br label %b160
b160:
  br label %b161
b161:
  br label %b162
b162:
  br label %b163
b163:
  br label %b164
b164:
  br label %b165
b165:
  br label %b166
b166:
  br label %b167
b167:
  br label %b168
b168:
  br label %b169
b169:
  br label %b170
b170:
  br label %b171
b171:
  br label %b172
b172:
  br label %b173
b173:
  br label %b174
b174:
  br label %b175
b175:
  br label %b176
b176:
  br label %b177
b177:
  br label %b178
b178:
  br label %b179
b179:
  br label %b180
b180:
  br label %b181
b181:
  br label %b182
b182:
  br label %b183
b183:
  br label %b184
b184:
  br label %b185
b185:
  br label %b186
b186:
  br label %b187
b187:
  br label %b188
b188:
  br label %b189
b189:
  br label %b190
b190:
  br label %b191
b191:
  br label %b192
b192:
  br label %b193
b193:
  br label %b194
b194:
  br label %b195
b195:
  br label %b196
b196:
  br label %b197
b197:
  br label %b198
b198:
  br label %b199
b199:
  br label %b200
b200:
  br label %b201
b201:
  br label %b202
b202:
  br label %b203
b203:
  br label %b204
b204:
  br label %b205
b205:
  br label %b206
b206:
  br label %b207
b207:
  br label %b208
b208:
  br label %b209
b209:
  br label %b210
b210:
  br label %b211
b211:
  br label %b212
b212:
  br label %b213
b213:
  br label %b214
b214:
  br label %b215
b215:
  br label %b216
b216:
  br label %b217
b217:
  br label %b218
b218:
  br label %b219
b219:
  br label %b220
b220:
  br label %b221
b221:
  br label %b222
b222:
  br label %b223
b223:
  br label %b224
b224:
  br label %b225
b225:
  br label %b226
b226:
  br label %b227
b227:
  br label %b228
b228:
  br label %b229
b229:
  br label %b230
b230:
  br label %b231
b231:
  br label %b232
b232:
  br label %b233
b233:
  br label %b234
b234:
  br label %b235
b235:
  br label %b236
b236:
  br label %b237
b237:
  br label %b238
b238:
  br label %b239
b239:
  br label %b240
b240:
  br label %b241
b241:
  br label %b242
b242:
  br label %b243
b243:
  br label %b244
b244:
  br label %b245
b245:
  br label %b246
b246:
  br label %b247
b247:
  br label %b248
b248:
  br label %b249
b249:
  br label %b250
b250:
  br label %b251
b251:
  br label %b252
b252:
  br label %b253
b253:
  br label %b254
b254:
  br label %b255
b255:
  br label %b256
b256:
  br label %b257
b257:
  br label %b258
b258:
  br label %b259
b259:
  br label %b260
b260:
  br label %b261
b261:
  br label %b262
b262:
  br label %b263
b263:
  br label %b264
b264:
  br label %b265
b265:
  br label %b266
b266:
  br label %b267
b267:
  br label %b268
b268:
  br label %b269
b269:
  br label %b270
b270:
  br label %b271
b271:
  br label %b272
b272:
  br label %b273
b273:
  br label %b274
b274:
  br label %b275
b275:
  br label %b276
b276:
  br label %b277
b277:
  br label %b278
b278:
  br label %b279
b279:
  br label %b280
b280:
  br label %b281
b281:
  br label %b282
b282:
  br label %b283
b283:
  br label %b284
b284:
  br label %b285
b285:
  br label %b286
b286:
  br label %b287
b287:
  br label %b288
b288:
  br label %b289
b289:
  br label %b290
b290:
  br label %b291
b291:
  br label %b292
b292:
  br label %b293
b293:
  br label %b294
b294:
  br label %b295
b295:
  br label %b296
b296:
  br label %b297
b297:
  br label %b298
b298:
  br label %b299
b299:
  br label %b300
b300:
  br label %b301
b301:
  br label %b302
b302:
  br label %b303
b303:
  br label %b304
b304:
  br label %b305
b305:
  br label %b306
b306:
  br label %b307
b307:
  br label %b308
b308:
  br label %b309
b309:
  br label %b310
b310:
  br label %b311
b311:
  br label %b312
b312:
  br label %b313
b313:
  br label %b314
b314:
  br label %b315
b315:
  br label %b316
b316:
  br label %b317
b317:
  br label %b318
b318:
  br label %b319
b319:
  br label %b320
b320:
  br label %b321
b321:
  br label %b322
b322:
  br label %b323
b323:
  br label %b324
b324:
  br label %b325
b325:
  br label %b326
b326:
  br label %b327
b327:
  br label %b328
b328:
  br label %b329
b329:
  br label %b330
b330:
  br label %b331
b331:
  br label %b332
b332:
  br label %b333
b333:
  br label %b334
b334:
  br label %b335
b335:
  br label %b336
b336:
  br label %b337
b337:
  br label %b338
b338:
  br label %b339
b339:
  br label %b340
b340:
  br label %b341
b341:
  br label %b342
b342:
  br label %b343
b343:
  br label %b344
b344:
  br label %b345
b345:
  br label %b346
b346:
  br label %b347
b347:
  br label %b348
b348:
  br label %b349
b349:
  br label %b350
b350:
  br label %b351
b351:
  br label %b352
b352:
  br label %b353
b353:
  br label %b354
b354:
  br label %b355
b355:
  br label %b356
b356:
  br label %b357
b357:
  br label %b358
b358:
  br label %b359
b359:
  br label %b360
b360:
  br label %b361
b361:
  br label %b362
b362:
  br label %b363
b363:
  br label %b364
b364:
  br label %b365
b365:
  br label %b366
b366:
  br label %b367
b367:
  br label %b368
b368:
  br label %b369
b369:
  br label %b370
b370:
  br label %b371
b371:
  br label %b372
b372:
  br label %b373
b373:
  br label %b374
b374:
  br label %b375
b375:
  br label %b376
b376:
  br label %b377
b377:
  br label %b378
b378:
  br label %b379
b379:
  br label %b380
b380:
  br label %b381
b381:
  br label %b382
b382:
  br label %b383
b383:
  br label %b384
b384:
  br label %b385
b385:
  br label %b386
b386:
  br label %b387
b387:
  br label %b388
b388:
  br label %b389
b389:
  br label %b390
b390:
  br label %b391
b391:
  br label %b392
b392:
  br label %b393
b393:
  br label %b394
b394:
  br label %b395
b395:
  br label %b396
b396:
  br label %b397
b397:
  br label %b398
b398:
  br label %b399
b399:
  br label %b400
b400:
  br label %b401
b401:
  br label %b402
b402:
  br label %b403
b403:
  br label %b404
b404:
  br label %b405
b405:
  br label %b406
b406:
  br label %b407
b407:
  br label %b408
b408:
  br label %b409
b409:
  br label %b410
b410:
  br label %b411
b411:
  br label %b412
b412:
  br label %b413
b413:
  br label %b414
b414:
  br label %b415
b415:
  br label %b416
b416:
  br label %b417
b417:
  br label %b418
b418:
  br label %b419
b419:
  br label %b420
b420:
  br label %b421
b421:
  br label %b422
b422:
  br label %b423
b423:
  br label %b424
b424:
  br label %b425
b425:
  br label %b426
b426:
  br label %b427
b427:
  br label %b428
b428:
  br label %b429
b429:
  br label %b430
b430:
  br label %b431
b431:
  br label %b432
b432:
  br label %b433
b433:
  br label %b434
b434:
  br label %b435
b435:
  br label %b436
b436:
  br label %b437
b437:
  br label %b438
b438:
  br label %b439
b439:
  br label %b440
b440:
  br label %b441
b441:
  br label %b442
b442:
  br label %b443
b443:
  br label %b444
b444:
  br label %b445
b445:
  br label %b446
b446:
  br label %b447
b447:
  br label %b448
b448:
  br label %b449
b449:
  br label %b450
b450:
  br label %b451
b451:
  br label %b452
b452:
  br label %b453
b453:
  br label %b454
b454:
  br label %b455
b455:
  br label %b456
b456:
  br label %b457
b457:
  br label %b458
b458:
  br label %b459
b459:
  br label %b460
b460:
  br label %b461
b461:
  br label %b462
b462:
  br label %b463
b463:
  br label %b464
b464:
  br label %b465
b465:
  br label %b466
b466:
  br label %b467
b467:
  br label %b468
b468:
  br label %b469
b469:
  br label %b470
b470:
  br label %b471
b471:
  br label %b472
b472:
  br label %b473
b473:
  br label %b474
b474:
  br label %b475
b475:
  br label %b476
b476:
  br label %b477
b477:
  br label %b478
b478:
  br label %b479
b479:
  br label %b480
b480:
  br label %b481
b481:
  br label %b482
b482:
  br label %b483
b483:
  br label %b484
b484:
  br label %b485
b485:
  br label %b486
b486:
  br label %b487
b487:
  br label %b488
b488:
  br label %b489
b489:
  br label %b490
b490:
  br label %b491
b491:
  br label %b492
b492:
  br label %b493
b493:
  br label %b494
b494:
  br label %b495
b495:
  br label %b496
b496:
  br label %b497
b497:
  br label %b498
b498:
  br label %b499
b499:
  br label %b500
b500:
  br label %b501
b501:
  br label %b502
b502:
  br label %b503
b503:
  br label %b504
b504:
  br label %b505
b505:
  br label %b506
b506:
  br label %b507
b507:
  br label %b508
b508:
  br label %b509
b509:
  br label %b510
b510:
  br label %b511
b511:
  br label %b512
b512:
  br label %b513
b513:
  br label %b514
b514:
  br label %b515
b515:
  br label %b516
b516:
  br label %b517
b517:
  br label %b518
b518:
  br label %b519
b519:
  br label %b520
b520:
  br label %b521
b521:
  br label %b522
b522:
  br label %b523
b523:
  br label %b524
b524:
  br label %b525
b525:
  br label %b526
b526:
  br label %b527
b527:
  br label %b528
b528:
  br label %b529
b529:
  br label %b530
b530:
  br label %b531
b531:
  br label %b532
b532:
  br label %b533
b533:
  br label %b534
b534:
  br label %b535
b535:
  br label %b536
b536:
  br label %b537
b537:
  br label %b538
b538:
  br label %b539
b539:
  br label %b540
b540:
  br label %b541
b541:
  br label %b542
b542:
  br label %b543
b543:
  br label %b544
b544:
  br label %b545
b545:
  br label %b546
b546:
  br label %b547
b547:
  br label %b548
b548:
  br label %b549
b549:
  br label %b550
b550:
  br label %b551
b551:
  br label %b552
b552:
  br label %b553
b553:
  br label %b554
b554:
  br label %b555
b555:
  br label %b556
b556:
  br label %b557
b557:
  br label %b558
b558:
  br label %b559
b559:
  br label %b560
b560:
  br label %b561
b561:
  br label %b562
b562:
  br label %b563
b563:
  br label %b564
b564:
  br label %b565
b565:
  br label %b566
b566:
  br label %b567
b567:
  br label %b568
b568:
  br label %b569
b569:
  br label %b570
b570:
  br label %b571
b571:
  br label %b572
b572:
  br label %b573
b573:
  br label %b574
b574:
  br label %b575
b575:
  br label %b576
b576:
  br label %b577
b577:
  br label %b578
b578:
  br label %b579
b579:
  br label %b580
b580:
  br label %b581
b581:
  br label %b582
b582:
  br label %b583
b583:
  br label %b584
b584:
  br label %b585
b585:
  br label %b586
b586:
  br label %b587
b587:
  br label %b588
b588:
  br label %b589
b589:
  br label %b590
b590:
  br label %b591
b591:
  br label %b592
b592:
  br label %b593
b593:
  br label %b594
b594:
  br label %b595
b595:
  br label %b596
b596:
  br label %b597
b597:
  br label %b598
b598:
  br label %b599
b599:
  br label %b600
b600:
  br label %b601
b601:
  br label %b602
b602:
  br label %b603
b603:
  br label %b604
b604:
  br label %b605
b605:
  br label %b606
b606:
  br label %b607
b607:
  br label %b608
b608:
  br label %b609
b609:
  br label %b610
b610:
  br label %b611
b611:
  br label %b612
b612:
  br label %b613
b613:
  br label %b614
b614:
  br label %b615
b615:
  br label %b616
b616:
  br label %b617
b617:
  br label %b618
b618:
  br label %b619
b619:
  br label %b620
b620:
  br label %b621
b621:
  br label %b622
b622:
  br label %b623
b623:
  br label %b624
b624:
  br label %b625
b625:
  br label %b626
b626:
  br label %b627
b627:
  br label %b628
b628:
  br label %b629
b629:
  br label %b630
b630:
  br label %b631
b631:
  br label %b632
b632:
  br label %b633
b633:
  br label %b634
b634:
  br label %b635
b635:
  br label %b636
b636:
  br label %b637
b637:
  br label %b638
b638:
  br label %b639
b639:
  br label %b640
b640:
  br label %b641
b641:
  br label %b642
b642:
  br label %b643
b643:
  br label %b644
b644:
  br label %b645
b645:
  br label %b646
b646:
  br label %b647
b647:
  br label %b648
b648:
  br label %b649
b649:
  br label %b650
b650:
  br label %b651
b651:
  br label %b652
b652:
  br label %b653
b653:
  br label %b654
b654:
  br label %b655
b655:
  br label %b656
b656:
  br label %b657
b657:
  br label %b658
b658:
  br label %b659
b659:
  br label %b660
b660:
  br label %b661
b661:
  br label %b662
b662:
  br label %b663
b663:
  br label %b664
b664:
  br label %b665
b665:
  br label %b666
b666:
  br label %b667
b667:
  br label %b668
b668:
  br label %b669
b669:
  br label %b670
b670:
  br label %b671
b671:
  br label %b672
b672:
  br label %b673
b673:
  br label %b674
b674:
  br label %b675
b675:
  br label %b676
b676:
  br label %b677
b677:
  br label %b678
b678:
  br label %b679
b679:
  br label %b680
b680:
  br label %b681
b681:
  br label %b682
b682:
  br label %b683
b683:
  br label %b684
b684:
  br label %b685
b685:
  br label %b686
b686:
  br label %b687
b687:
  br label %b688
b688:
  br label %b689
b689:
  br label %b690
b690:
  br label %b691
b691:
  br label %b692
b692:
  br label %b693
b693:
  br label %b694
b694:
  br label %b695
b695:
  br label %b696
b696:
  br label %b697
b697:
  br label %b698
b698:
  br label %b699
b699:
  br label %b700
b700:
  br label %b701
b701:
  br label %b702
b702:
  br label %b703
b703:
  br label %b704
b704:
  br label %b705
b705:
  br label %b706
b706:
  br label %b707
b707:
  br label %b708
b708:
  br label %b709
b709:
  br label %b710
b710:
  br label %b711
b711:
  br label %b712
b712:
  br label %b713
b713:
  br label %b714
b714:
  br label %b715
b715:
  br label %b716
b716:
  br label %b717
b717:
  br label %b718
b718:
  br label %b719
b719:
  br label %b720
b720:
  br label %b721
b721:
  br label %b722
b722:
  br label %b723
b723:
  br label %b724
b724:
  br label %b725
b725:
  br label %b726
b726:
  br label %b727
b727:
  br label %b728
b728:
  br label %b729
b729:
  br label %b730
b730:
  br label %b731
b731:
  br label %b732
b732:
  br label %b733
b733:
  br label %b734
b734:
  br label %b735
b735:
  br label %b736
b736:
  br label %b737
b737:
  br label %b738
b738:
  br label %b739
b739:
  br label %b740
b740:
  br label %b741
b741:
  br label %b742
b742:
  br label %b743
b743:
  br label %b744
b744:
  br label %b745
b745:
  br label %b746
b746:
  br label %b747
b747:
  br label %b748
b748:
  br label %b749
b749:
  br label %b750
b750:
  br label %b751
b751:
  br label %b752
b752:
  br label %b753
b753:
  br label %b754
b754:
  br label %b755
b755:
  br label %b756
b756:
  br label %b757
b757:
  br label %b758
b758:
  br label %b759
b759:
  br label %b760
b760:
  br label %b761
b761:
  br label %b762
b762:
  br label %b763
b763:
  br label %b764
b764:
  br label %b765
b765:
  br label %b766
b766:
  br label %b767
b767:
  br label %b768
b768:
  br label %b769
b769:
  br label %b770
b770:
  br label %b771
b771:
  br label %b772
b772:
  br label %b773
b773:
  br label %b774
b774:
  br label %b775
b775:
  br label %b776
b776:
  br label %b777
b777:
  br label %b778
b778:
  %result = add i64 %sum, 779
  store i64 %result, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %result
}


define i64 @cfg_1024(i64 %input, i64 %salt, ptr %out) {
b0:
  %sum = add i64 %input, %salt
  br label %b1
b1:
  br label %b2
b2:
  br label %b3
b3:
  br label %b4
b4:
  br label %b5
b5:
  br label %b6
b6:
  br label %b7
b7:
  br label %b8
b8:
  br label %b9
b9:
  br label %b10
b10:
  br label %b11
b11:
  br label %b12
b12:
  br label %b13
b13:
  br label %b14
b14:
  br label %b15
b15:
  br label %b16
b16:
  br label %b17
b17:
  br label %b18
b18:
  br label %b19
b19:
  br label %b20
b20:
  br label %b21
b21:
  br label %b22
b22:
  br label %b23
b23:
  br label %b24
b24:
  br label %b25
b25:
  br label %b26
b26:
  br label %b27
b27:
  br label %b28
b28:
  br label %b29
b29:
  br label %b30
b30:
  br label %b31
b31:
  br label %b32
b32:
  br label %b33
b33:
  br label %b34
b34:
  br label %b35
b35:
  br label %b36
b36:
  br label %b37
b37:
  br label %b38
b38:
  br label %b39
b39:
  br label %b40
b40:
  br label %b41
b41:
  br label %b42
b42:
  br label %b43
b43:
  br label %b44
b44:
  br label %b45
b45:
  br label %b46
b46:
  br label %b47
b47:
  br label %b48
b48:
  br label %b49
b49:
  br label %b50
b50:
  br label %b51
b51:
  br label %b52
b52:
  br label %b53
b53:
  br label %b54
b54:
  br label %b55
b55:
  br label %b56
b56:
  br label %b57
b57:
  br label %b58
b58:
  br label %b59
b59:
  br label %b60
b60:
  br label %b61
b61:
  br label %b62
b62:
  br label %b63
b63:
  br label %b64
b64:
  br label %b65
b65:
  br label %b66
b66:
  br label %b67
b67:
  br label %b68
b68:
  br label %b69
b69:
  br label %b70
b70:
  br label %b71
b71:
  br label %b72
b72:
  br label %b73
b73:
  br label %b74
b74:
  br label %b75
b75:
  br label %b76
b76:
  br label %b77
b77:
  br label %b78
b78:
  br label %b79
b79:
  br label %b80
b80:
  br label %b81
b81:
  br label %b82
b82:
  br label %b83
b83:
  br label %b84
b84:
  br label %b85
b85:
  br label %b86
b86:
  br label %b87
b87:
  br label %b88
b88:
  br label %b89
b89:
  br label %b90
b90:
  br label %b91
b91:
  br label %b92
b92:
  br label %b93
b93:
  br label %b94
b94:
  br label %b95
b95:
  br label %b96
b96:
  br label %b97
b97:
  br label %b98
b98:
  br label %b99
b99:
  br label %b100
b100:
  br label %b101
b101:
  br label %b102
b102:
  br label %b103
b103:
  br label %b104
b104:
  br label %b105
b105:
  br label %b106
b106:
  br label %b107
b107:
  br label %b108
b108:
  br label %b109
b109:
  br label %b110
b110:
  br label %b111
b111:
  br label %b112
b112:
  br label %b113
b113:
  br label %b114
b114:
  br label %b115
b115:
  br label %b116
b116:
  br label %b117
b117:
  br label %b118
b118:
  br label %b119
b119:
  br label %b120
b120:
  br label %b121
b121:
  br label %b122
b122:
  br label %b123
b123:
  br label %b124
b124:
  br label %b125
b125:
  br label %b126
b126:
  br label %b127
b127:
  br label %b128
b128:
  br label %b129
b129:
  br label %b130
b130:
  br label %b131
b131:
  br label %b132
b132:
  br label %b133
b133:
  br label %b134
b134:
  br label %b135
b135:
  br label %b136
b136:
  br label %b137
b137:
  br label %b138
b138:
  br label %b139
b139:
  br label %b140
b140:
  br label %b141
b141:
  br label %b142
b142:
  br label %b143
b143:
  br label %b144
b144:
  br label %b145
b145:
  br label %b146
b146:
  br label %b147
b147:
  br label %b148
b148:
  br label %b149
b149:
  br label %b150
b150:
  br label %b151
b151:
  br label %b152
b152:
  br label %b153
b153:
  br label %b154
b154:
  br label %b155
b155:
  br label %b156
b156:
  br label %b157
b157:
  br label %b158
b158:
  br label %b159
b159:
  br label %b160
b160:
  br label %b161
b161:
  br label %b162
b162:
  br label %b163
b163:
  br label %b164
b164:
  br label %b165
b165:
  br label %b166
b166:
  br label %b167
b167:
  br label %b168
b168:
  br label %b169
b169:
  br label %b170
b170:
  br label %b171
b171:
  br label %b172
b172:
  br label %b173
b173:
  br label %b174
b174:
  br label %b175
b175:
  br label %b176
b176:
  br label %b177
b177:
  br label %b178
b178:
  br label %b179
b179:
  br label %b180
b180:
  br label %b181
b181:
  br label %b182
b182:
  br label %b183
b183:
  br label %b184
b184:
  br label %b185
b185:
  br label %b186
b186:
  br label %b187
b187:
  br label %b188
b188:
  br label %b189
b189:
  br label %b190
b190:
  br label %b191
b191:
  br label %b192
b192:
  br label %b193
b193:
  br label %b194
b194:
  br label %b195
b195:
  br label %b196
b196:
  br label %b197
b197:
  br label %b198
b198:
  br label %b199
b199:
  br label %b200
b200:
  br label %b201
b201:
  br label %b202
b202:
  br label %b203
b203:
  br label %b204
b204:
  br label %b205
b205:
  br label %b206
b206:
  br label %b207
b207:
  br label %b208
b208:
  br label %b209
b209:
  br label %b210
b210:
  br label %b211
b211:
  br label %b212
b212:
  br label %b213
b213:
  br label %b214
b214:
  br label %b215
b215:
  br label %b216
b216:
  br label %b217
b217:
  br label %b218
b218:
  br label %b219
b219:
  br label %b220
b220:
  br label %b221
b221:
  br label %b222
b222:
  br label %b223
b223:
  br label %b224
b224:
  br label %b225
b225:
  br label %b226
b226:
  br label %b227
b227:
  br label %b228
b228:
  br label %b229
b229:
  br label %b230
b230:
  br label %b231
b231:
  br label %b232
b232:
  br label %b233
b233:
  br label %b234
b234:
  br label %b235
b235:
  br label %b236
b236:
  br label %b237
b237:
  br label %b238
b238:
  br label %b239
b239:
  br label %b240
b240:
  br label %b241
b241:
  br label %b242
b242:
  br label %b243
b243:
  br label %b244
b244:
  br label %b245
b245:
  br label %b246
b246:
  br label %b247
b247:
  br label %b248
b248:
  br label %b249
b249:
  br label %b250
b250:
  br label %b251
b251:
  br label %b252
b252:
  br label %b253
b253:
  br label %b254
b254:
  br label %b255
b255:
  br label %b256
b256:
  br label %b257
b257:
  br label %b258
b258:
  br label %b259
b259:
  br label %b260
b260:
  br label %b261
b261:
  br label %b262
b262:
  br label %b263
b263:
  br label %b264
b264:
  br label %b265
b265:
  br label %b266
b266:
  br label %b267
b267:
  br label %b268
b268:
  br label %b269
b269:
  br label %b270
b270:
  br label %b271
b271:
  br label %b272
b272:
  br label %b273
b273:
  br label %b274
b274:
  br label %b275
b275:
  br label %b276
b276:
  br label %b277
b277:
  br label %b278
b278:
  br label %b279
b279:
  br label %b280
b280:
  br label %b281
b281:
  br label %b282
b282:
  br label %b283
b283:
  br label %b284
b284:
  br label %b285
b285:
  br label %b286
b286:
  br label %b287
b287:
  br label %b288
b288:
  br label %b289
b289:
  br label %b290
b290:
  br label %b291
b291:
  br label %b292
b292:
  br label %b293
b293:
  br label %b294
b294:
  br label %b295
b295:
  br label %b296
b296:
  br label %b297
b297:
  br label %b298
b298:
  br label %b299
b299:
  br label %b300
b300:
  br label %b301
b301:
  br label %b302
b302:
  br label %b303
b303:
  br label %b304
b304:
  br label %b305
b305:
  br label %b306
b306:
  br label %b307
b307:
  br label %b308
b308:
  br label %b309
b309:
  br label %b310
b310:
  br label %b311
b311:
  br label %b312
b312:
  br label %b313
b313:
  br label %b314
b314:
  br label %b315
b315:
  br label %b316
b316:
  br label %b317
b317:
  br label %b318
b318:
  br label %b319
b319:
  br label %b320
b320:
  br label %b321
b321:
  br label %b322
b322:
  br label %b323
b323:
  br label %b324
b324:
  br label %b325
b325:
  br label %b326
b326:
  br label %b327
b327:
  br label %b328
b328:
  br label %b329
b329:
  br label %b330
b330:
  br label %b331
b331:
  br label %b332
b332:
  br label %b333
b333:
  br label %b334
b334:
  br label %b335
b335:
  br label %b336
b336:
  br label %b337
b337:
  br label %b338
b338:
  br label %b339
b339:
  br label %b340
b340:
  br label %b341
b341:
  br label %b342
b342:
  br label %b343
b343:
  br label %b344
b344:
  br label %b345
b345:
  br label %b346
b346:
  br label %b347
b347:
  br label %b348
b348:
  br label %b349
b349:
  br label %b350
b350:
  br label %b351
b351:
  br label %b352
b352:
  br label %b353
b353:
  br label %b354
b354:
  br label %b355
b355:
  br label %b356
b356:
  br label %b357
b357:
  br label %b358
b358:
  br label %b359
b359:
  br label %b360
b360:
  br label %b361
b361:
  br label %b362
b362:
  br label %b363
b363:
  br label %b364
b364:
  br label %b365
b365:
  br label %b366
b366:
  br label %b367
b367:
  br label %b368
b368:
  br label %b369
b369:
  br label %b370
b370:
  br label %b371
b371:
  br label %b372
b372:
  br label %b373
b373:
  br label %b374
b374:
  br label %b375
b375:
  br label %b376
b376:
  br label %b377
b377:
  br label %b378
b378:
  br label %b379
b379:
  br label %b380
b380:
  br label %b381
b381:
  br label %b382
b382:
  br label %b383
b383:
  br label %b384
b384:
  br label %b385
b385:
  br label %b386
b386:
  br label %b387
b387:
  br label %b388
b388:
  br label %b389
b389:
  br label %b390
b390:
  br label %b391
b391:
  br label %b392
b392:
  br label %b393
b393:
  br label %b394
b394:
  br label %b395
b395:
  br label %b396
b396:
  br label %b397
b397:
  br label %b398
b398:
  br label %b399
b399:
  br label %b400
b400:
  br label %b401
b401:
  br label %b402
b402:
  br label %b403
b403:
  br label %b404
b404:
  br label %b405
b405:
  br label %b406
b406:
  br label %b407
b407:
  br label %b408
b408:
  br label %b409
b409:
  br label %b410
b410:
  br label %b411
b411:
  br label %b412
b412:
  br label %b413
b413:
  br label %b414
b414:
  br label %b415
b415:
  br label %b416
b416:
  br label %b417
b417:
  br label %b418
b418:
  br label %b419
b419:
  br label %b420
b420:
  br label %b421
b421:
  br label %b422
b422:
  br label %b423
b423:
  br label %b424
b424:
  br label %b425
b425:
  br label %b426
b426:
  br label %b427
b427:
  br label %b428
b428:
  br label %b429
b429:
  br label %b430
b430:
  br label %b431
b431:
  br label %b432
b432:
  br label %b433
b433:
  br label %b434
b434:
  br label %b435
b435:
  br label %b436
b436:
  br label %b437
b437:
  br label %b438
b438:
  br label %b439
b439:
  br label %b440
b440:
  br label %b441
b441:
  br label %b442
b442:
  br label %b443
b443:
  br label %b444
b444:
  br label %b445
b445:
  br label %b446
b446:
  br label %b447
b447:
  br label %b448
b448:
  br label %b449
b449:
  br label %b450
b450:
  br label %b451
b451:
  br label %b452
b452:
  br label %b453
b453:
  br label %b454
b454:
  br label %b455
b455:
  br label %b456
b456:
  br label %b457
b457:
  br label %b458
b458:
  br label %b459
b459:
  br label %b460
b460:
  br label %b461
b461:
  br label %b462
b462:
  br label %b463
b463:
  br label %b464
b464:
  br label %b465
b465:
  br label %b466
b466:
  br label %b467
b467:
  br label %b468
b468:
  br label %b469
b469:
  br label %b470
b470:
  br label %b471
b471:
  br label %b472
b472:
  br label %b473
b473:
  br label %b474
b474:
  br label %b475
b475:
  br label %b476
b476:
  br label %b477
b477:
  br label %b478
b478:
  br label %b479
b479:
  br label %b480
b480:
  br label %b481
b481:
  br label %b482
b482:
  br label %b483
b483:
  br label %b484
b484:
  br label %b485
b485:
  br label %b486
b486:
  br label %b487
b487:
  br label %b488
b488:
  br label %b489
b489:
  br label %b490
b490:
  br label %b491
b491:
  br label %b492
b492:
  br label %b493
b493:
  br label %b494
b494:
  br label %b495
b495:
  br label %b496
b496:
  br label %b497
b497:
  br label %b498
b498:
  br label %b499
b499:
  br label %b500
b500:
  br label %b501
b501:
  br label %b502
b502:
  br label %b503
b503:
  br label %b504
b504:
  br label %b505
b505:
  br label %b506
b506:
  br label %b507
b507:
  br label %b508
b508:
  br label %b509
b509:
  br label %b510
b510:
  br label %b511
b511:
  br label %b512
b512:
  br label %b513
b513:
  br label %b514
b514:
  br label %b515
b515:
  br label %b516
b516:
  br label %b517
b517:
  br label %b518
b518:
  br label %b519
b519:
  br label %b520
b520:
  br label %b521
b521:
  br label %b522
b522:
  br label %b523
b523:
  br label %b524
b524:
  br label %b525
b525:
  br label %b526
b526:
  br label %b527
b527:
  br label %b528
b528:
  br label %b529
b529:
  br label %b530
b530:
  br label %b531
b531:
  br label %b532
b532:
  br label %b533
b533:
  br label %b534
b534:
  br label %b535
b535:
  br label %b536
b536:
  br label %b537
b537:
  br label %b538
b538:
  br label %b539
b539:
  br label %b540
b540:
  br label %b541
b541:
  br label %b542
b542:
  br label %b543
b543:
  br label %b544
b544:
  br label %b545
b545:
  br label %b546
b546:
  br label %b547
b547:
  br label %b548
b548:
  br label %b549
b549:
  br label %b550
b550:
  br label %b551
b551:
  br label %b552
b552:
  br label %b553
b553:
  br label %b554
b554:
  br label %b555
b555:
  br label %b556
b556:
  br label %b557
b557:
  br label %b558
b558:
  br label %b559
b559:
  br label %b560
b560:
  br label %b561
b561:
  br label %b562
b562:
  br label %b563
b563:
  br label %b564
b564:
  br label %b565
b565:
  br label %b566
b566:
  br label %b567
b567:
  br label %b568
b568:
  br label %b569
b569:
  br label %b570
b570:
  br label %b571
b571:
  br label %b572
b572:
  br label %b573
b573:
  br label %b574
b574:
  br label %b575
b575:
  br label %b576
b576:
  br label %b577
b577:
  br label %b578
b578:
  br label %b579
b579:
  br label %b580
b580:
  br label %b581
b581:
  br label %b582
b582:
  br label %b583
b583:
  br label %b584
b584:
  br label %b585
b585:
  br label %b586
b586:
  br label %b587
b587:
  br label %b588
b588:
  br label %b589
b589:
  br label %b590
b590:
  br label %b591
b591:
  br label %b592
b592:
  br label %b593
b593:
  br label %b594
b594:
  br label %b595
b595:
  br label %b596
b596:
  br label %b597
b597:
  br label %b598
b598:
  br label %b599
b599:
  br label %b600
b600:
  br label %b601
b601:
  br label %b602
b602:
  br label %b603
b603:
  br label %b604
b604:
  br label %b605
b605:
  br label %b606
b606:
  br label %b607
b607:
  br label %b608
b608:
  br label %b609
b609:
  br label %b610
b610:
  br label %b611
b611:
  br label %b612
b612:
  br label %b613
b613:
  br label %b614
b614:
  br label %b615
b615:
  br label %b616
b616:
  br label %b617
b617:
  br label %b618
b618:
  br label %b619
b619:
  br label %b620
b620:
  br label %b621
b621:
  br label %b622
b622:
  br label %b623
b623:
  br label %b624
b624:
  br label %b625
b625:
  br label %b626
b626:
  br label %b627
b627:
  br label %b628
b628:
  br label %b629
b629:
  br label %b630
b630:
  br label %b631
b631:
  br label %b632
b632:
  br label %b633
b633:
  br label %b634
b634:
  br label %b635
b635:
  br label %b636
b636:
  br label %b637
b637:
  br label %b638
b638:
  br label %b639
b639:
  br label %b640
b640:
  br label %b641
b641:
  br label %b642
b642:
  br label %b643
b643:
  br label %b644
b644:
  br label %b645
b645:
  br label %b646
b646:
  br label %b647
b647:
  br label %b648
b648:
  br label %b649
b649:
  br label %b650
b650:
  br label %b651
b651:
  br label %b652
b652:
  br label %b653
b653:
  br label %b654
b654:
  br label %b655
b655:
  br label %b656
b656:
  br label %b657
b657:
  br label %b658
b658:
  br label %b659
b659:
  br label %b660
b660:
  br label %b661
b661:
  br label %b662
b662:
  br label %b663
b663:
  br label %b664
b664:
  br label %b665
b665:
  br label %b666
b666:
  br label %b667
b667:
  br label %b668
b668:
  br label %b669
b669:
  br label %b670
b670:
  br label %b671
b671:
  br label %b672
b672:
  br label %b673
b673:
  br label %b674
b674:
  br label %b675
b675:
  br label %b676
b676:
  br label %b677
b677:
  br label %b678
b678:
  br label %b679
b679:
  br label %b680
b680:
  br label %b681
b681:
  br label %b682
b682:
  br label %b683
b683:
  br label %b684
b684:
  br label %b685
b685:
  br label %b686
b686:
  br label %b687
b687:
  br label %b688
b688:
  br label %b689
b689:
  br label %b690
b690:
  br label %b691
b691:
  br label %b692
b692:
  br label %b693
b693:
  br label %b694
b694:
  br label %b695
b695:
  br label %b696
b696:
  br label %b697
b697:
  br label %b698
b698:
  br label %b699
b699:
  br label %b700
b700:
  br label %b701
b701:
  br label %b702
b702:
  br label %b703
b703:
  br label %b704
b704:
  br label %b705
b705:
  br label %b706
b706:
  br label %b707
b707:
  br label %b708
b708:
  br label %b709
b709:
  br label %b710
b710:
  br label %b711
b711:
  br label %b712
b712:
  br label %b713
b713:
  br label %b714
b714:
  br label %b715
b715:
  br label %b716
b716:
  br label %b717
b717:
  br label %b718
b718:
  br label %b719
b719:
  br label %b720
b720:
  br label %b721
b721:
  br label %b722
b722:
  br label %b723
b723:
  br label %b724
b724:
  br label %b725
b725:
  br label %b726
b726:
  br label %b727
b727:
  br label %b728
b728:
  br label %b729
b729:
  br label %b730
b730:
  br label %b731
b731:
  br label %b732
b732:
  br label %b733
b733:
  br label %b734
b734:
  br label %b735
b735:
  br label %b736
b736:
  br label %b737
b737:
  br label %b738
b738:
  br label %b739
b739:
  br label %b740
b740:
  br label %b741
b741:
  br label %b742
b742:
  br label %b743
b743:
  br label %b744
b744:
  br label %b745
b745:
  br label %b746
b746:
  br label %b747
b747:
  br label %b748
b748:
  br label %b749
b749:
  br label %b750
b750:
  br label %b751
b751:
  br label %b752
b752:
  br label %b753
b753:
  br label %b754
b754:
  br label %b755
b755:
  br label %b756
b756:
  br label %b757
b757:
  br label %b758
b758:
  br label %b759
b759:
  br label %b760
b760:
  br label %b761
b761:
  br label %b762
b762:
  br label %b763
b763:
  br label %b764
b764:
  br label %b765
b765:
  br label %b766
b766:
  br label %b767
b767:
  br label %b768
b768:
  br label %b769
b769:
  br label %b770
b770:
  br label %b771
b771:
  br label %b772
b772:
  br label %b773
b773:
  br label %b774
b774:
  br label %b775
b775:
  br label %b776
b776:
  br label %b777
b777:
  br label %b778
b778:
  br label %b779
b779:
  br label %b780
b780:
  br label %b781
b781:
  br label %b782
b782:
  br label %b783
b783:
  br label %b784
b784:
  br label %b785
b785:
  br label %b786
b786:
  br label %b787
b787:
  br label %b788
b788:
  br label %b789
b789:
  br label %b790
b790:
  br label %b791
b791:
  br label %b792
b792:
  br label %b793
b793:
  br label %b794
b794:
  br label %b795
b795:
  br label %b796
b796:
  br label %b797
b797:
  br label %b798
b798:
  br label %b799
b799:
  br label %b800
b800:
  br label %b801
b801:
  br label %b802
b802:
  br label %b803
b803:
  br label %b804
b804:
  br label %b805
b805:
  br label %b806
b806:
  br label %b807
b807:
  br label %b808
b808:
  br label %b809
b809:
  br label %b810
b810:
  br label %b811
b811:
  br label %b812
b812:
  br label %b813
b813:
  br label %b814
b814:
  br label %b815
b815:
  br label %b816
b816:
  br label %b817
b817:
  br label %b818
b818:
  br label %b819
b819:
  br label %b820
b820:
  br label %b821
b821:
  br label %b822
b822:
  br label %b823
b823:
  br label %b824
b824:
  br label %b825
b825:
  br label %b826
b826:
  br label %b827
b827:
  br label %b828
b828:
  br label %b829
b829:
  br label %b830
b830:
  br label %b831
b831:
  br label %b832
b832:
  br label %b833
b833:
  br label %b834
b834:
  br label %b835
b835:
  br label %b836
b836:
  br label %b837
b837:
  br label %b838
b838:
  br label %b839
b839:
  br label %b840
b840:
  br label %b841
b841:
  br label %b842
b842:
  br label %b843
b843:
  br label %b844
b844:
  br label %b845
b845:
  br label %b846
b846:
  br label %b847
b847:
  br label %b848
b848:
  br label %b849
b849:
  br label %b850
b850:
  br label %b851
b851:
  br label %b852
b852:
  br label %b853
b853:
  br label %b854
b854:
  br label %b855
b855:
  br label %b856
b856:
  br label %b857
b857:
  br label %b858
b858:
  br label %b859
b859:
  br label %b860
b860:
  br label %b861
b861:
  br label %b862
b862:
  br label %b863
b863:
  br label %b864
b864:
  br label %b865
b865:
  br label %b866
b866:
  br label %b867
b867:
  br label %b868
b868:
  br label %b869
b869:
  br label %b870
b870:
  br label %b871
b871:
  br label %b872
b872:
  br label %b873
b873:
  br label %b874
b874:
  br label %b875
b875:
  br label %b876
b876:
  br label %b877
b877:
  br label %b878
b878:
  br label %b879
b879:
  br label %b880
b880:
  br label %b881
b881:
  br label %b882
b882:
  br label %b883
b883:
  br label %b884
b884:
  br label %b885
b885:
  br label %b886
b886:
  br label %b887
b887:
  br label %b888
b888:
  br label %b889
b889:
  br label %b890
b890:
  br label %b891
b891:
  br label %b892
b892:
  br label %b893
b893:
  br label %b894
b894:
  br label %b895
b895:
  br label %b896
b896:
  br label %b897
b897:
  br label %b898
b898:
  br label %b899
b899:
  br label %b900
b900:
  br label %b901
b901:
  br label %b902
b902:
  br label %b903
b903:
  br label %b904
b904:
  br label %b905
b905:
  br label %b906
b906:
  br label %b907
b907:
  br label %b908
b908:
  br label %b909
b909:
  br label %b910
b910:
  br label %b911
b911:
  br label %b912
b912:
  br label %b913
b913:
  br label %b914
b914:
  br label %b915
b915:
  br label %b916
b916:
  br label %b917
b917:
  br label %b918
b918:
  br label %b919
b919:
  br label %b920
b920:
  br label %b921
b921:
  br label %b922
b922:
  br label %b923
b923:
  br label %b924
b924:
  br label %b925
b925:
  br label %b926
b926:
  br label %b927
b927:
  br label %b928
b928:
  br label %b929
b929:
  br label %b930
b930:
  br label %b931
b931:
  br label %b932
b932:
  br label %b933
b933:
  br label %b934
b934:
  br label %b935
b935:
  br label %b936
b936:
  br label %b937
b937:
  br label %b938
b938:
  br label %b939
b939:
  br label %b940
b940:
  br label %b941
b941:
  br label %b942
b942:
  br label %b943
b943:
  br label %b944
b944:
  br label %b945
b945:
  br label %b946
b946:
  br label %b947
b947:
  br label %b948
b948:
  br label %b949
b949:
  br label %b950
b950:
  br label %b951
b951:
  br label %b952
b952:
  br label %b953
b953:
  br label %b954
b954:
  br label %b955
b955:
  br label %b956
b956:
  br label %b957
b957:
  br label %b958
b958:
  br label %b959
b959:
  br label %b960
b960:
  br label %b961
b961:
  br label %b962
b962:
  br label %b963
b963:
  br label %b964
b964:
  br label %b965
b965:
  br label %b966
b966:
  br label %b967
b967:
  br label %b968
b968:
  br label %b969
b969:
  br label %b970
b970:
  br label %b971
b971:
  br label %b972
b972:
  br label %b973
b973:
  br label %b974
b974:
  br label %b975
b975:
  br label %b976
b976:
  br label %b977
b977:
  br label %b978
b978:
  br label %b979
b979:
  br label %b980
b980:
  br label %b981
b981:
  br label %b982
b982:
  br label %b983
b983:
  br label %b984
b984:
  br label %b985
b985:
  br label %b986
b986:
  br label %b987
b987:
  br label %b988
b988:
  br label %b989
b989:
  br label %b990
b990:
  br label %b991
b991:
  br label %b992
b992:
  br label %b993
b993:
  br label %b994
b994:
  br label %b995
b995:
  br label %b996
b996:
  br label %b997
b997:
  br label %b998
b998:
  br label %b999
b999:
  br label %b1000
b1000:
  br label %b1001
b1001:
  br label %b1002
b1002:
  br label %b1003
b1003:
  br label %b1004
b1004:
  br label %b1005
b1005:
  br label %b1006
b1006:
  br label %b1007
b1007:
  br label %b1008
b1008:
  br label %b1009
b1009:
  br label %b1010
b1010:
  br label %b1011
b1011:
  br label %b1012
b1012:
  br label %b1013
b1013:
  br label %b1014
b1014:
  br label %b1015
b1015:
  br label %b1016
b1016:
  br label %b1017
b1017:
  br label %b1018
b1018:
  br label %b1019
b1019:
  br label %b1020
b1020:
  br label %b1021
b1021:
  br label %b1022
b1022:
  br label %b1023
b1023:
  %result = add i64 %sum, 1024
  store i64 %result, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %result
}


define i64 @switch_duplicate(i64 %input, i64 %salt, ptr %out) {
entry:
  switch i64 %input, label %merge [
    i64 0, label %merge
    i64 9223372036854775808, label %one
    i64 -1, label %merge
  ]
one:
  %value = add i64 %salt, 7
  br label %merge
merge:
  %result = phi i64 [ %salt, %entry ], [ %salt, %entry ], [ %salt, %entry ], [ %value, %one ]
  store i64 %result, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %result
}


define i64 @switch_loop(i64 %input, i64 %salt, ptr %out) {
entry:
  %start = and i64 %input, 15
  br label %loop
loop:
  %counter = phi i64 [ %start, %entry ], [ %remaining, %join ]
  %total = phi i64 [ %salt, %entry ], [ %sum, %join ]
  %done = icmp eq i64 %counter, 0
  br i1 %done, label %exit, label %dispatch
dispatch:
  switch i64 %counter, label %fallback [
    i64 1, label %case1
    i64 2, label %case2
    i64 3, label %case3
    i64 4, label %case4
    i64 5, label %case5
    i64 6, label %case6
    i64 7, label %case7
    i64 8, label %case8
    i64 9, label %case9
  ]
fallback:
  br label %join
case1:
  br label %join
case2:
  br label %join
case3:
  br label %join
case4:
  br label %join
case5:
  br label %join
case6:
  br label %join
case7:
  br label %join
case8:
  br label %join
case9:
  br label %join
join:
  %step = phi i64 [ 17, %fallback ], [ 1, %case1 ], [ 2, %case2 ], [ 3, %case3 ], [ 4, %case4 ], [ 5, %case5 ], [ 6, %case6 ], [ 7, %case7 ], [ 8, %case8 ], [ 9, %case9 ]
  %sum = add i64 %total, %step
  %remaining = sub i64 %counter, 1
  br label %loop
exit:
  store i64 %total, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %total
}

