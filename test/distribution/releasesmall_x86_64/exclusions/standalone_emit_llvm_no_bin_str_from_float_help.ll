source_filename = "main"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux5.10.0-gnu2.31.0"

%Io.Writer.VTable = type { ptr, ptr, ptr, ptr }
%"fmt.float.FloatDecimal(u64)" = type { i64, i32, i1, [3 x i8] }
%Io.Writer = type { ptr, { ptr, i64 }, i64 }

@__anon_597 = private unnamed_addr constant %Io.Writer.VTable { ptr @Io.Writer.fixedDrain, ptr @Io.Writer.unimplementedSendFile, ptr @Io.Writer.noopFlush, ptr @Io.Writer.failingRebase }, align 8
@__anon_625 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 5, [6 x i8] undef }, align 8
@__anon_633 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 2, [6 x i8] undef }, align 8
@__anon_1089 = private unnamed_addr constant [8 x i8] c"(float)\00", align 1
@__anon_1295 = private unnamed_addr constant [4 x i8] c"nan\00", align 1
@__anon_1297 = private unnamed_addr constant [4 x i8] c"inf\00", align 1
@__anon_1423 = private unnamed_addr constant [26 x i64] [i64 1, i64 5, i64 25, i64 125, i64 625, i64 3125, i64 15625, i64 78125, i64 390625, i64 1953125, i64 9765625, i64 48828125, i64 244140625, i64 1220703125, i64 6103515625, i64 30517578125, i64 152587890625, i64 762939453125, i64 3814697265625, i64 19073486328125, i64 95367431640625, i64 476837158203125, i64 2384185791015625, i64 11920928955078125, i64 59604644775390625, i64 298023223876953125], align 8
@__anon_1473 = private unnamed_addr constant [21 x i32] [i32 0, i32 0, i32 0, i32 0, i32 1073741824, i32 1500076437, i32 1431590229, i32 1448432917, i32 1091896580, i32 1079333904, i32 1146442053, i32 1146111296, i32 1163220304, i32 1073758208, i32 -1773927360, i32 1431721317, i32 1413824581, i32 1075134801, i32 1431671125, i32 1363170645, i32 261], align 4
@__anon_1525 = private unnamed_addr constant [19 x i32] [i32 1414808916, i32 67458373, i32 268701696, i32 4195348, i32 1073807360, i32 1091917141, i32 1108, i32 65604, i32 1073741824, i32 1140850753, i32 1346716752, i32 1431634004, i32 1365595476, i32 1073758208, i32 16777217, i32 66816, i32 1364284433, i32 89478484, i32 0], align 4
@fmt.float.FLOAT64_POW5_INV_SPLIT2 = private unnamed_addr constant [15 x [2 x i64]] [[2 x i64] [i64 1, i64 2305843009213693952], [2 x i64] [i64 5955668970331000884, i64 1784059615882449851], [2 x i64] [i64 8982663654677661702, i64 1380349269358112757], [2 x i64] [i64 7286864317269821294, i64 2135987035920910082], [2 x i64] [i64 7005857020398200553, i64 1652639921975621497], [2 x i64] [i64 -481418970354774919, i64 1278668206209430417], [2 x i64] [i64 8928596168509315048, i64 1978643211784836272], [2 x i64] [i64 -8371072500651252758, i64 1530901034580419511], [2 x i64] [i64 597001226353042382, i64 1184477304306571148], [2 x i64] [i64 1527430471115325346, i64 1832889850782397517], [2 x i64] [i64 -5913534206540532074, i64 1418129833677084982], [2 x i64] [i64 5577825024675947042, i64 2194449627517475473], [2 x i64] [i64 -7439769533505684065, i64 1697873161311732311], [2 x i64] [i64 -8133250842069730034, i64 1313665730009899186], [2 x i64] [i64 -5745727253942878843, i64 2032799256770390445]], align 8
@fmt.float.FLOAT64_POW5_SPLIT2 = private unnamed_addr constant [13 x [2 x i64]] [[2 x i64] [i64 0, i64 1152921504606846976], [2 x i64] [i64 0, i64 1490116119384765625], [2 x i64] [i64 1032610780636961552, i64 1925929944387235853], [2 x i64] [i64 7910200175544436838, i64 1244603055572228341], [2 x i64] [i64 -1504838264676837686, i64 1608611746708759036], [2 x i64] [i64 -5421850118411349444, i64 2079081953128979843], [2 x i64] [i64 6607496772837067824, i64 1343575221513417750], [2 x i64] [i64 -1113817083813899013, i64 1736530273035216783], [2 x i64] [i64 -5409364890226003632, i64 2244412773384604712], [2 x i64] [i64 1605989338741628675, i64 1450417759929778918], [2 x i64] [i64 -8816519005292960336, i64 1874621017369538693], [2 x i64] [i64 665883850346957067, i64 1211445438634777304], [2 x i64] [i64 -3514853404985837908, i64 1565756531257009982]], align 8

@strFromFloatHelp = alias void (double), ptr @main.strFromFloatHelp

declare void @llvm.memset.p0.i64(ptr writeonly captures(none), i8, i64, i1 immarg) #1

declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #2

declare i64 @llvm.umin.i64(i64, i64) #6

declare void @llvm.assume(i1 noundef) #7

declare void @llvm.experimental.noalias.scope.decl(metadata) #12

declare void @llvm.lifetime.start.p0(ptr captures(none)) #13

declare void @llvm.lifetime.end.p0(ptr captures(none)) #13

define private void @main.strFromFloatHelp(double %0) unnamed_addr #0 align 1 {
1:
  %2 = alloca { i64, i16, [6 x i8] }, align 8
  %3 = alloca [1 x { ptr, i64 }], align 8
  %4 = alloca i64, align 8
  %5 = alloca %"fmt.float.FloatDecimal(u64)", align 8
  %6 = alloca i64, align 8
  %7 = alloca %"fmt.float.FloatDecimal(u64)", align 8
  %8 = alloca [2 x i64], align 16
  %9 = alloca [2 x i64], align 16
  %.sroa.10.i.i.i.i.i = alloca i8, align 4
  %.sroa.314.i.i.i.i = alloca i8, align 8
  %10 = alloca [347 x i8], align 1
  %.sroa.67.i.i.i = alloca i8, align 8
  %11 = alloca %Io.Writer, align 8
  %12 = alloca [400 x i8], align 1
  call void @llvm.lifetime.start.p0(ptr nonnull %11)
  store ptr @__anon_597, ptr %11, align 8, !noalias !0
  %.sroa.2.0..sroa_idx.i = getelementptr i8, ptr %11, i64 8
  store ptr %12, ptr %.sroa.2.0..sroa_idx.i, align 8, !noalias !0
  %.sroa.3.0..sroa_idx.i = getelementptr i8, ptr %11, i64 16
  store i64 400, ptr %.sroa.3.0..sroa_idx.i, align 8, !noalias !0
  %.sroa.4.0..sroa_idx.i = getelementptr i8, ptr %11, i64 24
  store i64 0, ptr %.sroa.4.0..sroa_idx.i, align 8, !noalias !0
  %13 = bitcast double %0 to i64
  call void @llvm.lifetime.start.p0(ptr nonnull %.sroa.67.i.i.i)
  store i3 0, ptr %.sroa.67.i.i.i, align 8, !alias.scope !3, !noalias !0
  call void @llvm.lifetime.start.p0(ptr nonnull %.sroa.314.i.i.i.i)
  call void @llvm.lifetime.start.p0(ptr nonnull %10), !noalias !0
  %.sroa.67.i.i.i.0..sroa.67.i.i.i.0..sroa.67.i.i.i.0..sroa.67.i.i.0..sroa.67.i.i.0..sroa.67.i.0..sroa.67.i.0..sroa.67.0..sroa.67.0..sroa.67.32..sroa.3.0.copyload.i2.i.i.i = load i8, ptr %.sroa.67.i.i.i, align 8, !noalias !0
  %14 = and i8 %.sroa.67.i.i.i.0..sroa.67.i.i.i.0..sroa.67.i.i.i.0..sroa.67.i.i.0..sroa.67.i.i.0..sroa.67.i.0..sroa.67.i.0..sroa.67.0..sroa.67.0..sroa.67.32..sroa.3.0.copyload.i2.i.i.i, 7
  %switch.selectcmp.i.i.i.i = icmp eq i8 %14, 0
  store i1 %switch.selectcmp.i.i.i.i, ptr %.sroa.314.i.i.i.i, align 8, !noalias !0
  call void @llvm.lifetime.start.p0(ptr nonnull %.sroa.10.i.i.i.i.i)
  %.sroa.314.i.i.i.i.0..sroa.314.i.i.i.i.0..sroa.314.i.i.i.i.0..sroa.314.i.i.i.0..sroa.314.i.i.i.0..sroa.314.i.i.0..sroa.314.i.i.0..sroa.314.i.0..sroa.314.i.0..sroa.314.0..sroa.314.0..sroa.314.16..sroa.3.0.copyload.i.i.i.i.i = load i8, ptr %.sroa.314.i.i.i.i, align 8, !noalias !6
  call void @llvm.experimental.noalias.scope.decl(metadata !9)
  call void @llvm.lifetime.start.p0(ptr nonnull %8), !noalias !6
  call void @llvm.lifetime.start.p0(ptr nonnull %9), !noalias !6
  %15 = and i64 %13, 4503599627370495
  %16 = lshr i64 %13, 52
  %17 = trunc nsw nuw i64 %16 to i32
  %18 = and i32 %17, 2047
  %19 = icmp eq i32 %18, 0
  %20 = icmp eq i64 %15, 0
  %21 = and i1 %20, %19
  %.0106.i.i.sroa.gep.i.i.i.i = getelementptr i8, ptr %10, i64 1
  %.0.i9.i.i.i.i.i.sroa.gep = getelementptr i8, ptr %10, i64 1
  br i1 %21, label %fmt.float.binaryToDecimal__anon_1143.exit.i.i.i.i.i, label %22
22:
  %23 = icmp eq i32 %18, 2047
  br i1 %23, label %fmt.float.binaryToDecimal__anon_1143.exit.i.i.i.i.i, label %24
24:
  %25 = add nsw i32 %18, -1077
  %26 = or disjoint i64 %15, 4503599627370496
  %.054.i.i.i.i.i.i = select i1 %19, i64 %15, i64 %26
  %.0.i.i.i.i.i.i = select i1 %19, i32 -1076, i32 %25
  %27 = and i64 %.054.i.i.i.i.i.i, 1
  %28 = icmp eq i64 %27, 0
  %29 = shl nsw nuw i64 %.054.i.i.i.i.i.i, 2
  %30 = icmp ne i64 %15, 0
  %31 = or i1 %30, %19
  %32 = icmp sgt i32 %.0.i.i.i.i.i.i, -1
  br i1 %32, label %34, label %107
33:
  %.067.i.i.i.i.i.i = phi i1 [ %185, %184 ], [ 0, %187 ], [ 0, %189 ], [ 0, %fmt.float.Backend64_TablesSmall.computeInvPow5.exit.i.i.i.i.i.i ], [ 0, %194 ], [ 1, %192 ], [ %200, %196 ]
  %.065.i.i.i.i.i.i = phi i1 [ 0, %184 ], [ %188, %187 ], [ 0, %189 ], [ 0, %fmt.float.Backend64_TablesSmall.computeInvPow5.exit.i.i.i.i.i.i ], [ 0, %194 ], [ %spec.select88.i.i.i.i.i.i, %192 ], [ 0, %196 ]
  %.064.i.i.i.i.i.i = phi i32 [ %40, %184 ], [ %40, %187 ], [ %40, %189 ], [ %40, %fmt.float.Backend64_TablesSmall.computeInvPow5.exit.i.i.i.i.i.i ], [ %115, %194 ], [ %115, %192 ], [ %115, %196 ]
  %.060.i.i.i.i.i.i = phi i64 [ %105, %184 ], [ %105, %187 ], [ %105, %189 ], [ %105, %fmt.float.Backend64_TablesSmall.computeInvPow5.exit.i.i.i.i.i.i ], [ %179, %194 ], [ %179, %192 ], [ %179, %196 ]
  %.057.i.i.i.i.i.i = phi i64 [ %102, %184 ], [ %102, %187 ], [ %191, %189 ], [ %102, %fmt.float.Backend64_TablesSmall.computeInvPow5.exit.i.i.i.i.i.i ], [ %176, %194 ], [ %spec.select89.i.i.i.i.i.i, %192 ], [ %176, %196 ]
  %.055.i.i.i.i.i.i = phi i64 [ %100, %184 ], [ %100, %187 ], [ %100, %189 ], [ %100, %fmt.float.Backend64_TablesSmall.computeInvPow5.exit.i.i.i.i.i.i ], [ %174, %194 ], [ %174, %192 ], [ %174, %196 ]
  br label %201
