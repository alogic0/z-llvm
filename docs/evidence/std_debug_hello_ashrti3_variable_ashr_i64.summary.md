# Variable i64 Arithmetic-Right Shift Evidence

schema_version: 1
z_llvm_base_commit: `798b79e8`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
result: `pass`

Named-count `ashr i64` now lowers through `sarq %cl, %rax`. Executable checks
cover positive values, negative values, and full-width sign propagation.

```text
summary zllvm-codegen-report-all target=x86_64-unknown-linux-gnu selected_functions=443 emitted_functions=163 failed_functions=280 first_failing_function=compiler_rt.trunc.__trunch first_failing_diagnostic=UnsupportedCodegenControlFlow first_failing_selector_tag=unsupported_type first_failing_selector_detail=unsupported-return-type local_fail=1
```

Log: `tmp/std_debug_hello_ashrti3_variable_ashr_i64.log`.

All three i128 shift rows emit. Acceptance is deliberately not claimed until
their exact native and pressure checks pass and Tier 3 closes the family.
