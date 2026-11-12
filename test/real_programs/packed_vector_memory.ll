target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
declare i1 @llvm.vector.reduce.umin.v3i1(<3 x i1>)
define i64 @packed_memory_3_1(ptr %input,ptr %output,i64 %live) {
entry:
 %v = load <3 x i1>,ptr %input,align 1
 %w = xor <3 x i1> %v,splat (i1 -1)
 store <3 x i1> %w,ptr %output,align 1
 %r = call i1 @llvm.vector.reduce.umin.v3i1(<3 x i1> %v)
 %wide = zext i1 %r to i64
 %answer = xor i64 %wide,%live
 ret i64 %answer
}
declare i3 @llvm.vector.reduce.umin.v8i3(<8 x i3>)
define i64 @packed_memory_8_3(ptr %input,ptr %output,i64 %live) {
entry:
 %v = load <8 x i3>,ptr %input,align 1
 %w = xor <8 x i3> %v,splat (i3 -1)
 store <8 x i3> %w,ptr %output,align 1
 %r = call i3 @llvm.vector.reduce.umin.v8i3(<8 x i3> %v)
 %wide = zext i3 %r to i64
 %answer = xor i64 %wide,%live
 ret i64 %answer
}
declare i9 @llvm.vector.reduce.umin.v7i9(<7 x i9>)
define i64 @packed_memory_7_9(ptr %input,ptr %output,i64 %live) {
entry:
 %v = load <7 x i9>,ptr %input,align 1
 %w = xor <7 x i9> %v,splat (i9 -1)
 store <7 x i9> %w,ptr %output,align 1
 %r = call i9 @llvm.vector.reduce.umin.v7i9(<7 x i9> %v)
 %wide = zext i9 %r to i64
 %answer = xor i64 %wide,%live
 ret i64 %answer
}
declare i17 @llvm.vector.reduce.umin.v5i17(<5 x i17>)
define i64 @packed_memory_5_17(ptr %input,ptr %output,i64 %live) {
entry:
 %v = load <5 x i17>,ptr %input,align 1
 %w = xor <5 x i17> %v,splat (i17 -1)
 store <5 x i17> %w,ptr %output,align 1
 %r = call i17 @llvm.vector.reduce.umin.v5i17(<5 x i17> %v)
 %wide = zext i17 %r to i64
 %answer = xor i64 %wide,%live
 ret i64 %answer
}
declare i33 @llvm.vector.reduce.umin.v3i33(<3 x i33>)
define i64 @packed_memory_3_33(ptr %input,ptr %output,i64 %live) {
entry:
 %v = load <3 x i33>,ptr %input,align 1
 %w = xor <3 x i33> %v,splat (i33 -1)
 store <3 x i33> %w,ptr %output,align 1
 %r = call i33 @llvm.vector.reduce.umin.v3i33(<3 x i33> %v)
 %wide = zext i33 %r to i64
 %answer = xor i64 %wide,%live
 ret i64 %answer
}
