; ModuleID = 'local-state/validations/compiler-behavior-completion-20261111/batch-01/abi-frame-research-v111/test/real_programs/limb_intrinsics_reference_v262.c'
source_filename = "local-state/validations/compiler-behavior-completion-20261111/batch-01/abi-frame-research-v111/test/real_programs/limb_intrinsics_reference_v262.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

; Function Attrs: nofree norecurse nosync nounwind memory(argmem: readwrite) uwtable
define dso_local noundef i64 @limb_intrinsics_140(ptr noundef captures(none) %0, ptr noundef readonly captures(none) %1, ptr noundef readonly captures(none) %2, ptr noundef readonly captures(none) %3, i64 noundef %4) local_unnamed_addr #0 {
  br label %15

6:                                                ; preds = %15
  %7 = tail call i140 @llvm.abs.i140(i140 %25, i1 false)
  %8 = zext i140 %7 to i192
  %9 = tail call range(i140 0, 141) i140 @llvm.ctpop.i140(i140 %25)
  %10 = zext nneg i140 %9 to i192
  %11 = tail call range(i140 0, 141) i140 @llvm.ctlz.i140(i140 %25, i1 false)
  %12 = zext nneg i140 %11 to i192
  %13 = tail call range(i140 0, 141) i140 @llvm.cttz.i140(i140 %25, i1 false)
  %14 = zext nneg i140 %13 to i192
  br label %132

15:                                               ; preds = %5, %15
  %16 = phi i64 [ 0, %5 ], [ %31, %15 ]
  %17 = phi i140 [ 0, %5 ], [ %25, %15 ]
  %18 = phi i140 [ 0, %5 ], [ %30, %15 ]
  %19 = getelementptr inbounds nuw i8, ptr %1, i64 %16
  %20 = load i8, ptr %19, align 1, !tbaa !9
  %21 = zext i8 %20 to i140
  %22 = shl nuw nsw i64 %16, 3
  %23 = zext nneg i64 %22 to i140
  %24 = shl i140 %21, %23
  %25 = or i140 %24, %17
  %26 = getelementptr inbounds nuw i8, ptr %2, i64 %16
  %27 = load i8, ptr %26, align 1, !tbaa !9
  %28 = zext i8 %27 to i140
  %29 = shl i140 %28, %23
  %30 = or i140 %29, %18
  %31 = add nuw nsw i64 %16, 1
  %32 = icmp eq i64 %31, 18
  br i1 %32, label %6, label %15, !llvm.loop !10

33:                                               ; preds = %132
  %34 = zext i140 %145 to i192
  %35 = tail call i140 @llvm.uadd.sat.i140(i140 %25, i140 %30)
  %36 = zext i140 %35 to i192
  %37 = tail call i140 @llvm.usub.sat.i140(i140 %25, i140 %30)
  %38 = zext i140 %37 to i192
  %39 = tail call i140 @llvm.sadd.sat.i140(i140 %25, i140 %30)
  %40 = zext i140 %39 to i192
  %41 = tail call i140 @llvm.ssub.sat.i140(i140 %25, i140 %30)
  %42 = zext i140 %41 to i192
  %43 = insertelement <16 x i192> poison, i192 %8, i64 0
  %44 = shufflevector <16 x i192> %43, <16 x i192> poison, <16 x i32> zeroinitializer
  %45 = lshr <16 x i192> %44, <i192 0, i192 8, i192 16, i192 24, i192 32, i192 40, i192 48, i192 56, i192 64, i192 72, i192 80, i192 88, i192 96, i192 104, i192 112, i192 120>
  %46 = trunc <16 x i192> %45 to <16 x i8>
  store <16 x i8> %46, ptr %0, align 1, !tbaa !9
  %47 = lshr i192 %8, 128
  %48 = trunc i192 %47 to i8
  %49 = getelementptr inbounds nuw i8, ptr %0, i64 16
  store i8 %48, ptr %49, align 1, !tbaa !9
  %50 = lshr i140 %7, 136
  %51 = trunc nuw nsw i140 %50 to i8
  %52 = getelementptr inbounds nuw i8, ptr %0, i64 17
  store i8 %51, ptr %52, align 1, !tbaa !9
  %53 = getelementptr inbounds nuw i8, ptr %0, i64 64
  %54 = insertelement <16 x i192> poison, i192 %10, i64 0
  %55 = shufflevector <16 x i192> %54, <16 x i192> poison, <16 x i32> zeroinitializer
  %56 = lshr <16 x i192> %55, <i192 0, i192 8, i192 16, i192 24, i192 32, i192 40, i192 48, i192 56, i192 64, i192 72, i192 80, i192 88, i192 96, i192 104, i192 112, i192 120>
  %57 = trunc nuw <16 x i192> %56 to <16 x i8>
  store <16 x i8> %57, ptr %53, align 1, !tbaa !9
  %58 = getelementptr inbounds nuw i8, ptr %0, i64 80
  store i8 0, ptr %58, align 1, !tbaa !9
  %59 = getelementptr inbounds nuw i8, ptr %0, i64 81
  store i8 0, ptr %59, align 1, !tbaa !9
  %60 = getelementptr inbounds nuw i8, ptr %0, i64 128
  %61 = insertelement <16 x i192> poison, i192 %12, i64 0
  %62 = shufflevector <16 x i192> %61, <16 x i192> poison, <16 x i32> zeroinitializer
  %63 = lshr <16 x i192> %62, <i192 0, i192 8, i192 16, i192 24, i192 32, i192 40, i192 48, i192 56, i192 64, i192 72, i192 80, i192 88, i192 96, i192 104, i192 112, i192 120>
  %64 = trunc nuw <16 x i192> %63 to <16 x i8>
  store <16 x i8> %64, ptr %60, align 1, !tbaa !9
  %65 = getelementptr inbounds nuw i8, ptr %0, i64 144
  store i8 0, ptr %65, align 1, !tbaa !9
  %66 = getelementptr inbounds nuw i8, ptr %0, i64 145
  store i8 0, ptr %66, align 1, !tbaa !9
  %67 = getelementptr inbounds nuw i8, ptr %0, i64 192
  %68 = insertelement <16 x i192> poison, i192 %14, i64 0
  %69 = shufflevector <16 x i192> %68, <16 x i192> poison, <16 x i32> zeroinitializer
  %70 = lshr <16 x i192> %69, <i192 0, i192 8, i192 16, i192 24, i192 32, i192 40, i192 48, i192 56, i192 64, i192 72, i192 80, i192 88, i192 96, i192 104, i192 112, i192 120>
  %71 = trunc nuw <16 x i192> %70 to <16 x i8>
  store <16 x i8> %71, ptr %67, align 1, !tbaa !9
  %72 = getelementptr inbounds nuw i8, ptr %0, i64 208
  store i8 0, ptr %72, align 1, !tbaa !9
  %73 = getelementptr inbounds nuw i8, ptr %0, i64 209
  store i8 0, ptr %73, align 1, !tbaa !9
  %74 = getelementptr inbounds nuw i8, ptr %0, i64 256
  %75 = insertelement <16 x i192> poison, i192 %34, i64 0
  %76 = shufflevector <16 x i192> %75, <16 x i192> poison, <16 x i32> zeroinitializer
  %77 = lshr <16 x i192> %76, <i192 0, i192 8, i192 16, i192 24, i192 32, i192 40, i192 48, i192 56, i192 64, i192 72, i192 80, i192 88, i192 96, i192 104, i192 112, i192 120>
  %78 = trunc <16 x i192> %77 to <16 x i8>
  store <16 x i8> %78, ptr %74, align 1, !tbaa !9
  %79 = lshr i192 %34, 128
  %80 = trunc i192 %79 to i8
  %81 = getelementptr inbounds nuw i8, ptr %0, i64 272
  store i8 %80, ptr %81, align 1, !tbaa !9
  %82 = lshr i140 %138, 136
  %83 = trunc nuw nsw i140 %82 to i8
  %84 = getelementptr inbounds nuw i8, ptr %0, i64 273
  store i8 %83, ptr %84, align 1, !tbaa !9
  %85 = getelementptr inbounds nuw i8, ptr %0, i64 384
  %86 = insertelement <16 x i192> poison, i192 %36, i64 0
  %87 = shufflevector <16 x i192> %86, <16 x i192> poison, <16 x i32> zeroinitializer
  %88 = lshr <16 x i192> %87, <i192 0, i192 8, i192 16, i192 24, i192 32, i192 40, i192 48, i192 56, i192 64, i192 72, i192 80, i192 88, i192 96, i192 104, i192 112, i192 120>
  %89 = trunc <16 x i192> %88 to <16 x i8>
  store <16 x i8> %89, ptr %85, align 1, !tbaa !9
  %90 = lshr i192 %36, 128
  %91 = trunc i192 %90 to i8
  %92 = getelementptr inbounds nuw i8, ptr %0, i64 400
  store i8 %91, ptr %92, align 1, !tbaa !9
  %93 = lshr i140 %35, 136
  %94 = trunc nuw nsw i140 %93 to i8
  %95 = getelementptr inbounds nuw i8, ptr %0, i64 401
  store i8 %94, ptr %95, align 1, !tbaa !9
  %96 = getelementptr inbounds nuw i8, ptr %0, i64 448
  %97 = insertelement <16 x i192> poison, i192 %38, i64 0
  %98 = shufflevector <16 x i192> %97, <16 x i192> poison, <16 x i32> zeroinitializer
  %99 = lshr <16 x i192> %98, <i192 0, i192 8, i192 16, i192 24, i192 32, i192 40, i192 48, i192 56, i192 64, i192 72, i192 80, i192 88, i192 96, i192 104, i192 112, i192 120>
  %100 = trunc <16 x i192> %99 to <16 x i8>
  store <16 x i8> %100, ptr %96, align 1, !tbaa !9
  %101 = lshr i192 %38, 128
  %102 = trunc i192 %101 to i8
  %103 = getelementptr inbounds nuw i8, ptr %0, i64 464
  store i8 %102, ptr %103, align 1, !tbaa !9
  %104 = lshr i140 %37, 136
  %105 = trunc nuw nsw i140 %104 to i8
  %106 = getelementptr inbounds nuw i8, ptr %0, i64 465
  store i8 %105, ptr %106, align 1, !tbaa !9
  %107 = getelementptr inbounds nuw i8, ptr %0, i64 512
  %108 = insertelement <16 x i192> poison, i192 %40, i64 0
  %109 = shufflevector <16 x i192> %108, <16 x i192> poison, <16 x i32> zeroinitializer
  %110 = lshr <16 x i192> %109, <i192 0, i192 8, i192 16, i192 24, i192 32, i192 40, i192 48, i192 56, i192 64, i192 72, i192 80, i192 88, i192 96, i192 104, i192 112, i192 120>
  %111 = trunc <16 x i192> %110 to <16 x i8>
  store <16 x i8> %111, ptr %107, align 1, !tbaa !9
  %112 = lshr i192 %40, 128
  %113 = trunc i192 %112 to i8
  %114 = getelementptr inbounds nuw i8, ptr %0, i64 528
  store i8 %113, ptr %114, align 1, !tbaa !9
  %115 = lshr i140 %39, 136
  %116 = trunc nuw nsw i140 %115 to i8
  %117 = getelementptr inbounds nuw i8, ptr %0, i64 529
  store i8 %116, ptr %117, align 1, !tbaa !9
  %118 = getelementptr inbounds nuw i8, ptr %0, i64 576
  %119 = insertelement <16 x i192> poison, i192 %42, i64 0
  %120 = shufflevector <16 x i192> %119, <16 x i192> poison, <16 x i32> zeroinitializer
  %121 = lshr <16 x i192> %120, <i192 0, i192 8, i192 16, i192 24, i192 32, i192 40, i192 48, i192 56, i192 64, i192 72, i192 80, i192 88, i192 96, i192 104, i192 112, i192 120>
  %122 = trunc <16 x i192> %121 to <16 x i8>
  store <16 x i8> %122, ptr %118, align 1, !tbaa !9
  %123 = lshr i192 %42, 128
  %124 = trunc i192 %123 to i8
  %125 = getelementptr inbounds nuw i8, ptr %0, i64 592
  store i8 %124, ptr %125, align 1, !tbaa !9
  %126 = lshr i140 %41, 136
  %127 = trunc nuw nsw i140 %126 to i8
  %128 = getelementptr inbounds nuw i8, ptr %0, i64 593
  store i8 %127, ptr %128, align 1, !tbaa !9
  %129 = getelementptr inbounds nuw i8, ptr %0, i64 640
  tail call fastcc void @funnel(ptr noundef nonnull %129, ptr noundef %1, ptr noundef %2, ptr noundef %3, i32 noundef 140, i32 noundef 1)
  %130 = getelementptr inbounds nuw i8, ptr %0, i64 704
  tail call fastcc void @funnel(ptr noundef nonnull %130, ptr noundef %1, ptr noundef %2, ptr noundef %3, i32 noundef 140, i32 noundef 0)
  %131 = xor i64 %4, 90
  ret i64 %131

