target triple = "x86_64-unknown-linux-gnu"
declare i64 @storage_boundaries_clobber(i64)
@storage_table32 = external global [16 x i32]
@storage_table64 = external global [16 x i64]
define i64 @storage_boundaries_fp32_0(i64 %raw,ptr %input,ptr %output,i64 %live) {
entry:
 %index = and i64 %raw,15
 %table = getelementptr [4 x i8],ptr @storage_table32,i64 %index
 %loaded = load float,ptr %table,align 1
 %saved = call i64 @storage_boundaries_clobber(i64 %live)
 %narrow = trunc i64 %raw to i32
 store i32 %narrow,ptr %input,align 1
 %bits = bitcast float %loaded to i32
 store i32 %bits,ptr %output,align 1
 %wide = zext i32 %bits to i64
 %answer = xor i64 %wide,%saved
 ret i64 %answer
}
define i64 @storage_boundaries_fp32_1(i64 %raw,ptr %input,ptr %output,i64 %live) {
entry:
 %index = and i64 %raw,15
 %table = getelementptr [4 x i8],ptr @storage_table32,i64 %index
 %choice = trunc i64 %live to i1
 br i1 %choice,label %left,label %right
left:
 br label %join
right:
 br label %join
join:
 %pointer = phi ptr [ %table,%left ],[ %input,%right ]
 %loaded = load float,ptr %pointer,align 1
 %saved = call i64 @storage_boundaries_clobber(i64 %live)
 %narrow = trunc i64 %raw to i32
 store i32 %narrow,ptr %input,align 1
 %bits = bitcast float %loaded to i32
 store i32 %bits,ptr %output,align 1
 %wide = zext i32 %bits to i64
 %answer = xor i64 %wide,%saved
 ret i64 %answer
}
define i64 @storage_boundaries_fp64_0(i64 %raw,ptr %input,ptr %output,i64 %live) {
entry:
 %index = and i64 %raw,15
 %table = getelementptr [8 x i8],ptr @storage_table64,i64 %index
 %loaded = load double,ptr %table,align 1
 %saved = call i64 @storage_boundaries_clobber(i64 %live)
 store i64 %raw,ptr %input,align 1
 %bits = bitcast double %loaded to i64
 store i64 %bits,ptr %output,align 1
 %answer = xor i64 %bits,%saved
 ret i64 %answer
}
define i64 @storage_boundaries_fp64_1(i64 %raw,ptr %input,ptr %output,i64 %live) {
entry:
 %index = and i64 %raw,15
 %table = getelementptr [8 x i8],ptr @storage_table64,i64 %index
 %choice = trunc i64 %live to i1
 br i1 %choice,label %left,label %right
left:
 br label %join
right:
 br label %join
join:
 %pointer = phi ptr [ %table,%left ],[ %input,%right ]
 %loaded = load double,ptr %pointer,align 1
 %saved = call i64 @storage_boundaries_clobber(i64 %live)
 store i64 %raw,ptr %input,align 1
 %bits = bitcast double %loaded to i64
 store i64 %bits,ptr %output,align 1
 %answer = xor i64 %bits,%saved
 ret i64 %answer
}
define i64 @storage_boundaries_object131072(i64 %raw,ptr %input,ptr %output,i64 %live) {
entry:
 %slot = alloca [131072 x i8],align 16
 %guard = alloca i64,align 8
 %tail = getelementptr i8,ptr %slot,i64 131071
 %middle = getelementptr i8,ptr %slot,i64 4096
 %head = trunc i64 %raw to i8
 %last = trunc i64 %live to i8
 %mix = xor i8 %head,%last
 store i64 %raw,ptr %guard,align 8
 store i8 %head,ptr %slot,align 1
 store i8 %last,ptr %tail,align 1
 store i8 %mix,ptr %middle,align 1
 %saved = call i64 @storage_boundaries_clobber(i64 %live)
 %h = load i8,ptr %slot,align 1
 %t = load i8,ptr %tail,align 1
 %m = load i8,ptr %middle,align 1
 %g = load i64,ptr %guard,align 8
 %hw = zext i8 %h to i64
 %tw = zext i8 %t to i64
 %mw = zext i8 %m to i64
 %ts = shl i64 %tw,8
 %ms = shl i64 %mw,16
 %one = or i64 %hw,%ts
 %two = or i64 %one,%ms
 %value = xor i64 %two,%g
 store i64 %value,ptr %output,align 1
 %answer = xor i64 %value,%saved
 ret i64 %answer
}
define i64 @storage_boundaries_object2300000(i64 %raw,ptr %input,ptr %output,i64 %live) {
entry:
 %slot = alloca [2300000 x i8],align 16
 %guard = alloca i64,align 8
 %tail = getelementptr i8,ptr %slot,i64 2299999
 %middle = getelementptr i8,ptr %slot,i64 4096
 %head = trunc i64 %raw to i8
 %last = trunc i64 %live to i8
 %mix = xor i8 %head,%last
 store i64 %raw,ptr %guard,align 8
 store i8 %head,ptr %slot,align 1
 store i8 %last,ptr %tail,align 1
 store i8 %mix,ptr %middle,align 1
 %saved = call i64 @storage_boundaries_clobber(i64 %live)
 %h = load i8,ptr %slot,align 1
 %t = load i8,ptr %tail,align 1
 %m = load i8,ptr %middle,align 1
 %g = load i64,ptr %guard,align 8
 %hw = zext i8 %h to i64
 %tw = zext i8 %t to i64
 %mw = zext i8 %m to i64
 %ts = shl i64 %tw,8
 %ms = shl i64 %mw,16
 %one = or i64 %hw,%ts
 %two = or i64 %one,%ms
 %value = xor i64 %two,%g
 store i64 %value,ptr %output,align 1
 %answer = xor i64 %value,%saved
 ret i64 %answer
}
define i64 @storage_boundaries_object4194304(i64 %raw,ptr %input,ptr %output,i64 %live) {
entry:
 %slot = alloca [4194304 x i8],align 16
 %guard = alloca i64,align 8
 %tail = getelementptr i8,ptr %slot,i64 4194303
 %middle = getelementptr i8,ptr %slot,i64 4096
 %head = trunc i64 %raw to i8
 %last = trunc i64 %live to i8
 %mix = xor i8 %head,%last
 store i64 %raw,ptr %guard,align 8
 store i8 %head,ptr %slot,align 1
 store i8 %last,ptr %tail,align 1
 store i8 %mix,ptr %middle,align 1
 %saved = call i64 @storage_boundaries_clobber(i64 %live)
 %h = load i8,ptr %slot,align 1
 %t = load i8,ptr %tail,align 1
 %m = load i8,ptr %middle,align 1
 %g = load i64,ptr %guard,align 8
 %hw = zext i8 %h to i64
 %tw = zext i8 %t to i64
 %mw = zext i8 %m to i64
 %ts = shl i64 %tw,8
 %ms = shl i64 %mw,16
 %one = or i64 %hw,%ts
 %two = or i64 %one,%ms
 %value = xor i64 %two,%g
 store i64 %value,ptr %output,align 1
 %answer = xor i64 %value,%saved
 ret i64 %answer
}
