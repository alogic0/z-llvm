; INBOX-54 exact captured __divei4/__divei5 audit bodies, linked and debug-stripped.
; Source md5: b0eda7a6427c3084fdf096a68696f19c.
; ModuleID = 'tmp/inbox54_signed_div.bc'
source_filename = "llvm-link"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux5.10.0-gnu2.31.0"

; Function Attrs: nofree norecurse nosync nounwind memory(argmem: readwrite, inaccessiblemem: write) uwtable
define hidden void @compiler_rt.divmodei4.__divei4(ptr nonnull align 1 captures(address) %0, ptr nonnull align 1 captures(none) %1, ptr nonnull align 1 captures(none) %2, i64 %3) unnamed_addr #0 align 1 {
Entry:
  %.sroa.2508 = alloca i8, align 4
  %.sroa.0504 = alloca i8, align 1
  %4 = alloca [2049 x i32], align 4
  %5 = alloca [2048 x i32], align 4
  %.sroa.2100 = alloca i8, align 4
  %.sroa.096 = alloca i8, align 1
  %.sroa.282 = alloca i8, align 4
  %.sroa.079 = alloca i8, align 1
  %6 = icmp ult i64 %3, 65536
  tail call void @llvm.assume(i1 %6)
  %7 = trunc nuw i64 %3 to i16
  %8 = tail call fastcc i16 @zig.target.intByteSize(i16 %7) #6
  %9 = lshr i16 %8, 2
  %10 = zext nneg i16 %9 to i64
  %11 = add nsw i64 %10, -1
  %12 = getelementptr inbounds nuw [4 x i8], ptr %1, i64 %11
  %13 = load i32, ptr %12, align 4
  %14 = getelementptr inbounds nuw [4 x i8], ptr %2, i64 %11
  %15 = load i32, ptr %14, align 4
  %16 = icmp slt i32 %13, 0
  br i1 %16, label %Then, label %Block4

Block1:                                           ; preds = %Then28, %TryCont
  ret void

Block4:                                           ; preds = %Then1, %Entry
  %17 = icmp slt i32 %15, 0
  br i1 %17, label %Then2, label %Block16

Then:                                             ; preds = %Entry
  store i1 true, ptr %.sroa.079, align 1
  %.not564 = icmp eq i16 %9, 0
  br i1 %.not564, label %Block19, label %Then1

Then1:                                            ; preds = %Then1, %Then
  %.0519542 = phi i64 [ %27, %Then1 ], [ 0, %Then ]
  %18 = getelementptr inbounds nuw [4 x i8], ptr %1, i64 %.0519542
  %19 = load i32, ptr %18, align 4
  %20 = xor i32 %19, -1
  %.sroa.079.0..sroa.079.0..sroa.079.0..sroa.079.0..sroa.079.0. = load i8, ptr %.sroa.079, align 1
  %21 = and i8 %.sroa.079.0..sroa.079.0..sroa.079.0..sroa.079.0..sroa.079.0., 1
  %22 = zext nneg i8 %21 to i32
  %23 = tail call { i32, i1 } @llvm.uadd.with.overflow.i32(i32 %20, i32 %22)
  %24 = extractvalue { i32, i1 } %23, 0
  %25 = extractvalue { i32, i1 } %23, 1
  store i1 %25, ptr %.sroa.282, align 4
  %.sroa.282.0..sroa.282.0..sroa.282.0..sroa.282.0..sroa.282.4. = load i8, ptr %.sroa.282, align 4
  %26 = trunc i8 %.sroa.282.0..sroa.282.0..sroa.282.0..sroa.282.0..sroa.282.4. to i1
  store i1 %26, ptr %.sroa.079, align 1
  store i32 %24, ptr %18, align 4
  %27 = add nuw nsw i64 %.0519542, 1
  %exitcond.not = icmp eq i64 %27, %10
  br i1 %exitcond.not, label %Block4, label %Then1

Then2:                                            ; preds = %Block4
  store i1 true, ptr %.sroa.096, align 1
  %.not565 = icmp eq i16 %9, 0
  br i1 %.not565, label %Block19, label %Then3

Then3:                                            ; preds = %Then3, %Then2
  %.0518543 = phi i64 [ %37, %Then3 ], [ 0, %Then2 ]
  %28 = getelementptr inbounds nuw [4 x i8], ptr %2, i64 %.0518543
  %29 = load i32, ptr %28, align 4
  %30 = xor i32 %29, -1
  %.sroa.096.0..sroa.096.0..sroa.096.0..sroa.096.0..sroa.096.0. = load i8, ptr %.sroa.096, align 1
  %31 = and i8 %.sroa.096.0..sroa.096.0..sroa.096.0..sroa.096.0..sroa.096.0., 1
  %32 = zext nneg i8 %31 to i32
  %33 = tail call { i32, i1 } @llvm.uadd.with.overflow.i32(i32 %30, i32 %32)
  %34 = extractvalue { i32, i1 } %33, 0
  %35 = extractvalue { i32, i1 } %33, 1
  store i1 %35, ptr %.sroa.2100, align 4
  %.sroa.2100.0..sroa.2100.0..sroa.2100.0..sroa.2100.0..sroa.2100.4. = load i8, ptr %.sroa.2100, align 4
  %36 = trunc i8 %.sroa.2100.0..sroa.2100.0..sroa.2100.0..sroa.2100.0..sroa.2100.4. to i1
  store i1 %36, ptr %.sroa.096, align 1
  store i32 %34, ptr %28, align 4
  %37 = add nuw nsw i64 %.0518543, 1
  %exitcond578.not = icmp eq i64 %37, %10
  br i1 %exitcond578.not, label %InlineMemsetBody.preheader, label %Then3

Block16:                                          ; preds = %Block4
  %.not544 = icmp eq i16 %9, 0
  br i1 %.not544, label %Block19, label %InlineMemsetBody.preheader

InlineMemsetBody.preheader:                       ; preds = %Block16, %Then3
  %.idx598.pn = shl nuw nsw i64 %10, 2
  %38 = getelementptr inbounds nuw i8, ptr %0, i64 %.idx598.pn
  %39 = add nsw i64 %.idx598.pn, -4
  %40 = lshr exact i64 %39, 2
  %41 = add nuw nsw i64 %40, 1
  %xtraiter = and i64 %41, 7
  %42 = and i64 %39, 28
  %lcmp.mod.not = icmp eq i64 %42, 28
  br i1 %lcmp.mod.not, label %InlineMemsetBody.prol.loopexit, label %InlineMemsetBody.prol

InlineMemsetBody.prol:                            ; preds = %InlineMemsetBody.prol, %InlineMemsetBody.preheader
  %43 = phi ptr [ %44, %InlineMemsetBody.prol ], [ %0, %InlineMemsetBody.preheader ]
  %prol.iter = phi i64 [ %prol.iter.next, %InlineMemsetBody.prol ], [ 0, %InlineMemsetBody.preheader ]
  store i32 0, ptr %43, align 4
  %44 = getelementptr inbounds nuw i8, ptr %43, i64 4
  %prol.iter.next = add i64 %prol.iter, 1
  %prol.iter.cmp.not = icmp eq i64 %prol.iter.next, %xtraiter
  br i1 %prol.iter.cmp.not, label %InlineMemsetBody.prol.loopexit, label %InlineMemsetBody.prol, !llvm.loop !2

InlineMemsetBody.prol.loopexit:                   ; preds = %InlineMemsetBody.prol, %InlineMemsetBody.preheader
  %.unr = phi ptr [ %0, %InlineMemsetBody.preheader ], [ %44, %InlineMemsetBody.prol ]
  %45 = icmp ult i64 %39, 28
  br i1 %45, label %Block19, label %InlineMemsetBody

Block19:                                          ; preds = %InlineMemsetBody, %InlineMemsetBody.prol.loopexit, %Block16, %Then2, %Then
  %46 = icmp ne i16 %9, 0
  tail call void @llvm.assume(i1 %46)
  %47 = load i32, ptr %12, align 4
  %48 = icmp eq i32 %47, 0
  br i1 %48, label %Then9, label %Loop3.preheader

InlineMemsetBody:                                 ; preds = %InlineMemsetBody, %InlineMemsetBody.prol.loopexit
  %49 = phi ptr [ %57, %InlineMemsetBody ], [ %.unr, %InlineMemsetBody.prol.loopexit ]
  store i32 0, ptr %49, align 4
  %50 = getelementptr inbounds nuw i8, ptr %49, i64 4
  store i32 0, ptr %50, align 4
  %51 = getelementptr inbounds nuw i8, ptr %49, i64 8
  store i32 0, ptr %51, align 4
  %52 = getelementptr inbounds nuw i8, ptr %49, i64 12
  store i32 0, ptr %52, align 4
  %53 = getelementptr inbounds nuw i8, ptr %49, i64 16
  store i32 0, ptr %53, align 4
  %54 = getelementptr inbounds nuw i8, ptr %49, i64 20
  store i32 0, ptr %54, align 4
  %55 = getelementptr inbounds nuw i8, ptr %49, i64 24
  store i32 0, ptr %55, align 4
  %56 = getelementptr inbounds nuw i8, ptr %49, i64 28
  store i32 0, ptr %56, align 4
  %57 = getelementptr inbounds nuw i8, ptr %49, i64 32
  %.not.7 = icmp eq ptr %57, %38
  br i1 %.not.7, label %Block19, label %InlineMemsetBody

Loop3.preheader:                                  ; preds = %Else10, %Block19
  %.0517.lcssa = phi i64 [ %11, %Block19 ], [ %61, %Else10 ]
  %.pre583 = phi i32 [ %47, %Block19 ], [ %63, %Else10 ]
  %58 = load i32, ptr %14, align 4
  %59 = icmp eq i32 %58, 0
  br i1 %59, label %Then11, label %Else11

Then9:                                            ; preds = %Else10, %Block19
  %.0517545 = phi i64 [ %61, %Else10 ], [ %11, %Block19 ]
  %60 = icmp eq i64 %.0517545, 0
  br i1 %60, label %TryCont, label %Else10

Else10:                                           ; preds = %Then9
  %61 = add nsw i64 %.0517545, -1
  %62 = getelementptr inbounds nuw [4 x i8], ptr %1, i64 %61
  %63 = load i32, ptr %62, align 4
  %64 = icmp eq i32 %63, 0
  br i1 %64, label %Then9, label %Loop3.preheader

Then11:                                           ; preds = %Then11, %Loop3.preheader
  %.0516547 = phi i64 [ %66, %Then11 ], [ %11, %Loop3.preheader ]
  %65 = icmp ne i64 %.0516547, 0
  tail call void @llvm.assume(i1 %65)
  %66 = add nsw i64 %.0516547, -1
  %67 = getelementptr inbounds nuw [4 x i8], ptr %2, i64 %66
  %68 = load i32, ptr %67, align 4
  %69 = icmp eq i32 %68, 0
  br i1 %69, label %Then11, label %Else11