132:                                              ; preds = %132, %6
  %133 = phi i140 [ 0, %6 ], [ %145, %132 ]
  %134 = phi i32 [ 0, %6 ], [ %146, %132 ]
  %135 = zext nneg i32 %134 to i140
  %136 = lshr i140 %25, %135
  %137 = or disjoint i32 %134, 1
  %138 = shl i140 %133, 2
  %139 = shl i140 %136, 1
  %140 = and i140 %139, 2
  %141 = zext nneg i32 %137 to i140
  %142 = lshr i140 %25, %141
  %143 = and i140 %142, 1
  %144 = or disjoint i140 %140, %143
  %145 = or disjoint i140 %144, %138
  %146 = add nuw nsw i32 %134, 2
  %147 = icmp eq i32 %146, 140
  br i1 %147, label %33, label %132, !llvm.loop !12
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(ptr captures(none)) #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(ptr captures(none)) #1

; Function Attrs: mustprogress nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none)
declare i140 @llvm.ctpop.i140(i140) #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i140 @llvm.ctlz.i140(i140, i1 immarg) #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i140 @llvm.cttz.i140(i140, i1 immarg) #3

; Function Attrs: nofree noinline norecurse nosync nounwind memory(argmem: readwrite) uwtable
define internal fastcc void @funnel(ptr noundef captures(none) %0, ptr noundef readonly captures(none) %1, ptr noundef readonly captures(none) %2, ptr noundef readonly captures(none) %3, i32 noundef range(i32 140, 496) %4, i32 noundef range(i32 0, 2) %5) unnamed_addr #4 {
  %7 = alloca [129 x i8], align 16
  %8 = add nuw nsw i32 %4, 7
  %9 = lshr i32 %8, 3
  %10 = add nuw nsw i32 %4, 7
  %11 = lshr i32 %10, 3
  %12 = icmp eq i32 %11, %9
  %13 = and i32 %4, 7
  %14 = icmp eq i32 %13, 0
  %15 = shl nsw i32 -1, %13
  %16 = xor i32 %15, -1
  %17 = select i1 %14, i32 255, i32 %16
  %18 = select i1 %12, i32 %17, i32 255
  %19 = zext nneg i32 %11 to i64
  %20 = add nsw i64 %19, -1
  %21 = getelementptr inbounds nuw i8, ptr %3, i64 %20
  %22 = load i8, ptr %21, align 1, !tbaa !9
  %23 = zext i8 %22 to i32
  %24 = and i32 %18, %23
  %25 = freeze i32 %24
  %26 = icmp ult i32 %25, %4
  %27 = select i1 %26, i32 0, i32 %4
  %28 = sub nuw i32 %25, %27
  %29 = and i64 %20, 1
  %30 = icmp eq i64 %29, 0
  br i1 %30, label %39, label %31

31:                                               ; preds = %6
  %32 = add nsw i64 %19, -2
  %33 = getelementptr inbounds nuw i8, ptr %3, i64 %32
  %34 = load i8, ptr %33, align 1, !tbaa !9
  %35 = zext i8 %34 to i32
  %36 = shl nuw nsw i32 %28, 8
  %37 = or disjoint i32 %36, %35
  %38 = urem i32 %37, %4
  br label %39

39:                                               ; preds = %31, %6
  %40 = phi i32 [ poison, %6 ], [ %38, %31 ]
  %41 = phi i64 [ %20, %6 ], [ %32, %31 ]
  %42 = phi i32 [ %28, %6 ], [ %38, %31 ]
  %43 = icmp eq i32 %11, 2
  br i1 %43, label %44, label %46

44:                                               ; preds = %46, %39
  %45 = phi i32 [ %40, %39 ], [ %62, %46 ]
  call void @llvm.lifetime.start.p0(ptr nonnull %7) #8
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(129) %7, i8 0, i64 129, i1 false)
  br label %154

46:                                               ; preds = %39, %46
  %47 = phi i64 [ %56, %46 ], [ %41, %39 ]
  %48 = phi i32 [ %62, %46 ], [ %42, %39 ]
  %49 = getelementptr i8, ptr %3, i64 %47
  %50 = getelementptr i8, ptr %49, i64 -1
  %51 = load i8, ptr %50, align 1, !tbaa !9
  %52 = zext i8 %51 to i32
  %53 = shl nuw nsw i32 %48, 8
  %54 = or disjoint i32 %53, %52
  %55 = urem i32 %54, %4
  %56 = add nsw i64 %47, -2
  %57 = getelementptr inbounds nuw i8, ptr %3, i64 %56
  %58 = load i8, ptr %57, align 1, !tbaa !9
  %59 = zext i8 %58 to i32
  %60 = shl nuw nsw i32 %55, 8
  %61 = or disjoint i32 %60, %59
  %62 = urem i32 %61, %4
  %63 = icmp eq i64 %56, 0
  br i1 %63, label %44, label %46, !llvm.loop !13

64:                                               ; preds = %154
  %65 = icmp eq i32 %5, 0
  %66 = sub nsw i32 %4, %45
  %67 = select i1 %65, i32 %45, i32 %66
  %68 = lshr i32 %67, 3
  %69 = trunc i32 %67 to i8
  %70 = zext nneg i32 %9 to i64
  %71 = trunc nuw i32 %68 to i29
  %72 = trunc nsw i64 %20 to i29
  %73 = xor i29 %71, -1
  %74 = icmp ult i29 %73, %72
  %75 = icmp ugt i64 %20, 536870911
  %76 = or i1 %74, %75
  br i1 %76, label %134, label %77

77:                                               ; preds = %64
  %78 = and i64 %19, 8
  %79 = and i64 %19, 112
  %80 = insertelement <16 x i8> poison, i8 %69, i64 0
  %81 = shufflevector <16 x i8> %80, <16 x i8> poison, <16 x i32> zeroinitializer
  %82 = zext nneg i32 %68 to i64
  %83 = getelementptr inbounds nuw i8, ptr %7, i64 %82
  %84 = load <16 x i8>, ptr %83, align 1, !tbaa !9
  %85 = getelementptr inbounds nuw i8, ptr %83, i64 1
  %86 = load <16 x i8>, ptr %85, align 1, !tbaa !9
  %87 = tail call <16 x i8> @llvm.fshr.v16i8(<16 x i8> %86, <16 x i8> %84, <16 x i8> %81)
  store <16 x i8> %87, ptr %0, align 1, !tbaa !9
  %88 = icmp eq i64 %79, 16
  br i1 %88, label %110, label %89, !llvm.loop !15

