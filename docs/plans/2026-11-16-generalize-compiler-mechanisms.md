# Generalize compiler mechanisms

Date: 2026-11-16
Status: stages 1 through 4 accepted after ReleaseSafe acceptance commit `338b8972`.
Stage 5 is measured and deferred; final documentation closure remains. Stage 2
qualifies its mechanical description migration separately from the power-of-two
length extension.
Review baseline: repository HEAD `97b6eced`, with compiler changes through `ae9d359f`.
Review reconciliation: 2026-11-16; operand mutation, proof semantics, identity
namespaces, effective scheduling order and storage boundaries clarified.

## Objective

Reduce repeated special-case handling by extending the shared mechanisms already
present in z_llvm. Equivalent supported programs should continue to compile when
internal names, surrounding instructions or admitted data layouts change.

The source review found a common IR, verifier, operand walkers, integer semantics,
layout helpers and transactional lowering. The main problem is uneven use of
those mechanisms, alongside legacy handlers tied to particular workloads.
Build on the completed [bounded architecture refactors](../roadmap/architecture_refactor_plan.md).

This document records a plan requested after a source review. No project code,
tests, builds or profiling were executed for that review or this document.
The findings describe maintenance and generality risks; they do not establish
new runtime failures.

## Relationship to current work

Finish the [ReleaseSafe preopt acceptance work](2026-11-14-release-safe-preopt-behavior.md)
before changing its frozen compiler candidate. That prerequisite completed in
`338b8972`, including final storage disposition. The user's subsequent instruction
authorizes this implementation; [next steps](../next_steps.md) records it as the
current action. The Safe acceptance conditions and frozen results remain unchanged.

At implementation admission, read the latest accepted state and record the exact
source, toolchain, target, pipelines and comparison inputs. The review baseline
above identifies inspected code; it is not automatically the future baseline.

Preserve existing edits, accepted results and source ownership. Separate
behavior-preserving refactors from support expansion and correctness repairs.
An unexpected behavior change needs a diagnosis and its own validation scope.

## Delivery order

| Stage | Improvement | Reason for this order |
| --- | --- | --- |
| 1 | Shared operand and use queries | Existing infrastructure and concrete duplication make a bounded first change. |
| 2 | General constant-table descriptions and index proofs | A small, explicit family can demonstrate generalization beyond fixed layouts. |
| 3 | One legacy lowering family through composed operations | Remove a dependency on fixture names and whole-function shapes. |
| 4 | Compact internal identities | Remove the dependency between textual name length and transaction admission. |
| 5 | Selective legalization scheduling | Change scheduling only after profiling and dependency analysis justify it. |

Each stage produces a separately reviewable change. Closing one stage does not
establish acceptance of the remaining stages or of a broader LLVM replacement.

## 1. Consolidate operand and use queries

Starting points:

- [Shared operand traversal](../../src/ir/operands.zig).
- [Use counts: existing migrated reference](../../src/analysis/def_use.zig).
- [Vector-combine queries and replacement](../../src/passes/vector_combine.zig).
- [Induction-variable queries](../../src/passes/indvars.zig).
- [Backend memory-use queries](../../src/codegen/x86_64/generic_cfg/composed_selector_memory.zig).

Vector-combine, induction-variable handling and backend memory-use queries contain
separate instruction switches for finding, counting or replacing uses. Their
coverage differs for allocation counts, vector operands, indirect callees and
other forms. Inventory which differences can occur in valid admitted IR before
treating them as defects; the alloca divergence alone is not demonstrated wrong code.

`analysis/def_use.zig` already delegates instruction add/remove and terminator
operands to `ir.operands`. It intentionally discards opaque coverage and retains
its structured-value counting contract. Use it as a migrated reference, not as
another duplicated switch to remove. Its counts alone cannot establish absence
of unknown references.

Work:

