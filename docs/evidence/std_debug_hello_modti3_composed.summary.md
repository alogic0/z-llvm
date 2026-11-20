# Gate Evidence Summary

schema_version: 1
log_path: `tmp/std_debug_hello_debug_modti3_composed.log`
command: `ZLLVM_DEBUG_DUMP_IR_SOURCE=__modti3 ZLLVM_GENERIC_CFG_SELECTOR=1 ZLLVM_CODEGEN_REPORT_ALL=1 ZIG_USE_ZLLVM_OBJECT=1 ZLLVM_PIPELINE=postopt ZLLVM_EXE=zig-out/bin/z_llvm ../ziglang/build/stage4/bin/zig build-exe -fllvm -flibllvm -fno-lld -O Debug -target x86_64-linux-gnu test/zig/integrated/std_debug_hello.zig -femit-bin=tmp/std_debug_hello_debug_modti3_composed 2>&1 | tee tmp/std_debug_hello_debug_modti3_composed.log`
z_llvm_commit: `8655f006f2ffafc47886f489a31989b4ffa060ac`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
process_exit_status: `0`
first_failure_line: `zllvm-codegen-failure function=compiler_rt.udivmodei4.__udivei5 diagnostic=UnsupportedCodegenControlFlow selector_tag=no_spill_envelope selector_detail=stage2-register-pressure`

## Ratchet Metadata

candidate_file_hash: `n/a`
selector_version: `n/a`
mode: `Debug`
limit: `compiler_rt`
comparison_log_path: `n/a`
comparison_summary_lines_match: `n/a`
ratchet_migration_note: `n/a`

## Summary Lines

```text
summary zllvm-codegen-report-all target=x86_64-unknown-linux-gnu selected_functions=443 emitted_functions=128 failed_functions=315 first_failing_function=compiler_rt.udivmodei4.__udivei5 first_failing_diagnostic=UnsupportedCodegenControlFlow first_failing_selector_tag=no_spill_envelope first_failing_selector_detail=stage2-register-pressure local_fail=1
```
