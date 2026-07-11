# Executable I128 Freeze Evidence

schema_version: 1
z_llvm_base_commit: `711f0d58`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
result: `pass`

The permanent arithmetic executable passes a nontrivial negative i128 value
through selector-emitted freeze and checks the exact returned value. A wrong
lane or location changes the process exit code.

```text
summary zig-integrated-exe total=5 build_ok=5 run_ok=5 stdout_ok=5 exit_ok=5 minimal_inline_asm_syscall_rows=3 compiler_rt_i128_arithmetic_rows=1 setcc_predicate_rows=1 local_fail=0
```

Log: `tmp/zig_integrated_exe_i128_arithmetic_freeze_i128.log`.
