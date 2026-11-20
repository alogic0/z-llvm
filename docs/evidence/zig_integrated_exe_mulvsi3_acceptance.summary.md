# Executable Trap-Block Evidence

schema_version: 1
z_llvm_base_commit: `df9545a3`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
result: `pass`

The focused generated-code test executes both owned trap-block outcomes: the
ordinary branch returns 7, while a forked child taking the `ud2` branch exits
through SIGILL. The permanent executable suite and exact native-link harness
also remain green.

```text
focused generated trap execution: normal_return=7 trap_signal=SIGILL
summary zig-integrated-exe total=5 build_ok=5 run_ok=5 stdout_ok=5 exit_ok=5 minimal_inline_asm_syscall_rows=3 compiler_rt_i128_arithmetic_rows=1 setcc_predicate_rows=1 local_fail=0
```

Log: `tmp/zig_integrated_exe_mulvsi3_trap.log`.
