; Reduced from the pinned upstream compiler-rt ABI cohort. Operations and flags
; retained; debug records, internal linkage and attribute-group references removed.

target triple = "x86_64-unknown-linux-gnu"

declare void @llvm.assume(i1)

define { i64, i64 } @compiler_rt.shift.__ashlti3(i64 %0, i64 %1, i32 %2) unnamed_addr {
Entry:
  %3 = icmp sgt i32 %2, 63
  br i1 %3, label %Then, label %Else

Block:                                            ; preds = %Then, %Else1, %Else
  %.off0 = phi i64 [ %0, %Else ], [ 0, %Then ], [ %10, %Else1 ]
  %.off64 = phi i64 [ %1, %Else ], [ %7, %Then ], [ %17, %Else1 ]
  %.fca.0.insert = insertvalue { i64, i64 } poison, i64 %.off0, 0
  %.fca.1.insert = insertvalue { i64, i64 } %.fca.0.insert, i64 %.off64, 1
  ret { i64, i64 } %.fca.1.insert

Then:                                             ; preds = %Entry
  %4 = icmp samesign ult i32 %2, 128
  tail call void @llvm.assume(i1 %4)
  %5 = and i32 %2, 63
  %6 = zext nneg i32 %5 to i64
  %7 = shl i64 %0, %6
  br label %Block

Else:                                             ; preds = %Entry
  %8 = icmp eq i32 %2, 0
  br i1 %8, label %Block, label %Else1

Else1:                                            ; preds = %Else
  %9 = zext nneg i32 %2 to i64
  %10 = shl i64 %0, %9
  %11 = icmp sgt i32 %2, -1
  tail call void @llvm.assume(i1 %11)
  %12 = shl i64 %1, %9
  %13 = sub nsw i32 0, %2
  %14 = and i32 %13, 63
  %15 = zext nneg i32 %14 to i64
  %16 = lshr i64 %0, %15
  %17 = or i64 %16, %12
  br label %Block
}

define { i64, i64 } @compiler_rt.__negti2(i64 %0, i64 %1) unnamed_addr {
Entry:
  %.neg = sub i64 0, %1
  %.neg.z = zext i64 %.neg to i128
  %.sroa.2.0.insert.shift.neg = shl nuw i128 %.neg.z, 64
  %.sroa.0.0.insert.ext = zext i64 %0 to i128
  %.sroa.0.0.insert.insert.neg = sub i128 %.sroa.2.0.insert.shift.neg, %.sroa.0.0.insert.ext
  %.sroa.01.0.extract.trunc = trunc i128 %.sroa.0.0.insert.insert.neg to i64
  %.sroa.22.0.extract.shift = lshr i128 %.sroa.0.0.insert.insert.neg, 64
  %.sroa.22.0.extract.trunc = trunc nuw i128 %.sroa.22.0.extract.shift to i64
  %.fca.0.insert = insertvalue { i64, i64 } poison, i64 %.sroa.01.0.extract.trunc, 0
  %.fca.1.insert = insertvalue { i64, i64 } %.fca.0.insert, i64 %.sroa.22.0.extract.trunc, 1
  ret { i64, i64 } %.fca.1.insert
}
