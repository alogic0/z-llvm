# `__modei5` And `__divei5` Composed Acceptance Evidence

schema_version: 1
z_llvm_base_commit: `7fb4ad4b`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
target: `x86_64-linux-gnu`
result: `pass`

The composed selector now classifies pointer selects as 64-bit location
selects while preserving the existing named-value and branch semantics. This
single typed form closes both five-argument signed extended-int rows. The exact
captured bodies emit, patched stage4 Zig links both objects together with
`-fno-lld`, and the linked harness exits zero.

```text
summary zllvm-codegen-report-all target=x86_64-unknown-linux-gnu selected_functions=443 emitted_functions=136 failed_functions=307 first_failing_function=compiler_rt.trunc.__trunch first_failing_diagnostic=UnsupportedCodegenControlFlow first_failing_selector_tag=unsupported_type first_failing_selector_detail=unsupported-return-type local_fail=1
focused object emission: status=0 symbol=compiler_rt.divmodei4.__modei5 size=8883
focused object emission: status=0 symbol=compiler_rt.divmodei4.__divei5 size=7615
native link: status=0 linker=zig build-exe -fno-lld
linked executable: status=0
__modei5 pressure: max_live_values=26 max_spill_slots_needed=20 max_spill_slots_over_envelope=0
__divei5 pressure: max_live_values=22 max_spill_slots_needed=16 max_spill_slots_over_envelope=0
```

Logs: `tmp/modei5_pointer_select_retry.log`, `tmp/modei5_acceptance_emit.log`,
`tmp/divei5_acceptance_emit.log`, and `tmp/modei5_divei5_native_link.log`.
Pressure data: `docs/evidence/std_debug_hello_modei5_acceptance_pressure.tsv`
and `docs/evidence/std_debug_hello_divei5_acceptance_pressure.tsv`.
