# i64 Negation And Absolute-Value Acceptance

schema_version: 1
z_llvm_base_commit: `704d6c5d`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
target: `x86_64-linux-gnu`
result: `pass`

The composed selector now lowers immediate-left i64 subtraction. It also
relocates a live RAX binding through the single value map before destructive
signed-less-than-zero predicate generation.

The exact native harness initially exited 1 and exposed `__absvdi2` returning
the overflow predicate instead of the absolute value. After relocation, exact
`__negvdi2` and `__absvdi2` shapes emit, native-link with patched Zig and
`-fno-lld`, and return correct positive and negative results. The machine
verifier carries the incoming return-register state of a terminal trap block
to its immediately following sibling label while ordinary labels remain
fail-closed.

```text
summary zllvm-codegen-report-all target=x86_64-unknown-linux-gnu selected_functions=443 emitted_functions=148 failed_functions=295 first_failing_function=compiler_rt.trunc.__trunch first_failing_diagnostic=UnsupportedCodegenControlFlow first_failing_selector_tag=unsupported_type first_failing_selector_detail=unsupported-return-type local_fail=1
focused object emission: status=0 negv_i64_size=54 absv_i64_size=45
native link: status=0 linker=zig build-exe -fno-lld
linked executable: status=0
negvdi2 pressure: max_live_values=2 max_spill_slots_needed=0 max_spill_slots_over_envelope=0
absvdi2 pressure: max_live_values=2 max_spill_slots_needed=0 max_spill_slots_over_envelope=0
```

Logs: `tmp/std_debug_hello_negvdi2_absvdi2.log` and
`tmp/negvdi2_acceptance_emit.log`.
Pressure data:
`docs/evidence/std_debug_hello_negvdi2_acceptance_pressure.tsv` and
`docs/evidence/std_debug_hello_absvdi2_acceptance_pressure.tsv`.
