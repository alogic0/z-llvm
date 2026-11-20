# Gate Evidence Summary

schema_version: 1
log_path: `tmp/std_debug_hello_debug_udivei5_stack_index_liveness.log`
z_llvm_base_commit: `3215b1ff`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
process_exit_status: `1`

```text
summary zllvm-codegen-report-all target=x86_64-unknown-linux-gnu selected_functions=443 emitted_functions=130 failed_functions=313 first_failing_function=compiler_rt.udivmodei4.__udivei5 first_failing_diagnostic=UnsupportedCodegenControlFlow first_failing_selector_tag=no_spill_envelope first_failing_selector_detail=composed-block-two-address-rhs-accumulator local_fail=1
```