Else11:                                           ; preds = %Then11, %Loop3.preheader
  %.0516.lcssa = phi i64 [ %11, %Loop3.preheader ], [ %66, %Then11 ]
  %.lcssa = phi i32 [ %58, %Loop3.preheader ], [ %68, %Then11 ]
  %.0516.lcssa.fr = freeze i64 %.0516.lcssa
  %70 = icmp ugt i64 %.0516.lcssa.fr, %.0517.lcssa
  br i1 %70, label %TryCont, label %Else13

Else13:                                           ; preds = %Else11
  %71 = tail call range(i32 0, 33) i32 @llvm.ctlz.i32(i32 %.lcssa, i1 true)
  %.fr567 = freeze i32 %71
  %72 = trunc i32 %.fr567 to i6
  %.not524550 = icmp eq i64 %.0516.lcssa.fr, 0
  %.pre584 = sub i6 -32, %72
  br i1 %.not524550, label %Else13.Else14_crit_edge, label %Then14.lr.ph

Else13.Else14_crit_edge:                          ; preds = %Else13
  %.pre585 = zext nneg i6 %.pre584 to i32
  br label %Else14

Then14.lr.ph:                                     ; preds = %Else13
  %73 = icmp sgt i6 %.pre584, -1
  %74 = zext nneg i6 %.pre584 to i32
  br i1 %73, label %Then14.us.preheader, label %Then14.preheader

Then14.preheader:                                 ; preds = %Then14.lr.ph
  %xtraiter630 = and i64 %.0516.lcssa.fr, 3
  %lcmp.mod631.not = icmp eq i64 %xtraiter630, 0
  br i1 %lcmp.mod631.not, label %Then14.prol.loopexit, label %Then14.prol

Then14.prol:                                      ; preds = %Then14.prol, %Then14.preheader
  %.0514551.prol = phi i64 [ %78, %Then14.prol ], [ %.0516.lcssa.fr, %Then14.preheader ]
  %prol.iter632 = phi i64 [ %prol.iter632.next, %Then14.prol ], [ 0, %Then14.preheader ]
  %75 = getelementptr inbounds nuw [4 x i8], ptr %2, i64 %.0514551.prol
  %76 = load i32, ptr %75, align 4
  %77 = shl i32 %76, %.fr567
  %78 = add nsw i64 %.0514551.prol, -1
  %79 = getelementptr inbounds nuw [4 x i8], ptr %5, i64 %.0514551.prol
  store i32 %77, ptr %79, align 4
  %prol.iter632.next = add i64 %prol.iter632, 1
  %prol.iter632.cmp.not = icmp eq i64 %prol.iter632.next, %xtraiter630
  br i1 %prol.iter632.cmp.not, label %Then14.prol.loopexit, label %Then14.prol, !llvm.loop !4

Then14.prol.loopexit:                             ; preds = %Then14.prol, %Then14.preheader
  %.0514551.unr = phi i64 [ %.0516.lcssa.fr, %Then14.preheader ], [ %78, %Then14.prol ]
  %80 = icmp ult i64 %.0516.lcssa.fr, 4
  br i1 %80, label %Else14, label %Then14

Then14.us.preheader:                              ; preds = %Then14.lr.ph
  %.phi.trans.insert = getelementptr inbounds nuw [4 x i8], ptr %2, i64 %.0516.lcssa.fr
  %.pre = load i32, ptr %.phi.trans.insert, align 4
  %xtraiter633 = and i64 %.0516.lcssa.fr, 1
  %lcmp.mod634.not = icmp eq i64 %xtraiter633, 0
  br i1 %lcmp.mod634.not, label %Then14.us.prol.loopexit, label %Then14.us.prol

Then14.us.prol:                                   ; preds = %Then14.us.preheader
  %81 = shl i32 %.pre, %.fr567
  %82 = add nsw i64 %.0516.lcssa.fr, -1
  %83 = getelementptr inbounds nuw [4 x i8], ptr %2, i64 %82
  %84 = load i32, ptr %83, align 4
  %85 = lshr i32 %84, %74
  %86 = or i32 %85, %81
  %87 = getelementptr inbounds nuw [4 x i8], ptr %5, i64 %.0516.lcssa.fr
  store i32 %86, ptr %87, align 4
  br label %Then14.us.prol.loopexit

Then14.us.prol.loopexit:                          ; preds = %Then14.us.prol, %Then14.us.preheader
  %.unr636 = phi i32 [ %.pre, %Then14.us.preheader ], [ %84, %Then14.us.prol ]
  %.0514551.us.unr = phi i64 [ %.0516.lcssa.fr, %Then14.us.preheader ], [ %82, %Then14.us.prol ]
  %88 = icmp eq i64 %.0516.lcssa.fr, 1
  br i1 %88, label %Else14, label %Then14.us

Then14.us:                                        ; preds = %Then14.us, %Then14.us.prol.loopexit
  %89 = phi i32 [ %100, %Then14.us ], [ %.unr636, %Then14.us.prol.loopexit ]
  %.0514551.us = phi i64 [ %98, %Then14.us ], [ %.0514551.us.unr, %Then14.us.prol.loopexit ]
  %90 = shl i32 %89, %.fr567
  %91 = add nsw i64 %.0514551.us, -1
  %92 = getelementptr inbounds nuw [4 x i8], ptr %2, i64 %91
  %93 = load i32, ptr %92, align 4
  %94 = lshr i32 %93, %74
  %95 = or i32 %94, %90
  %96 = getelementptr inbounds nuw [4 x i8], ptr %5, i64 %.0514551.us
  store i32 %95, ptr %96, align 4
  %97 = shl i32 %93, %.fr567
  %98 = add nsw i64 %.0514551.us, -2
  %99 = getelementptr inbounds nuw [4 x i8], ptr %2, i64 %98
  %100 = load i32, ptr %99, align 4
  %101 = lshr i32 %100, %74
  %102 = or i32 %101, %97
  %103 = getelementptr inbounds nuw [4 x i8], ptr %5, i64 %91
  store i32 %102, ptr %103, align 4
  %.not524.us.1 = icmp eq i64 %98, 0
  br i1 %.not524.us.1, label %Else14, label %Then14.us

Then14:                                           ; preds = %Then14, %Then14.prol.loopexit
  %.0514551 = phi i64 [ %122, %Then14 ], [ %.0514551.unr, %Then14.prol.loopexit ]
  %104 = getelementptr inbounds nuw [4 x i8], ptr %2, i64 %.0514551
  %105 = load i32, ptr %104, align 4
  %106 = shl i32 %105, %.fr567
  %107 = add nsw i64 %.0514551, -1
  %108 = getelementptr inbounds nuw [4 x i8], ptr %5, i64 %.0514551
  store i32 %106, ptr %108, align 4
  %109 = getelementptr inbounds nuw [4 x i8], ptr %2, i64 %107
  %110 = load i32, ptr %109, align 4
  %111 = shl i32 %110, %.fr567
  %112 = add nsw i64 %.0514551, -2
  %113 = getelementptr inbounds nuw [4 x i8], ptr %5, i64 %107
  store i32 %111, ptr %113, align 4
  %114 = getelementptr inbounds nuw [4 x i8], ptr %2, i64 %112
  %115 = load i32, ptr %114, align 4
  %116 = shl i32 %115, %.fr567
  %117 = add nsw i64 %.0514551, -3
  %118 = getelementptr inbounds nuw [4 x i8], ptr %5, i64 %112
  store i32 %116, ptr %118, align 4
  %119 = getelementptr inbounds nuw [4 x i8], ptr %2, i64 %117
  %120 = load i32, ptr %119, align 4
  %121 = shl i32 %120, %.fr567
  %122 = add nsw i64 %.0514551, -4
  %123 = getelementptr inbounds nuw [4 x i8], ptr %5, i64 %117
  store i32 %121, ptr %123, align 4
  %.not524.3 = icmp eq i64 %122, 0
  br i1 %.not524.3, label %Else14, label %Then14

Else14:                                           ; preds = %Then14, %Then14.us, %Then14.us.prol.loopexit, %Then14.prol.loopexit, %Else13.Else14_crit_edge
  %.pre-phi586 = phi i32 [ %.pre585, %Else13.Else14_crit_edge ], [ %74, %Then14.us.prol.loopexit ], [ %74, %Then14.us ], [ %74, %Then14 ], [ %74, %Then14.prol.loopexit ]
  %124 = load i32, ptr %2, align 4
  %125 = shl i32 %124, %.fr567
  store i32 %125, ptr %5, align 4
  %126 = icmp sgt i6 %.pre584, -1
  %127 = lshr i32 %.pre583, %.pre-phi586
  %common.ret.op.i532 = select i1 %126, i32 %127, i32 0
  %128 = getelementptr inbounds nuw [4 x i8], ptr %4, i64 %.0517.lcssa
  %129 = getelementptr inbounds nuw i8, ptr %128, i64 4
  store i32 %common.ret.op.i532, ptr %129, align 4
  %.not525552 = icmp eq i64 %.0517.lcssa, 0
  br i1 %.not525552, label %Else15, label %Then15.preheader

Then15.preheader:                                 ; preds = %Else14
  %xtraiter637 = and i64 %.0517.lcssa, 1
  %lcmp.mod638.not = icmp eq i64 %xtraiter637, 0
  br i1 %lcmp.mod638.not, label %Then15.prol.loopexit, label %Then15.prol

Then15.prol:                                      ; preds = %Then15.preheader
  %130 = shl i32 %.pre583, %.fr567
  %131 = add nsw i64 %.0517.lcssa, -1
  %132 = getelementptr inbounds nuw [4 x i8], ptr %1, i64 %131
  %133 = load i32, ptr %132, align 4
  %134 = lshr i32 %133, %.pre-phi586
  %common.ret.op.i534.prol = select i1 %126, i32 %134, i32 0
  %135 = or i32 %common.ret.op.i534.prol, %130
  %136 = getelementptr inbounds nuw [4 x i8], ptr %4, i64 %.0517.lcssa
  store i32 %135, ptr %136, align 4
  br label %Then15.prol.loopexit

Then15.prol.loopexit:                             ; preds = %Then15.prol, %Then15.preheader
  %.unr640 = phi i32 [ %.pre583, %Then15.preheader ], [ %133, %Then15.prol ]
  %.1515553.unr = phi i64 [ %.0517.lcssa, %Then15.preheader ], [ %131, %Then15.prol ]
  %137 = icmp eq i64 %.0517.lcssa, 1
  br i1 %137, label %Else15, label %Then15

