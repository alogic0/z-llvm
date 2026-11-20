# `__divei4` Typed Stack Byte Frontier

schema_version: 1
z_llvm_base_commit: `364bc4cf`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
result: `advanced`

The composed selector now stores an i1 through `%al` into a typed 8-bit frame
object and zero-extends a matching i8 stack load. Both disp8 and disp32 machine
forms are encoded and verified, while non-stack i1 pointer stores remain
fail-closed instead of widening to an i32 store.

```text
summary zllvm-codegen-report-all target=x86_64-unknown-linux-gnu selected_functions=443 emitted_functions=132 failed_functions=311 first_failing_function=compiler_rt.divmodei4.__divei4 first_failing_diagnostic=UnsupportedCodegenControlFlow first_failing_selector_tag=no_emitter first_failing_selector_detail=composed-block-binary-imm-rhs local_fail=1
```

Log: `tmp/divei4_stack_i1_retry.log`.
