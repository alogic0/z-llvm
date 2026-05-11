; ModuleID = 'BitcodeBuffer'
source_filename = "integers"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i8:8:32-i16:16:32-i64:64-i128:128-n32:64-S128-Fn32"
target triple = "aarch64-unknown-linux5.10.0-gnu2.31.0"

@cmp_select = alias i32 (i32, i32), ptr @integers.cmp_select
@shift_mix = alias i32 (i32, i32), ptr @integers.shift_mix
@add_wrap = alias i32 (i32, i32), ptr @integers.add_wrap

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define private i32 @integers.cmp_select(i32 %0, i32 %1) unnamed_addr #0 align 4 {
  %. = tail call i32 @llvm.smin.i32(i32 %0, i32 %1)
  ret i32 %.
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define private i32 @integers.shift_mix(i32 %0, i32 %1) unnamed_addr #0 align 4 {
  %3 = and i32 %1, 31
  %4 = shl i32 %0, %3
  %5 = lshr i32 %0, %3
  %6 = xor i32 %4, %5
  ret i32 %6
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define private i32 @integers.add_wrap(i32 %0, i32 %1) unnamed_addr #0 align 4 {
  %3 = add i32 %1, %0
  ret i32 %3
}

; Function Attrs: nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.smin.i32(i32, i32) #1

attributes #0 = { mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable "frame-pointer"="all" "target-cpu"="generic" "target-features"="+enable-select-opt,+ete,+fp-armv8,+fuse-adrp-add,+fuse-aes,+neon,+trbe,+use-postra-scheduler,-a320,-addr-lsl-slow-14,-aes,-aggressive-fma,-aggressive-interleaving,-alternate-sextload-cvt-f32-pattern,-altnzcv,-alu-lsl-fast,-am,-amvs,-arith-bcc-fusion,-arith-cbz-fusion,-ascend-store-address,-avoid-ldapur,-balance-fp-ops,-bf16,-brbe,-bti,-btie,-call-saved-x10,-call-saved-x11,-call-saved-x12,-call-saved-x13,-call-saved-x14,-call-saved-x15,-call-saved-x18,-call-saved-x8,-call-saved-x9,-ccdp,-ccidx,-ccpp,-chk,-clrbhb,-cmh,-cmp-bcc-fusion,-cmpbr,-complxnum,-CONTEXTIDREL2,-cpa,-crc,-crypto,-cssc,-d128,-disable-fast-inc-vl,-disable-latency-sched-heuristic,-disable-ldp,-disable-maximize-scalable-bandwidth,-disable-stp,-disable-unpredicated-ld-st-lower,-dit,-dotprod,-ecv,-el2vmsa,-el3,-execute-only,-exynos-cheap-as-move,-f16f32dot,-f16f32mm,-f16mm,-f32mm,-f64mm,-f8f16mm,-f8f32mm,-faminmax,-fgt,-fix-cortex-a53-835769,-flagm,-fmv,-force-32bit-jump-tables,-fp16fml,-fp8,-fp8dot2,-fp8dot4,-fp8fma,-fpac,-fprcvt,-fptoint,-fujitsu-monaka,-fullfp16,-fuse-address,-fuse-addsub-2reg-const1,-fuse-arith-logic,-fuse-crypto-eor,-fuse-csel,-fuse-cset,-fuse-literals,-gcie,-gcs,-harden-sls-blr,-harden-sls-nocomdat,-harden-sls-retbr,-hbc,-hcx,-i8mm,-ite,-jsconv,-ldp-aligned-only,-lor,-ls64,-lscp,-lse,-lse128,-lse2,-lsfe,-lsui,-lut,-max-interleave-factor-4,-mec,-mops,-mops-go,-mpam,-mpamv2,-mte,-mtetc,-nmi,-no-bti-at-return-twice,-no-neg-immediates,-no-sve-fp-ld1r,-no-zcz-fpr64,-nv,-occmo,-olympus,-outline-atomics,-pan,-pan-rwv,-pauth,-pauth-lr,-pcdphint,-perfmon,-poe2,-pops,-predictable-select-expensive,-predres,-prfm-slc-target,-rand,-ras,-rasv2,-rcpc,-rcpc3,-rcpc-immo,-rdm,-reserve-lr-for-ra,-reserve-x1,-reserve-x10,-reserve-x11,-reserve-x12,-reserve-x13,-reserve-x14,-reserve-x15,-reserve-x18,-reserve-x2,-reserve-x20,-reserve-x21,-reserve-x22,-reserve-x23,-reserve-x24,-reserve-x25,-reserve-x26,-reserve-x27,-reserve-x28,-reserve-x3,-reserve-x4,-reserve-x5,-reserve-x6,-reserve-x7,-reserve-x9,-rme,-sb,-sel2,-sha2,-sha3,-slow-misaligned-128store,-slow-paired-128,-slow-strqro-store,-sm4,-sme,-sme2,-sme2p1,-sme2p2,-sme2p3,-sme-b16b16,-sme-f16f16,-sme-f64f64,-sme-f8f16,-sme-f8f32,-sme-fa64,-sme-i16i64,-sme-lutv2,-sme-mop4,-sme-tmop,-spe,-spe-eef,-specres2,-specrestrict,-ssbs,-ssve-aes,-ssve-bitperm,-ssve-fexpa,-ssve-fp8dot2,-ssve-fp8dot4,-ssve-fp8fma,-store-pair-suppress,-stp-aligned-only,-strict-align,-sve,-sve2,-sve2-aes,-sve2-bitperm,-sve2-sha3,-sve2-sm4,-sve2p1,-sve2p2,-sve2p3,-sve-aes,-sve-aes2,-sve-b16b16,-sve-b16mm,-sve-bfscale,-sve-bitperm,-sve-f16f32mm,-sve-sha3,-sve-sm4,-tagged-globals,-tev,-the,-tlb-rmi,-tlbid,-tlbiw,-tpidr-el1,-tpidr-el2,-tpidr-el3,-tpidrro-el0,-tracev8.4,-uaops,-use-experimental-zeroing-pseudos,-use-fixed-over-scalable-if-equal-cost,-use-reciprocal-square-root,-use-wzr-to-vec-move,-v8.1a,-v8.2a,-v8.3a,-v8.4a,-v8.5a,-v8.6a,-v8.7a,-v8.8a,-v8.9a,-v8a,-v8r,-v9.1a,-v9.2a,-v9.3a,-v9.4a,-v9.5a,-v9.6a,-v9.7a,-v9a,-vh,-wfxt,-xs,-zcm-fpr128,-zcm-fpr32,-zcm-fpr64,-zcm-gpr32,-zcm-gpr64,-zcz-fp-workaround,-zcz-fpr128,-zcz-gpr32,-zcz-gpr64" }
attributes #1 = { nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none) }

!llvm.module.flags = !{}
