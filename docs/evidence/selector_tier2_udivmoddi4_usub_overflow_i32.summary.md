# Tier 2 Selector Validation

schema_version: 1
z_llvm_base_commit: `fa582848`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
change: `operation-parametric composed i32 unsigned add/sub overflow`
result: `pass`

```text
zig build test: status=0 tests=826/826
zig build structural-smoke: status=0
zig build distribution-zig-integrated-object: status=0 rows=146/146
zig build distribution-zig-integrated-exe: status=0 rows=5/5
executable semantics: 7-3=value4 borrow0; 3-7=value0xfffffffc borrow1; 0-0x80000000=value0x80000000 borrow1
__udivmoddi4: emitted
```

Logs: `tmp/selector_tier2_udivmoddi4_usub_overflow_i32_object.log`,
`tmp/selector_tier2_udivmoddi4_usub_overflow_i32_exe.log`, and
`tmp/std_debug_hello_udivmoddi4_usub_overflow_i32.log`.

This is the emission boundary, not acceptance. Native-link, executable exact
row semantics, and the pressure diagnostic remain for the next INBOX-9 cycle.
