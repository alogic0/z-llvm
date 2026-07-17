# INBOX-127 O2-R0 refactoring ownership/import plan

Status: **evidence only; architectural review required before R1**

Date: 2026-07-17

Accepted code baseline: commit `aa127e10` (I-B3 accepted; ICMP 44/44)

Working source identity: commit `4e34fe1b2d464391332d9edb172c2baf0bea7463`,
tree `cf0df2af8e3e6f8c50bb033a44df183adb3d320a` (the accepted code plus
Supervisor documentation commits)

Direct-materialization ratchet: **172, unchanged**

Tier 3: **not authorized anywhere in O2-R**

This document plans a structural split of
`src/codegen/x86_64/generic_cfg/composed_selector_value_use_transaction.zig`.
It moves no code, changes no production/test/guard/build source, changes no
diagnostic or capability, and advances no frontier.

## 1. Frozen R0 identities

The monolith is exactly:

| File | Lines | Bytes | SHA-256 |
|---|---:|---:|---|
| `composed_selector_value_use_transaction.zig` | 6,698 | 290,587 | `825abb19d5a24bfa2fc1ccc1c611a4ffc6c620c1d771ad3a026fa5bc866f52e1` |

The complete directly affected import/test/guard/build boundary is:

| File | Lines | SHA-256 |
|---|---:|---|
| `composed_selector_value_use_transaction_tests.zig` | 7,771 | `776a4edf2940cc640b5f2536b6cf4760a9eef9abc11fe21a282ea88786482dac` |
| `composed_selector.zig` | 17 | `77a1ed04e81d6bc44281a2e3535137702b6426939110a01310eaf9d5f62ff7f4` |
| `composed_selector_calls.zig` | 1,264 | `f1046632d670d61439df7252ba12a1ea474829a4b479ed7758ea4e223866cf2d` |
| `composed_selector_cfg.zig` | 1,347 | `3a12b07e2fd9269c1b8f7075559c2f4affbb9554db4ab1894ca77c4e3d204c21` |
| `composed_selector_icmp.zig` | 640 | `09c565220a1dea5fb9a8e2c8d92a587c04f8473328366d5661ef6a0413e2c289` |
| `composed_selector_memory.zig` | 1,058 | `d6e141ea7a0cbc5927015073544b99fba06cd55e6e1958623f90695f55a37f0d` |
| `composed_selector_tests.zig` | 20 | `a49078ebaf3a9725e8d2e9b279674f8f4fe2511ec1f07b6af145d7138c8f4294` |
| `composed_selector_source_guard_tests.zig` | 4,297 | `3cbd6ec717ceefeb24926bca6fa1c4b04dbb29600f0ecae8994a46a601e4a10b` |
| `generic_cfg_selector.zig` | 242 | `55712a6957b865d2ef9afbcc3a2f1dc8f0c25e1f83d8ea5486c3cb0781378d63` |
| `src/main.zig` | 2 | `2dbdadebd518984b5f384d1ac7cab51846537205d435eb14409a0a20ecad8410` |
| `src/tests.zig` | 8 | `14b3abe011810946fb9c93685f41cd79d847c98d19d7f72cd442d4824049ea15` |
| `build.zig` | 424 | `7dc0609438a3b560ab0ee96cd2ec72329ba8327368cd8b177fb6a2f0fa6120a0` |

R1 must record the same table for the committed R1 source tree. R2 must
record it again and compare the production, tools, build configuration, and
facade identities against accepted R1.

## 2. Proposed layout and size budget

The current file remains the compatibility facade. The new leaf layout is:

```text
generic_cfg/
  composed_selector_value_use_transaction.zig       facade
  value_use/
    model.zig
    core.zig
    planning.zig
    materialization.zig
    composition.zig
    actions/
      address_memory.zig
      control_compare.zig
      calls.zig
```

Projected physical line counts include imports, module comments, and
cross-file adapters. They are estimates to be checked after each mechanical
move, not permission to add behavior.

| File | Projected lines | Cohesive owner |
|---|---:|---|
| facade | 90-180 | compatibility export and API-surface assertions only |
| `model.zig` | 1,050-1,250 | inline identities, request/action descriptors, private prepared records, transaction state |
| `core.zig` | 850-1,050 | lifecycle, snapshot, provenance, registration, public method shells, central dispatch |
| `planning.zig` | 1,500-1,800 | seal, compatibility, conflicts, mappings, copy/semantic ordering, early plan |
| `materialization.zig` | 900-1,150 | canonical resolution, prepared records/views, fixed materializers |
| `composition.zig` | 300-450 | subordinate accumulator bridge and durable identity ownership |
| `actions/address_memory.zig` | 1,300-1,550 | GEP/address, store, load actions |
| `actions/control_compare.zig` | 1,700-1,950 | branch/switch and all compare actions/classifiers |
| `actions/calls.zig` | 180-260 | inline memcpy action |

No projected leaf exceeds 2,000 lines. `actions/control_compare.zig` is the
only leaf within 10% of the limit and is therefore a **watch**, not a reviewed
exception. If its committed R1 count exceeds 2,000, R1 must stop for a
Reviewer-approved split; moving code merely to satisfy the count is not
allowed.

## 3. Inventory notation

The inventory covers every file-scope declaration and every declaration at
`ValueUseTransaction` member scope. Function-local variables and local
comptime constants are not cross-file symbols and are excluded.

Error codes:

- `none`: no error union.
- `inferred`: inferred error union; R1 must preserve the exact reachable error
  set and ordering, not replace it with `anyerror`.
- `closed(X)`: explicit closed error set `X`.
- `diag`: inferred errors plus an optional legacy `Diagnostic`.
- `test-only`: `ValueUseTestHookUnavailable` plus no production behavior.

Ownership/rollback codes:

- `inline`: copied into fixed transaction storage; no allocator ownership.
- `borrowed`: valid only during the calling transaction/action.
- `selector-owned`: allocator-backed durable selector identity; outer snapshot
  removes it on rollback and commit retains it.
- `snapshot-owned`: selector allocator allocation owned by `Snapshot.deinit`;
  contents drive the one outer restore.
- `pure`: no mutation and no rollback participation.
- `plan`: mutates transaction-local plan/request/prepared state; automatic
  rollback resets it.
- `outer`: may mutate selector instructions/bindings/spills/counters/EFLAGS/
  labels/dependencies and is covered only by the one outer snapshot.
- `subordinate`: accumulator state mutation has no independent snapshot or
  commit; the outer snapshot restores it.

Visibility in the tables is the **current** visibility. `pub-internal` in the
destination column means a declaration must become technically `pub` only
because Zig has no package-private visibility; it is not a facade export.

## 4. Full symbol-ownership inventory

### 4.1 Imports, aliases, root type, and transaction state

| Current symbol/signature | Current visibility | Destination | Error | Ownership and rollback |
|---|---|---|---|---|
| `std`, `builtin`, `ir`, `x86_64_machine`, `x86_64_types`, `selector_types`, `state_data`, `selector_state`, `stage2_planning`, `address_dependencies`, `eflags`, `constant_table`, `aggregate_object`, `composed_helpers`, `Diagnostic` | file-private imports | only the leaves that use them | none | pure; imports must not be re-exported |
| `ArgReg`, `FrameIndex`, `RegPair`, `ValueBinding`, `ValueLoc`, `VirtualReg`, `VirtualRegClass`, `ComposedBlockSelector`, `AddressDependencyDomain`, `AccumulatorDefinition`, `AccumulatorDefinitionSession`, `AccumulatorDisplacementPolicy`, `AccumulatorPreparationEffect` | file-private aliases | repeat privately in using leaves | none | pure |
| `ValueUseTransaction` | `pub const struct` | `core.zig`; facade aliases this exact type | inferred through methods | owns all inline plan state plus exactly one `Snapshot`; outer rollback owner |
| `selector: *ComposedBlockSelector` | private field | `model.zig` transaction state | none | borrowed selector lifetime |
| `snapshot: Snapshot` | private field | `core.zig` | allocator failure at begin | snapshot-owned; sole state snapshot |
| `requests`, `request_count`, `request_phase`, `lifecycle` | private fields | `model.zig` | none | inline; reset on rollback |
| `write_nodes`, `early_plans`, `semantic_order_edges`, `ordered_operands`, `ordered_operand_count` | private fields | `model.zig` | none | inline planning state; reset on rollback |
| `early_homes`, `early_home_valid`, `prepared_views`, `prepared_view_valid`, `switch_boundary_applied`, `view_generation` | private fields | `model.zig` | none | inline phase-bound state; invalidated/reset by core |
| `action_diagnostic`, `failed_request` | private fields | `core.zig` | none | diagnostic-only; first request failure intentionally survives automatic rollback |
| `accumulator_session` | private field | `composition.zig` | none | subordinate; cleared by outer rollback |
| `memcpy_test_failure`, `load_test_failure`, `scratch_compare_test_failure`, `current_home_eq_zero_test_failure`, `setcc_eax_compare_test_failure`, `current_home_sign_bit_test_failure`, `i128_eq_min_test_failure`, `i128_sign_bit_test_failure` | private `builtin.is_test` fields | corresponding action leaves | test-only | inline test boundary state; never present as capability in production |

### 4.2 `value_use/model.zig`

All declarations in this table are data-model declarations. Methods listed in
parentheses remain owned with their type.

