# i128 Shift Acceptance Evidence

schema_version: 1
z_llvm_base_commit: `8d896719`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
target: `x86_64-linux-gnu`
result: `pass`

Parallel phi-edge moves now stabilize every named incoming source before any
destination copy. This prevents one copy from clobbering a later RAX-backed
incoming value and closes `__lshrti3`, `__ashrti3`, and `__ashlti3`.

```text
summary zllvm-codegen-report-all target=x86_64-unknown-linux-gnu selected_functions=443 emitted_functions=163 failed_functions=280 first_failing_function=compiler_rt.trunc.__trunch first_failing_diagnostic=UnsupportedCodegenControlFlow first_failing_selector_tag=unsupported_type first_failing_selector_detail=unsupported-return-type local_fail=1
focused object: symbols=3 sizes=529,529,523 relocations=0
native executable: status=0 cases=18/18 counts=0,1,63,64,65,127
__lshrti3 pressure: max_live_values=5 max_spill_slots_needed=0 max_spill_slots_over_envelope=0
__ashrti3 pressure: max_live_values=5 max_spill_slots_needed=0 max_spill_slots_over_envelope=0
__ashlti3 pressure: max_live_values=6 max_spill_slots_needed=0 max_spill_slots_over_envelope=0
```

Logs: `tmp/std_debug_hello_i128_shift_acceptance.log` and
`tmp/i128_shift_acceptance_emit.log`. Pressure evidence:
`docs/evidence/std_debug_hello_lshrti3_acceptance_pressure.tsv`,
`docs/evidence/std_debug_hello_ashrti3_acceptance_pressure.tsv`, and
`docs/evidence/std_debug_hello_ashlti3_acceptance_pressure.tsv`.
