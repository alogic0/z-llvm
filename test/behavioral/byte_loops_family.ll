; Exact retained definitions; see docs/evidence/composed_byte_loops.md.
target triple = "x86_64-unknown-linux-gnu"
define private range(i32 0, 2) i32 @compiler_rt.bcmp(ptr readonly align 1 captures(none) %0, ptr readonly align 1 captures(none) %1, i64 %2) unnamed_addr #2 align 1 {
  %.not6 = icmp eq i64 %2, 0
  br i1 %.not6, label %common.ret, label %.lr.ph

common.ret:                                       ; preds = %4, %.lr.ph, %3
  %common.ret.op = phi i32 [ 0, %3 ], [ 1, %.lr.ph ], [ 0, %4 ]
  ret i32 %common.ret.op

4:                                                ; preds = %.lr.ph
  %5 = add nuw i64 %.07, 1
  %.not = icmp eq i64 %5, %2
  br i1 %.not, label %common.ret, label %.lr.ph

.lr.ph:                                           ; preds = %3, %4
  %.07 = phi i64 [ %5, %4 ], [ 0, %3 ]
  %6 = getelementptr inbounds [1 x i8], ptr %0, i64 %.07
  %7 = load i8, ptr %6, align 1
  %8 = getelementptr inbounds [1 x i8], ptr %1, i64 %.07
  %9 = load i8, ptr %8, align 1
  %.not5 = icmp eq i8 %7, %9
  br i1 %.not5, label %4, label %common.ret
}

define private range(i32 -255, 256) i32 @compiler_rt.memcmp(ptr nonnull readonly align 1 captures(none) %0, ptr nonnull readonly align 1 captures(none) %1, i64 %2) unnamed_addr #1 align 1 {
  %.not9 = icmp eq i64 %2, 0
  br i1 %.not9, label %common.ret, label %.lr.ph

common.ret:                                       ; preds = %4, %.lr.ph, %3
  %common.ret.op = phi i32 [ 0, %3 ], [ %12, %.lr.ph ], [ 0, %4 ]
  ret i32 %common.ret.op

4:                                                ; preds = %.lr.ph
  %5 = add nuw i64 %.06, 1
  %exitcond.not = icmp eq i64 %5, %2
  br i1 %exitcond.not, label %common.ret, label %.lr.ph

.lr.ph:                                           ; preds = %3, %4
  %.06 = phi i64 [ %5, %4 ], [ 0, %3 ]
  %6 = getelementptr inbounds [1 x i8], ptr %0, i64 %.06
  %7 = load i8, ptr %6, align 1
  %8 = zext i8 %7 to i32
  %9 = getelementptr inbounds [1 x i8], ptr %1, i64 %.06
  %10 = load i8, ptr %9, align 1
  %11 = zext i8 %10 to i32
  %12 = sub nsw i32 %8, %11
  %.not = icmp eq i32 %12, 0
  br i1 %.not, label %4, label %common.ret
}

define private nonnull ptr @compiler_rt.ssp.__strncpy_chk(ptr nonnull returned writeonly align 1 captures(ret: address, provenance) %0, ptr nonnull readonly align 1 captures(none) %1, i64 %2, i64 %3) unnamed_addr #10 align 1 {
  %5 = icmp ult i64 %3, %2
  br i1 %5, label %6, label %.preheader

.preheader:                                       ; preds = %4
  %.not18 = icmp eq i64 %2, 0
  br i1 %.not18, label %.critedge, label %.lr.ph

6:                                                ; preds = %4
  tail call void @llvm.trap()
  unreachable

.lr.ph:                                           ; preds = %.preheader, %9
  %.013 = phi i64 [ %11, %9 ], [ 0, %.preheader ]
  %7 = getelementptr inbounds [1 x i8], ptr %1, i64 %.013
  %8 = load i8, ptr %7, align 1
  %.not = icmp eq i8 %8, 0
  br i1 %.not, label %.critedge, label %9

9:                                                ; preds = %.lr.ph
  %10 = getelementptr inbounds [1 x i8], ptr %0, i64 %.013
  store i8 %8, ptr %10, align 1
  %11 = add nuw i64 %.013, 1
  %exitcond.not = icmp eq i64 %11, %2
  br i1 %exitcond.not, label %._crit_edge, label %.lr.ph

