target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"
declare i1 @boolean_wide_65_0_0_provider(i65,i64)
define i64 @boolean_wide_65_0_0(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load i65,ptr %input,align 1
 %r = call i1 @boolean_wide_65_0_0_provider(i65 %v,i64 %salt)
 store i1 %r,ptr %out,align 1
 %saved = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %saved,align 1
 %z = zext i1 %r to i64
 %answer = xor i64 %z,%salt
 ret i64 %answer
}
declare fastcc i1 @boolean_wide_65_0_1_provider(i65,i64)
define fastcc i64 @boolean_wide_65_0_1(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load i65,ptr %input,align 1
 %r = call fastcc i1 @boolean_wide_65_0_1_provider(i65 %v,i64 %salt)
 store i1 %r,ptr %out,align 1
 %saved = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %saved,align 1
 %z = zext i1 %r to i64
 %answer = xor i64 %z,%salt
 ret i64 %answer
}
declare i1 @boolean_wide_96_0_0_provider(i96,i64)
define i64 @boolean_wide_96_0_0(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load i96,ptr %input,align 1
 %r = call i1 @boolean_wide_96_0_0_provider(i96 %v,i64 %salt)
 store i1 %r,ptr %out,align 1
 %saved = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %saved,align 1
 %z = zext i1 %r to i64
 %answer = xor i64 %z,%salt
 ret i64 %answer
}
declare fastcc i1 @boolean_wide_96_0_1_provider(i96,i64)
define fastcc i64 @boolean_wide_96_0_1(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load i96,ptr %input,align 1
 %r = call fastcc i1 @boolean_wide_96_0_1_provider(i96 %v,i64 %salt)
 store i1 %r,ptr %out,align 1
 %saved = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %saved,align 1
 %z = zext i1 %r to i64
 %answer = xor i64 %z,%salt
 ret i64 %answer
}
declare i1 @boolean_wide_127_0_0_provider(i127,i64)
define i64 @boolean_wide_127_0_0(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load i127,ptr %input,align 1
 %r = call i1 @boolean_wide_127_0_0_provider(i127 %v,i64 %salt)
 store i1 %r,ptr %out,align 1
 %saved = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %saved,align 1
 %z = zext i1 %r to i64
 %answer = xor i64 %z,%salt
 ret i64 %answer
}
declare fastcc i1 @boolean_wide_127_0_1_provider(i127,i64)
define fastcc i64 @boolean_wide_127_0_1(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load i127,ptr %input,align 1
 %r = call fastcc i1 @boolean_wide_127_0_1_provider(i127 %v,i64 %salt)
 store i1 %r,ptr %out,align 1
 %saved = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %saved,align 1
 %z = zext i1 %r to i64
 %answer = xor i64 %z,%salt
 ret i64 %answer
}
declare i1 @boolean_wide_128_0_0_provider(i128,i64)
define i64 @boolean_wide_128_0_0(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load i128,ptr %input,align 1
 %r = call i1 @boolean_wide_128_0_0_provider(i128 %v,i64 %salt)
 store i1 %r,ptr %out,align 1
 %saved = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %saved,align 1
 %z = zext i1 %r to i64
 %answer = xor i64 %z,%salt
 ret i64 %answer
}
declare fastcc i1 @boolean_wide_128_0_1_provider(i128,i64)
define fastcc i64 @boolean_wide_128_0_1(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load i128,ptr %input,align 1
 %r = call fastcc i1 @boolean_wide_128_0_1_provider(i128 %v,i64 %salt)
 store i1 %r,ptr %out,align 1
 %saved = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %saved,align 1
 %z = zext i1 %r to i64
 %answer = xor i64 %z,%salt
 ret i64 %answer
}
declare i1 @boolean_wide_128_1_0_provider(i128,i64)
define i64 @boolean_wide_128_1_0(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load i128,ptr %input,align 1
 %r = call i1 @boolean_wide_128_1_0_provider(i128 %v,i64 %salt)
 store i1 %r,ptr %out,align 1
 %saved = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %saved,align 1
 %z = zext i1 %r to i64
 %answer = xor i64 %z,%salt
 ret i64 %answer
}
declare fastcc i1 @boolean_wide_128_1_1_provider(i128,i64)
define fastcc i64 @boolean_wide_128_1_1(ptr %out,ptr %input,i64 %salt) noinline {
entry:
 %v = load i128,ptr %input,align 1
 %r = call fastcc i1 @boolean_wide_128_1_1_provider(i128 %v,i64 %salt)
 store i1 %r,ptr %out,align 1
 %saved = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %saved,align 1
 %z = zext i1 %r to i64
 %answer = xor i64 %z,%salt
 ret i64 %answer
}
