# Gate Evidence Summary

schema_version: 1
log_path: `tmp/std_debug_hello_udivmoddi4_ptr_null.log`
z_llvm_base_commit: `cfd884c4`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
process_exit_status: `1`

Pointer equality with null now uses a width-correct 64-bit test followed by
the repaired flag-preserving equality materialization.

```text
compiler_rt.int.__udivmoddi4: no_emitter / composed-block-store-width
summary zllvm-codegen-report-all target=x86_64-unknown-linux-gnu selected_functions=443 emitted_functions=153 failed_functions=290 first_failing_function=compiler_rt.trunc.__trunch first_failing_diagnostic=UnsupportedCodegenControlFlow first_failing_selector_tag=unsupported_type first_failing_selector_detail=unsupported-return-type local_fail=1
```
