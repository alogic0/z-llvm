# Executable Shift Phi-Edge Evidence

schema_version: 1
z_llvm_base_commit: `cb42edcd`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
result: `pass`

```text
summary zig-integrated-exe total=5 build_ok=5 run_ok=5 stdout_ok=5 exit_ok=5 minimal_inline_asm_syscall_rows=3 compiler_rt_i128_arithmetic_rows=1 setcc_predicate_rows=1 local_fail=0
exact __ashlsi3 executable: status=0 cases=5/5
```

The permanent canary covers variable i16 left/right shifts; the exact native
harness covers counts 0, 1, 15, 16, and 31.
