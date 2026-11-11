target triple = "x86_64-unknown-linux-gnu"
declare i128 @__udivti3(i128, i128)
declare i128 @__umodti3(i128, i128)
declare i128 @__divti3(i128, i128)
declare i128 @__modti3(i128, i128)
define i128 @pair_division_udiv_named(i128 %a, i128 %b, i64 %seed, i64 %live1, i64 %live2, i64 %live3) {
entry:
 %raw = udiv i128 %a, %b
 %with_a = xor i128 %raw, %a
 %with_b = xor i128 %with_a, %b
 %one = xor i64 %seed, %live1
 %two = add i64 %one, %live2
 %three = xor i64 %two, %live3
 %wide = zext i64 %three to i128
 %result = xor i128 %with_b, %wide
 ret i128 %result
}
define i128 @pair_division_udiv_constant(i128 %a, i128 %b, i64 %seed, i64 %live1, i64 %live2, i64 %live3) {
entry:
 %raw = udiv i128 %a, 79228162514264337593543950339
 %with_a = xor i128 %raw, %a
 %with_b = xor i128 %with_a, %b
 %one = xor i64 %seed, %live1
 %two = add i64 %one, %live2
 %three = xor i64 %two, %live3
 %wide = zext i64 %three to i128
 %result = xor i128 %with_b, %wide
 ret i128 %result
}
define i128 @pair_division_urem_named(i128 %a, i128 %b, i64 %seed, i64 %live1, i64 %live2, i64 %live3) {
entry:
 %raw = urem i128 %a, %b
 %with_a = xor i128 %raw, %a
 %with_b = xor i128 %with_a, %b
 %one = xor i64 %seed, %live1
 %two = add i64 %one, %live2
 %three = xor i64 %two, %live3
 %wide = zext i64 %three to i128
 %result = xor i128 %with_b, %wide
 ret i128 %result
}
define i128 @pair_division_urem_constant(i128 %a, i128 %b, i64 %seed, i64 %live1, i64 %live2, i64 %live3) {
entry:
 %raw = urem i128 %a, 79228162514264337593543950339
 %with_a = xor i128 %raw, %a
 %with_b = xor i128 %with_a, %b
 %one = xor i64 %seed, %live1
 %two = add i64 %one, %live2
 %three = xor i64 %two, %live3
 %wide = zext i64 %three to i128
 %result = xor i128 %with_b, %wide
 ret i128 %result
}
define i128 @pair_division_sdiv_named(i128 %a, i128 %b, i64 %seed, i64 %live1, i64 %live2, i64 %live3) {
entry:
 %raw = sdiv i128 %a, %b
 %with_a = xor i128 %raw, %a
 %with_b = xor i128 %with_a, %b
 %one = xor i64 %seed, %live1
 %two = add i64 %one, %live2
 %three = xor i64 %two, %live3
 %wide = zext i64 %three to i128
 %result = xor i128 %with_b, %wide
 ret i128 %result
}
define i128 @pair_division_sdiv_constant(i128 %a, i128 %b, i64 %seed, i64 %live1, i64 %live2, i64 %live3) {
entry:
 %raw = sdiv i128 %a, -79228162514264337593543950339
 %with_a = xor i128 %raw, %a
 %with_b = xor i128 %with_a, %b
 %one = xor i64 %seed, %live1
 %two = add i64 %one, %live2
 %three = xor i64 %two, %live3
 %wide = zext i64 %three to i128
 %result = xor i128 %with_b, %wide
 ret i128 %result
}
define i128 @pair_division_srem_named(i128 %a, i128 %b, i64 %seed, i64 %live1, i64 %live2, i64 %live3) {
entry:
 %raw = srem i128 %a, %b
 %with_a = xor i128 %raw, %a
 %with_b = xor i128 %with_a, %b
 %one = xor i64 %seed, %live1
 %two = add i64 %one, %live2
 %three = xor i64 %two, %live3
 %wide = zext i64 %three to i128
 %result = xor i128 %with_b, %wide
 ret i128 %result
}
define i128 @pair_division_srem_constant(i128 %a, i128 %b, i64 %seed, i64 %live1, i64 %live2, i64 %live3) {
entry:
 %raw = srem i128 %a, -79228162514264337593543950339
 %with_a = xor i128 %raw, %a
 %with_b = xor i128 %with_a, %b
 %one = xor i64 %seed, %live1
 %two = add i64 %one, %live2
 %three = xor i64 %two, %live3
 %wide = zext i64 %three to i128
 %result = xor i128 %with_b, %wide
 ret i128 %result
}
