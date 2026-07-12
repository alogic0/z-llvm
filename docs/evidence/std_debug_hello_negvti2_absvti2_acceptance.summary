# Framed i128 Trap Acceptance

schema_version: 1
z_llvm_base_commit: `8a3d40e2`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
target: `x86_64-linux-gnu`
result: `pass`

The composed selector now lowers zero-left i128 subtraction through the
existing low-limb `sub` and high-limb `sbb` pair operation. The machine
verifier also recognizes that `ud2` is terminal and therefore does not
require a live stack frame to be restored before the trap.

This closes `compiler_rt.negv.__negvti2` and the already-selected
`compiler_rt.absvti2.__absvti2`, which shared the framed-trap verifier
boundary. An exact executable-shape unit test checks positive and negative
i128 negation and verifies SIGILL for the minimum value with the frame active.
Standalone exact-shape objects native-link with patched Zig and `-fno-lld`;
the linked harness validates negation and absolute-value results.

```text
summary zllvm-codegen-report-all target=x86_64-unknown-linux-gnu selected_functions=443 emitted_functions=146 failed_functions=297 first_failing_function=compiler_rt.trunc.__trunch first_failing_diagnostic=UnsupportedCodegenControlFlow first_failing_selector_tag=unsupported_type first_failing_selector_detail=unsupported-return-type local_fail=1
focused object emission: status=0 negv_i128_size=144 absv_i128_size=128
native link: status=0 linker=zig build-exe -fno-lld
linked executable: status=0
negvti2 pressure: max_live_values=2 max_spill_slots_needed=0 max_spill_slots_over_envelope=0
absvti2 pressure: max_live_values=2 max_spill_slots_needed=0 max_spill_slots_over_envelope=0
```

Logs: `tmp/std_debug_hello_negvti2_framed_trap.log` and
`tmp/negvti2_acceptance_emit.log`.
Pressure data:
`docs/evidence/std_debug_hello_negvti2_acceptance_pressure.tsv` and
`docs/evidence/std_debug_hello_absvti2_acceptance_pressure.tsv`.
