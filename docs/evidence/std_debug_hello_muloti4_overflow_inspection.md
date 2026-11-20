# `__muloti4` I128 Overflow Inspection Frontier

schema_version: 1
z_llvm_base_commit: `8f3264df`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
result: `advanced`

Generic CFG inspection now recognizes the exact
`{ i128, i1 } @llvm.smul.with.overflow.i128(i128, i128)` signature and matching
extractvalue types. No arithmetic lowering is admitted: the real row now fails
closed at aggregate overflow-result planning.

```text
zllvm-codegen-failure function=compiler_rt.mulo.__muloti4 diagnostic=UnsupportedCodegenControlFlow selector_tag=unsupported_value selector_detail=stage2-unsupported-value
summary zllvm-codegen-report-all target=x86_64-unknown-linux-gnu selected_functions=443 emitted_functions=136 failed_functions=307 first_failing_function=compiler_rt.trunc.__trunch first_failing_diagnostic=UnsupportedCodegenControlFlow first_failing_selector_tag=unsupported_type first_failing_selector_detail=unsupported-return-type local_fail=1
```

Validation: `zig build test`, status 0, `773/773` tests.
Log: `tmp/muloti4_inspection_full_retry.log`.
