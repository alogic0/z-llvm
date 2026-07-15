; INBOX-54 exact captured __modei4/__modei5 audit bodies, linked and debug-stripped.
; Source md5: b0eda7a6427c3084fdf096a68696f19c.
; ModuleID = 'tmp/inbox54_signed_rem.bc'
source_filename = "llvm-link"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux5.10.0-gnu2.31.0"

; Function Attrs: nofree norecurse nosync nounwind memory(argmem: readwrite, inaccessiblemem: write) uwtable
define hidden void @compiler_rt.divmodei4.__modei4(ptr nonnull align 1 captures(address) %0, ptr nonnull align 1 captures(none) %1, ptr nonnull align 1 captures(none) %2, i64 %3) unnamed_addr #0 align 1 {
Entry:
  %.sroa.2532 = alloca i8, align 4
  %.sroa.0528 = alloca i8, align 1
  %4 = alloca [2049 x i32], align 4
  %5 = alloca [2048 x i32], align 4
  %.sroa.299 = alloca i8, align 4
  %.sroa.095 = alloca i8, align 1
  %.sroa.281 = alloca i8, align 4
  %.sroa.078 = alloca i8, align 1
  %6 = icmp ult i64 %3, 65536
  tail call void @llvm.assume(i1 %6)
  %7 = trunc nuw i64 %3 to i16
  %8 = tail call fastcc i16 @zig.target.intByteSize(i16 %7) #7
  %9 = zext nneg i16 %8 to i64
  %10 = lshr exact i64 %9, 2
  %11 = add nsw i64 %10, -1
  %12 = getelementptr inbounds nuw [4 x i8], ptr %1, i64 %11
  %13 = load i32, ptr %12, align 4
  %14 = getelementptr inbounds nuw [4 x i8], ptr %2, i64 %11
  %15 = load i32, ptr %14, align 4
  %16 = icmp sgt i32 %13, -1
  br i1 %16, label %Block4, label %Then

Block1:                                           ; preds = %Then29, %Block18
  ret void

Block4:                                           ; preds = %Then1, %Entry
  %17 = icmp slt i32 %15, 0
  %.not598 = icmp eq i16 %8, 0
  br i1 %17, label %Then2, label %Block16

Then:                                             ; preds = %Entry
  store i1 true, ptr %.sroa.078, align 1
  %.not597 = icmp eq i16 %8, 0
  br i1 %.not597, label %Block19, label %Then1

Then1:                                            ; preds = %Then1, %Then
  %.0543574 = phi i64 [ %27, %Then1 ], [ 0, %Then ]
  %18 = getelementptr inbounds nuw [4 x i8], ptr %1, i64 %.0543574
  %19 = load i32, ptr %18, align 4
  %20 = xor i32 %19, -1
  %.sroa.078.0..sroa.078.0..sroa.078.0..sroa.078.0..sroa.078.0. = load i8, ptr %.sroa.078, align 1
  %21 = and i8 %.sroa.078.0..sroa.078.0..sroa.078.0..sroa.078.0..sroa.078.0., 1
  %22 = zext nneg i8 %21 to i32
  %23 = tail call { i32, i1 } @llvm.uadd.with.overflow.i32(i32 %20, i32 %22)
  %24 = extractvalue { i32, i1 } %23, 0
  %25 = extractvalue { i32, i1 } %23, 1
  store i1 %25, ptr %.sroa.281, align 4
  %.sroa.281.0..sroa.281.0..sroa.281.0..sroa.281.0..sroa.281.4. = load i8, ptr %.sroa.281, align 4
  %26 = trunc i8 %.sroa.281.0..sroa.281.0..sroa.281.0..sroa.281.0..sroa.281.4. to i1
  store i1 %26, ptr %.sroa.078, align 1
  store i32 %24, ptr %18, align 4
  %27 = add nuw nsw i64 %.0543574, 1
  %exitcond.not = icmp eq i64 %27, %10
  br i1 %exitcond.not, label %Block4, label %Then1

Then2:                                            ; preds = %Block4
  store i1 true, ptr %.sroa.095, align 1
  br i1 %.not598, label %Block19, label %Then3

Then3:                                            ; preds = %Then3, %Then2
  %.0542575 = phi i64 [ %37, %Then3 ], [ 0, %Then2 ]
  %28 = getelementptr inbounds nuw [4 x i8], ptr %2, i64 %.0542575
  %29 = load i32, ptr %28, align 4
  %30 = xor i32 %29, -1
  %.sroa.095.0..sroa.095.0..sroa.095.0..sroa.095.0..sroa.095.0. = load i8, ptr %.sroa.095, align 1
  %31 = and i8 %.sroa.095.0..sroa.095.0..sroa.095.0..sroa.095.0..sroa.095.0., 1
  %32 = zext nneg i8 %31 to i32
  %33 = tail call { i32, i1 } @llvm.uadd.with.overflow.i32(i32 %30, i32 %32)
  %34 = extractvalue { i32, i1 } %33, 0
  %35 = extractvalue { i32, i1 } %33, 1
  store i1 %35, ptr %.sroa.299, align 4
  %.sroa.299.0..sroa.299.0..sroa.299.0..sroa.299.0..sroa.299.4. = load i8, ptr %.sroa.299, align 4
  %36 = trunc i8 %.sroa.299.0..sroa.299.0..sroa.299.0..sroa.299.0..sroa.299.4. to i1
  store i1 %36, ptr %.sroa.095, align 1
  store i32 %34, ptr %28, align 4
  %37 = add nuw nsw i64 %.0542575, 1
  %exitcond608.not = icmp eq i64 %37, %10
  br i1 %exitcond608.not, label %InlineMemsetBody.preheader, label %Then3

Block16:                                          ; preds = %Block4
  br i1 %.not598, label %Block19, label %InlineMemsetBody.preheader

InlineMemsetBody.preheader:                       ; preds = %Block16, %Then3
  %38 = getelementptr inbounds nuw i8, ptr %0, i64 %9
  %39 = add nsw i64 %9, -4
  %40 = lshr i64 %39, 2
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

Block18:                                          ; preds = %Else26, %Then14, %Then9
  br i1 %16, label %Block1, label %Then29.preheader, !prof !4

Block19:                                          ; preds = %InlineMemsetBody, %InlineMemsetBody.prol.loopexit, %Block16, %Then2, %Then
  %46 = icmp ne i16 %8, 0
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
  %.0541.lcssa = phi i64 [ %11, %Block19 ], [ %61, %Else10 ]
  %.pre615 = phi i32 [ %47, %Block19 ], [ %63, %Else10 ]
  %58 = load i32, ptr %14, align 4
  %59 = icmp eq i32 %58, 0
  br i1 %59, label %Then11, label %Else11

Then9:                                            ; preds = %Else10, %Block19
  %.0541577 = phi i64 [ %61, %Else10 ], [ %11, %Block19 ]
  %60 = icmp eq i64 %.0541577, 0
  br i1 %60, label %Block18, label %Else10

Else10:                                           ; preds = %Then9
  %61 = add nsw i64 %.0541577, -1
  %62 = getelementptr inbounds nuw [4 x i8], ptr %1, i64 %61
  %63 = load i32, ptr %62, align 4
  %64 = icmp eq i32 %63, 0
  br i1 %64, label %Then9, label %Loop3.preheader

Then11:                                           ; preds = %Then11, %Loop3.preheader
  %.0540579 = phi i64 [ %66, %Then11 ], [ %11, %Loop3.preheader ]
  %65 = icmp ne i64 %.0540579, 0
  tail call void @llvm.assume(i1 %65)
  %66 = add nsw i64 %.0540579, -1
  %67 = getelementptr inbounds nuw [4 x i8], ptr %2, i64 %66
  %68 = load i32, ptr %67, align 4
  %69 = icmp eq i32 %68, 0
  br i1 %69, label %Then11, label %Else11

Else11:                                           ; preds = %Then11, %Loop3.preheader
  %.0540.lcssa = phi i64 [ %11, %Loop3.preheader ], [ %66, %Then11 ]
  %.lcssa = phi i32 [ %58, %Loop3.preheader ], [ %68, %Then11 ]
  %.0540.lcssa.fr = freeze i64 %.0540.lcssa
  %70 = icmp ugt i64 %.0540.lcssa.fr, %.0541.lcssa
  br i1 %70, label %Then14, label %Else13

Else13:                                           ; preds = %Else11
  %71 = tail call range(i32 0, 33) i32 @llvm.ctlz.i32(i32 %.lcssa, i1 true)
  %72 = trunc nuw nsw i32 %71 to i6
  %.not548582 = icmp eq i64 %.0540.lcssa.fr, 0
  %.pre617 = sub nuw i6 -32, %72
  br i1 %.not548582, label %Else13.Else15_crit_edge, label %Then15.lr.ph

Else13.Else15_crit_edge:                          ; preds = %Else13
  %.pre618 = zext nneg i6 %.pre617 to i32
  br label %Else15

Then15.lr.ph:                                     ; preds = %Else13
  %73 = icmp sgt i6 %.pre617, -1
  %74 = zext nneg i6 %.pre617 to i32
  %.phi.trans.insert = getelementptr inbounds nuw [4 x i8], ptr %2, i64 %.0540.lcssa.fr
  %.pre = load i32, ptr %.phi.trans.insert, align 4
  %xtraiter654 = and i64 %.0540.lcssa.fr, 1
  %lcmp.mod655.not = icmp eq i64 %xtraiter654, 0
  br i1 %lcmp.mod655.not, label %Then15.prol.loopexit, label %Then15.prol

Then15.prol:                                      ; preds = %Then15.lr.ph
  %75 = shl i32 %.pre, %71
  %76 = add nsw i64 %.0540.lcssa.fr, -1
  %77 = getelementptr inbounds nuw [4 x i8], ptr %2, i64 %76
  %78 = load i32, ptr %77, align 4
  %79 = lshr i32 %78, %74
  %common.ret.op.i556.prol = select i1 %73, i32 %79, i32 0
  %80 = or i32 %common.ret.op.i556.prol, %75
  %81 = getelementptr inbounds nuw [4 x i8], ptr %5, i64 %.0540.lcssa.fr
  store i32 %80, ptr %81, align 4
  br label %Then15.prol.loopexit

