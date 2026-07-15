; INBOX-54 exact captured __udivei5/__umodei4 bodies, linked and debug-stripped.
; Source md5: b0eda7a6427c3084fdf096a68696f19c.
; ModuleID = 'tmp/inbox54_rows.bc'
source_filename = "llvm-link"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux5.10.0-gnu2.31.0"

; Function Attrs: nofree norecurse nosync nounwind memory(argmem: readwrite, inaccessiblemem: write) uwtable
define hidden void @compiler_rt.udivmodei4.__udivei5(ptr nonnull writeonly align 1 captures(address) %0, ptr nonnull readonly align 1 captures(none) %1, ptr nonnull readonly align 1 captures(none) %2, ptr nonnull readnone align 1 captures(none) %3, i64 %4) unnamed_addr #0 align 1 {
Entry:
  %5 = alloca [2049 x i32], align 4
  %6 = alloca [2048 x i32], align 4
  %7 = icmp ult i64 %4, 65536
  tail call void @llvm.assume(i1 %7)
  %8 = trunc nuw i64 %4 to i16
  %9 = tail call fastcc i16 @zig.target.intByteSize(i16 %8) #5
  %10 = lshr i16 %9, 2
  %11 = zext nneg i16 %10 to i64
  %.idx = shl nuw nsw i64 %11, 2
  %12 = getelementptr inbounds nuw i8, ptr %0, i64 %.idx
  %.not398 = icmp eq i16 %10, 0
  br i1 %.not398, label %Block2, label %InlineMemsetBody.preheader

InlineMemsetBody.preheader:                       ; preds = %Entry
  %13 = add nsw i64 %.idx, -4
  %14 = lshr exact i64 %13, 2
  %15 = add nuw nsw i64 %14, 1
  %xtraiter = and i64 %15, 7
  %16 = and i64 %13, 28
  %lcmp.mod.not = icmp eq i64 %16, 28
  br i1 %lcmp.mod.not, label %InlineMemsetBody.prol.loopexit, label %InlineMemsetBody.prol

InlineMemsetBody.prol:                            ; preds = %InlineMemsetBody.prol, %InlineMemsetBody.preheader
  %17 = phi ptr [ %18, %InlineMemsetBody.prol ], [ %0, %InlineMemsetBody.preheader ]
  %prol.iter = phi i64 [ %prol.iter.next, %InlineMemsetBody.prol ], [ 0, %InlineMemsetBody.preheader ]
  store i32 0, ptr %17, align 4
  %18 = getelementptr inbounds nuw i8, ptr %17, i64 4
  %prol.iter.next = add i64 %prol.iter, 1
  %prol.iter.cmp.not = icmp eq i64 %prol.iter.next, %xtraiter
  br i1 %prol.iter.cmp.not, label %InlineMemsetBody.prol.loopexit, label %InlineMemsetBody.prol, !llvm.loop !2

InlineMemsetBody.prol.loopexit:                   ; preds = %InlineMemsetBody.prol, %InlineMemsetBody.preheader
  %.unr = phi ptr [ %0, %InlineMemsetBody.preheader ], [ %18, %InlineMemsetBody.prol ]
  %19 = icmp ult i64 %13, 28
  br i1 %19, label %Block2, label %InlineMemsetBody

Block1:                                           ; preds = %Block56, %Else5, %Then3
  ret void

Block2:                                           ; preds = %InlineMemsetBody, %InlineMemsetBody.prol.loopexit, %Entry
  %20 = icmp ne i16 %10, 0
  tail call void @llvm.assume(i1 %20)
  %21 = add nsw i64 %11, -1
  %22 = getelementptr inbounds [4 x i8], ptr %1, i64 %21
  %23 = load i32, ptr %22, align 4
  %24 = icmp eq i32 %23, 0
  br i1 %24, label %Then3, label %Loop1.preheader

InlineMemsetBody:                                 ; preds = %InlineMemsetBody, %InlineMemsetBody.prol.loopexit
  %25 = phi ptr [ %33, %InlineMemsetBody ], [ %.unr, %InlineMemsetBody.prol.loopexit ]
  store i32 0, ptr %25, align 4
  %26 = getelementptr inbounds nuw i8, ptr %25, i64 4
  store i32 0, ptr %26, align 4
  %27 = getelementptr inbounds nuw i8, ptr %25, i64 8
  store i32 0, ptr %27, align 4
  %28 = getelementptr inbounds nuw i8, ptr %25, i64 12
  store i32 0, ptr %28, align 4
  %29 = getelementptr inbounds nuw i8, ptr %25, i64 16
  store i32 0, ptr %29, align 4
  %30 = getelementptr inbounds nuw i8, ptr %25, i64 20
  store i32 0, ptr %30, align 4
  %31 = getelementptr inbounds nuw i8, ptr %25, i64 24
  store i32 0, ptr %31, align 4
  %32 = getelementptr inbounds nuw i8, ptr %25, i64 28
  store i32 0, ptr %32, align 4
  %33 = getelementptr inbounds nuw i8, ptr %25, i64 32
  %.not.7 = icmp eq ptr %33, %12
  br i1 %.not.7, label %Block2, label %InlineMemsetBody

Loop1.preheader:                                  ; preds = %Else4, %Block2
  %.0377.lcssa = phi i64 [ %21, %Block2 ], [ %38, %Else4 ]
  %.pre433 = phi i32 [ %23, %Block2 ], [ %40, %Else4 ]
  %34 = getelementptr inbounds [4 x i8], ptr %2, i64 %21
  %35 = load i32, ptr %34, align 4
  %36 = icmp eq i32 %35, 0
  br i1 %36, label %Then5, label %Else5

Then3:                                            ; preds = %Else4, %Block2
  %.0377399 = phi i64 [ %38, %Else4 ], [ %21, %Block2 ]
  %37 = icmp eq i64 %.0377399, 0
  br i1 %37, label %Block1, label %Else4

Else4:                                            ; preds = %Then3
  %38 = add nsw i64 %.0377399, -1
  %39 = getelementptr inbounds [4 x i8], ptr %1, i64 %38
  %40 = load i32, ptr %39, align 4
  %41 = icmp eq i32 %40, 0
  br i1 %41, label %Then3, label %Loop1.preheader

Then5:                                            ; preds = %Then5, %Loop1.preheader
  %.0376401 = phi i64 [ %43, %Then5 ], [ %21, %Loop1.preheader ]
  %42 = icmp ne i64 %.0376401, 0
  tail call void @llvm.assume(i1 %42)
  %43 = add i64 %.0376401, -1
  %44 = getelementptr inbounds [4 x i8], ptr %2, i64 %43
  %45 = load i32, ptr %44, align 4
  %46 = icmp eq i32 %45, 0
  br i1 %46, label %Then5, label %Else5

Else5:                                            ; preds = %Then5, %Loop1.preheader
  %.0376.lcssa = phi i64 [ %21, %Loop1.preheader ], [ %43, %Then5 ]
  %.lcssa = phi i32 [ %35, %Loop1.preheader ], [ %45, %Then5 ]
  %.0376.lcssa.fr = freeze i64 %.0376.lcssa
  %47 = icmp ugt i64 %.0376.lcssa.fr, %.0377.lcssa
  br i1 %47, label %Block1, label %Else7

Else7:                                            ; preds = %Else5
  %48 = tail call range(i32 0, 33) i32 @llvm.ctlz.i32(i32 %.lcssa, i1 true)
  %.fr419 = freeze i32 %48
  %49 = trunc i32 %.fr419 to i6
  %.not382404 = icmp eq i64 %.0376.lcssa.fr, 0
  %.pre434 = sub i6 -32, %49
  br i1 %.not382404, label %Else7.Else8_crit_edge, label %Then8.lr.ph

Else7.Else8_crit_edge:                            ; preds = %Else7
  %.pre435 = zext nneg i6 %.pre434 to i32
  br label %Else8

Then8.lr.ph:                                      ; preds = %Else7
  %50 = icmp sgt i6 %.pre434, -1
  %51 = zext nneg i6 %.pre434 to i32
  br i1 %50, label %Then8.us.preheader, label %Then8.preheader

Then8.preheader:                                  ; preds = %Then8.lr.ph
  %xtraiter477 = and i64 %.0376.lcssa.fr, 3
  %lcmp.mod478.not = icmp eq i64 %xtraiter477, 0
  br i1 %lcmp.mod478.not, label %Then8.prol.loopexit, label %Then8.prol

Then8.prol:                                       ; preds = %Then8.prol, %Then8.preheader
  %.0374405.prol = phi i64 [ %55, %Then8.prol ], [ %.0376.lcssa.fr, %Then8.preheader ]
  %prol.iter479 = phi i64 [ %prol.iter479.next, %Then8.prol ], [ 0, %Then8.preheader ]
  %52 = getelementptr inbounds [4 x i8], ptr %2, i64 %.0374405.prol
  %53 = load i32, ptr %52, align 4
  %54 = shl i32 %53, %.fr419
  %55 = add i64 %.0374405.prol, -1
  %56 = getelementptr inbounds [4 x i8], ptr %6, i64 %.0374405.prol
  store i32 %54, ptr %56, align 4
  %prol.iter479.next = add i64 %prol.iter479, 1
  %prol.iter479.cmp.not = icmp eq i64 %prol.iter479.next, %xtraiter477
  br i1 %prol.iter479.cmp.not, label %Then8.prol.loopexit, label %Then8.prol, !llvm.loop !4

Then8.prol.loopexit:                              ; preds = %Then8.prol, %Then8.preheader
  %.0374405.unr = phi i64 [ %.0376.lcssa.fr, %Then8.preheader ], [ %55, %Then8.prol ]
  %57 = icmp ult i64 %.0376.lcssa.fr, 4
  br i1 %57, label %Else8, label %Then8

Then8.us.preheader:                               ; preds = %Then8.lr.ph
  %.phi.trans.insert = getelementptr inbounds [4 x i8], ptr %2, i64 %.0376.lcssa.fr
  %.pre = load i32, ptr %.phi.trans.insert, align 4
  %xtraiter480 = and i64 %.0376.lcssa.fr, 1
  %lcmp.mod481.not = icmp eq i64 %xtraiter480, 0
  br i1 %lcmp.mod481.not, label %Then8.us.prol.loopexit, label %Then8.us.prol

Then8.us.prol:                                    ; preds = %Then8.us.preheader
  %58 = shl i32 %.pre, %.fr419
  %59 = add nsw i64 %.0376.lcssa.fr, -1
  %60 = getelementptr inbounds [4 x i8], ptr %2, i64 %59
  %61 = load i32, ptr %60, align 4
  %62 = lshr i32 %61, %51
  %63 = or i32 %62, %58
  %64 = getelementptr inbounds [4 x i8], ptr %6, i64 %.0376.lcssa.fr
  store i32 %63, ptr %64, align 4
  br label %Then8.us.prol.loopexit

