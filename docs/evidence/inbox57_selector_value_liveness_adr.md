# ADR: Selector, Value-Location, And Liveness Ownership

status: accepted-with-amendments
directive: `INBOX-57`
date: 2026-07-15
baseline: `69461b73`
target: `x86_64-linux-gnu`
accepted_report: 443 selected / 285 emitting / 158 failing

## Context And Evidence Boundary

This is checkpoint area 1 of the agreed six-step post-fma program. It is a
read-only architecture decision record. It does not authorize selector work,
documentation compaction, retention cleanup, preopt sharding, an ABI
differential harness, or another capability family.

The review used the accepted source at `69461b73`, the accepted INBOX-56
report `tmp/inbox56_fma_report.log`, the committed acceptance summaries, and
the frozen compiler-rt capture at
`tmp/udivmoddi4_ptr_null_cache/o/8c6b4a5e45095cb98b30ca8d3f251feb/libcompiler_rt_zcu.o.zllvm.ll`.
The capture's observed MD5 is the pinned
`b0eda7a6427c3084fdf096a68696f19c`. No gate or Tier 3 was run. No selector,
test, fixture, ratchet, or handoff file was changed.

The accepted report does not print the successful selector subroute.
`MachineFunction.CodegenPath` has only `generic_cfg` and
`structural_matcher`; `lowerFunctionWithOptions` overwrites every success from
`generic_cfg_selector.tryLowerWithContext` with `generic_cfg`. Consequently,
the subroute counts below are acceptance-ledger ownership, not a fresh dynamic
dispatch trace. Making that distinction executable is itself an identified
gap.

## Decision

1. Freeze new exact multi-block and whole-function admissions. Existing exact
   admissions may receive correctness or fail-closed repairs, but no new
   function-name, envelope, or captured-CFG template should be added before
   the first genericization slice is reviewed and accepted.
2. Make `ComposedBlockSelector.values`, its allocation-plan intervals, and
   the selector-state bind/clobber/spill/materialize operations the canonical
   value-location authority. Extend that authority incrementally; do not
   rewrite the selector wholesale.
3. The first implementation slice, if separately authorized, is a
   behavior-preserving accumulator-definition transaction for EAX/RAX. Every
   composed-selector physical accumulator definition must preserve or expire
   all aliases through the shared liveness authority before the write, then
   bind the result through the shared result-location authority.
4. Do not retire the 17 legacy terminal rows immediately. Quarantine them:
   no new users, explicit ownership reporting, and retirement only one
   semantic family at a time with exact before/after executable comparison.
   Freeze the post-selector fallback population under the same no-expansion
   rule.
5. Work on shared ordinary-class invariants before x87/fp128. The scattered
   40 contain coherent GPR/pointer/frame work with substantially more reuse
   than their row order suggests.
6. Treat x86 `x86_fp80` and LLVM `fp128` as a separate ABI, register-class,
   spill, call, return, and verifier project. They are not the next routine
   scalar capability slice.

## Selection Ownership

### Accepted-row ledger

The last pre-composition state was 120 emitted rows: zero composed rows, 17
terminal-template rows, and therefore 103 existing post-selector fallback
rows. The accepted state is 285 emitted rows. The ledger records no later
terminal-template expansion and attributes the 165 net additions to composed
selection.

| Primary acceptance owner | Accepted rows | Dispatch position | Character |
| --- | ---: | --- | --- |
| Composed per-instruction selector | 165 | After inspection; block or CFG composition | Typed operation selection plus allocation-plan/value-map state |
| Legacy envelope selector | 17 | First inside `generic_cfg_selector.tryLowerWithContext` | Whole-function semantic envelopes that emit terminal machine routines |
| Post-selector fallback | 103 | After the opt-in selector rejects | Older exact structural and function-specific lowering chain in `air_patterns_impl.zig` and `generic_cfg/core_*` |
| **Unique accepted total** | **285** |  |  |

Two requested style counts overlap the primary owners and are not additive:

| Implementation style | Accepted rows | Relationship |
| --- | ---: | --- |
| Terminal templates | 17 | The same 17 rows owned by the legacy-envelope route: 15 limb64 rows plus `__udivei4` and `__umodei5` |
| Exact structural admissions | 103 | The accepted fallback population predating composition; it includes semantic structural matchers and function/envelope-specific matchers |

