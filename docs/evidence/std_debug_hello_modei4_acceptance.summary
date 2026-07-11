# `__modei4` Composed Acceptance Evidence

schema_version: 1
z_llvm_base_commit: `2bcd0b70`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
target: `x86_64-linux-gnu`
result: `pass`

The composed selector now lowers `icmp sgt i32 value, -1` through a sign-bit
mask followed by the corrected `sete` operation. This advances `__modei5` and
generically closes sibling `compiler_rt.divmodei4.__modei4`. The exact sibling
body emits as an 8,659-byte function, patched stage4 Zig links it with
`-fno-lld`, and the linked harness exits zero.

```text
summary zllvm-codegen-report-all target=x86_64-unknown-linux-gnu selected_functions=443 emitted_functions=134 failed_functions=309 first_failing_function=compiler_rt.divmodei4.__modei5 first_failing_diagnostic=UnsupportedCodegenControlFlow first_failing_selector_tag=no_emitter first_failing_selector_detail=composed-block-select-type local_fail=1
focused object emission: status=0 symbol=compiler_rt.divmodei4.__modei4 size=8659
native link: status=0 linker=zig build-exe -fno-lld
linked executable: status=0
pressure: max_live_values=26 max_spill_slots_needed=20 max_spill_slots_over_envelope=0
```

Logs: `tmp/modei5_sgt_i32_retry.log`, `tmp/modei4_acceptance_emit.log`,
`tmp/modei4_acceptance_pressure.log`, and `tmp/modei4_native_link.log`.
Pressure data: `docs/evidence/std_debug_hello_modei4_acceptance_pressure.tsv`.