Then15:                                           ; preds = %Then15, %Then15.prol.loopexit
  %138 = phi i32 [ %149, %Then15 ], [ %.unr640, %Then15.prol.loopexit ]
  %.1515553 = phi i64 [ %147, %Then15 ], [ %.1515553.unr, %Then15.prol.loopexit ]
  %139 = shl i32 %138, %.fr567
  %140 = add nsw i64 %.1515553, -1
  %141 = getelementptr inbounds nuw [4 x i8], ptr %1, i64 %140
  %142 = load i32, ptr %141, align 4
  %143 = lshr i32 %142, %.pre-phi586
  %common.ret.op.i534 = select i1 %126, i32 %143, i32 0
  %144 = or i32 %common.ret.op.i534, %139
  %145 = getelementptr inbounds nuw [4 x i8], ptr %4, i64 %.1515553
  store i32 %144, ptr %145, align 4
  %146 = shl i32 %142, %.fr567
  %147 = add nsw i64 %.1515553, -2
  %148 = getelementptr inbounds nuw [4 x i8], ptr %1, i64 %147
  %149 = load i32, ptr %148, align 4
  %150 = lshr i32 %149, %.pre-phi586
  %common.ret.op.i534.1 = select i1 %126, i32 %150, i32 0
  %151 = or i32 %common.ret.op.i534.1, %146
  %152 = getelementptr inbounds nuw [4 x i8], ptr %4, i64 %140
  store i32 %151, ptr %152, align 4
  %.not525.1 = icmp eq i64 %147, 0
  br i1 %.not525.1, label %Else15, label %Then15

Else15:                                           ; preds = %Then15, %Then15.prol.loopexit, %Else14
  %153 = load i32, ptr %1, align 4
  %154 = shl i32 %153, %.fr567
  store i32 %154, ptr %4, align 4
  %155 = sub nuw nsw i64 %.0517.lcssa, %.0516.lcssa.fr
  %invariant.gep561 = getelementptr [4 x i8], ptr %4, i64 %.0516.lcssa.fr
  %156 = getelementptr inbounds nuw [4 x i8], ptr %5, i64 %.0516.lcssa.fr
  %157 = load i32, ptr %156, align 4
  %158 = zext i32 %157 to i64
  %159 = getelementptr i8, ptr %156, i64 -4
  %160 = add i64 %.0516.lcssa.fr, 1
  %xtraiter641 = and i64 %160, 1
  %161 = icmp eq i64 %.0516.lcssa.fr, 0
  %unroll_iter = and i64 %160, -2
  %lcmp.mod642.not = icmp eq i64 %xtraiter641, 0
  %lcmp.mod644 = icmp ne i64 %xtraiter641, 0
  %xtraiter645 = and i64 %160, 1
  %162 = icmp eq i64 %.0516.lcssa.fr, 0
  %unroll_iter649 = and i64 %160, -2
  %lcmp.mod646.not = icmp eq i64 %xtraiter645, 0
  %lcmp.mod648 = icmp ne i64 %xtraiter645, 0
  br label %Loop6

Loop6:                                            ; preds = %Block73, %Else15
  %.0513 = phi i64 [ %155, %Else15 ], [ %238, %Block73 ]
  %gep562 = getelementptr [4 x i8], ptr %invariant.gep561, i64 %.0513
  %163 = getelementptr inbounds nuw i8, ptr %gep562, i64 4
  %164 = load i32, ptr %163, align 4
  %165 = zext i32 %164 to i64
  %166 = shl nuw i64 %165, 32
  %167 = load i32, ptr %gep562, align 4
  %168 = zext i32 %167 to i64
  %169 = or disjoint i64 %166, %168
  %170 = udiv i64 %169, %158
  %171 = urem i64 %169, %158
  %172 = getelementptr i8, ptr %gep562, i64 -4
  br i1 %.not524550, label %Loop7.us, label %Loop7

Loop7.us:                                         ; preds = %Then18.us, %Loop6
  %.0512.us = phi i64 [ %174, %Then18.us ], [ %170, %Loop6 ]
  %.0511.us = phi i64 [ %175, %Then18.us ], [ %171, %Loop6 ]
  %173 = icmp ugt i64 %.0512.us, 4294967295
  br i1 %173, label %Then18.us, label %Block56

Then18.us:                                        ; preds = %Loop7.us
  %174 = add i64 %.0512.us, -1
  %175 = add nuw nsw i64 %.0511.us, %158
  %176 = icmp samesign ult i64 %175, 4294967296
  br i1 %176, label %Loop7.us, label %Block56

Loop7:                                            ; preds = %Then18, %Loop6
  %.0512 = phi i64 [ %186, %Then18 ], [ %170, %Loop6 ]
  %.0511 = phi i64 [ %187, %Then18 ], [ %171, %Loop6 ]
  %177 = icmp ugt i64 %.0512, 4294967295
  br i1 %177, label %Then18, label %Else16

Block56:                                          ; preds = %Then18, %Else16, %Then18.us, %Loop7.us
  %.us-phi = phi i64 [ %174, %Then18.us ], [ %.0512.us, %Loop7.us ], [ %186, %Then18 ], [ %.0512, %Else16 ]
  %invariant.gep = getelementptr [4 x i8], ptr %4, i64 %.0513
  br i1 %161, label %Then20.epil.preheader, label %Then20

Else16:                                           ; preds = %Loop7
  %178 = load i32, ptr %159, align 4
  %179 = zext i32 %178 to i64
  %180 = mul nuw i64 %.0512, %179
  %181 = shl nuw i64 %.0511, 32
  %182 = load i32, ptr %172, align 4
  %183 = zext i32 %182 to i64
  %184 = or disjoint i64 %181, %183
  %185 = icmp ugt i64 %180, %184
  br i1 %185, label %Then18, label %Block56

Then18:                                           ; preds = %Else16, %Loop7
  %186 = add i64 %.0512, -1
  %187 = add nuw nsw i64 %.0511, %158
  %188 = icmp samesign ult i64 %187, 4294967296
  br i1 %188, label %Loop7, label %Block56

Then20:                                           ; preds = %Then20, %Block56
  %.0510556 = phi i64 [ %215, %Then20 ], [ 0, %Block56 ]
  %.2555 = phi i64 [ %216, %Then20 ], [ 0, %Block56 ]
  %niter = phi i64 [ %niter.next.1, %Then20 ], [ 0, %Block56 ]
  %189 = getelementptr inbounds nuw [4 x i8], ptr %5, i64 %.2555
  %190 = load i32, ptr %189, align 4
  %191 = zext i32 %190 to i64
  %192 = mul nuw i64 %.us-phi, %191
  %gep = getelementptr [4 x i8], ptr %invariant.gep, i64 %.2555
  %193 = load i32, ptr %gep, align 4
  %194 = zext i32 %193 to i64
  %195 = and i64 %192, 4294967295
  %196 = add nuw nsw i64 %.0510556, %195
  %197 = sub nsw i64 %194, %196
  %198 = trunc i64 %197 to i32
  store i32 %198, ptr %gep, align 4
  %199 = lshr i64 %192, 32
  %200 = ashr i64 %197, 32
  %201 = sub nsw i64 %199, %200
  %202 = or disjoint i64 %.2555, 1
  %203 = getelementptr inbounds nuw [4 x i8], ptr %5, i64 %202
  %204 = load i32, ptr %203, align 4
  %205 = zext i32 %204 to i64
  %206 = mul nuw i64 %.us-phi, %205
  %gep.1 = getelementptr [4 x i8], ptr %invariant.gep, i64 %202
  %207 = load i32, ptr %gep.1, align 4
  %208 = zext i32 %207 to i64
  %209 = and i64 %206, 4294967295
  %210 = add nuw nsw i64 %201, %209
  %211 = sub nsw i64 %208, %210
  %212 = trunc i64 %211 to i32
  store i32 %212, ptr %gep.1, align 4
  %213 = lshr i64 %206, 32
  %214 = ashr i64 %211, 32
  %215 = sub nsw i64 %213, %214
  %216 = add nuw i64 %.2555, 2
  %niter.next.1 = add i64 %niter, 2
  %niter.ncmp.1 = icmp eq i64 %niter.next.1, %unroll_iter
  br i1 %niter.ncmp.1, label %Else20.unr-lcssa, label %Then20

Else20.unr-lcssa:                                 ; preds = %Then20
  br i1 %lcmp.mod642.not, label %Else20, label %Then20.epil.preheader

Then20.epil.preheader:                            ; preds = %Else20.unr-lcssa, %Block56
  %.0510556.epil.init = phi i64 [ 0, %Block56 ], [ %215, %Else20.unr-lcssa ]
  %.2555.epil.init = phi i64 [ 0, %Block56 ], [ %216, %Else20.unr-lcssa ]
  tail call void @llvm.assume(i1 %lcmp.mod644)
  %217 = getelementptr inbounds nuw [4 x i8], ptr %5, i64 %.2555.epil.init
  %218 = load i32, ptr %217, align 4
  %219 = zext i32 %218 to i64
  %220 = mul nuw i64 %.us-phi, %219
  %gep.epil = getelementptr [4 x i8], ptr %invariant.gep, i64 %.2555.epil.init
  %221 = load i32, ptr %gep.epil, align 4
  %222 = zext i32 %221 to i64
  %223 = and i64 %220, 4294967295
  %224 = add nuw nsw i64 %.0510556.epil.init, %223
  %225 = sub nsw i64 %222, %224
  %226 = trunc i64 %225 to i32
  store i32 %226, ptr %gep.epil, align 4
  %227 = lshr i64 %220, 32
  %228 = ashr i64 %225, 32
  %229 = sub nsw i64 %227, %228
  br label %Else20

Else20:                                           ; preds = %Then20.epil.preheader, %Else20.unr-lcssa
  %.lcssa622 = phi i64 [ %215, %Else20.unr-lcssa ], [ %229, %Then20.epil.preheader ]
  %230 = load i32, ptr %163, align 4
  %231 = zext i32 %230 to i64
  %232 = sub nsw i64 %231, %.lcssa622
  %233 = trunc i64 %232 to i32
  store i32 %233, ptr %163, align 4
  %234 = trunc i64 %.us-phi to i32
  %235 = getelementptr inbounds nuw [4 x i8], ptr %0, i64 %.0513
  store i32 %234, ptr %235, align 4
  %236 = icmp slt i64 %232, 0
  br i1 %236, label %Then23, label %Block73

Block73:                                          ; preds = %Else24, %Else20
  %237 = icmp eq i64 %.0513, 0
  %238 = add nsw i64 %.0513, -1
  br i1 %237, label %TryCont, label %Loop6

Then23:                                           ; preds = %Else20
  %239 = add i32 %234, -1
  store i32 %239, ptr %235, align 4
  br i1 %162, label %Then24.epil.preheader, label %Then24

Then24:                                           ; preds = %Then24, %Then23
  %.0509560 = phi i64 [ %258, %Then24 ], [ 0, %Then23 ]
  %.3559 = phi i64 [ %259, %Then24 ], [ 0, %Then23 ]
  %niter650 = phi i64 [ %niter650.next.1, %Then24 ], [ 0, %Then23 ]
  %gep558 = getelementptr [4 x i8], ptr %invariant.gep, i64 %.3559
  %240 = load i32, ptr %gep558, align 4
  %241 = zext i32 %240 to i64
  %242 = getelementptr inbounds nuw [4 x i8], ptr %5, i64 %.3559
  %243 = load i32, ptr %242, align 4
  %244 = zext i32 %243 to i64
  %245 = add nuw nsw i64 %.0509560, %241
  %246 = add nuw nsw i64 %245, %244
  %247 = trunc i64 %246 to i32
  store i32 %247, ptr %gep558, align 4
  %248 = lshr i64 %246, 32
  %249 = or disjoint i64 %.3559, 1
  %gep558.1 = getelementptr [4 x i8], ptr %invariant.gep, i64 %249
  %250 = load i32, ptr %gep558.1, align 4
  %251 = zext i32 %250 to i64
  %252 = getelementptr inbounds nuw [4 x i8], ptr %5, i64 %249
  %253 = load i32, ptr %252, align 4
  %254 = zext i32 %253 to i64
  %255 = add nuw nsw i64 %248, %251
  %256 = add nuw nsw i64 %255, %254
  %257 = trunc i64 %256 to i32
  store i32 %257, ptr %gep558.1, align 4
  %258 = lshr i64 %256, 32
  %259 = add nuw i64 %.3559, 2
  %niter650.next.1 = add i64 %niter650, 2
  %niter650.ncmp.1 = icmp eq i64 %niter650.next.1, %unroll_iter649
  br i1 %niter650.ncmp.1, label %Else24.unr-lcssa, label %Then24

