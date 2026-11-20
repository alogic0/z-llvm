# Executable Canary Evidence

schema_version: 1
z_llvm_base_commit: `b1819bc9`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
change: `spill-backed trunc alias`
result: `pass`

The compiler_rt arithmetic fixture keeps an i32 live across inline memcpy,
spills it through the shared frame, truncates it to i6, zero-extends it, and
checks the returned low-bit result. A wrong reload or width changes the exit
code.

```text
summary zig-integrated-exe total=5 build_ok=5 run_ok=5 stdout_ok=5 exit_ok=5 minimal_inline_asm_syscall_rows=3 compiler_rt_i128_arithmetic_rows=1 setcc_predicate_rows=1 local_fail=0
```