34:
  %35 = zext nneg i32 %.0.i.i.i.i.i.i to i64
  %36 = mul nsw nuw i64 %35, 169464822037455
  %37 = lshr i64 %36, 49
  %38 = trunc nsw nuw i64 %37 to i32
  %39 = icmp samesign ugt i32 %.0.i.i.i.i.i.i, 3
  %.neg84.i.i.i.i.i.i = sext i1 %39 to i32
  %40 = add nsw i32 %38, %.neg84.i.i.i.i.i.i
  %41 = icmp ult i32 %40, 32769
  call void @llvm.assume(i1 %41)
  %42 = zext nneg i32 %40 to i64
  %43 = mul nsw nuw i64 %42, 163391164108059
  %44 = lshr i64 %43, 46
  %45 = trunc nsw nuw i64 %44 to i32
  %reass.sub = sub nsw i32 %40, %.0.i.i.i.i.i.i
  %46 = add nsw i32 %reass.sub, 125
  %47 = add nsw i32 %46, %45
  %48 = icmp sgt i32 %47, -1
  call void @llvm.assume(i1 %48)
  %49 = trunc nsw nuw i32 %40 to i16
  %.lhs.trunc.i.i.i.i.i.i.i = add nsw nuw i16 %49, 25
  %50 = udiv i16 %.lhs.trunc.i.i.i.i.i.i.i, 26
  %narrow.i.i.i.i.i.i.i = mul nsw nuw i16 %50, 26
  %51 = zext nneg i16 %narrow.i.i.i.i.i.i.i to i32
  %52 = zext nneg i16 %50 to i64
  %53 = getelementptr [16 x i8], ptr @fmt.float.FLOAT64_POW5_INV_SPLIT2, i64 %52
  %54 = icmp eq i32 %40, %51
  br i1 %54, label %55, label %57
55:
  %56 = load <2 x i64>, ptr %53, align 8, !noalias !12
  br label %fmt.float.Backend64_TablesSmall.computeInvPow5.exit.i.i.i.i.i.i
57:
  %58 = sub nsw nuw i32 %51, %40
  %59 = zext nneg i32 %58 to i64
  %60 = getelementptr [8 x i8], ptr @__anon_1423, i64 %59
  %61 = load i64, ptr %60, align 8, !noalias !12
  %62 = zext i64 %61 to i128
  %63 = load i64, ptr %53, align 8, !noalias !12
  %64 = add i64 %63, -1
  %65 = zext i64 %64 to i128
  %66 = mul nuw i128 %65, %62
  %67 = getelementptr i8, ptr %53, i64 8
  %68 = load i64, ptr %67, align 8, !noalias !12
  %69 = zext i64 %68 to i128
  %70 = mul nuw i128 %69, %62
  %71 = zext nneg i16 %narrow.i.i.i.i.i.i.i to i64
  %72 = mul nsw nuw i64 %71, 163391164108059
  %73 = lshr i64 %72, 46
  %74 = trunc nsw nuw i64 %73 to i32
  %75 = sub nsw i32 %74, %45
  %76 = icmp samesign ult i32 %75, 128
  call void @llvm.assume(i1 %76)
  %77 = trunc nuw i32 %75 to i7
  %78 = shl nsw nuw i32 %40, 1
  %79 = zext nneg i32 %75 to i128
  %80 = lshr i128 %66, %79
  %81 = sub nuw i7 -64, %77
  %82 = zext i7 %81 to i128
  %83 = shl i128 %70, %82
  %84 = lshr i32 %40, 4
  %85 = zext nneg i32 %84 to i64
  %86 = getelementptr [4 x i8], ptr @__anon_1525, i64 %85
  %87 = load i32, ptr %86, align 4, !noalias !12
  %88 = and i32 %78, 30
  %89 = lshr i32 %87, %88
  %90 = and i32 %89, 3
  %91 = zext nneg i32 %90 to i128
  %92 = add nuw i128 %83, 1
  %93 = add nuw i128 %92, %80
  %94 = add nuw i128 %93, %91
  %95 = lshr i128 %94, 64
  %96 = insertelement <2 x i128> poison, i128 %94, i64 0
  %97 = insertelement <2 x i128> %96, i128 %95, i64 1
  %98 = trunc <2 x i128> %97 to <2 x i64>
  br label %fmt.float.Backend64_TablesSmall.computeInvPow5.exit.i.i.i.i.i.i
fmt.float.Backend64_TablesSmall.computeInvPow5.exit.i.i.i.i.i.i:
  %99 = phi <2 x i64> [ %56, %55 ], [ %98, %57 ]
  store <2 x i64> %99, ptr %9, align 16, !noalias !15
  %100 = call fastcc i64 @fmt.float.mulShift64(i64 %29, ptr nonnull readonly align 8 %9, i32 %47), !noalias !15
  %101 = or disjoint i64 %29, 2
  %102 = call fastcc i64 @fmt.float.mulShift64(i64 %101, ptr nonnull readonly align 8 %9, i32 %47), !noalias !15
  %103 = add nsw i64 %29, -1
  %.neg85.i.i.i.i.i.i = sext i1 %31 to i64
  %104 = add nsw i64 %103, %.neg85.i.i.i.i.i.i
  %105 = call fastcc i64 @fmt.float.mulShift64(i64 %104, ptr nonnull readonly align 8 %9, i32 %47), !noalias !15
  %106 = icmp samesign ult i32 %40, 22
  br i1 %106, label %181, label %33
107:
  %108 = sub nsw i32 0, %.0.i.i.i.i.i.i
  %109 = zext nneg i32 %108 to i64
  %110 = mul nsw nuw i64 %109, 196742565691928
  %111 = lshr i64 %110, 48
  %112 = trunc nsw nuw i64 %111 to i32
  %113 = icmp ne i32 %.0.i.i.i.i.i.i, -1
  %.neg.i.i.i.i.i.i = sext i1 %113 to i32
  %114 = add nsw i32 %112, %.neg.i.i.i.i.i.i
  %115 = add nsw i32 %114, %.0.i.i.i.i.i.i
  %116 = icmp sgt i32 %114, -1
  call void @llvm.assume(i1 %116)
  %117 = sub nsw i32 %108, %114
  %118 = icmp ult i32 %117, 32769
  call void @llvm.assume(i1 %118)
  %119 = zext nneg i32 %117 to i64
  %120 = mul nsw nuw i64 %119, 163391164108059
  %121 = lshr i64 %120, 46
  %122 = trunc nsw nuw i64 %121 to i32
  %.neg96.i.i.i.i.i.i = add nsw nuw i32 %114, 124
  %123 = sub nsw i32 %.neg96.i.i.i.i.i.i, %122
  %124 = icmp sgt i32 %123, -1
  call void @llvm.assume(i1 %124)
  %.lhs.trunc.i.i.i.i.i.i = trunc nsw nuw i32 %117 to i16
  %125 = udiv i16 %.lhs.trunc.i.i.i.i.i.i, 26
  %narrow.i.i.i.i.i.i = mul nsw nuw i16 %125, 26
  %126 = zext nneg i16 %narrow.i.i.i.i.i.i to i32
  %127 = zext nneg i16 %125 to i64
  %128 = getelementptr [16 x i8], ptr @fmt.float.FLOAT64_POW5_SPLIT2, i64 %127
  %129 = icmp eq i32 %117, %126
  br i1 %129, label %130, label %132
130:
  %131 = load <2 x i64>, ptr %128, align 8, !noalias !16
  br label %fmt.float.Backend64_TablesSmall.computePow5.exit.i.i.i.i.i.i
132:
  %133 = sub nsw nuw i32 %117, %126
  %134 = zext nneg i32 %133 to i64
  %135 = getelementptr [8 x i8], ptr @__anon_1423, i64 %134
  %136 = load i64, ptr %135, align 8, !noalias !16
  %137 = zext i64 %136 to i128
  %138 = load i64, ptr %128, align 8, !noalias !16
  %139 = zext i64 %138 to i128
  %140 = mul nuw i128 %139, %137
  %141 = getelementptr i8, ptr %128, i64 8
  %142 = load i64, ptr %141, align 8, !noalias !16
  %143 = zext i64 %142 to i128
  %144 = mul nuw i128 %143, %137
  %145 = zext nneg i16 %narrow.i.i.i.i.i.i to i64
  %146 = mul nsw nuw i64 %145, 163391164108059
  %147 = lshr i64 %146, 46
  %148 = trunc nsw nuw i64 %147 to i32
  %149 = sub nsw i32 %122, %148
  %150 = icmp samesign ult i32 %149, 128
  call void @llvm.assume(i1 %150)
  %151 = trunc nuw i32 %149 to i7
  %152 = shl nsw nuw i32 %117, 1
  %153 = zext nneg i32 %149 to i128
  %154 = lshr i128 %140, %153
  %155 = sub nuw i7 -64, %151
  %156 = zext i7 %155 to i128
  %157 = shl i128 %144, %156
  %158 = lshr i32 %117, 4
  %159 = zext nneg i32 %158 to i64
  %160 = getelementptr [4 x i8], ptr @__anon_1473, i64 %159
  %161 = load i32, ptr %160, align 4, !noalias !16
  %162 = and i32 %152, 30
  %163 = lshr i32 %161, %162
  %164 = and i32 %163, 3
  %165 = zext nneg i32 %164 to i128
  %166 = add nuw i128 %154, 1
  %167 = add nuw i128 %166, %157
  %168 = add nuw i128 %167, %165
  %169 = lshr i128 %168, 64
  %170 = insertelement <2 x i128> poison, i128 %168, i64 0
  %171 = insertelement <2 x i128> %170, i128 %169, i64 1
  %172 = trunc <2 x i128> %171 to <2 x i64>
  br label %fmt.float.Backend64_TablesSmall.computePow5.exit.i.i.i.i.i.i
fmt.float.Backend64_TablesSmall.computePow5.exit.i.i.i.i.i.i:
  %173 = phi <2 x i64> [ %131, %130 ], [ %172, %132 ]
  store <2 x i64> %173, ptr %8, align 16, !noalias !15
  %174 = call fastcc i64 @fmt.float.mulShift64(i64 %29, ptr nonnull readonly align 8 %8, i32 %123), !noalias !15
  %175 = or disjoint i64 %29, 2
  %176 = call fastcc i64 @fmt.float.mulShift64(i64 %175, ptr nonnull readonly align 8 %8, i32 %123), !noalias !15
  %177 = add nsw i64 %29, -1
  %.neg83.i.i.i.i.i.i = sext i1 %31 to i64
  %178 = add nsw i64 %177, %.neg83.i.i.i.i.i.i
  %179 = call fastcc i64 @fmt.float.mulShift64(i64 %178, ptr nonnull readonly align 8 %8, i32 %123), !noalias !15
  %180 = icmp samesign ult i32 %114, 2
  br i1 %180, label %192, label %194
181:
  %182 = urem i64 %29, 5
  %183 = icmp eq i64 %182, 0
  br i1 %183, label %184, label %186
184:
  %185 = call fastcc i1 @fmt.float.multipleOfPowerOf5__anon_1356(i64 %29, i32 %40)
  br label %33
186:
  br i1 %28, label %187, label %189
187:
  %188 = call fastcc i1 @fmt.float.multipleOfPowerOf5__anon_1356(i64 %104, i32 %40)
  br label %33
189:
  %190 = call fastcc i1 @fmt.float.multipleOfPowerOf5__anon_1356(i64 %101, i32 %40)
  %.neg86.i.i.i.i.i.i = sext i1 %190 to i64
  %191 = add i64 %102, %.neg86.i.i.i.i.i.i
  br label %33
192:
  %spec.select88.i.i.i.i.i.i = and i1 %31, %28
  %not..i.i.i.i.i.i = xor i1 %28, 1
  %193 = sext i1 %not..i.i.i.i.i.i to i64
  %spec.select89.i.i.i.i.i.i = add i64 %176, %193
  br label %33
194:
  %195 = icmp samesign ult i32 %114, 63
  br i1 %195, label %196, label %33
196:
  %197 = zext nneg i32 %114 to i64
  %notmask.i.i.i.i.i.i.i = shl nsw i64 -1, %197
  %198 = xor i64 %notmask.i.i.i.i.i.i.i, -1
  %199 = and i64 %29, %198
  %200 = icmp eq i64 %199, 0
  br label %33
201:
  %.074.i.i.i.i.i.i = phi i8 [ 0, %33 ], [ %211, %206 ]
  %.071.i.i.i.i.i.i = phi i32 [ 0, %33 ], [ %213, %206 ]
  %.168.i.i.i.i.i.i = phi i1 [ %.067.i.i.i.i.i.i, %33 ], [ %209, %206 ]
  %.166.i.i.i.i.i.i = phi i1 [ %.065.i.i.i.i.i.i, %33 ], [ %spec.select, %206 ]
  %.161.i.i.i.i.i.i = phi i64 [ %.060.i.i.i.i.i.i, %33 ], [ %203, %206 ]
  %.158.i.i.i.i.i.i = phi i64 [ %.057.i.i.i.i.i.i, %33 ], [ %202, %206 ]
  %.156.i.i.i.i.i.i = phi i64 [ %.055.i.i.i.i.i.i, %33 ], [ %212, %206 ]
  %202 = udiv i64 %.158.i.i.i.i.i.i, 10
  %203 = udiv i64 %.161.i.i.i.i.i.i, 10
  %204 = urem i64 %.161.i.i.i.i.i.i, 10
  %205 = icmp samesign ugt i64 %202, %203
  br i1 %205, label %206, label %214
206:
  %207 = icmp eq i64 %204, 0
  %spec.select = select i1 %.166.i.i.i.i.i.i, i1 %207, i1 0
  %208 = icmp eq i8 %.074.i.i.i.i.i.i, 0
  %209 = select i1 %.168.i.i.i.i.i.i, i1 %208, i1 0
  %210 = urem i64 %.156.i.i.i.i.i.i, 10
  %211 = trunc nsw nuw i64 %210 to i8
  %212 = udiv i64 %.156.i.i.i.i.i.i, 10
  %213 = add nuw i32 %.071.i.i.i.i.i.i, 1
  br label %201
