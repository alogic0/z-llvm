# `__divei4` Composed Acceptance Evidence

schema_version: 1
z_llvm_base_commit: `fb2518eb`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
target: `x86_64-linux-gnu`
result: `pass`

The final i8 immediate-AND form remains narrowly admitted while all other i8
binary forms stay fail-closed. The focused compiler_rt retry moves beyond
`__divei4` to `compiler_rt.divmodei4.__modei5`. The exact captured body emits
as an 8,096-byte function, patched stage4 Zig links it with `-fno-lld`, and the
linked harness exits zero.

```text
summary zllvm-codegen-report-all target=x86_64-unknown-linux-gnu selected_functions=443 emitted_functions=133 failed_functions=310 first_failing_function=compiler_rt.divmodei4.__modei5 first_failing_diagnostic=UnsupportedCodegenControlFlow first_failing_selector_tag=no_emitter first_failing_selector_detail=composed-block-gep-source local_fail=1
focused object emission: status=0 symbol=compiler_rt.divmodei4.__divei4 size=8096
native link: status=0 linker=zig build-exe -fno-lld
linked executable: status=0
pressure: max_live_values=22 max_spill_slots_needed=16 max_spill_slots_over_envelope=0
```

Logs: `tmp/divei4_and_i8_retry.log`, `tmp/divei4_acceptance_emit.log`,
`tmp/divei4_acceptance_pressure.log`, and `tmp/divei4_native_link.log`.
Pressure data: `docs/evidence/std_debug_hello_divei4_acceptance_pressure.tsv`.
