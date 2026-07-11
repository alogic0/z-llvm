# x86_64 Add-Carry Immediate-Zero Form

schema_version: 1
z_llvm_base_commit: `ef078b4e`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
change: `adcq $0, %rax machine operation`
result: `pass`

The machine, assembly, encoder, size, and verifier layers now provide a
general carry-propagation operation for a 64-bit accumulator. Exact bytes are
`48 83 d0 00`. An executable unit case first wraps `UINT64_MAX + 1`, then
proves that the new instruction converts the preserved carry into result `1`.

Tier 2 was selected under `docs/validation_tiers.md` because this closes a
machine/encoder arithmetic capability without changing ABI, frame layout,
allocation, a tracker item, or a strict ratchet.

```text
zig build test: status=0
zig build structural-smoke: status=0
zig build distribution-object: status=0 rows=38
zig build distribution-releasesafe-object: status=0 rows=9
zig build distribution-zig-integrated-exe: status=0 rows=5
zig build distribution-boundary: status=0
```

Logs use the `tmp/*_adc_rax_imm0.log` suffix. No report-all or item-15
accounting moves in this foundation slice.