Else24.unr-lcssa:                                 ; preds = %Then24
  br i1 %lcmp.mod646.not, label %Else24, label %Then24.epil.preheader

Then24.epil.preheader:                            ; preds = %Else24.unr-lcssa, %Then23
  %.0509560.epil.init = phi i64 [ 0, %Then23 ], [ %258, %Else24.unr-lcssa ]
  %.3559.epil.init = phi i64 [ 0, %Then23 ], [ %259, %Else24.unr-lcssa ]
  tail call void @llvm.assume(i1 %lcmp.mod648)
  %gep558.epil = getelementptr [4 x i8], ptr %invariant.gep, i64 %.3559.epil.init
  %260 = load i32, ptr %gep558.epil, align 4
  %261 = zext i32 %260 to i64
  %262 = getelementptr inbounds nuw [4 x i8], ptr %5, i64 %.3559.epil.init
  %263 = load i32, ptr %262, align 4
  %264 = zext i32 %263 to i64
  %265 = add nuw nsw i64 %.0509560.epil.init, %261
  %266 = add nuw nsw i64 %265, %264
  %267 = trunc i64 %266 to i32
  store i32 %267, ptr %gep558.epil, align 4
  %268 = lshr i64 %266, 32
  br label %Else24

Else24:                                           ; preds = %Then24.epil.preheader, %Else24.unr-lcssa
  %.lcssa623 = phi i64 [ %258, %Else24.unr-lcssa ], [ %268, %Then24.epil.preheader ]
  %269 = load i32, ptr %163, align 4
  %270 = trunc nuw nsw i64 %.lcssa623 to i32
  %271 = add i32 %269, %270
  store i32 %271, ptr %163, align 4
  br label %Block73

TryCont:                                          ; preds = %Block73, %Else11, %Then9
  %272 = xor i32 %15, %13
  %273 = icmp slt i32 %272, 0
  br i1 %273, label %Then28.preheader, label %Block1

Then28.preheader:                                 ; preds = %TryCont
  store i1 true, ptr %.sroa.0504, align 1
  br label %Then28

Then28:                                           ; preds = %Then28, %Then28.preheader
  %.0563 = phi i64 [ %283, %Then28 ], [ 0, %Then28.preheader ]
  %274 = getelementptr inbounds nuw [4 x i8], ptr %0, i64 %.0563
  %275 = load i32, ptr %274, align 4
  %276 = xor i32 %275, -1
  %.sroa.0504.0..sroa.0504.0..sroa.0504.0..sroa.0504.0..sroa.0504.0. = load i8, ptr %.sroa.0504, align 1
  %277 = and i8 %.sroa.0504.0..sroa.0504.0..sroa.0504.0..sroa.0504.0..sroa.0504.0., 1
  %278 = zext nneg i8 %277 to i32
  %279 = tail call { i32, i1 } @llvm.uadd.with.overflow.i32(i32 %276, i32 %278)
  %280 = extractvalue { i32, i1 } %279, 0
  %281 = extractvalue { i32, i1 } %279, 1
  store i1 %281, ptr %.sroa.2508, align 4
  %.sroa.2508.0..sroa.2508.0..sroa.2508.0..sroa.2508.0..sroa.2508.4. = load i8, ptr %.sroa.2508, align 4
  %282 = trunc i8 %.sroa.2508.0..sroa.2508.0..sroa.2508.0..sroa.2508.0..sroa.2508.4. to i1
  store i1 %282, ptr %.sroa.0504, align 1
  store i32 %280, ptr %274, align 4
  %283 = add nuw nsw i64 %.0563, 1
  %exitcond581.not = icmp eq i64 %283, %10
  br i1 %exitcond581.not, label %Block1, label %Then28
}

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(inaccessiblemem: write)
declare void @llvm.assume(i1 noundef) #1

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(inaccessiblemem: write) uwtable
declare hidden fastcc range(i16 0, 8208) i16 @zig.target.intByteSize(i16) unnamed_addr #2 align 1

; Function Attrs: nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none)
declare { i32, i1 } @llvm.uadd.with.overflow.i32(i32, i32) #3

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.ctlz.i32(i32, i1 immarg) #4

; Function Attrs: nofree norecurse nosync nounwind memory(read, argmem: readwrite, inaccessiblemem: write, target_mem0: none, target_mem1: none) uwtable
define hidden void @compiler_rt.divmodei4.__divei5(ptr nonnull align 1 captures(address) %0, ptr nonnull readonly align 1 captures(none) %1, ptr nonnull readonly align 1 captures(none) %2, ptr nonnull align 1 captures(none) %3, i64 %4) unnamed_addr #5 align 1 {
Entry:
  %.sroa.2502 = alloca i8, align 4
  %.sroa.0498 = alloca i8, align 1
  %5 = alloca [2049 x i32], align 4
  %6 = alloca [2048 x i32], align 4
  %.sroa.294 = alloca i8, align 4
  %.sroa.090 = alloca i8, align 1
  %.sroa.276 = alloca i8, align 4
  %.sroa.073 = alloca i8, align 1
  %7 = icmp ult i64 %4, 65536
  tail call void @llvm.assume(i1 %7)
  %8 = trunc nuw i64 %4 to i16
  %9 = tail call fastcc i16 @zig.target.intByteSize(i16 %8) #6
  %10 = zext nneg i16 %9 to i64
  %11 = lshr exact i64 %10, 2
  %12 = getelementptr inbounds nuw [1 x i8], ptr %3, i64 %10
  %13 = add nsw i64 %11, -1
  %14 = getelementptr inbounds nuw [4 x i8], ptr %1, i64 %13
  %15 = load i32, ptr %14, align 4
  %16 = getelementptr inbounds nuw [4 x i8], ptr %2, i64 %13
  %17 = load i32, ptr %16, align 4
  %18 = icmp slt i32 %15, 0
  br i1 %18, label %Then, label %Block4

Block1:                                           ; preds = %Then28, %TryCont
  ret void

Block4:                                           ; preds = %Then1, %Entry
  %19 = icmp slt i32 %17, 0
  %.not566 = icmp eq i16 %9, 0
  br i1 %19, label %Then2, label %Block10

Block4.thread:                                    ; preds = %Then
  %20 = icmp slt i32 %17, 0
  br i1 %20, label %Block10.thread, label %Block19

Then:                                             ; preds = %Entry
  store i1 true, ptr %.sroa.073, align 1
  %.not565 = icmp eq i16 %9, 0
  br i1 %.not565, label %Block4.thread, label %Then1

Then1:                                            ; preds = %Then1, %Then
  %.0513544 = phi i64 [ %31, %Then1 ], [ 0, %Then ]
  %21 = getelementptr inbounds nuw [4 x i8], ptr %1, i64 %.0513544
  %22 = load i32, ptr %21, align 4
  %23 = xor i32 %22, -1
  %.sroa.073.0..sroa.073.0..sroa.073.0..sroa.073.0..sroa.073.0. = load i8, ptr %.sroa.073, align 1
  %24 = and i8 %.sroa.073.0..sroa.073.0..sroa.073.0..sroa.073.0..sroa.073.0., 1
  %25 = zext nneg i8 %24 to i32
  %26 = tail call { i32, i1 } @llvm.uadd.with.overflow.i32(i32 %23, i32 %25)
  %27 = extractvalue { i32, i1 } %26, 0
  %28 = extractvalue { i32, i1 } %26, 1
  store i1 %28, ptr %.sroa.276, align 4
  %.sroa.276.0..sroa.276.0..sroa.276.0..sroa.276.0..sroa.276.4. = load i8, ptr %.sroa.276, align 4
  %29 = trunc i8 %.sroa.276.0..sroa.276.0..sroa.276.0..sroa.276.0..sroa.276.4. to i1
  store i1 %29, ptr %.sroa.073, align 1
  %30 = getelementptr inbounds nuw [4 x i8], ptr %3, i64 %.0513544
  store i32 %27, ptr %30, align 4
  %31 = add nuw nsw i64 %.0513544, 1
  %exitcond.not = icmp eq i64 %31, %11
  br i1 %exitcond.not, label %Block4, label %Then1

Block10:                                          ; preds = %Block4
  %spec.select = select i1 %18, ptr %3, ptr %1
  br i1 %.not566, label %Block19, label %InlineMemsetBody.preheader

InlineMemsetBody.preheader:                       ; preds = %Block10.thread601, %Block10
  %spec.select606 = phi ptr [ %spec.select603, %Block10.thread601 ], [ %spec.select, %Block10 ]
  %.pn524605 = phi ptr [ %12, %Block10.thread601 ], [ %2, %Block10 ]
  %32 = getelementptr inbounds nuw i8, ptr %0, i64 %10
  %33 = add nsw i64 %10, -4
  %34 = lshr i64 %33, 2
  %35 = add nuw nsw i64 %34, 1
  %xtraiter = and i64 %35, 7
  %36 = and i64 %33, 28
  %lcmp.mod.not = icmp eq i64 %36, 28
  br i1 %lcmp.mod.not, label %InlineMemsetBody.prol.loopexit, label %InlineMemsetBody.prol

InlineMemsetBody.prol:                            ; preds = %InlineMemsetBody.prol, %InlineMemsetBody.preheader
  %37 = phi ptr [ %38, %InlineMemsetBody.prol ], [ %0, %InlineMemsetBody.preheader ]
  %prol.iter = phi i64 [ %prol.iter.next, %InlineMemsetBody.prol ], [ 0, %InlineMemsetBody.preheader ]
  store i32 0, ptr %37, align 4
  %38 = getelementptr inbounds nuw i8, ptr %37, i64 4
  %prol.iter.next = add i64 %prol.iter, 1
  %prol.iter.cmp.not = icmp eq i64 %prol.iter.next, %xtraiter
  br i1 %prol.iter.cmp.not, label %InlineMemsetBody.prol.loopexit, label %InlineMemsetBody.prol, !llvm.loop !5

InlineMemsetBody.prol.loopexit:                   ; preds = %InlineMemsetBody.prol, %InlineMemsetBody.preheader
  %.unr = phi ptr [ %0, %InlineMemsetBody.preheader ], [ %38, %InlineMemsetBody.prol ]
  %39 = icmp ult i64 %33, 28
  br i1 %39, label %Block19, label %InlineMemsetBody

