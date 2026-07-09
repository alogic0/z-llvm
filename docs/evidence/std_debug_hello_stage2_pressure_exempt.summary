# Gate Evidence Summary

schema_version: 1
log_path: `tmp/std_debug_hello_debug_stage2_pressure_exempt.log`
command: `ZLLVM_DEBUG_DUMP_IR_SOURCE=__udivei5 ZLLVM_GENERIC_CFG_SELECTOR=1 ZLLVM_CODEGEN_REPORT_ALL=1 ZIG_USE_ZLLVM_OBJECT=1 ZLLVM_PIPELINE=postopt ZLLVM_EXE=zig-out/bin/z_llvm ../ziglang/build/stage4/bin/zig build-exe -fllvm -flibllvm -fno-lld -O Debug -target x86_64-linux-gnu test/zig/integrated/std_debug_hello.zig -femit-bin=tmp/std_debug_hello_debug_stage2_pressure_exempt 2>&1 | tee tmp/std_debug_hello_debug_stage2_pressure_exempt.log`
z_llvm_commit: `83cd609d97411135dcf4e267dfe2dc0d9549b0b8`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
process_exit_status: `0`
first_failure_line: `zllvm-codegen-failure function=compiler_rt.udivmodei4.__udivei5 diagnostic=UnsupportedCodegenControlFlow selector_tag=no_spill_envelope selector_detail=stage2-register-pressure`

## Ratchet Metadata

candidate_file_hash: `n/a`
selector_version: `n/a`
mode: `n/a`
limit: `n/a`
comparison_log_path: `n/a`
comparison_summary_lines_match: `n/a`
ratchet_migration_note: `n/a`

## Summary Lines

```text
summary zllvm-codegen-report-all target=x86_64-unknown-linux-gnu selected_functions=443 emitted_functions=126 failed_functions=317 first_failing_function=compiler_rt.udivmodei4.__udivei5 first_failing_diagnostic=UnsupportedCodegenControlFlow first_failing_selector_tag=no_spill_envelope first_failing_selector_detail=stage2-register-pressure local_fail=1
```
