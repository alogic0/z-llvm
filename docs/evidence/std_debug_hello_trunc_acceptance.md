# Double Truncation Type-Driven Acceptance

schema_version: 1
directive: `INBOX-19`
target: `x86_64-linux-gnu`
validation_tier: 2
result: pass

The composed selector closes `compiler_rt.trunc.trunc` through width-driven
scalar FP lowering. Double/i64 bitcasts use explicit XMM/GPR moves, double
addition uses `addsd`, and the exact empty side-effect barrier accepts both
float and double operands. The row's variable i64 shift and immediate i64 XOR
forms are selected by operation and type; no symbol or block-name checks were
added.

The focused object exports one `trunc` function, has no relocations, and links
with `zig build-exe -fno-lld -fno-compiler-rt`. Native execution passes 24
raw-double cases: signed zeros, positive/negative finite values and subnormals,
both infinities, quiet and signaling NaN payloads, both return branches, the
masking branch, and adjacent representable values around positive and negative
integer boundaries. The native probe exposed and drove a general repair for
integer values kept live in EAX/RAX across predicate production.

```text
summary zllvm-codegen-report-all target=x86_64-unknown-linux-gnu selected_functions=443 emitted_functions=173 failed_functions=270 first_failing_function=compiler_rt.trunc.truncl first_failing_diagnostic=UnsupportedTailCallAbi first_failing_selector_tag=unsupported_type first_failing_selector_detail=unsupported-return-type local_fail=1
focused object: size=1024 symbols=1 text_functions=1 relocations=0
native executable: status=0 cases=24/24 linker=zig build-exe -fno-lld
tier2: unit=pass structural=pass releasefast_object=pass debug_object=pass debug_executable=pass releasesafe_object=pass integrated_executable=5/5
```

The operation-driven forms also make `compiler_rt.extendhfdf2.__extendhfdf2`
and `compiler_rt.extendsfdf2.__extendsfdf2` emit in report-all, moving the
soft-float bucket by three rows in total. These collateral rows are not claimed
as separately accepted semantic canaries. The next non-tail frontier is
`compiler_rt.tan.tanh` at `no_emitter` / `composed-block-call-form`.
`truncl` remains in the tail-call ABI family, while `truncq` and `__truncx`
remain wider-format boundaries and were not entered.

Logs: `tmp/inbox19_trunc_final_report.log`,
`tmp/inbox19_trunc_acceptance_emit.log`,
`tmp/inbox19_trunc_acceptance_readelf.log`, and
`tmp/inbox19_trunc_acceptance_objdump.log`.