Then2:                                            ; preds = %Block4
  store i1 true, ptr %.sroa.090, align 1
  br i1 %.not566, label %Block10.thread, label %Then3

Block10.thread:                                   ; preds = %Then2, %Block4.thread
  %spec.select597 = select i1 %18, ptr %3, ptr %1
  br label %Block19

Then3:                                            ; preds = %Then3, %Then2
  %.0512545 = phi i64 [ %50, %Then3 ], [ 0, %Then2 ]
  %40 = getelementptr inbounds nuw [4 x i8], ptr %2, i64 %.0512545
  %41 = load i32, ptr %40, align 4
  %42 = xor i32 %41, -1
  %.sroa.090.0..sroa.090.0..sroa.090.0..sroa.090.0..sroa.090.0. = load i8, ptr %.sroa.090, align 1
  %43 = and i8 %.sroa.090.0..sroa.090.0..sroa.090.0..sroa.090.0..sroa.090.0., 1
  %44 = zext nneg i8 %43 to i32
  %45 = tail call { i32, i1 } @llvm.uadd.with.overflow.i32(i32 %42, i32 %44)
  %46 = extractvalue { i32, i1 } %45, 0
  %47 = extractvalue { i32, i1 } %45, 1
  store i1 %47, ptr %.sroa.294, align 4
  %.sroa.294.0..sroa.294.0..sroa.294.0..sroa.294.0..sroa.294.4. = load i8, ptr %.sroa.294, align 4
  %48 = trunc i8 %.sroa.294.0..sroa.294.0..sroa.294.0..sroa.294.0..sroa.294.4. to i1
  store i1 %48, ptr %.sroa.090, align 1
  %49 = getelementptr inbounds nuw [4 x i8], ptr %12, i64 %.0512545
  store i32 %46, ptr %49, align 4
  %50 = add nuw nsw i64 %.0512545, 1
  %exitcond582.not = icmp eq i64 %50, %11
  br i1 %exitcond582.not, label %Block10.thread601, label %Then3

Block10.thread601:                                ; preds = %Then3
  %spec.select603 = select i1 %18, ptr %3, ptr %1
  br label %InlineMemsetBody.preheader

Block19:                                          ; preds = %InlineMemsetBody, %Block10.thread, %InlineMemsetBody.prol.loopexit, %Block10, %Block4.thread
  %spec.select600 = phi ptr [ %spec.select597, %Block10.thread ], [ %3, %Block4.thread ], [ %spec.select, %Block10 ], [ %spec.select606, %InlineMemsetBody ], [ %spec.select606, %InlineMemsetBody.prol.loopexit ]
  %.pn524599 = phi ptr [ %12, %Block10.thread ], [ %2, %Block4.thread ], [ %2, %Block10 ], [ %.pn524605, %InlineMemsetBody ], [ %.pn524605, %InlineMemsetBody.prol.loopexit ]
  %51 = icmp ne i16 %9, 0
  tail call void @llvm.assume(i1 %51)
  br label %Loop2

InlineMemsetBody:                                 ; preds = %InlineMemsetBody, %InlineMemsetBody.prol.loopexit
  %52 = phi ptr [ %60, %InlineMemsetBody ], [ %.unr, %InlineMemsetBody.prol.loopexit ]
  store i32 0, ptr %52, align 4
  %53 = getelementptr inbounds nuw i8, ptr %52, i64 4
  store i32 0, ptr %53, align 4
  %54 = getelementptr inbounds nuw i8, ptr %52, i64 8
  store i32 0, ptr %54, align 4
  %55 = getelementptr inbounds nuw i8, ptr %52, i64 12
  store i32 0, ptr %55, align 4
  %56 = getelementptr inbounds nuw i8, ptr %52, i64 16
  store i32 0, ptr %56, align 4
  %57 = getelementptr inbounds nuw i8, ptr %52, i64 20
  store i32 0, ptr %57, align 4
  %58 = getelementptr inbounds nuw i8, ptr %52, i64 24
  store i32 0, ptr %58, align 4
  %59 = getelementptr inbounds nuw i8, ptr %52, i64 28
  store i32 0, ptr %59, align 4
  %60 = getelementptr inbounds nuw i8, ptr %52, i64 32
  %.not.7 = icmp eq ptr %60, %32
  br i1 %.not.7, label %Block19, label %InlineMemsetBody

Loop2:                                            ; preds = %Then9, %Block19
  %indvar = phi i64 [ 0, %Block19 ], [ %indvar.next, %Then9 ]
  %.0511.in = phi i64 [ %11, %Block19 ], [ %.0511, %Then9 ]
  %.0511 = add i64 %.0511.in, -1
  %61 = getelementptr inbounds [4 x i8], ptr %spec.select600, i64 %.0511
  %62 = load i32, ptr %61, align 4
  %63 = icmp eq i32 %62, 0
  br i1 %63, label %Then9, label %Loop3.preheader

Loop3.preheader:                                  ; preds = %Loop2
  %64 = getelementptr inbounds [4 x i8], ptr %.pn524599, i64 %13
  %65 = load i32, ptr %64, align 4
  %66 = icmp eq i32 %65, 0
  br i1 %66, label %Then11, label %Else11

Then9:                                            ; preds = %Loop2
  %67 = icmp eq i64 %.0511, 0
  %indvar.next = add i64 %indvar, 1
  br i1 %67, label %TryCont, label %Loop2

Then11:                                           ; preds = %Then11, %Loop3.preheader
  %.0510548 = phi i64 [ %.0510, %Then11 ], [ %13, %Loop3.preheader ]
  %68 = icmp ne i64 %.0510548, 0
  tail call void @llvm.assume(i1 %68)
  %.0510 = add i64 %.0510548, -1
  %69 = getelementptr inbounds [4 x i8], ptr %.pn524599, i64 %.0510
  %70 = load i32, ptr %69, align 4
  %71 = icmp eq i32 %70, 0
  br i1 %71, label %Then11, label %Else11

Else11:                                           ; preds = %Then11, %Loop3.preheader
  %.0510.in.lcssa = phi i64 [ %11, %Loop3.preheader ], [ %.0510548, %Then11 ]
  %.0510.lcssa = phi i64 [ %13, %Loop3.preheader ], [ %.0510, %Then11 ]
  %.lcssa = phi i32 [ %65, %Loop3.preheader ], [ %70, %Then11 ]
  %.0510.lcssa.fr = freeze i64 %.0510.lcssa
  %72 = icmp ugt i64 %.0510.lcssa.fr, %.0511
  br i1 %72, label %TryCont, label %Else13

Else13:                                           ; preds = %Else11
  %73 = tail call range(i32 0, 33) i32 @llvm.ctlz.i32(i32 %.lcssa, i1 true)
  %.fr568 = freeze i32 %73
  %74 = trunc i32 %.fr568 to i6
  %.not525551 = icmp eq i64 %.0510.lcssa.fr, 0
  %.pre587 = sub i6 -32, %74
  br i1 %.not525551, label %Else13.Else14_crit_edge, label %Then14.lr.ph

Else13.Else14_crit_edge:                          ; preds = %Else13
  %.pre588 = zext nneg i6 %.pre587 to i32
  br label %Else14

Then14.lr.ph:                                     ; preds = %Else13
  %75 = icmp sgt i6 %.pre587, -1
  %76 = zext nneg i6 %.pre587 to i32
  br i1 %75, label %Then14.us.preheader, label %Then14.preheader

Then14.preheader:                                 ; preds = %Then14.lr.ph
  %xtraiter648 = and i64 %.0510.lcssa.fr, 3
  %lcmp.mod649.not = icmp eq i64 %xtraiter648, 0
  br i1 %lcmp.mod649.not, label %Then14.prol.loopexit, label %Then14.prol

Then14.prol:                                      ; preds = %Then14.prol, %Then14.preheader
  %.0508552.prol = phi i64 [ %80, %Then14.prol ], [ %.0510.lcssa.fr, %Then14.preheader ]
  %prol.iter650 = phi i64 [ %prol.iter650.next, %Then14.prol ], [ 0, %Then14.preheader ]
  %77 = getelementptr inbounds [4 x i8], ptr %.pn524599, i64 %.0508552.prol
  %78 = load i32, ptr %77, align 4
  %79 = shl i32 %78, %.fr568
  %80 = add i64 %.0508552.prol, -1
  %81 = getelementptr inbounds [4 x i8], ptr %6, i64 %.0508552.prol
  store i32 %79, ptr %81, align 4
  %prol.iter650.next = add i64 %prol.iter650, 1
  %prol.iter650.cmp.not = icmp eq i64 %prol.iter650.next, %xtraiter648
  br i1 %prol.iter650.cmp.not, label %Then14.prol.loopexit, label %Then14.prol, !llvm.loop !6

Then14.prol.loopexit:                             ; preds = %Then14.prol, %Then14.preheader
  %.0508552.unr = phi i64 [ %.0510.lcssa.fr, %Then14.preheader ], [ %80, %Then14.prol ]
  %82 = icmp ult i64 %.0510.lcssa.fr, 4
  br i1 %82, label %Else14, label %Then14

Then14.us.preheader:                              ; preds = %Then14.lr.ph
  %.phi.trans.insert = getelementptr inbounds [4 x i8], ptr %.pn524599, i64 %.0510.lcssa.fr
  %.pre = load i32, ptr %.phi.trans.insert, align 4
  %xtraiter651 = and i64 %.0510.lcssa.fr, 1
  %lcmp.mod652.not = icmp eq i64 %xtraiter651, 0
  br i1 %lcmp.mod652.not, label %Then14.us.prol.loopexit, label %Then14.us.prol

Then14.us.prol:                                   ; preds = %Then14.us.preheader
  %83 = shl i32 %.pre, %.fr568
  %84 = add nsw i64 %.0510.lcssa.fr, -1
  %85 = getelementptr inbounds [4 x i8], ptr %.pn524599, i64 %84
  %86 = load i32, ptr %85, align 4
  %87 = lshr i32 %86, %76
  %88 = or i32 %87, %83
  %89 = getelementptr inbounds [4 x i8], ptr %6, i64 %.0510.lcssa.fr
  store i32 %88, ptr %89, align 4
  br label %Then14.us.prol.loopexit

Then14.us.prol.loopexit:                          ; preds = %Then14.us.prol, %Then14.us.preheader
  %.unr654 = phi i32 [ %.pre, %Then14.us.preheader ], [ %86, %Then14.us.prol ]
  %.0508552.us.unr = phi i64 [ %.0510.lcssa.fr, %Then14.us.preheader ], [ %84, %Then14.us.prol ]
  %90 = icmp eq i64 %.0510.lcssa.fr, 1
  br i1 %90, label %Else14, label %Then14.us

