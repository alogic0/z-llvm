# Executable Semantic Evidence

schema_version: 1
log_path: `tmp/zig_integrated_exe_select_preserve.log`
command: `zig build distribution-zig-integrated-exe > tmp/zig_integrated_exe_select_preserve.log 2>&1`
z_llvm_base_commit: `25221fba`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
process_exit_status: `0`
result: `pass`

An accumulator-resident shifted true operand is explicitly spilled before the
select materializes false zero, then reloaded on the true path. Inputs exercise
both outcomes: 5 shifted by 3 returns 40 when selected and 0 otherwise.
