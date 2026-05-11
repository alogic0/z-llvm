; ModuleID = 'BitcodeBuffer'
source_filename = "aggregates"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux5.10.0-gnu2.31.0"

@error_union_payload = alias i32 (i32), ptr @aggregates.error_union_payload
@optional_payload = alias i32 (i32, i32), ptr @aggregates.optional_payload
@slice_sum = alias i32 (ptr, i64), ptr @aggregates.slice_sum
@struct_sum = alias i32 (ptr), ptr @aggregates.struct_sum
@array_sum = alias i32 (i32, i32, i32), ptr @aggregates.array_sum

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define private range(i32 -1, 8) i32 @aggregates.error_union_payload(i32 %0) unnamed_addr #0 align 1 {
  %.not.i = icmp eq i32 %0, 0
  %2 = select i1 %.not.i, i32 7, i32 -1
  ret i32 %2
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define private i32 @aggregates.optional_payload(i32 %0, i32 %1) unnamed_addr #0 align 1 {
.thread:
  %.not = icmp eq i32 %0, 0
  %spec.select = select i1 %.not, i32 -1, i32 %1
  ret i32 %spec.select
}

; Function Attrs: nofree norecurse nosync nounwind memory(argmem: read) uwtable
define private i32 @aggregates.slice_sum(ptr nonnull readonly captures(none) %0, i64 %1) unnamed_addr #1 align 1 {
  %.not = icmp eq i64 %1, 0
  br i1 %.not, label %._crit_edge, label %.lr.ph.preheader

.lr.ph.preheader:                                 ; preds = %2
  %xtraiter = and i64 %1, 7
  %3 = icmp ult i64 %1, 8
  br i1 %3, label %._crit_edge.loopexit.unr-lcssa, label %.lr.ph.preheader.new

.lr.ph.preheader.new:                             ; preds = %.lr.ph.preheader
  %unroll_iter = and i64 %1, -8
  %invariant.gep = getelementptr i8, ptr %0, i64 4
  %invariant.gep15 = getelementptr i8, ptr %0, i64 8
  %invariant.gep17 = getelementptr i8, ptr %0, i64 12
  %invariant.gep19 = getelementptr i8, ptr %0, i64 16
  %invariant.gep21 = getelementptr i8, ptr %0, i64 20
  %invariant.gep23 = getelementptr i8, ptr %0, i64 24
  %invariant.gep25 = getelementptr i8, ptr %0, i64 28
  br label %.lr.ph

.lr.ph:                                           ; preds = %.lr.ph, %.lr.ph.preheader.new
  %.010 = phi i32 [ 0, %.lr.ph.preheader.new ], [ %20, %.lr.ph ]
  %.089 = phi i64 [ 0, %.lr.ph.preheader.new ], [ %21, %.lr.ph ]
  %niter = phi i64 [ 0, %.lr.ph.preheader.new ], [ %niter.next.7, %.lr.ph ]
  %4 = getelementptr inbounds [4 x i8], ptr %0, i64 %.089
  %5 = load i32, ptr %4, align 4
  %6 = add nsw i32 %5, %.010
  %gep = getelementptr [4 x i8], ptr %invariant.gep, i64 %.089
  %7 = load i32, ptr %gep, align 4
  %8 = add nsw i32 %7, %6
  %gep16 = getelementptr [4 x i8], ptr %invariant.gep15, i64 %.089
  %9 = load i32, ptr %gep16, align 4
  %10 = add nsw i32 %9, %8
  %gep18 = getelementptr [4 x i8], ptr %invariant.gep17, i64 %.089
  %11 = load i32, ptr %gep18, align 4
  %12 = add nsw i32 %11, %10
  %gep20 = getelementptr [4 x i8], ptr %invariant.gep19, i64 %.089
  %13 = load i32, ptr %gep20, align 4
  %14 = add nsw i32 %13, %12
  %gep22 = getelementptr [4 x i8], ptr %invariant.gep21, i64 %.089
  %15 = load i32, ptr %gep22, align 4
  %16 = add nsw i32 %15, %14
  %gep24 = getelementptr [4 x i8], ptr %invariant.gep23, i64 %.089
  %17 = load i32, ptr %gep24, align 4
  %18 = add nsw i32 %17, %16
  %gep26 = getelementptr [4 x i8], ptr %invariant.gep25, i64 %.089
  %19 = load i32, ptr %gep26, align 4
  %20 = add nsw i32 %19, %18
  %21 = add nuw i64 %.089, 8
  %niter.next.7 = add i64 %niter, 8
  %niter.ncmp.7 = icmp eq i64 %niter.next.7, %unroll_iter
  br i1 %niter.ncmp.7, label %._crit_edge.loopexit.unr-lcssa, label %.lr.ph

