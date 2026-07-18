# INBOX-144 — O2 checkpoint refactoring plan

Status: evidence only; architectural review required before any move.

Date: 2026-07-18

No production, test, guard, tool, or build file is changed by this plan.
No performance or Tier 3 command was run.

## 1. Frozen checkpoint

The checkpoint is frozen against the accepted INBOX-143 tree plus the
Supervisor's acceptance documentation:

```text
accepted_immediate_production=41bdecf9fd2019b644174057f3f18ec9296eae63
accepted_immediate_evidence=01722543e2f312ed7055cd81dd5c342bdade7ac5
checkpoint_head=45d8b517bfdf421ded38c63311d15535913bd36c
checkpoint_tree=0f3e75e96fb52b47e2ab1eaba2ff4798ec811cbf
direct_materialization_ratchet=154
report=49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681
selected/emitted/failed=443/285/158
first_failure=compiler_rt.trunc.truncl/UnsupportedLongDoubleAbi
accepted_object=061a64e4241c92be1fafbdd9800f00cd3ac7bd1d2d3bef460d79ea1d5a32a0be
owner_manifest=5d91960e5a01a0e6387f7ef2894dae4a1de93d2ce648c28377f97cd4afa0229d
ledger=167/17/101
frozen_bypass_inventory=155f7be0d933df9516731265d4442c3ebbc1fb9ca4d5d6f3bacc2776aa936eb6
classification=f7281a2a47da5ecc1ecdef8b9d4b96727d82be056bab823a17c28a19ef2d8e7c
stash_at_0=untouched
preserved_patches=untouched
```

The identities above are inherited from the accepted INBOX-143 evidence.
This documentation-only slice does not rerun them. Every later checkpoint
slice must reproduce the same identities and ratchet.

## 2. Current physical identity

The SHA-256 and Git blob IDs make the source used by future move proofs
unambiguous. Lines and bytes are physical file counts at the checkpoint.

| File | Lines | Bytes | SHA-256 | Git blob |
| --- | ---: | ---: | --- | --- |
| `composed_selector_value_use_transaction.zig` | 3 | 103 | `4f5887e9d2bce0943df26c1e08e8360053440da64eefd19ddfd9d53225dddd7a` | `c232b07d951e07fbba1354a59eaeda77a6ca35f9` |
| `value_use/actions/scalar_arithmetic.zig` | 1,561 | 57,213 | `ff6d112ac285bef239f64873d77954e48e66594049a18867b6def17fb91e64f1` | `a251fa028ed3e9d8cb3e99b96100d3954a22ab2f` |
| `value_use/actions/scalar_arithmetic_cast_tests.zig` | 854 | 34,364 | `f111dcf1f9d9a556f850e4a3fa45cbc6730f5fbb158493e018239b23c2ee05f5` | `8c1a07cdf2d6b53c6d6e85541d6dd25dbc316520` |
| `value_use/actions/scalar_arithmetic_immediate_tests.zig` | 1,250 | 53,622 | `aa7d9a3c722aa6cf7d13393469e96ef8ac8cad39cdb774dc809a7eb93ca06df7` | `a198a58b3b3d1ca3c7bd1ddbc9eaed2f8cafb927` |
| `value_use/planning.zig` | 2,301 | 102,753 | `0dfd3a8f02842539a128bb6c0b05e699377346264d0160ab6874dcec671140ff` | `aea74f02aeadfd371f7835f20ef8b5b94c135e18` |
| `value_use/core_planning_tests.zig` | 421 | 20,612 | `fa1cb47c2b867b1335a1134179786a644d146e698c7135ecd848e84c5427bead` | `fe100d54bafc0b13529acd1d6ac6b4a4b601d172` |
| `value_use/planning_early_tests.zig` | 538 | 27,724 | `3d294e88c70408b2020f0a0af94a4fdf20b14721939a9d46f65f9be95cae2910` | `8380090f8bc9f460cb37ec45fecba8d75e32dba2` |
| `value_use/model.zig` | 1,513 | 55,104 | `b9c61b866fecb563795ae94be3eabfeb7d173e75b95cdf79325e430698b02ad8` | `e6341826be9d9d0a5e906c736a8338f6480b4df2` |
| `value_use/core.zig` | 1,235 | 58,203 | `8d4221bdde74f697d5c16f819c2458511f7663bb550da67fa747d964386cedf1` | `f8392fd508f9627a7f651f32013f1b7f37baec9f` |
| `composed_selector_state.zig` | 2,730 | 136,052 | `6133798fd12668f41ebe4b8c7cfe73d1ed86f3824ffa624b65174538b7d0dd1f` | `07819ef8c3fc01e8c150cd3b7fad0d0edf5e0e32` |

