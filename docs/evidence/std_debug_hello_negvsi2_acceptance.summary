# Signed i32 Negation Acceptance

schema_version: 1
z_llvm_base_commit: `d1c7e18e`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
target: `x86_64-linux-gnu`
result: `pass`

The composed selector now lowers immediate-left subtraction for integer widths
through i32. Narrow results retain their width mask, while i32 uses the native
wrapping EAX result. This closes `compiler_rt.negv.__negvsi2` after its
minimum-value overflow guard.

The exact row emits as a 38-byte function, native-links with patched Zig and
`-fno-lld`, and returns correct results for both positive and negative inputs.

```text
summary zllvm-codegen-report-all target=x86_64-unknown-linux-gnu selected_functions=443 emitted_functions=144 failed_functions=299 first_failing_function=compiler_rt.trunc.__trunch first_failing_diagnostic=UnsupportedCodegenControlFlow first_failing_selector_tag=unsupported_type first_failing_selector_detail=unsupported-return-type local_fail=1
focused object emission: status=0 symbol=compiler_rt.negv.__negvsi2 size=38
native link: status=0 linker=zig build-exe -fno-lld
linked executable: status=0
pressure: max_live_values=2 max_spill_slots_needed=0 max_spill_slots_over_envelope=0
```

Logs: `tmp/negvsi2_acceptance_emit.log` and
`tmp/std_debug_hello_negvsi2_sub.log`.
Pressure data: `docs/evidence/std_debug_hello_negvsi2_acceptance_pressure.tsv`.
