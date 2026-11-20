# Executable Semantic Evidence

schema_version: 1
log_path: `tmp/zig_integrated_exe_i128_arithmetic_icmp_ne_i64_zero.log`
command: `zig build distribution-zig-integrated-exe > tmp/zig_integrated_exe_i128_arithmetic_icmp_ne_i64_zero.log 2>&1`
z_llvm_base_commit: `8e796bad`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
process_exit_status: `0`
result: `pass`

Selector-emitted i64 inequality checks values one and zero. Either wrong result
changes the integrated executable's exit code.