The guard and public-contract boundary is:

| File | Lines | Bytes | SHA-256 | Git blob |
| --- | ---: | ---: | --- | --- |
| `source_guard/model.zig` | 486 | 37,376 | `4da7009c024764f1cf3d05035d6a56630b905d66e85eff8493d052708538f978` | `8fe161e48d48c2ff7c912d6a7f2077aee1e35b8a` |
| `source_guard/split_policy.zig` | 380 | 18,721 | `be3c612348edbbd6ba4c014472d360b2a5a058b149c99526354cff0e4d6cef2a` | `f2bd8989fe181eca011b4d0f8ed46e699f745f9d` |
| `source_guard/authority_policy.zig` | 1,326 | 61,095 | `926c3166c2ae01837f805be662ba73c35a4833499b2382e608a948f25994e6b2` | `14f241a0bd568ad71fa03c09644f49c1d781d4e3` |
| `source_guard/residual_policy.zig` | 504 | 23,375 | `2d2f5bb6f33a4ae5ad181d0be8712e490047d59aaa6eeb498012abc02654cc26` | `ecf5288e650b38e2f90f6fbe3d1723a0bb7b4f01` |
| `source_guard/consumer_policy.zig` | 1,762 | 89,186 | `6f79ae69bab0a24b84077d56a2faa9292ea6c71ab2634ecb70971e7b898bad54` | `d8e850333d2f8c55f4ce0a4cce9e9997ae0448a1` |
| `inbox128_o2_r1_facade_manifest.tsv` | 108 | 2,235 | `68db09931f2916753f2fd257da06ee78ab7aac851efe855ab9b32e280b9e9966` | `7c6568e503b7fbbf93102789196acc92ca47dd06` |

The stable test/build roots are also frozen:

| File | Lines | SHA-256 |
| --- | ---: | --- |
| `build.zig` | 424 | `7dc0609438a3b560ab0ee96cd2ec72329ba8327368cd8b177fb6a2f0fa6120a0` |
| `src/tests.zig` | 8 | `14b3abe011810946fb9c93685f41cd79d847c98d19d7f72cd442d4824049ea15` |
| `generic_cfg_selector.zig` | 242 | `55712a6957b865d2ef9afbcc3a2f1dc8f0c25e1f83d8ea5486c3cb0781378d63` |
| `generic_cfg/composed_selector.zig` | 17 | `77a1ed04e81d6bc44281a2e3535137702b6426939110a01310eaf9d5f62ff7f4` |
| `generic_cfg/composed_selector_tests.zig` | 20 | `a49078ebaf3a9725e8d2e9b279674f8f4fe2511ec1f07b6af145d7138c8f4294` |
| `generic_cfg/composed_selector_value_use_transaction_tests.zig` | 23 | `154ae1ffc3713396dddd726e3e5efd2a37afc58bf88bf1b1d6338dcdaf5b28c3` |
| `generic_cfg/composed_selector_source_guard_tests.zig` | 7 | `bcac92c71832678d831f46bcc0656c7458630877048f9d511964ec9aef7dfda2` |

There is no `build.zig.zon` in this tree.

## 3. Frozen facade, tags, signatures, and errors

The external facade remains exactly:

```zig
const core = @import("value_use/core.zig");

pub const ValueUseTransaction = core.ValueUseTransaction;
```

Its sorted 107-symbol public manifest remains
`docs/evidence/inbox128_o2_r1_facade_manifest.tsv`, SHA-256
`68db09931f2916753f2fd257da06ee78ab7aac851efe855ab9b32e280b9e9966`.
No checkpoint slice may add, remove, or rename a facade symbol.

The central `model.zig` remains the sole owner of `UseForm`,
`PreparedAction`, every semantic action payload, the request/action error
sets, and transaction storage. The order of the scalar additions is frozen:

```text
UseForm tail:
pair_low_scalar_cast_operand
accumulator_scalar_cast_operand
sign_extend_scratch_operand
immediate_rhs_scalar_operand
immediate_lhs_scalar_operand
stack_argument
new_pair_ownership

PreparedAction tail:
pair_low_scalar_cast
accumulator_scalar_cast
sign_extend_scratch
immediate_rhs_scalar
immediate_lhs_scalar

ScalarCastRequestError:
ValueUseScalarCastFormUnsupported
ValueUseScalarCastWidthUnsupported
ValueUseScalarCastLocationUnsupported
ValueUseScalarCastImmediateMismatch
ValueUseScalarCastScratchUnavailable

ImmediateScalarRequestError:
ValueUseImmediateScalarFormUnsupported
ValueUseImmediateScalarWidthUnsupported
ValueUseImmediateScalarLocationUnsupported
ValueUseImmediateScalarLiteralOutOfRange
ValueUseImmediateScalarScratchUnavailable
```

