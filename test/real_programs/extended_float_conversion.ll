target triple = "x86_64-unknown-linux-gnu"
declare fp128 @extended_mixed_quad(i64, i128, fp128, i128, i64)
declare i128 @extended_mixed_integer(fp128, i64, i128)
define i128 @extended_float_from_half(i128 %raw, i64 %live, i64 %e1, i64 %e2, i64 %e3, i64 %e4, ptr %out) {
entry:
 %half_bits = trunc i128 %raw to i16
 %input = bitcast i16 %half_bits to half
 %number = fpext half %input to fp128
 %converted = bitcast fp128 %number to i128
 store i128 %converted, ptr %out, align 1
 %one = xor i64 %live, %e1
 %two = add i64 %one, %e2
 %three = xor i64 %two, %e3
 %four = add i64 %three, %e4
 %wide = zext i64 %four to i128
 %with_raw = xor i128 %converted, %raw
 %answer = xor i128 %with_raw, %wide
 ret i128 %answer
}
define i128 @extended_float_from_signed(i128 %raw, i64 %live, i64 %e1, i64 %e2, i64 %e3, i64 %e4, ptr %out) {
entry:
 %number = sitofp i128 %raw to fp128
 %converted = bitcast fp128 %number to i128
 store i128 %converted, ptr %out, align 1
 %one = xor i64 %live, %e1
 %two = add i64 %one, %e2
 %three = xor i64 %two, %e3
 %four = add i64 %three, %e4
 %wide = zext i64 %four to i128
 %with_raw = xor i128 %converted, %raw
 %answer = xor i128 %with_raw, %wide
 ret i128 %answer
}
define i128 @extended_float_from_unsigned(i128 %raw, i64 %live, i64 %e1, i64 %e2, i64 %e3, i64 %e4, ptr %out) {
entry:
 %number = uitofp i128 %raw to fp128
 %converted = bitcast fp128 %number to i128
 store i128 %converted, ptr %out, align 1
 %one = xor i64 %live, %e1
 %two = add i64 %one, %e2
 %three = xor i64 %two, %e3
 %four = add i64 %three, %e4
 %wide = zext i64 %four to i128
 %with_raw = xor i128 %converted, %raw
 %answer = xor i128 %with_raw, %wide
 ret i128 %answer
}
define i128 @extended_float_to_half(i128 %raw, i64 %live, i64 %e1, i64 %e2, i64 %e3, i64 %e4, ptr %out) {
entry:
 %input = bitcast i128 %raw to fp128
 %number = fptrunc fp128 %input to half
 %half_result = bitcast half %number to i16
 %converted = zext i16 %half_result to i128
 store i128 %converted, ptr %out, align 1
 %one = xor i64 %live, %e1
 %two = add i64 %one, %e2
 %three = xor i64 %two, %e3
 %four = add i64 %three, %e4
 %wide = zext i64 %four to i128
 %with_raw = xor i128 %converted, %raw
 %answer = xor i128 %with_raw, %wide
 ret i128 %answer
}
define i128 @extended_float_to_signed(i128 %raw, i64 %live, i64 %e1, i64 %e2, i64 %e3, i64 %e4, ptr %out) {
entry:
 %input = bitcast i128 %raw to fp128
 %number = fptosi fp128 %input to i128
 store i128 %number, ptr %out, align 1
 %one = xor i64 %live, %e1
 %two = add i64 %one, %e2
 %three = xor i64 %two, %e3
 %four = add i64 %three, %e4
 %wide = zext i64 %four to i128
 %with_raw = xor i128 %number, %raw
 %answer = xor i128 %with_raw, %wide
 ret i128 %answer
}
define i128 @extended_float_to_unsigned(i128 %raw, i64 %live, i64 %e1, i64 %e2, i64 %e3, i64 %e4, ptr %out) {
entry:
 %input = bitcast i128 %raw to fp128
 %number = fptoui fp128 %input to i128
 store i128 %number, ptr %out, align 1
 %one = xor i64 %live, %e1
 %two = add i64 %one, %e2
 %three = xor i64 %two, %e3
 %four = add i64 %three, %e4
 %wide = zext i64 %four to i128
 %with_raw = xor i128 %number, %raw
 %answer = xor i128 %with_raw, %wide
 ret i128 %answer
}
define i128 @extended_float_signed_literal(i128 %raw, i64 %live, i64 %e1, i64 %e2, i64 %e3, i64 %e4, ptr %out) {
entry:
 %number = sitofp i128 -170141183460469231731687303715884105727 to fp128
 %converted = bitcast fp128 %number to i128
 store i128 %converted, ptr %out, align 1
 %one = xor i64 %live, %e1
 %two = add i64 %one, %e2
 %three = xor i64 %two, %e3
 %four = add i64 %three, %e4
 %wide = zext i64 %four to i128
 %with_raw = xor i128 %converted, %raw
 %answer = xor i128 %with_raw, %wide
 ret i128 %answer
}
define i128 @extended_float_unsigned_literal(i128 %raw, i64 %live, i64 %e1, i64 %e2, i64 %e3, i64 %e4, ptr %out) {
entry:
 %number = uitofp i128 -1 to fp128
 %converted = bitcast fp128 %number to i128
 store i128 %converted, ptr %out, align 1
 %one = xor i64 %live, %e1
 %two = add i64 %one, %e2
 %three = xor i64 %two, %e3
 %four = add i64 %three, %e4
 %wide = zext i64 %four to i128
 %with_raw = xor i128 %converted, %raw
 %answer = xor i128 %with_raw, %wide
 ret i128 %answer
}
define i128 @extended_float_mixed_quad(i128 %raw, i64 %live, i64 %e1, i64 %e2, i64 %e3, i64 %e4, ptr %out) {
entry:
 %input = bitcast i128 %raw to fp128
 %other_seed = zext i64 %e1 to i128
 %other = xor i128 %raw, %other_seed
 %number = call fp128 @extended_mixed_quad(i64 %live, i128 %raw, fp128 %input, i128 %other, i64 %e4)
 %converted = bitcast fp128 %number to i128
 store i128 %converted, ptr %out, align 1
 %one = xor i64 %live, %e1
 %two = add i64 %one, %e2
 %three = xor i64 %two, %e3
 %four = add i64 %three, %e4
 %wide = zext i64 %four to i128
 %with_raw = xor i128 %converted, %raw
 %answer = xor i128 %with_raw, %wide
 ret i128 %answer
}
define i128 @extended_float_mixed_integer(i128 %raw, i64 %live, i64 %e1, i64 %e2, i64 %e3, i64 %e4, ptr %out) {
entry:
 %input = bitcast i128 %raw to fp128
 %number = call i128 @extended_mixed_integer(fp128 %input, i64 %e2, i128 %raw)
 store i128 %number, ptr %out, align 1
 %one = xor i64 %live, %e1
 %two = add i64 %one, %e2
 %three = xor i64 %two, %e3
 %four = add i64 %three, %e4
 %wide = zext i64 %four to i128
 %with_raw = xor i128 %number, %raw
 %answer = xor i128 %with_raw, %wide
 ret i128 %answer
}
