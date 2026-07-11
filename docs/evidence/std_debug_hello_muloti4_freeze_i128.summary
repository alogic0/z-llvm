# `__muloti4` I128 Freeze Frontier

schema_version: 1
z_llvm_base_commit: `711f0d58`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
result: `advanced`

The composed selector now preserves `freeze i128` across proven pair-valued
register, stack-value, and spill locations while continuing to reject frame
object pointers and unrelated stack classes.

```text
zllvm-codegen-failure function=compiler_rt.mulo.__muloti4 diagnostic=UnsupportedCodegenControlFlow selector_tag=no_emitter selector_detail=composed-block-call-form
summary zllvm-codegen-report-all target=x86_64-unknown-linux-gnu selected_functions=443 emitted_functions=136 failed_functions=307 first_failing_function=compiler_rt.trunc.__trunch first_failing_diagnostic=UnsupportedCodegenControlFlow first_failing_selector_tag=unsupported_type first_failing_selector_detail=unsupported-return-type local_fail=1
```

Log: `tmp/muloti4_freeze_i128_retry.log`.
