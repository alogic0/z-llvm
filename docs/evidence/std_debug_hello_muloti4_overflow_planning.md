# `__muloti4` Overflow Tuple Planning Frontier

schema_version: 1
z_llvm_base_commit: `0643dea1`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
result: `advanced`

Stage-two planning now pressure-exempts the exact i128 signed-multiply
overflow aggregate, matching the selector-side component-location invariant
already used by i32 add-overflow tuples. No arithmetic lowering is admitted.

```text
zllvm-codegen-failure function=compiler_rt.mulo.__muloti4 diagnostic=UnsupportedCodegenControlFlow selector_tag=no_emitter selector_detail=composed-block-freeze-width
summary zllvm-codegen-report-all target=x86_64-unknown-linux-gnu selected_functions=443 emitted_functions=136 failed_functions=307 first_failing_function=compiler_rt.trunc.__trunch first_failing_diagnostic=UnsupportedCodegenControlFlow first_failing_selector_tag=unsupported_type first_failing_selector_detail=unsupported-return-type local_fail=1
```

Validation: `zig build test`, status 0, `774/774` tests.
Log: `tmp/muloti4_overflow_planning_retry.log`.