This accounting is exact as a claim ledger but is not sufficient as a
current route census: because composed selection runs before fallback, a new
composed capability can capture an old fallback row without changing
443/285/158. A future non-semantic observability slice must attach one of
`composed_block`, `composed_cfg`, `legacy_envelope`, or `structural_fallback`
to every successful row and must fail if the four counts do not sum to the
emitted total. Until then, ownership movement without an explicit claim is a
stop condition.

### Admission taxonomy

| Admission class | Current examples | Classification | Decision |
| --- | --- | --- | --- |
| Typed per-instruction forms | Scalar, pointer, FP, vector, conversion, memory, call, and ordinary CFG modules under `composed_selector_*` | Semantic structural capability | Continue only through reviewed generic slices |
| Exact composed CFG shapes | `isExactFrexpSwitchPhiShape`, `isExactEiEntrySwitchPhiShape`, `isExactEiScalarFamily` | Captured-family structural envelope; not function-name keyed, but still multi-instruction/multi-block matching | Freeze new shapes; retain existing shapes fail-closed |
| Exact provenance chains | `isExactI52ShiftCount`, pinned `isExactCtlzI52Envelope`, EI narrow-width predicates | Semantic only inside a whole-chain proof | Retain; do not use this pattern to admit unrelated families |
| Legacy whole-function envelopes | Fourteen `matches*Envelope` entry points in `legacy_envelopes.zig`, covering 17 rows | Semantic envelope matched across a whole body, followed by a terminal routine | Quarantine and retire incrementally, no expansion |
| Structural fallback | Ordered `lower*` chain in `air_patterns_impl.zig`, `generic_cfg/core_*`, C ABI and runtime row modules | Mixture of reusable structure and exact fixture/function matching | Freeze population; tag ownership before retirement |
| Function-name admissions | Numerous `function.name` checks in `air_patterns_*`, C ABI row modules, and runtime fixture paths | Function/envelope matching rather than generic selection | Never add on the compiler-rt convergence path |

The existing frexp and EI admissions are narrow enough to remain accepted,
but they are the boundary: another exact multi-block template would deepen
the same ownership problem instead of reducing it.

## Canonical Value-Location Invariants

The intended invariant set is:

| ID | Lifecycle point | Required invariant | Present authority | Gap |
| --- | --- | --- | --- | --- |
| V1 | Definition | A result has one virtual identity, type/class metadata, and one current `ValueLoc`; every physical definition displaces all live occupants first | `bindResultLoc`, `bindValueLoc`, allocation-plan assignments | Fixed-result helpers and emitter-local EAX/RAX/XMM writes can separate clobber from bind; the protocol is conventional, not enforced |
| V2 | Binding | Rebinding changes location without changing virtual identity; width and vector shape remain invariant | `ValueBinding`, `virtualRegMetadata`, `bindResultLoc` | No assertion checks old/new class compatibility on every `bindValueLoc`; some aliases are deliberately represented as multiple names at one location |
| V3 | Aliasing | All names sharing a physical location are visible to one occupant query and are preserved or expired together | Iteration over `selector.values`; accumulator, scalar, pair, and XMM queries | There is no reverse location-to-binding index or explicit alias set; correctness depends on each query covering every `ValueLoc` variant |
| V4 | Liveness | Preservation uses one definition of live-at/current, live-after/current, PHI-edge use, and address dependency closure | Allocation-plan intervals; `valueIsLiveAtOrAfterCurrent`, `valueIsLiveAfterCurrent` | Two boundary predicates plus `preserve_current_position_values` are caller-controlled; stack-pointer dependency closure is special-cased for `stack_i32_ptr` rather than type-general |
| V5 | Clobber | A physical-register write must go through a class-aware displacement operation before emission | `clobberArgReg`, `clobberXmmReg`, `clobberAccumulator` | Machine instructions have no declared def/clobber set, so an emitter can append a fixed-register write without invoking the authority |
| V6 | Preservation | Every live displaced value gets a stable planned register or spill home; dead values are removed | `valueMustSurviveClobber`, `spillValue`, `spillPairValue` | Accumulator, pair, scalar, XMM, call, and PHI preservation have separate loops and exception rules; aggregate values cannot use the ordinary spill path |
| V7 | Spill | Spill slots are deterministic, non-overlapping frame objects of the correct size/alignment and the binding changes atomically | Allocation-plan spill assignments, `allocateSpillSlot`, `prepareStackFrame` | Scalar, pair, FP/vector, stack-object, and aggregate cases use different representations; `spillValue` rejects aggregate and stack-object locations |
| V8 | Reload/materialize | Uses consume the current location, clobber the destination through V5, emit one typed move/reload, and update location only for a real relocation | `materializeLocIntoLocWithBits`, `emitValueInto*`, FP/vector materializers | Materialization is a growing Cartesian switch duplicated by scalar, pointer, FP/vector, call, return, and PHI helpers |
| V9 | Call | All ABI-clobbered live values are preserved before argument staging; return values are normalized to the IR type before binding | `spillLiveCallerClobbersForCall`, SysV planners, call result binding | Scalar-SSE calls add class-specific preservation; pointer/aggregate call paths live elsewhere; narrow integer return normalization is specialized rather than ABI-generic |
| V10 | PHI edge | All incoming sources are stabilized before any destination write; the edge is a parallel copy and cycles are resolved without losing a source | `emitPhiEdgeMoves`, scalar/XMM snapshots, `phi_destinations` | Scalar and XMM algorithms are separate, aggregate/pointer shapes are restricted, and no accepted proof exhausts mixed-class cycles under simultaneous spill pressure |
| V11 | Merge | Block entry observes only PHI destinations or stable carried homes, independent of traversal order | `phi_destinations`, boundary spilling, allocation-plan forward values | Selector state is mutated in emission order; exact EI forward-value exceptions and framed boundary spilling compensate for shapes rather than model a general state join |
| V12 | Return | A return consumes the current typed location, applies ABI normalization, restores one frame, and defines only ABI return registers | `lowerReturn`, `emitReturnEpilogue`, return materializers | Scalar integer, pair, FP, vector/aggregate, and direct-call returns use distinct paths; sub-32-bit normalization is not one common ABI rule |
| V13 | Frame | All stack objects, spills, outgoing areas, and temporary homes share one size/alignment/layout authority | `prepareStackFrame`, frame indexes, spill reservation | Planning demand, special stack locations, aggregate objects, and call alignment still enter through different APIs; cross-kind non-overlap lacks one combined executable stress case |
| V14 | Target semantics | Selected machine operations are legal for captured target attributes and bit-equivalent to the IR operation | Instruction selectors, verifier, exact executable tests | The map cannot prevent target-feature misuse or an operation-identity mistake; those require target and semantic invariants beside location invariants |