The complete scalar action facade budget is these 14 names, sorted by the
existing guard:

```text
executeAccumulatorScalarCast
executeImmediateLhsScalar
executeImmediateRhsScalar
executePairLowScalarCast
executeSignExtendScratch
isAccumulatorScalarCast
isImmediateLhsScalar
isImmediateRhsScalar
isPairLowScalarCast
isSignExtendScratchCast
validateAccumulatorScalarCastAction
validateImmediateLhsScalarAction
validateImmediateRhsScalarAction
validatePairLowScalarCastAction
```

The complete planning facade budget is these 15 names:

```text
actionOwnsOrderedWrites
argRegForNode
nodeForArgReg
pairSourceNodes
planEarlyMaterializations
requestDestinationNodes
requestMappings
scalarSourceNode
seal
validateBindingCompatibility
validateEarlyHome
validateFormAndDestination
validateRequest
validateRequestAt
validateSemanticOrderTopology
```

The scalar public signatures are frozen verbatim from the
`ff6d112a...` blob:

```text
isPairLowScalarCast(ir.CastInst) bool
isAccumulatorScalarCast(ir.CastInst, bool) bool
isSignExtendScratchCast(ir.CastInst) bool
validatePairLowScalarCastAction(*const PairLowScalarCastAction) !void
validateAccumulatorScalarCastAction(*const AccumulatorScalarCastAction) !void
executePairLowScalarCast(comptime Authority: type, anytype, u8, *const PreparedView, *const PairLowScalarCastAction) !void
executeAccumulatorScalarCast(comptime Authority: type, anytype, u8, *const PreparedView, *const AccumulatorScalarCastAction) !void
executeSignExtendScratch(comptime Authority: type, anytype, u8, *const PreparedView, *const SignExtendScratchAction) !void
isImmediateRhsScalar(ir.BinaryInst) bool
isImmediateLhsScalar(ir.BinaryInst) bool
validateImmediateRhsScalarAction(*const ImmediateRhsScalarAction) !void
validateImmediateLhsScalarAction(*const ImmediateLhsScalarAction) !void
executeImmediateRhsScalar(comptime Authority: type, anytype, u8, *const PreparedView, *const ImmediateRhsScalarAction) !void
executeImmediateLhsScalar(comptime Authority: type, anytype, u8, *const PreparedView, *const ImmediateLhsScalarAction) !void
```

The planning public signatures are frozen verbatim from the
`0dfd3a8f...` blob. All `Authority`/`transaction` functions retain their
generic inferred but finite error unions:

```text
seal(comptime Authority: type, transaction: anytype) !void
validateRequestAt(comptime Authority: type, transaction: anytype, index: u8) !?ValueLoc
validateRequest(comptime Authority: type, transaction: anytype, index: u8, request: *const StoredRequest) !?ValueLoc
validateSemanticOrderTopology(comptime Authority: type, transaction: anytype) !void
planEarlyMaterializations(comptime Authority: type, transaction: anytype, mappings: []const Mapping) !void
validateEarlyHome(comptime Authority: type, transaction: anytype, index: u8) !void
validateFormAndDestination(request: *const StoredRequest) !void
requestDestinationNodes(comptime Authority: type, transaction: anytype, request: *const StoredRequest, current: ?ValueLoc) !NodeList
requestMappings(comptime Authority: type, transaction: anytype, request: *const StoredRequest, request_index: u8, current: ?ValueLoc) !MappingList
actionOwnsOrderedWrites(PreparedAction) bool
validateBindingCompatibility(ValueBinding, *const StoredRequest, ValueLoc) !void
scalarSourceNode(ValueLoc) ?PhysicalNode
pairSourceNodes(ValueLoc) [2]?PhysicalNode
nodeForArgReg(ArgReg) PhysicalNode
argRegForNode(PhysicalNode) ?ArgReg
```

A Zig `@typeInfo` inventory of all 43 concrete transaction methods proves
that no reachable set is `anyerror`. Each digest is SHA-256 over the
compiler-reported error names in order, one name plus newline. The complete
manifest SHA-256 is
`9134b5f6aee662e81040584a8ba9205eb212ecd4f14125ab1f3b64cccf6b66fc`.
The methods affected most directly by the planned moves are:

