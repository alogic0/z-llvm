# INBOX-167 — O2 quotient evidence refresh

Status: evidence only. This document authorizes no dormant action,
production wiring, source-guard change, test change, refactoring, or
ratchet movement.

Date: 2026-07-18

## 1. Accepted basis

This refresh is enumerated from the accepted ratchet-135 tree. It does not
inherit the old INBOX-130 terminal projection:

```text
authorization_commit=e77c5d4f45280cc75444ac3eea3d8a73038d1263
authorization_tree=f5972860df3727d4a7368647e7fc508d3969229f
accepted_M64_production_commit=50acec11e5fc257a6add7e74646237f64ccbdd7d
accepted_M64_production_tree=6975178c35e5a799db54010722b1aeb7b87023a6
accepted_M64_evidence_commit=15082e2d
direct_materialization_ratchet=135
```

The accepted decisive identities remain:

```text
report_sha256=49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681
selected/emitted/failed=443/285/158
first_failure=compiler_rt.trunc.truncl/UnsupportedLongDoubleAbi
accepted_object_sha256=061a64e4241c92be1fafbdd9800f00cd3ac7bd1d2d3bef460d79ea1d5a32a0be
owner_manifest_sha256=5d91960e5a01a0e6387f7ef2894dae4a1de93d2ce648c28377f97cd4afa0229d
owner_ledger=167/17/101
```

They are inherited from accepted INBOX-166 evidence. INBOX-167 runs no
Zig gate and regenerates no report, object, owner manifest, canary, or
performance artifact.

### 1.1 Exact refresh inputs

| Input | Lines | SHA-256 | Authority |
| --- | ---: | --- | --- |
| `docs/evidence/inbox81_o2_resolution_materialization_bypasses.tsv` | 67 | `3928114a0fcc55d5f18a367b29865925396c80c3a2589e02c87f4e0a73b23537` | ratchet-bearing direct operations |
| `docs/evidence/inbox84_o2_bypass_classification.tsv` | 151 | `f7281a2a47da5ecc1ecdef8b9d4b96727d82be056bab823a17c28a19ef2d8e7c` | occurrence classification and future ownership |
| `docs/evidence/inbox77_scalar_accepted_ir_occurrences.tsv` | 90 | `14614c6c33a431be2b30a3de12e3f68cfa7295a3cd9e76ee6c1d7635f878336b` | accepted function sets by scalar IR form |
| `tmp/inbox63_accepted_cohort.ll` | — | `d8da86cae494d7d4a58053ab24b1e8be944859263072b85ffa164880b0110cd4` | frozen accepted-cohort IR |
| `src/codegen/x86_64/generic_cfg/composed_selector_scalar.zig` | 1,228 | `ac4ffae4e822d7056b655e11c72096af29ff5b715e61846f3af6e82c4bfeb8fd` | division dispatch, exact order, and diagnostics |
| `value_use/actions/scalar_multiply_divide.zig` | 411 | `9a32e275c70a10d9feb09cb98dd7814dc9d6649601e0aa1a226fd6bda50bd1c0` | frozen future quotient leaf |
| `value_use/actions/scalar_arithmetic.zig` | 28 | `52d434214d7c21bb017d0d58b4cda3c075acf61ac020e1b5ad9c3af06d564cd9` | 23-name action facade |
| `value_use/model.zig` | 1,776 | `e48c949d0e04a24e7fae8c2e54ae48562b2c38c4a2fb403db8630307fd81bcd7` | centralized payload and transaction ownership |
| `value_use/core.zig` | 1,262 | `424f470a350cd17bfc9567766b4889fe82478b69d726abee796ae36a40eb13b4` | sole prepared-action dispatch |
| `source_guard/model.zig` | 593 | `57d41ac55586a146ae239fc40ba072de62f08717f342fb78bddad98a88565d0d` | residual and facade manifests |
| `source_guard/consumer_policy.zig` | 1,991 | `6edcafa64142b5e17d1b941f1b017fd4a7b7853b4a6f2ae9530d0af5d215e41f` | exact consumer ownership |
| `source_guard/split_policy.zig` | 651 | `feb50d9a133dc786795e77e03abd998c3c312dab1bcc8f0d567181bb0f04bac3` | leaf import and size boundaries |