Then15.prol.loopexit:                             ; preds = %Then15.prol, %Then15.lr.ph
  %.unr657 = phi i32 [ %.pre, %Then15.lr.ph ], [ %78, %Then15.prol ]
  %.0538583.unr = phi i64 [ %.0540.lcssa.fr, %Then15.lr.ph ], [ %76, %Then15.prol ]
  %82 = icmp eq i64 %.0540.lcssa.fr, 1
  br i1 %82, label %Else15, label %Then15

Then14:                                           ; preds = %Else11
  tail call void @llvm.memcpy.inline.p0.p0.i64(ptr nonnull align 4 %0, ptr nonnull align 4 %1, i64 %9, i1 false)
  br label %Block18

Then15:                                           ; preds = %Then15, %Then15.prol.loopexit
  %83 = phi i32 [ %94, %Then15 ], [ %.unr657, %Then15.prol.loopexit ]
  %.0538583 = phi i64 [ %92, %Then15 ], [ %.0538583.unr, %Then15.prol.loopexit ]
  %84 = shl i32 %83, %71
  %85 = add nsw i64 %.0538583, -1
  %86 = getelementptr inbounds nuw [4 x i8], ptr %2, i64 %85
  %87 = load i32, ptr %86, align 4
  %88 = lshr i32 %87, %74
  %common.ret.op.i556 = select i1 %73, i32 %88, i32 0
  %89 = or i32 %common.ret.op.i556, %84
  %90 = getelementptr inbounds nuw [4 x i8], ptr %5, i64 %.0538583
  store i32 %89, ptr %90, align 4
  %91 = shl i32 %87, %71
  %92 = add nsw i64 %.0538583, -2
  %93 = getelementptr inbounds nuw [4 x i8], ptr %2, i64 %92
  %94 = load i32, ptr %93, align 4
  %95 = lshr i32 %94, %74
  %common.ret.op.i556.1 = select i1 %73, i32 %95, i32 0
  %96 = or i32 %common.ret.op.i556.1, %91
  %97 = getelementptr inbounds nuw [4 x i8], ptr %5, i64 %85
  store i32 %96, ptr %97, align 4
  %.not548.1 = icmp eq i64 %92, 0
  br i1 %.not548.1, label %Else15, label %Then15

Else15:                                           ; preds = %Then15, %Then15.prol.loopexit, %Else13.Else15_crit_edge
  %.pre-phi619 = phi i32 [ %.pre618, %Else13.Else15_crit_edge ], [ %74, %Then15 ], [ %74, %Then15.prol.loopexit ]
  %98 = load i32, ptr %2, align 4
  %99 = shl i32 %98, %71
  store i32 %99, ptr %5, align 4
  %100 = icmp sgt i6 %.pre617, -1
  %101 = lshr i32 %.pre615, %.pre-phi619
  %common.ret.op.i558 = select i1 %100, i32 %101, i32 0
  %102 = getelementptr inbounds nuw [4 x i8], ptr %4, i64 %.0541.lcssa
  %103 = getelementptr inbounds nuw i8, ptr %102, i64 4
  store i32 %common.ret.op.i558, ptr %103, align 4
  %.not549584 = icmp eq i64 %.0541.lcssa, 0
  br i1 %.not549584, label %Else16, label %Then16.preheader

Then16.preheader:                                 ; preds = %Else15
  %xtraiter658 = and i64 %.0541.lcssa, 1
  %lcmp.mod659.not = icmp eq i64 %xtraiter658, 0
  br i1 %lcmp.mod659.not, label %Then16.prol.loopexit, label %Then16.prol

Then16.prol:                                      ; preds = %Then16.preheader
  %104 = shl i32 %.pre615, %71
  %105 = add nsw i64 %.0541.lcssa, -1
  %106 = getelementptr inbounds nuw [4 x i8], ptr %1, i64 %105
  %107 = load i32, ptr %106, align 4
  %108 = lshr i32 %107, %.pre-phi619
  %common.ret.op.i560.prol = select i1 %100, i32 %108, i32 0
  %109 = or i32 %common.ret.op.i560.prol, %104
  %110 = getelementptr inbounds nuw [4 x i8], ptr %4, i64 %.0541.lcssa
  store i32 %109, ptr %110, align 4
  br label %Then16.prol.loopexit

Then16.prol.loopexit:                             ; preds = %Then16.prol, %Then16.preheader
  %.unr661 = phi i32 [ %.pre615, %Then16.preheader ], [ %107, %Then16.prol ]
  %.1539585.unr = phi i64 [ %.0541.lcssa, %Then16.preheader ], [ %105, %Then16.prol ]
  %111 = icmp eq i64 %.0541.lcssa, 1
  br i1 %111, label %Else16, label %Then16

Then16:                                           ; preds = %Then16, %Then16.prol.loopexit
  %112 = phi i32 [ %123, %Then16 ], [ %.unr661, %Then16.prol.loopexit ]
  %.1539585 = phi i64 [ %121, %Then16 ], [ %.1539585.unr, %Then16.prol.loopexit ]
  %113 = shl i32 %112, %71
  %114 = add nsw i64 %.1539585, -1
  %115 = getelementptr inbounds nuw [4 x i8], ptr %1, i64 %114
  %116 = load i32, ptr %115, align 4
  %117 = lshr i32 %116, %.pre-phi619
  %common.ret.op.i560 = select i1 %100, i32 %117, i32 0
  %118 = or i32 %common.ret.op.i560, %113
  %119 = getelementptr inbounds nuw [4 x i8], ptr %4, i64 %.1539585
  store i32 %118, ptr %119, align 4
  %120 = shl i32 %116, %71
  %121 = add nsw i64 %.1539585, -2
  %122 = getelementptr inbounds nuw [4 x i8], ptr %1, i64 %121
  %123 = load i32, ptr %122, align 4
  %124 = lshr i32 %123, %.pre-phi619
  %common.ret.op.i560.1 = select i1 %100, i32 %124, i32 0
  %125 = or i32 %common.ret.op.i560.1, %120
  %126 = getelementptr inbounds nuw [4 x i8], ptr %4, i64 %114
  store i32 %125, ptr %126, align 4
  %.not549.1 = icmp eq i64 %121, 0
  br i1 %.not549.1, label %Else16, label %Then16

Else16:                                           ; preds = %Then16, %Then16.prol.loopexit, %Else15
  %127 = load i32, ptr %1, align 4
  %128 = shl i32 %127, %71
  store i32 %128, ptr %4, align 4
  %129 = sub nuw nsw i64 %.0541.lcssa, %.0540.lcssa.fr
  %invariant.gep593 = getelementptr [4 x i8], ptr %4, i64 %.0540.lcssa.fr
  %130 = getelementptr inbounds nuw [4 x i8], ptr %5, i64 %.0540.lcssa.fr
  %131 = load i32, ptr %130, align 4
  %132 = zext i32 %131 to i64
  %133 = getelementptr i8, ptr %130, i64 -4
  %134 = add i64 %.0540.lcssa.fr, 1
  %xtraiter662 = and i64 %134, 1
  %135 = icmp eq i64 %.0540.lcssa.fr, 0
  %unroll_iter = and i64 %134, -2
  %lcmp.mod663.not = icmp eq i64 %xtraiter662, 0
  %lcmp.mod665 = icmp ne i64 %xtraiter662, 0
  %xtraiter666 = and i64 %134, 1
  %136 = icmp eq i64 %.0540.lcssa.fr, 0
  %unroll_iter670 = and i64 %134, -2
  %lcmp.mod667.not = icmp eq i64 %xtraiter666, 0
  %lcmp.mod669 = icmp ne i64 %xtraiter666, 0
  br label %Loop6

Loop6:                                            ; preds = %Block72, %Else16
  %.0537 = phi i64 [ %129, %Else16 ], [ %210, %Block72 ]
  %gep594 = getelementptr [4 x i8], ptr %invariant.gep593, i64 %.0537
  %137 = getelementptr inbounds nuw i8, ptr %gep594, i64 4
  %138 = load i32, ptr %137, align 4
  %139 = zext i32 %138 to i64
  %140 = shl nuw i64 %139, 32
  %141 = load i32, ptr %gep594, align 4
  %142 = zext i32 %141 to i64
  %143 = or disjoint i64 %140, %142
  %144 = udiv i64 %143, %132
  %145 = urem i64 %143, %132
  %146 = getelementptr i8, ptr %gep594, i64 -4
  br i1 %.not548582, label %Loop7.us, label %Loop7

Loop7.us:                                         ; preds = %Then19.us, %Loop6
  %.0536.us = phi i64 [ %148, %Then19.us ], [ %144, %Loop6 ]
  %.0535.us = phi i64 [ %149, %Then19.us ], [ %145, %Loop6 ]
  %147 = icmp ugt i64 %.0536.us, 4294967295
  br i1 %147, label %Then19.us, label %Block57

Then19.us:                                        ; preds = %Loop7.us
  %148 = add i64 %.0536.us, -1
  %149 = add nuw nsw i64 %.0535.us, %132
  %150 = icmp samesign ult i64 %149, 4294967296
  br i1 %150, label %Loop7.us, label %Block57

Loop7:                                            ; preds = %Then19, %Loop6
  %.0536 = phi i64 [ %160, %Then19 ], [ %144, %Loop6 ]
  %.0535 = phi i64 [ %161, %Then19 ], [ %145, %Loop6 ]
  %151 = icmp ugt i64 %.0536, 4294967295
  br i1 %151, label %Then19, label %Else17

Block57:                                          ; preds = %Then19, %Else17, %Then19.us, %Loop7.us
  %.us-phi = phi i64 [ %148, %Then19.us ], [ %.0536.us, %Loop7.us ], [ %160, %Then19 ], [ %.0536, %Else17 ]
  %invariant.gep = getelementptr [4 x i8], ptr %4, i64 %.0537
  br i1 %135, label %Then21.epil.preheader, label %Then21

Else17:                                           ; preds = %Loop7
  %152 = load i32, ptr %133, align 4
  %153 = zext i32 %152 to i64
  %154 = mul nuw i64 %.0536, %153
  %155 = shl nuw i64 %.0535, 32
  %156 = load i32, ptr %146, align 4
  %157 = zext i32 %156 to i64
  %158 = or disjoint i64 %155, %157
  %159 = icmp ugt i64 %154, %158
  br i1 %159, label %Then19, label %Block57

Then19:                                           ; preds = %Else17, %Loop7
  %160 = add i64 %.0536, -1
  %161 = add nuw nsw i64 %.0535, %132
  %162 = icmp samesign ult i64 %161, 4294967296
  br i1 %162, label %Loop7, label %Block57

