; ModuleID = '/tmp/inbox56_fma_stripped.ll'
source_filename = "compiler_rt"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux5.10.0-gnu2.31.0"

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i64 @llvm.ctlz.i64(i64, i1 immarg) #0

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(inaccessiblemem: write) uwtable
declare hidden fastcc double @math.ldexp.ldexp__anon_5959(double, i32) unnamed_addr #1 align 1

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(inaccessiblemem: write) uwtable
define hidden double @compiler_rt.fma.fma(double %0, double %1, double %2) unnamed_addr #1 align 1 {
Entry:
  %3 = tail call double @llvm.fabs.f64(double %0)
  %4 = bitcast double %3 to i64
  %5 = icmp samesign ult i64 %4, 9218868437227405312
  br i1 %5, label %Else, label %Then1

Else:                                             ; preds = %Entry
  %6 = tail call double @llvm.fabs.f64(double %1)
  %7 = bitcast double %6 to i64
  %8 = icmp samesign ult i64 %7, 9218868437227405312
  br i1 %8, label %Else1, label %Then1

common.ret:                                       ; preds = %Else8, %Then8, %Then7, %Then5, %Then4, %Else1, %Then1
  %common.ret.op = phi double [ %10, %Then1 ], [ %153, %Else8 ], [ %18, %Then4 ], [ %20, %Then5 ], [ %117, %Then7 ], [ %152, %Then8 ], [ %2, %Else1 ]
  ret double %common.ret.op

Then1:                                            ; preds = %Else, %Entry
  %9 = fmul double %0, %1
  %10 = fadd double %9, %2
  br label %common.ret

Else1:                                            ; preds = %Else
  %11 = tail call double @llvm.fabs.f64(double %2)
  %12 = bitcast double %11 to i64
  %13 = icmp samesign ult i64 %12, 9218868437227405312
  br i1 %13, label %Else2, label %common.ret

Else2:                                            ; preds = %Else1
  %14 = fcmp oeq double %0, 0.000000e+00
  %15 = fcmp oeq double %1, 0.000000e+00
  %16 = select i1 %14, i1 true, i1 %15
  br i1 %16, label %Then4, label %Else4

Then4:                                            ; preds = %Else2
  %17 = fmul double %0, %1
  %18 = fadd double %17, %2
  br label %common.ret

Else4:                                            ; preds = %Else2
  %19 = fcmp oeq double %2, 0.000000e+00
  br i1 %19, label %Then5, label %Else5

Then5:                                            ; preds = %Else4
  %20 = fmul double %0, %1
  br label %common.ret

Else5:                                            ; preds = %Else4
  %21 = bitcast double %0 to i64
  %22 = trunc i64 %21 to i52
  %23 = lshr i64 %21, 52
  %24 = trunc i64 %23 to i11
  switch i11 %24, label %Default.i [
    i11 0, label %Case.i
    i11 -1, label %math.frexp.frexp__anon_9469.exit
  ]

Case.i:                                           ; preds = %Else5
  %.not.i = icmp eq i52 %22, 0
  br i1 %.not.i, label %math.frexp.frexp__anon_9469.exit, label %Then.i

Default.i:                                        ; preds = %Else5
  %25 = and i64 %21, -9218868437227405313
  %26 = or disjoint i64 %25, 4602678819172646912
  %27 = trunc nuw nsw i64 %23 to i32
  %28 = and i32 %27, 2047
  %29 = add nsw i32 %28, -1022
  br label %math.frexp.frexp__anon_9469.exit

Then.i:                                           ; preds = %Case.i
  %30 = tail call range(i52 0, 53) i52 @llvm.ctlz.i52(i52 %22, i1 true)
  %31 = trunc nuw i52 %30 to i6
  %32 = add nuw i6 %31, 1
  %33 = and i64 %21, -9223372036854775808
  %34 = icmp ult i6 %31, -13
  %35 = zext i6 %32 to i52
  %36 = shl i52 %22, %35
  %37 = zext i52 %36 to i64
  %38 = select i1 %34, i64 %37, i64 0
  %39 = or disjoint i64 %33, %38
  %40 = or disjoint i64 %39, 4602678819172646912
  %41 = trunc nuw nsw i52 %30 to i32
  %42 = sub nuw nsw i32 -1022, %41
  br label %math.frexp.frexp__anon_9469.exit

