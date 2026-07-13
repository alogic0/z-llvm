# Scalar FP Compare Predicate Acceptance

schema_version: 1
directive: `INBOX-23 pre-authorized successor`
target: `x86_64-linux-gnu`
validation_tier: 2
result: pass

Baseline commit `fd5b5c8e` used the accepted report
`tmp/inbox23_scalar_fp_final_report.log` (443 selected / 190 emitting / 253
failing), captured compiler_rt IR md5
`b0eda7a6427c3084fdf096a68696f19c`, and the stage4 pin
`bdee02bc0c7f227c0f11bc9a449df673fe803540` recorded in the tracker.

The composed selector now admits all 16 LLVM scalar `fcmp` predicates for
float and double by predicate and operand type only. It materializes operands
through the single width-tagged XMM value map and reuses parametric `ucomiss`
and `ucomisd`. Result materialization derives ordered and unordered semantics
from ZF/PF/CF. Predicates that need two conditions use AL and AH before
zero-extension, avoiding an implicit GPR source clobber. Constant `false` and
`true` do not evaluate operands. Half, fp80, fp128, vector, and aggregate forms
remain fail-closed.

Executable coverage evaluates every predicate for float and double across six
relation classes: less, signed-zero equality, greater, left-NaN unordered,
right-NaN unordered, and ordered infinities. That is 96 outcomes per width and
192 total, including predicate-complete NaN behavior for ordered, unordered,
equality, inequality, and range comparisons.

Focused object inspection samples ordered equality, unordered greater-or-
equal, unordered detection, and ordered detection. It contains four functions
with no relocations:

```text
oeq_float:  ucomiss; sete; setnp; and; movzbl; and $1; ret  (20 bytes)
uge_double: ucomisd; setae; setp; or; movzbl; and $1; ret   (21 bytes)
uno_float:  ucomiss; setp; movzbl; and $1; ret              (15 bytes)
ord_double: ucomisd; setnp; movzbl; and $1; ret             (16 bytes)
```

Fresh report-all advances to 443 selected / 192 emitting / 251 failing.
`compiler_rt.round.__roundh` and `compiler_rt.round.roundf` are collateral
emissions and have no separate rounding-semantic acceptance claim. Nineteen
other diagnostics advance past scalar `fcmp`: float/double rows expose later
`sitofp`, phi, select, integer compare/binary, or GEP frontiers; three
half-precision rows are correctly reclassified to the explicit unsupported
`fcmp` type boundary. No new failure or regression appears.

```text
summary zllvm-codegen-report-all target=x86_64-unknown-linux-gnu selected_functions=443 emitted_functions=192 failed_functions=251 first_failing_function=compiler_rt.trunc.truncl first_failing_diagnostic=UnsupportedLongDoubleAbi first_failing_selector_tag=unsupported_type first_failing_selector_detail=unsupported-return-type local_fail=1
focused tests: unit=884/884 executable_scalar_fcmp_outcomes=192/192
focused object: ELF64 functions=4 sizes=20,21,15,16 relocations=0
tier2: steps=21/21 structural=7/7 object_inspection=pass selected_modes=pass executable_canaries=pass
```

Logs: `tmp/scalar_fcmp_unit.log`, `tmp/scalar_fcmp_acceptance_emit.log`,
`tmp/scalar_fcmp_acceptance_readelf.log`,
`tmp/scalar_fcmp_acceptance_objdump.log`,
`tmp/scalar_fcmp_final_report.log`, and `tmp/scalar_fcmp_tier2.log`.
