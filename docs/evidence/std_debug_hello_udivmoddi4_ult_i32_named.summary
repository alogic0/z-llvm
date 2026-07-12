# Gate Evidence Summary

schema_version: 1
log_path: `tmp/std_debug_hello_udivmoddi4_ult_i32_named.log`
command: `ZLLVM_DEBUG_DUMP_IR_SOURCE=__udivmoddi4 ZLLVM_GENERIC_CFG_SELECTOR=1 ZLLVM_CODEGEN_REPORT_ALL=1 ZLLVM_PIPELINE=postopt zig-out/bin/z_llvm --emit=obj --target=x86_64-unknown-linux-gnu --input-limit=67108864 tmp/udivmoddi4_ptr_null_cache/o/8c6b4a5e45095cb98b30ca8d3f251feb/libcompiler_rt_zcu.o.zllvm.ll`
z_llvm_base_commit: `5b74ec31`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
process_exit_status: `1`

Named i32 unsigned less-than now materializes the left operand in R8D and the
right operand in ECX before `cmpl %ecx, %r8d` and flag-preserving `setb`.
The nonzero process status is expected because report-all remains fail-closed
on unsupported compiler_rt rows.

```text
compiler_rt.int.__udivmoddi4: no_emitter / composed-block-binary-op
summary zllvm-codegen-report-all target=x86_64-unknown-linux-gnu selected_functions=443 emitted_functions=153 failed_functions=290 first_failing_function=compiler_rt.trunc.__trunch first_failing_diagnostic=UnsupportedCodegenControlFlow first_failing_selector_tag=unsupported_type first_failing_selector_detail=unsupported-return-type local_fail=1
```
