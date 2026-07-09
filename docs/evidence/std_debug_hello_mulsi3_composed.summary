# Gate Evidence Summary

schema_version: 1
log_path: `tmp/std_debug_hello_debug_mulsi3_composed.log`
command: `ZLLVM_DEBUG_DUMP_IR_SOURCE=__mulsi3 ZLLVM_GENERIC_CFG_SELECTOR=1 ZLLVM_CODEGEN_REPORT_ALL=1 ZIG_USE_ZLLVM_OBJECT=1 ZLLVM_PIPELINE=postopt ZLLVM_EXE=zig-out/bin/z_llvm ../ziglang/build/stage4/bin/zig build-exe -fllvm -flibllvm -fno-lld -O Debug -target x86_64-linux-gnu test/zig/integrated/std_debug_hello.zig -femit-bin=tmp/std_debug_hello_debug_mulsi3_composed 2>&1 | tee tmp/std_debug_hello_debug_mulsi3_composed.log`
z_llvm_commit: `134b228f471b8fbc6312240a492f69b92a9e3a9a`
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

## Composed Row Metadata

row: `compiler_rt.mulXi3.__mulsi3`
emission_path: `composed-selection`
terminal_template: `false`
stage_two_boundary: `false`
max_live_values: `3`
max_spill_slots_needed: `0`
max_spill_slots_over_envelope: `0`
first_exceeding_block: `-`
first_exceeding_boundary: `-`
validation_log_path: `tmp/distribution_all_after_mulsi3_composed.log`

## Summary Lines

```text
summary zllvm-codegen-report-all target=x86_64-unknown-linux-gnu selected_functions=443 emitted_functions=129 failed_functions=314 first_failing_function=compiler_rt.udivmodei4.__udivei5 first_failing_diagnostic=UnsupportedCodegenControlFlow first_failing_selector_tag=no_spill_envelope first_failing_selector_detail=stage2-register-pressure local_fail=1
```