1. Inventory the selected callers' operand coverage and handling of removed
   instructions, PHI edges, indirect callees and opaque syntax. Specify whether
   each query counts raw operand occurrences or distinct users: two operands in
   one instruction are two occurrences but may be one user. State how PHI
   incoming edges participate in counts and dominance checks.
2. Extend the existing walker with reusable query/count helpers and use the
   existing replacement API where its semantics match the caller.
3. Preserve the distinction between value operands, block labels and module
   symbols. Propagate incomplete coverage; an empty walk cannot prove that an
   opaque expression has no references.
4. Establish coverage, type compatibility and dominance before the first write,
   or provide full rollback of every affected change. `operands.replaceAllUses`
   reports coverage after mutation; it is not a preflight operation.
   `foldExtractAfterInsert` also sets `removed` and `replacement` before calling
   `replaceValue`. Move the relevant checks before those writes. Never perform
   a mutating replacement and then merely return false on opaque coverage.
5. Migrate one consumer first, then a second independent consumer. Prefer
   vector-combine followed by the backend memory-use helpers, subject to the
   initial coverage audit. Classify any deliberate eligibility restriction or
   expansion separately from the mechanical migration, including a newly
   introduced refusal on unknown references.
6. Add a function-local definition index only where a selected consumer needs
   it. Define its lifetime and invalidation before using it across mutations.

Acceptance:

- [x] The migrated consumers use shared traversal and have explicit coverage policies.
- [x] Focused cases exercise allocation counts, indirect calls, vector operands,
  PHIs, removed instructions and opaque references relevant to those callers.
- [x] An unknown-reference refusal case asserts that the complete IR and its
  bookkeeping remain unchanged, including operands, instruction lists,
  `removed` and `replacement` fields. Rejection after partial mutation cannot pass.
- [x] Repeated operands, multiple users and PHI edges verify each query's declared
  counting and dominance policy.
- [x] Replacement and deletion preserve IR validity and native behavior.
- [x] Any intentional eligibility change has its own diagnosis and validation
  scope; it is not reported as behavior-preserving mechanical migration.
- [x] The duplicated walkers for those consumers are removed.

## 2. Generalize constant-table descriptions and proofs

Starting points:

- [Constant-table decoding](../../src/codegen/x86_64/constant_table.zig).
- [Index proofs](../../src/codegen/x86_64/constant_table_index.zig).
- [Table-load lowering](../../src/codegen/x86_64/generic_cfg/composed_selector_memory.zig).

At the review baseline, the table shape enum described four specific layouts,
including
`[128 x i16]`, `[16 x double]` and `[512 x double]`. Load admission contains
corresponding masks and paired-access restrictions.

`constant_table_index.proves` accepts an allowed-bit mask, not an arbitrary
numeric upper bound. For example, `510` requires high bits to be zero and the
low bit to be zero: it proves an envelope and even parity. Keep these bit facts
separate from interval/range facts.

Work:

1. Introduce a typed table description containing element layout, element
   count, stride, alignment, serialized extent and permitted access widths.
2. First represent the four existing layouts through that description while
   preserving their current admission boundaries and emitted behavior.
3. Reuse the existing index-proof machinery for allowed-bit facts and derived
   alignment requirements independently of a particular table name or size.
   Represent any additional range proof separately; do not pass a general
   upper bound to the mask API or infer parity from a range alone.
4. Derive access bounds from the actual layout, byte offset and access width.
   Use checked arithmetic for element count times stride, index times stride,
   field offsets, access ends and target address/displacement limits. Refuse
   overflow or incomplete extent proofs. Preserve paired-load parity,
   integer-width semantics, alias checks, read-only storage checks and proof budgets.
5. Extend one element family to additional lengths as a separate capability
   change. The first extension is explicitly limited to power-of-two lengths.
   Arbitrary lengths remain separate work requiring a suitable range proof and
   at least one non-power-of-two acceptance case. Keep unsupported initializer
   syntax and types explicit.

Acceptance:

