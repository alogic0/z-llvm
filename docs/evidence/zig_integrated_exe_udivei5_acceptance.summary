# Executable Canary Evidence

schema_version: 1
z_llvm_base_commit: `0fc6498b40ce88b0b747824a99048ea881371ad7`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
change: `trunc location class and shared framed return epilogue`
result: `pass`

The compiler_rt arithmetic canary executes the narrowed i64-to-i32 RHS and
both paths through a framed multi-block function: an early return and a later
stack store/load return. A wrong result changes the process exit code.

```text
summary zig-integrated-exe total=5 build_ok=5 run_ok=5 stdout_ok=5 exit_ok=5 minimal_inline_asm_syscall_rows=3 compiler_rt_i128_arithmetic_rows=1 setcc_predicate_rows=1 local_fail=0
```
