# End-to-End Convergence Plan

Author: Claude (assistant), 2026-07-02. Status: proposal, not yet adopted.
Amended 2026-07-02 after review: adoption patch in Phase 0, staged ratchet
counters, candidate-selector tooling as a deliverable, earlier hello-world,
incremental register-allocation scope, expanded differential-testing scope.
Second amendment 2026-07-02: ratchet denominator pinning, closure-aware
candidate schema, evidence-summary schema, precise hello-world acceptance,
first-cycle split.
Final amendment 2026-07-02: denominator rule extended to
`unsupported_functions`, conservative selector v1, exit-criteria and
pin-validation clarifications. Revision is closed; the next change to this
plan should come from contact with a real compiler-core row, not another
editing pass.

Adoption note: this plan must not remain a proposal doc beside the old
process. Adopting it means executing the Phase 0 adoption patch below, which
retires the conflicting operating truth in `docs/next_steps.md`,
`docs/working-cycle.md`, and `docs/roadmap/project_finish_statement.md`.
Until that patch lands, worker cycles will keep optimizing the old metric.

This plan describes how to get from the current state (753 fixture-backed
frontier functions, all gates green, 55,852 of 61,375 real compiler-core
functions still unsupported in ReleaseFast) to the actual goal: the patched
Zig compiler emitting working x86_64 code for real programs through z_llvm,
with `llvm_targetmachine_rows=0` and `lld_rows=0`, ending at self-host.

## Definition of Done

The goal is reached when all of the following hold:

1. A patched Zig using z_llvm as its x86_64 backend compiles and links real
   programs (Debug + all three release modes) that pass their own test suites.
2. The Zig compiler itself (`../ziglang` compiler-core module) builds through
   z_llvm, and the resulting stage compiler passes the Zig behavior test
   suite for x86_64-linux.
3. No LLVM TargetMachine and no LLD anywhere in that path.
4. Remaining unsupported forms are explicit fail-closed boundaries with
   documented justification (e.g. inline asm subforms), not silent gaps.

## The One Metric That Matters

Today the primary metric is checklist items closed and unknown inventory
buckets zeroed. Both can move without the goal getting closer (buckets can be
reclassified; items can be closed for one-shape subsets). This plan replaces
them as the headline metric with:

> **real_functions_compiled**: the number of functions from the real
> `../ziglang` compiler-core module (not fixtures) that z_llvm lowers, emits,
> and — where callable — executes correctly.

That single number is the headline. For diagnosis and ratcheting it is
tracked as five staged counters, mirroring the stage split the fixture gates
already report (`generic_cfg_functions`, `object_emitted_functions`,
`native_link_accepted_rows`, `executable_ok_rows`):

- `real_functions_lowered` — real functions through typed lowering + CFG.
- `real_objects_emitted` — real functions through x86_64 object emission.
- `real_native_linked` — real rows through the Zig native linker handoff.
- `real_executed` — real callable rows with verified execution results.
- `real_programs_ok` — whole real programs built, linked, run, exit-checked.

Each counter is an independent ratchet: it may only grow, and a drop fails
the gate. Failures will cluster at different stages for different families;
one blended number would hide that.

**Ratchet denominator rule.** The counters' denominator is the candidate
file, and the candidate file is allowed to improve (better exclusion
reasons, dedup, closure facts) — so a raw only-grow rule would punish the
selector for becoming more honest. Every recorded ratchet value therefore
carries its denominator: candidate-file hash, selector version, mode, and
gate limit. A counter drop under an *unchanged* denominator always fails the
gate. A drop caused by a denominator change is legal only through an
explicit ratchet-migration note in the tracked evidence summary, recording
old and new candidate-file hashes and which functions left the denominator
and why. Superseded candidate files stay tracked so every migration is
diffable.

