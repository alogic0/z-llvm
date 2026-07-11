# Executable Semantic Evidence

schema_version: 1
log_path: `tmp/zig_integrated_exe_phi_stable_final.log`
command: `zig build distribution-zig-integrated-exe > tmp/zig_integrated_exe_phi_stable_final.log 2>&1`
z_llvm_base_commit: `eab34c81`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
process_exit_status: `0`
result: `pass`

A three-PHI loop forces its third PHI out of `%rcx` through a variable shift
and returns 13 after two iterations. The first executable attempt exposed a
one-byte high-register compare size overcount and jumped into an instruction;
after that repair, exit weight 42 exposed a path-sensitive PHI location bug.
Stable PHI destinations and restoration before non-PHI outgoing edges correct
both loop continuation and exit semantics.
