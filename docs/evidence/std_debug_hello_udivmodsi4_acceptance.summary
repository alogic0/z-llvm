# `__udivmodsi4` Acceptance Evidence

schema_version: 1
z_llvm_base_commit: `0a7ff4bd`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
target: `x86_64-linux-gnu`
result: `pass`

The i32 inequality form cleared the final selector frontier, but exact native
execution then exposed two allocator correctness defects. The first emitted
frame indexes beyond the reserved frame and overwrote the return address. The
second preserved only one of several values aliased to a clobbered register,
leaving a live loop phi bound to reused ECX. Planned i32 spill homes,
width-correct spill copies, stable framed parameter homes, and parallel-copy
phi-edge preservation repair those defects under the single value map.

The exact extracted body is call-free and relocation-free. Its native harness
checks `100 / 7`, a smaller dividend, zero dividend, and a full-width quotient;
all quotient and remainder results pass. Report-all also resolves the two
wrappers sharing this body.

```text
summary zllvm-codegen-report-all target=x86_64-unknown-linux-gnu selected_functions=443 emitted_functions=153 failed_functions=290 first_failing_function=compiler_rt.trunc.__trunch first_failing_diagnostic=UnsupportedCodegenControlFlow first_failing_selector_tag=unsupported_type first_failing_selector_detail=unsupported-return-type local_fail=1
focused object emission: status=0 symbol=compiler_rt.int.__udivmodsi4 size=1213
native link: status=0 linker=zig build-exe -fno-lld
linked executable: status=0
pressure: max_live_values=11 max_spill_slots_needed=5 max_spill_slots_over_envelope=0
resolved rows: compiler_rt.int.__udivmodsi4 compiler_rt.int.__udivsi3 compiler_rt.int.__umodsi3
```

Logs: `tmp/std_debug_hello_udivmodsi4_acceptance3.log`,
`tmp/udivmodsi4_acceptance_emit.log`, and
`tmp/udivmodsi4_native_link.log`.
Pressure data:
`docs/evidence/std_debug_hello_udivmodsi4_acceptance_pressure.tsv`.
