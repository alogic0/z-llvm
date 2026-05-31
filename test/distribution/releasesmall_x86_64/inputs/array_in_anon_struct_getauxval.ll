source_filename = "array_in_anon_struct"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

@os.linux.elf_aux_maybe = private unnamed_addr global ptr null, align 8
@getauxval = weak_odr alias i64 (i64), ptr @os.linux.getauxvalImpl

define private i64 @os.linux.getauxvalImpl(i64 %0) unnamed_addr align 1 {
1:
  %2 = load ptr, ptr @os.linux.elf_aux_maybe, align 8
  %.not = icmp eq ptr %2, null
  br i1 %.not, label %common.ret, label %.preheader
common.ret:
  %common.ret.op = phi i64 [ %10, %8 ], [ 0, %1 ], [ 0, %.preheader ]
  ret i64 %common.ret.op
.preheader:
  %.0 = phi i64 [ %7, %5 ], [ 0, %1 ]
  %3 = getelementptr [16 x i8], ptr %2, i64 %.0
  %4 = load i64, ptr %3, align 8
  %.not8 = icmp eq i64 %4, 0
  br i1 %.not8, label %common.ret, label %5
5:
  %6 = icmp eq i64 %4, %0
  %7 = add nuw i64 %.0, 1
  br i1 %6, label %8, label %.preheader
8:
  %9 = getelementptr i8, ptr %3, i64 8
  %10 = load i64, ptr %9, align 8
  br label %common.ret
}
