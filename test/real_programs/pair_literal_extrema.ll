target triple = "x86_64-unknown-linux-gnu"
declare i128 @llvm.umin.i128(i128,i128)
declare i128 @llvm.umax.i128(i128,i128)
define i128 @pair_literal_extrema_body_8(i128 %a,i128 %b) noinline {
entry:
 %r = call i128 @llvm.umin.i128(i128 -2,i128 %b)
 ret i128 %r
}
declare i128 @pair_literal_extrema_provider_8(i128,i128)
define i64 @pair_literal_extrema_probe_8(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load i128,ptr %ap,align 1
 %b = load i128,ptr %bp,align 1
 %local = call i128 @pair_literal_extrema_body_8(i128 %a,i128 %b)
 %external = call i128 @pair_literal_extrema_provider_8(i128 %a,i128 %b)
 store i128 %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store i128 %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define i128 @pair_literal_extrema_body_9(i128 %a,i128 %b) noinline {
entry:
 %r = call i128 @llvm.umax.i128(i128 -2,i128 %b)
 ret i128 %r
}
declare i128 @pair_literal_extrema_provider_9(i128,i128)
define i64 @pair_literal_extrema_probe_9(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load i128,ptr %ap,align 1
 %b = load i128,ptr %bp,align 1
 %local = call i128 @pair_literal_extrema_body_9(i128 %a,i128 %b)
 %external = call i128 @pair_literal_extrema_provider_9(i128 %a,i128 %b)
 store i128 %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store i128 %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define i128 @pair_literal_extrema_body_10(i128 %a,i128 %b) noinline {
entry:
 %r = call i128 @llvm.umin.i128(i128 %a,i128 -2)
 ret i128 %r
}
declare i128 @pair_literal_extrema_provider_10(i128,i128)
define i64 @pair_literal_extrema_probe_10(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load i128,ptr %ap,align 1
 %b = load i128,ptr %bp,align 1
 %local = call i128 @pair_literal_extrema_body_10(i128 %a,i128 %b)
 %external = call i128 @pair_literal_extrema_provider_10(i128 %a,i128 %b)
 store i128 %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store i128 %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define i128 @pair_literal_extrema_body_11(i128 %a,i128 %b) noinline {
entry:
 %r = call i128 @llvm.umax.i128(i128 %a,i128 -2)
 ret i128 %r
}
declare i128 @pair_literal_extrema_provider_11(i128,i128)
define i64 @pair_literal_extrema_probe_11(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load i128,ptr %ap,align 1
 %b = load i128,ptr %bp,align 1
 %local = call i128 @pair_literal_extrema_body_11(i128 %a,i128 %b)
 %external = call i128 @pair_literal_extrema_provider_11(i128 %a,i128 %b)
 store i128 %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store i128 %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
