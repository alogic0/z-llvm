; ModuleID = '/tmp/inbox56_fma_stripped.ll'
source_filename = "compiler_rt"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux5.10.0-gnu2.31.0"

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(inaccessiblemem: write)
declare void @llvm.assume(i1 noundef) #0

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i64 @llvm.cttz.i64(i64, i1 immarg) #1

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i64 @llvm.ctlz.i64(i64, i1 immarg) #1

; Function Attrs: nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.smin.i32(i32, i32) #2

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(inaccessiblemem: write) uwtable
define hidden fastcc double @math.ldexp.ldexp__anon_5959(double %0, i32 %1) unnamed_addr #3 align 1 {
Entry:
  %2 = sub i32 0, %1
  %3 = bitcast double %0 to i64
  %4 = and i64 %3, -9223372036854775808
  %5 = fcmp uno double %0, 0.000000e+00
  br i1 %5, label %common.ret, label %Else

Else:                                             ; preds = %Entry
  %6 = tail call double @llvm.fabs.f64(double %0)
  %7 = bitcast double %6 to i64
  %8 = icmp samesign ult i64 %7, 9218868437227405312
  br i1 %8, label %Else1, label %common.ret

common.ret:                                       ; preds = %Else8, %Then8, %Else7, %Else6, %Then6, %Then5, %Block13, %Else, %Entry
  %common.ret.op = phi double [ %48, %Then8 ], [ %41, %Else6 ], [ %22, %Block13 ], [ %27, %Then5 ], [ %37, %Then6 ], [ %47, %Else7 ], [ %68, %Else8 ], [ %0, %Entry ], [ %0, %Else ]
  ret double %common.ret.op

Else1:                                            ; preds = %Else
  %9 = shl i64 %3, 1
  %10 = lshr i64 %9, 53
  %11 = trunc nuw nsw i64 %10 to i32
  %12 = icmp eq i64 %10, 0
  %13 = tail call range(i64 11, 65) i64 @llvm.ctlz.i64(i64 %9, i1 false)
  %14 = trunc nuw nsw i64 %13 to i32
  %15 = sub nsw i32 11, %14
  %.0 = select i1 %12, i32 %15, i32 %11
  %16 = icmp sgt i32 %1, -1
  br i1 %16, label %Then3, label %Else3

Then3:                                            ; preds = %Else1
  %17 = sub nsw i32 2046, %.0
  %18 = icmp sgt i32 %1, %17
  br i1 %18, label %Block13, label %Else4

Else3:                                            ; preds = %Else1
  %19 = sub nsw i32 0, %.0
  %.not = icmp sgt i32 %1, %19
  br i1 %.not, label %Else7, label %Then7

Else4:                                            ; preds = %Then3
  %20 = add nsw i32 %.0, %1
  %21 = icmp slt i32 %20, 1
  br i1 %21, label %Then5, label %Else5

Block13:                                          ; preds = %Then3
  %22 = tail call double @llvm.copysign.f64(double 0x7FF0000000000000, double %0)
  br label %common.ret

Then5:                                            ; preds = %Else4
  %23 = icmp samesign ult i32 %1, 64
  tail call void @llvm.assume(i1 %23)
  %24 = zext nneg i32 %1 to i64
  %25 = shl i64 %3, %24
  %26 = or i64 %25, %4
  %27 = bitcast i64 %26 to double
  br label %common.ret

Else5:                                            ; preds = %Else4
  %28 = icmp slt i32 %.0, 1
  br i1 %28, label %Then6, label %Else6

Then6:                                            ; preds = %Else5
  %29 = zext nneg i32 %20 to i64
  %30 = shl i64 %29, 52
  %31 = sub nsw i32 1, %.0
  %32 = zext nneg i32 %31 to i64
  %33 = shl i64 %3, %32
  %34 = and i64 %33, 4503599627370495
  %35 = or disjoint i64 %34, %30
  %36 = or i64 %35, %4
  %37 = bitcast i64 %36 to double
  br label %common.ret

Else6:                                            ; preds = %Else5
  %38 = zext nneg i32 %1 to i64
  %39 = shl nuw i64 %38, 52
  %40 = add nuw i64 %39, %3
  %41 = bitcast i64 %40 to double
  br label %common.ret