Then21:                                           ; preds = %Then21, %Block57
  %.0534588 = phi i64 [ %189, %Then21 ], [ 0, %Block57 ]
  %.2587 = phi i64 [ %190, %Then21 ], [ 0, %Block57 ]
  %niter = phi i64 [ %niter.next.1, %Then21 ], [ 0, %Block57 ]
  %163 = getelementptr inbounds nuw [4 x i8], ptr %5, i64 %.2587
  %164 = load i32, ptr %163, align 4
  %165 = zext i32 %164 to i64
  %166 = mul nuw i64 %.us-phi, %165
  %gep = getelementptr [4 x i8], ptr %invariant.gep, i64 %.2587
  %167 = load i32, ptr %gep, align 4
  %168 = zext i32 %167 to i64
  %169 = and i64 %166, 4294967295
  %170 = add nuw nsw i64 %.0534588, %169
  %171 = sub nsw i64 %168, %170
  %172 = trunc i64 %171 to i32
  store i32 %172, ptr %gep, align 4
  %173 = lshr i64 %166, 32
  %174 = ashr i64 %171, 32
  %175 = sub nsw i64 %173, %174
  %176 = or disjoint i64 %.2587, 1
  %177 = getelementptr inbounds nuw [4 x i8], ptr %5, i64 %176
  %178 = load i32, ptr %177, align 4
  %179 = zext i32 %178 to i64
  %180 = mul nuw i64 %.us-phi, %179
  %gep.1 = getelementptr [4 x i8], ptr %invariant.gep, i64 %176
  %181 = load i32, ptr %gep.1, align 4
  %182 = zext i32 %181 to i64
  %183 = and i64 %180, 4294967295
  %184 = add nuw nsw i64 %175, %183
  %185 = sub nsw i64 %182, %184
  %186 = trunc i64 %185 to i32
  store i32 %186, ptr %gep.1, align 4
  %187 = lshr i64 %180, 32
  %188 = ashr i64 %185, 32
  %189 = sub nsw i64 %187, %188
  %190 = add nuw i64 %.2587, 2
  %niter.next.1 = add i64 %niter, 2
  %niter.ncmp.1 = icmp eq i64 %niter.next.1, %unroll_iter
  br i1 %niter.ncmp.1, label %Else21.unr-lcssa, label %Then21

Else21.unr-lcssa:                                 ; preds = %Then21
  br i1 %lcmp.mod663.not, label %Else21, label %Then21.epil.preheader

Then21.epil.preheader:                            ; preds = %Else21.unr-lcssa, %Block57
  %.0534588.epil.init = phi i64 [ 0, %Block57 ], [ %189, %Else21.unr-lcssa ]
  %.2587.epil.init = phi i64 [ 0, %Block57 ], [ %190, %Else21.unr-lcssa ]
  tail call void @llvm.assume(i1 %lcmp.mod665)
  %191 = getelementptr inbounds nuw [4 x i8], ptr %5, i64 %.2587.epil.init
  %192 = load i32, ptr %191, align 4
  %193 = zext i32 %192 to i64
  %194 = mul nuw i64 %.us-phi, %193
  %gep.epil = getelementptr [4 x i8], ptr %invariant.gep, i64 %.2587.epil.init
  %195 = load i32, ptr %gep.epil, align 4
  %196 = zext i32 %195 to i64
  %197 = and i64 %194, 4294967295
  %198 = add nuw nsw i64 %.0534588.epil.init, %197
  %199 = sub nsw i64 %196, %198
  %200 = trunc i64 %199 to i32
  store i32 %200, ptr %gep.epil, align 4
  %201 = lshr i64 %194, 32
  %202 = ashr i64 %199, 32
  %203 = sub nsw i64 %201, %202
  br label %Else21

Else21:                                           ; preds = %Then21.epil.preheader, %Else21.unr-lcssa
  %.lcssa648 = phi i64 [ %189, %Else21.unr-lcssa ], [ %203, %Then21.epil.preheader ]
  %204 = load i32, ptr %137, align 4
  %205 = zext i32 %204 to i64
  %206 = sub nsw i64 %205, %.lcssa648
  %207 = trunc i64 %206 to i32
  store i32 %207, ptr %137, align 4
  %208 = icmp slt i64 %206, 0
  br i1 %208, label %Then23.preheader, label %Block72

Then23.preheader:                                 ; preds = %Else21
  br i1 %136, label %Then23.epil.preheader, label %Then23

Block72:                                          ; preds = %Else23, %Else21
  %209 = icmp eq i64 %.0537, 0
  %210 = add nsw i64 %.0537, -1
  br i1 %209, label %Then26.preheader, label %Loop6

Then26.preheader:                                 ; preds = %Block72
  %.pre616 = load i32, ptr %4, align 4
  %xtraiter672 = and i64 %134, 1
  %211 = icmp eq i64 %.0540.lcssa.fr, 0
  br i1 %211, label %Then26.epil.preheader, label %Then26.preheader.new

Then26.preheader.new:                             ; preds = %Then26.preheader
  %unroll_iter676 = and i64 %134, -2
  br label %Then26

Then23:                                           ; preds = %Then23, %Then23.preheader
  %.0533592 = phi i64 [ %230, %Then23 ], [ 0, %Then23.preheader ]
  %.3591 = phi i64 [ %231, %Then23 ], [ 0, %Then23.preheader ]
  %niter671 = phi i64 [ %niter671.next.1, %Then23 ], [ 0, %Then23.preheader ]
  %gep590 = getelementptr [4 x i8], ptr %invariant.gep, i64 %.3591
  %212 = load i32, ptr %gep590, align 4
  %213 = zext i32 %212 to i64
  %214 = getelementptr inbounds nuw [4 x i8], ptr %5, i64 %.3591
  %215 = load i32, ptr %214, align 4
  %216 = zext i32 %215 to i64
  %217 = add nuw nsw i64 %.0533592, %213
  %218 = add nuw nsw i64 %217, %216
  %219 = trunc i64 %218 to i32
  store i32 %219, ptr %gep590, align 4
  %220 = lshr i64 %218, 32
  %221 = or disjoint i64 %.3591, 1
  %gep590.1 = getelementptr [4 x i8], ptr %invariant.gep, i64 %221
  %222 = load i32, ptr %gep590.1, align 4
  %223 = zext i32 %222 to i64
  %224 = getelementptr inbounds nuw [4 x i8], ptr %5, i64 %221
  %225 = load i32, ptr %224, align 4
  %226 = zext i32 %225 to i64
  %227 = add nuw nsw i64 %220, %223
  %228 = add nuw nsw i64 %227, %226
  %229 = trunc i64 %228 to i32
  store i32 %229, ptr %gep590.1, align 4
  %230 = lshr i64 %228, 32
  %231 = add nuw i64 %.3591, 2
  %niter671.next.1 = add i64 %niter671, 2
  %niter671.ncmp.1 = icmp eq i64 %niter671.next.1, %unroll_iter670
  br i1 %niter671.ncmp.1, label %Else23.unr-lcssa, label %Then23

Else23.unr-lcssa:                                 ; preds = %Then23
  br i1 %lcmp.mod667.not, label %Else23, label %Then23.epil.preheader

Then23.epil.preheader:                            ; preds = %Else23.unr-lcssa, %Then23.preheader
  %.0533592.epil.init = phi i64 [ 0, %Then23.preheader ], [ %230, %Else23.unr-lcssa ]
  %.3591.epil.init = phi i64 [ 0, %Then23.preheader ], [ %231, %Else23.unr-lcssa ]
  tail call void @llvm.assume(i1 %lcmp.mod669)
  %gep590.epil = getelementptr [4 x i8], ptr %invariant.gep, i64 %.3591.epil.init
  %232 = load i32, ptr %gep590.epil, align 4
  %233 = zext i32 %232 to i64
  %234 = getelementptr inbounds nuw [4 x i8], ptr %5, i64 %.3591.epil.init
  %235 = load i32, ptr %234, align 4
  %236 = zext i32 %235 to i64
  %237 = add nuw nsw i64 %.0533592.epil.init, %233
  %238 = add nuw nsw i64 %237, %236
  %239 = trunc i64 %238 to i32
  store i32 %239, ptr %gep590.epil, align 4
  %240 = lshr i64 %238, 32
  br label %Else23

Else23:                                           ; preds = %Then23.epil.preheader, %Else23.unr-lcssa
  %.lcssa649 = phi i64 [ %230, %Else23.unr-lcssa ], [ %240, %Then23.epil.preheader ]
  %241 = load i32, ptr %137, align 4
  %242 = trunc nuw nsw i64 %.lcssa649 to i32
  %243 = add i32 %241, %242
  store i32 %243, ptr %137, align 4
  br label %Block72

Then26:                                           ; preds = %Then26, %Then26.preheader.new
  %244 = phi i32 [ %.pre616, %Then26.preheader.new ], [ %255, %Then26 ]
  %.4595 = phi i64 [ 0, %Then26.preheader.new ], [ %253, %Then26 ]
  %niter677 = phi i64 [ 0, %Then26.preheader.new ], [ %niter677.next.1, %Then26 ]
  %245 = lshr i32 %244, %71
  %246 = or disjoint i64 %.4595, 1
  %247 = getelementptr inbounds nuw [4 x i8], ptr %4, i64 %246
  %248 = load i32, ptr %247, align 4
  %249 = shl i32 %248, %.pre-phi619
  %common.ret.op.i563 = select i1 %100, i32 %249, i32 0
  %250 = or i32 %common.ret.op.i563, %245
  %251 = getelementptr inbounds nuw [4 x i8], ptr %0, i64 %.4595
  store i32 %250, ptr %251, align 4
  %252 = lshr i32 %248, %71
  %253 = add nuw nsw i64 %.4595, 2
  %254 = getelementptr inbounds nuw [4 x i8], ptr %4, i64 %253
  %255 = load i32, ptr %254, align 4
  %256 = shl i32 %255, %.pre-phi619
  %common.ret.op.i563.1 = select i1 %100, i32 %256, i32 0
  %257 = or i32 %common.ret.op.i563.1, %252
  %258 = getelementptr inbounds nuw [4 x i8], ptr %0, i64 %246
  store i32 %257, ptr %258, align 4
  %niter677.next.1 = add i64 %niter677, 2
  %niter677.ncmp.1 = icmp eq i64 %niter677.next.1, %unroll_iter676
  br i1 %niter677.ncmp.1, label %Else26.unr-lcssa, label %Then26