### Class ownership and duplication

| Value class | Binding/location owner | Preservation/materialization duplication | Assessment |
| --- | --- | --- | --- |
| Scalar GPR | `values`, allocation plan, selector-state scalar helpers | EAX/RAX special cases, general argument registers, pairs, compares, loads, returns, and PHI snapshots | Best consolidation target; most P0 evidence points here |
| Pointer | GPR locations plus semantic stack/table-pointer variants | Memory lowering, call argument lowering, table GEP, stack-index dependency scan | Physical ownership should be scalar-GPR; provenance/address descriptors remain typed metadata |
| Scalar XMM | `xmm` location with bit width | FP materializer, XMM clobber/spill loop, call planner, FP return, PHI snapshots | Shares the value map, but not one use/def transaction |
| Vector XMM | `xmm` plus `VectorShape`, `spill_vector` | Vector-specific moves, lane-definedness, pair-slot spills, XMM PHI path | Preserve shape metadata, but route register defs/clobbers through the same XMM transaction |
| Aggregate | `aggregate_sse` leaf descriptors and C ABI-specific structures | Separate field/return/call machinery; ordinary spill rejects it | Keep out of the first slice; later decide whether it becomes a first-class value or remains ABI decomposition |
| Frame/stack object | Special `stack_*` locations plus frame preparation | Stack allocas, pointer descriptors, scalar/pair/vector spills, outgoing calls | One final layout exists, but object creation and liveness dependencies are fragmented |

## Recent Correctness Events Mapped To Invariants

“Recent” here means the correctness series that established the standing
executable-proof discipline plus every post-INBOX-44 P0 and its immediate
generated-index recovery.

