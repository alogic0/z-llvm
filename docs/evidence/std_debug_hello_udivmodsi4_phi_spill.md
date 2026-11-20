# Gate Evidence Summary

schema_version: 1
log_path: `tmp/std_debug_hello_udivmodsi4_phi_spill_generic.log`
z_llvm_base_commit: `73c8343a`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
process_exit_status: `1`

Frame-backed phi destinations now extend the three-register phi pool through
the selector's single spill authority. The exact `__udivmodsi4` row fits the
pressure envelope and advances from `stage2-phi-registers` to the next
instruction form.

```text
compiler_rt.int.__udivmodsi4: no_emitter / composed-block-select-width
summary zllvm-codegen-report-all target=x86_64-unknown-linux-gnu selected_functions=443 emitted_functions=150 failed_functions=293 first_failing_function=compiler_rt.trunc.__trunch first_failing_diagnostic=UnsupportedCodegenControlFlow first_failing_selector_tag=unsupported_type first_failing_selector_detail=unsupported-return-type local_fail=1
```
