# Gate Evidence Summary

schema_version: 1
log_path: `tmp/std_debug_hello_debug_udivei5_icmp_sgt_i6.log`
command: `ZLLVM_DEBUG_DUMP_IR_SOURCE=__udivei5 ZLLVM_GENERIC_CFG_SELECTOR=1 ZLLVM_CODEGEN_REPORT_ALL=1 ZIG_USE_ZLLVM_OBJECT=1 ZLLVM_PIPELINE=postopt ZLLVM_EXE=zig-out/bin/z_llvm ../ziglang/build/stage4/bin/zig build-exe -fllvm -flibllvm -fno-lld -O Debug -target x86_64-linux-gnu test/zig/integrated/std_debug_hello.zig -femit-bin=tmp/std_debug_hello_debug_udivei5_icmp_sgt_i6 > tmp/std_debug_hello_debug_udivei5_icmp_sgt_i6.log 2>&1`
z_llvm_base_commit: `e9f22b95`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
process_exit_status: `1`
result: `expected frontier failure`

```text
summary zllvm-codegen-report-all target=x86_64-unknown-linux-gnu selected_functions=443 emitted_functions=130 failed_functions=313 first_failing_function=compiler_rt.udivmodei4.__udivei5 first_failing_diagnostic=UnsupportedCodegenControlFlow first_failing_selector_tag=no_emitter first_failing_selector_detail=composed-block-icmp-form local_fail=1
```
