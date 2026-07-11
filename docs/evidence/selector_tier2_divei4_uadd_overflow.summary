# Tier 2 Selector Validation

schema_version: 1
z_llvm_base_commit: `0585be0f`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
change: `composed i32 unsigned-add overflow aggregate lowering`
result: `pass`

```text
zig build test: status=0 tests=765/765
zig build structural-smoke: status=0
ReleaseFast captured object rows: status=0 rows=38
ReleaseSafe captured object rows: status=0 rows=9
permanent executable canaries: status=0 rows=5
distribution boundary gates: status=0
focused __divei4 retry: advanced to no_emitter/composed-block-alloca-form
```

Logs:

- `tmp/structural_smoke_after_divei4_uadd_overflow.log`
- `tmp/distribution_object_after_divei4_uadd_overflow.log`
- `tmp/distribution_releasesafe_object_after_divei4_uadd_overflow.log`
- `tmp/zig_integrated_exe_after_divei4_uadd_overflow.log`
- `tmp/distribution_boundary_after_divei4_uadd_overflow.log`

Tier 3 `distribution-all` was not required because the integer row advanced
but did not close, and this slice does not change an ABI or frame boundary.
