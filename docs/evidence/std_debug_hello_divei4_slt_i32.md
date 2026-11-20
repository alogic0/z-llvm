# `__divei4` Signed I32 Less-Than-Zero Frontier

schema_version: 1
z_llvm_base_commit: `089665a0`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
result: `advanced`

The composed selector now lowers `icmp slt i32 value, 0` by extracting bit 31
through a logical shift, yielding a canonical zero-or-one result.

```text
summary zllvm-codegen-report-all target=x86_64-unknown-linux-gnu selected_functions=443 emitted_functions=132 failed_functions=311 first_failing_function=compiler_rt.divmodei4.__divei4 first_failing_diagnostic=UnsupportedCodegenControlFlow first_failing_selector_tag=no_emitter first_failing_selector_detail=composed-block-store-width local_fail=1
```

Log: `tmp/divei4_slt_i32_retry.log`.
