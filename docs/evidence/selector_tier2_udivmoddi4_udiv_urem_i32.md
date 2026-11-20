# Tier 2 Selector And Machine Validation

schema_version: 1
z_llvm_base_commit: `79608b4c`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
change: `width-parametric composed unsigned division/remainder with divl machine form`
result: `pass`

```text
zig build test: status=0 tests=824/824
zig build structural-smoke: status=0
encoding: divl %ecx=f7 f1 divl %r8d=41 f7 f0
assembly: xorl %edx,%edx; divl %ecx
zig build distribution-zig-integrated-object: status=0 rows=146/146
zig build distribution-zig-integrated-exe: status=0 rows=5/5
executable semantics: 100/7 quotient=14 remainder=2; 0x80000000/7 quotient=306783378 remainder=2
__udivmoddi4 frontier: composed-block-icmp-form
```

Logs: `tmp/selector_tier2_udivmoddi4_udiv_urem_i32_object.log`,
`tmp/selector_tier2_udivmoddi4_udiv_urem_i32_exe.log`, and
`tmp/std_debug_hello_udivmoddi4_udiv_urem_i32.log`.

Tier 3 was not repeated: this machine/selector capability passed the binding
machine-layer and selector Tier 2 gates, and it does not change an ABI, frame,
allocator, relocation, AIR-export, linker, tracker, or strict-ratchet boundary.