| Method | Error count | Ordered error-name digest |
| --- | ---: | --- |
| `register` | 25 | `01d279d8c999e9b48a1720453f63b3d3a883e9beb63d43188394c008681f80d7` |
| `seal` | 78 | `ce8ed7acdca0aedd347d2ab207af295dfb70967b6262b01fb1891f140369f140` |
| `prepare` | 78 | `1267339d1d99a25be40a379d0e3bf92d64586a62bbcbe53e25336e2f64895525` |
| `materializeAll` | 81 | `f03b07e1978d8baf097131299012af1a6e8c270ddfddd63d60c0df304efe616a` |
| `executePreparedAction` | 147 | `ca2c7a09c7fdeba6a08d21f403fcc64ac1977bc28f73c07ccf08671eec29b98e` |
| `commit` | 3 | `644c906beba32dc015dddc54d1aa0533674ed2a290c075d99b35da56790429a4` |
| `rollback` | 1 | `8c83efbdfe37fd362c10b4a0e342df8c65de2c2b96f8672a094f386d18a212b8` |
| all eight scalar classifiers | 0 | `-` |

Every production move must regenerate the complete 43-row manifest and
match both the per-method counts/digests and the aggregate digest. A changed
inferred set is a hard stop even when compilation succeeds.

## 4. Current and planned import DAG

The current internal production graph is:

```text
composed_selector_value_use_transaction.zig
  -> value_use/core.zig

core
  -> model
  -> planning
  -> materialization
  -> composition
  -> actions/{address_memory,control_compare,scalar_arithmetic,calls}

planning
  -> model
  -> actions/control_compare
     (classifyScratchCompare only)

materialization -> model
composition     -> model
address_memory  -> model, materialization, composition
control_compare -> model, materialization, composition
scalar_arithmetic -> model, composition
calls           -> model, materialization
model           -> no value_use leaf
```

The current test/build graph is:

```text
build.zig -> src/tests.zig
src/tests.zig -> generic CFG selector test roots
generic_cfg_selector -> composed_selector
composed_selector -> composed_selector_tests
composed_selector_tests
  -> composed_selector_value_use_transaction_tests
  -> composed_selector_source_guard_tests

composed_selector_value_use_transaction_tests
  -> 21 value_use test leaves, including the two scalar files and
     core_planning_tests + planning_early_tests

composed_selector_source_guard_tests
  -> source_guard/{residual,authority,consumer,compare,split}_policy_tests
```

The planned graph is acyclic:

```text
actions/scalar_arithmetic.zig (thin facade)
  -> actions/scalar_cast.zig
  -> actions/scalar_immediate.zig

core -> actions/scalar_arithmetic.zig only
scalar_cast      -> model, composition
scalar_immediate -> model, composition

planning.zig (thin facade)
  -> planning/lifetime_admission.zig
  -> planning/compatibility.zig
  -> planning/physical_mapping.zig
  -> planning/semantic_ordering.zig

core -> planning.zig only
physical_mapping -> lifetime_admission, compatibility, semantic_ordering
lifetime_admission -> compatibility
semantic_ordering -> compatibility
compatibility -> model
physical_mapping -> actions/control_compare
  (the existing frozen classifyScratchCompare edge only)
```

No action leaf may import `planning.zig` or a planning leaf. No planning
leaf may import `core`, `materialization`, `composition`, an action facade,
or an action executor. The sole planning-to-action edge remains the two
existing calls to the pure `classifyScratchCompare`; its signature/body
must be frozen separately. If another action classifier is required, or
any reverse action-to-planning edge appears, the planning slice stops for
review. Shared classification data moves to `model.zig` only under a
separate reviewed ruling; it is not invented during the split.

The technically public declarations needed only across leaves are guarded
internal names. They are never exported from the external facade and may
not be imported directly by composed-selector production consumers.

## 5. Slice 1 — production scalar-action split

`actions/scalar_arithmetic.zig` becomes a direct-alias facade over two
implementation leaves. No empty named-arithmetic leaf is created.

### 5.1 Exact declaration ownership