math.frexp.frexp__anon_9469.exit:                 ; preds = %Then.i, %Default.i, %Case.i, %Else5
  %.sroa.3.0.i = phi i32 [ %29, %Default.i ], [ %42, %Then.i ], [ 0, %Case.i ], [ 0, %Else5 ]
  %.0.i = phi i64 [ %26, %Default.i ], [ %40, %Then.i ], [ %21, %Case.i ], [ %21, %Else5 ]
  %43 = bitcast i64 %.0.i to double
  %44 = bitcast double %1 to i64
  %45 = trunc i64 %44 to i52
  %46 = lshr i64 %44, 52
  %47 = trunc i64 %46 to i11
  switch i11 %47, label %Default.i34 [
    i11 0, label %Case.i31
    i11 -1, label %math.frexp.frexp__anon_9469.exit35
  ]

Case.i31:                                         ; preds = %math.frexp.frexp__anon_9469.exit
  %.not.i32 = icmp eq i52 %45, 0
  br i1 %.not.i32, label %math.frexp.frexp__anon_9469.exit35, label %Then.i33

Default.i34:                                      ; preds = %math.frexp.frexp__anon_9469.exit
  %48 = and i64 %44, -9218868437227405313
  %49 = or disjoint i64 %48, 4602678819172646912
  %50 = trunc nuw nsw i64 %46 to i32
  %51 = and i32 %50, 2047
  %52 = add nsw i32 %51, -1022
  br label %math.frexp.frexp__anon_9469.exit35

Then.i33:                                         ; preds = %Case.i31
  %53 = tail call range(i52 0, 53) i52 @llvm.ctlz.i52(i52 %45, i1 true)
  %54 = trunc nuw i52 %53 to i6
  %55 = add nuw i6 %54, 1
  %56 = and i64 %44, -9223372036854775808
  %57 = icmp ult i6 %54, -13
  %58 = zext i6 %55 to i52
  %59 = shl i52 %45, %58
  %60 = zext i52 %59 to i64
  %61 = select i1 %57, i64 %60, i64 0
  %62 = or disjoint i64 %56, %61
  %63 = or disjoint i64 %62, 4602678819172646912
  %64 = trunc nuw nsw i52 %53 to i32
  %65 = sub nuw nsw i32 -1022, %64
  br label %math.frexp.frexp__anon_9469.exit35

math.frexp.frexp__anon_9469.exit35:               ; preds = %Then.i33, %Default.i34, %Case.i31, %math.frexp.frexp__anon_9469.exit
  %.sroa.3.0.i27 = phi i32 [ %52, %Default.i34 ], [ %65, %Then.i33 ], [ 0, %Case.i31 ], [ 0, %math.frexp.frexp__anon_9469.exit ]
  %.0.i28 = phi i64 [ %49, %Default.i34 ], [ %63, %Then.i33 ], [ %44, %Case.i31 ], [ %44, %math.frexp.frexp__anon_9469.exit ]
  %66 = bitcast i64 %.0.i28 to double
  %67 = bitcast double %2 to i64
  %68 = trunc i64 %67 to i52
  %69 = lshr i64 %67, 52
  %70 = trunc i64 %69 to i11
  switch i11 %70, label %Default.i43 [
    i11 0, label %Case.i40
    i11 -1, label %math.frexp.frexp__anon_9469.exit44
  ]

Case.i40:                                         ; preds = %math.frexp.frexp__anon_9469.exit35
  %.not.i41 = icmp eq i52 %68, 0
  br i1 %.not.i41, label %math.frexp.frexp__anon_9469.exit44, label %Then.i42

Default.i43:                                      ; preds = %math.frexp.frexp__anon_9469.exit35
  %71 = and i64 %67, -9218868437227405313
  %72 = or disjoint i64 %71, 4602678819172646912
  %73 = trunc nuw nsw i64 %69 to i32
  %74 = and i32 %73, 2047
  %75 = add nsw i32 %74, -1022
  br label %math.frexp.frexp__anon_9469.exit44

