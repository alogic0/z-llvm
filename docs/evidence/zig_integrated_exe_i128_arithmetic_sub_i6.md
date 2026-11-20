# Executable Semantic Evidence

schema_version: 1
log_path: `tmp/zig_integrated_exe_i128_arithmetic_sub_i6.log`
command: `zig build distribution-zig-integrated-exe > tmp/zig_integrated_exe_i128_arithmetic_sub_i6.log 2>&1`
z_llvm_base_commit: `d42a72e4`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
process_exit_status: `0`
result: `pass`

The selector-emitted executable checks `-32 - rhs` modulo 64 for RHS 0, 1,
and 32. The existing i6 zext mask produces 32, 31, and 0 respectively.