._crit_edge.loopexit.unr-lcssa:                   ; preds = %.lr.ph, %.lr.ph.preheader
  %.lcssa.ph = phi i32 [ poison, %.lr.ph.preheader ], [ %20, %.lr.ph ]
  %.010.unr = phi i32 [ 0, %.lr.ph.preheader ], [ %20, %.lr.ph ]
  %.089.unr = phi i64 [ 0, %.lr.ph.preheader ], [ %21, %.lr.ph ]
  %lcmp.mod.not = icmp eq i64 %xtraiter, 0
  br i1 %lcmp.mod.not, label %._crit_edge, label %.lr.ph.epil

.lr.ph.epil:                                      ; preds = %._crit_edge.loopexit.unr-lcssa, %.lr.ph.epil
  %.010.epil = phi i32 [ %24, %.lr.ph.epil ], [ %.010.unr, %._crit_edge.loopexit.unr-lcssa ]
  %.089.epil = phi i64 [ %25, %.lr.ph.epil ], [ %.089.unr, %._crit_edge.loopexit.unr-lcssa ]
  %epil.iter = phi i64 [ %epil.iter.next, %.lr.ph.epil ], [ 0, %._crit_edge.loopexit.unr-lcssa ]
  %22 = getelementptr inbounds [4 x i8], ptr %0, i64 %.089.epil
  %23 = load i32, ptr %22, align 4
  %24 = add nsw i32 %23, %.010.epil
  %25 = add nuw i64 %.089.epil, 1
  %epil.iter.next = add i64 %epil.iter, 1
  %epil.iter.cmp.not = icmp eq i64 %epil.iter.next, %xtraiter
  br i1 %epil.iter.cmp.not, label %._crit_edge, label %.lr.ph.epil, !llvm.loop !0

._crit_edge:                                      ; preds = %._crit_edge.loopexit.unr-lcssa, %.lr.ph.epil, %2
  %.0.lcssa = phi i32 [ 0, %2 ], [ %.lcssa.ph, %._crit_edge.loopexit.unr-lcssa ], [ %24, %.lr.ph.epil ]
  ret i32 %.0.lcssa
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(argmem: read) uwtable
define private i32 @aggregates.struct_sum(ptr nonnull readonly align 4 captures(none) %0) unnamed_addr #2 align 1 {
  %2 = load i32, ptr %0, align 4
  %3 = getelementptr inbounds nuw i8, ptr %0, i64 4
  %4 = load i32, ptr %3, align 4
  %5 = add nsw i32 %4, %2
  ret i32 %5
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define private i32 @aggregates.array_sum(i32 %0, i32 %1, i32 %2) unnamed_addr #0 align 1 {
  %4 = add nsw i32 %1, %0
  %5 = add nsw i32 %4, %2
  ret i32 %5
}

