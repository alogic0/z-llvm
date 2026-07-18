# INBOX-149 — O2 scalar Slice-3 refresh

Status: evidence only; dormant implementation is not authorized.

Date: 2026-07-18

This document refreshes the named-scalar and exact-i52 ownership boundary
after the immediate campaign and the O2 refactoring checkpoint. It changes no
production, test, guard, tool, build, facade, manifest, or ratchet file. No
Zig gate, performance command, or Tier 3 command was run.

## 1. Baseline and provenance

The last accepted semantic/capability change is the narrowed immediate
production wiring. The later checkpoint commits are pure production moves or
test-only splits and do not change the semantic baseline:

| Role | Commit | Tree | Meaning |
| --- | --- | --- | --- |
| semantic production | `41bdecf9fd2019b644174057f3f18ec9296eae63` | `2f4402a0c39431bb40a378b0ecec3571f667d9e3` | INBOX-143 immediate wiring; ratchet becomes 154 |
| semantic evidence | `01722543e2f312ed7055cd81dd5c342bdade7ac5` | `de8c19746c655c0de9e8e647114d725b97d446b5` | immutable INBOX-143 evidence |
| semantic acceptance | `45d8b517bfdf421ded38c63311d15535913bd36c` | `0f3e75e96fb52b47e2ab1eaba2ff4798ec811cbf` | Supervisor/Reviewer acceptance record |
| checkpoint production | `3beffdfbc361c6e22258086e3d4a4fcb2a31c22c` | `779772107f4c9ad8dbbdb000f6320f9a2db04786` | final planning-test split; test-only |
| checkpoint evidence | `8b20b6f1dba93a039bab9d9c10d1b7c24d2c0f57` | `2e60a5911f73db3cac93cfc2e423ec601c38d7af` | checkpoint gate evidence |
| checkpoint acceptance | `96af6a9e71e7a89f8e4fcec52d0366e40f3de4c1` | `24f88b3b7dffee3870764844ce420c2f7d20c573` | final checkpoint acceptance record |
| sequencing record | `4969e39ff4900a7dd4bd83032f3d2798de88f1c9` | `0e56e0de21fd8041c62e02926f44cf544f9bfe3a` | reviewed post-checkpoint ordering |
| this authorization | `b977751200433f74db1861aa1fee6753c18f1612` | `0da0e38b627a4fb1c004d10ca4df64041927cd04` | INBOX-149 only |

The accepted invariants remain:

```text
direct_materialization_ratchet=154
report=49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681
selected/emitted/failed=443/285/158
first_failure=compiler_rt.trunc.truncl/UnsupportedLongDoubleAbi
accepted_object=061a64e4241c92be1fafbdd9800f00cd3ac7bd1d2d3bef460d79ea1d5a32a0be
owner_manifest=5d91960e5a01a0e6387f7ef2894dae4a1de93d2ce648c28377f97cd4afa0229d
ledger=167/17/101
```

The identities are inherited from accepted evidence. This docs-only refresh
does not rerun them.

### 1.1 Exact refresh inputs

SHA-256 is over the exact file bytes at authorization tree `0da0e38b...`;
the line count is `wc -l`. These are every source, guard, manifest, ratchet,
and cohort input used below.

