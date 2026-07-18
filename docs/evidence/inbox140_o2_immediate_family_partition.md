# INBOX-140 — immediate closed-plan family partition

Status: evidence-only partition for review. No production, action, test,
guard, tool, build, or inventory source is changed by this slice.

## Frozen basis and counting method

```text
accepted_durable_key_commit=de3cb6f980369534932488502424370aecf82486
working_head_with_supervisor_docs=f9604e13f5b037f233bac2c7a752ff96faa3936c
working_head_tree=227e323d7d35828b3bc77d279a66f44b44ac9e2d
current_ratchet=166
retired_B5_carrier=tmp/inbox135_immediate_wiring/inbox135_b3_hard_stop.patch
retired_B5_carrier_sha256=3f3e46ff0fd9b92a40287840716853c1dda70a3f90220107d3301598051f035d
preserved_B5_stopped_state=tmp/inbox138_o2_immediate_wiring_final/inbox138_b5_canary_hard_stop.patch
preserved_B5_stopped_state_sha256=1fb434f2e2209d7af2caae5b865d334fd635207bace49fc143a68db7e5c1bf05
stash_at_0=7985c6d01040a6e47e4ce5b918866d0e89517ac7 (untouched)
```

The retired carrier was not reapplied. Byte comparisons below use its
already-preserved accepted and wired streams:

```text
accepted_fma_stream_sha256=cc791b46ef93f564040e5245874216a7aa267df7319e84135862177f4eff776a
retired_B5_fma_stream_sha256=0eaed5c57bf54dd1d02107403856af347cdb13b25ec63def693a1792ea3361c3
accepted_fma_object_sha256=b8b720e69b6b32d427cd1633ef8b76f663f9933300cca291feefc560ce994b2f
retired_B5_fma_object_sha256=d369a7a4d939c767e53eafb336592fd45b505fdb3f623455450a34bfb671e835
```

The cohort and canary counts are the exact semantic-occurrence projections
from INBOX-136. They preserve multiplicity rather than merely counting
functions:

```text
cohort_occurrence_projection_sha256=7f434896345b71565ba479d01ddfa92b4713ae8a1632c187323b1feb84218f21
canary_occurrence_projection_sha256=06015458cd611951a858f0511cd7c5c31a833d54c5783d568fc5aba77772ce9c
cohort_total=4074 occurrences / 314 distinct functions
canary_total=104 occurrences
```

The unit count is an exact count of family-scoped cases in
`scalar_arithmetic_immediate_tests.zig`: successful action executions,
injected rollback executions, and family-specific request/registration
negatives each count once per loop iteration. It totals 50. The shared
1,260-cell type/class/home matrix and the ten classifier-only positives are
reported separately; neither is multiplied into the action-case count.
Legacy production-path unit anchors remain additional byte-stream evidence,
not double-counted action cases.

## Closed classifier partition

Every boundary below is pure IR semantics: operand kind, operation, integer
type/width, and inline literal only. None may inspect selector state, source
home, function identity, allocation plan, or alias topology.

| Family | Pure classifier boundary | Cohort occurrences / functions | Unit family cases | Canary occurrences |
|---|---|---:|---:|---:|
| R00 | RHS literal; named lhs; `sdiv i32`; literal exactly `2` | 5 / 5 | 4 | 0 |
| R01 | RHS literal; named lhs; `lshr`; width exactly 16, 32, or 64 | 519 / 191 | 5 | 19 |
| R02 | RHS literal; named lhs; `shl`; nonzero width at most 32, or width 64 | 247 / 111 | 6 | 6 |
| R03 | RHS literal; named lhs; `ashr`; nonzero width at most 32, or width 64 | 58 / 36 | 2 | 2 |
| R04 | RHS literal; named lhs; `and/or/add/sub/xor`; nonzero width at most 32 | 1,432 / 256 | 3 | 26 |
| R05 | RHS literal; named lhs; width 64; `and/or/xor`, or `add` whose literal does not fit i32 | 793 / 144 | 12 | 30 |
| R06 | RHS literal; named lhs; width 64; `add/sub` with an i32-encodable literal | 555 / 87 | 4 | 5 |
| L01 | LHS literal; named rhs; `sub`; nonzero width at most 32, or width 64 | 438 / 185 | 9 | 16 |
| L02 | LHS literal; named rhs; `shl`; width exactly 16 or 32 | 14 / 14 | 2 | 0 |
| L03 | LHS literal; named rhs; `lshr`; nonzero width at most 32, or width 64 | 13 / 12 | 3 | 0 |
| **Total** | ten disjoint closed plans | **4,074 / 314 distinct overall** | **50** | **104** |

