# Executable Semantic Evidence

schema_version: 1
log_path: `tmp/zig_integrated_exe_i128_arithmetic_spill_cond.log`
command: `zig build distribution-zig-integrated-exe > tmp/zig_integrated_exe_i128_arithmetic_spill_cond.log 2>&1`
z_llvm_base_commit: `5fbc63e9`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
process_exit_status: `0`
result: `pass`

A live i1 condition is evicted by an intervening accumulator operation, then
reloaded from spill64 for the branch. True and false paths return 27 and 0.
