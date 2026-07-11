# Gate Evidence Summary

schema_version: 1
log_path: `tmp/std_debug_hello_debug_udivei5_load_i32_spill_ptr.log`
command: `ZLLVM_DEBUG_DUMP_IR_SOURCE=__udivei5 ZLLVM_GENERIC_CFG_SELECTOR=1 ZLLVM_CODEGEN_REPORT_ALL=1 ZIG_USE_ZLLVM_OBJECT=1 ZLLVM_PIPELINE=postopt ZLLVM_EXE=zig-out/bin/z_llvm ../ziglang/build/stage4/bin/zig build-exe -fllvm -flibllvm -fno-lld -O Debug -target x86_64-linux-gnu test/zig/integrated/std_debug_hello.zig -femit-bin=tmp/std_debug_hello_debug_udivei5_load_i32_spill_ptr > tmp/std_debug_hello_debug_udivei5_load_i32_spill_ptr.log 2>&1`
z_llvm_base_commit: `f2971187`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
process_exit_status: `1`
first_failure_line: `error: sub-compilation of compiler_rt failed`

## Ratchet Metadata

candidate_file_hash: `n/a`
selector_version: `n/a`
mode: `Debug`
limit: `443`
comparison_log_path: `tmp/std_debug_hello_debug_udivei5_icmp_ptr_eq.log`
comparison_summary_lines_match: `counts match; frontier advances`
ratchet_migration_note: `No report-count migration. Reloading a spilled pointer for an i32 load advances __udivei5 from composed-block-load-ptr to stage2-phi-src while report-all remains 443 selected / 130 emitted / 313 failed.`

## Summary Lines

```text
summary zllvm-codegen-report-all target=x86_64-unknown-linux-gnu selected_functions=443 emitted_functions=130 failed_functions=313 first_failing_function=compiler_rt.udivmodei4.__udivei5 first_failing_diagnostic=UnsupportedCodegenControlFlow first_failing_selector_tag=unsupported_value first_failing_selector_detail=stage2-phi-src local_fail=1
```