| Destination | Frozen declarations from `scalar_arithmetic.zig` |
| --- | --- |
| `scalar_cast.zig` | `AccumulatorScalarCastPlan`; `isPairLowScalarCast`; `isAccumulatorScalarCast`; `isSignExtendScratchCast`; both cast validators; all three cast executors; `scalarCastExactEiBits`; `scalarCastNamedSource`; `scalarCastSourceValue`; `scalarCastDisplacement`; `scalarCastSourceDisplacement`; `scalarCastPlan`; `scalarCastResultDefinition`; `plannedScalarCastScratch`; `scalarCastScratchForUse`; `scalarCastScratchAvailable`; `scalarCastRequestError`; `failScalarCastForTest` |
| `scalar_immediate.zig` | `ImmediateScalarPlan`; `ImmediateAccumulatorPreamble`; `ImmediateDisplacementAuthority`; both immediate classifiers and validators; both immediate executors; both semantic classifiers; `immediateAccumulatorPreamble`; `preserveImmediateUnrelatedAccumulator`; `executeImmediateR00`; `executeImmediateR01`; `executeImmediateR02`; `executeImmediateR03`; `executeImmediateR04R06`; `beginImmediateAccumulatorSession`; `materializeImmediateAccumulator`; `finishImmediateAccumulatorResult`; `bindImmediateScratchResult`; `ownImmediateResult`; `immediateScalarNamedSource`; `immediateScalarSourceValue`; `validateImmediateScalarSource`; `refreshImmediateScalarSource`; `immediateDisplacementAuthority`; `immediateSourceDisplacement`; `immediateScratch64Destination`; `immediateScratchAvailable`; `immediateAccumulatorDefinition`; `emitImmediateWrite`; `immediateScalarRequestError`; `immediateShiftAmount`; `immediateI32`; `immediateI64`; `fitsI32`; `integerBits`; `failImmediateScalarForTest` |
| `scalar_arithmetic.zig` | imports of the two leaves and direct public aliases for exactly the frozen 14-name budget; no implementation, classifier, plan, error translation, retry, or cleanup |
| `model.zig` | all cast/immediate payload structs, `PreparedAction` tags, `UseForm` tags, request errors, test-failure enums, prepared-view tags, and transaction fields remain in place |

The original physical ranges are imports/aliases 1-18, immediate private
plan types 20-47, cast plan and implementation 49-444, and immediate
implementation 445-1561. Imports may be duplicated or removed only as
required by Zig's unused-declaration rules. Every non-import declaration
is a verbatim move.

The facade does not forward through runtime callbacks and does not branch.
`core.zig` keeps its single import of `actions/scalar_arithmetic.zig`; it
must not import the new leaves.

### 5.2 Size budget

| File | Projected lines | Limit |
| --- | ---: | ---: |
| `scalar_arithmetic.zig` facade | 20-40 | preferred <1,500 |
| `scalar_cast.zig` | 430-500 | preferred <1,500 |
| `scalar_immediate.zig` | 1,120-1,200 | preferred <1,500 |

Any implementation leaf at or above 1,500 lines is flagged in evidence.
At 2,000 lines the slice stops for review. The facade does not count as a
place to hide implementation.

## 6. Slice 2 — production planning split

`planning.zig` becomes a direct-alias facade with exactly the frozen
15-name budget.

### 6.1 Proven ownership partition

| Destination | Public owner | Private declarations moved with it |
| --- | --- | --- |
| `planning/lifetime_admission.zig` | `validateRequestAt`, `validateRequest`, `validateFormAndDestination` | `validateDeferredSwitchRequest`; the `core_availabilityForConsumption`, `core_mustSurviveInstruction`, and `core_occupantNeedsPreservation` three-question authority moves as one reviewed block; no Boolean fallback |
| `planning/compatibility.zig` | `validateBindingCompatibility` | `validateScratchCompareBinding`; `validateOrdinaryLoadHome`; `validateReadOnlyPointerLoadHome`; `validateReadOnlyTableLoadHome`; `hasLow32View`; `validateExpectedType`; `validateSourceView`; store/memcpy/load operand compatibility helpers |
| `planning/physical_mapping.zig` | `seal`, `requestDestinationNodes`, `requestMappings`, `scalarSourceNode`, `pairSourceNodes`, `nodeForArgReg`, `argRegForNode` | `NodeList`; `MappingList`; `CopyVisitState`; destination/mapping appenders; immediate/cast scratch destination helpers; copy-form validation; `rejectCopyCycles`; `visitCopyNode`; fixed-node conversion helpers |
| `planning/semantic_ordering.zig` | `validateSemanticOrderTopology`, `planEarlyMaterializations`, `validateEarlyHome`, `actionOwnsOrderedWrites` | `Mapping`; `actionSecondaryOperand`; `actionTertiaryOperand`; `resetSemanticOrderPlan`; `appendOrderedOperand`; `sortSemanticRoots`; `semanticRootLessThan`; `firstStructuralDestination`; `validateEarlyHomeUnchecked`; `earlySequencingCandidate`; `rejectSemanticOrderCycles`; `visitSemanticOrderNode`; `firstMappingDestination`; `sourceStructuralOrder`; `earlyCopyIsFlagsPreserving` |
| `planning.zig` | direct aliases for the exact 15 public names | imports only; no orchestration, mutation, validation, or error translation |