| Current symbol/signature | Current visibility | Destination/API status | Error | Ownership and rollback |
|---|---|---|---|---|
| `max_requests = 16`, `max_identity_bytes = 192`, `max_switch_cases = 8` | public nested constants | model; existing facade surface | none | pure fixed-capacity contract |
| `address_domain_snapshot_copies: usize = 1`, `address_domain_copies_per_request: usize = 0`, `address_domain_snapshot_bytes: usize` | public nested constants | model; existing facade test surface | none | pure metrics contract |
| `Expected { ty, register_class, pointer_address_space }`; `eql(Expected, Expected) bool` | public type/private method | model; existing facade type | none | inline/pure |
| `UseForm` | public enum | model; existing facade type | none | inline semantic intent |
| `Destination`; `eql(Destination, Destination) bool` | public union/private method | model; existing facade type | none | inline physical intent |
| `RequestHandle { authority, index, generation }` | public opaque struct | model; existing facade type | none | inline transaction-local identity |
| `AccumulatorSessionHandle { authority, generation }` | public opaque struct | model; existing facade type | none | inline subordinate identity |
| `PreparedViewLease { request, view_generation }` | public opaque struct | model; existing facade type | none | inline phase-bound capability; no location |
| `ActionIdentity`; `init([]const u8) !ActionIdentity`; `slice(*const ActionIdentity) []const u8`; `validate(*const ActionIdentity) !void` | public type/public constructor/private methods | model; existing facade constructor | identity errors | fixed inline bytes; slice is transaction-local and never a durable key |
| `AddressOffset` | public union | model; existing facade type | none | inline semantic constant/request |
| `PreparedShape` | public union | model; **test-only existing surface**, guard from production | none | inline expected shape, never a discovered location |
| `ByteAddressAction { result, offset }` | public struct | model; existing facade type | none | inline action intent |
| `ScaledAddressAction { result, index, scale, expected_stack_array_len }` | public struct | model; existing facade type | none | inline action intent |
| `ReadOnlyTableAddressAction { result, symbol, shape, scale }` | public struct | model; existing facade type | none | inline action intent |
| `StoreScalarAction { pointer, bits }` | public struct | model; existing facade type | none | inline action intent |
| `StoreImmediateAction { value, bits }` | public struct | model; existing facade type | none | inline action intent |
| `StoreI64Action { value }` | public struct | model; existing facade type | none | inline action intent |
| `StoreStackPointerAction { destination }` | public struct | model; existing facade type | none | inline action intent |
| `MemcpyAction { source, length }` | public struct | model; existing facade type | none | inline action intent |
| `MemcpyTestFailure` | public enum | model; test-only existing surface | test-only | inline test state |
| `ScalarLoadKind` | public enum | model; existing facade type | none | inline action intent |
| `ScalarLoadAction { kind, bits }` | public struct | model; existing facade type | none | inline action intent |
| `ReadOnlyPairLoadAction { result, bits }` | public struct | model; existing facade type | none | inline action intent |
| `StackI128AliasLoadAction { result }` | public struct | model; existing facade type | none | inline action intent |
| `ReadOnlyTableI16LoadAction { result }` | public struct | model; existing facade type | none | inline action intent |
| `LoadRequestError` | public error set | model; existing facade error surface | `closed(LoadRequestError)` | pure semantic diagnostic classes |
| `LoadTestFailure` | public enum | model; test-only existing surface | test-only | inline test state |
| `ScratchCompareRhs` | public union | model; existing facade type | none | inline immediate/null/handle |
| `ScratchCompareAction { result, operand_ty, predicate, samesign, rhs }` | public struct | model; existing facade type | none | inline action intent |
| `ScratchCompareTestFailure` | public enum | model; test-only existing surface | test-only | inline test state |
| `CurrentHomeEqZeroAction { result, operand_ty }` | public struct | model; existing facade type | none | inline action intent |
| `CurrentHomeEqZeroRequestError` | public error set | model; existing facade error surface | `closed(CurrentHomeEqZeroRequestError)` | pure diagnostic classes |
| `CurrentHomeEqZeroTestFailure` | public enum | model; test-only existing surface | test-only | inline test state |
| `SetccEaxCompareStructure` | public enum | model; existing facade type | none | inline action intent |
| `SetccEaxCompareAction { result, operand_ty, predicate, samesign, immediate, structure }` | public struct | model; existing facade type | none | inline action intent |
| `SetccEaxCompareRequestError` | public error set | model; existing facade error surface | `closed(SetccEaxCompareRequestError)` | pure diagnostic classes |
| `SetccEaxCompareTestFailure` | public enum | model; test-only existing surface | test-only | inline test state |
| `CurrentHomeSignBitAction { result, operand_ty }` | public struct | model; existing facade type | none | inline action intent |
| `CurrentHomeSignBitRequestError` | public error set | model; existing facade error surface | `closed(CurrentHomeSignBitRequestError)` | pure diagnostic classes |
| `CurrentHomeSignBitTestFailure` | public enum | model; test-only existing surface | test-only | inline test state |
| `I128EqMinAction { result }`, `I128SignBitAction { result }` | public structs | model; existing facade types | none | inline action intent; pair remains read-only |
| `I128PairRequestError` | public error set | model; existing facade error surface | `closed(I128PairRequestError)` | pure diagnostic classes |
| `I128EqMinTestFailure`, `I128SignBitTestFailure` | public enums | model; test-only existing surface | test-only | inline test state |
| `SwitchCaseIntent { value, target }` | public struct | model; existing facade type | none | borrowed only during `init` |
| `SwitchCompareChainAction`; `init(bits, []const SwitchCaseIntent, []const u8, ?u8) !SwitchCompareChainAction`; `validate(*const SwitchCompareChainAction) !void` | public type/public constructor/private validator | model; existing facade constructor | switch width/count/identity/duplicate/exhaustive errors | fixed-owned identities and cases; no borrowed slice survives |
| `PreparedAction`; `eql(PreparedAction, PreparedAction) bool` | public central union/private method | **model, frozen owner**; existing facade type | none | inline closed action intent |
| `CopyDestination`; `asDestination(CopyDestination) Destination` | public union/private method | model; existing facade type | none | inline/pure |
| `PreparedIdentity`; `init`, `slice`, `eql` | private type/methods | model, pub-internal only if another leaf needs it | identity errors | fixed inline prepared identity |
| `PreparedRegister`, `PreparedScalarHome`, `PreparedStackObject`, `PreparedAddressComponent`, `PreparedAddressDescriptor`, `PreparedStackF32PairAddress`, `PreparedTablePointer`, `PreparedPairLimb`, `PreparedReadOnlyPair`, `PreparedCondition`, `PreparedView`, `PreparedRecord` | private types | model, pub-internal | none | inline opaque prepared representation; never facade-visible |
| `EarlyPlan`, `OperandPhase`, `OrderedOperand`, `SemanticRole`, `EarlyPreparedHome` | private types | model, pub-internal to planning/core | none | inline plan state; outer rollback resets |
| `Request { source, expected, form, destination, prepared_action }` | public struct | model; existing facade type | none | caller intent copied at registration |
| `RequestPhase` | public enum | model; existing facade test/introspection surface | none | inline lifecycle state |
| `Lifecycle` | private enum | model, pub-internal to core | none | inline outer lifecycle |
| `Identity`; `init`, `slice`, `eql` | private type/methods | model, pub-internal | identity errors | fixed inline registered source identity |
| `Source`; `from(ir.Value) !Source`; `eql`; `value` | private union/methods | model, pub-internal | identity errors | fixed inline source; returned `ir.Value` borrows inline bytes |
| `StoredRequest`; `eql` | private struct/method | model, pub-internal | none | fixed inline sealed request |
| `PhysicalNode`, `physical_node_count`, `max_mappings` | private enum/constants | model, pub-internal to planning/materialization/actions | none | pure closed physical graph |

### 4.3 `value_use/core.zig`

| Current symbol/signature | Current visibility | Destination/API status | Error | Ownership and rollback |
|---|---|---|---|---|
| `ValueEntry`, `SpillEntry`, `PhiDestinationEntry` | private structs | core private | none | snapshot borrowed keys plus copied values |
| `Snapshot.init(*ComposedBlockSelector) !Snapshot` | private | core private | allocator failure | allocates values/spills/PHI arrays; captures instructions, labels, counters, domains, EFLAGS |
| `Snapshot.restore(*const Snapshot, *ComposedBlockSelector) void` | private | core private | none | sole rollback: truncate instructions, free speculative labels once, restore all captured state |
| `Snapshot.deinit(*Snapshot, *ComposedBlockSelector) void` | private | core private | none | frees the three snapshot arrays exactly once |
| `begin(*ComposedBlockSelector) !ValueUseTransaction` | public method | core; existing facade method | allocator failure | creates exactly one snapshot |
| `deinit(*ValueUseTransaction) void` | public method | core; existing facade method | none | auto-rolls back active authority, then frees snapshot |
| `register(*ValueUseTransaction, Request) !RequestHandle` | public method | core; existing facade method | phase/capacity/identity/duplicate compatibility | copies request inline; no selector mutation |
| `attachScratchCompareAction(*ValueUseTransaction, RequestHandle, ScratchCompareAction) !void` | public method | core thin adapter; existing facade method | handle/action/source-order validation | plan-only mutation |
| `seal(*ValueUseTransaction) !void` | public method | core wrapper over `planning.seal` | inferred planning errors | no selector mutation; seals full graph |
| `prepare(*ValueUseTransaction) !void` | public method | core wrapper over planning/materialization | inferred | outer mutations; auto-rollback |
| `applySwitchBoundary(*ValueUseTransaction, RequestHandle) !void` | public method | core | phase/action plus CFG spill/restore errors | outer mutation before deferred source resolution |
| `materializeAll(*ValueUseTransaction) !void` | public method | core wrapper over materialization | inferred/request-scoped | outer mutation; fixed requests first, views last |
| `preparedView(*ValueUseTransaction, RequestHandle) !PreparedViewLease` | public method | core; existing opaque facade method | stale/phase/missing/handle | phase-only; exposes no location |
| `executePreparedAction(*ValueUseTransaction, PreparedViewLease) !void` | public method | **core, frozen sole dispatch owner** | inferred/action/request errors | outer mutation; canonical pre/post validation; auto-rollback |
| `commit(*ValueUseTransaction) !void` | public method | core; existing facade method | phase/result-not-finalized | sole commit; retains outer effects |
| `rollback(*ValueUseTransaction) !void` | public method | core; existing facade method | transaction-closed | invokes sole restore |
| `requestCount(*const ValueUseTransaction) usize`, `phase(*const ValueUseTransaction) RequestPhase` | public methods | core; existing facade test surface | none | pure |
| `actionDiagnostic(*const ValueUseTransaction) ?Diagnostic` | public method | core; existing guarded mapper surface | none | read-only diagnostic after rollback |
| `failedRequestIs(*const ValueUseTransaction, RequestHandle) bool` | public method | core; exact guarded production mapper surface | none | read-only first-failure comparison; no identity/home exposure |
| all eight `set*TestFailure(*ValueUseTransaction, ?Failure) !void` methods | public methods | core wrappers to action test state; test-only existing surface | `test-only` | plan/test state only |
| `requireActive(*const ValueUseTransaction) !void` | private | core private | `ValueUseTransactionClosed` | pure validation |
| `rollbackInternal(*ValueUseTransaction) void` | private | core private | none | sole automatic restore/reset; preserves diagnostic provenance |
| `handleFor(*ValueUseTransaction, u8) RequestHandle`, `validateHandle(*ValueUseTransaction, RequestHandle) !u8` | private | core private/pub-internal only if leaf adapter requires | foreign/stale/index | pure |
| `recordRequestFailure(*ValueUseTransaction, u8) void`, `noteRequestBoundaryError(*ValueUseTransaction, u8, anyerror) void` | private | core private with narrow internal callback | none | records first attributable failure exactly once |
| `validateRegisteredOperandHandle`, `noteRegisteredOperandBoundaryError` | private methods | core private/internal callback | handle/phase errors | provenance only |
| `registeredOperandCurrent(*ValueUseTransaction, RequestHandle) !ValueLoc`, `registeredOperandView(*ValueUseTransaction, RequestHandle) !*const PreparedView` | private methods | core internal seam used only by closed actions | request/home/stale errors | borrowed canonical value valid only inside the action execution call |
| `validateActionRegistration(*ValueUseTransaction, PreparedAction) !void` | private method | core (union exhaustiveness owner) | action/handle/shape errors | no selector mutation |
| `validateActionDependenciesCanonical`, `validateConsumedActionAfter`, `validateConsumedOperandAfter`, `validateConsumedOperandAfterUnchecked`, `validateOperandCanonical` | private methods | core | dependency/stale/binding errors | read-only canonical checks; failures auto-rollback |
| `optionalPreparedActionEql(?PreparedAction, ?PreparedAction) bool` | file-private | core private | none | pure |

