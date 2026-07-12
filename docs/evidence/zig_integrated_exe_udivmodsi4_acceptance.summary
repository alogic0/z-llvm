# Executable i32 Inequality Evidence

schema_version: 1
z_llvm_base_commit: `0a7ff4bd`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
result: `pass`

The permanent arithmetic executable checks i32 inequality against zero for
both outcomes and reuses the compared operand. The standalone exact
`__udivmodsi4` executable additionally validates quotient/remainder semantics
across four control-flow paths.

```text
summary zig-integrated-exe total=5 build_ok=5 run_ok=5 stdout_ok=5 exit_ok=5 minimal_inline_asm_syscall_rows=3 compiler_rt_i128_arithmetic_rows=1 setcc_predicate_rows=1 local_fail=0
summary zig-integrated-object pipeline=postopt ir_writer=false total=146 executable_ok=146 link_only_ok=0 local_fail=0
```

Logs: `tmp/zig_integrated_exe_udivmodsi4_acceptance_final.log` and
`tmp/zig_integrated_object_udivmodsi4_acceptance_final.log`.