Then8.us.prol.loopexit:                           ; preds = %Then8.us.prol, %Then8.us.preheader
  %.unr483 = phi i32 [ %.pre, %Then8.us.preheader ], [ %61, %Then8.us.prol ]
  %.0374405.us.unr = phi i64 [ %.0376.lcssa.fr, %Then8.us.preheader ], [ %59, %Then8.us.prol ]
  %65 = icmp eq i64 %.0376.lcssa.fr, 1
  br i1 %65, label %Else8, label %Then8.us

Then8.us:                                         ; preds = %Then8.us, %Then8.us.prol.loopexit
  %66 = phi i32 [ %77, %Then8.us ], [ %.unr483, %Then8.us.prol.loopexit ]
  %.0374405.us = phi i64 [ %75, %Then8.us ], [ %.0374405.us.unr, %Then8.us.prol.loopexit ]
  %67 = shl i32 %66, %.fr419
  %68 = add i64 %.0374405.us, -1
  %69 = getelementptr inbounds [4 x i8], ptr %2, i64 %68
  %70 = load i32, ptr %69, align 4
  %71 = lshr i32 %70, %51
  %72 = or i32 %71, %67
  %73 = getelementptr inbounds [4 x i8], ptr %6, i64 %.0374405.us
  store i32 %72, ptr %73, align 4
  %74 = shl i32 %70, %.fr419
  %75 = add i64 %.0374405.us, -2
  %76 = getelementptr inbounds [4 x i8], ptr %2, i64 %75
  %77 = load i32, ptr %76, align 4
  %78 = lshr i32 %77, %51
  %79 = or i32 %78, %74
  %80 = getelementptr inbounds [4 x i8], ptr %6, i64 %68
  store i32 %79, ptr %80, align 4
  %.not382.us.1 = icmp eq i64 %75, 0
  br i1 %.not382.us.1, label %Else8, label %Then8.us

Then8:                                            ; preds = %Then8, %Then8.prol.loopexit
  %.0374405 = phi i64 [ %99, %Then8 ], [ %.0374405.unr, %Then8.prol.loopexit ]
  %81 = getelementptr inbounds [4 x i8], ptr %2, i64 %.0374405
  %82 = load i32, ptr %81, align 4
  %83 = shl i32 %82, %.fr419
  %84 = add i64 %.0374405, -1
  %85 = getelementptr inbounds [4 x i8], ptr %6, i64 %.0374405
  store i32 %83, ptr %85, align 4
  %86 = getelementptr inbounds [4 x i8], ptr %2, i64 %84
  %87 = load i32, ptr %86, align 4
  %88 = shl i32 %87, %.fr419
  %89 = add i64 %.0374405, -2
  %90 = getelementptr inbounds [4 x i8], ptr %6, i64 %84
  store i32 %88, ptr %90, align 4
  %91 = getelementptr inbounds [4 x i8], ptr %2, i64 %89
  %92 = load i32, ptr %91, align 4
  %93 = shl i32 %92, %.fr419
  %94 = add i64 %.0374405, -3
  %95 = getelementptr inbounds [4 x i8], ptr %6, i64 %89
  store i32 %93, ptr %95, align 4
  %96 = getelementptr inbounds [4 x i8], ptr %2, i64 %94
  %97 = load i32, ptr %96, align 4
  %98 = shl i32 %97, %.fr419
  %99 = add i64 %.0374405, -4
  %100 = getelementptr inbounds [4 x i8], ptr %6, i64 %94
  store i32 %98, ptr %100, align 4
  %.not382.3 = icmp eq i64 %99, 0
  br i1 %.not382.3, label %Else8, label %Then8

Else8:                                            ; preds = %Then8, %Then8.us, %Then8.us.prol.loopexit, %Then8.prol.loopexit, %Else7.Else8_crit_edge
  %.pre-phi436 = phi i32 [ %.pre435, %Else7.Else8_crit_edge ], [ %51, %Then8.us.prol.loopexit ], [ %51, %Then8.us ], [ %51, %Then8 ], [ %51, %Then8.prol.loopexit ]
  %101 = load i32, ptr %2, align 4
  %102 = shl i32 %101, %.fr419
  store i32 %102, ptr %6, align 4
  %103 = icmp sgt i6 %.pre434, -1
  %104 = lshr i32 %.pre433, %.pre-phi436
  %common.ret.op.i389 = select i1 %103, i32 %104, i32 0
  %105 = getelementptr [4 x i8], ptr %5, i64 %.0377.lcssa
  %106 = getelementptr i8, ptr %105, i64 4
  store i32 %common.ret.op.i389, ptr %106, align 4
  %.not383406 = icmp eq i64 %.0377.lcssa, 0
  br i1 %.not383406, label %Else9, label %Then9.lr.ph

Then9.lr.ph:                                      ; preds = %Else8
  br i1 %103, label %Then9.us.preheader, label %Then9.preheader

Then9.preheader:                                  ; preds = %Then9.lr.ph
  %xtraiter484 = and i64 %.0377.lcssa, 3
  %lcmp.mod485.not = icmp eq i64 %xtraiter484, 0
  br i1 %lcmp.mod485.not, label %Then9.prol.loopexit, label %Then9.prol

Then9.prol:                                       ; preds = %Then9.prol, %Then9.preheader
  %.1375407.prol = phi i64 [ %110, %Then9.prol ], [ %.0377.lcssa, %Then9.preheader ]
  %prol.iter486 = phi i64 [ %prol.iter486.next, %Then9.prol ], [ 0, %Then9.preheader ]
  %107 = getelementptr inbounds [4 x i8], ptr %1, i64 %.1375407.prol
  %108 = load i32, ptr %107, align 4
  %109 = shl i32 %108, %.fr419
  %110 = add i64 %.1375407.prol, -1
  %111 = getelementptr inbounds [4 x i8], ptr %5, i64 %.1375407.prol
  store i32 %109, ptr %111, align 4
  %prol.iter486.next = add i64 %prol.iter486, 1
  %prol.iter486.cmp.not = icmp eq i64 %prol.iter486.next, %xtraiter484
  br i1 %prol.iter486.cmp.not, label %Then9.prol.loopexit, label %Then9.prol, !llvm.loop !5

Then9.prol.loopexit:                              ; preds = %Then9.prol, %Then9.preheader
  %.1375407.unr = phi i64 [ %.0377.lcssa, %Then9.preheader ], [ %110, %Then9.prol ]
  %112 = icmp ult i64 %.0377.lcssa, 4
  br i1 %112, label %Else9, label %Then9

Then9.us.preheader:                               ; preds = %Then9.lr.ph
  %xtraiter487 = and i64 %.0377.lcssa, 1
  %lcmp.mod488.not = icmp eq i64 %xtraiter487, 0
  br i1 %lcmp.mod488.not, label %Then9.us.prol.loopexit, label %Then9.us.prol

Then9.us.prol:                                    ; preds = %Then9.us.preheader
  %113 = shl i32 %.pre433, %.fr419
  %114 = add nsw i64 %.0377.lcssa, -1
  %115 = getelementptr inbounds [4 x i8], ptr %1, i64 %114
  %116 = load i32, ptr %115, align 4
  %117 = lshr i32 %116, %.pre-phi436
  %118 = or i32 %117, %113
  %119 = getelementptr inbounds [4 x i8], ptr %5, i64 %.0377.lcssa
  store i32 %118, ptr %119, align 4
  br label %Then9.us.prol.loopexit

Then9.us.prol.loopexit:                           ; preds = %Then9.us.prol, %Then9.us.preheader
  %.unr490 = phi i32 [ %.pre433, %Then9.us.preheader ], [ %116, %Then9.us.prol ]
  %.1375407.us.unr = phi i64 [ %.0377.lcssa, %Then9.us.preheader ], [ %114, %Then9.us.prol ]
  %120 = icmp eq i64 %.0377.lcssa, 1
  br i1 %120, label %Else9, label %Then9.us

Then9.us:                                         ; preds = %Then9.us, %Then9.us.prol.loopexit
  %121 = phi i32 [ %132, %Then9.us ], [ %.unr490, %Then9.us.prol.loopexit ]
  %.1375407.us = phi i64 [ %130, %Then9.us ], [ %.1375407.us.unr, %Then9.us.prol.loopexit ]
  %122 = shl i32 %121, %.fr419
  %123 = add i64 %.1375407.us, -1
  %124 = getelementptr inbounds [4 x i8], ptr %1, i64 %123
  %125 = load i32, ptr %124, align 4
  %126 = lshr i32 %125, %.pre-phi436
  %127 = or i32 %126, %122
  %128 = getelementptr inbounds [4 x i8], ptr %5, i64 %.1375407.us
  store i32 %127, ptr %128, align 4
  %129 = shl i32 %125, %.fr419
  %130 = add i64 %.1375407.us, -2
  %131 = getelementptr inbounds [4 x i8], ptr %1, i64 %130
  %132 = load i32, ptr %131, align 4
  %133 = lshr i32 %132, %.pre-phi436
  %134 = or i32 %133, %129
  %135 = getelementptr inbounds [4 x i8], ptr %5, i64 %123
  store i32 %134, ptr %135, align 4
  %.not383.us.1 = icmp eq i64 %130, 0
  br i1 %.not383.us.1, label %Else9, label %Then9.us

Then9:                                            ; preds = %Then9, %Then9.prol.loopexit
  %.1375407 = phi i64 [ %154, %Then9 ], [ %.1375407.unr, %Then9.prol.loopexit ]
  %136 = getelementptr inbounds [4 x i8], ptr %1, i64 %.1375407
  %137 = load i32, ptr %136, align 4
  %138 = shl i32 %137, %.fr419
  %139 = add i64 %.1375407, -1
  %140 = getelementptr inbounds [4 x i8], ptr %5, i64 %.1375407
  store i32 %138, ptr %140, align 4
  %141 = getelementptr inbounds [4 x i8], ptr %1, i64 %139
  %142 = load i32, ptr %141, align 4
  %143 = shl i32 %142, %.fr419
  %144 = add i64 %.1375407, -2
  %145 = getelementptr inbounds [4 x i8], ptr %5, i64 %139
  store i32 %143, ptr %145, align 4
  %146 = getelementptr inbounds [4 x i8], ptr %1, i64 %144
  %147 = load i32, ptr %146, align 4
  %148 = shl i32 %147, %.fr419
  %149 = add i64 %.1375407, -3
  %150 = getelementptr inbounds [4 x i8], ptr %5, i64 %144
  store i32 %148, ptr %150, align 4
  %151 = getelementptr inbounds [4 x i8], ptr %1, i64 %149
  %152 = load i32, ptr %151, align 4
  %153 = shl i32 %152, %.fr419
  %154 = add i64 %.1375407, -4
  %155 = getelementptr inbounds [4 x i8], ptr %5, i64 %149
  store i32 %153, ptr %155, align 4
  %.not383.3 = icmp eq i64 %154, 0
  br i1 %.not383.3, label %Else9, label %Then9

