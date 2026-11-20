# Executable Multi-Use Binary Evidence

schema_version: 1
z_llvm_base_commit: `bc28feb8`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
result: `pass`

The permanent arithmetic executable evaluates the same multi-use add/xor/and
lifetime pattern used by the signed overflow formulas and requires
`((7 + 3) xor 7) and ((7 + 3) xor 3) == 9`. Existing spill-condition true and
false cases remain green after register relocation.

```text
summary zig-integrated-exe total=5 build_ok=5 run_ok=5 stdout_ok=5 exit_ok=5 minimal_inline_asm_syscall_rows=3 compiler_rt_i128_arithmetic_rows=1 setcc_predicate_rows=1 local_fail=0
```

Log: `tmp/zig_integrated_exe_subvdi3_multi_use.log`.