214:
  br i1 %.166.i.i.i.i.i.i, label %.preheader.i.i.i.i.i.i, label %.critedge.i.i.i.i.i.i
.critedge.i.i.i.i.i.i:
  %.175.i.i.i.i.i.i = phi i8 [ %.074.i.i.i.i.i.i, %214 ], [ %.276.i.i.i.i.i.i, %.preheader.i.i.i.i.i.i ]
  %.172.i.i.i.i.i.i = phi i32 [ %.071.i.i.i.i.i.i, %214 ], [ %.273.i.i.i.i.i.i, %.preheader.i.i.i.i.i.i ]
  %.269.i.i.i.i.i.i = phi i1 [ %.168.i.i.i.i.i.i, %214 ], [ %.370.i.i.i.i.i.i, %.preheader.i.i.i.i.i.i ]
  %.262.i.i.i.i.i.i = phi i64 [ %.161.i.i.i.i.i.i, %214 ], [ %.363.i.i.i.i.i.i, %.preheader.i.i.i.i.i.i ]
  %.2.i.i.i.i.i.i = phi i64 [ %.156.i.i.i.i.i.i, %214 ], [ %.3.i.i.i.i.i.i, %.preheader.i.i.i.i.i.i ]
  %215 = icmp eq i8 %.175.i.i.i.i.i.i, 5
  %216 = select i1 %.269.i.i.i.i.i.i, i1 %215, i1 0
  %217 = and i64 %.2.i.i.i.i.i.i, 1
  %218 = icmp eq i64 %217, 0
  %spec.select.i.i.i.i.i.i = select i1 %218, i8 4, i8 5
  %.377.i.i.i.i.i.i = select i1 %216, i8 %spec.select.i.i.i.i.i.i, i8 %.175.i.i.i.i.i.i
  %219 = icmp ne i64 %.2.i.i.i.i.i.i, %.262.i.i.i.i.i.i
  %.not87.i.i.i.i.i.i = select i1 %28, i1 %.166.i.i.i.i.i.i, i1 0
  %or.cond.i.i.i.i.i.i = select i1 %219, i1 1, i1 %.not87.i.i.i.i.i.i
  %220 = icmp samesign ugt i8 %.377.i.i.i.i.i.i, 4
  %not.or.cond.i.i.i.i.i.i = xor i1 %or.cond.i.i.i.i.i.i, 1
  %narrow94.i.i.i.i.i.i = select i1 %not.or.cond.i.i.i.i.i.i, i1 1, i1 %220
  %221 = zext i1 %narrow94.i.i.i.i.i.i to i64
  %222 = add nuw i64 %.2.i.i.i.i.i.i, %221
  %223 = icmp sgt i32 %.172.i.i.i.i.i.i, -1
  call void @llvm.assume(i1 %223)
  %224 = add nsw i32 %.172.i.i.i.i.i.i, %.064.i.i.i.i.i.i
  br label %fmt.float.binaryToDecimal__anon_1143.exit.i.i.i.i.i
.preheader.i.i.i.i.i.i:
  %.276.i.i.i.i.i.i = phi i8 [ %232, %228 ], [ %.074.i.i.i.i.i.i, %214 ]
  %.273.i.i.i.i.i.i = phi i32 [ %234, %228 ], [ %.071.i.i.i.i.i.i, %214 ]
  %.370.i.i.i.i.i.i = phi i1 [ %230, %228 ], [ %.168.i.i.i.i.i.i, %214 ]
  %.363.i.i.i.i.i.i = phi i64 [ %226, %228 ], [ %.161.i.i.i.i.i.i, %214 ]
  %.3.i.i.i.i.i.i = phi i64 [ %233, %228 ], [ %.156.i.i.i.i.i.i, %214 ]
  %225 = urem i64 %.363.i.i.i.i.i.i, 10
  %226 = udiv i64 %.363.i.i.i.i.i.i, 10
  %227 = icmp eq i64 %225, 0
  br i1 %227, label %228, label %.critedge.i.i.i.i.i.i
228:
  %229 = icmp eq i8 %.276.i.i.i.i.i.i, 0
  %230 = select i1 %.370.i.i.i.i.i.i, i1 %229, i1 0
  %231 = urem i64 %.3.i.i.i.i.i.i, 10
  %232 = trunc nsw nuw i64 %231 to i8
  %233 = udiv i64 %.3.i.i.i.i.i.i, 10
  %234 = add nuw i32 %.273.i.i.i.i.i.i, 1
  br label %.preheader.i.i.i.i.i.i
fmt.float.binaryToDecimal__anon_1143.exit.i.i.i.i.i:
  %.sroa.5.0.i.i.i.i.i = phi i32 [ %224, %.critedge.i.i.i.i.i.i ], [ 0, %1 ], [ 2147483647, %22 ]
  %.sroa.014.0.i.i.i.i.i = phi i64 [ %222, %.critedge.i.i.i.i.i.i ], [ 0, %1 ], [ %15, %22 ]
  %235 = icmp slt i64 %13, 0
  store i1 %235, ptr %.sroa.10.i.i.i.i.i, align 4, !alias.scope !9, !noalias !6
  call void @llvm.lifetime.end.p0(ptr nonnull %8), !noalias !6
  call void @llvm.lifetime.end.p0(ptr nonnull %9), !noalias !6
  %236 = trunc i8 %.sroa.314.i.i.i.i.0..sroa.314.i.i.i.i.0..sroa.314.i.i.i.i.0..sroa.314.i.i.i.0..sroa.314.i.i.i.0..sroa.314.i.i.0..sroa.314.i.i.0..sroa.314.i.0..sroa.314.i.0..sroa.314.0..sroa.314.0..sroa.314.16..sroa.3.0.copyload.i.i.i.i.i to i1
  %237 = icmp eq i32 %.sroa.5.0.i.i.i.i.i, 2147483647
  br i1 %236, label %312, label %238
238:
  call void @llvm.lifetime.start.p0(ptr nonnull %6), !noalias !6
  call void @llvm.lifetime.start.p0(ptr nonnull %7), !noalias !6
  %.sroa.10.i.i.i.i.i.0..sroa.10.i.i.i.i.i.0..sroa.10.i.i.i.i.i.0..sroa.10.i.i.i.i.0..sroa.10.i.i.i.i.0..sroa.10.i.i.i.0..sroa.10.i.i.i.0..sroa.10.i.i.0..sroa.10.i.i.0..sroa.10.i.0..sroa.10.i.0..sroa.10.0..sroa.10.0..sroa.10.12..i.i.i.i.i = load i8, ptr %.sroa.10.i.i.i.i.i, align 4, !noalias !19
  br i1 %237, label %239, label %241
239:
  store i64 %.sroa.014.0.i.i.i.i.i, ptr %7, align 8, !noalias !19
  %.sroa.5.0..sroa_idx65.i.i.i.i.i.i = getelementptr i8, ptr %7, i64 8
  store i32 2147483647, ptr %.sroa.5.0..sroa_idx65.i.i.i.i.i.i, align 8, !noalias !19
  %.sroa.7.0..sroa_idx72.i.i.i.i.i.i = getelementptr i8, ptr %7, i64 12
  store i8 %.sroa.10.i.i.i.i.i.0..sroa.10.i.i.i.i.i.0..sroa.10.i.i.i.i.i.0..sroa.10.i.i.i.i.0..sroa.10.i.i.i.i.0..sroa.10.i.i.i.0..sroa.10.i.i.i.0..sroa.10.i.i.0..sroa.10.i.i.0..sroa.10.i.0..sroa.10.i.0..sroa.10.0..sroa.10.0..sroa.10.12..i.i.i.i.i, ptr %.sroa.7.0..sroa_idx72.i.i.i.i.i.i, align 4, !noalias !19
  %240 = call fastcc { ptr, i64 } @fmt.float.copySpecialStr__anon_1179(ptr nonnull %10, ptr nonnull readonly align 8 %7)
  %.elt.i.i.i.i.i.i = extractvalue { ptr, i64 } %240, 0
  %.elt117.i.i.i.i.i.i = extractvalue { ptr, i64 } %240, 1
  br label %Io.Writer.printFloat__anon_1043.exit.thread.i.i.i
241:
  store i64 %.sroa.014.0.i.i.i.i.i, ptr %6, align 8, !noalias !19
  %242 = call fastcc i32 @fmt.float.decimalLength__anon_1195(i64 %.sroa.014.0.i.i.i.i.i)
  %.sroa.7.sroa.0.0..sroa.7.sroa.0.0..sroa.7.sroa.0.0..sroa.7.0..sroa.7.12..i.i.i.i.i.i = trunc i8 %.sroa.10.i.i.i.i.i.0..sroa.10.i.i.i.i.i.0..sroa.10.i.i.i.i.i.0..sroa.10.i.i.i.i.0..sroa.10.i.i.i.i.0..sroa.10.i.i.i.0..sroa.10.i.i.i.0..sroa.10.i.i.0..sroa.10.i.i.0..sroa.10.i.0..sroa.10.i.0..sroa.10.0..sroa.10.0..sroa.10.12..i.i.i.i.i to i1
  br i1 %.sroa.7.sroa.0.0..sroa.7.sroa.0.0..sroa.7.sroa.0.0..sroa.7.0..sroa.7.12..i.i.i.i.i.i, label %243, label %244
243:
  store i8 45, ptr %10, align 1, !noalias !19
  br label %244
244:
  %.0106.i.i.sroa.phi.i.i.i.i = phi ptr [ %.0106.i.i.sroa.gep.i.i.i.i, %243 ], [ %10, %241 ]
  %.0106.i.i.i.i.i.i = phi i64 [ 1, %243 ], [ 0, %241 ]
  %245 = or disjoint i64 %.0106.i.i.i.i.i.i, 2
  %246 = getelementptr [1 x i8], ptr %10, i64 %245
  %247 = add nsw i32 %242, -1
  %248 = zext nneg i32 %247 to i64
  call fastcc void @fmt.float.writeDecimal__anon_1212(ptr nonnull %246, ptr nonnull align 8 %6, i64 %248)
  %249 = load i64, ptr %6, align 8, !noalias !19
  %250 = urem i64 %249, 10
  %251 = trunc nsw nuw i64 %250 to i8
  %252 = or disjoint i8 %251, 48
  store i8 %252, ptr %.0106.i.i.sroa.phi.i.i.i.i, align 1, !noalias !19
  %253 = getelementptr i8, ptr %.0106.i.i.sroa.phi.i.i.i.i, i64 1
  store i8 46, ptr %253, align 1, !noalias !19
  %254 = icmp samesign ugt i32 %242, 1
  %255 = add nsw nuw i64 %245, %248
  %256 = add nsw nuw i64 %.0106.i.i.i.i.i.i, 1
  %.1.i.i.i.i.i.i = select i1 %254, i64 %255, i64 %256
  %257 = getelementptr [1 x i8], ptr %10, i64 %.1.i.i.i.i.i.i
  store i8 101, ptr %257, align 1, !noalias !19
  %258 = add nsw nuw i64 %.1.i.i.i.i.i.i, 1
  %259 = add nsw i32 %242, %.sroa.5.0.i.i.i.i.i
  %260 = add nsw i32 %259, -1
  %261 = icmp slt i32 %259, 1
  br i1 %261, label %308, label %262
262:
  %.3.i3.i.i.i.i.i = phi i64 [ %310, %308 ], [ %258, %244 ]
  %.0.i4.i.i.i.i.i = phi i32 [ %311, %308 ], [ %260, %244 ]
  %263 = icmp samesign ugt i32 %.0.i4.i.i.i.i.i, 999999999
  br i1 %263, label %fmt.float.decimalLength__anon_1308.exit.i.i.i.i.i.i, label %264
264:
  %265 = icmp samesign ugt i32 %.0.i4.i.i.i.i.i, 99999999
  br i1 %265, label %fmt.float.decimalLength__anon_1308.exit.i.i.i.i.i.i, label %266
266:
  %267 = icmp samesign ugt i32 %.0.i4.i.i.i.i.i, 9999999
  br i1 %267, label %fmt.float.decimalLength__anon_1308.exit.i.i.i.i.i.i, label %268
268:
  %269 = icmp samesign ugt i32 %.0.i4.i.i.i.i.i, 999999
  br i1 %269, label %fmt.float.decimalLength__anon_1308.exit.i.i.i.i.i.i, label %270
270:
  %271 = icmp samesign ugt i32 %.0.i4.i.i.i.i.i, 99999
  br i1 %271, label %fmt.float.decimalLength__anon_1308.exit.i.i.i.i.i.i, label %272
272:
  %273 = icmp samesign ugt i32 %.0.i4.i.i.i.i.i, 9999
  br i1 %273, label %fmt.float.decimalLength__anon_1308.exit.i.i.i.i.i.i, label %274
274:
  %275 = icmp samesign ugt i32 %.0.i4.i.i.i.i.i, 999
  br i1 %275, label %fmt.float.decimalLength__anon_1308.exit.i.i.i.i.i.i, label %276
276:
  %277 = icmp samesign ugt i32 %.0.i4.i.i.i.i.i, 99
  br i1 %277, label %fmt.float.decimalLength__anon_1308.exit.i.i.i.i.i.i, label %278
278:
  %279 = icmp samesign ugt i32 %.0.i4.i.i.i.i.i, 9
  %spec.select.i.i.i.i.i.i.i = select i1 %279, i64 2, i64 1
  br label %fmt.float.decimalLength__anon_1308.exit.i.i.i.i.i.i
