; Exact retained compiler_rt.ssp.__memcpy_chk definition.
target triple = "x86_64-unknown-linux-gnu"
@family_memcpy_checked = alias ptr (ptr, ptr, i64, i64), ptr @compiler_rt.ssp.__memcpy_chk
declare void @llvm.trap()
declare void @llvm.experimental.noalias.scope.decl(metadata)
declare void @llvm.memcpy.p0.p0.i64(ptr, ptr, i64, i1)

define private ptr @compiler_rt.ssp.__memcpy_chk(ptr noalias returned writeonly align 1 captures(ret: address, provenance) %0, ptr noalias readonly align 1 %1, i64 %2, i64 %3) unnamed_addr #9 align 1 {
  %5 = icmp ult i64 %3, %2
  br i1 %5, label %6, label %7

6:                                                ; preds = %4
  tail call void @llvm.trap()
  unreachable

7:                                                ; preds = %4
  tail call void @llvm.experimental.noalias.scope.decl(metadata !0)
  tail call void @llvm.experimental.noalias.scope.decl(metadata !3)
  %8 = icmp ult i64 %2, 16
  br i1 %8, label %9, label %38

9:                                                ; preds = %7
  %10 = icmp samesign ult i64 %2, 4
  br i1 %10, label %11, label %13

11:                                               ; preds = %9
  %12 = icmp eq i64 %2, 0
  br i1 %12, label %compiler_rt.memcpy.memcpyFast.exit, label %28

13:                                               ; preds = %9
  %14 = lshr i64 %2, 1
  %15 = and i64 %14, 4
  %16 = add nsw i64 %2, -4
  %17 = sub nuw nsw i64 %16, %15
  %18 = load i32, ptr %1, align 1, !alias.scope !3, !noalias !0
  store i32 %18, ptr %0, align 1, !alias.scope !0, !noalias !3
  %19 = getelementptr inbounds nuw [1 x i8], ptr %0, i64 %15
  %20 = getelementptr inbounds nuw [1 x i8], ptr %1, i64 %15
  %21 = load i32, ptr %20, align 1, !alias.scope !3, !noalias !0
  store i32 %21, ptr %19, align 1, !alias.scope !0, !noalias !3
  %22 = getelementptr inbounds nuw [1 x i8], ptr %0, i64 %17
  %23 = getelementptr inbounds nuw [1 x i8], ptr %1, i64 %17
  %24 = load i32, ptr %23, align 1, !alias.scope !3, !noalias !0
  store i32 %24, ptr %22, align 1, !alias.scope !0, !noalias !3
  %25 = getelementptr inbounds nuw [1 x i8], ptr %0, i64 %16
  %26 = getelementptr inbounds nuw [1 x i8], ptr %1, i64 %16
  %27 = load i32, ptr %26, align 1, !alias.scope !3, !noalias !0
  store i32 %27, ptr %25, align 1, !alias.scope !0, !noalias !3
  br label %compiler_rt.memcpy.memcpyFast.exit

28:                                               ; preds = %11
  %29 = load i8, ptr %1, align 1, !alias.scope !3, !noalias !0
  store i8 %29, ptr %0, align 1, !alias.scope !0, !noalias !3
  %30 = lshr i64 %2, 1
  %31 = getelementptr inbounds nuw [1 x i8], ptr %0, i64 %30
  %32 = getelementptr inbounds nuw [1 x i8], ptr %1, i64 %30
  %33 = load i8, ptr %32, align 1, !alias.scope !3, !noalias !0
  store i8 %33, ptr %31, align 1, !alias.scope !0, !noalias !3
  %34 = add nsw i64 %2, -1
  %35 = getelementptr inbounds nuw [1 x i8], ptr %0, i64 %34
  %36 = getelementptr inbounds nuw [1 x i8], ptr %1, i64 %34
  %37 = load i8, ptr %36, align 1, !alias.scope !3, !noalias !0
  store i8 %37, ptr %35, align 1, !alias.scope !0, !noalias !3
  br label %compiler_rt.memcpy.memcpyFast.exit

38:                                               ; preds = %7
  %39 = icmp ult i64 %2, 64
  br i1 %39, label %.critedge2.i, label %._crit_edge.i