Else26.unr-lcssa:                                 ; preds = %Then26
  %lcmp.mod674.not = icmp eq i64 %xtraiter672, 0
  br i1 %lcmp.mod674.not, label %Else26, label %Then26.epil.preheader

Then26.epil.preheader:                            ; preds = %Else26.unr-lcssa, %Then26.preheader
  %.epil.init = phi i32 [ %.pre616, %Then26.preheader ], [ %255, %Else26.unr-lcssa ]
  %.4595.epil.init = phi i64 [ 0, %Then26.preheader ], [ %253, %Else26.unr-lcssa ]
  %lcmp.mod675 = icmp ne i64 %xtraiter672, 0
  tail call void @llvm.assume(i1 %lcmp.mod675)
  %259 = lshr i32 %.epil.init, %71
  %260 = getelementptr inbounds nuw [4 x i8], ptr %4, i64 %.4595.epil.init
  %261 = getelementptr inbounds nuw i8, ptr %260, i64 4
  %262 = load i32, ptr %261, align 4
  %263 = shl i32 %262, %.pre-phi619
  %common.ret.op.i563.epil = select i1 %100, i32 %263, i32 0
  %264 = or i32 %common.ret.op.i563.epil, %259
  %265 = getelementptr inbounds nuw [4 x i8], ptr %0, i64 %.4595.epil.init
  store i32 %264, ptr %265, align 4
  br label %Else26

Else26:                                           ; preds = %Then26.epil.preheader, %Else26.unr-lcssa
  %266 = load i32, ptr %invariant.gep593, align 4
  %267 = lshr i32 %266, %71
  %268 = getelementptr inbounds nuw [4 x i8], ptr %0, i64 %.0540.lcssa.fr
  store i32 %267, ptr %268, align 4
  br label %Block18

Then29.preheader:                                 ; preds = %Block18
  store i1 true, ptr %.sroa.0528, align 1
  br label %Then29

Then29:                                           ; preds = %Then29, %Then29.preheader
  %.0596 = phi i64 [ %278, %Then29 ], [ 0, %Then29.preheader ]
  %269 = getelementptr inbounds nuw [4 x i8], ptr %0, i64 %.0596
  %270 = load i32, ptr %269, align 4
  %271 = xor i32 %270, -1
  %.sroa.0528.0..sroa.0528.0..sroa.0528.0..sroa.0528.0..sroa.0528.0. = load i8, ptr %.sroa.0528, align 1
  %272 = and i8 %.sroa.0528.0..sroa.0528.0..sroa.0528.0..sroa.0528.0..sroa.0528.0., 1
  %273 = zext nneg i8 %272 to i32
  %274 = tail call { i32, i1 } @llvm.uadd.with.overflow.i32(i32 %271, i32 %273)
  %275 = extractvalue { i32, i1 } %274, 0
  %276 = extractvalue { i32, i1 } %274, 1
  store i1 %276, ptr %.sroa.2532, align 4
  %.sroa.2532.0..sroa.2532.0..sroa.2532.0..sroa.2532.0..sroa.2532.4. = load i8, ptr %.sroa.2532, align 4
  %277 = trunc i8 %.sroa.2532.0..sroa.2532.0..sroa.2532.0..sroa.2532.0..sroa.2532.4. to i1
  store i1 %277, ptr %.sroa.0528, align 1
  store i32 %275, ptr %269, align 4
  %278 = add nuw nsw i64 %.0596, 1
  %exitcond613.not = icmp eq i64 %278, %10
  br i1 %exitcond613.not, label %Block1, label %Then29
}

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(inaccessiblemem: write)
declare void @llvm.assume(i1 noundef) #1

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(inaccessiblemem: write) uwtable
declare hidden fastcc range(i16 0, 8208) i16 @zig.target.intByteSize(i16) unnamed_addr #2 align 1

; Function Attrs: nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none)
declare { i32, i1 } @llvm.uadd.with.overflow.i32(i32, i32) #3

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.ctlz.i32(i32, i1 immarg) #4

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memcpy.inline.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #5

; Function Attrs: nofree norecurse nosync nounwind memory(readwrite, inaccessiblemem: write, target_mem0: none, target_mem1: none) uwtable
define hidden void @compiler_rt.divmodei4.__modei5(ptr nonnull align 1 captures(address) %0, ptr nonnull readonly align 1 captures(none) %1, ptr nonnull readonly align 1 captures(none) %2, ptr nonnull align 1 captures(none) %3, i64 %4) unnamed_addr #6 align 1 {
Entry:
  %.sroa.2526 = alloca i8, align 4
  %.sroa.0522 = alloca i8, align 1
  %5 = alloca [2049 x i32], align 4
  %6 = alloca [2048 x i32], align 4
  %.sroa.293 = alloca i8, align 4
  %.sroa.089 = alloca i8, align 1
  %.sroa.275 = alloca i8, align 4
  %.sroa.072 = alloca i8, align 1
  %7 = icmp ult i64 %4, 65536
  tail call void @llvm.assume(i1 %7)
  %8 = trunc nuw i64 %4 to i16
  %9 = tail call fastcc i16 @zig.target.intByteSize(i16 %8) #7
  %10 = zext nneg i16 %9 to i64
  %11 = lshr exact i64 %10, 2
  %12 = getelementptr inbounds nuw [1 x i8], ptr %3, i64 %10
  %13 = add nsw i64 %11, -1
  %14 = getelementptr inbounds nuw [4 x i8], ptr %1, i64 %13
  %15 = load i32, ptr %14, align 4
  %16 = getelementptr inbounds nuw [4 x i8], ptr %2, i64 %13
  %17 = load i32, ptr %16, align 4
  %18 = icmp sgt i32 %15, -1
  br i1 %18, label %Block4, label %Then

Block1:                                           ; preds = %Then29, %Block18
  ret void

Block4:                                           ; preds = %Then1, %Entry
  %19 = icmp slt i32 %17, 0
  %.not599 = icmp eq i16 %9, 0
  br i1 %19, label %Then2, label %Block10

Block4.thread:                                    ; preds = %Then
  %20 = icmp slt i32 %17, 0
  br i1 %20, label %Block10.thread, label %Block19

Then:                                             ; preds = %Entry
  store i1 true, ptr %.sroa.072, align 1
  %.not598 = icmp eq i16 %9, 0
  br i1 %.not598, label %Block4.thread, label %Then1

Then1:                                            ; preds = %Then1, %Then
  %.0537576 = phi i64 [ %31, %Then1 ], [ 0, %Then ]
  %21 = getelementptr inbounds nuw [4 x i8], ptr %1, i64 %.0537576
  %22 = load i32, ptr %21, align 4
  %23 = xor i32 %22, -1
  %.sroa.072.0..sroa.072.0..sroa.072.0..sroa.072.0..sroa.072.0. = load i8, ptr %.sroa.072, align 1
  %24 = and i8 %.sroa.072.0..sroa.072.0..sroa.072.0..sroa.072.0..sroa.072.0., 1
  %25 = zext nneg i8 %24 to i32
  %26 = tail call { i32, i1 } @llvm.uadd.with.overflow.i32(i32 %23, i32 %25)
  %27 = extractvalue { i32, i1 } %26, 0
  %28 = extractvalue { i32, i1 } %26, 1
  store i1 %28, ptr %.sroa.275, align 4
  %.sroa.275.0..sroa.275.0..sroa.275.0..sroa.275.0..sroa.275.4. = load i8, ptr %.sroa.275, align 4
  %29 = trunc i8 %.sroa.275.0..sroa.275.0..sroa.275.0..sroa.275.0..sroa.275.4. to i1
  store i1 %29, ptr %.sroa.072, align 1
  %30 = getelementptr inbounds nuw [4 x i8], ptr %3, i64 %.0537576
  store i32 %27, ptr %30, align 4
  %31 = add nuw nsw i64 %.0537576, 1
  %exitcond.not = icmp eq i64 %31, %11
  br i1 %exitcond.not, label %Block4, label %Then1

Block10:                                          ; preds = %Block4
  %spec.select = select i1 %18, ptr %1, ptr %3
  br i1 %.not599, label %Block19, label %InlineMemsetBody.preheader

InlineMemsetBody.preheader:                       ; preds = %Block10.thread631, %Block10
  %spec.select636 = phi ptr [ %spec.select633, %Block10.thread631 ], [ %spec.select, %Block10 ]
  %.pn548635 = phi ptr [ %12, %Block10.thread631 ], [ %2, %Block10 ]
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
  store i1 true, ptr %.sroa.089, align 1
  br i1 %.not599, label %Block10.thread, label %Then3

Block10.thread:                                   ; preds = %Then2, %Block4.thread
  %spec.select627 = select i1 %18, ptr %1, ptr %3
  br label %Block19

Then3:                                            ; preds = %Then3, %Then2
  %.0536577 = phi i64 [ %50, %Then3 ], [ 0, %Then2 ]
  %40 = getelementptr inbounds nuw [4 x i8], ptr %2, i64 %.0536577
  %41 = load i32, ptr %40, align 4
  %42 = xor i32 %41, -1
  %.sroa.089.0..sroa.089.0..sroa.089.0..sroa.089.0..sroa.089.0. = load i8, ptr %.sroa.089, align 1
  %43 = and i8 %.sroa.089.0..sroa.089.0..sroa.089.0..sroa.089.0..sroa.089.0., 1
  %44 = zext nneg i8 %43 to i32
  %45 = tail call { i32, i1 } @llvm.uadd.with.overflow.i32(i32 %42, i32 %44)
  %46 = extractvalue { i32, i1 } %45, 0
  %47 = extractvalue { i32, i1 } %45, 1
  store i1 %47, ptr %.sroa.293, align 4
  %.sroa.293.0..sroa.293.0..sroa.293.0..sroa.293.0..sroa.293.4. = load i8, ptr %.sroa.293, align 4
  %48 = trunc i8 %.sroa.293.0..sroa.293.0..sroa.293.0..sroa.293.0..sroa.293.4. to i1
  store i1 %48, ptr %.sroa.089, align 1
  %49 = getelementptr inbounds nuw [4 x i8], ptr %12, i64 %.0536577
  store i32 %46, ptr %49, align 4
  %50 = add nuw nsw i64 %.0536577, 1
  %exitcond611.not = icmp eq i64 %50, %11
  br i1 %exitcond611.not, label %Block10.thread631, label %Then3

Block10.thread631:                                ; preds = %Then3
  %spec.select633 = select i1 %18, ptr %1, ptr %3
  br label %InlineMemsetBody.preheader

