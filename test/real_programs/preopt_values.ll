define i32 @values_bswap32(i32 %"0") {
Entry:
  %"1" = and i32 %"0", -16777216
  %"3" = lshr i32 %"1", 24
  %"4" = and i32 %"0", 16711680
  %"6" = lshr i32 %"4", 8
  %"7" = or i32 %"3", %"6"
  %"8" = and i32 %"0", 65280
  %"10" = shl i32 %"8", 8
  %"11" = or i32 %"7", %"10"
  %"12" = and i32 %"0", 255
  %"14" = shl i32 %"12", 24
  %"15" = or i32 %"11", %"14"
  ret i32 %"15"
}
define i64 @values_bswap64(i64 %"0") {
Entry:
  %"1" = and i64 %"0", -72057594037927936
  %"3" = lshr i64 %"1", 56
  %"4" = and i64 %"0", 71776119061217280
  %"6" = lshr i64 %"4", 40
  %"7" = or i64 %"3", %"6"
  %"8" = and i64 %"0", 280375465082880
  %"10" = lshr i64 %"8", 24
  %"11" = or i64 %"7", %"10"
  %"12" = and i64 %"0", 1095216660480
  %"14" = lshr i64 %"12", 8
  %"15" = or i64 %"11", %"14"
  %"16" = and i64 %"0", 4278190080
  %"18" = shl i64 %"16", 8
  %"19" = or i64 %"15", %"18"
  %"20" = and i64 %"0", 16711680
  %"22" = shl i64 %"20", 24
  %"23" = or i64 %"19", %"22"
  %"24" = and i64 %"0", 65280
  %"26" = shl i64 %"24", 40
  %"27" = or i64 %"23", %"26"
  %"28" = and i64 %"0", 255
  %"30" = shl i64 %"28", 56
  %"31" = or i64 %"27", %"30"
  ret i64 %"31"
}
define float @values_copysign32(float %"0", float %"1") {
Entry:
  %"2" = bitcast float %"0" to i32
  %"3" = and i32 %"2", 2147483647
  %"4" = bitcast float %"1" to i32
  %"5" = and i32 %"4", -2147483648
  %"6" = or i32 %"3", %"5"
  %"7" = bitcast i32 %"6" to float
  ret float %"7"
}
define double @values_copysign64(double %"0", double %"1") {
Entry:
  %"2" = bitcast double %"0" to i64
  %"3" = and i64 %"2", 9223372036854775807
  %"4" = bitcast double %"1" to i64
  %"5" = and i64 %"4", -9223372036854775808
  %"6" = or i64 %"3", %"5"
  %"7" = bitcast i64 %"6" to double
  ret double %"7"
}

define i128 @values_zero_return(i128 %value, i1 %choose) {
entry:
 br i1 %choose, label %yes, label %no
yes:
 ret i128 %value
no:
 ret i128 0
}

define i128 @values_wide_literal() {
entry:
 ret i128 18446744073709551616
}

define i64 @values_signed3(i8 %input) {
entry:
 %narrow = trunc i8 %input to i3
 %converted = sitofp i3 %narrow to double
 %bits = bitcast double %converted to i64
 ret i64 %bits
}

define i64 @values_unsigned3(i8 %input) {
entry:
 %narrow = trunc i8 %input to i3
 %converted = uitofp i3 %narrow to double
 %bits = bitcast double %converted to i64
 ret i64 %bits
}

declare i32 @values_int_source(i32)

define i64 @values_srem32_call(i32 %input, i64 %keep) {
entry:
 %value = call i32 @values_int_source(i32 %input)
 %remainder = srem i32 %value, 64
 %signed = sext i32 %remainder to i64
 %live = zext i32 %value to i64
 %mix = xor i64 %signed, %live
 %answer = xor i64 %mix, %keep
 ret i64 %answer
}

define i32 @values_srem32_plain(i32 %value) {
entry:
 %remainder = srem i32 %value, 64
 ret i32 %remainder
}