fmt.float.decimalLength__anon_1308.exit.i.i.i.i.i.i:
  %common.ret.op.i.i.i.i.i.i.i = phi i64 [ 3, %276 ], [ 10, %262 ], [ 9, %264 ], [ 8, %266 ], [ 7, %268 ], [ 6, %270 ], [ 5, %272 ], [ 4, %274 ], [ %spec.select.i.i.i.i.i.i.i, %278 ]
  %280 = getelementptr [1 x i8], ptr %10, i64 %.3.i3.i.i.i.i.i
  br label %281
281:
  %.0120.i.i.i.i.i.i = phi i32 [ %.0.i4.i.i.i.i.i, %fmt.float.decimalLength__anon_1308.exit.i.i.i.i.i.i ], [ %288, %285 ]
  %.0.i.i.i.i.i.i.i = phi i64 [ 0, %fmt.float.decimalLength__anon_1308.exit.i.i.i.i.i.i ], [ %282, %285 ]
  %282 = add nsw nuw i64 %.0.i.i.i.i.i.i.i, 2
  %283 = icmp samesign ult i64 %282, %common.ret.op.i.i.i.i.i.i.i
  br i1 %283, label %285, label %.preheader.i.i.i.i.i.i.i
.preheader.i.i.i.i.i.i.i:
  %284 = getelementptr [1 x i8], ptr %280, i64 %common.ret.op.i.i.i.i.i.i.i
  br label %297
285:
  %286 = urem i32 %.0120.i.i.i.i.i.i, 100
  %287 = trunc nsw nuw i32 %286 to i8
  %288 = udiv i32 %.0120.i.i.i.i.i.i, 100
  %289 = udiv i8 %287, 10
  %290 = or disjoint i8 %289, 48
  %291 = urem i8 %287, 10
  %292 = or disjoint i8 %291, 48
  %293 = sub nsw nuw i64 %common.ret.op.i.i.i.i.i.i.i, %.0.i.i.i.i.i.i.i
  %294 = getelementptr [1 x i8], ptr %280, i64 %293
  %295 = getelementptr i8, ptr %294, i64 -1
  store i8 %292, ptr %295, align 1, !noalias !19
  %296 = getelementptr i8, ptr %294, i64 -2
  store i8 %290, ptr %296, align 1, !noalias !19
  br label %281
297:
  %.1121.i.i.i.i.i.i = phi i32 [ %.0120.i.i.i.i.i.i, %.preheader.i.i.i.i.i.i.i ], [ %302, %299 ]
  %.1.i.i.i.i.i.i.i = phi i64 [ %.0.i.i.i.i.i.i.i, %.preheader.i.i.i.i.i.i.i ], [ %306, %299 ]
  %298 = icmp samesign ult i64 %.1.i.i.i.i.i.i.i, %common.ret.op.i.i.i.i.i.i.i
  br i1 %298, label %299, label %fmt.float.writeDecimal__anon_1310.exit.i.i.i.i.i.i
299:
  %300 = urem i32 %.1121.i.i.i.i.i.i, 10
  %301 = trunc nsw nuw i32 %300 to i8
  %302 = udiv i32 %.1121.i.i.i.i.i.i, 10
  %303 = xor i64 %.1.i.i.i.i.i.i.i, -1
  %304 = getelementptr [1 x i8], ptr %284, i64 %303
  %305 = or disjoint i8 %301, 48
  store i8 %305, ptr %304, align 1, !noalias !19
  %306 = add nsw nuw i64 %.1.i.i.i.i.i.i.i, 1
  br label %297
fmt.float.writeDecimal__anon_1310.exit.i.i.i.i.i.i:
  %307 = add nsw nuw i64 %common.ret.op.i.i.i.i.i.i.i, %.3.i3.i.i.i.i.i
  br label %Io.Writer.printFloat__anon_1043.exit.thread.i.i.i
308:
  %309 = getelementptr [1 x i8], ptr %10, i64 %258
  store i8 45, ptr %309, align 1, !noalias !19
  %310 = add nsw nuw i64 %.1.i.i.i.i.i.i, 2
  %311 = sub nsw i32 1, %259
  br label %262
Io.Writer.printFloat__anon_1043.exit.thread.i.i.i:
  %.sroa.0.0.i.i.i.i = phi ptr [ %.elt.i.i.i.i.i.i, %239 ], [ %10, %fmt.float.writeDecimal__anon_1310.exit.i.i.i.i.i.i ]
  %.sroa.6.0.i.i.i.i = phi i64 [ %.elt117.i.i.i.i.i.i, %239 ], [ %307, %fmt.float.writeDecimal__anon_1310.exit.i.i.i.i.i.i ]
  call void @llvm.lifetime.end.p0(ptr nonnull %6), !noalias !6
  call void @llvm.lifetime.end.p0(ptr nonnull %7), !noalias !6
  br label %Io.Writer.printValue__anon_986.exit.i.i
312:
  call void @llvm.lifetime.start.p0(ptr nonnull %4), !noalias !6
  call void @llvm.lifetime.start.p0(ptr nonnull %5), !noalias !6
  %.sroa.10.i.i.i.i.i.0..sroa.10.i.i.i.i.i.0..sroa.10.i.i.i.i.i.0..sroa.10.i.i.i.i.0..sroa.10.i.i.i.i.0..sroa.10.i.i.i.0..sroa.10.i.i.i.0..sroa.10.i.i.0..sroa.10.i.i.0..sroa.10.i.0..sroa.10.i.0..sroa.10.0..sroa.10.0..sroa.10.12.17.i.i.i.i.i = load i8, ptr %.sroa.10.i.i.i.i.i, align 4, !noalias !22
  br i1 %237, label %313, label %315
313:
  store i64 %.sroa.014.0.i.i.i.i.i, ptr %5, align 8, !noalias !22
  %.sroa.5.0..sroa_idx107.i.i.i.i.i.i = getelementptr i8, ptr %5, i64 8
  store i32 2147483647, ptr %.sroa.5.0..sroa_idx107.i.i.i.i.i.i, align 8, !noalias !22
  %.sroa.10.0..sroa_idx117.i.i.i.i.i.i = getelementptr i8, ptr %5, i64 12
  store i8 %.sroa.10.i.i.i.i.i.0..sroa.10.i.i.i.i.i.0..sroa.10.i.i.i.i.i.0..sroa.10.i.i.i.i.0..sroa.10.i.i.i.i.0..sroa.10.i.i.i.0..sroa.10.i.i.i.0..sroa.10.i.i.0..sroa.10.i.i.0..sroa.10.i.0..sroa.10.i.0..sroa.10.0..sroa.10.0..sroa.10.12.17.i.i.i.i.i, ptr %.sroa.10.0..sroa_idx117.i.i.i.i.i.i, align 4, !noalias !22
  %314 = call fastcc { ptr, i64 } @fmt.float.copySpecialStr__anon_1179(ptr nonnull %10, ptr nonnull readonly align 8 %5)
  %.elt.i13.i.i.i.i.i = extractvalue { ptr, i64 } %314, 0
  %.elt179.i.i.i.i.i.i = extractvalue { ptr, i64 } %314, 1
  br label %Io.Writer.printFloat__anon_1043.exit.thread28.i.i.i
315:
  store i64 %.sroa.014.0.i.i.i.i.i, ptr %4, align 8, !noalias !22
  %316 = call fastcc i32 @fmt.float.decimalLength__anon_1195(i64 %.sroa.014.0.i.i.i.i.i)
  %narrow.i12.i.i.i.i.i = add nuw i32 %.sroa.5.0.i.i.i.i.i, 2
  %317 = zext i32 %narrow.i12.i.i.i.i.i to i64
  %318 = zext nneg i32 %316 to i64
  %319 = add nsw nuw i64 %318, %317
  %320 = sub i32 %316, %.sroa.5.0.i.i.i.i.i
  %321 = zext i32 %320 to i64
  %322 = add nsw nuw i64 %321, 2
  %323 = icmp slt i32 %.sroa.5.0.i.i.i.i.i, 0
  %324 = select i1 %323, i64 %322, i64 %319
  %325 = icmp samesign ugt i64 %324, 347
  br i1 %325, label %353, label %326, !prof !25
326:
  %.sroa.10.sroa.0.0..sroa.10.sroa.0.0..sroa.10.sroa.0.0..sroa.10.0..sroa.10.12..i.i.i.i.i.i = trunc i8 %.sroa.10.i.i.i.i.i.0..sroa.10.i.i.i.i.i.0..sroa.10.i.i.i.i.i.0..sroa.10.i.i.i.i.0..sroa.10.i.i.i.i.0..sroa.10.i.i.i.0..sroa.10.i.i.i.0..sroa.10.i.i.0..sroa.10.i.i.0..sroa.10.i.0..sroa.10.i.0..sroa.10.0..sroa.10.0..sroa.10.12.17.i.i.i.i.i to i1
  br i1 %.sroa.10.sroa.0.0..sroa.10.sroa.0.0..sroa.10.sroa.0.0..sroa.10.0..sroa.10.12..i.i.i.i.i.i, label %330, label %327
327:
  %.0.i9.i.sroa.phi.i.i.i.i = phi ptr [ %.0106.i.i.sroa.gep.i.i.i.i, %330 ], [ %10, %326 ]
  %.0.i9.i.i.i.i.i.sroa.phi = phi ptr [ %.0.i9.i.i.i.i.i.sroa.gep, %330 ], [ %10, %326 ]
  %.0.i9.i.i.i.i.i = phi i64 [ 1, %330 ], [ 0, %326 ]
  %328 = add nsw i32 %316, %.sroa.5.0.i.i.i.i.i
  %329 = icmp slt i32 %328, 1
  br i1 %329, label %331, label %340
330:
  store i8 45, ptr %10, align 1, !noalias !22
  br label %327
331:
  store i8 48, ptr %.0.i9.i.sroa.phi.i.i.i.i, align 1, !noalias !22
  %332 = getelementptr i8, ptr %.0.i9.i.sroa.phi.i.i.i.i, i64 1
  store i8 46, ptr %332, align 1, !noalias !22
  %333 = or disjoint i64 %.0.i9.i.i.i.i.i, 2
  %334 = sub nsw i32 0, %328
  %335 = getelementptr [1 x i8], ptr %10, i64 %333
  %336 = zext nneg i32 %334 to i64
  call void @llvm.memset.p0.i64(ptr nonnull align 1 %335, i8 48, i64 %336, i1 0), !noalias !22
  %337 = add nsw nuw i64 %333, %336
  %338 = getelementptr [1 x i8], ptr %10, i64 %337
  call fastcc void @fmt.float.writeDecimal__anon_1212(ptr nonnull %338, ptr nonnull align 8 %4, i64 %318)
  %339 = add nsw nuw i64 %337, %318
  br label %Io.Writer.printFloat__anon_1043.exit.thread28.i.i.i
340:
  %341 = zext nneg i32 %328 to i64
  %.not170.i.i.i.i.i.i = icmp samesign ult i32 %328, %316
  br i1 %.not170.i.i.i.i.i.i, label %346, label %342
342:
  call fastcc void @fmt.float.writeDecimal__anon_1212(ptr nonnull %.0.i9.i.sroa.phi.i.i.i.i, ptr nonnull align 8 %4, i64 %318)
  %343 = sext i32 %.sroa.5.0.i.i.i.i.i to i64
  %344 = getelementptr [1 x i8], ptr %.0.i9.i.sroa.phi.i.i.i.i, i64 %318
  call void @llvm.memset.p0.i64(ptr nonnull align 1 %344, i8 48, i64 %343, i1 0), !noalias !22
  %345 = add nsw nuw i64 %.0.i9.i.i.i.i.i, %341
  br label %Io.Writer.printFloat__anon_1043.exit.thread28.i.i.i
346:
  %347 = getelementptr [1 x i8], ptr %.0.i9.i.i.i.i.i.sroa.phi, i64 %341
  %348 = getelementptr i8, ptr %347, i64 1
  %349 = sub nsw nuw i64 %318, %341
  call fastcc void @fmt.float.writeDecimal__anon_1212(ptr nonnull %348, ptr nonnull align 8 %4, i64 %349)
  store i8 46, ptr %347, align 1, !noalias !22
  call fastcc void @fmt.float.writeDecimal__anon_1212(ptr nonnull %.0.i9.i.sroa.phi.i.i.i.i, ptr nonnull align 8 %4, i64 %341)
  %350 = add nsw nuw i32 %316, 1
  %351 = zext nneg i32 %350 to i64
  %352 = add nsw nuw i64 %.0.i9.i.i.i.i.i, %351
  br label %Io.Writer.printFloat__anon_1043.exit.thread28.i.i.i
Io.Writer.printFloat__anon_1043.exit.thread28.i.i.i:
  %.sroa.629.0.i.ph.i.i.i = phi i64 [ %352, %346 ], [ %339, %331 ], [ %345, %342 ], [ %.elt179.i.i.i.i.i.i, %313 ]
  %.sroa.028.0.i.ph.i.i.i = phi ptr [ %10, %346 ], [ %10, %331 ], [ %10, %342 ], [ %.elt.i13.i.i.i.i.i, %313 ]
  call void @llvm.lifetime.end.p0(ptr nonnull %4), !noalias !6
  call void @llvm.lifetime.end.p0(ptr nonnull %5), !noalias !6
  br label %Io.Writer.printValue__anon_986.exit.i.i