89:                                               ; preds = %77
  %90 = add nuw nsw i32 %68, 16
  %91 = and i32 %90, 536870911
  %92 = zext nneg i32 %91 to i64
  %93 = getelementptr inbounds nuw i8, ptr %7, i64 %92
  %94 = load <16 x i8>, ptr %93, align 1, !tbaa !9
  %95 = getelementptr inbounds nuw i8, ptr %93, i64 1
  %96 = load <16 x i8>, ptr %95, align 1, !tbaa !9
  %97 = tail call <16 x i8> @llvm.fshr.v16i8(<16 x i8> %96, <16 x i8> %94, <16 x i8> %81)
  %98 = getelementptr inbounds nuw i8, ptr %0, i64 16
  store <16 x i8> %97, ptr %98, align 1, !tbaa !9
  %99 = icmp eq i64 %79, 32
  br i1 %99, label %110, label %100, !llvm.loop !15

100:                                              ; preds = %89
  %101 = add nuw nsw i32 %68, 32
  %102 = and i32 %101, 536870911
  %103 = zext nneg i32 %102 to i64
  %104 = getelementptr inbounds nuw i8, ptr %7, i64 %103
  %105 = load <16 x i8>, ptr %104, align 1, !tbaa !9
  %106 = getelementptr inbounds nuw i8, ptr %104, i64 1
  %107 = load <16 x i8>, ptr %106, align 1, !tbaa !9
  %108 = tail call <16 x i8> @llvm.fshr.v16i8(<16 x i8> %107, <16 x i8> %105, <16 x i8> %81)
  %109 = getelementptr inbounds nuw i8, ptr %0, i64 32
  store <16 x i8> %108, ptr %109, align 1, !tbaa !9
  br label %110

110:                                              ; preds = %100, %89, %77
  %111 = icmp eq i64 %79, %19
  br i1 %111, label %185, label %112

112:                                              ; preds = %110
  %113 = icmp eq i64 %78, 0
  br i1 %113, label %134, label %114, !prof !18

114:                                              ; preds = %112
  %115 = and i64 %19, 120
  %116 = insertelement <8 x i8> poison, i8 %69, i64 0
  %117 = shufflevector <8 x i8> %116, <8 x i8> poison, <8 x i32> zeroinitializer
  br label %118

118:                                              ; preds = %118, %114
  %119 = phi i64 [ %79, %114 ], [ %130, %118 ]
  %120 = trunc i64 %119 to i32
  %121 = add i32 %68, %120
  %122 = and i32 %121, 536870911
  %123 = zext nneg i32 %122 to i64
  %124 = getelementptr inbounds nuw i8, ptr %7, i64 %123
  %125 = load <8 x i8>, ptr %124, align 1, !tbaa !9
  %126 = getelementptr inbounds nuw i8, ptr %124, i64 1
  %127 = load <8 x i8>, ptr %126, align 1, !tbaa !9
  %128 = tail call <8 x i8> @llvm.fshr.v8i8(<8 x i8> %127, <8 x i8> %125, <8 x i8> %117)
  %129 = getelementptr inbounds nuw i8, ptr %0, i64 %119
  store <8 x i8> %128, ptr %129, align 1, !tbaa !9
  %130 = add nuw i64 %119, 8
  %131 = icmp eq i64 %130, %115
  br i1 %131, label %132, label %118, !llvm.loop !19

132:                                              ; preds = %118
  %133 = icmp eq i64 %115, %19
  br i1 %133, label %185, label %134

134:                                              ; preds = %64, %112, %132
  %135 = phi i64 [ 0, %64 ], [ %79, %112 ], [ %115, %132 ]
  %136 = and i64 %19, 1
  %137 = icmp eq i64 %136, 0
  br i1 %137, label %150, label %138

138:                                              ; preds = %134
  %139 = trunc nuw nsw i64 %135 to i32
  %140 = add nuw nsw i32 %68, %139
  %141 = and i32 %140, 536870911
  %142 = zext nneg i32 %141 to i64
  %143 = getelementptr inbounds nuw i8, ptr %7, i64 %142
  %144 = load i8, ptr %143, align 1, !tbaa !9
  %145 = getelementptr inbounds nuw i8, ptr %143, i64 1
  %146 = load i8, ptr %145, align 1, !tbaa !9
  %147 = tail call i8 @llvm.fshr.i8(i8 %146, i8 %144, i8 %69)
  %148 = getelementptr inbounds nuw i8, ptr %0, i64 %135
  store i8 %147, ptr %148, align 1, !tbaa !9
  %149 = or disjoint i64 %135, 1
  br label %150

150:                                              ; preds = %138, %134
  %151 = phi i64 [ %135, %134 ], [ %149, %138 ]
  %152 = add nsw i64 %19, -1
  %153 = icmp eq i64 %135, %152
  br i1 %153, label %185, label %188

154:                                              ; preds = %44, %154
  %155 = phi i32 [ 0, %44 ], [ %183, %154 ]
  %156 = lshr i32 %155, 3
  %157 = zext nneg i32 %156 to i64
  %158 = getelementptr inbounds nuw i8, ptr %2, i64 %157
  %159 = load i8, ptr %158, align 1, !tbaa !9
  %160 = zext i8 %159 to i32
  %161 = and i32 %155, 7
  %162 = lshr i32 %160, %161
  %163 = and i32 %162, 1
  %164 = shl nuw nsw i32 %163, %161
  %165 = getelementptr inbounds nuw i8, ptr %7, i64 %157
  %166 = load i8, ptr %165, align 1, !tbaa !9
  %167 = trunc nuw i32 %164 to i8
  %168 = or i8 %166, %167
  store i8 %168, ptr %165, align 1, !tbaa !9
  %169 = getelementptr inbounds nuw i8, ptr %1, i64 %157
  %170 = load i8, ptr %169, align 1, !tbaa !9
  %171 = zext i8 %170 to i32
  %172 = lshr i32 %171, %161
  %173 = and i32 %172, 1
  %174 = add nuw nsw i32 %155, %4
  %175 = and i32 %174, 7
  %176 = shl nuw nsw i32 %173, %175
  %177 = lshr i32 %174, 3
  %178 = zext nneg i32 %177 to i64
  %179 = getelementptr inbounds nuw i8, ptr %7, i64 %178
  %180 = load i8, ptr %179, align 1, !tbaa !9
  %181 = trunc nuw i32 %176 to i8
  %182 = or i8 %180, %181
  store i8 %182, ptr %179, align 1, !tbaa !9
  %183 = add nuw nsw i32 %155, 1
  %184 = icmp eq i32 %183, %4
  br i1 %184, label %64, label %154, !llvm.loop !20

185:                                              ; preds = %150, %188, %132, %110
  %186 = and i32 %4, 7
  %187 = icmp eq i32 %186, 0
  br i1 %187, label %222, label %213

188:                                              ; preds = %150, %188
  %189 = phi i64 [ %211, %188 ], [ %151, %150 ]
  %190 = trunc i64 %189 to i32
  %191 = add i32 %68, %190
  %192 = and i32 %191, 536870911
  %193 = zext nneg i32 %192 to i64
  %194 = getelementptr inbounds nuw i8, ptr %7, i64 %193
  %195 = load i8, ptr %194, align 1, !tbaa !9
  %196 = getelementptr inbounds nuw i8, ptr %194, i64 1
  %197 = load i8, ptr %196, align 1, !tbaa !9
  %198 = tail call i8 @llvm.fshr.i8(i8 %197, i8 %195, i8 %69)
  %199 = getelementptr inbounds nuw i8, ptr %0, i64 %189
  store i8 %198, ptr %199, align 1, !tbaa !9
  %200 = add nuw nsw i64 %189, 1
  %201 = trunc i64 %200 to i32
  %202 = add i32 %68, %201
  %203 = and i32 %202, 536870911
  %204 = zext nneg i32 %203 to i64
  %205 = getelementptr inbounds nuw i8, ptr %7, i64 %204
  %206 = load i8, ptr %205, align 1, !tbaa !9
  %207 = getelementptr inbounds nuw i8, ptr %205, i64 1
  %208 = load i8, ptr %207, align 1, !tbaa !9
  %209 = tail call i8 @llvm.fshr.i8(i8 %208, i8 %206, i8 %69)
  %210 = getelementptr inbounds nuw i8, ptr %0, i64 %200
  store i8 %209, ptr %210, align 1, !tbaa !9
  %211 = add nuw nsw i64 %189, 2
  %212 = icmp eq i64 %211, %70
  br i1 %212, label %185, label %188, !llvm.loop !21

213:                                              ; preds = %185
  %214 = shl nsw i32 -1, %186
  %215 = zext nneg i32 %9 to i64
  %216 = getelementptr i8, ptr %0, i64 %215
  %217 = getelementptr i8, ptr %216, i64 -1
  %218 = load i8, ptr %217, align 1, !tbaa !9
  %219 = trunc nsw i32 %214 to i8
  %220 = xor i8 %219, -1
  %221 = and i8 %218, %220
  store i8 %221, ptr %217, align 1, !tbaa !9
  br label %222

222:                                              ; preds = %213, %185
  call void @llvm.lifetime.end.p0(ptr nonnull %7) #8
  ret void
}

