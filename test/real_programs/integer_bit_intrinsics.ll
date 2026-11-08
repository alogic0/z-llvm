target datalayout = "e-m:e-p:64:64-i64:64-i128:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"
declare i32 @llvm.ctpop.i32(i32)
declare i16 @llvm.ctpop.i16(i16)
declare i64 @llvm.ctpop.i64(i64)
declare i64 @llvm.fshl.i64(i64, i64, i64)
declare i16 @llvm.fshl.i16(i16, i16, i16)
declare i6 @llvm.fshl.i6(i6, i6, i6)
declare i37 @llvm.cttz.i37(i37, i1)
declare i23 @llvm.cttz.i23(i23, i1)
declare i23 @llvm.ctlz.i23(i23, i1)
declare i8 @llvm.ctlz.i8(i8, i1)
declare i25 @llvm.abs.i25(i25, i1)
declare i29 @llvm.abs.i29(i29, i1)
declare i48 @llvm.bswap.i48(i48)
declare i64 @llvm.umax.i64(i64, i64)
declare i64 @llvm.umin.i64(i64, i64)
declare { i64, i1 } @llvm.uadd.with.overflow.i64(i64, i64)
declare i64 @bit_intrinsic_clobber(i64)

define i64 @bit_pop32(i64 %a, i64 %live) {
entry:
  %word = trunc i64 %a to i32
  %count = tail call range(i32 0, 33) i32 @llvm.ctpop.i32(i32 %word)
  %wide = zext i32 %count to i64
  %called = call i64 @bit_intrinsic_clobber(i64 %live)
  %one = xor i64 %wide, %a
  %result = xor i64 %one, %called
  ret i64 %result
}

define i64 @bit_pop16(i64 %a, i64 %live) {
entry:
  %word = trunc i64 %a to i16
  %nonzero = or i16 %word, 1
  %count = tail call noundef range(i16 1, 17) i16 @llvm.ctpop.i16(i16 noundef %nonzero)
  %wide = zext i16 %count to i64
  %result = xor i64 %wide, %live
  ret i64 %result
}

define i64 @bit_pop64(i64 %a, i64 %live) {
entry:
  %nonzero = or i64 %a, 1
  %count = call range(i64 1, 65) i64 @llvm.ctpop.i64(i64 range(i64 1, 0) %nonzero)
  %result = xor i64 %count, %live
  ret i64 %result
}

define i64 @bit_funnel64(i64 %a, i64 %b, i64 %count) {
entry:
  %value = call i64 @llvm.fshl.i64(i64 %a, i64 %b, i64 %count)
  %result = xor i64 %value, %b
  ret i64 %result
}

define i64 @bit_funnel16(i64 %a, i64 %live) {
entry:
  %word = trunc i64 %a to i16
  %value = call i16 @llvm.fshl.i16(i16 %word, i16 %word, i16 12)
  %wide = zext i16 %value to i64
  %result = xor i64 %wide, %live
  ret i64 %result
}

define i64 @bit_funnel6(i64 %a, i64 %b, i64 %count) {
entry:
  %x = trunc i64 %a to i6
  %y = trunc i64 %b to i6
  %c = trunc i64 %count to i6
  %value = call i6 @llvm.fshl.i6(i6 %x, i6 %y, i6 %c)
  %wide = zext i6 %value to i64
  %result = xor i64 %wide, %a
  ret i64 %result
}

define i64 @bit_cttz37(i64 %a) {
entry:
  %word = trunc i64 %a to i37
  %count = call range(i37 0, 38) i37 @llvm.cttz.i37(i37 %word, i1 false)
  %result = zext i37 %count to i64
  ret i64 %result
}

define i64 @bit_cttz23(i64 %a) {
entry:
  %word = trunc i64 %a to i23
  %count = call range(i23 0, 24) i23 @llvm.cttz.i23(i23 %word, i1 false)
  %result = zext i23 %count to i64
  ret i64 %result
}

define i64 @bit_ctlz23(i64 %a) {
entry:
  %word = trunc i64 %a to i23
  %count = call range(i23 0, 24) i23 @llvm.ctlz.i23(i23 %word, i1 false)
  %result = zext i23 %count to i64
  ret i64 %result
}

define i64 @bit_ctlz8(i64 %a) {
entry:
  %word = trunc i64 %a to i8
  %nonzero = or i8 %word, 1
  %count = call range(i8 0, 9) i8 @llvm.ctlz.i8(i8 range(i8 1, 0) %nonzero, i1 true)
  %result = zext i8 %count to i64
  ret i64 %result
}

define i64 @bit_abs25(i64 %a) {
entry:
  %word = trunc i64 %a to i25
  %value = call i25 @llvm.abs.i25(i25 %word, i1 false)
  %result = zext i25 %value to i64
  ret i64 %result
}

define i64 @bit_abs29(i64 %a) {
entry:
  %word = trunc i64 %a to i29
  %value = call i29 @llvm.abs.i29(i29 %word, i1 false)
  %result = zext i29 %value to i64
  ret i64 %result
}

define i64 @bit_bswap48(i64 %a) {
entry:
  %word = trunc i64 %a to i48
  %value = call i48 @llvm.bswap.i48(i48 %word)
  %result = zext i48 %value to i64
  ret i64 %result
}

define i64 @bit_extrema64(i64 %a, i64 %b) {
entry:
  %maximum = call range(i64 1, 0) i64 @llvm.umax.i64(i64 %a, i64 range(i64 1, 2) 1)
  %minimum = call range(i64 1, 0) i64 @llvm.umin.i64(i64 range(i64 1, 0) %maximum, i64 -1)
  %result = xor i64 %minimum, %b
  ret i64 %result
}

define i64 @bit_overflow64(i64 %a, i64 %b) {
entry:
  %masked = and i64 %b, 4294967295
  %positive = or i64 %masked, 1
  %pair = call { i64, i1 } @llvm.uadd.with.overflow.i64(i64 %a, i64 range(i64 1, 4294967296) %positive)
  %sum = extractvalue { i64, i1 } %pair, 0
  %flag = extractvalue { i64, i1 } %pair, 1
  %wide = zext i1 %flag to i64
  %one = xor i64 %sum, %wide
  %result = xor i64 %one, %a
  ret i64 %result
}