353:
  call void @llvm.lifetime.end.p0(ptr nonnull %4), !noalias !6
  call void @llvm.lifetime.end.p0(ptr nonnull %5), !noalias !6
  br label %Io.Writer.printValue__anon_986.exit.i.i
Io.Writer.printValue__anon_986.exit.i.i:
  %354 = phi i64 [ 7, %353 ], [ %.sroa.629.0.i.ph.i.i.i, %Io.Writer.printFloat__anon_1043.exit.thread28.i.i.i ], [ %.sroa.6.0.i.i.i.i, %Io.Writer.printFloat__anon_1043.exit.thread.i.i.i ]
  %355 = phi ptr [ @__anon_1089, %353 ], [ %.sroa.028.0.i.ph.i.i.i, %Io.Writer.printFloat__anon_1043.exit.thread28.i.i.i ], [ %.sroa.0.0.i.i.i.i, %Io.Writer.printFloat__anon_1043.exit.thread.i.i.i ]
  call void @llvm.lifetime.end.p0(ptr nonnull %.sroa.10.i.i.i.i.i)
  %.fca.1.gep.i.i.i.i = getelementptr i8, ptr %3, i64 8
  %.sroa.3.0..sroa_idx.i.i.i = getelementptr i8, ptr %2, i64 8
  br label %356
356:
  %.0.i.i.i = phi i64 [ 0, %Io.Writer.printValue__anon_986.exit.i.i ], [ %369, %368 ]
  %.not.not.not.not = icmp ult i64 %.0.i.i.i, %354
  br i1 %.not.not.not.not, label %357, label %fmt.bufPrint__anon_201.exit
357:
  %358 = getelementptr [1 x i8], ptr %355, i64 %.0.i.i.i
  %359 = sub nuw i64 %354, %.0.i.i.i
  call void @llvm.lifetime.start.p0(ptr nonnull %2), !noalias !0
  call void @llvm.lifetime.start.p0(ptr nonnull %3), !noalias !0
  %360 = load i64, ptr %.sroa.4.0..sroa_idx.i, align 8, !noalias !26
  %361 = add nuw i64 %360, %359
  %362 = load i64, ptr %.sroa.3.0..sroa_idx.i, align 8, !noalias !26
  %.not.i.i.i.i = icmp ugt i64 %361, %362
  br i1 %.not.i.i.i.i, label %Io.Writer.write.exit.i.i.i, label %Io.Writer.write.exit.thread.i.i.i, !prof !29
Io.Writer.write.exit.thread.i.i.i:
  %.unpack.i.i.i.i = load ptr, ptr %.sroa.2.0..sroa_idx.i, align 8, !noalias !26
  %363 = getelementptr [1 x i8], ptr %.unpack.i.i.i.i, i64 %360
  call void @llvm.memcpy.p0.p0.i64(ptr align 1 %363, ptr nonnull readonly align 1 %358, i64 %359, i1 0), !noalias !26
  %364 = load i64, ptr %.sroa.4.0..sroa_idx.i, align 8, !noalias !26
  %365 = add nuw i64 %364, %359
  store i64 %365, ptr %.sroa.4.0..sroa_idx.i, align 8, !noalias !26
  call void @llvm.lifetime.end.p0(ptr nonnull %2), !noalias !0
  call void @llvm.lifetime.end.p0(ptr nonnull %3), !noalias !0
  br label %368
Io.Writer.write.exit.i.i.i:
  %366 = load ptr, ptr %11, align 8, !noalias !26
  %367 = load ptr, ptr %366, align 8, !noalias !26
  store ptr %358, ptr %3, align 8, !noalias !26
  store i64 %359, ptr %.fca.1.gep.i.i.i.i, align 8, !noalias !26
  call fastcc void %367(ptr nonnull sret({ i64, i16, [6 x i8] }) %2, ptr nonnull align 8 %11, ptr nonnull readonly align 8 %3, i64 1, i64 1) #14, !noalias !26
  %.sroa.0.0.copyload.i.i.i = load i64, ptr %2, align 8, !noalias !0
  %.sroa.3.0.copyload.i.i.i = load i16, ptr %.sroa.3.0..sroa_idx.i.i.i, align 8, !noalias !0
  call void @llvm.lifetime.end.p0(ptr nonnull %2), !noalias !0
  call void @llvm.lifetime.end.p0(ptr nonnull %3), !noalias !0
  %.not.i.i.i = icmp eq i16 %.sroa.3.0.copyload.i.i.i, 0
  br i1 %.not.i.i.i, label %368, label %fmt.bufPrint__anon_201.exit, !prof !30
368:
  %.sroa.0.011.i.i.i = phi i64 [ %359, %Io.Writer.write.exit.thread.i.i.i ], [ %.sroa.0.0.copyload.i.i.i, %Io.Writer.write.exit.i.i.i ]
  %369 = add nuw i64 %.sroa.0.011.i.i.i, %.0.i.i.i
  br label %356
fmt.bufPrint__anon_201.exit:
  call void @llvm.lifetime.end.p0(ptr nonnull %.sroa.314.i.i.i.i)
  call void @llvm.lifetime.end.p0(ptr nonnull %10), !noalias !0
  call void @llvm.lifetime.end.p0(ptr nonnull %.sroa.67.i.i.i)
  call void @llvm.lifetime.end.p0(ptr nonnull %11)
  ret void
}

define private fastcc void @Io.Writer.unimplementedSendFile(ptr noalias nonnull writeonly sret({ i64, i16, [6 x i8] }) captures(none) initializes((0, 16)) %0, ptr nonnull readnone align 8 captures(none) %1, ptr nonnull readnone align 1 captures(none) %2, i64 %3) unnamed_addr #3 align 1 {
4:
  tail call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 8 dereferenceable(16) %0, ptr noundef nonnull align 8 dereferenceable(16) @__anon_625, i64 16, i1 0)
  ret void
}

define private fastcc noundef i16 @Io.Writer.failingRebase(ptr nonnull readnone align 8 captures(none) %0, i64 %1, i64 %2) unnamed_addr #4 align 1 {
3:
  ret i16 2
}

define private fastcc noundef i16 @Io.Writer.noopFlush(ptr nonnull readnone align 8 captures(none) %0) unnamed_addr #4 align 1 {
1:
  ret i16 0
}

define private fastcc void @Io.Writer.fixedDrain(ptr noalias nonnull writeonly sret({ i64, i16, [6 x i8] }) captures(none) %0, ptr nonnull align 8 captures(none) %1, ptr nonnull readonly align 8 captures(none) %2, i64 %3, i64 %4) unnamed_addr #5 align 1 {
5:
  %6 = icmp eq i64 %3, 0
  br i1 %6, label %7, label %8
common.ret:
  ret void
7:
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 8 dereferenceable(16) %0, i8 0, i64 16, i1 0)
  br label %common.ret
8:
  %9 = add i64 %3, -1
  %10 = getelementptr i8, ptr %1, i64 8
  %11 = getelementptr i8, ptr %1, i64 24
  %.elt90 = getelementptr i8, ptr %1, i64 16
  br label %12
12:
  %.078 = phi i64 [ 0, %8 ], [ %22, %16 ]
  %exitcond.not = icmp eq i64 %.078, %9
  %13 = load i64, ptr %11, align 8
  %.unpack83 = load ptr, ptr %10, align 8
  %.unpack85 = load i64, ptr %.elt90, align 8
  %14 = getelementptr [1 x i8], ptr %.unpack83, i64 %13
  %15 = sub nuw i64 %.unpack85, %13
  br i1 %exitcond.not, label %23, label %16
16:
  %17 = getelementptr [16 x i8], ptr %2, i64 %.078
  %.unpack86 = load ptr, ptr %17, align 8
  %.elt87 = getelementptr i8, ptr %17, i64 8
  %.unpack88 = load i64, ptr %.elt87, align 8
  %18 = tail call i64 @llvm.umin.i64(i64 %.unpack88, i64 %15)
  tail call void @llvm.memcpy.p0.p0.i64(ptr align 1 %14, ptr align 1 %.unpack86, i64 %18, i1 0)
  %19 = load i64, ptr %11, align 8
  %20 = add nuw i64 %19, %18
  store i64 %20, ptr %11, align 8
  %21 = icmp ugt i64 %.unpack88, %15
  %22 = add i64 %.078, 1
  br i1 %21, label %25, label %12
23:
  %24 = getelementptr [16 x i8], ptr %2, i64 %9
  %.unpack = load ptr, ptr %24, align 8
  %.elt81 = getelementptr i8, ptr %24, i64 8
  %.unpack82 = load i64, ptr %.elt81, align 8
  switch i64 %.unpack82, label %.preheader [
    i64 0, label %26
    i64 1, label %27
  ]
25:
  tail call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 8 dereferenceable(16) %0, ptr noundef nonnull align 8 dereferenceable(16) @__anon_633, i64 16, i1 0)
  br label %common.ret
26:
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 8 dereferenceable(16) %0, i8 0, i64 16, i1 0)
  br label %common.ret
27:
  %28 = icmp uge i64 %4, %15
  tail call void @llvm.assume(i1 %28)
  %29 = load i8, ptr %.unpack, align 1
  tail call void @llvm.memset.p0.i64(ptr align 1 %14, i8 %29, i64 %15, i1 0)
  %30 = load i64, ptr %11, align 8
  %31 = add nuw i64 %30, %15
  store i64 %31, ptr %11, align 8
  tail call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 8 dereferenceable(16) %0, ptr noundef nonnull align 8 dereferenceable(16) @__anon_633, i64 16, i1 0)
  br label %common.ret
.preheader:
  %.0 = phi i64 [ %40, %.preheader ], [ 0, %23 ]
  %32 = icmp ult i64 %.0, %4
  tail call void @llvm.assume(i1 %32)
  %33 = mul nuw i64 %.0, %.unpack82
  %34 = getelementptr [1 x i8], ptr %14, i64 %33
  %35 = sub nuw i64 %15, %33
  %36 = tail call i64 @llvm.umin.i64(i64 %.unpack82, i64 %35)
  tail call void @llvm.memcpy.p0.p0.i64(ptr align 1 %34, ptr align 1 %.unpack, i64 %36, i1 0)
  %37 = load i64, ptr %11, align 8
  %38 = add nuw i64 %37, %36
  store i64 %38, ptr %11, align 8
  %39 = icmp ugt i64 %.unpack82, %35
  %40 = add nuw i64 %.0, 1
  br i1 %39, label %41, label %.preheader
41:
  tail call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 8 dereferenceable(16) %0, ptr noundef nonnull align 8 dereferenceable(16) @__anon_633, i64 16, i1 0)
  br label %common.ret
}

define private fastcc void @fmt.float.writeDecimal__anon_1212(ptr nonnull writeonly captures(none) %0, ptr nonnull align 8 captures(none) %1, i64 range(i64 0, 18) %2) unnamed_addr #8 align 1 {
3:
  br label %4
4:
  %.0 = phi i64 [ 0, %3 ], [ %5, %8 ]
  %5 = add nsw nuw i64 %.0, 2
  %6 = icmp samesign ult i64 %5, %2
  br i1 %6, label %8, label %.preheader
.preheader:
  %7 = getelementptr [1 x i8], ptr %0, i64 %2
  br label %21
8:
  %9 = load i64, ptr %1, align 8
  %10 = urem i64 %9, 100
  %11 = trunc nsw nuw i64 %10 to i8
  %12 = udiv i64 %9, 100
  store i64 %12, ptr %1, align 8
  %13 = udiv i8 %11, 10
  %14 = or disjoint i8 %13, 48
  %15 = urem i8 %11, 10
  %16 = or disjoint i8 %15, 48
  %17 = sub nsw nuw i64 %2, %.0
  %18 = getelementptr [1 x i8], ptr %0, i64 %17
  %19 = getelementptr i8, ptr %18, i64 -1
  store i8 %16, ptr %19, align 1
  %20 = getelementptr i8, ptr %18, i64 -2
  store i8 %14, ptr %20, align 1
  br label %4
21:
  %.1 = phi i64 [ %31, %23 ], [ %.0, %.preheader ]
  %22 = icmp samesign ult i64 %.1, %2
  br i1 %22, label %23, label %32
23:
  %24 = load i64, ptr %1, align 8
  %25 = urem i64 %24, 10
  %26 = trunc nsw nuw i64 %25 to i8
  %27 = udiv i64 %24, 10
  store i64 %27, ptr %1, align 8
  %28 = xor i64 %.1, -1
  %29 = getelementptr [1 x i8], ptr %7, i64 %28
  %30 = or disjoint i8 %26, 48
  store i8 %30, ptr %29, align 1
  %31 = add nsw nuw i64 %.1, 1
  br label %21
32:
  ret void
}

define private fastcc range(i32 1, 18) i32 @fmt.float.decimalLength__anon_1195(i64 %0) unnamed_addr #9 align 1 {
1:
  %2 = icmp ult i64 %0, 100000000000000000
  tail call void @llvm.assume(i1 %2)
  %3 = icmp samesign ugt i64 %0, 9999999999999999
  br i1 %3, label %common.ret, label %4
common.ret:
  %common.ret.op = phi i32 [ 3, %30 ], [ 17, %1 ], [ 16, %4 ], [ 15, %6 ], [ 14, %8 ], [ 13, %10 ], [ 12, %12 ], [ 11, %14 ], [ 10, %16 ], [ 9, %18 ], [ 8, %20 ], [ 7, %22 ], [ 6, %24 ], [ 5, %26 ], [ 4, %28 ], [ %spec.select, %32 ]
  ret i32 %common.ret.op