Then.i42:                                         ; preds = %Case.i40
  %76 = tail call range(i52 0, 53) i52 @llvm.ctlz.i52(i52 %68, i1 true)
  %77 = trunc nuw i52 %76 to i6
  %78 = add nuw i6 %77, 1
  %79 = and i64 %67, -9223372036854775808
  %80 = icmp ult i6 %77, -13
  %81 = zext i6 %78 to i52
  %82 = shl i52 %68, %81
  %83 = zext i52 %82 to i64
  %84 = select i1 %80, i64 %83, i64 0
  %85 = or disjoint i64 %79, %84
  %86 = or disjoint i64 %85, 4602678819172646912
  %87 = trunc nuw nsw i52 %76 to i32
  %88 = sub nuw nsw i32 -1022, %87
  br label %math.frexp.frexp__anon_9469.exit44

math.frexp.frexp__anon_9469.exit44:               ; preds = %Then.i42, %Default.i43, %Case.i40, %math.frexp.frexp__anon_9469.exit35
  %.sroa.3.0.i36 = phi i32 [ %75, %Default.i43 ], [ %88, %Then.i42 ], [ 0, %Case.i40 ], [ 0, %math.frexp.frexp__anon_9469.exit35 ]
  %.0.i37 = phi i64 [ %72, %Default.i43 ], [ %86, %Then.i42 ], [ %67, %Case.i40 ], [ %67, %math.frexp.frexp__anon_9469.exit35 ]
  %89 = bitcast i64 %.0.i37 to double
  %90 = add nsw i32 %.sroa.3.0.i27, %.sroa.3.0.i
  %91 = sub nsw i32 %90, %.sroa.3.0.i36
  %92 = icmp slt i32 %91, 107
  br i1 %92, label %Then6, label %Block11

Block6:                                           ; preds = %Block11, %Then6
  %.0 = phi double [ %114, %Then6 ], [ %115, %Block11 ]
  %93 = insertelement <2 x double> poison, double %43, i64 0
  %94 = insertelement <2 x double> %93, double %66, i64 1
  %95 = fmul <2 x double> %94, splat (double 0x41A0000002000000)
  %96 = fsub <2 x double> %94, %95
  %97 = fadd <2 x double> %95, %96
  %98 = extractelement <2 x double> %97, i64 0
  %99 = fsub double %43, %98
  %100 = extractelement <2 x double> %97, i64 1
  %101 = fsub double %66, %100
  %102 = fmul double %98, %100
  %103 = fmul double %98, %101
  %104 = fmul double %99, %100
  %105 = fadd double %104, %103
  %106 = fadd double %102, %105
  %107 = fsub double %102, %106
  %108 = fadd double %105, %107
  %109 = fmul double %99, %101
  %110 = fadd double %109, %108
  %111 = fadd double %106, %.0
  %112 = fcmp oeq double %111, 0.000000e+00
  br i1 %112, label %Then7, label %Else7

Then6:                                            ; preds = %math.frexp.frexp__anon_9469.exit44
  %113 = sub nsw i32 0, %91
  %114 = tail call fastcc double @math.ldexp.ldexp__anon_5959(double %89, i32 %113) #3
  br label %Block6

Block11:                                          ; preds = %math.frexp.frexp__anon_9469.exit44
  %115 = tail call double @llvm.copysign.f64(double 0x10000000000000, double %89)
  br label %Block6

Then7:                                            ; preds = %Block6
  %116 = tail call fastcc double @math.ldexp.ldexp__anon_5959(double %110, i32 %90) #3
  %117 = fadd double %111, %116
  br label %common.ret

Else7:                                            ; preds = %Block6
  %118 = fsub double %111, %106
  %119 = fsub double %.0, %118
  %120 = fsub double %111, %118
  %121 = fsub double %106, %120
  %122 = fadd double %119, %121
  %123 = fadd double %110, %122
  %124 = fsub double %123, %122
  %125 = fsub double %123, %124
  %126 = fsub double %122, %125
  %127 = fsub double %110, %124
  %128 = fadd double %127, %126
  %129 = fcmp une double %128, 0.000000e+00
  br i1 %129, label %Then.i47, label %compiler_rt.fma.add_adjusted.exit

