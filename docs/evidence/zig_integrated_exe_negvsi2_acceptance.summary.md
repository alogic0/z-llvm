# Executable i32 Negation Evidence

schema_version: 1
z_llvm_base_commit: `d1c7e18e`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
result: `pass`

The permanent arithmetic executable verifies `0 - 12 == -12` and
`0 - -12 == 12` through selector-produced code. Existing arithmetic and
predicate cases remain green.

```text
summary zig-integrated-exe total=5 build_ok=5 run_ok=5 stdout_ok=5 exit_ok=5 minimal_inline_asm_syscall_rows=3 compiler_rt_i128_arithmetic_rows=1 setcc_predicate_rows=1 local_fail=0
```

Log: `tmp/zig_integrated_exe_negvsi2_sub.log`.
