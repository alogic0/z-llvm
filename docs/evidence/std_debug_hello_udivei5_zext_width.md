# Gate Evidence Summary

schema_version: 1
log_path: `tmp/std_debug_hello_debug_udivei5_zext_width.log`
command: `ZLLVM_DEBUG_DUMP_IR_SOURCE=__udivei5 ZLLVM_GENERIC_CFG_SELECTOR=1 ZLLVM_CODEGEN_REPORT_ALL=1 ZIG_USE_ZLLVM_OBJECT=1 ZLLVM_PIPELINE=postopt ZLLVM_EXE=zig-out/bin/z_llvm ../ziglang/build/stage4/bin/zig build-exe -fllvm -flibllvm -fno-lld -O Debug -target x86_64-linux-gnu test/zig/integrated/std_debug_hello.zig -femit-bin=tmp/std_debug_hello_debug_udivei5_zext_width > tmp/std_debug_hello_debug_udivei5_zext_width.log 2>&1`
z_llvm_commit: `91a38428c60dff65197bd0ea75067dbd48fa5aa6`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
process_exit_status: `1`
first_failure_line: `error: sub-compilation of compiler_rt failed`

## Ratchet Metadata

candidate_file_hash: `n/a`
selector_version: `n/a`
mode: `Debug`
limit: `443`
comparison_log_path: `n/a`
comparison_summary_lines_match: `n/a`
ratchet_migration_note: `No report-count migration. Narrow-to-i64 zext lowering advances __udivei5 from composed-block-zext-width to composed-block-gep-source while report-all remains 443 selected / 130 emitted / 313 failed.`

## Summary Lines

```text
summary zllvm-codegen-report-all target=x86_64-unknown-linux-gnu selected_functions=443 emitted_functions=130 failed_functions=313 first_failing_function=compiler_rt.udivmodei4.__udivei5 first_failing_diagnostic=UnsupportedCodegenControlFlow first_failing_selector_tag=no_emitter first_failing_selector_detail=composed-block-gep-source local_fail=1
```