; Function Attrs: nofree norecurse nosync nounwind memory(argmem: readwrite) uwtable
define dso_local noundef i64 @limb_intrinsics_200(ptr noundef captures(none) %0, ptr noundef readonly captures(none) %1, ptr noundef readonly captures(none) %2, ptr noundef readonly captures(none) %3, i64 noundef %4) local_unnamed_addr #0 {
  br label %11

6:                                                ; preds = %11
  %7 = tail call i200 @llvm.abs.i200(i200 %21, i1 false)
  %8 = tail call range(i200 0, 201) i200 @llvm.ctpop.i200(i200 %21)
  %9 = tail call range(i200 0, 201) i200 @llvm.ctlz.i200(i200 %21, i1 false)
  %10 = tail call range(i200 0, 201) i200 @llvm.cttz.i200(i200 %21, i1 false)
  br label %144

11:                                               ; preds = %5, %11
  %12 = phi i64 [ 0, %5 ], [ %27, %11 ]
  %13 = phi i200 [ 0, %5 ], [ %21, %11 ]
  %14 = phi i200 [ 0, %5 ], [ %26, %11 ]
  %15 = getelementptr inbounds nuw i8, ptr %1, i64 %12
  %16 = load i8, ptr %15, align 1, !tbaa !9
  %17 = zext i8 %16 to i200
  %18 = shl nuw nsw i64 %12, 3
  %19 = zext nneg i64 %18 to i200
  %20 = shl nuw i200 %17, %19
  %21 = or i200 %20, %13
  %22 = getelementptr inbounds nuw i8, ptr %2, i64 %12
  %23 = load i8, ptr %22, align 1, !tbaa !9
  %24 = zext i8 %23 to i200
  %25 = shl nuw i200 %24, %19
  %26 = or i200 %25, %14
  %27 = add nuw nsw i64 %12, 1
  %28 = icmp eq i64 %27, 25
  br i1 %28, label %6, label %11, !llvm.loop !22

29:                                               ; preds = %144
  %30 = tail call i200 @llvm.uadd.sat.i200(i200 %21, i200 %26)
  %31 = tail call i200 @llvm.usub.sat.i200(i200 %21, i200 %26)
  %32 = tail call i200 @llvm.sadd.sat.i200(i200 %21, i200 %26)
  %33 = tail call i200 @llvm.ssub.sat.i200(i200 %21, i200 %26)
  %34 = insertelement <8 x i200> poison, i200 %7, i64 0
  %35 = shufflevector <8 x i200> %34, <8 x i200> poison, <8 x i32> zeroinitializer
  %36 = lshr <8 x i200> %35, <i200 0, i200 8, i200 16, i200 24, i200 32, i200 40, i200 48, i200 56>
  %37 = trunc <8 x i200> %36 to <8 x i8>
  store <8 x i8> %37, ptr %0, align 1, !tbaa !9
  %38 = lshr <8 x i200> %35, <i200 64, i200 72, i200 80, i200 88, i200 96, i200 104, i200 112, i200 120>
  %39 = trunc <8 x i200> %38 to <8 x i8>
  %40 = getelementptr inbounds nuw i8, ptr %0, i64 8
  store <8 x i8> %39, ptr %40, align 1, !tbaa !9
  %41 = lshr <8 x i200> %35, <i200 128, i200 136, i200 144, i200 152, i200 160, i200 168, i200 176, i200 184>
  %42 = trunc <8 x i200> %41 to <8 x i8>
  %43 = getelementptr inbounds nuw i8, ptr %0, i64 16
  store <8 x i8> %42, ptr %43, align 1, !tbaa !9
  %44 = lshr i200 %7, 192
  %45 = trunc nuw i200 %44 to i8
  %46 = getelementptr inbounds nuw i8, ptr %0, i64 24
  store i8 %45, ptr %46, align 1, !tbaa !9
  %47 = getelementptr inbounds nuw i8, ptr %0, i64 64
  %48 = insertelement <8 x i200> poison, i200 %8, i64 0
  %49 = shufflevector <8 x i200> %48, <8 x i200> poison, <8 x i32> zeroinitializer
  %50 = lshr <8 x i200> %49, <i200 0, i200 8, i200 16, i200 24, i200 32, i200 40, i200 48, i200 56>
  %51 = trunc nuw <8 x i200> %50 to <8 x i8>
  store <8 x i8> %51, ptr %47, align 1, !tbaa !9
  %52 = getelementptr inbounds nuw i8, ptr %0, i64 72
  store <8 x i8> zeroinitializer, ptr %52, align 1, !tbaa !9
  %53 = getelementptr inbounds nuw i8, ptr %0, i64 80
  store <8 x i8> zeroinitializer, ptr %53, align 1, !tbaa !9
  %54 = getelementptr inbounds nuw i8, ptr %0, i64 88
  store i8 0, ptr %54, align 1, !tbaa !9
  %55 = getelementptr inbounds nuw i8, ptr %0, i64 128
  %56 = insertelement <8 x i200> poison, i200 %9, i64 0
  %57 = shufflevector <8 x i200> %56, <8 x i200> poison, <8 x i32> zeroinitializer
  %58 = lshr <8 x i200> %57, <i200 0, i200 8, i200 16, i200 24, i200 32, i200 40, i200 48, i200 56>
  %59 = trunc nuw <8 x i200> %58 to <8 x i8>
  store <8 x i8> %59, ptr %55, align 1, !tbaa !9
  %60 = getelementptr inbounds nuw i8, ptr %0, i64 136
  store <8 x i8> zeroinitializer, ptr %60, align 1, !tbaa !9
  %61 = getelementptr inbounds nuw i8, ptr %0, i64 144
  store <8 x i8> zeroinitializer, ptr %61, align 1, !tbaa !9
  %62 = getelementptr inbounds nuw i8, ptr %0, i64 152
  store i8 0, ptr %62, align 1, !tbaa !9
  %63 = getelementptr inbounds nuw i8, ptr %0, i64 192
  %64 = insertelement <8 x i200> poison, i200 %10, i64 0
  %65 = shufflevector <8 x i200> %64, <8 x i200> poison, <8 x i32> zeroinitializer
  %66 = lshr <8 x i200> %65, <i200 0, i200 8, i200 16, i200 24, i200 32, i200 40, i200 48, i200 56>
  %67 = trunc nuw <8 x i200> %66 to <8 x i8>
  store <8 x i8> %67, ptr %63, align 1, !tbaa !9
  %68 = getelementptr inbounds nuw i8, ptr %0, i64 200
  store <8 x i8> zeroinitializer, ptr %68, align 1, !tbaa !9
  %69 = getelementptr inbounds nuw i8, ptr %0, i64 208
  store <8 x i8> zeroinitializer, ptr %69, align 1, !tbaa !9
  %70 = getelementptr inbounds nuw i8, ptr %0, i64 216
  store i8 0, ptr %70, align 1, !tbaa !9
  %71 = getelementptr inbounds nuw i8, ptr %0, i64 256
  %72 = insertelement <8 x i200> poison, i200 %157, i64 0
  %73 = shufflevector <8 x i200> %72, <8 x i200> poison, <8 x i32> zeroinitializer
  %74 = lshr <8 x i200> %73, <i200 0, i200 8, i200 16, i200 24, i200 32, i200 40, i200 48, i200 56>
  %75 = trunc <8 x i200> %74 to <8 x i8>
  store <8 x i8> %75, ptr %71, align 1, !tbaa !9
  %76 = lshr <8 x i200> %73, <i200 64, i200 72, i200 80, i200 88, i200 96, i200 104, i200 112, i200 120>
  %77 = trunc <8 x i200> %76 to <8 x i8>
  %78 = getelementptr inbounds nuw i8, ptr %0, i64 264
  store <8 x i8> %77, ptr %78, align 1, !tbaa !9
  %79 = lshr <8 x i200> %73, <i200 128, i200 136, i200 144, i200 152, i200 160, i200 168, i200 176, i200 184>
  %80 = trunc <8 x i200> %79 to <8 x i8>
  %81 = getelementptr inbounds nuw i8, ptr %0, i64 272
  store <8 x i8> %80, ptr %81, align 1, !tbaa !9
  %82 = lshr i200 %150, 192
  %83 = trunc nuw i200 %82 to i8
  %84 = getelementptr inbounds nuw i8, ptr %0, i64 280
  store i8 %83, ptr %84, align 1, !tbaa !9
  %85 = getelementptr inbounds nuw i8, ptr %0, i64 384
  %86 = insertelement <8 x i200> poison, i200 %30, i64 0
  %87 = shufflevector <8 x i200> %86, <8 x i200> poison, <8 x i32> zeroinitializer
  %88 = lshr <8 x i200> %87, <i200 0, i200 8, i200 16, i200 24, i200 32, i200 40, i200 48, i200 56>
  %89 = trunc <8 x i200> %88 to <8 x i8>
  store <8 x i8> %89, ptr %85, align 1, !tbaa !9
  %90 = lshr <8 x i200> %87, <i200 64, i200 72, i200 80, i200 88, i200 96, i200 104, i200 112, i200 120>
  %91 = trunc <8 x i200> %90 to <8 x i8>
  %92 = getelementptr inbounds nuw i8, ptr %0, i64 392
  store <8 x i8> %91, ptr %92, align 1, !tbaa !9
  %93 = lshr <8 x i200> %87, <i200 128, i200 136, i200 144, i200 152, i200 160, i200 168, i200 176, i200 184>
  %94 = trunc <8 x i200> %93 to <8 x i8>
  %95 = getelementptr inbounds nuw i8, ptr %0, i64 400
  store <8 x i8> %94, ptr %95, align 1, !tbaa !9
  %96 = lshr i200 %30, 192
  %97 = trunc nuw i200 %96 to i8
  %98 = getelementptr inbounds nuw i8, ptr %0, i64 408
  store i8 %97, ptr %98, align 1, !tbaa !9
  %99 = getelementptr inbounds nuw i8, ptr %0, i64 448
  %100 = insertelement <8 x i200> poison, i200 %31, i64 0
  %101 = shufflevector <8 x i200> %100, <8 x i200> poison, <8 x i32> zeroinitializer
  %102 = lshr <8 x i200> %101, <i200 0, i200 8, i200 16, i200 24, i200 32, i200 40, i200 48, i200 56>
  %103 = trunc <8 x i200> %102 to <8 x i8>
  store <8 x i8> %103, ptr %99, align 1, !tbaa !9
  %104 = lshr <8 x i200> %101, <i200 64, i200 72, i200 80, i200 88, i200 96, i200 104, i200 112, i200 120>
  %105 = trunc <8 x i200> %104 to <8 x i8>
  %106 = getelementptr inbounds nuw i8, ptr %0, i64 456
  store <8 x i8> %105, ptr %106, align 1, !tbaa !9
  %107 = lshr <8 x i200> %101, <i200 128, i200 136, i200 144, i200 152, i200 160, i200 168, i200 176, i200 184>
  %108 = trunc <8 x i200> %107 to <8 x i8>
  %109 = getelementptr inbounds nuw i8, ptr %0, i64 464
  store <8 x i8> %108, ptr %109, align 1, !tbaa !9
  %110 = lshr i200 %31, 192
  %111 = trunc nuw i200 %110 to i8
  %112 = getelementptr inbounds nuw i8, ptr %0, i64 472
  store i8 %111, ptr %112, align 1, !tbaa !9
  %113 = getelementptr inbounds nuw i8, ptr %0, i64 512
  %114 = insertelement <8 x i200> poison, i200 %32, i64 0
  %115 = shufflevector <8 x i200> %114, <8 x i200> poison, <8 x i32> zeroinitializer
  %116 = lshr <8 x i200> %115, <i200 0, i200 8, i200 16, i200 24, i200 32, i200 40, i200 48, i200 56>
  %117 = trunc <8 x i200> %116 to <8 x i8>
  store <8 x i8> %117, ptr %113, align 1, !tbaa !9
  %118 = lshr <8 x i200> %115, <i200 64, i200 72, i200 80, i200 88, i200 96, i200 104, i200 112, i200 120>
  %119 = trunc <8 x i200> %118 to <8 x i8>
  %120 = getelementptr inbounds nuw i8, ptr %0, i64 520
  store <8 x i8> %119, ptr %120, align 1, !tbaa !9
  %121 = lshr <8 x i200> %115, <i200 128, i200 136, i200 144, i200 152, i200 160, i200 168, i200 176, i200 184>
  %122 = trunc <8 x i200> %121 to <8 x i8>
  %123 = getelementptr inbounds nuw i8, ptr %0, i64 528
  store <8 x i8> %122, ptr %123, align 1, !tbaa !9
  %124 = lshr i200 %32, 192
  %125 = trunc nuw i200 %124 to i8
  %126 = getelementptr inbounds nuw i8, ptr %0, i64 536
  store i8 %125, ptr %126, align 1, !tbaa !9
  %127 = getelementptr inbounds nuw i8, ptr %0, i64 576
  %128 = insertelement <8 x i200> poison, i200 %33, i64 0
  %129 = shufflevector <8 x i200> %128, <8 x i200> poison, <8 x i32> zeroinitializer
  %130 = lshr <8 x i200> %129, <i200 0, i200 8, i200 16, i200 24, i200 32, i200 40, i200 48, i200 56>
  %131 = trunc <8 x i200> %130 to <8 x i8>
  store <8 x i8> %131, ptr %127, align 1, !tbaa !9
  %132 = lshr <8 x i200> %129, <i200 64, i200 72, i200 80, i200 88, i200 96, i200 104, i200 112, i200 120>
  %133 = trunc <8 x i200> %132 to <8 x i8>
  %134 = getelementptr inbounds nuw i8, ptr %0, i64 584
  store <8 x i8> %133, ptr %134, align 1, !tbaa !9
  %135 = lshr <8 x i200> %129, <i200 128, i200 136, i200 144, i200 152, i200 160, i200 168, i200 176, i200 184>
  %136 = trunc <8 x i200> %135 to <8 x i8>
  %137 = getelementptr inbounds nuw i8, ptr %0, i64 592
  store <8 x i8> %136, ptr %137, align 1, !tbaa !9
  %138 = lshr i200 %33, 192
  %139 = trunc nuw i200 %138 to i8
  %140 = getelementptr inbounds nuw i8, ptr %0, i64 600
  store i8 %139, ptr %140, align 1, !tbaa !9
  %141 = getelementptr inbounds nuw i8, ptr %0, i64 640
  tail call fastcc void @funnel(ptr noundef nonnull %141, ptr noundef %1, ptr noundef %2, ptr noundef %3, i32 noundef 200, i32 noundef 1)
  %142 = getelementptr inbounds nuw i8, ptr %0, i64 704
  tail call fastcc void @funnel(ptr noundef nonnull %142, ptr noundef %1, ptr noundef %2, ptr noundef %3, i32 noundef 200, i32 noundef 0)
  %143 = xor i64 %4, 90
  ret i64 %143

