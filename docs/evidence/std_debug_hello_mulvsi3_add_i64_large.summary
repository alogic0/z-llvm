# `__mulvsi3` Large I64 Immediate Add Frontier

schema_version: 1
z_llvm_base_commit: `64e7eec8`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
result: `advanced`

The composed selector now lowers i64 immediate adds whose constants do not fit
the sign-extended imm32 encoding by materializing the full constant in RCX and
performing a register add through RAX. Encodable signed imm32 constants retain
the compact existing path. The permanent executable canary verifies
`5 + 2147483648 == 2147483653`.

```text
zllvm-codegen-failure function=compiler_rt.mulvsi3.__mulvsi3 diagnostic=UnsupportedCodegenControlFlow selector_tag=no_emitter selector_detail=composed-block-call-form
summary zllvm-codegen-report-all target=x86_64-unknown-linux-gnu selected_functions=443 emitted_functions=138 failed_functions=305 first_failing_function=compiler_rt.trunc.__trunch first_failing_diagnostic=UnsupportedCodegenControlFlow first_failing_selector_tag=unsupported_type first_failing_selector_detail=unsupported-return-type local_fail=1
summary zig-integrated-exe total=5 build_ok=5 run_ok=5 stdout_ok=5 exit_ok=5 minimal_inline_asm_syscall_rows=3 compiler_rt_i128_arithmetic_rows=1 setcc_predicate_rows=1 local_fail=0
```

Validation: `zig build test`, `zig build`, and
`zig build distribution-zig-integrated-exe`, all status 0.
Logs: `tmp/std_debug_hello_mulvsi3_add_i64_large.log` and
`tmp/zig_integrated_exe_mulvsi3_add_i64_large.log`.
