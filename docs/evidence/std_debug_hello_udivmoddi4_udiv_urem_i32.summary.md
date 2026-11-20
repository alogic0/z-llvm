# Gate Evidence Summary

schema_version: 1
log_path: `tmp/std_debug_hello_udivmoddi4_udiv_urem_i32.log`
command: `ZLLVM_DEBUG_DUMP_IR_SOURCE=__udivmoddi4 ZLLVM_GENERIC_CFG_SELECTOR=1 ZLLVM_CODEGEN_REPORT_ALL=1 ZLLVM_PIPELINE=postopt zig-out/bin/z_llvm --emit=obj --target=x86_64-unknown-linux-gnu --input-limit=67108864 tmp/udivmoddi4_ptr_null_cache/o/8c6b4a5e45095cb98b30ca8d3f251feb/libcompiler_rt_zcu.o.zllvm.ll`
z_llvm_base_commit: `79608b4c`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
process_exit_status: `1`

The composed selector's unsigned division/remainder path now shares one
width-parametric fixed-register protocol for i32 and i64. i32 uses EDX:EAX and
the new `divl` machine form, while i64 continues to use RDX:RAX and `divq`.
The nonzero process status is expected because report-all remains fail-closed
on unsupported compiler_rt rows.

```text
compiler_rt.int.__udivmoddi4: no_emitter / composed-block-icmp-form
summary zllvm-codegen-report-all target=x86_64-unknown-linux-gnu selected_functions=443 emitted_functions=153 failed_functions=290 first_failing_function=compiler_rt.trunc.__trunch first_failing_diagnostic=UnsupportedCodegenControlFlow first_failing_selector_tag=unsupported_type first_failing_selector_detail=unsupported-return-type local_fail=1
```