### 4.4 `value_use/planning.zig`

| Current symbol/signature | Current visibility | Destination | Error | Ownership and rollback |
|---|---|---|---|---|
| `NodeList`; `append(*NodeList, PhysicalNode) !void`; `slice(*const NodeList)` | private | planning private | capacity | fixed inline |
| `Mapping`, `MappingList`; `append`, `slice` | private | planning private | none | fixed inline |
| `validateRequestAt(*Transaction, u8) !?ValueLoc`, `validateRequest(*Transaction, *const StoredRequest) !?ValueLoc` | private methods | planning pub-internal | resolution/dependency/type/home | read-only canonical resolution; provenance applied by core |
| `validateSemanticOrderTopology(*Transaction) !void` | private method | planning pub-internal | early-order conflict/cycle | plan only |
| `actionSecondaryOperand`, `actionTertiaryOperand` | private methods | planning private | handle/action errors | pure relationship derivation |
| `resetSemanticOrderPlan(*Transaction) void` | private method | planning private | none | resets inline plan |
| `planEarlyMaterializations(*Transaction, []const Mapping) !void` | private method | planning pub-internal | ordering/capacity/cycle | inline plan only |
| `appendOrderedOperand`, `sortSemanticRoots`, `semanticRootLessThan`, `firstStructuralDestination` | private methods | planning private | inferred only on append | inline deterministic role order |
| `validateEarlyHome`, `validateEarlyHomeUnchecked` | private methods | planning pub-internal | stale/unresolved/binding | read-only canonical validation |
| `validateFormAndDestination(*const StoredRequest) !void` | file-private | planning pub-internal | closed form/destination/action errors | pure |
| `validateBindingCompatibility(ValueBinding, *const StoredRequest, ValueLoc) !void` | file-private | planning pub-internal | class/bits/home/load/action errors | pure; sole semantic compatibility authority |
| `validateScratchCompareBinding`, `validateOrdinaryLoadHome`, `validateReadOnlyPointerLoadHome`, `validateReadOnlyTableLoadHome` | file-private | planning private | compare/load closed errors | pure |
| `hasLow32View(ValueLoc) bool` | file-private | planning private | none | pure |
| `validateExpectedType(Expected, UseForm) !void`, `validateSourceView(ValueLoc, UseForm) !void` | file-private | planning private | type/class/source errors | pure |
| `earlyCopyIsFlagsPreserving(ValueLoc, UseForm) bool`, `earlySequencingCandidate(ValueLoc, UseForm) bool` | file-private | planning private | none | pure |
| `requestDestinationNodes(*Transaction, *const StoredRequest, ?ValueLoc) !NodeList` | file-private | planning pub-internal | inferred | pure graph derivation |
| `requestMappings(*Transaction, *const StoredRequest, u8, ?ValueLoc) !MappingList` | file-private | planning pub-internal | inferred | pure graph derivation |
| `actionOwnsOrderedWrites(PreparedAction) bool` | file-private | planning pub-internal and core | none | pure exhaustive union classification |
| `validateStorePointerOperand`, `validateStoreI64ValueOperand`, `validateStoreStackObjectOperand`, `validateMemcpyPointerOperand`, `validateMemcpyLengthOperand` | file-private | planning private | closed form/type errors | pure |
| `appendStorePointerDestinationNodes`, `appendStorePointerMappings` | file-private | planning private | inferred | pure fixed graph construction |
| `validateI64StorePointer`, `validateStackPointerStoreViews`, `validateCopyActionForm` | file-private | planning private | closed action/home errors | pure |
| `scalarSourceNode`, `pairSourceNodes`, `nodeForArgReg`, `argRegForNode` | file-private | planning pub-internal where actions need node identity | none | pure |
| `rejectCopyCycles`, `visitCopyNode`, `CopyVisitState` | file-private | planning private | `ValueUseCopyCycleRequiresO4` | pure pre-mutation graph traversal |
| `rejectSemanticOrderCycles`, `visitSemanticOrderNode` | file-private | planning private | `ValueUseEarlyOrderingConflict` | pure pre-mutation graph traversal |
| `firstMappingDestination`, `sourceStructuralOrder` | file-private | planning private | none | pure deterministic ordering |

### 4.5 `value_use/materialization.zig`

| Current symbol/signature | Current visibility | Destination | Error | Ownership and rollback |
|---|---|---|---|---|
| `resolveNamedCurrent(*Transaction, []const u8) !ValueLoc` | private method | materialization pub-internal | unresolved/location | read-only; returned location must not cross mutation |
| `buildPreparedRecord`, `buildPreparedRecordUnchecked` | private methods | materialization pub-internal | type/home/dependency/stale | inline opaque record; no escape |
| `preparedViewFromLoc(*Transaction, *const StoredRequest, ValueLoc) !PreparedView` | file-private | materialization private | view/type/dependency | inline opaque view |
| `preparedMemcpyScalarView`, `preparedScratchCompareView`, `preparedConditionView`, `preparedStackF32PairAddressView`, `preparedScalarView`, `preparedPointerView`, `preparedStackObjectView`, `preparedPairView` | file-private | materialization pub-internal only where action leaf needs it | closed unsupported-view errors | pure adapters returning opaque inline views |
| `preparedAddressDescriptor`, `requireDependencyRole`, `preparedAddressComponent` | file-private | materialization private | missing/stale/role dependency errors | validates canonical domain; no edge creation |
| `preparedScalarHome` | file-private | materialization private | unsupported view | pure |
| `materializeEarlyPlans`, `materializeEarlyPlan` | private methods | materialization pub-internal | inferred | outer instructions/bindings plus inline prepared home; rollback covered |
| `materializeRequest`, `materializeRequestUnchecked`, `materializeRequestFromLoc` | private methods | materialization pub-internal | inferred | outer mutations; current `ValueLoc` consumed immediately |
| `validatePreparedShape(*const PreparedView, PreparedShape) !void` | file-private | materialization **test-only internal** | shape mismatch | pure; production guard forbids use |
| `preparedViewLoc(*const PreparedView) !ValueLoc` | file-private | materialization internal only; never facade | unsupported prepared view | borrows private representation within action call |
| `preparedRecordEql`, `preparedViewEql`, `preparedStackObjectEql`, `preparedAddressDescriptorEql`, `preparedAddressComponentEql`, `preparedTablePointerEql` | file-private | materialization private | none | pure canonical/staleness comparison |
| `clobberPhysicalNode(*Selector, PhysicalNode) !void` | file-private | materialization pub-internal | selector clobber/preservation errors | outer mutation |
| `materializeScalar32`, `materializeScalar64`, `materializeByteAddressPointer`, `materializePointer`, `materializeStackAddress`, `materializePair`, `materializePairLimb`, `materializeNull` | file-private | materialization pub-internal | source/home/range/selector errors | outer instructions only; no independent ownership |

### 4.6 `value_use/composition.zig`

| Current symbol/signature | Current visibility | Destination/API status | Error | Ownership and rollback |
|---|---|---|---|---|
| `beginAccumulatorSession(*Transaction) !AccumulatorSessionHandle` | public method | core wrapper, body in composition | phase/already-open | subordinate; zero snapshots |
| `prepareAccumulator(*Transaction, handle, effect, displacement) !?Diagnostic` | public method | core wrapper, body in composition | `diag` | subordinate outer-covered mutation |
| `prepareAccumulatorCallBeforeArguments(*Transaction, handle, effect) !?Diagnostic` | public method | core wrapper, body in composition | `diag` | subordinate outer-covered mutation |
| `finishAccumulatorCallPreparationAfterArguments(*Transaction, handle) !void` | public method | core wrapper, body in composition | inferred | subordinate outer-covered mutation |
| `materializeAccumulator(*Transaction, handle, ir.Value, AccumulatorDefinition) !void` | public method | core wrapper, body in composition | inferred | subordinate; canonical post-prepare resolution |
| `spillAccumulatorValue(*Transaction, handle, []const u8) !void` | public method | core wrapper, body in composition | inferred | subordinate spill |
| `defineAccumulatorResult(*Transaction, handle, []const u8, AccumulatorDefinition) !void` | public method | core wrapper, body in composition | inferred | durable binding, outer-owned |
| `finalizeAccumulatorResult(*Transaction, handle) !void` | public method | core wrapper, body in composition | inferred | marks subordinate finalized |
| `commitAccumulatorSession(*Transaction, handle) !void` | public method | core wrapper, body in composition | always `ValueUseAccumulatorIndependentCommit` after handle validation | no independent commit |
| `validateAccumulatorSession(*Transaction, handle) !*AccumulatorDefinitionSession` | private method | composition pub-internal | foreign/stale/closed | pure validation |
| `ownActionIdentity(*Transaction, *const ActionIdentity) ![]const u8` | file-private | composition pub-internal to actions | allocator/identity | selector-owned durable copy; rollback frees via owned identity tracking |
| `ownRegisteredOperandName(*Transaction, RequestHandle) ![]const u8` | file-private | composition pub-internal to address actions | handle/source/allocator | selector-owned durable copy; rollback covered |

### 4.7 `actions/address_memory.zig`

The semantic descriptor types remain in `model.zig`; this leaf owns their
execution only.