Then14.us:                                        ; preds = %Then14.us, %Then14.us.prol.loopexit
  %91 = phi i32 [ %102, %Then14.us ], [ %.unr654, %Then14.us.prol.loopexit ]
  %.0508552.us = phi i64 [ %100, %Then14.us ], [ %.0508552.us.unr, %Then14.us.prol.loopexit ]
  %92 = shl i32 %91, %.fr568
  %93 = add i64 %.0508552.us, -1
  %94 = getelementptr inbounds [4 x i8], ptr %.pn524599, i64 %93
  %95 = load i32, ptr %94, align 4
  %96 = lshr i32 %95, %76
  %97 = or i32 %96, %92
  %98 = getelementptr inbounds [4 x i8], ptr %6, i64 %.0508552.us
  store i32 %97, ptr %98, align 4
  %99 = shl i32 %95, %.fr568
  %100 = add i64 %.0508552.us, -2
  %101 = getelementptr inbounds [4 x i8], ptr %.pn524599, i64 %100
  %102 = load i32, ptr %101, align 4
  %103 = lshr i32 %102, %76
  %104 = or i32 %103, %99
  %105 = getelementptr inbounds [4 x i8], ptr %6, i64 %93
  store i32 %104, ptr %105, align 4
  %.not525.us.1 = icmp eq i64 %100, 0
  br i1 %.not525.us.1, label %Else14, label %Then14.us

Then14:                                           ; preds = %Then14, %Then14.prol.loopexit
  %.0508552 = phi i64 [ %124, %Then14 ], [ %.0508552.unr, %Then14.prol.loopexit ]
  %106 = getelementptr inbounds [4 x i8], ptr %.pn524599, i64 %.0508552
  %107 = load i32, ptr %106, align 4
  %108 = shl i32 %107, %.fr568
  %109 = add i64 %.0508552, -1
  %110 = getelementptr inbounds [4 x i8], ptr %6, i64 %.0508552
  store i32 %108, ptr %110, align 4
  %111 = getelementptr inbounds [4 x i8], ptr %.pn524599, i64 %109
  %112 = load i32, ptr %111, align 4
  %113 = shl i32 %112, %.fr568
  %114 = add i64 %.0508552, -2
  %115 = getelementptr inbounds [4 x i8], ptr %6, i64 %109
  store i32 %113, ptr %115, align 4
  %116 = getelementptr inbounds [4 x i8], ptr %.pn524599, i64 %114
  %117 = load i32, ptr %116, align 4
  %118 = shl i32 %117, %.fr568
  %119 = add i64 %.0508552, -3
  %120 = getelementptr inbounds [4 x i8], ptr %6, i64 %114
  store i32 %118, ptr %120, align 4
  %121 = getelementptr inbounds [4 x i8], ptr %.pn524599, i64 %119
  %122 = load i32, ptr %121, align 4
  %123 = shl i32 %122, %.fr568
  %124 = add i64 %.0508552, -4
  %125 = getelementptr inbounds [4 x i8], ptr %6, i64 %119
  store i32 %123, ptr %125, align 4
  %.not525.3 = icmp eq i64 %124, 0
  br i1 %.not525.3, label %Else14, label %Then14

Else14:                                           ; preds = %Then14, %Then14.us, %Then14.us.prol.loopexit, %Then14.prol.loopexit, %Else13.Else14_crit_edge
  %.pre-phi589 = phi i32 [ %.pre588, %Else13.Else14_crit_edge ], [ %76, %Then14.us.prol.loopexit ], [ %76, %Then14.us ], [ %76, %Then14 ], [ %76, %Then14.prol.loopexit ]
  %126 = load i32, ptr %.pn524599, align 4
  %127 = shl i32 %126, %.fr568
  store i32 %127, ptr %6, align 4
  %128 = icmp sgt i6 %.pre587, -1
  %129 = lshr i32 %62, %.pre-phi589
  %common.ret.op.i533 = select i1 %128, i32 %129, i32 0
  %130 = getelementptr [4 x i8], ptr %5, i64 %.0511
  %131 = getelementptr i8, ptr %130, i64 4
  store i32 %common.ret.op.i533, ptr %131, align 4
  %.not526553 = icmp eq i64 %.0511, 0
  br i1 %.not526553, label %Else15, label %Then15.preheader

Then15.preheader:                                 ; preds = %Else14
  %132 = add nsw i64 %11, -2
  %xtraiter656 = and i64 %.0511, 1
  %lcmp.mod657.not = icmp eq i64 %xtraiter656, 0
  br i1 %lcmp.mod657.not, label %Then15.prol.loopexit, label %Then15.prol

Then15.prol:                                      ; preds = %Then15.preheader
  %133 = shl i32 %62, %.fr568
  %134 = add i64 %.0511.in, -2
  %135 = getelementptr inbounds [4 x i8], ptr %spec.select600, i64 %134
  %136 = load i32, ptr %135, align 4
  %137 = lshr i32 %136, %.pre-phi589
  %common.ret.op.i535.prol = select i1 %128, i32 %137, i32 0
  %138 = or i32 %common.ret.op.i535.prol, %133
  %139 = getelementptr inbounds [4 x i8], ptr %5, i64 %.0511
  store i32 %138, ptr %139, align 4
  br label %Then15.prol.loopexit

Then15.prol.loopexit:                             ; preds = %Then15.prol, %Then15.preheader
  %.unr659 = phi i32 [ %62, %Then15.preheader ], [ %136, %Then15.prol ]
  %.1509554.unr = phi i64 [ %.0511, %Then15.preheader ], [ %134, %Then15.prol ]
  %140 = icmp eq i64 %132, %indvar
  br i1 %140, label %Else15, label %Then15

Then15:                                           ; preds = %Then15, %Then15.prol.loopexit
  %141 = phi i32 [ %152, %Then15 ], [ %.unr659, %Then15.prol.loopexit ]
  %.1509554 = phi i64 [ %150, %Then15 ], [ %.1509554.unr, %Then15.prol.loopexit ]
  %142 = shl i32 %141, %.fr568
  %143 = add i64 %.1509554, -1
  %144 = getelementptr inbounds [4 x i8], ptr %spec.select600, i64 %143
  %145 = load i32, ptr %144, align 4
  %146 = lshr i32 %145, %.pre-phi589
  %common.ret.op.i535 = select i1 %128, i32 %146, i32 0
  %147 = or i32 %common.ret.op.i535, %142
  %148 = getelementptr inbounds [4 x i8], ptr %5, i64 %.1509554
  store i32 %147, ptr %148, align 4
  %149 = shl i32 %145, %.fr568
  %150 = add i64 %.1509554, -2
  %151 = getelementptr inbounds [4 x i8], ptr %spec.select600, i64 %150
  %152 = load i32, ptr %151, align 4
  %153 = lshr i32 %152, %.pre-phi589
  %common.ret.op.i535.1 = select i1 %128, i32 %153, i32 0
  %154 = or i32 %common.ret.op.i535.1, %149
  %155 = getelementptr inbounds [4 x i8], ptr %5, i64 %143
  store i32 %154, ptr %155, align 4
  %.not526.1 = icmp eq i64 %150, 0
  br i1 %.not526.1, label %Else15, label %Then15

Else15:                                           ; preds = %Then15, %Then15.prol.loopexit, %Else14
  %156 = load i32, ptr %spec.select600, align 4
  %157 = shl i32 %156, %.fr568
  store i32 %157, ptr %5, align 4
  %158 = sub i64 %.0511.in, %.0510.in.lcssa
  %invariant.gep562 = getelementptr [4 x i8], ptr %5, i64 %.0510.lcssa.fr
  %159 = getelementptr inbounds [4 x i8], ptr %6, i64 %.0510.lcssa.fr
  %160 = load i32, ptr %159, align 4
  %161 = zext i32 %160 to i64
  %162 = getelementptr i8, ptr %159, i64 -4
  %163 = add i64 %.0510.lcssa.fr, 1
  %xtraiter660 = and i64 %163, 1
  %164 = icmp eq i64 %.0510.lcssa.fr, 0
  %unroll_iter = and i64 %163, -2
  %lcmp.mod661.not = icmp eq i64 %xtraiter660, 0
  %lcmp.mod663 = icmp ne i64 %xtraiter660, 0
  %xtraiter664 = and i64 %163, 1
  %165 = icmp eq i64 %.0510.lcssa.fr, 0
  %unroll_iter668 = and i64 %163, -2
  %lcmp.mod665.not = icmp eq i64 %xtraiter664, 0
  %lcmp.mod667 = icmp ne i64 %xtraiter664, 0
  br label %Loop6

Loop6:                                            ; preds = %Block73, %Else15
  %.0507 = phi i64 [ %158, %Else15 ], [ %241, %Block73 ]
  %gep563 = getelementptr [4 x i8], ptr %invariant.gep562, i64 %.0507
  %166 = getelementptr i8, ptr %gep563, i64 4
  %167 = load i32, ptr %166, align 4
  %168 = zext i32 %167 to i64
  %169 = shl nuw i64 %168, 32
  %170 = load i32, ptr %gep563, align 4
  %171 = zext i32 %170 to i64
  %172 = or disjoint i64 %169, %171
  %173 = udiv i64 %172, %161
  %174 = urem i64 %172, %161
  %175 = getelementptr i8, ptr %gep563, i64 -4
  br i1 %.not525551, label %Loop7.us, label %Loop7

Loop7.us:                                         ; preds = %Then18.us, %Loop6
  %.0506.us = phi i64 [ %177, %Then18.us ], [ %173, %Loop6 ]
  %.0505.us = phi i64 [ %178, %Then18.us ], [ %174, %Loop6 ]
  %176 = icmp ugt i64 %.0506.us, 4294967295
  br i1 %176, label %Then18.us, label %Block56

Then18.us:                                        ; preds = %Loop7.us
  %177 = add i64 %.0506.us, -1
  %178 = add nuw nsw i64 %.0505.us, %161
  %179 = icmp samesign ult i64 %178, 4294967296
  br i1 %179, label %Loop7.us, label %Block56

Loop7:                                            ; preds = %Then18, %Loop6
  %.0506 = phi i64 [ %189, %Then18 ], [ %173, %Loop6 ]
  %.0505 = phi i64 [ %190, %Then18 ], [ %174, %Loop6 ]
  %180 = icmp ugt i64 %.0506, 4294967295
  br i1 %180, label %Then18, label %Else16

Block56:                                          ; preds = %Then18, %Else16, %Then18.us, %Loop7.us
  %.us-phi = phi i64 [ %177, %Then18.us ], [ %.0506.us, %Loop7.us ], [ %189, %Then18 ], [ %.0506, %Else16 ]
  %invariant.gep = getelementptr [4 x i8], ptr %5, i64 %.0507
  br i1 %164, label %Then20.epil.preheader, label %Then20

Else16:                                           ; preds = %Loop7
  %181 = load i32, ptr %162, align 4
  %182 = zext i32 %181 to i64
  %183 = mul nuw i64 %.0506, %182
  %184 = shl nuw i64 %.0505, 32
  %185 = load i32, ptr %175, align 4
  %186 = zext i32 %185 to i64
  %187 = or disjoint i64 %184, %186
  %188 = icmp ugt i64 %183, %187
  br i1 %188, label %Then18, label %Block56

Then18:                                           ; preds = %Else16, %Loop7
  %189 = add i64 %.0506, -1
  %190 = add nuw nsw i64 %.0505, %161
  %191 = icmp samesign ult i64 %190, 4294967296
  br i1 %191, label %Loop7, label %Block56

