# `__umodei4` Spilled-Trunc Frontier

schema_version: 1
z_llvm_base_commit: `b1819bc9`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
result: `advanced`

Trunc and integer bitcast operations may now retain a `spill64` location when
no machine operation is required. Width-sensitive consumers still select the
reload width, so the frame slot remains the single value-location authority.

```text
summary zllvm-codegen-report-all target=x86_64-unknown-linux-gnu selected_functions=443 emitted_functions=131 failed_functions=312 first_failing_function=compiler_rt.udivmodei4.__umodei4 first_failing_diagnostic=UnsupportedCodegenControlFlow first_failing_selector_tag=no_emitter first_failing_selector_detail=composed-block-load-ptr local_fail=1
```

Log: `tmp/umodei4_spilled_trunc_retry.log`.
