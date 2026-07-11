# x86_64 Signed I128 Multiply-Overflow Expansion

schema_version: 1
z_llvm_base_commit: `243af5cc`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
change: `inline llvm.smul.with.overflow.i128 expansion`
result: `advanced`

The composed selector now lowers the exact signed i128 multiply-overflow
intrinsic without a nominal helper template. The implementation maps LLVM
`DAGTypeLegalizer::ExpandIntRes_XMULO` (`LegalizeIntegerTypes.cpp`, dispatch at
3181 and expansion at 5175) onto the local machine model:

- four unsigned 64-by-64 full products form the 256-bit schoolbook product;
- `adcq $0, %rax` propagates cross-product carries through the upper limbs;
- negative operands subtract the opposite 128-bit operand from the upper half,
  converting the unsigned schoolbook result to the signed 256-bit result;
- overflow is true exactly when the upper i128 differs from the sign extension
  of the low i128.

Every partial product is an allocator-visible fixed-definition result that is
immediately bound to an ordinary pair spill. Both operands, the caller's live
pointer, the low product, and the overflow flag remain authoritative in the
single value-location map.

Executable unit and permanent-canary cases cover non-overflowing and
overflowing products in positive and negative sign directions, checking both
the low product and overflow flag. The exact captured `__muloti4` retry
advances from `composed-block-call-form` to `composed-block-icmp-form`.

Tier 3 was required because intrinsic-specific frame reservation and spill
allocation changed.

```text
zig build test: status=0
zig build distribution-zig-integrated-exe: status=0 rows=5
zig build distribution-all: status=0 subgates=17 local_fail=0
strict real rows: ReleaseFast=100 ReleaseSafe=100 ReleaseSmall=100
focused __muloti4: no_emitter/composed-block-icmp-form
```

Logs:

- `tmp/zig_integrated_exe_smul_i128_expansion.log`
- `tmp/muloti4_inline_expansion_retry.log`
- `tmp/distribution_all_after_smul_i128_expansion.log`

Report-all remains 443 selected, 136 emitted, and 307 failed. No tracker or
ratchet moves in this advancing slice.