| Current symbol/signature | Current visibility | Error | Ownership and rollback |
|---|---|---|---|
| `executeByteAddress(*Transaction, *const PreparedView, *const StoredRequest, ByteAddressAction) !void` | file-private -> pub-internal entrypoint | range/address/dependency/materialization/allocator | constant descriptor has no write; dynamic formation and durable result are outer-owned |
| `executeScaledAddress(..., ScaledAddressAction) !void` | file-private -> pub-internal entrypoint | scale/range/address/dependency/materialization/allocator | outer instructions/dependency/result binding |
| `executeReadOnlyTableAddress(..., ReadOnlyTableAddressAction) !void` | file-private -> pub-internal entrypoint | scale/identity/materialization/allocator | symbol/result copies selector-owned; outer rollback |
| `scaleShift(u8) !u6`, `scaledOffset(i32, u8) !i32` | file-private | unsupported scale/overflow | pure |
| `executeStoreScalar`, `executeStoreImmediate`, `executeStoreI64`, `executeStoreStackPointer` | file-private -> pub-internal action entries | inferred store/home/action errors | outer staging/store/binding mutations |
| `executeStoreEaxToPointer`, `executeStoreStackI32`, `appendStoreEaxStack` | file-private | inferred | outer instructions; helpers never start a transaction |
| `materializeActionScalar32`, `materializeActionScalar64`, `materializeActionPointer`, `materializeActionScalarHome`, `clobberActionDestination`, `stackScalarFromPreparedView` | file-private | inferred closed home/materialization errors | outer mutation or pure private-view adapter |
| `executeScalarLoad(*Transaction, u8, *const PreparedView, ScalarLoadAction) !void` | file-private -> pub-internal entrypoint | load closed errors/inferred selector errors | outer load; scalar result subordinate |
| `prepareScalarLoadAccumulator`, `refreshLoadPreparedOperand` | file-private | inferred | subordinate preparation/canonical refresh |
| `executeOrdinaryScalarLoad`, `appendPreparedLoadStackI32`, `appendPreparedLoadStackU64IntoRax`, `preparedScalarHomeLoc` | file-private | inferred | outer instructions; last is pure |
| `executeReadOnlyScalarLoad`, `stageReadOnlyScalarLoadPointer`, `materializePreparedLoadPointer` | file-private | load staging/width/home errors | outer staging/load |
| `executeReadOnlyPairLoad` | file-private -> pub-internal action entry | pair chooser/materializer/load errors | existing pair authority only; no accumulator session; durable result outer-owned |
| `executeStackI128AliasLoad` | file-private -> pub-internal action entry | home/identity/allocator | alias-only durable binding outer-owned |
| `executeReadOnlyTableI16Load` | file-private -> pub-internal action entry | table home/type/staging/identity | R8 result binding outer-owned; no accumulator session |
| `failLoadForTest` | file-private | test-only injected failure | triggers outer rollback |

### 4.8 `actions/control_compare.zig`

| Current symbol/signature | Current visibility | Error | Ownership and rollback |
|---|---|---|---|
| `isCurrentHomeSignBitIcmp(ir.IcmpInst) bool`, `isI128EqMinIcmp(ir.IcmpInst) bool`, `isI128SignBitIcmp(ir.IcmpInst) bool` | public nested -> facade-visible unchanged | none | pure IR-only classifiers |
| `ScratchCompareKind`, `ScratchComparePlan`, `classifyScratchCompare(*const ScratchCompareAction) !ScratchComparePlan` | file-private | predicate/type/immediate/form errors | pure |
| `executeScratchCompare` | file-private -> pub-internal action entry | inferred/request-scoped | outer staging/EFLAGS/setcc; result subordinate and durable |
| `preserveScratchCompareLiveAccumulator`, `refreshScratchCompareOperandViews`, `stageScratchCompareOperand`, `stageScratchCompareOperandUnchecked` | file-private | inferred | outer preservation/staging; canonical refresh |
| `failScratchCompareForTest` | file-private | test-only | outer rollback |
| `CurrentHomeEqZeroTest`, `classifyCurrentHomeEqZero(...) CurrentHomeEqZeroRequestError!CurrentHomeEqZeroTest` | file-private | closed eq-zero request errors | pure |
| `executeCurrentHomeEqZero` | file-private -> pub-internal action entry | inferred/request-scoped | outer test/EFLAGS/sete; result subordinate and durable |
| `failCurrentHomeEqZeroForTest` | file-private | test-only | outer rollback |
| `SetccEaxComparePlan`, `classifySetccEaxCompare(*const SetccEaxCompareAction) !SetccEaxComparePlan` | file-private | predicate/type/immediate errors | pure |
| `executeSetccEaxCompare` | file-private -> pub-internal action entry | inferred/request-scoped | outer preamble/mask/compare/setcc; subordinate result |
| `validateSetccEaxCompareHome(...) SetccEaxCompareRequestError!void` | file-private | closed setcc request errors | pure |
| `failSetccEaxCompareForTest` | file-private | test-only | outer rollback |
| `CurrentHomeSignBitPlan`, `classifyCurrentHomeSignBit(...) CurrentHomeSignBitRequestError!CurrentHomeSignBitPlan` | file-private | closed sign-bit errors | pure |
| `executeCurrentHomeSignBit` | file-private -> pub-internal action entry | inferred/request-scoped | outer preservation/SHR incidental write; subordinate result |
| `validateCurrentHomeSignBitHome`, `preserveCurrentHomeSignBitLiveAccumulator` | file-private | closed home errors/inferred preservation | pure validation or outer preservation |
| `failCurrentHomeSignBitForTest` | file-private | test-only | outer rollback |
| `executeI128EqMin`, `executeI128SignBit` | file-private -> pub-internal action entries | inferred/pair request errors | wrap existing read-only pair helpers; outer reload/EFLAGS; subordinate result |
| `refreshAndValidateI128PairSource`, `validateI128PairHome` | file-private | inferred/closed pair errors | canonical read-only pair resolution |
| `failI128EqMinForTest`, `failI128SignBitForTest` | file-private | test-only | outer rollback |
| `executeBranchCondition` | file-private -> pub-internal action entry | condition-home/EFLAGS errors | outer test; commits EFLAGS definition for caller |
| `executeSwitchCompareChain` | file-private -> pub-internal action entry | switch/identity/EFLAGS errors | outer compare chain; durable target copies outer-owned |
| `switchConditionMask`, `validateDeferredSwitchRequest` | file-private | pure/closed switch errors | pure |
| `restoreSwitchDisplacedPhiDestinations` | file-private | selector restoration errors | outer mutation before deferred condition resolution |

### 4.9 `actions/calls.zig`

| Current symbol/signature | Current visibility | Error | Ownership and rollback |
|---|---|---|---|
| `executeInlineMemcpy(*Transaction, u8, MemcpyAction) !void` | file-private -> pub-internal action entry | request/provenance/caller-clobber/EFLAGS/action errors | one outer authority owns caller preservation, RDI/RSI/RDX staging, call append |
| `refreshMemcpyPreparedOperand(*Transaction, u8) !void` | file-private | canonical stale/request errors | re-derives inline prepared record |
| `materializeMemcpyHandle(*Transaction, RequestHandle, ArgReg) !void` | file-private | handle/request errors | outer staging |
| `materializeMemcpyRequest`, `materializeMemcpyRequestUnchecked` | file-private | request/home/materialization errors | outer staging; exact destination-source-length order |
| `failMemcpyForTest` | file-private | test-only | outer rollback |

### 4.10 Central dispatch ownership

`executePreparedActionInternal(*Transaction, u8, *const PreparedView,
*const StoredRequest, PreparedAction) !void` moves to `core.zig` and remains
the **only exhaustive switch over execution**. `PreparedAction` itself remains
in `model.zig`. The dispatch imports the three action leaves and calls only
their technically-public internal entrypoints.

Action leaves:

- may import `model`, `materialization`, and `composition`;
- may not import `core`;
- may not invoke `begin`, `commit`, `rollback`, or create a snapshot;
- may not dispatch another action;
- may not import one another;
- may not export anything through the compatibility facade.

Planning may import `actions/control_compare` only for the pure
scratch-compare classifier needed to derive writes/mappings. It derives all
other mappings exhaustively from model descriptors. Action leaves may **not**
import planning. This fixes the direction and prevents a planning/action
cycle.

## 5. Thin facade contract

The facade remains at the existing path, so current production imports do not
move. Its implementation target is under 180 lines and its hard ceiling is
800. It exports one named type:

```zig
pub const ValueUseTransaction = core.ValueUseTransaction;
```

The facade must preserve, and must not add to, the following production-visible
nested contract.

Types/constants used or legally available to production:

```text
max_requests
max_identity_bytes
max_switch_cases
Expected
UseForm
Destination
RequestHandle
AccumulatorSessionHandle
PreparedViewLease
ActionIdentity (+ ActionIdentity.init)
AddressOffset
ByteAddressAction
ScaledAddressAction
ReadOnlyTableAddressAction
StoreScalarAction
StoreImmediateAction
StoreI64Action
StoreStackPointerAction
MemcpyAction
ScalarLoadKind
ScalarLoadAction
ReadOnlyPairLoadAction
StackI128AliasLoadAction
ReadOnlyTableI16LoadAction
LoadRequestError
ScratchCompareRhs
ScratchCompareAction
CurrentHomeEqZeroAction
CurrentHomeEqZeroRequestError
SetccEaxCompareStructure
SetccEaxCompareAction
SetccEaxCompareRequestError
CurrentHomeSignBitAction
CurrentHomeSignBitRequestError
I128EqMinAction
I128SignBitAction
I128PairRequestError
SwitchCaseIntent
SwitchCompareChainAction (+ SwitchCompareChainAction.init)
PreparedAction
CopyDestination
Request
RequestPhase
```

Production-callable methods/classifiers:

```text
begin
deinit
register
attachScratchCompareAction
seal
prepare
applySwitchBoundary
materializeAll
preparedView
beginAccumulatorSession
prepareAccumulator
prepareAccumulatorCallBeforeArguments
finishAccumulatorCallPreparationAfterArguments
materializeAccumulator
spillAccumulatorValue
defineAccumulatorResult
finalizeAccumulatorResult
commitAccumulatorSession
executePreparedAction
commit
rollback
requestCount
phase
actionDiagnostic
failedRequestIs
isCurrentHomeSignBitIcmp
isI128EqMinIcmp
isI128SignBitIcmp
```

The following currently-public members are retained only because tests already
compile against them. A guard must reject their use from production:

```text
address_domain_snapshot_copies
address_domain_copies_per_request
address_domain_snapshot_bytes
PreparedShape
MemcpyTestFailure / setMemcpyTestFailure
LoadTestFailure / setLoadTestFailure
ScratchCompareTestFailure / setScratchCompareTestFailure
CurrentHomeEqZeroTestFailure / setCurrentHomeEqZeroTestFailure
SetccEaxCompareTestFailure / setSetccEaxCompareTestFailure
CurrentHomeSignBitTestFailure / setCurrentHomeSignBitTestFailure
I128EqMinTestFailure / setI128EqMinTestFailure
I128SignBitTestFailure / setI128SignBitTestFailure
```

R1 must generate an exact sorted manifest of the facade's public declarations
and compare it with the R0 list above. An addition is a hard failure. A removal
or signature/error change is also a hard failure unless separately reviewed;
“must not widen” is not permission to narrow compatibility during a mechanical
split.

## 6. Cross-file declarations that become technically `pub`

These are internal visibility seams, not facade exports.

