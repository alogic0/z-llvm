# Signed Add/Sub Overflow Family Acceptance

schema_version: 1
z_llvm_base_commit: `bc28feb8`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
target: `x86_64-linux-gnu`
result: `pass`

The composed selector now preserves accumulator-backed values whose allocation
intervals extend beyond a destructive binary instruction by relocating each
value to an available scratch register using its own virtual-register width.
The width source is the authoritative value binding; using the current binary
width initially regressed `__umodei4` and was rejected before commit.

This generic two-address correction closes signed add/sub overflow helpers
`__subvdi3`, `__subvsi3`, `__addvdi3`, and `__addvsi3`. Exact
`compiler_rt.subvdi3.__subvdi3` emits as a 50-byte function, native-links with
patched Zig and `-fno-lld`, and returns correct positive and negative results.

```text
summary zllvm-codegen-report-all target=x86_64-unknown-linux-gnu selected_functions=443 emitted_functions=143 failed_functions=300 first_failing_function=compiler_rt.trunc.__trunch first_failing_diagnostic=UnsupportedCodegenControlFlow first_failing_selector_tag=unsupported_type first_failing_selector_detail=unsupported-return-type local_fail=1
focused object emission: status=0 symbol=compiler_rt.subvdi3.__subvdi3 size=50
native link: status=0 linker=zig build-exe -fno-lld
linked executable: status=0
pressure: max_live_values=3 max_spill_slots_needed=0 max_spill_slots_over_envelope=0
```

Logs: `tmp/subvdi3_acceptance_emit.log` and
`tmp/std_debug_hello_subvdi3_multi_use.log`.
Pressure data: `docs/evidence/std_debug_hello_subvdi3_acceptance_pressure.tsv`.
