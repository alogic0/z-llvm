# Executable Semantic Evidence

schema_version: 1
log_path: `tmp/zig_integrated_exe_stack_index_liveness.log`
command: `zig build distribution-zig-integrated-exe > tmp/zig_integrated_exe_stack_index_liveness.log 2>&1`
z_llvm_base_commit: `3215b1ff`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
process_exit_status: `0`
result: `pass`

A local pointer retains an index expression after its direct GEP use, then a
variable shift clobbers `%rcx`. The index is spilled, reloaded for the store,
and element zero remains 11 rather than being overwritten.