Block18:                                          ; preds = %Else26, %Then14, %Then9
  br i1 %18, label %Block1, label %Then29.preheader, !prof !4

Block19:                                          ; preds = %InlineMemsetBody, %Block10.thread, %InlineMemsetBody.prol.loopexit, %Block10, %Block4.thread
  %spec.select630 = phi ptr [ %spec.select627, %Block10.thread ], [ %3, %Block4.thread ], [ %spec.select, %Block10 ], [ %spec.select636, %InlineMemsetBody ], [ %spec.select636, %InlineMemsetBody.prol.loopexit ]
  %.pn548629 = phi ptr [ %12, %Block10.thread ], [ %2, %Block4.thread ], [ %2, %Block10 ], [ %.pn548635, %InlineMemsetBody ], [ %.pn548635, %InlineMemsetBody.prol.loopexit ]
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
  %.0535.in = phi i64 [ %11, %Block19 ], [ %.0535, %Then9 ]
  %.0535 = add i64 %.0535.in, -1
  %61 = getelementptr inbounds [4 x i8], ptr %spec.select630, i64 %.0535
  %62 = load i32, ptr %61, align 4
  %63 = icmp eq i32 %62, 0
  br i1 %63, label %Then9, label %Loop3.preheader

Loop3.preheader:                                  ; preds = %Loop2
  %64 = getelementptr inbounds [4 x i8], ptr %.pn548629, i64 %13
  %65 = load i32, ptr %64, align 4
  %66 = icmp eq i32 %65, 0
  br i1 %66, label %Then11, label %Else11

Then9:                                            ; preds = %Loop2
  %67 = icmp eq i64 %.0535, 0
  %indvar.next = add i64 %indvar, 1
  br i1 %67, label %Block18, label %Loop2

Then11:                                           ; preds = %Then11, %Loop3.preheader
  %.0534580 = phi i64 [ %.0534, %Then11 ], [ %13, %Loop3.preheader ]
  %68 = icmp ne i64 %.0534580, 0
  tail call void @llvm.assume(i1 %68)
  %.0534 = add i64 %.0534580, -1
  %69 = getelementptr inbounds [4 x i8], ptr %.pn548629, i64 %.0534
  %70 = load i32, ptr %69, align 4
  %71 = icmp eq i32 %70, 0
  br i1 %71, label %Then11, label %Else11

Else11:                                           ; preds = %Then11, %Loop3.preheader
  %.0534.in.lcssa = phi i64 [ %11, %Loop3.preheader ], [ %.0534580, %Then11 ]
  %.0534.lcssa = phi i64 [ %13, %Loop3.preheader ], [ %.0534, %Then11 ]
  %.lcssa = phi i32 [ %65, %Loop3.preheader ], [ %70, %Then11 ]
  %.0534.lcssa.fr = freeze i64 %.0534.lcssa
  %72 = icmp ugt i64 %.0534.lcssa.fr, %.0535
  br i1 %72, label %Then14, label %Else13

Else13:                                           ; preds = %Else11
  %73 = tail call range(i32 0, 33) i32 @llvm.ctlz.i32(i32 %.lcssa, i1 true)
  %74 = trunc nuw nsw i32 %73 to i6
  %.not549583 = icmp eq i64 %.0534.lcssa.fr, 0
  %.pre618 = sub nuw i6 -32, %74
  br i1 %.not549583, label %Else13.Else15_crit_edge, label %Then15.lr.ph

Else13.Else15_crit_edge:                          ; preds = %Else13
  %.pre619 = zext nneg i6 %.pre618 to i32
  br label %Else15

Then15.lr.ph:                                     ; preds = %Else13
  %75 = icmp sgt i6 %.pre618, -1
  %76 = zext nneg i6 %.pre618 to i32
  %.phi.trans.insert = getelementptr inbounds [4 x i8], ptr %.pn548629, i64 %.0534.lcssa.fr
  %.pre = load i32, ptr %.phi.trans.insert, align 4
  %xtraiter672 = and i64 %.0534.lcssa.fr, 1
  %lcmp.mod673.not = icmp eq i64 %xtraiter672, 0
  br i1 %lcmp.mod673.not, label %Then15.prol.loopexit, label %Then15.prol

Then15.prol:                                      ; preds = %Then15.lr.ph
  %77 = shl i32 %.pre, %73
  %78 = add nsw i64 %.0534.lcssa.fr, -1
  %79 = getelementptr inbounds [4 x i8], ptr %.pn548629, i64 %78
  %80 = load i32, ptr %79, align 4
  %81 = lshr i32 %80, %76
  %common.ret.op.i557.prol = select i1 %75, i32 %81, i32 0
  %82 = or i32 %common.ret.op.i557.prol, %77
  %83 = getelementptr inbounds [4 x i8], ptr %6, i64 %.0534.lcssa.fr
  store i32 %82, ptr %83, align 4
  br label %Then15.prol.loopexit

Then15.prol.loopexit:                             ; preds = %Then15.prol, %Then15.lr.ph
  %.unr675 = phi i32 [ %.pre, %Then15.lr.ph ], [ %80, %Then15.prol ]
  %.0532584.unr = phi i64 [ %.0534.lcssa.fr, %Then15.lr.ph ], [ %78, %Then15.prol ]
  %84 = icmp eq i64 %.0534.lcssa.fr, 1
  br i1 %84, label %Else15, label %Then15

Then14:                                           ; preds = %Else11
  tail call void @llvm.memcpy.inline.p0.p0.i64(ptr nonnull align 4 %0, ptr nonnull align 4 %spec.select630, i64 %10, i1 false)
  br label %Block18

Then15:                                           ; preds = %Then15, %Then15.prol.loopexit
  %85 = phi i32 [ %96, %Then15 ], [ %.unr675, %Then15.prol.loopexit ]
  %.0532584 = phi i64 [ %94, %Then15 ], [ %.0532584.unr, %Then15.prol.loopexit ]
  %86 = shl i32 %85, %73
  %87 = add i64 %.0532584, -1
  %88 = getelementptr inbounds [4 x i8], ptr %.pn548629, i64 %87
  %89 = load i32, ptr %88, align 4
  %90 = lshr i32 %89, %76
  %common.ret.op.i557 = select i1 %75, i32 %90, i32 0
  %91 = or i32 %common.ret.op.i557, %86
  %92 = getelementptr inbounds [4 x i8], ptr %6, i64 %.0532584
  store i32 %91, ptr %92, align 4
  %93 = shl i32 %89, %73
  %94 = add i64 %.0532584, -2
  %95 = getelementptr inbounds [4 x i8], ptr %.pn548629, i64 %94
  %96 = load i32, ptr %95, align 4
  %97 = lshr i32 %96, %76
  %common.ret.op.i557.1 = select i1 %75, i32 %97, i32 0
  %98 = or i32 %common.ret.op.i557.1, %93
  %99 = getelementptr inbounds [4 x i8], ptr %6, i64 %87
  store i32 %98, ptr %99, align 4
  %.not549.1 = icmp eq i64 %94, 0
  br i1 %.not549.1, label %Else15, label %Then15

Else15:                                           ; preds = %Then15, %Then15.prol.loopexit, %Else13.Else15_crit_edge
  %.pre-phi620 = phi i32 [ %.pre619, %Else13.Else15_crit_edge ], [ %76, %Then15 ], [ %76, %Then15.prol.loopexit ]
  %100 = load i32, ptr %.pn548629, align 4
  %101 = shl i32 %100, %73
  store i32 %101, ptr %6, align 4
  %102 = icmp sgt i6 %.pre618, -1
  %103 = lshr i32 %62, %.pre-phi620
  %common.ret.op.i559 = select i1 %102, i32 %103, i32 0
  %104 = getelementptr [4 x i8], ptr %5, i64 %.0535
  %105 = getelementptr i8, ptr %104, i64 4
  store i32 %common.ret.op.i559, ptr %105, align 4
  %.not550585 = icmp eq i64 %.0535, 0
  br i1 %.not550585, label %Else16, label %Then16.preheader

Then16.preheader:                                 ; preds = %Else15
  %106 = add nsw i64 %11, -2
  %xtraiter677 = and i64 %.0535, 1
  %lcmp.mod678.not = icmp eq i64 %xtraiter677, 0
  br i1 %lcmp.mod678.not, label %Then16.prol.loopexit, label %Then16.prol

Then16.prol:                                      ; preds = %Then16.preheader
  %107 = shl i32 %62, %73
  %108 = add i64 %.0535.in, -2
  %109 = getelementptr inbounds [4 x i8], ptr %spec.select630, i64 %108
  %110 = load i32, ptr %109, align 4
  %111 = lshr i32 %110, %.pre-phi620
  %common.ret.op.i561.prol = select i1 %102, i32 %111, i32 0
  %112 = or i32 %common.ret.op.i561.prol, %107
  %113 = getelementptr inbounds [4 x i8], ptr %5, i64 %.0535
  store i32 %112, ptr %113, align 4
  br label %Then16.prol.loopexit

Then16.prol.loopexit:                             ; preds = %Then16.prol, %Then16.preheader
  %.unr680 = phi i32 [ %62, %Then16.preheader ], [ %110, %Then16.prol ]
  %.1533586.unr = phi i64 [ %.0535, %Then16.preheader ], [ %108, %Then16.prol ]
  %114 = icmp eq i64 %106, %indvar
  br i1 %114, label %Else16, label %Then16

Then16:                                           ; preds = %Then16, %Then16.prol.loopexit
  %115 = phi i32 [ %126, %Then16 ], [ %.unr680, %Then16.prol.loopexit ]
  %.1533586 = phi i64 [ %124, %Then16 ], [ %.1533586.unr, %Then16.prol.loopexit ]
  %116 = shl i32 %115, %73
  %117 = add i64 %.1533586, -1
  %118 = getelementptr inbounds [4 x i8], ptr %spec.select630, i64 %117
  %119 = load i32, ptr %118, align 4
  %120 = lshr i32 %119, %.pre-phi620
  %common.ret.op.i561 = select i1 %102, i32 %120, i32 0
  %121 = or i32 %common.ret.op.i561, %116
  %122 = getelementptr inbounds [4 x i8], ptr %5, i64 %.1533586
  store i32 %121, ptr %122, align 4
  %123 = shl i32 %119, %73
  %124 = add i64 %.1533586, -2
  %125 = getelementptr inbounds [4 x i8], ptr %spec.select630, i64 %124
  %126 = load i32, ptr %125, align 4
  %127 = lshr i32 %126, %.pre-phi620
  %common.ret.op.i561.1 = select i1 %102, i32 %127, i32 0
  %128 = or i32 %common.ret.op.i561.1, %123
  %129 = getelementptr inbounds [4 x i8], ptr %5, i64 %117
  store i32 %128, ptr %129, align 4
  %.not550.1 = icmp eq i64 %124, 0
  br i1 %.not550.1, label %Else16, label %Then16

