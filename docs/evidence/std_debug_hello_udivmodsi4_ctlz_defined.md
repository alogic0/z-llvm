# Gate Evidence Summary

schema_version: 1
log_path: `tmp/std_debug_hello_udivmodsi4_ctlz_defined.log`
z_llvm_base_commit: `4d40c89a`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
process_exit_status: `1`

The composed `llvm.ctlz.i32` lowering now accepts both legal i1 zero flags.
Its existing machine form defines the zero result as 32, satisfying the
`false` flag used by `__udivmodsi4`.

```text
compiler_rt.int.__udivmodsi4: no_emitter / composed-block-icmp-form
summary zllvm-codegen-report-all target=x86_64-unknown-linux-gnu selected_functions=443 emitted_functions=150 failed_functions=293 first_failing_function=compiler_rt.trunc.__trunch first_failing_diagnostic=UnsupportedCodegenControlFlow first_failing_selector_tag=unsupported_type first_failing_selector_detail=unsupported-return-type local_fail=1
```
