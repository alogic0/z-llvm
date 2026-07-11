# Executable Signed I32 Comparison Evidence

schema_version: 1
z_llvm_base_commit: `089665a0`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
result: `pass`

The permanent arithmetic executable checks that `-1` is negative and zero is
not negative through the selector-emitted i32 sign-test function. Either wrong
result changes the process exit code.

```text
summary zig-integrated-exe total=5 build_ok=5 run_ok=5 stdout_ok=5 exit_ok=5 minimal_inline_asm_syscall_rows=3 compiler_rt_i128_arithmetic_rows=1 setcc_predicate_rows=1 local_fail=0
```

Log: `tmp/zig_integrated_exe_after_divei4_slt_i32.log`.