Paths in the last seven rows are relative to
`src/codegen/x86_64/generic_cfg/`.

## 2. Fresh ratchet recount

The accepted ratchet-135 inventory contains exactly three quotient-owned
rows. The table also includes the three retained remainder entries needed
to prove that no shared setup or helper credit belongs to quotient:

| File / function | Direct operation | Count | Ownership at 135 |
| --- | --- | ---: | --- |
| `composed_selector_scalar.zig/lowerUnsignedDivRem` | `resolveValue` | 1 | unsigned quotient RHS classification |
| `composed_selector_scalar.zig/lowerUnsignedDivRem` | `emitValueIntoScratch` | 2 | mutually exclusive RHS-to-RCX staging sites |
| `composed_selector_scalar.zig/accumulatorDirectMaterializationDisplacement` | `resolveValue` | 1 | quotient-only parent helper |
| `composed_selector_scalar.zig/lowerUnsignedRem` | `resolveValue` | 1 | retained remainder RHS classification |
| `composed_selector_scalar.zig/lowerUnsignedRem` | `emitValueIntoAccumulator` | 2 | retained dividend staging |
| `composed_selector_scalar.zig/lowerUnsignedRem` | `emitValueIntoScratch` | 2 | retained divisor staging |

The first three entries total four conditional credits. The final three
entries total five retained occurrences. The two
`lowerUnsignedDivRem/emitValueIntoScratch` calls are separate static
gateways in mutually exclusive accumulator/non-accumulator branches; they
are not two dynamic copies in one lowering.

The early `binary.op == .urem` dispatch occurs before every counted
`lowerUnsignedDivRem` operation. Therefore the three function-local sites
are quotient-only even though the function remains as a dispatcher after a
future quotient migration.

### 2.1 Last-owner and shared-helper audit

The accepted tree has exactly two call sites for
`accumulatorDirectMaterializationDisplacement`, both in the quotient branch
of `lowerUnsignedDivRem`, plus its declaration. Its internal
`resolveValue×1` is a real last-owner candidate only after both admitted
quotient widths land. It is not used by `lowerUnsignedRem`.

No other helper or setup credit belongs to quotient:

| Shared authority/helper | Retained owner preventing credit |
| --- | --- |
| `emitValueIntoAccumulator` | remainder and other scalar consumers |
| `emitValueIntoScratch` | remainder and many ordinary consumers |
| `clobberArgReg(.rcx/.rdx)` | general fixed-register and call preservation |
| `emitArithmeticWrite` / EFLAGS `.write` | retained R03/R04 arithmetic and remainder |
| `emitEflagsInstruction(...div..., .clobber)` | retained remainder |
| `accumulatorDefinition` / `finishArithmeticResult` | retained legacy accumulator-result branches |
| machine `xor_edx_edx`, `div_arg32`, `div_arg64` | retained remainder |
| `lowerUnsignedDivRem` itself | remains the semantic `urem` dispatcher unless separately reviewed |
| `lowerUnsignedRem` and `bindScratch(...rdx...)` | `pair_rdx_authority.urem_rdx_result` |

In particular, quotient may not claim the shared RAX/RDX/RCX setup merely
because it emits the same instructions. The remainder path still executes
that setup and owns its five direct gateways.

The honest conditional arithmetic is:

```text
ratchet_before=135
unsigned_quotient_direct_credit=3
quotient_only_last_owner_credit=1
remainder_or_combined_result_credit=0
conditional_complete_quotient_target=131
```

`131` is conditional on both quotient width families and their aggregate
passing byte-identical isolation, followed by a separately reviewed wiring
slice. If the helper still has any production owner at that future tree,
the last-owner credit is zero and the target is `132`. INBOX-167 itself
leaves the ratchet at `135`.

