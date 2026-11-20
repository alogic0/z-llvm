# `__divei4` Mixed Frame-Object Frontier

schema_version: 1
z_llvm_base_commit: `bce02dbf`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
result: `advanced`

The composed frame authority now lays out multiple typed scalar and i32-array
allocas in declaration order with explicit alignment. The exact `__divei4`
frame contains six i8 objects plus `[2049 x i32]` and `[2048 x i32]` objects.

```text
summary zllvm-codegen-report-all target=x86_64-unknown-linux-gnu selected_functions=443 emitted_functions=132 failed_functions=311 first_failing_function=compiler_rt.divmodei4.__divei4 first_failing_diagnostic=UnsupportedCodegenControlFlow first_failing_selector_tag=no_emitter first_failing_selector_detail=composed-block-icmp-form local_fail=1
```

Log: `tmp/divei4_mixed_frame_retry.log`.
