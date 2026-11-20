# `__mulodi4` Composed Acceptance Evidence

schema_version: 1
z_llvm_base_commit: `30d9e5d5`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
target: `x86_64-linux-gnu`
result: `pass`

The composed selector lowers `llvm.smul.with.overflow.i64` through the fixed
RDX:RAX signed full-product operation, stores both tuple components in frame
slots immediately, and determines overflow by comparing the high product with
the sign extension of the low product. Immediate component spills are required:
the exact-row harness caught the initial stale-EAX implementation when later
guard comparisons overwrote the unextracted overflow result.

The exact `compiler_rt.mulo.__mulodi4` body emits as a 157-byte function,
patched stage4 Zig links it with `-fno-lld`, and the linked harness exits zero
after checking positive and negative non-overflow plus positive and negative
overflow products and out-parameter flags.

```text
summary zllvm-codegen-report-all target=x86_64-unknown-linux-gnu selected_functions=443 emitted_functions=138 failed_functions=305 first_failing_function=compiler_rt.trunc.__trunch first_failing_diagnostic=UnsupportedCodegenControlFlow first_failing_selector_tag=unsupported_type first_failing_selector_detail=unsupported-return-type local_fail=1
focused object emission: status=0 symbol=compiler_rt.mulo.__mulodi4 size=157
native link: status=0 linker=zig build-exe -fno-lld
linked executable: status=0
pressure: max_live_values=3 max_spill_slots_needed=0 max_spill_slots_over_envelope=0
```

Logs: `tmp/mulodi4_acceptance_emit.log` and
`tmp/std_debug_hello_mulodi4_acceptance_report.log`.
Pressure data: `docs/evidence/std_debug_hello_mulodi4_acceptance_pressure.tsv`.
