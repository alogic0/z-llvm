# Executable `__muloti4` Acceptance Evidence

schema_version: 1
z_llvm_base_commit: `53643df1`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
result: `pass`

The permanent i128 arithmetic executable now exercises boolean conjunction of
two i128 predicates with one true case and two independently false cases. The
focused native acceptance harness also executes exact `__muloti4` result and
overflow-pointer checks in both sign directions.

```text
focused __muloti4 native executable: status=0
summary zig-integrated-exe total=5 build_ok=5 run_ok=5 stdout_ok=5 exit_ok=5 minimal_inline_asm_syscall_rows=3 compiler_rt_i128_arithmetic_rows=1 setcc_predicate_rows=1 local_fail=0
```

Log: `tmp/distribution_all_after_muloti4_acceptance.log`.