The inherited `129` terminal projection is obsolete: it began at ratchet
172 and assumed every earlier family/helper credit. This refresh derives
only the four still-available credits from the accepted 135 tree.

## 3. Closed division ownership partition

The current selector does not have one generic division authority. It has
the following distinct, closed forms.

| ID | Exact semantic form | Current authority | Result owner | Disposition |
| --- | --- | --- | --- | --- |
| `S32-I2` | `sdiv i32 <named>, 2` | landed R00 immediate action | EAX quotient | already migrated; control only |
| `UQ32` | `udiv i32 <named>, <named>` | fixed EDX:EAX / RCX legacy quotient | EAX quotient | candidate |
| `UQ64` | `udiv i64 <named>, <named>` | fixed RDX:RAX / RCX legacy quotient | RAX quotient | candidate |
| `UR32` | `urem i32 <named>, <named>` | fixed EDX:EAX / RCX legacy remainder | EDX/RDX scratch32 | retained |
| `UR64` | `urem i64 <named>, <named>` | fixed RDX:RAX / RCX legacy remainder | RDX scratch64 | retained |
| `SN` | named/named `sdiv`, other signed constants, or i64 signed division | no admitted fixed-register emitter | none | retained fail-closed |
| `SR` | `srem` | no admitted fixed-register emitter | none | retained fail-closed |

There is no current `idiv` machine instruction or accepted named signed
fixed-register path. A future quotient action must not add one. “Signed
coverage” in this refresh means preserving the already-landed `S32-I2`
sequence and the exact rejection boundary for every other signed form; it
does not authorize a new IDIV capability.

The candidate is specifically an `UnsignedQuotientAction`, not a generic
divide/rem action. `UR32`, `UR64`, combined quotient/remainder algorithms,
and rejected signed forms do not become action variants.

## 4. Exact admitted streams and state order

### 4.1 `S32-I2` — landed signed quotient control

This form is already owned by `ImmediateRhsScalarAction` plan
`r00_signed_divide_by_two`; it contributes no future ratchet credit. Its
cohort population is exactly five occurrences:

```text
compiler_rt.powiXf2.__powihf2
compiler_rt.powiXf2.__powixf2
compiler_rt.powiXf2.__powitf2
compiler_rt.powiXf2.__powidf2
compiler_rt.powiXf2.__powisf2
```

Its exact authority and order are:

```text
validate semantic i32/named/constant-2 form
validate the one named request
preserve any plan-derived unrelated accumulator occupant
clobber/preserve RCX
prepare the subordinate accumulator session with the R00
  liveness-aware/scratch-preferred displacement
materialize the source into EAX
mov EAX -> ECX
shr EAX,31
add ECX,EAX
sar EAX,1
own and define the i32 result in EAX
finalize and outer-commit
```

RDX is untouched and no DIV/IDIV instruction is emitted. SHR, ADD, and SAR
each record an incidental EFLAGS `.write`; there is no EFLAGS definition,
use, or consumer edge. Form/width/literal checks precede named-source
admission, then RCX preservation, preparation, materialization, the three
writes, result ownership/definition, and finalization. This landed stream is
an exact interaction control for quotient work.

### 4.2 `UQ32` and `UQ64` — candidate unsigned quotient

The source forms are named operands with matching semantic widths. Current
accepted homes are the existing scalar GPR/accumulator/spill homes:

```text
UQ32: arg32, scratch32, EAX, or an accepted low-32 spill/wider scalar view
UQ64: arg64, scratch64, RAX, or spill64
```

No FP/XMM, pointer, pair, aggregate, stack-argument, or new physical home is
admitted. The future transaction remains the sole class/width/home
authority; the consumer may not inspect homes.

The exact state sequence for both widths is:

1. Resolve/classify RHS first.
2. Determine only whether RHS currently occupies the matching accumulator
   (`EAX` for 32 bits, `RAX` for 64 bits).
3. Begin the accumulator-result authority.
4. If RHS is in the accumulator:
   - preserve/clobber RCX and copy RHS to RCX;
   - choose the lhs direct-materialization displacement;
   - preserve the prior accumulator state as required;
   - materialize lhs into EAX/RAX.