144:                                              ; preds = %144, %6
  %145 = phi i200 [ 0, %6 ], [ %157, %144 ]
  %146 = phi i32 [ 0, %6 ], [ %158, %144 ]
  %147 = zext nneg i32 %146 to i200
  %148 = lshr i200 %21, %147
  %149 = or disjoint i32 %146, 1
  %150 = shl i200 %145, 2
  %151 = shl i200 %148, 1
  %152 = and i200 %151, 2
  %153 = zext nneg i32 %149 to i200
  %154 = lshr i200 %21, %153
  %155 = and i200 %154, 1
  %156 = or disjoint i200 %152, %155
  %157 = or disjoint i200 %156, %150
  %158 = add nuw nsw i32 %146, 2
  %159 = icmp eq i32 %158, 200
  br i1 %159, label %29, label %144, !llvm.loop !23
}

; Function Attrs: mustprogress nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none)
declare i200 @llvm.ctpop.i200(i200) #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i200 @llvm.ctlz.i200(i200, i1 immarg) #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i200 @llvm.cttz.i200(i200, i1 immarg) #3

; Function Attrs: nofree norecurse nosync nounwind memory(argmem: readwrite) uwtable
define dso_local noundef i64 @limb_intrinsics_256(ptr noundef captures(none) %0, ptr noundef readonly captures(none) %1, ptr noundef readonly captures(none) %2, ptr noundef readonly captures(none) %3, i64 noundef %4) local_unnamed_addr #0 {
  br label %11

6:                                                ; preds = %11
  %7 = tail call i256 @llvm.abs.i256(i256 %21, i1 false)
  %8 = tail call range(i256 0, 257) i256 @llvm.ctpop.i256(i256 %21)
  %9 = tail call range(i256 0, 257) i256 @llvm.ctlz.i256(i256 %21, i1 false)
  %10 = tail call range(i256 0, 257) i256 @llvm.cttz.i256(i256 %21, i1 false)
  br label %29

11:                                               ; preds = %5, %11
  %12 = phi i64 [ 0, %5 ], [ %27, %11 ]
  %13 = phi i256 [ 0, %5 ], [ %21, %11 ]
  %14 = phi i256 [ 0, %5 ], [ %26, %11 ]
  %15 = getelementptr inbounds nuw i8, ptr %1, i64 %12
  %16 = load i8, ptr %15, align 1, !tbaa !9
  %17 = zext i8 %16 to i256
  %18 = shl nuw nsw i64 %12, 3
  %19 = zext nneg i64 %18 to i256
  %20 = shl nuw i256 %17, %19
  %21 = or i256 %20, %13
  %22 = getelementptr inbounds nuw i8, ptr %2, i64 %12
  %23 = load i8, ptr %22, align 1, !tbaa !9
  %24 = zext i8 %23 to i256
  %25 = shl nuw i256 %24, %19
  %26 = or i256 %25, %14
  %27 = add nuw nsw i64 %12, 1
  %28 = icmp eq i64 %27, 32
  br i1 %28, label %6, label %11, !llvm.loop !24

29:                                               ; preds = %29, %6
  %30 = phi i256 [ 0, %6 ], [ %42, %29 ]
  %31 = phi i32 [ 0, %6 ], [ %43, %29 ]
  %32 = zext nneg i32 %31 to i256
  %33 = lshr i256 %21, %32
  %34 = or disjoint i32 %31, 1
  %35 = shl i256 %30, 2
  %36 = shl i256 %33, 1
  %37 = and i256 %36, 2
  %38 = or disjoint i256 %35, %37
  %39 = zext nneg i32 %34 to i256
  %40 = lshr i256 %21, %39
  %41 = and i256 %40, 1
  %42 = or disjoint i256 %41, %38
  %43 = add nuw nsw i32 %31, 2
  %44 = icmp eq i32 %43, 256
  br i1 %44, label %126, label %29, !llvm.loop !25

