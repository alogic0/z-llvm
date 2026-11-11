target triple = "x86_64-unknown-linux-gnu"
define i64 @integer_truncation_53_to_52(i64 %input, i64 %live, ptr %out, i64 %extra1, i64 %extra2, i64 %extra3, i64 %extra4) {
entry:
 %source = trunc i64 %input to i53
 %narrow = trunc i53 %source to i52
 store i52 %narrow, ptr %out, align 1
 %wide = zext i52 %narrow to i64
 %one = xor i64 %live, %extra1
 %two = add i64 %one, %extra2
 %three = xor i64 %two, %extra3
 %four = add i64 %three, %extra4
 %mixed = xor i64 %wide, %input
 %answer = xor i64 %mixed, %four
 ret i64 %answer
}
define i64 @integer_truncation_55_to_52(i64 %input, i64 %live, ptr %out, i64 %extra1, i64 %extra2, i64 %extra3, i64 %extra4) {
entry:
 %source = trunc i64 %input to i55
 %narrow = trunc i55 %source to i52
 store i52 %narrow, ptr %out, align 1
 %wide = zext i52 %narrow to i64
 %one = xor i64 %live, %extra1
 %two = add i64 %one, %extra2
 %three = xor i64 %two, %extra3
 %four = add i64 %three, %extra4
 %mixed = xor i64 %wide, %input
 %answer = xor i64 %mixed, %four
 ret i64 %answer
}
define i64 @integer_truncation_56_to_52(i64 %input, i64 %live, ptr %out, i64 %extra1, i64 %extra2, i64 %extra3, i64 %extra4) {
entry:
 %source = trunc i64 %input to i56
 %narrow = trunc i56 %source to i52
 store i52 %narrow, ptr %out, align 1
 %wide = zext i52 %narrow to i64
 %one = xor i64 %live, %extra1
 %two = add i64 %one, %extra2
 %three = xor i64 %two, %extra3
 %four = add i64 %three, %extra4
 %mixed = xor i64 %wide, %input
 %answer = xor i64 %mixed, %four
 ret i64 %answer
}
define i64 @integer_truncation_63_to_52(i64 %input, i64 %live, ptr %out, i64 %extra1, i64 %extra2, i64 %extra3, i64 %extra4) {
entry:
 %source = trunc i64 %input to i63
 %narrow = trunc i63 %source to i52
 store i52 %narrow, ptr %out, align 1
 %wide = zext i52 %narrow to i64
 %one = xor i64 %live, %extra1
 %two = add i64 %one, %extra2
 %three = xor i64 %two, %extra3
 %four = add i64 %three, %extra4
 %mixed = xor i64 %wide, %input
 %answer = xor i64 %mixed, %four
 ret i64 %answer
}
define i64 @integer_truncation_64_to_52(i64 %input, i64 %live, ptr %out, i64 %extra1, i64 %extra2, i64 %extra3, i64 %extra4) {
entry:
 %source = add i64 %input, 0
 %narrow = trunc i64 %source to i52
 store i52 %narrow, ptr %out, align 1
 %wide = zext i52 %narrow to i64
 %one = xor i64 %live, %extra1
 %two = add i64 %one, %extra2
 %three = xor i64 %two, %extra3
 %four = add i64 %three, %extra4
 %mixed = xor i64 %wide, %input
 %answer = xor i64 %mixed, %four
 ret i64 %answer
}
define i64 @integer_truncation_52_to_1(i64 %input, i64 %live, ptr %out, i64 %extra1, i64 %extra2, i64 %extra3, i64 %extra4) {
entry:
 %source = trunc i64 %input to i52
 %narrow = trunc i52 %source to i1
 store i1 %narrow, ptr %out, align 1
 %wide = zext i1 %narrow to i64
 %one = xor i64 %live, %extra1
 %two = add i64 %one, %extra2
 %three = xor i64 %two, %extra3
 %four = add i64 %three, %extra4
 %mixed = xor i64 %wide, %input
 %answer = xor i64 %mixed, %four
 ret i64 %answer
}
define i64 @integer_truncation_52_to_2(i64 %input, i64 %live, ptr %out, i64 %extra1, i64 %extra2, i64 %extra3, i64 %extra4) {
entry:
 %source = trunc i64 %input to i52
 %narrow = trunc i52 %source to i2
 store i2 %narrow, ptr %out, align 1
 %wide = zext i2 %narrow to i64
 %one = xor i64 %live, %extra1
 %two = add i64 %one, %extra2
 %three = xor i64 %two, %extra3
 %four = add i64 %three, %extra4
 %mixed = xor i64 %wide, %input
 %answer = xor i64 %mixed, %four
 ret i64 %answer
}
define i64 @integer_truncation_52_to_5(i64 %input, i64 %live, ptr %out, i64 %extra1, i64 %extra2, i64 %extra3, i64 %extra4) {
entry:
 %source = trunc i64 %input to i52
 %narrow = trunc i52 %source to i5
 store i5 %narrow, ptr %out, align 1
 %wide = zext i5 %narrow to i64
 %one = xor i64 %live, %extra1
 %two = add i64 %one, %extra2
 %three = xor i64 %two, %extra3
 %four = add i64 %three, %extra4
 %mixed = xor i64 %wide, %input
 %answer = xor i64 %mixed, %four
 ret i64 %answer
}
define i64 @integer_truncation_52_to_6(i64 %input, i64 %live, ptr %out, i64 %extra1, i64 %extra2, i64 %extra3, i64 %extra4) {
entry:
 %source = trunc i64 %input to i52
 %narrow = trunc i52 %source to i6
 store i6 %narrow, ptr %out, align 1
 %wide = zext i6 %narrow to i64
 %one = xor i64 %live, %extra1
 %two = add i64 %one, %extra2
 %three = xor i64 %two, %extra3
 %four = add i64 %three, %extra4
 %mixed = xor i64 %wide, %input
 %answer = xor i64 %mixed, %four
 ret i64 %answer
}
define i64 @integer_truncation_52_to_7(i64 %input, i64 %live, ptr %out, i64 %extra1, i64 %extra2, i64 %extra3, i64 %extra4) {
entry:
 %source = trunc i64 %input to i52
 %narrow = trunc i52 %source to i7
 store i7 %narrow, ptr %out, align 1
 %wide = zext i7 %narrow to i64
 %one = xor i64 %live, %extra1
 %two = add i64 %one, %extra2
 %three = xor i64 %two, %extra3
 %four = add i64 %three, %extra4
 %mixed = xor i64 %wide, %input
 %answer = xor i64 %mixed, %four
 ret i64 %answer
}
define i64 @integer_truncation_52_to_8(i64 %input, i64 %live, ptr %out, i64 %extra1, i64 %extra2, i64 %extra3, i64 %extra4) {
entry:
 %source = trunc i64 %input to i52
 %narrow = trunc i52 %source to i8
 store i8 %narrow, ptr %out, align 1
 %wide = zext i8 %narrow to i64
 %one = xor i64 %live, %extra1
 %two = add i64 %one, %extra2
 %three = xor i64 %two, %extra3
 %four = add i64 %three, %extra4
 %mixed = xor i64 %wide, %input
 %answer = xor i64 %mixed, %four
 ret i64 %answer
}
define i64 @integer_truncation_52_to_16(i64 %input, i64 %live, ptr %out, i64 %extra1, i64 %extra2, i64 %extra3, i64 %extra4) {
entry:
 %source = trunc i64 %input to i52
 %narrow = trunc i52 %source to i16
 store i16 %narrow, ptr %out, align 1
 %wide = zext i16 %narrow to i64
 %one = xor i64 %live, %extra1
 %two = add i64 %one, %extra2
 %three = xor i64 %two, %extra3
 %four = add i64 %three, %extra4
 %mixed = xor i64 %wide, %input
 %answer = xor i64 %mixed, %four
 ret i64 %answer
}
define i64 @integer_truncation_52_to_31(i64 %input, i64 %live, ptr %out, i64 %extra1, i64 %extra2, i64 %extra3, i64 %extra4) {
entry:
 %source = trunc i64 %input to i52
 %narrow = trunc i52 %source to i31
 store i31 %narrow, ptr %out, align 1
 %wide = zext i31 %narrow to i64
 %one = xor i64 %live, %extra1
 %two = add i64 %one, %extra2
 %three = xor i64 %two, %extra3
 %four = add i64 %three, %extra4
 %mixed = xor i64 %wide, %input
 %answer = xor i64 %mixed, %four
 ret i64 %answer
}
define i64 @integer_truncation_52_to_32(i64 %input, i64 %live, ptr %out, i64 %extra1, i64 %extra2, i64 %extra3, i64 %extra4) {
entry:
 %source = trunc i64 %input to i52
 %narrow = trunc i52 %source to i32
 store i32 %narrow, ptr %out, align 1
 %wide = zext i32 %narrow to i64
 %one = xor i64 %live, %extra1
 %two = add i64 %one, %extra2
 %three = xor i64 %two, %extra3
 %four = add i64 %three, %extra4
 %mixed = xor i64 %wide, %input
 %answer = xor i64 %mixed, %four
 ret i64 %answer
}
define i64 @integer_truncation_52_to_33(i64 %input, i64 %live, ptr %out, i64 %extra1, i64 %extra2, i64 %extra3, i64 %extra4) {
entry:
 %source = trunc i64 %input to i52
 %narrow = trunc i52 %source to i33
 store i33 %narrow, ptr %out, align 1
 %wide = zext i33 %narrow to i64
 %one = xor i64 %live, %extra1
 %two = add i64 %one, %extra2
 %three = xor i64 %two, %extra3
 %four = add i64 %three, %extra4
 %mixed = xor i64 %wide, %input
 %answer = xor i64 %mixed, %four
 ret i64 %answer
}
define i64 @integer_truncation_52_to_51(i64 %input, i64 %live, ptr %out, i64 %extra1, i64 %extra2, i64 %extra3, i64 %extra4) {
entry:
 %source = trunc i64 %input to i52
 %narrow = trunc i52 %source to i51
 store i51 %narrow, ptr %out, align 1
 %wide = zext i51 %narrow to i64
 %one = xor i64 %live, %extra1
 %two = add i64 %one, %extra2
 %three = xor i64 %two, %extra3
 %four = add i64 %three, %extra4
 %mixed = xor i64 %wide, %input
 %answer = xor i64 %mixed, %four
 ret i64 %answer
}
