# Gate Evidence Summary

schema_version: 1
log_path: `tmp/std_debug_hello_debug_report_all.log`
command: `ZLLVM_CODEGEN_REPORT_ALL=1 ZIG_USE_ZLLVM_OBJECT=1 ZLLVM_PIPELINE=postopt ZLLVM_EXE=zig-out/bin/z_llvm ../ziglang/build/stage4/bin/zig build-exe -fllvm -flibllvm -fno-lld -O Debug -target x86_64-linux-gnu test/zig/integrated/std_debug_hello.zig -femit-bin=tmp/std_debug_hello_debug_report_all`
z_llvm_commit: `f60802c66d056d202d6b59cce8db1735df86167f`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
process_exit_status: `1`
first_failure_line: `zllvm-codegen-failure function=compiler_rt.limb64.__mulo_limb64 diagnostic=UnsupportedCodegenControlFlow`

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
summary zllvm-codegen-report-all target=x86_64-unknown-linux-gnu selected_functions=443 emitted_functions=103 failed_functions=340 first_failing_function=compiler_rt.limb64.__mulo_limb64 first_failing_diagnostic=UnsupportedCodegenControlFlow local_fail=1
```