45:                                               ; preds = %126
  %46 = tail call i256 @llvm.uadd.sat.i256(i256 %21, i256 %26)
  %47 = tail call i256 @llvm.usub.sat.i256(i256 %21, i256 %26)
  %48 = tail call i256 @llvm.sadd.sat.i256(i256 %21, i256 %26)
  %49 = insertelement <16 x i256> poison, i256 %7, i64 0
  %50 = shufflevector <16 x i256> %49, <16 x i256> poison, <16 x i32> zeroinitializer
  %51 = lshr <16 x i256> %50, <i256 0, i256 8, i256 16, i256 24, i256 32, i256 40, i256 48, i256 56, i256 64, i256 72, i256 80, i256 88, i256 96, i256 104, i256 112, i256 120>
  %52 = trunc <16 x i256> %51 to <16 x i8>
  store <16 x i8> %52, ptr %0, align 1, !tbaa !9
  %53 = lshr <16 x i256> %50, <i256 128, i256 136, i256 144, i256 152, i256 160, i256 168, i256 176, i256 184, i256 192, i256 200, i256 208, i256 216, i256 224, i256 232, i256 240, i256 248>
  %54 = trunc <16 x i256> %53 to <16 x i8>
  %55 = getelementptr inbounds nuw i8, ptr %0, i64 16
  store <16 x i8> %54, ptr %55, align 1, !tbaa !9
  %56 = insertelement <16 x i256> poison, i256 %8, i64 0
  %57 = shufflevector <16 x i256> %56, <16 x i256> poison, <16 x i32> zeroinitializer
  %58 = lshr <16 x i256> %57, <i256 0, i256 8, i256 16, i256 24, i256 32, i256 40, i256 48, i256 56, i256 64, i256 72, i256 80, i256 88, i256 96, i256 104, i256 112, i256 120>
  %59 = trunc <16 x i256> %58 to <16 x i8>
  %60 = getelementptr inbounds nuw i8, ptr %0, i64 64
  store <16 x i8> %59, ptr %60, align 1, !tbaa !9
  %61 = getelementptr inbounds nuw i8, ptr %0, i64 80
  store <16 x i8> zeroinitializer, ptr %61, align 1, !tbaa !9
  %62 = insertelement <16 x i256> poison, i256 %9, i64 0
  %63 = shufflevector <16 x i256> %62, <16 x i256> poison, <16 x i32> zeroinitializer
  %64 = lshr <16 x i256> %63, <i256 0, i256 8, i256 16, i256 24, i256 32, i256 40, i256 48, i256 56, i256 64, i256 72, i256 80, i256 88, i256 96, i256 104, i256 112, i256 120>
  %65 = trunc <16 x i256> %64 to <16 x i8>
  %66 = getelementptr inbounds nuw i8, ptr %0, i64 128
  store <16 x i8> %65, ptr %66, align 1, !tbaa !9
  %67 = getelementptr inbounds nuw i8, ptr %0, i64 144
  store <16 x i8> zeroinitializer, ptr %67, align 1, !tbaa !9
  %68 = insertelement <16 x i256> poison, i256 %10, i64 0
  %69 = shufflevector <16 x i256> %68, <16 x i256> poison, <16 x i32> zeroinitializer
  %70 = lshr <16 x i256> %69, <i256 0, i256 8, i256 16, i256 24, i256 32, i256 40, i256 48, i256 56, i256 64, i256 72, i256 80, i256 88, i256 96, i256 104, i256 112, i256 120>
  %71 = trunc <16 x i256> %70 to <16 x i8>
  %72 = getelementptr inbounds nuw i8, ptr %0, i64 192
  store <16 x i8> %71, ptr %72, align 1, !tbaa !9
  %73 = getelementptr inbounds nuw i8, ptr %0, i64 208
  store <16 x i8> zeroinitializer, ptr %73, align 1, !tbaa !9
  %74 = insertelement <16 x i256> poison, i256 %42, i64 0
  %75 = shufflevector <16 x i256> %74, <16 x i256> poison, <16 x i32> zeroinitializer
  %76 = lshr <16 x i256> %75, <i256 0, i256 8, i256 16, i256 24, i256 32, i256 40, i256 48, i256 56, i256 64, i256 72, i256 80, i256 88, i256 96, i256 104, i256 112, i256 120>
  %77 = trunc <16 x i256> %76 to <16 x i8>
  %78 = getelementptr inbounds nuw i8, ptr %0, i64 256
  store <16 x i8> %77, ptr %78, align 1, !tbaa !9
  %79 = lshr <16 x i256> %75, <i256 128, i256 136, i256 144, i256 152, i256 160, i256 168, i256 176, i256 184, i256 192, i256 200, i256 208, i256 216, i256 224, i256 232, i256 240, i256 248>
  %80 = trunc <16 x i256> %79 to <16 x i8>
  %81 = getelementptr inbounds nuw i8, ptr %0, i64 272
  store <16 x i8> %80, ptr %81, align 1, !tbaa !9
  %82 = insertelement <16 x i256> poison, i256 %145, i64 0
  %83 = shufflevector <16 x i256> %82, <16 x i256> poison, <16 x i32> zeroinitializer
  %84 = lshr <16 x i256> %83, <i256 0, i256 8, i256 16, i256 24, i256 32, i256 40, i256 48, i256 56, i256 64, i256 72, i256 80, i256 88, i256 96, i256 104, i256 112, i256 120>
  %85 = trunc <16 x i256> %84 to <16 x i8>
  %86 = getelementptr inbounds nuw i8, ptr %0, i64 320
  store <16 x i8> %85, ptr %86, align 1, !tbaa !9
  %87 = lshr <16 x i256> %83, <i256 128, i256 136, i256 144, i256 152, i256 160, i256 168, i256 176, i256 184, i256 192, i256 200, i256 208, i256 216, i256 224, i256 232, i256 240, i256 248>
  %88 = trunc <16 x i256> %87 to <16 x i8>
  %89 = getelementptr inbounds nuw i8, ptr %0, i64 336
  store <16 x i8> %88, ptr %89, align 1, !tbaa !9
  %90 = insertelement <16 x i256> poison, i256 %46, i64 0
  %91 = shufflevector <16 x i256> %90, <16 x i256> poison, <16 x i32> zeroinitializer
  %92 = lshr <16 x i256> %91, <i256 0, i256 8, i256 16, i256 24, i256 32, i256 40, i256 48, i256 56, i256 64, i256 72, i256 80, i256 88, i256 96, i256 104, i256 112, i256 120>
  %93 = trunc <16 x i256> %92 to <16 x i8>
  %94 = getelementptr inbounds nuw i8, ptr %0, i64 384
  store <16 x i8> %93, ptr %94, align 1, !tbaa !9
  %95 = lshr <16 x i256> %91, <i256 128, i256 136, i256 144, i256 152, i256 160, i256 168, i256 176, i256 184, i256 192, i256 200, i256 208, i256 216, i256 224, i256 232, i256 240, i256 248>
  %96 = trunc <16 x i256> %95 to <16 x i8>
  %97 = getelementptr inbounds nuw i8, ptr %0, i64 400
  store <16 x i8> %96, ptr %97, align 1, !tbaa !9
  %98 = insertelement <16 x i256> poison, i256 %47, i64 0
  %99 = shufflevector <16 x i256> %98, <16 x i256> poison, <16 x i32> zeroinitializer
  %100 = lshr <16 x i256> %99, <i256 0, i256 8, i256 16, i256 24, i256 32, i256 40, i256 48, i256 56, i256 64, i256 72, i256 80, i256 88, i256 96, i256 104, i256 112, i256 120>
  %101 = trunc <16 x i256> %100 to <16 x i8>
  %102 = getelementptr inbounds nuw i8, ptr %0, i64 448
  store <16 x i8> %101, ptr %102, align 1, !tbaa !9
  %103 = lshr <16 x i256> %99, <i256 128, i256 136, i256 144, i256 152, i256 160, i256 168, i256 176, i256 184, i256 192, i256 200, i256 208, i256 216, i256 224, i256 232, i256 240, i256 248>
  %104 = trunc <16 x i256> %103 to <16 x i8>
  %105 = getelementptr inbounds nuw i8, ptr %0, i64 464
  store <16 x i8> %104, ptr %105, align 1, !tbaa !9
  %106 = insertelement <16 x i256> poison, i256 %48, i64 0
  %107 = shufflevector <16 x i256> %106, <16 x i256> poison, <16 x i32> zeroinitializer
  %108 = lshr <16 x i256> %107, <i256 0, i256 8, i256 16, i256 24, i256 32, i256 40, i256 48, i256 56, i256 64, i256 72, i256 80, i256 88, i256 96, i256 104, i256 112, i256 120>
  %109 = trunc <16 x i256> %108 to <16 x i8>
  %110 = getelementptr inbounds nuw i8, ptr %0, i64 512
  store <16 x i8> %109, ptr %110, align 1, !tbaa !9
  %111 = lshr <16 x i256> %107, <i256 128, i256 136, i256 144, i256 152, i256 160, i256 168, i256 176, i256 184, i256 192, i256 200, i256 208, i256 216, i256 224, i256 232, i256 240, i256 248>
  %112 = trunc <16 x i256> %111 to <16 x i8>
  %113 = getelementptr inbounds nuw i8, ptr %0, i64 528
  store <16 x i8> %112, ptr %113, align 1, !tbaa !9
  %114 = tail call i256 @llvm.ssub.sat.i256(i256 %21, i256 %26)
  %115 = insertelement <16 x i256> poison, i256 %114, i64 0
  %116 = shufflevector <16 x i256> %115, <16 x i256> poison, <16 x i32> zeroinitializer
  %117 = lshr <16 x i256> %116, <i256 0, i256 8, i256 16, i256 24, i256 32, i256 40, i256 48, i256 56, i256 64, i256 72, i256 80, i256 88, i256 96, i256 104, i256 112, i256 120>
  %118 = trunc <16 x i256> %117 to <16 x i8>
  %119 = getelementptr inbounds nuw i8, ptr %0, i64 576
  store <16 x i8> %118, ptr %119, align 1, !tbaa !9
  %120 = lshr <16 x i256> %116, <i256 128, i256 136, i256 144, i256 152, i256 160, i256 168, i256 176, i256 184, i256 192, i256 200, i256 208, i256 216, i256 224, i256 232, i256 240, i256 248>
  %121 = trunc <16 x i256> %120 to <16 x i8>
  %122 = getelementptr inbounds nuw i8, ptr %0, i64 592
  store <16 x i8> %121, ptr %122, align 1, !tbaa !9
  %123 = getelementptr inbounds nuw i8, ptr %0, i64 640
  tail call fastcc void @funnel(ptr noundef nonnull %123, ptr noundef nonnull %1, ptr noundef nonnull %2, ptr noundef %3, i32 noundef 256, i32 noundef 1)
  %124 = getelementptr inbounds nuw i8, ptr %0, i64 704
  tail call fastcc void @funnel(ptr noundef nonnull %124, ptr noundef nonnull %1, ptr noundef nonnull %2, ptr noundef %3, i32 noundef 256, i32 noundef 0)
  %125 = xor i64 %4, 90
  ret i64 %125