Then.i47:                                         ; preds = %Else7
  %130 = bitcast double %123 to i64
  %131 = and i64 %130, 1
  %132 = icmp eq i64 %131, 0
  br i1 %132, label %Then1.i, label %compiler_rt.fma.add_adjusted.exit

Then1.i:                                          ; preds = %Then.i47
  %133 = bitcast double %128 to i64
  %134 = or disjoint i64 %130, 1
  %135 = xor i64 %133, %130
  %136 = lshr i64 %135, 62
  %137 = sub i64 %134, %136
  %138 = bitcast i64 %137 to double
  br label %compiler_rt.fma.add_adjusted.exit

compiler_rt.fma.add_adjusted.exit:                ; preds = %Then1.i, %Then.i47, %Else7
  %.sroa.0.0.i = phi double [ %138, %Then1.i ], [ %123, %Then.i47 ], [ %123, %Else7 ]
  %139 = tail call double @llvm.fabs.f64(double %111)
  %140 = bitcast double %139 to i64
  %141 = lshr i64 %140, 52
  %142 = trunc nuw nsw i64 %141 to i32
  switch i32 %142, label %Else2.i.i [
    i32 0, label %Then.i.i
    i32 2047, label %Then2.i.i
  ]

Then.i.i:                                         ; preds = %compiler_rt.fma.add_adjusted.exit
  %143 = icmp eq i64 %140, 0
  br i1 %143, label %math.ilogb.ilogb__anon_9491.exit, label %Else1.i.i

Else1.i.i:                                        ; preds = %Then.i.i
  %144 = tail call range(i64 1, 65) i64 @llvm.ctlz.i64(i64 %140, i1 true)
  %145 = trunc nuw nsw i64 %144 to i32
  %146 = sub nuw nsw i32 -1011, %145
  br label %math.ilogb.ilogb__anon_9491.exit

Then2.i.i:                                        ; preds = %compiler_rt.fma.add_adjusted.exit
  %147 = icmp samesign ugt i64 %140, 9218868437227405312
  %spec.select.i.i = select i1 %147, i32 -2147483648, i32 2147483647
  br label %math.ilogb.ilogb__anon_9491.exit

Else2.i.i:                                        ; preds = %compiler_rt.fma.add_adjusted.exit
  %148 = add nsw i32 %142, -1023
  br label %math.ilogb.ilogb__anon_9491.exit

math.ilogb.ilogb__anon_9491.exit:                 ; preds = %Else2.i.i, %Then2.i.i, %Else1.i.i, %Then.i.i
  %common.ret.op.i.i = phi i32 [ %146, %Else1.i.i ], [ %spec.select.i.i, %Then2.i.i ], [ %148, %Else2.i.i ], [ -2147483648, %Then.i.i ]
  %149 = add nsw i32 %common.ret.op.i.i, %90
  %150 = icmp sgt i32 %149, -1023
  br i1 %150, label %Then8, label %Else8

Then8:                                            ; preds = %math.ilogb.ilogb__anon_9491.exit
  %151 = fadd double %111, %.sroa.0.0.i
  %152 = tail call fastcc double @math.ldexp.ldexp__anon_5959(double %151, i32 %90) #3
  br label %common.ret

Else8:                                            ; preds = %math.ilogb.ilogb__anon_9491.exit
  %153 = tail call fastcc double @compiler_rt.fma.add_and_denorm(double %111, double %.sroa.0.0.i, i32 %90) #3
  br label %common.ret
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(inaccessiblemem: write) uwtable
declare hidden fastcc double @compiler_rt.fma.add_and_denorm(double, double, i32) unnamed_addr #1 align 1

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i52 @llvm.ctlz.i52(i52, i1 immarg) #0

; Function Attrs: nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.fabs.f64(double) #2

; Function Attrs: nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.copysign.f64(double, double) #2