| Event | Violated invariant | Permanent executable regression |
| --- | --- | --- |
| INBOX-10 fused setcc wrong-code | V14: `xor eax,eax` changed flags between compare and setcc; a machine operation did not preserve its semantic inputs | `test/zig/integrated/setcc_predicates_start.zig` exercises `sete`, `setne`, `setb`, and unsigned-greater outcomes; acceptance summaries are `zig_integrated_exe_setcc_correctness.summary` and `distribution_all_after_setcc_correctness.summary` |
| INBOX-45 accumulator-alias P0 | V3/V5/V6: destructive immediate lowering preserved one arbitrary EAX alias rather than every live alias | The permanent mmap regression in `composed_selector_scalar_tests.zig` combines ctlz, no-op trunc aliasing, immediate XOR, and later use of both values; four exact cases include the `127007` result |
| INBOX-49 baseline POPCNT P0 | V14: accepted objects used POPCNT under captured `-popcnt` attributes | Executable i32 baseline cases plus the exact extracted `__popcount_limb64` caller cover zero/boundary/mixed patterns and require POPCNT to be absent |
| INBOX-51 scalar fneg P0 | V14: parser-normalized `fsub -0.0,x` was selected as arithmetic subtraction rather than bit-exact sign toggle | Composed f32/f64 execution covers zeros, subnormals, normals, infinities, and both signs of quiet/signaling NaNs; extracted `__subsf3` has 34 exact checks |
| INBOX-53 narrow-return P0 | V9/V12: an i16 call result was bound in EAX without removing ABI-undefined upper bits | Hostile helper returns `0xdead0020`; the selected i16 shift must observe only `0x0020` and produce 8 |
| INBOX-54 generated-index recovery | V4/V5/V6: a stack i32 load overwrote EAX while an i64 accumulator was live only through a PHI edge | `composed_selector_memory_tests.zig` retains the focused PHI-edge case; `compiler_rt_i128_arithmetic_start.zig` with the exact wide-division fixtures executes 54 quotient/remainder operations across six rows |

The pattern is not “insufficient special cases.” All six events fail to make
an implicit machine dependency—flags, target features, operation identity,
upper-bit definition, alias occupants, or PHI-edge liveness—part of a
mandatory selection or definition transaction.

## Remaining Report Topology

### The 118-row ABI/register-class wall

Every one of these 118 signatures contains `x86_fp80`, `fp128`, or both:

| Signature population | Rows |
| --- | ---: |
| `x86_fp80` only | 65 |
| `fp128` only | 51 |
| Mixed `x86_fp80`/`fp128` conversion | 2 |
| **Total** | **118** |

The selector-detail split is 83 unsupported return types and 35 unsupported
parameter types. Diagnostic names split into 18 explicit long-double ABI
rejections, 99 early control-flow rejections, and one instruction rejection;
those diagnostic classes do not change the architectural root. Opening this
population requires, at minimum, SysV classification, x87 stack-register or
softening policy, fp128 representation, call/return rules, spill classes,
frame alignment, verifier state, encoder support, and differential execution.

### The scattered 40 by reusable yield

| Priority | Shared capability/root | Rows | Exact diagnostic population | Reuse assessment |
| --- | --- | ---: | --- | --- |
| High | Float-to-EI/TI conversion result domains | 12 | 6 `cast-from-not-int`, 3 `cast-width`, 3 `select-width` | One typed conversion/normalization design can serve a twelve-row family |
| High | i128-to-FP compare operand location | 6 | 6 `icmp-lhs-loc` | Direct test of pair/spill materialization and comparison operand symmetry |
| High | Pointer call-argument materialization | 6 | 5 `call-unknown-ptr-arg`, 1 `call-ptr-arg` | Shared pointer-value/call staging work; should not be row-specific |
| Medium, high risk | Local scalar/complex frame objects | 6 | 6 `unsupported_type=alloca` | Shared frame-object capability, but it crosses V13 and must follow accumulator consolidation |
| Medium | Read-only table pointer GEP | 2 | 2 `gep-readonly-table-global` | Reuses pointer provenance and table-location materialization |
| Low/leaf | Scalar FP operation or intrinsic | 4 | `fmul`, `fdiv`, `fsub`, `llvm-intrinsic` | Operation-specific unless a common missing type/form is first demonstrated |
| Low/leaf | Singular typed forms | 4 | one each: `pair-binary-op`, `insertelement`, `binary-width`, `icmp-form` | Do not schedule from row order; re-rank after shared slices |
| **Total** |  | **40** |  |  |

The top three groups account for 24 of 40 and exercise existing ordinary GPR,
pair, pointer, spill, and call classes. That is enough shared yield to justify
ordinary-class consolidation before the 118-row x87/fp128 project. It is not
authorization to implement any of them now.

## Bounded Implementation Slices

These are proposed review units, not an authorized queue.

