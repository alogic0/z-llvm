# Executable Dynamic Byte GEP Evidence

schema_version: 1
z_llvm_base_commit: `15c5ca95`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
result: `pass`

The permanent arithmetic executable computes `base + 5` through a `[1 x i8]`
GEP and compares it with a caller-provided expected pointer. Before the result
binding repair this case exited with code 72; the accepted implementation exits
zero.

```text
summary zig-integrated-exe total=5 build_ok=5 run_ok=5 stdout_ok=5 exit_ok=5 minimal_inline_asm_syscall_rows=3 compiler_rt_i128_arithmetic_rows=1 setcc_predicate_rows=1 local_fail=0
```

Log: `tmp/zig_integrated_exe_i128_arithmetic_modei5_gep_source.log`.