.critedge2.i:                                     ; preds = %38
  %40 = lshr i64 %2, 1
  %41 = and i64 %40, 16
  %42 = add nsw i64 %2, -16
  %43 = sub nuw nsw i64 %42, %41
  %44 = load <16 x i8>, ptr %1, align 1, !alias.scope !3, !noalias !0
  store <16 x i8> %44, ptr %0, align 1, !alias.scope !0, !noalias !3
  %45 = getelementptr inbounds nuw [1 x i8], ptr %0, i64 %41
  %46 = getelementptr inbounds nuw [1 x i8], ptr %1, i64 %41
  %47 = load <16 x i8>, ptr %46, align 1, !alias.scope !3, !noalias !0
  store <16 x i8> %47, ptr %45, align 1, !alias.scope !0, !noalias !3
  %48 = getelementptr inbounds nuw [1 x i8], ptr %0, i64 %43
  %49 = getelementptr inbounds nuw [1 x i8], ptr %1, i64 %43
  %50 = load <16 x i8>, ptr %49, align 1, !alias.scope !3, !noalias !0
  store <16 x i8> %50, ptr %48, align 1, !alias.scope !0, !noalias !3
  %51 = getelementptr inbounds nuw [1 x i8], ptr %0, i64 %42
  %52 = getelementptr inbounds nuw [1 x i8], ptr %1, i64 %42
  %53 = load <16 x i8>, ptr %52, align 1, !alias.scope !3, !noalias !0
  store <16 x i8> %53, ptr %51, align 1, !alias.scope !0, !noalias !3
  br label %compiler_rt.memcpy.memcpyFast.exit

._crit_edge.i:                                    ; preds = %38
  %54 = load <16 x i8>, ptr %1, align 1, !alias.scope !3, !noalias !0
  store <16 x i8> %54, ptr %0, align 1, !alias.scope !0, !noalias !3
  %55 = ptrtoint ptr %1 to i64
  %56 = and i64 %55, 15
  %57 = sub nuw nsw i64 16, %56
  %58 = sub nuw i64 %2, %57
  %59 = and i64 %58, -16
  %60 = getelementptr [1 x i8], ptr %1, i64 %57
  %61 = getelementptr [1 x i8], ptr %0, i64 %57
  tail call void @llvm.memcpy.p0.p0.i64(ptr align 1 %61, ptr readonly align 16 %60, i64 %59, i1 false), !alias.scope !5
  %62 = add i64 %2, -16
  %63 = getelementptr inbounds [1 x i8], ptr %0, i64 %62
  %64 = getelementptr inbounds [1 x i8], ptr %1, i64 %62
  %65 = load <16 x i8>, ptr %64, align 1, !alias.scope !3, !noalias !0
  store <16 x i8> %65, ptr %63, align 1, !alias.scope !0, !noalias !3
  br label %compiler_rt.memcpy.memcpyFast.exit

compiler_rt.memcpy.memcpyFast.exit:               ; preds = %11, %13, %28, %.critedge2.i, %._crit_edge.i
  ret ptr %0
}

