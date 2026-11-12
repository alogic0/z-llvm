target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"
define fastcc i64 @wide_switch_body_129(i64 %seed,i129 %x,i64 %salt) noinline {
entry:
 switch i129 %x,label %other [ i129 -125,label %negative
 i129 125,label %positive
 i129 340282366920938463463374607431768211456,label %minimum
 i129 340282366920938463463374607431768211455,label %maximum ]
negative:
 br label %join
positive:
 br label %join
minimum:
 br label %join
maximum:
 br label %join
other:
 br label %join
join:
 %tag = phi i64 [1,%negative],[2,%positive],[3,%minimum],[4,%maximum],[5,%other]
 %added = add i64 %tag,%seed
 %r = xor i64 %added,%salt
 ret i64 %r
}
define i64 @wide_switch_129(ptr %input,ptr %out,i64 %salt) {
entry:
 %x = load i129,ptr %input,align 1
 %seed = load i64,ptr %input,align 1
 %r = call fastcc i64 @wide_switch_body_129(i64 %seed,i129 %x,i64 %salt)
 store i64 %r,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %out1,align 1
 %out2 = getelementptr i8,ptr %out,i64 16
 store i64 %seed,ptr %out2,align 1
 %live = add i64 %seed,%salt
 %answer = xor i64 %r,%live
 ret i64 %answer
}
define fastcc i64 @wide_switch_body_140(i64 %seed,i140 %x,i64 %salt) noinline {
entry:
 switch i140 %x,label %other [ i140 -125,label %negative
 i140 125,label %positive
 i140 696898287454081973172991196020261297061888,label %minimum
 i140 696898287454081973172991196020261297061887,label %maximum ]
negative:
 br label %join
positive:
 br label %join
minimum:
 br label %join
maximum:
 br label %join
other:
 br label %join
join:
 %tag = phi i64 [1,%negative],[2,%positive],[3,%minimum],[4,%maximum],[5,%other]
 %added = add i64 %tag,%seed
 %r = xor i64 %added,%salt
 ret i64 %r
}
define i64 @wide_switch_140(ptr %input,ptr %out,i64 %salt) {
entry:
 %x = load i140,ptr %input,align 1
 %seed = load i64,ptr %input,align 1
 %r = call fastcc i64 @wide_switch_body_140(i64 %seed,i140 %x,i64 %salt)
 store i64 %r,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %out1,align 1
 %out2 = getelementptr i8,ptr %out,i64 16
 store i64 %seed,ptr %out2,align 1
 %live = add i64 %seed,%salt
 %answer = xor i64 %r,%live
 ret i64 %answer
}
define fastcc i64 @wide_switch_body_200(i64 %seed,i200 %x,i64 %salt) noinline {
entry:
 switch i200 %x,label %other [ i200 -125,label %negative
 i200 125,label %positive
 i200 803469022129495137770981046170581301261101496891396417650688,label %minimum
 i200 803469022129495137770981046170581301261101496891396417650687,label %maximum ]
negative:
 br label %join
positive:
 br label %join
minimum:
 br label %join
maximum:
 br label %join
other:
 br label %join
join:
 %tag = phi i64 [1,%negative],[2,%positive],[3,%minimum],[4,%maximum],[5,%other]
 %added = add i64 %tag,%seed
 %r = xor i64 %added,%salt
 ret i64 %r
}
define i64 @wide_switch_200(ptr %input,ptr %out,i64 %salt) {
entry:
 %x = load i200,ptr %input,align 1
 %seed = load i64,ptr %input,align 1
 %r = call fastcc i64 @wide_switch_body_200(i64 %seed,i200 %x,i64 %salt)
 store i64 %r,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %out1,align 1
 %out2 = getelementptr i8,ptr %out,i64 16
 store i64 %seed,ptr %out2,align 1
 %live = add i64 %seed,%salt
 %answer = xor i64 %r,%live
 ret i64 %answer
}
define fastcc i64 @wide_switch_body_257(i64 %seed,i257 %x,i64 %salt) noinline {
entry:
 switch i257 %x,label %other [ i257 -125,label %negative
 i257 125,label %positive
 i257 115792089237316195423570985008687907853269984665640564039457584007913129639936,label %minimum
 i257 115792089237316195423570985008687907853269984665640564039457584007913129639935,label %maximum ]
negative:
 br label %join
positive:
 br label %join
minimum:
 br label %join
maximum:
 br label %join
other:
 br label %join
join:
 %tag = phi i64 [1,%negative],[2,%positive],[3,%minimum],[4,%maximum],[5,%other]
 %added = add i64 %tag,%seed
 %r = xor i64 %added,%salt
 ret i64 %r
}
define i64 @wide_switch_257(ptr %input,ptr %out,i64 %salt) {
entry:
 %x = load i257,ptr %input,align 1
 %seed = load i64,ptr %input,align 1
 %r = call fastcc i64 @wide_switch_body_257(i64 %seed,i257 %x,i64 %salt)
 store i64 %r,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %out1,align 1
 %out2 = getelementptr i8,ptr %out,i64 16
 store i64 %seed,ptr %out2,align 1
 %live = add i64 %seed,%salt
 %answer = xor i64 %r,%live
 ret i64 %answer
}
define fastcc i64 @wide_switch_body_500(i64 %seed,i500 %x,i64 %salt) noinline {
entry:
 switch i500 %x,label %other [ i500 -125,label %negative
 i500 125,label %positive
 i500 1636695303948070935006594848413799576108321023021532394741645684048066898202337277441635046162952078575443342063780035504608628272942696526664263794688,label %minimum
 i500 1636695303948070935006594848413799576108321023021532394741645684048066898202337277441635046162952078575443342063780035504608628272942696526664263794687,label %maximum ]
negative:
 br label %join
positive:
 br label %join
minimum:
 br label %join
maximum:
 br label %join
other:
 br label %join
join:
 %tag = phi i64 [1,%negative],[2,%positive],[3,%minimum],[4,%maximum],[5,%other]
 %added = add i64 %tag,%seed
 %r = xor i64 %added,%salt
 ret i64 %r
}
define i64 @wide_switch_500(ptr %input,ptr %out,i64 %salt) {
entry:
 %x = load i500,ptr %input,align 1
 %seed = load i64,ptr %input,align 1
 %r = call fastcc i64 @wide_switch_body_500(i64 %seed,i500 %x,i64 %salt)
 store i64 %r,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %out1,align 1
 %out2 = getelementptr i8,ptr %out,i64 16
 store i64 %seed,ptr %out2,align 1
 %live = add i64 %seed,%salt
 %answer = xor i64 %r,%live
 ret i64 %answer
}
define fastcc i64 @wide_switch_body_512(i64 %seed,i512 %x,i64 %salt) noinline {
entry:
 switch i512 %x,label %other [ i512 -125,label %negative
 i512 125,label %positive
 i512 6703903964971298549787012499102923063739682910296196688861780721860882015036773488400937149083451713845015929093243025426876941405973284973216824503042048,label %minimum
 i512 6703903964971298549787012499102923063739682910296196688861780721860882015036773488400937149083451713845015929093243025426876941405973284973216824503042047,label %maximum ]
negative:
 br label %join
positive:
 br label %join
minimum:
 br label %join
maximum:
 br label %join
other:
 br label %join
join:
 %tag = phi i64 [1,%negative],[2,%positive],[3,%minimum],[4,%maximum],[5,%other]
 %added = add i64 %tag,%seed
 %r = xor i64 %added,%salt
 ret i64 %r
}
define i64 @wide_switch_512(ptr %input,ptr %out,i64 %salt) {
entry:
 %x = load i512,ptr %input,align 1
 %seed = load i64,ptr %input,align 1
 %r = call fastcc i64 @wide_switch_body_512(i64 %seed,i512 %x,i64 %salt)
 store i64 %r,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %out1,align 1
 %out2 = getelementptr i8,ptr %out,i64 16
 store i64 %seed,ptr %out2,align 1
 %live = add i64 %seed,%salt
 %answer = xor i64 %r,%live
 ret i64 %answer
}