| Leaf | Technically-public declarations |
|---|---|
| `model.zig` | `TransactionState`/the state fields needed by core; all model types named in §4.2; private prepared types (`PreparedIdentity`, all `Prepared*`, `EarlyPlan`, ordering types, `Identity`, `Source`, `StoredRequest`, `PhysicalNode`) and fixed constants used by another leaf |
| `planning.zig` | `seal`, `validateRequestAt`, `validateRequest`, `planEarlyMaterializations`, `validateEarlyHome`, `requestDestinationNodes`, `requestMappings`, `actionOwnsOrderedWrites`, node/register conversion helpers needed by core/materialization |
| `materialization.zig` | `materializeAll`, early/request materializers, `resolveNamedCurrent`, prepared-record construction/validation, opaque prepared adapters needed by action leaves, physical clobber and scalar/pointer/pair/null materializers |
| `composition.zig` | subordinate-session operations, `ownActionIdentity`, `ownRegisteredOperandName` |
| `actions/address_memory.zig` | only its address/store/load `execute*` entrypoints |
| `actions/control_compare.zig` | only its branch/switch/compare `execute*` entrypoints, three existing public classifiers, and pure classifier helpers explicitly required by planning |
| `actions/calls.zig` | only `executeInlineMemcpy` |

The exact technically-public internal name budget is:

```text
model:
  Transaction
  Expected UseForm Destination RequestHandle AccumulatorSessionHandle
  PreparedViewLease ActionIdentity AddressOffset PreparedShape
  ByteAddressAction ScaledAddressAction ReadOnlyTableAddressAction
  StoreScalarAction StoreImmediateAction StoreI64Action
  StoreStackPointerAction MemcpyAction MemcpyTestFailure
  ScalarLoadKind ScalarLoadAction ReadOnlyPairLoadAction
  StackI128AliasLoadAction ReadOnlyTableI16LoadAction LoadRequestError
  LoadTestFailure ScratchCompareRhs ScratchCompareAction
  ScratchCompareTestFailure CurrentHomeEqZeroAction
  CurrentHomeEqZeroRequestError CurrentHomeEqZeroTestFailure
  SetccEaxCompareStructure SetccEaxCompareAction
  SetccEaxCompareRequestError SetccEaxCompareTestFailure
  CurrentHomeSignBitAction CurrentHomeSignBitRequestError
  CurrentHomeSignBitTestFailure I128EqMinAction I128SignBitAction
  I128PairRequestError I128EqMinTestFailure I128SignBitTestFailure
  SwitchCaseIntent SwitchCompareChainAction PreparedAction CopyDestination
  Request RequestPhase PreparedIdentity PreparedRegister PreparedScalarHome
  PreparedStackObject PreparedAddressComponent PreparedAddressDescriptor
  PreparedStackF32PairAddress PreparedTablePointer PreparedPairLimb
  PreparedReadOnlyPair PreparedCondition PreparedView PreparedRecord
  EarlyPlan OperandPhase OrderedOperand SemanticRole EarlyPreparedHome
  Lifecycle Identity Source StoredRequest PhysicalNode
  max_requests max_identity_bytes max_switch_cases physical_node_count
  max_mappings address_domain_snapshot_copies
  address_domain_copies_per_request address_domain_snapshot_bytes

planning:
  seal validateRequestAt validateRequest validateSemanticOrderTopology
  planEarlyMaterializations validateEarlyHome
  validateFormAndDestination validateBindingCompatibility
  requestDestinationNodes requestMappings actionOwnsOrderedWrites
  scalarSourceNode pairSourceNodes nodeForArgReg argRegForNode

materialization:
  prepare materializeAll materializeEarlyPlans materializeRequest
  resolveNamedCurrent buildPreparedRecord preparedViewFromLoc
  preparedMemcpyScalarView preparedScratchCompareView preparedConditionView
  preparedStackF32PairAddressView preparedScalarView preparedPointerView
  preparedStackObjectView preparedPairView validatePreparedShape
  preparedViewLoc preparedRecordEql clobberPhysicalNode materializeScalar32
  materializeScalar64 materializeByteAddressPointer materializePointer
  materializeStackAddress materializePair materializePairLimb materializeNull

composition:
  beginAccumulatorSession prepareAccumulator
  prepareAccumulatorCallBeforeArguments
  finishAccumulatorCallPreparationAfterArguments materializeAccumulator
  spillAccumulatorValue defineAccumulatorResult finalizeAccumulatorResult
  commitAccumulatorSession ownActionIdentity ownRegisteredOperandName

actions/address_memory:
  executeByteAddress executeScaledAddress executeReadOnlyTableAddress
  executeStoreScalar executeStoreImmediate executeStoreI64
  executeStoreStackPointer executeScalarLoad executeReadOnlyPairLoad
  executeStackI128AliasLoad executeReadOnlyTableI16Load

actions/control_compare:
  executeScratchCompare executeCurrentHomeEqZero executeSetccEaxCompare
  executeCurrentHomeSignBit executeI128EqMin executeI128SignBit
  executeBranchCondition executeSwitchCompareChain classifyScratchCompare
  isCurrentHomeSignBitIcmp isI128EqMinIcmp isI128SignBitIcmp

actions/calls:
  executeInlineMemcpy
```

R1 may reduce this budget by replacing an internal cross-file call with a
cohesive move into one owner. It may not add a name without amending this plan
in review. The guard compares this exact name set per leaf.

No private prepared representation, `ValueLoc`, `Snapshot`, mapper, retry
capability, or action helper becomes a facade export. Where action leaves need
transaction internals, R1 should pass a narrow internal context or use
internal generic parameters; it must not expose those internals to production.

The source guard must enforce:

1. Production `composed_selector_*.zig` files may import only
   `composed_selector_value_use_transaction.zig`, never a path containing
   `/value_use/` or `value_use/`.
2. The facade may import `value_use/core.zig` only.
3. Internal module imports match the frozen DAG in §7.
4. The facade public-declaration manifest matches §5 exactly.
5. Action leaves do not declare `begin`, `commit`, `rollback`, snapshot
   creation, or public raw-location/prepared-view accessors.
6. `validatePreparedShape` remains test-only and no production source calls it.
7. No production consumer imports or calls a technically-public internal
   declaration.

Negative fixtures must cover a production direct-leaf import, a new facade
export, an action-to-core import, an action-to-action import, and a production
use of a test-only facade member.

## 7. Complete import DAG

### 7.1 Planned internal graph

Edges point from importer to imported module:

```text
facade
  -> value_use/core

value_use/core
  -> value_use/model
  -> value_use/planning
  -> value_use/materialization
  -> value_use/composition
  -> actions/address_memory
  -> actions/control_compare
  -> actions/calls

value_use/planning
  -> value_use/model
  -> actions/control_compare      (pure planning classifiers only)

actions/address_memory
  -> value_use/model
  -> value_use/materialization
  -> value_use/composition

actions/control_compare
  -> value_use/model
  -> value_use/materialization
  -> value_use/composition

actions/calls
  -> value_use/model
  -> value_use/materialization

value_use/materialization
  -> value_use/model

value_use/composition
  -> value_use/model
  -> value_use/materialization

value_use/model
  -> existing foundational IR/machine/selector type modules only
```

Topological leaf order:

```text
model
materialization
composition
address_memory | control_compare | calls
planning
core
facade
```

This graph is acyclic. There is **no unavoidable cycle requiring a Reviewer
ruling** in the proposed graph. The fragile edge is planning-to-actions for
pure action classifiers. If a moved action requires planning at implementation
time, R1 must stop rather than add the reverse edge. The allowed resolution is
to move the pure classification data into `model`, not create a cycle.

The concrete Zig type construction is also frozen by this plan. `model.zig`
defines `Transaction(comptime Impl: type) type`, containing the fields and
thin public method forwarders. `core.zig` defines `Impl` as free functions and
exports `pub const ValueUseTransaction = model.Transaction(Impl)`. Internal
leaves accept that transaction through internal generic parameters; they are
not public callbacks and never receive or return an unchecked prepared
representation. This is how methods remain callable with their exact current
signatures without making `model` import `core` or making actions import
`core`. The facade imports only `core` and aliases
`core.ValueUseTransaction`.

### 7.2 Production import roots

Current direct importers remain unchanged:

```text
composed_selector_calls.zig  -> facade
composed_selector_cfg.zig    -> facade
composed_selector_icmp.zig   -> facade
composed_selector_memory.zig -> facade
composed_selector.zig        -> facade (re-export of ValueUseTransaction)
```

The enclosing production root is:

```text
build.zig
  -> src/main.zig
  -> src/main_logic.zig / codegen entry
  -> src/codegen/x86_64/generic_cfg_selector.zig
  -> generic_cfg/composed_selector.zig
  -> composed selector implementation modules
  -> facade
  -> internal DAG
```

### 7.3 Test, guard, and build roots

Current test root:

```text
build.zig
  -> src/tests.zig
  -> src/tests/codegen_x86_64_generic_cfg_selector.zig
  -> generic_cfg_selector.zig
  -> composed_selector.zig test block
  -> composed_selector_tests.zig
     -> composed_selector_value_use_transaction_tests.zig
     -> composed_selector_source_guard_tests.zig
     -> all existing selector test modules
```

R2 changes only the transaction-test branch:

```text
composed_selector_value_use_transaction_tests.zig (aggregator)
  -> value_use/core tests
  -> value_use/planning tests
  -> value_use/materialization tests
  -> value_use/composition tests
  -> actions/address_memory tests
  -> actions/control_compare tests
  -> actions/calls tests
```

Implementation-private tests should be co-located in the owning leaf's `test`
blocks. Cross-module behavior tests may remain in grouped `_tests.zig` modules
but must use the facade contract only. The existing
`composed_selector_tests.zig` and build roots remain the only test entrypoints.

The source guard remains reachable through the same aggregator. R2 may split
its implementation into shared parsing and policy helpers, but
`composed_selector_source_guard_tests.zig` remains the build-visible entry and
the exact current allowlists/ratchets remain authoritative.

## 8. Test-to-private-detail map

No current external test can lexically name a private declaration: Zig
visibility prevents that, and an R0 scan found no direct use of private
transaction fields or private prepared types. The oversized test file does,
however, rely on public members that are implementation/test details. Those
are mapped below so R2 does not solve the split by exporting more internals.

