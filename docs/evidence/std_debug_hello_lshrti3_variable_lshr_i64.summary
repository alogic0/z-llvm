# Variable i64 Logical-Right Shift Evidence

schema_version: 1
z_llvm_base_commit: `ca90daef`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
result: `pass`

The composed selector now lowers named-count `lshr i64` through a verified
`shrq %cl, %rax` machine form. Executable checks cover the sign-bit boundary
and a multi-bit high-nibble shift.

```text
summary zllvm-codegen-report-all target=x86_64-unknown-linux-gnu selected_functions=443 emitted_functions=160 failed_functions=283 first_failing_function=compiler_rt.trunc.__trunch first_failing_diagnostic=UnsupportedCodegenControlFlow first_failing_selector_tag=unsupported_type first_failing_selector_detail=unsupported-return-type local_fail=1
compiler_rt.shift.__lshrti3: composed-block-binary-op
compiler_rt.shift.__ashrti3: composed-block-binary-op
compiler_rt.shift.__ashlti3: composed-block-binary-op
```

Log: `tmp/std_debug_hello_lshrti3_variable_lshr_i64.log`.

No report-count migration occurred. The exact rows remain fail-closed at a
later operation carrying the same coarse binary-op diagnostic.
