# x86_64 Soft-Float Selector Execution Plan

## Purpose

This is the durable supervisor program for reducing the remaining x86_64
compiler-rt soft-float selector bucket without stopping for external review
after every routine implementation cycle.

The supervisor may direct ordinary, operation-driven work autonomously. It
must stop for architectural review at the checkpoints defined below. This plan
does not replace the repository's existing authorities:

- [`../working-cycle.md`](../working-cycle.md) controls worker goal selection,
  cycle mechanics, clean-worktree requirements, and inbox handling.
- [`../validation_tiers.md`](../validation_tiers.md) controls validation scope
  and Tier 3 triggers.
- [`convergence_progress.md`](convergence_progress.md) is the live progress
  tracker.
- [`../next_steps.md`](../next_steps.md) records only current blockers and
  architectural handoffs.

If this plan conflicts with either `working-cycle.md` or
`validation_tiers.md`, those documents win.

## Adoption Baseline

The adoption baseline for this program is commit `a9f95ddf`:

- compiler-rt report-all: 443 selected / 190 emitted / 253 failed;
- soft-float selector bucket: 230 open / 6 recorded;
- advisory tail-marker inventory: 32 open / 10 emitting;
- the scalar SSE call ABI is accepted by Tier 3;
- scalar widening, narrowing, and multiplication are accepted by Tier 2;
- `compiler_rt.tan.tanf` has reached the first vector frontier,
  `insertelement`.

These values are historical starting coordinates, not permanent targets. At
the start of every cycle, the supervisor and worker must use the latest
`convergence_progress.md`, `next_steps.md`, evidence summary, and focused log
instead of copying counts from this section.

## Objective

Reduce the non-boundary compiler-rt soft-float bucket through reusable,
operation- and type-driven selector capabilities while preserving:

- one authoritative value-location map;
- one frame and spill authority;
- `sysv_abi.zig` as the authoritative x86_64 call classifier;
- explicit x86_64 target ownership;
- fail-closed handling for unsupported types and forms;
- executable semantic evidence for accepted capabilities;
- no source-symbol, block-name, case-id, or polynomial-shape admission.

Object emission is useful progress, but it is not automatically a semantic
acceptance claim. Collateral emissions must be recorded separately from rows
with focused native or executable proof.

## Supervisor Authority

The user explicitly authorizes the supervisor to originate bounded routine
capability goals under this plan. This expands the supervisor role beyond
verification and documentation, but it does not delegate architectural or
product-direction authority.

The supervisor may:

- select the next routine capability from the live non-boundary frontier;
- define its bounded scope, exclusions, acceptance evidence, and validation
  routing;
- issue a corrective follow-up within the same accepted capability and
  architecture;
- continue to the next routine cycle when every continuation rule passes.

The supervisor may not autonomously:

- introduce or redefine value-location, register, vector-lane, allocator,
  frame, ABI, relocation, linker, or AIR-export architecture;
- change milestone meaning, target scope, ownership policy, or semantic
  acceptance criteria;
- authorize nominal admission, terminal templates, or permissive fallback;
- cross a mandatory checkpoint defined by this plan.

Those decisions require external architectural review.

## Supervisor Operating Loop

For an ordinary cycle, the supervisor should:

1. Read the worker inbox, live tracker, current handoff, latest relevant
   evidence summary, and current-cycle logs.
2. Select the first actionable non-boundary failure according to
   `working-cycle.md`.
3. Identify the smallest coherent typed capability that advances that real
   failure. Do not reduce the goal to a single symbol-specific workaround.
4. Give the worker a bounded capability goal with explicit exclusions,
   acceptance evidence, and validation routing.
5. Allow the worker to use Tier 1 checks during development and Tier 2 at
   capability close.
6. Inspect the completed commit for scope, ownership, fail-closed behavior,
   executable evidence, documentation accuracy, and a clean worktree.
7. If the commit satisfies the routine continuation rules and no mandatory
   checkpoint applies, direct the next cycle without requesting external
   review.
8. Request architectural review only at the mandatory checkpoints or the
   periodic review cadence below.

Do not interrupt a dirty in-progress cycle with a new directive. Queue the
next instruction only after the current capability is committed or the worker
reports a genuine blocker.

## Routine Continuation Rules

The supervisor may continue autonomously when all of these are true:

- the next failure stays within the established scalar GPR/XMM value model;
- the implementation is selected by IR operation, operand types, attributes,
  and target ABI facts rather than nominal identity;
- any new machine operation is a narrow x86_64 encoding with focused assembly,
  encoding, verification, and executable tests;