126:                                              ; preds = %29, %126
  %127 = phi i256 [ %145, %126 ], [ 0, %29 ]
  %128 = phi i32 [ %146, %126 ], [ 0, %29 ]
  %129 = shl nuw nsw i32 %128, 3
  %130 = zext nneg i32 %129 to i256
  %131 = lshr i256 %21, %130
  %132 = and i256 %131, 255
  %133 = sub nuw nsw i32 248, %129
  %134 = zext nneg i32 %133 to i256
  %135 = shl nuw i256 %132, %134
  %136 = or i256 %135, %127
  %137 = shl i32 %128, 3
  %138 = or disjoint i32 %137, 8
  %139 = zext nneg i32 %138 to i256
  %140 = lshr i256 %21, %139
  %141 = and i256 %140, 255
  %142 = sub nuw nsw i32 248, %138
  %143 = zext nneg i32 %142 to i256
  %144 = shl nuw nsw i256 %141, %143
  %145 = or i256 %144, %136
  %146 = add nuw nsw i32 %128, 2
  %147 = icmp eq i32 %146, 32
  br i1 %147, label %45, label %126, !llvm.loop !26
}

; Function Attrs: mustprogress nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none)
declare i256 @llvm.ctpop.i256(i256) #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i256 @llvm.ctlz.i256(i256, i1 immarg) #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i256 @llvm.cttz.i256(i256, i1 immarg) #3

; Function Attrs: nofree norecurse nosync nounwind memory(argmem: readwrite) uwtable
define dso_local noundef i64 @limb_intrinsics_495(ptr noundef captures(none) %0, ptr noundef readonly captures(none) %1, ptr noundef readonly captures(none) %2, ptr noundef readonly captures(none) %3, i64 noundef %4) local_unnamed_addr #0 {
  %6 = alloca [10 x i512], align 16
  br label %20

7:                                                ; preds = %20
  call void @llvm.lifetime.start.p0(ptr nonnull %6) #8
  %8 = tail call i495 @llvm.abs.i495(i495 %30, i1 false)
  %9 = zext i495 %8 to i512
  store i512 %9, ptr %6, align 16, !tbaa !27
  %10 = tail call range(i495 0, 496) i495 @llvm.ctpop.i495(i495 %30)
  %11 = getelementptr inbounds nuw i8, ptr %6, i64 64
  %12 = zext nneg i495 %10 to i512
  store i512 %12, ptr %11, align 16, !tbaa !27
  %13 = tail call range(i495 0, 496) i495 @llvm.ctlz.i495(i495 %30, i1 false)
  %14 = getelementptr inbounds nuw i8, ptr %6, i64 128
  %15 = zext nneg i495 %13 to i512
  store i512 %15, ptr %14, align 16, !tbaa !27
  %16 = tail call range(i495 0, 496) i495 @llvm.cttz.i495(i495 %30, i1 false)
  %17 = getelementptr inbounds nuw i8, ptr %6, i64 192
  %18 = zext nneg i495 %16 to i512
  store i512 %18, ptr %17, align 16, !tbaa !27
  %19 = getelementptr inbounds nuw i8, ptr %6, i64 256
  br label %50

20:                                               ; preds = %5, %20
  %21 = phi i64 [ 0, %5 ], [ %36, %20 ]
  %22 = phi i495 [ 0, %5 ], [ %30, %20 ]
  %23 = phi i495 [ 0, %5 ], [ %35, %20 ]
  %24 = getelementptr inbounds nuw i8, ptr %1, i64 %21
  %25 = load i8, ptr %24, align 1, !tbaa !9
  %26 = zext i8 %25 to i495
  %27 = shl nuw nsw i64 %21, 3
  %28 = zext nneg i64 %27 to i495
  %29 = shl i495 %26, %28
  %30 = or i495 %29, %22
  %31 = getelementptr inbounds nuw i8, ptr %2, i64 %21
  %32 = load i8, ptr %31, align 1, !tbaa !9
  %33 = zext i8 %32 to i495
  %34 = shl i495 %33, %28
  %35 = or i495 %34, %23
  %36 = add nuw nsw i64 %21, 1
  %37 = icmp eq i64 %36, 62
  br i1 %37, label %7, label %20, !llvm.loop !29

38:                                               ; preds = %50
  %39 = icmp slt i495 %30, 0
  %40 = zext i495 %57 to i512
  store i512 %40, ptr %19, align 16, !tbaa !27
  %41 = getelementptr inbounds nuw i8, ptr %6, i64 320
  store i512 0, ptr %41, align 16, !tbaa !27
  %42 = tail call i495 @llvm.uadd.sat.i495(i495 %30, i495 %35)
  %43 = getelementptr inbounds nuw i8, ptr %6, i64 384
  %44 = zext i495 %42 to i512
  store i512 %44, ptr %43, align 16, !tbaa !27
  %45 = tail call i495 @llvm.usub.sat.i495(i495 %30, i495 %35)
  %46 = getelementptr inbounds nuw i8, ptr %6, i64 448
  %47 = zext i495 %45 to i512
  store i512 %47, ptr %46, align 16, !tbaa !27
  %48 = tail call { i495, i1 } @llvm.sadd.with.overflow.i495(i495 %30, i495 %35)
  %49 = extractvalue { i495, i1 } %48, 1
  br i1 %49, label %60, label %62

50:                                               ; preds = %7, %50
  %51 = phi i495 [ 0, %7 ], [ %57, %50 ]
  %52 = phi i32 [ 0, %7 ], [ %58, %50 ]
  %53 = shl i495 %51, 1
  %54 = zext nneg i32 %52 to i495
  %55 = lshr i495 %30, %54
  %56 = and i495 %55, 1
  %57 = or disjoint i495 %56, %53
  %58 = add nuw nsw i32 %52, 1
  %59 = icmp eq i32 %58, 495
  br i1 %59, label %38, label %50, !llvm.loop !30

60:                                               ; preds = %38
  %61 = select i1 %39, i495 -51146728248377216718956089012931236753385031969422887335676427626502090568823039920051095192592252455482604439493126109519019633529459266458258243584, i495 51146728248377216718956089012931236753385031969422887335676427626502090568823039920051095192592252455482604439493126109519019633529459266458258243583
  br label %64

62:                                               ; preds = %38
  %63 = extractvalue { i495, i1 } %48, 0
  br label %64

64:                                               ; preds = %62, %60
  %65 = phi i495 [ %61, %60 ], [ %63, %62 ]
  %66 = getelementptr inbounds nuw i8, ptr %6, i64 512
  %67 = zext i495 %65 to i512
  store i512 %67, ptr %66, align 16, !tbaa !27
  %68 = tail call { i495, i1 } @llvm.ssub.with.overflow.i495(i495 %30, i495 %35)
  %69 = extractvalue { i495, i1 } %68, 1
  br i1 %69, label %70, label %72

70:                                               ; preds = %64
  %71 = select i1 %39, i495 -51146728248377216718956089012931236753385031969422887335676427626502090568823039920051095192592252455482604439493126109519019633529459266458258243584, i495 51146728248377216718956089012931236753385031969422887335676427626502090568823039920051095192592252455482604439493126109519019633529459266458258243583
  br label %74

72:                                               ; preds = %64
  %73 = extractvalue { i495, i1 } %68, 0
  br label %74

74:                                               ; preds = %72, %70
  %75 = phi i495 [ %71, %70 ], [ %73, %72 ]
  %76 = getelementptr inbounds nuw i8, ptr %6, i64 576
  %77 = zext i495 %75 to i512
  store i512 %77, ptr %76, align 16, !tbaa !27
  br label %82

78:                                               ; preds = %131
  %79 = getelementptr inbounds nuw i8, ptr %0, i64 640
  tail call fastcc void @funnel(ptr noundef nonnull %79, ptr noundef %1, ptr noundef %2, ptr noundef %3, i32 noundef 495, i32 noundef 1)
  %80 = getelementptr inbounds nuw i8, ptr %0, i64 704
  tail call fastcc void @funnel(ptr noundef nonnull %80, ptr noundef %1, ptr noundef %2, ptr noundef %3, i32 noundef 495, i32 noundef 0)
  %81 = xor i64 %4, 90
  call void @llvm.lifetime.end.p0(ptr nonnull %6) #8
  ret i64 %81

