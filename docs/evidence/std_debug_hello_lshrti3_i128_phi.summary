# i128 Phi-Edge Lowering Evidence

schema_version: 1
z_llvm_base_commit: `9879923a`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
result: `pass`

The composed selector now assigns i128 phi results to frame-backed pair
locations and copies named register or spilled pairs into those destinations.
Pair-spill copies preserve both limbs when source and destination overlap.

```text
summary zllvm-codegen-report-all target=x86_64-unknown-linux-gnu selected_functions=443 emitted_functions=160 failed_functions=283 first_failing_function=compiler_rt.trunc.__trunch first_failing_diagnostic=UnsupportedCodegenControlFlow first_failing_selector_tag=unsupported_type first_failing_selector_detail=unsupported-return-type local_fail=1
compiler_rt.shift.__lshrti3: composed-block-binary-op
compiler_rt.shift.__ashrti3: composed-block-binary-op
compiler_rt.shift.__ashlti3: composed-block-binary-op
```

Command: `ZLLVM_DEBUG_DUMP_IR_SOURCE=__lshrti3 ZLLVM_GENERIC_CFG_SELECTOR=1 ZLLVM_CODEGEN_REPORT_ALL=1 ZLLVM_PIPELINE=postopt zig-out/bin/z_llvm --emit=obj --target=x86_64-unknown-linux-gnu --input-limit=67108864 tmp/udivmoddi4_ptr_null_cache/o/8c6b4a5e45095cb98b30ca8d3f251feb/libcompiler_rt_zcu.o.zllvm.ll`

Log: `tmp/std_debug_hello_lshrti3_i128_phi.log`.

No report-count migration occurred. All three i128 shift rows advanced from
`stage2-phi-width` to the first unsupported binary operation.
