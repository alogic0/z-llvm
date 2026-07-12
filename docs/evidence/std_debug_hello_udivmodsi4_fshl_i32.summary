# Gate Evidence Summary

schema_version: 1
log_path: `tmp/std_debug_hello_udivmodsi4_fshl_i32.log`
z_llvm_base_commit: `791f368a`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
process_exit_status: `1`

The machine and encoder layers now expose i32 funnel shift as x86 `shldl`
with EAX destination and an allocator-visible register source. The composed
selector lowers constant-amount `llvm.fshl.i32` calls through that operation.

```text
compiler_rt.int.__udivmodsi4: unsupported_value / stage2-phi-src-spill64
summary zllvm-codegen-report-all target=x86_64-unknown-linux-gnu selected_functions=443 emitted_functions=150 failed_functions=293 first_failing_function=compiler_rt.trunc.__trunch first_failing_diagnostic=UnsupportedCodegenControlFlow first_failing_selector_tag=unsupported_type first_failing_selector_detail=unsupported-return-type local_fail=1
```
