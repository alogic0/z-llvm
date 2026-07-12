# `__negvsi2` I32 Minimum Equality Frontier

schema_version: 1
z_llvm_base_commit: `16514250`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
result: `advanced`

The composed selector now lowers nonzero immediate equality for integer widths
up to 32 through EAX and `cmp eax, imm32`, complementing the existing i64 and
i128 forms. Permanent executable cases distinguish `INT32_MIN` from its
adjacent value.

```text
zllvm-codegen-failure function=compiler_rt.negv.__negvsi2 diagnostic=UnsupportedCodegenControlFlow selector_tag=no_emitter selector_detail=composed-block-binary-imm-lhs
summary zllvm-codegen-report-all target=x86_64-unknown-linux-gnu selected_functions=443 emitted_functions=143 failed_functions=300 first_failing_function=compiler_rt.trunc.__trunch first_failing_diagnostic=UnsupportedCodegenControlFlow first_failing_selector_tag=unsupported_type first_failing_selector_detail=unsupported-return-type local_fail=1
summary zig-integrated-exe total=5 build_ok=5 run_ok=5 stdout_ok=5 exit_ok=5 minimal_inline_asm_syscall_rows=3 compiler_rt_i128_arithmetic_rows=1 setcc_predicate_rows=1 local_fail=0
```

Validation: `zig build test`, `zig build`, and
`zig build distribution-zig-integrated-exe`, all status 0.
Logs: `tmp/std_debug_hello_negvsi2_eq_min.log` and
`tmp/zig_integrated_exe_negvsi2_eq_min.log`.
