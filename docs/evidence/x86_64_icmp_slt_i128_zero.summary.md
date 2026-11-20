# x86_64 I128 Signed-Negative Comparison

schema_version: 1
z_llvm_base_commit: `740e072b`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
change: `icmp slt i128 value, 0`
result: `advanced`

The composed selector now lowers signed i128 negativity by extracting bit 63
of the high limb. Register pairs, stack i128 values, and pair spills share the
same high-lane materialization path. Unit and permanent executable cases prove
negative and zero results.

The exact `__muloti4` retry advances from `composed-block-icmp-form` to
`unsupported_value/stage2-icmp-value`, where planning does not yet admit its
i128 minimum-value equality constant.

Tier 2 is green:

```text
zig build test: status=0
zig build structural-smoke: status=0
zig build distribution-object: status=0 rows=38
zig build distribution-releasesafe-object: status=0 rows=9
zig build distribution-zig-integrated-exe: status=0 rows=5
zig build distribution-boundary: status=0
```

Logs use the `tmp/*_icmp_slt_i128.log` suffix, with the exact retry at
`tmp/muloti4_icmp_slt_i128_retry.log`. Report-all and ratchets do not move.
