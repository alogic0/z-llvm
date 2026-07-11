# `__muloti4` Composed Acceptance Evidence

schema_version: 1
z_llvm_base_commit: `53643df1`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
target: `x86_64-linux-gnu`
result: `pass`

The composed selector now lowers named `and i1` values and reserves its
standard spill frame when i128 comparisons may need to displace overlapping
ABI pairs. The exact `compiler_rt.mulo.__muloti4` body emits as a 560-byte
function, patched stage4 Zig links it with `-fno-lld`, and the linked harness
exits zero after checking positive and negative non-overflow plus positive and
negative overflow results and overflow flags.

```text
summary zllvm-codegen-report-all target=x86_64-unknown-linux-gnu selected_functions=443 emitted_functions=137 failed_functions=306 first_failing_function=compiler_rt.trunc.__trunch first_failing_diagnostic=UnsupportedCodegenControlFlow first_failing_selector_tag=unsupported_type first_failing_selector_detail=unsupported-return-type local_fail=1
focused object emission: status=0 symbol=compiler_rt.mulo.__muloti4 size=560
native link: status=0 linker=zig build-exe -fno-lld
linked executable: status=0
pressure: max_live_values=3 max_spill_slots_needed=0 max_spill_slots_over_envelope=0
```

Logs: `tmp/muloti4_and_i1_retry.log`,
`tmp/std_debug_hello_muloti4_acceptance_report.log`, and the temporary native
acceptance artifacts under `tmp/muloti4_acceptance*`.
Pressure data: `docs/evidence/std_debug_hello_muloti4_acceptance_pressure.tsv`.
