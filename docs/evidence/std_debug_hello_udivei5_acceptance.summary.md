# `__udivei5` Acceptance Evidence

schema_version: 1
z_llvm_base_commit: `0fc6498b40ce88b0b747824a99048ea881371ad7`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
target: `x86_64-linux-gnu`
result: `pass`

The focused Debug compiler_rt report-all retry moved the first failing row to
`compiler_rt.udivmodei4.__umodei4`, proving that `__udivei5` selected and
emitted. `llvm-extract-22` then isolated the exact captured post-optimization
body; `z_llvm` emitted it as `tmp/udivei5_acceptance.o`, and patched stage4 Zig
linked that object with `-fno-lld`. The resulting executable exited zero.

```text
summary zllvm-codegen-report-all target=x86_64-unknown-linux-gnu selected_functions=443 emitted_functions=131 failed_functions=312 first_failing_function=compiler_rt.udivmodei4.__umodei4 first_failing_diagnostic=UnsupportedCodegenControlFlow first_failing_selector_tag=no_spill_envelope first_failing_selector_detail=stage2-block-count local_fail=1
focused object emission: status=0 symbol=compiler_rt.udivmodei4.__udivei5 size=7876
native link: status=0 linker=zig build-exe -fno-lld
linked executable: status=0
```

Logs: `tmp/std_debug_hello_debug_udivei5_shared_epilogue.log`,
`tmp/udivei5_acceptance_emit.log`, and `tmp/udivei5_native_link.log`.