Then7:                                            ; preds = %Else3
  %42 = sub nsw i32 -52, %.0
  %43 = icmp slt i32 %1, %42
  br i1 %43, label %Then8, label %Else8

Else7:                                            ; preds = %Else3
  %44 = zext nneg i32 %2 to i64
  %45 = shl nuw nsw i64 %44, 52
  %46 = sub nuw i64 %3, %45
  %47 = bitcast i64 %46 to double
  br label %common.ret

Then8:                                            ; preds = %Then7
  %48 = bitcast i64 %4 to double
  br label %common.ret

Else8:                                            ; preds = %Then7
  %49 = add nsw i32 %1, %.0
  %50 = sub nsw i32 1, %49
  %51 = tail call i32 @llvm.smin.i32(i32 %2, i32 %50)
  %52 = icmp samesign ult i32 %51, 64
  tail call void @llvm.assume(i1 %52)
  %53 = tail call range(i64 0, 65) i64 @llvm.cttz.i64(i64 %3, i1 false)
  %narrow = add nuw nsw i32 %51, 63
  %54 = and i32 %narrow, 63
  %55 = zext nneg i32 %54 to i64
  %56 = icmp eq i64 %53, %55
  %57 = and i64 %3, 4503599627370495
  %58 = icmp sgt i32 %.0, 0
  %59 = select i1 %58, i64 4503599627370496, i64 0
  %60 = or disjoint i64 %59, %57
  %61 = lshr i64 %60, %55
  %62 = add nuw nsw i64 %61, 1
  %63 = lshr i64 %62, 1
  %64 = zext i1 %56 to i64
  %65 = xor i64 %64, -1
  %66 = and i64 %63, %65
  %67 = bitcast i64 %66 to double
  %68 = tail call double @llvm.copysign.f64(double %67, double %0)
  br label %common.ret
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(inaccessiblemem: write) uwtable
define hidden fastcc double @compiler_rt.fma.add_and_denorm(double %0, double %1, i32 %2) unnamed_addr #3 align 1 {
Entry:
  %3 = fadd double %0, %1
  %4 = fsub double %3, %0
  %5 = fsub double %3, %4
  %6 = fsub double %0, %5
  %7 = fsub double %1, %4
  %8 = fadd double %7, %6
  %9 = fcmp une double %8, 0.000000e+00
  br i1 %9, label %Then, label %Block

Block:                                            ; preds = %Then1, %Then, %Entry
  %.sroa.0.0 = phi double [ %26, %Then1 ], [ %3, %Then ], [ %3, %Entry ]
  %10 = tail call fastcc double @math.ldexp.ldexp__anon_5959(double %.sroa.0.0, i32 %2) #4
  ret double %10

Then:                                             ; preds = %Entry
  %11 = bitcast double %3 to i64
  %12 = lshr i64 %11, 52
  %13 = trunc nuw nsw i64 %12 to i32
  %14 = and i32 %13, 2047
  %15 = sub i32 0, %2
  %16 = icmp ne i32 %14, %15
  %17 = and i64 %11, 1
  %18 = icmp eq i64 %17, 0
  %19 = xor i1 %18, %16
  br i1 %19, label %Then1, label %Block

Then1:                                            ; preds = %Then
  %20 = bitcast double %8 to i64
  %21 = add nuw i64 %11, 1
  %22 = xor i64 %20, %11
  %23 = lshr i64 %22, 62
  %24 = and i64 %23, 2
  %25 = sub i64 %21, %24
  %26 = bitcast i64 %25 to double
  br label %Block
}

define double @zllvm_fma_proof_ldexp(double %value, i32 %exponent) {
entry:
  %result = call fastcc double @math.ldexp.ldexp__anon_5959(double %value, i32 %exponent)
  ret double %result
}

define double @zllvm_fma_proof_add_and_denorm(double %hi, double %lo, i32 %scale) {
entry:
  %result = call fastcc double @compiler_rt.fma.add_and_denorm(double %hi, double %lo, i32 %scale)
  ret double %result
}

; Function Attrs: nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.fabs.f64(double) #2

; Function Attrs: nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.copysign.f64(double, double) #2