Then20:                                           ; preds = %Then20, %Block56
  %.0504557 = phi i64 [ %218, %Then20 ], [ 0, %Block56 ]
  %.2556 = phi i64 [ %219, %Then20 ], [ 0, %Block56 ]
  %niter = phi i64 [ %niter.next.1, %Then20 ], [ 0, %Block56 ]
  %192 = getelementptr inbounds [4 x i8], ptr %6, i64 %.2556
  %193 = load i32, ptr %192, align 4
  %194 = zext i32 %193 to i64
  %195 = mul nuw i64 %.us-phi, %194
  %gep = getelementptr [4 x i8], ptr %invariant.gep, i64 %.2556
  %196 = load i32, ptr %gep, align 4
  %197 = zext i32 %196 to i64
  %198 = and i64 %195, 4294967295
  %199 = add nuw nsw i64 %.0504557, %198
  %200 = sub nsw i64 %197, %199
  %201 = trunc i64 %200 to i32
  store i32 %201, ptr %gep, align 4
  %202 = lshr i64 %195, 32
  %203 = ashr i64 %200, 32
  %204 = sub nsw i64 %202, %203
  %205 = or disjoint i64 %.2556, 1
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
  %219 = add i64 %.2556, 2
  %niter.next.1 = add i64 %niter, 2
  %niter.ncmp.1 = icmp eq i64 %niter.next.1, %unroll_iter
  br i1 %niter.ncmp.1, label %Else20.unr-lcssa, label %Then20

Else20.unr-lcssa:                                 ; preds = %Then20
  br i1 %lcmp.mod661.not, label %Else20, label %Then20.epil.preheader

Then20.epil.preheader:                            ; preds = %Else20.unr-lcssa, %Block56
  %.0504557.epil.init = phi i64 [ 0, %Block56 ], [ %218, %Else20.unr-lcssa ]
  %.2556.epil.init = phi i64 [ 0, %Block56 ], [ %219, %Else20.unr-lcssa ]
  tail call void @llvm.assume(i1 %lcmp.mod663)
  %220 = getelementptr inbounds [4 x i8], ptr %6, i64 %.2556.epil.init
  %221 = load i32, ptr %220, align 4
  %222 = zext i32 %221 to i64
  %223 = mul nuw i64 %.us-phi, %222
  %gep.epil = getelementptr [4 x i8], ptr %invariant.gep, i64 %.2556.epil.init
  %224 = load i32, ptr %gep.epil, align 4
  %225 = zext i32 %224 to i64
  %226 = and i64 %223, 4294967295
  %227 = add nuw nsw i64 %.0504557.epil.init, %226
  %228 = sub nsw i64 %225, %227
  %229 = trunc i64 %228 to i32
  store i32 %229, ptr %gep.epil, align 4
  %230 = lshr i64 %223, 32
  %231 = ashr i64 %228, 32
  %232 = sub nsw i64 %230, %231
  br label %Else20

Else20:                                           ; preds = %Then20.epil.preheader, %Else20.unr-lcssa
  %.lcssa638 = phi i64 [ %218, %Else20.unr-lcssa ], [ %232, %Then20.epil.preheader ]
  %233 = load i32, ptr %166, align 4
  %234 = zext i32 %233 to i64
  %235 = sub nsw i64 %234, %.lcssa638
  %236 = trunc i64 %235 to i32
  store i32 %236, ptr %166, align 4
  %237 = trunc i64 %.us-phi to i32
  %238 = getelementptr inbounds [4 x i8], ptr %0, i64 %.0507
  store i32 %237, ptr %238, align 4
  %239 = icmp slt i64 %235, 0
  br i1 %239, label %Then23, label %Block73

Block73:                                          ; preds = %Else24, %Else20
  %240 = icmp eq i64 %.0507, 0
  %241 = add i64 %.0507, -1
  br i1 %240, label %TryCont, label %Loop6

Then23:                                           ; preds = %Else20
  %242 = add i32 %237, -1
  store i32 %242, ptr %238, align 4
  br i1 %165, label %Then24.epil.preheader, label %Then24

Then24:                                           ; preds = %Then24, %Then23
  %.0503561 = phi i64 [ %261, %Then24 ], [ 0, %Then23 ]
  %.3560 = phi i64 [ %262, %Then24 ], [ 0, %Then23 ]
  %niter669 = phi i64 [ %niter669.next.1, %Then24 ], [ 0, %Then23 ]
  %gep559 = getelementptr [4 x i8], ptr %invariant.gep, i64 %.3560
  %243 = load i32, ptr %gep559, align 4
  %244 = zext i32 %243 to i64
  %245 = getelementptr inbounds [4 x i8], ptr %6, i64 %.3560
  %246 = load i32, ptr %245, align 4
  %247 = zext i32 %246 to i64
  %248 = add nuw nsw i64 %.0503561, %244
  %249 = add nuw nsw i64 %248, %247
  %250 = trunc i64 %249 to i32
  store i32 %250, ptr %gep559, align 4
  %251 = lshr i64 %249, 32
  %252 = or disjoint i64 %.3560, 1
  %gep559.1 = getelementptr [4 x i8], ptr %invariant.gep, i64 %252
  %253 = load i32, ptr %gep559.1, align 4
  %254 = zext i32 %253 to i64
  %255 = getelementptr inbounds [4 x i8], ptr %6, i64 %252
  %256 = load i32, ptr %255, align 4
  %257 = zext i32 %256 to i64
  %258 = add nuw nsw i64 %251, %254
  %259 = add nuw nsw i64 %258, %257
  %260 = trunc i64 %259 to i32
  store i32 %260, ptr %gep559.1, align 4
  %261 = lshr i64 %259, 32
  %262 = add i64 %.3560, 2
  %niter669.next.1 = add i64 %niter669, 2
  %niter669.ncmp.1 = icmp eq i64 %niter669.next.1, %unroll_iter668
  br i1 %niter669.ncmp.1, label %Else24.unr-lcssa, label %Then24

Else24.unr-lcssa:                                 ; preds = %Then24
  br i1 %lcmp.mod665.not, label %Else24, label %Then24.epil.preheader

Then24.epil.preheader:                            ; preds = %Else24.unr-lcssa, %Then23
  %.0503561.epil.init = phi i64 [ 0, %Then23 ], [ %261, %Else24.unr-lcssa ]
  %.3560.epil.init = phi i64 [ 0, %Then23 ], [ %262, %Else24.unr-lcssa ]
  tail call void @llvm.assume(i1 %lcmp.mod667)
  %gep559.epil = getelementptr [4 x i8], ptr %invariant.gep, i64 %.3560.epil.init
  %263 = load i32, ptr %gep559.epil, align 4
  %264 = zext i32 %263 to i64
  %265 = getelementptr inbounds [4 x i8], ptr %6, i64 %.3560.epil.init
  %266 = load i32, ptr %265, align 4
  %267 = zext i32 %266 to i64
  %268 = add nuw nsw i64 %.0503561.epil.init, %264
  %269 = add nuw nsw i64 %268, %267
  %270 = trunc i64 %269 to i32
  store i32 %270, ptr %gep559.epil, align 4
  %271 = lshr i64 %269, 32
  br label %Else24

Else24:                                           ; preds = %Then24.epil.preheader, %Else24.unr-lcssa
  %.lcssa639 = phi i64 [ %261, %Else24.unr-lcssa ], [ %271, %Then24.epil.preheader ]
  %272 = load i32, ptr %166, align 4
  %273 = trunc nuw nsw i64 %.lcssa639 to i32
  %274 = add i32 %272, %273
  store i32 %274, ptr %166, align 4
  br label %Block73

TryCont:                                          ; preds = %Block73, %Else11, %Then9
  %275 = xor i32 %17, %15
  %276 = icmp slt i32 %275, 0
  br i1 %276, label %Then28.preheader, label %Block1

Then28.preheader:                                 ; preds = %TryCont
  store i1 true, ptr %.sroa.0498, align 1
  br label %Then28

Then28:                                           ; preds = %Then28, %Then28.preheader
  %.0564 = phi i64 [ %286, %Then28 ], [ 0, %Then28.preheader ]
  %277 = getelementptr inbounds nuw [4 x i8], ptr %0, i64 %.0564
  %278 = load i32, ptr %277, align 4
  %279 = xor i32 %278, -1
  %.sroa.0498.0..sroa.0498.0..sroa.0498.0..sroa.0498.0..sroa.0498.0. = load i8, ptr %.sroa.0498, align 1
  %280 = and i8 %.sroa.0498.0..sroa.0498.0..sroa.0498.0..sroa.0498.0..sroa.0498.0., 1
  %281 = zext nneg i8 %280 to i32
  %282 = tail call { i32, i1 } @llvm.uadd.with.overflow.i32(i32 %279, i32 %281)
  %283 = extractvalue { i32, i1 } %282, 0
  %284 = extractvalue { i32, i1 } %282, 1
  store i1 %284, ptr %.sroa.2502, align 4
  %.sroa.2502.0..sroa.2502.0..sroa.2502.0..sroa.2502.0..sroa.2502.4. = load i8, ptr %.sroa.2502, align 4
  %285 = trunc i8 %.sroa.2502.0..sroa.2502.0..sroa.2502.0..sroa.2502.0..sroa.2502.4. to i1
  store i1 %285, ptr %.sroa.0498, align 1
  store i32 %283, ptr %277, align 4
  %286 = add nuw nsw i64 %.0564, 1
  %exitcond586.not = icmp eq i64 %286, %11
  br i1 %exitcond586.not, label %Block1, label %Then28
}