- [x] All four original layouts retain their behavior and rejection boundaries.
- [x] At least two additional power-of-two lengths in the selected family work
  through the same implementation without adding shape enum variants; the
  result does not claim arbitrary-length support.
- [x] Boundary, out-of-range, wrong-parity, escaped-pointer, incomplete-proof and
  checked extent/address-overflow cases are covered as applicable.
- [x] Mask proofs retain their bit contract, including the envelope-plus-parity
  meaning of `510`. Any introduced range proof has a separate contract and tests.
- [x] Independent native comparisons verify actual accesses and adjacent guards.

The [stage-2 evidence](../evidence/compiler_generalization_stage2_20261116.md)
records the four-layout preservation proof, i16 counts 64/256, initializer
regression and correction, checked boundaries and storage disposition. All 17
cumulative integration gates and the complete 231-population native suite pass.
The admitted integer family is limited to power-of-two counts 2 through 65,536;
arbitrary lengths and broader floating layouts remain outside this stage.

## 3. Replace one fixture-specific lowering family

Starting points:

- [Optional-pointer lowering](../../src/codegen/x86_64/air_patterns_optional_pointer.zig).
- [Global/TLS legacy rows](../../src/codegen/x86_64/air_patterns_global_tls_rows.zig).
- [Composed selector entry](../../src/codegen/x86_64/generic_cfg_selector.zig).
- [Selection ownership](../architecture.md).

At the review baseline, legacy paths recognized names such as
`runtime_optional_pointer_main.optionalPtrValue`. Other handlers combine exact
function names, instruction counts and constants to emit a particular sequence.
These examples do not describe every backend route.

Work:

1. Identify current callers and selection owners before changing a legacy
   handler. Distinguish active dependencies from unused compatibility code.
2. Select one family; optional-pointer load/return is the initial candidate.
   Map it to reusable pointer comparison, branching, load, PHI and return
   operations with explicit type and ABI requirements.
3. Extend composed lowering for the missing operations or their composition.
   Preserve transactional rollback, liveness and ownership checks.
4. Keep fixture names in tests. For ordinary internal symbols, derive behavior
   from IR and proven facts. Preserve semantics associated with real intrinsics,
   external symbols, calling conventions and linkage.
5. If replacing calls with direct operations, prove the callees' behavior,
   side effects and relevant linkage constraints. Removing a name check alone
   does not establish that transformation.
6. Remove the old handler only after its dependent cases use the qualified
   replacement. Record any intentional ownership transition explicitly.

Acceptance:

- [x] The original family passes through composed lowering, with ownership checked.
- [x] Equivalent cases pass after permissible internal renaming, harmless
  instruction rearrangement and insertion of independent instructions.
- [x] Additional uses, register pressure and branch variations exercise the
  mechanism beyond the original whole-function shape.
- [x] Unsupported or semantically different neighbors still reject safely.
- [x] The replaced name-specific handler is removed or its remaining dependency
  is precisely documented; generic counters alone do not close the stage.

The [stage-3 evidence](../evidence/compiler_generalization_stage3_20261116.md)
records removal of the obsolete load/return and named-helper handlers. Original
raw objects retain their already-composed ownership. A separate confirmed
computed-scalar fork-preservation repair passes exact optimized-failure replay,
native comparisons and all 17 integration gates, including all 232 native
populations. Two main-function legacy shapers remain outside this slice; no
unproven call substitution is introduced.

## 4. Separate internal identity from textual names

Starting points:

- [Value-use identity model](../../src/codegen/x86_64/generic_cfg/value_use/model.zig).
- [Existing identifier equality contract](../../src/ir/identifiers.zig).
- [Selector rename-and-retry path](../../src/codegen/x86_64/generic_cfg_selector.zig).

Value-use identities currently own a fixed 512-byte name buffer. An overflow
can cause the selector to construct a privately renamed function and retry.
Current `value_use.Identity.eql` and `PreparedIdentity.eql` compare bytes exactly.
The `ir.identifiers` contract can equate quoted/escaped spellings, so adopting
that equivalence can change behavior independently of how identities are stored.