Else16:                                           ; preds = %Then16, %Then16.prol.loopexit, %Else15
  %130 = load i32, ptr %spec.select630, align 4
  %131 = shl i32 %130, %73
  store i32 %131, ptr %5, align 4
  %132 = sub i64 %.0535.in, %.0534.in.lcssa
  %invariant.gep594 = getelementptr [4 x i8], ptr %5, i64 %.0534.lcssa.fr
  %133 = getelementptr inbounds [4 x i8], ptr %6, i64 %.0534.lcssa.fr
  %134 = load i32, ptr %133, align 4
  %135 = zext i32 %134 to i64
  %136 = getelementptr i8, ptr %133, i64 -4
  %137 = add i64 %.0534.lcssa.fr, 1
  %xtraiter681 = and i64 %137, 1
  %138 = icmp eq i64 %.0534.lcssa.fr, 0
  %unroll_iter = and i64 %137, -2
  %lcmp.mod682.not = icmp eq i64 %xtraiter681, 0
  %lcmp.mod684 = icmp ne i64 %xtraiter681, 0
  %xtraiter685 = and i64 %137, 1
  %139 = icmp eq i64 %.0534.lcssa.fr, 0
  %unroll_iter689 = and i64 %137, -2
  %lcmp.mod686.not = icmp eq i64 %xtraiter685, 0
  %lcmp.mod688 = icmp ne i64 %xtraiter685, 0
  br label %Loop6

Loop6:                                            ; preds = %Block72, %Else16
  %.0531 = phi i64 [ %132, %Else16 ], [ %213, %Block72 ]
  %gep595 = getelementptr [4 x i8], ptr %invariant.gep594, i64 %.0531
  %140 = getelementptr i8, ptr %gep595, i64 4
  %141 = load i32, ptr %140, align 4
  %142 = zext i32 %141 to i64
  %143 = shl nuw i64 %142, 32
  %144 = load i32, ptr %gep595, align 4
  %145 = zext i32 %144 to i64
  %146 = or disjoint i64 %143, %145
  %147 = udiv i64 %146, %135
  %148 = urem i64 %146, %135
  %149 = getelementptr i8, ptr %gep595, i64 -4
  br i1 %.not549583, label %Loop7.us, label %Loop7

Loop7.us:                                         ; preds = %Then19.us, %Loop6
  %.0530.us = phi i64 [ %151, %Then19.us ], [ %147, %Loop6 ]
  %.0529.us = phi i64 [ %152, %Then19.us ], [ %148, %Loop6 ]
  %150 = icmp ugt i64 %.0530.us, 4294967295
  br i1 %150, label %Then19.us, label %Block57

Then19.us:                                        ; preds = %Loop7.us
  %151 = add i64 %.0530.us, -1
  %152 = add nuw nsw i64 %.0529.us, %135
  %153 = icmp samesign ult i64 %152, 4294967296
  br i1 %153, label %Loop7.us, label %Block57

Loop7:                                            ; preds = %Then19, %Loop6
  %.0530 = phi i64 [ %163, %Then19 ], [ %147, %Loop6 ]
  %.0529 = phi i64 [ %164, %Then19 ], [ %148, %Loop6 ]
  %154 = icmp ugt i64 %.0530, 4294967295
  br i1 %154, label %Then19, label %Else17

Block57:                                          ; preds = %Then19, %Else17, %Then19.us, %Loop7.us
  %.us-phi = phi i64 [ %151, %Then19.us ], [ %.0530.us, %Loop7.us ], [ %163, %Then19 ], [ %.0530, %Else17 ]
  %invariant.gep = getelementptr [4 x i8], ptr %5, i64 %.0531
  br i1 %138, label %Then21.epil.preheader, label %Then21

Else17:                                           ; preds = %Loop7
  %155 = load i32, ptr %136, align 4
  %156 = zext i32 %155 to i64
  %157 = mul nuw i64 %.0530, %156
  %158 = shl nuw i64 %.0529, 32
  %159 = load i32, ptr %149, align 4
  %160 = zext i32 %159 to i64
  %161 = or disjoint i64 %158, %160
  %162 = icmp ugt i64 %157, %161
  br i1 %162, label %Then19, label %Block57

Then19:                                           ; preds = %Else17, %Loop7
  %163 = add i64 %.0530, -1
  %164 = add nuw nsw i64 %.0529, %135
  %165 = icmp samesign ult i64 %164, 4294967296
  br i1 %165, label %Loop7, label %Block57

Then21:                                           ; preds = %Then21, %Block57
  %.0528589 = phi i64 [ %192, %Then21 ], [ 0, %Block57 ]
  %.2588 = phi i64 [ %193, %Then21 ], [ 0, %Block57 ]
  %niter = phi i64 [ %niter.next.1, %Then21 ], [ 0, %Block57 ]
  %166 = getelementptr inbounds [4 x i8], ptr %6, i64 %.2588
  %167 = load i32, ptr %166, align 4
  %168 = zext i32 %167 to i64
  %169 = mul nuw i64 %.us-phi, %168
  %gep = getelementptr [4 x i8], ptr %invariant.gep, i64 %.2588
  %170 = load i32, ptr %gep, align 4
  %171 = zext i32 %170 to i64
  %172 = and i64 %169, 4294967295
  %173 = add nuw nsw i64 %.0528589, %172
  %174 = sub nsw i64 %171, %173
  %175 = trunc i64 %174 to i32
  store i32 %175, ptr %gep, align 4
  %176 = lshr i64 %169, 32
  %177 = ashr i64 %174, 32
  %178 = sub nsw i64 %176, %177
  %179 = or disjoint i64 %.2588, 1
  %180 = getelementptr inbounds [4 x i8], ptr %6, i64 %179
  %181 = load i32, ptr %180, align 4
  %182 = zext i32 %181 to i64
  %183 = mul nuw i64 %.us-phi, %182
  %gep.1 = getelementptr [4 x i8], ptr %invariant.gep, i64 %179
  %184 = load i32, ptr %gep.1, align 4
  %185 = zext i32 %184 to i64
  %186 = and i64 %183, 4294967295
  %187 = add nuw nsw i64 %178, %186
  %188 = sub nsw i64 %185, %187
  %189 = trunc i64 %188 to i32
  store i32 %189, ptr %gep.1, align 4
  %190 = lshr i64 %183, 32
  %191 = ashr i64 %188, 32
  %192 = sub nsw i64 %190, %191
  %193 = add i64 %.2588, 2
  %niter.next.1 = add i64 %niter, 2
  %niter.ncmp.1 = icmp eq i64 %niter.next.1, %unroll_iter
  br i1 %niter.ncmp.1, label %Else21.unr-lcssa, label %Then21

Else21.unr-lcssa:                                 ; preds = %Then21
  br i1 %lcmp.mod682.not, label %Else21, label %Then21.epil.preheader

Then21.epil.preheader:                            ; preds = %Else21.unr-lcssa, %Block57
  %.0528589.epil.init = phi i64 [ 0, %Block57 ], [ %192, %Else21.unr-lcssa ]
  %.2588.epil.init = phi i64 [ 0, %Block57 ], [ %193, %Else21.unr-lcssa ]
  tail call void @llvm.assume(i1 %lcmp.mod684)
  %194 = getelementptr inbounds [4 x i8], ptr %6, i64 %.2588.epil.init
  %195 = load i32, ptr %194, align 4
  %196 = zext i32 %195 to i64
  %197 = mul nuw i64 %.us-phi, %196
  %gep.epil = getelementptr [4 x i8], ptr %invariant.gep, i64 %.2588.epil.init
  %198 = load i32, ptr %gep.epil, align 4
  %199 = zext i32 %198 to i64
  %200 = and i64 %197, 4294967295
  %201 = add nuw nsw i64 %.0528589.epil.init, %200
  %202 = sub nsw i64 %199, %201
  %203 = trunc i64 %202 to i32
  store i32 %203, ptr %gep.epil, align 4
  %204 = lshr i64 %197, 32
  %205 = ashr i64 %202, 32
  %206 = sub nsw i64 %204, %205
  br label %Else21

Else21:                                           ; preds = %Then21.epil.preheader, %Else21.unr-lcssa
  %.lcssa664 = phi i64 [ %192, %Else21.unr-lcssa ], [ %206, %Then21.epil.preheader ]
  %207 = load i32, ptr %140, align 4
  %208 = zext i32 %207 to i64
  %209 = sub nsw i64 %208, %.lcssa664
  %210 = trunc i64 %209 to i32
  store i32 %210, ptr %140, align 4
  %211 = icmp slt i64 %209, 0
  br i1 %211, label %Then23.preheader, label %Block72

Then23.preheader:                                 ; preds = %Else21
  br i1 %139, label %Then23.epil.preheader, label %Then23

Block72:                                          ; preds = %Else23, %Else21
  %212 = icmp eq i64 %.0531, 0
  %213 = add i64 %.0531, -1
  br i1 %212, label %Then26.preheader, label %Loop6

Then26.preheader:                                 ; preds = %Block72
  %.pre617 = load i32, ptr %5, align 4
  %xtraiter691 = and i64 %137, 1
  %214 = icmp eq i64 %.0534.lcssa.fr, 0
  br i1 %214, label %Then26.epil.preheader, label %Then26.preheader.new

Then26.preheader.new:                             ; preds = %Then26.preheader
  %unroll_iter695 = and i64 %137, -2
  br label %Then26