attributes #0 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #1 = { mustprogress nofree norecurse nosync nounwind willreturn memory(inaccessiblemem: write) uwtable "frame-pointer"="all" "no-builtins" "target-cpu"="x86-64" "target-features"="+64bit,+cmov,+cx8,+fxsr,+idivq-to-divl,+macrofusion,+mmx,+nopl,+slow-3ops-lea,+slow-incdec,+sse,+sse2,+vzeroupper,+x87,-16bit-mode,-32bit-mode,-adx,-aes,-allow-light-256-bit,-amx-avx512,-amx-bf16,-amx-complex,-amx-fp16,-amx-fp8,-amx-int8,-amx-movrs,-amx-tf32,-amx-tile,-avx,-avx10.1,-avx10.2,-avx2,-avx512bf16,-avx512bitalg,-avx512bw,-avx512cd,-avx512dq,-avx512f,-avx512fp16,-avx512ifma,-avx512vbmi,-avx512vbmi2,-avx512vl,-avx512vnni,-avx512vp2intersect,-avx512vpopcntdq,-avxifma,-avxneconvert,-avxvnni,-avxvnniint16,-avxvnniint8,-bmi,-bmi2,-branch-hint,-branchfusion,-ccmp,-cf,-cldemote,-clflushopt,-clwb,-clzero,-cmpccxadd,-crc32,-cx16,-egpr,-enqcmd,-ermsb,-f16c,-false-deps-getmant,-false-deps-lzcnt-tzcnt,-false-deps-mulc,-false-deps-mullq,-false-deps-perm,-false-deps-popcnt,-false-deps-range,-fast-11bytenop,-fast-15bytenop,-fast-7bytenop,-fast-bextr,-fast-dpwssd,-fast-gather,-fast-hops,-fast-imm16,-fast-lzcnt,-fast-movbe,-fast-scalar-fsqrt,-fast-scalar-shift-masks,-fast-shld-rotate,-fast-variable-crosslane-shuffle,-fast-variable-perlane-shuffle,-fast-vector-fsqrt,-fast-vector-shift-masks,-faster-shift-than-shuffle,-fma,-fma4,-fsgsbase,-fsrm,-gfni,-harden-sls-ijmp,-harden-sls-ret,-hreset,-idivl-to-divb,-inline-asm-use-gpr32,-invpcid,-kl,-lea-sp,-lea-uses-ag,-lvi-cfi,-lvi-load-hardening,-lwp,-lzcnt,-movbe,-movdir64b,-movdiri,-movrs,-mwaitx,-ndd,-nf,-no-bypass-delay,-no-bypass-delay-blend,-no-bypass-delay-mov,-no-bypass-delay-shuffle,-pad-short-functions,-pclmul,-pconfig,-pku,-popcnt,-ppx,-prefer-128-bit,-prefer-256-bit,-prefer-legacy-setcc,-prefer-mask-registers,-prefer-movmsk-over-vtest,-prefer-no-gather,-prefer-no-scatter,-prefetchi,-prfchw,-ptwrite,-push2pop2,-raoint,-rdpid,-rdpru,-rdrnd,-rdseed,-retpoline,-retpoline-external-thunk,-retpoline-indirect-branches,-retpoline-indirect-calls,-rtm,-sahf,-sbb-dep-breaking,-serialize,-seses,-sgx,-sha,-sha512,-shstk,-slow-lea,-slow-pmaddwd,-slow-pmulld,-slow-pmullq,-slow-shld,-slow-two-mem-ops,-slow-unaligned-mem-16,-slow-unaligned-mem-32,-sm3,-sm4,-soft-float,-sse3,-sse4.1,-sse4.2,-sse4a,-sse-unaligned-mem,-ssse3,-tagged-globals,-tbm,-tsxldtrk,-tuning-fast-imm-vector-shift,-uintr,-use-glm-div-sqrt-costs,-use-slm-arith-costs,-usermsr,-vaes,-vpclmulqdq,-waitpkg,-wbnoinvd,-widekl,-xop,-xsave,-xsavec,-xsaveopt,-xsaves,-zu" }
attributes #2 = { nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none) }
attributes #3 = { nobuiltin }

!llvm.module.flags = !{!0, !1}

!0 = !{i32 2, !"Debug Info Version", i32 3}
!1 = !{i32 7, !"Dwarf Version", i32 4}
