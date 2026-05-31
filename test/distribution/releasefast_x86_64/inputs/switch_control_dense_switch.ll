source_filename = "switch_control"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux5.10.0-gnu2.31.0"

@switch.table.switch_control.dense_switch = private unnamed_addr constant [3 x i32] [i32 11, i32 13, i32 17], align 4
@dense_switch = alias i32 (i8), ptr @switch_control.dense_switch

define private range(i32 11, 24) i32 @switch_control.dense_switch(i8 zeroext %0) unnamed_addr #0 align 1 {
1:
  %2 = icmp ult i8 %0, 3
  br i1 %2, label %switch.lookup, label %6
switch.lookup:
  %3 = zext nneg i8 %0 to i64
  %switch.gep = getelementptr i32, ptr @switch.table.switch_control.dense_switch, i64 %3
  %switch.load = load i32, ptr %switch.gep, align 4
  br label %4
4:
  %5 = phi i32 [ %spec.select, %6 ], [ %switch.load, %switch.lookup ]
  ret i32 %5
6:
  %7 = add i8 %0, -3
  %8 = icmp ult i8 %7, 3
  %spec.select = select i1 %8, i32 19, i32 23
  br label %4
}

!llvm.module.flags = !{}