| Slice | Scope | Measurable exit | Explicit exclusions |
| --- | --- | --- | --- |
| O0 successful-route observability | Add a non-semantic success-owner tag and report counts for composed block/CFG, legacy, and fallback | Four tags sum to 285; per-row owner manifest is deterministic; 443/285/158 and objects are unchanged | No selector precedence or admission change |
| O1 accumulator definition transaction | Central `prepare/define` path for composed EAX/RAX writes; migrate accumulator-producing loads, casts, compares, calls, and scalar arithmetic | No migrated emitter can bind EAX/RAX without the transaction; all alias/PHI/narrow-return regressions pass; owner manifest and report unchanged | No XMM, pair, aggregate, frame redesign, or row closure |
| O2 ordinary GPR/pointer materialization | One use transaction for scalar/pointer register, spill, and table-pointer sources; address dependency metadata becomes type-general | Six pointer-call and six i128 compare-location failures either advance as predicted or stay at one honest new frontier; no function-name checks | No stack-argument ABI expansion or aggregate calls |
| O3 XMM use/def transaction | Share XMM clobber, spill/reload, result binding, and shape preservation across scalar FP and vectors | Mixed scalar/vector pressure and crossed PHI tests pass with no undefined lanes; no direct untracked XMM definitions in migrated modules | No new vector width, aggregate ABI, x87, or fp128 |
| O4 PHI parallel-copy generalization | One class-parameterized cycle resolver using stable homes; remove duplicated scalar/XMM snapshot policy | Two- and three-cycle GPR, pair, scalar-XMM, vector-XMM, and pressured-spill matrices pass; existing exact EI/frexp wrappers call the same resolver | No new switch/CFG admission |
| O5 frame-object unification | Represent allocas, spills, vector pairs, outgoing areas, and temporary homes as sized/aligned frame objects | Combined stress object proves non-overlap/alignment and frame restoration; six alloca rows have honest frontiers | No aggregate ABI or x87/fp128 |
| O6 legacy retirement | Replace one legacy semantic family at a time with composed selection | Owner count moves from legacy to composed by the expected number; extracted before/after execution is bit-exact; terminal byte routine removed for that family | Never batch all 17; no fallback rewrite |
| X1 x87/fp128 project contract | Separate read-only ABI/register/spill/differential design | Approved ABI matrix and executable differential plan exist before code | All routine scalar capability work |

O0 is necessary because the present 165/17/103 ledger cannot detect silent
ownership capture. O1 is the smallest semantic genericization: it addresses
the repeated accepted wrong-code class without widening a type, instruction,
or CFG shape.

## Interaction Test Gaps And Validation Requirements

Existing tests cover many components independently, including live XMM values
across calls, scalar/vector spills, crossed PHIs, narrow intByteSize returns,
generated indexes, and mixed frame objects. The missing requirement is a
small matrix that composes those components at their boundaries.

| Boundary | Required executable validation before the owning slice can close |
| --- | --- |
| Calls plus live values | One direct and one indirect call with simultaneous live EAX/RAX alias, ordinary GPR, scalar XMM, vector XMM, and pointer-derived address; include swapped arguments and narrow integer plus FP returns |
| Scalar/vector pressure | A deterministic case where GPR pair and vector pressure spill at the same instruction boundary, then both values are consumed after a call or branch |
| PHI cycles | Two- and three-way cycles for GPR32/64, GPR128 pairs, scalar XMM, and vector XMM; include overlapping destinations, duplicate sources, a backedge, and forced spills |
| Narrow returns | Hostile upper-bit stubs for i1, i8, and i16 direct/indirect returns, followed by 32- and 64-bit consumers and a PHI edge; FP returns retain exact lane-definedness |
| Generated indexes | Address base, index, and addend remain live across an EAX-writing load, a call, and a PHI edge; verify the addressed element and neighboring memory |
| Frame ownership | One function combines aligned scalar/vector allocas, scalar/pair/vector spills, an outgoing call area, PHI stable homes, and return epilogue; inspect every displacement and execute canaries around each object |

For any separately authorized implementation slice:

1. Focused unit and negative tests must prove both the new transaction and
   fail-closed exclusions.
2. Tier 2 must cover the complete accepted captured-row cohort, not a sample:
   selection, success owner, emission, object inspection, relocation summary,
   exact 443/285/158 diagnostics, and object identity where behavior is
   intended to remain unchanged.
3. Every mapped P0 executable above must run in the relevant Tier-2 canary
   set. Structural or byte inspection alone is insufficient.
