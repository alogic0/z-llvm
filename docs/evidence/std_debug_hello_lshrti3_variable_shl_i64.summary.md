# Variable i64 Left Shift Evidence

schema_version: 1
z_llvm_base_commit: `79118987`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
result: `pass`

The composed selector now lowers named-count `shl i64` through a verified
`shlq %cl, %rax` machine form. Executable checks cover shifts into the sign
bit and full high-nibble placement.

```text
summary zllvm-codegen-report-all target=x86_64-unknown-linux-gnu selected_functions=443 emitted_functions=162 failed_functions=281 first_failing_function=compiler_rt.trunc.__trunch first_failing_diagnostic=UnsupportedCodegenControlFlow first_failing_selector_tag=unsupported_type first_failing_selector_detail=unsupported-return-type local_fail=1
compiler_rt.shift.__ashrti3: composed-block-binary-op
```

Log: `tmp/std_debug_hello_lshrti3_variable_shl_i64.log`.

Fresh report after rebuilding `zig-out/bin/z_llvm` shows `__lshrti3` and
`__ashlti3` emitting. Their exact acceptance remains pending; only
`__ashrti3` remains fail-closed at the next operation-specific form.