Else9:                                            ; preds = %Then9, %Then9.us, %Then9.us.prol.loopexit, %Then9.prol.loopexit, %Else8
  %156 = load i32, ptr %1, align 4
  %157 = shl i32 %156, %.fr419
  store i32 %157, ptr %5, align 4
  %158 = sub nuw i64 %.0377.lcssa, %.0376.lcssa.fr
  %invariant.gep416 = getelementptr [4 x i8], ptr %5, i64 %.0376.lcssa.fr
  %159 = getelementptr inbounds [4 x i8], ptr %6, i64 %.0376.lcssa.fr
  %160 = load i32, ptr %159, align 4
  %161 = zext i32 %160 to i64
  %162 = getelementptr i8, ptr %159, i64 -4
  %163 = add i64 %.0376.lcssa.fr, 1
  %xtraiter491 = and i64 %163, 1
  %164 = icmp eq i64 %.0376.lcssa.fr, 0
  %unroll_iter = and i64 %163, -2
  %lcmp.mod492.not = icmp eq i64 %xtraiter491, 0
  %lcmp.mod494 = icmp ne i64 %xtraiter491, 0
  %xtraiter495 = and i64 %163, 1
  %165 = icmp eq i64 %.0376.lcssa.fr, 0
  %unroll_iter499 = and i64 %163, -2
  %lcmp.mod496.not = icmp eq i64 %xtraiter495, 0
  %lcmp.mod498 = icmp ne i64 %xtraiter495, 0
  br label %Loop4

Loop4:                                            ; preds = %Block56, %Else9
  %.0373 = phi i64 [ %158, %Else9 ], [ %241, %Block56 ]
  %gep417 = getelementptr [4 x i8], ptr %invariant.gep416, i64 %.0373
  %166 = getelementptr i8, ptr %gep417, i64 4
  %167 = load i32, ptr %166, align 4
  %168 = zext i32 %167 to i64
  %169 = shl nuw i64 %168, 32
  %170 = load i32, ptr %gep417, align 4
  %171 = zext i32 %170 to i64
  %172 = or disjoint i64 %169, %171
  %173 = udiv i64 %172, %161
  %174 = urem i64 %172, %161
  %175 = getelementptr i8, ptr %gep417, i64 -4
  br i1 %.not382404, label %Loop5.us, label %Loop5

Loop5.us:                                         ; preds = %Then12.us, %Loop4
  %.0372.us = phi i64 [ %177, %Then12.us ], [ %173, %Loop4 ]
  %.0371.us = phi i64 [ %178, %Then12.us ], [ %174, %Loop4 ]
  %176 = icmp ugt i64 %.0372.us, 4294967295
  br i1 %176, label %Then12.us, label %Block39

Then12.us:                                        ; preds = %Loop5.us
  %177 = add i64 %.0372.us, -1
  %178 = add nuw nsw i64 %.0371.us, %161
  %179 = icmp samesign ult i64 %178, 4294967296
  br i1 %179, label %Loop5.us, label %Block39

Loop5:                                            ; preds = %Then12, %Loop4
  %.0372 = phi i64 [ %189, %Then12 ], [ %173, %Loop4 ]
  %.0371 = phi i64 [ %190, %Then12 ], [ %174, %Loop4 ]
  %180 = icmp ugt i64 %.0372, 4294967295
  br i1 %180, label %Then12, label %Else10

Block39:                                          ; preds = %Then12, %Else10, %Then12.us, %Loop5.us
  %.us-phi = phi i64 [ %177, %Then12.us ], [ %.0372.us, %Loop5.us ], [ %189, %Then12 ], [ %.0372, %Else10 ]
  %invariant.gep = getelementptr [4 x i8], ptr %5, i64 %.0373
  br i1 %164, label %Then14.epil.preheader, label %Then14

Else10:                                           ; preds = %Loop5
  %181 = load i32, ptr %162, align 4
  %182 = zext i32 %181 to i64
  %183 = mul nuw i64 %.0372, %182
  %184 = shl nuw i64 %.0371, 32
  %185 = load i32, ptr %175, align 4
  %186 = zext i32 %185 to i64
  %187 = or disjoint i64 %184, %186
  %188 = icmp ugt i64 %183, %187
  br i1 %188, label %Then12, label %Block39

Then12:                                           ; preds = %Else10, %Loop5
  %189 = add i64 %.0372, -1
  %190 = add nuw nsw i64 %.0371, %161
  %191 = icmp samesign ult i64 %190, 4294967296
  br i1 %191, label %Loop5, label %Block39

Then14:                                           ; preds = %Then14, %Block39
  %.0370411 = phi i64 [ %218, %Then14 ], [ 0, %Block39 ]
  %.2410 = phi i64 [ %219, %Then14 ], [ 0, %Block39 ]
  %niter = phi i64 [ %niter.next.1, %Then14 ], [ 0, %Block39 ]
  %192 = getelementptr inbounds [4 x i8], ptr %6, i64 %.2410
  %193 = load i32, ptr %192, align 4
  %194 = zext i32 %193 to i64
  %195 = mul nuw i64 %.us-phi, %194
  %gep = getelementptr [4 x i8], ptr %invariant.gep, i64 %.2410
  %196 = load i32, ptr %gep, align 4
  %197 = zext i32 %196 to i64
  %198 = and i64 %195, 4294967295
  %199 = add nuw nsw i64 %.0370411, %198
  %200 = sub nsw i64 %197, %199
  %201 = trunc i64 %200 to i32
  store i32 %201, ptr %gep, align 4
  %202 = lshr i64 %195, 32
  %203 = ashr i64 %200, 32
  %204 = sub nsw i64 %202, %203
  %205 = or disjoint i64 %.2410, 1
  %206 = getelementptr inbounds [4 x i8], ptr %6, i64 %205
  %207 = load i32, ptr %206, align 4
  %208 = zext i32 %207 to i64
  %209 = mul nuw i64 %.us-phi, %208
  %gep.1 = getelementptr [4 x i8], ptr %invariant.gep, i64 %205
  %210 = load i32, ptr %gep.1, align 4
  %211 = zext i32 %210 to i64
  %212 = and i64 %209, 4294967295
  %213 = add nuw nsw i64 %204, %212
  %214 = sub nsw i64 %211, %213
  %215 = trunc i64 %214 to i32
  store i32 %215, ptr %gep.1, align 4
  %216 = lshr i64 %209, 32
  %217 = ashr i64 %214, 32
  %218 = sub nsw i64 %216, %217
  %219 = add i64 %.2410, 2
  %niter.next.1 = add i64 %niter, 2
  %niter.ncmp.1 = icmp eq i64 %niter.next.1, %unroll_iter
  br i1 %niter.ncmp.1, label %Else14.unr-lcssa, label %Then14

Else14.unr-lcssa:                                 ; preds = %Then14
  br i1 %lcmp.mod492.not, label %Else14, label %Then14.epil.preheader

Then14.epil.preheader:                            ; preds = %Else14.unr-lcssa, %Block39
  %.0370411.epil.init = phi i64 [ 0, %Block39 ], [ %218, %Else14.unr-lcssa ]
  %.2410.epil.init = phi i64 [ 0, %Block39 ], [ %219, %Else14.unr-lcssa ]
  tail call void @llvm.assume(i1 %lcmp.mod494)
  %220 = getelementptr inbounds [4 x i8], ptr %6, i64 %.2410.epil.init
  %221 = load i32, ptr %220, align 4
  %222 = zext i32 %221 to i64
  %223 = mul nuw i64 %.us-phi, %222
  %gep.epil = getelementptr [4 x i8], ptr %invariant.gep, i64 %.2410.epil.init
  %224 = load i32, ptr %gep.epil, align 4
  %225 = zext i32 %224 to i64
  %226 = and i64 %223, 4294967295
  %227 = add nuw nsw i64 %.0370411.epil.init, %226
  %228 = sub nsw i64 %225, %227
  %229 = trunc i64 %228 to i32
  store i32 %229, ptr %gep.epil, align 4
  %230 = lshr i64 %223, 32
  %231 = ashr i64 %228, 32
  %232 = sub nsw i64 %230, %231
  br label %Else14

Else14:                                           ; preds = %Then14.epil.preheader, %Else14.unr-lcssa
  %.lcssa468 = phi i64 [ %218, %Else14.unr-lcssa ], [ %232, %Then14.epil.preheader ]
  %233 = load i32, ptr %166, align 4
  %234 = zext i32 %233 to i64
  %235 = sub nsw i64 %234, %.lcssa468
  %236 = trunc i64 %235 to i32
  store i32 %236, ptr %166, align 4
  %237 = trunc i64 %.us-phi to i32
  %238 = getelementptr inbounds [4 x i8], ptr %0, i64 %.0373
  store i32 %237, ptr %238, align 4
  %239 = icmp slt i64 %235, 0
  br i1 %239, label %Then17, label %Block56

Block56:                                          ; preds = %Else18, %Else14
  %240 = icmp eq i64 %.0373, 0
  %241 = add i64 %.0373, -1
  br i1 %240, label %Block1, label %Loop4

Then17:                                           ; preds = %Else14
  %242 = add i32 %237, -1
  store i32 %242, ptr %238, align 4
  br i1 %165, label %Then18.epil.preheader, label %Then18

Then18:                                           ; preds = %Then18, %Then17
  %.0415 = phi i64 [ %261, %Then18 ], [ 0, %Then17 ]
  %.3414 = phi i64 [ %262, %Then18 ], [ 0, %Then17 ]
  %niter500 = phi i64 [ %niter500.next.1, %Then18 ], [ 0, %Then17 ]
  %gep413 = getelementptr [4 x i8], ptr %invariant.gep, i64 %.3414
  %243 = load i32, ptr %gep413, align 4
  %244 = zext i32 %243 to i64
  %245 = getelementptr inbounds [4 x i8], ptr %6, i64 %.3414
  %246 = load i32, ptr %245, align 4
  %247 = zext i32 %246 to i64
  %248 = add nuw nsw i64 %.0415, %244
  %249 = add nuw nsw i64 %248, %247
  %250 = trunc i64 %249 to i32
  store i32 %250, ptr %gep413, align 4
  %251 = lshr i64 %249, 32
  %252 = or disjoint i64 %.3414, 1
  %gep413.1 = getelementptr [4 x i8], ptr %invariant.gep, i64 %252
  %253 = load i32, ptr %gep413.1, align 4
  %254 = zext i32 %253 to i64
  %255 = getelementptr inbounds [4 x i8], ptr %6, i64 %252
  %256 = load i32, ptr %255, align 4
  %257 = zext i32 %256 to i64
  %258 = add nuw nsw i64 %251, %254
  %259 = add nuw nsw i64 %258, %257
  %260 = trunc i64 %259 to i32
  store i32 %260, ptr %gep413.1, align 4
  %261 = lshr i64 %259, 32
  %262 = add i64 %.3414, 2
  %niter500.next.1 = add i64 %niter500, 2
  %niter500.ncmp.1 = icmp eq i64 %niter500.next.1, %unroll_iter499
  br i1 %niter500.ncmp.1, label %Else18.unr-lcssa, label %Then18

