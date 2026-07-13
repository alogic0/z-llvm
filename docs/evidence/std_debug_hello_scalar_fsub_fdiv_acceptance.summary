# Scalar FP Subtraction And Division Acceptance

schema_version: 1
directive: `INBOX-23`
target: `x86_64-linux-gnu`
validation_tier: 2
result: pass

Baseline commit `a372bd3f` used the accepted 443-function captured compiler_rt
IR (`b0eda7a6427c3084fdf096a68696f19c`) and the stage4 pin
`bdee02bc0c7f227c0f11bc9a449df673fe803540` recorded in the tracker.

The composed selector now admits scalar `fsub` and `fdiv` for float and
double by operation and type only. Register-parametric `subss`, `subsd`,
`divss`, and `divsd` forms preserve width-tagged XMM ownership through the
single value map. The destination always receives the left operand; destination
selection avoids a resident right-operand register, so non-commutative operand
order is preserved for named, constant, spilled, identical, and
destination-occupying operands. Half, fp80, fp128, and vector forms remain
fail-closed.

Executable selector tests compare exact result bits for 10 float-subtraction,
10 double-subtraction, 12 float-division, and 12 double-division cases. The 44
cases cover reversed finite operands, cancellation, signed-zero results,
subnormal production, overflow, underflow, division by positive and negative
zero, infinities, `0/0`, `inf/inf`, and payload-bearing NaN propagation. This
set exercises the operations' operand-order hazard as well as their distinct
IEEE exceptional-result and rounding boundaries.

The focused ELF object contains four five-byte functions and no relocations:

```text
sub_float:  subss %xmm1,%xmm0; ret
sub_double: subsd %xmm1,%xmm0; ret
div_float:  divss %xmm1,%xmm0; ret
div_double: divsd %xmm1,%xmm0; ret
```

Fresh report-all remains 443 selected / 190 emitting / 253 failing, with no
new failure, regression, or collateral emission. The directed rows advance as
follows:

- `compiler_rt.cos.cosf`, `compiler_rt.exp2.__exp2h`, and
  `compiler_rt.exp2.exp2f`: `fsub` -> `insertelement`;
- `compiler_rt.log.log`: `fsub` -> `insertelement`;
- `compiler_rt.log.__logh`, `compiler_rt.log.logf`, and the float, double,
  and half members of the `log2` and `log10` families: `fdiv` ->
  `insertelement`.

Seven collateral diagnostics advance without semantic or emission claims:
the three round rows expose `fcmp`, `__powidf2` and `__powisf2` expose integer
`sdiv`, and `__subdf3`/`__subsf3` expose a later scalar select form. The
half-only `compiler_rt.powiXf2.__powihf2` and `compiler_rt.subhf3.__subhf3`
rows remain at `fdiv` and `fsub`, respectively, as required by type-driven
admission.

```text
summary zllvm-codegen-report-all target=x86_64-unknown-linux-gnu selected_functions=443 emitted_functions=190 failed_functions=253 first_failing_function=compiler_rt.trunc.truncl first_failing_diagnostic=UnsupportedLongDoubleAbi first_failing_selector_tag=unsupported_type first_failing_selector_detail=unsupported-return-type local_fail=1
focused tests: unit=880/880 executable_scalar_fsub_fdiv_cases=44/44
focused object: ELF64 functions=4 function_size=5 relocations=0
tier2: steps=21/21 structural=7/7 object_inspection=pass selected_modes=pass executable_canaries=pass
```

Logs: `tmp/inbox23_unit.log`, `tmp/inbox23_scalar_fp_acceptance_emit.log`,
`tmp/inbox23_scalar_fp_acceptance_readelf.log`,
`tmp/inbox23_scalar_fp_acceptance_objdump.log`,
`tmp/inbox23_scalar_fp_final_report.log`, and `tmp/inbox23_tier2.log`.