| Current test population | Detail exercised | R2 owner |
|---|---|---|
| copy-amplification contract; phase/capacity/coalescing; rollback; unsupported/dependency failures | snapshot metrics, `RequestPhase`, `requestCount`, lifecycle rollback | core/planning co-located tests |
| repeated sources, copy cycles, early reload, semantic-role prefix closure/order/conflicts | planner graph and early-plan behavior | planning co-located tests |
| restricted prepared views, capability relocation negative, mixed fixed/view ordering, canonical revalidation | opaque prepared record/view generation | materialization co-located tests; do not export `PreparedView` |
| owned-label rollback and retained target identity | snapshot label ownership | core co-located test |
| subordinate accumulator lifecycle, combined rollback, provenance inheritance, standalone O1 unchanged | subordinate session internals and one-snapshot metric | composition co-located tests |
| address/GEP descriptor, f32-pair, readonly table action tests | private descriptor/view adapters and durable identity helper | address-memory action tests |
| scalar/i64/stack-pointer store and narrow-view tests | binding compatibility, store action staging, test failure boundaries | planning plus address-memory action tests |
| all 28 load matrix, ordinary/readonly/table precedence, pair/alias load, load rollback tests | `LoadRequestError`, `LoadTestFailure`, private load executors | address-memory action tests |
| branch EFLAGS and switch storage/boundary/rollback tests | private condition view, switch action execution, owned target copies | control-compare action tests |
| all scratch/current-home/setcc/sign-bit/i128 compare tests | private compare plans/classifiers/executors and seven test-failure enums | control-compare action tests |
| inline memcpy staging/provenance/rollback tests | private memcpy materializers and `MemcpyTestFailure` | calls action tests |
| production-path tests in `composed_selector_calls_tests.zig`, `composed_selector_icmp_tests.zig`, and other selector tests | only facade behavior | remain external integration tests |

The current transaction test file contains 128 `test` declarations. R2 must
produce a machine-readable test-name manifest mapping all 128 names to exactly
one destination, and compare the sorted name set before/after. The grouping
above is the ownership rule for that manifest. In particular:

- `PreparedShape`, all `*TestFailure` enums/setters, snapshot metrics,
  `RequestPhase`, and `requestCount` must not motivate new facade exports.
- Tests needing `PreparedRecord`, `PreparedView`, graph nodes, mappings,
  snapshot arrays, or action plans move into the owning module's colocated
  `test` block.
- Integration tests must continue to observe only opaque handles, semantic
  requests/actions, diagnostics, instructions, and final selector state.

For completeness, this is the exhaustive R0 line-band mapping. The bands are
non-overlapping, cover all 128 declarations, and their counts sum to 128:

| Current test-file lines | Count | R2 owner |
|---|---:|---|
| 680-972 | 10 | `actions/control_compare` (branch/switch) |
| 973-1775 | 14 | `actions/address_memory` (stores/narrow views) |
| 1776-1953 | 4 | `materialization` (supported prepared source forms) |
| 1954-2218 | 5 | `core`/`planning` (phase, capacity, overlap, rollback, dependency failures) |
| 2219-2307 | 2 | `materialization` (restricted prepared members/repeated source views) |
| 2308-2780 | 8 | `planning` (early and semantic-role scheduling) |
| 2781-2967 | 3 | `materialization` (capability invalidation/revalidation) |
| 2968-3051 | 1 | `core` (owned-label snapshot rollback) |
| 3052-3697 | 9 | `actions/address_memory` (GEP/address forms) |
| 3698-4046 | 9 | `actions/calls` (memcpy/provenance) |
| 4047-4303 | 4 | `composition` (subordinate accumulator session) |
| 4304-4999 | 11 | `actions/address_memory` (loads/diagnostic precedence) |
| 5000-7771 | 48 | `actions/control_compare` (scratch/current-home/setcc/sign-bit/i128) |

No test outside those bands accesses a transaction implementation detail.
The R2 name manifest refines the two mixed `core/planning` rows without
changing their total or silently dropping a test.

## 9. Mechanical move proof for R1 and R2

Color-moved output is supporting evidence only. The acceptance proof is a
symbol provenance manifest with one row for every symbol in §4:

```text
old_file
old_symbol
old_start_line
old_end_line
old_signature_sha256
old_body_sha256
new_file
new_symbol
new_start_line
new_end_line
new_signature_sha256
new_body_sha256
move_kind
review_note
```

The comparison procedure is:

1. Parse declarations from the frozen R0 blob, not the mutable worktree.
2. Strip only indentation and the mechanically-required visibility token from
   the signature before hashing. Parameter order/types, return/error type,
   defaults, field order, enum/union tags, and comptime values remain exact.
3. For a verbatim move (`move_kind=verbatim`), normalize indentation only and
   require identical body hashes.
4. For a public method whose body becomes a leaf call
   (`move_kind=wrapper-extraction`), retain the old public signature exactly;
   hash the wrapper separately; and compare the extracted leaf body with the
   old body after a declared mechanical receiver rewrite
   (`transaction.method(x)` to `module.method(transaction, x)`). Every rewrite
   is enumerated; no semantic rewrite is hidden by normalization.
5. For nested types moved to `model` and aliased from the transaction
   (`move_kind=type-alias`), require identical field/tag/default order and
   identical nested method bodies.
6. For an import/alias repeated privately in several leaves
   (`move_kind=private-import-copy`), record it but exclude it from behavior
   body comparison.
7. Reject an unlisted new/deleted symbol, unmatched old symbol, changed error
   annotation, widened visibility, changed default, reordered union tag, or
   changed action dispatch arm.
8. Separately compare the sorted facade manifest (§5), central
   `PreparedAction` tag manifest, `UseForm` tag manifest, error-set member
   manifests, and dispatch tag manifest.
9. R2 repeats the R1 production provenance comparison and adds a sorted
   128-test-name provenance manifest plus source-guard policy/fixture
   provenance.

The R1 commit must contain the provenance manifest and the tool command used
to produce it. The proof tool is procedural evidence and must not become a
production build dependency.

## 10. R1/R2 execution and gates

### R1 — production split

R1 moves production declarations and leaves the existing facade path/API
stable. Before timing, the complete source tree, evidence, guard updates, and
commit must be final. Only then may immutable A and B artifacts be frozen.

Required gates:

1. Mechanical provenance and facade/action/error manifest checks.
2. Full unit suite and source guard.
3. Fresh cohort report exactly `49a19f04` (443/285/158, first fail
   `compiler_rt.trunc.truncl`).
4. Accepted-cohort object exactly `061a64e4`.
5. Owner manifest exactly `5d91960e`, ledger `167/17/101`.
6. ABI differential 60/60 + 30/30.
7. Focused fma and `__multi3` canaries.
8. Integrated-exe 7/7.
9. Strengthened Tier 2.
10. Counterbalanced performance using immutable artifacts: idle check; two
    discarded warmups per artifact; six pairs `AB, BA, AB, BA, AB, BA`; all
    samples retained; aggregate median delta no more than
    `max(A*5%, 100ms)` and median paired ratio `B/A <= 1.05`; RSS increase no
    more than 16 MiB; exact commands beside logs.

No Tier 3.

### R2 — tests and guard split

R2 splits the transaction tests and, if useful, the guard implementation while
preserving their build entrypoints and exact policy.

R2 may omit performance **only if all four are byte-identical to accepted R1**:

1. every production source file;
2. every tool source/file;
3. build configuration and build roots;
4. `composed_selector_value_use_transaction.zig` facade.

The byte comparison and hashes must be tracked evidence. If any of those four
classes differs, R2 runs the full R1 gate including counterbalanced
performance. With or without performance, R2 runs full unit/source-guard,
mechanical test provenance, fresh frozen identities, ABI, canaries,
integrated-exe, and strengthened Tier 2.

No Tier 3.

## 11. Architectural review decisions requested

The proposed graph has no unavoidable cycle. Review is requested on these
specific structural choices before R1:

1. `PreparedAction` and all semantic payload types remain centrally owned by
   `model.zig`; core alone owns exhaustive dispatch.
2. Planning may depend on pure classifiers in action leaves, but action leaves
   may not depend on planning or core.
3. Technically-public internal declarations are guarded rather than
   re-exported; production imports remain facade-only.
4. Public method bodies may become mechanically-provable wrappers while their
   extracted bodies are compared under the narrowly declared receiver rewrite.
5. `actions/control_compare.zig` is accepted as a near-limit watch and must
   stop if the actual R1 leaf exceeds 2,000 lines.

Until those decisions are accepted, no R1 production movement is authorized.

## Appendix A — exact current function-signature ledger

This ledger disambiguates every function symbol grouped in §4. Line numbers
refer to the R0 monolith identified in §1. Visibility tokens shown are current.