Else18.unr-lcssa:                                 ; preds = %Then18
  br i1 %lcmp.mod496.not, label %Else18, label %Then18.epil.preheader

Then18.epil.preheader:                            ; preds = %Else18.unr-lcssa, %Then17
  %.0415.epil.init = phi i64 [ 0, %Then17 ], [ %261, %Else18.unr-lcssa ]
  %.3414.epil.init = phi i64 [ 0, %Then17 ], [ %262, %Else18.unr-lcssa ]
  tail call void @llvm.assume(i1 %lcmp.mod498)
  %gep413.epil = getelementptr [4 x i8], ptr %invariant.gep, i64 %.3414.epil.init
  %263 = load i32, ptr %gep413.epil, align 4
  %264 = zext i32 %263 to i64
  %265 = getelementptr inbounds [4 x i8], ptr %6, i64 %.3414.epil.init
  %266 = load i32, ptr %265, align 4
  %267 = zext i32 %266 to i64
  %268 = add nuw nsw i64 %.0415.epil.init, %264
  %269 = add nuw nsw i64 %268, %267
  %270 = trunc i64 %269 to i32
  store i32 %270, ptr %gep413.epil, align 4
  %271 = lshr i64 %269, 32
  br label %Else18

Else18:                                           ; preds = %Then18.epil.preheader, %Else18.unr-lcssa
  %.lcssa469 = phi i64 [ %261, %Else18.unr-lcssa ], [ %271, %Then18.epil.preheader ]
  %272 = load i32, ptr %166, align 4
  %273 = trunc nuw nsw i64 %.lcssa469 to i32
  %274 = add i32 %272, %273
  store i32 %274, ptr %166, align 4
  br label %Block56
}

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(inaccessiblemem: write)
declare void @llvm.assume(i1 noundef) #1

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(inaccessiblemem: write) uwtable
declare hidden fastcc range(i16 0, 8208) i16 @zig.target.intByteSize(i16) unnamed_addr #2 align 1

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.ctlz.i32(i32, i1 immarg) #3

; Function Attrs: nofree norecurse nosync nounwind memory(argmem: readwrite, inaccessiblemem: write) uwtable
define hidden void @compiler_rt.udivmodei4.__umodei4(ptr nonnull writeonly align 1 captures(address) %0, ptr nonnull readonly align 1 captures(none) %1, ptr nonnull readonly align 1 captures(none) %2, i64 %3) unnamed_addr #0 align 1 {
Entry:
  %4 = alloca [2049 x i32], align 4
  %5 = alloca [2048 x i32], align 4
  %6 = icmp ult i64 %3, 65536
  tail call void @llvm.assume(i1 %6)
  %7 = trunc nuw i64 %3 to i16
  %8 = tail call fastcc i16 @zig.target.intByteSize(i16 %7) #5
  %9 = zext nneg i16 %8 to i64
  %10 = lshr exact i64 %9, 2
  %11 = getelementptr inbounds nuw i8, ptr %0, i64 %9
  %.not424 = icmp eq i16 %8, 0
  br i1 %.not424, label %Block2, label %InlineMemsetBody.preheader

InlineMemsetBody.preheader:                       ; preds = %Entry
  %12 = add nsw i64 %9, -4
  %13 = lshr i64 %12, 2
  %14 = add nuw nsw i64 %13, 1
  %xtraiter = and i64 %14, 7
  %15 = and i64 %12, 28
  %lcmp.mod.not = icmp eq i64 %15, 28
  br i1 %lcmp.mod.not, label %InlineMemsetBody.prol.loopexit, label %InlineMemsetBody.prol

InlineMemsetBody.prol:                            ; preds = %InlineMemsetBody.prol, %InlineMemsetBody.preheader
  %16 = phi ptr [ %17, %InlineMemsetBody.prol ], [ %0, %InlineMemsetBody.preheader ]
  %prol.iter = phi i64 [ %prol.iter.next, %InlineMemsetBody.prol ], [ 0, %InlineMemsetBody.preheader ]
  store i32 0, ptr %16, align 4
  %17 = getelementptr inbounds nuw i8, ptr %16, i64 4
  %prol.iter.next = add i64 %prol.iter, 1
  %prol.iter.cmp.not = icmp eq i64 %prol.iter.next, %xtraiter
  br i1 %prol.iter.cmp.not, label %InlineMemsetBody.prol.loopexit, label %InlineMemsetBody.prol, !llvm.loop !6

InlineMemsetBody.prol.loopexit:                   ; preds = %InlineMemsetBody.prol, %InlineMemsetBody.preheader
  %.unr = phi ptr [ %0, %InlineMemsetBody.preheader ], [ %17, %InlineMemsetBody.prol ]
  %18 = icmp ult i64 %12, 28
  br i1 %18, label %Block2, label %InlineMemsetBody

Block1:                                           ; preds = %Else20, %Then8, %Then3
  ret void

Block2:                                           ; preds = %InlineMemsetBody, %InlineMemsetBody.prol.loopexit, %Entry
  %19 = icmp ne i16 %8, 0
  tail call void @llvm.assume(i1 %19)
  %20 = add nsw i64 %10, -1
  %21 = getelementptr inbounds [4 x i8], ptr %1, i64 %20
  %22 = load i32, ptr %21, align 4
  %23 = icmp eq i32 %22, 0
  br i1 %23, label %Then3, label %Loop1.preheader

InlineMemsetBody:                                 ; preds = %InlineMemsetBody, %InlineMemsetBody.prol.loopexit
  %24 = phi ptr [ %32, %InlineMemsetBody ], [ %.unr, %InlineMemsetBody.prol.loopexit ]
  store i32 0, ptr %24, align 4
  %25 = getelementptr inbounds nuw i8, ptr %24, i64 4
  store i32 0, ptr %25, align 4
  %26 = getelementptr inbounds nuw i8, ptr %24, i64 8
  store i32 0, ptr %26, align 4
  %27 = getelementptr inbounds nuw i8, ptr %24, i64 12
  store i32 0, ptr %27, align 4
  %28 = getelementptr inbounds nuw i8, ptr %24, i64 16
  store i32 0, ptr %28, align 4
  %29 = getelementptr inbounds nuw i8, ptr %24, i64 20
  store i32 0, ptr %29, align 4
  %30 = getelementptr inbounds nuw i8, ptr %24, i64 24
  store i32 0, ptr %30, align 4
  %31 = getelementptr inbounds nuw i8, ptr %24, i64 28
  store i32 0, ptr %31, align 4
  %32 = getelementptr inbounds nuw i8, ptr %24, i64 32
  %.not.7 = icmp eq ptr %32, %11
  br i1 %.not.7, label %Block2, label %InlineMemsetBody

Loop1.preheader:                                  ; preds = %Else4, %Block2
  %.0400.lcssa = phi i64 [ %20, %Block2 ], [ %37, %Else4 ]
  %.pre463 = phi i32 [ %22, %Block2 ], [ %39, %Else4 ]
  %33 = getelementptr inbounds [4 x i8], ptr %2, i64 %20
  %34 = load i32, ptr %33, align 4
  %35 = icmp eq i32 %34, 0
  br i1 %35, label %Then5, label %Else5

Then3:                                            ; preds = %Else4, %Block2
  %.0400425 = phi i64 [ %37, %Else4 ], [ %20, %Block2 ]
  %36 = icmp eq i64 %.0400425, 0
  br i1 %36, label %Block1, label %Else4

Else4:                                            ; preds = %Then3
  %37 = add i64 %.0400425, -1
  %38 = getelementptr inbounds [4 x i8], ptr %1, i64 %37
  %39 = load i32, ptr %38, align 4
  %40 = icmp eq i32 %39, 0
  br i1 %40, label %Then3, label %Loop1.preheader

Then5:                                            ; preds = %Then5, %Loop1.preheader
  %.0399427 = phi i64 [ %42, %Then5 ], [ %20, %Loop1.preheader ]
  %41 = icmp ne i64 %.0399427, 0
  tail call void @llvm.assume(i1 %41)
  %42 = add i64 %.0399427, -1
  %43 = getelementptr inbounds [4 x i8], ptr %2, i64 %42
  %44 = load i32, ptr %43, align 4
  %45 = icmp eq i32 %44, 0
  br i1 %45, label %Then5, label %Else5

Else5:                                            ; preds = %Then5, %Loop1.preheader
  %.0399.lcssa = phi i64 [ %20, %Loop1.preheader ], [ %42, %Then5 ]
  %.lcssa = phi i32 [ %34, %Loop1.preheader ], [ %44, %Then5 ]
  %.0399.lcssa.fr = freeze i64 %.0399.lcssa
  %46 = icmp ugt i64 %.0399.lcssa.fr, %.0400.lcssa
  br i1 %46, label %Then8, label %Else7

Else7:                                            ; preds = %Else5
  %47 = tail call range(i32 0, 33) i32 @llvm.ctlz.i32(i32 %.lcssa, i1 true)
  %.fr447 = freeze i32 %47
  %48 = trunc i32 %.fr447 to i6
  %.not405430 = icmp eq i64 %.0399.lcssa.fr, 0
  %.pre465 = sub i6 -32, %48
  br i1 %.not405430, label %Else7.Else9_crit_edge, label %Then9.lr.ph

Else7.Else9_crit_edge:                            ; preds = %Else7
  %.pre466 = zext nneg i6 %.pre465 to i32
  br label %Else9

Then9.lr.ph:                                      ; preds = %Else7
  %49 = icmp sgt i6 %.pre465, -1
  %50 = zext nneg i6 %.pre465 to i32
  br i1 %49, label %Then9.us.preheader, label %Then9.preheader

Then9.preheader:                                  ; preds = %Then9.lr.ph
  %xtraiter508 = and i64 %.0399.lcssa.fr, 3
  %lcmp.mod509.not = icmp eq i64 %xtraiter508, 0
  br i1 %lcmp.mod509.not, label %Then9.prol.loopexit, label %Then9.prol

