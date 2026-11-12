target triple = "x86_64-unknown-linux-gnu"
declare i128 @llvm.abs.i128(i128,i1)
define i128 @pair_absolute_body_0(i128 %a,i128 %b) noinline {
entry:
 %v = call i128 @llvm.abs.i128(i128 %a,i1 false)
 %r = xor i128 %v,%b
 ret i128 %r
}
declare i128 @pair_absolute_provider_0(i128,i128)
define i64 @pair_absolute_probe_0(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load i128,ptr %ap,align 1
 %b = load i128,ptr %bp,align 1
 %local = call i128 @pair_absolute_body_0(i128 %a,i128 %b)
 %external = call i128 @pair_absolute_provider_0(i128 %a,i128 %b)
 store i128 %local,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 16
 store i128 %external,ptr %next,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define i128 @pair_absolute_body_1(i128 %a,i128 %b) noinline {
entry:
 %v = call i128 @llvm.abs.i128(i128 %a,i1 true)
 %r = xor i128 %v,%b
 ret i128 %r
}
declare i128 @pair_absolute_provider_1(i128,i128)
define i64 @pair_absolute_probe_1(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load i128,ptr %ap,align 1
 %b = load i128,ptr %bp,align 1
 %local = call i128 @pair_absolute_body_1(i128 %a,i128 %b)
 %external = call i128 @pair_absolute_provider_1(i128 %a,i128 %b)
 store i128 %local,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 16
 store i128 %external,ptr %next,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc i128 @pair_absolute_body_2(i128 %a,i128 %b) noinline {
entry:
 %v = call i128 @llvm.abs.i128(i128 %a,i1 false)
 %r = xor i128 %v,%b
 ret i128 %r
}
declare i128 @pair_absolute_provider_2(i128,i128)
define i64 @pair_absolute_probe_2(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load i128,ptr %ap,align 1
 %b = load i128,ptr %bp,align 1
 %local = call fastcc i128 @pair_absolute_body_2(i128 %a,i128 %b)
 %external = call i128 @pair_absolute_provider_2(i128 %a,i128 %b)
 store i128 %local,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 16
 store i128 %external,ptr %next,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc i128 @pair_absolute_body_3(i128 %a,i128 %b) noinline {
entry:
 %v = call i128 @llvm.abs.i128(i128 %a,i1 true)
 %r = xor i128 %v,%b
 ret i128 %r
}
declare i128 @pair_absolute_provider_3(i128,i128)
define i64 @pair_absolute_probe_3(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load i128,ptr %ap,align 1
 %b = load i128,ptr %bp,align 1
 %local = call fastcc i128 @pair_absolute_body_3(i128 %a,i128 %b)
 %external = call i128 @pair_absolute_provider_3(i128 %a,i128 %b)
 store i128 %local,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 16
 store i128 %external,ptr %next,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