| Input | Lines | SHA-256 | Use |
| --- | ---: | --- | --- |
| `src/codegen/x86_64/generic_cfg/composed_selector_scalar.zig` | 1,195 | `1546fe4c600b4649ecd0aab8ee9c556e11feb70818e9d4b4ef49b0ad0e2d4c2c` | reachable gateways, legacy order, helpers, R03/R04 |
| `src/codegen/x86_64/generic_cfg/value_use/model.zig` | 1,513 | `b9c61b866fecb563795ae94be3eabfeb7d173e75b95cdf79325e430698b02ad8` | current semantic payload/tag boundary |
| `src/codegen/x86_64/generic_cfg/value_use/core.zig` | 1,154 | `613594a96d34b75df6277a05e727f0f98ee4795a05177bae3d30e6aeb1ca3fe8` | sole action dispatch and facade consumer |
| `src/codegen/x86_64/generic_cfg/value_use/composition.zig` | 277 | `bcecd26f7faef31621695b940db55bcc4060bf12476c1803404d13f3ec95e82c` | subordinate accumulator composition |
| `src/codegen/x86_64/generic_cfg/value_use/materialization.zig` | 1,395 | `76363aed186e1b0a7ac301d2fe2fa9847e0f75d4a5ebc4496d73b7de3c6e86d6` | closed prepared-home materialization |
| `src/codegen/x86_64/generic_cfg/value_use/actions/scalar_arithmetic.zig` | 17 | `d43c06c654fee7216d153fb8f6bedd53d8487cdff3fa33cee98ed13ed7d6c766` | stable scalar facade |
| `src/codegen/x86_64/generic_cfg/value_use/actions/scalar_cast.zig` | 414 | `d72c17b3460cf007b74cb8826c40784cc531751badc1f47afac3f09464be0c32` | accepted leaf/import precedent |
| `src/codegen/x86_64/generic_cfg/value_use/actions/scalar_immediate.zig` | 1,165 | `6bfaef0e50819371e164a53b21f19c30780ed11c4784a15dfeefbda9f297c68c` | accepted leaf/import and displacement precedent |
| `src/codegen/x86_64/generic_cfg/value_use/actions/scalar_arithmetic_tests.zig` | 4 | `00075c74bac51d2d78b74cbce5edd26a3428b571cad56a836c03019df15ca8cc` | stable scalar-test aggregator |
| `src/codegen/x86_64/generic_cfg/composed_selector_scalar_tests.zig` | 2,397 | `7cedc1451e8c4ab9c71114120ad97e25e90bbfbbb8f4a093205de151b839cf2e` | named-scalar production-faithful fixture names |
| `src/codegen/x86_64/generic_cfg/composed_selector_cfg_tests.zig` | 2,179 | `8a27c2d6ad56ddba6e6055136fbb7db3c68ca14b243e694741ff9fd2a8fb7901` | exact-i52 production-faithful fixture names |
| `src/codegen/x86_64/generic_cfg/source_guard/model.zig` | 555 | `41b2af473caa1d3958ddbe236ce3e6156eec2dc869ea4f8e87f29307b9994c69` | leaf and facade budgets |
| `src/codegen/x86_64/generic_cfg/source_guard/consumer_policy.zig` | 1,762 | `6f79ae69bab0a24b84077d56a2faa9292ea6c71ab2634ecb70971e7b898bad54` | R03/R04 production ownership guard |
| `src/codegen/x86_64/generic_cfg/source_guard/consumer_policy_tests.zig` | 670 | `9c86f6d0bdc8e9c7e703784fe098bc4b1678f05cdbd757959a6a426cec96cbde` | residual negative fixtures |
| `src/codegen/x86_64/generic_cfg/source_guard/authority_policy.zig` | 1,326 | `926c3166c2ae01837f805be662ba73c35a4833499b2382e608a948f25994e6b2` | displacement/lifetime authority guard |
| `src/codegen/x86_64/generic_cfg/source_guard/authority_policy_tests.zig` | 634 | `ddcef35ab740d3f73878cecb999c0659d7c5885cb7140ae9ecbf92ba1439954a` | plan-derived preservation negatives |
| `src/codegen/x86_64/generic_cfg/source_guard/split_policy.zig` | 617 | `f8002ac05d97b05bfe438cd04a9f2dc17a13ea56295b90dee368ba2247af6adb` | current import/facade boundaries |
| `src/codegen/x86_64/generic_cfg/source_guard/split_policy_tests.zig` | 334 | `894746f1b16e09e94de16c42eef531c374394ad5c36f2529057626b895c663b9` | split-policy negatives |
| `docs/evidence/inbox81_o2_resolution_materialization_bypasses.tsv` | 71 | `155f7be0d933df9516731265d4442c3ebbc1fb9ca4d5d6f3bacc2776aa936eb6` | frozen textual occurrence authority |
| `docs/evidence/inbox84_o2_bypass_classification.tsv` | 151 | `f7281a2a47da5ecc1ecdef8b9d4b96727d82be056bab823a17c28a19ef2d8e7c` | current classification and ratchet inputs |
| `docs/evidence/inbox77_scalar_accepted_ir_occurrences.tsv` | 90 | `14614c6c33a431be2b30a3de12e3f68cfa7295a3cd9e76ee6c1d7635f878336b` | exact accepted-row sets by width/op/form |
| `docs/evidence/inbox128_o2_r1_facade_manifest.tsv` | 108 | `68db09931f2916753f2fd257da06ee78ab7aac851efe855ab9b32e280b9e9966` | current public facade manifest |
| `docs/evidence/inbox130_o2_scalar_enumeration.md` | 349 | `0929a1451cf349aa16625c617e6fd72ec53a8921add4704efe2e758a7ed6ee89` | old 153-based proposal being corrected |
| `docs/evidence/inbox140_o2_immediate_family_partition.md` | 334 | `36b10d32ef9e32165c454a3da4a7819c724f91d3e8ad9ea1f0f6aa7a24a89cf7` | R03/R04 occurrence and canary counts |
| `docs/evidence/inbox142_o2_family_isolation_matrix.md` | 332 | `56423ad43e8b0232a45d293a44d1a7fe705bd62606f0d7cd8d69a587f6ccccba` | R03/R04 first-divergence evidence and matrix discipline |
| `docs/evidence/inbox143_o2_final_narrowed_wiring.summary` | 221 | `a2114ff94f352795b2fb41202810cf1f3208536b3d37968942988232bbc3ca8c` | accepted ratchet 154 and residual dispatch |
| `tmp/inbox63_accepted_cohort.ll` | 103,185 | `d8da86cae494d7d4a58053ab24b1e8be944859263072b85ffa164880b0110cd4` | complete cohort IR |

