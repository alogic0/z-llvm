# Executable Semantic Evidence

schema_version: 1
log_path: `tmp/zig_integrated_exe_i128_arithmetic_icmp_ptr_eq.log`
command: `zig build distribution-zig-integrated-exe > tmp/zig_integrated_exe_i128_arithmetic_icmp_ptr_eq.log 2>&1`
z_llvm_base_commit: `e2811b76`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
target: `x86_64-unknown-linux-gnu`
process_exit_status: `0`
result: `pass`

The compiler-rt arithmetic executable now calls selector-emitted pointer
equality with identical and distinct addresses. The expected results are one
and zero respectively, and either mismatch contributes a nonzero process exit
code.

```text
ok zig-integrated-exe case=compiler_rt_i128_arithmetic_releasefast mode=ReleaseFast proof=compiler_rt_i128_arithmetic exit=0
summary zig-integrated-exe total=5 build_ok=5 run_ok=5 stdout_ok=5 exit_ok=5 minimal_inline_asm_syscall_rows=3 compiler_rt_i128_arithmetic_rows=1 setcc_predicate_rows=1 local_fail=0
```