Then9.prol:                                       ; preds = %Then9.prol, %Then9.preheader
  %.0397431.prol = phi i64 [ %54, %Then9.prol ], [ %.0399.lcssa.fr, %Then9.preheader ]
  %prol.iter510 = phi i64 [ %prol.iter510.next, %Then9.prol ], [ 0, %Then9.preheader ]
  %51 = getelementptr inbounds [4 x i8], ptr %2, i64 %.0397431.prol
  %52 = load i32, ptr %51, align 4
  %53 = shl i32 %52, %.fr447
  %54 = add i64 %.0397431.prol, -1
  %55 = getelementptr inbounds [4 x i8], ptr %5, i64 %.0397431.prol
  store i32 %53, ptr %55, align 4
  %prol.iter510.next = add i64 %prol.iter510, 1
  %prol.iter510.cmp.not = icmp eq i64 %prol.iter510.next, %xtraiter508
  br i1 %prol.iter510.cmp.not, label %Then9.prol.loopexit, label %Then9.prol, !llvm.loop !7

Then9.prol.loopexit:                              ; preds = %Then9.prol, %Then9.preheader
  %.0397431.unr = phi i64 [ %.0399.lcssa.fr, %Then9.preheader ], [ %54, %Then9.prol ]
  %56 = icmp ult i64 %.0399.lcssa.fr, 4
  br i1 %56, label %Else9, label %Then9

Then9.us.preheader:                               ; preds = %Then9.lr.ph
  %.phi.trans.insert = getelementptr inbounds [4 x i8], ptr %2, i64 %.0399.lcssa.fr
  %.pre = load i32, ptr %.phi.trans.insert, align 4
  %xtraiter511 = and i64 %.0399.lcssa.fr, 1
  %lcmp.mod512.not = icmp eq i64 %xtraiter511, 0
  br i1 %lcmp.mod512.not, label %Then9.us.prol.loopexit, label %Then9.us.prol

Then9.us.prol:                                    ; preds = %Then9.us.preheader
  %57 = shl i32 %.pre, %.fr447
  %58 = add nsw i64 %.0399.lcssa.fr, -1
  %59 = getelementptr inbounds [4 x i8], ptr %2, i64 %58
  %60 = load i32, ptr %59, align 4
  %61 = lshr i32 %60, %50
  %62 = or i32 %61, %57
  %63 = getelementptr inbounds [4 x i8], ptr %5, i64 %.0399.lcssa.fr
  store i32 %62, ptr %63, align 4
  br label %Then9.us.prol.loopexit

Then9.us.prol.loopexit:                           ; preds = %Then9.us.prol, %Then9.us.preheader
  %.unr514 = phi i32 [ %.pre, %Then9.us.preheader ], [ %60, %Then9.us.prol ]
  %.0397431.us.unr = phi i64 [ %.0399.lcssa.fr, %Then9.us.preheader ], [ %58, %Then9.us.prol ]
  %64 = icmp eq i64 %.0399.lcssa.fr, 1
  br i1 %64, label %Else9, label %Then9.us

Then9.us:                                         ; preds = %Then9.us, %Then9.us.prol.loopexit
  %65 = phi i32 [ %76, %Then9.us ], [ %.unr514, %Then9.us.prol.loopexit ]
  %.0397431.us = phi i64 [ %74, %Then9.us ], [ %.0397431.us.unr, %Then9.us.prol.loopexit ]
  %66 = shl i32 %65, %.fr447
  %67 = add i64 %.0397431.us, -1
  %68 = getelementptr inbounds [4 x i8], ptr %2, i64 %67
  %69 = load i32, ptr %68, align 4
  %70 = lshr i32 %69, %50
  %71 = or i32 %70, %66
  %72 = getelementptr inbounds [4 x i8], ptr %5, i64 %.0397431.us
  store i32 %71, ptr %72, align 4
  %73 = shl i32 %69, %.fr447
  %74 = add i64 %.0397431.us, -2
  %75 = getelementptr inbounds [4 x i8], ptr %2, i64 %74
  %76 = load i32, ptr %75, align 4
  %77 = lshr i32 %76, %50
  %78 = or i32 %77, %73
  %79 = getelementptr inbounds [4 x i8], ptr %5, i64 %67
  store i32 %78, ptr %79, align 4
  %.not405.us.1 = icmp eq i64 %74, 0
  br i1 %.not405.us.1, label %Else9, label %Then9.us

Then8:                                            ; preds = %Else5
  tail call void @llvm.memcpy.inline.p0.p0.i64(ptr nonnull align 4 %0, ptr nonnull align 4 %1, i64 %9, i1 false)
  br label %Block1

Then9:                                            ; preds = %Then9, %Then9.prol.loopexit
  %.0397431 = phi i64 [ %98, %Then9 ], [ %.0397431.unr, %Then9.prol.loopexit ]
  %80 = getelementptr inbounds [4 x i8], ptr %2, i64 %.0397431
  %81 = load i32, ptr %80, align 4
  %82 = shl i32 %81, %.fr447
  %83 = add i64 %.0397431, -1
  %84 = getelementptr inbounds [4 x i8], ptr %5, i64 %.0397431
  store i32 %82, ptr %84, align 4
  %85 = getelementptr inbounds [4 x i8], ptr %2, i64 %83
  %86 = load i32, ptr %85, align 4
  %87 = shl i32 %86, %.fr447
  %88 = add i64 %.0397431, -2
  %89 = getelementptr inbounds [4 x i8], ptr %5, i64 %83
  store i32 %87, ptr %89, align 4
  %90 = getelementptr inbounds [4 x i8], ptr %2, i64 %88
  %91 = load i32, ptr %90, align 4
  %92 = shl i32 %91, %.fr447
  %93 = add i64 %.0397431, -3
  %94 = getelementptr inbounds [4 x i8], ptr %5, i64 %88
  store i32 %92, ptr %94, align 4
  %95 = getelementptr inbounds [4 x i8], ptr %2, i64 %93
  %96 = load i32, ptr %95, align 4
  %97 = shl i32 %96, %.fr447
  %98 = add i64 %.0397431, -4
  %99 = getelementptr inbounds [4 x i8], ptr %5, i64 %93
  store i32 %97, ptr %99, align 4
  %.not405.3 = icmp eq i64 %98, 0
  br i1 %.not405.3, label %Else9, label %Then9

Else9:                                            ; preds = %Then9, %Then9.us, %Then9.us.prol.loopexit, %Then9.prol.loopexit, %Else7.Else9_crit_edge
  %.pre-phi467 = phi i32 [ %.pre466, %Else7.Else9_crit_edge ], [ %50, %Then9.us.prol.loopexit ], [ %50, %Then9.us ], [ %50, %Then9 ], [ %50, %Then9.prol.loopexit ]
  %100 = load i32, ptr %2, align 4
  %101 = shl i32 %100, %.fr447
  store i32 %101, ptr %5, align 4
  %102 = icmp sgt i6 %.pre465, -1
  %103 = lshr i32 %.pre463, %.pre-phi467
  %common.ret.op.i413 = select i1 %102, i32 %103, i32 0
  %104 = getelementptr [4 x i8], ptr %4, i64 %.0400.lcssa
  %105 = getelementptr i8, ptr %104, i64 4
  store i32 %common.ret.op.i413, ptr %105, align 4
  %.not406432 = icmp eq i64 %.0400.lcssa, 0
  br i1 %.not406432, label %Else10, label %Then10.lr.ph

Then10.lr.ph:                                     ; preds = %Else9
  br i1 %102, label %Then10.us.preheader, label %Then10.preheader

Then10.preheader:                                 ; preds = %Then10.lr.ph
  %xtraiter515 = and i64 %.0400.lcssa, 3
  %lcmp.mod516.not = icmp eq i64 %xtraiter515, 0
  br i1 %lcmp.mod516.not, label %Then10.prol.loopexit, label %Then10.prol

Then10.prol:                                      ; preds = %Then10.prol, %Then10.preheader
  %.1398433.prol = phi i64 [ %109, %Then10.prol ], [ %.0400.lcssa, %Then10.preheader ]
  %prol.iter517 = phi i64 [ %prol.iter517.next, %Then10.prol ], [ 0, %Then10.preheader ]
  %106 = getelementptr inbounds [4 x i8], ptr %1, i64 %.1398433.prol
  %107 = load i32, ptr %106, align 4
  %108 = shl i32 %107, %.fr447
  %109 = add i64 %.1398433.prol, -1
  %110 = getelementptr inbounds [4 x i8], ptr %4, i64 %.1398433.prol
  store i32 %108, ptr %110, align 4
  %prol.iter517.next = add i64 %prol.iter517, 1
  %prol.iter517.cmp.not = icmp eq i64 %prol.iter517.next, %xtraiter515
  br i1 %prol.iter517.cmp.not, label %Then10.prol.loopexit, label %Then10.prol, !llvm.loop !8

Then10.prol.loopexit:                             ; preds = %Then10.prol, %Then10.preheader
  %.1398433.unr = phi i64 [ %.0400.lcssa, %Then10.preheader ], [ %109, %Then10.prol ]
  %111 = icmp ult i64 %.0400.lcssa, 4
  br i1 %111, label %Else10, label %Then10

Then10.us.preheader:                              ; preds = %Then10.lr.ph
  %xtraiter518 = and i64 %.0400.lcssa, 1
  %lcmp.mod519.not = icmp eq i64 %xtraiter518, 0
  br i1 %lcmp.mod519.not, label %Then10.us.prol.loopexit, label %Then10.us.prol

Then10.us.prol:                                   ; preds = %Then10.us.preheader
  %112 = shl i32 %.pre463, %.fr447
  %113 = add nsw i64 %.0400.lcssa, -1
  %114 = getelementptr inbounds [4 x i8], ptr %1, i64 %113
  %115 = load i32, ptr %114, align 4
  %116 = lshr i32 %115, %.pre-phi467
  %117 = or i32 %116, %112
  %118 = getelementptr inbounds [4 x i8], ptr %4, i64 %.0400.lcssa
  store i32 %117, ptr %118, align 4
  br label %Then10.us.prol.loopexit

Then10.us.prol.loopexit:                          ; preds = %Then10.us.prol, %Then10.us.preheader
  %.unr521 = phi i32 [ %.pre463, %Then10.us.preheader ], [ %115, %Then10.us.prol ]
  %.1398433.us.unr = phi i64 [ %.0400.lcssa, %Then10.us.preheader ], [ %113, %Then10.us.prol ]
  %119 = icmp eq i64 %.0400.lcssa, 1
  br i1 %119, label %Else10, label %Then10.us