The unit-case reconciliation is:

```text
R00=4 R01=5 R02=6 R03=2 R04=3
R05=12 R06=4 L01=9 L02=2 L03=3
total=50
```

The classifier table additionally tests every family once, rejects L00
(`sub i128 0, pair`) and every rhs-immediate i128 pair form, and freezes the
shared 6 declared types × 10 binding classes × 21 physical homes matrix.
Those are admission proofs rather than emitted plan occurrences.

The 104 canary occurrences reconcile independently:

```text
R00=0 R01=19 R02=6 R03=2 R04=26
R05=30 R06=5 L01=16 L02=0 L03=0
total=104
```

## Per-family ownership and disposition

### R00 — signed divide by two

- **Gateways and last owners:** no direct bypass-inventory occurrence. It
  already uses the accumulator transaction materializer. It does not own a
  helper collapse.
- **Accepted authority/topology:** RCX is clobbered first; the source uses
  strict-after Q2 with scratch-preferred fallback; the session materializes
  EAX and emits the accepted EAX→ECX, SHR, ADD, SAR sequence. There is no
  plan preamble. Existing accumulator aliases are displaced by the legacy
  session authority.
- **Frozen-model result:** the exact R00 unit stream and its rollback
  boundaries passed in the 1,325/1,325 B5 unit run. R00 has no focused
  canary occurrence and no B5 stream hunk was attributed to it.
- **Disposition:** **LAND as the complete R00 family** in the narrowed
  slice, subject to that slice's full cohort/object/owner and performance
  gates.

### R01 — logical shift right

- **Gateways and last owners:** owns two
  `lowerBinaryImmediateRhs/emitValueIntoScratch` occurrences: the 16/32-bit
  RCX path and the 64-bit chosen-scratch path. It is the sole owner of
  `tryLowerLshr64SpillThroughRax/resolveValue`; removing that helper is one
  separately proven last-owner collapse.
- **Accepted authority/topology:** sessionless planned/free/reusable scratch
  is preferred. A live reusable scratch source is spilled and reloaded in
  place; only the no-scratch fallback uses a subordinate RAX session with
  hard spill-live. The result may reuse the source scratch, but no
  per-logical-alias home fan-out is required.
- **Frozen-model result:** all source-choice unit streams passed. The
  focused and integrated `__multi3` bodies contain five R01 occurrences
  each; the focused `__multi3` stream completed its exact canary check
  before B5 reached fma. No R01 instruction hunk appears in the retained
  fma diff.
- **Disposition:** **LAND as the complete R01 family**, including the
  proven lshr-helper collapse.

### R02 — shift left

- **Gateways and last owners:** owns
  `lowerBinaryImmediateRhs/resolveValue` plus the paired
  `emitValueIntoEax` in the scratch32 write-back branch. No helper collapse.
- **Accepted authority/topology:** widths through 32 use strict-after Q2
  and scratch-preferred displacement; the scratch32 form stages through
  EAX and writes back to the original scratch. The i64 form uses inclusive
  preserve-current/spill-source. Canonical re-resolution follows any
  preservation.
- **Frozen-model result:** the scratch write-back, live-source spill,
  no-accumulator, malformed-domain, and rollback unit cases all passed.
  The focused `__multi3` R02 occurrence passed exact stream validation.
  No R02 hunk is present in the retained fma diff.
- **Disposition:** **LAND as the complete R02 family**.

### R03 — arithmetic shift right

- **Gateways and last owners:** owns the i64
  `lowerBinaryImmediateRhs/emitValueIntoScratch` occurrence. The narrow
  accumulator arm has no counted direct bypass and no helper collapse.
- **Accepted authority/topology:** the narrow arm uses strict-after Q2 with
  scratch-preferred displacement and an EAX session; the i64 arm is
  sessionless RCX scratch followed by the accepted durable spill. Neither
  arm needs multi-alias physical-home fan-out.