The same rule applies to `unsupported_functions`: its denominator moves for
the same honest reasons (scanner improvements, `../ziglang` pin bumps,
better classification), so every recorded value carries ziglang pin, scanner
version, mode, and slice, and a change caused by a denominator change is
legal only through a migration note. This matters doubly because checklist
closure may cite `unsupported_functions` movement (see "What Changes in the
Working Cycle") — without the migration rule, a scanner change that quietly
shrinks the number would count as progress, reopening the reclassification
loophole this plan exists to close.

Equivalently: drive `unsupported_functions=55852` down, and never let it
ratchet up. Fixture rows remain the *debugging* corpus; they stop being the
*progress* corpus. Every phase below has an exit criterion stated in real
functions or real programs.

## Phase 0 — Hardening and Adoption (short, do first)

Fix the conflicting operating truth and the two operational weaknesses
before scaling the loop.

- **Adoption patch.** The repo currently carries three conflicting
  process truths and this plan must become the only active one:
  - Relabel `docs/roadmap/project_finish_statement.md` as a *milestone*
    finish ("Optimizer/IR-layer milestone finish"), with a pointer stating
    that project-level scope is now defined by this plan. As written, its
    "Finished Scope" declares backend work validation-only and bounded to a
    smoke subset — a worker reading it could conclude nothing is left to do.
  - Update the "Current Operating Rule" in `docs/next_steps.md` and the
    "Goal Selection" section of `docs/working-cycle.md` to the new selector
    (see "What Changes in the Working Cycle" below).
  - Update the Documentation Rule in `docs/next_steps.md` so a stopping
    worker records real-row ratchet state (current staged counter values and
    the first failing real row), not only family/checklist state.
- **Evidence durability.** Checklist proof currently lives in untracked
  `tmp/*.log` files. Add a small tool (`tools/summarize_gate_log.zig`) that
  writes a tracked `docs/evidence/<topic>.summary` file, and change the doc
  rule: a checklist item is closed by a tracked summary, with the full log
  path recorded as a pointer only. Backfill summaries for the currently
  cited logs that still exist in `tmp/`.

  Summary-lines-only is too thin to debug a future regression. Each summary
  file records:
  - the exact command that produced the log;
  - the z_llvm commit hash and the `../ziglang` pin hash;
  - the process exit status;
  - all `summary ...` lines;
  - the first failure line, when any stage failed;
  - for real-row gates: the ratchet metadata from the denominator rule
    (candidate-file hash, selector version, mode, limit) and any
    ratchet-migration note. One schema serves both gate evidence and
    ratchet state so the two cannot drift apart.
- **Pin the sibling coupling.** Record the exact `../ziglang` commit hash the
  stage4 binary was built from in a tracked file
  (`docs/evidence/ziglang_pin.txt`), and make the stage4 emitter check compare
  against the pin instead of live HEAD, so the recurring binary/HEAD mismatch
  blocker becomes a one-line diagnostic with a documented fix
  (rebuild per `docs/build_steps.md`).
- **Close the open loose end.** Re-run the interrupted ReleaseFast
  compiler-core-module inventory refresh and close the last vector-family
  checklist item, so Phase 1 starts from a complete inventory.

Exit criteria: tracked evidence summaries exist; pin check in place; vector
family fully closed; all currently existing gates green (the real-row and
integrated-exe gates do not exist yet at this point).

## Phase 1 — First Real Rows (the pivot)

Stop proving mirrored fixtures; start compiling actual compiler-core
functions. This is the highest-information move available: it tests whether
the family abstractions built so far *compose* on code nobody hand-shaped.

- **Candidate selector is a tooling deliverable, not a judgment call.** The
  current inventory is count-oriented: it emits totals and
  `first_source`/`first_function` examples, but no per-function candidate
  list. Phase 1 therefore starts by extending the inventory scanner to emit
  a durable ranked candidate file (TSV or JSON, saved as evidence) with one
  row per function. "Fully-known" opcodes are necessary but not sufficient:
  a function with only supported opcodes can still fail native link or
  differential execution because of what it *references*. Each row records:
  - source, function, instruction count;
  - signature class: C-ABI-stable / internal-callable / not-callable;
  - `call_class`: leaf / internal (callees inside the module) / external;
  - `global_refs` and `runtime_refs` (panic handler, safety runtime);
  - `determinism`: conservatively `assumed_nondeterministic` unless proven
    pure — this field gates only the execution stage, never
    lowering/emission;
  - `harnessable_reason` / exclusion reason: which opcode, boundary
    category, or dependency fact disqualifies the row from each stage.

  Ranking is closure-aware, not just size-ascending: true leaves with no
  global or runtime refs rank first; after that, functions whose transitive
  callee closure lies entirely within the already-green set. A row's link
  and execution stages are only attempted when its closure qualifies; its
  lowering and emission stages are attempted regardless.

  The first selector version may be conservatively approximate: full
  transitive-closure and determinism analysis over the whole module is
  nontrivial, and v1 may mark uncertain rows as not link/execution
  harnessable while still attempting lowering and object emission.
  Uncertainty must degrade toward fewer claims, never more, and the
  `harnessable_reason` field must distinguish *proven unharnessable* from
  *not yet analyzed*, so later selector versions can lift conservative marks
  through the normal ratchet-migration mechanism. The inventory says
  z_llvm already claims to understand every instruction in these functions,
  so they are the cheapest real functions in existence.
- **New gate: `distribution-real-rows --limit=N`.** Takes the top N
  candidates, exports their AIR from the real module build, lowers, emits
  objects, native-links, and where a function is a pure computable leaf,
  executes it against an interpreter-style expected result or a differential
  check (see Phase 3). Fail closed on the first divergence. Start at
  `--limit=1` — the first real function is itself a milestone and will
  likely expose composition bugs alone — then ratchet to 10. The gate
  reports the staged `real_*` counters and becomes part of
  `distribution-all`.
- **Fix what breaks, in place.** Every failure here is a composition bug the
  fixture corpus could not see. Expect failures even on "fully-known"
  functions — that is the point. Each fix cycle follows the existing
  working-cycle discipline, but the goal selector changes: the next cycle
  goal is *the first failing real row*, not the next checklist checkbox.
- **Ratchet.** Once N=10 is green in all three release modes, raise N.
  Never lower it. Record the history of N and of each staged counter in the
  tracked evidence summary.
- **Start hello-world in parallel once N reaches 10–25.** Do not wait for
  the Phase 1 exit criterion before attempting Milestone 2a. Startup and
  linking problems are a different failure class from function lowering
  problems and should surface as early as possible; the two tracks inform
  each other rather than queue behind each other.

Exit criteria: 100 real functions green through their applicable stages
across all three release modes, sustained through subsequent commits (the
ratchets make regressions loud).

## Phase 2 — First Real Program

Compose real functions into a real linked executable that does something.
Milestone 2a starts while Phase 1 is still ratcheting (at N=10–25), per the
Phase 1 note; only 2b waits for the Phase 1 exit.

- **Milestone 2a: syscall hello.** Precisely defined acceptance, one step:
  a program that exports `_start`, uses no `std`, issues `write` and `exit`
  via direct Linux syscalls, built by the patched Zig with z_llvm codegen
  for fixed target `x86_64-linux-gnu`, linked by the Zig native linker, no
  LLD; the gate runs the binary and checks stdout and exit code. This forces
  startup code and the linker handoff at program scale while keeping the
  `std` dependency closure out of the acceptance step. The existing
  `distribution-zig-integrated-object` gate is the seed; extend it to a
  full-program `distribution-zig-integrated-exe` gate.

  Budgeted dependency: the direct-syscall hello pulls the minimal inline-asm
  work (family 15, currently ordered last) forward. Expect the first attempt
  to block on inline asm *by design* — that is this milestone surfacing a
  critical-path family early, not a planning failure. The minimal `syscall`
  form (fixed register inputs, no outputs beyond the return register,
  explicit clobbers) is in scope for this milestone; general inline asm
  stays fail-closed.
- **Milestone 2a′: std hello.** A separate acceptance step, after 2a:
  the same program printing through `std.debug.print` with the default
  `_start`. This is a different order of magnitude — it pulls in the real
  `std` startup path, `std.io`/formatting generics, and comptime-heavy
  instantiations — and must not be folded into 2a's acceptance.
- **Milestone 2b: a std unit.** Compile and run one real `std` test file
  (e.g. `std.mem` subset) through the same path. `zig test` semantics
  exercise error unions, optionals, slices, and panics together — the exact
  composition risk identified in the current approach.
- **Boundary policy.** Where hello world hits a genuinely hard family early
  (varargs for C interop, inline asm in `start`), prefer a *minimal real
  implementation* over a boundary if the form is on the critical path of
  every program; keep boundaries only for forms real programs can avoid.
  This inverts the current default, deliberately: critical-path families are
  no longer allowed to stay fail-closed.

Exit criteria: the syscall hello (2a), the std hello (2a′), and one std test
binary (2b) each build, link natively, run, and exit 0 in Debug + all three
release modes, via the patched Zig.

## Phase 3 — Generalize Instead of Enumerate

The per-shape economics do not scale (i32-only overflow ops, shift-by-one
only, `@Vector(4, u8)` only). Before bulk coverage, replace enumeration with
parametric implementations. Do this *after* Phase 2 so real-program failures
prioritize which generalizations pay.

- **Width/type-parametric scalar lowering.** One implementation per operation
  family over (i8..i128, signedness), driven by typed facts, replacing the
  per-width accepted subsets. Delete the subset carve-outs as they are
  subsumed; the boundary gate keeps whatever remains genuinely unsupported.
- **Retire shape recognizers incrementally.** The backend's whole-function
  dataflow recognizers ("add leaves extracted from an inserted vector")
  become a liability at real-program scale. Replace them with incremental
  generic instruction selection for the generic CFG path: per-instruction
  selection first, then liveness and register-pressure tracking, then spill
  support — each stage landed when real rows prove the need, not as one
  up-front register-allocator project. Two constraints on that phrasing:
  the *delivery* is incremental, but the *design* of the selection layer
  must assume liveness and spilling from the start, because real
  compiler-core functions have high register pressure and will prove the
  need within the first handful of non-leaf rows. Migrate one family at a
  time and keep the recognizer path only as a transitional fallback with a
  counter (`shape_recognizer_functions`) that must trend to zero — the
  counter already exists and is already 0 for the frontier; hold it at 0
  for real rows too.
- **Differential testing as the execution oracle.** Real functions rarely
  have hand-writable expected values. This is a new build, not an extension:
  the current layer in `docs/differential_testing.md` generates six trivial
  scalar identity IR cases, compares against normalized `opt-22`, and
  optionally runs `lli-22` — an IR-level oracle. The oracle this plan needs
  is ABI-level: compile the same real function with stock LLVM-backed Zig
  and with z_llvm into two objects, link each behind a shared C harness that
  generates inputs (respecting the function's signature class from the
  candidate file), run both, and compare outputs, exit codes, and — for
  ReleaseSafe — panic/no-panic behavior. This is what lets `real_executed`
  grow at the same rate as `real_functions_lowered` instead of execution
  coverage being frozen at 14 hand-written rows.

Exit criteria: scalar transforms and overflow/safety ops are
width-parametric; differential harness runs on every `distribution-real-rows`
function with a callable signature; recognizer counter is 0 on the real-row
gate.

## Phase 4 — Bulk Coverage of Compiler-Core

Now scale the loop with the composition risk retired and the economics fixed.

- Drive `unsupported_functions` down bucket-by-bucket, but with priority
  order chosen by *what blocks the most real functions* (the inventory
  already records first_source/first_function; extend it to a blocking-count
  per category so the choice is computed, not judged).
- Families 10–16 (packed aggregates, float math, select, x87, varargs,
  inline asm, debug metadata) get implemented or boundary-justified in that
  computed order. Expect float math and select to be cheap after Phase 3;
  expect x87 to be justifiable as a boundary if inventory shows it confined
  to `c_longdouble` paths real builds can avoid; inline asm needs the minimal
  `start._start` subset and little else.
- Weekly (or per-N-cycles) full three-mode inventory refresh becomes the
  cadence checkpoint; the tracked evidence summary records the
  `unsupported_functions` curve so the trend is auditable.

Exit criteria: `unsupported_functions < 1000` in ReleaseFast on
compiler-core-module, with every remaining function attributable to a
documented boundary category.

## Phase 5 — Self-Host

- **Milestone 5a:** build the full Zig compiler through z_llvm; the build
  completes and the binary starts (`zig version`).
- **Milestone 5b:** the z_llvm-built stage compiler passes the Zig behavior
  test suite for x86_64-linux in all release modes.
- **Milestone 5c:** the z_llvm-built compiler rebuilds itself (fixed point),
  and the second-generation binary is functionally identical (same test
  results; ideally bit-identical modulo known nondeterminism).
- This plan defines completion through correctness. The [pass references](../passes/)
  and [original pass pipeline plan](historical/zig_llvm_pass_pipeline_plan.md)
  cover the optimization work that follows convergence.

## What Changes in the Working Cycle

Only the goal selector and the evidence rule change; the cycle discipline
(one item, focused validation, clean tree, commit) stays.

1. Goal selection order becomes: first failing `distribution-real-rows`
   entry → first failing real-program milestone gate → computed
   highest-blocking family item. The family checklist becomes the *tactic*
   list, not the strategy.
2. A checklist item may not be closed by reclassification alone; closure
   requires movement in a staged `real_*` counter or
   `unsupported_functions`, or a tracked boundary justification.
3. Ratchet counters (the five staged `real_*` counters, program milestones,
   recognizer count on real rows) are enforced by `distribution-all` so
   regressions fail the gate rather than relying on doc review.
4. A stopping worker records real-row ratchet state (current staged counter
   values and the first failing real row) in addition to family state, per
   the Phase 0 Documentation Rule update.

## Recommended First Cycle Sequence

The durable, checkbox-tracked version of this historical sequence and of every
phase milestone is [`convergence_progress.md`](convergence_progress.md). It
records progress and proposed ordering but does not authorize a next goal;
`docs/next_steps.md` is the sole current-action authority, subject to a newer
Active worker-inbox directive. This plan stays frozen as the strategy
reference.

Concrete adoption order, each step one committable working cycle (docs,
tooling, and process-check changes are separate cycles with separate
validation, per the one-item cycle rule):

1. Docs adoption patch only: finish-statement relabel, selector update in
   `next_steps.md` and `working-cycle.md`, Documentation Rule update.
2. Evidence tooling: `tools/summarize_gate_log.zig` emitting the summary
   schema above; backfill summaries for currently cited surviving logs.
3. Ziglang pin: tracked pin file plus the stage4 emitter check comparing
   against the pin, validated by a deliberately mismatched pin failing —
   using a temporary override (env var or flag, in the style of the
   existing debug affordances) or a fixture pin file, never by editing the
   tracked pin, so the worktree stays clean at cycle completion.
4. Close the interrupted vector-family inventory refresh.
5. Extend the inventory scanner to emit the ranked real-candidate TSV/JSON
   with the full schema above; commit the first candidate file as evidence.
6. Add `distribution-real-rows --limit=1`; make the first real function
   green (expect this to take multiple fix cycles).
7. Ratchet to `--limit=10`.
8. Resume family work only as directed by the first real failure; start the
   syscall-hello track once the ratchet reaches 10–25.

## Risks

- **Phase 1 may fail broadly at first contact.** That is expected and is
  the reason to do it now rather than after 43 more fixture items; every
  early failure is a composition defect found cheaply.
- **Recognizer migration (Phase 3) is the largest engineering risk.** The
  transitional fallback plus per-family migration keeps gates green
  throughout; the loop-sum regression history says matcher changes need the
  `distribution-all` bisect discipline already recorded in project notes.
- **Comptime/generic instantiation volume** may explode the real-row corpus
  with near-duplicate functions. Mitigate by deduplicating rows on lowered
  IR shape before ranking, so effort lands on distinct shapes.
- **ReleaseSafe divergence** (407k unsupported opcodes vs 47k in
  ReleaseFast) means safety-edge work recurs in every phase; the
  differential harness must always run all three modes so ReleaseSafe-only
  regressions cannot hide.