The accepted-row appendix's last column is the exact comma-separated
function-identity set for each `(width, op, lhs-kind, rhs-kind)` key.
References to a key below therefore name exact rows, not an approximate
family. A function may occur in several keys and may contain multiple
occurrences of one key. Since lowering is fail-fast, later occurrences in a
function are shadowed until every earlier producer succeeds.

## 2. Canonical forms and notation

- `N32` is a named integer of semantic width at most 32. Its canonical
  accepted homes are `arg32`, `scratch32`, `eax`, or `spill64`; its binding
  is `gpr32`, or an audited `gpr64` binding whose defined low bits cover the
  semantic width. Machine staging uses a 32-bit low view and EAX defines a
  zero-extended physical RAX.
- `N64` is a named i64 or an admitted exact-EI i33–i63 value. Its canonical
  homes are `arg64`, `scratch64`, `rax`, or `spill64`; its binding is
  `gpr64`, physical width 64, with the logical exact-EI width retained.
- Every Slice-3 operand is named. Literals and pair-result i128 forms remain
  outside this slice. Signed interpretation is relevant only to `ashr`;
  add/sub/mul, bitwise operations, `shl`, and `lshr` use their ordinary
  bit-vector semantics. LLVM `nuw`, `nsw`, and `exact` do not create a new
  machine carry/overflow consumer in these branches.
- Every emitted arithmetic instruction goes through
  `emitArithmeticWrite(..., .write)`. That is an incidental EFLAGS write,
  never a `.definition` or `.use`. A zero-count shift emits neither an
  instruction nor a record.
- All EAX/RAX results are currently durable
  `AccumulatorDefinitionTransaction` definitions. A future O2 action must
  use one outer `ValueUseTransaction`, one snapshot, and one subordinate
  accumulator session, with durable `ownActionIdentity` ownership before
  definition and only the outer commit.

## 3. Refreshed family inventory

The accepted source anchors are
`composed_selector_scalar.zig:75-235` for `lowerBinary` and
`:993-1096` for `lowerI52Binary`. The direct counts below are static
occurrences in the frozen bypass inventory, not dynamic executions.

### B01 — named i1 `and`/`or`

- **IR/admission:** `and` or `or`, i1, named lhs and named rhs; both are
  `N32` semantic i1 values. Any literal is rejected before source work.
- **Ownership/order:** register both named uses. Legacy order is
  rhs→RCX, begin/prepare the accumulator result, lhs→EAX, binary, define
  `.zeroExtending(1)`, finalize. The rhs staging is the first destructive
  write. Same-source requests may require RCX and EAX.
- **Displacement:** the **direct-materialization form table**, currently
  `accumulatorDirectMaterializationDisplacement(lhs, .spill_live)`.
- **EFLAGS:** exactly one incidental `.write` for the binary.
- **Diagnostics/provenance:** missing result → non-int/width/form → rhs
  request failure → preparation authority failure → lhs request failure.
  Only the matching request may own a future mapped diagnostic.
- **Cohort:** exact appendix keys `1/and/named/named` (7 rows) and
  `1/or/named/named` (14 rows). The seven `and` rows are `exp2.exp2`,
  `limb64.__mulo_limb64`, `log10.log10`, `log2.log2`,
  `mulo.__mulodi4`, `mulo.__muloti4`, and `mulsc3.__mulsc3`; the 14-row
  `or` set is frozen verbatim in the appendix.
- **Ratchet:** one `lowerBinary/emitValueIntoScratch` occurrence.

### B03 — named narrow multiply

- **IR/admission:** named/named `mul` at i6, i7, i16, i32, or the already
  admitted exact-EI i3/i4/i5/i13/i14/i26/i27 widths; both are `N32`.
  i64 multiply remains the later multiply slice, and pair results remain
  excluded.
- **Ownership/order:** begin the accumulator authority and prepare lhs
  **before** rhs staging; rhs→RCX; lhs→EAX; `imul`; typed definition and
  finalization. A preservation emitted by preparation is the first possible
  mutation; otherwise rhs staging is first.
- **Displacement:** **liveness-aware arithmetic displacement** with
  `scratch_preferred`, exactly the current
  `accumulatorArithmeticDisplacement` authority.