Then23:                                           ; preds = %Then23, %Then23.preheader
  %.0527593 = phi i64 [ %233, %Then23 ], [ 0, %Then23.preheader ]
  %.3592 = phi i64 [ %234, %Then23 ], [ 0, %Then23.preheader ]
  %niter690 = phi i64 [ %niter690.next.1, %Then23 ], [ 0, %Then23.preheader ]
  %gep591 = getelementptr [4 x i8], ptr %invariant.gep, i64 %.3592
  %215 = load i32, ptr %gep591, align 4
  %216 = zext i32 %215 to i64
  %217 = getelementptr inbounds [4 x i8], ptr %6, i64 %.3592
  %218 = load i32, ptr %217, align 4
  %219 = zext i32 %218 to i64
  %220 = add nuw nsw i64 %.0527593, %216
  %221 = add nuw nsw i64 %220, %219
  %222 = trunc i64 %221 to i32
  store i32 %222, ptr %gep591, align 4
  %223 = lshr i64 %221, 32
  %224 = or disjoint i64 %.3592, 1
  %gep591.1 = getelementptr [4 x i8], ptr %invariant.gep, i64 %224
  %225 = load i32, ptr %gep591.1, align 4
  %226 = zext i32 %225 to i64
  %227 = getelementptr inbounds [4 x i8], ptr %6, i64 %224
  %228 = load i32, ptr %227, align 4
  %229 = zext i32 %228 to i64
  %230 = add nuw nsw i64 %223, %226
  %231 = add nuw nsw i64 %230, %229
  %232 = trunc i64 %231 to i32
  store i32 %232, ptr %gep591.1, align 4
  %233 = lshr i64 %231, 32
  %234 = add i64 %.3592, 2
  %niter690.next.1 = add i64 %niter690, 2
  %niter690.ncmp.1 = icmp eq i64 %niter690.next.1, %unroll_iter689
  br i1 %niter690.ncmp.1, label %Else23.unr-lcssa, label %Then23

Else23.unr-lcssa:                                 ; preds = %Then23
  br i1 %lcmp.mod686.not, label %Else23, label %Then23.epil.preheader

Then23.epil.preheader:                            ; preds = %Else23.unr-lcssa, %Then23.preheader
  %.0527593.epil.init = phi i64 [ 0, %Then23.preheader ], [ %233, %Else23.unr-lcssa ]
  %.3592.epil.init = phi i64 [ 0, %Then23.preheader ], [ %234, %Else23.unr-lcssa ]
  tail call void @llvm.assume(i1 %lcmp.mod688)
  %gep591.epil = getelementptr [4 x i8], ptr %invariant.gep, i64 %.3592.epil.init
  %235 = load i32, ptr %gep591.epil, align 4
  %236 = zext i32 %235 to i64
  %237 = getelementptr inbounds [4 x i8], ptr %6, i64 %.3592.epil.init
  %238 = load i32, ptr %237, align 4
  %239 = zext i32 %238 to i64
  %240 = add nuw nsw i64 %.0527593.epil.init, %236
  %241 = add nuw nsw i64 %240, %239
  %242 = trunc i64 %241 to i32
  store i32 %242, ptr %gep591.epil, align 4
  %243 = lshr i64 %241, 32
  br label %Else23

Else23:                                           ; preds = %Then23.epil.preheader, %Else23.unr-lcssa
  %.lcssa665 = phi i64 [ %233, %Else23.unr-lcssa ], [ %243, %Then23.epil.preheader ]
  %244 = load i32, ptr %140, align 4
  %245 = trunc nuw nsw i64 %.lcssa665 to i32
  %246 = add i32 %244, %245
  store i32 %246, ptr %140, align 4
  br label %Block72

Then26:                                           ; preds = %Then26, %Then26.preheader.new
  %247 = phi i32 [ %.pre617, %Then26.preheader.new ], [ %258, %Then26 ]
  %.4596 = phi i64 [ 0, %Then26.preheader.new ], [ %256, %Then26 ]
  %niter696 = phi i64 [ 0, %Then26.preheader.new ], [ %niter696.next.1, %Then26 ]
  %248 = lshr i32 %247, %73
  %249 = or disjoint i64 %.4596, 1
  %250 = getelementptr inbounds [4 x i8], ptr %5, i64 %249
  %251 = load i32, ptr %250, align 4
  %252 = shl i32 %251, %.pre-phi620
  %common.ret.op.i564 = select i1 %102, i32 %252, i32 0
  %253 = or i32 %common.ret.op.i564, %248
  %254 = getelementptr inbounds [4 x i8], ptr %0, i64 %.4596
  store i32 %253, ptr %254, align 4
  %255 = lshr i32 %251, %73
  %256 = add nuw i64 %.4596, 2
  %257 = getelementptr inbounds [4 x i8], ptr %5, i64 %256
  %258 = load i32, ptr %257, align 4
  %259 = shl i32 %258, %.pre-phi620
  %common.ret.op.i564.1 = select i1 %102, i32 %259, i32 0
  %260 = or i32 %common.ret.op.i564.1, %255
  %261 = getelementptr inbounds [4 x i8], ptr %0, i64 %249
  store i32 %260, ptr %261, align 4
  %niter696.next.1 = add i64 %niter696, 2
  %niter696.ncmp.1 = icmp eq i64 %niter696.next.1, %unroll_iter695
  br i1 %niter696.ncmp.1, label %Else26.unr-lcssa, label %Then26

Else26.unr-lcssa:                                 ; preds = %Then26
  %lcmp.mod693.not = icmp eq i64 %xtraiter691, 0
  br i1 %lcmp.mod693.not, label %Else26, label %Then26.epil.preheader

Then26.epil.preheader:                            ; preds = %Else26.unr-lcssa, %Then26.preheader
  %.epil.init = phi i32 [ %.pre617, %Then26.preheader ], [ %258, %Else26.unr-lcssa ]
  %.4596.epil.init = phi i64 [ 0, %Then26.preheader ], [ %256, %Else26.unr-lcssa ]
  %lcmp.mod694 = icmp ne i64 %xtraiter691, 0
  tail call void @llvm.assume(i1 %lcmp.mod694)
  %262 = lshr i32 %.epil.init, %73
  %263 = getelementptr [4 x i8], ptr %5, i64 %.4596.epil.init
  %264 = getelementptr i8, ptr %263, i64 4
  %265 = load i32, ptr %264, align 4
  %266 = shl i32 %265, %.pre-phi620
  %common.ret.op.i564.epil = select i1 %102, i32 %266, i32 0
  %267 = or i32 %common.ret.op.i564.epil, %262
  %268 = getelementptr inbounds [4 x i8], ptr %0, i64 %.4596.epil.init
  store i32 %267, ptr %268, align 4
  br label %Else26

Else26:                                           ; preds = %Then26.epil.preheader, %Else26.unr-lcssa
  %269 = load i32, ptr %invariant.gep594, align 4
  %270 = lshr i32 %269, %73
  %271 = getelementptr inbounds [4 x i8], ptr %0, i64 %.0534.lcssa.fr
  store i32 %270, ptr %271, align 4
  br label %Block18

Then29.preheader:                                 ; preds = %Block18
  store i1 true, ptr %.sroa.0522, align 1
  br label %Then29

Then29:                                           ; preds = %Then29, %Then29.preheader
  %.0597 = phi i64 [ %281, %Then29 ], [ 0, %Then29.preheader ]
  %272 = getelementptr inbounds nuw [4 x i8], ptr %0, i64 %.0597
  %273 = load i32, ptr %272, align 4
  %274 = xor i32 %273, -1
  %.sroa.0522.0..sroa.0522.0..sroa.0522.0..sroa.0522.0..sroa.0522.0. = load i8, ptr %.sroa.0522, align 1
  %275 = and i8 %.sroa.0522.0..sroa.0522.0..sroa.0522.0..sroa.0522.0..sroa.0522.0., 1
  %276 = zext nneg i8 %275 to i32
  %277 = tail call { i32, i1 } @llvm.uadd.with.overflow.i32(i32 %274, i32 %276)
  %278 = extractvalue { i32, i1 } %277, 0
  %279 = extractvalue { i32, i1 } %277, 1
  store i1 %279, ptr %.sroa.2526, align 4
  %.sroa.2526.0..sroa.2526.0..sroa.2526.0..sroa.2526.0..sroa.2526.4. = load i8, ptr %.sroa.2526, align 4
  %280 = trunc i8 %.sroa.2526.0..sroa.2526.0..sroa.2526.0..sroa.2526.0..sroa.2526.4. to i1
  store i1 %280, ptr %.sroa.0522, align 1
  store i32 %278, ptr %272, align 4
  %281 = add nuw nsw i64 %.0597, 1
  %exitcond616.not = icmp eq i64 %281, %11
  br i1 %exitcond616.not, label %Block1, label %Then29
}

