# i64 Limb-Decomposed Multiply Acceptance

schema_version: 1
z_llvm_base_commit: `f573657b`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
target: `x86_64-linux-gnu`
result: `pass`

The x86_64 machine and encoder layers now provide named i32 multiplication
through `imull r32, %eax`, including high-register REX.B encoding. The
composed selector uses that operation for allocator-visible i32 products.

The exact `__muldi3` native harness initially failed only the wrapping
`maxInt(u64) * 2` case. Disassembly showed a live EAX value used by both
left and right shifts being overwritten because preservation silently stopped
when RDX was occupied. EAX preservation now chooses any available mapped
scratch register and otherwise uses the planned spill path.

The final 311-byte decomposed body native-links with patched Zig and
`-fno-lld` and passes low-limb, cross-limb, and wrapping products.

```text
summary zllvm-codegen-report-all target=x86_64-unknown-linux-gnu selected_functions=443 emitted_functions=150 failed_functions=293 first_failing_function=compiler_rt.trunc.__trunch first_failing_diagnostic=UnsupportedCodegenControlFlow first_failing_selector_tag=unsupported_type first_failing_selector_detail=unsupported-return-type local_fail=1
focused object emission: status=0 symbol=muldi3 size=311
native link: status=0 linker=zig build-exe -fno-lld
linked executable: status=0
pressure: max_live_values=10 max_spill_slots_needed=4 max_spill_slots_over_envelope=0
```

Logs: `tmp/std_debug_hello_muldi3_acceptance.log` and
`tmp/muldi3_acceptance_emit.log`.
Pressure data: `docs/evidence/std_debug_hello_muldi3_acceptance_pressure.tsv`.