- **EFLAGS:** `imul` records one incidental `.write`.
- **Diagnostics/provenance:** width/form → preparation/authority → rhs
  request → lhs materialization. A future action must not move rhs
  validation before the accepted preparation point.
- **Cohort:** appendix key `32/mul/named/named` is the exact nine-row set
  (`divsf3`, `int.__divmodsi4`, `int.__modsi3`,
  `int.__udivmoddi4`, `int.__udivmodsi4`, `int.__umodsi4`,
  `mulXi3.__muldi3`, `rem_pio2_large`, `sqrtf`); admitted narrow forms are
  covered structurally and may be shadowed behind earlier producers.
- **Ratchet:** one `lowerBinary/emitValueIntoScratch` occurrence.

### B04 — named narrow variable shifts

- **IR/admission:** named/named `shl`, `lshr`, or `ashr` at i16, i32, or
  admitted exact-EI widths below 32. Both uses are `N32`.
- **Ownership/order:** rhs→RCX; begin/prepare; lhs→EAX; shift by CL; typed
  result definition/finalization. RHS staging is the first write.
- **Displacement:** the **direct-materialization form table**, currently
  `accumulatorDirectMaterializationDisplacement(lhs, .spill_live)`.
- **EFLAGS:** one incidental `.write` for the chosen shift.
- **Diagnostics/provenance:** form → rhs request → preparation authority →
  lhs request. Exact-EI admission and its dispatch position are unchanged.
- **Cohort:** exact appendix keys are
  `13/shl`, `14/shl`, `16/{ashr,lshr,shl}`,
  `26/shl`, `27/shl`, and `32/{ashr,lshr,shl}`, all named/named.
  Their frozen distinct-row counts are 1, 1, 2/40/9, 1, 1, and 9/63/42.
- **Ratchet:** one `lowerBinary/emitValueIntoScratch` occurrence.

### B05 — named wide and exact-EI variable shifts

- **IR/admission:** named/named `shl`, `lshr`, or `ashr` at i64 or admitted
  exact-EI i55/i56; both are `N64`.
- **Ownership/order:** rhs→RCX64; begin/prepare; lhs→RAX; shift by CL;
  define `.fullRax()` for i64 or `.zeroExtendedRax(bits)` for exact-EI;
  finalize. RHS staging is first.
- **Displacement:** the **preserve-current table**, currently
  `accumulatorPreserveCurrentDisplacement(lhs, .spill_live)`.
- **EFLAGS:** one incidental `.write`.
- **Diagnostics/provenance:** rhs (`ei-shift-rhs` on exact-EI) →
  preparation → lhs (`ei-shift-lhs`). No caller-selected preservation home.
- **Cohort:** appendix keys `55/shl`, `56/{lshr,shl}`, and
  `64/{ashr,lshr,shl}`, all named/named, with frozen row counts
  1, 2/1, and 19/85/60.
- **Ratchet:** one `lowerBinary/emitValueIntoScratch` occurrence.

### B06 — named exact-EI wide non-shift

- **IR/admission:** admitted exact-EI i55/i56 named/named non-shift
  operations accepted by `machineBinaryOp`; current accepted cohort keys are
  `55/or/named/named` and `56/or/named/named`. Both uses are `N64`.
- **Ownership/order:** derive op; rhs→RCX64; begin/prepare; lhs→RAX; binary;
  logical-width definition and finalization. RHS staging is first.
- **Displacement:** the **preserve-current table**.
- **EFLAGS:** one incidental `.write`.
- **Diagnostics/provenance:** unsupported op → rhs
  `composed-block-ei-binary-rhs` → preparation → lhs
  `composed-block-ei-binary-lhs`.
- **Cohort:** exact rows are `floatuneidf.__floatuneidf` for i55 and
  `floateidf.__floateidf` for i56.
- **Ratchet:** one `lowerBinary/emitValueIntoScratch` occurrence.

### B07 — general named scalar binary

- **IR/admission:** named/named machine binary after the i52, immediate,
  pair, i64-multiply, udiv/urem, narrow-multiply, and specialized shift/
  exact-EI dispatches. Accepted semantic widths are i3/i4/i5/i6/i7/i13/
  i14/i16/i26/i27/i32 and i64 as admitted by the existing
  width/exact-EI gate;
  operands are matching `N32` or `N64`. The i55/i56 forms have already
  returned through B05/B06. No immediate or pair form enters.
- **Ownership/order:** first run the accepted live-accumulator loop, then
  preserve a live named lhs, then resolve lhs **before** rhs. The closed
  home branches are:
  1. both accumulator: stage rhs→RCX; relocate only when logical names
     differ; prepare/materialize lhs; emit;
  2. rhs accumulator, commutative: prepare/materialize rhs and consume a
     canonically re-resolved lhs from its current home;
  3. rhs accumulator, ordered: stage rhs→RCX or RDX selected from the lhs
     home; prepare/materialize lhs; emit;
  4. neither accumulator: prepare/materialize lhs; canonically re-resolve
     rhs; use its GPR home or reload a spill→RCX; emit.
  The first destructive write is the preamble when it preserves, otherwise
  the branch's rhs staging or accumulator preparation. No prepared home may
  cross a preservation mutation.
