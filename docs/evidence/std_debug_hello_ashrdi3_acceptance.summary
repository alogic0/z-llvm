# Arithmetic-Right Shift Acceptance Evidence

schema_version: 1
z_llvm_base_commit: `25fa51db`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
result: `pass`

i32 immediate and CL-variable arithmetic-right shifts now use verified x86
`sarl` forms. Exact `__ashrdi3` native execution passes positive, negative,
minimum, maximum, and sign-extension cases; sibling `__ashrsi3` also closes.

```text
summary zllvm-codegen-report-all target=x86_64-unknown-linux-gnu selected_functions=443 emitted_functions=160 failed_functions=283 first_failing_function=compiler_rt.trunc.__trunch local_fail=1
focused object: symbol=compiler_rt.shift.__ashrdi3 size=349 relocations=0
native executable: status=0 cases=5/5
pressure: max_live_values=5 max_spill_slots_needed=0 max_spill_slots_over_envelope=0
```

Logs: `tmp/std_debug_hello_ashrdi3_i32_ashr.log` and
`tmp/ashrdi3_acceptance_emit.log`. Pressure:
`docs/evidence/std_debug_hello_ashrdi3_acceptance_pressure.tsv`.
