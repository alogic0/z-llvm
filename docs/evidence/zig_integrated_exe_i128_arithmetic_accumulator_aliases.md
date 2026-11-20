# Executable Semantic Evidence

schema_version: 1
log_path: `tmp/zig_integrated_exe_accumulator_aliases_gate.log`
command: `zig build distribution-zig-integrated-exe > tmp/zig_integrated_exe_accumulator_aliases_gate.log 2>&1`
z_llvm_base_commit: `7f810983`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
process_exit_status: `0`
result: `pass`

One case proves noncommutative RHS-accumulator order with `20 - (3 + 4) =
13`. A second load/zext/add chain returns 17 and proves every live accumulator
alias is preserved before destructive in-place arithmetic.
