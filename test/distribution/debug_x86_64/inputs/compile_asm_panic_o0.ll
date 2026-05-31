; ModuleID = 'BitcodeBuffer'
source_filename = "main"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux5.10.0-gnu2.31.0"

%Target.Cpu.Feature.Set = type { [6 x i64] }
%Target.Cpu = type { ptr, %Target.Cpu.Feature.Set, i6, [7 x i8] }
%Target.Os = type { %Target.Os.VersionRange, i6, [7 x i8] }
%Target.Os.VersionRange = type { %Target.Os.LinuxVersionRange, i3, [7 x i8] }
%Target.Os.LinuxVersionRange = type { %SemanticVersion.Range, %SemanticVersion, i32, [4 x i8] }
%SemanticVersion.Range = type { %SemanticVersion, %SemanticVersion }
%SemanticVersion = type { i64, i64, i64, { ptr, i64 }, { ptr, i64 } }
%Target = type { %Target.Cpu, %Target.Os, i5, i4, %Target.DynamicLinker, [6 x i8] }
%Target.DynamicLinker = type { [255 x i8], i8 }
%lang.CallingConvention.CommonOptions = type { { i64, i8, [7 x i8] } }
%Target.Cpu.Model = type { { ptr, i64 }, { ptr, i64 }, %Target.Cpu.Feature.Set }

@builtin.output_mode = private unnamed_addr constant i2 -2, align 1
@Target.Cpu.Feature.Set.empty = private unnamed_addr constant %Target.Cpu.Feature.Set zeroinitializer, align 8
@builtin.cpu = private unnamed_addr constant %Target.Cpu { ptr @Target.x86.cpu.x86_64, %Target.Cpu.Feature.Set { [6 x i64] [i64 153122387330596880, i64 72083991041146880, i64 4611738796596133888, i64 8, i64 0, i64 0] }, i6 -9, [7 x i8] undef }, align 8
@builtin.os = private unnamed_addr constant %Target.Os { %Target.Os.VersionRange { %Target.Os.LinuxVersionRange { %SemanticVersion.Range { %SemanticVersion { i64 5, i64 10, i64 0, { ptr, i64 } zeroinitializer, { ptr, i64 } zeroinitializer }, %SemanticVersion { i64 6, i64 19, i64 0, { ptr, i64 } zeroinitializer, { ptr, i64 } zeroinitializer } }, %SemanticVersion { i64 2, i64 31, i64 0, { ptr, i64 } zeroinitializer, { ptr, i64 } zeroinitializer }, i32 29, [4 x i8] undef }, i3 3, [7 x i8] undef }, i6 9, [7 x i8] undef }, align 8
@builtin.abi = private unnamed_addr constant i5 1, align 1
@builtin.object_format = private unnamed_addr constant i4 2, align 1
@builtin.target = private unnamed_addr constant %Target { %Target.Cpu { ptr @Target.x86.cpu.x86_64, %Target.Cpu.Feature.Set { [6 x i64] [i64 153122387330596880, i64 72083991041146880, i64 4611738796596133888, i64 8, i64 0, i64 0] }, i6 -9, [7 x i8] undef }, %Target.Os { %Target.Os.VersionRange { %Target.Os.LinuxVersionRange { %SemanticVersion.Range { %SemanticVersion { i64 5, i64 10, i64 0, { ptr, i64 } zeroinitializer, { ptr, i64 } zeroinitializer }, %SemanticVersion { i64 6, i64 19, i64 0, { ptr, i64 } zeroinitializer, { ptr, i64 } zeroinitializer } }, %SemanticVersion { i64 2, i64 31, i64 0, { ptr, i64 } zeroinitializer, { ptr, i64 } zeroinitializer }, i32 29, [4 x i8] undef }, i3 3, [7 x i8] undef }, i6 9, [7 x i8] undef }, i5 1, i4 2, %Target.DynamicLinker { [255 x i8] [i8 47, i8 108, i8 105, i8 98, i8 54, i8 52, i8 47, i8 108, i8 100, i8 45, i8 108, i8 105, i8 110, i8 117, i8 120, i8 45, i8 120, i8 56, i8 54, i8 45, i8 54, i8 52, i8 46, i8 115, i8 111, i8 46, i8 50, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef, i8 undef], i8 27 }, [6 x i8] undef }, align 8
@lang.CallingConvention.c = private unnamed_addr constant { <{ %lang.CallingConvention.CommonOptions, [8 x i8] }>, i8, [7 x i8] } { <{ %lang.CallingConvention.CommonOptions, [8 x i8] }> <{ %lang.CallingConvention.CommonOptions { { i64, i8, [7 x i8] } { i64 undef, i8 0, [7 x i8] undef } }, [8 x i8] undef }>, i8 4, [7 x i8] undef }, align 8
@__anon_1101 = private unnamed_addr constant [25 x i8] c"reached unreachable code\00", align 1
@Target.x86.cpu.x86_64 = private unnamed_addr constant %Target.Cpu.Model { { ptr, i64 } { ptr @__anon_1109, i64 6 }, { ptr, i64 } { ptr @__anon_1112, i64 6 }, %Target.Cpu.Feature.Set { [6 x i64] [i64 153122387330596880, i64 72083991041146880, i64 4611721204410089472, i64 8, i64 0, i64 0] } }, align 8
@__anon_1109 = private unnamed_addr constant [7 x i8] c"x86_64\00", align 1
@__anon_1112 = private unnamed_addr constant [7 x i8] c"x86-64\00", align 1
@Target.DynamicLinker.none = private unnamed_addr constant %Target.DynamicLinker { [255 x i8] undef, i8 0 }, align 1

