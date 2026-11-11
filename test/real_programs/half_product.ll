target triple = "x86_64-unknown-linux-gnu"
define i64 @half_product_0(i16 %a, i16 %b, i64 %live, i64 %e1, i64 %e2, i64 %e3, i64 %e4, ptr %out) {
entry:
 %left = bitcast i16 %a to half
 %right = bitcast i16 %b to half

 %raw = fmul half %left, %right
 %bits = bitcast half %raw to i16
 store i16 %bits, ptr %out, align 1
 %wide = zext i16 %bits to i64
 %aw = zext i16 %a to i64
 %bw = zext i16 %b to i64
 %one = xor i64 %live, %e1
 %two = add i64 %one, %e2
 %three = xor i64 %two, %e3
 %four = add i64 %three, %e4
 %mixed = xor i64 %four, %wide
 %with_a = xor i64 %mixed, %aw
 %answer = xor i64 %with_a, %bw
 ret i64 %answer
}
define i64 @half_product_1(i16 %a, i16 %b, i64 %live, i64 %e1, i64 %e2, i64 %e3, i64 %e4, ptr %out) {
entry:
 %left = bitcast i16 %a to half
 %right = bitcast i16 %b to half

 %raw = fmul half 0xH0000, %right
 %bits = bitcast half %raw to i16
 store i16 %bits, ptr %out, align 1
 %wide = zext i16 %bits to i64
 %aw = zext i16 %a to i64
 %bw = zext i16 %b to i64
 %one = xor i64 %live, %e1
 %two = add i64 %one, %e2
 %three = xor i64 %two, %e3
 %four = add i64 %three, %e4
 %mixed = xor i64 %four, %wide
 %with_a = xor i64 %mixed, %aw
 %answer = xor i64 %with_a, %bw
 ret i64 %answer
}
define i64 @half_product_2(i16 %a, i16 %b, i64 %live, i64 %e1, i64 %e2, i64 %e3, i64 %e4, ptr %out) {
entry:
 %left = bitcast i16 %a to half
 %right = bitcast i16 %b to half

 %raw = fmul half %left, 0xH0000
 %bits = bitcast half %raw to i16
 store i16 %bits, ptr %out, align 1
 %wide = zext i16 %bits to i64
 %aw = zext i16 %a to i64
 %bw = zext i16 %b to i64
 %one = xor i64 %live, %e1
 %two = add i64 %one, %e2
 %three = xor i64 %two, %e3
 %four = add i64 %three, %e4
 %mixed = xor i64 %four, %wide
 %with_a = xor i64 %mixed, %aw
 %answer = xor i64 %with_a, %bw
 ret i64 %answer
}
define i64 @half_product_3(i16 %a, i16 %b, i64 %live, i64 %e1, i64 %e2, i64 %e3, i64 %e4, ptr %out) {
entry:
 %left = bitcast i16 %a to half
 %right = bitcast i16 %b to half

 %raw = fmul half 0xH8000, %right
 %bits = bitcast half %raw to i16
 store i16 %bits, ptr %out, align 1
 %wide = zext i16 %bits to i64
 %aw = zext i16 %a to i64
 %bw = zext i16 %b to i64
 %one = xor i64 %live, %e1
 %two = add i64 %one, %e2
 %three = xor i64 %two, %e3
 %four = add i64 %three, %e4
 %mixed = xor i64 %four, %wide
 %with_a = xor i64 %mixed, %aw
 %answer = xor i64 %with_a, %bw
 ret i64 %answer
}
define i64 @half_product_4(i16 %a, i16 %b, i64 %live, i64 %e1, i64 %e2, i64 %e3, i64 %e4, ptr %out) {
entry:
 %left = bitcast i16 %a to half
 %right = bitcast i16 %b to half

 %raw = fmul half %left, 0xH8000
 %bits = bitcast half %raw to i16
 store i16 %bits, ptr %out, align 1
 %wide = zext i16 %bits to i64
 %aw = zext i16 %a to i64
 %bw = zext i16 %b to i64
 %one = xor i64 %live, %e1
 %two = add i64 %one, %e2
 %three = xor i64 %two, %e3
 %four = add i64 %three, %e4
 %mixed = xor i64 %four, %wide
 %with_a = xor i64 %mixed, %aw
 %answer = xor i64 %with_a, %bw
 ret i64 %answer
}
define i64 @half_product_5(i16 %a, i16 %b, i64 %live, i64 %e1, i64 %e2, i64 %e3, i64 %e4, ptr %out) {
entry:
 %left = bitcast i16 %a to half
 %right = bitcast i16 %b to half

 %raw = fmul half 0xH0001, %right
 %bits = bitcast half %raw to i16
 store i16 %bits, ptr %out, align 1
 %wide = zext i16 %bits to i64
 %aw = zext i16 %a to i64
 %bw = zext i16 %b to i64
 %one = xor i64 %live, %e1
 %two = add i64 %one, %e2
 %three = xor i64 %two, %e3
 %four = add i64 %three, %e4
 %mixed = xor i64 %four, %wide
 %with_a = xor i64 %mixed, %aw
 %answer = xor i64 %with_a, %bw
 ret i64 %answer
}
define i64 @half_product_6(i16 %a, i16 %b, i64 %live, i64 %e1, i64 %e2, i64 %e3, i64 %e4, ptr %out) {
entry:
 %left = bitcast i16 %a to half
 %right = bitcast i16 %b to half

 %raw = fmul half %left, 0xH0001
 %bits = bitcast half %raw to i16
 store i16 %bits, ptr %out, align 1
 %wide = zext i16 %bits to i64
 %aw = zext i16 %a to i64
 %bw = zext i16 %b to i64
 %one = xor i64 %live, %e1
 %two = add i64 %one, %e2
 %three = xor i64 %two, %e3
 %four = add i64 %three, %e4
 %mixed = xor i64 %four, %wide
 %with_a = xor i64 %mixed, %aw
 %answer = xor i64 %with_a, %bw
 ret i64 %answer
}
define i64 @half_product_7(i16 %a, i16 %b, i64 %live, i64 %e1, i64 %e2, i64 %e3, i64 %e4, ptr %out) {
entry:
 %left = bitcast i16 %a to half
 %right = bitcast i16 %b to half

 %raw = fmul half 0xH3C00, %right
 %bits = bitcast half %raw to i16
 store i16 %bits, ptr %out, align 1
 %wide = zext i16 %bits to i64
 %aw = zext i16 %a to i64
 %bw = zext i16 %b to i64
 %one = xor i64 %live, %e1
 %two = add i64 %one, %e2
 %three = xor i64 %two, %e3
 %four = add i64 %three, %e4
 %mixed = xor i64 %four, %wide
 %with_a = xor i64 %mixed, %aw
 %answer = xor i64 %with_a, %bw
 ret i64 %answer
}
define i64 @half_product_8(i16 %a, i16 %b, i64 %live, i64 %e1, i64 %e2, i64 %e3, i64 %e4, ptr %out) {
entry:
 %left = bitcast i16 %a to half
 %right = bitcast i16 %b to half

 %raw = fmul half %left, 0xH3C00
 %bits = bitcast half %raw to i16
 store i16 %bits, ptr %out, align 1
 %wide = zext i16 %bits to i64
 %aw = zext i16 %a to i64
 %bw = zext i16 %b to i64
 %one = xor i64 %live, %e1
 %two = add i64 %one, %e2
 %three = xor i64 %two, %e3
 %four = add i64 %three, %e4
 %mixed = xor i64 %four, %wide
 %with_a = xor i64 %mixed, %aw
 %answer = xor i64 %with_a, %bw
 ret i64 %answer
}
define i64 @half_product_9(i16 %a, i16 %b, i64 %live, i64 %e1, i64 %e2, i64 %e3, i64 %e4, ptr %out) {
entry:
 %left = bitcast i16 %a to half
 %right = bitcast i16 %b to half

 %raw = fmul half 0xH70E2, %right
 %bits = bitcast half %raw to i16
 store i16 %bits, ptr %out, align 1
 %wide = zext i16 %bits to i64
 %aw = zext i16 %a to i64
 %bw = zext i16 %b to i64
 %one = xor i64 %live, %e1
 %two = add i64 %one, %e2
 %three = xor i64 %two, %e3
 %four = add i64 %three, %e4
 %mixed = xor i64 %four, %wide
 %with_a = xor i64 %mixed, %aw
 %answer = xor i64 %with_a, %bw
 ret i64 %answer
}
define i64 @half_product_10(i16 %a, i16 %b, i64 %live, i64 %e1, i64 %e2, i64 %e3, i64 %e4, ptr %out) {
entry:
 %left = bitcast i16 %a to half
 %right = bitcast i16 %b to half

 %raw = fmul half %left, 0xH70E2
 %bits = bitcast half %raw to i16
 store i16 %bits, ptr %out, align 1
 %wide = zext i16 %bits to i64
 %aw = zext i16 %a to i64
 %bw = zext i16 %b to i64
 %one = xor i64 %live, %e1
 %two = add i64 %one, %e2
 %three = xor i64 %two, %e3
 %four = add i64 %three, %e4
 %mixed = xor i64 %four, %wide
 %with_a = xor i64 %mixed, %aw
 %answer = xor i64 %with_a, %bw
 ret i64 %answer
}
define i64 @half_product_11(i16 %a, i16 %b, i64 %live, i64 %e1, i64 %e2, i64 %e3, i64 %e4, ptr %out) {
entry:
 %left = bitcast i16 %a to half
 %right = bitcast i16 %b to half

 %raw = fmul half 0xH7C00, %right
 %bits = bitcast half %raw to i16
 store i16 %bits, ptr %out, align 1
 %wide = zext i16 %bits to i64
 %aw = zext i16 %a to i64
 %bw = zext i16 %b to i64
 %one = xor i64 %live, %e1
 %two = add i64 %one, %e2
 %three = xor i64 %two, %e3
 %four = add i64 %three, %e4
 %mixed = xor i64 %four, %wide
 %with_a = xor i64 %mixed, %aw
 %answer = xor i64 %with_a, %bw
 ret i64 %answer
}
define i64 @half_product_12(i16 %a, i16 %b, i64 %live, i64 %e1, i64 %e2, i64 %e3, i64 %e4, ptr %out) {
entry:
 %left = bitcast i16 %a to half
 %right = bitcast i16 %b to half

 %raw = fmul half %left, 0xH7C00
 %bits = bitcast half %raw to i16
 store i16 %bits, ptr %out, align 1
 %wide = zext i16 %bits to i64
 %aw = zext i16 %a to i64
 %bw = zext i16 %b to i64
 %one = xor i64 %live, %e1
 %two = add i64 %one, %e2
 %three = xor i64 %two, %e3
 %four = add i64 %three, %e4
 %mixed = xor i64 %four, %wide
 %with_a = xor i64 %mixed, %aw
 %answer = xor i64 %with_a, %bw
 ret i64 %answer
}
define i64 @half_product_13(i16 %a, i16 %b, i64 %live, i64 %e1, i64 %e2, i64 %e3, i64 %e4, ptr %out) {
entry:
 %left = bitcast i16 %a to half
 %right = bitcast i16 %b to half

 %raw = fmul half 0xH7E55, %right
 %bits = bitcast half %raw to i16
 store i16 %bits, ptr %out, align 1
 %wide = zext i16 %bits to i64
 %aw = zext i16 %a to i64
 %bw = zext i16 %b to i64
 %one = xor i64 %live, %e1
 %two = add i64 %one, %e2
 %three = xor i64 %two, %e3
 %four = add i64 %three, %e4
 %mixed = xor i64 %four, %wide
 %with_a = xor i64 %mixed, %aw
 %answer = xor i64 %with_a, %bw
 ret i64 %answer
}
define i64 @half_product_14(i16 %a, i16 %b, i64 %live, i64 %e1, i64 %e2, i64 %e3, i64 %e4, ptr %out) {
entry:
 %left = bitcast i16 %a to half
 %right = bitcast i16 %b to half

 %raw = fmul half %left, 0xH7E55
 %bits = bitcast half %raw to i16
 store i16 %bits, ptr %out, align 1
 %wide = zext i16 %bits to i64
 %aw = zext i16 %a to i64
 %bw = zext i16 %b to i64
 %one = xor i64 %live, %e1
 %two = add i64 %one, %e2
 %three = xor i64 %two, %e3
 %four = add i64 %three, %e4
 %mixed = xor i64 %four, %wide
 %with_a = xor i64 %mixed, %aw
 %answer = xor i64 %with_a, %bw
 ret i64 %answer
}
define i64 @half_product_15(i16 %a, i16 %b, i64 %live, i64 %e1, i64 %e2, i64 %e3, i64 %e4, ptr %out) {
entry:
 %left = bitcast i16 %a to half
 %right = bitcast i16 %b to half
 %loaded = load half, ptr %out, align 1
 %raw = fmul half %loaded, %right
 %bits = bitcast half %raw to i16
 store i16 %bits, ptr %out, align 1
 %wide = zext i16 %bits to i64
 %aw = zext i16 %a to i64
 %bw = zext i16 %b to i64
 %one = xor i64 %live, %e1
 %two = add i64 %one, %e2
 %three = xor i64 %two, %e3
 %four = add i64 %three, %e4
 %mixed = xor i64 %four, %wide
 %with_a = xor i64 %mixed, %aw
 %answer = xor i64 %with_a, %bw
 ret i64 %answer
}
define i64 @half_product_16(i16 %a, i16 %b, i64 %live, i64 %e1, i64 %e2, i64 %e3, i64 %e4, ptr %out) {
entry:
 %left = bitcast i16 %a to half
 %right = bitcast i16 %b to half

 %raw = fdiv half %left, %right
 %bits = bitcast half %raw to i16
 store i16 %bits, ptr %out, align 1
 %wide = zext i16 %bits to i64
 %aw = zext i16 %a to i64
 %bw = zext i16 %b to i64
 %one = xor i64 %live, %e1
 %two = add i64 %one, %e2
 %three = xor i64 %two, %e3
 %four = add i64 %three, %e4
 %mixed = xor i64 %four, %wide
 %with_a = xor i64 %mixed, %aw
 %answer = xor i64 %with_a, %bw
 ret i64 %answer
}
define i64 @half_product_17(i16 %a, i16 %b, i64 %live, i64 %e1, i64 %e2, i64 %e3, i64 %e4, ptr %out) {
entry:
 %left = bitcast i16 %a to half
 %right = bitcast i16 %b to half

 %raw = fdiv half 0xH0000, %right
 %bits = bitcast half %raw to i16
 store i16 %bits, ptr %out, align 1
 %wide = zext i16 %bits to i64
 %aw = zext i16 %a to i64
 %bw = zext i16 %b to i64
 %one = xor i64 %live, %e1
 %two = add i64 %one, %e2
 %three = xor i64 %two, %e3
 %four = add i64 %three, %e4
 %mixed = xor i64 %four, %wide
 %with_a = xor i64 %mixed, %aw
 %answer = xor i64 %with_a, %bw
 ret i64 %answer
}
define i64 @half_product_18(i16 %a, i16 %b, i64 %live, i64 %e1, i64 %e2, i64 %e3, i64 %e4, ptr %out) {
entry:
 %left = bitcast i16 %a to half
 %right = bitcast i16 %b to half

 %raw = fdiv half %left, 0xH0000
 %bits = bitcast half %raw to i16
 store i16 %bits, ptr %out, align 1
 %wide = zext i16 %bits to i64
 %aw = zext i16 %a to i64
 %bw = zext i16 %b to i64
 %one = xor i64 %live, %e1
 %two = add i64 %one, %e2
 %three = xor i64 %two, %e3
 %four = add i64 %three, %e4
 %mixed = xor i64 %four, %wide
 %with_a = xor i64 %mixed, %aw
 %answer = xor i64 %with_a, %bw
 ret i64 %answer
}
define i64 @half_product_19(i16 %a, i16 %b, i64 %live, i64 %e1, i64 %e2, i64 %e3, i64 %e4, ptr %out) {
entry:
 %left = bitcast i16 %a to half
 %right = bitcast i16 %b to half

 %raw = fdiv half 0xH8000, %right
 %bits = bitcast half %raw to i16
 store i16 %bits, ptr %out, align 1
 %wide = zext i16 %bits to i64
 %aw = zext i16 %a to i64
 %bw = zext i16 %b to i64
 %one = xor i64 %live, %e1
 %two = add i64 %one, %e2
 %three = xor i64 %two, %e3
 %four = add i64 %three, %e4
 %mixed = xor i64 %four, %wide
 %with_a = xor i64 %mixed, %aw
 %answer = xor i64 %with_a, %bw
 ret i64 %answer
}
define i64 @half_product_20(i16 %a, i16 %b, i64 %live, i64 %e1, i64 %e2, i64 %e3, i64 %e4, ptr %out) {
entry:
 %left = bitcast i16 %a to half
 %right = bitcast i16 %b to half

 %raw = fdiv half %left, 0xH8000
 %bits = bitcast half %raw to i16
 store i16 %bits, ptr %out, align 1
 %wide = zext i16 %bits to i64
 %aw = zext i16 %a to i64
 %bw = zext i16 %b to i64
 %one = xor i64 %live, %e1
 %two = add i64 %one, %e2
 %three = xor i64 %two, %e3
 %four = add i64 %three, %e4
 %mixed = xor i64 %four, %wide
 %with_a = xor i64 %mixed, %aw
 %answer = xor i64 %with_a, %bw
 ret i64 %answer
}
define i64 @half_product_21(i16 %a, i16 %b, i64 %live, i64 %e1, i64 %e2, i64 %e3, i64 %e4, ptr %out) {
entry:
 %left = bitcast i16 %a to half
 %right = bitcast i16 %b to half

 %raw = fdiv half 0xH0001, %right
 %bits = bitcast half %raw to i16
 store i16 %bits, ptr %out, align 1
 %wide = zext i16 %bits to i64
 %aw = zext i16 %a to i64
 %bw = zext i16 %b to i64
 %one = xor i64 %live, %e1
 %two = add i64 %one, %e2
 %three = xor i64 %two, %e3
 %four = add i64 %three, %e4
 %mixed = xor i64 %four, %wide
 %with_a = xor i64 %mixed, %aw
 %answer = xor i64 %with_a, %bw
 ret i64 %answer
}
define i64 @half_product_22(i16 %a, i16 %b, i64 %live, i64 %e1, i64 %e2, i64 %e3, i64 %e4, ptr %out) {
entry:
 %left = bitcast i16 %a to half
 %right = bitcast i16 %b to half

 %raw = fdiv half %left, 0xH0001
 %bits = bitcast half %raw to i16
 store i16 %bits, ptr %out, align 1
 %wide = zext i16 %bits to i64
 %aw = zext i16 %a to i64
 %bw = zext i16 %b to i64
 %one = xor i64 %live, %e1
 %two = add i64 %one, %e2
 %three = xor i64 %two, %e3
 %four = add i64 %three, %e4
 %mixed = xor i64 %four, %wide
 %with_a = xor i64 %mixed, %aw
 %answer = xor i64 %with_a, %bw
 ret i64 %answer
}
define i64 @half_product_23(i16 %a, i16 %b, i64 %live, i64 %e1, i64 %e2, i64 %e3, i64 %e4, ptr %out) {
entry:
 %left = bitcast i16 %a to half
 %right = bitcast i16 %b to half

 %raw = fdiv half 0xH3C00, %right
 %bits = bitcast half %raw to i16
 store i16 %bits, ptr %out, align 1
 %wide = zext i16 %bits to i64
 %aw = zext i16 %a to i64
 %bw = zext i16 %b to i64
 %one = xor i64 %live, %e1
 %two = add i64 %one, %e2
 %three = xor i64 %two, %e3
 %four = add i64 %three, %e4
 %mixed = xor i64 %four, %wide
 %with_a = xor i64 %mixed, %aw
 %answer = xor i64 %with_a, %bw
 ret i64 %answer
}
define i64 @half_product_24(i16 %a, i16 %b, i64 %live, i64 %e1, i64 %e2, i64 %e3, i64 %e4, ptr %out) {
entry:
 %left = bitcast i16 %a to half
 %right = bitcast i16 %b to half

 %raw = fdiv half %left, 0xH3C00
 %bits = bitcast half %raw to i16
 store i16 %bits, ptr %out, align 1
 %wide = zext i16 %bits to i64
 %aw = zext i16 %a to i64
 %bw = zext i16 %b to i64
 %one = xor i64 %live, %e1
 %two = add i64 %one, %e2
 %three = xor i64 %two, %e3
 %four = add i64 %three, %e4
 %mixed = xor i64 %four, %wide
 %with_a = xor i64 %mixed, %aw
 %answer = xor i64 %with_a, %bw
 ret i64 %answer
}
define i64 @half_product_25(i16 %a, i16 %b, i64 %live, i64 %e1, i64 %e2, i64 %e3, i64 %e4, ptr %out) {
entry:
 %left = bitcast i16 %a to half
 %right = bitcast i16 %b to half

 %raw = fdiv half 0xH70E2, %right
 %bits = bitcast half %raw to i16
 store i16 %bits, ptr %out, align 1
 %wide = zext i16 %bits to i64
 %aw = zext i16 %a to i64
 %bw = zext i16 %b to i64
 %one = xor i64 %live, %e1
 %two = add i64 %one, %e2
 %three = xor i64 %two, %e3
 %four = add i64 %three, %e4
 %mixed = xor i64 %four, %wide
 %with_a = xor i64 %mixed, %aw
 %answer = xor i64 %with_a, %bw
 ret i64 %answer
}
define i64 @half_product_26(i16 %a, i16 %b, i64 %live, i64 %e1, i64 %e2, i64 %e3, i64 %e4, ptr %out) {
entry:
 %left = bitcast i16 %a to half
 %right = bitcast i16 %b to half

 %raw = fdiv half %left, 0xH70E2
 %bits = bitcast half %raw to i16
 store i16 %bits, ptr %out, align 1
 %wide = zext i16 %bits to i64
 %aw = zext i16 %a to i64
 %bw = zext i16 %b to i64
 %one = xor i64 %live, %e1
 %two = add i64 %one, %e2
 %three = xor i64 %two, %e3
 %four = add i64 %three, %e4
 %mixed = xor i64 %four, %wide
 %with_a = xor i64 %mixed, %aw
 %answer = xor i64 %with_a, %bw
 ret i64 %answer
}
define i64 @half_product_27(i16 %a, i16 %b, i64 %live, i64 %e1, i64 %e2, i64 %e3, i64 %e4, ptr %out) {
entry:
 %left = bitcast i16 %a to half
 %right = bitcast i16 %b to half

 %raw = fdiv half 0xH7C00, %right
 %bits = bitcast half %raw to i16
 store i16 %bits, ptr %out, align 1
 %wide = zext i16 %bits to i64
 %aw = zext i16 %a to i64
 %bw = zext i16 %b to i64
 %one = xor i64 %live, %e1
 %two = add i64 %one, %e2
 %three = xor i64 %two, %e3
 %four = add i64 %three, %e4
 %mixed = xor i64 %four, %wide
 %with_a = xor i64 %mixed, %aw
 %answer = xor i64 %with_a, %bw
 ret i64 %answer
}
define i64 @half_product_28(i16 %a, i16 %b, i64 %live, i64 %e1, i64 %e2, i64 %e3, i64 %e4, ptr %out) {
entry:
 %left = bitcast i16 %a to half
 %right = bitcast i16 %b to half

 %raw = fdiv half %left, 0xH7C00
 %bits = bitcast half %raw to i16
 store i16 %bits, ptr %out, align 1
 %wide = zext i16 %bits to i64
 %aw = zext i16 %a to i64
 %bw = zext i16 %b to i64
 %one = xor i64 %live, %e1
 %two = add i64 %one, %e2
 %three = xor i64 %two, %e3
 %four = add i64 %three, %e4
 %mixed = xor i64 %four, %wide
 %with_a = xor i64 %mixed, %aw
 %answer = xor i64 %with_a, %bw
 ret i64 %answer
}
define i64 @half_product_29(i16 %a, i16 %b, i64 %live, i64 %e1, i64 %e2, i64 %e3, i64 %e4, ptr %out) {
entry:
 %left = bitcast i16 %a to half
 %right = bitcast i16 %b to half

 %raw = fdiv half 0xH7E55, %right
 %bits = bitcast half %raw to i16
 store i16 %bits, ptr %out, align 1
 %wide = zext i16 %bits to i64
 %aw = zext i16 %a to i64
 %bw = zext i16 %b to i64
 %one = xor i64 %live, %e1
 %two = add i64 %one, %e2
 %three = xor i64 %two, %e3
 %four = add i64 %three, %e4
 %mixed = xor i64 %four, %wide
 %with_a = xor i64 %mixed, %aw
 %answer = xor i64 %with_a, %bw
 ret i64 %answer
}
define i64 @half_product_30(i16 %a, i16 %b, i64 %live, i64 %e1, i64 %e2, i64 %e3, i64 %e4, ptr %out) {
entry:
 %left = bitcast i16 %a to half
 %right = bitcast i16 %b to half

 %raw = fdiv half %left, 0xH7E55
 %bits = bitcast half %raw to i16
 store i16 %bits, ptr %out, align 1
 %wide = zext i16 %bits to i64
 %aw = zext i16 %a to i64
 %bw = zext i16 %b to i64
 %one = xor i64 %live, %e1
 %two = add i64 %one, %e2
 %three = xor i64 %two, %e3
 %four = add i64 %three, %e4
 %mixed = xor i64 %four, %wide
 %with_a = xor i64 %mixed, %aw
 %answer = xor i64 %with_a, %bw
 ret i64 %answer
}
define i64 @half_product_31(i16 %a, i16 %b, i64 %live, i64 %e1, i64 %e2, i64 %e3, i64 %e4, ptr %out) {
entry:
 %left = bitcast i16 %a to half
 %right = bitcast i16 %b to half
 %loaded = load half, ptr %out, align 1
 %raw = fdiv half %loaded, %right
 %bits = bitcast half %raw to i16
 store i16 %bits, ptr %out, align 1
 %wide = zext i16 %bits to i64
 %aw = zext i16 %a to i64
 %bw = zext i16 %b to i64
 %one = xor i64 %live, %e1
 %two = add i64 %one, %e2
 %three = xor i64 %two, %e3
 %four = add i64 %three, %e4
 %mixed = xor i64 %four, %wide
 %with_a = xor i64 %mixed, %aw
 %answer = xor i64 %with_a, %bw
 ret i64 %answer
}
define i64 @half_product_32(i16 %a, i16 %b, i64 %live, i64 %e1, i64 %e2, i64 %e3, i64 %e4, ptr %out) {
entry:
 %left = bitcast i16 %a to half
 %right = bitcast i16 %b to half

 %raw = fneg half %left
 %bits = bitcast half %raw to i16
 store i16 %bits, ptr %out, align 1
 %wide = zext i16 %bits to i64
 %aw = zext i16 %a to i64
 %bw = zext i16 %b to i64
 %one = xor i64 %live, %e1
 %two = add i64 %one, %e2
 %three = xor i64 %two, %e3
 %four = add i64 %three, %e4
 %mixed = xor i64 %four, %wide
 %with_a = xor i64 %mixed, %aw
 %answer = xor i64 %with_a, %bw
 ret i64 %answer
}
define i64 @half_product_33(i16 %a, i16 %b, i64 %live, i64 %e1, i64 %e2, i64 %e3, i64 %e4, ptr %out) {
entry:
 %left = bitcast i16 %a to half
 %right = bitcast i16 %b to half
 %loaded = load half, ptr %out, align 1
 %raw = fneg half %loaded
 %bits = bitcast half %raw to i16
 store i16 %bits, ptr %out, align 1
 %wide = zext i16 %bits to i64
 %aw = zext i16 %a to i64
 %bw = zext i16 %b to i64
 %one = xor i64 %live, %e1
 %two = add i64 %one, %e2
 %three = xor i64 %two, %e3
 %four = add i64 %three, %e4
 %mixed = xor i64 %four, %wide
 %with_a = xor i64 %mixed, %aw
 %answer = xor i64 %with_a, %bw
 ret i64 %answer
}
define i64 @half_product_34(i16 %a, i16 %b, i64 %live, i64 %e1, i64 %e2, i64 %e3, i64 %e4, ptr %out) {
entry:
 %left = bitcast i16 %a to half
 %right = bitcast i16 %b to half

 %raw = fneg half 0xH0000
 %bits = bitcast half %raw to i16
 store i16 %bits, ptr %out, align 1
 %wide = zext i16 %bits to i64
 %aw = zext i16 %a to i64
 %bw = zext i16 %b to i64
 %one = xor i64 %live, %e1
 %two = add i64 %one, %e2
 %three = xor i64 %two, %e3
 %four = add i64 %three, %e4
 %mixed = xor i64 %four, %wide
 %with_a = xor i64 %mixed, %aw
 %answer = xor i64 %with_a, %bw
 ret i64 %answer
}
define i64 @half_product_35(i16 %a, i16 %b, i64 %live, i64 %e1, i64 %e2, i64 %e3, i64 %e4, ptr %out) {
entry:
 %left = bitcast i16 %a to half
 %right = bitcast i16 %b to half

 %raw = fneg half 0xH8000
 %bits = bitcast half %raw to i16
 store i16 %bits, ptr %out, align 1
 %wide = zext i16 %bits to i64
 %aw = zext i16 %a to i64
 %bw = zext i16 %b to i64
 %one = xor i64 %live, %e1
 %two = add i64 %one, %e2
 %three = xor i64 %two, %e3
 %four = add i64 %three, %e4
 %mixed = xor i64 %four, %wide
 %with_a = xor i64 %mixed, %aw
 %answer = xor i64 %with_a, %bw
 ret i64 %answer
}
define i64 @half_product_36(i16 %a, i16 %b, i64 %live, i64 %e1, i64 %e2, i64 %e3, i64 %e4, ptr %out) {
entry:
 %left = bitcast i16 %a to half
 %right = bitcast i16 %b to half

 %raw = fneg half 0xH0001
 %bits = bitcast half %raw to i16
 store i16 %bits, ptr %out, align 1
 %wide = zext i16 %bits to i64
 %aw = zext i16 %a to i64
 %bw = zext i16 %b to i64
 %one = xor i64 %live, %e1
 %two = add i64 %one, %e2
 %three = xor i64 %two, %e3
 %four = add i64 %three, %e4
 %mixed = xor i64 %four, %wide
 %with_a = xor i64 %mixed, %aw
 %answer = xor i64 %with_a, %bw
 ret i64 %answer
}
define i64 @half_product_37(i16 %a, i16 %b, i64 %live, i64 %e1, i64 %e2, i64 %e3, i64 %e4, ptr %out) {
entry:
 %left = bitcast i16 %a to half
 %right = bitcast i16 %b to half

 %raw = fneg half 0xH3C00
 %bits = bitcast half %raw to i16
 store i16 %bits, ptr %out, align 1
 %wide = zext i16 %bits to i64
 %aw = zext i16 %a to i64
 %bw = zext i16 %b to i64
 %one = xor i64 %live, %e1
 %two = add i64 %one, %e2
 %three = xor i64 %two, %e3
 %four = add i64 %three, %e4
 %mixed = xor i64 %four, %wide
 %with_a = xor i64 %mixed, %aw
 %answer = xor i64 %with_a, %bw
 ret i64 %answer
}
define i64 @half_product_38(i16 %a, i16 %b, i64 %live, i64 %e1, i64 %e2, i64 %e3, i64 %e4, ptr %out) {
entry:
 %left = bitcast i16 %a to half
 %right = bitcast i16 %b to half

 %raw = fneg half 0xH70E2
 %bits = bitcast half %raw to i16
 store i16 %bits, ptr %out, align 1
 %wide = zext i16 %bits to i64
 %aw = zext i16 %a to i64
 %bw = zext i16 %b to i64
 %one = xor i64 %live, %e1
 %two = add i64 %one, %e2
 %three = xor i64 %two, %e3
 %four = add i64 %three, %e4
 %mixed = xor i64 %four, %wide
 %with_a = xor i64 %mixed, %aw
 %answer = xor i64 %with_a, %bw
 ret i64 %answer
}
define i64 @half_product_39(i16 %a, i16 %b, i64 %live, i64 %e1, i64 %e2, i64 %e3, i64 %e4, ptr %out) {
entry:
 %left = bitcast i16 %a to half
 %right = bitcast i16 %b to half

 %raw = fneg half 0xH7C00
 %bits = bitcast half %raw to i16
 store i16 %bits, ptr %out, align 1
 %wide = zext i16 %bits to i64
 %aw = zext i16 %a to i64
 %bw = zext i16 %b to i64
 %one = xor i64 %live, %e1
 %two = add i64 %one, %e2
 %three = xor i64 %two, %e3
 %four = add i64 %three, %e4
 %mixed = xor i64 %four, %wide
 %with_a = xor i64 %mixed, %aw
 %answer = xor i64 %with_a, %bw
 ret i64 %answer
}
define i64 @half_product_40(i16 %a, i16 %b, i64 %live, i64 %e1, i64 %e2, i64 %e3, i64 %e4, ptr %out) {
entry:
 %left = bitcast i16 %a to half
 %right = bitcast i16 %b to half

 %raw = fneg half 0xH7E55
 %bits = bitcast half %raw to i16
 store i16 %bits, ptr %out, align 1
 %wide = zext i16 %bits to i64
 %aw = zext i16 %a to i64
 %bw = zext i16 %b to i64
 %one = xor i64 %live, %e1
 %two = add i64 %one, %e2
 %three = xor i64 %two, %e3
 %four = add i64 %three, %e4
 %mixed = xor i64 %four, %wide
 %with_a = xor i64 %mixed, %aw
 %answer = xor i64 %with_a, %bw
 ret i64 %answer
}
