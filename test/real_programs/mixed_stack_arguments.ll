target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"
declare i64 @mixed_stack_provider_0(i64,i64,i64,i64,i64,i64,i64,float,i128,i64)
define i64 @mixed_stack_probe_0(ptr %input,i64 %fpbits,i64 %salt) {
entry:
 %pair = load i128,ptr %input,align 1
 %low = trunc i64 %fpbits to i32
 %fp = bitcast i32 %low to float
 %result = call i64 @mixed_stack_provider_0(i64 1311768467463790320,i64 18364758544493064720,i64 1234605616436508552,i64 12379552201711258095,i64 9756277981056907928,i64 1161981756646125696,i64 17381532669550570720,float %fp,i128 %pair,i64 %salt)
 ret i64 %result
}
declare i64 @mixed_stack_provider_1(i64,i64,i64,i64,i64,i64,i64,double,i128,i64)
define i64 @mixed_stack_probe_1(ptr %input,i64 %fpbits,i64 %salt) {
entry:
 %pair = load i128,ptr %input,align 1
 %fp = bitcast i64 %fpbits to double
 %result = call i64 @mixed_stack_provider_1(i64 1311768467463790320,i64 18364758544493064720,i64 1234605616436508552,i64 12379552201711258095,i64 9756277981056907928,i64 1161981756646125696,i64 17381532669550570720,double %fp,i128 %pair,i64 %salt)
 ret i64 %result
}
declare i64 @mixed_stack_provider_2(i64,i64,i64,i64,i64,i64,i64,<2 x double>,i128,i64)
define i64 @mixed_stack_probe_2(ptr %input,i64 %fpbits,i64 %salt) {
entry:
 %pair = load i128,ptr %input,align 1
 %fp = load <2 x double>,ptr %input,align 1
 %result = call i64 @mixed_stack_provider_2(i64 1311768467463790320,i64 18364758544493064720,i64 1234605616436508552,i64 12379552201711258095,i64 9756277981056907928,i64 1161981756646125696,i64 17381532669550570720,<2 x double> %fp,i128 %pair,i64 %salt)
 ret i64 %result
}
declare fastcc i64 @mixed_stack_provider_3(i64,i64,i64,i64,i64,i64,i64,float,i128,i64)
define i64 @mixed_stack_probe_3(ptr %input,i64 %fpbits,i64 %salt) {
entry:
 %pair = load i128,ptr %input,align 1
 %low = trunc i64 %fpbits to i32
 %fp = bitcast i32 %low to float
 %result = call fastcc i64 @mixed_stack_provider_3(i64 1311768467463790320,i64 18364758544493064720,i64 1234605616436508552,i64 12379552201711258095,i64 9756277981056907928,i64 1161981756646125696,i64 17381532669550570720,float %fp,i128 %pair,i64 %salt)
 ret i64 %result
}
declare fastcc i64 @mixed_stack_provider_4(i64,i64,i64,i64,i64,i64,i64,double,i128,i64)
define i64 @mixed_stack_probe_4(ptr %input,i64 %fpbits,i64 %salt) {
entry:
 %pair = load i128,ptr %input,align 1
 %fp = bitcast i64 %fpbits to double
 %result = call fastcc i64 @mixed_stack_provider_4(i64 1311768467463790320,i64 18364758544493064720,i64 1234605616436508552,i64 12379552201711258095,i64 9756277981056907928,i64 1161981756646125696,i64 17381532669550570720,double %fp,i128 %pair,i64 %salt)
 ret i64 %result
}
declare fastcc i64 @mixed_stack_provider_5(i64,i64,i64,i64,i64,i64,i64,<2 x double>,i128,i64)
define i64 @mixed_stack_probe_5(ptr %input,i64 %fpbits,i64 %salt) {
entry:
 %pair = load i128,ptr %input,align 1
 %fp = load <2 x double>,ptr %input,align 1
 %result = call fastcc i64 @mixed_stack_provider_5(i64 1311768467463790320,i64 18364758544493064720,i64 1234605616436508552,i64 12379552201711258095,i64 9756277981056907928,i64 1161981756646125696,i64 17381532669550570720,<2 x double> %fp,i128 %pair,i64 %salt)
 ret i64 %result
}