4. Exact extracted-row execution is required for every accepted row whose
   owner or object changes, even if report counts do not move.
5. The real-program boundary and mixed interaction matrix must remain green.
6. Tier 3 follows `docs/validation_tiers.md`: run it only when the accepted
   slice crosses its allocator/frame/ABI/milestone trigger or repairs P0
   wrong-code. Do not use Tier 3 as diagnosis.

## Stop Conditions

Stop the authorized slice and return for review if any of the following is
observed:

- a successful row changes owner without appearing in the approved owner
  delta;
- selection, object bytes, diagnostics, or 443/285/158 move outside the
  slice's stated exit criteria;
- an executable mismatch, stale binding, undefined upper bit, flag clobber,
  target-feature violation, or frame overlap appears;
- completion needs a new `ValueLoc`, register class, spill allocator, frame
  authority, calling convention, or exact multi-block admission;
- a supposedly generic change needs a function-name or compiler-rt-family
  predicate;
- aggregate, x87, or fp128 work enters O0-O6;
- the implementation cannot remain one reviewable ownership transaction and
  starts combining capability closure with infrastructure or legacy
  retirement.

## Consequences

This decision preserves the accepted selector and focuses the next possible
architecture work on enforcement rather than expansion. It leaves useful
legacy and fallback coverage in place while making their growth illegal. It
also makes report-row order non-authoritative: the shared ordinary-class
groups among the scattered 40 are the only plausible near-term capability
population, and even those follow ownership observability and accumulator
definition consolidation.

INBOX-57 is acknowledged. Stop after this ADR and request review; no later
checkpoint area or implementation slice has begun.

## Accepted amendments (Reviewer, 2026-07-15)

The Reviewer accepts this ADR with the following binding amendments. They
refine and, where necessary, supersede the ownership and invariant wording
above; the original review body remains intact as the decision record that was
reviewed.

### Canonical selector-state authority

The canonical authority is the selector-state transaction API together with
its allocation plan, not direct access to the raw `values` map. The API must
own allocation, binding, resolution, use, definition, clobber, spill,
materialization, and rollback as one state transition. The raw map is backing
storage only and is not an independent source of authority.

Two existing bypass scans must be closed progressively in O1:

- `composed_selector_scalar.zig:561`, where scratch-register availability is
  inferred by iterating the raw values map; and
- `composed_selector_vector.zig:661`, where XMM availability is inferred the
  same way.

O1 may migrate those reads behind the transaction API in bounded steps, but
must not add another raw-map access. This amendment does not authorize O1.

### V3/V5: EAX and RAX are one alias and defined-bit domain

V3 and V5 are strengthened: EAX and RAX are one physical-register alias
domain and one defined-bit domain, never independently live locations. An EAX
definition overwrites the low 32 bits and zero-extends them, thereby defining
the full RAX value. An RAX definition defines the full domain. Every bind,
definition, clobber, reuse, spill, and invalidation must account for both names
and update or invalidate all affected bindings atomically. No selector route
may retain separate live EAX and RAX occupants or preserve stale upper-bit
knowledge across an EAX definition.

### Explicit EFLAGS liveness

Add an explicit EFLAGS use/definition/clobber invariant to selector state.
Every flags consumer, including `setcc`, conditional branches, and related
flag-dependent forms, must have a reaching flags definition with no intervening
clobber. Accumulator preparation and all other flag-writing instructions must
declare that clobber and cannot be inserted between a live EFLAGS definition
and its use. Future ownership work must snapshot and validate EFLAGS liveness
alongside register and memory state rather than infer it from instruction
adjacency.

### Fail-closed selection atomicity

Selection is fail-closed only when an unsupported speculative attempt restores
every externally visible `MachineFunction` field, not merely the instruction
length. The snapshot boundary includes instructions, owned labels and other
owned allocations, frame/ABI and entry metadata, selector/codegen owner state,
and any future mutable field visible after the attempt. The current generic
wrapper restores only `instructions.items.len`, while composed selection can
append `owned_labels`; that partial rollback is not sufficient evidence of
atomicity.

O0 must therefore include a negative snapshot test that forces an unsupported
result after label or selector-state mutation and compares instructions,
labels, frame/ABI metadata, and owner state with the pre-attempt snapshot. If
the test exposes leakage, stop and authorize a separate corrective slice before
O1. O0 itself, O1-O6, and X1 remain proposed and unauthorized.
