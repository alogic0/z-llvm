# Gate Evidence Summary

schema_version: 1
log_path: `tmp/std_debug_hello_udivmoddi4_usub_tuple.log`
z_llvm_base_commit: `1c3e6cc8`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
process_exit_status: `1`

Unsigned-subtract overflow aggregates are now pressure-exempt like the other
selector-owned overflow tuples. Their extracted scalar components remain
ordinary planned values.

```text
compiler_rt.int.__udivmoddi4: no_emitter / stage2-phi-restore-loc
summary zllvm-codegen-report-all target=x86_64-unknown-linux-gnu selected_functions=443 emitted_functions=153 failed_functions=290 first_failing_function=compiler_rt.trunc.__trunch first_failing_diagnostic=UnsupportedCodegenControlFlow first_failing_selector_tag=unsupported_type first_failing_selector_detail=unsupported-return-type local_fail=1
```