attributes #0 = { nocallback nofree nosync nounwind willreturn memory(inaccessiblemem: write) }
attributes #1 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #2 = { nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none) }
attributes #3 = { mustprogress nofree norecurse nosync nounwind willreturn memory(inaccessiblemem: write) uwtable "frame-pointer"="all" "no-builtins" "target-cpu"="x86-64" "target-features"="+64bit,+cmov,+cx8,+fxsr,+idivq-to-divl,+macrofusion,+mmx,+nopl,+slow-3ops-lea,+slow-incdec,+sse,+sse2,+vzeroupper,+x87,-16bit-mode,-32bit-mode,-adx,-aes,-allow-light-256-bit,-amx-avx512,-amx-bf16,-amx-complex,-amx-fp16,-amx-fp8,-amx-int8,-amx-movrs,-amx-tf32,-amx-tile,-avx,-avx10.1,-avx10.2,-avx2,-avx512bf16,-avx512bitalg,-avx512bw,-avx512cd,-avx512dq,-avx512f,-avx512fp16,-avx512ifma,-avx512vbmi,-avx512vbmi2,-avx512vl,-avx512vnni,-avx512vp2intersect,-avx512vpopcntdq,-avxifma,-avxneconvert,-avxvnni,-avxvnniint16,-avxvnniint8,-bmi,-bmi2,-branch-hint,-branchfusion,-ccmp,-cf,-cldemote,-clflushopt,-clwb,-clzero,-cmpccxadd,-crc32,-cx16,-egpr,-enqcmd,-ermsb,-f16c,-false-deps-getmant,-false-deps-lzcnt-tzcnt,-false-deps-mulc,-false-deps-mullq,-false-deps-perm,-false-deps-popcnt,-false-deps-range,-fast-11bytenop,-fast-15bytenop,-fast-7bytenop,-fast-bextr,-fast-dpwssd,-fast-gather,-fast-hops,-fast-imm16,-fast-lzcnt,-fast-movbe,-fast-scalar-fsqrt,-fast-scalar-shift-masks,-fast-shld-rotate,-fast-variable-crosslane-shuffle,-fast-variable-perlane-shuffle,-fast-vector-fsqrt,-fast-vector-shift-masks,-faster-shift-than-shuffle,-fma,-fma4,-fsgsbase,-fsrm,-gfni,-harden-sls-ijmp,-harden-sls-ret,-hreset,-idivl-to-divb,-inline-asm-use-gpr32,-invpcid,-kl,-lea-sp,-lea-uses-ag,-lvi-cfi,-lvi-load-hardening,-lwp,-lzcnt,-movbe,-movdir64b,-movdiri,-movrs,-mwaitx,-ndd,-nf,-no-bypass-delay,-no-bypass-delay-blend,-no-bypass-delay-mov,-no-bypass-delay-shuffle,-pad-short-functions,-pclmul,-pconfig,-pku,-popcnt,-ppx,-prefer-128-bit,-prefer-256-bit,-prefer-legacy-setcc,-prefer-mask-registers,-prefer-movmsk-over-vtest,-prefer-no-gather,-prefer-no-scatter,-prefetchi,-prfchw,-ptwrite,-push2pop2,-raoint,-rdpid,-rdpru,-rdrnd,-rdseed,-retpoline,-retpoline-external-thunk,-retpoline-indirect-branches,-retpoline-indirect-calls,-rtm,-sahf,-sbb-dep-breaking,-serialize,-seses,-sgx,-sha,-sha512,-shstk,-slow-lea,-slow-pmaddwd,-slow-pmulld,-slow-pmullq,-slow-shld,-slow-two-mem-ops,-slow-unaligned-mem-16,-slow-unaligned-mem-32,-sm3,-sm4,-soft-float,-sse3,-sse4.1,-sse4.2,-sse4a,-sse-unaligned-mem,-ssse3,-tagged-globals,-tbm,-tsxldtrk,-tuning-fast-imm-vector-shift,-uintr,-use-glm-div-sqrt-costs,-use-slm-arith-costs,-usermsr,-vaes,-vpclmulqdq,-waitpkg,-wbnoinvd,-widekl,-xop,-xsave,-xsavec,-xsaveopt,-xsaves,-zu" }
attributes #4 = { nobuiltin }

!llvm.module.flags = !{!0, !1}

!0 = !{i32 2, !"Debug Info Version", i32 3}
!1 = !{i32 7, !"Dwarf Version", i32 4}
