# `__umodei4` Stack-Array Load Frontier

schema_version: 1
z_llvm_base_commit: `0ea55b50`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
result: `advanced`

An i32 load from a local stack-array alloca now addresses element zero at the
array frame object's `base_disp`, matching the established direct store path.

```text
summary zllvm-codegen-report-all target=x86_64-unknown-linux-gnu selected_functions=443 emitted_functions=131 failed_functions=312 first_failing_function=compiler_rt.udivmodei4.__umodei4 first_failing_diagnostic=UnsupportedCodegenControlFlow first_failing_selector_tag=no_spill_envelope first_failing_selector_detail=composed-block-two-address-rhs-accumulator local_fail=1
```

Log: `tmp/umodei4_stack_array_load_retry.log`.
