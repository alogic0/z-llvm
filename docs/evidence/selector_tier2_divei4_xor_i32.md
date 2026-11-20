# Tier 2 Selector Validation

schema_version: 1
z_llvm_base_commit: `c3522e85`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
change: `composed i32 immediate xor lowering`
result: `pass`

```text
zig build test: status=0 tests=768/768
zig build structural-smoke: status=0
ReleaseFast captured object rows: status=0 rows=38
ReleaseSafe captured object rows: status=0 rows=9
permanent executable canaries: status=0 rows=5
distribution boundary gates: status=0
focused __divei4 retry: advanced to no_emitter/composed-block-binary-width
```

Tier 3 was not required under `docs/validation_tiers.md` because the row
advanced without closing and no ABI, frame, relocation, or ratchet changed.
