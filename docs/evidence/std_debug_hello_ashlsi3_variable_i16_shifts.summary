# `__ashlsi3` Variable i16 Shift Evidence

schema_version: 1
z_llvm_base_commit: `76475388`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
target: `x86_64-linux-gnu`
result: `pass`

The existing EAX/CL variable shift path now handles i16 `shl` and `lshr` as
well as i32, preserving the low-width result through the selector value map.
The exact `compiler_rt.shift.__ashlsi3` body clears its remaining binary forms
and advances from `composed-block-binary-op` to
`unsupported_value/stage2-phi-src-unknown`.

```text
summary zllvm-codegen-report-all target=x86_64-unknown-linux-gnu selected_functions=443 emitted_functions=154 failed_functions=289 first_failing_function=compiler_rt.trunc.__trunch first_failing_diagnostic=UnsupportedCodegenControlFlow first_failing_selector_tag=unsupported_type first_failing_selector_detail=unsupported-return-type local_fail=1
compiler_rt.shift.__ashlsi3: unsupported_value / stage2-phi-src-unknown
```

Log: `tmp/std_debug_hello_ashlsi3_variable_i16_shifts.log`.
