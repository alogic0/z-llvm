# Gate Evidence Summary

schema_version: 1
log_path: `tmp/std_debug_hello_udivmodsi4_phi_spill_frame.log`
z_llvm_base_commit: `2e0303d1`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
process_exit_status: `1`

Spill materialization now validates the concrete frame index being accessed
against the finalized frame size. It no longer rejects an existing valid slot
when unrelated later allocation has advanced the cumulative spill cursor.

```text
compiler_rt.int.__udivmodsi4: no_emitter / composed-block-icmp-form
summary zllvm-codegen-report-all target=x86_64-unknown-linux-gnu selected_functions=443 emitted_functions=150 failed_functions=293 first_failing_function=compiler_rt.trunc.__trunch first_failing_diagnostic=UnsupportedCodegenControlFlow first_failing_selector_tag=unsupported_type first_failing_selector_detail=unsupported-return-type local_fail=1
```
