target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"
define <3 x i32> @promoted_body_3_32_c(<3 x i32> %a,<3 x i32> %b) noinline {
entry:
 %r = add <3 x i32> %a,%b
 ret <3 x i32> %r
}
declare <3 x i32> @promoted_provider_3_32_c(<3 x i32>,<3 x i32>)
define i64 @promoted_probe_3_32_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <3 x i32>,ptr %ap,align 1
 %b = load <3 x i32>,ptr %bp,align 1
 %local = call <3 x i32> @promoted_body_3_32_c(<3 x i32> %a,<3 x i32> %b)
 %external = call <3 x i32> @promoted_provider_3_32_c(<3 x i32> %a,<3 x i32> %b)
 store <3 x i32> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <3 x i32> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <3 x i32> @promoted_body_3_32_fast(<3 x i32> %a,<3 x i32> %b) noinline {
entry:
 %r = add <3 x i32> %a,%b
 ret <3 x i32> %r
}
declare fastcc <3 x i32> @promoted_provider_3_32_fast(<3 x i32>,<3 x i32>)
define i64 @promoted_probe_3_32_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <3 x i32>,ptr %ap,align 1
 %b = load <3 x i32>,ptr %bp,align 1
 %local = call fastcc <3 x i32> @promoted_body_3_32_fast(<3 x i32> %a,<3 x i32> %b)
 %external = call fastcc <3 x i32> @promoted_provider_3_32_fast(<3 x i32> %a,<3 x i32> %b)
 store <3 x i32> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <3 x i32> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
