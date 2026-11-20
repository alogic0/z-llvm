# `__mulvsi3` Cold Assume Bundle Frontier

schema_version: 1
z_llvm_base_commit: `09802230`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
result: `advanced`

Generic CFG inspection and composed `llvm.assume` lowering now admit only the
exact empty `[ "cold"() ]` operand bundle used as intrinsic metadata. The same
bundle on an ordinary call remains rejected, and verifier policy already
rejects argument-bearing bundle entries. No call ABI or arithmetic behavior is
admitted by this change.

```text
zllvm-codegen-failure function=compiler_rt.mulvsi3.__mulvsi3 diagnostic=UnsupportedCodegenControlFlow selector_tag=unsupported_value selector_detail=stage2-binary-value
summary zllvm-codegen-report-all target=x86_64-unknown-linux-gnu selected_functions=443 emitted_functions=138 failed_functions=305 first_failing_function=compiler_rt.trunc.__trunch first_failing_diagnostic=UnsupportedCodegenControlFlow first_failing_selector_tag=unsupported_type first_failing_selector_detail=unsupported-return-type local_fail=1
```

Validation: `zig build test`, status 0; `zig build`, status 0.
Log: `tmp/std_debug_hello_mulvsi3_cold_assume.log`.
