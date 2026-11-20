# Gate Evidence Summary

schema_version: 1
log_path: `tmp/zig_integrated_exe_setcc_correctness.log`
command: `zig build distribution-zig-integrated-exe > tmp/zig_integrated_exe_setcc_correctness.log 2>&1`
z_llvm_commit: `46926530be5d269ff98cf4a472a833c6da46d6da`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
process_exit_status: `0`
first_failure_line: `none`

## Ratchet Metadata

candidate_file_hash: `n/a`
selector_version: `n/a`
mode: `n/a`
limit: `n/a`
comparison_log_path: `n/a`
comparison_summary_lines_match: `n/a`
ratchet_migration_note: `No ratchet migration. A fifth integrated executable row now exercises true and false sete, setne, unsigned-less setb, and unsigned-greater semantics from an MC-encoded ELF object.`

## Summary Lines

```text
summary zig-integrated-exe total=5 build_ok=5 run_ok=5 stdout_ok=5 exit_ok=5 minimal_inline_asm_syscall_rows=3 compiler_rt_i128_arithmetic_rows=1 setcc_predicate_rows=1 local_fail=0
```