Work:

1. Audit the selected identity callers and record where byte-exact equality is
   part of admission or state correlation, and where IR identifier equivalence
   is required. Preserve each caller's equality contract in a representational
   refactor. Any newly unified spelling behavior is an explicit behavioral
   change with separate validation, not an assumed consequence of interning.
2. Specify a function/rewrite-generation namespace and transaction ownership
   rules. A local numeric slot is meaningful only with its function and rewrite
   generation. Use exact equality under the audited caller contract; a hash
   alone is insufficient. Where IR identifier equivalence is selected, follow
   `ir.identifiers` for quoted/escaped spellings and numbered slots versus quoted
   numeric names. Unsupported spellings cannot establish inequality.
3. Begin inside the value-use layer. Retain original names for diagnostics,
   source correspondence and external IR or symbol interfaces.
4. Define identity lifetime across rollback, retries and function rewrites.
   Retain protection against cross-function, stale-generation and stale
   transaction identities. Publish a new generation explicitly when required.
5. Make insertion and ownership changes atomic under allocation failure and
   rollback. Restore the prior state or invalidate unpublished state explicitly;
   never silently reuse a still-observable identity for another value. Numeric
   slot reuse requires a namespace/generation transition that rejects old handles.
6. Migrate a bounded set of consumers, then remove the corresponding name-length
   admission limit and retry only when all its consumers are covered.

Acceptance:

- [x] Distinct long names, including names sharing long prefixes, remain distinct.
- [x] The caller audit identifies byte-exact and IR-equivalence contracts.
  Quoted/escaped spellings and numbered-slot versus quoted-name cases follow
  the selected contract. Any newly unified spelling behavior is explicitly
  classified and separately validated.
- [x] Cross-function and stale-generation handles reject even when their numeric
  slots match. Failed allocation and rollback do not alias an old handle to a
  different value or publish incomplete identity state.
- [x] The selected path handles long names without private renaming solely to
  fit its identity storage.
- [x] External names, relocations, diagnostics and accepted output contracts are preserved.

The [stage-4 evidence](../evidence/compiler_generalization_stage4_20261116.md)
records compact namespace/slot identities with selector-owned exact name bytes,
atomic insertion and rollback, stale-pool and same-address transaction rejection,
and strict long-parameter execution without private renaming. All 2,417 Fast
units, 244 selected Debug/Fast checks, 74 structural checks and 17 integration
gates pass, including all 233 native populations. Action-name and separate
address-dependency limits remain explicit. All cycle compiler and source
pipelines are closed; the seven contracts and seventeen holds are preserved.

## 5. Make legalization scheduling selective

Starting points:

- [Ordered optional legalizers](../../src/codegen/x86_64/generic_cfg/optional_legalization.zig).
- [Mandatory normalization](../../src/codegen/x86_64/generic_cfg/semantic_normalization.zig).
- [Selector retry loop](../../src/codegen/x86_64/generic_cfg_selector.zig).

Each successful optional rewrite restarts the ordered search. This creates an
opportunity to avoid repeated irrelevant scans, but rule order is currently
semantic and must remain explicit.

The effective order in `next()` is self-tail, tail, signed, `memory_bytes`, then
`memory_bitcasts`, followed by the remaining stages in enum order with those five
skipped. The `Stage` enum alone is not the scheduler specification.

Work:

1. Use existing profiles first; measure additional data only where needed.
   Establish whether repeated scans or normalization materially affect a fixed
   workload before changing the scheduler.
2. Describe selected rules' applicable operations and types, required facts,
   produced forms and invalidated information.
3. Introduce selective revisiting for a small rule group, preserving the effective
   `next()` order above, mandatory normalization, original-form retries and label
   lifetimes. Record dependencies before omitting an earlier rule check.
