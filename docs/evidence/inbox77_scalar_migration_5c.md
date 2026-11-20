# INBOX-77 scalar-arithmetic migration (slice 5C)

Date: 2026-07-15

## Scope and freeze

Slice 5C migrates scalar accumulator-producing arithmetic and the admitted
arithmetic call form through `AccumulatorDefinitionTransaction` and the 5A
emission-time EFLAGS authority.  Compare producers remain the accepted 5B
implementation; `urem`'s RDX result, full-product RAX/RDX, pair-result
arithmetic, and anything requiring new authority remain excluded.

The enumerate-first reconstruction was frozen before repair at commit
`8156c1e91c562bdb5a26e63a18c5f5e4738561bd`, tree
`9931dd8990b09b4f470cff758d54fb80b006452a`, based on accepted 5B
`f78eeed4`.  Its input was the preserved patch
`tmp/inbox74_intermixed_reslice_base.patch`, SHA-256
`bfc0a2a3fe25290d543077852213d3b0f1c962cc7eed131321c01bc42c06b888`.
The committed static inventory, accepted-IR occurrence table, and shadowed
dynamic 26-row failure inventory are:

- `inbox77_scalar_static_inventory.md`
- `inbox77_scalar_accepted_ir_occurrences.tsv`
- `inbox77_scalar_dynamic_inventory.md`

The unrepaired dynamic report was 443 selected / 259 emitted / 184 failed.
Every real first selector diagnostic was recovered through the existing
`lowerFunctionWithOptions` report plumbing; no temporary production
instrumentation was added.

## Structural repairs

The `and64-lhs`, `or64-lhs`, large `add64`/`xor64`, exact-EI binary/shift,
i52 shift, and `usub.sat.i64` seams share a typed preservation displacement.
It spills a current-use/live RAX occupant before destructive materialization
and reuses an expired accumulator-resident source.  This reproduces both the
accepted reload and no-reload streams and restores the fma and `__multi3`
canaries.

The enumerated direct EAX producers (i1 named/named, named variable shifts,
and quotient-producing `udiv`) reuse an accumulator-resident operand exactly
as their accepted materialization paths did.  Named i32 multiply performs
transaction preparation before RHS materialization, restoring the accepted
instruction order.  Focused regression tests preceded each repair on the
scratch branch.  The final repaired scratch commit/tree are
`b0873b5b087c9e0e54342ba0715a4345a311f6d2` /
`984457ba469e05158ea6d2a29cb09dfffb1e27f8`.

No ordinary form was deferred.  The residual direct-producer inventory is
limited to the predeclared exclusions; no new pair/RDX ownership, location
authority, allocator widening, CFG-aware EFLAGS/block-state authority, or
per-function special case was introduced.

## Final frozen-tree validation

- Full unit/source-guard suite: 1077/1077; ABI differential 60/60 cases and
  30/30 real functions.  Log `tmp/inbox77_unit_final.log`, SHA-256
  `7766d69f692b5e9490047fc1a0fe111c3fc664241a763a02db37f151c1aef579`.
- Standalone procedural focused canaries: `__multi3` 6 executable cases; fma
  29 executable cases, object/stream/symbol/helper identities exact, no
  host-libc substitution; total 35.  Log
  `tmp/inbox77_focused_canaries_final.log`, SHA-256
  `d704046eacfa8c3c2cf852ed97c86ab42b5a6a07dcfe4dd7de48cb870f2292c6`.
- Whole-capture report: exactly 443 selected / 285 emitted / 158 failed,
  first failure `compiler_rt.trunc.truncl` / `UnsupportedLongDoubleAbi`;
  SHA-256 `49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681`.
- Accepted aggregate object: byte-identical SHA-256
  `061a64e4241c92be1fafbdd9800f00cd3ac7bd1d2d3bef460d79ea1d5a32a0be`.
- Selection-owner manifest: byte-identical SHA-256
  `5d91960e5a01a0e6387f7ef2894dae4a1de93d2ce648c28377f97cd4afa0229d`;
  167 composed / 17 legacy / 101 fallback, zero unassigned.
- Standard integrated executable: 7/7.  Log
  `tmp/inbox77_integrated_exe_final.log`, SHA-256
  `9a6346f900be16fec9958d2cc4801832f5d8b52061959edf2c834e5c38d480dc`.
- Strengthened Tier 2: 28/28 steps, 1085/1085 tests.  Log
  `tmp/inbox77_tier2_final.log`, SHA-256
  `f2d616ff77440538e176fc96a0db8972def52206d2a9d1e1bc307c865b718847`.

Frozen identities are exact: `49a19f04` / `443-285-158-truncl` /
`061a64e4` / `5d91960e` / `167-17-101`.  No Tier 3 was run.  Stop for
Supervisor/Reviewer review before commit 6 or commit 7.