attributes #0 = { mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable "frame-pointer"="all" "target-cpu"="x86-64" "target-features"="+64bit,+cmov,+cx8,+fxsr,+idivq-to-divl,+macrofusion,+mmx,+nopl,+slow-3ops-lea,+slow-incdec,+sse,+sse2,+vzeroupper,+x87,-16bit-mode,-32bit-mode,-adx,-aes,-allow-light-256-bit,-amx-avx512,-amx-bf16,-amx-complex,-amx-fp16,-amx-fp8,-amx-int8,-amx-movrs,-amx-tf32,-amx-tile,-amx-transpose,-avx,-avx10.1-512,-avx10.2-512,-avx2,-avx512bf16,-avx512bitalg,-avx512bw,-avx512cd,-avx512dq,-avx512f,-avx512fp16,-avx512ifma,-avx512vbmi,-avx512vbmi2,-avx512vl,-avx512vnni,-avx512vp2intersect,-avx512vpopcntdq,-avxifma,-avxneconvert,-avxvnni,-avxvnniint16,-avxvnniint8,-bmi,-bmi2,-branch-hint,-branchfusion,-ccmp,-cf,-cldemote,-clflushopt,-clwb,-clzero,-cmpccxadd,-crc32,-cx16,-egpr,-enqcmd,-ermsb,-evex512,-f16c,-false-deps-getmant,-false-deps-lzcnt-tzcnt,-false-deps-mulc,-false-deps-mullq,-false-deps-perm,-false-deps-popcnt,-false-deps-range,-fast-11bytenop,-fast-15bytenop,-fast-7bytenop,-fast-bextr,-fast-dpwssd,-fast-gather,-fast-hops,-fast-imm16,-fast-lzcnt,-fast-movbe,-fast-scalar-fsqrt,-fast-scalar-shift-masks,-fast-shld-rotate,-fast-variable-crosslane-shuffle,-fast-variable-perlane-shuffle,-fast-vector-fsqrt,-fast-vector-shift-masks,-faster-shift-than-shuffle,-fma,-fma4,-fsgsbase,-fsrm,-gfni,-harden-sls-ijmp,-harden-sls-ret,-hreset,-idivl-to-divb,-inline-asm-use-gpr32,-invpcid,-kl,-lea-sp,-lea-uses-ag,-lvi-cfi,-lvi-load-hardening,-lwp,-lzcnt,-movbe,-movdir64b,-movdiri,-movrs,-mwaitx,-ndd,-nf,-no-bypass-delay,-no-bypass-delay-blend,-no-bypass-delay-mov,-no-bypass-delay-shuffle,-pad-short-functions,-pclmul,-pconfig,-pku,-popcnt,-ppx,-prefer-128-bit,-prefer-256-bit,-prefer-mask-registers,-prefer-movmsk-over-vtest,-prefer-no-gather,-prefer-no-scatter,-prefetchi,-prfchw,-ptwrite,-push2pop2,-raoint,-rdpid,-rdpru,-rdrnd,-rdseed,-retpoline,-retpoline-external-thunk,-retpoline-indirect-branches,-retpoline-indirect-calls,-rtm,-sahf,-sbb-dep-breaking,-serialize,-seses,-sgx,-sha,-sha512,-shstk,-slow-lea,-slow-pmaddwd,-slow-pmulld,-slow-shld,-slow-two-mem-ops,-slow-unaligned-mem-16,-slow-unaligned-mem-32,-sm3,-sm4,-soft-float,-sse3,-sse4.1,-sse4.2,-sse4a,-sse-unaligned-mem,-ssse3,-tagged-globals,-tbm,-tsxldtrk,-tuning-fast-imm-vector-shift,-uintr,-use-glm-div-sqrt-costs,-use-slm-arith-costs,-usermsr,-vaes,-vpclmulqdq,-waitpkg,-wbnoinvd,-widekl,-xop,-xsave,-xsavec,-xsaveopt,-xsaves,-zu" }
attributes #1 = { nofree norecurse nosync nounwind memory(argmem: read) uwtable "frame-pointer"="all" "target-cpu"="x86-64" "target-features"="+64bit,+cmov,+cx8,+fxsr,+idivq-to-divl,+macrofusion,+mmx,+nopl,+slow-3ops-lea,+slow-incdec,+sse,+sse2,+vzeroupper,+x87,-16bit-mode,-32bit-mode,-adx,-aes,-allow-light-256-bit,-amx-avx512,-amx-bf16,-amx-complex,-amx-fp16,-amx-fp8,-amx-int8,-amx-movrs,-amx-tf32,-amx-tile,-amx-transpose,-avx,-avx10.1-512,-avx10.2-512,-avx2,-avx512bf16,-avx512bitalg,-avx512bw,-avx512cd,-avx512dq,-avx512f,-avx512fp16,-avx512ifma,-avx512vbmi,-avx512vbmi2,-avx512vl,-avx512vnni,-avx512vp2intersect,-avx512vpopcntdq,-avxifma,-avxneconvert,-avxvnni,-avxvnniint16,-avxvnniint8,-bmi,-bmi2,-branch-hint,-branchfusion,-ccmp,-cf,-cldemote,-clflushopt,-clwb,-clzero,-cmpccxadd,-crc32,-cx16,-egpr,-enqcmd,-ermsb,-evex512,-f16c,-false-deps-getmant,-false-deps-lzcnt-tzcnt,-false-deps-mulc,-false-deps-mullq,-false-deps-perm,-false-deps-popcnt,-false-deps-range,-fast-11bytenop,-fast-15bytenop,-fast-7bytenop,-fast-bextr,-fast-dpwssd,-fast-gather,-fast-hops,-fast-imm16,-fast-lzcnt,-fast-movbe,-fast-scalar-fsqrt,-fast-scalar-shift-masks,-fast-shld-rotate,-fast-variable-crosslane-shuffle,-fast-variable-perlane-shuffle,-fast-vector-fsqrt,-fast-vector-shift-masks,-faster-shift-than-shuffle,-fma,-fma4,-fsgsbase,-fsrm,-gfni,-harden-sls-ijmp,-harden-sls-ret,-hreset,-idivl-to-divb,-inline-asm-use-gpr32,-invpcid,-kl,-lea-sp,-lea-uses-ag,-lvi-cfi,-lvi-load-hardening,-lwp,-lzcnt,-movbe,-movdir64b,-movdiri,-movrs,-mwaitx,-ndd,-nf,-no-bypass-delay,-no-bypass-delay-blend,-no-bypass-delay-mov,-no-bypass-delay-shuffle,-pad-short-functions,-pclmul,-pconfig,-pku,-popcnt,-ppx,-prefer-128-bit,-prefer-256-bit,-prefer-mask-registers,-prefer-movmsk-over-vtest,-prefer-no-gather,-prefer-no-scatter,-prefetchi,-prfchw,-ptwrite,-push2pop2,-raoint,-rdpid,-rdpru,-rdrnd,-rdseed,-retpoline,-retpoline-external-thunk,-retpoline-indirect-branches,-retpoline-indirect-calls,-rtm,-sahf,-sbb-dep-breaking,-serialize,-seses,-sgx,-sha,-sha512,-shstk,-slow-lea,-slow-pmaddwd,-slow-pmulld,-slow-shld,-slow-two-mem-ops,-slow-unaligned-mem-16,-slow-unaligned-mem-32,-sm3,-sm4,-soft-float,-sse3,-sse4.1,-sse4.2,-sse4a,-sse-unaligned-mem,-ssse3,-tagged-globals,-tbm,-tsxldtrk,-tuning-fast-imm-vector-shift,-uintr,-use-glm-div-sqrt-costs,-use-slm-arith-costs,-usermsr,-vaes,-vpclmulqdq,-waitpkg,-wbnoinvd,-widekl,-xop,-xsave,-xsavec,-xsaveopt,-xsaves,-zu" }
attributes #2 = { mustprogress nofree norecurse nosync nounwind willreturn memory(argmem: read) uwtable "frame-pointer"="all" "target-cpu"="x86-64" "target-features"="+64bit,+cmov,+cx8,+fxsr,+idivq-to-divl,+macrofusion,+mmx,+nopl,+slow-3ops-lea,+slow-incdec,+sse,+sse2,+vzeroupper,+x87,-16bit-mode,-32bit-mode,-adx,-aes,-allow-light-256-bit,-amx-avx512,-amx-bf16,-amx-complex,-amx-fp16,-amx-fp8,-amx-int8,-amx-movrs,-amx-tf32,-amx-tile,-amx-transpose,-avx,-avx10.1-512,-avx10.2-512,-avx2,-avx512bf16,-avx512bitalg,-avx512bw,-avx512cd,-avx512dq,-avx512f,-avx512fp16,-avx512ifma,-avx512vbmi,-avx512vbmi2,-avx512vl,-avx512vnni,-avx512vp2intersect,-avx512vpopcntdq,-avxifma,-avxneconvert,-avxvnni,-avxvnniint16,-avxvnniint8,-bmi,-bmi2,-branch-hint,-branchfusion,-ccmp,-cf,-cldemote,-clflushopt,-clwb,-clzero,-cmpccxadd,-crc32,-cx16,-egpr,-enqcmd,-ermsb,-evex512,-f16c,-false-deps-getmant,-false-deps-lzcnt-tzcnt,-false-deps-mulc,-false-deps-mullq,-false-deps-perm,-false-deps-popcnt,-false-deps-range,-fast-11bytenop,-fast-15bytenop,-fast-7bytenop,-fast-bextr,-fast-dpwssd,-fast-gather,-fast-hops,-fast-imm16,-fast-lzcnt,-fast-movbe,-fast-scalar-fsqrt,-fast-scalar-shift-masks,-fast-shld-rotate,-fast-variable-crosslane-shuffle,-fast-variable-perlane-shuffle,-fast-vector-fsqrt,-fast-vector-shift-masks,-faster-shift-than-shuffle,-fma,-fma4,-fsgsbase,-fsrm,-gfni,-harden-sls-ijmp,-harden-sls-ret,-hreset,-idivl-to-divb,-inline-asm-use-gpr32,-invpcid,-kl,-lea-sp,-lea-uses-ag,-lvi-cfi,-lvi-load-hardening,-lwp,-lzcnt,-movbe,-movdir64b,-movdiri,-movrs,-mwaitx,-ndd,-nf,-no-bypass-delay,-no-bypass-delay-blend,-no-bypass-delay-mov,-no-bypass-delay-shuffle,-pad-short-functions,-pclmul,-pconfig,-pku,-popcnt,-ppx,-prefer-128-bit,-prefer-256-bit,-prefer-mask-registers,-prefer-movmsk-over-vtest,-prefer-no-gather,-prefer-no-scatter,-prefetchi,-prfchw,-ptwrite,-push2pop2,-raoint,-rdpid,-rdpru,-rdrnd,-rdseed,-retpoline,-retpoline-external-thunk,-retpoline-indirect-branches,-retpoline-indirect-calls,-rtm,-sahf,-sbb-dep-breaking,-serialize,-seses,-sgx,-sha,-sha512,-shstk,-slow-lea,-slow-pmaddwd,-slow-pmulld,-slow-shld,-slow-two-mem-ops,-slow-unaligned-mem-16,-slow-unaligned-mem-32,-sm3,-sm4,-soft-float,-sse3,-sse4.1,-sse4.2,-sse4a,-sse-unaligned-mem,-ssse3,-tagged-globals,-tbm,-tsxldtrk,-tuning-fast-imm-vector-shift,-uintr,-use-glm-div-sqrt-costs,-use-slm-arith-costs,-usermsr,-vaes,-vpclmulqdq,-waitpkg,-wbnoinvd,-widekl,-xop,-xsave,-xsavec,-xsaveopt,-xsaves,-zu" }

!llvm.module.flags = !{}

!0 = distinct !{!0, !1}
!1 = !{!"llvm.loop.unroll.disable"}
