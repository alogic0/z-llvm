# x86_64 I128 Minimum Equality Comparison

schema_version: 1
z_llvm_base_commit: `0bc794ab`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
change: `icmp eq i128 value, INT128_MIN`
result: `advanced`

The composed selector now lowers equality with the i128 minimum constant by
XORing the high limb with `INT64_MIN`, ORing the low limb, and testing the
combined difference for zero. Pair materialization keeps register, stack-value,
and spill sources on one path. Permanent executable cases cover the exact
minimum and the adjacent value.

The exact `__muloti4` retry advances from `stage2-icmp-value` to
`no_emitter/composed-block-binary-width` on its `and i1` guard.

Tier 2 is green across unit, structural, 38 ReleaseFast object rows, 9
ReleaseSafe rows, the 5-row permanent executable suite, and boundary gates.
Logs use the `tmp/*_icmp_eq_min_i128.log` suffix. Report-all and ratchets do
not move.
