# Executable I32 Unsigned-Add Overflow Evidence

schema_version: 1
z_llvm_base_commit: `0585be0f`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
change: `composed llvm.uadd.with.overflow.i32 and extractvalue lowering`
result: `pass`

The permanent compiler-rt arithmetic executable now checks both extracted
components for a plain `7 + 5` addition and the wrapping `0xffffffff + 1`
case. A wrong sum or carry changes the process exit code.

```text
summary zig-integrated-exe total=5 build_ok=5 run_ok=5 stdout_ok=5 exit_ok=5 minimal_inline_asm_syscall_rows=3 compiler_rt_i128_arithmetic_rows=1 setcc_predicate_rows=1 local_fail=0
```

Log: `tmp/zig_integrated_exe_after_divei4_uadd_overflow.log`.
