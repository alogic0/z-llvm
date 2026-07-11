# Executable Semantic Evidence

schema_version: 1
log_path: `tmp/zig_integrated_exe_store_ptr_forms.log`
command: `zig build distribution-zig-integrated-exe > tmp/zig_integrated_exe_store_ptr_forms.log 2>&1`
z_llvm_base_commit: `bbaa0baa`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
process_exit_status: `0`
result: `pass`

One pressure case stores 77 through a spilled external pointer and verifies
the target plus six neighbors. A second case stores 91 directly through a
local i32 array alloca and reads element zero through a typed GEP.