```text
L78   fn Expected.eql(Expected, Expected) bool
L145  fn Destination.eql(Destination, Destination) bool
L185  pub fn ActionIdentity.init([]const u8) !ActionIdentity
L194  fn ActionIdentity.slice(*const ActionIdentity) []const u8
L198  fn ActionIdentity.validate(*const ActionIdentity) !void
L443  pub fn isCurrentHomeSignBitIcmp(ir.IcmpInst) bool
L529  pub fn isI128EqMinIcmp(ir.IcmpInst) bool
L547  pub fn isI128SignBitIcmp(ir.IcmpInst) bool
L581  pub fn SwitchCompareChainAction.init(u8, []const SwitchCaseIntent, []const u8, ?u8) !SwitchCompareChainAction
L609  fn SwitchCompareChainAction.validate(*const SwitchCompareChainAction) !void
L655  fn PreparedAction.eql(PreparedAction, PreparedAction) bool
L666  fn CopyDestination.asDestination(CopyDestination) Destination
L680  fn PreparedIdentity.init([]const u8) !PreparedIdentity
L689  fn PreparedIdentity.slice(*const PreparedIdentity) []const u8
L693  fn PreparedIdentity.eql(*const PreparedIdentity, *const PreparedIdentity) bool
L835  fn Identity.init([]const u8) !Identity
L844  fn Identity.slice(*const Identity) []const u8
L848  fn Identity.eql(*const Identity, *const Identity) bool
L859  fn Source.from(ir.Value) !Source
L868  fn Source.eql(*const Source, *const Source) bool
L877  fn Source.value(*const Source) ir.Value
L894  fn StoredRequest.eql(*const StoredRequest, *const StoredRequest) bool
L938  fn Snapshot.init(*ComposedBlockSelector) !Snapshot
L985  fn Snapshot.restore(*const Snapshot, *ComposedBlockSelector) void
L1014 fn Snapshot.deinit(*Snapshot, *ComposedBlockSelector) void
L1033 pub fn begin(*ComposedBlockSelector) !ValueUseTransaction
L1037 pub fn deinit(*ValueUseTransaction) void
L1044 pub fn register(*ValueUseTransaction, Request) !RequestHandle
L1075 pub fn attachScratchCompareAction(*ValueUseTransaction, RequestHandle, ScratchCompareAction) !void
L1109 pub fn seal(*ValueUseTransaction) !void
L1166 pub fn prepare(*ValueUseTransaction) !void
L1217 pub fn applySwitchBoundary(*ValueUseTransaction, RequestHandle) !void
L1241 pub fn materializeAll(*ValueUseTransaction) !void
L1264 pub fn preparedView(*ValueUseTransaction, RequestHandle) !PreparedViewLease
L1280 pub fn beginAccumulatorSession(*ValueUseTransaction) !AccumulatorSessionHandle
L1295 pub fn prepareAccumulator(*ValueUseTransaction, AccumulatorSessionHandle, AccumulatorPreparationEffect, AccumulatorDisplacementPolicy) !?Diagnostic
L1310 pub fn prepareAccumulatorCallBeforeArguments(*ValueUseTransaction, AccumulatorSessionHandle, AccumulatorPreparationEffect) !?Diagnostic
L1324 pub fn finishAccumulatorCallPreparationAfterArguments(*ValueUseTransaction, AccumulatorSessionHandle) !void
L1333 pub fn materializeAccumulator(*ValueUseTransaction, AccumulatorSessionHandle, ir.Value, AccumulatorDefinition) !void
L1344 pub fn spillAccumulatorValue(*ValueUseTransaction, AccumulatorSessionHandle, []const u8) !void
L1354 pub fn defineAccumulatorResult(*ValueUseTransaction, AccumulatorSessionHandle, []const u8, AccumulatorDefinition) !void
L1365 pub fn finalizeAccumulatorResult(*ValueUseTransaction, AccumulatorSessionHandle) !void
L1376 pub fn commitAccumulatorSession(*ValueUseTransaction, AccumulatorSessionHandle) !void
L1388 pub fn executePreparedAction(*ValueUseTransaction, PreparedViewLease) !void
L1429 pub fn commit(*ValueUseTransaction) !void
L1440 pub fn rollback(*ValueUseTransaction) !void
L1445 pub fn requestCount(*const ValueUseTransaction) usize
L1449 pub fn phase(*const ValueUseTransaction) RequestPhase
L1456 pub fn actionDiagnostic(*const ValueUseTransaction) ?Diagnostic
L1462 pub fn failedRequestIs(*const ValueUseTransaction, RequestHandle) bool
L1475 pub fn setMemcpyTestFailure(*ValueUseTransaction, ?MemcpyTestFailure) !void
L1485 pub fn setLoadTestFailure(*ValueUseTransaction, ?LoadTestFailure) !void
L1495 pub fn setScratchCompareTestFailure(*ValueUseTransaction, ?ScratchCompareTestFailure) !void
L1505 pub fn setCurrentHomeEqZeroTestFailure(*ValueUseTransaction, ?CurrentHomeEqZeroTestFailure) !void
L1515 pub fn setSetccEaxCompareTestFailure(*ValueUseTransaction, ?SetccEaxCompareTestFailure) !void
L1525 pub fn setCurrentHomeSignBitTestFailure(*ValueUseTransaction, ?CurrentHomeSignBitTestFailure) !void
L1534 pub fn setI128EqMinTestFailure(*ValueUseTransaction, ?I128EqMinTestFailure) !void
L1543 pub fn setI128SignBitTestFailure(*ValueUseTransaction, ?I128SignBitTestFailure) !void
L1551 fn requireActive(*const ValueUseTransaction) !void
L1555 fn rollbackInternal(*ValueUseTransaction) void
L1571 fn validateAccumulatorSession(*ValueUseTransaction, AccumulatorSessionHandle) !*AccumulatorDefinitionSession
L1587 fn handleFor(*ValueUseTransaction, u8) RequestHandle
L1595 fn validateHandle(*ValueUseTransaction, RequestHandle) !u8
L1602 fn recordRequestFailure(*ValueUseTransaction, u8) void
L1607 fn noteRequestBoundaryError(*ValueUseTransaction, u8, anyerror) void
L1654 fn validateRequestAt(*ValueUseTransaction, u8) !?ValueLoc
L1661 fn validateActionRegistration(*ValueUseTransaction, PreparedAction) !void
L1745 fn validateRegisteredOperandHandle(*ValueUseTransaction, RequestHandle) !u8
L1756 fn noteRegisteredOperandBoundaryError(*ValueUseTransaction, RequestHandle, anyerror) void
L1765 fn registeredOperandCurrent(*ValueUseTransaction, RequestHandle) !ValueLoc
L1773 fn registeredOperandView(*ValueUseTransaction, RequestHandle) !*const PreparedView
L1785 fn validateActionDependenciesCanonical(*ValueUseTransaction, PreparedAction) !void
L1825 fn validateConsumedActionAfter(*ValueUseTransaction, u8, PreparedAction) !void
L1837 fn validateConsumedOperandAfter(*ValueUseTransaction, u8) !void
L1844 fn validateConsumedOperandAfterUnchecked(*ValueUseTransaction, u8) !void
L1867 fn validateOperandCanonical(*ValueUseTransaction, RequestHandle) !void
L1880 fn validateRequest(*ValueUseTransaction, *const StoredRequest) !?ValueLoc
L1918 fn validateSemanticOrderTopology(*ValueUseTransaction) !void
L1947 fn actionSecondaryOperand(*ValueUseTransaction, PreparedAction) !?u8
L1988 fn actionTertiaryOperand(*ValueUseTransaction, PreparedAction) !?u8
L2019 fn resetSemanticOrderPlan(*ValueUseTransaction) void
L2025 fn planEarlyMaterializations(*ValueUseTransaction, []const Mapping) !void
L2111 fn appendOrderedOperand(*ValueUseTransaction, u8, SemanticRole, *bool, []const Mapping, [max_requests]u8, [physical_node_count]bool) !void
L2179 fn sortSemanticRoots(*ValueUseTransaction, []u8, []const Mapping) !void
L2206 fn semanticRootLessThan(*ValueUseTransaction, u8, u8, []const Mapping) bool
L2221 fn firstStructuralDestination(*ValueUseTransaction, u8, []const Mapping) PhysicalNode
L2238 fn materializeEarlyPlans(*ValueUseTransaction) !void
L2249 fn materializeEarlyPlan(*ValueUseTransaction, u8) !void
L2288 fn validateEarlyHome(*ValueUseTransaction, u8) !void
L2295 fn validateEarlyHomeUnchecked(*ValueUseTransaction, u8) !void
L2311 fn materializeRequest(*ValueUseTransaction, u8, *const StoredRequest) !void
L2322 fn materializeRequestUnchecked(*ValueUseTransaction, *const StoredRequest) !void
L2342 fn materializeRequestFromLoc(*ValueUseTransaction, *const StoredRequest, ValueLoc, Destination) !void
L2371 fn resolveNamedCurrent(*ValueUseTransaction, []const u8) !ValueLoc
L2376 fn buildPreparedRecord(*ValueUseTransaction, u8) !PreparedRecord
L2383 fn buildPreparedRecordUnchecked(*ValueUseTransaction, u8) !PreparedRecord
L2425 fn optionalPreparedActionEql(?PreparedAction, ?PreparedAction) bool
L2433 fn preparedViewFromLoc(*ValueUseTransaction, *const StoredRequest, ValueLoc) !PreparedView
L2464 fn preparedMemcpyScalarView(ValueLoc) !PreparedView
L2474 fn preparedScratchCompareView(ValueLoc, ir.Type) !PreparedView
L2495 fn preparedConditionView(ValueLoc) !PreparedView
L2507 fn preparedStackF32PairAddressView(ValueLoc) !PreparedView
L2517 fn preparedScalarView(ValueLoc) !PreparedView
L2528 fn preparedPointerView(*ValueUseTransaction, *const StoredRequest, ValueLoc) !PreparedView
L2550 fn preparedStackObjectView(ValueLoc) !PreparedView
L2559 fn preparedAddressDescriptor(*ValueUseTransaction, *const StoredRequest, selector_types.StackPtrLoc) !PreparedAddressDescriptor
L2582 fn requireDependencyRole(AddressDependencyDomain.OwnerView, []const u8, AddressDependencyDomain.Role) !void
L2593 fn preparedAddressComponent(*ValueUseTransaction, []const u8, AddressDependencyDomain.Role) !PreparedAddressComponent
L2608 fn preparedScalarHome(ValueLoc) !PreparedScalarHome
L2619 fn preparedPairView(ValueLoc, UseForm) !PreparedView
L2670 fn classifyScratchCompare(*const ScratchCompareAction) !ScratchComparePlan
L2761 fn executePreparedActionInternal(*ValueUseTransaction, u8, *const PreparedView, *const StoredRequest, PreparedAction) !void
L2843 fn executeScratchCompare(*ValueUseTransaction, u8, *const PreparedView, *const ScratchCompareAction) !void
L2988 fn preserveScratchCompareLiveAccumulator(*ValueUseTransaction) !void
L3009 fn refreshScratchCompareOperandViews(*ValueUseTransaction, u8, *const ScratchCompareAction) !void
L3026 fn stageScratchCompareOperand(*ValueUseTransaction, u8, *const PreparedView, ArgReg, u16) !void
L3039 fn stageScratchCompareOperandUnchecked(*ValueUseTransaction, *const PreparedView, ArgReg, u16) !void
L3059 fn failScratchCompareForTest(*ValueUseTransaction, ScratchCompareTestFailure) !void
L3067 fn executeCurrentHomeEqZero(*ValueUseTransaction, u8, *const PreparedView, *const CurrentHomeEqZeroAction) !void
L3155 fn classifySetccEaxCompare(*const SetccEaxCompareAction) !SetccEaxComparePlan
L3272 fn executeSetccEaxCompare(*ValueUseTransaction, u8, *const PreparedView, *const SetccEaxCompareAction) !void
L3361 fn validateSetccEaxCompareHome(ValueBinding, Expected, ValueLoc) SetccEaxCompareRequestError!void
L3381 fn failSetccEaxCompareForTest(*ValueUseTransaction, SetccEaxCompareTestFailure) !void
L3394 fn classifyCurrentHomeSignBit(*const CurrentHomeSignBitAction) CurrentHomeSignBitRequestError!CurrentHomeSignBitPlan
L3407 fn executeCurrentHomeSignBit(*ValueUseTransaction, u8, *const PreparedView, *const CurrentHomeSignBitAction) !void
L3494 fn validateCurrentHomeSignBitHome(ValueBinding, Expected, ValueLoc) CurrentHomeSignBitRequestError!void
L3518 fn preserveCurrentHomeSignBitLiveAccumulator(*ValueUseTransaction) !void
L3570 fn failCurrentHomeSignBitForTest(*ValueUseTransaction, CurrentHomeSignBitTestFailure) !void
L3578 fn executeI128EqMin(*ValueUseTransaction, u8, *const PreparedView, *const I128EqMinAction) !void
L3678 fn executeI128SignBit(*ValueUseTransaction, u8, *const PreparedView, *const I128SignBitAction) !void
L3726 fn refreshAndValidateI128PairSource(*ValueUseTransaction, u8) ![]const u8
L3752 fn validateI128PairHome(ValueBinding, Expected, ValueLoc) I128PairRequestError!void
L3768 fn failI128EqMinForTest(*ValueUseTransaction, I128EqMinTestFailure) !void
L3776 fn failI128SignBitForTest(*ValueUseTransaction, I128SignBitTestFailure) !void
L3790 fn classifyCurrentHomeEqZero(ValueBinding, Expected, ValueLoc) CurrentHomeEqZeroRequestError!CurrentHomeEqZeroTest
L3839 fn failCurrentHomeEqZeroForTest(*ValueUseTransaction, CurrentHomeEqZeroTestFailure) !void
L3847 fn executeScalarLoad(*ValueUseTransaction, u8, *const PreparedView, ScalarLoadAction) !void
L3874 fn prepareScalarLoadAccumulator(*ValueUseTransaction, *AccumulatorDefinitionSession) !void
L3885 fn refreshLoadPreparedOperand(*ValueUseTransaction, u8) !void
L3893 fn executeOrdinaryScalarLoad(*ValueUseTransaction, *const PreparedView, u16) !void
L3945 fn appendPreparedLoadStackI32(*ValueUseTransaction, PreparedAddressDescriptor) !void
L3983 fn appendPreparedLoadStackU64IntoRax(*ComposedBlockSelector, u32) !void
L3995 fn preparedScalarHomeLoc(PreparedScalarHome) ValueLoc
L4007 fn executeReadOnlyScalarLoad(*ValueUseTransaction, ArgReg, u16) !void
L4057 fn stageReadOnlyScalarLoadPointer(*ValueUseTransaction, *const PreparedView) !ArgReg
L4065 fn materializePreparedLoadPointer(*ValueUseTransaction, *const PreparedView, ArgReg) !ArgReg
L4089 fn executeReadOnlyPairLoad(*ValueUseTransaction, u8, *const PreparedView, *const ReadOnlyPairLoadAction) !void
L4140 fn executeStackI128AliasLoad(*ValueUseTransaction, *const PreparedView, *const StackI128AliasLoadAction) !void
L4156 fn executeReadOnlyTableI16Load(*ValueUseTransaction, *const PreparedView, *const ReadOnlyTableI16LoadAction) !void
L4188 fn failLoadForTest(*ValueUseTransaction, LoadTestFailure) !void
L4198 fn executeInlineMemcpy(*ValueUseTransaction, u8, MemcpyAction) !void
L4238 fn refreshMemcpyPreparedOperand(*ValueUseTransaction, u8) !void
L4246 fn materializeMemcpyHandle(*ValueUseTransaction, RequestHandle, ArgReg) !void
L4255 fn materializeMemcpyRequest(*ValueUseTransaction, u8, ArgReg) !void
L4266 fn materializeMemcpyRequestUnchecked(*ValueUseTransaction, u8, ArgReg) !void
L4291 fn failMemcpyForTest(*ValueUseTransaction, MemcpyTestFailure) !void
L4301 fn executeBranchCondition(*ValueUseTransaction, *const PreparedView) !void
L4339 fn executeSwitchCompareChain(*ValueUseTransaction, *const PreparedView, *const SwitchCompareChainAction) !void
L4397 fn switchConditionMask(u8) i32
L4403 fn validateDeferredSwitchRequest(*const StoredRequest) !void
L4420 fn restoreSwitchDisplacedPhiDestinations(*ComposedBlockSelector) !void
L4436 fn executeStoreScalar(*ValueUseTransaction, *const PreparedView, StoreScalarAction) !void
L4449 fn executeStoreImmediate(*ValueUseTransaction, *const PreparedView, StoreImmediateAction) !void
L4461 fn executeStoreI64(*ValueUseTransaction, *const PreparedView, StoreI64Action) !void
L4483 fn executeStoreStackPointer(*ValueUseTransaction, *const PreparedView, StoreStackPointerAction) !void
L4529 fn executeStoreEaxToPointer(*ValueUseTransaction, *const PreparedView, u8) !void
L4575 fn executeStoreStackI32(*ValueUseTransaction, *const PreparedView, u32) !void
L4596 fn appendStoreEaxStack(*ValueUseTransaction, u32, bool) !void
L4612 fn materializeActionScalar32(*ValueUseTransaction, *const PreparedView, PhysicalNode) !void
L4622 fn materializeActionScalar64(*ValueUseTransaction, *const PreparedView, PhysicalNode) !void
L4632 fn materializeActionPointer(*ValueUseTransaction, ValueLoc, ArgReg) !void
L4641 fn materializeActionScalarHome(*ValueUseTransaction, PreparedScalarHome, ArgReg) !void
L4659 fn clobberActionDestination(*ValueUseTransaction, ValueLoc, PhysicalNode) !void
L4668 fn stackScalarFromPreparedView(*const PreparedView) !selector_types.StackScalarLoc
L4680 fn executeByteAddress(*ValueUseTransaction, *const PreparedView, *const StoredRequest, ByteAddressAction) !void
L4752 fn executeScaledAddress(*ValueUseTransaction, *const PreparedView, *const StoredRequest, ScaledAddressAction) !void
L4862 fn executeReadOnlyTableAddress(*ValueUseTransaction, *const PreparedView, *const StoredRequest, ReadOnlyTableAddressAction) !void
L4889 fn ownActionIdentity(*ValueUseTransaction, *const ActionIdentity) ![]const u8
L4899 fn ownRegisteredOperandName(*ValueUseTransaction, RequestHandle) ![]const u8
L4917 fn scaleShift(u8) !u6
L4925 fn scaledOffset(i32, u8) !i32
L4930 fn validatePreparedShape(*const PreparedView, PreparedShape) !void
L4965 fn preparedViewLoc(*const PreparedView) !ValueLoc
L5010 fn preparedRecordEql(*const PreparedRecord, *const PreparedRecord) bool
L5019 fn preparedViewEql(*const PreparedView, *const PreparedView) bool
L5040 fn preparedStackObjectEql(*const PreparedStackObject, *const PreparedStackObject) bool
L5052 fn preparedAddressDescriptorEql(*const PreparedAddressDescriptor, *const PreparedAddressDescriptor) bool
L5067 fn preparedAddressComponentEql(*const PreparedAddressComponent, *const PreparedAddressComponent) bool
L5075 fn preparedTablePointerEql(*const PreparedTablePointer, *const PreparedTablePointer) bool
L5087 fn NodeList.append(*NodeList, PhysicalNode) !void
L5093 fn NodeList.slice(*const NodeList) []const PhysicalNode
L5108 fn MappingList.append(*MappingList, Mapping) void
L5113 fn MappingList.slice(*const MappingList) []const Mapping
L5118 fn validateFormAndDestination(*const StoredRequest) !void
L5252 fn validateBindingCompatibility(ValueBinding, *const StoredRequest, ValueLoc) !void
L5361 fn validateScratchCompareBinding(ValueBinding, Expected, ValueLoc) !void
L5387 fn validateOrdinaryLoadHome(ValueBinding, ValueLoc, u16, bool) !void
L5421 fn validateReadOnlyPointerLoadHome(ValueBinding, ValueLoc) !void
L5429 fn validateReadOnlyTableLoadHome(ValueBinding, ValueLoc) !void
L5441 fn hasLow32View(ValueLoc) bool
L5448 fn validateExpectedType(Expected, UseForm) !void
L5572 fn validateSourceView(ValueLoc, UseForm) !void
L5674 fn earlyCopyIsFlagsPreserving(ValueLoc, UseForm) bool
L5712 fn earlySequencingCandidate(ValueLoc, UseForm) bool
L5731 fn requestDestinationNodes(*ValueUseTransaction, *const StoredRequest, ?ValueLoc) !NodeList
L5920 fn requestMappings(*ValueUseTransaction, *const StoredRequest, u8, ?ValueLoc) !MappingList
L6250 fn actionOwnsOrderedWrites(PreparedAction) bool
L6279 fn validateStorePointerOperand(*const StoredRequest, bool) !void
L6296 fn validateStoreI64ValueOperand(*const StoredRequest) !void
L6302 fn validateStoreStackObjectOperand(*const StoredRequest) !void
L6309 fn validateMemcpyPointerOperand(*const StoredRequest) !void
L6318 fn validateMemcpyLengthOperand(*const StoredRequest) !void
L6326 fn appendStorePointerDestinationNodes(*NodeList, ValueLoc, u8) !void
L6352 fn appendStorePointerMappings(*ValueUseTransaction, *MappingList, ValueLoc, ?u8, u8) !void
L6390 fn validateI64StorePointer(ValueLoc) !void
L6397 fn validateStackPointerStoreViews(ValueLoc, ValueLoc) !void
L6412 fn validateCopyActionForm(UseForm, CopyDestination) !void
L6439 fn scalarSourceNode(ValueLoc) ?PhysicalNode
L6452 fn pairSourceNodes(ValueLoc) [2]?PhysicalNode
L6460 fn nodeForArgReg(ArgReg) PhysicalNode
L6471 fn argRegForNode(PhysicalNode) ?ArgReg
L6483 fn rejectCopyCycles([physical_node_count][physical_node_count]bool) !void
L6488 fn visitCopyNode([physical_node_count][physical_node_count]bool, usize, *[physical_node_count]CopyVisitState) !void
L6504 fn rejectSemanticOrderCycles([max_requests][max_requests]bool, u8) !void
L6512 fn visitSemanticOrderNode([max_requests][max_requests]bool, usize, u8, *[max_requests]CopyVisitState) !void
L6529 fn firstMappingDestination(u8, []const Mapping) ?PhysicalNode
L6539 fn sourceStructuralOrder(*const Source, *const Source) std.math.Order
L6554 fn clobberPhysicalNode(*ComposedBlockSelector, PhysicalNode) !void
L6563 fn materializeScalar32(*ComposedBlockSelector, ValueLoc, Destination) !void
L6576 fn materializeScalar64(*ComposedBlockSelector, ValueLoc, Destination) !void
L6589 fn materializeByteAddressPointer(*ComposedBlockSelector, ValueLoc, ArgReg) !void
L6600 fn materializePointer(*ComposedBlockSelector, ValueLoc, Destination) !void
L6619 fn materializeStackAddress(*ComposedBlockSelector, u32, ?selector_types.StackPtrLoc, Destination) !void
L6652 fn materializePair(*ComposedBlockSelector, ValueLoc, UseForm, Destination) !void
L6671 fn materializePairLimb(*ComposedBlockSelector, ValueLoc, bool, ArgReg) !void
L6685 fn materializeNull(*ComposedBlockSelector, Destination) !void
```
