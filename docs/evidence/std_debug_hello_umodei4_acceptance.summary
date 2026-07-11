# `__umodei4` Acceptance Evidence

schema_version: 1
z_llvm_base_commit: `c9e78368`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
target: `x86_64-linux-gnu`
result: `pass`

The focused compiler_rt report-all retry moves beyond `__umodei4` to
`compiler_rt.divmodei4.__divei4`. `llvm-extract-22` isolated the exact
captured post-optimization body; `z_llvm` emitted it as a 10,177-byte
function, patched stage4 Zig linked the object with `-fno-lld`, and the linked
executable exited zero.

```text
summary zllvm-codegen-report-all target=x86_64-unknown-linux-gnu selected_functions=443 emitted_functions=132 failed_functions=311 first_failing_function=compiler_rt.divmodei4.__divei4 first_failing_diagnostic=UnsupportedCodegenControlFlow first_failing_selector_tag=unsupported_type first_failing_selector_detail=call-ret local_fail=1
focused object emission: status=0 symbol=compiler_rt.udivmodei4.__umodei4 size=10177
native link: status=0 linker=zig build-exe -fno-lld
linked executable: status=0
```

Logs: `tmp/umodei4_accumulator_alias_retry.log`,
`tmp/umodei4_acceptance_emit.log`, and `tmp/umodei4_native_link.log`.
