# INBOX-161 — O2 multiply evidence refresh

Status: evidence only. No dormant action, production wiring, source-guard
change, test change, or refactoring is authorized by this document.

Date: 2026-07-18

## 1. Accepted basis

This refresh is enumerated from the accepted ratchet-140 source, not from the
old INBOX-130 projection:

```text
authorization_commit=f71dd6b3ea855168c54db9b989eb8884d0fd8f98
authorization_tree=c94ba46328826701a137aa14b200ed0ba6013714
accepted_B07_production_commit=19c4c3b86a0f604cb5e566b4a776c95843fdcce0
accepted_B07_production_tree=a907dcf6498b1a15784db241b019887b48e2ed4a
accepted_B07_evidence_commit=fee82b59b06d8356ad9fc7a07bb21c3f21b95024
direct_materialization_ratchet=140
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

They are inherited from accepted INBOX-160 evidence. INBOX-161 runs no Zig
gate and regenerates no object, report, owner manifest, or performance
artifact.

### 1.1 Exact refresh inputs

| Input | Lines | SHA-256 | Authority |
| --- | ---: | --- | --- |
| `docs/evidence/inbox81_o2_resolution_materialization_bypasses.tsv` | 69 | `92f921c3ae0e87ec25f6ed64803d667789991831da134a466438474ee29eb755` | ratchet-bearing direct operations |
| `docs/evidence/inbox84_o2_bypass_classification.tsv` | 151 | `f7281a2a47da5ecc1ecdef8b9d4b96727d82be056bab823a17c28a19ef2d8e7c` | occurrence classification and future ownership |
| `docs/evidence/inbox77_scalar_accepted_ir_occurrences.tsv` | 90 | `14614c6c33a431be2b30a3de12e3f68cfa7295a3cd9e76ee6c1d7635f878336b` | exact accepted-row sets |
| `src/codegen/x86_64/generic_cfg/composed_selector_scalar.zig` | 1,239 | `79b11acbad195436c900e2a3a3344e8f816f90d4fbd447a5a2fc367c2b17f965` | multiply and division dispatch/order |
| `src/codegen/x86_64/generic_cfg/composed_selector_calls.zig` | 1,264 | `f1046632d670d61439df7252ba12a1ea474829a4b479ed7758ea4e223866cf2d` | full-product exclusion |
| `value_use/actions/scalar_arithmetic.zig` | 24 | `5044d3110298721028ea6565429bef5caecacef96a18e93407e906a4d0ad287c` | current scalar facade |
| `value_use/actions/scalar_named.zig` | 752 | `8ca8e37e93513f2e40c5dd08e0b389ff743ea07944d033b6ec18fcdbeafe48c1` | already-landed narrow multiply |
| `value_use/model.zig` | 1,735 | `eb989e6cb6e8aa9645387751a1839ab751741f96484b6fc3f3cb6dd0d3fdb649` | centralized action payload ownership |
| `value_use/core.zig` | 1,229 | `8ae12ac056f1433d0319a718807090ad2994e5cbc120b98c88eaa6adb19ad44a` | sole prepared-action dispatch |
| `source_guard/model.zig` | 584 | `04eb28b5389661467d2150d518209c3a9400fc2545f10c4b679e0bbfcf3e6d0b` | facade and architectural exclusions |
| `source_guard/consumer_policy.zig` | 1,919 | `ef2e38ad510cfd68eaadf0b163c27c1d7007c0f9b43f614460716faef1f1ccb2` | production consumers and R03/R04 |
| `source_guard/split_policy.zig` | 639 | `48a68ec38dac1e07ba8465de630f8030cd145b1f0827d7ca33565fac0dd27068` | import and line budgets |

Paths in the last six rows are relative to
`src/codegen/x86_64/generic_cfg/`.

## 2. Fresh ratchet recount

The accepted ratchet inventory contains exactly these remaining scalar
multiply rows:

| File / function | Direct operation | Count | Family |
| --- | --- | ---: | --- |
| `composed_selector_scalar.zig/lowerMul64` | `resolveValue` | 2 | complete i64 named multiply |
| `composed_selector_scalar.zig/lowerMul64` | `emitValueIntoScratch` | 2 | complete i64 named multiply |
| `composed_selector_scalar.zig/lowerMul64SpillLhsThroughRax` | `resolveValue` | 1 | complete i64 named multiply fallback |
| **Total** |  | **5** |  |

The four `lowerMul64` occurrences are shared by several physical-home
branches. They cannot be credited to a selected home or occurrence:

1. the first `resolveValue` selects the lhs/result plan;
2. the first `emitValueIntoScratch` stages the lhs into the selected result
   scratch;
3. the second `resolveValue` classifies the rhs after lhs staging; and
4. the second `emitValueIntoScratch` stages a spill-backed rhs only when a
   second scratch register is available.

The fifth occurrence belongs to the accumulator-producing fallback, which
must re-resolve rhs after accumulator preparation. All five disappear only
when the complete semantic `mul i64 <named>, <named>` consumer lands.

### 2.1 Last-owner audit

The following scalar-local symbols are owned only by the current i64
multiply implementation and may disappear or become private action helpers
when that complete family moves:

```text
lowerMul64
lowerMul64SpillLhsThroughRax
plannedScratch64RegForResult
scratch64RegForUseAvoiding                 (scalar-local wrapper)
reusableScratch64RegForInPlace             (scalar-local wrapper)
spillScratch64SourceForInPlace             (scalar-local wrapper)
scratch64RegIsAvailableForUse              (scalar-local wrapper)
SpillScratchForInPlaceResult
```

None is an additional row in the ratchet-bearing bypass inventory. The one
direct operation inside `lowerMul64SpillLhsThroughRax` is already counted
above. The selector-state implementations behind the wrappers retain other
production/test owners, including scalar-immediate and physical-mapping
users. Therefore:

| Ratchet-bearing shared helper | Why multiply cannot claim it |
| --- | --- |
| `accumulatorArithmeticDisplacement/resolveValue×1` | retained by the complete R03/R04 legacy owners |
| `accumulatorDirectMaterializationDisplacement/resolveValue×1` | retained by fixed-register quotient |
| `accumulatorPreserveCurrentDisplacement/resolveValue×1` | retained by the separately owned call consumer |

```text
ratchet_before=140
complete_i64_multiply_direct_credit=5
last_owner_ratchet_credit=0
conditional_complete_multiply_target=135
```

`135` is the honest target only if the whole i64 multiply family is
byte-identical in isolation and aggregate interaction. If any admitted plan
diverges, the complete family remains legacy and the target remains `140`.
There is no partial target by physical home, helper, function, or occurrence.

The old `133` projection is rejected. It began from an obsolete intermediate
ratchet and inherited credits that have since landed or remained with other
owners.

## 3. Multiply forms by exact existing displacement authority

### 3.1 N32 — narrow multiply, already migrated

Semantic family:

```text
mul {i6,i7,i16,i32,admitted exact-EI <=32} <named>, <named>
```

This is the already-landed B03 plan in `NamedScalarBinaryAction`, not work
for the future multiply leaf. Its accepted authority is exactly:

```text
accumulatorArithmeticDisplacement(lhs, .scratch_preferred)
```

That authority uses the strict-after liveness decision. The subordinate
accumulator session prepares lhs before rhs staging, rhs stages to RCX, lhs
materializes to EAX, and `imul` records one incidental EFLAGS `.write`.
Its direct gateway credit already landed during Scalar Slice 3 and is zero
in the ratchet-140 recount.

The accepted appendix records the i32 form in exactly nine rows:

```text
compiler_rt.divsf3.__divsf3
compiler_rt.int.__divmodsi4
compiler_rt.int.__modsi3
compiler_rt.int.__udivmoddi4
compiler_rt.int.__udivmodsi4
compiler_rt.int.__umodsi3
compiler_rt.mulXi3.__muldi3
compiler_rt.rem_pio2_large.rem_pio2_large
compiler_rt.sqrt.sqrtf
```

Narrow multiply is an interaction control for future isolation. It must not
be reimplemented, rerouted, or credited again.

### 3.2 M64-D — i64 scratch-result destination selection

Semantic admission is `mul i64 <named>, <named>`. This is not an accumulator
displacement enum. The existing displacement authority is the complete
source-home-derived destination-selection chain in `lowerMul64`:

| Plan branch | Existing authority and exact order | Result |
| --- | --- | --- |
| reusable scratch lhs, no plan | retain the lhs scratch register | same scratch64 |
| plan present | `reusableScratch64RegForInPlace(lhs)` → `plannedScratch64RegForResult(result)` → `scratch64RegForUseAvoiding(null)` | selected scratch64 |
| no free result scratch and reusable lhs | `spillScratch64SourceForInPlace(lhs)` spills the genuinely live source once, then reuses its register | selected scratch64 |
| arg64/RAX/spill64 lhs with a result scratch | planned result scratch, otherwise first available scratch | selected scratch64 |
| spill-backed rhs with second scratch | after lhs staging and rhs resolution, stage rhs into `scratch64RegForUseAvoiding(dst)` | selected scratch64 |
| spill-backed rhs without second scratch | `spillCurrentAccumulator`, reload rhs to RAX, then `imul dst,rax` | selected scratch64 |

The accepted validation and mutation order is:

```text
resolve lhs
select destination
stage lhs
resolve rhs
stage/reload rhs if required
emit imul
bind scratch64 result
```

The first destructive write is a required lhs/live-source spill when
destination selection needs one; otherwise it is lhs staging. The rhs-RAX
branch preserves the existing accumulator before reload. The action must
derive every choice from canonical state internally. A consumer may not
supply a home, destination register, scratch priority, spill decision,
phase hint, or fallback choice.

### 3.3 M64-R — spill-lhs-through-RAX result

When lhs is `spill64` and M64-D cannot obtain a result scratch, the existing
leaf uses an accumulator definition:

```text
AccumulatorDefinitionTransaction.prepare(.preserve, .spill_live)
reload lhs -> RAX
re-resolve rhs after preparation
imul rax,reg | imul rax,[rsp+spill]
define full RAX
commit
```

The exact authority is the hardcoded `.spill_live` policy at that preparation
point. It is not the narrow arithmetic displacement table and not the i64
scratch-result destination selector. Re-resolution after preparation is
mandatory because preservation may relocate rhs.

M64-D and M64-R are private closed plans of one semantic i64 multiply action.
They are not independently dispatchable production families: selecting them
requires canonical transaction state. No consumer-side home inspection or
attempt-then-legacy fallback is permitted.

### 3.4 Accepted i64 coverage

The appendix key `64/mul/named/named` contains exactly 19 accepted function
identities:

```text
compiler_rt.divdf3.__divdf3
compiler_rt.divmodei4.__divei4
compiler_rt.divmodei4.__divei5
compiler_rt.divmodei4.__modei4
compiler_rt.divmodei4.__modei5
compiler_rt.divsf3.__divsf3
compiler_rt.int.__udivmoddi4
compiler_rt.limb64.__mulo_limb64
compiler_rt.memmove.memmoveFast
compiler_rt.mulXi3.__muldi3
compiler_rt.mulXi3.__multi3
compiler_rt.mulo.__mulosi4
compiler_rt.mulsf3.__mulsf3
compiler_rt.mulvsi3.__mulvsi3
compiler_rt.sqrt.sqrtf
compiler_rt.udivmodei4.__udivei4
compiler_rt.udivmodei4.__udivei5
compiler_rt.udivmodei4.__umodei4
compiler_rt.udivmodei4.__umodei5
```

Several functions contain more than one multiply or mix narrow and i64
multiply. Fail-fast shadowing means the full per-function comparison, not
only the aggregate report hash, is decisive. The existing focused forms also
cover:

- planned result scratch;
- RAX-resident rhs and the rejected EAX near miss;
- spill-backed rhs reloaded through a second scratch;
- spill-backed rhs reloaded through RAX under scratch pressure;
- live scratch lhs spilled exactly once before in-place reuse;
- spill-backed lhs using the RAX result fallback; and
- the exact executable `__multi3` stream.

## 4. Named retained owners

Every boundary below contributes zero multiply credit and must be dispatched
before a future multiply transaction unless its separately reviewed owner is
active.

| Excluded capability/form | Frozen retained owner | Existing enforcement/effect |
| --- | --- | --- |
| signed full-product RAX/RDX aggregate from `lowerSmulOverflowI64` | `pair_rdx_authority.full_product_rax_rdx` | exact architectural exclusion around `prepareFixedProductDefs`; no ordinary scalar result ownership |
| i128 binary and other pair results | `pair_rdx_authority.pair_result` | existing pair chooser/allocation/binding; `lowerPairBinary` direct sites remain |
| fixed EAX/RAX/RDX quotient protocol | `scalar_fixed_register_quotient` | `lowerUnsignedDivRem` remains legacy; no fixed-register action is authorized |
| unsigned remainder bound in RDX | `pair_rdx_authority.urem_rdx_result` | `lowerUnsignedRem` retains all five direct sites and its RDX result |
| genuine physical copy cycle | `o4_parallel_copy_cycle` | remains `ValueUseCopyCycleRequiresO4` before mutation; no cycle scheduling |
| immediate R03 family | `scalar_immediate_live_shared_source_preservation` | complete family remains pre-transaction |
| immediate R04 family | `scalar_immediate_multi_alias_preservation` | complete family remains pre-transaction |

The owner strings in this table are the required future guard labels. The
three `pair_rdx_authority.*` entries correspond to the existing structural
guard's `pair_rdx_authority` slice and its exact exclusion operations.
Neither full-product nor pair-result code may be absorbed merely because it
contains a multiply instruction.

The multiply action also rejects FP/XMM, aggregate, pointer, pair, i128,
unsupported-width, immediate, missing-result, and unsupported-home forms
without mutation. Those existing architectural exclusions are not new
multiply families.

## 5. Family-isolation gate before production wiring

The dormant implementation must be reviewed before isolation. During
isolation the action, model, planning, lifetime/Q1, and materialization
surfaces are frozen; no fix-forward is allowed.

### 5.1 Baseline

Freeze from the accepted ratchet-140 tree:

1. complete 443-row report and its `443/285/158` counters/first failure;
2. accepted 285-row object and owner manifest;
3. per-function bytes and disassembly for all 285 accepted functions;
4. the six `.spill128` frontier rows;
5. focused fma, `__multi3`, and exp2 streams;
6. full unit and focused multiply fixtures; and
7. exact source, temporary patch, artifact, and log hashes.

### 5.2 Isolated candidate

Build exactly one temporary production candidate:

```text
family=M64_complete_named_i64_multiply
semantic_form=mul i64 <named>, <named>
private_plans=M64-D + M64-R
all_other_forms=accepted legacy/previously-landed routes
```

Narrow B03 remains on its already-landed `NamedScalarBinaryAction`. R03,
R04, full-product, pair-result, quotient, remainder, and genuine-cycle
forms remain with the retained owners above. There is no action attempt
followed by fallback.

The isolated build must run:

- complete cohort report comparison;
- whole accepted object comparison;
- owner-manifest and `167/17/101` ledger comparison;
- `285/0/0` per-function bytes and disassembly comparison;
- full unit suite; and
- focused fma and `__multi3` canaries.

Every admitted M64-D and M64-R home/order branch must be exercised. If any
cohort or focused occurrence differs, diagnose the first semantic instruction
change separately from downstream branch-offset movement and retain the
complete M64 family wholesale. No plan-, home-, function-, row-, or
occurrence-specific landing is allowed.

### 5.3 Aggregate interaction

The aggregate build is the isolated M64 family on top of the complete
accepted ratchet-140 tree, which already includes narrow B03, B01/B04-B07,
I52B0, casts, and the landed immediate families. It must repeat the complete
identity/gate set above.

Particular interaction watches are:

- functions containing both narrow and i64 multiply;
- functions with multiple i64 multiplies;
- `compiler_rt.mulXi3.__multi3`;
- `compiler_rt.limb64.__mulo_limb64`;
- divmode/udivmode rows that also contain quotient/remainder forms;
- R03/R04 owners; and
- accumulator pressure that switches between M64-D and M64-R.

Because M64-D/M64-R selection is physical-state-derived, a plan-specific
temporary build is diagnostic only and can never establish a partial landing.
If the aggregate differs after the complete isolated family passed, isolate
the smallest interacting set of already-landed semantic families. An
unattributed or uncorrectable interaction is a review stop, not authorization
to widen the action.

Only after isolated and aggregate byte identity may a separate production
directive claim the five direct credits and target ratchet 135.

## 6. Frozen `scalar_multiply_divide.zig` boundary

The future leaf path is:

```text
src/codegen/x86_64/generic_cfg/value_use/actions/scalar_multiply_divide.zig
```

It is the sole future action leaf for ordinary scalar i64 multiply and,
after a separate later design/authorization, fixed-register quotient. The
multiply dormant slice may add only this exact public leaf surface:

```text
executeScalarMultiply
isScalarMultiply
validateScalarMultiplyAction
```

`isScalarMultiply` is a pure IR classifier for only
`mul i64 <named>, <named>`. It cannot inspect a function identity, selector
state, source home, allocation plan, or alias topology.

The current scalar-arithmetic facade has exactly 20 public aliases. The
multiply slice may add the leaf import and exactly those three forwarding
aliases:

```text
facade_before=20 names / 24 lines
facade_after_multiply=23 names / 28 lines
```

No existing alias may move or change. `core.zig` continues to import only
`actions/scalar_arithmetic.zig`; composed-selector production files never
import the new leaf directly.

Central ownership remains:

- `model.zig`: semantic `ScalarMultiplyAction`, closed request error/test
  types, prepared-action tag, equality, transaction field/attach method;
- `core.zig`: the sole exhaustive registration validation and execution
  dispatch;
- `scalar_multiply_divide.zig`: pure classifier, validation, private closed
  M64-D/M64-R plan derivation, and execution;
- `scalar_arithmetic.zig`: direct forwarding aliases only; and
- `composed_selector_scalar.zig`: pure semantic dispatch and
  provenance-gated legacy diagnostic mapping only.

The semantic action payload is limited to result identity, integer type, and
the already-registered rhs handle. No physical register, `ValueLoc`, spill
slot, destination choice, displacement enum, source-home category, phase
hint, or fallback flag may cross the API.

The leaf's allowed production imports are exactly:

```text
std
builtin
ir.zig
machine.zig
types.zig
selector_types.zig
composed_selector_state.zig
value_use/model.zig
value_use/composition.zig
```

`builtin` is for test-only hooks; production logic may not branch on it.
The leaf may not import `core.zig`, any planning leaf/facade, materialization,
another action leaf, `composed_selector_scalar.zig`, or
`scalar_arithmetic.zig`. Core-to-facade-to-leaf is the only action execution
edge; model and composition remain lower layers.

Line budgets are frozen as:

```text
preferred_leaf_lines<=1500
hard_stop_leaf_lines>2000
facade_public_names=23 after multiply
facade_lines=28 after multiply
```

The eventual quotient work must fit within the same 2,000-line hard ceiling
or return for a reviewed split. It receives no symbols, model tags, facade
aliases, imports, or capacity in the multiply dormant slice.

## 7. Quotient/division inventory — outside multiply authorization

The accepted ratchet-140 inventory separately contains:

| Owner | Direct gateways | Count | Disposition |
| --- | --- | ---: | --- |
| `lowerUnsignedDivRem` quotient path | `resolveValue×1`, `emitValueIntoScratch×2` | 3 | future `scalar_fixed_register_quotient` |
| `accumulatorDirectMaterializationDisplacement` | `resolveValue×1` | 1 | potential last owner only after quotient moves |
| `lowerUnsignedRem` | `resolveValue×1`, `emitValueIntoAccumulator×2`, `emitValueIntoScratch×2` | 5 | retained `pair_rdx_authority.urem_rdx_result` |

The quotient's three direct sites and possible one-site helper collapse are
not multiply credits and are not part of the conditional target 135.
`accumulatorDirectMaterializationDisplacement` currently serves the quotient
path and may be credited only after a separately reviewed division slice
proves it has no remaining production owner. The five remainder sites never
belong to quotient ownership.

Division also retains its exact rhs-first admission, conditional
rhs-accumulator staging, EAX/RAX dividend and quotient, RDX clobber/zeroing,
flag clobber, and no-consumer-across-DIV contract. This document inventories
those facts but authorizes no division payload, action tag, classifier,
facade name, test, or wiring.

## 8. Delivery assertion

INBOX-161 adds only this evidence document. It changes no production source,
test, source guard, tool, build file, manifest, or ratchet inventory. No Zig
gate, performance command, or Tier 3 command was run. The tracked ratchet
remains exactly 140 pending review of a separate dormant multiply design.