@main = alias void (i32, i32, i32), ptr @main.main

; Function Attrs: cold noreturn nounwind uwtable
define private void @main.main(i32 %0, i32 %1, i32 %2) unnamed_addr #0 align 1 {
  call fastcc void @"debug.FullPanic((function 'panic')).reachedUnreachable"()
  unreachable
}

; Function Attrs: cold noreturn nounwind uwtable
define private fastcc void @"debug.FullPanic((function 'panic')).reachedUnreachable"() unnamed_addr #0 align 1 {
  %1 = alloca { i64, i8, [7 x i8] }, align 8
  %2 = call ptr @llvm.returnaddress(i32 0)
  %3 = ptrtoint ptr %2 to i64
  store i64 %3, ptr %1, align 8
  %4 = getelementptr inbounds i8, ptr %1, i64 8
  store i8 1, ptr %4, align 1
  %5 = extractvalue { ptr, i64 } { ptr @__anon_1101, i64 24 }, 0
  %6 = extractvalue { ptr, i64 } { ptr @__anon_1101, i64 24 }, 1
  call fastcc void @lang.panic__struct_1031.panic(ptr nonnull readonly %5, i64 %6, ptr nonnull readonly align 8 %1)
  unreachable
}

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(none)
declare ptr @llvm.returnaddress(i32 immarg) #1

; Function Attrs: noreturn nounwind uwtable
define private fastcc void @lang.panic__struct_1031.panic(ptr nonnull readonly %0, i64 %1, ptr nonnull readonly align 8 %2) unnamed_addr #2 align 1 {
  %4 = insertvalue { ptr, i64 } poison, ptr %0, 0
  %5 = insertvalue { ptr, i64 } %4, i64 %1, 1
  %6 = extractvalue { ptr, i64 } %5, 0
  %7 = extractvalue { ptr, i64 } %5, 1
  call fastcc void @main.panic(ptr nonnull readonly %6, i64 %7, ptr align 8 null, ptr nonnull readonly align 8 %2)
  unreachable
}

; Function Attrs: noreturn nounwind uwtable
define private fastcc void @main.panic(ptr nonnull readonly %0, i64 %1, ptr align 8 %2, ptr nonnull readonly align 8 %3) unnamed_addr #2 align 1 {
  %5 = insertvalue { ptr, i64 } poison, ptr %0, 0
  %6 = insertvalue { ptr, i64 } %5, i64 %1, 1
  br label %7

7:                                                ; preds = %7, %4
  br label %7
}

