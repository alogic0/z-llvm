target triple = "x86_64-unknown-linux-gnu"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
declare <64 x x86_fp80> @llvm.fabs.v64f80(<64 x x86_fp80>)

define void @frame_compact_abs64(ptr %input, ptr %output) {
entry:
 %v = load <64 x x86_fp80>, ptr %input, align 1
 %r = call <64 x x86_fp80> @llvm.fabs.v64f80(<64 x x86_fp80> %v)
 store <64 x x86_fp80> %r, ptr %output, align 1
 ret void
}
