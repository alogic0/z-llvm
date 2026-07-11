# `__umodei4` Inline-Memcpy Frontier

schema_version: 1
z_llvm_base_commit: `89e15cd8`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
result: `advanced`

The composed selector now validates and lowers nonvolatile
`llvm.memcpy.inline.p0.p0.i64` calls through the existing x86_64 memcpy
primitive. Live caller-clobbered values are spilled before destination,
source, and length arguments are materialized.

```text
summary zllvm-codegen-report-all target=x86_64-unknown-linux-gnu selected_functions=443 emitted_functions=131 failed_functions=312 first_failing_function=compiler_rt.udivmodei4.__umodei4 first_failing_diagnostic=UnsupportedCodegenControlFlow first_failing_selector_tag=no_emitter first_failing_selector_detail=composed-block-cast-width local_fail=1
```

Log: `tmp/umodei4_inline_memcpy_retry.log`.
