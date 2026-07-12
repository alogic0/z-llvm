# Tier 2 Selector Validation

schema_version: 1
z_llvm_base_commit: `73c8343a`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
change: `frame-backed phi destinations beyond the dedicated register pool`
result: `pass`

```text
zig build test: status=0 tests=805/805
zig build structural-smoke: status=0
zig-integrated-object: status=0 rows=146/146
zig-integrated-exe: status=0 rows=5/5
four-phi executable result: expected=26 status=0
__udivmodsi4 frontier: composed-block-select-width
```

Tier 3 was not required because `__udivmodsi4` advanced to a later frontier
but did not close, no strict ratchet moved, and no ABI boundary changed.