- **Displacement:** **liveness-aware arithmetic displacement**, always the
  current `accumulatorArithmeticDisplacement` call with the branch's
  `spill_live` fallback.
- **EFLAGS:** the final machine binary records one incidental `.write`.
- **Diagnostics/provenance:** preamble authority → unresolved lhs →
  unresolved rhs → branch-specific staging/width/home → preparation and
  post-prepare canonical resolution in the accepted order. Future mapping
  is request-specific; authority errors remain unattributed.
- **Cohort:** the exact row sets are every accepted appendix key
  `(width, op, named, named)` not assigned above or to an exclusion, for
  `add/and/or/sub/xor` at widths 3, 4, 5, 6, 7, 13, 14, 16, 26, 27, 32,
  and 64.
  The largest frozen sets are i32 add/and/or/sub/xor
  84/84/40/27/38 and i64 add/and/or/sub/xor 74/84/58/45/31. The appendix
  names every function exactly. Multiple forms in one function are
  shadowable and must all be compared in family isolation.
- **Ratchet:** eight occurrences:
  `resolveValue×4`, `emitValueIntoScratch×2`,
  `emitValueIntoScratchAndRelocate×1`, and
  `emitBinaryLocIntoAccumulator×1`.

### I52B0 — exact i52 guarded shift

- **IR/admission:** only `shl i52 <named>, <named>` whose rhs is structurally
  the exact `llvm.ctlz.i52` → trunc i6 → `nuw add 1` → zext i52 envelope.
  Both operands are `N64` bindings with logical width 52 and physical width
  64. The classifier examines IR structure, never a function name.
- **Ownership/order:** begin/prepare lhs first; rhs→RCX64; lhs→RAX; SHL;
  materialize `(1<<52)-1` in RCX; AND RAX,RCX; define
  `.zeroExtendedRax(52)` and finalize. Preparation is the first possible
  mutation.
- **Displacement:** the **preserve-current table**.
- **EFLAGS:** SHL is one incidental `.write`; AND is a second incidental
  `.write`. The mask materialization does not write flags.
- **Diagnostics/provenance:** missing function/provenance →
  structural-form rejection → preparation authority → rhs
  `composed-block-i52-shift-rhs` → lhs
  `composed-block-i52-shift-lhs`.
- **Cohort:** exact row `compiler_rt.fma.fma`; three textual envelope/shift
  occurrences within the row are shadowable behind the first failure.
- **Ratchet:** one `lowerI52Binary/emitValueIntoScratch` occurrence.

### 3.1 Retained exclusions

The following remain outside Slice 3 and contribute zero credit:

- i128 pair-result `lowerPairBinary` branches, their pair allocation/
  ownership, and carry-chain subtraction;
- i64 multiply and spill-through-RAX, reserved for the multiply slice;
- quotient and RDX remainder paths, reserved for fixed-register division;
- all immediate forms, including the frozen R03/R04 residuals;
- non-integer, unsupported-width, unsupported-op, literal, missing-result,
  and missing-provenance tails.

If a proposed complete family requires pair authority, fixed-register/RDX
authority, new cycle resolution, or either R03/R04 preservation semantic, the
entire family stays legacy and receives zero ratchet credit.

## 4. R03 and R04 are frozen complete residual owners

The accepted source makes both decisions before constructing the migrated
immediate action:

```text
composed_selector_scalar.zig:386-390  R03 pure classifier
composed_selector_scalar.zig:393-423  R03 legacy owner
composed_selector_scalar.zig:425-433  R04 pure classifier
composed_selector_scalar.zig:435-492  R04 legacy owner
composed_selector_scalar.zig:494-505  R03 -> R04 -> migrated-action dispatch
```

### R03 — `scalar_immediate_live_shared_source_preservation`

- Owns every named-lhs, immediate-rhs `ashr` with nonzero width at most 32
  or width 64. It opens no `ValueUseTransaction`.
- The narrow branch owns one live-accumulator loop, one
  `AccumulatorDefinitionTransaction`, and one
  `accumulatorArithmeticDisplacement(..., .spill_live)` call. The i64
  branch owns the one counted `emitValueIntoScratch`, the RCX shift, durable
  scratch binding, and spill.