attributes #0 = { cold noreturn nounwind uwtable "frame-pointer"="all" "probe-stack"="__zig_probe_stack" "target-cpu"="x86-64" "target-features"="+64bit,+cmov,+cx8,+fxsr,+idivq-to-divl,+macrofusion,+mmx,+nopl,+slow-3ops-lea,+slow-incdec,+sse,+sse2,+vzeroupper,+x87,-16bit-mode,-32bit-mode,-adx,-aes,-allow-light-256-bit,-amx-avx512,-amx-bf16,-amx-complex,-amx-fp16,-amx-fp8,-amx-int8,-amx-movrs,-amx-tf32,-amx-tile,-avx,-avx10.1,-avx10.2,-avx2,-avx512bf16,-avx512bitalg,-avx512bw,-avx512cd,-avx512dq,-avx512f,-avx512fp16,-avx512ifma,-avx512vbmi,-avx512vbmi2,-avx512vl,-avx512vnni,-avx512vp2intersect,-avx512vpopcntdq,-avxifma,-avxneconvert,-avxvnni,-avxvnniint16,-avxvnniint8,-bmi,-bmi2,-branch-hint,-branchfusion,-ccmp,-cf,-cldemote,-clflushopt,-clwb,-clzero,-cmpccxadd,-crc32,-cx16,-egpr,-enqcmd,-ermsb,-f16c,-false-deps-getmant,-false-deps-lzcnt-tzcnt,-false-deps-mulc,-false-deps-mullq,-false-deps-perm,-false-deps-popcnt,-false-deps-range,-fast-11bytenop,-fast-15bytenop,-fast-7bytenop,-fast-bextr,-fast-dpwssd,-fast-gather,-fast-hops,-fast-imm16,-fast-lzcnt,-fast-movbe,-fast-scalar-fsqrt,-fast-scalar-shift-masks,-fast-shld-rotate,-fast-variable-crosslane-shuffle,-fast-variable-perlane-shuffle,-fast-vector-fsqrt,-fast-vector-shift-masks,-faster-shift-than-shuffle,-fma,-fma4,-fsgsbase,-fsrm,-gfni,-harden-sls-ijmp,-harden-sls-ret,-hreset,-idivl-to-divb,-inline-asm-use-gpr32,-invpcid,-kl,-lea-sp,-lea-uses-ag,-lvi-cfi,-lvi-load-hardening,-lwp,-lzcnt,-movbe,-movdir64b,-movdiri,-movrs,-mwaitx,-ndd,-nf,-no-bypass-delay,-no-bypass-delay-blend,-no-bypass-delay-mov,-no-bypass-delay-shuffle,-pad-short-functions,-pclmul,-pconfig,-pku,-popcnt,-ppx,-prefer-128-bit,-prefer-256-bit,-prefer-legacy-setcc,-prefer-mask-registers,-prefer-movmsk-over-vtest,-prefer-no-gather,-prefer-no-scatter,-prefetchi,-prfchw,-ptwrite,-push2pop2,-raoint,-rdpid,-rdpru,-rdrnd,-rdseed,-retpoline,-retpoline-external-thunk,-retpoline-indirect-branches,-retpoline-indirect-calls,-rtm,-sahf,-sbb-dep-breaking,-serialize,-seses,-sgx,-sha,-sha512,-shstk,-slow-lea,-slow-pmaddwd,-slow-pmulld,-slow-pmullq,-slow-shld,-slow-two-mem-ops,-slow-unaligned-mem-16,-slow-unaligned-mem-32,-sm3,-sm4,-soft-float,-sse3,-sse4.1,-sse4.2,-sse4a,-sse-unaligned-mem,-ssse3,-tagged-globals,-tbm,-tsxldtrk,-tuning-fast-imm-vector-shift,-uintr,-use-glm-div-sqrt-costs,-use-slm-arith-costs,-usermsr,-vaes,-vpclmulqdq,-waitpkg,-wbnoinvd,-widekl,-xop,-xsave,-xsavec,-xsaveopt,-xsaves,-zu" }
attributes #1 = { nocallback nofree nosync nounwind willreturn memory(none) }
attributes #2 = { noreturn nounwind uwtable "frame-pointer"="all" "probe-stack"="__zig_probe_stack" "target-cpu"="x86-64" "target-features"="+64bit,+cmov,+cx8,+fxsr,+idivq-to-divl,+macrofusion,+mmx,+nopl,+slow-3ops-lea,+slow-incdec,+sse,+sse2,+vzeroupper,+x87,-16bit-mode,-32bit-mode,-adx,-aes,-allow-light-256-bit,-amx-avx512,-amx-bf16,-amx-complex,-amx-fp16,-amx-fp8,-amx-int8,-amx-movrs,-amx-tf32,-amx-tile,-avx,-avx10.1,-avx10.2,-avx2,-avx512bf16,-avx512bitalg,-avx512bw,-avx512cd,-avx512dq,-avx512f,-avx512fp16,-avx512ifma,-avx512vbmi,-avx512vbmi2,-avx512vl,-avx512vnni,-avx512vp2intersect,-avx512vpopcntdq,-avxifma,-avxneconvert,-avxvnni,-avxvnniint16,-avxvnniint8,-bmi,-bmi2,-branch-hint,-branchfusion,-ccmp,-cf,-cldemote,-clflushopt,-clwb,-clzero,-cmpccxadd,-crc32,-cx16,-egpr,-enqcmd,-ermsb,-f16c,-false-deps-getmant,-false-deps-lzcnt-tzcnt,-false-deps-mulc,-false-deps-mullq,-false-deps-perm,-false-deps-popcnt,-false-deps-range,-fast-11bytenop,-fast-15bytenop,-fast-7bytenop,-fast-bextr,-fast-dpwssd,-fast-gather,-fast-hops,-fast-imm16,-fast-lzcnt,-fast-movbe,-fast-scalar-fsqrt,-fast-scalar-shift-masks,-fast-shld-rotate,-fast-variable-crosslane-shuffle,-fast-variable-perlane-shuffle,-fast-vector-fsqrt,-fast-vector-shift-masks,-faster-shift-than-shuffle,-fma,-fma4,-fsgsbase,-fsrm,-gfni,-harden-sls-ijmp,-harden-sls-ret,-hreset,-idivl-to-divb,-inline-asm-use-gpr32,-invpcid,-kl,-lea-sp,-lea-uses-ag,-lvi-cfi,-lvi-load-hardening,-lwp,-lzcnt,-movbe,-movdir64b,-movdiri,-movrs,-mwaitx,-ndd,-nf,-no-bypass-delay,-no-bypass-delay-blend,-no-bypass-delay-mov,-no-bypass-delay-shuffle,-pad-short-functions,-pclmul,-pconfig,-pku,-popcnt,-ppx,-prefer-128-bit,-prefer-256-bit,-prefer-legacy-setcc,-prefer-mask-registers,-prefer-movmsk-over-vtest,-prefer-no-gather,-prefer-no-scatter,-prefetchi,-prfchw,-ptwrite,-push2pop2,-raoint,-rdpid,-rdpru,-rdrnd,-rdseed,-retpoline,-retpoline-external-thunk,-retpoline-indirect-branches,-retpoline-indirect-calls,-rtm,-sahf,-sbb-dep-breaking,-serialize,-seses,-sgx,-sha,-sha512,-shstk,-slow-lea,-slow-pmaddwd,-slow-pmulld,-slow-pmullq,-slow-shld,-slow-two-mem-ops,-slow-unaligned-mem-16,-slow-unaligned-mem-32,-sm3,-sm4,-soft-float,-sse3,-sse4.1,-sse4.2,-sse4a,-sse-unaligned-mem,-ssse3,-tagged-globals,-tbm,-tsxldtrk,-tuning-fast-imm-vector-shift,-uintr,-use-glm-div-sqrt-costs,-use-slm-arith-costs,-usermsr,-vaes,-vpclmulqdq,-waitpkg,-wbnoinvd,-widekl,-xop,-xsave,-xsavec,-xsaveopt,-xsaves,-zu" }

!llvm.module.flags = !{}