attributes #9 = { nounwind memory(argmem: readwrite, inaccessiblemem: readwrite) uwtable "frame-pointer"="all" "target-cpu"="x86-64" "target-features"="+64bit,+cmov,+cx8,+fxsr,+idivq-to-divl,+macrofusion,+mmx,+nopl,+slow-3ops-lea,+slow-incdec,+sse,+sse2,+vzeroupper,+x87,-16bit-mode,-32bit-mode,-adx,-aes,-allow-light-256-bit,-amx-avx512,-amx-bf16,-amx-complex,-amx-fp16,-amx-fp8,-amx-int8,-amx-movrs,-amx-tf32,-amx-tile,-avx,-avx10.1,-avx10.2,-avx2,-avx512bf16,-avx512bitalg,-avx512bw,-avx512cd,-avx512dq,-avx512f,-avx512fp16,-avx512ifma,-avx512vbmi,-avx512vbmi2,-avx512vl,-avx512vnni,-avx512vp2intersect,-avx512vpopcntdq,-avxifma,-avxneconvert,-avxvnni,-avxvnniint16,-avxvnniint8,-bmi,-bmi2,-branch-hint,-branchfusion,-ccmp,-cf,-cldemote,-clflushopt,-clwb,-clzero,-cmpccxadd,-crc32,-cx16,-egpr,-enqcmd,-ermsb,-f16c,-false-deps-getmant,-false-deps-lzcnt-tzcnt,-false-deps-mulc,-false-deps-mullq,-false-deps-perm,-false-deps-popcnt,-false-deps-range,-fast-11bytenop,-fast-15bytenop,-fast-7bytenop,-fast-bextr,-fast-dpwssd,-fast-gather,-fast-hops,-fast-imm16,-fast-lzcnt,-fast-movbe,-fast-scalar-fsqrt,-fast-scalar-shift-masks,-fast-shld-rotate,-fast-variable-crosslane-shuffle,-fast-variable-perlane-shuffle,-fast-vector-fsqrt,-fast-vector-shift-masks,-faster-shift-than-shuffle,-fma,-fma4,-fsgsbase,-fsrm,-gfni,-harden-sls-ijmp,-harden-sls-ret,-hreset,-idivl-to-divb,-inline-asm-use-gpr32,-invpcid,-kl,-lea-sp,-lea-uses-ag,-lvi-cfi,-lvi-load-hardening,-lwp,-lzcnt,-movbe,-movdir64b,-movdiri,-movrs,-mwaitx,-ndd,-nf,-no-bypass-delay,-no-bypass-delay-blend,-no-bypass-delay-mov,-no-bypass-delay-shuffle,-pad-short-functions,-pclmul,-pconfig,-pku,-popcnt,-ppx,-prefer-128-bit,-prefer-256-bit,-prefer-legacy-setcc,-prefer-mask-registers,-prefer-movmsk-over-vtest,-prefer-no-gather,-prefer-no-scatter,-prefetchi,-prfchw,-ptwrite,-push2pop2,-raoint,-rdpid,-rdpru,-rdrnd,-rdseed,-retpoline,-retpoline-external-thunk,-retpoline-indirect-branches,-retpoline-indirect-calls,-rtm,-sahf,-sbb-dep-breaking,-serialize,-seses,-sgx,-sha,-sha512,-shstk,-slow-lea,-slow-pmaddwd,-slow-pmulld,-slow-pmullq,-slow-shld,-slow-two-mem-ops,-slow-unaligned-mem-16,-slow-unaligned-mem-32,-sm3,-sm4,-soft-float,-sse3,-sse4.1,-sse4.2,-sse4a,-sse-unaligned-mem,-ssse3,-tagged-globals,-tbm,-tsxldtrk,-tuning-fast-imm-vector-shift,-uintr,-use-glm-div-sqrt-costs,-use-slm-arith-costs,-usermsr,-vaes,-vpclmulqdq,-waitpkg,-wbnoinvd,-widekl,-xop,-xsave,-xsavec,-xsaveopt,-xsaves,-zu" }

!0 = !{!1}
!1 = distinct !{!1, !2, !"compiler_rt.memcpy.memcpyFast: argument 0"}
!2 = distinct !{!2, !"compiler_rt.memcpy.memcpyFast"}
!3 = !{!4}
!4 = distinct !{!4, !2, !"compiler_rt.memcpy.memcpyFast: argument 1"}
!5 = !{!1, !4}

@family_memcpy_fast = alias ptr (ptr, ptr, i64), ptr @compiler_rt.memcpy.memcpyFast

define private ptr @compiler_rt.memcpy.memcpyFast(ptr noalias returned writeonly align 1 captures(ret: address, provenance) %0, ptr noalias readonly align 1 %1, i64 %2) unnamed_addr #14 align 1 {
  %4 = icmp ult i64 %2, 16
  br i1 %4, label %5, label %34

5:                                                ; preds = %3
  %6 = icmp samesign ult i64 %2, 4
  br i1 %6, label %7, label %9

7:                                                ; preds = %5
  %8 = icmp eq i64 %2, 0
  br i1 %8, label %common.ret, label %24

