# Gate Evidence Summary

schema_version: 1
log_path: `tmp/std_debug_hello_udivmodsi4_select_i1.log`
z_llvm_base_commit: `8e3d6774`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
process_exit_status: `1`

The composed selector now lowers scalar selects from i1 through i32 through
the existing EAX path. The exact `__udivmodsi4` row advances from its boolean
entry select to the next intrinsic form.

```text
compiler_rt.int.__udivmodsi4: no_emitter / composed-block-ctlz-args
summary zllvm-codegen-report-all target=x86_64-unknown-linux-gnu selected_functions=443 emitted_functions=150 failed_functions=293 first_failing_function=compiler_rt.trunc.__trunch first_failing_diagnostic=UnsupportedCodegenControlFlow first_failing_selector_tag=unsupported_type first_failing_selector_detail=unsupported-return-type local_fail=1
```
