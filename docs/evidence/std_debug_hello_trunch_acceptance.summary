# __trunch Type-Driven Acceptance

schema_version: 1
directive: `INBOX-18`
target: `x86_64-linux-gnu`
validation_tier: 2
result: pass

The composed selector closes `compiler_rt.trunc.__trunch` through typed scalar
FP operations. Baseline half extension and truncation use the in-module
`__extendhfsf2` and `__truncsfhf2` aliases; their emitted helper bodies contain
no recursive half conversion. No F16C or AVX512-FP16 instruction is used.

The focused object exports `__trunch`, `__extendhfsf2`, `__gnu_h2f_ieee`, and
`__truncsfhf2`; its only two relocations resolve to those local helper aliases.
Native linking uses `zig build-exe -fno-lld -fno-compiler-rt`. Executable
semantics pass 14 raw-half cases covering both zeros, finite normals, positive
and negative subnormals, both infinities, quiet and signaling NaN payloads,
and positive/negative truncation branches. The native probe exposed and drove
the repair of a general live-EAX overwrite in immediate integer operations.

```text
summary zllvm-codegen-report-all target=x86_64-unknown-linux-gnu selected_functions=443 emitted_functions=170 failed_functions=273 first_failing_function=compiler_rt.trunc.truncl first_failing_diagnostic=UnsupportedTailCallAbi first_failing_selector_tag=unsupported_type first_failing_selector_detail=unsupported-return-type local_fail=1
focused object: size=2488 symbols=7 text_functions=3 relocations=2
native executable: status=0 cases=14/14 linker=zig build-exe -fno-lld
tier2: unit=pass structural=pass releasefast_object=pass debug_object=pass debug_executable=pass releasesafe_object=pass integrated_executable=5/5
```

The next non-tail soft-float frontier is `compiler_rt.trunc.trunc` at typed
`fadd`. `truncq` and `__truncx` remain wider-format boundaries, and `truncl`
remains in the separate tail-call ABI family.

Logs: `tmp/inbox18_trunch_final_report.log`,
`tmp/inbox18_trunch_acceptance_emit.log`,
`tmp/inbox18_distribution_object.log`,
`tmp/inbox18_distribution_debug_object.log`,
`tmp/inbox18_distribution_debug_executable.log`,
`tmp/inbox18_distribution_releasesafe_object.log`, and
`tmp/inbox18_distribution_zig_integrated_exe.log`.