Then10.us:                                        ; preds = %Then10.us, %Then10.us.prol.loopexit
  %120 = phi i32 [ %131, %Then10.us ], [ %.unr521, %Then10.us.prol.loopexit ]
  %.1398433.us = phi i64 [ %129, %Then10.us ], [ %.1398433.us.unr, %Then10.us.prol.loopexit ]
  %121 = shl i32 %120, %.fr447
  %122 = add i64 %.1398433.us, -1
  %123 = getelementptr inbounds [4 x i8], ptr %1, i64 %122
  %124 = load i32, ptr %123, align 4
  %125 = lshr i32 %124, %.pre-phi467
  %126 = or i32 %125, %121
  %127 = getelementptr inbounds [4 x i8], ptr %4, i64 %.1398433.us
  store i32 %126, ptr %127, align 4
  %128 = shl i32 %124, %.fr447
  %129 = add i64 %.1398433.us, -2
  %130 = getelementptr inbounds [4 x i8], ptr %1, i64 %129
  %131 = load i32, ptr %130, align 4
  %132 = lshr i32 %131, %.pre-phi467
  %133 = or i32 %132, %128
  %134 = getelementptr inbounds [4 x i8], ptr %4, i64 %122
  store i32 %133, ptr %134, align 4
  %.not406.us.1 = icmp eq i64 %129, 0
  br i1 %.not406.us.1, label %Else10, label %Then10.us

Then10:                                           ; preds = %Then10, %Then10.prol.loopexit
  %.1398433 = phi i64 [ %153, %Then10 ], [ %.1398433.unr, %Then10.prol.loopexit ]
  %135 = getelementptr inbounds [4 x i8], ptr %1, i64 %.1398433
  %136 = load i32, ptr %135, align 4
  %137 = shl i32 %136, %.fr447
  %138 = add i64 %.1398433, -1
  %139 = getelementptr inbounds [4 x i8], ptr %4, i64 %.1398433
  store i32 %137, ptr %139, align 4
  %140 = getelementptr inbounds [4 x i8], ptr %1, i64 %138
  %141 = load i32, ptr %140, align 4
  %142 = shl i32 %141, %.fr447
  %143 = add i64 %.1398433, -2
  %144 = getelementptr inbounds [4 x i8], ptr %4, i64 %138
  store i32 %142, ptr %144, align 4
  %145 = getelementptr inbounds [4 x i8], ptr %1, i64 %143
  %146 = load i32, ptr %145, align 4
  %147 = shl i32 %146, %.fr447
  %148 = add i64 %.1398433, -3
  %149 = getelementptr inbounds [4 x i8], ptr %4, i64 %143
  store i32 %147, ptr %149, align 4
  %150 = getelementptr inbounds [4 x i8], ptr %1, i64 %148
  %151 = load i32, ptr %150, align 4
  %152 = shl i32 %151, %.fr447
  %153 = add i64 %.1398433, -4
  %154 = getelementptr inbounds [4 x i8], ptr %4, i64 %148
  store i32 %152, ptr %154, align 4
  %.not406.3 = icmp eq i64 %153, 0
  br i1 %.not406.3, label %Else10, label %Then10

Else10:                                           ; preds = %Then10, %Then10.us, %Then10.us.prol.loopexit, %Then10.prol.loopexit, %Else9
  %155 = load i32, ptr %1, align 4
  %156 = shl i32 %155, %.fr447
  store i32 %156, ptr %4, align 4
  %157 = sub nuw i64 %.0400.lcssa, %.0399.lcssa.fr
  %invariant.gep442 = getelementptr [4 x i8], ptr %4, i64 %.0399.lcssa.fr
  %158 = getelementptr inbounds [4 x i8], ptr %5, i64 %.0399.lcssa.fr
  %159 = load i32, ptr %158, align 4
  %160 = zext i32 %159 to i64
  %161 = getelementptr i8, ptr %158, i64 -4
  %162 = add i64 %.0399.lcssa.fr, 1
  %xtraiter522 = and i64 %162, 1
  %163 = icmp eq i64 %.0399.lcssa.fr, 0
  %unroll_iter = and i64 %162, -2
  %lcmp.mod523.not = icmp eq i64 %xtraiter522, 0
  %lcmp.mod525 = icmp ne i64 %xtraiter522, 0
  %xtraiter526 = and i64 %162, 1
  %164 = icmp eq i64 %.0399.lcssa.fr, 0
  %unroll_iter530 = and i64 %162, -2
  %lcmp.mod527.not = icmp eq i64 %xtraiter526, 0
  %lcmp.mod529 = icmp ne i64 %xtraiter526, 0
  br label %Loop4

Loop4:                                            ; preds = %Block55, %Else10
  %.0396 = phi i64 [ %157, %Else10 ], [ %238, %Block55 ]
  %gep443 = getelementptr [4 x i8], ptr %invariant.gep442, i64 %.0396
  %165 = getelementptr i8, ptr %gep443, i64 4
  %166 = load i32, ptr %165, align 4
  %167 = zext i32 %166 to i64
  %168 = shl nuw i64 %167, 32
  %169 = load i32, ptr %gep443, align 4
  %170 = zext i32 %169 to i64
  %171 = or disjoint i64 %168, %170
  %172 = udiv i64 %171, %160
  %173 = urem i64 %171, %160
  %174 = getelementptr i8, ptr %gep443, i64 -4
  br i1 %.not405430, label %Loop5.us, label %Loop5

Loop5.us:                                         ; preds = %Then13.us, %Loop4
  %.0395.us = phi i64 [ %176, %Then13.us ], [ %172, %Loop4 ]
  %.0394.us = phi i64 [ %177, %Then13.us ], [ %173, %Loop4 ]
  %175 = icmp ugt i64 %.0395.us, 4294967295
  br i1 %175, label %Then13.us, label %Block40

Then13.us:                                        ; preds = %Loop5.us
  %176 = add i64 %.0395.us, -1
  %177 = add nuw nsw i64 %.0394.us, %160
  %178 = icmp samesign ult i64 %177, 4294967296
  br i1 %178, label %Loop5.us, label %Block40

Loop5:                                            ; preds = %Then13, %Loop4
  %.0395 = phi i64 [ %188, %Then13 ], [ %172, %Loop4 ]
  %.0394 = phi i64 [ %189, %Then13 ], [ %173, %Loop4 ]
  %179 = icmp ugt i64 %.0395, 4294967295
  br i1 %179, label %Then13, label %Else11

Block40:                                          ; preds = %Then13, %Else11, %Then13.us, %Loop5.us
  %.us-phi = phi i64 [ %176, %Then13.us ], [ %.0395.us, %Loop5.us ], [ %188, %Then13 ], [ %.0395, %Else11 ]
  %invariant.gep = getelementptr [4 x i8], ptr %4, i64 %.0396
  br i1 %163, label %Then15.epil.preheader, label %Then15

Else11:                                           ; preds = %Loop5
  %180 = load i32, ptr %161, align 4
  %181 = zext i32 %180 to i64
  %182 = mul nuw i64 %.0395, %181
  %183 = shl nuw i64 %.0394, 32
  %184 = load i32, ptr %174, align 4
  %185 = zext i32 %184 to i64
  %186 = or disjoint i64 %183, %185
  %187 = icmp ugt i64 %182, %186
  br i1 %187, label %Then13, label %Block40

Then13:                                           ; preds = %Else11, %Loop5
  %188 = add i64 %.0395, -1
  %189 = add nuw nsw i64 %.0394, %160
  %190 = icmp samesign ult i64 %189, 4294967296
  br i1 %190, label %Loop5, label %Block40

Then15:                                           ; preds = %Then15, %Block40
  %.0393437 = phi i64 [ %217, %Then15 ], [ 0, %Block40 ]
  %.2436 = phi i64 [ %218, %Then15 ], [ 0, %Block40 ]
  %niter = phi i64 [ %niter.next.1, %Then15 ], [ 0, %Block40 ]
  %191 = getelementptr inbounds [4 x i8], ptr %5, i64 %.2436
  %192 = load i32, ptr %191, align 4
  %193 = zext i32 %192 to i64
  %194 = mul nuw i64 %.us-phi, %193
  %gep = getelementptr [4 x i8], ptr %invariant.gep, i64 %.2436
  %195 = load i32, ptr %gep, align 4
  %196 = zext i32 %195 to i64
  %197 = and i64 %194, 4294967295
  %198 = add nuw nsw i64 %.0393437, %197
  %199 = sub nsw i64 %196, %198
  %200 = trunc i64 %199 to i32
  store i32 %200, ptr %gep, align 4
  %201 = lshr i64 %194, 32
  %202 = ashr i64 %199, 32
  %203 = sub nsw i64 %201, %202
  %204 = or disjoint i64 %.2436, 1
  %205 = getelementptr inbounds [4 x i8], ptr %5, i64 %204
  %206 = load i32, ptr %205, align 4
  %207 = zext i32 %206 to i64
  %208 = mul nuw i64 %.us-phi, %207
  %gep.1 = getelementptr [4 x i8], ptr %invariant.gep, i64 %204
  %209 = load i32, ptr %gep.1, align 4
  %210 = zext i32 %209 to i64
  %211 = and i64 %208, 4294967295
  %212 = add nuw nsw i64 %203, %211
  %213 = sub nsw i64 %210, %212
  %214 = trunc i64 %213 to i32
  store i32 %214, ptr %gep.1, align 4
  %215 = lshr i64 %208, 32
  %216 = ashr i64 %213, 32
  %217 = sub nsw i64 %215, %216
  %218 = add i64 %.2436, 2
  %niter.next.1 = add i64 %niter, 2
  %niter.ncmp.1 = icmp eq i64 %niter.next.1, %unroll_iter
  br i1 %niter.ncmp.1, label %Else15.unr-lcssa, label %Then15

Else15.unr-lcssa:                                 ; preds = %Then15
  br i1 %lcmp.mod523.not, label %Else15, label %Then15.epil.preheader

Then15.epil.preheader:                            ; preds = %Else15.unr-lcssa, %Block40
  %.0393437.epil.init = phi i64 [ 0, %Block40 ], [ %217, %Else15.unr-lcssa ]
  %.2436.epil.init = phi i64 [ 0, %Block40 ], [ %218, %Else15.unr-lcssa ]
  tail call void @llvm.assume(i1 %lcmp.mod525)
  %219 = getelementptr inbounds [4 x i8], ptr %5, i64 %.2436.epil.init
  %220 = load i32, ptr %219, align 4
  %221 = zext i32 %220 to i64
  %222 = mul nuw i64 %.us-phi, %221
  %gep.epil = getelementptr [4 x i8], ptr %invariant.gep, i64 %.2436.epil.init
  %223 = load i32, ptr %gep.epil, align 4
  %224 = zext i32 %223 to i64
  %225 = and i64 %222, 4294967295
  %226 = add nuw nsw i64 %.0393437.epil.init, %225
  %227 = sub nsw i64 %224, %226
  %228 = trunc i64 %227 to i32
  store i32 %228, ptr %gep.epil, align 4
  %229 = lshr i64 %222, 32
  %230 = ashr i64 %227, 32
  %231 = sub nsw i64 %229, %230
  br label %Else15