.critedge:                                        ; preds = %.lr.ph, %.preheader
  %.0.lcssa = phi i64 [ 0, %.preheader ], [ %.013, %.lr.ph ]
  %12 = icmp ult i64 %.0.lcssa, %2
  br i1 %12, label %.lr.ph17.preheader, label %._crit_edge

.lr.ph17.preheader:                               ; preds = %.critedge
  %scevgep = getelementptr i8, ptr %0, i64 %.0.lcssa
  %13 = sub nuw i64 %2, %.0.lcssa
  tail call void @llvm.memset.p0.i64(ptr align 1 %scevgep, i8 0, i64 %13, i1 false)
  br label %._crit_edge

._crit_edge:                                      ; preds = %9, %.lr.ph17.preheader, %.critedge
  ret ptr %0
}
attributes #1 = { nofree norecurse nosync nounwind memory(argmem: read) uwtable "frame-pointer"="all" "target-cpu"="x86-64" "target-features"="+64bit,+cmov,+cx8,+fxsr,+idivq-to-divl,+macrofusion,+mmx,+nopl,+slow-3ops-lea,+slow-incdec,+sse,+sse2,+vzeroupper,+x87,-16bit-mode,-32bit-mode,-adx,-aes,-allow-light-256-bit,-amx-avx512,-amx-bf16,-amx-complex,-amx-fp16,-amx-fp8,-amx-int8,-amx-movrs,-amx-tf32,-amx-tile,-avx,-avx10.1,-avx10.2,-avx2,-avx512bf16,-avx512bitalg,-avx512bw,-avx512cd,-avx512dq,-avx512f,-avx512fp16,-avx512ifma,-avx512vbmi,-avx512vbmi2,-avx512vl,-avx512vnni,-avx512vp2intersect,-avx512vpopcntdq,-avxifma,-avxneconvert,-avxvnni,-avxvnniint16,-avxvnniint8,-bmi,-bmi2,-branch-hint,-branchfusion,-ccmp,-cf,-cldemote,-clflushopt,-clwb,-clzero,-cmpccxadd,-crc32,-cx16,-egpr,-enqcmd,-ermsb,-f16c,-false-deps-getmant,-false-deps-lzcnt-tzcnt,-false-deps-mulc,-false-deps-mullq,-false-deps-perm,-false-deps-popcnt,-false-deps-range,-fast-11bytenop,-fast-15bytenop,-fast-7bytenop,-fast-bextr,-fast-dpwssd,-fast-gather,-fast-hops,-fast-imm16,-fast-lzcnt,-fast-movbe,-fast-scalar-fsqrt,-fast-scalar-shift-masks,-fast-shld-rotate,-fast-variable-crosslane-shuffle,-fast-variable-perlane-shuffle,-fast-vector-fsqrt,-fast-vector-shift-masks,-faster-shift-than-shuffle,-fma,-fma4,-fsgsbase,-fsrm,-gfni,-harden-sls-ijmp,-harden-sls-ret,-hreset,-idivl-to-divb,-inline-asm-use-gpr32,-invpcid,-kl,-lea-sp,-lea-uses-ag,-lvi-cfi,-lvi-load-hardening,-lwp,-lzcnt,-movbe,-movdir64b,-movdiri,-movrs,-mwaitx,-ndd,-nf,-no-bypass-delay,-no-bypass-delay-blend,-no-bypass-delay-mov,-no-bypass-delay-shuffle,-pad-short-functions,-pclmul,-pconfig,-pku,-popcnt,-ppx,-prefer-128-bit,-prefer-256-bit,-prefer-legacy-setcc,-prefer-mask-registers,-prefer-movmsk-over-vtest,-prefer-no-gather,-prefer-no-scatter,-prefetchi,-prfchw,-ptwrite,-push2pop2,-raoint,-rdpid,-rdpru,-rdrnd,-rdseed,-retpoline,-retpoline-external-thunk,-retpoline-indirect-branches,-retpoline-indirect-calls,-rtm,-sahf,-sbb-dep-breaking,-serialize,-seses,-sgx,-sha,-sha512,-shstk,-slow-lea,-slow-pmaddwd,-slow-pmulld,-slow-pmullq,-slow-shld,-slow-two-mem-ops,-slow-unaligned-mem-16,-slow-unaligned-mem-32,-sm3,-sm4,-soft-float,-sse3,-sse4.1,-sse4.2,-sse4a,-sse-unaligned-mem,-ssse3,-tagged-globals,-tbm,-tsxldtrk,-tuning-fast-imm-vector-shift,-uintr,-use-glm-div-sqrt-costs,-use-slm-arith-costs,-usermsr,-vaes,-vpclmulqdq,-waitpkg,-wbnoinvd,-widekl,-xop,-xsave,-xsavec,-xsaveopt,-xsaves,-zu" }
attributes #2 = { nofree norecurse nosync nounwind null_pointer_is_valid memory(argmem: read) uwtable "frame-pointer"="all" "target-cpu"="x86-64" "target-features"="+64bit,+cmov,+cx8,+fxsr,+idivq-to-divl,+macrofusion,+mmx,+nopl,+slow-3ops-lea,+slow-incdec,+sse,+sse2,+vzeroupper,+x87,-16bit-mode,-32bit-mode,-adx,-aes,-allow-light-256-bit,-amx-avx512,-amx-bf16,-amx-complex,-amx-fp16,-amx-fp8,-amx-int8,-amx-movrs,-amx-tf32,-amx-tile,-avx,-avx10.1,-avx10.2,-avx2,-avx512bf16,-avx512bitalg,-avx512bw,-avx512cd,-avx512dq,-avx512f,-avx512fp16,-avx512ifma,-avx512vbmi,-avx512vbmi2,-avx512vl,-avx512vnni,-avx512vp2intersect,-avx512vpopcntdq,-avxifma,-avxneconvert,-avxvnni,-avxvnniint16,-avxvnniint8,-bmi,-bmi2,-branch-hint,-branchfusion,-ccmp,-cf,-cldemote,-clflushopt,-clwb,-clzero,-cmpccxadd,-crc32,-cx16,-egpr,-enqcmd,-ermsb,-f16c,-false-deps-getmant,-false-deps-lzcnt-tzcnt,-false-deps-mulc,-false-deps-mullq,-false-deps-perm,-false-deps-popcnt,-false-deps-range,-fast-11bytenop,-fast-15bytenop,-fast-7bytenop,-fast-bextr,-fast-dpwssd,-fast-gather,-fast-hops,-fast-imm16,-fast-lzcnt,-fast-movbe,-fast-scalar-fsqrt,-fast-scalar-shift-masks,-fast-shld-rotate,-fast-variable-crosslane-shuffle,-fast-variable-perlane-shuffle,-fast-vector-fsqrt,-fast-vector-shift-masks,-faster-shift-than-shuffle,-fma,-fma4,-fsgsbase,-fsrm,-gfni,-harden-sls-ijmp,-harden-sls-ret,-hreset,-idivl-to-divb,-inline-asm-use-gpr32,-invpcid,-kl,-lea-sp,-lea-uses-ag,-lvi-cfi,-lvi-load-hardening,-lwp,-lzcnt,-movbe,-movdir64b,-movdiri,-movrs,-mwaitx,-ndd,-nf,-no-bypass-delay,-no-bypass-delay-blend,-no-bypass-delay-mov,-no-bypass-delay-shuffle,-pad-short-functions,-pclmul,-pconfig,-pku,-popcnt,-ppx,-prefer-128-bit,-prefer-256-bit,-prefer-legacy-setcc,-prefer-mask-registers,-prefer-movmsk-over-vtest,-prefer-no-gather,-prefer-no-scatter,-prefetchi,-prfchw,-ptwrite,-push2pop2,-raoint,-rdpid,-rdpru,-rdrnd,-rdseed,-retpoline,-retpoline-external-thunk,-retpoline-indirect-branches,-retpoline-indirect-calls,-rtm,-sahf,-sbb-dep-breaking,-serialize,-seses,-sgx,-sha,-sha512,-shstk,-slow-lea,-slow-pmaddwd,-slow-pmulld,-slow-pmullq,-slow-shld,-slow-two-mem-ops,-slow-unaligned-mem-16,-slow-unaligned-mem-32,-sm3,-sm4,-soft-float,-sse3,-sse4.1,-sse4.2,-sse4a,-sse-unaligned-mem,-ssse3,-tagged-globals,-tbm,-tsxldtrk,-tuning-fast-imm-vector-shift,-uintr,-use-glm-div-sqrt-costs,-use-slm-arith-costs,-usermsr,-vaes,-vpclmulqdq,-waitpkg,-wbnoinvd,-widekl,-xop,-xsave,-xsavec,-xsaveopt,-xsaves,-zu" }
attributes #10 = { nounwind memory(argmem: readwrite, inaccessiblemem: write) uwtable "frame-pointer"="all" "target-cpu"="x86-64" "target-features"="+64bit,+cmov,+cx8,+fxsr,+idivq-to-divl,+macrofusion,+mmx,+nopl,+slow-3ops-lea,+slow-incdec,+sse,+sse2,+vzeroupper,+x87,-16bit-mode,-32bit-mode,-adx,-aes,-allow-light-256-bit,-amx-avx512,-amx-bf16,-amx-complex,-amx-fp16,-amx-fp8,-amx-int8,-amx-movrs,-amx-tf32,-amx-tile,-avx,-avx10.1,-avx10.2,-avx2,-avx512bf16,-avx512bitalg,-avx512bw,-avx512cd,-avx512dq,-avx512f,-avx512fp16,-avx512ifma,-avx512vbmi,-avx512vbmi2,-avx512vl,-avx512vnni,-avx512vp2intersect,-avx512vpopcntdq,-avxifma,-avxneconvert,-avxvnni,-avxvnniint16,-avxvnniint8,-bmi,-bmi2,-branch-hint,-branchfusion,-ccmp,-cf,-cldemote,-clflushopt,-clwb,-clzero,-cmpccxadd,-crc32,-cx16,-egpr,-enqcmd,-ermsb,-f16c,-false-deps-getmant,-false-deps-lzcnt-tzcnt,-false-deps-mulc,-false-deps-mullq,-false-deps-perm,-false-deps-popcnt,-false-deps-range,-fast-11bytenop,-fast-15bytenop,-fast-7bytenop,-fast-bextr,-fast-dpwssd,-fast-gather,-fast-hops,-fast-imm16,-fast-lzcnt,-fast-movbe,-fast-scalar-fsqrt,-fast-scalar-shift-masks,-fast-shld-rotate,-fast-variable-crosslane-shuffle,-fast-variable-perlane-shuffle,-fast-vector-fsqrt,-fast-vector-shift-masks,-faster-shift-than-shuffle,-fma,-fma4,-fsgsbase,-fsrm,-gfni,-harden-sls-ijmp,-harden-sls-ret,-hreset,-idivl-to-divb,-inline-asm-use-gpr32,-invpcid,-kl,-lea-sp,-lea-uses-ag,-lvi-cfi,-lvi-load-hardening,-lwp,-lzcnt,-movbe,-movdir64b,-movdiri,-movrs,-mwaitx,-ndd,-nf,-no-bypass-delay,-no-bypass-delay-blend,-no-bypass-delay-mov,-no-bypass-delay-shuffle,-pad-short-functions,-pclmul,-pconfig,-pku,-popcnt,-ppx,-prefer-128-bit,-prefer-256-bit,-prefer-legacy-setcc,-prefer-mask-registers,-prefer-movmsk-over-vtest,-prefer-no-gather,-prefer-no-scatter,-prefetchi,-prfchw,-ptwrite,-push2pop2,-raoint,-rdpid,-rdpru,-rdrnd,-rdseed,-retpoline,-retpoline-external-thunk,-retpoline-indirect-branches,-retpoline-indirect-calls,-rtm,-sahf,-sbb-dep-breaking,-serialize,-seses,-sgx,-sha,-sha512,-shstk,-slow-lea,-slow-pmaddwd,-slow-pmulld,-slow-pmullq,-slow-shld,-slow-two-mem-ops,-slow-unaligned-mem-16,-slow-unaligned-mem-32,-sm3,-sm4,-soft-float,-sse3,-sse4.1,-sse4.2,-sse4a,-sse-unaligned-mem,-ssse3,-tagged-globals,-tbm,-tsxldtrk,-tuning-fast-imm-vector-shift,-uintr,-use-glm-div-sqrt-costs,-use-slm-arith-costs,-usermsr,-vaes,-vpclmulqdq,-waitpkg,-wbnoinvd,-widekl,-xop,-xsave,-xsavec,-xsaveopt,-xsaves,-zu" }
declare void @llvm.trap()
declare void @llvm.memset.p0.i64(ptr, i8, i64, i1 immarg)

@family_strncpy_checked = alias ptr (ptr, ptr, i64, i64), ptr @compiler_rt.ssp.__strncpy_chk
@family_bcmp = alias i32 (ptr, ptr, i64), ptr @compiler_rt.bcmp
@family_memcmp = alias i32 (ptr, ptr, i64), ptr @compiler_rt.memcmp
