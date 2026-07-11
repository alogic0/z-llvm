# `__modei5` One-Byte Array GEP Frontier

schema_version: 1
z_llvm_base_commit: `15c5ca95`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
result: `advanced`

The composed selector now treats a one-index `[1 x i8]` GEP as byte pointer
arithmetic. Executable validation also exposed and repaired the shared dynamic
byte-GEP result binding: `add_r8_rcx` writes `%rcx`, so the value map now binds
the result to `%rcx` instead of the unadjusted base in `%r8`.

```text
summary zllvm-codegen-report-all target=x86_64-unknown-linux-gnu selected_functions=443 emitted_functions=133 failed_functions=310 first_failing_function=compiler_rt.divmodei4.__modei5 first_failing_diagnostic=UnsupportedCodegenControlFlow first_failing_selector_tag=no_emitter first_failing_selector_detail=composed-block-icmp-form local_fail=1
```

Log: `tmp/modei5_gep_source_retry.log`.
