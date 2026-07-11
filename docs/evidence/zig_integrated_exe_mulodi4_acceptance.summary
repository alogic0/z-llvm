# Executable I64 Signed Multiply Overflow Evidence

schema_version: 1
z_llvm_base_commit: `30d9e5d5`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
result: `pass`

The permanent arithmetic executable verifies i64 signed multiply result and
overflow components for positive and negative non-overflow and overflow cases.
The exact native harness independently verifies the compiler-rt out-parameter
contract and exits zero.

```text
focused __mulodi4 native executable: status=0
summary zig-integrated-exe total=5 build_ok=5 run_ok=5 stdout_ok=5 exit_ok=5 minimal_inline_asm_syscall_rows=3 compiler_rt_i128_arithmetic_rows=1 setcc_predicate_rows=1 local_fail=0
```

Log: `tmp/zig_integrated_exe_mulodi4_acceptance.log`.
