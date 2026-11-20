# Executable Canary Evidence

schema_version: 1
z_llvm_base_commit: `0ea55b50`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
change: `direct i32 load from local stack array`
result: `pass`

The existing stack-array-base executable case now stores and loads element
zero directly through the alloca pointer and checks the returned value.

```text
summary zig-integrated-exe total=5 build_ok=5 run_ok=5 stdout_ok=5 exit_ok=5 minimal_inline_asm_syscall_rows=3 compiler_rt_i128_arithmetic_rows=1 setcc_predicate_rows=1 local_fail=0
```
