# Shift Phi-Edge Acceptance Evidence

schema_version: 1
z_llvm_base_commit: `cb42edcd`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
target: `x86_64-linux-gnu`
result: `pass`

Parallel phi-edge copies now preserve accumulator values whose interval ends at
the current terminator position. This closes `__ashlsi3`, `__lshrsi3`,
`__lshrdi3`, and `__ashldi3`; report-all advances from 154/289 to 158/285.
The exact relocation-free `__ashlsi3` object passes five native shift cases.

```text
summary zllvm-codegen-report-all target=x86_64-unknown-linux-gnu selected_functions=443 emitted_functions=158 failed_functions=285 first_failing_function=compiler_rt.trunc.__trunch first_failing_diagnostic=UnsupportedCodegenControlFlow first_failing_selector_tag=unsupported_type first_failing_selector_detail=unsupported-return-type local_fail=1
focused object: symbol=compiler_rt.shift.__ashlsi3 size=339 relocations=0
native executable: status=0 cases=5/5
pressure: max_live_values=5 max_spill_slots_needed=0 max_spill_slots_over_envelope=0
```

Logs: `tmp/std_debug_hello_ashlsi3_phi_edge_preserve.log` and
`tmp/ashlsi3_acceptance_emit.log`. Pressure:
`docs/evidence/std_debug_hello_ashlsi3_acceptance_pressure.tsv`.
