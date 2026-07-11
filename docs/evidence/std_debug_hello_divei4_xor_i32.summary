# `__divei4` I32 Immediate XOR Frontier

schema_version: 1
z_llvm_base_commit: `c3522e85`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
result: `advanced`

The composed selector now lowers i32 XOR with an immediate by materializing
the constant in scratch and using the existing register XOR operation.

```text
summary zllvm-codegen-report-all target=x86_64-unknown-linux-gnu selected_functions=443 emitted_functions=132 failed_functions=311 first_failing_function=compiler_rt.divmodei4.__divei4 first_failing_diagnostic=UnsupportedCodegenControlFlow first_failing_selector_tag=no_emitter first_failing_selector_detail=composed-block-binary-width local_fail=1
```

Log: `tmp/divei4_xor_i32_retry.log`.
