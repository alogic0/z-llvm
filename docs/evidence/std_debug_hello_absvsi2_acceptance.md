# i32 Absolute-Value Acceptance

schema_version: 1
z_llvm_base_commit: `4c733fd3`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
target: `x86_64-linux-gnu`
result: `pass`

The x86_64 machine layer now provides a width-correct i32 conditional-negate
operation for exact `llvm.abs.i32(value, false)` calls. Assembly and encoding
use `movl`, `negl`, `testl`, and `cmovsl`; malformed signatures and
poison-enabled modes remain fail-closed.

The exact native harness initially exited 1 and exposed the same destructive
predicate bug as i64: signed-less-than-zero shifted the live EAX absolute value
in place. Relocating the live binding through the single value map fixes the
result. The 36-byte exact shape native-links with patched Zig and `-fno-lld`
and returns correct positive and negative values.

```text
summary zllvm-codegen-report-all target=x86_64-unknown-linux-gnu selected_functions=443 emitted_functions=149 failed_functions=294 first_failing_function=compiler_rt.trunc.__trunch first_failing_diagnostic=UnsupportedCodegenControlFlow first_failing_selector_tag=unsupported_type first_failing_selector_detail=unsupported-return-type local_fail=1
focused object emission: status=0 symbol=absv_i32 size=36
native link: status=0 linker=zig build-exe -fno-lld
linked executable: status=0
pressure: max_live_values=2 max_spill_slots_needed=0 max_spill_slots_over_envelope=0
```

Logs: `tmp/std_debug_hello_absvsi2.log` and
`tmp/absvsi2_acceptance_emit.log`.
Pressure data: `docs/evidence/std_debug_hello_absvsi2_acceptance_pressure.tsv`.