4. Retain conservative scheduling for incomplete applicability information and
   preserve rewrite-budget semantics and failure diagnostics. Keep the current
   limit and the point at which the selector consumes a rewrite: skipped checks
   do not consume the budget, and successful original-form selection does not
   charge the proposed rewrite. Preserve exhaustion behavior on actual rewrites.

Acceptance:

- [ ] Interacting-rule cases preserve the five prioritized stages, remaining
  effective order, retry semantics and label lifetimes.
- [ ] Boundary cases verify rewrite-budget consumption and exhaustion, including
  skipped checks and successful original-form retries.
- [ ] Relevant fixed outputs, ownership and behavior match the chosen baseline.
- [ ] Measurements distinguish fewer scans from actual wall-time or memory gains.
- [ ] Any performance claim includes unprofiled comparisons with matching inputs,
  settings and outputs. If the benefit is not demonstrated, defer this stage.

## Proposed follow-up abstractions

The review agreed on these three additional maintenance candidates. They sit
outside the five-stage delivery sequence above and do not change its order or
the preferred first consumer, vector-combine. Prioritize shared layout facts,
then small rewrite-construction helpers. Pointer/access facts require a precise
caller-contract audit before selecting an implementation slice.

These are proposed follow-up work, not demonstrated bugs or implementation
requests. Any selected slice needs its own bounded scope and the validation,
ownership and storage requirements below. The ReleaseSafe acceptance prerequisite
and existing preopt exception ownership remain unchanged.

### Shared module-aware layout facts

Starting points: [target data layout](../../src/target/datalayout.zig),
[memory-location analysis](../../src/analysis/memory_location.zig) and
[backend storage layout](../../src/codegen/x86_64/generic_cfg/storage_layout.zig).

Extend the shared target/IR layer to provide module-aware type and field-layout
facts consumed by both analysis and backend storage code. Resolve named types
against the actual module and target layout, with explicit unknown, ambiguous
and cyclic-type handling. Preserve each caller's identifier-equality contract.

Keep store size, allocation size/stride, field offset and alignment as distinct
facts. Knowing an object's memory layout does not establish register ABI support
or backend admission. Keep backend size limits, supported-layout restrictions
and ABI checks with their existing owners. Use checked extent/offset arithmetic
and do not reuse facts across changed module or layout identities.

A first slice should migrate one bounded layout query while preserving its
accepted and rejected inputs. Qualification should cover named and nested types,
packed/unpacked fields, scalar padding, unsupported overrides, cycles and overflow.
Any new admitted layout is a separately classified capability change.

### Small rewrite-construction helper

Start with [floating pair loads](../../src/codegen/x86_64/generic_cfg/floating_pair_loads.zig)
and [memory bitcasts](../../src/codegen/x86_64/generic_cfg/memory_bitcasts.zig).
[Memory-byte lowering](../../src/codegen/x86_64/generic_cfg/memory_bytes.zig)
is a later consumer whose specific control-flow policy stays local.

Factor repeated candidate-block construction, temporary naming and publication
into a small helper. Reuse `Instruction.clone` from the
[IR core](../../src/ir/core.zig) and `TemporaryNames` from
[scalar forms](../../src/codegen/x86_64/generic_cfg/scalar_forms.zig).
Make borrowed versus owned instruction buffers, strings and labels explicit;
clone mutable operand storage before modifying a borrowed source instruction.

Preserve each rewrite's eligibility and semantics, original SSA position of
loads/bitcasts, metadata, PHI placement and entry-prefix insertion rules.
Publish a candidate only after construction succeeds. Unsupported cases and
allocation failures must leave the complete original IR unchanged and release
candidate-owned resources through the declared allocator/lifetime contract.

Qualify both initial consumers, including allocation-failure and unchanged-source
checks. Keep instruction selection, family-specific rewrites and legality tests
outside this helper; this candidate does not introduce a universal legalizer.

### Bounded pointer and access facts

Starting points: [memory-location analysis](../../src/analysis/memory_location.zig)
and [aggregate-object views](../../src/codegen/x86_64/generic_cfg/aggregate_object.zig).