- **Frozen-model result:** both representative arms passed the B5 unit
  suite. Its two canary-manifest occurrences are integrated-i128 forms, not
  a separately reached focused-canary identity before the fma stop. No R03
  hunk appears in the retained B5 streams.
- **Disposition:** **LAND as the complete R03 family**, with the narrowed
  slice providing the decisive integrated/full-cohort proof.

### R04 — narrow immediate arithmetic

- **Gateways and last owners:** owns **zero** counted bypass-inventory
  occurrences and no helper collapse. Its existing branches already use
  the accumulator transaction materializer, so retaining it does not grant
  another family ownership of its semantics.
- **Accepted authority/topology:** strict-after Q2 with scratch-preferred
  displacement plus the legacy live-accumulator loop. The accepted fma
  shape has two logical values in the EAX/RAX physical domain that require
  distinct homes: the low i6 view `%31` moves to EDI while the live wide
  i52 value `%30` moves to RSI. This is per-alias home assignment, not
  preserve-once physical-source relocation.
- **Frozen-model result:** **DIVERGENT**. The first failing producer is
  `%32 = add nuw i6 %31, 1`. The retired B5 path emits one `movq %rax,%rdi`
  instead of the accepted `movl %eax,%edi` plus `movq %rax,%rsi`, changing
  the fma stream from `cc791b46…` to `0eaed5c5…` and recurring in all three
  frexp expansions. The selector report remains accepted and
  byte-identical; this is an ownership/stream divergence, not a diagnostic.
- **Disposition:** **RETAIN WHOLESALE on the legacy path** under future
  owner `scalar_immediate_multi_alias_preservation`. Every R04 form,
  including currently byte-identical cohort/unit/canary occurrences, must
  bypass O2 transaction construction by pure classifier dispatch. No
  transactional attempt followed by fallback is allowed.

### R05 — wide accumulator immediate arithmetic

- **Gateways and last owners:** owns no direct counted bypass occurrence and
  no helper collapse.
- **Accepted authority/topology:** inclusive preserve-current with
  spill-live fallback. The closed preamble spills the semantic RAX source
  when required, updates aliases to the one durable spill, re-resolves
  canonically, then emits the wide operation. This is intentionally
  different from R04's need for distinct per-alias homes.
- **Frozen-model result:** the real `__multi3` `%11`, no-alias,
  multiple-alias, malformed-alias, durable-key, and rollback units all
  passed. Four focused `__multi3` R05 occurrences passed exact stream
  validation. The fma aggregate diff begins at R04 and its later register
  substitutions inherit that changed R04 topology; no independent R05
  first divergence was observed.
- **Disposition:** **LAND as the complete R05 family**. The narrowed slice
  must still prove the restored fma identity with R04 never entering the
  transaction.

### R06 — wide scratch immediate arithmetic

- **Gateways and last owners:** owns two
  `lowerBinaryImmediateRhs/emitValueIntoScratch` occurrences: i32-encodable
  i64 add and sub. No helper collapse.
- **Accepted authority/topology:** sessionless RCX scratch result, with no
  destructive accumulator destination and therefore no accumulator-alias
  preamble. The durable result identity is transaction rollback-owned.
- **Frozen-model result:** representative, literal-range, durable-result,
  and rollback cases passed. The retained fma-main diff has no R06 hunk;
  its canary-manifest occurrences are helper bodies rather than a separate
  first divergence in B5.
- **Disposition:** **LAND as the complete R06 family**.

### L01 — reverse subtract

- **Gateways and last owners:** owns two
  `lowerBinaryImmediateLhs/emitValueIntoScratch` occurrences, for the
  64-bit and at-most-32-bit branches. No helper collapse.
- **Accepted authority/topology:** stage the named rhs into RCX before
  accumulator preparation; use hard spill-live; materialize the literal
  into EAX/RAX and subtract. Narrow masking remains part of the same closed
  plan. Same-source alias topology is not applicable because there is only
  one named request.
- **Frozen-model result:** its exact stream and all seven general rollback
  boundaries passed. The retained fma diff has no L01 first divergence.
