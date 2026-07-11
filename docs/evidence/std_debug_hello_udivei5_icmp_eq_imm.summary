# Gate Evidence Summary

schema_version: 1
log_path: `tmp/std_debug_hello_debug_udivei5_icmp_eq_imm.log`
command: `ZLLVM_DEBUG_DUMP_IR_SOURCE=__udivei5 ZLLVM_GENERIC_CFG_SELECTOR=1 ZLLVM_CODEGEN_REPORT_ALL=1 ZIG_USE_ZLLVM_OBJECT=1 ZLLVM_PIPELINE=postopt ZLLVM_EXE=zig-out/bin/z_llvm ../ziglang/build/stage4/bin/zig build-exe -fllvm -flibllvm -fno-lld -O Debug -target x86_64-linux-gnu test/zig/integrated/std_debug_hello.zig -femit-bin=tmp/std_debug_hello_debug_udivei5_icmp_eq_imm > tmp/std_debug_hello_debug_udivei5_icmp_eq_imm.log 2>&1`
z_llvm_commit: `66712dfc8f3f5d3dc05fadf0c2063871991313c4`
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
ratchet_migration_note: `No report-count migration. Nonzero i64 equality-immediate lowering advances __udivei5 from composed-block-icmp-eq-rhs to composed-block-icmp-rhs while report-all remains 443 selected / 130 emitted / 313 failed.`

## Summary Lines

```text
summary zllvm-codegen-report-all target=x86_64-unknown-linux-gnu selected_functions=443 emitted_functions=130 failed_functions=313 first_failing_function=compiler_rt.udivmodei4.__udivei5 first_failing_diagnostic=UnsupportedCodegenControlFlow first_failing_selector_tag=no_emitter first_failing_selector_detail=composed-block-icmp-rhs local_fail=1
```
