# Executable Pointer Select Evidence

schema_version: 1
z_llvm_base_commit: `7fb4ad4b`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
result: `pass`

The permanent arithmetic executable selects between two distinct pointers for
both true and false conditions and compares each result with its expected
pointer. Either wrong branch or pointer value changes the process exit code.

```text
summary zig-integrated-exe total=5 build_ok=5 run_ok=5 stdout_ok=5 exit_ok=5 minimal_inline_asm_syscall_rows=3 compiler_rt_i128_arithmetic_rows=1 setcc_predicate_rows=1 local_fail=0
```

Log: `tmp/distribution_all_after_modei5_divei5_acceptance.log`.
