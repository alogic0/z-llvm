# Gate Evidence Summary

schema_version: 1
log_path: `tmp/std_debug_hello_udivmoddi4_store_i64.log`
z_llvm_base_commit: `d7dc3e33`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
process_exit_status: `1`

The composed memory selector now stores named i64 values through register or
spilled pointers by materializing the pointer in RCX and the value in RAX
through the authoritative value-location map.

```text
compiler_rt.int.__udivmoddi4: no_emitter / composed-block-icmp-form
summary zllvm-codegen-report-all target=x86_64-unknown-linux-gnu selected_functions=443 emitted_functions=153 failed_functions=290 first_failing_function=compiler_rt.trunc.__trunch first_failing_diagnostic=UnsupportedCodegenControlFlow first_failing_selector_tag=unsupported_type first_failing_selector_detail=unsupported-return-type local_fail=1
```
