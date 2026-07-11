# Executable Semantic Evidence

schema_version: 1
log_path: `tmp/zig_integrated_exe_variable_i32_shifts.log`
command: `zig build distribution-zig-integrated-exe > tmp/zig_integrated_exe_variable_i32_shifts.log 2>&1`
z_llvm_base_commit: `ea08086e`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
process_exit_status: `0`
result: `pass`

Variable i32 left shift maps 8 by 2 to 32, and variable logical-right shift
maps `0x80000000` by 31 to 1. Either incorrect shift direction changes the
integrated program's exit status.
