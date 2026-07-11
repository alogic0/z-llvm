# Executable Semantic Evidence

schema_version: 1
log_path: `tmp/zig_integrated_exe_i128_arithmetic_ctlz_i32.log`
command: `zig build distribution-zig-integrated-exe > tmp/zig_integrated_exe_i128_arithmetic_ctlz_i32.log 2>&1`
z_llvm_base_commit: `fa0ab77e`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
process_exit_status: `0`
result: `pass`

Selector-emitted `llvm.ctlz.i32(value, true)` checks inputs 1 and 16, expecting
31 and 27. Either mismatch changes the process exit code.
