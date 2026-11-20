# `__ashlsi3` Unsigned i32 Immediate Comparison Evidence

schema_version: 1
z_llvm_base_commit: `ec18226d`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
target: `x86_64-linux-gnu`
result: `pass`

Unsigned i32 less-than against an immediate now lowers through `cmpl` and the
existing flag-preserving `setb` materialization. The exact
`compiler_rt.shift.__ashlsi3` body clears `icmp samesign ult i32 %shift, 32`
and advances from `composed-block-icmp-form` to `composed-block-binary-op`.

```text
summary zllvm-codegen-report-all target=x86_64-unknown-linux-gnu selected_functions=443 emitted_functions=154 failed_functions=289 first_failing_function=compiler_rt.trunc.__trunch first_failing_diagnostic=UnsupportedCodegenControlFlow first_failing_selector_tag=unsupported_type first_failing_selector_detail=unsupported-return-type local_fail=1
compiler_rt.shift.__ashlsi3: no_emitter / composed-block-binary-op
```

Log: `tmp/std_debug_hello_ashlsi3_ult_i32_imm.log`.
