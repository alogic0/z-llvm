# Scalar FP Conversion, Multiplication, And Tanf Frontier

schema_version: 1
directive: `INBOX-21`
target: `x86_64-linux-gnu`
validation_tier: 2
result: pass

The composed selector now admits scalar `fpext float -> double`, `fptrunc
double -> float`, and `fmul` for float and double by operation and type only.
It reuses the existing scalar SSE instruction families through register-
parametric `cvtss2sd`, `cvtsd2ss`, `mulss`, and `mulsd` forms. Register
selection uses the generic selector's authoritative allocatable XMM set;
focused selector tests cover named, spilled, constant, identical, and
destination-occupying operands without fixed-XMM0 clobbers. Vector forms and
wider floating types remain fail-closed.

Executable selector tests compare exact result bits for 9 widening cases, 11
narrowing cases, 9 float multiplication cases, and 9 double multiplication
cases. The matrices cover signed zeros, finite signs, subnormals, infinities,
representative NaNs, overflow and underflow, exact widening, and the values
immediately below, at, and above a narrowing rounding boundary. The focused
ELF object contains four five-byte functions and no relocations:

```text
widen:      cvtss2sd %xmm0,%xmm0; ret
narrow:     cvtsd2ss %xmm0,%xmm0; ret
mul_float:  mulss %xmm1,%xmm0; ret
mul_double: mulsd %xmm1,%xmm0; ret
```

The real `compiler_rt.tan.tanf` row consumes the new widening and multiply
forms and advances to its first vector instruction, exactly
`UnsupportedCodegenControlFlow / unsupported_instruction / insertelement`.
No vector lowering or tangent polynomial recognition was added. Fresh
report-all moves from 189 emitting / 254 failing to 190 emitting / 253
failing. The additional emitting row is `compiler_rt.fma.fmaf`; this is
recorded as collateral emission only and has no separate semantic acceptance
claim.

```text
summary zllvm-codegen-report-all target=x86_64-unknown-linux-gnu selected_functions=443 emitted_functions=190 failed_functions=253 first_failing_function=compiler_rt.trunc.truncl first_failing_diagnostic=UnsupportedLongDoubleAbi first_failing_selector_tag=unsupported_type first_failing_selector_detail=unsupported-return-type local_fail=1
focused tests: unit=877/877 executable_scalar_fp_cases=38/38
focused object: ELF64 functions=4 function_size=5 relocations=0
tier2: steps=21/21 structural=7/7 object_inspection=pass selected_modes=pass executable_canaries=pass
```

Logs: `tmp/inbox21_tanf_final_report.log`,
`tmp/inbox21_scalar_fp_acceptance_emit.log`,
`tmp/inbox21_scalar_fp_acceptance_readelf.log`,
`tmp/inbox21_scalar_fp_acceptance_objdump.log`, and
`tmp/inbox21_tier2.log`.