Else15:                                           ; preds = %Then15.epil.preheader, %Else15.unr-lcssa
  %.lcssa500 = phi i64 [ %217, %Else15.unr-lcssa ], [ %231, %Then15.epil.preheader ]
  %232 = load i32, ptr %165, align 4
  %233 = zext i32 %232 to i64
  %234 = sub nsw i64 %233, %.lcssa500
  %235 = trunc i64 %234 to i32
  store i32 %235, ptr %165, align 4
  %236 = icmp slt i64 %234, 0
  br i1 %236, label %Then17.preheader, label %Block55

Then17.preheader:                                 ; preds = %Else15
  br i1 %164, label %Then17.epil.preheader, label %Then17

Block55:                                          ; preds = %Else17, %Else15
  %237 = icmp eq i64 %.0396, 0
  %238 = add i64 %.0396, -1
  br i1 %237, label %Loop8.preheader, label %Loop4

Loop8.preheader:                                  ; preds = %Block55
  br i1 %102, label %Then20.us.preheader, label %Then20.preheader

Then20.preheader:                                 ; preds = %Loop8.preheader
  %xtraiter532 = and i64 %162, 3
  %239 = icmp ult i64 %.0399.lcssa.fr, 3
  br i1 %239, label %Then20.epil.preheader, label %Then20.preheader.new

Then20.preheader.new:                             ; preds = %Then20.preheader
  %unroll_iter535 = and i64 %162, -4
  br label %Then20

Then20.us.preheader:                              ; preds = %Loop8.preheader
  %.pre464 = load i32, ptr %4, align 4
  %xtraiter537 = and i64 %162, 1
  %240 = icmp eq i64 %.0399.lcssa.fr, 0
  br i1 %240, label %Then20.us.epil.preheader, label %Then20.us.preheader.new

Then20.us.preheader.new:                          ; preds = %Then20.us.preheader
  %unroll_iter542 = and i64 %162, -2
  br label %Then20.us

Then20.us:                                        ; preds = %Then20.us, %Then20.us.preheader.new
  %241 = phi i32 [ %.pre464, %Then20.us.preheader.new ], [ %252, %Then20.us ]
  %.4444.us = phi i64 [ 0, %Then20.us.preheader.new ], [ %250, %Then20.us ]
  %niter543 = phi i64 [ 0, %Then20.us.preheader.new ], [ %niter543.next.1, %Then20.us ]
  %242 = lshr i32 %241, %.fr447
  %243 = or disjoint i64 %.4444.us, 1
  %244 = getelementptr inbounds [4 x i8], ptr %4, i64 %243
  %245 = load i32, ptr %244, align 4
  %246 = shl i32 %245, %.pre-phi467
  %247 = or i32 %246, %242
  %248 = getelementptr inbounds [4 x i8], ptr %0, i64 %.4444.us
  store i32 %247, ptr %248, align 4
  %249 = lshr i32 %245, %.fr447
  %250 = add nuw i64 %.4444.us, 2
  %251 = getelementptr inbounds [4 x i8], ptr %4, i64 %250
  %252 = load i32, ptr %251, align 4
  %253 = shl i32 %252, %.pre-phi467
  %254 = or i32 %253, %249
  %255 = getelementptr inbounds [4 x i8], ptr %0, i64 %243
  store i32 %254, ptr %255, align 4
  %niter543.next.1 = add i64 %niter543, 2
  %niter543.ncmp.1 = icmp eq i64 %niter543.next.1, %unroll_iter542
  br i1 %niter543.ncmp.1, label %Else20.loopexit.unr-lcssa, label %Then20.us

Then17:                                           ; preds = %Then17, %Then17.preheader
  %.0441 = phi i64 [ %274, %Then17 ], [ 0, %Then17.preheader ]
  %.3440 = phi i64 [ %275, %Then17 ], [ 0, %Then17.preheader ]
  %niter531 = phi i64 [ %niter531.next.1, %Then17 ], [ 0, %Then17.preheader ]
  %gep439 = getelementptr [4 x i8], ptr %invariant.gep, i64 %.3440
  %256 = load i32, ptr %gep439, align 4
  %257 = zext i32 %256 to i64
  %258 = getelementptr inbounds [4 x i8], ptr %5, i64 %.3440
  %259 = load i32, ptr %258, align 4
  %260 = zext i32 %259 to i64
  %261 = add nuw nsw i64 %.0441, %257
  %262 = add nuw nsw i64 %261, %260
  %263 = trunc i64 %262 to i32
  store i32 %263, ptr %gep439, align 4
  %264 = lshr i64 %262, 32
  %265 = or disjoint i64 %.3440, 1
  %gep439.1 = getelementptr [4 x i8], ptr %invariant.gep, i64 %265
  %266 = load i32, ptr %gep439.1, align 4
  %267 = zext i32 %266 to i64
  %268 = getelementptr inbounds [4 x i8], ptr %5, i64 %265
  %269 = load i32, ptr %268, align 4
  %270 = zext i32 %269 to i64
  %271 = add nuw nsw i64 %264, %267
  %272 = add nuw nsw i64 %271, %270
  %273 = trunc i64 %272 to i32
  store i32 %273, ptr %gep439.1, align 4
  %274 = lshr i64 %272, 32
  %275 = add i64 %.3440, 2
  %niter531.next.1 = add i64 %niter531, 2
  %niter531.ncmp.1 = icmp eq i64 %niter531.next.1, %unroll_iter530
  br i1 %niter531.ncmp.1, label %Else17.unr-lcssa, label %Then17

Else17.unr-lcssa:                                 ; preds = %Then17
  br i1 %lcmp.mod527.not, label %Else17, label %Then17.epil.preheader

Then17.epil.preheader:                            ; preds = %Else17.unr-lcssa, %Then17.preheader
  %.0441.epil.init = phi i64 [ 0, %Then17.preheader ], [ %274, %Else17.unr-lcssa ]
  %.3440.epil.init = phi i64 [ 0, %Then17.preheader ], [ %275, %Else17.unr-lcssa ]
  tail call void @llvm.assume(i1 %lcmp.mod529)
  %gep439.epil = getelementptr [4 x i8], ptr %invariant.gep, i64 %.3440.epil.init
  %276 = load i32, ptr %gep439.epil, align 4
  %277 = zext i32 %276 to i64
  %278 = getelementptr inbounds [4 x i8], ptr %5, i64 %.3440.epil.init
  %279 = load i32, ptr %278, align 4
  %280 = zext i32 %279 to i64
  %281 = add nuw nsw i64 %.0441.epil.init, %277
  %282 = add nuw nsw i64 %281, %280
  %283 = trunc i64 %282 to i32
  store i32 %283, ptr %gep439.epil, align 4
  %284 = lshr i64 %282, 32
  br label %Else17

Else17:                                           ; preds = %Then17.epil.preheader, %Else17.unr-lcssa
  %.lcssa501 = phi i64 [ %274, %Else17.unr-lcssa ], [ %284, %Then17.epil.preheader ]
  %285 = load i32, ptr %165, align 4
  %286 = trunc nuw nsw i64 %.lcssa501 to i32
  %287 = add i32 %285, %286
  store i32 %287, ptr %165, align 4
  br label %Block55

Then20:                                           ; preds = %Then20, %Then20.preheader.new
  %.4444 = phi i64 [ 0, %Then20.preheader.new ], [ %306, %Then20 ]
  %niter536 = phi i64 [ 0, %Then20.preheader.new ], [ %niter536.next.3, %Then20 ]
  %288 = getelementptr inbounds [4 x i8], ptr %4, i64 %.4444
  %289 = load i32, ptr %288, align 4
  %290 = lshr i32 %289, %.fr447
  %291 = or disjoint i64 %.4444, 1
  %292 = getelementptr inbounds [4 x i8], ptr %0, i64 %.4444
  store i32 %290, ptr %292, align 4
  %293 = getelementptr inbounds [4 x i8], ptr %4, i64 %291
  %294 = load i32, ptr %293, align 4
  %295 = lshr i32 %294, %.fr447
  %296 = or disjoint i64 %.4444, 2
  %297 = getelementptr inbounds [4 x i8], ptr %0, i64 %291
  store i32 %295, ptr %297, align 4
  %298 = getelementptr inbounds [4 x i8], ptr %4, i64 %296
  %299 = load i32, ptr %298, align 4
  %300 = lshr i32 %299, %.fr447
  %301 = or disjoint i64 %.4444, 3
  %302 = getelementptr inbounds [4 x i8], ptr %0, i64 %296
  store i32 %300, ptr %302, align 4
  %303 = getelementptr inbounds [4 x i8], ptr %4, i64 %301
  %304 = load i32, ptr %303, align 4
  %305 = lshr i32 %304, %.fr447
  %306 = add i64 %.4444, 4
  %307 = getelementptr inbounds [4 x i8], ptr %0, i64 %301
  store i32 %305, ptr %307, align 4
  %niter536.next.3 = add i64 %niter536, 4
  %niter536.ncmp.3 = icmp eq i64 %niter536.next.3, %unroll_iter535
  br i1 %niter536.ncmp.3, label %Else20.loopexit497.unr-lcssa, label %Then20

Else20.loopexit.unr-lcssa:                        ; preds = %Then20.us
  %lcmp.mod540.not = icmp eq i64 %xtraiter537, 0
  br i1 %lcmp.mod540.not, label %Else20, label %Then20.us.epil.preheader

Then20.us.epil.preheader:                         ; preds = %Else20.loopexit.unr-lcssa, %Then20.us.preheader
  %.epil.init = phi i32 [ %.pre464, %Then20.us.preheader ], [ %252, %Else20.loopexit.unr-lcssa ]
  %.4444.us.epil.init = phi i64 [ 0, %Then20.us.preheader ], [ %250, %Else20.loopexit.unr-lcssa ]
  %lcmp.mod541 = icmp ne i64 %xtraiter537, 0
  tail call void @llvm.assume(i1 %lcmp.mod541)
  %308 = lshr i32 %.epil.init, %.fr447
  %309 = getelementptr [4 x i8], ptr %4, i64 %.4444.us.epil.init
  %310 = getelementptr i8, ptr %309, i64 4
  %311 = load i32, ptr %310, align 4
  %312 = shl i32 %311, %.pre-phi467
  %313 = or i32 %312, %308
  %314 = getelementptr inbounds [4 x i8], ptr %0, i64 %.4444.us.epil.init
  store i32 %313, ptr %314, align 4
  br label %Else20