- **Disposition:** **LAND as the complete L01 family**.

### L02 — variable shift left

- **Gateways and last owners:** owns one
  `lowerBinaryImmediateLhs/emitValueIntoScratch` occurrence. No helper
  collapse.
- **Accepted authority/topology:** rhs count→RCX first, hard spill-live
  preparation, literal→EAX, SHL by CL, and the exact i16 mask. It has one
  named request and no per-alias destination split.
- **Frozen-model result:** exact i16/i32 stream units and rollback coverage
  passed. There is no canary occurrence and no retained fma hunk.
- **Disposition:** **LAND as the complete L02 family**.

### L03 — variable logical shift right

- **Gateways and last owners:** owns two
  `lowerBinaryImmediateLhs/emitValueIntoScratch` occurrences, for the
  64-bit and at-most-32-bit branches. No helper collapse.
- **Accepted authority/topology:** rhs count→RCX first, hard spill-live
  preparation, literal→EAX/RAX, then logical SHR by CL. There is one named
  request and no multi-alias home split.
- **Frozen-model result:** exact i64 and non-accumulator control units passed.
  There is no canary occurrence and no retained fma hunk.
- **Disposition:** **LAND as the complete L03 family**.

## Honest narrowed ratchet

The present inventory rows are:

```text
lowerBinaryImmediateRhs:
  emitValueIntoEax×1 + emitValueIntoScratch×5 + resolveValue×1 = 7
lowerBinaryImmediateLhs:
  emitValueIntoScratch×5 + materializePairValue×1 = 6
tryLowerLshr64SpillThroughRax:
  resolveValue×1 = 1
```

L00 retains the one `materializePairValue` under O4 pair-result ownership.
The nine families selected to land own the other twelve direct occurrences:

| Landing family | Direct textual removals | Proven helper removal |
|---|---:|---:|
| R00 | 0 | 0 |
| R01 | 2 | 1 (`tryLowerLshr64SpillThroughRax/resolveValue`) |
| R02 | 2 | 0 |
| R03 | 1 | 0 |
| R05 | 0 | 0 |
| R06 | 2 | 0 |
| L01 | 2 | 0 |
| L02 | 1 | 0 |
| L03 | 2 | 0 |
| **Landing total** | **12** | **1** |
| R04 retained | **0** | **0** |

Therefore the independently recomputed, conditional narrowed target is:

```text
166
- 12 direct gateways owned only by complete landing families
-  1 R01 last-owner helper collapse
= 153
```

The number happens to equal the retired full-family carrier's proposed
target, but it is not inherited from that carrier. It follows from the
closed-family ownership partition: R04 contributes no counted gateway.
The narrowed source guard must nevertheless enforce the named R04 residual
and pure pre-transaction routing; a count of 153 alone is insufficient.

`accumulatorArithmeticDisplacement/resolveValue` is not a collapse in this
slice: R04 remains an owner, and named scalar arithmetic also retains future
ownership. L00 and every i128 pair-result branch remain legacy/O4. The
exact-EI dispatch position is unchanged.

## Required narrowed-slice boundary

The retired B5 carrier remains evidence only and cannot be edited into a
landing patch. After this partition is accepted, the new wiring patch must
be built from the accepted tree and:

1. route R04 to legacy before opening a value-use transaction;
2. route all nine landing families directly to their closed action, with no
   attempt/fallback path;
3. remove exactly the twelve family-owned direct gateways and the proven
   R01 helper owner;
4. preserve the L00/i128/exact-EI ownership boundaries;
5. enforce the R04 named residual structurally, not by function or source
   home;
6. prove the exact report/object/owner identities, six-row frontier,
   `__multi3` and fma streams, full gates, and counterbalanced performance.

After that separately reviewed slice, the required refactoring checkpoint
begins even though the ratchet remains 153. R04's future per-alias design is
owned only by `scalar_immediate_multi_alias_preservation` after the
checkpoint; scalar slice 3 cannot absorb it.

## Delivery assertion

INBOX-140 changes this document only. No gate was run because the accepted
tree and all executable behavior are unchanged. The tracked ratchet remains
166. No performance command or Tier 3 command was run. `stash@{0}`, the
retired carrier, and every other preserved carrier remain untouched.
