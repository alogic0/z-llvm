# Executable Named i32 Multiply Evidence

schema_version: 1
z_llvm_base_commit: `f573657b`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
result: `pass`

The permanent arithmetic executable checks a named i32 product that exceeds
32 bits and requires the correct wrapping low half. The standalone exact
`__muldi3` executable additionally covers low-limb, cross-limb, and wrapping
u64 products.

```text
summary zig-integrated-exe total=5 build_ok=5 run_ok=5 stdout_ok=5 exit_ok=5 minimal_inline_asm_syscall_rows=3 compiler_rt_i128_arithmetic_rows=1 setcc_predicate_rows=1 local_fail=0
```

Log: `tmp/zig_integrated_exe_muldi3_acceptance.log`.
