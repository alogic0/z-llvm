# Executable Semantic Evidence

schema_version: 1
log_path: `tmp/zig_integrated_exe_local_stack_gep_retry2.log`
command: `zig build distribution-zig-integrated-exe > tmp/zig_integrated_exe_local_stack_gep_retry2.log 2>&1`
z_llvm_base_commit: `5219cb1d`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
process_exit_status: `0`
result: `pass`

Three runtime cases prove constant byte offsets, direct optimized `[4 x i8]`
indices over local i32 arrays, and chained dynamic indices. The first chained
attempt exited with weight 40 because an eager `%rcx` update left an older
stack pointer stale; retaining both SSA index names and rematerializing them at
each load/store corrected the failure.