attributes #0 = { nofree norecurse nosync nounwind memory(argmem: readwrite, inaccessiblemem: write) uwtable "frame-pointer"="all" "no-builtins" "target-cpu"="x86-64" "target-features"="+64bit,+cmov,+cx8,+fxsr,+idivq-to-divl,+macrofusion,+mmx,+nopl,+slow-3ops-lea,+slow-incdec,+sse,+sse2,+vzeroupper,+x87,-16bit-mode,-32bit-mode,-adx,-aes,-allow-light-256-bit,-amx-avx512,-amx-bf16,-amx-complex,-amx-fp16,-amx-fp8,-amx-int8,-amx-movrs,-amx-tf32,-amx-tile,-avx,-avx10.1,-avx10.2,-avx2,-avx512bf16,-avx512bitalg,-avx512bw,-avx512cd,-avx512dq,-avx512f,-avx512fp16,-avx512ifma,-avx512vbmi,-avx512vbmi2,-avx512vl,-avx512vnni,-avx512vp2intersect,-avx512vpopcntdq,-avxifma,-avxneconvert,-avxvnni,-avxvnniint16,-avxvnniint8,-bmi,-bmi2,-branch-hint,-branchfusion,-ccmp,-cf,-cldemote,-clflushopt,-clwb,-clzero,-cmpccxadd,-crc32,-cx16,-egpr,-enqcmd,-ermsb,-f16c,-false-deps-getmant,-false-deps-lzcnt-tzcnt,-false-deps-mulc,-false-deps-mullq,-false-deps-perm,-false-deps-popcnt,-false-deps-range,-fast-11bytenop,-fast-15bytenop,-fast-7bytenop,-fast-bextr,-fast-dpwssd,-fast-gather,-fast-hops,-fast-imm16,-fast-lzcnt,-fast-movbe,-fast-scalar-fsqrt,-fast-scalar-shift-masks,-fast-shld-rotate,-fast-variable-crosslane-shuffle,-fast-variable-perlane-shuffle,-fast-vector-fsqrt,-fast-vector-shift-masks,-faster-shift-than-shuffle,-fma,-fma4,-fsgsbase,-fsrm,-gfni,-harden-sls-ijmp,-harden-sls-ret,-hreset,-idivl-to-divb,-inline-asm-use-gpr32,-invpcid,-kl,-lea-sp,-lea-uses-ag,-lvi-cfi,-lvi-load-hardening,-lwp,-lzcnt,-movbe,-movdir64b,-movdiri,-movrs,-mwaitx,-ndd,-nf,-no-bypass-delay,-no-bypass-delay-blend,-no-bypass-delay-mov,-no-bypass-delay-shuffle,-pad-short-functions,-pclmul,-pconfig,-pku,-popcnt,-ppx,-prefer-128-bit,-prefer-256-bit,-prefer-legacy-setcc,-prefer-mask-registers,-prefer-movmsk-over-vtest,-prefer-no-gather,-prefer-no-scatter,-prefetchi,-prfchw,-ptwrite,-push2pop2,-raoint,-rdpid,-rdpru,-rdrnd,-rdseed,-retpoline,-retpoline-external-thunk,-retpoline-indirect-branches,-retpoline-indirect-calls,-rtm,-sahf,-sbb-dep-breaking,-serialize,-seses,-sgx,-sha,-sha512,-shstk,-slow-lea,-slow-pmaddwd,-slow-pmulld,-slow-pmullq,-slow-shld,-slow-two-mem-ops,-slow-unaligned-mem-16,-slow-unaligned-mem-32,-sm3,-sm4,-soft-float,-sse3,-sse4.1,-sse4.2,-sse4a,-sse-unaligned-mem,-ssse3,-tagged-globals,-tbm,-tsxldtrk,-tuning-fast-imm-vector-shift,-uintr,-use-glm-div-sqrt-costs,-use-slm-arith-costs,-usermsr,-vaes,-vpclmulqdq,-waitpkg,-wbnoinvd,-widekl,-xop,-xsave,-xsavec,-xsaveopt,-xsaves,-zu" }
attributes #1 = { nocallback nofree nosync nounwind willreturn memory(inaccessiblemem: write) }
attributes #2 = { mustprogress nofree norecurse nosync nounwind willreturn memory(inaccessiblemem: write) uwtable "frame-pointer"="all" "no-builtins" "target-cpu"="x86-64" "target-features"="+64bit,+cmov,+cx8,+fxsr,+idivq-to-divl,+macrofusion,+mmx,+nopl,+slow-3ops-lea,+slow-incdec,+sse,+sse2,+vzeroupper,+x87,-16bit-mode,-32bit-mode,-adx,-aes,-allow-light-256-bit,-amx-avx512,-amx-bf16,-amx-complex,-amx-fp16,-amx-fp8,-amx-int8,-amx-movrs,-amx-tf32,-amx-tile,-avx,-avx10.1,-avx10.2,-avx2,-avx512bf16,-avx512bitalg,-avx512bw,-avx512cd,-avx512dq,-avx512f,-avx512fp16,-avx512ifma,-avx512vbmi,-avx512vbmi2,-avx512vl,-avx512vnni,-avx512vp2intersect,-avx512vpopcntdq,-avxifma,-avxneconvert,-avxvnni,-avxvnniint16,-avxvnniint8,-bmi,-bmi2,-branch-hint,-branchfusion,-ccmp,-cf,-cldemote,-clflushopt,-clwb,-clzero,-cmpccxadd,-crc32,-cx16,-egpr,-enqcmd,-ermsb,-f16c,-false-deps-getmant,-false-deps-lzcnt-tzcnt,-false-deps-mulc,-false-deps-mullq,-false-deps-perm,-false-deps-popcnt,-false-deps-range,-fast-11bytenop,-fast-15bytenop,-fast-7bytenop,-fast-bextr,-fast-dpwssd,-fast-gather,-fast-hops,-fast-imm16,-fast-lzcnt,-fast-movbe,-fast-scalar-fsqrt,-fast-scalar-shift-masks,-fast-shld-rotate,-fast-variable-crosslane-shuffle,-fast-variable-perlane-shuffle,-fast-vector-fsqrt,-fast-vector-shift-masks,-faster-shift-than-shuffle,-fma,-fma4,-fsgsbase,-fsrm,-gfni,-harden-sls-ijmp,-harden-sls-ret,-hreset,-idivl-to-divb,-inline-asm-use-gpr32,-invpcid,-kl,-lea-sp,-lea-uses-ag,-lvi-cfi,-lvi-load-hardening,-lwp,-lzcnt,-movbe,-movdir64b,-movdiri,-movrs,-mwaitx,-ndd,-nf,-no-bypass-delay,-no-bypass-delay-blend,-no-bypass-delay-mov,-no-bypass-delay-shuffle,-pad-short-functions,-pclmul,-pconfig,-pku,-popcnt,-ppx,-prefer-128-bit,-prefer-256-bit,-prefer-legacy-setcc,-prefer-mask-registers,-prefer-movmsk-over-vtest,-prefer-no-gather,-prefer-no-scatter,-prefetchi,-prfchw,-ptwrite,-push2pop2,-raoint,-rdpid,-rdpru,-rdrnd,-rdseed,-retpoline,-retpoline-external-thunk,-retpoline-indirect-branches,-retpoline-indirect-calls,-rtm,-sahf,-sbb-dep-breaking,-serialize,-seses,-sgx,-sha,-sha512,-shstk,-slow-lea,-slow-pmaddwd,-slow-pmulld,-slow-pmullq,-slow-shld,-slow-two-mem-ops,-slow-unaligned-mem-16,-slow-unaligned-mem-32,-sm3,-sm4,-soft-float,-sse3,-sse4.1,-sse4.2,-sse4a,-sse-unaligned-mem,-ssse3,-tagged-globals,-tbm,-tsxldtrk,-tuning-fast-imm-vector-shift,-uintr,-use-glm-div-sqrt-costs,-use-slm-arith-costs,-usermsr,-vaes,-vpclmulqdq,-waitpkg,-wbnoinvd,-widekl,-xop,-xsave,-xsavec,-xsaveopt,-xsaves,-zu" }
attributes #3 = { nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none) }
attributes #4 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #5 = { nofree norecurse nosync nounwind memory(read, argmem: readwrite, inaccessiblemem: write, target_mem0: none, target_mem1: none) uwtable "frame-pointer"="all" "no-builtins" "target-cpu"="x86-64" "target-features"="+64bit,+cmov,+cx8,+fxsr,+idivq-to-divl,+macrofusion,+mmx,+nopl,+slow-3ops-lea,+slow-incdec,+sse,+sse2,+vzeroupper,+x87,-16bit-mode,-32bit-mode,-adx,-aes,-allow-light-256-bit,-amx-avx512,-amx-bf16,-amx-complex,-amx-fp16,-amx-fp8,-amx-int8,-amx-movrs,-amx-tf32,-amx-tile,-avx,-avx10.1,-avx10.2,-avx2,-avx512bf16,-avx512bitalg,-avx512bw,-avx512cd,-avx512dq,-avx512f,-avx512fp16,-avx512ifma,-avx512vbmi,-avx512vbmi2,-avx512vl,-avx512vnni,-avx512vp2intersect,-avx512vpopcntdq,-avxifma,-avxneconvert,-avxvnni,-avxvnniint16,-avxvnniint8,-bmi,-bmi2,-branch-hint,-branchfusion,-ccmp,-cf,-cldemote,-clflushopt,-clwb,-clzero,-cmpccxadd,-crc32,-cx16,-egpr,-enqcmd,-ermsb,-f16c,-false-deps-getmant,-false-deps-lzcnt-tzcnt,-false-deps-mulc,-false-deps-mullq,-false-deps-perm,-false-deps-popcnt,-false-deps-range,-fast-11bytenop,-fast-15bytenop,-fast-7bytenop,-fast-bextr,-fast-dpwssd,-fast-gather,-fast-hops,-fast-imm16,-fast-lzcnt,-fast-movbe,-fast-scalar-fsqrt,-fast-scalar-shift-masks,-fast-shld-rotate,-fast-variable-crosslane-shuffle,-fast-variable-perlane-shuffle,-fast-vector-fsqrt,-fast-vector-shift-masks,-faster-shift-than-shuffle,-fma,-fma4,-fsgsbase,-fsrm,-gfni,-harden-sls-ijmp,-harden-sls-ret,-hreset,-idivl-to-divb,-inline-asm-use-gpr32,-invpcid,-kl,-lea-sp,-lea-uses-ag,-lvi-cfi,-lvi-load-hardening,-lwp,-lzcnt,-movbe,-movdir64b,-movdiri,-movrs,-mwaitx,-ndd,-nf,-no-bypass-delay,-no-bypass-delay-blend,-no-bypass-delay-mov,-no-bypass-delay-shuffle,-pad-short-functions,-pclmul,-pconfig,-pku,-popcnt,-ppx,-prefer-128-bit,-prefer-256-bit,-prefer-legacy-setcc,-prefer-mask-registers,-prefer-movmsk-over-vtest,-prefer-no-gather,-prefer-no-scatter,-prefetchi,-prfchw,-ptwrite,-push2pop2,-raoint,-rdpid,-rdpru,-rdrnd,-rdseed,-retpoline,-retpoline-external-thunk,-retpoline-indirect-branches,-retpoline-indirect-calls,-rtm,-sahf,-sbb-dep-breaking,-serialize,-seses,-sgx,-sha,-sha512,-shstk,-slow-lea,-slow-pmaddwd,-slow-pmulld,-slow-pmullq,-slow-shld,-slow-two-mem-ops,-slow-unaligned-mem-16,-slow-unaligned-mem-32,-sm3,-sm4,-soft-float,-sse3,-sse4.1,-sse4.2,-sse4a,-sse-unaligned-mem,-ssse3,-tagged-globals,-tbm,-tsxldtrk,-tuning-fast-imm-vector-shift,-uintr,-use-glm-div-sqrt-costs,-use-slm-arith-costs,-usermsr,-vaes,-vpclmulqdq,-waitpkg,-wbnoinvd,-widekl,-xop,-xsave,-xsavec,-xsaveopt,-xsaves,-zu" }
attributes #6 = { nobuiltin }

!llvm.module.flags = !{!0, !1}

!0 = !{i32 2, !"Debug Info Version", i32 3}
!1 = !{i32 7, !"Dwarf Version", i32 4}
!2 = distinct !{!2, !3}
!3 = !{!"llvm.loop.unroll.disable"}
!4 = distinct !{!4, !3}
!5 = distinct !{!5, !3}
!6 = distinct !{!6, !3}