- existing value-map, frame, spill, liveness, clobber, and SysV ownership is
  preserved;
- unsupported variants remain fail-closed with a precise diagnostic;
- focused execution covers dangerous numeric and ABI edge cases;
- the targeted diagnostic advances or the relevant inventory bucket drops;
- collateral emissions are not overclaimed as separately proven functions;
- validation matches `validation_tiers.md`;
- the cycle ends in one coherent commit with a clean worktree.

## Execution Phases

### Phase A: Scalar FP Core

Implement scalar capabilities only as real rows expose them. Expected work
includes:

- `fpext float -> double`;
- `fptrunc double -> float`;
- scalar `fadd`, `fsub`, `fmul`, and `fdiv` for supported widths;
- ordered and unordered `fcmp` predicates;
- FP constants, selects, phi edges, spills, reloads, and returns;
- integer/FP conversions when a real frontier reaches them;
- exact FP/integer bitcasts;
- width-correct caller clobber and result handling.

Prefer register-parametric machine operations when a fixed XMM0 form would
violate allocation, destroy a live source, or create a parallel-move hazard.
Do not add operations speculatively merely to make the instruction enum look
complete.

### Phase B: Scalar FP Memory And Calls

When real rows expose these forms, extend the established architecture for:

- scalar FP alloca, load, and store through the single frame authority;
- mixed GPR/XMM calls with independent SysV register indexes;
- supported stack-passed float and double arguments;
- call argument staging without overwriting later sources;
- exact call-result, call-clobber, relocation, and helper-symbol handling;
- advisory `tail` and `notail` markers as ordinary calls while keeping
  `musttail` fail-closed until actual tail-call ABI work is authorized.

Do not introduce a second call classifier in the composed selector. Factor a
narrow reusable interface from `sysv_abi.zig` when the existing planner cannot
be consumed directly.

### Phase C: Wrapper And Helper Families

Close half/float/double wrappers when their bodies are composed entirely from
established scalar operations and calls. The real internal callee must emit
before claiming full wrapper semantics.

A controlled exact-symbol stub may prove a caller ABI while its real callee is
still unavailable, but the evidence must explicitly state that this is an ABI
proof rather than an implementation proof. Do not substitute an unrelated
system libm symbol for a dotted internal compiler-rt symbol.

### Phase D: Vector FP Architectural Checkpoint

Stop for architectural review before introducing any of the following:

- vector value locations or allocation classes;
- generic `insertelement`, `extractelement`, or `shufflevector` lowering;
- packed SSE arithmetic;
- vector constants, spills, reloads, phi moves, or call ABI handling.

The review must define lane types, vector widths, register ownership,
allocation, spill size/alignment, shuffle semantics, and the relationship to
the existing scalar XMM model. Do not implement vector operations as a local
template for `tanf` or another libm function.

Before proposing an implementation, produce a read-only Phase D inventory
from the accepted report and captured IR. "Vector-blocked" must be reported as
three separate populations:

1. **Immediate vector frontiers:** rows whose current first failure is a
   vector type, value, or instruction.
2. **Latent vector-bearing rows:** failed rows that contain vector IR but are
   currently stopped by an earlier scalar, ABI, frame, or call failure.
3. **Minimal-slice candidates:** rows predicted to advance through one shared,
   narrowly defined vector representation and operation set.

For each population, record unique functions, immediate diagnostics, vector
opcodes, fixed lane counts, element types, total bit widths, and representative
IR shapes. Separate `<2 x double>` polynomial-splat/shuffle demand from other
vector families. State which rows would benefit from a minimal slice and which
would remain blocked immediately afterward.

The inventory is evidence for the architectural decision, not authorization
to implement vector lowering. It should be derived from existing logs and IR
where possible and must not trigger `distribution-all`.

### Phase E: Extended FP Architectural Checkpoint

Keep these explicit boundaries until a separate reviewed plan exists:

- `x86_fp80` and x87 stack ownership;
- `fp128` scalar representation and arithmetic;
- multi-register or memory-return extended FP conventions;
- extended-format stack arguments and varargs.

Do not reinterpret an extended type as a scalar SSE value merely to advance a
row.

## Mandatory Stop And Review Conditions

The supervisor must stop autonomous continuation when:

- a new value-location, register, lane, or allocation class is required;
- shared ABI, frame layout, register allocation, relocation, AIR export, or
  linker ownership must change;
- vector FP, x87, or fp128 support is reached;
- a broad or ambiguous Zig hook/export contract change is proposed;
- the apparent solution requires symbol, block, case, or constant-sequence
  admission;
- two consecutive cycles fail to reduce a target bucket or advance the exact
  diagnostic;