- The frozen occurrence projection is 58 semantic occurrences in 36 cohort
  functions, two unit family cases, and two canary-manifest occurrences.
  The exact accepted divergence is `compiler_rt.exp2.exp2`,
  `%11 = ashr i32 %10, 8`: legacy preserves live `%10` in EDI; the retired
  transaction path spilled/reloaded it and moved downstream branches. The
  current owner name supersedes the older descriptive
  `scalar_immediate_ashr_live_source_home_preservation` wording.
- Static ratchet ownership is one
  `scalar_immediate_live_shared_source_preservation/emitValueIntoScratch`
  occurrence. It also retains one owner of
  `accumulatorArithmeticDisplacement`.

### R04 — `scalar_immediate_multi_alias_preservation`

- Owns every named-lhs, immediate-rhs `and/or/add/sub/xor` with nonzero
  width at most 32. It opens no `ValueUseTransaction`.
- It owns the live-accumulator loop and five explicit legacy
  `AccumulatorDefinitionTransaction` branches. Those branches retain five
  `accumulatorArithmeticDisplacement(..., .scratch_preferred)` calls.
- The frozen occurrence projection is 1,432 semantic occurrences in 256
  cohort functions, three unit family cases, and 26 canary-manifest
  occurrences. The exact canary divergence is `compiler_rt.fma.fma`,
  `%32 = add nuw i6 %31, 1`: legacy assigns the live i6 `%31` and i52
  `%30` aliases distinct EDI and RSI homes; preserve-once transaction
  behavior did not.
- R04 owns zero counted textual gateway occurrences but remains a semantic
  legacy owner. Its zero delta is not permission to absorb it into another
  action.

The source guard enforces this ownership at
`source_guard/consumer_policy.zig:124-280`: pure state-free classifier
shapes, exact R03-before-R04-before-action order, no transactional
attempt/fallback, the one R03 transaction/helper/staging topology, and the
five R04 transaction/helper branches. Production-site confinement continues
at `:282-315`. Negative fixtures are
`consumer_policy_tests.zig:460-651`; plan-derived preservation is separately
frozen by `authority_policy_tests.zig:606-634`.

No Slice-3 action, classifier, helper move, or ratchet claim may change these
anchors. R03 and R04 remain under these exact named future owners until the
post-calls residual audit.

## 5. Closed displacement authorities

Each candidate family has exactly one approved authority:

| Family | Sole authority | Frozen meaning |
| --- | --- | --- |
| B01 | direct-materialization form table | reuse named EAX/RAX source; otherwise `spill_live` |
| B03 | liveness-aware arithmetic displacement | strict `valueIsLiveAfterCurrent`; dead source may reuse, live source uses `scratch_preferred` |
| B04 | direct-materialization form table | source-home-derived reuse or `spill_live`; no liveness query |
| B05 | preserve-current table | inclusive current accumulator preservation, otherwise named-source reuse or `spill_live` |
| B06 | preserve-current table | identical accepted table, no per-op override |
| B07 | liveness-aware arithmetic displacement | strict-after named-source reuse with branch-owned `spill_live` fallback |
| I52B0 | preserve-current table | inclusive current accumulator preservation with `spill_live` fallback |

The fourth reviewed category, an **explicitly hardcoded plan**, has no
Slice-3 member. It must remain empty rather than becoming a catch-all.

These choices are closed. A future action may not select a preservation home,
assign per-alias homes, add a consumer hint, inspect a function name, fall
back at runtime, or switch authority from observed source topology. If one
occurrence of a complete family cannot reproduce its accepted stream under
the table above, that family is retained wholesale.

## 6. Honest ratchet arithmetic from 154

The frozen textual occurrences reconcile independently of helper ownership:

| Family | Counted operation | Direct removal if the complete family lands |
| --- | --- | ---: |
| B01 | `lowerBinary/emitValueIntoScratch` | 1 |
| B03 | `lowerBinary/emitValueIntoScratch` | 1 |
| B04 | `lowerBinary/emitValueIntoScratch` | 1 |
| B05 | `lowerBinary/emitValueIntoScratch` | 1 |
| B06 | `lowerBinary/emitValueIntoScratch` | 1 |
| B07 | `resolveValue×4 + emitValueIntoScratch×2 + emitValueIntoScratchAndRelocate + emitBinaryLocIntoAccumulator` | 8 |
| I52B0 | `lowerI52Binary/emitValueIntoScratch` | 1 |
| **conditional direct total** |  | **14** |

There is one potential helper claim:

| Helper | Current complete owner inventory | Last-owner collapse credit |
| --- | --- | ---: |
| `accumulatorArithmeticDisplacement/resolveValue×1` | B03 call at scalar source line 113; B07 calls at 183, 191, 205, 213; R03 call at 407; R04 calls at 449, 457, 465, 474, 483 | **0** |

R03 and R04 are frozen legacy owners, so the helper cannot be removed by
Slice 3. The prior 153-based `-14 direct -1 helper = 138` proposal is
superseded twice: the accepted starting ratchet is 154, and the helper is not
a last-owner collapse.