9:                                                ; preds = %5
  %10 = lshr i64 %2, 1
  %11 = and i64 %10, 4
  %12 = add nsw i64 %2, -4
  %13 = sub nuw nsw i64 %12, %11
  %14 = load i32, ptr %1, align 1
  store i32 %14, ptr %0, align 1
  %15 = getelementptr inbounds nuw [1 x i8], ptr %0, i64 %11
  %16 = getelementptr inbounds nuw [1 x i8], ptr %1, i64 %11
  %17 = load i32, ptr %16, align 1
  store i32 %17, ptr %15, align 1
  %18 = getelementptr inbounds nuw [1 x i8], ptr %0, i64 %13
  %19 = getelementptr inbounds nuw [1 x i8], ptr %1, i64 %13
  %20 = load i32, ptr %19, align 1
  store i32 %20, ptr %18, align 1
  %21 = getelementptr inbounds nuw [1 x i8], ptr %0, i64 %12
  %22 = getelementptr inbounds nuw [1 x i8], ptr %1, i64 %12
  %23 = load i32, ptr %22, align 1
  store i32 %23, ptr %21, align 1
  br label %common.ret

24:                                               ; preds = %7
  %25 = load i8, ptr %1, align 1
  store i8 %25, ptr %0, align 1
  %26 = lshr i64 %2, 1
  %27 = getelementptr inbounds nuw [1 x i8], ptr %0, i64 %26
  %28 = getelementptr inbounds nuw [1 x i8], ptr %1, i64 %26
  %29 = load i8, ptr %28, align 1
  store i8 %29, ptr %27, align 1
  %30 = add nsw i64 %2, -1
  %31 = getelementptr inbounds nuw [1 x i8], ptr %0, i64 %30
  %32 = getelementptr inbounds nuw [1 x i8], ptr %1, i64 %30
  %33 = load i8, ptr %32, align 1
  store i8 %33, ptr %31, align 1
  br label %common.ret

34:                                               ; preds = %3
  %35 = icmp ult i64 %2, 64
  br i1 %35, label %.critedge2, label %._crit_edge

.critedge2:                                       ; preds = %34
  %36 = lshr i64 %2, 1
  %37 = and i64 %36, 16
  %38 = add nsw i64 %2, -16
  %39 = sub nuw nsw i64 %38, %37
  %40 = load <16 x i8>, ptr %1, align 1
  store <16 x i8> %40, ptr %0, align 1
  %41 = getelementptr inbounds nuw [1 x i8], ptr %0, i64 %37
  %42 = getelementptr inbounds nuw [1 x i8], ptr %1, i64 %37
  %43 = load <16 x i8>, ptr %42, align 1
  store <16 x i8> %43, ptr %41, align 1
  %44 = getelementptr inbounds nuw [1 x i8], ptr %0, i64 %39
  %45 = getelementptr inbounds nuw [1 x i8], ptr %1, i64 %39
  %46 = load <16 x i8>, ptr %45, align 1
  store <16 x i8> %46, ptr %44, align 1
  %47 = getelementptr inbounds nuw [1 x i8], ptr %0, i64 %38
  %48 = getelementptr inbounds nuw [1 x i8], ptr %1, i64 %38
  %49 = load <16 x i8>, ptr %48, align 1
  store <16 x i8> %49, ptr %47, align 1
  br label %common.ret

common.ret:                                       ; preds = %7, %9, %24, %.critedge2, %._crit_edge
  ret ptr %0

._crit_edge:                                      ; preds = %34
  %50 = load <16 x i8>, ptr %1, align 1
  store <16 x i8> %50, ptr %0, align 1
  %51 = ptrtoint ptr %1 to i64
  %52 = and i64 %51, 15
  %53 = sub nuw nsw i64 16, %52
  %54 = sub nuw i64 %2, %53
  %55 = and i64 %54, -16
  %56 = getelementptr [1 x i8], ptr %1, i64 %53
  %57 = getelementptr [1 x i8], ptr %0, i64 %53
  tail call void @llvm.memcpy.p0.p0.i64(ptr align 1 %57, ptr align 16 %56, i64 %55, i1 false)
  %58 = add i64 %2, -16
  %59 = getelementptr inbounds [1 x i8], ptr %0, i64 %58
  %60 = getelementptr inbounds [1 x i8], ptr %1, i64 %58
  %61 = load <16 x i8>, ptr %60, align 1
  store <16 x i8> %61, ptr %59, align 1
  br label %common.ret
}