5. Otherwise:
   - choose the lhs direct-materialization displacement;
   - preserve the prior accumulator state as required;
   - materialize lhs into EAX/RAX;
   - preserve/clobber RCX and stage RHS to RCX.
6. Preserve/clobber any live RDX occupant.
7. Emit `xor edx,edx`.
8. Emit `div rcx` in the matching physical width.
9. Define the quotient result in EAX/RAX.
10. Commit the accumulator result.

The direct-materialization displacement is a closed form table, not the
arithmetic strict-after authority:

```text
named lhs already in matching EAX/RAX -> reuse_source
every other lhs home                    -> spill_live
```

That reuse decision is intentionally location-derived and liveness
independent. A future action must derive it internally after canonical
admission. No consumer displacement hint is permitted.

RHS-accumulator staging is deliberately before accumulator preparation.
Non-accumulator RHS staging is deliberately after lhs preparation and
materialization. Reversing either order is a byte/diagnostic change.

RAX/EAX, RCX, and RDX preservation are three independent obligations:

- accumulator preparation owns the dividend/quotient register and any prior
  live accumulator result;
- `emitValueIntoScratch(...rcx...)` owns preservation of an existing live
  RCX occupant before divisor staging;
- `clobberArgReg(.rdx)` owns preservation of an existing live RDX occupant
  before zeroing the high dividend.

The quotient result binding occurs only after DIV. No speculative quotient
binding may exist while RDX is zeroed or while DIV executes.

EFLAGS are exact:

```text
xor edx,edx -> incidental .write
div rcx     -> .clobber
result bind -> no EFLAGS record
```

DIV creates no consumable EFLAGS definition; no definition/use may cross it.

### 4.3 `UR32` and `UR64` — retained remainder

Remainder shares the fixed physical sequence but not result ownership:

```text
resolve RHS first
if RHS is EAX/RAX:
  stage RHS -> RCX
  materialize lhs -> EAX/RAX
else:
  materialize lhs -> EAX/RAX
  stage RHS -> RCX
preserve/clobber RDX
xor EDX,EDX
div RCX
bind result as scratch32/scratch64 in RDX
```

Its EFLAGS sequence is the same `.write` then `.clobber`, but the durable
result is RDX, not the quotient in RAX. There is no subordinate accumulator
result session. All five direct operations and the structural
`bindScratch(...rdx...)` exclusion remain with
`pair_rdx_authority.urem_rdx_result`.

A quotient migration must leave the complete remainder body, diagnostic
timing, instruction order, result binding, and function fingerprint
byte-identical.

### 4.4 Combined-result algorithms

The accepted cohort contains functions that compute a quotient and later a
remainder from the same semantic dividend/divisor. Those are two IR
instructions and two current lowering authorities, not permission to turn
one DIV into a combined-result action.

The retained semantic owner is:

```text
scalar_unsigned_divrem_combined_sequence
```

It owns any future coalescing, cross-instruction fixed-register reuse, or
joint quotient/RDX-result transaction. The quotient slice owns only the
individual UQ instruction. It may not suppress, absorb, reorder, or share
setup with the following UREM instruction.

## 5. Diagnostic precedence and request provenance

The current `lowerBinary` semantic checks remain before any quotient
transaction:

```text
missing result
non-integer type
unsupported width
immediate-lhs / immediate-rhs dispatch
i128 pair dispatch
i64 multiply dispatch
udiv/urem i32-or-i64 dispatch
```

For admitted unsigned quotient the exact failure order is:

1. RHS resolution. A missing RHS returns
   `unsupported_value/composed-block-unknown-rhs` before any transaction or
   lhs work.
2. If RHS is accumulator-resident, its RCX staging/preservation failure.
3. Lhs displacement selection and accumulator preparation failure.
4. Lhs materialization failure.
5. If RHS is not accumulator-resident, its RCX staging/preservation failure.
6. RDX preservation/clobber failure.
7. XOR append.
8. DIV append/EFLAGS clobber.
9. Quotient identity definition and commit.

