# Executable Canary Evidence

schema_version: 1
z_llvm_base_commit: `2ad94d00`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
change: `bounded stage-two CFG envelope from 64 to 128 blocks`
result: `pass`

The compiler_rt arithmetic fixture executes a 65-block composed CFG and
checks that its argument survives to the terminal return. A wrong branch or
return changes the process exit code.

```text
summary zig-integrated-exe total=5 build_ok=5 run_ok=5 stdout_ok=5 exit_ok=5 minimal_inline_asm_syscall_rows=3 compiler_rt_i128_arithmetic_rows=1 setcc_predicate_rows=1 local_fail=0
```