The only honest conditional all-family target is therefore:

```text
154 - 14 accepted direct removals - 0 proven last-owner collapses = 140
```

This is not an authorized production target. Family isolation may reduce the
accepted direct-removal set. For any retained family `F`, its whole direct
credit is zero and the future target is recomputed as:

```text
154 - sum(direct removals of individually and compositionally accepted
          complete families) - 0
```

No semantic-only transition, R03/R04 ownership, dispatcher rewrite, or
shared-helper partial ownership changes that arithmetic.

## 7. Required family-isolation and aggregate procedure

Before production wiring, a reviewed isolation slice must freeze immutable
baseline artifacts from the accepted tree and make one temporary build per
complete candidate family: B01, B03, B04, B05, B06, B07, and I52B0. In each
build exactly that family is wired; every other candidate, every exclusion,
R03, and R04 remains on the accepted legacy path.

For each build, retain and compare:

1. the complete 443-row report and filtered 285/158 projections;
2. the complete owner manifest and ledger;
3. the whole accepted object;
4. every emitted function's symbol bytes and normalized disassembly;
5. the first semantic instruction change, separately from earlier
   branch-displacement or later stack-offset drift;
6. source, object, manifest, report, per-symbol, and disassembly hashes.

A family with any divergent cohort occurrence is retained wholesale and gets
zero ratchet credit. Full report/object equality is necessary but does not
replace the per-function comparison.

The aggregate build contains only all individually identical families. If it
diverges, isolate the minimal interacting set by deterministic subset
cardinality: test complete-family subsets of size two, then three, and so on,
in lexical family order until the first minimal divergent sets are frozen.
Never split a family or select functions/rows/homes. Attribute the root at
the first semantic producer; branch-offset-only movement is downstream. Any
interaction without clean attribution returns for review.

### 7.1 Production-faithful fixtures

Every fixture uses a real `SelectorAllocationPlan`, real interval endpoints,
real bindings, and the canonical dependency domain. No max-int interval or
test-only liveness bypass is admissible.

| Family | Exact fixture set to freeze before isolation |
| --- | --- |
| B01 | named i1 same-source EAX/RCX multi-destination; distinct arg/spill operands; rhs failure before lhs; rollback after rhs staging |
| B03 | existing `named i32 multiply preserves the accepted accumulator-before-rhs order`; exact-EI narrow control; live/dead lhs intervals; rollback after preparation and rhs stage |
| B04 | existing `generic cfg selector lowers variable i16 shifts` and `accumulator-resident named i32 shift keeps accepted direct materialization stream`; same-source shift operands; spill rhs |
| B05 | existing `generic cfg selector exact ei binary and shift reuse a dead accumulator lhs`, `exact ei shift preserves the accepted current-use accumulator rhs spill`, and `generic cfg selector shl64 spills live rax source before destructive shift`; i55/i56/i64 homes |
| B06 | exact i55/i56 named `or` in RAX, GPR, and spill homes; current-use preservation; post-prepare re-resolution |
| B07 | existing `generic cfg selector reloads 32-bit spill rhs for binary accumulator op`; both-accumulator same and distinct aliases; commutative rhs-accumulator; ordered rhs-accumulator; neither-accumulator GPR/spill; live-lhs and live-unrelated-alias preambles |
| I52B0 | existing `composed selector executes guarded i52 normalization family` and `composed selector keeps excluded i52 forms fail closed`; real `fma.fma` envelope; failures after preparation, rhs staging, SHL, mask, and definition |

Focused fma, `__multi3`, and exp2 streams are supplemental collateral checks.
They never replace the full-cohort family matrix or aggregate interaction
build.

## 8. Frozen future `scalar_named.zig` boundary

This section freezes the proposed boundary for a later dormant review. It
does not create a file or authorize any API addition.

### 8.1 Central model additions

`value_use/model.zig` remains the sole owner of these exact proposed types:

```zig
pub const NamedScalarBinaryAction = struct {
    result: ActionIdentity,
    operation: ir.BinaryOp,
    integer_ty: ir.Type,
    exact_ei: bool,
    rhs: RequestHandle,
};

pub const ExactI52BinaryAction = struct {
    result: ActionIdentity,
    rhs: RequestHandle,
};

pub const NamedScalarRequestError = error{
    ValueUseNamedScalarFormUnsupported,
    ValueUseNamedScalarWidthUnsupported,
    ValueUseNamedScalarLocationUnsupported,
    ValueUseNamedScalarScratchUnavailable,
    ValueUseNamedScalarExactEiUnsupported,
    ValueUseNamedScalarI52EnvelopeUnsupported,
};

pub const NamedScalarTestFailure = enum {
    after_preamble,
    after_canonical_refresh,
    after_first_operand_staging,
    after_accumulator_preparation,
    after_second_operand_staging,
    after_first_arithmetic_write,
    after_second_arithmetic_write,
    after_result_identity_ownership,
    after_result_definition,
    after_finalization,
};
```