82:                                               ; preds = %74, %131
  %83 = phi i64 [ 0, %74 ], [ %132, %131 ]
  %84 = icmp eq i64 %83, 5
  br i1 %84, label %131, label %85

85:                                               ; preds = %82
  %86 = getelementptr inbounds nuw i512, ptr %6, i64 %83
  %87 = load i512, ptr %86, align 16, !tbaa !27
  %88 = trunc i512 %87 to i495
  %89 = shl nuw nsw i64 %83, 6
  %90 = getelementptr inbounds nuw i8, ptr %0, i64 %89
  %91 = insertelement <8 x i495> poison, i495 %88, i64 0
  %92 = shufflevector <8 x i495> %91, <8 x i495> poison, <8 x i32> zeroinitializer
  %93 = lshr <8 x i495> %92, <i495 0, i495 8, i495 16, i495 24, i495 32, i495 40, i495 48, i495 56>
  %94 = trunc <8 x i495> %93 to <8 x i8>
  store <8 x i8> %94, ptr %90, align 1, !tbaa !9
  %95 = lshr <8 x i495> %92, <i495 64, i495 72, i495 80, i495 88, i495 96, i495 104, i495 112, i495 120>
  %96 = trunc <8 x i495> %95 to <8 x i8>
  %97 = getelementptr inbounds nuw i8, ptr %90, i64 8
  store <8 x i8> %96, ptr %97, align 1, !tbaa !9
  %98 = lshr <8 x i495> %92, <i495 128, i495 136, i495 144, i495 152, i495 160, i495 168, i495 176, i495 184>
  %99 = trunc <8 x i495> %98 to <8 x i8>
  %100 = getelementptr inbounds nuw i8, ptr %90, i64 16
  store <8 x i8> %99, ptr %100, align 1, !tbaa !9
  %101 = lshr <8 x i495> %92, <i495 192, i495 200, i495 208, i495 216, i495 224, i495 232, i495 240, i495 248>
  %102 = trunc <8 x i495> %101 to <8 x i8>
  %103 = getelementptr inbounds nuw i8, ptr %90, i64 24
  store <8 x i8> %102, ptr %103, align 1, !tbaa !9
  %104 = lshr <8 x i495> %92, <i495 256, i495 264, i495 272, i495 280, i495 288, i495 296, i495 304, i495 312>
  %105 = trunc <8 x i495> %104 to <8 x i8>
  %106 = getelementptr inbounds nuw i8, ptr %90, i64 32
  store <8 x i8> %105, ptr %106, align 1, !tbaa !9
  %107 = lshr <8 x i495> %92, <i495 320, i495 328, i495 336, i495 344, i495 352, i495 360, i495 368, i495 376>
  %108 = trunc <8 x i495> %107 to <8 x i8>
  %109 = getelementptr inbounds nuw i8, ptr %90, i64 40
  store <8 x i8> %108, ptr %109, align 1, !tbaa !9
  %110 = lshr <8 x i495> %92, <i495 384, i495 392, i495 400, i495 408, i495 416, i495 424, i495 432, i495 440>
  %111 = trunc <8 x i495> %110 to <8 x i8>
  %112 = getelementptr inbounds nuw i8, ptr %90, i64 48
  store <8 x i8> %111, ptr %112, align 1, !tbaa !9
  %113 = lshr i512 %87, 448
  %114 = trunc i512 %113 to i8
  %115 = getelementptr inbounds nuw i8, ptr %90, i64 56
  store i8 %114, ptr %115, align 1, !tbaa !9
  %116 = lshr i512 %87, 456
  %117 = trunc i512 %116 to i8
  %118 = getelementptr inbounds nuw i8, ptr %90, i64 57
  store i8 %117, ptr %118, align 1, !tbaa !9
  %119 = lshr i512 %87, 464
  %120 = trunc i512 %119 to i8
  %121 = getelementptr inbounds nuw i8, ptr %90, i64 58
  store i8 %120, ptr %121, align 1, !tbaa !9
  %122 = lshr i512 %87, 472
  %123 = trunc i512 %122 to i8
  %124 = getelementptr inbounds nuw i8, ptr %90, i64 59
  store i8 %123, ptr %124, align 1, !tbaa !9
  %125 = lshr i512 %87, 480
  %126 = trunc i512 %125 to i8
  %127 = getelementptr inbounds nuw i8, ptr %90, i64 60
  store i8 %126, ptr %127, align 1, !tbaa !9
  %128 = lshr i495 %88, 488
  %129 = trunc nuw nsw i495 %128 to i8
  %130 = getelementptr inbounds nuw i8, ptr %90, i64 61
  store i8 %129, ptr %130, align 1, !tbaa !9
  br label %131

131:                                              ; preds = %85, %82
  %132 = add nuw nsw i64 %83, 1
  %133 = icmp eq i64 %132, 10
  br i1 %133, label %78, label %82, !llvm.loop !31
}

; Function Attrs: mustprogress nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none)
declare i495 @llvm.ctpop.i495(i495) #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i495 @llvm.ctlz.i495(i495, i1 immarg) #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i495 @llvm.cttz.i495(i495, i1 immarg) #3

; Function Attrs: mustprogress nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none)
declare { i495, i1 } @llvm.sadd.with.overflow.i495(i495, i495) #2

; Function Attrs: mustprogress nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none)
declare { i495, i1 } @llvm.ssub.with.overflow.i495(i495, i495) #2

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr writeonly captures(none), i8, i64, i1 immarg) #5

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i140 @llvm.abs.i140(i140, i1 immarg) #6

; Function Attrs: nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none)
declare i140 @llvm.uadd.sat.i140(i140, i140) #7

; Function Attrs: nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none)
declare i140 @llvm.usub.sat.i140(i140, i140) #7

; Function Attrs: nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none)
declare i8 @llvm.fshr.i8(i8, i8, i8) #7

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i200 @llvm.abs.i200(i200, i1 immarg) #6

; Function Attrs: nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none)
declare i200 @llvm.uadd.sat.i200(i200, i200) #7

; Function Attrs: nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none)
declare i200 @llvm.usub.sat.i200(i200, i200) #7

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i256 @llvm.abs.i256(i256, i1 immarg) #6

; Function Attrs: nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none)
declare i256 @llvm.uadd.sat.i256(i256, i256) #7

; Function Attrs: nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none)
declare i256 @llvm.usub.sat.i256(i256, i256) #7

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i495 @llvm.abs.i495(i495, i1 immarg) #6

; Function Attrs: nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none)
declare i495 @llvm.uadd.sat.i495(i495, i495) #7

; Function Attrs: nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none)
declare i495 @llvm.usub.sat.i495(i495, i495) #7

; Function Attrs: nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none)
declare i140 @llvm.sadd.sat.i140(i140, i140) #7

; Function Attrs: nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none)
declare i140 @llvm.ssub.sat.i140(i140, i140) #7

; Function Attrs: nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none)
declare i200 @llvm.sadd.sat.i200(i200, i200) #7

; Function Attrs: nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none)
declare i200 @llvm.ssub.sat.i200(i200, i200) #7

; Function Attrs: nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none)
declare i256 @llvm.sadd.sat.i256(i256, i256) #7

; Function Attrs: nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none)
declare i256 @llvm.ssub.sat.i256(i256, i256) #7

; Function Attrs: nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none)
declare <16 x i8> @llvm.fshr.v16i8(<16 x i8>, <16 x i8>, <16 x i8>) #7

; Function Attrs: nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none)
declare <8 x i8> @llvm.fshr.v8i8(<8 x i8>, <8 x i8>, <8 x i8>) #7

attributes #0 = { nofree norecurse nosync nounwind memory(argmem: readwrite) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { mustprogress nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none) }
attributes #3 = { mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #4 = { nofree noinline norecurse nosync nounwind memory(argmem: readwrite) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #5 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: write) }
attributes #6 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #7 = { nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none) }
attributes #8 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3}
!llvm.ident = !{!4}
!llvm.errno.tbaa = !{!5}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 8, !"PIC Level", i32 2}
!2 = !{i32 7, !"PIE Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{!"Ubuntu clang version 22.1.8 (++20260714014902+ca7933e47d3a-1~exp1~20260714135019.80)"}
!5 = !{!6, !6, i64 0}
!6 = !{!"int", !7, i64 0}
!7 = !{!"omnipotent char", !8, i64 0}
!8 = !{!"Simple C/C++ TBAA"}
!9 = !{!7, !7, i64 0}
!10 = distinct !{!10, !11}
!11 = !{!"llvm.loop.mustprogress"}
!12 = distinct !{!12, !11}
!13 = distinct !{!13, !11, !14}
!14 = !{!"llvm.loop.peeled.count", i32 1}
!15 = distinct !{!15, !11, !16, !17}
!16 = !{!"llvm.loop.isvectorized", i32 1}
!17 = !{!"llvm.loop.unroll.runtime.disable"}
!18 = !{!"branch_weights", i32 8, i32 8}
!19 = distinct !{!19, !11, !16, !17}
!20 = distinct !{!20, !11}
!21 = distinct !{!21, !11, !16}
!22 = distinct !{!22, !11}
!23 = distinct !{!23, !11}
!24 = distinct !{!24, !11}
!25 = distinct !{!25, !11}
!26 = distinct !{!26, !11}
!27 = !{!28, !28, i64 0}
!28 = !{!"_BitInt(495)", !7, i64 0}
!29 = distinct !{!29, !11}
!30 = distinct !{!30, !11}
!31 = distinct !{!31, !11}