- focused native execution reveals a possible miscompile;
- expected Tier 1 or Tier 2 validation fails outside the new capability;
- Tier 3 fails;
- a file again accumulates unrelated selector, allocator, ABI, frame, and CFG
  ownership;
- a repository-wide refactor is proposed;
- a compiler-rt family or tracker item is ready for a completion claim;
- evidence and implementation disagree about emitted, linked, or executable
  status.

At a mandatory stop, preserve the dirty worktree if the cycle is incomplete,
record the full state required by `working-cycle.md`, and request review. Do
not paper over the boundary with a terminal template.

## Validation And Distribution-All Policy

Use the smallest proof that can validate the current capability:

1. focused unit, selector, verifier, assembly, and encoding checks;
2. a focused executable semantic case;
3. the exact real row and nearby family rows;
4. Tier 2 at coherent capability close;
5. Tier 3 only for a binding trigger in `validation_tiers.md`.

Do not run `distribution-all` merely because the worker committed or stopped.
Reuse fresh evidence when relevant inputs and contracts are unchanged. After a
series of low-risk Tier 2 commits, schedule one periodic Tier 3 at a natural
family checkpoint, normally after four to six commits, unless an earlier
binding trigger applies.

Before every Tier 3 run, record the changed subsystem, trigger, command, log
path, intended evidence file, and why the latest accepted result cannot be
reused. Launch exactly one run, inspect it before continuing, and investigate
any failure with the narrowest reproducing subgate. Never cache executable
semantic results.

## Numeric And ABI Evidence Requirements

Choose cases appropriate to the operation. Across the scalar FP program,
focused native evidence should cover as applicable:

- positive and negative zero;
- normal positive and negative finite values;
- positive and negative subnormals;
- infinities;
- quiet and representative signaling NaN payloads;
- widening exactness;
- narrowing on both sides of rounding boundaries;
- arithmetic overflow, underflow, sign, and cancellation;
- ordered and unordered comparisons;
- live values across calls;
- swapped and overlapping XMM sources;
- mixed GPR/XMM argument numbering;
- spills and reloads at each supported width.

Do not require every case for every operation, but record why the chosen set
exercises the operation's actual hazards.

## Supervisor Commit Review

Before directing another cycle, confirm:

- the commit contains one coherent capability;
- the worktree is clean;
- no nominal or case-specific path was introduced;
- x86_64-specific behavior remains in explicit x86_64 or ABI modules;
- unsupported forms remain fail-closed;
- ownership did not drift from the value map, frame planner, or SysV planner;
- executable evidence is exact enough to detect quiet miscompiles;
- object emission, native linkage, and semantic acceptance are distinguished;
- counters and diagnostics match the saved evidence;
- the selected validation tier is justified.

If all checks pass and no mandatory stop applies, continue autonomously.

If any check fails, the commit is not an accepted cycle boundary. Resolve the
disagreement as follows:

- If the defect is local, unambiguous, and correctable inside the same accepted
  capability and architecture, issue a fix-forward corrective directive and
  require a corrective commit before beginning another capability. Do not
  rewrite or discard already committed history merely to make the cycle look
  atomic.
- If the correction changes ownership, architecture, scope, validation
  authority, or the semantic claim, stop and request external review.
- If it is unclear which category applies, use the conservative second rule.

A commit that is mostly correct but fails one review item may be repaired
without external review only under the first rule; it must not be recorded as
fully accepted until that repair lands.

## Periodic External Review Cadence

Request an external architectural review:

- after four to six autonomous capability commits;
- at every mandatory stop condition;
- before vector FP, x87, fp128, allocator, frame, or ABI expansion;
- before a broad refactor;
- before declaring a family or milestone complete;
- whenever progress counters improve while structural ownership appears to
  worsen.

Routine scalar instruction additions do not need external discussion after
every iteration.

## Current Adoption Sequence

The scalar sequence that originally motivated this plan is complete in
`a9f95ddf`. Adoption therefore begins at the Phase D checkpoint:

1. archive INBOX-21 as completed by `a9f95ddf`;
2. produce the read-only vector inventory required by Phase D;
3. record the three vector-blocked populations and the smallest reusable
   candidate slice, without changing code;
4. request external architectural review of that evidence;
5. authorize vector implementation only through a subsequent explicit
   directive based on the reviewed architecture.

Until that review is complete, do not assign vector value locations, vector
allocation, lane operations, packed arithmetic, or a `tanf`-specific lowering
to the worker. If the vector investment is rejected or deferred, return to the
live report and select the next actionable scalar non-boundary frontier under
the normal operating rules.