A future action must register both named operands before mutation in legacy
source-validation order: RHS first, then lhs. Request-specific errors map
only when `failedRequestIs(rhs_handle)` or `failedRequestIs(lhs_handle)` is
true; authority-level RCX/RDX/EFLAGS/capacity/cycle failures remain
unattributed and propagate unchanged. There is no consumer-side home
classification, retry, or attempt-then-fallback.

For retained remainder the exact order remains RHS resolution, conditional
RHS-accumulator staging, lhs materialization, non-accumulator RHS staging,
RDX preservation, XOR, DIV, then RDX binding.

Signed diagnostics remain distinct:

- `sdiv i32 <named>,2` routes to the landed R00 action;
- other signed immediate RHS forms retain
  `no_emitter/composed-block-sdiv-form`;
- named/named signed division and signed remainder retain the existing
  binary-op rejection before any fixed-register action.

## 6. Accepted cohort population and shadowing

The frozen IR contains:

| Form | Occurrences | Distinct functions | Exact function population |
| --- | ---: | ---: | --- |
| `S32-I2` | 5 | 5 | the five `compiler_rt.powiXf2` functions listed above |
| `UQ32` | 10 | 4 | `compiler_rt.int.__divmodsi4` ×1, `__modsi3` ×1, `__divsi3` ×1, `__udivmoddi4` ×7 |
| `UR32` | 7 | 1 | `compiler_rt.int.__udivmoddi4` ×7 |
| `UQ64` | 9 | 9 | eight `compiler_rt.divmodei4`/`udivmodei4` functions plus `compiler_rt.udivmod.udivmod__anon_15304` |
| `UR64` | 9 | 9 | the same nine functions |

The exact eight 64-bit helper identities are:

```text
compiler_rt.divmodei4.__divei4
compiler_rt.divmodei4.__divei5
compiler_rt.divmodei4.__modei4
compiler_rt.divmodei4.__modei5
compiler_rt.udivmodei4.__udivei4
compiler_rt.udivmodei4.__udivei5
compiler_rt.udivmodei4.__umodei4
compiler_rt.udivmodei4.__umodei5
```

`__udivmoddi4` and every 64-bit row pair UQ with a later UR. A quotient
success can expose a previously shadowed remainder divergence. Therefore
aggregate report identity alone is insufficient: every accepted function
must be compared independently, and the first semantic instruction change
must be separated from downstream branch-offset movement.

## 7. Named retained owners

| Capability/form | Frozen retained owner | Required effect |
| --- | --- | --- |
| unsigned remainder result in RDX | `pair_rdx_authority.urem_rdx_result` | five direct gateways and RDX binding remain |
| cross-instruction quotient+remainder combination | `scalar_unsigned_divrem_combined_sequence` | no DIV coalescing or setup sharing |
| landed signed divide-by-two | `scalar_immediate_signed_divide_by_two` | R00 stream remains in `scalar_immediate.zig` |
| named/general signed division | `scalar_fixed_register_signed_division` | remains fail-closed; no IDIV capability |
| signed remainder | `scalar_fixed_register_signed_remainder` | remains fail-closed |
| full-product RAX/RDX | `pair_rdx_authority.full_product_rax_rdx` | no multiply-result ownership movement |
| genuine fixed-register copy cycle | `o4_parallel_copy_cycle` | fails before mutation; no cycle scheduler |
| immediate residual R03 | `scalar_immediate_live_shared_source_preservation` | unchanged pre-transaction owner |
| immediate residual R04 | `scalar_immediate_multi_alias_preservation` | unchanged pre-transaction owner |

The future guard must enforce quotient-only action use and every retained
boundary structurally. No function-name or compiler-rt predicate is
permitted.

## 8. Dormant placement and facade budget

The future unsigned quotient implementation belongs in the existing:

```text
value_use/actions/scalar_multiply_divide.zig
```

