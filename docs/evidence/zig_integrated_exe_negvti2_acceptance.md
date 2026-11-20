# Executable i128 Negation Evidence

schema_version: 1
z_llvm_base_commit: `8a3d40e2`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
result: `pass`

The permanent arithmetic executable verifies positive and negative i128
negation through selector-produced pair subtraction. The focused selector test
also executes the exact framed overflow guard and requires SIGILL for
`minInt(i128)`.

```text
summary zig-integrated-exe total=5 build_ok=5 run_ok=5 stdout_ok=5 exit_ok=5 minimal_inline_asm_syscall_rows=3 compiler_rt_i128_arithmetic_rows=1 setcc_predicate_rows=1 local_fail=0
```

Log: `tmp/zig_integrated_exe_negvti2_acceptance.log`.
