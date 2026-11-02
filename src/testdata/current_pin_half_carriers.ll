; Current-pin baseline f16 C ABI carriers; operations/flags retained, debug metadata and linkage omitted.

target triple = "x86_64-unknown-linux-gnu"

declare half @llvm.fabs.f16(half)

define double @compiler_rt.__neghf2(double %0) unnamed_addr {
Entry:
  %1 = alloca half, align 8
  %2 = bitcast double %0 to i64
  %.sroa.0.0.extract.trunc = trunc i64 %2 to i16
  %3 = xor i16 %.sroa.0.0.extract.trunc, -32768
  store i16 %3, ptr %1, align 8
  %.0..0..0..0. = load double, ptr %1, align 8
  ret double %.0..0..0..0.
}

define double @compiler_rt.fabs.__fabsh(double %0) unnamed_addr {
Entry:
  %1 = alloca half, align 8
  %2 = bitcast double %0 to i64
  %3 = trunc i64 %2 to i16
  %4 = bitcast i16 %3 to half
  %5 = tail call half @llvm.fabs.f16(half %4)
  store half %5, ptr %1, align 8
  %.0..0..0..0. = load double, ptr %1, align 8
  ret double %.0..0..0..0.
}
