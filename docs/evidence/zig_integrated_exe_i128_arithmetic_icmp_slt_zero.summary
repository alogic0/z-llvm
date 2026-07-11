# Executable Semantic Evidence

schema_version: 1
log_path: `tmp/zig_integrated_exe_i128_arithmetic_icmp_slt_zero.log`
command: `zig build distribution-zig-integrated-exe > tmp/zig_integrated_exe_i128_arithmetic_icmp_slt_zero.log 2>&1`
z_llvm_base_commit: `5b1375da`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
process_exit_status: `0`
result: `pass`

The selector-emitted executable checks signed i64 values -1 and 0. Shifting
the sign bit into bit zero produces the expected predicate result or changes
the process exit code.
