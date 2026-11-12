target triple = "x86_64-unknown-linux-gnu"
declare i128 @llvm.uadd.sat.i128(i128,i128)
define i128 @pair_saturation_body_0(i128 %a,i128 %b) noinline {
entry:
 %r = call i128 @llvm.uadd.sat.i128(i128 %a,i128 %b)
 ret i128 %r
}
declare i128 @pair_saturation_provider_0(i128,i128)
define i64 @pair_saturation_probe_0(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load i128,ptr %ap,align 1
 %b = load i128,ptr %bp,align 1
 %local = call i128 @pair_saturation_body_0(i128 %a,i128 %b)
 %external = call i128 @pair_saturation_provider_0(i128 %a,i128 %b)
 store i128 %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store i128 %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i128 @llvm.usub.sat.i128(i128,i128)
define i128 @pair_saturation_body_1(i128 %a,i128 %b) noinline {
entry:
 %r = call i128 @llvm.usub.sat.i128(i128 %a,i128 %b)
 ret i128 %r
}
declare i128 @pair_saturation_provider_1(i128,i128)
define i64 @pair_saturation_probe_1(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load i128,ptr %ap,align 1
 %b = load i128,ptr %bp,align 1
 %local = call i128 @pair_saturation_body_1(i128 %a,i128 %b)
 %external = call i128 @pair_saturation_provider_1(i128 %a,i128 %b)
 store i128 %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store i128 %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i128 @llvm.sadd.sat.i128(i128,i128)
define i128 @pair_saturation_body_2(i128 %a,i128 %b) noinline {
entry:
 %r = call i128 @llvm.sadd.sat.i128(i128 %a,i128 %b)
 ret i128 %r
}
declare i128 @pair_saturation_provider_2(i128,i128)
define i64 @pair_saturation_probe_2(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load i128,ptr %ap,align 1
 %b = load i128,ptr %bp,align 1
 %local = call i128 @pair_saturation_body_2(i128 %a,i128 %b)
 %external = call i128 @pair_saturation_provider_2(i128 %a,i128 %b)
 store i128 %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store i128 %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i128 @llvm.ssub.sat.i128(i128,i128)
define i128 @pair_saturation_body_3(i128 %a,i128 %b) noinline {
entry:
 %r = call i128 @llvm.ssub.sat.i128(i128 %a,i128 %b)
 ret i128 %r
}
declare i128 @pair_saturation_provider_3(i128,i128)
define i64 @pair_saturation_probe_3(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load i128,ptr %ap,align 1
 %b = load i128,ptr %bp,align 1
 %local = call i128 @pair_saturation_body_3(i128 %a,i128 %b)
 %external = call i128 @pair_saturation_provider_3(i128 %a,i128 %b)
 store i128 %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store i128 %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i128 @llvm.umin.i128(i128,i128)
define i128 @pair_saturation_body_4(i128 %a,i128 %b) noinline {
entry:
 %r = call i128 @llvm.umin.i128(i128 %a,i128 %b)
 ret i128 %r
}
declare i128 @pair_saturation_provider_4(i128,i128)
define i64 @pair_saturation_probe_4(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load i128,ptr %ap,align 1
 %b = load i128,ptr %bp,align 1
 %local = call i128 @pair_saturation_body_4(i128 %a,i128 %b)
 %external = call i128 @pair_saturation_provider_4(i128 %a,i128 %b)
 store i128 %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store i128 %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i128 @llvm.umax.i128(i128,i128)
define i128 @pair_saturation_body_5(i128 %a,i128 %b) noinline {
entry:
 %r = call i128 @llvm.umax.i128(i128 %a,i128 %b)
 ret i128 %r
}
declare i128 @pair_saturation_provider_5(i128,i128)
define i64 @pair_saturation_probe_5(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load i128,ptr %ap,align 1
 %b = load i128,ptr %bp,align 1
 %local = call i128 @pair_saturation_body_5(i128 %a,i128 %b)
 %external = call i128 @pair_saturation_provider_5(i128 %a,i128 %b)
 store i128 %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store i128 %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i128 @llvm.smin.i128(i128,i128)
define i128 @pair_saturation_body_6(i128 %a,i128 %b) noinline {
entry:
 %r = call i128 @llvm.smin.i128(i128 %a,i128 %b)
 ret i128 %r
}
declare i128 @pair_saturation_provider_6(i128,i128)
define i64 @pair_saturation_probe_6(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load i128,ptr %ap,align 1
 %b = load i128,ptr %bp,align 1
 %local = call i128 @pair_saturation_body_6(i128 %a,i128 %b)
 %external = call i128 @pair_saturation_provider_6(i128 %a,i128 %b)
 store i128 %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store i128 %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare i128 @llvm.smax.i128(i128,i128)
define i128 @pair_saturation_body_7(i128 %a,i128 %b) noinline {
entry:
 %r = call i128 @llvm.smax.i128(i128 %a,i128 %b)
 ret i128 %r
}
declare i128 @pair_saturation_provider_7(i128,i128)
define i64 @pair_saturation_probe_7(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load i128,ptr %ap,align 1
 %b = load i128,ptr %bp,align 1
 %local = call i128 @pair_saturation_body_7(i128 %a,i128 %b)
 %external = call i128 @pair_saturation_provider_7(i128 %a,i128 %b)
 store i128 %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store i128 %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
