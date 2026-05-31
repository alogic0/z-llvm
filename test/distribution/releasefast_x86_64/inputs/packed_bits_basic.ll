source_filename = "packed_bits"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux5.10.0-gnu2.31.0"

@replace_low = alias i8 (i8, i8), ptr @packed_bits.replace_low
@read_flag = alias i1 (i8), ptr @packed_bits.read_flag

define private zeroext i8 @packed_bits.replace_low(i8 zeroext %0, i8 zeroext %1) unnamed_addr #0 align 1 {
2:
  %3 = and i8 %0, -8
  %4 = and i8 %1, 7
  %5 = or disjoint i8 %4, %3
  ret i8 %5
}

define private i1 @packed_bits.read_flag(i8 zeroext %0) unnamed_addr #0 align 1 {
1:
  %2 = icmp slt i8 %0, 0
  ret i1 %2
}

attributes #0 = { mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable "frame-pointer"="all" "target-cpu"="x86-64" }

!llvm.module.flags = !{}