attributes #14 = { mustprogress nofree norecurse nosync nounwind willreturn memory(argmem: readwrite) uwtable "frame-pointer"="all" "target-cpu"="x86-64" "target-features"="+64bit,+cmov,+cx8,+fxsr,+idivq-to-divl,+macrofusion,+mmx,+nopl,+slow-3ops-lea,+slow-incdec,+sse,+sse2,+vzeroupper,+x87,-16bit-mode,-32bit-mode,-adx,-aes,-allow-light-256-bit,-amx-avx512,-amx-bf16,-amx-complex,-amx-fp16,-amx-fp8,-amx-int8,-amx-movrs,-amx-tf32,-amx-tile,-avx,-avx10.1,-avx10.2,-avx2,-avx512bf16,-avx512bitalg,-avx512bw,-avx512cd,-avx512dq,-avx512f,-avx512fp16,-avx512ifma,-avx512vbmi,-avx512vbmi2,-avx512vl,-avx512vnni,-avx512vp2intersect,-avx512vpopcntdq,-avxifma,-avxneconvert,-avxvnni,-avxvnniint16,-avxvnniint8,-bmi,-bmi2,-branch-hint,-branchfusion,-ccmp,-cf,-cldemote,-clflushopt,-clwb,-clzero,-cmpccxadd,-crc32,-cx16,-egpr,-enqcmd,-ermsb,-f16c,-false-deps-getmant,-false-deps-lzcnt-tzcnt,-false-deps-mulc,-false-deps-mullq,-false-deps-perm,-false-deps-popcnt,-false-deps-range,-fast-11bytenop,-fast-15bytenop,-fast-7bytenop,-fast-bextr,-fast-dpwssd,-fast-gather,-fast-hops,-fast-imm16,-fast-lzcnt,-fast-movbe,-fast-scalar-fsqrt,-fast-scalar-shift-masks,-fast-shld-rotate,-fast-variable-crosslane-shuffle,-fast-variable-perlane-shuffle,-fast-vector-fsqrt,-fast-vector-shift-masks,-faster-shift-than-shuffle,-fma,-fma4,-fsgsbase,-fsrm,-gfni,-harden-sls-ijmp,-harden-sls-ret,-hreset,-idivl-to-divb,-inline-asm-use-gpr32,-invpcid,-kl,-lea-sp,-lea-uses-ag,-lvi-cfi,-lvi-load-hardening,-lwp,-lzcnt,-movbe,-movdir64b,-movdiri,-movrs,-mwaitx,-ndd,-nf,-no-bypass-delay,-no-bypass-delay-blend,-no-bypass-delay-mov,-no-bypass-delay-shuffle,-pad-short-functions,-pclmul,-pconfig,-pku,-popcnt,-ppx,-prefer-128-bit,-prefer-256-bit,-prefer-legacy-setcc,-prefer-mask-registers,-prefer-movmsk-over-vtest,-prefer-no-gather,-prefer-no-scatter,-prefetchi,-prfchw,-ptwrite,-push2pop2,-raoint,-rdpid,-rdpru,-rdrnd,-rdseed,-retpoline,-retpoline-external-thunk,-retpoline-indirect-branches,-retpoline-indirect-calls,-rtm,-sahf,-sbb-dep-breaking,-serialize,-seses,-sgx,-sha,-sha512,-shstk,-slow-lea,-slow-pmaddwd,-slow-pmulld,-slow-pmullq,-slow-shld,-slow-two-mem-ops,-slow-unaligned-mem-16,-slow-unaligned-mem-32,-sm3,-sm4,-soft-float,-sse3,-sse4.1,-sse4.2,-sse4a,-sse-unaligned-mem,-ssse3,-tagged-globals,-tbm,-tsxldtrk,-tuning-fast-imm-vector-shift,-uintr,-use-glm-div-sqrt-costs,-use-slm-arith-costs,-usermsr,-vaes,-vpclmulqdq,-waitpkg,-wbnoinvd,-widekl,-xop,-xsave,-xsavec,-xsaveopt,-xsaves,-zu" }
