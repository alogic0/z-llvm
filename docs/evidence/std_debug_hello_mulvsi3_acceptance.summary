# `__mulvsi3` Composed Acceptance Evidence

schema_version: 1
z_llvm_base_commit: `df9545a3`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
target: `x86_64-linux-gnu`
result: `pass`

The composed selector owns exact zero-argument `llvm.trap` calls as x86 `ud2`
and accepts `unreachable` only when the same block ends in that trap. A forked
executable selector test proves the safe branch returns and the trap branch
terminates with SIGILL after resetting the inherited test-runner signal handler.

The exact `compiler_rt.mulvsi3.__mulvsi3` body emits as a 62-byte function,
patched stage4 Zig links it with `-fno-lld`, and the linked harness verifies
positive and negative non-overflow products.

```text
summary zllvm-codegen-report-all target=x86_64-unknown-linux-gnu selected_functions=443 emitted_functions=139 failed_functions=304 first_failing_function=compiler_rt.trunc.__trunch first_failing_diagnostic=UnsupportedCodegenControlFlow first_failing_selector_tag=unsupported_type first_failing_selector_detail=unsupported-return-type local_fail=1
focused object emission: status=0 symbol=compiler_rt.mulvsi3.__mulvsi3 size=62
native link: status=0 linker=zig build-exe -fno-lld
linked executable: status=0
pressure: max_live_values=2 max_spill_slots_needed=0 max_spill_slots_over_envelope=0
```

Logs: `tmp/mulvsi3_acceptance_emit.log` and
`tmp/std_debug_hello_mulvsi3_trap.log`.
Pressure data: `docs/evidence/std_debug_hello_mulvsi3_acceptance_pressure.tsv`.