`physical_mapping.seal` remains the sole orchestrator: semantic topology,
per-request admission/compatibility, destination/mapping construction,
copy-cycle rejection, early-plan construction, write-node commit, then
phase transition. The statement order is body-proven and may not change.

`Mapping` becomes technically public only to
`physical_mapping` and `semantic_ordering`. `NodeList` and `MappingList`
remain owned by `physical_mapping`; they are not facade exports. Exact
internal-name budgets and direct-import guards prevent composed-selector
production files from importing any planning leaf.

### 6.2 Lifetime and durable-key indivisible units

The lifetime unit consists of:

- `model.LifetimePin` and `model.LifetimeContext`, including the
  identity-plus-generation-only pin and the transaction field;
- the three Q1/Q2/Q3 functions named above;
- every `validateRequest` and post-relocation revalidation call;
- the private, request-attributable errors `ValueUseSourcePlanMissing`,
  `ValueUseSourceIntervalMissing`, `ValueUseExpiredSource`, and
  `ValueUseSourceGenerationChanged`;
- the address-dependency validation calls and strict/inclusive interval
  boundaries.

The storage declarations remain in central `model.zig` to preserve
transaction field layout and avoid a model/planning import cycle. All
behavioral functions move together to `lifetime_admission.zig` in the same
production slice. Moving only one question, exposing the context, retaining
a `ValueLoc`, changing an error attribution, or changing an interval
boundary is a hard stop.

The durable spill-key unit consists of:

- `composed_selector_state.insertOwnedSpillSlot`;
- `snapshotContainsSpillSlot`;
- `restoreSpillSlots`;
- `allocateSpillSlot` and `allocatePairSpillSlots`;
- `ComposedBlockSelector.owned_spill_slot_keys`;
- `CoreSnapshot` spill capture, rollback call, and teardown.

This unit is an explicit no-move anchor in the planning split. It remains
whole across `composed_selector_state_data.zig`,
`composed_selector_state.zig`, and `core.zig`; no planning leaf owns or
copies it. A mechanical hunk that intersects any member stops the split
rather than moving part of the boundary. This is the only disposition
consistent with the explicit deferral of `composed_selector_state.zig`.

### 6.3 Size budget

| File | Projected lines | Limit |
| --- | ---: | ---: |
| `planning.zig` facade | 25-50 | preferred <1,500 |
| `planning/lifetime_admission.zig` | 300-450 | preferred <1,500 |
| `planning/compatibility.zig` | 500-700 | preferred <1,500 |
| `planning/physical_mapping.zig` | 750-950 | preferred <1,500 |
| `planning/semantic_ordering.zig` | 550-750 | preferred <1,500 |

Any leaf at or above 1,500 lines is flagged. Any leaf at 2,000 lines is a
mandatory review stop.

## 7. Slice 3 — scalar tests

The stable aggregator will be
`value_use/actions/scalar_arithmetic_tests.zig`. The root
`composed_selector_value_use_transaction_tests.zig` replaces its two
current scalar imports with this one aggregator import. The aggregator
imports `scalar_cast_tests.zig` and `scalar_immediate_tests.zig`; tests
remain owned by the matching production leaf and continue to exercise the
public transaction facade. No private production declaration is exported
for testing.

There are exactly 33 names. Their sorted-name-set SHA-256 is
`ca5ccf5816f893fbdbf2875f5522d6b4f69e49f7bcfdfaf4985e8d5c6e976d0c`.

