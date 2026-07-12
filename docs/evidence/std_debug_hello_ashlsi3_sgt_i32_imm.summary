# `__ashlsi3` Signed i32 Immediate Comparison Evidence

schema_version: 1
z_llvm_base_commit: `193ee5d8`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
target: `x86_64-linux-gnu`
result: `pass`

Signed i32 greater-than against an immediate now lowers through `cmpl` and a
flag-preserving `setg %al; movzbl %al, %eax` machine form. The exact
`compiler_rt.shift.__ashlsi3` body clears its first `icmp sgt i32 %shift, 15`
and remains fail-closed at a later `composed-block-icmp-form`.

```text
summary zllvm-codegen-report-all target=x86_64-unknown-linux-gnu selected_functions=443 emitted_functions=154 failed_functions=289 first_failing_function=compiler_rt.trunc.__trunch first_failing_diagnostic=UnsupportedCodegenControlFlow first_failing_selector_tag=unsupported_type first_failing_selector_detail=unsupported-return-type local_fail=1
compiler_rt.shift.__ashlsi3: no_emitter / composed-block-icmp-form
encoding: cmp eax,15 = 3d 0f 00 00 00; setg/movzx = 0f 9f c0 0f b6 c0
```

Log: `tmp/std_debug_hello_ashlsi3_sgt_i32_imm.log`.
