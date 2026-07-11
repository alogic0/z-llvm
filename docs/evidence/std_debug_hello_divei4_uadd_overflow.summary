# `__divei4` I32 Unsigned-Add Overflow Frontier

schema_version: 1
z_llvm_base_commit: `0585be0f`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
result: `advanced`

The composed selector now represents the exact
`llvm.uadd.with.overflow.i32` aggregate as a wrapped i32 value plus an i1
carry location and consumes the compiler-rt extraction order fail closed.

```text
summary zllvm-codegen-report-all target=x86_64-unknown-linux-gnu selected_functions=443 emitted_functions=132 failed_functions=311 first_failing_function=compiler_rt.divmodei4.__divei4 first_failing_diagnostic=UnsupportedCodegenControlFlow first_failing_selector_tag=no_emitter first_failing_selector_detail=composed-block-alloca-form local_fail=1
```

Log: `tmp/divei4_uadd_overflow_retry.log`.
