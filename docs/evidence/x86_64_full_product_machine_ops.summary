# x86_64 Full-Product Machine Operations

schema_version: 1
z_llvm_base_commit: `22e09945`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
change: `general one-operand mulq and imulq machine operations`
result: `pass`

The machine layer now represents unsigned and signed 64-by-64 full products.
Both operations follow the x86_64 architectural contract: RAX is the low
64-bit definition and RDX is the high 64-bit definition. Exact assembly,
encoding, and instruction-size checks cover ordinary and REX.B operands.
Executable unit checks call generated code through the C ABI and prove both
halves with an unsigned overflowing-64-bit product and a negative signed
product.

Tier 2 was selected under `docs/validation_tiers.md` because this closes the
machine/encoder capability but does not yet change selector allocation, ABI,
frame layout, a strict ratchet, or a tracker item.

```text
zig build test: status=0
zig build structural-smoke: status=0
zig build distribution-object: status=0 rows=38
zig build distribution-releasesafe-object: status=0 rows=9
zig build distribution-zig-integrated-exe: status=0 rows=5
zig build distribution-boundary: status=0
```

Logs:

- `tmp/distribution_object_full_product_machine_ops.log`
- `tmp/distribution_releasesafe_object_full_product_machine_ops.log`
- `tmp/zig_integrated_exe_full_product_machine_ops.log`
- `tmp/distribution_boundary_full_product_machine_ops.log`

No report-all or item-15 accounting moves in this foundation slice. The next
slice must expose both fixed definitions through the selector's ordinary
displace/clobber/value-map protocol before the i128 overflow intrinsic uses
the operations.
