# Half Zero Comparison Acceptance

schema_version: 1
directive: `INBOX-30`
target: `x86_64-linux-gnu`
validation_tier: 3
result: pass

The composed selector now admits exactly `fcmp oeq half` with one named value
and one raw half zero literal. Lowering moves the 16-bit payload from XMM to
EAX and evaluates `(bits & 0x7fff) == 0`; it makes no FP conversion call and
does not introduce a general FP16 comparison surface. Named-vs-named half
compares, nonzero literals, `uno`, and `olt` remain fail-closed, including the
captured `fminh` and `fmaxh` frontiers.

Permanent executable coverage exercises both operand orders and raw half
payloads for positive and negative zero, positive and negative minimum
subnormals, positive and negative normals, both infinities, and positive and
negative quiet and signaling NaNs. Structural coverage checks the exact
`movd`/mask/test/`sete` sequence and the fail-closed near misses.

Fresh report-all advances from 443 selected / 210 emitting / 233 failing to
443 selected / 213 emitting / 230 failing. The three directed closures are:

- `compiler_rt.log2.__log2h`;
- `compiler_rt.log10.__log10h`;
- `compiler_rt.log.__logh`.

The expected fourth row does not close: `compiler_rt.sqrt.__sqrth` advances
past `fcmp` to a distinct unsupported scalar half `fmul`. No half arithmetic
was admitted to force that expectation. There are no collateral emissions.

A parser/printer-derived native module exports all three exact dotted symbols.
Its six PLT32 relocations resolve locally to freshly emitted
`__extendhfsf2`/`__truncsfhf2` helpers. A freestanding native executable checks
39 precomputed raw-half results from the pinned compiler-rt sources: 13 inputs
for each wrapper across zeros, subnormals, normals, infinities, and quiet and
signaling NaN payloads. All calls pass.

The first native attempt exposed a stale framed FP phi destination and was not
accepted. Standalone repair `70c63cc4` gives framed scalar FP phis stable
allocator-owned spill destinations; its permanent branch-local executable
regression and audit are recorded in
`docs/evidence/framed_fp_phi_destination_repair.summary.md`. The row canary then
passed from freshly emitted objects.

```text
summary zllvm-codegen-report-all target=x86_64-linux selected_functions=443 emitted_functions=213 failed_functions=230 first_failing_function=compiler_rt.trunc.truncl local_fail=1
focused tests: unit=913/913 half_payload_cases=24/24 framed_phi_paths=2/2 native_half_log_calls=39/39
tier2: pass
tier3: pass; one recorded invocation, all 17 subgates green
```

Logs:

- `tmp/inbox30_half_zero_report.log`, sha256 `fca6e4b495a0762de806a0957cbeeb9fe3bc89578a8c6d8746722f05f1056991`;
- `tmp/inbox30_half_zero_tier2.log`, sha256 `8ce2f1d03a625776b5fd710fbcce58fa0f1fcf0502d977802ce131d6f163ef18`;
- `tmp/inbox30_half_log_reference.log`, sha256 `c7ac802421ab8169b681bdbb908d95ae62620be4e52a1c1dfed8cc61a9a13b1c`;
- `tmp/inbox30_half_log_rows_acceptance`, sha256 `373668037fae74d1a3a8a8fc5d4819517306719b8dc61494dc6b92a6241429b6`.

Tier-3 preface, staged identity, and final summaries are recorded in
`docs/evidence/distribution_all_after_inbox30_half_zero_fcmp.summary.md`.
