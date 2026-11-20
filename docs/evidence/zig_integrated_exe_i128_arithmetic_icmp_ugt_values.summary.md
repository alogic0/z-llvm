# Executable Semantic Evidence

schema_version: 1
log_path: `tmp/zig_integrated_exe_i128_arithmetic_icmp_ugt_values.log`
command: `zig build distribution-zig-integrated-exe > tmp/zig_integrated_exe_i128_arithmetic_icmp_ugt_values.log 2>&1`
z_llvm_base_commit: `2f4ed6f0`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
target: `x86_64-unknown-linux-gnu`
process_exit_status: `0`
result: `pass`

The selector-emitted executable checks true and false named i64 unsigned-
greater comparisons. The initial reversed compare produced exit code 41;
the corrected RCX-LHS/R8-RHS order produces exit code zero.

```text
summary zig-integrated-exe total=5 build_ok=5 run_ok=5 stdout_ok=5 exit_ok=5 minimal_inline_asm_syscall_rows=3 compiler_rt_i128_arithmetic_rows=1 setcc_predicate_rows=1 local_fail=0
```