The exact proposed `UseForm` addition is
`named_scalar_operand`. The exact `PreparedAction` additions, in dispatch
order, are `named_scalar_binary: NamedScalarBinaryAction` and
`exact_i52_binary: ExactI52BinaryAction`. There is no literal, pair-result,
physical-register, home, displacement, preservation, or sequencing field.
`exact_ei` carries only the already established semantic admission result;
it is not a home or phase hint.

The transaction surface would add only the two action-attachment methods
needed to preserve named-source registration order:

```text
attachNamedScalarBinaryAction(RequestHandle, NamedScalarBinaryAction) !void
attachExactI52BinaryAction(RequestHandle, ExactI52BinaryAction) !void
```

No prepared location is exposed.

### 8.2 Leaf declarations and facade budget

`value_use/actions/scalar_named.zig` would own exactly these six technically
public declarations:

```text
isNamedScalarBinary(ir.BinaryInst, bool) bool
isExactI52Binary(?*const ir.Function, ir.BinaryInst) bool
validateNamedScalarBinaryAction(*const NamedScalarBinaryAction) !void
validateExactI52BinaryAction(*const ExactI52BinaryAction) !void
executeNamedScalarBinary(comptime Authority: type, anytype, u8, *const PreparedView, *const NamedScalarBinaryAction) !void
executeExactI52Binary(comptime Authority: type, anytype, u8, *const PreparedView, *const ExactI52BinaryAction) !void
```

Private declarations are limited to the closed B01/B03-B07 plan enum, the
closed I52 plan, structural i52 envelope walkers, canonical-home
classification, diagnostic helpers, and the `NamedScalarTestFailure`
injection hook. They are not facade exports.

`scalar_arithmetic.zig` remains a forwarding-only facade. Its exact
expansion is one import plus these six aliases:

```zig
const scalar_named = @import("scalar_named.zig");
pub const executeExactI52Binary = scalar_named.executeExactI52Binary;
pub const executeNamedScalarBinary = scalar_named.executeNamedScalarBinary;
pub const isExactI52Binary = scalar_named.isExactI52Binary;
pub const isNamedScalarBinary = scalar_named.isNamedScalarBinary;
pub const validateExactI52BinaryAction = scalar_named.validateExactI52BinaryAction;
pub const validateNamedScalarBinaryAction = scalar_named.validateNamedScalarBinaryAction;
```

Thus the scalar facade budget changes from exactly 14 to exactly 20 names
and its projected physical size is 24 lines. The source guard must freeze:
the six-name leaf budget, the twenty-name facade budget, two exact core
dispatch uses per action (validation and execution), the two exact
attachment methods, and facade-only production imports. There is no
open-ended re-export allowance.

### 8.3 Import graph and size budget

The accepted graph for the proposed leaf is:

```text
core.zig
  -> actions/scalar_arithmetic.zig
       -> actions/scalar_cast.zig
       -> actions/scalar_immediate.zig
       -> actions/scalar_named.zig

actions/scalar_named.zig
  -> value_use/model.zig
  -> value_use/composition.zig
  -> value_use/materialization.zig
  -> foundational ir/machine/type/state type declarations already used by
     reviewed action leaves
```

`scalar_named.zig` must not import `planning.zig`, any planning leaf, or
`core.zig`; no reverse action→planning edge is allowed. `core.zig` continues
to import only `scalar_arithmetic.zig`, never `scalar_named.zig` directly.
Semantic payloads stay in `model.zig`, and sole exhaustive validation/
execution dispatch stays in `core.zig`.

Projected production size is 850–1,200 lines. The co-located
`scalar_named_tests.zig` projection is 1,000–1,450 lines and is imported by
the stable `scalar_arithmetic_tests.zig` aggregator. Both targets are below
the preferred 1,500-line limit; either reaching 2,000 lines is a mandatory
review stop. No private declaration may be exported merely for testing.

## 9. Future reviewed sequence and stop

Only this future sequence is frozen:

1. dormant complete-family actions and focused production-faithful tests;
2. family-isolation matrix plus aggregate/minimal-interaction review;
3. production wiring of only accepted complete families with an honestly
   recomputed ratchet;
4. post-final-tree immutable counterbalanced performance evidence.

Each is a separate review stop. This document authorizes none of them. It
does not design R03 or R04, refactor code, or move any residual owner.

INBOX-149 leaves the ratchet at exactly 154. `stash@{0}` and all preserved
patches remain untouched.