4:
  %5 = icmp samesign ugt i64 %0, 999999999999999
  br i1 %5, label %common.ret, label %6
6:
  %7 = icmp samesign ugt i64 %0, 99999999999999
  br i1 %7, label %common.ret, label %8
8:
  %9 = icmp samesign ugt i64 %0, 9999999999999
  br i1 %9, label %common.ret, label %10
10:
  %11 = icmp samesign ugt i64 %0, 999999999999
  br i1 %11, label %common.ret, label %12
12:
  %13 = icmp samesign ugt i64 %0, 99999999999
  br i1 %13, label %common.ret, label %14
14:
  %15 = icmp samesign ugt i64 %0, 9999999999
  br i1 %15, label %common.ret, label %16
16:
  %17 = icmp samesign ugt i64 %0, 999999999
  br i1 %17, label %common.ret, label %18
18:
  %19 = icmp samesign ugt i64 %0, 99999999
  br i1 %19, label %common.ret, label %20
20:
  %21 = icmp samesign ugt i64 %0, 9999999
  br i1 %21, label %common.ret, label %22
22:
  %23 = icmp samesign ugt i64 %0, 999999
  br i1 %23, label %common.ret, label %24
24:
  %25 = icmp samesign ugt i64 %0, 99999
  br i1 %25, label %common.ret, label %26
26:
  %27 = icmp samesign ugt i64 %0, 9999
  br i1 %27, label %common.ret, label %28
28:
  %29 = icmp samesign ugt i64 %0, 999
  br i1 %29, label %common.ret, label %30
30:
  %31 = icmp samesign ugt i64 %0, 99
  br i1 %31, label %common.ret, label %32
32:
  %33 = icmp samesign ugt i64 %0, 9
  %spec.select = select i1 %33, i32 2, i32 1
  br label %common.ret
}

define private fastcc { ptr, i64 } @fmt.float.copySpecialStr__anon_1179(ptr nonnull %0, ptr nonnull readonly align 8 captures(none) %1) unnamed_addr #3 align 1 {
2:
  %.sroa.031.0.copyload = load i64, ptr %1, align 8
  %.sroa.232.0..sroa_idx = getelementptr i8, ptr %1, i64 12
  %3 = load i8, ptr %.sroa.232.0..sroa_idx, align 4
  %4 = trunc i8 %3 to i1
  br i1 %4, label %8, label %5
5:
  %.mask = and i8 %3, 1
  %6 = zext nneg i8 %.mask to i64
  %.not = icmp eq i64 %.sroa.031.0.copyload, 0
  %7 = getelementptr [1 x i8], ptr %0, i64 %6
  br i1 %.not, label %12, label %11
8:
  store i8 45, ptr %0, align 1
  br label %5
common.ret:
  %9 = select i1 %4, i64 4, i64 3
  %10 = insertvalue { ptr, i64 } poison, ptr %0, 0
  %common.ret.op = insertvalue { ptr, i64 } %10, i64 %9, 1
  ret { ptr, i64 } %common.ret.op
11:
  tail call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 1 dereferenceable(3) %7, ptr noundef nonnull align 1 dereferenceable(3) @__anon_1295, i64 3, i1 0)
  br label %common.ret
12:
  tail call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 1 dereferenceable(3) %7, ptr noundef nonnull align 1 dereferenceable(3) @__anon_1297, i64 3, i1 0)
  br label %common.ret
}

define private fastcc i1 @fmt.float.multipleOfPowerOf5__anon_1356(i64 range(i64 0, 36028797018963967) %0, i32 range(i32 0, 22) %1) unnamed_addr #10 align 1 {
2:
  br label %3
3:
  %.05.i = phi i64 [ %0, %2 ], [ %6, %7 ]
  %.0.i = phi i32 [ 0, %2 ], [ %8, %7 ]
  %.not.i = icmp eq i64 %.05.i, 0
  br i1 %.not.i, label %fmt.float.pow5Factor__anon_1481.exit, label %4
4:
  %5 = urem i64 %.05.i, 5
  %6 = udiv i64 %.05.i, 5
  %.not6.i = icmp eq i64 %5, 0
  br i1 %.not6.i, label %7, label %fmt.float.pow5Factor__anon_1481.exit
7:
  %8 = add nuw i32 %.0.i, 1
  br label %3
fmt.float.pow5Factor__anon_1481.exit:
  %common.ret.op.i = phi i32 [ 0, %3 ], [ %.0.i, %4 ]
  %9 = icmp uge i32 %common.ret.op.i, %1
  ret i1 %9
}

define private fastcc i64 @fmt.float.mulShift64(i64 range(i64 0, 36028797018963967) %0, ptr nonnull readonly align 8 captures(none) %1, i32 range(i32 0, -2147483648) %2) unnamed_addr #11 align 1 {
3:
  %4 = icmp samesign ugt i32 %2, 64
  tail call void @llvm.assume(i1 %4)
  %5 = icmp samesign ult i32 %2, 128
  br i1 %5, label %6, label %common.ret
common.ret:
  %common.ret.op = phi i64 [ %22, %6 ], [ 0, %3 ]
  ret i64 %common.ret.op
6:
  %7 = zext nneg i64 %0 to i128
  %8 = getelementptr i8, ptr %1, i64 8
  %9 = load i64, ptr %8, align 8
  %10 = zext i64 %9 to i128
  %11 = mul nsw nuw i128 %10, %7
  %12 = load i64, ptr %1, align 8
  %13 = zext i64 %12 to i128
  %14 = mul nsw nuw i128 %13, %7
  %15 = lshr i128 %14, 64
  %16 = add nsw nuw i128 %15, %11
  %17 = trunc nuw i32 %2 to i7
  %18 = and i7 %17, 63
  %19 = zext nneg i7 %18 to i128
  %20 = lshr i128 %16, %19
  %21 = icmp samesign ult i128 %20, 18446744073709551616
  tail call void @llvm.assume(i1 %21)
  %22 = trunc nuw i128 %20 to i64
  br label %common.ret
}

