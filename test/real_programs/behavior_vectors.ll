target triple = "x86_64-unknown-linux-gnu"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
@"behavior vector nan" = internal constant <1 x float> splat (float 0x7FF8000000000000), align 4
@"behavior vector extended" = internal constant <3 x x86_fp80> <x86_fp80 0xK00000000000000000001, x86_fp80 0xK80000000000000000000, x86_fp80 0xK7FFF8000000000000001>, align 32
@"behavior vector nested" = internal constant { i8, <3 x float>, i8 } { i8 7, <3 x float> <float 1.0, float -0.0, float 0x7FF0000020000000>, i8 9 }, align 16
@"behavior pointer cell" = internal constant ptr @"behavior vector extended", align 8
declare <3 x x86_fp80> @llvm.fabs.v3f80(<3 x x86_fp80>)
declare <64 x x86_fp80> @llvm.fabs.v64f80(<64 x x86_fp80>)

define ptr @behavior_vector_nan() {
entry:
 ret ptr @"behavior vector nan"
}
define ptr @behavior_vector_extended() {
entry:
 ret ptr @"behavior vector extended"
}
define ptr @behavior_vector_nested() {
entry:
 ret ptr @"behavior vector nested"
}
define ptr @behavior_vector_pointer() {
entry:
 %p = load ptr, ptr @"behavior pointer cell", align 8
 ret ptr %p
}
define void @behavior_vector_abs3(ptr %input, ptr %output) {
entry:
 %v = load <3 x x86_fp80>, ptr %input, align 1
 %r = call <3 x x86_fp80> @llvm.fabs.v3f80(<3 x x86_fp80> %v)
 store <3 x x86_fp80> %r, ptr %output, align 1
 ret void
}
define void @behavior_vector_abs64(ptr %input, ptr %output) {
entry:
 %v = load <64 x x86_fp80>, ptr %input, align 1
 %r = call <64 x x86_fp80> @llvm.fabs.v64f80(<64 x x86_fp80> %v)
 store <64 x x86_fp80> %r, ptr %output, align 1
 ret void
}
define void @behavior_vector_phi3(i32 %condition, ptr %input, ptr %output) {
entry:
 %test = icmp ne i32 %condition, 0
 %v = load <3 x x86_fp80>, ptr %input, align 1
 br i1 %test, label %yes, label %no
yes:
 br label %join
no:
 br label %join
join:
 %r = phi <3 x x86_fp80> [ %v, %yes ], [ zeroinitializer, %no ]
 store <3 x x86_fp80> %r, ptr %output, align 1
 ret void
}
define i64 @behavior_vector_compare3(ptr %left, ptr %right) {
entry:
 %x = load <3 x x86_fp80>, ptr %left, align 1
 %y = load <3 x x86_fp80>, ptr %right, align 1
 %c = fcmp ole <3 x x86_fp80> %x, %y
 %bits = bitcast <3 x i1> %c to i3
 %r = zext i3 %bits to i64
 ret i64 %r
}
define void @behavior_vector_stack3(ptr %input, ptr %output) {
entry:
 %slot = alloca <3 x x86_fp80>, align 16
 %v = load <3 x x86_fp80>, ptr %input, align 1
 store <3 x x86_fp80> %v, ptr %slot, align 1
 %r = load <3 x x86_fp80>, ptr %slot, align 1
 store <3 x x86_fp80> %r, ptr %output, align 1
 ret void
}