Else20.loopexit497.unr-lcssa:                     ; preds = %Then20
  %lcmp.mod533.not = icmp eq i64 %xtraiter532, 0
  br i1 %lcmp.mod533.not, label %Else20, label %Then20.epil.preheader

Then20.epil.preheader:                            ; preds = %Else20.loopexit497.unr-lcssa, %Then20.preheader
  %.4444.epil.init = phi i64 [ 0, %Then20.preheader ], [ %306, %Else20.loopexit497.unr-lcssa ]
  %lcmp.mod534 = icmp ne i64 %xtraiter532, 0
  tail call void @llvm.assume(i1 %lcmp.mod534)
  br label %Then20.epil

Then20.epil:                                      ; preds = %Then20.epil, %Then20.epil.preheader
  %.4444.epil = phi i64 [ %318, %Then20.epil ], [ %.4444.epil.init, %Then20.epil.preheader ]
  %epil.iter = phi i64 [ %epil.iter.next, %Then20.epil ], [ 0, %Then20.epil.preheader ]
  %315 = getelementptr inbounds [4 x i8], ptr %4, i64 %.4444.epil
  %316 = load i32, ptr %315, align 4
  %317 = lshr i32 %316, %.fr447
  %318 = add i64 %.4444.epil, 1
  %319 = getelementptr inbounds [4 x i8], ptr %0, i64 %.4444.epil
  store i32 %317, ptr %319, align 4
  %epil.iter.next = add i64 %epil.iter, 1
  %epil.iter.cmp.not = icmp eq i64 %epil.iter.next, %xtraiter532
  br i1 %epil.iter.cmp.not, label %Else20, label %Then20.epil, !llvm.loop !9

Else20:                                           ; preds = %Then20.epil, %Else20.loopexit497.unr-lcssa, %Then20.us.epil.preheader, %Else20.loopexit.unr-lcssa
  %320 = load i32, ptr %invariant.gep442, align 4
  %321 = lshr i32 %320, %.fr447
  %322 = getelementptr inbounds [4 x i8], ptr %0, i64 %.0399.lcssa.fr
  store i32 %321, ptr %322, align 4
  br label %Block1
}

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memcpy.inline.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #4

attributes #0 = { nofree norecurse nosync nounwind memory(argmem: readwrite, inaccessiblemem: write) uwtable "frame-pointer"="all" "no-builtins" "target-cpu"="x86-64" "target-features"="+64bit,+cmov,+cx8,+fxsr,+idivq-to-divl,+macrofusion,+mmx,+nopl,+slow-3ops-lea,+slow-incdec,+sse,+sse2,+vzeroupper,+x87,-16bit-mode,-32bit-mode,-adx,-aes,-allow-light-256-bit,-amx-avx512,-amx-bf16,-amx-complex,-amx-fp16,-amx-fp8,-amx-int8,-amx-movrs,-amx-tf32,-amx-tile,-avx,-avx10.1,-avx10.2,-avx2,-avx512bf16,-avx512bitalg,-avx512bw,-avx512cd,-avx512dq,-avx512f,-avx512fp16,-avx512ifma,-avx512vbmi,-avx512vbmi2,-avx512vl,-avx512vnni,-avx512vp2intersect,-avx512vpopcntdq,-avxifma,-avxneconvert,-avxvnni,-avxvnniint16,-avxvnniint8,-bmi,-bmi2,-branch-hint,-branchfusion,-ccmp,-cf,-cldemote,-clflushopt,-clwb,-clzero,-cmpccxadd,-crc32,-cx16,-egpr,-enqcmd,-ermsb,-f16c,-false-deps-getmant,-false-deps-lzcnt-tzcnt,-false-deps-mulc,-false-deps-mullq,-false-deps-perm,-false-deps-popcnt,-false-deps-range,-fast-11bytenop,-fast-15bytenop,-fast-7bytenop,-fast-bextr,-fast-dpwssd,-fast-gather,-fast-hops,-fast-imm16,-fast-lzcnt,-fast-movbe,-fast-scalar-fsqrt,-fast-scalar-shift-masks,-fast-shld-rotate,-fast-variable-crosslane-shuffle,-fast-variable-perlane-shuffle,-fast-vector-fsqrt,-fast-vector-shift-masks,-faster-shift-than-shuffle,-fma,-fma4,-fsgsbase,-fsrm,-gfni,-harden-sls-ijmp,-harden-sls-ret,-hreset,-idivl-to-divb,-inline-asm-use-gpr32,-invpcid,-kl,-lea-sp,-lea-uses-ag,-lvi-cfi,-lvi-load-hardening,-lwp,-lzcnt,-movbe,-movdir64b,-movdiri,-movrs,-mwaitx,-ndd,-nf,-no-bypass-delay,-no-bypass-delay-blend,-no-bypass-delay-mov,-no-bypass-delay-shuffle,-pad-short-functions,-pclmul,-pconfig,-pku,-popcnt,-ppx,-prefer-128-bit,-prefer-256-bit,-prefer-legacy-setcc,-prefer-mask-registers,-prefer-movmsk-over-vtest,-prefer-no-gather,-prefer-no-scatter,-prefetchi,-prfchw,-ptwrite,-push2pop2,-raoint,-rdpid,-rdpru,-rdrnd,-rdseed,-retpoline,-retpoline-external-thunk,-retpoline-indirect-branches,-retpoline-indirect-calls,-rtm,-sahf,-sbb-dep-breaking,-serialize,-seses,-sgx,-sha,-sha512,-shstk,-slow-lea,-slow-pmaddwd,-slow-pmulld,-slow-pmullq,-slow-shld,-slow-two-mem-ops,-slow-unaligned-mem-16,-slow-unaligned-mem-32,-sm3,-sm4,-soft-float,-sse3,-sse4.1,-sse4.2,-sse4a,-sse-unaligned-mem,-ssse3,-tagged-globals,-tbm,-tsxldtrk,-tuning-fast-imm-vector-shift,-uintr,-use-glm-div-sqrt-costs,-use-slm-arith-costs,-usermsr,-vaes,-vpclmulqdq,-waitpkg,-wbnoinvd,-widekl,-xop,-xsave,-xsavec,-xsaveopt,-xsaves,-zu" }
attributes #1 = { nocallback nofree nosync nounwind willreturn memory(inaccessiblemem: write) }
attributes #2 = { mustprogress nofree norecurse nosync nounwind willreturn memory(inaccessiblemem: write) uwtable "frame-pointer"="all" "no-builtins" "target-cpu"="x86-64" "target-features"="+64bit,+cmov,+cx8,+fxsr,+idivq-to-divl,+macrofusion,+mmx,+nopl,+slow-3ops-lea,+slow-incdec,+sse,+sse2,+vzeroupper,+x87,-16bit-mode,-32bit-mode,-adx,-aes,-allow-light-256-bit,-amx-avx512,-amx-bf16,-amx-complex,-amx-fp16,-amx-fp8,-amx-int8,-amx-movrs,-amx-tf32,-amx-tile,-avx,-avx10.1,-avx10.2,-avx2,-avx512bf16,-avx512bitalg,-avx512bw,-avx512cd,-avx512dq,-avx512f,-avx512fp16,-avx512ifma,-avx512vbmi,-avx512vbmi2,-avx512vl,-avx512vnni,-avx512vp2intersect,-avx512vpopcntdq,-avxifma,-avxneconvert,-avxvnni,-avxvnniint16,-avxvnniint8,-bmi,-bmi2,-branch-hint,-branchfusion,-ccmp,-cf,-cldemote,-clflushopt,-clwb,-clzero,-cmpccxadd,-crc32,-cx16,-egpr,-enqcmd,-ermsb,-f16c,-false-deps-getmant,-false-deps-lzcnt-tzcnt,-false-deps-mulc,-false-deps-mullq,-false-deps-perm,-false-deps-popcnt,-false-deps-range,-fast-11bytenop,-fast-15bytenop,-fast-7bytenop,-fast-bextr,-fast-dpwssd,-fast-gather,-fast-hops,-fast-imm16,-fast-lzcnt,-fast-movbe,-fast-scalar-fsqrt,-fast-scalar-shift-masks,-fast-shld-rotate,-fast-variable-crosslane-shuffle,-fast-variable-perlane-shuffle,-fast-vector-fsqrt,-fast-vector-shift-masks,-faster-shift-than-shuffle,-fma,-fma4,-fsgsbase,-fsrm,-gfni,-harden-sls-ijmp,-harden-sls-ret,-hreset,-idivl-to-divb,-inline-asm-use-gpr32,-invpcid,-kl,-lea-sp,-lea-uses-ag,-lvi-cfi,-lvi-load-hardening,-lwp,-lzcnt,-movbe,-movdir64b,-movdiri,-movrs,-mwaitx,-ndd,-nf,-no-bypass-delay,-no-bypass-delay-blend,-no-bypass-delay-mov,-no-bypass-delay-shuffle,-pad-short-functions,-pclmul,-pconfig,-pku,-popcnt,-ppx,-prefer-128-bit,-prefer-256-bit,-prefer-legacy-setcc,-prefer-mask-registers,-prefer-movmsk-over-vtest,-prefer-no-gather,-prefer-no-scatter,-prefetchi,-prfchw,-ptwrite,-push2pop2,-raoint,-rdpid,-rdpru,-rdrnd,-rdseed,-retpoline,-retpoline-external-thunk,-retpoline-indirect-branches,-retpoline-indirect-calls,-rtm,-sahf,-sbb-dep-breaking,-serialize,-seses,-sgx,-sha,-sha512,-shstk,-slow-lea,-slow-pmaddwd,-slow-pmulld,-slow-pmullq,-slow-shld,-slow-two-mem-ops,-slow-unaligned-mem-16,-slow-unaligned-mem-32,-sm3,-sm4,-soft-float,-sse3,-sse4.1,-sse4.2,-sse4a,-sse-unaligned-mem,-ssse3,-tagged-globals,-tbm,-tsxldtrk,-tuning-fast-imm-vector-shift,-uintr,-use-glm-div-sqrt-costs,-use-slm-arith-costs,-usermsr,-vaes,-vpclmulqdq,-waitpkg,-wbnoinvd,-widekl,-xop,-xsave,-xsavec,-xsaveopt,-xsaves,-zu" }
attributes #3 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #4 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
attributes #5 = { nobuiltin }

!llvm.module.flags = !{!0, !1}

!0 = !{i32 2, !"Debug Info Version", i32 3}
!1 = !{i32 7, !"Dwarf Version", i32 4}
!2 = distinct !{!2, !3}
!3 = !{!"llvm.loop.unroll.disable"}
!4 = distinct !{!4, !3}
!5 = distinct !{!5, !3}
!6 = distinct !{!6, !3}
!7 = distinct !{!7, !3}
!8 = distinct !{!8, !3}
!9 = distinct !{!9, !3}