attributes #0 = { minsize nounwind optsize uwtable "frame-pointer"="all" "target-cpu"="x86-64" "target-features"="+64bit,+cmov,+cx8,+fxsr,+idivq-to-divl,+macrofusion,+mmx,+nopl,+slow-3ops-lea,+slow-incdec,+sse,+sse2,+vzeroupper,+x87,-16bit-mode,-32bit-mode,-adx,-aes,-allow-light-256-bit,-amx-avx512,-amx-bf16,-amx-complex,-amx-fp16,-amx-fp8,-amx-int8,-amx-movrs,-amx-tf32,-amx-tile,-avx,-avx10.1,-avx10.2,-avx2,-avx512bf16,-avx512bitalg,-avx512bw,-avx512cd,-avx512dq,-avx512f,-avx512fp16,-avx512ifma,-avx512vbmi,-avx512vbmi2,-avx512vl,-avx512vnni,-avx512vp2intersect,-avx512vpopcntdq,-avxifma,-avxneconvert,-avxvnni,-avxvnniint16,-avxvnniint8,-bmi,-bmi2,-branch-hint,-branchfusion,-ccmp,-cf,-cldemote,-clflushopt,-clwb,-clzero,-cmpccxadd,-crc32,-cx16,-egpr,-enqcmd,-ermsb,-f16c,-false-deps-getmant,-false-deps-lzcnt-tzcnt,-false-deps-mulc,-false-deps-mullq,-false-deps-perm,-false-deps-popcnt,-false-deps-range,-fast-11bytenop,-fast-15bytenop,-fast-7bytenop,-fast-bextr,-fast-dpwssd,-fast-gather,-fast-hops,-fast-imm16,-fast-lzcnt,-fast-movbe,-fast-scalar-fsqrt,-fast-scalar-shift-masks,-fast-shld-rotate,-fast-variable-crosslane-shuffle,-fast-variable-perlane-shuffle,-fast-vector-fsqrt,-fast-vector-shift-masks,-faster-shift-than-shuffle,-fma,-fma4,-fsgsbase,-fsrm,-gfni,-harden-sls-ijmp,-harden-sls-ret,-hreset,-idivl-to-divb,-inline-asm-use-gpr32,-invpcid,-kl,-lea-sp,-lea-uses-ag,-lvi-cfi,-lvi-load-hardening,-lwp,-lzcnt,-movbe,-movdir64b,-movdiri,-movrs,-mwaitx,-ndd,-nf,-no-bypass-delay,-no-bypass-delay-blend,-no-bypass-delay-mov,-no-bypass-delay-shuffle,-pad-short-functions,-pclmul,-pconfig,-pku,-popcnt,-ppx,-prefer-128-bit,-prefer-256-bit,-prefer-legacy-setcc,-prefer-mask-registers,-prefer-movmsk-over-vtest,-prefer-no-gather,-prefer-no-scatter,-prefetchi,-prfchw,-ptwrite,-push2pop2,-raoint,-rdpid,-rdpru,-rdrnd,-rdseed,-retpoline,-retpoline-external-thunk,-retpoline-indirect-branches,-retpoline-indirect-calls,-rtm,-sahf,-sbb-dep-breaking,-serialize,-seses,-sgx,-sha,-sha512,-shstk,-slow-lea,-slow-pmaddwd,-slow-pmulld,-slow-pmullq,-slow-shld,-slow-two-mem-ops,-slow-unaligned-mem-16,-slow-unaligned-mem-32,-sm3,-sm4,-soft-float,-sse3,-sse4.1,-sse4.2,-sse4a,-sse-unaligned-mem,-ssse3,-tagged-globals,-tbm,-tsxldtrk,-tuning-fast-imm-vector-shift,-uintr,-use-glm-div-sqrt-costs,-use-slm-arith-costs,-usermsr,-vaes,-vpclmulqdq,-waitpkg,-wbnoinvd,-widekl,-xop,-xsave,-xsavec,-xsaveopt,-xsaves,-zu" }
attributes #1 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: write) }
attributes #2 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite) }
attributes #3 = { minsize mustprogress nofree norecurse nosync nounwind optsize willreturn memory(argmem: readwrite) uwtable "frame-pointer"="all" "target-cpu"="x86-64" "target-features"="+64bit,+cmov,+cx8,+fxsr,+idivq-to-divl,+macrofusion,+mmx,+nopl,+slow-3ops-lea,+slow-incdec,+sse,+sse2,+vzeroupper,+x87,-16bit-mode,-32bit-mode,-adx,-aes,-allow-light-256-bit,-amx-avx512,-amx-bf16,-amx-complex,-amx-fp16,-amx-fp8,-amx-int8,-amx-movrs,-amx-tf32,-amx-tile,-avx,-avx10.1,-avx10.2,-avx2,-avx512bf16,-avx512bitalg,-avx512bw,-avx512cd,-avx512dq,-avx512f,-avx512fp16,-avx512ifma,-avx512vbmi,-avx512vbmi2,-avx512vl,-avx512vnni,-avx512vp2intersect,-avx512vpopcntdq,-avxifma,-avxneconvert,-avxvnni,-avxvnniint16,-avxvnniint8,-bmi,-bmi2,-branch-hint,-branchfusion,-ccmp,-cf,-cldemote,-clflushopt,-clwb,-clzero,-cmpccxadd,-crc32,-cx16,-egpr,-enqcmd,-ermsb,-f16c,-false-deps-getmant,-false-deps-lzcnt-tzcnt,-false-deps-mulc,-false-deps-mullq,-false-deps-perm,-false-deps-popcnt,-false-deps-range,-fast-11bytenop,-fast-15bytenop,-fast-7bytenop,-fast-bextr,-fast-dpwssd,-fast-gather,-fast-hops,-fast-imm16,-fast-lzcnt,-fast-movbe,-fast-scalar-fsqrt,-fast-scalar-shift-masks,-fast-shld-rotate,-fast-variable-crosslane-shuffle,-fast-variable-perlane-shuffle,-fast-vector-fsqrt,-fast-vector-shift-masks,-faster-shift-than-shuffle,-fma,-fma4,-fsgsbase,-fsrm,-gfni,-harden-sls-ijmp,-harden-sls-ret,-hreset,-idivl-to-divb,-inline-asm-use-gpr32,-invpcid,-kl,-lea-sp,-lea-uses-ag,-lvi-cfi,-lvi-load-hardening,-lwp,-lzcnt,-movbe,-movdir64b,-movdiri,-movrs,-mwaitx,-ndd,-nf,-no-bypass-delay,-no-bypass-delay-blend,-no-bypass-delay-mov,-no-bypass-delay-shuffle,-pad-short-functions,-pclmul,-pconfig,-pku,-popcnt,-ppx,-prefer-128-bit,-prefer-256-bit,-prefer-legacy-setcc,-prefer-mask-registers,-prefer-movmsk-over-vtest,-prefer-no-gather,-prefer-no-scatter,-prefetchi,-prfchw,-ptwrite,-push2pop2,-raoint,-rdpid,-rdpru,-rdrnd,-rdseed,-retpoline,-retpoline-external-thunk,-retpoline-indirect-branches,-retpoline-indirect-calls,-rtm,-sahf,-sbb-dep-breaking,-serialize,-seses,-sgx,-sha,-sha512,-shstk,-slow-lea,-slow-pmaddwd,-slow-pmulld,-slow-pmullq,-slow-shld,-slow-two-mem-ops,-slow-unaligned-mem-16,-slow-unaligned-mem-32,-sm3,-sm4,-soft-float,-sse3,-sse4.1,-sse4.2,-sse4a,-sse-unaligned-mem,-ssse3,-tagged-globals,-tbm,-tsxldtrk,-tuning-fast-imm-vector-shift,-uintr,-use-glm-div-sqrt-costs,-use-slm-arith-costs,-usermsr,-vaes,-vpclmulqdq,-waitpkg,-wbnoinvd,-widekl,-xop,-xsave,-xsavec,-xsaveopt,-xsaves,-zu" }
attributes #4 = { minsize mustprogress nofree norecurse nosync nounwind optsize willreturn memory(none) uwtable "frame-pointer"="all" "target-cpu"="x86-64" "target-features"="+64bit,+cmov,+cx8,+fxsr,+idivq-to-divl,+macrofusion,+mmx,+nopl,+slow-3ops-lea,+slow-incdec,+sse,+sse2,+vzeroupper,+x87,-16bit-mode,-32bit-mode,-adx,-aes,-allow-light-256-bit,-amx-avx512,-amx-bf16,-amx-complex,-amx-fp16,-amx-fp8,-amx-int8,-amx-movrs,-amx-tf32,-amx-tile,-avx,-avx10.1,-avx10.2,-avx2,-avx512bf16,-avx512bitalg,-avx512bw,-avx512cd,-avx512dq,-avx512f,-avx512fp16,-avx512ifma,-avx512vbmi,-avx512vbmi2,-avx512vl,-avx512vnni,-avx512vp2intersect,-avx512vpopcntdq,-avxifma,-avxneconvert,-avxvnni,-avxvnniint16,-avxvnniint8,-bmi,-bmi2,-branch-hint,-branchfusion,-ccmp,-cf,-cldemote,-clflushopt,-clwb,-clzero,-cmpccxadd,-crc32,-cx16,-egpr,-enqcmd,-ermsb,-f16c,-false-deps-getmant,-false-deps-lzcnt-tzcnt,-false-deps-mulc,-false-deps-mullq,-false-deps-perm,-false-deps-popcnt,-false-deps-range,-fast-11bytenop,-fast-15bytenop,-fast-7bytenop,-fast-bextr,-fast-dpwssd,-fast-gather,-fast-hops,-fast-imm16,-fast-lzcnt,-fast-movbe,-fast-scalar-fsqrt,-fast-scalar-shift-masks,-fast-shld-rotate,-fast-variable-crosslane-shuffle,-fast-variable-perlane-shuffle,-fast-vector-fsqrt,-fast-vector-shift-masks,-faster-shift-than-shuffle,-fma,-fma4,-fsgsbase,-fsrm,-gfni,-harden-sls-ijmp,-harden-sls-ret,-hreset,-idivl-to-divb,-inline-asm-use-gpr32,-invpcid,-kl,-lea-sp,-lea-uses-ag,-lvi-cfi,-lvi-load-hardening,-lwp,-lzcnt,-movbe,-movdir64b,-movdiri,-movrs,-mwaitx,-ndd,-nf,-no-bypass-delay,-no-bypass-delay-blend,-no-bypass-delay-mov,-no-bypass-delay-shuffle,-pad-short-functions,-pclmul,-pconfig,-pku,-popcnt,-ppx,-prefer-128-bit,-prefer-256-bit,-prefer-legacy-setcc,-prefer-mask-registers,-prefer-movmsk-over-vtest,-prefer-no-gather,-prefer-no-scatter,-prefetchi,-prfchw,-ptwrite,-push2pop2,-raoint,-rdpid,-rdpru,-rdrnd,-rdseed,-retpoline,-retpoline-external-thunk,-retpoline-indirect-branches,-retpoline-indirect-calls,-rtm,-sahf,-sbb-dep-breaking,-serialize,-seses,-sgx,-sha,-sha512,-shstk,-slow-lea,-slow-pmaddwd,-slow-pmulld,-slow-pmullq,-slow-shld,-slow-two-mem-ops,-slow-unaligned-mem-16,-slow-unaligned-mem-32,-sm3,-sm4,-soft-float,-sse3,-sse4.1,-sse4.2,-sse4a,-sse-unaligned-mem,-ssse3,-tagged-globals,-tbm,-tsxldtrk,-tuning-fast-imm-vector-shift,-uintr,-use-glm-div-sqrt-costs,-use-slm-arith-costs,-usermsr,-vaes,-vpclmulqdq,-waitpkg,-wbnoinvd,-widekl,-xop,-xsave,-xsavec,-xsaveopt,-xsaves,-zu" }
attributes #5 = { minsize nofree norecurse nosync nounwind optsize memory(readwrite, inaccessiblemem: write, target_mem0: none, target_mem1: none) uwtable "frame-pointer"="all" "target-cpu"="x86-64" "target-features"="+64bit,+cmov,+cx8,+fxsr,+idivq-to-divl,+macrofusion,+mmx,+nopl,+slow-3ops-lea,+slow-incdec,+sse,+sse2,+vzeroupper,+x87,-16bit-mode,-32bit-mode,-adx,-aes,-allow-light-256-bit,-amx-avx512,-amx-bf16,-amx-complex,-amx-fp16,-amx-fp8,-amx-int8,-amx-movrs,-amx-tf32,-amx-tile,-avx,-avx10.1,-avx10.2,-avx2,-avx512bf16,-avx512bitalg,-avx512bw,-avx512cd,-avx512dq,-avx512f,-avx512fp16,-avx512ifma,-avx512vbmi,-avx512vbmi2,-avx512vl,-avx512vnni,-avx512vp2intersect,-avx512vpopcntdq,-avxifma,-avxneconvert,-avxvnni,-avxvnniint16,-avxvnniint8,-bmi,-bmi2,-branch-hint,-branchfusion,-ccmp,-cf,-cldemote,-clflushopt,-clwb,-clzero,-cmpccxadd,-crc32,-cx16,-egpr,-enqcmd,-ermsb,-f16c,-false-deps-getmant,-false-deps-lzcnt-tzcnt,-false-deps-mulc,-false-deps-mullq,-false-deps-perm,-false-deps-popcnt,-false-deps-range,-fast-11bytenop,-fast-15bytenop,-fast-7bytenop,-fast-bextr,-fast-dpwssd,-fast-gather,-fast-hops,-fast-imm16,-fast-lzcnt,-fast-movbe,-fast-scalar-fsqrt,-fast-scalar-shift-masks,-fast-shld-rotate,-fast-variable-crosslane-shuffle,-fast-variable-perlane-shuffle,-fast-vector-fsqrt,-fast-vector-shift-masks,-faster-shift-than-shuffle,-fma,-fma4,-fsgsbase,-fsrm,-gfni,-harden-sls-ijmp,-harden-sls-ret,-hreset,-idivl-to-divb,-inline-asm-use-gpr32,-invpcid,-kl,-lea-sp,-lea-uses-ag,-lvi-cfi,-lvi-load-hardening,-lwp,-lzcnt,-movbe,-movdir64b,-movdiri,-movrs,-mwaitx,-ndd,-nf,-no-bypass-delay,-no-bypass-delay-blend,-no-bypass-delay-mov,-no-bypass-delay-shuffle,-pad-short-functions,-pclmul,-pconfig,-pku,-popcnt,-ppx,-prefer-128-bit,-prefer-256-bit,-prefer-legacy-setcc,-prefer-mask-registers,-prefer-movmsk-over-vtest,-prefer-no-gather,-prefer-no-scatter,-prefetchi,-prfchw,-ptwrite,-push2pop2,-raoint,-rdpid,-rdpru,-rdrnd,-rdseed,-retpoline,-retpoline-external-thunk,-retpoline-indirect-branches,-retpoline-indirect-calls,-rtm,-sahf,-sbb-dep-breaking,-serialize,-seses,-sgx,-sha,-sha512,-shstk,-slow-lea,-slow-pmaddwd,-slow-pmulld,-slow-pmullq,-slow-shld,-slow-two-mem-ops,-slow-unaligned-mem-16,-slow-unaligned-mem-32,-sm3,-sm4,-soft-float,-sse3,-sse4.1,-sse4.2,-sse4a,-sse-unaligned-mem,-ssse3,-tagged-globals,-tbm,-tsxldtrk,-tuning-fast-imm-vector-shift,-uintr,-use-glm-div-sqrt-costs,-use-slm-arith-costs,-usermsr,-vaes,-vpclmulqdq,-waitpkg,-wbnoinvd,-widekl,-xop,-xsave,-xsavec,-xsaveopt,-xsaves,-zu" }
attributes #6 = { mustprogress nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none) }
attributes #7 = { mustprogress nocallback nofree nosync nounwind willreturn memory(inaccessiblemem: write) }
attributes #8 = { minsize nofree norecurse nosync nounwind optsize memory(argmem: readwrite) uwtable "frame-pointer"="all" "target-cpu"="x86-64" "target-features"="+64bit,+cmov,+cx8,+fxsr,+idivq-to-divl,+macrofusion,+mmx,+nopl,+slow-3ops-lea,+slow-incdec,+sse,+sse2,+vzeroupper,+x87,-16bit-mode,-32bit-mode,-adx,-aes,-allow-light-256-bit,-amx-avx512,-amx-bf16,-amx-complex,-amx-fp16,-amx-fp8,-amx-int8,-amx-movrs,-amx-tf32,-amx-tile,-avx,-avx10.1,-avx10.2,-avx2,-avx512bf16,-avx512bitalg,-avx512bw,-avx512cd,-avx512dq,-avx512f,-avx512fp16,-avx512ifma,-avx512vbmi,-avx512vbmi2,-avx512vl,-avx512vnni,-avx512vp2intersect,-avx512vpopcntdq,-avxifma,-avxneconvert,-avxvnni,-avxvnniint16,-avxvnniint8,-bmi,-bmi2,-branch-hint,-branchfusion,-ccmp,-cf,-cldemote,-clflushopt,-clwb,-clzero,-cmpccxadd,-crc32,-cx16,-egpr,-enqcmd,-ermsb,-f16c,-false-deps-getmant,-false-deps-lzcnt-tzcnt,-false-deps-mulc,-false-deps-mullq,-false-deps-perm,-false-deps-popcnt,-false-deps-range,-fast-11bytenop,-fast-15bytenop,-fast-7bytenop,-fast-bextr,-fast-dpwssd,-fast-gather,-fast-hops,-fast-imm16,-fast-lzcnt,-fast-movbe,-fast-scalar-fsqrt,-fast-scalar-shift-masks,-fast-shld-rotate,-fast-variable-crosslane-shuffle,-fast-variable-perlane-shuffle,-fast-vector-fsqrt,-fast-vector-shift-masks,-faster-shift-than-shuffle,-fma,-fma4,-fsgsbase,-fsrm,-gfni,-harden-sls-ijmp,-harden-sls-ret,-hreset,-idivl-to-divb,-inline-asm-use-gpr32,-invpcid,-kl,-lea-sp,-lea-uses-ag,-lvi-cfi,-lvi-load-hardening,-lwp,-lzcnt,-movbe,-movdir64b,-movdiri,-movrs,-mwaitx,-ndd,-nf,-no-bypass-delay,-no-bypass-delay-blend,-no-bypass-delay-mov,-no-bypass-delay-shuffle,-pad-short-functions,-pclmul,-pconfig,-pku,-popcnt,-ppx,-prefer-128-bit,-prefer-256-bit,-prefer-legacy-setcc,-prefer-mask-registers,-prefer-movmsk-over-vtest,-prefer-no-gather,-prefer-no-scatter,-prefetchi,-prfchw,-ptwrite,-push2pop2,-raoint,-rdpid,-rdpru,-rdrnd,-rdseed,-retpoline,-retpoline-external-thunk,-retpoline-indirect-branches,-retpoline-indirect-calls,-rtm,-sahf,-sbb-dep-breaking,-serialize,-seses,-sgx,-sha,-sha512,-shstk,-slow-lea,-slow-pmaddwd,-slow-pmulld,-slow-pmullq,-slow-shld,-slow-two-mem-ops,-slow-unaligned-mem-16,-slow-unaligned-mem-32,-sm3,-sm4,-soft-float,-sse3,-sse4.1,-sse4.2,-sse4a,-sse-unaligned-mem,-ssse3,-tagged-globals,-tbm,-tsxldtrk,-tuning-fast-imm-vector-shift,-uintr,-use-glm-div-sqrt-costs,-use-slm-arith-costs,-usermsr,-vaes,-vpclmulqdq,-waitpkg,-wbnoinvd,-widekl,-xop,-xsave,-xsavec,-xsaveopt,-xsaves,-zu" }
attributes #9 = { minsize mustprogress nofree norecurse nosync nounwind optsize willreturn memory(inaccessiblemem: write) uwtable "frame-pointer"="all" "target-cpu"="x86-64" "target-features"="+64bit,+cmov,+cx8,+fxsr,+idivq-to-divl,+macrofusion,+mmx,+nopl,+slow-3ops-lea,+slow-incdec,+sse,+sse2,+vzeroupper,+x87,-16bit-mode,-32bit-mode,-adx,-aes,-allow-light-256-bit,-amx-avx512,-amx-bf16,-amx-complex,-amx-fp16,-amx-fp8,-amx-int8,-amx-movrs,-amx-tf32,-amx-tile,-avx,-avx10.1,-avx10.2,-avx2,-avx512bf16,-avx512bitalg,-avx512bw,-avx512cd,-avx512dq,-avx512f,-avx512fp16,-avx512ifma,-avx512vbmi,-avx512vbmi2,-avx512vl,-avx512vnni,-avx512vp2intersect,-avx512vpopcntdq,-avxifma,-avxneconvert,-avxvnni,-avxvnniint16,-avxvnniint8,-bmi,-bmi2,-branch-hint,-branchfusion,-ccmp,-cf,-cldemote,-clflushopt,-clwb,-clzero,-cmpccxadd,-crc32,-cx16,-egpr,-enqcmd,-ermsb,-f16c,-false-deps-getmant,-false-deps-lzcnt-tzcnt,-false-deps-mulc,-false-deps-mullq,-false-deps-perm,-false-deps-popcnt,-false-deps-range,-fast-11bytenop,-fast-15bytenop,-fast-7bytenop,-fast-bextr,-fast-dpwssd,-fast-gather,-fast-hops,-fast-imm16,-fast-lzcnt,-fast-movbe,-fast-scalar-fsqrt,-fast-scalar-shift-masks,-fast-shld-rotate,-fast-variable-crosslane-shuffle,-fast-variable-perlane-shuffle,-fast-vector-fsqrt,-fast-vector-shift-masks,-faster-shift-than-shuffle,-fma,-fma4,-fsgsbase,-fsrm,-gfni,-harden-sls-ijmp,-harden-sls-ret,-hreset,-idivl-to-divb,-inline-asm-use-gpr32,-invpcid,-kl,-lea-sp,-lea-uses-ag,-lvi-cfi,-lvi-load-hardening,-lwp,-lzcnt,-movbe,-movdir64b,-movdiri,-movrs,-mwaitx,-ndd,-nf,-no-bypass-delay,-no-bypass-delay-blend,-no-bypass-delay-mov,-no-bypass-delay-shuffle,-pad-short-functions,-pclmul,-pconfig,-pku,-popcnt,-ppx,-prefer-128-bit,-prefer-256-bit,-prefer-legacy-setcc,-prefer-mask-registers,-prefer-movmsk-over-vtest,-prefer-no-gather,-prefer-no-scatter,-prefetchi,-prfchw,-ptwrite,-push2pop2,-raoint,-rdpid,-rdpru,-rdrnd,-rdseed,-retpoline,-retpoline-external-thunk,-retpoline-indirect-branches,-retpoline-indirect-calls,-rtm,-sahf,-sbb-dep-breaking,-serialize,-seses,-sgx,-sha,-sha512,-shstk,-slow-lea,-slow-pmaddwd,-slow-pmulld,-slow-pmullq,-slow-shld,-slow-two-mem-ops,-slow-unaligned-mem-16,-slow-unaligned-mem-32,-sm3,-sm4,-soft-float,-sse3,-sse4.1,-sse4.2,-sse4a,-sse-unaligned-mem,-ssse3,-tagged-globals,-tbm,-tsxldtrk,-tuning-fast-imm-vector-shift,-uintr,-use-glm-div-sqrt-costs,-use-slm-arith-costs,-usermsr,-vaes,-vpclmulqdq,-waitpkg,-wbnoinvd,-widekl,-xop,-xsave,-xsavec,-xsaveopt,-xsaves,-zu" }
attributes #10 = { minsize nofree norecurse nosync nounwind optsize memory(none) uwtable "frame-pointer"="all" "target-cpu"="x86-64" "target-features"="+64bit,+cmov,+cx8,+fxsr,+idivq-to-divl,+macrofusion,+mmx,+nopl,+slow-3ops-lea,+slow-incdec,+sse,+sse2,+vzeroupper,+x87,-16bit-mode,-32bit-mode,-adx,-aes,-allow-light-256-bit,-amx-avx512,-amx-bf16,-amx-complex,-amx-fp16,-amx-fp8,-amx-int8,-amx-movrs,-amx-tf32,-amx-tile,-avx,-avx10.1,-avx10.2,-avx2,-avx512bf16,-avx512bitalg,-avx512bw,-avx512cd,-avx512dq,-avx512f,-avx512fp16,-avx512ifma,-avx512vbmi,-avx512vbmi2,-avx512vl,-avx512vnni,-avx512vp2intersect,-avx512vpopcntdq,-avxifma,-avxneconvert,-avxvnni,-avxvnniint16,-avxvnniint8,-bmi,-bmi2,-branch-hint,-branchfusion,-ccmp,-cf,-cldemote,-clflushopt,-clwb,-clzero,-cmpccxadd,-crc32,-cx16,-egpr,-enqcmd,-ermsb,-f16c,-false-deps-getmant,-false-deps-lzcnt-tzcnt,-false-deps-mulc,-false-deps-mullq,-false-deps-perm,-false-deps-popcnt,-false-deps-range,-fast-11bytenop,-fast-15bytenop,-fast-7bytenop,-fast-bextr,-fast-dpwssd,-fast-gather,-fast-hops,-fast-imm16,-fast-lzcnt,-fast-movbe,-fast-scalar-fsqrt,-fast-scalar-shift-masks,-fast-shld-rotate,-fast-variable-crosslane-shuffle,-fast-variable-perlane-shuffle,-fast-vector-fsqrt,-fast-vector-shift-masks,-faster-shift-than-shuffle,-fma,-fma4,-fsgsbase,-fsrm,-gfni,-harden-sls-ijmp,-harden-sls-ret,-hreset,-idivl-to-divb,-inline-asm-use-gpr32,-invpcid,-kl,-lea-sp,-lea-uses-ag,-lvi-cfi,-lvi-load-hardening,-lwp,-lzcnt,-movbe,-movdir64b,-movdiri,-movrs,-mwaitx,-ndd,-nf,-no-bypass-delay,-no-bypass-delay-blend,-no-bypass-delay-mov,-no-bypass-delay-shuffle,-pad-short-functions,-pclmul,-pconfig,-pku,-popcnt,-ppx,-prefer-128-bit,-prefer-256-bit,-prefer-legacy-setcc,-prefer-mask-registers,-prefer-movmsk-over-vtest,-prefer-no-gather,-prefer-no-scatter,-prefetchi,-prfchw,-ptwrite,-push2pop2,-raoint,-rdpid,-rdpru,-rdrnd,-rdseed,-retpoline,-retpoline-external-thunk,-retpoline-indirect-branches,-retpoline-indirect-calls,-rtm,-sahf,-sbb-dep-breaking,-serialize,-seses,-sgx,-sha,-sha512,-shstk,-slow-lea,-slow-pmaddwd,-slow-pmulld,-slow-pmullq,-slow-shld,-slow-two-mem-ops,-slow-unaligned-mem-16,-slow-unaligned-mem-32,-sm3,-sm4,-soft-float,-sse3,-sse4.1,-sse4.2,-sse4a,-sse-unaligned-mem,-ssse3,-tagged-globals,-tbm,-tsxldtrk,-tuning-fast-imm-vector-shift,-uintr,-use-glm-div-sqrt-costs,-use-slm-arith-costs,-usermsr,-vaes,-vpclmulqdq,-waitpkg,-wbnoinvd,-widekl,-xop,-xsave,-xsavec,-xsaveopt,-xsaves,-zu" }
attributes #11 = { minsize mustprogress nofree norecurse nosync nounwind optsize willreturn memory(argmem: read, inaccessiblemem: write) uwtable "frame-pointer"="all" "target-cpu"="x86-64" "target-features"="+64bit,+cmov,+cx8,+fxsr,+idivq-to-divl,+macrofusion,+mmx,+nopl,+slow-3ops-lea,+slow-incdec,+sse,+sse2,+vzeroupper,+x87,-16bit-mode,-32bit-mode,-adx,-aes,-allow-light-256-bit,-amx-avx512,-amx-bf16,-amx-complex,-amx-fp16,-amx-fp8,-amx-int8,-amx-movrs,-amx-tf32,-amx-tile,-avx,-avx10.1,-avx10.2,-avx2,-avx512bf16,-avx512bitalg,-avx512bw,-avx512cd,-avx512dq,-avx512f,-avx512fp16,-avx512ifma,-avx512vbmi,-avx512vbmi2,-avx512vl,-avx512vnni,-avx512vp2intersect,-avx512vpopcntdq,-avxifma,-avxneconvert,-avxvnni,-avxvnniint16,-avxvnniint8,-bmi,-bmi2,-branch-hint,-branchfusion,-ccmp,-cf,-cldemote,-clflushopt,-clwb,-clzero,-cmpccxadd,-crc32,-cx16,-egpr,-enqcmd,-ermsb,-f16c,-false-deps-getmant,-false-deps-lzcnt-tzcnt,-false-deps-mulc,-false-deps-mullq,-false-deps-perm,-false-deps-popcnt,-false-deps-range,-fast-11bytenop,-fast-15bytenop,-fast-7bytenop,-fast-bextr,-fast-dpwssd,-fast-gather,-fast-hops,-fast-imm16,-fast-lzcnt,-fast-movbe,-fast-scalar-fsqrt,-fast-scalar-shift-masks,-fast-shld-rotate,-fast-variable-crosslane-shuffle,-fast-variable-perlane-shuffle,-fast-vector-fsqrt,-fast-vector-shift-masks,-faster-shift-than-shuffle,-fma,-fma4,-fsgsbase,-fsrm,-gfni,-harden-sls-ijmp,-harden-sls-ret,-hreset,-idivl-to-divb,-inline-asm-use-gpr32,-invpcid,-kl,-lea-sp,-lea-uses-ag,-lvi-cfi,-lvi-load-hardening,-lwp,-lzcnt,-movbe,-movdir64b,-movdiri,-movrs,-mwaitx,-ndd,-nf,-no-bypass-delay,-no-bypass-delay-blend,-no-bypass-delay-mov,-no-bypass-delay-shuffle,-pad-short-functions,-pclmul,-pconfig,-pku,-popcnt,-ppx,-prefer-128-bit,-prefer-256-bit,-prefer-legacy-setcc,-prefer-mask-registers,-prefer-movmsk-over-vtest,-prefer-no-gather,-prefer-no-scatter,-prefetchi,-prfchw,-ptwrite,-push2pop2,-raoint,-rdpid,-rdpru,-rdrnd,-rdseed,-retpoline,-retpoline-external-thunk,-retpoline-indirect-branches,-retpoline-indirect-calls,-rtm,-sahf,-sbb-dep-breaking,-serialize,-seses,-sgx,-sha,-sha512,-shstk,-slow-lea,-slow-pmaddwd,-slow-pmulld,-slow-pmullq,-slow-shld,-slow-two-mem-ops,-slow-unaligned-mem-16,-slow-unaligned-mem-32,-sm3,-sm4,-soft-float,-sse3,-sse4.1,-sse4.2,-sse4a,-sse-unaligned-mem,-ssse3,-tagged-globals,-tbm,-tsxldtrk,-tuning-fast-imm-vector-shift,-uintr,-use-glm-div-sqrt-costs,-use-slm-arith-costs,-usermsr,-vaes,-vpclmulqdq,-waitpkg,-wbnoinvd,-widekl,-xop,-xsave,-xsavec,-xsaveopt,-xsaves,-zu" }
attributes #12 = { nocallback nofree nosync nounwind willreturn memory(inaccessiblemem: readwrite) }
attributes #13 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #14 = { nounwind }

