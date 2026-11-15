target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i64 @frontier_clobber(i64)
declare void @frontier_mutate(ptr)

define internal fastcc i96 @frontier_identity96_core(i96 %value) #0 {
entry:
  ret i96 %value
}
define internal fastcc i96 @frontier_not96_core(i96 %value) #0 {
entry:
  %out = xor i96 %value, -1
  ret i96 %out
}
define internal fastcc i65 @frontier_not65_core(i65 %value) #0 {
entry:
  %out = xor i65 %value, -1
  ret i65 %out
}
define i128 @frontier_identity96(i128 %input) {
entry:
  %value = trunc i128 %input to i96
  %out = call fastcc i96 @frontier_identity96_core(i96 %value)
  %wide = zext i96 %out to i128
  ret i128 %wide
}
define i128 @frontier_not96(i128 %input) {
entry:
  %value = trunc i128 %input to i96
  %out = call fastcc i96 @frontier_not96_core(i96 %value)
  %wide = zext i96 %out to i128
  ret i128 %wide
}
define i128 @frontier_not65(i128 %input) {
entry:
  %value = trunc i128 %input to i65
  %out = call fastcc i65 @frontier_not65_core(i65 %value)
  %wide = zext i65 %out to i128
  ret i128 %wide
}
define i64 @frontier_word_mask(i64 %a, i64 %b) {
entry:
  %keep = add i64 %a, 1234567890123
  %masked = and i64 %b, 4294967295
  %out = xor i64 %keep, %masked
  ret i64 %out
}
define i64 @frontier_shift4(i32 %value, i32 %count, i64 %keep) {
entry:
  %narrow = trunc i32 %value to i4
  %small_count = trunc i32 %count to i2
  %amount = zext i2 %small_count to i4
  %shifted = shl i4 %narrow, %amount
  %roundtrip = lshr i4 %shifted, %amount
  %overflow = icmp ne i4 %narrow, %roundtrip
  %low = zext i4 %shifted to i64
  %flag = zext i1 %overflow to i64
  %high = shl i64 %flag, 32
  %packed = or i64 %low, %high
  %call = call i64 @frontier_clobber(i64 %keep)
  %out = xor i64 %packed, %call
  ret i64 %out
}
define i64 @frontier_shift9(i32 %value, i32 %count, i64 %keep) {
entry:
  %narrow = trunc i32 %value to i9
  %small_count = trunc i32 %count to i4
  %amount = zext i4 %small_count to i9
  %shifted = shl i9 %narrow, %amount
  %roundtrip = ashr i9 %shifted, %amount
  %overflow = icmp ne i9 %narrow, %roundtrip
  %low = zext i9 %shifted to i64
  %flag = zext i1 %overflow to i64
  %high = shl i64 %flag, 32
  %packed = or i64 %low, %high
  %call = call i64 @frontier_clobber(i64 %keep)
  %out = xor i64 %packed, %call
  ret i64 %out
}
define i64 @frontier_shift16(i32 %value, i32 %count, i64 %keep) {
entry:
  %narrow = trunc i32 %value to i16
  %small_count = trunc i32 %count to i4
  %amount = zext i4 %small_count to i16
  %shifted = shl i16 %narrow, %amount
  %roundtrip = lshr i16 %shifted, %amount
  %overflow = icmp ne i16 %narrow, %roundtrip
  %low = zext i16 %shifted to i64
  %flag = zext i1 %overflow to i64
  %high = shl i64 %flag, 32
  %packed = or i64 %low, %high
  %call = call i64 @frontier_clobber(i64 %keep)
  %out = xor i64 %packed, %call
  ret i64 %out
}
define i32 @frontier_vector_lane(i32 %input, i32 %other) {
entry:
  %a = bitcast i32 %input to float
  %b = bitcast i32 %other to float
  %first = insertelement <4 x float> poison, float %a, i32 0
  %second = insertelement <4 x float> %first, float %b, i32 1
  %lane = extractelement <4 x float> %second, i64 0
  %out = bitcast float %lane to i32
  ret i32 %out
}
define void @frontier_vector_snapshot(ptr %source, ptr %destination) {
entry:
  %vector = load <4 x float>, ptr %source, align 1
  call void @frontier_mutate(ptr %source)
  %a = extractelement <4 x float> %vector, i64 0
  %b = extractelement <4 x float> %vector, i64 1
  %c = extractelement <4 x float> %vector, i64 2
  %d = extractelement <4 x float> %vector, i64 3
  store float %a, ptr %destination, align 1
  %p1 = getelementptr i8, ptr %destination, i64 4
  store float %b, ptr %p1, align 1
  %p2 = getelementptr i8, ptr %destination, i64 8
  store float %c, ptr %p2, align 1
  %p3 = getelementptr i8, ptr %destination, i64 12
  store float %d, ptr %p3, align 1
  ret void
}
attributes #0 = { noinline nounwind }