attributes #0 = { nofree norecurse nosync nounwind memory(argmem: readwrite, inaccessiblemem: write) uwtable "frame-pointer"="all" "no-builtins" "target-cpu"="x86-64" "target-features"="+64bit,+cmov,+cx8,+fxsr,+idivq-to-divl,+macrofusion,+mmx,+nopl,+slow-3ops-lea,+slow-incdec,+sse,+sse2,+vzeroupper,+x87,-16bit-mode,-32bit-mode,-adx,-aes,-allow-light-256-bit,-amx-avx512,-amx-bf16,-amx-complex,-amx-fp16,-amx-fp8,-amx-int8,-amx-movrs,-amx-tf32,-amx-tile,-avx,-avx10.1,-avx10.2,-avx2,-avx512bf16,-avx512bitalg,-avx512bw,-avx512cd,-avx512dq,-avx512f,-avx512fp16,-avx512ifma,-avx512vbmi,-avx512vbmi2,-avx512vl,-avx512vnni,-avx512vp2intersect,-avx512vpopcntdq,-avxifma,-avxneconvert,-avxvnni,-avxvnniint16,-avxvnniint8,-bmi,-bmi2,-branch-hint,-branchfusion,-ccmp,-cf,-cldemote,-clflushopt,-clwb,-clzero,-cmpccxadd,-crc32,-cx16,-egpr,-enqcmd,-ermsb,-f16c,-false-deps-getmant,-false-deps-lzcnt-tzcnt,-false-deps-mulc,-false-deps-mullq,-false-deps-perm,-false-deps-popcnt,-false-deps-range,-fast-11bytenop,-fast-15bytenop,-fast-7bytenop,-fast-bextr,-fast-dpwssd,-fast-gather,-fast-hops,-fast-imm16,-fast-lzcnt,-fast-movbe,-fast-scalar-fsqrt,-fast-scalar-shift-masks,-fast-shld-rotate,-fast-variable-crosslane-shuffle,-fast-variable-perlane-shuffle,-fast-vector-fsqrt,-fast-vector-shift-masks,-faster-shift-than-shuffle,-fma,-fma4,-fsgsbase,-fsrm,-gfni,-harden-sls-ijmp,-harden-sls-ret,-hreset,-idivl-to-divb,-inline-asm-use-gpr32,-invpcid,-kl,-lea-sp,-lea-uses-ag,-lvi-cfi,-lvi-load-hardening,-lwp,-lzcnt,-movbe,-movdir64b,-movdiri,-movrs,-mwaitx,-ndd,-nf,-no-bypass-delay,-no-bypass-delay-blend,-no-bypass-delay-mov,-no-bypass-delay-shuffle,-pad-short-functions,-pclmul,-pconfig,-pku,-popcnt,-ppx,-prefer-128-bit,-prefer-256-bit,-prefer-legacy-setcc,-prefer-mask-registers,-prefer-movmsk-over-vtest,-prefer-no-gather,-prefer-no-scatter,-prefetchi,-prfchw,-ptwrite,-push2pop2,-raoint,-rdpid,-rdpru,-rdrnd,-rdseed,-retpoline,-retpoline-external-thunk,-retpoline-indirect-branches,-retpoline-indirect-calls,-rtm,-sahf,-sbb-dep-breaking,-serialize,-seses,-sgx,-sha,-sha512,-shstk,-slow-lea,-slow-pmaddwd,-slow-pmulld,-slow-pmullq,-slow-shld,-slow-two-mem-ops,-slow-unaligned-mem-16,-slow-unaligned-mem-32,-sm3,-sm4,-soft-float,-sse3,-sse4.1,-sse4.2,-sse4a,-sse-unaligned-mem,-ssse3,-tagged-globals,-tbm,-tsxldtrk,-tuning-fast-imm-vector-shift,-uintr,-use-glm-div-sqrt-costs,-use-slm-arith-costs,-usermsr,-vaes,-vpclmulqdq,-waitpkg,-wbnoinvd,-widekl,-xop,-xsave,-xsavec,-xsaveopt,-xsaves,-zu" }
attributes #1 = { nocallback nofree nosync nounwind willreturn memory(inaccessiblemem: write) }
attributes #2 = { mustprogress nofree norecurse nosync nounwind willreturn memory(inaccessiblemem: write) uwtable "frame-pointer"="all" "no-builtins" "target-cpu"="x86-64" "target-features"="+64bit,+cmov,+cx8,+fxsr,+idivq-to-divl,+macrofusion,+mmx,+nopl,+slow-3ops-lea,+slow-incdec,+sse,+sse2,+vzeroupper,+x87,-16bit-mode,-32bit-mode,-adx,-aes,-allow-light-256-bit,-amx-avx512,-amx-bf16,-amx-complex,-amx-fp16,-amx-fp8,-amx-int8,-amx-movrs,-amx-tf32,-amx-tile,-avx,-avx10.1,-avx10.2,-avx2,-avx512bf16,-avx512bitalg,-avx512bw,-avx512cd,-avx512dq,-avx512f,-avx512fp16,-avx512ifma,-avx512vbmi,-avx512vbmi2,-avx512vl,-avx512vnni,-avx512vp2intersect,-avx512vpopcntdq,-avxifma,-avxneconvert,-avxvnni,-avxvnniint16,-avxvnniint8,-bmi,-bmi2,-branch-hint,-branchfusion,-ccmp,-cf,-cldemote,-clflushopt,-clwb,-clzero,-cmpccxadd,-crc32,-cx16,-egpr,-enqcmd,-ermsb,-f16c,-false-deps-getmant,-false-deps-lzcnt-tzcnt,-false-deps-mulc,-false-deps-mullq,-false-deps-perm,-false-deps-popcnt,-false-deps-range,-fast-11bytenop,-fast-15bytenop,-fast-7bytenop,-fast-bextr,-fast-dpwssd,-fast-gather,-fast-hops,-fast-imm16,-fast-lzcnt,-fast-movbe,-fast-scalar-fsqrt,-fast-scalar-shift-masks,-fast-shld-rotate,-fast-variable-crosslane-shuffle,-fast-variable-perlane-shuffle,-fast-vector-fsqrt,-fast-vector-shift-masks,-faster-shift-than-shuffle,-fma,-fma4,-fsgsbase,-fsrm,-gfni,-harden-sls-ijmp,-harden-sls-ret,-hreset,-idivl-to-divb,-inline-asm-use-gpr32,-invpcid,-kl,-lea-sp,-lea-uses-ag,-lvi-cfi,-lvi-load-hardening,-lwp,-lzcnt,-movbe,-movdir64b,-movdiri,-movrs,-mwaitx,-ndd,-nf,-no-bypass-delay,-no-bypass-delay-blend,-no-bypass-delay-mov,-no-bypass-delay-shuffle,-pad-short-functions,-pclmul,-pconfig,-pku,-popcnt,-ppx,-prefer-128-bit,-prefer-256-bit,-prefer-legacy-setcc,-prefer-mask-registers,-prefer-movmsk-over-vtest,-prefer-no-gather,-prefer-no-scatter,-prefetchi,-prfchw,-ptwrite,-push2pop2,-raoint,-rdpid,-rdpru,-rdrnd,-rdseed,-retpoline,-retpoline-external-thunk,-retpoline-indirect-branches,-retpoline-indirect-calls,-rtm,-sahf,-sbb-dep-breaking,-serialize,-seses,-sgx,-sha,-sha512,-shstk,-slow-lea,-slow-pmaddwd,-slow-pmulld,-slow-pmullq,-slow-shld,-slow-two-mem-ops,-slow-unaligned-mem-16,-slow-unaligned-mem-32,-sm3,-sm4,-soft-float,-sse3,-sse4.1,-sse4.2,-sse4a,-sse-unaligned-mem,-ssse3,-tagged-globals,-tbm,-tsxldtrk,-tuning-fast-imm-vector-shift,-uintr,-use-glm-div-sqrt-costs,-use-slm-arith-costs,-usermsr,-vaes,-vpclmulqdq,-waitpkg,-wbnoinvd,-widekl,-xop,-xsave,-xsavec,-xsaveopt,-xsaves,-zu" }
attributes #3 = { nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none) }
attributes #4 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #5 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
attributes #6 = { nofree norecurse nosync nounwind memory(readwrite, inaccessiblemem: write, target_mem0: none, target_mem1: none) uwtable "frame-pointer"="all" "no-builtins" "target-cpu"="x86-64" "target-features"="+64bit,+cmov,+cx8,+fxsr,+idivq-to-divl,+macrofusion,+mmx,+nopl,+slow-3ops-lea,+slow-incdec,+sse,+sse2,+vzeroupper,+x87,-16bit-mode,-32bit-mode,-adx,-aes,-allow-light-256-bit,-amx-avx512,-amx-bf16,-amx-complex,-amx-fp16,-amx-fp8,-amx-int8,-amx-movrs,-amx-tf32,-amx-tile,-avx,-avx10.1,-avx10.2,-avx2,-avx512bf16,-avx512bitalg,-avx512bw,-avx512cd,-avx512dq,-avx512f,-avx512fp16,-avx512ifma,-avx512vbmi,-avx512vbmi2,-avx512vl,-avx512vnni,-avx512vp2intersect,-avx512vpopcntdq,-avxifma,-avxneconvert,-avxvnni,-avxvnniint16,-avxvnniint8,-bmi,-bmi2,-branch-hint,-branchfusion,-ccmp,-cf,-cldemote,-clflushopt,-clwb,-clzero,-cmpccxadd,-crc32,-cx16,-egpr,-enqcmd,-ermsb,-f16c,-false-deps-getmant,-false-deps-lzcnt-tzcnt,-false-deps-mulc,-false-deps-mullq,-false-deps-perm,-false-deps-popcnt,-false-deps-range,-fast-11bytenop,-fast-15bytenop,-fast-7bytenop,-fast-bextr,-fast-dpwssd,-fast-gather,-fast-hops,-fast-imm16,-fast-lzcnt,-fast-movbe,-fast-scalar-fsqrt,-fast-scalar-shift-masks,-fast-shld-rotate,-fast-variable-crosslane-shuffle,-fast-variable-perlane-shuffle,-fast-vector-fsqrt,-fast-vector-shift-masks,-faster-shift-than-shuffle,-fma,-fma4,-fsgsbase,-fsrm,-gfni,-harden-sls-ijmp,-harden-sls-ret,-hreset,-idivl-to-divb,-inline-asm-use-gpr32,-invpcid,-kl,-lea-sp,-lea-uses-ag,-lvi-cfi,-lvi-load-hardening,-lwp,-lzcnt,-movbe,-movdir64b,-movdiri,-movrs,-mwaitx,-ndd,-nf,-no-bypass-delay,-no-bypass-delay-blend,-no-bypass-delay-mov,-no-bypass-delay-shuffle,-pad-short-functions,-pclmul,-pconfig,-pku,-popcnt,-ppx,-prefer-128-bit,-prefer-256-bit,-prefer-legacy-setcc,-prefer-mask-registers,-prefer-movmsk-over-vtest,-prefer-no-gather,-prefer-no-scatter,-prefetchi,-prfchw,-ptwrite,-push2pop2,-raoint,-rdpid,-rdpru,-rdrnd,-rdseed,-retpoline,-retpoline-external-thunk,-retpoline-indirect-branches,-retpoline-indirect-calls,-rtm,-sahf,-sbb-dep-breaking,-serialize,-seses,-sgx,-sha,-sha512,-shstk,-slow-lea,-slow-pmaddwd,-slow-pmulld,-slow-pmullq,-slow-shld,-slow-two-mem-ops,-slow-unaligned-mem-16,-slow-unaligned-mem-32,-sm3,-sm4,-soft-float,-sse3,-sse4.1,-sse4.2,-sse4a,-sse-unaligned-mem,-ssse3,-tagged-globals,-tbm,-tsxldtrk,-tuning-fast-imm-vector-shift,-uintr,-use-glm-div-sqrt-costs,-use-slm-arith-costs,-usermsr,-vaes,-vpclmulqdq,-waitpkg,-wbnoinvd,-widekl,-xop,-xsave,-xsavec,-xsaveopt,-xsaves,-zu" }
attributes #7 = { nobuiltin }

!llvm.module.flags = !{!0, !1}

!0 = !{i32 2, !"Debug Info Version", i32 3}
!1 = !{i32 7, !"Dwarf Version", i32 4}
!2 = distinct !{!2, !3}
!3 = !{!"llvm.loop.unroll.disable"}
!4 = !{!"branch_weights", i32 0, i32 -2147483648}
!5 = distinct !{!5, !3}