Audit each caller's proof requirements before extracting shared facts for object
identity, byte offset, extent and access bounds. Keep unknown information explicit
and preserve checked arithmetic, address-space restrictions, alias assumptions,
identifier equality and proof budgets.

Equal PHI offsets do not prove that incoming pointers have the same underlying
object. Different roots may still support a valid bounds proof on every incoming
path while unique-root and alias facts remain unknown. Represent those conclusions
separately so a bounds consumer cannot accidentally treat them as a same-object
proof. Unknown is not a zero offset, a known extent or a proven object identity.

A first slice should migrate one bounded caller without silently strengthening
or weakening admission. Qualification should distinguish same-root and
different-root PHIs, valid per-path bounds, unknown/escaped pointers and offset
overflow. Broader alias analysis or new pointer admission needs a separate scope.

## Validation and completion

Apply [validation tiers](../validation_tiers.md) to the actual changed subsystem.
Record the required tier and its trigger before execution. Optimizer changes
need optimizer comparisons and readiness; selector changes need executable
canaries and captured-row object checks. ABI, frame, allocation, verifier or
confirmed wrong-code changes follow the stronger gates specified there.

Each stage closes only after its applicable gates and the required cumulative
integration result. Reuse existing evidence only when relevant source, inputs,
toolchain, target, modes and arguments match. Preserve original failed receipts
and diagnose unexpected differences instead of silently replacing baselines.

Separate three kinds of result:

- Refactoring: existing behavior and admission remain preserved.
- Capability: additional inputs work through the shared mechanism and receive
  separate semantic and boundary validation.
- Performance: measured changes in compiler time or memory on named workloads.

Stage 1 is recorded in the
[implementation evidence](../evidence/compiler_generalization_stage1_20261116.md).
Its two selected consumers are vector-combine and the backend cyclic byte-vector
memory query. Mechanical consolidation, conservative opaque-reference refusal
and the current-insert correctness repair are separate changes. Focused checks,
both 2,395-unit builds, bounded native comparison, mutation control, full
readiness and 66 structural tests pass. All 17 cumulative integration gates pass
on that unchanged source, including the complete 230-population native suite.
Authenticated frontend AIR is reused; backend and executable results run afresh.

Keep ABI limits, floating-point promises, poison/undef rules, memory bounds,
target constraints and transaction guarantees explicit. Their correctness
conditions remain necessary when implementation code is shared.

## Evidence and storage

Follow the [development storage contract](../development_storage.md).
For implementation, allocate a fresh cycle below
`local-state/validations/compiler-generalization/`, with separate stage/run
roots and corresponding managed temporary workspaces. Record concrete paths,
producers, consumers and release conditions in the implementation cycle's
`retention.md` before generating data.

Retain compact commands, outcomes, diagnostics, selected reproductions and
comparison identities. Retain baseline/candidate products only through their
named comparison or fault-test consumers. Reuse authenticated existing inputs
and source revisions; keep any unique uncommitted source delta explicitly.
Avoid another full source snapshot for every attempt.

Collect eligible temporary work through the guarded managed workflow before
admission, after successful ordinary runs, and immediately after the last
consumer releases a retained pipeline. Retry collection deferred by a reader or
collector lock at the next idle boundary; do not postpone it until the end of
the whole improvement plan. Failed or interrupted work keeps its diagnosis and
owner-controlled disposition requirements.

Existing independent holds and accepted replay dependencies retain their
contracts. In particular, current preopt historical-model and `fe2` alias
exceptions remain with their existing owners and release conditions. Record
their current bindings at implementation admission; this plan inherits no
authority to clear or reclassify them. It does not initiate historical evidence
retirement.

## Final deliverable

For each completed stage, publish its source revision, exact migrated consumers,
removed special cases, preservation result, newly admitted inputs, rejection
boundaries and any measured performance result. Update architecture and current
state only after the corresponding implementation and evidence are accepted.
