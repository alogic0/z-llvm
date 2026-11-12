define i64 @pair_switch_33(ptr %out, i128 %input, i64 %salt) {
entry:
 %narrow = trunc i128 %input to i33
 switch i33 %narrow, label %merge [
 i33 0, label %c0
 i33 1, label %c1
 i33 4294967296, label %c2
 i33 4294967303, label %c3
 i33 8589934591, label %merge
 ]
c0:
 br label %merge
c1:
 br label %merge
c2:
 br label %merge
c3:
 br label %merge
merge:
 %tag = phi i64 [99, %entry], [99, %entry], [10, %c0], [11, %c1], [12, %c2], [13, %c3]
 %value = xor i64 %tag, %salt
 store i64 %value, ptr %out, align 8
 ret i64 %value
}
define i64 @pair_switch_63(ptr %out, i128 %input, i64 %salt) {
entry:
 %narrow = trunc i128 %input to i63
 switch i63 %narrow, label %merge [
 i63 0, label %c0
 i63 1, label %c1
 i63 4611686018427387904, label %c2
 i63 4611686018427387911, label %c3
 i63 9223372036854775807, label %merge
 ]
c0:
 br label %merge
c1:
 br label %merge
c2:
 br label %merge
c3:
 br label %merge
merge:
 %tag = phi i64 [99, %entry], [99, %entry], [10, %c0], [11, %c1], [12, %c2], [13, %c3]
 %value = xor i64 %tag, %salt
 store i64 %value, ptr %out, align 8
 ret i64 %value
}
define i64 @pair_switch_65(ptr %out, i128 %input, i64 %salt) {
entry:
 %narrow = trunc i128 %input to i65
 switch i65 %narrow, label %merge [
 i65 0, label %c0
 i65 1, label %c1
 i65 18446744073709551616, label %c2
 i65 18446744073709551623, label %c3
 i65 36893488147419103231, label %merge
 ]
c0:
 br label %merge
c1:
 br label %merge
c2:
 br label %merge
c3:
 br label %merge
merge:
 %tag = phi i64 [99, %entry], [99, %entry], [10, %c0], [11, %c1], [12, %c2], [13, %c3]
 %value = xor i64 %tag, %salt
 store i64 %value, ptr %out, align 8
 ret i64 %value
}
define i64 @pair_switch_97(ptr %out, i128 %input, i64 %salt) {
entry:
 %narrow = trunc i128 %input to i97
 switch i97 %narrow, label %merge [
 i97 0, label %c0
 i97 1, label %c1
 i97 79228162514264337593543950336, label %c2
 i97 79228162514264337593543950343, label %c3
 i97 158456325028528675187087900671, label %merge
 ]
c0:
 br label %merge
c1:
 br label %merge
c2:
 br label %merge
c3:
 br label %merge
merge:
 %tag = phi i64 [99, %entry], [99, %entry], [10, %c0], [11, %c1], [12, %c2], [13, %c3]
 %value = xor i64 %tag, %salt
 store i64 %value, ptr %out, align 8
 ret i64 %value
}
define i64 @pair_switch_127(ptr %out, i128 %input, i64 %salt) {
entry:
 %narrow = trunc i128 %input to i127
 switch i127 %narrow, label %merge [
 i127 0, label %c0
 i127 1, label %c1
 i127 85070591730234615865843651857942052864, label %c2
 i127 85070591730234615865843651857942052871, label %c3
 i127 170141183460469231731687303715884105727, label %merge
 ]
c0:
 br label %merge
c1:
 br label %merge
c2:
 br label %merge
c3:
 br label %merge
merge:
 %tag = phi i64 [99, %entry], [99, %entry], [10, %c0], [11, %c1], [12, %c2], [13, %c3]
 %value = xor i64 %tag, %salt
 store i64 %value, ptr %out, align 8
 ret i64 %value
}
define i64 @pair_switch_128(ptr %out, i128 %input, i64 %salt) {
entry:
 switch i128 %input, label %merge [
 i128 0, label %c0
 i128 1, label %c1
 i128 -170141183460469231731687303715884105728, label %c2
 i128 -170141183460469231731687303715884105721, label %c3
 i128 -1, label %merge
 ]
c0:
 br label %merge
c1:
 br label %merge
c2:
 br label %merge
c3:
 br label %merge
merge:
 %tag = phi i64 [99, %entry], [99, %entry], [10, %c0], [11, %c1], [12, %c2], [13, %c3]
 %value = xor i64 %tag, %salt
 store i64 %value, ptr %out, align 8
 ret i64 %value
}