!llvm.module.flags = !{}
!0 = !{!1}
!1 = distinct !{!1, !2, !"fmt.bufPrint__anon_201: argument 0"}
!2 = distinct !{!2, !"fmt.bufPrint__anon_201"}
!3 = !{!4}
!4 = distinct !{!4, !5, !"fmt.Options.toNumber: argument 0"}
!5 = distinct !{!5, !"fmt.Options.toNumber"}
!6 = !{!7, !1}
!7 = distinct !{!7, !8, !"fmt.float.render__anon_1086: argument 0"}
!8 = distinct !{!8, !"fmt.float.render__anon_1086"}
!9 = !{!10}
!10 = distinct !{!10, !11, !"fmt.float.binaryToDecimal__anon_1143: argument 0"}
!11 = distinct !{!11, !"fmt.float.binaryToDecimal__anon_1143"}
!12 = !{!13, !10, !7, !1}
!13 = distinct !{!13, !14, !"fmt.float.Backend64_TablesSmall.computeInvPow5: argument 0"}
!14 = distinct !{!14, !"fmt.float.Backend64_TablesSmall.computeInvPow5"}
!15 = !{!10, !7, !1}
!16 = !{!17, !10, !7, !1}
!17 = distinct !{!17, !18, !"fmt.float.Backend64_TablesSmall.computePow5: argument 0"}
!18 = distinct !{!18, !"fmt.float.Backend64_TablesSmall.computePow5"}
!19 = !{!20, !7, !1}
!20 = distinct !{!20, !21, !"fmt.float.formatScientific__anon_1150: argument 0"}
!21 = distinct !{!21, !"fmt.float.formatScientific__anon_1150"}
!22 = !{!23, !7, !1}
!23 = distinct !{!23, !24, !"fmt.float.formatDecimal__anon_1153: argument 0"}
!24 = distinct !{!24, !"fmt.float.formatDecimal__anon_1153"}
!25 = !{!"branch_weights", i32 2146410, i32 2145337238}
!26 = !{!27, !1}
!27 = distinct !{!27, !28, !"Io.Writer.write: argument 0"}
!28 = distinct !{!28, !"Io.Writer.write"}
!29 = !{!"branch_weights", i32 1, i32 2000}
!30 = !{!"branch_weights", i32 0, i32 -2147483648}
