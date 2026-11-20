# `__udivmoddi4` Acceptance Evidence

schema_version: 1
z_llvm_base_commit: `770c7a22`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
target: `x86_64-linux-gnu`
result: `pass`

The exact 50-block body exposed path-dependent register state after selection
first reached object emission. CFG live-out facts now extend allocation
intervals, planned spill destinations remain authoritative for phis, and
framed branch boundaries spill live register values to stable frame homes.
When a phi first crosses such a boundary, that frame home becomes its canonical
destination for every later incoming edge. Checked `llvm.lifetime.start.p0`
and `llvm.lifetime.end.p0` calls lower as metadata-only no-ops.

The exact extracted object is call-free and relocation-free. Its native harness
checks ordinary division, a smaller dividend, zero, a full-width quotient, and
a null remainder pointer. All quotient and remainder results pass.

```text
summary zllvm-codegen-report-all target=x86_64-unknown-linux-gnu selected_functions=443 emitted_functions=154 failed_functions=289 first_failing_function=compiler_rt.trunc.__trunch first_failing_diagnostic=UnsupportedCodegenControlFlow first_failing_selector_tag=unsupported_type first_failing_selector_detail=unsupported-return-type local_fail=1
focused object emission: status=0 symbol=compiler_rt.int.__udivmoddi4 size=6235 relocations=0
native link: status=0 linker=zig build-exe -fno-lld
linked executable: status=0
pressure: max_live_values=17 max_spill_slots_needed=11 max_spill_slots_over_envelope=0
resolved row: compiler_rt.int.__udivmoddi4
```

Logs: `tmp/std_debug_hello_udivmoddi4_acceptance.log` and
`tmp/udivmoddi4_acceptance_emit.log`. Pressure data:
`docs/evidence/std_debug_hello_udivmoddi4_acceptance_pressure.tsv`.