```text
value-use C52-0 rollback restores spill and reload boundaries exactly
value-use accumulator scalar cast reproduces ordinary exact-EI and i52 streams
value-use immediate scalar R01 spill source falls back through RAX when scratch is unavailable
value-use immediate scalar R05 inclusive policy and genuine Q3 aliases are exact
value-use immediate scalar declared-type binding-class home cross product is frozen
value-use immediate scalar diagnostics preserve request provenance
value-use immediate scalar displacement distinguishes live-after from dies-at-current RAX
value-use immediate scalar exact R00 and variable lhs streams
value-use immediate scalar literal validation precedes request mutation
value-use immediate scalar malformed dependency liveness fails closed and rolls back
value-use immediate scalar non-accumulator and literal controls remain exact
value-use immediate scalar plan table is closed and direction specific
value-use immediate scalar real __multi3 percent-11 uses inclusive policy without a Q3 alias
value-use immediate scalar representatives retain result ownership and writes
value-use immediate scalar rollback restores every tested boundary
value-use immediate scalar rollback spans preservation scratch and multi-instruction stages
value-use immediate scalar source-derived result branches retain accepted streams
value-use immediate scalar unrelated-alias malformed liveness fails closed before preservation
value-use immediate scalar unrelated-alias preamble rollback preserves flags and state
value-use outer rollback frees a subordinate speculative spill key exactly once
value-use pair-low scalar cast preserves existing pair low-limb streams
value-use pair-low scalar cast preserves width-before-home diagnostic precedence
value-use pair-low scalar cast rollback frees owned result exactly once
value-use pair-low scalar cast rolls back scratch selection and pair staging
value-use scalar cast classifiers are pure and fence alias and pair-result casts
value-use scalar cast displacement table is explicit and byte exact
value-use scalar cast request provenance preserves rejected home diagnostics
value-use scalar cast rollback restores every partial action boundary
value-use scalar cast unresolved source fails before home classification
value-use sessionless scalar cast identity allocation failures leave no durable state
value-use sessionless scalar cast rollback frees owned result exactly once
value-use sign-extend scratch cast is sessionless durable and byte exact
value-use subordinate spill key survives teardown churn rehash and later transaction
```

The test-move manifest records baseline file, original ordinal, original
line, test name, destination file, and exact body hash. Its key set and
sorted-name set must each match 1:1; missing, duplicate, renamed, or
unowned tests fail the slice.

## 8. Slice 4 — planning tests

The stable aggregator will be `value_use/planning_tests.zig`. The root test
aggregator imports it in place of `core_planning_tests.zig` and
`planning_early_tests.zig`. The leaf test ownership is:

| Test leaf | Ownership |
| --- | --- |
| `planning_lifetime_admission_tests.zig` | lifetime availability, dependency liveness, dead/live alias preservation |
| `planning_compatibility_tests.zig` | type/class/home/dependency rejection |
| `planning_physical_mapping_tests.zig` | registration/seal, destinations, conflicts, copy cycles, combined rollback |
| `planning_semantic_ordering_tests.zig` | semantic roles, early plans, prefix closure, ordering conflicts, early rollback |

There are exactly 14 names. Their sorted-name-set SHA-256 is
`85d127cc6f0815abb7edf425d944da512fa876a26ee69430751fb68fc5dfd11f`.

```text
value-use early sequencing rollback covers early and preservation failure points with live EFLAGS
value-use lifetime authority separates plan interval availability and provenance
value-use planner handles source aliases and multiple safe early reloads
value-use planner leaves occupied early destination to ordinary preservation
value-use planner reloads free r8 before preserving live rcx and does not rematerialize
value-use semantic ordering rejects shared role ownership before mutation
value-use semantic-order rollback restores after first and second early copies
value-use semantic-role early scheduling is prefix closed
value-use semantic-role planner orders base before secondary for byte and scaled addresses
value-use transaction dependency and unsupported-view failures leave selector unmodified
value-use transaction phase capacity identity and coalescing rules fail before mutation
value-use transaction removes dead aliases and preserves live aliases exactly once before re-resolution
value-use transaction rollback restores instructions bindings spills counters flags and domains after partial emission
value-use transaction separates safe overlap from genuine copy cycles and conflicting destinations
```

The same exact test manifest and no-export rule used by the scalar split
applies. Planning-private types remain private or technically public only
inside the frozen internal-name budgets; tests do not cause facade growth.

## 9. Guard contracts that must survive every slice

The following policies are semantic contracts, not incidental source
patterns:

1. `consumer_policy` keeps the exact pure classifiers and named residual
   owners `scalar_immediate_live_shared_source_preservation` (R03) and
   `scalar_immediate_multi_alias_preservation` (R04). Both dispatch before
   transaction creation; neither may use an action, fallback, function
   name, home, or alias-topology predicate.
2. The R00 and R05 zero-textual-count semantic ownership guards remain
   active. Moving files cannot reintroduce their legacy anchors.
3. `authority_policy.validateLifetimeContextAuthority` continues to prove
   a private identity/generation-only pin, distinct Q1/Q2/Q3 functions,
   plan and interval errors, dependency validation, strict
   survive-after-current behavior, and no retained `ValueLoc`.
4. `residual_policy.validateDurableSpillSlotOwnership` continues to reject
   raw insertion outside `insertOwnedSpillSlot`, prove lookup-before-own,
   duplicate-no-allocation, rollback free-once, committed teardown, and
   scalar/pair allocation routing.