It does not justify another leaf. The current leaf is 411 lines. The
preferred final leaf size remains at most 1,500 lines; reaching the
2,000-line ceiling is a hard review stop. The quotient design therefore has
1,089 preferred-budget lines and 1,588 lines before the hard ceiling.

The leaf import graph remains exactly the current graph:

```text
std
builtin                         (test hooks only)
ir.zig
machine.zig
types.zig
selector_types.zig
composed_selector_state.zig
value_use/model.zig
value_use/composition.zig
```

It may not import core, planning, materialization, another action leaf,
`composed_selector_scalar.zig`, or the scalar facade. Core continues to
import only `actions/scalar_arithmetic.zig`; payload and error ownership
remain centralized in `model.zig`; core remains the sole exhaustive action
dispatcher.

The reviewed conditional facade expansion is exactly three direct aliases:

```text
executeUnsignedQuotient
isUnsignedQuotient
validateUnsignedQuotientAction
```

Thus:

```text
current_facade_public_names=23
conditional_facade_public_names=26
current_facade_lines=28
conditional_facade_lines=31
```

No remainder, signed-IDIV, result-home, preservation, retry, or generic
division symbol is added to the facade. Any additional public name, import,
action tag, payload field, or reverse dependency requires another review.

## 9. Isolation and aggregate-interaction gates

A dormant action/model/test/guard slice must be accepted before isolation.
During isolation the action, model, lifetime/Q1, planning, materialization,
and fixed-register semantics are frozen; no fix-forward is permitted.

### 9.1 Immutable baseline

Freeze the accepted dormant tree and these baseline artifacts before
temporary wiring:

- complete 443-row report and its exact hash/counts/first failure;
- accepted 285-function object and owner manifest;
- per-function byte/disassembly manifest;
- UQ32/UQ64/UR32/UR64 function subsets;
- the five R00 signed-control functions;
- focused fma and `__multi3` canary streams as collateral controls; and
- exact source and temporary-patch hashes.

### 9.2 Family-isolation matrix

Build these temporary variants:

| Build | Transaction-owned form | Forms forced to current owner |
| --- | --- | --- |
| `Q32` | complete UQ32 family | UQ64, UR32, UR64, R00, signed rejects |
| `Q64` | complete UQ64 family | UQ32, UR32, UR64, R00, signed rejects |
| `Q32+Q64` | aggregate complete unsigned quotient family | UR32, UR64, R00, signed rejects |

For every build:

1. run the complete cohort report/object/owner/per-function comparison;
2. require exact `49a19f04`, `061a64e4`, `5d91960e/167-17-101`, and
   `285/0/0`;
3. run the full unit suite and focused fma/`__multi3` canaries;
4. compare every affected function's complete bytes and disassembly;
5. prove retained UR32/UR64 result bindings and streams are unchanged;
6. prove R00 and signed rejection diagnostics are unchanged; and
7. attribute any difference to the first semantic instruction change,
   separately from downstream branch offsets.

Any divergent occurrence retains its complete width family. Because the
three static quotient gateways and the parent helper are shared by both
widths, an individually accepted width receives no textual ratchet credit.
The four credits become available only when the `Q32+Q64` aggregate is
byte-identical.

If both individual builds pass but the aggregate diverges, isolate the
minimal interacting row/subset. Do not amend the action or land a partial
branch during isolation; stop for review.

### 9.3 Later production gate

A separately authorized production slice must repeat the exact identities,
full unit, source guard, ABI, focused canaries, integrated-exe, strengthened
Tier 2, and the post-final-tree frozen-artifact counterbalanced performance
protocol. No Tier 3 belongs to this O2 slice.

## 10. Delivery assertion

INBOX-167 adds only this evidence document. It changes no production source,
test, source guard, tool, build file, manifest, bypass inventory, or ratchet.
No Zig gate, performance command, or Tier 3 command was run. The tracked
ratchet remains exactly `135`; `131` is only the conditional complete
unsigned-quotient target pending dormant design, isolation, aggregate
review, and separately authorized production wiring.
