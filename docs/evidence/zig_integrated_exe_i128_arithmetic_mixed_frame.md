# Executable Mixed Frame-Object Evidence

schema_version: 1
z_llvm_base_commit: `bce02dbf`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
change: `mixed aligned scalar and array frame-object layout`
result: `pass`

Two permanent arithmetic-fixture functions interleave aligned i8 objects with
i32 arrays. They verify that a far disp32 array store does not overwrite the
near array and that the far array reads back its own value.

```text
summary zig-integrated-exe total=5 build_ok=5 run_ok=5 stdout_ok=5 exit_ok=5 minimal_inline_asm_syscall_rows=3 compiler_rt_i128_arithmetic_rows=1 setcc_predicate_rows=1 local_fail=0
```

Log: `tmp/distribution_all_after_divei4_mixed_frame.log`.