5. `split_policy` gains exact leaf path/name budgets, facade-only
   production imports, line ceilings, and the planned acyclic graph. It
   must not weaken `validateSplitValueUseTree` by normalizing away a
   forbidden dependency.

Each execution slice records a policy/negative-fixture provenance manifest:
policy function, accepted source anchor, every existing negative fixture,
new location, body hash, and result. Required negative fixtures cover
R03/R04 relocation and transaction absorption, lifetime public escape or
boundary collapse, durable raw-key insertion or partial movement, facade
growth, direct production leaf import, reverse action-to-planning import,
duplicate production instantiation, test-name loss/duplication, and both
1,500-line warning/2,000-line stop reporting.

## 10. Mechanical move proof

Every production and test split uses a tracked Zig provenance tool, not a
Python script. It parses the frozen source blob and emits one row per
top-level declaration or test:

```text
baseline_blob
old_file
old_start_token
old_end_token
symbol_or_test_name
visibility
normalized_signature_sha256
body_sha256
destination_file
destination_symbol
destination_signature_sha256
destination_body_sha256
disposition=verbatim_move|direct_alias|import_adjustment|no_move_anchor
```

For a `verbatim_move`, normalized signature and body hashes must match.
For a `direct_alias`, the destination implementation must match the old
body and the facade alias must contain no branch, cleanup, mutation, error
translation, retry, callback, or runtime dispatch. Import path changes,
module qualifiers required by the split, and removal of genuinely unused
imports are separately enumerated; they are never hidden inside the body
comparison.

The move proof also freezes and compares:

- the 107-symbol external facade manifest;
- the 14-name scalar and 15-name planning internal facade budgets;
- `UseForm`, `PreparedAction`, request-error, and dispatch tag order;
- every concrete facade method signature and its finite reachable error
  digest;
- `Transaction` size, alignment, field order, defaults, and offsets;
- the one production `model.Transaction(Implementation)` instantiation;
- allocated sections and the accepted identities.

Any unexplained body/signature mismatch is a hard stop, not an invitation
to clean up code while moving it.

## 11. Ordered execution and gates

The only approved sequence after this plan is reviewed is:

1. production scalar-action split;
2. production planning split;
3. scalar test split;
4. planning test split;
5. stop with the checkpoint complete.

Each item is a separate reviewed slice and stops before the next begins.
No R03/R04 design or ordinary named-arithmetic action may be absorbed into
these moves.

Each production slice runs the full non-Tier-3 correctness set with the
exact command recorded beside every log: full unit, source guard, ABI
differential, focused fma/`__multi3` canaries, integrated-exe 7/7,
strengthened Tier 2, fresh cohort report/object/owner identities, ratchet,
and frontier/stream watches. It then runs the standing counterbalanced
performance protocol against immutable artifacts frozen only after the
candidate committed tree is final: idle check, two discarded warmups per
artifact, six `AB/BA/AB/BA/AB/BA` pairs, all samples retained, aggregate
median delta at most `max(A*5%,100ms)`, paired-ratio median at most 1.05,
and RSS increase at most 16 MiB. A failed or contaminated batch stops
without a discretionary rerun.

A test-only slice may omit performance only when a tracked hash manifest
proves identical key sets and hashes for:

- every tracked production file under `src/`, excluding test and
  source-guard files;
- every tracked file under `tools/`;
- `build.zig` and every existing build root;
- the external transaction facade and the scalar/planning facades;
- the accepted preceding production tree.

Any difference outside the authorized test/guard/evidence files triggers
the full production performance gate. Regardless of the performance
decision, test-only slices run full unit and source guard and reproduce the
frozen report/object/owner identities and ratchet; the Reviewer may require
the remaining non-Tier-3 gates in the slice directive.

No slice runs Tier 3.

## 12. Explicit deferral: `composed_selector_state.zig`

`composed_selector_state.zig` is 2,730 lines, but it is not part of this
checkpoint. It owns accumulator sessions, value/binding mutation,
spill-slot insertion and restoration, frame allocation, EFLAGS-aware
emission, and other selector-wide state transitions. Splitting it without
a dedicated dependency, snapshot, durable-key, allocator, and ownership
plan would blur the exact boundaries this checkpoint protects.

A future state split therefore requires a separate evidence-only plan and
Reviewer approval. That plan must begin from a re-enumerated symbol/import
inventory and must treat the durable spill-key unit and accumulator
snapshot/rollback authority as indivisible. No checkpoint slice may move a
state declaration merely to improve a line count.

After all four reviewed slices, the ratchet remains 154 and R03/R04 remain
under their named residual owners. Only then may their separate
architectural design resume.
