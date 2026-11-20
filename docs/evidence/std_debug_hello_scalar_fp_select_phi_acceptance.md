# Scalar FP Select And Phi Acceptance

schema_version: 1
directive: `INBOX-26`
target: `x86_64-linux-gnu`
validation_tier: 3
result: pass

The accepted baseline is commits `c7e01c3a` and `54119042`, report state
443 selected / 193 emitting / 250 failing, captured compiler_rt IR md5
`b0eda7a6427c3084fdf096a68696f19c`, and stage4 pin
`bdee02bc0c7f227c0f11bc9a449df673fe803540`.

The composed selector now lowers scalar float/double `select` through
width-tagged XMM locations. A destination register outside both named source
registers keeps the branch arms source-safe, and the existing FP
materialization path preserves the selected bit pattern rather than
canonicalizing it. Half and vector selects remain outside this capability.

Float/double phi incoming values now admit FP constants. Named FP edge
sources are snapshotted before destination writes, closing a parallel-copy
hazard where a spilled destination could overwrite another phi's source.
Snapshot registers exclude all XMM source and destination registers; edges
that exceed the bounded non-conflicting XMM envelope fail closed. Existing
scalar FP spill/reload and phi destination planning remain authoritative.

Executable selector coverage passes true and false selects at both widths
with signed zeros and NaN payloads. Loop-carried f32 phis execute a two-value
swap for one and two backedges, proving parallel-copy behavior, while an f64
loop proves an immediate negative-zero incoming edge. Vector select and phi
forms remain rejected.

Fresh report-all advances to 443 selected / 199 emitting / 244 failing.
`compiler_rt.tan.tanf` fully emits. `sinf` and `cosf` clear their scalar FP
select/phi frontiers and stop at the existing unsupported `switch`
terminator; `sincosf` remains at the excluded external FP store. The newly
emitting `fmin`/`fmax` float/double rows and `__floatunsidf` are collateral
typed-form emissions without separate semantic claims.

The acceptance object is the captured `compiler_rt.tan.tanf` body with only
debug records removed and linkage made externally callable. It contains one
`R_X86_64_PLT32 compiler_rt.rem_pio2f.rem_pio2f` relocation and native-links
with `zig build-exe -fno-lld`. Eight precomputed exact-result cases pass:
positive/negative zero, positive/negative minimum subnormal, and four finite
polynomial/range branches. The controlled reducer records zero calls, so no
host libm or runtime expected-value oracle participates.

```text
summary zllvm-codegen-report-all target=x86_64-unknown-linux-gnu selected_functions=443 emitted_functions=199 failed_functions=244 first_failing_function=compiler_rt.trunc.truncl first_failing_diagnostic=UnsupportedLongDoubleAbi first_failing_selector_tag=unsupported_type first_failing_selector_detail=unsupported-return-type local_fail=1
focused tests: unit=900/900 scalar_fp_select=4/4 scalar_fp_phi=5/5 vector_fail_closed=2/2
native tanf canary: status=0 cases=8/8 reducer_calls=0 relocation=R_X86_64_PLT32:compiler_rt.rem_pio2f.rem_pio2f native_linker=zig-build-exe-fno-lld
tier2: pass; structural/selected-zllvm=pass selected_zllvm_executable=146/146
tier3: pass; distribution-all subgates=17 local_fail=0
```

Logs: `tmp/inbox26_tier2.log` (sha256
`cad1137bef95e42b3c4b56a09d60275fabd76cf8e324fa02fccd95ad72d7ae04`),
`tmp/inbox26_scalar_fp_cfg_report.log` (sha256
`7c522eaea598b8468c2d8fd2f7b7b18a9afd80d82c080fb3dace2985e0260027`),
and `tmp/distribution_all_after_scalar_fp_select_phi.log` (sha256
`368f6b751cb77e3b78bb7c8c4bd0b7c0d3d85c15c0950eeb738e104d867ba204`).
Focused object: `tmp/inbox26_tanf_acceptance.o` (sha256
`0505b2edb7675b75721f09f0c45098ea3a2d5f31cbe190d37fecd5465aa220a5`).

`INBOX-26` is acknowledged by id. The pre-authorized successor is scalar FP
stores through proven pointer arguments for the captured `sincosf` shape; no
third cycle is authorized before review.
