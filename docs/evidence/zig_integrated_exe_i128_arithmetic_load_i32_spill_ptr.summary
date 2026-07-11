# Executable Semantic Evidence

schema_version: 1
log_path: `tmp/zig_integrated_exe_i128_arithmetic_load_i32_spill_ptr.log`
command: `zig build distribution-zig-integrated-exe > tmp/zig_integrated_exe_i128_arithmetic_load_i32_spill_ptr.log 2>&1`
z_llvm_base_commit: `f2971187`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
target: `x86_64-unknown-linux-gnu`
process_exit_status: `0`
result: `pass`

The compiler-rt arithmetic executable calls a selector-emitted function whose
seven simultaneously live derived pointers force the final pointer into a
spill slot. The function reloads that pointer, reads the expected i32 value,
and folds six true pointer predicates into the returned result. A wrong reload
or load changes the process exit code.

```text
ok zig-integrated-exe case=compiler_rt_i128_arithmetic_releasefast mode=ReleaseFast proof=compiler_rt_i128_arithmetic exit=0
summary zig-integrated-exe total=5 build_ok=5 run_ok=5 stdout_ok=5 exit_ok=5 minimal_inline_asm_syscall_rows=3 compiler_rt_i128_arithmetic_rows=1 setcc_predicate_rows=1 local_fail=0
```
