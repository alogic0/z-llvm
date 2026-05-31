source_filename = "exports"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux5.10.0-gnu2.31.0"

%exports.T = type { i32 }

@exports.const_val = private unnamed_addr constant %exports.T { i32 42 }, align 4
@exports.mut_val = private unnamed_addr global double 1.230000e+00, align 8
@exports.hidden = private unnamed_addr global i32 0, align 4

@const_val = alias %exports.T, ptr @exports.const_val
@mut_val = alias double, ptr @exports.mut_val
@getHidden = alias i32 (), ptr @exports.getHidden
@updateHidden = alias void (i32), ptr @exports.updateHidden

define private i32 @exports.getHidden() unnamed_addr #0 align 1 {
0:
  %1 = load i32, ptr @exports.hidden, align 4
  ret i32 %1
}

define private void @exports.updateHidden(i32 %0) unnamed_addr #1 align 1 {
1:
  store i32 %0, ptr @exports.hidden, align 4
  ret void
}

attributes #0 = { minsize mustprogress nofree norecurse nosync nounwind optsize willreturn memory(read, argmem: none, inaccessiblemem: none, target_mem0: none, target_mem1: none) uwtable "frame-pointer"="all" }
attributes #1 = { minsize mustprogress nofree norecurse nosync nounwind optsize willreturn memory(write, argmem: none, inaccessiblemem: none, target_mem0: none, target_mem1: none) uwtable "frame-pointer"="all" }

!llvm.module.flags = !{}
