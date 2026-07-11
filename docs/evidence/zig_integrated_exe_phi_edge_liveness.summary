# Executable Semantic Evidence

schema_version: 1
log_path: `tmp/zig_integrated_exe_phi_edge_liveness.log`
command: `zig build distribution-zig-integrated-exe > tmp/zig_integrated_exe_phi_edge_liveness.log 2>&1`
z_llvm_base_commit: `2ff0af12`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
target: `x86_64-unknown-linux-gnu`
process_exit_status: `0`
result: `pass`

The selector-emitted executable contains a phi block placed textually before
the predecessor that defines its incoming value. Calling it with 41 must
return 42; a dropped or stale incoming binding changes the process exit code.

```text
summary zig-integrated-exe total=5 build_ok=5 run_ok=5 stdout_ok=5 exit_ok=5 minimal_inline_asm_syscall_rows=3 compiler_rt_i128_arithmetic_rows=1 setcc_predicate_rows=1 local_fail=0
```
